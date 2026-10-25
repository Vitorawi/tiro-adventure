class_name GrowthUi
extends RefCounted
## Consulta do crescimento. Toda ação continua no GameState; o painel atualiza sem fechar.

static func open() -> void:
	Events.sheet_requested.emit("Crescimento", panel())


static func panel() -> Control:
	var box := SheetBuilder.LiveBox.new(_build)
	box.name = "GrowthPanel"
	box.set_meta("tick_refresh", false)
	box.set_meta("sheet_size", "tall")
	return box


static func missing(info: Dictionary) -> int:
	return info.requirements.filter(func(row: Dictionary) -> bool: return not row.done).size()


## Quanto da próxima fase está pronto: requisito cumprido vale 1; momentos parciais valem a fração deles.
static func fraction(info: Dictionary) -> float:
	var rows: Array = info.requirements
	if rows.is_empty():
		return 1.0
	var sum := 0.0
	for row: Dictionary in rows:
		if row.done: sum += 1.0
		elif row.type == "moments": sum += clampf(float(row.have) / maxf(1.0, float(row.need)), 0.0, 1.0)
	return sum / rows.size()


## Resumo do avatar: só o que falta, com a ação de cada passo (toque leva a fazer).
static func compact_steps(info: Dictionary) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	for req: Dictionary in info.requirements:
		if req.done or req.type == "given": continue
		var step := step_view(req)
		step["title"] = step.short
		steps.append(step)
	return steps


const PILLAR_SHORT := {"brave": "Carinho", "smart": "Brincar", "coat": "Banho"}
const PILLAR_ACTION_ICON := {"brave": "action_pet", "smart": "action_play", "coat": "action_bathe"}
const PILLAR_NEED := {"brave": "happiness", "smart": "happiness", "coat": "hygiene"}


