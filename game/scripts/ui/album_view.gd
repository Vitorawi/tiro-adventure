class_name AlbumView
extends RefCounted
## Aba Álbum do caderninho (06 G): seções ativas em `UiKit.segmented`, grade de 3 colunas de polaroides,
## contador e detalhe de uma foto. Foto que falta = silhueta cinza + título; secreta = "?" + título.

const COLUMNS := 3


## Seção aberta por último na sessão (a aba volta nela).
static var last_section: String = ""


static func panel(section: String = "") -> Control:
	var sections := Database.album_sections()
	if sections.is_empty():
		return UiKit.fill_label("Ainda não há fotos.", &"SmallLabel")
	if section == "" or not sections.any(func(entry: Dictionary) -> bool: return str(entry.id) == section):
		section = last_section if sections.any(func(entry: Dictionary) -> bool: return str(entry.id) == last_section) else str(sections[0].id)
	last_section = section
	GameState.note_album_section(section)
	var box := UiKit.vbox(8)
	box.name = "AlbumView"
	box.add_child(UiKit.collection_progress(taken_count(), total_count()))
	var tabs: Array[Dictionary] = []
	for entry: Dictionary in sections:
		tabs.append({"id": str(entry.id), "text": str(entry.name), "icon": UiKit.ui_icon(str(entry.icon))})
	var segmented := UiKit.segmented(tabs, section, func(id: String) -> void: PetNotebook.open("album:" + id))
	segmented.name = "AlbumSections"
	if sections.size() > 3:
		for tab in segmented.get_children():
			(tab as Button).text = ""  # só o ícone: seis nomes não cabem na largura do celular
	box.add_child(segmented)
	var title := UiKit.label(str(sections.filter(func(entry: Dictionary) -> bool: return str(entry.id) == section)[0].name), &"SectionLabel")
	title.name = "AlbumSectionTitle"
	box.add_child(title)
	var grid := GridContainer.new()
	grid.name = "AlbumGrid"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for entry: Dictionary in Database.album.photos:
		if str(entry.section) == section:
			grid.add_child(_tile(entry))
	box.add_child(grid)
	return box


## Fotos tiradas nas seções ativas e quantas existem nelas.
static func taken_count() -> int:
	var total := 0
	for entry: Dictionary in Database.album.photos:
		if str(entry.section) in Database.album.active_sections and GameState.album.has_photo(str(entry.id)):
			total += 1
	return total


static func total_count() -> int:
	var total := 0
	for entry: Dictionary in Database.album.photos:
		total += 1 if str(entry.section) in Database.album.active_sections else 0
	return total


static func _tile(entry: Dictionary) -> Control:
	var id := str(entry.id)
	var taken := GameState.album.has_photo(id)
	var secret: bool = str(entry.section) == "tricks"
	var tile := UiKit.button("", func() -> void: _tap(id), &"GhostButton")
	tile.name = "Photo_" + id
	tile.custom_minimum_size = Vector2(0, 150)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := UiKit.vbox(2)
	column.name = "Visual"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	var card := PhotoCard.make(id, 98.0, {"secret": secret})
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(card)
	column.add_child(holder)
	var caption := UiKit.label(str(entry.title), &"SmallLabel")
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 13)
	caption.custom_minimum_size = Vector2(90, 0)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption)
	tile.add_child(column)
	if taken and not bool(GameState.album.photos[id].get("seen", false)):
		var badge := UiKit.short_label("Novo!", &"BadgeLabel", Palette.INK_ON_DARK)
		badge.name = "NewBadge"
		badge.position = Vector2(4, 4)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(badge)
	return tile


static func _tap(id: String) -> void:
	if GameState.album.has_photo(id):
		open_photo(id)
	else:
		Events.sheet_requested.emit(str(Database.photo(id).title), secret_detail(id))


