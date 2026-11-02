extends SceneTree
## Capturas e MEDIDAS do cartão de boas-vindas em "madeira ilustrada". NÃO é teste da suíte, mas imprime FAIL e sai com
## código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/welcome_shots.gd -- --out=welcome
## PNGs em build/screenshots/<out>/welcome_<largura>x<altura>_<caso>.png. Não grava o save pessoal.

var state: Node
var main: Control
var welcome: CanvasLayer
var folder := "res://../build/screenshots/welcome/"
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
	await create_timer(1.0).timeout
	_hide_modals()


## Monta o cartão como o WelcomeBack faz, mas com as linhas dadas (assim a rolagem e os textos longos são testáveis).
func _open(shot_name: String, gift: Dictionary, specs: Array) -> void:
	var lines: Array[Dictionary] = []
	for spec: Dictionary in specs:
		lines.append(welcome.call("_line_row", spec))
	var sheet: Control = (load("res://scripts/ui/welcome_sheet.gd") as GDScript).call("open", welcome, {"gift": gift, "lines": lines, "animate": false, "on_gift": func() -> void: pass})
	welcome.show()
	sheet.call("present")
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "welcome_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(shot_name, not gift.is_empty())
	welcome.hide()


func _screen_ok(rect: Rect2, tag: String, what: String) -> void:
	var screen := root.get_visible_rect().size
	_check(rect.position.x >= -0.5 and rect.end.x <= screen.x + 0.5, "[%s] %s fora da tela na horizontal %s" % [tag, what, rect])


