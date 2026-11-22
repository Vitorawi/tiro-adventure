extends SceneTree
## F04b do plano "Novo fluxo": a missão secreta da vovó (Ensopado Dourado).
## Só com `only_paws_left()`; minhoca gorda só com a missão aberta (garantia no 4º montinho); peixe dourado 1/dia e só
## Perfeito; ensopado só pelo Cozinhar junto com 3 estrelas; patinha extra só ao vivo na janela (1/dia, teto 2).

var failures := 0
var state: Node
var db: Node


func _initialize() -> void:
	run.call_deferred()


func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("F04b · " + message)


## Save novo, relógio fixo (9h do dia 1), fase Filhotinho com a lista do Dentinhos pronta menos as patinhas (ou não).
func _fresh(paws_only: bool) -> void:
	state.reset()
	state.set_clock(1792411200.0)
	state.reset()
	state.call("_count", "arrival_box")
	state.dev_week_goto(1)
	state.dev_content_day(11)
	state.growth.phase = "puppy"
	if paws_only:
		var info: Dictionary = state.growth_info()
		var target := str(info.next.id)
		if not state.growth.done.has(target):
			state.growth.done[target] = {}
		for row: Dictionary in info.requirements:
			if str(row.get("counter", "")) != "well_fed_day":
				state.growth.done[target][str(row.id)] = true
	state.dev_give_rod("bamboo_rod")
	state.finish_fishing_tutorial()
	state.dev_week_hour(9)


func _fish_once(perfect: bool) -> String:
	var error: String = state.cast("golden_worm", 1)
	if error != "":
		return error
	state.fishing.cast["wait"] = 0.0
	error = state.hook()
	if error != "":
		return error
	return state.finish_fishing({"caught": true, "score": 1.0, "perfect": perfect, "chest": false})


func _stew_stars(stars: int, together: bool) -> String:
	state.inventory.add("fish_golden", 1)
	state.inventory.add("pumpkin", 1)
	state.inventory.add("egg", 1)
	return state.cook_many("golden_stew", 1, stars, together)


