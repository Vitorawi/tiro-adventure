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
			var seen := completed or GameState.project_started(id)
			var action: Button = UiKit.soft("Ver", open.bind(id), null, true) if seen else UiKit.small_go("Começar", open.bind(id))
			var row := UiKit.list_row(UiKit.ui_icon(str(def.get("icon", "tab_park"))), str(def.name), chips, action, open.bind(id))
			row.name = "Project_" + id
			box.add_child(row)
		for place_id: String in Database.worlds[world].places.get("community", {}).get("services", []):
			var place: Dictionary = Database.worlds[world].places.get(place_id, {})
			if place.is_empty() or Places.place_error(place) != "":
				continue
			var row := UiKit.list_row(UiKit.ui_icon(str(place.icon)), str(place.name), [], UiKit.soft("Ir", Places.open.bind(world, place_id), null, true), Places.open.bind(world, place_id))
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
	var bar := UiKit.bar(float(GameState.project_stage(id).total_progress) * 100.0, Palette.SKY, 14)
	bar.name = "ProjectBar"
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	box.add_child(row)


## Fases em fileira: feita (check), atual (destaque) e próximas (apagadas).
static func _phase_row(box: VBoxContainer, id: String, def: Dictionary) -> void:
	var stage := GameState.project_stage(id)
	# Traços grandes (feita verde, atual mel, próximas afundadas) + o nome da fase atual num chip.
	var phases: Array = def.phases
	var completed := GameState.project_completed(id)
	var current := phases.size() if completed else int(stage.index)
	var row := UiKit.vbox(8)
	row.name = "ProjectPhases"
	var dashes := UiKit.steps(phases.size(), current)
	dashes.name = "ProjectSteps"
	for dash: Node in dashes.get_children():
		(dash as Control).custom_minimum_size = Vector2(0, 8)
		(dash as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(dashes)
	var shown := mini(current, phases.size() - 1)
	var chip := UiKit.chip(null, str(phases[shown].get("name", phases[shown].id)), null, "have" if completed else "neutral")
	chip.name = "Phase_" + str(phases[shown].id)
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
	tiles.add_theme_constant_override("h_separation", 8)
	tiles.add_theme_constant_override("v_separation", 8)
	for item: String in stage.needed:
		var left := int(remaining[item])
		var caption := "%d/%d" % [int(stage.given[item]), int(stage.needed[item])]
		var tile := UiKit.tile(Database.item_icon(item), caption, "selected" if str(model.item) == item else "normal")
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.pressed.connect(func() -> void:
			model.item = item
			model.qty = 1
			(box as SheetBuilder.LiveBox).refresh())
		tile.name = "ProjectItem_" + item
		if left <= 0:
			tile.modulate.a = 0.5
		tiles.add_child(tile)
	card.add_child(tiles)
	var chosen := str(model.item)
	if chosen == "":
		return
	var have := GameState.inventory.count(chosen)
	var most := mini(int(remaining[chosen]), have)
	var counts := UiKit.flow(4)
	counts.add_child(UiKit.chip(Database.item_icon(chosen), "faltam %d" % int(remaining[chosen])))
	counts.add_child(UiKit.chip(null, "tem %d" % have, null, "have" if have > 0 else "missing"))
	card.add_child(counts)
	if most <= 0:
		var help := UiKit.tap_chip(Database.item_icon(chosen), "%s: onde achar?" % Database.item_name(chosen), TaskHelp.open.bind("item", chosen, int(remaining[chosen])), UiKit.BAD)
		help.name = "ProjectMissing"
		card.add_child(help)
		return
	model.qty = clampi(int(model.qty), 1, most)
	var amount := int(model.qty)
	var row := UiKit.hbox(8)
	row.name = "ProjectQuantity"
	var stepper := UiKit.stepper(amount, 1, most, func(value: int) -> void:
		model.qty = value
		(box as SheetBuilder.LiveBox).refresh())
	row.add_child(stepper)
	var all := UiKit.soft("Tudo", func() -> void:
		model.qty = most
		(box as SheetBuilder.LiveBox).refresh(), null, true)
	all.name = "Qty_all"
	row.add_child(all)
	card.add_child(row)
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
		var button := UiKit.soft(str(def.get("interaction", {}).get("go_label", "Ir até lá")), func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(str(go.get("world", "")), str(go.get("place", ""))))
		button.name = "GoProject"
		card.add_child(button)


## Opção repetível depois da obra (ex.: "Encontro da turma"): material, espera e um botão. Sem obrigação.
static func _gathering_card(box: VBoxContainer, id: String) -> void:
	var def := GameState.meeting_def(id)
	var card := UiKit.card(box)
	card.name = "GatheringCard"
	(card.get_parent() as PanelContainer).add_theme_stylebox_override("panel", UiKit.surface(Palette.HONEY_SOFT, 20))  # cartão mel
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


