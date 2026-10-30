extends SceneTree
## Gera as peças do mini-cartão do próximo passo (madeira ilustrada) em game/assets/sprites/ui/home/ (prefixo step_)
## a partir das pranchas de IUREF/submission (farm-v1_<n>.png). Cada peça sai com ~3x o tamanho de exibição
## (o jogo desenha em escala 1/3, como as da tela inicial, da Mochila e das Missões).
## Uso: godot --headless --path game -s ../tools/step_card_art.gd   (depois: godot --headless --path game --import)
## As linhas "GROOVE" e "CAP" impressas aqui alimentam as constantes de `scripts/ui/step_card_ui.gd`.

const OUT := "res://assets/sprites/ui/home/"
const DARK := Color(0.2, 0.09, 0.03)


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://../IUREF/submission/farm-v1_%d.png" % n))
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


func _is_green(c: Color) -> bool:
	return c.a > 0.5 and c.g - c.b > 0.2 and c.g > c.r


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


func _green_bounds(image: Image) -> Rect2i:
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if _is_green(image.get_pixel(x, y)):
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	return Rect2i(lo, hi - lo + Vector2i.ONE)


## Composição "over" de uma cor com alfa sobre o pixel.
func _over(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height() or color.a <= 0.0:
		return
	var base := image.get_pixel(x, y)
	var a := color.a + base.a * (1.0 - color.a)
	if a <= 0.0:
		return
	var rgb := (Vector3(color.r, color.g, color.b) * color.a + Vector3(base.r, base.g, base.b) * base.a * (1.0 - color.a)) / a
	image.set_pixel(x, y, Color(rgb.x, rgb.y, rgb.z, a))


## Distância de `p` ao segmento a-b.
func _seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return (p - (a + ab * t)).length()


## Medalhão de "feito": disco verde brilhante com contorno marrom-escuro e um visto branco com contorno escuro.
## Desenhado em 4x e reduzido (bordas suaves), no mesmo estilo dos botões redondos de farm-v1_11/12.
func _medal() -> Image:
	var size := 384
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var c := Vector2(size, size) / 2.0
	var radius := size / 2.0 - 4.0
	var aa := 1.6
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var r := (p - c).length()
			var edge := clampf((radius - r) / aa, 0.0, 1.0)
			if edge <= 0.0:
				continue
			var color := DARK
			var inner := radius * 0.9
			var ring := clampf((inner - r) / aa, 0.0, 1.0)
			if ring > 0.0:
				var t := clampf((p.y - (c.y - inner)) / (inner * 2.0), 0.0, 1.0)
				var green := Color(0.62, 0.88, 0.22).lerp(Color(0.33, 0.66, 0.1), t)
				# Beirada de baixo mais escura (o "lábio" dos botões ilustrados).
				var lip := (p - (c - Vector2(0, radius * 0.1))).length()
				if lip > inner * 0.95:
					green = Color(0.2, 0.5, 0.08)
				color = DARK.lerp(green, ring)
			color.a = edge
			image.set_pixel(x, y, color)
	# Brilho no canto de cima à esquerda (uma mancha e um pontinho, como no botão verde).
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var q := p - (c + Vector2(-0.38, -0.5) * radius)
			var oval := Vector2(q.x / (radius * 0.3), q.y / (radius * 0.15)).length()
			if oval < 1.0:
				_over(image, x, y, Color(0.96, 1.0, 0.78, 0.9 * clampf((1.0 - oval) * 4.0, 0.0, 1.0)))
			var dot := (p - (c + Vector2(-0.62, -0.18) * radius)).length() / (radius * 0.07)
			if dot < 1.0:
				_over(image, x, y, Color(0.96, 1.0, 0.78, 0.85 * clampf((1.0 - dot) * 4.0, 0.0, 1.0)))
	# Visto: contorno escuro grosso, miolo branco.
	var a := c + Vector2(-0.38, 0.02) * radius
	var b := c + Vector2(-0.1, 0.34) * radius
	var d := c + Vector2(0.44, -0.3) * radius
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var dist := minf(_seg(p, a, b), _seg(p, b, d))
			var out_w := radius * 0.17
			var in_w := radius * 0.09
			if dist < out_w + aa:
				_over(image, x, y, Color(DARK.r, DARK.g, DARK.b, clampf((out_w - dist) / aa + 0.5, 0.0, 1.0)))
			if dist < in_w + aa:
				_over(image, x, y, Color(1, 1, 1, clampf((in_w - dist) / aa + 0.5, 0.0, 1.0)))
	return image


func _init() -> void:
	# Moldura de madeira com miolo creme (1182x495; desenhada a 960 de largura = 320 finais).
	_save(_src(1), "step_frame.png", 960)

	# Barra: trilho (o sulco verde vira marrom-escuro fundo; a ponta direita espelha a esquerda) e preenchimento verde.
	var bar := _src(4)
	var groove := _green_bounds(bar)
	print("GROOVE (no arquivo ", bar.get_size(), "): ", groove)
	# Corta a sombra de baixo: última linha opaca no meio da barra.
	var last := bar.get_height() - 1
	while last > 0 and bar.get_pixel(bar.get_width() / 2, last).a < 0.9:
		last -= 1
	var track := bar.get_region(Rect2i(0, 0, groove.end.x + groove.position.x, last + 1))
	var inset_top := Color(0.2, 0.1, 0.04)
	var inset_bottom := Color(0.34, 0.18, 0.07)
	for y in track.get_height():
		for x in track.get_width():
			var px := track.get_pixel(x, y)
			if px.a > 0.5 and px.g - px.b > 0.12 and px.g > px.r - 0.05 and groove.has_point(Vector2i(x, y)):
				var k := clampf(float(y - groove.position.y) / groove.size.y, 0.0, 1.0)
				track.set_pixel(x, y, inset_top.lerp(inset_bottom, k))
	var cap_w := 80
	var cap := track.get_region(Rect2i(0, 0, cap_w, track.get_height()))
	cap.flip_x()
	track.blit_rect(cap, Rect2i(Vector2i.ZERO, cap.get_size()), Vector2i(track.get_width() - cap_w, 0))
	var scale := 66.0 / float(track.get_height())
	print("CAP track ", track.get_size(), " escala ", scale, " groove no trilho 3x: x ", groove.position.x * scale, " y ", groove.position.y * scale, " alt ", groove.size.y * scale)
	_save(track, "step_bar_track.png", int(round(track.get_width() * scale)), 66)
	var fill := bar.get_region(groove)
	_round_mask(fill, fill.get_height() / 2.0)
	_save(fill, "step_bar_fill.png", int(round(fill.get_width() * scale)), int(round(fill.get_height() * scale)))

	# Botão verde grande (Ir): 3x de ~40 px de altura.
	_save(_src(5), "step_go.png", 548)
	# "?" de madeira (alvo 44, desenho 40).
	_save(_src(9), "step_help.png", 120, 118)
	# Moeda de estrela e brilhos.
	_save(_src(17), "step_coin.png", 66)
	var spark := _src(18)
	for y in range(84, spark.get_height()):
		for x in range(96, spark.get_width()):
			spark.set_pixel(x, y, Color(0, 0, 0, 0))
	var used := spark.get_used_rect()
	spark = spark.get_region(used)
	_save(spark, "step_sparkle.png", 66, int(round(float(used.size.y) * 66.0 / used.size.x)))
	_save(_src(19), "step_sparkle_small.png", 42)
	# Medalhão de "feito" (procedural).
	_save(_medal(), "step_done.png", 96)
	quit()
