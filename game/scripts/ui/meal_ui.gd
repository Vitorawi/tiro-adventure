class_name MealUi
extends RefCounted
## Telas do relógio de refeições (primeira semana, E01c): reloginho do HUD, folha "Hoje",
## escolha Dar agora / Deixar pronto e avisos. Toda a regra mora no GameState (`meal_*`, `store_meal`).

const OPEN_ICON := "clock"


## Estado de um período hoje: done (na hora) · ration (ração/fora da hora) · stored · open · soon · closed.
static func period_state(period: String) -> String:
	var info := GameState.meal_info()
	var record: Dictionary = info.done.get(period, {})
	if not record.is_empty():
		return "done" if bool(record.get("on_time", false)) else "ration"
	for stored: Dictionary in GameState.stored_meals():
		if str(stored.period) == period and int(stored.day) - GameState.week.started_day + 1 == int(info.day):
			return "stored"
	if str(info.period) == period:
		return "open"
	if GameState.week_hour() < GameState.meal_window(period).x:
		return "soon"
	return "closed"


## Há refeição pedindo agora (janela aberta e ainda não dada na hora)? Devolve o período ou "".
static func asking_period() -> String:
	if GameState.dog.sleeping or GameState.walking() or not GameState.food_lesson_done():
		return ""
	var info := GameState.meal_info()
	var period := str(info.period)
	if info.arrival:
		return period if int(info.on_time) < int(info.needed) and period != "" else ""
	if period == "" or period_state(period) != "open":
		return ""
	return period


## Com a janela aberta e o período já ✓ na hora, o que ele diz ao ser tocado ("Já almocei!"); vazio nos outros casos.
static func fed_text() -> String:
	if not GameState.food_lesson_done() or GameState.dog.sleeping or GameState.walking():
		return ""
	var period := str(GameState.meal_info().period)
	if period == "" or period_state(period) != "done":
		return ""
	return str(Database.week_routine.text.get("fed_" + period, ""))


static func period_name(period: String) -> String:
	return str(Database.meals.periods.get(period, {}).get("name", ""))


static func hours_text(period: String) -> String:
	var w := GameState.meal_window(period)
	return "%dh–%dh" % [w.x, w.y]


## Texto curto do estado, para a linha do período.
static func state_text(period: String, state: String) -> String:
	match state:
		"done": return "Comeu na hora!"
		"ration": return "Ração da vovó"
		"stored": return "Guardado: ele come sozinho"
		"open": return "Hora de comer!"
		"soon": return "Abre às %dh" % GameState.meal_window(period).x
	return "Passou"


static func _state_icon(state: String) -> Texture2D:
	match state:
		"done": return UiKit.ctl_icon("check")
		"stored", "soon": return UiKit.ctl_icon("clock")
	return UiKit.ctl_icon("clock")


## Reloginho do avatar: abre a folha Hoje. Verde com pontinho quando a refeição está pedindo.
static func clock_button() -> Button:
	var button := UiKit.ctl_button("clock", open_today, 28)
	button.name = "MealClock"
	button.custom_minimum_size = Vector2(44, 44)
	return button


## Atualiza cor/estado do reloginho (chamado pelo HUD a cada refresh).
static func sync_clock(button: Button) -> void:
	var asking := asking_period() != ""
	var disc := button.get_node_or_null("Disc") as PanelContainer
	if disc != null:
		var tone: Color = Palette.GO if asking else Palette.CARD
		disc.add_theme_stylebox_override("panel", UiKit.surface(tone, 14, not asking))
	button.set_meta("state", "asking" if asking else ("weak" if GameState.tiro_weak() else "calm"))
	var dot := button.get_node_or_null("WeakDot") as Control
	if dot != null:
		dot.visible = GameState.tiro_weak()


static func open_today() -> void:
	Events.sheet_requested.emit("Hoje", today_panel())


