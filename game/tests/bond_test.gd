extends SceneTree
## Etapa 16: cuidado útil (carinho/brincar/alimentar/banhar), desejos sem farm, rotinas R1 e linha da Nina.

var failures: int = 0
var state: Node
var database: Node


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Vínculo: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _progress() -> RefCounted:
	return state.get("progress")


func _stat(key: String) -> int:
	return _progress().stat(key)


## Põe a necessidade num valor exato agora (o relógio é o real; a queda em milissegundos não conta).
func _set_need(id: String, value: float) -> void:
	var dog: RefCounted = state.get("dog")
	dog.commit(state.call("now"))
	dog.needs[id] = value


func _clear_care_cooldowns() -> void:
	for key: String in ["affection:pet", "affection:play", "useful:pet"]:
		_progress().cooldowns.erase(key)


## Tutoriais do capítulo 1 já cumpridos: nenhuma exceção de história sobra.
func _fresh_after_tutorials() -> void:
	state.call("reset")
	for id: String in ["lais_feed", "lais_bath", "lais_play"]:
		state.call("dev_complete_quest", id)
	state.get("inventory").add("dog_food", 20)


func _reload() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	_pet_check()
	_play_check()
	_feed_bathe_check()
	_wish_check()
	_tutorial_check()
	_wish_economy_check()
	_routines_check()
	_nina_check()
	print("BOND TEST: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)


## Carinho: 100 chamadas diretas = +1 afeto; recarrega com o tempo e sobrevive ao reload.
func _pet_check() -> void:
	_fresh_after_tutorials()
	_set_need("happiness", 50.0)
	var affection: int = state.get("dog").affection
	var gained := 0
	for n in 100:
		gained += int(state.call("pet"))
	check(gained == 1 and state.get("dog").affection == affection + 1, "100 carinhos diretos = +1 afeto (%d)" % gained)
	check(_stat("pet") == 100, "contador bruto de carinho segue contando (%d)" % _stat("pet"))
	check(_stat("care_useful:pet") == 1 and _stat("care_useful") == 1, "carinho útil conta uma vez na guarda (%d)" % _stat("care_useful:pet"))
	# Reload antes da recarga: continua travado (o controle mora no estado).
	_reload()
	check(int(state.call("pet")) == 0 and state.get("dog").affection == affection + 1, "reload antes dos 120 s não libera afeto")
	# Depois da recarga (relógio andou 121 s): +1 de novo, também após o reload.
	for key: String in ["affection:pet", "useful:pet"]:
		_progress().cooldowns[key] = float(_progress().cooldowns[key]) - 121.0
	_reload()
	_set_need("happiness", 40.0)
	check(int(state.call("pet")) == 1 and state.get("dog").affection == affection + 2, "reload depois dos 120 s libera +1")
	check(_stat("care_useful:pet") == 2, "segundo carinho útil depois da guarda")
	# Felicidade cheia: reage, afeto só pela recarga, nunca útil (ganho 0 < 3).
	_clear_care_cooldowns()
	_set_need("happiness", 100.0)
	var useful := _stat("care_useful")
	state.call("pet")
	check(_stat("care_useful") == useful, "carinho sem benefício não conta como útil")
	# Limiar efetivo 3: ganho de exatamente 3 conta.
	_clear_care_cooldowns()
	_set_need("happiness", 97.0)
	state.call("pet")
	check(_stat("care_useful") == useful + 1, "ganho efetivo 3 conta como útil")
	_clear_care_cooldowns()
	_set_need("happiness", 98.0)
	state.call("pet")
	check(_stat("care_useful") == useful + 1, "ganho 2 não conta")


func _play_check() -> void:
	_fresh_after_tutorials()
	_set_need("energy", 100.0)
	_set_need("happiness", 100.0)
	var affection: int = state.get("dog").affection
	state.call("play")
	check(state.get("dog").affection == affection and _stat("care_useful:play") == 0, "brincar com felicidade cheia: sem afeto e sem útil")
	_set_need("happiness", 50.0)
	state.call("play")
	check(state.get("dog").affection == affection + 2 and _stat("care_useful:play") == 1, "brincar útil: +2 de afeto")
	_set_need("happiness", 50.0)
	state.call("play")
	check(state.get("dog").affection == affection + 2, "brincar de novo dentro dos 120 s não paga afeto")
	check(_stat("play") == 3, "contador bruto de brincar continua")
	_progress().cooldowns["affection:play"] = float(_progress().cooldowns["affection:play"]) - 121.0
	_set_need("happiness", 50.0)
	state.call("play")
	check(state.get("dog").affection == affection + 4, "depois da recarga paga de novo")


func _feed_bathe_check() -> void:
	_fresh_after_tutorials()
	_set_need("hunger", 100.0)
	state.call("feed", "dog_food")
	check(_stat("care_useful:feed") == 0 and _stat("feed") == 1, "fome cheia: alimentar não é útil, mas conta o bruto")
	_set_need("hunger", 40.0)
	state.call("feed", "dog_food")
	check(_stat("care_useful:feed") == 1, "fome baixa: alimentar é útil")
	_set_need("hygiene", 100.0)
	state.call("bathe")
	check(_stat("care_useful:bathe") == 0, "banho sem sujeira não é útil")
	_set_need("hygiene", 30.0)
	state.call("bathe")
	check(_stat("care_useful:bathe") == 1 and _stat("care_useful") == 2, "banho com sujeira é útil; total soma as ações")


## Desejo de ação: exceção uma vez por instância; satisfeito e esperando Receber não rende mais.
func _wish_check() -> void:
	state.call("reset")
	for id: String in ["lais_feed", "lais_bath", "lais_play"]:
		state.call("dev_complete_quest", id)
	state.call("dev_complete_quest", "lais_bed")
	var slots: Array = state.get("wishes").slots
	check(str(slots[0].id) == "pet", "primeiro desejo = carinho")
	_set_need("happiness", 100.0)
	state.call("pet")
	check(_stat("care_useful:pet") == 1 and bool(slots[0].used), "desejo pedindo carinho vale uma vez mesmo sem benefício")
	_clear_care_cooldowns()
	state.call("pet")
	_clear_care_cooldowns()
	state.call("pet")
	check(state.call("wish_error", 0) == "", "3 carinhos cumprem o desejo (Receber pendente)")
	var useful := _stat("care_useful")
	for n in 5:
		_clear_care_cooldowns()
		state.call("pet")
	check(_stat("care_useful") == useful, "desejo já satisfeito, prêmio pendente: nada de farm (%d)" % (_stat("care_useful") - useful))
	var coins: int = state.get("coins")
	check(state.call("fulfill_wish", 0) == "" and state.get("coins") == coins + 2, "receber paga 2 moedas")
	# Desejo de comida: a entrega conta como cuidado pedido, uma vez.
	state.get("wishes").slots[0] = WishState_empty()
	state.get("wishes").slots[0]["id"] = "carrot"
	state.get("inventory").add("carrot", 1)
	_set_need("hunger", 100.0)
	var feed_useful := _stat("care_useful:feed")
	_progress().claimed_bond_level = 99  # o presente de vínculo não entra na conta de moedas
	coins = state.get("coins")
	check(state.call("fulfill_wish", 0) == "", "entrega o desejo de cenoura")
	check(_stat("care_useful:feed") == feed_useful + 1 and _stat("wish_item:carrot") == 1, "entrega conta cuidado e wish_item:carrot (%d, %d)" % [_stat("care_useful:feed") - feed_useful, _stat("wish_item:carrot")])
	check(state.get("coins") == coins + 2, "cenoura paga 2 moedas (fórmula 50% do preço, mínimo 2)")
	state.get("inventory").add("carrot", 1)
	state.call("feed", "carrot")
	check(_stat("wish_item:carrot") == 1, "feed direto não vira wish_item")


func WishState_empty() -> Dictionary:
	return load("res://scripts/state/wish_state.gd").call("empty_slot", 0.0)


## Tutorial: o gesto pedido pela história vale como útil uma vez; repetir não.
func _tutorial_check() -> void:
	state.call("reset")
	state.call("dev_complete_quest", "lais_feed")
	state.call("dev_complete_quest", "lais_bath")
	check(_progress().active_steps().values().has("lais_play"), "passo ativo é brincar")
	_set_need("energy", 100.0)
	_set_need("happiness", 100.0)
	state.call("play")
	check(_stat("care_useful:play") == 1 and state.get("dog").affection >= 2, "tutorial de brincar vale uma vez")
	_progress().cooldowns.erase("affection:play")
	_set_need("happiness", 100.0)
	state.call("play")
	check(_stat("care_useful:play") == 1, "repetir depois do tutorial não conta")


func _wish_economy_check() -> void:
	state.call("reset")
	# Elegibilidade real: picolé exige liquidificador E receita acessível; sem a estação não sorteia.
	var def: Dictionary = state.call("wish_def", "strawberry_pop")
	check(not bool(state.call("wish_item_reachable", def)), "picolé sem fonte liberada não é alcançável")
	state.get("inventory").add("strawberry_pop", 1)
	check(bool(state.call("wish_item_reachable", def)), "item já na mochila sempre é alcançável")
	state.get("inventory").remove("strawberry_pop")
	# Fórmula de moedas.
	var wishes: Dictionary = database.get("wishes").wishes
	for id: String in wishes:
		var w: Dictionary = wishes[id]
		var coins := int(w.rewards.coins)
		if str(w.type) == "action":
			check(coins == 2, "%s: ação paga 2 moedas (%d)" % [id, coins])
		else:
			var price := float(database.get("items")[str(w.item)].get("sell_price", 0))
			check(coins == clampi(roundi(price * 0.5), 2, 8), "%s: %d moedas pela fórmula" % [id, coins])
	# Especial: dobra, teto de 12.
	state.call("dev_complete_quest", "lais_bed")
	state.get("wishes").slots[0]["id"] = "sweet_potato_chips"
	state.get("wishes").slots[0]["special"] = true
	check(int(state.call("wish_rewards", 0).coins) == 12, "especial limitado a 12 moedas")
	# Troca de pedido impossível: na hora, com o motivo guardado, sem item grátis.
	state.get("wishes").slots[0]["id"] = "strawberry_pop"
	state.get("wishes").slots[0]["special"] = false
	var items_before: int = state.get("inventory").count("strawberry_pop")
	check(state.call("swap_wish", 0) == "", "troca do pedido impossível")
	check(int(state.call("wish_wait", 0)) == 0 and str(state.get("wishes").slots[0].swap_reason) == "unreachable", "troca imediata + motivo guardado")
	check(state.get("inventory").count("strawberry_pop") == items_before, "nenhum item gerado")
	# Níveis de vínculo 2–8.
	var levels: Array = database.get("progression").bond_levels
	var expected := [10, 15, 20, 25, 30, 40, 50]
	for i in expected.size():
		check(int(levels[i + 1].rewards.coins) == expected[i], "vínculo %d paga %d" % [i + 2, expected[i]])
	check(int(levels[2].rewards.items.carrot_snack) == 2 and int(levels[4].rewards.items.bolt) == 1, "itens dos níveis preservados")


func _routines_check() -> void:
	var routines: Dictionary = database.get("routines")
	var expected_daily := ["care", "harvest", "cook", "order", "tiro_walk"]
	var expected_weekly := ["care_week", "big_harvest", "chef_week", "orders_week"]
	check(routines.daily.missions.keys() == expected_daily, "nove modelos: cinco diários")
	check(routines.weekly.missions.keys() == expected_weekly, "nove modelos: quatro semanais")
	var table := {
		"care": [[1, 2, 2], 5, 4], "harvest": [[2, 4, 4], 6, 5], "cook": [[1, 2, 3], 8, 6], "order": [[1, 1, 2], 8, 6], "tiro_walk": [[1, 1, 1], 5, 5],
	}
	for id: String in table:
		var m: Dictionary = routines.daily.missions[id]
		var t: Dictionary = m.goal.targets
		check([int(t.start), int(t.middle), int(t.community)] == table[id][0] and int(m.rewards.coins) == table[id][1] and int(m.player_xp) == table[id][2], "diária %s confere com a tabela" % id)
	var weekly := {"care_week": [[5, 8, 10], 20, 15], "big_harvest": [[10, 16, 20], 25, 20], "chef_week": [[6, 10, 14], 30, 20], "orders_week": [[3, 5, 6], 30, 20]}
	for id: String in weekly:
		var m: Dictionary = routines.weekly.missions[id]
		var t: Dictionary = m.goal.targets
		check([int(t.start), int(t.middle), int(t.community)] == weekly[id][0] and int(m.rewards.coins) == weekly[id][1] and int(m.player_xp) == weekly[id][2], "semanal %s confere com a tabela" % id)
	check(int(routines.weekly.missions.orders_week.rewards.items.bolt) == 1, "semanal de encomendas dá 1 parafuso")
	# Rotina antiga ativa mantém meta e prêmio.
	state.call("reset")
	state.call("dev_jump_to_chapter", 4)
	var progress := _progress()
	var period: String = state.call("routine_period", "daily")
	progress.routines["daily"] = {"period": period, "ids": ["play", "harvest"], "base": {"play": 0, "harvest": 0}, "claimed": {}}
	check(int(state.call("routine_target", "daily", "harvest")) == 3 and int(state.call("routine_data", "daily", "harvest").rewards.coins) == 15, "rotina antiga ativa mantém meta 3 e prêmio 15")
	check(state.call("routine_ids", "daily") == ["play", "harvest"], "sorteio ativo não é trocado no meio do período")
	# Novo sorteio: só acessíveis, snapshot de meta por fase, contagem por lote.
	state.call("dev_restart_routines")
	var ids: Array = state.call("routine_ids", "daily")
	check(int(progress.routines.daily.catalog) == 2 and ids.size() == 3, "novo sorteio no catálogo R1 (%s)" % str(ids))
	for id: String in ids:
		check(routines.daily.missions.has(id) and state.call("requirement_error", routines.daily.missions[id].get("requirements", {})) == "", "%s é acessível" % id)
		check(int(progress.routines.daily.targets[id]) == int(routines.daily.missions[id].goal.targets.middle), "%s: meta da fase do meio congelada" % id)
	check(not "tiro_walk" in ids and not "cook" in ids, "sem passeio/produção antes de liberar")
	state.call("dev_jump_to_chapter", 10)
	check(state.call("routine_ids", "daily") == ids and int(progress.routines.daily.targets[ids[0]]) == int(routines.daily.missions[ids[0]].goal.targets.middle), "fase não muda a meta já sorteada")
	# Idade do save não completa: baseline pelo contador atual.
	progress.stats["care_useful"] = 40
	progress.stats["harvest"] = 99
	state.call("dev_restart_routines")
	for id: String in state.call("routine_ids", "daily"):
		check(int(state.call("routine_value", "daily", id)) == 0, "%s começa do zero apesar do histórico" % id)
	# Contador de lotes: 1 por lote, não por unidade.
	state.call("reset")
	state.set("unlimited_storage", true)
	var before := _stat("production_jobs")
	var station: RefCounted = state.call("station", "stove")
	station.queue.append({"recipe": "carrot_snack", "ready_at": 0.0, "qty": 3})
	state.call("collect", "stove")
	check(_stat("production_jobs") == before + 1, "lote de várias unidades conta 1 (%d)" % (_stat("production_jobs") - before))
	check(_stat("produce") >= 3, "produce segue contando unidades")


func _nina_check() -> void:
	var quests: Dictionary = database.get("quests")
	check(str(quests.nina_rare.line) == "nina_discoveries" and int(quests.nina_rare.order) == 10, "nina_rare virou linha opcional nina_discoveries (ordem 10)")
	check(quests.nina_rare.requirements.quests == ["nina_walk"], "nina_discoveries começa depois de nina_walk")
	check(database.get("progression").upgrades.petshop.requirements.quests == ["nina_routes"], "pet shop depende de nina_routes")
	state.call("reset")
	var progress := _progress()
	for id: String in ["nina_meet", "nina_walk", "bloblo_chest", "nina_routes"]:
		progress.claimed_quests[id] = true
	check(progress.current_line_quest("nina") == "nina_petshop", "linha nina segue direto para o pet shop sem o raro (%s)" % progress.current_line_quest("nina"))
	check(progress.current_line_quest("nina_discoveries") == "nina_rare", "o raro continua disponível na linha opcional")
	check(state.call("requirement_error", database.get("progression").upgrades.petshop.requirements) == "", "pet shop liberado sem nunca ter achado raro")
	progress.claimed_quests["nina_rare"] = true
	check(progress.current_line_quest("nina_discoveries") == "", "quem já recebeu o raro mantém o prêmio e a linha encerrada")
