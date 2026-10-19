extends SceneTree
## Capturas da etapa 13 da economia (cartões da História 1–9 e ajuda "?"). NÃO é teste.
## Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/journey_shots.gd -- --out=etapa13_depois/360x780
## `--antes` troca em memória as missões/ervas pelas de antes da etapa (build/economy/etapa_13/*.before.json).
## PNGs em build/screenshots/<out>/. Não grava o save pessoal.

var state: Node
var main: Node
var folder := "res://../build/screenshots/etapa13/"
var before := false


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
		if arg == "--antes":
			before = true
	_run.call_deferred()


func shot(shot_name: String, wait: float = 0.6) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(ProjectSettings.globalize_path("res://../build/economy/etapa_13/" + path), FileAccess.READ)
	return JSON.parse_string(file.get_as_text())


## Marca como recebidos os passos da história até (sem incluir) `stop`, e os marcos de linha que eles representam.
func _claim_until(stop: String) -> void:
	var progress: Object = state.get("progress")
	var quests: Dictionary = root.get_node("Database").get("quests")
	var chapter: int = int(quests[stop].chapter)
	for c in range(1, chapter + 1):
		for id: String in progress.main_quests(c):
			if id == stop:
				break
			progress.claimed_quests[id] = true
			if quests[id].has("shared_with"):
				progress.claimed_quests[str(quests[id].shared_with)] = true
	state.call("_changed")


func _card(shot_name: String, stop: String, setup: Callable = Callable()) -> void:
	state.call("reset")
	var progress: Object = state.get("progress")
	progress.seen["intro"] = true
	_claim_until(stop)
	if setup.is_valid():
		setup.call(progress)
	state.call("_mark_all_seen")
	state.set("unlimited_storage", true)
	state.call("_changed")
	main.call("show_screen", &"pet")
	await create_timer(0.3).timeout
	main.call("show_screen", &"tasks")
	await shot(shot_name, 0.9)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", "user://journey_shots_descartavel.json")
	state = root.get_node("GameState")
	var database: Node = root.get_node("Database")
	if before:
		database.set("quests", _json("quests.before.json"))
		database.set("crops", _json("crops.before.json"))
	state.call("reset")
	root.get_node("GameState").get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	# 1. Primeiro capítulo (nada mudou aqui; conferência de que o começo segue igual).
	await _card("01_capitulo_1", "welcome")
	# 2. Capítulo 6: a história aponta para a linha do Guia (principal só orienta).
	await _card("02_cap6_guia_caverna", "main_5_pickaxe", func(p: Object) -> void:
		p.claimed_quests["guide_meet"] = true
		p.claimed_quests["guide_wood"] = true)
	await _card("03_cap6_guia_pedreira", "stone_path", func(p: Object) -> void:
		p.claimed_quests["guide_meet"] = true
		p.claimed_quests["guide_wood"] = true
		p.owned["cave_open"] = true)
	await _card("04_cap6_cozinha", "main_5_cooking", func(p: Object) -> void:
		p.stats["produce:carrot_snack"] = 2
		p.stats["produce:vegetable_soup"] = 1)
	await _card("05_cap7_variedade", "main_6_commerce", func(p: Object) -> void:
		p.claimed_quests["merchant_regular"] = true)
	await _card("06_cap8_estufa", "main_7_greenhouse", func(p: Object) -> void:
		p.owned["greenhouse"] = true)
	await _card("07_cap9_atelie", "atelier_open", func(p: Object) -> void:
		p.owned["atelier"] = true
		p.stats["produce:fabric"] = 2)
	# 3. Ajuda "?" de um passo novo (ervas e pedido) abre o primeiro passo.
	await _card("08_cap8_estufa_sem_estufa", "main_7_greenhouse")
	var task_help: Script = load("res://scripts/ui/task_help.gd")
	task_help.call("open", "crop", "herbs", 1)
	await shot("09_ajuda_ervas", 1.0)
	print("JOURNEY SHOTS: pronto")
	quit()
