extends SceneTree
## Etapa 20: Banco da Praça (primeiro projeto visível): dados, painel, mapa, fases, uso pelo Tiro, save no meio.
## --headless --path game -s res://tests/bench_test.gd

var failures: int = 0
var state: Node
var database: Node
var events: Node
var main: Control
var park: Control
var toasts: Array[String] = []


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Banco: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _inv() -> RefCounted:
	return state.get("inventory")


func _stat(key: String) -> int:
	return state.get("progress").stat(key)


func _reload() -> void:
	state.call("from_dict", JSON.parse_string(JSON.stringify(state.call("to_dict"))))


func _stage() -> Dictionary:
	return state.call("project_stage", "park_bench")


## Receita de verdade: cozinha, espera o tempo e recolhe.
func _make(recipe: String, times: int = 1) -> void:
	for i in times:
		var error: String = state.call("cook", recipe)
		check(error == "", "cook %s: %s" % [recipe, error])
		state.call("dev_advance_time", 4000.0)
		state.call("collect", str(database.recipes[recipe].station))


func _fresh() -> void:
	state.call("reset")
	state.set("xp", 0)
	state.set("level", 1)
	for id: String in ["stove", "workbench", "fridge", "atelier", "chest", "silo", "warehouse"]:
		state.call("dev_grant_upgrade", id)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	database = root.get_node("Database")
	events = root.get_node("Events")
	Motion.reduced = true
	events.toast_requested.connect(func(text: String) -> void: toasts.append(text))
	_data_check()
	_gate_check()
	_build_check()
	await _map_check()
	await _use_check()
	await _panel_check()
	print("BENCH TEST: " + ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(0 if failures == 0 else 1)


func _data_check() -> void:
	check((database.project_problems() as Array).is_empty(), "catálogo sem problemas: %s" % str(database.project_problems()))
	var def: Dictionary = database.project("park_bench")
	check(int(def.start_coins) == 150 and def.requirements == {"quests": ["atelier_open"]} and str(def.npc) == "lais" and str(def.world) == "park", "cabeçalho (tabela 07 E)")
	var phases: Array = def.phases
	check(phases.size() == 3 and phases[0].id == "base" and phases[1].id == "comfort" and phases[2].id == "welcome", "fases base/comfort/welcome")
	check(int(phases[0].items.plank) == 4 and int(phases[0].items.brick) == 2 and phases[0].items.size() == 2, "base: tábua 4 + tijolo 2")
	check(int(phases[1].items.fabric) == 2 and int(phases[1].items.braided_toy) == 1 and phases[1].items.size() == 2, "conforto: tecido 2 + brinquedo 1")
	check(int(phases[2].items.carrot_snack) == 3 and phases[2].items.size() == 1, "boas-vindas: lanche 3")
	check(int(def.rewards.pillars.brave) == 5 and int(def.rewards.get("coins", 0)) == 0 and not def.rewards.has("items"), "prêmio: Coragem 5 (sem devolver as moedas)")
	for phase: Dictionary in phases:
		check(not (def.phases as Array).is_empty() and ResourceLoader.exists("res://assets/sprites/areas/park/bench_%s.png" % phase.visual_state), "arte da fase " + str(phase.id))
	check(ResourceLoader.exists("res://assets/sprites/ui/icons/project_bench.png"), "ícone da obra")
	# No máximo quatro lugares visíveis na Praça, e todos os serviços seguem acessíveis.
	var places: Dictionary = database.worlds.park.places
	var visible := places.values().filter(func(p: Dictionary) -> bool: return not p.get("hidden", false) and not str(p.get("panel", "")).begins_with("travel"))
	check(visible.size() <= 4, "Praça com %d lugares visíveis" % visible.size())
	check(places.community.panel == "community" and not places.community.get("hidden", false), "Nossa praça visível")
	check(places.bench.panel == "project:park_bench" and places.bench.get("hidden", false), "banco: lugar escondido que o Ir alcança")
	check(places.friends.panel == "friends" and places.training.panel == "tricks" and places.walk.panel == "walks" and places.petshop.panel == "petshop", "serviços preservados")
	var room: Dictionary = database.room("park")
	var actions: Array[String] = []
	for obj: Dictionary in room.objects:
		actions.append(str(obj.get("action", "")))
	for zone: Dictionary in room.zones:
		actions.append(str(zone.get("action", "")))
	for action: String in ["place:sewing", "place:petshop", "place:walk", "place:friends", "place:training", "place:bench"]:
		check(action in actions, "a sala ainda tem " + action)
	var goal: Dictionary = database.project("park_bench").go
	check(goal.world == "park" and database.worlds.park.places.has(goal.place), "go aponta para um lugar real")


func _gate_check() -> void:
	_fresh()
	check(not state.call("project_available", "park_bench") and state.call("project_visual", "park_bench") == "", "sem o ateliê aberto a obra não existe")
	check(str(state.call("project_error", "park_bench")) != "", "começar recusa sem o requisito")
	state.call("dev_complete_quest", "atelier_open")
	check(state.call("project_available", "park_bench") and state.call("project_visual", "park_bench") == "ghost", "ateliê aberto: marcação do lugar")
	state.set("coins", 149)
	check(str(state.call("project_error", "park_bench")) == "Faltam 1 moedas", "149 moedas: faltam 1 (%s)" % state.call("project_error", "park_bench"))
	check(str(state.call("start_project", "park_bench")) != "" and int(state.get("coins")) == 149, "recusa sem cobrar")
	state.set("coins", 150)
	check(state.call("start_project", "park_bench") == "" and int(state.get("coins")) == 0, "começar cobra 150 uma vez")
	check(state.call("start_project", "park_bench") != "" and int(state.get("coins")) == 0, "segunda tentativa não cobra")


## Material por ações de verdade (receitas e relógio), entrega em partes, save no meio e conclusão.
func _build_check() -> void:
	_fresh()
	state.call("dev_complete_quest", "atelier_open")
	state.set("coins", 150)
	state.call("start_project", "park_bench")
	state.set("xp", 0)
	state.set("level", 1)
	var coins_before: int = state.get("coins")
	_inv().add("wood", 16)
	_inv().add("stone", 6)
	_inv().add("fiber", 9)
	_inv().add("carrot", 6)
	_make("plank", 4)
	_make("brick", 2)
	_make("fabric", 3)
	_make("cut_sticks")
	_make("braided_toy")
	_make("carrot_snack", 3)
	check(_inv().count("plank") == 4 and _inv().count("brick") == 2 and _inv().count("fabric") == 2 and _inv().count("braided_toy") == 1 and _inv().count("carrot_snack") >= 3, "materiais saíram das receitas: tábua %d tijolo %d tecido %d brinquedo %d lanche %d" % [_inv().count("plank"), _inv().count("brick"), _inv().count("fabric"), _inv().count("braided_toy"), _inv().count("carrot_snack")])
	check(str(state.call("contribute_project", "park_bench", "plank", 0)) != "" and str(state.call("contribute_project", "park_bench", "fabric", 1)) != "", "quantidade zero e item de outra fase são recusados")
	check(_inv().count("plank") == 4, "erro não consome")
	# Dois depósitos (materiais e baú/despensa) são lidos pela mesma entrega.
	check(state.call("contribute_project", "park_bench", "plank", 3) == "" and _inv().count("plank") == 1, "entrega parcial de tábuas")
	check(_stage().index == 0 and int(_stage().remaining.plank) == 1 and abs(float(_stage().progress) - 3.0 / 6.0) < 0.001, "fase 1 em andamento: 3 de 6")
	_reload()
	check(_stage().index == 0 and int(_stage().given.plank) == 3 and _inv().count("plank") == 1, "salvar e reabrir no meio mantém a entrega")
	check(state.call("contribute_project", "park_bench", "plank", 1) == "" and state.call("contribute_project", "park_bench", "brick", 2) == "", "termina a base")
	check(_stage().index == 1 and state.call("project_visual", "park_bench") == "base", "base entregue: desenho da base")
	check(state.call("contribute_project", "park_bench", "fabric", 2) == "" and state.call("contribute_project", "park_bench", "braided_toy", 1) == "", "conforto")
	check(_stage().index == 2 and state.call("project_visual", "park_bench") == "comfort", "conforto entregue")
	# Estoque cheio não bloqueia a conclusão (o prêmio é só XP).
	for i in 40:
		_inv().add("wood", 5)
	var brave_before := _stat("pillar:brave")
	check(state.call("contribute_project", "park_bench", "carrot_snack", 3) == "", "última entrega")
	check(state.call("project_completed", "park_bench") and state.call("project_visual", "park_bench") == "welcome", "obra concluída e desenho final")
	check(_stat("projects") == 1 and _stat("project_start") == 1, "contadores")
	check(int(state.get("coins")) == coins_before, "moedas não voltam (nem saem) na conclusão")
	check(_stat("pillar:brave") > brave_before, "Coragem paga ao concluir")
	var brave_after := _stat("pillar:brave")
	_reload()
	check(state.call("project_completed", "park_bench") and _stat("pillar:brave") == brave_after, "reabrir não paga de novo")
	check(state.call("complete_project", "park_bench") == "" and _stat("pillar:brave") == brave_after, "complete_project idempotente")


func _open_park() -> void:
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)


