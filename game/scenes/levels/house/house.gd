extends Control
## Casa do Tiro (primeiro ambiente do Mundo).
## Arrastar move a câmera; tocar nos objetos abre menus.
##
## Coordenadas abaixo estão em pixels da imagem de fundo (512x352) e são
## multiplicadas por ART_SCALE. Ao trocar a arte, ajuste HOTSPOTS e pontos.

const ART_SCALE := 2.0
const HOTSPOTS := {
	"fridge": Rect2(80, 105, 62, 112),
	"stove": Rect2(140, 118, 75, 50),
	"bowl": Rect2(212, 228, 38, 24),
	"sofa": Rect2(245, 165, 125, 90),
	"toys": Rect2(262, 225, 42, 42),
	"tv": Rect2(400, 88, 72, 82),
	"table": Rect2(145, 238, 100, 65),
	"door": Rect2(22, 102, 44, 105),
}
const WALK_POINTS: Array[Vector2] = [
	Vector2(165, 225), Vector2(255, 270), Vector2(330, 275),
	Vector2(390, 220), Vector2(320, 190), Vector2(280, 250),
]
const BOWL_POINT := Vector2(245, 245)
const SLEEP_POINT := Vector2(300, 205)
const START_FOCUS := Vector2(300, 190)

@onready var _content: Control = %Content
@onready var _background: TextureRect = %Background


func _ready() -> void:
	clip_contents = true
	_content.size = _background.texture.get_size() * ART_SCALE
	_background.size = _content.size
	_build_hotspots()
	_spawn_dog()
	resized.connect(_clamp_content)
	_focus_on.call_deferred(START_FOCUS * ART_SCALE)


func _gui_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_content.position += motion.relative
		_clamp_content()
		accept_event()


func _build_hotspots() -> void:
	for id: String in HOTSPOTS:
		var rect: Rect2 = HOTSPOTS[id]
		var hotspot := Hotspot.new()
		hotspot.name = id.capitalize()
		hotspot.position = rect.position * ART_SCALE
		hotspot.size = rect.size * ART_SCALE
		hotspot.tapped.connect(_on_hotspot_tapped.bind(id))
		_content.add_child(hotspot)


func _spawn_dog() -> void:
	var dog := DogWorld.new()
	dog.name = "Tiro"
	for point in WALK_POINTS:
		dog.walk_points.append(point * ART_SCALE)
	dog.bowl_point = BOWL_POINT * ART_SCALE
	dog.sleep_point = SLEEP_POINT * ART_SCALE
	_content.add_child(dog)
	dog.place_at(WALK_POINTS[1] * ART_SCALE)


func _on_hotspot_tapped(id: String) -> void:
	match id:
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
		"toys":
			if GameState.play():
				Events.toast_requested.emit("Tiro brincou com os brinquedos!")
			else:
				Events.toast_requested.emit("Tiro está cansado demais para brincar.")
		"door":
			Events.toast_requested.emit("A Horta abre no nível 2!")
		_:
			Events.toast_requested.emit("Em breve!")


func _focus_on(point: Vector2) -> void:
	_content.position = size / 2.0 - point
	_clamp_content()


func _clamp_content() -> void:
	var min_pos := (size - _content.size).min(Vector2.ZERO)
	_content.position = _content.position.clamp(min_pos, Vector2.ZERO)
