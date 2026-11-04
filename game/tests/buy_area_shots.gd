extends SceneTree
## Capturas da compra de terreno/área em madeira ilustrada e da pílula do mundo (topo esquerdo). NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/buy_area_shots.gd -- --out=buy_area
## PNGs em build/screenshots/<out>/buy_<largura>x<altura>_<tela>.png. Não grava o save pessoal.
## Imprime FAIL se algo sai da tela/sob o HUD, alvo < 44, texto cortado, pílula sobre o avatar ou PNG com razão torta.

var state: Node
var main: Node
var folder := "res://../build/screenshots/buy_area/"
var failures := 0
const SHEET_TOP := 128.0  # Hud.SHEET_TOP (em teste -s o Hud depende de autoload)
const SIDE := 12.0  # Hud.SIDE
const FONT := "res://assets/fonts/font_wood.tres"


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(400).timeout.connect(func() -> void: quit(1))


func _fail(message: String) -> void:
	failures += 1
	print("  FAIL: ", message)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_fail(message)


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "buy_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


## Controles comuns: dentro da tela, alvos de 44, texto sem corte, imagens sem distorção.
func _audit(host: Control, shot_name: String) -> void:
	var screen := root.get_visible_rect().size
	for node: Node in host.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0:
			continue
		var rect := control.get_global_rect()
		# A moldura de madeira (Frame/WoodArt) sangra para fora da folha de propósito; o recorte é da folha.
		if (rect.end.x > screen.x + 0.5 or rect.position.x < -0.5) and not (String(control.name).begins_with("Frame") or String(control.name).begins_with("WoodArt")):
			_fail("%s: %s sai dos lados da tela (%s)" % [shot_name, control.name, rect])
		if control is BaseButton and (control.size.x < 43.5 or control.size.y < 43.5):
			_fail("%s: alvo %s menor que 44 px (%s)" % [shot_name, control.name, control.size])
		if control is Label:
			var label := control as Label
			if label.get_minimum_size().y > label.size.y + 1.0 and label.clip_text:
				_fail("%s: texto cortado em %s ('%s')" % [shot_name, label.name, label.text])
			if label.text != "" and label.get_minimum_size().x > label.size.x + 1.0 and label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.size.x > 0.0 and label.clip_text:
				_fail("%s: texto estreito em %s" % [shot_name, label.name])
		if control is TextureRect:
			var picture := control as TextureRect
			if picture.texture != null and picture.stretch_mode == TextureRect.STRETCH_SCALE:
				var natural := picture.texture.get_size()
				var drawn := rect.size
				if absf((drawn.x / drawn.y) / (natural.x / natural.y) - 1.0) > 0.01:
					_fail("%s: %s desenhada com razão diferente da fonte (%s vs %s)" % [shot_name, picture.name, drawn, natural])
		if control is NinePatchRect:
			var patch := control as NinePatchRect
			if patch.texture != null and patch.scale.x > 0.0 and absf(patch.scale.x - patch.scale.y) > 0.001:
				_fail("%s: NinePatch %s com escala torta" % [shot_name, patch.name])


func _audit_sheet(shot_name: String) -> void:
	var sheet := main.get_node("Sheet") as Control
	var panel := sheet.get_node("%Panel") as Control
	var rect := panel.get_global_rect()
	var screen := root.get_visible_rect().size
	print("[%s] folha %s (tela %s)" % [shot_name, rect, screen])
	_check(rect.position.x <= 0.5 and rect.end.x >= screen.x - 0.5, shot_name + ": folha não ocupa a largura")
	_check(rect.end.y <= screen.y + 1.0, shot_name + ": folha passa da base")
	_check(rect.position.y >= SHEET_TOP - 1.0, shot_name + ": folha sob o HUD (%s)" % rect.position.y)
	var holder := sheet.get_node("%ContentHolder") as Control
	var scroll := holder.get_parent() as Control
	_check(holder.get_combined_minimum_size().x <= scroll.size.x + 1.0, shot_name + ": conteúdo mais largo que a folha")
	_audit(panel, shot_name)
	# Os textos de madeira usam a fonte da madeira e a cor marrom (nada de tema liso).
	for label: Node in sheet.find_children("UpgradeName", "Label", true, false):
		_check((label as Label).get_theme_font("font") == load(FONT), shot_name + ": nome fora da fonte da madeira")


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _close_sheet() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await create_timer(0.3).timeout


func _open_sheet(title: String, content: Control, shot_name: String) -> void:
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	await _save(shot_name)
	_audit_sheet(shot_name)
	await _close_sheet()


func _enter(world_id: String) -> void:
	main.call("_on_world_requested", world_id, "")
	main.call("show_screen", &"map")
	for i in 6:
		await process_frame
	await create_timer(0.8).timeout
	_hide_modals()


