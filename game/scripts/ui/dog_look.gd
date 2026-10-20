class_name DogLook
extends RefCounted
## Liga imagens estáticas ao mesmo estado visual que os animadores, sem material compartilhado.

static func material() -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = load("res://assets/shaders/tiro_coat.gdshader")
	result.set_shader_parameter("darks", load("res://assets/shaders/tiro_coat_darks.png"))
	_apply(result)
	return result


static func tint(item: CanvasItem) -> void:
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
