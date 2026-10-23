extends SceneTree
## Etapa 22: Festa da Vila, Lenço da nossa turma, capítulos 10–12 e Encontro da turma.
## --headless --path game -s res://tests/festival_test.gd

var failures: int = 0
var checks: int = 0
var state: Node
var database: Node
var events: Node
var toasts: Array[String] = []
var gathered: Array = []
var chapters_done: Array = []

const FEST := "village_festival"
const BENCH := "park_bench"
const GARDEN := "village_garden"
const PICNIC := "park_picnic"
const RIBBON := "community_ribbon"
const NEW_QUESTS := ["community_10_meet", "community_10_bench", "community_10_use", "community_11_garden", "community_11_picnic", "community_11_tiro", "community_12_prepare", "community_12_festival", "community_12_memory"]


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("Festa: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _inv() -> RefCounted:
	return state.get("inventory")


func _progress() -> RefCounted:
	return state.get("progress")


func _reload() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


func _fresh() -> void:
	state.call("reset")
	state.set("xp", 0)
	state.set("level", 1)
	for id: String in ["stove", "workbench", "fridge", "atelier", "chest", "silo", "warehouse"]:
		state.call("dev_grant_upgrade", id)
	toasts.clear()
	gathered.clear()
	chapters_done.clear()
	state.call("dev_complete_quest", "atelier_open")


func _give_all(id: String) -> void:
	for phase: Dictionary in database.project(id).phases:
		for item: String in phase.items:
			_inv().add(item, int(phase.items[item]))
		for item: String in phase.items:
			var error: String = state.call("contribute_project", id, item, int(phase.items[item]))
			check(error == "", "%s/%s ×%d: %s" % [id, item, int(phase.items[item]), error])


## Banco, jardim e piquenique feitos pelo caminho legítimo (taxa + entrega).
func _before_festival() -> void:
	for id: String in [BENCH, GARDEN, PICNIC]:
		state.set("coins", int(database.project(id).start_coins))
		check(state.call("start_project", id) == "", id + " começa")
		_give_all(id)
		check(state.call("project_completed", id), id + " concluído")


func _festival_done() -> void:
	_before_festival()
	state.call("dev_grant_upgrade", "stall_3")
	state.set("coins", 500)
	check(state.call("start_project", FEST) == "", "festa começa")
	_give_all(FEST)
	check(state.call("project_completed", FEST), "festa concluída")


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	events = root.get_node("Events")
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	events.project_gathered.connect(func(id: String, cycle: int) -> void: gathered.append([id, cycle]))
	events.chapter_completed.connect(func(chapter: int) -> void: chapters_done.append(chapter))
	_data_check()
	_gates()
	_rewards_and_ribbon()
	_story()
	_completed_history()
	_meeting()
	_meeting_edges()
	await _scene_and_ui()
	print("FESTIVAL TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures, " (%d verificações)" % checks)
	quit(0 if failures == 0 else 1)


func _ints(items: Dictionary) -> Dictionary:
	var out := {}
	for key: String in items:
		out[key] = int(items[key])
	return out


func _data_check() -> void:
	check((database.project_problems() as Array).is_empty(), "catálogo sem problemas: %s" % str(database.project_problems()))
	var def: Dictionary = database.project(FEST)
	check(int(def.start_coins) == 500 and def.requirements == {"projects": [GARDEN, PICNIC], "owned": ["stall_3"]}, "entrada 500; exige jardim, piquenique e a banca 3")
	var ph: Array = def.phases
	check(ph.size() == 3 and ph[0].id == "decorate" and ph[1].id == "table" and ph[2].id == "gifts", "fases decorate/table/gifts")
	check(_ints(ph[0].items) == {"fabric": 4, "plank": 6, "accessory_set": 2} and _ints(ph[1].items) == {"picnic_pack": 3, "apple_biscuit": 6, "cheese": 4} and _ints(ph[2].items) == {"treat_box": 3, "braided_toy": 2}, "material (tabela 07 E)")
	check(not def.rewards.has("pillars") and def.rewards.collections == [RIBBON] and def.rewards.size() == 1, "coleção sem pontos ou moedas; momento vem da conclusão")
	check(def.interaction.kind == "festival" and str(def.interaction.go_label) != "" and str(def.done_speech) != "", "interação própria")
	check(ResourceLoader.exists("res://assets/sprites/ui/icons/%s.png" % def.icon), "ícone da festa")
	for phase: Dictionary in ph:
		check(ResourceLoader.exists("res://assets/sprites/areas/village/festival_%s.png" % phase.visual_state), "arte " + str(phase.id))
	var found := false
	for obj: Dictionary in database.room("village").objects:
		if str(obj.get("project", "")) == FEST:
			found = true
			check(obj.project_sprites.has("ghost") and obj.project_sprites.has("decorate") and obj.project_sprites.has("table") and obj.project_sprites.has("gifts"), "sprites da cena")
	check(found, "objeto da festa na Vila")
	var places: Dictionary = database.worlds.village.places
	check(places.festival.panel == "project:" + FEST and places.festival.get("hidden", false), "lugar escondido da festa")
	var visible := places.values().filter(func(pl: Dictionary) -> bool: return not pl.get("hidden", false) and not str(pl.get("panel", "")).begins_with("travel"))
	check(visible.size() <= 4, "Vila com %d lugares visíveis" % visible.size())
	# O contrato comercial continua sendo outra coisa.
	check(database.progression.orders.has("festival_contract") and str(database.progression.orders.festival_contract.name) == "Encomenda para eventos", "contrato comercial com nome distinto")
	check(database.quests.merchant_festival.goals[0].key == "order:festival_contract", "missão do Feirante entrega o contrato (mesmo id)")
	var meet: Dictionary = def.gathering
	check(int(meet.hours) == 24 and _ints(meet.items) == {"picnic_pack": 1, "carrot_snack": 2} and _ints(meet.rewards) == {"xp": 10}, "encontro: 24 h, picnic_pack 1 + carrot_snack 2, XP 10")
	check(not meet.has("start_coins"), "encontro sem moedas")
	check(database.collections.has(RIBBON) and database.collections[RIBBON].slot == "neck" and ResourceLoader.exists("res://assets/sprites/ui/icons/outfit_community_ribbon.png"), "coleção do lenço")


func _gates() -> void:
	_fresh()
	check(str(state.call("project_error", FEST)) != "", "sem o resto, a festa não abre")
	_before_festival()
	var reason: String = state.call("project_error", FEST)
	check(reason != "" and not state.call("project_available", FEST), "sem a banca 3: bloqueada (%s)" % reason)
	state.call("dev_grant_upgrade", "stall_3")
	state.set("coins", 499)
	check(str(state.call("project_error", FEST)).begins_with("Faltam"), "499 moedas não bastam")
	state.set("coins", 500)
	check(state.call("start_project", FEST) == "" and state.get("coins") == 0, "500 moedas, uma vez")
	# Jardim sem piquenique não basta.
	_fresh()
	for id: String in [BENCH, GARDEN]:
		state.set("coins", 250)
		state.call("start_project", id)
		_give_all(id)
	state.call("dev_grant_upgrade", "stall_3")
	state.set("coins", 500)
	check(str(state.call("project_error", FEST)) != "", "só o jardim não abre a festa")


func _rewards_and_ribbon() -> void:
	_fresh()
	_before_festival()
	state.call("dev_grant_upgrade", "stall_3")
	state.set("coins", 600)
	state.call("start_project", FEST)
	var coins_after_fee: int = state.get("coins")
	var brave_before := int(state.get("progress").stat("moment:brave"))
	check(not _progress().collection.has(RIBBON), "lenço ainda não existe")
	_give_all(FEST)
	check(_progress().collection.has(RIBBON), "festa entrega o lenço da turma")
	check(state.get("coins") == coins_after_fee, "festa não paga moedas")
	check(int(state.get("progress").stat("moment:brave")) > brave_before, "festa paga Coragem")
	check(str(state.call("equip_error", RIBBON)) == "", "lenço pode ser vestido (overlay pronto)")
	check(state.call("equip", RIBBON) == "" and _progress().equipped.neck == RIBBON, "lenço vai ao pescoço")
	check(state.call("unequip", "neck") == "" and _progress().equipped.neck == "", "e sai")
	# Recebimento repetido (reload e nova conclusão): nada paga duas vezes.
	var xp_mark: int = state.get("xp")
	_reload()
	check(state.call("complete_project", FEST) == "" and state.call("contribute_project", FEST, "fabric", 1) != "", "obra pronta não recebe de novo")
	check(int(state.get("xp")) == xp_mark and state.get("economy").granted.has("project:" + FEST), "recibo único do prêmio")
	# Poses: todos os quadros variantes do lenço vermelho existem também no lenço da turma.
	for clip: String in ["sad", "eat", "lick_paw", "sleep", "head_tilt"]:
		var dir := "res://assets/sprites/characters/tiro_pet/overlays/%s/%s/" % [RIBBON, clip]
		var base_dir := "res://assets/sprites/characters/tiro_pet/overlays/red_scarf/%s/" % clip
		var same := true
		var total := 0
		for file: String in DirAccess.get_files_at(base_dir):
			if file.ends_with(".png"):
				total += 1
				if not ResourceLoader.exists(dir + file):
					same = false
		check(same and total > 0, "lenço tem todos os quadros de " + clip)


func _story() -> void:
	var main_count := 0
	for id: String in database.quests:
		if database.quests[id].get("kind", "side") == "main":
			main_count += 1
	check(main_count == 51 and database.progression.chapters.size() == 12, "51 principais (incluindo primeiro desejo) e 12 capítulos: %d / %d" % [main_count, database.progression.chapters.size()])
	for id: String in NEW_QUESTS:
		check(database.quests.has(id) and database.quests[id].kind == "main", id + " existe")
	var order := {"community_10_meet": [10, 10], "community_10_bench": [10, 20], "community_10_use": [10, 30], "community_11_garden": [11, 10], "community_11_picnic": [11, 20], "community_11_tiro": [11, 30], "community_12_prepare": [12, 10], "community_12_festival": [12, 20], "community_12_memory": [12, 30]}
	for id: String in order:
		check(int(database.quests[id].chapter) == order[id][0] and int(database.quests[id].order) == order[id][1], id + ": capítulo/ordem")
	var paid := {"community_10_use": 10, "community_11_tiro": 10}
	for id: String in NEW_QUESTS:
		var rewards: Dictionary = database.quests[id].rewards
		# A etapa 10 do plano Tiro soma a medalhinha de coragem à lembrança da festa.
		var extra := 1 if id == "community_12_memory" else 0
		check(rewards.size() == (1 if paid.has(id) else 0) + extra and int(rewards.get("coins", 0)) == int(paid.get(id, 0)), id + ": só a recompensa prevista")
		if extra == 1: check(rewards.items.size() == 1 and int(rewards.items.get("courage_medal", 0)) == 1, id + ": só a medalhinha")
	check(int(database.progression.chapters[9].rewards.coins) == 30 and int(database.progression.chapters[10].rewards.coins) == 40 and int(database.progression.chapters[11].rewards.coins) == 60, "capítulos 10/11/12 pagam 30/40/60")
	check(database.quests.community_12_festival.goals[0].type == "project" and database.quests.community_12_festival.goals[0].key == FEST, "objetivo da festa é o projeto")
	check(database.quests.community_10_meet.goals[0].fresh == true and database.quests.community_12_prepare.goals[0].fresh == true, "só as duas conversas pedem toque novo")
	check(str(database.progression.final_chapter.name) != "", "final_chapter definido")
	# Jogo novo até o final: história por ações legais (conversa, obras, uso).
	_fresh()
	for chapter in range(1, 10):
		for id: String in _progress().main_quests(chapter):
			_progress().claimed_quests[id] = true
	_progress().owned["stall_3"] = true
	state.call("_sync_step")
	chapters_done.clear()
	check(_progress().chapter_index() == 10, "depois do 9 vem o capítulo 10")
	check(_progress().current_main_quest() == "community_10_meet", "primeiro passo: conversar com a Laís")
	check(state.call("goal_value", database.quests.community_10_meet.goals[0]) == 0, "conversa fresh começa em zero")
	state.call("talk_to", "lais")
	check(state.call("goal_value", database.quests.community_10_meet.goals[0]) == 1, "tocar na Laís cumpre")
	_claim("community_10_meet")
	check(_progress().current_main_quest() == "community_10_bench", "depois: o banco")
	state.set("coins", 150)
	state.call("start_project", BENCH)
	_give_all(BENCH)
	_claim("community_10_bench")
	state.call("use_project", BENCH)
	_claim("community_10_use")
	check(chapters_done == [10], "capítulo 10 concluído uma vez: %s" % str(chapters_done))
	for id: String in [PICNIC, GARDEN]:
		state.set("coins", 250)
		state.call("start_project", id)
		_give_all(id)
	_claim("community_11_garden")
	_claim("community_11_picnic")
	state.call("use_project", PICNIC)
	_claim("community_11_tiro")
	check(chapters_done == [10, 11], "capítulo 11 concluído: %s" % str(chapters_done))
	check(_progress().current_main_quest() == "community_12_prepare", "capítulo 12 começa na conversa com a Nina")
	state.call("talk_to", "nina")
	_claim("community_12_prepare")
	state.set("coins", 500)
	check(state.call("start_project", FEST) == "", "festa na história")
	_give_all(FEST)
	_claim("community_12_festival")
	check(_progress().current_main_quest() == "community_12_memory", "falta só o uso")
	state.call("use_project", FEST)
	_claim("community_12_memory")
	check(_progress().current_main_quest() == "growth_12_adult", "depois da festa só falta crescer (etapa 11)")
	state.get("growth").phase = "adult"
	_claim("growth_12_adult")
	check(chapters_done == [10, 11, 12] and _progress().chapter_index() == 13 and _progress().current_main_quest() == "", "história completa: capítulos 10, 11 e 12")
	check(str(_progress().current_chapter().name) == str(database.progression.final_chapter.name), "depois do 12 vale o capítulo final")
	_reload()
	check(_progress().chapter_index() == 13 and chapters_done == [10, 11, 12], "reload não repete capítulo nem prêmio")


func _claim(id: String) -> void:
	check(state.call("quest_error", id) == "", "%s pronta: %s" % [id, state.call("quest_error", id)])
	state.call("claim_quest", id)
	check(_progress().claimed_quests.has(id), id + " recebida")


## Quem já tinha tudo até o capítulo 9 e as obras das etapas 20–21 entra no 10 sem refazer nada.
func _completed_history() -> void:
	_fresh()
	for chapter in range(1, 10):
		for id: String in _progress().main_quests(chapter):
			_progress().claimed_quests[id] = true
	_progress().owned["stall_3"] = true
	_before_festival()
	state.call("use_project", BENCH)
	state.call("use_project", PICNIC)
	state.call("_sync_step")
	chapters_done.clear()
	var coins: int = state.get("coins")
	var items: int = _item_total()
	check(_progress().chapter_index() == 10, "histórico completo no 9 entra no 10")
	check(state.call("goal_value", database.quests.community_10_bench.goals[0]) == 1 and state.call("goal_value", database.quests.community_11_garden.goals[0]) == 1 and state.call("goal_value", database.quests.community_11_picnic.goals[0]) == 1, "obras já feitas contam, sem refazer")
	check(state.call("goal_value", database.quests.community_10_use.goals[0]) == 1 and state.call("goal_value", database.quests.community_11_tiro.goals[0]) == 1, "usos já feitos contam")
	check(state.call("goal_value", database.quests.community_10_meet.goals[0]) == 0, "só a conversa pede toque novo")
	state.call("talk_to", "lais")
	for id: String in ["community_10_meet", "community_10_bench", "community_10_use", "community_11_garden", "community_11_picnic", "community_11_tiro"]:
		_claim(id)
	# Os usos pagam 10 moedas cada; XP não paga presentes.
	check(state.get("economy").granted.has("chapter:10") and state.get("economy").granted.has("chapter:11") and not state.get("economy").granted.has("chapter:12"), "pagou só os capítulos 10 e 11")
	check(state.get("coins") == coins + 30 + 40 + 20, "capítulos 30 + 40 e usos 20, sem presente de nível: %d -> %d" % [coins, state.get("coins")])
	check(_item_total() == items, "nada de material novo")
	check(_progress().current_main_quest() == "community_12_prepare", "e segue para a festa")
	# Uso nunca feito: não conta.
	_fresh()
	for chapter in range(1, 10):
		for id: String in _progress().main_quests(chapter):
			_progress().claimed_quests[id] = true
	_before_festival()
	state.call("_sync_step")
	check(state.call("goal_value", database.quests.community_10_use.goals[0]) == 0, "uso nunca feito: não conta")


## Estoque exato do material do encontro (o jogo novo já começa com um petisco de cenoura).
func _stock(pack: int, snack: int) -> void:
	for item: String in ["picnic_pack", "carrot_snack"]:
		_inv().remove(item, _inv().count(item))
	if pack > 0:
		_inv().add("picnic_pack", pack)
	if snack > 0:
		_inv().add("carrot_snack", snack)


func _item_total() -> int:
	var total := 0
	for key: String in _inv().counts:
		total += int(_inv().counts[key])
	return total


func _meeting() -> void:
	_fresh()
	_festival_done()
	check(str(state.call("meeting_error", FEST)).begins_with("Disponível em"), "logo após a festa: espera 24 h (%s)" % state.call("meeting_error", FEST))
	var xp_mark: int = state.get("xp")
	var coins: int = state.get("coins")
	check(str(state.call("gather_project", FEST)) != "" and gathered.is_empty(), "antes de 24 h não acontece")
	check(int(state.get("xp")) == xp_mark, "sem XP antes da hora")
	state.call("dev_advance_time", 23.0 * 3600.0)
	check(str(state.call("meeting_error", FEST)).begins_with("Disponível em"), "23 h: ainda não")
	state.call("dev_advance_time", 2.0 * 3600.0)
	check(str(state.call("meeting_error", FEST)).begins_with("Falta"), "25 h sem material: pede o que falta (%s)" % state.call("meeting_error", FEST))
	_stock(0, 0)
	var before: Dictionary = _inv().counts.duplicate()
	check(str(state.call("gather_project", FEST)) != "" and _inv().counts == before, "falta de material não consome")
	_stock(1, 1)
	check(str(state.call("meeting_error", FEST)).begins_with("Falta") and _inv().count("picnic_pack") == 1, "um petisco a menos não consome")
	_stock(1, 2)
	# Tiro indisponível.
	state.call("set_sleeping", true)
	check(str(state.call("gather_project", FEST)) != "" and _inv().count("picnic_pack") == 1 and _inv().count("carrot_snack") == 2, "dormindo: nada consumido")
	state.call("set_sleeping", false)
	check(state.call("gather_project", FEST) == "", "encontro confirmado")
	check(_inv().count("picnic_pack") == 0 and _inv().count("carrot_snack") == 0, "consumiu o material")
	check(int(state.get("xp")) - xp_mark == 10 and state.get("coins") == coins, "XP 10; sem moedas")
	check(gathered == [[FEST, 1]], "evento do ciclo 1: %s" % str(gathered))
	check(state.get("economy").granted.has("project_gather:%s:1" % FEST), "prêmio com identidade do ciclo")
	check(str(state.call("meeting_error", FEST)).begins_with("Disponível em"), "novo ciclo espera outras 24 h")
	_reload()
	check(str(state.call("meeting_error", FEST)).begins_with("Disponível em"), "reload no ciclo mantém a espera")
	check(state.call("project_completed", FEST) and state.get("projects").cycle_count(FEST) == 1, "festa permanece e o ciclo está salvo")
	state.call("dev_advance_time", 25.0 * 3600.0)
	_stock(1, 2)
	xp_mark = state.get("xp")
	check(state.call("gather_project", FEST) == "" and int(state.get("xp")) - xp_mark == 10 and gathered.size() == 2 and gathered[1] == [FEST, 2], "segundo ciclo, com identidade própria")
	check(state.get("economy").granted.has("project_gather:%s:2" % FEST), "recibo do ciclo 2")
	check(state.get("progress").stat("project_gather:" + FEST) == 2, "contador de ciclos")


func _meeting_edges() -> void:
	# Passeio: Tiro indisponível. Obra sem encontro. Festa não concluída.
	_fresh()
	_festival_done()
	state.call("dev_advance_time", 30.0 * 3600.0)
	_stock(1, 2)
	check(str(state.call("meeting_error", FEST)) == "", "pronto para o encontro")
	var dog: Object = state.get("dog")
	dog.set("energy", 100) if dog.get("energy") != null else null
	if state.call("start_walk", "park_loop") == "":
		check(state.call("walking") and str(state.call("meeting_error", FEST)) != "", "passeando: Tiro indisponível, nada consumido")
		check(str(state.call("gather_project", FEST)) != "" and _inv().count("picnic_pack") == 1, "passeando: não confirma")
		state.call("cancel_walk")
	else:
		check(false, "não consegui iniciar o passeio para o teste")
	check(str(state.call("gather_project", BENCH)) != "", "banco não tem encontro")
	_fresh()
	check(str(state.call("gather_project", FEST)) != "", "sem festa, sem encontro")
	_fresh()
	_festival_done()
	var entry: Dictionary = state.get("projects").projects[FEST]
	check(float(entry.completed_at) > 0.0, "festa registra a hora da conclusão")
	# Save na última entrega: a conclusão e o prêmio saem juntos.
	_fresh()
	_before_festival()
	state.call("dev_grant_upgrade", "stall_3")
	state.set("coins", 500)
	state.call("start_project", FEST)
	var phases: Array = database.project(FEST).phases
	for index: int in phases.size() - 1:
		for item: String in phases[index].items:
			_inv().add(item, int(phases[index].items[item]))
			state.call("contribute_project", FEST, item, int(phases[index].items[item]))
	var last: Dictionary = phases[phases.size() - 1].items
	var keys: Array = last.keys()
	for k: int in keys.size():
		_inv().add(keys[k], int(last[keys[k]]))
		if k == keys.size() - 1:
			_reload()  # salva antes da última entrega
		state.call("contribute_project", FEST, keys[k], int(last[keys[k]]))
	check(state.call("project_completed", FEST) and _progress().collection.has(RIBBON), "save antes da última entrega: conclui e premia")
	var xp_mark: int = state.get("xp")
	_reload()
	check(int(state.get("xp")) == xp_mark and state.get("economy").granted.has("project:" + FEST), "recarregar não paga duas vezes")


func _scene_and_ui() -> void:
	_fresh()
	_festival_done()
	state.call("dev_advance_time", 25.0 * 3600.0)
	_stock(1, 2)
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	var host := Control.new()
	host.size = Vector2(360, 780)
	root.add_child(host)
	var panel: Control = load("res://scripts/ui/project_ui.gd").call("panel", FEST)
	host.add_child(panel)
	panel.size = Vector2(360, 700)
	await create_timer(0.2).timeout
	check(panel.find_child("GatheringCard", true, false) != null and panel.find_child("GatherProject", true, false) != null, "painel da festa pronta mostra o Encontro")
	check(panel.get_combined_minimum_size().x <= 360.0, "painel cabe em 360 px")
	var primaries := 0
	for node in panel.find_children("*", "Button", true, false):
		if (node as Button).theme_type_variation == &"PrimaryButton":
			primaries += 1
	check(primaries <= 1, "um botão principal por painel (%d)" % primaries)
	(panel.find_child("GatherProject", true, false) as Button).pressed.emit()
	await create_timer(0.2).timeout
	check(gathered.size() == 1, "botão confirma o encontro")
	host.queue_free()
	# Sala: festa pronta, com o Tiro indo participar.
	main.call("show_screen", &"map")
	main.call("_on_world_requested", "village", "")
	await create_timer(3.0).timeout
	var room := main.find_child("World_village", true, false)
	check(room != null, "sala da Vila")
	if room != null:
		var sprite := room.find_child("community_festival", true, false) as Sprite2D
		check(sprite != null and sprite.visible and sprite.texture.resource_path.ends_with("festival_gifts.png"), "festa pronta desenhada na Vila")
		var approach: Vector2 = sprite.get_meta("approach")
		var near: Vector2 = room.call("nearest_floor_point", approach)
		check(near.distance_to(approach) <= 12.0, "ponto de uso é chão livre (a %.1f px)" % near.distance_to(approach))
		var start: Vector2 = room.call("nearest_floor_point", room.call("_point", "dog_start"))
		check((room.call("find_path", start, near) as Array).size() > 0, "há caminho até a festa")
	main.queue_free()
