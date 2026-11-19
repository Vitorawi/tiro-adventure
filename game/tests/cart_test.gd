extends SceneTree
## Primeira semana E10, com gestos no mapa, na entrega e em Cuidar.

var state: Node
var main: Node
var events: Node
var room: Control
var failures := 0
var screenshots := false


func _initialize() -> void:
	screenshots = "--screenshots" in OS.get_cmdline_user_args()
	Engine.max_fps = 60
	create_timer(90).timeout.connect(func() -> void:
		push_error("CART: tempo excedido")
		quit(1))
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("CART: " + message)


func pause(seconds: float = 0.25) -> void:
	await create_timer(seconds).timeout


func shot(name: String) -> void:
	if not screenshots:
		return
	var toast := main.find_child("Toast", true, false) as Control
	var show_toast := toast.visible
	toast.hide()
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	toast.visible = show_toast
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/e10_cart")
	DirAccess.make_dir_recursive_absolute(folder)
	check(frame.save_png(folder.path_join("%dx%d_%s.png" % [frame.get_width(), frame.get_height(), name])) == OK, "captura " + name)


func day(number: int, hour: int = 9) -> void:
	state.call("dev_week_goto", number)
	state.call("dev_week_hour", hour)
	state.call("update_week")


func hide_modals() -> void:
	for id: String in ["_celebration", "_welcome", "_walk_result"]:
		var layer: Variant = main.get(id)
		if layer is CanvasLayer:
			layer.hide()
	main.set("_modal_queue", [] as Array[Callable])