func run() -> void:
	root.get_node("SaveManager").free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	var cfg: Dictionary = db.meals.get("secret", {})
	check(not cfg.is_empty(), "config.json → meals.secret existe")

	# 1. A missão só aparece quando faltam apenas as patinhas.
	_fresh(false)
	check(not state.secret_open() and state.progress.current_line_quest("secret") == "", "lista cheia: sem missão secreta")
	_fresh(true)
	check(state.only_paws_left() and state.secret_open(), "só faltam as patinhas: aberta")
	check(state.progress.current_line_quest("secret") == "bloblo_secret", "a missão da vovó aparece")
	check(load("res://scripts/ui/places.gd").call("npc_badge", "bloblo") in ["secret", "ready"], "balão da vovó mostra o selo Segredo")
	state.growth.phase = "teething"
	check(not state.secret_open(), "depois de crescer a missão some")

	# 2. Minhoca gorda: só com a missão aberta, com garantia no 4º montinho.
	_fresh(false)
	state.finds.worlds["farm"] = {"next_at": 0.0, "pending": 1, "spot": 0, "dug": 0, "seed": 11}
	var found_closed := false
	for i in 8:
		state.finds.worlds["farm"].pending = 1
		state.finds.worlds["farm"].seed = 100 + i
		found_closed = found_closed or state.find_reward("farm").get("items", {}).has("golden_worm")
	check(not found_closed, "sem a missão, nenhum montinho dá a minhoca")
	_fresh(true)
	var dug_at := -1
	for i in 8:
		state.update_finds()
		state.finds.worlds["farm"].pending = 1
		state.finds.worlds["farm"].seed = 7000 + i * 31
		var reward: Dictionary = state.dig("farm")
		if reward.get("items", {}).has("golden_worm"):
			dug_at = i
			break
	check(dug_at >= 0 and dug_at <= 3, "a minhoca vem no máximo no 4º montinho (veio no %d)" % (dug_at + 1))
	check(state.inventory.count("golden_worm") == 1 and state.progress.stat("find_item:golden_worm") == 1, "uma minhoca gorda no inventário")
	var reward_again: Dictionary = state.find_reward("farm")
	check(not reward_again.get("items", {}).has("golden_worm"), "com uma minhoca na mão não sorteia outra")

	# 3. Peixe dourado: 1 mordida por dia e só vale Perfeito.
	_fresh(true)
	state.inventory.add("golden_worm", 3)
	check(state.cast_error("golden_worm", 1) == "", "a vara de bambu aceita a minhoca gorda")
	check(_fish_once(false) == "", "pescaria não Perfeita termina")
	check(state.inventory.count("fish_golden") == 0 and state.inventory.count("golden_worm") == 2, "não Perfeita: peixe some e a minhoca já foi")
	check(state.golden_bitten_today() and state.cast_error("golden_worm", 1) != "", "só uma mordida por dia")
	state.dev_week_goto(2)
	check(state.cast_error("golden_worm", 1) == "", "no dia seguinte morde de novo")
	check(_fish_once(true) == "", "pescaria Perfeita termina")
	check(state.inventory.count("fish_golden") == 1 and state.progress.stat("fish:fish_golden") == 1, "Perfeita: peixe dourado pescado")
	check(db.fishing.fish.fish_golden.difficulty > 85, "puxada mais forte que a do pintado")
	var plain: Array = []
	for id: String in db.fishing.rods.bamboo_rod.baits:
		plain.append(id)
	check("golden_worm" not in plain, "a minhoca gorda não está na lista comum de iscas")

	# 4. Ensopado Dourado: só 3 estrelas no Cozinhar junto.
	_fresh(true)
	state.progress.owned["stove"] = true
	check(state.content_error("recipe", "golden_stew", db.recipes.golden_stew) != "", "receita bloqueada antes do peixe dourado")
	state.progress.stats["fish:fish_golden"] = 1
	check(state.content_error("recipe", "golden_stew", db.recipes.golden_stew) == "", "receita liberada depois do peixe dourado")
	check(_stew_stars(3, false) == "", "fila aceita")
	check(db.entry_output(state.station("stove").queue.back()) == "fish_stew", "pela fila: ensopado comum")
	state.station("stove").queue.clear()
	check(_stew_stars(2, true) == "", "2 estrelas aceitas")
	check(db.entry_output(state.station("stove").queue.back()) == "fish_stew", "2 estrelas: ensopado comum")
	state.station("stove").queue.clear()
	check(_stew_stars(3, true) == "", "3 estrelas aceitas")
	check(db.entry_output(state.station("stove").queue.back()) == "golden_stew", "3 estrelas junto: Ensopado Dourado")

	# 5. Patinha extra: só ao vivo na janela, 1 por dia, teto 2 na fase; tigela não vale.
	_fresh(true)
	state.inventory.add("golden_stew", 6)
	var before: int = state.progress.stat("well_fed_day")
	state.dev_week_goto(2)
	state.dev_week_hour(9)
	check(state.feed("golden_stew"), "fora da janela só mata a fome")
	check(state.progress.stat("well_fed_day") == before and state.secret_bonus_total() == 0, "fora da janela: sem patinha extra")
	state.dev_week_hour(12)
	check(state.feed("golden_stew") and state.secret_bonus_total() == 1, "ao vivo no almoço: uma patinha extra")
	check(state.progress.stat("well_fed_day") == before + 1 and state.progress.stat("secret_paw") == 1, "conta no requisito dos dentinhos")
	state.dev_week_hour(19)
	check(state.feed("golden_stew") and state.secret_bonus_total() == 1, "no mesmo dia não rende outra")
	var stamps: Array = state.paw_stamps()
	check(stamps.any(func(entry: Dictionary) -> bool: return entry.kind == "bonus"), "a cartela tem o carimbo dourado")
	state.dev_week_goto(3)
	state.dev_week_hour(12)
	check(state.feed("golden_stew") and state.secret_bonus_total() == 2, "segundo dia: outra patinha extra")
	state.dev_week_goto(4)
	state.dev_week_hour(12)
	check(state.feed("golden_stew") and state.secret_bonus_total() == 2, "teto de 2 na fase")
	check(state.progress.stat("secret_paw") == 2, "o contador de extras parou em 2")
	# Tigela (Deixar pronto) não vale.
	_fresh(true)
	state.dev_week_goto(2)
	state.dev_week_hour(9)
	state.inventory.add("golden_stew", 1)
	var stored: String = state.store_meal("golden_stew")
	state.dev_week_hour(12)
	state.update_week()
	check(state.secret_bonus_total() == 0, "refeição da tigela não rende a patinha extra (%s)" % stored)

	# 6. Foto secreta ao pescar o peixe dourado pela primeira vez.
	_fresh(true)
	check(not state.album.has_photo("s_golden_fish"), "foto ainda não existe")
	state.inventory.add("golden_worm", 1)
	_fish_once(true)
	check(state.album.has_photo("s_golden_fish"), "foto secreta \"O peixe dourado\"")

	# 7. Formato do save.
	check(int(load("res://autoload/save_manager.gd").get("SAVE_VERSION")) >= 39, "SAVE_VERSION 39")
	var copy := WeekState.new()
	copy.from_dict(state.week.to_dict())
	check(copy.bonus_paws == state.week.bonus_paws, "extras sobrevivem ao save")

	print("SECRET STEW TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)
