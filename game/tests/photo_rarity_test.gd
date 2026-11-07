extends SceneTree
## Fotos do Tiro, etapa 01: a foto é uma carta que chega FECHADA; abrir sorteia o nível (pesos e garantias),
## "Tentar a sorte" custa só moedas, "Melhorar" usa materiais e sobe sempre +1 nível, varal de 3,
## tutorial com resultados forçados sem cobrar, e persistência (SAVE_VERSION 19).

var state: Node
var db: Node
var failures := 0
var rolled: Array = []
var taken: Array = []
var sealed: Array = []


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void:
		print("PHOTO RARITY TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Cartas: " + message)


func _fresh() -> void:
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_reset_album()
	state.test_time = 1791936000.0
	state.coins = 0
	rolled.clear()
	taken.clear()
	sealed.clear()


func _reload() -> void:
	state.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))


func _histogram(id: String, count: int) -> Dictionary:
	var hist := {1: 0, 2: 0, 3: 0, 4: 0}
	for i in count:
		hist[state._roll_rarity(id)] += 1
	return hist


func _near(hist: Dictionary, total: int, expected: Array, tolerance: float, label: String) -> void:
	for i in 4:
		var share := float(hist[i + 1]) / float(total)
		check(absf(share - float(expected[i])) <= tolerance, "%s nível %d: %.3f (esperado ~%.2f)" % [label, i + 1, share, expected[i]])


## Compara dicionários de números por valor (o JSON traz inteiros como float).
func _same(a: Dictionary, b: Dictionary) -> bool:
	if a.size() != b.size(): return false
	for key: Variant in a:
		if not b.has(key) or not is_equal_approx(float(a[key]), float(b[key])): return false
	return true


