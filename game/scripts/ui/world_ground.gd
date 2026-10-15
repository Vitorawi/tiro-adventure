class_name WorldGround
extends Control
## Gramado contínuo: a textura se repete nas coordenadas do mundo, inclusive na cobertura da terra.

var texture: ImageTexture
var camera_origin := Vector2.ZERO
var camera_zoom := 1.0


func configure(source: Texture2D, ground: Color, strength: float = 0.45) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var average := 0.0
	for y in image.get_height():
		for x in image.get_width():
			average += image.get_pixel(x, y).v
	average /= image.get_width() * image.get_height()
	# Mantém o desenho da grama, mas casa a cor média com o chão de cada mapa.
	for y in image.get_height():
		for x in image.get_width():
			var delta := (image.get_pixel(x, y).v - average) * strength
			var color := ground.lightened(delta) if delta >= 0.0 else ground.darkened(-delta)
			image.set_pixel(x, y, color)
	texture = ImageTexture.create_from_image(image)
	queue_redraw()


func set_camera(origin: Vector2, zoom: float) -> void:
	camera_origin = origin
	camera_zoom = zoom
	queue_redraw()


func _draw() -> void:
	if texture == null or camera_zoom <= 0.0:
		return
	var tile := texture.get_size()
	var phase := camera_origin / camera_zoom
	var start := Vector2(fposmod(phase.x, tile.x), fposmod(phase.y, tile.y)) - tile
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * camera_zoom)
	draw_texture_rect(texture, Rect2(start, size / camera_zoom + tile * 2.0), true)
