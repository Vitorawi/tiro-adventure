class_name PetBackdrop
extends Control
## A arte original ocupa a largura inteira, sem esticar os pixels na vertical.
## O recorte tira só a moldura vazia; parede e piso continuam até as bordas da tela.

const SOURCE := Rect2(36, 72, 289, 277)
const ZOOM := 1.75
const FOCUS_X := 168.0
const RUG := Vector2(0.39, 0.8)
var texture: Texture2D = preload("res://assets/sprites/areas/pet/corner.png")
var _wall := Palette.PAPER
var _floor := Palette.SUNKEN


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pixels := texture.get_image()
	_wall = pixels.get_pixel(204, 82)
	_floor = pixels.get_pixel(180, 341)
	resized.connect(queue_redraw)
	queue_redraw()


func pet_feet() -> Vector2:
	return Vector2(size.x * FOCUS_X / 360.0, size.y * 0.71)


func scene_rect() -> Rect2:
	var width := size.x * ZOOM
	var height := width * SOURCE.size.y / SOURCE.size.x
	return Rect2(Vector2(pet_feet().x - width * RUG.x, pet_feet().y - height * RUG.y), Vector2(width, height))


func _draw() -> void:
	var room := scene_rect()
	draw_rect(Rect2(Vector2.ZERO, size), _wall)
	draw_rect(Rect2(0, room.end.y, size.x, maxf(0, size.y - room.end.y)), _floor)
	draw_texture_rect_region(texture, room, SOURCE)
	# Continua a última tábua; o piso já chega aos cantos e aparece atrás da faixa flutuante.
	if room.end.y < size.y:
		draw_texture_rect_region(texture, Rect2(0, room.end.y, size.x, size.y - room.end.y), Rect2(36, 336, 289, 12))
