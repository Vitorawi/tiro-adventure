extends SceneTree
## Capturas e MEDIDAS da banca com abas Vender · Comprar (Sítio e Feirante). NÃO é teste da suíte, mas imprime FAIL e sai
## com código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/shop_shots.gd -- --out=shop
## PNGs em build/screenshots/<out>/shop_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/shop/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(900).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _near(a: float, b: float, tolerance: float) -> bool:
	return absf(a - b) <= tolerance


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	for hidden_name: String in ["Notice", "Toast", "MomentNotice"]:
		var extra := main.find_child(hidden_name, true, false) as CanvasItem
		if extra:
			extra.hide()


## Estado base: o que vender na aba Vender e o que a banca/Feirante liberam.
func _setup(meet: bool, rods: Array[String], coins: int, chapter_open: bool) -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.get("progress").seen["ui:places_entered:farm"] = true
	if chapter_open:
		state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("inventory").call("from_dict", {})
	var db: Node = root.get_node("Database")
	var given := 0
	for id: String in db.get("items"):
		if int(db.get("items")[id].get("sell_price", 0)) > 0 and given < 6:
			state.get("inventory").call("add", id, 4 + given)
			given += 1
	if meet:
		state.get("progress").claimed_quests["bloblo_meet"] = true
	for rod in rods:
		state.call("give_rod", rod)
	state.set("coins", coins)
	await create_timer(1.0).timeout
	_hide_modals()


func _open(world: String, shot_name: String, tab: String, pack: String = "", plus: int = 0, buy_first: int = 0) -> void:
	var sell_ui: Script = load("res://scripts/ui/sell_ui.gd")
	sell_ui.set("open_tab", tab)
	sell_ui.set("open_pack", pack)
	var who: Dictionary = sell_ui.call("seller", world)
	var shop_id: String = root.get_node("Database").call("shop_of_place", world, str(who.place))
	var title := str(root.get_node("Database").call("shop", shop_id).get("name", who.title)) if shop_id != "" else str(who.title)
	root.get_node("Events").sheet_requested.emit(title, (load("res://scripts/ui/market_ui.gd") as Script).call("sell", world))
	await create_timer(1.0).timeout
	for i in plus:
		var button := sheet.find_child("Plus", true, false) as Button
		if button:
			button.pressed.emit()
			await create_timer(0.3).timeout
	for i in buy_first:
		var buy := sheet.find_child("BuyItem", true, false) as Button
		if buy:
			buy.pressed.emit()
			await create_timer(0.5).timeout
		_hide_modals()
	await create_timer(0.5).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "shop_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(shot_name, tab, shop_id != "" and not (sheet.find_child("NotebookTab_buy", true, false) == null))


