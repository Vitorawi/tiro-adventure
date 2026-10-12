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

const LOW_COLOR := Color(0.85, 0.27, 0.22)

var _bars: Dictionary = {}  # need_id -> ProgressBar
var _sleep_icon: TextureRect
var _sleep_text: Label

@onready var _needs_grid: GridContainer = %NeedsGrid
@onready var _mood_label: Label = %MoodLabel
@onready var _dog_sprite: TextureRect = %DogSprite
@onready var _sleep_button: Button = %SleepButton


func _ready() -> void:
	_build_need_bars()
	_dress_button(%FeedButton, Database.item_icon("dog_food"), "Comer")
	_dress_button(%PlayButton, UiKit.ui_icon("action_play"), "Brincar")
	_dress_button(%BatheButton, UiKit.ui_icon("action_bathe"), "Banho")
	var sleep_parts := _dress_button(_sleep_button, UiKit.ui_icon("action_sleep"), "Dormir")
	_sleep_icon = sleep_parts[0]
	_sleep_text = sleep_parts[1]
	%DogArea.draw.connect(_draw_dog_shadow)
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


## Uma célula por necessidade: ícone + nome + barra na cor dela.
func _build_need_bars() -> void:
	for id: String in Database.needs:
		var row := UiKit.hbox(6)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(UiKit.icon(Database.need_icon(id), 32))
		var box := UiKit.vbox(2)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(UiKit.label(Database.needs[id].get("name", id), &"SmallLabel"))
		var bar := UiKit.bar(100.0, Database.need_color(id), 14)
		box.add_child(bar)
		row.add_child(box)
		_needs_grid.add_child(row)
		_bars[id] = bar


## Botão grande com ícone (2x, nítido) em cima e texto embaixo.
func _dress_button(button: Button, texture: Texture2D, text: String) -> Array:
	button.text = ""
	var box := UiKit.vbox(2)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	var picture := UiKit.icon(texture, 64)
	box.add_child(picture)
	var caption := UiKit.label(text)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(caption)
	button.add_child(box)
	return [picture, caption]


func _refresh() -> void:
	var now := GameState.now()
	var dog := GameState.dog
	for id: String in _bars:
		var value := dog.get_need(id, now)
		var bar: ProgressBar = _bars[id]
		bar.value = value
		var low := value < MOOD_LOW
		if bar.get_meta("low", false) != low:
			bar.set_meta("low", low)
			UiKit.tint_bar(bar, LOW_COLOR if low else Database.need_color(id))

	_sleep_text.text = "Acordar" if dog.sleeping else "Dormir"
	_sleep_icon.texture = UiKit.ui_icon("action_wake" if dog.sleeping else "action_sleep")
	_dog_sprite.modulate = Color(0.55, 0.55, 0.75) if dog.sleeping else Color.WHITE

	if dog.sleeping:
		_mood_label.text = "Zzz... %s está dormindo" % dog.name
		return
	var lowest := dog.lowest_need(now)
	if dog.get_need(lowest, now) < MOOD_LOW:
		_mood_label.text = MOOD_TEXTS.get(lowest, "")
	else:
		_mood_label.text = "%s está feliz da vida!" % dog.name


## Sombra oval sob as patas do Tiro (desenhada no DogArea, atrás do sprite).
func _draw_dog_shadow() -> void:
	var area: Control = %DogArea
	var feet := Vector2(_dog_sprite.position.x + _dog_sprite.size.x / 2.0, _dog_sprite.position.y + _dog_sprite.size.y * 0.97)
	area.draw_set_transform(feet, 0.0, Vector2(1.0, 0.25))
	area.draw_circle(Vector2.ZERO, _dog_sprite.size.x * 0.32, Color(0.25, 0.12, 0.05, 0.3), true, -1.0, false)
	area.draw_set_transform(Vector2.ZERO)


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
