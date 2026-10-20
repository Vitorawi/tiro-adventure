class_name DogWorld
extends Node2D
## Tiro pequeno no Mundo. A origem do nó fica nas patas (usada na ordenação por Y).
## Anda sozinho pelo piso desviando dos móveis (caminho calculado pela sala),
## vai à tigela quando está com fome, dorme no sofá, senta e late de vez em quando.
##
## Sprites (PixelLab) na pasta retornada por GameState.dog_look().dir_world:
##   rotations/<direção>.png               pose parada por direção
##   <ação>/<direção>/frame_XX.png         animações (walk, idle, sit, bark, sleep, eat)
## Direções que faltam usam o espelho (oeste <-> leste) ou qualquer outra disponível.

var sprite_dir: String = ""
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
var sleep_spot: String = "floor"
var _album_sleep_spot: String = ""
var sleep_approach := Vector2.INF

var _zooming := false

var _facing := "south"
var _on_sofa := false
var _party_hat: Sprite2D
var _sprite: AnimatedSprite2D
var _reaction: Dictionary = {}
var _move_tween: Tween
## Balãozinho do desejo sobre a cabeça (some dormindo ou sem pedido).
var _balloon: Node2D
var _balloon_icon: Sprite2D
var _balloon_wish := ""


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	sprite_dir = GameState.dog_look().dir_world
	_sprite.sprite_frames = _build_frames()
	_sprite.position = Vector2(0.0, -FEET_OFFSET)
	add_child(_sprite)
	_party_hat = Sprite2D.new()
	_party_hat.name = "PartyHat"
	_party_hat.texture = load("res://assets/sprites/ui/album/prop_party_hat.png")
	_party_hat.scale = Vector2.ONE * 0.3
	_party_hat.position = Vector2(0, -51)
	add_child(_party_hat)
	_party_hat.visible = GameState.tiro_party()
	DogLook.tint(_sprite)
	Events.state_changed.connect(_refresh_look)
	_play("idle", "south")
	if position.is_equal_approx(sleep_point):
		_set_on_sofa(true)
	Events.dog_action.connect(_on_care)
	_build_balloon()
	Events.state_changed.connect(_refresh_balloon)
	_refresh_balloon()
	_brain()


func _refresh_look() -> void:
	if _party_hat: _party_hat.visible = GameState.tiro_party() and not GameState.dog.sleeping and not str(_sprite.animation).begins_with("sleep_")
	var folder := str(GameState.dog_look().dir_world)
	if sprite_dir != folder:
		sprite_dir = folder
		var animation := _sprite.animation
		var frame := _sprite.frame
		_sprite.sprite_frames = _build_frames()
		if _sprite.sprite_frames.has_animation(animation):
			_sprite.play(animation)
			_sprite.frame = mini(frame, _sprite.sprite_frames.get_frame_count(animation) - 1)
		Motion.pop_in(_sprite)
	DogLook.tint(_sprite)


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
		if _balloon_icon.texture:
			# Ícones de itens têm canvases diferentes; cabem no mesmo espaço, sem distorcer.
			var image_size := _balloon_icon.texture.get_size()
			_balloon_icon.scale = Vector2.ONE * (19.2 / maxf(image_size.x, image_size.y))
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
				_note_album_sleep("floor")
				_play("sleep", _facing)
				await _wait(2.0)
				continue
			# Sofá ou caminha: o Tiro é desenhado na frente do móvel (z_index) enquanto dorme.
			if not _on_sofa:
				await _go_to(sleep_approach)
				_set_on_sofa(true)
			if position.distance_to(sleep_point) > 4.0:
				await _step_to(sleep_point)
			_note_album_sleep(sleep_spot)
			_play("sleep", "east")
			await _wait(2.0)
			continue
		_album_sleep_spot = ""
		if _on_sofa:
			await _step_to(sleep_approach)
			_set_on_sofa(false)
		if not _reaction.is_empty():
			var reaction := _reaction.duplicate()
			_reaction.clear()
			await _go_to(reaction.target)
			if not _reaction.is_empty() or GameState.dog.sleeping:
				continue
			# Só conta quando ele chegou: ponto inalcançável não gasta a "primeira vez".
			if reaction.on_start.is_valid() and position.distance_to(reaction.target) <= 12.0:
				reaction.on_start.call()
			await _show_reaction(reaction.kind)
			continue
		if bowl_point != Vector2.INF and dog.get_need("hunger", GameState.now()) < HUNGRY and randf() < 0.6:
			await _go_to(bowl_point)
			_play("eat", "east")
			await _wait(3.0)
			continue
		await _idle_moment()
		if is_inside_tree() and _reaction.is_empty():
			await _wander()


## Uma reação por vez; uma ação nova substitui a anterior sem somar caminhos.
## `on_start` (opcional) roda quando a reação realmente começa, já no ponto alcançado.
func react_at(kind: StringName, target: Vector2, on_start: Callable = Callable()) -> void:
	if GameState.dog.sleeping or not room.is_visible_in_tree():
		return
	_reaction = {"kind": kind, "target": room.nearest_floor_point(target), "on_start": on_start}
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
	if kind == &"bench":
		# Senta ao lado do banco um instante e comemora (animações já existentes).
		_play("sit", _facing)
		await _wait(2.5)
		if not _reaction.is_empty() or GameState.dog.sleeping:
			return
	if kind == &"garden":
		# Fareja as plantas de perto e depois comemora.
		_play("sniff", _facing)
		await _wait(2.5)
		if not _reaction.is_empty() or GameState.dog.sleeping:
			return
	if kind == &"festival":
		# Comemora com a turma: senta, late de alegria e ainda pula (o fecho comum da reação).
		_play("sit", _facing)
		await _wait(1.2)
		if not _reaction.is_empty() or GameState.dog.sleeping:
			return
		_play("bark", "south")
		await _wait(1.0)
		if not _reaction.is_empty() or GameState.dog.sleeping:
			return
	if kind == &"picnic":
		# Senta na toalha, mordisca o petisco do encontro e comemora.
		_play("sit", _facing)
		await _wait(1.5)
		if not _reaction.is_empty() or GameState.dog.sleeping:
			return
		_play("eat", _facing)
		await _wait(1.5)
		if not _reaction.is_empty() or GameState.dog.sleeping:
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


