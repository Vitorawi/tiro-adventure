extends SceneTree
## Capturas e MEDIDAS da etapa 09 da pesca: caderno de peixes (Caderninho → Coleção → Peixes) e detalhe da espécie. NÃO é teste da suíte;
## imprime FAIL e sai com 1
## se a geometria sair torta. Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fishing_book_shots.gd -- --out=fishing_09
## PNGs em build/screenshots/<out>/book_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

const HUD_HEIGHT := 168.0

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/fishing_09/"
var failures := 0


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
	for member: String in ["_celebration", "_welcome", "_growth_ceremony", "_quest_reward", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	var tutorial := main.find_child("AnglerTutorial", true, false)
	if tutorial != null:
		tutorial.queue_free()
	for hidden_name: String in ["Notice", "Toast", "MomentNotice"]:
		var extra := main.find_child(hidden_name, true, false) as CanvasItem
		if extra:
			extra.hide()


func _farm() -> Control:
	return main.find_child("World_farm", true, false) as Control


func _flow() -> Node:
	return _farm().call("fishing_flow") if _farm() != null else null


func _panel() -> Control:
	var node := _farm().find_child("FishingPanel", false, false) as Control
	return node if node != null and not bool(node.get("_closing")) else null


func _tabs_top() -> float:
	return (main.find_child("TabBarArt", true, false) as Control).global_position.y


## Chapter 5 aberto, Pesca nível 3 e o que cada tela precisa; sempre o jogo limpo antes.
func _fresh(rods: Array[String], fiber: int = 0, coins: int = 500) -> void:
	if _flow() != null:
		_flow().call("end")
	state.call("cancel_fishing")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("inventory").call("from_dict", {})
	state.get("fishing").xp = 100
	state.get("fishing").rods.clear()
	for rod in rods:
		state.call("give_rod", rod)
	state.get("fishing").tutorial["done"] = true
	state.get("inventory").add("fiber", fiber)
	state.get("inventory").add("bait_worm", 4)
	state.get("inventory").add("bait_dough", 4)
	state.get("inventory").add("bait_lure", 4)
	state.set("coins", coins)
	state.call("_changed")
	await create_timer(0.6).timeout
	_hide_modals()


func _snap(shot_name: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "book_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _measure(node: Control, label: String, button: bool = false, under_tabs: bool = true) -> void:
	if node == null or not node.is_visible_in_tree():
		_check(false, label + " visível")
		return
	var rect := node.get_global_rect()
	var screen := root.get_visible_rect()
	_check(rect.position.x >= -0.5 and rect.end.x <= screen.end.x + 0.5, "%s dentro da tela (%s)" % [label, rect])
	_check(rect.position.y >= HUD_HEIGHT - 45.0, "%s sob o HUD (y %.0f)" % [label, rect.position.y])
	if under_tabs:
		_check(rect.end.y <= _tabs_top() + 0.5, "%s sob as abas (fim %.0f, abas %.0f)" % [label, rect.end.y, _tabs_top()])
	if button:
		_check(rect.size.x >= 43.5 and rect.size.y >= 43.5, "%s alvo >= 44 (%s)" % [label, rect.size])


func _clipped(root_node: Node) -> void:
	for node in root_node.find_children("*", "Label", true, false):
		var label := node as Label
		if not label.is_visible_in_tree() or label.text == "" or label.autowrap_mode != TextServer.AUTOWRAP_OFF or label.clip_text:
			continue
		_check(label.size.x + 1.0 >= label.get_minimum_size().x or label.size.x < 1.0, "texto cortado: '%s'" % label.text)


func _record(id: String, cm: float, count: int, giants: int) -> void:
	state.get("fishing").records[id] = {"best_cm": cm, "best_class": "large", "count": count, "gigantes": giants, "perfects": 1, "first_at": 1.0}


func _open_book() -> void:
	sheet.call("close") if sheet.has_method("close") else null
	load("res://scripts/ui/pet_notebook.gd").call("open", "collection:fish")


func _check_book(label: String) -> void:
	await create_timer(0.8).timeout
	var book := main.find_child("PetNotebook", true, false) as Control
	_check(book != null, label + ": caderninho aberto")
	if book == null:
		return
	_measure(book, label + " caderninho", false, false)
	var sizes := {}
	for tile in book.find_children("Fish_*", "Button", true, false):
		var rect := (tile as Control).get_global_rect()
		sizes[Vector2(roundf(rect.size.x), roundf(rect.size.y))] = true
		_check(rect.position.x >= -0.5 and rect.end.x <= root.get_visible_rect().end.x + 0.5, label + " " + tile.name + " dentro da tela")
	_check(sizes.size() == 1, label + ": quadradinhos iguais " + str(sizes.keys()))
	_clipped(book)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fishing_book_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	main.call("show_screen", &"pet")
	await create_timer(1.0).timeout
	_hide_modals()

	# 1) Vazio: só a vara de bambu, nada pego.
	await _fresh(["bamboo_rod"])
	_open_book()
	await _check_book("vazio")
	await _snap("a_vazio")

	# 2) Meio: dois pegos, um Gigante.
	await _fresh(["bamboo_rod", "reel_rod"])
	_record("fish_lambari", 12.5, 6, 1)
	_record("fish_cara", 15.0, 2, 0)
	_record("fish_carp", 48.0, 1, 0)
	state.call("_changed")
	_open_book()
	await _check_book("meio")
	await _snap("b_meio")

	# 3) Completo com Gigantes.
	await _fresh(["bamboo_rod", "reel_rod", "angler_rod"])
	var db: Node = root.get_node("Database")
	for id: String in db.get("fishing").fish:
		var range: Array = db.get("fishing").fish[id].cm
		_record(id, float(range[1]) * 0.97, 4, 1)
	state.call("_changed")
	_open_book()
	await _check_book("completo")
	await _snap("c_completo")

	# 4) Detalhe de um pego e de um não pego.
	await _fresh(["bamboo_rod"])
	_record("fish_lambari", 13.2, 5, 1)
	state.call("_changed")
	load("res://scripts/ui/codex_sections.gd").call("fish_open", "fish_lambari")
	await create_timer(0.8).timeout
	var detail := main.find_child("CodexDetail", true, false) as Control
	_check(detail != null, "detalhe do pego aberto")
	if detail != null:
		_measure(detail, "detalhe pego", false, false)
		_clipped(detail)
		var go := detail.find_child("FishGo", true, false) as Control
		_measure(go, "Ir pescar", true, false)
	await _snap("d_detalhe_pego")
	load("res://scripts/ui/codex_sections.gd").call("fish_open", "fish_cara")
	await create_timer(0.8).timeout
	detail = main.find_child("CodexDetail", true, false) as Control
	_check(detail != null and detail.find_child("FishNever", true, false) != null, "detalhe do não pego")
	await _snap("e_detalhe_nao_pego")

	print("FISHING BOOK SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
