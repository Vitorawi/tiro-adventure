extends SceneTree
## Gera as peças do Caderninho "madeira ilustrada" em game/assets/sprites/ui/home/ (prefixo codex_) a partir das
## pranchas de IUREF/codex-v1. Tudo sai em ~3x o tamanho de exibição (o jogo desenha em escala 1/3, como Mochila/Venda):
## moldura e placa em tamanho original, quadradinhos normalizados em 204 px de largura (NinePatch), ícones 120x120.
## Uso: godot --headless --path game -s ../tools/codex_art.gd   (depois: godot --headless --path game --import)

const OUT := "res://assets/sprites/ui/home/"
const TILE_W := 204


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://../IUREF/codex-v1/codex-v1_%d.png" % n))
	if image == null:
		push_error("faltou %d" % n)
		quit(1)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, file: String) -> void:
	var path := ProjectSettings.globalize_path(OUT + file)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("%s %dx%d" % [file, image.get_width(), image.get_height()])


## Recorta a área opaca (alfa > 8) e devolve só ela.
func _trim(image: Image) -> Image:
	var minx := image.get_width()
	var miny := image.get_height()
	var maxx := -1
	var maxy := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.03:
				minx = mini(minx, x)
				maxx = maxi(maxx, x)
				miny = mini(miny, y)
				maxy = maxi(maxy, y)
	return image.get_region(Rect2i(minx, miny, maxx - minx + 1, maxy - miny + 1))


## Quadradinho com largura fixa (proporção mantida).
func _tile(n: int, file: String, hue_shift: float = 0.0) -> void:
	var image := _trim(_src(n))
	if hue_shift != 0.0:
		for y in image.get_height():
			for x in image.get_width():
				var c := image.get_pixel(x, y)
				if c.a > 0.0 and c.s > 0.15:
					c.h = fposmod(c.h + hue_shift, 1.0)
					image.set_pixel(x, y, c)
	var h := int(round(float(image.get_height()) * TILE_W / image.get_width()))
	image.resize(TILE_W, h, Image.INTERPOLATE_LANCZOS)
	_save(image, file)


func _icon(n: int, file: String) -> void:
	var icon := _trim(_src(n))
	var side := maxi(icon.get_width(), icon.get_height())
	var square := Image.create(side, side, false, Image.FORMAT_RGBA8)
	square.blit_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), Vector2i((side - icon.get_width()) / 2, (side - icon.get_height()) / 2))
	square.resize(120, 120, Image.INTERPOLATE_LANCZOS)
	_save(square, file)


func _init() -> void:
	_save(_trim(_src(1)), "codex_frame.png")
	_save(_trim(_src(3)), "codex_plate.png")
	_tile(7, "codex_tile.png")
	_tile(15, "codex_tile_off.png")
	_tile(9, "codex_tab_orange.png")
	_tile(13, "codex_tab_red.png")
	_tile(10, "codex_tab_green.png")
	_tile(11, "codex_tab_yellow.png")
	_tile(12, "codex_tab_blue.png")
	_tile(12, "codex_tab_purple.png", 0.19)
	for pair: Array in [[17, "resources"], [8, "stations"], [25, "album"], [19, "collection"], [20, "tricks"], [35, "growth"], [18, "flower"], [27, "lens"]]:
		_icon(pair[0], "codex_icon_%s.png" % pair[1])
	quit()
