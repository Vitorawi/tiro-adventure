extends SceneTree
## Para crescer da primeira semana (plano primeira_semana, E05): Recém-chegado → Filhotinho → Dentinhos com as listas
## do plano (dias bem alimentados, pratos diferentes por tipo, prato-chave com ingrediente, brincadeiras, truques com
## nível e prato inventado), ganchos das etapas futuras, "Crescer!" do dia 2 só no jantar, cerimônia com resumo e
## missão ligada ao prato-chave.
##   godot --headless --path game -s res://tests/growth_week_test.gd
var failures := 0
var state: Node
var db: Node
var events: Node
var rules: Script
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("GROWTH WEEK: " + message)


func row(id: String) -> Dictionary:
	for req: Dictionary in state.call("growth_info").requirements:
		if str(req.id) == id:
			return req
	return {}


func row_ids() -> Array[String]:
	var ids: Array[String] = []
	for req: Dictionary in state.call("growth_info").requirements:
		ids.append(str(req.id))
	return ids


func feed(item: String) -> bool:
	state.get("inventory").call("add", item, 1)
	return bool(state.call("feed", item))


func play_times(count: int) -> void:
	for i in count:
		state.call("dev_set_need", "energy", 100.0)
		state.call("dev_set_need", "happiness", 10.0)
		check(bool(state.call("play")), "brincar %d funciona" % (i + 1))


## Prato do motor com o tipo e os ingredientes dados (item dinâmico).
func dish(type: String, ingredients: Array, stars: int = 1) -> String:
	return str(rules.call("make_id", type, ingredients, stars))


