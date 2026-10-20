extends SceneTree
## Prepara as fontes PixelLab da Casa, sem rede nem geração: recorte de alfa, escala nearest e
## inclinação da parede. Fontes/jobs/prompts: tools/art/house_pixellab/manifest.json.
## godot --headless --path game -s ../tools/house_art.gd; depois --headless --path game --import
## Nenhum PNG do Tiro é alterado. O retrato usa o HUD adulto atual dentro da moldura PixelLab.
const SOURCE := "res://../tools/art/house_pixellab/"
const OUT := "res://assets/sprites/areas/house/"
const SLOPE := 0.37
const REQUIRED := ["arrival_box", "laundry_basket", "toy_basket", "paw_rug", "old_camera",
	"height_chart", "memory_shelf", "photo_wall", "gold_frame", "star_garland", "bed_soft", "bed_luxe", "named_bowl"]

func _init() -> void:
	# Valida todas as fontes antes de sobrescrever qualquer asset do jogo.
	for id: String in REQUIRED:
		if not FileAccess.file_exists(SOURCE + id + ".png"):
			push_error("Falta fonte PixelLab: " + id)
			quit(1)
			return
	for id: String in ["arrival_box", "laundry_basket", "toy_basket", "paw_rug", "old_camera"]:
		var dimensions: Vector2i = {"arrival_box": Vector2i(28, 20), "laundry_basket": Vector2i(20, 20),
			"toy_basket": Vector2i(24, 20), "paw_rug": Vector2i(30, 13), "old_camera": Vector2i(12, 10)}[id]
		_save(id, _fit(_source(id), dimensions))
	_save("height_chart", _shear(_stretch(_source("height_chart"), Vector2i(14, 60))))
	# A prateleira fica na base; a faixa de cima é reservada às lembranças desenhadas por HouseDecor.
	var shelf := _blank(Vector2i(60, 22))
	var board := _stretch(_source("memory_shelf"), Vector2i(60, 7))
	shelf.blend_rect(board, Rect2i(Vector2i.ZERO, board.get_size()), Vector2i(0, 15))
	_save("memory_shelf", _shear(shelf))
	_save("photo_wall", _shear(_stretch(_source("photo_wall"), Vector2i(62, 34))))
	_save("gold_frame", _shear(_stretch(_gold_frame(), Vector2i(20, 18))))
	_save("gold_frame_front", _stretch(_gold_frame(), Vector2i(32, 32)))
	_save("star_garland", _shear(_stretch(_tint(_source("star_garland"), 0.12, 1.4, 1.08), Vector2i(100, 14))))
	# Mesmo canvas das caminhas existentes para manter posição, área tocável e sono.
	var bed_size := _existing("dog_bed").get_size()
	_save("bed_soft", _tint(_fit(_source("bed_soft"), bed_size), 0.95, 0.55, 1.08))
	_save("bed_luxe", _tint(_fit(_source("bed_luxe"), bed_size), 0.77, 0.65, 1.02))
	_save("named_bowl", _fit(_source("named_bowl"), _existing("bowl").get_size()))
	var frame := _stretch(_gold_frame(), Vector2i(40, 40))
	var portrait := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/ui/icons/hud_tiro.png"))
	portrait.convert(Image.FORMAT_RGBA8)
	portrait.resize(32, 32, Image.INTERPOLATE_NEAREST)
	frame.blend_rect(portrait, Rect2i(0, 0, 32, 32), Vector2i(4, 4))
	_save("big_portrait", _shear(frame))
	print("HOUSE ART: PASS (13 fontes PixelLab, 14 objetos + moldura frontal; Tiro adulto existente preservado)")
	quit()

func _source(id: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + id + ".png"))
	image.convert(Image.FORMAT_RGBA8)
	if id == "height_chart":
		# A geração veio com uma faixa de piso isolada nas últimas seis linhas; só a régua entra no móvel.
		image = image.get_region(Rect2i(0, 0, 32, 56))
	return image.get_region(image.get_used_rect())

func _gold_frame() -> Image:
	return _tint(_source("gold_frame"), 0.12, 1.4, 1.08)

func _existing(id: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(OUT + id + ".png"))
	image.convert(Image.FORMAT_RGBA8)
	return image

func _blank(dimensions: Vector2i) -> Image:
	var image := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return image

func _stretch(image: Image, dimensions: Vector2i) -> Image:
	image.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_NEAREST)
	return image

func _fit(image: Image, dimensions: Vector2i) -> Image:
	var factor := minf(float(dimensions.x) / image.get_width(), float(dimensions.y) / image.get_height())
	image.resize(maxi(1, roundi(image.get_width() * factor)), maxi(1, roundi(image.get_height() * factor)), Image.INTERPOLATE_NEAREST)
	var result := _blank(dimensions)
	# Objetos apoiados no chão: centralizados e encostados no limite inferior, como os móveis originais.
	result.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i((dimensions.x - image.get_width()) / 2, dimensions.y - image.get_height()))
	return result

func _shear(image: Image) -> Image:
	var w := image.get_width()
	var h := image.get_height()
	var extra := ceili(w * SLOPE)
	var result := _blank(Vector2i(w, h + extra))
	for x in w:
		var shift := roundi(x * SLOPE)
		for y in h:
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0:
				result.set_pixel(x, y + extra - shift, pixel)
	return result

func _tint(image: Image, hue: float, saturation: float, value: float) -> Image:
	for x in image.get_width():
		for y in image.get_height():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0 and pixel.s > 0.12 and pixel.v > 0.3:
				image.set_pixel(x, y, Color.from_hsv(hue, clampf(pixel.s * saturation, 0.0, 1.0), clampf(pixel.v * value, 0.0, 1.0), pixel.a))
	return image

func _save(id: String, image: Image) -> void:
	var result := image.save_png(ProjectSettings.globalize_path(OUT + id + ".png"))
	if result != OK:
		push_error("Não foi possível salvar " + id)
