extends SceneTree
## Capturas e MEDIDAS da etapa 07 da pesca: Feirante com a vara de molinete, painel com duas varas, minigame com baú
## (meio cheio), resultado com "Baú!" e o Aventureiro pedindo o ensopado. NÃO é teste da suíte; imprime FAIL e sai com 1
## se a geometria sair torta. Rodar SEM --headless, uma resolução por vez:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fishing_rod2_shots.gd -- --out=fishing_07
## PNGs em build/screenshots/<out>/rod2_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

const HUD_HEIGHT := 168.0

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/fishing_07/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(600).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_growth_ceremony", "_quest_reward", "_walk_result"]:
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


func _farm() -> Control:
	return main.find_child("World_farm", true, false) as Control


func _flow() -> Node:
	return _farm().call("fishing_flow") if _farm() != null else null


func _panel() -> Control:
	var node := _farm().find_child("FishingPanel", false, false) as Control
	return node if node != null and not bool(node.get("_closing")) else null


func _tabs_top() -> float:
	return (main.find_child("TabBarArt", true, false) as Control).global_position.y


## Chapter 5 aberto, Pesca nível 3 e o que cada tela precisa; sempre o jogo limpo antes.
func _fresh(rods: Array[String], fiber: int = 0, coins: int = 500) -> void:
	if _flow() != null:
		_flow().call("end")
	state.call("cancel_fishing")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("inventory").call("from_dict", {})
	state.get("fishing").xp = 100
	state.get("fishing").rods.clear()
	for rod in rods:
		state.call("give_rod", rod)
	state.get("fishing").tutorial["done"] = true
	state.get("inventory").add("fiber", fiber)
	state.get("inventory").add("bait_worm", 4)
	state.get("inventory").add("bait_dough", 4)
	state.set("coins", coins)
	state.call("_changed")
	await create_timer(0.6).timeout
	_hide_modals()