func _give(items: Dictionary) -> void:
	for item: String in items:
		state.inventory.add(item, int(items[item]))


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	var events: Node = root.get_node("Events")
	events.photo_rolled.connect(func(id: String, result: Dictionary) -> void: rolled.append([id, result]))
	events.photo_taken.connect(func(id: String) -> void: taken.append(id))
	events.photo_sealed.connect(func(id: String) -> void: sealed.append(id))
	_fresh()

	# Dados: bloco `cards` (o antigo `rarity` não existe mais)
	check(not db.album.has("rarity") and db.album.has("cards"), "bloco renomeado para cards")
	var cards: Dictionary = db.album.cards
	var arts: Array = []
	for def: Dictionary in cards.levels: arts.append(str(def.art))
	check(arts == ["common", "shiny", "rare", "holographic"], "nível ↔ arte")
	check(state.album_rarity_def(3).get("name", "") == "Rara" and state.album_rarity_def(9).is_empty(), "definições dos níveis")
	check(_same(cards.reroll, {"coins": 40, "coins_step": 20, "coins_max": 160}), "tentar a sorte: só moedas")
	check(int(cards.featured_slots) == 3 and cards.tutorial.photo == "h_arrival" and (cards.tutorial.forced as Array).map(func(v: Variant) -> int: return int(v)) == [1, 2, 3], "varal e tutorial")
	check(_same(cards.upgrade["2"].items, {"wood": 4, "stone": 3}) and int(cards.upgrade["3"].coins) == 80 and cards.upgrade["4"].items.has("crystal"), "tabela de melhorar")
	for entry: Dictionary in db.album.photos:
		var section := str(entry.section)
		if section == "story": check(not bool(entry.get("repeatable", false)), "história não repete: " + str(entry.id))
		if section in ["tricks", "sleep"]: check(bool(entry.get("repeatable", false)), "momento que repete: " + str(entry.id))

	# Os prêmios de coleção (etapa 10) mexem nas moedas: este teste mede só custos, então os desliga (album_rewards_test cobre eles).
	cards["rewards"] = {}

	# 1. Foto nova chega fechada, sem sorteio
	state._take_photo("f_bath")
	var closed: Dictionary = state.photo_info("f_bath")
	check(closed.sealed == 1 and not closed.opened and state.photo_rarity("f_bath") == 0, "carta fechada sem nível")
	check(closed.variants == [] and closed.rolls == 0, "sem versões nem sorteios")
	check(rolled.is_empty() and taken == ["f_bath"], "photo_taken uma vez e nenhum sorteio")
	check(state.album.rarity_seed == 0 and state.album.pity_rare == 0 and state.album.pity_holo == 0, "tirar não gasta semente nem garantia")
	check(state.sealed_photos() == ["f_bath"] and state.album.has_photo("f_bath"), "fechada conta como foto tirada")
	check(state.reroll_photo_error("f_bath") != "" and state.upgrade_photo_error("f_bath") != "" and state.feature_photo_error("f_bath") != "", "fechada não rola, não melhora, não vai ao varal")

	# 2. Abrir
	check(state.open_photo_card_error("fantasma") != "", "foto que não tem")
	check(state.open_photo_card("f_bath") == "", "abrir funciona")
	var opened: Dictionary = state.photo_info("f_bath")
	check(opened.sealed == 0 and opened.opened and int(opened.rarity) in [1, 2, 3, 4], "abriu e ganhou nível")
	check(rolled.size() == 1 and rolled[0][1].kind == "open" and rolled[0][1].new_photo and rolled[0][1].new_variant, "sinal da abertura")
	check(opened.variants == [opened.rarity] and opened.rolls == 1 and state.progress.stat("photo_opens") == 1, "versão, sorteio e contador")
	check(state.open_photo_card("f_bath") != "" and state.photo_sealed("f_bath") == 0, "não abre duas vezes")
	check(state.rarity_counts()[int(opened.rarity)] == 1, "contagem por raridade")

	# 3. Pesos e determinismo
	_fresh()
	var total := 6000
	_near(_histogram("f_bath", total), total, [0.45, 0.30, 0.18, 0.07], 0.06, "normal")
	_fresh()
	_near(_histogram("h_arrival", total), total, [0.20, 0.35, 0.30, 0.15], 0.06, "história")
	_fresh()
	state.album.rarity_seed = 4242
	var first := _histogram("f_bath", 50)
	_fresh()
	state.album.rarity_seed = 4242
	check(_histogram("f_bath", 50) == first, "mesma semente, mesmo resultado")

	# 4. Garantias (abrir e tentar a sorte contam; melhorar não)
	_fresh()
	state.album.pity_rare = 10
	check(state._roll_rarity("f_bath") >= 3 and state.album.pity_rare == 0, "garantia de Rara+ após 10 sem")
	state.album.pity_holo = 30
	check(state._roll_rarity("f_bath") == 4, "garantia de Holográfica após 30 sem")
	check(state.album.pity_holo == 0 and state.album.pity_rare == 0, "contadores zeram na Holográfica")
	_fresh()
	state.album.rarity_seed = 7
	var longest := 0
	var run := 0
	for i in 400:
		if state._roll_rarity("f_bath") >= 3: run = 0
		else:
			run += 1
			longest = maxi(longest, run)
	check(longest <= 10, "nunca mais de 10 sem Rara+ (%d)" % longest)
	_fresh()
	state._take_photo("f_bath")
	state.album.pity_rare = 3
	state.album.pity_holo = 5
	state.open_photo_card("f_bath")
	check(state.album.pity_holo != 5, "abrir conta como sorteio nas garantias")
	state.album.pity_rare = 3
	state.album.pity_holo = 5
	var seed_now: int = state.album.rarity_seed
	state.album.photos["f_bath"]["rarity"] = 1
	state.album.photos["f_bath"]["variants"] = [1]
	state.coins = 5000
	_give({"wood": 4, "stone": 3})
	check(state.upgrade_photo("f_bath") == "", "melhorar")
	check(state.album.pity_rare == 3 and state.album.pity_holo == 5 and state.album.rarity_seed == seed_now, "melhorar não mexe nas garantias nem na semente")

	# 5. Tentar a sorte: só moedas
	_fresh()
	state._take_photo("h_arrival")
	state.open_photo_card("h_arrival")
	var first_cost: Dictionary = state.reroll_cost("h_arrival")
	check(first_cost.coins == 40 and first_cost.items == {}, "primeira tentativa 40 moedas")
	state.coins = 39
	var rolls_before: int = state.album.photos["h_arrival"].rolls
	check(state.reroll_photo_error("h_arrival") == "Faltam 1 moedas", "falta moeda")
	check(state.reroll_photo("h_arrival") != "" and state.coins == 39 and state.album.photos["h_arrival"].rolls == rolls_before, "erro não consome nem sorteia")
	state.coins = 100000
	state.album.rarity_seed = 99
	var costs: Array = []
	var expected: Array = [40, 60, 80, 100, 120, 140, 160, 160, 160]
	var step := 0
	rolled.clear()
	while not state.photo_styles_complete("h_arrival") and step < 60:
		var cost: int = state.reroll_cost("h_arrival").coins
		var before: int = state.coins
		check(state.reroll_photo("h_arrival") == "", "tentativa %d" % step)
		check(before - state.coins == cost, "cobra só as moedas (%d)" % cost)
		if step < expected.size(): check(cost == expected[step], "custo %d = %d (veio %d)" % [step, expected[step], cost])
		costs.append(cost)
		step += 1
	check(costs.max() <= 160, "custo respeita o teto")
	check(state.photo_variants("h_arrival") == [1, 2, 3, 4] and state.photo_rarity("h_arrival") == 4, "versões entram até completar")
	check(rolled.size() == step and rolled[0][1].kind == "reroll" and state.progress.stat("photo_rerolls") == step, "sinal e contador")
	check(state.reroll_photo_error("h_arrival") != "", "completa não tenta a sorte")
	check(state.progress.stat("photo_holo") == 1, "contou a Holográfica")

	# 6. Melhorar: sempre +1, custo do destino
	_fresh()
	state._take_photo("f_bath")
	state.dev_take_photo("f_bath", 1)
	check(state.photo_rarity("f_bath") == 1 and state.photo_sealed("f_bath") == 0, "dev abre a carta")
	var up: Dictionary = state.upgrade_cost("f_bath")
	check(up.level == 2 and up.coins == 30 and _same(up.items, {"wood": 4, "stone": 3}), "custo do destino 2")
	state.coins = 1000
	var err: String = state.upgrade_photo_error("f_bath")
	check(err.begins_with("Falta ") and "×4" in err, "mensagem com o item que falta: " + err)
	var coins_before: int = state.coins
	check(state.upgrade_photo("f_bath") != "" and state.coins == coins_before and state.photo_rarity("f_bath") == 1, "erro não consome")
	_give({"wood": 4, "stone": 3})
	state.coins = 29
	check(state.upgrade_photo_error("f_bath") == "Faltam 1 moedas", "falta moeda")
	state.coins = 1000
	rolled.clear()
	check(state.upgrade_photo("f_bath") == "", "melhorou para 2")
	check(state.photo_rarity("f_bath") == 2 and state.photo_variants("f_bath") == [1, 2] and state.coins == 970, "exatamente +1 e moedas")
	check(state.inventory.count("wood") == 0 and state.inventory.count("stone") == 0, "materiais consumidos")
	check(rolled.size() == 1 and rolled[0][1].kind == "upgrade" and rolled[0][1].improved and not rolled[0][1].new_photo, "sinal")
	check(state.album.photos["f_bath"].upgrades == 1 and state.album.photos["f_bath"].rolls == 1 and state.photo_shown_rarity("f_bath") == 2, "não conta sorteio e mostra a melhor")
	check(state.upgrade_cost("f_bath").items.has("plank") and state.upgrade_cost("f_bath").coins == 80, "custo do destino 3")
	_give({"plank": 3, "copper": 2, "fiber": 4, "crystal": 3, "hardwood": 3, "fabric": 2})
	check(state.upgrade_photo("f_bath") == "" and state.photo_rarity("f_bath") == 3, "melhorou para 3")
	check(state.upgrade_photo("f_bath") == "" and state.photo_rarity("f_bath") == 4, "melhorou para 4")
	check(state.progress.stat("photo_upgrades") == 3 and state.progress.stat("photo_holo") == 1, "contadores")
	check(state.upgrade_photo_error("f_bath") != "" and state.upgrade_cost("f_bath").is_empty(), "no 4 dá erro")
	# Pulou versões: melhorar parte do melhor, não da menor
	_fresh()
	state._take_photo("f_bath")
	state.dev_take_photo("f_bath", 3)
	_give({"crystal": 3, "hardwood": 3, "fabric": 2})
	state.coins = 500
	check(state.upgrade_photo("f_bath") == "" and state.photo_rarity("f_bath") == 4 and state.photo_variants("f_bath") == [3, 4], "do 3 vai ao 4")

	# 7. Retomada natural
	_fresh()
	state._take_photo("f_bath")
	state.open_photo_card("f_bath")
	state.album.photos["f_bath"]["rarity"] = 1
	state.album.photos["f_bath"]["variants"] = [1]
	sealed.clear()
	rolled.clear()
	state._album_event("bathed")
	check(state.photo_sealed("f_bath") == 0 and sealed.is_empty(), "espera de 20 h respeitada")
	state.test_time += 21.0 * 3600.0
	state._album_event("bathed")
	check(state.photo_sealed("f_bath") == 1 and sealed == ["f_bath"] and rolled.is_empty(), "passou a espera: mais uma carta fechada")
	check(state.photo_rarity("f_bath") == 1 and state.album.photos["f_bath"].rolls == 1, "retomar não sorteia")
	state._album_event("bathed")
	check(state.photo_sealed("f_bath") == 1, "a carta nova também tem espera")
	state.test_time += 21.0 * 3600.0
	state._album_event("bathed")
	check(state.photo_sealed("f_bath") == 2, "outra depois da espera")
	state.open_photo_card("f_bath")
	state.open_photo_card("f_bath")
	check(state.photo_sealed("f_bath") == 0 and state.photo_rarity("f_bath") >= 1, "abre as duas")
	_fresh()
	state._album_event("intro_done")
	check(state.album.has_photo("h_arrival") and state.photo_sealed("h_arrival") == 1, "foto da história chegou fechada")
	state.open_photo_card("h_arrival")
	state.test_time += 100.0 * 3600.0
	state._album_event("intro_done")
	check(state.photo_sealed("h_arrival") == 0 and sealed.is_empty(), "foto da história nunca retoma")
	_fresh()
	state._take_photo("f_bath")
	state.test_time += 100.0 * 3600.0
	state._album_event("bathed")
	check(state.photo_sealed("f_bath") == 1, "fechada e nunca aberta não acumula")
	_fresh()
	state.dev_take_photo("f_bath", 1)
	state.dev_take_photo("f_bath", 2)
	state.dev_take_photo("f_bath", 3)
	state.dev_take_photo("f_bath", 4)
	state.test_time += 100.0 * 3600.0
	state._album_event("bathed")
	check(state.photo_styles_complete("f_bath") and state.photo_sealed("f_bath") == 0, "completa não retoma")

	# 8. Varal
	_fresh()
	var ids := ["f_bath", "h_arrival", "f_taste", "f_dig"]
	for id: String in ids:
		check(not db.photo(id).is_empty(), "foto existe: " + id)
	state.dev_take_photo("f_bath", 1)
	state.dev_take_photo("h_arrival", 2)
	state.dev_take_photo("f_taste", 1)
	state._take_photo("f_dig")
	check(state.feature_photo_error("f_dig") != "" and state.featured_photos().is_empty(), "fechada não entra")
	check(state.feature_photo("f_bath") == "" and state.feature_photo("h_arrival") == "" and state.feature_photo("f_taste") == "", "três entram")
	check(state.feature_photo_error("f_bath") != "", "duplicada recusada")
	state.dev_take_photo("f_dig", 1)
	check(state.feature_photo("f_dig") == "Escolha qual sai" and state.featured_photos().size() == 3, "o quarto pede troca")
	check(state.unfeature_photo("h_arrival") == "" and state.feature_photo("f_dig") == "", "tirar e trocar")
	check(state.featured_photos() == ["f_bath", "f_taste", "f_dig"], "ordem do varal")
	check(state.unfeature_photo("h_arrival") != "", "tirar quem não está")

	# 9. Tutorial
	_fresh()
	state._take_photo("h_arrival")
	state._take_photo("f_bath")
	check(state._tutorial_level("h_arrival", "open") == 0 and state.album_tutorial_step() == 0, "sem tutorial nada é forçado")
	state.advance_album_tutorial(1)
	state.album.pity_rare = 3
	state.album.pity_holo = 5
	state.album.rarity_seed = 777
	state.coins = 0
	rolled.clear()
	check(state._tutorial_level("f_bath", "open") == 0, "só a foto da chegada")
	check(state.open_photo_card("h_arrival") == "" and state.photo_rarity("h_arrival") == 1, "passo 1-2: Comum")
	check(rolled[0][1].kind == "tutorial" and rolled[0][1].action == "open", "sinal do tutorial")
	check(state.album.pity_rare == 3 and state.album.pity_holo == 5 and state.album.rarity_seed == 777, "abrir forçado não mexe nas garantias")
	state.advance_album_tutorial(1)
	check(state.album_tutorial_step() == 1, "passo não volta")
	check(state.reroll_photo_error("h_arrival") != "" or state._tutorial_level("h_arrival", "reroll") == 0, "ainda não é a hora de rolar")
	state.advance_album_tutorial(3)
	check(state.reroll_photo("h_arrival") == "" and state.photo_variants("h_arrival") == [1, 2] and state.coins == 0, "passo 3: Brilhante grátis")
	check(state.album.pity_rare == 3 and state.album.pity_holo == 5 and state.album.rarity_seed == 777, "rolar forçado não mexe nas garantias")
	check(state.album.photos["h_arrival"].rerolls == 0 and state.reroll_cost("h_arrival").coins == 40, "tutorial não encarece a próxima")
	state.advance_album_tutorial(4)
	check(state.upgrade_photo("h_arrival") == "" and state.photo_rarity("h_arrival") == 3 and state.coins == 0, "passo 4: Rara grátis")
	check(state.photo_variants("h_arrival") == [1, 2, 3] and state.inventory.count("wood") == 0, "sem presente no inventário")
	check(state.progress.stat("photo_opens") == 1 and state.progress.stat("photo_rerolls") == 1 and state.progress.stat("photo_upgrades") == 1, "contadores normais")
	state.advance_album_tutorial(6)
	check(state.feature_photo("h_arrival") == "" and state.featured_photos() == ["h_arrival"], "passo 6: varal")
	state.finish_album_tutorial()
	check(state.album_tutorial_done() and state._tutorial_level("h_arrival", "reroll") == 0, "depois de acabar nada é forçado")
	check(state.reroll_photo_error("h_arrival") == "Faltam 40 moedas", "depois do tutorial cobra")
	state.dev_reset_album_tutorial()
	check(state.album_tutorial_step() == 0 and not state.album_tutorial_done(), "DEV reinicia o tutorial")
	# Só o DEV força um nível
	_fresh()
	state.dev_take_photo("h_arrival", 4)
	check(state.photo_rarity("h_arrival") == 4 and state.photo_sealed("h_arrival") == 0, "dev abre no nível pedido")
	state.dev_seal_photo("h_arrival")
	check(state.photo_sealed("h_arrival") == 1, "dev fecha mais uma carta")

	# 10. Salvar e carregar
	_fresh()
	state.dev_take_photo("h_arrival", 1)
	state.dev_take_photo("h_arrival", 3)
	state._take_photo("f_bath")
	state.dev_take_photo("f_taste", 2)
	state.set_photo_variant("h_arrival", 1)
	state.feature_photo("h_arrival")
	state.feature_photo("f_taste")
	state.advance_album_tutorial(4)
	state.album.pity_rare = 4
	state.album.pity_holo = 11
	state.album.rarity_seed = 31337
	state.album.photos["h_arrival"]["upgrades"] = 2
	_reload()
	var back: Dictionary = state.photo_info("h_arrival")
	check(back.rarity == 3 and back.variants == [1, 3] and back.shown == 1 and state.photo_shown_rarity("h_arrival") == 1, "versões e mostrada sobrevivem")
	check(back.upgrades == 2 and back.opened and back.sealed == 0, "campos novos sobrevivem")
	check(state.photo_sealed("f_bath") == 1 and state.photo_rarity("f_bath") == 0 and not state.photo_info("f_bath").opened, "carta fechada sobrevive")
	check(state.featured_photos() == ["h_arrival", "f_taste"], "varal sobrevive")
	check(state.album_tutorial_step() == 4 and not state.album_tutorial_done(), "tutorial sobrevive")
	check(state.album.pity_rare == 4 and state.album.pity_holo == 11 and state.album.rarity_seed == 31337, "garantias e semente")
	var save_version: Variant = (load("res://autoload/save_manager.gd") as GDScript).get_script_constant_map().get("SAVE_VERSION")
	check(int(save_version) == 19, "SAVE_VERSION 19")

	print("PHOTO RARITY TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
