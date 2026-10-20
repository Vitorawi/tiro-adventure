extends SceneTree
## Gera o "Lacinho do topete" (topknot_bow) a partir do lacinho amarelo: mesma máscara, mesmas
## âncoras e os mesmos quadros por pose; só muda a cor (amarelo → vermelho). Etapa 10 do plano Tiro.
## Uso: godot --headless --path game -s ../tools/bow_recolor.gd

const PET := "res://assets/sprites/characters/tiro_pet/overlays/"
const HUE := -0.15


func _init() -> void:
	var count := 0
	count += _recolor(PET + "yellow_bow.png", PET + "topknot_bow.png")
	var base := ProjectSettings.globalize_path(PET + "yellow_bow")
	for clip: String in DirAccess.get_directories_at(base):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PET + "topknot_bow/" + clip))
		for file: String in DirAccess.get_files_at(base + "/" + clip):
			if file.ends_with(".png"):
				count += _recolor(PET + "yellow_bow/%s/%s" % [clip, file], PET + "topknot_bow/%s/%s" % [clip, file])
	count += _recolor("res://assets/sprites/ui/icons/outfit_yellow_bow.png", "res://assets/sprites/ui/icons/outfit_topknot_bow.png")
	print("BOW: %d imagens" % count)
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
