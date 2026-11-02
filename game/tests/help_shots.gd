extends SceneTree
## Capturas e MEDIDAS da tela "Como fazer" em "madeira ilustrada". NÃO é teste da suíte, mas imprime FAIL e sai com código 1
## se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/help_shots.gd -- --out=help
## PNGs em build/screenshots/<out>/help_<largura>x<altura>_<caso>.png. Não grava o save pessoal.

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/help/"
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


func _unlock() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	await create_timer(1.0).timeout
	_hide_modals()


func _give(id: String, amount: int) -> void:
	var inventory: Object = state.get("inventory")
	inventory.call("remove", id, int(inventory.call("count", id)))
	if amount > 0:
		inventory.call("add", id, amount)
	state.call("_changed")


func _close() -> void:
	root.get_node("Events").sheet_close_requested.emit()
	for i in 20:
		await process_frame


func _all_buttons() -> Array[Button]:
	var result: Array[Button] = []
	for node in sheet.find_children("*", "Button", true, false):
		var button := node as Button
		if button.is_visible_in_tree():
			result.append(button)
	return result


func _transforms() -> Dictionary:
	var result := {}
	for node in sheet.find_children("*", "Control", true, false):
		var control := node as Control
		if control.is_visible_in_tree():
			result[str(control.get_path())] = [control.scale, control.size]
	return result


func _open(kind: String, id: String, amount: int, shot_name: String, history: Array = []) -> void:
	var typed: Array[Dictionary] = []
	for entry in history:
		typed.append(entry)
	(load("res://scripts/ui/task_help.gd") as Script).call("open", kind, id, amount, typed)
	await create_timer(1.0).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "help_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	var before := _transforms()
	for i in 60:
		await process_frame
	var after := _transforms()
	for key: String in before:
		if after.has(key):
			_check(before[key][0] == after[key][0], "[%s] escala mudou em %s" % [shot_name, key])
			_check((before[key][1] as Vector2).is_equal_approx(after[key][1]), "[%s] tamanho mudou em %s" % [shot_name, key])
	_measure(shot_name, not history.is_empty())


func _label_ok(label: Label, tag: String, bounds: Rect2) -> void:
	if label == null:
		return
	_check(label.get_line_count() <= label.get_visible_line_count() or label.max_lines_visible <= 0, "[%s] texto cortado em %s: %s (caixa %s, texto %.1f, linhas %d/%d, fonte %d, altura de linha %d)" % [tag, label.name, label.text, label.size, label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x, label.get_line_count(), label.get_visible_line_count(), label.get_theme_font_size("font_size"), label.get_line_height()])
	_check(bounds.grow(0.6).encloses(label.get_global_rect()), "[%s] %s sai da caixa %s %s" % [tag, label.name, label.get_global_rect(), bounds])


