extends SceneTree
## Investigação de arte da Etapa 08; sem modificar estado persistente ou vestir no jogo.
## --resolution 360x780 -s ../tools/scarf_preview.gd, com timeout externo.

const PET_DIR := "res://assets/sprites/characters/tiro_pet/"
const OUT := "res://../build/screenshots/etapa08_lenco/"
const SOURCE := "res://../build/art_sources/etapa08/"
var overlay: Image
var folder: String


func _initialize() -> void:
	_run.call_deferred()


func _composite(path: String, offset := Vector2i.ZERO) -> Image:
	var base := Image.load_from_file(ProjectSettings.globalize_path(path))
	base.convert(Image.FORMAT_RGBA8)
	base.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), offset)
	return base


func _shot(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder + id + ".png")


func _run() -> void:
	# Desconecta o salvamento antes de preparar o estado de demonstração.
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	folder = ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(folder)
	overlay = Image.load_from_file(ProjectSettings.globalize_path(SOURCE + "red_scarf_overlay.png"))
	assert(not overlay.is_empty() and overlay.get_size() == Vector2i(256, 216))
	overlay.convert(Image.FORMAT_RGBA8)
	if "--sponge" in OS.get_cmdline_user_args():
		await _pet_concept("sponge_set_candidate_01.png", "tiro_esponjinha_conceito")
		quit()
		return
	if "--transfer" in OS.get_cmdline_user_args():
		await _transfer_review()
		quit()
		return
	var clips: PackedStringArray = DirAccess.get_directories_at(PET_DIR)
	clips.sort()
	var stage := Control.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("f5e3c2")
	background.size = Vector2(360, 780)
	stage.add_child(background)
	var title := Label.new()
	title.position = Vector2(12, 8)
	title.add_theme_color_override("font_color", Color("402c24"))
	stage.add_child(title)
	var views: Array[TextureRect] = []
	var labels: Array[Label] = []
	for i: int in 3:
		var label := Label.new()
		label.position = Vector2(12, 40 + i * 244)
		label.add_theme_color_override("font_color", Color("402c24"))
		stage.add_child(label)
		labels.append(label)
		var view := TextureRect.new()
		view.position = Vector2(52, 62 + i * 244)
		view.size = Vector2(256, 216)
		view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stage.add_child(view)
		views.append(view)
	for clip: String in clips:
		var frames: PackedStringArray = DirAccess.get_files_at(PET_DIR + clip)
		var pngs: Array[String] = []
		for file: String in frames:
			if file.ends_with(".png"):
				pngs.append(file)
		if pngs.is_empty():
			continue
		pngs.sort()
		var indices: Array[int] = [0, pngs.size() / 2, pngs.size() - 1]
		title.text = "Lenço: %s · diagnóstico" % clip
		var strip := Image.create(768, 216, false, Image.FORMAT_RGBA8)
		for i: int in 3:
			var composed := _composite(PET_DIR + clip + "/" + pngs[indices[i]])
			views[i].texture = ImageTexture.create_from_image(composed)
			labels[i].text = "Quadro %02d / %02d · offset 0,0" % [indices[i], pngs.size() - 1]
			strip.blit_rect(composed, Rect2i(0, 0, 256, 216), Vector2i(i * 256, 0))
		strip.save_png(folder + "strip_" + clip + ".png")
		await _shot("alinhamento_" + clip)
	stage.queue_free()
	await process_frame
	var state: Node = root.get_node("GameState")
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	for id: String in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order"]:
		progress.claimed_quests[id] = true
	progress.seen["intro"] = true
	state.call("_mark_all_seen")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	main.get_node("Celebration").hide()
	main.call("show_screen", &"pet")
	var pet: Node = main.get_node("%PetScreen")
	var animator: Node = pet.get("_animator")
	animator.set_process(false)
	var sprite: TextureRect = pet.get_node("%DogSprite")
	# Composição temporária só na captura: não antecipa o sistema de roupas.
	sprite.texture = ImageTexture.create_from_image(_composite(PET_DIR + "idle_breathe/frame_00.png"))
	await _shot("tiro_lenco")
	print("SCARF PREVIEW: PASS (22 animações e tela Tiro; nenhum save escrito)")
	quit()


