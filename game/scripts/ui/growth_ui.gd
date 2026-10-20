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


## Resumo do avatar: só o que falta, com a mesma contagem dos requisitos reais.
static func compact_steps(info: Dictionary) -> Array[Dictionary]:
	var steps: Array[Dictionary] = []
	for req: Dictionary in info.requirements:
		if req.done or req.type == "given": continue
		var title := str(req.label)
		var have := mini(int(req.have), int(req.need))
		var need := int(req.need)
		if req.type == "pillars":
			title = str({"brave": "Carinho", "smart": "Brincar", "coat": "Banho"}.get(str(req.levels.keys()[0]), req.label))
			var cares := TaskHelp.growth_care_steps(req)
			have = cares.filter(func(care: Dictionary) -> bool: return care.done).size()
			need = cares.size()
		elif req.type == "feed": title = "Refeições"
		elif req.type == "deliver": title = Database.item_name(str(req.item)).get_slice(" ", 0)
		elif req.type == "owned": title = str(Database.progression.upgrades[str(req.upgrade)].name).get_slice(" ", 0)
		elif req.type == "stat" and req.get("counter", "") == "walk": title = "Passeios"
		var icon := TaskHelp.icon_for("growth_req", str(req.id))
		if req.type == "pillars": icon = UiKit.ui_icon(str({"brave": "action_pet", "smart": "action_play", "coat": "action_bathe"}.get(str(req.levels.keys()[0]), "action_pet")))
		elif req.type == "stat" and req.get("counter", "") == "walk": icon = UiKit.ui_icon("action_walk")
		steps.append({"id": str(req.id), "title": title, "have": have, "need": need, "icon": icon})
	return steps


static func _build(box: VBoxContainer) -> void:
	var info := GameState.growth_info()
	var silk := GameState.silk_info()
	box.set_meta("phase", info.phase)
	var hero := UiKit.hbox(12)
	hero.name = "GrowthHero"
	var dog := PetAnimator.portrait(64)
	dog.name = "CurrentDog"
	hero.add_child(dog)
	var heading := UiKit.vbox(4)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(UiKit.label(str(info.current.name), &"SectionLabel"))
	heading.add_child(UiKit.label("Próxima fase: " + str(info.next.name) if not info.next.is_empty() else "Guardião do Vale", &"SmallLabel"))
	hero.add_child(heading)
	if not info.next.is_empty():
		hero.add_child(silhouette(info.next, info.requirements.size() - missing(info), info.ready, "NextSilhouette", 48))
	box.add_child(hero)
	if not info.next.is_empty():
		var visible_steps: Array = info.requirements.filter(func(req: Dictionary) -> bool: return req.type != "given")
		var complete: int = visible_steps.filter(func(req: Dictionary) -> bool: return req.done).size()
		var summary := UiKit.label("Tudo pronto para crescer!" if info.ready else "%d de %d passos concluídos" % [complete, visible_steps.size()], &"SmallLabel")
		summary.name = "GrowthSummary"
		box.add_child(summary)
		var progress := ProgressBar.new()
		progress.name = "GrowthProgress"
		progress.custom_minimum_size.y = 8
		progress.max_value = maxi(1, visible_steps.size())
		progress.value = complete
		progress.show_percentage = false
		box.add_child(progress)
		if info.ready:
			var grow := UiKit.primary("Crescer!", func() -> void:
				var error := GameState.grow()
				if error != "": Events.toast_requested.emit(error))
			grow.name = "GrowButton"
			box.add_child(grow)
		else:
			_next_step(box, info)
		box.add_child(UiKit.label("Para crescer", &"SectionLabel"))
		for req: Dictionary in info.requirements:
			if req.type != "given": _requirement_row(box, req)
		var unlocks := UiKit.label("Depois: " + " · ".join(info.next.get("unlocks_text", [])), &"SmallLabel")
		unlocks.name = "NextUnlocks"
		box.add_child(unlocks)
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
	var details := UiKit.secondary("Ver cuidados", func() -> void: Events.sheet_requested.emit("Cuidados do Tiro", PillarUi.panel()), null, true)
	details.name = "GrowthDetails"
	box.add_child(details)
	var book := UiKit.ghost("Caderneta · fases e lembranças", history)
	book.name = "GrowthHistoryButton"
	box.add_child(book)