## Um passo para crescer em forma de ação: ícone, quantidade, dica de uma linha e o que o botão faz.
## Consulta pura: nunca conta nem entrega nada.
static func step_view(req: Dictionary) -> Dictionary:
	var need := int(req.need)
	var have := need if req.done else mini(int(req.have), need)
	var view := {"id": str(req.id), "type": str(req.type), "title": str(req.label), "short": str(req.label),
		"pillar": str(req.get("pillar", "")), "item": str(req.get("item", "")),
		"have": have, "need": need, "done": bool(req.done), "unit": "", "hint": "", "hint_good": false,
		"action": "Ir", "callback": TaskHelp.open.bind("growth_req", str(req.id)), "give": "",
		"icon": TaskHelp.icon_for("growth_req", str(req.id))}
	match str(req.type):
		"moments":
			view.short = str(PILLAR_SHORT.get(view.pillar, req.label))
			view.title = str({"brave": "Carinho", "smart": "Brincadeiras", "coat": "Banho e escova"}.get(view.pillar, req.label))
			view.icon = UiKit.ui_icon(str(PILLAR_ACTION_ICON.get(view.pillar, "action_pet")))
		"feed":
			view.short = "Refeições"
			view.unit = "refeições"
			var food := GameState.favorite_food() if req.item == "favorite" else str(req.item)
			if req.item == "any": view.title = "Dar comida"
			elif req.item == "favorite" and not GameState.favorite_found(): view.title = "Comida favorita"
			else: view.title = Database.item_name(food)
		"deliver":
			view.short = Database.item_name(view.item).get_slice(" ", 0)
			view.unit = "entregue"
		"stat":
			if str(req.get("counter", "")) == "walk":
				view.short = "Passeios"
				view.title = "Passear"
				view.unit = "passeios"
				view.icon = UiKit.ui_icon("action_walk")
		"owned":
			view.short = str(Database.progression.upgrades[str(req.upgrade)].name).get_slice(" ", 0)
		"collection":
			view.short = str(req.label).get_slice(" ", 0)
			view.icon = UiKit.ui_icon(str(Database.collections.get(str(req.collection), {}).get("icon", "action_sew")))
	if req.done: return view
	var help := TaskHelp.describe("growth_req", str(req.id))
	var go := TaskHelp._go.bind(help.target)
	match str(req.type):
		"moments":
			var pillar := str(view.pillar)
			view.action = str({"brave": "Fazer carinho", "smart": "Brincar", "coat": "Dar banho"}.get(pillar, "Ir"))
			view["action_short"] = str({"brave": "Carinho", "smart": "Brincar", "coat": "Banho"}.get(pillar, "Ir"))
			view.callback = TaskHelp._go.bind({"screen": "pet"})
			var asking := GameState.asking_need()
			if asking != "" and asking == PILLAR_NEED.get(pillar, "") and GameState.need_pillar(asking) == pillar:
				view.hint = "Ele está pedindo agora!"
				view.hint_good = true
			else:
				view.hint = "Quando pedir ou escovar" if pillar == "coat" else "Quando ele pedir"
		"feed":
			var food := GameState.favorite_food() if req.item == "favorite" else str(req.item)
			if help.has("food_guide"):
				var guide: Dictionary = help.food_guide
				var stock := GameState.inventory.count(food)
				view.callback = TaskHelp._go.bind(guide.target)
				if stock > 0:
					view.hint = "Você tem %d · dê na Tigela" % stock
					view.hint_good = true
					view.action = "Dar comida"
				elif str(guide.action).begins_with("Pegar"):
					view.hint = "Pronta para pegar"
					view.hint_good = true
					view.action = "Pegar"
				elif str(guide.status).begins_with("Para preparar, falta: "):
					view.hint = "Falta: " + str(guide.status).trim_prefix("Para preparar, falta: ").get_slice(".", 0)
					view.action = "Ver como"
					view.callback = TaskHelp.open.bind("growth_req", str(req.id))
				elif str(guide.status).begins_with("Falta conseguir"):
					view.hint = "Faltam ingredientes"
					view.action = "Ver o que falta"
					view["action_short"] = "Ver"
					view.callback = TaskHelp.open.bind("growth_req", str(req.id))
				elif str(guide.status).begins_with("A fila"):
					view.hint = "Fila cheia"
					view.action = "Ver fila"
				else:
					view.hint = "Prepare em " + str(guide.place)
					view.action = "Preparar"
			elif req.item == "favorite" and not GameState.favorite_found():
				view.hint = "Prove comidas novas"
				view.action = "Ver como"
			else:
				view.hint = "Qualquer comida conta" if req.item == "any" else "Dê na Tigela"
				view.action = "Dar comida"
				view.callback = go
		"deliver":
			if GameState.deliver_growth_error(view.item) == "":
				view.hint = "Você já tem!"
				view.hint_good = true
				view.action = "Dar"
				view.give = view.item
				view.callback = _deliver.bind(view.item)
			else:
				view.hint = _source_hint(view.item)
				if view.hint.begins_with("Faça"): view.action = "Fazer"
				view.callback = go
		"stat":
			if str(req.get("counter", "")) == "walk":
				view.hint = "Pelo portão da Praça"
				view.action = "Passear"
			view.callback = go
		"owned":
			view.hint = "Compre para ele"
			view.callback = go
		"collection":
			view.hint = "Faça na Costura da Praça"
			view.action = "Fazer"
			view.callback = go
		_:
			view.callback = go
	return view


## Onde nasce a lembrança, numa linha: quem dá, qual estação faz ou onde se acha.
static func _source_hint(item: String) -> String:
	var giver := TaskHelp.reward_source_text(item)
	if giver != "": return giver.split(" · ")[0]
	var source := TaskHelp.best_source(item)
	match str(source.get("kind", "")):
		"recipe": return "Faça na " + str(Database.stations[str(Database.recipes[str(source.id)].station)].name)
		"crop": return "Colha na Horta"
		"route": return "Busque em " + str(Database.progression.activities[str(source.id)].name)
	return "Veja onde conseguir"


## O passo que vale fazer primeiro: lembrança já na mão, cuidado que ele está pedindo, a comida
## (começo concreto) e, por fim, o primeiro que falta.
static func recommended(info: Dictionary) -> Dictionary:
	var pending: Array = info.requirements.filter(func(row: Dictionary) -> bool: return not row.done and row.type != "given")
	if pending.is_empty(): return {}
	for req: Dictionary in pending:
		if req.type == "deliver" and GameState.deliver_growth_error(str(req.item)) == "": return req
	for req: Dictionary in pending:
		if req.type == "moments" and bool(step_view(req).hint_good): return req
	for req: Dictionary in pending:
		if req.type == "feed": return req
	return pending[0]


