extends SceneTree
## Capturas e MEDIDAS do detalhe de item "madeira ilustrada" (Mochila). NÃO é teste da suíte, mas imprime FAIL e sai com
## código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/item_shots.gd -- --out=item
## PNGs em build/screenshots/<out>/item_<largura>x<altura>_<caso>.png. Não grava o save pessoal.

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/item/"
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


func _text_fits(label: Label, name_: String, tag: String) -> void:
	if label == null:
		return
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var rect := label.get_global_rect()
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF and not label.clip_text:
		var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_check(width <= rect.size.x + 0.5, "[%s] %s passa da sua caixa (%.1f > %.1f): %s" % [tag, name_, width, rect.size.x, label.text])


func _transforms() -> Dictionary:
	var result := {}
	for node in sheet.find_children("*", "Control", true, false):
		var control := node as Control
		if control.is_visible_in_tree():
			result[str(control.get_path())] = [control.scale, control.size, control.get_global_rect().position]
	return result


func _open(id: String, shot_name: String) -> void:
	root.get_node("Events").sheet_requested.emit(str(root.get_node("Database").call("item_name", id)), (load("res://scripts/ui/sheet_builder.gd") as Script).call("item_detail", id))
	await create_timer(1.0).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "item_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	var before := _transforms()
	for i in 60:
		await process_frame
	var after := _transforms()
	for key: String in before:
		if after.has(key):
			_check(before[key][0] == after[key][0], "[%s] escala mudou em %s" % [shot_name, key])
			_check((before[key][1] as Vector2).is_equal_approx(after[key][1]), "[%s] tamanho mudou em %s" % [shot_name, key])
	_measure(id, shot_name)


