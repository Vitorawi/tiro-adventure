extends SceneTree
## Gera `step_go_locked.png`: o botão verde (`step_go.png`, 548x120) em versão APAGADA para o botão bloqueado de madeira
## (dessaturado, clareado e sem o brilho do verde: bege acinzentado). Mesma geometria do original, para o NinePatch coincidir.
## Uso: godot --headless --path game -s ../tools/locked_button_art.gd   (depois: godot --headless --path game --import
## e `mipmaps/generate=true` em step_go_locked.png.import)

const DIR := "res://assets/sprites/ui/home/"
const TINT := Color(0.80, 0.74, 0.64)


func _init() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(DIR + "step_go.png"))
	if image == null:
		push_error("falta step_go.png")
		quit(1)
		return
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var l := c.get_luminance()
			var gray := Color(l, l * 0.97, l * 0.9, c.a)
			# Achata o contraste (sem brilho forte) e puxa para o bege.
			var flat := Color(lerpf(0.55, gray.r, 0.55), lerpf(0.5, gray.g, 0.55), lerpf(0.42, gray.b, 0.55), c.a)
			image.set_pixel(x, y, flat.lerp(Color(TINT, c.a), 0.4))
	image.save_png(ProjectSettings.globalize_path(DIR + "step_go_locked.png"))
	print("step_go_locked.png %dx%d" % [image.get_width(), image.get_height()])
	quit()
