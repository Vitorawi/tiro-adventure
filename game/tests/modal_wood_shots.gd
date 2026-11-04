extends SceneTree
## Capturas e MEDIDAS dos cartões de comemoração (`ModalCard`) em "madeira ilustrada". NÃO é teste da suíte, mas imprime
## FAIL e sai com código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/modal_wood_shots.gd -- --out=modal_wood
## PNGs em build/screenshots/<out>/modal_<largura>x<altura>_<caso>.png. Não grava o save pessoal.

var state: Node
var main: Control
var folder := "res://../build/screenshots/modal_wood/"
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


func _text_fits(label: Label, tag: String) -> void:
	var font := label.get_theme_font("font")
	var px := label.get_theme_font_size("font_size")
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		_check(width <= label.size.x + 0.5, "[%s] %s passa da caixa (%.1f > %.1f): %s" % [tag, label.name, width, label.size.x, label.text])
	else:
		_check(label.get_line_count() <= label.get_visible_line_count() or label.get_visible_line_count() < 0, "[%s] texto cortado em %s: %s" % [tag, label.name, label.text])


## Mede o cartão aberto na camada `layer` (ModalCard dentro dela).
func _measure(layer: CanvasLayer, tag: String, expect_scroll: bool = false) -> void:
	var screen := root.get_visible_rect().size
	var card := layer.find_child("ModalCard", true, false) as Control
	_check(card != null, "[%s] sem ModalCard" % tag)
	if card == null:
		return
	var panel := card.get("panel") as Control
	var pr := panel.get_global_rect()
	_check(pr.position.x >= 7.5 and pr.end.x <= screen.x - 7.5, "[%s] cartão sai da tela na horizontal %s" % [tag, pr])
	_check(pr.position.y >= 7.5 and pr.end.y <= screen.y - 7.5, "[%s] cartão sai da tela na vertical %s" % [tag, pr])
	_check(_near(pr.get_center().x, screen.x / 2.0, 1.0) and _near(pr.get_center().y, screen.y / 2.0, 1.5), "[%s] cartão descentralizado %s" % [tag, pr])
	var body := panel.find_child("Body", true, false) as Control
	# Placa.
	var title := panel.find_child("RibbonTitle", true, false) as Label
	_check(title != null, "[%s] sem título" % tag)
	if title != null:
		var width := title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
		_check(width <= title.size.x + 0.5, "[%s] título passa da placa (%.1f > %.1f)" % [tag, width, title.size.x])
		_check(_near(title.get_global_rect().get_center().x, pr.get_center().x, 1.5), "[%s] título descentralizado" % tag)
	# Botões.
	var greens := 0
	for node in panel.find_children("*", "Button", true, false):
		var button := node as Button
		if not button.is_visible_in_tree():
			continue
		var scroller := button.get_parent()
		while scroller != null and not scroller is ScrollContainer:
			scroller = scroller.get_parent()
		if scroller != null and not (scroller as Control).get_global_rect().grow(1.0).encloses(button.get_global_rect()):
			continue  # rolado para fora da vista
		_check(button.size.x >= 43.5 and button.size.y >= 43.5, "[%s] alvo menor que 44 em %s (%s)" % [tag, button.name, button.size])
		_check(pr.grow(0.5).encloses(button.get_global_rect()), "[%s] botão %s fora da moldura" % [tag, button.name])
		if button.has_meta("wood_primary"):
			greens += 1
		if button.text != "":
			var text_w := button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			_check(text_w <= button.size.x - 12.0, "[%s] texto do botão %s não cabe (%.1f > %.1f)" % [tag, button.name, text_w, button.size.x])
	_check(greens <= 1, "[%s] botões verdes: %d (máximo 1)" % [tag, greens])
	# Textos e imagens do corpo.
	var base := body.get_global_rect()
	for label_node in body.find_children("*", "Label", true, false):
		var label := label_node as Label
		if label.is_visible_in_tree() and label.text != "":
			_text_fits(label, tag)
	for rect_node in panel.find_children("*", "TextureRect", true, false):
		var picture := rect_node as TextureRect
		if not picture.is_visible_in_tree() or picture.texture == null:
			continue
		var texture := picture.texture
		if picture.stretch_mode == TextureRect.STRETCH_SCALE:
			var drawn := picture.size.x / picture.size.y
			var source := float(texture.get_width()) / float(texture.get_height())
			_check(absf(drawn / source - 1.0) <= 0.01, "[%s] %s desenhado com razão %.3f ≠ fonte %.3f" % [tag, picture.name, drawn, source])
		elif picture.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and picture.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST:
			var scale := minf(picture.size.x / texture.get_width(), picture.size.y / texture.get_height())
			_check(_near(scale, roundf(scale), 0.001) and scale >= 1.0 or texture.get_width() > 64, "[%s] pixel %s em escala %.3f (não inteira)" % [tag, picture.name, scale])
	# Herói: ícone dentro do pratinho, pratinho dentro do corpo.
	var icon := panel.find_child("BigIcon", true, false) as TextureRect
	var plate := panel.find_child("Plate", true, false) as TextureRect
	if icon != null and plate != null:
		_check(plate.get_global_rect().grow(0.5).encloses(icon.get_global_rect()), "[%s] ícone fora do pratinho" % tag)
		_check(_near(icon.get_global_rect().get_center().x, plate.get_global_rect().get_center().x, 0.6) and _near(icon.get_global_rect().get_center().y, plate.get_global_rect().get_center().y, 0.6), "[%s] ícone descentralizado no pratinho" % tag)
		_check(_near(plate.get_global_rect().get_center().x, pr.get_center().x, 1.5), "[%s] pratinho descentralizado" % tag)
		_check(base.grow(1.0).encloses(plate.get_global_rect()), "[%s] pratinho fora do corpo" % tag)
	# Nada do corpo vaza da moldura nem passa da base do papel.
	for control_node in body.find_children("*", "Control", true, false):
		var control := control_node as Control
		if not control.is_visible_in_tree() or control is ScrollBar:
			continue
		var scroller2 := control.get_parent()
		var rolled := false
		while scroller2 != null and scroller2 != body:
			if scroller2 is ScrollContainer:
				rolled = true
			scroller2 = scroller2.get_parent()
		if rolled:
			continue
		var rect := control.get_global_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0 and control.name != "Rays" and control.name != "Stage" and control.get_parent().name != "Stage":
			_check(base.grow(1.5).encloses(rect) or control.get_parent().name == "Stage", "[%s] %s vaza do corpo %s fora de %s" % [tag, control.name, rect, base])
	var scroll_node := body.find_child("*Scroll", true, false) as ScrollContainer
	if scroll_node != null and scroll_node.is_visible_in_tree():
		var scrolls := scroll_node.get_v_scroll_bar().max_value - scroll_node.get_v_scroll_bar().page > 1.0
		print("[%s] rolagem interna: %s" % [tag, "sim" if scrolls else "não"])
		if expect_scroll:
			_check(scrolls, "[%s] esperava rolagem" % tag)
	print("[%s] %dx%d cartão %s" % [tag, screen.x, screen.y, pr])


