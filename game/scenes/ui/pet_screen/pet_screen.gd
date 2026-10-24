extends Control
## Cantinho do Tiro: cenário, anéis, cuidados com o dedo e caderninho.

const MOOD_LOW := 25.0
const MOOD_TEXTS := {"hunger": "Estou com fome!", "happiness": "Quero brincar...", "energy": "Que soninho...", "hygiene": "Preciso de um banho!"}
const STROKE_STEP := 28.0
## Zonas do carinho, em frações do quadro do Tiro (como `back_rect`).
const SPOTS := {
	"head": Rect2(0.22, 0.16, 0.56, 0.20),
	"chin": Rect2(0.30, 0.36, 0.40, 0.14),
	"belly": Rect2(0.18, 0.50, 0.64, 0.26),
}

var _bars: Dictionary = {}
var _pulses: Dictionary = {}
var _animator: PetAnimator
var _growth_badge: Button
var _growth_ring: RingProgress
var _growth_number: Label
var _growth_hint: Label
var _growth_pulse: Tween
var _wish_bubble: Button
var _wish_icon: TextureRect
var _wish_pillar: TextureRect
var _wish_badge: Label
var _need_pillars: Dictionary = {}
var _away_view: VBoxContainer
var _away_postcard: TextureRect
var _away_name: Label
var _away_time: Label
var _away_collect: Button
var _away_walker: AnimatedSprite2D
var _away_body := ""
var _stroke_distance := 0.0
var _holding := false
var _hold_time := 0.0
var _hold_done := false
var _hold_rub := 0.0
var _hold_local := Vector2.ZERO
var _hold_ring: RingProgress
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
	need_back.offset_top = 128
	need_back.offset_bottom = 236
	_mood_bubble = SpeechBubble.new()
	_mood_bubble.name = "MoodBubble"
	_mood_label = _mood_bubble.label
	_mood_label.name = "MoodLabel"
	_mood_label.theme_type_variation = &"StrongLabel"
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
	Events.taste_reacted.connect(_on_taste)
	Events.favorite_spot_loved.connect(_on_spot_loved)
	%RefreshTimer.timeout.connect(_refresh)
	resized.connect(_layout_corner)
	_corner.resized.connect(_layout_corner)
	%DogArea.resized.connect(_layout_corner)
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree(): _care.cancel())
	_layout_corner.call_deferred()
	_refresh()


func play_growth_feedback(before: Dictionary, after: Dictionary) -> void:
	var gained := int(after.have) - int(before.have)
	_pet_message = "Momento de Esperteza!" if gained > 0 else str(after.hint)
	_pet_message_until = Time.get_ticks_msec() / 1000.0 + 4.0
	_mood_label.text = _pet_message
	_show_mood()


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
				if GameState.need_asking(id): text += "\n" + str(MOOD_TEXTS.get(id, ""))
				Popover.open(self, ring, UiKit.label(text, &"SmallLabel")))
		var need := UiKit.vbox(2)
		need.add_child(ring)
		# O cuidado que atende a necessidade faz este pilar crescer: o ícone só aparece enquanto ela pede.
		var mark := UiKit.icon(null, 22)
		mark.name = "NeedPillar_" + id
		mark.position = Vector2(44, -6)
		mark.visible = false
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.add_child(mark)
		_need_pillars[id] = mark
		var caption := UiKit.short_label(str(Database.needs[id].name), &"SmallLabel")
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		need.add_child(caption)
		%NeedsGrid.add_child(need)
		_bars[id] = ring
	# O crescimento fica abaixo das necessidades, sem espremer os quatro anéis.
	var badges := UiKit.hbox(12)
	badges.name = "LifeBadges"
	badges.position = Vector2(20, 244)
	add_child(badges)
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
	_wish_bubble = UiKit.icon_button(UiKit.ui_icon("wish_bubble"), _open_wish_card, 64)
	_wish_bubble.name = "WishBubble"
	_wish_bubble.add_theme_constant_override("icon_max_width", 64)
	for style: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		_wish_bubble.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	_wish_icon = UiKit.icon(null, 32)
	_wish_icon.position = Vector2(16, 12)
	_wish_bubble.add_child(_wish_icon)
	_wish_pillar = UiKit.icon(null, 20)
	_wish_pillar.name = "WishPillar"
	_wish_pillar.position = Vector2(40, 0)
	_wish_pillar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wish_bubble.add_child(_wish_pillar)
	_wish_badge = UiKit.alert_badge()
	_wish_badge.name = "WishReadyBadge"
	_wish_badge.position = Vector2(46, 20)
	_wish_bubble.add_child(_wish_badge)
	_wish_badge.reset_size()
	add_child(_wish_bubble)
	_dog_sprite.item_rect_changed.connect(_place_bubble)


