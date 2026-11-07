extends SceneTree
## Gera as molduras de raridade das fotos (`frame_1..4.png`, 528x528 = 3x da polaroide de 176) e os selos
## (`seal_1..4.png`, 96x96) em game/assets/sprites/ui/album/frames/. Tudo procedural, sem arte externa.
## A janela da foto (456x384 em 36,36) fica transparente; a faixa de baixo é papel para a legenda.
## Uso: godot --headless --path game -s ../tools/photo_frames_art.gd   (depois: --import; mipmaps/generate=true nos .import)

const OUT := "res://assets/sprites/ui/album/frames/"
const SIZE := 528
const HOLE := Rect2(36, 36, 456, 384)
const CARD_R := 30.0
const HOLE_R := 8.0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if "--back-only" in OS.get_cmdline_user_args():
		_back().save_png(ProjectSettings.globalize_path("res://assets/sprites/ui/album/card_back.png"))
		quit()
		return
	for kind in range(1, 5):
		var img := _frame(kind)
		img.save_png(ProjectSettings.globalize_path(OUT + "frame_%d.png" % kind))
		var seal := _seal(kind)
		seal.save_png(ProjectSettings.globalize_path(OUT + "seal_%d.png" % kind))
		print("nivel ", kind, " ok")
	quit()


# ---------- geometria ----------

static func _box(p: Vector2, rect: Rect2, r: float) -> float:
	var c := rect.get_center()
	var h := rect.size * 0.5
	var q := (p - c).abs() - h + Vector2(r, r)
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r


static func _cov(d: float) -> float:
	return clampf(0.5 - d, 0.0, 1.0)


static func _grad(stops: Array, t: float) -> Color:
	t = clampf(t, 0.0, 1.0)
	for i in range(stops.size() - 1):
		var a: Array = stops[i]
		var b: Array = stops[i + 1]
		if t <= float(b[0]):
			var k := (t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 0.0001)
			return (a[1] as Color).lerp(b[1] as Color, k)
	return (stops[stops.size() - 1] as Array)[1]


static func _over(img: Image, x: int, y: int, c: Color, cov: float) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height() or cov <= 0.0:
		return
	var dst := img.get_pixel(x, y)
	var a := c.a * cov
	var out_a := a + dst.a * (1.0 - a)
	if out_a <= 0.0:
		return
	var rgb := (Vector3(c.r, c.g, c.b) * a + Vector3(dst.r, dst.g, dst.b) * dst.a * (1.0 - a)) / out_a
	img.set_pixel(x, y, Color(rgb.x, rgb.y, rgb.z, out_a))


# ---------- molduras ----------

const GOLD := [[0.0, Color("fff3b0")], [0.3, Color("f4c64e")], [0.6, Color("c98a22")], [0.8, Color("f0c24a")], [1.0, Color("8d5a14")]]
const SILVER := [[0.0, Color("fbfaff")], [0.25, Color("c7cee2")], [0.5, Color("f0dcf2")], [0.75, Color("b3c5e0")], [1.0, Color("f6f3ff")]]
const WOOD := [[0.0, Color("a8693a")], [0.5, Color("8a5128")], [1.0, Color("6b3f1f")]]


static func _frame(kind: int) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var card := Rect2(0, 0, SIZE, SIZE)
	var rim: float = [0.0, 0.0, 10.0, 30.0, 24.0][kind]
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			var dc := _box(p, card, CARD_R)
			var cc := _cov(dc)
			if cc <= 0.0:
				continue
			var dh := _box(p, HOLE, HOLE_R)
			var hole_cov := _cov(dh)  # 1 dentro da janela
			var alpha := cc * (1.0 - hole_cov)
			if alpha <= 0.0:
				continue
			var col := _shade(kind, p, dc, dh, rim)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, alpha))
	if kind == 3:
		_garland(img)
	if kind == 4:
		_sparkles(img)
	return img


static func _paper(kind: int, p: Vector2) -> Color:
	var t := p.y / SIZE
	if kind == 4:
		return Color("faf9ff").lerp(Color("e9e8f5"), t)
	if kind == 3:
		return Color("fdf3dc").lerp(Color("f1dfbd"), t)
	return Color("fdf4e1").lerp(Color("f2e2c2"), t)