## Primeiro prato (refeição) do dia 9 do tipo, com o ingrediente (ou categoria) pedido.
func combo(type: String, needs: String, exclude: Array = []) -> Array:
	for entry: Dictionary in rules.call("combinations", 9):
		if str(entry.type) != type:
			continue
		var list: Array = entry.ingredients
		var key := "%s:%s" % [type, "+".join(PackedStringArray(list))]
		if key in exclude:
			continue
		if needs == "" or list.has(needs):
			return list
		if needs == "fruta":
			for id: String in list:
				if str(rules.call("ingredient", id).get("category", "")) == "fruta":
					return list
	return []


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	events = root.get_node("Events")
	rules = load("res://scripts/state/dish_rules.gd")
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	var build_info: Script = load("res://scripts/util/build_info.gd")
	if not build_info.call("is_dev"):
		print("GROWTH WEEK: PASS (pulado fora da versão dev)")
		quit(0)
		return
	_lists()
	_first_phase()
	_second_phase()
	_hooks()
	_persistence()
	_quest_link()
	print("GROWTH WEEK: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


# --- As listas do plano -------------------------------------------------------------------------------------------

func _lists() -> void:
	state.call("reset")
	check(row_ids() == ["feed", "bath", "play", "bed"], "Recém-chegado → Filhotinho é a lista curta do Ato 1: %s" % str(row_ids()))
	check(int(row("feed").need) == 1 and int(row("bath").need) == 1 and int(row("play").need) == 1, "comer, banho e brincar valem uma vez")
	var puppy: Dictionary = db.growth.phases[1]
	check(int(puppy.chapter) == 1 and not (puppy.rewards as Dictionary).has("coins"), "Filhotinho é do capítulo 1 e não paga moeda")
	var teething: Dictionary = db.growth.phases[2]
	check(not teething.requirements.filter(func(r: Dictionary) -> bool: return str(r.get("hook", "")) == "name_call").is_empty(), "o nome ficou pronto nos dados do Dentinhos")
	var hooks: Dictionary = db.growth.hooks
	for name: String in ["name_call", "play_rope", "trick_sit", "tricks_three"]:
		check(hooks.has(name) and bool(hooks[name].live), "gancho %s ativado" % name)


func _first_phase() -> void:
	state.call("reset")
	state.call("dev_week_goto", 1)
	state.call("dev_week_hour", 23)
	check(not bool(state.call("growth_info").ready), "começa sem estar pronto")
	# Ato 1: comida, banho, brincar e caminha, sem esperar dia nem jantar.
	check(feed("puppy_mash"), "papinha da caixinha")
	check(row("feed").done and not row("bath").done and not bool(state.call("growth_info").ready), "comer feito, o resto pendente")
	check(bool(state.call("bathe")), "banho")
	check(row("bath").done, "banho feito")
	play_times(1)
	check(row("play").done, "brincar feito")
	check(not row("bed").done and not bool(state.call("growth_info").ready), "falta a caminha")
	state.call("dev_grant_upgrade", "dog_bed")
	check(row("bed").done, "item-chave: caminha")
	check(bool(state.call("growth_info").ready), "Crescer! acende no primeiro dia")
	var coins: int = state.get("coins")
	check(str(state.call("grow")) == "", "cresce para Filhotinho")
	var growth: Variant = state.get("growth")
	check(growth.phase == "puppy" and growth.phase_dishes.is_empty(), "fase nova começa sem os pratos da anterior")
	check(state.get("coins") == coins, "o presente do Filhotinho não traz moedas")
	check(int(state.get("inventory").call("count", "dog_food")) >= 3, "o presente do Filhotinho traz a ração")
	var summary: Dictionary = growth.ceremonies.puppy.get("summary", {})
	check(int(summary.get("days", 0)) == 1 and int(summary.get("dishes", 0)) == 1 and int(summary.get("plays", 0)) == 1, "resumo congelado: %s" % str(summary))


func _second_phase() -> void:
	check(row_ids() == ["key", "days", "dishes", "star_dish", "invented", "key_egg", "key_fruit", "key_fish", "play", "name", "rope", "tricks", "sit_good"], "Filhotinho → Dentinhos: %s" % str(row_ids()))
	check(int(row("days").need) == 6 and int(row("dishes").need) == 8 and int(row("play").need) == 8, "números 6 dias, 8 pratos, 8 brincadeiras")
	check(int(row("days").have) == 1, "a patinha do dia da chegada já conta (dias com contagem total)")
	check(int(row("dishes").types_need) == 3, "pede 3 tipos de prato")
	# Os lanches também são pratos, o Gororoba não, e o progresso avisa.
	check(feed("carrot_snack") and feed("apple_biscuit"), "lanches também são pratos")
	check(not feed("gororoba") or int(row("dishes").have) == 2, "Gororoba não é prato")
	check(toasts.any(func(text: String) -> bool: return text.begins_with("Pratos diferentes: ")), "avisa o progresso dos pratos")
	# 2 estrelas e prato inventado (vieram do Filhotinho antigo para o Dentinhos).
	check(not row("star_dish").done and not row("invented").done, "ainda sem estrelas nem inventado")
	state.call("_note_recipe", "puppy_mash", 2)
	check(row("star_dish").done, "prato de 2 estrelas")
	state.call("_note_dish", "papinha", ["cenoura", "batata"], 1)
	check(row("invented").done, "prato inventado")
	# Pratos de 2 tipos não bastam, por mais que sejam 8.
	var seen: Array = []
	var served := 0
	var per_type := {"papinha": 0, "sopinha": 0}
	for entry: Dictionary in rules.call("combinations", 9):
		if str(entry.type) not in ["papinha", "sopinha"] or served >= 8 or int(per_type[str(entry.type)]) >= 4:
			continue
		per_type[str(entry.type)] = int(per_type[str(entry.type)]) + 1
		var list: Array = entry.ingredients
		if list.has("ovo") or list.has("peixe") or list.has("maca") or list.has("banana") or list.has("melancia"):
			continue
		check(feed(dish(str(entry.type), list)), "prato do motor é comida")
		served += 1
		seen.append(list)
	check(int(row("dishes").dishes_have if row("dishes").has("dishes_have") else row("dishes").have) >= 8, "oito pratos diferentes")
	check(int(row("dishes").types_have) == 2 and not row("dishes").done, "só papinha e sopinha: falta o mingau")
	check(int(row("dishes").have) == 7, "mostra 7/8 enquanto falta o tipo")
	var mingau := combo("mingau", "aveia")
	check(not mingau.is_empty(), "existe um mingau")
	check(feed(dish("mingau", mingau)), "mingau")
	check(int(row("dishes").types_have) == 3 and row("dishes").done, "com o mingau, 3 tipos e 9 pratos")
	# Pratos-chave.
	check(not row("key_egg").done and not row("key_fish").done, "ovo e peixe pendentes")
	var egg := combo("papinha", "ovo")
	check(not egg.is_empty() and feed(dish("papinha", egg)), "papinha com ovo")
	check(row("key_egg").done and not row("key_fish").done, "prato com ovo marca o ovo")
	var fruit := combo("mingau", "fruta")
	check(not fruit.is_empty() and feed(dish("mingau", fruit)), "mingau com fruta")
	check(row("key_fruit").done, "prato com fruta marca a fruta")
	# Lanche não vale como prato-chave.
	var fish_snack := combo("petisco", "peixe")
	if not fish_snack.is_empty():
		check(feed(dish("petisco", fish_snack)) and not row("key_fish").done, "lanche com peixe não é prato-chave")
	check(feed("fish_mash") and row("key_fish").done, "papinha de peixe fixa marca o peixe")
	# Dias e brincadeiras.
	check(not row("days").done and not bool(state.call("growth_info").ready), "faltam dias bem alimentados")
	for day in range(2, 7):
		state.call("dev_week_goto", day)
		state.call("dev_week_meal", "lunch")
		state.call("dev_week_meal", "dinner")
	check(row("days").done and int(row("days").have) == 6, "seis dias bem alimentados, contando o da chegada")
	play_times(8)
	state.get("progress").stats["play_rope"] = 1 # O gesto real é coberto em play_week_test.
	state.get("progress").stats["name_call"] = 1 # O botão real é coberto em play_week_test.
	check(row("play").done and row("name").done, "8 brincadeiras e o nome")
	state.get("progress").stats["trick:sit"] = 8
	state.get("progress").stats["trick_learned"] = 3
	check(not bool(state.call("growth_info").ready), "falta o mordedor")
	state.get("inventory").call("add", "chew_ring", 1)
	check(str(state.call("deliver_growth", "chew_ring")) == "", "entrega o mordedor")
	check(bool(state.call("growth_info").ready), "tudo pronto para Dentinhos: %s" % str(state.call("grow_error")))
	check(str(state.call("grow")) == "" and state.get("growth").phase == "teething", "cresce para Dentinhos")
	var summary: Dictionary = state.get("growth").ceremonies.teething.get("summary", {})
	check(int(summary.get("days", 0)) == 6 and int(summary.get("dishes", 0)) >= 9 and int(summary.get("plays", 0)) == 8, "resumo de Filhotinho: %s" % str(summary))


func _hooks() -> void:
	# O nome e o Senta moram na lista do Dentinhos: testa em Filhotinho com um save novo.
	state.call("reset")
	state.get("growth").phase = "puppy"
	var hooks: Dictionary = db.growth.hooks
	hooks.name_call.live = true
	check(row_ids().has("name") and row_ids().has("sit_good"), "gancho ligado mostra o requisito")
	check(not row("name").done and not row("sit_good").done, "nome e Senta pendentes")
	state.get("progress").stats["name_call"] = 1
	check(row("name").done, "atender pelo nome conta pelo contador")
	check(int(state.call("trick_level", "sit")) == 0, "Senta sem acertos: nível 0")
	state.get("progress").stats["trick:sit"] = 3
	check(int(state.call("trick_level", "sit")) == 1 and not row("sit_good").done, "3 acertos: Aprendeu, ainda não Sabe bem")
	state.get("progress").stats["trick:sit"] = 8
	check(int(state.call("trick_level", "sit")) == 2 and row("sit_good").done, "8 acertos: Sabe bem")
	state.get("progress").stats["trick:sit"] = 15
	check(int(state.call("trick_level", "sit")) == 3, "15 acertos: Craque")
	hooks.name_call.live = false
	check(not row_ids().has("name") and row_ids().has("sit_good"), "só o gancho desligado volta a se esconder")
	hooks.name_call.live = true


func _persistence() -> void:
	state.call("reset")
	state.get("growth").phase = "puppy"  # a contagem de pratos é a do Dentinhos
	check(feed("puppy_mash"), "prato antes de salvar")
	var before: Dictionary = state.get("growth").phase_dishes.duplicate(true)
	state.call("from_dict", state.call("to_dict"))
	check(state.get("growth").phase_dishes == before and not before.is_empty(), "pratos comidos sobrevivem à recarga")
	check(int(row("dishes").have) == 1, "a contagem continua")
	check(int(load("res://autoload/save_manager.gd").get("SAVE_VERSION")) >= 24, "formato do save subiu")


func _quest_link() -> void:
	state.call("reset")
	var progress: Variant = state.get("progress")
	var fish := combo("papinha", "peixe")
	check(not fish.is_empty(), "existe papinha com peixe")
	state.get("inventory").call("add", dish("papinha", fish), 1)
	var before_feed: int = progress.stat("feed:fish_mash")
	check(bool(state.call("feed", dish("papinha", fish))), "papinha com peixe do motor")
	check(progress.stat("feed:fish_mash") == before_feed + 1, "prato com peixe também marca a missão da papinha de peixe")
	state.call("_link_key_quests", state.call("dish_of_item", dish("papinha", fish)), dish("papinha", fish), "produce")
	check(progress.stat("produce:fish_mash") >= 1, "recolher prato com peixe marca o fazer da missão")
	check(state.call("dish_of_item", "dog_food").is_empty() and state.call("dish_of_item", "gororoba").is_empty(), "ração e Gororoba não são pratos")
