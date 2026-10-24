extends SceneTree
## Interface 2, etapa 04: o botão Cuidar abre a roleta; cuidados por toque e arrasto, atalho do pedido,
## sono, alfinete e Menos animação.

var KIT: Script
var failures: int = 0
var state: Node
var main: Control
var pet: Control
var tray: Control


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("CARE WHEEL: " + message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func node(node_name: String) -> Control:
	return main.find_child(node_name, true, false) as Control


func mouse(kind: String, point: Vector2) -> InputEvent:
	if kind == "move":
		var motion := InputEventMouseMotion.new()
		motion.global_position = point
		motion.position = point
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		return motion
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.pressed = kind == "press"
	button.global_position = point
	button.position = point
	return button


## Toque completo (aperta e solta) num disco: o mesmo caminho do dedo.
func tap_disc(disc: Control) -> void:
	var center := disc.get_global_rect().get_center()
	disc.gui_input.emit(mouse("press", center))
	disc.gui_input.emit(mouse("release", center))


func wheel_open() -> bool:
	return node("CareWheelOpen").visible


func discs() -> Array[Control]:
	var result: Array[Control] = []
	for child: Node in node("CareWheelOpen").get_children():
		if child is Button: result.append(child as Control)
	return result


func fresh() -> void:
	state.call("set_sleeping", false)
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("inventory").call("from_dict", {"dog_food": 5})
	var dog: Object = state.get("dog")
	for need: String in ["hunger", "happiness", "energy", "hygiene"]:
		dog.needs[need] = 100.0
	tray.call("close_wheel")
	tray.call("close_food_menu")
	state.call("_changed")
	await frames()


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	KIT = load("res://scripts/ui/ui_kit.gd")
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames()
	main.call("show_screen", &"pet")
	pet = node("PetScreen")
	tray = node("CareTray")
	await _caso_fechado()
	await _caso_hud_abas()
	await _caso_abrir_e_ordem()
	await _caso_espacamento()
	await _caso_fechar()
	await _caso_comida()
	await _caso_banho()
	await _caso_arrastar_comida()
	await _caso_pedido()
	await _caso_dormindo()
	await _caso_alfinete()
	await _caso_menos_animacao()
	Motion.reduced = false
	print("CARE WHEEL TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)


func _caso_fechado() -> void:
	await fresh()
	var button := node("CareButton")
	check(button != null and button.is_visible_in_tree(), "fechado: o botão Cuidar aparece")
	check(not wheel_open(), "fechado: a roleta está escondida")
	var bar := main.get_node("Layout/TabBar") as Control
	var center := button.get_global_rect().get_center()
	check(center.y <= bar.global_position.y - 8.0, "o centro do botão fica acima do rodapé, com folga (%s × %s)" % [center.y, bar.global_position.y])
	check(is_equal_approx(center.x, pet.get_global_rect().get_center().x), "o botão fica no meio da tela")


func _caso_abrir_e_ordem() -> void:
	await fresh()
	var center := node("CareButton").get_global_rect().get_center()
	root.push_input(mouse("press", center), true)
	await process_frame
	root.push_input(mouse("release", center), true)
	await frames()
	check(wheel_open(), "tocar no botão abre a roleta")
	for disc_name: String in ["FoodButton", "Care_sponge", "Care_ball", "SleepButton"]:
		check(node(disc_name).is_visible_in_tree(), "disco visível: " + disc_name)
	check(discs().size() == 4, "sem a escova há 4 discos (%d)" % discs().size())
	check(node("BrushTile") == null, "sem a escova não há Escovar")
	state.get("inventory").call("add", "basic_brush", 1)
	state.call("_changed")
	await frames()
	var names: Array[String] = []
	for disc: Control in discs(): names.append(str(disc.name))
	check(names == ["FoodButton", "Care_sponge", "BrushTile", "Care_ball", "SleepButton"], "com a escova: 5 discos na ordem de sempre: " + str(names))


func _caso_espacamento() -> void:
	# Segue do caso anterior: roleta aberta com cinco discos.
	var list := discs()
	for i in list.size():
		var rect := list[i].get_global_rect()
		check(Rect2(4, 4, 352, 772).encloses(rect), "disco dentro da tela: " + str(list[i].name))
		if i > 0:
			var gap := rect.get_center().distance_to(list[i - 1].get_global_rect().get_center())
			check(gap >= 80.0, "discos vizinhos a ≥ 80 px (%s: %.1f)" % [list[i].name, gap])


func _caso_fechar() -> void:
	await fresh()
	(node("CareButton") as Button).pressed.emit()
	await frames()
	check(wheel_open(), "abriu para testar o fechar")
	node("CareWheelOpen").gui_input.emit(mouse("press", Vector2(180, 120)))
	await frames()
	check(not wheel_open(), "tocar fora dos discos fecha")
	(node("CareButton") as Button).pressed.emit()
	await frames()
	(node("CareButton") as Button).pressed.emit()
	await frames()
	check(not wheel_open(), "tocar no botão de novo fecha")


func _caso_comida() -> void:
	await fresh()
	(node("CareButton") as Button).pressed.emit()
	await frames()
	(node("FoodButton") as Button).pressed.emit()
	await frames()
	check(not wheel_open(), "Comida fecha a roleta")
	var menu := node("FoodMenu")
	check(menu.visible, "Comida abre o FoodMenu")
	check(menu.get_global_rect().end.y < node("CareButton").global_position.y, "o FoodMenu fica acima do botão Cuidar")
	tray.call("close_food_menu")


func _caso_banho() -> void:
	await fresh()
	state.get("dog").needs.hygiene = 20.0
	state.call("_changed")
	(node("CareButton") as Button).pressed.emit()
	await frames()
	var before: float = state.get("dog").call("get_need", "hygiene", state.call("now"))
	tap_disc(node("Care_sponge"))
	await frames()
	var after: float = state.get("dog").call("get_need", "hygiene", state.call("now"))
	check(after > before, "tocar e soltar o Banho dá banho (%s → %s)" % [before, after])
	check(not wheel_open(), "escolher um cuidado fecha a roleta")


func _caso_arrastar_comida() -> void:
	await fresh()
	state.get("dog").needs.hunger = 10.0
	state.call("_changed")
	tray.call("open_food_menu")
	await frames()
	var before: float = state.get("dog").call("get_need", "hunger", state.call("now"))
	var start: Vector2 = tray.call("item_center", "dog_food")
	var head: Rect2 = pet.call("head_rect")
	var target := head.get_center() + Vector2(0, 40)
	tray.call("press_item", "dog_food", start)
	tray.call("move_item", target)
	tray.call("move_item", target)
	tray.call("release_item", target)
	await frames()
	var after: float = state.get("dog").call("get_need", "hunger", state.call("now"))
	check(after > before, "arrastar a comida até a cabeça alimenta (%s → %s)" % [before, after])


func _caso_pedido() -> void:
	await fresh()
	check(not node("CareAsk").visible, "sem pedido o atalho fica escondido")
	var asks := {"hunger": "dog_food", "hygiene": "action_sponge", "happiness": "action_play", "energy": "action_sleep"}
	for need: String in asks:
		await fresh()
		state.get("dog").needs[need] = 8.0
		state.call("_changed")
		await frames()
		check(state.call("asking_need") == need, "pedindo " + need)
		var ask := node("CareAsk")
		check(ask.is_visible_in_tree(), "o atalho aparece pedindo " + need)
		var icon := ask.find_child("CareAskIcon", true, false) as TextureRect
		var expected: Texture2D = root.get_node("Database").call("item_icon", "dog_food") if need == "hunger" else KIT.call("ui_icon", asks[need])
		check(icon != null and icon.texture == expected, "ícone do pedido certo: " + need)
		var before: float = state.get("dog").call("get_need", need, state.call("now"))
		(ask as Button).pressed.emit()
		await frames()
		match need:
			"hunger": check(node("FoodMenu").visible, "atalho da fome abre o FoodMenu")
			"hygiene", "happiness":
				var after: float = state.get("dog").call("get_need", need, state.call("now"))
				check(after > before, "atalho age na hora: " + need)
			"energy": check(state.get("dog").sleeping, "atalho do sono dorme")
		tray.call("close_food_menu")
	await fresh()


func _caso_dormindo() -> void:
	await fresh()
	state.call("set_sleeping", true)
	await frames()
	check(node("CareButton").is_visible_in_tree(), "dormindo o botão continua (vira a lua)")
	(node("CareButton") as Button).pressed.emit()
	await frames()
	check(not state.get("dog").sleeping, "tocar no botão dormindo acorda")
	check(not wheel_open(), "a roleta não abre ao acordar")
	state.call("set_sleeping", true)
	await frames()
	tray.call("open_wheel")
	check(not wheel_open(), "dormindo a roleta não abre")
	state.call("set_sleeping", false)


func _caso_alfinete() -> void:
	await fresh()
	root.get_node("Events").emit_signal("care_requested", "sponge")
	await frames()
	check(wheel_open(), "o alfinete abre a roleta")
	var pointer := node("Care_sponge").get_node_or_null("CarePointer")
	check(pointer is Polygon2D, "CarePointer é um Polygon2D filho do disco Banho")
	check(pointer != null and pointer.is_visible_in_tree(), "o alfinete aparece")
	tray.call("close_wheel")


func _caso_menos_animacao() -> void:
	await fresh()
	Motion.reduced = true
	(node("CareButton") as Button).pressed.emit()
	for disc: Control in discs():
		check(disc.modulate.a >= 0.99 and disc.scale.is_equal_approx(Vector2.ONE), "sem animação o disco já está no lugar: " + str(disc.name))
	tray.call("close_wheel")


func _caso_hud_abas() -> void:
	main.call("show_screen", &"tasks")
	await frames()
	var right := node("Row2Right")
	check(right.get_child_count() == 0 and right.custom_minimum_size.x == 0, "sair do Tiro libera o conteúdo e a largura da linha 2")
	main.call("show_screen", &"pet")
	await frames()
	check(right.find_child("NeedsPanel", true, false) != null, "voltar ao Tiro repõe os quatro anéis no HUD")
