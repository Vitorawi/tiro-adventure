class_name SlotDot
extends VBoxContainer
## Espaço de produção compacto: bolinha de 52 px + legenda de uma linha (~76 px de altura).
## Estados: vazio (círculo tracejado), na fila (ícone apagado), produzindo (anel de tempo),
## pronto (anel cheio verde + check, pulsando), comprar ("+" e preço) e nível (cadeado).
## Peça só de desenho: o toque (quando houver) é ligado por quem usa, no próprio SlotDot.

const EMPTY := "empty"
const QUEUED := "queued"
const BUSY := "busy"
const READY := "ready"
const BUY := "buy"
const LEVEL := "level"

const DOT := 52.0

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
			ring.thickness = 4.0
			ring.custom_minimum_size = Vector2(DOT, DOT)
			ring.progress = 1.0 if state == READY else progress
			ring.size = Vector2(DOT, DOT)
			_dot.add_child(ring)
			_add_icon(texture, 1.0)
			if state == READY:
				var check_disc := PanelContainer.new()
				check_disc.name = "CheckDisc"
				check_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
				check_disc.add_theme_stylebox_override("panel", UiKit.surface(Palette.GO, 11))
				check_disc.size = Vector2(22, 22)
				check_disc.position = Vector2(DOT - 20.0, -2.0)
				var check := UiKit.ctl("check", 16, Palette.CARD)
				check.name = "Check"
				check_disc.add_child(check)
				_dot.add_child(check_disc)
				_pulse = not Motion.reduced
		QUEUED:
			_add_icon(texture, 0.6)
		EMPTY:
			var plus := UiKit.ctl("plus", 20, Palette.INK_FAINT)
			plus.name = "Plus"
			plus.position = Vector2((DOT - 20) / 2, (DOT - 20) / 2)
			_dot.add_child(plus)
		BUY, LEVEL:
			var lock := UiKit.lock_icon(20)
			lock.position = Vector2((DOT - 20) / 2, (DOT - 20) / 2)
			if state == BUY:
				var legacy_plus := Control.new()
				legacy_plus.name = "Plus"
				legacy_plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
				legacy_plus.add_child(lock)
				_dot.add_child(legacy_plus)
			else:
				_dot.add_child(lock)
	_add_caption(caption, Palette.SKY_INK if state == BUSY else caption_color, caption_icon)
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
	if state == BUY:
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var style := UiKit.surface(Palette.SUNKEN, 11)
		style.content_margin_left = 4
		style.content_margin_right = 4
		chip.add_theme_stylebox_override("panel", style)
		chip.add_child(row)
		add_child(chip)
	else:
		add_child(row)


func _draw_dot() -> void:
	var center := Vector2(DOT, DOT) / 2.0
	match state:
		EMPTY, QUEUED:
			# 12 arcos curtos formam o círculo tracejado.
			for i in 12:
				var start := TAU * i / 12.0
				_dot.draw_arc(center, DOT / 2.0 - 2.0, start, start + TAU / 24.0 * 1.4, 6, Palette.SKY if state == QUEUED else Palette.INK_FAINT, 2.0, true)
		BUY, LEVEL:
			_dot.draw_circle(center, DOT / 2.0 - 1.0, Palette.SUNKEN)


func _process(_delta: float) -> void:
	# Pulsar 1,00 ↔ 1,04 preso ao relógio (não reinicia quando o painel se reconstrói a cada segundo).
	var phase := sin(float(Time.get_ticks_msec()) / 1000.0 * TAU / Motion.PULSE) * 0.5 + 0.5
	_dot.pivot_offset = Vector2(DOT, DOT) / 2.0
	_dot.scale = Vector2.ONE * (1.0 + 0.04 * phase)
