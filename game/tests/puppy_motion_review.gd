extends SceneTree
## Run with -- --capture for a deterministic review loop and support-foot checks.
const RIG := preload("res://scenes/art/puppy_2d_rig/puppy_motion.tscn")
const FOLDER := "res://../build/screenshots/puppy_motion/"
const ACTIONS := [&"idle_breathe", &"lick_paw", &"eat"]
const LABELS := ["Respirar", "Lamber a pata", "Comer"]
var dog
var buttons: Array[Button] = []

func _initialize() -> void:
	_review.call_deferred()

func choose(i: int) -> void:
	dog.play(ACTIONS[i])
	for j in buttons.size():
		buttons[j].button_pressed = (i == j)

func _review() -> void:
	root.title = "Tiro bebê · Estudo de movimento"
	root.content_scale_size = Vector2i(460,520)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.size = Vector2i(460,520)
	var stage := ColorRect.new()
	stage.color = Color("#f5e9d9")
	stage.size = Vector2(460,520)
	root.add_child(stage)
	dog = RIG.instantiate()
	dog.scale = Vector2.ONE*.84
	dog.position = Vector2(-80,-48)
	root.add_child(dog)
	var row := HBoxContainer.new()
	row.position = Vector2(30,455)
	row.add_theme_constant_override("separation",8)
	root.add_child(row)
	for i in ACTIONS.size():
		var b := Button.new()
		b.text = LABELS[i]
		b.custom_minimum_size = Vector2(128,45)
		b.toggle_mode = true
		row.add_child(b)
		buttons.append(b)
		b.pressed.connect(choose.bind(i))
	choose(0)
	if not "--capture" in OS.get_cmdline_user_args():
		dog.set_process(false)
		process_frame.connect(_tick)
		return
	dog.set_process(false)
	var folder := ProjectSettings.globalize_path(FOLDER)
	DirAccess.make_dir_recursive_absolute(folder)
	var support: Image
	for i in 270:
		if i == 45 or i == 162: choose(1)
		if i == 75 or i == 199: choose(2)
		if i == 230: choose(0)
		dog.advance(1./30.)
		_sync_buttons()
		await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		var foot := shot.get_region(Rect2i(168,395,17,15))
		if i == 0: support = foot
		if foot.get_data() != support.get_data():
			push_error("Apoio deslocado no quadro %d" % i)
			quit(1)
			return
		if shot.save_png(folder+"frame_%03d.png" % i) != OK:
			quit(1)
			return
	print("PUPPY MOTION PASS: 270 renders, planted paw RGB identical throughout")
	quit()

func _tick() -> void:
	dog.advance(root.get_process_delta_time())
	_sync_buttons()

func _sync_buttons() -> void:
	for j in buttons.size():
		buttons[j].button_pressed = dog.clip == ACTIONS[j]

