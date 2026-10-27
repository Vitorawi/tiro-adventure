extends SceneTree
## Capturas e toque emulado da etapa 11 do plano Tiro: a aba Missões com a missão de crescer. NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/story_shots.gd -- --out=tiro11_360x780
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/tiro11/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Capturas da história: " + message)


func shot(shot_name: String, wait: float = 0.6) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


## Marca como recebidos os passos da história até (sem incluir) `stop`, e os marcos de linha que eles representam.
func _claim_until(stop: String) -> void:
	var progress: Object = state.get("progress")
	var quests: Dictionary = root.get_node("Database").get("quests")
	for c in range(1, int(quests[stop].chapter) + 1):
		for id: String in progress.main_quests(c):
			if id == stop:
				break
			progress.claimed_quests[id] = true
			if quests[id].has("shared_with"):
				progress.claimed_quests[str(quests[id].shared_with)] = true
	state.call("_changed")


func _card(shot_name: String, stop: String, phase: String, setup: Callable = Callable()) -> void:
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	_claim_until(stop)
	state.get("growth").phase = phase
	if setup.is_valid():
		setup.call(progress)
	state.call("_mark_all_seen")
	state.set("unlimited_storage", true)
	state.call("_changed")
	main.call("show_screen", &"pet")
	await create_timer(0.3).timeout
	main.call("show_screen", &"tasks")
	await shot(shot_name, 0.9)


func _story_button(text: String) -> Button:
	var card: Node = main.find_child("StoryCard", true, false)
	if card == null:
		return null
	# Os botões de madeira desenham o rótulo num filho: "Ir" = QuestGo_*, "Pegar prêmio" = ClaimQuest_*.
	var prefix := "QuestGo_" if text == "Ir" else "ClaimQuest_"
	for button: Node in card.find_children("*", "Button", true, false):
		if String(button.name).begins_with(prefix):
			return button as Button
	return null


func _click(node: Control) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = root.get_final_transform() * (node.get_global_transform_with_canvas() * (node.size * 0.5))
		root.push_input(event)
	for _i in 12:
		await process_frame


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "story_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	# 1. Capítulo 1: depois da caminha, só falta ele crescer (silhueta + "Ir").
	await _card("01_cap1_crescer", "growth_1_puppy", "newborn", func(p: Object) -> void:
		p.claimed_quests["lais_bed"] = true
		state.get("growth").phase_moments["body"] = 10)
	check(main.find_child("GrowthGoalSilhouette", true, false) != null, "a silhueta do Filhotinho aparece no cartão da história")
	check(_story_button("Ir") != null, "cartão tem Ir")
	# Toque no Ir: abre o painel de crescimento.
	var go: Button = _story_button("Ir")
	if go != null:
		await _click(go)
		check(main.find_child("GrowthPanel", true, false) != null, "Ir abre o painel de crescimento")
		await shot("02_ir_abre_crescimento", 0.8)
		root.get_node("Events").sheet_close_requested.emit()
		await create_timer(0.5).timeout
	# 2. Filhotinho já chegou: o cartão mostra o retrato e o botão de pegar.
	await _card("03_cap1_pronto", "growth_1_puppy", "puppy")
	check(main.find_child("GrowthGoalPhoto", true, false) != null, "fase alcançada mostra o retrato")
	var claim: Button = _story_button("Pegar prêmio")
	check(claim != null, "tem Pegar prêmio")
	# 3. Capítulo 3: a história orienta até a vovó e depois pede os dentinhos.
	await _card("04_cap3_argolinha", "teeth_3_ring", "puppy")
	check(main.find_child("SharedQuestGuidance", true, false) != null, "capítulo 3 orienta a argolinha da vovó")
	await _card("05_cap3_dentinhos", "growth_3_teething", "puppy", func(p: Object) -> void:
		p.claimed_quests["bloblo_chew_ring"] = true)
	# 4. "?" do objetivo de crescimento: o que falta, tocável.
	var task_help: Script = load("res://scripts/ui/task_help.gd")
	task_help.call("open", "growth", "teething", 1)
	await shot("06_como_fazer_dentinhos", 1.0)
	root.get_node("Events").sheet_close_requested.emit()
	await create_timer(0.5).timeout
	# 5. Capítulos 6, 9 e 12.
	await _card("07_cap6_aventureiro", "growth_6_explorer", "teething")
	await _card("08_cap9_mocinho", "growth_9_young", "explorer")
	await _card("09_cap12_azul_dourado", "growth_12_adult", "young")
	print("STORY SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
