class_name CornerDecor
extends Control
## Enfeites do cantinho do Tiro (etapa 14): no máximo 3 por cima do cenário (tapete, foto principal,
## cesto de brinquedos, na ordem de `house.json → corner`) e a régua pequena. Ficam atrás do Tiro
## e longe dos anéis: tudo dentro de `scene_rect()` do `PetBackdrop`.

const MAX_DECOR := 3
const RUG_SIZE := Vector2(60, 26)
const BASKET_SIZE := Vector2(40, 36)
const PHOTO_WIDTH := 66.0

var backdrop: PetBackdrop
var shown: Array[String] = []
var _photo: Control
var _ruler: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	Events.state_changed.connect(refresh)
	if backdrop:
		backdrop.resized.connect(refresh)
	refresh()


## Quais enfeites aparecem agora (a foto principal só entra com a moldura e uma foto escolhida).
static func choose() -> Array[String]:
	var result: Array[String] = []
	for id: Variant in Database.house.get("corner", []):
		if result.size() >= MAX_DECOR:
			break
		var key := str(id)
		if not GameState.house_has(key):
			continue
		if key == "gold_frame" and not GameState.album.has_photo(GameState.album.main_photo):
			continue
		result.append(key)
	return result


func refresh() -> void:
	if not is_inside_tree() or backdrop == null:
		return
	shown = CornerDecor.choose()
	if _ruler == null:
		_ruler = Button.new()
		_ruler.name = "CornerRuler"
		_ruler.flat = true
		_ruler.focus_mode = Control.FOCUS_NONE
		_ruler.size = Vector2(44, 96)
		_ruler.pressed.connect(GrowthUi.open)
		add_child(_ruler)
	_ruler.visible = GameState.house_has("height_chart")
	_ruler.position = Vector2(backdrop.scene_rect().position.x, backdrop.pet_feet().y - 104.0) - position
	if _photo and is_instance_valid(_photo):
		_photo.queue_free()
		_photo = null
	if shown.has("gold_frame"):
		_photo = PhotoCard.make(GameState.album.main_photo, PHOTO_WIDTH, {"caption": false})
		_photo.name = "MainPhoto"
		# A moldura do cantinho usa a arte PixelLab de frente; no mapa ela acompanha a parede inclinada.
		(_photo.get_node("Canvas/Frame") as NinePatchRect).texture = load("res://assets/sprites/areas/house/gold_frame_front.png")
		add_child(_photo)
		var room := backdrop.scene_rect()
		_photo.position = Vector2(room.end.x - PHOTO_WIDTH - 14.0, room.position.y + 10.0) - position
	queue_redraw()


func _draw() -> void:
	if backdrop == null:
		return
	var room := backdrop.scene_rect()
	var feet := backdrop.pet_feet()
	var origin := -position
	if GameState.tiro_party():
		draw_texture_rect(load("res://assets/sprites/ui/album/prop_cake.png"), Rect2(origin + Vector2(feet.x - 98, feet.y - 38), Vector2(38, 38)), false)
	if shown.has("paw_rug"):
		draw_texture_rect(load("res://assets/sprites/areas/house/paw_rug.png"), Rect2(origin + Vector2(maxf(room.position.x + 8.0, feet.x - 150.0), feet.y - 6.0), RUG_SIZE), false)
	if shown.has("toy_basket"):
		draw_texture_rect(load("res://assets/sprites/areas/house/toy_basket.png"), Rect2(origin + Vector2(feet.x + 96.0, feet.y - 30.0), BASKET_SIZE), false)
	_draw_ruler(origin + Vector2(room.position.x + 14.0, feet.y - 18.0))


## Régua pequena: haste de madeira e um risquinho por fase já vivida.
func _draw_ruler(base: Vector2) -> void:
	if not GameState.house_has("height_chart"):
		return
	var height := 78.0
	draw_rect(Rect2(base + Vector2(0, -height), Vector2(8, height)), Palette.SUNKEN)
	draw_rect(Rect2(base + Vector2(0, -height), Vector2(8, height)), Palette.INK_SOFT, false, 1.0)
	for mark: Dictionary in HouseDecor.chart_marks():
		var y := base.y - 4.0 - (height - 8.0) * float(mark.frac)
		draw_line(Vector2(base.x - 3.0, y), Vector2(base.x + 11.0, y), Palette.BAD, 2.0)
