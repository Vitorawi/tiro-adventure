extends SceneTree
## Etapa 15: 32 novas fotos por ações reais; casos negativos, calendário, dicas e persistência.
var state: Node
var db: Node
var rules: Variant
var view: Variant
var fixture: Dictionary
var failures := 0
var covered: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()
	create_timer(170).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Segredos: " + message)

func _fresh() -> void:
	state.test_time = 1792440000.0
	state.from_dict(fixture.duplicate(true))
	state.dev_reset_album()
	state.progress.seen["intro"] = true
	state.progress.stats = {}
	state.progress.equipped = {"head": "", "neck": "", "body": ""}
	state.progress.house.toys = []
	state.progress.tricks = {}
	state.growth.phase = "explorer"
	state.dog.affection = 0
	state.dog.setup(state.now())
	for need: String in state.dog.needs: state.dog.needs[need] = 50.0
	state.friend_state.friends = {}
	state.projects.reset()
	state.album_world = "house"
	state.album_sleep_spot = ""

func _date(day: String, hour: int = 12) -> void:
	state.test_time = Time.get_unix_time_from_datetime_string(day + "T%02d:00:00" % hour)
	state.dog.updated_at = state.now()

func _friend(id: String, gifts: int) -> void:
	var entry: Dictionary = state.friend_state.entry(id).duplicate(true)
	entry.gifts = gifts
	state.friend_state.friends[id] = entry

func _project(id: String) -> void:
	var entry: Dictionary = state.projects.entry(id).duplicate(true)
	entry.started = true
	entry.completed = true
	entry.completion_rewarded = true
	entry.completed_at = state.now() - 2 * 86400
	state.projects.projects[id] = entry

