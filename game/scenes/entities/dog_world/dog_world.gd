class_name DogWorld
extends Node2D
## Tiro pequeno no Mundo. A origem do nó fica nas patas (usada na ordenação por Y).
## Anda sozinho pelo piso desviando dos móveis (caminho calculado pela sala),
## vai à tigela quando está com fome, dorme no sofá, senta e late de vez em quando.
##
## Sprites (PixelLab) em SPRITE_DIR:
##   rotations/<direção>.png               pose parada por direção
##   <ação>/<direção>/frame_XX.png         animações (walk, idle, sit, bark, sleep, eat)
## Direções que faltam usam o espelho (oeste <-> leste) ou qualquer outra disponível.

const SPRITE_DIR := "res://assets/sprites/characters/tiro_world/"
## Distância (px) do centro do canvas do sprite até as patas.
const FEET_OFFSET := 26.0
const HUNGRY := 30.0
## Ações em loop; as demais (sit, sleep, bark) tocam uma vez e param na última pose.
const LOOPING := ["walk", "idle", "eat"]
const MIRROR := { "west": "east", "east": "west" }
## Sombra oval sob as patas (raio em px e achatamento vertical).
const SHADOW_RADIUS := 17.0
const SHADOW_SQUASH := 0.4
const SHADOW_COLOR := Color(0.12, 0.05, 0.02, 0.5)

var room: HouseRoom
var bowl_point := Vector2.ZERO
## Lugar de dormir (em cima do sofá) e o ponto no chão, na frente dele, por onde sobe/desce.
var sleep_point := Vector2.ZERO
var sleep_approach := Vector2.ZERO

var _facing := "south"
var _on_sofa := false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.position = Vector2(0.0, -FEET_OFFSET)
	add_child(_sprite)
	_play("idle", "south")
	if position.is_equal_approx(sleep_point):
		_set_on_sofa(true)
	_brain()


func _draw() -> void:
	# Desenhada antes dos filhos, então fica embaixo do sprite.
	draw_set_transform(Vector2(0.0, -1.0), 0.0, Vector2(1.0, SHADOW_SQUASH))
	draw_circle(Vector2.ZERO, SHADOW_RADIUS, SHADOW_COLOR, true, -1.0, false)
	draw_set_transform(Vector2.ZERO)


## Área de toque em volta do Tiro (coordenadas do mundo).
func hit_test(point: Vector2) -> bool:
	return Rect2(position + Vector2(-24.0, -54.0), Vector2(48.0, 58.0)).has_point(point)


# --- Comportamento -----------------------------------------------------------

func _brain() -> void:
	await get_tree().process_frame
	while is_inside_tree():
		var dog := GameState.dog
		if dog.sleeping:
			if not _on_sofa:
				await _go_to(sleep_approach)
				_set_on_sofa(true)
				await _step_to(sleep_point)
			_play("sleep", "east")
			await _wait(2.0)
			continue
		if _on_sofa:
			await _step_to(sleep_approach)
			_set_on_sofa(false)
		if dog.get_need("hunger", GameState.now()) < HUNGRY and randf() < 0.6:
			await _go_to(bowl_point)
			_play("eat", "east")
			await _wait(3.0)
			continue
		await _idle_moment()
		if is_inside_tree():
			await _go_to(room.random_floor_point())


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


## Em cima do sofá o Tiro é desenhado na frente dele (z_index), inclusive
## enquanto sobe e desce pelo ponto da frente.
func _set_on_sofa(value: bool) -> void:
	_on_sofa = value
	z_index = 1 if value else 0


## Anda até o ponto pelo piso, desviando dos móveis.
func _go_to(target: Vector2) -> void:
	if position.distance_to(target) < 4.0 or not is_inside_tree():
		return
	var path := _simplify(room.find_path(position, target))
	path.append(target)
	for point in path:
		await _step_to(point)
		if not is_inside_tree():
			return
	_play("idle", _facing)


func _step_to(point: Vector2) -> void:
	var delta := point - position
	if delta.length() < 1.0:
		return
	if absf(delta.x) > absf(delta.y) * 1.2:
		_facing = "east" if delta.x > 0.0 else "west"
	else:
		_facing = "south" if delta.y > 0.0 else "north"
	_play("walk", _facing)
	var energy := GameState.dog.get_need("energy", GameState.now())
	var speed := lerpf(35.0, 80.0, energy / 100.0)
	var tween := create_tween()
	tween.tween_property(self, "position", point, delta.length() / speed)
	await tween.finished


## Remove pontos intermediários em linha reta (caminho da grade vem célula a célula).
func _simplify(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() < 3:
		return path
	var result := PackedVector2Array([path[0]])
	for i in range(1, path.size() - 1):
		var before := (path[i] - path[i - 1]).normalized()
		var after := (path[i + 1] - path[i]).normalized()
		if not before.is_equal_approx(after):
			result.append(path[i])
	result.append(path[path.size() - 1])
	return result


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