func tap_point(point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		event.position = point
		event.global_position = point
		root.push_input(event, true)


func tap(id: String, host: Node = null) -> void:
	var parent := main if host == null else host
	var button := parent.find_child(id, true, false) as Control
	check(button != null and button.is_visible_in_tree(), "controle " + id)
	if button != null:
		tap_point(button.get_global_rect().get_center())


func touch(point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)


func gesture(overlay: Node) -> void:
	var stage := overlay.find_child("LessonStage", true, false) as Control
	var path: PackedVector2Array = overlay.get("_path")
	check(path.size() > 1, "trajeto do Senta")
	if path.size() <= 1:
		return
	var origin := stage.global_position
	var last := origin + path[0]
	touch(last, true)
	for i in range(1, path.size()):
		var point := origin + path[i]
		var motion := InputEventScreenDrag.new()
		motion.position = point
		motion.relative = point - last
		root.push_input(motion, true)
		last = point
	touch(last, false)


func cart_open() -> void:
	load("res://scripts/ui/places.gd").call("open", "farm", "week_cart")


func stock(id: String) -> int:
	return state.get("inventory").count(id)


func coins() -> int:
	return int(state.get("coins"))


func run_farm_intro() -> void:
	day(1)
	var cloth: Dictionary = state.call("start_yard_round", "ball")
	check(not cloth.variant.fetch and not cloth.variant.squeak and not cloth.variant.lake, "dia 1: bolinha de pano no Quintal")
	state.call("cancel_yard_round", int(cloth.id))
	check(state.call("buy_shop_item", "week_plot") == "", "dia 1: canteiro pela banca da vovó")
	day(2, 12)
	check(state.call("buy_shop_item", "week_coop") == "", "dia 2: monta o galinheiro")
	check(state.call("plant", 8, "corn") == "", "planta milho no galinheiro")
	state.call("dev_finish_timers")
	check(not state.call("harvest", 8).is_empty(), "colhe o milho")
	check(state.call("cook", "eggs") == "", "o milho inicia um lote de ovos")
	state.call("dev_finish_timers")
	check(state.call("collect", "chicken_coop").get("egg") == 2, "recolhe ovos para encomenda")
	var inventory: Variant = state.get("inventory")
	inventory.add("apple_biscuit", 1)
	inventory.add("puppy_mash", 1)
	state.call("feed", "puppy_mash")
	check(state.call("start_trick_lesson", "sit") == "", "dia 2: abre aula com a vovó")
	var result: Dictionary
	for i in 5:
		state.call("trick_lesson_step", "sit", "show", 1.0)
		state.call("trick_lesson_step", "sit", "mark", 1.0)
		result = state.call("trick_lesson_step", "sit", "reward", 0.1)
	check(result.get("level_up", false), "Senta aprendido na Aula")
	day(3)
	check(state.call("current_rod") == "bamboo_rod" and state.call("cast_error", "bait_worm", 1) == "", "dia 3: lagoa e vara de bambu")
	day(4)
	check(state.call("harvest_orchard", "apple") == "" and state.call("harvest_orchard", "banana") == "", "dia 4: colheita no pomar")
	check(state.call("yard_open", "rope"), "dia 4: cordinha no Quintal")


func run_cart_rules() -> void:
	day(4)
	check(state.call("cart_order_ids").is_empty(), "sem pedidos no dia 4")
	check(state.call("buy_shop_item", "cart_ball") == "Abre no dia 5", "compras fechadas no dia 4")
	day(5)
	var ids: Array = state.call("cart_order_ids")
	check(ids == ["cart_eggs", "cart_lake"], "dois pedidos T4 no dia 5")
	var before := coins()
	check(state.call("fulfill_order", "cart_lake") != "" and coins() == before, "estoque insuficiente preserva moedas")
	check(not state.call("bathe", true), "banho caprichado precisa de xampu")
	var inventory: Variant = state.get("inventory")
	inventory.add("egg", 1)
	inventory.add("pumpkin", 2)
	var round_before: Dictionary = state.call("start_yard_round", "ball")
	check(round_before.variant.fetch and not round_before.variant.squeak, "sem empréstimo no dia 5")
	state.call("cancel_yard_round", int(round_before.id))
	check(state.call("cart_order_offer", "cart_eggs").get("tip") == 5, "Senta habilita gorjeta depois da aula")


func _run() -> void:
	if not screenshots:
		root.size = Vector2i(360, 780)
	state = root.get_node("GameState")
	events = root.get_node("Events")
	var saver := root.get_node("SaveManager")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_set_phase", "puppy")
	state.call("finish_fishing_tutorial")
	state.set("coins", 250)
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await pause(0.6)
	hide_modals()
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await pause(1.0)
	hide_modals()
	for view: Node in get_nodes_in_group("room_views"):
		if view.get("room_id") == "farm":
			room = view as Control
	check(room != null, "Sítio pelo Mapa")
	if room == null:
		quit(1)
		return
	var cart := room.find_child("week_cart", true, false) as Sprite2D
	check(cart != null and not cart.visible, "carroça escondida no mapa antes do dia 5")
	if cart == null:
		quit(1)
		return
	run_farm_intro()
	run_cart_rules()
	check(cart.visible, "carroça aparece no portão no dia 5")
	var cart_center := cart.transform * cart.get_rect().get_center()
	room.call("_tween_camera", cart_center, 0.79, 0.0)
	await pause()
	await shot("01_portao")
	hide_modals()
	room.call("close_tray")
	var art := cart.get_rect()
	var roof := cart.transform * (art.position + art.size * Vector2(0.5, 0.25))
	var board: Node
	var where: Vector2 = room.call("world_to_screen", roof)
	var motion := InputEventMouseMotion.new()
	motion.position = where
	motion.global_position = where
	root.push_input(motion, true)
	await process_frame
	for attempt in 3:
		hide_modals()
		tap_point(where)
		await pause(0.65)
		board = main.find_child("CartBoard", true, false)
		if board != null:
			break
	if board == null:
		print("CART MAP debug: point ", where, ", hover ", root.gui_get_hovered_control(), ", hit ", room.call("_hits", cart, roof - cart.position), ", cart ", cart.visible, ", active ", room.is_visible_in_tree())
	check(board != null, "toque na carroça abre a folha")
	if board == null:
		quit(1)
		return
	await shot("02_encomendas")
	var before := coins()
	var egg_order := board.find_child("Order_cart_eggs", true, false)
	tap("DeliverOrder", egg_order)
	await pause()
	var overlay := main.get_node_or_null("CartTrick")
	check(overlay != null, "Entregar oferece Senta pela gorjeta")
	if overlay != null:
		await shot("03_gorjeta")
		tap("MealTrickAsk", overlay)
		await pause()
		gesture(overlay)
		await pause(1.15)
	check(coins() == before + 35 and stock("egg") == 0, "acertar paga 30 + 5 e baixa três ovos")
	before = coins()
	state.get("inventory").add("egg", 3)
	check(state.call("fulfill_order", "cart_eggs") == "Já entregue" and coins() == before and stock("egg") == 3, "recibo impede segunda entrega")
	check(state.call("fulfill_order", "cart_lake") != "", "duas abóboras sem peixe não bastam")
	state.get("inventory").add("fish_tilapia", 1)
	check(state.call("fulfill_order", "cart_lake") == "" and coins() == before + 38, "entrega normal paga 38")
	await pause()
	board = main.find_child("CartBoard", true, false)
	if board == null:
		cart_open()
		await pause(0.5)
		board = main.find_child("CartBoard", true, false)
	check(board != null, "retorna ao quadro após o truque")
	if board == null:
		quit(1)
		return
	var offer: Dictionary = state.call("shop_pack", "cart_offer")
	var discounted: bool = offer.items == {"puppy_shampoo": 1}
	var purchase := "Buy_cart_offer" if discounted else "Buy_cart_shampoo"
	var price := int(offer.price) if discounted else 30
	if discounted:
		check(board.find_child("Buy_cart_shampoo", true, false) == null, "oferta substitui o xampu a preço cheio")
	var shampoo_button := board.find_child(purchase, true, false) as Control
	var scroll := shampoo_button.get_parent()
	while scroll != null and not scroll is ScrollContainer:
		scroll = scroll.get_parent()
	if scroll is ScrollContainer:
		(scroll as ScrollContainer).ensure_control_visible(shampoo_button)
		await pause()
	if scroll is ScrollContainer:
		var area := scroll as ScrollContainer
		var previous := area.scroll_vertical
		area.scroll_vertical = int(area.get_v_scroll_bar().max_value)
		await pause()
		await shot("04_compras")
		area.scroll_vertical = previous
		await pause()
	before = coins()
	tap(purchase, board)
	await pause()
	check(coins() == before - price and stock("puppy_shampoo") == 1, "compra xampu pelo toque")
	check(state.call("buy_shop_item", "cart_bow") == "" and coins() == before - price - 45, "lacinho custa 45")
	check(state.call("equip", "yellow_bow") == "", "lacinho disponível para vestir no Caderninho")
	check(state.call("buy_shop_item", "cart_ball") == "" and stock("squeaky_ball") == 1 and coins() == before - price - 80, "bolinha custa 35 e entra na Mochila")
	check(state.call("buy_shop_item", "cart_ball") != "" and state.call("buy_shop_item", "cart_bow") != "", "acessórios só uma vez")
	var variant: Dictionary = state.call("start_yard_round", "ball")
	check(variant.variant.squeak and not variant.variant.lake, "Quintal usa a compra no dia 5")
	state.call("cancel_yard_round", int(variant.id))
	if not discounted:
		check(state.call("buy_shop_item", "cart_offer") == "", "compra oferta distinta do xampu")
	check(state.call("shop_daily_left", "cart_offer") == 0, "uma oferta com desconto por dia")
	check(state.call("buy_shop_item", "cart_offer") == "Volta amanhã", "oferta não vende duas vezes")
	var actual_stock := stock("puppy_shampoo")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(state.call("cart_order_ids") == ["cart_eggs", "cart_lake"], "pedidos iguais após carregar")
	check(state.call("order_error", "cart_eggs") == "Já entregue" and state.call("shop_pack", "cart_offer") == offer and state.call("shop_daily_left", "cart_offer") == 0, "recibos e oferta persistem")
	check(state.get("progress").equipped.head == "yellow_bow" and stock("squeaky_ball") == 1, "compra e roupa persistem")
	var yesterday: int = state.call("cart_day")
	day(5, 23)
	state.call("dev_week_shift_hours", 1)
	check(state.call("cart_order_ids") == ["cart_fruit", "cart_pumpkins"], "renova dois pedidos na virada civil")
	check(state.call("shop_daily_left", "cart_offer") == 1 and state.call("shop_pack", "cart_offer") != offer, "renova a oferta")
	check(state.call("buy_shop_item", "cart_offer", 1, yesterday) != "" and state.call("fulfill_order", "cart_fruit", {}, yesterday) != "", "interface antiga não compra nem entrega no novo dia")
	var db := root.get_node("Database")
	for pair: Array in db.get("progression").cart_orders:
		for id: String in pair:
			var data: Dictionary = db.get("progression").cart_catalog[id]
			var loose := 0
			for item: String in data.inputs:
				loose += int(state.call("sale_price", item, "farm")) * int(data.inputs[item])
			check(int(data.rewards.coins) > loose, "pagamento supera venda avulsa: " + id)
	before = coins()
	check(state.call("cart_order_offer", "cart_fruit").is_empty(), "cliente não oferece gesto desconhecido")
	check(state.call("fulfill_order", "cart_fruit") == "" and coins() == before + 24, "cliente recebe pedido mesmo sem aprender Dá a pata")
	var lake: Dictionary = state.call("start_yard_round", "ball")
	check(lake.variant.lake and lake.variant.squeak, "lagoa abre no dia 6 e mantém a bolinha comprada")
	state.call("cancel_yard_round", int(lake.id))
	await pause(0.6)
	# A terceira encomenda da E11 abre Achado! antes de entrar no Quintal.
	hide_modals()
	load("res://scripts/ui/yard_play.gd").call("open")
	await pause(0.45)
	tap("YardBall")
	await pause(0.4)
	var yard := main.get_node_or_null("YardPlay")
	check(yard != null and yard.get("round_data").variant.squeak and yard.get("round_data").variant.lake, "Quintal abre com a bolinha comprada e a lagoa")
	if yard != null:
		await shot("08_quintal")
		tap("YardExit", yard)
		await pause()
	main.call("show_screen", &"pet")
	await pause(0.8)
	hide_modals()
	var pet := main.find_child("PetScreen", true, false)
	var animator: Node = pet.get("_animator")
	for tick in 60:
		if animator.get("_clip") == &"idle_breathe":
			break
		await pause(0.2)
	var bow := pet.find_child("PuppyBow", true, false) as Control
	check(bow != null and bow.is_visible_in_tree(), "lacinho aparece no filhote animado")
	await shot("05_lacinho")
	tap("CareButton")
	await pause()
	tap("Care_sponge")
	await pause()
	await shot("06_opcao_banho")
	var coat: int = state.get("growth").moments.get("coat", 0)
	state.get("dog").needs.hygiene = 10.0
	tap("BathShampoo")
	var bubbles := main.find_children("SoapBubble", "", true, false)
	check(not bubbles.is_empty(), "banho dispara bolhas")
	await pause(1.45)
	check(stock("puppy_shampoo") == actual_stock - 1, "um xampu consumido no banho")
	check(int(state.get("growth").moments.get("coat", 0)) == coat + 2, "banho caprichado dá dois momentos de Pelagem")
	check(animator.get("_clip") == &"bath", "reação Animaref do banho")
	await shot("07_banho")
	print("CART: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
