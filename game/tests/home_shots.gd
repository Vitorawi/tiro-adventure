extends SceneTree
## Capturas da tela inicial "madeira ilustrada" (aba Tiro e as outras abas com o HUD/rodapé novos). NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/home_shots.gd -- --out=home_wood
## PNGs em build/screenshots/<out>/home_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/home_wood/"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()


func shot(shot_name: String, wait: float = 0.7) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "home_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
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
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "home_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_mark_all_seen")
	state.set("coins", 1280)
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.find_child("PetScreen", true, false).set("preview_hour", 12)  # luz do dia, como no protótipo
	main.call("show_screen", &"pet")
	await shot("pet")
	# Cada fase do Tiro: a cabeça da moldura acompanha o corpo.
	for phase: String in ["puppy", "young", "adult"]:
		state.call("dev_set_phase", phase)
		await shot("fase_" + phase, 0.5)
	# Uma necessidade pedindo (véu vermelho na bandeja).
	state.call("dev_set_need", "hunger", 5.0)
	await shot("pet_pedindo")
	# Necessidades variadas: verde, amarela, vermelha (pedindo) e verde.
	for pair: Array in [["hunger", 90.0], ["happiness", 45.0], ["energy", 12.0], ["hygiene", 70.0]]:
		state.call("dev_set_need", pair[0], pair[1])
	await shot("pet_necessidades")
	state.call("dev_set_need", "hunger", 5.0)
	main.get_node("TopBar").call("show_level_popover")
	await shot("popover", 0.4)
	for catcher: Node in main.get_children():
		if catcher.name == "PopoverCatcher":
			catcher.queue_free()
	var pet := main.find_child("PetScreen", true, false)
	var care := pet.find_child("CareButton", true, false) as Button
	care.pressed.emit()
	await shot("roleta", 0.9)
	care.pressed.emit()
	await create_timer(0.3).timeout
	# Adulto com tudo liberado: balão do desejo, nível e requisitos completos.
	state.call("dev_unlock_everything")
	state.call("dev_set_phase", "adult")
	state.call("dev_fill_needs")
	state.call("dev_refresh_wishes")
	await create_timer(0.8).timeout
	_hide_modals()
	await shot("pet_adulto", 5.0)
	main.call("show_screen", &"map")
	await shot("mapa")
	main.call("show_screen", &"tasks")
	await shot("missoes")
	main.call("show_screen", &"bag")
	await shot("mochila")
	quit()
