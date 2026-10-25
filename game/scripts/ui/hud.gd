class_name Hud
extends Control
## HUD flutuante sobre as telas (nó `TopBar` da casca), em "madeira ilustrada" (posições do protótipo 360×780).
## Linha 1: moldura do avatar com a cabeça do Tiro · placa com a barra de crescimento ("n/m" dos requisitos da fase)
## · moedas e engrenagem (e o selo DEV). Linha 2 (`HudRow2`): o `NextStep` (cartão da missão) à esquerda; a direita
## fica para a tela (bandeja de necessidades, "Pegar tudo").
## Só as peças recebem toque (o resto é `MOUSE_FILTER_IGNORE`). Quem manda atualizar é a casca (`refresh`).
## As imagens vêm de `HomeUi`; os nomes de nó e as funções antigas continuam (testes e telas leem).

const HEIGHT := 168.0
## Topo mais alto da folha (Sheet): ela cobre a linha 2 (que recolhe) e deixa a linha 1 à vista; mantém a altura útil antiga.
const SHEET_TOP := 128.0
const AVATAR := 80.0
const AVATAR_SIZE := Vector2(80.0, 84.0)
const ROW1_TOP := 10.0
const ROW2_TOP := 100.0
const ROW2_HEIGHT := 65.0
const SIDE := 12.0
const ROW2_LEFT := 8.0
const ROW2_RIGHT := 6.0
const PROFILE_POS := Vector2(94.0, 10.0)
const PROFILE_SIZE := Vector2(168.0, 74.0)
const BAR_POS := Vector2(11.0, 44.0)
const BAR_WIDTH := 120.0
const COINS_SIZE := Vector2(86.0, 40.0)

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
var _head: TextureRect
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
var _profile_fill: NinePatchRect
var _profile_count: Label
var _row2_inset: Control
var _row2_left: Control
var _row2_right: Control
var _row2_shown := true
var _row2_tween: Tween
var _flash_tween: Tween


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
	_growth_alert.position = PROFILE_POS + Vector2(4.0, 4.0)
	_growth_alert.custom_minimum_size = Vector2(PROFILE_SIZE.x - 8.0, PROFILE_SIZE.y - 8.0)
	_growth_alert.size = _growth_alert.custom_minimum_size
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
	_avatar_group.position = Vector2(SIDE - 4.0, ROW1_TOP)
	_avatar_group.size = AVATAR_SIZE
	add_child(_avatar_group)
	HomeUi.pic(_avatar_group, "avatar_frame", Rect2(Vector2.ZERO, AVATAR_SIZE), "AvatarFrame")
	# A cabeça é recortada do quadro parado do corpo atual; a moldura vazia a enquadra.
	var clip := Control.new()
	clip.name = "HeadClip"
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = Vector2(8.0, 14.0)
	clip.size = Vector2(64.0, 55.0)
	clip.clip_contents = true
	_avatar_group.add_child(clip)
	_head = HomeUi.pic(clip, "avatar_frame", Rect2(8.0, 6.0, 49.0, 49.0), "HudHead")
	_head.texture = null
	avatar_button = Button.new()
	avatar_button.name = "HudAvatar"
	# O ícone do retrato continua ligado ao estado (testes leem), mas fica transparente: quem aparece é a cabeça.
	DogLook.bind(avatar_button, "portrait", "icon")
	avatar_button.self_modulate = Color(1, 1, 1, 0)
	avatar_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_button.expand_icon = true
	avatar_button.add_theme_constant_override("icon_max_width", 40)
	avatar_button.focus_mode = Control.FOCUS_NONE
	avatar_button.custom_minimum_size = AVATAR_SIZE
	avatar_button.size = AVATAR_SIZE
	for style_name: String in ["normal", "hover", "disabled", "pressed", "hover_pressed", "focus"]:
		avatar_button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	avatar_button.pressed.connect(show_level_popover)
	Motion.press(avatar_button)
	_avatar_group.add_child(avatar_button)
	# Anel de crescimento antigo: só guarda o progresso (a placa mostra a barra).
	_ring = RingProgress.new()
	_ring.name = "XpRing"
	_ring.visible = false
	_ring.custom_minimum_size = Vector2(AVATAR, AVATAR)
	_ring.size = Vector2(AVATAR, AVATAR)
	_avatar_group.add_child(_ring)
	# Número da fase: continua existindo (testes e ferramentas leem).
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
	_ask_icon.position = Vector2(AVATAR - 22.0, 0.0)
	_ask_icon.visible = false
	_avatar_group.add_child(_ask_icon)
	_animated_badge = UiKit.spark(18)
	_animated_badge.name = "AnimatedBadge"
	_animated_badge.position = Vector2(AVATAR - 22.0, AVATAR_SIZE.y - 24.0)
	_animated_badge.size = Vector2(18, 18)
	_animated_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_avatar_group.add_child(_animated_badge)
	# Mantida só por compatibilidade (testes e ferramentas leem); a placa mostra o progresso.
	xp_bar = ProgressBar.new()
	xp_bar.name = "XpBar"
	xp_bar.visible = false
	xp_bar.show_percentage = false
	add_child(xp_bar)


