extends SceneTree
## Desejos do Tiro (aba Desejos) e vínculo: sorteio, cumprir, trocar, esperas, especial e presentes.

var failures: int = 0
var state: Node
var database: Node
var bond_events: Array[int] = []


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Desejos: " + message)


func _initialize() -> void:
	_run.call_deferred()


func slot(i: int) -> Dictionary:
	return state.get("wishes").slots[i]


## Faz o que o desejo do espaço pede e o cumpre.
func complete(i: int) -> String:
	var def: Dictionary = state.call("wish_at", i)
	if str(def.type) == "action":
		for n in int(def.goal.target):
			match str(def.goal.key):
				"pet": state.call("pet")
				"play": state.call("play")
				"bathe": state.call("bathe")
				"feed":
					state.get("inventory").add("dog_food", 1)
					state.call("feed", "dog_food")
	else:
		state.get("inventory").add(str(def.item), 1)
	return state.call("fulfill_wish", i)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	var events: Node = root.get_node("Events")
	events.connect("bond_up", func(level: int, _rewards: Dictionary) -> void: bond_events.append(level))
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	var taken: Array[String] = []
	check(not state.call("_wish_eligible", "strawberry_pop", taken, ""), "picolé não sorteia sem liquidificador")
	progress.owned["blender"] = true
	check(state.call("_wish_eligible", "strawberry_pop", taken, ""), "picolé elegível com liquidificador")
	progress.owned.erase("blender")

	# Antes da caminha: aba escondida, nenhum desejo.
	check(not progress.feature_unlocked("wishes"), "aba escondida antes da caminha")
	check(not state.call("wish_slot_open", 0), "espaço 1 fechado antes da caminha")
	check(state.call("balloon_wish") == "" and int(state.call("fulfillable_wish_count")) == 0, "sem balão nem badge")
	check(slot(0).id == "", "nenhum desejo antes da caminha")
	state.call("dev_add_affection", 100)
	check(not state.call("wish_slot_open", 1) and not state.call("wish_slot_open", 2), "vínculo alto não antecipa a caminha")
	check(state.call("balloon_wish") == "", "nenhum desejo com vínculo alto antes da caminha")
	state.call("reset")
	progress = state.get("progress")

	# Depois: 1 espaço; o primeiro é carinho.
	state.call("dev_complete_quest", "lais_bed")
	state.call("dev_set_phase", "puppy")
	check(progress.feature_unlocked("wishes"), "aba liberada com caminha e Filhotinho")
	check("feature:wishes" in state.call("new_unlocks"), "Desejos entra no anúncio Novo!")
	check(state.call("wish_slot_open", 0) and not state.call("wish_slot_open", 1), "só o 1º espaço está aberto")
	check(slot(0).id == "pet", "primeiro desejo = carinho (%s)" % slot(0).id)
	check(state.call("balloon_wish") == "pet", "balão mostra o carinho")
	var coins: int = state.get("coins")
	var affection: int = state.get("dog").affection
	check(state.call("wish_error", 0) != "" and state.call("fulfill_wish", 0) != "", "ainda não dá para receber")
	for n in 3:
		state.call("pet")
	check(state.call("wish_error", 0) == "" and int(state.call("fulfillable_wish_count")) == 1, "3 carinhos cumprem")
	var pet_gain: int = state.get("dog").affection - affection  # carinhos (+1 cada)
	check(state.call("fulfill_wish", 0) == "", "receber o desejo")
	check(state.get("coins") == coins + 2, "moedas do desejo uma vez")
	check(state.get("dog").affection == affection + pet_gain + 5, "afeto do desejo uma vez")
	check(progress.stat("wish") == 1 and progress.stat("wish:pet") == 1, "contadores wish")
	check(state.call("fulfill_wish", 0) != "" and state.get("coins") == coins + 2, "não paga duas vezes")

	# Os 3 primeiros reabastecem em 60 s; o 4º em 600 s.
	check(slot(0).id == "" and int(state.call("wish_wait", 0)) >= 55 and int(state.call("wish_wait", 0)) <= 60, "1º desejo: espera ~60 s")
	state.call("dev_advance_time", 30.0)
	check(slot(0).id == "", "ainda esperando aos 30 s")
	state.call("dev_advance_time", 31.0)
	check(slot(0).id != "", "novo desejo depois de 60 s")
	check(complete(0) == "", "cumpre o 2º (%s)" % slot(0).id)
	check(int(state.call("wish_wait", 0)) <= 60, "2º desejo: espera ~60 s")
	state.call("dev_advance_time", 61.0)
	check(slot(0).id != "", "3º desejo aparece")
	check(complete(0) == "", "cumpre o 3º")
	check(int(state.call("wish_wait", 0)) <= 60, "3º desejo: espera ~60 s")
	state.call("dev_advance_time", 61.0)
	check(complete(0) == "", "cumpre o 4º")
	check(int(state.call("wish_wait", 0)) > 590 and int(state.call("wish_wait", 0)) <= 600, "4º desejo: espera ~600 s (%d)" % int(state.call("wish_wait", 0)))
	state.call("dev_advance_time", 601.0)
	check(slot(0).id != "", "desejo volta depois de 600 s")

	# Comida: sem o item, o erro cita o nome; com ele, "Dar" consome 1 e conta feed:<item>.
	state.call("dev_complete_quest", "first_harvest")
	state.get("wishes").slots[0] = {"id": "carrot", "base": 0, "since": 0.0, "ready_at": 0.0, "special": false, "last": ""}
	state.get("inventory").remove("carrot", state.get("inventory").count("carrot"))
	check("Cenoura" in str(state.call("wish_error", 0)), "erro cita a cenoura: %s" % state.call("wish_error", 0))
	check(state.call("wish_slot_for_item", "carrot") == -1, "sem item: comida não é 'desejada'")
	state.get("inventory").add("carrot", 2)
	check(state.call("wish_slot_for_item", "carrot") == 0, "com item: comida desejada no espaço 1")
	var direct_before: int = progress.stat("wish")
	state.call("feed", "carrot")
	check(slot(0).id == "carrot" and progress.stat("wish") == direct_before, "alimentar diretamente não cumpre o desejo")
	state.get("inventory").add("carrot", 1)
	var feed_before: int = progress.stat("feed:carrot")
	var wishes_before: int = progress.stat("wish")
	check(state.call("fulfill_wish", 0) == "", "Dar a cenoura")
	check(state.get("inventory").count("carrot") == 1, "consumiu 1 cenoura")
	check(progress.stat("feed:carrot") == feed_before + 1 and progress.stat("wish") == wishes_before + 1, "contou feed:carrot e wish")

	# Trocar: sem custo, espera 300 s.
	state.call("dev_advance_time", 700.0)
	check(slot(0).id != "", "espaço com desejo para trocar")
	var swapped_from: String = slot(0).id
	coins = state.get("coins")
	check(state.call("swap_wish", 0) == "" and state.get("coins") == coins, "trocar não custa nada")
	check(slot(0).id == "" and int(state.call("wish_wait", 0)) > 295 and int(state.call("wish_wait", 0)) <= 300, "troca: espera ~300 s")
	check(state.call("swap_wish_error", 0) != "", "espaço vazio não troca")
	state.call("dev_advance_time", 301.0)
	check(slot(0).id != "" and slot(0).id != swapped_from, "novo desejo diferente do trocado")

	# Prioridade de necessidade: higiene baixa pede banho.
	for i in 3:
		state.get("wishes").slots[i] = WishState.empty_slot(0.0)
	state.get("dog").apply({"hygiene": -100}, state.call("now"))
	state.call("dev_refresh_wishes")
	check(slot(0).id == "bath", "higiene baixa -> banho (%s)" % slot(0).id)
	state.call("dev_fill_needs")

	# Sorteio estável ao recarregar.
	var ids: Array = []
	for i in 3:
		ids.append(slot(i).id)
	var saved: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", saved)
	var again: Array = []
	for i in 3:
		again.append(slot(i).id)
	check(ids == again, "mesmos desejos depois de recarregar")
	state.get("wishes").slots[0] = WishState.empty_slot(5000.0)
	var pending_save: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("update_wishes")
	var first_pick: String = slot(0).id
	state.call("from_dict", pending_save)
	check(first_pick != "" and slot(0).id == first_pick, "mesma semente pendente sorteia o mesmo desejo ao recarregar")

	# Vínculo: 2º espaço com vínculo 2; sem repetir desejo; presente de nível uma vez.
	state.call("reset")
	state.call("dev_complete_quest", "lais_bed")
	state.call("dev_set_phase", "puppy")
	bond_events.clear()
	state.get("dog").affection = 0
	state.get("progress").claimed_bond_level = 1
	check(not state.call("wish_slot_open", 1), "2º espaço fechado no vínculo 1")
	coins = state.get("coins")
	state.call("dev_add_affection", 25)
	check(state.call("bond_level") == 2 and state.call("wish_slot_open", 1), "vínculo 2 abre o 2º espaço")
	check(state.get("coins") == coins + 10 and bond_events == [2], "presente do vínculo 2 uma vez + sinal")
	state.call("dev_add_affection", 0)
	check(state.get("coins") == coins + 10 and bond_events == [2], "presente não repete")
	var bond_save: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", bond_save)
	check(state.get("coins") == coins + 10 and bond_events == [2], "recarregar não repete presente de vínculo")
	check(slot(1).id != "" and slot(1).id != slot(0).id, "2º espaço sem repetir o desejo do 1º")
	state.call("dev_add_affection", 30)
	check(state.call("bond_level") == 3 and bond_events == [2, 3], "vínculo 3 emite sinal")

	# Especial: só com vínculo >= 3; recompensa dobrada.
	state.call("dev_complete_quest", "bloblo_stew")
	state.get("progress").owned["stove"] = true  # o pedido só sorteia o que dá para fazer: fogão e geladeira
	state.get("progress").owned["fridge"] = true
	database.get("wishes").settings.special_chance = 1.0
	state.get("wishes").slots[0] = WishState.empty_slot(0.0)
	state.get("wishes").slots[1] = WishState.empty_slot(0.0)
	state.call("dev_refresh_wishes")
	var found := -1
	for i in 2:
		if slot(i).special:
			found = i
	check(found >= 0 and slot(found).id == "vegetable_soup", "especial aparece com vínculo 3")
	if found >= 0:
		check(int(state.call("wish_rewards", found).coins) == 12 and int(state.call("wish_rewards", found).affection) == 20, "especial paga o dobro")
		state.get("inventory").add("vegetable_soup", 1)
		coins = state.get("coins")
		check(state.call("fulfill_wish", found) == "" and state.get("coins") == coins + 12, "especial entrega a recompensa dobrada (moedas no teto de 12)")
	state.get("dog").affection = 0
	state.get("wishes").slots[0] = WishState.empty_slot(0.0)
	state.call("dev_refresh_wishes")
	check(not slot(0).special, "sem vínculo 3, nada de especial")
	database.get("wishes").settings.special_chance = 0.05

	# Conteúdo e ações.
	check(database.get("routines").daily.legacy.has("wishes") and database.get("routines").weekly.legacy.has("best_friend"), "diária e semanal de desejos (legado, fora do sorteio novo)")
	check(database.get("collections").has("heart_collar"), "coleira de coração na coleção")
	state.call("reset")
	state.call("dev_complete_quest", "lais_bed")
	state.call("dev_set_phase", "puppy")
	for n in 3:
		state.call("pet")
	var kinds: Array = []
	for action: Dictionary in state.call("available_actions"):
		kinds.append(action.kind)
	check("wish" in kinds, "available_actions inclui desejo")
	await _ui_checks()
	print("WISHES TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


## Telas: aba, cartões, balão, seletor de comida, vínculo. Capturas com "-- --screenshots".
func _ui_checks() -> void:
	# Este teste consulta as salas na hora; a viagem animada é coberta em world_selector_test.
	Motion.reduced = true
	state.call("reset")
	state.call("dev_complete_quest", "lais_bed")
	state.call("dev_set_phase", "puppy")
	state.call("dev_complete_quest", "growth_1_puppy")  # o Sítio abre ao receber o primeiro crescimento
	state.get("progress").seen["intro"] = true
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var tab: Button = main.get_node("%WishesTab")
	check(tab.visible, "aba Desejos aparece depois da caminha")
	main.call("show_screen", &"wishes")
	await process_frame
	await process_frame
	var screen: Node = main.get_node("%WishesScreen")
	check(screen.visible and _find_label(screen, "Quero carinho!") != null, "cartão do desejo de carinho na aba")
	check(_find_button(screen, "Ir") != null, "desejo de carinho mostra Ir")
	var help_script: Script = load("res://scripts/ui/task_help.gd")
	var help: Dictionary = help_script.call("describe", "wish", "pet")
	check(help.target.screen == "pet" and "carinho" in str(help.detail), "? do carinho explica o toque na tela Tiro")
	await _shot("wishes_start", main)
	# Balão no mapa da casa.
	main.call("show_screen", &"map")
	main.call("_on_world_requested", "house", "")
	for n in 40:
		await process_frame
	var dog: Node2D = _find_dog(main)
	check(dog != null and dog.call("has_balloon"), "balão sobre o Tiro no mapa")
	check(dog.call("hit_test", dog.position), "Tiro com balão aceita toque")
	main.get_node("%WorldsScreen").get("_views")["house"].call("_handle_tap", dog.position)
	check(main.get("_current_screen") == &"wishes", "toque no Tiro com balão abre Desejos")
	main.call("show_screen", &"map")
	await _shot("wishes_balloon_map", main)
	main.call("_on_world_requested", "farm", "")
	for n in 8:
		await process_frame
	var farm_dog: Node2D = _find_dog(main.get_node("%WorldsScreen").get("_views")["farm"])
	check(farm_dog != null and farm_dog.call("has_balloon"), "balão legível no Tiro pequeno do sítio")
	# Cenoura alta e demais canvases: o ícone inteiro fica no miolo do balão.
	var original_slot: Dictionary = slot(0).duplicate(true)
	var balloon_icons: Script = load("res://scripts/ui/wish_ui.gd")
	for id: String in database.get("wishes").wishes:
		state.get("wishes").slots[0] = {"id": id, "base": 0, "since": 0.0, "ready_at": 0.0, "special": false, "last": ""}
		for actor: Node2D in [dog, farm_dog]:
			actor.call("_refresh_balloon")
			var icon: Sprite2D = actor.get("_balloon_icon")
			check(icon.texture != null, "ícone do desejo existe: " + id)
			check(icon.texture == balloon_icons.call("icon", id), "balão trocou para o ícone pedido: " + id)
			var drawn := Rect2(icon.position + icon.get_rect().position * icon.scale, icon.get_rect().size * icon.scale)
			check(Rect2(-10, -12, 20, 20).encloses(drawn), "ícone cabe no balão: " + id)
			check(is_equal_approx(icon.scale.x, icon.scale.y), "ícone mantém proporção: " + id)
		if id == "carrot": await _shot("wishes_balloon_carrot", main)
	state.get("wishes").slots[0] = original_slot
	dog.call("_refresh_balloon")
	farm_dog.call("_refresh_balloon")
	await _shot("wishes_balloon_farm", main)
	# Tela do Tiro: balão e chip de vínculo.
	main.call("show_screen", &"pet")
	for n in 5:
		await process_frame
	check(main.get_node("%PetScreen").find_child("WishBubble", true, false).visible, "balão na tela do Tiro")
	await _shot("wishes_balloon_pet", main)
	state.call("set_sleeping", true)
	check(not dog.call("has_balloon") and not main.get_node("%PetScreen").find_child("WishBubble", true, false).visible, "balões somem dormindo")
	state.call("set_sleeping", false)
	# O cabeçalho de Desejos usa pose fixa: não tenta dormir nem altera sua posição.
	main.call("show_screen", &"wishes")
	for phase: String in ["puppy", "teething", "young"]:
		state.call("dev_set_phase", phase)
		for n in 4: await process_frame
		var portrait := screen.find_child("WishesTiroPortrait", true, false) as TextureRect
		check(portrait != null, "retrato fixo na aba Desejos: " + phase)
		var texture := portrait.texture
		var rect := portrait.get_global_rect()
		check(texture.resource_path == str(state.call("dog_look").idle_front), "retrato acompanha corpo da fase")
		check(portrait.find_children("*", "PetAnimator", true, false).is_empty(), "retrato não tem animador")
		state.call("set_sleeping", true)
		for n in 6: await process_frame
		portrait = screen.find_child("WishesTiroPortrait", true, false) as TextureRect
		check(state.get("dog").sleeping and portrait.texture == texture and portrait.get_global_rect() == rect, "sono preserva pose/tamanho/posição: " + phase)
		if phase == "teething": await _shot("wishes_static_sleeping", main)
		state.call("set_sleeping", false)
		for n in 4: await process_frame
		portrait = screen.find_child("WishesTiroPortrait", true, false) as TextureRect
		check(portrait.texture == texture and portrait.get_global_rect() == rect, "acordar não move o retrato: " + phase)
	state.call("dev_set_phase", "puppy")
	# Cumpre: badge some, cartão vira espera.
	for n in 3:
		state.call("pet")
	check(int(state.call("fulfillable_wish_count")) == 1, "badge conta 1")
	check(main.get("_wishes_badge").visible and main.get("_wishes_badge").text == "1", "badge visível da aba")
	state.call("fulfill_wish", 0)
	check(not main.get("_wishes_badge").visible, "badge some ao receber")
	main.call("show_screen", &"wishes")
	for n in 3:
		await process_frame
	check(_find_label(screen, "Novo desejo em", true) != null, "espaço esperando mostra o relógio")
	# Três espaços: normal, especial e fechado (vínculo 3), depois esperando.
	state.get("dog").affection = 55
	state.call("dev_complete_quest", "bloblo_stew")
	state.get("progress").owned["stove"] = true  # o pedido só sorteia o que dá para fazer: fogão e geladeira
	state.get("progress").owned["fridge"] = true
	state.get("progress").claimed_bond_level = state.call("bond_level")
	database.get("wishes").settings.special_chance = 1.0
	state.get("wishes").slots[0] = WishState.empty_slot(0.0)
	state.get("wishes").slots[1] = WishState.empty_slot(0.0)
	state.call("dev_refresh_wishes")
	database.get("wishes").settings.special_chance = 0.05
	state.get("inventory").add("carrot_snack", 1)
	for n in 3:
		await process_frame
	check(_find_label(screen, "Com vínculo ♥4", true) != null, "3º espaço fechado mostra o vínculo")
	await _shot("wishes_three", main)
	state.get("wishes").slots[0] = WishState.empty_slot(float(state.call("now")) + 250.0)
	state.call("_changed")
	for n in 3:
		await process_frame
	await _shot("wishes_waiting", main)
	state.call("dev_add_affection", 50)
	await _shot("wishes_all_open", main)
	# Seletor de comida com "Ele quer!".
	state.get("wishes").slots[0] = {"id": "carrot_snack", "base": 0, "since": 0.0, "ready_at": 0.0, "special": false, "last": ""}
	state.get("inventory").add("dog_food", 2)
	var sheet_builder: Script = load("res://scripts/ui/sheet_builder.gd")
	root.get_node("Events").emit_signal("sheet_requested", "Comidinha", sheet_builder.call("food_picker"))
	for n in 4:
		await process_frame
	check(_find_label(main, "Ele quer!", true) != null, "seletor de comida destaca o que ele quer")
	await _shot("wishes_food_picker", main)
	var food_before: int = state.get("inventory").count("carrot_snack")
	var done_before: int = state.get("wishes").done_count
	_find_button(main.get_node("Sheet"), "Dar").emit_signal("pressed")
	check(state.get("wishes").done_count == done_before + 1 and state.get("inventory").count("carrot_snack") == food_before - 1, "Dar no seletor cumpre o desejo com uma comida")
	root.get_node("Events").emit_signal("sheet_close_requested")
	# Comemoração de vínculo.
	main.get("_celebration").call("show_bond", 3, {"coins": 25, "items": {"carrot_snack": 2}})
	for n in 3:
		await process_frame
	await _shot("wishes_bond_up", main, false)
	main.get("_celebration").call("hide")
	var wish_ui: Script = load("res://scripts/ui/wish_ui.gd")
	root.get_node("Events").emit_signal("sheet_requested", "Vínculo", wish_ui.call("bond_panel"))
	for n in 4:
		await process_frame
	await _shot("wishes_bond_panel", main)
	main.queue_free()
	await process_frame


func _find_dog(node: Node) -> Node2D:
	if node.name == "Tiro" and node.has_method("has_balloon"):
		return node as Node2D
	for child in node.get_children():
		var found := _find_dog(child)
		if found:
			return found
	return null


func _find_label(node: Node, text: String, contains: bool = false) -> Label:
	if node is Label and node.is_visible_in_tree() and (((node as Label).text == text) or (contains and text in (node as Label).text)):
		return node as Label
	for child in node.get_children():
		var found := _find_label(child, text, contains)
		if found:
			return found
	return null


func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text and node.is_visible_in_tree():
		return node as Button
	for child in node.get_children():
		var found := _find_button(child, text)
		if found:
			return found
	return null


func _shot(file_name: String, main: Node, clean_modals: bool = true) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	# Saltos DEV da preparação geram anúncios; eles não devem encobrir a tela que estamos revisando.
	for n in 5:
		await process_frame
	await create_timer(1.3).timeout  # espera os chips animados da última recompensa saírem da tela
	if clean_modals:
		main.get("_modal_queue").clear()
		main.get("_celebration").hide()
		main.get("_welcome").hide()
		main.get_node("Toast").hide()
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../build/screenshots"))
	root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../build/screenshots/%s.png" % file_name))
