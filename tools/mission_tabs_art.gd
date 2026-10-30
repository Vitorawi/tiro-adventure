extends SceneTree
## Gera as peças das abas da aba Missões (bandeja de madeira, abas escolhida/não escolhida, selo "!", pílula do capítulo)
## em game/assets/sprites/ui/home/ (prefixo mission_tab*/mission_chapter_pill) a partir de IUREF/painel missao.
## O X redondo (mission_close) sai de Missoes-v1_7.png.
## Uso: godot --headless --path game -s ../tools/mission_tabs_art.gd   (depois: godot --headless --path game --import)

const OUT := "res://assets/sprites/ui/home/"


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://../IUREF/painel missao/Missoes-v1_%d.png" % n))
	if image == null:
		push_error("faltou %d" % n)
		quit(1)
	image.convert(Image.FORMAT_RGBA8)
	# Fundo opaco colado na borda (cor do canto) vira transparente.
	if image.get_pixel(0, 0).a > 0.5:
		_cut_flood(image, 0.12)
	return image


func _save(image: Image, file: String, width: int, height: int) -> void:
	if image.get_width() != width or image.get_height() != height:
		image.resize(width, height, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path(OUT + file))
	print("%s %dx%d" % [file, image.get_width(), image.get_height()])


func _cut_flood(image: Image, tolerance: float) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var ref := image.get_pixel(0, 0)
	var seen := PackedByteArray()
	seen.resize(w * h)
	var queue: Array[Vector2i] = []
	for x in w:
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in h:
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))
	while not queue.is_empty():
		var p: Vector2i = queue.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen[p.y * w + p.x] == 1:
			continue
		var c := image.get_pixelv(p)
		var d := absf(c.r - ref.r) + absf(c.g - ref.g) + absf(c.b - ref.b)
		if c.a < 0.05 or d < tolerance:
			seen[p.y * w + p.x] = 1
			image.set_pixelv(p, Color(0, 0, 0, 0))
			queue.append(p + Vector2i(1, 0))
			queue.append(p + Vector2i(-1, 0))
			queue.append(p + Vector2i(0, 1))
			queue.append(p + Vector2i(0, -1))


func _darken(image: Image, factor: float) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.0:
				image.set_pixel(x, y, Color(c.r * factor, c.g * factor * 0.95, c.b * factor * 0.9, c.a))


func _init() -> void:
	# Abas: 44 px finais de altura (x3 = 132); cantos de 22 px finais.
	_save(_src(12), "mission_tab_on.png", 396, 132)
	_save(_src(11), "mission_tab_off.png", 396, 132)
	# Selo vermelho "!": 26 px finais, guardado com 104 px.
	var badge := _src(14)
	_save(badge, "mission_tab_badge.png", 104, int(round(float(badge.get_height()) * 104.0 / badge.get_width())))
	# Bandeja: a pílula de madeira escurecida, 56 px finais de altura.
	var tray := _src(11)
	_darken(tray, 0.52)
	_save(tray, "mission_tabs_tray.png", 504, 168)
	# Pílula creme do nome do capítulo: 30 px finais de altura.
	_save(_src(15), "mission_chapter_pill.png", 264, 90)
	# Botão X redondo: 40 px finais (x3 = 120).
	_save(_src(7), "mission_close.png", 120, 120)
	quit()
