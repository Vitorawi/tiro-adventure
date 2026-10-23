extends SceneTree
## Capturas da etapa 12 do plano Tiro: escovar (t07_brush) e Guia de sabores (t08_tastes). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/brush_taste_shots.gd -- --out=tiro12_360x780
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/tiro12/"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))


func shot(shot_name: String, wait: float = 0.6) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _event(tray: Control, kind: String, point: Vector2) -> void:
	var item: Control = tray.call("item_node", "brush")
	var event: InputEvent
	if kind == "move":
		var motion := InputEventMouseMotion.new()
		motion.global_position = point
		motion.position = point - item.global_position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		event = motion
	else:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = kind == "press"
		button.global_position = point
		button.position = point - item.global_position
		event = button
	item.gui_input.emit(event)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "brush_taste_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("growth").phase = "teething"
	state.get("growth").taste_seed = 7
	state.get("inventory").call("from_dict", {"basic_brush": 1, "dog_food": 2, "pumpkin_mash": 1, "carrot": 1})
	state.get("growth").tastes = {"dog_food": "liked", "carrot": "odd", "blueberry": "grimace", "apple": "liked"}
	state.get("growth").tastes[str(state.call("favorite_food"))] = "loved"
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: (node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree(): (intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	state.call("_mark_all_seen")
	main.call("show_screen", &"pet")
	await create_timer(0.6).timeout
	var pet: Control = main.find_child("PetScreen", true, false)
	var tray: Control = pet.find_child("CareTray", true, false)
	await shot("t07_care_tray")
	# Escovada em andamento: nós ainda nas costas.
	var back: Rect2 = pet.call("back_rect")
	var a := back.get_center() + Vector2(-60, 40)
	_event(tray, "press", tray.call("item_center", "brush"))
	_event(tray, "move", a)
	_event(tray, "move", a + Vector2(120, 0))
	_event(tray, "move", a)
	await shot("t07_brush", 0.3)
	_event(tray, "release", a)
	await create_timer(0.3).timeout
	tray.call("open_food_menu")
	await shot("t07_food_guide")
	tray.call("close_food_menu")
	state.get("progress").seen["feature:growth_tab"] = true
	var notebook: Script = load("res://scripts/ui/pet_notebook.gd")
	notebook.call("open", "growth")
	await create_timer(0.8).timeout
	await shot("t08_tastes", 0.5)
	quit(0)
