extends SceneTree
## Capturas da etapa 17 do plano Tiro: painel da Pelagem de seda e o Tiro brilhando. NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/silk_shots.gd -- --out=tiro17_360x780
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/tiro17/"


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




func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "silk_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("growth").phase = "adult"
	state.get("growth").phase_moments["coat"] = 330
	state.get("growth").silk = 1
	state.get("growth").brush_days = {"a": true, "b": true, "c": true, "d": true, "e": true, "f": true, "g": true, "h": true, "i": true, "j": true}
	state.get("progress").stats["shampoo_bath"] = 6
	Motion.reduced = false
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
	state.get("growth").silk = 3
	main.call("show_screen", &"pet")
	await create_timer(0.6).timeout
	Motion.reduced = true
	Events_state_changed()
	await shot("t01_tiro_silk3_parado")
	Motion.reduced = false
	state.get("growth").silk = 1
	Events_state_changed()
	var notebook: Script = load("res://scripts/ui/growth_ui.gd")
	notebook.call("open")
	await create_timer(0.8).timeout
	await shot("t02_silk_panel_ready", 0.5)
	state.get("growth").brush_days = {"a": true}
	state.call("_changed")
	await shot("t03_silk_panel_locked", 0.5)
	quit(0)


func Events_state_changed() -> void:
	root.get_node("Events").state_changed.emit()
