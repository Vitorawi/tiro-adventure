extends SceneTree
## Pesca, etapa 06: papinha de peixe, Dentinhos, missões do capítulo 3 e minhoca na colheita. Sem SaveManager.
## --headless --path game -s res://tests/fishing_story_test.gd

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PESCA_HISTORIA: " + message)


func _fresh() -> void:
	state.reset()
	state.growth.phase = "puppy"
	for need: String in state.dog.needs:
		state.dog.needs[need] = 40.0
	state.dog.updated_at = state.now()


func _row(id: String) -> Dictionary:
	for row: Dictionary in state.growth_info().requirements:
		if str(row.id) == id:
			return row
	return {}


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	Motion.reduced = true

	# 1. Receita bloqueada sem fogão/vara; liberada depois de first_kitchen com a vara.
	_fresh()
	state.inventory.add("fish_tilapia", 2)
	state.inventory.add("potato", 2)
	var reqs: Dictionary = db.recipes.fish_mash.requirements
	check(state.requirement_error(reqs) != "", "receita bloqueada no começo")
	state.progress.claimed_quests["first_kitchen"] = true
	check(state.requirement_error(reqs) != "", "sem a vara continua bloqueada")
	state.give_rod("bamboo_rod")
	check(state.requirement_error(reqs) == "", "com cozinha e vara libera: " + state.requirement_error(reqs))

	# 2. Cozinhar consome 1 tilápia + 1 batata e entrega 1 papinha; dar ao Tiro conta feed:fish_mash.
	state.dev_grant_upgrade("stove")
	check(state.cook("fish_mash") == "", "cozinhar a papinha: " + state.cook_error("fish_mash"))
	check(state.inventory.count("fish_tilapia") == 1 and state.inventory.count("potato") == 1, "consome 1 tilápia e 1 batata")
	state.dev_finish_timers()
	state.collect("stove")
	check(state.inventory.count("fish_mash") == 1, "entrega 1 papinha")
	check(state.progress.stat("produce:fish_mash") == 1, "conta produce:fish_mash")
	var body_before: int = state.growth.body_level
	check(state.feed("fish_mash"), "dar a papinha ao Tiro")
	check(state.progress.stat("feed:fish_mash") == 1, "conta feed:fish_mash")
	check(state.growth.body_level == body_before, "papinha não muda o Corpo")

	# 3/4. Dentinhos: o prato-chave usa o peixe da lagoa.
	_fresh()
	var fish_row := _row("key_fish")
	check(not fish_row.is_empty() and int(fish_row.need) == 1, "Dentinhos pedem um prato com peixe")
	state.inventory.add("fish_mash", 1)
	check(state.feed("fish_mash"), "alimentar com papinha de peixe")
	check(bool(_row("key_fish").done), "a papinha cumpre o prato-chave")

	# 5. Missão do capítulo 3.
	var q: Dictionary = db.quests.week_fish_dish
	check(str(q.kind) == "main" and int(q.chapter) == 6, "O prato-chave é do capítulo 6")
	check(int(q.order) > int(db.quests.week_fish.order), "O prato-chave vem após pescar")
	check(q.goals[0].type == "week_dish" and q.goals[0].key == "fish", "objetivo usa o requisito do Para crescer")
	check(str(q.go.place) == "stove", "Ir leva ao fogão")

	# 6. Tilápia Grande (e Gigante) completa a vovó.
	var big: Dictionary = db.quests.bloblo_big_tilapia
	check(big.requirements.quests.has("week_fish_dish"), "bloblo_big_tilapia depende da papinha")
	var key := str(big.goals[0].key)
	check(key == "fish_size:large:fish_tilapia", "chave do objetivo: " + key)
	_fresh()
	var base: int = state.progress.stat(key)
	state.give_rod("bamboo_rod")
	state._count("fish_size:large:fish_tilapia")
	check(state.progress.stat(key) == base + 1, "Grande conta")

	# 7. Minhoca na colheita: 100 colheitas ≈ 15 (±6) com a vara; nenhuma sem.
	var with_rod := _harvest_worms(true)
	var without := _harvest_worms(false)
	check(with_rod >= 9 and with_rod <= 21, "minhocas com vara: %d" % with_rod)
	check(without == 0, "sem vara nenhuma minhoca: %d" % without)

	# 8. GrowthUi: passo do Dentinhos.
	_fresh()
	var view: Dictionary = load("res://scripts/ui/growth_ui.gd").call("step_view", _row("key_fish"))
	check(int(view.need) == 1 and int(view.have) == 0, "GrowthUi 0/1")
	check(str(view.hint).contains("peixe"), "GrowthUi mostra a refeição com peixe")

	print("FISHING STORY TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


func _harvest_worms(with_rod: bool) -> int:
	_fresh()
	state.dev_grant_upgrade("farm")
	state.progress.claimed_quests.clear()  # a lagoa (e a vara de bambu) abre pelo capítulo 3
	state.unlocked_plots = 4
	state.fishing.rods.clear()
	if with_rod:
		state.give_rod("bamboo_rod")
	var total := 0
	for n in 100:
		var index := n % 4
		state.inventory.remove_all({"carrot": state.inventory.count("carrot")})
		state.plots[index] = {"crop": "carrot", "ready_at": 0.0, "planted_at": float(1000 + n * 7)}
		var before: int = state.inventory.count("bait_worm")
		state.harvest(index)
		total += state.inventory.count("bait_worm") - before
		state.inventory.remove_all({"bait_worm": state.inventory.count("bait_worm")})
	return total
