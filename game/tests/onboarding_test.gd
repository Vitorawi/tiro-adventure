extends SceneTree
## "Nunca só esperar": um jogador simulado joga o começo (do zero até o capítulo 4) e o teste mede
## quando acontecem as primeiras vezes e quanto tempo ele ficou sem nada útil para fazer.
## As próximas etapas do plano (docs/plans/comeco) ampliam este teste. Constantes fáceis de mudar:

const MAX_FIRST_HARVEST_MIN := 4.0
const MAX_FIRST_WISH_MIN := 7.0
const MAX_FIRST_FIND_MIN := 9.0
const MAX_IDLE_TOTAL_SEC := 240.0  # ocioso total até o fim do capítulo 3
const MAX_IDLE_STREAK_SEC := 120.0  # nenhum trecho ocioso contínuo maior que isto
const GOAL_CHAPTER := 4
const MAX_FIRST_WALK_MIN := 60.0  # primeiro passeio recolhido (Etapa 06)
const MAX_FIRST_RARE_MIN := 60.0  # garantia de até 6 voltas, com descanso real
const MAX_SIM_MIN := 60.0
const ACTION_SEC := 3.0  # custo de tempo de cada ação do jogador simulado
const IDLE_STEP_SEC := 10.0

var failures: int = 0
var state: Node
var database: Node
var sim: float = 0.0  # segundos simulados
var idle_total: float = 0.0
var idle_streak: float = 0.0
var idle_max: float = 0.0
var firsts: Dictionary = {}
var idle_steps: Dictionary = {}
var goal_sim := -1.0  # instante em que o capítulo alvo começou
var goal_idle_total := 0.0
var goal_idle_max := 0.0


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Onboarding: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	state.call("reset")
	# Mede o pior caso da garantia (sem sorte), preservando custos, timers e descanso reais.
	var rare: Dictionary = database.get("walks").walks.park_loop.loot.rare
	var rare_chance := float(rare.chance)
	rare.chance = 0.0
	var progress: RefCounted = state.get("progress")
	while (progress.chapter_index() < GOAL_CHAPTER or progress.stat("walk_rare") == 0) and sim < MAX_SIM_MIN * 60.0:
		var acts := _turn()
		_record_firsts()
		if goal_sim < 0.0 and progress.chapter_index() >= GOAL_CHAPTER:
			goal_sim = sim
			goal_idle_total = idle_total
			goal_idle_max = idle_max
		if acts == 0:
			var active: String = str(progress.active_steps())
			idle_steps[active] = float(idle_steps.get(active, 0)) + IDLE_STEP_SEC
			state.call("dev_advance_time", IDLE_STEP_SEC)
			sim += IDLE_STEP_SEC
			idle_total += IDLE_STEP_SEC
			idle_streak += IDLE_STEP_SEC
			idle_max = maxf(idle_max, idle_streak)
		else:
			state.call("dev_advance_time", ACTION_SEC * acts)
			sim += ACTION_SEC * acts
			idle_streak = 0.0
	progress = state.get("progress")
	print("Linha do tempo (min simulados):")
	for key: String in ["talk:lais", "feed", "open:bag", "talk:bloblo", "wish", "water", "harvest", "find", "produce", "open:village", "walk"]:
		print("  ", key, ": ", ("%.1f" % (float(firsts[key]) / 60.0)) if firsts.has(key) else "nunca")
	print("  capítulo %d em %.1f min; ocioso total %.0f s; maior trecho ocioso %.0f s" % [GOAL_CHAPTER, goal_sim / 60.0, goal_idle_total, goal_idle_max])
	print("  primeiro passeio recolhido em %.1f min" % (float(firsts.get("walk", -60.0)) / 60.0))
	print("  primeiro raro em %.1f min; %d passeios" % [float(firsts.get("walk_rare", -60.0)) / 60.0, progress.stat("walk")])
	print("  espera por passos: ", idle_steps)
	check(progress.chapter_index() >= GOAL_CHAPTER, "chegou ao capítulo %d em %.0f min simulados" % [GOAL_CHAPTER, MAX_SIM_MIN])
	check(firsts.has("harvest") and float(firsts.harvest) / 60.0 <= MAX_FIRST_HARVEST_MIN, "primeira colheita em até %.0f min" % MAX_FIRST_HARVEST_MIN)
	check(firsts.has("wish") and float(firsts.wish) / 60.0 <= MAX_FIRST_WISH_MIN, "primeiro desejo do Tiro cumprido em até %.0f min" % MAX_FIRST_WISH_MIN)
	check(firsts.has("find") and float(firsts.find) / 60.0 <= MAX_FIRST_FIND_MIN, "primeiro achado em até %.0f min" % MAX_FIRST_FIND_MIN)
	check(firsts.has("water"), "o jogador regou ao menos uma vez")
	check(goal_sim >= 0.0, "chegou ao capítulo %d" % GOAL_CHAPTER)
	check(firsts.has("walk") and float(firsts.walk) / 60.0 <= MAX_FIRST_WALK_MIN, "primeiro passeio recolhido em até %.0f min" % MAX_FIRST_WALK_MIN)
	check(firsts.has("walk_rare") and float(firsts.walk_rare) / 60.0 <= MAX_FIRST_RARE_MIN, "primeiro raro em até %.0f min" % MAX_FIRST_RARE_MIN)
	check(goal_idle_total <= MAX_IDLE_TOTAL_SEC, "ocioso total %.0f s (máximo %.0f s)" % [goal_idle_total, MAX_IDLE_TOTAL_SEC])
	check(goal_idle_max <= MAX_IDLE_STREAK_SEC, "maior trecho ocioso %.0f s (máximo %.0f s)" % [goal_idle_max, MAX_IDLE_STREAK_SEC])
	print("ONBOARDING TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	rare.chance = rare_chance
	quit(1 if failures > 0 else 0)


func _record_firsts() -> void:
	var progress: RefCounted = state.get("progress")
	if not firsts.has("walk_rare") and progress.stat("walk_rare") > 0:
		firsts["walk_rare"] = sim
	for key: String in ["talk:lais", "feed", "open:bag", "talk:bloblo", "wish", "water", "harvest", "find", "produce", "open:village", "walk"]:
		if not firsts.has(key) and progress.stat(key) > 0:
			firsts[key] = sim


## Uma rodada do jogador simulado. Devolve quantas ações úteis fez (0 = ficou parado).
func _turn() -> int:
	var progress: RefCounted = state.get("progress")
	var acts := 0
	var wanted: Array[String] = []
	var owned_goals: Array[String] = []
	for step: String in progress.active_steps().values():
		for goal: Dictionary in database.get("quests")[step].goals:
			wanted.append(str(goal.get("key", "")))
			if goal.type == "owned":
				owned_goals.append(str(goal.key))
	# Comidas pedidas pelo Tiro também são objetivos úteis, com a cadeia de ingredientes.
	for i in 3:
		var wish: Dictionary = state.call("wish_at", i)
		if wish.get("type", "") == "feed":
			var item_id: String = wish.item
			wanted.append(item_id)
			if database.get("crops").has(item_id) and state.get("inventory").count(item_id) == 0:
				wanted.append("harvest:" + item_id)
			for recipe: Dictionary in database.get("recipes").values():
				if recipe.get("output", recipe.get("output_collection", "")) == item_id:
					for input: String in recipe.inputs:
						if database.get("crops").has(input) and state.get("inventory").count(input) < int(recipe.inputs[input]):
							wanted.append("harvest:" + input)
	# Crescer (etapa 11): comidas e itens-chave que a fase pede entram na lista do que fazer.
	for row: Dictionary in state.call("growth_info").requirements:
		if not row.done and str(row.type) in ["feed", "deliver"] and str(row.item) != "any":
			wanted.append(str(state.call("favorite_food")) if str(row.item) == "favorite" else str(row.item))
	# 1. Recebe o que está pronto (missões e diárias).
	for step: String in progress.active_steps().values():
		if state.call("claim_quest", step) == "":
			acts += 1
	for kind: String in ["daily", "weekly"]:
		for id: String in state.call("routine_ids", kind):
			if state.call("claim_routine", kind, id) == "":
				acts += 1
	acts += _grow_turn()
	# 2. Conversas e telas pedidas pela história.
	for npc_id: String in database.get("npcs"):
		if progress.npc_visible(npc_id) and ("talk:" + npc_id) in wanted and progress.stat("talk:" + npc_id) == 0:
			state.call("talk_to", npc_id)
			acts += 1
	for key: String in wanted:
		if key.begins_with("open:") and progress.stat(key) == 0:
			state.call("note_screen_opened", key.trim_prefix("open:"))
			acts += 1
	# 3. Cuidar do Tiro (quando a história pede ou ele precisa).
	if "feed" in wanted or state.call("_need_is_low", "hunger"):
		if state.get("inventory").count("dog_food") == 0:
			state.call("emergency_food")
		if state.call("feed", "dog_food"):
			acts += 1
	if "bathe" in wanted and progress.stat("bathe") == 0:
		state.call("bathe")
		acts += 1
	if "play" in wanted and progress.stat("play") == 0 and state.call("play"):
		acts += 1
	# 4. Horta: colher, regar, plantar (batata quando a vovó pede).
	for i in int(state.call("accessible_plots")):
		if state.call("plot_status", i) == "ready" and not (state.call("harvest", i) as Dictionary).is_empty():
			acts += 1
		if state.call("water", i) == "":
			acts += 1
		if state.call("plot_status", i) == "empty":
			# Um canteiro por cultura pedida; os outros mantêm colheitas rápidas.
			var planted := false
			for goal: String in wanted:
				if not goal.begins_with("harvest:"):
					continue
				var crop_id := goal.trim_prefix("harvest:")
				var busy := false
				for j in state.get("plots").size():
					busy = busy or (state.call("plot_status", j) != "empty" and state.call("plot", j).crop == crop_id)
				if not busy and state.call("plant", i, crop_id) == "":
					planted = true
					break
			if planted or state.call("plant", i, "carrot") == "":
				acts += 1
	# 4b. Desejos do Tiro: faz o que ele pede (carinho, brincar, banho, comida) e recebe.
	for i in 3:
		var wish: Dictionary = state.call("wish_at", i)
		if wish.is_empty():
			continue
		if str(wish.type) == "action" and state.call("wish_error", i) != "":
			# Ao buscar o raro, deixa os pedidos de brincar para depois de descansar.
			if wish.goal.key == "play" and progress.claimed_quests.has("nina_meet") and (state.get("dog").sleeping or state.get("dog").get_need("energy", state.call("now")) < 25.0):
				continue
			for n in int(wish.goal.target):
				match str(wish.goal.key):
					"pet": state.call("pet")
					"play": state.call("play")
					"bathe": state.call("bathe")
					"feed":
						if state.get("inventory").count("dog_food") == 0:
							state.call("emergency_food")
						state.call("feed", "dog_food")
			acts += 1
		if state.call("fulfill_wish", i) == "":
			acts += 1
	# 4c. Faro: cava o montinho que o Tiro farejou.
	for find_world: String in state.get("finds").worlds:
		if state.call("dig_error", find_world) == "" and not (state.call("dig", find_world) as Dictionary).is_empty():
			acts += 1
	# 5. Construir o que a história pede, se der.
	for id: String in owned_goals:
		if not state.call("has_upgrade", id) and state.call("buy_upgrade", id) == "":
			acts += 1
	# 6. Cozinhar o que a história pede e recolher.
	for id: String in database.get("recipes"):
		var recipe: Dictionary = database.get("recipes")[id]
		if ("deliver:" + id) == "" or not (id in wanted or str(recipe.get("output", recipe.get("output_collection", ""))) in wanted):
			continue
		if state.get("inventory").count(str(recipe.get("output", recipe.get("output_collection", "")))) >= 1:
			continue
		if state.call("cook", id) == "":
			acts += 1
	for station_id: String in state.get("stations"):
		if not (state.call("collect", station_id) as Dictionary).is_empty():
			acts += 1
	# 6b. Vende o excedente (cenoura guarda 4 para a encomenda) quando a Vila pede vendas.
	if "trade" in wanted or "sold" in wanted:
		for item: String in state.get("inventory").counts.keys():
			var spare: int = int(state.get("inventory").counts[item]) - (4 if item == "carrot" else 0)
			if database.get("crops").has(item) and spare > 0 and state.call("sell", item, spare) == "":
				acts += 1
	# 7. Encomenda da feira (fecha o capítulo 4 e abre a Praça) e o primeiro passeio.
	if "orders" in wanted:
		for id: String in database.get("progression").orders:
			if state.call("fulfill_order", id) == "":
				acts += 1
				break
	if state.call("walk_ready"):
		if not (state.call("collect_walk") as Dictionary).is_empty():
			acts += 1
	elif state.call("walk_error", "park_loop") == "Tiro está cansado: deixe ele dormir":
		state.call("set_sleeping", true)
		acts += 1
	elif state.get("dog").sleeping and state.get("dog").get_need("energy", state.call("now")) >= 20.0:
		state.call("set_sleeping", false)
		acts += 1
	elif state.call("start_walk", "park_loop") == "":
		acts += 1
	return acts


## O jogador simulado cuida do Tiro até ele crescer (etapa 11): dá a refeição da fase, entrega o item-chave e
## aperta Crescer. Os pontos dos pilares usam `dev_add_pillar`: o ritmo deles é medido em pillars_test e na
## calibração (etapa 17); aqui interessa o começo (primeiras vezes e ocioso), não os dias de cuidado.
func _grow_turn() -> int:
	var progress: RefCounted = state.get("progress")
	var main: String = progress.current_main_quest()
	if main == "" or str(database.get("quests")[main].goals[0].type) != "growth":
		return 0
	var acts := 0
	for row: Dictionary in state.call("growth_info").requirements:
		if row.done:
			continue
		match str(row.type):
			"feed":
				var food := str(state.call("favorite_food")) if str(row.item) == "favorite" else (str(row.item) if str(row.item) != "any" else "dog_food")
				for _i in int(row.need) - int(row.have):
					if food == "dog_food" and state.get("inventory").count(food) == 0:
						state.call("emergency_food")
					if state.call("feed", food):
						acts += 1
			"deliver":
				if state.call("deliver_growth", str(row.item)) == "":
					acts += 1
			"pillars":
				for id: String in row.levels:
					var missing: int = int(database.get("growth").levels[int(row.levels[id]) - 1]) - int(state.get("growth").points.get(id, 0))
					if missing > 0:
						state.call("dev_add_pillar", id, missing)
	if state.call("grow_error") == "" and state.call("grow") == "":
		acts += 1
	return acts
