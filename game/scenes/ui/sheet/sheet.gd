extends Control
## Painel inferior (bottom sheet) para menus de objetos: geladeira, fogão...
## Aberto via Events.sheet_requested(title, content); fecha ao tocar fora,
## no "X" ou via Events.sheet_close_requested.

@onready var _dim: ColorRect = %Dim
@onready var _title: Label = %Title
@onready var _content_holder: VBoxContainer = %ContentHolder


func _ready() -> void:
	hide()
	_dim.gui_input.connect(_on_dim_input)
	%CloseButton.pressed.connect(close)
	Events.sheet_requested.connect(open)
	Events.sheet_close_requested.connect(close)


func open(title: String, content: Control) -> void:
	for child in _content_holder.get_children():
		child.queue_free()
	_title.text = title
	_content_holder.add_child(content)
	show()


func close() -> void:
	hide()
	for child in _content_holder.get_children():
		child.queue_free()


func _on_dim_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed:
		close()
