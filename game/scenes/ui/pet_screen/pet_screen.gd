extends Control
## Cantinho do Tiro: cenário, anéis, cuidados com o dedo e caderninho.

const MOOD_LOW := 25.0
const MOOD_TEXTS := {"hunger": "Estou com fome!", "happiness": "Quero brincar...", "energy": "Que soninho...", "hygiene": "Preciso de um banho!"}
const STROKE_STEP := 28.0
const PET_REWARD_EVERY := 1.2
var _bars: Dictionary = {}
var _pulses: Dictionary = {}
var _animator: PetAnimator
var _bond_chip: Button
var _bond_ring: RingProgress
var _growth_badge: Button
var _growth_ring: RingProgress
var _growth_number: Label
var _growth_hint: Label
var _growth_pulse: Tween
var _bond_caption: Label
var _wish_bubble: Button
var _wish_icon: TextureRect
var _away_view: VBoxContainer
var _away_postcard: TextureRect
var _away_name: Label
var _away_time: Label
var _away_collect: Button
var _away_walker: AnimatedSprite2D
var _away_body := ""
var _stroke_distance := 0.0
var _last_pet_reward := -10.0
var _last_pet_feedback := -10.0
var _pet_message := ""
var _pet_message_until := 0.0
var _care: PetCareTray
var _mood_bubble: SpeechBubble
var _mood_label: Label
var _manual: Button
var _new_badge: Label
var _corner: PetBackdrop
var _mood_age := 20.0
var _wish_age := 0.0
var _sleep_age := 0.0
var _minute := -1
var _pillar_pending: Dictionary = {}
var _pillar_showing := false
var _knots: Array[Control] = []
## Apenas apresentação: testes/capturas podem forçar a hora, sem tocar no relógio do jogo.
var preview_hour := -1

@onready var _dog_sprite: TextureRect = %DogSprite


func _ready() -> void:
	_corner = %Corner
	var decor := CornerDecor.new()
	decor.name = "CornerDecor"
	decor.backdrop = _corner
	decor.set_anchors_preset(Control.PRESET_FULL_RECT)
	_corner.add_child(decor)
	%DogArea.draw.connect(_draw_dog_shadow)
	%Stars.draw.connect(func() -> void:
		for point: Vector2 in [Vector2(8, 6), Vector2(42, 18), Vector2(24, 42)]:
			%Stars.draw_circle(point, 2.0, Palette.GOLD))
	_dog_sprite.gui_input.connect(_on_dog_input)
	_animator = PetAnimator.new()
	add_child(_animator)
	_animator.setup(_dog_sprite)
	_build_need_rings()
	var need_back := Panel.new()
	need_back.name = "NeedsPanel"
	need_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var paper := StyleBoxFlat.new()
	paper.bg_color = Palette.PET_SURFACE
	paper.set_corner_radius_all(24)
	paper.shadow_color = Palette.SHADE
	paper.shadow_size = 5
	paper.shadow_offset = Vector2(0, 2)
	paper.border_color = Palette.CARD_LINE

	need_back.add_theme_stylebox_override("panel", paper)
	add_child(need_back)
	move_child(need_back, %Margin.get_index())
	need_back.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	need_back.offset_left = 12
	need_back.offset_right = -12
	need_back.offset_top = 88
	need_back.offset_bottom = 196
	_mood_bubble = SpeechBubble.new()
	_mood_bubble.name = "MoodBubble"
	_mood_label = _mood_bubble.label
	_mood_label.name = "MoodLabel"
	_mood_label.add_theme_font_size_override("font_size", 18)
	add_child(_mood_bubble)
	_build_wish_widgets()
	_manual = UiKit.icon_button(UiKit.ui_icon("ui_notebook"), PetNotebook.open, 52)
	_manual.name = "ManualButton"
	add_child(_manual)
	_new_badge = UiKit.alert_badge()
	_new_badge.name = "NotebookNewBadge"
	_new_badge.position = Vector2(32, -4)
	_new_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_manual.add_child(_new_badge)
	_new_badge.reset_size()
	_care = PetCareTray.new()
	_care.pet_screen = self
	%VBox.add_child(_care)
	_build_away_view()
	_build_baggage_button()
	Events.state_changed.connect(_refresh)
	Events.pillar_gained.connect(_on_pillar_gained)
	Events.taste_reacted.connect(_on_taste)
	%RefreshTimer.timeout.connect(_refresh)
	resized.connect(_layout_corner)
	_corner.resized.connect(_layout_corner)
	%DogArea.resized.connect(_layout_corner)
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree(): _care.cancel())
	_layout_corner.call_deferred()
	_refresh()