## Detalhe de uma foto tirada, no painel do caderninho. Abrir marca a foto como vista.
static func open_photo(id: String) -> void:
	if not GameState.album.has_photo(id):
		return
	GameState.open_album_photo(id)
	var entry := Database.photo(id)
	Events.sheet_requested.emit(str(entry.title), detail(id))


static func detail(id: String) -> Control:
	var entry := Database.photo(id)
	var info := GameState.photo_info(id)
	var box := UiKit.vbox(8)
	box.name = "PhotoDetail"
	box.set_meta("sheet_size", "tall")
	var big := PhotoCard.make(id, 264.0, {"caption": true})
	var center := CenterContainer.new()
	center.add_child(big)
	box.add_child(center)
	var phase_name := ""
	for phase: Dictionary in Database.growth.phases:
		if str(phase.id) == str(info.phase):
			phase_name = str(phase.name)
	var line := UiKit.fill_label("Fase: " + phase_name, &"SmallLabel")
	line.name = "PhotoWhen"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(line)
	var before := str(entry.get("photo", {}).get("compare", ""))
	if before != "" and GameState.album.has_photo(before):
		var pair := UiKit.hbox(8)
		pair.name = "BeforeAfterPhotos"
		pair.alignment = BoxContainer.ALIGNMENT_CENTER
		var old := PhotoCard.make(before, 120.0, {"caption": false})
		old.name = "BeforePhoto"
		pair.add_child(old)
		pair.add_child(UiKit.label("→", &"TitleLabel"))
		pair.add_child(PhotoCard.make(id, 120.0, {}))
		box.add_child(pair)
	if GameState.house_has("photo_wall"):
		var hung: bool = GameState.album.wall.has(id)
		var hang := UiKit.secondary("Tirar da parede" if hung else "Pendurar na parede", func() -> void:
			var reason := ""
			if hung:
				GameState.unhang_photo(id)
			else:
				reason = GameState.hang_photo(id)
			if reason != "":
				Events.toast_requested.emit(reason)
			else:
				open_photo(id))
		hang.name = "HangButton"
		box.add_child(hang)
	if GameState.house_has("gold_frame"):
		var main: bool = GameState.album.main_photo == id
		var pick := UiKit.secondary("Tirar do cantinho" if main else "Foto do cantinho", func() -> void:
			GameState.set_main_photo("" if main else id)
			open_photo(id))
		pick.name = "MainButton"
		box.add_child(pick)
	box.add_child(UiKit.secondary("Voltar ao álbum", func() -> void: PetNotebook.open("album:" + str(entry.section))))
	return box


## Silhueta, pista permanente e lupa diária para as fotos que ainda não aconteceram.
static func secret_detail(id: String) -> Control:
	var entry := Database.photo(id)
	var box := UiKit.vbox(8)
	box.name = "PhotoSecret"
	var center := CenterContainer.new()
	center.add_child(PhotoCard.make(id, 220.0, {"locked": true}))
	box.add_child(center)
	box.add_child(UiKit.fill_label(str(entry.get("hint", "Uma lembrança espera por vocês.")), &"SmallLabel"))
	if str(entry.section) in ["tricks", "sleep"]:
		if int(GameState.album.hints.get(id, 0)) > 0:
			var row := UiKit.flow()
			row.name = "HintIcons"
			for icon: Variant in entry.get("icons", []):
				row.add_child(UiKit.icon(UiKit.ui_icon(str(icon)), 32))
			box.add_child(row)
		else:
			var button := UiKit.secondary("?  Lupa · %d" % GameState.album_lupas_left(), func() -> void:
				var error := GameState.reveal_photo_hint(id)
				if error != "": Events.toast_requested.emit(error)
				else: Events.sheet_requested.emit(str(entry.title), secret_detail(id)))
			button.name = "HintButton"
			box.add_child(button)
	box.add_child(UiKit.secondary("Voltar ao álbum", func() -> void: PetNotebook.open("album:" + str(entry.section))))
	return box
