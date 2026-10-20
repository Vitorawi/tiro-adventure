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


static func _build(box: VBoxContainer) -> void:
	var info := GameState.growth_info()
	box.set_meta("phase", info.phase)
	box.add_child(PillarUi.personality_title())
	var dots := UiKit.hbox(8)
	dots.custom_minimum_size.y = 22
	dots.name = "LifeDots"
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	for phase: Dictionary in info.phases:
		var dot := Control.new()
		dot.custom_minimum_size = Vector2(12, 18)
		dot.draw.connect(func() -> void:
			dot.draw_circle(Vector2(6, 9), 4, Palette.PRIMARY if phase.visited else Palette.SUNKEN)
			if phase.id == info.phase: dot.draw_arc(Vector2(6, 9), 6, 0, TAU, 20, Palette.INK, 1, true))
		dots.add_child(dot)
	box.add_child(dots)
	var portraits := UiKit.hbox(8)
	portraits.alignment = BoxContainer.ALIGNMENT_CENTER
	var current := UiKit.vbox(0)
	current.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var dog := PetAnimator.portrait(120)
	dog.custom_minimum_size.y = 112
	dog.get_child(0).scale = Vector2(0.85, 0.85)
	dog.get_child(0).position.x = -42
	dog.name = "CurrentDog"
	dog.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	current.add_child(dog)
	current.add_child(_center(str(info.current.name)))
	current.add_child(_center(str(info.current.age) + " · " + str(info.current.weight), &"SmallLabel"))
	portraits.add_child(current)
	if not info.next.is_empty():
		portraits.add_child(_center("→", &"SectionLabel"))
		var future := UiKit.vbox(0)
		future.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		future.add_child(silhouette(info.next, info.requirements.size() - missing(info), info.ready, "NextSilhouette", 96))
		future.add_child(_center(str(info.next.name)))
		future.add_child(_center("Cap. %d" % int(info.next.chapter), &"SmallLabel"))
		portraits.add_child(future)
	var silk := GameState.silk_info()
	var silk_open: bool = info.next.is_empty() and silk.adult and not silk.next.is_empty()
	if silk_open:
		portraits.add_child(_center("→", &"SectionLabel"))
		var shiny := UiKit.vbox(0)
		shiny.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var done_rows: int = silk.requirements.filter(func(row: Dictionary) -> bool: return row.done).size()
		shiny.add_child(silhouette(info.current, done_rows, silk.ready, "SilkSilhouette", 96))
		shiny.add_child(_center(str(silk.next.name)))
		portraits.add_child(shiny)
	box.add_child(portraits)
	var closing := "Ele já é o Guardião do Vale"
	if silk.adult and silk.level >= silk.max: closing = "Guardião do Vale, de pelagem de seda"
	var unlocks := UiKit.fill_label("Próximo brilho: o pelo cada vez mais sedoso" if silk_open else ("Próxima fase: " + " · ".join(info.next.get("unlocks_text", [])) if not info.next.is_empty() else closing), &"SmallLabel")
	unlocks.name = "NextUnlocks"
	var unlock_row := UiKit.hbox(4)
	unlock_row.add_child(UiKit.icon(UiKit.ui_icon("tab_tasks"), 24))
	unlock_row.add_child(unlocks)
	box.add_child(unlock_row)
	if silk_open: _silk_requirements(box, silk)
	if missing(info) == 1:
		var almost := UiKit.chip(null, "Falta 1!", Palette.INK)
		almost.name = "GrowthAlmost"
		box.add_child(almost)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for req: Dictionary in info.requirements:
		var tile := VBoxContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var card := UiKit.card(tile, &"ReadyCardPanel" if req.done else &"CardPanel")
		var tap := UiKit.ghost("", TaskHelp.open.bind("growth_req", str(req.id)))
		tap.custom_minimum_size.y = 64
		for state: String in ["normal", "hover", "pressed", "focus"]:
			tap.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		tap.name = "GrowthReq_" + str(req.id)
		card.add_child(tap)
		var text := UiKit.label("%s\n%d/%d%s" % [req.label, mini(int(req.have), int(req.need)) if not req.done else int(req.need), int(req.need), " ✓" if req.done else ""], &"SmallLabel")
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tap.add_child(text)
		text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if str(req.type) == "deliver" and not req.done and GameState.deliver_growth_error(str(req.item)) == "":
			var give := UiKit.secondary("Dar", _deliver.bind(str(req.item)), null, true)
			give.name = "GiveGrowth_" + str(req.item)
			card.add_child(give)
		grid.add_child(tile)
	var rings := UiKit.hbox(8)
	box.add_child(rings)
	for id: String in info.pillars:
		var data: Dictionary = info.pillars[id]
		var column := UiKit.vbox(2)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ring := RingProgress.new()
		ring.name = "PillarRing_" + id
		ring.custom_minimum_size = Vector2(44, 44)
		ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ring.texture = UiKit.ui_icon(data.icon)
		ring.progress = float(data.level) / int(data.cap)
		column.add_child(ring)
		column.add_child(_center(str(data.title), &"SmallLabel"))
		column.add_child(_center("%d/%d" % [data.level, data.cap], &"SmallLabel"))
		if int(data.reserve) > 0: column.add_child(_center("+%d guardado" % data.reserve, &"SmallLabel"))
		rings.add_child(column)
	if not info.next.is_empty():
		if info.ready:
			var grow := UiKit.primary("Crescer!", func() -> void:
				var error := GameState.grow()
				if error != "": Events.toast_requested.emit(error))
			grow.name = "GrowButton"
			box.add_child(grow)
		else:
			var first: Dictionary = info.requirements.filter(func(row: Dictionary) -> bool: return not row.done)[0]
			var lock := UiKit.lock_hint("Falta: " + str(first.label), TaskHelp.open.bind("growth_req", str(first.id)))
			lock.name = "GrowthLock"
			box.add_child(lock)
	if silk_open:
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