func play_growth_feedback(before: Dictionary, after: Dictionary) -> void:
	var gained := int(after.points) - int(before.points)
	var stored := int(after.reserve) - int(before.reserve)
	var message := str(after.status)
	if gained > 0:
		message = "Esperteza +%d · %d/%d" % [gained, after.points, after.cap]
	if stored > 0:
		message = (message + "\n" if gained > 0 else "Esperteza · ") + "+%d guardado para depois de crescer." % stored
	elif gained == 0 and int(after.seconds) == 0:
		message = str(after.hint)
	_pet_message = message
	_pet_message_until = Time.get_ticks_msec() / 1000.0 + 4.0
	_mood_label.text = message
	_show_mood()


func _on_pillar_gained(id: String, points: int, _level_up: bool) -> void:
	if not is_visible_in_tree(): return
	_pillar_pending[id] = int(_pillar_pending.get(id, 0)) + points
	if not _pillar_showing:
		_pillar_showing = true
		_show_pillar_gains.call_deferred()


func _show_pillar_gains() -> void:
	while not _pillar_pending.is_empty():
		var id: String = _pillar_pending.keys()[0]
		var points := int(_pillar_pending[id])
		_pillar_pending.erase(id)
		if is_visible_in_tree():
			var head := head_rect()
			var pos := Vector2(head.get_center().x - 28, head.position.y + 12) - global_position
			Motion.float_text(self, pos, "+%d" % points, Palette.GOLD)
			if not Motion.reduced:
				var radiant := GameState.CARE_NEEDS.all(func(need: String) -> bool:
					return GameState.dog.get_need(need, GameState.now()) >= float(Database.growth.radiant.min_need))
				if radiant:
					_dog_sprite.modulate = Color(1.3, 1.2, 1.0)
					_dog_sprite.create_tween().tween_property(_dog_sprite, "modulate", Color.WHITE, Motion.FLOAT)
				var icon := TextureRect.new()
				icon.texture = UiKit.ui_icon(str(Database.growth.pillars[id].icon))
				icon.position = pos + Vector2(40, 0)
				icon.z_as_relative = false
				icon.z_index = Motion.WORLD_FX_Z
				icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(icon)
				var tween := icon.create_tween().set_parallel()
				tween.tween_property(icon, "position:y", icon.position.y - 28, Motion.FLOAT).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				tween.tween_property(icon, "modulate:a", 0.0, Motion.FLOAT).set_delay(Motion.FLOAT * 0.4)
				tween.chain().tween_callback(icon.queue_free)
		await get_tree().create_timer(Motion.FLOAT).timeout
	_pillar_showing = false


