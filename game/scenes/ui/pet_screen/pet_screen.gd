extends Control
## Tela do Pet: Tiro grande e detalhado, necessidades e ações de cuidado.
## Tocar no Tiro faz carinho.

const MOOD_LOW := 25.0
const MOOD_TEXTS := {
	"hunger": "Estou com fome!",
	"happiness": "Quero brincar...",
	"energy": "Que soninho...",
	"hygiene": "Preciso de um banho!",
}

var _bars: Dictionary = {}  # need_id -> ProgressBar

@onready var _needs_grid: GridContainer = %NeedsGrid
@onready var _mood_label: Label = %MoodLabel
@onready var _dog_sprite: TextureRect = %DogSprite
@onready var _sleep_button: Button = %SleepButton


func _ready() -> void:
	_build_need_bars()
	_dog_sprite.gui_input.connect(_on_dog_input)
	%FeedButton.pressed.connect(func() -> void:
		Events.sheet_requested.emit("Comidinha", SheetBuilder.food_picker()))
	%PlayButton.pressed.connect(_on_play_pressed)
	%BatheButton.pressed.connect(func() -> void:
		GameState.bathe()
		Events.toast_requested.emit("Tiro está cheiroso!"))
	_sleep_button.pressed.connect(func() -> void:
		GameState.set_sleeping(not GameState.dog.sleeping))
	Events.state_changed.connect(_refresh)
	%RefreshTimer.timeout.connect(_refresh)
	_refresh()


func _build_need_bars() -> void:
	for id: String in Database.needs:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.text = Database.needs[id].get("name", id)
		var bar := ProgressBar.new()
		bar.custom_minimum_size = Vector2(0, 14)
		bar.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color(0.45, 0.8, 0.4)
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("fill", fill)
		box.add_child(label)
		box.add_child(bar)
		_needs_grid.add_child(box)
		_bars[id] = bar


func _refresh() -> void:
	var now := GameState.now()
	var dog := GameState.dog
	for id: String in _bars:
		var value := dog.get_need(id, now)
		var bar: ProgressBar = _bars[id]
		bar.value = value
		bar.modulate = Color(1, 0.45, 0.45) if value < MOOD_LOW else Color.WHITE

	_sleep_button.text = "Acordar" if dog.sleeping else "Dormir"
	_dog_sprite.modulate = Color(0.55, 0.55, 0.75) if dog.sleeping else Color.WHITE

	if dog.sleeping:
		_mood_label.text = "Zzz... %s está dormindo" % dog.name
		return
	var lowest := dog.lowest_need(now)
	if dog.get_need(lowest, now) < MOOD_LOW:
		_mood_label.text = MOOD_TEXTS.get(lowest, "")
	else:
		_mood_label.text = "%s está feliz da vida!" % dog.name


func _on_play_pressed() -> void:
	if GameState.play():
		_bounce()
		Events.toast_requested.emit("Que divertido!")
	else:
		Events.toast_requested.emit("Tiro está cansado demais para brincar.")


func _on_dog_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if GameState.dog.sleeping:
		Events.toast_requested.emit("Shh... ele está dormindo.")
		return
	GameState.pet()
	_bounce()
	_float_text("+carinho", button.global_position)


func _bounce() -> void:
	_dog_sprite.pivot_offset = _dog_sprite.size * Vector2(0.5, 1.0)
	var tween := create_tween()
	tween.tween_property(_dog_sprite, "scale", Vector2(1.08, 0.92), 0.08)
	tween.tween_property(_dog_sprite, "scale", Vector2(0.95, 1.06), 0.1)
	tween.tween_property(_dog_sprite, "scale", Vector2.ONE, 0.12)


func _float_text(text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(1, 0.55, 0.7))
	add_child(label)
	label.global_position = at - Vector2(30, 30)
	var tween := create_tween().set_parallel()
	tween.tween_property(label, "position:y", label.position.y - 60, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)
