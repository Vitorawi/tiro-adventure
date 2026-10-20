extends SceneTree
## Grupos de missões, personagem recolhido/aberto e avisos de prêmio disponível.
var failures := 0
var main: Control
var tasks: Control
var state: Node

func _initialize() -> void:
	_run.call_deferred()

func frames() -> void:
	for i in 5: await process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TASK GROUPS: " + message)

func clear_modals() -> void:
	main.set("_modal_queue", [] as Array[Callable])
	for member: String in ["_celebration", "_welcome", "_growth_ceremony", "_walk_result"]:
		var modal: CanvasLayer = main.get(member)
		if modal: modal.hide()
	main.find_child("Toast", true, false).hide()

func capture(id: String) -> void:
	if "--screenshots" not in OS.get_cmdline_user_args(): return
	clear_modals()
	await create_timer(0.2).timeout
	await frames()
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/tasks_groups")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("%s_%d.png" % [id, root.size.x]))

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	tasks = main.find_child("TasksScreen", true, false)
	main.call("show_screen", &"tasks")
	state.get("progress").stats["talk:lais"] = 1
	state.call("_changed")
	await frames()
	check(tasks.find_child("NotebookTab_story", true, false).find_child("NewBadge", true, false) != null, "principal pronta avisa no grupo")
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await frames()
		var tabs: Control = tasks.find_child("GroupTabs", true, false)
		check(tabs.size.x <= viewport.x, "grupos cabem em %d" % viewport.x)
		var last: Control = tasks.find_child("NotebookTab_timed", true, false)
		check(last.get_global_rect().end.x <= tasks.get_global_rect().end.x, "último grupo não corta em %d" % viewport.x)
		await capture("principal")
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	for id: String in ["main_9_coop", "nina_walk", "lais_album"]:
		state.get("progress").claimed_quests.erase(id)
	state.get("inventory").call("from_dict", {})
	state.call("_changed")
	await frames()
	clear_modals()
	tasks.call("choose_group", "characters")
	await frames()
	check(tasks.find_child("NotebookTab_characters", true, false).find_child("NewBadge", true, false) != null, "secundária pronta avisa mesmo com personagem fechado")
	check(tasks.find_child("Character_bloblo", true, false).find_child("NewBadge", true, false) != null, "personagem com prêmio tem exclamação")
	check(tasks.find_child("LineCard_bloblo", true, false) == null, "personagem começa recolhido")
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await frames()
		await capture("personagens")
		tasks.call("choose_character", "bloblo")
		await frames()
		check(tasks.find_child("LineCard_bloblo", true, false) != null, "abre missões da Bloblo")
		await capture("bloblo")
		tasks.call("choose_character", "bloblo")
		await frames()
	check(state.call("claim_quest", "main_9_coop") == "", "recebe missão real")
	await frames()
	check(tasks.find_child("Character_bloblo", true, false) == null, "personagem sem missão ativa sai da lista após receber")
	tasks.call("choose_group", "timed")
	tasks.call("choose_routine", "daily")
	await frames()
	check(tasks.find_child("Routines_daily", true, false) != null and tasks.find_child("Routines_weekly", true, false) == null, "temporárias mostram só período escolhido")
	await capture("diarias")
	tasks.call("choose_routine", "weekly")
	await frames()
	check(tasks.find_child("Routines_weekly", true, false) != null and tasks.find_child("Routines_daily", true, false) == null, "semanais separadas")
	await capture("semanais")
	print("TASK GROUPS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
