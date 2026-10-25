extends SceneTree
## Etapa 01 da interface nova: tema (cartão sem degrau), peças do UiKit, um botão principal por painel
## e cadeado no lugar do botão cinza quando falta um requisito.
## As classes de interface usam o autoload Database: por isso são carregadas só em tempo de execução.

var failures: int = 0
var state: Node
var db: Node
var ui_kit: GDScript
var sheet_builder: GDScript
var progression_ui: GDScript
var nature_ui: GDScript


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("UI style: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	ui_kit = load("res://scripts/ui/ui_kit.gd")
	sheet_builder = load("res://scripts/ui/sheet_builder.gd")
	progression_ui = load("res://scripts/ui/progression_ui.gd")
	nature_ui = load("res://scripts/ui/nature_ui.gd")
	state.call("reset")
	_theme()
	_kit()
	await _lock_cards()
	state.call("dev_unlock_everything")
	state.call("dev_add_items", 20)
	state.call("dev_add_coins", 5000)
	await _primary_per_panel()
	print("UI_STYLE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


## Botões principais visíveis e habilitados, recursivo.
func count_primary(node: Node) -> int:
	var total := 0
	if node is Button and (node as Button).theme_type_variation == &"PrimaryButton" and not (node as Button).disabled \
			and (node as Control).is_visible_in_tree():
		total += 1
	for child: Node in node.get_children():
		total += count_primary(child)
	return total


func _theme() -> void:
	var theme: Theme = load("res://assets/theme/main_theme.tres")
	var card := theme.get_stylebox("panel", "CardPanel") as StyleBoxFlat
	check(card.border_width_bottom == 0, "Cartão liso sem borda")
	check(_near(card.bg_color, Palette.CARD), "Cartão usa CARD / CARD_LINE")
	var button := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	check(button.border_width_bottom == 0, "Botão calmo sem degrau")
	check(_near(button.bg_color, Palette.SUNKEN), "Botão comum é afundado")
	var pressed := theme.get_stylebox("pressed", "Button") as StyleBoxFlat
	check(pressed.border_width_bottom == 0, "Botão calmo pressionado sem borda")
	var primary := theme.get_stylebox("normal", "PrimaryButton") as StyleBoxFlat
	check(_near(primary.bg_color, Palette.GO) and _near(primary.border_color, Palette.GO_EDGE), "PrimaryButton é verde")
	var types := theme.get_type_list()
	for type_name: String in ["SecondaryButton", "GhostButton", "IconButton", "PillPanel", "NumberLabel", "BadgeLabel"]:
		check(types.has(type_name), "Tema tem a variação " + type_name)
	var chip := theme.get_stylebox("panel", "ChipPanel") as StyleBoxFlat
	check(chip.border_width_left == 0 and chip.corner_radius_top_left == 14, "Chip é pílula sem borda")
	check(theme.get_font_size("font_size", "TitleLabel") == 24 and theme.get_font_size("font_size", "SmallLabel") == 12, "Tipografia: título 24, pequeno 12")
	var sheet := theme.get_stylebox("panel", "SheetPanel") as StyleBoxFlat
	check(sheet.border_width_left == 0 and sheet.corner_radius_top_left == 28, "Painel sem borda, cantos de cima 28")


func _kit() -> void:
	var owned: Array[Node] = []
	var noop := func() -> void: pass
	check((_own(owned, ui_kit.call("primary", "a", noop)) as Button).theme_type_variation == &"PrimaryButton", "UiKit.primary")
	check((_own(owned, ui_kit.call("secondary", "a", noop)) as Button).theme_type_variation == &"SecondaryButton", "UiKit.secondary")
	check((_own(owned, ui_kit.call("secondary", "a", noop, null, true)) as Button).custom_minimum_size.y == 44, "secondary pequeno tem altura 44")
	check((_own(owned, ui_kit.call("ghost", "a", noop)) as Button).theme_type_variation == &"GhostButton", "UiKit.ghost")
	var help: Button = ui_kit.call("square_button", "?", noop)
	check(help.theme_type_variation == &"IconButton" and help.text == "" and help.icon == ui_kit.call("ctl_icon", "help"), "square_button devolve um icon_button com ajuda vetorial")
	check((_own(owned, ui_kit.call("icon_button", null, noop, 44, "?")) as Button).custom_minimum_size == Vector2(44, 44), "icon_button 44")
	var pill: PanelContainer = ui_kit.call("pill", null, "12")
	check(pill.theme_type_variation == &"PillPanel", "UiKit.pill")
	var lock_texture: Texture2D = ui_kit.call("ctl_icon", "lock")
	var hint: HBoxContainer = ui_kit.call("lock_hint", "Depois do fogão", noop)
	var has_lock := false
	for child: Node in hint.get_children():
		if child is TextureRect and (child as TextureRect).texture == lock_texture:
			has_lock = true
	check(has_lock and lock_texture != null, "lock_hint contém o cadeado ui_lock")
	check(hint.get_child_count() == 3, "lock_hint com ajuda: cadeado + texto + '?'")
	var plain: HBoxContainer = ui_kit.call("lock_hint", "x")
	check(plain.get_child_count() == 2, "lock_hint sem ajuda: cadeado + texto")
	check(ui_kit.call("ctl_icon", "x") != null and ui_kit.call("ctl_icon", "check") != null, "ícones vetoriais x e check existem")
	for node: Node in owned:
		node.free()
	help.free()
	pill.free()
	hint.free()
	plain.free()


## Num jogo novo, uma construção com requisito não cumprido mostra cadeado e nenhum botão habilitado.
func _lock_cards() -> void:
	var found := ""
	var upgrades: Dictionary = db.get("progression").upgrades
	for id: String in upgrades:
		var data: Dictionary = upgrades[id]
		if data.has("nature_unlock") or data.get("requirements", {}).is_empty():
			continue
		if state.call("requirement_error", data.requirements) != "":
			found = id
			break
	check(found != "", "existe construção com requisito aberto num jogo novo")
	if found == "":
		return
	var live_box: GDScript = sheet_builder.get_script_constant_map()["LiveBox"]
	var box: Control = live_box.new(func(inner: VBoxContainer) -> void: progression_ui.call("upgrade_card", inner, found))
	root.add_child(box)
	await process_frame
	check(box.find_child("LockHint", true, false) != null, "Construção bloqueada por requisito mostra cadeado")
	check(count_primary(box) == 0, "Construção bloqueada não tem botão verde")
	var any_buy := false
	for node: Node in box.find_children("*", "Button", true, false):
		if (node as Button).text == "Comprar":
			any_buy = true
	check(not any_buy, "Construção bloqueada não tem botão Comprar")
	box.queue_free()
	await process_frame


func _primary_per_panel() -> void:
	var panels := {
		"fogão": sheet_builder.call("station_view", "stove"),
		"sementes": sheet_builder.call("seed_picker", 3),
		"comida": sheet_builder.call("food_picker"),
		"natureza": nature_ui.call("panel", "trees"),
		"coleção": progression_ui.call("collection_panel"),
		"vender": progression_ui.call("sell_panel"),
		"encomendas": progression_ui.call("orders_panel"),
		"rotas": progression_ui.call("routes_panel", "walk"),
	}
	for panel_name: String in panels:
		var panel: Control = panels[panel_name]
		root.add_child(panel)
		await process_frame
		await process_frame
		var total := count_primary(panel)
		check(total <= 1, "Painel %s tem no máximo um botão principal (tem %d)" % [panel_name, total])
		check(panel.find_children("*", "Button", true, false).size() > 0, "Painel %s tem botões" % panel_name)
		panel.queue_free()
		await process_frame


## O .tres guarda a cor em decimais (3 casas); a Palette vem do hexadecimal: compara com folga.
func _near(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01


func _own(nodes: Array[Node], node: Node) -> Node:
	nodes.append(node)
	return node
