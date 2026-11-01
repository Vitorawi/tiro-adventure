extends SceneTree
## Gera as peças da bandeja de estação "madeira ilustrada" (StationTray/ActionTray em modo wood) em
## game/assets/sprites/ui/home/ (prefixo station_) e as comidas ilustradas `food_<item>.png` a partir de
## IUREF/cookinig-v1/cookinig-v1_<n>.png e IUREF/comidas_sheet.png. Cada peça sai com ~3x o tamanho de exibição (o jogo
## desenha os NinePatch em escala 1/3, como farm_*, step_* e bag_*).
## Uso: godot --headless --path game -s ../tools/station_art.gd   (depois: godot --headless --path game --import e
## troque mipmaps/generate=true nos station_*.png.import e food_*.png.import novos).

const OUT := "res://assets/sprites/ui/home/"
const SRC := "res://../IUREF/cookinig-v1/cookinig-v1_%d.png"

## Comidas da prancha: (item, coluna 0..4, linha 0..3).
const FOODS := [
	["dog_food", 0, 0], ["carrot_snack", 1, 0], ["pumpkin_mash", 2, 0], ["vegetable_soup", 3, 0], ["apple_biscuit", 4, 0],
	["cheese", 0, 1], ["strawberry_pop", 1, 1], ["strawberry_juice", 2, 1], ["mashed_potato", 3, 1], ["sweet_potato_chips", 4, 1],
	["mint_snack", 0, 2], ["blueberry_treat", 1, 2], ["frozen_carrot", 2, 2], ["puppy_mash", 3, 2], ["corn_crunch", 4, 2],
	["growth_kibble", 0, 3], ["egg_scramble", 1, 3], ["cheese_bites", 2, 3], ["milk_porridge", 3, 3], ["birthday_cake", 4, 3],
]
const COL_X := [364, 683, 1004, 1323, 1643]
const ROW_Y := [[262, 540], [590, 862], [900, 1182], [1228, 1500]]


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
	var path := ProjectSettings.globalize_path(OUT + file)
	image.save_png(path)
	print("%s %dx%d" % [file, image.get_width(), image.get_height()])


## Copia a coluna limpa `from_x` sobre o retângulo `area` (apaga desenhos mantendo o degradê vertical).
func _wipe_cols(image: Image, area: Rect2i, from_x: int) -> void:
	for y in range(area.position.y, area.end.y):
		var c := image.get_pixel(from_x, y)
		for x in range(area.position.x, area.end.x):
			image.set_pixel(x, y, c)


## Retângulo com alfa acima do limiar.
func _bounds(image: Image, threshold: float) -> Rect2i:
	var x0 := image.get_width()
	var y0 := image.get_height()
	var x1 := -1
	var y1 := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > threshold:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2i(0, 0, 1, 1)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


## Cola `top` centrada sobre `base`, com a escala `fraction` da menor lateral da base.
func _stamp(base: Image, top: Image, fraction: float, dy: int = 0) -> void:
	var t := top.duplicate() as Image
	var side := int(minf(base.get_width(), base.get_height()) * fraction)
	var ratio := minf(float(side) / t.get_width(), float(side) / t.get_height())
	t.resize(maxi(1, int(t.get_width() * ratio)), maxi(1, int(t.get_height() * ratio)), Image.INTERPOLATE_LANCZOS)
	base.blend_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i((base.get_width() - t.get_width()) / 2, (base.get_height() - t.get_height()) / 2 + dy))


