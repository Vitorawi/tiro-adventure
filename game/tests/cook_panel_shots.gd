extends SceneTree
## Capturas da cozinha nova (fogão) com medidas que imprimem FALHOU. NÃO é teste. Rodar SEM --headless, por resolução:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/cook_panel_shots.gd -- --out=cook_panel
## PNGs em build/screenshots/<out>/cook_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var house: Control
var folder := "res://../build/screenshots/cook_panel/"
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


## Retângulo na tela de um Control (a escala do painel vale para tudo que está dentro dele).
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
	state.call("dev_week_goto", 4)
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	state.set("animals", {})


func _add(item: String, amount: int) -> void:
	state.get("inventory").call("add", item, amount)


func _open(focus: String = "") -> void:
	# O estado recém-zerado dispara anúncios da casca (que fecham painéis): abre de novo até assentar.
	for attempt in 4:
		house.call("close_tray")
		house.call("open_station_tray", "stove", focus)
		await create_timer(0.6).timeout
		_hide_modals()
		if panel() != null:
			return


func shot(shot_name: String, wait: float = 0.5) -> void:
	await create_timer(wait).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "cook_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(shot_name)


## Medidas: dentro da tela, entre a pílula do mundo e as abas; cartões iguais; texto cabendo; alvos de toque.
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
	print("[%s] tela %s painel %s s=%.3f E=%.1f pílula fim y=%.1f abas y=%.1f" % [label, screen, frame, current.scale.x, current.get("_e"), grect(pill).end.y, grect(tabs).position.y])
	_check(frame.position.x >= -0.5 and frame.end.x <= screen.x + 0.5, "[%s] painel fora da tela na largura" % label)
	_check(frame.position.y >= grect(pill).end.y - 3.0, "[%s] painel sobre a pílula do mundo (topo %.1f, pílula %.1f)" % [label, frame.position.y, grect(pill).end.y])
	_check(frame.end.y <= grect(tabs).position.y + 0.5, "[%s] painel sobre as abas (fim %.1f, abas %.1f)" % [label, frame.end.y, grect(tabs).position.y])
	_check(frame.position.y >= 100.0, "[%s] painel sob o HUD" % label)
	# cartões de prato idênticos
	var sizes: Dictionary = {}
	for node in current.find_children("Dish_*", "Control", true, false):
		sizes[(node as Control).size] = true
		_tap_target(label, node as Control, true)
	_check(sizes.size() <= 1, "[%s] cartões de prato com tamanhos diferentes: %s" % [label, sizes.keys()])
	for node in current.find_children("Slot_*", "Control", true, false):
		_tap_target(label, node as Control, true)
	for node in current.find_children("Cat_*", "Control", true, false):
		if _on_screen(current, node as Control):
			_tap_target(label, node as Control, false)
	for node_name: String in ["DishesHalf", "InventHalf", "CloseButton"]:
		var node := current.find_child(node_name, true, false) as Control
		if node:
			_tap_target(label, node, true)
	for node_name: String in ["QueueButton", "TogetherButton"]:
		var node := current.find_child(node_name, true, false) as Control
		if node:
			_tap_target(label, node, false)
	for node_name: String in ["Filter_can", "Filter_missing", "Filter_tiro", "CatArrow", "Thumb", "Up", "Down"]:
		var node := current.find_child(node_name, true, false) as Control
		if node and node.is_visible_in_tree():
			_tap_target(label, node, false)
	for node in current.find_children("Ingredient_*", "Control", true, false):
		_tap_target(label, node as Control, false)
	# texto cabendo na caixa
	for node in current.find_children("*", "Label", true, false):
		var text := node as Label
		if text.text == "" or not _on_screen(current, text):
			continue
		var font := text.get_theme_font("font")
		var px := text.get_theme_font_size("font_size")
		var wraps := text.autowrap_mode != TextServer.AUTOWRAP_OFF
		var measured := font.get_multiline_string_size(text.text, HORIZONTAL_ALIGNMENT_LEFT, text.size.x if wraps else -1.0, px)
		if measured.y > text.size.y + 1.0 or measured.x > text.size.x + 1.0:
			_check(false, "[%s] texto estoura a caixa: '%s' (%.1fx%.1f em %.1fx%.1f, fonte %d)" % [label, text.text, measured.x, measured.y, text.size.x, text.size.y, px])
		if px * current.scale.x < 8.0:
			print("  AVISO: fonte pequena na tela (%.1f px): '%s'" % [px * current.scale.x, text.text])


