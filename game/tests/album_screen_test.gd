extends SceneTree
## Álbum fora do caderninho: botão `AlbumButton` na home (só com foto, selo, abaixo do caderninho), tela própria
## `AlbumScreen` sem aba lateral, entradas antigas redirecionadas e o tutorial começando na tela nova.

var failures := 0
var state: Node
var main: Control
var pet: Control


func _initialize() -> void:
	_run.call_deferred()
	create_timer(90.0).timeout.connect(func() -> void:
		print("ALBUM SCREEN TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Tela do Álbum: " + message)
		print("FALHA: ", message)


func frames(count: int = 4) -> void:
	for i in count: await process_frame


func _close() -> void:
	root.get_node("Events").sheet_close_requested.emit()
	await frames(8)


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	saver.get_parent().remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	for timer in main.find_children("*", "Timer", false, false):
		if is_equal_approx((timer as Timer).wait_time, 0.3): (timer as Timer).stop()
	pet = main.find_child("PetScreen", true, false)
	main.call("show_screen", &"pet")
	await frames()
	var screen: Script = load("res://scripts/ui/album_screen.gd")
	var notebook: Script = load("res://scripts/ui/pet_notebook.gd")

	# 1. Sem foto não há botão; com foto ele aparece logo abaixo do caderninho, do mesmo tamanho.
	state.call("dev_reset_album")
	state.call("_mark_all_seen")
	await frames()
	var album := pet.find_child("AlbumButton", true, false) as Button
	var manual := pet.find_child("ManualButton", true, false) as Button
	check(album != null and manual != null, "1: os dois botões existem")
	check(not album.visible, "1: sem foto o botão do Álbum não aparece")
	state.call("dev_take_photo", "h_arrival")
	await frames(6)
	check(album.visible, "2: com foto o botão aparece")
	check(album.size == manual.size, "2: mesmo tamanho do caderninho")
	check(is_equal_approx(album.position.x, manual.position.x) and album.position.y >= manual.position.y + manual.size.y, "2: logo abaixo do caderninho")
	check(album.get_node_or_null("AlbumArt") != null and (album.get_node("AlbumArt") as TextureRect).texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "2: arte de madeira suave")
	check(not (screen.call("available") as bool) == false, "2: AlbumScreen.available")

	# 2. Selo: só depois de conhecer o Álbum.
	var badge := album.find_child("AlbumNewBadge", true, false) as Control
	check(badge != null and not badge.visible, "3: sem avisos habilitados o selo fica escondido")
	state.call("note_screen_opened", "album")
	state.call("dev_seal_photo", "f_bath")
	await frames(6)
	check(badge.visible, "3: carta fechada acende o selo")

	# 3. Caderninho sem aba Álbum.
	var ids: Array = (notebook.call("tabs") as Array).map(func(t: Dictionary) -> String: return t.id)
	check(not ("album" in ids), "4: o caderninho não tem aba Álbum")

	# 4. O botão abre a tela inteira, sem aba lateral e com a placa "Álbum".
	album.pressed.emit()
	await frames(8)
	var panel := main.find_child("AlbumScreen", true, false)
	check(panel != null, "5: o botão abre AlbumScreen")
	check(main.find_child("PetNotebook", true, false) == null, "5: não é o caderninho")
	check(panel.find_child("CodexTitle", true, false) != null and (panel.find_child("CodexTitle", true, false) as Label).text == "Álbum", "5: placa Álbum")
	check(panel.find_child("AlbumGrid", true, false) != null and panel.find_child("AlbumSummary", true, false) != null, "5: resumo e grade")
	check(panel.find_child("NotebookTab_resources", true, false) == null, "5: sem abas laterais do caderninho")
	var strip := panel.find_child("CodexFilters", true, false) as Control
	check(strip != null, "5: seções como abas")
	var tabs: Array[Button] = []
	for child in strip.get_children():
		if child is Button: tabs.append(child as Button)
	check(tabs.size() == 7, "5: 7 abas (Todas + 6 seções), são %d" % tabs.size())
	check(tabs.size() > 0 and tabs[0].name == "NotebookTab_all" and bool(tabs[0].get_meta("picked")), "5: Todas é a primeira e a padrão")
	var inside_scroll := false
	var up: Node = strip.get_parent()
	while up != null and up != panel:
		if up is ScrollContainer and (up as ScrollContainer).horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED: inside_scroll = true
		up = up.get_parent()
	check(not inside_scroll, "5: abas fora de qualquer rolagem horizontal")
	for tab in tabs:
		check(tab.size.x >= 44.0 and tab.size.y >= 44.0, "5: aba %s com alvo >= 44" % tab.name)
		var caption := tab.find_child("Caption", true, false) as Label
		check(caption != null and caption.text != "" and caption.get_line_count() <= 2, "5: aba %s com nome escrito em até 2 linhas" % tab.name)
	# Todas mostra só as fotos que o jogador tem (sem faltantes) e uma linha de título.
	var shown := 0
	for card in panel.find_children("AlbumCard_*", "Button", true, false): shown += 1
	check(shown == int(state.call("photo_count")), "5: Todas lista só as fotos obtidas (%d de %d)" % [shown, int(state.call("photo_count"))])
	check(panel.find_child("MissingLock", true, false) == null, "5: Todas não mostra faltantes")
	var row := panel.find_child("AlbumTitleRow", true, false) as Control
	check(row != null and row.find_child("AlbumTitle", true, false) != null and row.find_child("SectionCount", true, false) != null and row.find_child("AlbumLevels", true, false) != null, "5: título, contagem e selos na mesma linha")
	check(panel.find_child("AlbumVersions", true, false) == null, "5: sem a segunda linha de versões")
	var board := panel.find_child("CodexBoard", true, false) as Control
	check(board.size.x >= 340.0, "5: a madeira usa a largura toda (%s)" % str(board.size.x))
	check(state.get("progress").stat("open:album") >= 1, "5: abrir conta open:album")
	await _close()
	check(main.find_child("AlbumScreen", true, false) == null, "5: fecha")
	# "Para abrir" só na aba Todas e na seção que tem carta fechada (f_bath está fechada, em "firsts").
	for pair: Array in [["all", true], ["firsts", true], ["tricks", false], ["story", false]]:
		screen.call("open", str(pair[0]))
		await frames(8)
		var has_strip := main.find_child("AlbumSealed", true, false) != null
		check(has_strip == bool(pair[1]), "5: faixa Para abrir na aba %s = %s" % [pair[0], str(pair[1])])
		await _close()
	# Faltante: disquinho "?" sem cadeado nem texto; dica de data sem botão Ir.
	screen.call("open", "dates")
	await frames(8)
	var date_card := main.find_child("AlbumCard_d_month", true, false)
	if date_card == null:
		for card in main.find_children("AlbumCard_*", "Button", true, false):
			if (card as Control).find_child("HintMark", true, false) != null:
				date_card = card
				break
	check(date_card != null and date_card.find_child("HintMark", true, false) is TextureRect and date_card.find_child("MissingLock", true, false) == null, "5: faltante com bolinha de madeira ?")
	(date_card as Button).pressed.emit()
	await frames(6)
	check(main.find_child("PhotoHintPop", true, false) != null and main.find_child("PhotoHintGo", true, false) == null, "5: dica de data sem botão Ir")
	var catcher := main.find_child("PopoverCatcher", true, false)
	if catcher != null: catcher.free()
	await _close()

	# 5. Entradas antigas.
	notebook.call("open", "album:firsts")
	await frames(8)
	check(main.find_child("AlbumScreen", true, false) != null, "6: PetNotebook.open(album:seção) abre a tela do Álbum")
	check(str(load("res://scripts/ui/album_view.gd").get("last_section")) == "firsts", "6: a seção pedida é a mostrada")
	await _close()
	load("res://scripts/ui/places.gd").call("go", {"notebook": "album"})
	await frames(8)
	check(main.find_child("AlbumScreen", true, false) != null, "7: Ir (notebook: album) abre a tela")
	await _close()
	load("res://scripts/ui/house_ui.gd")  # carrega a classe (parse)
	notebook.call("open", "manual")
	await frames(8)
	check(main.find_child("PetNotebook", true, false) != null, "8: o caderninho continua abrindo")
	check(main.find_child("NotebookTab_album", true, false) == null, "8: sem aba Álbum no caderninho")
	await _close()

	# 6. Tutorial: começa na tela nova e fecha a tela ao terminar.
	state.call("reset")
	state.call("mark_seen", ["intro"] as Array[String])
	for timer in main.find_children("*", "Timer", true, false): (timer as Timer).stop()
	main.get("_modal_queue").clear()
	main.get("_photo_queue").clear()
	main.set("_announce_pending", false)
	main.set("_chapter_done", 0)
	main.set("_reward_not_before", 0)
	for key in ["_welcome", "_celebration", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		(main.get(key) as CanvasLayer).hide()
	await frames(6)
	album = pet.find_child("AlbumButton", true, false) as Button
	check(album.visible, "9: botão aparece com a foto da chegada")
	album.pressed.emit()
	await frames(30)
	check(main.find_child("AlbumTutorial", true, false) != null, "9: o tutorial começa ao abrir a tela do Álbum")
	check(main.find_child("AlbumScreen", true, false) != null or main.find_child("CardViewer", true, false) != null, "9: tela ou carta abertas")

	print("ALBUM SCREEN TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