## Barra em segmentos: um por passo, verde quando feito.
static func progress_strip(done: int, total: int, height: int = 10) -> HBoxContainer:
	var strip := UiKit.hbox(4)
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in maxi(1, total):
		var piece := Panel.new()
		piece.name = "Segment_%d" % i
		piece.custom_minimum_size = Vector2(0, height)
		piece.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := UiKit.surface(Palette.GO if i < done else Palette.SUNKEN, height / 2)
		piece.add_theme_stylebox_override("panel", style)
		piece.set_meta("filled", i < done)
		strip.add_child(piece)
	return strip


## Anel com o ícone do passo: enche conforme a quantidade.
static func step_ring(step: Dictionary, px: int) -> RingProgress:
	var ring := RingProgress.new()
	ring.custom_minimum_size = Vector2(px, px)
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.texture = step.icon
	ring.progress = float(step.have) / maxf(1.0, float(step.need))
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return ring


static func _build(box: VBoxContainer) -> void:
	var info := GameState.growth_info()
	var silk := GameState.silk_info()
	box.set_meta("phase", info.phase)
	var visible_steps: Array = info.requirements.filter(func(req: Dictionary) -> bool: return req.type != "given")
	var complete: int = visible_steps.filter(func(req: Dictionary) -> bool: return req.done).size()
	box.add_child(_hero(info))
	if not info.next.is_empty():
		var text := "Tudo pronto para crescer!" if info.ready else "%d de %d passos · falta %d" % [complete, visible_steps.size(), visible_steps.size() - complete]
		var summary := UiKit.label(text, &"SmallLabel", Palette.GO_INK if info.ready else Palette.INK_SOFT)
		summary.name = "GrowthSummary"
		summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(summary)
		var progress := progress_strip(complete, visible_steps.size(), 8)
		progress.name = "GrowthProgress"
		box.add_child(progress)
		_steps(box, info, visible_steps)
		if info.ready:
			var grow := UiKit.primary("Crescer!", func() -> void:
				var error := GameState.grow()
				if error != "": Events.toast_requested.emit(error))
			grow.name = "GrowButton"
			box.add_child(grow)
		box.add_child(_unlocks(info))
	elif silk.adult and not silk.next.is_empty():
		box.add_child(silhouette(info.current, silk.requirements.filter(func(row: Dictionary) -> bool: return row.done).size(), silk.ready, "SilkSilhouette", 64))
		box.add_child(UiKit.label(str(silk.next.name), &"SectionLabel"))
		_silk_requirements(box, silk)
		if silk.ready:
			var shine := UiKit.primary("Mais brilho!", func() -> void:
				var error := GameState.brighten()
				if error != "": Events.toast_requested.emit(error))
			shine.name = "SilkButton"
			box.add_child(shine)
		else:
			var lacking: Dictionary = silk.requirements.filter(func(row: Dictionary) -> bool: return not row.done)[0]
			var wait := UiKit.lock_hint("Falta: " + str(lacking.label))
			wait.name = "SilkLock"
			box.add_child(wait)
	else:
		box.add_child(UiKit.label("Ele cresceu com você. Continue cuidando do Tiro!"))


## Agora → depois: o Tiro de hoje e a silhueta da próxima fase, que se revela a cada passo feito.
## À direita, dois botões pequenos: Cuidados do Tiro e Caderneta.
static func _hero(info: Dictionary) -> Control:
	var hero := UiKit.hbox(4)
	hero.name = "GrowthHero"
	var trio := UiKit.hbox(4)
	trio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trio.alignment = BoxContainer.ALIGNMENT_CENTER
	var now := UiKit.vbox(2)
	var dog := PetAnimator.portrait(64)
	dog.name = "CurrentDog"
	dog.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	now.add_child(dog)
	now.add_child(_phase_name(str(info.current.name)))
	trio.add_child(now)
	if not info.next.is_empty():
		var arrow := _center("→", &"TitleLabel")
		arrow.name = "GrowthArrow"
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		arrow.add_theme_color_override("font_color", Palette.GO_INK if info.ready else Palette.INK_SOFT)
		trio.add_child(arrow)
		var then := UiKit.vbox(2)
		then.add_child(silhouette(info.next, info.requirements.size() - missing(info), info.ready, "NextSilhouette", 64))
		then.add_child(_phase_name(str(info.next.name)))
		trio.add_child(then)
	hero.add_child(trio)
	var side := UiKit.vbox(6)
	side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var details := UiKit.ctl_button("info", func() -> void: Events.sheet_requested.emit("Cuidados do Tiro", PillarUi.panel()), 40)
	details.name = "GrowthDetails"
	side.add_child(details)
	var book := UiKit.ctl_button("list", history, 40)
	book.name = "GrowthHistoryButton"
	side.add_child(book)
	hero.add_child(side)
	return hero


