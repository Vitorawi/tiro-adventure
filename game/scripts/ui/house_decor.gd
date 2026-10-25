class_name HouseDecor
extends Node2D
## Desenho em código por cima dos objetos da Casa que mudam com a história (etapa 14):
## régua da parede (um risquinho por fase), prateleira de lembranças e parede de fotos.
## Fica filho do sprite do objeto: a origem é o meio da base, igual ao sprite.

const KIND_CHART := "chart"
const KIND_SHELF := "shelf"
const KIND_WALL := "wall"
const KIND_FRAME := "frame"
const FONT_SIZE := 7
## Inclinação das paredes do cenário (a mesma de `tools/house_art.gd`): objetos de parede sobem para a direita.
const SLOPE := 0.37

var kind: String = ""
var size: Vector2 = Vector2.ZERO
## Corpo do desenho sem a inclinação (a imagem do objeto é `size`, já inclinada).
var body: Vector2 = Vector2.ZERO
var _photos: Node2D
var _photo_snapshot: Array[String] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Events.state_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	queue_redraw()
	if kind not in [KIND_WALL, KIND_FRAME]:
		return
	var ids: Array[String] = []
	if kind == KIND_WALL:
		ids.assign(GameState.album.wall)
	else:
		ids.append(GameState.album.main_photo)
	if ids == _photo_snapshot and _photos != null:
		return
	_photo_snapshot = ids
	if _photos != null:
		remove_child(_photos)
		_photos.queue_free()
	_photos = Node2D.new()
	_photos.name = "SelectedPhotos"
	_photos.transform = Transform2D(Vector2(1.0, -SLOPE), Vector2(0.0, 1.0), Vector2(0.0, -SLOPE * size.x / 2.0))
	add_child(_photos)
	var height := size.y - ceilf(size.x * SLOPE)
	var slots := int(Database.house.get("wall_slots", 3)) if kind == KIND_WALL else 1
	var step := (size.x - 8.0) / slots
	for index in mini(slots, ids.size()):
		if not GameState.album.has_photo(ids[index]):
			continue
		var width := minf(step - 3.0, height - 8.0)
		var card := PhotoCard.make(ids[index], width, {"caption": false})
		card.position = Vector2(-size.x / 2.0 + 4.0 + step * index + (step - width) / 2.0, -height + 4.0)
		_photos.add_child(card)


func _draw() -> void:
	body = Vector2(size.x, size.y - ceilf(size.x * SLOPE))
	# Mesma inclinação do sprite: o ponto (x, y) do corpo vai para (x, y − SLOPE·(x + largura/2)).
	draw_set_transform_matrix(Transform2D(Vector2(1.0, -SLOPE), Vector2(0.0, 1.0), Vector2(0.0, -SLOPE * size.x / 2.0)))
	match kind:
		KIND_CHART:
			_draw_chart()
		KIND_SHELF:
			_draw_shelf()
		KIND_WALL:
			_draw_wall()


## Um risquinho por fase já vivida: a chegada (newborn) e uma por cerimônia de crescimento.
## `frac` = altura de 0 a 1 proporcional ao peso daquela fase.
static func chart_marks() -> Array[Dictionary]:
	var marks: Array[Dictionary] = []
	var phases: Array = Database.growth.get("phases", [])
	var heaviest := 0.01
	for phase: Dictionary in phases:
		heaviest = maxf(heaviest, _kilos(str(phase.get("weight", "0"))))
	for index in phases.size():
		var phase: Dictionary = phases[index]
		var id := str(phase.id)
		var at := 0.0
		if index == 0:
			at = GameState.progress.started_at
		elif GameState.growth.ceremonies.has(id):
			at = float(GameState.growth.ceremonies[id].get("at", 0.0))
		else:
			continue
		marks.append({"phase": id, "name": str(phase.get("name", id)), "at": at,
			"weight": str(phase.get("weight", "")), "frac": _kilos(str(phase.get("weight", "0"))) / heaviest})
	return marks


static func date_text(at: float) -> String:
	if at <= 0.0:
		return ""
	var date := Time.get_date_dict_from_unix_time(int(at) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60)
	return "%02d/%02d" % [date.day, date.month]


static func _kilos(text: String) -> float:
	return float(text.replace(" kg", "").replace(",", "."))


func _draw_chart() -> void:
	var font := ThemeDB.fallback_font
	var top := -body.y + 6.0
	var span := body.y - 12.0
	for mark: Dictionary in HouseDecor.chart_marks():
		var y := -6.0 - span * float(mark.frac) * 0.92
		y = maxf(y, top)
		draw_line(Vector2(-body.x / 2.0 + 2.0, y), Vector2(body.x / 2.0 - 2.0, y), Palette.ALERT_INK, 2.0)
		draw_string(font, Vector2(body.x / 2.0 + 2.0, y + 3.0), str(mark.name) + " " + date_text(float(mark.at)), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Palette.INK)


## Itens da prateleira, da esquerda para a direita; só o que já foi entregue aparece.
static func shelf_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for entry: Dictionary in Database.house.get("shelf", []):
		var id := str(entry.id)
		var here := GameState.keepsake_delivered(id) if id != "arrival_box" else GameState.house_has("memory_shelf")
		if here:
			items.append(entry)
	if GameState.house_has("old_camera"):
		items.append({"id": "old_camera", "name": "Câmera antiga", "icon": "res://assets/sprites/areas/house/old_camera.png"})
	return items


func _draw_shelf() -> void:
	var items := HouseDecor.shelf_items()
	var step := (body.x - 8.0) / maxf(1.0, float(items.size()))
	for index in items.size():
		var entry: Dictionary = items[index]
		var texture: Texture2D = null
		if entry.has("icon"):
			texture = load(str(entry.icon))
		else:
			texture = Database.item_icon(str(entry.id))
		if texture == null:
			continue
		var width := minf(step, 12.0)
		var rect := Rect2(Vector2(-body.x / 2.0 + 4.0 + step * index + (step - width) / 2.0, -body.y + 4.0), Vector2(width, width))
		draw_texture_rect(texture, rect, false)


## Moldurinhas da parede de fotos: pendurada = polaroide clara; vazia = moldura vazia.
func _draw_wall() -> void:
	var slots := int(Database.house.get("wall_slots", 3))
	var width := (body.x - 8.0) / slots
	for index in slots:
		var id := str(GameState.album.wall[index]) if index < GameState.album.wall.size() else ""
		var rect := Rect2(Vector2(-body.x / 2.0 + 4.0 + width * index + 2.0, -body.y + 6.0), Vector2(width - 4.0, body.y - 14.0))
		draw_rect(rect, Palette.PAPER if id != "" else Palette.SUNKEN)
		if id != "":
			draw_rect(rect.grow(-2.0), Palette.GO.lerp(Palette.PAPER, 0.55))
			draw_rect(Rect2(rect.position + Vector2(3, rect.size.y - 5.0), Vector2(rect.size.x - 6.0, 2.0)), Palette.INK_SOFT)
