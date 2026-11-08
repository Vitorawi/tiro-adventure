class_name GrowthUi
extends RefCounted
## Consulta do crescimento. Toda ação continua no GameState; o painel atualiza sem fechar.
## Visual: folha de madeira ilustrada (Sheet em modo `sheet_wood`), peças de `StepCardUi`/`CodexUi`/`WelcomeSheet`.

const PLATE := 72.0  # pratinho do retrato (agora → depois)
const TILE_H := 72.0  # quadradinho de um passo


static func open() -> void:
	Events.sheet_requested.emit("Crescimento", panel())


static func panel() -> Control:
	var box := SheetBuilder.LiveBox.new(_build)
	box.name = "GrowthPanel"
	box.set_meta("tick_refresh", false)
	box.add_theme_constant_override("separation", 6)
	box.set_meta("sheet_wood", true)
	box.set_meta("sheet_fit_content", true)
	box.set_meta("sheet_actions", _header_actions)
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
	ring.color = Palette.HONEY
	ring.thickness = 4.0
	# Ícone 40 independente do cálculo geométrico do RingProgress genérico.
	var image := UiKit.icon(step.icon, 40)
	image.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	image.offset_left = -20
	image.offset_top = -20
	image.offset_right = 20
	image.offset_bottom = 20
	ring.add_child(image)
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
		var summary := UiKit.hbox(8)
		summary.name = "GrowthSummary"
		summary.alignment = BoxContainer.ALIGNMENT_CENTER
		var progress := StepCardUi.bar(float(complete) / maxf(1.0, float(visible_steps.size())), 18.0, "GrowthProgress")
		progress.custom_minimum_size.x = 170.0
		progress.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		summary.add_child(progress)
		summary.add_child(StepCardUi.wood("%d/%d" % [complete, visible_steps.size()], 20))
		box.add_child(summary)
		_steps(box, info, visible_steps)
		if info.ready:
			var grow := StepCardUi.go_button("Crescer!", func() -> void:
				var error := GameState.grow()
				if error != "": Events.toast_requested.emit(error))
			grow.name = "GrowButton"
			grow.set_meta("wood_primary", true)
			box.add_child(grow)
		box.add_child(_unlocks(info))
	elif silk.adult and not silk.next.is_empty():
		_silk_requirements(box, silk)
		if silk.ready:
			var shine := StepCardUi.go_button("Mais brilho!", func() -> void:
				var error := GameState.brighten()
				if error != "": Events.toast_requested.emit(error))
			shine.name = "SilkButton"
			shine.set_meta("wood_primary", true)
			box.add_child(shine)
		else:
			var lacking: Dictionary = silk.requirements.filter(func(row: Dictionary) -> bool: return not row.done)[0]
			var wait := StepCardUi.lock_note("Falta: " + str(lacking.label), Callable(), _silk_step(lacking).icon)
			wait.name = "SilkLock"
			box.add_child(wait)
	else:
		var done := StepCardUi.wood("Ele cresceu com você. Continue cuidando do Tiro!", 18)
		done.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(done)


## A folha recebe os controles de consulta no título (botões redondos de madeira); o herói fica só com as fases.
static func _header_actions() -> Array[Control]:
	var details := NpcFace.wood_button("info", func() -> void:
		var care := PillarUi.panel()
		Events.sheet_requested.emit("Cuidados do Tiro", care))
	details.name = "GrowthDetails"
	var book := NpcFace.wood_button("list", history)
	book.name = "GrowthHistoryButton"
	for button: Button in [details, book]:
		button.custom_minimum_size = Vector2(44, 44)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return [details, book]


## Coloca `inner` (centralizado, no tamanho mínimo dele) dentro de um pratinho de madeira.
static func _plated(inner: Control, plate_name: String) -> Control:
	var plate: Control = WelcomeSheet._plate(PLATE, null, plate_name)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.add_child(inner)
	inner.set_anchors_preset(Control.PRESET_CENTER)
	var half := inner.custom_minimum_size / 2.0
	inner.offset_left = -half.x
	inner.offset_right = half.x
	inner.offset_top = -half.y
	inner.offset_bottom = half.y
	return plate


