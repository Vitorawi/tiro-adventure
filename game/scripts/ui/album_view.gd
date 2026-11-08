class_name AlbumView
extends RefCounted
## Livro de cartas no caderninho: duas colunas, versões, Para abrir e pistas em madeira.

const COLUMNS := 3


## Seção aberta por último na sessão (a aba volta nela).
static var last_section: String = ""


static func panel(section: String = "") -> Control:
	return AlbumScreen.panel(section)


## (tiradas, total) de uma seção.
static func section_counts(section: String) -> Vector2i:
	return _section_counts(section)


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


static func _tap(id: String) -> void:
	if GameState.album.has_photo(id):
		open_photo(id)
		return
	var tree := Engine.get_main_loop() as SceneTree
	var tapped: Control = null
	for node in tree.root.find_children("AlbumCard_" + id, "Button", true, false):
		tapped = node as Control
		break
	if tapped != null and hint_popover(id, tapped) != null:
		return
	Events.sheet_requested.emit(str(Database.photo(id).title), secret_detail(id))


## Detalhe de uma foto tirada, no painel do caderninho. Abrir marca a foto como vista.
static func open_photo(id: String) -> void:
	if not GameState.album.has_photo(id):
		return
	if GameState.photo_sealed(id) > 0:
		CardReveal.open(id)
		return
	GameState.open_album_photo(id)
	# A carta grande em 3D (etapa 04); sem a casca (testes soltos) cai no detalhe liso de reserva.
	if CardViewer.open(id) != null:
		return
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
		var hang := UiKit.soft("Tirar da parede" if hung else "Pendurar na parede", func() -> void:
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
		var pick := UiKit.soft("Tirar do cantinho" if main else "Foto do cantinho", func() -> void:
			GameState.set_main_photo("" if main else id)
			open_photo(id))
		pick.name = "MainButton"
		box.add_child(pick)
	box.add_child(UiKit.soft("Voltar ao álbum", func() -> void: AlbumScreen.open(str(entry.section))))
	return box


## Folha de madeira compartilhada por toda faltante; a consulta guarda o segredo.
static func secret_detail(id: String) -> Control:
	return photo_hint(id)


static func photo_hint(id: String) -> Control:
	var entry := Database.photo(id)
	var hint := GameState.photo_hint(id)
	var made := CodexSections._detail(null, "???" if secret_hidden(id) else str(entry.title), "")
	var box: Control = made.box
	box.name = "PhotoHint"
	var inner: VBoxContainer = made.inner
	var stage := inner.get_node("UpgradeStage")
	inner.remove_child(stage)
	stage.free()
	(box.get_child(box.get_child_count() - 1) as Control).custom_minimum_size.y = CodexUi.TAB_BAR + CodexUi.TAIL
	var width := ItemUi.panel_width() - 84.0
	var center := CenterContainer.new()
	center.add_child(preview(id, minf(144.0, width)))
	inner.add_child(center)
	inner.add_child(_hint_line(hint, width, 14))
	if int(hint.need) > 0:
		var bar := ProgressBar.new()
		bar.name = "PhotoHintProgress"
		bar.custom_minimum_size.y = 12
		bar.max_value = hint.need
		bar.value = hint.have
		bar.show_percentage = false
		bar.add_theme_stylebox_override("background", UiKit.surface(Palette.CARD, 6))
		bar.add_theme_stylebox_override("fill", UiKit.surface(Palette.GO, 6))
		inner.add_child(bar)
	if is_secret(id) and not bool(hint.revealed):
		var button := WelcomeSheet._button("Lupa · %d" % GameState.album_lupas_left(), true, width, "HintButton", func() -> void:
			var error := GameState.reveal_photo_hint(id)
			if error != "": Events.toast_requested.emit(error)
			else: Events.sheet_requested.emit(str(entry.title), photo_hint(id)))
		if GameState.album_lupas_left() <= 0:
			button.free()
			button = StepCardUi.locked_button("A lupa volta amanhã", UiKit.ctl_icon("lock"))
			button.name = "HintButton"
		inner.add_child(button)
	elif hint_has_go(id, hint):
		var reason := _go_error(hint.go)
		var go: Button
		if reason == "":
			go = WelcomeSheet._button("Ir", true, width, "PhotoHintGo", Places.go.bind(hint.go))
		else:
			go = StepCardUi.locked_button(reason, UiKit.ctl_icon("lock"))
			go.name = "PhotoHintGo"
			go.set_meta("reason", reason)
		inner.add_child(go)
	var npc := str(entry.get("hint_npc", ""))
	if npc != "" and Database.npcs.has(npc):
		var row := HBoxContainer.new()
		row.name = "PhotoHintNpc"
		row.add_theme_constant_override("separation", 8)
		var face := UiKit.icon(ProgressionUi.npc_portrait(npc), 44)
		face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var portrait := StepCardUi.portrait_frame(face, 44, "HintNpcFace")
		(portrait.find_child("Wood", true, false) as TextureRect).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(portrait)
		var target := {"world": Database.npc_world(npc), "place": "npc:" + npc}
		row.add_child(WelcomeSheet._button("Conversar", false, width - 52, "PhotoHintTalk", Places.go.bind(target)))
		inner.add_child(row)
	inner.add_child(WelcomeSheet._button("Voltar ao álbum", false, width, "BackToAlbum", func() -> void: AlbumScreen.open(str(entry.section))))
	return box


## Dica com destino real? Dicas de tempo/data (seção Datas, ícone de calendário) não têm para onde ir: sem botão Ir.
static func hint_has_go(id: String, hint: Dictionary) -> bool:
	if hint.go.is_empty():
		return false
	if str(Database.photo(id).section) == "dates" or str(hint.get("icon", "")) == "album_dates":
		return false
	return true


static func _go_error(target: Dictionary) -> String:
	if not target.has("world"): return ""
	var world := str(target.world)
	var reason := Places.world_error(world)
	if reason != "": return reason
	var place: Dictionary = Database.worlds.get(world, {}).get("places", {}).get(str(target.get("place", "")), {})
	return Places.place_error(place) if not place.is_empty() else ""


## Ícone e texto concretos apenas depois de revelar; horas/datas não viram contadores.
static func _hint_line(hint: Dictionary, width: float, px: int = 12) -> Control:
	var row := HBoxContainer.new()
	row.name = "HintIcons"
	row.add_theme_constant_override("separation", 4)
	var icon := str(hint.get("icon", ""))
	var text_width := width
	if icon != "":
		row.add_child(UiKit.icon(UiKit.ui_icon(icon), 32))
		text_width -= 36
	var line := str(hint.text)
	if int(hint.need) > 0: line += " · %d/%d" % [hint.have, hint.need]
	var label := _text(line, px, text_width)
	label.name = "PhotoHintText"
	row.add_child(label)
	return row


static func is_secret(id: String) -> bool:
	var entry := Database.photo(id)
	return bool(entry.get("secret", false)) or str(entry.section) in ["tricks", "sleep"]


static func secret_hidden(id: String) -> bool:
	return is_secret(id) and not bool(GameState.photo_hint(id).get("revealed", false))


static func _text(value: String, px: int, width: float) -> Label:
	var label := MissionUi.text(value, px, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_LEFT)
	label.custom_minimum_size.x = width
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Verso quadrado compartilhado com a revelação; não cria SubViewport na grade.
static func back(width: float) -> Control:
	var picture := TextureRect.new()
	picture.name = "CardBack"
	picture.texture = load("res://assets/sprites/ui/album/card_back.png")
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2.ONE * width
	picture.size = picture.custom_minimum_size
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture


## Miniatura cinza 24×24 da foto que falta, guardada: a arte inteira não precisa ser decodificada a cada abertura.
static var _missing_cache: Dictionary = {}


static func _missing_texture(id: String) -> Texture2D:
	if _missing_cache.has(id):
		return _missing_cache[id]
	var art := PhotoCard.art_for(id, 0)
	if art == null:
		return null
	var image := art.get_image()
	image.resize(24, 24, Image.INTERPOLATE_LANCZOS)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var gray := pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
			image.set_pixel(x, y, Color(gray * 0.48, gray * 0.48, gray * 0.48, pixel.a))
	var texture := ImageTexture.create_from_image(image)
	_missing_cache[id] = texture
	return texture


## Faltante: ilustração base em baixa resolução, cinza e escura. Segredo sem pista nunca carrega a arte.
static func preview(id: String, width: float) -> Control:
	if secret_hidden(id) or (GameState.album.has_photo(id) and GameState.photo_rarity(id) == 0):
		return back(width)
	var card := PhotoCard.make(id, width, {"thumb": true, "lazy": true, "locked": not GameState.album.has_photo(id)})
	if not GameState.album.has_photo(id):
		var missing := _missing_texture(id)
		if missing != null:
			var window := card.get_node("Canvas/Window") as Control
			for child in window.get_children():
				window.remove_child(child)
				child.free()
			var picture := TextureRect.new()
			picture.name = "MissingIllustration"
			picture.texture = missing
			picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			picture.size = window.size
			picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			window.add_child(picture)
	return card


## Contagens da seção: fotos obtidas (inclui fechadas), versões possuídas, quatro níveis.
static func summary(section: String) -> Dictionary:
	var sections: Array[String] = []
	if section == "all":
		for entry: Dictionary in Database.album_sections():
			sections.append(str(entry.id))
	else:
		sections.append(section)
	var taken := 0
	var total := 0
	var levels := {1: 0, 2: 0, 3: 0, 4: 0}
	var versions := 0
	for id: String in sections:
		var counts := _section_counts(id)
		taken += counts.x
		total += counts.y
	for entry: Dictionary in Database.album.photos:
		if not (str(entry.section) in sections):
			continue
		for level: int in GameState.photo_variants(str(entry.id)):
			if levels.has(level):
				levels[level] += 1
				versions += 1
	return {"taken": taken, "total": total, "versions": versions, "possible": total * 4, "levels": levels}


## Seção completa (todas as cartas abertas); "all" = todas as seções ativas completas.
static func section_done(section: String) -> bool:
	if section != "all":
		return bool(GameState.album_milestones(section).section.get("complete", false))
	for entry: Dictionary in Database.album_sections():
		if not bool(GameState.album_milestones(str(entry.id)).section.get("complete", false)):
			return false
	return true


static func book(section: String, width: float) -> Control:
	var box := VBoxContainer.new()
	box.name = "AlbumBook"
	box.custom_minimum_size.x = width
	box.add_theme_constant_override("separation", 4)
	var stats := summary(section)
	var name_text := "Todas" if section == "all" else section
	for entry: Dictionary in Database.album_sections():
		if str(entry.id) == section: name_text = str(entry.name)
	# Uma linha só, alinhada ao centro: nome da aba + pílula "x/y" (+ ✓) à esquerda e os 4 selos de nível à direita.
	var head := VBoxContainer.new()
	head.name = "AlbumSummary"
	head.set_meta("counts", stats)
	head.add_theme_constant_override("separation", 0)
	var milestones := GameState.album_milestones("" if section == "all" else section)
	var done := section_done(section)
	var top := HBoxContainer.new()
	top.name = "AlbumTitleRow"
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_theme_constant_override("separation", 6)
	# Largura que sobra ao nome: total - pílula (58) - quatro selos com números (~126) - folgas; a fonte encolhe até caber.
	var title := _text(name_text, CodexUi.fit_px(name_text, width - 48.0 - 134.0 - 22.0, 18, 11), 40.0)
	title.name = "AlbumTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.custom_minimum_size.y = 22.0
	top.add_child(title)
	top.add_child(_count_pill("%d/%d" % [stats.taken, stats.total], done))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(spacer)
	var levels := HBoxContainer.new()
	levels.name = "AlbumLevels"
	levels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	levels.add_theme_constant_override("separation", 3)
	levels.tooltip_text = "Versões %d/%d" % [stats.versions, stats.possible]
	for level in range(1, 5):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		row.tooltip_text = str(PhotoCard.LEVEL_NAMES.get(level, ""))
		var icon := TextureRect.new()
		icon.name = "LevelSeal_%d" % level
		icon.texture = load(PhotoCard.FRAMES_DIR + "seal_%d.png" % level)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.custom_minimum_size = Vector2(16, 16)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var count := _text(str(stats.levels[level]), 12, 14)
		count.name = "AlbumLevelCount_%d" % level
		count.autowrap_mode = TextServer.AUTOWRAP_OFF
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(count)
		levels.add_child(row)
	top.add_child(levels)
	head.add_child(top)
	box.add_child(head)
	var rare: Dictionary = milestones.rare
	# Cartas fechadas: UM cartão de madeira baixo (versos empilhados + texto + Abrir). O botão abre a primeira sem consumir antes.
	var sealed: Array[String] = []
	var amount := 0
	for id: String in GameState.sealed_photos():
		# Só na aba Todas ou na seção que tem a carta fechada.
		if str(Database.photo(id).section) in Database.album.active_sections and (section == "all" or str(Database.photo(id).section) == section):
			sealed.append(id)
			amount += GameState.photo_sealed(id)
	if not sealed.is_empty():
		box.add_child(_sealed_card(sealed, amount, width))
	var near: Array[Dictionary] = []
	if section != "all":
		near = near_entries(section)
	if not near.is_empty():
		var strip := VBoxContainer.new()
		strip.name = "AlbumNear"
		strip.add_child(_text("Quase lá", 16, width))
		for entry: Dictionary in near:
			strip.add_child(_hint_line(entry, width, 13))
			strip.add_child(WelcomeSheet._button("Ir", false, 80, "AlbumNearGo_" + str(entry.id), Places.go.bind(entry.go)))
		box.add_child(strip)
	var card_w := floorf((width - 6.0 * (COLUMNS - 1)) / COLUMNS)
	if section == "all":
		# Só as fotos que o jogador tem, por seção (cabecinho fino) e na ordem do catálogo; as faltantes ficam nas abas.
		var shown := 0
		for entry: Dictionary in Database.album_sections():
			var ids: Array[String] = []
			for photo: Dictionary in Database.album.photos:
				if str(photo.section) == str(entry.id) and GameState.album.has_photo(str(photo.id)):
					ids.append(str(photo.id))
			if ids.is_empty():
				continue
			shown += ids.size()
			var group := VBoxContainer.new()
			group.name = "AlbumGroup_" + str(entry.id)
			group.add_theme_constant_override("separation", 2)
			var header := HBoxContainer.new()
			header.name = "AlbumGroupHeader"
			header.add_theme_constant_override("separation", 5)
			var mark := UiKit.icon(UiKit.ui_icon(str(entry.icon)), 16)
			mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			header.add_child(mark)
			var header_text := _text(str(entry.name), 13, width - 30.0)
			header_text.autowrap_mode = TextServer.AUTOWRAP_OFF
			header.add_child(header_text)
			group.add_child(header)
			group.add_child(_grid(ids, card_w))
			box.add_child(group)
		if shown == 0:
			var empty := _text("Ainda não há fotos. Elas chegam enquanto o Tiro vive!", 14, width)
			empty.name = "AlbumEmpty"
			box.add_child(empty)
	else:
		var ids: Array[String] = []
		for entry: Dictionary in Database.album.photos:
			if str(entry.section) == section:
				ids.append(str(entry.id))
		box.add_child(_grid(ids, card_w))
	if not rare.is_empty():
		var next := _text("Mais %d Rara%s para o próximo prêmio" % [rare.left, "s" if int(rare.left) > 1 else ""], 12, width)
		next.name = "NextMilestone"
		next.autowrap_mode = TextServer.AUTOWRAP_OFF
		next.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(next)
	return box


## Pílula "x/y" da seção: marrom enquanto incompleta, verde quando completa. Nó `SectionCount` (meta `complete`).
static func _count_pill(value: String, done: bool) -> Control:
	if not done:
		var brown := MissionUi.pill("brown", value, "SectionCount", Vector2(48, 24))
		brown.set_meta("complete", false)
		return brown
	var pill := PanelContainer.new()
	pill.name = "SectionCount"
	pill.set_meta("complete", true)
	pill.custom_minimum_size = Vector2(48, 24)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiKit.surface(Palette.GO, 12)
	style.border_color = Palette.GO_EDGE
	style.set_border_width_all(2)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	pill.add_theme_stylebox_override("panel", style)
	var text := MissionUi.text(value, 13, Color.WHITE, 0)
	text.name = "PillText"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.add_child(text)
	return pill


static func _grid(ids: Array[String], card_w: float) -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "AlbumGrid"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	for id in ids:
		grid.add_child(book_card(id, card_w))
	return grid


## Cartão baixo de madeira das cartas fechadas: 1–3 versos levemente deslocados, "N fotos para abrir" e o botão Abrir.
static func _sealed_card(sealed: Array[String], amount: int, width: float) -> Control:
	var card := MissionUi.card("card", Vector4i(10, 2, 10, 2), "AlbumSealed", 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stack := Control.new()
	stack.name = "SealedStack"
	var layers := mini(amount, 3)
	stack.custom_minimum_size = Vector2(34.0 + 6.0 * (layers - 1), 38.0)
	stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in layers:
		var back_card := back(34)
		back_card.position = Vector2(6.0 * (layers - 1 - i), 6.0 - 2.0 * (layers - 1 - i) * 0.5)
		back_card.rotation_degrees = (layers - 1 - i) * -4.0 if layers > 1 else 0.0
		stack.add_child(back_card)
	row.add_child(stack)
	var text := _text("%d %s para abrir" % [amount, "foto" if amount == 1 else "fotos"], 14, 100.0)
	text.name = "SealedText"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text)
	var open_button := WelcomeSheet._button("Abrir", true, 84.0, "AlbumOpenSealed", open_photo.bind(sealed[0]))
	open_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(open_button)
	MissionUi.body(card).add_child(row)
	return card


## Altura reservada à legenda (duas linhas): a mesma em todas as cartas, para as linhas da grade alinharem.
const CAPTION_LINES := 2
const CAPTION_LINE_H := 12.5

static func caption_height() -> float:
	return CAPTION_LINES * CAPTION_LINE_H + 2.0


## Maior fonte (12 a 9) em que o nome cabe em até duas linhas da largura da carta.
static func caption_px(text: String, width: float) -> int:
	var px := 12
	while px > 9 and (CodexUi._line_count(text, px, width - 4.0) > CAPTION_LINES or CodexUi._longest_word(text, px) > width - 4.0):
		px -= 1
	return px


static func book_card(id: String, width: float) -> Button:
	var taken := GameState.album.has_photo(id)
	var entry := Database.photo(id)
	var button := BagUi.plain_button(_tap.bind(id))
	button.name = "AlbumCard_" + id
	button.set_meta("photo", id)
	button.set_meta("level", GameState.photo_shown_rarity(id))
	var hidden := secret_hidden(id)
	var caption := "???" if hidden else str(entry.title)
	button.custom_minimum_size = Vector2(width, width + 2.0 + caption_height())
	button.add_child(preview(id, width))
	# Legenda: centralizada sob a carta, fonte da madeira em marrom, mesma altura reservada em todas.
	var px := caption_px(caption, width)
	var label := MissionUi.text(caption, px, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_CENTER)
	label.name = "AlbumCaption"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = CAPTION_LINES
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_constant_override("line_spacing", -3)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.position = Vector2(2.0, width + 2.0)
	label.size = Vector2(width - 4.0, caption_height())
	button.add_child(label)
	if not taken:
		# Faltante: só a bolinha de madeira com "?" no canto; a dica abre num balãozinho ao tocar.
		var mark := TextureRect.new()  # bolinha de madeira (map_disc) com o "?" branco
		mark.name = "HintMark"
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.texture = load(HomeUi.DIR + "map_disc.png") as Texture2D
		mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mark.size = Vector2(28.0, 28.0)
		mark.position = Vector2(width - 31.0, width - 31.0)
		var question := MissionUi.text("?", 18, Color.WHITE, 0)
		question.name = "Question"
		question.size = mark.size
		question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.add_child(question)
		button.add_child(mark)
	elif not bool(GameState.album.photos[id].get("seen", false)):
		var dot := CodexUi._new_dot(Vector2(3, 3))  # só a bolinha vermelha, sem texto
		dot.name = "NewBadge"
		button.add_child(dot)
	if taken and GameState.photo_styles_complete(id):
		var done_mark := MissionUi.text("4/4", 11, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_RIGHT)
		done_mark.name = "StylesComplete"
		done_mark.size = Vector2(30.0, 16.0)
		done_mark.position = Vector2(width - 34.0, width - 23.0)
		button.add_child(done_mark)
	return button


## Balãozinho de madeira com a dica da foto que falta: texto, contador, Ir (quando há destino) e, nos segredos sem lupa,
## o caminho para a pista completa. Fecha ao tocar fora (`Popover`, meta `popover_bare`).
static func hint_popover(id: String, anchor: Control) -> Popover:
	var tree := Engine.get_main_loop() as SceneTree
	var host := tree.root.get_node_or_null("Main") as Control
	if host == null:
		host = tree.current_scene as Control
	if host == null:
		return null
	var hint := GameState.photo_hint(id)
	var width := 220.0
	var card := MissionUi.card("card", Vector4i(12, 10, 12, 10), "PhotoHintPop", 10)
	card.set_meta("popover_bare", true)
	card.custom_minimum_size.x = width
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MissionUi.body(card).add_child(box)
	var text := _text(str(hint.text), 14, width - 24.0)
	text.name = "PhotoHintText"
	box.add_child(text)
	if int(hint.need) > 0:
		var count := _text("%d/%d" % [hint.have, hint.need], 13, width - 24.0)
		count.name = "PhotoHintCount"
		box.add_child(count)
	var secret_hidden_now := secret_hidden(id)
	if secret_hidden_now:
		box.add_child(WelcomeSheet._button("Ver pista", false, width - 24.0, "PhotoHintMore", func() -> void:
			Events.sheet_requested.emit(str(Database.photo(id).title), photo_hint(id))))
	elif hint_has_go(id, hint):
		var reason := _go_error(hint.go)
		if reason == "":
			box.add_child(WelcomeSheet._button("Ir", true, width - 24.0, "PhotoHintGo", Places.go.bind(hint.go)))
		else:
			var lock := StepCardUi.locked_button(reason, UiKit.ctl_icon("lock"))
			lock.name = "PhotoHintGo"
			lock.set_meta("reason", reason)
			box.add_child(lock)
	return Popover.open(host, anchor, card, 0.0)


## A faixa só destaca progresso real da seção; a ordenação vem do GameState.
static func near_entries(section: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for hint: Dictionary in GameState.near_photos(Database.album.photos.size()):
		if str(Database.photo(str(hint.id)).section) != section: continue
		if int(hint.have) <= 0 or int(hint.need) <= 0 or hint.go.is_empty(): continue
		result.append(hint)
		if result.size() == 3: break
	return result
