extends SceneTree
## Capturas e MEDIDAS da jornada fluida (26/11/2026): avisos leves no lugar das telas grandes. NÃO é teste da suíte,
## mas imprime FAIL e sai com código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fluxo_shots.gd -- --out=fluxo
## PNGs em build/screenshots/<out>/fluxo_<largura>x<altura>_<caso>.png. Não grava o save pessoal.
## Casos: a_passo (aviso Passo concluído ✓), b_novo (folha Novo! com 3 novidades juntas), c_dia (Dia completo! com a
## patinha a caminho do potinho), d_foto (Nova foto!), e_chef (aviso do cozinheiro), f_capitulo (fim do capítulo junto
## com o crescer: só a cerimônia).

var state: Node
var main: Control
var notice: Object
var folder := "res://../build/screenshots/fluxo/"
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
	# O dev_unlock_everything entrega passos sozinho: os avisos desses passos chegam depois; limpa até assentar.
	for i in 3:
		_hide_modals()
		await _clear()
		await create_timer(0.4).timeout
	_hide_modals()
	await _clear()


func _save(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "fluxo_%dx%d_%s.png" % [image.get_width(), image.get_height(), tag])


## Aviso na tela: mede (fora do HUD e das abas, ≥ 44 de altura, dentro da tela, texto inteiro) e salva a captura.
func _toast_shot(tag: String, wait: float = 0.6) -> void:
	await create_timer(wait).timeout
	await _save(tag)
	var toast := main.get_node("Toast") as Control
	var screen := root.get_visible_rect().size
	_check(toast.visible, "[%s] aviso não está na tela" % tag)
	if not toast.visible:
		return
	var rect := toast.get_global_rect()
	var tab_top: float = main.size.y + (main.get("_tab_art") as Control).offset_top
	_check(rect.position.y >= HUD_HEIGHT, "[%s] aviso sobrepõe o HUD" % tag)
	_check(rect.end.y <= tab_top + 0.5, "[%s] aviso sobrepõe a barra de abas" % tag)
	_check(rect.size.y >= 43.5, "[%s] altura %.1f < 44" % [tag, rect.size.y])
	_check(rect.position.x >= 0.0 and rect.end.x <= screen.x, "[%s] aviso fora da tela" % tag)
	var text := main.find_child("ToastText", true, false) as Label
	_check(text.get_visible_line_count() >= text.get_line_count(), "[%s] texto cortado" % tag)
	print("[%s] %dx%d aviso %s '%s' toque=%s" % [tag, screen.x, screen.y, rect, text.text, toast.mouse_filter == Control.MOUSE_FILTER_STOP])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fluxo_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	notice = main.get("_notice")
	_hide_modals()
	var celebration: CanvasLayer = main.get("_celebration")

	# a) Passo concluído ✓: só o aviso (e o pulinho na pílula), sem folha.
	await _fresh()
	main.get("_quest_rewards").append({"id": "lais_feed", "next": ""})
	main.call("_announce")
	await _toast_shot("a_passo")
	_check(not celebration.visible and not (main.get("_quest_reward") as CanvasLayer).visible, "passo concluído não abre tela")

	# b) Novo! com três novidades numa folha só.
	await _fresh()
	var keys: Array[String] = ["world:village", "npc:nina", "place:farm/orchard"]
	celebration.call("show_unlocks", keys)
	await create_timer(0.9).timeout
	await _save("b_novo")
	var tiles := celebration.find_children("ChapterUnlock_*", "Control", true, false)
	_check(tiles.size() >= 2, "folha Novo! com as novidades juntas (%d)" % tiles.size())
	for tile: Node in tiles:
		_check((tile as Control).get_global_rect().size.y >= 44.0, "alvo da novidade ≥ 44")
	_check(celebration.find_child("UnlockClose", true, false) != null, "botão de fechar")
	print("[b_novo] %d novidades" % tiles.size())
	_hide_modals()

	# c) Dia completo!: aviso com a patinha a caminho do potinho.
	await _fresh()
	main.call("_day_complete_notice")
	await _toast_shot("c_dia", 0.55)
	var fly := main.find_child("DayPawFly", true, false)
	print("[c_dia] patinha voando: %s" % (fly != null))

	# d) Nova foto!
	await _fresh()
	main.call("_show_photo_toast", "f_bath")
	await _toast_shot("d_foto")

	# e) Nível de cozinheiro.
	await _fresh()
	main.call("_chef_notice", 2)
	await _toast_shot("e_chef")

	# f) Fim do capítulo junto com o crescer: só a cerimônia.
	await _fresh()
	state.call("dev_set_phase", str(root.get_node("Database").get("growth").phases[0].id))
	state.call("dev_complete_growth_reqs")
	var grow_error: String = str(state.call("grow"))
	print("[f_capitulo] grow -> '%s' fase=%s cerimônias=%s" % [grow_error, state.get("growth").phase, state.get("growth").ceremonies.keys()])
	var steps: Array = main.get("_quest_rewards")
	steps.append({"id": "growth_1_puppy", "next": ""})
	main.set("_chapter_done", 1)
	main.call("_announce")
	await create_timer(3.0).timeout
	var ceremony: CanvasLayer = main.get("_growth_ceremony")
	_check(ceremony.visible, "a cerimônia de crescer abre")
	_check(not celebration.visible, "o cartão de capítulo NÃO abre junto com a cerimônia")
	await create_timer(2.5).timeout
	await _save("f_capitulo")
	print("[f_capitulo] cerimônia=%s capítulo=%s" % [ceremony.visible, celebration.visible])

	_hide_modals()
	print("FALHAS: %d" % failures)
	quit(1 if failures > 0 else 0)
