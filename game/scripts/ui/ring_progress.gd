class_name RingProgress
extends Control
## Anel de progresso com ícone no meio (plantação, estação, fila). Sem toque: só desenha.
## Cheio (progress = 1) usa `done_color` (pronto = verde); antes disso, `color` (azul = tempo).

## Progresso de 0 a 1 (valores fora da faixa são cortados).
@export var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()
@export var thickness := 4.0:
	set(value):
		thickness = value
		queue_redraw()
@export var color := Palette.INFO:
	set(value):
		color = value
		queue_redraw()
@export var done_color := Palette.PRIMARY:
	set(value):
		done_color = value
		queue_redraw()
@export var track := Palette.SUNKEN:
	set(value):
		track = value
		queue_redraw()
## Ícone no meio (desenhado em escala inteira quando couber).
var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(56, 56)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	var center := size / 2.0
	var radius := maxf(minf(size.x, size.y) / 2.0 - thickness / 2.0, 1.0)
	draw_arc(center, radius, 0.0, TAU, 48, track, thickness, true)
	if progress > 0.0:
		var arc_color := done_color if progress >= 1.0 else color
		draw_arc(center, radius, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, arc_color, thickness, true)
	if texture:
		# Maior quadrado que cabe dentro do anel; escala sempre um múltiplo inteiro do PNG.
		var room := (radius - thickness / 2.0) * 2.0 / sqrt(2.0)
		var base := texture.get_size()
		var factor := floorf(room / maxf(base.x, base.y))
		var icon_size := base * factor if factor >= 1.0 else base * (room / maxf(base.x, base.y))
		draw_texture_rect(texture, Rect2((center - icon_size / 2.0).round(), icon_size), false)
