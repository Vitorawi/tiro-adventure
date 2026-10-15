class_name RoomView
extends Control
## Um ambiente do Mundo (casa, sítio...), montado a partir de data/rooms/<room_id>.json:
## fundo + objetos separados (PixelLab), cada um com uma área no chão (footprint)
## que o Tiro contorna. Objetos com "plot" são canteiros de horta.
## O Tiro só aparece se a sala tiver o ponto "dog_start"; sem "floor" não há caminho
## (sala só de toques). Ações: "plot" ou "place:<id>"/"npc:<id>" (Places).
##
## Arrastar move a câmera; tocar num objeto abre o menu dele (toque preciso no
## desenho, não num retângulo); tocar no Tiro abre a Tela do Pet.
## Coordenadas do JSON estão em pixels da imagem de fundo.

## Qual sala montar (nome do arquivo em data/rooms/).
@export var room_id := "house"
## Mundo dono da sala (data/worlds.json), usado para abrir os lugares ("place:<id>"). Vazio = room_id.
@export var world_id := ""

const MAX_ZOOM := 2.0
const ZOOM_STEP := 1.25
const TAP_SLOP := 12.0
const NAV_CELL := 8
const SAME_FINGER_DISTANCE := 24.0
const TOUCH_STALE_MS := 1000
const SLICE_WIDTH := 4
## Quadros por segundo das animações de móveis (ex.: fogão cozinhando).
const OBJECT_FPS := 8.0

var _room: Dictionary = {}
var _zoom := 1.0
var _touches: Dictionary = {}  # índice do dedo -> { "pos": Vector2, "time": ms } (para a pinça)
var _pinch_distance := 0.0
var _objects: Array[Sprite2D] = []
var _dog: DogWorld
var _dig_spot: Node2D
var _walk_marker: WalkIndicator
var _find_reacted_seed := -1
## Só DEV: desenha os pontos candidatos para revisar o chão.
var dev_show_dig_spots := false
var _npcs: Array[NpcWorld] = []
var _nav := AStarGrid2D.new()
var _walkable: Array[Vector2i] = []
var _press_position := Vector2.ZERO
var _dragged := false
var _object_frame := 0
var _owned_snapshot: Dictionary = {}
var _animals_snapshot: Dictionary = {}
var _region_open_snapshot: Array[bool] = []
var _gated_snapshot: Array[String] = []
var _quests_snapshot := -1
var _labels: Array[Label] = []
var _regions: Array[Node2D] = []
var _route_markers: Array[RouteIndicator] = []
var _ready_counts: Dictionary = {}
var navigation_revision: int = 0
## Seta do "Ir": pulsa sobre o objeto do destino até o próximo toque (ou alguns segundos).
var _pointer: Node2D

@onready var _content: Control = %Content
@onready var _background: TextureRect = %Background
@onready var _world: Node2D = %World


func _ready() -> void:
	_room = Database.room(room_id)
	_background.texture = load(_room["background"])
	_background.size = _background.texture.get_size()
	_content.size = _background.size
	_spawn_objects()
	_build_navigation()
	_spawn_dog()
	if world_id == "":
		world_id = room_id
	_spawn_npcs()
	_sync_friends()
	Events.state_changed.connect(_sync_friends)
	var friend_timer := Timer.new()
	friend_timer.wait_time = 60.0
	friend_timer.autostart = true
	friend_timer.timeout.connect(_sync_friends)
	add_child(friend_timer)
	_spawn_labels()
	_spawn_regions()
	for data: Dictionary in _room.get("route_markers", []):
		var indicator := RouteIndicator.new()
		indicator.group = data.get("group", "")
		indicator.site = data.get("site", "")
		indicator.position = _vec(data.pos)
		indicator.z_index = 5
		_world.add_child(indicator)
		_route_markers.append(indicator)
	if _room.get("points", {}).has("walk_marker"):
		_walk_marker = WalkIndicator.new()
		_walk_marker.position = _point("walk_marker")
		_walk_marker.z_index = 5
		_world.add_child(_walk_marker)
	Events.state_changed.connect(_refresh_ownership)
	Events.state_changed.connect(_refresh_gated)
	Events.state_changed.connect(_refresh_find)
	Events.world_activity.connect(_on_world_activity)
	_refresh_ownership()
	_refresh_gated()
	_refresh_find()
	%ZoomIn.pressed.connect(func() -> void: _zoom_at(size / 2.0, _zoom * ZOOM_STEP))
	%ZoomOut.pressed.connect(func() -> void: _zoom_at(size / 2.0, _zoom / ZOOM_STEP))
	resized.connect(_on_resized)
	_show_whole_room.call_deferred()
	var timer := Timer.new()
	timer.wait_time = 1.0 / OBJECT_FPS
	timer.timeout.connect(_animate_objects)
	add_child(timer)
	timer.start()


# --- Navegação (usada pelo DogWorld) -----------------------------------------

## Caminho pelo piso, desviando dos móveis. Pontos em pixels do fundo.
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if _walkable.is_empty():
		return PackedVector2Array()
	return _nav.get_point_path(_nearest_walkable(from), _nearest_walkable(to))


func random_floor_point(from: Vector2) -> Vector2:
	if _walkable.is_empty():
		return from
	for attempt in 20:
		var target := _nav.get_point_position(_walkable.pick_random())
		if not find_path(from, target).is_empty():
			return target
	return from


## Ponto do chão a até `radius` px de `center` (quem acompanha alguém usa isto).
func floor_point_near(center: Vector2, radius: float) -> Vector2:
	if _walkable.is_empty():
		return center
	for attempt in 16:
		var point := center + Vector2.from_angle(randf() * TAU) * randf_range(10.0, radius)
		var cell := Vector2i((point / NAV_CELL).floor())
		if _nav.is_in_boundsv(cell) and not _nav.is_point_solid(cell):
			return _nav.get_point_position(cell)
	return nearest_floor_point(center)


## Personagem do mundo pelo id (null se não estiver nesta sala).
func npc_node(npc_id: String) -> NpcWorld:
	for npc: NpcWorld in _npcs:
		if npc.npc_id == npc_id:
			return npc
	return null


