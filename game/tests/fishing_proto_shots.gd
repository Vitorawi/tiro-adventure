extends SceneTree
## Capturas e medidas do protótipo da pesca (etapa 00). NÃO é teste da suíte. Rodar SEM --headless:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/fishing_proto_shots.gd
## PNGs em build/screenshots/fishing_proto/proto_<largura>x<altura>_<caso>.png; FAIL e saída 1 se a
## pista/rede/ferramentas saírem da tela ou ficarem sob o HUD (168) ou as abas (100).

const HUD := 168.0
const TABS := 100.0
var failures := 0
var folder := "res://../build/screenshots/fishing_proto/"
var game: Control


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _shot(tag: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path := ProjectSettings.globalize_path(folder) + "proto_%dx%d_%s.png" % [image.get_width(), image.get_height(), tag]
	image.save_png(path)
	print("PNG: ", path)


## Peixe seguido por um jogador automático simples.
func _bot_step(frames: int) -> void:
	for i in frames:
		var sim: Object = game.get("sim")
		var center: float = sim.bar_y + sim.bar_h * 0.5
		# dedo "apertado" por script: a cena lê _mouse_down
		game.set("_mouse_down", center - sim.bar_v * 0.25 < sim.fish_y)
		await process_frame


func _measure(tag: String) -> void:
	var size_px := root.get_visible_rect().size
	var track: Rect2 = game.call("track_rect")
	var meter: Rect2 = game.call("meter_rect")
	_check(track.position.y >= HUD and track.end.y <= size_px.y - TABS, tag + ": pista entre HUD e abas")
	_check(track.end.x <= size_px.x and meter.position.x >= 0.0, tag + ": pista e rede na tela")
	var tools := game.find_child("Tools", true, false) as Control
	var tools_rect := Rect2(tools.position, tools.get_combined_minimum_size())
	_check(tools_rect.end.x <= meter.position.x, tag + ": ferramentas não encostam na rede")
	_check(tools_rect.end.y <= size_px.y - TABS, tag + ": ferramentas acima das abas (fim em %.0f)" % tools_rect.end.y)


func _run() -> void:
	game = load("res://scenes/ui/fishing/fishing_game.tscn").instantiate()
	game.set("profile", "darter")
	game.set("seed_value", 7)
	root.add_child(game)
	await create_timer(0.3).timeout
	_measure("começo")
	await _shot("a_comeco")
	# no meio: um peixe mais calmo, seguido por um jogador automático, até a rede passar de 60%
	game.set("profile", "smooth")
	game.call("_start")
	var mid: Object = game.get("sim")
	mid.bar_y = clampf(mid.fish_y - mid.bar_h * 0.5, 0.0, 1.0 - mid.bar_h)
	mid.meter = 0.6
	game.set("_mouse_down", false)
	await create_timer(0.15).timeout
	_check(game.get("sim").meter >= 0.5 and not game.get("sim").finished, "rede chegou perto de 60%%: %.2f" % game.get("sim").meter)
	await _shot("b_meio")
	# Pegou!: peixe dentro da barra e rede quase cheia
	game.call("_start")
	var sim: Object = game.get("sim")
	sim.bar_y = clampf(sim.fish_y - sim.bar_h * 0.5, 0.0, 1.0 - sim.bar_h)
	sim.meter = 0.999
	await create_timer(0.4).timeout
	_check(sim.finished and sim.caught, "Pegou! terminou")
	await _shot("c_pegou")
	# Escapou: barra no fundo, peixe no alto, rede quase vazia
	game.call("_start")
	sim = game.get("sim")
	sim.bar_y = 0.0
	sim.set("_base", 0.85)
	sim.fish_y = 0.85
	sim.meter = 0.01
	await create_timer(0.6).timeout
	_check(sim.finished and not sim.caught, "Escapou terminou")
	await _shot("d_escapou")
	print("FISHING PROTO SHOTS: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
