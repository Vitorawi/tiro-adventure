extends SceneTree
## Prancha do "Lacinho do topete" (etapa 10 do plano Tiro): adulto e jovem, lacinho amarelo × vermelho, em cinco poses.
## Uso: godot --headless --path game -s ../tools/bow_board.gd   → build/art/tiro10/lacinho.png

const PET := "res://assets/sprites/characters/tiro_pet/"
const CLIPS := ["idle_breathe", "eat", "sleep", "head_tilt", "sad"]
const SCALE := 2


func _init() -> void:
	var anchors: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PET + "overlay_anchors.json"))
	var board := Image.create(256 * SCALE * CLIPS.size(), 216 * SCALE * 4, false, Image.FORMAT_RGBA8)
	board.fill(Color("#f3ead7"))
	var row := 0
	for body: String in ["adult", "young"]:
		for bow: String in ["yellow_bow", "topknot_bow"]:
			for i in CLIPS.size():
				var clip: String = CLIPS[i]
				var dir := PET if body == "adult" else PET.replace("tiro_pet/", "tiro_pet_young/")
				var frame := _load(dir + clip + "/frame_00.png")
				var overlay_path := PET + "overlays/%s/%s/frame_00.png" % [bow, clip]
				var overlay := _load(overlay_path if FileAccess.file_exists(ProjectSettings.globalize_path(overlay_path)) else PET + "overlays/%s.png" % bow)
				var anchor: Dictionary = anchors.bodies.get(body, {}).get(clip, {}).get("head", {})
				var offset: Array = anchor.get("offset", [0, 0])
				var scale := float(anchor.get("scale", 1.0))
				if scale != 1.0:
					overlay.resize(int(overlay.get_width() * scale), int(overlay.get_height() * scale), Image.INTERPOLATE_NEAREST)
				frame.blend_rect(overlay, Rect2i(Vector2i.ZERO, overlay.get_size()), Vector2i(int(offset[0]), int(offset[1])))
				frame.resize(256 * SCALE, 216 * SCALE, Image.INTERPOLATE_NEAREST)
				board.blit_rect(frame, Rect2i(0, 0, 256 * SCALE, 216 * SCALE), Vector2i(i * 256 * SCALE, row * 216 * SCALE))
			row += 1
	var out := ProjectSettings.globalize_path("res://../build/art/tiro10/lacinho.png")
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	board.save_png(out)
	print("BOARD: ", out)
	quit()


func _load(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image