## Placa de madeira "Tiro" com a barra de crescimento e o "n/m" dos requisitos da fase. Tocar = tocar no avatar.
func _build_profile() -> void:
	_profile = Button.new()
	_profile.name = "HudProfile"
	_profile.focus_mode = Control.FOCUS_NONE
	_profile.custom_minimum_size = PROFILE_SIZE
	_profile.size = PROFILE_SIZE
	_profile.position = PROFILE_POS
	for style_name: String in ["normal", "hover", "disabled", "focus", "pressed", "hover_pressed"]:
		_profile.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	_profile.pressed.connect(show_level_popover)
	Motion.press(_profile)
	add_child(_profile)
	HomeUi.pic(_profile, "plaque", Rect2(Vector2.ZERO, PROFILE_SIZE), "ProfilePlaque")
	HomeUi.bar(_profile, "bar_track", Rect2(BAR_POS, Vector2(BAR_WIDTH + 2.0, 18.0)), 9, "ProfileTrack")
	_profile_fill = HomeUi.bar(_profile, "bar_fill", Rect2(BAR_POS + Vector2(1.0, 1.0), Vector2(BAR_WIDTH, 16.0)), 8, "ProfileBar")
	HomeUi.patch(_profile, Rect2(134.0, 41.0, 26.0, 24.0), Palette.WOOD_PATCH, 4)
	_profile_count = HomeUi.text(_profile, "", Rect2(131.0, 41.0, 32.0, 24.0), 15, Palette.WOOD_CREAM, Palette.WOOD_INK, 6, "ProfileCount")


