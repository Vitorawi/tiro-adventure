class_name Hud
extends Control
## HUD flutuante sobre as telas (nó `TopBar` da casca): à esquerda o rostinho do Tiro com o anel de crescimento e o
## número da fase; à direita a pílula de moedas, a engrenagem e, na versão dev, o selo DEV.
## Só as peças recebem toque (o resto é `MOUSE_FILTER_IGNORE`). Quem manda atualizar é a casca (`refresh`).

const HEIGHT := 60.0
const AVATAR := 52.0
const RING := 60.0
const BADGE := 22.0

var level_label: Label
var xp_bar: ProgressBar
var coins_label: Label
var coins_pill: Control
var dev_button: Button
var settings_button: Button
var avatar_button: Button

var _avatar_group: Control
var _ring: RingProgress
var _shown_level: int = -1
var _coins_target: int = -1  # valor para onde o número está contando (-1 = ainda não mostrou)
var _count_tween: Tween
var _ring_tween: Tween
var _growth_alert: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = HEIGHT
	_build_avatar()
	_build_right()
	_growth_alert = UiKit.button("! Pode\nCrescer!", func() -> void: GrowthUi.open())
	_growth_alert.name = "GrowthReadyAlert"
	_growth_alert.position = Vector2(72, 4)
	_growth_alert.custom_minimum_size = Vector2(100, 48)
	_growth_alert.add_theme_font_size_override("font_size", 20)
	for kind: String in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Palette.BAD
		style.set_corner_radius_all(12)
		style.content_margin_left = 8
		style.content_margin_right = 8
		_growth_alert.add_theme_stylebox_override(kind, style)
		_growth_alert.add_theme_color_override("font_" + (kind + "_" if kind != "normal" else "") + "color", Color.WHITE)
	_growth_alert.hide()
	add_child(_growth_alert)


func _build_avatar() -> void:
	_avatar_group = Control.new()
	_avatar_group.name = "AvatarGroup"
	_avatar_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_group.position = Vector2(6.0, 0.0)
	_avatar_group.size = Vector2(RING, RING)
	add_child(_avatar_group)
	# Anel de XP em volta do avatar (cheio = ouro; trilho escuro para aparecer sobre o mundo).
	_ring = RingProgress.new()
	_ring.name = "XpRing"
	_ring.custom_minimum_size = Vector2(RING, RING)
	_ring.size = Vector2(RING, RING)
	_ring.thickness = 4.0
	_ring.color = Palette.GOLD
	_ring.done_color = Palette.GOLD
	_ring.track = Palette.HUD
	_avatar_group.add_child(_ring)
	avatar_button = Button.new()
	avatar_button.name = "HudAvatar"
	DogLook.bind(avatar_button, "portrait", "icon")
	avatar_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_button.focus_mode = Control.FOCUS_NONE
	avatar_button.custom_minimum_size = Vector2(AVATAR, AVATAR)
	avatar_button.size = Vector2(AVATAR, AVATAR)
	avatar_button.position = Vector2((RING - AVATAR) / 2.0, (RING - AVATAR) / 2.0)
	# Todos os estados com margem zero (o tamanho mínimo do Button vem do maior deles).
	for style_name: String in ["normal", "hover", "disabled"]:
		avatar_button.add_theme_stylebox_override(style_name, _circle_style(Palette.PAPER))
	for style_name: String in ["pressed", "hover_pressed"]:
		avatar_button.add_theme_stylebox_override(style_name, _circle_style(Palette.CARD))
	avatar_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	avatar_button.pressed.connect(show_level_popover)
	Motion.press(avatar_button)
	_avatar_group.add_child(avatar_button)
	# Selo da fase no canto de baixo à direita do avatar.
	var badge := Panel.new()
	badge.name = "LevelBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size = Vector2(BADGE, BADGE)
	badge.position = Vector2(RING - BADGE + 2.0, RING - BADGE + 2.0)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Palette.GOLD
	badge_style.set_corner_radius_all(int(BADGE / 2.0))
	badge_style.set_border_width_all(2)
	badge_style.border_color = Palette.INK
	badge.add_theme_stylebox_override("panel", badge_style)
	_avatar_group.add_child(badge)
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.theme_type_variation = &"NumberLabel"
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Palette.INK)
	level_label.add_theme_constant_override("outline_size", 0)
	level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.add_child(level_label)
	# Mantida só por compatibilidade (testes e ferramentas leem); o anel mostra o progresso.
	xp_bar = ProgressBar.new()
	xp_bar.name = "XpBar"
	xp_bar.visible = false
	xp_bar.show_percentage = false
	add_child(xp_bar)


func _circle_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(AVATAR / 2.0))
	style.set_border_width_all(3)
	style.border_color = Palette.INK
	style.set_content_margin_all(0.0)  # sem margem interna: o botão fica redondo, com 52 px
	return style


