extends SceneTree
## Abre o protótipo da pesca (etapa 00). NÃO é teste. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fishing_proto.gd -- --fish=mixed --seed=7
## Perfis: mixed, smooth, sinker, floater, darter. Segure o botão do mouse = segurar o dedo.
## Ao sair, imprime no console o bloco de números para colar no fishing.json.


func _initialize() -> void:
	var game: Control = load("res://scenes/ui/fishing/fishing_game.tscn").instantiate()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--fish="):
			game.set("profile", arg.trim_prefix("--fish="))
		elif arg.begins_with("--seed="):
			game.set("seed_value", int(arg.trim_prefix("--seed=")))
	game.connect("closed", func() -> void: quit())
	root.add_child(game)