## Reutiliza a IA, escala e navegação dos NPCs. Só recria quem entrou/saiu da janela.
func _sync_friends() -> void:
	var desired: Array[String] = []
	if world_id == "park":
		for id: String in GameState.friends_present():
			if str(GameState.friend_def(id).get("npc", "")) == "":
				desired.append(id)
	elif world_id == "house":
		for id: String in Database.friends.friends:
			if bool(GameState.friend_state.entry(id).visit_pending):
				desired.append(id)
	for npc: NpcWorld in _npcs.duplicate():
		if npc.npc_id != "":
			continue
		if npc.friend_id not in desired:
			_npcs.erase(npc)
			npc.react()
			var goodbye := npc.create_tween()
			goodbye.tween_property(npc, "modulate:a", 0.0, 0.5)
			goodbye.tween_callback(npc.queue_free)
		else:
			desired.erase(npc.friend_id)
	for id: String in desired:
		var npc := NpcWorld.new()
		npc.friend_id = id
		npc.friend_visit = world_id == "house"
		npc.room = self
		npc.scale = Vector2.ONE * float(_room.get("dog_scale", 1.0))
		npc.home = nearest_floor_point(_point("friend_visit" if npc.friend_visit else "friend_1"))
		npc.position = floor_point_near(npc.home, 24.0)
		_world.add_child(npc)
		_npcs.append(npc)


func nearest_floor_point(point: Vector2) -> Vector2:
	return _nav.get_point_position(_nearest_walkable(point)) if not _walkable.is_empty() else point


func _build_navigation() -> void:
	if not _room.has("floor"):
		return  # sala sem chão andável: só toques
	var cells := Vector2i((_background.size / NAV_CELL).ceil())
	_nav.region = Rect2i(Vector2i.ZERO, cells)
	_nav.cell_size = Vector2.ONE * NAV_CELL
	_nav.offset = Vector2.ONE * NAV_CELL / 2.0
	_nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_nav.update()

	var floor_area := _polygon(_room["floor"])
	var margin: float = float(_room.get("navigation_margin", NAV_CELL / 2.0))
	var blocked: Array[PackedVector2Array] = []
	for obstacle: Dictionary in _room.get("obstacles", []):
		blocked.append(_polygon(obstacle["polygon"]))
	for region: Dictionary in _room.get("regions", []):
		if region_error(region) != "":
			blocked.append(_polygon(region.polygon))
	for data: Dictionary in _room.get("objects", []):
		if data.has("footprint"):
			if data.has("animal_station") and int(data.animal_slot) >= GameState.animal_count(data.animal_station):
				continue
			if data.has("upgrade") and not GameState.has_upgrade(data.upgrade):
				continue
			if data.has("requirements") and GameState.requirement_error(data.requirements) != "":
				continue
			if data.has("hide_seen") and GameState.progress.seen.get(data.hide_seen, false):
				continue
			blocked.append(_polygon(data["footprint"]))

	_walkable.clear()
	for x in cells.x:
		for y in cells.y:
			var cell := Vector2i(x, y)
			var center := _nav.get_point_position(cell)
			var solid := false
			# Margem das patas nos mapas externos; inclui os cantos da célula
			# para os segmentos diagonais não cortarem as bordas dos obstáculos.
			for offset: Vector2 in [Vector2.ZERO, Vector2(-margin, -margin), Vector2(margin, -margin), Vector2(-margin, margin), Vector2(margin, margin)]:
				var sample := center + offset
				solid = not Geometry2D.is_point_in_polygon(sample, floor_area)
				for area in blocked:
					solid = solid or Geometry2D.is_point_in_polygon(sample, area)
				if solid:
					break
			_nav.set_point_solid(cell, solid)
			if not solid:
				_walkable.append(cell)
	navigation_revision += 1


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
		if data.get("slice", false):
			_spawn_sliced(load(data["sprite"]), _vec(data["pos"]))
			continue
		var sprite := Sprite2D.new()
		sprite.name = data["id"]
		sprite.texture = load(data["sprite"])
		# Origem no meio da base do sprite: é o ponto usado na ordenação por Y.
		sprite.centered = false
		sprite.offset = -Vector2(sprite.texture.get_width() / 2.0, sprite.texture.get_height())
		sprite.position = _vec(data["pos"])
		# Objetos apoiados em móveis podem ficar acima das fatias do cenário.
		sprite.z_index = int(data.get("z_index", 0))
		sprite.scale = Vector2.ONE * float(data.get("scale", 1.0))
		sprite.set_meta("action", data.get("action", ""))
		sprite.set_meta("decoration", data.get("decoration", false))
		if data.has("animal_station"):
			sprite.set_meta("animal_station", data.animal_station)
			sprite.set_meta("animal_slot", int(data.animal_slot))
		if data.has("route_group"):
			var indicator := RouteIndicator.new()
			indicator.name = "RouteIndicator"
			indicator.group = data.route_group
			indicator.z_index = 2
			sprite.add_child(indicator)
		if data.get("animal_idle", false):
			sprite.set_meta("idle_offset", sprite.offset)
		sprite.set_meta("approach", _vec(data.get("approach", data["pos"])))
		if data.has("region"):
			sprite.set_meta("region", data.region)
		if data.has("requirements"):
			sprite.set_meta("requirements", data.requirements)
		if data.has("seen_sprite"):
			sprite.set_meta("seen_sprite", data.seen_sprite)
		if data.has("hide_seen"):
			sprite.set_meta("hide_seen", data.hide_seen)
		if data.has("station"):
			sprite.set_meta("station", data.station)
			var indicator := StationIndicator.new()
			indicator.name = "ProductionIndicator"
			indicator.station_id = data.station
			indicator.z_index = 2
			sprite.add_child(indicator)
		if data.has("upgrade"):
			sprite.set_meta("upgrade", data.upgrade)
			var marker := Label.new()
			marker.name = "PurchaseMarker"
			marker.text = "+"
			marker.position = Vector2(-14, -28)
			marker.size = Vector2(28, 28)
			marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			marker.add_theme_font_size_override("font_size", 26)
			marker.add_theme_color_override("font_color", Color("fff0c0"))
			var marker_box := StyleBoxFlat.new()
			marker_box.bg_color = Color("67573f")
			marker_box.border_color = Color("edc56b")
			marker_box.set_border_width_all(2)
			marker_box.set_corner_radius_all(5)
			marker.add_theme_stylebox_override("normal", marker_box)
			marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sprite.add_child(marker)
		if data.has("busy_frames"):
			# Estação com animação enquanto produz (ex.: fogão cozinhando).
			sprite.set_meta("station", data["station"])
			sprite.set_meta("base_texture", sprite.texture)
			sprite.set_meta("busy_frames", _load_frames(data["busy_frames"]))
		if data.has("plot"):
			# Canteiro: a planta (broto ou pronta) é um sprite por cima do solo.
			sprite.set_meta("plot", int(data["plot"]))
			var crop := Sprite2D.new()
			crop.name = "Crop"
			crop.position = Vector2(0, -sprite.texture.get_height() / 2.0 + float(data.get("crop_offset", 0)))
			crop.offset = Vector2(0, -8)
			sprite.add_child(crop)
			var indicator := PlotIndicator.new()
			indicator.name = "Indicator"
			indicator.plot_index = int(data["plot"])
			indicator.z_index = 2
			sprite.add_child(indicator)
		_world.add_child(sprite)
		_objects.append(sprite)


