extends SceneTree
## Casa que cresce: ações reais, relógio injetado, recarga e navegação; sem save pessoal.
var state: Node
var db: Node
var failures := 0
var arrivals: Array[String] = []
var decor: Variant
const T0 := 1791936000.0

func _initialize() -> void:
	_run.call_deferred()
	create_timer(170).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Casa: " + message)

func fresh(phase: String = "newborn") -> void:
	state.test_time = T0
	state.reset()
	state.progress.seen["intro"] = true
	state.growth.phase = phase
	for need: String in state.dog.needs:
		state.dog.needs[need] = 50.0
	arrivals.clear()

func reload_state() -> void:
	state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))

func photos(count: int) -> void:
	for i in count:
		state.dev_take_photo(str(db.album.photos[i].id))

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	decor = load("res://scripts/ui/house_decor.gd")
	root.get_node("Events").house_item_arrived.connect(func(id: String) -> void: arrivals.append(id))
	check(db.house_problems().is_empty(), "catálogo da Casa válido")
	fresh()
	check(state.house_has("arrival_box"), "caixinha desde a chegada")
	for id: String in db.house.items:
		if id != "arrival_box": check(not state.house_has(id), "ainda não chegou: " + id)
	check(decor.chart_marks().size() == 1, "régua começa na chegada")
	state.growth.phase = "explorer"
	state.growth.ceremonies = {"puppy": {"at": T0 + 10}, "teething": {"at": T0 + 20}}
	state._changed()
	check(decor.chart_marks().size() == 3, "régua conta cerimônias, não fases DEV")
	check(state.house_has("height_chart") and state.house_has("laundry_basket") and state.house_has("toy_basket"), "presentes por fase")
	state.inventory.add("chew_ring")
	check(not state.house_has("memory_shelf"), "possuir lembrança não conta entrega")
	state.growth.delivered = {"teething": {"chew_ring": 1}}
	state._changed()
	check(state.house_has("memory_shelf") and not state.house_has("arrival_box"), "caixinha vai para a prateleira")
	check(decor.shelf_items().map(func(e: Dictionary) -> String: return e.id) == ["arrival_box", "chew_ring"], "prateleira só com entregues")
	_rewards_and_photos()
	_toys()
	_purchases()
	_sleep()
	_food()
	await _room_and_ui()
	print("HOUSE TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func _rewards_and_photos() -> void:
	fresh()
	for threshold in [6, 12, 18, 30, 45]:
		photos(threshold - 1)
		var id: String = {6: "photo_wall", 12: "old_camera", 18: "gold_frame", 30: "star_garland", 45: "big_portrait"}[threshold]
		check(not state.house_has(id), "prêmio espera meta: " + id)
		photos(threshold)
		check(state.house_has(id), "prêmio na meta: " + id)
		check(arrivals.count(id) == 1, "aviso único: " + id)
		state._changed()
		reload_state()
		check(arrivals.count(id) == 1, "recarregar não repete prêmio: " + id)
	check(state.house_has("paw_rug") and state.lupas_per_day() == 2, "tapete e dado da câmera")
	var ids: Array[String] = ["h_arrival", "h_first_night", "h_growth_puppy", "h_kitchen"]
	for id in ids.slice(0, 3): check(state.hang_photo(id) == "", "pendurar: " + id)
	check(state.hang_photo(ids[3]) != "", "quarta foto bloqueada")
	check(state.hang_photo("inexistente", 0) != "", "foto inexistente recusada")
	check(state.hang_photo(ids[3], 1) == "", "trocar lugar ocupado")
	state.unhang_photo(ids[0])
	check(state.hang_photo(ids[0]) == "", "reocupar lugar vazio")
	check(state.set_main_photo(ids[3]) == "", "escolher foto do cantinho")
	var wall: Array = state.album.wall.duplicate()
	reload_state()
	check(state.album.wall == wall and state.album.main_photo == ids[3], "parede e principal persistem")

func _toys() -> void:
	fresh()
	state.inventory.add("braided_toy", 2)
	check(state.give_toy("braided_toy") != "" and state.inventory.count("braided_toy") == 2, "sem cesto não consome")
	state.growth.phase = "explorer"
	check(state.give_toy("braided_toy") == "" and state.inventory.count("braided_toy") == 1, "dar move uma unidade")
	check(state.give_toy("braided_toy") != "" and state.inventory.count("braided_toy") == 1, "não duplica brinquedo")
	state.inventory.add("lost_ball")
	check(state.give_toy("lost_ball") == "", "bolinha também serve")
	check(state.give_toy("carrot") != "", "recusa item sem toy")
	reload_state()
	check(state.toy_basket_count() == 2, "brinquedos persistem")
	state.dog.needs.happiness = 40.0
	var before: int = state.progress.stat("moment:smart")
	check(state.play(), "brincar pelo caminho real")
	check(state.progress.stat("moment:smart") - before == 1, "brincar útil rende um momento com brinquedos")
	state.progress.house.toys.append_array(["futuro_3", "futuro_4"])
	check(state.toy_basket_count() == 3, "bônus máximo +3")
	before = state.progress.stat("moment:smart")
	state.dog.needs.happiness = 40.0
	state.play()
	check(state.progress.stat("moment:smart") - before == 1, "brinquedos não multiplicam momentos")

func _sleep() -> void:
	for bed: String in ["", "bed_soft", "bed_luxe"]:
		fresh("adult")
		if bed != "": state.progress.owned[bed] = true
		if bed == "bed_luxe": state.progress.owned.bed_soft = true
		state._changed()
		state.dog.needs.energy = 10.0
		state.dog.sleeping = true
		var expected := 50.0 + 40.0 * float(db.house.sleep_bonus.get(bed, 0.0))
		check(is_equal_approx(state.dog.get_need("energy", T0 + 3600), expected), "energia online: " + bed)
		state.begin_absence(T0)
		reload_state()
		check(is_equal_approx(state.dog.get_need("energy", T0 + 3600), expected), "energia ausência/reload: " + bed)
		check(state.dog.get_need("energy", T0 + 72 * 3600) == 100.0, "energia não passa de 100")
		for need: String in ["hunger", "hygiene", "happiness"]:
			check(state.dog.get_need(need, T0 + 72 * 3600) >= float(db.needs[need].offline_floor), "pisos preservados")

func _purchases() -> void:
	fresh()
	state.progress.owned.dog_bed = true
	for id: String in ["fabric", "yarn", "plank", "hen_feather", "brick"]:
		state.inventory.add(id, 10)
	var before: Dictionary = state.inventory.to_dict().duplicate(true)
	check(state.buy_upgrade("bed_soft") != "" and state.inventory.to_dict() == before, "fase bloqueia compra sem consumir")
	state.growth.phase = "young"
	check(state.buy_upgrade("bed_soft") == "", "caminha macia comprada com materiais")
	check(state.inventory.count("fabric") == 8 and state.inventory.count("yarn") == 8, "custo macia")
	check(state.buy_upgrade("bed_luxe") != "", "luxo aguarda adulto")
	state.growth.phase = "adult"
	check(state.buy_upgrade("bed_luxe") == "", "luxo comprado")
	check(is_equal_approx(state.dog.sleep_bonus, 0.2), "melhor caminha atualiza DogState")
	check(state.buy_upgrade("named_bowl") == "", "tigela comprada")
	check(state.inventory.count("plank") == 7 and state.inventory.count("brick") == 9, "custo luxo + tigela")

func _food() -> void:
	for bowl: bool in [false, true]:
		fresh("puppy")
		state.growth.taste_seed = 1
		if bowl: state.progress.owned.named_bowl = true
		state.inventory.add("puppy_mash")
		check(state.feed("puppy_mash"), "alimentar real")
		check(state.growth.body_level == 0, "uma porção não antecipa Corpo nem dá pontos")

func _room_and_ui() -> void:
	fresh()
	Motion.reduced = true
	var room: Node = load("res://scenes/levels/room/room.tscn").instantiate()
	root.add_child(room)
	await process_frame
	check(room.find_child("arrival_box", true, false).visible, "caixinha visível no começo")
	check(not room.find_child("memory_shelf", true, false).visible, "prateleira escondida")
	check(room.get("_dog").sleep_point == Vector2(262, 318), "dorme na caixinha")
	state.dev_unlock_everything()
	state.growth.phase = "adult"
	state.growth.delivered = {"teething": {"chew_ring": 1}}
	photos(45)
	state._changed()
	await create_timer(0.2).timeout
	check(room.find_child("bed_luxe", true, false).self_modulate.a == 1.0 and not room.find_child("dog_bed", true, false).visible, "caminha substituída")
	check(room.find_child("memory_shelf", true, false).visible, "entrega revela prateleira")
	check(not (room.find_path(Vector2(330, 310), Vector2(282, 332)) as PackedVector2Array).is_empty(), "chão navegável com enfeites")
	state.hang_photo("h_arrival")
	state.set_main_photo("h_arrival")
	await process_frame
	check(room.find_child("photo_wall", true, false).find_child("PhotoCard", true, false) != null, "parede mostra foto escolhida")
	var ui: Variant = load("res://scripts/ui/house_ui.gd")
	var shelf: Control = ui.shelf()
	check(shelf.find_child("ShelfItem_chew_ring", true, false) != null and shelf.find_child("ShelfItem_stick_chew", true, false) == null, "painel da prateleira só com entregues")
	shelf.free()
	var corner: Variant = load("res://scripts/ui/corner_decor.gd")
	check(corner.choose().size() == 3, "máximo 3 enfeites no cantinho")
	check(db.worlds.house.places.bed.panel == "house:bed" and "named_bowl" in db.worlds.house.places.bowl.upgrades, "melhorias acessíveis")
	room.queue_free()
	await process_frame
