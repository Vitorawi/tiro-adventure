extends SceneTree
## Capturas do Lote 4 da revisão em madeira ilustrada: Configurações, "Novo!", passo concluído, cartões de presentes e
## achados na Mochila, nível do cliente, treino de truque, esconde-esconde, introdução e aviso. NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/misc_wood_shots.gd -- --out=misc_wood
## PNGs em build/screenshots/<out>/misc_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Imprime FAIL se algo sai da tela/sob o HUD, alvo < 44, texto cortado, NinePatch torto ou mais de um botão verde.

var state: Node
var main: Node
var folder := "res://../build/screenshots/misc_wood/"
var failures := 0
const SHEET_TOP := 128.0  # Hud.SHEET_TOP


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _fail(message: String) -> void:
	failures += 1
	print("  FAIL: ", message)


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "misc_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


## Medidas gerais de `area` (a moldura/folha): dentro da tela, fora do HUD (se `below_hud`), alvos >= 44, texto, NinePatch, verdes.
func _audit(shot_name: String, area: Control, below_hud := true, max_green := 1) -> void:
	var screen := root.get_visible_rect().size
	var rect := area.get_global_rect()
	print("[%s] %s" % [shot_name, rect])
	if rect.position.x < -0.5 or rect.end.x > screen.x + 0.5: _fail(shot_name + ": sai dos lados")
	if below_hud and rect.position.y < SHEET_TOP - 1.0: _fail(shot_name + ": sob o HUD")
	if rect.end.y > screen.y + 1.0: _fail(shot_name + ": passa da base")
	var greens := 0
	for node: Node in area.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0: continue
		var r := control.get_global_rect()
		var clipped := false
		var parent := control.get_parent()
		while parent != null and parent != area:
			if parent is ScrollContainer and not (parent as Control).get_global_rect().grow(1.0).encloses(r):
				clipped = true
			parent = parent.get_parent()
		if clipped: continue
		if control is BaseButton:
			if control.size.x < 43.5 or control.size.y < 43.5:
				if not (control is TextureButton):
					_fail("%s: alvo %s pequeno (%s)" % [shot_name, control.name, control.size])
			if control.has_meta("wood_primary"): greens += 1
		if control is Label and (control as Label).clip_text and control.get_minimum_size().y > control.size.y + 1.0:
			_fail("%s: texto cortado em %s" % [shot_name, control.name])
		if control is NinePatchRect and absf(control.scale.x - control.scale.y) > 0.001:
			_fail("%s: NinePatch %s torto" % [shot_name, control.name])
	if greens > max_green: _fail("%s: %d botões verdes" % [shot_name, greens])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _sheet(title: String, content: Control, shot_name: String) -> void:
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	await create_timer(0.7).timeout
	await _save(shot_name)
	_audit(shot_name, main.get_node("Sheet").get_node("%Panel") as Control)
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.4).timeout


func _celebration(shot_name: String, call_name: String, args: Array) -> void:
	var layer: CanvasLayer = main.get("_celebration")
	layer.callv(call_name, args)
	await create_timer(0.8).timeout
	await _save(shot_name)
	var sheet := layer.find_child("RewardPanel", true, false) as Control
	if sheet == null:
		_fail(shot_name + ": sem RewardPanel")
	else:
		_audit(shot_name, sheet)
	layer.hide()
	await create_timer(0.3).timeout


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "misc_wood_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	state.call("dev_unlock_everything")
	await create_timer(0.5).timeout
	_hide_modals()
	# Configurações (um segundo save para mostrar as duas variações de linha).
	var settings: GDScript = load("res://scripts/ui/settings_panel.gd")
	await _sheet("Configurações", settings.call("panel"), "a_config")
	# "Novo!" (destino curto e destino que não cabe).
	await _celebration("b_novo", "show_unlocks", [["place:farm/orchard"] as Array[String]])
	await _celebration("b2_novo_praca", "show_unlocks", [["npc:nina"] as Array[String]])
	# Passo concluído.
	var reward: CanvasLayer = main.get("_quest_reward")
	var ids: Array = state.get("progress").claimed_quests.keys() if state.get("progress").get("claimed_quests") is Dictionary else []
	var first := "lais_bed" if root.get_node("Database").get("quests").has("lais_bed") else str(root.get_node("Database").get("quests").keys()[0])
	var second := "lais_feed" if root.get_node("Database").get("quests").has("lais_feed") else first
	print("passo: ", first, " -> ", second, " (", ids.size(), ")")
	reward.call("open", first, second)
	await create_timer(0.8).timeout
	await _save("c_passo")
	var panel := reward.find_child("RewardPanel", true, false) as Control
	if panel == null: _fail("c_passo: sem RewardPanel")
	else: _audit("c_passo", panel)
	reward.hide()
	await create_timer(0.3).timeout
	# Presentes para guardar + achados (geladeira cheia: bloqueado).
	state.set("unlimited_storage", false)
	var owned: Dictionary = state.get("progress").owned
	owned["fridge"] = true
	for id: String in ["fridge_2", "fridge_3", "fridge_4", "fridge_5"]:
		owned.erase(id)
	state.get("economy").storage_floor.clear()
	state.get("inventory").add("egg", 24)
	state.call("_grant_automatic", "customer:lais:1", {"coins": 20, "items": {"carrot_snack": 1}})
	state.call("_grant_automatic", "customer:lais:2", {"coins": 25, "items": {"carrot_snack": 2}})
	main.call("show_screen", &"bag")
	await create_timer(0.8).timeout
	await _save("d_presentes")
	var gifts := main.find_child("PendingGifts", true, false) as Control
	if gifts == null: _fail("d_presentes: sem cartão")
	else: _audit("d_presentes", gifts, false, 1)
	var toggle := main.find_child("GiftsToggle", true, false) as Button
	if toggle != null:
		toggle.pressed.emit()
		await create_timer(0.6).timeout
		await _save("d2_presentes_abertos")
	main.call("show_screen", &"pet")
	await create_timer(0.3).timeout
	# Nível do cliente.
	await _sheet("Laís", load("res://scripts/ui/market_ui.gd").call("customer_info", "lais"), "e_cliente")
	# Treino de truque e esconde-esconde.
	var training: Control = load("res://scenes/ui/trick_training/trick_training.tscn").instantiate()
	await _sheet("Treino", training, "f_truque")
	var hide_game: Control = load("res://scripts/ui/hide_seek_ui.gd").new()
	await _sheet("Esconde-esconde", hide_game, "g_esconde")
	# Aviso (pílula de madeira embaixo).
	root.get_node("Events").emit_signal("toast_requested", "Missão concluída: pegue o prêmio!")
	await create_timer(0.7).timeout
	await _save("h_aviso")
	# Introdução.
	var intro: CanvasLayer = load("res://scenes/ui/intro/intro.gd").new()
	root.add_child(intro)
	await create_timer(1.0).timeout
	intro.call("_advance")
	await create_timer(0.6).timeout
	await _save("i_intro")
	var card := intro.find_child("IntroCard", true, false) as Control
	if card == null: _fail("i_intro: sem cartão")
	else: _audit("i_intro", card, false, 1)
	print("misc_wood_shots: %d falha(s)" % failures)
	quit(0 if failures == 0 else 1)
