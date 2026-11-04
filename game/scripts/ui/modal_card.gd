class_name ModalCard
extends Control
## Cartão modal único da interface (nível, capítulo, Novo!, vínculo, truque, tesouro, achado,
## volta do passeio raro, roupa nova). Tela cheia com fundo `DIM` e, no meio, o cartão em "madeira ilustrada"
## (a mesma moldura `item_frame` do detalhe de item): placa de madeira com o título, papel creme com o ícone
## grande num pratinho bege com raios girando atrás, o corpo que cada tela monta (`box`), chips de madeira que
## entram um por um e os botões (um verde `primary` + `ghost` amarelo opcional).
## Quem usa é um CanvasLayer (Celebration, WalkResult, GrowthCeremony): `ModalCard.open(self, {...})`
## troca o cartão anterior e devolve este. Os botões fecham o CanvasLayer pelos callbacks de quem usa.
##
## Opções de `open`: title, ribbon (Color, hoje só guardada), icon (Texture2D), icon_px (64), rays (true com ícone),
## hero (Control no lugar do ícone), scroll_name, separation (12), confetti (false),
## haptic ("" | "big" | "success"), animate (true; false = cartão reaberto sem repetir a entrada),
## fixed_body (false; true mantém o corpo fixo e reserva a rolagem para add_scroll_area).
##
## Nós: `CardPanel` (moldura), `Ribbon`/`RibbonTitle` (placa), `Stage`/`Plate`/`BigIcon`/`Rays`, `Body`, o rolável
## (`scroll_name`), botões `Primary`/`Ghost` (a tela que usa pode renomear).

const WIDTH := 344
const INNER := 275  # largura útil do corpo: moldura 344 − bordas da madeira (46,5) − folga do papel (2 × 11)
const PAD_X := 11.0  # folga do papel até o corpo
const PAD_Y := 12.0
const SCREEN_GAP := 8.0  # folga mínima até as bordas laterais da tela
const VERTICAL_GAP := 16.0  # folga até o topo e a base (como antes)
const PLATE_EXTRA := 20  # pratinho = ícone + 20
const RAYS_PATH := "res://assets/sprites/ui/fx/rays.png"
const RAYS_PX := 128
const RAYS_DEGREES_PER_SECOND := 20.0
const CONFETTI_COUNT := 40

static var _confetti_texture: ImageTexture

var panel: Control
var body: Control
var scroll: ScrollContainer
var box: VBoxContainer
var dim: ColorRect
var ribbon: Control
var stage: Control
var icon_node: TextureRect
var rays: TextureRect
var confetti: CPUParticles2D
var _want_confetti := false
var _animate := true
var _fixed_body := false
var _scroll_content: Control


## Troca o cartão que estiver em `host` por um novo, já com placa, ícone e raios.
static func open(host: Node, options: Dictionary) -> ModalCard:
	for child: Node in host.get_children():
		host.remove_child(child)
		child.queue_free()
	var card := ModalCard.new()
	card.name = "ModalCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(card)
	card._build(options)
	return card


static func _width() -> float:
	return minf(float(WIDTH), ItemUi._screen().x - SCREEN_GAP)


