extends SceneTree
## Gera `home_album.png` (botão do Álbum na home) a partir do botão do caderninho: apaga o livro do miolo da tábua
## (copiando a coluna limpa do degradê) e põe a polaroide de `codex_icon_album.png`, sem distorcer.
## Uso: godot --headless --path game -s ../tools/album_button_art.gd   (depois: godot --headless --path game --import)

const DIR := "res://assets/sprites/ui/home/"


func _init() -> void:
	var base := Image.load_from_file(ProjectSettings.globalize_path(DIR + "home_notebook.png"))
	var icon := Image.load_from_file(ProjectSettings.globalize_path(DIR + "codex_icon_album.png"))
	base.convert(Image.FORMAT_RGBA8)
	icon.convert(Image.FORMAT_RGBA8)
	var w := base.get_width()
	var h := base.get_height()
	print("base %dx%d icone %dx%d" % [w, h, icon.get_width(), icon.get_height()])
	# Apaga o livro: cada linha recebe o pixel limpo da coluna 24 (esquerda do livro, dentro da tábua).
	for y in range(int(h * 0.12), int(h * 0.88)):
		var clean := base.get_pixel(int(w * 0.14), y)
		for x in range(int(w * 0.2), int(w * 0.82)):
			if base.get_pixel(x, y).a > 0.5:
				base.set_pixel(x, y, clean)
	# Polaroide: escala uniforme pelo lado maior, centrada.
	var side := int(h * 0.64)
	var scale := float(side) / maxf(icon.get_width(), icon.get_height())
	icon.resize(int(round(icon.get_width() * scale)), int(round(icon.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	var at := Vector2i((w - icon.get_width()) / 2, int((h - icon.get_height()) / 2.0) - 2)
	# Sombrinha suave embaixo.
	var shadow := icon.duplicate() as Image
	for y in shadow.get_height():
		for x in shadow.get_width():
			var a := shadow.get_pixel(x, y).a
			shadow.set_pixel(x, y, Color(0.25, 0.12, 0.04, a * 0.35))
	base.blend_rect(shadow, Rect2i(Vector2i.ZERO, shadow.get_size()), at + Vector2i(3, 5))
	base.blend_rect(icon, Rect2i(Vector2i.ZERO, icon.get_size()), at)
	base.save_png(ProjectSettings.globalize_path(DIR + "home_album.png"))
	print("home_album.png ok")
	quit()
