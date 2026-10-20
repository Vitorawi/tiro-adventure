extends SceneTree
## Plano "Tiro no centro", etapa 01: prova de identidade do Tiro. NÃO é teste.
## Monta a paleta, os candidatos exatos (método b), alinha a linha dos pés e grava as pranchas em
## build/art/tiro_fases/. Duas fases:
##   & $env:GODOT_BIN --headless --path game -s res://tests/growth_art_shots.gd -- --step=prep
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/growth_art_shots.gd -- --step=boards
## "prep" só mexe em imagens (pode ser headless). "boards" desenha com os shaders: rode SEM --headless.

const OUT := "res://../build/art/tiro_fases/"
const SPRITES := "res://assets/sprites/"
const ADULT := {
	"pet": "characters/tiro_pet/idle_breathe/frame_00.png",
	"front": "characters/tiro_pet/tiro_pet_idle_front.png",
	"world": "characters/tiro_world/rotations/south.png",
	"hud": "ui/icons/hud_tiro.png",
}
## Destinos definitivos de cada corpo (etapa 01, item 8). Nenhum código usa ainda.
const BODY_FILES := {
	"pet": "characters/tiro_pet_%s/idle_breathe/frame_00.png",
	"front": "characters/tiro_pet_%s/tiro_pet_%s_idle_front.png",
	"world": "characters/tiro_world_%s/rotations/south.png",
	"hud": "ui/icons/hud_tiro_%s.png",
}
## Recorte da cabeça usado no retrato do HUD (o mesmo do adulto, ver ART_PIPELINE "Etapa 03").
const HUD_CROP := Rect2i(74, 38, 98, 98)
const HUD_SIZE := 44
const HUD_AT := Vector2i(2, 3)

var step := "prep"
var board_bg := Color(0.93, 0.91, 0.86)


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--step="):
			step = arg.trim_prefix("--step=")
	_run.call_deferred()


func _run() -> void:
	var saver: Node = root.get_node_or_null("SaveManager")
	if saver != null and saver.has_method("_schedule_save"):
		var events: Node = root.get_node("Events")
		var cb := Callable(saver, "_schedule_save")
		if events.state_changed.is_connected(cb):
			events.state_changed.disconnect(cb)
	DirAccess.make_dir_recursive_absolute(_abs("cand"))
	match step:
		"prep":
			_prep()
		"install":
			_install()
		"boards":
			await _boards()
	quit()


# ---------------------------------------------------------------- utilidades

func _abs(rel: String) -> String:
	return ProjectSettings.globalize_path(OUT + rel)


func _load_png(path: String) -> Image:
	var img := Image.new()
	var err := img.load(path)
	if err != OK:
		push_error("não abriu %s" % path)
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img


func _adult(key: String) -> Image:
	return _load_png(ProjectSettings.globalize_path(SPRITES + ADULT[key]))


func _cand(name: String) -> Image:
	var path := _abs("cand/%s.png" % name)
	if not FileAccess.file_exists(path):
		return null
	return _load_png(path)


## Linha mais baixa com pixel opaco (a linha dos pés).
func _feet_row(img: Image) -> int:
	for y in range(img.get_height() - 1, -1, -1):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				return y
	return -1


func _bbox(img: Image) -> Rect2i:
	return img.get_used_rect()


## Desloca o desenho para a linha dos pés e o centro horizontal da referência.
func _align(img: Image, ref: Image) -> Image:
	var dy := _feet_row(ref) - _feet_row(img)
	var rb := _bbox(ref)
	var ib := _bbox(img)
	var dx := int(round((rb.position.x + rb.size.x * 0.5) - (ib.position.x + ib.size.x * 0.5)))
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(dx, dy))
	return out


## Cores opacas únicas, da mais escura para a mais clara.
func _colors(images: Array) -> Array[Color]:
	var seen := {}
	for img: Image in images:
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5:
					seen[c.to_html(false)] = true
	var out: Array[Color] = []
	for hex: String in seen:
		out.append(Color(hex))
	out.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
	return out


## Sela azul-acinzentada do adulto: pouca saturação e brilho médio (mesma regra do tiro_coat.gdshader).
func _is_saddle(c: Color) -> bool:
	return c.a > 0.5 and c.s <= 0.22 and c.v >= 0.22 and c.v <= 0.66


## Método b (edição exata): troca a sela cinza pelos pretos da própria paleta, pela ordem de brilho.
func _blacken(img: Image, darks: Array[Color]) -> Image:
	var out := img.duplicate() as Image
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if _is_saddle(c):
				var t := clampf((c.v - 0.22) / 0.44, 0.0, 1.0)
				var d := darks[mini(int(t * darks.size()), darks.size() - 1)]
				out.set_pixel(x, y, Color(d, c.a))
	return out


