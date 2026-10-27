extends SceneTree
## Capturas do grupo História das Missões em "madeira ilustrada". NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/mission_shots.gd -- --out=mission_wood
## PNGs em build/screenshots/<out>/mission_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/mission_wood/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(400).timeout.connect(func() -> void: quit(1))


func shot(shot_name: String, wait: float = 0.7) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "mission_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_report(shot_name, int(root.get_visible_rect().size.x))


func _r(node: Node) -> Rect2:
	if node is NinePatchRect:
		return Rect2((node as Control).global_position, (node as Control).size * (node as Control).scale)
	return (node as Control).get_global_rect() if node is Control else Rect2()


func _fmt(rect: Rect2) -> String:
	return "x=%.1f y=%.1f w=%.1f h=%.1f (fim x=%.1f y=%.1f)" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y, rect.end.x, rect.end.y]


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FALHOU: ", message)


## Imprime os retângulos da História e confere simetria, alinhamento dos cartões, botões 104×44 e a barra de abas.
func _report(tag: String, width: int) -> void:
	var tasks := main.find_child("TasksScreen", true, false) as Control
	var holder := tasks.get_node("MissionFrame") as Control
	if not holder.visible:
		print("[%dx? %s] sem moldura (outro grupo)" % [width, tag])
		return
	print("[%d %s]" % [width, tag])
	var frame := _r(holder.get_node("Frame"))
	var scroll := _r(tasks.find_child("Scroll", true, false))
	var plaque := _r(tasks.find_child("ChapterPlaque", true, false))
	var bar_top := INF
	for node_name: String in ["TabBarArt", "TabBar"]:
		var bar := main.find_child(node_name, true, false) as Control
		if bar:
			bar_top = minf(bar_top, bar.get_global_rect().position.y)
			print("  ", node_name, " ", _fmt(bar.get_global_rect()))
	print("  tela    ", _fmt(tasks.get_global_rect()), " holder ", _fmt(holder.get_global_rect()), " min ", tasks.get_combined_minimum_size())
	print("  moldura ", _fmt(frame))
	print("  placa   ", _fmt(plaque))
	print("  scroll  ", _fmt(scroll))
	var screen := float(width)
	_check(absf(frame.position.x - (screen - frame.end.x)) <= 1.0, "moldura assimétrica: esquerda %.1f direita %.1f" % [frame.position.x, screen - frame.end.x])
	_check(absf(frame.position.x - 8.0) <= 1.0, "margem da moldura != 8")
	_check(frame.end.y <= bar_top + 0.5 and scroll.end.y <= bar_top + 0.5, "moldura/scroll passam do topo da barra de abas")
	_check(absf(plaque.get_center().x - frame.get_center().x) <= 1.0 and absf(plaque.get_center().y - frame.position.y) <= 1.0, "placa fora do centro da borda de cima")
	_check(absf(plaque.size.x - frame.size.x * 0.78) <= 2.0, "placa != 78% da moldura")
	var tabs := main.find_child("GroupTabs", true, false) as Control
	if tabs.visible:
		_check(plaque.position.y - tabs.get_global_rect().end.y <= 8.5, "folga entre abas e placa > 8")
	_check(scroll.position.x >= frame.position.x + 30.0 and screen - scroll.end.x >= 8.0 + 30.0, "lista fora do interior da moldura")
	var cards: Array[Rect2] = []
	for node: Node in tasks.find_children("StoryHero", "Control", true, false) + tasks.find_children("StoryRewards", "Control", true, false) + tasks.find_children("StoryGoal_*", "Control", true, false):
		cards.append(_r(node))
		print("  cartão ", node.name, " ", _fmt(cards.back()))
	for rect: Rect2 in cards:
		_check(absf(rect.position.x - cards[0].position.x) <= 0.5 and absf(rect.size.x - cards[0].size.x) <= 0.5, "cartões com x/largura diferentes")
		_check(rect.position.x >= scroll.position.x - 0.5 and rect.end.x <= scroll.end.x + 0.5, "cartão fora do scroll")
	var ends: Array[float] = []
	for node: Node in tasks.find_children("*", "Button", true, false):
		var button_name := String(node.name)
		if button_name.begins_with("QuestGo_") or button_name.begins_with("GoalGo_") or button_name.begins_with("ClaimQuest_") or button_name.begins_with("QuestSpace_"):
			var rect := _r(node)
			print("  botão ", button_name, " ", _fmt(rect))
			_check(absf(rect.size.x - 104.0) <= 0.5 and absf(rect.size.y - 44.0) <= 0.5, "botão %s != 104×44" % button_name)
			ends.append(rect.end.x)
	for end_x: float in ends:
		_check(absf(end_x - ends[0]) <= 0.5, "botões com borda direita diferente")


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


## Marca como recebidos os passos da história até (sem incluir) `stop`, e os marcos de linha que eles representam.
func _claim_until(stop: String) -> void:
	var progress: Object = state.get("progress")
	var quests: Dictionary = root.get_node("Database").get("quests")
	for c in range(1, int(quests[stop].chapter) + 1):
		for id: String in progress.main_quests(c):
			if id == stop:
				break
			progress.claimed_quests[id] = true
			if quests[id].has("shared_with"):
				progress.claimed_quests[str(quests[id].shared_with)] = true
	state.call("_changed")


func _scene(shot_name: String, stop: String, phase: String, setup: Callable = Callable()) -> void:
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	if stop != "":
		_claim_until(stop)
	if phase != "":
		state.get("growth").phase = phase
	if setup.is_valid():
		setup.call(progress)
	state.call("_mark_all_seen")
	state.set("unlimited_storage", true)
	state.call("_changed")
	main.call("show_screen", &"pet")
	await create_timer(0.3).timeout
	_hide_modals()
	main.call("show_screen", &"tasks")
	await shot(shot_name, 0.9)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "mission_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	# (a) começo do capítulo 1, missão em andamento.
	main.call("show_screen", &"tasks")
	await shot("a_comeco", 0.9)
	# (b) missão pronta para pegar.
	state.get("progress").stats["talk:lais"] = 1
	state.call("_changed")
	await shot("b_pronta", 0.6)
	# (c) vários objetivos, um deles feito.
	await _scene("c_varios", "main_5_cooking", "adult", func(p: Object) -> void:
		p.stats["produce:carrot_snack"] = 2)
	var tasks := main.find_child("TasksScreen", true, false)
	var scroll := tasks.find_child("Scroll", true, false) as ScrollContainer
	scroll.scroll_vertical = 100000
	await shot("c_varios_fim", 0.5)
	# (d) história que segue com outra pessoa.
	await _scene("d_compartilhada", "teeth_3_ring", "puppy")
	# Grupo Pessoas (continua liso).
	tasks.call("choose_group", "characters")
	await shot("f_pessoas", 0.5)
	# (e) história concluída.
	state.call("dev_unlock_everything")
	await create_timer(2.2).timeout
	_hide_modals()
	main.call("show_screen", &"pet")
	await create_timer(0.3).timeout
	_hide_modals()
	main.call("show_screen", &"tasks")
	await shot("e_completa", 0.9)
	print("MISSION SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
