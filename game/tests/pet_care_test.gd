extends SceneTree
## Cuidados pelo mesmo gui_input do celular; sem SaveManager nem save pessoal.

var failures := 0
var state: Node
var pet: Control
var tray: Control
var main: Control


func _initialize() -> void:
	_run.call_deferred()
	create_timer(35.0).timeout.connect(func() -> void:
		push_error("PET CARE: tempo excedido")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PET CARE: " + message)


func frames() -> void:
	for i in 4: await process_frame


func send(id: String, kind: String, point: Vector2) -> void:
	var item: Control = tray.call("item_node", id)
	if not item:
		check(false, "item existe: " + id)
		return
	var event: InputEvent
	if kind == "move":
		var motion := InputEventMouseMotion.new()
		motion.global_position = point
		motion.position = point - item.global_position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		event = motion
	else:
		var button := InputEventMouseButton.new()
		button.button_index = MOUSE_BUTTON_LEFT
		button.pressed = kind == "press"
		button.global_position = point
		button.position = point - item.global_position
		event = button
	item.gui_input.emit(event)


func tap(id: String) -> void:
	var center: Vector2 = tray.call("item_center", id)
	send(id, "press", center)
	send(id, "release", center)


func drag_food(target: Vector2, id: String = "dog_food") -> void:
	send(id, "press", tray.call("item_center", id))
	send(id, "move", target)
	send(id, "move", target)
	send(id, "release", target)
	# Segundo touchEnd do mesmo gesto precisa ser inofensivo.
	tray.call("release_item", target)


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver := root.get_node("SaveManager")
	saver.get_parent().remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	state.get("inventory").call("from_dict", {"dog_food": 8})
	state.get("dog").needs.hunger = 10.0
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	pet = main.find_child("PetScreen", true, false)
	tray = pet.find_child("CareTray", true, false)
	tray.call("open_food_menu")
	await frames()
	check(tray != null, "faixa de cuidados presente")
	check(tray.find_child("FoodButton", true, false) != null, "um botão fixo abre as comidas")
	var menu: Control = pet.find_child("FoodMenu", true, false)
	check(menu.visible and pet.find_child("FoodScroll", true, false).horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "comidas abrem na vertical")
	check(menu.position.x >= 0 and menu.get_global_rect().end.y <= tray.global_position.y, "guia fica dentro da tela e acima dos controles")
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await frames()
		var badge: Label = pet.find_child("NotebookNewBadge", true, false)
		check(badge.text == "!" and badge.get_theme_color("font_color") == Color.WHITE, "caderninho: exclamação branca sobre bolinha vermelha")
		check(badge.size.x >= badge.get_combined_minimum_size().x and badge.size.y > 0, "selo do caderninho tem espaço para o texto")
		for need_id: String in ["hunger", "happiness", "energy", "hygiene"]:
			var need_ring: Control = pet.find_child("Need_" + need_id, true, false)
			var press := InputEventMouseButton.new()
			press.button_index = MOUSE_BUTTON_LEFT
			press.pressed = true
			need_ring.gui_input.emit(press)
			await frames()
			var popover: Control = pet.get_node("PopoverCatcher/Popover")
			check(popover.size.x >= 200 and popover.size.y < 160, "balão legível sem coluna de letras: " + need_id)
			check(pet.get_global_rect().encloses(popover.get_global_rect()), "balão dentro da tela: " + need_id)
			if need_id == "hunger" and "--popover-shots" in OS.get_cmdline_user_args():
				badge.show()
				var folder := ProjectSettings.globalize_path("res://../build/screenshots/pet_popovers")
				DirAccess.make_dir_recursive_absolute(folder)
				await RenderingServer.frame_post_draw
				check(root.get_texture().get_image().save_png(folder.path_join("needs_%d.png" % viewport.x)) == OK, "captura dos balões")
			pet.get_node("PopoverCatcher").free()
		var circle_y := -1.0
		for action: String in ["FoodButton", "Care_sponge", "Care_ball", "SleepButton"]:
			var tile: Control = tray.find_child(action, true, false)
			var circle: Control = tile.find_child("Circle", true, false)
			var icon: Control = tile.find_child("CareIcon", true, false)
			check(circle.size == Vector2(56, 56), "quatro círculos iguais: " + action)
			check(tray.get_global_rect().encloses(icon.get_global_rect()), "ícone dentro da faixa: " + action)
			if circle_y >= 0: check(is_equal_approx(circle_y, circle.global_position.y), "cuidados alinhados na mesma linha")
			circle_y = circle.global_position.y
	root.size = Vector2i(360, 780)
	await frames()
	check(pet.find_child("Extras", true, false) == null, "chips antigos removidos")
	for id: String in ["hunger", "happiness", "energy", "hygiene"]:
		var ring: Control = pet.find_child("Need_" + id, true, false)
		check(ring != null and ring.size == Vector2(64, 64), "anel 64: " + id)
	var bag: RefCounted = state.get("inventory")
	var progress: RefCounted = state.get("progress")
	var before := int(bag.call("count", "dog_food"))
	var hunger: float = state.get("dog").call("get_need", "hunger", state.call("now"))
	tap("dog_food")
	check(bag.call("count", "dog_food") == before - 1, "toque consome uma comida")
	check(state.get("dog").call("get_need", "hunger", state.call("now")) > hunger, "toque aumenta barriga")
	var head: Rect2 = pet.call("head_rect")
	before = bag.call("count", "dog_food")
	drag_food(head.get_center() + Vector2(0, 40))
	check(bag.call("count", "dog_food") == before - 1 and progress.stat("feed") == 2, "soltar na cabeça alimenta uma vez")
	drag_food(Vector2(12, 180))
	check(bag.call("count", "dog_food") == before - 1, "soltar fora não consome")
	# Esfregar começa dentro e percorre mais de 800 px, sem contar o trajeto até o corpo.
	var dog: Rect2 = pet.call("dog_rect")
	var a := dog.get_center() + Vector2(-60, 40)
	var b := a + Vector2(120, 0)
	send("sponge", "press", tray.call("item_center", "sponge"))
	send("sponge", "move", a)
	for i in 12: send("sponge", "move", b if i % 2 == 0 else a)
	send("sponge", "release", a)
	check(progress.stat("bathe") == 1, "banho uma vez por gesto longo")
	tap("sponge")
	check(progress.stat("bathe") == 2, "banho por toque")
	send("sponge", "press", tray.call("item_center", "sponge"))
	send("sponge", "move", a)
	send("sponge", "release", a)
	check(progress.stat("bathe") == 2, "esfregada curta não dá banho")
	state.get("dog").needs.energy = 100.0
	tap("ball")
	check(progress.stat("play") == 1, "brincar por toque")
	var ball: Vector2 = tray.call("item_center", "ball")
	send("ball", "press", ball)
	send("ball", "move", ball - Vector2(0, 130))
	send("ball", "move", ball - Vector2(0, 130))
	send("ball", "release", ball - Vector2(0, 130))
	check(progress.stat("play") == 2, "arremesso para cima brinca uma vez")
	send("ball", "press", ball)
	send("ball", "move", ball + Vector2(0, 40))
	send("ball", "release", ball + Vector2(0, 40))
	check(progress.stat("play") == 2, "soltar bola para baixo não brinca")
	state.call("set_sleeping", true)
	before = bag.call("count", "dog_food")
	tap("dog_food")
	tap("sponge")
	tap("ball")
	check(bag.call("count", "dog_food") == before and progress.stat("bathe") == 2 and progress.stat("play") == 2, "sono bloqueia todos os cuidados")
	check(tray.call("item_node", "dog_food").modulate.a < 0.6, "comida apagada dormindo")
	check(tray.find_child("SleepButton", true, false).find_child("Caption", true, false).text == "Acordar", "acordar preservado")
	tray.find_child("SleepButton", true, false).pressed.emit()
	check(not state.get("dog").sleeping, "botão acorda")
	state.get("walk_state").current = {"id": "park_loop", "ready_at": 9999999999.0, "seed": 42}
	state.call("_changed")
	check(not tray.visible and pet.find_child("AwayView", true, false).visible, "passeio troca a bandeja pelo postal")
	tap("dog_food")
	check(bag.call("count", "dog_food") == before, "passeio não alimenta nem por chamada de UI")
	var collect_walk: Button = pet.find_child("CollectWalk", true, false)
	check(not collect_walk.visible, "finalizar fica oculto enquanto passeia")
	state.get("walk_state").current.ready_at = 1.0
	var walks_before: int = progress.stat("walk")
	state.call("return_due_walk")
	check(progress.stat("walk") == walks_before + 1 and not state.call("walking"), "a volta conta o passeio uma vez, com a bagagem esperando")
	check(not pet.find_child("AwayView", true, false).visible and tray.visible, "Tiro volta à home e os cuidados reaparecem")
	check(collect_walk.visible and collect_walk.text == "Guardar achados", "home oferece guardar os achados")
	collect_walk.pressed.emit()
	check(not state.call("walk_ready") and not collect_walk.visible, "home guarda a bagagem")
	collect_walk.pressed.emit()
	check(progress.stat("walk") == walks_before + 1 and not pet.find_child("AwayView", true, false).visible, "não duplica prêmio")
	(main.get("_walk_result") as CanvasLayer).hide()
	state.call("dev_set_phase", "puppy")
	state.call("dev_complete_quest", "lais_bed")
	# Cenoura é um desejo de comida real; ração é o desejo de ação food_any.
	var food_wish := "carrot"
	bag.call("add", "carrot", 3)
	state.get("wishes").slots[0] = WishState.empty_slot(0.0)
	state.get("wishes").slots[0].id = food_wish
	state.call("_changed")
	await frames()
	before = bag.call("count", "carrot")
	var wishes_before: int = state.get("wishes").done_count
	var feeds_before: int = progress.stat("feed")
	drag_food(head.get_center() + Vector2(0, 40), "carrot")
	check(bag.call("count", "carrot") == before - 1 and progress.stat("feed") == feeds_before + 1, "desejo alimenta uma vez")
	check(state.get("wishes").done_count == wishes_before + 1, "arrasto cumpre desejo via Ele quer")
	# Manual padrão e abas reveladas progressivamente.
	pet.find_child("ManualButton", true, false).pressed.emit()
	await frames()
	check(main.find_child("ManualPanel", true, false) != null, "caderninho abre Manual por padrão")
	var notebook: Script = load("res://scripts/ui/pet_notebook.gd")
	# Antes da primeira visita, fotos ficam guardadas sem avisos ou fila retroativa.
	state.call("dev_reset_album")
	state.get("progress").stats.erase("open:album")
	main.get("_photo_queue").clear()
	state.call("dev_take_photo", "h_arrival")
	check(state.call("photo_count") == 1 and not state.call("photo_alerts_enabled"), "foto da chegada existe antes de conhecer o Álbum")
	check(main.get("_photo_queue").is_empty(), "primeira foto não anuncia Álbum ainda desconhecido")
	check(not notebook.call("section_has_new", "album"), "sem exclamação de foto antes da primeira visita")
	if "--album-intro-shots" in OS.get_cmdline_user_args():
		for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
			root.size = viewport
			var intro_box: VBoxContainer = load("res://scripts/ui/ui_kit.gd").call("vbox", 8)
			load("res://scripts/ui/progression_ui.gd").call("npc_header", intro_box, "lais", str(root.get_node("Database").get("quests").lais_album.dialogue))
			load("res://scripts/ui/progression_ui.gd").call("quest_card", intro_box, "lais_album")
			root.get_node("Events").sheet_requested.emit("Laís", intro_box)
			await frames()
			for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]:
				(main.get(member) as CanvasLayer).hide()
			main.get("_modal_queue").clear()
			(main.get("_toast") as Control).hide()
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/album_introduction")
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder.path_join("mission_%d.png" % viewport.x)) == OK, "captura da apresentação do Álbum")
	load("res://scripts/ui/places.gd").call("go", {"notebook": "album"})
	await frames()
	check(main.find_child("AlbumView", true, false) != null and state.call("photo_alerts_enabled"), "Ir abre o Álbum e ativa avisos")
	check(main.get("_photo_queue").is_empty() and state.call("photo_count") == 1, "abrir preserva o passado sem disparar avisos retroativos")
	state.call("dev_take_photo", "h_growth_adult")
	check(main.get("_photo_queue").has("h_growth_adult"), "depois da visita fotos novas entram na fila")
	main.get("_photo_queue").clear()
	state.call("dev_unlock_everything")
	state.call("dev_set_phase", "puppy")  # Crescimento aparece depois da primeira fase.
	state.call("_mark_all_seen")
	await create_timer(2.2).timeout
	for member: String in ["_celebration", "_welcome", "_walk_result"]: (main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	check((notebook.call("tabs") as Array).size() == 5, "cinco consultas após liberar (Manual, Crescimento, Álbum, Coleção, Truques)")
	# Consultar uma aba confirma só seus desbloqueios, sem apagar novidades das outras.
	for key: String in ["feature:growth_tab", "feature:dress", "feature:tricks"]:
		progress.seen.erase(key)
	notebook.call("open", "manual")
	await frames()
	for section: String in ["growth", "collection", "tricks", "album"]:
		var tab: Button = main.find_child("NotebookTab_" + section, true, false)
		check(tab.find_child("NewBadge", true, false) != null, "aba com novidades marcada: " + section)
	notebook.call("open", "growth")
	await frames()
	check(not notebook.call("section_has_new", "growth"), "abrir Crescimento confirma só essa aba")
	check(notebook.call("section_has_new", "collection") and notebook.call("section_has_new", "tricks") and notebook.call("section_has_new", "album"), "outras abas continuam com aviso")
	if "--notebook-shots" in OS.get_cmdline_user_args():
		for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
			root.size = viewport
			notebook.call("open", "manual")
			await frames()
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/notebook_alerts")
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder.path_join("manual_%d.png" % viewport.x)) == OK, "captura das abas com aviso")
	# As cinco mais usadas vêm primeiro; as demais continuam na mesma lista vertical.
	var added := 0
	for id: String in root.get_node("Database").get("items"):
		if root.get_node("Database").get("items")[id].has("feed") and added < 8:
			bag.call("add", id, 1)
			added += 1
	progress.count("feed:carrot_snack", 12)
	progress.count("feed:carrot", 10)
	state.call("_changed")
	var foods: Array = tray.call("food_ids")
	check(foods[0] == "carrot_snack" and foods[1] == "carrot", "mais usadas ordenadas pelos contadores existentes")
	check(foods.size() > 5, "lista conserva todas as comidas disponíveis")
	tray.call("close_food_menu")
	tray.call("open_food_menu")
	await frames()
	var list: ScrollContainer = pet.find_child("FoodScroll", true, false)
	check(list.custom_minimum_size.y == 316, "cinco opções visíveis antes de rolar")
	var row: Control = tray.call("item_node", str(foods[0]))
	var scroll_from := row.global_position + Vector2(150, 24)
	var feeds: int = progress.stat("feed")
	send(str(foods[0]), "press", scroll_from)
	send(str(foods[0]), "move", scroll_from - Vector2(0, 110))
	send(str(foods[0]), "release", scroll_from - Vector2(0, 110))
	check(list.scroll_vertical > 0 and progress.stat("feed") == feeds, "rolar pelo nome mostra outras comidas sem alimentar")
	for section: String in ["growth", "collection", "tricks"]:
		notebook.call("open", section)
		await frames()
		check(main.find_child("PetNotebook", true, false) != null, "aba do caderninho: " + section)
	pet.set("preview_hour", 22)
	pet.call("_update_light")
	check(pet.find_child("Stars", true, false).visible, "estrelas à noite")
	pet.set("preview_hour", 12)
	pet.call("_update_light")
	check(not pet.find_child("Stars", true, false).visible, "dia sem estrelas")
	# Carinho pelo mesmo input da cabeça: ganho nomeado e espera, mesmo com menos animação.
	main.call("show_screen", &"pet")
	state.get("growth").phase = "teething"
	state.get("growth").points.brave = 68
	state.get("growth").reserve.brave = 0
	state.get("progress").cooldowns.erase("affection:pet")
	state.get("dog").sleeping = false
	for need: String in ["hunger", "happiness", "energy", "hygiene"]: state.get("dog").needs[need] = 40.0
	state.get("dog").updated_at = state.call("now")
	var sprite: TextureRect = pet.get("_dog_sprite")
	var touch := InputEventMouseButton.new()
	touch.button_index = MOUSE_BUTTON_LEFT
	touch.pressed = true
	touch.position = sprite.size * Vector2(0.5, 0.3)
	pet.set("_last_pet_reward", -10.0)
	sprite.gui_input.emit(touch)
	var feedback: Label = pet.find_child("MoodLabel", true, false)
	check("Coragem +1" in feedback.text and "69/70" in feedback.text, "carinho anuncia pontos e progresso reais")
	pet.set("_last_pet_reward", -10.0)
	pet.set("_last_pet_feedback", -10.0)
	sprite.gui_input.emit(touch)
	check(feedback.text.begins_with("Próximo ganho de Coragem em "), "reação sem pontos explica recarga")
	pet.call("_refresh")
	check(feedback.text.begins_with("Próximo ganho de Coragem em "), "atualização do humor preserva retorno do carinho")
	check(state.get("growth").points.brave == 69, "toque repetido não promete pontos extras")
	if "--pet-growth-shots" in OS.get_cmdline_user_args():
		for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
			root.size = viewport
			root.get_node("Events").sheet_close_requested.emit()
			pet.set("_last_pet_reward", -10.0)
			pet.set("_last_pet_feedback", -10.0)
			sprite.gui_input.emit(touch)
			await frames()
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/pet_growth_feedback")
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder.path_join("cooldown_%d.png" % viewport.x)) == OK, "captura do retorno do carinho")
	await _test_play_feedback()
	await _test_food_help()
	main.queue_free()
	await process_frame
	print("PET CARE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _test_play_feedback() -> void:
	root.get_node("Events").sheet_close_requested.emit()
	state.get("dog").sleeping = false
	for need: String in ["hunger", "happiness", "energy", "hygiene"]: state.get("dog").needs[need] = 40.0
	state.get("dog").updated_at = state.call("now")
	state.get("growth").cooldowns.erase("play")
	state.get("growth").points.smart = 10
	state.get("growth").reserve.smart = 0
	tap("ball")
	var mood: Label = pet.find_child("MoodLabel", true, false)
	check(mood.text.begins_with("Esperteza +"), "brincar anuncia o ganho nomeado")
	check(pet.find_child("PlayGrowthTimer", true, false).text.begins_with("Esperteza: próximo ganho em "), "espera aparece na faixa de cuidados")
	tap("ball")
	check(mood.text.begins_with("Esperteza: próximo ganho em "), "brincadeira sem pontos explica espera")
	pet.call("_refresh")
	check(mood.text.begins_with("Esperteza: próximo ganho em "), "refresh não apaga retorno da brincadeira")
	if "--play-growth-shots" in OS.get_cmdline_user_args():
		for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
			root.size = viewport
			state.get("dog").needs.energy = 100.0
			await frames()
			tap("ball")
			await frames()
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/play_growth")
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("wait_%d.png" % viewport.x))


