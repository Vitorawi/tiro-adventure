class_name HouseUi
extends RefCounted
## Painéis da Casa que cresce (etapa 14), em madeira ilustrada: prateleira de lembranças, parede de fotos, moldura dourada
## e cesto de brinquedos. Toque num objeto da sala chega aqui por `open("<objeto>")`.


static func open(id: String) -> void:
	match id:
		"height_chart":
			GrowthUi.open()
		"memory_shelf":
			Events.sheet_requested.emit("Prateleira de lembranças", shelf())
		"photo_wall":
			Events.sheet_requested.emit("Parede de fotos", wall())
		"gold_frame":
			Events.sheet_requested.emit("Moldura dourada", frame())
		"toy_basket":
			Events.sheet_requested.emit("Cesto de brinquedos", toys())
		"arrival_box":
			if GameState.album.has_photo("h_arrival"):
				AlbumView.open_photo("h_arrival")
			else:
				Events.toast_requested.emit(str(Database.house.items.arrival_box.desc))
		"big_portrait", "old_camera":
			PetNotebook.open("album")
		_:
			Events.toast_requested.emit(str(Database.house.get("items", {}).get(id, {}).get("desc", "")))


static func bed() -> Control:
	var box := UiKit.vbox(10)
	box.name = "BedPanel"
	ProjectUi.wood_sheet(box)
	var inner := StepCardUi.inner_card(box, "BedCard")
	inner.add_theme_constant_override("separation", 10)
	var sleeping := GameState.dog.sleeping
	var status := StepCardUi.wood("O Tiro está dormindo." if sleeping else "A caminha do Tiro.", 17)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(status)
	var toggle := ProjectUi.green("Acordar" if sleeping else "Dormir", func() -> void:
		GameState.set_sleeping(not GameState.dog.sleeping)
		Events.sheet_requested.emit("Caminha", bed()))
	toggle.name = "SleepToggle"
	inner.add_child(toggle)
	var next := "bed_luxe" if GameState.has_upgrade("bed_soft") else "bed_soft"
	if not GameState.has_upgrade(next):
		# A compra fica em outro painel para manter uma ação principal por vez.
		var buy := WelcomeSheet._button(str(Database.progression.upgrades[next].name), false, 240.0, "BedUpgrade", func() -> void:
			Events.sheet_requested.emit(str(Database.progression.upgrades[next].name), ProgressionUi.purchase(next)))
		inner.add_child(buy)
	return box


## Texto de apoio (marrom suave, centralizado) no topo das listas da Casa.
static func _intro(box: VBoxContainer, text: String) -> void:
	var label := StepCardUi.wood(text, 15, Color(Palette.WOOD_INK, 0.85))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 100.0
	box.add_child(label)


## Caixinha, argolinha, mordedor, escova e medalhinha: só o que já foi entregue; tocar abre a foto ligada.
static func shelf() -> Control:
	var box := UiKit.vbox(8)
	box.name = "ShelfPanel"
	ProjectUi.wood_sheet(box)
	_intro(box, "Tudo o que ele ganhou ao crescer.")
	for entry: Dictionary in HouseDecor.shelf_items():
		var id := str(entry.id)
		var icon: Texture2D = load(str(entry.icon)) if entry.has("icon") else Database.item_icon(id)
		var photo := str(entry.get("photo", ""))
		var tail: Control = null
		var tap := Callable()
		if photo != "" and GameState.album.has_photo(photo):
			tail = ProjectUi.chevron()
			tail.name = "ShelfPhoto_" + id
			tap = AlbumView.open_photo.bind(photo)
		var no_chips: Array[Control] = []
		box.add_child(ProjectUi.row("ShelfItem_" + id, icon, str(entry.name), no_chips, tail, tap))
	return box


## Foto como botão: a polaroide inteira é o alvo do toque.
static func photo_button(id: String, width: float, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.name = "PhotoPick_" + id
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	var card := PhotoCard.make(id, width, {"caption": false})
	button.custom_minimum_size = card.custom_minimum_size
	button.add_child(card)
	button.pressed.connect(on_pressed)
	return button


static func _photo_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in GameState.album.photos:
		ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool: return float(GameState.album.photos[a].at) > float(GameState.album.photos[b].at))
	return ids


