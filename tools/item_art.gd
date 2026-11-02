extends SceneTree
## Gera as peças do detalhe de item "madeira ilustrada" em game/assets/sprites/ui/home/ (prefixo item_) a partir de
## IUREF/iteusem-v1/iteusem-v1_<n>.png. Peças limpas (sem texto/ícones assados), ~3x o tamanho de exibição:
##  _1  item_frame.png   moldura com a placa vazia; o miolo (cartão creme, pílula, botões e painéis) vira madeira lisa
##                       (cada linha vai da faixa clara da esquerda à da direita: o veio continua). Flores/vinhas dos cantos de baixo ficam.
##  _1  item_card.png    cartão creme vazio, remontado dos quatro cantos + faixas (o miolo é uma cor só)
##  _1  item_panel.png   painel de madeira (cabeçalho sem texto, miolo creme sem a horta)
##  _1  item_pill.png    pílula creme vazia (a "Quantidade: N")
##  _1  item_plate.png   pratinho redondo vazio (sintético: disco pêssego + aro, perfil lido da referência)
##  _4  item_btn_gold.png  botão amarelo sem texto      _5  item_btn_green.png  botão verde-água sem texto
## Todas as escalas partem de S = 1116 / 836 (a moldura sai com 372 de exibição x 3). As medidas que o `ItemUi` usa
## (margens dos NinePatch, posição da placa etc.) são impressas no fim, em px guardados e de exibição.
## Uso: godot --headless --path game -s ../tools/item_art.gd   (depois: --import e mipmaps/generate=true nos item_*.png.import)

const OUT := "res://assets/sprites/ui/home/"
const SRC := "res://../IUREF/iteusem-v1/iteusem-v1_%d.png"
const S := 1116.0 / 836.0


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SRC % n))
	if image == null:
		push_error("faltou %d" % n)
		quit(1)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, file: String, scale: float) -> void:
	var w := int(round(image.get_width() * scale))
	var h := int(round(image.get_height() * scale))
	if image.get_width() != w or image.get_height() != h:
		image.resize(w, h, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path(OUT + file))
	print("%s %dx%d" % [file, w, h])


## Cor de decoração (folhas, vinhas, flores): verde/azul, coral ou o miolo amarelo das flores.
func _is_deco(c: Color) -> bool:
	if c.a < 0.5:
		return false
	var h := c.h * 360.0
	if c.s > 0.22 and h >= 70.0 and h <= 270.0:
		return true
	if c.s > 0.10 and h >= 170.0 and h <= 270.0:
		return true  # pétalas azul-acinzentadas
	if c.s > 0.5 and c.v > 0.7 and (h <= 14.0 or h >= 340.0):
		return true
	return c.s > 0.75 and c.v > 0.85 and h >= 35.0 and h <= 55.0


## Pixels de fora do desenho (a madeira clara em volta do contorno marrom) viram transparentes: flood a partir das bordas.
func _clear_outside(image: Image) -> void:
	var w := image.get_width()
	var h := image.get_height()
	var seen := {}
	var stack: Array[Vector2i] = []
	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or seen.has(p):
			continue
		var c := image.get_pixelv(p)
		var wood := c.r > 0.9 and c.g < 0.86 and c.b < 0.72 and c.a > 0.5
		if not wood and c.a > 0.5:
			continue
		seen[p] = true
		image.set_pixelv(p, Color(c.r, c.g, c.b, 0.0))
		stack.append(p + Vector2i(1, 0))
		stack.append(p + Vector2i(-1, 0))
		stack.append(p + Vector2i(0, 1))
		stack.append(p + Vector2i(0, -1))


# --- Moldura ----------------------------------------------------------------------------------

