extends SceneTree
## Etapa 07: requisitos, primeira volta, garantia por caminho, consolo, save e diário.

var state: Node
var db: Node
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Passeios: " + message)


func _rest() -> void:
	state.get("dog").sleeping = false
	state.get("dog").needs["energy"] = 100.0
	state.get("dog").updated_at = state.call("now")


func _collect(id: String) -> Dictionary:
	_rest()
	check(state.call("start_walk", id) == "", "começa " + id)
	state.get("walk_state").current["ready_at"] = 0.0
	return state.call("collect_walk")


func _run() -> void:
	root.size = Vector2i(360, 780)
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.call("reset")
	# Estas voltas se acumulam sem vender nada: o limite da sacola (etapa 08) tem teste próprio (chest_test).
	state.set("unlimited_storage", true)
	var progress: RefCounted = state.get("progress")
	progress.claimed_quests["main_2_order"] = true
	progress.claimed_quests["nina_meet"] = true
	progress.claimed_quests["nina_walk"] = true
	check(state.call("walk_lock_error", "flower_street") != "", "Flores exige 3")
	progress.count("walk", 3)
	check(state.call("walk_lock_error", "flower_street") == "", "Flores abre com 3")
	check((state.call("new_unlocks") as Array).has("walk:flower_street"), "Novo! inclui passeio")
	check(state.call("walk_lock_error", "village_fair") != "", "Feira exige 6")
	progress.count("walk", 3)
	check(state.call("walk_lock_error", "village_fair") == "", "Feira abre com 6")
	check(state.call("walk_lock_error", "creek_walk") != "", "Riacho exige Bosque e vínculo")
	progress.owned["forest_open"] = true
	state.get("dog").affection = 0
	state.get("dog").affection = 9999
	check(state.call("walk_lock_error", "creek_walk") == "Quando ele for Aventureiro", "Riacho espera o Tiro ser Aventureiro (etapa 11)")
	state.get("growth").phase = "explorer"
	state.get("dog").affection = 0
	check(state.call("walk_lock_error", "creek_walk") != "", "Bosque sozinho não libera")
	var levels: Array = db.get("progression").bond_levels
	state.get("dog").affection = int(levels[2].affection)
	check(state.call("walk_lock_error", "creek_walk") == "", "Riacho abre vínculo 3 + Bosque")
	progress.owned.erase("forest_open")
	check(state.call("walk_lock_error", "creek_walk") != "", "vínculo sozinho não libera")
	progress.count("walk", 9)
	check(state.call("walk_lock_error", "bird_clearing") != "", "Clareira precisa vínculo 4")
	state.get("dog").affection = int(levels[3].affection)
	check(state.call("walk_lock_error", "bird_clearing") == "", "Clareira abre 15 + vínculo 4")
	check(state.call("walk_lock_error", "hill_view") != "", "Mirante fechado")
	progress.count("walk", 10)
	check(state.call("walk_lock_error", "hill_view") != "", "Mirante precisa vínculo 5")
	state.get("dog").affection = int(levels[4].affection)
	check(state.call("walk_lock_error", "hill_view") == "", "Mirante abre 25 + vínculo 5")
	for hour in [0, 16, 21, 23]:
		check(state.call("walk_hours_error", "sunset_walk", hour) == "Abre às 17h", "pôr do sol fechado às %dh" % hour)
	for hour in [17, 18, 20]:
		check(state.call("walk_hours_error", "sunset_walk", hour) == "", "pôr do sol aberto às %dh" % hour)
	# Exercita também start_walk com a hora real, alterando apenas a janela de dados no teste.
	var sunset: Dictionary = db.get("walks").walks.sunset_walk
	var actual: int = Time.get_datetime_dict_from_unix_time(state.call("_local_time")).hour
	sunset.requirements.hours = [(actual + 1) % 24, (actual + 2) % 24]
	_rest()
	check(state.call("start_walk", "sunset_walk") == "Abre às %dh" % ((actual + 1) % 24), "começar fora da janela bloqueado")
	sunset.requirements.hours = [actual, (actual + 1) % 24]
	check(state.call("start_walk", "sunset_walk") == "", "começar dentro da janela")
	sunset.requirements.hours = [(actual + 1) % 24, (actual + 2) % 24]
	state.get("walk_state").current["ready_at"] = 0.0
	check(not (state.call("collect_walk") as Dictionary).is_empty(), "recolher fora da janela permitido")
	sunset.requirements.hours = [17, 21]
	# Força a ausência de sorte para medir a garantia sem depender da seed.
	state.call("reset")
	progress = state.get("progress")
	progress.claimed_quests["main_2_order"] = true
	progress.claimed_quests["nina_meet"] = true
	var rare: Dictionary = db.get("walks").walks.park_loop.loot.rare
	var chance := float(rare.chance)
	rare.chance = 0.0
	for i in 6:
		var result := _collect("park_loop")
		check(bool(result.first) == (i == 0), "first só na volta 1")
		if i == 0:
			check(int(result.items.get("stick", 0)) >= 2 and int(result.items.get("ribbon", 0)) >= 1, "primeira volta garante materiais")
			check((result.new_items as Array).has("stick"), "material novo marcado")
		check((str(result.rare) == "plaid_bow") == (i == 5), "garantia na sexta volta")
		if i < 5:
			check(state.call("walk_pity_left", "park_loop") == 5 - i, "garantia decresce")
		check(state.call("walk_pity_left", "flower_street") == 8, "garantia independente por caminho")
	check(progress.stat("walk_rare") == 1 and progress.stat("walk_rare:park_loop") == 1, "contadores de raro")
	check(progress.collection.has("plaid_bow") and state.get("walk_state").pity.park_loop == 0, "coleção e garantia zerada")
	check(state.call("walk_pity_left", "park_loop") == 0, "diário indica raro encontrado")
	var total := 0
	for item: String in db.get("items"):
		total += progress.stat("walk_item:" + item)
	check(progress.stat("walk_item") == total and total >= 3, "total walk_item soma quantidades")
	var before: int = progress.stat("walk")
	check((state.call("collect_walk") as Dictionary).is_empty() and progress.stat("walk") == before, "não duplica coleta")
	state.get("walk_state").pity.park_loop = 5
	var consolo := _collect("park_loop")
	check(consolo.rare == "" and consolo.rare_duplicate and consolo.rare_item == "plaid_bow", "duplicado vira consolo")
	check(int(consolo.coins) >= 26 and int(consolo.items.get("ribbon", 0)) >= 1, "moedas e material de consolo")
	check(progress.stat("walk_rare") == 1 and state.get("walk_state").pity.park_loop == 0, "consolo não conta novo raro")
	rare.chance = chance
	_rest()
	state.call("start_walk", "flower_street")
	var loot: Dictionary = state.call("walk_loot")
	var saved: Dictionary = state.call("to_dict").duplicate(true)
	state.call("from_dict", saved)
	check(state.call("walk_loot") == loot, "first/rare/loot estáveis no save")
	check(state.get("walk_state").history.park_loop.count == 7, "histórico preservado")
	state.call("cancel_walk")
	check(not state.get("walk_state").history.has("flower_street"), "cancelar não gasta primeira volta")
	var flowers := _collect("flower_street")
	check(flowers.first and int(flowers.items.get("wildflower", 0)) >= 3, "Flores garante 3 flores na primeira")
	var help: Script = load("res://scripts/ui/task_help.gd")
	check(help.call("best_source", "wild_mint").get("kind", "") == "walk", "ajuda de ingrediente aponta ao passeio")
	check(help.call("describe", "item", "wild_mint", 2).target.get("world", "") == "park", "Como fazer leva à Praça")
	check(state.call("cook_error", "mint_snack") != "", "petisco bloqueado antes da Clareira")
	state.get("progress").owned["stove"] = true
	state.get("progress").count("walk:bird_clearing", 1)
	state.get("inventory").add("wild_mint", 2)
	state.get("inventory").add("carrot", 1)
	check(state.call("cook", "mint_snack") == "", "petisco usa materiais do passeio")
	state.call("dev_finish_timers")
	state.call("collect", "stove")
	check(state.get("inventory").count("mint_snack") == 1 and state.call("feed", "mint_snack"), "petisco recolhido alimenta")
	await _ui_checks()
	await _announce_checks()
	print("WALKS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(0 if failures == 0 else 1)


func _ui_checks() -> void:
	var ui: Script = load("res://scripts/ui/progression_ui.gd")
	var diary: Control = ui.call("walk_diary")
	diary.theme = load("res://assets/theme/main_theme.tres")
	root.add_child(diary)
	await process_frame
	check(diary.find_child("Diary_park_loop", true, false) != null, "diário tem passeio")
	check(diary.find_child("Material_stick", true, false).modulate == Color.WHITE, "material encontrado colorido")
	check(diary.find_child("Rare_flower_clip", true, false) != null, "diário tem raro em silhueta")
	var found_pity := false
	for node: Node in diary.find_children("Pity", "Label", true, false):
		found_pity = found_pity or "Raro garantido em até" in (node as Label).text
	check(found_pity, "garantia visível no diário")
	diary.queue_free()
	var clothes: Control = ui.call("_clothes_panel")
	root.add_child(clothes)
	await process_frame
	check(clothes.find_child("RareHint_glow_collar", true, false) != null, "Coleção mostra também raro bloqueado")
	clothes.queue_free()
	var card: CanvasLayer = load("res://scenes/ui/walk_result/walk_result.tscn").instantiate()
	root.add_child(card)
	card.call("show_result", {"name": "Volta na praça", "postcard": state.call("walk_postcard", "park_loop"), "first": true, "rare": "plaid_bow", "items": {"stick": 2, "ribbon": 1}, "new": ["stick"]})
	await process_frame
	await process_frame
	check(card.find_child("FirstTime", true, false) != null and card.find_child("RareStar", true, false) != null, "primeira vez e festa do raro")
	var panel: PanelContainer = card.get("_panel")
	check(panel.size.y <= root.get_visible_rect().size.y - 31.0, "cartão raro cabe e rola")
	card.call("show_result", {"name": "Clareira dos passarinhos", "postcard": state.call("walk_postcard", "bird_clearing"), "first": true, "rare": "explorer_backpack", "items": {"bird_feather": 2, "wild_mint": 3, "wildflower": 1, "pinecone": 1, "creek_shell": 1}, "new": ["bird_feather", "wild_mint", "wildflower", "pinecone", "creek_shell"], "coins": 30, "affection": 7, "needs": {"happiness": 35, "hygiene": -20}})
	await process_frame
	await process_frame
	var scroll: ScrollContainer = card.find_child("WalkResultScroll", true, false)
	scroll.scroll_vertical = 10000
	await process_frame
	var close: Button = card.find_child("CloseResult", true, false)
	check(scroll.get_global_rect().encloses(close.get_global_rect()), "Oba inteiro acessível no cartão grande")
	close.pressed.emit()
	check(not card.visible, "Oba fecha cartão grande")
	card.queue_free()
	await process_frame


func _announce_checks() -> void:
	state.get("progress").stats["walk"] = 2
	state.get("progress").seen["intro"] = true
	state.call("_mark_all_seen")
	state.get("progress").seen.erase("walk:flower_street")
	state.get("progress").seen.erase("feature:walk_diary")
	var main: Control = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.get("_modal_queue").clear()
	_collect("park_loop")
	main.call("_flush_modals")
	var result: CanvasLayer = main.get("_walk_result")
	check(result.visible, "cartão de volta aparece antes do Novo!")
	result.hide()
	main.call("_flush_modals")
	check(main.get_node("Celebration").visible, "passeio novo anunciado sem receber missão")
	check(state.get("progress").seen.has("walk:flower_street"), "passeio anunciado fica visto")
	main.get_node("Celebration").hide()
	root.get_node("Events").emit_signal("sheet_requested", "Diário de passeios", load("res://scripts/ui/progression_ui.gd").call("walk_diary"))
	await create_timer(0.4).timeout
	var sheet_panel: Control = main.get_node("Sheet").get_node("%Panel")
	check(sheet_panel.get_global_rect().position.x >= -0.5 and sheet_panel.size.x <= root.get_visible_rect().size.x + 0.5, "diário e cabeçalho cabem na largura")
	main.queue_free()
	await process_frame