## "+" de bordas arredondadas com contorno escuro (cor do miolo `fill`), desenhado por distância.
func _plus(size_px: int, fill: Color, edge: Color) -> Image:
	var image := Image.create(size_px, size_px, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var c := size_px / 2.0
	var arm := size_px * 0.46
	var half := size_px * 0.17
	var out_w := size_px * 0.06
	for y in size_px:
		for x in size_px:
			var p := Vector2(x + 0.5 - c, y + 0.5 - c)
			var d := minf(_box_d(p, Vector2(arm, half)), _box_d(p, Vector2(half, arm)))
			if d < out_w:
				image.set_pixel(x, y, edge if d > -out_w else fill)
	return image


## Distância assinada a um retângulo centrado de meias-medidas `h` com cantos arredondados.
func _box_d(p: Vector2, h: Vector2) -> float:
	var r := minf(h.x, h.y) * 0.9
	var q := p.abs() - h + Vector2(r, r)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r


func _init() -> void:
	# Moldura grande, bandeja bege da fila e tábua do rodapé (NinePatch).
	_save(_src(1), "station_frame.png", 720)
	_save(_src(2), "station_tray.png", 480)
	_save(_src(3), "station_board.png", 598, 186)

	# Quadradinhos: espaço afundado, ícone do fogão e caixa em relevo (botões e ícone das outras estações).
	_save(_src(13), "station_slot.png", 168)
	_save(_src(14), "station_stove.png", 138)
	var box := _src(18)
	_save(box.duplicate(), "station_box.png", 138)
	var gear := box.duplicate() as Image
	_stamp(gear, _src(24), 0.62)
	_save(gear, "station_gear.png", 114)
	var minus := box.duplicate() as Image
	_stamp(minus, _src(31), 0.58)
	_save(minus, "station_minus.png", 108)
	var plus_btn := box.duplicate() as Image
	_stamp(plus_btn, _plus(200, Color("f6e3c2"), Color("5a2d12")), 0.62)
	_save(plus_btn, "station_plus.png", 108)
	_save(_plus(180, Color("f59a23"), Color("7a3a10")), "station_add.png", 66)  # "+" laranja do espaço vazio
	_save(_src(15), "station_button.png", 138, 108)  # botão de madeira ("Tudo", NinePatch)
	_save(_src(19), "station_x.png", 114)             # X vermelho

	# Cartões da grade: o creme sem comida (apaga o desenho do cartão 4) e o amarelo do escolhido.
	var card := _src(4)
	var w := card.get_width()
	var h := card.get_height()
	# A comida ocupa o miolo: repete a linha limpa de cima (y 86) por todo o meio, mantendo topo e base originais.
	for y in range(86, h - 66):
		for x in w:
			card.set_pixel(x, y, card.get_pixel(x, 86))
	# Miolo liso também na horizontal (sem as faixas escuras das laterais ao esticar o NinePatch).
	for y in range(60, h - 56):
		for x in range(40, w - 40):
			card.set_pixel(x, y, card.get_pixel(w / 2, y))
	_save(card, "station_card.png", 210)
	_save(_src(20), "station_card_on.png", 210)

	# Pequenos: relógio, brilho, ✓, seta amarela.
	_save(_src(29), "station_clock.png", 48)
	_save(_src(32), "station_sparkle.png", 66)
	_save(_src(27), "station_check.png", 72)
	_save(_src(26), "station_arrow.png", 78)

	# Comidas ilustradas, recortadas da prancha (fundo já transparente) e centradas num quadrado.
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://../IUREF/comidas_sheet.png"))
	sheet.convert(Image.FORMAT_RGBA8)
	for entry: Array in FOODS:
		var cx: int = COL_X[entry[1]]
		var y0: int = ROW_Y[entry[2]][0]
		var y1: int = ROW_Y[entry[2]][1]
		var cell := sheet.get_region(Rect2i(cx - 150, y0, 300, y1 - y0))
		var used := _bounds(cell, 0.3).grow(2).intersection(Rect2i(Vector2i.ZERO, cell.get_size()))
		var piece := cell.get_region(used)
		var side := maxi(piece.get_width(), piece.get_height())
		var square := Image.create(side, side, false, Image.FORMAT_RGBA8)
		square.fill(Color(0, 0, 0, 0))
		square.blend_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), Vector2i((side - piece.get_width()) / 2, (side - piece.get_height()) / 2))
		_save(square, "food_%s.png" % str(entry[0]), 144)
	quit()
