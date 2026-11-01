extends SceneTree
## Gera as peças da tela de encomendas "madeira ilustrada" em game/assets/sprites/ui/home/ (prefixo delivery_) a partir de
## IUREF/delivery-v1/delivery-v1_<n>.png. A moldura sai ~3x o tamanho de exibição (NinePatch em escala 1/3).
##  _1  moldura com faixa de pergaminho e cipó: a metade esquerda é espelhada para a direita (a madeira original é mais
##      grossa à esquerda: assim o papel fica centrado) -> delivery_frame.png
##  _4  cartão creme liso -> delivery_card.png
##  _10 caixinha creme com a moeda (prêmio no cartão) -> delivery_reward.png
##  _13 botão laranja (Preparar, falta item) -> delivery_orange.png
##  _8  botão verde (Pronto, tem o item) -> delivery_green.png
##  _23 moeda -> delivery_coin.png
## A tábua usa station_board.png; o X usa mission_close.png; o botão Entregar usa step_go.
## Uso: godot --headless --path game -s ../tools/delivery_art.gd   (depois: --import e mipmaps/generate=true nos delivery_*.png.import)

const OUT := "res://assets/sprites/ui/home/"
const SRC := "res://../IUREF/delivery-v1/delivery-v1_%d.png"
const FRAME_WIDTH := 1116  # 372 px de exibição x 3


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SRC % n))
	if image == null:
		push_error("faltou %d" % n)
		quit(1)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, file: String, width: int = 0) -> void:
	if width > 0 and image.get_width() != width:
		var h := int(round(float(image.get_height()) * width / image.get_width()))
		image.resize(width, h, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path(OUT + file))
	print("%s %dx%d" % [file, image.get_width(), image.get_height()])


func _init() -> void:
	var frame := _src(1)
	var w := frame.get_width()
	for y in frame.get_height():
		for x in range(w / 2, w):
			frame.set_pixel(x, y, frame.get_pixel(w - 1 - x, y))
	_save(frame, "delivery_frame.png", FRAME_WIDTH)
	_save(_src(4), "delivery_card.png")
	_save(_src(10), "delivery_reward.png")
	_save(_src(13), "delivery_orange.png")
	_save(_src(8), "delivery_green.png")
	_save(_src(23), "delivery_coin.png", 96)
	var board := _src(2)
	for point: Vector2i in [Vector2i(300, 70), Vector2i(150, 250), Vector2i(850, 150), Vector2i(850, 330), Vector2i(60, 250), Vector2i(48, 52)]:
		var c := board.get_pixelv(point)
		print("board ", point, " ", c.to_html(false))
	quit()
