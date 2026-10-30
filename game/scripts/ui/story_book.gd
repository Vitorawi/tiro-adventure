class_name StoryBook
extends Control
## "História completa" no visual madeira ilustrada: janela por cima da tela inteira (fundo escurecido, tocar fora
## fecha) com o quadro de madeira, a placa "História", o X redondo e um cartão por capítulo (concluído compacto,
## atual com barra e passos, futuros apagados com cadeado). Abre com `StoryBook.open()` (host: nó "Main").

const FRAME_SIDE := 8.0
const BORDER := 30.0
const PAD := 12.0
const CLOSE_PX := 40.0
const CLOSE_HIT := 44.0
const BOOK_NAME := "StoryBook"

var _frame: NinePatchRect
var _scroll: ScrollContainer
var _catcher: Control
var _plaque: Control
var _close: Button
var _current_card: Control


## Abre o livro (um só por vez). Devolve o nó, ou null se não achou a casca.
static func open() -> StoryBook:
	var tree := Engine.get_main_loop() as SceneTree
	var host := tree.root.find_child("Main", true, false) as Control
	if host == null:
		return null
	var old := host.get_node_or_null(BOOK_NAME)
	if old != null:
		old.free()
	var book := StoryBook.new()
	book.name = BOOK_NAME
	host.add_child(book)
	return book