## Toque no balão: o pedido em uma linha, com Pegar/Dar ou Ir; fecha sozinho ao atender.
func _open_wish_card() -> void:
	if _care.get("_pointed_item") == "wish": _care.clear_pointer()
	if GameState.balloon_wish() == "": return
	var card := WishUi.balloon_card()
	var popover := Popover.open(self, _wish_bubble, card, 0.0)
	for button_name: String in ["WishTake", "WishGo"]:
		var button := card.find_child(button_name, true, false) as Button
		if button: button.pressed.connect(popover.close, CONNECT_DEFERRED)


func _place_bubble() -> void:
	if _wish_bubble:
		_wish_bubble.position = _dog_sprite.global_position - global_position + Vector2(_dog_sprite.size.x * 0.72, _dog_sprite.size.y * 0.18)
	if _away_collect:
		var area: Control = %DogArea
		_away_collect.position = Vector2((size.x - _away_collect.size.x) * 0.5, area.global_position.y - global_position.y + area.size.y - _away_collect.size.y - 12.0)
	if _mood_bubble:
		_mood_bubble.position = Vector2(24, maxf(250, _dog_sprite.global_position.y - global_position.y - 20))
		_mood_bubble.size = Vector2(size.x - 104, 48)


func _layout_corner() -> void:
	if not is_instance_valid(_manual): return
	_manual.position = Vector2(size.x - 76, 252)
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
	_growth_ring.progress = 1.0 if growth.next.is_empty() else GrowthUi.fraction(growth)
	_growth_hint.text = "Falta 1!" if GrowthUi.missing(growth) == 1 else ("Pronto!" if growth.ready else "Crescer")
	if growth.ready and (_growth_pulse == null or not _growth_pulse.is_valid()):
		_growth_pulse = Motion.pulse(_growth_ring)
	elif not growth.ready and _growth_pulse != null:
		if _growth_pulse.is_valid(): _growth_pulse.kill()
		_growth_pulse = null
		_growth_ring.scale = Vector2.ONE
	var wish_id := GameState.balloon_wish()
	_wish_bubble.visible = wish_id != "" and not dog.sleeping and not away
	_wish_badge.visible = _wish_bubble.visible and GameState.fulfillable_wish_count() > 0
	if not _wish_bubble.visible and _care.get("_pointed_item") == "wish": _care.clear_pointer()
	_wish_icon.texture = WishUi.icon(wish_id) if wish_id != "" else null
	_wish_pillar.texture = WishUi.pillar_icon(GameState.wish_pillar()) if wish_id != "" else null
	_new_badge.visible = PetNotebook.has_new()
	for id: String in _bars:
		var ring: RingProgress = _bars[id]
		var value := dog.get_need(id, now)
		var asking := GameState.need_asking(id)
		ring.progress = value / 100.0
		ring.color = Palette.PRIMARY if not asking else (Palette.ACCENT if value >= MOOD_LOW else Palette.DANGER)
		var mark: TextureRect = _need_pillars[id]
		var pillar := GameState.need_pillar(id)
		mark.visible = asking and pillar != ""
		mark.texture = WishUi.pillar_icon(pillar) if mark.visible else null
		if asking and not _pulses.has(id):
			ring.pivot_offset = ring.size / 2.0
			_pulses[id] = Motion.pulse(ring)
		elif not asking and _pulses.has(id):
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
	hold_tick(delta)
	if GameState.tiro_animated() and not Motion.reduced: %DogArea.queue_redraw()
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
			var heart := UiKit.icon(UiKit.ui_icon("heart"), 16)
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
	if GameState.tiro_animated():
		var glow := Palette.GOLD
		glow.a = 0.12 if Motion.reduced else 0.12 + 0.035 * sin(_mood_age * 2.0)
		for offset in [Vector2(-0.15, -0.65), Vector2(0.85, -0.8), Vector2(1.1, -0.35)]:
			var point: Vector2 = feet + Vector2(offset.x - 0.5, offset.y) * _dog_sprite.size
			area.draw_circle(point, 7.0, glow, true, -1.0, true)
			area.draw_line(point - Vector2(0, 4), point + Vector2(0, 4), Palette.GOLD, 1.0, true)
			area.draw_line(point - Vector2(4, 0), point + Vector2(4, 0), Palette.GOLD, 1.0, true)


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


