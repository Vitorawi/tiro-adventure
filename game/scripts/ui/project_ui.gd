class_name ProjectUi
extends RefCounted
## Painéis das obras comunitárias (data/projects.json), em madeira ilustrada. Só apresenta e chama as ações do GameState
## (start_project/contribute_project): nada aqui paga, consome ou conclui por conta própria.
## `panel(id)` serve a qualquer projeto; `community()` é a lista "Nossa praça" (obras + serviços da Praça).
## `row(...)`, `chevron()` e `wood_sheet(...)` são peças de madeira reaproveitadas por outras listas (amigos, truques, casa, loja).


## Folha em madeira com a altura do conteúdo (opt-in da `Sheet`).
static func wood_sheet(content: Control) -> Control:
	content.set_meta("sheet_wood", true)
	content.set_meta("sheet_fit_content", true)
	return content


## Linha de papel: pratinho com o ícone, título (e chips opcionais embaixo) e um `tail` à direita (medalhão, seta, botão...).
## Com `go` válido a linha inteira é tocável (botão transparente por cima); sem `go`, só o `tail` recebe toque.
static func row(node_name: String, texture: Texture2D, title: String, chips: Array[Control], tail: Control, go: Callable, dim: bool = false) -> Control:
	var card := MissionUi.card("card", Vector4i(10, 6, 12, 6), node_name, 10, 56.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line := UiKit.hbox(10)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MissionUi.body(card).add_child(line)
	var plate := HelpUi._plate(texture, "", 52.0, 64.0, "RowIcon")
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(plate)
	var text := UiKit.vbox(3)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := StepCardUi.wood(title, 18)
	label.name = "RowTitle"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(label)
	if not chips.is_empty():
		var flow := HFlowContainer.new()
		flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 4)
		for chip: Control in chips:
			flow.add_child(chip)
		text.add_child(flow)
	line.add_child(text)
	if dim:
		plate.modulate.a = 0.55
		label.modulate.a = 0.6
	if tail != null:
		tail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(tail)
	if go.is_valid():
		var tap := BagUi.plain_button(go)
		tap.name = "RowGo"
		card.add_child(tap)
	return card


## Seta de madeira ("RowChevron") no fim de uma linha tocável.
static func chevron() -> Control:
	var arrow := UiKit.ctl("chev", 22, Palette.WOOD_INK)
	arrow.name = "RowChevron"
	return arrow


## Prêmios em pílulas de madeira (moeda, itens, roupa): versão de madeira do `ProgressionUi.reward_chips`.
static func reward_chips(rewards: Dictionary) -> HFlowContainer:
	var flow := HFlowContainer.new()
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 4)
	if int(rewards.get("coins", 0)) > 0:
		flow.add_child(StepCardUi.wood_chip(UiKit.ui_icon("coin"), "+%d" % int(rewards.coins)))
	for id: String in rewards.get("items", {}):
		var label := "+%d" % int(rewards.items[id])
		if Database.items.get(id, {}).get("category", "") == "keepsake":
			label += " " + Database.item_name(id)
		flow.add_child(StepCardUi.wood_chip(Database.item_icon(id), label))
	for id: String in rewards.get("collections", []):
		if not GameState.progress.collection.has(id):
			flow.add_child(StepCardUi.wood_chip(UiKit.ui_icon("item_accessory_set"), "+1"))
	return flow


## Versão de madeira do `UiKit.action_or_hint`: sem motivo devolve a ação; com motivo, o botão bloqueado de madeira
## (nome `Locked_<ação>`, meta `reason`, cadeado + motivo; o "?" só com `on_help`) no lugar dela.
static func action_or_note(action: Control, reason: String, on_help: Callable = Callable(), missing: Texture2D = null) -> Control:
	if reason == "":
		return action
	var note := StepCardUi.lock_note(reason, on_help, missing)
	note.name = "Locked_" + str(action.name)
	note.set_meta("reason", reason)
	action.free()
	return note


## Painel de uma obra: fala da personagem, fases, o que falta e uma única ação (Começar ou Entregar).
static func panel(id: String) -> Control:
	var model := {"item": "", "qty": 1}
	return wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "ProjectPanel"
		box.add_theme_constant_override("separation", 10)
		var def := Database.project(id)
		if def.is_empty() or Database.project_issue(id) != "":
			box.add_child(StepCardUi.wood("Em breve!", 18))
			return
		var completed := GameState.project_completed(id)
		var started := GameState.project_started(id)
		ProgressionUi.npc_header(box, str(def.get("npc", "lais")), _speech(id, def, started, completed), true, true)
		var inner := StepCardUi.inner_card(box, "ProjectCard", Vector4i(14, 12, 14, 12))
		_phase_row(inner, id, def)
		if completed:
			_done_card(inner, def)
			if not GameState.meeting_def(id).is_empty():
				_gathering_card(box, id)
		elif not started:
			_start_card(inner, id, def)
		else:
			_delivery_card(inner, box, id, model)
	))


