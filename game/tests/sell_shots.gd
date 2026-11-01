extends SceneTree
## Capturas e MEDIDAS da tela de venda "madeira ilustrada" (Sítio e Vila). NÃO é teste da suíte, mas imprime FAIL e sai
## com código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/sell_shots.gd -- --out=sell_wood
## PNGs em build/screenshots/<out>/sell_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/sell_wood/"
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


func _sellable() -> Array[String]:
	var ids: Array[String] = []
	for id: String in root.get_node("Database").get("items"):
		if int(root.get_node("Database").get("items")[id].get("sell_price", 0)) > 0:
			ids.append(id)
	return ids


func _stock(count: int, amount: int, long_name: bool) -> void:
	await _stock_now(count, amount, long_name)
	await create_timer(1.2).timeout
	_hide_modals()
	main.set("_modal_queue", [] as Array[Callable])


func _stock_now(count: int, amount: int, long_name: bool) -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("inventory").call("from_dict", {})
	var db: Node = root.get_node("Database")
	var ids := _sellable()
	if long_name:
		ids.sort_custom(func(a: String, b: String) -> bool: return str(db.call("item_name", a)).length() > str(db.call("item_name", b)).length())
	var given := 0
	for id in ids:
		if given >= count:
			break
		state.get("inventory").call("add", id, amount + given % 4)
		given += 1


func _open(world: String, shot_name: String, presses: int = 0, wait: float = 0.9) -> void:
	var who: Dictionary = (load("res://scripts/ui/sell_ui.gd") as Script).call("seller", world)
	root.get_node("Events").sheet_requested.emit(str(who.title), (load("res://scripts/ui/market_ui.gd") as Script).call("sell", world))
	await create_timer(wait).timeout
	for i in presses:
		var plus := sheet.find_child("Plus", true, false) as Button
		if plus:
			plus.pressed.emit()
			await create_timer(0.25).timeout
	await create_timer(0.5).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "sell_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(shot_name, str(who.npc))


func _near(a: float, b: float, tolerance: float) -> bool:
	return absf(a - b) <= tolerance