static func _shade(kind: int, p: Vector2, dc: float, dh: float, rim: float) -> Color:
	var col := _paper(kind, p)
	var diag := (p.x + p.y) / (SIZE * 2.0)
	if kind == 1:
		if dc > -3.0:
			col = Color("dcc59c")
		if dh < 6.0:
			col = col.lerp(Color("c9ae80"), clampf(1.0 - dh / 6.0, 0.0, 1.0) * 0.8)
		return col
	if kind == 2:
		if dc > -rim:
			col = _grad(GOLD, diag + 0.06 * sin(p.x * 0.05 + p.y * 0.03))
			if dc > -3.0 or dc < -rim + 3.0:
				col = col.lerp(Color("8a5a14"), 0.55)
			elif dc > -rim * 0.5 - 1.0 and dc < -rim * 0.5 + 1.5:
				col = col.lerp(Color("fff6c8"), 0.5)
		elif dh < 9.0:
			col = _grad(GOLD, 1.0 - diag)
			if dh > 6.0:
				col = col.lerp(Color("8a5a14"), 0.55)
		return col
	if kind == 3:
		if dc > -rim:
			col = _grad(WOOD, p.y / SIZE + 0.15 * sin(p.x * 0.02))
			if dc > -3.0:
				col = Color("4d2b13")
			elif dc > -7.0 and dc < -4.0:
				col = Color("c58e57")
			elif dc < -rim + 3.0:
				col = col.lerp(Color("3f230f"), 0.5)
		elif dh < 7.0:
			col = _grad(GOLD, 1.0 - diag)
			if dh > 4.5:
				col = col.lerp(Color("8a5a14"), 0.55)
		return col
	# kind == 4: prata/pérola
	if dc > -rim:
		col = _grad(SILVER, diag * 1.6 + 0.08 * sin((p.x - p.y) * 0.04))
		if dc > -3.0 or dc < -rim + 3.0:
			col = col.lerp(Color("7f89a8"), 0.5)
		elif dc > -rim * 0.5 - 1.0 and dc < -rim * 0.5 + 1.5:
			col = col.lerp(Color.WHITE, 0.55)
	elif dh < 8.0:
		col = _grad(SILVER, 1.0 - diag * 1.4)
		if dh > 5.5:
			col = col.lerp(Color("7f89a8"), 0.5)
	return col


# ---------- Rara: folhas e flores ----------

