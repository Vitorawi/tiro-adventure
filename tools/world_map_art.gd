extends SceneTree
## Gera as peças do seletor de mundos "madeira ilustrada" em game/assets/sprites/ui/home/ (prefixo map_) a partir de
## IUREF/Maps-v1/Maps-v1_<n>.png (arte 3x, fundo transparente):
##  _1 Natureza (cartão largo), _2 Sítio, _3 Casa, _4 Praça, _5 Vila -> map_<mundo>.png e map_<mundo>_locked.png
##     (os quatro quadrados usam a moldura do Sítio com o miolo transparente; cada ilustração é recortada sem esticar)
##  _6 placa creme de madeira (título e plaquinhas de nome) -> map_plate.png
##  _8 disco de madeira com a pata (achado do Tiro) -> map_status_finds.png; o disco VAZIO (a pata apagada e o miolo
##     preenchido por interpolação do aro) recebe um ícone por categoria: _7 estrelas (missão pronta), _10 pergaminho
##     (missão nova), _13 saco (colheita/coleta), _12 baú (tesouro), _11 cronômetro (em andamento) -> map_status_<tipo>.png
##  moldura: sell_frame.png sem a plaquinha de cima (o trilho de baixo, espelhado, vira o trilho de cima) -> map_frame.png
## Uso: godot --headless --path game -s ../tools/world_map_art.gd   (depois: --import e mipmaps/generate=true nos map_*.png.import)

const OUT := "res://assets/sprites/ui/home/"
const SRC := "res://../IUREF/Maps-v1/Maps-v1_%d.png"
const SQUARE := Vector2i(600, 580)
const DISC_PX := 132  # largura do disco guardado (exibido a ~44 px)


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SRC % n))
	if image == null:
		push_error("faltou %d" % n)
		quit(1)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, file: String) -> void:
	image.save_png(ProjectSettings.globalize_path(OUT + file))
	print("%s %dx%d" % [file, image.get_width(), image.get_height()])


## Recorte da parte opaca.
func _crop(image: Image) -> Image:
	var used := image.get_used_rect()
	return image.get_region(used)


func _resized(image: Image, width: int, height: int = 0) -> Image:
	var h := height if height > 0 else int(round(float(image.get_height()) * width / image.get_width()))
	var copy := image.duplicate() as Image
	copy.resize(width, h, Image.INTERPOLATE_LANCZOS)
	return copy


## Versão bloqueada: quase sem cor e mais escura (o alfa fica).
func _locked(image: Image) -> Image:
	var result := image.duplicate() as Image
	for y in result.get_height():
		for x in result.get_width():
			var c := result.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var grey := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			var mixed := Color(c.r, c.g, c.b).lerp(Color(grey, grey, grey), 0.85)
			result.set_pixel(x, y, Color(mixed.r * 0.62, mixed.g * 0.6, mixed.b * 0.58, c.a))
	return result


## Moldura dos quatro cartões quadrados: a do Sítio (_2, 616x582) com o miolo (retângulo arredondado) transparente.
## Cada ilustração é recortada de DENTRO da borda creme da própria foto (crop centrado, sem esticar) para a proporção
## do miolo, entra em escala UNIFORME por baixo da moldura e sai no tamanho nativo dela: nada fica deformado.
const FRAME_SIZE := Vector2i(616, 582)
const INNER := Rect2i(54, 51, 508, 471)    # miolo da moldura do Sítio
const UNDER := 4                           # a ilustração passa 4 px por baixo da moldura (sem fresta)
const CUT_RADIUS := 24.0
const CROP_INSET := 10                     # tira da foto fonte as pontas arredondadas da moldura dela
## Miolo (ilustração) de cada foto fonte, medido nas bordas creme: x, y, largura, altura.
const SOURCE_INNER := {
	"farm": Rect2i(57, 56, 503, 464),
	"house": Rect2i(60, 56, 486, 463),
	"park": Rect2i(57, 55, 502, 446),
	"village": Rect2i(57, 54, 496, 448),
}
const SOURCE_FILE := {"farm": 2, "house": 3, "park": 4, "village": 5}


func _frame_cut() -> Image:
	var frame := _src(2)
	var rect := Rect2(INNER)
	for y in range(INNER.position.y - 1, INNER.end.y + 1):
		for x in range(INNER.position.x - 1, INNER.end.x + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(p.x, rect.position.x + CUT_RADIUS, rect.end.x - CUT_RADIUS)
			var cy := clampf(p.y, rect.position.y + CUT_RADIUS, rect.end.y - CUT_RADIUS)
			var d := p.distance_to(Vector2(cx, cy))
			var inside := p.x >= rect.position.x and p.x <= rect.end.x and p.y >= rect.position.y and p.y <= rect.end.y and d <= CUT_RADIUS
			if inside:
				var c := frame.get_pixel(x, y)
				frame.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))
	return frame


