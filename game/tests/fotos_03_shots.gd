extends SceneTree
## Capturas das Fotos do Tiro, etapa 03: molduras e efeitos dos 4 níveis. NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fotos_03_shots.gd
## (repita com 390x844 e 412x915; use `-- --out=<pasta>`). PNGs em build/screenshots/<pasta>/ (padrão fotos_03).

var folder := "fotos_03"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = arg.substr(6)
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))


func _grab(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../build/screenshots/" + folder + "/")
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + name + ".png")


func _clear(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()


func _row(card_script: GDScript, id: String, width: float, levels: Array, options: Dictionary = {}) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	for level: int in levels:
		var merged := options.duplicate()
		merged["level"] = level
		row.add_child(card_script.call("make", id, width, merged))
	return row


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	var card_script: GDScript = load("res://scripts/ui/photo_card.gd")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/ui/album/rarities/manifest.json"))
	var complete: Array[String] = []
	var pending := ""
	for entry: Dictionary in root.get_node("Database").album.photos:
		var id := str(entry.id)
		if manifest.items.has(id + "/common"):
			complete.append(id)
		elif pending == "":
			pending = id
	var ids: Array[String] = ["h_arrival", complete[1], pending]
	for id in ids:
		state.call("dev_take_photo", id, 1)
	var backdrop := ColorRect.new()
	backdrop.color = Palette.PAPER
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 6)
	root.add_child(column)

	# prancha: três fotos nos 4 níveis (~84 px) + a mesma no tamanho grande do álbum
	Motion.reduced = false
	for id in ids:
		column.add_child(_row(card_script, id, 84.0, [1, 2, 3, 4], {"thumb": true}))
	column.add_child(_row(card_script, "h_arrival", 170.0, [1, 2]))
	column.add_child(_row(card_script, "h_arrival", 170.0, [3, 4]))
	await create_timer(0.7).timeout
	await _grab("prancha")

	# grande, um por vez (300 px), cada nível
	for level in [1, 2, 3, 4]:
		_clear(column)
		await process_frame
		var holder := HBoxContainer.new()
		holder.alignment = BoxContainer.ALIGNMENT_CENTER
		holder.add_child(card_script.call("make", "h_arrival", 300.0, {"level": level, "still": false}))
		column.add_child(holder)
		var badge: Control = card_script.call("rarity_badge", level, 28)
		var badge_row := HBoxContainer.new()
		badge_row.alignment = BoxContainer.ALIGNMENT_CENTER
		badge_row.add_child(badge)
		column.add_child(badge_row)
		await create_timer(0.5).timeout
		await _grab("grande_%d" % level)

	# nível 4: dois instantes e inclinações (−1, 0) e (1, 0); nível 3: faixa de luz em dois instantes
	for level in [3, 4]:
		_clear(column)
		await process_frame
		column.add_child(_row(card_script, "h_arrival", 108.0, [level, level, level], {}))
		var tilts := [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0)]
		var row := column.get_child(0)
		for i in 3:
			var foil: Control = row.get_child(i).find_child("CardFoil", true, false)
			(foil.material as ShaderMaterial).set_shader_parameter("tilt", tilts[i])
		await create_timer(0.4).timeout
		await _grab("tilt_%d_a" % level)
		await create_timer(1.3).timeout
		await _grab("tilt_%d_b" % level)

	# Menos animação: parado
	Motion.reduced = true
	_clear(column)
	await process_frame
	column.add_child(_row(card_script, "h_arrival", 150.0, [3, 4]))
	await create_timer(0.4).timeout
	await _grab("parado")
	quit(0)
