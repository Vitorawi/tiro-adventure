class_name SlotDot
extends VBoxContainer
## Espaço de produção compacto: bolinha de 56 px + legenda de uma linha (~76 px de altura).
## Estados: vazio (círculo tracejado), na fila (ícone apagado), produzindo (anel de tempo),
## pronto (anel cheio verde + check, pulsando), comprar ("+" e preço) e nível (cadeado).
## Peça só de desenho: o toque (quando houver) é ligado por quem usa, no próprio SlotDot.

const EMPTY := "empty"
const QUEUED := "queued"
const BUSY := "busy"
const READY := "ready"
const BUY := "buy"
const LEVEL := "level"

const DOT := 56.0

var state := EMPTY
## Ícone do produto (para dar nome ao nó em quem precisa achá-lo).
var icon_rect: TextureRect
var _dot: Control
var _pulse := false


func _init(new_state: String = EMPTY, texture: Texture2D = null, progress: float = 0.0, caption: String = "", caption_color: Variant = null, caption_icon: Texture2D = null) -> void:
	state = new_state
	mouse_filter = Control.MOUSE_FILTER_PASS  # deixa rolar arrastando em cima do espaço
	add_theme_constant_override("separation", 2)
	_dot = Control.new()
	_dot.name = "Dot"
	_dot.custom_minimum_size = Vector2(DOT, DOT)
	_dot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.draw.connect(_draw_dot)
	add_child(_dot)
	match state:
		BUSY, READY:
			var ring := RingProgress.new()
			ring.name = "Ring"
			ring.thickness = 5.0
			ring.progress = 1.0 if state == READY else progress
			ring.size = Vector2(DOT, DOT)
			_dot.add_child(ring)
			_add_icon(texture, 1.0)
			if state == READY:
				var check := UiKit.icon(UiKit.ctl_icon("check"), 16)
				check.name = "Check"
				check.position = Vector2(DOT - 18.0, 0.0)
				_dot.add_child(check)
				_pulse = not Motion.reduced
		QUEUED:
			_add_icon(texture, 0.6)
		BUY:
			var plus := UiKit.label("+", &"TitleLabel", UiKit.GOOD if progress >= 1.0 else Palette.INK_SOFT)
			plus.name = "Plus"
			plus.add_theme_font_size_override("font_size", 40)
			plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			plus.size = Vector2(DOT, DOT)
			plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_dot.add_child(plus)
		LEVEL:
			var lock := UiKit.lock_icon()
			lock.position = Vector2((DOT - 32.0) / 2.0, (DOT - 32.0) / 2.0)
			_dot.add_child(lock)
	_add_caption(caption, caption_color, caption_icon)
	set_process(_pulse)


func _add_icon(texture: Texture2D, alpha: float) -> void:
	icon_rect = UiKit.icon(texture, 32)
	icon_rect.name = "Icon"
	icon_rect.position = Vector2((DOT - 32.0) / 2.0, (DOT - 32.0) / 2.0)
	icon_rect.size = Vector2(32, 32)
	icon_rect.modulate.a = alpha
	_dot.add_child(icon_rect)


## Legenda de uma linha; sem texto nem ícone ela nem existe (fileira só de espaços vazios fica mais baixa).
func _add_caption(caption: String, color: Variant, icon: Texture2D) -> void:
	if caption == "" and icon == null:
		return
	var row := UiKit.hbox(2)
	row.name = "Caption"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(0, 22)
	if icon:
		row.add_child(UiKit.icon(icon, 16))
	var text := UiKit.short_label(caption, &"SmallLabel", color)
	row.add_child(text)
	add_child(row)


func _draw_dot() -> void:
	var center := Vector2(DOT, DOT) / 2.0
	match state:
		EMPTY:
			# 12 arcos curtos formam o círculo tracejado.
			for i in 12:
				var start := TAU * i / 12.0
				_dot.draw_arc(center, DOT / 2.0 - 2.0, start, start + TAU / 24.0 * 1.4, 6, Palette.CARD_LINE, 3.0, true)
		QUEUED, BUY, LEVEL:
			_dot.draw_circle(center, DOT / 2.0 - 1.0, Palette.SUNKEN)


func _process(_delta: float) -> void:
	# Pulsar 1,00 ↔ 1,04 preso ao relógio (não reinicia quando o painel se reconstrói a cada segundo).
	var phase := sin(float(Time.get_ticks_msec()) / 1000.0 * TAU / Motion.PULSE) * 0.5 + 0.5
	_dot.pivot_offset = Vector2(DOT, DOT) / 2.0
	_dot.scale = Vector2.ONE * (1.0 + 0.04 * phase)
