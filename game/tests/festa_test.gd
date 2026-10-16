extends SceneTree
## Etapa 12 (festa): ModalCard (nível, raios, confete, chips que contam), Motion.reduced, Haptics,
## preferências "Vibrar"/"Menos animação" em settings.json e boas-vindas agrupado.
## Perfil isolado; o SaveManager fica sem autosave e o settings.json é restaurado no fim.

var failures := 0
var state: Node
var saver: Node
var events: Node


func _initialize() -> void:
	_run.call_deferred()
	create_timer(60.0).timeout.connect(func() -> void:
		push_error("FESTA: tempo excedido")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FESTA: " + message)


func frames(count: int = 4) -> void:
	for i in count:
		await process_frame


func primary_count(node: Node) -> int:
	var total := 0
	for button: Button in node.find_children("*", "Button", true, false):
		if button.theme_type_variation == &"PrimaryButton":
			total += 1
	return total


func has_text(node: Node, text: String) -> bool:
	for label: Label in node.find_children("*", "Label", true, false):
		if text in label.text:
			return true
	return false


func _run() -> void:
	saver = root.get_node("SaveManager")
	events = root.get_node("Events")
	events.state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", "user://festa_descartavel.json")
	state = root.get_node("GameState")
	state.call("reset")
	state.call("dev_complete_quest", "lais_bed")
	Motion.reduced = false
	Haptics.enabled = true
	await _celebration_checks()
	await _haptics_checks()
	await _settings_checks()
	await _welcome_checks()
	Motion.reduced = false
	Haptics.enabled = true
	print("FESTA TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


func _open_celebration() -> CanvasLayer:
	var celebration: CanvasLayer = load("res://scenes/ui/celebration/celebration.tscn").instantiate()
	root.add_child(celebration)
	return celebration


func _celebration_checks() -> void:
	var rewards := {"coins": 50, "items": {"carrot": 3}}
	var celebration := _open_celebration()
	Haptics.calls.clear()
	celebration.call("show_level", 6, rewards)
	var card := celebration.find_child("ModalCard", true, false) as Control
	check(card != null and card.visible and celebration.visible, "show_level monta um ModalCard")
	check(card.find_child("RibbonTitle", true, false) is Label and "Nível 6!" == (card.find_child("RibbonTitle", true, false) as Label).text, "fita traz o número do nível")
	check(card.find_child("BigIcon", true, false) != null and card.find_child("Rays", true, false) != null, "ícone grande com raios")
	check(((card.get("panel") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat).corner_radius_top_left == 22 and (card.get("panel") as PanelContainer).custom_minimum_size.x == 320.0, "cartão 320 de largura, cantos 22")
	check(primary_count(card) == 1, "um botão principal só (%d)" % primary_count(card))
	check(Haptics.calls == [Haptics.BIG_MS], "nível vibra forte uma vez (%s)" % str(Haptics.calls))
	var chips := (card.get("box") as Control).find_children("*", "HFlowContainer", true, false)[0] as Container
	check(chips.get_child_count() == 2, "dois chips de prêmio")
	for chip: Node in chips.get_children():
		check((chip as Control).modulate.a < 0.01, "chip começa escondido e entra depois")
	await create_timer(1.2).timeout
	for chip: Node in chips.get_children():
		check(is_equal_approx((chip as Control).modulate.a, 1.0), "chip aparece")
	var coin_text := (chips.get_child(0).find_children("*", "Label", true, false)[0] as Label).text
	check(coin_text == "+50", "número de moeda conta até o valor (%s)" % coin_text)
	var confetti := card.find_child("Confetti", true, false) as CPUParticles2D
	check(confetti != null and confetti.amount == 40 and confetti.one_shot and is_equal_approx(confetti.lifetime, 1.6), "confete: 40 partículas, uma vez, 1,6 s")
	check(is_equal_approx((card.get("panel") as Control).modulate.a, 1.0), "cartão apareceu inteiro")
	# O "Novo!" simples e o achado não soltam confete.
	var unlocks: Array[String] = ["place:farm/orchard"]
	celebration.call("show_unlocks", unlocks)
	await frames()
	check(celebration.find_child("Confetti", true, false) == null, "Novo! sem confete")
	# Capítulo, tesouro e vínculo soltam.
	celebration.call("show_chapter", 2, [] as Array[String])
	await frames()
	check(celebration.find_child("Confetti", true, false) != null, "capítulo com confete")
	celebration.call("show_bond", 3, {"coins": 25})
	await frames()
	check(celebration.find_child("Confetti", true, false) != null, "vínculo com confete")
	celebration.call("show_treasure", {"coins": 100, "items": {}})
	await frames()
	check(celebration.find_child("Confetti", true, false) != null and primary_count(celebration) == 1, "tesouro com confete e um botão")
	celebration.call("show_trick", "paw")
	await frames()
	check(celebration.find_child("Confetti", true, false) == null, "truque sem confete")
	# "Menos animação": chips visíveis e com o número final na hora, sem confete.
	Motion.reduced = true
	celebration.call("show_level", 7, rewards)
	card = celebration.find_child("ModalCard", true, false) as Control
	chips = (card.get("box") as Control).find_children("*", "HFlowContainer", true, false)[0] as Container
	for chip: Node in chips.get_children():
		check(is_equal_approx((chip as Control).modulate.a, 1.0), "reduced: chip visível na hora")
	check((chips.get_child(0).find_children("*", "Label", true, false)[0] as Label).text == "+50", "reduced: número final na hora")
	check(card.find_child("Confetti", true, false) == null, "reduced: sem confete")
	check(is_equal_approx((card.get("panel") as Control).modulate.a, 1.0) and is_equal_approx((card.get("dim") as Control).modulate.a, 1.0), "reduced: cartão e fundo na hora")
	Motion.reduced = false
	# Fechar: o botão principal esconde a camada.
	var close: Button = null
	for button: Button in celebration.find_children("*", "Button", true, false):
		if button.text == "Oba!":
			close = button
	check(close != null, "botão Oba!")
	close.pressed.emit()
	check(not celebration.visible, "Oba! fecha")
	celebration.queue_free()
	await frames()


func _haptics_checks() -> void:
	Haptics.enabled = false
	Haptics.calls.clear()
	Haptics.tap()
	Haptics.success()
	Haptics.big()
	Haptics.error()
	Motion.shake(Control.new())
	await create_timer(0.2).timeout
	check(Haptics.calls.is_empty(), "desligado não vibra (%s)" % str(Haptics.calls))
	var celebration := _open_celebration()
	celebration.call("show_level", 8, {"coins": 5})
	check(Haptics.calls.is_empty(), "desligado: comemoração também não vibra")
	celebration.queue_free()
	Haptics.enabled = true
	Haptics.tap()
	Haptics.success()
	Haptics.big()
	check(Haptics.calls == [12, 30, 60], "tap 12, success 30, big 60 (%s)" % str(Haptics.calls))
	Haptics.calls.clear()
	Haptics.error()
	await create_timer(0.3).timeout
	check(Haptics.calls == [20, 20], "erro vibra duas vezes de 20 ms (%s)" % str(Haptics.calls))
	Haptics.calls.clear()
	Motion.shake(Control.new())
	await create_timer(0.3).timeout
	check(Haptics.calls == [20, 20], "Motion.shake de erro vibra (%s)" % str(Haptics.calls))
	Haptics.calls.clear()
	Events_items_gained()
	check(Haptics.calls == [30], "colher/pegar vibra leve (%s)" % str(Haptics.calls))


func Events_items_gained() -> void:
	var fx: Control = load("res://scripts/ui/collect_fx.gd").new()
	root.add_child(fx)
	events.emit_signal("items_gained", {"carrot": 2}, 0, Vector2(100, 300))
	fx.queue_free()


func _settings_checks() -> void:
	var path := "user://settings_dev.json"
	var original := FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var existed := FileAccess.file_exists(path)
	# Painel: duas linhas com Sim/Não.
	var panel: Control = load("res://scripts/ui/settings_panel.gd").call("panel")
	panel.theme = load("res://assets/theme/main_theme.tres")
	root.add_child(panel)
	await frames()
	var vibrate := panel.find_child("VibrateToggle", true, false)
	var reduced := panel.find_child("ReducedMotionToggle", true, false)
	check(vibrate != null and reduced != null, "configurações têm Vibrar e Menos animação")
	check(has_text(panel, "Vibrar") and has_text(panel, "Menos animação"), "textos das preferências")
	check(saver.get("vibrate_enabled") == true and saver.get("reduced_motion") == false, "padrão: vibra, animação normal")
	(vibrate.find_child("NotebookTab_off", true, false) as Button).pressed.emit()
	check(saver.get("vibrate_enabled") == false and Haptics.enabled == false, "Vibrar = Não desliga Haptics")
	await frames()
	reduced = panel.find_child("ReducedMotionToggle", true, false)
	(reduced.find_child("NotebookTab_on", true, false) as Button).pressed.emit()
	check(saver.get("reduced_motion") == true and Motion.reduced == true, "Menos animação = Sim liga Motion.reduced")
	await frames()
	# Fica em settings.json (preferência do aparelho, não do save).
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(typeof(parsed) == TYPE_DICTIONARY and parsed.get("vibrate") == false and parsed.get("reduced_motion") == true, "settings.json guarda as duas preferências")
	check(not state.call("to_dict").has("vibrate") and not state.call("to_dict").has("reduced_motion"), "o save não leva as preferências")
	# Recarregar do disco aplica de novo.
	Haptics.enabled = true
	Motion.reduced = false
	saver.call("_load_settings")
	check(Haptics.enabled == false and Motion.reduced == true, "ao abrir o jogo as preferências voltam")
	saver.call("set_vibrate", true)
	saver.call("set_reduced_motion", false)
	check(Haptics.enabled == true and Motion.reduced == false, "religar volta ao normal")
	panel.queue_free()
	if existed:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(original)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	await frames()


func _welcome_checks() -> void:
	state.call("reset")
	state.call("dev_complete_quest", "lais_bed")
	state.get("progress").owned["farm"] = true
	state.get("progress").seen["intro"] = true
	var worlds: Array = root.get_node("Database").get("finds").worlds.keys()
	check(worlds.size() >= 3, "o faro tem pelo menos três mundos")
	for i in 3:
		state.get("finds").worlds[worlds[i]] = {"next_at": 0.0, "pending": 1, "spot": 0, "dug": 0, "seed": 0}
	state.call("plant", 0, "carrot")
	state.call("plant", 1, "carrot")
	for i in 2:
		state.get("plots")[i]["ready_at"] = float(state.call("now")) - 1.0
	var lines: Array = state.call("welcome_ready_lines")
	var kinds: Array = lines.map(func(line: Dictionary) -> String: return str(line.kind))
	check(kinds.count("dig") == 1 and kinds.count("ready") == 1 and lines.size() == 2, "uma linha por tipo: %s" % str(kinds))
	check(int(lines[0].count) == 3 and lines[0].worlds.size() == 3 and lines[0].world == worlds[0] and lines[0].target == "find", "achados juntos, Ir ao primeiro")
	check(lines[1].world == "farm" and int(lines[1].count) == 2 and lines[1].icons == ["carrot"], "dois canteiros prontos no Sítio, um ícone só")
	var welcome: CanvasLayer = load("res://scenes/ui/welcome_back/welcome_back.tscn").instantiate()
	root.add_child(welcome)
	welcome.call("open")
	await frames()
	var card := welcome.find_child("ModalCard", true, false) as Control
	check(card != null and welcome.visible, "boas-vindas usa o ModalCard")
	var dig_rows := welcome.find_children("Line_dig", "", true, false)
	check(dig_rows.size() == 1 and has_text(dig_rows[0], "3 achados"), "boas-vindas com 3 achados mostra UMA linha de achados")
	var world_icons := 0
	for icon: Node in dig_rows[0].find_children("*", "TextureRect", true, false):
		world_icons += 1
	check(world_icons == 4, "linha de achados: ícone da pata + 3 ícones de mundo (%d)" % world_icons)
	var ready_rows := welcome.find_children("Line_ready_farm", "", true, false)
	check(ready_rows.size() == 1 and has_text(ready_rows[0], "2 prontos no Sítio"), "2 prontos no Sítio")
	check(welcome.find_child("DailyGift", true, false) != null, "presente do dia em destaque")
	var gift_pos := (welcome.find_child("DailyGift", true, false) as Control).get_parent().get_index()
	var dig_pos := (dig_rows[0] as Control).get_index()
	check(gift_pos < dig_pos, "presente vem antes das linhas")
	check(primary_count(welcome) == 1, "um botão principal só (%d)" % primary_count(welcome))
	# Tocar na linha leva ao primeiro (fecha o cartão).
	var visited: Array = []
	events.connect("world_requested", func(world: String, target: String) -> void: visited.append([world, target]))
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	(dig_rows[0] as Control).gui_input.emit(click)
	await frames()
	check(not welcome.visible, "tocar na linha fecha o cartão")
	check(visited == [[str(worlds[0]), "find"]], "tocar na linha vai ao primeiro mundo do achado (%s)" % str(visited))
	# Sem presente, "Vamos lá!" vira o botão principal.
	state.call("claim_daily_gift")
	welcome.call("open")
	await frames()
	check(primary_count(welcome) == 1 and welcome.find_child("DailyGift", true, false) == null, "sem presente: Vamos lá! é o principal")
	welcome.queue_free()
	await frames()