## PNGs de uma pasta, em ordem de nome (frame_00.png, frame_01.png...).
func _load_frames(folder: String) -> Array[Texture2D]:
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	var frames: Array[Texture2D] = []
	for file: String in files:
		if file.ends_with(".png"):
			frames.append(load(folder + file))
	return frames


## Troca o quadro dos móveis animados; parados mostram a imagem base.
func _animate_objects() -> void:
	_refresh_find()
	if not is_visible_in_tree():
		return
	_object_frame += 1
	if _walk_marker:
		_walk_marker.refresh()
	for indicator: RouteIndicator in _route_markers:
		indicator.refresh()
	for sprite in _objects:
		if sprite.has_node("RouteIndicator"):
			(sprite.get_node("RouteIndicator") as RouteIndicator).refresh()
		if sprite.has_meta("idle_offset"):
			var phase := float(_object_frame) / OBJECT_FPS + sprite.position.x
			sprite.offset = (sprite.get_meta("idle_offset") as Vector2) + Vector2(sin(phase * 1.5) * 1.3, sin(phase) * 0.8)
		if sprite.has_meta("station") and (not sprite.has_meta("upgrade") or GameState.has_upgrade(sprite.get_meta("upgrade"))):
			(sprite.get_node("ProductionIndicator") as StationIndicator).refresh()
			var station_id: String = sprite.get_meta("station")
			var ready := GameState.station(station_id).ready_count(GameState.now())
			if ready > int(_ready_counts.get(station_id, 0)) and _dog:
				_dog.react_at(&"ready", sprite.get_meta("approach"))
			_ready_counts[station_id] = ready
		if sprite.has_meta("plot"):
			_update_plot(sprite)
		if not sprite.has_meta("busy_frames"):
			continue
		var frames: Array[Texture2D] = sprite.get_meta("busy_frames")
		var busy := GameState.station(sprite.get_meta("station")).is_busy(GameState.now())
		sprite.texture = frames[_object_frame % frames.size()] if busy and not frames.is_empty() else sprite.get_meta("base_texture")


## Mostra o broto enquanto cresce e a planta madura quando dá para colher.
func _update_plot(sprite: Sprite2D) -> void:
	var index: int = sprite.get_meta("plot")
	var crop: Sprite2D = sprite.get_node("Crop")
	var texture: Texture2D = null
	var status := GameState.plot_status(index)
	var progress := GameState.plot_progress(index)
	sprite.self_modulate = Color("777e69") if status == "locked" else Color.WHITE
	match status:
		"growing":
			texture = Database.farm_texture("sprout") if progress < 0.33 else Database.crop_texture(GameState.plot(index)["crop"])
			crop.scale = Vector2.ONE * lerpf(0.55, 0.9, progress)
		"ready":
			texture = Database.crop_texture(GameState.plot(index)["crop"])
	if crop.texture != texture:
		crop.texture = texture
		if texture and GameState.plot_status(index) == "ready":
			_pop(crop)
	# A textura adulta também aparece no meio do crescimento: detectar a mudança de estado.
	elif status == "ready" and sprite.get_meta("plot_status", "") != "ready":
		_pop(crop)
	sprite.set_meta("plot_status", status)
	(sprite.get_node("Indicator") as PlotIndicator).refresh()


func _refresh_ownership() -> void:
	_sync_dog()
	for npc: NpcWorld in _npcs:
		npc.visible = GameState.progress.npc_visible(npc.npc_id) if npc.npc_id != "" else true
	var opened: Array[bool] = []
	for data: Dictionary in _room.get("regions", []):
		opened.append(region_error(data) == "")
	if _owned_snapshot == GameState.progress.owned and _animals_snapshot == GameState.animals and _region_open_snapshot == opened and _quests_snapshot == GameState.progress.claimed_quests.size() and has_meta("ownership_ready"):
		return
	set_meta("ownership_ready", true)
	_owned_snapshot = GameState.progress.owned.duplicate()
	_animals_snapshot = GameState.animals.duplicate()
	_region_open_snapshot = opened
	_quests_snapshot = GameState.progress.claimed_quests.size()
	for sprite: Sprite2D in _objects:
		if sprite.has_meta("upgrade"):
			var purchased := GameState.has_upgrade(sprite.get_meta("upgrade"))
			sprite.self_modulate.a = 1.0 if purchased else 0.0
			var region_locked := false
			for data: Dictionary in _room.get("regions", []):
				if data.id == sprite.get_meta("region", ""):
					region_locked = region_error(data) != ""
			# "+" só aparece quando a história já libera a compra (revelar aos poucos).
			var available := GameState.requirement_error(Database.progression.upgrades.get(sprite.get_meta("upgrade"), {}).get("requirements", {})) == ""
			sprite.get_node("PurchaseMarker").visible = not purchased and not region_locked and available and not sprite.get_meta("decoration", false)
		if sprite.has_meta("animal_station"):
			var roster := GameState.animal_roster(sprite.get_meta("animal_station"))
			var slot: int = sprite.get_meta("animal_slot")
			sprite.visible = slot < roster.size()
			if sprite.visible:
				var animal: Dictionary = Database.animals[roster[slot]]
				sprite.texture = load(animal.sprite)
				sprite.offset = -Vector2(sprite.texture.get_width() / 2.0, sprite.texture.get_height())
				sprite.set_meta("idle_offset", sprite.offset)
				sprite.scale = Vector2.ONE * float(animal.map_scale)
	for region: Node2D in _regions:
		region.visible = region_error(region.get_meta("data")) != ""
	for tag: Label in _labels:
		if tag.has_meta("requirements"):
			var blocked := GameState.requirement_error(tag.get_meta("requirements")) != ""
			tag.visible = blocked if tag.get_meta("locked_label", false) else not blocked
		var upgrade: String = tag.get_meta("upgrade", "")
		if upgrade != "":
			tag.visible = GameState.has_upgrade(upgrade)
		var locked_upgrade: String = tag.get_meta("locked_upgrade", "")
		if locked_upgrade != "":
			tag.visible = not GameState.has_upgrade(locked_upgrade)
	_place_labels()
	_build_navigation()
	refresh_sleep_points()