func _build_right() -> void:
	var right := HBoxContainer.new()
	right.name = "Right"
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 6)
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -8.0
	right.offset_right = -8.0
	right.offset_top = 6.0
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(right)
	var column := VBoxContainer.new()
	column.name = "CoinsColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	right.add_child(column)
	# A pílula mora num Control simples para o pulinho (`Motion.bounce`) não brigar com o container.
	var pill := UiKit.pill(UiKit.ui_icon("coin"), "0")
	pill.name = "CoinsPill"
	pill.custom_minimum_size = Vector2(0, 40)
	coins_pill = pill
	coins_label = pill.find_child("Value", true, false) as Label
	coins_label.name = "CoinsLabel"
	var holder := Control.new()
	holder.name = "CoinsHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_SHRINK_END
	holder.custom_minimum_size = Vector2(0, 40)
	holder.add_child(pill)
	pill.resized.connect(func() -> void: holder.custom_minimum_size = pill.size)
	column.add_child(holder)
	dev_button = Button.new()
	dev_button.name = "DevButton"
	dev_button.text = "DEV"
	dev_button.visible = false
	dev_button.focus_mode = Control.FOCUS_NONE
	dev_button.custom_minimum_size = Vector2(48, 24)
	dev_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	dev_button.add_theme_font_size_override("font_size", 18)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		dev_button.add_theme_color_override(color_name, Palette.INK_ON_DARK)
	var dev_style := StyleBoxFlat.new()
	dev_style.bg_color = Palette.DANGER
	dev_style.set_corner_radius_all(12)
	dev_style.content_margin_left = 10.0
	dev_style.content_margin_right = 10.0
	dev_style.content_margin_top = 0.0
	dev_style.content_margin_bottom = 0.0
	for style_name: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		dev_button.add_theme_stylebox_override(style_name, dev_style)
	Motion.press(dev_button)
	column.add_child(dev_button)
	settings_button = UiKit.icon_button(UiKit.ui_icon("settings"), SettingsPanel.open, 44)
	settings_button.name = "SettingsButton"
	settings_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	right.add_child(settings_button)


## Atualiza fase, anel de crescimento e moedas. `animate` falso = só põe os valores (primeira vez).
func refresh(animate: bool = true) -> void:
	var info := GameState.growth_info()
	var total: int = info.requirements.size()
	var missing := GrowthUi.missing(info)
	var fraction := float(total - missing) / float(total) if total > 0 else 1.0
	xp_bar.max_value = 1.0
	xp_bar.value = fraction
	var phase := GameState.growth.phase_index()
	level_label.text = str(phase) if phase > 0 else "•"
	_set_ring(fraction, animate and _shown_level >= 0)
	_shown_level = phase
	_growth_alert.visible = bool(info.ready)
	_set_coins(GameState.coins, animate)


func _set_ring(fraction: float, animate: bool) -> void:
	if _ring_tween:
		_ring_tween.kill()
	if not animate or Motion.reduced or is_equal_approx(_ring.progress, fraction):
		_ring.progress = fraction
		return
	_ring_tween = create_tween()
	_ring_tween.tween_property(_ring, "progress", fraction, Motion.RESIZE)


func _set_coins(value: int, animate: bool) -> void:
	if value == _coins_target:
		return
	var first := _coins_target < 0
	_coins_target = value
	var shown := int(coins_label.text) if coins_label.text.is_valid_int() else value
	if _count_tween:
		_count_tween.kill()
	if first or not animate:
		coins_label.text = str(value)
		return
	_count_tween = Motion.count_up(coins_label, shown, value)
	if value > shown:
		Motion.bounce(coins_pill)


## Centro da pílula de moedas na tela: as moedas do `CollectFx` voam até aqui.
func coins_target() -> Vector2:
	return coins_label.get_global_rect().get_center()


## Consulta da fase; nome antigo mantido para ferramentas e testes existentes.
func show_level_popover() -> Popover:
	var info := GameState.growth_info()
	var card := UiKit.vbox(8)
	card.name = "GrowthQuickSummary"
	card.custom_minimum_size.x = 248
	card.add_child(UiKit.label(str(info.current.name), &"SmallLabel"))
	card.add_child(UiKit.label("Guardião do Vale" if info.next.is_empty() else "Rumo a " + str(info.next.name), &"SectionLabel"))
	if info.ready:
		card.add_child(UiKit.label("Tudo pronto para crescer!", &"SmallLabel", Palette.GOOD))
	elif not info.next.is_empty():
		card.add_child(UiKit.label("Ainda falta", &"SmallLabel"))
		var grid := GridContainer.new()
		grid.name = "GrowthQuickGrid"
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for step: Dictionary in GrowthUi.compact_steps(info):
			var tile := UiKit.hbox(4)
			tile.name = "GrowthQuick_" + str(step.id)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var ring := RingProgress.new()
			ring.custom_minimum_size = Vector2(36, 36)
			ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			ring.texture = step.icon
			ring.progress = float(step.have) / maxf(1.0, float(step.need))
			tile.add_child(ring)
			var label := UiKit.vbox(0)
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.add_child(UiKit.label(str(step.title), &"SmallLabel"))
			label.add_child(UiKit.label("%d/%d" % [step.have, step.need], &"SmallLabel"))
			tile.add_child(label)
			grid.add_child(tile)
		card.add_child(grid)
	else:
		card.add_child(UiKit.label("Ele cresceu com você!", &"SmallLabel"))
	var view := UiKit.secondary("Ver detalhes", func() -> void:
		var catcher := get_parent().get_node_or_null("PopoverCatcher")
		if catcher: catcher.queue_free()
		GrowthUi.open(), null, true)
	view.name = "ViewGrowth"
	card.add_child(view)
	return Popover.open(get_parent() as Control, avatar_button, card, 0.0)
