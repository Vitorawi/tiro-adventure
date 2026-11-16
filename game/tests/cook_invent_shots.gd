extends SceneTree
## Capturas da aba Inventar do fogão com medidas que imprimem FALHOU. NÃO é teste. Rodar SEM --headless, por resolução:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/cook_invent_shots.gd -- --out=cook_invent
## PNGs em build/screenshots/<out>/inv_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var house: Control
var folder := "res://../build/screenshots/cook_invent/"
var failures := 0
var cook: Script


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(300).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FALHOU: ", message)


func panel() -> Control:
	return cook.call("current") as Control


func view() -> Control:
	return panel().find_child("InventView", true, false) as Control


func grect(node: Control) -> Rect2:
	var xf := node.get_global_transform_with_canvas()
	return Rect2(xf.origin, node.size * xf.get_scale())


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


func _fresh() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	state.set("animals", {})
	state.get("progress").owned.erase("stove_queue_3")


func _add(item: String, amount: int) -> void:
	state.get("inventory").call("add", item, amount)


func _open() -> void:
	for attempt in 4:
		house.call("close_tray")
		house.call("open_station_tray", "stove", "")
		await create_timer(0.6).timeout
		_hide_modals()
		if panel() != null:
			panel().call("_set_mode", true)
			view().call("reset_choices")
			await create_timer(0.2).timeout
			return


func shot(shot_name: String, wait: float = 0.5) -> void:
	await create_timer(wait).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "inv_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(shot_name)


## Está dentro da janela de rolagem que o recorta (só o que está à vista conta)?
func _visible_in_scroll(node: Control) -> bool:
	var rect := grect(node)
	var ancestor: Node = node.get_parent()
	while ancestor != null and ancestor != panel():
		if ancestor is CookScroll:
			return grect(ancestor as Control).grow(1.0).encloses(rect)
		ancestor = ancestor.get_parent()
	return rect.size.x > 0.0


func _tap_target(label: String, node: Control, strict: bool) -> void:
	var hit := node.get_node_or_null("Hit") as Control
	var rect := grect(hit if hit != null else node)
	if node.has_meta("hit_pad"):
		var pad: Vector2 = node.get_meta("hit_pad")
		rect = Rect2(rect.position, rect.size + pad * 2.0 * node.get_global_transform_with_canvas().get_scale())
	if rect.size.x < 43.5 or rect.size.y < 43.5:
		if strict:
			_check(false, "[%s] %s menor que 44 px (%.1fx%.1f)" % [label, node.name, rect.size.x, rect.size.y])
		else:
			print("  AVISO: alvo %s menor que 44 px (%.1fx%.1f) — tamanho do Figma" % [node.name, rect.size.x, rect.size.y])


func _measure(label: String) -> void:
	var current := panel()
	if current == null:
		_check(false, "[%s] sem painel aberto" % label)
		return
	var screen := root.get_visible_rect().size
	var top := grect(current.find_child("PanelTop", true, false) as Control)
	var bottom := grect(current.find_child("PanelBottom", true, false) as Control)
	var pill := main.find_child("MapButton", true, false) as Control
	var tabs := main.find_child("TabBarArt", true, false) as Control
	var frame := top.merge(bottom)
	print("[%s] tela %s painel %s s=%.3f E=%.1f" % [label, screen, frame, current.scale.x, current.get("_e")])
	_check(frame.position.x >= -0.5 and frame.end.x <= screen.x + 0.5, "[%s] painel fora da tela na largura" % label)
	_check(frame.position.y >= grect(pill).end.y - 3.0, "[%s] painel sobre a pílula do mundo" % label)
	_check(frame.end.y <= grect(tabs).position.y + 0.5, "[%s] painel sobre as abas" % label)
	var inv := view()
	# tudo que é peça do Inventar fica dentro da tela
	for node in inv.find_children("*", "Control", true, false):
		var control := node as Control
		if control.name in ["Hit", "InvPickerCatcher", "Backing"] or not control.is_visible_in_tree() or not _visible_in_scroll(control):
			continue
		var rect := grect(control)
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if rect.position.x < -2.0 or rect.end.x > screen.x + 2.0 or rect.position.y < -2.0 or rect.end.y > screen.y + 2.0:
			if not (control is Label):
				_check(false, "[%s] %s sai da tela %s" % [label, control.name, rect])
	# alvos de toque
	for node in inv.find_children("InvType_*", "Control", true, false):
		if _visible_in_scroll(node as Control):
			_tap_target(label, node as Control, true)
	for node in inv.find_children("InvSlot_*", "Control", true, false):
		_tap_target(label, node as Control, true)
	for node_name: String in ["InvCookButton", "InvSelect", "InvRemove", "InvPickerClose"]:
		var node := inv.find_child(node_name, true, false) as Control
		if node != null:
			_tap_target(label, node, true)
	for node in inv.find_children("InvCell_*", "Control", true, false):
		if _visible_in_scroll(node as Control):
			_tap_target(label, node as Control, true)
	for node_name: String in ["InvTypeArrow", "Thumb", "Up", "Down"]:
		var node := inv.find_child(node_name, true, false) as Control
		if node != null and node.is_visible_in_tree():
			_tap_target(label, node, false)
	# texto cabendo na caixa
	for node in inv.find_children("*", "Label", true, false):
		var text := node as Label
		if text.text == "" or not text.is_visible_in_tree() or not _visible_in_scroll(text):
			continue
		var font := text.get_theme_font("font")
		var px := text.get_theme_font_size("font_size")
		var wraps := text.autowrap_mode != TextServer.AUTOWRAP_OFF
		var measured := font.get_multiline_string_size(text.text, HORIZONTAL_ALIGNMENT_LEFT, text.size.x if wraps else -1.0, px)
		if measured.y > text.size.y + 1.0 or measured.x > text.size.x + 1.0:
			_check(false, "[%s] texto estoura a caixa: '%s' (%.1fx%.1f em %.1fx%.1f, fonte %d)" % [label, text.text, measured.x, measured.y, text.size.x, text.size.y, px])
	# imagens do Figma desenhadas na razão da fonte
	for node in inv.find_children("*", "TextureRect", true, false):
		var pic := node as TextureRect
		if pic.texture == null or pic.stretch_mode != TextureRect.STRETCH_SCALE or not pic.is_visible_in_tree():
			continue
		var source := pic.texture.get_size()
		if pic.size.x <= 0.0 or pic.size.y <= 0.0:
			continue
		var ratio := (pic.size.x / pic.size.y) / (source.x / source.y)
		if absf(ratio - 1.0) > 0.01:
			_check(false, "[%s] imagem %s deformada (razão %.3f)" % [label, pic.name, ratio])


