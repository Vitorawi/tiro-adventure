extends SceneTree
## Etapa 21: Jardim da Vila e Piquenique da Praça (obras independentes, nas duas ordens).
## --headless --path game -s res://tests/garden_picnic_test.gd

var failures: int = 0
var checks: int = 0
var state: Node
var database: Node
var events: Node
var toasts: Array[String] = []
var completed_events: Array[String] = []
var used_events: Array = []

const GARDEN := "village_garden"
const PICNIC := "park_picnic"
const BENCH := "park_bench"


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("Jardim/Piquenique: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _inv() -> RefCounted:
	return state.get("inventory")


func _reload() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


func _fresh() -> void:
	state.call("reset")
	state.set("xp", 0)
	state.set("level", 1)
	for id: String in ["stove", "workbench", "fridge", "atelier", "chest", "silo", "warehouse"]:
		state.call("dev_grant_upgrade", id)
	toasts.clear()
	completed_events.clear()
	used_events.clear()
	state.call("dev_complete_quest", "atelier_open")


## Banco concluído do jeito legítimo (entrada + material entregue).
func _bench_done() -> void:
	state.set("coins", 150)
	check(state.call("start_project", BENCH) == "", "banco começa")
	_give_all(BENCH)
	check(state.call("project_completed", BENCH), "banco concluído")


func _give_all(id: String) -> void:
	for phase: Dictionary in database.project(id).phases:
		for item: String in phase.items:
			_inv().add(item, int(phase.items[item]))
		for item: String in phase.items:
			var error: String = state.call("contribute_project", id, item, int(phase.items[item]))
			check(error == "", "%s/%s ×%d: %s" % [id, item, int(phase.items[item]), error])


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	events = root.get_node("Events")
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	events.project_completed.connect(func(id: String, _result: Dictionary) -> void: completed_events.append(id))
	events.project_used.connect(func(id: String, first: bool) -> void: used_events.append([id, first]))
	_data_check()
	_gates()
	_both_orders()
	_independence_and_reload()
	_missing_material()
	_use()
	await _scene_and_ui()
	print("GARDEN PICNIC TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures, " (%d verificações)" % checks)
	quit(0 if failures == 0 else 1)


func _ints(items: Dictionary) -> Dictionary:
	var out := {}
	for key: String in items:
		out[key] = int(items[key])
	return out


func _data_check() -> void:
	check((database.project_problems() as Array).is_empty(), "catálogo sem problemas: %s" % str(database.project_problems()))
	var garden: Dictionary = database.project(GARDEN)
	var picnic: Dictionary = database.project(PICNIC)
	check(int(garden.start_coins) == 250 and int(picnic.start_coins) == 250, "entrada 250 moedas nas duas")
	check(garden.requirements == {"projects": [BENCH]} and picnic.requirements == {"projects": [BENCH]}, "só exigem o banco (um não exige o outro)")
	check(int(garden.rewards.pillars.brave) == 5 and int(picnic.rewards.pillars.brave) == 5 and garden.rewards.size() == 1 and picnic.rewards.size() == 1, "prêmio: Coragem 5")
	var g: Array = garden.phases
	check(g.size() == 3 and g[0].id == "beds" and g[1].id == "planting" and g[2].id == "opening", "fases do jardim")
	check(_ints(g[0].items) == {"plank": 4, "brick": 4} and _ints(g[1].items) == {"herbs": 8, "wood": 6} and _ints(g[2].items) == {"strawberry_juice": 3}, "material do jardim (tabela 07 E)")
	var p: Array = picnic.phases
	check(p.size() == 3 and p[0].id == "corner" and p[1].id == "basket" and p[2].id == "meeting", "fases do piquenique")
	check(_ints(p[0].items) == {"plank": 3, "fabric": 3} and _ints(p[1].items) == {"picnic_pack": 2, "cheese": 2} and _ints(p[2].items) == {"carrot_snack": 4, "strawberry_pop": 4}, "material do piquenique (tabela 07 E)")
	for id: String in [GARDEN, PICNIC]:
		var def: Dictionary = database.project(id)
		check(ResourceLoader.exists("res://assets/sprites/ui/icons/%s.png" % def.icon), id + ": ícone")
		check(str(def.get("pitch", "")) != "" and str(def.get("done_speech", "")) != "" and str(def.interaction.get("go_label", "")) != "", id + ": falas e rótulo do Ir")
		var folder := "village/garden_" if id == GARDEN else "park/picnic_"
		for phase: Dictionary in def.phases:
			check(ResourceLoader.exists("res://assets/sprites/areas/%s%s.png" % [folder, phase.visual_state]), "%s: arte %s" % [id, phase.id])
	check(garden.interaction.kind == "garden" and picnic.interaction.kind == "picnic", "interações próprias")
	# Lugares: no máximo quatro visíveis, serviços e compras preservados.
	for world_id: String in ["village", "park"]:
		var places: Dictionary = database.worlds[world_id].places
		var visible := places.values().filter(func(pl: Dictionary) -> bool: return not pl.get("hidden", false) and not str(pl.get("panel", "")).begins_with("travel"))
		check(visible.size() <= 4, "%s com %d lugares visíveis" % [world_id, visible.size()])
	var village: Dictionary = database.worlds.village.places
	check(village.community.panel == "community:village" and village.community.services == ["orders"], "Nossa vila agrupa as obras e as Encomendas")
	check(village.market.panel == "sell" and village.orders.panel == "orders" and village.stall.panel == "contracts" and village.atelier.panel == "station:atelier", "feira, encomendas, banca e ateliê preservados")
	check(village.garden.panel == "project:" + GARDEN and village.garden.get("hidden", false), "jardim: lugar escondido que o Ir alcança")
	check(database.worlds.park.places.picnic.panel == "project:" + PICNIC and database.worlds.park.places.picnic.get("hidden", false), "piquenique: lugar escondido que o Ir alcança")
	check(database.worlds.park.places.community.services == ["friends", "training"], "Nossa praça mantém Amigos e Treino")
	for id: String in [GARDEN, PICNIC]:
		var go: Dictionary = database.project(id).go
		check(database.worlds[go.world].places.has(go.place) and str(database.project(id).world) == str(go.world), id + ": go aponta para um lugar real do mundo da obra")
	# Os objetos de sala têm todas as chaves visuais da obra.
	for entry: Array in [["village", GARDEN], ["park", PICNIC]]:
		var found := false
		for obj: Dictionary in database.room(entry[0]).objects:
			if str(obj.get("project", "")) == entry[1]:
				found = true
				var sprites: Dictionary = obj.project_sprites
				check(sprites.has("ghost"), entry[1] + ": marcação inicial")
				for phase: Dictionary in database.project(entry[1]).phases:
					check(sprites.has(phase.visual_state) and ResourceLoader.exists(str(sprites[phase.visual_state])), "%s: sprite %s" % [entry[1], phase.visual_state])
				check(obj.has("approach") and obj.has("footprint") and obj.has("label"), entry[1] + ": ponto de uso, footprint e etiqueta")
		check(found, "%s: objeto na sala %s" % [entry[1], entry[0]])


func _gates() -> void:
	_fresh()
	for id: String in [GARDEN, PICNIC]:
		check(not state.call("project_available", id) and state.call("project_visual", id) == "", id + ": invisível sem o banco")
		check(str(state.call("project_error", id)) != "", id + ": não começa sem o banco")
	_bench_done()
	for id: String in [GARDEN, PICNIC]:
		check(state.call("project_available", id) and state.call("project_visual", id) == "ghost", id + ": marcação do lugar com o banco pronto")
	state.set("coins", 249)
	check(str(state.call("start_project", GARDEN)) != "" and int(state.get("coins")) == 249 and not state.call("project_started", GARDEN), "249 moedas: recusa sem cobrar")
	state.set("coins", 250)
	check(state.call("start_project", GARDEN) == "" and int(state.get("coins")) == 0, "jardim cobra 250 uma vez")
	check(state.call("start_project", GARDEN) != "" and int(state.get("coins")) == 0, "segunda tentativa não cobra")
	check(not state.call("project_started", PICNIC) and state.call("project_visual", PICNIC) == "ghost", "começar o jardim não inicia o piquenique")


func _both_orders() -> void:
	for order: Array in [[GARDEN, PICNIC], [PICNIC, GARDEN]]:
		_fresh()
		_bench_done()
		completed_events.clear()
		var brave_before := int(state.get("progress").stat("pillar:brave"))
		for id: String in order:
			state.set("coins", 250)
			check(state.call("start_project", id) == "", "%s começa (ordem %s)" % [id, str(order)])
			check(not state.call("project_completed", order[1] if id == order[0] else order[0]) or id == order[1], "a outra obra não avança sozinha")
			_give_all(id)
			check(state.call("project_completed", id), id + " concluída")
			check(int(state.get("coins")) == 0, id + ": prêmio não devolve a entrada")
		check(completed_events == [order[0], order[1]], "conclusões consecutivas em ordem: %s" % str(completed_events))
		check(int(state.get("progress").stat("pillar:brave")) > brave_before, "Coragem dos dois prêmios entrou")
		check(state.call("project_visual", GARDEN) == "opening" and state.call("project_visual", PICNIC) == "meeting", "cenas finais permanentes")
		_reload()
		check(state.call("project_completed", GARDEN) and state.call("project_completed", PICNIC), "reload preserva as duas conclusões")
		check(completed_events.size() == 2, "reload não repete o prêmio")


func _independence_and_reload() -> void:
	_fresh()
	_bench_done()
	state.set("coins", 500)
	check(state.call("start_project", GARDEN) == "" and state.call("start_project", PICNIC) == "", "os dois começam juntos")
	_inv().add("plank", 7)
	_inv().add("brick", 2)
	_inv().add("fabric", 1)
	check(state.call("contribute_project", GARDEN, "plank", 4) == "", "tábuas ao jardim")
	check(state.call("contribute_project", PICNIC, "plank", 3) == "", "tábuas ao piquenique")
	check(state.call("contribute_project", GARDEN, "brick", 2) == "", "tijolos ao jardim")
	check(state.call("contribute_project", PICNIC, "fabric", 1) == "", "tecido ao piquenique")
	var garden: Dictionary = state.call("project_stage", GARDEN)
	var picnic: Dictionary = state.call("project_stage", PICNIC)
	check(int(garden.given.plank) == 4 and int(garden.given.brick) == 2 and int(picnic.given.plank) == 3 and int(picnic.given.fabric) == 1, "contribuições separadas")
	check(state.call("contribute_project", GARDEN, "fabric", 1) != "", "material de outra obra não entra no jardim")
	_reload()
	garden = state.call("project_stage", GARDEN)
	picnic = state.call("project_stage", PICNIC)
	check(int(garden.given.plank) == 4 and int(garden.given.brick) == 2 and int(picnic.given.plank) == 3 and int(picnic.given.fabric) == 1, "reload preserva as duas contribuições")
	check(state.call("project_started", GARDEN) and state.call("project_started", PICNIC) and not state.call("project_completed", GARDEN), "reload preserva o estado")
	check(int(garden.total_progress) != int(picnic.total_progress) or float(garden.total_progress) != float(picnic.total_progress), "progressos independentes")


func _missing_material() -> void:
	_fresh()
	_bench_done()
	state.set("coins", 250)
	state.call("start_project", GARDEN)
	_inv().add("plank", 4)
	var plank_before: int = _inv().count("plank")
	check(state.call("contribute_project", GARDEN, "brick", 1) != "", "sem tijolo: recusa")
	check(state.call("contribute_project", GARDEN, "plank", 5) != "", "acima do pedido: recusa")
	check(state.call("contribute_project", GARDEN, "plank", 0) != "", "zero: recusa")
	check(_inv().count("plank") == plank_before, "recusa não consome")
	var sources: Array = database.item_sources("herbs")
	check(not sources.is_empty(), "ervas têm origem para o 'de onde vem?'")


func _use() -> void:
	_fresh()
	_bench_done()
	state.set("coins", 500)
	check(str(state.call("project_use_error", GARDEN)) != "", "obra não pronta não se usa")
	state.call("start_project", GARDEN)
	state.call("start_project", PICNIC)
	_give_all(GARDEN)
	_give_all(PICNIC)
	state.call("set_sleeping", true)
	check(state.call("project_completed", GARDEN) and state.call("project_completed", PICNIC), "dormindo: entrega e conclusão funcionam")
	check(str(state.call("project_use_error", GARDEN)) != "" and str(state.call("project_use_error", PICNIC)) != "", "dormindo: só o convite espera")
	state.call("set_sleeping", false)
	var xp_mark: int = state.get("xp")
	check(state.call("use_project", GARDEN) == "", "usar o jardim")
	check(state.get("progress").stat("project_use:" + GARDEN) == 1 and state.get("progress").stat("project_use:" + PICNIC) == 0, "primeiro uso conta só o jardim")
	check(state.call("use_project", GARDEN) == "" and state.get("progress").stat("project_use:" + GARDEN) == 1, "repetição é só visual")
	check(state.call("use_project", PICNIC) == "" and state.get("progress").stat("project_use:" + PICNIC) == 1, "primeiro uso do piquenique")
	check(used_events == [[GARDEN, true], [GARDEN, false], [PICNIC, true]], "eventos de uso: %s" % str(used_events))
	check(int(state.get("xp")) == xp_mark, "usar não dá XP")
	_reload()
	check(state.get("progress").stat("project_use:" + GARDEN) == 1 and state.call("use_project", PICNIC) == "" and state.get("progress").stat("project_use:" + PICNIC) == 1, "reload reconhece o uso anterior")


func _scene_and_ui() -> void:
	_fresh()
	_bench_done()
	state.set("coins", 500)
	state.call("start_project", GARDEN)
	state.call("start_project", PICNIC)
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.5).timeout
	# Painel com nome comprido em 360 px: o texto do título e das fases não pode estourar a largura.
	_give_phase(GARDEN, 0)
	_give_phase(GARDEN, 1)
	_give_phase(PICNIC, 0)
	_give_phase(PICNIC, 1)
	for id: String in [GARDEN, PICNIC]:
		var panel: Control = load("res://scripts/ui/project_ui.gd").call("panel", id)
		var host := Control.new()
		host.size = Vector2(360, 780)
		root.add_child(host)
		host.add_child(panel)
		panel.size = Vector2(360, 700)
		await create_timer(0.2).timeout
		check(panel.find_child("ProjectPhases", true, false) != null and panel.find_child("StartProject", true, false) == null, id + ": painel em andamento sem botão de começar")
		var deliver := panel.find_child("DeliverProject", true, false)
		check(deliver != null or panel.find_child("ProjectMissing", true, false) != null, id + ": entrega ou chip do que falta")
		var phases := panel.find_child("ProjectPhases", true, false) as Control
		check(phases.get_combined_minimum_size().x <= 340.0 and panel.get_combined_minimum_size().x <= 360.0, "%s: fases e painel cabem em 360 px (%d, %d)" % [id, int(phases.get_combined_minimum_size().x), int(panel.get_combined_minimum_size().x)])
		host.queue_free()
	# Volta ao começo das obras para a parte do mapa.
	_fresh()
	_bench_done()
	state.set("coins", 500)
	state.call("start_project", GARDEN)
	state.call("start_project", PICNIC)
	# Listas "Nossa praça"/"Nossa vila".
	var park_list: Control = load("res://scripts/ui/project_ui.gd").call("community", "park")
	var village_list: Control = load("res://scripts/ui/project_ui.gd").call("community", "village")
	root.add_child(park_list)
	root.add_child(village_list)
	await create_timer(0.2).timeout
	check(park_list.find_child("Project_" + PICNIC, true, false) != null and park_list.find_child("Project_" + BENCH, true, false) != null, "Nossa praça lista banco e piquenique")
	check(park_list.find_child("Project_" + GARDEN, true, false) == null, "Nossa praça não lista o jardim")
	check(village_list.find_child("Project_" + GARDEN, true, false) != null and village_list.find_child("Service_orders", true, false) != null, "Nossa vila lista o jardim e as Encomendas")
	park_list.queue_free()
	village_list.queue_free()
	# Salas: marcação, fases e navegação.
	main.call("show_screen", &"map")
	for entry: Array in [["village", "garden", GARDEN, "community_garden"], ["park", "picnic", PICNIC, "community_picnic"]]:
		main.call("_on_world_requested", entry[0], "")
		await create_timer(3.0).timeout
		var room := main.find_child("World_" + entry[0], true, false)
		check(room != null, "sala " + entry[0])
		if room == null:
			continue
		var sprite := room.find_child(entry[3], true, false) as Sprite2D
		check(sprite != null and sprite.visible and is_equal_approx(sprite.self_modulate.a, 0.5), entry[2] + ": marcação translúcida")
		var def: Dictionary = database.project(entry[2])
		var approach: Vector2 = sprite.get_meta("approach")
		var near: Vector2 = room.call("nearest_floor_point", approach)
		check(near.distance_to(approach) <= 12.0, "%s: ponto de uso é chão livre (a %.1f px)" % [entry[2], near.distance_to(approach)])
		var start: Vector2 = room.call("nearest_floor_point", room.call("_point", "dog_start"))
		check((room.call("find_path", start, near) as Array).size() > 0, entry[2] + ": há caminho até a obra")
		check(sprite.get_node("ProjectMarker").state == "buy" or sprite.get_node("ProjectMarker").state == "progress", entry[2] + ": balão da obra")
		var expected := [str(def.phases[0].visual_state), str(def.phases[1].visual_state), str(def.phases[2].visual_state)]
		var revision_before: int = room.get("navigation_revision")
		for index: int in 3:
			_give_phase(entry[2], index)
			await create_timer(0.3).timeout
			var path := str((room.find_child(entry[3], true, false) as Sprite2D).texture.resource_path)
			check(path.ends_with("_%s.png" % expected[index]), "%s: desenho da fase %d (%s)" % [entry[2], index + 1, path])
		check(int(room.get("navigation_revision")) > revision_before, entry[2] + ": navegação recalculada")
		check((room.find_child(entry[3], true, false) as Sprite2D).self_modulate.a == 1.0, entry[2] + ": obra pronta opaca")
	main.queue_free()


func _give_phase(id: String, index: int) -> void:
	var phase: Dictionary = database.project(id).phases[index]
	for item: String in phase.items:
		_inv().add(item, int(phase.items[item]))
		var error: String = state.call("contribute_project", id, item, int(phase.items[item]))
		check(error == "", "%s/%s: %s" % [id, item, error])