## Onde o Tiro dorme: caminha (no chão) > sofá > chão perto do sofá.
func refresh_sleep_points() -> void:
	if _dog == null:
		return
	var points: Dictionary = _room.get("points", {})
	if GameState.has_upgrade("dog_bed") and points.has("bed_sleep") and points.has("bed_approach"):
		_dog.sleep_point = _point("bed_sleep")
		_dog.sleep_approach = _point("bed_approach")
	elif points.has("sleep") and points.has("sleep_approach"):
		_dog.sleep_approach = _point("sleep_approach")
		_dog.sleep_point = _point("sleep") if GameState.has_upgrade("sofa") else _point("sleep_approach")


## Regiões podem abrir por compra ou por requisitos da aventura/história.
func region_error(data: Dictionary) -> String:
	var requirements: Dictionary = data.get("requirements", {}).duplicate(true)
	if data.has("upgrade"):
		var owned: Array = requirements.get("owned", []).duplicate()
		owned.append(data.upgrade)
		requirements["owned"] = owned
	return GameState.requirement_error(requirements)


## Etiquetas sobre o que dá para tocar ("label" + "label_pos" em zonas e objetos):
## mostram ao jogador onde fica cada coisa sem precisar adivinhar.
func _spawn_labels() -> void:
	for data: Dictionary in _room.get("zones", []) + _room.get("objects", []) + _room.get("regions", []):
		if not data.has("label"):
			continue
		var tag := Label.new()
		tag.text = data.label
		tag.add_theme_font_size_override("font_size", 16)
		tag.add_theme_color_override("font_color", Color("fff4dc"))
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.29, 0.18, 0.13, 0.85)
		box.border_color = Color("edc56b")
		box.set_border_width_all(1)
		box.set_corner_radius_all(6)
		box.content_margin_left = 6
		box.content_margin_right = 6
		tag.add_theme_stylebox_override("normal", box)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tag.z_index = 4
		tag.z_as_relative = false
		tag.set_meta("anchor", _vec(data.get("label_pos", data.get("pos", [0, 0]))))
		tag.set_meta("detail_label", data.get("detail_label", false))
		tag.set_meta("overview_label", data.get("overview_label", false))
		tag.set_meta("tap_data", data)
		if data.has("hide_seen"):
			tag.set_meta("hide_seen", data.hide_seen)
		if data.has("requirements"):
			tag.set_meta("requirements", data.requirements)
			tag.set_meta("locked_label", data.get("locked_label", false))
		if data.has("upgrade"):
			tag.set_meta("locked_upgrade" if data.get("locked_label", false) else "upgrade", data.upgrade)
		_world.add_child(tag)
		tag.reset_size()
		_labels.append(tag)
	_place_labels()


## Áreas laterais fechadas: chão escurecido e cerca sobre a divisa.
func _spawn_regions() -> void:
	for data: Dictionary in _room.get("regions", []):
		var region := Node2D.new()
		region.name = "Region_" + str(data.id)
		region.z_index = 0  # sombra e cerca ficam atrás dos objetos (galinheiro, plantas, Tiro)
		region.set_meta("data", data)
		var shade := Polygon2D.new()
		shade.polygon = _polygon(data.polygon)
		shade.color = Color(0.16, 0.12, 0.08, 0.45)
		region.add_child(shade)
		var gate := _polygon(data.gate)
		for height: float in [-12.0, -22.0]:
			var rail := Line2D.new()
			for point: Vector2 in gate:
				rail.add_point(point + Vector2(0, height))
			rail.width = 4.0
			rail.default_color = Color("a67843")
			region.add_child(rail)
		var posts := maxi(2, ceili(gate[0].distance_to(gate[1]) / 24.0))
		for i in range(posts + 1):
			var foot := gate[0].lerp(gate[1], float(i) / posts)
			var post := Line2D.new()
			post.points = PackedVector2Array([foot, foot - Vector2(0, 30)])
			post.width = 5.0
			post.default_color = Color("654529")
			region.add_child(post)
		_world.add_child(region)
		_world.move_child(region, 0)
		_regions.append(region)


func _on_world_activity(kind: StringName, subject: String, plot_index: int) -> void:
	if not _dog or not is_visible_in_tree():
		return
	# Início da história: o Tiro é solto na porta e corre para dentro de casa.
	if kind == &"arrive" and _room.get("points", {}).has("door_in"):
		_dog.position = nearest_floor_point(_point("door_in"))
		_dog.react_at(&"happy", _point("dog_start"))
		return
	for sprite: Sprite2D in _objects:
		var matches: bool = (kind == &"harvest" and sprite.get_meta("plot", -1) == plot_index) or (kind in [&"collect", &"feed_animal"] and sprite.get_meta("station", "") == subject) or (kind == &"build" and sprite.get_meta("upgrade", "") == subject)
		if matches:
			_dog.react_at(kind, sprite.get_meta("approach", sprite.position))
			return


