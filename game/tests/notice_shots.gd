extends SceneTree
## Capturas e MEDIDAS dos avisos (`Notice`) embaixo, na pele de madeira. NÃO é teste da suíte, mas imprime FAIL e sai
## com código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/notice_shots.gd -- --out=notice
## PNGs em build/screenshots/<out>/notice_<largura>x<altura>_<caso>.png. Não grava o save pessoal.

var state: Node
var main: Control
var notice: Object
var folder := "res://../build/screenshots/notice/"
var failures := 0
const HUD_HEIGHT := 168.0  # `Hud.HEIGHT` (o tipo depende de autoload: não referenciar em -s)


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(600).timeout.connect(func() -> void: quit(1))


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
	main.set("_chapter_done", 0)
	main.set("_announce_pending", false)


func _clear() -> void:
	notice.call("finish_current")
	while int(notice.call("queued")) > 0 or str(notice.call("showing")) != "":
		notice.call("finish_current")
	await process_frame


func _fresh() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	await create_timer(1.0).timeout
	_hide_modals()
	await _clear()


func _enter(world: String) -> Control:
	main.call("_on_world_requested", world, "")
	main.call("show_screen", &"map")
	await create_timer(0.8).timeout
	_hide_modals()
	var room := main.find_child("World_" + world, true, false) as Control
	room.call("_animate_objects")
	room.call("recenter")
	await create_timer(0.4).timeout
	return room


