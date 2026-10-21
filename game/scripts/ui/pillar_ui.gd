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
		var value := UiKit.label("", &"SmallLabel")
		value.name = "PillarValue_" + id
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(value)
		var reserve := UiKit.label("", &"SmallLabel")
		reserve.name = "PillarReserve_" + id
		reserve.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(reserve)
		grid.add_child(column)
		var refresh := func() -> void:
			ring.progress = float(GameState.growth.level(id)) / GameState.growth.cap()
			value.text = "%d/%d" % [GameState.growth.level(id), GameState.growth.cap()]
			reserve.text = "+%d guardado" % int(GameState.growth.reserve.get(id, 0))
			reserve.visible = int(GameState.growth.reserve.get(id, 0)) > 0
		refresh.call()
		# As conexões existem somente enquanto o anel está na árvore.
		ring.tree_exiting.connect(func() -> void:
			if Events.state_changed.is_connected(refresh): Events.state_changed.disconnect(refresh))
		var gained := func(pillar: String, _points: int, level_up: bool) -> void:
			if pillar == id and level_up and ring.is_inside_tree(): Motion.bounce(ring)
		ring.tree_entered.connect(func() -> void:
			refresh.call()
			Events.state_changed.connect(refresh)
			Events.pillar_gained.connect(gained))
		ring.tree_exiting.connect(func() -> void:
			if Events.pillar_gained.is_connected(gained): Events.pillar_gained.disconnect(gained))
	var pet_hint := UiKit.label("", &"SmallLabel")
	pet_hint.name = "PetGrowthHint"
	var refresh_pet := func() -> void: pet_hint.text = str(GameState.pet_growth_info().hint)
	refresh_pet.call()
	var pet_timer := Timer.new()
	pet_timer.wait_time = 1.0
	pet_timer.autostart = true
	pet_timer.timeout.connect(refresh_pet)
	pet_hint.add_child(pet_timer)
	box.add_child(pet_hint)
	var play_hint := UiKit.label("", &"SmallLabel")
	play_hint.name = "PlayGrowthHint"
	var refresh_play := func() -> void: play_hint.text = str(GameState.play_growth_info().hint)
	refresh_play.call()
	pet_timer.timeout.connect(refresh_play)
	box.add_child(play_hint)
	box.add_child(diary())
	box.add_child(taste_guide())
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
	box.add_child(UiKit.label("Guia de sabores %d/%d" % [found, foods.size()], &"SectionLabel"))
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
				var heart := UiKit.icon(UiKit.ui_icon("bond_heart"), 18)
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
	var title := UiKit.fill_label(PersonalityRules.title(GameState.growth), &"SectionLabel")
	title.name = "PersonalityTitle"
	title.visible = title.text != ""
	return title


static func diary() -> Control:
	var box := UiKit.vbox(6)
	box.name = "GrowthDiary"
	box.add_child(UiKit.label("Hoje o Tiro...", &"SectionLabel"))
	var entries := GameState.growth.diary.duplicate()
	entries.reverse()
	if entries.is_empty(): box.add_child(UiKit.fill_label("As lembranças dele vão aparecer aqui.", &"SmallLabel"))
	for entry: Dictionary in entries:
		box.add_child(UiKit.fill_label(str(entry.day) + " · " + str(entry.text), &"SmallLabel"))
	return box
