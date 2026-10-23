extends SceneTree
## Contrato da tela e entregas; fixtures só no processo isolado do teste.
var failures := 0
var state: Node
var db: Node
var ui: Script
var main: Control

func _initialize() -> void:
	_run.call_deferred()
	create_timer(150.0).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Growth UI: " + message)

func frames(n: int = 8) -> void:
	for i in n: await process_frame

func click(node: Control) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = root.get_final_transform() * (node.get_global_transform_with_canvas() * (node.size * 0.5))
		root.push_input(event)
	await frames()

func primary(node: Node) -> int:
	var count := int(node is Button and node.theme_type_variation == &"PrimaryButton")
	for child: Node in node.get_children(): count += primary(child)
	return count

func text(node: Node, value: String) -> bool:
	for label: Label in node.find_children("*", "Label", true, false):
		if value in label.text: return true
	return false

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	ui = load("res://scripts/ui/growth_ui.gd")
	Motion.reduced = true
	state.call("reset")
	state.get("progress").seen.intro = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	for member: String in ["_celebration", "_welcome", "_walk_result"]: main.get(member).hide()
	main.set("_modal_queue", [] as Array[Callable])
	# Destinos e painel em qualquer fase, incluindo o adulto sem próximo corpo.
	for phase: Dictionary in db.get("growth").phases:
		state.call("dev_set_phase", str(phase.id))
		if str(phase.id) == "teething" and "--layout-shots" in OS.get_cmdline_user_args():
			state.get("growth").phase_moments = {"body": 34, "coat": 0, "smart": 19, "brave": 61}
			state.get("progress").owned["stove"] = true
		if str(phase.id) == "puppy" and "--ring-shots" in OS.get_cmdline_user_args():
			state.get("progress").claimed_quests["growth_1_puppy"] = true
		ui.call("open")
		await frames()
		var panel := main.find_child("GrowthPanel", true, false)
		check(panel != null and panel.find_child("GrowthHero", true, false) != null, "cabeçalho compacto " + str(phase.id))
		check(panel.find_child("GrowthCard_" + str(phase.id), true, false) == null, "histórico fora da lista de tarefas")
		for row: Dictionary in state.call("growth_info").requirements:
			if row.type == "given": continue
			check(panel.find_child("GrowthReq_" + str(row.id), true, false) != null, "requisito " + str(row.id))
			var help: Dictionary = load("res://scripts/ui/task_help.gd").call("describe", "growth_req", str(row.id))
			check(str(help.action) != "" and not help.target.is_empty(), "requisito tem ação e destino concretos")
		check(primary(panel) <= 1, "no máximo um PrimaryButton")
		if "--layout-shots" in OS.get_cmdline_user_args(): await layout_shot(str(phase.id))
		if "--portrait-shots" in OS.get_cmdline_user_args():
			await layout_shot(str(phase.id) + "_awake")
			state.get("dog").sleeping = true
			ui.call("open")
			await frames()
			await create_timer(3.0).timeout
			await layout_shot(str(phase.id) + "_sleep")
			state.get("dog").sleeping = false
		ui.call("history")
		await frames()
		var history := main.find_child("GrowthHistory", true, false)
		check(history != null and history.find_child("GrowthCard_" + str(phase.id), true, false) != null, "caderneta preservada " + str(phase.id))
		ui.call("open")
		await frames()
		if str(phase.id) == "teething" and "--food-shots" in OS.get_cmdline_user_args():
			state.get("progress").owned["stove"] = true
			state.get("progress").claimed_quests["growth_1_puppy"] = true
			var helper: Script = load("res://scripts/ui/task_help.gd")
			helper.call("open", "growth_req", "meals")
			await frames()
			var folder := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/food_help").simplify_path()
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder.path_join("meal_%d.png" % root.size.x)) == OK, "captura da ajuda de comida")
		if str(phase.id) == "puppy" and "--ring-shots" in OS.get_cmdline_user_args():
			var folder := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/ring_help").simplify_path()
			DirAccess.make_dir_recursive_absolute(folder)
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder.path_join("growth_%d.png" % root.size.x)) == OK, "captura da origem no crescimento")
			var help: Script = load("res://scripts/ui/task_help.gd")
			help.call("open", "growth_req", "key")
			await frames()
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder.path_join("source_%d.png" % root.size.x)) == OK, "captura de onde conseguir")
	state.call("dev_set_phase", "newborn")
	state.get("growth").phase_moments = {"body": 2, "brave": 0}
	var helper: Script = load("res://scripts/ui/task_help.gd")
	helper.call("open", "growth_req", "pillars")
	await frames()
	var care_sheet := main.find_child("Sheet", true, false)
	check(text(care_sheet, "0/2 momentos"), "carinho mostra momentos de Coragem")
	check(text(care_sheet, "Faça carinho"), "explica a ação que ainda falta")
	check(care_sheet.find_child("GrowthCare_body", true, false) == null and care_sheet.find_child("GrowthCare_brave", true, false) != null, "Corpo pertence às refeições e não é cobrado nos cuidados")
	check(primary(care_sheet) == 1, "uma ação principal nos cuidados")
	if "--screenshots" in OS.get_cmdline_user_args():
		var shots := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/first_growth").simplify_path()
		DirAccess.make_dir_recursive_absolute(shots)
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(shots.path_join("care_%d.png" % root.size.x)) == OK, "salva captura dos cuidados")
	state.get("growth").done = {"puppy": {"home": true, "bed": true, "pillars": true}}
	state.get("growth").phase_stats["feed"] = 0
	state.get("progress").stats["feed"] = 2
	state.call("_changed")
	ui.call("open")
	await frames()
	var panel := main.find_child("GrowthPanel", true, false)
	for name: String in ["GrowthHero", "CurrentDog", "NextSilhouette", "NextUnlocks", "GrowthNextAction", "GrowthSummary", "GrowthProgress"]:
		check(panel.find_child(name, true, false) != null, "nó " + name)
	check(text(panel, "2/3") and text(panel, "2 de 3 passos"), "quantidade e resumo dos passos visíveis")
	check(panel.find_child("GrowthNextAction", true, false).text == "Dar comida", "próxima ação nomeada")
	check(panel.find_child("PillarRing_body", true, false) == null, "não repete pontos e anéis no painel principal")
	check(main.find_child("GrowthBadgeHint", true, false).text == "Falta 1!", "selo quase pronto")
	var shadow: ShaderMaterial = panel.find_child("NextSilhouette", true, false).get_child(0).material
	check(shadow.shader.resource_path.ends_with("silhouette.gdshader") and int(shadow.get_shader_parameter("stage")) == 3, "estágio por requisitos")
	for future: Control in panel.find_children("Future_*", "", true, false):
		check(future.get_child(0).material.shader.resource_path.ends_with("silhouette.gdshader"), "cartão futuro sempre mascarado")
	var list_scroll := main.find_child("Sheet", true, false).find_child("Scroll", true, false) as ScrollContainer
	list_scroll.ensure_control_visible(panel.find_child("GrowthReq_meals", true, false))
	await frames()
	await click(panel.find_child("GrowthReq_meals", true, false))
	check(main.find_child("Sheet", true, false).get_node("%Title").text == "Como fazer", "toque abre ajuda")
	check(text(main.find_child("Sheet", true, false), "Qualquer comida") and text(main.find_child("Sheet", true, false), "ração"), "ajuda explica que a ração inicial conta")
	# Dar usa o mesmo item no painel e na Mochila; parcial, atualização e repetição.
	var original: Array = db.get("growth").phases[1].requirements.duplicate(true)
	db.get("growth").phases[1].requirements = [{"id": "fixture_key", "type": "deliver", "item": "stick", "qty": 2, "label": "Chave de teste"}]
	state.get("growth").done = {}
	state.get("inventory").add("stick", 1)
	ui.call("open")
	await frames()
	panel = main.find_child("GrowthPanel", true, false)
	var before: int = state.get("inventory").count("stick")
	await click(panel.find_child("GiveGrowth_stick", true, false))
	check(state.get("inventory").count("stick") == before - 1, "Dar consome exatamente uma vez")
	check(text(panel, "1/2") and panel.is_inside_tree(), "parcial sem fechar")
	state.get("inventory").add("stick", 1)
	state.call("_changed")
	var item_panel: Control = load("res://scripts/ui/sheet_builder.gd").call("item_detail", "stick")
	root.add_child(item_panel)
	await frames()
	var give: Button = item_panel.find_child("GiveGrowth_stick", true, false)
	check(give != null and primary(item_panel) == 1, "Dar na Mochila")
	give.pressed.emit()
	await frames()
	check(panel.find_child("GrowButton", true, false) != null and primary(panel) == 1, "pronto acende na mesma árvore")
	if "--layout-shots" in OS.get_cmdline_user_args(): await layout_shot("ready")
	check(state.call("deliver_growth", "stick") != "", "entrega repetida não consome")
	item_panel.queue_free()
	# Crescer pelo caminho de input, após colocar o botão na área visível do Sheet.
	var scroll := main.find_child("Sheet", true, false).find_child("Scroll", true, false) as ScrollContainer
	scroll.ensure_control_visible(panel.find_child("GrowButton", true, false))
	await frames()
	await click(panel.find_child("GrowButton", true, false))
	check(state.get("growth").phase == "puppy", "toque Crescer muda fase")
	check(main.get("_growth_queued").has("puppy"), "Crescer enfileira a cerimônia que assume a tela")
	db.get("growth").phases[1].requirements = original
	if "--meal-shots" in OS.get_cmdline_user_args(): await meal_shots()
	main.queue_free()
	await frames()
	print("GROWTH_UI TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func layout_shot(label: String) -> void:
	var folder := ProjectSettings.globalize_path("res://").path_join("../build/screenshots/growth_layout").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join("%s_%d.png" % [label, root.size.x])) == OK, "captura do layout " + label)


func meal_shots() -> void:
	for phase: String in ["newborn", "teething"]:
		state.call("reset")
		state.get("progress").seen.intro = true
		state.get("progress").owned.dog_bed = true
		state.get("growth").phase = phase
		state.get("growth").phase_moments = {}
		var info: Dictionary = state.call("growth_info")
		var meals: Dictionary = info.requirements.filter(func(row: Dictionary) -> bool: return row.type == "feed")[0]
		var item := "dog_food" if meals.item == "any" else str(meals.item)
		state.get("inventory").add(item, int(meals.need))
		for n in int(meals.need):
			state.call("feed", item)
			if n != 0 and n + 1 != int(meals.need): continue
			ui.call("open")
			await frames()
			for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]: main.get(member).hide()
			main.get("_modal_queue").clear()
			main.get("_toast").hide()
			await layout_shot("%s_meals%d" % [phase, n + 1])
		check(text(main.find_child("GrowthPanel", true, false), "Corpo completo"), "refeições completas explicam Corpo atendido")