func _build_need_rings() -> void:
	for id: String in Database.needs:
		var ring := RingProgress.new()
		ring.name = "Need_" + id
		ring.custom_minimum_size = Vector2(64, 64)
		ring.texture = Database.need_icon(id)
		ring.mouse_filter = Control.MOUSE_FILTER_STOP
		ring.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				var value := GameState.dog.get_need(id, GameState.now())
				var text := "%s %d%%" % [Database.needs[id].name, roundi(value)]
				if value < MOOD_LOW: text += "\n" + str(MOOD_TEXTS.get(id, ""))
				Popover.open(self, ring, UiKit.label(text, &"SmallLabel")))
		var need := UiKit.vbox(2)
		need.add_child(ring)
		var caption := UiKit.short_label(str(Database.needs[id].name), &"SmallLabel")
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		need.add_child(caption)
		%NeedsGrid.add_child(need)
		_bars[id] = ring
	_bond_chip = UiKit.ghost("", func() -> void:
		Events.sheet_requested.emit("Vínculo", WishUi.bond_panel()))
	_bond_chip.name = "BondChip"
	_bond_chip.custom_minimum_size = Vector2(48, 88)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		_bond_chip.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_bond_ring = RingProgress.new()
	_bond_ring.custom_minimum_size = Vector2(48, 48)
	_bond_ring.size = Vector2(48, 48)
	_bond_ring.texture = UiKit.ui_icon("bond_heart")
	_bond_ring.color = Palette.DANGER
	_bond_ring.done_color = Palette.DANGER
	_bond_ring.position = Vector2(0, 8)
	_bond_chip.add_child(_bond_ring)
	_bond_caption = UiKit.short_label("1", &"SmallLabel")
	_bond_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bond_caption.position = Vector2(0, 66)
	_bond_caption.size = Vector2(48, 20)
	_bond_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bond_chip.add_child(_bond_caption)
	# Vínculo e crescimento lado a lado abaixo das necessidades, sem espremer os quatro anéis.
	var badges := UiKit.hbox(12)
	badges.name = "LifeBadges"
	badges.position = Vector2(20, 204)
	add_child(badges)
	badges.add_child(_bond_chip)
	_growth_badge = UiKit.ghost("", GrowthUi.open)
	_growth_badge.name = "GrowthBadge"
	for state: String in ["normal", "hover", "pressed", "focus"]:
		_growth_badge.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	_growth_badge.custom_minimum_size = Vector2(92, 88)
	_growth_ring = RingProgress.new()
	_growth_ring.custom_minimum_size = Vector2(44, 44)
	_growth_ring.size = Vector2(44, 44)
	_growth_ring.position = Vector2(24, 8)
	_growth_badge.add_child(_growth_ring)
	_growth_number = UiKit.short_label("0", &"SectionLabel")
	_growth_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_growth_number.position = Vector2(24, 16)
	_growth_number.size = Vector2(44, 28)
	_growth_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_growth_badge.add_child(_growth_number)
	_growth_hint = UiKit.short_label("Crescer", &"SmallLabel")
	_growth_hint.name = "GrowthBadgeHint"
	_growth_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_growth_hint.position = Vector2(0, 58)
	_growth_hint.size = Vector2(92, 24)
	_growth_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint_back := PanelContainer.new()
	hint_back.theme_type_variation = &"ChipPanel"
	hint_back.position = Vector2(0, 58)
	hint_back.size = Vector2(92, 24)
	hint_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_back.add_child(_growth_hint)
	_growth_badge.add_child(hint_back)
	badges.add_child(_growth_badge)


func _build_wish_widgets() -> void:
	_wish_bubble = UiKit.icon_button(UiKit.ui_icon("wish_bubble"), func() -> void:
		Events.screen_requested.emit(&"wishes"), 64)
	_wish_bubble.name = "WishBubble"
	_wish_bubble.add_theme_constant_override("icon_max_width", 64)
	for style: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		_wish_bubble.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	_wish_icon = UiKit.icon(null, 32)
	_wish_icon.position = Vector2(16, 12)
	_wish_bubble.add_child(_wish_icon)
	add_child(_wish_bubble)
	_dog_sprite.item_rect_changed.connect(_place_bubble)


func _place_bubble() -> void:
	if _wish_bubble:
		_wish_bubble.position = _dog_sprite.global_position - global_position + Vector2(_dog_sprite.size.x * 0.72, _dog_sprite.size.y * 0.18)
	if _away_collect:
		var area: Control = %DogArea
		_away_collect.position = Vector2((size.x - _away_collect.size.x) * 0.5, area.global_position.y - global_position.y + area.size.y - _away_collect.size.y - 12.0)
	if _mood_bubble:
		_mood_bubble.position = Vector2(24, maxf(210, _dog_sprite.global_position.y - global_position.y - 20))
		_mood_bubble.size = Vector2(size.x - 104, 48)