func _snap(shot_name: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "rod2_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _measure(node: Control, label: String, button: bool = false, under_tabs: bool = true) -> void:
	if node == null or not node.is_visible_in_tree():
		_check(false, label + " visível")
		return
	var rect := node.get_global_rect()
	var screen := root.get_visible_rect()
	_check(rect.position.x >= -0.5 and rect.end.x <= screen.end.x + 0.5, "%s dentro da tela (%s)" % [label, rect])
	_check(rect.position.y >= HUD_HEIGHT - 0.5, "%s sob o HUD (y %.0f)" % [label, rect.position.y])
	if under_tabs:
		_check(rect.end.y <= _tabs_top() + 0.5, "%s sob as abas (fim %.0f, abas %.0f)" % [label, rect.end.y, _tabs_top()])
	if button:
		_check(rect.size.x >= 43.5 and rect.size.y >= 43.5, "%s alvo >= 44 (%s)" % [label, rect.size])


func _clipped(root_node: Node) -> void:
	for node in root_node.find_children("*", "Label", true, false):
		var label := node as Label
		if not label.is_visible_in_tree() or label.text == "" or label.autowrap_mode != TextServer.AUTOWRAP_OFF or label.clip_text:
			continue
		_check(label.size.x + 1.0 >= label.get_minimum_size().x or label.size.x < 1.0, "texto cortado: '%s'" % label.text)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "fishing_rod2_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await create_timer(1.5).timeout
	_hide_modals()
	var events: Node = root.get_node("Events")
	var db: Node = root.get_node("Database")
	var bamboo: Array[String] = ["bamboo_rod"]
	var two: Array[String] = ["bamboo_rod", "reel_rod"]

	# 1) Feirante: a vara de molinete à venda (com tudo em mãos) e sem as fibras.
	for case: Array in [["a_feirante_vara", 4, 500], ["b_feirante_sem_fibras", 0, 500], ["c_feirante_sem_moedas", 4, 60]]:
		await _fresh(bamboo, int(case[1]), int(case[2]))
		var sell_ui: Script = load("res://scripts/ui/sell_ui.gd")
		sell_ui.set("open_tab", "buy")
		sell_ui.set("open_pack", "reel_rod_pack")
		var who: Dictionary = sell_ui.call("seller", "village")
		var shop_id: String = db.call("shop_of_place", "village", str(who.place))
		events.sheet_requested.emit(str(db.call("shop", shop_id).get("name", who.title)), (load("res://scripts/ui/market_ui.gd") as Script).call("sell", "village"))
		await create_timer(1.0).timeout
		_hide_modals()
		await _snap(str(case[0]))
		var card := sheet.find_child("Buy_reel_rod_pack", true, false) as Control
		_check(card != null, "[%s] cartão da vara" % case[0])
		if card != null:
			_check(card.find_child("Pack", true, false) == null, "[%s] vara sem ×N" % case[0])
			var icon := card.find_child("Icon", true, false) as TextureRect
			_check(icon != null and icon.texture != null, "[%s] ícone da vara" % case[0])
		var action := sheet.find_child("BuyItem", true, false) as Control
		if action == null:
			action = sheet.find_child("Locked_BuyItem", true, false) as Control
		_check(action != null and action.get_global_rect().end.y <= root.get_visible_rect().size.y, "[%s] botão de compra visível" % case[0])
		if action != null:
			_check(action.get_global_rect().size.y >= 43.5, "[%s] botão de compra com alvo >= 44" % case[0])
		_clipped(sheet)
		events.sheet_close_requested.emit()
		await create_timer(0.6).timeout

	# 2) Painel de arremesso com duas varas.
	await _fresh(two)
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	for i in 6:
		await process_frame
	await create_timer(1.0).timeout
	_hide_modals()
	_farm().call("recenter")
	await create_timer(0.5).timeout
	state.call("choose_bait", "bait_dough")
	state.get("progress").seen["fishing_tip:chest"] = true
	_farm().call("open_fishing")
	await _snap("d_painel_2_varas")
	_measure(_panel().find_child("Panel", true, false) as Control, "FishingPanel")
	_measure(_panel().find_child("Rod_reel_rod", true, false) as Control, "Rod_reel_rod", true)
	_measure(_panel().find_child("Bait_bait_dough", true, false) as Control, "Bait_bait_dough", true)
	_clipped(_panel())

	# 3) Minigame com baú (meio cheio): carpa conhecida, chance 100%.
	db.get("fishing").chest["chance"] = 1.0
	for species: String in db.get("fishing").fish:
		state.get("fishing").records[species] = {"best_cm": 40.0, "best_class": "medium", "count": 2, "gigantes": 0, "perfects": 0, "first_at": 1.0}
	state.call("choose_bait", "bait_dough")
	_panel().set("power_override", 0.5)
	_panel().call("press_cast")
	_panel().call("release_cast")
	await create_timer(0.9).timeout
	var cast: Dictionary = state.get("fishing").cast
	cast["at"] = float(state.call("now")) - float(cast.wait) - 0.05
	state.call("update_fishing")
	await create_timer(0.3).timeout
	_flow().call("handle_tap")
	await create_timer(0.8).timeout
	var game := main.find_child("FishingGame", true, false) as Control
	_check(game != null, "FishingGame aberto")
	var fish_id := str(state.get("fishing").cast.get("fish", ""))
	if game != null:
		game.set("_paused", true)
		var sim: FishingSim = game.get("sim")
		_check(sim.chest_enabled, "partida com baú")
		# segue o peixe, depois cobre o baú até a metade
		for i in 150:
			sim.bar_y = clampf(sim.fish_y - sim.bar_h / 2.0, 0.0, 1.0 - sim.bar_h)
			sim.bar_v = 0.0
			sim.step(false, 1.0 / 60.0)
		for i in 60:
			sim.bar_y = clampf(sim.chest_y - sim.bar_h / 2.0, 0.0, 1.0 - sim.bar_h)
			sim.bar_v = 0.0
			sim.step(false, 1.0 / 60.0)
		sim.meter = maxf(sim.meter, 0.55)
		_check(sim.chest_shown and sim.chest_meter > 0.3 and sim.chest_meter < 1.0, "baú meio cheio (%.2f)" % sim.chest_meter)
		var track: Rect2 = game.call("track_rect")
		var chest_screen := Vector2(track.get_center().x, track.end.y - sim.chest_y * track.size.y)
		_check(track.grow(2.0).has_point(chest_screen), "baú dentro da pista")
		await _snap("e_minigame_bau")
		_measure(game, "FishingGame", false, true)
		game.set("_paused", false)
	state.call("cancel_fishing")
	_flow().call("end")

	# 4) Resultado com "Baú!".
	var result: Node = _flow().get("result")
	var info := {"fish": fish_id if fish_id != "" else "fish_carp", "cm": 52.5, "class": "large", "previous_cm": 40.0, "first": false, "qty": 1, "xp": 12, "perfect": false,
		"chest": {"coins": 24, "items": {"bolt": 1}}}
	result.call("show_caught", info)
	await _snap("f_resultado_bau")
	_check(result.find_child("FishChest", true, false) != null, "'Baú!' no resultado")
	_check(result.find_child("FishChestChip_coins", true, false) != null and result.find_child("FishChestChip_bolt", true, false) != null, "chips do prêmio do baú")
	_measure(result.find_child("FishAgain", true, false) as Control, "FishAgain", true, false)
	_measure(result.find_child("FishLeave", true, false) as Control, "FishLeave", true, false)
	_clipped(result)
	result.call("close")

	# 5) Aventureiro pedindo o ensopado (e a ração de crescimento).
	await _fresh(two)
	state.call("dev_set_phase", "teething")
	state.get("growth").done = {}
	state.get("growth").phase_moments = {"brave": 4, "smart": 3}
	state.get("inventory").add("fish_stew", 1)
	state.call("_changed")
	main.find_child("Notice", true, false)
	(load("res://scripts/ui/growth_ui.gd") as Script).call("open")
	await create_timer(0.9).timeout
	_hide_modals()
	await _snap("g_aventureiro_ensopado")
	var step := sheet.find_child("GrowthReq_fish_meal", true, false) as Control
	_check(step != null, "passo do ensopado na grade do Aventureiro")
	if step != null:
		_check(step.get_global_rect().size.x >= 43.5 and step.get_global_rect().size.y >= 43.5, "passo do ensopado com alvo >= 44")
		_check(sheet.get_global_rect().encloses(step.get_global_rect().grow(-1.0)), "passo do ensopado dentro da folha")
	_clipped(sheet)

	print("FISHING ROD2 SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
