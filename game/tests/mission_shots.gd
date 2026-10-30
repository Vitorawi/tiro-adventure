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


func _g(path: String) -> Rect2:
	var tasks := main.find_child("TasksScreen", true, false) as Control
	var node := tasks.find_child(path, true, false)
	return _r(node) if node else Rect2()


## Retângulos globais da moldura, da bandeja e da lista: devem ficar idênticos entre reconstruções e trocas de aba.
func _snapshot() -> Array[Rect2]:
	var tasks := main.find_child("TasksScreen", true, false) as Control
	return [_r(tasks.get_node("MissionFrame/Frame")), _g("GroupTabs"), _g("Scroll")]


func _same(before: Array[Rect2], label: String) -> void:
	var now := _snapshot()
	for i in before.size():
		var names: Array[String] = ["moldura", "bandeja", "lista"]
		var moved := maxf(maxf(absf(now[i].position.x - before[i].position.x), absf(now[i].position.y - before[i].position.y)), maxf(absf(now[i].size.x - before[i].size.x), absf(now[i].size.y - before[i].size.y)))
		_check(moved <= 0.5, "%s: %s mexeu %.2f px" % [label, names[i], moved])
		if moved > 0.0:
			print("  (%s: %s mexeu %.3f)" % [label, names[i], moved])
	print("  estável ", label, " ", _fmt(now[0]), " | ", _fmt(now[1]), " | ", _fmt(now[2]))


## Força o LiveBox a reconstruir 3 vezes e confere que nada mudou de lugar; depois troca Principal → Pessoas → Diárias → Principal.
func _stability(tag: String, groups: Array[String]) -> void:
	var tasks := main.find_child("TasksScreen", true, false)
	var before := _snapshot()
	var live: Object = tasks.get("_content")
	for i in 3:
		live.call("refresh")
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		_same(before, "%s rebuild %d" % [tag, i + 1])
	var first_group := str(tasks.get("_group"))
	for id: String in groups:
		tasks.call("choose_group", id)
		await create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		_same(before, "%s grupo %s" % [tag, id])
	tasks.call("choose_group", first_group)
	await create_timer(0.25).timeout
	_same(before, "%s volta %s" % [tag, first_group])


## Imprime os retângulos e confere simetria, bandeja centralizada na borda de cima, alinhamento dos cartões, botões 104×44 e a barra de abas.
func _report(tag: String, width: int) -> void:
	var tasks := main.find_child("TasksScreen", true, false) as Control
	var holder := tasks.get_node("MissionFrame") as Control
	_check(holder.visible, "moldura deve aparecer em todos os grupos")
	print("[%d %s]" % [width, tag])
	var frame := _r(holder.get_node("Frame"))
	var scroll := _g("Scroll")
	var tray := _g("GroupTabs")
	var bar_top := INF
	for node_name: String in ["TabBarArt", "TabBar"]:
		var bar := main.find_child(node_name, true, false) as Control
		if bar:
			bar_top = minf(bar_top, bar.get_global_rect().position.y)
			print("  ", node_name, " ", _fmt(bar.get_global_rect()))
	print("  moldura ", _fmt(frame))
	print("  bandeja ", _fmt(tray))
	print("  scroll  ", _fmt(scroll))
	var screen := float(width)
	_check(absf(frame.position.x - (screen - frame.end.x)) <= 1.0, "moldura assimétrica: esquerda %.1f direita %.1f" % [frame.position.x, screen - frame.end.x])
	_check(absf(frame.position.x - 8.0) <= 1.0, "margem da moldura != 8")
	_check(frame.end.y <= bar_top + 0.5 and scroll.end.y <= bar_top + 0.5, "moldura/scroll passam do topo da barra de abas")
	_check(absf(tray.get_center().x - frame.get_center().x) <= 1.0 and absf(tray.get_center().y - frame.position.y) <= 1.0, "bandeja fora do centro da borda de cima")
	# Bandeja cheia = 86% da moldura; com menos grupos ela encolhe e cada aba mantém um terço da cheia.
	var tab_count := tasks.find_children("NotebookTab_*", "Button", true, false).size()
	var full := roundf(frame.size.x * 0.86)
	var want := 12.0 + tab_count * (full - 20.0) / 3.0 + (tab_count - 1) * 4.0
	_check(absf(tray.size.x - want) <= 2.0, "bandeja com %d abas: %.1f != %.1f" % [tab_count, tray.size.x, want])
	_check(scroll.position.x >= frame.position.x + 30.0 and screen - scroll.end.x >= 8.0 + 30.0, "lista fora do interior da moldura")
	for tab: Node in tasks.find_children("NotebookTab_*", "Button", true, false):
		var rect := _r(tab)
		print("  aba ", tab.name, " ", _fmt(rect), " selo ", tab.find_child("NewBadge", true, false) != null)
		_check(rect.size.y >= 44.0 and rect.position.x >= tray.position.x and rect.end.x <= tray.end.x, "aba %s fora da bandeja ou menor que 44 px" % tab.name)
	var cards: Array[Rect2] = []
	for node: Node in tasks.find_children("StoryHero", "Control", true, false) + tasks.find_children("StoryRewards", "Control", true, false) + tasks.find_children("StoryGoal_*", "Control", true, false):
		cards.append(_r(node))
		print("  cartão ", node.name, " ", _fmt(cards.back()))
	for rect: Rect2 in cards:
		_check(absf(rect.position.x - cards[0].position.x) <= 0.5 and absf(rect.size.x - cards[0].size.x) <= 0.5, "cartões com x/largura diferentes")
		_check(rect.position.x >= scroll.position.x - 0.5 and rect.end.x <= scroll.end.x + 0.5, "cartão fora do scroll")
	var ends: Array[float] = []
	var story := tasks.find_child("StoryCard", true, false)
	for node: Node in (story.find_children("*", "Button", true, false) if story else []):
		var button_name := String(node.name)
		if button_name.begins_with("QuestGo_") or button_name.begins_with("GoalGo_") or button_name.begins_with("ClaimQuest_") or button_name.begins_with("QuestSpace_"):
			var rect := _r(node)
			print("  botão ", button_name, " ", _fmt(rect))
			_check(absf(rect.size.x - 104.0) <= 0.5 and absf(rect.size.y - 44.0) <= 0.5, "botão %s != 104×44" % button_name)
			ends.append(rect.end.x)
	for end_x: float in ends:
		_check(absf(end_x - ends[0]) <= 0.5, "botões com borda direita diferente")