func _measure(tag: String, has_gift: bool) -> void:
	var screen := root.get_visible_rect().size
	var sheet := welcome.find_child("RewardSheet", true, false) as Control
	var frame := sheet.find_child("WelcomeFrame", true, false) as Control
	var fr := frame.get_global_rect()
	_screen_ok(fr, tag, "moldura")
	_check(_near(fr.get_center().x, screen.x / 2.0, 1.0), "[%s] moldura descentralizada" % tag)
	_check(fr.position.y >= 127.5, "[%s] folha invade o HUD (topo %.1f)" % [tag, fr.position.y])
	_check(fr.end.y <= screen.y + 0.5, "[%s] folha passa da base (%.1f > %.1f)" % [tag, fr.end.y, screen.y])
	# Botões: alvo >= 44; exatamente um verde (wood_primary), fora o X.
	var greens := 0
	for node in frame.find_children("*", "Button", true, false):
		var button := node as Button
		if not button.is_visible_in_tree():
			continue
		var scroller := button.get_parent()
		while scroller != null and not scroller is ScrollContainer:
			scroller = scroller.get_parent()
		if scroller != null and not (scroller as Control).get_global_rect().grow(1.0).encloses(button.get_global_rect()):
			continue  # linha rolada para fora da vista
		_check(button.size.x >= 43.5 and button.size.y >= 43.5, "[%s] alvo de toque menor que 44 em %s (%s)" % [tag, button.name, button.size])
		_check(fr.grow(0.5).encloses(button.get_global_rect()), "[%s] botão %s fora da moldura" % [tag, button.name])
		if button.has_meta("wood_primary"):
			greens += 1
		if button.text != "":
			var width := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			_check(width <= button.size.x - 12.0, "[%s] texto do botão %s não cabe (%.1f > %.1f)" % [tag, button.name, width, button.size.x])
	_check(greens == 1, "[%s] botões verdes: %d (deve ser 1)" % [tag, greens])
	# Placa.
	var title := frame.find_child("WelcomeTitle", true, false) as Label
	var title_width := title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
	_check(title_width <= title.size.x + 0.5, "[%s] título passa da placa (%.1f > %.1f)" % [tag, title_width, title.size.x])
	_check(_near(title.get_global_rect().get_center().x, fr.get_center().x, 1.5), "[%s] título descentralizado" % tag)
	# Cartão do presente.
	var gift := frame.find_child("DailyGift", true, false) as Control
	_check((gift != null) == has_gift, "[%s] cartão do presente %s" % [tag, "ausente" if has_gift else "presente sem presente"])
	var anchor_bottom := fr.position.y
	if gift != null:
		var gr := gift.get_global_rect()
		_check(fr.grow(0.5).encloses(gr), "[%s] cartão fora da moldura" % tag)
		_check(_near(gr.get_center().x, fr.get_center().x + 1.25, 1.5), "[%s] cartão descentralizado" % tag)
		var body := gift.find_child("Body", true, false) as Control
		for child in body.get_children():
			_check(gr.grow(0.5).encloses((child as Control).get_global_rect()), "[%s] %s fora do cartão do presente" % [tag, child.name])
		var plate := gift.find_child("GiftPlate", true, false) as Control
		_check(_near(plate.size.x, plate.size.y, 0.01), "[%s] pratinho do Tiro torto" % tag)
		var head := plate.find_child("Icon", true, false) as TextureRect
		if head:
			_check(_near(head.get_global_rect().get_center().x, plate.get_global_rect().get_center().x, 0.6), "[%s] Tiro fora do centro do pratinho" % tag)
		var take := gift.find_child("Pegar", true, false) as Control
		_check(gr.grow(0.5).encloses(take.get_global_rect()) and take.get_global_rect().position.y - gr.position.y <= 20.0, "[%s] Pegar fora do topo do cartão" % tag)
		var chips_box := gift.find_child("GiftChips", true, false) as Control
		if chips_box != null:
			for chip in chips_box.get_children():
				_check(chips_box.get_global_rect().grow(0.5).encloses((chip as Control).get_global_rect()), "[%s] chip %s vaza do fluxo" % [tag, chip.name])
		anchor_bottom = gr.end.y
		for label in gift.find_children("*", "Label", true, false):
			if (label as Label).autowrap_mode == TextServer.AUTOWRAP_OFF and not (label as Label).clip_text:
				_text_fits(label as Label, tag)
	# Painel de linhas.
	var panel := frame.find_child("WelcomePanel", true, false) as Control
	var last_end := anchor_bottom
	if panel != null:
		var pr := panel.get_global_rect()
		_check(fr.grow(0.5).encloses(pr), "[%s] painel fora da moldura" % tag)
		_check(pr.position.y >= anchor_bottom + 7.5, "[%s] painel encosta no cartão" % tag)
		var heading := panel.find_child("PanelTitle", true, false) as Label
		_check(_near(heading.get_global_rect().get_center().x, pr.get_center().x, 1.0), "[%s] título do painel descentralizado" % tag)
		var scroll := panel.find_child("WelcomeScroll", true, false) as ScrollContainer
		var scrolls := scroll != null and scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page > 1.0
		var visible_rect := (scroll.get_global_rect() if scroll != null else pr)
		var deepest := 0.0
		var rows := panel.find_children("Line_*", "Control", true, false)
		_check(not rows.is_empty(), "[%s] painel sem linhas" % tag)
		for row_node in rows:
			var row := row_node as Control
			var rr := row.get_global_rect()
			deepest = maxf(deepest, rr.end.y)
			var go := row.find_child("LineGo", true, false) as Button
			_check(go != null and rr.grow(0.5).encloses(go.get_global_rect()), "[%s] Ir fora da linha %s" % [tag, row.name])
			_check(_near(go.get_global_rect().get_center().y, rr.get_center().y, 1.5), "[%s] Ir descentralizado na linha %s" % [tag, row.name])
			var plate2 := row.find_child("RowPlate", true, false) as Control
			_check(_near(plate2.size.x, plate2.size.y, 0.01), "[%s] pratinho da linha torto" % tag)
			_check(_near(plate2.get_global_rect().get_center().y, rr.get_center().y, 1.5), "[%s] pratinho descentralizado na linha %s" % [tag, row.name])
			var icon := plate2.find_child("Icon", true, false) as TextureRect
			if icon:
				_check(_near(icon.get_global_rect().get_center().x, plate2.get_global_rect().get_center().x, 0.6) and _near(icon.get_global_rect().get_center().y, plate2.get_global_rect().get_center().y, 0.6), "[%s] ícone fora do pratinho em %s" % [tag, row.name])
				var ratio := minf(icon.size.x / icon.texture.get_width(), icon.size.y / icon.texture.get_height())
				_check(_near(ratio, 1.0, 0.001) or icon.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST, "[%s] ícone pixel com escala %.3f em %s" % [tag, ratio, row.name])
			var name_label := row.find_child("RowName", true, false) as Label
			_check(name_label.get_line_count() <= name_label.get_visible_line_count() or name_label.get_visible_line_count() < 0, "[%s] texto cortado em %s: %s" % [tag, row.name, name_label.text])
			_check(name_label.get_line_count() <= 3, "[%s] título com mais de 3 linhas em %s" % [tag, row.name])
			for tex in row.find_children("*", "TextureRect", true, false):
				var t := tex as TextureRect
				if t.name != "Icon" and t.get_parent().name == "RowIcons":
					_check(_near(t.size.x, 32.0, 0.1), "[%s] ícone da fileira com tamanho %s" % [tag, t.size])
					if t.texture.get_width() != 32: print("  nota: ícone ", t.texture.resource_path, " ", t.texture.get_size())
				if not scrolls:
					continue
			if not scrolls:
				_check(visible_rect.grow(1.0).encloses(rr), "[%s] linha %s fora da área %s %s" % [tag, row.name, rr, visible_rect])
		if not scrolls:
			var holder_bottom := deepest
			_check(pr.end.y - 20.4 - holder_bottom <= 16.0, "[%s] creme vazio sob a última linha: %.1f px" % [tag, pr.end.y - 20.4 - holder_bottom])
		else:
			_check(visible_rect.size.y >= 120.0, "[%s] área rolável muito baixa (%.1f)" % [tag, visible_rect.size.y])
			print("[%s] rola: sim (%d linhas)" % [tag, rows.size()])
		last_end = pr.end.y
	# Botão de baixo: centrado, abaixo do conteúdo, e as flores da base livres.
	var closing := frame.find_child("Depois" if has_gift else "Vamos lá!", true, false) as Control
	_check(closing != null, "[%s] botão de baixo ausente" % tag)
	if closing != null:
		var cr := closing.get_global_rect()
		_check(_near(cr.get_center().x, fr.get_center().x + 1.25, 1.5), "[%s] botão de baixo descentralizado" % tag)
		_check(cr.position.y >= last_end + 7.5, "[%s] botão de baixo encosta no conteúdo" % tag)
		_check(fr.end.y - cr.end.y >= 45.5, "[%s] botão invade a base da moldura (%.1f)" % [tag, fr.end.y - cr.end.y])
	print("[%s] %dx%d moldura %s" % [tag, screen.x, screen.y, fr])