## Escolhas só visuais; não chamam set_sleeping, prêmios ou contadores de cuidado.
func idle_choice(roll: float) -> String:
	var weights: Dictionary = PersonalityRules.behavior(GameState.growth).world
	for kind: String in ["nap", "sit", "sniff"]:
		roll -= float(weights.get(kind, 0))
		if roll < 0: return kind
	return "idle"


func _idle_moment() -> void:
	var data: Dictionary = Database.growth.behaviors.world
	var kind := idle_choice(randf())
	var interval: Array = data.idle_seconds
	match kind:
		"nap":
			_play("sleep", _facing)
			interval = data.nap_seconds
		"sit":
			_play("sit", _facing)
			interval = data.sit_seconds
		"sniff":
			_play("sniff", _facing)
			await _wait(float(data.sniff_seconds))
			return
		_:
			_play("bark" if randf() < float(data.bark) else "idle", _facing)
	await _wait(randf_range(float(interval[0]), float(interval[1])))


func _wander() -> void:
	if GameState.dog.sleeping or not room.is_visible_in_tree(): return
	var weights: Dictionary = PersonalityRules.behavior(GameState.growth).world
	var data: Dictionary = Database.growth.behaviors.world
	if randf() < float(weights.zoomies):
		_zooming = true
		for step in int(data.zoomies_steps):
			await _go_to(room.floor_point_near(position, float(data.zoomies_radius)))
			if not _reaction.is_empty() or GameState.dog.sleeping or not room.is_visible_in_tree(): break
		_zooming = false
		return
	var target := room.random_floor_point(position)
	if sleep_approach != Vector2.INF and randf() < float(weights.get("home", 0)):
		target = room.floor_point_near(sleep_approach, float(data.social_radius))
	if randf() < float(weights.social):
		var company: Array[Vector2] = []
		for npc: NpcWorld in room._npcs:
			if npc.visible: company.append(npc.position)
		for object: Sprite2D in room._objects:
			if object.visible and object.self_modulate.a > 0 and object.has_meta("station") and GameState.station(str(object.get_meta("station"))).is_busy(GameState.now()):
				company.append(object.position)
		if not company.is_empty(): target = room.floor_point_near(company.pick_random(), float(data.social_radius))
	await _go_to(target)
	if GameState.growth.phase == "adult" and _reaction.is_empty() and not GameState.dog.sleeping:
		_play("sit", _facing)
		await _wait(float(data.sit_seconds[0]))


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
	if _zooming: speed *= float(Database.growth.behaviors.world.zoomies_speed)
	_move_tween = create_tween()
	var revision := room.navigation_revision
	_move_tween.tween_property(self, "position", point, delta.length() / speed)
	var stumble := not _on_sofa and not _zooming and delta.length() > float(Database.growth.behaviors.world.stumble_min_distance) and randf() < float(PersonalityRules.behavior(GameState.growth).world.stumble)
	var halfway := position + delta * 0.5
	while _move_tween.is_running():
		await get_tree().process_frame
		if stumble and _move_tween.is_running() and position.distance_to(point) <= halfway.distance_to(point):
			stumble = false
			_move_tween.pause()
			_play("idle", _facing)
			var seconds := float(Database.growth.behaviors.world.stumble_seconds)
			var hop := create_tween()
			hop.tween_property(_sprite, "position:y", -FEET_OFFSET - float(Database.growth.behaviors.world.stumble_hop), seconds * 0.5)
			hop.tween_property(_sprite, "position:y", -FEET_OFFSET, seconds * 0.5)
			await hop.finished
			_move_tween.play()
			_play("walk", _facing)
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
	if _party_hat: _party_hat.visible = GameState.tiro_party() and not GameState.dog.sleeping and action != "sleep"
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
	for file in ResourceLoader.list_directory(sprite_dir + "rotations/"):
		if file.ends_with(".png"):
			var anim := "pose_" + file.get_basename()
			frames.add_animation(anim)
			frames.add_frame(anim, load(sprite_dir + "rotations/" + file))
	for action in ResourceLoader.list_directory(sprite_dir):
		if not action.ends_with("/") or action == "rotations/":
			continue
		action = action.trim_suffix("/")
		for direction in ResourceLoader.list_directory(sprite_dir + action + "/"):
			if direction.ends_with("/"):
				_add_animation(frames, action, direction.trim_suffix("/"))
	return frames


func _add_animation(frames: SpriteFrames, action: String, direction: String) -> void:
	var folder := "%s%s/%s/" % [sprite_dir, action, direction]
	var files := Array(ResourceLoader.list_directory(folder))
	files.sort()
	var anim := "%s_%s" % [action, direction]
	frames.add_animation(anim)
	frames.set_animation_speed(anim, 8.0)
	frames.set_animation_loop(anim, action in LOOPING)
	for file: String in files:
		if file.ends_with(".png"):
			frames.add_frame(anim, load(folder + file))


func _note_album_sleep(spot: String) -> void:
	if _album_sleep_spot == spot: return
	_album_sleep_spot = spot
	GameState.note_sleep_spot(spot)
