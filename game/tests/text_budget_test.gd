extends SceneTree
## Interface 2, etapa 11: orçamento de texto (04 §C) e "Texto maior".
## Monta as telas principais de verdade (main.tscn) e conta as palavras visíveis de Label/Button que não
## são nome de item/lugar/personagem/missão, fala de personagem nem número. Com "Texto maior" ligado,
## confere que nenhum Label de uma linha passa da largura do pai.
## --headless --path game -s res://tests/text_budget_test.gd [-- --measure]

const BUDGET := {
	"tiro": 6,
	"missoes_historia": 8,
	"missoes_pessoas": 6,
	"missoes_diarias": 9,  # + bandeja Principal e cabeçalhos "Hoje"/"Esta semana" em pílulas
	"mochila": 6,
	"fogao": 4,
	"horta": 4,
	"folha_premio": 17,
}

var failures := 0
var state: Node
var main: Control
var names := {}
var speech := {}
var measure := "--measure" in OS.get_cmdline_user_args()


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("TEXT BUDGET: " + message)


func frames(n: int = 6) -> void:
	for i in n:
		await process_frame


## Junta nomes (name/label/map_name) e falas (dialogue/greeting/introduction/text/postcard) dos dados.
func _collect(node: Variant, key: String) -> void:
	if node is String:
		var low := (node as String).strip_edges().to_lower()
		if key in ["name", "label", "map_name", "in_name", "action_label"]:
			names[low] = true
		elif key in ["dialogue", "greeting", "introduction", "text", "postcard", "request", "complete"]:
			speech[low] = true
	elif node is Dictionary:
		for k: Variant in node:
			_collect(node[k], str(k))
	elif node is Array:
		for x: Variant in node:
			_collect(x, key)


func _is_name(text: String) -> bool:
	var low := text.strip_edges().to_lower()
	return names.has(low) or speech.has(low)


## Palavras de um texto visível: cada token com letra; "+3", "12/20", "×2" não contam.
func words_of(text: String) -> Array[String]:
	var out: Array[String] = []
	if text.strip_edges() == "" or _is_name(text):
		return out
	for token: String in text.replace("\n", " ").split(" ", false):
		var has_letter := false
		for i in token.length():
			if token.unicode_at(i) > 64 and token.to_upper() != token.to_lower():
				has_letter = true
				break
		if token in ["min", "h", "s", "d"]:
			continue  # unidade de tempo depois de número ("5 min")
		if has_letter and not names.has(token.to_lower().trim_suffix(",").trim_suffix(".")):
			out.append(token)
	return out


func visible_texts(root_node: Node, rect: Rect2 = Rect2()) -> Array[String]:
	var found: Array[String] = []
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
			continue
		if node is Label or node is Button:
			var text: String = (node as Label).text if node is Label else (node as Button).text
			var control := node as Control
			if text != "" and control.size.x > 1 and (rect.size == Vector2.ZERO or rect.intersects(control.get_global_rect())):
				found.append(text)
		for child: Node in node.get_children():
			stack.append(child)
	return found


func count(label: String, root_node: Node, rect: Rect2 = Rect2()) -> void:
	var total := 0
	var detail: Array[String] = []
	for text: String in visible_texts(root_node, rect):
		var words := words_of(text)
		total += words.size()
		if not words.is_empty():
			detail.append("%s [%d]" % [text.replace("\n", " "), words.size()])
	if measure:
		print("MEDIDA %s = %d  %s" % [label, total, " | ".join(detail)])
	check(total <= int(BUDGET[label]), "%s: %d palavras (máximo %d): %s" % [label, total, BUDGET[label], " | ".join(detail)])


