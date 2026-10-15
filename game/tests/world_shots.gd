extends SceneTree
## Capturas rápidas dos mundos em tela cheia (Etapa 04): os cinco mundos, zoom mínimo no Sítio, duplo toque
## e painel aberto a partir de um objeto. NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/world_shots.gd -- --out=mundos
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/mundos/"


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


func _world(world_id: String) -> Control:
	main.call("_on_world_requested", world_id, "")
	main.call("show_screen", &"map")
	await create_timer(0.6).timeout
	return main.find_child("World_" + world_id, true, false)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", "user://world_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.call("plant", 0, "carrot")
	state.call("plant", 1, "potato")
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	for w: String in ["house", "farm", "park", "village", "nature"]:
		await _world(w)
		await shot("b06_world_" + w)
	var farm := await _world("farm")
	farm.call("_zoom_at", farm.size / 2.0, 0.0)
	await shot("d01_farm_zoom_out")
	farm.call("_on_tap_released", Vector2(10, 10))
	farm.call("_on_tap_released", Vector2(12, 12))
	await shot("d02_farm_doubletap", 0.6)
	farm.call("recenter")
	await create_timer(0.5).timeout
	
	farm.call("_on_object_tapped", "place:silo", farm.find_child("silo", true, false))
	await shot("d03_sheet_over_object", 1.0)
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.5).timeout
	quit()