## Janelas de rolagem escondem o que passa da borda: só confere o que está à vista.
func _on_screen(current: Control, node: Control) -> bool:
	var rect := grect(node)
	for ancestor: Node in [node.get_parent(), node.get_parent().get_parent() if node.get_parent() else null]:
		if ancestor is CookScroll or (ancestor is Control and ancestor.get_parent() is CookScroll):
			var scroll := (ancestor if ancestor is CookScroll else ancestor.get_parent()) as CookScroll
			if not grect(scroll).grow(1.0).encloses(rect):
				return false
	return rect.size.x > 0.0 and current.is_visible_in_tree()


func _tap_target(label: String, node: Control, strict: bool) -> void:
	var hit := node.get_node_or_null("Hit") as Control
	var rect := grect(hit if hit != null else node)
	if hit != null:
		print("  alvo %s (área de toque ampliada): %.1fx%.1f px" % [node.name, rect.size.x, rect.size.y])
	elif node.name.begins_with("Cat_") and node.has_meta("hit_pad"):
		var pad: Vector2 = node.get_meta("hit_pad")
		rect = Rect2(rect.position, rect.size + pad * 2.0 * node.get_global_transform_with_canvas().get_scale())
		print("  alvo %s (área de toque ampliada): %.1fx%.1f px" % [node.name, rect.size.x, rect.size.y])
	if rect.size.x < 43.5 or rect.size.y < 43.5:
		if strict:
			_check(false, "[%s] %s menor que 44 px (%.1fx%.1f)" % [label, node.name, rect.size.x, rect.size.y])
		else:
			print("  AVISO: alvo %s menor que 44 px (%.1fx%.1f) — tamanho do Figma" % [node.name, rect.size.x, rect.size.y])


func _run() -> void:
	cook = load("res://scripts/ui/cook_panel.gd")
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "cook_panel_descartavel.json"))
	state = root.get_node("GameState")
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

	# (a) sem prato escolhido; espaços: pronto, fazendo, livre e fechado.
	_fresh()
	state.get("progress").owned.erase("stove_queue_3")
	_add("carrot", 12)
	_add("potato", 4)
	state.call("cook_many", "carrot_snack", 2)
	state.call("station", "stove").queue[0]["ready_at"] = float(state.call("now")) - 5.0
	await _open()
	await shot("a_sem_prato")

	# (b) prato com todos os ingredientes escolhido (1 ingrediente).
	panel().call("_select_dish", "carrot_snack")
	await shot("b_prato_com_tudo")

	# (c) faltando ingredientes: com 2 e com 3 ingredientes.
	_fresh()
	_add("carrot", 1)
	await _open("vegetable_soup")
	await shot("c_falta_2_ingredientes")
	await _open("growth_kibble")
	_add("corn", 1)
	await shot("c2_falta_3_ingredientes")

	# (d) quatro espaços ocupados.
	_fresh()
	_add("carrot", 30)
	for i in 4:
		state.call("cook", "carrot_snack")
	await _open("carrot_snack")
	await shot("d_quatro_ocupados")

	# (e) lista rolada até o fim + filtro "Dá para fazer".
	_fresh()
	_add("carrot", 30)
	_add("potato", 6)
	await _open("carrot_snack")
	var list := panel().find_child("DishList", true, false) as Control
	list.call("scroll_to", 100000.0, false)
	await shot("e_lista_no_fim", 0.3)
	panel().call("_toggle_filter", "can")
	await shot("e2_filtro_pode_fazer", 0.3)
	panel().call("_toggle_filter", "tiro")
	await shot("e3_filtro_do_tiro", 0.3)

	# (f) categorias roladas.
	panel().call("_toggle_filter", "tiro")
	panel().call("_scroll_categories")
	panel().call("_select_category", "sopinha")
	await shot("f_categorias", 0.6)

	# (g) pratos conhecidos com estrelas e o selo "Para crescer" (papinha de peixe pedida pelo crescimento).
	_fresh()
	_add("carrot", 12)
	_add("corn", 4)
	_add("egg", 3)
	state.call("cook_invented", {"carrot": 1, "corn": 1}, "papinha")
	state.call("cook_invented", {"carrot": 1, "egg": 1}, "papinha")
	state.call("cook", "carrot_snack")
	state.call("dev_set_phase", "puppy")
	_add("fish_tilapia", 2)
	_add("potato", 2)
	state.call("station", "stove").queue[0]["ready_at"] = float(state.call("now")) - 5.0
	await _open("fish_mash")
	await shot("g_conhecidos_e_para_crescer")
	panel().call("_select_dish", "k_papinha_cenoura+milho")
	await shot("g2_prato_conhecido_selecionado", 0.3)
	panel().call("_select_category", "papinha")
	await shot("g3_categoria_papinhas", 0.4)

	panel().call("close", true)
	print("COOK PANEL SHOTS: ", "PASS" if failures == 0 else "FALHOU (%d)" % failures)
	quit(0 if failures == 0 else 1)
