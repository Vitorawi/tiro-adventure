extends SceneTree
## Cartões de mundo: bloqueios, um toque para entrar e dimensões no celular.

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Mundos: " + message)


func _run() -> void:
	Motion.reduced = true
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.call("reset")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.call("_on_world_requested", "house", "")
	var worlds: Control = main.find_child("WorldsScreen", true, false)
	worlds.call("show_map")
	await create_timer(0.3).timeout
	var nature: Button = worlds.find_child("WorldCard_nature", true, false)
	check(nature != null and nature.disabled, "Natureza fechada antes da história")
	check(worlds.find_child("WorldCard_house", true, false).custom_minimum_size.y >= 64, "Linha inteira é alvo grande")
	_shot("worlds_locked")
	state.call("dev_jump_to_chapter", 4)
	await create_timer(0.3).timeout
	main.get_node("Celebration").hide()
	worlds.call("show_map")
	await create_timer(3.2).timeout
	await process_frame
	await process_frame
	(main.get("_toast") as Control).hide()
	nature = worlds.find_child("WorldCard_nature", true, false)
	check(not nature.disabled, "Cartão libera conforme história")
	_shot("worlds_select")
	# Todos os destinos visíveis viajam com um único toque.
	nature.pressed.emit()
	await create_timer(0.2).timeout
	check(worlds.get("current_world") == "nature", "Um toque entra no mundo")
	check(not worlds.call("is_map_open"), "Seleção fecha após entrar")
	var collect: Button = worlds.get_node("%PlacesButton")
	check(collect.text == "" and collect.icon != null, "Lugares é um botão só de ícone (Natureza também)")
	check((worlds.get_node("%MapButton") as Button).text == "Natureza", "Pílula do mundo mostra o nome")
	collect.pressed.emit()
	await create_timer(0.2).timeout
	load("res://scripts/ui/places.gd").call("open", "nature", "trees")
	await create_timer(0.2).timeout
	check(main.find_child("Material_wood", true, false) == null, "Bosque fechado mostra desbloqueio")
	state.call("dev_add_coins", 100)
	state.call("buy_upgrade", "forest_open")
	await create_timer(0.2).timeout
	check(main.find_child("Material_wood", true, false) != null, "Árvores abre corte diretamente")
	main.queue_free()
	await process_frame
	print("WORLDS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _shot(file_name: String) -> void:
	if "--screenshots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/")
		DirAccess.make_dir_recursive_absolute(folder)
		root.get_texture().get_image().save_png(folder + file_name + ".png")
