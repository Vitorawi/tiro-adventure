extends Control
## Cena inicial provisória: valida que o save local funciona no celular.
## Substituir pelo menu/jogo real quando o design estiver definido.

@onready var _counter_label: Label = %CounterLabel
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	Events.state_changed.connect(_refresh)
	Events.game_saved.connect(func() -> void: _status_label.text = "Salvo!")
	%AddButton.pressed.connect(_on_add_pressed)
	%ResetButton.pressed.connect(_on_reset_pressed)
	_refresh()


func _refresh() -> void:
	_counter_label.text = str(GameState.counter)


func _on_add_pressed() -> void:
	GameState.add_to_counter()
	SaveManager.save_game()


func _on_reset_pressed() -> void:
	SaveManager.delete_save()
	_status_label.text = "Save apagado"
