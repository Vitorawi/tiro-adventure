extends SceneTree
## Aba Inventar do painel do fogão (CookInvent + CookInventPicker), no main.tscn de verdade, sem SaveManager.
## --headless --path game -s res://tests/cook_invent_test.gd

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
		push_error("COOK INVENT: " + message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func panel() -> Control:
	return cook.call("current") as Control


func node(node_name: String) -> Control:
	return panel().find_child(node_name, true, false) as Control if panel() != null else null


func tap(target: Control) -> void:
	check(target != null, "peça para tocar existe")
	if target == null:
		return
	var hit := target.get_node_or_null("Hit") as Control
	if hit != null:
		target = hit
	var point := target.size / 2.0
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = point
		target.gui_input.emit(click)


func tap_card(scroll: Control, card: Control) -> void:
	check(card != null and scroll != null, "cartão na rolagem existe")
	if card == null or scroll == null:
		return
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = card.position + scroll.get("content").position + card.size / 2.0
		scroll.call("_gui_input", click)


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


func give(item: String, amount: int) -> void:
	state.get("inventory").call("add", item, amount)
	events.state_changed.emit()


func count(item: String) -> int:
	return int(state.get("inventory").call("count", item))


func open(room: Control) -> void:
	room.call("close_tray")
	room.call("open_station_tray", "stove", "")
	await frames(4)


func names(pattern: String) -> Array[String]:
	var result: Array[String] = []
	for each in panel().find_children(pattern, "Control", true, false):
		result.append(each.name)
	return result


func slot(i: int) -> Control:
	return node("InvSlot_%d" % i)


func card_state() -> String:
	return str(node("InvCard").get_meta("state"))


func queue_size() -> int:
	return state.call("station", "stove").queue.size()


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
	var db: Node = root.get_node("Database")

	# 0. Dados coerentes; a receita escondida existe mas não aparece como prato.
	check((db.call("invent_problems") as Array).is_empty(), "invent.json coerente: %s" % [db.call("invent_problems")])
	check(not (db.call("recipes_for", "stove") as Array).has("invented_dish"), "o prato inventado não é receita listada")
	check(db.get("recipes").has("invented_dish"), "a receita escondida existe para a fila")
	# Um legume fica fora dos recomendados para testar a seção "Outros ingredientes".
	var rec_legume: Array = db.get("invent").recommended.legume
	rec_legume.erase("sweet_potato")

	# 1. Alternador: Inventar troca o miolo e o fundo; Pratos volta.
	await open(house)
	cook.set("invent_mode", false)
	var top := node("PanelTop") as TextureRect
	var pratos_top := top.texture
	tap(node("InventHalf"))
	await frames(2)
	check(node("InventView").is_visible_in_tree() and not node("DishList").is_visible_in_tree() and not node("Slot_0").is_visible_in_tree(), "Inventar mostra o miolo novo e esconde fila/lista")
	check(top.texture != pratos_top, "o fundo da Inventar é outro")
	check(cook.get("invent_mode") == true, "o modo fica guardado")
	tap(node("DishesHalf"))
	await frames(2)
	check(not node("InventView").is_visible_in_tree() and node("DishList").is_visible_in_tree() and top.texture == pratos_top, "Pratos volta ao desenho de antes")
	panel().call("close", true)
	await frames(2)
	await open(house)
	check(not node("InventView").is_visible_in_tree(), "a aba escolhida (Pratos) vale ao reabrir")
	tap(node("InventHalf"))
	await frames(2)

	# 2. Tipos de prato: escolher só troca o fundo; o número de espaços é o do tipo.
	var types: Array = db.get("invent").dish_types
	var type_nodes := names("InvType_*")
	check(type_nodes.size() == types.size(), "um cartão por tipo (%d)" % type_nodes.size())
	check(bool(node("InvType_" + str(types[0].id)).get_meta("selected")), "o primeiro tipo vem escolhido")
	check(names("InvSlot_*").size() == (types[0].slots as Array).size(), "espaços = os do tipo (%d)" % names("InvSlot_*").size())
	var scroll_types := node("InvTypes")
	tap_card(scroll_types, node("InvType_" + str(types[1].id)))
	await frames(2)
	check(bool(node("InvType_" + str(types[1].id)).get_meta("selected")) and not bool(node("InvType_" + str(types[0].id)).get_meta("selected")), "tocar escolhe o tipo")
	check(names("InvSlot_*").size() == (types[1].slots as Array).size(), "os espaços acompanham o tipo escolhido (%d)" % names("InvSlot_*").size())
	var cats_before := float(scroll_types.get("offset"))
	tap(node("InvTypeArrow"))
	check(float(scroll_types.get("offset")) > cats_before, "a seta rola os tipos")
	tap_card(scroll_types, node("InvType_" + str(types[0].id)))
	await frames(2)
	check(card_state() == "empty", "nada escolhido: cartão vazio (%s)" % card_state())
	check(node("InvCookButton") == null, "sem botão no cartão vazio")

	# 3. Janelinha: recomendados fixos ("Acabou" com 0), outros só com quantidade.
	tap(slot(0))
	await frames(2)
	check(node("InvPicker") != null, "tocar num espaço abre a janelinha")
	var carrot := node("InvCell_carrot")
	check(carrot != null and bool(carrot.get_meta("recommended")) and bool(carrot.get_meta("out")), "recomendado sem estoque aparece como Acabou")
	check(carrot.find_child("OutPill", true, false) != null and carrot.find_child("Qty", true, false) == null, "selo Acabou no lugar da quantidade")
	tap_card(node("InvPickerScroll"), carrot)
	check(not bool(node("InvCell_carrot").get_meta("selected")), "o que acabou não se escolhe")
	check(node("InvCell_sweet_potato") == null, "não recomendado sem estoque não aparece")
	give("sweet_potato", 2)
	await frames(2)
	var sweet := node("InvCell_sweet_potato")
	check(sweet != null and not bool(sweet.get_meta("recommended")), "não recomendado com estoque aparece em Outros")
	check(node("HeadOther") != null, "cabeçalho dos outros ingredientes")
	tap(node("InvPickerClose"))
	await frames(2)
	check(node("InvPicker") == null and str(slot(0).get_meta("item")) == "", "o X fecha sem mudar nada")

	# 4. Selecionar / Remover; estados do cartão.
	give("carrot", 2)
	give("potato", 1)
	tap(slot(0))
	await frames(2)
	check(not bool(node("InvCell_carrot").get_meta("out")), "com estoque o recomendado é escolhível")
	tap_card(node("InvPickerScroll"), node("InvCell_carrot"))
	check(bool(node("InvCell_carrot").get_meta("selected")), "tocar marca a célula")
	tap(node("InvSelect"))
	await frames(2)
	check(node("InvPicker") == null and str(slot(0).get_meta("item")) == "carrot", "Selecionar põe no espaço e fecha")
	check(slot(0).find_child("Filled", true, false) != null and slot(0).find_child("Figure", true, false) != null, "espaço preenchido tem frente e figura")
	check(card_state() == "unknown", "só cenoura não é receita conhecida (%s)" % card_state())
	check(node("InvCookButton") != null, "desconhecido tem o botão Cozinhar junto")
	tap(slot(1))
	await frames(2)
	check(bool(node("InvCell_potato").get_meta("recommended")), "batata recomendada no legume")
	tap_card(node("InvPickerScroll"), node("InvCell_potato"))
	tap(node("InvSelect"))
	await frames(2)
	check(String(state.call("invent_match", {"carrot": 1, "potato": 1})) == "puppy_mash", "cenoura + batata batem com a papinha da vovó")
	check(card_state() == "known", "cenoura + batata: prato conhecido (%s)" % card_state())
	check((node("InvCardName") as Label).text == "Papinha da vovó", "nome do prato conhecido (%s)" % (node("InvCardName") as Label).text)
	tap(slot(1))
	await frames(2)
	check(bool(node("InvCell_potato").get_meta("in_pot")), "a batata está 'na panela' neste espaço")
	tap(node("InvRemove"))
	await frames(2)
	check(str(slot(1).get_meta("item")) == "" and card_state() == "unknown", "Remover esvazia o espaço")
	# O que já está no outro espaço não conta de novo: cenoura x2 -> 1 no espaço 0, sobra 1 para o espaço 1.
	tap(slot(1))
	await frames(2)
	check((node("InvCell_carrot").find_child("Qty", true, false) as Label).text == "x1", "a quantidade desconta o que já está nos outros espaços")
	tap(node("InvPickerClose"))
	await frames(2)
	# O catcher fecha a janelinha por fora, sem mudar nada.
	tap(slot(1))
	await frames(2)
	var catcher := node("InvPickerCatcher")
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = Vector2(5, 5)
		catcher.gui_input.emit(click)
	await frames(2)
	check(node("InvPicker") == null, "tocar fora fecha a janelinha")

	# 5. Cozinhar junto no prato conhecido: a receita de sempre, 1 lote.
	tap(slot(1))
	await frames(2)
	tap_card(node("InvPickerScroll"), node("InvCell_potato"))
	tap(node("InvSelect"))
	await frames(2)
	check(card_state() == "known", "de novo conhecido")
	toasts.clear()
	tap(node("InvCookButton"))
	await frames(2)
	check(queue_size() == 1 and str(state.call("station", "stove").queue[0].recipe) == "puppy_mash", "conhecido: a receita entra na fila")
	check(count("carrot") == 1 and count("potato") == 0, "os ingredientes foram gastos")
	check(str(slot(0).get_meta("item")) == "" and card_state() == "empty", "depois de cozinhar os espaços esvaziam")

	# 6. Prato desconhecido: surpresa provisória.
	state.call("station", "stove").queue.clear()
	give("corn", 1)
	tap_card(scroll_types, node("InvType_" + str(types[0].id)))
	tap(slot(0))
	await frames(2)
	tap_card(node("InvPickerScroll"), node("InvCell_carrot"))
	tap(node("InvSelect"))
	await frames(2)
	tap(slot(2))
	await frames(2)
	tap_card(node("InvPickerScroll"), node("InvCell_corn"))
	tap(node("InvSelect"))
	await frames(2)
	check(card_state() == "unknown", "cenoura + milho: prato desconhecido")
	tap(node("InvCookButton"))
	await frames(2)
	check(queue_size() == 1 and str(state.call("station", "stove").queue[0].recipe) == "invented_dish", "desconhecido: entra o prato inventado")
	check(count("carrot") == 0 and count("corn") == 0, "gastou os ingredientes escolhidos")
	state.call("station", "stove").queue[0]["ready_at"] = float(state.call("now")) - 1.0
	var got: Dictionary = state.call("collect", "stove")
	check(int(got.get("invented_dish", 0)) == 1 and count("invented_dish") == 1, "recolher entrega 1 prato inventado")

	# 7. Fila cheia: erro, nada gasto, escolha mantida.
	give("carrot", 8)
	give("corn", 1)
	for i in 3:
		state.call("cook", "carrot_snack")
	check(queue_size() == 3, "fila do fogão cheia (%d)" % queue_size())
	tap(slot(0))
	await frames(2)
	tap_card(node("InvPickerScroll"), node("InvCell_carrot"))
	tap(node("InvSelect"))
	await frames(2)
	tap(slot(2))
	await frames(2)
	tap_card(node("InvPickerScroll"), node("InvCell_corn"))
	tap(node("InvSelect"))
	await frames(2)
	var carrots := count("carrot")
	toasts.clear()
	tap(node("InvCookButton"))
	await frames(2)
	check(toasts.has("Fila cheia"), "fila cheia avisa (%s)" % [toasts])
	check(count("carrot") == carrots and queue_size() == 3 and str(slot(0).get_meta("item")) == "carrot", "erro não gasta nem esvazia")

	# 8. Altura extra: a janelinha cresce com o painel.
	tap(slot(1))
	await frames(2)
	check(node("InvPicker") != null, "janelinha abre de novo")
	var picker_scroll := node("InvPickerScroll")
	var before := picker_scroll.size.y
	node("InvPicker").call("set_extra", 40.0)
	check(is_equal_approx(picker_scroll.size.y, before + 40.0), "a rolagem da janelinha cresce com E")
	panel().call("close", true)
	await frames(2)
	rec_legume.append("sweet_potato")

	print("COOK INVENT: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
