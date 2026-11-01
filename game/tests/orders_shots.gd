extends SceneTree
## Capturas e MEDIDAS da tela de encomendas "madeira ilustrada" (vizinhos e banca). NÃO é teste da suíte, mas imprime FAIL e
## sai com código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/orders_shots.gd -- --out=orders_wood
## PNGs em build/screenshots/<out>/orders_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/orders_wood/"
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


func _unlock() -> void:
	_unlock_now()
	await create_timer(1.2).timeout
	_hide_modals()


func _unlock_now() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("inventory").call("from_dict", {})
	state.get("progress").cooldowns.clear()


func _stock(items: Dictionary) -> void:
	state.get("inventory").call("from_dict", items)


func _open(shot_name: String, focus: String = "", channel: String = "neighbors", scroll_to: int = -1) -> void:
	root.get_node("Events").sheet_requested.emit("Encomendas", (load("res://scripts/ui/market_ui.gd") as Script).call("orders", focus, channel))
	await create_timer(1.0).timeout
	if scroll_to >= 0:
		var list := sheet.find_child("OrderScroll", true, false) as ScrollContainer
		if list:
			list.scroll_vertical = scroll_to
			await create_timer(0.3).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "orders_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(shot_name)


func _near(a: float, b: float, tolerance: float) -> bool:
	return absf(a - b) <= tolerance


func _text_fits(label: Label, box: Rect2, name_: String, label_name: String) -> void:
	if label == null:
		return
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var rect := label.get_global_rect()
	_check(rect.position.x >= box.position.x - 0.5 and rect.end.x <= box.end.x + 0.5, "[%s] %s fora da caixa %s (%s vs %s)" % [label_name, name_, label.text, rect, box])
	if not label.clip_text:
		_check(width <= rect.size.x + 0.5, "[%s] %s passa da sua caixa (%.1f > %.1f): %s" % [label_name, name_, width, rect.size.x, label.text])