## Segurar o dedo no Tiro (1,2 s, com anel) ou esfregar sem parar = UM carinho por gesto. Um toque curto só
## faz festa. Onde o dedo está (cabeça, queixo, barriga) decide se é o lugar favorito dele.
func _on_dog_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if not button.pressed:
			hold_end()
			return
		if GameState.walking() or _care.get("_pressed") != "":
			return
		if GameState.dog.sleeping:
			if GameState.growth.pending_reveal != "":
				GameState.set_sleeping(false)
			else:
				Events.toast_requested.emit("Shh... ele está dormindo.")
			return
		hold_begin(button.position)
	elif motion != null and _holding and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		hold_move(motion.position, motion.relative.length())


func hold_begin(local: Vector2) -> void:
	_holding = true
	_hold_time = 0.0
	_hold_done = false
	_hold_rub = 0.0
	_stroke_distance = 0.0
	_hold_local = local
	_animator.stroke(&"head" if local.y / maxf(_dog_sprite.size.y, 1.0) < 0.5 else &"belly", 0.5)
	if _hold_ring == null:
		_hold_ring = RingProgress.new()
		_hold_ring.name = "HoldRing"
		_hold_ring.custom_minimum_size = Vector2(40, 40)
		_hold_ring.size = Vector2(40, 40)
		_hold_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_hold_ring.z_as_relative = false
		_hold_ring.z_index = Motion.WORLD_FX_Z
		add_child(_hold_ring)
	_hold_ring.progress = 0.0
	_hold_ring.show()
	_place_hold_ring()


func hold_move(local: Vector2, length: float) -> void:
	if not _holding: return
	_hold_local = local
	_hold_rub += length
	_stroke_distance += length
	if _stroke_distance >= STROKE_STEP:
		_stroke_distance = 0.0
		var y := local.y / maxf(_dog_sprite.size.y, 1.0)
		_animator.stroke(&"head" if y < 0.5 else (&"belly" if y < 0.76 else &"paw"), 0.2)
	_place_hold_ring()
	if not _hold_done and _hold_rub >= float(Database.growth.gestures.rub_distance):
		_hold_reward()


func hold_tick(delta: float) -> void:
	if not _holding or _hold_done: return
	if GameState.dog.sleeping or GameState.walking():
		hold_end()
		return
	_hold_time += delta
	var seconds := float(Database.growth.gestures.hold_seconds)
	_hold_ring.progress = minf(_hold_time / seconds, 1.0)
	if _hold_time >= seconds:
		_hold_reward()


func hold_end() -> void:
	_holding = false
	_hold_done = false
	if _hold_ring != null: _hold_ring.hide()


func _hold_reward() -> void:
	_hold_done = true
	_hold_ring.progress = 1.0
	var spot := spot_at(_hold_local)
	var before := GameState.pet_growth_info()
	var gained := GameState.pet(spot)
	var after := GameState.pet_growth_info()
	var earned := int(after.have) - int(before.have)
	var now := Time.get_ticks_msec() / 1000.0
	if earned > 0 or now - _last_pet_feedback >= 5.0:
		_last_pet_feedback = now
		_pet_message = "Momento de Coragem!" if earned > 0 else str(after.hint)
		_pet_message_until = now + 4.0
		_mood_label.text = _pet_message
		_show_mood()
	if gained > 0:
		_float_text("+carinho", _dog_sprite.global_position + _hold_local)


func _place_hold_ring() -> void:
	if _hold_ring != null:
		_hold_ring.position = _dog_sprite.global_position - global_position + _hold_local - Vector2(20, 76)


func spot_rect(spot: String) -> Rect2:
	var rect := dog_rect()
	var part: Rect2 = SPOTS[spot]
	return Rect2(rect.position + rect.size * part.position, rect.size * part.size)


## Zona sob o ponto (local ao sprite do Tiro); "" fora das três (patas, orelhas).
func spot_at(local: Vector2) -> String:
	var global_point := dog_rect().position + local
	for spot: String in SPOTS:
		if spot_rect(spot).has_point(global_point): return spot
	return ""


## O Tiro rola de barriga para cima e solta corações no lugar favorito.
func _on_spot_loved(_zone: String, _first: bool) -> void:
	if not is_visible_in_tree(): return
	_animator.love()
	_on_taste("", "loved")


func _float_text(text: String, at: Vector2) -> void:
	Motion.float_text(self, at - global_position - Vector2(30, 30), text, Palette.ACCENT)
