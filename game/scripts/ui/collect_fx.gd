class_name CollectFx
extends Control
## Animação de recolher: miniaturas "ícone +N" saltam do ponto tocado, sobem e somem.
## Escuta Events.items_gained(itens, moedas, origem); origem em coordenadas da tela
## (Vector2(-1, -1) = sem origem: usa o meio da tela). Fica acima do mundo e do Sheet.

const RISE := 70.0
const STAGGER := 0.14
const ICON_PX := 30
const FLY := 0.45  # voo das moedas até a pílula do HUD


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20  # acima do Sheet (10), do toast (11) e da barra (12)
	Events.items_gained.connect(_on_items_gained)


func _on_items_gained(items: Dictionary, coins: int, origin: Vector2) -> void:
	var entries: Array[Array] = []
	var coin_index := -1
	for id: String in items:
		if int(items[id]) > 0:
			entries.append([Database.item_icon(id), int(items[id])])
	if coins > 0:
		coin_index = entries.size()
		entries.append([UiKit.ui_icon("coin"), coins])
	var start := origin if origin.x >= 0.0 else get_viewport_rect().size / 2.0
	var hud := get_parent().get_node_or_null("TopBar") as Hud if get_parent() else null
	for i in entries.size():
		# As moedas terminam o voo na pílula do HUD; os itens sobem e somem onde estão.
		var fly_to := hud.coins_target() if hud and i == coin_index else Vector2(-1.0, -1.0)
		_spawn(entries[i][0], int(entries[i][1]), start, i, entries.size(), fly_to)


func _spawn(texture: Texture2D, amount: int, start: Vector2, index: int, total: int, fly_to: Vector2 = Vector2(-1.0, -1.0)) -> void:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(UiKit.icon(texture, ICON_PX))
	var label := Label.new()
	label.text = "+%d" % amount
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Palette.INK_ON_DARK)
	label.add_theme_color_override("font_outline_color", Palette.INK)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	chip.modulate.a = 0.0
	add_child(chip)
	# Lado a lado em torno da origem, sem sair da tela.
	var area := get_viewport_rect().size
	var width := ICON_PX + 3.0 + 14.0 * str(amount).length() + 14.0
	var spread := (index - (total - 1) / 2.0) * (width + 8.0)
	var x := clampf(start.x + spread - width / 2.0, 4.0, maxf(4.0, area.x - width - 4.0))
	var y := clampf(start.y - ICON_PX, 90.0, maxf(90.0, area.y - 120.0))
	chip.position = Vector2(x, y)
	chip.pivot_offset = Vector2(width / 2.0, ICON_PX / 2.0)
	chip.scale = Vector2.ONE * 0.3
	var tween := chip.create_tween()
	tween.tween_interval(index * STAGGER)
	tween.tween_property(chip, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(chip, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Moeda que vai para o HUD sobe pouco e depressa; o resto sobe e some devagar.
	var rise_time := 0.4 if fly_to.x >= 0.0 else 1.1
	tween.parallel().tween_property(chip, "position:y", y - RISE, rise_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if fly_to.x >= 0.0:
		# Voa até a pílula de moedas (centro do chip no centro do número) e encolhe ao chegar.
		var landing := fly_to - Vector2(width, ICON_PX) / 2.0
		tween.tween_property(chip, "position", landing, FLY).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN).set_delay(0.1)
		tween.parallel().tween_property(chip, "scale", Vector2.ONE * 0.5, FLY).set_delay(0.1)
		tween.tween_property(chip, "modulate:a", 0.0, 0.1)
	else:
		tween.tween_property(chip, "modulate:a", 0.0, 0.35).set_delay(0.45)
	tween.tween_callback(chip.queue_free)
