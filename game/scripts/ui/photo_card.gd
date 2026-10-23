class_name PhotoCard
extends RefCounted
## Polaroide do álbum (06 G): moldura + recorte do cenário + quadro do Tiro no corpo e pelo gravados na foto
## + adereços + legenda. Montada na hora, sem arte exclusiva por foto. O Tiro usa os mesmos quadros e o mesmo
## `tiro_coat` do jogo; a foto guarda a fase e o pelo do dia, então continua mostrando aquele corpo depois de crescer.

const BASE := Vector2(176, 176)
const WINDOW := Rect2(12, 12, 152, 128)
const FRAME := preload("res://assets/sprites/ui/album/polaroid.png")
const MONTHS := ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"]


## `options`: `locked` (silhueta cinza), `secret` ("?" no lugar da silhueta), `caption` (título e data na moldura), `thumb` (miniatura da grade: sem a faixa de fase).
static func make(id: String, width: float = 104.0, options: Dictionary = {}) -> Control:
	var entry := Database.photo(id)
	var info := GameState.photo_info(id)
	var locked: bool = bool(options.get("locked", info.is_empty()))
	var scale_factor := width / BASE.x
	var root := Control.new()
	root.name = "PhotoCard"
	root.custom_minimum_size = BASE * scale_factor
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.set_meta("photo", id)
	var canvas := Control.new()
	canvas.name = "Canvas"
	canvas.size = BASE
	canvas.scale = Vector2.ONE * scale_factor
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(canvas)
	var frame := NinePatchRect.new()
	frame.name = "Frame"
	frame.texture = FRAME
	for side: String in ["left", "top", "right", "bottom"]:
		frame.set("patch_margin_" + side, 8)
	frame.size = BASE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(frame)
	var window := Control.new()
	window.name = "Window"
	window.position = WINDOW.position
	window.size = WINDOW.size
	window.clip_contents = true
	window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(window)
	var photo_def: Dictionary = entry.get("photo", {})
	var scene := _scene_texture(str(photo_def.get("scene", "")))
	if scene != null and not locked:
		var picture := TextureRect.new()
		picture.name = "Scene"
		picture.texture = scene
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_SCALE
		picture.size = WINDOW.size
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		window.add_child(picture)
	else:
		var blank := ColorRect.new()
		blank.color = Palette.SUNKEN
		blank.size = WINDOW.size
		blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		window.add_child(blank)
	if bool(options.get("secret", false)) and locked:
		return _finish(root, entry, info, width, options)
	var dog := _dog(photo_def, info, locked)
	if not locked:
		for prop: Variant in photo_def.get("props", []):
			if bool(Database.album.get("props", {}).get(str(prop), {}).get("behind", false)):
				var backdrop := _prop(str(prop))
				if backdrop: window.add_child(backdrop)
	if dog != null:
		window.add_child(dog)
	if not locked:
		for prop: Variant in photo_def.get("props", []):
			if bool(Database.album.get("props", {}).get(str(prop), {}).get("behind", false)): continue
			var node := _prop(str(prop))
			if node != null:
				window.add_child(node)
		var friend := _friend(str(photo_def.get("friend", "")), id == "p_pipoca")
		if friend != null:
			window.add_child(friend)
		var people: Array = photo_def.get("friends", [])
		for index in people.size():
			var person := _friend(str(people[index]))
			if person:
				person.position = Vector2(4 + index * 44, 4)
				window.add_child(person)
	return _finish(root, entry, info, width, options)


