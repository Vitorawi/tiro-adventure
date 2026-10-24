class_name ProjectUi
extends RefCounted
## Painéis das obras comunitárias (data/projects.json). Só apresenta e chama as ações do GameState
## (start_project/contribute_project): nada aqui paga, consome ou conclui por conta própria.
## `panel(id)` serve a qualquer projeto; `community()` é a lista "Nossa praça" (obras + serviços da Praça).


## Painel de uma obra: fala da personagem, fases, o que falta e uma única ação (Começar ou Entregar).
static func panel(id: String) -> Control:
	var model := {"item": "", "qty": 1}
	return SheetBuilder.tall(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "ProjectPanel"
		var def := Database.project(id)
		if def.is_empty() or Database.project_issue(id) != "":
			box.add_child(UiKit.label("Em breve!"))
			return
		var completed := GameState.project_completed(id)
		var started := GameState.project_started(id)
		ProgressionUi.npc_header(box, str(def.get("npc", "lais")), _speech(id, def, started, completed))
		_title_row(box, id, def)
		_phase_row(box, id, def)
		if completed:
			_done_card(box, def)
			if not GameState.meeting_def(id).is_empty():
				_gathering_card(box, id)
		elif not started:
			_start_card(box, id, def)
		else:
			_delivery_card(box, id, model)
	))


## Lista "Nossa praça"/"Nossa vila": obras do mundo que já apareceram e os serviços (`services` do lugar
## `community` em worlds.json) que moram ali.
static func community(world: String = "park") -> Control:
	return SheetBuilder.tall(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "CommunityList"
		for id: String in Database.project_ids():
			var def := Database.project(id)
			if str(def.get("world", "")) != world or not GameState.project_available(id):
				continue
			var stage := GameState.project_stage(id)
			var completed := GameState.project_completed(id)
			var chips: Array[Control] = []
			if completed:
				chips.append(UiKit.chip(UiKit.ctl_icon("check"), "Pronto", UiKit.GOOD))
			elif GameState.project_started(id):
				chips.append(UiKit.chip(null, "Fase %d/%d" % [mini(int(stage.index) + 1, int(stage.count)), int(stage.count)]))
				chips.append(UiKit.chip(null, "%d%%" % int(round(float(stage.total_progress) * 100.0))))
			else:
				chips.append(UiKit.chip(UiKit.ui_icon("coin"), str(int(def.get("start_coins", 0)))))
			var row := UiKit.list_row(UiKit.ui_icon(str(def.get("icon", "tab_park"))), str(def.name), chips, UiKit.secondary("Ver" if completed or GameState.project_started(id) else "Começar", open.bind(id), null, true), open.bind(id))
			row.name = "Project_" + id
			box.add_child(row)
		for place_id: String in Database.worlds[world].places.get("community", {}).get("services", []):
			var place: Dictionary = Database.worlds[world].places.get(place_id, {})
			if place.is_empty() or Places.place_error(place) != "":
				continue
			var row := UiKit.list_row(UiKit.ui_icon(str(place.icon)), str(place.name), [], UiKit.secondary("Ir", Places.open.bind(world, place_id), null, true), Places.open.bind(world, place_id))
			row.name = "Service_" + place_id
			box.add_child(row)
	))


static func open(id: String) -> void:
	Events.sheet_requested.emit(str(Database.project(id).get("name", "Obra")), panel(id))


static func _speech(id: String, def: Dictionary, started: bool, completed: bool) -> String:
	if completed:
		return str(def.get("done_speech", "Ficou lindo!"))
	if not started:
		return str(def.get("pitch", ""))
	var stage := GameState.project_stage(id)
	return "Falta pouco, vamos juntos! Fase %d de %d." % [mini(int(stage.index) + 1, int(stage.count)), int(stage.count)]


static func _title_row(box: VBoxContainer, id: String, def: Dictionary) -> void:
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(UiKit.ui_icon(str(def.get("icon", "tab_park"))), 48))
	var bar := UiKit.bar(float(GameState.project_stage(id).total_progress) * 100.0, Palette.PRIMARY, 14)
	bar.name = "ProjectBar"
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	box.add_child(row)


## Fases em fileira: feita (check), atual (destaque) e próximas (apagadas).
static func _phase_row(box: VBoxContainer, id: String, def: Dictionary) -> void:
	var stage := GameState.project_stage(id)
	# Quebra de linha: nomes de fase mais compridos com ✓ não cabem lado a lado em 360 px.
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	row.name = "ProjectPhases"
	var phases: Array = def.phases
	for position: int in phases.size():
		var done: bool = position < int(stage.index) or GameState.project_completed(id)
		var chip := UiKit.chip(UiKit.ctl_icon("check") if done else null, str(phases[position].get("name", phases[position].id)), UiKit.GOOD if done else null)
		chip.name = "Phase_" + str(phases[position].id)
		if not done and position != int(stage.index):
			chip.modulate.a = 0.55
		row.add_child(chip)
	box.add_child(row)


static func _start_card(box: VBoxContainer, id: String, def: Dictionary) -> void:
	var card := UiKit.card(box)
	card.add_child(UiKit.label("Você entrega o material aos poucos. O que entregar não volta e a obra não vence.", &"SmallLabel"))
	var reason := GameState.project_error(id)
	var fee := int(def.get("start_coins", 0))
	if reason != "":
		card.add_child(UiKit.lock_hint(reason))
		return
	var start := UiKit.primary("Começar por %d moedas" % fee, func() -> void:
		var error := GameState.start_project(id)
		if error != "":
			Events.toast_requested.emit(error), UiKit.ui_icon("coin"))
	start.name = "StartProject"
	card.add_child(start)


