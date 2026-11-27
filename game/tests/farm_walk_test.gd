extends SceneTree
## Sítio: chão andável todo conectado, destinos alcançáveis e personagens que nunca pisam em obstáculo, em três estados
## (começo, áreas abertas sem construções, tudo comprado). Usa o motor de verdade (RoomView/_nav/DogWorld/NpcWorld).
## Rodar: powershell -ExecutionPolicy Bypass -File tools\run_godot_test.ps1 farm_walk_test
## Com "-- --shots" (sem --headless) grava os rastros em build/screenshots/farm_walk/walk_<estado>.png
## (vermelho = bloqueado dentro do chão, amarelo = trajetos testados, laranja = passeio do Tiro, azul = passeio dos NPCs).

var failures := 0
var shots := "--shots" in OS.get_cmdline_user_args()
var state: Node
var main: Control
const BUILDINGS := ["silo", "warehouse", "workbench", "greenhouse", "orchard", "chicken_coop", "cow_barn", "mill", "dairy"]
const WALK_SECONDS := 20.0  # passeio livre (tempo real) por estado


func _initialize() -> void:
	_run.call_deferred()
	create_timer(280, true, false, true).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FARM WALK: " + message)


func settle(frames := 12) -> void:
	for i: int in frames:
		await process_frame


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
	return main.find_child("World_farm", true, false) as Control


## Mesmo teste de ponto-no-polígono do motor (à prova do erro do Geometry2D com vértices). O script da sala só é
## tocado depois que os autoloads existem (carregar antes quebra a compilação dele).
var _script: GDScript


func _inside(point: Vector2, poly: PackedVector2Array) -> bool:
	if _script == null:
		_script = _room().get_script()
	return _script.call("point_in_polygon", point, poly)


func _box(poly: PackedVector2Array) -> Rect2:
	var box := Rect2(poly[0], Vector2.ZERO)
	for v in poly:
		box = box.expand(v)
	return box


## Primeiro polígono ativo que contém o ponto (com filtro pela caixa), ou -1.
func _hit(point: Vector2, polys: Array[PackedVector2Array], boxes: Array[Rect2]) -> int:
	for j: int in polys.size():
		if boxes[j].has_point(point) and _inside(point, polys[j]):
			return j
	return -1


