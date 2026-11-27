extends SceneTree
## Capturas do Tiro parado ATRÁS de cada construção/recorte do Sítio (tudo comprado). NÃO é teste.
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/farm_behind_shots.gd
## PNGs em build/screenshots/farm_behind/<desenho>.png (o Tiro dorme no lugar para não sair andando).

var main: Control
const TARGETS := ["cut_casa", "cut_banca", "cut_tree_1", "cut_tree_2", "cut_bridge_post_2", "silo", "warehouse", "cow_barn", "chicken_coop", "mill", "dairy", "greenhouse"]


func _initialize() -> void:
	_run.call_deferred()
	create_timer(240).timeout.connect(func() -> void: quit(1))


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.reset()
	state.progress.seen.intro = true
	state.progress.seen["npc_intro:bloblo"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i in 30: await process_frame
	state.dev_unlock_everything()
	state.call("finish_fishing_tutorial")
	state.set("unlocked_plots", 9)
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await create_timer(1.5).timeout
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer: (node as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var room: Control = main.find_child("World_farm", true, false)
	var nav: AStarGrid2D = room.get("_nav")
	var dog: Node2D = room.get("_dog")
	state.dog.sleeping = true  # parado no lugar
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/farm_behind/")
	DirAccess.make_dir_recursive_absolute(folder)
	for target: String in TARGETS:
		var sprite := room.find_child(target, true, false) as Sprite2D
		if sprite == null or not sprite.visible:
			continue
		var footprint: PackedVector2Array = sprite.get_meta("depth_footprint")
		# célula andável atrás da base onde o desenho cobre mais o corpo do Tiro
		var best := Vector2.INF
		var best_hits := 0
		for cell: Vector2i in room.get("_walkable"):
			var p := nav.get_point_position(cell)
			if p.y > float(room.call("_front_y", footprint, p.x)) - 10.0:
				continue
			var hits := 0
			for fx: float in [0.2, 0.5, 0.8]:
				for fy: float in [0.2, 0.5, 0.8]:
					var local := (Vector2(p.x - 12 + 24 * fx, p.y - 34 + 34 * fy) - sprite.position) / sprite.scale
					if sprite.get_rect().has_point(local) and sprite.is_pixel_opaque(local): hits += 1
			if hits > best_hits and hits < 9:  # meio coberto: dá para ver que ele está atrás
				best_hits = hits
				best = p
		if best == Vector2.INF:
			print("sem posição atrás de ", target)
			continue
		dog.position = best
		room.call("recenter")
		await create_timer(0.3).timeout
		var there: Vector2 = room.call("world_to_screen", best)
		room.call("scroll_by", there - Vector2(180, 400))
		await create_timer(0.4).timeout
		room.call("zoom_to", Vector2(180, 400), 1.8, 0.01)
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder + target + ".png")
		print("atrás de ", target, " em ", best, " (z ", dog.z_index, ")")
	quit(0)
