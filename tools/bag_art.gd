extends SceneTree
## Gera as peças da Mochila "madeira ilustrada" em game/assets/sprites/ui/home/ (prefixo bag_) a partir das
## pranchas recortadas em IUREF/Mochila-v1 (extraídas de IUREF/Mochila-v1_*.zip). Cada peça sai com ~3x o tamanho
## de exibição (o jogo desenha em escala 1/3, como as da tela inicial).
## Uso: godot --headless --path game -s ../tools/bag_art.gd   (depois: godot --headless --path game --import)

const OUT := "res://assets/sprites/ui/home/"


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://../IUREF/Mochila-v1/Mochila-v1_%d.png" % n))
	if image == null:
		push_error("faltou %d" % n)
		quit(1)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, file: String, width: int, height: int = 0) -> void:
	var h := height if height > 0 else int(round(float(image.get_height()) * width / image.get_width()))
	if image.get_width() != width or image.get_height() != h:
		image.resize(width, h, Image.INTERPOLATE_LANCZOS)
	var path := ProjectSettings.globalize_path(OUT + file)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("%s %dx%d" % [file, image.get_width(), image.get_height()])


## Copia a coluna limpa `from_x` sobre o retângulo `area` (apaga desenhos mantendo o degradê vertical).
func _wipe_cols(image: Image, area: Rect2i, from_x: int) -> void:
	for y in range(area.position.y, area.end.y):
		var c := image.get_pixel(from_x, y)
		for x in range(area.position.x, area.end.x):
			image.set_pixel(x, y, c)


## Copia a linha limpa `from_y` sobre o retângulo `area` (degradê horizontal).
func _wipe_rows(image: Image, area: Rect2i, from_y: int) -> void:
	for x in range(area.position.x, area.end.x):
		var c := image.get_pixel(x, from_y)
		for y in range(area.position.y, area.end.y):
			image.set_pixel(x, y, c)


## Deixa só o retângulo arredondado (some o que estava atrás da tábua: folhas e vigas), com borda suave.
func _round_mask(image: Image, radius: float) -> void:
	var w := float(image.get_width())
	var h := float(image.get_height())
	for y in image.get_height():
		for x in image.get_width():
			var px := float(x) + 0.5
			var py := float(y) + 0.5
			var cx := clampf(px, radius + 1.0, w - radius - 1.0)
			var cy := clampf(py, radius + 1.0, h - radius - 1.0)
			var outside := Vector2(px - cx, py - cy).length() - radius
			if outside > 0.0:
				var c := image.get_pixel(x, y)
				c.a *= clampf(1.0 - outside, 0.0, 1.0)
				image.set_pixel(x, y, c)


## Contorno escuro só fica se encostar numa folha/pétala (senão é a borda do quadro).
func _near_color(image: Image, x: int, y: int) -> bool:
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var px := clampi(x + dx, 0, image.get_width() - 1)
			var py := clampi(y + dy, 0, image.get_height() - 1)
			var c := image.get_pixel(px, py)
			if (c.g > c.r + 0.05 and c.g > c.b and c.g > 0.35) or (x > image.get_width() / 2 and c.r > 0.75 and c.r > c.g + 0.15):
				return true
	return false


func _crop(image: Image, area: Rect2i) -> Image:
	return image.get_region(area)


func _init() -> void:
	# Moldura da tela: o fundo inteiro sem a tábua do meio (os filtros trazem a deles) e sem a tábua de baixo
	# (o rodapé do jogo fica por cima). Emenda o pedaço de cima (0..1170) com o de baixo (1490..2470).
	var full := _src(51)
	var top := _crop(full, Rect2i(0, 0, full.get_width(), 1170))
	var low := _crop(full, Rect2i(0, 1490, full.get_width(), 980))
	var frame := Image.create(full.get_width(), top.get_height() + low.get_height(), false, Image.FORMAT_RGBA8)
	frame.blit_rect(top, Rect2i(Vector2i.ZERO, top.get_size()), Vector2i.ZERO)
	frame.blit_rect(low, Rect2i(Vector2i.ZERO, low.get_size()), Vector2i(0, top.get_height()))
	print("BAG_CREAM = ", full.get_pixel(760, 700).to_html(false))
	_save(frame, "bag_frame.png", 1080)
	# Cartão do depósito (o da geladeira), sem o ícone, o fundo do ícone e a barra: o jogo desenha os seus.
	var sheet := _src(1)
	var card := _crop(sheet, Rect2i(36, 6, 830, 260))
	_wipe_cols(card, Rect2i(40, 30, 750, 200), 275)
	print("BAG_INSET = ", sheet.get_pixel(110, 60).to_html(false))
	_save(card, "bag_depot.png", 498)
	# Tábua dos filtros com folhas, flor e parafusos; o miolo vira madeira lisa (sem o "Tudo" e os ícones).
	var plank := _crop(sheet, Rect2i(0, 508, sheet.get_width(), 244))
	_wipe_cols(plank, Rect2i(116, 84, 1656, 150), 500)
	# Acima da tábua só ficam as folhas e a flor: o resto (pé dos cartões, creme e a borda do quadro) some.
	plank.fill_rect(Rect2i(112, 0, 1628, 76), Color(0, 0, 0, 0))
	for y in range(0, 74):
		for x in range(plank.get_width()):
			var c := plank.get_pixel(x, y)
			var leaf := c.g > c.r and c.g > c.b
			var petal := x > plank.get_width() / 2 and c.r > 0.75 and c.r > c.g + 0.15
			var outline := c.get_luminance() < 0.22 and _near_color(plank, x, y)
			if not (leaf or petal or outline):
				plank.set_pixel(x, y, Color(0, 0, 0, 0))
	_save(plank, "bag_plank.png", int(round(1885.0 * 3 * 66 / 244)), 3 * 66)
	# Pílula creme da categoria escolhida e quadrado do item (cartão das verduras sem o desenho).
	_save(_src(4), "bag_chip.png", 240)
	var tile := _src(5)
	_wipe_cols(tile, Rect2i(26, 24, 236, 180), 22)
	_save(tile, "bag_tile.png", 228)
	# Ícone de cada depósito já com o fundo afundado, recortado do quadro montado (os soltos vieram com riscos).
	for pair: Array in [[Vector2i(70, 30), "fridge"], [Vector2i(922, 30), "chest"], [Vector2i(70, 297), "silo"], [Vector2i(922, 297), "warehouse"]]:
		_save(_crop(sheet, Rect2i(pair[0], Vector2i(230, 200))), "bag_depot_%s.png" % pair[1], 165)
	# Ícones ilustrados: depósitos, categorias e o selo de novo.
	for pair: Array in [[23, "fridge"], [17, "chest"], [26, "silo"], [21, "warehouse"], [46, "food"], [41, "crop"],
			[28, "material"], [19, "product"], [43, "find"], [36, "trail"], [38, "keepsake"], [16, "all"]]:
		var icon := _src(pair[0])
		var used := icon.get_used_rect()
		icon = icon.get_region(used)
		var side := maxi(icon.get_width(), icon.get_height())
		var square := Image.create(side, side, false, Image.FORMAT_RGBA8)
		square.blit_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), Vector2i((side - icon.get_width()) / 2, (side - icon.get_height()) / 2))
		_save(square, "bag_icon_%s.png" % pair[1], 120, 120)
	_save(_src(47), "bag_new.png", 42, 42)
	quit()
