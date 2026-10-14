extends SceneTree
## Manual: cobertura do conteúdo, navegação, bloqueios, consulta sem modificar save.

var failures: int = 0
var manual: Script


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Manual: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.call("reset")
	manual = load("res://scripts/ui/game_manual.gd")
	var db: Node = root.get_node("Database")
	var before: Dictionary = state.call("to_dict").duplicate(true)
	for id: String in db.get("items"):
		if id in ["lost_ball", "bone_keychain", "shiny_pebble", "dog_tag", "map_piece_2"]:
			continue  # achados da Praça: ganham fonte na Etapa 06
		check(not (manual.call("sources", id) as Array).is_empty(), id + ": precisa explicar uma fonte")
		var detail: Control = manual.call("item_panel", id)
		check(detail.get_child_count() > 3, id + ": detalhe deve mostrar fontes")
		detail.free()
	var catalog: Control = manual.call("panel")
	for id: String in db.get("items"):
		check(catalog.find_child("Resource_" + id, true, false) != null, id + ": deve aparecer sem estar na mochila")
	catalog.free()
	var stations: Control = manual.call("panel", "stations")
	check(_has_text(stations, "Liquidificador"), "Liquidificador aparece no catálogo")
	check(_has_text(stations, "Bloqueado"), "Mundos/lugares fechados precisam de botão bloqueado")
	check(_button_with_text(stations, "Bloqueado").disabled, "Consultar o catálogo não permite pular bloqueios")
	check(_has_text(stations, "Ver compra"), "Estações ainda não compradas precisam de atalho de compra")
	stations.free()
	check(state.call("to_dict") == before, "Consultar o manual não altera progresso/inventário")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.2).timeout
	var button: Button = main.find_child("ManualButton", true, false)
	check(button != null and button.is_visible_in_tree(), "Manual visível na tela inicial")
	_shot("manual_home")
	button.pressed.emit()
	await create_timer(0.2).timeout
	check(main.find_child("ManualPanel", true, false) != null, "Atalho abre manual")
	_shot("manual_resources")
	manual.call("open_item", "carrot_snack")
	await create_timer(0.2).timeout
	_shot("manual_recipe")
	var resource: Control = main.find_child("ManualResource*", true, false)
	var ingredient: Button = _button_with_text(resource, "2x Cenoura")
	check(ingredient != null, "Ingrediente deve mostrar nome e quantidade")
	ingredient.pressed.emit()
	await create_timer(0.2).timeout
	check(_has_text(main.find_child("ManualResource*", true, false), "Plantar → esperar → colher"), "Tocar no ingrediente abre sua origem")
	_shot("manual_crop")
	manual.call("open", "stations")
	await create_timer(0.2).timeout
	_shot("manual_stations")
	root.get_node("Events").emit_signal("sheet_close_requested")
	state.call("dev_unlock_everything")
	await create_timer(2.2).timeout
	main.get_node("Celebration").hide()
	main.call("show_screen", &"pet")
	await process_frame
	await process_frame
	_shot("manual_home_late")
	manual.call("open_item", "plank")
	await create_timer(0.2).timeout
	_shot("manual_plank")
	resource = main.find_child("ManualResource*", true, false)
	var go: Button = _button_with_text(resource, "Ir até lá")
	check(go != null and not go.disabled, "Ir liberado quando a bancada existe")
	go.pressed.emit()
	await create_timer(0.2).timeout
	check(main.get("_current_screen") == &"map", "Ir abre o mapa")
	check(main.find_child("World_farm", true, false) != null, "Bancada fica no sítio")
	main.queue_free()
	await process_frame
	print("MANUAL TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _has_text(node: Node, value: String) -> bool:
	if node == null:
		return false
	if (node is Label or node is Button) and node.get("text") == value:
		return true
	for child: Node in node.get_children():
		if _has_text(child, value):
			return true
	return false


func _button_with_text(node: Node, value: String) -> Button:
	if node is Button and node.text == value:
		return node
	for child: Node in node.get_children():
		var found := _button_with_text(child, value)
		if found:
			return found
	return null


func _shot(file_name: String) -> void:
	if "--screenshots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder + file_name + ".png")
