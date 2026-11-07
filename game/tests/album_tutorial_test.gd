extends SceneTree
## Etapa 09 das fotos: tutorial da carta da chegada de ponta a ponta (passos, só o alvo recebe toque, retomada, fim).
var failures := 0
var state: Node
var main: Control
var tutorial_script: GDScript
var viewer_script: GDScript
var rolls: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: print("ALBUM TUTORIAL TEST: TIMEOUT"); quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Tutorial do álbum: " + message)

func _viewer() -> Control:
	return viewer_script.get("current") as Control

func _tut() -> Control:
	return tutorial_script.get("current") as Control

func _clear_queue() -> void:
	main.get("_modal_queue").clear()
	main.get("_photo_queue").clear()
	main.set("_announce_pending", false)
	main.set("_chapter_done", 0)
	main.set("_reward_not_before", 0)
	for key in ["_welcome", "_celebration", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		(main.get(key) as CanvasLayer).hide()

func _frames(count: int) -> void:
	for i in count:
		await process_frame

func _wait_phase(phase: String, seconds: float = 4.0) -> bool:
	var left := seconds
	while left > 0.0:
		var node := _tut()
		if node != null and str(node.get("phase")) == phase: return true
		await create_timer(0.1).timeout
		left -= 0.1
	return false

## Um toque (pressionar + soltar) numa posição da tela, entregue como a casca entrega.
func _tap(pos: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = pos
		event.global_position = pos
		root.push_input(event, true)
		await process_frame

func _open_album() -> void:
	load("res://scripts/ui/pet_notebook.gd").call("open", "album")
	await _frames(3)

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_reset_album()
	tutorial_script = load("res://scripts/ui/album_tutorial.gd")
	viewer_script = load("res://scripts/ui/card_viewer.gd")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _frames(2)
	for timer in main.find_children("*", "Timer", true, false): timer.stop()
	_clear_queue()
	root.get_node("Events").photo_rolled.connect(func(_id: String, result: Dictionary) -> void: rolls.append(result))
	# 1. Save novo: a intro tira a foto da chegada, fechada; lais_play pronta destrava a missão do Álbum.
	var intro: Array[String] = ["intro"]
	state.mark_seen(intro)
	check(state.album.has_photo("h_arrival") and state.photo_sealed("h_arrival") == 1, "a foto da chegada existe fechada")
	state.progress.claimed_quests.lais_play = true
	state.coins = 777
	var coins_before: int = state.coins
	var wood_before: int = state.inventory.count("wood")
	check(state.album_tutorial_step() == 0, "tutorial ainda não começou")
	await _frames(2)
	_clear_queue()
	await _open_album()
	check(await _wait_phase("open"), "abrir o Álbum inicia o tutorial no passo 1")
	check(state.album_tutorial_step() == 1, "passo 1 salvo")
	check(viewer_script.call("is_open") and _viewer().get("photo_id") == "h_arrival", "carta fechada em destaque")
	var tut := _tut()
	check(tut.find_child("TutorialBalloon", true, false) != null and tut.find_child("NpcPortrait", true, false) != null, "balão da Laís com retrato")
	# 3. Só o alvo recebe toque: tocar fora não abre nem fecha.
	var hole: Rect2 = tut.call("target_rect")
	await _tap(Vector2(8, 300))
	check(viewer_script.call("is_open") and state.photo_sealed("h_arrival") == 1 and rolls.is_empty(), "tocar fora não avança nem fecha")
	await _tap(hole.get_center())
	# 2. Abrir dá Comum.
	check(rolls.size() == 1 and int(rolls[0].rolled) == 1 and rolls[0].kind == "tutorial", "Abrir dá Comum")
	check(await _wait_phase("reroll", 5.0), "depois da revelação vai para Tentar a sorte")
	check(state.album_tutorial_step() == 3, "passo 3 salvo")
	check(state.coins == coins_before and state.album.pity_rare == 0, "abrir não mexe em moedas nem garantias")
	# 4. Fechar no passo 3 e reabrir o Álbum retoma no passo 3.
	_viewer().call("close")
	await _frames(3)
	check(_tut() == null and state.album_tutorial_step() == 3, "sair deixa o passo salvo")
	await _open_album()
	check(await _wait_phase("reroll"), "reabrir o Álbum retoma no passo 3")
	hole = _tut().call("target_rect")
	check(hole.size.x >= 44.0 and hole.size.y >= 44.0, "alvo com pelo menos 44 px")
	await _tap(Vector2(8, 300))
	check(rolls.size() == 1, "tocar fora no passo 3 não rola")
	await _tap(hole.get_center())
	check(rolls.size() == 2 and int(rolls[1].rolled) == 2, "Tentar a sorte grátis dá Brilhante")
	check(state.coins == coins_before and int(state.album.photos.h_arrival.rerolls) == 0, "grátis: sem cobrar nem encarecer")
	check(await _wait_phase("upgrade", 5.0), "passo 4: Melhorar")
	hole = _tut().call("target_rect")
	await _tap(hole.get_center())
	check(rolls.size() == 3 and int(rolls[2].rolled) == 3 and state.photo_rarity("h_arrival") == 3, "Melhorar dá Rara")
	check(state.coins == coins_before and state.inventory.count("wood") == wood_before, "Melhorar de presente não gasta nada")
	check(await _wait_phase("tilt", 5.0), "passo 5: inclinar")
	# Arrastar a carta avança para escolher a versão.
	var card := _viewer()
	card.call("touch_down", card.call("card_rect").get_center())
	card.call("touch_move", card.call("card_rect").get_center() + Vector2(90, 0))
	await _frames(2)
	card.call("touch_up", card.call("card_rect").get_center() + Vector2(90, 0))
	check(await _wait_phase("version", 2.0), "arrastar ≥ 60 px avança")
	var version := card.find_child("Version_1", true, false) as Control
	await _tap(version.get_global_rect().get_center())
	check(await _wait_phase("feature", 3.0), "tocar numa versão avança")
	check(state.album_tutorial_step() == 6, "passo 6 salvo")
	hole = _tut().call("target_rect")
	await _tap(Vector2(8, 300))
	check("h_arrival" not in state.album.featured, "tocar fora não põe no varal")
	await _tap(hole.get_center())
	await create_timer(1.3).timeout
	# 5. Fim.
	check(state.album_tutorial_done() and "h_arrival" in state.album.featured, "tutorial concluído e foto no varal")
	check(state.quest_error("lais_album") == "", "missão lais_album cumprida")
	check(_tut() == null and not viewer_script.call("is_open"), "camada e visualizador fecham")
	check(state.coins == coins_before, "moedas intactas no fim")
	# 6. Depois do fim, nada é forçado.
	state.dev_seal_photo("f_bath")
	check(state._tutorial_level("h_arrival", "reroll") == 0 and state._tutorial_level("f_bath", "open") == 0, "nada forçado depois do tutorial")
	check(state.open_photo_card("f_bath") == "" and rolls[-1].kind == "open", "abrir outra carta sorteia normal")
	# Foto da chegada aberta fora do tutorial: não há o que ensinar.
	state.reset()
	state.mark_seen(intro)
	check(state.open_photo_card("h_arrival") == "" and int(rolls[-1].rolled) == 1 and rolls[-1].kind == "tutorial", "abrir a chegada fora da tela conta como passo 1")
	print("ALBUM TUTORIAL TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
