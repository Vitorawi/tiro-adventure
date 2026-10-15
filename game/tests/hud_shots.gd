extends SceneTree
## Capturas rápidas do HUD novo (Etapa 03): HUD, balão do nível, aviso (curto, longo, com banner), moedas voando
## e configurações com a versão no rodapé. NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/hud_shots.gd -- --out=hud
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/hud/"


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
	saver.set("_save_path", "user://hud_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("xp", 40)
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("show_screen", &"pet")
	await shot("d01_hud")
	main.get_node("TopBar").call("show_level_popover")
	await shot("d02_popover", 0.4)
	await create_timer(2.2).timeout
	root.get_node("Events").emit_signal("toast_requested", "Missão concluída! Próximo: Plante sua primeira semente")
	await shot("d03_toast_long", 0.5)
	await create_timer(2.2).timeout
	main.get_node("UpdateBanner").show()
	root.get_node("Events").emit_signal("toast_requested", "Faltam moedas")
	await shot("d04_banner_toast", 0.5)
	main.get_node("UpdateBanner").hide()
	await create_timer(2.2).timeout
	root.get_node("Events").emit_signal("items_gained", {}, 30, Vector2(180.0, 460.0))
	state.set("coins", int(state.get("coins")) + 30)
	root.get_node("Events").emit_signal("state_changed")
	await shot("d05_coins_fly_a", 0.5)
	await shot("d05_coins_fly_b", 0.5)
	main.call("show_screen", &"map")
	await create_timer(0.6).timeout
	load("res://scripts/ui/settings_panel.gd").call("open")
	await shot("d06_settings", 1.2)
	quit(0)
