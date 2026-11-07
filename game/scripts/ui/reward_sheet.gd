class_name RewardSheet
extends Control
## Folha média de prêmio em "madeira ilustrada" (a mesma moldura `item_frame` do detalhe de item, das boas-vindas e do
## `ModalCard`): sobe de baixo e fica encostada na base, com a placa de madeira do título, o X de madeira, papel creme
## com fala opcional (retrato na moldura + balão de papel), chips de madeira, um bloco livre (`body`) e os botões
## (amarelo "Depois" + verde principal, um só verde). Base de QuestReward (passo da história) e "Novo!".
## Quem usa é um CanvasLayer: `RewardSheet.open(self, {...})` troca a folha anterior e devolve esta; o fundo, o X e
## Escape fecham pelo `on_close` (padrão: esconder o host). O corpo rola por dentro se não couber entre o HUD e a base.
##
## Opções de `open`: title, hero (Control logo abaixo da placa), speech ({npc, text}), close_button (true), on_close
## (Callable), scroll_name, animate (true; false = folha reaberta sem repetir a entrada), haptic ("success").
## (`ribbon`/`ribbon_icon` são aceitas e ignoradas: a placa de madeira não leva cor nem ícone.)
## Nós: `RewardPanel` (moldura), `RewardRibbon`/`RibbonTitle` (placa), `RewardClose` (X), `RewardSpeech`, o rolável
## (`scroll_name`); `soft`/`primary` de `add_actions` são botões de madeira com o texto no próprio Button.


var host: Node
var panel: Control
var scroll: ScrollContainer
var body: VBoxContainer
var dim: ColorRect
var _on_close := Callable()
var _animate := true
var _rest_y := 0.0
var _tween: Tween


static func open(host_node: Node, options: Dictionary) -> RewardSheet:
	for child: Node in host_node.get_children():
		host_node.remove_child(child)
		child.queue_free()
	var sheet := RewardSheet.new()
	sheet.name = "RewardSheet"
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host_node.add_child(sheet)
	sheet._build(host_node, options)
	return sheet


## Largura da folha e do corpo útil (a moldura menos as bordas e a folga do papel), limitadas pela tela.
static func sheet_width() -> float:
	return minf(float(ModalCard.WIDTH), ItemUi._screen().x - ModalCard.SCREEN_GAP)


static func inner_width() -> float:
	return sheet_width() - ItemUi.IN_L - ItemUi.IN_R - ModalCard.PAD_X * 2.0


func _build(host_node: Node, options: Dictionary) -> void:
	host = host_node
	_on_close = options.get("on_close", Callable()) as Callable
	_animate = bool(options.get("animate", true))
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			close())
	panel = Control.new()
	panel.name = "RewardPanel"
	panel.theme = load("res://assets/theme/main_theme.tres")
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	var art := SellUi.nine("frame", ItemUi.FRAME_MARGINS, "Art", null, "item_")
	panel.add_child(art)
	StepCardUi.stretch(art)
	var paper := SellUi.nine("card", Vector4i(75, 75, 75, 75), "Paper", null, "item_")
	panel.add_child(paper)
	SellUi.place(paper, 0.0, ItemUi.IN_L, 1.0, -ItemUi.IN_R, 0.0, ItemUi.TOP, 1.0, -ItemUi.BOTTOM)
	scroll = ScrollContainer.new()
	scroll.name = str(options.get("scroll_name", "RewardScroll"))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	var pad_x := ItemUi.IN_L + ModalCard.PAD_X
	SellUi.place(scroll, 0.0, pad_x, 1.0, -(ItemUi.IN_R + ModalCard.PAD_X), 0.0, ItemUi.TOP + ModalCard.PAD_Y, 1.0, -(ItemUi.BOTTOM + ModalCard.PAD_Y))
	body = UiKit.vbox(10)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	panel.add_child(_overlay(str(options.get("title", "")), bool(options.get("close_button", true))))
	if options.get("hero") is Control:
		var hero := options.hero as Control
		hero.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		body.add_child(hero)
	var speech: Dictionary = options.get("speech", {})
	if not speech.is_empty():
		body.add_child(_speech(str(speech.get("npc", "lais")), str(speech.get("text", ""))))
	full_resized_connect()
	match str(options.get("haptic", "success")):
		"success":
			Haptics.success()
		"big":
			Haptics.big()


func full_resized_connect() -> void:
	resized.connect(layout)
	minimum_size_changed.connect(layout)
	body.minimum_size_changed.connect(layout)


