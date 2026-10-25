extends SceneTree
## Gera as peças da tela inicial "madeira ilustrada" em game/assets/sprites/ui/home/ a partir das
## pranchas recortadas em IUREF/MAIN (r) e IUREF/MAIN2 (k). Cada peça sai com ~3x o tamanho de exibição.
## Uso: godot --headless --path game -s ../tools/home_art.gd   (depois: godot --headless --path game --import)

const OUT := "res://assets/sprites/ui/home/"


func _src(kind: String, n: int) -> Image:
	var folder := "MAIN" if kind == "r" else "MAIN2"
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://../IUREF/%s/GUI V1 Edit-v1_%d.png" % [folder, n]))
	if image == null:
		push_error("faltou %s%d" % [kind, n])
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


## Cartão da missão sem o desenho de dentro: copia a coluna limpa x=240 (creme com o degradê) sobre o resto.
func _clean_card(image: Image) -> Image:
	for y in range(21, 237):
		var c := image.get_pixel(240, y)
		for x in range(28, 416):
			image.set_pixel(x, y, c)
	return image


## Balão do desejo sem o pedaço de bolinha que veio cortado embaixo do recorte.
func _clean_bubble(image: Image) -> Image:
	for y in range(377, image.get_height()):
		for x in range(0, 170):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	# Esvazia o miolo (osso e brilhos): a arte do jogo põe o ícone do desejo atual no lugar.
	for y in range(48, 326):
		var left := -1
		var right := -1
		var x := 0
		while x < image.get_width() and image.get_pixel(x, y).a < 0.5:
			x += 1
		while x < image.get_width() and image.get_pixel(x, y).get_luminance() < 0.45:
			x += 1
		left = x + 8
		x = image.get_width() - 1
		while x > 0 and image.get_pixel(x, y).a < 0.5:
			x -= 1
		while x > 0 and image.get_pixel(x, y).get_luminance() < 0.45:
			x -= 1
		right = x - 8
		var cream := image.get_pixel(left, y)
		for fx in range(left, right + 1):
			image.set_pixel(fx, y, cream)
	return image


func _init() -> void:
	_save(_src("r", 34), "home_room.png", 900)
	_save(_src("k", 9), "home_avatar_frame.png", 240)
	var plaque := _src("r", 4)
	print("WOOD_PATCH = ", plaque.get_pixel(530, 150).to_html(false))
	_save(plaque, "home_plaque.png", 504)
	# Barras: alturas finais 3x (track 54, fill 48); o jogo desenha com NinePatchRect em escala 1/3.
	var track := _src("r", 18)
	_save(track, "home_bar_track.png", int(round(344.0 * 54 / 66)), 54)
	var fill := _src("r", 19)
	_save(fill, "home_bar_fill.png", int(round(321.0 * 48 / 67)), 48)
	_save(_src("k", 4), "home_coins.png", 258)
	_save(_src("r", 15), "home_settings.png", 114)
	_save(_clean_card(_src("r", 6)), "home_quest_card.png", 420)
	_save(_clean_bubble(_src("r", 5)), "home_wish_bubble.png", 282)
	_save(_src("k", 26), "home_bubble_dot_big.png", 39)
	_save(_src("k", 27), "home_bubble_dot_small.png", 24)
	_save(_src("r", 9), "home_notebook.png", 192)
	_save(_src("r", 7), "home_care_heart.png", 192)
	_save(_src("k", 23), "home_badge.png", 72)
	# Bandeja de necessidades: tábua com 4 espaços vazios, quadradinho creme e um ícone por necessidade.
	_save(_src("k", 1), "home_needs_tray_empty.png", 594)
	_save(_src("k", 12), "home_need_tile.png", 114)
	for pair: Array in [["hunger", 28], ["happiness", 29], ["energy", 30], ["hygiene", 23]]:
		var icon := _src("r", int(pair[1]))
		var longest := maxi(icon.get_width(), icon.get_height())
		_save(icon, "home_need_%s.png" % pair[0], int(round(66.0 * icon.get_width() / longest)), int(round(66.0 * icon.get_height() / longest)))
	_save(_src("r", 10), "home_care_label.png", 216)
	# Rodapé em peças: tábua lisa, encaixe creme, ícone e pílula do nome por aba (a aba ativa sobe sozinha).
	_save(_src("k", 7), "home_tabbar.png", 1080, 311)
	_save(_src("k", 13), "home_tab_socket.png", 216)
	_save(_src("k", 21), "home_tab_label.png", 213)
	for pair: Array in [["pet", 26], ["map", 22], ["tasks", 16], ["bag", 13]]:
		var tab_icon := _src("r", int(pair[1]))
		var longest := maxi(tab_icon.get_width(), tab_icon.get_height())
		_save(tab_icon, "home_tab_%s.png" % pair[0], int(round(138.0 * tab_icon.get_width() / longest)), int(round(138.0 * tab_icon.get_height() / longest)))
	quit()
