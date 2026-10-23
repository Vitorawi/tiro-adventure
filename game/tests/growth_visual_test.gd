extends SceneTree
## Seis fases na mesma cena; sem carregar/gravar saves pessoais.
var failures := 0
var state: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Growth visual: " + message)

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Motion.reduced = true
	var main := load("res://scenes/main/main.tscn").instantiate() as Control
	root.add_child(main)
	await process_frame
	var pet: Node = main.find_child("PetScreen", true, false)
	var animator: Node = pet.get("_animator")
	var hud: Node = main.find_child("TopBar", true, false)
	var room: Node = main.find_child("World_house", true, false)
	var world: Node = room.get("_dog")
	var intro: Node = load("res://scenes/ui/intro/intro.gd").new()
	root.add_child(intro)
	var animator_script: Script = load("res://scripts/ui/pet_animator.gd")
	var portrait: Control = animator_script.call("portrait")
	root.add_child(portrait)
	var small: Node = portrait.get_child(1)
	var expected := ["puppy", "puppy", "young", "young", "adult", "adult"]
	for i in 6:
		var phase: Dictionary = root.get_node("Database").get("growth").phases[i]
		state.call("dev_set_phase", str(phase.id))
		await process_frame
		var look: Dictionary = state.call("dog_look")
		check(look.body == expected[i], "corpo " + str(phase.id))
		check(animator._look.dir_pet == look.dir_pet and small._look.body == look.body, "animador/retrato atualizados")
		# Issue #2: cada quadro inteiro deve caber no retrato, inclusive o sono.
		for clip: StringName in [&"idle_breathe", &"sleep"]:
			small._play(clip, 1)
			var target: TextureRect = small._target
			var factor: Vector2 = target.size / target.texture.get_size()
			for texture: Texture2D in small._frames[clip]:
				var used := Rect2(texture.get_image().get_used_rect())
				var drawn := Rect2(target.position + used.position * factor, used.size * factor)
				check(Rect2(Vector2.ZERO, portrait.custom_minimum_size).encloses(drawn), "retrato inteiro " + str(phase.id) + "/" + str(clip))
			check(is_equal_approx(factor.x, factor.y), "retrato sem distorção")
		check(world.sprite_dir == look.dir_world, "mundo atualizado sem recarregar")
		var world_frames: SpriteFrames = world.get("_sprite").sprite_frames
		for action: String in ["idle", "walk", "sit", "sleep", "sniff", "dig", "eat", "bark"]:
			var found := false
			for animation: String in world_frames.get_animation_names():
				if not animation.begins_with(action + "_"): continue
				found = true
				check(world_frames.get_frame_count(animation) > 0, "clipe do mundo " + animation)
				for frame in world_frames.get_frame_count(animation):
					var texture := world_frames.get_frame_texture(animation, frame)
					check(texture.resource_path.begins_with(look.dir_world), "quadro do mundo no corpo certo")
			check(found, "ação do mundo " + action)
		check(hud.avatar_button.icon.resource_path == look.portrait, "HUD atualizado")
		check((intro.get("_tiro") as TextureRect).texture.resource_path == look.idle_front, "intro atualizada")
		check(ResourceLoader.exists(look.idle_front), "frontal existe")
		for clip: StringName in animator_script.get("FPS"):
			check(not animator._frames[clip].is_empty(), "clipe " + str(clip))
			for texture: Texture2D in animator._frames[clip]:
				check(texture.resource_path.begins_with(look.dir_pet), "quadro do corpo certo")
		var walker: AnimatedSprite2D = pet.get("_away_walker")
		check(walker.sprite_frames.get_frame_texture("walk", 0).resource_path.begins_with(look.dir_world), "passeio atualizado")
		for item: CanvasItem in [animator._target, world._sprite, hud.avatar_button, walker, intro.get("_tiro"), small._target]:
			check(is_equal_approx(float((item.material as ShaderMaterial).get_shader_parameter("coat")), look.coat), "shader na fase " + str(phase.id))
		if i != 4: check(is_equal_approx(look.coat, 1.0 if i == 5 else 0.0), "coat fixo")
		if i == 0:
			check(animator._frames[&"give_paw"][0].resource_path.contains("wag_excited"), "fallback do filhote")
		for id: String in root.get_node("Database").get("collections"):
			var data: Dictionary = root.get_node("Database").get("collections")[id]
			if str(data.get("overlay", "")) == "": continue
			state.get("progress").equipped[str(data.slot)] = id
			animator._play(&"idle_breathe", 1)
			var layer: TextureRect = animator._clothes[str(data.slot)]
			check(layer.visible == (look.body != "puppy"), "roupa " + id + " no " + str(look.body))
			if look.body == "young":
				for clip: String in animator._anchors.show_in:
					check(animator._anchors.bodies.young[clip].has(str(data.slot)), "âncora " + id + "/" + clip)
	state.call("dev_set_phase", "young")
	for id: String in state.get("growth").phase_moments: state.get("growth").phase_moments[id] = 0
	check(is_equal_approx(state.call("dog_look").coat, 0.3), "Mocinho mínimo")
	for id: String in state.get("growth").phase_moments: state.get("growth").phase_moments[id] = 220
	state.call("_changed")
	check(is_equal_approx(state.call("dog_look").coat, 0.7), "Mocinho máximo")
	check(is_equal_approx(float((animator._target.material as ShaderMaterial).get_shader_parameter("coat")), 0.7), "pilares atualizam pelagem sem trocar corpo")
	# Crescimento real emite grew e troca o corpo/limpa os caches na cena existente.
	state.call("dev_set_phase", "puppy")
	state.call("dev_complete_growth_reqs")
	check(state.call("grow") == "", "cresce pela ação real")
	check(animator._look.body == "young" and world.sprite_dir == state.call("dog_look").dir_world, "grew troca imediatamente")
	intro.queue_free()
	portrait.queue_free()
	main.queue_free()
	await process_frame
	print("GROWTH VISUAL TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
