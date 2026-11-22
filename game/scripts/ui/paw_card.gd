class_name PawCard
extends RefCounted
## Cartela de patinhas (F02B): seis espaços como cartão de carimbo. Cada dia bem alimentado carimba o prato que ele comeu;
## o primeiro é o "Dia da chegada"; dia fraco é um carimbo tracejado vazio. Aparece na folha Hoje e na linha das patinhas
## do painel Crescer. Só consulta o `GameState` (`paw_stamps`, `next_meal_in`).

const CELL := Vector2(42, 54)
const NEED := 6


## Quantas patinhas o Dentinhos pede (padrão 6; lido do requisito `well_fed_day` da fase seguinte).
static func need() -> int:
	for row: Dictionary in GameState.growth_info().requirements:
		if str(row.get("counter", "")) == "well_fed_day":
			return maxi(1, int(row.need))
	return NEED


## Cartela inteira: título com n/m, grade de carimbos, "Dia completo!" e a linha do próximo almoço/jantar.
static func build(node_name: String = "PawCard", animate: bool = false) -> Control:
	var box := UiKit.vbox(4)
	box.name = node_name
	var stamps := GameState.paw_stamps()
	var paws := stamps.filter(func(entry: Dictionary) -> bool: return entry.kind == "paw" or entry.kind == "bonus").size()
	var total := need()
	var head := UiKit.hbox(8)
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	var title := StepCardUi.wood("Patinhas", 18)
	title.name = "PawTitle"
	head.add_child(title)
	head.add_child(StepCardUi.wood_chip(UiKit.ui_icon("find_paw"), "%d/%d" % [mini(paws, total), total], "have" if paws >= total else "", Callable(), "PawCount"))
	box.add_child(head)
	var grid := HFlowContainer.new()
	grid.name = "PawGrid"
	grid.alignment = FlowContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 3)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(grid)
	var count := maxi(total, stamps.size())
	var newest := -1
	for i in count:
		var entry: Dictionary = stamps[i] if i < stamps.size() else {}
		var cell := _cell(entry, i)
		grid.add_child(cell)
		if not entry.is_empty() and entry.kind == "paw":
			newest = i
	var today := GameState.meal_info()
	var done_today: bool = bool(today.paw) and newest >= 0 and int(stamps[newest].day) == int(today.day)
	if done_today:
		var note := StepCardUi.wood("Dia da chegada!" if bool(stamps[newest].arrival) else "Dia completo!", 15, Palette.GO_INK)
		note.name = "PawDone"
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(note)
		if animate and newest >= 0:
			Motion.pop_in(grid.get_child(newest))
	var next := next_text()
	if next != "":
		var line := StepCardUi.wood(next, 15, Color(Palette.WOOD_INK, 0.8))
		line.name = "PawNext"
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(line)
	return box


## Um espaço: carimbo (prato + ✓), carimbo fraco (tracejado vazio) ou vazio. Legenda só no dia da chegada.
static func _cell(entry: Dictionary, index: int) -> Control:
	var state := str(entry.get("kind", "empty"))
	var column := UiKit.vbox(0)
	column.name = "PawSlot_%d" % index
	column.set_meta("state", state)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var slot := PanelContainer.new()
	slot.name = "Stamp"
	slot.custom_minimum_size = Vector2(CELL.x, CELL.y - 14.0)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	match state:
		"paw":
			style.bg_color = Palette.HONEY_SOFT
			style.border_color = Palette.HONEY_EDGE
		"bonus":  # patinha extra do Ensopado Dourado: carimbo dourado
			style.bg_color = Palette.HONEY
			style.border_color = Palette.HONEY_INK
		"weak":
			style.bg_color = Color(Palette.WOOD_INSET, 0.35)
			style.border_color = Color(0, 0, 0, 0)
		_:
			style.bg_color = Color(Palette.WOOD_INSET, 0.45)
			style.border_color = Color(0, 0, 0, 0)
	slot.add_theme_stylebox_override("panel", style)
	if state == "paw" or state == "bonus":
		var inner := UiKit.vbox(0)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dish := UiKit.icon(Database.item_icon(str(entry.item)), 28)
		dish.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		dish.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.add_child(dish)
		var check := UiKit.ctl("check", 14, Palette.GO_INK)
		check.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		inner.add_child(check)
		slot.add_child(inner)
	else:
		var color := Color(Palette.WOOD_INK, 0.55 if state == "weak" else 0.3)
		slot.draw.connect(func() -> void: _dashed(slot, color))
	column.add_child(slot)
	var caption := StepCardUi.wood("Chegada" if bool(entry.get("arrival", false)) else ("Extra" if state == "bonus" else " "), 11, Color(Palette.WOOD_INK, 0.8))
	caption.name = "Caption"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	return column


## Contorno tracejado do espaço vazio (o StyleBoxFlat não tem tracejado).
static func _dashed(slot: Control, color: Color) -> void:
	var rect := Rect2(Vector2(2, 2), slot.size - Vector2(4, 4))
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position]
	for i in 4:
		slot.draw_dashed_line(corners[i], corners[i + 1], color, 2.0, 5.0)


static func _span(seconds: int) -> String:
	var minutes := ceili(float(seconds) / 60.0)
	var hours := minutes / 60
	minutes = minutes % 60
	if hours > 0:
		return "%d h" % hours if minutes == 0 else "%d h %d min" % [hours, minutes]
	return "%d min" % maxi(1, minutes)


## "Próximo almoço em 2 h" ou "Hora do almoço!" (vazio antes da aula da comida: o relógio ainda não existe).
static func next_text() -> String:
	if not GameState.food_clock_on():
		return ""
	var next := GameState.next_meal_in()
	if next.is_empty():
		return ""
	var name := MealUi.period_name(str(next.period)).to_lower()
	return "Hora do %s!" % name if bool(next.open) else "Próximo %s em %s" % [name, _span(int(next.seconds))]
