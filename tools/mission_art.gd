extends SceneTree
## Gera as peças das Missões "madeira ilustrada" (grupo História) em game/assets/sprites/ui/home/ (prefixo mission_)
## a partir das pranchas de IUREF/missaoprincipal (Missoes-v3_<n>.png). Cada peça sai com ~3x o tamanho de exibição
## (o jogo desenha em escala 1/3, como as da tela inicial e da Mochila).
## Uso: godot --headless --path game -s ../tools/mission_art.gd   (depois: godot --headless --path game --import)

const OUT := "res://assets/sprites/ui/home/"


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://../IUREF/missaoprincipal/Missoes-v3_%d.png" % n))
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


## Cor única sobre o retângulo (só onde o desenho original era opaco).
func _wipe_flat(image: Image, area: Rect2i, color: Color) -> void:
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if image.get_pixel(x, y).a > 0.9:
				image.set_pixel(x, y, color)


## Deixa só o retângulo arredondado (borda suave).
func _round_mask(image: Image, radius: float) -> void:
	var w := float(image.get_width())
	var h := float(image.get_height())
	for y in image.get_height():
		for x in image.get_width():
			var px := float(x) + 0.5
			var py := float(y) + 0.5
			var cx := clampf(px, radius, w - radius)
			var cy := clampf(py, radius, h - radius)
			var outside := Vector2(px - cx, py - cy).length() - radius
			if outside > 0.0:
				var c := image.get_pixel(x, y)
				c.a *= clampf(1.0 - outside, 0.0, 1.0)
				image.set_pixel(x, y, c)


## Apaga (alfa 0) o fundo que encosta na borda da imagem: pixels parecidos com a cor da linha, por inundação.
func _cut_flood(image: Image, tolerance: float) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var bg: Array[Color] = []
	for y in h:
		bg.append(image.get_pixel(0, y))
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
		var ref := bg[p.y]
		var d := absf(c.r - ref.r) + absf(c.g - ref.g) + absf(c.b - ref.b)
		if c.a < 0.05 or d < tolerance:
			seen[p.y * w + p.x] = 1
			image.set_pixelv(p, Color(0, 0, 0, 0))
			queue.append(p + Vector2i(1, 0))
			queue.append(p + Vector2i(-1, 0))
			queue.append(p + Vector2i(0, 1))
			queue.append(p + Vector2i(0, -1))


## Retângulo que contém os pixels que passam em `test` (dentro de `area`).
func _bounds(image: Image, area: Rect2i, test: Callable) -> Rect2i:
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if test.call(image.get_pixel(x, y)):
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	return Rect2i(lo, hi - lo + Vector2i.ONE)


func _init() -> void:
	# Moldura da tela: madeira com cipós, no tamanho da prancha (762 px = 254 finais).
	_save(_src(1), "mission_frame.png", 762)

	# Cartão do topo, sem retrato, etiqueta e barra (só o creme com a borda).
	var hero_src := _src(2)
	# A etiqueta laranja (texto do título) é recortada antes de apagar.
	var orange := func(c: Color) -> bool: return c.r > 0.85 and c.g > 0.5 and c.g < 0.7 and c.b < 0.35
	var label_box := _bounds(hero_src, Rect2i(290, 10, 330, 110), orange)
	print("label ", label_box)
	var label := hero_src.get_region(label_box)
	_round_mask(label, 19.0)
	_save(label, "mission_label.png", int(round(float(label_box.size.x) * 78.0 / label_box.size.y)), 78)
	var hero := hero_src.duplicate() as Image
	_wipe_cols(hero, Rect2i(28, 4, 944, 266), 287)
	_save(hero, "mission_hero.png", 840)

	# Moldura do retrato: o miolo arco-íris vira transparente (o retrato do personagem passa por baixo).
	var frame := _src(10)
	var hole := Rect2(33.0, 30.0, 164.0, 163.0)
	for y in frame.get_height():
		for x in frame.get_width():
			var px := Vector2(x + 0.5, y + 0.5)
			var cx := clampf(px.x, hole.position.x + 10.0, hole.end.x - 10.0)
			var cy := clampf(px.y, hole.position.y + 10.0, hole.end.y - 10.0)
			var inside := 10.0 - Vector2(px.x - cx, px.y - cy).length()
			if inside > 0.0:
				var c := frame.get_pixel(x, y)
				c.a = 1.0 - clampf(inside, 0.0, 1.0)
				frame.set_pixel(x, y, c)
	print("PORTRAIT_HOLE = ", hole)
	_save(frame, "mission_portrait.png", 229)

	# Barra: trilho (sem a parte coberta pela barra laranja; a ponta direita espelha a esquerda) e preenchimento.
	var bar := _src(12)
	var start := 503
	var track := bar.get_region(Rect2i(0, 0, start, bar.get_height()))
	var cap := track.get_region(Rect2i(0, 0, 40, track.get_height()))
	cap.flip_x()
	track.blit_rect(cap, Rect2i(Vector2i.ZERO, cap.get_size()), Vector2i(track.get_width() - 40, 0))
	_save(track, "mission_bar_track.png", int(round(float(track.get_width()) * 48.0 / track.get_height())), 48)
	var fill := bar.get_region(Rect2i(start, 0, bar.get_width() - start, bar.get_height()))
	_round_mask(fill, 27.0)
	_save(fill, "mission_bar_fill.png", int(round(float(fill.get_width()) * 48.0 / fill.get_height())), 48)

	# Placa de título (folhas e estrelinhas).
	_save(_src(5), "mission_plaque.png", 690)

	# Cartão de recompensas/passos sem os quadradinhos, a pílula e o botão (a prancha 4 tem os dois).
	var card_src := _src(4)
	var button_area := Rect2i(552, 70, 230, 110)
	var button := card_src.get_region(button_area)
	_cut_flood(button, 0.16)
	var shape: Rect2i = button.get_used_rect()
	button = button.get_region(shape)
	_save(button, "mission_go.png", 252, int(round(float(shape.size.y) * 252.0 / shape.size.x)))
	var card := card_src.duplicate() as Image
	_wipe_cols(card, Rect2i(28, 4, 752, 182), 420)
	_save(card, "mission_card.png", 840)

	# Quadradinho bege vazio (a prancha do elmo, sem o desenho).
	var tile := _src(18)
	var flat := tile.get_pixel(10, 60)
	_wipe_flat(tile, Rect2i(14, 8, tile.get_width() - 28, tile.get_height() - 16), flat)
	_wipe_flat(tile, Rect2i(8, 20, tile.get_width() - 16, tile.get_height() - 40), flat)
	_save(tile, "mission_tile.png", 112)

	# Botão verde grande e as duas pílulas (marrom e verde), com a mesma altura.
	_save(_src(11), "mission_claim.png", 304)
	var brown := _src(13)
	_save(brown, "mission_pill_brown.png", int(round(float(brown.get_width()) * 60.0 / brown.get_height())), 60)
	var green := _src(16)
	_save(green, "mission_pill_green.png", int(round(float(green.get_width()) * 60.0 / green.get_height())), 60)
	quit()
