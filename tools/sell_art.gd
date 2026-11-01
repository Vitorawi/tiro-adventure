extends SceneTree
## Gera as peças da tela de venda "madeira ilustrada" em game/assets/sprites/ui/home/ (prefixo sell_) a partir de
## IUREF/venda-v2/venda-v2_<n>.png. Cada peça sai com ~3x o tamanho de exibição (o jogo desenha os NinePatch em escala 1/3).
##  _1  moldura entalhada: os cartões e a barra de rolagem desenhados dentro dela são apagados (o miolo vira um degradê
##      liso, igual nas linhas, para o NinePatch esticar na vertical sem emendas) -> sell_frame.png
##  _3  cartão creme vazio -> sell_card.png
##  _5  caixinha creme com a moeda (total da venda) -> sell_total.png
##  _18 pegador da barra de rolagem -> sell_thumb.png
## A tábua usa station_board.png (a _2 traz −/N/+ e botão desenhados dentro); os botões usam station_*/step_go.
## Uso: godot --headless --path game -s ../tools/sell_art.gd   (depois: --import e mipmaps/generate=true nos sell_*.png.import)

const OUT := "res://assets/sprites/ui/home/"
const SRC := "res://../IUREF/venda-v2/venda-v2_%d.png"
## Escala da moldura (o jogo mostra a 1/3 disso): 1087 px -> 913 px guardados.
const FRAME_SCALE := 0.84


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SRC % n))
	if image == null:
		push_error("faltou %d" % n)
		quit(1)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, file: String, width: int, height: int = 0) -> void:
	var h := height if height > 0 else int(round(float(image.get_height()) * width / image.get_width()))
	if image.get_width() != width or image.get_height() != h:
		image.resize(width, h, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path(OUT + file))
	print("%s %dx%d" % [file, image.get_width(), image.get_height()])


func _init() -> void:
	# Moldura: apaga os 12 cartões (x 150..932, y 228..1462) e a barra de rolagem (x 941..978, y 255..1405) desenhados.
	# A cor de cada linha vai da amostra à esquerda (x 135) à da direita (x 938): a linha fica contínua e os cantos ficam intactos.
	var frame := _src(1)
	for y in range(228, 1463):
		var left := frame.get_pixel(135, y)
		var right := frame.get_pixel(938, y)
		for x in range(150, 933):
			frame.set_pixel(x, y, left.lerp(right, clampf(float(x - 135) / (938.0 - 135.0), 0.0, 1.0)))
		if y >= 255 and y <= 1405:
			for x in range(941, 979):
				frame.set_pixel(x, y, right)
	_save(frame, "sell_frame.png", int(round(1087.0 * FRAME_SCALE)))
	_save(_src(3), "sell_card.png", 395)
	_save(_src(5), "sell_total.png", 312)
	_save(_src(18), "sell_thumb.png", 30)
	quit()
