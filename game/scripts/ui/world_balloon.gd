class_name WorldBalloon
extends Node2D
## Balão compartilhado. O retângulo de toque usa o espaço do pai e acompanha a escala.

const DIAMETER := 44.0
## Menor tamanho de tela: afastado, o balão encolhe junto com o mapa para continuar colado no que aponta.
const MIN_SCREEN_SCALE := 0.5
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
var _elapsed := 0.0
var _bob := Node2D.new()
var _check: Texture2D
var _font: Font


func _ready() -> void:
	add_to_group("world_balloons")
	add_child(_bob)
	_check = UiKit.ui_icon("ui_check")
	_font = load("res://assets/theme/main_theme.tres").default_font
	refresh()


func refresh() -> void:
	queue_redraw()


## Limita o tamanho FINAL de tela, compensando também a escala do móvel.
func set_zoom(value: float) -> void:
	room_zoom = maxf(value, 0.01)
	var parent_scale: Vector2 = (get_parent() as Node2D).global_scale.abs() if get_parent() is Node2D else Vector2.ONE * room_zoom
	var screen_factor := clampf(room_zoom, MIN_SCREEN_SCALE, 1.25)
	scale = Vector2.ONE * screen_factor / parent_scale
	refresh()


func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_elapsed += delta
	if state == "ready" and _elapsed >= Motion.WORLD_BOUNCE:
		_elapsed = 0.0
		Motion.bounce(_bob)
	queue_redraw()


func _draw() -> void:
	if _font == null: return
	var center := anchor + draw_offset + _bob.position
	var ready := state == "ready"
	var fill := Palette.PRIMARY.lightened(0.22) if ready else Palette.ACCENT if state == "buy" else Palette.PAPER
	var edge := Palette.PRIMARY_EDGE if ready else Palette.ACCENT_EDGE if state == "buy" else Palette.CARD_LINE
	draw_colored_polygon(PackedVector2Array([center + Vector2(-7, 17), center + Vector2(0, 29), center + Vector2(7, 17)]), edge)
	draw_circle(center, 22, edge)
	draw_circle(center, 19 if ready else 20, fill)
	if state in ["progress", "queued"]:
		draw_arc(center, 19, -PI / 2, TAU - PI / 2, 48, Palette.SUNKEN, 4, true)
		if progress > 0:
			draw_arc(center, 19, -PI / 2, TAU * clampf(progress, 0, 1) - PI / 2, 48, Palette.INFO, 4, true)
	if texture:
		draw_texture_rect(texture, Rect2(center - Vector2(16, 16), Vector2(32, 32)), false, Color(1, 1, 1, 0.6) if state == "queued" else Color.WHITE)
	if state == "buy" or state == "alert":
		_text("+" if state == "buy" else "!", center + Vector2(0, 8), 24, Palette.INK if state == "buy" else Palette.DANGER)
	var corner := _check if ready else corner_texture
	if corner:
		draw_circle(center + Vector2(17, 15), 10, Palette.PAPER)
		draw_texture_rect(corner, Rect2(center + Vector2(9, 7), Vector2(16, 16)), false)
	if show_caption and caption != "":
		var width := _font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 12
		var box := StyleBoxFlat.new()
		box.bg_color = Palette.HUD
		box.set_corner_radius_all(10)
		draw_style_box(box, Rect2(center + Vector2(-width / 2, 28), Vector2(width, 22)))
		_text(caption, center + Vector2(0, 45), 18, Palette.INK_ON_DARK)


func _text(value: String, baseline: Vector2, font_size: int, color: Color) -> void:
	var width := _font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(_font, baseline - Vector2(width / 2, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
