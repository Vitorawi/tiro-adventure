class_name Hud
extends Control
## HUD flutuante sobre as telas (nó `TopBar` da casca), em duas linhas (Interface 2, etapa 03).
## Linha 1: avatar do Tiro com o anel mel de crescimento + `HudProfile` ("Tiro 3/5") · moedas · engrenagem
## (e o selo DEV). Linha 2 (`HudRow2`): o `NextStep` à esquerda; a direita fica para a tela (anéis, "Pegar tudo").
## Só as peças recebem toque (o resto é `MOUSE_FILTER_IGNORE`). Quem manda atualizar é a casca (`refresh`).

const HEIGHT := 128.0
const AVATAR := 58.0
const ROW1_TOP := 10.0
const ROW2_TOP := 76.0
const ROW2_HEIGHT := 52.0
const SIDE := 12.0
const PROFILE_SIZE := Vector2(116.0, 44.0)
const PROFILE_MIN := 80.0

var level_label: Label
var xp_bar: ProgressBar
var coins_label: Label
var coins_pill: Control
var dev_button: Button
var settings_button: Button
var avatar_button: Button
var next_step: NextStep
var row2: HBoxContainer

var _avatar_group: Control
var _ring: RingProgress
var _shown_level: int = -1
var _coins_target: int = -1  # valor para onde o número está contando (-1 = ainda não mostrou)
var _coins_shown: int = 0
var _count_tween: Tween
var _ring_tween: Tween
var _growth_alert: Button
var _animated_badge: Control
var _ask_icon: TextureRect
var _profile: Button
var _profile_box: Control
var _profile_bar: ProgressBar
var _profile_count: Label
var _row2_inset: Control
var _row2_left: Control
var _row2_right: Control
var _row2_shown := true
var _row2_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	offset_bottom = HEIGHT
	_build_avatar()
	_build_profile()
	_build_right()
	_build_row2()
	_growth_alert = UiKit.button("! Pode\nCrescer!", func() -> void: GrowthUi.open(), &"ChipButton")
	_growth_alert.name = "GrowthReadyAlert"
	_growth_alert.position = Vector2(SIDE + AVATAR + 8.0, ROW1_TOP + (AVATAR - PROFILE_SIZE.y) / 2.0)
	_growth_alert.custom_minimum_size = Vector2(100, PROFILE_SIZE.y)
	for kind: String in ["normal", "hover", "pressed"]:
		var style := UiKit.surface(Palette.ALERT, 16)
		style.content_margin_left = 8
		style.content_margin_right = 8
		_growth_alert.add_theme_stylebox_override(kind, style)
		_growth_alert.add_theme_color_override("font_" + (kind + "_" if kind != "normal" else "") + "color", Palette.CARD)
	_growth_alert.hide()
	add_child(_growth_alert)


func _build_avatar() -> void:
	_avatar_group = Control.new()
	_avatar_group.name = "AvatarGroup"
	_avatar_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_group.position = Vector2(SIDE, ROW1_TOP)
	_avatar_group.size = Vector2(AVATAR, AVATAR)
	add_child(_avatar_group)
	avatar_button = Button.new()
	avatar_button.name = "HudAvatar"
	DogLook.bind(avatar_button, "portrait", "icon")
	avatar_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_button.expand_icon = true
	avatar_button.add_theme_constant_override("icon_max_width", 40)
	avatar_button.focus_mode = Control.FOCUS_NONE
	avatar_button.custom_minimum_size = Vector2(AVATAR, AVATAR)
	avatar_button.size = Vector2(AVATAR, AVATAR)
	# Todos os estados com a mesma margem (o tamanho mínimo do Button vem do maior deles).
	for style_name: String in ["normal", "hover", "disabled"]:
		avatar_button.add_theme_stylebox_override(style_name, _circle_style(Palette.CARD))
	for style_name: String in ["pressed", "hover_pressed"]:
		avatar_button.add_theme_stylebox_override(style_name, _circle_style(Palette.SUNKEN))
	avatar_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	avatar_button.pressed.connect(show_level_popover)
	Motion.press(avatar_button)
	_avatar_group.add_child(avatar_button)
	# Anel de crescimento (mel) por cima do disco, na borda; só desenha.
	_ring = RingProgress.new()
	_ring.name = "XpRing"
	_ring.custom_minimum_size = Vector2(AVATAR, AVATAR)
	_ring.size = Vector2(AVATAR, AVATAR)
	_ring.thickness = 5.0
	_ring.color = Palette.HONEY
	_ring.done_color = Palette.HONEY
	_ring.track = Palette.SUNKEN
	_avatar_group.add_child(_ring)
	# Número da fase: continua existindo (testes e ferramentas leem), mas o perfil já mostra o progresso.
	var badge := Panel.new()
	badge.name = "LevelBadge"
	badge.visible = false
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.size = Vector2(22, 22)
	_avatar_group.add_child(badge)
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.theme_type_variation = &"NumberLabel"
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.add_child(level_label)
	# Selo do que ele pede agora: o desejo do balão ou, sem desejo, a necessidade que está pedindo.
	_ask_icon = UiKit.icon(null, 22)
	_ask_icon.name = "AvatarAsk"
	_ask_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ask_icon.position = Vector2(AVATAR - 18.0, -4.0)
	_ask_icon.visible = false
	_avatar_group.add_child(_ask_icon)
	_animated_badge = UiKit.spark(18)
	_animated_badge.name = "AnimatedBadge"
	_animated_badge.position = Vector2(AVATAR - 18.0, AVATAR - 18.0)
	_animated_badge.size = Vector2(18, 18)
	_animated_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_group.add_child(_animated_badge)
	# Mantida só por compatibilidade (testes e ferramentas leem); o anel mostra o progresso.
	xp_bar = ProgressBar.new()
	xp_bar.name = "XpBar"
	xp_bar.visible = false
	xp_bar.show_percentage = false
	add_child(xp_bar)


