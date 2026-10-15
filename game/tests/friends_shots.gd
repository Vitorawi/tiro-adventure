extends SceneTree
## Capturas gráficas da Etapa 09, sem gravação de saves pessoais.
var state: Node
var db: Node
var main: Node
var events: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	events = root.get_node("Events")
	state.set_script(load("res://tests/friend_clock.gd"))
	state.set("test_time", Time.get_unix_time_from_system())
	state.call("reset")
	var p: RefCounted = state.get("progress")
	for id: String in db.get("quests"):
		if id not in ["nina_sewing", "nina_pipoca", "nina_friends"]:
			p.claimed_quests[id] = true
	p.seen["intro"] = true
	p.seen["npc_intro:nina"] = true
	p.owned["blender"] = true
	state.call("_changed")
	state.call("_mark_all_seen")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.call("_on_world_requested", "park", "look:npc:dog_pipoca")
	await shot("01_pipoca_decor")
	p.claimed_quests["nina_sewing"] = true
	state.call("_changed")
	state.call("_mark_all_seen")
	main.call("_on_world_requested", "park", "look:friend:pipoca")
	await shot("02_pipoca_amiga")
	load("res://scripts/ui/places.gd").call("open_npc", "nina")
	await shot("02b_missao_nina")
	var friend_ui: Script = load("res://scripts/ui/friend_ui.gd")
	friend_ui.call("open", "pipoca")
	await shot("03_cartao_falta_petisco")
	state.get("inventory").add("carrot_snack", 10)
	state.call("_changed")
	await shot("04_cartao_dar")
	state.call("give_friend", "pipoca")
	await shot("05_petisco_ja_dado")
	state.call("claim_quest", "nina_pipoca")
	state.call("_mark_all_seen")
	main.get("_modal_queue").clear()
	for n in range(2, 7):
		state.set("test_time", state.get("test_time") + 10800)
		state.call("_changed")
		state.get("dog").updated_at = state.get("test_time")
		if n == 3:
			friend_ui.call("open", "pipoca")
			await shot("06_segundo_coracao_antes")
		state.call("give_friend", "pipoca")
		if n == 3:
			await shot("07_segundo_coracao_bonus")
	await shot("08_melhor_amiga")
	var ui: Script = load("res://scripts/ui/progression_ui.gd")
	ui.set("_collection_tab", "friends")
	events.emit_signal("sheet_requested", "Coleção", ui.call("collection_panel"))
	await shot("11_colecao_silhuetas")
	events.emit_signal("sheet_close_requested")
	state.call("_changed")
	await create_timer(1.0).timeout
	main.get("_celebration").hide()
	for n in 3:
		var visitor: String = state.call("friends_present")[1]
		main.call("_on_world_requested", "park", "look:friend:" + visitor)
		await shot("09_visitante_" + visitor)
		state.get("inventory").add(str(state.call("friend_def", visitor).likes), 1)
		state.call("give_friend", visitor)
		friend_ui.call("open", visitor)
		await shot("10_cartao_" + visitor)
		events.emit_signal("sheet_close_requested")
		state.set("test_time", state.get("test_time") + 10800)
		state.call("_changed")
	ui.set("_collection_tab", "friends")
	events.emit_signal("sheet_requested", "Coleção", ui.call("collection_panel"))
	await shot("11_colecao_amigos")
	var scroll: ScrollContainer = main.find_child("Sheet").get_node("Panel/VBox/Scroll")
	scroll.scroll_vertical = 10000
	await shot("11_colecao_fim")
	ui.set("_collection_tab", "clothes")
	events.emit_signal("sheet_requested", "Coleção", ui.call("collection_panel"))
	await process_frame
	scroll.scroll_vertical = 10000
	await shot("11b_bandana_colecao")
	events.emit_signal("sheet_requested", "Passeios", ui.call("walks_panel"))
	state.get("progress").owned["walk_bag"] = true
	state.get("dog").updated_at = state.get("test_time")
	state.get("dog").needs.energy = 100.0
	state.call("_changed")
	await shot("12_bonus_passeio")
	events.emit_signal("sheet_close_requested")
	var since: float = state.get("test_time")
	state.set("test_time", since + 28801)
	state.call("update_friend_visits", since)
	main.call("_on_world_requested", "house", "look:friend_visit:pipoca")
	await shot("13_visita_casa")
	main.get("_welcome").call("open")
	await shot("14_boas_vindas")
	main.get("_welcome").hide()
	state.call("collect_friend_visit", "pipoca")
	await shot("15_presente_coletado")
	print("FRIENDS SHOTS: PASS")
	quit()

func shot(id: String) -> void:
	await create_timer(0.6).timeout
	var folder := ProjectSettings.globalize_path("res://../build/screenshots/etapa09")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(id + ".png"))
