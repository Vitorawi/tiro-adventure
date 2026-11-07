extends SceneTree
## Capturas das Fotos do Tiro, etapa 04: a carta grande em 3D (CardViewer). NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fotos_04_shots.gd
## (repita com 390x844 e 412x915; `-- --out=<pasta>`). PNGs em build/screenshots/<pasta>/ (padrão fotos_04).
## Imprime FAIL se algo sai da tela, botão < 44, carta não quadrada, mais de um botão verde ou carta maior que 78%.

var folder := "fotos_04"
var failures := 0
var state: Node
var viewer_script: GDScript
var perf: Array[Dictionary] = []


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = arg.substr(6)
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + name + ".png")


func _fail(message: String) -> void:
	failures += 1
	print("FAIL ", message)


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


## Medição local com renderizador Compatibility; não substitui o roteiro no aparelho físico.
func _performance(level: int) -> void:
	var samples: Array[float] = []
	var last := Time.get_ticks_usec()
	for frame in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now - last) / 1000.0)
		last = now
	samples.sort()
	var total := 0.0
	var slow := 0
	for ms in samples:
		total += ms
		if ms > 33.3:
			slow += 1
	var result := {"level": level, "mean_ms": total / samples.size(), "p95_ms": samples[113], "max_ms": samples[-1], "over_33_ms": slow}
	perf.append(result)
	print("CARD PERF ", JSON.stringify(result))


func _open(id: String) -> Control:
	var viewer: Control = viewer_script.call("open", id, {"host": root})
	await create_timer(0.4).timeout
	return viewer


func _close() -> void:
	if viewer_script.call("is_open"):
		(viewer_script.get("current") as Control).call("close")
	await process_frame


func _tilt(viewer: Control, delta: Vector2) -> void:
	var rect: Rect2 = viewer.call("card_rect")
	viewer.call("touch_down", rect.get_center())
	viewer.call("touch_move", rect.get_center() + delta)


func _fresh() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_reset_album")
	state.set("coins", 0)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	viewer_script = load("res://scripts/ui/card_viewer.gd")
	var backdrop := ColorRect.new()
	backdrop.color = Color("6b8f5a")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	Motion.reduced = false

	# níveis 1, 3 e 4: parada e inclinada
	for level in [1, 3, 4]:
		_fresh()
		state.call("dev_take_photo", "h_arrival", level)
		state.set("coins", 500)
		var viewer := await _open("h_arrival")
		_measure(viewer, "nivel_%d" % level)
		await _grab("nivel_%d_parada" % level)
		_tilt(viewer, Vector2(110, -40))
		await create_timer(0.25).timeout
		await _grab("nivel_%d_inclinada_a" % level)
		if level == 4:
			await create_timer(0.5).timeout
			await _grab("nivel_4_inclinada_a_tempo_2")
		if level in [1, 4]:
			await _performance(level)
		viewer.call("touch_up", (viewer.call("card_rect") as Rect2).get_center())
		_tilt(viewer, Vector2(-110, 40))
		await create_timer(0.9).timeout
		await _grab("nivel_%d_inclinada_b" % level)
		viewer.call("touch_up", (viewer.call("card_rect") as Rect2).get_center())
		await _close()

	# versões: 2 de 4 e 4 de 4
	_fresh()
	state.call("dev_take_photo", "h_arrival", 1)
	state.call("dev_take_photo", "h_arrival", 3)
	state.set("coins", 500)
	var versions := await _open("h_arrival")
	_measure(versions, "versoes_2")
	await _grab("versoes_2_de_4")
	await _close()

	# Melhorar bloqueado (falta material) e liberado
	_fresh()
	state.call("dev_take_photo", "h_arrival", 2)
	state.set("coins", 1000)
	var locked := await _open("h_arrival")
	_measure(locked, "melhorar_bloqueado")
	await _grab("melhorar_bloqueado")
	var cost: Dictionary = state.call("upgrade_cost", "h_arrival")
	for item: String in cost.items:
		state.get("inventory").add(item, int(cost.items[item]))
	state.call("_changed")
	await create_timer(0.3).timeout
	_measure(locked, "melhorar_liberado")
	await _grab("melhorar_liberado")
	await _close()

	# sem moedas
	_fresh()
	state.call("dev_take_photo", "h_arrival", 1)
	var poor := await _open("h_arrival")
	_measure(poor, "sem_moedas")
	await _grab("sem_moedas")
	await _close()

	# coleção completa
	_fresh()
	for level in [1, 2, 3, 4]:
		state.call("dev_take_photo", "h_arrival", level)
	var complete := await _open("h_arrival")
	_measure(complete, "colecao_completa")
	await _grab("colecao_completa")
	await _close()

	# varal cheio: escolha de qual sai
	_fresh()
	for other in ["f_bath", "h_kitchen", "h_growth_adult"]:
		state.call("dev_take_photo", other, 1)
		state.call("feature_photo", other)
	state.call("dev_take_photo", "h_arrival", 3)
	var shelf := await _open("h_arrival")
	(shelf.find_child("FeatureButton", true, false) as Button).pressed.emit()
	await create_timer(0.3).timeout
	_measure(shelf, "varal_cheio")
	await _grab("varal_cheio")
	await _close()

	# Menos animação: parado
	Motion.reduced = true
	_fresh()
	state.call("dev_take_photo", "h_arrival", 4)
	var calm := await _open("h_arrival")
	await _grab("menos_animacao")
	await _close()
	var report_path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/performance.json")
	var report := FileAccess.open(report_path, FileAccess.WRITE)
	report.store_string(JSON.stringify(perf, "  "))
	print("FOTOS 04 SHOTS: ", "OK" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
