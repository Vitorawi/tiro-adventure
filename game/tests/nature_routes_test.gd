extends SceneTree
## Etapa 11 do plano de economia: aprender uma rota × ganhar mais vagas.
## Cobre: tabela 02 E (tempo, saída, XP local por rota), patamares 0/24/120/360 e vagas 1/2/2/3,
## tokens (cobre/segunda vaga no 2, madeira dura/cristal no 3, terceira vaga no 4), piso legado,
## XP uma vez só (erro/cancelado não paga), snapshot antigo, route_id opcional validado,
## escolha de rota só na sessão (NatureUi/StationTray), pomar sem XP local e capacidade com três rotas.
## --headless --path game -s res://tests/nature_routes_test.gd

const T0 := 1791936000.0

## rota -> [segundos, saída, XP local]
const TABLE := {
	"lane": [120, {"wood": 2}, 2],
	"pebbles": [120, {"stone": 2}, 2],
	"trail": [600, {"wood": 4, "stone": 3}, 8],
	"quarry": [600, {"stone": 6}, 8],
	"woodcutting": [900, {"wood": 8}, 12],
	"timber": [3600, {"wood": 8, "hardwood": 3}, 35],
	"copper_vein": [1200, {"stone": 3, "copper": 3}, 16],
	"deep_quarry": [3600, {"stone": 8, "copper": 5}, 35],
	"crystal_cave": [2400, {"crystal": 2, "copper": 2}, 26],
	"crystal_deep": [7200, {"crystal": 5, "copper": 4}, 60],
	"meadow": [600, {"fiber": 4, "wood": 2}, 8],
	"reeds": [3600, {"fiber": 10, "wood": 3}, 35],
}

var failures := 0
var state: Node
var db: Node
var ui: Script


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("NATUREZA 11: " + message)


func _p() -> RefCounted:
	return state.get("progress")


func _inv(id: String) -> int:
	return int(state.get("inventory").count(id))


func _xp(site: String) -> int:
	return int(_p().nature_xp.get(site, 0))


## Save novo com os três locais abertos (compra normal), pilha sem limite (o limite tem teste próprio).
func _fresh(unlimited: bool = true) -> void:
	state.set("test_time", T0)
	state.set("unlimited_storage", unlimited)
	state.call("reset")
	state.get("inventory").counts.clear()
	state.call("dev_jump_to_chapter", 4)
	state.call("dev_add_coins", 4000)
	for id in ["forest_open", "cave_open", "meadow_open"]:
		check(state.call("buy_upgrade", id) == "", "abre " + id)
	ui.call("clear_choices")


## Coloca o local no XP dado e sincroniza as ampliações como o jogo faz ao ganhar XP.
func _set_xp(site: String, xp: int) -> void:
	_fresh()
	_p().nature_xp[site] = xp
	_p().sync_nature_tokens(site)


func _site_of(route: String) -> String:
	return str(db.call("gathering_site", route))


