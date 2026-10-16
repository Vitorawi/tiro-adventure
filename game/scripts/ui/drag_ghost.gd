class_name DragGhost
extends RefCounted
## Gesto e ficha compartilhados pelas bandejas do mundo e pelos cuidados do Tiro.
## A ponta da ficha fica 40 px acima do dedo; coordenadas sempre globais.

const SLOP := 12.0
const PX := 56.0
const LIFT := 40.0
var start := Vector2.ZERO
var finger := Vector2.ZERO
var previous := Vector2.ZERO
var velocity := Vector2.ZERO
var token: Control
var _time := 0


func press(point: Vector2) -> void:
	start = point
	finger = point
	previous = point
	velocity = Vector2.ZERO
	_time = Time.get_ticks_msec()


func move(point: Vector2) -> bool:
	previous = finger
	# Alguns celulares repetem a posição do mesmo dedo; não apaga a velocidade do arremesso.
	if point.is_equal_approx(finger):
		return finger.distance_to(start) > SLOP
	var now := Time.get_ticks_msec()
	velocity = (point - finger) / maxf(float(now - _time) / 1000.0, 0.001)
	_time = now
	finger = point
	return finger.distance_to(start) > SLOP


func release_velocity() -> Vector2:
	return velocity if Time.get_ticks_msec() - _time < 180 else Vector2.ZERO


func target() -> Vector2:
	return finger - Vector2(0, LIFT)


func begin(host: Control, texture: Texture2D) -> Control:
	token = make_token(texture)
	token.name = "Ghost"
	host.add_child(token)
	Motion.pop_in(token)
	follow(host)
	return token


func follow(host: Control) -> void:
	if is_instance_valid(token):
		token.global_position = finger - Vector2(PX / 2.0, PX + LIFT)


func finish() -> void:
	if is_instance_valid(token):
		Motion.pop_out(token)
	token = null


static func make_token(texture: Texture2D) -> Control:
	var result := Panel.new()
	result.size = Vector2(PX, PX)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PAPER
	style.set_corner_radius_all(int(PX / 2.0))
	style.set_border_width_all(2)
	style.border_color = Palette.CARD_LINE
	style.shadow_color = Palette.SHADE
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	result.add_theme_stylebox_override("panel", style)
	var icon := UiKit.icon(texture, 48)
	icon.position = Vector2(4, 4)
	icon.size = Vector2(48, 48)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	result.add_child(icon)
	return result
