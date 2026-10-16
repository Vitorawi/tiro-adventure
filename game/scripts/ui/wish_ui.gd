class_name WishUi
extends RefCounted
## Peças visuais dos desejos do Tiro e do vínculo: cartão de desejo, cabeçalho com vínculo,
## painel "o que libera" e o balão. Ícone + número; só ações pelo GameState.



## Ícone do desejo: o campo "icon" (ação) ou o do item pedido.
static func icon(wish_id: String) -> Texture2D:
	var def := GameState.wish_def(wish_id)
	if def.get("type", "") == "action":
		return UiKit.ui_icon(str(def.get("icon", "tab_wishes")))
	return Database.item_icon(str(def.get("item", "")))


## Cabeçalho: retrato do Tiro, título e o chip de vínculo com barra até o próximo coração.
static func header(box: VBoxContainer) -> void:
	var card := UiKit.card(box, &"CardPanel")
	var row := UiKit.hbox(10)
	row.add_child(PetAnimator.portrait())
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label("O que o Tiro quer", &"SectionLabel"))
	info.add_child(bond_bar())
	row.add_child(info)
	card.add_child(row)
	card.get_parent().gui_input.connect(func(event: InputEvent) -> void:
		var button := event as InputEventMouseButton
		if button and not button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			Events.sheet_requested.emit("Vínculo", bond_panel()))


## [coração N] + barra até o próximo nível (cheia no máximo).
static func bond_bar() -> HBoxContainer:
	var info := GameState.progress.bond_info(GameState.dog.affection)
	var line := UiKit.hbox(8)
	line.add_child(UiKit.chip(UiKit.ui_icon("bond_heart"), str(info.level)))
	var span := maxi(1, int(info.next) - int(info.floor))
	var fill := 100.0 if info.max else 100.0 * (int(info.affection) - int(info.floor)) / span
	var bar := UiKit.bar(fill, Palette.DANGER, 14)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(bar)
	return line


## Vínculo em detalhe: barra, presente do próximo nível e o que cada nível libera.
static func bond_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var info := GameState.progress.bond_info(GameState.dog.affection)
		var card := UiKit.card(box, &"ReadyCardPanel")
		card.add_child(bond_bar())
		if info.max:
			card.add_child(UiKit.label("Melhores amigos!", &"SectionLabel", UiKit.GOOD))
		else:
			card.add_child(UiKit.label("%d / %d" % [info.affection, info.next], &"SmallLabel"))
			card.add_child(ProgressionUi.reward_chips(info.rewards))
		var unlocks := UiKit.card(box, &"CardPanel")
		var slots: Array = GameState.wish_settings().get("slots", [])
		for i in slots.size():
			var need := int(slots[i].get("requirements", {}).get("bond", 0))
			if need > 0:
				unlocks.add_child(_unlock_row(need, "Espaço de desejo %d" % (i + 1)))
		var special := int(GameState.wish_settings().get("special_requirements", {}).get("bond", 0))
		if special > 0:
			unlocks.add_child(_unlock_row(special, "Desejos especiais"))
	)


static func _unlock_row(level: int, text: String) -> HBoxContainer:
	var done := GameState.bond_level() >= level
	var row := UiKit.hbox(8)
	row.add_child(UiKit.chip(UiKit.ui_icon("bond_heart"), str(level), UiKit.GOOD if done else null))
	row.add_child(UiKit.fill_label(text, &"SmallLabel", UiKit.GOOD if done else null))
	return row


