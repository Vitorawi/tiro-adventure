extends SceneTree
## Etapa 08 das Fotos: capturas do varal na home. NÃO é teste. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fotos_08_shots.gd -- --out=fotos_08
## PNGs em build/screenshots/<out>/varal_<largura>x<altura>_<caso>.png; imprime "FAIL ..." na auditoria de geometria.
## Usa save descartável (nenhuma escrita no save pessoal).

var state: Node
var main: Node
var pet: Control
var folder := "fotos_08"
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
	var line: Control = pet.find_child("PhotoLine", true, false)
	if line == null or not line.visible: return
	var screen := root.get_visible_rect()
	var head: Rect2 = pet.call("head_rect")
	var others: Dictionary = {
		"NeedsPanel": main.find_child("NeedsPanel", true, false),
		"WishBubble": pet.find_child("WishBubble", true, false),
		"ManualButton": pet.find_child("ManualButton", true, false),
		"CareButton": pet.find_child("CareButton", true, false),
	}
	for child in line.get_children():
		if not child is Button: continue
		var rect := (child as Control).get_global_rect()
		if not screen.encloses(rect): _fail("%s: %s fora da tela" % [label, child.name])
		if rect.size.x < 71.9 or rect.size.x > 84.1: _fail("%s: %s com %s px" % [label, child.name, rect.size.x])
		if rect.size.x < 44.0 or rect.size.y < 44.0: _fail("%s: alvo menor que 44" % label)
		if rect.position.y < 168.0: _fail("%s: %s sob o HUD" % [label, child.name])
		if rect.intersects(head): _fail("%s: %s cobre a cabeça" % [label, child.name])
		for key: String in others:
			var node: Control = others[key]
			if node != null and node.is_visible_in_tree() and rect.intersects(node.get_global_rect()):
				_fail("%s: %s cobre %s" % [label, child.name, key])


func shot(label: String, wait: float = 0.9) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	_audit(label)
	var path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/")
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "varal_%dx%d_%s.png" % [image.get_width(), image.get_height(), label])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer: child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fotos_08_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_mark_all_seen")
	state.set("coins", 800)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	pet = main.find_child("PetScreen", true, false)
	pet.set("preview_hour", 12)
	main.call("show_screen", &"pet")
	state.call("dev_fill_needs")
	state.call("dev_refresh_wishes")
	await shot("0_sem_foto", 0.5)
	# Foto aberta, nada em destaque: três espaços "+".
	state.call("dev_take_photo", "h_arrival", 1)
	await shot("1_vazio")
	state.call("feature_photo", "h_arrival")
	await shot("2_uma")
	state.call("dev_take_photo", "f_bath", 4)
	state.call("dev_take_photo", "f_taste", 3)
	state.call("feature_photo", "f_bath")
	state.call("feature_photo", "f_taste")
	await shot("3_tres_holografica")
	# Dormindo.
	state.get("dog").sleeping = true
	state.call("_changed")
	await shot("4_dormindo")
	state.get("dog").sleeping = false
	# Passeando: o varal some.
	state.call("dev_unlock_everything")
	state.call("dev_set_phase", "adult")
	state.call("start_walk", "park_loop")
	state.call("_changed")
	await create_timer(0.6).timeout
	_hide_modals()
	await shot("5_passeando", 0.5)
	print("FOTOS 08 SHOTS: ", "PASS" if failures == 0 else "FALHAS=%d" % failures)
	quit(failures)
