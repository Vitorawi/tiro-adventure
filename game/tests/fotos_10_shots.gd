extends SceneTree
## Etapa 10 das Fotos: capturas dos cartões de marco (seção completa, quatro versões, primeira Holográfica)
## e do álbum com medalhão/4/4/"Mais N Raras". NÃO é teste. Rodar SEM --headless, uma vez por resolução:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fotos_10_shots.gd -- --out=fotos_10
## PNGs em build/screenshots/<out>/marco_<largura>x<altura>_<nome>.png; "FAIL ..." na auditoria.
## Usa save descartável (nenhuma escrita no save pessoal).

var state: Node
var main: Node
var folder := "fotos_10"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(120.0).timeout.connect(func() -> void: quit(1))


func _fail(message: String) -> void:
	failures += 1
	print("FAIL ", message)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: (node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree(): (intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _audit(label: String) -> void:
	var screen := root.get_visible_rect()
	var panel := main.get("_celebration").find_child("CardPanel", true, false) as Control
	if panel == null:
		_fail("%s: sem cartão" % label)
		return
	if not screen.encloses(panel.get_global_rect()): _fail("%s: cartão fora da tela %s" % [label, panel.get_global_rect()])
	var greens := 0
	for button in panel.find_children("*", "Button", true, false):
		var control := button as Control
		if not control.is_visible_in_tree(): continue
		if control.size.y < 44.0: _fail("%s: botão %s menor que 44 (%s)" % [label, control.name, control.size])
		if control.has_meta("wood_primary"): greens += 1
	if greens != 1: _fail("%s: esperado 1 botão verde, achei %d" % [label, greens])


func shot(label: String, wait: float = 1.2) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/")
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "marco_%dx%d_%s.png" % [image.get_width(), image.get_height(), label])


func _celebrate(kind: String, key: String, label: String) -> void:
	main.get("_celebration").call("show_album_milestone", kind, key)
	await shot(label)
	_audit(label)
	main.get("_celebration").hide()


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer: child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fotos_10_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var intro: Array[String] = ["intro"]
	state.call("mark_seen", intro)
	state.call("note_screen_opened", "album")
	main.call("show_screen", &"pet")
	await create_timer(0.5).timeout
	_hide_modals()
	# Dados: seção da história quase completa, uma foto com as 4 versões e quatro Raras.
	var story: Array[String] = []
	for entry: Dictionary in root.get_node("Database").album.photos:
		if str(entry.section) == "story": story.append(str(entry.id))
	for id in story:
		state.call("dev_take_photo", id, 3)
	state.call("dev_take_photo", story[0], 1)
	state.call("dev_take_photo", story[0], 2)
	state.call("dev_take_photo", story[0], 4)
	await create_timer(0.3).timeout
	_hide_modals()
	await _celebrate("section", "story", "1_secao")
	await _celebrate("styles", story[0], "2_quatro_versoes")
	await _celebrate("holo", "first", "3_holografica")
	await _celebrate("rare", "5", "4_raras")
	# Álbum: título com ✓, "4/4" na carta e próximo marco.
	load("res://scripts/ui/pet_notebook.gd").call("open", "album:story")
	await shot("5_album", 1.0)
	var screen := root.get_visible_rect()
	for node_name in ["SectionComplete", "StylesComplete", "NextMilestone"]:
		var node := main.find_child(node_name, true, false) as Control
		if node == null:
			if node_name == "NextMilestone" and int(state.call("rare_plus_count")) >= 5: continue
			_fail("5_album: falta %s" % node_name)
		elif not screen.encloses(node.get_global_rect()): _fail("5_album: %s fora da tela" % node_name)
	print("FOTOS 10 SHOTS: ", "PASS" if failures == 0 else "FALHAS=%d" % failures)
	quit(failures)
