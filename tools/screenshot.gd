extends SceneTree
## Captura telas do jogo para revisão visual (usado pelo Claude e por humanos).
## Uso (na raiz do repositório):
##   & $env:GODOT_BIN --path game --resolution 360x780 -s ../tools/screenshot.gd
## Gera build/screenshots/pet.png e build/screenshots/house.png.

const OUT_DIR := "../build/screenshots/"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + OUT_DIR))
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _frames(30)
	_save("pet")
	main.show_screen(&"house")
	await _frames(90)
	_save("house")
	# Chamada dinâmica: referenciar classes do jogo aqui quebra a compilação no modo -s.
	main.find_child("House").call("_on_hotspot_tapped", "stove")
	await _frames(10)
	_save("stove_sheet")
	quit()


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _save(file_name: String) -> void:
	var path := ProjectSettings.globalize_path("res://" + OUT_DIR + file_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("screenshot: ", path)
