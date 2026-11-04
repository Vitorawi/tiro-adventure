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
		check(not (manual.call("sources", id) as Array).is_empty(), id + ": precisa explicar uma fonte")
	# Catálogo do Caderninho: todos os itens aparecem (mesmo sem estar na mochila), um filtro por categoria.
	var notebook: Script = load("res://scripts/ui/pet_notebook.gd")
	var sections: Script = load("res://scripts/ui/codex_sections.gd")
	var categories := {}
	for id: String in db.get("items"):
		categories[str(db.get("items")[id].get("category", "product"))] = true
	for category: String in categories:
		var catalog: Control = notebook.call("panel", "resources:" + category)
		root.add_child(catalog)
		check(catalog.find_child("NotebookTab_" + category, true, false) != null or category == "care", category + ": filtro da categoria")
		for id: String in db.get("items"):
			if str(db.get("items")[id].get("category", "product")) == category:
				check(catalog.find_child("Resource_" + id, true, false) != null, id + ": deve aparecer sem estar na mochila")
		catalog.free()
	var stations: Control = notebook.call("panel", "stations")
	root.add_child(stations)
	check(stations.find_child("Station_blender", true, false) != null and _has_text(stations, "Liquidificador"), "Liquidificador aparece no catálogo")
	check(stations.find_child("Crop_carrot", true, false) == null, "plantas só no filtro delas")
	stations.free()
	# Detalhe enxuto da estação: bloqueio com motivo (sem navegação proibida) ou Ir; estação comprável leva à compra.
	var locked_seen := false
	var buy_seen := false
	for id: String in db.get("stations"):
		var detail: Control = sections.call("station_detail", id)
		root.add_child(detail)
		for lock: Node in detail.find_children("Locked_ManualGo_*", "HBoxContainer", true, false):
			locked_seen = true
			check(str(lock.get_meta("reason", "")) != "" and lock.find_child("LockIcon", true, false) != null, id + ": bloqueio sem motivo")
		check(_button_with_text(detail, "Bloqueado") == null, id + ": não oferece navegação proibida")
		if _has_prefix(detail, "Compre: "):
			buy_seen = true
			check(detail.find_children("ManualGo_*", "Button", true, false).size() == 1, id + ": compra tem Ir")
		detail.free()
	check(locked_seen, "Mundos/lugares fechados precisam de cadeado com motivo")
	check(buy_seen, "Estações ainda não compradas precisam de atalho de compra (Ir + Compre: ...)")
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
	check(main.find_child("ItemBoard", true, false) != null and main.find_child("ItemSources", true, false) != null, "Tocar num recurso abre o detalhe com a origem")
	manual.call("open_item", "carrot")
	await create_timer(0.2).timeout
	check(main.find_child("ItemSources", true, false) != null and main.find_child("Source_0", true, false) != null, "Ingrediente mostra de onde vem (canteiros)")
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
	var go: Button = main.find_child("Source_0", true, false)
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


func _has_prefix(node: Node, prefix: String) -> bool:
	if node == null:
		return false
	if node is Label and str(node.get("text")).begins_with(prefix):
		return true
	for child: Node in node.get_children():
		if _has_prefix(child, prefix):
			return true
	return false