func _ready() -> void:
	# Acima do HUD (8), da barra de abas (5), de popovers (13) e de avisos (12-20 só ao aparecer): 14 cobre HUD e abas.
	z_index = 14
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_dim_input)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var holder := Control.new()
	holder.name = "BookHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame = MissionUi.frame(holder, "frame", Vector4(BORDER, BORDER, BORDER, BORDER), "Frame", Vector4.ZERO, false)
	_catcher = Control.new()
	_catcher.name = "Catcher"
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	holder.add_child(_catcher)
	_scroll = ScrollContainer.new()
	_scroll.name = "BookScroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll.clip_contents = true
	holder.add_child(_scroll)
	var list := VBoxContainer.new()
	list.name = "Chapters"
	list.add_theme_constant_override("separation", 8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(list)
	_fill_chapters(list)
	_close = BagUi.plain_button(close)
	_close.name = "StoryClose"
	_close.custom_minimum_size = Vector2(CLOSE_HIT, CLOSE_HIT)
	var art := TextureRect.new()
	art.texture = MissionUi.tex("close")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_close.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	art.offset_left = -CLOSE_PX / 2.0
	art.offset_right = CLOSE_PX / 2.0
	art.offset_top = -CLOSE_PX / 2.0
	art.offset_bottom = CLOSE_PX / 2.0
	_close.pressed.connect(func() -> void: Motion.bounce(art))
	holder.add_child(_close)
	resized.connect(_layout)
	_layout()
	_layout.call_deferred()
	_scroll_to_current.call_deferred()
	if not Motion.reduced:
		Motion.pop_in(holder, Vector2.ONE, 0.92)
		holder.pivot_offset = size / 2.0


func close() -> void:
	if is_inside_tree():
		get_parent().remove_child(self)
	queue_free()


func _dim_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and not click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		close()


func _bar_top() -> float:
	var top := INF
	var host := get_parent()
	if host != null:
		for node_name: String in ["TabBarArt", "TabBar"]:
			var bar := host.find_child(node_name, true, false) as Control
			if bar != null and bar.is_visible_in_tree():
				top = minf(top, bar.get_global_rect().position.y)
	return top if top != INF else size.y - 96.0


func _layout() -> void:
	if size.x <= 0.0:
		return
	var top := Hud.HEIGHT - 6.0
	var bottom := _bar_top() - 2.0
	var width := size.x - 2.0 * FRAME_SIDE
	_frame.position = Vector2(FRAME_SIDE, top)
	_frame.size = Vector2(width, bottom - top) * 3.0
	_catcher.position = Vector2(FRAME_SIDE, top)
	_catcher.size = Vector2(width, bottom - top)
	var inner := BORDER + PAD
	_scroll.position = Vector2(FRAME_SIDE + inner, top + inner)
	_scroll.size = Vector2(width - 2.0 * inner, bottom - top - 2.0 * inner)
	if _plaque != null:
		_plaque.get_parent().remove_child(_plaque)
		_plaque.free()
	_plaque = MissionUi.plaque("História", roundf(width * 0.66))
	_plaque.position = Vector2(roundf(size.x / 2.0 - _plaque.size.x / 2.0), top - _plaque.size.y / 2.0)
	_catcher.get_parent().add_child(_plaque)
	_catcher.get_parent().move_child(_close, -1)
	_close.position = Vector2(FRAME_SIDE + width - CLOSE_HIT + 2.0, top - CLOSE_HIT / 2.0 - 4.0)


func _scroll_to_current() -> void:
	if _current_card != null and is_instance_valid(_current_card):
		_scroll.scroll_vertical = maxi(0, int(_current_card.position.y) - 4)


func _fill_chapters(list: VBoxContainer) -> void:
	var current := GameState.progress.chapter_index()
	var chapters: Array = Database.progression.chapters
	for i in chapters.size():
		var index := i + 1
		var name_text := str((chapters[i] as Dictionary).get("name", ""))
		var card: Control
		if index < current:
			card = _done_card(index, name_text)
		elif index == current:
			card = _current_chapter_card(index, name_text)
			_current_card = card
		else:
			card = _future_card(index, name_text)
		list.add_child(card)


func _chapter_label(index: int) -> Label:
	var label := MissionUi.text("Capítulo %d" % index, 12, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_LEFT)
	label.modulate.a = 0.7
	return label


func _name_label(value: String, px: int = 17) -> Label:
	var label := MissionUi.text(value, px, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_LEFT)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MissionUi.tap_full_text(label)
	return label


func _done_card(index: int, name_text: String) -> Control:
	var card := MissionUi.card("card", Vector4i(14, 8, 14, 8), "BookChapter_%d" % index)
	var row := UiKit.hbox(8)
	var names := UiKit.vbox(0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(_chapter_label(index))
	names.add_child(_name_label(name_text))
	row.add_child(names)
	var check := UiKit.ctl("check", 22, Palette.GO)
	check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(check)
	MissionUi.body(card).add_child(row)
	return card


func _future_card(index: int, name_text: String) -> Control:
	var card := MissionUi.card("card", Vector4i(14, 8, 14, 8), "BookChapter_%d" % index)
	card.modulate.a = 0.55
	var row := UiKit.hbox(8)
	var names := UiKit.vbox(0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.add_child(_chapter_label(index))
	names.add_child(_name_label(name_text))
	row.add_child(names)
	row.add_child(_lock_disc())
	MissionUi.body(card).add_child(row)
	return card


## Disquinho creme com o cadeado escuro (igual ao `TabLock` das abas).
func _lock_disc() -> Control:
	var lock := PanelContainer.new()
	lock.name = "BookLock"
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var disc := StyleBoxFlat.new()
	disc.bg_color = Palette.WOOD_INSET
	disc.set_corner_radius_all(12)
	disc.set_content_margin_all(4)
	lock.add_theme_stylebox_override("panel", disc)
	lock.add_child(UiKit.ctl("lock", 16, Palette.WOOD_INK))
	return lock


func _current_chapter_card(index: int, name_text: String) -> Control:
	var card := MissionUi.card("card", Vector4i(14, 10, 14, 12), "BookChapter_%d" % index)
	var box := UiKit.vbox(8)
	box.add_child(_chapter_label(index))
	box.add_child(_name_label(name_text, 18))
	var ids := GameState.progress.main_quests(index)
	var done := 0
	for id: String in ids:
		if GameState.progress.claimed_quests.has(id):
			done += 1
	box.add_child(MissionUi.bar(float(done) / maxf(1.0, float(ids.size())), "%d/%d" % [done, ids.size()]))
	var now := GameState.progress.current_main_quest()
	var steps := UiKit.vbox(4)
	steps.name = "BookSteps"
	for id: String in ids:
		steps.add_child(_step_row(id, id == now))
	box.add_child(steps)
	MissionUi.body(card).add_child(box)
	return card


func _step_row(id: String, is_now: bool) -> Control:
	var claimed := GameState.progress.claimed_quests.has(id)
	var panel := PanelContainer.new()
	panel.name = "BookStep_" + id
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WOOD_INSET if is_now else Color(0, 0, 0, 0)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	if is_now:
		style.border_color = Palette.WOOD_PICK
		style.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", style)
	var row := UiKit.hbox(8)
	row.custom_minimum_size = Vector2(0, 28)
	var icon: Control
	if claimed:
		icon = UiKit.ctl("check", 20, Palette.GO)
	elif is_now:
		icon = UiKit.ctl("chev", 20, Palette.WOOD_INK)
	else:
		icon = UiKit.ctl("lock", 18, Palette.WOOD_INK)
		icon.modulate.a = 0.6
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := _name_label(str(Database.quests[id].name), 15)
	label.name = "StepName"
	if not claimed and not is_now:
		label.modulate.a = 0.6
	row.add_child(label)
	panel.add_child(row)
	return panel
