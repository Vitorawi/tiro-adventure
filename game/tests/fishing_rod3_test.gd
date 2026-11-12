extends SceneTree
## Pesca, etapa 08: vara do pescador (receita da bancada, missões do Guia), isca artificial, traíra/tucunaré/pintado,
## peixe com ervas (pelo brilhante) e o requisito do Mocinho. Relógio injetado e sem SaveManager.
## --headless --path game -s res://tests/fishing_rod3_test.gd

const T0 := 1900000000.0

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	_run.call_deferred()
	create_timer(150).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("VARA3: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _f() -> RefCounted:
	return state.get("fishing")


func _inv() -> RefCounted:
	return state.get("inventory")


func _fresh() -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", false)
	state.call("reset")
	state.set("coins", 500)


func _advance(seconds: float) -> void:
	state.set("test_time", float(state.get("test_time")) + seconds)


func _same(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size():
		return false
	for key: Variant in expected:
		if not actual.has(key) or int(actual[key]) != int(expected[key]):
			return false
	return true


func _row(id: String) -> Dictionary:
	for row: Dictionary in state.call("growth_info").requirements:
		if str(row.id) == id:
			return row
	return {}


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	Motion.reduced = true
	_guide_and_recipe()
	_lure_and_fish()
	_bar_and_rate()
	_herb_fish()
	_story()
	print("FISHING ROD3 TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# 1/2. Guia só depois do tesouro + molinete; receita entrega a vara (sem item) uma vez.
func _guide_and_recipe() -> void:
	_fresh()
	var q: Dictionary = db.get("quests")
	check(str(q.guide_angler.line) == "guide" and int(q.guide_angler.order) == 60, "1: guide_angler na linha do Guia, ordem 60")
	check(q.guide_angler.requirements.quests.has("guide_treasure") and str(q.guide_angler.requirements.rod) == "reel_rod", "1: pede o tesouro e a vara 2")
	check(bool(q.guide_angler.goals[0].fresh) and str(q.guide_angler.goals[0].key) == "talk:guide", "1: objetivo é falar com o Guia (fresh)")
	check(str(state.call("requirement_error", q.guide_angler.requirements)) != "", "1: no começo a missão está fechada")
	state.call("dev_give_rod", "reel_rod")
	check(str(state.call("requirement_error", {"rod": "angler_rod"})) != "", "1: sem a vara 3 o requisito explica")
	var recipe: Dictionary = db.get("recipes").angler_rod
	check(str(recipe.station) == "workbench" and str(recipe.output_rod) == "angler_rod" and not recipe.has("output"), "2: receita da bancada entrega a vara (sem item)")
	check(_same(recipe.inputs, {"hardwood": 3, "fiber": 4, "copper": 2}) and int(recipe.seconds) == 900, "2: 3 madeiras de lei, 4 fibras, 2 cobres, 15 min")
	check(recipe.requirements.quests == ["guide_angler"], "2: a receita abre com guide_angler")
	check(str(db.call("recipe_output", recipe)) == "angler_rod" and str(db.call("item_name", "angler_rod")) == "Vara do pescador", "2: nome da vara para a interface")
	check(db.call("item_icon", "angler_rod") != null, "2: ícone da vara")
	state.call("dev_grant_upgrade", "workbench")
	check(str(state.call("cook_error", "angler_rod")) != "", "2: sem a missão a receita não abre")
	state.call("dev_complete_quest", "guide_angler")
	check(str(state.call("cook_error", "angler_rod")).begins_with("Falta"), "2: sem materiais: " + str(state.call("cook_error", "angler_rod")))
	_inv().add("hardwood", 3)
	_inv().add("fiber", 4)
	_inv().add("copper", 2)
	check(str(state.call("cook_error", "angler_rod")) == "", "2: com os materiais dá para fazer: " + str(state.call("cook_error", "angler_rod")))
	check(int(state.call("cook_max", "angler_rod")) == 1, "2: só uma por vez")
	check(str(state.call("cook_many_error", "angler_rod", 2)) != "", "2: não deixa fazer duas")
	check(str(state.call("cook", "angler_rod")) == "", "2: começou")
	check(_inv().count("hardwood") == 0 and _inv().count("copper") == 0, "2: consumiu os materiais")
	check(str(state.call("cook_error", "angler_rod")) != "", "2: já está sendo feita")
	check(not _f().has_rod("angler_rod"), "2: a vara só vem ao recolher")
	state.call("dev_finish_timers")
	var got: Dictionary = state.call("collect", "workbench")
	check(_f().has_rod("angler_rod") and got.has("angler_rod"), "2: recolher entrega a vara")
	check(_p().stat("rod:angler_rod") == 1 and _p().stat("produce:angler_rod") == 1, "2: conta rod: e produce:")
	check(_inv().count("angler_rod") == 0, "2: a vara não vira item")
	check(str(state.call("cook_error", "angler_rod")) == "Você já tem", "2: depois: Você já tem")
	_inv().add("hardwood", 3)
	_inv().add("fiber", 4)
	_inv().add("copper", 2)
	check(str(state.call("cook", "angler_rod")) == "Você já tem" and _inv().count("hardwood") == 3, "2: tentar de novo não gasta")
	var again: Dictionary = state.call("collect", "workbench")
	check(again.is_empty() and _p().stat("rod:angler_rod") == 1, "2: recolher de novo não duplica")


# 3. Isca artificial e os três peixes da vara 3.
func _lure_and_fish() -> void:
	_fresh()
	var lure: Dictionary = db.get("recipes").bait_lure
	check(_same(lure.inputs, {"copper": 1, "stick": 1}) and int(lure.qty) == 1 and int(lure.seconds) == 120 and str(lure.requirements.rod) == "angler_rod", "3: receita da isca artificial")
	state.call("dev_give_rod", "angler_rod")
	state.call("dev_grant_upgrade", "workbench")
	_inv().add("copper", 1)
	_inv().add("stick", 1)
	check(str(state.call("cook", "bait_lure")) == "", "3: dá para fazer a isca: " + str(state.call("cook_error", "bait_lure")))
	state.call("dev_finish_timers")
	state.call("collect", "workbench")
	check(_inv().count("bait_lure") == 1, "3: recolheu a isca")
	check(float(db.get("fishing").baits.bait_lure.keep_chance) == 0.7, "3: keep_chance 0,7")
	var seen := {}
	for i in 60:
		_inv().add("bait_lure", 3)
		state.set("test_time", T0 + 1000.0 * i)
		check(str(state.call("cast", "bait_lure", 1 + i % 3)) == "", "3: lançou a isca " + str(i))
		_advance(float(_f().cast.wait) + 0.1)
		check(str(state.call("hook")) == "", "3: fisgou " + str(i))
		seen[str(_f().cast.fish)] = true
		state.call("cancel_fishing")
	var ok := true
	for id: String in seen:
		if id not in ["fish_traira", "fish_tucunare", "fish_pintado"]:
			ok = false
	check(ok and seen.size() >= 2, "3: a isca artificial só sorteia traíra, tucunaré e pintado (%s)" % str(seen.keys()))
	# 100 pescas: ~70% não gastam a isca.
	_fresh()
	state.call("dev_give_rod", "angler_rod")
	var spent := 0
	for i in 100:
		_inv().add("bait_lure", 3)
		var before: int = _inv().count("bait_lure")
		state.set("test_time", T0 + 1000.0 * i)
		state.call("cast", "bait_lure", 1)
		_advance(float(_f().cast.wait) + 0.1)
		state.call("hook")
		if _inv().count("bait_lure") < before:
			spent += 1
		state.call("cancel_fishing")
	check(spent >= 20 and spent <= 40, "3: ≈30 de 100 pescas gastam a isca (%d)" % spent)
	var fish: Dictionary = db.get("fishing").fish
	for id: String in ["fish_traira", "fish_tucunare", "fish_pintado"]:
		check(str(fish[id].bait) == "bait_lure", "3: " + id + " pede a isca artificial")
	check(str(fish.fish_traira.motion) == "darter" and str(fish.fish_tucunare.motion) == "darter" and str(fish.fish_pintado.motion) == "sinker", "3: perfis darter/darter/sinker")


## Piloto com reação de `delay` ticks (18 = 0,3 s): segura quando o peixe (visto com atraso) está acima do centro da barra
## ou quando a barra está caindo rápido demais; devolve se pegou.
func _pilot(config: Dictionary, fish_def: Dictionary, rod: Dictionary, seed_value: int, delay: int = 18) -> bool:
	# A altura real da barra é limitada por `bar_max` (ver `fishing_bar_height`).
	var height := minf(float(config.physics.bar_base) + float(rod.get("bar_bonus", 0.0)), float(config.physics.bar_max))
	var sim := FishingSim.new(config, fish_def, seed_value, height, rod)
	sim.bar_y = 0.3
	var history: Array[float] = []
	var guard := 0
	while not sim.finished and guard < 20000:
		guard += 1
		history.append(sim.fish_y)
		var seen_y: float = history[maxi(0, history.size() - 1 - delay)]
		var error: float = seen_y - (sim.bar_y + sim.bar_h / 2.0)
		var hold: bool = error + 0.12 * sim.bar_v > 0.0
		sim.step(hold, sim._tick)
	return sim.caught


# 4. Rebote 0 com a vara 3 e taxa de acerto de um piloto médio no pintado.
func _bar_and_rate() -> void:
	var config: Dictionary = db.get("fishing")
	var rods: Dictionary = config.rods
	check(float(rods.angler_rod.bounce) == 0.0 and float(rods.angler_rod.hold) == 0.30 and float(rods.angler_rod.bar_bonus) == 0.05, "4: vara 3: rebote 0, hold 0,30, barra +0,05")
	var sim := FishingSim.new(config, {"still": true, "difficulty": 20}, 3, 0.3, rods.angler_rod)
	sim.bar_y = 0.5
	sim.bar_v = -2.0
	for i in 200:
		sim.step(false, sim._tick)
		check(sim.bar_y >= 0.0, "4: a barra não passa do fundo")
	check(sim.bar_y == 0.0 and sim.bar_v == 0.0, "4: bate no fundo e para, sem quicar")
	var bamboo := FishingSim.new(config, {"still": true, "difficulty": 20}, 3, 0.3, rods.bamboo_rod)
	bamboo.bar_y = 0.5
	bamboo.bar_v = -2.0
	var bounced := false
	for i in 200:
		bamboo.step(false, bamboo._tick)
		if bamboo.bar_v > 0.05 and bamboo.bar_y < 0.2:
			bounced = true
	check(bounced, "4: controle negativo: a vara 1 ainda quica")
	var rates := {}
	for id: String in ["fish_lambari", "fish_traira", "fish_tucunare", "fish_pintado"]:
		var wins := 0
		for n in 100:
			if _pilot(config, config.fish[id], rods.angler_rod, 500 + n * 31):
				wins += 1
		rates[id] = wins
	print("VARA3 taxa de acerto do piloto (100 partidas, vara 3, reação 0,3 s): ", rates)
	var slow := {}
	for delay: int in [24, 30, 36]:
		var wins := 0
		for n in 100:
			if _pilot(config, config.fish.fish_pintado, rods.angler_rod, 500 + n * 31, delay):
				wins += 1
		slow[delay] = wins
	print("VARA3 pintado com reação mais lenta (ticks → acertos): ", slow)
	var bamboo_wins := 0
	for n in 100:
		if _pilot(config, config.fish.fish_pintado, rods.bamboo_rod, 500 + n * 31):
			bamboo_wins += 1
	print("VARA3 pintado com a vara 1 (controle): ", bamboo_wins)
	check(int(rates.fish_pintado) > 0, "4: o pintado é possível para o piloto (%d/100)" % int(rates.fish_pintado))
	check(int(rates.fish_pintado) >= bamboo_wins, "4: a vara 3 não piora o pintado (%d × %d com a vara 1)" % [int(rates.fish_pintado), bamboo_wins])


# 5. Peixe com ervas: receitas, momento de Pelagem (com teto) e o Mocinho.
func _herb_fish() -> void:
	_fresh()
	var item: Dictionary = db.get("items").herb_fish
	check(str(item.category) == "food" and str(item.storage) == "fridge" and int(item.sell_price) == 60, "5: item herb_fish")
	check(int(item.feed.hunger) == 35 and int(item.feed.hygiene) == 10 and item.growth.phases == ["young", "adult"], "5: feed e fases")
	var recipes: Dictionary = db.get("recipes")
	for pair: Array in [["herb_fish_pintado", "fish_pintado"], ["herb_fish_tucunare", "fish_tucunare"]]:
		var r: Dictionary = recipes[pair[0]]
		check(str(r.station) == "stove" and str(r.output) == "herb_fish" and int(r.qty) == 2 and int(r.seconds) == 720, "5: " + str(pair[0]) + " dados")
		check(_same(r.inputs, {pair[1]: 1, "herbs": 2}) and str(r.requirements.rod) == "angler_rod", "5: " + str(pair[0]) + " ingredientes e vara")
	var source: Dictionary = db.get("growth").moments.sources.herb_fish
	check(str(source.pillar) == "coat" and int(source.qty) == 1 and bool(source.capped) and not bool(source.first), "5: fonte de momento de Pelagem com teto")
	check(db.call("growth_problems").is_empty(), "5: growth.json sem problemas: " + str(db.call("growth_problems")))
	var facts := ""
	for phase: Dictionary in db.get("growth").phases:
		if str(phase.id) == "young":
			facts = str(phase.facts)
	check(facts.contains("ômega-3"), "5: fato do ômega-3 nos fatos do Mocinho")
	# Cozinhar de verdade.
	state.call("dev_grant_upgrade", "stove")
	state.call("dev_give_rod", "angler_rod")
	for pair: Array in [["herb_fish_pintado", "fish_pintado"], ["herb_fish_tucunare", "fish_tucunare"]]:
		_inv().add(pair[1], 1)
		_inv().add("herbs", 2)
		var before: int = _inv().count("herb_fish")
		check(str(state.call("cook", pair[0])) == "", "5: cozinhar " + str(pair[0]) + ": " + str(state.call("cook_error", pair[0])))
		state.call("dev_finish_timers")
		state.call("collect", "stove")
		check(_inv().count("herb_fish") == before + 2, "5: " + str(pair[0]) + " entrega 2 peixes com ervas")
	# Dar ao Tiro: 1 momento de Pelagem, com teto por período.
	_fresh()
	state.growth.phase = "young"
	_inv().add("herb_fish", 4)
	var coat_before: int = int(state.growth.moments.get("coat", 0))
	state.dog.needs["hunger"] = 10.0
	check(state.call("feed", "herb_fish"), "5: deu o primeiro")
	check(int(state.growth.moments.get("coat", 0)) == coat_before + 1, "5: 1 momento de Pelagem")
	for i in 3:
		state.dog.needs["hunger"] = 10.0
		state.call("feed", "herb_fish")
	var gained: int = int(state.growth.moments.get("coat", 0)) - coat_before
	var cap: int = int(db.get("growth").moments.period_cap)
	check(gained == cap, "5: o teto do período segura os momentos (%d de %d)" % [gained, cap])
	# Mocinho pede 2.
	_fresh()
	state.growth.phase = "explorer"
	var row := _row("fish_meal")
	check(not row.is_empty() and int(row.need) == 2 and str(row.item) == "herb_fish", "5: o Mocinho pede 2 peixes com ervas")
	check(not row.has("body_level") or int(row.get("body_level", 0)) == 0, "5: o peixe não leva Corpo")
	check(int(_row("meals").need) == 3 and str(_row("meals").item) == "milk_porridge", "5: a papinha de leite continua pedindo 3")
	state.call("dev_complete_growth_reqs")
	state.growth.done["young"]["fish_meal"] = false
	check(str(state.call("grow_error")).contains("Peixe com ervas"), "5: falta o peixe: " + str(state.call("grow_error")))
	var body_before: int = state.growth.body_level
	for i in 2:
		_inv().add("herb_fish", 1)
		state.dog.needs["hunger"] = 10.0
		check(state.call("feed", "herb_fish"), "5: dar o peixe %d" % i)
	check(bool(_row("fish_meal").done), "5: 2 peixes cumprem o passo")
	check(state.growth.body_level == body_before, "5: o Corpo não mudou")
	check(_p().stat("feed:herb_fish") == 2, "5: conta feed:herb_fish")


# 6. Missões.
func _story() -> void:
	var q: Dictionary = db.get("quests")
	var rod: Dictionary = q.guide_angler_rod
	check(str(rod.line) == "guide" and int(rod.order) == 62 and str(rod.goals[0].key) == "rod:angler_rod", "6: guide_angler_rod pede a vara")
	check(int(rod.rewards.items.bait_lure) == 4 and rod.requirements.quests == ["guide_angler"], "6: prêmio 4 iscas e vem depois do guide_angler")
	check(str(rod.go.place) == "workbench", "6: Ir leva à bancada")
	var big: Dictionary = q.guide_pintado
	check(int(big.order) == 64 and str(big.goals[0].key) == "fish:fish_pintado" and int(big.rewards.coins) == 40, "6: guide_pintado 40 moedas")
	var shiny: Dictionary = q.lais_shiny_coat
	check(str(shiny.kind) == "main" and int(shiny.chapter) == 9 and int(shiny.rewards.coins) == 30, "6: lais_shiny_coat no capítulo 9, 30 moedas")
	check(str(shiny.goals[0].key) == "produce:herb_fish" and str(shiny.goals[1].key) == "feed:herb_fish" and bool(shiny.goals[0].fresh) and bool(shiny.goals[1].fresh), "6: contadores reais e fresh")
	check(int(shiny.order) > int(q.main_8_building.order) and int(shiny.order) < int(q.growth_9_young.order), "6: antes de growth_9_young")
	# As ordens do Guia não colidem.
	var orders := {}
	for id: String in q:
		if str(q[id].get("line", "")) == "guide":
			check(not orders.has(int(q[id].order)), "6: ordem repetida na linha do Guia: " + id)
			orders[int(q[id].order)] = true
	# Cumprir de verdade: pescar o pintado e fazer a vara conta os contadores.
	_fresh()
	state.call("dev_give_rod", "reel_rod")
	state.call("dev_complete_quest", "guide_treasure")
	check(str(state.call("requirement_error", q.guide_angler.requirements)) == "", "6: com o tesouro e a vara 2 a missão abre: " + str(state.call("requirement_error", q.guide_angler.requirements)))
	state.call("give_rod", "angler_rod")
	check(_p().stat("rod:angler_rod") == 1, "6: ter a vara cumpre guide_angler_rod")
	state.call("_count", "fish:fish_pintado")
	check(_p().stat("fish:fish_pintado") >= 1, "6: o pintado cumpre guide_pintado")