## Nome da fase sob o retrato: uma linha só, um pouco menor para caber lado a lado.
static func _phase_name(text: String) -> Label:
	var result := UiKit.short_label(text, &"StrongLabel")
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result


## Grade de passos (feitos e por fazer) + faixa de detalhe do passo escolhido.
## Tocar num quadradinho só escolhe; a escolha sobrevive às reconstruções do painel.
static func _steps(box: VBoxContainer, info: Dictionary, visible_steps: Array) -> void:
	var views: Dictionary = {}
	var tiles: Dictionary = {}
	var details: Dictionary = {}
	var first := recommended(info)
	var first_id := str(first.get("id", ""))
	var chosen := str(box.get_meta("selected", ""))
	var chosen_done := bool(box.get_meta("selected_done", false))
	for req: Dictionary in visible_steps:
		views[str(req.id)] = step_view(req)
	if not views.has(chosen) or (bool(views[chosen].done) and not chosen_done) or info.ready:
		chosen = first_id
	var grid := GridContainer.new()
	grid.name = "GrowthSteps"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(grid)
	var select := func(id: String) -> void:
		box.set_meta("selected", id)
		box.set_meta("selected_done", bool(views[id].done))
		for key: String in tiles:
			_style_tile(tiles[key], bool(views[key].done), key == id)
			if details.has(key): details[key].visible = key == id
	for req: Dictionary in visible_steps:
		var id := str(req.id)
		var tile := _step_tile(views[id])
		if not info.ready: tile.pressed.connect(select.bind(id))
		_style_tile(tile, bool(views[id].done), id == chosen and not info.ready)
		tiles[id] = tile
		grid.add_child(tile)
	if first_id == "" or info.ready:
		return
	var strip := UiKit.card(box)
	strip.get_parent().name = "GrowthDetail"
	for req: Dictionary in visible_steps:
		var id := str(req.id)
		var detail := _step_detail(views[id], id == first_id, req)
		detail.visible = id == chosen
		details[id] = detail
		strip.add_child(detail)


## Quadradinho de um passo: anel com o ícone (✓ quando feito), nome curto e quantidade.
static func _step_tile(step: Dictionary) -> Button:
	var tile := UiKit.button("", func() -> void: pass, &"GhostButton")
	tile.name = "GrowthReq_" + str(step.id)
	tile.custom_minimum_size = Vector2(0, 92)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.clip_contents = true
	var column := UiKit.vbox(2)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 4
	column.offset_right = -4
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	tile.add_child(column)
	var ring := step_ring(step, 44)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(ring)
	var name_label := UiKit.short_label(str(step.short), &"SmallLabel")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(name_label)
	if step.type == "moments":
		var dots := PillarUi.dots(int(step.have), int(step.need))
		dots.name = "GrowthDots_" + str(step.pillar)
		dots.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(dots)
	else:
		var count := UiKit.short_label("%d/%d" % [step.have, step.need], &"SmallLabel", Palette.GO_INK if step.done else Palette.INK_SOFT)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(count)
	if step.done:
		var check := UiKit.disc(UiKit.ctl_icon("check"), 20, 14)
		check.name = "StepCheck"
		check.add_theme_stylebox_override("panel", UiKit.surface(Palette.GO, 10))
		(check.get_child(0) as Control).modulate = Palette.CARD
		check.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		check.offset_left = -26
		check.offset_right = -6
		check.offset_top = 6
		check.offset_bottom = 26
		tile.add_child(check)
	return tile


## Fundo do quadradinho: feito = tom verde; escolhido = borda verde mais grossa.
static func _style_tile(tile: Button, done: bool, selected: bool) -> void:
	# Feito = verde claro; escolhido = fundo branco com contorno de tinta (nunca verde).
	var style := UiKit.surface(Palette.CARD if selected else (Palette.GO_SOFT if done else Palette.SUNKEN), 16, selected)
	if selected:
		style.set_border_width_all(2)
		style.border_color = Palette.INK
		style.border_blend = true
	for state: String in ["normal", "hover", "pressed", "focus"]:
		tile.add_theme_stylebox_override(state, style)


