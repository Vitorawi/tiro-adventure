extends SceneTree
## Portão 08: recibos, fila modal, sono, acessibilidade e os cinco cartões. Sem campanha.
var failures := 0
var state: Node
var main: Control
var ceremony_script: Script

func _initialize() -> void:
	_run.call_deferred()
	create_timer(170).timeout.connect(func() -> void: quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("CEREMONY: " + message)

func frames(n: int = 4) -> void:
	for i in n: await process_frame

func start_main() -> void:
	state.get("progress").seen.intro = true
	state.call("_mark_all_seen")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await frames()

func remove_main() -> void:
	main.queue_free()
	await frames()

func wait_card() -> void:
	for i in 140:
		if main.find_child("BeforeAfter", true, false) != null: return
		await create_timer(0.05).timeout
	check(false, "cartão abriu antes de 7 s")

func close_card() -> void:
	var button := main.find_child("CloseCeremony", true, false) as Button
	check(button != null, "botão único Que lindo!")
	if button: button.pressed.emit()
	await frames()

func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	ceremony_script = load("res://scenes/ui/growth_ceremony/growth_ceremony.gd")
	state.call("reset")
	Motion.reduced = true
	await start_main()
	check(ceremony_script.MAX_SWITCHES_PER_SECOND <= 3.0, "limite de alternância")
	var total := 0.0
	for interval: float in ceremony_script.SWITCH_INTERVALS:
		check(interval >= 1.0 / 3.0, "intervalo seguro")
		total += interval
	check(is_equal_approx(total, ceremony_script.TRANSFORMATION_SECONDS), "transformação 2,5 s")
	# Percorre o DEV de cada fase anterior; crescimento real preserva recibo/presente.
	var phases: Array = root.get_node("Database").get("growth").phases
	for index in range(1, phases.size()):
		state.call("dev_set_phase", str(phases[index - 1].id))
		if index == 1:
			state.get("progress").claimed_quests["lais_bed"] = true
			check(not state.get("progress").feature_unlocked("wishes"), "caminha sozinha não libera Desejos")
		state.call("dev_complete_growth_reqs")
		check(state.call("grow") == "", "cresce para " + str(phases[index].id))
		main.call("_check_growth_ceremonies")
		main.call("_check_growth_ceremonies")
		check(main.get("_modal_queue").size() == 1, "uma cerimônia por evento")
		main.call("_flush_modals")
		await create_timer(0.1).timeout
		check(not main.get("_growth_ceremony").get("switching"), "reduzido não inicia alternância")
		await wait_card()
		var ceremony: CanvasLayer = main.get("_growth_ceremony")
		check(not ceremony.switching, "reduzido sem piscar")
		check(ceremony.find_child("Confetti", true, false) == null, "reduzido sem confete")
		check(ceremony.find_child("HeightMark", true, false) != null, "régua miniatura")
		check(not main.get("_celebration").visible, "Novo espera fechar a cerimônia")
		await close_card()
		check(state.get("growth").ceremonies[str(phases[index].id)].seen, "visto depois de fechar")
		if index == 1:
			main.call("_flush_modals")
			check(main.get("_celebration").visible and state.get("progress").seen.has("feature:wishes"), "Novo de Desejos depois de Que lindo!")
			main.get("_celebration").hide()
		main.set("_modal_queue", [] as Array[Callable])
		main.get("_celebration").hide()
	# Reiniciar durante a cena retoma só um cartão; confirmar e recarregar não repete.
	await remove_main()
	state.call("reset")
	state.call("dev_complete_growth_reqs")
	state.call("grow")
	var saved: Dictionary = state.call("to_dict")
	state.call("from_dict", saved)
	await start_main()
	await wait_card()
	check(main.get("_modal_queue").is_empty(), "recarga não duplica fila")
	await close_card()
	saved = state.call("to_dict")
	await remove_main()
	state.call("from_dict", saved)
	await start_main()
	check(main.get("_modal_queue").is_empty(), "visto não repete ao reabrir")
	# Mocinho dormindo: fase salva imediatamente, tocar nele acorda e revela.
	state.call("dev_set_phase", "explorer")
	state.call("dev_complete_growth_reqs")
	state.call("set_sleeping", true)
	check(state.call("grow") == "", "cresce dormindo")
	check(state.get("growth").phase == "young" and state.get("growth").pending_reveal == "young", "fase nova e pendência")
	check(main.get("_modal_queue").is_empty(), "sono adia fila")
	saved = state.call("to_dict")
	state.call("from_dict", saved)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	main.find_child("PetScreen", true, false).call("_on_dog_input", press)
	check(not state.get("dog").sleeping, "toque acorda")
	await wait_card()
	await close_card()
	check(state.get("growth").pending_reveal == "", "fecha limpa pendência")
	main.set("_modal_queue", [] as Array[Callable])
	await remove_main()
	# Adulto dormindo ao reabrir: boas-vindas mostra linha, fechar revela.
	state.call("dev_set_phase", "young")
	state.call("dev_complete_growth_reqs")
	state.call("set_sleeping", true)
	state.call("grow")
	saved = state.call("to_dict")
	state.call("from_dict", saved)
	state.get("progress").claimed_quests["lais_bed"] = true
	await start_main()
	main.call("_flush_modals")
	await frames()
	check(main.get("_welcome").find_child("Line_growth", true, false) != null, "boas-vindas do sono")
	main.get("_welcome").call("_close")
	await wait_card()
	await close_card()
	main.set("_modal_queue", [] as Array[Callable])
	await remove_main()
	# Pronto ainda não visto aparece e desaparece quando a linha foi exibida.
	state.call("reset")
	state.call("dev_complete_growth_reqs")
	state.get("progress").claimed_quests["lais_bed"] = true
	await start_main()
	check(state.call("welcome_ready_lines").any(func(row: Dictionary) -> bool: return row.kind == "growth"), "linha pronto não vista")
	main.get("_welcome").call("open")
	check(not state.call("welcome_ready_lines").any(func(row: Dictionary) -> bool: return row.kind == "growth"), "linha some depois de vista")
	saved = state.call("to_dict")
	state.call("from_dict", saved)
	check(state.get("growth").ready_seen == "puppy", "vista persiste")
	main.get("_welcome").call("_close")
	await remove_main()
	print("CEREMONY TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)
