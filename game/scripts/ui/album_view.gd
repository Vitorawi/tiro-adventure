class_name AlbumView
extends RefCounted
## Livro de cartas no caderninho: duas colunas, versões, Para abrir e pistas em madeira.

const COLUMNS := 2


## Seção aberta por último na sessão (a aba volta nela).
static var last_section: String = ""


static func panel(section: String = "") -> Control:
	return CodexUi.build("album", section)


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


static func _tap(id: String) -> void:
	if GameState.album.has_photo(id):
		open_photo(id)
	else:
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
	box.add_child(UiKit.soft("Voltar ao álbum", func() -> void: PetNotebook.open("album:" + str(entry.section))))
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
	elif not hint.go.is_empty():
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
	inner.add_child(WelcomeSheet._button("Voltar ao álbum", false, width, "BackToAlbum", func() -> void: PetNotebook.open("album:" + str(entry.section))))
	return box


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


## Faltante: ilustração base em baixa resolução, cinza e escura. Segredo sem pista nunca carrega a arte.
static func preview(id: String, width: float) -> Control:
	if secret_hidden(id) or (GameState.album.has_photo(id) and GameState.photo_rarity(id) == 0):
		return back(width)
	var card := PhotoCard.make(id, width, {"thumb": true, "locked": not GameState.album.has_photo(id)})
	if not GameState.album.has_photo(id):
		var art := PhotoCard.art_for(id, 0)
		if art != null:
			var image := art.get_image()
			image.resize(24, 24, Image.INTERPOLATE_LANCZOS)
			for y in image.get_height():
				for x in image.get_width():
					var pixel := image.get_pixel(x, y)
					var gray := pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114
					image.set_pixel(x, y, Color(gray * 0.48, gray * 0.48, gray * 0.48, pixel.a))
			var window := card.get_node("Canvas/Window") as Control
			for child in window.get_children():
				window.remove_child(child)
				child.free()
			var picture := TextureRect.new()
			picture.name = "MissingIllustration"
			picture.texture = ImageTexture.create_from_image(image)
			picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			picture.size = window.size
			picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
			window.add_child(picture)
	return card


## Contagens da seção: fotos obtidas (inclui fechadas), versões possuídas, quatro níveis.
static func summary(section: String) -> Dictionary:
	var counts := _section_counts(section)
	var levels := {1: 0, 2: 0, 3: 0, 4: 0}
	var versions := 0
	for entry: Dictionary in Database.album.photos:
		if str(entry.section) != section:
			continue
		for level: int in GameState.photo_variants(str(entry.id)):
			if levels.has(level):
				levels[level] += 1
				versions += 1
	return {"taken": counts.x, "total": counts.y, "versions": versions, "possible": counts.y * 4, "levels": levels}