## Reduz por vizinho mais próximo, mantendo a linha dos pés e o centro.
func _shrink(img: Image, factor: float) -> Image:
	var used := img.get_used_rect()
	var part := img.get_region(used)
	var w := maxi(1, int(round(used.size.x * factor)))
	var h := maxi(1, int(round(used.size.y * factor)))
	part.resize(w, h, Image.INTERPOLATE_NEAREST)
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var at := Vector2i(used.position.x + (used.size.x - w) / 2, used.end.y - h)
	out.blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), at)
	return out


## Pretos que já existem na paleta do Tiro (contorno e sombras), do mais escuro ao mais claro.
func _darks(palette: Array[Color]) -> Array[Color]:
	var out: Array[Color] = []
	for c in palette:
		if c.v < 0.2:
			out.append(c)
	return out


# ---------------------------------------------------------------- prep

func _prep() -> void:
	var adults: Array = []
	for key: String in ADULT:
		adults.append(_adult(key))
	var palette := _colors(adults)
	var cols := 16
	var rows := int(ceil(palette.size() / float(cols)))
	var swatch := Image.create(cols * 16, rows * 16, false, Image.FORMAT_RGBA8)
	var strip := Image.create(palette.size(), 1, false, Image.FORMAT_RGBA8)
	var hexes: PackedStringArray = []
	for i in palette.size():
		swatch.fill_rect(Rect2i((i % cols) * 16, (i / cols) * 16, 16, 16), palette[i])
		strip.set_pixel(i, 0, palette[i])
		hexes.append("#" + palette[i].to_html(false))
	swatch.save_png(_abs("paleta.png"))
	strip.save_png(_abs("paleta_strip.png"))
	var f := FileAccess.open(_abs("paleta.txt"), FileAccess.WRITE)
	f.store_string(" ".join(hexes) + "\n")
	f.close()
	print("paleta: %d cores" % palette.size())

	var darks := _darks(palette)
	print("pretos da paleta: %d" % darks.size())
	# Os mesmos pretos alimentam o tiro_coat.gdshader (coat = 0 = sela do jovem).
	var darks_img := Image.create(darks.size(), 1, false, Image.FORMAT_RGBA8)
	for i in darks.size():
		darks_img.set_pixel(i, 0, darks[i])
	darks_img.save_png(ProjectSettings.globalize_path(DARKS_PNG))
	var pet := _adult("pet")
	# Método b: edição exata sobre o quadro atual.
	_blacken(pet, darks).save_png(_abs("cand/b_young_1.png"))
	_shrink(_blacken(pet, darks), 0.86).save_png(_abs("cand/b_puppy_1.png"))
	# Escolhidos (c + b): forma pelo inpaint, sela pelos pretos da paleta.
	for pair: Array in [["c_puppy_2", "cb_puppy"], ["c_young_1", "cb_young"]]:
		var img := _cand(pair[0])
		if img != null:
			_blacken(img, darks).save_png(_abs("cand/%s.png" % pair[1]))
	# Todos os candidatos alinhados aos pés do adulto do mesmo tamanho.
	for file: String in DirAccess.get_files_at(_abs("cand")):
		if not file.ends_with(".png") or file.begins_with("al_"):
			continue
		var img := _load_png(_abs("cand/" + file))
		for key: String in ADULT:
			var ref := _adult(key)
			if img.get_size() == ref.get_size():
				_align(img, ref).save_png(_abs("cand/al_" + file))
				print("%s: pés %d → %d" % [file, _feet_row(img), _feet_row(ref)])
				break
	# Finais: quadro base já reduzido à paleta (final/<corpo>_pet.png); 160 e 64 vêm de q_*; retrato pelo recorte.
	DirAccess.make_dir_recursive_absolute(_abs("final"))
	# Filhote escolhido pelo Vitor (opção 1): redução local para a paleta, cor a cor (a opção 1 já sai do
	# PixelLab com 9 cores; o 160 e o 64 foram feitos com ela de referência).
	for pair: Array in [["al_a_puppy_1", "puppy_pet"], ["al_r1_puppy_front", "puppy_front"], ["al_r1_puppy_world", "puppy_world"]]:
		var img := _cand(pair[0])
		if img != null:
			_quantize(img, palette).save_png(_abs("final/%s.png" % pair[1]))
	for key: String in ["front", "world"]:
		var path := _abs("final/puppy_%s.png" % key)
		if FileAccess.file_exists(path):
			var img := _load_png(path)
			print("puppy %s: pés %d, cores %d" % [key, _feet_row(img), _colors([img]).size()])
	var hud_check := hud_from(pet)
	print("retrato do adulto refeito pelo recorte = hud_tiro.png: %s" % str(_diff(hud_check, _adult("hud")) == 0))
	for body: String in ["puppy", "young"]:
		for pair: Array in [["front", "q_%s_front"], ["world", "q_%s_world"]]:
			if body == "puppy":
				continue
			var img := _cand((pair[1] as String) % body)
			if img != null:
				_align(img, _adult(pair[0])).save_png(_abs("final/%s_%s.png" % [body, pair[0]]))
		var base_path := _abs("final/%s_pet.png" % body)
		if FileAccess.file_exists(base_path):
			var base := _align(_load_png(base_path), pet)
			base.save_png(base_path)
			hud_from(base).save_png(_abs("final/%s_hud.png" % body))
			print("%s: pés %d, cores %d" % [body, _feet_row(base), _colors([base]).size()])


