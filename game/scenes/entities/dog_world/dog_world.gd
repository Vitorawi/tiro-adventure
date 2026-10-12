class_name DogWorld
extends Hotspot
## Tiro pequeno no Mundo. Anda sozinho entre pontos do chão, vai à tigela
## quando está com fome, dorme no sofá, senta e late de vez em quando.
## Tocar nele abre a Tela do Pet.
##
## Sprites (PixelLab) em SPRITE_DIR:
##   rotations/<direção>.png               pose parada por direção
##   <ação>/<direção>/frame_XX.png         animações (walk, idle, sit, bark, sleep, eat)
## Direções que faltam usam o espelho (oeste <-> leste) ou qualquer outra disponível.

const SPRITE_DIR := "res://assets/sprites/characters/tiro_world/"
const SPRITE_SCALE := 1.0
## Distância (px) do centro do canvas do sprite até as patas.
const FEET_OFFSET := 26.0
const HUNGRY := 30.0
## Ações em loop; as demais (sit, sleep, bark) tocam uma vez e param na última pose.
const LOOPING := ["walk", "idle", "eat"]
const MIRROR := { "west": "east", "east": "west" }

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
	_sprite.position = Vector2(size.x / 2.0, size.y - FEET_OFFSET * SPRITE_SCALE)
	add_child(_sprite)
	_play("idle", "south")
	tapped.connect(func() -> void: Events.screen_requested.emit(&"pet"))
	_brain()


## Posiciona o Tiro com as patas no ponto dado.
func place_at(point: Vector2) -> void:
	position = point - Vector2(size.x / 2.0, size.y)


func _feet() -> Vector2:
	return position + Vector2(size.x / 2.0, size.y)


# --- Comportamento -----------------------------------------------------------

func _brain() -> void:
	await get_tree().process_frame
	while is_inside_tree():
		var dog := GameState.dog
		if dog.sleeping:
			await _walk_to(sleep_point)
			_play("sleep", "east")
			await _wait(2.0)
			continue
		if dog.get_need("hunger", GameState.now()) < HUNGRY and randf() < 0.6:
			await _walk_to(bowl_point)
			_play("eat", "east")
			await _wait(3.0)
			continue
		await _idle_moment()
		if is_inside_tree() and not walk_points.is_empty():
			await _walk_to(walk_points.pick_random())


func _idle_moment() -> void:
	var roll := randf()
	if roll < 0.25:
		_play("sit", _facing)
		await _wait(randf_range(3.0, 6.0))
	elif roll < 0.35:
		_play("bark", "south")
		await _wait(1.5)
	else:
		_play("idle", _facing)
		await _wait(randf_range(1.5, 4.0))


func _walk_to(point: Vector2) -> void:
	var delta := point - _feet()
	if delta.length() < 4.0 or not is_inside_tree():
		return
	if absf(delta.x) > absf(delta.y) * 1.2:
		_facing = "east" if delta.x > 0.0 else "west"
	else:
		_facing = "south" if delta.y > 0.0 else "north"
	_play("walk", _facing)
	var energy := GameState.dog.get_need("energy", GameState.now())
	var speed := lerpf(35.0, 80.0, energy / 100.0)
	var tween := create_tween()
	tween.tween_property(self, "position", point - Vector2(size.x / 2.0, size.y), delta.length() / speed)
	await tween.finished
	_play("idle", _facing)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


# --- Animação ----------------------------------------------------------------

## Toca "<ação>_<direção>"; sem ela, tenta o espelho e depois qualquer direção.
func _play(action: String, direction: String) -> void:
	var frames := _sprite.sprite_frames
	var flip := false
	var anim := "%s_%s" % [action, direction]
	if not frames.has_animation(anim) and MIRROR.has(direction):
		anim = "%s_%s" % [action, MIRROR[direction]]
		flip = true
	if not frames.has_animation(anim):
		flip = false
		anim = ""
		for candidate in frames.get_animation_names():
			if candidate.begins_with(action + "_"):
				anim = candidate
				break
	if anim == "":
		anim = "pose_" + direction
	if not frames.has_animation(anim):
		return
	if _sprite.animation == anim and _sprite.flip_h == flip:
		return  # já está tocando/parado nessa pose (não reinicia "deitar", "sentar")
	_sprite.flip_h = flip
	_sprite.play(anim)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for file in ResourceLoader.list_directory(SPRITE_DIR + "rotations/"):
		if file.ends_with(".png"):
			var anim := "pose_" + file.get_basename()
			frames.add_animation(anim)
			frames.add_frame(anim, load(SPRITE_DIR + "rotations/" + file))
	for action in ResourceLoader.list_directory(SPRITE_DIR):
		if not action.ends_with("/") or action == "rotations/":
			continue
		action = action.trim_suffix("/")
		for direction in ResourceLoader.list_directory(SPRITE_DIR + action + "/"):
			if direction.ends_with("/"):
				_add_animation(frames, action, direction.trim_suffix("/"))
	return frames


func _add_animation(frames: SpriteFrames, action: String, direction: String) -> void:
	var folder := "%s%s/%s/" % [SPRITE_DIR, action, direction]
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	var anim := "%s_%s" % [action, direction]
	frames.add_animation(anim)
	frames.set_animation_speed(anim, 8.0)
	frames.set_animation_loop(anim, action in LOOPING)
	for file: String in files:
		if file.ends_with(".png"):
			frames.add_frame(anim, load(folder + file))