## Abre a "História completa" pelo link, num capítulo do meio (passados, atual e futuros), e confere o livro.
func _book_shot() -> void:
	var tasks := main.find_child("TasksScreen", true, false)
	var full := tasks.find_child("StoryFull", true, false) as LinkButton
	_check(full != null, "StoryFull não existe")
	if full == null:
		return
	full.pressed.emit()
	await create_timer(0.5).timeout
	var book := main.get_node_or_null("StoryBook") as Control
	_check(book != null, "StoryFull não abriu o StoryBook")
	if book == null:
		return
	var width := float(int(root.get_visible_rect().size.x))
	var frame_node := book.find_child("Frame", true, false) as Control
	var frame := _r(frame_node)
	var close := book.find_child("StoryClose", true, false) as Control
	var bar_top := INF
	for node_name: String in ["TabBarArt", "TabBar"]:
		var bar := main.find_child(node_name, true, false) as Control
		if bar:
			bar_top = minf(bar_top, bar.get_global_rect().position.y)
	print("[%d livro] moldura %s | X %s" % [int(width), _fmt(frame), _fmt(_r(close))])
	_check(absf(frame.position.x - (width - frame.end.x)) <= 1.0 and absf(frame.position.x - 8.0) <= 1.0, "livro: moldura assimétrica")
	_check(frame.end.y <= bar_top + 0.5, "livro: moldura passa do topo da barra de abas")
	_check(close.size.x >= 44.0 and close.size.y >= 44.0, "StoryClose menor que 44 px")
	_check(book.find_children("BookChapter_*", "Control", true, false).size() >= 3, "livro sem capítulos")
	var plaque := _r(book.find_child("ChapterPlaque", true, false))
	print("  placa ", _fmt(plaque))
	_check(absf(plaque.get_center().x - frame.get_center().x) <= 1.0 and absf(plaque.get_center().y - frame.position.y) <= 1.0, "livro: placa fora do centro da borda")
	var scroll := _r(book.find_child("BookScroll", true, false))
	_check(scroll.position.x >= frame.position.x + 30.0 and scroll.end.x <= frame.end.x - 30.0, "livro: lista fora do interior da moldura")
	await shot("i_historia_completa", 0.3)
	close.emit_signal("pressed")
	await create_timer(0.2).timeout
	_check(main.get_node_or_null("StoryBook") == null, "StoryClose não fechou o livro")


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
	await _stability("principal", [] as Array[String])
	# (c) vários objetivos, um deles feito.
	await _scene("c_varios", "main_5_cooking", "adult", func(p: Object) -> void:
		p.stats["produce:carrot_snack"] = 2)
	var tasks := main.find_child("TasksScreen", true, false)
	var scroll := tasks.find_child("Scroll", true, false) as ScrollContainer
	scroll.scroll_vertical = 100000
	await shot("c_varios_fim", 0.5)
	await _book_shot()
	# (d) história que segue com outra pessoa.
	await _scene("d_compartilhada", "teeth_3_ring", "puppy")
	# Três abas: Pessoas e Diárias com "!".
	state.call("dev_unlock_everything")
	await create_timer(2.2).timeout
	_hide_modals()
	var progress: Object = state.get("progress")
	for id: String in ["main_9_coop", "nina_walk", "lais_album"]:
		progress.claimed_quests.erase(id)
	state.get("inventory").call("from_dict", {})
	for kind: String in ["daily", "weekly"]:
		for id: String in state.call("routine_ids", kind):
			var goal: Dictionary = state.call("routine_data", kind, id).goal
			progress.stats[goal.key] = progress.stat(goal.key) + int(state.call("routine_target", kind, id))
	state.call("_changed")
	main.call("show_screen", &"pet")
	await create_timer(0.3).timeout
	_hide_modals()
	main.call("show_screen", &"tasks")
	tasks.call("choose_group", "story")
	await shot("g_tres_abas", 0.6)
	await _stability("tres_abas", ["characters", "timed", "story"] as Array[String])
	tasks.call("choose_group", "characters")
	await shot("f_pessoas", 0.5)
	# Pessoa escolhida: mesmo layout da Principal (cartão, Recompensas, Passos).
	var first_line := tasks.find_child("LineCard_*", true, false)
	if first_line:
		tasks.call("choose_line", str(first_line.name).trim_prefix("LineCard_"))
		await shot("j_pessoa_detalhe", 0.6)
		_check(tasks.find_child("LineDetail_*", true, false) != null and tasks.find_child("PersonRewards", true, false) != null, "detalhe da pessoa abre dentro da linha, com prêmios e Pegar")
		tasks.call("choose_line", str(tasks.get("_line")))
		await create_timer(0.3).timeout
	tasks.call("choose_group", "timed")
	await shot("h_diarias", 0.5)
	tasks.call("choose_group", "story")
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
