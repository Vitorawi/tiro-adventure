class_name WorldCard
extends Button
## Linha de destino: ícone, nome e avisos curtos; o mundo inteiro cabe no seletor.

const ROW_HEIGHT := 72.0
const COMPACT_HEIGHT := 64.0
const ICON_SIZE := 40
var world_id := ""
var _picture: TextureRect
var _title: Label
var _here: Label
var _lock: TextureRect
var _arrow: Label
var _status: HFlowContainer
var _hint: Label
var _style: StyleBoxFlat


func setup(id: String) -> void:
	world_id = id
	name = "WorldCard_" + id
	custom_minimum_size = Vector2(0, ROW_HEIGHT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE
	_style = StyleBoxFlat.new()
	_style.bg_color = Palette.CARD
	_style.border_color = Palette.CARD_LINE
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(16)
	for kind: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(kind, _style)
	var world: Dictionary = Database.worlds[id]
	_picture = UiKit.icon(UiKit.ui_icon(str(world.get("icon", "tab_map"))), ICON_SIZE)
	_picture.name = "WorldIcon"
	add_child(_picture)
	_title = UiKit.label(str(world.get("map_name", world.name)), &"TitleLabel")
	_title.name = "WorldName"

	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(_title)
	_here = UiKit.label("Aqui", &"SmallLabel", Palette.GOOD)
	_here.name = "CurrentWorld"
	_here.add_theme_font_size_override("font_size", 16)
	_here.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(_here)
	_lock = UiKit.lock_icon(20)
	_lock.name = "WorldLock"
	add_child(_lock)
	_arrow = UiKit.label("›", &"SectionLabel", Palette.INK_SOFT)
	_arrow.add_theme_font_size_override("font_size", 30)
	add_child(_arrow)
	_status = UiKit.flow(6)
	_status.name = "WorldStatusRows"
	_status.add_theme_constant_override("v_separation", 0)
	add_child(_status)
	_hint = UiKit.label("", &"SmallLabel", Palette.INK_SOFT)
	_hint.name = "WorldHint"
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_hint)
	resized.connect(_layout)
	refresh("")


func refresh(current: String) -> void:
	disabled = Places.world_error(world_id) != ""
	_here.visible = not disabled and current == world_id
	_lock.visible = disabled
	_arrow.visible = not disabled and not _here.visible
	_picture.modulate.a = 0.45 if disabled else 1.0
	_style.bg_color = Palette.CARD.lerp(Palette.PRIMARY, 0.12) if _here.visible else Palette.CARD
	_style.border_color = Palette.PRIMARY if _here.visible else Palette.CARD_LINE
	for child: Node in _status.get_children():
		_status.remove_child(child)
		child.queue_free()
	var summary := Places.world_summary(world_id)
	if not disabled:
		for entry: Array in [
			["rewards", "tab_tasks", "prêmio", "prêmios", Palette.GOOD],
			["collections", "check", "coleta", "coletas", Palette.GOOD],
			["missions", "tab_tasks", "missão", "missões", Palette.ACCENT_EDGE],
			["finds", "find_paw", "achado", "achados", Palette.INFO],
			["treasure", "item_map_piece", "tesouro", "tesouros", Palette.ACCENT_EDGE],
		]:
			var amount := int(summary[str(entry[0])])
			if amount <= 0: continue
			var notice := UiKit.hbox(3)
			notice.name = "WorldStatus_" + str(entry[0])
			notice.add_child(UiKit.icon(UiKit.ctl_icon("check") if str(entry[1]) == "check" else UiKit.ui_icon(str(entry[1])), 14))
			var caption := UiKit.label("%d %s" % [amount, str(entry[2] if amount == 1 else entry[3])], &"SmallLabel", entry[4])
			caption.autowrap_mode = TextServer.AUTOWRAP_OFF
			caption.add_theme_font_size_override("font_size", 16)
			notice.add_child(caption)
			_status.add_child(notice)
	_status.visible = _status.get_child_count() > 0
	_hint.visible = not _status.visible
	_hint.text = _locked_hint() if disabled else "Tudo em dia"
	_layout()
	_ignore_mouse(self)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _locked_hint() -> String:
	var world: Dictionary = Database.worlds[world_id]
	if world.has("map_locked_hint"):
		return str(world.map_locked_hint)
	var requirements: Dictionary = world.get("requirements", {})
	for id: String in requirements.get("quests", []):
		if not GameState.progress.claimed_quests.has(id):
			return "Após " + str(Database.quests.get(id, {}).get("name", id))
	if requirements.has("chapter"):
		var chapter := int(requirements.chapter)
		var chapters: Array = Database.progression.chapters
		return "Capítulo %d · %s" % [chapter, str(chapters[chapter - 1].name)] if chapter > 0 and chapter <= chapters.size() else Places.world_error(world_id)
	return Places.world_error(world_id)


func _layout() -> void:
	if not is_instance_valid(_hint): return
	var extra := maxf(0, (size.y - COMPACT_HEIGHT) * 0.5)
	var text_width := maxf(0, size.x - 86)
	_picture.position = Vector2(12, (size.y - ICON_SIZE) * 0.5)
	_picture.size = Vector2(ICON_SIZE, ICON_SIZE)
	_title.position = Vector2(62, 3 + extra)
	_title.size = Vector2(text_width - (34 if _here.visible else 0), 26)
	_here.position = Vector2(size.x - 48, 8 + extra)
	_here.size = Vector2(36, 20)
	_lock.position = Vector2(size.x - 30, (size.y - 20) * 0.5)
	_lock.size = Vector2(20, 20)
	_arrow.position = Vector2(size.x - 25, (size.y - 32) * 0.5)
	_arrow.size = Vector2(16, 32)
	_status.position = Vector2(62, 29 + extra)
	_status.size = Vector2(text_width, 32)
	_hint.position = Vector2(62, 29 + extra)
	_hint.size = Vector2(text_width, 32)


func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		if child is Control: _ignore_mouse(child)