func _text_fits(label: Label, tag: String) -> void:
	var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	_check(width <= label.size.x + 0.5, "[%s] %s passa da caixa (%.1f > %.1f): %s" % [tag, label.name, width, label.size.x, label.text])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "welcome_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	welcome = main.get("_welcome")
	await _unlock()
	var friend_id: String = str(root.get_node("Database").get("friends").friends.keys()[0])
	var worlds: Array = root.get_node("Database").get("worlds").keys()
	var photo := {"kind": "photo", "count": 10, "world": "", "target": ""}
	var dig2 := {"kind": "dig", "count": 2, "worlds": [worlds[0], worlds[1]], "world": worlds[0], "target": "find"}
	var dig5 := {"kind": "dig", "count": 5, "worlds": worlds.slice(0, 5), "world": worlds[0], "target": "find"}
	var ready := {"kind": "ready", "count": 2, "icons": ["carrot"], "world": "farm", "target": "plots"}
	var ready3 := {"kind": "ready", "count": 7, "icons": ["carrot", "egg", "milk"], "world": "house", "target": "station:stove"}
	var walk := {"kind": "walk", "count": 1, "world": "park", "target": "walks"}
	var grow := {"kind": "growth", "count": 1, "world": "", "target": "", "sleeping": false}
	var visit := {"kind": "friend_visit", "count": 1, "friend": friend_id, "world": "house", "target": "friend_visit:" + friend_id}
	var gift := {"coins": 25}
	var gift2 := {"coins": 25, "items": {"dog_food": 3, "carrot": 2}}
	await _open("a_presente_3_linhas", gift, [photo, dig2, ready])
	await _open("a2_presente_dois_chips", gift2, [photo, dig2, ready])
	await _open("b_so_presente", gift, [])
	await _open("c_sem_presente_linhas", {}, [photo, dig5, ready3, walk])
	await _open("c2_sem_presente_muitas", {}, [photo, dig5, ready3, walk, grow, visit, ready, dig2, ready3, photo])
	await _open("d_crescimento", gift, [grow])
	await _open("e_visita_longa", {}, [visit, grow])
	print("WELCOME SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
