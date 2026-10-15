extends SceneTree
## Construções/expansões e reações a ações reais do GameState, sem gravar save pessoal.

var failures: int = 0
var state: Node
var main: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Vida no mundo: " + message)


func _run() -> void:
	# Consulta das salas sem esperar a viagem; a animação tem teste próprio em world_selector_test.
	Motion.reduced = true
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.call("dev_complete_quest", "bloblo_meet")  # vovó Bloblo já emprestou o canteiro
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("_on_world_requested", "farm", "")
	await create_timer(0.4).timeout
	var farm: Control = main.find_child("World_farm", true, false)
	var dog: Node2D = farm.get("_dog")
	var greenhouse: Sprite2D = farm.find_child("greenhouse", true, false)
	var orchard: Sprite2D = farm.find_child("orchard", true, false)
	check(greenhouse.self_modulate.a == 0.0 and orchard.self_modulate.a == 0.0, "Construções ainda não compradas invisíveis")
	check(farm.find_child("Region_greenhouse_area", true, false).visible, "Área da estufa fechada")
	_shot("farm_expansion_start")
	var nav: AStarGrid2D = farm.get("_nav")
	check(nav.is_point_solid(Vector2i(300, 260) / 8), "Tiro não entra na área fechada")
	# Colheita real e caminho da reação: deve continuar contornando canteiros.
	check(state.call("plant", 0, "carrot") == "", "Plantar cenoura")
	state.get("plots")[0].ready_at = 0.0
	check(not (state.call("harvest", 0) as Dictionary).is_empty(), "Colher cenoura")
	check(dog.get_meta("last_reaction", "") == &"harvest", "Tiro reage à colheita")
	var before_walk := dog.position
	await create_timer(0.3).timeout
	check(dog.position.distance_to(before_walk) > 1.0, "Tiro interrompe o passeio e se aproxima da colheita")
	var sprite: AnimatedSprite2D = dog.get("_sprite")
	var deadline := Time.get_ticks_msec() + 10000
	while not str(sprite.animation).begins_with("eat_") and Time.get_ticks_msec() < deadline:
		await create_timer(0.1).timeout
	check(str(sprite.animation).begins_with("eat_"), "Tiro chega e cheira a colheita")
	if "--screenshots" in OS.get_cmdline_user_args():
		await create_timer(1.1).timeout
		_shot("tiro_harvest_reaction")
	state.call("dev_grant_upgrade", "farm")
	state.call("dev_add_coins", 2000)
	state.set("unlimited_storage", true)
	state.call("dev_add_items", 20)
	check(state.call("buy_upgrade", "greenhouse") == "", "Comprar estufa abre a expansão pela ação real")
	check(dog.get_meta("last_reaction", "") == &"build", "Tiro comemora a construção")
	check(greenhouse.self_modulate.a == 1.0, "Compra revela estufa imediatamente")
	check(orchard.self_modulate.a == 0.0, "Comprar estufa não libera o pomar")
	# Um save com compras antigas também revela as novas construções/áreas.
	state.call("dev_unlock_everything")
	state.call("dev_add_coins", 3000)
	for id: String in root.get_node("Database").get("animals"):
		if int(state.get("animals").get(id, 0)) > 0:
			continue  # Abrigos já entregaram o primeiro animal.
		check(state.call("buy_animal", id) == "", "Comprar variedades para conferir caminhos")
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	check(greenhouse.self_modulate.a == 1.0 and orchard.self_modulate.a == 1.0, "Construções compradas aparecem")
	check(not farm.find_child("Region_greenhouse_area", true, false).visible, "Cerca sai depois da compra")
	check(not nav.is_point_solid(Vector2i(300, 260) / 8), "Área aberta entra na navegação")
	check(not (farm.call("find_path", dog.position, Vector2(300, 260)) as PackedVector2Array).is_empty(), "Área expandida é alcançável")
	farm.call("_zoom_at", farm.size / 2.0, 0.3)
	await create_timer(0.3).timeout
	_shot("farm_expansion_built")
	farm.call("point_at", "place:orchard")
	await create_timer(0.3).timeout
	_shot("farm_orchard_focus")
	var bench: Sprite2D = farm.find_child("workbench", true, false)
	check(bench.self_modulate.a == 1.0, "Bancada aparece")
	state.set("unlimited_storage", true)
	state.call("dev_add_items", 20)
	check(state.call("cook", "plank") == "", "Produzir tábua")
	state.call("dev_finish_timers")
	farm.call("_animate_objects")
	check(dog.get_meta("last_reaction", "") == &"ready", "Tiro percebe estação pronta")
	check(not (state.call("collect", "workbench") as Dictionary).is_empty(), "Recolher tábua")
	check(dog.get_meta("last_reaction", "") == &"collect", "Tiro comemora a coleta")
	main.call("_on_world_requested", "house", "")
	await create_timer(0.3).timeout
	var house: Control = main.find_child("World_house", true, false)
	_shot("house_buildings")
	main.call("_on_world_requested", "village", "")
	await create_timer(0.3).timeout
	var village: Control = main.find_child("World_village", true, false)
	check(village.find_child("stall_extension", true, false).self_modulate.a == 1.0, "Banca extra aparece")
	check(village.find_child("atelier_station", true, false).self_modulate.a == 1.0, "Oficina da Laís aparece")
	_shot("village_buildings")
	for room: Control in [farm, house, village]:
		_check_paths(room)
	# Caminha do Tiro: presente grátis, e o Tiro passa a dormir nela (no chão).
	state.get("progress").owned.erase("dog_bed")  # dev_unlock_everything já comprou
	state.call("dev_add_coins", 0)  # só para emitir state_changed
	await process_frame
	var house_dog: Node2D = house.get("_dog")
	check(not (house_dog.get("sleep_point") as Vector2).is_equal_approx(Vector2(376, 330)), "Sem caminha, o Tiro não dorme nela")
	state.get("inventory").call("remove", "bed_gift", int(state.get("inventory").call("count", "bed_gift")))  # dev_add_items deu 20
	check(state.call("upgrade_error", "dog_bed") != "", "Caminha exige o presente")
	state.get("inventory").call("add", "bed_gift", 1)
	var coins_before: int = state.get("coins")
	check(state.call("buy_upgrade", "dog_bed") == "", "Comprar a caminha com o presente")
	check(state.get("coins") == coins_before, "Caminha não custa moedas")
	check(state.get("inventory").call("count", "bed_gift") == 0, "Comprar consome o presente")
	check((house_dog.get("sleep_point") as Vector2).is_equal_approx(Vector2(376, 330)), "Com caminha, sleep_point = bed_sleep")
	check(house.find_child("dog_bed", true, false).self_modulate.a == 1.0, "Caminha aparece na casa")
	_shot("house_bed")
	# Dormindo/fora do mapa não reage nem acorda por causa de uma produção.
	state.call("set_sleeping", true)
	var village_dog: Node = village.get("_dog")
	var before: Variant = village_dog.get_meta("last_reaction", "")
	village_dog.call("react_at", &"build", Vector2(300, 220))
	check(village_dog.get_meta("last_reaction", "") == before, "Não acorda o Tiro para comemorar")
	state.call("set_sleeping", false)
	main.call("show_screen", &"pet")
	village_dog.call("react_at", &"happy", Vector2(300, 220))
	check(village_dog.get_meta("last_reaction", "") == before, "Não reage em mapa oculto")
	main.queue_free()
	await process_frame
	print("WORLD LIFE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


## Verifica os segmentos completos após todas as construções estarem no chão.
func _check_paths(room: Control) -> void:
	var data: Dictionary = root.get_node("Database").call("room", room.get("room_id"))
	var obstacles: Array[PackedVector2Array] = []
	for object: Dictionary in data.objects:
		if object.has("footprint"):
			obstacles.append(_polygon(object.footprint))
	for obstacle: Dictionary in data.get("obstacles", []):
		obstacles.append(_polygon(obstacle.polygon))
	var dog: Node2D = room.get("_dog")
	var start := dog.position
	for attempt in 60:
		var target: Vector2 = room.call("random_floor_point", start)
		var path: PackedVector2Array = room.call("find_path", start, target)
		check(not path.is_empty(), "Destino continua alcançável depois das compras")
		for i in range(1, path.size()):
			var steps := maxi(1, ceili(path[i - 1].distance_to(path[i])))
			for step in range(steps + 1):
				var point := path[i - 1].lerp(path[i], float(step) / steps)
				for area: PackedVector2Array in obstacles:
					check(not Geometry2D.is_point_in_polygon(point, area), "Caminho contorna construções compradas em " + str(room.get("room_id")))
		start = target


func _polygon(values: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for value: Array in values:
		result.append(Vector2(value[0], value[1]))
	return result


func _shot(file_name: String) -> void:
	if "--screenshots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder + file_name + ".png")
