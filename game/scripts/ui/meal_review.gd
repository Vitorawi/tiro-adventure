class_name MealReview
extends RefCounted
## Rever a aula da comida (F02B): o dia de 24 h com as duas janelas, ✓ ✓ → patinha → crescer. Abre pelo "?" da folha
## Hoje e da linha das patinhas, e vira a página "Comida e crescimento" do Manual (`GameManual.open("tutorials")`).
## Tudo é desenhado a partir das janelas reais (`GameState.meal_window`), então Mais cedo/Mais tarde se refletem aqui.

const BAR_W := 300.0


static func open() -> void:
	Events.sheet_requested.emit("Comida e crescimento", ProjectUi.wood_sheet(body()))


## Conteúdo da revisão (usado pela folha e pelo Manual).
static func body() -> VBoxContainer:
	var box := UiKit.vbox(8)
	box.name = "MealReview"
	box.add_child(_day_bar())
	box.add_child(_flow())
	var need := PawCard.need()
	for line: String in [
		"Almoço e jantar na hora valem uma patinha por dia.",
		"%d patinhas e ele cresce. Não dá para adiantar." % need,
		"Deixar pronto na tigela vale igual.",
	]:
		var text := StepCardUi.wood(line, 16)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(text)
	return box


## O dia do Tiro (das 6h às 6h) como uma barra: as janelas de almoço e jantar em destaque, o resto apagado.
static func _day_bar() -> Control:
	var start := int(Database.meals.get("day_starts_at", 6))
	var periods: Array = Database.meals.periods.keys()
	var column := UiKit.vbox(2)
	column.name = "DayBar"
	column.custom_minimum_size.x = BAR_W
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bar := UiKit.hbox(0)
	bar.custom_minimum_size.y = 34
	var hours := UiKit.hbox(0)
	var cursor := start
	var pieces: Array[Dictionary] = []
	for period: String in periods:
		var window := GameState.meal_window(period)
		pieces.append({"len": window.x - cursor, "on": false, "text": "", "range": ""})
		pieces.append({"len": window.y - window.x, "on": true, "text": MealUi.period_name(period), "range": "%dh–%dh" % [window.x, window.y], "period": period})
		cursor = window.y
	pieces.append({"len": start + 24 - cursor, "on": false, "text": "Noite", "range": ""})
	for piece: Dictionary in pieces:
		var length := maxf(0.2, float(piece.len))
		var cell := PanelContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_stretch_ratio = length
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if piece.on:
			cell.name = "Window_" + str(piece.period)
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.HONEY if piece.on else Color(Palette.WOOD_INSET, 0.55)
		style.border_color = Palette.HONEY_EDGE if piece.on else Color(0, 0, 0, 0)
		style.set_border_width_all(2 if piece.on else 0)
		style.set_corner_radius_all(8 if piece.on else 4)
		cell.add_theme_stylebox_override("panel", style)
		var label := StepCardUi.wood(str(piece.text), 13, Palette.WOOD_INK if piece.on else Color(Palette.WOOD_INK, 0.6))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.clip_text = true
		cell.add_child(label)
		bar.add_child(cell)
		var range_cell := StepCardUi.wood(str(piece.range), 12, Color(Palette.WOOD_INK, 0.8))
		range_cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		range_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		range_cell.size_flags_stretch_ratio = length
		range_cell.clip_text = true
		hours.add_child(range_cell)
	column.add_child(bar)
	column.add_child(hours)
	return column


## ✓ Almoço  ✓ Jantar  →  patinha  →  cresce.
static func _flow() -> Control:
	var row := HFlowContainer.new()
	row.name = "MealFlow"
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for period: String in Database.meals.periods:
		row.add_child(StepCardUi.wood_chip(UiKit.ctl_icon("check"), MealUi.period_name(period), "have"))
	row.add_child(UiKit.ctl("arrow", 20, Palette.WOOD_INK))
	row.add_child(StepCardUi.wood_chip(UiKit.ui_icon("find_paw"), "Patinha"))
	row.add_child(UiKit.ctl("arrow", 20, Palette.WOOD_INK))
	row.add_child(StepCardUi.wood_chip(UiKit.ui_icon("tab_pet"), "Cresce"))
	return row
