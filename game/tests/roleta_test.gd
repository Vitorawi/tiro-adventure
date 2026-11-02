extends SceneTree
## Regressão da roleta: ScreenTouch emulado, opções e geometria nas três telas.
var state: Node
var main: Control
var tray: Control
var failures := 0
var before := false
var shots := false

func _initialize() -> void:
	before = "--before" in OS.get_cmdline_user_args()
	shots = "--shots" in OS.get_cmdline_user_args()
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("ROLETA: " + message)

func frames(n: int = 5) -> void:
	for i in n: await process_frame

func node(id: String) -> Control:
	return main.find_child(id, true, false) as Control

func tap(control: Control) -> void:
	check(control != null and control.is_visible_in_tree(), "alvo de toque visível")
	if control == null: return
	var point := root.get_final_transform() * control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames(2)
	await frames()

func shot(kind: String) -> void:
	if not shots: return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/roleta/")
	DirAccess.make_dir_recursive_absolute(folder)
	var image := root.get_texture().get_image()
	check(image.save_png(folder + "%s_%dx%d_%s.png" % ["antes" if before else "depois", root.size.x, root.size.y, kind]) == OK, "salvar captura")

func fresh() -> void:
	var catcher := node("PopoverCatcher")
	if catcher: catcher.free()
	tray.call("cancel")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("growth").phase = "explorer"
	state.get("inventory").call("from_dict", {"dog_food": 5, "basic_brush": 1, "herb_shampoo": 2, "carrot_snack": 2})
	for need: String in ["hunger", "happiness", "energy", "hygiene"]:
		state.get("dog").needs[need] = 100.0
	state.get("dog").needs.hunger = 5.0
	state.call("_changed")
	await frames()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	Input.emulate_mouse_from_touch = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	main.call("show_screen", &"pet")
	tray = node("CareTray")
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = resolution
		await frames(12)
		await fresh()
		await tap(node("CareButton"))
		check(node("CareWheelOpen").visible, "abre a roleta em " + str(resolution))
		await shot("roleta")
		if not before: _check_badges()
		state.get("dog").needs.hygiene = 10.0
		state.call("_changed")
		await tap(node("Care_sponge"))
		await shot("popup_banho")
		if before: continue # Antes: o toque já dá banho; não existe popup para capturar.
		check(node("BathChoice") != null, "banho abre o popup normal")
		check(node("BathPlain") != null and node("BathShampoo") != null, "duas opções de banho")
		var popup := node("Popover")
		check(popup != null and node("PetScreen").get_global_rect().encloses(popup.get_global_rect()), "popup inteiro na tela")
		check(popup != null and popup.get_global_rect().end.y < node("CareButton").global_position.y, "popup acima de Cuidar e das abas")
		check(state.get("progress").call("stat", "bathe") == 0, "abrir não executa banho")
		await tap(node("BathShampoo"))
		check(state.get("inventory").call("count", "herb_shampoo") == 1, "com xampu consome exatamente um")
		check(state.get("progress").call("stat", "shampoo_bath") == 1, "registra banho com xampu")
		check(state.get("dog").needs.hygiene > 10.0, "banho com xampu limpa")
		state.get("dog").needs.hygiene = 10.0
		state.call("_changed")
		await tap(node("CareButton"))
		await tap(node("Care_sponge"))
		await tap(node("BathPlain"))
		check(state.get("inventory").call("count", "herb_shampoo") == 1, "sem xampu não consome")
		check(state.get("dog").needs.hygiene > 10.0, "banho comum limpa")
		check(state.get("progress").call("stat", "bathe") == 2 and state.get("progress").call("stat", "shampoo_bath") == 1, "sem xampu executa somente banho comum")
		state.get("inventory").call("remove", "herb_shampoo", 1)
		await tap(node("CareButton"))
		await tap(node("Care_sponge"))
		check(node("BathShampooLocked") != null and node("BathShampoo") == null, "sem estoque explica o xampu ausente")
		await tap(node("BathPlain"))
		await tap(node("CareButton"))
		await tap(node("Care_ball"))
		check(node("PlayChoice") != null and node("PlayBall") != null and node("PlayCups") != null, "outro cuidado com várias opções usa popup")
		await tap(node("PlayBall"))
		check(state.get("progress").call("stat", "play") == 1, "opção Bola executa")
		state.get("growth").phase = "puppy"
		state.call("_changed")
		await tap(node("CareButton"))
		await tap(node("Care_ball"))
		check(node("PlayChoice") == null and state.get("progress").call("stat", "play") == 2, "uma opção executa direto")
		print("ROLETA RESOLUTION PASS: ", resolution)
	print("ROLETA TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)

func _check_badges() -> void:
	var food := node("FoodButton")
	check(food.get_node_or_null("MomentSpark") == null, "sem selo amarelo na comida")
	check(node("ShampooToggle") == null, "sem texto flutuante Com xampu")
	for control: Control in main.find_children("*", "Control", true, false):
		if (control is Label or control is Button) and control.is_visible_in_tree():
			check(control.text != "Com xampu", "Com xampu só aparece dentro do popup")
	var dot := food.get_node("AskDot") as Control
	check(dot.is_visible_in_tree(), "fome acende bolinha")
	check(food.get_global_rect().encloses(dot.get_global_rect()), "bolinha inteira dentro do cartão")
	check(dot.z_index > 0, "bolinha acima da arte")
	if shots:
		var pixel := Vector2i(root.get_final_transform() * dot.get_global_rect().get_center())
		var color := root.get_texture().get_image().get_pixelv(pixel)
		check(color.is_equal_approx(Palette.ALERT), "pixel central vermelho confirma bolinha sem cobertura")
	var ancestor := dot.get_parent() as Control
	while ancestor:
		check(not ancestor.clip_contents or ancestor.get_global_rect().encloses(dot.get_global_rect()), "nenhum ancestral corta a bolinha")
		ancestor = ancestor.get_parent() as Control
	for disc: Control in node("CareWheelOpen").get_children():
		if disc != food: check(not disc.get_global_rect().intersects(dot.get_global_rect()), "outro cartão não cobre bolinha")
	state.get("dog").needs.hunger = 100.0
	state.call("_changed")
	check(not dot.visible, "sem fome não acende bolinha")