## Lista "Nossa praça"/"Nossa vila": obras do mundo que já apareceram e os serviços (`services` do lugar
## `community` em worlds.json) que moram ali.
static func community(world: String = "park") -> Control:
	return wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "CommunityList"
		box.add_theme_constant_override("separation", 8)
		for id: String in Database.project_ids():
			var def := Database.project(id)
			if str(def.get("world", "")) != world or not GameState.project_available(id):
				continue
			var stage := GameState.project_stage(id)
			var completed := GameState.project_completed(id)
			var chips: Array[Control] = []
			var tail: Control = chevron()
			if completed:
				tail.free()
				tail = StepCardUi.done_medal(26.0, "ProjectDone")
			elif GameState.project_started(id):
				chips.append(StepCardUi.wood_chip(null, "Fase %d/%d" % [mini(int(stage.index) + 1, int(stage.count)), int(stage.count)]))
				chips.append(StepCardUi.wood_chip(null, "%d%%" % int(round(float(stage.total_progress) * 100.0))))
			else:
				chips.append(StepCardUi.wood_chip(UiKit.ui_icon("coin"), str(int(def.get("start_coins", 0)))))
			box.add_child(row("Project_" + id, UiKit.ui_icon(str(def.get("icon", "tab_park"))), str(def.name), chips, tail, open.bind(id)))
		for place_id: String in Database.worlds[world].places.get("community", {}).get("services", []):
			var place: Dictionary = Database.worlds[world].places.get(place_id, {})
			if place.is_empty() or Places.place_error(place) != "":
				continue
			var no_chips: Array[Control] = []
			box.add_child(row("Service_" + place_id, UiKit.ui_icon(str(place.icon)), str(place.name), no_chips, chevron(), Places.open.bind(world, place_id)))
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


## Fases em fileira: feita (verde), atual (mel) e próximas (apagadas), mais o nome da fase atual numa pílula de madeira.
static func _phase_row(box: VBoxContainer, id: String, def: Dictionary) -> void:
	var stage := GameState.project_stage(id)
	var phases: Array = def.phases
	var completed := GameState.project_completed(id)
	var current := phases.size() if completed else int(stage.index)
	var column := UiKit.vbox(8)
	column.name = "ProjectPhases"
	var dashes := UiKit.hbox(4)
	dashes.name = "ProjectSteps"
	for i in phases.size():
		var dash := Panel.new()
		dash.custom_minimum_size = Vector2(0, 10)
		dash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.GO if i < current else (Palette.WOOD_PICK if i == current else Palette.WOOD_INSET)
		style.border_color = Color("c9935f")
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		dash.add_theme_stylebox_override("panel", style)
		dashes.add_child(dash)
	column.add_child(dashes)
	var shown := mini(current, phases.size() - 1)
	var chip := StepCardUi.wood_chip(null, str(phases[shown].get("name", phases[shown].id)), "have" if completed else "")
	chip.name = "Phase_" + str(phases[shown].id)
	chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(chip)
	box.add_child(column)


static func _note(box: VBoxContainer, text: String) -> void:
	var label := StepCardUi.wood(text, 15, Color(Palette.WOOD_INK, 0.85))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 100.0
	box.add_child(label)


static func _start_card(inner: VBoxContainer, id: String, def: Dictionary) -> void:
	_note(inner, "Você entrega o material aos poucos. O que entregar não volta e a obra não vence.")
	var reason := GameState.project_error(id)
	var fee := int(def.get("start_coins", 0))
	if reason != "":
		inner.add_child(StepCardUi.lock_note(reason))
		return
	var start := ProjectUi.green("Começar por %d moedas" % fee, func() -> void:
		var error := GameState.start_project(id)
		if error != "":
			Events.toast_requested.emit(error))
	start.name = "StartProject"
	inner.add_child(start)


