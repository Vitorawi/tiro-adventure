extends SceneTree
## Álbum em tela própria: capturas da home com os dois botões e da tela do Álbum (cartas fechadas, seções, carta aberta,
## tutorial). NÃO é teste. Rodar SEM --headless, uma vez por resolução:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/album_screen_shots.gd -- --out=album_screen
## PNGs em build/screenshots/<out>/<caso>_<largura>x<altura>.png; imprime "FAIL ..." nas medições.
## Usa save descartável.

var state: Node
var main: Node
var folder := "album_screen"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(170.0).timeout.connect(func() -> void:
		print("TEMPO ESGOTADO")
		quit(1))


func _fail(message: String) -> void:
	failures += 1
	print("FAIL ", message)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: (node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree(): (intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	main.get("_photo_queue").clear()


func _top() -> float:
	return float((load("res://scripts/ui/hud.gd") as GDScript).get_script_constant_map()["SHEET_TOP"])


func _hud_h() -> float:
	return float((load("res://scripts/ui/hud.gd") as GDScript).get_script_constant_map()["HEIGHT"])


## Pelo menos duas linhas inteiras de cartas abaixo da faixa "Para abrir" (ou do resumo), na rolagem em 0.
## Abas do álbum: nomes escritos, todas visíveis (sem ScrollContainer), altura igual ≥ 44, dentro do miolo, fileiras simétricas,
## nome nunca cortado/elidido, e título + selos de nível na mesma linha.
func _audit_tabs(label: String, area: Control) -> void:
	var strip := area.find_child("CodexFilters", true, false) as Control
	if strip == null:
		return
	var parent := strip.get_parent()
	while parent != null and parent != area:
		if parent is ScrollContainer: _fail("%s: filtros dentro de ScrollContainer" % label)
		parent = parent.get_parent()
	var board := area.find_child("CodexBoard", true, false) as Control
	var wood: Rect2 = board.get_meta("wood")
	var inner := Rect2(board.global_position + wood.position, wood.size)
	var rows := {}
	var height := -1.0
	for node in strip.get_children():
		var tab := node as Button
		if tab == null: continue
		var r := tab.get_global_rect()
		if r.size.x < 44.0 or r.size.y < 44.0: _fail("%s: aba %s menor que 44 (%s)" % [label, tab.name, r.size])
		if height < 0.0: height = r.size.y
		elif absf(height - r.size.y) > 0.5: _fail("%s: abas de alturas diferentes" % label)
		if not inner.encloses(r): _fail("%s: aba %s fora do miolo" % [label, tab.name])
		var dot := tab.find_child("NewBadge", true, false) as Control
		if dot != null and not r.encloses(dot.get_global_rect()):
			_fail("%s: pontinho da aba %s sai pela borda da aba" % [label, tab.name])
		var caption := tab.find_child("Caption", true, false) as Label
		if caption == null or caption.text == "": _fail("%s: aba %s sem nome escrito" % [label, tab.name])
		else:
			if caption.get_line_count() > 2: _fail("%s: nome da aba %s em mais de 2 linhas" % [label, tab.name])
			var font := caption.get_theme_font("font")
			var px := caption.get_theme_font_size("font_size")
			for word in caption.text.split(" "):
				if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > caption.size.x + 0.5:
					_fail("%s: palavra '%s' cortada na aba %s" % [label, word, tab.name])
		var key := snappedf(r.position.y, 1.0)
		if not rows.has(key): rows[key] = []
		(rows[key] as Array).append(r)
	for key in rows:
		var list: Array = rows[key]
		var left := (list[0] as Rect2).position.x
		var right := (list[list.size() - 1] as Rect2).end.x
		if absf((left - inner.position.x) - (inner.end.x - right)) > 2.0: _fail("%s: fileira de abas assimétrica" % label)
	# A grade nunca toca a linha creme lateral da moldura: >= 6 px entre elas (a linha fica ~10 px dentro do miolo).
	var consts: Dictionary = (load("res://scripts/ui/codex_ui.gd") as GDScript).get_script_constant_map()
	var creme: Vector4 = consts["CREAM"]
	var cream_left: float = board.global_position.x + float(consts["LEFT"]) + creme.x
	var cream_right: float = board.global_position.x + wood.position.x + wood.size.x - creme.z
	for grid in area.find_children("AlbumGrid", "GridContainer", true, false):
		var g := Rect2()
		var first := true
		for card in grid.get_children():
			var cr := (card as Control).get_global_rect()
			g = cr if first else g.merge(cr)
			first = false
		var book := area.find_child("AlbumBook", true, false) as Control
		if book != null and book.size.x > book.custom_minimum_size.x + 1.0:
			var widest := ""
			for child in book.get_children():
				if (child as Control).get_combined_minimum_size().x > book.custom_minimum_size.x + 1.0: widest += str(child.name) + " "
			_fail("%s: AlbumBook alargou para %s (esperado %s) por: %s" % [label, book.size.x, book.custom_minimum_size.x, widest])
		if g.position.x < cream_left + 16.0 - 0.5 or g.end.x > cream_right - 16.0 + 0.5:
			_fail("%s: a grade toca a linha lateral da moldura (%s..%s, miolo %s..%s)" % [label, g.position.x, g.end.x, cream_left, cream_right])
		if absf((g.position.x - cream_left) - (cream_right - g.end.x)) > 3.0:
			_fail("%s: folga lateral da grade assimétrica" % label)
	var title := area.find_child("AlbumTitle", true, false) as Control
	var levels := area.find_child("AlbumLevels", true, false) as Control
	if title != null and levels != null:
		if absf(title.get_global_rect().get_center().y - levels.get_global_rect().get_center().y) > 3.0:
			_fail("%s: título e selos de nível em linhas diferentes" % label)


## Cartas: sem cadeado nem texto de pista; legendas centralizadas e com a mesma altura reservada.
func _audit_captions(label: String, area: Control) -> void:
	var heights := {}
	for node in area.find_children("AlbumCaption", "Label", true, false):
		var l := node as Label
		heights[snappedf(l.size.y, 0.5)] = true
		if l.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER: _fail("%s: legenda não centralizada (%s)" % [label, l.text])
		if l.get_line_count() > 2: _fail("%s: legenda em mais de 2 linhas (%s)" % [label, l.text])
	if heights.size() > 1: _fail("%s: legendas com alturas diferentes" % label)
	if area.find_child("MissingLock", true, false) != null: _fail("%s: cadeado em carta faltante" % label)
	if area.find_child("AlbumHint", true, false) != null: _fail("%s: texto de pista embaixo da carta" % label)


func _audit_rows(label: String, area: Control) -> void:
	var scroll := area.find_child("CodexScroll", true, false) as ScrollContainer
	if scroll == null:
		return
	var window := scroll.get_global_rect()
	var floor_y := window.position.y
	var sealed := area.find_child("AlbumSealed", true, false) as Control
	if sealed != null:
		floor_y = sealed.get_global_rect().end.y
	var rows := {}
	for node in area.find_children("AlbumCard_*", "Button", true, false):
		var r := (node as Control).get_global_rect()
		# Linhas INTEIRAS (carta + legenda) dentro da área visível: sem tocar o enfeite do canto do miolo.
		if r.position.y >= floor_y - 0.5 and r.end.y <= window.end.y + 0.5:
			rows[snappedf(r.position.y, 2.0)] = true
	if rows.size() < 2:
		_fail("%s: só %d linha(s) inteira(s) de cartas visíveis (mínimo 2)" % [label, rows.size()])


func _audit_viewer(label: String) -> void:
	var viewer: Control = load("res://scripts/ui/card_viewer.gd").get("current") as Control
	if viewer == null:
		return
	var hud := Rect2(0.0, 0.0, root.get_visible_rect().size.x, _hud_h())
	for named: String in ["CardTitle", "CloseViewer", "CardInfo", "CardSlot", "CardVersions", "CardBoard"]:
		var n := viewer.find_child(named, true, false) as Control
		if n != null and n.is_visible_in_tree() and n.get_global_rect().intersects(hud):
			_fail("%s: %s do visualizador sobre o HUD %s" % [label, named, n.get_global_rect()])
		if n != null and n.is_visible_in_tree() and n.get_global_rect().end.y > root.get_visible_rect().size.y + 0.5:
			_fail("%s: %s fora da tela embaixo" % [label, named])
	var slot := viewer.find_child("CardSlot", true, false) as Control
	if slot != null and root.get_visible_rect().size.x <= 360.0 and slot.size.x < 240.0:
		_fail("%s: carta com %s px (mínimo 240 em 360)" % [label, slot.size.x])
	var album_x := main.find_child("AlbumScreen", true, false)
	if album_x != null:
		var close := album_x.find_child("CloseButton", true, false) as Control
		if close != null and close.is_visible_in_tree() and close.modulate.a > 0.01:
			_fail("%s: o X da folha do álbum continua visível sob a carta" % label)


func _audit_balloon(label: String, tut: Control) -> void:
	var balloon := tut.find_child("TutorialBalloon", true, false) as Control
	if balloon == null or not balloon.visible:
		return
	# O VBox do balão pode medir mais que o desenho: vale o que se vê (fala + retrato).
	var speech := tut.get("_balloon_label") as Control
	var rect := speech.get_global_rect()
	var face := balloon.find_child("NpcPortrait", true, false) as Control
	if face != null:
		rect = rect.merge(face.get_global_rect())
	if rect.intersects(Rect2(0.0, 0.0, root.get_visible_rect().size.x, _hud_h())):
		_fail("%s: balão sobre o HUD %s" % [label, rect])
	var plate := main.find_child("CodexPlate", true, false) as Control
	if plate != null and plate.is_visible_in_tree() and rect.intersects(plate.get_global_rect()):
		_fail("%s: balão sobre a placa do Álbum" % label)
	var hole: Rect2 = tut.call("target_rect")
	if hole.size != Vector2.ZERO and rect.intersects(hole):
		_fail("%s: balão sobre o alvo %s %s" % [label, rect, hole])
	if not root.get_visible_rect().encloses(rect):
		_fail("%s: balão fora da tela %s" % [label, rect])


func _bars_top() -> float:
	var bar := main.find_child("TabBarArt", true, false) as Control
	return bar.get_global_rect().position.y if bar != null and bar.visible else root.get_visible_rect().size.y - 84.0


## Medições de uma tela: tudo dentro da tela, fora do HUD e da barra de abas, alvos ≥ 44, texto cortado, razão das imagens.
func _audit(label: String, area: Control) -> void:
	var screen := root.get_visible_rect()
	var top := _top()
	var bottom := _bars_top()
	for node in area.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree(): continue
		var rect := control.get_global_rect()
		if control is Button and rect.size.x > 0.0:
			if rect.size.x < 44.0 or rect.size.y < 44.0:
				_fail("%s: alvo menor que 44 em %s %s" % [label, control.name, rect.size])
		if control is Label and (control as Label).clip_text and (control as Label).autowrap_mode == TextServer.AUTOWRAP_OFF:
			var l := control as Label
			var font := l.get_theme_font("font")
			var px := l.get_theme_font_size("font_size")
			if font != null and l.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > rect.size.x + 1.5:
				_fail("%s: texto cortado em %s (%s) largura %s fonte %s" % [label, l.name, l.text, rect.size.x, px])
		if control is TextureRect and (control as TextureRect).texture != null and (control as TextureRect).stretch_mode == TextureRect.STRETCH_SCALE:
			var t := control as TextureRect
			var texture_ratio := float(t.texture.get_width()) / float(t.texture.get_height())
			if rect.size.y > 1.0 and absf(rect.size.x / rect.size.y / texture_ratio - 1.0) > 0.01:
				_fail("%s: imagem distorcida em %s" % [label, t.name])
	_audit_tabs(label, area)
	var board := area.find_child("CodexBoard", true, false) as Control
	if board != null:
		var r := board.get_global_rect()
		if r.position.x < -0.5 or r.end.x > screen.size.x + 0.5: _fail("%s: moldura fora da tela %s" % [label, r])
		if r.position.y < top - 1.0: _fail("%s: moldura sob o HUD %s" % [label, r])
		var wood: Rect2 = board.get_meta("wood")
		if r.position.y + wood.end.y > bottom + 1.0: _fail("%s: madeira sob a barra de abas" % label)
	for named: String in ["CloseButton", "CodexTitle", "CodexFilterScroll"]:
		var n := area.find_child(named, true, false) as Control
		if n != null and n.is_visible_in_tree() and not screen.encloses(n.get_global_rect()):
			_fail("%s: %s fora da tela %s" % [label, named, n.get_global_rect()])


func shot(label: String, wait: float = 0.7) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/")
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "%s_%dx%d.png" % [label, image.get_width(), image.get_height()])


func _home_audit(label: String) -> void:
	var pet := main.find_child("PetScreen", true, false) as Control
	var screen := root.get_visible_rect()
	var album := pet.find_child("AlbumButton", true, false) as Control
	var manual := pet.find_child("ManualButton", true, false) as Control
	if album == null or not album.visible:
		_fail("%s: botão do Álbum ausente" % label)
		return
	var rect := album.get_global_rect()
	if not screen.encloses(rect): _fail("%s: botão do Álbum fora da tela" % label)
	if rect.size.x < 44.0 or rect.size.y < 44.0: _fail("%s: botão do Álbum menor que 44" % label)
	if rect.position.y < manual.get_global_rect().end.y: _fail("%s: Álbum não está abaixo do caderninho" % label)
	if absf(rect.position.x - manual.get_global_rect().position.x) > 0.5: _fail("%s: Álbum desalinhado do caderninho" % label)
	var art := album.get_node("AlbumArt") as TextureRect
	var texture_ratio := float(art.texture.get_width()) / float(art.texture.get_height())
	if absf(art.size.x / art.size.y / texture_ratio - 1.0) > 0.01: _fail("%s: arte do Álbum distorcida" % label)
	for other: String in ["PhotoLine", "WishBubble", "CareButton", "MoodBubble", "NeedsPanel"]:
		var node := pet.find_child(other, true, false) as Control
		if node != null and node.is_visible_in_tree() and node.get_global_rect().size.x > 0.0 and node.get_global_rect().intersects(rect):
			_fail("%s: botão do Álbum encosta em %s" % [label, other])
	var care := pet.find_child("CareButton", true, false) as Control
	if care != null and care.is_visible_in_tree() and care.get_global_rect().intersects(manual.get_global_rect()):
		_fail("%s: caderninho encosta em Cuidar" % label)


func _open_album(section: String = "") -> Control:
	load("res://scripts/ui/album_screen.gd").call("open", section)
	await create_timer(0.8).timeout
	_hide_modals()
	return main.find_child("AlbumScreen", true, false) as Control


func _close() -> void:
	root.get_node("Events").sheet_close_requested.emit()
	await create_timer(0.5).timeout


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer: child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "album_screen_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("show_screen", &"pet")
	await create_timer(0.5).timeout
	_hide_modals()
	# Fotos de várias seções: abertas com versões, algumas fechadas, e o varal da home.
	var database: Node = root.get_node("Database")
	var ids: Array[String] = []
	for entry: Dictionary in database.album.photos:
		if str(entry.section) in database.album.active_sections and ids.size() < 40:
			ids.append(str(entry.id))
	for i in ids.size():
		state.call("dev_take_photo", ids[i], 1 + (i % 4))
	state.call("note_screen_opened", "album")
	state.call("dev_seal_photo", ids[2])
	state.call("dev_seal_photo", ids[5])
	state.call("feature_photo", ids[0])
	state.call("feature_photo", ids[1])
	state.call("feature_photo", ids[3])
	await create_timer(0.8).timeout
	_hide_modals()
	_home_audit("home")
	await shot("a_home")
	# Tela do Álbum: início (cartas fechadas, resumo).
	var first_section := str(database.photo(ids[0]).section)
	var screen := await _open_album("")
	if screen == null:
		_fail("tela do Álbum não abriu")
		quit(1)
		return
	_audit("album_inicio", screen)
	_audit_rows("album_inicio", screen)
	_audit_captions("album_inicio", screen)
	await shot("b_inicio")
	var scroll := screen.find_child("CodexScroll", true, false) as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 100000
		await create_timer(0.4).timeout
		_audit("album_fim", screen)
		await shot("c_rolado")
	# Outras seções (um filtro por vez; os filtros são refeitos a cada troca).
	var total := 0
	var strip := screen.find_child("CodexFilters", true, false)
	if strip != null:
		for child in strip.get_children():
			if child is Button: total += 1
	for index in range(1, total):
		strip = screen.find_child("CodexFilters", true, false)
		var buttons: Array[Button] = []
		for child in strip.get_children():
			if child is Button: buttons.append(child as Button)
		buttons[index].pressed.emit()
		await create_timer(0.5).timeout
		screen = main.find_child("AlbumScreen", true, false) as Control
		_audit("album_secao_%d" % index, screen)
		_audit_captions("album_secao_%d" % index, screen)
		if index == 1: _audit_rows("album_secao_1", screen)
		if index == total - 1:
			await shot("d_secao")
			# Toque numa faltante: balãozinho de madeira com a dica (e fecha ao tocar fora).
			var missing: Button = null
			for card in screen.find_children("AlbumCard_*", "Button", true, false):
				if (card as Control).find_child("HintMark", true, false) != null:
					missing = card as Button
					break
			if missing == null:
				_fail("seção incompleta sem carta faltante com ?")
			else:
				missing.pressed.emit()
				await create_timer(0.5).timeout
				var pop := main.find_child("PhotoHintPop", true, false) as Control
				if pop == null:
					_fail("o ? da faltante não abriu o balãozinho da dica")
				else:
					var pr := pop.get_global_rect()
					var top := _hud_h()
					if not root.get_visible_rect().encloses(pr) or pr.position.y < top: _fail("balãozinho da dica fora da tela ou sob o HUD %s" % pr)
					await shot("h_dica", 0.2)
				var catcher := main.find_child("PopoverCatcher", true, false)
				if catcher != null: catcher.queue_free()
				await create_timer(0.3).timeout
	# Carta aberta por cima do álbum.
	screen = await _open_album(first_section)
	var card := screen.find_child("AlbumCard_" + ids[1], true, false) as Button
	if card != null:
		card.pressed.emit()
		await create_timer(1.0).timeout
		var viewer: Control = load("res://scripts/ui/card_viewer.gd").get("current") as Control
		if viewer == null: _fail("carta não abriu por cima do álbum")
		_audit_viewer("carta")
		await shot("e_carta")
		if viewer != null: viewer.call("close")
		await create_timer(0.4).timeout
	await _close()
	# Tutorial: save novo, foto da chegada fechada.
	state.call("reset")
	var intro: Array[String] = ["intro"]
	state.call("mark_seen", intro)
	state.get("progress").claimed_quests["lais_play"] = true
	main.call("show_screen", &"pet")
	await create_timer(0.6).timeout
	_hide_modals()
	_home_audit("home_novo")
	await shot("f_home_novo")
	load("res://scripts/ui/album_screen.gd").call("open", "")
	for i in 60:
		var tutorial: Control = load("res://scripts/ui/album_tutorial.gd").get("current") as Control
		if tutorial != null and str(tutorial.get("phase")) == "open": break
		await create_timer(0.1).timeout
		_hide_modals()
	var tut: Control = load("res://scripts/ui/album_tutorial.gd").get("current") as Control
	if tut == null or str(tut.get("phase")) != "open":
		_fail("tutorial não começou na tela do Álbum")
	else:
		var hole: Rect2 = tut.call("target_rect")
		if not root.get_visible_rect().encloses(hole) or hole.size.x < 44.0 or hole.size.y < 44.0:
			_fail("tutorial: alvo fora da tela ou pequeno %s" % hole)
		await shot("g_tutorial")
		_audit_balloon("tutorial", tut)
		_audit_viewer("tutorial")
	print("ALBUM SCREEN SHOTS: ", "PASS" if failures == 0 else "FALHAS=%d" % failures)
	quit(failures)
