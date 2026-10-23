extends SceneTree
## Gestos (Cuidar é crescer, etapa 04): carinho de segurar/esfregar, lugar favorito e esconde-esconde.
## Regras reais do GameState e os métodos de gesto da PetScreen; sem SaveManager nem save pessoal.
## Com `-- --shots`, grava o minijogo nas três resoluções (precisa de janela).
var state: Node
var main: Control
var pet: Control
var failures := 0
var toasts: Array[String] = []
var HIDE: Script


func _initialize() -> void:
	_run.call_deferred()
	create_timer(60.0).timeout.connect(func() -> void:
		push_error("GESTURES: tempo excedido")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("GESTURES: " + message)


func frames(n: int = 4) -> void:
	for i in n: await process_frame


func click(point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = root.get_final_transform() * point
		event.global_position = event.position
		root.push_input(event)
		await frames()


func happiness_to(value: float) -> void:
	state.dog.commit(state.now())
	state.dog.needs.happiness = value


func pets() -> int:
	return int(state.progress.stat("pet"))


func smart() -> int:
	return int(state.growth.phase_moments.get("smart", 0))


func to_period(id: String) -> void:
	var guard := 0
	while not state.moment_period().ends_with(":" + id) and guard < 100:
		state.advance_clock(3600)
		guard += 1


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	saver.get_parent().remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	HIDE = load("res://scripts/ui/hide_seek_ui.gd")
	state.set_script(load("res://tests/helpers/economy_clock.gd"))
	state.set_clock(1792746000.0)
	state.reset()
	state.progress.seen.intro = true
	Motion.reduced = true
	root.get_node("Events").toast_requested.connect(func(text: String) -> void: toasts.append(text))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	main.call("show_screen", &"pet")
	await frames()
	pet = main.find_child("PetScreen", true, false)
	state.growth.phase = "teething"
	state.dog.sleeping = false
	to_period("morning")
	var sprite: TextureRect = pet.get("_dog_sprite")
	var paw := sprite.size * Vector2(0.5, 0.9)  # fora das três zonas

	# Carinho de segurar: 0,8 s não conta; 1,2 s conta uma vez, mesmo segurando mais.
	happiness_to(40.0)
	var base := pets()
	pet.call("hold_begin", paw)
	pet.call("hold_tick", 0.8)
	pet.call("hold_end")
	check(pets() == base, "segurar 0,8 s não dá carinho")
	pet.call("hold_begin", paw)
	pet.call("hold_tick", 0.6)
	check(pets() == base, "0,6 s ainda não")
	pet.call("hold_tick", 0.6)
	check(pets() == base + 1, "segurar 1,2 s dá um carinho")
	pet.call("hold_tick", 2.0)
	check(pets() == base + 1, "segurar mais não repete")
	pet.call("hold_end")
	var ring: Control = pet.find_child("HoldRing", true, false)
	check(ring != null and not ring.visible, "anel some ao soltar")

	# Esfregar: um gesto contínuo longo = um carinho; toque curto sem mexer = nenhum.
	base = pets()
	pet.call("hold_begin", paw)
	for i in 20: pet.call("hold_move", paw + Vector2(i, 0), 30.0)
	check(pets() == base + 1, "esfregar longo dá um carinho só")
	pet.call("hold_tick", 3.0)
	check(pets() == base + 1, "esfregar e segurar no mesmo gesto = um")
	pet.call("hold_end")
	pet.call("hold_begin", paw)
	pet.call("hold_end")
	check(pets() == base + 1, "toque curto não dá carinho")
	var phase_before: String = state.growth.phase
	check(phase_before == "teething", "fase preservada")

	# Dois gestos seguidos: cada um um carinho.
	pet.call("hold_begin", paw)
	pet.call("hold_tick", 1.3)
	pet.call("hold_end")
	check(pets() == base + 2, "novo gesto, novo carinho")

	# Lugar favorito: fixo pela semente, zonas derivadas do quadro, reação e +25 só nele.
	var favorite: String = state.favorite_spot()
	check(favorite in ["head", "chin", "belly"], "favorito é uma das três zonas")
	check(state.favorite_spot() == favorite, "favorito estável")
	var other := "head" if favorite != "head" else "chin"
	for spot: String in ["head", "chin", "belly"]:
		var center: Vector2 = (pet.call("spot_rect", spot) as Rect2).get_center() - (pet.call("dog_rect") as Rect2).position
		check(pet.call("spot_at", center) == spot, "zona " + spot + " reconhecida no centro dela")
	check(pet.call("spot_at", paw) == "", "patas não são zona")
	happiness_to(40.0)
	state.pet(other)
	var plain: float = state.dog.get_need("happiness", state.now()) - 40.0
	check(not state.favorite_spot_found(), "outra zona não revela o favorito")
	happiness_to(40.0)
	toasts.clear()
	var diary_before: int = state.growth.diary.size()
	var loved := [0]
	root.get_node("Events").favorite_spot_loved.connect(func(_z: String, _f: bool) -> void: loved[0] += 1)
	state.pet(favorite)
	var bonus: float = state.dog.get_need("happiness", state.now()) - 40.0
	check(bonus >= 25.0 and bonus > plain + 20.0, "lugar favorito dá +25 de Felicidade (%.1f x %.1f)" % [bonus, plain])
	check(state.favorite_spot_found() and state.growth.diary.size() == diary_before + 1, "primeira vez entra no diário")
	check(toasts.any(func(t: String) -> bool: return "Ele ama carinho" in t), "aviso de que ele ama carinho ali")
	check(loved[0] == 1, "reação do lugar favorito dispara")
	state.pet(favorite)
	check(state.growth.diary.size() == diary_before + 1 and toasts.filter(func(t: String) -> bool: return "Ele ama carinho" in t).size() == 1, "revela uma vez só")
	check(loved[0] == 2, "a reação continua nas próximas")

	# Pelo gesto da tela: segurar exatamente no favorito.
	var spot_center: Vector2 = (pet.call("spot_rect", favorite) as Rect2).get_center() - (pet.call("dog_rect") as Rect2).position
	loved[0] = 0
	pet.call("hold_begin", spot_center)
	pet.call("hold_tick", 1.3)
	pet.call("hold_end")
	check(loved[0] == 1, "segurar no favorito pela tela reage")

	# Esconde-esconde.
	state.growth.phase = "puppy"
	check(state.hide_and_seek_error("carrot_snack") != "", "filhote ainda não joga")
	state.growth.phase = "explorer"
	state.inventory.from_dict({"dog_food": 3})
	check(state.hide_and_seek_error("carrot_snack") == "Falta o petisco.", "sem petisco não joga")
	check(state.hide_and_seek_error("dog_food") != "", "só petisco com treat entra")
	check(state.hide_treats().is_empty(), "sem petiscos na mochila")
	state.inventory.from_dict({"carrot_snack": 5, "mint_snack": 1})
	check(state.hide_treats() == ["carrot_snack", "mint_snack"] or state.hide_treats().size() == 2, "lista petiscos da mochila")
	for id: String in ["carrot_snack", "mint_snack", "apple_biscuit", "corn_crunch", "cheese_bites"]:
		check(root.get_node("Database").items[id].get("treat", false), "treat: " + id)
	check(state.finish_hide_and_seek(true) == 0, "sem rodada pendente não rende nada")
	to_period("afternoon")
	var moments := smart()
	check(state.hide_and_seek("carrot_snack") == "", "começa com petisco")
	check(state.inventory.count("carrot_snack") == 4, "consome um petisco ao começar")
	check(state.finish_hide_and_seek(false) == 1 and smart() == moments + 1, "errar também rende um momento de Esperteza")
	check(state.finish_hide_and_seek(true) == 0, "fim repetido não conta")
	state.hide_and_seek("carrot_snack")
	check(state.finish_hide_and_seek(true) == 1 and smart() == moments + 2, "acertar rende o segundo")
	state.hide_and_seek("carrot_snack")
	check(state.finish_hide_and_seek(true) == 0 and smart() == moments + 2, "teto do período: sem terceiro momento")
	check(state.inventory.count("carrot_snack") == 2, "o petisco foi gasto nas três rodadas")
	to_period("night")
	state.hide_and_seek("carrot_snack")
	check(state.finish_hide_and_seek(true) == 1, "novo período volta a render")
	state.dog.sleeping = true
	check(state.hide_and_seek_error("carrot_snack") != "", "dormindo não joga")
	state.dog.sleeping = false

	# Trocas por fase e minijogo.
	for row: Array in [["explorer", 3], ["young", 4], ["adult", 5]]:
		state.growth.phase = row[0]
		check(state.hide_swaps() == row[1], "trocas em %s = %d" % [row[0], row[1]])
		state.inventory.from_dict({"carrot_snack": 3})
		Motion.reduced = false
		var game: VBoxContainer = HIDE.new()
		root.add_child(game)
		check(game.start("carrot_snack") == "", "minijogo começa em " + row[0])
		await frames(2)
		check(game.plan.size() == row[1], "plano com %d trocas em %s" % [row[1], row[0]])
		check(state.inventory.count("carrot_snack") == 2, "minijogo gasta um petisco")
		var sorted: Array = game.slots.duplicate()
		sorted.sort()
		game.choose(game.treat_cup)
		check(not game.finished, "não escolhe antes de acabar as trocas")
		game.skip_animation()
		check(sorted == [0, 1, 2] and game.ready_to_pick, "copos continuam em três lugares e liberam a escolha")
		var right: int = game.treat_cup
		game.choose(right)
		check(game.finished and game.found, "tocar no copo certo acerta")
		game.free()
		Motion.reduced = true
	state.growth.phase = "adult"
	state.inventory.from_dict({"carrot_snack": 2})
	var miss: VBoxContainer = HIDE.new()
	root.add_child(miss)
	miss.start("carrot_snack")
	miss.skip_animation()
	miss.choose((miss.treat_cup + 1) % 3)
	check(miss.finished and not miss.found, "tocar no copo errado erra")
	miss.free()

	# Brincar: bola ou copinhos desde o Aventureiro.
	state.growth.phase = "explorer"
	state.inventory.from_dict({"carrot_snack": 2})
	var tray: Control = pet.find_child("CareTray", true, false)
	tray.call("open_play_choice")
	await frames()
	check(pet.find_child("PlayBall", true, false) != null and pet.find_child("PlayCups", true, false) != null, "Brincar oferece bola e copinhos")
	var choice: Control = pet.get_node("PopoverCatcher/Popover")
	check(pet.get_global_rect().encloses(choice.get_global_rect()), "Bola e Copinhos ficam inteiros na área do Tiro, acima das abas")
	var cups_button: Control = pet.find_child("PlayCups", true, false)
	await click(cups_button.get_global_rect().get_center())
	await frames()
	check(main.find_child("HideSeek", true, false) != null and state.inventory.count("carrot_snack") == 1, "toque real em Copinhos abre a rodada e gasta um petisco")
	root.get_node("Events").sheet_close_requested.emit()
	await frames()
	var catcher := pet.get_node_or_null("PopoverCatcher")
	if catcher: catcher.free()
	state.inventory.from_dict({})
	tray.call("open_play_choice")
	await frames()
	check(pet.find_child("PlayCups", true, false) == null and pet.find_child("PlayCupsLocked", true, false) != null, "sem petisco, copinhos mostram o motivo")
	pet.get_node("PopoverCatcher").free()
	state.growth.phase = "puppy"
	check(not state.hide_unlocked(), "escolha só aparece desde o Aventureiro")

	if "--shots" in OS.get_cmdline_user_args():
		var folder := ProjectSettings.globalize_path("res://../build/screenshots/cuidado04")
		DirAccess.make_dir_recursive_absolute(folder)
		state.growth.phase = "explorer"
		for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
			root.size = viewport
			state.inventory.from_dict({"carrot_snack": 3})
			state.dog.sleeping = false
			tray.call("start_hide_and_seek", "carrot_snack")
			await frames(10)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("cups_start_%d.png" % viewport.x))
			var game: Node = main.find_child("HideSeek", true, false)
			if game:
				game.call("skip_animation")
				game.call("choose", game.get("treat_cup"))
			await frames(6)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("cups_result_%d.png" % viewport.x))
			root.get_node("Events").sheet_close_requested.emit()
			await frames(10)
			main.call("show_screen", &"pet")
			await frames(4)
			pet.call("hold_begin", paw)
			pet.call("hold_tick", 0.7)
			await frames(4)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("hold_ring_%d.png" % viewport.x))
			pet.call("hold_end")

	print("GESTURES: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)