static func _delivery_card(inner: VBoxContainer, box: VBoxContainer, id: String, model: Dictionary) -> void:
	var stage := GameState.project_stage(id)
	if bool(stage.done):
		_note(inner, "Quase! A obra termina já já.")
		return
	_note(inner, "Fase %d de %d" % [int(stage.index) + 1, int(stage.count)])
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
	tiles.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for item: String in stage.needed:
		var left := int(remaining[item])
		var cell := UiKit.vbox(4)
		cell.custom_minimum_size.x = 80.0
		var pick := func() -> void:
			model.item = item
			model.qty = 1
			(box as SheetBuilder.LiveBox).refresh()
		var tile := CodexUi.tile({
			"name": "ProjectItem_" + item, "icon": Database.item_icon(item),
			"selected": str(model.item) == item, "on_tap": pick,
		}, 76.0, 76.0)
		tile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(tile)
		var count := StepCardUi.wood_chip(null, "%d/%d" % [int(stage.given[item]), int(stage.needed[item])], "have" if left <= 0 else "missing", Callable(), "ProjectCount_" + item)
		count.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cell.add_child(count)
		tiles.add_child(cell)
	inner.add_child(tiles)
	var chosen := str(model.item)
	if chosen == "":
		return
	var have := GameState.inventory.count(chosen)
	var most := mini(int(remaining[chosen]), have)
	if most <= 0:
		var ask := TaskHelp.open.bind("item", chosen, int(remaining[chosen]))
		var no_chips: Array[Control] = []
		inner.add_child(row("ProjectMissing", Database.item_icon(chosen), "%s: onde achar?" % Database.item_name(chosen), no_chips, chevron(), ask))
		return
	model.qty = clampi(int(model.qty), 1, most)
	var amount := int(model.qty)
	# A ação fica na tábua de madeira (como nas estações): quantidade e o único botão verde.
	var actions := UiKit.vbox(6)
	actions.name = "ProjectQuantity"
	var stepper := StationWood.stepper(amount, most, func(value: int) -> void:
		model.qty = value
		(box as SheetBuilder.LiveBox).refresh())
	stepper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	actions.add_child(stepper)
	var deliver := ProjectUi.green("Entregar ×%d %s" % [amount, Database.item_name(chosen)], func() -> void:
		var error := GameState.contribute_project(id, chosen, amount)
		if error != "":
			Events.toast_requested.emit(error)
		else:
			Events.toast_requested.emit("Entregue: %s ×%d" % [Database.item_name(chosen), amount]))
	deliver.name = "DeliverProject"
	actions.add_child(deliver)
	box.add_child(StationWood.board(actions))


static func _done_card(inner: VBoxContainer, def: Dictionary) -> void:
	var head := UiKit.hbox(8)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(StepCardUi.done_medal(28.0, "ProjectReady"))
	head.add_child(StepCardUi.wood("Obra pronta!", 20))
	inner.add_child(head)
	_note(inner, str(def.get("interaction", {}).get("hint", "")))
	var go: Dictionary = def.get("go", {})
	if not go.is_empty():
		var button := WelcomeSheet._button(str(def.get("interaction", {}).get("go_label", "Ir até lá")), false, 200.0, "GoProject", func() -> void:
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(str(go.get("world", "")), str(go.get("place", ""))))
		inner.add_child(button)


## Opção repetível depois da obra (ex.: "Encontro da turma"): material, espera e um botão. Sem obrigação.
static func _gathering_card(box: VBoxContainer, id: String) -> void:
	var def := GameState.meeting_def(id)
	var inner := StepCardUi.inner_card(box, "GatheringCard")
	var title := StepCardUi.wood(str(def.get("name", "Encontro")), 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(title)
	_note(inner, str(def.get("hint", "")))
	var chips := HFlowContainer.new()
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_theme_constant_override("v_separation", 4)
	for item: String in def.items:
		var need := int(def.items[item])
		var have := GameState.inventory.count(item)
		chips.add_child(StepCardUi.wood_chip(Database.item_icon(item), "%d/%d" % [have, need], "have" if have >= need else "missing", TaskHelp.open.bind("item", item, need)))
	inner.add_child(chips)
	var reason := GameState.meeting_error(id)
	if reason != "":
		inner.add_child(StepCardUi.lock_note(reason))
		return
	var go := ProjectUi.green("Fazer o " + str(def.get("name", "encontro")), func() -> void:
		var error := GameState.gather_project(id)
		if error != "":
			Events.toast_requested.emit(error))
	go.name = "GatherProject"
	inner.add_child(go)


## Botão verde de madeira (a ação principal da folha), marcado com `wood_primary` para o "um verde por tela".
static func green(caption: String, on_pressed: Callable, icon: Texture2D = null) -> Button:
	var button := StepCardUi.go_button(caption, on_pressed, icon)
	button.set_meta("wood_primary", true)
	return button
