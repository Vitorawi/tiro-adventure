extends SceneTree
## Introdução completa sem gravar o save pessoal, incluindo a chegada e a conversa.

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.call("reset")
	var intro_script: Script = load("res://scenes/ui/intro/intro.gd")
	check(intro_script.should_show(), "Jogo novo apresenta a Laís")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	var intro: Node
	main.call("_refresh_tasks_badge")
	check((main.get("_map_badge") as Label).text == "!" and (main.get("_map_badge") as Label).visible, "Mapa avisa primeira missão nova")
	for child: Node in main.get_children():
		if child.get_script() == intro_script:
			intro = child
	check(is_instance_valid(intro), "A casca abre a introdução automaticamente")
	if not is_instance_valid(intro):
		quit(1)
		return
	check(not (intro.get("_wave") as Array).is_empty(), "Avatar animado da Laís disponível")
	await _shot("intro_1")
	intro.call("_advance")
	intro.call("_advance")
	await create_timer(0.4).timeout
	check((intro.get("_tiro") as Control).modulate.a == 1.0, "Tiro aparece quando é apresentado")
	await _shot("intro_3")
	intro.call("_advance")
	intro.call("_advance")
	check((intro.get("_next") as Button).text == "Soltar o Tiro!", "Última fala permite soltar o Tiro")
	await _shot("intro_5")
	intro.call("_advance")
	intro.call("_advance")  # Toques repetidos no mesmo frame não duplicam a chegada.
	await create_timer(0.7).timeout
	check(not intro_script.should_show(), "Introdução não se repete após terminar")
	var saved: Dictionary = state.call("to_dict").duplicate(true)
	state.call("reset")
	state.call("from_dict", saved)
	check(not intro_script.should_show(), "Conclusão persiste ao recarregar o save")
	var house: Node = main.find_child("World_house", true, false)
	var dog: Node2D = house.get("_dog")
	check(dog.get_meta("last_reaction", "") == &"happy", "Tiro reage à chegada em casa")
	await _shot("intro_release")
	await create_timer(3.0).timeout
	check(state.get("progress").stat("talk:lais") > 0, "Chegada conduz à primeira conversa com a Laís")
	check(not state.get("progress").claimed_quests.has("welcome"), "Apresentação não recebe missão automaticamente")
	await _shot("intro_lais")
	var places: Script = load("res://scripts/ui/places.gd")
	state.call("dev_complete_quest", "lais_bag")
	main.call("_on_world_requested", "farm", "")
	await create_timer(0.3).timeout
	main.get_node("Celebration").hide()
	var farm: Node = main.find_child("World_farm", true, false)
	farm.call("_on_plot_tapped", 2)
	await process_frame
	var sheet: Control = main.find_child("Sheet", true, false)
	check(sheet.get_node("%Title").text == "Vovó Bloblo", "Canteiro emprestado leva à vovó, sem pedir escritura cedo")
	check(sheet.find_child("NpcIntroduction", true, false) != null, "Vovó se apresenta na primeira conversa")
	await _shot("intro_bloblo")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await process_frame
	places.call("open_npc", "bloblo")
	await process_frame
	check(sheet.find_child("NpcIntroduction", true, false) != null, "Fechar no meio não perde a apresentação")
	for i in 3:
		var panel: Node = sheet.find_child("NpcIntroduction", true, false)
		var button: Button = panel.find_children("*", "Button", true, false)[0]
		button.pressed.emit()
		await process_frame
		await process_frame
	check(state.get("progress").seen.has("npc_intro:bloblo"), "Fim da apresentação fica salvo")
	check(sheet.find_child("NpcIntroduction", true, false) == null, "Fim abre missão da vovó")
	var has_orchard: bool = false
	for button: Button in sheet.find_children("*", "Button", true, false):
		has_orchard = has_orchard or button.text == "Pomar"
	check(not has_orchard, "Conversa não anuncia pomar antes da compra")
	main.call("_refresh_tasks_badge")
	check((main.get("_map_badge") as Label).text == "✓", "Missão pronta tem prioridade no Mapa")
	await _shot("intro_bloblo_quest")
	saved = state.call("to_dict").duplicate(true)
	state.call("reset")
	state.call("from_dict", saved)
	root.get_node("Events").emit_signal("sheet_close_requested")
	await process_frame
	places.call("open_npc", "bloblo")
	await process_frame
	check(sheet.find_child("NpcIntroduction", true, false) == null, "Save recarregado não repete apresentação da vovó")
	print("INTRO TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)


func _shot(filename: String) -> void:
	if "--screenshots" not in OS.get_cmdline_user_args():
		return
	await process_frame
	await process_frame
	var folder: String = ProjectSettings.globalize_path("res://../build/screenshots")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(filename + ".png"))
