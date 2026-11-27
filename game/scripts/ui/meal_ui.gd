class_name MealUi
extends RefCounted
## Telas da comida do Tiro, de dia e de noite (regra única em `docs/plans/alimentacao/README.md`): o potinho do HUD
## (`MealDay`: sol e lua), a folha "Hoje", a pergunta "Ele já comeu" e os avisos. Toda a regra mora no GameState
## (`meal_*`, `store_meal`); aqui só se lê e se desenha.

const DISC := 30.0
const HUD_DISC := 24.0  # discos do potinho no canto do retrato do HUD

## Estados de uma metade do dia: done (✓) · stored (na tigela) · open (aberta e sem ✓) · soon (ainda não começou) · closed (passou).
const STATE_NOTES := {"soon": "%dh", "closed": "Passou"}

## Rótulo do atalho que guarda a comida na tigela (folha Hoje e Boa noite do dia 1).
const BOWL_TEXT := "Guardar na tigela"


static func _periods() -> Array:
	return Database.meals.periods.keys()


## "sun" ou "moon": nome do ícone vetorial de cada metade.
static func period_icon(period: String) -> String:
	return "sun" if _periods().find(period) <= 0 else "moon"


## Dia do Tiro absoluto de hoje (o mesmo número de `week.stored[].day`).
static func _today_absolute() -> int:
	return GameState.week.started_day + int(GameState.meal_info().day) - 1


## Estado de uma metade do dia hoje.
static func period_state(period: String) -> String:
	var info := GameState.meal_info()
	var record: Dictionary = info.done.get(period, {})
	if bool(record.get("on_time", false)):
		return "done"
	for stored: Dictionary in GameState.stored_meals():
		if str(stored.period) == period and int(stored.day) == _today_absolute():
			return "stored"
	if str(info.period) == period:
		return "open"
	var order := _periods()
	if order.find(period) > order.find(str(info.period)):
		return "soon"
	return "closed"


## Há refeição pedindo agora (metade aberta, sem ✓ e a patinha ainda precisa dela)? Devolve a metade ou "".
static func asking_period() -> String:
	if GameState.dog.sleeping or GameState.walking() or not GameState.food_clock_on():  # o relógio já existe durante a aula
		return ""
	var info := GameState.meal_info()
	var period := str(info.period)
	if info.arrival and int(info.on_time) >= int(info.needed):
		return ""
	if period == "" or period_state(period) != "open":
		return ""
	return period


## Com a metade aberta já ✓, o que ele diz ao ser tocado ("Barriga cheia!"); vazio nos outros casos.
static func fed_text() -> String:
	if not GameState.food_lesson_done() or GameState.dog.sleeping or GameState.walking():
		return ""
	var period := str(GameState.meal_info().period)
	if period == "" or period_state(period) != "done":
		return ""
	return str(Database.week_routine.text.get("fed_" + period, ""))


static func period_name(period: String) -> String:
	return str(Database.meals.periods.get(period, {}).get("name", ""))


## "Comidinha do dia" / "Comidinha da noite" (com a primeira letra maiúscula).
static func meal_title(period: String) -> String:
	var meal := str(Database.meals.periods.get(period, {}).get("meal", ""))
	return meal.substr(0, 1).to_upper() + meal.substr(1)


static func hours_text(period: String) -> String:
	var w := GameState.meal_window(period)
	return "%dh–%dh" % [w.x, w.y]


## "a noite" · "amanhã de dia" · "amanhã à noite": para onde vai a comida guardada ("Guardar para ...").
static func target_phrase(target: Dictionary) -> String:
	if target.is_empty():
		return ""
	var tomorrow := int(target.get("week_day", 0)) > int(GameState.meal_info().day)
	var night := str(target.period) == str(_periods()[1])
	if not tomorrow:
		return "a noite" if night else "o dia"
	return "amanhã à noite" if night else "amanhã de dia"