## Etiquetas mantêm o mesmo tamanho na tela em qualquer zoom (escala 1/zoom),
## centradas no ponto "label_pos".
func _place_labels() -> void:
	for tag in _labels:
		var upgrade: String = tag.get_meta("upgrade", "")
		var locked: String = tag.get_meta("locked_upgrade", "")
		tag.visible = (upgrade == "" or GameState.has_upgrade(upgrade)) and (locked == "" or not GameState.has_upgrade(locked))
		if tag.has_meta("requirements"):
			var blocked := GameState.requirement_error(tag.get_meta("requirements")) != ""
			tag.visible = tag.visible and (blocked if tag.get_meta("locked_label", false) else not blocked)
		if tag.has_meta("hide_seen") and GameState.progress.seen.get(tag.get_meta("hide_seen"), false):
			tag.visible = false
		if tag.get_meta("detail_label", false):
			tag.visible = tag.visible and _zoom >= 0.5
		if tag.get_meta("overview_label", false):
			tag.visible = tag.visible and _zoom < 0.5
		tag.scale = Vector2.ONE / _zoom
		tag.position = (tag.get_meta("anchor") as Vector2) - tag.size * tag.scale / 2.0


## Pulinho de "ficou pronto".
func _pop(node: Node2D) -> void:
	node.scale = Vector2(0.6, 0.6)
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(node, "scale", Vector2.ONE, 0.35)


## Peça comprida em diagonal (ex.: ilha recortada do fundo): um único ponto de
## ordenação erraria de um lado. Fatia em colunas, cada uma ordenada pela própria
## base, para o Tiro passar atrás/na frente certo. Não é tocável.
func _spawn_sliced(texture: Texture2D, pos: Vector2) -> void:
	var image := texture.get_image()
	var top_left := pos - Vector2(texture.get_width() / 2.0, texture.get_height())
	for x0 in range(0, image.get_width(), SLICE_WIDTH):
		var width := mini(SLICE_WIDTH, image.get_width() - x0)
		var base := -1
		for x in range(x0, x0 + width):
			for y in range(image.get_height() - 1, base, -1):
				if image.get_pixel(x, y).a > 0.1:
					base = y
					break
		if base < 0:
			continue  # coluna vazia
		var strip := Sprite2D.new()
		strip.texture = texture
		strip.centered = false
		strip.region_enabled = true
		strip.region_rect = Rect2(x0, 0, width, image.get_height())
		strip.position = top_left + Vector2(x0, base)
		strip.offset = Vector2(0, -base)
		_world.add_child(strip)


## O Tiro sai da sala enquanto passeia e reaparece no "dog_start" quando volta.
func _sync_dog() -> void:
	if GameState.walking() and is_instance_valid(_dog):
		_dog.queue_free()
		_dog = null
	elif not GameState.walking() and _dog == null:
		_spawn_dog()


func _spawn_dog() -> void:
	if not _room.get("points", {}).has("dog_start") or GameState.walking():
		return  # sala sem o Tiro (ou o Tiro está passeando)
	_dog = DogWorld.new()
	_dog.name = "Tiro"
	_dog.room = self
	_dog.scale = Vector2.ONE * float(_room.get("dog_scale", 1.0))
	var points: Dictionary = _room["points"]
	if points.has("bowl"):
		_dog.bowl_point = _point("bowl")
	refresh_sleep_points()
	_dog.position = _dog.sleep_point if GameState.dog.sleeping and _dog.sleep_point != Vector2.INF else nearest_floor_point(_point("dog_start"))
	_world.add_child(_dog)


## Personagens do mundo (worlds.json → npcs) que têm ponto "npc_<id>" nesta sala.
func _spawn_npcs() -> void:
	var points: Dictionary = _room.get("points", {})
	for npc_id: String in Database.worlds.get(world_id, {}).get("npcs", []):
		if not points.has("npc_" + npc_id):
			continue
		var npc := NpcWorld.new()
		npc.name = "Npc_" + npc_id
		npc.npc_id = npc_id
		for id: String in Database.friends.friends:
			if GameState.friend_def(id).get("npc", "") == npc_id:
				npc.friend_id = id
		npc.room = self
		npc.scale = Vector2.ONE * float(_room.get("dog_scale", 1.0)) * float(Database.npcs.get(npc_id, {}).get("world_scale", 1.0))
		npc.home = nearest_floor_point(_point("npc_" + npc_id))
		npc.position = npc.home
		npc.visible = GameState.progress.npc_visible(npc_id)
		_world.add_child(npc)
		_npcs.append(npc)


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


