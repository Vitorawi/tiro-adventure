class_name CollectFx
extends Control
## Animação de recolher: miniaturas "ícone +N" saltam do ponto tocado, sobem e somem.
## Escuta Events.items_gained(itens, moedas, origem); origem em coordenadas da tela
## (Vector2(-1, -1) = sem origem: usa o meio da tela). Fica acima do mundo, abaixo das janelas.

const RISE := 70.0
const ICON_PX := 30


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_as_relative = false
	z_index = Motion.WORLD_FX_Z
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
	if not entries.is_empty():
		Haptics.success()
	var start := origin if origin.x >= 0.0 else get_viewport_rect().size / 2.0
	var hud := get_parent().get_node_or_null("TopBar") as Hud if get_parent() else null
	var bag := get_parent().find_child("BagTab", true, false) as Button
	var faces: Dictionary = get_parent().get("_faces") if get_parent().has_method("set_tab_joined") else {}
	var face: NavTab = faces.get(&"bag")
	for i in entries.size():
		# Itens chegam à Mochila; antes da apresentação da aba, sobem e somem no lugar.
		var fly_to := hud.coins_target() if hud and i == coin_index else (bag.global_position + face.icon_center() if bag and bag.is_visible_in_tree() and face else Vector2(-1, -1))
		var arrive := hud.flash_coins if hud and i == coin_index else (face.reward_arrived if face else Callable())
		_spawn(entries[i][0], int(entries[i][1]), start, i, entries.size(), fly_to, arrive)


func _spawn(texture: Texture2D, amount: int, start: Vector2, index: int, total: int, fly_to: Vector2 = Vector2(-1.0, -1.0), arrive: Callable = Callable()) -> void:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 3)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(UiKit.icon(texture, ICON_PX))
	var label := Label.new()
	label.text = "+%d" % amount
	label.theme_type_variation = &"NumberLabel"
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
	if Motion.reduced:
		chip.queue_free()
		return
	if fly_to.x >= 0:
		chip.modulate.a = 1.0
		Motion.fly_arc(chip, chip.position, fly_to - Vector2(width, ICON_PX) / 2)
		var flight := chip.create_tween()
		flight.tween_property(chip, "scale", Vector2.ONE, Motion.FLY * 0.5)
		flight.tween_property(chip, "scale", Vector2.ONE * 0.4, Motion.FLY * 0.5)
		if arrive.is_valid(): flight.tween_callback(arrive)
		flight.tween_callback(chip.queue_free)
	else:
		var tween := chip.create_tween()
		tween.tween_interval(0.0)
		tween.tween_property(chip, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(chip, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(chip, "position:y", y - RISE, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(chip, "modulate:a", 0.0, 0.1)
		tween.tween_callback(chip.queue_free)