func _build(options: Dictionary) -> void:
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = Control.new()
	panel.name = "CardPanel"
	panel.theme = load("res://assets/theme/main_theme.tres")
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size.x = _width()
	center.add_child(panel)
	var art := SellUi.nine("frame", ItemUi.FRAME_MARGINS, "Art", null, "item_")
	panel.add_child(art)
	StepCardUi.stretch(art)
	var paper := SellUi.nine("card", Vector4i(75, 75, 75, 75), "Paper", null, "item_")
	panel.add_child(paper)
	SellUi.place(paper, 0.0, ItemUi.IN_L, 1.0, -ItemUi.IN_R, 0.0, ItemUi.TOP, 1.0, -ItemUi.BOTTOM)
	body = Control.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(body)
	SellUi.place(body, 0.0, ItemUi.IN_L + PAD_X, 1.0, -(ItemUi.IN_R + PAD_X), 0.0, ItemUi.TOP + PAD_Y, 1.0, -(ItemUi.BOTTOM + PAD_Y))
	scroll = ScrollContainer.new()
	scroll.name = str(options.get("scroll_name", "ModalScroll"))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_fixed_body = bool(options.get("fixed_body", false))
	if not _fixed_body:
		body.add_child(scroll)
		StepCardUi.stretch(scroll)
	box = UiKit.vbox(int(options.get("separation", 12)))
	box.custom_minimum_size.x = INNER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _fixed_body:
		body.add_child(box)
		StepCardUi.stretch(box)
	else:
		scroll.add_child(box)
	var title := str(options.get("title", ""))
	if title != "":
		panel.add_child(_ribbon(title))
	if options.get("hero") is Control:
		box.add_child(_centered(options.hero as Control))
	elif options.get("icon") is Texture2D:
		box.add_child(_stage(options.icon as Texture2D, int(options.get("icon_px", 64)), bool(options.get("rays", true))))
	if _fixed_body:
		box.add_child(scroll)
		scroll.hide()
	_animate = bool(options.get("animate", true))
	_want_confetti = bool(options.get("confetti", false))
	match str(options.get("haptic", "")):
		"big":
			Haptics.big()
		"success":
			Haptics.success()
	box.minimum_size_changed.connect(_resize_panel)
	get_viewport().size_changed.connect(_resize_panel)
	_resize_panel.call_deferred()
	_start()


## Placa de madeira no alto da moldura com o título (fonte da madeira; encolhe para caber). Nó `Ribbon`, texto `RibbonTitle`.
func _ribbon(title: String) -> Control:
	ribbon = Control.new()
	ribbon.name = "Ribbon"
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	StepCardUi.stretch(ribbon)
	var avail := _width() - ItemUi.PLAQUE_X * 2.0
	var px := 22
	for candidate in [22, 20, 19, 18, 17, 16, 15, 14, 13]:
		px = candidate
		if ItemUi._text_w(title, candidate) <= avail:
			break
	var label := MissionUi.text(title, px, Palette.WOOD_CREAM, 3)
	label.name = "RibbonTitle"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ribbon.add_child(label)
	SellUi.place(label, 0.0, ItemUi.PLAQUE_X, 1.0, -ItemUi.PLAQUE_X, 0.0, ItemUi.PLAQUE_Y, 0.0, ItemUi.PLAQUE_BASE)
	return ribbon


## Ícone grande num pratinho bege, com os raios girando devagar atrás. Pixel (até 32 px) sempre em escala INTEIRA e
## nítido; ilustração maior é reduzida e suave.
func _stage(texture: Texture2D, icon_px: int, with_rays: bool) -> Control:
	stage = Control.new()
	stage.name = "Stage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.clip_contents = true
	var pixel := texture.get_width() <= 32
	var drawn := icon_px
	if pixel:
		drawn = texture.get_width() * maxi(1, roundi(icon_px / float(texture.get_width())))
	var plate_px := drawn + PLATE_EXTRA
	var height := plate_px + 28 if with_rays else plate_px + 4
	stage.custom_minimum_size = Vector2(INNER, height)
	if with_rays and ResourceLoader.exists(RAYS_PATH):
		rays = TextureRect.new()
		rays.name = "Rays"
		rays.texture = load(RAYS_PATH)
		rays.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rays.stretch_mode = TextureRect.STRETCH_SCALE
		rays.size = Vector2(height, height)
		rays.position = Vector2((INNER - height) / 2.0, 0)
		rays.pivot_offset = rays.size / 2.0
		rays.modulate.a = 0.35
		rays.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(rays)
	var plate := SellUi.soft(TextureRect.new())
	plate.name = "Plate"
	plate.texture = ItemUi.tex("plate")
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.size = Vector2(plate_px, plate_px)
	plate.position = Vector2((INNER - plate_px) / 2.0, (height - plate_px) / 2.0)
	stage.add_child(plate)
	icon_node = TextureRect.new()
	icon_node.name = "BigIcon"
	icon_node.texture = texture
	icon_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon_node.size = Vector2(drawn, drawn)
	icon_node.position = Vector2((INNER - drawn) / 2.0, (height - drawn) / 2.0)
	icon_node.pivot_offset = icon_node.size / 2.0
	stage.add_child(icon_node)
	return stage


