extends SceneTree
## Capturas 360×780 sem SaveManager; somente arquivos isolados em build/.
var state: Node
var db: Node
var main: Node
var events: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	events = root.get_node("Events")
	state.call("reset")
	var p: RefCounted = state.get("progress")
	for id: String in db.get("quests"):
		if id not in ["nina_pipoca", "nina_trick", "nina_friends", "nina_roll"]:
			p.claimed_quests[id] = true
	p.seen.intro = true
	p.seen["npc_intro:nina"] = true
	state.call("_changed")
	state.call("_mark_all_seen")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.call("_on_world_requested", "park", "")
	await shot("01_praca_antes")
	p.claimed_quests.nina_pipoca = true
	state.call("_changed")
	state.call("_mark_all_seen")
	main.get("_celebration").hide()
	main.get("_modal_queue").clear()
	main.call("_on_world_requested", "park", "look:training")
	await shot("02_treino_mapa")
	state.get("dog").affection = 0
	var ui: Script = load("res://scripts/ui/trick_ui.gd")
	load("res://scripts/ui/places.gd").call("open", "park", "training")
	await shot("03_lista_bloqueados")
	var scroll: ScrollContainer = main.find_child("Sheet").get_node("Panel/VBox/Scroll")
	scroll.scroll_vertical = 10000
	await shot("04_lista_fim")
	for id: String in ["yellow_bow", "red_scarf", "rain_coat"]:
		p.collection[id] = true
		state.call("equip", id)
	ui.call("start", "paw")
	await process_frame
	var training: Node = main.find_child("TrickTraining", true, false)
	training.get("_motion").pause()
	training.call("dev_force_marker", training.get("zone_center"))
	await shot("05_barra_zona")
	training.call("dev_force_marker", 0.0)
	training.call("attempt")
	await shot("06_quase")
	await create_timer(0.8).timeout
	for i in 3:
		training.call("dev_force_marker", training.get("zone_center"))
		var button: Button = training.get("_button")
		for pressed: bool in [true, false]:
			var tap := InputEventMouseButton.new()
			tap.button_index = MOUSE_BUTTON_LEFT
			tap.pressed = pressed
			tap.position = button.global_position + button.size * 0.5
			root.push_input(tap)
		await process_frame
		if int(training.get("hits")) != i + 1:
			push_error("Toque Agora não registrou acerto")
			quit(1)
			return
		if i == 0:
			await shot("07_acerto_pata_roupas")
		if i < 2:
			await create_timer(1.3).timeout
	await shot("08_novo_truque")
	main.get("_celebration").hide()
	events.emit_signal("sheet_close_requested")
	load("res://scripts/ui/places.gd").call("open_npc", "nina")
	await shot("08b_missao_nina")
	state.call("claim_quest", "nina_trick")
	await shot("08c_novidade")
	state.call("_mark_all_seen")
	await create_timer(0.3).timeout
	main.get("_celebration").hide()
	main.get("_modal_queue").clear()
	main.call("show_screen", &"pet")
	await shot("09_botao_truques")
	state.get("dog").affection = 500
	for id: String in db.get("progression").tricks:
		state.call("learn_trick", id)
	main.get("_modal_queue").clear()
	main.get("_celebration").hide()
	ui.call("open")
	await shot("10_lista_aprendidos")
	scroll.scroll_vertical = 10000
	await shot("10b_lista_fim")
	events.emit_signal("sheet_close_requested")
	var animator: Node = main.find_child("PetScreen").get("_animator")
	for id: String in db.get("progression").tricks:
		state.call("perform_trick", id)
		animator.set_process(false)
		animator.set("_frame", 2)
		animator.call("_show")
		await shot("11_" + id + "_roupas")
		animator.set_process(true)
		await create_timer(1.2).timeout
	await shot("12_roupas_restauradas")
	ui.call("open")
	await shot("13_recargas")
	state.call("set_sleeping", true)
	events.emit_signal("sheet_requested", "Treino", ui.call("panel", true))
	await shot("14_dormindo")
	state.call("set_sleeping", false)
	state.get("walk_state").current = {"id":"park_loop", "ready_at":1.0}
	events.emit_signal("state_changed")
	await shot("15_passeando")
	print("TRICKS SHOTS: PASS")
	quit()

func shot(id: String) -> void:
	await create_timer(0.5).timeout
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/etapa10")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(id + ".png"))
