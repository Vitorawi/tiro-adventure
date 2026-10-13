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
	var scroll := _content_holder.get_parent() as ScrollContainer
	if scroll:
		scroll.set_deferred("scroll_vertical", 0)
	var was_open := visible
	show()
	if not was_open:
		_slide_in()


## Painel sobe de baixo e o fundo escurece.
func _slide_in() -> void:
	var panel: Control = %Panel
	await get_tree().process_frame  # espera o layout calcular a posição final
	var final_y := panel.position.y
	panel.position.y = size.y
	_dim.modulate.a = 0.0
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "position:y", final_y, 0.28)
	tween.tween_property(_dim, "modulate:a", 1.0, 0.2)


func close() -> void:
	hide()
	for child in _content_holder.get_children():
		child.queue_free()


func _on_dim_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.pressed:
		close()