## Quando uma refeição guardada será comida: "hoje à noite", "amanhã de dia"...
static func stored_when(entry: Dictionary) -> String:
	var tomorrow := int(entry.day) > _today_absolute()
	var night := str(entry.period) == str(_periods()[1])
	if tomorrow:
		return "amanhã à noite" if night else "amanhã de dia"
	return "hoje à noite" if night else "hoje de dia"


## Texto curto do estado da metade, para o cartão da folha Hoje.
static func state_text(period: String, state: String) -> String:
	match state:
		"done":
			var item := str(GameState.meal_info().done.get(period, {}).get("item", ""))
			var name := Database.item_name(item) if Database.items.has(item) or item.begins_with(DishRules.PREFIX) else "Comeu"
			return name + " ✓"
		"stored":
			return "Na tigela"
		"open":
			var info := GameState.meal_info()
			if info.arrival and int(info.on_time) >= int(info.needed):
				return "Hoje uma basta"
			return "Com fome!"
		"soon":
			return str(STATE_NOTES.soon) % GameState.meal_window(period).x
	return str(STATE_NOTES.closed)


# --- Disco do sol e da lua --------------------------------------------------------------------

## Disco de uma metade: sol ou lua dentro de um círculo, com o selo do estado (✓ verde ou reloginho mel).
## `pulse` faz o disco com fome pulsar (parado em Menos animação).
static func period_disc(period: String, state: String, px: float = DISC, pulse: bool = false) -> Control:
	var disc := Control.new()
	disc.name = "Disc_" + period
	disc.custom_minimum_size = Vector2(px, px)
	disc.size = Vector2(px, px)
	disc.pivot_offset = Vector2(px, px) / 2.0
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # redondo: nunca estica para a altura da pílula
	disc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	disc.set_meta("state", state)
	var fill := Palette.CARD
	var ink := Palette.WOOD_INK
	var alpha := 1.0
	match state:
		"open":
			fill = Palette.GO
			ink = Color.WHITE
		"soon":
			alpha = 0.6
		"closed":
			alpha = 0.38
	var back := Panel.new()
	back.name = "Back"
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Palette.GO_EDGE if state == "open" else Color("c9935f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(px))
	back.add_theme_stylebox_override("panel", style)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	disc.add_child(back)
	var glyph_px := int(round(px * 0.6))
	var glyph := UiKit.ctl(period_icon(period), glyph_px, ink)
	glyph.name = "Glyph"
	glyph.set_anchors_preset(Control.PRESET_CENTER)
	glyph.offset_left = -glyph_px / 2.0
	glyph.offset_right = glyph_px / 2.0
	glyph.offset_top = -glyph_px / 2.0
	glyph.offset_bottom = glyph_px / 2.0
	disc.add_child(glyph)
	if state in ["done", "stored"]:
		var seal_px := roundf(px * 0.5)
		var seal := Panel.new()
		seal.name = "Seal"
		var seal_style := StyleBoxFlat.new()
		seal_style.bg_color = Palette.GO if state == "done" else Palette.HONEY
		seal_style.border_color = Color.WHITE if state == "done" else Palette.HONEY_EDGE
		seal_style.set_border_width_all(1)
		seal_style.set_corner_radius_all(int(seal_px))
		seal.add_theme_stylebox_override("panel", seal_style)
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.position = Vector2(px - seal_px + 3.0, px - seal_px + 3.0)
		seal.size = Vector2(seal_px, seal_px)
		var mark_px := int(round(seal_px * 0.66))
		var mark := UiKit.ctl("check" if state == "done" else "clock", mark_px, Color.WHITE if state == "done" else Palette.WOOD_INK)
		mark.position = Vector2((seal_px - mark_px) / 2.0, (seal_px - mark_px) / 2.0)
		seal.add_child(mark)
		disc.add_child(seal)
	disc.modulate.a = alpha
	if pulse and state == "open" and not Motion.reduced:
		var tween := disc.create_tween().set_loops()
		tween.tween_property(disc, "scale", Vector2.ONE * 1.12, 0.6).set_trans(Tween.TRANS_SINE)
		tween.tween_property(disc, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	return disc


# --- Potinho do HUD ------------------------------------------------------------------------------

## Potinho do dia, junto ao avatar: só os dois discos (sol e lua), pequenos, no canto de baixo à direita do retrato,
## sem pílula de fundo, para a carinha do Tiro aparecer inteira. Tocar abre a folha Hoje (alvo 56×44).
static func day_button() -> Button:
	var button := _corner_button("MealDay")
	# A lua fica no outro canto do retrato: botão filho (o HUD posiciona com `place_day`), mesmo toque.
	button.add_child(_corner_button("MealDayMoon"))
	# O tempo passa sem mudar o estado do jogo: o potinho se confere sozinho de vez em quando.
	var timer := Timer.new()
	timer.name = "Tick"
	timer.wait_time = 5.0
	timer.autostart = true
	timer.timeout.connect(func() -> void: sync_day(button))
	button.add_child(timer)
	return button


## Um cantinho tocável de 44×44 com um disco no meio (o sol no MealDay, a lua no MealDayMoon).
static func _corner_button(node_name: String) -> Button:
	var button := BagUi.plain_button(open_today)
	button.name = node_name
	button.custom_minimum_size = Vector2(44, 44)
	button.size = Vector2(44, 44)
	button.focus_mode = Control.FOCUS_NONE
	var row := CenterContainer.new()
	row.name = "Discs"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(row)
	Motion.press(button)
	return button


## Põe o sol com o centro em `sun` e a lua com o centro em `moon` (coordenadas do pai do MealDay).
static func place_day(button: Button, sun: Vector2, moon: Vector2) -> void:
	button.position = sun - button.size / 2.0
	var moon_button := button.get_node_or_null("MealDayMoon") as Control
	if moon_button != null:
		moon_button.position = moon - sun + button.size / 2.0 - moon_button.size / 2.0


## Atualiza os dois discos (chamado pelo HUD a cada refresh). Só refaz quando o desenho muda.
static func sync_day(button: Button) -> void:
	var row := button.get_node_or_null("Discs") as Control
	var moon_button := button.get_node_or_null("MealDayMoon") as Control
	if row == null or not GameState.food_clock_on():
		return
	var asking := asking_period()
	var states: Array[String] = []
	for period: String in _periods():
		var state := period_state(period)
		if state == "open" and asking != period:
			state = "soon"  # a metade aberta que a patinha não pede (dia da chegada já completo) fica calma
		states.append(state)
	var signature := "|".join(states) + ("~" if Motion.reduced else "")
	if str(button.get_meta("sig", "")) == signature:
		return
	button.set_meta("sig", signature)
	var rows: Array[Control] = [row, moon_button.get_node("Discs") as Control if moon_button != null else row]
	for target: Control in rows:
		for child in target.get_children():
			target.remove_child(child)
			child.queue_free()
	var order := _periods()
	for i in order.size():
		rows[mini(i, 1)].add_child(period_disc(str(order[i]), states[i], HUD_DISC, true))
	button.set_meta("state", "asking" if asking != "" else "calm")
	button.tooltip_text = ""


## A patinha deste dia acabou de sair COM O JOGO ABERTO? Devolve {day, arrival, from_bowl, hour, minute} para o cartão
## "Dia completo!", ou vazio. Vazio também durante a aula da comida (ela mostra a própria patinha) e para a patinha que se
## completou com o jogo fechado ou em segundo plano (a tigela comeu à 16h e o jogador abriu o app às 17h): essas o Bom dia
## conta. A diferença é a hora do ✓ que fechou o dia: ao vivo ela é de agora (a tigela come no tique de 1 s depois da virada).
static func live_paw(day: int) -> Dictionary:
	if not GameState.food_lesson_done() or GameState.food_lesson_running() or LessonGuide.is_active():
		return {}
	var record: Dictionary = GameState.week.day_record(day)
	var latest := {}
	var latest_period := ""
	for period: String in _periods():
		var entry: Dictionary = record.get(period, {})
		if bool(entry.get("on_time", false)) and (latest.is_empty() or float(entry.get("at", 0.0)) >= float(latest.at)):
			latest = entry
			latest_period = period
	if latest.is_empty() or str(latest.get("item", "")) == "lesson" or absf(GameState.week_now() - float(latest.at)) > 10.0:
		return {}
	var from_bowl := bool(latest.get("stored", false))
	return {"day": day, "arrival": GameState.is_arrival_day(day), "from_bowl": from_bowl, "period": latest_period,
		"hour": GameState.meal_window(latest_period).x if from_bowl else 0, "minute": 0}


## Aviso do ✓ ao vivo quando a outra metade ainda falta: "Comidinha do dia ✓ · A da noite é a partir das 16h" ou
## "Comidinha da noite ✓ · Amanhã cedo tem mais". Vazio: não foi ao vivo (tigela), a patinha saiu (o cartão "Dia completo!"
## cuida), a aula da comida está rodando (ela tem as falas) ou o relógio ainda não existe. Chamar depois do registro do dia.
static func counted_notice(period: String) -> String:
	if not GameState.food_lesson_done() or GameState.food_lesson_running() or LessonGuide.is_active():
		return ""
	var day := int(GameState.meal_info().day)
	var record: Dictionary = GameState.week.day_record(day)
	var entry: Dictionary = record.get(period, {})
	if not bool(entry.get("on_time", false)) or bool(entry.get("stored", false)) or bool(record.get("paw", false)):
		return ""
	return "%s ✓" % meal_title(period)


static func open_today() -> void:
	GameState.note_screen_opened("meal_today")  # a lição do potinho termina no primeiro toque nele
	Events.sheet_requested.emit("Hoje", today_panel())


# --- Folha Hoje -----------------------------------------------------------------------------------

## Folha "Hoje": os dois cartões (dia e noite), a conta sol + lua = patinha, a cartela e a comida na tigela.
static func today_panel() -> Control:
	var panel := ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "TodayPanel"
		box.add_theme_constant_override("separation", 10)
		var info := GameState.meal_info()
		var asking := asking_period()
		var cards := UiKit.hbox(10)
		cards.name = "TodayCards"
		box.add_child(cards)
		for period: String in _periods():
			cards.add_child(_slot_card(period, asking))
		box.add_child(_equation(info))
		var paw_box := StepCardUi.inner_card(box, "PawCardBox", Vector4i(12, 8, 12, 8))
		paw_box.add_child(PawCard.build("PawCard", false, false, false))
		for stored: Dictionary in GameState.stored_meals():
			_stored_card(box, stored)
		_store_row(box)
	))
	panel.set_meta("sheet_actions", _header_actions)
	return panel


