extends SceneTree
## Capturas dos quatro tipos de aviso (ferramenta, NÃO é teste). Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/avisos_shots.gd
## PNGs em build/screenshots/avisos/<largura>x<altura>_<caso>.png. Imprime FAIL se algo sair da tela / sob HUD.

var state: Node
var main: Control
var notice: Object
var folder := "res://../build/screenshots/avisos/"
var failures := 0
const HUD_HEIGHT := 168.0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	root.get_node("Events").emit_signal("sheet_close_requested")


func _clear() -> void:
	notice.call("finish_current")
	while int(notice.call("queued")) > 0 or str(notice.call("showing")) != "":
		notice.call("finish_current")
	await process_frame


func _shot(tag: String, wait: float) -> void:
	await create_timer(wait).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "%dx%d_%s.png" % [image.get_width(), image.get_height(), tag])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.set("coins", 500)
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(1.2).timeout
	notice = main.get("_notice")
	_hide_modals()
	await _clear()
	main.call("show_screen", &"pet")
	await create_timer(0.5).timeout
	var events := root.get_node("Events")
	var hud: Control = main.get("_hud")
	# 1. ✓ saltando na pílula do próximo passo
	var step := hud.get("next_step") as Control
	_check(step.visible, "pílula do próximo passo não está visível")
	step.call("flash_done")
	await _shot("a_passo_check", 0.2)
	# 2. potinho com o pop e a patinha voando
	main.call("_day_complete_notice")
	await _shot("b_potinho_patinha", 0.45)
	# 3. momento: o ícone voa ao avatar (sem pílula)
	main.call("_on_moment_gained", "brave", "test")
	await _shot("c_momento_voando", 0.3)
	_check(str(notice.call("showing")) == "", "momento mostrou pílula de texto")
	await create_timer(1.0).timeout
	# 4. balão do Tiro (tela do Tiro): sobremesa e travessura
	events.emit_signal("tiro_said", "Sobremesa! Não vale patinha.")
	await _shot("d_balao_sobremesa", 0.35)
	await create_timer(3.8).timeout
	events.emit_signal("tiro_said", "Tentou roer o chinelo!")
	await _shot("e_balao_travessura", 0.35)
	# 5. balão do Tiro no mapa (Sítio)
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	await _clear()
	main.call("_on_world_requested", "house", "")
	main.call("show_screen", &"map")
	await create_timer(1.2).timeout
	_hide_modals()
	events.emit_signal("tiro_said", "Latiu para as galinhas!")
	var say := main.find_child("SayBubble", true, false) as Control
	_check(say != null and say.visible, "balão do Tiro não apareceu sobre ele no mapa")
	await _shot("f_balao_mapa", 0.4)
	# 6. foto nova: pontinho na aba Tiro (estando em outra aba)
	state.call("note_screen_opened", "album")
	state.call("dev_take_photo", "h_arrival", 0)
	state.call("dev_seal_photo", "h_arrival")
	main.call("show_screen", &"bag")
	main.call("_refresh_tasks_badge")
	await _shot("g_foto_selo_aba", 0.4)
	var dot := main.get("_pet_dot") as Control
	_check(dot != null and dot.visible, "pontinho da aba Tiro não apareceu com foto nova")
	# 7. erro embaixo
	main.call("show_screen", &"pet")
	await _clear()
	notice.call("notify", "error", "Silo sem espaço: abra lugar para Morango ×1")
	await _shot("h_erro_embaixo", 0.55)
	var toast := main.get_node("Toast") as Control
	_check(toast.visible and toast.get_global_rect().position.y >= HUD_HEIGHT, "erro fora do lugar")
	await _clear()
	# 8. conquista dourada
	main.call("_chef_notice", 1)
	await _shot("i_conquista_dourada", 0.55)
	_check(toast.visible and toast.get_global_rect().end.x <= root.get_visible_rect().size.x, "conquista cortada")
	print("AVISOS SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
