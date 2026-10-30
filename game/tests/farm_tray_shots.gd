extends SceneTree
## Capturas do menu de madeira da horta (FarmDock em cima do canteiro). NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/farm_tray_shots.gd -- --out=farm_tray
## PNGs em build/screenshots/<out>/tray_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var farm: Control
var folder := "res://../build/screenshots/farm_tray/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(400).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FALHOU: ", message)


func dock() -> Control:
	return load("res://scripts/ui/farm_dock.gd").call("current") as Control


func shot(shot_name: String, wait: float = 0.7) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "tray_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	var current := dock()
	if current:
		var rect := current.get_global_rect()
		var screen := root.get_visible_rect().size
		print("[%s] menu %s tela %s" % [shot_name, rect, screen])
		_check(rect.position.x >= 7.5 and rect.end.x <= screen.x - 7.5, "menu fora da folga de 8 px")
		_check(rect.position.y >= 100.0, "menu sob o HUD (y %.1f)" % rect.position.y)
		var close := current.find_child("CloseDock", true, false) as Control
		if close:
			var hit := close.get_global_rect()
			_check(hit.size.x >= 43.5 and hit.size.y >= 43.5, "X menor que 44")
			_check(hit.position.x >= 0.0 and hit.end.x <= screen.x and hit.position.y >= 0.0, "X fora da tela")
		for tile_id: String in current.call("entry_ids"):
			var tile := current.call("tile_node", tile_id) as Control
			if tile and tile.is_visible_in_tree() and (tile.size.x < 43.5 or tile.size.y < 43.5):
				_check(false, "espaço %s menor que 44" % tile_id)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _empty_plots() -> void:
	var plots: Array = state.get("plots")
	for i in plots.size():
		plots[i] = {"crop": "", "ready_at": 0.0}
	state.call("_changed")


## Estado do Sítio com `plots` canteiros, só as sementes pedidas liberadas pelas missões (`claimed`).
func _scene(plots: int, claimed: Array[String], everything: bool = false) -> void:
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	if everything:
		state.call("dev_unlock_everything")
	progress.claimed_quests["growth_1_puppy"] = true  # abre o Sítio
	state.call("_grant_upgrade", "farm")  # escritura: os canteiros deixam de ser emprestados
	for id: String in claimed:
		progress.claimed_quests[id] = true
	state.call("_mark_all_seen")
	state.set("unlocked_plots", plots)
	state.set("coins", 500)
	progress.seen.erase("ui:tray_drag_hint")
	state.call("_changed")
	(state.get("inventory") as RefCounted).call("from_dict", {})
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await create_timer(0.6).timeout
	_hide_modals()
	farm = main.find_child("World_farm", true, false)
	farm.call("_animate_objects")
	farm.call("recenter")
	if everything:
		await create_timer(2.5).timeout  # deixa passar o aviso dos presentes do desbloqueio
		_hide_modals()
	await create_timer(0.5).timeout
	_empty_plots()


func _top_plot() -> int:
	var best := 0
	var best_y := INF
	for index: int in farm.call("plot_indices"):
		var y: float = (farm.call("world_to_screen", farm.call("plot_center", index)) as Vector2).y
		if y < best_y and state.call("plot_status", index) == "empty":
			best_y = y
			best = index
	return best


func _open(index: int, focus: String = "", plant_now: bool = true) -> void:
	farm.call("close_tray")
	farm.call("open_plot_tray", index, focus, false, true, plant_now)
	await create_timer(0.9).timeout


