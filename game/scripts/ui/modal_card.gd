class_name ModalCard
extends Control
## Cartão modal único da interface (nível, capítulo, Novo!, vínculo, truque, tesouro, achado,
## volta do passeio, boas-vindas, roupa nova). Tela cheia com fundo `DIM` e, no meio, o cartão:
## fita colorida com o título, ícone grande com raios girando, o corpo que cada tela monta
## (`box`), chips que entram um por um e os botões (um `primary` + `ghost` opcional).
## Quem usa é um CanvasLayer (Celebration, WalkResult, WelcomeBack): `ModalCard.open(self, {...})`
## troca o cartão anterior e devolve este. Os botões fecham o CanvasLayer pelos callbacks de quem usa.
##
## Opções de `open`: title, ribbon (Color), icon (Texture2D), icon_px (64), rays (true com ícone),
## hero (Control no lugar do ícone), scroll_name, separation (12), confetti (false),
## haptic ("" | "big" | "success"), animate (true; false = cartão reaberto sem repetir a entrada),
## fixed_body (false; true mantém o corpo fixo e reserva a rolagem para add_scroll_area).

const WIDTH := 320
const INNER := 292  # largura útil do corpo (cartão 320 − margens 14)
const RAYS_PATH := "res://assets/sprites/ui/fx/rays.png"
const RAYS_PX := 128
const RAYS_DEGREES_PER_SECOND := 20.0
const CONFETTI_COUNT := 40

static var _confetti_texture: ImageTexture

var panel: PanelContainer
var scroll: ScrollContainer
var box: VBoxContainer
var dim: ColorRect
var ribbon: PanelContainer
var stage: Control
var icon_node: TextureRect
var rays: TextureRect
var confetti: CPUParticles2D
var _want_confetti := false
var _animate := true
var _fixed_body := false
var _scroll_content: Control


## Troca o cartão que estiver em `host` por um novo, já com fita, ícone e raios.
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


func _build(options: Dictionary) -> void:
	dim = ColorRect.new()
	dim.name = "Dim"
	dim.color = Palette.SCRIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = PanelContainer.new()
	panel.name = "CardPanel"
	panel.theme = load("res://assets/theme/main_theme.tres")
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.custom_minimum_size.x = WIDTH
	center.add_child(panel)
	scroll = ScrollContainer.new()
	scroll.name = str(options.get("scroll_name", "ModalScroll"))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	_fixed_body = bool(options.get("fixed_body", false))
	if not _fixed_body:
		panel.add_child(scroll)
	box = UiKit.vbox(int(options.get("separation", 12)))
	box.custom_minimum_size.x = INNER
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _fixed_body:
		panel.add_child(box)
	else:
		scroll.add_child(box)
	var title := str(options.get("title", ""))
	if title != "":
		box.add_child(_ribbon(title, options.get("ribbon", Palette.HONEY) as Color, str(options.get("ribbon_icon", ""))))
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


static func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PAPER
	style.set_corner_radius_all(28)
	style.set_border_width_all(3)
	style.border_color = Palette.LINE
	style.set_content_margin_all(14)
	style.shadow_color = Palette.SHADOW
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	return style


## Pílula colorida no topo (verde = concluído, mel = crescimento/prêmio, azul = descoberta)
## com o título em StrongLabel branco e um ícone opcional (`ribbon_icon`, nome ctl).
func _ribbon(title: String, color: Color, icon_name: String = "") -> Control:
	ribbon = PanelContainer.new()
	ribbon.name = "Ribbon"
	var style := UiKit.surface(color, 20)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	ribbon.add_theme_stylebox_override("panel", style)
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row := UiKit.hbox(6)
	if icon_name != "":
		row.add_child(UiKit.ctl(icon_name, 20, Palette.CARD))
	var label := UiKit.short_label(title, &"StrongLabel", Palette.CARD)
	label.name = "RibbonTitle"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(label)
	ribbon.add_child(row)
	return ribbon


## Ícone grande (64–96) com os raios girando devagar atrás.
func _stage(texture: Texture2D, icon_px: int, with_rays: bool) -> Control:
	stage = Control.new()
	stage.name = "Stage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var height := RAYS_PX if with_rays else icon_px + 8
	stage.custom_minimum_size = Vector2(INNER, height)
	if with_rays and ResourceLoader.exists(RAYS_PATH):
		rays = TextureRect.new()
		rays.name = "Rays"
		rays.texture = load(RAYS_PATH)
		rays.size = Vector2(RAYS_PX, RAYS_PX)
		rays.position = Vector2((INNER - RAYS_PX) / 2.0, 0)
		rays.pivot_offset = rays.size / 2.0
		rays.modulate.a = 0.35
		rays.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rays.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(rays)
	icon_node = UiKit.icon(texture, icon_px)
	icon_node.name = "BigIcon"
	icon_node.size = Vector2(icon_px, icon_px)
	icon_node.position = Vector2((INNER - icon_px) / 2.0, (height - icon_px) / 2.0)
	icon_node.pivot_offset = icon_node.size / 2.0
	icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	var frame_height := panel.get_theme_stylebox("panel").get_minimum_size().y
	if _fixed_body and is_instance_valid(_scroll_content):
		# Só a grade cede altura: fita, herói e ações nunca entram na rolagem.
		var fixed_height := box.get_combined_minimum_size().y - scroll.custom_minimum_size.y
		var available := get_viewport().get_visible_rect().size.y - 32.0 - frame_height - fixed_height
		var height := minf(_scroll_content.get_combined_minimum_size().y, maxf(0.0, available))
		if not is_equal_approx(scroll.custom_minimum_size.y, height):
			scroll.custom_minimum_size.y = height
	var content_height := box.get_combined_minimum_size().y + frame_height
	panel.custom_minimum_size.y = minf(content_height, maxf(0.0, get_viewport().get_visible_rect().size.y - 32.0))


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


## Texto centralizado no corpo.
func add_text(text: String, variation: StringName = &"", color: Variant = null) -> Label:
	var label := UiKit.label(text, variation, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(label)
	return label


## Chips de prêmio centralizados; entram um por um e os números contam.
func add_chips(chips: Container) -> Container:
	if chips.get_child_count() == 0:
		chips.queue_free()
		return chips
	if chips is FlowContainer:
		(chips as FlowContainer).alignment = FlowContainer.ALIGNMENT_CENTER
	for chip: Node in chips.get_children():
		RewardSheet.grow_chip(chip as Control)
	box.add_child(chips)
	reveal(chips)
	return chips


## O botão principal do cartão (um só).
func add_primary(text: String, on_pressed: Callable) -> Button:
	var button := UiKit.primary(text, on_pressed)
	box.add_child(button)
	return button


## Ação fraca embaixo ("Continuar").
func add_ghost(text: String, on_pressed: Callable) -> Button:
	var button := UiKit.ghost(text, on_pressed)
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