## Contorno de madeira (mel) em volta da foto escolhida; sem `on` só reserva o mesmo espaço.
static func _picked(content: Control, on: bool) -> Control:
	var holder := PanelContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.WOOD_PICK, 0.25) if on else Color(0, 0, 0, 0)
	style.border_color = Palette.WOOD_PICK if on else Color(0, 0, 0, 0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(3)
	holder.add_theme_stylebox_override("panel", style)
	holder.add_child(content)
	return holder


## Até 3 fotos penduradas; a lista de baixo pendura a foto tocada.
static func wall() -> Control:
	var box := UiKit.vbox(10)
	box.name = "WallPanel"
	ProjectUi.wood_sheet(box)
	var slots := int(Database.house.get("wall_slots", 3))
	var top := StepCardUi.inner_card(box, "WallCard")
	_intro(top, "Escolha até %d fotos para a parede." % slots)
	var hung := UiKit.hbox(8)
	hung.name = "WallSlots"
	hung.alignment = BoxContainer.ALIGNMENT_CENTER
	for slot in slots:
		var id := str(GameState.album.wall[slot]) if slot < GameState.album.wall.size() else ""
		var cell := UiKit.vbox(4)
		if id != "":
			cell.add_child(photo_button(id, 76.0, func() -> void: _unhang(id)))
			cell.add_child(WelcomeSheet._button("Tirar", false, 76.0, "Unhang_" + id, _unhang.bind(id)))
		else:
			var empty := Panel.new()
			empty.custom_minimum_size = Vector2(76, 92)
			empty.name = "EmptySlot_%d" % slot
			var style := StyleBoxFlat.new()
			style.bg_color = Palette.WOOD_INSET
			style.border_color = Color("c9935f")
			style.set_border_width_all(2)
			style.set_corner_radius_all(8)
			empty.add_theme_stylebox_override("panel", style)
			cell.add_child(empty)
		hung.add_child(cell)
	top.add_child(hung)
	var below := StepCardUi.inner_card(box, "WallPhotosCard")
	var heading := StepCardUi.wood("Suas fotos", 18)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	below.add_child(heading)
	var grid := HFlowContainer.new()
	grid.name = "WallPhotos"
	grid.alignment = FlowContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for id: String in _photo_ids():
		if not GameState.album.wall.has(id):
			grid.add_child(photo_button(id, 76.0, _hang.bind(id)))
	below.add_child(grid)
	return box


static func _hang(id: String) -> void:
	var reason := GameState.hang_photo(id)
	if reason != "":
		Events.toast_requested.emit(reason)
	else:
		Events.sheet_requested.emit("Parede de fotos", wall())


static func _unhang(id: String) -> void:
	GameState.unhang_photo(id)
	Events.sheet_requested.emit("Parede de fotos", wall())


## Moldura dourada: a foto principal aparece no cantinho do Tiro.
static func frame() -> Control:
	var box := UiKit.vbox(10)
	box.name = "FramePanel"
	ProjectUi.wood_sheet(box)
	var inner := StepCardUi.inner_card(box, "FrameCard")
	_intro(inner, "Qual foto fica no cantinho do Tiro?")
	var grid := HFlowContainer.new()
	grid.name = "FramePhotos"
	grid.alignment = FlowContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for id: String in _photo_ids():
		var button := photo_button(id, 76.0, _set_main.bind(id))
		grid.add_child(_picked(button, id == GameState.album.main_photo))
	inner.add_child(grid)
	if GameState.album.main_photo != "":
		inner.add_child(WelcomeSheet._button("Tirar a foto", false, 160.0, "ClearFrame", _set_main.bind("")))
	return box


static func _set_main(id: String) -> void:
	var reason := GameState.set_main_photo(id)
	if reason != "":
		Events.toast_requested.emit(reason)
	else:
		Events.sheet_requested.emit("Moldura dourada", frame())


## Cesto de brinquedos: o que já está nele e o que dá para colocar agora.
static func toys() -> Control:
	var box := UiKit.vbox(8)
	box.name = "ToysPanel"
	ProjectUi.wood_sheet(box)
	_intro(box, "Guarde aqui os brinquedos favoritos do Tiro.")
	for item: String in Database.house.get("toys", []):
		var inside: bool = GameState.progress.house.toys.has(item)
		var action: Control = null
		if not inside and GameState.inventory.count(item) > 0:
			action = WelcomeSheet._button("Dar", false, 84.0, "GiveToy_" + item, _give.bind(item))
		var chips: Array[Control] = []
		if inside:
			chips.append(StepCardUi.wood_chip(null, "No cesto", "have"))
		box.add_child(ProjectUi.row("Toy_" + item, Database.item_icon(item), Database.item_name(item), chips, action, Callable(), not inside and action == null))
	return box


static func _give(item: String) -> void:
	var reason := GameState.give_toy(item)
	if reason != "":
		Events.toast_requested.emit(reason)
	else:
		Events.sheet_requested.emit("Cesto de brinquedos", toys())
