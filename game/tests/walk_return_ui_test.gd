extends SceneTree
## Etapa 03 da economia R1, interface: o Tiro volta mesmo com a bagagem impossível de guardar.
## Toque real (mouse emulado no viewport) nas três resoluções: cantinho do Tiro, Mochila, painel da Praça e cartão da volta.
## --headless --path game -s res://tests/walk_return_ui_test.gd   (sem --headless grava capturas em build/economy/etapa_03/depois)

const SIZES: Array[Vector2i] = [Vector2i(360, 780), Vector2i(390, 844), Vector2i(412, 915)]
const T0 := 1791936000.0

var failures := 0
var state: Node
var db: Node
var main: Control
var requested: Array = []


func _initialize() -> void:
	_run.call_deferred()
	create_timer(150.0).timeout.connect(func() -> void:
		push_error("WALK RETURN UI: tempo excedido")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("WALK RETURN UI: " + message)


func frames(count: int = 8) -> void:
	for i in count:
		await process_frame


func click(button: Control) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = root.get_final_transform() * (button.get_global_transform_with_canvas() * (button.size * 0.5))
		root.push_input(event)
	await frames()


func has_text(node: Node, text: String) -> bool:
	for label: Label in node.find_children("*", "Label", true, false):
		if text in label.text:
			return true
	for button: Button in node.find_children("*", "Button", true, false):
		if text in button.text:
			return true
	return false


func shot(tag: String, name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://").path_join("../build/economy/etapa_03/depois").simplify_path()
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join("%s_%s.png" % [name, tag]))


func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	db = root.get_node("Database")
	state.set_script(load("res://tests/friend_clock.gd"))
	root.get_node("Events").connect("world_requested", func(world: String, place: String) -> void: requested.append([world, place]))
	Motion.reduced = true
	for size in SIZES:
		await _scenario(size)
	print("WALK RETURN UI TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


func _scenario(size: Vector2i) -> void:
	var tag := "%dx%d" % [size.x, size.y]
	root.size = size
	state.set("test_time", T0)
	state.set("unlimited_storage", false)
	state.call("reset")
	var progress: RefCounted = state.get("progress")
	progress.claimed_quests["main_2_order"] = true
	progress.claimed_quests["nina_meet"] = true
	progress.claimed_quests["nina_walk"] = true
	progress.seen["intro"] = true
	state.call("_mark_all_seen")
	state.get("dog").needs["energy"] = 100.0
	state.get("dog").updated_at = T0
	# Gravetos e fitas moram na sacola do baú (etapa 08); o teste a encolhe para 4 (provisória) e a deixa cheia.
	var def: Dictionary = db.get("walks").walks.park_loop
	var loot_before: Dictionary = def.loot.duplicate(true)
	def.loot = {"rolls": 1, "table": [{"weight": 1, "items": {"stick": 3}}], "first": {"items": {"stick": 2, "ribbon": 1}}}
	db.get("progression").storage.chest["prebuild_capacity"] = 4
	state.get("inventory").add("stick", 4)
	requested.clear()
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames(10)
	var pet: Control = main.find_child("PetScreen", true, false)
	check(state.call("start_walk", "park_loop") == "", "%s: sai" % tag)
	await frames()
	check(pet.find_child("AwayView", true, false).visible, "%s: viagem em curso mostra o AwayView" % tag)
	check(not pet.find_child("CollectWalk", true, false).visible, "%s: nada para guardar enquanto viaja" % tag)
	await shot(tag, "pet_viajando")
	# O tempo acaba: o tick liquida, o Tiro volta e o cartão da volta entra na fila.
	state.set("test_time", T0 + 120.0)
	state.call("return_due_walk")
	await frames(4)
	for wait in 20:
		if (main.get("_walk_result") as CanvasLayer).visible:
			break
		await create_timer(0.1).timeout
	await frames(2)
	check(not pet.find_child("AwayView", true, false).visible, "%s: AwayView some com a bagagem impossível de guardar" % tag)
	check(db.get("walks").settings.away_text != pet.find_child("MoodLabel", true, false).text, "%s: o texto não diz que está passeando" % tag)
	var walk_card: CanvasLayer = main.get("_walk_result")
	check(walk_card.visible, "%s: cartão da volta aparece uma vez (celebração=%s boas-vindas=%s fila=%d)" % [tag, main.get("_celebration").visible, main.get("_welcome").visible, (main.get("_modal_queue") as Array).size()])
	var close: Button = walk_card.find_child("CloseResult", true, false)
	var store_card: Button = walk_card.find_child("StoreBaggage", true, false)
	check(close != null and store_card != null and store_card.text == "Ver bagagem", "%s: cartão oferece Ver bagagem (não cabe) e Depois" % tag)
	check(has_text(walk_card, "De volta!"), "%s: título do cartão" % tag)
	check(not state.call("walk_result_unseen"), "%s: abrir o cartão marca como visto" % tag)
	await shot(tag, "cartao_bloqueado")
	# "Ver bagagem" no cartão: fecha e leva ao portão da Praça, sem mexer no inventário.
	var sticks: int = state.get("inventory").count("stick")
	await click(store_card)
	check(not walk_card.visible and requested.size() >= 1 and requested[requested.size() - 1][0] == "park", "%s: Ver bagagem leva à Praça: %s" % [tag, str(requested)])
	check(state.get("inventory").count("stick") == sticks, "%s: nada entrou sem espaço" % tag)
	main.call("show_screen", &"pet")
	await frames()
	var collect: Button = pet.find_child("CollectWalk", true, false)
	check(collect.visible and collect.text == "Ver bagagem", "%s: cantinho do Tiro mostra Ver bagagem" % tag)
	check(collect.size.x >= 44 and collect.size.y >= 44 and root.get_visible_rect().encloses(Rect2(collect.global_position, collect.size)), "%s: botão na tela e com alvo grande" % tag)
	var care_button := pet.find_child("CareButton", true, false) as Control
	check(not collect.get_global_rect().intersects(care_button.get_global_rect()), "%s: bagagem não cobre Cuidar" % tag)
	await click(care_button)
	check(not collect.visible, "%s: roleta aberta recolhe o botão da bagagem" % tag)
	await click(care_button)
	check(collect.visible, "%s: fechar roleta devolve a bagagem" % tag)
	await shot(tag, "pet_bagagem_bloqueada")
	requested.clear()
	await click(collect)
	check(requested.size() == 1 and requested[0][0] == "park", "%s: toque leva à Praça" % tag)
	# Trocar de aba e de mundo não perde a bagagem nem o botão.
	main.call("show_screen", &"map")
	await frames()
	main.call("show_screen", &"pet")
	await frames()
	check(state.call("walk_ready") and pet.find_child("CollectWalk", true, false).visible, "%s: trocar de aba mantém a bagagem" % tag)
	# Cuidar continua livre.
	check(state.call("walk_error", "park_loop").contains("sem espaço"), "%s: novo passeio explica o depósito" % tag)
	var care: Control = pet.find_child("SleepButton", true, false)
	check(care != null and not care.disabled, "%s: dormir liberado com a bagagem esperando" % tag)
	# Mochila: cartão da bagagem com o motivo e sem botão de guardar.
	main.call("show_screen", &"bag")
	await frames()
	var bag: Control = main.find_child("BagScreen", true, false)
	var baggage: Control = bag.find_child("WalkBaggage", true, false)
	check(baggage != null and bag.find_child("BaggageBlocked", true, false) != null and bag.find_child("StoreBaggage", true, false) == null, "%s: Mochila mostra a bagagem bloqueada" % tag)
	check(baggage != null and has_text(baggage, "Sacola de passeio sem espaço"), "%s: motivo nomeia a sacola" % tag)
	check(baggage != null and root.get_visible_rect().encloses(Rect2(baggage.global_position, baggage.size)), "%s: cartão cabe na tela" % tag)
	await shot(tag, "mochila_bagagem_bloqueada")
	# Painel da Praça.
	var panel: Control = load("res://scripts/ui/progression_ui.gd").call("walks_panel")
	main.call("show_screen", &"pet")
	root.get_node("Events").emit_signal("sheet_requested", "Passeios", panel)
	await frames(12)
	check(panel.find_child("WalkSlot", true, false) != null and panel.find_child("BaggageBlocked", true, false) != null, "%s: painel mostra a bagagem" % tag)
	check(panel.find_child("Baggage_stick", true, false) != null and panel.find_child("Baggage_ribbon", true, false) != null, "%s: achados em ícones" % tag)
	check((panel.find_child("StartWalk_park_loop", true, false) as Button).disabled, "%s: Passear bloqueado até esvaziar" % tag)
	await shot(tag, "painel_bloqueado")
	requested.clear()
	var go: Button = panel.find_child("GoDepot", true, false)
	check(go != null and go.text.contains("Sacola de passeio"), "%s: botão para a sacola" % tag)
	if go:
		await click(go)
		check(requested.size() == 1 and requested[0][0] == "house", "%s: o botão da sacola leva à Casa" % tag)
	root.get_node("Events").emit_signal("sheet_close_requested")
	await frames(12)
	# Abre espaço: o toque real guarda por parcelas.
	state.get("inventory").remove("stick", 2)
	state.call("_changed")
	await frames()
	main.call("show_screen", &"bag")
	await frames()
	var store: Button = bag.find_child("StoreBaggage", true, false)
	check(store != null and store.size.y >= 44, "%s: Guardar achados aparece com 2 vagas" % tag)
	await shot(tag, "mochila_parcela")
	if store:
		await click(store)
	check(state.get("inventory").count("stick") == 4 and int(state.get("walk_state").baggage_count()) == 4, "%s: guardou 2 gravetos, 4 esperam" % tag)
	check(state.get("progress").stat("walk_item") == 2, "%s: contador só dos itens que entraram" % tag)
	main.call("show_screen", &"pet")
	await frames()
	collect = pet.find_child("CollectWalk", true, false)
	check(collect.visible and collect.text == "Ver bagagem", "%s: o que sobrou segue esperando" % tag)
	# Esvazia: o botão do Tiro vira Guardar achados e guarda o resto.
	state.get("inventory").remove("stick", 4)
	state.call("_changed")
	await frames()
	check(collect.visible and collect.text == "Guardar achados", "%s: com espaço o botão diz Guardar achados" % tag)
	await shot(tag, "pet_guardar")
	await click(collect)
	check(not state.call("walk_ready") and not pet.find_child("CollectWalk", true, false).visible, "%s: tudo guardado, botão some" % tag)
	check(state.get("inventory").count("stick") == 3 and state.get("inventory").count("ribbon") == 1, "%s: nada perdido: %d gravetos" % [tag, state.get("inventory").count("stick")])
	check(state.get("progress").stat("walk_item") == 6 and state.get("progress").stat("walk") == 1, "%s: contadores únicos" % tag)
	check(not state.get("walk_state").has_baggage(), "%s: bagagem encerrada" % tag)
	main.queue_free()
	await frames()
	def.loot = loot_before
	db.get("progression").storage.chest["prebuild_capacity"] = 12
