extends SceneTree
## Etapa 12: Escovar (5º cuidado), paladar, favorita e Guia de sabores.

var failures := 0
var state: Node
var db: Node
var pet: Control
var tray: Control
var discovered := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(170.0).timeout.connect(func() -> void:
		push_error("BRUSH TASTE: tempo excedido")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("BRUSH TASTE: " + message)


func frames() -> void:
	for i in 4: await process_frame


func fresh(phase: String = "newborn", seed_value: int = 1000) -> void:
	state.call("reset")
	state.get("progress").seen.intro = true
	state.growth.phase = phase
	state.growth.taste_seed = seed_value
	for need: String in state.dog.needs:
		state.dog.needs[need] = 30.0


func pool() -> Array:
	return db.growth.tastes.favorite_pool


func seed_for_favorite(item: String) -> int:
	for i in range(1, 200):
		state.growth.taste_seed = i
		if state.call("favorite_food") == item:
			return i
	return 1


func earned(pillar: String) -> int:
	return int(state.get("progress").call("stat", "pillar:" + pillar))


func send(id: String, kind: String, point: Vector2) -> void:
	var item: Control = tray.call("item_node", id)
	if not item:
		check(false, "item existe: " + id)
		return
	var event: InputEvent
	if kind == "move":
		var motion := InputEventMouseMotion.new()
		motion.global_position = point
		motion.position = point - item.global_position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		event = motion
	else:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = kind == "press"
		button.global_position = point
		button.position = point - item.global_position
		event = button
	item.gui_input.emit(event)


func knots() -> int:
	var count := 0
	for child in pet.get_children():
		if child.name == "BrushKnot" and not child.is_queued_for_deletion(): count += 1
	return count


## Arrasta a escova pelas costas: `length` px em trechos de 120 px.
func scrub(length: float) -> void:
	var back: Rect2 = pet.call("back_rect")
	var a := back.get_center() + Vector2(-60, 40)
	var b := a + Vector2(120, 0)
	send("brush", "press", tray.call("item_center", "brush"))
	send("brush", "move", a)
	var walked := 0.0
	var step := 0
	while walked < length:
		send("brush", "move", b if step % 2 == 0 else a)
		walked += 120.0
		step += 1
	send("brush", "release", a)


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	saver.get_parent().remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.test_time = 1791936000.0
	Motion.reduced = true
	root.get_node("Events").taste_discovered.connect(func(_item: String, _reaction: String) -> void: discovered += 1)

	# --- Dados: favorita só entre as do favorite_pool e alcançáveis.
	for item: String in pool():
		check(db.items.get(item, {}).has("feed"), "favorita come: " + item)
		var made := false
		for recipe_id: String in db.recipes:
			if str(db.recipes[recipe_id].get("output", "")) == item: made = true
		check(made, "favorita tem receita: " + item)
	check(db.items.has("basic_brush") and db.items.basic_brush.category == "keepsake", "escovinha é lembrança")
	var teething: Dictionary = db.growth.phases[2]
	check(teething.id == "teething" and int(teething.rewards.items.get("basic_brush", 0)) == 1, "Dentinhos dá a escovinha")

	# --- Reações fixas pela semente; favorita = amou; mirtilo cru = careta.
	fresh()
	var seen_reactions := {}
	for i in range(1, 120):
		state.growth.taste_seed = i
		var fav: String = state.call("favorite_food")
		check(fav in pool(), "favorita no pool, semente %d" % i)
		check(state.call("taste_reaction_for", fav) == "loved", "favorita ama")
		check(state.call("taste_reaction_for", "blueberry") == "grimace", "mirtilo cru é careta")
		for item: String in ["carrot", "apple", "dog_food", "pumpkin_mash"]:
			var first: String = state.call("taste_reaction_for", item)
			check(first == state.call("taste_reaction_for", item), "reação estável")
			seen_reactions[first] = true
	check(seen_reactions.has("liked") and seen_reactions.has("odd") and seen_reactions.has("grimace"), "as três reações aparecem")

	# --- Primeira prova: uma vez, persistida; recarregar não repete.
	fresh("puppy", 55)
	var fav_item: String = state.call("favorite_food")
	var other := "carrot" if fav_item != "carrot" else "apple"
	discovered = 0
	state.inventory.add(other, 3)
	check(state.feed(other), "come " + other)
	check(discovered == 1 and state.growth.tastes.has(other), "primeira prova registrada")
	check(state.growth.tastes[other] == state.call("taste_reaction_for", other), "reação gravada")
	check(state.feed(other) and discovered == 1, "segunda vez não repete")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.to_dict()))
	state.from_dict(saved)
	check(state.growth.tastes.has(other) and state.call("favorite_food") == fav_item and state.growth.taste_seed == 55, "recarregar mantém sabores e favorita")
	check(state.feed(other) and discovered == 1, "recarregar não repete a reação")
	state.growth.tastes.erase(fav_item)
	check(not state.call("favorite_found"), "favorita ainda é ?")

	# --- Favorita: +50% nos pilares.
	fresh("puppy")
	seed_for_favorite("pumpkin_mash")
	var base_body := int(db.items.pumpkin_mash.growth.pillars.body)
	state.inventory.add("pumpkin_mash", 2)
	state.feed("pumpkin_mash")
	var with_bonus := earned("body")
	check(with_bonus == ceili(base_body * 1.5), "favorita +50%%: %d" % with_bonus)
	check(state.call("favorite_found") and state.growth.tastes.pumpkin_mash == "loved", "favorita descoberta amou")
	fresh("puppy")
	state.growth.taste_seed = seed_for_favorite("mashed_potato")
	state.inventory.add("pumpkin_mash", 1)
	state.feed("pumpkin_mash")
	check(earned("body") == base_body, "não favorita sem bônus")

	# --- Requisito do adulto: Descubra a favorita, depois conta ×3.
	fresh("young", 77)
	var meals: Dictionary = {}
	for r: Dictionary in state.growth_info().requirements:
		if r.id == "meals": meals = r
	check(meals.type == "feed" and meals.item == "favorite" and meals.need == 3, "requisito favorita ×3")
	check(meals.label == "Descubra a favorita", "chip descubra a favorita: " + str(meals.label))
	var help: Dictionary = load("res://scripts/ui/task_help.gd").describe("growth_req", "meals")
	check(help.needs.size() > 0, "Como fazer lista comidas não provadas")
	var favorite: String = state.call("favorite_food")
	state.inventory.add(favorite, 3)
	state.feed(favorite)
	for r: Dictionary in state.growth_info().requirements:
		if r.id == "meals": meals = r
	check(meals.have == 1 and meals.label.begins_with("Comer "), "favorita descoberta conta: " + str(meals.label))
	state.feed(favorite)
	state.feed(favorite)
	for r: Dictionary in state.growth_info().requirements:
		if r.id == "meals": meals = r
	check(meals.done and meals.have == 3, "favorita ×3 cumpre")

	# --- Escovar: recarga, escova macia, dias distintos.
	fresh("teething", 9)
	check(state.call("brush_error") != "", "sem escova não escova")
	state.inventory.add("basic_brush", 1)
	check(state.call("brush_error") == "", "com escova pode")
	check(state.call("brush") == "", "escova uma vez")
	check(earned("coat") == 5 and state.progress.stat("brush") == 1, "Pelagem 5, conta brush")
	check(state.call("brush") == "Ele já está penteadinho" and earned("coat") == 5, "recarga sem ganho")
	state.test_time += 4.0 * 3600.0 + 1.0
	check(state.call("brush") == "" and earned("coat") == 10, "depois de 4 h escova de novo")
	check(state.growth.brush_days.size() == 1, "mesmo dia, uma data")
	state.test_time += 86400.0
	state.call("brush")
	check(state.growth.brush_days.size() == 2, "dias distintos")
	state.dog.set_sleeping(true, state.call("now"))
	state.test_time += 5 * 3600.0
	check(state.call("brush_error") != "", "dormindo não escova")
	state.dog.set_sleeping(false, state.call("now"))
	fresh("young", 9)
	state.inventory.add("basic_brush", 1)
	state.growth.delivered["young"] = {"soft_brush": 1}
	state.call("brush")
	check(earned("coat") == 8, "escova macia dá 8: %d" % earned("coat"))

	# --- Interface: cinco cuidados, gesto de escovar, guia de comida e de sabores.
	fresh("puppy", 55)
	state.growth.tastes.clear()
	state.get("inventory").call("from_dict", {"dog_food": 3, "carrot": 2})
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	pet = main.find_child("PetScreen", true, false)
	tray = pet.find_child("CareTray", true, false)
	check(tray.find_child("BrushTile", true, false) == null, "sem escova não há BrushTile")
	state.inventory.add("basic_brush", 1)
	state.call("_changed")
	await frames()
	var tile: Control = tray.find_child("BrushTile", true, false)
	check(tile != null, "BrushTile com a escova")
	if tile:
		var row := tile.get_parent()
		var names: Array[String] = []
		for child in row.get_children(): names.append(str(child.name))
		check(names.find("BrushTile") == names.find("Care_sponge") + 1 and names.find("Care_ball") == names.find("BrushTile") + 1, "ordem Comida, Banho, Escovar, Brincar, Dormir: " + str(names))
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await frames()
		var circle_y := -1.0
		for action: String in ["FoodButton", "Care_sponge", "BrushTile", "Care_ball", "SleepButton"]:
			var item: Control = tray.find_child(action, true, false)
			var circle: Control = item.find_child("Circle", true, false)
			check(circle.size == Vector2(56, 56), "círculos iguais: " + action)
			check(tray.get_global_rect().encloses(item.get_global_rect()), "dentro da faixa: %s %s" % [action, str(viewport)])
			if circle_y >= 0: check(is_equal_approx(circle_y, circle.global_position.y), "mesma linha: " + action)
			circle_y = circle.global_position.y
	root.size = Vector2i(360, 780)
	await frames()
	state.growth.cooldowns.erase("brush")
	var coat_before := earned("coat")
	var count_before: int = state.progress.stat("brush")
	scrub(180.0)
	check(state.progress.stat("brush") == count_before, "arrasto curto não escova")
	await frames()
	scrub(400.0)
	check(state.progress.stat("brush") == count_before, "400 px ainda não escova")
	state.growth.cooldowns.erase("brush")
	scrub(720.0)
	check(state.progress.stat("brush") == count_before + 1 and earned("coat") > coat_before, "~600 px = uma escovação")
	await frames()
	check(knots() == 0, "nós somem")
	scrub(720.0)
	check(state.progress.stat("brush") == count_before + 1, "em recarga: sem ganho")
	check(tray.find_child("BrushTile", true, false) != null, "tile continua")

	# Guia de comida: Nova! nas não provadas; ♥ na favorita depois de descoberta.
	tray.call("open_food_menu")
	await frames()
	check(pet.find_child("NewTaste", true, false) != null, "Nova! nas não provadas")
	var guide: Control = load("res://scripts/ui/pillar_ui.gd").taste_guide()
	root.add_child(guide)
	var foods := 0
	for id: String in db.items:
		if db.items[id].has("feed"): foods += 1
	var tiles := 0
	for child in guide.find_children("Taste_*", "Control", true, false): tiles += 1
	check(tiles == foods, "grade com todas as comidas: %d/%d" % [tiles, foods])
	guide.queue_free()
	state.growth.taste_seed = seed_for_favorite("pumpkin_mash")
	state.inventory.add("pumpkin_mash", 1)
	state.feed("pumpkin_mash")
	await frames()
	guide = load("res://scripts/ui/pillar_ui.gd").taste_guide()
	root.add_child(guide)
	var heart: Node = guide.find_child("Taste_pumpkin_mash", true, false).find_child("FavoriteHeart", true, false)
	check(heart != null, "♥ na favorita descoberta")
	guide.queue_free()
	print("BRUSH TASTE: ", "FAIL" if failures > 0 else "PASS")
	quit(1 if failures > 0 else 0)
