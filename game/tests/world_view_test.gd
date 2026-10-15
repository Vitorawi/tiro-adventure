extends SceneTree
## Etapa 04 da interface nova: mundos em tela cheia. Fundo (céu/chão/paisagem) cobrindo a tela, enquadramento
## inicial por mundo, zoom mínimo, arrasto elástico e com inércia, duplo toque, botão de centralizar (sem +/−),
## barra do mundo (pílula + lugares + rostos), etiquetas que não cortam e painel que sobe o objeto.
## `Motion.reduced` fica ligado para a câmera chegar ao destino na hora.

var failures: int = 0
var state: Node
var main: Control
var worlds: Control


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("WORLD_VIEW: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	Motion.reduced = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	_hide_modals()
	worlds = main.find_child("WorldsScreen", true, false)
	await _backdrops()
	await _framing()
	await _camera()
	await _taps()
	await _world_bar()
	await _labels()
	await _sheet_lift()
	Motion.reduced = false
	print("WORLD_VIEW TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	state.get("progress").seen["intro"] = true


func _enter(world_id: String) -> Control:
	main.call("_on_world_requested", world_id, "")
	main.call("show_screen", &"map")
	for i in 4:
		await process_frame
	return main.find_child("World_" + world_id, true, false)


## Posição do ponto da sala (coordenadas do fundo) na tela da sala.
func _on_screen(room: Control, point: Vector2) -> Vector2:
	return (room.get("_content") as Control).position + point * float(room.get("_zoom"))


func _backdrops() -> void:
	for id: String in ["house", "farm", "park", "village", "nature"]:
		var room := await _enter(id)
		var backdrop: Control = room.get_node("Backdrop")
		check(backdrop.size.is_equal_approx(room.size) and room.size.x > 0.0, id + ": o fundo cobre a tela toda")
		var sky: Control = room.get_node("%Sky")
		check(sky.visible and sky.texture != null, id + ": existe o céu")
		check(not (room.get_node("Backdrop/Void") as Control).visible, id + ": nada de vazio escuro")
		var ground: Control = room.get_node("%Ground")
		check(ground.visible and is_equal_approx(ground.position.y, sky.size.y), id + ": chão começa onde o céu termina")
		check(ground.position.y + ground.size.y >= room.size.y - 0.5, id + ": o chão vai até embaixo")
		check(is_equal_approx(sky.size.x, room.size.x) and is_equal_approx(ground.size.x, room.size.x), id + ": céu e chão têm a largura da tela")
		var far: Control = room.get_node("%Far")
		check(far.visible == (id != "house"), id + ": paisagem ao longe só nos mundos abertos")
		if far.visible:
			check(far.position.x <= 0.5 and far.position.x + far.size.x >= room.size.x - 0.5, id + ": a paisagem cobre a largura")
		var clouds: Array = room.get("_clouds")
		check((id in ["house"]) == clouds.is_empty(), id + ": nuvens só onde o fundo pede")
	# Mundo sem "backdrop" no JSON: comportamento antigo (cor escura).
	var plain: Control = (load("res://scenes/levels/room/room.tscn") as PackedScene).instantiate()
	plain.set("room_id", "house")
	plain.set("_room", {})
	check(not bool(plain.get("_has_backdrop")), "sala sem backdrop não liga o fundo novo")
	plain.free()
	# Nuvens andam para a direita e voltam pela esquerda.
	var park: Control = await _enter("park")
	var cloud: Sprite2D = (park.get("_clouds") as Array)[0]
	var before := cloud.position.x
	park.call("_drift_clouds", 1.0)
	check(cloud.position.x > before, "nuvem anda para a direita")
	cloud.position.x = park.size.x + 10.0
	park.call("_drift_clouds", 0.01)
	check(cloud.position.x < 0.0, "nuvem volta pela esquerda")


func _framing() -> void:
	var farm := await _enter("farm")
	check(is_equal_approx(float(farm.get("_zoom")), 1.0), "Sítio abre com zoom 1,0")
	var inside := true
	for index in 9:
		var plot: Sprite2D = farm.find_child("plot_%d" % index, true, false)
		var at := _on_screen(farm, plot.position)
		inside = inside and Rect2(Vector2.ZERO, farm.size).has_point(at)
	check(inside, "os 9 canteiros da horta aparecem na tela")
	var house := await _enter("house")
	var dog: Node2D = house.get("_dog")
	check(dog != null and Rect2(Vector2.ZERO, house.size).has_point(_on_screen(house, dog.position)), "Casa: o Tiro está dentro da tela")
	var content: Control = house.get("_content")
	check(content.size.x * float(house.get("_zoom")) <= house.size.x + 0.5 and absf(content.size.x * float(house.get("_zoom")) - house.size.x) < 1.0, "Casa: a maquete ocupa a largura")
	for id: String in ["park", "village"]:
		var room := await _enter(id)
		check(float(room.get("_zoom")) >= 0.8 and float(room.get("_zoom")) <= 0.9, id + ": zoom entre 0,8 e 0,9")
	var nature := await _enter("nature")
	check(is_equal_approx(float(nature.get("_zoom")), nature.size.x / (nature.get("_content") as Control).size.x), "Natureza: framing width")
	for id: String in ["house", "farm", "park", "village", "nature"]:
		var room := await _enter(id)
		check(float(room.call("_min_zoom")) <= float(room.get("_zoom")) + 0.0001, id + ": zoom mínimo não passa do inicial")
		room.call("_zoom_at", room.size / 2.0, 0.01)
		check(is_equal_approx(float(room.get("_zoom")), float(room.call("_min_zoom"))), id + ": afasta até o zoom mínimo e para")
		room.call("_zoom_at", room.size / 2.0, 99.0)
		check(is_equal_approx(float(room.get("_zoom")), 2.0), id + ": aproxima até 2,0 e para")
		room.call("recenter")
		await process_frame
		check(is_equal_approx(float(room.get("_zoom")), float(room.get("_home_zoom"))), id + ": recenter volta ao enquadramento")


func _camera() -> void:
	var farm := await _enter("farm")
	check(not (farm.get_node("ZoomControls") as Control).visible, "os botões +/− saíram")
	var recenter: Control = farm.get_node("RecenterButton")
	check(not recenter.visible, "centralizar fica escondido no começo")
	check(recenter.mouse_filter == Control.MOUSE_FILTER_STOP, "o toque no botão de centralizar não vaza para o mapa")
	farm.call("_zoom_at", farm.size / 2.0, 2.0)
	check(recenter.visible, "centralizar aparece depois de aproximar")
	farm.call("recenter")
	check(not recenter.visible, "centralizar some ao voltar")
	# Arrastar longe também mostra o botão.
	var content: Control = farm.get("_content")
	var home: Vector2 = content.position
	content.position += Vector2(-200, 0)
	farm.call("_clamp_content")
	farm.call("_camera_changed")
	check(recenter.visible, "centralizar aparece depois de arrastar 120 px ou mais")
	farm.call("recenter")
	check(content.position.is_equal_approx(home) and not recenter.visible, "centralizar devolve a posição inicial")
	# Elástico: pode passar 48 px da borda e volta ao soltar.
	farm.set("_zoom", 1.0)
	var hard: Vector2 = farm.call("_clamped_position", Vector2(500, 0), 0.0)
	var soft: Vector2 = farm.call("_clamped_position", Vector2(500, 0), 48.0)
	check(absf(soft.x - hard.x) == 48.0, "arrasto passa 48 px da borda")
	content.position = soft
	farm.call("_settle_content")
	await process_frame
	check(content.position.is_equal_approx(farm.call("_clamped_position", content.position, 0.0)), "volta ao limite ao soltar")
	# Inércia: velocidade dos últimos 80 ms; para sozinha e qualquer toque a interrompe.
	farm.call("recenter")
	var start: Vector2 = content.position
	var now := Time.get_ticks_msec()
	farm.set("_drag_samples", [[now - 30, Vector2(-8, 0)], [now - 10, Vector2(-8, 0)], [now - 500, Vector2(300, 0)]])
	farm.call("_launch_inertia")
	var velocity: Vector2 = farm.get("_velocity")
	check(velocity.x < -100.0 and is_equal_approx(velocity.x, -16.0 / 0.08), "inércia usa só os últimos 80 ms")
	for i in 6:
		farm.call("_process", 1.0 / 60.0)
	check(content.position.x < start.x, "o mundo continua deslizando depois de soltar")
	farm.call("_stop_camera")
	check(farm.get("_velocity") == Vector2.ZERO, "qualquer toque para a inércia")
	farm.set("_velocity", Vector2(-300, 0))
	for i in 240:
		farm.call("_process", 1.0 / 60.0)
		if farm.get("_velocity") == Vector2.ZERO:
			break
	check(farm.get("_velocity") == Vector2.ZERO, "a inércia desacelera até parar")
	# Zoom animado (com Motion.reduced chega na hora).
	farm.call("recenter")
	farm.call("zoom_to", farm.size / 2.0, 1.5)
	check(is_equal_approx(float(farm.get("_zoom")), 1.5), "zoom_to chega ao zoom pedido")
	farm.call("recenter")


func _tap(room: Control, at: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = at
	room.call("_gui_input", press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = at
	room.call("_gui_input", release)


## Um pixel opaco do desenho (perto do meio), em coordenadas locais do sprite: o toque é por pixel.
func _opaque_point(sprite: Sprite2D) -> Vector2:
	var rect := sprite.get_rect()
	var middle := rect.get_center()
	var best := middle
	var best_distance := INF
	for y in range(int(rect.position.y), int(rect.end.y), 2):
		for x in range(int(rect.position.x), int(rect.end.x), 2):
			var candidate := Vector2(x, y)
			if sprite.is_pixel_opaque(candidate) and candidate.distance_to(middle) < best_distance:
				best = candidate
				best_distance = candidate.distance_to(middle)
	return best * sprite.scale


func _taps() -> void:
	var farm := await _enter("farm")
	farm.call("_zoom_at", farm.size / 2.0, 0.01)
	var far_zoom := float(farm.get("_zoom"))
	# Duplo toque em área vazia (céu): aproxima.
	var empty := Vector2(10, 10)
	_tap(farm, empty)
	_tap(farm, empty + Vector2(3, 2))
	check(float(farm.get("_zoom")) > far_zoom + 0.5 and is_equal_approx(float(farm.get("_zoom")), 1.6), "duplo toque em área vazia aproxima para 1,6")
	# Duplo toque já aproximado: volta ao enquadramento inicial.
	farm.call("_double_tap", empty)
	check(is_equal_approx(float(farm.get("_zoom")), float(farm.get("_home_zoom"))), "duplo toque aproximado volta ao enquadramento")
	# Toques longe um do outro ou demorados não dão zoom.
	farm.call("_zoom_at", farm.size / 2.0, 0.01)
	var zoom_before := float(farm.get("_zoom"))
	_tap(farm, empty)
	_tap(farm, empty + Vector2(60, 0))
	check(is_equal_approx(float(farm.get("_zoom")), zoom_before), "dois toques distantes não são duplo toque")
	_tap(farm, empty)
	farm.set("_last_tap_ms", Time.get_ticks_msec() - 1000)
	_tap(farm, empty)
	check(is_equal_approx(float(farm.get("_zoom")), zoom_before), "dois toques demorados não são duplo toque")
	# Toque simples em objeto abre o painel na hora, sem esperar um segundo toque.
	farm.call("recenter")
	var bench: Sprite2D = farm.find_child("workbench", true, false)
	(farm.get("_dog") as Node2D).position = Vector2(60, 400)  # o Tiro anda pelo mundo: tira ele da frente da Bancada
	var at := _on_screen(farm, bench.position + _opaque_point(bench))
	_tap(farm, at)
	await process_frame
	check(bool(main.get_node("Sheet").call("is_open")), "toque simples na Bancada abre o painel na hora")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await process_frame


func _world_bar() -> void:
	var farm := await _enter("farm")
	var view: Control = worlds.get_node("%WorldView")
	check(is_equal_approx(view.offset_top, 0.0) and view.size.is_equal_approx(worlds.size), "o mundo vai até o topo (sem cabeçalho)")
	check(worlds.find_child("Header", true, false) == null, "o cabeçalho grande saiu")
	var holder: Control = worlds.get_node("%WorldHolder")
	check(holder.size.is_equal_approx(worlds.size), "o mundo ocupa a área toda")
	var bar: Control = worlds.find_child("WorldBar", true, false)
	check(bar != null and bar.mouse_filter == Control.MOUSE_FILTER_IGNORE, "a barra do mundo não bloqueia o arrasto")
	var pill := worlds.get_node("%MapButton") as Button
	check(pill.get_script() == load("res://scripts/ui/world_pill.gd") and pill.text == "Sítio" and pill.icon != null, "pílula mostra ícone e nome do mundo")
	check(pill.size.y >= 44.0 and pill.global_position.y >= 60.0, "pílula fica abaixo do HUD")
	var places := worlds.get_node("%PlacesButton") as Button
	check(places.text == "" and places.icon != null and places.size.x >= 44.0, "lugares é um botão de ícone de 44")
	check(worlds.get_node("%WorldTitle").text == "Sítio da Bloblo", "WorldTitle guarda o nome")
	var faces := worlds.get_node("%NpcRow")
	check(faces is VBoxContainer and faces.mouse_filter == Control.MOUSE_FILTER_IGNORE, "rostos em coluna que ignora o mouse")
	check(faces.get_child_count() >= 1 and faces.get_child(0).get_script() == load("res://scripts/ui/npc_face.gd"), "o Sítio mostra o rosto da vovó")
	var face := faces.get_child(0) as Button
	check(face.size.x >= 48.0 and face.size.y >= 48.0, "rosto tem 48 de alvo de toque")
	check(face.global_position.x + face.size.x <= worlds.size.x - 8.0, "rosto fica dentro da tela")
	# Tocar no rosto abre a conversa; a pílula abre a lista de mundos.
	pill.pressed.emit()
	check(bool(worlds.call("is_map_open")), "tocar na pílula abre a lista de mundos")
	worlds.call("enter", "farm")
	for i in 3:
		await process_frame
	# Selo: missão pronta ganha o check, nova ganha "!".
	var face_script := load("res://scripts/ui/npc_face.gd")
	var ready_face: Button = face_script.new()
	main.add_child(ready_face)
	ready_face.call("setup", "bloblo", "ready")
	check(ready_face.get_child_count() == 1 and ready_face.get_child(0) is TextureRect, "missão pronta mostra o check")
	var new_face: Button = face_script.new()
	main.add_child(new_face)
	new_face.call("setup", "bloblo", "new")
	check(new_face.get_child_count() == 1 and new_face.get_child(0) is Label and (new_face.get_child(0) as Label).text == "!", "missão nova mostra o selo")
	ready_face.queue_free()
	new_face.queue_free()
	# Troca de mundo atualiza a pílula e a cor da borda.
	await _enter("nature")
	check(pill.text == "Natureza", "pílula troca de nome com o mundo")
	check(farm != null, "sala do Sítio continua guardada")


func _labels() -> void:
	# Etiqueta que sai pela lateral é empurrada para dentro (margem de 8 px); a totalmente fora não.
	var farm := await _enter("farm")
	var tags: Array = farm.get("_labels")
	var partial := 0
	for tag: Label in tags:
		if not tag.visible:
			continue
		var width := tag.size.x
		var left: float = (farm.get("_content") as Control).position.x + tag.position.x * float(farm.get("_zoom"))
		if left < 7.5 and left + width > 0.5:
			partial += 1
		if left + width > farm.size.x - 7.5 and left < farm.size.x - 0.5:
			partial += 1
	check(partial == 0, "nenhuma etiqueta fica cortada pelas laterais (cortadas: %d)" % partial)
	# Arrastando, as etiquetas continuam inteiras.
	var content: Control = farm.get("_content")
	for dx in [-120.0, 90.0, -60.0]:
		content.position.x += dx
		farm.call("_clamp_content")
		farm.call("_camera_changed")
		partial = 0
		for tag: Label in tags:
			if not tag.visible:
				continue
			var left: float = content.position.x + tag.position.x * float(farm.get("_zoom"))
			if left < 7.5 and left + tag.size.x > 0.5:
				partial += 1
			if left + tag.size.x > farm.size.x - 7.5 and left < farm.size.x - 0.5:
				partial += 1
		check(partial == 0, "etiquetas inteiras depois de arrastar %d" % int(dx))
	farm.call("recenter")


func _sheet_lift() -> void:
	var farm := await _enter("farm")
	farm.call("recenter")
	var coop: Sprite2D = farm.find_child("chicken_coop", true, false)
	state.call("dev_add_coins", 99999)
	var middle := coop.position - Vector2(0, coop.texture.get_height() * coop.scale.y / 2.0)
	var y_before := _on_screen(farm, middle).y
	farm.call("_on_object_tapped", "place:chicken_coop", coop)
	await process_frame
	var y_after := _on_screen(farm, middle).y
	check(y_before > farm.size.y * 0.45, "o galinheiro ficaria atrás do painel (y %d)" % int(y_before))
	check(y_after < y_before, "a câmera sobe o objeto quando o painel o cobriria (y %d → %d)" % [int(y_before), int(y_after)])
	check(y_after <= farm.size.y * 0.45 + 1.0 or y_after <= y_before - 20.0, "objeto acima do painel")
	root.get_node("Events").emit_signal("sheet_close_requested")
	await process_frame
	# Objeto já no alto da tela: a câmera não mexe.
	farm.call("recenter")
	var bench: Sprite2D = farm.find_child("workbench", true, false)
	var pos_before: Vector2 = (farm.get("_content") as Control).position
	var bench_y := _on_screen(farm, bench.position).y
	if bench_y <= farm.size.y * 0.45:
		farm.call("_on_object_tapped", "place:workbench", bench)
		check((farm.get("_content") as Control).position.is_equal_approx(pos_before), "objeto no alto da tela não move a câmera")
		root.get_node("Events").emit_signal("sheet_close_requested")
	await process_frame