func _circle_style(color: Color) -> StyleBoxFlat:
	var style := UiKit.surface(color, int(AVATAR / 2.0), true)
	style.set_content_margin_all(0.0)  # sem margem interna: o botão fica redondo, com 58 px
	return style


## Pílula "Tiro 3/5": nome, barrinha mel e quantos requisitos da fase já estão feitos. Tocar = tocar no avatar.
func _build_profile() -> void:
	_profile = Button.new()
	_profile.name = "HudProfile"
	_profile.focus_mode = Control.FOCUS_NONE
	_profile.custom_minimum_size = Vector2(PROFILE_MIN, PROFILE_SIZE.y)
	_profile.size = PROFILE_SIZE
	_profile.position = Vector2(SIDE + AVATAR + 8.0, ROW1_TOP + (AVATAR - PROFILE_SIZE.y) / 2.0)
	for style_name: String in ["normal", "hover", "disabled", "focus"]:
		_profile.add_theme_stylebox_override(style_name, UiKit.surface(Palette.CARD, 22, true))
	for style_name: String in ["pressed", "hover_pressed"]:
		_profile.add_theme_stylebox_override(style_name, UiKit.surface(Palette.SUNKEN, 22, true))
	_profile.pressed.connect(show_level_popover)
	Motion.press(_profile)
	var box := UiKit.vbox(2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.position = Vector2(14.0, 4.0)
	box.size = PROFILE_SIZE - Vector2(28.0, 8.0)
	var name_label := UiKit.short_label("Tiro", &"StrongLabel")
	name_label.name = "ProfileName"
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(name_label)
	var line := UiKit.hbox(6)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_profile_bar = UiKit.bar(0.0, Palette.HONEY, 6)
	_profile_bar.name = "ProfileBar"
	_profile_bar.max_value = 1.0
	_profile_bar.custom_minimum_size = Vector2(20, 6)
	_profile_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(_profile_bar)
	_profile_count = UiKit.short_label("", &"SmallLabel", Palette.INK_SOFT)
	_profile_count.name = "ProfileCount"
	line.add_child(_profile_count)
	box.add_child(line)
	_profile_box = box
	_profile.add_child(box)
	add_child(_profile)


## O perfil encolhe (nome com reticências) até encostar nas moedas, que crescem para a esquerda com Texto maior;
## nunca se sobrepõem. Largura entre `PROFILE_MIN` e `PROFILE_SIZE.x`.
func _fit_profile() -> void:
	var right := get_node_or_null("Right") as Control
	if right == null or _profile == null:
		return
	var width := clampf(right.position.x - 6.0 - _profile.position.x, PROFILE_MIN, PROFILE_SIZE.x)
	_profile.size.x = width
	_profile.custom_minimum_size.x = 0.0
	_profile_box.size.x = width - 28.0


func _build_right() -> void:
	var right := HBoxContainer.new()
	right.name = "Right"
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.alignment = BoxContainer.ALIGNMENT_END
	right.add_theme_constant_override("separation", 8)
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.offset_left = -SIDE
	right.offset_right = -SIDE
	right.offset_top = ROW1_TOP + (AVATAR - 44.0) / 2.0
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	add_child(right)
	right.resized.connect(_fit_profile)
	var column := VBoxContainer.new()
	column.name = "CoinsColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
	right.add_child(column)
	# Pílula branca com a moeda pixel 28 e o número. Mora num Control simples para o pulinho não brigar com o container.
	var pill := PanelContainer.new()
	pill.name = "CoinsPill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pill_style := UiKit.surface(Palette.CARD, 20, true)
	pill_style.content_margin_left = 10.0
	pill_style.content_margin_right = 14.0
	pill_style.content_margin_top = 4.0
	pill_style.content_margin_bottom = 4.0
	pill.add_theme_stylebox_override("panel", pill_style)
	pill.custom_minimum_size = Vector2(0, 40)
	var pill_row := UiKit.hbox(4)
	pill_row.add_child(UiKit.icon(UiKit.ui_icon("coin"), 28))
	coins_label = UiKit.label("0", &"NumberLabel")
	coins_label.name = "CoinsLabel"
	coins_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	pill_row.add_child(coins_label)
	pill.add_child(pill_row)
	coins_pill = pill
	var holder := Control.new()
	holder.name = "CoinsHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_SHRINK_END
	holder.custom_minimum_size = Vector2(0, 44)
	holder.add_child(pill)
	pill.position.y = 2.0
	pill.resized.connect(func() -> void: holder.custom_minimum_size = Vector2(pill.size.x, 44))
	column.add_child(holder)
	# Engrenagem (disco 40, alvo 44) com o selo DEV encostado embaixo.
	var gear_column := VBoxContainer.new()
	gear_column.name = "SettingsColumn"
	gear_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gear_column.add_theme_constant_override("separation", -10)
	right.add_child(gear_column)
	settings_button = UiKit.ctl_button("gear", SettingsPanel.open, 40)
	settings_button.name = "SettingsButton"
	settings_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	gear_column.add_child(settings_button)
	dev_button = Button.new()
	dev_button.name = "DevButton"
	dev_button.text = "DEV"
	dev_button.theme_type_variation = &"ChipButton"
	dev_button.visible = false
	dev_button.focus_mode = Control.FOCUS_NONE
	dev_button.custom_minimum_size = Vector2(40, 20)
	dev_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		dev_button.add_theme_color_override(color_name, Palette.CARD)
	var dev_style := UiKit.surface(Palette.ALERT, 10)
	dev_style.content_margin_left = 8.0
	dev_style.content_margin_right = 8.0
	dev_style.content_margin_top = 0.0
	dev_style.content_margin_bottom = 0.0
	for style_name: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		dev_button.add_theme_stylebox_override(style_name, dev_style)
	Motion.press(dev_button)
	gear_column.add_child(dev_button)


## Segunda linha: [recuo do Mapa] [próximo passo] ····· [conteúdo da tela, à direita].
func _build_row2() -> void:
	row2 = HBoxContainer.new()
	row2.name = "HudRow2"
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row2.add_theme_constant_override("separation", 0)
	row2.anchor_right = 1.0
	row2.offset_left = SIDE
	row2.offset_right = -SIDE
	row2.offset_top = ROW2_TOP
	row2.offset_bottom = ROW2_TOP + ROW2_HEIGHT
	add_child(row2)
	_row2_inset = Control.new()
	_row2_inset.name = "Row2Inset"
	_row2_inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row2.add_child(_row2_inset)
	_row2_left = Control.new()
	_row2_left.name = "Row2Left"
	_row2_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row2_left.custom_minimum_size = Vector2(0, ROW2_HEIGHT)
	row2.add_child(_row2_left)
	var spacer := Control.new()
	spacer.name = "Row2Spacer"
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(spacer)
	_row2_right = Control.new()
	_row2_right.name = "Row2Right"
	_row2_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row2_right.custom_minimum_size = Vector2(0, ROW2_HEIGHT)
	row2.add_child(_row2_right)
	next_step = NextStep.new()
	next_step.position = Vector2(0.0, (ROW2_HEIGHT - NextStep.HEIGHT) / 2.0)
	_row2_left.add_child(next_step)
	next_step.resized.connect(func() -> void:
		_row2_left.custom_minimum_size = Vector2(next_step.size.x, ROW2_HEIGHT))


## Troca o que vive à direita da linha 2 (a tela do Tiro põe os anéis, as Missões o "Pegar tudo"). `null` esvazia.
func set_row2_right(control: Control) -> void:
	for child: Node in _row2_right.get_children():
		_row2_right.remove_child(child)
	_row2_right.custom_minimum_size = Vector2(0, ROW2_HEIGHT)
	if control != null:
		_row2_right.add_child(control)
		_row2_right.custom_minimum_size = Vector2(control.get_combined_minimum_size().x, ROW2_HEIGHT)


## Empurra o `NextStep` para a direita (o Mapa usa para caber a pílula do mundo).
func set_row2_inset(px: float) -> void:
	_row2_inset.custom_minimum_size = Vector2(px, 0.0)


func row2_inset() -> float:
	return _row2_inset.custom_minimum_size.x


## Mostra/esconde a linha 2 (alfa em 0,12 s). Escondida não pega toque: a casca decide quando (`main.set_row2_blocker`).
func set_row2_shown(shown: bool) -> void:
	if shown == _row2_shown and (not shown or row2.visible):
		return
	_row2_shown = shown
	if _row2_tween:
		_row2_tween.kill()
	if shown:
		row2.visible = true
	if Motion.reduced or not is_inside_tree():
		row2.modulate.a = 1.0 if shown else 0.0
		row2.visible = shown
		return
	_row2_tween = create_tween()
	_row2_tween.tween_property(row2, "modulate:a", 1.0 if shown else 0.0, Motion.FADE)
	if not shown:
		_row2_tween.tween_callback(func() -> void: row2.visible = false)


func row2_shown() -> bool:
	return _row2_shown


## Há algo da tela na metade direita da linha 2 (ex.: "Pegar tudo").
func row2_right_used() -> bool:
	return _row2_right.get_child_count() > 0


## Atualiza fase, anel de crescimento e moedas. `animate` falso = só põe os valores (primeira vez).
func refresh(animate: bool = true) -> void:
	var info := GameState.growth_info()
	var fraction := GrowthUi.fraction(info)
	xp_bar.max_value = 1.0
	xp_bar.value = fraction
	var phase := GameState.growth.phase_index()
	level_label.text = str(phase) if phase > 0 else "•"
	_set_ring(fraction, animate and _shown_level >= 0)
	_shown_level = phase
	var total: int = info.requirements.size()
	_profile_bar.value = fraction
	_profile_count.text = "%d/%d" % [total - GrowthUi.missing(info), total] if total > 0 else ""
	_growth_alert.visible = bool(info.ready)
	_profile.visible = not _growth_alert.visible
	_refresh_ask()
	_set_coins(GameState.coins, animate)
	_fit_profile.call_deferred()


## Ícone do que o Tiro pede: o desejo do balão, senão a necessidade que está pedindo.
func _refresh_ask() -> void:
	_animated_badge.visible = GameState.tiro_animated()
	var texture: Texture2D = null
	if not GameState.dog.sleeping and not GameState.walking():
		var wish := GameState.balloon_wish()
		if wish != "":
			texture = WishUi.icon(wish)
		else:
			var need := GameState.asking_need()
			if need != "": texture = Database.need_icon(need)
	_ask_icon.texture = texture
	_ask_icon.visible = texture != null


func _set_ring(fraction: float, animate: bool) -> void:
	if _ring_tween:
		_ring_tween.kill()
	if not animate or Motion.reduced or is_equal_approx(_ring.progress, fraction):
		_ring.progress = fraction
		return
	_ring_tween = create_tween()
	_ring_tween.tween_property(_ring, "progress", fraction, Motion.RESIZE)


## "2645" → "2.645" (algarismos de largura fixa no Fredoka: o número que conta não treme).
static func format_coins(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += "."
		out += digits[i]
	return ("-" if value < 0 else "") + out


func _set_coins(value: int, animate: bool) -> void:
	if value == _coins_target:
		return
	var first := _coins_target < 0
	_coins_target = value
	var shown := _coins_shown
	_coins_shown = value
	if _count_tween:
		_count_tween.kill()
	if first or not animate or Motion.reduced or shown == value:
		coins_label.text = format_coins(value)
		return
	_count_tween = create_tween()
	_count_tween.tween_method(func(step: float) -> void: coins_label.text = format_coins(roundi(step)), float(shown), float(value), Motion.COUNT) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_count_tween.tween_callback(func() -> void: coins_label.text = format_coins(value))
	if value > shown:
		Motion.bounce(coins_pill)


## Centro da pílula de moedas na tela: as moedas do `CollectFx` voam até aqui.
func coins_target() -> Vector2:
	return coins_label.get_global_rect().get_center()


## Consulta da fase; nome antigo mantido para ferramentas e testes existentes.
## Resumo visual: rumo a qual fase, barra em segmentos e um quadradinho tocável por passo que falta.
func show_level_popover() -> Popover:
	var info := GameState.growth_info()
	var card := UiKit.vbox(8)
	card.name = "GrowthQuickSummary"
	card.custom_minimum_size.x = 264
	var visible_steps: Array = info.requirements.filter(func(req: Dictionary) -> bool: return req.type != "given")
	var complete: int = visible_steps.filter(func(req: Dictionary) -> bool: return req.done).size()
	var head := UiKit.hbox(8)
	if not info.next.is_empty():
		head.add_child(GrowthUi.silhouette(info.next, info.requirements.size() - GrowthUi.missing(info), info.ready, "QuickSilhouette", 40))
	var titles := UiKit.vbox(0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titles.add_child(UiKit.label("Guardião do Vale" if info.next.is_empty() else "Rumo a " + str(info.next.name), &"StrongLabel"))
	if info.ready:
		titles.add_child(UiKit.label("Tudo pronto para crescer!", &"SmallLabel", Palette.GO_INK))
	elif not info.next.is_empty():
		titles.add_child(UiKit.label("%s · falta %d" % [str(info.current.name), visible_steps.size() - complete], &"SmallLabel", Palette.INK_SOFT))
	else:
		titles.add_child(UiKit.label("Ele cresceu com você!", &"SmallLabel"))
	head.add_child(titles)
	card.add_child(head)
	if not info.next.is_empty():
		card.add_child(GrowthUi.progress_strip(complete, visible_steps.size(), 8))
	if not info.next.is_empty() and not info.ready:
		var grid := GridContainer.new()
		grid.name = "GrowthQuickGrid"
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		for step: Dictionary in GrowthUi.compact_steps(info):
			grid.add_child(_quick_tile(step))
		card.add_child(grid)
		var tip := UiKit.label("Toque num passo para fazer", &"SmallLabel", Palette.INK_SOFT)
		tip.name = "QuickTip"
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(tip)
	if GameState.tiro_animated():
		var mood := UiKit.hbox(6)
		mood.name = "AnimatedRow"
		mood.add_child(UiKit.icon(UiKit.ui_icon("need_happiness"), 24))
		var words := UiKit.vbox(0)
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_child(UiKit.label("Ele está animado!", &"SmallLabel", Palette.GO_INK))
		var help := UiKit.label(GameState.animated_help(), &"SmallLabel", Palette.INK_SOFT)
		help.name = "AnimatedHelp"
		words.add_child(help)
		mood.add_child(words)
		card.add_child(mood)
	var view := UiKit.soft("Ver detalhes", func() -> void:
		_close_popover()
		GrowthUi.open(), null, true)
	view.name = "ViewGrowth"
	card.add_child(view)
	return Popover.open(get_parent() as Control, avatar_button, card, 0.0)


## Quadradinho de um passo: anel com ícone, nome e quantidade. Tocar fecha o resumo e leva a fazer.
func _quick_tile(step: Dictionary) -> Button:
	var tile := UiKit.button("", func() -> void:
		_close_popover()
		(step.callback as Callable).call(), &"GhostButton")
	tile.name = "GrowthQuick_" + str(step.id)
	tile.custom_minimum_size = Vector2(0, 56)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.SUNKEN
	style.set_corner_radius_all(12)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		tile.add_theme_stylebox_override(state, style)
	var row := UiKit.hbox(4)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 4
	row.offset_right = -4
	tile.add_child(row)
	row.add_child(GrowthUi.step_ring(step, 40))
	var words := UiKit.vbox(0)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	words.add_child(UiKit.short_label(str(step.title), &"SmallLabel"))
	words.add_child(UiKit.short_label("%d/%d" % [step.have, step.need], &"SmallLabel", Palette.GO_INK if step.hint_good else Palette.INK_SOFT))
	row.add_child(words)
	return tile


func _close_popover() -> void:
	var catcher := get_parent().get_node_or_null("PopoverCatcher")
	if catcher: catcher.queue_free()

## O prêmio chegou à pílula: contorno mel curto, independente da contagem das moedas.
func flash_coins() -> void:
	if Motion.reduced: return
	var style := UiKit.surface(Palette.CARD, 20, true)
	style.border_color = Palette.HONEY
	style.set_border_width_all(3)
	coins_pill.add_theme_stylebox_override("panel", style)
	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_instance_valid(coins_pill): coins_pill.remove_theme_stylebox_override("panel"))
