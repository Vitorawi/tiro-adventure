extends SceneTree
## Etapa 05: fila real, abertura única, resultado, recuperação e ações na mesma carta.
var failures := 0
var state: Node
var main: Control
var viewer_script: GDScript
var reveal_script: GDScript
var results: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: print("CARD REVEAL TEST: TIMEOUT"); quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Revelação: " + message)

func _viewer() -> Control:
	return viewer_script.get("current") as Control

func _clear_queue() -> void:
	main.get("_modal_queue").clear()
	main.get("_photo_queue").clear()
	main.set("_announce_pending", false)
	main.set("_chapter_done", 0)
	main.set("_reward_not_before", 0)
	for key in ["_welcome", "_celebration", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		(main.get(key) as CanvasLayer).hide()

func _close() -> void:
	if viewer_script.call("is_open"): _viewer().call("close")
	await process_frame

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_reset_album()
	viewer_script = load("res://scripts/ui/card_viewer.gd")
	reveal_script = load("res://scripts/ui/card_reveal.gd")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	for timer in main.find_children("*", "Timer", true, false): timer.stop()
	_clear_queue()
	root.get_node("Events").photo_rolled.connect(func(_id: String, result: Dictionary) -> void: results.append(result))
	# 1. Antes de conhecer o álbum fica fechada, depois um evento enfileira uma vez.
	state.dev_seal_photo("h_arrival")
	check(main.get("_photo_queue").is_empty(), "foto anterior ao álbum não abre sozinha")
	state.note_screen_opened("album")
	state.dev_seal_photo("f_bath")
	main.call("_queue_photo", "f_bath")
	check(main.get("_photo_queue").size() == 1 and main.get("_modal_queue").size() == 1, "photo_taken enfileira uma vez")
	var priority: Array[bool] = []
	main.call("_queue_modal", func() -> void: priority.append(true))
	main.call("_flush_modals")
	check(priority.size() == 1 and not viewer_script.call("is_open"), "prêmio anunciado depois ainda precede a foto")
	main.call("_flush_modals")
	var card := _viewer()
	await process_frame
	check(card != null and card.find_child("CardBack", true, false) != null, "fila abre o verso")
	check(state.photo_sealed("f_bath") == 1 and results.is_empty(), "não consome nem sorteia antes do Abrir")
	# 2. Dois toques na mesma abertura: uma transação e resultado fiel.
	var controller := card.get_node("CardReveal")
	controller.call("_open_card")
	controller.call("_open_card")
	check(results.size() == 1 and state.photo_sealed("f_bath") == 0, "Abrir chama o motor uma vez")
	var rolled := int(results[-1].rolled)
	await create_timer(1.5).timeout
	check(_viewer() == card and not card.get("revealing"), "entrega ao MESMO visualizador em menos de 3 s")
	check(int(card.get("level")) == rolled and int(card.find_child("RevealSeal", true, false).get_meta("level")) == rolled, "carta e RevealSeal mostram nível devolvido")
	await _close()
	# 3. Menos animação é direto, efeito parado.
	Motion.reduced = true
	card = reveal_script.call("open", "h_arrival", {"host": root})
	card.get_node("CardReveal").call("_open_card")
	check(not card.get("revealing") and float(card.call("surface_material").get_shader_parameter("spin")) == 0.0, "Menos animação sem virar nem revelar")
	check(card.find_child("CardBack", true, false) == null, "resultado direto")
	await _close()
	# 4. Duas fotos na fila: nenhuma sobreposta, mesmo com a primeira já entregue.
	_clear_queue()
	state.dev_seal_photo("f_taste")
	state.dev_seal_photo("f_dig")
	main.call("_flush_modals")
	card = _viewer()
	check(main.get("_photo_queue").size() == 1, "primeira de duas saiu da fila")
	card.get_node("CardReveal").call("_open_card")
	main.call("_flush_modals")
	check(_viewer() == card and main.get("_photo_queue").size() == 1, "segunda aguarda fechar o visualizador")
	await _close()
	main.call("_flush_modals")
	check(_viewer() != null and _viewer().get("photo_id") == "f_dig", "segunda revelação vem depois")
	await _close()
	# 5. Fecha em plena animação, roundtrip do save e reabre sem sorteio.
	Motion.reduced = false
	card = reveal_script.call("open", "f_dig", {"host": root})
	card.get_node("CardReveal").call("_open_card")
	var count := results.size()
	var saved: Dictionary = state.to_dict().duplicate(true)
	await _close()
	state.from_dict(saved)
	card = reveal_script.call("open", "f_dig", {"host": root})
	check(not card.get("revealing") and state.photo_sealed("f_dig") == 0 and results.size() == count, "reabrir após save não sorteia nem perde resultado")
	await _close()
	# 6. Tentar a sorte e repetida: sinal real do motor; sem perder a carta.
	state.dev_take_photo("h_arrival", 1)
	state.coins = 1000
	state.album.tutorial = {"step": 3, "done": false}
	card = viewer_script.call("open", "h_arrival", {"host": root})
	card.call("_reroll")
	check(card.get("revealing"), "Tentar a sorte inicia sequência")
	await create_timer(1.8).timeout
	check(int(card.get("level")) == 2 and _viewer() == card, "Tentar a sorte termina na versão nova")
	var previous := int(card.get("level"))
	card.call("_reroll")
	await process_frame
	check(card.find_child("RevealResult", true, false).text == "Você já tinha esta versão", "repetida explica o resultado")
	await create_timer(1.8).timeout
	check(int(card.get("level")) == previous, "repetida mantém a carta")
	await _close()
	_clear_queue()
	# photo_sealed usa a mesma fila; boas-vindas conta cartas e abre a primeira.
	state.dev_seal_photo("f_bath")
	check(main.get("_photo_queue").size() == 1, "photo_sealed também enfileira")
	var lines: Array = state.welcome_ready_lines()
	var photo_line: Dictionary = {}
	for line: Dictionary in lines:
		if str(line.kind) == "photo": photo_line = line
	check(not photo_line.is_empty(), "boas-vindas oferece cartas fechadas")
	if not photo_line.is_empty():
		var total := 0
		for id: String in state.sealed_photos(): total += int(state.photo_sealed(id))
		check(int(photo_line.count) == total, "boas-vindas conta cartas, incluindo múltiplas da mesma foto")
		var welcome: Node = main.get("_welcome")
		var row: Dictionary = welcome.call("_line_row", photo_line)
		check("para abrir" in str(row.title), "Line_photo diz fotos para abrir")
		row.go.call()
		check(viewer_script.call("is_open") and _viewer().get("photo_id") == state.sealed_photos()[0], "Ir abre a primeira carta fechada")
		await _close()
	_clear_queue()
	main.queue_free()
	print("CARD REVEAL TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
