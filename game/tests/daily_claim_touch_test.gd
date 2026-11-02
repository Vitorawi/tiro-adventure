extends SceneTree
## Aba real: sanfona, rebuild entre down/up, limites, estilo e prêmio único.
var failures := 0
var main: Control
var tasks: Control
var state: Node

func _initialize() -> void:
	_run.call_deferred()

func frames(n: int = 6) -> void:
	for i in n: await process_frame

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("DAILY CLAIM: " + message)

func touch(point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * point
	event.pressed = down
	Input.parse_input_event(event)
	await frames(2)

func fixture() -> void:
	state.call("reset")
	state.get("progress").seen.intro = true
	var progress: Variant = state.get("progress")
	# Libere só as diárias, sem prêmios/avisos laterais das ferramentas DEV.
	var database := root.get_node("Database")
	for id: String in database.get("quests"):
		var quest: Dictionary = database.get("quests")[id]
		if quest.get("kind", "") == "main" and int(quest.get("chapter", 99)) < 3:
			progress.claimed_quests[id] = true
	progress.owned["stove"] = true
	progress.stats["production_jobs"] = 1
	progress.stats["harvest"] = 0
	progress.routines["daily"] = {"period": state.call("routine_period", "daily"), "ids": ["harvest", "cook"], "base": {}, "targets": {"harvest": 2, "cook": 1}, "claimed": {}}
	tasks.set("_routine", "")
	state.call("_changed")
	main.call("show_screen", &"tasks")
	tasks.call("choose_group", "timed")
	await frames()
	main.set("_modal_queue", [] as Array[Callable])
	for member: String in ["_celebration", "_welcome", "_growth_ceremony", "_walk_result", "_quest_reward"]:
		var modal: CanvasLayer = main.get(member)
		if modal: modal.hide()
	await frames()

func claim_button(id: String) -> Button:
	var row := tasks.find_child("Routine_daily_" + id, true, false)
	for button: Node in row.find_children("*", "Button", true, false):
		if (button as Button).text == "Pegar": return button as Button
	return null

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen.intro = true
	Input.emulate_mouse_from_touch = true
	Motion.reduced = true
	var before := "--before" in OS.get_cmdline_user_args()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	tasks = main.find_child("TasksScreen", true, false)
	for resolution: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = resolution
		await fixture()
		if "--shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			var folder := ProjectSettings.globalize_path("res://../build/screenshots/diarias_pegar/")
			DirAccess.make_dir_recursive_absolute(folder)
			root.get_texture().get_image().save_png(folder + ("antes" if before else "depois") + "_%dx%d.png" % [resolution.x, resolution.y])
		if before:
			var point := claim_button("cook").get_global_rect().get_center()
			await touch(point, true)
			await touch(point, false)
			print("ANTES %s: resgatou=%s, detalhe=%s" % [resolution, state.call("routine_claimed", "daily", "cook"), tasks.get("_routine")])
			continue
		for opened: bool in [false, true]:
			await fixture()
			if opened:
				tasks.call("choose_routine_detail", "daily", "cook")
				await frames()
			var button := claim_button("cook")
			var incomplete := claim_button("harvest")
			check(button != null and incomplete != null, "ambos estados têm Pegar")
			if button == null or incomplete == null: continue
			var reference: Button = load("res://scripts/ui/mission_ui.gd").call("button", "go", "Pegar", func() -> void: pass)
			check(button.get_node("Frame").texture == reference.get_node("Frame").texture, "arte padrão amarela")
			check(not button.disabled and button.get_node("Frame").modulate == Color.WHITE, "completo amarelo ativo")
			check(incomplete.disabled and incomplete.get_node("Frame").modulate == Color(0.48, 0.48, 0.48, 0.65), "incompleto cinza desabilitado")
			reference.free()
			var row := tasks.find_child("Routine_daily_cook", true, false) as Control
			var scroll := tasks.find_child("Scroll", true, false) as Control
			check(row.get_global_rect().encloses(button.get_global_rect()), "botão dentro da linha")
			check(scroll.get_global_rect().encloses(button.get_global_rect()), "alvo dentro da rolagem")
			check(button.size.x >= 44 and button.size.y >= 44, "alvo mínimo 44")
			var point := button.get_global_rect().get_center()
			var coins: int = state.get("coins")
			await touch(point, true)
			check(str(tasks.get("_routine")) == ("daily_cook" if opened else ""), "Pegar não aciona a sanfona")
			state.call("_changed")
			tasks.get("_content").call("refresh")
			await frames()
			check(is_instance_valid(button) and not button.is_queued_for_deletion(), "rebuild preserva gesto")
			await touch(point, false)
			await frames()
			check(state.call("routine_claimed", "daily", "cook"), "resgate %s aberta=%s" % [resolution, opened])
			check(int(state.get("coins")) == coins + 8, "pagamento exato")
			await touch(point, true)
			await touch(point, false)
			check(int(state.get("coins")) == coins + 8, "toque duplo não duplica")
			check(tasks.find_child("Routine_daily_cook", true, false) == null, "rebuild remove resgatada")
			var disabled := claim_button("harvest")
			var disabled_point := disabled.get_global_rect().get_center()
			await touch(disabled_point, true)
			await touch(disabled_point, false)
			check(not state.call("routine_claimed", "daily", "harvest"), "incompleta não paga")
		print("DIÁRIAS %s: verificado" % resolution)
	print("DAILY CLAIM TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
