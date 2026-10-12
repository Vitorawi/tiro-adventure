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
	# Começa de um jogo novo (save local de desenvolvimento) para os prints serem previsíveis.
	root.get_node("/root/GameState").call("reset")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await _frames(30)
	_save("pet")
	main.show_screen(&"house")
	await _frames(90)
	_save("house")
	# Chamadas dinâmicas: referenciar classes do jogo aqui quebra a compilação no modo -s.
	var house: Node = main.find_child("House")
	house.call("_on_object_tapped", "stove")
	await _frames(10)
	_save("stove_sheet")
	root.get_node("/root/Events").emit_signal("sheet_close_requested")
	# Manda dormir e espera o Tiro chegar ao sofá.
	root.get_node("/root/GameState").call("set_sleeping", true)
	await _seconds(14.0)
	_save("house_sleep")
	house.call("_zoom_at", Vector2(250, 330), 1.6)
	await _frames(5)
	_save("house_zoom")
	# Menu aberto com o Tiro no sofá: o painel tem que ficar na frente dele.
	house.call("_on_object_tapped", "fridge")
	await _seconds(0.5)
	_save("sheet_over_dog")
	root.get_node("/root/Events").emit_signal("sheet_close_requested")
	root.get_node("/root/GameState").call("set_sleeping", false)
	# Fogão cozinhando (animação) e cozinha de perto: uma receita em preparo e outra na fila.
	print("cozinhar: ", root.get_node("/root/GameState").call("cook", "carrot_snack"))
	print("cozinhar: ", root.get_node("/root/GameState").call("cook", "pumpkin_mash"))
	house.call("_zoom_at", Vector2(180, 250), 2.0)
	var content: Control = house.get_node("Content")
	content.position = house.size / 2.0 - Vector2(270, 150) * 2.0
	house.call("_clamp_content")
	await _seconds(0.5)
	_save("house_kitchen")
	# Painéis com o fogão cozinhando, geladeira e comida.
	for action: String in ["stove", "fridge", "bowl"]:
		house.call("_on_object_tapped", action)
		await _seconds(0.5)
		_save("sheet_" + action)
		if action == "stove":
			var scroll: ScrollContainer = main.find_child("Scroll", true, false)
			scroll.scroll_vertical = 10000
			await _seconds(0.2)
			_save("sheet_stove_recipes")
		root.get_node("/root/Events").emit_signal("sheet_close_requested")
	quit()


func _seconds(duration: float) -> void:
	await create_timer(duration).timeout


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _save(file_name: String) -> void:
	var path := ProjectSettings.globalize_path("res://" + OUT_DIR + file_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("screenshot: ", path)
