extends SceneTree
## Etapa 08: bandeja nas estações, criações e Natureza (modo "pick" da ActionTray).
## Usa a Casa, o Sítio, a Natureza e a Praça de verdade (main.tscn), sem SaveManager.
## --headless --path game -s res://tests/station_tray_test.gd

var failures := 0
var state: Node
var events: Node
var main: Control
var tray_script: Script
var places: Script
var toasts: Array[String] = []
var sheet_titles: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("STATION TRAY: " + message)


## Bandeja aberta agora (null se não há ou se está fechando).
func tray() -> Control:
	var current: Variant = tray_script.get("current")
	if current is Control and is_instance_valid(current) and not bool((current as Control).get("closing")):
		return current as Control
	return null


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func enter(world: String) -> Control:
	main.call("_on_world_requested", world, "")
	main.call("show_screen", &"map")
	await frames(4)
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var room: Control = main.find_child("World_" + world, true, false)
	room.call("_animate_objects")
	return room


## Toca no sprite do objeto como o jogador faria e espera a bandeja ganhar layout.
func tap(room: Control, action: String, object_id: String) -> Control:
	room.call("close_tray")
	room.call("_on_object_tapped", action, room.find_child(object_id, true, false))
	await frames()
	return tray()


func buttons(node: Node, found: Array[Button] = []) -> Array[Button]:
	if node is Button:
		found.append(node as Button)
	for child in node.get_children():
		buttons(child, found)
	return found


func primaries(current: Control) -> int:
	var count := 0
	for button in buttons(current):
		if button.theme_type_variation == &"PrimaryButton":
			count += 1
	return count


func press(current: Control, node_name: String) -> Button:
	var button := current.call("find_in_panel", node_name) as Button
	check(button != null, "botão %s existe" % node_name)
	if button:
		button.pressed.emit()
	return button


func reset_world_state() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	state.set("animals", {})