## O "?" de madeira ao lado do X da folha: abre a revisão da regra.
static func _header_actions() -> Array[Control]:
	var help := StepCardUi.help_button(MealReview.open)
	help.name = "MealHelp"
	return [help]


## Cartão de uma metade: disco grande, nome e o estado em poucas palavras.
static func _slot_card(period: String, asking: String) -> Control:
	var state := period_state(period)
	var tone := state
	if state == "open" and asking != period:
		tone = "soon"
	var card := MissionUi.card("card", Vector4i(8, 8, 8, 8), "Slot_" + period, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.set_meta("state", state)
	var column := UiKit.vbox(4)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	MissionUi.body(card).add_child(column)
	var disc := period_disc(period, tone, 40.0)
	disc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(disc)
	var title := StepCardUi.wood(period_name(period), 19)
	title.name = "SlotName"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var ink := Palette.GO_INK if state in ["done", "open"] and tone != "soon" else Palette.WOOD_INK
	var note := StepCardUi.wood(state_text(period, state), 14, ink)
	note.name = "SlotState"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.custom_minimum_size.y = 20.0
	column.add_child(note)
	return card


## A conta, desenhada: sol + lua = patinha. Os discos mostram o que já está feito hoje.
static func _equation(info: Dictionary) -> Control:
	return equation_row(info)


## A conta com um rótulo opcional na frente ("Amanhã"): com `info` vazio nada está feito (discos e patinha apagados).
static func equation_row(info: Dictionary, label: String = "", node_name: String = "PawEquation") -> Control:
	var row := UiKit.hbox(8)
	row.name = node_name
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if label != "":
		row.add_child(StepCardUi.wood(label, 16))
	var order := _periods()
	for i in order.size():
		var period := str(order[i])
		var state := period_state(period) if not info.is_empty() else "soon"
		row.add_child(period_disc(period, "done" if state == "done" else "soon", 34.0))
		if i == 0:
			row.add_child(StepCardUi.wood("+", 24))
	row.add_child(StepCardUi.wood("=", 24))
	var paw := UiKit.icon(UiKit.ui_icon("find_paw"), 36)
	paw.name = "EquationPaw"
	paw.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	paw.modulate = Color.WHITE if bool(info.get("paw", false)) else Color(1, 1, 1, 0.55)
	row.add_child(paw)
	return row


static func _stored_card(parent: Control, stored: Dictionary) -> void:
	var card := StepCardUi.inner_card(parent, "StoredCard", Vector4i(12, 10, 12, 10))
	var line := UiKit.hbox(10)
	line.add_child(UiKit.icon(Database.item_icon(str(stored.item)), 32))
	var text := UiKit.vbox(0)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := StepCardUi.wood(Database.item_name(str(stored.item)), 16)
	label.name = "StoredLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(label)
	line.add_child(text)
	var cancel := UiKit.soft("Pegar de volta", func() -> void:
		var error := GameState.cancel_stored_meal(str(stored.period))
		if error != "": Events.toast_requested.emit(error), null, true)
	cancel.name = "CancelStored"
	line.add_child(cancel)
	card.add_child(line)


## Deixar pronto direto da folha Hoje: só quando a metade atual já tem ✓ e a tigela tem lugar. Um botão por refeição.
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
	var title := StepCardUi.wood(BOWL_TEXT, 15)
	title.name = "StoreTitle"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(title)
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 6)
	buttons.add_theme_constant_override("v_separation", 6)
	for id: String in items.slice(0, 2):
		var button := UiKit.soft(Database.item_name(id), func() -> void:
			var error := GameState.store_meal(id)
			if error != "": Events.toast_requested.emit(error), Database.item_icon(id), true)
		button.name = "StoreNow_" + id
		button.add_theme_constant_override("icon_max_width", 28)
		button.expand_icon = true
		buttons.add_child(button)
	card.add_child(buttons)


