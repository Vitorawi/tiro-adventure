extends SceneTree
## Cozinha completa (plano primeira_semana, E03): pratos conhecidos (estado salvo), prévia ao vivo da aba Inventar
## ("Prato novo!", nutrientes, "Conta como prato com ovo", Gororoba), 2 vagas na panela e a 3ª no dia 3, tipos que abrem
## por dia, categorias reais, filtros Dá para fazer / Faltam / Do Tiro, selo "Para crescer", estrelas reais e o ciclo
## descobrir → cozinhar → recolher → dar ao Tiro sem nenhum prato provisório.
##   godot --headless --path game -s res://tests/cook_dishes_test.gd

var failures := 0
var state: Node
var events: Node
var db: Node
var main: Control
var cook: Script
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("COOK DISHES: " + message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func panel() -> Control:
	return cook.call("current") as Control


func node(node_name: String) -> Control:
	return panel().find_child(node_name, true, false) as Control if panel() != null else null


func names(pattern: String) -> Array[String]:
	var result: Array[String] = []
	if panel() == null:
		return result
	for each in panel().find_children(pattern, "Control", true, false):
		result.append(each.name)
	return result


func tap(target: Control) -> void:
	check(target != null, "peça para tocar existe")
	if target == null:
		return
	var hit := target.get_node_or_null("Hit") as Control
	if hit != null:
		target = hit
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = target.size / 2.0
		target.gui_input.emit(click)


func tap_card(scroll: Control, card: Control) -> void:
	check(card != null and scroll != null, "cartão na rolagem existe")
	if card == null or scroll == null:
		return
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = card.position + scroll.get("content").position + card.size / 2.0
		scroll.call("_gui_input", click)


## "Cozinhar junto" abre o minigame (E04): estes testes cobrem a regra da cozinha, então Pulam (cozinha como o botão).
func skip_together() -> void:
	var game := root.find_child("CookTogether", true, false)
	if game != null:
		game.call("skip")


func give(item: String, amount: int) -> void:
	state.get("inventory").call("add", item, amount)
	events.state_changed.emit()


func count(item: String) -> int:
	return int(state.get("inventory").call("count", item))


func reset_world() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.set("coins", 5000)
	for id: String in state.get("stations"):
		state.get("stations")[id].queue.clear()
	state.get("inventory").call("from_dict", {})
	state.set("animals", {})


func preview(type: String, picks: Array) -> Dictionary:
	return state.call("dish_preview", type, picks)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	events = root.get_node("Events")
	db = root.get_node("Database")
	load("res://tests/helpers/old_day_rules.gd").new().apply(db)
	cook = load("res://scripts/ui/cook_panel.gd")
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	reset_world()
	_preview_rules()
	_known_and_cycle()
	_save_roundtrip()
	await _ui()
	print("COOK DISHES: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- Regras ---------------------------------------------------------------------------------------------------

func _preview_rules() -> void:
	state.call("dev_week_goto", 1)
	state.call("dev_content_day", 1)
	check(not db.get("items").has("invented_dish") and not db.get("recipes").get("dish_batch", {}).has("inputs_required"), "não existe prato provisório")
	check(str(preview("papinha", []).state) == "empty", "nada na panela: empty")
	check(str(preview("papinha", ["carrot"]).state) == "incomplete", "um só ingrediente na papinha: faltam")
	var fixed := preview("papinha", ["carrot", "potato"])
	check(str(fixed.state) == "new" and str(fixed.recipe) == "puppy_mash" and str(fixed.name) == "Papinha de cenoura e batata", "cenoura + batata: prato novo (receita fixa equivalente) %s" % [fixed])
	check(str(fixed.output) == "puppy_mash" and int(fixed.stars) == 1, "a saída é a papinha de sempre, 1 estrela")
	check(int((fixed.nutrients as Dictionary).forca) > 0 or int((fixed.nutrients as Dictionary).foco) > 0, "a prévia traz os nutrientes")
	var egg := preview("papinha", ["carrot", "egg"])
	check(str(egg.state) == "new" and (egg.notes as Array).has("Conta como prato com ovo"), "ovo: Conta como prato com ovo (%s)" % [egg.notes])
	var fish := preview("papinha", ["potato", "fish_tilapia"])
	check(str(fish.counts_as) == "fish_mash" and (fish.notes as Array).has("Conta como prato com peixe"), "papinha de peixe vale como fish_mash e conta como prato com peixe")
	var junk := preview("papinha", ["carrot", "apple"])
	check(str(junk.state) == "gororoba" and str(junk.output) == "gororoba" and (junk.refund as Dictionary).has("apple"), "fruta na papinha: Gororoba, devolve a maçã")
	check(str(preview("sopinha", ["carrot", "potato", "pumpkin"]).state) == "blocked", "Sopinha ainda fechada no dia 1")
	check(str(preview("papinha", ["carrot", "potato", "pumpkin"]).state) == "blocked", "3ª vaga da papinha só no dia 3")
	check(not bool(state.call("dish_type_open", "sopinha")) and bool(state.call("dish_type_open", "papinha")), "tipos abrem pelo dia")
	state.call("dev_week_goto", 3)
	state.call("dev_content_day", 3)
	check(bool(state.call("dish_type_open", "sopinha")) and str(preview("sopinha", ["carrot", "potato", "pumpkin"]).state) == "new", "dia 3: a Sopinha abre")
	check(str(preview("papinha", ["carrot", "potato", "pumpkin"]).state) == "new", "dia 3: a papinha ganha a 3ª vaga")
	check(not bool(state.call("dish_type_open", "mingau")), "Mingau só no dia 4")
	var text := str(load("res://scripts/ui/cook_invent.gd").call("nutrient_text", {"forca": 2, "brilho": 0, "foco": 1, "animo": 0}, true))
	check(text == "Força 2 · Foco 1", "texto dos nutrientes (%s)" % text)


func _known_and_cycle() -> void:
	reset_world()
	state.call("dev_week_goto", 2)
	state.call("dev_content_day", 2)
	give("carrot", 4)
	give("corn", 1)
	give("egg", 2)
	check(int(state.call("dishes_known_count")) == 0, "nenhum prato conhecido no começo")
	toasts.clear()
	check(str(state.call("cook_invented", {"carrot": 1, "corn": 1}, "papinha")) == "", "descobre a papinha de cenoura e milho")
	check(bool(state.call("dish_known", "papinha", ["cenoura", "milho"])) and int(state.call("dish_stars", "papinha", ["milho", "cenoura"])) == 1, "o prato fica conhecido, 1 estrela (ordem não importa)")
	check(toasts.has("Prato novo: Papinha de cenoura e milho!"), "avisa o prato novo (%s)" % [toasts])
	check(str(preview("papinha", ["carrot", "corn"]).state) == "known", "a prévia agora diz já conhecido")
	var queue: Dictionary = state.call("station", "stove").queue[0]
	check(str(queue.recipe) == "dish_batch" and str(queue.job.output) == "dish_papinha_cenoura+milho_1", "o lote guarda o prato do motor")
	check(str(db.call("entry_output", queue)) == "dish_papinha_cenoura+milho_1" and float(db.call("entry_seconds", queue)) == 300.0, "a fila mostra o prato e o tempo dele")
	toasts.clear()
	give("carrot", 1)
	give("corn", 1)
	check(str(state.call("cook_invented", {"carrot": 1, "corn": 1}, "papinha")) == "", "cozinha de novo")
	check(int(state.call("dishes_known_count", "papinha")) == 1 and int(state.get("week").dishes["dish:papinha:cenoura+milho"].made) == 2, "conta lotes, sem repetir o prato")
	check(not toasts.has("Prato novo: Papinha de cenoura e milho!"), "o aviso de prato novo sai uma vez")
	state.call("station", "stove").queue.clear()
	# Ciclo: recolher e dar ao Tiro, nada provisório.
	check(str(state.call("cook_known_dish", "dish:papinha:cenoura+milho")) == "Falta Cenoura ×1" or count("carrot") > 0, "refazer o prato conhecido gasta os ingredientes")
	state.call("station", "stove").queue.clear()
	give("corn", 1)
	check(str(state.call("cook_invented", {"carrot": 1, "corn": 1}, "papinha")) == "", "papinha para o ciclo")
	state.call("station", "stove").queue[0]["ready_at"] = float(state.call("now")) - 1.0
	var got: Dictionary = state.call("collect", "stove")
	var dish := "dish_papinha_cenoura+milho_1"
	check(int(got.get(dish, 0)) == 1 and count(dish) == 1, "recolher entrega o prato (%s)" % [got])
	check(bool(state.call("feed", dish)), "dá o prato ao Tiro")
	check(count(dish) == 0, "o Tiro comeu e o prato saiu da Mochila")
	# Receita fixa: cozinhar a papinha de sempre dá 1 estrela, e o prato do motor equivalente não duplica o cartão.
	give("potato", 2)
	check(int(state.call("recipe_stars", "puppy_mash")) == 0, "receita nunca feita: 0 estrela")
	check(str(state.call("cook_invented", {"carrot": 1, "potato": 1}, "papinha")) == "", "cenoura + batata cozinha a receita fixa")
	check(int(state.call("recipe_stars", "puppy_mash")) == 1 and not bool(state.call("dish_known", "papinha", ["cenoura", "batata"])), "a receita fixa ganha 1 estrela e não vira prato do motor")


func _save_roundtrip() -> void:
	var data: Dictionary = (state.get("week").call("to_dict") as Dictionary).duplicate(true)
	check((data.dishes as Dictionary).has("dish:papinha:cenoura+milho") and (data.dishes as Dictionary).has("recipe:puppy_mash"), "os pratos conhecidos vão para o save")
	state.get("week").call("from_dict", data)
	check(bool(state.call("dish_known", "papinha", ["cenoura", "milho"])) and int(state.call("recipe_stars", "puppy_mash")) == 1, "e voltam ao carregar")
	var known: Array = state.call("known_dishes")
	check(known.size() == 1 and str(known[0].type) == "papinha", "known_dishes devolve o prato do motor")


# --- Tela -----------------------------------------------------------------------------------------------------

func open_stove(room: Control) -> void:
	room.call("close_tray")
	room.call("open_station_tray", "stove", "")
	await frames(4)


func _ui() -> void:
	reset_world()
	state.call("dev_week_goto", 2)
	state.call("dev_content_day", 2)
	give("carrot", 6)
	give("potato", 4)
	give("corn", 2)
	give("egg", 2)
	give("apple", 1)
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(4)
	main.call("_on_world_requested", "house", "")
	main.call("show_screen", &"map")
	await frames(4)
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var house := main.find_child("World_house", true, false) as Control
	house.call("_animate_objects")
	# Um prato do motor conhecido e uma receita fixa feita, para a lista mostrar os dois.
	state.call("cook_invented", {"carrot": 1, "corn": 1}, "papinha")
	state.call("cook", "carrot_snack")
	state.call("station", "stove").queue.clear()
	await open_stove(house)
	cook.set("invent_mode", false)
	check(panel() != null, "o painel do fogão abriu")

	# Categorias reais: Todos, os tipos abertos no dia 2 e Outros; Mingau e Sopinha ainda fechados.
	var cats := names("Cat_*")
	check("Cat_all" in cats and "Cat_papinha" in cats and "Cat_petisco" in cats and "Cat_biscoito" in cats and "Cat_other" in cats, "categorias de tipos abertos: %s" % [cats])
	check(not ("Cat_sopinha" in cats) and not ("Cat_mingau" in cats), "tipos fechados não viram categoria no dia 2")

	# Pratos conhecidos entram na lista, com estrelas reais.
	var known_card := node("Dish_k_papinha_cenoura+milho")
	check(known_card != null, "o prato descoberto aparece na lista (%s)" % [names("Dish_*")])
	if known_card != null:
		check(int(known_card.find_child("DishStars", true, false).get_meta("count")) == 1, "prato do motor: 1 estrela")
	var snack := node("Dish_carrot_snack")
	check(snack != null and int(snack.find_child("DishStars", true, false).get_meta("count")) == 1, "receita feita: 1 estrela")
	var puppy := node("Dish_puppy_mash")
	check(puppy != null and int(puppy.find_child("DishStars", true, false).get_meta("count")) == 0, "receita nunca feita: sem estrela")

	# Categoria filtra a lista de verdade.
	tap_card(node("CatScroll"), node("Cat_petisco"))
	await frames(2)
	var dishes := names("Dish_*")
	check("Dish_carrot_snack" in dishes and not ("Dish_puppy_mash" in dishes) and not ("Dish_k_papinha_cenoura+milho" in dishes), "Petiscos só mostra petiscos (%s)" % [dishes])
	tap_card(node("CatScroll"), node("Cat_papinha"))
	await frames(2)
	dishes = names("Dish_*")
	check("Dish_k_papinha_cenoura+milho" in dishes and "Dish_puppy_mash" in dishes and not ("Dish_carrot_snack" in dishes), "Papinhas junta fixas e conhecidas (%s)" % [dishes])
	tap_card(node("CatScroll"), node("Cat_all"))
	await frames(2)

	# Filtros.
	tap(node("Filter_can"))
	await frames(2)
	dishes = names("Dish_*")
	check("Dish_carrot_snack" in dishes and "Dish_k_papinha_cenoura+milho" in dishes and not ("Dish_pumpkin_mash" in dishes), "Dá para fazer: só o que há ingredientes e fila (%s)" % [dishes])
	tap(node("Filter_can"))
	tap(node("Filter_missing"))
	await frames(2)
	dishes = names("Dish_*")
	check("Dish_puppy_mash" in dishes or "Dish_vegetable_soup" in dishes or dishes.size() > 0, "Faltam mostra pratos com ingrediente faltando (%s)" % [dishes])
	check(not ("Dish_carrot_snack" in dishes), "Faltam não traz o que dá para fazer")
	tap(node("Filter_missing"))
	await frames(2)

	# "Para crescer": o selo nos pratos que o próximo crescimento pede (Dentinhos: papinha de peixe).
	state.call("dev_set_phase", "puppy")
	await frames(2)
	var foods: Array = load("res://scripts/ui/station_tray.gd").call("growth_foods")
	tap(node("Filter_tiro"))
	await frames(2)
	dishes = names("Dish_*")
	var shown_ok := true
	for entry: Dictionary in panel().call("_entries"):
		if bool(entry.grow) != (str(entry.output) in foods):
			shown_ok = false
		if bool(entry.grow) != (("Dish_" + str(entry.id)) in dishes):
			shown_ok = false
	check(shown_ok, "Do Tiro e o selo Para crescer seguem o que o crescimento pede (%s)" % [foods])
	tap(node("Filter_tiro"))
	await frames(2)
	var fish_card := node("Dish_fish_mash")
	check("fish_mash" in foods and fish_card != null and fish_card.find_child("GrowBadge", true, false) != null, "selo Para crescer na papinha de peixe (%s)" % [foods])

	# Inventar: prévia ao vivo, 2 vagas e a 3ª no dia 3.
	tap(node("InventHalf"))
	await frames(2)
	check(names("InvSlot_*").size() == 2, "papinha no dia 2 tem 2 espaços (%d)" % names("InvSlot_*").size())
	check(str(node("InvCard").get_meta("state")) == "empty", "panela vazia")
	var view := node("InventView")
	view.call("set_slot", 0, "carrot")
	view.call("set_slot", 1, "egg")
	await frames(2)
	var card := node("InvCard")
	check(str(card.get_meta("state")) == "new", "cenoura + ovo: Prato novo! (%s)" % card.get_meta("state"))
	check((node("BoxText") as Label).text == "Prato novo!" and (node("BoxNote") as Label).text == "Conta como prato com ovo", "o cartão diz Prato novo! e Conta como prato com ovo")
	check((node("Hint") as Label).text.contains("Foco"), "a dica traz os nutrientes (%s)" % (node("Hint") as Label).text)
	check(node("InvStars") != null, "estrelas no cartão da prévia")
	view.call("set_slot", 1, "apple")
	await frames(2)
	check(str(card.get_meta("state")) == "gororoba" or str(node("InvCard").get_meta("state")) == "gororoba", "fruta na papinha: Gororoba")
	check((node("InvCardName") as Label).text == "Gororoba", "a Gororoba aparece com um nome só")
	check((node("BoxNote") as Label).text.begins_with("Devolve"), "Gororoba diz o que devolve (%s)" % (node("BoxNote") as Label).text)
	view.call("set_slot", 1, "")
	await frames(2)
	check(str(node("InvCard").get_meta("state")) == "incomplete", "um só ingrediente: Falta pouco")
	# Tipos fechados: cadeado, toque avisa e não troca.
	var closed := node("InvType_sopinha")
	check(closed != null and bool(closed.get_meta("locked")) and closed.find_child("LockIcon", true, false) != null, "Sopinha trancada no dia 2")
	toasts.clear()
	tap_card(node("InvTypes"), closed)
	await frames(2)
	check(toasts.has("Continue a História") and not bool(node("InvType_sopinha").get_meta("selected")), "tocar na Sopinha trancada avisa o dia (%s)" % [toasts])
	state.call("dev_week_goto", 3)
	state.call("dev_content_day", 3)
	await frames(3)
	check(names("InvSlot_*").size() == 3, "no dia 3 a papinha ganha o 3º espaço (%d)" % names("InvSlot_*").size())
	check(not bool(node("InvType_sopinha").get_meta("locked")), "e a Sopinha abre")
	# Cozinhar o prato novo pelo botão, recolher e ver conhecido.
	view.call("set_slot", 0, "carrot")
	view.call("set_slot", 1, "egg")
	await frames(2)
	tap(node("InvCookButton"))
	skip_together()
	await frames(2)
	check(bool(state.call("dish_known", "papinha", ["cenoura", "ovo"])), "o botão cozinhou e o prato ficou conhecido")
	check(str(node("InvCard").get_meta("state")) == "empty", "os espaços esvaziam depois de cozinhar")
	panel().call("close", true)
	await frames(2)
	await open_stove(house)
	check(node("Dish_k_papinha_cenoura+ovo") != null, "o prato novo aparece na aba Pratos")
	var slot0 := node("Slot_0")
	check(slot0 != null and str(slot0.get_meta("state")) in ["busy", "queued"] and slot0.find_child("Dish", true, false) != null, "a fila mostra o prato em preparo")
	panel().call("close", true)