static func _next_step(box: VBoxContainer, info: Dictionary) -> void:
	var pending: Array = info.requirements.filter(func(row: Dictionary) -> bool: return not row.done)
	var first: Dictionary = pending[0]
	# A comida é um começo concreto; entregar uma lembrança já possuída vem primeiro.
	for req: Dictionary in pending:
		if req.type == "feed": first = req
	for req: Dictionary in pending:
		if req.type == "deliver" and GameState.deliver_growth_error(str(req.item)) == "": first = req
	var help := TaskHelp.describe("growth_req", str(first.id))
	var card := UiKit.card(box, &"ReadyCardPanel")
	card.get_parent().name = "GrowthNextStep"
	var title := str(first.label)
	var detail := ""
	var action := "Ver como fazer"
	var callback := TaskHelp.open.bind("growth_req", str(first.id))
	if first.type == "feed":
		if help.has("food_guide"):
			title = str(help.title)
			detail = str(help.food_guide.status)
			action = str(help.food_guide.action)
			callback = TaskHelp._go.bind(help.food_guide.target)
		else:
			title = "Dê comida ao Tiro na Tigela."
			action = "Dar comida"
			callback = TaskHelp._go.bind(help.target)
	elif first.type == "deliver":
		if GameState.deliver_growth_error(str(first.item)) == "":
			title = "Você já tem: " + Database.item_name(str(first.item))
			action = "Dar ao Tiro"
			callback = _deliver.bind(str(first.item))
		else:
			title = "Consiga " + Database.item_name(str(first.item))
			action = "Onde conseguir"
	elif first.type == "pillars":
		var care: Dictionary = TaskHelp.growth_care_steps(first)[0]
		var pillar := str(first.levels.keys()[0])
		title = str({"brave": "Faça carinho no Tiro.", "smart": "Brinque com o Tiro.", "coat": "Dê banho quando o Tiro precisar."}.get(pillar, care.hint))
		detail = str(care.progress)
		if pillar == "brave":
			var pet := GameState.pet_growth_info()
			detail += " · Próximo ganho em " + str(pet.wait) if int(pet.seconds) > 0 else " · Coragem a cada 2 min"
		action = str(care.action)
		callback = TaskHelp._go.bind(care.target)
	card.add_child(UiKit.label("Agora: " + title))
	if detail != "": card.add_child(UiKit.label(detail, &"SmallLabel"))
	var button := UiKit.primary(action, callback)
	button.name = "GrowthNextAction"
	card.add_child(button)


static func _requirement_row(box: VBoxContainer, req: Dictionary) -> void:
	var title := str(req.label)
	var detail := "%d/%d%s" % [int(req.need) if req.done else mini(int(req.have), int(req.need)), int(req.need), " · Feito!" if req.done else ""]
	var action := "Ver"
	if req.type == "pillars":
		var care: Dictionary = TaskHelp.growth_care_steps(req)[0]
		detail = str(care.progress)
		action = "Ver como"
	elif req.type == "feed":
		title = "Dar comida" if req.item == "any" else ("Dar a comida favorita" if req.item == "favorite" else "Dar " + Database.item_name(str(req.item)))
		detail = "%d/%d refeições" % [int(req.need) if req.done else mini(int(req.have), int(req.need)), int(req.need)]
		if req.has("body_level"): detail += " · Corpo completo" if req.done else " · Desenvolve Corpo"
	elif req.type == "deliver":
		title = Database.item_name(str(req.item))
		detail += " entregue" if not req.done else ""
		action = "Conseguir"
	elif req.type == "stat" and str(req.get("counter", "")) == "walk":
		title = "Passear com o Tiro"
		detail = "%d/%d passeios" % [int(req.need) if req.done else mini(int(req.have), int(req.need)), int(req.need)]
		action = "Passear"
	var callback := TaskHelp.open.bind("growth_req", str(req.id))
	var button_name := "GrowthReq_" + str(req.id)
	if req.type == "deliver" and not req.done and GameState.deliver_growth_error(str(req.item)) == "":
		action = "Dar"
		button_name = "GiveGrowth_" + str(req.item)
		callback = _deliver.bind(str(req.item))
	var button := UiKit.secondary(action, callback, null, true)
	button.name = button_name
	if req.done:
		button.text = "✓"
		button.disabled = true
	var row := UiKit.list_row(TaskHelp.icon_for("growth_req", str(req.id)), title, [], button)
	if button_name.begins_with("GiveGrowth_"): row.name = "GrowthReq_" + str(req.id)
	var body := row.get_child(0) as VBoxContainer
	var top := body.get_child(0) as HBoxContainer
	(top.get_child(0) as Control).custom_minimum_size = Vector2(32, 32)
	var old_label := top.get_child(1)
	top.remove_child(old_label)
	old_label.queue_free()
	var labels := UiKit.vbox(2)
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	labels.add_child(UiKit.label(title, &"SmallLabel"))
	labels.add_child(UiKit.label(detail, &"SmallLabel", Palette.GOOD if req.done else Palette.INK_SOFT))
	top.add_child(labels)
	top.move_child(labels, 1)
	if req.type == "deliver" and not req.done:
		var source := TaskHelp.reward_source_text(str(req.item))
		if source != "":
			var hint := UiKit.label(source.split(" · ")[0], &"SmallLabel")
			hint.name = "GrowthSource_" + str(req.item)
			body.add_child(hint)
	box.add_child(row)


static func history() -> void:
	var book := SheetBuilder.LiveBox.new(_build_history)
	book.name = "GrowthHistory"
	book.set_meta("sheet_size", "tall")
	Events.sheet_requested.emit("Caderneta", book)


static func _build_history(box: VBoxContainer) -> void:
	var info := GameState.growth_info()
	var silk := GameState.silk_info()
	box.add_child(UiKit.secondary("Voltar ao crescimento", open, null, true))
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
				for id: String in info.pillars: values.append("%s %d" % [info.pillars[id].title, info.pillars[id].level])
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
		var card := UiKit.card(tile, &"ReadyCardPanel" if req.done else &"CardPanel")
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
	material.set_shader_parameter("outline", Palette.INK_ON_DARK)
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
	question.add_theme_color_override("font_color", Palette.INK if completed == 0 else (Palette.GOLD if phase.id == "adult" else Palette.INK_ON_DARK))
	holder.add_child(question)
	return holder
