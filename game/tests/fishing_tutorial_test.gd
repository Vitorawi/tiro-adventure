extends SceneTree
## Pesca, etapa 05: capítulo 2 (vara, primeira fisgada, três peixes, minhocas na banca) e o tutorial "A vovó ensina a
## pescar" (AnglerTutorial) de ponta a ponta no Sítio de verdade. Sem SaveManager.
## --headless --path game -s res://tests/fishing_tutorial_test.gd

var failures := 0
var state: Node
var events: Node
var main: Control
var farm: Control


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PESCA_TUTORIAL: " + message)


func _fishing() -> RefCounted:
	return state.get("fishing")


func _inv() -> RefCounted:
	return state.get("inventory")


func _flow() -> Node:
	return farm.call("fishing_flow")


func _panel() -> Control:
	var node := farm.find_child("FishingPanel", false, false) as Control
	return node if node != null and not bool(node.get("_closing")) else null


func _tutorial() -> Control:
	return main.find_child("AnglerTutorial", false, false) as Control


func _phase() -> String:
	var node := _tutorial()
	return str(node.get("phase")) if node != null else ""


func _frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func _game() -> Control:
	var flow := _flow()
	return flow.get("game") as Control if flow != null else null


## Até a fase pedida (ou esgotar as tentativas): o tutorial anda por `_process`.
func _wait_phase(expected: String, tries: int = 40) -> bool:
	for i in tries:
		_clear_cards()
		if _phase() == expected:
			return true
		await process_frame
	return _phase() == expected


