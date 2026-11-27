class_name MealReview
extends RefCounted
## Rever a regra da comida (README da alimentação, 3.9): o dia de 24 h numa barra (6h → 16h → 6h, sol claro e lua escura) e
## quatro linhas curtas com ícone. Abre pelo "?" da folha Hoje e da linha das patinhas, e vira a página "Comida e crescimento" do
## Manual (`GameManual.open("tutorials")`). As horas saem das metades reais do dia (`GameState.meal_window`).

const BAR_W := 300.0
const SUN_FILL := Color("ffe39a")
const MOON_FILL := Color("3d4a78")


static func open() -> void:
	Events.sheet_requested.emit("Comida e crescimento", ProjectUi.wood_sheet(body()))


## Conteúdo da revisão (usado pela folha e pelo Manual).
static func body() -> VBoxContainer:
	var box := UiKit.vbox(10)
	box.name = "MealReview"
	box.add_child(_day_bar())
	var need := PawCard.need()
	var lines: Array[Dictionary] = [
		{"name": "Rule_paw", "icons": [UiKit.ctl_icon("sun"), UiKit.ctl_icon("moon"), UiKit.ui_icon("find_paw")], "text": "Dia + noite = 1 patinha"},
		{"name": "Rule_bowl", "icons": [preload("res://assets/sprites/ui/album/prop_bowl.png")], "text": "Tigela: ele come sozinho"},
		{"name": "Rule_snack", "icons": [UiKit.ui_icon("heart")], "text": "Petisco não é refeição"},
		{"name": "Rule_grow", "icons": [UiKit.ui_icon("tab_pet")], "text": "%d patinhas = Dentinhos" % need},
	]
	for line: Dictionary in lines:
		box.add_child(_rule(line))
	return box


## Uma regra: ícone(s) à esquerda e a frase ao lado.
static func _rule(line: Dictionary) -> Control:
	var row := UiKit.hbox(10)
	row.name = str(line.name)
	var icons := UiKit.hbox(2)
	icons.custom_minimum_size.x = 80.0
	icons.alignment = BoxContainer.ALIGNMENT_CENTER
	for texture: Texture2D in line.icons:
		var ctl := texture.resource_path.contains("/ctl/")
		var icon: TextureRect = UiKit.ctl(texture.resource_path.get_file().get_basename(), 24, Palette.WOOD_INK) if ctl else UiKit.icon(texture, 28)
		if not ctl:
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if texture.get_width() <= 48 else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icons.add_child(icon)
	row.add_child(icons)
	var text := StepCardUi.wood(str(line.text), 16)
	text.name = "RuleText"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text)
	return row


## O dia do Tiro (6h → 16h → 6h) como uma barra de duas metades: o sol (claro) e a lua (escura), com as horas embaixo.
static func _day_bar() -> Control:
	var periods: Array = Database.meals.periods.keys()
	var column := UiKit.vbox(2)
	column.name = "DayBar"
	column.custom_minimum_size.x = BAR_W
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bar := UiKit.hbox(0)
	bar.custom_minimum_size.y = 38
	var total := 0.0
	var cuts: Array[float] = []
	for period: String in periods:
		var window := GameState.meal_window(period)
		var length := float(posmod(window.y - window.x, 24))
		cuts.append(total)
		total += length
		var sun := period_is_sun(period, periods)
		var cell := PanelContainer.new()
		cell.name = "Window_" + period
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_stretch_ratio = length
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = SUN_FILL if sun else MOON_FILL
		style.border_color = Palette.HONEY_EDGE if sun else Color("2a3359")
		style.set_border_width_all(2)
		style.corner_radius_top_left = 10 if sun else 0
		style.corner_radius_bottom_left = 10 if sun else 0
		style.corner_radius_top_right = 0 if sun else 10
		style.corner_radius_bottom_right = 0 if sun else 10
		cell.add_theme_stylebox_override("panel", style)
		var inner := UiKit.hbox(6)
		inner.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.add_child(UiKit.ctl(MealUi.period_icon(period), 20, Palette.WOOD_INK if sun else Palette.WOOD_CREAM))
		var label := StepCardUi.wood(MealUi.period_name(period), 15, Palette.WOOD_INK if sun else Palette.WOOD_CREAM)
		inner.add_child(label)
		cell.add_child(inner)
		bar.add_child(cell)
	column.add_child(bar)
	# Horas: 6h na ponta, 16h na virada, 6h na outra ponta (a posição segue a proporção das metades).
	var hours := Control.new()
	hours.name = "DayHours"
	hours.custom_minimum_size = Vector2(BAR_W, 18)
	hours.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var marks: Array[Dictionary] = []
	for i in periods.size():
		marks.append({"x": cuts[i] / total, "text": "%dh" % GameState.meal_window(str(periods[i])).x})
	marks.append({"x": 1.0, "text": "%dh" % GameState.meal_window(str(periods[0])).x})
	for mark: Dictionary in marks:
		var hour := StepCardUi.wood(str(mark.text), 13, Color(Palette.WOOD_INK, 0.85))
		hour.name = "Hour_" + str(mark.text)
		var width := 34.0
		hour.size = Vector2(width, 18)
		hour.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hour.position = Vector2(clampf(BAR_W * float(mark.x) - width / 2.0, 0.0, BAR_W - width), 0.0)
		hours.add_child(hour)
	column.add_child(hours)
	return column


static func period_is_sun(period: String, periods: Array) -> bool:
	return periods.find(period) <= 0
