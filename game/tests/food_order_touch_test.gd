extends "res://tests/food_menu_bounds_touch_test.gd"
## Ordem do catálogo, independente de uso, estoque, remoção/reinserção e reconstrução.
const STANDARD: Array[String] = ["dog_food", "carrot", "strawberry"]
var before := false
var snapshots := false

func food_order() -> Array[String]:
	var result: Array[String] = []
	var menu := pet.find_child("FoodMenu", true, false)
	for item: Control in menu.get("grid").get_children():
		result.append(str(item.name).trim_prefix("Care_"))
	return result

func check_order() -> void:
	var expected: Array[String] = []
	for id: String in STANDARD:
		if state.get("inventory").count(id) > 0: expected.append(id)
	check(food_order() == expected, "ordem padrão: %s (veio %s)" % [expected, food_order()])
	check(tray.call("food_ids") == expected, "fonte e grade concordam")

func touch_node(id: String) -> void:
	var target := main.find_child(id, true, false) as Control
	check(target != null and target.is_visible_in_tree(), "alvo visível: " + id)
	if target: await tap(target.get_global_rect().get_center())

func open_food() -> void:
	tray.call("close_food_menu")
	await touch_node("CareButton")
	await touch_node("FoodButton")
	check(pet.find_child("FoodMenu", true, false).visible, "Comida abre por ScreenTouch")

func consume(id: String) -> void:
	state.get("dog").needs.hunger = 10.0
	var quantity: int = state.get("inventory").count(id)
	var feeds: int = state.get("progress").stat("feed")
	await touch_node("Care_" + id)
	await frames()
	check(state.get("inventory").count(id) == quantity - 1, "consome uma unidade de " + id)
	check(state.get("progress").stat("feed") == feeds + 1, "uma alimentação de " + id)
	check(state.get("dog").get_need("hunger", state.call("now")) > 10.0, "efeito da comida preservado")

func shot(stage: int) -> void:
	if not snapshots: return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/prato_ordem/")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder + "%s_%dx%d_%d.png" % ["antes" if before else "depois", root.size.x, root.size.y, stage]) == OK, "captura")

func choice_order(id: String) -> Array[String]:
	var result: Array[String] = []
	var window := main.find_child(id, true, false)
	for item: Control in window.get("grid").get_children():
		result.append(str(item.name).trim_suffix("Locked"))
	return result

func shared_choices() -> void:
	tray.call("close_food_menu")
	state.get("growth").phase = "explorer"
	state.get("inventory").add("herb_shampoo", 2)
	state.get("inventory").add("carrot_snack", 2)
	state.call("_changed")
	await frames()
	for i in 2:
		await touch_node("CareButton")
		await touch_node("Care_sponge")
		check(choice_order("BathChoice") == ["BathPlain", "BathShampoo"], "banho conserva ordem ao consumir xampu")
		await touch_node("BathShampoo")
	await touch_node("CareButton")
	await touch_node("Care_sponge")
	check(choice_order("BathChoice") == ["BathPlain", "BathShampoo"], "opção bloqueada mantém posição")
	state.get("inventory").add("herb_shampoo", 1)
	state.call("_changed")
	await frames()
	check(choice_order("BathChoice") == ["BathPlain", "BathShampoo"], "repor xampu mantém posição")
	tray.call("close_food_menu")
	await touch_node("CareButton")
	await touch_node("Care_ball")
	check(choice_order("PlayChoice") == ["PlayBall", "PlayCups"], "Bola/Copinhos têm ordem fixa")
	await touch_node("PlayBall")
	await touch_node("CareButton")
	await touch_node("Care_ball")
	check(choice_order("PlayChoice") == ["PlayBall", "PlayCups"], "brincar não reordena opções")
	tray.call("close_food_menu")

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	Input.emulate_mouse_from_touch = true
	before = "--before" in OS.get_cmdline_user_args()
	snapshots = "--shots" in OS.get_cmdline_user_args()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	pet = main.find_child("PetScreen", true, false)
	tray = pet.find_child("CareTray", true, false)
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = resolution
		tray.call("cancel")
		state.call("reset")
		state.get("progress").seen.intro = true
		# Inserção inversa no inventário: a fonte da posição deve ser o catálogo.
		state.get("inventory").call("from_dict", {"strawberry": 14, "carrot": 1, "dog_food": 9})
		if before: tray.get_script().set("recent_foods", [] as Array[String])
		state.call("_changed")
		await frames()
		await open_food()
		var initial := food_order()
		await shot(1)
		if not before: check_order()
		await consume("strawberry")
		await shot(2)
		if before:
			check(initial != food_order(), "reproduz troca de posição no código anterior")
			print("ANTES %s: %s -> %s" % [resolution, initial, food_order()])
			continue
		check_order()
		for id: String in ["strawberry", "strawberry", "dog_food", "carrot"]:
			await consume(id)
			check_order()
		check(food_order() == ["dog_food", "strawberry"], "acabou cenoura: demais mantêm ordem relativa")
		state.get("inventory").add("carrot", 2)
		state.call("_changed")
		await frames()
		check_order()
		await consume("carrot")
		check_order()
		# Histórico e quantidades contradizem a ordem; rebuild e reabertura não podem mudar posição.
		state.get("progress").stats["feed:strawberry"] = 100
		state.get("inventory").add("strawberry", 50)
		state.call("_changed")
		await frames()
		check_order()
		await open_food()
		check_order()
		await shared_choices()
		print("FOOD ORDER %s: verificado" % resolution)
	print("FOOD ORDER TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