func _measure(id: String, tag: String) -> void:
	var screen := root.get_visible_rect().size
	var frame := sheet.find_child("ItemFrame", true, false) as Control
	if frame == null:
		_check(false, "[%s] sem ItemFrame" % tag)
		return
	var fr := frame.get_global_rect()
	_check(fr.position.x >= 0.0 and fr.end.x <= screen.x, "[%s] moldura fora da tela %s" % [tag, fr])
	_check(_near(fr.get_center().x, screen.x / 2.0, 1.0), "[%s] moldura não centralizada" % tag)
	_check(fr.position.y >= 127.5, "[%s] folha passa do HUD (topo %.1f)" % [tag, fr.position.y])
	_check(fr.end.y <= screen.y + 0.5, "[%s] folha passa da base da tela (%.1f > %.1f)" % [tag, fr.end.y, screen.y])
	# Placa: título centrado e dentro do espaço entre os parafusos.
	var title := sheet.find_child("ItemTitle", true, false) as Label
	var rect := title.get_global_rect()
	_check(_near(rect.get_center().x, fr.get_center().x, 1.0), "[%s] título fora do centro da placa" % tag)
	var font := title.get_theme_font("font")
	var width := font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
	_check(width <= rect.size.x + 0.5 or title.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS and title.get_theme_font_size("font_size") <= 14, "[%s] texto do título sai da placa (%.1f > %.1f)" % [tag, width, rect.size.x])
	_check(rect.position.x >= fr.position.x + 84.0 and rect.end.x <= fr.end.x - 84.0, "[%s] título passa da placa %s" % [tag, rect])
	# Cartão: altura igual à prevista (a moldura e os painéis dependem dela).
	var card := sheet.find_child("ItemCard", true, false) as Control
	_check(_near(card.size.y, float(frame.get_meta("est_card_h")), 1.0), "[%s] cartão %.1f != previsto %.1f" % [tag, card.size.y, float(frame.get_meta("est_card_h"))])
	_check(_near(card.get_global_rect().get_center().x, fr.get_center().x + 1.25, 1.5), "[%s] cartão fora do centro da moldura" % tag)
	var card_rect := card.get_global_rect()
	var body := card.find_child("Body", true, false) as Control
	for child in body.get_children():
		var c := child as Control
		_check(card_rect.grow(0.5).encloses(c.get_global_rect()), "[%s] %s fora do cartão" % [tag, c.name])
	var hero := sheet.find_child("ItemHero", true, false) as Control
	var plate_rect := hero.get_global_rect()
	_check(_near(hero.size.x, hero.size.y, 0.01), "[%s] pratinho do ícone não é quadrado" % tag)
	var icon := hero.find_child("Icon", true, false) as TextureRect
	if icon:
		_check(_near(icon.get_global_rect().get_center().x, plate_rect.get_center().x, 0.6) and _near(icon.get_global_rect().get_center().y, plate_rect.get_center().y, 0.6), "[%s] ícone fora do centro do pratinho" % tag)
		var sw := float(icon.texture.get_width())
		var ratio := minf(icon.size.x / sw, icon.size.y / float(icon.texture.get_height()))
		if icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST:
			_check(_near(ratio, roundf(ratio), 0.001), "[%s] ícone pixel com escala não inteira (%.3f)" % [tag, ratio])
	var pill := sheet.find_child("QuantityPill", true, false) as Control
	_check(_near(pill.size.y, 29.0, 0.1), "[%s] pílula de altura %.1f" % [tag, pill.size.y])
	_check(_near(pill.get_global_rect().position.y, hero.get_global_rect().get_center().y - pill.size.y / 2.0, 80.0), "[%s] pílula fora da linha do ícone" % tag)
	var note := sheet.find_child("ItemNote", true, false) as Label
	if note:
		_check(note.get_visible_line_count() <= 3, "[%s] linha de uso com mais de 3 linhas" % tag)
	_text_fits(pill.find_child("QuantityText", true, false) as Label, "QuantityText", tag)
	# Ações: mesmo tamanho, juntas e centradas no cartão, alvo >= 44.
	var row := sheet.find_child("ItemActions", true, false) as Control
	if row:
		var buttons: Array[Control] = []
		for child in row.get_children():
			buttons.append(child as Control)
		var first := buttons[0]
		var left := 99999.0
		var right := -99999.0
		for b in buttons:
			_check(_near(b.size.x, first.size.x, 0.5) and _near(b.size.y, first.size.y, 0.5), "[%s] botões de ação de tamanhos diferentes (%s %s)" % [tag, b.name, b.size])
			_check(b.size.x >= 43.5 and b.size.y >= 43.5, "[%s] alvo de toque menor que 44 em %s" % [tag, b.name])
			_check(_near(b.get_global_rect().position.y, first.get_global_rect().position.y, 0.5), "[%s] botões desalinhados na vertical" % tag)
			_check(card_rect.grow(0.5).encloses(b.get_global_rect()), "[%s] botão %s fora do cartão" % [tag, b.name])
			var label := b.find_child("Caption", true, false) as Label
			if label:
				var lw := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
				_check(lw <= b.size.x - 12.0, "[%s] texto do botão %s não cabe (%.1f > %.1f)" % [tag, b.name, lw, b.size.x])
			left = minf(left, b.get_global_rect().position.x)
			right = maxf(right, b.get_global_rect().end.x)
		_check(_near((left + right) / 2.0, card_rect.get_center().x, 1.0), "[%s] fileira de ações descentralizada (%.1f x %.1f)" % [tag, (left + right) / 2.0, card_rect.get_center().x])
	# Painéis: mesma largura e altura, mesmo topo, dentro da moldura; itens da primeira linha visíveis; ícones nítidos.
	var sources := sheet.find_child("ItemSources", true, false) as Control
	var uses := sheet.find_child("ItemUses", true, false) as Control
	var fills: Array = []
	var panels: Array[Control] = []
	for p in [sources, uses]:
		if p != null:
			panels.append(p)
	for p in panels:
		var pr := p.get_global_rect()
		_check(fr.grow(0.5).encloses(pr), "[%s] %s fora da moldura" % [tag, p.name])
		_check(pr.position.y >= card_rect.end.y + 7.5, "[%s] %s encosta no cartão" % [tag, p.name])
		_check(_near(pr.size.x, panels[0].size.x, 0.5) and _near(pr.size.y, panels[0].size.y, 0.5), "[%s] painéis de tamanhos diferentes %s %s" % [tag, panels[0].size, p.size])
		_check(_near(pr.position.y, panels[0].get_global_rect().position.y, 0.5), "[%s] painéis em alturas diferentes" % tag)
		_check(fr.end.y - pr.end.y >= 45.5, "[%s] painel invade a base da moldura (%.1f)" % [tag, fr.end.y - pr.end.y])
		var head := p.find_child("PanelTitle", true, false) as Label
		_check(_near(head.get_global_rect().get_center().x, pr.get_center().x, 1.0), "[%s] título do painel descentralizado" % tag)
		var scroll := p.find_child("*Scroll", true, false) as ScrollContainer
		var scroll_rect := scroll.get_global_rect()
		_check(pr.grow(0.5).encloses(scroll_rect), "[%s] rolagem fora do painel %s" % [tag, p.name])
		var cells: Array[Button] = []
		for node in p.find_children("*", "Button", true, false):
			cells.append(node as Button)
		_check(not cells.is_empty(), "[%s] painel %s sem itens" % [tag, p.name])
		var first_y := -1.0
		var first_cell: Button = null
		for cell in cells:
			var r := cell.get_global_rect()
			if first_cell == null:
				first_cell = cell
				first_y = r.position.y
			_check(_near(cell.size.x, first_cell.size.x, 0.5) and _near(cell.size.y, first_cell.size.y, 0.5), "[%s] células de tamanho diferente em %s" % [tag, p.name])
			_check(cell.size.x >= 43.5 and cell.size.y >= 43.5, "[%s] alvo da célula %s menor que 44" % [tag, cell.name])
			var plate := cell.find_child("Plate", true, false) as Control
			_check(_near(plate.size.x, plate.size.y, 0.01), "[%s] pratinho torto em %s" % [tag, cell.name])
			_check(_near(plate.get_global_rect().get_center().x, r.get_center().x, 0.6), "[%s] pratinho fora do centro em %s" % [tag, cell.name])
			var cell_icon := cell.find_child("Icon", true, false) as TextureRect
			if cell_icon:
				_check(_near(cell_icon.get_global_rect().get_center().x, plate.get_global_rect().get_center().x, 0.6) and _near(cell_icon.get_global_rect().get_center().y, plate.get_global_rect().get_center().y, 0.6), "[%s] ícone fora do pratinho em %s" % [tag, cell.name])
				if cell_icon.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST:
					var ratio2 := minf(cell_icon.size.x / cell_icon.texture.get_width(), cell_icon.size.y / cell_icon.texture.get_height())
					_check(_near(ratio2, 1.0, 0.001), "[%s] ícone pixel de célula com escala %.3f" % [tag, ratio2])
			if _near(r.position.y, first_y, 1.0):
				_check(scroll_rect.grow(1.0).encloses(r), "[%s] %s da primeira linha fora da área visível %s %s" % [tag, cell.name, r, scroll_rect])
			_text_fits(cell.find_child("Name", true, false) as Label, "Name", tag)
		var last_end := 0.0
		for cell in cells:
			last_end = maxf(last_end, cell.get_global_rect().end.y)
		var bar := scroll.get_v_scroll_bar()
		fills.append([scroll_rect, last_end, bar.max_value - bar.page > 1.0, first_y])
	var deepest := 0.0
	for f in fills:
		deepest = maxf(deepest, float(f[1]))
	for f in fills:
		var sr: Rect2 = f[0]
		_check(float(f[3]) - sr.position.y <= 6.0, "[%s] respiro de cima do pratinho %.1f" % [tag, float(f[3]) - sr.position.y])
		if not bool(f[2]) and _near(float(f[1]), deepest, 0.5):
			_check(sr.end.y - float(f[1]) <= 16.0, "[%s] creme vazio embaixo da última linha: %.1f px" % [tag, sr.end.y - float(f[1])])
	if panels.size() == 2:
		_check(_near(panels[0].get_global_rect().end.x + 8.0, panels[1].get_global_rect().position.x, 0.6), "[%s] espaço entre painéis diferente de 8" % tag)
		var left_gap := panels[0].get_global_rect().position.x - card_rect.position.x
		var right_gap := card_rect.end.x - panels[1].get_global_rect().end.x
		_check(_near(left_gap, right_gap, 0.6), "[%s] painéis descentralizados em relação ao cartão (%.1f x %.1f)" % [tag, left_gap, right_gap])
	elif panels.size() == 1:
		_check(_near(panels[0].get_global_rect().position.x, card_rect.position.x, 0.6) and _near(panels[0].size.x, card_rect.size.x, 0.6), "[%s] painel único não ocupa a largura do cartão" % tag)
	print("[%s] %dx%d moldura %s cartão %.0f painéis %s" % [tag, screen.x, screen.y, fr, card.size.y, "-" if panels.is_empty() else str(panels[0].size)])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "item_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()
	var db: Node = root.get_node("Database")
	var sb: Script = load("res://scripts/ui/sheet_builder.gd")

	# Escolhe itens pelos dados: o mais usado em receitas, um só com origem, um brinquedo.
	var best_use := "egg"
	var best_n := 0
	var second_use := "egg"
	var second_n := 0
	var only_source := ""
	var toy := ""
	for id: String in db.get("items"):
		var uses: Array = sb.call("_uses", id)
		var sources: Array = sb.call("_sources", id)
		if id != "carrot" and uses.size() > second_n:
			second_n = uses.size()
			second_use = id
		if uses.size() > best_n:
			best_n = uses.size()
			best_use = id
		if only_source == "" and uses.is_empty() and not sources.is_empty() and int(db.get("items")[id].get("sell_price", 0)) > 0:
			only_source = id
		if toy == "" and bool(db.get("items")[id].get("toy", false)):
			toy = id
	print("mais usado: %s (%d usos); só origem: %s; brinquedo: %s" % [best_use, best_n, only_source, toy])

	await _unlock()
	_give("carrot", 15)
	await _open("carrot", "a_cenoura")
	await _close()

	await _unlock()
	_give(second_use, 7)
	await _open(second_use, "b_muitos_usos")
	await _close()

	await _unlock()
	_give("carrot_snack", 3)
	await _open("carrot_snack", "c_comida")
	await _close()

	await _unlock()
	_give("carrot", 0)
	await _open("carrot", "d_sem_item")
	await _close()

	if only_source != "":
		await _unlock()
		_give(only_source, 4)
		await _open(only_source, "e_so_origem")
		await _close()

	await _unlock()
	_give("chew_ring", 1)
	await _open("chew_ring", "f_keepsake")
	await _close()

	await _unlock()
	var items: Dictionary = db.get("items")
	var old_name: String = items["wheat"]["name"]
	items["wheat"]["name"] = "Petisco de cenoura com mel e flores do sítio"
	_give("wheat", 9)
	await _open("wheat", "g_nome_longo")
	items["wheat"]["name"] = old_name
	await _close()

	if toy != "":
		await _unlock()
		_give(toy, 2)
		await _open(toy, "h_brinquedo")
		await _close()

	print("ITEM SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