## Seta pulsando sobre o objeto/zona com a ação ("place:stove", "npc:bloblo", "market:orders"
## ou "plot" = primeiro canteiro). Mostra o jogador ONDE fica a coisa. Devolve se achou o alvo.
func point_at(action: String) -> bool:
	clear_pointer()
	var anchor := Vector2.INF
	if action == "find":
		if is_instance_valid(_dig_spot):
			anchor = _dig_spot.position - Vector2(0, 16)
		elif not _room.get("dig_spots", []).is_empty():
			anchor = _vec(_room.dig_spots[0])
	for npc: NpcWorld in _npcs:
		if npc.visible and (action == "npc:" + npc.npc_id or (npc.friend_id != "" and action in ["friend:" + npc.friend_id, "friend_visit:" + npc.friend_id, "place:friends"])):
			anchor = npc.head_point()
	if action.begins_with("buy:"):
		# Compra: a seta vai no "+" do objeto (sprite com "upgrade" ainda não comprado).
		var upgrade_id := action.trim_prefix("buy:")
		for sprite in _objects:
			if sprite.get_meta("upgrade", "") == upgrade_id and not GameState.has_upgrade(upgrade_id) and not sprite.get_meta("decoration", false):
				anchor = sprite.position + Vector2(0, -44)
				break
		if anchor == Vector2.INF:
			action = Places.upgrade_place_action(upgrade_id)
	for sprite in _objects:
		if anchor != Vector2.INF:
			break
		if action == "plot" and sprite.has_meta("plot") or sprite.get_meta("action", "") == action:
			anchor = sprite.position - Vector2(0, sprite.texture.get_height())
			break
	if anchor == Vector2.INF:
		for zone: Dictionary in _room.get("zones", []):
			if zone.get("action", "") == action:
				anchor = _vec(zone.get("label_pos", [0, 0])) if zone.has("label_pos") else _polygon(zone.polygon)[0]
				anchor.y -= 12  # acima da etiqueta
				break
	if anchor == Vector2.INF:
		return false
	# Em mapas maiores, o destino pode estar fora da parte visível da câmera. Numa sala recém-aberta
	# o tamanho e o enquadramento inicial só se acertam depois de alguns quadros: confere de novo.
	_reveal(anchor)
	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		if is_instance_valid(_pointer):
			_reveal(anchor))
	_pointer = Node2D.new()
	_pointer.name = "Pointer"
	_pointer.z_index = 5
	_pointer.z_as_relative = false
	_pointer.position = anchor
	_pointer.scale = Vector2.ONE / _zoom
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([Vector2(-14, -34), Vector2(14, -34), Vector2(14, -20), Vector2(24, -20), Vector2(0, 0), Vector2(-24, -20), Vector2(-14, -20)])
	arrow.color = Color("ffd23f")
	var outline := Line2D.new()
	outline.points = arrow.polygon
	outline.closed = true
	outline.width = 3.0
	outline.default_color = Color("4a2e21")
	arrow.add_child(outline)
	_pointer.add_child(arrow)
	_world.add_child(_pointer)
	var bounce := _pointer.create_tween().set_loops()
	bounce.tween_property(arrow, "position:y", -10.0, 0.35).set_trans(Tween.TRANS_SINE)
	bounce.tween_property(arrow, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(5.0).timeout.connect(func() -> void:
		if is_instance_valid(_pointer) and _pointer.position == anchor:
			clear_pointer())
	return true


## Leva a câmera até `anchor` (coordenadas da sala) se ele estiver fora da parte visível.
func _reveal(anchor: Vector2) -> void:
	var on_screen := _content.position + anchor * _zoom
	if size.x > 72.0 and size.y > 96.0 and not Rect2(Vector2(36, 48), size - Vector2(72, 96)).has_point(on_screen):
		_content.position = size / 2.0 - anchor * _zoom
		_clamp_content()


func clear_pointer() -> void:
	if is_instance_valid(_pointer):
		_pointer.queue_free()
	_pointer = null


func _handle_tap(point: Vector2) -> void:
	clear_pointer()
	if is_instance_valid(_dig_spot):
		var radius := 28.0 / maxf(_zoom, 0.01)
		var dog_near := _dog and _dog.position.distance_to(_dig_spot.position) < 40.0
		if point.distance_to(_dig_spot.position) <= radius or (dog_near and _dog.hit_test(point)):
			_dig_find()
			return
	if _tap_label(point):
		return
	for region: Dictionary in _room.get("regions", []):
		if region_error(region) != "" and Geometry2D.is_point_in_polygon(point, _polygon(region.polygon)):
			if region.has("action"):
				Places.run(world_id, region.action)
			elif region.has("upgrade"):
				Events.sheet_requested.emit(region.get("label", "Expandir"), ProgressionUi.purchase(region.upgrade))
			else:
				Places.run(world_id, region.get("action", ""))
			return
	if _walk_marker and _walk_marker.active() and _walk_marker.hit_rect.has_point(point - _walk_marker.position):
		_collect_walk()
		return
	for indicator: RouteIndicator in _route_markers:
		if indicator.active() and indicator.hit_rect.has_point(point - indicator.position):
			if indicator.site != "" and GameState.gathering_ready_count(indicator.site) > 0:
				_collect_site(indicator.site, indicator.position)
			else:
				Places.run(world_id, "place:" + indicator.site)
			return
	for npc: NpcWorld in _npcs:
		if npc.visible and npc.hit_test(point):
			if npc.friend_visit:
				var reason := GameState.collect_friend_visit(npc.friend_id)
				if reason != "":
					Events.toast_requested.emit(reason)
			elif npc.friend_id != "" and GameState.friend_unlocked(npc.friend_id):
				npc.react()
				FriendUi.open(npc.friend_id)
			elif npc.is_decor():
				npc.react()
			else:
				Places.run(world_id, "npc:" + npc.npc_id)
			return
	if _dog and _dog.hit_test(point):
		Events.screen_requested.emit(&"wishes" if _dog.has_balloon() else &"pet")
		return
	# Do mais à frente (maior Y) para o mais ao fundo.
	var ordered := _objects.duplicate()
	ordered.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool: return a.position.y > b.position.y)
	for sprite: Sprite2D in ordered:
		if sprite.has_node("RouteIndicator"):
			var indicator := sprite.get_node("RouteIndicator") as RouteIndicator
			if indicator.active() and indicator.hit_rect.has_point((point - sprite.position) / sprite.scale):
				_on_object_tapped(sprite.get_meta("action"), sprite)
				return
		if sprite.has_node("ProductionIndicator"):
			var indicator := sprite.get_node("ProductionIndicator") as StationIndicator
			if GameState.has_upgrade(indicator.station_id) and not GameState.station(indicator.station_id).queue.is_empty() and indicator.hit_rect.has_point(point - sprite.position):
				_on_object_tapped(sprite.get_meta("action"), sprite)
				return
		if sprite.has_node("Indicator"):
			var index := int(sprite.get_meta("plot"))
			var indicator := sprite.get_node("Indicator") as PlotIndicator
			if GameState.plot_status(index) in ["growing", "ready"] and indicator.hit_rect.has_point(point - sprite.position):
				_on_plot_tapped(index)
				return
	for sprite: Sprite2D in ordered:
		if sprite.has_meta("upgrade") and not GameState.has_upgrade(sprite.get_meta("upgrade")):
			if sprite.get_meta("decoration", false) or not sprite.get_node("PurchaseMarker").visible:
				continue
			if Rect2(sprite.position + Vector2(-24, -36), Vector2(48, 48)).has_point(point):
				Events.sheet_requested.emit("Construir", ProgressionUi.purchase(sprite.get_meta("upgrade")))
				return
			continue
		if _hits(sprite, point - sprite.position) or (sprite.has_node("Crop") and _hits(sprite.get_node("Crop"), point - sprite.position - sprite.get_node("Crop").position)):
			_flash(sprite)
			_on_object_tapped(sprite.get_meta("action"), sprite)
			return
	# Zonas: partes tocáveis do próprio fundo (ex.: porta).
	for zone: Dictionary in _room.get("zones", []):
		if Geometry2D.is_point_in_polygon(point, _polygon(zone["polygon"])):
			_on_object_tapped(zone["action"])
			return


