extends SceneTree
## "Presentes para guardar" na Mochila (etapa 02 da economia): seção recolhida, aviso de falta de espaço,
## "Guardar" com toque real (mouse/toque emulado no viewport) nas três resoluções, guarda parcial e fim da seção.
## --headless --path game -s res://tests/pending_gifts_test.gd

const SIZES: Array[Vector2i] = [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]

var failures := 0
var state: Node
var main: Control


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120.0).timeout.connect(func() -> void:
		push_error("PENDING GIFTS: tempo excedido")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PENDING GIFTS: " + message)


func frames(count: int = 8) -> void:
	for i in count:
		await process_frame


func click(button: Control) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = root.get_final_transform() * (button.get_global_transform_with_canvas() * (button.size * 0.5))
		root.push_input(event)
	await frames()


func has_text(node: Node, text: String) -> bool:
	for label: Label in node.find_children("*", "Label", true, false):
		if text in label.text:
			return true
	return false


func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	Motion.reduced = true
	for size in SIZES:
		await _scenario(size)
	print("PENDING GIFTS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)


func _scenario(size: Vector2i) -> void:
	var tag := "%dx%d" % [size.x, size.y]
	root.size = size
	state.call("reset")
	state.set("unlimited_storage", false)
	state.call("dev_unlock_everything")
	state.get("progress").seen.intro = true
	var owned: Dictionary = state.get("progress").owned
	owned["fridge"] = true
	owned.erase("fridge_2")
	owned.erase("fridge_3")
	owned.erase("fridge_4")
	owned.erase("fridge_5")
	state.get("economy").storage_floor.clear()  # a fixture "desfaz" as compras: o piso persistido também
	var inventory: Object = state.get("inventory")
	inventory.counts.clear()
	inventory.add("egg", 24)  # geladeira cheia (24/24)
	state.call("_mark_all_seen")
	state.call("_grant_automatic", "customer:lais:1", {"coins": 20, "items": {"carrot_snack": 1}})
	state.call("_grant_automatic", "customer:lais:2", {"coins": 25, "items": {"carrot_snack": 2}})
	var coins := int(state.get("coins"))
	check(int(state.call("pending_reward_total")) == 3, "%s: três unidades esperando" % tag)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames(10)
	main.call("show_screen", &"bag")
	await frames()
	var bag: Control = main.find_child("BagScreen", true, false)
	var card: Control = bag.find_child("PendingGifts", true, false)
	check(card != null, "%s: seção Presentes para guardar aparece" % tag)
	if card == null:
		main.queue_free()
		await frames()
		return
	check(has_text(card, "Presentes para guardar (3)"), "%s: título com a quantidade" % tag)
	check(not has_text(card, "Nível 3"), "%s: detalhes recolhidos" % tag)
	check(bag.find_child("StoreGifts", true, false) == null and bag.find_child("GiftsBlocked", true, false) != null, "%s: sem espaço, só o aviso" % tag)
	check(has_text(card, "Geladeira sem espaço: abra lugar"), "%s: aviso nomeia a geladeira" % tag)
	var viewport := root.get_visible_rect()
	var toggle: Control = card.find_child("GiftsToggle", true, false)
	check(toggle.size.x >= 44 and toggle.size.y >= 44, "%s: alvo do botão recolher >= 44 px" % tag)
	check(viewport.encloses(Rect2(card.global_position, card.size)), "%s: cartão cabe na tela sem rolagem horizontal" % tag)
	await click(toggle)
	card = bag.find_child("PendingGifts", true, false)
	check(has_text(card, str(state.get("economy").pending["customer:lais:1"].label)), "%s: expandido mostra de onde veio cada presente" % tag)
	check(viewport.encloses(Rect2(card.global_position, card.size)), "%s: expandido cabe na largura" % tag)
	# Abre uma vaga: aparece "Guardar"; toque real guarda só uma unidade e mantém o resto.
	inventory.remove("egg", 1)
	state.call("_changed")
	await frames()
	var store: Control = bag.find_child("StoreGifts", true, false)
	check(store != null, "%s: com espaço aparece Guardar" % tag)
	if store != null:
		check(store.size.y >= 44 and viewport.encloses(Rect2(store.global_position, store.size)), "%s: Guardar tem alvo grande e está na tela" % tag)
		await click(store)
		check(int(inventory.count("carrot_snack")) == 1, "%s: toque guardou 1 unidade (cabia só 1)" % tag)
		check(int(state.call("pending_reward_total")) == 2, "%s: 2 continuam esperando" % tag)
		check(int(state.get("coins")) == coins, "%s: moedas não são pagas de novo" % tag)
		await click(bag.find_child("StoreGifts", true, false)) if bag.find_child("StoreGifts", true, false) != null else await frames()
		check(int(inventory.count("carrot_snack")) == 1, "%s: sem espaço de novo, nada entra" % tag)
	# Libera o bastante: guarda tudo e a seção some.
	inventory.remove("egg", 4)
	state.call("_changed")
	await frames()
	store = bag.find_child("StoreGifts", true, false)
	check(store != null, "%s: Guardar volta com mais espaço" % tag)
	if store != null:
		await click(store)
	check(int(inventory.count("carrot_snack")) == 3 and int(state.call("pending_reward_total")) == 0, "%s: tudo guardado, nada perdido" % tag)
	await frames()
	check(bag.find_child("PendingGifts", true, false) == null, "%s: seção some quando não há presentes" % tag)
	check(int(state.get("coins")) == coins, "%s: moedas intactas no fim" % tag)
	main.queue_free()
	await frames()
