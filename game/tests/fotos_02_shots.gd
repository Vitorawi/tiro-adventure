extends SceneTree
## Capturas das Fotos do Tiro, etapa 02: uma foto completa e uma pendente nos 4 níveis (PhotoCard.make com `level`).
## NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fotos_02_shots.gd
## PNGs em build/screenshots/fotos_02/.

const FOLDER := "res://../build/screenshots/fotos_02/"


func _initialize() -> void:
	_run.call_deferred()
	create_timer(60).timeout.connect(func() -> void: quit(1))


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state: Node = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	var card_script: GDScript = load("res://scripts/ui/photo_card.gd")
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/sprites/ui/album/rarities/manifest.json"))
	var complete := "h_arrival"
	var pending := ""
	for entry: Dictionary in root.get_node("Database").album.photos:
		if not manifest.items.has(str(entry.id) + "/common") and pending == "":
			pending = str(entry.id)
	for id: String in [complete, pending]:
		state.call("dev_take_photo", id)
	var backdrop := ColorRect.new()
	backdrop.color = Palette.PAPER
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 8)
	root.add_child(column)
	for id: String in [complete, pending]:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 4)
		for level in [1, 2, 3, 4]:
			row.add_child(card_script.call("make", id, 84.0, {"level": level, "thumb": true}))
		column.add_child(row)
	var big := HBoxContainer.new()
	big.alignment = BoxContainer.ALIGNMENT_CENTER
	for level in [1, 4]:
		big.add_child(card_script.call("make", complete, 170.0, {"level": level}))
	column.add_child(big)
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + "niveis.png")
	quit(0)