## Tocar na etiqueta de um lugar (ex.: "Caverna") faz o mesmo que tocar no objeto dele.
## A área de toque ganha folga para o polegar. Devolve true se tratou o toque.
func _tap_label(point: Vector2) -> bool:
	for i in range(_labels.size() - 1, -1, -1):
		var tag := _labels[i]
		if not tag.visible or not tag.has_meta("tap_data"):
			continue
		var pad := Vector2(8, 8) / _zoom
		var rect := Rect2(tag.position - pad, tag.size * tag.scale + pad * 2.0)
		if not rect.has_point(point):
			continue
		var data: Dictionary = tag.get_meta("tap_data")
		var upgrade: String = data.get("upgrade", "")
		if data.has("polygon") and data.has("gate"):  # região fechada
			if data.has("action"):
				Places.run(world_id, data.action)
			elif upgrade != "":
				Events.sheet_requested.emit(data.get("label", "Expandir"), ProgressionUi.purchase(upgrade))
			else:
				continue
			return true
		if upgrade != "" and not GameState.has_upgrade(upgrade):
			Events.sheet_requested.emit("Construir", ProgressionUi.purchase(upgrade))
			return true
		var action: String = data.get("action", "")
		if action == "":
			continue
		var target: Sprite2D = null
		if data.has("pos"):
			var pos := _vec(data.pos)
			for sprite: Sprite2D in _objects:
				if sprite.get_meta("action", "") == action and sprite.position.distance_to(pos) < 1.0:
					target = sprite
					break
		if target:
			_flash(target)
		_on_object_tapped(action, target)
		return true
	return false


## Canteiro vazio abre as sementes; crescendo mostra quanto falta; pronto colhe.
func _on_plot_tapped(index: int) -> void:
	if GameState.plot_status(index) == "locked" and not GameState.has_upgrade("farm") and GameState.requirement_error(Database.progression.upgrades.farm.get("requirements", {})) != "":
		Places.open_npc("bloblo")
		return
	if GameState.water_error(index) == "":
		GameState.water(index)
		_water_fx(index)
		return
	match GameState.plot_status(index):
		"locked":
			Events.sheet_requested.emit("Expandir o sítio", SheetBuilder.plot_purchase(index) if GameState.has_upgrade("farm") else ProgressionUi.purchase("farm"))
		"empty":
			Events.sheet_requested.emit("Canteiro", SheetBuilder.seed_picker(index))
		"growing":
			Events.sheet_requested.emit("Plantação", SheetBuilder.growing_plot(index))
		"ready":
			var reward := int(Database.crops[GameState.plot(index)["crop"]].get("coins", 0))
			var origin := Vector2(-1.0, -1.0)
			for sprite: Sprite2D in _objects:
				if sprite.has_meta("plot") and int(sprite.get_meta("plot")) == index:
					origin = _screen_point(sprite.position)
			Events.items_gained.emit(GameState.harvest(index), reward, origin)


## Gotinhas caem sobre o canteiro regado: o ícone desce e some, mais quatro pontinhos azuis.
func _water_fx(index: int) -> void:
	for sprite: Sprite2D in _objects:
		if not sprite.has_meta("plot") or int(sprite.get_meta("plot")) != index:
			continue
		var drop := Sprite2D.new()
		drop.texture = UiKit.ui_icon("action_water")
		drop.position = Vector2(0, -54)
		drop.z_index = 5
		sprite.add_child(drop)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(drop, "position:y", -10.0, 0.6)
		tween.tween_property(drop, "modulate:a", 0.0, 0.6).set_delay(0.2)
		tween.chain().tween_callback(drop.queue_free)
		for i in 4:
			var dot := ColorRect.new()
			dot.color = Color("5aa9e6")
			dot.size = Vector2(3, 3)
			dot.position = Vector2(-12 + i * 8, -50)
			dot.z_index = 5
			sprite.add_child(dot)
			var fall := create_tween().set_parallel(true)
			fall.tween_property(dot, "position:y", -6.0, 0.5).set_delay(0.08 * i)
			fall.tween_property(dot, "modulate:a", 0.0, 0.2).set_delay(0.4 + 0.08 * i)
			fall.chain().tween_callback(dot.queue_free)
		return


## Ponto da sala (coordenadas do mundo) na tela, de onde saltam as miniaturas de recolher.
func _refresh_find() -> void:
	var entry: Dictionary = GameState.finds.worlds.get(world_id, {})
	var spots: Array = _room.get("dig_spots", [])
	if entry.is_empty() or int(entry.pending) <= 0 or spots.is_empty():
		if is_instance_valid(_dig_spot):
			_dig_spot.queue_free()
		_dig_spot = null
		_find_reacted_seed = -1
		return
	if not is_instance_valid(_dig_spot):
		_dig_spot = Node2D.new()
		_dig_spot.name = "DigSpot"
		_dig_spot.position = _vec(spots[int(entry.spot) % spots.size()])
		_world.add_child(_dig_spot)
		var mound := Sprite2D.new()
		mound.texture = load("res://assets/sprites/areas/fx/dig_spot.png")
		mound.position.y = -8
		_dig_spot.add_child(mound)
		var sparkle := Sprite2D.new()
		sparkle.texture = load("res://assets/sprites/areas/fx/fx_sparkle.png")
		sparkle.position = Vector2(4, -22)
		_dig_spot.add_child(sparkle)
		var blink := sparkle.create_tween().set_loops()
		blink.tween_property(sparkle, "modulate:a", 0.15, 0.65)
		blink.tween_property(sparkle, "modulate:a", 1.0, 0.65)
	if _dog and is_visible_in_tree() and not GameState.dog.sleeping and _find_reacted_seed != int(entry.seed):
		_find_reacted_seed = int(entry.seed)
		_dog.react_at(&"sniff", _dig_spot.position)

func _dig_find() -> void:
	var error := GameState.dig_error(world_id)
	if error != "":
		Events.toast_requested.emit(error)
		return
	var point := _dig_spot.position
	if not GameState.dig(world_id, _screen_point(point)).is_empty() and _dog:
		_dog.react_at(&"dig", point)