## Entrada: fundo escurece, cartão salta de 0,7, ícone salta, raios giram e (se pedido) cai confete.
func _start() -> void:
	if Motion.reduced or not _animate:
		return
	dim.modulate.a = 0.0
	panel.modulate.a = 0.0
	create_tween().tween_property(dim, "modulate:a", 1.0, 0.2)
	if icon_node:
		icon_node.modulate.a = 0.0
	if rays:
		rays.create_tween().set_loops().tween_property(rays, "rotation_degrees", 360.0, 360.0 / RAYS_DEGREES_PER_SECOND).from(0.0)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	Motion.pop_in(panel, Vector2.ONE, 0.7)
	if icon_node:
		get_tree().create_timer(0.12).timeout.connect(func() -> void:
			if is_instance_valid(icon_node) and is_inside_tree():
				Motion.pop_in(icon_node))
	if _want_confetti:
		fire_confetti()


## Confete: 40 retângulos 4×6 que sobem do cartão e caem (CPUParticles2D: serve no Web/Compatibility).
## "Menos animação" não solta confete.
func fire_confetti() -> void:
	if Motion.reduced or is_instance_valid(confetti):
		return
	confetti = CPUParticles2D.new()
	confetti.name = "Confetti"
	confetti.texture = _confetti_tex()
	confetti.amount = CONFETTI_COUNT
	confetti.lifetime = 1.6
	confetti.one_shot = true
	confetti.explosiveness = 0.95
	confetti.emitting = false
	confetti.direction = Vector2(0, -1)
	confetti.spread = 70.0
	confetti.gravity = Vector2(0, 300)
	confetti.initial_velocity_min = 220.0
	confetti.initial_velocity_max = 380.0
	confetti.angle_min = 0.0
	confetti.angle_max = 360.0
	confetti.angular_velocity_min = -360.0
	confetti.angular_velocity_max = 360.0
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	colors.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8])
	colors.colors = PackedColorArray([Palette.GO, Palette.HONEY, Palette.HONEY, Palette.SKY, Palette.ALERT])
	confetti.color_initial_ramp = colors
	var area := get_viewport_rect().size
	confetti.position = Vector2(area.x / 2.0, area.y * 0.55)
	add_child(confetti)
	confetti.restart()
	confetti.emitting = true