func _frame() -> void:
	var image := _src(1)
	var orig := image.duplicate() as Image
	# Interior: cada linha vai da faixa clara da esquerda (x 45) à da direita (x 797). As amostras param antes das vinhas.
	for y in range(169, 1297):
		var left := orig.get_pixel(45, mini(y, 1170))
		var right := orig.get_pixel(797, mini(y, 1170))
		var x0 := 54
		var x1 := 786
		if y < 224:
			# abaixo da placa: só o que é creme (ou a sombra dela) vira madeira; a placa e o contorno ficam
			for x in range(x0, x1):
				var c := orig.get_pixel(x, y)
				var corner := x < 128 or x >= 715
				if corner or (c.b > 0.58 and c.g > 0.70 and c.a > 0.5):
					image.set_pixel(x, y, left.lerp(right, clampf(float(x - 45) / 752.0, 0.0, 1.0)))
			continue
		for x in range(x0, x1):
			image.set_pixel(x, y, left.lerp(right, clampf(float(x - 45) / 752.0, 0.0, 1.0)))
	# Flores e vinhas dos cantos de baixo: volta o original só onde é decoração (com 3 px de contorno).
	for zone: Rect2i in [Rect2i(0, 1150, 125, 150), Rect2i(650, 1150, 186, 150)]:
		var mask := {}
		for y in range(zone.position.y, zone.end.y):
			for x in range(zone.position.x, zone.end.x):
				if _is_deco(orig.get_pixel(x, y)):
					for dy in range(-3, 4):
						for dx in range(-3, 4):
							if dx * dx + dy * dy <= 10:
								mask[Vector2i(x + dx, y + dy)] = true
		for p: Vector2i in mask:
			if zone.has_point(p):
				image.set_pixelv(p, orig.get_pixelv(p))
	_save(image, "item_frame.png", S)
	var f := S / 3.0
	print("moldura: placa interna x %.0f..%.0f y %.0f..%.0f (exibição)" % [150 * f, 690 * f, 78 * f, 190 * f])
	print("moldura: cartão começa y %.1f, madeira útil x %.1f..%.1f, painéis podem acabar em y(base) %.1f da base" % [225 * f, 55 * f, 786 * f, (1359 - 1255) * f])
	print("moldura: margens px guardados L %.0f T %.0f R %.0f B %.0f" % [285 * S, 232 * S, (836 - 550) * S, (1359 - 1170) * S])


# --- Cartão -----------------------------------------------------------------------------------

func _card() -> void:
	var r := 56
	var mid := 8
	var w := r * 2 + mid
	var image := Image.create(w, w, false, Image.FORMAT_RGBA8)
	var src := _src(1)
	for y in w:
		for x in w:
			var sx: int
			var sy: int
			var in_left := x < r
			var in_right := x >= w - r
			var in_top := y < r
			var in_bottom := y >= w - r
			if in_left:
				sx = 54 + x
			elif in_right:
				sx = 786 - r + (x - (w - r))
			else:
				sx = 104 if in_top else 420
			var color: Color
			if in_top:
				color = src.get_pixel(sx, 169 + y)
			elif in_bottom:
				color = src.get_pixel(sx, 892 - r + (y - (w - r)))
			else:
				# faixa do meio: mistura a linha de cima (230) com a de baixo (830), sem degrau
				if not in_left and not in_right:
					sx = 420
				var t := float(y - r) / float(mid)
				color = src.get_pixel(sx, 230).lerp(src.get_pixel(sx, 830), t)
			image.set_pixel(x, y, color)
	# cantos: o que fica fora do arco (raio 44) sai; a linha de madeira que desce pela esquerda/direita não faz parte do cartão
	var rc := 44.0
	for y in w:
		for x in w:
			var cx := rc if x < rc else (w - rc if x > w - rc else float(x))
			var cy := rc if y < rc else (w - rc if y > w - rc else float(y))
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(cx, cy))
			if (x < rc or x > w - rc) and (y < rc or y > w - rc):
				var c := image.get_pixel(x, y)
				image.set_pixel(x, y, Color(c.r, c.g, c.b, clampf(rc - d + 0.5, 0.0, 1.0)))
	_save(image, "item_card.png", S)
	print("cartão: margem %.0f px guardados (raio %d de origem)" % [r * S, r])


# --- Painel -----------------------------------------------------------------------------------

func _panel() -> void:
	var src := _src(1)
	# Texto do cabeçalho: cada linha vira o degradê entre a coluna limpa da esquerda (135) e a da direita (357).
	for y in range(936, 1001):
		var a := src.get_pixel(135, y)
		var b := src.get_pixel(357, y)
		for x in range(136, 357):
			src.set_pixel(x, y, a.lerp(b, float(x - 135) / 222.0))
	# Miolo creme: a horta some; cada linha copia a coluna limpa do cantinho (104 no reto, 130 nas curvas).
	for y in range(1013, 1239):
		var col := 104 if y >= 1034 and y <= 1216 else 130
		var c := src.get_pixel(col, y)
		for x in range(106, 384):
			src.set_pixel(x, y, c)
	var image := src.get_region(Rect2i(72, 912, 340, 366))
	# A flor cobre o canto de baixo à esquerda: ele vem do canto de baixo à direita espelhado.
	for y in range(290, 366):
		for x in range(0, 70):
			image.set_pixel(x, y, image.get_pixel(339 - x, y))
	_clear_outside(image)
	_save(image, "item_panel.png", S)
	print("painel: margens guardados L/R %.0f T %.0f B %.0f; creme em x %.1f..%.1f y %.1f..%.1f de exibição" % [52 * S, 112 * S, 66 * S, (101 - 72) * S / 3.0, (394 - 72) * S / 3.0, (1006 - 912) * S / 3.0, (1245 - 912) * S / 3.0])


