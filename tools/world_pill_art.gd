extends SceneTree
## Gera `world_pill.png` (pílula do mundo no topo esquerdo do mapa): aro de madeira (aba "não escolhida" das Missões) com
## miolo creme (pílula do capítulo), 264x90 (3x; 44 px finais de altura com a escala 1/3 do NinePatch).
## Só junta peças que já existem em game/assets/sprites/ui/home/. Cores/arte vêm de IUREF/painel missao.
## Uso: godot --headless --path game -s ../tools/world_pill_art.gd   (depois: godot --headless --path game --import)

const DIR := "res://assets/sprites/ui/home/"


func _init() -> void:
	var wood := Image.load_from_file(ProjectSettings.globalize_path(DIR + "mission_tab_off.png"))
	var cream := Image.load_from_file(ProjectSettings.globalize_path(DIR + "mission_chapter_pill.png"))
	if wood == null or cream == null:
		push_error("faltam mission_tab_off.png / mission_chapter_pill.png")
		quit(1)
		return
	wood.convert(Image.FORMAT_RGBA8)
	cream.convert(Image.FORMAT_RGBA8)
	wood.resize(264, 90, Image.INTERPOLATE_LANCZOS)
	cream.resize(240, 66, Image.INTERPOLATE_LANCZOS)
	wood.blend_rect(cream, Rect2i(0, 0, 240, 66), Vector2i(12, 10))
	wood.save_png(ProjectSettings.globalize_path(DIR + "world_pill.png"))
	print("world_pill.png 264x90")
	quit()