func _photo(id: String, act: Callable, positive: bool) -> void:
	check(not state.album.has_photo(id), id + " antes da ação")
	act.call()
	check(state.album.has_photo(id) == positive, id + (" combinação completa" if positive else " condição ausente"))
	if positive:
		covered.append(id)
		var snapshot: Dictionary = state.photo_info(id)
		state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
		act.call()
		check(state.photo_info(id) == snapshot, id + " recarga sem duplicar/regravar")

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	rules = load("res://scripts/state/album_rules.gd")
	view = load("res://scripts/ui/album_view.gd")
	state.test_time = 1792440000.0
	state.reset()
	state.dev_unlock_everything()
	fixture = state.to_dict()
	check(db.album_problems().is_empty(), str(db.album_problems()))
	for positive in [false, true]:
		for entry: Dictionary in db.album.photos:
			if str(entry.section) in ["story", "firsts"]: continue
			_fresh()
			_case(str(entry.id), positive)
	_hints()
	_photobomb()
	_calendar()
	_gesture()
	check(covered.size() == 32, "32 fotos novas cobertas: " + str(covered))
	print("PHOTO COVERAGE: ", covered)
	print("ALBUM_SECRETS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)

func _case(id: String, yes: bool) -> void:
	match id:
		"s_foam_ghost":
			if yes: state.bathe()
			_photo(id, func() -> void: state.pet(), yes)
		"s_carrot_thief":
			state.album_world = "farm"
			state.dog.needs.hunger = 20.0 if yes else 60.0
			state.plots[0] = {"crop": "carrot", "ready_at": state.now() - 1}
			_photo(id, func() -> void: state.harvest(0), yes)
		"s_hero_shadow":
			_date("2026-10-19", 18 if yes else 15)
			_photo(id, func() -> void: state.note_dog_tapped("park"), yes)
		"s_sock_hunter":
			state.growth.phase = "teething" if yes else "adult"
			state.note_object_tapped("laundry_basket", "house")
			_photo(id, func() -> void: state.note_object_tapped("laundry_basket", "house"), yes)
		"s_blueberry_face":
			state.inventory.add("blueberry", 3)
			state.inventory.add("apple", 3)
			_photo(id, func() -> void: state.feed("blueberry" if yes else "apple"), yes)
		"s_soap_explorer":
			if yes: check(state.equip("explorer_hat") == "", "chapéu veste pela ação real")
			_photo(id, func() -> void: state.bathe(), yes)
		"s_sprinkler":
			state.album_world = "farm" if yes else "house"
			state.unlocked_plots = 5
			for i in 5: state.plots[i] = {"crop": "carrot", "ready_at": state.now() + 300, "watered": false}
			_photo(id, func() -> void:
				state.begin_album_water_drag()
				for i in 5: state.water(i)
				state.end_album_water_drag(), yes)
		"s_sofa_throne", "p_sofa":
			_photo(id, func() -> void: state.set_sleeping(true, "sofa" if yes else "bed"), yes)
		"s_photobomb":
			_friend("pipoca", 1 if yes else 0)
			state.dev_take_photo("h_arrival")
			state.album.photobomb_pity = 7
			_photo(id, func() -> void: state.open_album_photo("h_arrival"), yes)
		"s_moon_friend":
			_project("park_bench")
			_date("2026-10-19", 22 if yes else 16)
			_photo(id, func() -> void: state.use_project("park_bench"), yes)
		"s_zoomies":
			state.growth.phase = "explorer" if yes else "puppy"
			state.play()
			state.play()
			_photo(id, func() -> void: state.play(), yes)
		"s_begging":
			state.dog.needs.hunger = 20.0 if yes else 70.0
			_photo(id, func() -> void: state.note_object_tapped("fridge", "house"), yes)
		"s_muddy":
			state.dog.needs.hygiene = 10.0 if yes else 100.0
			state.walk_state.current = {"id": "creek_walk", "started_at": state.now() - 5000, "ready_at": state.now() - 1, "seed": 1}
			_photo(id, func() -> void: state.return_due_walk(), yes)
		"p_curled":
			_photo(id, func() -> void: state.set_sleeping(yes), yes)
		"p_belly_up":
			state.dog.affection = 1000
			state.dog.needs.happiness = 100.0 if yes else 50.0
			_photo(id, func() -> void: state.set_sleeping(true), yes)
		"p_ball_hug":
			_date("2026-10-19", 23)
			if yes: state.progress.house.toys.append("lost_ball")
			_photo(id, func() -> void: state.set_sleeping(true), yes)
		"p_pipoca":
			state.set_sleeping(yes)
			var entry: Dictionary = state.friend_state.entry("pipoca").duplicate(true)
			entry.visit_pending = true
			entry.visit_gift = {"items": {}, "coins": 0}
			state.friend_state.friends.pipoca = entry
			_photo(id, func() -> void: state.collect_friend_visit("pipoca"), yes)
		"p_crown":
			state.progress.equipped.head = "flower_crown"
			state.dog.needs.happiness = 100.0 if yes else 50.0
			_photo(id, func() -> void: state.set_sleeping(true), yes)
		"p_sweater":
			_date("2026-07-19" if yes else "2026-10-19")
			state.progress.equipped.body = "knit_sweater"
			_photo(id, func() -> void: state.set_sleeping(true), yes)
		"p_luxe":
			if not yes: state.progress.owned.erase("bed_luxe")
			_photo(id, func() -> void: state.set_sleeping(true, "bed"), yes)
		"a_pipoca":
			_friend("pipoca", 5 if yes else 0)
			state.friend_state.visitor = "pipoca"
			state.friend_state.visitor_window = state.friend_window()
			state.inventory.add("carrot_snack", 5)
			_photo(id, func() -> void: state.give_friend("pipoca"), yes)
		"a_nina_class":
			state.dog.affection = 1000
			state.growth.phase = "young"
			for key: String in db.progression.tricks:
				if key != "spin": state.progress.tricks[key] = yes
			_photo(id, func() -> void: state.learn_trick("spin"), yes)
		"a_bloblo_helper":
			state.progress.stats["order:snacks"] = 19 if yes else 0
			for item: String in db.progression.orders.snacks.inputs: state.inventory.add(item, 100)
			_photo(id, func() -> void: state.fulfill_order("snacks"), yes)
		"a_gathering":
			_project("village_festival")
			state.progress.stats["project_gather:village_festival"] = 2 if yes else 0
			for item: String in state.meeting_def("village_festival").items: state.inventory.add(item, 10)
			_photo(id, func() -> void: state.gather_project("village_festival"), yes)
		"a_lais_lap":
			state.dog.affection = 1000 if yes else 0
			_photo(id, func() -> void: state.pet(), yes)
		"a_four_friends":
			for friend: String in ["pipoca", "mel", "bolota", "fred"]: _friend(friend, 1 if yes else 0)
			# The public gift action must cause a heart transition for the final friend.
			_friend("pipoca", 0)
			state.friend_state.visitor = "pipoca"
			state.friend_state.visitor_window = state.friend_window()
			state.inventory.add("carrot_snack", 5)
			_photo(id, func() -> void: state.give_friend("pipoca"), yes)
		"d_month":
			state.progress.started_at = state.now() - (31 if yes else 20) * 86400
			_photo(id, func() -> void: state.note_app_opened(), yes)
		"d_gotcha":
			_date("2025-10-19")
			state.progress.started_at = state.now()
			_date("2026-10-21" if yes else "2026-10-27")
			_photo(id, func() -> void: state.note_app_opened(), yes)
		"d_full_moon":
			state.test_time = rules.NEW_MOON + rules.SYNODIC * 0.5 * 86400
			# Reference full moon evening, use local civil hour while keeping the ±1 day window.
			var date := Time.get_date_string_from_unix_time(int(state._local_time()))
			_date(date, 22 if yes else 12)
			_photo(id, func() -> void: state.note_world_visit("park"), yes)
		"d_first_cold":
			_date("2026-07-19")
			if yes: state.progress.equipped.body = "knit_sweater"
			_photo(id, func() -> void: state.note_app_opened(), yes)
		"d_after_party":
			_project("village_festival")
			if not yes: state.projects.projects.village_festival.completed_at = state.now()
			_photo(id, func() -> void: state.note_world_visit("village"), yes)

func _hints() -> void:
	_fresh()
	check(state.reveal_photo_hint("s_foam_ghost") == "", "lupa grátis")
	check(state.reveal_photo_hint("s_begging") != "", "limite diário")
	state.from_dict(state.to_dict())
	check(state.album.hints.has("s_foam_ghost"), "lupa persistida")
	state.test_time += 86400
	check(state.reveal_photo_hint("s_begging") == "", "novo dia")
	state.test_time -= 86400
	check(state.reveal_photo_hint("p_crown") != "", "voltar relógio não devolve lupa")
	for entry: Dictionary in db.album.photos.slice(0, 12): state.dev_take_photo(str(entry.id))
	check(state.album_lupas_left() == 1, "câmera dá segunda lupa")
	check(state.reveal_photo_hint("p_crown") == "", "lupa da câmera")
	state.note_album_section("tricks")
	check(state.album_talk("bloblo") == "", "sem fala antes de três dias")
	state.test_time += 3 * 86400
	var text: String = state.album_talk("bloblo")
	check(text != "", "fala após três dias")
	state.from_dict(state.to_dict())
	check(state.album_talk("bloblo") != text, "fala não se repete após recarregar")
	state.album_world = "farm"
	state.dog.needs.hunger = 20.0
	check(state.album_hint_glow("plot"), "brilho com duas das três condições")
	state.dog.needs.hunger = 80.0
	state.dog.updated_at = state.now()
	check(not state.album_hint_glow("plot"), "sem brilho com uma condição")
	state.dev_take_photo("h_first_trick")
	text = state.album_talk("nina")
	check(text.contains("Pata"), "personagem comenta foto")
	state.from_dict(state.to_dict())
	check(state.album_talk("nina") != text, "comentário único")
	state.dev_take_photo("h_guardian")
	check(state.album_talk("lais").contains("turma"), "foto da turma é comentada pela Laís")
	check(state.album_talk("bloblo").contains("turma"), "cada personagem comenta a foto da turma")
	var panel: Control = view.secret_detail("p_belly_up")
	check(panel.find_child("HintButton", true, false) != null, "lupa acessível no painel")
	panel.free()
	var npc: Node2D = load("res://scenes/entities/npc_world/npc_world.gd").new()
	npc.set("friend_id", "pipoca")
	var frames: SpriteFrames = npc.call("_build_frames")
	check(frames.has_animation("sleep_east"), "Pipoca tem pose real de sono no mundo")
	npc.free()

func _photobomb() -> void:
	_fresh()
	_friend("pipoca", 1)
	state.open_album_photo("h_arrival")
	check(state.album.photobomb_pity == 0, "foto inexistente não conta abertura")
	state.dev_take_photo("h_arrival")
	for i in 8:
		state.open_album_photo("h_arrival")
	check(state.album.has_photo("s_photobomb"), "oito aberturas reais garantem Penetra")

func _calendar() -> void:
	_fresh()
	_date("2024-02-29")
	state.progress.started_at = state.now()
	_date("2025-02-28")
	state.note_app_opened()
	check(state.album.has_photo("d_gotcha") and state.tiro_party(), "ano bissexto e festa")
	check(state.album.party_until - state.now() < 7.0 * 86400.0, "festa termina na janela do aniversário")
	check(state.content_error("recipe", "birthday_cake", db.recipes.birthday_cake) == "", "receita do bolo liberada")
	for item: String in db.recipes.birthday_cake.inputs: state.inventory.add(item, 1)
	check(state.cook("birthday_cake") == "", "bolo usa a fila real do fogão")
	state.test_time += 601
	state.collect("stove")
	check(state.inventory.count("birthday_cake") >= 1, "bolo pronto pode ser pego")
	var until: float = state.album.party_until
	state.note_app_opened()
	check(state.album.party_until == until, "não renova festa no mesmo ano")
	_date("2026-02-28")
	state.note_app_opened()
	check(int(state.album.years.gotcha) == 2026 and state.tiro_party(), "festa volta no ano seguinte")
	state.from_dict(state.to_dict())
	_date("2025-02-28")
	state.note_app_opened()
	check(int(state.album.years.gotcha) == 2026 and not state.tiro_party(), "voltar data não reabre festa")
	check(rules.full_moon(947182440.0 + 29.530588853 * 0.5 * 86400), "lua cheia referência janeiro 2000")
	check(not rules.full_moon(947182440.0), "lua nova não é cheia")
	check(rules.full_moon(Time.get_unix_time_from_datetime_string("2000-01-21T04:40:00")), "lua cheia em data conhecida")
	check(state.album.occurrences("futuro", 60, state.now()) == 0, "evento futuro não conta")

func _gesture() -> void:
	_fresh()
	state.album_world = "farm"
	state.unlocked_plots = 6
	for i in 6: state.plots[i] = {"crop": "carrot", "ready_at": state.now() + 300, "watered": false}
	state.begin_album_water_drag()
	for i in 3: state.water(i)
	state.end_album_water_drag()
	state.begin_album_water_drag()
	for i in range(3, 6): state.water(i)
	state.end_album_water_drag()
	check(not state.album.has_photo("s_sprinkler"), "dois arrastos não se somam")
	_fresh()
	state.set_sleeping(true, "sofa")
	state.from_dict(state.to_dict())
	check(state.album_sleep_spot == "sofa", "lugar da soneca persistido")
