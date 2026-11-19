class_name RecipeBookUi
extends RefCounted
## Páginas do Livro dentro do caderninho. A navegação fica no modelo da folha.

const PAPER := Color("fffaf0")
const LINE := Color("e5cda6")
const MUTED := Color("806345")

const TABS: Array[Dictionary] = [
	{"id": "stock", "text": "Com o que tenho"},
	{"id": "all", "text": "Todos"},
	{"id": "secrets", "text": "Segredos"},
]


static func body(model: Dictionary, refresh: Callable) -> Control:
	var box := UiKit.vbox(7)
	box.name = "RecipeBook"
	var page: Dictionary = model.get("recipe_page", {})
	if not page.is_empty():
		box.add_child(_back("Voltar às receitas", _page.bind(model, refresh, {})))
		if page.has("ingredient"):
			_ingredient(box, str(page.ingredient), model, refresh)
		elif page.has("pairs"):
			box.add_child(_heading(str(Database.week_routine.text.duples)))
			for pair: Dictionary in GameState.week_routine_pairs():
				var ingredients := "%s + %s" % [DishRules.ingredient(str(pair.a)).name, DishRules.ingredient(str(pair.b)).name]
				box.add_child(_panel(_text("%s · %s" % [pair.name, ingredients]), PAPER))
		elif page.has("secret"):
			for id: String in Database.recipe_book.secrets:
				if id == str(page.secret):
					_secret(box, GameState.recipe_secret(id), model, refresh)
		else:
			_recipe(box, str(page.key), model, refresh)
		return box
	var tab := str(model.get("recipe_tab", "stock"))
	var header := UiKit.hbox(6)
	header.add_child(_back("Caderninho", _back_to_notebook.bind(model, refresh)))
	var chef := GameState.chef_info()
	var summary := _text(str(chef.name) + " · %d pts" % chef.score, false, 12, MUTED)
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(summary)
	box.add_child(header)
	var tabs := UiKit.hbox(3)
	for option: Dictionary in TABS:
		var id := str(option.id)
		var button := _button(str(option.text), _tab.bind(model, refresh, id), null, id == tab)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.name = "BookTab_" + id
		if id == "stock":
			button.custom_minimum_size.x = 110
		tabs.add_child(button)
	box.add_child(_panel(tabs, Color("f1e1c7"), 4))
	var complete := GameState.week_routine_badge("complete_dish")
	if complete != "":
		box.add_child(_panel(_text(complete, true), PAPER))
	if GameState.week_routine_badge("pair") != "":
		box.add_child(_button(str(Database.week_routine.text.duples), _page.bind(model, refresh, {"pairs": true})))
	if tab == "secrets":
		for id: String in Database.recipe_book.secrets:
			_secret(box, GameState.recipe_secret(id), model, refresh)
		return box
	var selected: Array = model.get("recipe_selected", []) if tab == "stock" else []
	if tab == "stock":
		_stock(box, selected, model, refresh)
	var rows := GameState.recipe_book_rows(selected)
	var list_header := UiKit.hbox(6)
	list_header.add_child(_heading("Receitas" if selected.is_empty() else "Com os selecionados"))
	var count := _text("%d" % rows.size(), true, 14, MUTED)
	count.size_flags_horizontal = Control.SIZE_SHRINK_END
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	list_header.add_child(count)
	box.add_child(list_header)
	if rows.is_empty():
		box.add_child(_panel(_text("Nenhum prato com essa seleção." if not selected.is_empty() else "Faça um prato no fogão para começar."), PAPER, 12))
	for row: Dictionary in rows:
		_row(box, row, model, refresh)
	if tab == "stock":
		if not GameState.recipe_novelty(selected).is_empty():
			box.add_child(_button("Dá para inventar algo novo  ›", open_kitchen.bind("invent")))
		var daily := GameState.recipe_ingredient_day()
		if not daily.is_empty():
			box.add_child(_text("Ingrediente do dia · %s" % daily.name, false, 13, MUTED))
	return box