## Folha "Hoje": almoço e jantar, patinha, aviso do fraquinho, refeição guardada e escolha do horário.
static func today_panel() -> Control:
	var panel := ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "TodayPanel"
		box.add_theme_constant_override("separation", 10)
		var info := GameState.meal_info()
		var head := UiKit.hbox(8)
		head.alignment = BoxContainer.ALIGNMENT_CENTER
		var day := StepCardUi.wood("Dia %d" % int(info.day), 22)
		day.name = "TodayDay"
		head.add_child(day)
		head.add_child(_paw_chip(bool(info.paw), int(info.on_time), int(info.needed)))
		var help := StepCardUi.help_button(MealReview.open)
		help.name = "MealHelp"
		head.add_child(help)
		box.add_child(head)
		if GameState.tiro_weak():
			var weak := StepCardUi.wood("Ele está fraquinho. Uma refeição na hora e ele melhora!", 15, Palette.ALERT_INK)
			weak.name = "WeakNote"
			weak.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			weak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(weak)
		var inner := StepCardUi.inner_card(box, "TodayCard", Vector4i(12, 10, 12, 10))
		for period: String in Database.meals.periods:
			inner.add_child(_period_row(period, int(info.day)))
		var paw_box := StepCardUi.inner_card(box, "PawCardBox", Vector4i(12, 8, 12, 8))
		paw_box.add_child(PawCard.build())
		for stored: Dictionary in GameState.stored_meals():
			_stored_card(box, stored)
		_store_row(box)
		if not info.arrival:
			_option_card(box)
		if GameState.week_meal_reminder_offered():
			var reminder := CheckButton.new()
			reminder.name = "MealReminder"
			reminder.text = str(Database.week_routine.text.reminder_setting)
			reminder.set_pressed_no_signal(GameState.week_meal_reminder_enabled())
			reminder.toggled.connect(GameState.set_week_meal_reminder)
			box.add_child(reminder)
	))
	return panel


static func _paw_chip(paw: bool, done: int, needed: int) -> Control:
	var icon: Texture2D = UiKit.ctl_icon("check") if paw else null
	var chip := StepCardUi.wood_chip(icon, "Patinha" if paw else "%d/%d na hora" % [done, needed], "have" if paw else "")
	chip.name = "PawChip"
	return chip


static func _period_row(period: String, _day: int) -> Control:
	var state := period_state(period)
	var row := UiKit.hbox(10)
	row.name = "Period_" + period
	row.set_meta("state", state)
	row.custom_minimum_size.y = 52
	var icon := UiKit.icon(_state_icon(state), 28)
	icon.modulate = Palette.GO_INK if state == "done" else Palette.WOOD_INK
	row.add_child(icon)
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var title := StepCardUi.wood("%s  %s" % [period_name(period), hours_text(period)], 18)
	title.name = "PeriodTitle"
	text.add_child(title)
	var tone := Palette.GO_INK if state in ["done", "open"] else Palette.WOOD_INK
	var note := StepCardUi.wood(state_text(period, state), 14, tone)
	note.name = "PeriodState"
	text.add_child(note)
	row.add_child(text)
	return row


static func _stored_card(parent: Control, stored: Dictionary) -> void:
	var card := StepCardUi.inner_card(parent, "StoredCard", Vector4i(12, 10, 12, 10))
	var line := UiKit.hbox(10)
	line.add_child(UiKit.icon(Database.item_icon(str(stored.item)), 32))
	var label := StepCardUi.wood("Para o %s: %s" % [period_name(str(stored.period)).to_lower(), Database.item_name(str(stored.item))], 15)
	label.name = "StoredLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_child(label)
	var cancel := UiKit.soft("Pegar de volta", func() -> void:
		var error := GameState.cancel_stored_meal(str(stored.period))
		if error != "": Events.toast_requested.emit(error), null, true)
	cancel.name = "CancelStored"
	line.add_child(cancel)
	card.add_child(line)