func _layout_corner() -> void:
	if not is_instance_valid(_manual): return
	_manual.position = Vector2(size.x - 76, 212)
	_manual.size = Vector2(52, 52)
	# Cenário e Tiro são irmãos: a ordenação diferida do VBox/CenterContainer
	# não pode mover o sprite depois deste cálculo absoluto, nem ao trocar de aba.
	_dog_sprite.position = _corner.position + _corner.pet_feet() - _dog_sprite.size * Vector2(0.5, 0.81)
	%Stars.position = _corner.scene_rect().position + Vector2(34, 58)
	%Stars.size = Vector2(64, 64)
	%DogArea.queue_redraw()
	_place_bubble()


func _refresh() -> void:
	_refresh_away_look()
	if not is_instance_valid(_care): return
	var dog := GameState.dog
	var now := GameState.now()
	var away := GameState.walking()
	_dog_sprite.visible = not away
	%DogArea.queue_redraw()
	_away_view.visible = away
	_care.refresh()
	if away:
		var walk_id := str(GameState.walk_state.current.id)
		_away_postcard.texture = WalkResult.postcard_texture(GameState.walk_postcard(walk_id))
		_away_name.text = str(GameState.walk_def(walk_id).get("name", ""))
		_away_time.text = TimeText.short(GameState.walk_remaining())
	# O Tiro volta mesmo com a bagagem cheia: guardar os achados é um botão à parte, nunca uma ausência.
	_away_collect.visible = not away and GameState.walk_ready()
	if _away_collect.visible:
		_away_collect.text = "Guardar achados" if GameState.walk_baggage_error() == "" else "Ver bagagem"
	var growth := GameState.growth_info()
	_growth_number.text = str(GameState.growth.phase_index())
	_growth_ring.progress = 1.0 if growth.next.is_empty() else float(growth.requirements.size() - GrowthUi.missing(growth)) / maxi(1, growth.requirements.size())
	_growth_hint.text = "Falta 1!" if GrowthUi.missing(growth) == 1 else ("Pronto!" if growth.ready else "Crescer")
	if growth.ready and (_growth_pulse == null or not _growth_pulse.is_valid()):
		_growth_pulse = Motion.pulse(_growth_ring)
	elif not growth.ready and _growth_pulse != null:
		if _growth_pulse.is_valid(): _growth_pulse.kill()
		_growth_pulse = null
		_growth_ring.scale = Vector2.ONE
	_bond_caption.text = str(GameState.bond_level())
	var bond := GameState.progress.bond_info(GameState.dog.affection)
	_bond_ring.progress = 1.0 if bond.max else float(int(bond.affection) - int(bond.floor)) / maxi(1, int(bond.next) - int(bond.floor))
	_bond_chip.visible = GameState.progress.feature_unlocked("wishes")
	var wish_id := GameState.balloon_wish()
	_wish_bubble.visible = wish_id != "" and not dog.sleeping and not away
	_wish_icon.texture = WishUi.icon(wish_id) if wish_id != "" else null
	_new_badge.visible = PetNotebook.has_new()
	for id: String in _bars:
		var ring: RingProgress = _bars[id]
		var value := dog.get_need(id, now)
		ring.progress = value / 100.0
		ring.color = Palette.PRIMARY if value > 50.0 else (Palette.ACCENT if value >= MOOD_LOW else Palette.DANGER)
		if value < MOOD_LOW and not _pulses.has(id):
			ring.pivot_offset = ring.size / 2.0
			_pulses[id] = Motion.pulse(ring)
		elif value >= MOOD_LOW and _pulses.has(id):
			var pulse: Tween = _pulses[id]
			if pulse and pulse.is_valid(): pulse.kill()
			_pulses.erase(id)
			ring.scale = Vector2.ONE
	_animator.set_sleeping(dog.sleeping)
	_animator.set_sad(dog.get_need(dog.lowest_need(now), now) < MOOD_LOW)
	var text := GameState.away_text() if away else ("Zzz... %s está dormindo" % dog.name if dog.sleeping else str(MOOD_TEXTS.get(dog.lowest_need(now), "")) if dog.get_need(dog.lowest_need(now), now) < MOOD_LOW else "%s está feliz da vida!" % dog.name)
	if not away and not dog.sleeping and Time.get_ticks_msec() / 1000.0 < _pet_message_until:
		text = _pet_message
	if text != _mood_label.text:
		_mood_label.text = text
		_show_mood()
	_update_light()