## Placa de madeira com o título (fonte da madeira; encolhe para caber) e o X de madeira. Nós `RewardRibbon`/`RibbonTitle`, `RewardClose`.
func _overlay(title: String, with_close: bool) -> Control:
	var layer := Control.new()
	layer.name = "RewardRibbon"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StepCardUi.stretch(layer)
	var avail := sheet_width() - ItemUi.PLAQUE_X * 2.0
	var px := 22
	for candidate in [22, 20, 19, 18, 17, 16, 15, 14, 13]:
		px = candidate
		if ItemUi._text_w(title, candidate) <= avail:
			break
	var plaque := MissionUi.text(title, px, Palette.WOOD_CREAM, 3)
	plaque.name = "RibbonTitle"
	plaque.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plaque.clip_text = true
	plaque.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layer.add_child(plaque)
	SellUi.place(plaque, 0.0, ItemUi.PLAQUE_X, 1.0, -ItemUi.PLAQUE_X, 0.0, ItemUi.PLAQUE_Y, 0.0, ItemUi.PLAQUE_BASE)
	if with_close:
		var x := BagUi.plain_button(close)
		x.name = "RewardClose"
		x.custom_minimum_size = Vector2(44, 44)
		var picture := SellUi.soft(TextureRect.new())
		picture.texture = MissionUi.tex("close")
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		x.add_child(picture)
		picture.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		picture.offset_left = -19.0
		picture.offset_right = 19.0
		picture.offset_top = -19.0
		picture.offset_bottom = 19.0
		x.pressed.connect(func() -> void: Motion.bounce(picture))
		layer.add_child(x)
		var box := ItemUi.CLOSE_BOX
		SellUi.place(x, 1.0, box.x, 1.0, box.z, 0.0, box.y, 0.0, box.w)
	return layer


## Fala: retrato na moldura de madeira (72) e balão de papel que aponta para ele.
func _speech(npc: String, text: String) -> Control:
	var speech := UiKit.hbox(6)
	speech.name = "RewardSpeech"
	var face := TextureRect.new()
	face.texture = ProgressionUi.npc_portrait(npc)
	var framed := StepCardUi.portrait_frame(face, 72.0, "NpcPortrait")
	framed.size_flags_vertical = Control.SIZE_SHRINK_END
	speech.add_child(framed)
	var bubble := SpeechBubble.new(text, "", false, true)
	bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speech.add_child(bubble)
	return speech


## Adiciona ao corpo e devolve o próprio controle.
func add(control: Control) -> Control:
	body.add_child(control)
	return control


## Texto centralizado na fonte da madeira (forte/título maiores; `color` null = marrom da madeira).
func add_text(text: String, variation: StringName = &"", color: Variant = null) -> Label:
	var px := 16
	var ink := Palette.WOOD_INK
	match variation:
		&"TitleLabel":
			px = 22
		&"StrongLabel", &"NumberLabel":
			px = 20
		&"SmallLabel":
			px = 15
			ink = Palette.WOOD_INK.lightened(0.18)
	var label := StepCardUi.wood(text, px, color as Color if color is Color else ink)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(label)
	return label


## Título de seção em madeira ("Próximo passo"), à esquerda.
func add_heading(text: String) -> Label:
	var label := StepCardUi.wood(text, 16)
	label.name = "Heading"
	body.add_child(label)
	return label


## Chips de prêmio em madeira, centralizados; entram um por um e os números contam.
func add_chips(chips: Container) -> Container:
	if chips.get_child_count() == 0:
		chips.queue_free()
		return chips
	if chips is FlowContainer:
		(chips as FlowContainer).alignment = FlowContainer.ALIGNMENT_CENTER
	for chip: Node in chips.get_children():
		grow_chip(chip as Control)
	body.add_child(chips)
	if _animate:
		reveal_in(chips)
	return chips


## Linha de botões: amarelo (opcional, "Depois") à esquerda e o verde principal (um só) ocupando o resto.
## Se o texto do verde não couber nem em 14 px, o botão ganha a meta `too_long` (quem usa pode trocar por "Ir").
func add_actions(soft_text: String, soft_call: Callable, primary_text: String, primary_call: Callable) -> Dictionary:
	var actions := UiKit.hbox(8)
	actions.name = "RewardActions"
	var soft: Button = null
	var soft_w := 0.0
	if soft_text != "":
		soft_w = maxf(96.0, ItemUi._text_w(soft_text, 18) + 40.0)
		soft = WelcomeSheet._button(soft_text, false, soft_w, "RewardSoft", soft_call)
		actions.add_child(soft)
	var primary: Button = null
	if primary_text != "":
		var room := inner_width() - (soft_w + 8.0 if soft else 0.0)
		primary = WelcomeSheet._button(primary_text, true, room, "RewardPrimary", primary_call)
		primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		primary.custom_minimum_size.x = 0.0
		actions.add_child(primary)
		if ItemUi._text_w(primary_text, 14) > room - 24.0:
			primary.set_meta("too_long", true)
	elif soft:
		soft.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		soft.custom_minimum_size.x = 0.0
	body.add_child(actions)
	return {"soft": soft, "primary": primary}