func _map_check() -> void:
	_fresh()
	state.get("progress").seen["intro"] = true
	for id: String in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order", "nina_pipoca"]:
		state.get("progress").claimed_quests[id] = true
	state.call("dev_complete_quest", "atelier_open")
	state.call("_mark_all_seen")
	state.set("coins", 1000)
	_open_park()
	for i in 4: await process_frame
	main.call("_on_world_requested", "park", "")
	main.call("show_screen", &"map")
	for i in 6: await process_frame
	for member: String in ["_celebration", "_welcome", "_walk_result"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	park = main.find_child("World_park", true, false)
	var bench: Sprite2D = park.find_child("community_bench", true, false)
	check(bench != null and bench.visible and bench.self_modulate.a < 1.0, "marcação do banco aparece (translúcida) antes de começar")
	check(bench.get_node("ProjectMarker").state == "buy" and bench.get_node("ProjectMarker").caption == "150", "balão com a entrada de 150")
	# Alcançável: o ponto de uso é chão livre e há caminho a partir do início do Tiro.
	var approach: Vector2 = bench.get_meta("approach")
	var near: Vector2 = park.call("nearest_floor_point", approach)
	check(near.distance_to(approach) <= 12.0, "ponto de uso é chão livre (a %.1f px)" % near.distance_to(approach))
	var start: Vector2 = park.call("nearest_floor_point", park.call("_point", "dog_start"))
	check((park.call("find_path", start, near) as Array).size() > 0, "há caminho até o banco")
	check(not Geometry2D.is_point_in_polygon(near, PackedVector2Array([Vector2(380, 274), Vector2(402, 264), Vector2(424, 274), Vector2(402, 286)])), "o ponto de uso está fora do footprint")
	# Toque em três zooms abre o painel da obra.
	for zoom: float in [0.85, 1.4, 2.0]:
		park.call("_zoom_at", park.size / 2.0, zoom)
		var screen: Vector2 = park.call("world_to_screen", bench.position - Vector2(0, 14))
		var panels := [0]
		var hook := func(title: String, _content: Control) -> void:
			if title == "Banco da Praça":
				panels[0] += 1
		events.sheet_requested.connect(hook)
		park.call("_on_tap_released", screen)
		events.sheet_requested.disconnect(hook)
		check(panels[0] == 1 or not Rect2(Vector2.ZERO, park.size).has_point(screen), "toque no banco (zoom %.2f) abre a obra" % zoom)
	park.call("recenter")
	# Fases no mapa.
	state.call("start_project", "park_bench")
	state.set("xp", 0)
	for item: String in ["plank", "brick"]:
		_inv().add(item, 10)
	for item: String in ["plank:4", "brick:2"]:
		state.call("contribute_project", "park_bench", item.get_slice(":", 0), int(item.get_slice(":", 1)))
	await process_frame
	check(bench.texture.resource_path.ends_with("bench_base.png") and is_equal_approx(bench.self_modulate.a, 1.0), "fase 1: banco de base, opaco")
	for item: String in ["fabric", "braided_toy"]:
		_inv().add(item, 5)
	state.call("contribute_project", "park_bench", "fabric", 2)
	state.call("contribute_project", "park_bench", "braided_toy", 1)
	await process_frame
	check(bench.texture.resource_path.ends_with("bench_comfort.png"), "fase 2: com almofada")
	_inv().add("carrot_snack", 5)
	state.call("contribute_project", "park_bench", "carrot_snack", 3)
	await process_frame
	check(bench.texture.resource_path.ends_with("bench_welcome.png") and not bench.get_node("ProjectMarker").visible, "obra pronta: banco final, sem balão")
	check(bench.get_meta("project") == "park_bench", "objeto da obra")


func _use_check() -> void:
	var bench: Sprite2D = park.find_child("community_bench", true, false)
	var dog: Node = park.get("_dog")
	check(dog != null, "o Tiro está na Praça")
	check(_stat("project_use:park_bench") == 0, "nenhum uso ainda")
	# Dormindo: dica amigável, sem consumir a primeira vez.
	state.call("set_sleeping", true)
	toasts.clear()
	var screen: Vector2 = park.call("world_to_screen", bench.position - Vector2(0, 14))
	park.call("_on_tap_released", screen)
	check(not toasts.is_empty() and "dormindo" in toasts[0] and _stat("project_use:park_bench") == 0 and not bool(state.get("projects").entry("park_bench").used_once), "dormindo: dica e nada consumido (%s)" % str(toasts))
	state.call("set_sleeping", false)
	# Passeando: o Tiro some da sala e o toque só avisa.
	state.call("start_walk", "park_loop")
	await process_frame
	await process_frame
	toasts.clear()
	park.call("_on_tap_released", screen)
	check(not toasts.is_empty() and _stat("project_use:park_bench") == 0, "passeando: aviso sem consumir (%s)" % str(toasts))
	state.call("dev_finish_timers")
	state.call("return_due_walk")
	state.call("claim_walk_baggage")
	for i in 6: await process_frame
	dog = park.get("_dog")
	check(dog != null, "o Tiro volta do passeio")
	var energy_before: float = state.get("dog").get_need("energy", state.call("now"))
	var coins_before: int = state.get("coins")
	var xp_before: int = state.get("xp")
	park.call("_on_tap_released", screen)
	var waited := 0.0
	while _stat("project_use:park_bench") == 0 and waited < 30.0:
		await create_timer(0.25).timeout
		waited += 0.25
	check(_stat("project_use:park_bench") == 1, "o uso conta quando a reação começa (esperou %.1f s; Tiro em %s, destino %s, reação %s, última %s, visível %s)" % [waited, str(dog.position), str(bench.get_meta("approach")), str(dog.get("_reaction")), str(dog.get_meta("last_reaction", "")), str(park.is_visible_in_tree())])
	check(dog.position.distance_to(bench.get_meta("approach")) < 40.0, "o Tiro foi até o banco")
	await create_timer(4.0).timeout
	park.call("_on_tap_released", screen)
	await create_timer(1.0).timeout
	var again := 0.0
	while again < 12.0:
		await create_timer(0.5).timeout
		again += 0.5
	check(_stat("project_use:park_bench") == 1, "repetir não conta de novo")
	check(int(state.get("coins")) == coins_before and int(state.get("xp")) == xp_before, "repetir não paga moedas nem XP")
	check(absf(float(state.get("dog").get_need("energy", state.call("now"))) - energy_before) < 3.0, "necessidades intactas")


func _panel_check() -> void:
	_fresh()
	state.call("dev_complete_quest", "atelier_open")
	state.set("coins", 400)
	var panel: Control = load("res://scripts/ui/project_ui.gd").call("panel", "park_bench")
	root.add_child(panel)
	await process_frame
	await process_frame
	check(panel.find_child("StartProject", true, false) != null, "antes de começar: um botão Começar por moedas")
	check("150" in (panel.find_child("StartProject", true, false) as Button).text, "o botão diz a taxa (%s)" % (panel.find_child("StartProject", true, false) as Button).text)
	check(panel.find_child("DeliverProject", true, false) == null, "sem entregar antes de começar")
	(panel.find_child("StartProject", true, false) as Button).pressed.emit()
	for i in 4: await process_frame
	check(state.call("project_started", "park_bench") and int(state.get("coins")) == 250, "tocar começa e cobra")
	check(panel.find_child("StartProject", true, false) == null and panel.find_child("ProjectItem_plank", true, false) != null, "painel passa à entrega, com itens tocáveis")
	check(panel.find_child("ProjectMissing", true, false) != null, "sem material: mostra o que falta e de onde vem")
	_inv().add("plank", 4)
	_inv().add("brick", 1)
	await create_timer(1.3).timeout
	var primary_count := 0
	for node: Node in panel.find_children("*", "Button", true, false):
		if (node as Button).theme_type_variation == &"PrimaryButton":
			primary_count += 1
	check(primary_count == 1, "um único botão primário (%d)" % primary_count)
	check((panel.find_child("DeliverProject", true, false) as Button).text.begins_with("Entregar ×1"), "quantidade 1 por padrão (%s)" % (panel.find_child("DeliverProject", true, false) as Button).text)
	(panel.find_child("Qty_all", true, false) as Button).pressed.emit()
	for i in 4: await process_frame
	check((panel.find_child("DeliverProject", true, false) as Button).text.begins_with("Entregar ×4"), "Tudo = o que falta e eu tenho")
	(panel.find_child("DeliverProject", true, false) as Button).pressed.emit()
	for i in 4: await process_frame
	check(int(_stage().given.plank) == 4 and _inv().count("plank") == 0, "entrega feita; painel continua aberto")
	check(panel.is_inside_tree() and panel.find_child("ProjectItem_brick", true, false) != null, "painel permanece com o tijolo selecionado")
	check((panel.find_child("DeliverProject", true, false) as Button).text.contains("Tijolo") or (panel.find_child("DeliverProject", true, false) as Button).text.contains("brick"), "seleção passou ao item que falta (%s)" % (panel.find_child("DeliverProject", true, false) as Button).text)
	panel.queue_free()
	var community: Control = load("res://scripts/ui/project_ui.gd").call("community")
	root.add_child(community)
	await process_frame
	await process_frame
	check(community.find_child("Project_park_bench", true, false) != null, "Nossa praça lista a obra")
	community.queue_free()