## Um cartão por espaço: fechado, esperando ou com o pedido.
static func slot_card(box: VBoxContainer, i: int, primary: bool = true) -> void:
	if not GameState.wish_slot_open(i):
		_closed_card(box, i)
		return
	var def := GameState.wish_at(i)
	if def.is_empty():
		_waiting_card(box, i)
		return
	var special := bool(GameState.wishes.slots[i].special)
	var ready := GameState.wish_error(i) == ""
	var card := UiKit.card(box, &"ReadyCardPanel" if special or ready else &"CardPanel")
	if special:
		var panel := card.get_parent() as PanelContainer
		var border := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		border.border_color = Palette.ACCENT_EDGE
		panel.add_theme_stylebox_override("panel", border)
	card.name = "Wish%d" % i
	var wish_id := str(GameState.wishes.slots[i].id)
	var row := UiKit.hbox(10)
	row.add_child(UiKit.icon(icon(wish_id), 64))
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UiKit.hbox(6)
	if special:
		title.add_child(UiKit.icon(UiKit.ui_icon("xp"), 24))
	title.add_child(UiKit.fill_label(str(def.name) + "!", &"SectionLabel"))
	info.add_child(title)
	info.add_child(_progress(def, i))
	row.add_child(info)
	var swap := UiKit.icon_button(null, func() -> void:
		var error := GameState.swap_wish(i)
		if error != "": Events.toast_requested.emit(error), 48, "↔")
	swap.tooltip_text = "Trocar desejo"
	swap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(swap)
	card.add_child(row)
	card.add_child(ProgressionUi.reward_chips(GameState.wish_rewards(i)))
	_actions(card, def, i, ready, primary)


## Ação: barra "1/3"; comida/item: chip "tem 0/1" tocável (de onde vem).
static func _progress(def: Dictionary, i: int) -> Control:
	var target := GameState.wish_target(i)
	var value := mini(GameState.wish_value(i), target)
	if def.type != "action":
		return ProgressionUi.item_chip(str(def.item), 1)
	var line := UiKit.hbox(8)
	var bar := UiKit.bar(100.0 * value / maxi(1, target), UiKit.GOOD, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(bar)
	line.add_child(UiKit.short_label("%d/%d" % [value, target], &"", UiKit.GOOD if value >= target else null))
	return line


static func _actions(card: VBoxContainer, def: Dictionary, i: int, ready: bool, primary: bool) -> void:
	var row := UiKit.hbox(8)
	var give: bool = def.type != "action"
	var on_press := func() -> void:
		if ready:
			var error := GameState.fulfill_wish(i)
			if error != "":
				Events.toast_requested.emit(error)
		else:
			Places.go(go_target(def))
	# Cumprível = botão principal ("Dar"/"Receber"); ainda não = "Ir" secundário pequeno.
	var caption := ("Dar" if give else "Pegar") if ready else "Ir"
	var main := UiKit.primary(caption, on_press) if ready and primary else UiKit.secondary(caption, on_press, null, true)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(main)
	row.add_child(UiKit.square_button("?", TaskHelp.open.bind("wish", str(GameState.wishes.slots[i].id), 1), null, 44))
	card.add_child(row)


## Para onde o "Ir" leva: tela ("screen:pet") ou, para comida/item, a origem dele.
static func go_target(def: Dictionary) -> Dictionary:
	var go := str(def.get("go", ""))
	if go.begins_with("screen:"):
		return {"screen": go.trim_prefix("screen:")}
	if go.begins_with("place:"):
		return {"world": go.get_slice(":", 1), "place": go.get_slice(":", 2), "hint": "Passeio"}
	if def.get("type", "") != "action":
		return Places.goal_target({"type": "have", "key": str(def.item)})
	return {"screen": "pet"}


static func _waiting_card(box: VBoxContainer, i: int) -> void:
	var card := UiKit.card(box, &"CardPanel")
	card.name = "WishWait%d" % i
	var row := UiKit.hbox(10)
	var ring := RingProgress.new()
	ring.texture = UiKit.ui_icon("timer")
	var settings := GameState.wish_settings()
	var duration := int(settings.get("first_refill_seconds", 60)) if GameState.wishes.done_count <= int(settings.get("first_count", 3)) else int(settings.get("refill_seconds", 600))
	if GameState.wish_wait(i) > duration: duration = int(settings.get("swap_seconds", 300))
	ring.progress = 1.0 - float(GameState.wish_wait(i)) / maxi(1, duration)
	row.add_child(ring)
	row.add_child(UiKit.fill_label("Novo desejo em %s" % TimeText.short(GameState.wish_wait(i)), &"SectionLabel"))
	card.add_child(row)


static func _closed_card(box: VBoxContainer, i: int) -> void:
	var card := UiKit.card(box, &"CardPanel")
	card.name = "WishClosed%d" % i
	card.get_parent().modulate.a = 0.6
	var need := int(GameState.wish_settings().slots[i].get("requirements", {}).get("bond", 0))
	card.add_child(UiKit.lock_hint("Com vínculo ♥%d" % need if need > 0 else "Fechado"))