func _test_food_help() -> void:
	var bag: Object = state.get("inventory")
	var progress: Object = state.get("progress")
	var events: Node = root.get_node("Events")
	events.sheet_close_requested.emit()
	state.get("dog").sleeping = false
	bag.call("from_dict", {"carrot_snack": 1})
	progress.cooldowns.erase("emergency_food")
	var picker: Control = load("res://scripts/ui/sheet_builder.gd").call("food_picker")
	root.add_child(picker)
	await frames()
	var button: Button = picker.find_child("FoodHelpButton", true, false)
	check(button != null and not button.disabled, "Tigela sempre permite pedir, mesmo com outra comida")
	button.pressed.emit()
	await frames()
	check(bag.call("count", "dog_food") == 2, "vovó dá duas rações sem cobrar")
	check(state.call("emergency_food") != "" and bag.call("count", "dog_food") == 2, "recarga impede duplicar o pedido")
	check(picker.find_child("FoodHelpButton", true, false).disabled, "Tigela mostra pedido indisponível durante recarga")
	check(picker.find_child("FoodHelpTimer", true, false).text.begins_with("Pedir de novo em "), "Tigela mostra tempo restante")
	var saved: Dictionary = progress.call("to_dict")
	check(float(saved.cooldowns.emergency_food) > float(state.call("now")), "recarga fica no save")
	picker.queue_free()
	bag.call("from_dict", {})
	tray.call("refresh")
	tray.call("close_food_menu")
	tray.call("open_food_menu")
	await frames()
	var menu: Control = pet.find_child("FoodMenu", true, false)
	check(menu.find_child("FoodHelpButton", true, false).disabled, "guia vazia compartilha a recarga da Tigela")
	progress.cooldowns.emergency_food = float(state.call("now")) - 1.0
	var help: Control = menu.find_child("FoodHelp", true, false)
	help.call("_on_tick")
	await frames()
	check(not menu.find_child("FoodHelpButton", true, false).disabled, "timer libera pedido automaticamente ao vencer")
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		await frames()
		check(menu.get_global_rect().encloses(help.get_global_rect()), "pedido cabe na guia em %d" % viewport.x)
		if "--food-help-shots" in OS.get_cmdline_user_args():
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/food_help")
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("empty_%d.png" % viewport.x))
	menu.find_child("FoodHelpButton", true, false).pressed.emit()
	await frames()
	check(bag.call("count", "dog_food") == 2 and menu.find_child("FoodHelp", true, false) == null, "pedido direto na guia devolve a lista com a ração")