## Troca cada cor pela mais próxima da paleta (RGB); alfa vira 0 ou 1.
func _quantize(img: Image, palette: Array[Color]) -> Image:
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var cache := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var key := c.to_html(false)
			if not cache.has(key):
				var best := palette[0]
				var dist := INF
				for p in palette:
					var d := (p.r - c.r) ** 2 + (p.g - c.g) ** 2 + (p.b - c.b) ** 2
					if d < dist:
						dist = d
						best = p
				cache[key] = best
			out.set_pixel(x, y, cache[key])
	return out


## Quantos pixels diferem (RGBA 8 bits) entre duas imagens do mesmo tamanho.
func _diff(a: Image, b: Image) -> int:
	if a.get_size() != b.get_size():
		return -1
	var n := 0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if ca.a8 == 0 and cb.a8 == 0:
				continue
			if ca.r8 != cb.r8 or ca.g8 != cb.g8 or ca.b8 != cb.b8 or ca.a8 != cb.a8:
				n += 1
	return n


# ---------------------------------------------------------------- install

## Copia os escolhidos (build/art/tiro_fases/final/<corpo>_<tipo>.png) para as pastas definitivas.
func _install() -> void:
	for body: String in ["puppy", "young"]:
		for key: String in BODY_FILES:
			var src := _abs("final/%s_%s.png" % [body, key])
			if not FileAccess.file_exists(src):
				print("falta %s" % src)
				continue
			var rel: String = BODY_FILES[key]
			rel = rel.replace("%s", body)
			var dst := ProjectSettings.globalize_path(SPRITES + rel)
			DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
			_load_png(src).save_png(dst)
			print("instalado %s" % rel)


## Retrato 48×48: mesmo recorte e redução do adulto.
func hud_from(pet: Image) -> Image:
	var head := pet.get_region(HUD_CROP)
	head.resize(HUD_SIZE, HUD_SIZE, Image.INTERPOLATE_NEAREST)
	var out := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	out.blit_rect(head, Rect2i(Vector2i.ZERO, head.get_size()), HUD_AT)
	return out


# ---------------------------------------------------------------- pranchas

const COAT_SHADER := preload("res://assets/shaders/tiro_coat.gdshader")
const DARKS_PNG := "res://assets/shaders/tiro_coat_darks.png"
const SILHOUETTE_SHADER := preload("res://assets/shaders/silhouette.gdshader")
## Candidatos da prancha de métodos, na ordem numerada (arquivo em cand/al_<id>.png).
const METHODS := [
	["a_puppy_1", "ESCOLHIDO (Vitor) a · edição PixelLab"],
	["b_puppy_1", "b · exata (sela + reduzir)"],
	["c_puppy_1", "c · inpaint orelhas"],
	["c_puppy_2", "c · inpaint orelhas + corpo"],
	["cb_puppy", "c + sela exata"],
	["a_young_1", "a · edição PixelLab"],
	["a_young_2", "a · edição PixelLab (2ª)"],
	["b_young_1", "b · exata (sela preta)"],
	["c_young_1", "c · inpaint corpo"],
	["cb_young", "ESCOLHIDO c + sela exata"],
]