func show_dig_spots() -> void:
	if not BuildInfo.is_dev(): return
	for index in _room.get("dig_spots", []).size():
		var marker := Polygon2D.new()
		marker.position = _vec(_room.dig_spots[index])
		marker.polygon = PackedVector2Array([Vector2(-6,-6),Vector2(6,-6),Vector2(6,6),Vector2(-6,6)])
		marker.color = Color(1, 0.2, 0.1, 0.8)
		marker.z_index = 5
		_world.add_child(marker)

func _screen_point(point: Vector2) -> Vector2:
	return _world.get_global_transform_with_canvas() * point


## Recolhe direto no mapa as coletas prontas de um local da Natureza.
func _collect_site(site: String, point: Vector2) -> void:
	var data: Dictionary = Database.progression.nature_sites[site]
	var previous_level := GameState.progress.nature_level(site)
	var error := GameState.collect_gathering_all(site)
	if error != "":
		if error.ends_with("sem espaço"):
			Events.toast_requested.emit(error)
		return
	Events.items_gained.emit(GameState.last_gain, GameState.last_coins, _screen_point(point))
	var level := GameState.progress.nature_level(site)
	if level > previous_level:
		Events.toast_requested.emit("%s nível %d!" % [data.name, level])


## Recolhe direto no mapa os lotes prontos de uma estação/criação. Devolve true se recolheu.
func _collect_station(station_id: String, point: Vector2) -> bool:
	if station_id == "" or not GameState.has_upgrade(station_id) or GameState.station(station_id).ready_count(GameState.now()) <= 0:
		return false
	Events.items_gained.emit(GameState.collect(station_id), 0, _screen_point(point))
	return true


## Objetos com "requirements" (ex.: baú da Clareira) só existem depois que a história os revela;
## "seen_sprite" troca o desenho quando a marca em progress.seen existe (baú aberto).
func _refresh_gated() -> void:
	var states: Array[String] = []
	for sprite: Sprite2D in _objects:
		if not sprite.has_meta("requirements") and not sprite.has_meta("seen_sprite") and not sprite.has_meta("hide_seen"):
			continue
		var open := GameState.requirement_error(sprite.get_meta("requirements", {})) == ""
		var seen_data: Dictionary = sprite.get_meta("seen_sprite", {})
		var seen := not seen_data.is_empty() and bool(GameState.progress.seen.get(seen_data.key, false))
		var gone := bool(GameState.progress.seen.get(sprite.get_meta("hide_seen", ""), false))
		states.append("%s:%s:%s:%s" % [sprite.name, open, seen, gone])
		sprite.visible = open and not gone
		if not seen_data.is_empty():
			if not sprite.has_meta("base_texture_path"):
				sprite.set_meta("base_texture_path", sprite.texture.resource_path)
			sprite.texture = load(seen_data.sprite if seen else sprite.get_meta("base_texture_path"))
			sprite.offset = -Vector2(sprite.texture.get_width() / 2.0, sprite.texture.get_height())
	if states == _gated_snapshot:
		return
	_gated_snapshot = states
	_build_navigation()


## Toque no baú: abre uma vez (festa na casca) e troca para o desenho aberto.
func _open_treasure(sprite: Sprite2D) -> void:
	var error := GameState.open_treasure()
	if error != "":
		Events.toast_requested.emit(error)
		return
	var rewards: Dictionary = Database.progression.treasure.rewards
	Events.items_gained.emit(rewards.get("items", {}), int(rewards.get("coins", 0)), _screen_point(sprite.position - Vector2(0, sprite.texture.get_height() / 2.0)))


## Toque preciso: dentro do retângulo e num pixel não transparente do desenho.
func _hits(sprite: Sprite2D, local: Vector2) -> bool:
	var unscaled := local / sprite.scale
	return sprite.visible and sprite.texture != null and sprite.get_rect().has_point(unscaled) and sprite.is_pixel_opaque(unscaled)


## Recolhe direto no mapa o passeio pronto; senão abre o painel de passeios.
func _collect_walk() -> void:
	if GameState.walk_ready():
		var error := GameState.collect_walk_error()
		if error != "":
			Events.toast_requested.emit(error)
		else:
			GameState.collect_walk()
	else:
		Places.run(world_id, "place:walk")


## `target` é o sprite tocado (quando houver), para ações que dependem dele (canteiros).
func _on_object_tapped(action: String, target: Node = null) -> void:
	if action == "place:walk" and GameState.walk_ready():
		_collect_walk()
		return
	if target is Sprite2D and _collect_station(str(target.get_meta("station", target.get_meta("animal_station", ""))), target.position):
		return
	match action:
		"plot":
			_on_plot_tapped(int(target.get_meta("plot")) if target else 0)
		"treasure":
			if target is Sprite2D:
				_open_treasure(target)
		_:
			Places.run(world_id, action)  # "place:<id>" ou "npc:<id>" (data/worlds.json)


func _flash(sprite: Sprite2D) -> void:
	sprite.modulate = Color(1.35, 1.35, 1.35)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)


## Menor zoom: a sala inteira cabe na tela.
func _fit_zoom() -> float:
	return minf(size.x / _content.size.x, size.y / _content.size.y)


func _show_whole_room() -> void:
	_zoom_at(size / 2.0, float(_room.get("initial_zoom", _fit_zoom())))
	if _room.has("view_center"):
		_content.position = size / 2.0 - _vec(_room.view_center) * _zoom
		_clamp_content()


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
	_update_filter()
	_place_labels()
	if is_instance_valid(_pointer):
		_pointer.scale = Vector2.ONE / _zoom


## Pixel art em escala quebrada (ex.: 1,9 pixel de tela por pixel) com filtro "nearest"
## fica serrilhada: uns pixels saem com 1 de largura e outros com 2. Nesses casos usa
## filtro suave (com mipmaps ao reduzir); em escala inteira mantém os pixels nítidos.
func _update_filter() -> void:
	var screen_scale := _zoom * get_viewport().get_final_transform().get_scale().x
	var whole := absf(screen_scale - roundf(screen_scale)) < 0.05 and screen_scale >= 1.0
	_content.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if whole else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


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