## Deixar pronto direto da folha Hoje: uma refeição da Mochila vai para a tigela (a primeira refeição do dia nunca pergunta,
## então este é o caminho de quem vai sair). Um botão por refeição que dá para guardar agora.
static func _store_row(parent: Control) -> void:
	if not GameState.food_lesson_done() or GameState.week.stored.size() >= int(Database.meals.get("stored_slots", 2)):
		return
	var items: Array[String] = []
	for id: String in GameState.meal_items_owned():
		if GameState.store_meal_error(id) == "":
			items.append(id)
	if items.is_empty():
		return
	var card := StepCardUi.inner_card(parent, "StoreCard", Vector4i(12, 10, 12, 10))
	var target := GameState.meal_next_target()
	var title := StepCardUi.wood("Deixar pronto na tigela: ele come no %s" % period_name(str(target.get("period", ""))).to_lower(), 15)
	title.name = "StoreTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(title)
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 6)
	buttons.add_theme_constant_override("v_separation", 6)
	for id: String in items.slice(0, 3):
		var button := UiKit.soft(Database.item_name(id), func() -> void:
			var error := GameState.store_meal(id)
			if error != "": Events.toast_requested.emit(error), Database.item_icon(id), true)
		button.name = "StoreNow_" + id
		button.add_theme_constant_override("icon_max_width", 28)
		button.expand_icon = true
		buttons.add_child(button)
	card.add_child(buttons)


static func _option_card(parent: Control) -> void:
	var card := StepCardUi.inner_card(parent, "OptionCard", Vector4i(12, 10, 12, 10))
	var title := StepCardUi.wood("Horário das refeições", 15)
	title.name = "OptionTitle"
	card.add_child(title)
	var entries: Array[Dictionary] = []
	for id: String in Database.meals.options:
		entries.append({"id": id, "text": str(Database.meals.options[id].name)})
	card.add_child(UiKit.segmented(entries, GameState.week.option, func(id: String) -> void:
		GameState.set_meal_option(id)))


static func offer_trick(offer: Dictionary, serve: Callable) -> void:
	var root := GameState.get_tree().root
	var host := root.get_node_or_null("Main")
	TrickLesson.offer_meal(host if host != null else root, offer, serve)


## Quando a refeição arrastada não conta agora, mas dá para guardar: Dar agora ou Deixar pronto.
static func store_choice(item_id: String, give_now: Callable) -> void:
	var target := GameState.meal_next_target()
	var name := period_name(str(target.get("period", ""))).to_lower()
	var content := ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "StoreChoice"
		box.add_theme_constant_override("separation", 10)
		var line := UiKit.hbox(10)
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_child(UiKit.icon(Database.item_icon(item_id), 40))
		var ask := StepCardUi.wood("Ainda não é hora de comer. Deixar pronto para o %s?" % name, 16)
		ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ask.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ask.name = "StoreAsk"
		line.add_child(ask)
		box.add_child(line)
		var store := ProjectUi.green("Deixar pronto", func() -> void:
			var error := GameState.store_meal(item_id)
			Events.sheet_close_requested.emit()
			Events.toast_requested.emit(error if error != "" else "Pronto! Ele come no %s." % name))
		store.name = "StoreMeal"
		box.add_child(store)
		var now := UiKit.soft("Dar agora", func() -> void:
			Events.sheet_close_requested.emit()
			give_now.call())
		now.name = "GiveNow"
		box.add_child(now)
	))
	Events.sheet_requested.emit("Deixar pronto?", content)


## Liga os avisos de dia fraco e marmita (chamado uma vez pela casca).
static func connect_notices() -> void:
	Events.weak_day.connect(func(_day: int) -> void:
		Events.toast_requested.emit("Ele ficou fraquinho. Dê uma refeição na hora!"))
	Events.lunchbox_given.connect(func(_day: int) -> void:
		Events.toast_requested.emit("A vovó mandou uma marmita!"))
