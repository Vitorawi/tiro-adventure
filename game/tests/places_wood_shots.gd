extends SceneTree
## Capturas dos rostos e do botão Lugares no mapa (bolinha de madeira) e da folha "Lugares" em madeira. NÃO é teste.
## Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/places_wood_shots.gd
## PNGs em build/screenshots/places_wood/. Não grava o save pessoal.
## Imprime FAIL se a bolinha sair da tela, alvo < 44, linhas de larguras diferentes ou folha sob o HUD.

var main: Node
var failures := 0
const FOLDER := "res://../build/screenshots/places_wood/"
const SHEET_TOP := 128.0  # Hud.SHEET_TOP (em teste -s o Hud depende de autoload)


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _save(shot_name: String) -> void:
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "places_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _audit_map(world_id: String) -> void:
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var button := main.find_child("PlacesButton", true, false) as Control
	_check(button.size.x >= 44.0 and button.size.y >= 44.0, "%s: Lugares menor que 44 (%s)" % [world_id, button.size])
	_check(screen.encloses(button.get_global_rect()), "%s: Lugares fora da tela" % world_id)
	_check(button.find_child("Disc", false, false) is TextureRect, "%s: Lugares sem a bolinha de madeira" % world_id)
	for face: Node in main.find_child("NpcRow", true, false).get_children():
		var rect := (face as Control).get_global_rect()
		_check(screen.encloses(rect), "%s: %s fora da tela" % [world_id, face.name])
		_check(not rect.intersects(button.get_global_rect()), "%s: %s cobre Lugares" % [world_id, face.name])


func _audit_sheet(world_id: String) -> void:
	var panel := main.get_node("Sheet").get_node("%Panel") as Control
	_check(panel.get_global_rect().position.y >= SHEET_TOP - 1.0, "%s: folha sob o HUD" % world_id)
	_check(panel.get_global_rect().end.y <= root.get_visible_rect().size.y + 1.0, "%s: folha passa da base" % world_id)
	var list := main.find_child("PlacesList", true, false) as Control
	_check(list != null and list.get_child_count() > 0, "%s: lista vazia" % world_id)
	for row: Node in list.get_children():
		_check(absf((row as Control).size.x - list.size.x) < 0.5, "%s: linha %s com largura diferente" % [world_id, row.name])
		_check((row as Control).size.y >= 56.0, "%s: linha %s baixa" % [world_id, row.name])
		var tap := row.find_child("PlaceGo", true, false) as Control
		_check(tap != null and tap.size.y >= 44.0, "%s: alvo de %s menor que 44" % [world_id, row.name])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "places_shots_descartavel.json"))
	var state: Node = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("progress").owned.erase("orchard")
	for world_id: String in ["farm", "village", "park"]:
		main.call("_on_world_requested", world_id, "")
		main.call("show_screen", &"map")
		await create_timer(1.5).timeout
		_hide_modals()
		_audit_map(world_id)
		await _save(world_id + "_mapa")
		(main.find_child("PlacesButton", true, false) as Button).pressed.emit()
		await create_timer(0.5).timeout
		_audit_sheet(world_id)
		await _save(world_id + "_lugares")
		root.get_node("Events").emit_signal("sheet_close_requested")
		await create_timer(0.3).timeout
	print("PLACES SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)