static func book(section: String, width: float) -> Control:
	var box := VBoxContainer.new()
	box.name = "AlbumBook"
	box.custom_minimum_size.x = width
	box.add_theme_constant_override("separation", 10)
	var stats := summary(section)
	var name_text := section
	for entry: Dictionary in Database.album_sections():
		if str(entry.id) == section: name_text = str(entry.name)
	var head := VBoxContainer.new()
	head.name = "AlbumSummary"
	head.set_meta("counts", stats)
	var milestones := GameState.album_milestones(section)
	var done: bool = bool(milestones.section.get("complete", false))
	head.add_child(_text("%s %d/%d%s" % [name_text, stats.taken, stats.total, "  ✓" if done else ""], 17, width))
	if done:
		head.get_child(head.get_child_count() - 1).name = "SectionComplete"
	var levels := HBoxContainer.new()
	levels.name = "AlbumLevels"
	levels.add_theme_constant_override("separation", 4)
	for level in range(1, 5):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.name = "LevelSeal_%d" % level
		icon.texture = load(PhotoCard.FRAMES_DIR + "frame_%d.png" % level)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.custom_minimum_size = Vector2(20, 20)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var count := _text(str(stats.levels[level]), 13, 24)
		count.name = "AlbumLevelCount_%d" % level
		count.autowrap_mode = TextServer.AUTOWRAP_OFF
		row.add_child(count)
		levels.add_child(row)
	head.add_child(levels)
	head.add_child(_text("Versões %d/%d" % [stats.versions, stats.possible], 13, width))
	var rare: Dictionary = milestones.rare
	if not rare.is_empty():
		var next := _text("Mais %d Rara%s" % [rare.left, "s" if int(rare.left) > 1 else ""], 13, width)
		next.name = "NextMilestone"
		head.add_child(next)
	box.add_child(head)
	# A faixa cobre todas as seções ativas; o botão abre a primeira sem consumir antecipadamente.
	var sealed: Array[String] = []
	var amount := 0
	for id: String in GameState.sealed_photos():
		if str(Database.photo(id).section) in Database.album.active_sections:
			sealed.append(id)
			amount += GameState.photo_sealed(id)
	if not sealed.is_empty():
		var strip := HBoxContainer.new()
		strip.name = "AlbumSealed"
		strip.add_theme_constant_override("separation", 6)
		strip.add_child(back(44))
		var column := VBoxContainer.new()
		column.add_child(_text("Para abrir", 14, width - 50))
		column.add_child(WelcomeSheet._button("Abrir (%d)" % amount, true, width - 50, "AlbumOpenSealed", open_photo.bind(sealed[0])))
		strip.add_child(column)
		box.add_child(strip)
	var near := near_entries(section)
	if not near.is_empty():
		var strip := VBoxContainer.new()
		strip.name = "AlbumNear"
		strip.add_child(_text("Quase lá", 16, width))
		for entry: Dictionary in near:
			strip.add_child(_hint_line(entry, width, 13))
			strip.add_child(WelcomeSheet._button("Ir", false, 80, "AlbumNearGo_" + str(entry.id), Places.go.bind(entry.go)))
		box.add_child(strip)
	var grid := GridContainer.new()
	grid.name = "AlbumGrid"
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 12)
	var card_w := floorf((width - 6.0) / 2.0)
	for entry: Dictionary in Database.album.photos:
		if str(entry.section) == section:
			grid.add_child(book_card(str(entry.id), card_w))
	box.add_child(grid)
	return box


static func book_card(id: String, width: float) -> Button:
	var taken := GameState.album.has_photo(id)
	var entry := Database.photo(id)
	var button := BagUi.plain_button(_tap.bind(id))
	button.name = "AlbumCard_" + id
	button.set_meta("photo", id)
	button.set_meta("level", GameState.photo_shown_rarity(id))
	var hidden := secret_hidden(id)
	var hint := GameState.photo_hint(id)
	var caption := "???" if hidden else str(entry.title)
	var content := caption
	var hint_text := str(hint.text) + (" · %d/%d" % [hint.have, hint.need] if int(hint.need) > 0 else "")
	var hint_width := width - 36.0 if str(hint.icon) != "" else width
	var caption_h := CodexUi._line_count(content, 12, width) * 17.0 + 6.0
	var hint_h := maxf(32.0, CodexUi._line_count(hint_text, 12, hint_width) * 17.0) if not taken else 0.0
	var text_h := caption_h + hint_h
	button.custom_minimum_size = Vector2(width, width + maxf(38.0, text_h))
	button.add_child(preview(id, width))
	var label := _text(content, 12, width)
	label.name = "AlbumCaption"
	label.position.y = width + 3
	label.size = Vector2(width, caption_h)
	if not taken:
		var line := _hint_line(hint, width)
		line.position.y = width + 3 + caption_h
		line.size = Vector2(width, hint_h)
		button.add_child(line)
	button.add_child(label)
	if not taken:
		var lock := UiKit.icon(UiKit.ctl_icon("lock"), 24)
		lock.name = "MissingLock"
		lock.position = Vector2(width - 28, width - 28)
		button.add_child(lock)
	elif not bool(GameState.album.photos[id].get("seen", false)):
		var badge := _text("Novo", 11, 34)
		badge.name = "NewBadge"
		badge.position = Vector2(6, width - 23)
		button.add_child(badge)
	if taken and GameState.photo_styles_complete(id):
		var mark := _text("4/4", 11, 30)
		mark.name = "StylesComplete"
		mark.position = Vector2(width - 34, width - 23)
		button.add_child(mark)
	return button


## A faixa só destaca progresso real da seção; a ordenação vem do GameState.
static func near_entries(section: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for hint: Dictionary in GameState.near_photos(Database.album.photos.size()):
		if str(Database.photo(str(hint.id)).section) != section: continue
		if int(hint.have) <= 0 or int(hint.need) <= 0 or hint.go.is_empty(): continue
		result.append(hint)
		if result.size() == 3: break
	return result
