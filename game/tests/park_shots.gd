extends SceneTree
## Capturas da Etapa 06 (rode SEM --headless, com --resolution 360x780). Não entra no test_all.
var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa06/"


func _initialize() -> void:
	_run.call_deferred()


func shot(shot_name: String, wait: float = 0.6) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	for id in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order"]:
		state.get("progress").claimed_quests[id] = true
	state.get("progress").seen["intro"] = true
	state.call("mark_seen", state.get("progress").unlocked_keys())
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	main.get_node("Celebration").hide()
	main.call("show_screen", &"map")
	main.find_child("WorldsScreen", true, false).call("show_map")
	await shot("mapa_lista")
	main.call("_on_world_requested", "park", "")
	await create_timer(3.0).timeout
	await shot("praca_inteira", 1.5)
	root.get_node("Events").emit_signal("sheet_requested", "Nina", load("res://scripts/ui/progression_ui.gd").call("npc_introduction", "nina"))
	await shot("conversa_nina")
	root.get_node("Events").emit_signal("sheet_close_requested")
	state.call("talk_to", "nina")
	state.call("claim_quest", "nina_meet")
	root.get_node("Events").emit_signal("sheet_requested", "Passeio", load("res://scripts/ui/places.gd").call("_panel", "walks", ""))
	await shot("painel_passeio_vazio")
	state.call("start_walk", "park_loop")
	await shot("painel_passeio_andando", 1.2)
	root.get_node("Events").emit_signal("sheet_close_requested")
	await shot("praca_passeando", 1.0)
	main.call("show_screen", &"pet")
	await shot("tela_tiro_passeando", 1.5)
	main.call("_on_world_requested", "house", "")
	await create_timer(2.0).timeout
	await shot("casa_sem_tiro")
	state.call("dev_finish_timers")
	root.get_node("Events").emit_signal("sheet_requested", "Passeio", load("res://scripts/ui/places.gd").call("_panel", "walks", ""))
	await shot("painel_passeio_pronto", 1.2)
	root.get_node("Events").emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "park", "")
	await create_timer(1.5).timeout
	await shot("praca_portao_pronto")
	state.call("collect_walk")
	await create_timer(1.0).timeout
	await shot("cartao_volta", 1.0)
	quit(0)