func _measure(label: String, tab: String, with_tabs: bool) -> void:
	var screen := root.get_visible_rect().size
	var frame := sheet.find_child("SellFrame", true, false) as Control
	if frame == null:
		_check(false, "[%s] sem SellFrame" % label)
		return
	var frame_rect := frame.get_global_rect()
	_check(frame_rect.position.x >= 0.0 and frame_rect.end.x <= screen.x, "[%s] moldura fora da tela %s" % [label, frame_rect])
	_check(_near(frame_rect.get_center().x, screen.x / 2.0, 1.0), "[%s] moldura não centralizada" % label)
	var has_buy_tab := sheet.find_child("NotebookTab_buy", true, false) != null
	var has_sell_tab := sheet.find_child("NotebookTab_sell", true, false) != null
	_check(has_buy_tab == has_sell_tab, "[%s] só uma das abas" % label)
	if label.contains("sem_abas"):
		_check(not has_buy_tab, "[%s] banca sem pacotes tem abas" % label)
	elif has_buy_tab:
		for name_id: String in ["NotebookTab_sell", "NotebookTab_buy"]:
			var tab_button := sheet.find_child(name_id, true, false) as Control
			var rect := tab_button.get_global_rect()
			_check(rect.size.x >= 43.5 and rect.size.y >= 43.5, "[%s] %s menor que 44: %s" % [label, name_id, rect.size])
			_check(frame_rect.encloses(rect), "[%s] %s fora da moldura" % [label, name_id])
	var grid_name := "BuyGrid" if tab == "buy" and has_buy_tab else "SellGrid"
	var grid := sheet.find_child(grid_name, true, false) as GridContainer
	var info := "[%s] tela %dx%d moldura %s grade %s abas %s" % [label, screen.x, screen.y, frame_rect, grid_name, has_buy_tab]
	if grid != null:
		var scroll := sheet.find_child("BuyScroll" if grid_name == "BuyGrid" else "SellScroll", true, false) as Control
		var scroll_rect := scroll.get_global_rect()
		var cards: Array[Control] = []
		for child in grid.get_children():
			cards.append(child as Control)
		var xs := {}
		for card in cards:
			xs[int(roundf(card.global_position.x))] = true
			_check(_near(card.size.x, cards[0].size.x, 1.0) and _near(card.size.y, cards[0].size.y, 1.0), "[%s] cartão de tamanho diferente %s" % [label, card.name])
			_check(card.size.x >= 43.5 and card.size.y >= 43.5, "[%s] cartão menor que 44" % label)
		_check(xs.size() <= 2, "[%s] mais de duas colunas" % label)
		_check(_near(grid.global_position.x - scroll_rect.position.x, scroll_rect.end.x - (grid.global_position.x + grid.size.x), 1.0), "[%s] folga lateral da grade desigual" % label)
		_check(scroll_rect.end.y <= screen.y and scroll_rect.position.y >= 100.0, "[%s] grade fora da área útil %s" % [label, scroll_rect])
		for card in cards:
			var rect := card.get_global_rect()
			if not scroll_rect.intersects(rect.grow(-4.0)) or rect.position.y < scroll_rect.position.y - 1.0 or rect.end.y > scroll_rect.end.y + 1.0:
				continue
			for node_name: String in ["Caption", "Pack", "Price", "DailyLeft", "LockText", "Have", "Coin"]:
				var node := card.find_child(node_name, true, false) as Control
				if node == null:
					continue
				var node_rect := node.get_global_rect()
				if node is Label:
					var text_label := node as Label
					var font := text_label.get_theme_font("font")
					var size := text_label.get_theme_font_size("font_size")
					if node_name in ["Caption", "LockText"]:
						_check(text_label.get_line_count() <= 2, "[%s] %s com mais de 2 linhas em %s" % [label, node_name, card.name])
						_check(not text_label.get_visible_line_count() < text_label.get_line_count(), "[%s] %s cortado em %s: %s" % [label, node_name, card.name, text_label.text])
					else:
						var width := font.get_string_size(text_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
						_check(node_rect.position.x + width <= rect.end.x - 3.0, "[%s] %s passa da borda em %s" % [label, node_name, card.name])
				_check(node_rect.end.x <= rect.end.x - 2.0 and node_rect.position.x >= rect.position.x + 2.0, "[%s] %s fora do cartão %s" % [label, node_name, card.name])
				_check(node_rect.end.y <= rect.end.y - 2.0 and node_rect.position.y >= rect.position.y + 2.0, "[%s] %s fora (vertical) do cartão %s" % [label, node_name, card.name])
			var slot := card.find_child("Picture", true, false) as Control
			if slot:
				_check(_near(slot.get_global_rect().get_center().y, rect.get_center().y, 2.0), "[%s] ícone fora do centro vertical em %s" % [label, card.name])
	print(info)
	for node_name: String in ["CloseButton", "Minus", "Plus", "QuantityMax", "SellSelected", "BuyItem", "Locked_BuyItem"]:
		var button := sheet.find_child(node_name, true, false) as Control
		if button and button.is_visible_in_tree():
			var size := button.get_global_rect().size
			_check(size.x >= 43.5 and size.y >= 43.5, "[%s] %s menor que 44: %s" % [label, node_name, size])
	var board := sheet.find_child("SellPanel", true, false) as Control
	if board:
		var board_rect := board.get_global_rect()
		_check(_near(board_rect.get_center().x, screen.x / 2.0, 1.0), "[%s] tábua fora do centro da tela" % label)
		_check(board_rect.end.y <= screen.y + 0.5, "[%s] tábua passa do fim da tela (%.1f > %.1f)" % [label, board_rect.end.y, screen.y])
		var summary := board.find_child("SellSummary", true, false) as Label
		if summary:
			_check(summary.get_global_rect().end.x <= board_rect.end.x - 6.0, "[%s] resumo passa da tábua" % label)
		var total := board.find_child("BuyTotalValue" if tab == "buy" else "SellTotalValue", true, false) as Label
		if total:
			var font := total.get_theme_font("font")
			var width := font.get_string_size(total.text, HORIZONTAL_ALIGNMENT_LEFT, -1, total.get_theme_font_size("font_size")).x
			_check(width <= total.get_global_rect().size.x + 0.5, "[%s] total passa da caixinha" % label)
		var action: Control = board.find_child("BuyItem", true, false) as Control
		if action == null:
			action = board.find_child("Locked_BuyItem", true, false) as Control
		if tab == "buy" and action:
			_check(action.get_global_rect().end.x <= board_rect.end.x - 6.0, "[%s] botão de compra passa da tábua" % label)
			_check(board_rect.encloses(action.get_global_rect()), "[%s] botão de compra fora da tábua" % label)
		print("  tábua %s" % board_rect)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "shop_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	var events: Node = root.get_node("Events")
	var none: Array[String] = []
	var bamboo: Array[String] = ["bamboo_rod"]
	var both: Array[String] = ["bamboo_rod", "reel_rod", "angler_rod"]

	await _setup(false, none, 300, false)
	await _open("farm", "a_sem_abas", "sell")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _setup(true, none, 300, false)
	await _open("farm", "b_com_abas_vender", "sell")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _open("farm", "c_comprar_1_pacote", "buy")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _setup(true, bamboo, 300, false)
	await _open("farm", "d_comprar_3_pacotes_bloqueio", "buy", "worm_pack", 2)
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _setup(true, bamboo, 3, false)
	await _open("farm", "e_sem_moedas", "buy", "worm_pack")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _setup(true, none, 300, false)
	await _open("farm", "f_limite_do_dia", "buy", "food_stall", 1, 1)
	await _open("farm", "f2_limite_esgotado", "buy", "food_stall", 0, 1)
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _setup(true, both, 300, true)
	await _open("village", "g_feirante_massa_e_isca", "buy", "dough_pack", 1)
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	print("SHOP SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