## Agora → depois: retratos do mesmo tamanho em pratinhos de madeira, com nomes abaixo.
static func _hero(info: Dictionary) -> Control:
	var inner_px := PLATE - 16.0
	var hero := UiKit.hbox(8)
	hero.name = "GrowthHero"
	hero.alignment = BoxContainer.ALIGNMENT_CENTER
	var now := UiKit.vbox(2)
	now.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dog := PetAnimator.portrait(int(inner_px))
	dog.custom_minimum_size = Vector2(inner_px, inner_px)
	dog.name = "CurrentDog"
	now.add_child(_plated(dog, "CurrentPlate"))
	now.add_child(_phase_name(str(info.current.name)))
	hero.add_child(now)
	var silk := GameState.silk_info()
	if not info.next.is_empty() or (silk.adult and not silk.next.is_empty()):
		var arrow := UiKit.ctl("arrow", 22, Palette.WOOD_INK)
		arrow.name = "GrowthArrow"
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hero.add_child(arrow)
		var then := UiKit.vbox(2)
		then.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not info.next.is_empty():
			var shadow := silhouette(info.next, maxi(1, info.requirements.size() - missing(info)), info.ready, "NextSilhouette", int(inner_px), true)
			then.add_child(_plated(shadow, "NextPlate"))
			var name_label := _phase_name(str(info.next.name))
			name_label.add_theme_color_override("font_color", Color(Palette.WOOD_INK, 0.6))
			then.add_child(name_label)
		else:
			var preview_holder := Control.new()
			preview_holder.name = "SilkSilhouette"
			preview_holder.custom_minimum_size = Vector2(inner_px, inner_px)
			preview_holder.clip_contents = true
			var preview := UiKit.icon(load(str(info.current.art.dir.pet) + "idle_breathe/frame_00.png"), 0)
			preview.material = DogLook.material()
			(preview.material as ShaderMaterial).set_shader_parameter("sheen", float(silk.next.sheen))
			preview_holder.add_child(preview)
			_fit_static(preview, int(inner_px))
			then.add_child(_plated(preview_holder, "NextPlate"))
			then.add_child(_phase_name(str(silk.next.name)))
		hero.add_child(then)
	return hero

## Nome da fase sob o retrato: uma linha só, na fonte da madeira.
static func _phase_name(text: String) -> Label:
	var result := StepCardUi.wood(text, 17)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.clip_text = true
	result.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.custom_minimum_size.x = 60.0
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
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(grid)
	var select := func(id: String) -> void:
		box.set_meta("selected", id)
		box.set_meta("selected_done", bool(views[id].done))
		for key: String in tiles:
			_style_tile(tiles[key], bool(views[key].done), key == id)
			if details.has(key): _select_detail(details[key], key == id)
	for req: Dictionary in visible_steps:
		var id := str(req.id)
		var tile := _step_tile(views[id])
		if not info.ready: tile.pressed.connect(select.bind(id))
		_style_tile(tile, bool(views[id].done), id == chosen and not info.ready)
		tiles[id] = tile
		grid.add_child(tile)
	if first_id == "" or info.ready:
		return
	var strip := StepCardUi.inner_card(box, "GrowthDetail", Vector4i(12, 4, 12, 8))
	for req: Dictionary in visible_steps:
		var id := str(req.id)
		var detail := _step_detail(views[id], id == first_id, req)
		_select_detail(detail, id == chosen)
		details[id] = detail
		strip.add_child(detail)


