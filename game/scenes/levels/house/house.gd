class_name HouseRoom
extends Control
## Casa do Tiro (primeiro ambiente do Mundo), montada a partir de data/rooms/house.json:
## fundo vazio (piso + paredes) + móveis separados (PixelLab), cada um com uma
## área no chão (footprint) que o Tiro contorna.
##
## Arrastar move a câmera; tocar num móvel abre o menu dele (toque preciso no
## desenho, não num retângulo); tocar no Tiro abre a Tela do Pet.
## Coordenadas do JSON estão em pixels da imagem de fundo.

const ROOM_ID := "house"
const MAX_ZOOM := 2.0
const ZOOM_STEP := 1.25
const TAP_SLOP := 12.0
const NAV_CELL := 8
const SAME_FINGER_DISTANCE := 24.0
const TOUCH_STALE_MS := 1000

var _room: Dictionary = {}
var _zoom := 1.0
var _touches: Dictionary = {}  # índice do dedo -> { "pos": Vector2, "time": ms } (para a pinça)
var _pinch_distance := 0.0
var _objects: Array[Sprite2D] = []
var _dog: DogWorld
var _nav := AStarGrid2D.new()
var _walkable: Array[Vector2i] = []
var _press_position := Vector2.ZERO
var _dragged := false

@onready var _content: Control = %Content
@onready var _background: TextureRect = %Background
@onready var _world: Node2D = %World


func _ready() -> void:
	_room = Database.room(ROOM_ID)
	_background.texture = load(_room["background"])
	_background.size = _background.texture.get_size()
	_content.size = _background.size
	_spawn_objects()
	_build_navigation()
	_spawn_dog()
	%ZoomIn.pressed.connect(func() -> void: _zoom_at(size / 2.0, _zoom * ZOOM_STEP))
	%ZoomOut.pressed.connect(func() -> void: _zoom_at(size / 2.0, _zoom / ZOOM_STEP))
	resized.connect(_on_resized)
	_show_whole_room.call_deferred()


# --- Navegação (usada pelo DogWorld) -----------------------------------------

## Caminho pelo piso, desviando dos móveis. Pontos em pixels do fundo.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return _nav.get_point_path(_nearest_walkable(from), _nearest_walkable(to))


func random_floor_point() -> Vector2:
	return _nav.get_point_position(_walkable.pick_random())


func _build_navigation() -> void:
	var cells := Vector2i((_background.size / NAV_CELL).ceil())
	_nav.region = Rect2i(Vector2i.ZERO, cells)
	_nav.cell_size = Vector2.ONE * NAV_CELL
	_nav.offset = Vector2.ONE * NAV_CELL / 2.0
	_nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_nav.update()

	var floor_area := _polygon(_room["floor"])
	var blocked: Array[PackedVector2Array] = []
	for data: Dictionary in _room.get("objects", []):
		if data.has("footprint"):
			blocked.append(_polygon(data["footprint"]))

	_walkable.clear()
	for x in cells.x:
		for y in cells.y:
			var cell := Vector2i(x, y)
			var center := _nav.get_point_position(cell)
			var solid := not Geometry2D.is_point_in_polygon(center, floor_area)
			for area in blocked:
				if solid:
					break
				solid = Geometry2D.is_point_in_polygon(center, area)
			_nav.set_point_solid(cell, solid)
			if not solid:
				_walkable.append(cell)


func _nearest_walkable(point: Vector2) -> Vector2i:
	var cell := Vector2i((point / NAV_CELL).floor())
	if _nav.is_in_boundsv(cell) and not _nav.is_point_solid(cell):
		return cell
	var best := _walkable[0]
	for candidate in _walkable:
		if Vector2(candidate).distance_squared_to(Vector2(cell)) < Vector2(best).distance_squared_to(Vector2(cell)):
			best = candidate
	return best


# --- Montagem ----------------------------------------------------------------

func _spawn_objects() -> void:
	for data: Dictionary in _room.get("objects", []):
		var sprite := Sprite2D.new()
		sprite.name = data["id"]
		sprite.texture = load(data["sprite"])
		# Origem no meio da base do sprite: é o ponto usado na ordenação por Y.
		sprite.centered = false
		sprite.offset = -Vector2(sprite.texture.get_width() / 2.0, sprite.texture.get_height())
		sprite.position = _vec(data["pos"])
		sprite.set_meta("action", data.get("action", ""))
		_world.add_child(sprite)
		_objects.append(sprite)


func _spawn_dog() -> void:
	_dog = DogWorld.new()
	_dog.name = "Tiro"
	_dog.room = self
	_dog.bowl_point = _point("bowl")
	_dog.sleep_point = _point("sleep")
	_dog.sleep_approach = _point("sleep_approach")
	_dog.position = _point("sleep") if GameState.dog.sleeping else _point("dog_start")
	_world.add_child(_dog)


# --- Toque e câmera ----------------------------------------------------------

## Pinça com dois dedos. Toques chegam aqui antes do _gui_input.
##
## O rastreio é defensivo porque navegadores (Safari/iOS) podem avisar o mesmo
## dedo duas vezes ou soltar com outro identificador; um dedo "fantasma" na
## lista transformaria todo arrastar em zoom e bloquearia os toques.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var touch := event as InputEventScreenTouch
	if touch:
		_prune_stale_touches()
		if touch.pressed:
			_erase_touch_near(touch.position, SAME_FINGER_DISTANCE)  # mesmo dedo avisado de novo
			if get_global_rect().has_point(touch.position):
				_set_touch(touch.index, touch.position)
		elif _touches.has(touch.index):
			_touches.erase(touch.index)
		else:
			_erase_touch_near(touch.position, INF)  # soltou com outro identificador
		if _is_pinching():
			_dragged = true  # pinça não conta como toque
		_pinch_distance = _current_pinch_distance()
		return
	var drag := event as InputEventScreenDrag
	if drag and (_touches.has(drag.index) or get_global_rect().has_point(drag.position)):
		if not _touches.has(drag.index):
			_erase_touch_near(drag.position, SAME_FINGER_DISTANCE)  # é o mesmo dedo com outro id
		_set_touch(drag.index, drag.position)
		if _is_pinching():
			var distance := _current_pinch_distance()
			if _pinch_distance > 0.0:
				var points := _touch_positions()
				_zoom_at((points[0] + points[1]) / 2.0 - global_position, _zoom * distance / _pinch_distance)
			_pinch_distance = distance


