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
	var current: Dictionary = sections.filter(func(entry: Dictionary) -> bool: return str(entry.id) == section)[0]
	# Cabeçalho: seção atual (ícone + nome + quantas já foram tiradas) e o progresso geral discreto.
	var head := UiKit.hbox(8)
	head.name = "AlbumHeader"
	head.add_child(UiKit.icon(UiKit.ui_icon(str(current.icon)), 32))
	var title := UiKit.label(str(current.name), &"SectionLabel")
	title.name = "AlbumSectionTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var counts := _section_counts(section)
	var section_count := UiKit.short_label("%d/%d" % [counts.x, counts.y], &"SectionLabel", Palette.INK_SOFT)
	section_count.name = "AlbumSectionCount"
	head.add_child(section_count)
	box.add_child(head)
	var overall := UiKit.collection_progress(taken_count(), total_count())
	overall.name = "AlbumProgress"
	box.add_child(overall)
	# Seletor: chips com ícone e nome, em rolagem horizontal.
	var unseen_sections: Array = GameState.photos_unseen().map(func(id: String) -> String: return str(Database.photo(id).section))
	var tabs: Array[Dictionary] = []
	for entry: Dictionary in sections:
		tabs.append({"id": str(entry.id), "text": str(entry.name), "icon": UiKit.ui_icon(str(entry.icon)), "alert": str(entry.id) in unseen_sections})
	var segmented := UiKit.segmented(tabs, section, func(id: String) -> void: PetNotebook.open("album:" + id))
	segmented.name = "AlbumSections"
	for tab in segmented.get_children():
		var button := tab as Button
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.custom_minimum_size = Vector2(0, 40)
		button.add_theme_font_size_override("font_size", 16)
		var badge := button.find_child("NewBadge", false, false) as Label
		if badge != null:
			_make_dot(badge, 10)
			badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			badge.position += Vector2(-2, 8)
	var strip := ScrollContainer.new()
	strip.name = "AlbumSectionScroll"
	strip.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	strip.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	strip.custom_minimum_size = Vector2(0, 52)
	var strip_pad := MarginContainer.new()
	strip_pad.add_theme_constant_override("margin_top", 6)
	strip_pad.add_theme_constant_override("margin_right", 10)
	strip_pad.add_child(segmented)
	strip.add_child(strip_pad)
	box.add_child(strip)
	var selected_tab := segmented.find_child("NotebookTab_" + section, false, false) as Control
	if selected_tab != null:
		_reveal_tab.call_deferred(strip, selected_tab)
	var grid := GridContainer.new()
	grid.name = "AlbumGrid"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 10)
	for entry: Dictionary in Database.album.photos:
		if str(entry.section) == section:
			grid.add_child(_tile(entry))
	box.add_child(grid)
	return box


## Transforma o selo de novidade numa bolinha sem texto visível.
static func _make_dot(badge: Label, px: int) -> void:
	# A altura mínima do Label não encolhe abaixo de 24: reduz por escala.
	badge.custom_minimum_size = Vector2(24, 24)
	badge.size = Vector2(24, 24)
	badge.scale = Vector2.ONE * (px / 24.0)
	badge.add_theme_color_override("font_color", Color(1, 1, 1, 0))
	badge.add_theme_font_size_override("font_size", 6)
	badge.add_theme_font_size_override("outline_size", 0)
	badge.clip_text = true
	badge.theme_type_variation = &""
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.DANGER
	style.set_corner_radius_all(12)
	badge.add_theme_stylebox_override("normal", style)


## Rola o seletor até o chip da seção aberta, depois do primeiro layout.
static func _reveal_tab(strip_ref: Variant, tab_ref: Variant) -> void:
	var strip := strip_ref as ScrollContainer if is_instance_valid(strip_ref) else null
	var tab := tab_ref as Control if is_instance_valid(tab_ref) else null
	if strip == null or tab == null:
		return
	if not is_instance_valid(strip) or not strip.is_inside_tree():
		return
	await strip.get_tree().process_frame
	if is_instance_valid(strip) and is_instance_valid(tab):
		strip.scroll_horizontal = maxi(0, int(tab.position.x + tab.size.x * 0.5 - strip.size.x * 0.5))


## (tiradas, total) de uma seção.
static func _section_counts(section: String) -> Vector2i:
	var taken := 0
	var total := 0
	for entry: Dictionary in Database.album.photos:
		if str(entry.section) == section:
			total += 1
			taken += 1 if GameState.album.has_photo(str(entry.id)) else 0
	return Vector2i(taken, total)


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
	tile.custom_minimum_size = Vector2(0, 130)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var clear := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		tile.add_theme_stylebox_override(state, clear)
	var column := UiKit.vbox(2)
	column.name = "Visual"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_BEGIN
	var card := PhotoCard.make(id, 100.0, {"secret": secret, "thumb": true})
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
		# Bolinha no canto superior direito da moldura; o "!" fica invisível só para manter o nó NewBadge.
		var badge := UiKit.alert_badge()
		_make_dot(badge, 11)
		badge.position = Vector2(88, -2)
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
