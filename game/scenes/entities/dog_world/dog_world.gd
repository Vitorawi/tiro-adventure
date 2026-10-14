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
const LOOPING := ["walk", "idle", "eat", "sniff", "dig"]
const MIRROR := { "west": "east", "east": "west" }
## Sombra oval sob as patas (raio em px e achatamento vertical).
const SHADOW_RADIUS := 17.0
const SHADOW_SQUASH := 0.4
const SHADOW_COLOR := Color(0.12, 0.05, 0.02, 0.5)

var room: RoomView
var bowl_point := Vector2.INF
## Lugar de dormir (em cima do sofá) e o ponto no chão, na frente dele, por onde sobe/desce.
var sleep_point := Vector2.INF
var sleep_approach := Vector2.INF

var _facing := "south"
var _on_sofa := false
var _sprite: AnimatedSprite2D
var _reaction: Dictionary = {}
var _move_tween: Tween
## Balãozinho do desejo sobre a cabeça (some dormindo ou sem pedido).
var _balloon: Node2D
var _balloon_icon: Sprite2D
var _balloon_wish := ""


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.position = Vector2(0.0, -FEET_OFFSET)
	add_child(_sprite)
	_play("idle", "south")
	if position.is_equal_approx(sleep_point):
		_set_on_sofa(true)
	Events.dog_action.connect(_on_care)
	_build_balloon()
	Events.state_changed.connect(_refresh_balloon)
	_refresh_balloon()
	_brain()


func _draw() -> void:
	# Desenhada antes dos filhos, então fica embaixo do sprite.
	draw_set_transform(Vector2(0.0, -1.0), 0.0, Vector2(1.0, SHADOW_SQUASH))
	draw_circle(Vector2.ZERO, SHADOW_RADIUS, SHADOW_COLOR, true, -1.0, false)
	draw_set_transform(Vector2.ZERO)


## O Tiro está com um desejo no balão (tocar nele abre a aba Desejos)?
func has_balloon() -> bool:
	return _balloon.visible


## Área de toque em volta do Tiro (coordenadas do mundo).
func hit_test(point: Vector2) -> bool:
	var local := (point - position) / scale
	if _balloon.visible:
		var screen_scale := get_global_transform_with_canvas().get_scale().abs()
		var half := Vector2(maxf(24.0 / maxf(screen_scale.x, 0.01), 18.0 * _balloon.scale.x), maxf(24.0 / maxf(screen_scale.y, 0.01), 18.0 * _balloon.scale.y))
		if Rect2(_balloon.position - half, half * 2.0).has_point(local):
			return true
	return Rect2(Vector2(-24.0, -54.0), Vector2(48.0, 58.0)).has_point(local)



## Balão do desejo: fundo + ícone; ~40 px no mundo, ~25 px no enquadramento inicial do sítio.
func _build_balloon() -> void:
	_balloon = Node2D.new()
	_balloon.name = "WishBalloon"
	var factor := 1.25 / maxf(scale.x, 0.1)
	_balloon.scale = Vector2.ONE * factor
	_balloon.position = Vector2(0.0, -54.0 - 16.0 * factor - 4.0)
	_balloon.z_index = 3
	var bubble := Sprite2D.new()
	bubble.texture = UiKit.ui_icon("wish_bubble")
	_balloon.add_child(bubble)
	_balloon_icon = Sprite2D.new()
	_balloon_icon.scale = Vector2.ONE * 0.6
	_balloon_icon.position = Vector2(0.0, -2.0)
	_balloon.add_child(_balloon_icon)
	_balloon.visible = false
	add_child(_balloon)
	var bob := create_tween().set_loops()
	bob.tween_property(_balloon, "position:y", _balloon.position.y - 2.0, 0.7)
	bob.tween_property(_balloon, "position:y", _balloon.position.y, 0.7)


func _refresh_balloon() -> void:
	var wish := "" if GameState.dog.sleeping else GameState.balloon_wish()
	_balloon.visible = wish != ""
	if wish != "" and wish != _balloon_wish:
		_balloon_icon.texture = WishUi.icon(wish)
	_balloon_wish = wish

# --- Comportamento -----------------------------------------------------------