## Mostra a folha (entra subindo de baixo, salvo Menos animação ou `animate` falso).
func present() -> void:
	scroll.scroll_vertical = 0
	layout.call_deferred()
	if not Motion.reduced and _animate:
		_animate_open.call_deferred()


func close() -> void:
	if _tween:
		_tween.kill()
	if _on_close.is_valid():
		_on_close.call()
	elif is_instance_valid(host) and host is CanvasLayer:
		(host as CanvasLayer).hide()


## Folha centrada, encostada na base e nunca sob o HUD; o corpo rola por dentro quando não cabe.
func layout() -> void:
	if not is_instance_valid(panel) or not is_inside_tree():
		return
	var area := get_viewport().get_visible_rect().size
	var width := sheet_width()
	body.custom_minimum_size.x = inner_width()
	var wanted := body.get_combined_minimum_size().y + ItemUi.TOP + ItemUi.BOTTOM + ModalCard.PAD_Y * 2.0
	var limit := area.y - Hud.SHEET_TOP - ItemUi.TAIL
	var height := minf(wanted, limit)
	panel.custom_minimum_size = Vector2(width, height)
	panel.size = Vector2(width, height)
	_rest_y = area.y - height - ItemUi.TAIL
	if _tween == null or not _tween.is_running():
		panel.position = Vector2((area.x - width) / 2.0, _rest_y)


func _animate_open() -> void:
	if not is_instance_valid(panel) or not is_inside_tree():
		return
	layout()
	if _tween:
		_tween.kill()
	panel.position.y = get_viewport().get_visible_rect().size.y
	_tween = create_tween()
	_tween.tween_property(panel, "position:y", _rest_y, Motion.SHEET_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		close()


## Cartão de papel "próximo passo" (madeira): ícone do objetivo num quadradinho, nome da missão, destino e n/m.
## Mantém o nó `NextStepCard` (meta `quest`) e `QuestDestination`.
static func next_card(id: String) -> Control:
	var holder := UiKit.vbox(0)
	holder.name = "NextStepCard"
	holder.set_meta("quest", id)
	var inner := StepCardUi.inner_card(holder, "NextStepPaper", Vector4i(10, 8, 12, 8))
	var goal := ProgressionUi.current_goal(id)
	var target := Places.quest_target(id)
	var row := UiKit.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(MissionUi.tile(ProgressionUi.goal_icon(goal), "", "NextStepIcon", Vector2(48, 48.0 * 119.0 / 112.0)))
	var info := UiKit.vbox(0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name_label := StepCardUi.wood(str(Database.quests[id].name), 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = 80.0
	info.add_child(name_label)
	var destination := StepCardUi.wood(ProgressionUi.quest_place_name(target), 14, Palette.WOOD_INK.lightened(0.25))
	destination.name = "QuestDestination"
	info.add_child(destination)
	row.add_child(info)
	var total := int(goal.get("target", 1))
	var count := StepCardUi.wood("%d/%d" % [mini(GameState.goal_value(goal), total), total], 16)
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(count)
	inner.add_child(row)
	return holder


## Chip de prêmio de madeira (veste o chip liso com a pele de madeira do `ModalCard`).
static func grow_chip(chip: Control) -> void:
	ModalCard.wood_skin_chip(chip)


## Chip de prêmio "+N" para a folha (moedas, item); o número conta quando `add_chips` o revela.
static func prize_chip(chip_name: String, texture: Texture2D, amount: int, keepsake: bool = false) -> Control:
	var chip := UiKit.chip(texture, "+%d" % amount, null, "prize")
	chip.name = chip_name
	grow_chip(chip)
	if keepsake:
		(chip.get_child(0) as HBoxContainer).add_child(UiKit.spark())
	return chip


## Os filhos de `container` entram um por um (pop_in, 80 ms entre eles); "+N" e "×N" contam de 0.
## Com Motion.reduced ficam visíveis e com o número final na hora.
static func reveal_in(container: Container) -> void:
	Motion.reveal_rewards(container)
