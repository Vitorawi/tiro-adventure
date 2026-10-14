extends SceneTree
## Etapa 04: cadeias reais, navegação do liquidificador e prévias mobile.
var failures: int = 0
var state: Node
var db: Node
var main: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Sabores: " + message)

func labels(node: Node, result: Array[String]) -> void:
	if node is Label:
		result.append((node as Label).text)
	for child: Node in node.get_children():
		labels(child, result)

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.call("reset")
	check(state.call("upgrade_error", "blender") != "", "não revela compra antes da primeira cozinha")
	state.get("progress").claimed_quests["first_kitchen"] = true
	check("place:house/blender" in state.call("new_unlocks"), "liquidificador aparece no Novo após primeira cozinha")
	state.set("coins", 100)
	check(state.call("buy_upgrade", "blender") == "" and state.get("coins") == 70, "liquidificador custa 30")
	check(state.call("buy_upgrade", "blender") != "" and state.get("coins") == 70, "compra repetida não cobra")
	check(db.call("place_with_panel", "station:blender") == ["house", "blender"], "Ir leva ao lugar próprio")
	state.get("progress").owned["stove"] = true
	state.set("unlimited_storage", true)
	for quest: String in ["bloblo_potato", "bloblo_sweet_potato"]:
		state.get("progress").claimed_quests[quest] = true
	for id: String in ["strawberry_pop", "strawberry_juice", "mashed_potato", "sweet_potato_chips"]:
		var recipe: Dictionary = db.get("recipes")[id]
		for input: String in recipe.inputs:
			state.get("inventory").add(input, int(recipe.inputs[input]))
		check(state.call("cook", id) == "", id + ": produção inicia")
		for input: String in recipe.inputs:
			check(state.get("inventory").count(input) == 0, id + ": ingrediente consumido uma única vez")
		check((state.call("collect", recipe.station) as Dictionary).is_empty(), id + ": não coleta antes da hora")
		for batch: Dictionary in state.call("station", recipe.station).queue:
			batch.ready_at = 1.0
		state.call("collect", recipe.station)
		check(state.get("inventory").count(id) == 1, id + ": entrega uma unidade")
		check((state.call("collect", recipe.station) as Dictionary).is_empty(), id + ": não duplica")
	check(not state.call("feed", "strawberry_juice"), "suco é para pessoas")
	check(state.call("feed", "strawberry_pop"), "picolé alimenta o Tiro")
	state.call("dev_unlock_everything")
	var builder: Script = load("res://scripts/ui/sheet_builder.gd")
	var picker: Control = builder.call("seed_picker", 0)
	root.add_child(picker)
	await process_frame
	var texts: Array[String] = []
	labels(picker, texts)
	var previous := -1
	for name: String in ["Cenoura", "Trigo", "Morango", "Milho", "Batata", "Batata-doce", "Abóbora", "Ervas"]:
		var index := texts.find(name)
		check(index > previous, "sementes ordenadas: " + name)
		previous = index
	picker.queue_free()
	if "--screenshots" in OS.get_cmdline_user_args():
		await screenshots()
	print("FLAVORS TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures > 0 else 0)

func shot(name: String) -> void:
	await create_timer(0.5).timeout
	if name in ["blender_before", "blender_after", "blender_working"]:
		var room: Control = main.get_node("%WorldsScreen").get("_views")["house"]
		room.call("_zoom_at", room.size / 2.0, 0.85)
		var content: Control = room.get("_content")
		content.position = room.size / 2.0 - Vector2(335, 235) * float(room.get("_zoom"))
		room.call("_clamp_content")
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/etapa04/")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder + name + ".png")

func screenshots() -> void:
	state.call("dev_add_items", 20)
	state.get("progress").seen["intro"] = true
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.3).timeout
	main.get_node("Celebration").hide()
	state.call("set_sleeping", true)
	main.call("_on_world_requested", "house", "")
	var house: Control = main.get_node("%WorldsScreen").get("_views")["house"]
	house.call("_zoom_at", house.size / 2.0, 0.85)
	var content: Control = house.get("_content")
	content.position = house.size / 2.0 - Vector2(335, 235) * float(house.get("_zoom"))
	house.call("_clamp_content")
	state.get("progress").owned.erase("blender")
	root.get_node("Events").emit_signal("state_changed")
	await shot("blender_before")
	state.get("progress").owned["blender"] = true
	root.get_node("Events").emit_signal("state_changed")
	await shot("blender_after")
	state.call("cook", "strawberry_pop")
	await shot("blender_working")
	main.call("_on_world_requested", "house", "blender")
	await create_timer(1.5).timeout
	await shot("blender_recipes")
	root.get_node("Events").emit_signal("sheet_close_requested")
	main.call("_on_world_requested", "farm", "")
	state.call("plant", 0, "strawberry")
	state.call("plant", 1, "sweet_potato")
	state.get("plots")[0].ready_at = 1.0
	state.get("plots")[1].ready_at = 1.0
	root.get_node("Events").emit_signal("state_changed")
	await shot("strawberry_mature")
	var farm: Control = main.get_node("%WorldsScreen").get("_views")["farm"]
	farm.call("point_at", "plot:0")
	farm.call("_zoom_at", farm.size / 2.0, 1.4)
	await shot("crops_close")
	var builder: Script = load("res://scripts/ui/sheet_builder.gd")
	root.get_node("Events").emit_signal("sheet_requested", "Plantar", builder.call("seed_picker", 2))
	await shot("seeds")
	root.get_node("Events").emit_signal("sheet_close_requested")
	state.get("wishes").slots[0] = {"id": "strawberry_pop", "base": 0, "since": state.call("now"), "ready_at": 0.0, "special": false, "last": ""}
	state.call("set_sleeping", false)
	root.get_node("Events").emit_signal("state_changed")
	main.call("show_screen", &"wishes")
	await shot("wish_pop")
	main.call("_on_world_requested", "village", "")
	var ui: Script = load("res://scripts/ui/progression_ui.gd")
	root.get_node("Events").emit_signal("sheet_requested", "Pedidos novos", ui.call("orders_panel", "fruit_basket"))
	await shot("fruit_order")
	root.get_node("Events").emit_signal("sheet_requested", "Suco para a Laís", ui.call("orders_panel", "juice_order"))
	await shot("juice_order")
