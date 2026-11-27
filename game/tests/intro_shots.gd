extends SceneTree
## Capturas da abertura por gestos (caixinha, carinho na cabeça, Tiro fora). NÃO é teste.
## Rodar SEM --headless: & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/intro_shots.gd
## PNGs em build/screenshots/intro_gestos/. Imprime FAIL se algo sair da tela, alvo < 44, texto cortado,
## houver botão na abertura ou a mão cobrir a caixinha/cabeça de um jeito que atrapalhe.

const FOLDER := "res://../build/screenshots/intro_gestos/"
var main: Control
var intro: Node
var guide: Control
var failures := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _wait(seconds: float = 0.5) -> void:
	await create_timer(seconds).timeout
	await process_frame


func _pointer(at: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.position = at
	event.global_position = at
	root.push_input(event, true)


func _move(from: Vector2, to: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = to
	event.global_position = to
	event.relative = to - from
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event, true)


func _rect(node_name: String) -> Rect2:
	var node := intro.find_child(node_name, true, false) as Control
	return node.get_global_rect() if node != null and node.is_visible_in_tree() else Rect2()


## Foto + conferências da tela da abertura. `target` = nome do alvo da mão neste passo.
func _save(shot_name: String, target: String, hand_expected: bool, pause: float = 0.6) -> void:
	await _wait(pause)
	await RenderingServer.frame_post_draw
	var screen := Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var card := intro.find_child("IntroCard", true, false) as Control
	_check(card != null and screen.encloses(card.get_global_rect()), "%s: cartão da Laís fora da tela" % shot_name)
	var buttons := intro.find_children("*", "Button", true, false).filter(func(b: Node) -> bool: return (b as Control).is_visible_in_tree())
	_check(buttons.is_empty(), "%s: a abertura não pode ter botão" % shot_name)
	var text := intro.get("_text") as Label
	_check(text.get_line_count() <= text.get_visible_line_count() and text.get_minimum_size().y <= text.size.y + 1.0, "%s: texto da Laís cortado" % shot_name)
	var stage := intro.find_child("ArrivalStage", true, false) as Control
	_check(stage.get_global_rect().end.y <= card.get_global_rect().position.y + 1.0, "%s: o palco encosta no cartão" % shot_name)
	var area := _rect(target)
	_check(area.has_area() and screen.encloses(area) and area.size.x >= 44.0 and area.size.y >= 44.0, "%s: alvo %s fora da tela ou menor que 44 px (%s)" % [shot_name, target, str(area)])
	if target == "ArrivalHead":
		_check(area.size.x >= 88.0, "%s: cabeça com menos de 88 px de largura" % shot_name)
	var hint := guide.find_child("WeekTutorialHint", true, false) as Control
	_check(hint == null or not hint.is_visible_in_tree(), "%s: o balão da mão cobre a cena" % shot_name)
	var hand := guide.get("_hand") as Control
	_check(hand.visible == hand_expected, "%s: mão %s" % [shot_name, "deveria aparecer" if hand_expected else "deveria estar escondida"])
	if hand.visible:
		_check(screen.encloses(hand.get_global_rect()), "%s: mão fora da tela" % shot_name)
		_check(str(guide.get("active")) == "arrival", "%s: lição da abertura não está ativa" % shot_name)
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "%s_%dx%d.png" % [shot_name, image.get_width(), image.get_height()])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", str(load("res://scripts/util/build_info.gd").call("data_dir")) + "intro_gestos_descartavel.json")
	var state: Node = root.get_node("GameState")
	state.call("reset")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _wait(1.5)
	intro = main.get("_intro")
	guide = main.find_child("WeekTutorial", true, false) as Control
	if intro == null:
		print("FAIL: a abertura não abriu")
		quit(1)
		return
	# a) Caixinha fechada com a mão pedindo o toque.
	await _save("a_caixinha", "ArrivalBox", true)
	# Toque real na caixinha: ela abre e as orelhinhas aparecem.
	var at := _rect("ArrivalBox").get_center()
	_pointer(at, true)
	_pointer(at, false)
	await _wait(0.2)
	_check(int(intro.get("_index")) == 1, "o toque na caixinha não abriu")
	# b) Orelhinhas e a mão esfregando a cabeça.
	await _save("b_orelhinhas", "ArrivalHead", true)
	# c) Meio do carinho: o dedo passa na cabeça, corações saem e o Tiro sobe.
	var head := _rect("ArrivalHead")
	var finger := head.get_center()
	_pointer(finger, true)
	var sign := 1.0
	for i in 8:
		var next := Vector2(finger.x + 60.0 * sign, _rect("ArrivalHead").get_center().y)
		_move(finger, next)
		finger = next
		sign = -sign
		await process_frame
	await _wait(0.1)
	_check(float(intro.get("_goal")) > 0.28 and float(intro.get("_goal")) < 1.0, "o carinho não revelou parte do Tiro (%s)" % str(intro.get("_goal")))
	await _save("c_carinho", "ArrivalHead", false, 0.05)
	# Termina de esfregar: ele sai.
	for i in 12:
		var next := Vector2(finger.x + 60.0 * sign, _rect("ArrivalHead").get_center().y)
		_move(finger, next)
		finger = next
		sign = -sign
		await process_frame
	_pointer(finger, false)
	await _wait(0.3)
	_check(int(intro.get("_index")) == 2, "o carinho não fez o Tiro sair")
	# d) Ele saiu, a mão pede o toque no Tiro.
	await _save("d_saiu", "ArrivalTiro", true)
	print("INTRO SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(failures)