static func _delivery_card(box: VBoxContainer, id: String, model: Dictionary) -> void:
	var stage := GameState.project_stage(id)
	if bool(stage.done):
		box.add_child(UiKit.label("Quase! A obra termina já já.", &"SmallLabel"))
		return
	var card := UiKit.card(box)
	card.add_child(UiKit.label("Fase %d de %d" % [int(stage.index) + 1, int(stage.count)], &"SectionLabel"))
	# A seleção sobrevive às reconstruções; se o item já está completo, passa ao próximo que falta.
	var remaining: Dictionary = stage.remaining
	if int(remaining.get(str(model.item), 0)) <= 0:
		model.item = ""
		for item: String in remaining:
			if int(remaining[item]) > 0:
				model.item = item
				break
		model.qty = 1
	var tiles := GridContainer.new()
	tiles.name = "ProjectItems"
	tiles.columns = 3
	tiles.add_theme_constant_override("h_separation", 6)
	tiles.add_theme_constant_override("v_separation", 6)
	for item: String in stage.needed:
		var left := int(remaining[item])
		var selected := str(model.item) == item
		var caption := "%d/%d" % [int(stage.given[item]), int(stage.needed[item])]
		var tile := UiKit.grid_tile(Database.item_icon(item), "%s\n%s" % [Database.item_name(item), caption], func() -> void:
			model.item = item
			model.qty = 1
			(box as SheetBuilder.LiveBox).refresh(), 100, 40)
		tile.custom_minimum_size = Vector2(0, 120)
		tile.name = "ProjectItem_" + item
		if left <= 0:
			tile.modulate.a = 0.5
		if selected:
			tile.add_theme_stylebox_override("normal", _selected_style())
		tiles.add_child(tile)
	card.add_child(tiles)
	var chosen := str(model.item)
	if chosen == "":
		return
	var have := GameState.inventory.count(chosen)
	var most := mini(int(remaining[chosen]), have)
	card.add_child(UiKit.label("%s: faltam %d · você tem %d" % [Database.item_name(chosen), int(remaining[chosen]), have], &"SmallLabel"))
	if most <= 0:
		var help := UiKit.tap_chip(Database.item_icon(chosen), "%s: onde achar?" % Database.item_name(chosen), TaskHelp.open.bind("item", chosen, int(remaining[chosen])), UiKit.BAD)
		help.name = "ProjectMissing"
		card.add_child(help)
		return
	model.qty = clampi(int(model.qty), 1, most)
	var row := UiKit.hbox(6)
	row.name = "ProjectQuantity"
	for entry: Dictionary in [{"label": "−", "change": -1}, {"label": "+", "change": 1}, {"label": "Tudo", "change": 0}]:
		var button := UiKit.secondary(str(entry.label), func() -> void:
			model.qty = most if int(entry.change) == 0 else clampi(int(model.qty) + int(entry.change), 1, most)
			(box as SheetBuilder.LiveBox).refresh(), null, true)
		button.name = "Qty_" + ("all" if int(entry.change) == 0 else "plus" if int(entry.change) > 0 else "minus")
		row.add_child(button)
	card.add_child(row)
	var amount := int(model.qty)
	var deliver := UiKit.primary("Entregar ×%d %s" % [amount, Database.item_name(chosen)], func() -> void:
		var error := GameState.contribute_project(id, chosen, amount)
		if error != "":
			Events.toast_requested.emit(error)
		else:
			Events.toast_requested.emit("Entregue: %s ×%d" % [Database.item_name(chosen), amount]))
	deliver.name = "DeliverProject"
	card.add_child(deliver)


static func _done_card(box: VBoxContainer, def: Dictionary) -> void:
	var card := UiKit.card(box, &"ReadyCardPanel")
	card.add_child(UiKit.label("Obra pronta!", &"SectionLabel"))
	card.add_child(UiKit.label(str(def.get("interaction", {}).get("hint", "")), &"SmallLabel"))
	var go: Dictionary = def.get("go", {})
	if not go.is_empty():
		var button := UiKit.secondary(str(def.get("interaction", {}).get("go_label", "Ir até lá")), func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(str(go.get("world", "")), str(go.get("place", ""))))
		button.name = "GoProject"
		card.add_child(button)


## Opção repetível depois da obra (ex.: "Encontro da turma"): material, espera e um botão. Sem obrigação.
static func _gathering_card(box: VBoxContainer, id: String) -> void:
	var def := GameState.meeting_def(id)
	var card := UiKit.card(box)
	card.name = "GatheringCard"
	card.add_child(UiKit.label(str(def.get("name", "Encontro")), &"SectionLabel"))
	card.add_child(UiKit.label(str(def.get("hint", "")), &"SmallLabel"))
	var chips := UiKit.flow()
	for item: String in def.items:
		chips.add_child(ProgressionUi.item_chip(item, int(def.items[item])))
	card.add_child(chips)
	var reason := GameState.meeting_error(id)
	if reason != "":
		card.add_child(UiKit.lock_hint(reason))
		return
	var go := UiKit.primary("Fazer o " + str(def.get("name", "encontro")), func() -> void:
		var error := GameState.gather_project(id)
		if error != "":
			Events.toast_requested.emit(error))
	go.name = "GatherProject"
	card.add_child(go)


static func _selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.CARD
	style.border_color = Palette.PRIMARY
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	return style
