extends SceneTree
## Evidência visual da etapa 15; save descartável, sem tocar no progresso pessoal.
var main: Node
var state: Node
var view: Variant
var notebook: Variant
const OUT := "res://../build/screenshots/tiro15/"

func _initialize() -> void:
	_run.call_deferred()
	create_timer(80).timeout.connect(func() -> void: quit(1))

func shot(id: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT) + id + ".png")

func clear_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: node.hide()
	main.set("_modal_queue", [] as Array[Callable])
	state._mark_all_seen()

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer: child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "album_secrets_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.reset()
	state.dev_unlock_everything()
	state.dev_reset_album()
	state.dev_take_photo("h_arrival")
	state.progress.seen["intro"] = true
	state.growth.phase = "explorer"
	state.progress.equipped.head = "explorer_hat"
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	clear_modals()
	main.show_screen(&"pet")
	notebook = load("res://scripts/ui/pet_notebook.gd")
	view = load("res://scripts/ui/album_view.gd")
	var db: Node = root.get_node("Database")
	var active: Array = db.album.active_sections.duplicate()
	db.album.active_sections = ["story", "firsts"]
	notebook.open("album:firsts")
	await shot("before_sections")
	db.album.active_sections = active
	notebook.open("album:tricks")
	await shot("secret_grid")
	root.get_node("Events").sheet_requested.emit("Fantasminha de espuma", view.secret_detail("s_foam_ghost"))
	await shot("secret_hint")
	state.reveal_photo_hint("s_foam_ghost")
	root.get_node("Events").sheet_requested.emit("Fantasminha de espuma", view.secret_detail("s_foam_ghost"))
	await shot("secret_lupa")
	state.bathe()
	state.pet()
	state.bathe()
	clear_modals()
	view.open_photo("s_soap_explorer")
	await shot("secret_discovered")
	root.get_node("Events").sheet_close_requested.emit()
	state.album.party_from = state.now() - 1
	state.album.party_until = state.now() + 86400
	state._changed()
	clear_modals()
	main.show_screen(&"pet")
	await create_timer(3.0).timeout
	await shot("tiro_party")
	state.dev_take_photo("p_pipoca")
	clear_modals()
	view.open_photo("p_pipoca")
	await shot("sleep_pipoca")
	main.queue_free()
	await process_frame
	quit(0)
