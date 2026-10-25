class_name PillarUi
extends RefCounted
## Consulta dos atributos do Tiro; painel de crescer entra na etapa 06.

static func panel() -> Control:
	var box := UiKit.vbox(12)
	box.name = "PillarPanel"
	var phase: Dictionary = Database.growth.phases[GameState.growth.phase_index()]
	box.add_child(personality_title())
	box.add_child(UiKit.label(str(phase.name) + " · " + str(phase.age)))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	for id: String in Database.growth.pillars:
		var column := UiKit.vbox(3)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ring := RingProgress.new()
		ring.name = "PillarRing_" + id
		ring.custom_minimum_size = Vector2(64, 64)
		ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ring.texture = UiKit.ui_icon(str(Database.growth.pillars[id].icon))
		column.add_child(ring)
		var title := UiKit.label(str(Database.growth.pillars[id].name), &"SmallLabel")
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
		var dots := UiKit.hbox(4)
		dots.name = "PillarDots_" + id
		dots.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(dots)
		var value := UiKit.label("", &"SmallLabel")
		value.name = "PillarValue_" + id
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
		grid.add_child(column)
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
		var style := UiKit.surface(Palette.HONEY if i < have else Palette.SUNKEN, 5)
		style.border_color = Palette.INK
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
	var box := UiKit.vbox(6)
	box.name = "MomentOrigins"
	box.add_child(UiKit.section("De onde vêm os momentos"))
	for pillar: String in ["brave", "smart", "coat"]:
		var group := UiKit.vbox(4)
		group.name = "Origins_" + pillar
		var head := UiKit.hbox(6)
		head.add_child(UiKit.icon(UiKit.ui_icon(str(Database.growth.pillars[pillar].icon)), 24))
		head.add_child(UiKit.fill_label(str(Database.growth.pillars[pillar].name), &"StrongLabel"))
		group.add_child(head)
		for source: String in Database.growth.moments.sources:
			var rule: Dictionary = Database.growth.moments.sources[source]
			if str(rule.pillar) != pillar or not rule.has("label"): continue
			var go: Control = null
			if rule.has("go"):
				var target := WishUi.go_target({"go": rule.go})
				go = UiKit.secondary("Ir", Places.go.bind(target), null, true)
				go.name = "OriginGo_" + source
			var row := UiKit.list_row(UiKit.ui_icon(str(Database.growth.pillars[pillar].icon)), str(rule.label), [], go)
			row.name = "Origin_" + source
			group.add_child(row)
		box.add_child(group)
	return box


const TASTE_FACES := {"liked": ":)", "odd": ":/", "grimace": ">:("}


## Guia de sabores: provadas com a carinha da reação, não provadas em silhueta, ♥ na favorita descoberta.
static func taste_guide() -> Control:
	var box := UiKit.vbox(6)
	box.name = "TasteGuide"
	var found := 0
	var foods: Array[String] = []
	for id: String in Database.items:
		if Database.items[id].has("feed"): foods.append(id)
	for id: String in foods:
		if GameState.growth.tastes.has(id): found += 1
	box.add_child(UiKit.section("Guia de sabores %d/%d" % [found, foods.size()]))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for id: String in foods:
		var tile := Control.new()
		tile.name = "Taste_" + id
		tile.custom_minimum_size = Vector2(52, 52)
		var tried := GameState.growth.tastes.has(id)
		var icon := UiKit.icon(Database.item_icon(id), 40)
		icon.position = Vector2(6, 6)
		if not tried: icon.modulate = Color(0, 0, 0, 0.35)
		tile.add_child(icon)
		if tried:
			var reaction := str(GameState.growth.tastes[id])
			tile.tooltip_text = Database.item_name(id)
			if reaction == "loved" or (GameState.favorite_found() and id == GameState.favorite_food()):
				var heart := UiKit.icon(UiKit.ui_icon("heart"), 18)
				heart.name = "FavoriteHeart"
				heart.position = Vector2(34, 0)
				tile.add_child(heart)
			else:
				var face := UiKit.short_label(str(TASTE_FACES.get(reaction, "")), &"BadgeLabel")
				face.name = "Face"
				face.position = Vector2(26, 30)
				tile.add_child(face)
		grid.add_child(tile)
	return box


static func personality_title() -> Control:
	var title := UiKit.fill_label(PersonalityRules.title(GameState.growth), &"StrongLabel")
	title.name = "PersonalityTitle"
	title.visible = title.text != ""
	return title


static func diary() -> Control:
	var box := UiKit.vbox(6)
	box.name = "GrowthDiary"
	box.add_child(UiKit.section("Hoje o Tiro..."))
	var entries := GameState.growth.diary.duplicate()
	entries.reverse()
	if entries.is_empty(): box.add_child(UiKit.fill_label("As lembranças dele vão aparecer aqui.", &"SmallLabel"))
	for entry: Dictionary in entries:
		box.add_child(UiKit.fill_label(str(entry.day) + " · " + str(entry.text), &"SmallLabel"))
	return box