static func _back_to_notebook(model: Dictionary, refresh: Callable) -> void:
	model.section = "resources"
	model.scroll = 0
	refresh.call()


static func _back(title: String, action: Callable) -> Button:
	var button := _button(title, action, UiKit.ctl_icon("back"))
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.clip_text = false
	button.custom_minimum_size.x = 114 if title == "Caderninho" else 155
	button.add_theme_constant_override("icon_max_width", 15)
	return button


static func _panel(content: Control, color: Color = PAPER, padding: int = 8) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := UiKit.surface(color, 12)
	style.set_content_margin_all(padding)
	style.set_border_width_all(1)
	style.border_color = LINE
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(content)
	return panel


static func _tab(model: Dictionary, refresh: Callable, tab: String) -> void:
	model["recipe_tab"] = tab
	model["scroll"] = 0
	refresh.call()


static func _page(model: Dictionary, refresh: Callable, page: Dictionary) -> void:
	model["recipe_page"] = page
	model["scroll"] = 0
	refresh.call()


static func _heading(value: String) -> Label:
	return _text(value, true, 17)


static func _text(value: String, heading: bool = false, px: int = 14, tint: Color = Palette.WOOD_INK) -> Label:
	var label := UiKit.fill_label(value, &"StrongLabel" if heading else &"", tint)
	label.add_theme_font_size_override("font_size", px)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func _stock(box: VBoxContainer, selected: Array, model: Dictionary, refresh: Callable) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 6)
	var ingredients := DishRules.order().duplicate()
	ingredients.sort_custom(func(a: String, b: String) -> bool:
		return int(GameState.recipe_ingredient_stock(a) > 0) > int(GameState.recipe_ingredient_stock(b) > 0))
	var all := bool(model.get("recipe_show_stock", false))
	var header := UiKit.hbox(4)
	var title := _heading("Minha mochila")
	title.add_theme_font_size_override("font_size", 14)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	var more := _button("Menos" if all else "Ver %d" % ingredients.size(), func() -> void:
		model["recipe_show_stock"] = not all
		refresh.call())
	more.custom_minimum_size.x = 54
	more.name = "BookExpandStock"
	header.add_child(more)
	if not selected.is_empty():
		var reset := _button("Limpar", func() -> void:
			model["recipe_selected"] = []
			refresh.call())
		reset.custom_minimum_size.x = 54
		header.add_child(reset)
	box.add_child(header)
	box.add_child(grid)
	for id: String in ingredients if all else ingredients.slice(0, 8):
		var def := DishRules.ingredient(id)
		var n := GameState.recipe_ingredient_stock(id)
		var tile := UiKit.vbox(0)
		var pick := _button("", func() -> void:
			var next := selected.duplicate()
			if id in next:
				next.erase(id)
			else:
				next.append(id)
			model["recipe_selected"] = next
			refresh.call(), Database.item_icon(DishRules.main_item(id)), id in selected)
		pick.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pick.add_theme_constant_override("icon_max_width", 31)
		var count := _text("×%d" % n, true, 12, MUTED)
		count.add_theme_font_size_override("font_size", 11)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pick.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		count.offset_right = -4
		count.offset_bottom = -2
		pick.name = "BookStock_" + id
		pick.modulate.a = 0.6 if n == 0 and id not in selected else 1.0
		tile.add_child(pick)
		var detail := _button(str(def.name), _page.bind(model, refresh, {"ingredient": id}), null)
		detail.name = "BookIngredient_" + id
		detail.add_theme_font_size_override("font_size", 11)
		detail.custom_minimum_size.y = 34
		for style: String in ["normal", "hover", "pressed", "focus"]:
			detail.add_theme_stylebox_override(style, StyleBoxEmpty.new())
		tile.add_child(detail)
		var shell := _panel(tile, Color("f9edda") if id in selected else PAPER, 0)
		shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(shell)


