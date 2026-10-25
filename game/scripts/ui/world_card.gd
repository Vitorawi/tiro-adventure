class_name WorldCard
extends Button
## Cartão-postal com foto fixa e os bloqueios reais do mundo.
var world_id := ""
var wide := false
var photo_height := 104.0
var _picture: TextureRect
var _title: Label
var _world_icon: TextureRect
var _here: Control
var _lock: Control
var _status: HBoxContainer
var _hint: Label
var _opener: TextureRect
var _style: StyleBoxFlat

func setup(id: String) -> void:
	world_id = id
	name = "WorldCard_" + id
	focus_mode = Control.FOCUS_NONE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style = UiKit.surface(Palette.CARD, 20, true)
	_style.border_color = Palette.HONEY
	for kind: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(kind, _style)
	var world: Dictionary = Database.worlds[id]
	_picture = UiKit.icon(null, 0)
	_picture.name = "WorldPhoto"
	_picture.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_picture)
	_world_icon = UiKit.icon(UiKit.ui_icon(str(world.get("icon", "tab_map"))), 28)
	_world_icon.name = "WorldIcon"
	add_child(_world_icon)
	_title = UiKit.short_label(str(world.get("map_name", world.name)), &"StrongLabel")
	_title.name = "WorldName"
	add_child(_title)
	_here = UiKit.postcard_chip(UiKit.ctl_icon("check"), "Aqui", true)
	_here.name = "CurrentWorld"
	add_child(_here)
	_lock = UiKit.disc(UiKit.ctl_icon("lock"), 44, 22)
	_lock.name = "WorldLock"
	_lock.add_theme_stylebox_override("panel", UiKit.surface(Palette.CARD, 22, true))
	add_child(_lock)
	_status = UiKit.hbox(4)
	_status.name = "WorldStatusRows"
	add_child(_status)
	_hint = UiKit.label("", &"SmallLabel", Palette.INK_SOFT)
	_hint.name = "WorldHint"
	add_child(_hint)
	_opener = UiKit.icon(null, 20)
	_opener.name = "WorldOpener"
	add_child(_opener)
	resized.connect(_layout)
	refresh("")

func refresh(current: String) -> void:
	disabled = Places.world_error(world_id) != ""
	_here.visible = not disabled and current == world_id
	_lock.visible = disabled
	_style.set_border_width_all(3 if _here.visible else 0)
	var path := "res://assets/sprites/ui/worlds/%s%s.png" % [world_id, "_locked" if disabled else ""]
	if ResourceLoader.exists(path): _picture.texture = load(path)
	for child: Node in _status.get_children():
		_status.remove_child(child)
		child.queue_free()
	var summary := Places.world_summary(world_id)
	if not disabled:
		for npc: String in Database.worlds[world_id].get("npcs", []):
			if Places.npc_badge(npc) == "": continue
			var badge := UiKit.postcard_chip(ProgressionUi.npc_portrait(npc), "!")
			badge.name = "WorldStatus_missions"
			_status.add_child(badge)
			break
		# Categorias independentes: prêmio de missão, coleta, achado do Tiro e tesouro.
		for entry: Array in [["rewards", UiKit.ctl_icon("check")], ["collections", UiKit.ctl_icon("check")],
				["finds", UiKit.ui_icon("find_paw")], ["treasure", UiKit.ui_icon("item_map_piece")]]:
			var amount := int(summary.get(entry[0], 0))
			if amount <= 0: continue
			var chip := UiKit.postcard_chip(entry[1], str(amount))
			chip.name = "WorldStatus_" + str(entry[0])
			# Com até quatro categorias a fileira precisa caber na largura do cartão (2 colunas em 360 px).
			var style := chip.get_theme_stylebox("panel") as StyleBoxFlat
			style.content_margin_left = 5
			style.content_margin_right = 6
			chip.get_child(0).add_theme_constant_override("separation", 2)
			_status.add_child(chip)
	_status.visible = _status.get_child_count() > 0
	_hint.visible = disabled
	_hint.text = _locked_hint() if disabled else ""
	_opener.visible = false
	var requirements: Dictionary = Database.worlds[world_id].get("requirements", {})
	for quest: String in requirements.get("quests", []):
		var npc: String = Database.quests.get(quest, {}).get("npc", "")
		if npc != "":
			_opener.texture = ProgressionUi.npc_portrait(npc)
			_opener.visible = disabled
			break
	_layout()
	_ignore_mouse(self)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _locked_hint() -> String:
	var world: Dictionary = Database.worlds[world_id]
	if world.has("map_locked_hint"): return str(world.map_locked_hint)
	var requirements: Dictionary = world.get("requirements", {})
	for id: String in requirements.get("quests", []):
		if not GameState.progress.claimed_quests.has(id):
			return "Depois de: " + str(Database.quests.get(id, {}).get("name", id))
	if requirements.has("chapter"):
		return "Capítulo %d" % int(requirements.chapter)
	return Places.world_error(world_id)

func _layout() -> void:
	if not is_instance_valid(_hint): return
	_picture.position = Vector2(6, 6)
	_picture.size = Vector2(maxf(0, size.x - 12), photo_height)
	_world_icon.position = Vector2(12, photo_height + 16)
	_world_icon.size = Vector2(28,28)
	_title.position = Vector2(46, photo_height + 16)
	_title.size = Vector2(maxf(0, size.x - 58), 28)
	_here.position = Vector2(maxf(8, size.x - _here.get_combined_minimum_size().x - 12), 12)
	_lock.position = Vector2((size.x - 44) / 2, 6 + (photo_height - 44) / 2)
	_status.position = Vector2(12, photo_height - 26)
	_status.size = _status.get_combined_minimum_size()
	var hint_top := photo_height + (12 if wide else 48)
	var hint_left := 160.0 if wide else 12.0
	_hint.position = Vector2(hint_left, hint_top)
	_hint.size = Vector2(maxf(0,size.x - hint_left - (36 if _opener.visible else 12)), 0)
	_hint.size.y = _hint.get_minimum_size().y
	_opener.position = Vector2(size.x - 32, hint_top + 4)
	_opener.size = Vector2(20,20)

func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in node.get_children():
		if child is Control: _ignore_mouse(child)
