extends SceneTree
## Caminhos externos: limites, canteiros e obstáculos desenhados no fundo.

var failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, context: String) -> void:
	if not ok:
		failures += 1
		push_error("Navegação: " + context)


func polygon(values: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for value: Array in values:
		result.append(Vector2(value[0], value[1]))
	return result


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.call("reset")
	seed(2718)
	for id: String in ["house", "farm", "village", "nature"]:
		var room: Control = load("res://scenes/levels/room/room.tscn").instantiate()
		room.set("room_id", id)
		room.set_anchors_preset(Control.PRESET_TOP_LEFT)
		room.size = Vector2(360, 650)
		root.add_child(room)
		var dog: Node2D = room.get("_dog")
		check(dog != null, id + ": Tiro deve aparecer")
		var data: Dictionary = root.get_node("Database").call("room", id)
		var floor_area := polygon(data.floor)
		var blocked: Array[PackedVector2Array] = []
		for obstacle: Dictionary in data.get("obstacles", []):
			blocked.append(polygon(obstacle.polygon))
		for region: Dictionary in data.get("regions", []):
			if room.call("region_error", region) != "":
				blocked.append(polygon(region.polygon))
		for object: Dictionary in data.get("objects", []):
			if object.has("footprint") and not object.has("upgrade"):
				blocked.append(polygon(object.footprint))
		var start := dog.position
		var destinations: Array[Vector2] = []
		for attempt in 100:
			var target: Vector2 = room.call("random_floor_point", start)
			var path: PackedVector2Array = room.call("find_path", start, target)
			check(not path.is_empty(), id + ": destino sorteado deve ser alcançável")
			if not destinations.has(target):
				destinations.append(target)
			for i in range(1, path.size()):
				var steps := maxi(1, ceili(path[i - 1].distance_to(path[i])))
				for step in range(steps + 1):
					var sample := path[i - 1].lerp(path[i], float(step) / steps)
					check(Geometry2D.is_point_in_polygon(sample, floor_area), id + ": caminho saiu do chão")
					for area in blocked:
						check(not Geometry2D.is_point_in_polygon(sample, area), id + ": caminho atravessou obstáculo")
			start = target
		check(destinations.size() > 20, id + ": precisa de espaço para passear")
		if id != "house":
			check(dog.get("bowl_point") == Vector2.INF, id + ": não existe tigela")
			state.call("set_sleeping", true)
			await create_timer(0.1).timeout
			check(dog.position.is_equal_approx(room.call("nearest_floor_point", Vector2(data.points.dog_start[0], data.points.dog_start[1]))), id + ": deve dormir no chão sem ir à origem")
			state.call("set_sleeping", false)
			# Sem rota: _go_to precisa parar, sem acrescentar o alvo cru.
			var walkable: Array = room.get("_walkable")
			walkable.clear()
			var before := dog.position
			await dog.call("_go_to", Vector2.ZERO)
			check(dog.position == before, id + ": sem caminho não pode atravessar direto")
		room.queue_free()
		await process_frame
	if failures == 0:
		print("NAVIGATION TEST: PASS")
	quit(1 if failures else 0)
