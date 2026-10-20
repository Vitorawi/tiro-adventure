extends SceneTree
## Capturas da etapa 13 do plano Tiro: grade do álbum (t09_album_grid), detalhe (t10_photo_detail) e uma
## folha de contato com todas as fotos de História e Primeiras vezes. NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/album_shots.gd -- --out=tiro13_360x780
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/tiro13/"


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
	saver.set("_save_path", "user://album_shots_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	# Fotos tiradas em fases diferentes: o corpo de cada foto é o do dia em que foi tirada.
	var phase_of := {"h_arrival": "newborn", "h_first_night": "newborn", "h_growth_puppy": "puppy", "h_kitchen": "puppy",
		"h_growth_teething": "teething", "h_first_walk": "teething", "h_first_trick": "teething", "h_growth_explorer": "explorer",
		"h_banca": "explorer", "h_growth_young": "young", "h_bench": "young", "h_courage": "young", "h_growth_adult": "adult",
		"h_guardian": "adult", "f_bath": "newborn", "f_taste": "puppy", "f_dig": "puppy", "f_tooth": "teething", "f_friend": "explorer",
		"f_outfit": "young"}
	for id: String in phase_of:
		state.get("growth").phase = phase_of[id]
		state.get("growth").phase_since = state.call("now")
		state.call("dev_take_photo", id)
	state.get("growth").phase = "adult"
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
	var notebook: Variant = load("res://scripts/ui/pet_notebook.gd")
	var album_view: Variant = load("res://scripts/ui/album_view.gd")
	notebook.open("album:story")
	await shot("t09_album_grid")
	notebook.open("album:firsts")
	await shot("t09_album_firsts")
	album_view.open_photo("h_growth_adult")
	await shot("t10_photo_detail")
	album_view.open_photo("h_kitchen")
	await shot("t10_photo_detail_kitchen")
	# Todas as abas do caderninho abertas (cabem na largura?).
	state.call("dev_unlock_everything")
	state.get("growth").phase = "adult"
	await create_timer(0.5).timeout
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: (node as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	state.call("_mark_all_seen")
	notebook.open("album:firsts")
	await shot("t09_notebook_tabs")
	# Folha de contato: todas as fotos, em grade, sobre o mundo.
	Events_close(main)
	var photo_card: Variant = load("res://scripts/ui/photo_card.gd")
	var ids: Array = phase_of.keys()
	for page in 2:
		var sheet := ColorRect.new()
		sheet.color = Color("fff6e3")
		sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sheet.z_index = 100
		var grid := GridContainer.new()
		grid.columns = 3
		grid.position = Vector2(4, 4)
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		for i in range(page * 12, mini(ids.size(), page * 12 + 12)):
			grid.add_child(photo_card.make(ids[i], 112.0, {"caption": true}))
		sheet.add_child(grid)
		root.add_child(sheet)
		await shot("t09_album_contact_%d" % (page + 1))
		sheet.queue_free()
	quit()


func Events_close(_node: Node) -> void:
	root.get_node("Events").sheet_close_requested.emit()