static func _button(text: String, action: Callable, icon: Texture2D = null, selected: bool = false) -> Button:
	var button := UiKit.soft(text, action, icon, true)
	button.clip_text = true
	button.tooltip_text = text
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Palette.WOOD_INK)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 26)
	var style := UiKit.surface(Color("ffe5b4") if selected else Color("f6ebd8"), 9)
	style.set_border_width_all(1)
	style.border_color = Palette.HONEY_EDGE if selected else LINE
	button.add_theme_stylebox_override("normal", style)
	var focus := style.duplicate() as StyleBoxFlat
	focus.bg_color = Color("ffedca")
	for name: String in ["hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(name, focus)
	return button


static func _row(box: VBoxContainer, row: Dictionary, model: Dictionary, refresh: Callable) -> void:
	var content := UiKit.hbox(9)
	content.add_child(UiKit.disc(Database.item_icon(str(row.item)), 40, 34))
	var text := UiKit.vbox(1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(_text(str(row.name), true, 15))
	var stars := " · " + "★".repeat(int(row.stars)) if int(row.stars) > 0 else ""
	text.add_child(_text(_state_label(str(row.state)) + stars, false, 12, MUTED))
	content.add_child(text)
	var status := _text("Tem tudo" if int(row.missing) == 0 else "Faltam %d" % int(row.missing),
		true, 12, Palette.GO_INK if int(row.missing) == 0 else Palette.HONEY_INK)
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.size_flags_horizontal = Control.SIZE_SHRINK_END
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(status)
	var panel := _panel(content)
	var target := BagUi.plain_button(_page.bind(model, refresh, {"key": row.key}))
	target.name = "BookDish_" + str(row.key).replace(":", "_")
	panel.add_child(target)
	for child: Node in panel.find_children("*", "Control", true, false):
		if child != target:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(panel)


static func _state_label(state: String) -> String:
	match state:
		"pista": return "Pista"
		"descoberta": return "Descoberta"
		"provada": return "Provada"
		"dominada": return "Dominada"
	return "Desconhecida"


static func _hero(texture: Texture2D, title: String, note: String) -> Control:
	var row := UiKit.hbox(11)
	row.add_child(UiKit.disc(texture, 60, 48))
	var text := UiKit.vbox(3)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_child(_text(title, true, 21))
	text.add_child(_text(note, false, 13, MUTED))
	row.add_child(text)
	return _panel(row, PAPER, 9)


static func _nutrients(values: Dictionary) -> Control:
	var row := UiKit.hbox(5)
	for id: String in DishRules.nutrient_ids():
		var stat := UiKit.vbox(0)
		var value := _text(str(int(values.get(id, 0))), true, 17)
		var label := _text(str(Database.dishes.nutrients[id].name), false, 12, MUTED)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat.add_child(value)
		stat.add_child(label)
		var tile := _panel(stat, Color("f9edda"), 4)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(tile)
	return row


static func _taste(id: String) -> String:
	return str(Database.dishes.tastes.get(id, id))


static func _ingredient(box: VBoxContainer, id: String, model: Dictionary, refresh: Callable) -> void:
	box.name = "RecipeIngredientPage"
	var def := DishRules.ingredient(id)
	var origin: Dictionary = Database.recipe_book.ingredients.get(id, {})
	box.add_child(_hero(Database.item_icon(DishRules.main_item(id)), str(def.name),
		"%s · %s · %d na Mochila" % [Database.dishes.categories[def.category], _taste(str(def.taste)), GameState.recipe_ingredient_stock(id)]))
	box.add_child(_nutrients(def.n))
	if not origin.is_empty():
		box.add_child(_button(str(origin.label) + "  ›", Places.go.bind(origin.go)))
	var suggestions := GameState.recipe_novelty([id])
	if not suggestions.is_empty():
		var names := PackedStringArray()
		for ingredient: String in suggestions[0].ingredients:
			names.append(str(DishRules.ingredient(ingredient).name))
		box.add_child(_button("Experimentar · " + " + ".join(names), open_kitchen.bind("invent")))
	var rows := GameState.recipe_book_rows([id])
	box.add_child(_heading("Pratos com %s" % str(def.name).to_lower()))
	for row: Dictionary in rows:
		_row(box, row, model, refresh)
	box.add_child(_text("%d no Livro · %d por descobrir" % [rows.size(), GameState.recipe_undiscovered_count(id)], false, 13, MUTED))
	for secret_id: String in Database.recipe_book.secrets:
		var secret := GameState.recipe_secret(secret_id)
		if secret.state == "pista" and id in secret.revealed:
			box.add_child(_button("Pista de receita secreta  ›", _page.bind(model, refresh, {"secret": secret_id}), null))
	box.add_child(_heading("Duplas"))
	for pair: Dictionary in Database.dishes.duples:
		if id not in [pair.a, pair.b]:
			continue
		var other := str(pair.b if pair.a == id else pair.a)
		var label := str(DishRules.ingredient(other).name) if GameState.recipe_ingredient_stock(other) > 0 else "?"
		box.add_child(_text("%s · %s" % [pair.name, label]))


static func _recipe(box: VBoxContainer, key: String, model: Dictionary, refresh: Callable) -> void:
	box.name = "RecipeDetailPage"
	for row: Dictionary in GameState.recipe_book_rows():
		if str(row.key) == key:
			_recipe_details(box, row, model, refresh)
			return


static func _recipe_details(box: VBoxContainer, row: Dictionary, model: Dictionary, refresh: Callable) -> void:
	var key := str(row.key)
	var record := GameState.dish_record(key)
	var mastery := GameState.recipe_mastery(key)
	var quality := "★".repeat(int(row.stars)) if int(row.stars) > 0 else "Sem estrelas"
	box.add_child(_hero(Database.item_icon(str(row.item)), str(row.name),
		"%s · %s · %s" % [_state_label(str(row.state)), quality, _taste(DishRules.taste(row.ingredients))]))
	box.add_child(_nutrients(DishRules.nutrients(str(row.type), row.ingredients, maxi(1, int(row.stars)), GameState.growth.phase)))
	var tasted := str(GameState.week.recipe_book.get("tasted", {}).get(GameState._book_taste_key(key), ""))
	if tasted != "":
		box.add_child(_text(GameState.taste_line(tasted)))
	box.add_child(_heading("Ingredientes"))
	var ingredients := GridContainer.new()
	ingredients.columns = 2
	ingredients.add_theme_constant_override("h_separation", 5)
	box.add_child(ingredients)
	for ingredient: String in DishRules.canon(row.ingredients):
		if row.ingredients.find(ingredient) != row.ingredients.rfind(ingredient) and ingredients.has_node("Need_" + ingredient):
			continue
		var stock := GameState.recipe_ingredient_stock(ingredient)
		var need: int = row.ingredients.count(ingredient)
		var chip := _button("%s · %s" % [DishRules.ingredient(ingredient).name, "Tem %d" % stock if stock >= need else "Faltam %d" % (need - stock)],
			_page.bind(model, refresh, {"ingredient": ingredient}), Database.item_icon(DishRules.main_item(ingredient)))
		chip.name = "Need_" + ingredient
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ingredients.add_child(chip)
	var progress := UiKit.vbox(4)
	var points := "%d/%d" % [mastery.score, mastery.next] if int(mastery.next) > 0 else "%d" % int(mastery.score)
	progress.add_child(_text("%s · %s pts · %d preparos" % [mastery.name, points, int(record.get("made", 0))], true))
	if int(mastery.next) > 0:
		progress.add_child(UiKit.bar(100.0 * float(mastery.score) / float(mastery.next), Palette.HONEY))
	if int(mastery.until_gift) > 0:
		progress.add_child(_text("Próxima porção de brinde em %d preparos" % int(mastery.until_gift), false, 12, MUTED))
	box.add_child(_panel(progress, PAPER, 7))
	var book_key := GameState._book_taste_key(key).trim_prefix("dish:")
	var alternate := str(Database.recipe_book.caprichada.get(book_key, ""))
	if alternate != "":
		var variant := GameState._named_book_recipe(alternate)
		var variant_key := GameState.dish_key(str(variant.type), variant.ingredients)
		if GameState.dish_known(str(variant.type), variant.ingredients):
			box.add_child(_button("Versão caprichada  ›", _page.bind(model, refresh, {"key": variant_key})))
		else:
			box.add_child(_text("Versão caprichada · experimente com um grão."))
	var source := "Páginas reunidas" if str(record.get("source", "")) == "pieces" else "Inventar"
	if key.begins_with("recipe:"):
		source = "Receitas do fogão"
	box.add_child(_text("Origem · %s%s" % [source, " · dia %d" % int(record.day) if record.has("day") else ""]))
	var together := UiKit.primary("Cozinhar junto", open_kitchen.bind("together:" + key))
	together.name = "BookCookTogether"
	together.clip_text = true
	together.add_theme_font_size_override("font_size", 14)
	var actions := UiKit.hbox(6)
	actions.add_child(together)
	together.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var queue := _button("Colocar na fila", func() -> void:
		var recipe := str(row.get("recipe", ""))
		var error := GameState.cook_known_dish(key) if recipe == "" else GameState.cook(recipe)
		Events.toast_requested.emit("Prato na fila!" if error == "" else error))
	queue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(queue)
	box.add_child(actions)


static func _secret(box: VBoxContainer, secret: Dictionary, model: Dictionary, refresh: Callable) -> void:
	var card := UiKit.vbox(4)
	var panel := _panel(card, PAPER, 9)
	panel.name = "BookSecret_" + str(secret.id)
	box.add_child(panel)
	var header := UiKit.hbox(6)
	header.add_child(_heading(str(secret.name)))
	var pieces: Array = secret.pieces
	var total := (Database.recipe_book.secrets[str(secret.id)].pieces as Array).size()
	for i in total:
		var piece := UiKit.icon(UiKit.ui_icon("item_map_piece"), 18)
		piece.modulate.a = 1.0 if i in pieces else 0.24
		header.add_child(piece)
	card.add_child(header)
	card.add_child(_text("%d/%d páginas · %s" % [pieces.size(), total, _state_label(str(secret.state))], false, 12, MUTED))

	if secret.state not in ["pista", "desconhecida"]:
		card.add_child(_button("Ver receita", _page.bind(model, refresh, {"key": secret.key}), null))
	if not secret.revealed.is_empty() and secret.state in ["pista", "desconhecida"]:
		var names: Array[String] = []
		for id: String in secret.revealed:
			names.append(str(DishRules.ingredient(id).name))
		card.add_child(_text("Ingredientes da pista · " + ", ".join(names)))
	var hint: Dictionary = secret.hint
	if bool(secret.hinted):
		card.add_child(_text("“%s”" % hint.text))
	elif secret.state in ["pista", "desconhecida"]:
		card.add_child(_destination(str(hint.label), hint.go))
	var next: Dictionary = secret.next
	if not next.is_empty():
		card.add_child(_text("Próxima página · faltam %d" % int(next.left), false, 12, MUTED))
		card.add_child(_destination(str(next.label), next.go))


static func _destination(title: String, target: Dictionary) -> Control:
	var row := UiKit.hbox(8)
	var label := _text(title, false, 13)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	row.add_child(_button("Ir", Places.go.bind(target)))
	return row


static func open_kitchen(focus: String) -> void:
	Places.go({"world": "house", "place": "cookbook:" + focus})