## Mostra uma prévia de roupa na tela existente, sem instalar a arte ou salvar.
func _pet_concept(file: String, shot_name: String) -> void:
	var state: Node = root.get_node("GameState")
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	for id: String in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order"]:
		progress.claimed_quests[id] = true
	progress.seen["intro"] = true
	state.call("_mark_all_seen")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.6).timeout
	main.get_node("Celebration").hide()
	main.call("show_screen", &"pet")
	var pet: Node = main.get_node("%PetScreen")
	var animator: Node = pet.get("_animator")
	animator.set_process(false)
	var sprite: TextureRect = pet.get_node("%DogSprite")
	var concept := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + file))
	assert(not concept.is_empty() and concept.get_size() == Vector2i(256, 216))
	sprite.texture = ImageTexture.create_from_image(concept)
	await _shot(shot_name)
	print("PET CONCEPT PREVIEW: PASS (somente captura; nenhum save escrito)")


## Compara a mesma pose original, com sobreposição fixa e com transfer_outfit.
func _transfer_review() -> void:
	var stage := Control.new()
	root.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("f5e3c2")
	background.size = Vector2(360, 780)
	stage.add_child(background)
	var title := Label.new()
	title.position = Vector2(12, 8)
	title.add_theme_color_override("font_color", Color("402c24"))
	stage.add_child(title)
	var views: Array[TextureRect] = []
	var headings: Array[String] = ["Original", "Sobreposição fixa", "Transfer Outfit · PixelLab"]
	for i: int in 3:
		var label := Label.new()
		label.text = headings[i]
		label.position = Vector2(12, 40 + i * 244)
		label.add_theme_color_override("font_color", Color("402c24"))
		stage.add_child(label)
		var view := TextureRect.new()
		view.position = Vector2(52, 62 + i * 244)
		view.size = Vector2(256, 216)
		view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stage.add_child(view)
		views.append(view)
	var cases: Array[Array] = [["eat", 4, "Comendo"], ["sleep", 16, "Dormindo"], ["lick_paw", 4, "Lambendo a pata"]]
	for entry: Array in cases:
		var clip: String = entry[0]
		var frame: int = entry[1]
		title.text = "%s · quadro %02d" % [entry[2], frame]
		var path := PET_DIR + "%s/frame_%02d.png" % [clip, frame]
		var original := Image.load_from_file(ProjectSettings.globalize_path(path))
		var transferred := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + "transfer_%s_%02d.png" % [clip, frame]))
		assert(not transferred.is_empty() and transferred.get_size() == original.get_size())
		_report_difference(clip, original, transferred)
		views[0].texture = ImageTexture.create_from_image(original)
		views[1].texture = ImageTexture.create_from_image(_composite(path))
		views[2].texture = ImageTexture.create_from_image(transferred)
		await _shot("transfer_" + clip)
	stage.queue_free()
	print("SCARF TRANSFER PREVIEW: PASS (3 poses, original/fixa/transferida; nenhum save escrito)")


## Mede o quanto a transferência alterou a silhueta e os pixels além do tecido vermelho.
func _report_difference(clip: String, original: Image, transferred: Image) -> void:
	var changed := 0
	var changed_outside_scarf := 0
	var silhouette_changed := 0
	var visible_union := 0
	var scarf_bounds := Rect2i()
	for y: int in transferred.get_height():
		for x: int in transferred.get_width():
			var pixel := transferred.get_pixel(x, y)
			if pixel.a > 0.1 and pixel.r > 0.45 and pixel.r > pixel.g * 1.7 and pixel.r > pixel.b * 1.7:
				var point := Vector2i(x, y)
				scarf_bounds = Rect2i(point, Vector2i.ONE) if scarf_bounds.size == Vector2i.ZERO else scarf_bounds.expand(point)
	scarf_bounds = scarf_bounds.grow(5)
	for y: int in transferred.get_height():
		for x: int in transferred.get_width():
			var a := original.get_pixel(x, y)
			var b := transferred.get_pixel(x, y)
			if a.a < 0.1 and b.a < 0.1:
				continue
			visible_union += 1
			if (a.a > 0.1) != (b.a > 0.1):
				silhouette_changed += 1
			var diff := absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)
			if diff * 255.0 > 24.0:
				changed += 1
				if not scarf_bounds.has_point(Vector2i(x, y)):
					changed_outside_scarf += 1
	print("TRANSFER %s: union=%d, RGBA>24=%d, fora_do_tecido=%d, silhueta=%d, regiao=%s" % [clip, visible_union, changed, changed_outside_scarf, silhouette_changed, scarf_bounds])
