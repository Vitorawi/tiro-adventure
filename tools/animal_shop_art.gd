extends SceneTree
## Gera as peças da loja de animais "madeira ilustrada" em game/assets/sprites/ui/home/ (prefixo animalshop_) a partir de
## IUREF/buy animal-v1/buy animal-v1_<n>.png. Cada peça sai com ~3x o tamanho de exibição (o jogo desenha os NinePatch a 1/3).
##  _1  moldura com a plaquinha, fitas, laços, flores, pata e a barra de capacidade -> animalshop_frame.png (372 px x 3, sem
##      esticar em largura no tamanho máximo)
##  _3  tábua com as casinhas e o ninho, remontada em 372 de largura: casinhas nas pontas e miolo liso -> animalshop_board.png
##  _5  botão laranja (Ver meus animais) -> animalshop_button.png
## O cartão creme é o `sell_card.png`; o disco do animal e a pílula de preço são desenhados em código.
## Também imprime as medidas (em px de exibição) da plaquinha e da barra, que viram constantes do `AnimalShopUi`.
## Uso: godot --headless --path game -s ../tools/animal_shop_art.gd   (depois: --import e mipmaps/generate=true nos animalshop_*.png.import)

const OUT := "res://assets/sprites/ui/home/"
const SRC := "res://../IUREF/buy animal-v1/buy animal-v1_%d.png"
const FRAME_WIDTH := 1116   # 372 de exibição x 3
const BOARD_WIDTH := 1116   # 372 de exibição x 3: tábua larga como a moldura
const BOARD_SCALE := 0.68   # tamanho das casinhas em relação ao original (px de origem -> px guardados)
const BUTTON_HEIGHT := 132  # 44 x 3


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


## Região contínua (cor parecida) a partir de um ponto: devolve o retângulo dela.
func _region(image: Image, start: Vector2i, tolerance: float) -> Rect2i:
	var base := image.get_pixelv(start)
	var seen := {}
	var stack: Array[Vector2i] = [start]
	var box := Rect2i(start, Vector2i.ONE)
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= image.get_width() or p.y >= image.get_height() or seen.has(p):
			continue
		var c := image.get_pixelv(p)
		if c.a < 0.5 or absf(c.r - base.r) + absf(c.g - base.g) + absf(c.b - base.b) > tolerance:
			continue
		seen[p] = true
		box = box.expand(p)
		stack.append(p + Vector2i(1, 0))
		stack.append(p + Vector2i(-1, 0))
		stack.append(p + Vector2i(0, 1))
		stack.append(p + Vector2i(0, -1))
	return box


func _init() -> void:
	var frame := _src(1)
	var k := float(FRAME_WIDTH) / frame.get_width() / 3.0  # px de origem -> px de exibição
	var plaque := _region(frame, Vector2i(460, 140), 0.12)
	var lane := _region(frame, Vector2i(400, 298), 0.10)
	print("frame origem ", frame.get_size(), " fator exibição ", k)
	print("plaquinha (origem) ", plaque, " -> exibição x %.1f..%.1f y %.1f..%.1f" % [plaque.position.x * k, plaque.end.x * k, plaque.position.y * k, plaque.end.y * k])
	print("barra (origem) ", lane, " -> exibição x %.1f..%.1f y %.1f..%.1f" % [lane.position.x * k, lane.end.x * k, lane.position.y * k, lane.end.y * k])
	print("cor da barra ", frame.get_pixelv(Vector2i(400, 298)).to_html(false), " papel ", frame.get_pixelv(Vector2i(450, 600)).to_html(false))
	print("disco/cartão _4 ", _src(4).get_pixelv(Vector2i(60, 150)).to_html(false))
	_save(frame, "animalshop_frame.png", FRAME_WIDTH)
	# Tábua: o miolo liso de _3 abre espaço entre as casinhas (blocos laterais iguais, 312 px cada) para o botão laranja.
	var board := _src(3)
	var scale := BOARD_SCALE
	var height := int(round(board.get_height() * scale))
	var left := board.get_region(Rect2i(0, 0, 450, board.get_height()))
	left.resize(int(round(450 * scale)), height, Image.INTERPOLATE_LANCZOS)
	var right := board.get_region(Rect2i(636, 0, board.get_width() - 636, board.get_height()))
	right.resize(int(round((board.get_width() - 636) * scale)), height, Image.INTERPOLATE_LANCZOS)
	var middle := board.get_region(Rect2i(450, 0, 186, board.get_height()))
	middle.resize(BOARD_WIDTH - left.get_width() - right.get_width(), height, Image.INTERPOLATE_LANCZOS)
	var canvas := Image.create(BOARD_WIDTH, height, false, Image.FORMAT_RGBA8)
	canvas.blit_rect(middle, Rect2i(Vector2i.ZERO, middle.get_size()), Vector2i(left.get_width(), 0))
	canvas.blit_rect(left, Rect2i(Vector2i.ZERO, left.get_size()), Vector2i.ZERO)
	canvas.blit_rect(right, Rect2i(Vector2i.ZERO, right.get_size()), Vector2i(BOARD_WIDTH - right.get_width(), 0))
	_save(canvas, "animalshop_board.png", BOARD_WIDTH, height)
	print("tábua: casinha da esquerda termina em %.1f e a da direita começa em %.1f (exibição, da borda de cada lado)" % [440 * scale / 3.0, (board.get_width() - 645) * scale / 3.0])
	var button := _src(5)
	_save(button, "animalshop_button.png", int(round(float(button.get_width()) * BUTTON_HEIGHT / button.get_height())), BUTTON_HEIGHT)
	quit()
