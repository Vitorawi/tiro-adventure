extends SceneTree
## Interface 2, etapa 02: contratos públicos, toque, estados e movimento reduzido das peças.

var failures := 0
var kit: Script
var host: Control
var tex: Texture2D


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("UI2_KIT: " + message)


func mount(node: Control) -> Control:
	host.add_child(node)
	return node


func _tap(button: BaseButton) -> void:
	var point := root.get_final_transform() * button.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = point
	root.push_input(move)
	await process_frame
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = point
		click.global_position = point
		click.pressed = pressed
		root.push_input(click)
		await process_frame


func _run() -> void:
	var saver := root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	kit = load("res://scripts/ui/ui_kit.gd")
	host = Control.new()
	host.theme = load("res://assets/theme/main_theme.tres")
	root.add_child(host)
	host.size = Vector2(360, 780)
	tex = kit.call("ui_icon", "coin")
	Motion.reduced = true
	_caso_alvos_e_variacoes()
	_caso_chips()
	await _caso_stepper()
	_caso_tiles()
	_caso_segmented()
	_caso_steps()
	await _caso_toggle()
	_caso_rings()
	_caso_slots()
	_caso_motion()
	await _caso_lista()
	host.free()
	Motion.reduced = false
	print("UI2_KIT TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _caso_alvos_e_variacoes() -> void:
	var noop := func() -> void: pass
	for spec: Array in [["primary", "PrimaryButton"], ["soft", "SecondaryButton"], ["small_go", "SmallGoButton"], ["ghost", "GhostButton"]]:
		var control: Button = mount(kit.call(spec[0], "Ação", noop))
		check(control.theme_type_variation == StringName(spec[1]), str(spec[0]) + " preserva a variação")
		_target(control, str(spec[0]))
		control.free()
	for px: int in [40, 32]:
		var control: Button = mount(kit.call("ctl_button", "x", noop, px))
		_target(control, "ctl_button %d" % px)
		check(control.find_child("Disc", true, false) != null, "controle tem superfície própria")
		control.free()
	var icon: Button = mount(kit.call("icon_button", null, noop, 32, "?"))
	_target(icon, "ajuda legada")
	check(icon.icon == kit.call("ctl_icon", "help"), "ajuda legada usa vetor")
	icon.free()
	var tile: Button = mount(kit.call("tile", tex, "Item"))
	_target(tile, "tile")
	tile.free()


func _target(control: Control, message: String) -> void:
	var minimum := control.get_combined_minimum_size()
	check(minimum.x >= 44 and minimum.y >= 44, message + " tem alvo mínimo de 44×44")


func _caso_chips() -> void:
	var colors: Array[Color] = [Palette.SUNKEN, Palette.HONEY_SOFT, Palette.SKY_SOFT, Palette.GO_SOFT, Palette.ALERT_SOFT]
	var kinds := ["neutral", "prize", "time", "have", "missing"]
	for i in kinds.size():
		var chip: PanelContainer = mount(kit.call("chip", null, "2", null, kinds[i]))
		check((chip.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.is_equal_approx(colors[i]), "fundo do chip " + kinds[i])
		check(chip.get_combined_minimum_size().y == 28, "chip de 28 px")
		if kinds[i] in ["have", "time"]:
			var expected: Texture2D = kit.call("ctl_icon", "check" if kinds[i] == "have" else "clock")
			check(_has_texture(chip, expected), "chip contém controle " + kinds[i])
		chip.free()
	var legacy: Control = mount(kit.call("chip", tex, "2", Palette.ALERT_INK))
	check((legacy.find_children("*", "Label", true, false)[0] as Label).get_theme_color("font_color") == Palette.ALERT_INK, "cor legada do chip continua válida")
	legacy.free()


func _has_texture(node: Node, texture: Texture2D) -> bool:
	for picture: Node in node.find_children("*", "TextureRect", true, false):
		if (picture as TextureRect).texture == texture: return true
	return false


func _caso_stepper() -> void:
	var values: Array[int] = []
	var row: Control = mount(kit.call("stepper", 1, 1, 3, func(value: int) -> void: values.append(value)))
	for i in 4: await process_frame
	var minus := row.find_child("Minus", true, false) as Button
	var plus := row.find_child("Plus", true, false) as Button
	_target(minus, "menos")
	_target(plus, "mais")
	check(minus.disabled and not plus.disabled, "limite inferior desliga só menos")
	await _tap(plus)
	check(values == [2], "toque mais chama cb(2) uma vez")
	row.free()
	row = mount(kit.call("stepper", 3, 1, 3, func(_value: int) -> void: pass))
	check((row.find_child("Plus", true, false) as Button).disabled, "limite superior desliga mais")
	check(row.find_child("QuantityMax", true, false) == null, "sem max_label não há atalho")
	row.free()
	# Ajustes, etapa 04: `max_label` acrescenta a pílula QuantityMax (vai ao máximo; apagada e sem toque no limite).
	var picked: Array[int] = []
	row = mount(kit.call("stepper", 1, 1, 5, func(value: int) -> void: picked.append(value), "Tudo"))
	for i in 4: await process_frame
	var all := row.find_child("QuantityMax", true, false) as Button
	check(all != null and all.text == "Tudo", "QuantityMax mostra o texto pedido")
	if all:
		_target(all, "tudo")
		check(all.modulate.a == 1.0 and all.mouse_filter != Control.MOUSE_FILTER_IGNORE, "no meio do caminho o Tudo está aceso")
		all.pressed.emit()
		check(picked == [5], "Tudo chama cb(máximo)")
	row.free()
	row = mount(kit.call("stepper", 5, 1, 5, func(_value: int) -> void: pass, "Tudo"))
	var dim := row.find_child("QuantityMax", true, false) as Button
	check(dim != null and dim.modulate.a < 0.6 and dim.mouse_filter == Control.MOUSE_FILTER_IGNORE, "no máximo o Tudo fica apagado e sem toque")
	row.free()


func _caso_tiles() -> void:
	for state: String in ["missing", "locked", "selected"]:
		var tile: Button = mount(kit.call("tile", tex, "Item", state, tex))
		if state == "missing":
			var mark := tile.find_child("Missing", true, false)
			check(mark != null and _has_texture(mark, tex), "falta mostra o ingrediente no mini disco")
		if state == "locked":
			check(_has_texture(tile, kit.call("ctl_icon", "lock")), "bloqueio usa cadeado vetor")
		if state == "selected":
			var style := tile.get_theme_stylebox("normal") as StyleBoxFlat
			check(style.border_width_left >= 2 and style.border_color == Palette.INK, "seleção tem contorno de tinta")
		tile.free()


func _caso_segmented() -> void:
	var entries: Array[Dictionary] = [{"id": "a", "text": "Itens", "count": 2, "icon": tex}, {"id": "b", "text": "Fotos", "alert": true}]
	var row: Control = mount(kit.call("segmented", entries, "a", func(_id: String) -> void: pass))
	for id: String in ["a", "b"]:
		var tab := row.find_child("NotebookTab_" + id, true, false) as Button
		_target(tab, "aba " + id)
		var mark := tab.find_child("NewBadge", true, false) as Label
		check(mark != null and mark.text == ("2" if id == "a" else ""), "aba mostra contador/pontinho")
	var selected := row.find_child("NotebookTab_a", true, false) as Button
	check((selected.get_theme_stylebox("normal") as StyleBoxFlat).bg_color == Palette.CARD, "aba ativa branca")
	row.free()
	var one_entry: Array[Dictionary] = [{"id": "only", "text": "História"}]
	var single: Control = mount(kit.call("segmented", one_entry, "only", func(_id: String) -> void: pass))
	single.name = "SingleTabs"
	check(not single.visible and single.get_child_count() == 0 and single.custom_minimum_size == Vector2.ZERO, "uma opção preserva o contêiner, sem desenho nem altura")
	single.free()
	var links: Control = mount(kit.call("section_links", entries, "a", func(_id: String) -> void: pass))
	check(links.find_child("NotebookTab_b", true, false) != null, "links secundários mantêm destinos e nomes das abas")
	links.free()


func _caso_steps() -> void:
	var steps: HBoxContainer = mount(kit.call("steps", 6, 2))
	check(steps.get_child_count() == 6, "seis passos")
	for i in 6:
		var color := (steps.get_child(i).get_theme_stylebox("panel") as StyleBoxFlat).bg_color
		check(color == (Palette.GO if i < 2 else (Palette.HONEY if i == 2 else Palette.SUNKEN)), "cor do passo %d" % i)
	steps.free()


func _caso_toggle() -> void:
	var values: Array[bool] = []
	var toggle: Button = mount(kit.call("toggle", false, func(value: bool) -> void: values.append(value)))
	_target(toggle, "interruptor")
	for i in 4: await process_frame
	await _tap(toggle)
	check(values == [true] and toggle.button_pressed, "toque muda estado e chama cb(true)")
	var track := toggle.find_child("Track", true, false) as Panel
	check((track.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == Palette.GO, "interruptor ligado tem trilho verde")
	check((toggle.find_child("Knob", true, false) as Control).position.x == 23, "bolinha chega sem animação")
	toggle.free()


func _caso_rings() -> void:
	var default_ring := RingProgress.new()
	check(default_ring.custom_minimum_size == Vector2(56, 56), "anel padrão preservado")
	default_ring.free()
	var ring: Control = kit.call("ring", tex, 0.5, Palette.HONEY, 44)
	check(ring.custom_minimum_size == Vector2(44, 44), "atalho de anel 44×44")
	ring.free()


func _caso_motion() -> void:
	var node := Control.new()
	mount(node)
	Motion.fly_arc(node, Vector2.ZERO, Vector2(20, 30))
	check(node.position == Vector2(20, 30), "voo reduzido termina no mesmo quadro")
	node.modulate.a = 0
	Motion.stagger_in([node])
	check(node.modulate.a == 1, "entrada reduzida aparece no mesmo quadro")
	node.free()
	# O efeito de chegada pode liberar o ícone no mesmo quadro do último passo do arco.
	Motion.reduced = false
	var flying := Control.new()
	mount(flying)
	var flying_id := flying.get_instance_id()
	Motion.fly_arc(flying, Vector2.ZERO, Vector2(20, 30), 0.08)
	var arrival := flying.create_tween()
	arrival.tween_interval(0.08)
	arrival.tween_callback(flying.queue_free)
	await create_timer(0.16).timeout
	check(not is_instance_id_valid(flying_id), "chegada libera o ícone sem callback com captura morta")
	Motion.reduced = true


func _caso_slots() -> void:
	for state: String in ["empty", "queued", "busy", "ready", "buy", "level"]:
		var slot: Control = mount(kit.call("slot_dot", state, tex, 0.5, "1 min"))
		check(slot.get("state") == state and slot.find_child("Dot", true, false).custom_minimum_size == Vector2(52, 52), "slot preserva estado e disco 52: " + state)
		if state in ["empty", "buy"]:
			check(slot.find_child("Plus", true, false) != null, "nome Plus preservado: " + state)
		if state in ["buy", "level"]:
			check(_has_texture(slot, kit.call("ctl_icon", "lock")), "slot fechado usa cadeado")
		slot.free()


func _caso_lista() -> void:
	var list: VBoxContainer = kit.call("list_card", host)
	for i in 3:
		list.add_child(kit.call("list_row", tex, "Item", [] as Array[Control], null, Callable(), i == 1))
	await process_frame
	await process_frame
	check(list.find_children("Divider*", "ColorRect", false, false).size() == 2, "três linhas têm duas divisórias")
	for i in list.get_child_count():
		check(list.get_child(i).has_meta("divider") == (i % 2 == 1), "divisória só entre linhas, posição %d" % i)
	list.get_parent().free()
