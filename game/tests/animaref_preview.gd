extends SceneTree
## Prévia na tela real do jogo. Abrir com tools/preview_animaref.ps1.
## Mantém quadros, fundo, marcas e durações originais; nenhuma interpolação.
var clips: Array[Array] = []
var durations: Array[Array] = []
var animator: Node
var caption: Label
var clip := 0
var frame := 0
var clock := 0.0
var ready_to_play := false
var elapsed := 0.0
var shots := [false, false, false]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var source := ProjectSettings.globalize_path("res://").path_join("../Animaref/animation-sequence/")
	var files := DirAccess.get_files_at(source)
	files.sort()
	for file: String in files:
		if not file.ends_with(".json"): continue
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source + file))
		var image := Image.load_from_file(source + str(data.meta.image))
		assert(image != null and not image.is_empty(), "Spritesheet ausente: " + file)
		var sheet := ImageTexture.create_from_image(image)
		var textures: Array = []
		var times: Array = []
		for entry: Dictionary in data.frames.values():
			assert(not entry.rotated and not entry.trimmed)
			var region: Dictionary = entry.frame
			var texture := AtlasTexture.new()
			texture.atlas = sheet
			texture.region = Rect2(region.x, region.y, region.w, region.h)
			# O clipe da pata veio ~2,2% mais alto e com os pés 15 px
			# abaixo do idle. Corrige UMA vez por clipe, preservando o
			# movimento interno e as marcas d'água sem editar a arte.
			texture.margin = Rect2(230, 36, 460, 180) if clips.is_empty() else Rect2(240, 34, 480, 197)
			texture.filter_clip = true
			textures.append(texture)
			times.append(float(entry.duration) / 1000.0)
		clips.append(textures)
		durations.append(times)
	assert(clips.size() == 2 and clips[0].size() == 36 and clips[1].size() == 36)
	var state: Node = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	var pet: Control = main.find_child("PetScreen", true, false)
	pet.set("preview_hour", 12)
	animator = pet.get("_animator")
	caption = Label.new()
	caption.name = "AnimarefCaption"
	caption.position = Vector2(10, 165)
	caption.add_theme_font_size_override("font_size", 14)
	caption.add_theme_color_override("font_color", Color("513b2d"))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pet.add_child(caption)
	_show_frame()
	if "--verify" in OS.get_cmdline_user_args():
		_advance(2.808)
		assert(clip == 1 and frame == 0, "Transição idle → pata")
		_advance(3.276)
		assert(clip == 0 and frame == 0, "Retorno pata → idle")
		_advance(12.168)
		assert(clip == 0 and frame == 0, "Dois ciclos adicionais")
		print("ANIMAREF: PASS; 72 quadros, idle 2,808 s + pata 3,276 s = 6,084 s/ciclo")
		quit()
	ready_to_play = true

func _show_frame() -> void:
	animator.set("preview_texture", clips[clip][frame])
	animator.call("_show")
	caption.text = "Prévia Ludo · %s · %02d/36" % ["Parado" if clip == 0 else "Lambendo a pata", frame + 1]

func _advance(delta: float) -> void:
	clock += delta
	while clock + 0.000001 >= float(durations[clip][frame]):
		clock -= float(durations[clip][frame])
		frame += 1
		if frame == clips[clip].size():
			frame = 0
			clip = (clip + 1) % clips.size()
	_show_frame()

func _process(delta: float) -> bool:
	if not ready_to_play: return false
	_advance(delta)
	elapsed += delta
	if "--shots" in OS.get_cmdline_user_args():
		for i: int in 3:
			if not shots[i] and elapsed >= [0.5, 4.2, 6.4][i]:
				shots[i] = true
				_capture(i)
		if elapsed > 6.8: quit()
	return false

func _capture(index: int) -> void:
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/animaref/")
	DirAccess.make_dir_recursive_absolute(output)
	root.get_texture().get_image().save_png(output + "%02d.png" % index)
