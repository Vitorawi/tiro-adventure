extends SceneTree
## Nível de cozinheiro com 9 habilidades: pontos (prato, prato novo, estrelas), subida de nível com sinal, cada
## habilidade (fila 3/4, fogo esperto, prévia, mão leve, economia, panelão, chapéu) e o tutorial do Livro.

var state: Node
var database: Node
var events: Node
var main: Node
var inventory: RefCounted
var failures := 0
var clock := 1791936000.0
var levels_seen: Array[int] = []


func _initialize() -> void:
	create_timer(100).timeout.connect(func() -> void:
		push_error("CHEF: tempo excedido")
		quit(1))
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("CHEF: " + label)


func reset() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_set_phase", "puppy")
	state.call("_grant_upgrade", "stove")
	state.call("_mark_all_seen")
	state.call("dev_week_goto", 9)
	state.call("dev_content_day", 11)
	inventory = state.get("inventory")
	inventory.call("from_dict", {})
	state.call("dev_chef_points", 0)
	levels_seen.clear()


func points() -> int:
	return int(state.call("chef_info").score)


## Cozinha um prato do motor pelo fogão; devolve o trabalho (`job`) enfileirado.
func cook(type: String, items: Array, stars: int = 1, together: bool = false) -> Dictionary:
	for item: String in items:
		inventory.call("add", item, 1)
	var error: String = state.call("cook_dish", type, items, stars, together)
	check(error == "", "cozinha %s: %s" % [items, error])
	var queue: Array = state.call("station", "stove").queue
	return queue.back().job if not queue.is_empty() else {}


func collect_all() -> void:
	state.call("dev_finish_timers")
	state.call("collect", "stove")


func test_points() -> void:
	reset()
	cook("papinha", ["carrot", "corn"])
	check(points() == 3, "primeiro prato: 1 do preparo + 2 de prato novo (%d)" % points())
	collect_all()
	cook("papinha", ["carrot", "corn"])
	check(points() == 4, "repetir o prato vale 1 (%d)" % points())
	collect_all()
	cook("papinha", ["carrot", "corn"], 3, true)
	check(points() == 8, "Cozinhar junto soma as estrelas: 1 + 3 (%d)" % points())
	collect_all()
	var before := points()
	state.call("chef_add", 0)
	check(points() == before, "zero pontos não muda nada")
	cook("papinha", ["potato", "egg"], 2, true)
	check(points() == before + 1 + 2 + 2, "prato novo no Cozinhar junto: 1 + 2 + 2 estrelas (%d)" % points())
	collect_all()
	# Receita fixa do fogão também vale pontos.
	reset()
	inventory.call("add", "carrot", 6)
	inventory.call("add", "potato", 6)
	inventory.call("add", "corn", 6)
	var fixed := ""
	for id: String in database.call("recipes_for", "stove"):
		var recipe: Dictionary = database.get("recipes")[id]
		if bool(recipe.get("hidden", false)) or str(recipe.get("dish_type", "")) == "":
			continue
		if state.call("cook_many_error", id, 1) == "":
			fixed = id
			break
	if fixed != "":
		state.call("cook", fixed)
		check(points() >= 1, "receita fixa dá pontos (%d)" % points())
	state.call("dev_chef_points", 0)
	var save: Dictionary = state.call("to_dict")
	state.call("chef_add", 7)
	state.call("from_dict", save)
	inventory = state.get("inventory")
	check(points() == 0, "pontos voltam do save")
	state.call("chef_add", 7)
	save = state.call("to_dict")
	state.call("from_dict", save)
	inventory = state.get("inventory")
	check(points() == 7, "pontos persistem (%d)" % points())


func test_levels() -> void:
	reset()
	var rows: Array = state.call("chef_levels")
	check(rows.size() == 9, "nove níveis")
	var expected := [0, 10, 25, 40, 60, 85, 110, 140, 180]
	for i in 9:
		check(int(rows[i].points) == expected[i] and not str(rows[i].skill.id).is_empty(), "nível %d: %d pts" % [i, expected[i]])
	check(state.call("chef_info").name == "Ajudante" and state.call("chef_skill", "together"), "começa Ajudante com Cozinhar junto")
	state.call("chef_add", 9)
	check(levels_seen.is_empty(), "9 pontos ainda não sobem")
	state.call("chef_add", 1)
	check(levels_seen == [1] and state.call("chef_info").name == "Ajudante+", "10 pontos: Ajudante+ e sinal")
	levels_seen.clear()
	state.call("chef_add", 30)
	check(levels_seen == [2, 3], "40 pontos cruzam dois níveis de uma vez (%s)" % [levels_seen])
	check(int(state.call("chef_info").next) == 60, "próximo nível em 60")
	state.call("dev_chef_points", 500)
	check(int(state.call("chef_info").level) == 8 and int(state.call("chef_info").next) == 0, "nível máximo sem próximo")