func add(item: String, amount: int) -> void:
	state.get("inventory").call("add", item, amount)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	tray_script = load("res://scripts/ui/action_tray.gd")
	places = load("res://scripts/ui/places.gd")
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	events.sheet_requested.connect(func(title: String, _content: Control) -> void: sheet_titles.append(title))
	reset_world_state()
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(4)

	await _test_stove_cooks()
	await _test_full_queue()
	await _test_missing_ingredients()
	await _test_collect_without_opening()
	await _test_blender_and_focus()
	await _test_see_all()
	await _test_coop()
	await _test_animal_spaces()
	await _test_nature()
	await _test_sewing()
	await _test_outside_closes()

	print("STATION TRAY TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


## Compra durante produção: cada animal tem seu espaço e o rodapé abre a loja diretamente.
func _test_animal_spaces() -> void:
	reset_world_state()
	state.set("animals", {"chicken_brown": 1})
	add("corn", 20)
	check(state.call("cook", "eggs") == "", "alimenta a galinha ruiva")
	check(state.call("buy_animal", "chicken_white") == "" and state.call("buy_animal", "chicken_white") == "", "compra duas galinhas durante o lote")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	var farm := await enter("farm")
	var current := await tap(farm, "place:chicken_coop", "chicken_coop")
	var herd: Control = current.call("find_in_panel", "Herd")
	check(herd != null and herd.get_child_count() == 3, "três animais com três colunas")
	for i in 3:
		var dot: Control = current.call("find_in_panel", "Slot_%d" % i)
		check(dot != null and dot.get_parent().name == "Animal_%d" % i, "espaço embaixo do animal %d" % i)
		check(dot.get("state") == ("busy" if i == 2 else "empty"), "só a ruiva alimentada produz; novas ficam vazias após recarga")
	var buy: Button = current.call("find_in_panel", "BuyAnimals")
	check(buy != null and buy.get_parent().get_child(-1) == buy, "Comprar animais é o último botão")
	sheet_titles.clear()
	buy.pressed.emit()
	await frames()
	check(sheet_titles == ["Comprar animais"], "rodapé abre a loja sem Ver tudo")
	events.emit_signal("sheet_close_requested")
	state.call("dev_finish_timers")
	check(state.call("collect", "chicken_coop").get("egg", 0) == 2, "animais novos não duplicam a produção antiga")
	check(state.call("cook", "eggs") == "", "próxima alimentação inclui as três")
	current = await tap(farm, "place:chicken_coop", "chicken_coop")
	for i in 3:
		check(current.call("find_in_panel", "Slot_%d" % i).get("state") == "busy", "três espaços ocupados na nova alimentação")
	state.call("dev_finish_timers")
	await frames()
	for i in 3:
		check(current.call("find_in_panel", "Slot_%d" % i).get("state") == "ready", "cada animal tem produto pronto")
	check(state.call("collect", "chicken_coop").get("egg", 0) == 6, "três animais entregam seis ovos uma vez")
	farm.call("close_tray")


# --- 1. fogão: escolher a receita e cozinhar sem sair do mapa -------------------------------

func _test_stove_cooks() -> void:
	reset_world_state()
	var house := await enter("house")
	add("carrot", 4)
	toasts.clear()
	sheet_titles.clear()
	var current := await tap(house, "place:stove", "stove")
	check(current != null, "tocar no fogão abre a bandeja")
	if current == null:
		return
	check(bool(current.get("pick")), "bandeja no modo pick")
	check(sheet_titles.is_empty(), "nenhum painel grande abriu")
	check(current.get_parent() == house, "bandeja é filha da sala")
	check(current.get("selected") == "carrot_snack", "começa na primeira receita disponível")
	var ids: Array = current.call("entry_ids")
	check(ids.size() >= 3 and ids[0] == "carrot_snack", "receitas do fogão em grade (%d)" % ids.size())
	var box: Control = current.get("_box")
	check(is_equal_approx(box.size.x, 328.0), "largura 328 (%.0f)" % box.size.x)
	check(box.position.y >= 119.0, "bandeja não fica sob o HUD (y %.0f)" % box.position.y)
	check(Rect2(Vector2.ZERO, house.size).encloses(Rect2(box.position, box.size)), "bandeja inteira dentro da sala")
	var close_button: Control = current.call("find_in_panel", "CloseTray")
	check(box.get_global_rect().encloses(close_button.get_global_rect()), "fechar fica dentro da bandeja")
	check(primaries(current) == 1, "um único botão principal (%d)" % primaries(current))
	check(current.call("find_in_panel", "Slot_0") != null, "bolinha da vaga 1 no cabeçalho")
	var cook := current.call("find_in_panel", "Cook") as Button
	check(cook != null and not cook.disabled and cook.text == "Cozinhar", "botão Cozinhar habilitado (%s)" % (cook.text if cook else "?"))
	check(not close_button.get_global_rect().intersects(cook.get_global_rect()), "fechar não cobre o botão de ação")
	var slot_before: Control = current.call("find_in_panel", "Slot_0")
	check(slot_before.get("state") == "empty", "vaga 1 começa vazia")
	press(current, "Cook")
	await frames()
	check(state.get("inventory").call("count", "carrot") == 2, "cenouras descontadas uma vez (%d)" % state.get("inventory").call("count", "carrot"))
	check((state.call("station", "stove").queue as Array).size() == 1, "uma receita na fila")
	check(tray() == current, "a bandeja continua aberta")
	var slot: Control = current.call("find_in_panel", "Slot_0")
	check(slot != null and slot.get("state") == "busy", "bolinha 1 ocupada")
	check(current.get("selected") == "carrot_snack", "a receita continua selecionada")
	check(toasts.is_empty(), "cozinhar não gera aviso de erro")
	# Selecionar outra receita muda o detalhe e lembra a escolha.
	current.call("tap_item", "vegetable_soup")
	await frames()
	check(current.get("selected") == "vegetable_soup", "tocar numa receita só a seleciona")
	check((state.call("station", "stove").queue as Array).size() == 1, "selecionar não cozinha")
	check((current.call("find_in_panel", "RecipeName") as Label).text == root.get_node("Database").call("item_name", "vegetable_soup"), "detalhe mostra a receita escolhida")
	house.call("close_tray")
	var again := await tap(house, "place:stove", "stove")
	check(again != null and again.get("selected") == "vegetable_soup", "a última receita escolhida volta selecionada")
	house.call("close_tray")


# --- 2. fila cheia -------------------------------------------------------------------------

func _test_full_queue() -> void:
	reset_world_state()
	var house := await enter("house")
	add("carrot", 100)
	var slots: int = state.call("station_slots", "stove")
	for i in slots:
		check(state.call("cook", "carrot_snack") == "", "enche a fila (%d)" % i)
	var current := await tap(house, "place:stove", "stove")
	check(current != null, "bandeja abre com a fila cheia")
	if current == null:
		return
	var cook := current.call("find_in_panel", "Cook") as Button
	check(cook != null and cook.disabled, "botão desabilitado com a fila cheia")
	check(cook != null and cook.text == state.call("cook_error", "carrot_snack") and cook.text == "Fila cheia", "o botão mostra o motivo (%s)" % (cook.text if cook else "?"))
	var carrots: int = state.get("inventory").call("count", "carrot")
	if cook:
		cook.pressed.emit()
	check(state.get("inventory").call("count", "carrot") == carrots, "nada é descontado com a fila cheia")
	house.call("close_tray")


# --- 3. faltam ingredientes: selo "!" e "Como fazer" --------------------------------------------

func _test_missing_ingredients() -> void:
	reset_world_state()
	var house := await enter("house")
	var current := await tap(house, "place:stove", "stove")
	check(current != null, "bandeja abre sem ingredientes")
	if current == null:
		return
	var item: Control = current.call("item_node", "carrot_snack")
	var badge := item.find_child("Badge", true, false) as Label
	check(badge != null and badge.visible and badge.text == "!", "selo \"!\" na receita sem ingredientes")
	var cook := current.call("find_in_panel", "Cook") as Button
	check(cook != null and cook.disabled and cook.text == state.call("cook_error", "carrot_snack") and cook.text.begins_with("Falta "), "primary desabilitado mostra o que falta (%s)" % (cook.text if cook else "?"))
	var chips := current.call("find_in_panel", "Ingredients") as Control
	check(chips != null and chips.get_child_count() > 0 and chips.get_child(0) is Button, "ingrediente que falta é chip tocável")
	sheet_titles.clear()
	if chips != null and chips.get_child_count() > 0:
		(chips.get_child(0) as Button).pressed.emit()
		await frames()
	check(not sheet_titles.is_empty(), "o chip abre o \"Como fazer\" (%s)" % str(sheet_titles))
	# Com ingredientes o selo some sozinho.
	var reopened := await tap(house, "place:stove", "stove")
	add("carrot", 2)
	state.call("_changed")
	await frames()
	var badge_now := reopened.call("item_node", "carrot_snack").find_child("Badge", true, false) as Label
	check(badge_now != null and not badge_now.visible, "o selo some quando os ingredientes chegam")
	house.call("close_tray")


# --- 4. pronto: tocar só pega -------------------------------------------------------------

func _test_collect_without_opening() -> void:
	reset_world_state()
	var house := await enter("house")
	add("carrot", 4)
	check(state.call("cook", "carrot_snack") == "", "cozinha um petisco")
	state.call("dev_finish_timers")
	var snacks: int = state.get("inventory").call("count", "carrot_snack")
	var current := await tap(house, "place:stove", "stove")
	check(state.get("inventory").call("count", "carrot_snack") == snacks + 1, "o toque pega o petisco pronto")
	check(state.call("station", "stove").ready_count(state.call("now")) == 0, "nada pronto sobrando")
	check(current == null, "coletar no mapa não abre bandeja")
	house.call("close_tray")


# --- 5. liquidificador (outra estação do mesmo lugar) e "Ir" com receita ------------------------

func _test_blender_and_focus() -> void:
	reset_world_state()
	var house := await enter("house")
	add("strawberry", 6)
	var current := await tap(house, "place:blender", "blender")
	check(current != null, "tocar no liquidificador abre a bandeja dele")
	if current == null:
		return
	var ids: Array = current.call("entry_ids")
	check("strawberry_pop" in ids and not ("carrot_snack" in ids), "a bandeja é da estação do sprite tocado")
	var cook := current.call("find_in_panel", "Cook") as Button
	check(cook != null and cook.text == "Cozinhar", "liquidificador também cozinha")
	house.call("close_tray")
	# "Ir" de missão com receita: abre a bandeja da estação com a receita selecionada.
	add("carrot", 4)
	sheet_titles.clear()
	places.call("run", "house", "recipe:vegetable_soup")
	await frames()
	var focused := tray()
	check(focused != null, "\"Ir\" com receita abre a bandeja")
	check(focused != null and focused.get("selected") == "vegetable_soup", "com a receita já selecionada")
	check(sheet_titles.is_empty(), "sem painel grande")
	house.call("close_tray")


# --- 6. Ver tudo -----------------------------------------------------------------------------

func _test_see_all() -> void:
	reset_world_state()
	var house := await enter("house")
	var current := await tap(house, "place:stove", "stove")
	check(current != null, "bandeja do fogão")
	if current == null:
		return
	sheet_titles.clear()
	press(current, "FooterGhost")
	await frames()
	check(sheet_titles == ["Fogão"], "\"Ver tudo\" abre o painel antigo do fogão (%s)" % str(sheet_titles))
	check(tray() == null, "e a bandeja fecha")
	events.emit_signal("sheet_close_requested")
	await frames()


# --- 7. galinheiro --------------------------------------------------------------------------

func _test_coop() -> void:
	reset_world_state()
	var farm := await enter("farm")
	var current := await tap(farm, "place:chicken_coop", "chicken_coop")
	check(current != null, "tocar no galinheiro abre a bandeja")
	if current == null:
		return
	var buy := current.call("find_in_panel", "BuyAnimals") as Button
	check(buy != null and buy.text == "Comprar animais", "sem animais: Comprar animais")
	check(current.call("item_count") == 0, "abrigo vazio não tem ração")
	check(primaries(current) == 1, "um único botão principal")
	sheet_titles.clear()
	if buy:
		buy.pressed.emit()
		await frames()
	check(sheet_titles == ["Comprar animais"], "o botão abre a loja de animais (%s)" % str(sheet_titles))
	events.emit_signal("sheet_close_requested")
	await frames()
	# Com uma galinha: produto selecionável, tempo e ingredientes; Alimentar executa.
	check(state.call("buy_animal", "chicken_white") == "", "compra uma galinha")
	add("corn", 10)
	current = await tap(farm, "place:chicken_coop", "chicken_coop")
	check(current != null and current.call("item_count") == 1 and current.get("pick"), "com animais há uma receita no padrão das estações")
	if current == null:
		return
	check(current.call("find_in_panel", "Herd") != null, "fileirinha dos animais no cabeçalho")
	var feed: String = (current.call("entry_ids") as Array)[0]
	var item: Control = current.call("item_node", feed)
	check((item.find_child("Caption", true, false) as Label).text == TimeText.short(int(root.get_node("Database").get("recipes")[feed].seconds)), "produto mostra tempo de preparo")
	check((item.find_child("Icon", true, false) as TextureRect).texture == root.get_node("Database").call("item_icon", "egg"), "ícone da receita é ovo, não milho")
	current.call("tap_item", feed)
	check(state.get("inventory").call("count", "corn") == 10, "selecionar o ovo não gasta milho")
	var ingredients: Control = current.call("find_in_panel", "Ingredients")
	check(ingredients != null and (ingredients.get_child(0) as Button).text == "10/2", "ingredientes tocáveis mostram milho tem/precisa")
	var action: Button = current.call("find_in_panel", "Cook")
	check(action != null and action.text == "Alimentar" and not action.disabled, "botão Alimentar disponível")
	action.pressed.emit()
	check(state.get("inventory").call("count", "corn") == 8, "alimentar consome o milho uma vez (%d)" % state.get("inventory").call("count", "corn"))
	check((state.call("station", "chicken_coop").queue as Array).size() == 1, "uma alimentação na fila")
	check(tray() == current, "a bandeja fica um instante")
	check(not current.get("options").has("auto_close"), "receita permanece aberta para consulta")
	await frames()
	check(current.call("find_in_panel", "Slot_0") != null and current.call("find_in_panel", "Slot_0").get("state") == "busy", "a bolinha da produção acende")
	var arrow: Control = current.get("_arrow")
	var panel_box: Control = current.get("_box")
	check(is_equal_approx(arrow.position.y, -float(current.get("ARROW")) if arrow.get("points_up") else panel_box.size.y), "a seta acompanha a altura do cabeçalho depois de alimentar")
	await create_timer(1.8).timeout
	check(tray() == current, "bandeja permanece aberta como as outras estações")
	# Uma galinha individual faz o mesmo que o abrigo.
	var hen: Node = farm.find_child("hen_1", true, false)
	if hen != null and hen.visible:
		farm.call("_on_object_tapped", "place:chicken_coop", hen)
		await frames()
		check(tray() != null, "tocar numa galinha abre a bandeja do galinheiro")
	farm.call("close_tray")


# --- 8. Natureza ---------------------------------------------------------------------------

func _test_nature() -> void:
	reset_world_state()
	var progress: Object = state.get("progress")
	progress.nature_xp.clear()
	for id in ["forest_level_2", "forest_level_3", "trees_slot_2", "trees_slot_3"]:
		progress.owned.erase(id)
	check(progress.call("nature_level", "trees") == 1, "Bosque no nível 1 (%d)" % progress.call("nature_level", "trees"))
	var nature := await enter("nature")
	nature.call("close_tray")
	sheet_titles.clear()
	nature.call("_on_object_tapped", "place:trees")
	await frames()
	var current := tray()
	check(current != null, "tocar no Bosque abre a bandeja")
	if current == null:
		return
	check(sheet_titles.is_empty(), "sem painel grande")
	check(bool(current.get("pick")), "modo pick")
	check(current.call("find_in_panel", "LevelRing") != null, "anel de XP do nível")
	check((current.call("find_in_panel", "NatureLevel") as Label).text == "Nível 1", "mostra o nível do local")
	check(current.call("find_in_panel", "LevelsHelp") != null, "\"?\" dos níveis")
	var locked: String = ""
	for id: String in current.call("entry_ids"):
		if str(current.get("entries")[(current.call("entry_ids") as Array).find(id)].get("error", "")) != "":
			locked = id
	check(locked != "", "há um material bloqueado pelo nível com 0 XP")
	if locked != "":
		current.call("tap_item", locked)
		await frames()
		check(current.call("find_in_panel", "RequiredLevel_" + locked) != null, "o detalhe mostra o cadeado com o nível")
		check(current.call("find_in_panel", "Material_" + locked) == null, "sem botão para o material bloqueado")
		check((current.call("item_node", locked).find_child("Caption", true, false) as Label).text.begins_with("Nível"), "legenda do bloqueado = Nível N")
	current.call("tap_item", "wood")
	await frames()
	check(primaries(current) == 1, "um único botão principal")
	check(state.call("gathering_entry", "trees", 0).is_empty(), "vaga 1 livre antes")
	press(current, "Material_wood")
	await frames()
	check(not state.call("gathering_entry", "trees", 0).is_empty(), "\"Buscar\" começa a coleta na vaga 1")
	check(tray() == current, "a bandeja continua aberta")
	var gather: Variant = current.call("find_in_panel", "GatherItem_trees_0")
	check(gather != null, "GatherItem_trees_0 no cabeçalho")
	# Pronto: tocar de novo só recolhe.
	state.call("dev_finish_timers")
	var wood: int = state.get("inventory").call("count", "wood")
	nature.call("close_tray")
	nature.call("_on_object_tapped", "place:trees")
	await frames()
	check(state.get("inventory").call("count", "wood") > wood, "o toque recolhe a coleta pronta")
	check(tray() == null, "Natureza: coleta não abre bandeja")
	nature.call("close_tray")
	# Local fechado: continua abrindo o painel/compra.
	progress.owned.erase("cave_open")
	progress.nature_xp.erase("rocks")
	check(progress.call("nature_level", "rocks") == 0, "Caverna fechada")
	sheet_titles.clear()
	nature.call("_on_object_tapped", "place:rocks")
	await frames()
	check(tray() == null and not sheet_titles.is_empty(), "local fechado abre o painel de compra, não a bandeja")
	events.emit_signal("sheet_close_requested")
	await frames()


# --- 9. mesa de costura -----------------------------------------------------------------------

func _test_sewing() -> void:
	reset_world_state()
	var park := await enter("park")
	var table: Node = park.find_child("sewing_table", true, false)
	if table == null or not state.call("has_upgrade", "sewing"):
		check(false, "mesa de costura no mapa e comprada")
		return
	sheet_titles.clear()
	await tap(park, "place:petshop", "petshop")
	check(tray() == null and sheet_titles == ["Pet shop"], "loja abre o menu de compras separado da costura")
	events.emit_signal("sheet_close_requested")
	await frames()
	var current := await tap(park, "place:sewing", "sewing_table")
	check(current != null, "tocar na mesa de costura abre a bandeja")
	if current == null:
		return
	var ids: Array = current.call("entry_ids")
	check("sew_flower_crown" in ids, "receitas de costura em grade")
	var cook := current.call("find_in_panel", "Cook") as Button
	check(cook != null and (cook.text in ["Costurar", "Você já tem"] or cook.text.begins_with("Falta ")), "verbo da costura (%s)" % (cook.text if cook else "?"))
	park.call("close_tray")


# --- 10. fechar ---------------------------------------------------------------------------------

func _test_outside_closes() -> void:
	reset_world_state()
	var house := await enter("house")
	var current := await tap(house, "place:stove", "stove")
	check(current != null, "bandeja do fogão")
	if current == null:
		return
	check(current.call("find_in_panel", "CloseTray") != null, "✕ pequeno no canto")
	press(current, "CloseTray")
	await frames()
	check(tray() == null, "o ✕ fecha")
	current = await tap(house, "place:stove", "stove")
	events.emit_signal("sheet_requested", "Qualquer", Control.new())
	await frames()
	check(tray() == null, "abrir um painel fecha a bandeja")
	events.emit_signal("sheet_close_requested")
	current = await tap(house, "place:stove", "stove")
	house.call("recenter")
	house.call("_camera_changed")
	await frames()
	check(tray() == null, "mexer na câmera fecha a bandeja")
	var other := await tap(house, "place:stove", "stove")
	var third := await tap(house, "place:blender", "blender")
	check(third != null and third != other, "só uma bandeja por vez")
	house.call("close_tray")
