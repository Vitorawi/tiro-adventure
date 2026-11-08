class_name DogLook
extends RefCounted
const PUPPY_REFERENCE := "res://assets/sprites/characters/tiro_pet_puppy_animaref/reference.png"

static func pose_texture(body: String) -> Texture2D:
	if body == "puppy": return load(PUPPY_REFERENCE)
	return load(str(Database.growth.bodies[body].dir.pet) + "idle_breathe/frame_00.png")

static func is_illustrated(texture: Texture2D) -> bool:
	if texture is AtlasTexture: return is_illustrated(texture.atlas)
	return texture != null and texture.resource_path.contains("/tiro_pet_puppy_animaref/")
## Liga imagens estáticas ao mesmo estado visual que os animadores, sem material compartilhado.

static func material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = load("res://assets/shaders/tiro_coat.gdshader")
	result.set_shader_parameter("darks", load("res://assets/shaders/tiro_coat_darks.png"))
	_apply(result)
	return result


static func tint(item: CanvasItem) -> void:
	var texture: Texture2D
	if item is TextureRect: texture = item.texture
	elif item is Button: texture = item.icon
	elif item is AnimatedSprite2D and item.sprite_frames != null and item.sprite_frames.has_animation(item.animation) and item.sprite_frames.get_frame_count(item.animation) > 0:
		texture = item.sprite_frames.get_frame_texture(item.animation, item.frame)
	if is_illustrated(texture):
		item.material = null
		item.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		return
	if not item.material is ShaderMaterial:
		item.material = material()
	_apply(item.material as ShaderMaterial)


static func _apply(target: ShaderMaterial) -> void:
	var look := GameState.dog_look()
	target.set_shader_parameter("coat", look.coat)
	target.set_shader_parameter("sheen", look.sheen)
	target.set_shader_parameter("reduced", Motion.reduced)


static func bind(item: CanvasItem, key: String, property: String = "texture") -> void:
	refresh(item, key, property)
	# Método do próprio nó como receptor: a conexão desaparece quando a imagem é liberada.
	if not item.has_meta("dog_look_binding"):
		var binding := DogLookImage.new()
		binding.item = item
		binding.key = key
		binding.property = property
		item.add_child(binding)
		item.set_meta("dog_look_binding", true)


static func refresh(item: CanvasItem, key: String, property: String) -> void:
	item.set(property, load(str(GameState.dog_look()[key])))
	tint(item)


class DogLookImage extends Node:
	var item: CanvasItem
	var key: String
	var property: String
	func _ready() -> void:
		Events.state_changed.connect(_refresh)
	func _refresh() -> void:
		DogLook.refresh(item, key, property)