func _show_mood() -> void:
	_mood_age = 0.0
	_mood_bubble.show()
	Motion.pop_in(_mood_bubble)


func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_mood_age += delta
	_wish_age += delta
	_sleep_age += delta
	if _mood_age > 20.0: _show_mood()
	elif _mood_age > 4.0: _mood_bubble.hide()
	if _wish_age >= 3.0:
		_wish_age = 0.0
		if _wish_bubble.visible: Motion.bounce(_wish_bubble)
	if GameState.dog.sleeping and _sleep_age > 2.0:
		_sleep_age = 0.0
		Motion.float_text(self, head_rect().get_center() - global_position, "Zz", Palette.INK_ON_DARK)


func _update_light() -> void:
	var local := Time.get_datetime_dict_from_system()
	var minute := int(local.hour) * 60 + int(local.minute)
	var hour := preview_hour if preview_hour >= 0 else int(local.hour)
	if minute != _minute or %Corner.get_meta("hour", -1) != hour:
		_minute = minute
		%Corner.set_meta("hour", hour)
		%Corner.modulate = Palette.PET_SUNSET if hour >= 17 and hour < 19 else (Palette.PET_NIGHT if hour >= 19 or hour < 6 else Palette.PET_DAY)
		%Stars.visible = hour >= 19 or hour < 6
	modulate = Palette.PET_SLEEP if GameState.dog.sleeping else Palette.PET_DAY


## A cabeça ocupa cerca de 40% do canvas, descontando a margem transparente acima das orelhas.
func dog_rect() -> Rect2:
	return _dog_sprite.get_global_rect()


func head_rect() -> Rect2:
	var rect := dog_rect()
	return Rect2(rect.position + rect.size * Vector2(0.22, 0.16), rect.size * Vector2(0.56, 0.44))


## As costas: faixa do corpo logo abaixo da cabeça.
func back_rect() -> Rect2:
	var rect := dog_rect()
	return Rect2(rect.position + rect.size * Vector2(0.18, 0.42), rect.size * Vector2(0.64, 0.34))


## Nós no pelo (um por ~200 px de escovada); só aparecem quando a escovada vai render.
func brush_stroke() -> void:
	_animator.scrub()
	if not _knots.is_empty() or GameState.brush_error() != "": return
	var back := back_rect()
	for i in 3:
		var knot := Panel.new()
		knot.name = "BrushKnot"
		knot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.INK_SOFT
		style.border_color = Palette.PAPER
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		knot.add_theme_stylebox_override("panel", style)
		knot.size = Vector2(16, 16)
		add_child(knot)
		knot.global_position = back.position + back.size * Vector2(0.2 + 0.3 * i, 0.3 + 0.2 * (i % 2))
		_knots.append(knot)


func brush_knot_off(at: Vector2) -> void:
	if _knots.is_empty(): return
	var knot: Control = _knots.pop_front()
	var tween := create_tween().set_parallel()
	var seconds := 0.0 if Motion.reduced else Motion.FLOAT
	tween.tween_property(knot, "global_position:y", at.y - 40, seconds)
	tween.tween_property(knot, "modulate:a", 0.0, seconds)
	tween.chain().tween_callback(knot.queue_free)


func brush_cleanup() -> void:
	for knot: Control in _knots:
		knot.queue_free()
	_knots.clear()


func _on_taste(_item: String, reaction: String) -> void:
	if not is_visible_in_tree(): return
	var texts := {"loved": "Amou!", "liked": "Gostou!", "odd": "Hmm...", "grimace": "Eca!"}
	Motion.float_text(self, head_rect().get_center() - global_position - Vector2(24, 40), str(texts.get(reaction, "")), Palette.ACCENT)
	if reaction == "loved":
		for i in 3:
			var heart := UiKit.icon(UiKit.ui_icon("bond_heart"), 16)
			heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
			heart.z_as_relative = false
			heart.z_index = Motion.WORLD_FX_Z
			add_child(heart)
			heart.global_position = head_rect().get_center() + Vector2((i - 1) * 24, -30)
			var tween := heart.create_tween().set_parallel()
			var seconds := 0.0 if Motion.reduced else Motion.FLOAT
			tween.tween_property(heart, "position:y", heart.position.y - 48, seconds)
			tween.tween_property(heart, "modulate:a", 0.0, seconds)
			tween.chain().tween_callback(heart.queue_free)