func _is_pinching() -> bool:
	return _touches.size() >= 2


func _set_touch(index: int, position_on_screen: Vector2) -> void:
	_touches[index] = { "pos": position_on_screen, "time": Time.get_ticks_msec() }


func _touch_positions() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for entry: Dictionary in _touches.values():
		result.append(entry["pos"])
	return result


## Remove o dedo registrado mais perto de `point` (até `max_distance`).
func _erase_touch_near(point: Vector2, max_distance: float) -> void:
	var nearest: Variant = null
	var best := max_distance
	for index: int in _touches:
		var distance: float = (_touches[index]["pos"] as Vector2).distance_to(point)
		if distance <= best:
			best = distance
			nearest = index
	if nearest != null:
		_touches.erase(nearest)


## Dedos sem notícia há muito tempo provavelmente já saíram da tela.
func _prune_stale_touches() -> void:
	var now := Time.get_ticks_msec()
	for index: int in _touches.keys():
		if now - int(_touches[index]["time"]) > TOUCH_STALE_MS:
			_touches.erase(index)


func _current_pinch_distance() -> float:
	if not _is_pinching():
		return 0.0
	var points := _touch_positions()
	return points[0].distance_to(points[1])


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var factor := ZOOM_STEP if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP
		_zoom_at(button.position, _zoom * factor)
		return
	if _is_pinching():
		return  # durante a pinça, não arrasta nem toca
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_press_position = button.position
			_dragged = false
		elif not _dragged:
			_handle_tap(_world.get_local_mouse_position())
		return
	var motion := event as InputEventMouseMotion
	if motion and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		if motion.position.distance_to(_press_position) > TAP_SLOP:
			_dragged = true
		if _dragged:
			_content.position += motion.relative
			_clamp_content()


func _handle_tap(point: Vector2) -> void:
	if _dog.hit_test(point):
		Events.screen_requested.emit(&"pet")
		return
	# Do mais à frente (maior Y) para o mais ao fundo.
	var ordered := _objects.duplicate()
	ordered.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool: return a.position.y > b.position.y)
	for sprite: Sprite2D in ordered:
		var local := point - sprite.position
		if sprite.get_rect().has_point(local) and sprite.is_pixel_opaque(local):
			_flash(sprite)
			_on_object_tapped(sprite.get_meta("action"))
			return
	# Zonas: partes tocáveis do próprio fundo (ex.: porta).
	for zone: Dictionary in _room.get("zones", []):
		if Geometry2D.is_point_in_polygon(point, _polygon(zone["polygon"])):
			_on_object_tapped(zone["action"])
			return


func _on_object_tapped(action: String) -> void:
	match action:
		"fridge":
			Events.sheet_requested.emit("Geladeira", SheetBuilder.inventory_view())
		"stove":
			Events.sheet_requested.emit("Fogão", SheetBuilder.station_view("stove"))
		"bowl":
			Events.sheet_requested.emit("Tigela do Tiro", SheetBuilder.food_picker())
		"sofa":
			var sleeping := not GameState.dog.sleeping
			GameState.set_sleeping(sleeping)
			Events.toast_requested.emit("Hora da soneca!" if sleeping else "Tiro acordou!")
		"door":
			Events.toast_requested.emit("A Horta abre no nível 2!")
		_:
			Events.toast_requested.emit("Em breve!")


func _flash(sprite: Sprite2D) -> void:
	sprite.modulate = Color(1.35, 1.35, 1.35)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)


## Menor zoom: a sala inteira cabe na tela.
func _fit_zoom() -> float:
	return minf(size.x / _content.size.x, size.y / _content.size.y)


func _show_whole_room() -> void:
	_zoom_at(size / 2.0, _fit_zoom())


## Muda o zoom mantendo fixo o ponto da sala sob `pivot` (coordenadas desta tela).
func _zoom_at(pivot: Vector2, new_zoom: float) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return  # ainda sem layout
	new_zoom = clampf(new_zoom, _fit_zoom(), MAX_ZOOM)
	var room_point := (pivot - _content.position) / _zoom
	_zoom = new_zoom
	_content.scale = Vector2.ONE * _zoom
	_content.position = pivot - room_point * _zoom
	_clamp_content()


func _on_resized() -> void:
	_zoom_at(size / 2.0, _zoom)


func _clamp_content() -> void:
	var scaled := _content.size * _content.scale
	var pos := _content.position
	for axis in 2:
		if scaled[axis] <= size[axis]:
			pos[axis] = (size[axis] - scaled[axis]) / 2.0
		else:
			pos[axis] = clampf(pos[axis], size[axis] - scaled[axis], 0.0)
	_content.position = pos


# --- Helpers -----------------------------------------------------------------

func _point(id: String) -> Vector2:
	return _vec(_room["points"][id])


func _vec(value: Array) -> Vector2:
	return Vector2(value[0], value[1])


func _polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for value: Array in points:
		result.append(_vec(value))
	return result
