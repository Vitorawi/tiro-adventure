extends SceneTree
## Gera as peças do menu de madeira da horta (FarmDock) em game/assets/sprites/ui/home/ (prefixo farm_) a partir das
## pranchas de IUREF/farm2-v2 (farm2-v2_<n>.png). Cada peça sai com ~3x o tamanho de exibição (o jogo desenha em
## escala 1/3, como as da tela inicial, da Mochila, das Missões e do mini-cartão do passo).
## Uso: godot --headless --path game -s ../tools/farm_tray_art.gd   (depois: godot --headless --path game --import e
## troque mipmaps/generate=true nos farm_*.png.import, como nos outros home_*/mission_*/step_*).
## As linhas "FRAME"/"SLOT" impressas aqui alimentam as constantes de `scripts/ui/farm_dock.gd`.
## Também gera a cenoura nova (farm_carrot.png, grande) e `item_carrot.png` (64 px, ícone de item; sobrescreve o pixel antigo, guardado em item_carrot_pixel_old.png).

const OUT := "res://assets/sprites/ui/home/"
const ICONS := "res://assets/sprites/ui/icons/"
## 3x: o encaixe de 340 px do quadradinho na prancha vira 62 px de exibição.
const K := 0.547
## Centros dos quatro quadradinhos na prancha (x) e a linha dos centros (y), e a meia-largura do recorte.
const CENTERS := [296.0, 680.0, 1060.0, 1440.0]
const CENTER_Y := 266.0


func _src(n: int) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://../IUREF/farm2-v2/farm2-v2_%d.png" % n))
	if image == null:
		push_error("faltou %d" % n)
		quit(1)
	image.convert(Image.FORMAT_RGBA8)
	return image


func _save(image: Image, file: String, width: int, height: int = 0, folder: String = OUT) -> void:
	var h := height if height > 0 else int(round(float(image.get_height()) * width / image.get_width()))
	if image.get_width() != width or image.get_height() != h:
		image.resize(width, h, Image.INTERPOLATE_LANCZOS)
	var path := ProjectSettings.globalize_path(folder + file)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("%s %dx%d" % [file, image.get_width(), image.get_height()])


## Copia a coluna limpa `from_x` sobre o retângulo `area` (apaga desenhos mantendo o degradê vertical do sulco).
func _wipe_cols(image: Image, area: Rect2i, from_x: int) -> void:
	for y in range(area.position.y, area.end.y):
		var c := image.get_pixel(from_x, y)
		for x in range(area.position.x, area.end.x):
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


## Recorte do quadradinho centrado em `center` com meia-largura `half`, já sem o sulco em volta.
func _slot(board: Image, index: int, half: int, tolerance: float) -> Image:
	var cx := int(CENTERS[index])
	var piece := board.get_region(Rect2i(cx - half, int(CENTER_Y) - half, half * 2, half * 2))
	_cut_flood(piece, tolerance)
	return piece


func _init() -> void:
	var board := _src(2)
	# Quadradinhos (antes de apagar a prancha). O selecionado leva o brilho dourado, por isso o recorte é maior.
	_save(_slot(board, 1, 172, 0.14), "farm_slot.png", int(round(344.0 * K)))
	_save(_slot(board, 0, 188, 0.14), "farm_slot_on.png", int(round(376.0 * K)))
	var locked := board.duplicate() as Image
	# O cadeado desenhado sai (o dourado de `_7` vai por cima no jogo): a coluna limpa do bege cobre a área.
	_wipe_cols(locked, Rect2i(1370, 150, 150, 220), 1345)
	_save(_slot(locked, 3, 172, 0.14), "farm_slot_lock.png", int(round(344.0 * K)))

	# Moldura: os quatro quadradinhos viram sulco liso (a coluna de entre dois quadradinhos cobre toda a faixa).
	var frame := board.duplicate() as Image
	_wipe_cols(frame, Rect2i(100, 78, 1525, 376), 493)
	print("FRAME ", frame.get_size(), " escala ", K, " -> ", Vector2(frame.get_width(), frame.get_height()) * K)
	_save(frame, "farm_frame.png", int(round(frame.get_width() * K)), int(round(frame.get_height() * K)))

	_save(_src(6), "farm_x.png", 102)       # X vermelho de madeira (34 de exibição)
	_save(_src(7), "farm_lock.png", 84)     # cadeado dourado (28 de exibição)
	_save(_src(8), "farm_arrow.png", 96)    # seta verde para baixo (32 de exibição)

	# Cenoura nova (substitui a pixel nos menus): grande para o menu e 32 px para ícone de item.
	var carrot := _src(5)
	_save(carrot.duplicate(), "farm_carrot.png", 180)
	var small := carrot.duplicate() as Image
	var used := small.get_used_rect()
	var side := maxi(used.size.x, used.size.y)
	var square := Image.create(side, side, false, Image.FORMAT_RGBA8)
	square.fill(Color(0, 0, 0, 0))
	square.blit_rect(small, used, Vector2i((side - used.size.x) / 2, (side - used.size.y) / 2))
	square.resize(60, 60, Image.INTERPOLATE_LANCZOS)
	var icon := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	icon.fill(Color(0, 0, 0, 0))
	icon.blit_rect(square, Rect2i(Vector2i.ZERO, square.get_size()), Vector2i(2, 2))
	_save(icon, "item_carrot.png", 64, 64, ICONS)  # o pixel antigo ficou em item_carrot_pixel_old.png
	# Guarda as outras duas (não usadas ainda): abóbora e repolho.
	_save(_src(3), "farm_pumpkin.png", 180)
	_save(_src(4), "farm_cabbage.png", 180)
	quit()