func _pill_audit(shot_name: String) -> void:
	var worlds: Control = main.find_child("MapButton", true, false)
	var pill := worlds as Button
	var screen := root.get_visible_rect().size
	var rect := pill.get_global_rect()
	print("[%s] pílula %s texto '%s'" % [shot_name, rect, pill.text])
	_check(rect.size.y >= 44.0, shot_name + ": pílula menor que 44 de alto")
	_check(rect.position.x >= 0.0 and rect.end.x <= screen.x * 0.6, shot_name + ": pílula fora do canto ou larga demais")
	_check(rect.position.y >= 60.0, shot_name + ": pílula sob o HUD (linha 1)")
	_check(absf(rect.position.x - SIDE) <= 0.5, shot_name + ": margem esquerda diferente do HUD (%s)" % rect.position.x)
	var hud: Control = main.find_child("TopBar", true, false)
	for part: String in ["AvatarGroup", "HudProfile", "CoinsColumn"]:
		var other := hud.find_child(part, true, false) as Control
		if other != null and other.is_visible_in_tree() and other.get_global_rect().size.x > 0.0:
			var overlap := rect.intersection(other.get_global_rect())
			if overlap.size.x > 1.0 and overlap.size.y > 1.0:
				_fail("%s: pílula sobrepõe %s (%s)" % [shot_name, part, overlap])
	# A madeira cobre o botão inteiro e a arte é desenhada na razão da fonte (escala 1/3 uniforme).
	var art := pill.find_child("PillArt", true, false) as NinePatchRect
	_check(art != null and art.texture != null and is_equal_approx(art.scale.x, art.scale.y) and art.size.is_equal_approx(rect.size * 3.0), shot_name + ": pele da pílula não acompanha o botão")
	_check(pill.get_theme_font("font") == load(FONT), shot_name + ": nome fora da fonte da madeira")
	_check(pill.get_theme_color("font_color") == Palette.WOOD_INK, shot_name + ": nome fora do marrom da madeira")
	# Pílula e NextStep (linha 2) não se cobrem.
	var step := hud.find_child("NextStep", true, false) as Control
	if step != null and step.is_visible_in_tree() and step.get_global_rect().size.x > 0.0:
		var cover := rect.intersection(step.get_global_rect())
		if cover.size.x > 1.0 and cover.size.y > 1.0:
			_fail("%s: pílula cobre o próximo passo (%s)" % [shot_name, cover])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "buy_area_shots_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	var progression_ui: Script = load("res://scripts/ui/progression_ui.gd")

	# Terreno: com moedas, sem moedas, fora de ordem e já comprado.
	state.call("dev_unlock_everything")
	state.get("progress").owned.erase("greenhouse")
	state.set("unlocked_plots", 4)
	state.set("coins", 500)
	await create_timer(0.5).timeout
	_hide_modals()
	var next_plot: int = int(state.get("unlocked_plots"))
	await _open_sheet("Terreno %d" % (next_plot + 1), progression_ui.call("plot_purchase", next_plot), "a_terreno_com_moedas")
	state.set("coins", 12)
	await create_timer(0.3).timeout
	await _open_sheet("Terreno %d" % (next_plot + 1), progression_ui.call("plot_purchase", next_plot), "b_terreno_sem_moedas")
	await _open_sheet("Terreno %d" % (next_plot + 2), progression_ui.call("plot_purchase", next_plot + 1), "c_terreno_fora_de_ordem")

	# Região cercada de 850 (estufa) com e sem moedas.
	state.set("coins", 2000)
	await create_timer(0.3).timeout
	await _open_sheet("Estufa", progression_ui.call("purchase", "greenhouse"), "d_regiao_estufa")
	state.set("coins", 100)
	await create_timer(0.3).timeout
	await _open_sheet("Estufa", progression_ui.call("purchase", "greenhouse"), "e_regiao_estufa_sem_moedas")

	# O toque real no balão do próximo canteiro e na região abre as mesmas folhas.
	state.set("coins", 500)
	await _enter("farm")
	await _save("f_sitio_pilula")
	_pill_audit("f_sitio_pilula")
	var room: Control = main.find_child("World_farm", true, false)
	var locked_index := next_plot
	room.call("_on_plot_tapped", locked_index) if room.has_method("_on_plot_tapped") else null
	await create_timer(0.6).timeout
	var sheet := main.get_node("Sheet") as Control
	if sheet.has_method("is_open") and sheet.call("is_open"):
		_check(sheet.find_child("BuyPlot", true, false) != null, "tocar o canteiro fechado abre a compra em madeira")
		await _save("g_toque_no_canteiro")
		_audit_sheet("g_toque_no_canteiro")
		await _close_sheet()

	# Pílula em outros mundos (nome longo).
	for id: String in ["nature", "village", "house", "park"]:
		await _enter(id)
		await _save("pilula_" + id)
		_pill_audit("pilula_" + id)

	print("BUY AREA SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