func _shot(layer: CanvasLayer, shot_name: String, expect_scroll: bool = false) -> void:
	for i in 60:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "modal_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	_measure(layer, shot_name, expect_scroll)
	layer.hide()
	_hide_modals()


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "modal_wood_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	await _unlock()
	var celebration: CanvasLayer = main.get("_celebration")
	var walk: CanvasLayer = main.get("_walk_result")
	var ceremony: CanvasLayer = main.get("_growth_ceremony")
	# Achado (pena colorida, como no print do celular).
	celebration.call("show_find", {"new": ["hen_feather"], "label": "Pena colorida", "icon": "find_paw"})
	await _shot(celebration, "a_achado")
	# Raro do passeio e roupa pronta (apetrecho novo na Coleção).
	var rare := ""
	var db: Node = root.get_node("Database")
	for id: String in db.get("collections"):
		if str(db.get("collections")[id].get("rarity", "")) == "rare":
			rare = id
			break
	walk.call("show_result", {"kind": "walk", "name": "Passeio no Bosque", "rare": rare, "coins": 30, "items": {"hen_feather": 2, "carrot": 3}, "new": ["hen_feather"], "needs": {"fun": 12}, "first": true, "collections": []})
	await _shot(walk, "b_raro_passeio")
	walk.call("show_result", {"kind": "sewing", "rare": rare, "coins": 0, "items": {}, "collections": [rare]})
	await _shot(walk, "c_roupa_pronta")
	# Tesouro.
	celebration.call("show_treasure", {"coins": 100, "items": {"bolt": 2}, "collections": ["explorer_hat"], "unlocks": ["crop:blueberry"]})
	await _shot(celebration, "d_tesouro")
	# Capítulo com seis novidades (corpo fixo + rolagem só das novidades).
	var unlocks: Array[String] = ["world:farm", "world:village", "world:house", "npc:nina", "place:farm/orchard", "feature:bag"]
	celebration.call("show_chapter", 2, unlocks)
	await _shot(celebration, "e_capitulo")
	# Truque aprendido.
	celebration.call("show_trick", "paw")
	await _shot(celebration, "f_truque")
	# Crescimento (herói próprio: antes/depois + régua).
	var phases: Array = db.get("growth").phases
	ceremony.set("phase", str(phases[1].id))
	ceremony.set("_before", phases[0].duplicate(true))
	ceremony.set("_after", phases[1].duplicate(true))
	ceremony.call("show")
	ceremony.call("show_card")
	await _shot(ceremony, "g_crescimento")
	print("MODAL WOOD SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
