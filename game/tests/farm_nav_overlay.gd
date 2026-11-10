extends SceneTree
## Desenha por cima da cena do Sítio onde o motor deixa o Tiro e os NPCs andarem. NÃO é teste.
## Rodar com janela (não precisa ser headless):
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/farm_nav_overlay.gd -- --out=farm_nav
## PNGs em build/screenshots/<out>/nav_<estado>.png: vermelho = bloqueado dentro do chão; sem cor = anda; pontos = Tiro (vermelho)/NPCs (azul).
## Estados: "a_inicio" (nada construído, áreas fechadas) e "b_tudo" (tudo construído).

var state: Node
var main: Node
var folder := "res://../build/screenshots/farm_nav/"
const BUILDINGS := ["silo", "warehouse", "workbench", "greenhouse", "orchard", "chicken_coop", "cow_barn", "mill", "dairy"]


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(200).timeout.connect(func() -> void: quit(1))


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])


func _room() -> Control:
	for view: Node in get_nodes_in_group("room_views"):
		if view.get("room_id") == "farm":
			return view as Control
	return null


func _overlay(shot_name: String) -> void:
	var room := _room()
	var nav: AStarGrid2D = room.get("_nav")
	var content: Control = room.get("_content")
	var texture: Texture2D = (room.get("_background") as TextureRect).texture
	var image := texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var cell := 8
	var red := Color(1.0, 0.05, 0.05, 0.5)
	var floor_poly := PackedVector2Array()
	for point: Array in room.get("_room")["floor"]:
		floor_poly.append(Vector2(point[0], point[1]))
	for cx in nav.region.size.x:
		for cy in nav.region.size.y:
			var center := Vector2(cx * cell + 4, cy * cell + 4)
			# vermelho = bloqueado dentro do chão da ilha (fora dele não interessa)
			if nav.is_point_solid(Vector2i(cx, cy)) and Geometry2D.is_point_in_polygon(center, floor_poly):
				image.blend_rect(_block(red), Rect2i(0, 0, cell, cell), Vector2i(cx * cell, cy * cell))
	var dog: Node2D = room.get("_dog")
	_dot(image, dog.position, Color(1, 0, 0))
	for npc: Node2D in room.get("_npcs"):
		_dot(image, npc.position, Color(0.1, 0.3, 1))
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	image.save_png(path + "nav_%s.png" % shot_name)
	print("overlay ", shot_name, " ", content.size)


var _cache: Image


func _block(color: Color) -> Image:
	if _cache == null:
		_cache = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		_cache.fill(color)
	return _cache


func _dot(image: Image, at: Vector2, color: Color) -> void:
	for dx in range(-6, 7):
		for dy in range(-6, 7):
			var p := Vector2i(int(at.x) + dx, int(at.y) + dy)
			if Rect2i(0, 0, image.get_width(), image.get_height()).has_point(p):
				image.set_pixelv(p, color)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "farm_nav_overlay_descartavel.json"))
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	_hide_modals()
	state.call("dev_unlock_everything")
	for id: String in BUILDINGS:
		state.get("progress").owned.erase(id)
	state.set("unlocked_plots", 4)
	await create_timer(0.5).timeout
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await create_timer(1.2).timeout
	_hide_modals()
	_overlay("a_inicio")
	state.call("dev_unlock_everything")
	state.set("unlocked_plots", 9)
	await create_timer(1.0).timeout
	_overlay("b_tudo")
	quit(0)
