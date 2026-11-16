extends SceneTree
## Cozinha nova (fogão): painel do Figma aberto no fogão da Casa (main.tscn de verdade, sem SaveManager).
## --headless --path game -s res://tests/cook_panel_test.gd

var failures := 0
var state: Node
var events: Node
var main: Control
var cook: Script
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("COOK PANEL: " + message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func panel() -> Control:
	return cook.call("current") as Control


func node(node_name: String) -> Control:
	return panel().find_child(node_name, true, false) as Control if panel() != null else null


## Toque curto numa peça tocável (UiKit.on_tap: apertar e soltar dentro dela).
func tap(target: Control) -> void:
	check(target != null, "peça para tocar existe")
	if target == null:
		return
	var hit := target.get_node_or_null("Hit") as Control
	if hit != null:
		target = hit  # área de toque ampliada
	var point := target.size / 2.0
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = point
		target.gui_input.emit(click)


## Toque num cartão dentro de uma janela de rolagem própria.
func tap_card(scroll: Control, card: Control) -> void:
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = card.position + scroll.get("content").position + card.size / 2.0
		scroll.call("_gui_input", click)


func slot_state(index: int) -> String:
	var slot := node("Slot_%d" % index)
	return str(slot.get_meta("state")) if slot != null else "(sem)"


func now() -> float:
	return float(state.call("now"))


func reset_world() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	state.set("animals", {})


func open(room: Control, focus: String = "") -> void:
	room.call("close_tray")
	room.call("open_station_tray", "stove", focus)
	await frames(4)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	cook = load("res://scripts/ui/cook_panel.gd")
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	reset_world()
	state.get("progress").owned.erase("stove_queue_3")
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(4)
	main.call("_on_world_requested", "house", "")
	main.call("show_screen", &"map")
	await frames(4)
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var house := main.find_child("World_house", true, false) as Control
	house.call("_animate_objects")

	# 1. Abre pelo fogão; sem prato escolhido; espaços: três livres e um fechado.
	await open(house)
	check(panel() != null and panel().name == "CookPanel", "o fogão abre o CookPanel")
	check(node("DetailEmpty") != null and node("DetailName") == null, "sem prato escolhido mostra o detalhe vazio")
	check(node("CookToggle") != null and node("CloseButton") != null, "alternador e X de fechar existem")
	check([slot_state(0), slot_state(1), slot_state(2), slot_state(3)] == ["free", "free", "free", "locked"], "três livres e um fechado (%s)" % [[slot_state(0), slot_state(1), slot_state(2), slot_state(3)]])
	var dishes := panel().find_children("Dish_*", "Control", true, false)
	check(dishes.size() >= 5, "lista com os pratos do fogão (%d)" % dishes.size())
	check(node("DishStars") != null and (node("DishStars") as TextureRect).texture.get_width() == 75, "cartão tem as estrelas (0)")
	check(node("Cat_all") != null and bool(node("Cat_all").get_meta("selected")), "Todos escolhido por padrão")
	var scroll := node("DishList")

	# 2. Escolher um prato; ingredientes faltando × tendo; fila.
	var card := node("Dish_carrot_snack")
	tap_card(scroll, card)
	await frames(2)
	check(bool(card.get_meta("selected")), "tocar escolhe o prato")
	check(node("DetailName") != null and node("DetailEmpty") == null, "detalhe do prato aparece")
	check(node("DetailStars") != null, "detalhe tem as estrelas")
	var ingredient := node("Ingredient_carrot")
	check(ingredient != null and not bool(ingredient.get_meta("ok")), "sem cenoura: ingrediente faltando")
	check((node("QueueButton") as CanvasItem).modulate.a < 0.9, "colocar na fila apagado sem ingredientes")
	toasts.clear()
	tap(node("QueueButton"))
	check(not toasts.is_empty() and state.call("station", "stove").queue.is_empty(), "sem ingrediente: aviso e nada na fila")
	state.get("inventory").call("add", "carrot", 6)
	events.state_changed.emit()
	await frames(2)
	check(bool(node("Ingredient_carrot").get_meta("ok")), "com cenouras o ingrediente fica ok")
	check((node("QueueButton") as CanvasItem).modulate.a > 0.95, "botão normal com ingredientes")
	tap(node("QueueButton"))
	await frames(2)
	check(state.call("station", "stove").queue.size() == 1, "colocar na fila cozinha 1 lote")
	check(slot_state(0) == "busy", "espaço 0 produzindo (%s)" % slot_state(0))
	check(bool(node("Dish_carrot_snack").get_meta("selected")), "a escolha continua depois de cozinhar")

	# 3. Fica pronto e recolhe pelo espaço.
	state.call("station", "stove").queue[0]["ready_at"] = now() - 1.0
	events.state_changed.emit()
	await frames(2)
	check(slot_state(0) == "ready", "espaço 0 pronto (%s)" % slot_state(0))
	var before: int = state.get("inventory").call("count", "carrot_snack")
	tap(node("Slot_0"))
	await frames(2)
	check(state.get("inventory").call("count", "carrot_snack") > before, "tocar no pronto recolhe")
	check(slot_state(0) == "free", "espaço volta a livre")

	# 4. Filtros: único, funcionais e se limpam ao tocar de novo.
	var total := panel().find_children("Dish_*", "Control", true, false).size()
	tap(node("Filter_can"))
	await frames(2)
	check(bool(node("Filter_can").get_meta("selected")) and not bool(node("Filter_tiro").get_meta("selected")), "um filtro por vez")
	var can_ids: Array[String] = []
	for each in panel().find_children("Dish_*", "Control", true, false):
		can_ids.append(each.name.trim_prefix("Dish_"))
	check(not can_ids.is_empty() and can_ids.size() < total, "Dá para fazer encolhe a lista (%d de %d)" % [can_ids.size(), total])
	for id in can_ids:
		check(String(state.call("cook_many_error", id, 1)) == "", "%s dá para fazer" % id)
	tap(node("Filter_missing"))
	await frames(2)
	check(bool(node("Filter_missing").get_meta("selected")) and not bool(node("Filter_can").get_meta("selected")), "trocar de filtro troca a escolha")
	for each in panel().find_children("Dish_*", "Control", true, false):
		check(String(state.call("cook_many_error", each.name.trim_prefix("Dish_"), 1)) != "", "Faltam só tem o que não dá")
	tap(node("Filter_missing"))
	await frames(2)
	check(not bool(node("Filter_missing").get_meta("selected")), "tocar de novo limpa o filtro")
	check(panel().find_children("Dish_*", "Control", true, false).size() == total, "sem filtro volta a lista inteira")

	# 5. Categoria escolhe sem mexer na lista; seta rola as categorias.
	tap_card(node("CatScroll"), node("Cat_soups"))
	check(bool(node("Cat_soups").get_meta("selected")) and not bool(node("Cat_all").get_meta("selected")), "categoria escolhida troca o fundo")
	check(panel().find_children("Dish_*", "Control", true, false).size() == total, "categorias ainda mostram tudo")
	var cats := node("CatScroll")
	check(float(cats.get("offset")) == 0.0, "categorias começam no início")
	tap(node("CatArrow"))
	check(float(cats.get("offset")) > 0.0, "a seta rola as categorias")

	# 6. state_changed não mexe em rolagem, escolha, filtro nem categoria.
	tap(node("Filter_tiro"))
	tap(node("Filter_tiro"))
	scroll.call("scroll_to", 164.0, false)
	var cat_offset := float(cats.get("offset"))
	events.state_changed.emit()
	await frames(2)
	check(is_equal_approx(float(scroll.get("offset")), 164.0), "rolagem da lista mantida (%s)" % scroll.get("offset"))
	check(is_equal_approx(float(cats.get("offset")), cat_offset), "rolagem das categorias mantida")
	check(bool(node("Dish_carrot_snack").get_meta("selected")) and bool(node("Cat_soups").get_meta("selected")), "escolha e categoria mantidas")

	# 7. O alternador troca de aba (Inventar tem o teste dele); "Cozinhar junto" dos Pratos só avisa; o espaço fechado abre a compra.
	toasts.clear()
	tap(node("InventHalf"))
	check(node("InventView") != null and node("InventView").visible and not scroll.is_visible_in_tree(), "Inventar troca o miolo")
	tap(node("DishesHalf"))
	check(not node("InventView").visible and scroll.is_visible_in_tree(), "Pratos volta o miolo")
	tap(node("TogetherButton"))
	check(toasts.count("Em breve!") == 1, "Cozinhar junto dos Pratos avisa 'Em breve!'")
	var sheets: Array[String] = []
	events.sheet_requested.connect(func(title: String, _c: Control) -> void: sheets.append(title))
	tap(node("Slot_3"))
	await frames(2)
	check(sheets.size() == 1, "espaço fechado abre a compra da ampliação")
	check(panel() == null, "abrir uma folha fecha o painel")

	# 8. Receita bloqueada continua escolhível; Ir com foco escolhe e rola; fechar por X, fora e Escape.
	await open(house, "vegetable_soup")
	check(panel() != null and bool(node("Dish_vegetable_soup").get_meta("selected")), "foco do Ir já vem escolhido")
	check(node("DetailName") != null, "detalhe do foco aberto")
	(node("CloseButton") as Button).pressed.emit()
	await frames(2)
	check(panel() == null, "o X fecha o painel")
	await open(house)
	var catcher := root.find_child("CookCatcher", true, false) as Control
	check(catcher != null, "existe o captador de toque fora")
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = Vector2(5, 5)
		catcher.gui_input.emit(click)
	await frames(2)
	check(panel() == null, "tocar fora fecha")
	# A pílula do mundo vale com o painel aberto: fecha e abre o seletor.
	await open(house)
	var pill := main.find_child("MapButton", true, false) as Control
	var catcher2 := root.find_child("CookCatcher", true, false) as Control
	for pressed in [true, false]:
		var tap_pill := InputEventMouseButton.new()
		tap_pill.button_index = MOUSE_BUTTON_LEFT
		tap_pill.pressed = pressed
		tap_pill.position = pill.get_global_rect().get_center()
		catcher2.gui_input.emit(tap_pill)
	await frames(3)
	check(panel() == null, "tocar na pílula fecha o painel")
	check(bool(main.find_child("WorldsScreen", true, false).call("is_map_open")), "e abre o seletor de mundos")
	main.find_child("WorldsScreen", true, false).call("close_map")
	await frames(2)
	await open(house)
	check(panel() != null, "reabre")
	panel().call("close", true)
	await frames(2)
	check(root.find_child("CookCatcher", true, false) == null, "o captador some ao fechar")

	print("COOK PANEL: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
