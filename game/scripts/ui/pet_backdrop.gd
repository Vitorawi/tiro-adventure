class_name PetBackdrop
extends Control
## Fundo da tela do Tiro: o quarto ilustrado (`home_room.png`) cobrindo a tela inteira (corte centralizado, sem
## esticar). O Tiro continua em pixel por cima; `pet_feet()` é o ponto onde as patinhas pisam no chão do quarto.
## No protótipo (360×780) o Tiro é desenhado em escala 2 com as patas em y = 600 → o quadro 336×284 vira 512×432
## (`ZOOM`), e `pet_feet().y` fica 20 px acima das patas reais porque o código assume 0,81 da altura do quadro.

const ZOOM := 1.5238
const FOCUS_X := 180.0
const FEET_Y := 0.7436
var texture: Texture2D = preload("res://assets/sprites/ui/home/home_room.png")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(queue_redraw)
	queue_redraw()


func pet_feet() -> Vector2:
	return Vector2(size.x * 0.5, size.y * FEET_Y)


## Retângulo do quarto na tela (a imagem cobre `size`; o que passa das bordas é cortado).
func scene_rect() -> Rect2:
	var image := texture.get_size()
	var factor := maxf(size.x / image.x, size.y / image.y)
	var shown := image * factor
	return Rect2((size - shown) / 2.0, shown)


func _draw() -> void:
	draw_texture_rect(texture, scene_rect(), false)