func test_skills() -> void:
	reset()
	for id: String in ["sniff", "queue3", "quick_fire", "preview", "light_hand", "thrifty", "big_pot", "chef_hat"]:
		check(not state.call("chef_skill", id), "%s começa trancada" % id)
	var base_slots: int = state.call("station_slots", "stove")
	state.call("dev_chef_points", 10)
	check(state.call("chef_skill", "sniff"), "Faro de cozinha aos 10")
	state.call("dev_chef_points", 25)
	check(state.call("chef_skill", "queue3") and int(state.call("station_slots", "stove")) >= 3 and int(state.call("station_slots", "stove")) >= base_slots, "Fila maior: 3 vagas")
	var three: int = state.call("station_slots", "stove")
	# Fogo esperto: 10% mais rápido, só em lotes novos.
	state.call("dev_chef_points", 39)
	var slow := cook("papinha", ["carrot", "corn"])
	state.call("dev_finish_timers")
	state.call("collect", "stove")
	state.call("dev_chef_points", 40)
	var fast := cook("papinha", ["carrot", "corn"])
	check(state.call("chef_skill", "quick_fire") and is_equal_approx(float(fast.seconds), float(slow.seconds) * 0.9), "Fogo esperto: %s -> %s" % [slow.seconds, fast.seconds])
	collect_all()
	check(not bool(state.call("chef_info").exact_preview), "sem Prévia antes dos 60")
	state.call("dev_chef_points", 60)
	check(bool(state.call("chef_info").exact_preview) and state.call("chef_skill", "preview"), "Prévia aos 60")
	check(is_equal_approx(float(state.call("chef_gesture_scale")), 1.0), "sem Mão leve a escala é 1")
	var rules: Script = load("res://scripts/state/cook_rules.gd")
	var slow_speed := 1.1  # abaixo do mínimo (1,2): devagar demais
	check(rules.call("stir_zone", slow_speed, 1.0) == "slow", "sem Mão leve 1,1 rad/s é devagar")
	state.call("dev_chef_points", 85)
	check(is_equal_approx(float(state.call("chef_gesture_scale")), 1.15), "Mão leve: zonas 15% maiores")
	check(rules.call("stir_zone", slow_speed, float(state.call("chef_gesture_scale"))) == "good", "com Mão leve 1,1 rad/s já é bom")
	# Economia: a Gororoba devolve mais um ingrediente.
	state.call("dev_chef_points", 0)
	var plan_before: Dictionary = state.call("dish_plan", "papinha", ["oat", "oat", "oat"])
	check(plan_before.state == "gororoba", "aveia sozinha vira Gororoba")
	state.call("dev_chef_points", 110)
	var plan_after: Dictionary = state.call("dish_plan", "papinha", ["oat", "oat", "oat"])
	var refunded_before := 0
	var refunded_after := 0
	for item: String in plan_before.refund:
		refunded_before += int(plan_before.refund[item])
	for item: String in plan_after.refund:
		refunded_after += int(plan_after.refund[item])
	check(refunded_after == refunded_before + 1, "Economia: sobra um ingrediente (%d -> %d)" % [refunded_before, refunded_after])
	# Panelão: a cada 5 pratos recolhidos do fogão, uma porção extra.
	state.call("dev_chef_points", 139)
	inventory.call("from_dict", {})
	var extras := 0
	for i in 5:
		var job := cook("papinha", ["carrot", "corn"])
		state.call("dev_chef_points", 139)  # mantém o nível (os pontos do preparo não importam aqui)
		var queue: Array = state.call("station", "stove").queue
		queue.back()["qty"] = 1
		state.call("dev_finish_timers")
		var got: int = state.call("collect", "stove").get(str(job.output), 0)
		check(got in [1, 2], "colheita %d entrega %d" % [i + 1, got])
		state.call("dev_chef_points", 139)
	check(not state.call("chef_skill", "big_pot"), "sem Panelão antes dos 140")
	state.call("dev_chef_points", 140)
	inventory.call("from_dict", {})
	var totals: Array[int] = []
	for i in 6:
		var job := cook("papinha", ["carrot", "corn"])
		state.call("dev_finish_timers")
		var got: int = state.call("collect", "stove").get(str(job.output), 0)
		totals.append(got)
		extras += int(got > 1)
	check(totals == [1, 1, 1, 1, 2, 1], "Panelão: a 5ª colheita rende uma porção extra (%s)" % [totals])
	# Chapéu: 4ª vaga e a coleção, uma vez só.
	check(not state.get("progress").collection.has("week_chef_hat"), "sem chapéu antes do nível")
	var collections_before: int = state.get("progress").collection.size()
	state.call("dev_chef_points", 170)
	state.call("chef_add", 10)
	check(state.get("progress").collection.has("week_chef_hat") and int(state.call("station_slots", "stove")) >= 4, "Chapéu de chef: coleção e 4 vagas")
	check(state.get("progress").collection.size() == collections_before + 1, "coleção entregue uma vez")
	state.call("chef_add", 50)
	check(state.get("progress").collection.size() == collections_before + 1, "o chapéu não é entregue de novo")
	check(three >= 3, "três vagas confirmadas antes")