func _poly(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Array in points:
		out.append(Vector2(p[0], p[1]))
	return out


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.reset()
	state.progress.seen.intro = true
	state.progress.seen["npc_intro:bloblo"] = true
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await settle()
	_hide_modals()

	# 1) Começo de jogo: áreas futuras fechadas (cercas), nada construído.
	state.call("dev_grant_upgrade", "farm")
	await _enter()
	await _audit("a_comeco")

	# 2) Tudo liberado pela história, mas nenhuma construção comprada (lotes abertos).
	state.dev_unlock_everything()
	state.call("finish_fishing_tutorial")
	for id: String in BUILDINGS:
		state.progress.owned.erase(id)
	state.set("unlocked_plots", 4)
	await settle(30)
	await _audit("b_aberto")

	# 3) Tudo comprado, com animais.
	state.dev_unlock_everything()
	state.set("unlocked_plots", 9)
	for i in 3:
		state.call("buy_animal", "chicken_brown")
		state.call("buy_animal", "cow_brown")
	await settle(30)
	await _audit("c_tudo")

	print("FARM WALK: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _enter() -> void:
	main.call("_on_world_requested", "farm", "")
	main.call("show_screen", &"map")
	await settle(30)
	_hide_modals()
	await settle()


func _audit(tag: String) -> void:
	var room := _room()
	check(room != null, tag + ": sala do Sítio aberta")
	if room == null:
		return
	room.call("_build_navigation")  # garante a navegação do estado atual
	var t0 := Time.get_ticks_usec()
	room.call("_build_navigation")
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("FARM WALK %s: montar a navegação levou %.0f ms" % [tag, ms])
	var nav: AStarGrid2D = room.get("_nav")
	var walkable: Array = room.get("_walkable")
	var data: Dictionary = room.get("_room")
	check(walkable.size() > 3000, tag + ": chão andável grande (%d células)" % walkable.size())

	# --- conectividade: todo chão andável alcançável a partir do primeiro ---
	var start: Vector2i = room.call("_nearest_walkable", Vector2(data.points.dog_start[0], data.points.dog_start[1]))
	var reached := {start: true}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if nav.is_in_boundsv(n) and not nav.is_point_solid(n) and not reached.has(n):
				reached[n] = true
				stack.append(n)
	var loose: Array = []
	for cell: Vector2i in walkable:
		if not reached.has(cell):
			loose.append(cell)
	check(loose.is_empty(), "%s: %d células de chão isoladas (ex.: %s)" % [tag, loose.size(), str(loose.slice(0, 6))])

	# --- destinos: pontos, montinhos e aproximações dos objetos visíveis ficam no chão alcançável ---
	var targets := {}
	for key: String in data.points:
		if key.begins_with("fishing_bubble_") or key == "fishing_pier" or not (data.points[key] is Array):
			continue
		targets["ponto " + key] = data.points[key]
	for i: int in data.get("dig_spots", []).size():
		targets["montinho %d" % i] = data.dig_spots[i]
	for obj: Dictionary in data.objects:
		if not obj.has("approach"):
			continue
		var sprite := room.find_child(str(obj.id), true, false) as CanvasItem
		if sprite != null and not sprite.visible:
			continue
		targets["aproximação " + str(obj.id)] = obj.approach
	for label: String in targets:
		var p := Vector2(targets[label][0], targets[label][1])
		var cell: Vector2i = room.call("_nearest_walkable", p)
		var gap := nav.get_point_position(cell).distance_to(p)
		check(reached.has(cell), "%s: %s fora do chão alcançável" % [tag, label])
		check(gap <= 12.0, "%s: %s a %.0f px do chão andável (%s)" % [tag, label, gap, str(p)])

	# --- o que está bloqueado AGORA, igual ao motor: obstáculos, áreas fechadas e bases dos objetos presentes ---
	var active: Array[PackedVector2Array] = []
	var names: Array[String] = []
	for ob: Dictionary in data.get("obstacles", []):
		active.append(_poly(ob.polygon))
		names.append(str(ob.id))
	for region: Dictionary in data.get("regions", []):
		if str(room.call("region_error", region)) != "":
			active.append(_poly(region.polygon))
			names.append("área fechada " + str(region.id))
	for obj: Dictionary in data.objects:
		if not obj.has("footprint"):
			continue
		if obj.has("animal_station") and int(obj.animal_slot) >= int(state.call("animal_count", obj.animal_station)):
			continue
		if obj.has("upgrade") and not state.call("has_upgrade", obj.upgrade):
			continue
		if obj.has("requirements") and str(state.call("requirement_error", obj.requirements)) != "":
			continue
		if bool(room.call("_replaced", obj.get("hidden_by", []))):
			continue
		active.append(_poly(obj.footprint))
		names.append("base de " + str(obj.id))
	var floor_area := _poly(data.floor)
	var boxes: Array[Rect2] = []
	for poly in active:
		boxes.append(_box(poly))

	# --- trajetos: os mesmos caminhos que o Tiro e os NPCs pedem à sala, conferidos a cada 2 px ---
	var dog: Node = room.get("_dog")
	var trails := {}
	var bad := {}
	var routes: Array = []
	var start_point := nav.get_point_position(start)
	for label: String in targets:
		routes.append([start_point, Vector2(targets[label][0], targets[label][1])])
	seed(7)
	for i in 160:
		routes.append([nav.get_point_position(walkable.pick_random()), nav.get_point_position(walkable.pick_random())])
	var samples := 0
	var no_path := 0
	for r: Array in routes:
		var path: PackedVector2Array = room.call("find_path", r[0], r[1])
		if path.is_empty():
			no_path += 1
			continue
		if is_instance_valid(dog):
			path = dog.call("_simplify", path)
		var line := PackedVector2Array()
		for i: int in range(1, path.size()):
			var a: Vector2 = path[i - 1]
			var b: Vector2 = path[i]
			var steps := maxi(1, int(a.distance_to(b) / 4.0))
			for k in steps + 1:
				var q := a.lerp(b, float(k) / steps)
				line.append(q)
				samples += 1
				var problem := ""
				if not _inside(q, floor_area):
					problem = "fora do chão"
				else:
					var j := _hit(q, active, boxes)
					if j >= 0:
						problem = "dentro de %s %s (trecho %s → %s)" % [names[j], str(boxes[j]), str(a), str(b)]
				if problem != "" and not bad.has(problem):
					bad[problem] = true
					check(false, "%s: caminho passa %s em %s" % [tag, problem, str(q.round())])
		trails["rota %d" % trails.size()] = line
	check(no_path == 0, "%s: %d trajetos sem caminho" % [tag, no_path])
	print("FARM WALK %s: %d trajetos, %d pontos conferidos, %d sem caminho" % [tag, routes.size(), samples, no_path])

	# --- sem voltas enormes: do ponto de partida até os canteiros de cima e dos lados (0 topo, 1 direita, 2 esquerda,
	# 4 e 5 pontas) o caminho é no máximo o dobro da linha reta. Os de baixo (6, 7, 8) ficam atrás da grade, do
	# caixote, do pote e da lagoa no próprio desenho: chega-se a eles pela direita, por isso ficam de fora. ---
	for obj: Dictionary in data.objects:
		if str(obj.get("action", "")) != "plot" or int(obj.plot) not in [0, 1, 2, 4, 5]:
			continue
		var goal := Vector2(obj.approach[0], obj.approach[1])
		var route: PackedVector2Array = room.call("find_path", start_point, goal)
		var length := 0.0
		for i: int in range(1, route.size()):
			length += route[i - 1].distance_to(route[i])
		var straight := maxf(start_point.distance_to(goal), 40.0)
		check(length <= straight * 2.0, "%s: caminho até %s dá volta (%.0f px para %.0f em linha reta)" % [tag, str(obj.id), length, straight])

	# --- camadas: atrás de uma construção/recorte o Tiro é desenhado por baixo; na frente, por cima ---
	if is_instance_valid(dog):
		_check_layers(tag, room, nav, walkable, dog as Node2D)

	# --- passeio livre de verdade (IA do Tiro e dos NPCs), no tempo normal ---
	if is_instance_valid(dog):
		state.dog.sleeping = false
	var walk := {}
	var until := Time.get_ticks_msec() + int(WALK_SECONDS * 1000.0)
	var next_hop := 0
	while Time.get_ticks_msec() < until:
		await process_frame
		# O recém-nascido cochila boa parte do tempo: a cada 2 s ele recebe um destino sorteado pelo mesmo caminho
		# das reações do jogo (o que o leva até a horta, a banca, a estufa...).
		if is_instance_valid(dog) and Time.get_ticks_msec() >= next_hop:
			next_hop = Time.get_ticks_msec() + 2000
			dog.call("react_at", &"happy", nav.get_point_position(walkable.pick_random()))
		var walkers: Array = []
		if is_instance_valid(dog) and (dog as Node2D).visible:
			walkers.append(["Tiro", dog])
		for npc: Node2D in room.get("_npcs"):
			if is_instance_valid(npc) and npc.visible:
				walkers.append([str(npc.get("npc_id")) if str(npc.get("npc_id")) != "" else str(npc.get("friend_id")), npc])
		for w: Array in walkers:
			var who: String = w[0]
			var p: Vector2 = (w[1] as Node2D).position
			var trail: PackedVector2Array = walk.get(who, PackedVector2Array())
			trail.append(p)
			walk[who] = trail  # PackedVector2Array é valor: precisa guardar de volta
			var problem := ""
			if not _inside(p, floor_area):
				problem = "fora do chão"
			else:
				var j := _hit(p, active, boxes)
				if j >= 0:
					problem = "dentro de " + names[j]
			if problem != "" and not bad.has(who + problem):
				bad[who + problem] = true
				check(false, "%s: %s %s em %s" % [tag, who, problem, str(p.round())])
	var moved := {}
	for who: String in walk:
		var t: PackedVector2Array = walk[who]
		var length := 0.0
		for i: int in range(1, t.size()):
			length += t[i - 1].distance_to(t[i])
		moved[who] = int(length)
		trails["IA " + who] = t
	print("FARM WALK %s: passeio livre de %.0f s, distância andada %s" % [tag, WALK_SECONDS, str(moved)])
	check(int(moved.get("Tiro", 0)) > 300, "%s: o Tiro andou pelo Sítio no passeio livre" % tag)
	if shots:
		_draw(tag, room, nav, trails)


## Para cada desenho com base no chão (construção comprada, recorte da casa/árvore/poste), o Tiro é posto em cada célula
## andável onde o desenho cobriria o corpo dele (algum pixel opaco na caixa do corpo, como o motor decide). Atrás da borda da frente da base ele
## precisa ficar por baixo (z 0 e Y menor que o do desenho, que a ordenação por Y põe antes); na frente, por cima.
func _check_layers(tag: String, room: Control, nav: AStarGrid2D, walkable: Array, dog: Node2D) -> void:
	var world: Node2D = dog.get_parent()
	check(world.y_sort_enabled, tag + ": o mundo ordena por Y")
	var keep := dog.position
	dog.set_process(false)
	var behind_total := 0
	var front_total := 0
	var taps := 0
	var report := {}
	for sprite: Sprite2D in room.get("_depth_sprites"):
		if not sprite.visible or sprite.self_modulate.a < 0.5:
			continue
		var rect := Rect2(sprite.position + sprite.offset * sprite.scale, sprite.texture.get_size() * sprite.scale)
		var footprint: PackedVector2Array = sprite.get_meta("depth_footprint")
		var behind := 0
		var front := 0
		var tall := 34.0 * float(room.get("_room").get("dog_scale", 1.0)) / 0.7
		for cell: Vector2i in walkable:
			var p := nav.get_point_position(cell)
			var body := Rect2(p.x - 12.0, p.y - tall, 24.0, tall)
			if not rect.intersects(body) or not room.call("_covers", sprite, body):
				continue  # o desenho não cobre o corpo aqui
			dog.position = p
			room.call("_sort_walkers")
			var front_y: float = room.call("_front_y", footprint, p.x)
			if p.y <= front_y:
				behind += 1
				var hidden := dog.z_index == 0 and p.y < sprite.position.y
				if not hidden:
					check(false, "%s: Tiro por cima de %s estando atrás dele em %s (z %d)" % [tag, sprite.name, str(p), dog.z_index])
				# tocar num ponto do corpo dele que o desenho cobre é tocar no desenho, não no Tiro
				for fx: float in [0.3, 0.5, 0.7]:
					for fy: float in [0.3, 0.6]:
						var q := Vector2(body.position.x + body.size.x * fx, body.position.y + body.size.y * fy)
						var lq := (q - sprite.position) / sprite.scale
						if dog.call("hit_test", q) and sprite.get_rect().has_point(lq) and sprite.is_pixel_opaque(lq):
							taps += 1
							if room.call("_walker_hit", dog, q):
								check(false, "%s: toque em %s (escondendo o Tiro) foi para o Tiro em %s" % [tag, sprite.name, str(q)])
			else:
				front += 1
				if not (dog.z_index == 1 or p.y > sprite.position.y):
					check(false, "%s: Tiro por baixo de %s estando na frente em %s" % [tag, sprite.name, str(p)])
		behind_total += behind
		front_total += front
		if behind > 0:
			report[str(sprite.name)] = behind
	dog.position = keep
	room.call("_sort_walkers")
	dog.set_process(true)
	print("FARM WALK %s: camadas conferidas, %d posições atrás e %d na frente, %d toques no desenho; atrás de: %s" % [tag, behind_total, front_total, taps, str(report)])


func _draw(tag: String, room: Control, nav: AStarGrid2D, trails: Dictionary) -> void:
	var image: Image = (room.get("_background") as TextureRect).texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var floor_area := _poly(room.get("_room").floor)
	var red := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	red.fill(Color(1, 0.05, 0.05, 0.45))
	for cx in nav.region.size.x:
		for cy in nav.region.size.y:
			if nav.is_point_solid(Vector2i(cx, cy)) and _inside(Vector2(cx * 8 + 4, cy * 8 + 4), floor_area):
				image.blend_rect(red, Rect2i(0, 0, 8, 8), Vector2i(cx * 8, cy * 8))
	for who: String in trails:
		var color := Color(1, 0.9, 0) if who.begins_with("rota") else (Color(1, 0.4, 0) if who == "IA Tiro" else Color(0.1, 0.5, 1))
		for p: Vector2 in trails[who]:
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					var q := Vector2i(int(p.x) + dx, int(p.y) + dy)
					if Rect2i(Vector2i.ZERO, image.get_size()).has_point(q):
						image.set_pixelv(q, color)
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/farm_walk/")
	DirAccess.make_dir_recursive_absolute(folder)
	image.save_png(folder + "walk_%s.png" % tag)