func _close() -> void:
	farm.call("close_tray")
	await create_timer(0.5).timeout


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "farm_tray_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()

	# (a) primeira vez: só a cenoura (+ a próxima bloqueada) e a dica "Arraste até a terra".
	await _scene(6, [])
	print("  status: ", (farm.call("plot_indices") as Array).map(func(i: int) -> String: return "%d=%s" % [i, state.call("plot_status", i)]))
	await _open(2, "carrot", false)
	await shot("a_primeira_vez", 0.9)
	_check(main.find_child("DragHint", true, false) != null, "a dica do primeiro uso apareceu")
	await _close()

	# (b) três espaços: cenoura, batata e a próxima (bloqueada).
	await _scene(6, ["bloblo_more_crops"])
	await _open(3)
	await shot("b_tres_sementes")
	await _close()

	# (c) muitas sementes, rolada até o meio.
	await _scene(9, [], true)
	_empty_plots()
	await _open(4)
	var current := dock()
	current.call("_set_scroll", 70.0)
	await shot("c_rolagem_meio", 0.4)
	await _close()

	# (d) semente escolhida sendo arrastada por vários canteiros (menu esmaecido).
	await _scene(9, [], true)
	_empty_plots()
	await _open(0, "", false)
	current = dock()
	current.call("tap_tile", "potato")
	await create_timer(0.3).timeout
	var path: Array[Vector2] = []
	for index in [1, 2, 5]:
		path.append(farm.call("world_to_screen", farm.call("plot_center", index)))
	current.call("drag_points", path, false)
	await shot("d_arrastando", 0.4)
	current.call("release_drag")
	await _close()

	# (e) canteiro lá em cima: a câmera desce o canteiro, o menu cabe em cima dele sem passar sob o HUD.
	await _scene(9, [], true)
	_empty_plots()
	await _open(_top_plot(), "", false)
	await shot("e_canteiro_no_topo")
	# Sem lugar em cima (a câmera sobe o mundo com o menu aberto): ele vira para baixo, seta para cima.
	farm.call("scroll_by", Vector2(0, -330))
	await shot("e2_virado_para_baixo", 0.5)
	await _close()

	# (f) regar.
	await _scene(9, [], true)
	_empty_plots()
	for i in [1, 2, 3]:
		state.call("plant", i, "carrot")
	farm.call("open_farm_dock", "plant", 1, "water")
	await create_timer(0.9).timeout
	await shot("f_regar")
	await _close()

	# (g) colher: sobraram prontos.
	await _scene(9, [], true)
	_empty_plots()
	for i in [0, 1, 2, 3]:
		state.call("plant", i, "carrot")
	state.call("dev_finish_timers")
	farm.call("_animate_objects")
	farm.call("_on_plot_tapped", 0)
	await create_timer(0.9).timeout
	await shot("g_colher_tudo")

	# (h) depósito cheio: o verde vira o aviso com cadeado.
	(state.get("inventory") as RefCounted).call("add", "carrot", 5000)
	root.get_node("Events").emit_signal("state_changed")
	await create_timer(0.6).timeout
	await shot("h_deposito_cheio")
	await _close()

	# (i) a cenoura nova nos outros lugares: Mochila e cartão de missão.
	await _scene(9, [], true)
	(state.get("inventory") as RefCounted).call("add", "carrot", 12)
	(state.get("inventory") as RefCounted).call("add", "potato", 5)
	main.call("show_screen", &"bag")
	await shot("i_mochila", 1.0)
	main.call("show_screen", &"pet")
	await create_timer(0.4).timeout
	var quests: Dictionary = root.get_node("Database").get("quests")
	quests["_shot_carrot"] = {"npc": "bloblo", "name": "Cenouras", "dialogue": "Preciso de cenouras para a massa.", "goals": [{"type": "deliver", "key": "carrot", "target": 6, "label": "Entregar 6 cenouras"}], "rewards": {"coins": 10, "items": {"carrot": 2}}, "kind": "main", "chapter": 1, "order": 1}
	var card: Control = load("res://scripts/ui/next_step.gd").call("card", "_shot_carrot")
	load("res://scripts/ui/popover.gd").call("open", main, main.find_child("NextStep", true, false), card, 0.0)
	await shot("j_cartao_cenoura", 0.8)
	quests.erase("_shot_carrot")

	print("FARM TRAY SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