func _brain() -> void:
	await get_tree().process_frame
	while is_inside_tree():
		var dog := GameState.dog
		if not room.is_visible_in_tree():
			_reaction.clear()
			await get_tree().create_timer(0.2).timeout
			continue
		if dog.sleeping:
			_reaction.clear()
			if sleep_point == Vector2.INF:
				_play("sleep", _facing)
				await _wait(2.0)
				continue
			# Sofá ou caminha: o Tiro é desenhado na frente do móvel (z_index) enquanto dorme.
			if not _on_sofa:
				await _go_to(sleep_approach)
				_set_on_sofa(true)
			if position.distance_to(sleep_point) > 4.0:
				await _step_to(sleep_point)
			_play("sleep", "east")
			await _wait(2.0)
			continue
		if _on_sofa:
			await _step_to(sleep_approach)
			_set_on_sofa(false)
		if not _reaction.is_empty():
			var reaction := _reaction.duplicate()
			_reaction.clear()
			await _go_to(reaction.target)
			if not _reaction.is_empty() or GameState.dog.sleeping:
				continue
			await _show_reaction(reaction.kind)
			continue
		if bowl_point != Vector2.INF and dog.get_need("hunger", GameState.now()) < HUNGRY and randf() < 0.6:
			await _go_to(bowl_point)
			_play("eat", "east")
			await _wait(3.0)
			continue
		await _idle_moment()
		if is_inside_tree() and _reaction.is_empty():
			await _go_to(room.random_floor_point(position))


## Uma reação por vez; uma ação nova substitui a anterior sem somar caminhos.
func react_at(kind: StringName, target: Vector2) -> void:
	if GameState.dog.sleeping or not room.is_visible_in_tree():
		return
	_reaction = {"kind": kind, "target": room.nearest_floor_point(target)}
	set_meta("last_reaction", kind)


func _on_care(action: StringName) -> void:
	if action in [&"pet", &"play", &"feed", &"bathe", &"wish"]:
		react_at(&"happy", position)


func _show_reaction(kind: StringName) -> void:
	if kind == &"sniff":
		_play("sniff", _facing)
		await _wait(2.0)
		if not _reaction.is_empty() or GameState.dog.sleeping: return
		_play("sit", _facing)
		await _wait(20.0)
		return
	if kind == &"dig":
		_play("dig", _facing)
		await _wait(float(Database.finds.settings.get("dig_seconds", 0.8)))
		return
	if kind == &"harvest" or kind == &"ready":
		# A animação de focinho da comida também serve para cheirar de perto.
		_play("eat", _facing)
		await _wait(1.2)
		if not _reaction.is_empty() or GameState.dog.sleeping:
			return
	_play("bark", "south")
	var heart := Sprite2D.new()
	heart.texture = UiKit.ui_icon("need_happiness")
	heart.position = Vector2(0, -66)
	heart.scale = Vector2.ONE * 0.7
	add_child(heart)
	var float_up := create_tween()
	float_up.tween_property(heart, "position:y", -82.0, 0.8)
	float_up.parallel().tween_property(heart, "modulate:a", 0.0, 0.8)
	float_up.tween_callback(heart.queue_free)
	var hop := create_tween()
	for repeat in 2:
		hop.tween_property(_sprite, "position:y", -FEET_OFFSET - 7.0, 0.16)
		hop.tween_property(_sprite, "position:y", -FEET_OFFSET, 0.16)
	await _wait(0.9)
	if hop.is_running():
		await hop.finished
	_play("idle", _facing)


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
## enquanto sobe e desce pelo ponto da frente. Atenção: z_index vale para a tela
## toda; por isso painéis, avisos e botões por cima da casa têm z_index maior (5+).
func _set_on_sofa(value: bool) -> void:
	_on_sofa = value
	z_index = 1 if value else 0


## Anda até o ponto pelo piso, desviando dos móveis.
func _go_to(target: Vector2) -> void:
	if position.distance_to(target) < 4.0 or not is_inside_tree():
		return
	var path := _simplify(room.find_path(position, target))
	var revision := room.navigation_revision
	# Destino final é a célula livre retornada pela sala. Um alvo bloqueado
	# ou sem caminho nunca vira um trecho direto atravessando o cenário.
	for point in path:
		await _step_to(point)
		if not is_inside_tree() or not _reaction.is_empty() or not room.is_visible_in_tree() or revision != room.navigation_revision:
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
	_move_tween = create_tween()
	var revision := room.navigation_revision
	_move_tween.tween_property(self, "position", point, delta.length() / speed)
	while _move_tween.is_running():
		await get_tree().process_frame
		if revision != room.navigation_revision:
			_move_tween.kill()
			if not _on_sofa:
				position = room.nearest_floor_point(position)
			break
		if not _reaction.is_empty() or not room.is_visible_in_tree() or (GameState.dog.sleeping and not _on_sofa and sleep_point == Vector2.INF):
			_move_tween.kill()
			break


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
	var end := Time.get_ticks_msec() + int(seconds * 1000)
	while Time.get_ticks_msec() < end:
		await get_tree().create_timer(0.1).timeout
		if not _reaction.is_empty() or not room.is_visible_in_tree():
			return


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