static func _confetti_tex() -> ImageTexture:
	if _confetti_texture == null:
		var image := Image.create_empty(4, 6, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_confetti_texture = ImageTexture.create_from_image(image)
	return _confetti_texture


## Cartões curtos ficam centrados; listas longas cabem na tela e rolam até os botões finais.
func _resize_panel() -> void:
	if not is_instance_valid(panel) or not is_instance_valid(box) or not is_inside_tree():
		return
	var frame_height := ItemUi.TOP + ItemUi.BOTTOM + PAD_Y * 2.0
	var limit := maxf(0.0, get_viewport().get_visible_rect().size.y - VERTICAL_GAP * 2.0)
	if _fixed_body and is_instance_valid(_scroll_content):
		# Só a grade cede altura: placa, herói e ações nunca entram na rolagem.
		var fixed_height := box.get_combined_minimum_size().y - scroll.custom_minimum_size.y
		var available := limit - frame_height - fixed_height
		var height := minf(_scroll_content.get_combined_minimum_size().y, maxf(0.0, available))
		if not is_equal_approx(scroll.custom_minimum_size.y, height):
			scroll.custom_minimum_size.y = height
	var content_height := box.get_combined_minimum_size().y + frame_height
	panel.custom_minimum_size = Vector2(_width(), minf(content_height, limit))


## Adiciona ao corpo e devolve o próprio controle.
func add(control: Control) -> Control:
	box.add_child(control)
	return control


## Corpo fixo opcional: somente este conteúdo rola no espaço restante do cartão.
func add_scroll_area(content: Control) -> void:
	_scroll_content = content
	box.move_child(scroll, -1)
	scroll.show()
	scroll.add_child(content)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.minimum_size_changed.connect(_resize_panel)
	_resize_panel.call_deferred()


## Texto centralizado no corpo, na fonte da madeira (forte/título maiores; `color` null = marrom da madeira).
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
	box.add_child(label)
	return label


## Pílula creme pequena (a mesma do "Quantidade" do detalhe de item) com um texto curto, ex.: "2/16".
func add_pill(text: String, node_name: String = "CountPill") -> Control:
	var pill := ItemUi._pill(text)
	pill.name = node_name
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(pill)
	return pill


## Chips de prêmio em madeira, centralizados; entram um por um e os números contam.
func add_chips(chips: Container) -> Container:
	if chips.get_child_count() == 0:
		chips.queue_free()
		return chips
	if chips is FlowContainer:
		(chips as FlowContainer).alignment = FlowContainer.ALIGNMENT_CENTER
	for chip: Node in chips.get_children():
		wood_skin_chip(chip as Control)
	box.add_child(chips)
	reveal(chips)
	return chips


## Veste um chip liso do `UiKit.chip` com a pele de madeira (a mesma da `StepCardUi.wood_chip`): ícone pixel 32 em escala 1:1
## e número na fonte da madeira.
static func wood_skin_chip(chip: Control) -> void:
	if chip == null or not chip is PanelContainer or chip.get_child_count() == 0:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WOOD_INSET
	style.border_color = Color("c9935f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.content_margin_left = 8.0
	style.content_margin_right = 12.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	chip.theme_type_variation = &""
	chip.add_theme_stylebox_override("panel", style)
	chip.custom_minimum_size.y = 40.0
	for child: Node in chip.get_child(0).get_children():
		if child is TextureRect:
			var picture := child as TextureRect
			if picture.texture != null and picture.texture.get_width() <= 32:
				picture.custom_minimum_size = Vector2(32, 32)
				picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		elif child is Label:
			var label := child as Label
			var ink := label.get_theme_color("font_color") if label.has_theme_color_override("font_color") else Palette.WOOD_INK
			label.theme_type_variation = &""
			label.theme = HomeUi.theme(19, ink)
			label.autowrap_mode = TextServer.AUTOWRAP_OFF


## Largura do botão de madeira: segue o texto, entre 168 e a largura do corpo.
static func button_width(text: String) -> float:
	return clampf(ItemUi._text_w(text, 18) + 56.0, 168.0, float(INNER))


## O botão principal do cartão (um só): verde de madeira.
func add_primary(text: String, on_pressed: Callable) -> Button:
	var button := WelcomeSheet._button(text, true, button_width(text), "Primary", on_pressed)
	box.add_child(button)
	return button


## Ação fraca embaixo ("Continuar"): amarelo de madeira.
func add_ghost(text: String, on_pressed: Callable) -> Button:
	var button := WelcomeSheet._button(text, false, button_width(text), "Ghost", on_pressed)
	box.add_child(button)
	return button


## Os filhos de `container` entram um por um (pop_in, 80 ms entre eles); "+N" e "×N" contam de 0.
## Com Motion.reduced ficam visíveis e com o número final na hora.
func reveal(container: Container) -> void:
	Motion.reveal_rewards(container, _animate)


func _centered(control: Control) -> Control:
	if control is Label:
		(control as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return control
