class_name PillarUi
extends RefCounted
## Consulta dos atributos do Tiro ("Cuidados do Tiro"), em madeira ilustrada.

static func panel() -> Control:
	var box := UiKit.vbox(10)
	box.name = "PillarPanel"
	box.set_meta("sheet_wood", true)
	var phase: Dictionary = Database.growth.phases[GameState.growth.phase_index()]
	box.add_child(personality_title())
	var age := StepCardUi.wood(str(phase.name) + " · " + str(phase.age), 18)
	age.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(age)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for id: String in Database.growth.pillars:
		var holder := Control.new()
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var card := SellUi.nine("tile", CodexUi.TILE_MARGINS, "Art", null, "codex_")
		holder.add_child(card)
		StepCardUi.stretch(card)
		var column := UiKit.vbox(2)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		holder.add_child(column)
		StepCardUi.stretch(column)
		column.offset_top = 6
		column.offset_bottom = -10
		holder.custom_minimum_size.y = 128
		var ring := RingProgress.new()
		ring.name = "PillarRing_" + id
		ring.custom_minimum_size = Vector2(64, 64)
		ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ring.color = Palette.HONEY
		ring.texture = UiKit.ui_icon(str(Database.growth.pillars[id].icon))
		column.add_child(ring)
		var title := StepCardUi.wood(str(Database.growth.pillars[id].name), 15)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
		var dots := UiKit.hbox(4)
		dots.name = "PillarDots_" + id
		dots.alignment = BoxContainer.ALIGNMENT_CENTER
		dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(dots)
		var value := StepCardUi.wood("", 14, Color(Palette.WOOD_INK, 0.8))
		value.name = "PillarValue_" + id
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
		grid.add_child(holder)
		var refresh := func() -> void:
			var have := int(GameState.growth.phase_moments.get(id, 0))
			var need := GameState.growth.phase_need(id)
			if id == "body":
				for row: Dictionary in GameState.growth_info().requirements:
					if row.type == "feed":
						have = int(row.have)
						need = int(row.need)
			ring.progress = minf(1.0, float(have) / maxf(1.0, need))
			dots.visible = need > 0
			if need > 0: fill_dots(dots, have, need)
			value.text = "refeições" if id == "body" and need > 0 else ("" if need > 0 else "%d na vida" % int(GameState.growth.moments.get(id, 0)))
			value.visible = value.text != ""
		refresh.call()
		# As conexões existem somente enquanto o anel está na árvore.
		ring.tree_exiting.connect(func() -> void:
			if Events.state_changed.is_connected(refresh): Events.state_changed.disconnect(refresh))
		var gained := func(pillar: String, _source: String) -> void:
			if pillar == id and ring.is_inside_tree(): Motion.bounce(ring)
		ring.tree_entered.connect(func() -> void:
			refresh.call()
			Events.state_changed.connect(refresh)
			Events.moment_gained.connect(gained))
		ring.tree_exiting.connect(func() -> void:
			if Events.moment_gained.is_connected(gained): Events.moment_gained.disconnect(gained))
	box.add_child(origins())
	box.add_child(diary())
	box.add_child(taste_guide())
	return box


## Título de uma seção, na fonte da madeira.
static func _heading(text: String) -> Label:
	var result := StepCardUi.wood(text, 20)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result


## Bolinhas de momentos (●●●○): uma por momento pedido, cheias até o que já tem.
static func fill_dots(row: HBoxContainer, have: int, need: int) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for i in need:
		var dot := Panel.new()
		dot.name = "Dot_%d" % i
		dot.custom_minimum_size = Vector2(10, 10)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := UiKit.surface(Palette.HONEY if i < have else Palette.WOOD_INSET, 5)
		style.border_color = Palette.WOOD_INK
		style.set_border_width_all(2)
		dot.add_theme_stylebox_override("panel", style)
		dot.set_meta("filled", i < have)
		row.add_child(dot)


## Linha de bolinhas pronta para um requisito de momentos.
static func dots(have: int, need: int) -> HBoxContainer:
	var row := UiKit.hbox(4)
	fill_dots(row, mini(have, need), need)
	return row


