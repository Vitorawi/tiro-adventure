class_name HouseUi
extends RefCounted
## Painéis da Casa que cresce (etapa 14): prateleira de lembranças, parede de fotos, moldura dourada
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
	var box := UiKit.vbox(8)
	box.name = "BedPanel"
	box.add_child(UiKit.primary("Acordar" if GameState.dog.sleeping else "Dormir", func() -> void:
		GameState.set_sleeping(not GameState.dog.sleeping)
		Events.sheet_requested.emit("Caminha", bed())))
	var next := "bed_luxe" if GameState.has_upgrade("bed_soft") else "bed_soft"
	if not GameState.has_upgrade(next):
		# A compra fica em outro painel para manter uma ação principal por vez.
		box.add_child(UiKit.soft(str(Database.progression.upgrades[next].name), func() -> void:
			Events.sheet_requested.emit(str(Database.progression.upgrades[next].name), ProgressionUi.purchase(next))))
	return box


## Caixinha, argolinha, mordedor, escova e medalhinha: só o que já foi entregue; tocar abre a foto ligada.
static func shelf() -> Control:
	var box := UiKit.vbox(8)
	box.name = "ShelfPanel"
	box.add_child(UiKit.fill_label("Tudo o que ele ganhou ao crescer.", &"SmallLabel"))
	for entry: Dictionary in HouseDecor.shelf_items():
		var id := str(entry.id)
		var icon: Texture2D = load(str(entry.icon)) if entry.has("icon") else Database.item_icon(id)
		var photo := str(entry.get("photo", ""))
		var action: Control = null
		var tap := Callable()
		if photo != "" and GameState.album.has_photo(photo):
			action = UiKit.soft("Ver foto", AlbumView.open_photo.bind(photo), null, true)
			action.name = "ShelfPhoto_" + id
			tap = AlbumView.open_photo.bind(photo)
		var no_chips: Array[Control] = []
		var row := UiKit.list_row(icon, str(entry.name), no_chips, action, tap)
		row.name = "ShelfItem_" + id
		box.add_child(row)
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


## Até 3 fotos penduradas; a lista de baixo pendura a foto tocada.
static func wall() -> Control:
	var box := UiKit.vbox(8)
	box.name = "WallPanel"
	box.set_meta("sheet_size", "tall")
	var slots := int(Database.house.get("wall_slots", 3))
	box.add_child(UiKit.fill_label("Escolha até %d fotos para a parede." % slots, &"SmallLabel"))
	var hung := UiKit.hbox(8)
	hung.name = "WallSlots"
	hung.alignment = BoxContainer.ALIGNMENT_CENTER
	for slot in slots:
		var id := str(GameState.album.wall[slot]) if slot < GameState.album.wall.size() else ""
		var cell := UiKit.vbox(4)
		if id != "":
			cell.add_child(photo_button(id, 92.0, func() -> void: _unhang(id)))
			var remove := UiKit.ghost("Tirar", _unhang.bind(id))
			remove.name = "Unhang_" + id
			cell.add_child(remove)
		else:
			var empty := Panel.new()
			empty.custom_minimum_size = Vector2(92, 92)
			empty.name = "EmptySlot_%d" % slot
			cell.add_child(empty)
		hung.add_child(cell)
	box.add_child(hung)
	box.add_child(UiKit.section("Suas fotos"))
	var grid := UiKit.flow(6)
	grid.name = "WallPhotos"
	for id: String in _photo_ids():
		if not GameState.album.wall.has(id):
			grid.add_child(photo_button(id, 76.0, _hang.bind(id)))
	box.add_child(grid)
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
	var box := UiKit.vbox(8)
	box.name = "FramePanel"
	box.set_meta("sheet_size", "tall")
	box.add_child(UiKit.fill_label("Qual foto fica no cantinho do Tiro?", &"SmallLabel"))
	var grid := UiKit.flow(6)
	grid.name = "FramePhotos"
	for id: String in _photo_ids():
		var button := photo_button(id, 76.0, _set_main.bind(id))
		if id == GameState.album.main_photo:
			button.modulate = Color(1.0, 0.93, 0.6)
		grid.add_child(button)
	box.add_child(grid)
	if GameState.album.main_photo != "":
		box.add_child(UiKit.soft("Tirar a foto", _set_main.bind("")))
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
	box.add_child(UiKit.fill_label("Guarde aqui os brinquedos favoritos do Tiro.", &"SmallLabel"))
	for item: String in Database.house.get("toys", []):
		var inside: bool = GameState.progress.house.toys.has(item)
		var action: Control = null
		if not inside and GameState.inventory.count(item) > 0:
			action = UiKit.soft("Dar", _give.bind(item), null, true)
			action.name = "GiveToy_" + item
		var chips: Array[Control] = []
		if inside:
			chips.append(UiKit.chip(null, "No cesto"))
		var row := UiKit.list_row(Database.item_icon(item), Database.item_name(item), chips, action)
		row.name = "Toy_" + item
		box.add_child(row)
	return box


static func _give(item: String) -> void:
	var reason := GameState.give_toy(item)
	if reason != "":
		Events.toast_requested.emit(reason)
	else:
		Events.sheet_requested.emit("Cesto de brinquedos", toys())
