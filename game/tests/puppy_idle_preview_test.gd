extends SceneTree
## Só a respiração na home muda; preferência persistida devolve o pixel sem reset.
var failures := 0
var state: Node
var manager: Node
var main: Control

func _initialize() -> void: _run.call_deferred()
func frames() -> void:
	for i: int in 5: await process_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PUPPY IDLE: " + message)
func shot(id: String) -> void:
	if "--shots" not in OS.get_cmdline_user_args(): return
	await frames()
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/puppy_idle_preview/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + id + ".png")

func _run() -> void:
	state = root.get_node("GameState")
	manager = root.get_node("SaveManager")
	state.call("reset")
	state.get("progress").seen.intro = true
	manager.call("set_puppy_illustrated", true)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	var pet: Control = main.find_child("PetScreen", true, false)
	var animator: Node = pet.get("_animator")
	var target: TextureRect = pet.get("_dog_sprite")
	animator.set_process(false)
	animator.set("_frame", 0)
	animator.call("_show")
	var first := target.texture.resource_path
	check(first.contains("tiro_pet_puppy_illustrated/idle_breathe/frame_00"), "home usa o quadro novo")
	check(target.texture.get_size() == Vector2(768, 648), "canvas 3× preserva enquadramento")
	check(target.material == null and target.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "pintura sem shader de paleta pixel")
	check(animator.get("_illustrated_idle").size() == 9, "nove quadros")
	check(animator.get("FPS")[&"idle_breathe"] == 6.0, "mesmo ritmo de 6 fps")
	await shot("illustrated")
	animator.call("_play", &"head_tilt", 1)
	check(target.texture.resource_path.contains("tiro_pet_puppy/head_tilt/"), "outra animação mantém original")
	check(target.material is ShaderMaterial, "shader pixel volta na outra animação")
	animator.call("_play", &"idle_breathe", 1)
	check(target.texture.resource_path == first, "retorno à respiração usa teste")
	manager.call("set_puppy_illustrated", false)
	manager.call("_load_settings")
	check(not bool(manager.get("puppy_illustrated")), "preferência de volta ao pixel fica gravada")
	animator.call("_show")
	check(target.texture.resource_path.contains("tiro_pet_puppy/idle_breathe/"), "desligar restaura pixel original")
	check(target.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and target.material is ShaderMaterial, "pixel com filtro e material originais")
	await shot("pixel")
	var settings: Control = load("res://scripts/ui/settings_panel.gd").call("panel")
	root.add_child(settings)
	await frames()
	var toggle := settings.find_child("PuppyIllustratedToggle", true, false) as Button
	check(toggle != null and not toggle.button_pressed, "configuração mostra estado desligado")
	if toggle: toggle.button_pressed = true
	check(bool(manager.get("puppy_illustrated")), "interruptor liga de volta")
	settings.queue_free()
	var portrait: Control = load("res://scripts/ui/pet_animator.gd").call("portrait", 64)
	root.add_child(portrait)
	await frames()
	check((portrait.get_child(0) as TextureRect).texture.resource_path.contains("tiro_pet_puppy/"), "retratos não mudam")
	portrait.queue_free()
	state.call("dev_set_phase", "teething")
	await frames()
	animator.call("_show")
	check(not target.texture.resource_path.contains("puppy_illustrated"), "Dentinhos e demais corpos não usam teste do bebê")
	main.queue_free()
	await frames()
	print("PUPPY IDLE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
