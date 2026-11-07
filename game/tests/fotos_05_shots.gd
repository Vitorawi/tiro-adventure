extends SceneTree
## Etapa 05: capturas com fixtures de resultado; nenhuma escrita no save pessoal.
var folder := "fotos_05"
var failures := 0
var state: Node
var viewer_script: GDScript
var reveal_script: GDScript

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.substr(6)
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))

func _fail(message: String) -> void:
	failures += 1
	print("FAIL ", message)

func _grab(label: String, viewer: Control) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	_measure(viewer, label)
	var path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + label + ".png")

func _measure(viewer: Control, name: String) -> void:
	var screen := root.get_visible_rect()
	var card: Rect2 = viewer.call("card_rect")
	if absf(card.size.x - card.size.y) > 0.5:
		_fail("%s: carta não quadrada %s" % [name, card.size])
	if card.size.x > screen.size.x * 0.78 + 1.0:
		_fail("%s: carta maior que 78%% da largura" % name)
	var greens := 0
	for node in viewer.find_children("*", "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.get_parent() is SubViewport:
			continue
		if control.is_ancestor_of(viewer.find_child("CardStage", true, false)):
			continue
		var in_stage := false
		var up: Node = control
		while up != null and up != viewer:
			if up is SubViewport or up.name == "CardSurface":
				in_stage = true
			up = up.get_parent()
		if in_stage:
			continue
		var rect := control.get_global_rect()
		if rect.size.x > 0.0 and rect.size.y > 0.0 and not screen.grow(1.0).encloses(rect) and control.name not in ["Dim", "Column"]:
			_fail("%s: %s sai da tela %s" % [name, control.name, rect])
		if (control is Button or control.has_meta("card_touch_target")) and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and (rect.size.y < 43.5 or rect.size.x < 43.5):
			_fail("%s: alvo pequeno %s %s" % [name, control.name, rect.size])
		if control is Label and not (control as Label).text.is_empty():
			var label := control as Label
			if label.get_minimum_size().y > label.size.y + 1.0 or (label.autowrap_mode == TextServer.AUTOWRAP_OFF and label.get_minimum_size().x > label.size.x + 1.0):
				_fail("%s: texto cortado %s" % [name, control.name])
		if control is NinePatchRect:
			var transform := control.get_global_transform()
			if absf(transform.x.length() / transform.y.length() - 1.0) > 0.01:
				_fail("%s: moldura distorcida %s" % [name, control.name])
		if control is TextureRect and (control as TextureRect).texture != null and (control as TextureRect).stretch_mode == TextureRect.STRETCH_SCALE:
			var source := (control as TextureRect).texture.get_size()
			if absf((rect.size.x / rect.size.y) / (source.x / source.y) - 1.0) > 0.01:
				_fail("%s: imagem distorcida %s" % [name, control.name])
		if control is Button and control.has_meta("wood_primary"):
			greens += 1
	if greens > 1:
		_fail("%s: %d botões verdes" % [name, greens])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	saver.set("_save_path", "user://fotos05_discard.json")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	viewer_script = load("res://scripts/ui/card_viewer.gd")
	reveal_script = load("res://scripts/ui/card_reveal.gd")
	var bg := ColorRect.new()
	bg.color = Color("6b8f5a")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	Motion.reduced = false
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_reset_album()
	state.dev_seal_photo("h_arrival")
	var viewer: Control = reveal_script.call("open", "h_arrival", {"host": root})
	await create_timer(0.4).timeout
	await _grab("01_verso", viewer)
	viewer.get_node("CardReveal").call("_open_card")
	await create_timer(0.12).timeout
	await _grab("02_virando", viewer)
	await create_timer(1.4).timeout
	viewer.call("close")
	await process_frame
	for level in [1, 2, 3, 4]:
		state.dev_reset_album()
		state.dev_take_photo("h_arrival", level)
		state.coins = 1000
		viewer = viewer_script.call("open", "h_arrival", {"host": root})
		reveal_script.call("play_result", "h_arrival", {"rolled": level, "new_variant": true, "action": "open"})
		await create_timer(0.53).timeout
		await _grab("nivel_%d_festa" % level, viewer)
		await create_timer(0.22).timeout
		await _grab("nivel_%d_luz" % level, viewer)
		await create_timer(0.6).timeout
		await _grab("nivel_%d_final" % level, viewer)
		viewer.call("close")
		await process_frame
	state.dev_reset_album()
	state.dev_take_photo("h_arrival", 2)
	viewer = viewer_script.call("open", "h_arrival", {"host": root})
	reveal_script.call("play_result", "h_arrival", {"rolled": 2, "new_variant": false, "action": "reroll"})
	await create_timer(0.85).timeout
	await _grab("repetida", viewer)
	await create_timer(0.8).timeout
	viewer.call("close")
	await process_frame
	Motion.reduced = true
	state.dev_seal_photo("f_bath")
	viewer = reveal_script.call("open", "f_bath", {"host": root})
	viewer.get_node("CardReveal").call("_open_card")
	await process_frame
	await _grab("menos_animacao", viewer)
	viewer.call("close")
	print("FOTOS 05 SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures else 0)
