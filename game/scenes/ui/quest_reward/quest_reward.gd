class_name QuestReward
extends CanvasLayer
## Folha de um passo já pago. A fila da casca é a única responsável por abri-la.
var _panel: PanelContainer
var _body: VBoxContainer
var _scroll: ScrollContainer
var _drag_y := 0.0
var _last_y := 0.0
var _last_ms := 0
var _velocity := 0.0
var _dragging := false
var _rest_y := 0.0
var _tween: Tween

func _ready() -> void:
	layer = 24
	hide()
	var full := Control.new()
	full.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(full)
	var dim := ColorRect.new()
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	full.add_child(dim)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed: close())
	_panel = PanelContainer.new()
	_panel.name = "RewardPanel"
	var style := UiKit.surface(Palette.PAPER, 28, true)
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
	full.add_child(_panel)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(_scroll)
	_body = UiKit.vbox(12)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_body)
	full.resized.connect(_layout)

func open(id: String, next: String = "") -> void:
	if next == "": next = GameState.progress.current_main_quest()
	for child: Node in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	var handle := Control.new()
	handle.name = "RewardHandle"
	handle.custom_minimum_size.y = 12
	handle.draw.connect(func() -> void: handle.draw_style_box(UiKit.surface(Palette.LINE, 3), Rect2((handle.size.x - 40) / 2, 0, 40, 5)))
	handle.resized.connect(handle.queue_redraw)
	handle.gui_input.connect(_drag_input)
	_body.add_child(handle)
	var header := UiKit.hbox(8)
	var ribbon := PanelContainer.new()
	ribbon.name = "RewardRibbon"
	var style := UiKit.surface(Palette.GO, 18)
	style.set_content_margin_all(8)
	ribbon.add_theme_stylebox_override("panel", style)
	var title := UiKit.hbox(4)
	title.add_child(UiKit.ctl("check", 20, Palette.CARD))
	title.add_child(UiKit.short_label("Passo concluído!", &"StrongLabel", Palette.CARD))
	ribbon.add_child(title)
	header.add_child(ribbon)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var x := UiKit.ctl_button("x", close, 32, "sunken")
	x.name = "RewardClose"
	header.add_child(x)
	header.gui_input.connect(_drag_input)
	_body.add_child(header)
	var quest: Dictionary = Database.quests[id]
	var next_quest: Dictionary = Database.quests.get(next, {})
	var npc := str(quest.get("npc", "lais"))
	var speech := UiKit.hbox(8)
	speech.name = "RewardSpeech"
	speech.add_child(UiKit.disc(ProgressionUi.npc_portrait(npc), 56, 56))
	var text := str(next_quest.get("dialogue", ""))
	if text == "": text = str(Database.npcs.get(npc, {}).get("greeting", ""))
	var bubble := SpeechBubble.new(text)
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speech.add_child(bubble)
	_body.add_child(speech)
	var chips := UiKit.flow(8)
	chips.name = "RewardChips"
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	_body.add_child(chips)
	var rewards: Dictionary = quest.get("rewards", {})
	if int(rewards.get("coins", 0)) > 0: _chip(chips, "coins", UiKit.ui_icon("coin"), int(rewards.coins))
	for item: String in rewards.get("items", {}): _chip(chips, item, Database.item_icon(item), int(rewards.items[item]))
	if next != "":
		_body.add_child(UiKit.section("Próximo passo"))
		_body.add_child(ProgressionUi.next_step_card(next))
	var actions := UiKit.hbox(8)
	if next != "":
		var later := UiKit.soft("Depois", close)
		later.name = "RewardLater"
		actions.add_child(later)
	var target := Places.quest_target(next) if next != "" else {}
	var go := UiKit.primary("Ir para " + ProgressionUi.quest_place_name(target) if next != "" else "Que bom!", func() -> void:
		close()
		if next != "": Places.go(target))
	go.name = "RewardGo"
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(go)
	_body.add_child(actions)
	_scroll.scroll_vertical = 0
	show()
	Haptics.success()
	_layout.call_deferred()
	if not Motion.reduced: _animate_open.call_deferred()

func _chip(host: Control, id: String, texture: Texture2D, amount: int) -> void:
	var chip := UiKit.chip(texture, "+%d" % amount, null, "prize")
	chip.name = "RewardChip_" + id
	chip.custom_minimum_size.y = 44
	var row := chip.get_child(0) as HBoxContainer
	(row.get_child(0) as TextureRect).custom_minimum_size = Vector2(36, 36)
	var label := row.get_child(1) as Label
	label.theme_type_variation = &"NumberLabel"
	if Database.items.get(id, {}).get("category", "") == "keepsake": row.add_child(UiKit.spark())
	host.add_child(chip)
	Motion.count_up(label, 0, amount, "+%d")

func _layout() -> void:
	if not visible: return
	var area := get_viewport().get_visible_rect().size
	_panel.size.x = area.x - 16
	_body.custom_minimum_size.x = area.x - 48
	var height := minf(_body.get_combined_minimum_size().y + 32, area.y - 32)
	_panel.size.y = height
	_panel.position = Vector2(8, area.y - height - 8)
	_rest_y = _panel.position.y

func _animate_open() -> void:
	_layout()
	if _tween: _tween.kill()
	_panel.position.y = get_viewport().get_visible_rect().size.y
	_tween = create_tween()
	_tween.tween_property(_panel, "position:y", _rest_y, Motion.SHEET_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func close() -> void:
	if _tween: _tween.kill()
	hide()
	_dragging = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"): close()

func _drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_y = event.global_position.y
			_last_y = _drag_y
			_last_ms = Time.get_ticks_msec()
			_velocity = 0
		elif _dragging:
			_dragging = false
			var distance: float = event.global_position.y - _drag_y
			if distance > 8 and (distance > _panel.size.y * 0.25 or (Time.get_ticks_msec() - _last_ms < 120 and _velocity > 900)): close()
			else: _panel.position.y = _rest_y
	elif event is InputEventMouseMotion and _dragging:
		var now := Time.get_ticks_msec()
		if now > _last_ms: _velocity = (event.global_position.y - _last_y) * 1000 / (now - _last_ms)
		_last_ms = now
		_last_y = event.global_position.y
		_panel.position.y = _rest_y + maxf(0, _last_y - _drag_y)
