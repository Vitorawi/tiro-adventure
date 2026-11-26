extends SceneTree
## Capturas e MEDIDAS do novo Livro de receitas (tela única, Panela, painel do prato, caminho do cozinheiro, nível novo e
## tutorial). NÃO é teste da suíte, mas imprime FAIL e sai com código 1 se algo sair da tela, ficar menor que 44 px,
## tiver texto cortado ou mais de um botão verde. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/recipe_book_shots.gd -- --out=recipe_book_v2
## PNGs em build/screenshots/<out>/book_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

var state: Node
var main: Control
var folder := "res://../build/screenshots/recipe_book_v2/"
var failures := 0
var current := ""


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(900).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: [%s] %s" % [current, message])


func _pause(seconds: float = 0.3) -> void:
	await create_timer(seconds).timeout


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


func _node(id: String) -> Control:
	return main.find_child(id, true, false) as Control


func _touch(id: String) -> void:
	var control := _node(id)
	_check(control != null and control.is_visible_in_tree(), "controle %s existe" % id)
	if control == null:
		return
	var scroll := control.get_parent()
	while scroll != null and not scroll is ScrollContainer:
		scroll = scroll.get_parent()
	if scroll is ScrollContainer:
		(scroll as ScrollContainer).ensure_control_visible(control)
		await _pause(0.1)
	var point := control.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = pressed
		root.push_input(event, true)
	await _pause(0.35)


func _setup() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_set_phase", "puppy")
	state.call("_grant_upgrade", "stove")
	state.call("_mark_all_seen")
	state.call("dev_week_goto", 9)
	state.call("dev_content_day", 11)
	state.get("inventory").call("from_dict", {})
	state.call("dev_chef_points", 0)


func _dish(type: String, ingredients: Array, points: int, stars: int = 2) -> void:
	var key: String = state.call("dish_key", type, ingredients)
	state.get("week").dishes[key] = {"stars": stars, "made": maxi(1, points), "day": 3, "points": points}


func _fill() -> void:
	_dish("papinha", ["cenoura", "milho"], 8)
	_dish("papinha", ["batata", "batata"], 0, 1)
	_dish("papinha", ["abobora", "cenoura"], 16, 3)
	_dish("papinha", ["batata", "ovo"], 31, 3)
	_dish("sopinha", ["cenoura", "batata", "batata"], 3)
	_dish("petisco", ["maca", "aveia"], 1)
	var stock := {"carrot": 4, "potato": 2, "corn": 5, "egg": 2, "apple": 1, "pumpkin": 0, "oat": 3, "banana": 1}
	state.get("inventory").call("from_dict", stock)
	state.call("dev_chef_points", 62)


func _open_book() -> void:
	main.call("show_screen", &"pet")
	await _pause(0.2)
	(load("res://scripts/ui/pet_notebook.gd") as Script).call("open", "recipes")
	await _pause(0.6)
	_hide_modals()


func _close_book() -> void:
	root.get_node("Events").emit_signal("sheet_close_requested")
	await _pause(0.4)


func _rect_clipped(control: Control) -> Rect2:
	var rect := control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
	var parent := control.get_parent()
	while parent is Control and rect.has_area():
		if (parent as Control).clip_contents:
			rect = rect.intersection((parent as Control).get_global_transform_with_canvas() * Rect2(Vector2.ZERO, (parent as Control).size))
		parent = parent.get_parent()
	return rect


func _label_cut(label: Label) -> bool:
	if label.text == "":
		return false
	if label.max_lines_visible > 0:
		return label.get_line_count() > label.max_lines_visible
	if label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		var font := label.get_theme_font("font")
		var px := label.get_theme_font_size("font_size")
		return font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > label.size.x + 0.5
	return false