## "De onde vêm": as fontes dos momentos de cada pilar (Coragem, Esperteza, Pelagem), com Ir quando há lugar.
static func origins() -> Control:
	var box := UiKit.vbox(8)
	box.name = "MomentOrigins"
	box.add_child(_heading("De onde vêm os momentos"))
	for pillar: String in ["brave", "smart", "coat"]:
		var group := StepCardUi.inner_card(box, "Origins_" + pillar, Vector4i(12, 8, 12, 10))
		group.add_theme_constant_override("separation", 4)
		var head := UiKit.hbox(8)
		var pillar_icon := UiKit.icon(UiKit.ui_icon(str(Database.growth.pillars[pillar].icon)), 32)
		pillar_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		head.add_child(pillar_icon)
		var pillar_name := StepCardUi.wood(str(Database.growth.pillars[pillar].name), 19)
		pillar_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(pillar_name)
		group.add_child(head)
		for source: String in Database.growth.moments.sources:
			var rule: Dictionary = Database.growth.moments.sources[source]
			if str(rule.pillar) != pillar or not rule.has("label"): continue
			var row := UiKit.hbox(8)
			row.name = "Origin_" + source
			var label := StepCardUi.wood(str(rule.label), 15)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			if rule.has("go"):
				var target := WishUi.go_target({"go": rule.go})
				row.add_child(WelcomeSheet._button("Ir", false, 64.0, "OriginGo_" + source, Places.go.bind(target)))
			group.add_child(row)
	return box


## Guia de sabores: provadas com a carinha da reação, não provadas em silhueta, ♥ na favorita descoberta.
static func taste_guide() -> Control:
	var box := UiKit.vbox(8)
	box.name = "TasteGuide"
	var found := 0
	var foods: Array[String] = []
	for id: String in Database.items:
		if Database.items[id].has("feed"): foods.append(id)
	for id: String in foods:
		if GameState.growth.tastes.has(id): found += 1
	box.add_child(_heading("Guia de sabores %d/%d" % [found, foods.size()]))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for id: String in foods:
		var tile := Control.new()
		tile.name = "Taste_" + id
		tile.custom_minimum_size = Vector2(54, 54)
		tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var art := SellUi.nine("tile", CodexUi.TILE_MARGINS, "Art", null, "codex_")
		tile.add_child(art)
		StepCardUi.stretch(art)
		var tried := GameState.growth.tastes.has(id)
		var icon := UiKit.icon(Database.item_icon(id), 32)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.position = Vector2(11, 9)
		if not tried: icon.modulate = Color(0, 0, 0, 0.35)
		tile.add_child(icon)
		if tried:
			var reaction := str(GameState.growth.tastes[id])
			tile.tooltip_text = Database.item_name(id)
			var loved := reaction == "loved" or (GameState.favorite_found() and id == GameState.favorite_food())
			var face := CodexUi._taste_face("heart" if loved else reaction)
			face.position = Vector2(30, 26)
			tile.add_child(face)
		grid.add_child(tile)
	return box


static func personality_title() -> Control:
	var title := StepCardUi.wood(PersonalityRules.title(GameState.growth), 18)
	title.name = "PersonalityTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.visible = title.text != ""
	return title


static func diary() -> Control:
	var box := UiKit.vbox(6)
	box.name = "GrowthDiary"
	box.add_child(_heading("Hoje o Tiro..."))
	var entries := GameState.growth.diary.duplicate()
	entries.reverse()
	var card := StepCardUi.inner_card(box, "", Vector4i(12, 8, 12, 10))
	card.add_theme_constant_override("separation", 4)
	if entries.is_empty(): card.add_child(_line("As lembranças dele vão aparecer aqui."))
	for entry: Dictionary in entries:
		card.add_child(_line(str(entry.day) + " · " + str(entry.text)))
	return box


static func _line(text: String) -> Label:
	var result := StepCardUi.wood(text, 14, Color(Palette.WOOD_INK, 0.85))
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return result