# --- Pílula -----------------------------------------------------------------------------------

func _pill() -> void:
	var src := _src(1)
	var top := 619
	var bottom := 706
	var h := bottom - top
	var left_w := 32
	var right_w := 28
	var mid := 8
	var image := Image.create(left_w + mid + right_w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in left_w:
			image.set_pixel(x, y, src.get_pixel(226 + x, top + y))
		for x in right_w:
			image.set_pixel(left_w + mid + x, y, src.get_pixel(587 + x, top + y))
		var column := src.get_pixel(538, top + y)
		if top + y >= 653 and top + y <= 657:
			column = src.get_pixel(538, 652).lerp(src.get_pixel(538, 658), float(top + y - 652) / 6.0)
		for x in mid:
			image.set_pixel(left_w + x, y, column)
		# suaviza a emenda: as últimas colunas dos cantos se misturam com a coluna do meio
		for i in 12:
			var t := float(i + 1) / 13.0
			var xl := left_w - 1 - i
			image.set_pixel(xl, y, image.get_pixel(xl, y).lerp(column, (1.0 - t) * 0.0 + (1.0 - t)))
			var xr := left_w + mid + i
			image.set_pixel(xr, y, image.get_pixel(xr, y).lerp(column, 1.0 - t))
	# cápsula: o que fica fora dela (cantos) sai; o cartão atrás tem outro tom de creme
	var radius := h / 2.0
	for y in h:
		for x in image.get_width():
			var sx := -1.0
			if x < left_w:
				sx = 226.0 + x + 0.5
			elif x >= left_w + mid:
				sx = 587.0 + (x - left_w - mid) + 0.5
			var dx := 0.0
			if sx >= 0.0 and sx < 269.5:
				dx = sx - 269.5
			elif sx > 571.5:
				dx = sx - 571.5
			var d := Vector2(dx, y + 0.5 - radius).length()
			var c := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(c.r, c.g, c.b, clampf(radius - d + 0.5, 0.0, 1.0)))
	_save(image, "item_pill.png", 1.0)
	print("pílula: margens guardados L %d R %d (altura %d)" % [left_w, right_w, h])


# --- Pratinho ---------------------------------------------------------------------------------

func _plate() -> void:
	var src := _src(1)
	var size := 132
	var radius := size / 2.0
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var ratio := 62.0 / radius  # raio da referência / raio guardado: o perfil do aro vem de cima para dentro
	var inner := src.get_pixel(527, 1065)
	for y in size:
		for x in size:
			var d := radius - (Vector2(x + 0.5, y + 0.5) - Vector2(radius, radius)).length()
			if d <= 0.0:
				continue
			var color := inner
			var step := d * ratio
			if step < 8.0:
				color = src.get_pixel(527, 1050 + int(step)).lerp(src.get_pixel(527, 1051 + int(step)), step - floor(step))
			var a := clampf(d, 0.0, 1.0)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, a))
	_save(image, "item_plate.png", 1.0)


# --- Botões -----------------------------------------------------------------------------------

func _button(n: int, file: String) -> void:
	var image := _src(n)
	for y in range(60, 201):
		var a := image.get_pixel(82, y)
		var b := image.get_pixel(494, y)
		for x in range(83, 494):
			image.set_pixel(x, y, a.lerp(b, float(x - 82) / 412.0))
	var scale := 132.0 / image.get_height()
	_save(image, file, scale)
	print("%s: origem %dx%d; margens guardados %d" % [file, image.get_width(), image.get_height(), 66])


func _init() -> void:
	_frame()
	_card()
	_panel()
	_pill()
	_plate()
	_button(4, "item_btn_gold.png")
	_button(5, "item_btn_green.png")
	quit()