func _composed(id: String, frame: Image) -> Image:
	var source := _src(SOURCE_FILE[id])
	var area: Rect2i = SOURCE_INNER[id].grow(-CROP_INSET)
	var under_w := INNER.size.x + UNDER * 2
	var under_h := INNER.size.y + UNDER * 2
	var aspect := float(under_w) / float(under_h)
	# crop centrado na proporção do miolo, o maior possível dentro da área
	var crop_w := area.size.x
	var crop_h := int(floor(crop_w / aspect))
	if crop_h > area.size.y:
		crop_h = area.size.y
		crop_w = int(floor(crop_h * aspect))
	var crop := Rect2i(area.position + Vector2i((area.size.x - crop_w) / 2, (area.size.y - crop_h) / 2), Vector2i(crop_w, crop_h))
	var art := source.get_region(crop)
	art.resize(under_w, under_h, Image.INTERPOLATE_LANCZOS)
	var result := Image.create(FRAME_SIZE.x, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	result.blend_rect(art, Rect2i(Vector2i.ZERO, art.get_size()), INNER.position - Vector2i(UNDER, UNDER))
	result.blend_rect(frame, Rect2i(Vector2i.ZERO, FRAME_SIZE), Vector2i.ZERO)
	print("%s: crop %s -> %dx%d (escala %.3f x %.3f)" % [id, crop, under_w, under_h, float(under_w) / crop_w, float(under_h) / crop_h])
	return result


func _photos() -> void:
	var frame := _frame_cut()
	for id: String in SOURCE_FILE:
		var image := _composed(id, frame)
		_save(image, "map_%s.png" % id)
		_save(_locked(image), "map_%s_locked.png" % id)
	# Natureza: a moldura própria da _1 já é proporcional; a foto sai nativa, sem redimensionar.
	var nature := _crop(_src(1))
	_save(nature, "map_nature.png")
	_save(_locked(nature), "map_nature_locked.png")


func _plate() -> void:
	_save(_resized(_crop(_src(6)), 600), "map_plate.png")


# --- Discos -----------------------------------------------------------------------------------

## Disco da pata sem a pata: o miolo (raio < 88) vem de uma interpolação ponderada dos pontos do círculo de raio 94,
## que já está no miolo liso e fora da pata.
func _blank_disc(full: Image) -> Image:
	var disc := full.duplicate() as Image
	var center := Vector2(full.get_width() / 2.0, full.get_height() / 2.0)
	var ring: Array[Vector2] = []
	var colors: Array[Color] = []
	for i in 48:
		var a := TAU * i / 48.0
		var p := center + Vector2(cos(a), sin(a)) * 94.0
		ring.append(p)
		colors.append(full.get_pixelv(Vector2i(p)))
	for y in disc.get_height():
		for x in disc.get_width():
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(center) >= 88.0:
				continue
			var total := 0.0
			var mixed := Color(0, 0, 0, 0)
			for i in ring.size():
				var w := 1.0 / maxf(1.0, p.distance_squared_to(ring[i]))
				total += w
				mixed += colors[i] * w
			disc.set_pixel(x, y, Color(mixed.r / total, mixed.g / total, mixed.b / total, 1.0))
	return disc


func _stamp(disc: Image, icon: Image, ratio: float, down: float = 0.0) -> Image:
	var result := disc.duplicate() as Image
	var box := Vector2(disc.get_width(), disc.get_height()) * ratio
	var fit := minf(box.x / icon.get_width(), box.y / icon.get_height())
	var small := _resized(icon, int(round(icon.get_width() * fit)), int(round(icon.get_height() * fit)))
	var at := Vector2i((disc.get_width() - small.get_width()) / 2, int((disc.get_height() - small.get_height()) / 2 + down * disc.get_height()))
	result.blend_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), at)
	return result


func _discs() -> void:
	var full := _crop(_src(8))
	_save(_resized(full, DISC_PX), "map_status_finds.png")
	var blank := _blank_disc(full)
	var kinds := {"rewards": [7, 0.70, 0.0], "missions": [10, 0.60, 0.0], "collections": [13, 0.58, 0.0], "treasure": [12, 0.60, 0.0], "busy": [11, 0.56, 0.0]}
	for kind: String in kinds:
		var entry: Array = kinds[kind]
		var icon := _crop(_src(entry[0]))
		var big := _stamp(blank, _resized(icon, 400), float(entry[1]), float(entry[2]))
		_save(_resized(big, DISC_PX), "map_status_%s.png" % kind)
	_save(_resized(blank, DISC_PX), "map_disc.png")


# --- Moldura ----------------------------------------------------------------------------------

## sell_frame.png sem a plaquinha: x 185..730, y 0..170 vira trilho de madeira (o de baixo, espelhado) + creme.
func _frame() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(OUT + "sell_frame.png"))
	image.convert(Image.FORMAT_RGBA8)
	var h := image.get_height()
	var src := image.duplicate() as Image
	var x0 := 185
	var x1 := 731
	var rail_top := 1262   # o trilho de baixo: do fim do creme (1262) ao contorno (1306)
	var rail_h := 46
	var at := 66           # onde o trilho entra em cima
	for x in range(x0, x1):
		var cream := image.get_pixel(x, 168)
		for y in range(0, 170):
			var c := Color(0, 0, 0, 0)
			if y >= at and y < at + rail_h:
				# espelhado: a linha `at` é a de baixo do trilho original; as folhinhas de baixo (x < 255 e x > 660) não sobem
				var sx := x if x >= 255 and x <= 660 else 450
				c = src.get_pixel(sx, rail_top + (rail_h - 1 - (y - at)))
			elif y >= at + rail_h:
				c = cream
			image.set_pixel(x, y, c)
	# a emenda com os cantos: vira o creme do meio, sem degrau
	_save(image, "map_frame.png")
	print("map_frame: trilho em y %d..%d de %d guardados" % [at, at + rail_h, h])


func _init() -> void:
	_photos()
	_plate()
	_discs()
	_frame()
	quit()
