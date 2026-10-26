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


func _crop(image: Image, area: Rect2i) -> Image:
	return image.get_region(area)


func _init() -> void:
	var full := _src(51)
	print("BAG_CREAM = ", full.get_pixel(760, 700).to_html(false))
	# Cartão do depósito (o da geladeira), sem o ícone, o fundo do ícone e a barra: o jogo desenha os seus.
	var sheet := _src(1)
	var card := _crop(sheet, Rect2i(36, 6, 830, 260))
	_wipe_cols(card, Rect2i(40, 30, 750, 200), 275)
	print("BAG_INSET = ", sheet.get_pixel(110, 60).to_html(false))
	_save(card, "bag_depot.png", 498)
	# Tábua dos filtros: só a madeira da frente (sem as pontas com folhas, flor e parafusos); o miolo vira liso.
	var plank := _crop(sheet, Rect2i(96, 583, 1698, 166))
	_wipe_cols(plank, Rect2i(20, 6, 1658, 150), 404)
	_round_mask(plank, 26.0)
	_save(plank, "bag_plank.png", int(round(1698.0 * 3 * 56 / 166)), 3 * 56)
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