static func _finish(root: Control, entry: Dictionary, info: Dictionary, width: float, options: Dictionary) -> Control:
	var locked: bool = info.is_empty()
	var scale_factor := width / BASE.x
	if bool(options.get("secret", false)) and locked:
		var mark := UiKit.label("?", &"TitleLabel")
		mark.name = "SecretMark"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.size = WINDOW.size * scale_factor
		mark.position = WINDOW.position * scale_factor + Vector2(0, WINDOW.size.y * scale_factor * 0.18)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(mark)
	var ribbon := str(entry.get("photo", {}).get("ribbon", ""))
	if ribbon != "" and not locked and not bool(options.get("thumb", false)):
		var band := ColorRect.new()
		band.name = "RibbonBand"
		band.color = Palette.PRIMARY
		band.position = Vector2(WINDOW.position.x, WINDOW.position.y + 6) * scale_factor
		band.size = Vector2(WINDOW.size.x, 18) * scale_factor
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(band)
		var text := UiKit.label(ribbon, &"BadgeLabel")
		text.name = "RibbonText"
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text.size = band.size
		text.add_theme_font_size_override("font_size", maxi(9, int(12 * scale_factor)))
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		band.add_child(text)
	if bool(options.get("caption", false)):
		var title := UiKit.label(str(entry.get("title", "")) if not locked or not bool(options.get("secret", false)) else "???", &"SmallLabel")
		title.name = "PhotoTitle"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.position = Vector2(WINDOW.position.x, 143) * scale_factor
		title.size = Vector2(WINDOW.size.x * scale_factor, 18 * scale_factor)
		title.add_theme_font_size_override("font_size", maxi(11, int(13 * scale_factor)))
		title.clip_text = true
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(title)
		if not locked:
			var date := UiKit.label(date_text(float(info.at)), &"SmallLabel", Palette.INK_SOFT)
			date.name = "PhotoDate"
			date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			date.position = Vector2(WINDOW.position.x, 158) * scale_factor
			date.size = Vector2(WINDOW.size.x * scale_factor, 14 * scale_factor)
			date.add_theme_font_size_override("font_size", maxi(9, int(11 * scale_factor)))
			date.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.add_child(date)
	return root


## "12 de março, 19h" no relógio do aparelho.
static func date_text(at: float) -> String:
	var parts := Time.get_datetime_dict_from_unix_time(GameState._local_time(at))
	return "%d de %s, %dh" % [int(parts.day), MONTHS[int(parts.month) - 1], int(parts.hour)]


static func _scene_texture(scene_id: String) -> Texture2D:
	var def: Dictionary = Database.album.get("scenes", {}).get(scene_id, {})
	if def.is_empty():
		return null
	var image := load(str(def.image)) as Texture2D
	if image == null:
		return null
	var region: Array = def.region
	var atlas := AtlasTexture.new()
	atlas.atlas = image
	atlas.region = Rect2(float(region[0]), float(region[1]), float(region[2]), float(region[3]))
	return atlas


## Quadro do Tiro no corpo daquela fase: mesma pasta de clipes que o `PetAnimator` usa para o corpo.
static func dog_frame(phase_id: String, clip: String, frame: int) -> Texture2D:
	var phases: Array = Database.growth.phases
	var body := "adult"
	for phase: Dictionary in phases:
		if str(phase.id) == phase_id:
			body = str(phase.body)
	var art: Dictionary = Database.growth.bodies[body]
	var folder := str(art.dir.pet)
	var resolved := str(art.get("clip_fallback", {}).get(clip, clip))
	if clip == "sleep":
		# O primeiro quadro é a transição em pé; a foto usa a pose de sono concluída.
		var frames: Array = Array(ResourceLoader.list_directory(folder + resolved + "/")).filter(func(file: String) -> bool: return file.ends_with(".png"))
		frames.sort()
		if not frames.is_empty(): return load(folder + resolved + "/" + str(frames.back())) as Texture2D
	var path := "%s%s/frame_%02d.png" % [folder, resolved, frame]
	if not ResourceLoader.exists(path):
		path = "%s%s/frame_00.png" % [folder, resolved]
	if not ResourceLoader.exists(path):
		path = "%s%s/frame_00.png" % [folder, "idle_breathe"]
	return load(path) as Texture2D