func _tex(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


func _pic(parent: Control, img: Image, at: Vector2, scale: int, material: Material = null) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _tex(img)
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.position = at
	rect.size = Vector2(img.get_size() * scale)
	rect.material = material
	parent.add_child(rect)
	return rect


func _text(parent: Control, text: String, at: Vector2, size: int = 22, color: Color = Color(0.2, 0.16, 0.14)) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _line(parent: Control, from: Vector2, width: float, color: Color) -> void:
	var line := ColorRect.new()
	line.color = color
	line.position = from
	line.size = Vector2(width, 2)
	parent.add_child(line)


func _coat(value: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = COAT_SHADER
	mat.set_shader_parameter("coat", value)
	mat.set_shader_parameter("darks", _tex(_load_png(ProjectSettings.globalize_path(DARKS_PNG))))
	return mat


func _silhouette() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SILHOUETTE_SHADER
	return mat


## Desenha `build` numa SubViewport do tamanho pedido e devolve a imagem.
func _render(size: Vector2i, build: Callable, transparent := false) -> Image:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = transparent
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	var canvas := Control.new()
	canvas.size = Vector2(size)
	if not transparent:
		var bg := ColorRect.new()
		bg.color = board_bg
		bg.size = Vector2(size)
		canvas.add_child(bg)
	vp.add_child(canvas)
	root.add_child(vp)
	build.call(canvas)
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	vp.queue_free()
	return img


func _final(body: String, key: String) -> Image:
	if body == "adult":
		return _adult(key)
	return _load_png(_abs("final/%s_%s.png" % [body, key]))


func _boards() -> void:
	var bodies := ["adult", "young", "puppy"]
	var names := {"adult": "atual (adulto)", "young": "jovem", "puppy": "filhote"}

	# 1) Corpos lado a lado nas quatro telas.
	var corpos := await _render(Vector2i(1620, 1640), func(c: Control) -> void:
		_text(c, "Tiro — prova de identidade (etapa 01): atual | jovem | filhote", Vector2(20, 10), 30)
		for i in bodies.size():
			var body: String = bodies[i]
			var x := 20.0 + i * 540.0
			_text(c, names[body], Vector2(x, 56), 26)
			# Tela do Tiro 256×216 (×2) com a linha dos pés.
			var pet := _final(body, "pet")
			_pic(c, pet, Vector2(x, 96), 2)
			_line(c, Vector2(x, 96 + (_feet_row(pet) + 1) * 2), 512, Color(0.85, 0.2, 0.2, 0.7))
			_text(c, "tela 256×216 (×2) — linha vermelha = pés", Vector2(x, 532), 16)
			# idle_front 160 (×2).
			_pic(c, _final(body, "front"), Vector2(x, 570), 2)
			_text(c, "idle_front 160 (×2)", Vector2(x, 892), 16)
			# Mundo 64 (×4 e ×1).
			var world := _final(body, "world")
			_pic(c, world, Vector2(x, 930), 4)
			_pic(c, world, Vector2(x + 280, 930 + 192), 1)
			_text(c, "mundo 64 (×4 e ×1)", Vector2(x, 1190), 16)
			# Retrato 48 (×4 e ×1).
			var hud := _final(body, "hud")
			_pic(c, hud, Vector2(x, 1230), 4)
			_pic(c, hud, Vector2(x + 220, 1230 + 144), 1)
			_text(c, "retrato 48 (×4 e ×1)", Vector2(x, 1430), 16)
		_text(c, "Mesmos olhos, nariz, língua e máscara do rosto; paleta do Tiro (81 cores); pés na mesma linha.", Vector2(20, 1480), 20)
		_text(c, "Filhote: orelhas caídas, sela preta, corpo fofo. Jovem: orelhas em pé, sela preta, pelo bagunçado.", Vector2(20, 1512), 20)
	)
	corpos.save_png(_abs("prancha_corpos.png"))

	# 2) Candidatos de cada método, numerados.
	var metodos := await _render(Vector2i(1360, 640), func(c: Control) -> void:
		_text(c, "Candidatos por método (a = edição PixelLab, b = edição exata, c = inpaint)", Vector2(20, 8), 26)
		for i in METHODS.size():
			var item: Array = METHODS[i]
			var x := 20.0 + (i % 5) * 268.0
			var y := 50.0 + (i / 5) * 290.0
			var img := _cand("al_" + (item[0] as String))
			if img != null:
				_pic(c, img, Vector2(x, y + 26), 1)
			_text(c, "%d. %s" % [i + 1, item[1]], Vector2(x, y), 16)
		_text(c, "linha de cima: filhote (1–5) · linha de baixo: jovem (6–10)", Vector2(20, 600), 18)
	)
	metodos.save_png(_abs("prancha_metodos.png"))

	# 3) Pelagem do adulto (coat 0 / 0,5 / 1) e silhuetas.
	var adult := _adult("pet")
	var pelagem := await _render(Vector2i(1620, 1100), func(c: Control) -> void:
		_text(c, "Pelagem do adulto (tiro_coat.gdshader) — do preto do jovem (0) ao Azul e Dourado (1)", Vector2(20, 8), 26)
		var coats := [0.0, 0.5, 1.0]
		for i in coats.size():
			var x := 20.0 + i * 540.0
			_text(c, "coat = %s" % str(coats[i]), Vector2(x, 48), 22)
			_pic(c, adult, Vector2(x, 80), 2, _coat(coats[i]))
		_text(c, "Silhuetas (silhouette.gdshader): atual | jovem | filhote", Vector2(20, 530), 26)
		for i in bodies.size():
			var x := 20.0 + i * 540.0
			_pic(c, _final(bodies[i], "pet"), Vector2(x, 570), 2, _silhouette())
			_pic(c, _final(bodies[i], "world"), Vector2(x + 400, 1000), 1, _silhouette())
	)
	pelagem.save_png(_abs("prancha_pelagem.png"))

	# 2b) Uma prancha por corpo, com as opções grandes e numeradas (para o Vitor escolher).
	for group: Array in [["filhote", "Recém-chegado e Filhotinho", 0], ["jovem", "Dentinhos e Aventureiro", 5]]:
		var start: int = group[2]
		var opcoes := await _render(Vector2i(1960, 500), func(c: Control) -> void:
			_text(c, "Opções do %s (fases %s) — atual à esquerda para comparar" % [group[0], group[1]], Vector2(20, 8), 26)
			_text(c, "atual", Vector2(20, 50), 20)
			_pic(c, adult.get_region(Rect2i(56, 4, 144, 192)), Vector2(20, 80), 2)
			for i in 5:
				var item: Array = METHODS[start + i]
				var x := 340.0 + i * 322.0
				_text(c, "%d. %s" % [start + i + 1, item[1]], Vector2(x, 50), 16)
				var img := _cand("al_" + (item[0] as String))
				if img != null:
					_pic(c, img.get_region(Rect2i(56, 4, 144, 192)), Vector2(x, 80), 2)
		)
		opcoes.save_png(_abs("opcoes_%s.png" % group[0]))
	var mocinho := await _render(Vector2i(1960, 500), func(c: Control) -> void:
		_text(c, "Do jovem ao Tiro atual: o preto do jovem vai azulando. Mocinho = 0,3 a 0,7 conforme o cuidado; Azul e Dourado = 1", Vector2(20, 8), 22)
		_text(c, "jovem (10)", Vector2(20, 50), 20)
		_pic(c, _final("young", "pet").get_region(Rect2i(56, 4, 144, 192)), Vector2(20, 80), 2)
		var coats := [0.0, 0.3, 0.5, 0.7, 1.0]
		for i in coats.size():
			var x := 340.0 + i * 322.0
			_text(c, "coat = %s" % str(coats[i]), Vector2(x, 50), 20)
			_pic(c, adult.get_region(Rect2i(56, 4, 144, 192)), Vector2(x, 80), 2, _coat(coats[i]))
	)
	mocinho.save_png(_abs("opcoes_mocinho.png"))

	# 4) coat = 1 tem que ser idêntico ao original, pixel a pixel.
	var same := await _render(adult.get_size(), func(c: Control) -> void:
		_pic(c, adult, Vector2.ZERO, 1, _coat(1.0))
	, true)
	var diff := _diff(same, adult)
	var opaque := 0
	for y in adult.get_height():
		for x in adult.get_width():
			if adult.get_pixel(x, y).a8 > 0:
				opaque += 1
	var report := "coat=1 x frame_00.png: %d pixels diferentes de %d visíveis (%s)\n" % [
		diff, opaque, "IDÊNTICO" if diff == 0 else "DIFERENTE"]
	var zero := await _render(adult.get_size(), func(c: Control) -> void:
		_pic(c, adult, Vector2.ZERO, 1, _coat(0.0))
	, true)
	report += "coat=0 x frame_00.png: %d pixels mudam (só a sela)\n" % _diff(zero, adult)
	var young_saddle := _cand("b_young_1")
	if young_saddle != null:
		report += "coat=0 x adulto com a sela do jovem (b_young_1): %d pixels diferentes\n" % _diff(zero, young_saddle)
	var f := FileAccess.open(_abs("comparacao_coat.txt"), FileAccess.WRITE)
	f.store_string(report)
	f.close()
	print(report)