func _measure(label: String) -> void:
	var screen := root.get_visible_rect().size
	var frame := sheet.find_child("OrderFrame", true, false) as Control
	if frame == null:
		_check(false, "[%s] sem OrderFrame" % label)
		return
	var fr := frame.get_global_rect()
	_check(fr.position.x >= 0.0 and fr.end.x <= screen.x, "[%s] moldura fora da tela %s" % [label, fr])
	_check(_near(fr.get_center().x, screen.x / 2.0, 1.0), "[%s] moldura não centralizada (%.1f x %.1f)" % [label, fr.get_center().x, screen.x / 2.0])
	_check(_near(fr.position.x, screen.x - fr.end.x, 1.0), "[%s] folgas da moldura diferentes %.1f / %.1f" % [label, fr.position.x, screen.x - fr.end.x])
	var info := "[%s] tela %dx%d moldura %s" % [label, screen.x, screen.y, fr]
	var scroll := sheet.find_child("OrderScroll", true, false) as Control
	var grid := sheet.find_child("OrderGrid", true, false) as Control
	var cards: Array[Control] = []
	if grid:
		for child in grid.get_children():
			if str(child.name).begins_with("Order_"):
				cards.append(child as Control)
	var scroll_rect := scroll.get_global_rect() if scroll else Rect2()
	var gutter := sheet.find_child("ScrollGutter", true, false) as Control
	var bar_visible := gutter != null and gutter.visible
	if not cards.is_empty():
		var first := cards[0]
		var fr0 := first.get_global_rect()
		var card_pad := 10.0
		var reward_x: float = first.find_child("Reward", true, false).get_global_rect().position.x - fr0.position.x
		var status_gap: float = fr0.end.x - first.find_child("Status", true, false).get_global_rect().end.x
		var icons_x: float = first.find_child("Ingredients", true, false).get_global_rect().position.x - fr0.position.x
		for card in cards:
			var rect := card.get_global_rect()
			_check(_near(card.size.x, first.size.x, 1.0) and _near(card.size.y, first.size.y, 1.0), "[%s] cartão de tamanho diferente %s" % [label, card.name])
			_check(_near(rect.position.x, fr0.position.x, 1.0), "[%s] cartão em outra borda esquerda %s" % [label, card.name])
			_check(rect.size.x >= 43.5 and rect.size.y >= 43.5, "[%s] cartão menor que 44" % label)
			if not scroll_rect.intersects(rect.grow(-4.0)):
				continue
			if rect.position.y < scroll_rect.position.y - 1.0 or rect.end.y > scroll_rect.end.y + 1.0:
				continue
			var bottom := card.find_child("BottomRow", true, false) as Control
			var row_center := bottom.get_global_rect().get_center().y
			for part: String in ["Ingredients", "Reward", "Status"]:
				var node := card.find_child(part, true, false) as Control
				_check(node != null and _near(node.get_global_rect().get_center().y, row_center, 1.0), "[%s] %s fora do centro vertical da linha em %s" % [label, part, card.name])
			_check(bottom.get_global_rect().position.y - rect.position.y >= 8.0 + 28.0 + 5.5 and rect.end.y - bottom.get_global_rect().end.y >= 7.5, "[%s] linha de baixo desalinhada no cartão %s" % [label, card.name])
			var reward := card.find_child("Reward", true, false) as Control
			_check(_near(reward.get_global_rect().position.x - rect.position.x, reward_x, 1.0), "[%s] prêmio fora da coluna em %s" % [label, card.name])
			_check(_near(card.find_child("Ingredients", true, false).get_global_rect().position.x - rect.position.x, icons_x, 1.0), "[%s] ícones fora da coluna em %s" % [label, card.name])
			var status_rect := (card.find_child("Status", true, false) as Control).get_global_rect()
			_check(_near(rect.end.x - status_rect.end.x, status_gap, 1.0), "[%s] botão fora da borda direita em %s" % [label, card.name])
			_check(status_rect.position.x >= reward.get_global_rect().end.x + 3.0, "[%s] botão encosta no prêmio em %s" % [label, card.name])
			var status_label := card.find_child("StatusLabel", true, false) as Label
			var text_w := status_label.get_theme_font("font").get_string_size(status_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, status_label.get_theme_font_size("font_size")).x
			if status_label.get_parent().name == "Status" and status_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT:
				_check((status_rect.size.x - text_w) / 2.0 >= 6.0, "[%s] texto do botão sem folga de 6 px (%.1f de %.1f) em %s" % [label, text_w, status_rect.size.x, card.name])
			_text_fits(card.find_child("RewardValue", true, false) as Label, reward.get_global_rect(), "RewardValue", label)
			var face_node := card.find_child("Customer_*", true, false) as Control
			var caption := card.find_child("Caption", true, false) as Label
			if face_node:
				_check(_near(face_node.get_global_rect().position.x, card.find_child("Ingredients", true, false).get_global_rect().position.x, 1.0), "[%s] retrato e primeiro ingrediente em x diferente em %s" % [label, card.name])
				_check(_near(face_node.get_global_rect().position.x - rect.position.x, card_pad, 1.0), "[%s] retrato fora da margem de 10 px em %s" % [label, card.name])
				_check(face_node.get_global_rect().size.x >= 27.5, "[%s] retrato menor que 28" % label)
				_check(caption.get_global_rect().position.x - face_node.get_global_rect().end.x <= 8.5, "[%s] nome longe do retrato em %s" % [label, card.name])
				_check(not face_node.get_global_rect().intersects(caption.get_global_rect()), "[%s] retrato sobre o nome em %s" % [label, card.name])
			_check(caption.get_theme_font_size("font_size") >= 13, "[%s] nome menor que 13 em %s" % [label, card.name])
			_check(caption.get_global_rect().end.x <= rect.end.x - card_pad + 0.5 and caption.get_global_rect().position.x >= rect.position.x, "[%s] nome fora do cartão em %s %s %s" % [label, card.name, caption.get_global_rect(), rect])
			var area := (card.find_child("Ingredients", true, false) as Control).get_global_rect()
			# Ícones: cada um com espaço próprio (sem cruzar, >= 4 px entre eles) e dentro da área de ingredientes.
			var rects: Array[Rect2] = []
			for need in (card.find_child("Ingredients", true, false) as Control).get_children():
				var ir := (need.find_child("Icon", true, false) as Control).get_global_rect()
				_check(area.grow(0.5).encloses(ir), "[%s] ícone fora da área de ingredientes em %s" % [label, card.name])
				_check(_near(ir.get_center().y, row_center, 1.0), "[%s] ícone fora do centro vertical em %s" % [label, card.name])
				for other in rects:
					_check(not ir.intersects(other) and (ir.position.x - other.end.x >= 3.5 or other.position.x - ir.end.x >= 3.5), "[%s] ícones colados/sobrepostos em %s" % [label, card.name])
				rects.append(ir)
			_check(area.end.x <= reward.get_global_rect().position.x + 0.5, "[%s] ingredientes invadem o prêmio em %s" % [label, card.name])
		if not bar_visible:
			var left := fr0.position.x - fr.position.x
			var right := fr.end.x - fr0.end.x
			_check(_near(left, right, 1.0), "[%s] folga até a moldura: esquerda %.1f != direita %.1f" % [label, left, right])
		info += " cartões %d tamanho %s barra %s" % [cards.size(), first.size, bar_visible]
	print(info)
	for node_name: String in ["CloseButton", "OrdersHelp", "DeliverOrder", "UpgradeStall"]:
		var button := sheet.find_child(node_name, true, false) as Control
		if button and button.is_visible_in_tree():
			var size := button.get_global_rect().size
			_check(size.x >= 43.5 and size.y >= 43.5, "[%s] %s menor que 44: %s" % [label, node_name, size])
	var top := sheet.find_child("TopPill", true, false) as Control
	if top:
		for child in top.find_children("Customer_*", "Button", true, false):
			_check((child as Control).get_global_rect().size.y >= 43.5, "[%s] cliente menor que 44" % label)
	var board := sheet.find_child("OrderDetail", true, false) as Control
	if board:
		var br := board.get_global_rect()
		_check(_near(br.get_center().x, fr.get_center().x, 1.0), "[%s] tábua não centralizada" % label)
		_check(br.end.y <= screen.y + 0.5, "[%s] tábua passa do fim da tela (%.1f > %.1f)" % [label, br.end.y, screen.y])
		var left_area := board.find_child("Area_delivery", true, false) as Control
		var right_area := board.find_child("Area_prize", true, false) as Control
		_check(_near(left_area.get_global_rect().position.y, right_area.get_global_rect().position.y, 1.0) and _near(left_area.size.y, right_area.size.y, 1.0), "[%s] áreas da tábua desalinhadas" % label)
		_check(_near(left_area.get_global_rect().position.x - br.position.x, br.end.x - right_area.get_global_rect().end.x, 1.0), "[%s] áreas com folgas laterais diferentes" % label)
		for key: String in ["delivery", "prize"]:
			var area := board.find_child("Area_" + key, true, false) as Control
			var title := board.find_child("AreaTitle_" + key, true, false) as Control
			_check(_near(title.get_global_rect().get_center().x, area.get_global_rect().get_center().x, 1.0), "[%s] título %s fora do centro da área" % [label, key])
		var action := board.find_child("DeliverOrder", true, false) as Control
		if action == null:
			action = board.find_child("Locked_DeliverOrder", true, false) as Control
		_check(action != null, "[%s] sem Entregar nem cadeado" % label)
		if action:
			var ar := right_area.get_global_rect()
			_check(_near(action.get_global_rect().position.x - ar.position.x, ar.end.x - action.get_global_rect().end.x, 1.0), "[%s] botão Entregar fora do centro da área" % label)
			_check(_near(action.get_global_rect().end.y, ar.end.y - 8.0, 1.5), "[%s] botão Entregar longe do pé da área (%.1f x %.1f)" % [label, action.get_global_rect().end.y, ar.end.y - 8.0])
		var locked := board.find_child("Locked_DeliverOrder", true, false) as Control
		if locked:
			var note: Label = null
			for node in locked.find_children("*", "Label", true, false):
				note = node as Label
			_check(note.get_theme_font_size("font_size") >= 13, "[%s] aviso de bloqueio menor que 13" % label)
			var lines := note.get_line_count()
			_check(lines <= 2, "[%s] aviso de bloqueio com %d linhas" % [label, lines])
			_check(note.get_visible_line_count() >= lines, "[%s] aviso de bloqueio cortado: %s" % [label, note.text])
			var coin_center := (board.find_child("PrizeCoins", true, false) as Control).get_global_rect().get_center().x
			_check(_near(locked.get_global_rect().get_center().x, coin_center, 1.5), "[%s] aviso fora do eixo da moeda" % label)
		var prize := board.find_child("PrizeValue", true, false) as Label
		if prize:
			_text_fits(prize, right_area.get_global_rect(), "PrizeValue", label)
		for need in board.find_children("Ingredient_*", "Button", true, false):
			var nr := (need as Control).get_global_rect()
			_check(nr.size.x >= 43.5 and nr.size.y >= 43.5, "[%s] ingrediente menor que 44" % label)
			_check(left_area.get_global_rect().encloses(nr), "[%s] ingrediente fora da área %s" % [label, need.name])
			var count := need.find_child("CountLabel", true, false) as Label
			_text_fits(count, (need.find_child("Count", true, false) as Control).get_global_rect(), "CountLabel", label)
		var title_label := board.find_child("AreaTitle_delivery", true, false) as Label
		var text_w := title_label.get_theme_font("font").get_string_size(title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_label.get_theme_font_size("font_size")).x
		var text_rect := Rect2(title_label.get_global_rect().get_center().x - text_w / 2.0, title_label.get_global_rect().position.y, text_w, title_label.size.y)
		for tagged in board.find_children("Customer_*", "", true, false):
			_check(not (tagged as Control).get_global_rect().intersects(text_rect), "[%s] rosto do cliente cruza o título da área" % label)
		print("  tábua ", br)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "orders_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	var events: Node = root.get_node("Events")
	var market := load("res://scripts/ui/market_ui.gd") as Script

	# a: poucos pedidos (início do jogo, ainda sem tudo liberado)
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("_mark_all_seen")
	await create_timer(0.6).timeout
	_hide_modals()
	print("pedidos neighbors no começo: ", market.call("order_ids", "neighbors"))
	await _open("a_poucos")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	print("pedidos neighbors liberados: ", market.call("order_ids", "neighbors"))
	await _open("b_muitos")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	_stock({"carrot": 4})
	await _open("c_pronto_escolhido", "vegetables")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	await _open("d_faltando_escolhido", "soup_order")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	state.get("progress").cooldowns["order:vegetables"] = float(state.call("now")) + 4500.0
	await _open("e_recarga", "vegetables")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	for quest in ["main_6_commerce", "main_2_order", "merchant_variety"]:
		state.get("progress").claimed_quests.erase(quest)
	state.get("progress").stats["order:vegetables"] = 0
	state.get("progress").stats["order:snacks"] = 0
	state.call("_changed")
	await create_timer(0.4).timeout
	await _open("f_missao", "vegetables")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	var orders: Dictionary = root.get_node("Database").get("progression").orders
	var old_name: String = orders["vegetables"]["name"]
	orders["vegetables"]["name"] = "Cesta de legumes fresquinhos da vovó Bloblo"
	await _open("g_nome_longo", "vegetables")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout
	orders["vegetables"]["name"] = old_name

	await _unlock()
	_stock({"plank": 4, "brick": 4})
	await _open("h_contratos_pronto", "building_order", "contracts")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	await _open("i_contratos", "", "contracts")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	state.get("progress").owned.erase("stall_3")
	state.get("progress").owned.erase("stall_2")
	state.get("progress").stats["contracts"] = 3
	state.call("_changed")
	await create_timer(0.4).timeout
	await _open("m_banca_nivel_1", "", "contracts")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	await _open("j_muitos_rolados", "", "neighbors", 9999)
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	await _unlock()
	_stock({"fabric": 4, "treat_box": 4, "strawberry_pop": 4})
	await _open("k_festival", "festival_contract", "contracts")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	state.call("reset")
	state.get("progress").seen["intro"] = true
	await _open("l_vazio", "", "contracts")

	print("ORDERS SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