func _measure(label: String, npc_id: String) -> void:
	var screen := root.get_visible_rect().size
	var frame := sheet.find_child("SellFrame", true, false) as Control
	if frame == null:
		_check(false, "[%s] sem SellFrame" % label)
		return
	var frame_rect := frame.get_global_rect()
	_check(frame_rect.position.x >= 0.0 and frame_rect.end.x <= screen.x, "[%s] moldura fora da tela %s" % [label, frame_rect])
	_check(_near(frame_rect.get_center().x, screen.x / 2.0, 1.0), "[%s] moldura não centralizada (%.1f x %.1f)" % [label, frame_rect.get_center().x, screen.x / 2.0])
	var grid := sheet.find_child("SellGrid", true, false) as GridContainer
	var info := "[%s] tela %dx%d moldura %s" % [label, screen.x, screen.y, frame_rect]
	if grid != null:
		var scroll := sheet.find_child("SellScroll", true, false) as Control
		var cards: Array[Control] = []
		for child in grid.get_children():
			cards.append(child as Control)
		var xs := {}
		var height := 0.0
		for card in cards:
			var key := int(roundf(card.global_position.x))
			if not xs.has(key):
				xs[key] = card.size.x
			_check(_near(card.size.x, cards[0].size.x, 1.0), "[%s] cartão de largura diferente %s" % [label, card.name])
			_check(_near(card.size.y, cards[0].size.y, 1.0), "[%s] cartão de altura diferente %s" % [label, card.name])
			height = card.size.y
		_check(xs.size() <= 2, "[%s] mais de duas colunas: %s" % [label, xs.keys()])
		var scroll_rect := scroll.get_global_rect()
		var gap_left := grid.global_position.x - scroll_rect.position.x
		var gap_right := scroll_rect.end.x - (grid.global_position.x + grid.size.x)
		_check(_near(gap_left, gap_right, 1.0), "[%s] folga esquerda %.1f != direita %.1f" % [label, gap_left, gap_right])
		var wood_left := grid.global_position.x - frame_rect.position.x
		var wood_right := frame_rect.end.x - (grid.global_position.x + grid.size.x)
		if not (sheet.find_child("ScrollGutter", true, false) as Control).visible:
			var cream_left := wood_left - 28.0
			var cream_right := wood_right - 26.0
			_check(_near(cream_left, cream_right, 1.0), "[%s] folga até o creme: esquerda %.1f != direita %.1f" % [label, cream_left, cream_right])
		info += " cartões %d colunas %s altura %.0f folga grade %.1f/%.1f madeira->grade %.1f grade->madeira %.1f" % [cards.size(), xs.values(), height, gap_left, gap_right, wood_left, wood_right]
		# Só os cartões visíveis na rolagem entram nas medidas de texto.
		for card in cards:
			var rect := card.get_global_rect()
			if not scroll_rect.intersects(rect.grow(-4.0)):
				continue
			if rect.position.y < scroll_rect.position.y - 1.0 or rect.end.y > scroll_rect.end.y + 1.0:
				continue
			for node_name: String in ["Caption", "Price", "Have", "Coin"]:
				var node := card.find_child(node_name, true, false) as Control
				if node == null:
					continue
				var node_rect := node.get_global_rect()
				var needed := node_rect.size
				if node is Label:
					var text_label := node as Label
					var font := text_label.get_theme_font("font")
					var size := text_label.get_theme_font_size("font_size")
					if node_name == "Caption":
						_check(text_label.get_line_count() <= 2, "[%s] nome com mais de 2 linhas em %s" % [label, card.name])
						_check(not text_label.get_visible_line_count() < text_label.get_line_count(), "[%s] nome cortado em %s: %s" % [label, card.name, text_label.text])
						_check(node_rect.end.x <= rect.end.x - 3.0, "[%s] nome passa da borda em %s" % [label, card.name])
					else:
						needed.x = font.get_string_size(text_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
						_check(node_rect.position.x + needed.x <= rect.end.x - 3.0, "[%s] %s passa da borda em %s (%.1f > %.1f)" % [label, node_name, card.name, node_rect.position.x + needed.x, rect.end.x - 3.0])
				_check(node_rect.end.x <= rect.end.x - 2.0 and node_rect.position.x >= rect.position.x + 2.0, "[%s] %s fora do cartão %s" % [label, node_name, card.name])
				_check(node_rect.end.y <= rect.end.y - 2.0 and node_rect.position.y >= rect.position.y + 2.0, "[%s] %s fora (vertical) do cartão %s" % [label, node_name, card.name])
			var slot := card.find_child("Picture", true, false) as Control
			if slot:
				_check(_near(slot.get_global_rect().get_center().y, rect.get_center().y, 2.0), "[%s] ícone fora do centro vertical em %s" % [label, card.name])
	print(info)
	for node_name: String in ["CloseButton", "Minus", "Plus", "QuantityMax", "SellSelected"]:
		var button := sheet.find_child(node_name, true, false) as Control
		if button and button.is_visible_in_tree():
			var size := button.get_global_rect().size
			_check(size.x >= 43.5 and size.y >= 43.5, "[%s] %s menor que 44: %s" % [label, node_name, size])
	for child in (grid.get_children() if grid else []):
		_check((child as Control).size.y >= 43.5 and (child as Control).size.x >= 43.5, "[%s] cartão menor que 44" % label)
	var board := sheet.find_child("SellPanel", true, false) as Control
	if board:
		var board_rect := board.get_global_rect()
		_check(_near(board_rect.get_center().x, frame_rect.get_center().x, 1.0), "[%s] tábua não centralizada %.1f x %.1f" % [label, board_rect.get_center().x, frame_rect.get_center().x])
		_check(_near(board_rect.get_center().x, screen.x / 2.0, 1.0), "[%s] tábua fora do centro da tela" % label)
		_check(board_rect.end.y <= screen.y + 0.5, "[%s] tábua passa do fim da tela" % label)
		# Título no alto; retrato e controles centralizados entre si na faixa de baixo.
		var controls := board.find_child("SellControls", true, false) as Control
		var face := board.find_child("SellerPortrait", true, false) as Control
		if controls and face:
			_check(_near(face.get_global_rect().get_center().y, controls.get_global_rect().get_center().y, 1.0), "[%s] retrato fora do centro dos controles (%.1f x %.1f)" % [label, face.get_global_rect().get_center().y, controls.get_global_rect().get_center().y])
		var title := board.find_child("SellSummary", true, false) as Control
		if title:
			_check(_near(title.get_global_rect().get_center().x, board_rect.get_center().x, 1.0), "[%s] título da tábua fora do centro" % label)
		# Linhas de controles alinhadas nas duas pontas.
		var minus := board.find_child("Minus", true, false) as Control
		var pill_left := board.find_child("SellTotal", true, false) as Control
		var max_button := board.find_child("QuantityMax", true, false) as Control
		var sell_button := board.find_child("SellSelected", true, false) as Control
		if minus and pill_left and max_button and sell_button:
			_check(_near(minus.get_global_rect().position.x, pill_left.get_global_rect().position.x, 1.0), "[%s] − e total não alinham à esquerda" % label)
			_check(_near(max_button.get_global_rect().end.x, sell_button.get_global_rect().end.x, 1.0), "[%s] Máx e Vender não alinham à direita" % label)
		_check(board.find_child("SellerPortrait", true, false) != null or npc_missing(npc_id), "[%s] sem retrato do vendedor %s" % [label, npc_id])
		var total := board.find_child("SellTotalValue", true, false) as Label
		var pill := board.find_child("SellTotal", true, false) as Control
		if total and pill:
			var font := total.get_theme_font("font")
			var width := font.get_string_size(total.text, HORIZONTAL_ALIGNMENT_LEFT, -1, total.get_theme_font_size("font_size")).x
			_check(width <= total.get_global_rect().size.x + 0.5, "[%s] total passa da caixinha (%.1f > %.1f)" % [label, width, total.get_global_rect().size.x])
		var summary := board.find_child("SellSummary", true, false) as Label
		if summary:
			_check(summary.get_global_rect().end.x <= board_rect.end.x - 6.0, "[%s] resumo passa da tábua" % label)
		for pair: Array in [["Minus", "Plus"], ["QuantityMax", "SellSelected"]]:
			var a := board.find_child(pair[0], true, false) as Control
			var b := board.find_child(pair[1], true, false) as Control
			if a and b:
				_check(_near(a.get_global_rect().get_center().y, b.get_global_rect().get_center().y, 2.0) or pair[0] == "QuantityMax", "[%s] %s e %s desalinhados" % [label, pair[0], pair[1]])
		print("  tábua %s retrato %s" % [board_rect, npc_id])


func npc_missing(npc_id: String) -> bool:
	return str(root.get_node("Database").get("npcs").get(npc_id, {}).get("portrait", "")) == ""


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "sell_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	var events: Node = root.get_node("Events")

	await _stock(5, 4, false)
	await _open("farm", "a_sitio_poucos")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _stock(30, 12, false)
	await _open("village", "b_vila_muitos")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _stock(9, 6, true)
	await _open("village", "c_vila_nome_longo")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _stock(6, 9, false)
	await _open("farm", "d_sitio_quantidade_3", 2)
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _stock(1, 1, false)
	await _open("village", "e_vila_um_item")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _stock(0, 0, false)
	await _open("village", "f_vazio")

	print("SELL SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
