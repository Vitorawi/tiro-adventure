extends SceneTree
## Gera o "Lenço da nossa turma" (community_ribbon) a partir do lenço vermelho: mesma máscara, mesmas
## âncoras e os mesmos quadros por pose; só muda a cor (vermelho → verde-água). Etapa 22 da economia R1.
## Uso: godot --headless --path game -s ../tools/ribbon_recolor.gd

const PET := "res://assets/sprites/characters/tiro_pet/overlays/"
const HUE := 0.46


func _init() -> void:
	var count := 0
	count += _recolor(PET + "red_scarf.png", PET + "community_ribbon.png")
	var base := ProjectSettings.globalize_path(PET + "red_scarf")
	for clip: String in DirAccess.get_directories_at(base):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PET + "community_ribbon/" + clip))
		for file: String in DirAccess.get_files_at(base + "/" + clip):
			if file.ends_with(".png"):
				count += _recolor(PET + "red_scarf/%s/%s" % [clip, file], PET + "community_ribbon/%s/%s" % [clip, file])
	count += _recolor("res://assets/sprites/ui/icons/outfit_red_scarf.png", "res://assets/sprites/ui/icons/outfit_community_ribbon.png")
	print("RIBBON: %d imagens" % count)
	quit()


func _recolor(from: String, to: String) -> int:
	var image := Image.load_from_file(ProjectSettings.globalize_path(from))
	if image == null:
		push_error("sem imagem " + from)
		return 0
	image.convert(Image.FORMAT_RGBA8)
	for y: int in image.get_height():
		for x: int in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.0 and c.s > 0.15:
				image.set_pixel(x, y, Color.from_hsv(fposmod(c.h + HUE, 1.0), c.s, c.v, c.a))
	image.save_png(ProjectSettings.globalize_path(to))
	return 1