func _build_right() -> void:
	var column := Control.new()
	column.name = "CoinsColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.anchor_left = 1.0
	column.anchor_right = 1.0
	column.offset_left = -92.0
	column.offset_right = -6.0
	column.offset_top = ROW1_TOP - 1.0
	column.offset_bottom = ROW1_TOP + 88.0
	add_child(column)
	# Pílula de madeira vazia com a moeda; o número é um rótulo por cima.
	var pill := Control.new()
	pill.name = "CoinsPill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.position = Vector2.ZERO
	pill.size = COINS_SIZE
	pill.custom_minimum_size = COINS_SIZE
	pill.pivot_offset = COINS_SIZE / 2.0
	column.add_child(pill)
	coins_pill = pill
	HomeUi.pic(pill, "coins", Rect2(0.0, 3.0, 86.0, 34.0), "CoinsArt")
	coins_label = HomeUi.text(pill, "0", Rect2(32.0, 7.0, 50.0, 26.0), 17, Palette.WOOD_INK, Palette.WOOD_INK, 0, "CoinsLabel")
	# Engrenagem abaixo das moedas (arte 38×40 dentro de um alvo de 48).
	settings_button = UiKit.button("", SettingsPanel.open, &"GhostButton")
	settings_button.name = "SettingsButton"
	settings_button.custom_minimum_size = Vector2(48, 48)
	settings_button.size = Vector2(48, 48)
	settings_button.position = Vector2(43.0, 41.0)
	for style_name: String in ["normal", "hover", "disabled", "focus", "pressed", "hover_pressed"]:
		settings_button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	column.add_child(settings_button)
	HomeUi.pic(settings_button, "settings", Rect2(4.0, 4.0, 40.0, 40.0), "Disc")
	dev_button = Button.new()
	dev_button.name = "DevButton"
	dev_button.text = "DEV"
	dev_button.theme = HomeUi.theme(12, Palette.CARD)
	dev_button.visible = false
	dev_button.focus_mode = Control.FOCUS_NONE
	dev_button.custom_minimum_size = Vector2(40, 20)
	dev_button.position = Vector2(0.0, 52.0)
	var dev_style := UiKit.surface(Palette.ALERT, 10)
	dev_style.content_margin_left = 3.0
	dev_style.content_margin_right = 3.0
	dev_style.content_margin_top = 0.0
	dev_style.content_margin_bottom = 0.0
	for style_name: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		dev_button.add_theme_stylebox_override(style_name, dev_style)
	Motion.press(dev_button)
	column.add_child(dev_button)
	dev_button.size = Vector2(40, 20)  # depois dos estilos: antes, o tamanho mínimo padrão do botão o alargaria


## Segunda linha: [recuo do Mapa] [próximo passo] ····· [conteúdo da tela, à direita].
func _build_row2() -> void:
	row2 = HBoxContainer.new()
	row2.name = "HudRow2"
	row2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row2.add_theme_constant_override("separation", 0)
	row2.anchor_right = 1.0
	row2.offset_left = ROW2_LEFT
	row2.offset_right = -ROW2_RIGHT
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


## Troca o que vive à direita da linha 2 (a tela do Tiro põe a bandeja de necessidades, as Missões o "Pegar tudo"). `null` esvazia.
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


## Atualiza fase, barra de crescimento e moedas. `animate` falso = só põe os valores (primeira vez).
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
	_set_fill(fraction)
	_profile_count.text = "%d/%d" % [total - GrowthUi.missing(info), total] if total > 0 else ""
	_growth_alert.visible = bool(info.ready)
	_profile.visible = not _growth_alert.visible
	_refresh_head()
	_refresh_ask()
	_set_coins(GameState.coins, animate)


## Cabeça do Tiro na moldura: recorte do corpo atual, com a pelagem do estado.
func _refresh_head() -> void:
	_head.texture = HomeUi.head_texture()
	DogLook.tint(_head)


## A barra mostra a fração da fase; abaixo do tamanho dos cantos some, para não amassar a ponta.
func _set_fill(fraction: float) -> void:
	_profile_fill.visible = fraction > 0.0
	HomeUi.resize_bar(_profile_fill, Vector2(maxf(BAR_WIDTH * clampf(fraction, 0.0, 1.0), 16.0), 16.0))


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


## Número da pílula; passa de 6 caracteres, a fonte encolhe para caber nos 50 px do remendo.
func _show_coins(value: int) -> void:
	var text := format_coins(value)
	coins_label.text = text
	coins_label.theme = HomeUi.theme(17 if text.length() <= 6 else 13, Palette.WOOD_INK)


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
		_show_coins(value)
		return
	_count_tween = create_tween()
	_count_tween.tween_method(func(step: float) -> void: _show_coins(roundi(step)), float(shown), float(value), Motion.COUNT) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_count_tween.tween_callback(func() -> void: _show_coins(value))
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


## O prêmio chegou à pílula: brilho dourado curto, independente da contagem das moedas.
func flash_coins() -> void:
	if Motion.reduced: return
	if _flash_tween:
		_flash_tween.kill()
	coins_pill.modulate = Color(1.35, 1.2, 0.8)
	_flash_tween = create_tween()
	_flash_tween.tween_property(coins_pill, "modulate", Color.WHITE, 0.6)