## Espera o aviso terminar de subir, mede e salva a captura.
func _shot(tag: String, expect_lines: int = 0) -> void:
	await create_timer(0.55).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "notice_%dx%d_%s.png" % [image.get_width(), image.get_height(), tag])
	var toast := main.get_node("Toast") as Control
	var screen := root.get_visible_rect().size
	_check(toast.visible, "[%s] aviso não está na tela" % tag)
	if not toast.visible:
		return
	var rect := toast.get_global_rect()
	var tab_top: float = main.size.y + (main.get("_tab_art") as Control).offset_top
	_check(rect.position.y >= HUD_HEIGHT, "[%s] aviso sobrepõe o HUD (topo %.1f < %.1f)" % [tag, rect.position.y, HUD_HEIGHT])
	var sheet_open := bool(main.get_node("Sheet").call("is_open"))
	if not sheet_open or tag.begins_with("d_"):
		_check(rect.end.y <= tab_top + 0.5, "[%s] aviso sobrepõe a barra de abas (fim %.1f > %.1f)" % [tag, rect.end.y, tab_top])
	_check(rect.size.y >= 43.5, "[%s] altura %.1f < 44" % [tag, rect.size.y])
	_check(rect.size.x <= 320.0, "[%s] largura %.1f > 320" % [tag, rect.size.x])
	_check(rect.position.x >= 0.0 and rect.end.x <= screen.x, "[%s] aviso fora da tela" % tag)
	var text := main.find_child("ToastText", true, false) as Label
	var lines := text.get_line_count()
	_check(lines <= 2, "[%s] texto com %d linhas" % [tag, lines])
	_check(text.get_visible_line_count() >= lines, "[%s] texto cortado (%d de %d linhas)" % [tag, text.get_visible_line_count(), lines])
	if expect_lines > 0:
		_check(lines == expect_lines, "[%s] esperava %d linhas, veio %d" % [tag, expect_lines, lines])
	print("[%s] %dx%d aviso %s abas y=%.0f linhas %d" % [tag, screen.x, screen.y, rect, tab_top, lines])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "notice_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	notice = main.get("_notice")
	_hide_modals()

	# a) Sítio: colher cinco canteiros prontos com o silo cheio = um só aviso (tela + fila).
	await _fresh()
	var farm := await _enter("farm")
	var plots: Array = farm.call("plot_indices")
	var chosen: Array[int] = []
	for index: int in plots:
		if chosen.size() < 5 and str(state.call("plot_status", index)) == "empty":
			chosen.append(index)
	_check(chosen.size() == 5, "precisa de 5 canteiros vazios (veio %d)" % chosen.size())
	for index: int in chosen:
		state.call("plant", index, "carrot")
		state.get("plots")[index]["ready_at"] = 0.0
	state.get("inventory").call("add", "carrot", 999)
	state.call("_changed")
	await process_frame
	await _clear()
	var harvested := 0
	for index: int in chosen:
		if bool(farm.call("harvest_plot", index)):
			harvested += 1
	await process_frame
	var total := int(notice.call("queued")) + (1 if str(notice.call("showing")) != "" else 0)
	_check(harvested == 0, "o silo cheio não devia deixar colher (%d)" % harvested)
	_check(total == 1, "5 canteiros com silo cheio: %d avisos na tela+fila (esperado 1)" % total)
	await _shot("a_erro_horta")
	await _clear()

	# b) Tela do Tiro: info.
	main.call("show_screen", &"pet")
	await create_timer(0.5).timeout
	_hide_modals()
	await _clear()
	notice.call("notify", "info", "Ele já está penteadinho")
	await _shot("b_info_tiro")
	await _clear()

	# c) Aviso com folha média aberta embaixo.
	main.call("show_screen", &"map")
	await create_timer(0.4).timeout
	var small := PanelContainer.new()
	small.custom_minimum_size.y = 220.0
	var hello := Label.new()
	hello.text = "Folha de teste"
	small.add_child(hello)
	root.get_node("Events").sheet_requested.emit("Folha", small)
	await create_timer(0.8).timeout
	notice.call("notify", "error", "Silo sem espaço: abra lugar para Morango ×1")
	await _shot("c_folha_media")
	await _clear()
	root.get_node("Events").sheet_close_requested.emit()
	await create_timer(0.6).timeout

	# d) Folha alta (sem espaço acima): o aviso fica junto às abas, nunca sobre o HUD.
	var tall := Control.new()
	tall.custom_minimum_size.y = 900.0
	tall.set_meta("sheet_size", "tall")
	root.get_node("Events").sheet_requested.emit("Folha alta", tall)
	await create_timer(0.8).timeout
	notice.call("notify", "error", "Falta 1 cenoura")
	await _shot("d_folha_alta")
	await _clear()
	root.get_node("Events").sheet_close_requested.emit()
	await create_timer(0.6).timeout

	# e) Texto longo: duas linhas, quebra por palavra.
	notice.call("notify", "info", "Missão concluída! Próximo: plante a primeira cenoura")
	await _shot("e_texto_longo", 2)
	await _clear()

	# f) Bandeja de estação presa embaixo.
	farm = await _enter("farm")
	farm.call("close_tray")
	farm.call("_on_object_tapped", "place:workbench", farm.find_child("workbench", true, false))
	await create_timer(1.0).timeout
	_hide_modals()
	notice.call("notify", "error", "Falta 1 tábua")
	await _shot("f_bandeja")
	var tray: Variant = (load("res://scripts/ui/action_tray.gd") as Script).get("current")
	var tray_top := float(tray.call("screen_top")) if tray != null and is_instance_valid(tray) else INF
	var toast_rect := (main.get_node("Toast") as Control).get_global_rect()
	_check(tray != null and is_instance_valid(tray), "bandeja da bancada não abriu")
	_check(tray_top == INF or toast_rect.end.y <= tray_top + 0.5, "aviso cobre a bandeja (fim %.1f > topo %.1f)" % [toast_rect.end.y, tray_top])
	await _clear()

	# g) Erro com ícone do item (ícone pixel à esquerda).
	farm.call("close_tray")
	await create_timer(0.5).timeout
	root.get_node("Events").notice_requested.emit("error", "Falta 1 cenoura", "carrot")
	await _shot("g_erro_icone")
	await _clear()

	print("NOTICE SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