func food_effects(id: String) -> void:
	var row := UiKit.hbox(4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for chip in UiKit.effect_chip_list(Database.items[id].feed): row.add_child(chip)
	add_child(row)
	row.global_position = head_rect().get_center() - Vector2(36, 0)
	var tween := create_tween().set_parallel()
	var seconds := 0.0 if Motion.reduced else Motion.FLOAT
	tween.tween_property(row, "position:y", row.position.y - 60, seconds)
	tween.tween_property(row, "modulate:a", 0.0, seconds)
	tween.chain().tween_callback(row.queue_free)


func care_bubbles(at: Vector2) -> void:
	for i in 4:
		var bubble := Panel.new()
		bubble.name = "SoapBubble"
		bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.PAPER
		style.border_color = Palette.INFO
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		bubble.add_theme_stylebox_override("panel", style)
		bubble.size = Vector2.ONE * (10 + i * 3)
		add_child(bubble)
		bubble.global_position = at + Vector2((i - 2) * 18, i * 4)
		var tween := create_tween().set_parallel()
		var seconds := 0.0 if Motion.reduced else Motion.FLOAT
		tween.tween_property(bubble, "position:y", bubble.position.y - 80, seconds)
		tween.tween_property(bubble, "modulate:a", 0.0, seconds)
		tween.chain().tween_callback(bubble.queue_free)


func throw_ball() -> void:
	var ball := UiKit.icon(UiKit.ui_icon("action_play"), 48)
	ball.name = "ThrownBall"
	add_child(ball)
	var origin := _care.item_center("ball") - global_position
	var target := dog_rect().get_center() - global_position
	ball.position = origin
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		ball.position = origin.lerp(target, t) + Vector2(0, -140.0 * sin(PI * t)), 0.0, 1.0, 0.0 if Motion.reduced else Motion.SLIDE)
	tween.tween_callback(ball.queue_free)


func _draw_dog_shadow() -> void:
	if GameState.walking(): return
	var area: Control = %DogArea
	var feet := _dog_sprite.global_position - area.global_position + Vector2(_dog_sprite.size.x / 2.0, _dog_sprite.size.y * 0.81)
	area.draw_set_transform(feet, 0.0, Vector2(1.0, 0.25))
	area.draw_circle(Vector2.ZERO, _dog_sprite.size.x * 0.26, Palette.SHADE, true, -1.0, false)
	area.draw_set_transform(Vector2.ZERO)


## Durante o passeio: no lugar do Tiro grande, o postal com o Tiro do mapa andando (2x), nome e tempo.
func _build_away_view() -> void:
	_away_view = UiKit.vbox(6)
	_away_view.name = "AwayView"
	_away_view.visible = false
	_away_view.alignment = BoxContainer.ALIGNMENT_CENTER
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(256, 160)
	stage.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_away_postcard = TextureRect.new()
	_away_postcard.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_away_postcard.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_away_postcard.stretch_mode = TextureRect.STRETCH_SCALE
	_away_postcard.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_away_postcard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_away_postcard)
	var walker := AnimatedSprite2D.new()
	_away_walker = walker
	walker.name = "AwayTiro"
	walker.scale = Vector2(2, 2)
	walker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	walker.position = Vector2(-40, 92)
	stage.add_child(walker)
	_refresh_away_look()
	var stroll := walker.create_tween().set_loops()
	stroll.tween_property(walker, "position:x", 296.0, 5.0).from(-40.0)
	_away_view.add_child(stage)
	var caption := PanelContainer.new()
	caption.theme_type_variation = &"ChipPanel"
	caption.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var caption_box := UiKit.vbox(2)
	caption.add_child(caption_box)
	_away_name = UiKit.short_label("", &"SectionLabel")
	_away_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_box.add_child(_away_name)
	_away_time = UiKit.short_label("", &"SmallLabel")
	_away_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_box.add_child(_away_time)
	_away_view.add_child(caption)
	%DogArea.add_child(_away_view)