func _choose(index: int, item: String) -> void:
	view().call("set_slot", index, item)
	await create_timer(0.2).timeout


func _run() -> void:
	cook = load("res://scripts/ui/cook_panel.gd")
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "cook_invent_descartavel.json"))
	state = root.get_node("GameState")
	var db: Node = root.get_node("Database")
	Motion.reduced = false
	_fresh()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	main.call("_on_world_requested", "house", "")
	main.call("show_screen", &"map")
	await create_timer(0.8).timeout
	_hide_modals()
	house = main.find_child("World_house", true, false) as Control
	house.call("_animate_objects")
	# Um tipo de quatro espaços livres só para as capturas (não vai para o JSON).
	(db.get("invent").dish_types as Array).append({"id": "livre", "name": "Livre", "dish": "carrot_snack", "title": "Seu Prato", "slots": ["free", "free", "free", "free"], "hint": "Qualquer mistura.", "hint_long": "Quatro espaços livres: ponha o que quiser e veja no que dá."})
	(db.get("invent").recommended.legume as Array).erase("sweet_potato")

	# (a) sem nada escolhido.
	_fresh()
	_add("carrot", 3)
	_add("potato", 2)
	_add("corn", 2)
	await _open()
	await shot("a_sem_nada")

	# (b) um espaço preenchido: prato desconhecido.
	await _choose(0, "carrot")
	await shot("b_desconhecido")

	# (c) prato conhecido (cenoura + batata).
	await _choose(1, "potato")
	await shot("c_conhecido")

	# (d) janelinha: na panela, recomendados que acabaram, outro com estoque.
	_add("sweet_potato", 2)
	view().call("open_picker", 0)
	await shot("d_janelinha")

	# (e) janelinha rolada até o fim: tipo livre, vários ingredientes.
	view().call("close_picker")
	for item: String in db.get("invent").items:
		_add(item, 1)
	view().call("choose_type", "livre")
	await _choose(0, "apple")
	await _choose(1, "egg")
	await shot("e_quatro_espacos")
	view().call("open_picker", 2)
	await create_timer(0.4).timeout
	(panel().find_child("InvPickerScroll", true, false) as CookScroll).scroll_to(100000.0, false)
	await shot("e2_janelinha_no_fim", 0.3)
	view().call("close_picker")

	# (f) tipos rolados para o lado.
	view().call("choose_type", "papinha")
	view().call("_scroll_types")
	view().call("_scroll_types")
	await create_timer(0.4).timeout
	view().call("choose_type", "lanche")
	await shot("f_tipos_rolados", 0.4)

	panel().call("close", true)
	print("COOK INVENT SHOTS: ", "PASS" if failures == 0 else "FALHOU (%d)" % failures)
	quit(0 if failures == 0 else 1)
