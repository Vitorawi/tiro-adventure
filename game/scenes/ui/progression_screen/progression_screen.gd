extends Control
## Central de progresso, missões e atividades; navegação preserva o contexto.

var _page: String = "today"
var _body: Control

@onready var _holder: VBoxContainer = %PageHolder
@onready var _scroll: ScrollContainer = %PageScroll


func _ready() -> void:
	var pages := {"today": "Hoje", "skills": "Atributos", "quests": "Missões", "shop": "Construir", "routes": "Rotas", "market": "Feira", "production": "Produção", "collection": "Coleção"}
	for id: String in pages:
		var button := UiKit.button(pages[id], func() -> void: show_page(id))
		button.custom_minimum_size = Vector2(0, 44)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		%Navigation.add_child(button)
	show_page(_page)


func show_page(id: String) -> void:
	_page = id
	if is_instance_valid(_body):
		_holder.remove_child(_body)
		_body.queue_free()
	_body = ProgressionUi.panel(id)
	_holder.add_child(_body)
	_scroll.scroll_vertical = 0
	var ids: Array[String] = ["today", "skills", "quests", "shop", "routes", "market", "production", "collection"]
	for i in %Navigation.get_child_count():
		var button: Button = %Navigation.get_child(i)
		button.disabled = ids[i] == id