## Todo filho visível fica dentro do retângulo do seu cartão/aba/quadradinho (1 px de tolerância; cartões de prato
## com folga interna de 5 px) e nenhuma aba/ingrediente fica cortado pela área visível sem esmaecido.
func _contain(book: Control) -> void:
	var owners := ["BookDish_", "BookType_", "BookIngredient_", "BookPotItem_", "BookFilter_", "ChefCard", "BookSecret", "ChefSkill_", "BookNeed_"]
	var fade_on := false
	for fade: Node in book.find_children("Fade*", "TextureRect", true, false):
		if (fade as Control).is_visible_in_tree():
			fade_on = true
	for node: Node in book.find_children("*", "Control", true, false):
		var owner_control := node as Control
		if not owner_control.is_visible_in_tree():
			continue
		var matched := ""
		for prefix: String in owners:
			if str(owner_control.name).begins_with(prefix) and not (owner_control is Label):
				matched = prefix
				break
		if matched == "":
			continue
		var full := owner_control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, owner_control.size)
		var seen := _rect_clipped(owner_control)
		if matched in ["BookType_", "BookIngredient_"] and seen.has_area() and seen.get_area() < full.get_area() - 2.0 and not fade_on:
			_check(false, "%s cortado pela área visível sem esmaecido (%s de %s)" % [owner_control.name, seen, full])
		if seen.get_area() < full.get_area() - 2.0:
			continue  # rolando: o resto é conferido quando aparece inteiro
		var box := full.grow(-5.0) if matched == "BookDish_" else full
		for child: Node in owner_control.find_children("*", "Control", true, false):
			var control := child as Control
			if not control.is_visible_in_tree() or control.size.x <= 0.0 or control.size.y <= 0.0 or control is ScrollContainer:
				continue
			var rect := control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
			var tolerance := 1.0
			if rect.position.x < box.position.x - tolerance or rect.position.y < box.position.y - tolerance or rect.end.x > box.end.x + tolerance or rect.end.y > box.end.y + tolerance:
				_check(false, "%s: filho %s sai do quadrado (%s fora de %s)" % [owner_control.name, control.name, rect, box])


func _measure(label: String) -> void:
	current = label
	var screen := root.get_visible_rect().size
	var book := _node("RecipeBook")
	_check(book != null, "sem RecipeBook")
	if book == null:
		return
	_check(_node("ChefCard") != null and _node("BookIngredients") != null, "faltam cartão do cozinheiro ou barra de ingredientes")
	var interactive := ["BookDish_", "BookIngredient_", "BookType_", "BookFilter_", "ChefCard", "BookPotItem_", "BookNeed_", "BookSecret", "BookQueue",
		"BookFetch", "BookCookTogether", "BookInvent", "SecretSee_"]
	var greens := 0
	for node: Node in book.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree():
			continue
		var visible_rect := _rect_clipped(control)
		if not visible_rect.has_area():
			continue
		if control.has_meta("wood_primary"):
			greens += 1
		for prefix: String in interactive:
			if str(control.name).begins_with(prefix) and not (control is Label):
				if visible_rect.size.y >= control.size.y - 1.0:  # inteiro à vista: confere o alvo
					_check(control.size.y >= 43.5 and control.size.x >= 43.5, "alvo pequeno %s (%s)" % [control.name, control.size])
				_check(visible_rect.position.x >= -0.5 and visible_rect.end.x <= screen.x + 0.5 and visible_rect.position.y >= -0.5 and visible_rect.end.y <= screen.y + 0.5,
					"%s fora da tela %s" % [control.name, visible_rect])
				break
		if control is Label and _rect_clipped(control).size.y >= control.size.y - 1.0:
			_check(not _label_cut(control as Label), "texto cortado: '%s'" % (control as Label).text)
	_check(greens <= 1, "%d botões verdes" % greens)
	for row: Node in book.find_children("ChefSkill_*", "Control", true, false):
		_check((row as Control).size.y <= 110.0 and (row as Control).size.x >= 200.0, "linha do caminho torta %s %s" % [row.name, (row as Control).size])
	_contain(book)
	var rect := book.get_global_rect()
	_check(rect.position.x >= 0.0 and rect.end.x <= screen.x and rect.end.y <= screen.y, "livro fora da tela %s" % rect)
	var sheet := _node("BookDishSheet")
	if sheet == null:
		sheet = _node("ChefPath")
	if sheet == null:
		sheet = _node("BookSecretSheet")
	if sheet != null:
		var sr := sheet.get_global_rect()
		_check(sr.position.y >= book.get_global_rect().position.y - 0.5 and sr.end.y <= book.get_global_rect().end.y + 0.5, "painel de baixo fora do livro %s" % sr)
	print("  %s: livro %s, grade %s" % [label, book.size, _node("BookGridArea").size if _node("BookGridArea") else "-"])


func _shot(name_: String) -> void:
	_hide_modals()
	await _pause(0.2)
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "book_%dx%d_%s.png" % [image.get_width(), image.get_height(), name_])
	_measure(name_)


