extends SceneTree
## Cuidar > Comida pelo viewport: miolo creme, linhas e uso de uma comida.
var failures := 0
var main: Control
var pet: Control
var tray: Control
var state: Node

func _initialize() -> void:
	_run.call_deferred()

func frames(n: int = 6) -> void:
	for i in n: await process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FOOD MENU BOUNDS: " + message)

func tap(point: Vector2) -> void:
	for down: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = root.get_final_transform() * point
		event.pressed = down
		Input.parse_input_event(event)
		await frames(2)
	await frames()

func fixture(count: int) -> void:
	tray.call("close_food_menu")
	tray.call("close_wheel")
	var inventory := {"dog_food": 9, "carrot_snack": 1, "apple_biscuit": 1, "carrot": 4, "strawberry": 15}
	var database := root.get_node("Database")
	for id: String in database.get("items"):
		if database.get("items")[id].has("feed") and not inventory.has(id): inventory[id] = 10
	var selected := {}
	for id: String in inventory:
		if selected.size() == count: break
		selected[id] = inventory[id]
	state.get("inventory").call("from_dict", selected)
	state.get("dog").needs.hunger = 10.0
	state.call("_changed")
	await frames()
	await tap((tray.find_child("CareButton", true, false) as Control).get_global_rect().get_center())
	check(tray.find_child("CareWheelOpen", true, false).visible, "toque abre Cuidar")
	await tap((tray.find_child("FoodButton", true, false) as Control).get_global_rect().get_center())
	check(pet.find_child("FoodMenu", true, false).visible, "toque abre Comida")
	await frames()

## Limites reais do creme no NinePatch: amostra o arquivo de arte e converte sua coordenada
## pela mesma divisão canto/centro do desenho, sem confundir painel externo com área branca.
func mapped(pixel: float, source: float, target: float, start: float, finish: float) -> float:
	if pixel <= start: return pixel / 3.0
	if pixel >= source - finish: return target - (source - pixel) / 3.0
	return start / 3.0 + (pixel - start) / (source - start - finish) * (target - (start + finish) / 3.0)

func cream_rect(menu: Control) -> Rect2:
	var frame := menu.get_node("Art/Frame") as NinePatchRect
	var image := frame.texture.get_image()
	var top := 0
	var bottom := image.get_height() - 1
	var x := image.get_width() / 2
	while image.get_pixel(x, top).r < 0.9 or image.get_pixel(x, top).g < 0.78: top += 1
	while image.get_pixel(x, bottom).r < 0.9 or image.get_pixel(x, bottom).g < 0.78: bottom -= 1
	var y0 := mapped(top, image.get_height(), menu.size.y, frame.patch_margin_top, frame.patch_margin_bottom)
	var y1 := mapped(bottom, image.get_height(), menu.size.y, frame.patch_margin_top, frame.patch_margin_bottom)
	# Filetes escuros e cantos redondos: mais 4 px de folga vertical no miolo.
	return Rect2(menu.global_position + Vector2(16, y0 + 4), Vector2(menu.size.x - 32, y1 - y0 - 8))

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	Input.emulate_mouse_from_touch = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	pet = main.find_child("PetScreen", true, false)
	tray = pet.find_child("CareTray", true, false)
	var before := "--before" in OS.get_cmdline_user_args()
	var shots_only := "--shots-only" in OS.get_cmdline_user_args()
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = resolution
		for count: int in ([5] if before or shots_only else [1, 5, 9, 14]):
			await fixture(count)
			var menu := pet.find_child("FoodMenu", true, false) as Control
			var scroll := menu.find_child("FoodScroll", true, false) as ScrollContainer
			var grid := scroll.get_child(0) as GridContainer
			var cream := cream_rect(menu)
			print("FOOD %s count=%d menu=%s cream=%s scroll=%s grid=%s" % [resolution, count, menu.get_global_rect(), cream, scroll.get_global_rect(), grid.size])
			if count == 5 and "--shots" in OS.get_cmdline_user_args():
				await RenderingServer.frame_post_draw
				var folder := ProjectSettings.globalize_path("res://../build/screenshots/bandeja_comida/")
				DirAccess.make_dir_recursive_absolute(folder)
				root.get_texture().get_image().save_png(folder + ("antes" if before else "depois") + "_%dx%d.png" % [resolution.x, resolution.y])
			if before: continue
			check(pet.get_global_rect().encloses(menu.get_global_rect()), "bandeja dentro da tela")
			var bar := main.find_child("TabBar", true, false) as Control
			check(menu.get_global_rect().end.y <= bar.global_position.y - 8, "não cobre barra inferior")
			check(cream.encloses(scroll.get_global_rect()), "janela de comidas dentro do creme com margem")
			check(grid.get_child_count() == count, "quantidade de comidas da fixture")
			for item: Control in grid.get_children():
				scroll.ensure_control_visible(item)
				await frames(2)
				check(cream.encloses(item.get_global_rect()), "item inteiro no creme ao alcançar " + str(item.name))
				check(scroll.get_global_rect().encloses(item.get_global_rect()), "item alcançável inteiro")
			if count == 1:
				var food := grid.get_child(0) as Control
				var quantity: int = state.get("inventory").count("dog_food")
				await tap(food.get_global_rect().get_center())
				check(state.get("inventory").count("dog_food") == quantity - 1, "toque alimenta uma vez")
				check(not menu.visible, "escolher a comida fecha o menu e deixa a animação visível")
		print("COMIDA %s: verificado" % resolution)
	print("FOOD MENU BOUNDS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
