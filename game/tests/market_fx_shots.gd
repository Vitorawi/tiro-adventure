extends SceneTree
## Capturas dos efeitos da banca (venda e compra): meio do voo + mensagenzinha. NÃO é teste da suíte;
## imprime FAIL (e sai com 1) se a mensagem sair da tela ou ficar sob o HUD. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/market_fx_shots.gd
## PNGs em build/screenshots/market_fx/. Não grava o save pessoal.

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/market_fx/"
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


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


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	image.save_png(path + "fx_%dx%d_%s.png" % [image.get_width(), image.get_height(), name])
	var message := main.get_tree().root.find_child("MarketMessage", true, false) as Label
	if message == null:
		_check(false, "[%s] sem mensagem" % name)
		return
	var rect := message.get_global_rect()
	var screen := root.get_visible_rect().size
	_check(rect.position.x >= 0.0 and rect.end.x <= screen.x, "[%s] mensagem fora da tela nas laterais %s" % [name, rect])
	_check(rect.position.y >= 100.0 and rect.end.y <= screen.y, "[%s] mensagem sob o HUD ou fora embaixo %s" % [name, rect])
	print("  ok [%s] mensagem %s" % [name, rect])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fx_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 900)
	state.get("inventory").call("from_dict", {})
	state.get("inventory").call("add", "carrot", 6)
	state.get("inventory").call("add", "egg", 4)
	await create_timer(1.0).timeout
	_hide_modals()
	var events: Node = root.get_node("Events")
	var sell_ui: Script = load("res://scripts/ui/sell_ui.gd")
	var who: Dictionary = sell_ui.call("seller", "farm")

	# Venda: toca no botão e captura no meio do voo.
	sell_ui.set("last_tab", "sell")
	events.sheet_requested.emit(str(who.title), (load("res://scripts/ui/market_ui.gd") as Script).call("sell", "farm"))
	await create_timer(1.0).timeout
	_hide_modals()
	var sell_button := sheet.find_child("SellSelected", true, false) as Button
	if sell_button == null:
		_check(false, "sem botão Vender")
	else:
		sell_button.pressed.emit()
		await create_timer(0.3).timeout
		await _shot("a_venda")
	await create_timer(1.6).timeout
	_check(root.find_child("MarketMessage", true, false) == null, "a mensagem da venda não sumiu")
	events.sheet_close_requested.emit()
	await create_timer(0.6).timeout

	# Compra: aba Comprar, escolhe o primeiro pacote liberado.
	state.get("progress").claimed_quests["bloblo_meet"] = true
	sell_ui.set("last_tab", "buy")
	events.sheet_requested.emit(str(who.title), (load("res://scripts/ui/market_ui.gd") as Script).call("sell", "farm"))
	await create_timer(1.0).timeout
	_hide_modals()
	for pack: String in state.call("shop_items", "farm_stall"):
		if not Database_has_ready(pack) and state.call("shop_item_locked", pack) == "":
			sheet.find_child("Buy_" + pack, true, false).pressed.emit()
			await create_timer(0.3).timeout
			break
	var buy_button := sheet.find_child("BuyItem", true, false) as Button
	if buy_button == null:
		_check(false, "sem botão Comprar")
	else:
		buy_button.pressed.emit()
		await create_timer(0.3).timeout
		await _shot("b_compra")
	await create_timer(1.6).timeout
	events.sheet_close_requested.emit()
	await create_timer(0.4).timeout
	_check(root.find_child("MarketFxLayer", true, false) == null or (root.find_child("MarketFxLayer", true, false) as Node).get_child_count() == 0, "efeitos presos após fechar a folha")
	print("MARKET FX SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func Database_has_ready(pack: String) -> bool:
	return (state.call("shop_pack", pack) as Dictionary).has("ready")
