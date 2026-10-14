extends SceneTree
## Capturas da Etapa 07: sem headless, 360x780, processo com timeout externo.

var state: Node
var main: Node
var ui: Script
var folder := "res://../build/screenshots/etapa07/"


func _initialize() -> void:
	_run.call_deferred()


func shot(shot_name: String) -> void:
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	root.get_texture().get_image().save_png(path + shot_name + ".png")


func _sheet(title: String, content: Control) -> void:
	root.get_node("Events").emit_signal("sheet_requested", title, content)
	await create_timer(0.5).timeout


func _scroll_to(node_name: String) -> void:
	var sheet: Control = main.get_node("Sheet")
	var target: Control = sheet.find_child(node_name, true, false)
	var scroll := sheet.get_node("%ContentHolder").get_parent() as ScrollContainer
	if target and scroll:
		scroll.scroll_vertical += int(target.global_position.y - scroll.global_position.y)
	await process_frame


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	for id in ["welcome", "lais_bed", "bloblo_meet", "first_harvest", "main_2_order", "nina_meet", "nina_walk"]:
		progress.claimed_quests[id] = true
	progress.seen["intro"] = true
	progress.count("walk", 6)
	progress.count("walk:park_loop", 6)
	state.get("walk_state").history.park_loop = {"count": 6}
	state.get("dog").needs["energy"] = 100.0
	state.call("_mark_all_seen")
	state.call("_changed")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	ui = load("res://scripts/ui/progression_ui.gd")
	await create_timer(0.5).timeout
	main.get_node("Celebration").hide()
	main.call("_on_world_requested", "park", "")
	await create_timer(2.0).timeout
	await _sheet("Passeio", ui.call("walks_panel"))
	await shot("painel_3_liberados")
	await _scroll_to("WalkCard_village_fair")
	await shot("painel_2_bloqueados")
	progress.count("walk", 4)
	var sunset: Dictionary = root.get_node("Database").get("walks").walks.sunset_walk
	var actual: int = Time.get_datetime_dict_from_unix_time(state.call("_local_time")).hour
	# Janela fechada garantida qualquer que seja a hora desta captura; texto do plano preservado.
	if actual >= 17 and actual < 21:
		sunset.requirements.hours = [17, actual] if actual > 17 else [18, 21]
	await _sheet("Passeio", ui.call("walks_panel"))
	await _scroll_to("WalkCard_sunset_walk")
	await shot("por_do_sol_fechado")
	sunset.requirements.hours = [17, 21]
	await _sheet("Diário de passeios", ui.call("walk_diary"))
	await shot("diario")
	await _scroll_to("Diary_creek_walk")
	await shot("diario_bloqueados")
	root.get_node("Events").emit_signal("sheet_close_requested")
	var card: Node = main.get_node("WalkResult")
	var result := {"id": "park_loop", "name": "Volta na praça", "postcard": state.call("walk_postcard", "park_loop"), "items": {"stick": 2, "ribbon": 1}, "coins": 12, "affection": 3, "needs": {"happiness": 20, "hygiene": -10}, "new": []}
	card.call("show_result", result)
	await shot("volta_normal")
	result["first"] = true
	result["new"] = ["stick", "ribbon"]
	card.call("show_result", result)
	await shot("volta_primeira")
	result["rare"] = "plaid_bow"
	card.call("show_result", result)
	await shot("volta_raro")
	var scroll: ScrollContainer = card.find_child("WalkResultScroll", true, false)
	scroll.scroll_vertical = 10000
	await shot("volta_raro_botao")
	result["rare"] = ""
	result["first"] = false
	result["rare_duplicate"] = true
	result["rare_item"] = "plaid_bow"
	result["coins"] = 32
	card.call("show_result", result)
	await shot("volta_consolo")
	card.hide()
	await _sheet("Coleção", ui.call("_clothes_panel"))
	await _scroll_to("RareHint_plaid_bow")
	await shot("colecao_silhuetas")
	await _sheet("Mochila", load("res://scripts/ui/sheet_builder.gd").call("inventory_view"))
	root.get_node("Events").emit_signal("sheet_close_requested")
	state.get("inventory").counts.clear()
	for id: String in root.get_node("Database").get("items"):
		if root.get_node("Database").get("items")[id].get("category", "") == "trail":
			state.get("inventory").add(id, 3)
	await _sheet("Mochila", load("res://scripts/ui/sheet_builder.gd").call("inventory_view"))
	await shot("mochila_passeio")
	await _sheet("Novelo de lã", load("res://scripts/ui/sheet_builder.gd").call("item_detail", "yarn"))
	await shot("item_nota_origem")
	quit(0)
