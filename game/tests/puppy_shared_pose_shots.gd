extends SceneTree
## Isolated motion proof; does not install a renderer in the game.
const ART := "res://assets/sprites/characters/"
const RATE := 24.0
const LEAD := 1.5
const ACTION := 9.0 / 7.0
const TAIL := 1.5
const NOSE_Y := [0.0, -3.0, -9.0, -18.0, -24.0, -24.0, -15.0, -9.0, -3.0]
const EYE_L := [Vector2.ZERO, Vector2(0,-3), Vector2(0,-12), Vector2(0,-18), Vector2(0,-24), Vector2(0,-24), Vector2(0,-15), Vector2(0,-9), Vector2(0,-3)]
const EYE_R := EYE_L
# Original source tilt angles from the line between the eyes. Head translations
# are deliberately not copied; continuous interpolation, neutral at both ends.
const ANGLES := [0.0,0.0,0.0,-8.43,-19.09,-19.09,-16.50,0.0,0.0]
var targets: Array[TextureRect] = []
var idle: Array[Texture2D] = []
var material: ShaderMaterial
var output: String

func _initialize() -> void: _run.call_deferred()

func texture(folder: String, clip: String, frame: int) -> Texture2D:
	return load(ART + folder + "/" + clip + "/frame_%02d.png" % frame)

func _run() -> void:
	root.content_scale_size = Vector2i(960,330)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	output = ProjectSettings.globalize_path("res://../build/screenshots/puppy_shared_pose/")
	DirAccess.make_dir_recursive_absolute(output)
	var background := ColorRect.new()
	background.color = Color("ead4b0")
	background.size = Vector2(960,330)
	root.add_child(background)
	var labels := ["PIXEL ORIGINAL", "PUBLICADO: DESENHOS SEPARADOS", "PROVA: MESMA PELE / ROSTO"]
	for j: int in 3:
		var label := Label.new()
		label.text = labels[j]
		label.position = Vector2(j * 320 + 7, 8)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color("4b321f"))
		root.add_child(label)
		var target := TextureRect.new()
		target.position = Vector2(j * 320, 32)
		target.size = Vector2(320,270)
		target.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		target.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		target.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if j == 0 else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		root.add_child(target)
		targets.append(target)
	var shader := Shader.new()
	shader.code = FileAccess.get_file_as_string("res://../tools/art/tiro_continuity_shared_v5/shared_head.gdshader")
	material = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("eyelids", texture("tiro_pet_puppy_illustrated", "head_tilt", 7))
	material.set_shader_parameter("closed_left", Vector2(328.5,240.0))
	material.set_shader_parameter("closed_right", Vector2(413.01,239.49))
	targets[2].material = material
	for i: int in 9: idle.append(texture("tiro_pet_puppy_illustrated", "idle_breathe", i))
	var status := Label.new()
	status.position = Vector2(12,302)
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", Color("4b321f"))
	root.add_child(status)
	var count := int(ceil((LEAD+ACTION+TAIL)*RATE))
	for frame: int in count:
		var time := float(frame) / RATE
		var acting := time >= LEAD and time < LEAD + ACTION
		var clip := "head_tilt" if acting else "idle_breathe"
		var local_time := time-LEAD if acting else (time-LEAD-ACTION if time>=LEAD+ACTION else time)
		var index := mini(int(local_time*7.0),8) if acting else posmod(int(local_time*6.0),9)
		for j: int in 2:
			targets[j].texture=texture("tiro_pet_puppy" if j==0 else "tiro_pet_puppy_illustrated",clip,index)
		var base := posmod(int(time*6.0),9)
		targets[2].texture = idle[base]
		var degrees := 0.0
		var shift := Vector2.ZERO
		var blink := 0.0
		if acting:
			var cursor := minf((time-LEAD)*7.0,8.0)
			var low := int(cursor)
			var high := mini(low+1,8)
			var blend := smoothstep(0.0,1.0,cursor-float(low))
			degrees = lerpf(ANGLES[low],ANGLES[high],blend)
			# Neck pivot stays attached to the breathing torso. Do not stack the
			# independent clip's upward translation on top of the live idle bob.
			shift = Vector2.ZERO
			blink = (1.0-absf(cursor-7.0)) if cursor>6.0 and cursor<8.0 else 0.0
		material.set_shader_parameter("angle",deg_to_rad(degrees))
		material.set_shader_parameter("offset",shift)
		material.set_shader_parameter("pivot",Vector2(369,365+NOSE_Y[base]*0.4))
		material.set_shader_parameter("blink",blink)
		material.set_shader_parameter("eye_left",Vector2(328.5,255)+EYE_L[base])
		material.set_shader_parameter("eye_right",Vector2(413,254.5)+EYE_R[base])
		status.text = "Respirar → inclinar → respirar   |   %s   |   %.2f s" % ["INCLINANDO" if acting else "RESPIRANDO", time]
		await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.save_png(output + "frame_%03d.png" % frame)
		if not acting:
			# Exact skin source at rest; rig must be identity, without a crossfade.
			assert(is_zero_approx(degrees) and shift == Vector2.ZERO and is_zero_approx(blink))
	print("PUPPY SHARED POSE: PASS; ", count, " rendered frames; source idle sequence continues through the action")
	quit()