static func offer_trick(offer: Dictionary, serve: Callable) -> void:
	var root := GameState.get_tree().root
	var host := root.get_node_or_null("Main")
	TrickLesson.offer_meal(host if host != null else root, offer, serve)


# --- Ele já comeu -----------------------------------------------------------------------------------

## Quando a refeição arrastada não contaria (a metade já tem ✓) mas dá para guardar: Guardar na tigela ou Dar assim mesmo.
static func store_choice(item_id: String, give_now: Callable) -> void:
	var target := GameState.meal_next_target()
	var phrase := target_phrase(target)
	var content := ProjectUi.wood_sheet(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.name = "StoreChoice"
		box.add_theme_constant_override("separation", 10)
		var plate := UiKit.icon(Database.item_icon(item_id), 64)
		plate.name = "StoreItem"
		plate.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(plate)
		var store := ProjectUi.green("Guardar para " + phrase, func() -> void:
			var error := GameState.store_meal(item_id)
			Events.sheet_close_requested.emit()
			Events.toast_requested.emit(error if error != "" else "Pronto! Ele come %s." % stored_when(target)))
		store.name = "StoreMeal"
		box.add_child(store)
		var now := WelcomeSheet._button("Dar assim mesmo", false, 300.0, "GiveNow", func() -> void:
			Events.sheet_close_requested.emit()
			give_now.call())
		now.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(now)
	))
	Events.sheet_requested.emit("Ele já comeu", content)
