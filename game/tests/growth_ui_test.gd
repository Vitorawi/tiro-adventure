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
		ui.call("open")
		await frames()
		var panel := main.find_child("GrowthPanel", true, false)
		check(panel != null and panel.find_child("GrowthCard_" + str(phase.id), true, false) != null, "caderneta " + str(phase.id))
		for row: Dictionary in state.call("growth_info").requirements:
			check(panel.find_child("GrowthReq_" + str(row.id), true, false) != null, "requisito " + str(row.id))
			var help: Dictionary = load("res://scripts/ui/task_help.gd").call("describe", "growth_req", str(row.id))
			check(help.action == "Ir" and not help.target.is_empty(), "destino do requisito")
		check(primary(panel) <= 1, "no máximo um PrimaryButton")
	state.call("dev_set_phase", "newborn")
	state.get("growth").points = {"body": 2, "brave": 0}
	var helper: Script = load("res://scripts/ui/task_help.gd")
	helper.call("open", "growth_req", "pillars")
	await frames()
	var care_sheet := main.find_child("Sheet", true, false)
	check(text(care_sheet, "2/10 pontos") and text(care_sheet, "0/10 pontos"), "mostra pontos separados dos dois cuidados")
	check(text(care_sheet, "Ração") and text(care_sheet, "Faça carinho"), "explica as duas ações sem outra ajuda")
	check(care_sheet.find_child("GrowthCare_body", true, false) != null and care_sheet.find_child("GrowthCare_brave", true, false) != null, "cada cuidado tem seu atalho")
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
	for name: String in ["LifeDots", "CurrentDog", "NextSilhouette", "NextUnlocks", "PillarRing_body", "GrowthLock"]:
		check(panel.find_child(name, true, false) != null, "nó " + name)
	check(text(panel, "2/3") and text(panel, "✓"), "quantidade e marca de cumprido")
	check(text(panel.find_child("GrowthLock", true, false), "Dar comida"), "primeiro motivo legível")
	check(main.find_child("GrowthBadgeHint", true, false).text == "Falta 1!", "selo quase pronto")
	var shadow: ShaderMaterial = panel.find_child("NextSilhouette", true, false).get_child(0).material
	check(shadow.shader.resource_path.ends_with("silhouette.gdshader") and int(shadow.get_shader_parameter("stage")) == 3, "estágio por requisitos")
	for future: Control in panel.find_children("Future_*", "", true, false):
		check(future.get_child(0).material.shader.resource_path.ends_with("silhouette.gdshader"), "cartão futuro sempre mascarado")
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
	main.queue_free()
	await frames()
	print("GROWTH_UI TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