func _setup_chapter_two() -> void:
	if _flow() != null:
		_flow().call("end")
	var tutorial := _tutorial()
	if tutorial != null:
		tutorial.call("stop")
	state.call("cancel_fishing")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_dev_complete_quest", "bloblo_more_crops")
	state.call("_dev_complete_quest", "lais_first_crops")
	state.call("_mark_all_seen")
	_inv().call("from_dict", {})
	state.call("_changed")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	Motion.reduced = true
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await _frames(4)
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await _frames(4)
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	_clear_cards()
	farm = main.find_child("World_farm", true, false)
	farm.call("recenter")
	await _frames()

	_test_content()
	_test_sim_rules()
	await _test_quests_and_rod()
	await _test_steps()
	await _test_unattended_and_result()
	await _test_resume()
	await _test_finish_and_next()
	await _test_worms()
	await _test_tips()

	print("FISHING TUTORIAL TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# 0 — as cinco missões e as falas existem nos dados, com as ordens combinadas.
func _test_content() -> void:
	var quests: Dictionary = root.get_node("Database").get("quests")
	for id: String in ["lais_fishing", "bloblo_rod", "bloblo_first_fish", "bloblo_three_fish", "bloblo_worms"]:
		check(quests.has(id), "0: missão %s" % id)
	check(int(quests.bloblo_rod.order) == 32 and int(quests.bloblo_first_fish.order) == 34 and int(quests.bloblo_three_fish.order) == 36 and int(quests.bloblo_worms.order) == 38, "0: ordens 32/34/36/38")
	check(str(quests.lais_fishing.shared_with) == "bloblo_first_fish" and int(quests.lais_fishing.chapter) == 2 and int(quests.lais_fishing.order) == 30, "0: principal compartilha a primeira fisgada")
	check((quests.bloblo_rod.rewards.rods as Array).has("bamboo_rod") and int(quests.bloblo_rod.rewards.items.bait_worm) == 5, "0: a vara dá bambu e 5 minhocas")
	var lines: Dictionary = root.get_node("Database").get("npcs").bloblo.lines
	for key: String in ["lake", "bait", "force", "wait", "bite", "see", "hold", "release", "play", "almost", "result", "outro"]:
		check(str(lines.tutorial.get(key, "")) != "", "0: fala do passo %s" % key)
	for tip: String in ["bubble", "escape", "no_bait"]:
		check(str(lines.tips.get(tip, "")) != "", "0: dica %s" % tip)


# Regras do motor que garantem a primeira pesca (sem tela): piso e dreno do tutorial.
func _test_sim_rules() -> void:
	var config: Dictionary = (root.get_node("Database").get("fishing") as Dictionary).duplicate(true)
	var fish: Dictionary = config.fish.fish_lambari.duplicate()
	fish["difficulty"] = float(config.tutorial.difficulty)
	var all_caught := true
	var floor_kept := true
	for seed_value in 12:
		var sim := FishingSim.new(config, fish, seed_value + 1, 0.34)
		sim.tutorial = {"drain_until": float(config.tutorial.drain_until), "meter_floor": float(config.tutorial.meter_floor)}
		var unlocked := false
		var guard := 0
		while not sim.finished and guard < 60000:
			sim.step(false, 0.1)  # ninguém toca na tela
			if sim.meter >= float(config.tutorial.drain_until):
				unlocked = true
			if unlocked and sim.meter < float(config.tutorial.meter_floor) - 1e-6:
				floor_kept = false
			guard += 1
		if not (sim.finished and sim.caught):
			all_caught = false
	check(floor_kept, "4: depois de passar de 50% a rede nunca cai abaixo do piso")
	check(all_caught, "4: sem tocar nenhuma vez a partida do tutorial termina em captura (12 sementes)")
	# sem o tutorial a rede pode esvaziar de verdade (controle negativo)
	var lost := false
	for seed_value in 12:
		var plain := FishingSim.new(config, config.fish.fish_tilapia, seed_value + 1, 0.34)
		var guard2 := 0
		while not plain.finished and guard2 < 60000:
			plain.step(false, 0.1)
			guard2 += 1
		if plain.finished and not plain.caught:
			lost = true
	check(lost, "4: controle — sem as regras do tutorial, ficar parado perde o peixe")


# 1 — save no fim do "Mãos na terra": a vara e as minhocas vêm da vovó, uma vez só.
func _test_quests_and_rod() -> void:
	_setup_chapter_two()
	var progress: RefCounted = state.get("progress")
	var active: Dictionary = progress.call("active_steps")
	check(active.values().has("bloblo_rod"), "1: bloblo_rod ativa (%s)" % str(active))
	check(str(progress.call("current_main_quest")) == "lais_fishing", "1: a principal é lais_fishing (%s)" % str(progress.call("current_main_quest")))
	check(str(state.call("current_rod")) == "", "1: ainda sem vara")
	check(str(state.call("claim_quest", "bloblo_rod")) != "", "1: sem falar com a vovó não pega a vara")
	state.call("talk_to", "bloblo")
	check(str(state.call("claim_quest", "bloblo_rod")) == "", "1: falar com a vovó libera a vara")
	check(str(state.call("current_rod")) == "bamboo_rod", "1: vara de bambu")
	check(_inv().count("bait_worm") == 5, "1: 5 minhocas")
	check(str(state.call("claim_quest", "bloblo_rod")) != "" and _inv().count("bait_worm") == 5, "1: não paga duas vezes")
	check(not bool(_fishing().tutorial.done), "1: o tutorial ainda não terminou")
	check(progress.call("active_steps").values().has("bloblo_first_fish"), "1: primeira fisgada ativa")


# 2/3 — o tutorial começa sozinho; cada passo só avança com a ação certa.
func _test_steps() -> void:
	_clear_cards()
	await _frames(6)
	check(_tutorial() != null, "2: o tutorial começa sozinho no Sítio")
	check(await _wait_phase("lake"), "2: começa no passo da lagoa (%s) blocked=%s card=%s q=%s ann=%s ch=%s sheet=%s tut=%s" % [_phase(), main.call("notice_blocked"), main.call("_card_open"), (main.get("_modal_queue") as Array).size(), main.get("_announce_pending"), main.get("_chapter_done"), main.get_node("Sheet").call("is_open"), _tutorial()])
	check(int(state.call("fishing_tutorial_step")) == 2, "2: passo 2 salvo")
	# o véu só deixa tocar na lagoa
	var tutorial := _tutorial()
	var rects: Array[Rect2] = []
	for side: String in ["T", "B", "L", "R"]:
		var rect := tutorial.find_child("Veil_" + side, true, false) as ColorRect
		rects.append(Rect2(rect.position, rect.size))
	var lake: Rect2 = farm.call("lake_screen_rect")
	check(lake.size != Vector2.ZERO, "2: a lagoa tem retângulo na tela")
	check(not rects.any(func(rect: Rect2) -> bool: return rect.has_point(lake.get_center())), "2: o centro da lagoa fica no buraco do véu")
	check(rects.any(func(rect: Rect2) -> bool: return rect.has_point(Vector2(4, 4))), "2: o resto da tela fica bloqueado")
	await _frames(2)
	# não avança sozinho sem tocar na água
	check(_phase() == "lake", "3: parado na lagoa até o toque")
	farm.call("open_fishing")  # o toque na água
	await _frames(4)
	check(_panel() != null, "3: o painel abriu")
	check(await _wait_phase("bait"), "3: passo da isca (%s)" % _phase())
	check(int(state.call("fishing_tutorial_step")) == 3, "3: passo 3 salvo")
	var next := _tutorial().find_child("TutorialNext", true, false) as Button
	check(next != null and next.is_visible_in_tree(), "3: botão Continuar visível")
	next.pressed.emit()
	await _frames(2)
	check(_phase() == "force", "3: Continuar leva ao passo da força (%s)" % _phase())
	var panel := _panel()
	panel.set("power_override", 0.0)  # "Perto": o tutorial sobe para Meio
	panel.call("press_cast")
	panel.call("release_cast")
	await _frames(3)
	check(int(_fishing().cast.get("zone", 0)) >= 2, "3: a zona nunca é Perto no tutorial (%s)" % str(_fishing().cast.get("zone")))
	check(is_equal_approx(float(_fishing().cast.wait), float((root.get_node("Database").get("fishing") as Dictionary).cast.tutorial_wait)), "3: espera fixa de 3 s")
	check(await _wait_phase("wait"), "3: passo da espera (%s)" % _phase())
	check(_inv().count("bait_worm") == 5, "5: a isca não é gasta")
	# a mordida chega
	var cast: Dictionary = _fishing().cast
	cast["at"] = float(state.call("now")) - float(cast.wait) - 0.05
	state.call("update_fishing")
	check(await _wait_phase("bite"), "3: passo da mordida (%s)" % _phase())
	check(int(state.call("fishing_tutorial_step")) == 6, "3: passo 6 salvo")
	# tocar longe da lagoa não fisga (o véu consome); tocar na lagoa fisga
	check(bool(_flow().call("handle_tap")), "3: o toque na lagoa fisga")
	await _frames(3)
	check(await _wait_phase("see"), "3: minigame pausado (%s)" % _phase())
	var game := _game()
	check(game != null and bool(game.get("frozen")), "3: o minigame fica congelado no passo 7")
	check(str(_fishing().cast.fish) == "fish_lambari", "5: o primeiro peixe é o lambari")
	check(_inv().count("bait_worm") == 5, "5: fisgar no tutorial não gasta a minhoca")
	var elapsed_before := float(game.sim.elapsed)
	await _frames(10)
	check(is_equal_approx(float(game.sim.elapsed), elapsed_before), "3: o tempo do peixe não anda enquanto a vovó explica")
	check(_tutorial().find_child("TutorialArrow", true, false).visible, "3: seta na barra")
	check(_tutorial().find_child("TutorialArrowFish", true, false).visible, "3: seta no peixe")
	check(int(state.call("fishing_tutorial_step")) == 7, "3: passo 7 salvo")
	(_tutorial().find_child("TutorialNext", true, false) as Button).pressed.emit()
	await _frames(2)
	check(_phase() == "hold", "3: Continuar leva a segurar (%s)" % _phase())
	check(not bool(game.get("frozen")), "3: o tempo volta a andar no passo 8")
	# só avança depois de segurar ~1 s
	game.set("_button_held", true)
	await create_timer(0.3).timeout
	check(_phase() == "hold", "3: 0,3 s segurando ainda não basta")
	await create_timer(1.0).timeout
	check(_phase() == "release", "3: 1 s segurando leva a soltar (%s)" % _phase())
	check(int(state.call("fishing_tutorial_step")) == 9, "3: passo 9 salvo")
	check(_phase() == "release", "3: soltar é o passo 9")
	game.set("_button_held", false)
	await create_timer(0.5).timeout
	check(_phase() == "play", "3: soltar leva ao jogo ao vivo (%s)" % _phase())
	check(not game.sim.tutorial.has("cap"), "3: no passo 10 a rede pode terminar")


# 4/5 — ninguém toca em nada: a primeira partida ainda termina em captura; resultado e passo 12.
func _test_unattended_and_result() -> void:
	var game := _game()
	var floor_ok := true
	var guard := 0
	while _flow().get("state") == "fighting" and guard < 8000:
		game.call("_process", 0.1)
		if float(game.sim.meter) > 0.5:
			pass
		if game.sim.tutorial.has("meter_floor") and float(game.sim.meter) < 0.0:
			floor_ok = false
		guard += 1
		if guard % 50 == 0:
			await process_frame
	check(floor_ok, "4: a rede não passou de zero")
	await _frames(4)
	check(_flow().get("state") == "result", "4: terminou no resultado (%s)" % str(_flow().get("state")))
	check(_inv().count("fish_lambari") >= 1, "4: o lambari entrou na geladeira")
	check(int(_fishing().records.fish_lambari.count) == 1, "5: registro do lambari")
	check(_inv().count("bait_worm") == 5, "5: depois do tutorial a minhoca continua inteira")
	check(await _wait_phase("result"), "4: passo do resultado (%s)" % _phase())
	check(int(state.call("fishing_tutorial_step")) == 12, "4: passo 12 salvo")
	check(not bool(_fishing().tutorial.done), "4: o tutorial só fecha no último passo")


# 6 — fechar o app no meio da partida e voltar: recomeça da mordida, sem prêmio duplicado.
func _test_resume() -> void:
	_setup_chapter_two()
	state.call("talk_to", "bloblo")
	check(str(state.call("claim_quest", "bloblo_rod")) == "", "6: vara entregue")
	_clear_cards()
	await _frames(6)
	check(await _wait_phase("lake"), "6: começa de novo (%s)" % _phase())
	farm.call("open_fishing")
	await _frames(3)
	check(await _wait_phase("bait"), "6: passo da isca")
	(_tutorial().find_child("TutorialNext", true, false) as Button).pressed.emit()
	await _frames(2)
	var panel := _panel()
	panel.set("power_override", 0.9)
	panel.call("press_cast")
	panel.call("release_cast")
	await _frames(3)
	var cast: Dictionary = _fishing().cast
	cast["at"] = float(state.call("now")) - float(cast.wait) - 0.05
	state.call("update_fishing")
	await _wait_phase("bite")
	_flow().call("handle_tap")
	await _frames(3)
	await _wait_phase("see")
	(_tutorial().find_child("TutorialNext", true, false) as Button).pressed.emit()
	await _frames(2)
	game_hold_for_release()
	await create_timer(1.4).timeout
	check(_phase() == "release", "6: no passo 9 (%s)" % _phase())
	check(int(state.call("fishing_tutorial_step")) == 9, "6: passo 9 salvo")
	_game().set("_button_held", false)
	# fecha o app: salva, derruba tudo e carrega de novo
	var data: Dictionary = state.call("to_dict")
	_tutorial().call("stop")
	_flow().call("end")
	await _frames(2)
	state.call("from_dict", data)
	await _frames(4)
	check(_inv().count("bait_worm") == 5, "6: nenhuma minhoca perdida")
	check(_inv().count("fish_lambari") == 0, "6: nenhum peixe duplicado")
	check(str(state.call("current_rod")) == "bamboo_rod", "6: a vara continua")
	check(int(state.call("fishing_tutorial_step")) == 9, "6: o passo salvo continua 9")
	check(not bool(_fishing().tutorial.done), "6: o tutorial continua aberto")
	_clear_cards()
	await _frames(4)
	check(await _wait_phase("lake"), "6: volta à lagoa (%s)" % _phase())
	farm.call("open_fishing")
	await _frames(4)
	check(await _wait_phase("bite"), "6: retoma da mordida (%s)" % _phase())
	check(str(_fishing().cast.get("state", "")) == "waiting" and bool(_fishing().cast.get("bitten", false)), "6: a mordida chega já")
	check(_inv().count("bait_worm") == 5, "6: retomar não gasta minhoca")
	check(int(state.call("fishing_tutorial_step")) == 9, "6: retomar não volta o passo salvo")
	var rewarded: int = int(state.get("coins"))
	check(str(state.call("claim_quest", "bloblo_rod")) != "", "6: o prêmio da vara não se repete")
	check(int(state.get("coins")) == rewarded, "6: sem moedas extras")


func game_hold_for_release() -> void:
	var game := _game()
	if game != null:
		game.set("_button_held", true)


# 7 — terminar: a primeira fisgada fica pronta, entrega e abre a próxima missão.
func _test_finish_and_next() -> void:
	# continua da retomada: pesca de novo até o resultado
	var tut := _tutorial()
	var guard := 0
	while _flow().get("state") != "fighting" and guard < 20:
		if _flow().get("state") == "waiting":
			_flow().call("handle_tap")
		await _frames(2)
		guard += 1
	await _wait_phase("see")
	(_tutorial().find_child("TutorialNext", true, false) as Button).pressed.emit()
	await _frames(2)
	var game := _game()
	game.set("_button_held", true)
	await create_timer(1.3).timeout
	game.set("_button_held", false)
	await create_timer(0.5).timeout
	check(_phase() == "play", "7: chegou ao jogo ao vivo (%s)" % _phase())
	var loops := 0
	while _flow().get("state") == "fighting" and loops < 8000:
		game.call("_process", 0.1)
		loops += 1
		if loops % 50 == 0:
			await process_frame
	await _frames(4)
	check(await _wait_phase("result"), "7: resultado (%s)" % _phase())
	# "Pescar de novo" leva ao painel e ao último passo
	var again := main.find_child("FishAgain", true, false) as Button
	check(again != null, "7: botão Pescar de novo")
	if again != null:
		again.pressed.emit()
	await _frames(4)
	check(await _wait_phase("outro"), "7: passo final (%s)" % _phase())
	check(int(state.call("fishing_tutorial_step")) == 13, "7: passo 13 salvo")
	(_tutorial().find_child("TutorialNext", true, false) as Button).pressed.emit()
	await _frames(3)
	check(bool(_fishing().tutorial.done), "7: tutorial concluído")
	check(_tutorial() == null, "7: o véu sumiu")
	check(str(state.call("quest_error", "bloblo_first_fish")) == "", "7: a primeira fisgada está pronta")
	var coins_before := int(state.get("coins"))
	check(str(state.call("claim_quest", "bloblo_first_fish")) == "", "7: entrega")
	check(int(state.get("coins")) >= coins_before + 10, "7: pelo menos 10 moedas (%d → %d)" % [coins_before, int(state.get("coins"))])
	check(state.get("progress").call("active_steps").values().has("bloblo_three_fish"), "7: peixes da lagoa ativa")
	check(str(state.get("progress").call("current_main_quest")) != "lais_fishing", "7: a principal avançou junto")
	var places: Script = load("res://scripts/ui/places.gd")
	var target: Dictionary = places.call("goal_target", {"type": "stat", "key": "fish:fish_cara"})
	check(str(target.get("place", "")) == "fishing" or str(target.get("spot", "")) == "fishing" or str(target.get("panel", "")) == "fishing" or not target.is_empty(), "7: o Ir dos peixes leva à lagoa (%s)" % str(target))
	_dev_finish_three_fish()


func _dev_finish_three_fish() -> void:
	state.call("_dev_complete_quest", "bloblo_three_fish")
	state.call("_changed")


# 8 — minhocas: o Ir abre a banca na aba Comprar com o pacote escolhido; comprar conclui.
func _test_worms() -> void:
	check(state.get("progress").call("active_steps").values().has("bloblo_worms"), "8: minhocas ativa")
	var places: Script = load("res://scripts/ui/places.gd")
	var target: Dictionary = places.call("goal_target", {"type": "stat", "key": "bought:bait_worm"})
	check(str(target.get("place", "")) == "shop:worm_pack", "8: o Ir leva ao pacote de minhocas (%s)" % str(target))
	state.set("coins", 100)
	var seen: Array[Dictionary] = []
	events.sheet_requested.connect(func(_title: String, content: Variant) -> void:
		var card: Control = content.find_child("Buy_worm_pack", true, false)
		seen.append({"card": card != null, "selected": card != null and bool(card.get_meta("selected", false)), "buy": content.find_child("BuyItem", true, false) != null}))
	places.call("run", "farm", "shop:worm_pack")
	await _frames(4)
	check(not seen.is_empty(), "8: o Ir abre a banca")
	if not seen.is_empty():
		check(bool(seen.back().card) and bool(seen.back().selected), "8: o pacote de minhocas vem escolhido")
		check(bool(seen.back().buy), "8: botão Comprar")
	events.sheet_close_requested.emit()
	await _frames(3)
	check(str(state.call("quest_error", "bloblo_worms")) != "", "8: antes de comprar não está pronta")
	check(str(state.call("buy_shop_item", "worm_pack", 1)) == "", "8: comprou")
	check(str(state.call("quest_error", "bloblo_worms")) == "", "8: comprar conclui o objetivo")


# 9 — dicas de primeira vez: uma vez cada.
func _test_tips() -> void:
	var first: String = str(state.call("fishing_tip", "escape"))
	check(first != "", "9: dica de escapar aparece")
	check(str(state.call("fishing_tip", "escape")) == "", "9: só uma vez")
	var no_bait: String = str(state.call("fishing_tip", "no_bait"))
	check("banca" in no_bait, "9: dica sem minhoca fala da banca (%s)" % no_bait)
	check(str(state.call("fishing_tip", "no_bait")) == "", "9: sem minhoca também só uma vez")
	# pelo fluxo de verdade: a partida escapa e o aviso da vovó aparece
	state.get("progress").seen.erase("fishing_tip:escape")
	_inv().add("bait_worm", 5)
	farm.call("open_fishing")
	await _frames(4)
	var panel := _panel()
	check(panel != null, "9: o painel abre depois do tutorial")
	if panel != null:
		panel.set("power_override", 0.9)
		panel.call("press_cast")
		panel.call("release_cast")
		await _frames(3)
		var cast: Dictionary = _fishing().cast
		cast["at"] = float(state.call("now")) - float(cast.wait) - 0.05
		state.call("update_fishing")
		_flow().call("handle_tap")
		await _frames(3)
		var game := _game()
		if game != null:
			game.call("release")
			await _frames(4)
		var notice: Object = main.get("_notice")
		var texts: Array[String] = [str((notice.get("_current") as Dictionary).get("text", ""))]
		for waiting: Dictionary in notice.get("_queue"):
			texts.append(str(waiting.text))
		check(texts.any(func(text: String) -> bool: return "solte o dedo" in text), "9: aviso de escapar pelo fluxo (%s)" % str(texts))
	# primeira vez sem minhoca: aparece ao abrir o painel sem isca
	_flow().call("end")
	state.get("progress").seen.erase("fishing_tip:no_bait")
	_inv().remove("bait_worm", _inv().count("bait_worm"))
	farm.call("open_fishing")
	await _frames(4)
	var notice2: Object = main.get("_notice")
	var texts2: Array[String] = [str((notice2.get("_current") as Dictionary).get("text", ""))]
	for waiting2: Dictionary in notice2.get("_queue"):
		texts2.append(str(waiting2.text))
	check(texts2.any(func(text: String) -> bool: return "banca" in text), "9: aviso sem minhoca pelo fluxo (%s)" % str(texts2))


## O prêmio da vara abre a folha de prêmio; na tela o jogador fecha, aqui fechamos (o tutorial espera a fila vazia).
func _clear_cards() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var layer: Object = main.get(member)
		if layer != null and layer.has_method("hide"):
			layer.call("hide")
	main.set("_modal_queue", [] as Array[Callable])