static func _dog(photo_def: Dictionary, info: Dictionary, locked: bool) -> Control:
	var pose: Dictionary = photo_def.get("pose", {})
	var phase_id := str(info.get("phase", GameState.growth.phase))
	var body := "adult"
	for phase: Dictionary in Database.growth.phases:
		if str(phase.id) == phase_id: body = str(phase.body)
	var texture := dog_frame(phase_id, str(pose.get("clip", "idle_breathe")), int(pose.get("frame", 0)))
	if texture == null:
		return null
	var dog := TextureRect.new()
	dog.name = "Tiro"
	dog.texture = texture
	dog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dog.size = Vector2(150, 126.5)
	dog.position = Vector2(1, WINDOW.size.y - 126.5 + 6)
	dog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if locked:
		var flat := ShaderMaterial.new()
		flat.shader = load("res://assets/shaders/flat_silhouette.gdshader")
		dog.material = flat
	else:
		dog.material = DogLook.material()
		(dog.material as ShaderMaterial).set_shader_parameter("coat", float(info.get("coat", 0.0)))
	if not locked and body != "puppy":
		var anchors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PetAnimator.DIR + "overlay_anchors.json"))
		var clip := str(pose.get("clip", "idle_breathe"))
		for slot: String in info.get("equipped", {}):
			if slot == "head" and "party_hat" in photo_def.get("props", []): continue
			var outfit := str(info.equipped[slot])
			var path := str(Database.collections.get(outfit, {}).get("overlay", ""))
			if path == "" or clip not in Database.collections.get(outfit, {}).get("show_in", anchors.get("show_in", [])): continue
			var variant := PetAnimator.DIR + "overlays/%s/%s/frame_%02d.png" % [outfit, clip, int(pose.get("frame", 0))]
			if ResourceLoader.exists(variant): path = variant
			var layer := TextureRect.new()
			layer.name = "Outfit_" + slot
			layer.texture = load(path)
			layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			layer.stretch_mode = dog.stretch_mode
			layer.size = dog.size
			layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var anchor: Dictionary = anchors.get("bodies", {}).get(body, {}).get(clip, {}).get(slot, {})
			layer.scale = Vector2.ONE * float(anchor.get("scale", 1.0))
			var offset: Array = anchor.get("offset", [0, 0])
			layer.position = Vector2(float(offset[0]), float(offset[1])) * dog.size / Vector2(256, 216)
			dog.add_child(layer)
	return dog


static func _prop(id: String) -> Control:
	var def: Dictionary = Database.album.get("props", {}).get(id, {})
	if def.is_empty() or not ResourceLoader.exists(str(def.image)):
		return null
	var node := TextureRect.new()
	node.name = "Prop_" + id
	node.texture = load(str(def.image))
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var px := float(def.get("size", 48))
	node.size = Vector2(px, px)
	node.position = Vector2(float(def.pos[0]) * WINDOW.size.x, float(def.pos[1]) * WINDOW.size.y) - node.size * 0.5
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


## Retrato pequeno de um personagem ou amigo no canto da foto.
static func _friend(id: String, sleeping: bool = false) -> Control:
	if id == "":
		return null
	var path := str(Database.npcs.get(id, {}).get("portrait", ""))
	if path == "":
		path = str(GameState.friend_def(id).get("portrait", ""))
	if sleeping and id == "pipoca":
		var sleep_path := "res://assets/sprites/ui/album/pipoca_sleep.png"
		if ResourceLoader.exists(sleep_path): path = sleep_path
	if path == "" or not ResourceLoader.exists(path):
		return null
	var node := TextureRect.new()
	node.name = "Friend_" + id
	node.texture = load(path)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.size = Vector2(40, 40)
	node.position = Vector2(WINDOW.size.x - 44, 4)
	if sleeping:
		node.position = Vector2(108, 79)
		node.pivot_offset = node.size * 0.5
		node.rotation = 0.0
		var zzz := UiKit.label("z z z", &"SmallLabel")
		zzz.position = Vector2(0, -14)
		node.add_child(zzz)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
