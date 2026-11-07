extends RefCounted
## Imported from Animaref; original pixels, frame rectangles and durations.
const CLIPS := {
	&"idle_breathe": [0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105, 0.105],
	&"head_tilt": [0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094, 0.094],
	&"close_eyes": [0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097, 0.097],
}

static func frames(clip: StringName) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if not CLIPS.has(clip): return result
	var path := "res://assets/sprites/characters/tiro_pet_puppy_animaref/%s.png" % clip
	if not ResourceLoader.exists(path): return result
	var sheet: Texture2D = load(path)
	for i: int in CLIPS[clip].size():
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2((i % 6) * 415, (i / 6) * 544, 415, 544)
		# Shared canvas preserves the existing home scale and foot baseline.
		frame.margin = Rect2(300, 190, 601, 313)
		frame.filter_clip = true
		result.append(frame)
	return result
