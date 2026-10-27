class_name HomeUi
extends RefCounted
## Peças do visual "madeira ilustrada" da tela inicial (HUD, cartão da missão, bandeja de necessidades, balão do
## desejo, caderninho, Cuidar e abas). As imagens ficam em `assets/sprites/ui/home/` (geradas por `tools/home_art.gd`);
## aqui só há ajudantes para montá-las com as mesmas posições do protótipo aprovado (360×780).
## Texto sobre madeira: Fredoka peso 650 (`font_wood.tres`), tema local por tamanho (sem override de fonte).

const DIR := "res://assets/sprites/ui/home/"
const FONT := "res://assets/fonts/font_wood.tres"

static var _themes: Dictionary = {}
static var _heads: Dictionary = {}
## Recorte da cabeça no quadro adulto `idle_breathe/frame_00` (256×216), medido sobre a área opaca dele.
const HEAD_CROP := Rect2i(74, 38, 98, 93)
static var _head_ref := Rect2i()


static func tex(file: String) -> Texture2D:
	return load(DIR + "home_" + file + ".png") as Texture2D


## Imagem estática posta em `rect` (como o protótipo: ignora tamanho próprio e mantém a proporção, centrada).
static func pic(host: Control, file: String, rect: Rect2, node_name: String = "", pixel: bool = false, cover: bool = false) -> TextureRect:
	var result := TextureRect.new()
	result.texture = tex(file)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if cover else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if node_name != "":
		result.name = node_name
	# Peça ilustrada = suave (o projeto é "nearest" por causa da pixel art do mundo).
	result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.position = rect.position
	result.size = rect.size
	host.add_child(result)
	return result


static func theme(px: int, color: Color = Palette.WOOD_INK, outline: Color = Color(0, 0, 0, 0), outline_size: int = 0) -> Theme:
	var key := "%d/%s/%d" % [px, color.to_html(), outline_size]
	if _themes.has(key):
		return _themes[key]
	var result := Theme.new()
	result.default_font = load(FONT) as Font
	result.default_font_size = px
	result.set_color("font_color", "Label", color)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		result.set_color(state, "Button", color)
	if outline_size > 0:
		result.set_color("font_outline_color", "Label", outline)
		result.set_constant("outline_size", "Label", outline_size)
		result.set_color("font_outline_color", "Button", outline)
		result.set_constant("outline_size", "Button", outline_size)
	_themes[key] = result
	return result


## Rótulo centrado em `rect`, com a fonte da madeira. Sem contorno quando `outline_size` é 0.
static func text(host: Control, value: String, rect: Rect2, px: int, color: Color = Palette.WOOD_INK, outline: Color = Palette.WOOD_INK, outline_size: int = 0, node_name: String = "") -> Label:
	var result := Label.new()
	result.text = value
	result.theme = theme(px, color, outline, outline_size)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.autowrap_mode = TextServer.AUTOWRAP_OFF
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.position = rect.position
	result.size = rect.size
	if node_name != "":
		result.name = node_name
	host.add_child(result)
	return result


static func patch(host: Control, rect: Rect2, color: Color, radius: int = 8) -> Panel:
	var result := Panel.new()
	result.add_theme_stylebox_override("panel", UiKit.surface(color, radius))
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.position = rect.position
	result.size = rect.size
	host.add_child(result)
	return result


## Barra em NinePatch guardada com 3x a altura final: o nó fica em escala 1/3 (bordas nítidas em telas densas).
## `margin` é o canto em pixels FINAIS (do tamanho da barra); `rect` também é final.
static func bar(host: Control, file: String, rect: Rect2, margin: int, node_name: String = "") -> NinePatchRect:
	var result := NinePatchRect.new()
	result.texture = tex(file)
	result.patch_margin_left = margin * 3
	result.patch_margin_right = margin * 3
	result.scale = Vector2.ONE / 3.0
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.position = rect.position
	result.size = rect.size * 3.0
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if node_name != "":
		result.name = node_name
	host.add_child(result)
	return result


## Muda o tamanho final de uma barra criada por `bar` (largura/altura em pixels finais).
static func resize_bar(node: NinePatchRect, size_px: Vector2) -> void:
	node.size = size_px * 3.0


## Cabeça do Tiro na fase atual: recorta o quadro parado do corpo atual (a mesma proporção do adulto sobre a área
## opaca do quadro, então filhote e jovem também ficam com as orelhas inteiras). Em cache por corpo.
static func head_texture() -> Texture2D:
	var look := GameState.dog_look()
	var body := str(look.body)
	if _heads.has(body):
		return _heads[body]
	var path := str(look.dir_pet) + "idle_breathe/frame_00.png"
	if not ResourceLoader.exists(path):
		path = str(look.idle_front)
	var frame := load(path) as Texture2D
	if frame == null:
		return null
	var image := frame.get_image()
	if image.is_compressed():
		image.decompress()
	if _head_ref.size == Vector2i.ZERO:
		var adult := load("res://assets/sprites/characters/tiro_pet/idle_breathe/frame_00.png") as Texture2D
		_head_ref = adult.get_image().get_used_rect()
	var used := image.get_used_rect()
	var fx := float(HEAD_CROP.position.x - _head_ref.position.x) / _head_ref.size.x
	var fy := float(HEAD_CROP.position.y - _head_ref.position.y) / _head_ref.size.y
	var fw := float(HEAD_CROP.size.x) / _head_ref.size.x
	var fh := float(HEAD_CROP.size.y) / _head_ref.size.y
	var crop := Rect2i(used.position.x + roundi(fx * used.size.x), used.position.y + roundi(fy * used.size.y), roundi(fw * used.size.x), roundi(fh * used.size.y))
	crop = crop.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var result := ImageTexture.create_from_image(image.get_region(crop))
	_heads[body] = result
	return result