static func _leaf(img: Image, c: Vector2, ang: float, a: float, b: float, base: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(-dir.y, dir.x)
	var r := int(a) + 3
	for y in range(int(c.y) - r, int(c.y) + r + 1):
		for x in range(int(c.x) - r, int(c.x) + r + 1):
			var d := Vector2(x + 0.5, y + 0.5) - c
			var u := d.dot(dir) / a
			if absf(u) > 1.05:
				continue
			var v := d.dot(nrm)
			var limit := b * (1.0 - u * u)
			var cov := clampf(0.5 + limit - absf(v), 0.0, 1.0)
			if cov <= 0.0:
				continue
			var shade := base.lerp(Color("2f6b2c"), clampf(absf(v) / maxf(b, 1.0), 0.0, 1.0) * 0.7)
			if absf(v) < 1.1 and u > -0.8 and u < 0.85:
				shade = shade.lerp(Color("c9e8a0"), 0.7)
			_over(img, x, y, shade, cov)


static func _flower(img: Image, c: Vector2, rad: float, petal: Color) -> void:
	for i in 5:
		var ang := TAU * i / 5.0 - PI / 2.0
		var pc := c + Vector2(cos(ang), sin(ang)) * rad * 0.55
		_disc(img, pc, rad * 0.5, petal.darkened(0.12))
		_disc(img, pc, rad * 0.42, petal)
		_disc(img, pc - Vector2(0, rad * 0.06) + Vector2(cos(ang), sin(ang)) * rad * 0.05, rad * 0.2, petal.lightened(0.35))
	_disc(img, c, rad * 0.3, Color("c98a22"))
	_disc(img, c, rad * 0.24, Color("ffd45c"))


static func _disc(img: Image, c: Vector2, r: float, col: Color) -> void:
	var n := int(r) + 2
	for y in range(int(c.y) - n, int(c.y) + n + 1):
		for x in range(int(c.x) - n, int(c.x) + n + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c) - r
			_over(img, x, y, col, _cov(d))


static func _garland(img: Image) -> void:
	var green := Color("5fa043")
	# cantos: três folhas + uma flor
	var corners := [Vector2(34, 34), Vector2(SIZE - 34, 34), Vector2(34, SIZE - 34), Vector2(SIZE - 34, SIZE - 34)]
	var signs := [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	var petals := [Color("f58fae"), Color("fff0d8"), Color("fff0d8"), Color("f58fae")]
	for i in 4:
		var c: Vector2 = corners[i]
		var sg: Vector2 = signs[i]
		for k in 2:
			var ang := (Vector2(sg.x, 0.0).angle() if k == 0 else (Vector2(0.0, sg.y).angle() if k == 1 else Vector2(sg.x, sg.y).angle()))
			_leaf(img, c + Vector2(cos(ang), sin(ang)) * 20.0, ang, 20.0, 6.5, green)
		_flower(img, c, 18.0, petals[i])


# ---------- Holográfica: estrelinhas nos cantos ----------

static func _sparkles(img: Image) -> void:
	var spots := [[Vector2(46, 46), 18.0], [Vector2(SIZE - 46, 46), 14.0], [Vector2(46, SIZE - 46), 12.0], [Vector2(SIZE - 46, SIZE - 46), 18.0], [Vector2(SIZE * 0.5, 14), 9.0]]
	for s: Array in spots:
		_star4(img, s[0], s[1], Color(1, 1, 1, 0.95))


static func _star4(img: Image, c: Vector2, r: float, col: Color) -> void:
	var n := int(r) + 3
	for y in range(int(c.y) - n, int(c.y) + n + 1):
		for x in range(int(c.x) - n, int(c.x) + n + 1):
			var d := (Vector2(x + 0.5, y + 0.5) - c).abs()
			# astroide: |x|^0.5 + |y|^0.5 <= r^0.5
			var f := sqrt(d.x) + sqrt(d.y) - sqrt(r)
			_over(img, x, y, col, clampf(0.5 - f * 1.6, 0.0, 1.0))
			var halo := clampf(1.0 - (d.x + d.y) / (r * 1.8), 0.0, 1.0)
			_over(img, x, y, Color(col.r, col.g, col.b, 0.0), 0.0)
			if halo > 0.0:
				_over(img, x, y, Color(0.8, 0.85, 1.0, 0.25), halo * halo)


# ---------- selos ----------

static func _star_poly(c: Vector2, r_out: float, r_in: float, pts: int, rot: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in pts * 2:
		var r := r_out if i % 2 == 0 else r_in
		var a := rot + TAU * i / (pts * 2.0)
		out.append(c + Vector2(cos(a), sin(a)) * r)
	return out


static func _poly(img: Image, poly: PackedVector2Array, col: Color) -> void:
	var rect := Rect2(poly[0], Vector2.ZERO)
	for pt in poly:
		rect = rect.expand(pt)
	for y in range(int(rect.position.y) - 1, int(rect.end.y) + 2):
		for x in range(int(rect.position.x) - 1, int(rect.end.x) + 2):
			var hit := 0
			for sy in 3:
				for sx in 3:
					if Geometry2D.is_point_in_polygon(Vector2(x + (sx + 0.5) / 3.0, y + (sy + 0.5) / 3.0), poly):
						hit += 1
			if hit > 0:
				_over(img, x, y, col, hit / 9.0)


static func _seal(kind: int) -> Image:
	var s := 96
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(s * 0.5, s * 0.5)
	var rings := [Color("c9ae80"), Color("c98a22"), Color("c98a22"), Color("9aa6c6")]
	var fills := [Color("fdf4e1"), Color("ffe38a"), Color("5fa043"), Color("f4f2ff")]
	var edge := [Color("8d7a58"), Color("8a5a14"), Color("3f6b2c"), Color("6b7699")]
	_disc(img, c + Vector2(0, 2), 44.0, Color(0, 0, 0, 0.18))
	_disc(img, c, 44.0, edge[kind - 1])
	_disc(img, c, 41.0, rings[kind - 1])
	_disc(img, c, 34.0, fills[kind - 1])
	if kind == 1:
		_disc(img, c, 9.0, Color("c9ae80"))
	elif kind == 2:
		_poly(img, _star_poly(c, 24.0, 6.0, 4, -PI / 2.0), Color("c98a22"))
	elif kind == 3:
		_poly(img, _star_poly(c + Vector2(0, 1), 27.0, 11.5, 5, -PI / 2.0), Color("fff3b0"))
		_poly(img, _star_poly(c + Vector2(0, 1), 21.0, 9.0, 5, -PI / 2.0), Color("f4c64e"))
	else:
		# prisma: losango com facetas pastel
		var top := c + Vector2(0, -26)
		var bot := c + Vector2(0, 26)
		var lft := c + Vector2(-22, -2)
		var rgt := c + Vector2(22, -2)
		_poly(img, PackedVector2Array([top, rgt, c + Vector2(0, -2)]), Color("ffb3d4"))
		_poly(img, PackedVector2Array([top, c + Vector2(0, -2), lft]), Color("b5e3ff"))
		_poly(img, PackedVector2Array([lft, c + Vector2(0, -2), bot]), Color("c9b3ff"))
		_poly(img, PackedVector2Array([rgt, bot, c + Vector2(0, -2)]), Color("b6f0cf"))
	return img


## Verso ilustrado independente: não regrava as molduras aprovadas.
static func _back() -> Image:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			var edge := _box(p, Rect2(2, 2, SIZE - 4, SIZE - 4), 30.0)
			if edge > 0: continue
			var grain := sin(p.x * 0.048 + sin(p.y * 0.015) * 3.0) * 0.025 + sin(p.x * 0.22) * 0.012
			var col := Color("b77c49").lightened(grain + (1.0 - p.y / SIZE) * 0.12)
			var inner := _box(p, Rect2(24, 24, SIZE - 48, SIZE - 48), 22.0)
			if absf(inner) < 4: col = Color("ecc994")
			# Almofada e quatro dedinhos da pata, gravados na madeira.
			var pad := ((p - Vector2(264, 307)) / Vector2(83, 67)).length() < 1.0
			for toe: Vector2 in [Vector2(180, 219), Vector2(231, 184), Vector2(293, 184), Vector2(345, 219)]:
				pad = pad or ((p - toe) / Vector2(28, 38)).length() < 1.0
			if pad: col = Color("f5ddac")
			image.set_pixel(x, y, Color(col.r, col.g, col.b, _cov(edge)))
	return image
