extends SceneTree
## Captura o menu de comidas em madeira (360x780). Não é teste: grava build/screenshots/food_menu/.

func _initialize() -> void:
	call_deferred("_run")


func _frames(count: int = 4) -> void:
	for i in count: await process_frame


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	saver.get_parent().remove_child(saver)
	saver.free()
	var state := root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	state.get("inventory").call("from_dict", {"dog_food": 7, "carrot_snack": 3, "carrot": 5, "egg_scramble": 2, "milk_porridge": 3, "pumpkin_mash": 1, "apple_biscuit": 4})
	state.get("dog").needs.hunger = 10.0
	Motion.reduced = true
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _frames()
	var tray: Control = main.find_child("CareTray", true, false)
	tray.call("open_food_menu")
	await _frames(6)
	var folder := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/food_menu").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("comidas.png"))
	quit()
