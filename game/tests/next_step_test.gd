extends SceneTree
## Interface 2, etapa 03: a pílula do próximo passo (NextStep + QuestGuide) e o rodapé preso. Comportamento e contrato,
## não pixel: estados, toque, entrega uma vez só, linha 2 do HUD que some com folha, modo compacto no Mapa e nomes das abas.

var failures: int = 0
var state: Node
var main: Control


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("NEXT_STEP: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 4:
		await process_frame
	await _footer()
	await _talk_step()
	await _claim_step()
	await _progress_step()
	await _shared_step()
	await _row2_hides()
	await _map_compact()
	await _story_done()
	Motion.reduced = false
	print("NEXT STEP TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _step() -> Control:
	return main.find_child("NextStep", true, false) as Control


func _reset_fresh() -> void:
	# Cartões de comemoração de testes anteriores não podem sobrar na tela.
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]:
		var card: Variant = main.get(member)
		if card is CanvasLayer:
			(card as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	main.set("_chapter_done", 0)
	main.call("show_screen", &"pet")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	root.get_node("Events").emit_signal("state_changed")
	for i in 2:
		await process_frame


## 9. Rodapé: 84 de altura e o nome embaixo de cada aba.
func _footer() -> void:
	var bar := main.get_node("Layout/TabBar") as Control
	check(is_equal_approx(bar.size.y, 84.0), "o rodapé tem 84 px de altura (veio %f)" % bar.size.y)
	check(is_equal_approx(bar.get_global_rect().end.y, main.size.y), "o rodapé fica preso à borda de baixo")
	(main.find_child("BagTab", true, false) as Control).visible = true
	await process_frame
	for pair: Array in [["PetTab", "Tiro"], ["MapTab", "Mapa"], ["TasksTab", "Missões"], ["BagTab", "Mochila"]]:
		var title := main.find_child(pair[0], true, false).find_child("Title", true, false) as Label
		check(title != null and title.text == pair[1] and title.is_visible_in_tree(), "aba %s mostra o nome %s" % [pair[0], pair[1]])
	(main.find_child("BagTab", true, false) as Control).visible = false


## 1 e 2. Save novo: pílula visível no estado `talk`; o cartão leva ao lugar e fecha.
func _talk_step() -> void:
	await _reset_fresh()
	var step: Control = _step()
	var guide: Dictionary = _guide()
	check(step != null and step.visible, "a pílula aparece com a primeira missão")
	check(guide.id == "welcome" and guide.state == "talk", "save novo: welcome em estado talk (veio %s/%s)" % [guide.id, guide.state])
	check((step.find_child("StepCount", true, false) as Label).text == "0/1", "StepCount mostra 0/1")
	var heard: Array = []
	root.get_node("Events").world_requested.connect(func(world: String, place: String) -> void: heard.append([world, place]))
	step.pressed.emit()
	await process_frame
	await process_frame
	var card := main.find_child("StepCard", true, false)
	check(card != null and card.find_child("StepCardGo", true, false) != null and card.find_child("StepCardHelp", true, false) != null, "tocar abre o cartão com Ir e ?")
	var target: Dictionary = load("res://scripts/ui/places.gd").call("quest_target", "welcome")
	(card.find_child("StepCardGo", true, false) as Button).pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	if target.has("world"):
		check(not heard.is_empty() and heard[0][0] == target.world and heard[0][1] == target.get("place", ""), "Ir pede o lugar do passo (%s)" % str(heard))
	else:
		check(not heard.is_empty() or target.has("screen"), "Ir leva ao destino do passo")
	check(main.get_node_or_null("PopoverCatcher") == null, "Ir fecha o cartão")


## 3. Pronto: verde, "Pegar" visível, um toque entrega uma vez.
func _claim_step() -> void:
	await _reset_fresh()
	state.call("talk_to", "lais")
	await process_frame
	await process_frame
	var step: Control = _step()
	check(_guide().state == "ready", "depois de falar com a Laís o passo está pronto")
	check((step.find_child("StepClaim", true, false) as Control).visible, "StepClaim aparece no estado pronto")
	var coins: int = state.get("coins")
	var food: int = state.get("inventory").count("dog_food")
	step.pressed.emit()
	await process_frame
	await process_frame
	check(state.get("progress").claimed_quests.has("welcome"), "tocar na pílula pronta conclui welcome")
	check(int(state.get("coins")) == coins + 5, "as moedas sobem exatamente o prêmio (+5; veio %d)" % (int(state.get("coins")) - coins))
	check(state.get("inventory").count("dog_food") == food + 2, "dog_food +2")
	check(_guide().id == "lais_feed", "a pílula já mostra lais_feed")
	step.pressed.emit()
	await process_frame
	check(int(state.get("coins")) == coins + 5, "tocar de novo não paga de novo")
	var catcher := main.get_node_or_null("PopoverCatcher")
	if catcher:
		catcher.queue_free()
	await process_frame
	await process_frame


## 4. lais_feed anda: 0/1 → 1/1 e fica pronto.
func _progress_step() -> void:
	await _reset_fresh()
	state.call("dev_complete_quest", "welcome")
	state.call("_changed")
	await process_frame
	await process_frame
	var guide: Dictionary = _guide()
	check(guide.id == "lais_feed" and guide.state == "progress" and guide.value == 0, "lais_feed começa em progress 0/1 (veio %s/%s/%s)" % [guide.id, guide.state, guide.value])
	state.get("dog").needs.hunger = 40
	state.call("feed", "dog_food")
	await process_frame
	await process_frame
	guide = _guide()
	check((_step().find_child("StepCount", true, false) as Label).text == "1/1", "StepCount vira 1/1 (veio %s)" % (_step().find_child("StepCount", true, false) as Label).text)
	check(guide.state == "ready", "lais_feed fica pronto")


## 5. História que aponta para personagem: o passo é o da linha dele.
func _shared_step() -> void:
	await _reset_fresh()
	var progress: Object = state.get("progress")
	var done := false
	for chapter in range(1, (root.get_node("Database").progression.chapters.size()) + 1):
		for id: String in progress.main_quests(chapter):
			if id == "lais_meet_bloblo":
				done = true
				break
			state.call("dev_complete_quest", id)
		if done:
			break
	state.call("_changed")
	await process_frame
	await process_frame
	var guide: Dictionary = _guide()
	check(guide.shared, "a história aponta para a linha do personagem (shared)")
	check(guide.id == progress.current_line_quest("bloblo") or guide.id == "bloblo_meet", "o passo é o da linha da Bloblo (veio %s)" % guide.id)
	check(guide.npc == "bloblo", "o retrato é o da Bloblo (veio %s)" % guide.npc)


## 7. A linha 2 some com a folha aberta e volta ao fechar.
func _row2_hides() -> void:
	await _reset_fresh()
	var row2 := main.find_child("HudRow2", true, false) as Control
	check(row2.modulate.a == 1.0, "linha 2 começa visível")
	root.get_node("Events").emit_signal("sheet_requested", "x", Control.new())
	await create_timer(0.35).timeout
	check(row2.modulate.a == 0.0, "folha aberta esconde a linha 2")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.45).timeout
	check(row2.modulate.a == 1.0, "ao fechar a folha a linha 2 volta")
	main.call("set_row2_blocker", "teste", true)
	check(row2.modulate.a == 0.0, "um bloqueio por chave também esconde")
	main.call("set_row2_blocker", "teste", false)
	check(row2.modulate.a == 1.0, "e solta ao remover a chave")


## 8. No Mapa a pílula fica compacta e não cruza a pílula do mundo nem os rostos.
func _map_compact() -> void:
	await _reset_fresh()
	main.call("show_screen", &"map")
	for i in 4:
		await process_frame
	var step: Control = _step()
	check(step.visible and bool(step.get("compact")), "no Mapa a pílula usa o modo compacto")
	var rect := step.get_global_rect()
	var world_pill := main.find_child("MapButton", true, false) as Control
	check(not rect.intersects(world_pill.get_global_rect()), "não cruza a pílula do mundo")
	var faces := main.find_child("NpcRow", true, false) as Control
	if faces.visible:
		check(not rect.intersects(faces.get_global_rect()), "não cruza os rostos dos personagens")
	check(rect.end.x <= main.size.x - 12.0 - 48.0 - 8.0 + 0.5, "termina antes da coluna dos rostos (x = %f)" % rect.end.x)
	main.call("show_screen", &"pet")
	await process_frame
	await process_frame
	check(not bool(step.get("compact")), "fora do Mapa a pílula volta ao tamanho normal")


## 6. História concluída: a pílula some.
func _story_done() -> void:
	await _reset_fresh()
	var progress: Object = state.get("progress")
	for chapter in range(1, (root.get_node("Database").progression.chapters.size()) + 1):
		for id: String in progress.main_quests(chapter):
			state.call("dev_complete_quest", id)
	state.call("_changed")
	await process_frame
	await process_frame
	check(_guide().state == "hidden", "história concluída: estado hidden")
	check(not _step().visible, "história concluída: a pílula some")


func _guide() -> Dictionary:
	return (load("res://scripts/ui/quest_guide.gd") as GDScript).call("current")
