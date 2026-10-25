class_name WorldBalloon
extends Node2D
## Balão compartilhado. O retângulo de toque usa o espaço do pai e acompanha a escala.

const DIAMETER := 44.0
var state: String = "progress"
var texture: Texture2D
var progress: float = 0.0
var caption: String = ""
var show_caption := false
var corner_texture: Texture2D
var anchor := Vector2(0, -48)
var room_zoom := 1.0
var draw_offset := Vector2.ZERO
var hit_rect: Rect2:
	get:
		return Rect2((anchor + draw_offset + Vector2(-22, -22 + _bob.position.y)) * scale, Vector2(44, 72 if show_caption and caption != "" else 52) * scale)
## Só o balão escolhido pela sala pula (orçamento de atenção); avulso, pula como sempre.
var bounces := true:
	set(value):
		bounces = value
		_wake()
## Quando ficou pronto (ms): o mais antigo é o que a sala escolhe para pular.
var ready_since := 0
var _elapsed := 0.0
var _bob := Node2D.new()
var _check: Texture2D
var _font: Font
var _signature: Array = []
var _last_bob := Vector2.ZERO
static var _legend_box: StyleBox


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_to_group("world_balloons")
	add_child(_bob)
	_check = UiKit.ctl_icon("check")
	_font = load("res://assets/theme/main_theme.tres").default_font
	refresh()


## Só redesenha quando algo visível mudou (o anel muda em passos de 1/48).
func refresh() -> void:
	var ready := state == "ready"
	if ready and ready_since == 0: ready_since = Time.get_ticks_msec()
	elif not ready: ready_since = 0
	var signature: Array = [state, texture, roundi(progress * 48.0), caption, show_caption, corner_texture, anchor, draw_offset, room_zoom]
	if signature != _signature:
		_signature = signature
		queue_redraw()
	_wake()


## Acompanha o zoom sem tamanho mínimo nem afastamento: a âncora fica presa ao mapa.
## Compensa só a escala própria do móvel (animais, canteiros etc.).
func set_zoom(value: float) -> void:
	room_zoom = maxf(value, 0.01)
	var parent_scale: Vector2 = (get_parent() as Node2D).global_scale.abs() if get_parent() is Node2D else Vector2.ONE * room_zoom
	scale = Vector2.ONE * room_zoom / parent_scale
	refresh()


## Só gira o `_process` quando há pulinho a disparar ou a acompanhar.
func _needs_tick() -> bool:
	return state == "spark" or (state == "ready" and bounces) or _bob.position != _last_bob or _bob.position != Vector2.ZERO


func _wake() -> void:
	if is_inside_tree(): set_process(_needs_tick())


func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_elapsed += delta
	if state in ["ready", "spark"] and (bounces or state == "spark") and not Motion.reduced and _elapsed >= (2.0 if state == "spark" else Motion.WORLD_BOUNCE):
		_elapsed = 0.0
		Motion.bounce(_bob)
	if _bob.position != _last_bob:
		_last_bob = _bob.position
		queue_redraw()
	if not _needs_tick(): set_process(false)


func _draw() -> void:
	if _font == null: return
	var center := anchor + draw_offset + _bob.position
	if state == "alert":
		draw_circle(center, 6, Palette.ALERT)
		return
	if state == "spark":
		draw_circle(center + Vector2(0, 2), 13, Palette.SHADOW)
		draw_circle(center, 13, Palette.HONEY)
		draw_texture_rect(UiKit.ctl_icon("spark"), Rect2(center - Vector2(9, 9), Vector2(18, 18)), false, Palette.CARD)
		return
	var ready := state == "ready"
	draw_circle(center + Vector2(0, 2), 22, Palette.SHADOW)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-7, 17), center + Vector2(0, 29), center + Vector2(7, 17)]), Palette.HONEY if state == "buy" else Palette.CARD)
	draw_circle(center, 22, Palette.HONEY if state == "buy" else Color(Palette.CARD, 0.95))
	if state == "queued":
		for i: int in 12:
			var start := TAU * i / 12.0 - PI / 2
			draw_arc(center, 20, start, start + TAU / 18, 6, Palette.SKY, 4, true)
	elif state in ["progress", "ready"]:
		draw_arc(center, 20, -PI / 2, TAU - PI / 2, 48, Palette.GO if ready else Palette.SUNKEN, 4, true)
		if not ready and progress > 0:
			draw_arc(center, 20, -PI / 2, TAU * clampf(progress, 0, 1) - PI / 2, 48, Palette.SKY, 4, true)
	if texture and state != "buy":
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		draw_texture_rect(texture, Rect2(center - Vector2(16, 16), Vector2(32, 32)), false, Color(Palette.CARD, 0.6) if state == "queued" else Color.WHITE)
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if state == "buy":
		draw_texture_rect(corner_texture if corner_texture != null else UiKit.ctl_icon("plus"), Rect2(center - Vector2(12, 12), Vector2(24, 24)), false, Palette.CARD)
	var corner := _check if ready else (null if state == "buy" else corner_texture)
	if corner:
		draw_circle(center + Vector2(17, 15), 11, Palette.CARD)
		draw_circle(center + Vector2(17, 15), 9, Palette.GO if ready else Palette.SUNKEN)
		draw_texture_rect(corner, Rect2(center + Vector2(9, 7), Vector2(16, 16)), false, Palette.CARD)
	if show_caption and caption != "":
		var width := _font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 16
		if _legend_box == null: _legend_box = UiKit.surface(Palette.CARD, 12, true)
		draw_style_box(_legend_box, Rect2(center + Vector2(-width / 2, 28), Vector2(width, 24)))
		_text(caption, center + Vector2(0, 44), 12, Palette.INK)


func _text(value: String, baseline: Vector2, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_font, baseline - Vector2(width / 2, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
