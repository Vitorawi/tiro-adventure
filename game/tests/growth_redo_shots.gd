extends SceneTree
## Capturas do painel de Crescimento e do resumo do avatar (não é teste).
## godot --path game --resolution 360x780 -s res://tests/growth_redo_shots.gd -- --out=crescimento_novo
var state: Node
var main: Control
var folder := ""

func _initialize() -> void:
	_run.call_deferred()
	create_timer(120.0).timeout.connect(func() -> void: quit(1))

func frames(n: int = 8) -> void:
	for i in n: await process_frame

func shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("%s_%d.png" % [label, root.size.x]))

func _run() -> void:
	var out := "crescimento_novo"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	folder = ProjectSettings.globalize_path("res://").path_join("../build/screenshots/" + out).simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	Motion.reduced = true
	state.call("reset")
	state.get("progress").seen.intro = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	for member: String in ["_celebration", "_welcome", "_walk_result"]: main.get(member).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var ui: Script = load("res://scripts/ui/growth_ui.gd")
	var hud: Control = main.get_node("TopBar")
	# Filhotinho rumo a Dentinhos com carinho feito: o caso do print do iPhone.
	for phase: String in ["newborn", "puppy", "teething", "explorer", "young"]:
		state.call("dev_set_phase", phase)
		state.get("growth").done = {}
		state.get("growth").phase_moments = {"brave": 3}
		if phase == "explorer": state.get("inventory").add("soft_brush", 1)
		state.call("_changed")
		main.get("_toast").hide()
		ui.call("open")
		await frames()
		await shot(phase + "_top")
		var scroll := main.find_child("Sheet", true, false).find_child("Scroll", true, false) as ScrollContainer
		scroll.scroll_vertical = 10000
		await frames()
		await shot(phase + "_bottom")
		root.get_node("Events").sheet_close_requested.emit()
		await frames()
		hud.call("refresh", false)
		hud.call("show_level_popover")
		await frames()
		await shot(phase + "_popover")
		var catcher := main.get_node_or_null("PopoverCatcher")
		if catcher: catcher.free()
		await frames()
	state.call("dev_complete_growth_reqs")
	ui.call("open")
	await frames()
	await shot("ready_top")
	quit(0)