func _measure(tag: String, with_back: bool) -> void:
	var screen := root.get_visible_rect().size
	var frame := sheet.find_child("HelpFrame", true, false) as Control
	if frame == null:
		_check(false, "[%s] sem HelpFrame" % tag)
		return
	var fr := frame.get_global_rect()
	_check(fr.position.x >= 0.0 and fr.end.x <= screen.x, "[%s] moldura fora da tela %s" % [tag, fr])
	_check(_near(fr.get_center().x, screen.x / 2.0, 1.0), "[%s] moldura não centralizada" % tag)
	_check(fr.position.y >= 127.5, "[%s] folha passa do HUD (topo %.1f)" % [tag, fr.position.y])
	_check(fr.end.y <= screen.y + 0.5, "[%s] folha passa da base da tela (%.1f > %.1f)" % [tag, fr.end.y, screen.y])
	var title := sheet.find_child("HelpTitle", true, false) as Label
	_check(_near(title.get_global_rect().get_center().x, fr.get_center().x, 1.0), "[%s] título fora do centro" % tag)
	var close := sheet.find_child("CloseButton", true, false) as Control
	_check(close != null and close.size.x >= 43.5 and close.size.y >= 43.5, "[%s] X menor que 44" % tag)
	var back := sheet.find_child("HelpBack", true, false) as Control
	_check((back != null) == with_back, "[%s] botão voltar %s" % [tag, "ausente" if with_back else "inesperado"])
	if back:
		_check(back.size.x >= 43.5 and back.size.y >= 43.5, "[%s] voltar menor que 44" % tag)
		_check(back.get_global_rect().end.x <= title.get_global_rect().position.x + 1.0, "[%s] voltar encosta no título" % tag)
	# Cartão do topo.
	var card := sheet.find_child("HelpCard", true, false) as Control
	var card_rect := card.get_global_rect()
	_check(_near(card.size.y, float(frame.get_meta("est_card_h")), 1.0), "[%s] cartão %.1f != previsto %.1f" % [tag, card.size.y, float(frame.get_meta("est_card_h"))])
	var hero := card.find_child("HelpHero", true, false) as Control
	_check(card_rect.grow(0.5).encloses(hero.get_global_rect()), "[%s] pratinho fora do cartão" % tag)
	_check(_near(hero.get_global_rect().get_center().y, card_rect.get_center().y, 1.0), "[%s] pratinho fora do centro vertical do cartão" % tag)
	for name_ in ["HelpName", "HelpDetail"]:
		_label_ok(card.find_child(name_, true, false) as Label, tag, card_rect)
	var pill := card.find_child("HelpPill", true, false) as Control
	if pill:
		_check(card_rect.grow(0.5).encloses(pill.get_global_rect()), "[%s] pílula fora do cartão" % tag)
		_check(_near(pill.size.y, 28.0, 0.1), "[%s] pílula de altura %.1f" % [tag, pill.size.y])
		_label_ok(pill.find_child("PillText", true, false) as Label, tag, pill.get_global_rect())
	_check_icon(hero.find_child("Icon", true, false) as TextureRect, hero, tag)
	# Botões: alvo, verdes.
	var greens := 0
	for button in _all_buttons():
		_check(button.size.x >= 43.5 and button.size.y >= 43.5, "[%s] alvo menor que 44 em %s %s" % [tag, button.name, button.size])
		if bool(button.get_meta("wood_primary", false)):
			greens += 1
	_check(greens <= 1, "[%s] %d botões verdes" % [tag, greens])
	# Painéis.
	var panels: Array[Control] = []
	for node in sheet.find_children("HelpSection_*", "Control", true, false):
		panels.append(node as Control)
	_check(not panels.is_empty(), "[%s] sem painéis" % tag)
	var previous_end := card_rect.end.y
	var button_right := -1.0
	var plate_left := -1.0
	var rows_total := 0
	var scroll := sheet.find_child("HelpScroll", true, false) as ScrollContainer
	var scroll_rect := scroll.get_global_rect()
	var bar := scroll.get_v_scroll_bar()
	var scrolls := bar.max_value - bar.page > 1.0
	_check(fr.grow(0.5).encloses(scroll_rect), "[%s] área de rolagem fora da moldura" % tag)
	_check(fr.end.y - scroll_rect.end.y >= 45.5, "[%s] área invade a base da moldura (%.1f)" % [tag, fr.end.y - scroll_rect.end.y])
	_check(scroll_rect.position.y >= card_rect.end.y + 7.5, "[%s] área encosta no cartão" % tag)
	var first_panel := true
	var last_end := 0.0
	for p in panels:
		var pr := p.get_global_rect()
		_check(_near(pr.position.x, card_rect.position.x, 0.6) and _near(pr.size.x, card_rect.size.x, 0.6), "[%s] %s não tem a largura do cartão" % [tag, p.name])
		if not first_panel:
			_check(_near(pr.position.y - previous_end, 8.0, 0.6), "[%s] espaço antes de %s = %.1f" % [tag, p.name, pr.position.y - previous_end])
		else:
			_check(scroll_rect.grow(1.0).encloses(Rect2(pr.position, Vector2(pr.size.x, 60.0))), "[%s] topo do primeiro painel fora da área" % tag)
		first_panel = false
		previous_end = pr.end.y
		last_end = pr.end.y
		var head := p.find_child("PanelTitle", true, false) as Label
		_check(_near(head.get_global_rect().get_center().x, pr.get_center().x, 1.0), "[%s] título do painel descentralizado" % tag)
		if not scrolls:
			_check(fr.grow(0.5).encloses(pr), "[%s] %s fora da moldura" % [tag, p.name])
		for node in p.find_children("HelpRow_*", "Control", true, false):
			var row := node as Control
			var rr := row.get_global_rect()
			rows_total += 1
			if not scrolls:
				_check(scroll_rect.grow(1.0).encloses(rr), "[%s] %s fora da área" % [tag, row.name])
			var row_plate := row.find_child("RowPlate", true, false) as Control
			_check(_near(row_plate.size.x, row_plate.size.y, 0.01), "[%s] pratinho torto" % tag)
			var center_y := _head_center(row, rr)
			_check(_near(row_plate.get_global_rect().get_center().y, center_y, 1.0), "[%s] pratinho fora do centro vertical em %s (%.1f x %.1f, linha %s)" % [tag, row.name, row_plate.get_global_rect().get_center().y, center_y, rr])
			if plate_left < 0.0:
				plate_left = row_plate.get_global_rect().position.x
			_check(_near(row_plate.get_global_rect().position.x, plate_left, 0.6), "[%s] pratinhos desalinhados em %s" % [tag, row.name])
			_check_icon(row_plate.find_child("Icon", true, false) as TextureRect, row_plate, tag)
			for label_name in ["RowName", "RowText", "ItemSource"]:
				_label_ok(row.find_child(label_name, true, false) as Label, tag, rr)
			var row_pill := row.find_child("RowPill", true, false) as Control
			if row_pill:
				_label_ok(row_pill.find_child("PillText", true, false) as Label, tag, row_pill.get_global_rect())
				_check(rr.grow(0.5).encloses(row_pill.get_global_rect()), "[%s] pílula fora da linha %s" % [tag, row.name])
			var trailing: Control = null
			for node2 in row.find_children("*", "Button", true, false):
				trailing = node2 as Control
			if trailing == null:
				trailing = row.find_child("HelpDone", true, false) as Control
			if trailing:
				var tr := trailing.get_global_rect()
				_check(_near(tr.get_center().y, center_y, 1.0), "[%s] botão fora do centro vertical em %s" % [tag, row.name])
				_check(rr.grow(0.5).encloses(tr), "[%s] botão fora da linha %s" % [tag, row.name])
				if trailing is Button:
					if button_right < 0.0:
						button_right = tr.end.x
					_check(_near(tr.end.x, button_right, 0.6), "[%s] botões desalinhados em %s" % [tag, row.name])
					_check(_near(tr.size.x, 72.0, 0.1) and _near(tr.size.y, 44.0, 0.1), "[%s] botão com tamanho %s" % [tag, tr.size])
	if not scrolls:
		_check(scroll_rect.end.y - last_end <= 16.0, "[%s] vazio embaixo da última linha: %.1f px" % [tag, scroll_rect.end.y - last_end])
	print("[%s] %dx%d moldura %s cartão %.0f painéis %d linhas %d" % [tag, screen.x, screen.y, fr, card.size.y, panels.size(), rows_total])