func _run() -> void:
	Motion.reduced = true
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	ui = load("res://scripts/ui/nature_ui.gd")

	# --- Tabela 02 E nos dados ------------------------------------------------------
	for id: String in TABLE:
		var route: Dictionary = db.progression.activities[id]
		check(int(route.seconds) == int(TABLE[id][0]), id + ": tempo")
		var items: Dictionary = TABLE[id][1]
		var got: Dictionary = route.rewards.get("items", {})
		check(got.size() == items.size(), id + ": mesmos itens")
		for item: String in items:
			check(int(got.get(item, -1)) == int(items[item]), "%s: %s ×%d" % [id, item, int(items[item])])
		check(int(route.nature_xp) == int(TABLE[id][2]), id + ": XP local")
		check(not (route.rewards.get("skill_xp", {}) as Dictionary).is_empty(), id + ": XP de atributo continua (fora desta etapa)")
	var orchard: Dictionary = db.progression.activities.orchard_harvest
	check(int(orchard.seconds) == 3600 and int(orchard.rewards.items.apple) == 8 and not orchard.has("nature_xp"), "pomar: 1 h, 8 maçãs, sem XP local")
	check(db.progression.activities.woodcutting.requirements.owned == ["forest_open"], "woodcutting abre com o Bosque (sem nível 2)")
	check(int(db.progression.activities.timber.get("seconds")) > int(db.progression.activities.woodcutting.seconds), "longa fica depois da média")

	# --- Patamares, vagas e tokens --------------------------------------------------
	var steps := [[0, 1, 1], [23, 1, 1], [24, 2, 2], [119, 2, 2], [120, 3, 2], [359, 3, 2], [360, 4, 3], [900, 4, 3]]
	for site: String in ["trees", "rocks", "fibers"]:
		for step: Array in steps:
			_set_xp(site, int(step[0]))
			check(_p().nature_level(site) == int(step[1]), "%s: XP %d = nível %d" % [site, int(step[0]), int(step[1])])
			check(state.call("gathering_slots", site) == int(step[2]), "%s: XP %d = %d vagas" % [site, int(step[0]), int(step[2])])
		var config: Dictionary = db.progression.nature_sites[site]
		_set_xp(site, 24)
		check(_p().has_upgrade(config.level_upgrades[1]) and _p().has_upgrade(config.slot_upgrades[0]), site + ": nível 2 libera o token do nível e da vaga 2")
		check(not _p().has_upgrade(config.level_upgrades[2]) and not _p().has_upgrade(config.slot_upgrades[1]), site + ": nível 2 ainda sem o 3")
		_set_xp(site, 120)
		check(_p().has_upgrade(config.level_upgrades[2]) and not _p().has_upgrade(config.slot_upgrades[1]), site + ": nível 3 libera o material, mas não a vaga 3")
		_set_xp(site, 360)
		check(_p().has_upgrade(config.slot_upgrades[1]), site + ": nível 4 libera a vaga 3")
	# Materiais por patamar: cobre 2, madeira dura e cristal 3.
	_set_xp("rocks", 23)
	check(state.call("activity_error", "copper_vein") != "" and state.call("activity_error", "crystal_cave") != "", "Caverna 1: cobre e cristal fechados")
	_set_xp("rocks", 24)
	check(state.call("activity_error", "copper_vein") == "" and state.call("activity_error", "deep_quarry") == "" and state.call("activity_error", "crystal_cave") != "", "Caverna 2: cobre aberto, cristal ainda não")
	_set_xp("rocks", 120)
	check(state.call("activity_error", "crystal_cave") == "" and state.call("gathering_slots", "rocks") == 2, "Caverna 3: cristal aberto, ainda duas vagas")
	_set_xp("trees", 119)
	check(state.call("activity_error", "timber") != "", "Bosque 2: sem madeira dura")
	_set_xp("trees", 120)
	check(state.call("activity_error", "timber") == "", "Bosque 3: madeira dura")
	_set_xp("fibers", 23)
	check(state.call("activity_error", "reeds") != "", "Prado 1: sem juncos")
	_set_xp("fibers", 24)
	check(state.call("activity_error", "reeds") == "", "Prado 2: juncos abertos")

	# --- XP local por rota: concedido uma vez, só ao recolher ----------------------
	for id: String in TABLE:
		var site := _site_of(id)
		_fresh()
		# Patamares que a rota exige, sem XP (tokens de uso gratuitos).
		for token: String in db.progression.activities[id].requirements.get("owned", []):
			_p().owned[token] = true
		_p().owned["trees_slot_2"] = true
		var before_xp := _xp(site)
		var error: String = state.call("start_gathering", site, 0, id, "")
		check(error == "", id + ": começa (" + error + ")")
		check(_xp(site) == before_xp, id + ": iniciar não dá XP")
		check(state.call("collect_gathering", site, 0) != "", id + ": ainda não terminou")
		check(_xp(site) == before_xp, id + ": recolher cedo não dá XP")
		state.call("dev_advance_time", float(TABLE[id][0]))
		check(state.call("collect_gathering", site, 0) == "", id + ": recolhe")
		check(_xp(site) == before_xp + int(TABLE[id][2]), "%s: +%d XP local" % [id, int(TABLE[id][2])])
		for item: String in TABLE[id][1]:
			check(_inv(item) == int(TABLE[id][1][item]), "%s: recebeu %s" % [id, item])
		check(state.call("collect_gathering", site, 0) != "" and _xp(site) == before_xp + int(TABLE[id][2]), id + ": segunda coleta não repete XP")

	# --- Erros não concedem XP nem ocupam vaga -------------------------------------
	_fresh()
	var snap: Dictionary = state.call("to_dict").duplicate(true)
	check(state.call("start_gathering", "trees", 0, "timber", "") != "", "madeira dura bloqueada no nível 1")
	check(state.call("start_gathering", "trees", 0, "quarry", "") != "", "pedreira não é do Bosque")
	check(state.call("start_gathering", "trees", 0, "deep_quarry", "wood") != "", "veio profundo de outro local")
	check(state.call("start_gathering", "trees", 0, "meadow", "wood") != "", "fibras não valem para a madeira do Bosque")
	check(state.call("start_gathering", "trees", 0, "woodcutting", "hardwood") != "", "rota que não rende o material pedido")
	check(state.call("start_gathering", "trees", 0, "invalida", "wood") != "", "rota desconhecida")
	check(state.call("start_gathering", "trees", 1, "lane", "wood") != "", "vaga fechada")
	check(state.call("start_next_gathering", "rocks", "copper_vein", "copper") != "", "cobre fechado no nível 1")
	check(state.call("to_dict") == snap, "nenhum erro mexe no estado")
	check(not ui.call("choose_route", "wood", "quarry") and not ui.call("choose_route", "wood", "timber") and not ui.call("choose_route", "copper", "copper_vein"), "escolha recusa rota de outro material ou bloqueada")
	check(int(ui.call("choice_count")) == 0, "escolha recusada não fica guardada")

	# --- route_id opcional: sem rota, vale a elegível mais curta -------------------
	_fresh()
	check(state.call("default_gathering_route", "wood") == "lane", "padrão da madeira = a mais curta (lane)")
	check(state.call("start_gathering", "trees", 0, "", "wood") == "" and state.call("gathering_entry", "trees", 0).id == "lane", "sem route_id começa a rota padrão")
	check(state.call("start_gathering", "trees", 0, "", "wood") != "", "vaga ocupada continua recusando")
	check(state.call("start_gathering", "trees", 0) != "", "sem rota e sem material: erro")
	_fresh()
	check(state.call("start_next_gathering", "trees", "", "hardwood") != "", "madeira dura sem rota pede o nível 3")
	_fresh()
	check(state.call("start_next_gathering", "rocks", "", "stone") == "" and state.call("gathering_entry", "rocks", 0).id == "pebbles", "pedra: padrão = pedrinhas (120 s)")

	# --- Cancelar: sem erro nem XP (passeio de rota global) ------------------------
	_fresh()
	_p().owned["orchard"] = true
	var xp_before: Dictionary = _p().nature_xp.duplicate(true)
	check(state.call("start_activity", "orchard_harvest") == "", "pomar começa")
	state.call("dev_advance_time", 3600)
	check(state.call("collect_activity") == "" and _inv("apple") == 8, "pomar: 8 maçãs em 1 h")
	check(_p().nature_xp == xp_before, "pomar não dá XP de um local inexistente")

	# --- Duas buscas longas × doze curtas ------------------------------------------
	_fresh()
	var long_seconds := 0
	for i in 2:
		check(state.call("start_next_gathering", "trees", "woodcutting", "wood") == "", "busca longa %d" % (i + 1))
		long_seconds += int(db.progression.activities.woodcutting.seconds)
		state.call("dev_advance_time", 900)
		state.call("collect_gathering_all", "trees")
		check(_p().nature_level("trees") == (1 if i == 0 else 2), "XP da busca longa %d" % (i + 1))
	check(_xp("trees") == 24 and _p().nature_level("trees") == 2 and _inv("wood") == 16, "duas buscas longas: 24 XP, nível 2, 16 madeiras")
	_fresh()
	var short_seconds := 0
	for i in 12:
		state.call("start_next_gathering", "trees", "lane", "wood")
		short_seconds += int(db.progression.activities.lane.seconds)
		state.call("dev_advance_time", 120)
		state.call("collect_gathering_all", "trees")
		check(_p().nature_level("trees") == (1 if i < 11 else 2), "lane %d" % (i + 1))
	check(_xp("trees") == 24 and _p().nature_level("trees") == 2 and _inv("wood") == 24, "doze curtas: mesmo patamar 2 e 24 madeiras")
	check(long_seconds == 1800 and short_seconds == 1440, "tempos próprios (30 min × 24 min)")
	# A escolha fica no que o jogador marcou: nada troca por conta própria.
	check(ui.call("choose_route", "wood", "woodcutting") and ui.call("best_route", "wood") == "woodcutting", "escolher a longa vale para o material")
	state.call("start_next_gathering", "trees", ui.call("best_route", "wood"), "wood")
	state.call("dev_advance_time", 900)
	state.call("collect_gathering_all", "trees")
	check(ui.call("best_route", "wood") == "woodcutting", "recolher não troca a preferência")
	ui.call("clear_choices")
	check(ui.call("best_route", "wood") == "lane", "sem escolha, o padrão volta a ser a mais curta")

	# --- Piso legado: vaga 3 + XP 90 mantém o acesso, sem cobrar de novo -----------
	_fresh()
	var coins_before: int = state.get("coins")
	var legacy: Dictionary = state.call("to_dict").duplicate(true)
	legacy.progression.nature_levels_version = 2
	legacy.progression.nature_xp = {"trees": 90, "rocks": 90, "fibers": 90}
	for token in ["forest_level_2", "forest_level_3", "trees_slot_2", "trees_slot_3", "cave_level_2", "cave_level_3", "rocks_slot_2", "rocks_slot_3"]:
		legacy.progression.owned[token] = true
	state.call("from_dict", legacy)
	check(_p().nature_level("trees") == 4 and state.call("gathering_slots", "trees") == 3, "Bosque antigo (vaga 3, XP 90) mantém as três vagas")
	check(_p().nature_level("rocks") == 4 and state.call("gathering_slots", "rocks") == 3, "Caverna antiga mantém as três vagas")
	check(state.call("activity_error", "timber") == "" and state.call("activity_error", "crystal_cave") == "", "madeira dura e cristal continuam abertos")
	check(_p().nature_level("fibers") == 2 and state.call("gathering_slots", "fibers") == 2, "Prado só com XP 90: nível 2, duas vagas (sem inventar XP)")
	check(_xp("trees") == 90 and _xp("fibers") == 90, "XP guardado não é alterado pela migração")
	check(state.get("coins") == coins_before, "migração não cobra moedas")
	var info: Dictionary = _p().nature_info("trees")
	check(info.level == 4 and info.max, "nível exibido não cai (4, máximo)")
	var again: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", again)
	check(state.call("to_dict") == again, "recarregar é idempotente")
	# Legado em nível 2 (token do nível 2 e XP baixo, ex.: machado antigo) continua no 2.
	_fresh()
	var low: Dictionary = state.call("to_dict").duplicate(true)
	low.progression.nature_levels_version = 2
	low.progression.nature_xp = {"trees": 10}
	low.progression.owned["forest_level_2"] = true
	state.call("from_dict", low)
	var low_info: Dictionary = _p().nature_info("trees")
	check(_p().nature_level("trees") == 2 and low_info.xp == 0 and low_info.remaining == 110, "token do nível 2 vale 2; a barra começa no zero e falta 110 até o 3")
	check(state.call("gathering_slots", "trees") == 2, "token do nível 2 mantém duas vagas")
	# Save sem versão de níveis: as ferramentas antigas viram os níveis pelos tokens.
	_fresh()
	var ancient: Dictionary = state.call("to_dict").duplicate(true)
	ancient.progression.erase("nature_levels_version")
	ancient.progression.nature_xp = {}
	ancient.progression.owned = {"axe_reinforced": true, "pickaxe_crystal": true, "sickle": true}
	state.call("from_dict", ancient)
	check(_p().nature_level("trees") == 3 and _p().nature_level("rocks") == 3 and _p().nature_level("fibers") == 2, "ferramentas antigas viram 3/3/2")

	# --- Snapshot velho mantém o lote antigo ---------------------------------------
	_fresh()
	var now_time: float = state.call("now")
	_p().gathering["trees"] = [{"id": "woodcutting", "resource": "wood", "started_at": now_time - 300.0, "ready_at": now_time - 1.0, "rewards": {"items": {"wood": 4}}, "player_xp": 5, "nature_xp": 10}]
	check(state.call("collect_gathering", "trees", 0) == "" and _inv("wood") == 4 and _xp("trees") == 10, "lote antigo: 4 madeiras e 10 XP, mesmo com a tabela nova")
	_p().gathering["trees"] = [{"id": "woodcutting", "resource": "wood", "started_at": now_time - 300.0, "ready_at": now_time - 1.0, "rewards": {"items": {"wood": 4}}}]
	var xp_trees := _xp("trees")
	check(state.call("collect_gathering", "trees", 0) == "" and _xp("trees") == xp_trees + 10, "lote sem XP guardado usa o valor antigo do local (10)")
	# Rota antiga sem ser da tabela: lote iniciado com a regra nova guarda o XP da rota.
	state.call("start_gathering", "trees", 0, "timber" if _p().has_upgrade("forest_level_3") else "woodcutting", "wood")
	check(int(state.call("gathering_entry", "trees", 0).nature_xp) == 12, "lote novo guarda o XP da rota escolhida")
	# Mudar a tabela depois não altera o que já está em andamento.
	var saved_xp: int = int(db.progression.activities.woodcutting.nature_xp)
	db.progression.activities.woodcutting.nature_xp = 99
	state.call("dev_advance_time", 900)
	var xp_snapshot := _xp("trees")
	state.call("collect_gathering", "trees", 0)
	check(_xp("trees") == xp_snapshot + 12, "tabela alterada depois não muda o lote em andamento")
	db.progression.activities.woodcutting.nature_xp = saved_xp

	# --- Três rotas simultâneas e capacidade ---------------------------------------
	_set_xp("trees", 360)
	state.set("unlimited_storage", false)
	state.get("inventory").counts.clear()
	var depot: String = state.call("storage_of", "wood")
	var cap: int = state.call("storage_capacity", depot)
	for i in 3:
		check(state.call("start_next_gathering", "trees", "woodcutting", "wood") == "", "três buscas ao mesmo tempo %d" % (i + 1))
	state.call("dev_advance_time", 900)
	check(state.call("gathering_ready_count", "trees") == 3, "as três terminam juntas")
	var xp_full := _xp("trees")
	state.call("collect_gathering_all", "trees")
	check(_inv("wood") <= cap, "a pilha nunca passa da capacidade (%d)" % cap)
	if cap < 24:
		check(state.call("gathering_ready_count", "trees") >= 1, "o lote que não cabe fica pronto no mundo")
		check(_xp("trees") < xp_full + 36, "lote que não coube não paga XP")
		var pending_before: int = state.call("gathering_ready_count", "trees")
		check(state.call("collect_gathering", "trees", 2) != "" or state.call("gathering_ready_count", "trees") == 0, "sem espaço: erro claro, nada se perde")
		state.get("inventory").counts["wood"] = 0
		check(state.call("collect_gathering_all", "trees") == "" or pending_before == 0, "com espaço, recolhe o que ficou")
	check(state.call("gathering_slots", "trees") == 3, "três vagas só no nível 4")
	_set_xp("trees", 120)
	check(state.call("start_next_gathering", "trees", "timber", "hardwood") == "" and state.call("start_next_gathering", "trees", "timber", "hardwood") == "" and state.call("start_next_gathering", "trees", "timber", "hardwood") != "", "nível 3: madeira dura em duas vagas, a terceira não existe")

	# --- Interface: escolha explícita de rota na bandeja ---------------------------
	_fresh()
	var tray: Script = load("res://scripts/ui/station_tray.gd")
	var detail: Control = tray.call("material_detail", "trees", "wood")
	root.add_child(detail)
	var choice := detail.find_child("RouteChoice_wood", true, false)
	check(choice != null, "bandeja de madeira mostra a escolha de rota")
	check(detail.find_child("NotebookTab_lane", true, false) != null and detail.find_child("NotebookTab_woodcutting", true, false) != null, "duas rotas elegíveis: curta e longa")
	check(not _p().has_upgrade("forest_level_2"), "sem nível 2 a longa já está disponível")
	var before_choice: Dictionary = state.call("to_dict").duplicate(true)
	(detail.find_child("NotebookTab_woodcutting", true, false) as Button).pressed.emit()
	check(ui.call("best_route", "wood") == "woodcutting", "tocar na rota guarda a escolha")
	check(state.call("to_dict") == before_choice and state.call("gathering_jobs", "trees").is_empty(), "escolher não inicia a busca nem altera o save")
	var action := detail.find_child("Material_wood", true, false) as Button
	check(action != null and not action.disabled, "Buscar continua no detalhe")
	var texts := _all_text(detail)
	check(texts.contains("15 min") and texts.contains("12 XP") and texts.contains("×8"), "detalhe mostra tempo, saída e XP da rota escolhida")
	action.pressed.emit()
	check(state.call("gathering_entry", "trees", 0).id == "woodcutting", "Buscar usa a rota escolhida")
	detail.queue_free()
	var stone_detail: Control = tray.call("material_detail", "rocks", "stone")
	root.add_child(stone_detail)
	check(stone_detail.find_child("NotebookTab_pebbles", true, false) != null and stone_detail.find_child("NotebookTab_quarry", true, false) != null and stone_detail.find_child("NotebookTab_deep_quarry", true, false) == null, "pedra mostra só as rotas que já valem")
	stone_detail.queue_free()
	var hardwood_detail: Control = tray.call("material_detail", "trees", "hardwood")
	root.add_child(hardwood_detail)
	check(hardwood_detail.find_child("RouteChoice_hardwood", true, false) == null and hardwood_detail.find_child("RequiredLevel_hardwood", true, false) != null, "uma só rota (e bloqueada): sem escolha, com cadeado")
	hardwood_detail.queue_free()
	# Vagas fechadas dizem o nível certo (2 e 4), não "nível 3" para a terceira.
	_fresh()
	var holder := HBoxContainer.new()
	root.add_child(holder)
	ui.call("slot", holder, "trees", 1)
	ui.call("slot", holder, "trees", 2)
	var slot_text := _all_text(holder)
	check(slot_text.contains("Nível 2") and slot_text.contains("Nível 4") and not slot_text.contains("Nível 3"), "vagas fechadas: segunda no nível 2, terceira no nível 4 (%s)" % slot_text)
	holder.queue_free()
	await process_frame

	print("NATURE ROUTES TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


## Texto de todos os rótulos e botões de uma árvore (para checar o que o jogador lê).
func _all_text(node: Node) -> String:
	var text := ""
	if node is Label:
		text += (node as Label).text + " "
	elif node is Button:
		text += (node as Button).text + " "
	for child in node.get_children():
		text += _all_text(child)
	return text
