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
	# Consulta das salas sem esperar a viagem; a animação tem teste próprio em world_selector_test.
	Motion.reduced = true
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	var before: Dictionary = state.call("to_dict").duplicate(true)
	check(state.call("cook", "eggs") != "", "Não alimenta sem galinheiro")
	check(state.call("plant", 0, "corn") != "", "Milho espera apresentação do sítio")
	check(state.call("to_dict") == before, "Falhas não consomem itens/progresso")
	state.call("dev_jump_to_chapter", 5)
	state.call("dev_complete_quest", "farm_deed")
	state.call("dev_grant_upgrade", "farm")
	state.call("dev_add_coins", 3000)
	state.set("unlimited_storage", true)
	state.call("dev_add_items", 20)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("_on_world_requested", "farm", "")
	await create_timer(0.4).timeout
	var farm: Control = main.find_child("World_farm", true, false)
	check(farm.find_child("Region_animals_area", true, false).visible, "Área começa cercada")
	check(not farm.find_child("hen_1", true, false).get_node("PurchaseMarker").visible, "Não mostra marcador duplicado nas galinhas")
	var planks: int = state.get("inventory").count("plank")
	state.get("inventory").remove("plank", planks)
	var lacking: Dictionary = state.call("to_dict").duplicate(true)
	check(state.call("buy_upgrade", "chicken_coop") != "", "Tábuas são obrigatórias")
	check(state.call("to_dict") == lacking, "Sem tábuas não cobra nem entrega presente")
	state.get("inventory").add("plank", planks)
	var construction_coins: int = state.get("coins")
	var buy_error: String = state.call("buy_upgrade", "chicken_coop")
	check(buy_error == "", "Comprar galinheiro: " + buy_error)
	check(state.get("coins") == construction_coins - 180 and state.get("inventory").count("plank") == planks - 4, "Cobra moedas e tábuas exatamente uma vez")
	check(not farm.find_child("Region_animals_area", true, false).visible, "Compra abre a área")
	check(state.call("animal_count", "chicken_coop") == 1, "Abrigo inclui primeira galinha de presente")
	check(farm.find_child("hen_1", true, false).visible, "Presente aparece no mapa")
	check(state.call("buy_animal", "chicken_brown") != "", "Ruiva espera primeira coleta")
	var purchased: Dictionary = state.call("to_dict").duplicate(true)
	check(state.call("buy_upgrade", "chicken_coop") != "", "Não recompra abrigo")
	check(state.call("to_dict") == purchased, "Recompra não duplica presente nem cobra")
	var saved_coins: int = state.get("coins")
	state.set("coins", 0)
	check(state.call("buy_animal", "chicken_white") != "" and state.call("animal_count", "chicken_coop") == 1, "Falta de moedas não entrega outro animal")
	state.set("coins", saved_coins)
	var animal_shop: Control = load("res://scripts/ui/sheet_builder.gd").call("animal_shop", "chicken_coop")
	root.add_child(animal_shop)
	await process_frame
	var buy_button: Button
	for button: Node in animal_shop.find_children("*", "Button", true, false):
		if button.text == "Comprar · 60 moedas":
			buy_button = button
	check(buy_button != null and not buy_button.disabled, "Loja permite comprar animal disponível")
	check(state.call("animal_count", "chicken_coop") == 1, "Loja preserva animal presente")
	animal_shop.queue_free()
	await process_frame
	check(state.get("coins") == saved_coins, "Abrir loja não cobra moedas")
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
	check(state.call("buy_animal", "chicken_brown") != "", "Esperar timer não libera variedade antes de recolher")
	state.call("dev_advance_time", 180)
	check(state.call("collect", "chicken_coop").get("egg", 0) == 2, "Ovos terminam offline")
	check((state.call("collect", "chicken_coop") as Dictionary).is_empty(), "Não duplica coleta")
	check(state.call("buy_animal", "chicken_brown") == "", "Primeira coleta libera ruiva")
	check(state.call("cook", "eggs") == "", "Alimentar duas galinhas")
	state.call("dev_finish_timers")
	check(state.call("collect", "chicken_coop").get("egg", 0) == 4, "Quantidade acompanha animais alimentados")
	check(state.call("buy_animal", "chicken_black") == "", "Terceira variedade")
	var full_save: Dictionary = state.call("to_dict").duplicate(true)
	check(state.call("buy_animal", "chicken_white") != "", "Respeita três vagas")
	check(state.call("to_dict") == full_save, "Compra recusada não cobra moedas")
	check(state.call("buy_upgrade", "cow_barn") == "", "Comprar curral")
	check(state.call("animal_count", "cow_barn") == 1, "Curral inclui vaca presente")
	check(state.call("buy_animal", "cow_brown") != "", "Caramelo espera leite")
	check(state.call("cook", "milk") == "", "Alimentar vacas")
	state.call("dev_advance_time", 300)
	check(state.call("collect", "cow_barn").get("milk", 0) == 2, "Vacas dão leite")
	check(state.call("buy_upgrade", "mill") == "", "Comprar moinho")
	check(state.call("cook", "flour") == "", "Moer trigo")
	state.call("dev_advance_time", 120)
	check(state.call("collect", "mill").get("flour", 0) == 2, "Moinho dá farinha")
	check(state.call("has_upgrade", "workbench"), "Bancada precede abrigos")
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
	check(farm.find_child("hen_3", true, false).visible, "Três galinhas visíveis")
	check(farm.find_child("hen_2", true, false).texture.resource_path.ends_with("chicken_brown.png"), "Variedade correta no mapa")
	check(state.call("buy_animal", "cow_brown") == "", "Comprar vaca caramelo")
	check(state.call("cook", "milk") == "", "Alimentar duas vacas")
	state.call("dev_finish_timers")
	check(state.call("collect", "cow_barn").get("milk", 0) == 4, "Mais leite libera malhada")
	check(state.call("buy_animal", "cow_spotted") == "", "Comprar vaca malhada")
	var herd_save: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", JSON.parse_string(JSON.stringify(herd_save)))
	check(state.call("animal_count", "cow_barn") == 3, "Rebanho salvo")
	check(state.call("animal_count", "chicken_coop") == 3, "Galinhas salvas")
	state.set("coins", 0)
	check(state.call("buy_animal", "cow_white") != "", "Compra inválida não altera rebanho")
	state.call("from_dict", herd_save)
	# Uma compra durante o timer só conta no lote seguinte.
	state.get("animals").erase("chicken_black")
	check(state.call("cook", "eggs") == "", "Começar lote com duas galinhas")
	check(state.call("buy_animal", "chicken_black") == "", "Comprar terceira durante produção")
	state.call("dev_finish_timers")
	check(state.call("collect", "chicken_coop").get("egg", 0) == 4, "Animal novo não aumenta lote em andamento")
	state.call("from_dict", herd_save)
	# Saves anteriores não tinham estas estações; o loader cria filas vazias.
	var old: Dictionary = state.call("to_dict").duplicate(true)
	old.erase("animals")
	for id: String in ["chicken_coop", "cow_barn", "mill", "dairy"]:
		old.stations.erase(id)
	state.call("from_dict", old)
	check(state.call("station", "cow_barn").queue.is_empty(), "Save antigo compatível")
	check(state.call("animal_count", "cow_barn") == 2 and state.call("animal_count", "chicken_coop") == 2, "Preserva animais da versão anterior")
	var legacy: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", legacy)
	check(state.call("animal_count", "cow_barn") == 2, "Migração não duplica animais")
	state.call("from_dict", herd_save)
	state.call("dev_unlock_everything")
	state.set("unlimited_storage", true)
	state.call("dev_add_items", 20)
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	await process_frame
	await process_frame
	farm.call("_zoom_at", farm.size / 2, 0.32)
	await create_timer(0.2).timeout
	_shot("animals_farm_overview")
	load("res://scripts/ui/sheet_builder.gd").call("open_animal_shop", "cow_barn")
	await create_timer(0.5).timeout
	_shot("animals_shop")
	root.get_node("Events").emit_signal("sheet_close_requested")
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