func test_tutorial() -> void:
	reset()
	state.call("dev_chef_points", 5)
	var lessons: Array = database.get("week_tutorials")
	var ids := lessons.map(func(row: Dictionary) -> String: return str(row.id))
	check("recipe_book" in ids, "lição recipe_book existe")
	var lesson: Dictionary = {}
	for row: Dictionary in lessons:
		if row.id == "recipe_book":
			lesson = row
	check(lesson.get("steps", []).size() == 4 and lesson.get("sequence", false), "quatro passos em sequência")
	check(str(lesson.steps[0].target) == "ChefCard" and str(lesson.steps[2].target) == "BookIngredients" and str(lesson.steps[3].target) == "BookGrid", "alvos do tutorial")
	# A lição de Inventar também fala dos pontos de cozinheiro.
	for row: Dictionary in lessons:
		if row.id == "invent":
			check("pontos de cozinheiro" in str(row.text), "Inventar explica os pontos")
	for row: Dictionary in lessons:
		var data: Dictionary = state.get("week").tutorial.get(row.id, {})
		data["done"] = true
		state.get("week").tutorial[row.id] = data
	state.get("week").tutorial["recipe_book"] = {}
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.8).timeout
	for member: String in ["_celebration", "_welcome", "_walk_result", "_quest_reward", "_growth_ceremony"]:
		(main.get(member) as Node).call("hide")
	main.set("_modal_queue", [] as Array[Callable])
	var guide: Node = main.find_child("WeekTutorial", true, false)
	check(guide != null, "guia de tutorial existe")
	await create_timer(0.5).timeout
	check(guide.get("active") != "recipe_book", "sem o Livro aberto a lição não aparece")
	(load("res://scripts/ui/pet_notebook.gd") as Script).call("open", "recipes")
	await create_timer(1.0).timeout
	check(guide.get("active") == "recipe_book" and guide.get("step") == 0, "abrir o Livro dispara a lição (%s/%s)" % [str(guide.get("active")), str(guide.get("step"))])
	for index in 4:
		var accept := main.find_child("TutorialAccept", true, false) as Control
		check(accept != null and accept.is_visible_in_tree(), "Entendi no passo %d" % (index + 1))
		if accept == null:
			break
		for pressed: bool in [true, false]:
			var touch := InputEventScreenTouch.new()
			touch.position = accept.get_global_rect().get_center()
			touch.pressed = pressed
			root.push_input(touch, true)
		await create_timer(0.8).timeout
	check(bool(state.get("week").tutorial.get("recipe_book", {}).get("done", false)), "a lição termina e fica registrada")
	check(guide.get("active") != "recipe_book" or not guide.visible, "o balão some depois do último passo")
	# O Manual de tutoriais lista a página no capítulo 8.
	var manual := load("res://scripts/ui/week_tutorial.gd") as Script
	var model := {}
	var body: Control = manual.call("manual_body", model, func() -> void: pass)
	root.add_child(body)
	check(body.find_child("TutorialReview_recipe_book", true, false) != null, "Manual de tutoriais tem a página do Livro")
	body.queue_free()


func test_celebration() -> void:
	var celebration: Node = main.get("_celebration")
	var seen: Array[int] = []
	events.chef_level_up.connect(func(level: int) -> void: seen.append(level))
	state.call("dev_chef_points", 0)
	state.call("chef_add", 25)
	check(seen == [1, 2], "sinal chef_level_up por nível (%s)" % [seen])
	celebration.call("show_chef_level", 2)
	await create_timer(0.8).timeout
	var card := main.find_child("CardPanel", true, false)
	check(card != null and card.is_visible_in_tree(), "comemoração do nível aparece")
	celebration.call("hide")


func _run() -> void:
	state = root.get_node("GameState")
	database = root.get_node("Database")
	events = root.get_node("Events")
	var saver := root.get_node("SaveManager")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	load("res://tests/helpers/old_day_rules.gd").new().apply(database)
	state.set_script(load("res://tests/friend_clock.gd"))
	state.set("test_time", clock)
	(load("res://scripts/ui/motion.gd") as GDScript).set("reduced", true)
	events.chef_level_up.connect(func(level: int) -> void: levels_seen.append(level))
	test_points()
	test_levels()
	test_skills()
	await test_tutorial()
	await test_celebration()
	print("CHEF SKILLS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(int(failures > 0))
