extends SceneTree
## Jeito, memória curta, diário e decisões visuais, sem percorrer a campanha.
var failures := 0
var state: Node
var db: Node
var rules: Script
var animator: Script
var pillar_ui: Script

func _initialize() -> void:
	_run.call_deferred()
	create_timer(170).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("PERSONALITY: " + message)

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	rules = load("res://scripts/state/personality_rules.gd")
	animator = load("res://scripts/ui/pet_animator.gd")
	pillar_ui = load("res://scripts/ui/pillar_ui.gd")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.test_time = 1791936000.0
	var examples := {"walk": "explorer", "feed": "foodie", "play": "playful", "care_useful:pet": "cuddly", "bathe": "calm"}
	for counter: String in examples:
		state.reset()
		for day in 4:
			state.test_time += 86400
			state._count(counter, 20)
		check(state.growth.personality.current == examples[counter], "contador leva ao jeito: " + counter)
		for phase: Dictionary in db.growth.phases:
			state.growth.phase = phase.id
			check((rules.id(state.growth) != "") == (state.growth.phase_index() >= 3), "revelado em Aventureiro: " + str(phase.id))
		state.growth.phase = "explorer"
		var data: Dictionary = state.to_dict()
		state.from_dict(data)
		check(state.growth.personality.current == examples[counter], "jeito persiste")
	state.reset()
	state.growth.phase = "explorer"
	for day in 14:
		state.test_time += 86400
		state._count("walk", 3)
	state.test_time += 86400
	state._count("play", 10000)
	check(rules.id(state.growth) == "explorer", "um dia diferente não troca")
	for day in 40:
		state.test_time += 86400
		state._count("play", 5)
	check(rules.id(state.growth) == "playful", "rotina prolongada muda devagar")
	check(state.growth.personality.days.size() == 14, "janela de dias jogados limitada")
	var memory: Dictionary = state.growth.personality.duplicate(true)
	state.test_time -= 100 * 86400
	state._count("play")
	check(state.growth.personality.days.size() == 14 and state.growth.personality.played_days == memory.played_days, "relógio atrasado não fabrica dias")
	state.reset()
	state._count("pet", 1000)
	check(state.growth.personality.is_empty(), "carinho sem utilidade não pontua")
	state._count("care_useful:pet", 4)
	check(state.growth.personality.current == "cuddly", "carinho útil pontua")
	state.reset()
	state.growth.phase = "explorer"
	check("personality:revealed" in state.new_unlocks(), "Novo ao revelar")
	state.mark_seen(["personality:revealed"] as Array[String])
	state.from_dict(state.to_dict())
	check("personality:revealed" not in state.new_unlocks(), "Novo não duplica no reload")
	for phase: Dictionary in db.growth.phases:
		state.growth.phase = phase.id
		state.growth.personality.current = "explorer"
		var behavior: Dictionary = rules.behavior(state.growth)
		var original: Dictionary = db.growth.behaviors.phases[phase.id]
		check(behavior.idle_seconds == original.idle_seconds, "intervalo vem do dado")
		check(float(behavior.fidgets.sniff) == float(original.fidgets.sniff) + (3 if state.growth.phase_index() >= 3 else 0), "peso de fase/jeito vem do dado")
		for clip: String in behavior.fidgets:
			check(StringName(clip) in animator.FPS, "clipe existente: " + clip)
	var dog: Node = load("res://scenes/entities/dog_world/dog_world.gd").new()
	state.growth.phase = "puppy"
	check(dog.idle_choice(0.1) == "nap", "filhote cochila")
	state.growth.phase = "adult"
	check(dog.idle_choice(0.3) == "sit", "adulto senta")
	dog.free()
	# Primeira prova e foto vêm das ações reais, sem mudar o efeito do cuidado.
	state.reset()
	state.growth.phase = "puppy"
	state.inventory.add("carrot", 3)
	check(state.feed("carrot"), "comida real")
	check(state.growth.diary.any(func(e: Dictionary) -> bool: return e.kind == "taste"), "primeira prova no diário")
	var before: int = state.growth.diary.size()
	state.from_dict(state.to_dict())
	state.feed("carrot")
	check(state.growth.diary.size() == before, "primeira prova não repete após reload")
	state._take_photo("h_arrival")
	check(state.growth.diary.back().kind == "photo", "foto no diário")
	state.dev_complete_growth_reqs()
	check(state.grow() == "", "crescimento real")
	check(state.growth.diary.any(func(e: Dictionary) -> bool: return e.kind == "grew"), "crescimento no diário")
	state.dev_unlock_everything()
	state.progress.collection.erase("plaid_bow")
	state.walk_state.pity["park_loop"] = 5
	check(state.start_walk("park_loop") == "", "passeio real inicia")
	state.test_time += 3600
	check(state.return_due_walk(), "passeio real volta")
	check(state.growth.diary.any(func(e: Dictionary) -> bool: return e.kind == "walk"), "passeio no diário")
	check(state.growth.diary.any(func(e: Dictionary) -> bool: return e.kind == "rare" and "plaid_bow" not in e.text), "raro usa nome visível")
	var diary: Array = state.growth.diary.duplicate(true)
	state.from_dict(state.to_dict())
	state.return_due_walk()
	check(state.growth.diary == diary, "volta já concluída não duplica ao recarregar")
	for i in 30: state._diary("rare", "pedra %d" % i)
	check(state.growth.diary.size() == 20 and "pedra 10" in state.growth.diary.front().text, "limite conserva as últimas 20")
	state.from_dict(state.to_dict())
	state._take_photo("h_arrival")
	check(state.growth.diary.size() == 20 and state.growth.diary.back().kind == "rare", "recibo de foto sobrevive ao descarte da linha")
	var ui: Control = pillar_ui.panel()
	check(ui.find_child("GrowthDiary", true, false) != null, "diário no caderninho")
	ui.free()
	print("PERSONALITY TEST: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)