func _run() -> void:
	state = root.get_node("GameState")
	var saver := root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	(load("res://scripts/ui/motion.gd") as GDScript).set("reduced", true)
	_setup()
	main = load("res://scenes/main/main.tscn").instantiate() as Control
	root.add_child(main)
	await _pause(1.0)
	_hide_modals()
	# Chega só até o tutorial do livro: as outras lições ficam como feitas para não atrapalhar as capturas.
	for lesson: Dictionary in root.get_node("Database").get("week_tutorials"):
		var data: Dictionary = state.get("week").tutorial.get(lesson.id, {})
		data["done"] = true
		state.get("week").tutorial[lesson.id] = data
	var recipe_lesson: Dictionary = state.get("week").tutorial.get("recipe_book", {})
	state.get("week").tutorial["recipe_book"] = recipe_lesson
	await _open_book()
	await _shot("01_vazio")
	await _close_book()
	_fill()
	await _open_book()
	await _shot("02_livro")
	await _touch("BookIngredient_cenoura")
	await _shot("03_panela1")
	await _touch("BookIngredient_milho")
	await _shot("04_panela2")
	await _touch("BookPotItem_cenoura")
	await _touch("BookPotItem_milho")
	await _touch("BookFilter_can")
	await _shot("05_filtro_da_pra_fazer")
	await _touch("BookFilter_all")
	await _touch("BookDish_dish_papinha_cenoura+milho")
	await _shot("06_prato_da_pra_fazer")
	await _touch("BookNeed_cenoura")
	await _touch("BookIngredient_cenoura")  # tira da Panela
	await _touch("BookType_sopinha")
	await _touch("BookDish_dish_sopinha_cenoura+batata+batata")
	await _shot("07_sopinha_conhecida")
	state.get("inventory").call("from_dict", {"carrot": 4, "corn": 5})
	await _close_book()
	await _open_book()
	await _touch("BookType_papinha")
	await _touch("BookFilter_new")
	await _shot("08_nao_fiz")
	var mystery := ""
	for node: Node in _node("RecipeBook").find_children("BookDish_*", "Control", true, false):
		if not bool(node.get_meta("known", true)):
			mystery = str(node.name)
			break
	await _touch(mystery)
	await _shot("09_prato_misterio")
	await _close_book()
	state.call("dev_chef_points", 12)  # com o Faro de cozinha a pista mostra o primeiro ingrediente
	await _open_book()
	await _touch("BookFilter_new")
	await _shot("10_pista_faro")
	await _touch("BookSecret")
	await _shot("11_secretas")
	await _close_book()
	await _open_book()
	await _touch("ChefCard")
	await _shot("12_caminho_inicio")
	await _close_book()
	state.call("dev_chef_points", 100)
	await _open_book()
	await _touch("ChefCard")
	await _shot("13_caminho_meio")
	await _close_book()
	state.call("dev_chef_points", 200)
	await _open_book()
	await _touch("ChefCard")
	await _shot("14_caminho_completo")
	await _close_book()
	state.call("dev_chef_points", 100)
	await _pause(0.2)
	var celebration: Variant = main.get("_celebration")
	(celebration as Node).call("show_chef_level", 5)
	await _pause(0.9)
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	var image := root.get_texture().get_image()
	image.save_png(path + "book_%dx%d_15_comemoracao.png" % [image.get_width(), image.get_height()])
	current = "15_comemoracao"
	var card := main.find_child("CardPanel", true, false) as Control
	_check(card != null and card.get_global_rect().position.x >= 0.0 and card.get_global_rect().end.x <= root.get_visible_rect().size.x, "comemoração fora da tela")
	(celebration as Node).call("hide")
	# Tutorial: abre o livro com a lição ainda pendente.
	state.get("week").tutorial["recipe_book"] = {}
	state.call("dev_chef_points", 20)
	state.get("week").tutorial.erase("resume")
	await _open_book()
	await _pause(1.2)
	var guide := main.find_child("WeekTutorial", true, false)
	_check(guide != null, "sem guia de tutorial")
	for index in 4:
		await RenderingServer.frame_post_draw
		var tour := root.get_texture().get_image()
		tour.save_png(path + "book_%dx%d_16_tutorial_%d.png" % [tour.get_width(), tour.get_height(), index + 1])
		current = "16_tutorial_%d" % (index + 1)
		_check(guide != null and guide.get("active") == "recipe_book" and guide.get("step") == index, "passo %d do tutorial (ativo %s, passo %s)" % [index + 1, str(guide.get("active")) if guide else "-", str(guide.get("step")) if guide else "-"])
		var accept := main.find_child("TutorialAccept", true, false) as Control
		if accept != null and accept.is_visible_in_tree():
			var point := accept.get_global_rect().get_center()
			for pressed: bool in [true, false]:
				var event := InputEventScreenTouch.new()
				event.position = point
				event.pressed = pressed
				root.push_input(event, true)
		await _pause(0.7)
	print("RECIPE BOOK SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(int(failures > 0))
