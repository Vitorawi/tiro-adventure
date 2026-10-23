extends SceneTree
## Capturas rápidas do painel novo (Etapa 02): fogão, fogão trabalhando, Bosque trabalhando e arrasto.
## NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/sheet_shots.gd -- --out=sheet
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/sheet/"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()


func shot(shot_name: String, wait: float = 0.8) -> void:
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


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "sheet_shots_descartavel.json"))
	state = root.get_node("GameState")
	var places: Script = load("res://scripts/ui/places.gd")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("dev_add_items", 20)
	state.call("_mark_all_seen")
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("_on_world_requested", "house", "")
	await create_timer(2.0).timeout
	_hide_modals()
	places.call("open", "house", "stove")
	await shot("01_stove")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout
	# Fogão sozinho (começo do jogo: sem liquidificador, sem título repetido).
	var sb: Script = load("res://scripts/ui/sheet_builder.gd")
	root.get_node("Events").emit_signal("sheet_requested", "Cozinha", sb.call("stations_view", PackedStringArray(["stove"])))
	await shot("01b_stove_only")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout
	for i in 4:
		state.call("cook", "carrot_snack")
	state.call("dev_advance_time", 70)
	places.call("open", "house", "stove")
	await shot("02_stove_busy")
	# Arrasto no meio do caminho.
	var sheet: Control = main.find_child("Sheet", true, false)
	var panel: Control = sheet.get_node("%Panel")
	var top := panel.global_position.y + 10.0
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(180, top)
	press.global_position = press.position
	sheet.call("_drag_input", press)
	var move := InputEventMouseMotion.new()
	move.position = Vector2(180, top + 160)
	move.global_position = move.position
	sheet.call("_drag_input", move)
	await shot("03_stove_dragging", 0.3)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = move.position
	release.global_position = move.position
	sheet.call("_drag_input", release)
	await create_timer(0.6).timeout
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout
	main.call("_on_world_requested", "nature", "")
	await create_timer(2.0).timeout
	_hide_modals()
	state.call("start_gathering", "trees", 0, "lane")
	state.call("start_gathering", "trees", 1, "lane")
	state.call("dev_advance_time", 30)
	places.call("open", "nature", "trees")
	await shot("04_nature_busy")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout
	quit(0)
