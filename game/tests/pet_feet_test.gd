extends SceneTree
## Regressão nos pixels de apoio (o retângulo imóvel sozinho não detecta o samba).
const GROUNDED: Array[StringName] = [&"idle_breathe", &"head_tilt", &"yawn", &"sniff", &"shake_off", &"look_around", &"wag_excited", &"sad", &"pet_head"]
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var state := root.get_node("GameState")
	state.reset()
	state.progress.seen.intro = true
	state._mark_all_seen()
	state.dev_set_phase("puppy")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i in 12: await process_frame
	var pet: Control = main.find_child("PetScreen", true, false)
	var animator: Node = pet.get("_animator")
	animator.set_process(false)
	var target: TextureRect = pet.get_node("%DogSprite")
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		for i in 8: await process_frame
		for clip: StringName in GROUNDED:
			animator.call("_play", clip, 1)
			var frames: Array = animator.get("_frames")[clip]
			var low := Vector2(INF, INF)
			var high := Vector2(-INF, -INF)
			for frame in frames.size():
				animator.set("_frame", frame)
				animator.call("_show")
				await process_frame
				var image := target.texture.get_image()
				var box := image.get_used_rect()
				var left := image.get_width()
				var right := -1
				for x in image.get_width():
					if image.get_pixel(x, box.end.y - 1).a > 0.5:
						left = mini(left, x)
						right = maxi(right, x)
				var factor := minf(target.size.x / image.get_width(), target.size.y / image.get_height())
				var feet := target.global_position + (target.size - Vector2(image.get_size()) * factor) * 0.5 + Vector2((left + right + 1) * 0.5, box.end.y) * factor
				low = low.min(feet)
				high = high.max(feet)
			var drift := high - low
			print("PET FEET: %s %s drift=%s px" % [viewport, clip, drift])
			if drift.x > 1.001 or drift.y > 1.001:
				failures += 1
				push_error("PET FEET: patas deslizam em %s: %s" % [clip, drift])
	# Saltos, rolagens, sono e levantar a pata têm movimento intencional: não os imobilizar.
	main.queue_free()
	await process_frame
	print("PET FEET: %s (%d falhas)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
