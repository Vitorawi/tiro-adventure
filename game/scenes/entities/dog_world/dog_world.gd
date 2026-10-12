class_name DogWorld
extends Hotspot
## Tiro pequeno no Mundo. Anda sozinho entre pontos do chão, vai à tigela
## quando está com fome e dorme no sofá. Tocar nele abre a Tela do Pet.

const SPRITE_DIR := "res://assets/sprites/characters/tiro_world/"
const SPRITE_SCALE := 2.0
## Distância (px de tela) do centro do sprite até as patas.
const FEET_OFFSET := 32.0
const HUNGRY := 30.0

var walk_points: Array[Vector2] = []
var bowl_point := Vector2.ZERO
var sleep_point := Vector2.ZERO

var _facing := "south"
var _sprite: AnimatedSprite2D


func _ready() -> void:
	size = Vector2(64, 64)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.scale = Vector2.ONE * SPRITE_SCALE
	_sprite.position = Vector2(size.x / 2.0, size.y - FEET_OFFSET)
	add_child(_sprite)
	_play_idle("south")
	tapped.connect(func() -> void: Events.screen_requested.emit(&"pet"))
	_brain()


## Posiciona o Tiro com as patas no ponto dado.
func place_at(point: Vector2) -> void:
	position = point - Vector2(size.x / 2.0, size.y)


func _feet() -> Vector2:
	return position + Vector2(size.x / 2.0, size.y)


func _brain() -> void:
	await get_tree().process_frame
	while is_inside_tree():
		var dog := GameState.dog
		if dog.sleeping:
			await _walk_to(sleep_point)
			_play_idle("south")
			await _wait(2.0)
			continue
		await _wait(randf_range(1.5, 4.0))
		if not is_inside_tree() or walk_points.is_empty():
			continue
		var target: Vector2 = walk_points.pick_random()
		if dog.get_need("hunger", GameState.now()) < HUNGRY and randf() < 0.6:
			target = bowl_point
		await _walk_to(target)


func _walk_to(point: Vector2) -> void:
	var delta := point - _feet()
	if delta.length() < 4.0 or not is_inside_tree():
		return
	_play_walk(delta)
	var energy := GameState.dog.get_need("energy", GameState.now())
	var speed := lerpf(40.0, 90.0, energy / 100.0)
	var tween := create_tween()
	tween.tween_property(self, "position", point - Vector2(size.x / 2.0, size.y), delta.length() / speed)
	await tween.finished
	_play_idle(_facing)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _play_walk(delta: Vector2) -> void:
	if absf(delta.x) > absf(delta.y) * 1.2:
		_facing = "east" if delta.x > 0.0 else "west"
	else:
		_facing = "south" if delta.y > 0.0 else "north"
	# Só existe walk para leste; oeste é o leste espelhado.
	var anim := "walk_" + ("east" if _facing == "west" else _facing)
	_sprite.flip_h = _facing == "west"
	if _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)


func _play_idle(direction: String) -> void:
	var anim := "idle_" + direction
	_sprite.flip_h = false
	if _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for direction: String in ["south", "east", "north", "west"]:
		var path := SPRITE_DIR + "rotations/%s.png" % direction
		if ResourceLoader.exists(path):
			frames.add_animation("idle_" + direction)
			frames.add_frame("idle_" + direction, load(path))
	for direction: String in ["south", "east", "north"]:
		var folder := SPRITE_DIR + "walk/%s/" % direction
		var files := Array(ResourceLoader.list_directory(folder))
		files.sort()
		var anim := "walk_" + direction
		for file: String in files:
			if file.ends_with(".png"):
				if not frames.has_animation(anim):
					frames.add_animation(anim)
					frames.set_animation_speed(anim, 10.0)
				frames.add_frame(anim, load(folder + file))
	return frames