func _check_icon(icon: TextureRect, plate: Control, tag: String) -> void:
	if icon == null:
		return
	var pr := plate.get_global_rect()
	_check(_near(icon.get_global_rect().get_center().x, pr.get_center().x, 0.6) and _near(icon.get_global_rect().get_center().y, pr.get_center().y, 0.6), "[%s] ícone fora do centro do pratinho" % tag)
	if icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST:
		var ratio := minf(icon.size.x / icon.texture.get_width(), icon.size.y / icon.texture.get_height())
		_check(_near(ratio, roundf(ratio), 0.001) and ratio >= 0.99, "[%s] ícone pixel com escala não inteira (%.3f)" % [tag, ratio])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "help_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	var db: Node = root.get_node("Database")

	# a) Suco de morango: receita com ingrediente faltando (0/2).
	await _unlock()
	_give("strawberry", 0)
	_give("strawberry_juice", 0)
	await _open("item", "strawberry_juice", 2, "a_suco")
	await _close()

	# b) Parafuso no começo: fonte de missão + "Primeiro:" + Madeira.
	state.call("reset")
	state.get("progress").seen["intro"] = true
	await create_timer(0.5).timeout
	_hide_modals()
	await _open("item", "bolt", 1, "b_parafuso")
	await _close()

	# c) Ingrediente com history (botão voltar).
	await _unlock()
	_give("strawberry", 0)
	await _open("item", "strawberry", 6, "c_historico", [{"kind": "item", "id": "strawberry_juice", "amount": 2}])
	await _close()

	# d) Já tem.
	await _unlock()
	_give("carrot_snack", 2)
	await _open("item", "carrot_snack", 1, "d_ja_tem")
	await _close()

	# e) Comida de crescimento: preparo + ingredientes por preparo.
	await _unlock()
	state.call("dev_set_phase", "teething")
	state.get("progress").owned["stove"] = true
	state.get("progress").claimed_quests["growth_1_puppy"] = true
	state.call("_changed")
	await create_timer(0.5).timeout
	_hide_modals()
	await _open("growth_req", "meals", 1, "e_comida_crescimento")
	await _close()

	# f) Cuidados de crescimento.
	await _unlock()
	state.call("dev_set_phase", "newborn")
	state.get("growth").phase_moments = {"body": 2, "brave": 0}
	state.get("growth").done = {}
	state.call("_changed")
	await create_timer(0.5).timeout
	_hide_modals()
	await _open("growth_req", "pillars", 1, "f_cuidados")
	await _close()

	# g) Muitos ingredientes (rolagem): enche a receita com insumos extras só para o teste.
	await _unlock()
	var recipes: Dictionary = db.get("recipes")
	var old_inputs: Dictionary = (recipes["carrot_snack"]["inputs"] as Dictionary).duplicate()
	recipes["carrot_snack"]["inputs"] = {"carrot": 2, "egg": 1, "milk": 1, "wheat": 2, "strawberry": 3, "potato": 2, "pumpkin": 1}
	for item: String in ["carrot", "egg", "milk", "wheat", "strawberry", "potato", "pumpkin", "carrot_snack"]:
		_give(item, 0)
	await _open("item", "carrot_snack", 4, "g_muitos")
	recipes["carrot_snack"]["inputs"] = old_inputs
	await _close()

	print("HELP SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)


## Centro vertical onde pratinho e botão devem ficar: o da linha, ou o da cabeça (nome + pílula) se o texto longo desce.
func _head_center(row: Control, rr: Rect2) -> float:
	var text := row.find_child("RowText", true, false) as Label
	if text == null or text.get_global_rect().position.x > rr.position.x + 52.0:
		return rr.get_center().y
	var head := 44.0
	var name_label := row.find_child("RowName", true, false) as Control
	var pill := row.find_child("RowPill", true, false) as Control
	var top := name_label.get_global_rect().position.y
	var bottom := name_label.get_global_rect().end.y
	if pill:
		bottom = pill.get_global_rect().end.y
	head = maxf(head, bottom - top)
	return rr.position.y + 7.0 + head / 2.0
