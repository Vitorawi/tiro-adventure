extends SceneTree
## Conferência (NÃO é teste): segue a história de um save NOVO de `welcome` até `lais_bag` só pela pílula do próximo passo.
## Em cada passo: captura, abre o cartão, toca em Ir (anota o destino), faz no lugar o que a missão pede, toca na pílula verde.
## Rodar SEM --headless: & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/pill_walk_shots.gd
## PNGs em build/screenshots/i2_03_mao/ e log em build/i2_03_mao.log.

var state: Node
var main: Control
var log_lines: PackedStringArray = []
var heard: Array = []
var shots_folder := "res://../build/screenshots/i2_03_mao/"


func _initialize() -> void:
	_run.call_deferred()


func say(text: String) -> void:
	print(text)
	log_lines.append(text)


func shot(shot_name: String, wait: float = 0.5) -> void:
	await create_timer(wait).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(shots_folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func guide() -> Dictionary:
	return (load("res://scripts/ui/quest_guide.gd") as GDScript).call("current")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	main.find_child("PetScreen", true, false).set("preview_hour", 12)
	await create_timer(1.2).timeout
	root.get_node("Events").world_requested.connect(func(world: String, place: String) -> void: heard.append("mundo %s / %s" % [world, place]))
	root.get_node("Events").screen_requested.connect(func(screen: StringName) -> void: heard.append("tela %s" % screen))
	var step: Control = main.find_child("NextStep", true, false)
	var order: Array[String] = []
	for n in 8:
		var g := guide()
		if g.state == "hidden":
			break
		var id: String = g.id
		order.append(id)
		say("[%d] %s estado=%s valor=%s/%s" % [n + 1, id, g.state, g.value, g.target])
		await shot("%02d_%s_antes" % [n + 1, id])
		if g.state != "ready":
			heard.clear()
			step.pressed.emit()
			await create_timer(0.3).timeout
			await shot("%02d_%s_cartao" % [n + 1, id], 0.2)
			var go := main.find_child("StepCardGo", true, false) as Button
			say("    cartão aberto, Ir presente: %s" % (go != null))
			go.pressed.emit()
			await create_timer(1.2).timeout
			say("    Ir levou a: %s" % str(heard))
			await shot("%02d_%s_destino" % [n + 1, id], 0.3)
			# O que a missão pede no lugar para onde a pílula levou.
			match id:
				"welcome":
					state.call("talk_to", "lais")
				"lais_feed":
					state.get("dog").needs.hunger = 40
					state.call("feed", "dog_food")
				"lais_bath":
					state.call("bathe")
				"lais_play":
					state.call("play")
				"lais_bag":
					pass  # o próprio Ir abriu a Mochila
			await create_timer(0.5).timeout
			g = guide()
			say("    depois de fazer: estado=%s valor=%s/%s" % [g.state, g.value, g.target])
		# Esconde cartões/avisos que atrapalhem e toca na pílula verde.
		var catcher := main.get_node_or_null("PopoverCatcher")
		if catcher:
			catcher.queue_free()
			await process_frame
		main.call("show_screen", &"pet")
		await create_timer(0.4).timeout
		await shot("%02d_%s_pronto" % [n + 1, id], 0.2)
		if guide().state not in ["ready", "shared_ready"]:
			say("    PROBLEMA: não ficou pronto")
			break
		step.pressed.emit()
		await create_timer(0.4).timeout
		say("    pílula verde tocada: %s %s" % [id, "concluída" if state.get("progress").claimed_quests.has(id) else "NÃO concluída"])
		# Cartões de comemoração/avisos não podem atrapalhar o próximo passo.
		for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]:
			var card: Variant = main.get(member)
			if card is CanvasLayer:
				(card as CanvasLayer).hide()
		main.set("_modal_queue", [] as Array[Callable])
		if id == "lais_bag":
			break
	say("ORDEM: %s" % " > ".join(order))
	var f := FileAccess.open(ProjectSettings.globalize_path("res://../build/i2_03_mao.log"), FileAccess.WRITE)
	f.store_string("\n".join(log_lines))
	f.close()
	quit(0)
