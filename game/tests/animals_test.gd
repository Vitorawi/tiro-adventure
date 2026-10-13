extends SceneTree
## Cadeias reais: alimentação, capacidade, tempo offline, coleta única e processamento.

var failures: int = 0
var state: Node
var main: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Animais: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	var before: Dictionary = state.call("to_dict").duplicate(true)
	check(state.call("cook", "eggs") != "", "Não alimenta sem galinheiro")
	check(state.call("plant", 0, "corn") != "", "Milho espera apresentação do sítio")
	check(state.call("to_dict") == before, "Falhas não consomem itens/progresso")
	state.call("dev_jump_to_chapter", 2)
	state.call("dev_grant_upgrade", "farm")
	state.call("dev_add_coins", 3000)
	state.call("dev_add_items", 20)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("_on_world_requested", "farm", "")
	await create_timer(0.4).timeout
	var farm: Control = main.find_child("World_farm", true, false)
	check(farm.find_child("Region_animals_area", true, false).visible, "Área começa cercada")
	check(not farm.find_child("hen_1", true, false).get_node("PurchaseMarker").visible, "Não mostra marcador duplicado nas galinhas")
	var buy_error: String = state.call("buy_upgrade", "chicken_coop")
	check(buy_error == "", "Comprar galinheiro: " + buy_error)
	check(not farm.find_child("Region_animals_area", true, false).visible, "Compra abre a área")
	var dog: Node2D = farm.get("_dog")
	check(not (farm.call("find_path", dog.position, Vector2(603, 400)) as PackedVector2Array).is_empty(), "Animais acessíveis sem comprar estufa/pomar")
	check(farm.find_child("Region_greenhouse_area", true, false).visible, "Corredor não libera outras expansões")
	check(state.call("plant", 0, "corn") == "", "Plantar alimento das galinhas")
	state.call("dev_finish_timers")
	check(state.call("harvest", 0).get("corn", 0) == 3, "Milho rende três unidades")
	var corn: int = state.get("inventory").count("corn")
	check(state.call("cook_error", "eggs") == "", "UI e ação podem alimentar")
	check(state.call("cook", "eggs") == "", "Alimentar galinhas")
	check(state.get("inventory").count("corn") == corn - 2, "Consome o milho uma vez")
	check(state.call("cook", "eggs") != "", "Um lote por vez")
	check(state.get("inventory").count("corn") == corn - 2, "Fila cheia não consome comida")
	check((state.call("collect", "chicken_coop") as Dictionary).is_empty(), "Não antecipa ovos")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	check(state.call("station", "chicken_coop").queue.size() == 1, "Alimentação sobrevive ao save")
	state.call("dev_advance_time", 180)
	check(state.call("collect", "chicken_coop").get("egg", 0) == 2, "Ovos terminam offline")
	check((state.call("collect", "chicken_coop") as Dictionary).is_empty(), "Não duplica coleta")
	check(state.call("buy_upgrade", "cow_barn") == "", "Comprar curral")
	check(state.call("cook", "milk") == "", "Alimentar vacas")
	state.call("dev_advance_time", 300)
	check(state.call("collect", "cow_barn").get("milk", 0) == 2, "Vacas dão leite")
	check(state.call("buy_upgrade", "mill") == "", "Comprar moinho")
	check(state.call("cook", "flour") == "", "Moer trigo")
	state.call("dev_advance_time", 120)
	check(state.call("collect", "mill").get("flour", 0) == 2, "Moinho dá farinha")
	check(not state.call("has_upgrade", "workbench"), "Setup mantém bancada não comprada")
	farm.call("_on_object_tapped", "place:mill")
	await create_timer(0.2).timeout
	var sheet: Control = main.find_child("Sheet", true, false)
	check(sheet.get_node("%Title").text == "Moinho", "Toque no moinho abre moinho, sem exigir bancada")
	root.get_node("Events").emit_signal("sheet_close_requested")
	check(state.call("buy_upgrade", "dairy") == "", "Comprar queijaria")
	var milk: int = state.get("inventory").count("milk")
	check(state.call("cook", "cheese") == "", "Fazer queijo")
	check(state.get("inventory").count("milk") == milk - 2, "Queijo consome leite")
	state.call("dev_advance_time", 240)
	check(state.call("collect", "dairy").get("cheese", 0) == 1, "Queijaria dá queijo")
	check(farm.find_child("cow_1", true, false).self_modulate.a == 1, "Vacas aparecem no mapa")
	check(farm.find_child("hen_1", true, false).self_modulate.a == 1, "Galinhas aparecem no mapa")
	# Saves anteriores não tinham estas estações; o loader cria filas vazias.
	var old: Dictionary = state.call("to_dict").duplicate(true)
	for id: String in ["chicken_coop", "cow_barn", "mill", "dairy"]:
		old.stations.erase(id)
	state.call("from_dict", old)
	check(state.call("station", "cow_barn").queue.is_empty(), "Save antigo compatível")
	state.call("dev_unlock_everything")
	state.call("dev_add_items", 20)
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	farm.call("_zoom_at", farm.size / 2, 0.32)
	await create_timer(0.2).timeout
	_shot("animals_farm_overview")
	state.call("cook", "eggs")
	state.call("cook", "milk")
	main.call("_on_world_requested", "farm", "recipe:eggs")
	await create_timer(1.2).timeout
	_shot("animals_feed")
	root.get_node("Events").emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "farm", "recipe:cheese")
	await create_timer(1.2).timeout
	_shot("animals_dairy")
	root.get_node("Events").emit_signal("sheet_close_requested")
	load("res://scripts/ui/game_manual.gd").call("open_item", "milk")
	await create_timer(0.3).timeout
	_shot("animals_manual_milk")
	main.queue_free()
	await process_frame
	print("ANIMALS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _shot(file_name: String) -> void:
	if "--screenshots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder + file_name + ".png")
