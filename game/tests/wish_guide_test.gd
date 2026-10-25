extends SceneTree
## Regressão do Ir das missões e da prontidão do balão; sem save pessoal.
var failures := 0
var KIT: Script
var PLACES: Script
var PROGRESSION: Script
var state: Node
var main: Control
var shots := "--screenshots" in OS.get_cmdline_user_args()

func _initialize() -> void:
	_run.call_deferred()
	create_timer(90).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("WISH_GUIDE: " + message)

func frames() -> void:
	for i: int in 12: await process_frame

func tap(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = point
		root.push_input(event, true)
		await process_frame
	await frames()

func shot(kind: String) -> void:
	if not shots: return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/desejo")
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder.path_join("%s_%dx%d.png" % [kind, root.size.x, root.size.y])) == OK, "captura " + kind)

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	KIT = load("res://scripts/ui/ui_kit.gd")
	PLACES = load("res://scripts/ui/places.gd")
	PROGRESSION = load("res://scripts/ui/progression_ui.gd")
	state = root.get_node("GameState")
	state.set_script(load("res://tests/helpers/economy_clock.gd"))
	state.set_clock(1792746000.0)
	state.reset()
	state.set_process(false)
	state.growth.phase = "puppy"
	state.progress.claimed_quests["lais_bed"] = true
	state.progress.seen.intro = true
	state._mark_all_seen()
	state.update_wishes()
	Motion.reduced = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony"]:
		(main.get(member) as CanvasLayer).hide()
	main.set("_modal_queue", [] as Array[Callable])
	var pet: Control = main.find_child("PetScreen", true, false)
	var bubble: Button = pet.find_child("WishBubble", true, false)
	var badge: Label = bubble.get_node("WishReadyBadge")
	var events := root.get_node("Events")
	for key: String in ["wish", "wish:meal", "wish:pet"]:
		check(PLACES.goal_target({"type": "stat", "key": key}).get("care") == "wish", "destino genérico " + key)
	for viewport: Vector2i in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]:
		root.size = viewport
		state.wishes.current = {"id": "pet", "item": "", "period": state.moment_period(), "progress": state.progress.stat("pet"), "since": state.now()}
		state._changed()
		main.call("show_screen", &"tasks")
		# Mesmo botão/callback usado no cartão Principal da missão real (inclusive seu override go).
		var actions: VBoxContainer = KIT.vbox()
		main.add_child(actions)
		PROGRESSION.quest_action(actions, "lais_first_wish")
		await frames()
		var go: Button = actions.find_children("*", "Button", true, false)[0]
		check(go.text == "Ir", "missão oferece Ir")
		await tap(go)
		actions.queue_free()
		await frames()
		check(main.get("_current_screen") == &"pet" and pet.is_visible_in_tree(), "Ir abre Home")
		var pointer: Polygon2D = bubble.get_node_or_null("CarePointer")
		check(pointer != null and pointer.is_visible_in_tree(), "Ir mostra seta no balão")
		if pointer:
			check(is_equal_approx(pointer.position.x, bubble.size.x / 2), "seta centralizada")
			check(Rect2(Vector2.ZERO, Vector2(viewport)).encloses(pointer.get_global_transform() * Rect2(-15, -42, 30, 32)), "seta dentro da tela")
		check(not badge.is_visible_in_tree(), "ação ainda pendente sem badge")
		await shot("arrow")

		await tap(bubble)
		check(bubble.get_node_or_null("CarePointer") == null, "toque limpa seta")
		check(main.find_child("WishCard", true, false) != null, "toque abre pedido")
		var catcher := main.find_child("PopoverCatcher", true, false)
		if catcher: catcher.free()
		state.pet()
		await frames()
		check(badge.is_visible_in_tree(), "ação pronta ganha badge")
		check(badge.text == "!" and badge.get_theme_stylebox("normal").bg_color == Palette.ALERT, "badge compartilhada")
		await shot("badge")
		PLACES.go(PLACES.quest_target("lais_first_wish"))
		check(state.fulfill_wish() == "", "atende desejo")
		await frames()
		check(not bubble.visible and not badge.is_visible_in_tree() and bubble.get_node_or_null("CarePointer") == null, "atender limpa balão, badge e seta")
		# Estoque entra/sai pela mesma notificação de estado usada pelas ações reais.
		state.wishes.current = {"id": "meal", "item": "dog_food", "period": state.moment_period(), "progress": 0, "since": state.now()}
		state.inventory.from_dict({})
		state._changed()
		await frames()
		check(not badge.visible, "sem comida sem badge")
		state.inventory.add("dog_food", 1)
		state._changed()
		await frames()
		check(badge.is_visible_in_tree(), "receber comida mostra badge")
		state.inventory.remove("dog_food", 1)
		state._changed()
		await frames()
		check(not badge.visible, "gastar comida remove badge")
		PLACES.go(PLACES.goal_target({"type": "stat", "key": "wish:meal"}))
		events.screen_requested.emit(&"tasks")
		await frames()
		check(bubble.get_node_or_null("CarePointer") == null, "sair limpa seta")
	print("WISH GUIDE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)