func _refresh_away_look() -> void:
	if _away_walker == null: return
	var look := GameState.dog_look()
	if _away_body != look.body:
		_away_body = look.body
		var frames := SpriteFrames.new()
		frames.add_animation("walk")
		frames.set_animation_speed("walk", 8.0)
		var index := 0
		while ResourceLoader.exists("%swalk/east/frame_%02d.png" % [look.dir_world, index]):
			frames.add_frame("walk", load("%swalk/east/frame_%02d.png" % [look.dir_world, index]))
			index += 1
		_away_walker.sprite_frames = frames
		_away_walker.play("walk")
	DogLook.tint(_away_walker)


## Botão da bagagem do passeio, sobre o cantinho (fora do AwayView): "Guardar achados" quando cabe,
## "Ver bagagem" (leva ao portão da Praça, com o motivo e o caminho do depósito) quando não cabe.
func _build_baggage_button() -> void:
	_away_collect = UiKit.primary("Guardar achados", func() -> void:
		if GameState.walk_baggage_error() == "":
			GameState.claim_walk_baggage()
		else:
			var at := Database.place_with_panel("walks")
			Events.world_requested.emit(str(at[0]), str(at[1])))
	_away_collect.name = "CollectWalk"
	_away_collect.custom_minimum_size = Vector2(190, 52)
	_away_collect.size = Vector2(190, 52)
	_away_collect.visible = false
	add_child(_away_collect)


## Toque ou arrastar o dedo no Tiro = carinho. A zona (cabeça, barriga, patas) vem de onde o dedo está.
func _on_dog_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	var button := event as InputEventMouseButton
	var pressing := button != null and button.pressed and button.button_index == MOUSE_BUTTON_LEFT
	var dragging := motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if not pressing and not dragging:
		return
	if GameState.walking() or _care.get("_pressed") != "":
		return
	if GameState.dog.sleeping:
		if pressing:
			if GameState.growth.pending_reveal != "":
				GameState.set_sleeping(false)
			else:
				Events.toast_requested.emit("Shh... ele está dormindo.")
		return
	var local := (button.position if pressing else motion.position) as Vector2
	var seconds := 0.5  # um toque conta como meio segundo de carinho
	if dragging:
		_stroke_distance += motion.relative.length()
		if _stroke_distance < STROKE_STEP:
			return
		_stroke_distance = 0.0
		seconds = 0.2
	var y := local.y / maxf(_dog_sprite.size.y, 1.0)
	var zone := &"head" if y < 0.5 else (&"belly" if y < 0.76 else &"paw")
	_animator.stroke(zone, seconds)
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_pet_reward >= PET_REWARD_EVERY:
		_last_pet_reward = now
		var before := GameState.pet_growth_info()
		var gained := GameState.pet()
		var after := GameState.pet_growth_info()
		var points := int(after.points) - int(before.points)
		var stored := int(after.reserve) - int(before.reserve)
		if points > 0 or stored > 0 or now - _last_pet_feedback >= 5.0:
			_last_pet_feedback = now
			var message := "Próximo ganho de Coragem em %s." % after.wait
			if points > 0:
				message = "Coragem +%d · %d/%d" % [points, after.points, after.cap]
			if stored > 0:
				message = (message + "\n" if points > 0 else "Coragem %d/%d · " % [after.points, after.cap]) + "+%d guardado para depois de crescer." % stored
			elif points == 0 and int(after.seconds) == 0:
				message = "Coragem no limite da fase; a reserva também está cheia."
			# Fica junto do Tiro e não disputa o aviso superior com "Nova foto!".
			_pet_message = message
			_pet_message_until = now + 4.0
			_mood_label.text = message
			_show_mood()
		if gained > 0:
			_float_text("+carinho", _dog_sprite.get_global_transform() * local)


func _float_text(text: String, at: Vector2) -> void:
	Motion.float_text(self, at - global_position - Vector2(30, 30), text, Palette.ACCENT)
