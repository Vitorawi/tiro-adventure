extends SceneTree
## Primeira fase: chegada automática 1/3, carinho útil 2/3 e novidades continuam válidas.
## Usa a casca/introdução reais, sem SaveManager nem acesso ao save pessoal.
var state: Node
var failures := 0
var moments: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()
	create_timer(45.0).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("COURAGE_START: " + message)

func care() -> Dictionary:
	for row: Dictionary in state.growth_info().requirements:
		if row.id == "pillars": return row
	return {}

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.reset()
	state.set_process(false)
	Motion.reduced = true
	check(care().type == "moments" and care().pillar == "brave" and care().need == 3, "Coragem restaurada com meta 3")
	check(care().have == 0, "reset antes de entrar na Casa tem zero momentos")
	root.get_node("Events").moment_gained.connect(func(pillar: String, source: String) -> void:
		moments.append(pillar + ":" + source))
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	# Conclui só as falas da introdução; não conversa com Laís nem faz carinho.
	var intro_script: Script = load("res://scenes/ui/intro/intro.gd")
	for child: Node in main.get_children():
		if child.get_script() == intro_script:
			for i in 6: child.call("_advance")
	await create_timer(0.7).timeout
	check(moments == ["brave:world:house"], "chegada emite exatamente Coragem por world:house")
	check(care().have == 1 and not care().done, "depois da chegada mostra exatamente 1/3 incompleto")
	check(state.progress.stat("pet") == 0 and state.progress.stat("talk:lais") == 0, "nenhum carinho ou conversa na chegada")
	state.note_world_visit("house")
	check(care().have == 1 and moments.size() == 1, "reentrar na Casa não duplica a novidade")
	var growth_ui: Script = load("res://scripts/ui/growth_ui.gd")
	growth_ui.call("open")
	await create_timer(0.2).timeout
	var step: Dictionary = growth_ui.call("step_view", care())
	check(step.have == 1 and step.need == 3 and not step.done, "consulta da UI mostra 1/3 incompleto")
	var label: Control = main.find_child("MomentText", true, false)
	check(label.get("text") == "Momento de Coragem!", "aviso literal da primeira chegada")
	print("COURAGE_START: aviso inicial capturado = '", label.get("text"), "'; fonte = ", moments)
	if "--screenshots" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/carinho")
		DirAccess.make_dir_recursive_absolute(folder)
		check(root.get_texture().get_image().save_png(folder.path_join("partida_nova_coragem.png")) == OK, "captura salva")
	var saved: Dictionary = state.to_dict().duplicate(true)
	state.from_dict(saved)
	check(care().have == 1 and not care().done and moments.size() == 1, "reload preserva 1/3 sem repetir novidade")
	root.get_node("Events").sheet_close_requested.emit()
	main.call("show_screen", &"pet")
	await process_frame
	var pet: Control = main.find_child("PetScreen", true, false)
	var sprite: Control = pet.get("_dog_sprite")
	pet.call("hold_begin", sprite.size * Vector2(0.5, 0.9))
	pet.call("hold_tick", 1.3)
	pet.call("hold_tick", 2.0)
	pet.call("hold_end")
	check(care().have == 2 and not care().done and moments == ["brave:world:house", "brave:pet"], "carinho útil real avança uma vez para 2/3")
	state.talk_to("lais")
	check(care().have == 3 and care().done, "conhecer Laís continua contando: 3/3")
	state.from_dict(state.to_dict())
	check(care().done, "conclusão persistida permanece definitiva")
	main.queue_free()
	print("COURAGE START TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
