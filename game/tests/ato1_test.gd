extends SceneTree
## F01 do plano "Novo fluxo": o Ato 1 acontece só em casa, uma coisa nova por vez, sem moeda, e termina no
## Filhotinho e na carta da chegada. Joga os passos 1 a 8 pelas ações reais e confere a roleta de cuidados,
## as abas do rodapé, o botão do Álbum, o Sítio fechado e as mãos de ajuda.
## --headless --path game -s res://tests/ato1_test.gd

var failures := 0
var state: Node
var main: Control
var tray: Control
var coins_start := 0


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("ATO 1: " + message)


func frames(count: int = 3) -> void:
	for i in count:
		await process_frame


func node(node_name: String) -> Control:
	return main.find_child(node_name, true, false) as Control


func shown(node_name: String) -> bool:
	var control := node(node_name)
	return control != null and control.is_visible_in_tree()


## Discos da roleta que o jogador já pode ver, na ordem do leque.
func discs() -> Array[String]:
	var result: Array[String] = []
	for child: Node in node("CareWheelOpen").get_children():
		if child is Button and (child as Control).visible:
			result.append(str(child.name))
	return result


func quest() -> String:
	return str(state.progress.current_main_quest())


func claim(id: String) -> void:
	if bool(root.get_node("Database").quests[id].get("auto_claim", false)):
		check(state.progress.claimed_quests.has(id), "%s se entregou sozinho (sem Pegar)" % id)
		await frames()
		return
	check(quest() == id, "passo %s é o atual (era %s)" % [id, quest()])
	check(state.quest_error(id) == "", "%s pode ser pego (%s)" % [id, state.quest_error(id)])
	check(state.claim_quest(id) == "", "pegar %s" % id)
	await frames()


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	var db: Node = root.get_node("Database")
	Motion.reduced = true
	state.call("reset")
	coins_start = state.coins

	# Os oito passos do capítulo 1, na ordem, e a lista curta do Filhotinho.
	var steps: Array = state.progress.main_quests(1).slice(0, 5)  # o resto (Sítio, vovó, papinha e crescer) é do ato2_test
	check(steps == ["welcome", "lais_feed", "lais_bath", "lais_play", "lais_bed"], "ordem dos passos em casa: " + str(steps))
	check(state.progress.main_quests(2).has("lais_photo") and not state.progress.main_quests(1).has("lais_photo"), "a foto da chegada foi para o capítulo 2 (depois dos canteiros)")
	check(state.progress.main_quests(1).slice(-2) == ["lais_growth", "growth_1_puppy"], "o capítulo 1 fecha com o crescimento")
	check(not db.quests.has("lais_album"), "a linha lais_album saiu")
	check(state.progress.main_quests(2).find("lais_bed") == -1 and state.progress.main_quests(2).find("growth_1_puppy") == -1, "capítulo 2 perdeu a caminha e o Filhotinho")
	check(db.progression.chapters.size() >= 2 and state.progress.main_quests(2).size() > 0, "capítulo 2 continua existindo")
	var puppy: Dictionary = db.growth.phases[1]
	var ids: Array = puppy.requirements.map(func(req: Dictionary) -> String: return str(req.id))
	check(puppy.id == "puppy" and ids == ["feed", "bath", "play", "bed", "home_mash"] and int(puppy.chapter) == 1, "Filhotinho pede comer, banho, brincar, caminha e a papinha caseira: " + str(ids))
	check(not puppy.rewards.has("coins") and int(puppy.rewards.items.dog_food) == 3, "Filhotinho sem moedas, com a ração")
	var teething: Dictionary = db.growth.phases[2]
	var days := {}
	for req: Dictionary in teething.requirements:
		if str(req.id) == "days": days = req
	check(int(days.get("qty", 0)) == 6 and bool(days.get("total", false)), "Dentinhos pedem 6 patinhas contando o dia da chegada")
	var teething_ids: Array = teething.requirements.map(func(req: Dictionary) -> String: return str(req.id))
	for moved: String in ["star_dish", "invented", "name"]:
		check(teething_ids.count(moved) == 1, "Dentinhos recebeu " + moved)

	# Caixinha: a fala final é da Laís e o save vira "de verdade" (as regras do Ato 1 passam a valer).
	var lines: Array = db.week_story.arrival.lines
	check(str(lines[lines.size() - 1].npc) == "lais", "a última fala da caixinha é da Laís")
	check(not db.week_story.arrival.lines.any(func(line: Dictionary) -> bool: return str(line.npc) == "bloblo"), "a vovó não aparece na caixinha")
	state.call("finish_week_arrival")
	check(quest() == "welcome", "o primeiro passo é a caixinha")
	check(state.progress.stat("arrival_box") == 1, "caixinha aberta")
	check(state.requirement_error({"story_gate": ["lais_photo"]}) != "", "porta do Ato 1 fechada")

	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await frames(4)
	main.call("show_screen", &"pet")
	tray = node("CareTray")
	await frames()

	# Passo 1: a caixinha. Antes de pegar o prêmio ainda não há cuidados nem abas.
	check(shown("CareButton"), "o passeio pela casa começa no Cuidar (sem repetir o carinho da abertura)")
	check(not shown("MapTab") and not shown("TasksTab") and not shown("BagTab"), "só a aba Tiro no rodapé")
	check(not shown("AlbumButton"), "sem botão do Álbum")
	check(not shown("CoinsPill"), "sem pílula de moedas no Ato 1")
	check(state.quest_error("welcome") != "", "o Pegar da primeira missão espera o passeio pela casa")
	state.call("finish_home_tour")
	check(state.quest_error("welcome") == "", "o fim do passeio libera o Pegar")
	await claim("welcome")
	check(state.inventory.count("puppy_mash") == 1, "a papinha pronta veio da caixinha")
	check(state.coins == coins_start, "a caixinha não paga moeda")

	# Passo 2: comida. O botão Cuidar aparece com só um disco.
	check(shown("CareButton"), "Cuidar aparece depois da caixinha")
	tray.call("open_wheel")
	await frames()
	check(discs() == ["FoodButton"], "a roleta tem só a Comida: " + str(discs()))
	var cuidar: Control = node("CareButton")
	var food: Control = node("FoodButton")
	check(absf(food.get_global_rect().get_center().x - cuidar.get_global_rect().get_center().x) < 40.0, "um disco só fica logo acima do botão")
	tray.call("close_wheel")
	check(state.feed("puppy_mash"), "dar a papinha")
	check(state.progress.stat("well_fed_day") == 0, "antes da aula da comida a papinha não registra ✓ nem patinha (a aula dá a primeira)")
	await claim("lais_feed")

	# Passo 3: banho.
	tray.call("open_wheel")
	await frames()
	check(discs() == ["FoodButton", "Care_sponge"], "o Banho entrou na roleta: " + str(discs()))
	tray.call("close_wheel")
	check(state.bathe(), "dar banho")
	await claim("lais_bath")

	# Passo 4: brincar. A bolinha gera a caminha de presente.
	tray.call("open_wheel")
	await frames()
	check(discs() == ["FoodButton", "Care_sponge", "Care_ball"], "Brincar entrou na roleta: " + str(discs()))
	tray.call("close_wheel")
	check(not shown("MapTab"), "ainda sem Mapa")
	check(state.play(), "jogar a bolinha")
	check(state.inventory.count("bed_gift") == 0, "a caminha ainda não chegou")
	await claim("lais_play")
	check(state.inventory.count("bed_gift") == 1, "a caminha vem direto para o inventário")
	check(state.coins == coins_start, "brincar não paga moeda")

	# Passo 5: a caminha na Casa. Aparece o Mapa (só a Casa), sem pílula do mundo.
	check(shown("MapTab") and shown("TasksTab") and not shown("BagTab"), "o Mapa entra no rodapé (Missões já estão desde o Pegar do welcome)")
	var upgrade: Dictionary = db.progression.upgrades.dog_bed
	check(int(upgrade.cost) == 0 and str(upgrade.get("verb", "")) == "Colocar", "a caminha é grátis e a folha diz Colocar")
	check(state.upgrade_error("dog_bed") == "", "a caminha pode ser colocada: " + str(state.upgrade_error("dog_bed")))
	check(state.requirement_error(db.worlds.farm.requirements) != "", "o Sítio ainda está fechado")
	main.call("show_screen", &"map")
	await frames(4)
	var map_pill: Control = node("MapButton")
	check(map_pill != null and not map_pill.visible, "sem pílula do mundo com um mundo só")
	tray.call("open_wheel")
	await frames()
	check(discs() == ["FoodButton", "Care_sponge", "Care_ball"], "a roleta não ganhou o soninho ainda")
	tray.call("close_wheel")
	check(state.buy_upgrade("dog_bed") == "", "colocar a caminha")
	check(state.inventory.count("bed_gift") == 0, "a caminha gastou o presente")
	await claim("lais_bed")
	main.call("show_screen", &"pet")
	tray.call("open_wheel")
	await frames()
	check(discs() == ["FoodButton", "Care_sponge", "Care_ball", "SleepButton"], "o soninho entrou na roleta: " + str(discs()))
	tray.call("close_wheel")

	# Fim da casa: a caminha abre o Sítio. A foto da chegada espera o capítulo 2 (o Álbum ainda não aparece).
	check(state.growth.phase == "newborn" and state.grow_error() != "", "ainda não cresce: falta a papinha caseira")
	await frames(3)
	check(not shown("AlbumButton"), "o botão do Álbum espera a foto do capítulo 2")
	check(shown("TasksTab") and not shown("BagTab"), "Missões desde o começo; a Mochila espera o fim do Ato 1")
	check(state.photo_sealed("h_arrival") > 0 and not state.album_tutorial_done(), "a carta da chegada espera fechada")
	check(state.coins == coins_start, "nenhuma moeda ganha em todo o Ato 1")
	check(not shown("CoinsPill"), "a pílula de moedas só volta no capítulo 2")
	check(state.requirement_error(db.worlds.farm.requirements) == "", "o Sítio abre depois da caminha")
	check(quest() == "lais_farm", "o Sítio vem logo depois da caminha")
	check(str(db.quests.lais_farm.dialogue).contains("uma vez de dia e uma de noite"), "a fala-gancho: uma vez de dia e uma de noite")
	# Mãos de ajuda: cada passo tem a sua lição presa ao passo (não ao dia).
	var lessons := {}
	for lesson: Dictionary in db.week_tutorials:
		lessons[str(lesson.id)] = lesson
	var wanted := {"home_tour": "welcome", "home_claim": "welcome", "home_feed": "lais_feed", "home_bath": "lais_bath", "home_play": "lais_play", "home_bed": "lais_bed",
		"home_growth": "lais_growth", "home_grow": "growth_1_puppy", "home_album": "lais_photo"}
	for id: String in wanted:
		check(lessons.has(id) and str(lessons[id].get("quest", "")) == str(wanted[id]), "lição %s presa ao passo %s" % [id, wanted[id]])

	print("ATO 1 TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