## Quadradinho de um passo (papel creme do caderninho): anel com o ícone, nome curto e quantidade; ✓ verde quando feito.
static func _step_tile(step: Dictionary) -> Button:
	var tile := BagUi.plain_button(func() -> void: pass)
	tile.name = "GrowthReq_" + str(step.id)
	tile.custom_minimum_size = Vector2(0, TILE_H)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var art := SellUi.nine("tile", CodexUi.TILE_MARGINS, "Art", null, "codex_")
	tile.add_child(art)
	StepCardUi.stretch(art)
	var column := UiKit.vbox(1)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(column)
	StepCardUi.stretch(column)
	column.offset_left = 4
	column.offset_right = -4
	column.offset_top = 6
	column.offset_bottom = -8
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	var ring := step_ring(step, 40)
	ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var amount := UiKit.hbox(4)
	amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount.alignment = BoxContainer.ALIGNMENT_CENTER
	amount.add_child(ring)
	var count := StepCardUi.wood("%d/%d" % [step.have, step.need], 18, Palette.GO_INK if step.done else Palette.WOOD_INK)
	amount.add_child(count)
	column.add_child(amount)
	var name_label := StepCardUi.wood(str(step.short), 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(name_label)
	if step.type == "moments":
		var dots := PillarUi.dots(int(step.have), int(step.need))
		dots.name = "GrowthDots_" + str(step.pillar)
		dots.alignment = BoxContainer.ALIGNMENT_CENTER
		dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(dots)
	if step.done:
		var check := StepCardUi.done_medal(24.0, "StepCheck")
		check.set_anchors_preset(Control.PRESET_TOP_LEFT)
		check.offset_left = 6
		check.offset_top = 6
		check.offset_right = 30
		check.offset_bottom = 30
		tile.add_child(check)
	return tile


## Fundo do quadradinho: o escolhido leva a moldura laranja do caderninho; os demais, o papel creme.
static func _style_tile(tile: Button, _done: bool, selected: bool) -> void:
	var frame := tile.find_child("Frame", true, false) as NinePatchRect
	if frame != null:
		frame.texture = load(HomeUi.DIR + "codex_" + ("tab_orange" if selected else "tile") + ".png") as Texture2D


## Detalhe de um passo (um só fica visível): nome, caminho, dica de uma linha, uma ação e o "?".
## A ação do passo escolhido é a verde (meta `wood_primary`); só uma por painel.
static func _select_detail(detail: Control, selected: bool) -> void:
	detail.visible = selected
	for action: Button in detail.find_children("*", "Button", true, false):
		if action.has_meta("growth_action"):
			if selected: action.set_meta("wood_primary", true)
			elif action.has_meta("wood_primary"): action.remove_meta("wood_primary")


static func _step_detail(step: Dictionary, highlight: bool, req: Dictionary) -> Control:
	var detail := UiKit.vbox(4)
	detail.name = "GrowthNextStep" if highlight else "GrowthDetail_" + str(step.id)
	var head := UiKit.hbox(8)
	var title := StepCardUi.wood(str(step.title), 20)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.add_child(title)
	if not step.done:
		var help := StepCardUi.help_button(TaskHelp.open.bind("growth_req", str(step.id)))
		help.name = "GrowthHelp"
		head.add_child(help)
	detail.add_child(head)
	if not step.done:
		var target: Dictionary = TaskHelp.describe("growth_req", str(step.id)).target
		var path := _step_path(target, step)
		if path != null: detail.add_child(path)
	var hint_text := str(step.hint)
	var good: bool = step.hint_good
	if step.done:
		hint_text = "Corpo completo" if req.type == "feed" and req.has("body_level") else "Feito!"
		good = true
	var hint := StepCardUi.wood(hint_text, 15, Palette.GO_INK if good else Color(Palette.WOOD_INK, 0.75))
	hint.name = "GrowthSource_" + str(step.item) if step.type == "deliver" and step.give == "" else "GrowthHint_" + str(step.id)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.visible = hint_text != ""
	detail.add_child(hint)
	if step.done:
		return detail
	var button := StepCardUi.go_button(str(step.action), step.callback)
	button.name = "GrowthNextAction" if highlight else "GrowthAct_" + str(step.id)
	button.set_meta("growth_action", true)
	if step.give != "":
		button.name = "GiveGrowth_" + str(step.give)  # mesmo nome do Dar da Mochila
	detail.add_child(button)
	return detail


## O que muda quando ele crescer: dá vontade de completar.
static func _unlocks(info: Dictionary) -> Control:
	var row := UiKit.hbox(6)
	row.name = "GrowthUnlocks"
	row.tooltip_text = "Ao crescer"
	var prizes := HFlowContainer.new()
	prizes.name = "NextUnlocks"
	prizes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prizes.add_theme_constant_override("h_separation", 4)
	prizes.add_theme_constant_override("v_separation", 4)
	for text: String in info.next.get("unlocks_text", []):
		for prize: String in text.split(" · "):
			prizes.add_child(StepCardUi.wood_chip(UiKit.ui_icon("rare_star"), prize))
	row.add_child(prizes)
	return row


## Caminho visual derivado do destino já usado pela ajuda, sem inventar destino ou regra.
static func _step_path(target: Dictionary, step: Dictionary) -> Control:
	var row := UiKit.hbox(4)
	row.name = "GrowthPath_" + str(step.id)
	var world: Dictionary = Database.worlds.get(str(target.get("world", "")), {})
	var place := str(target.get("spot", target.get("place", ""))).trim_prefix("place:")
	var data: Dictionary = world.get("places", {}).get(place, {})
	if target.get("screen", "") == "pet":
		row.add_child(StepCardUi.wood_chip(UiKit.ui_icon("tab_pet"), "Tiro"))
	elif not world.is_empty():
		row.add_child(StepCardUi.wood_chip(UiKit.ui_icon(str(world.get("icon", ""))), str(world.name)))
	else:
		row.free()
		return null
	if not data.is_empty():
		row.add_child(StepCardUi.wood("›", 20))
		row.add_child(StepCardUi.wood_chip(UiKit.ui_icon(str(data.get("icon", ""))), str(data.name)))
	return row

static func history() -> void:
	var book := SheetBuilder.LiveBox.new(_build_history)
	book.name = "GrowthHistory"
	book.set_meta("sheet_wood", true)
	book.set_meta("sheet_size", "tall")
	Events.sheet_requested.emit("Caderneta", book)


## Linha de texto pequena e calma da caderneta.
static func _note(text: String) -> Label:
	var result := StepCardUi.wood(text, 14, Color(Palette.WOOD_INK, 0.8))
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result


static func _build_history(box: VBoxContainer) -> void:
	var info := GameState.growth_info()
	var silk := GameState.silk_info()
	box.add_theme_constant_override("separation", 8)
	box.add_child(WelcomeSheet._button("Voltar ao crescimento", false, 250.0, "BackToGrowth", open))
	var personality := PillarUi.personality_title()
	box.add_child(personality)
	var heading := StepCardUi.wood("Caderneta", 22)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	for phase: Dictionary in info.phases:
		var card := StepCardUi.inner_card(box, "GrowthCard_" + str(phase.id), Vector4i(14, 10, 14, 12))
		card.add_theme_constant_override("separation", 4)
		var row := UiKit.hbox(8)
		var ceremony_photo := "h_growth_" + str(phase.id)
		if phase.visited and GameState.album.has_photo(ceremony_photo):
			# Foto oficial da cerimônia (álbum): o corpo e o pelo do dia em que ele cresceu.
			var polaroid := PhotoCard.make(ceremony_photo, 72.0)
			polaroid.name = "CeremonyPhoto_" + str(phase.id)
			row.add_child(polaroid)
		elif phase.visited:
			var photo := UiKit.icon(load(str(phase.art.portrait)), 48)
			if str(phase.body) != "puppy":
				photo.material = DogLook.material()
				(photo.material as ShaderMaterial).set_shader_parameter("coat", float(phase.coat))
			row.add_child(photo)
		else:
			row.add_child(silhouette(phase, 0, false, "Future_" + str(phase.id), 64))
		var phase_name := StepCardUi.wood(str(phase.name), 20)
		phase_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(phase_name)
		card.add_child(row)
		if phase.visited:
			card.add_child(_note(str(phase.age) + " · " + str(phase.weight)))
			card.add_child(_note(_date(float(phase.at))))
			if phase.id == info.phase:
				var values: PackedStringArray = []
				for id: String in info.pillars: values.append("%s %d" % [info.pillars[id].title, info.pillars[id].total])
				card.add_child(_note(" · ".join(values)))
			card.add_child(_note(str(phase.facts[0])))
		else:
			card.add_child(_note(str(phase.teaser)))
			card.add_child(StepCardUi.lock_note("Cap. %d" % int(phase.get("chapter", 0))))
	for n in silk.level:
		var def: Dictionary = Database.growth.silk.levels[n]
		var card := StepCardUi.inner_card(box, "SilkCard_%d" % (n + 1), Vector4i(14, 10, 14, 12))
		card.add_theme_constant_override("separation", 4)
		card.add_child(StepCardUi.wood(str(def.name), 20))
		card.add_child(_note("Brilho %d de %d" % [n + 1, silk.max]))


static func _silk_step(req: Dictionary) -> Dictionary:
	var id := str(req.id)
	var icon := str({"coat": "pillar_coat", "brush_days": "action_brush", "shampoo": "item_herb_shampoo"}[id])
	return {"id": id, "type": "silk", "short": str({"coat": "Pelagem", "brush_days": "Escovar", "shampoo": "Xampu"}[id]),
		"have": mini(int(req.have), int(req.need)), "need": int(req.need), "done": bool(req.done), "icon": UiKit.ui_icon(icon)}


static func _silk_requirements(box: VBoxContainer, silk: Dictionary) -> void:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.name = "SilkRequirements"
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for req: Dictionary in silk.requirements:
		var step := _silk_step(req)
		var tile := _step_tile(step)
		tile.name = "SilkReq_" + str(req.id)
		_style_tile(tile, bool(req.done), false)
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


## Enquadra os pixels opacos sem alterar UVs/partes do shader ou a arte.
static func _fit_static(image: TextureRect, px: int) -> void:
	var bounds := Rect2(image.texture.get_image().get_used_rect())
	if not bounds.has_area(): return
	var area := Vector2(px, px)
	var factor := minf((px - 8.0) / bounds.size.x, (px - 8.0) / bounds.size.y)
	image.custom_minimum_size = Vector2.ZERO
	image.size = image.texture.get_size() * factor
	image.position = (area - bounds.size * factor) * 0.5 - bounds.position * factor


static func silhouette(phase: Dictionary, completed: int, ready: bool, node_name: String, px: int, filled_hero: bool = false) -> Control:
	var holder := Control.new()
	holder.name = node_name
	holder.custom_minimum_size = Vector2(px, px if filled_hero else px + 20)
	holder.clip_contents = filled_hero
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var image := UiKit.icon(DogLook.pose_texture(str(phase.body)), px)
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
			var scale := Vector2(3, 3) if str(phase.body) == "puppy" else Vector2.ONE
			regions.append(Vector4(rect[0]*scale.x, rect[1]*scale.y, rect[2]*scale.x, rect[3]*scale.y))
	material.set_shader_parameter("ear_count", phase.art.parts.get("ears", []).size())
	material.set_shader_parameter("part_count", regions.size())
	regions.resize(8)
	material.set_shader_parameter("parts", regions)
	image.material = material
	holder.add_child(image)
	if filled_hero:
		image.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_fit_static(image, px)
	else:
		var question := _center("?", &"TitleLabel")
		question.mouse_filter = Control.MOUSE_FILTER_IGNORE
		question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		question.add_theme_color_override("font_color", Palette.INK if completed == 0 else (Palette.HONEY if phase.id == "adult" else Palette.INK))
		holder.add_child(question)
	return holder
