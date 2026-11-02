extends "res://tests/food_menu_bounds_touch_test.gd"
## Mesmo roteiro real da comida, aplicado ao catálogo completo da roleta.
var snapshots := false
var before := false
var snapshots_only := false

func control(id: String) -> Control:
	return main.find_child(id, true, false) as Control

func touch_node(id: String) -> void:
	var node := control(id)
	check(node != null and node.is_visible_in_tree(), "toque visível: " + id)
	if node != null: await tap(node.get_global_rect().get_center())

func fresh(phase: String = "explorer") -> void:
	tray.call("cancel")
	var catcher := pet.get_node_or_null("PopoverCatcher")
	if catcher: catcher.free()
	state.call("reset")
	state.get("progress").seen.intro = true
	state.get("growth").phase = phase
	state.get("inventory").call("from_dict", {"dog_food": 9, "carrot": 4, "carrot_snack": 2, "strawberry": 15, "apple_biscuit": 1, "basic_brush": 1, "herb_shampoo": 2})
	for need: String in ["hunger", "hygiene", "happiness", "energy"]:
		state.get("dog").needs[need] = 30.0
	state.call("_changed")
	await frames()

func open_item(id: String) -> void:
	await touch_node("CareButton")
	await touch_node(id)

func capture(id: String) -> void:
	if not snapshots: return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/roda_janelinha/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + "%s_%s_%dx%d.png" % [id, "antes" if before else "depois", root.size.x, root.size.y])

func bounds(window: Control) -> void:
	check(window != null and window.visible, "janelinha visível")
	if window == null: return
	check(window.get_script() == load("res://scripts/ui/care_choice_window.gd"), "construtor compartilhado")
	check(window.get_meta("care_choice_window", false), "contrato compartilhado")
	var body := window.get_node("Body") as Control
	check(body.get_theme_constant("margin_top") == 20 and body.get_theme_constant("margin_bottom") == 28, "margens 20/28")
	check(pet.get_global_rect().encloses(window.get_global_rect()), "janela dentro da tela")
	check(window.get_global_rect().end.y <= control("TabBar").global_position.y - 8, "janela acima da barra")
	var cream := cream_rect(window)
	var scroll := window.get("scroll") as ScrollContainer
	var grid := window.get("grid") as GridContainer
	check(cream.encloses(scroll.get_global_rect()), "rolagem dentro do creme")
	for tile: Control in grid.get_children():
		scroll.ensure_control_visible(tile)
		await frames(2)
		check(cream.encloses(tile.get_global_rect()), "tile dentro do creme: " + str(tile.name))
		check(tile.has_node("FoodDisc") and tile.has_node("CareIcon") and tile.has_node("Quantity"), "mesmo tile com ícone/contador")

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	Input.emulate_mouse_from_touch = true
	snapshots = "--shots" in OS.get_cmdline_user_args()
	before = "--before" in OS.get_cmdline_user_args()
	snapshots_only = "--shots-only" in OS.get_cmdline_user_args()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	pet = control("PetScreen")
	tray = control("CareTray")
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = resolution
		for pair: Array in [["comida", "FoodButton", "FoodMenu"], ["banho", "Care_sponge", "BathChoice"], ["escova", "BrushTile", ""], ["brincar", "Care_ball", "PlayChoice"]]:
			await fresh()
			await open_item(str(pair[1]))
			await capture(str(pair[0]))
			if before: continue
			if str(pair[2]) != "": await bounds(control(str(pair[2])))
			else:
				check(not control("FoodMenu").visible and not control("CareChoice").visible, "escova não inventa escolhas; orienta o gesto")
				continue
			if snapshots_only: continue
			if pair[0] == "comida":
				var quantity: int = state.get("inventory").count("dog_food")
				await touch_node("Care_dog_food")
				check(state.get("inventory").count("dog_food") == quantity - 1, "comida executa uma vez")
			elif pair[0] == "banho":
				check(state.get("progress").stat("bathe") == 0, "abrir banho não executa")
				check((control("BathShampoo").get_node("Quantity") as Label).text == "×2", "contador do xampu")
				var point := control("BathShampoo").get_global_rect().get_center()
				await tap(point)
				await tap(point)
				check(state.get("inventory").count("herb_shampoo") == 1 and state.get("progress").stat("shampoo_bath") == 1, "xampu consome/aplica uma vez no toque duplo")
				await open_item("Care_sponge")
				await touch_node("BathPlain")
				check(state.get("inventory").count("herb_shampoo") == 1 and state.get("progress").stat("bathe") == 2, "banho comum sem custo de xampu")
				await open_item("Care_sponge")
				state.get("inventory").remove("herb_shampoo", 1)
				state.call("_changed")
				await frames()
				check((control("BathShampooLocked") as Button).disabled, "estoque muda: bloqueio atualizado sem recriar janela")
				await tap(control("BathShampooLocked").get_global_rect().get_center())
				check(state.get("progress").stat("bathe") == 2, "opção bloqueada não executa")
			elif pair[0] == "brincar":
				await touch_node("PlayBall")
				check(state.get("progress").stat("play") == 1, "bola executa uma vez")
				await open_item("Care_ball")
				var treats: Array = state.call("hide_treats")
				var quantity: int = state.get("inventory").count(treats[0])
				await touch_node("PlayCups")
				check(main.find_child("HideSeek", true, false) != null, "copinhos inicia o mesmo minijogo")
				check(state.get("inventory").count(treats[0]) == quantity - 1 and state.get("hide_pending"), "copinhos consome exatamente um petisco")
				root.get_node("Events").emit_signal("sheet_close_requested")
		if before or snapshots_only: continue
		await fresh("puppy")
		await open_item("Care_ball")
		check(state.get("progress").stat("play") == 1 and not control("CareChoice").visible, "só Bola: ação direta")
		await open_item("SleepButton")
		check(state.get("dog").sleeping and not control("CareChoice").visible, "Dormir: ação direta")
		print("CARE CHOICE %s: verificado" % resolution)
	print("CARE CHOICE WINDOW TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