func _run() -> void:
	_font_overrides("res://")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)  # fica de fora (sem gravar); volta só para abrir as Configurações
	state = root.get_node("GameState")
	var db: Node = root.get_node("Database")
	for field: String in ["items", "recipes", "stations", "animals", "crops", "npcs", "worlds", "quests", "collections", "progression", "projects", "growth", "walks", "friends", "routines", "wishes", "config"]:
		var value: Variant = db.get(field)
		if value != null:
			_collect(value, field)
	Motion.reduced = true
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("inventory").call("from_dict", {"carrot": 9, "carrot_snack": 4, "dog_food": 6, "wood": 6, "plank": 2, "stick": 3, "egg": 5, "milk": 2})
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(10)
	_hide_modals()
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)

	main.call("show_screen", &"pet")
	await frames()
	count("tiro", main.find_child("PetScreen", true, false), screen)

	main.call("show_screen", &"tasks")
	var tasks: Node = main.find_child("TasksScreen", true, false)
	for pair: Array in [["story", "missoes_historia"], ["characters", "missoes_pessoas"], ["timed", "missoes_diarias"]]:
		tasks.call("choose_group", pair[0])
		await frames()
		count(pair[1], tasks, screen)

	main.call("show_screen", &"bag")
	await frames()
	count("mochila", main.find_child("BagScreen", true, false), screen)

	main.call("show_screen", &"map")
	main.call("_on_world_requested", "house", "")
	await frames(40)
	_hide_modals()
	var house: Node = main.find_child("World_house", true, false)
	house.call("_on_object_tapped", "place:stove", house.find_child("stove", true, false))
	await frames()
	count("fogao", house.find_child("ActionTray", true, false), screen)
	house.call("close_tray")

	main.call("_on_world_requested", "farm", "")
	await frames(40)
	_hide_modals()
	var farm: Node = main.find_child("World_farm", true, false)
	farm.call("open_plot_tray", 0)
	await frames()
	count("horta", main.find_child("FarmDock", true, false), screen)
	farm.call("close_tray")

	main.get("_quest_reward").call("open", "welcome", "lais_feed")
	await frames(20)
	count("folha_premio", main.get("_quest_reward"))
	_hide_modals()

	# Texto maior: nenhum Label de uma linha passa da largura do pai.
	var photo := load("res://scripts/ui/photo_card.gd").call("make", "h_arrival", 264.0, {"caption": true}) as Control
	photo.theme = load("res://assets/theme/main_theme.tres")
	root.add_child(photo)
	var photo_title := photo.find_child("PhotoTitle", true, false) as Label
	check(photo_title != null and not photo_title.has_theme_font_size_override("font_size"), "polaroide usa fonte do tema, sem override local")
	LargeText.apply(true)
	check(LargeText.is_on(), "Texto maior liga")
	var scaled_theme := load("res://assets/theme/main_theme.tres") as Theme
	for pair: Array in [["PhotoRibbonLabel", 12], ["PhotoCaptionLabel", 13], ["PhotoDateLabel", 12], ["WorldBadgeLabel", 28], ["FloatLabel", 22]]:
		check(scaled_theme.get_font_size("font_size", pair[0]) == roundi(int(pair[1]) * LargeText.SCALE), str(pair[0]) + " acompanha Texto maior")
	await frames(10)
	check(photo_title.get_theme_font_size("font_size") == roundi(13 * LargeText.SCALE), "polaroide já montada acompanha Texto maior")
	photo.free()
	for screen_id: StringName in [&"pet", &"tasks", &"bag"]:
		main.call("show_screen", screen_id)
		await frames(6)
		_overflow(String(screen_id), main.find_child({&"pet": "PetScreen", &"tasks": "TasksScreen", &"bag": "BagScreen"}[screen_id], true, false))
	# Etapa 02 dos ajustes: perfil e moedas sem interseção e Configurações com margem de 16 px, sem rolagem lateral.
	main.call("show_screen", &"pet")
	state.set("coins", 2645)
	state.call("_changed")
	await frames(8)
	var profile := main.find_child("HudProfile", true, false) as Control
	var pill := main.find_child("CoinsPill", true, false) as Control
	check(not profile.get_global_rect().intersects(pill.get_global_rect()), "Texto maior: perfil %s e moedas %s não se sobrepõem" % [profile.get_global_rect(), pill.get_global_rect()])
	root.add_child(saver)
	load("res://scripts/ui/settings_panel.gd").call("open")
	await frames(30)
	var sheet_scroll := main.get_node("Sheet/%ContentHolder").get_parent() as ScrollContainer
	var sheet_title := main.get_node("Sheet/%Title") as Control
	check(sheet_title.get_global_rect().position.x >= 15.0, "Texto maior: título de Configurações com margem >= 16 (x = %d)" % sheet_title.get_global_rect().position.x)
	check(sheet_scroll.get_h_scroll_bar().max_value <= sheet_scroll.size.x + 1.0 and sheet_scroll.get_global_rect().end.x <= root.get_visible_rect().size.x - 15.0, "Texto maior: Configurações sem rolagem lateral e com margem direita")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await frames(6)
	root.remove_child(saver)
	LargeText.apply(false)
	var theme: Theme = load("res://assets/theme/main_theme.tres")
	check(theme.get_font_size("font_size", "TitleLabel") == 24 and theme.get_font_size("font_size", "SmallLabel") == 12, "Texto maior desligado volta aos tamanhos originais")
	LargeText.apply(true)
	LargeText.apply(true)
	check(theme.get_font_size("font_size", "TitleLabel") == roundi(24 * 1.15), "ligar duas vezes não acumula")
	LargeText.apply(false)

	Motion.reduced = false
	main.queue_free()
	await frames()
	if is_instance_valid(saver) and not saver.is_inside_tree():
		saver.free()
	print("TEXT BUDGET TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


## Lista branca: só main._warm_glyphs, que copia tamanhos >=12 do tema para aquecer glifos.
## Polaroides são texto do mundo (PhotoCard._finish): escala geométrica da foto, fonte sempre do tema;
## não precisam de override e acompanham LargeText inclusive depois de já montadas.
func _font_overrides(path: String) -> void:
	for file: String in DirAccess.get_files_at(path):
		if not file.ends_with(".gd"): continue
		var full := path.path_join(file)
		var source := FileAccess.get_file_as_string(full)
		if not source.contains("add_theme_font_size_override"): continue
		check(full == "res://scenes/main/main.gd", "override de fonte fora da lista branca: " + full)
	for folder: String in DirAccess.get_directories_at(path):
		if folder.begins_with(".") or folder == "tests": continue
		_font_overrides(path.path_join(folder))
	if path == "res://":
		var theme := load("res://assets/theme/main_theme.tres") as Theme
		check(theme.default_font_size >= 12, "fonte padrão >=12")
		for type_name: String in theme.get_font_size_type_list():
			for item: String in theme.get_font_size_list(type_name):
				check(theme.get_font_size(item, type_name) >= 12, "fonte do tema >=12: " + type_name)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])


## Label de uma linha (sem quebra) mais largo que o pai visível: corta.
func _overflow(label: String, screen_root: Node) -> void:
	if screen_root == null:
		check(false, "tela %s não encontrada" % label)
		return
	for node: Node in screen_root.find_children("*", "Label", true, false):
		var item := node as Label
		if not item.is_visible_in_tree() or item.autowrap_mode != TextServer.AUTOWRAP_OFF or item.text == "":
			continue
		var parent := item.get_parent() as Control
		if parent == null or item.clip_text:
			continue
		var edge := item.get_global_rect().end.x
		check(edge <= root.get_visible_rect().size.x + 1.0, "%s: '%s' termina em %d, além da tela" % [label, item.text, edge])
		check(item.get_minimum_size().x <= parent.size.x + 1.0 or item.size.x >= item.get_minimum_size().x - 1.0, "%s: '%s' (%d px) passa do pai (%d px)" % [label, item.text, item.get_minimum_size().x, parent.size.x])
