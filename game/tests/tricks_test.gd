extends SceneTree
## Validação transacional, persistência e interação real do treino da Etapa 10.
var state: Node
var db: Node
var failures: int = 0
var announcements: int = 0
var panels_opened: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Truques: " + message)

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.set("test_time", 1791936000.0)
	state.call("reset")
	var p: RefCounted = state.get("progress")
	check(state.call("learn_trick", "paw") != "" and p.tricks.is_empty(), "história bloqueia treino")
	check(state.call("learn_trick", "invalid") != "" and state.call("perform_trick", "invalid") != "", "ids inválidos")
	p.claimed_quests.nina_pipoca = true
	p.claimed_quests.main_2_order = true
	check(state.call("learn_trick_error", "paw") == "", "pata abre após Pipoca")
	check(state.call("learn_trick", "talk") != "", "vínculo e sequência bloqueiam")
	root.get_node("Events").connect("trick_learned", func(_id: String) -> void: announcements += 1)
	root.get_node("Events").connect("sheet_requested", func(_title: String, content: Control) -> void:
		panels_opened += 1
		content.free())
	load("res://scripts/ui/places.gd").call("open", "park", "training")
	check(panels_opened == 1, "toque no lugar abre o Sheet do treino")
	var started := Time.get_ticks_msec()
	var training: Control = load("res://scenes/ui/trick_training/trick_training.tscn").instantiate()
	root.add_child(training)
	await process_frame
	training.set("zone_center", 0.5)
	check(training.call("check_hit", 0.5) and training.call("check_hit", 0.375) and training.call("check_hit", 0.625), "centro e duas bordas inclusivas")
	check(not training.call("check_hit", 0.374) and not training.call("check_hit", 0.626), "fora das bordas")
	training.call("dev_force_marker", 0.0)
	training.call("attempt")
	check(training.get("hits") == 0 and p.tricks.is_empty(), "erro sem custo/progresso")
	await create_timer(1.3).timeout
	for i in 3:
		training.call("dev_force_marker", training.get("zone_center"))
		training.call("attempt")
		training.call("attempt")
		check(training.get("hits") == i + 1, "toque repetido só conta uma tentativa")
		if i < 2:
			check(p.tricks.is_empty(), "um/dois acertos não aprendem")
			await create_timer(1.3).timeout
	check(p.tricks.get("paw", false) and p.stat("trick_learned") == 1 and announcements == 1, "3 acertos aprendem/anunciam uma vez")
	check(Time.get_ticks_msec() - started < 30000, "primeiro aprendizado em menos de 30 s")
	check(state.call("learn_trick", "paw") != "" and announcements == 1, "aprender repetido sem prêmio/contador")
	training.queue_free()
	await process_frame
	state.get("dog").needs.happiness = 40.0
	state.get("dog").updated_at = state.call("now")
	var affection: int = state.get("dog").affection
	check(state.call("perform_trick", "paw") == "", "executa aprendido")
	check(is_equal_approx(state.get("dog").get_need("happiness", state.call("now")), 43.0) and state.get("dog").affection == affection + 1, "+3 felicidade +1 afeto")
	check(p.stat("trick") == 1 and p.stat("trick:paw") == 1, "contadores total e específico")
	check(state.call("perform_trick", "paw") != "" and p.stat("trick") == 1, "recarga evita repetição")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(state.call("to_dict")))
	state.call("from_dict", saved)
	p = state.get("progress")
	check(p.tricks.paw and state.call("perform_trick_error", "paw") != "", "save preserva aprendizado e timestamp")
	state.set("test_time", state.get("test_time") + 119)
	check(state.call("perform_trick_error", "paw") != "", "119 s ainda bloqueado")
	state.set("test_time", state.get("test_time") + 1)
	check(state.call("perform_trick_error", "paw") == "", "120 s libera")
	for id: String in ["talk", "roll", "jump", "spin"]:
		var def: Dictionary = db.get("progression").tricks[id]
		var level: int = def.requirements.bond
		state.get("dog").affection = int(db.get("progression").bond_levels[level - 1].affection) - 1
		check(state.call("learn_trick_error", id) != "", "vínculo abaixo " + id)
		state.get("dog").affection += 1
		check(state.call("learn_trick", id) == "", "aprende no vínculo " + id)
		check(state.call("perform_trick", id) == "", "recargas independentes " + id)
	check(p.stat("trick_learned") == 5, "cinco únicos")
	state.call("set_sleeping", true)
	check(state.call("perform_trick", "paw") != "", "sono bloqueia executar")
	p.tricks.erase("spin")
	check(state.call("learn_trick", "spin") != "", "sono bloqueia aprender")
	state.call("set_sleeping", false)
	state.get("walk_state").current = {"id": "park_loop", "ready_at": 1.0}
	check(state.call("perform_trick", "paw") == state.call("away_text") and state.call("learn_trick", "spin") == state.call("away_text"), "passeio bloqueia ambos mesmo pronto")
	state.get("walk_state").current = {}
	await _clothes()
	var places: Script = load("res://scripts/ui/places.gd")
	check(places.call("goal_target", {"type":"stat","key":"trick_learned"}).get("place") == "training", "Ir aprender aponta Treino")
	check(places.call("goal_target", {"type":"stat","key":"trick"}).get("screen") == "pet", "Ir executar aponta Tiro")
	check(db.get("quests").nina_trick.order == 90 and db.get("quests").nina_friends.order == 100 and db.get("quests").nina_roll.order == 110, "linha Nina preserva amigos")
	# Receber missão duas vezes ou reabrir o save não repete as recompensas.
	for id: String in db.get("quests"):
		if id.begins_with("nina_") and int(db.get("quests")[id].order) < 90:
			p.claimed_quests[id] = true
	state.call("_changed")
	var coins: int = state.get("coins")
	check(state.call("claim_quest", "nina_trick") == "" and state.get("coins") == coins + 20, "missão do truque paga uma vez")
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))
	p = state.get("progress")
	check(state.call("claim_quest", "nina_trick") != "" and state.get("coins") == coins + 20, "recompensa única persistida")
	check(p.feature_unlocked("tricks"), "feature abre ao receber missão")
	var wish: Dictionary = db.get("wishes").wishes.trick
	check(wish.goal.key == "trick" and state.call("requirement_error", wish.requirements) == "", "desejo usa contador e história reais")
	check(db.get("routines").daily.missions.trick.goal.target == 2, "diária pede dois truques")
	var room: Control = load("res://scenes/levels/room/room.tscn").instantiate()
	room.set("room_id", "park")
	room.set("world_id", "park")
	root.add_child(room)
	await process_frame
	var target: Vector2 = room.call("nearest_floor_point", Vector2(150, 195))
	var start: Vector2 = room.call("nearest_floor_point", Vector2(238, 262))
	check(target.distance_to(Vector2(150, 195)) < 16 and not room.call("find_path", start, target).is_empty(), "cones alcançáveis sem mudar obstáculos")
	room.queue_free()
	await process_frame
	var old: Dictionary = p.to_dict()
	old.erase("tricks")
	p.from_dict(old)
	check(p.tricks.is_empty(), "save anterior sem migração")
	print("TRICKS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func _clothes() -> void:
	var p: RefCounted = state.get("progress")
	for id: String in ["yellow_bow", "red_scarf", "rain_coat"]:
		p.collection[id] = true
		state.call("equip", id)
	var target := TextureRect.new()
	root.add_child(target)
	var animator: Node = load("res://scripts/ui/pet_animator.gd").new()
	root.add_child(animator)
	animator.call("setup", target)
	for clip: String in ["give_paw", "bark", "roll_over", "happy_jump", "chase_tail"]:
		animator.call("react", StringName(clip))
		check(str(animator.get("_clip")) == clip, "animação existente " + clip)
		for slot: String in ["head", "neck", "body"]:
			check(animator.get("_clothes")[slot].visible == (clip in ["give_paw", "bark"]), "camada " + slot + " " + clip)
		animator.call("_finish_clip")
		check(animator.get("_clothes").head.visible, "roupas voltam após " + clip)
	check(p.equipped == {"head":"yellow_bow","neck":"red_scarf","body":"rain_coat"}, "três slots preservados")
	animator.queue_free()
	target.queue_free()
	await process_frame