## Detalhe de um passo (um só fica visível): nome, dica de uma linha, uma ação e o "?".
static func _step_detail(step: Dictionary, highlight: bool, req: Dictionary) -> Control:
	var detail := UiKit.vbox(4)
	detail.name = "GrowthNextStep" if highlight else "GrowthDetail_" + str(step.id)
	var head := UiKit.hbox(8)
	head.add_child(UiKit.fill_label(str(step.title)))
	if not step.done:
		var help := UiKit.icon_button(UiKit.ctl_icon("help"), TaskHelp.open.bind("growth_req", str(step.id)), 40)
		help.name = "GrowthHelp"
		help.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(help)
	detail.add_child(head)
	var hint_text := str(step.hint)
	var good: bool = step.hint_good
	if step.done:
		hint_text = "Corpo completo" if req.type == "feed" and req.has("body_level") else "Feito!"
		good = true
	var hint := UiKit.label(hint_text, &"SmallLabel", Palette.GO_INK if good else Palette.INK_SOFT)
	hint.name = "GrowthSource_" + str(step.item) if step.type == "deliver" and step.give == "" else "GrowthHint_" + str(step.id)
	hint.visible = hint_text != ""
	detail.add_child(hint)
	if step.done:
		return detail
	var button: Button
	if highlight:
		button = UiKit.primary(str(step.action), step.callback)
		button.name = "GrowthNextAction"
	else:
		button = UiKit.soft(str(step.action), step.callback, null, true)
		button.name = "GrowthAct_" + str(step.id)
	button.custom_minimum_size = Vector2(160, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if step.give != "":
		button.name = "GiveGrowth_" + str(step.give)  # mesmo nome do Dar da Mochila
	detail.add_child(button)
	return detail


## O que muda quando ele crescer: dá vontade de completar.
static func _unlocks(info: Dictionary) -> Control:
	var row := UiKit.hbox(8)
	row.name = "GrowthUnlocks"
	row.add_child(UiKit.icon(UiKit.ui_icon("rare_star"), 24))
	var unlocks := UiKit.fill_label("Ao crescer: " + " · ".join(info.next.get("unlocks_text", [])), &"SmallLabel")
	unlocks.name = "NextUnlocks"
	unlocks.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(unlocks)
	return row


static func history() -> void:
	var book := SheetBuilder.LiveBox.new(_build_history)
	book.name = "GrowthHistory"
	book.set_meta("sheet_size", "tall")
	Events.sheet_requested.emit("Caderneta", book)


static func _build_history(box: VBoxContainer) -> void:
	var info := GameState.growth_info()
	var silk := GameState.silk_info()
	box.add_child(UiKit.soft("Voltar ao crescimento", open, null, true))
	box.add_child(PillarUi.personality_title())
	box.add_child(UiKit.label("Caderneta", &"SectionLabel"))
	for phase: Dictionary in info.phases:
		var card := UiKit.card(box)
		card.get_parent().name = "GrowthCard_" + str(phase.id)
		var row := UiKit.hbox(8)
		var ceremony_photo := "h_growth_" + str(phase.id)
		if phase.visited and GameState.album.has_photo(ceremony_photo):
			# Foto oficial da cerimônia (álbum): o corpo e o pelo do dia em que ele cresceu.
			var polaroid := PhotoCard.make(ceremony_photo, 72.0)
			polaroid.name = "CeremonyPhoto_" + str(phase.id)
			row.add_child(polaroid)
		elif phase.visited:
			var photo := UiKit.icon(load(str(phase.art.portrait)), 48)
			photo.material = DogLook.material()
			(photo.material as ShaderMaterial).set_shader_parameter("coat", float(phase.coat))
			row.add_child(photo)
		else:
			row.add_child(silhouette(phase, 0, false, "Future_" + str(phase.id), 64))
		row.add_child(UiKit.fill_label(str(phase.name), &"SectionLabel"))
		card.add_child(row)
		if phase.visited:
			card.add_child(UiKit.label(str(phase.age) + " · " + str(phase.weight), &"SmallLabel"))
			card.add_child(UiKit.label(_date(float(phase.at)), &"SmallLabel"))
			if phase.id == info.phase:
				var values: PackedStringArray = []
				for id: String in info.pillars: values.append("%s %d" % [info.pillars[id].title, info.pillars[id].total])
				card.add_child(UiKit.label(" · ".join(values), &"SmallLabel"))
			card.add_child(UiKit.label(str(phase.facts[0]), &"SmallLabel"))
		else:
			card.add_child(UiKit.label(str(phase.teaser), &"SmallLabel"))
			card.add_child(UiKit.lock_hint("Cap. %d" % int(phase.get("chapter", 0))))
	for n in silk.level:
		var def: Dictionary = Database.growth.silk.levels[n]
		var card := UiKit.card(box)
		card.get_parent().name = "SilkCard_%d" % (n + 1)
		card.add_child(UiKit.label(str(def.name), &"SectionLabel"))
		card.add_child(UiKit.label("Brilho %d de %d" % [n + 1, silk.max], &"SmallLabel"))


static func _silk_requirements(box: VBoxContainer, silk: Dictionary) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.name = "SilkRequirements"
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for req: Dictionary in silk.requirements:
		var tile := VBoxContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card := UiKit.card(tile, &"ReadyCardPanel" if req.done else &"CardPanel")  # mesmo cartão liso do tema
		card.add_child(UiKit.label("%s\n%d/%d%s" % [req.label, mini(int(req.have), int(req.need)), int(req.need), " ✓" if req.done else ""], &"SmallLabel"))
		tile.name = "SilkReq_" + str(req.id)
		grid.add_child(tile)


static func _center(text: String, variation: StringName = &"") -> Label:
	var result := UiKit.label(text, variation)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return result


static func _date(at: float) -> String:
	if at <= 0: return "Primeira chegada"
	var date := Time.get_date_dict_from_unix_time(int(at) + int(Time.get_time_zone_from_system().bias) * 60)
	return "Desde %02d/%02d/%d" % [date.day, date.month, date.year]


static func _deliver(item: String) -> void:
	# Origem e destino do ícone são lidos antes: o painel se refaz quando o item é entregue.
	var root := Engine.get_main_loop().root as Window
	var from := Vector2.ZERO
	var focus := root.gui_get_focus_owner() if root != null else null
	if focus != null: from = focus.get_global_rect().get_center()
	var error := GameState.deliver_growth(item)
	if error != "":
		Events.toast_requested.emit(error)
		return
	Haptics.tap()
	_fly_to_tiro(root, Database.item_icon(item), from)


## O ícone entregue voa até o Tiro do painel (some na hora com "Menos animação" ou sem painel aberto).
static func _fly_to_tiro(root: Window, icon: Texture2D, from: Vector2) -> void:
	if root == null or Motion.reduced or icon == null: return
	var dog := root.find_child("CurrentDog", true, false) as Control
	if dog == null or not dog.is_inside_tree(): return
	if from == Vector2.ZERO: from = dog.get_global_rect().get_center() + Vector2(0, 160)
	var token := DragGhost.make_token(icon)
	token.name = "FlyingKeepsake"
	token.z_index = 200
	root.add_child(token)
	var half := token.size / 2.0
	token.global_position = from - half
	var tween := token.create_tween()
	tween.tween_property(token, "global_position", dog.get_global_rect().get_center() - half, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(token.queue_free)


static func silhouette(phase: Dictionary, completed: int, ready: bool, node_name: String, px: int) -> Control:
	var holder := Control.new()
	holder.name = node_name
	holder.custom_minimum_size = Vector2(px, px + 20)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image := UiKit.icon(load(str(phase.art.dir.pet) + "idle_breathe/frame_00.png"), px)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material := ShaderMaterial.new()
	material.shader = load("res://assets/shaders/silhouette.gdshader")
	material.set_shader_parameter("tint", Palette.INK)
	material.set_shader_parameter("outline", Palette.INK)
	material.set_shader_parameter("stage", completed)
	material.set_shader_parameter("ready", ready)
	material.set_shader_parameter("reduced", Motion.reduced)
	var regions: Array[Vector4] = []
	for part: String in ["ears", "tail", "legs"]:
		for rect: Array in phase.art.parts.get(part, []):
			regions.append(Vector4(rect[0], rect[1], rect[2], rect[3]))
	material.set_shader_parameter("ear_count", phase.art.parts.get("ears", []).size())
	material.set_shader_parameter("part_count", regions.size())
	regions.resize(8)
	material.set_shader_parameter("parts", regions)
	image.material = material
	holder.add_child(image)
	var question := _center("?", &"TitleLabel")
	question.mouse_filter = Control.MOUSE_FILTER_IGNORE
	question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question.add_theme_color_override("font_color", Palette.INK if completed == 0 else (Palette.HONEY if phase.id == "adult" else Palette.INK))
	holder.add_child(question)
	return holder
