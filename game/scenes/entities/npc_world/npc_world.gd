class_name NpcWorld
extends Node2D
## Personagem (NPC) pequeno no Mundo: passeia sozinho perto de casa pelo piso da sala
## (mesma grade de caminho do Tiro) e mostra um balão sobre a cabeça:
##   "!" amarelo = passo novo ainda não conversado;  "✓" verde = missão pronta para receber.
## Tocar abre a conversa (RoomView → Places.open_npc). A origem do nó fica nos pés.
##
## Sprites (PixelLab) em npcs.json → "sprite_dir":
##   rotations/<direção>.png        pose parada por direção
##   walk/<direção>/frame_XX.png    caminhada (opcional)

const MIRROR := { "west": "east", "east": "west" }
## Distância máxima (px da sala) que o NPC se afasta do ponto de casa.
const ROAM_RADIUS := 140.0
## "follow": distância máxima (px da sala) do personagem que ele acompanha.
const FOLLOW_RADIUS := 40.0
const SPEED := 32.0
const SHADOW_RADIUS := 15.0
const SHADOW_COLOR := Color(0.12, 0.05, 0.02, 0.45)

var npc_id := ""
var friend_id := ""
var friend_visit := false
var room: RoomView
var home := Vector2.ZERO

var _facing := "south"
var _sprite: AnimatedSprite2D
var _badge: Label
var _feet := 26.0
var _move_tween: Tween
var _hopping := false
var _snack: Sprite2D


func _ready() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	add_child(_sprite)
	_sprite.position = Vector2(0.0, -_feet)
	_badge = Label.new()
	_badge.add_theme_font_size_override("font_size", 28)
	_badge.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	_badge.add_theme_constant_override("outline_size", 8)
	_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge.size = Vector2(40, 40)
	_badge.position = Vector2(-20, -_feet * 2.0 - 44.0)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_badge)
	_snack = Sprite2D.new()
	_snack.position = Vector2(0, -_feet * 2.0 - 22.0)
	add_child(_snack)
	var bounce := _badge.create_tween().set_loops()
	bounce.tween_property(_badge, "position:y", _badge.position.y - 6.0, 0.4).set_trans(Tween.TRANS_SINE)
	bounce.tween_property(_badge, "position:y", _badge.position.y, 0.4).set_trans(Tween.TRANS_SINE)
	Events.state_changed.connect(_refresh_badge)
	_refresh_badge()
	_play("idle", "south")
	_brain()


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -1.0), 0.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, SHADOW_RADIUS, SHADOW_COLOR, true, -1.0, false)
	draw_set_transform(Vector2.ZERO)


## Área de toque em volta do personagem (coordenadas da sala).
func hit_test(point: Vector2) -> bool:
	return Rect2(Vector2(-22.0, -_feet * 2.0 - 6.0), Vector2(44.0, _feet * 2.0 + 10.0)).has_point((point - position) / scale)


## Ponto acima da cabeça (para a seta do "Ir").
func head_point() -> Vector2:
	return position - Vector2(0.0, (_feet * 2.0 + 4.0) * scale.y)


func _refresh_badge() -> void:
	if friend_id != "" and GameState.friend_unlocked(friend_id):
		_badge.text = "✓" if friend_visit else ""
		_snack.texture = Database.item_icon(str(GameState.friend_def(friend_id).likes))
		_snack.visible = not friend_visit and str(GameState.friend_state.entry(friend_id).last_window) != GameState.friend_window()
		return
	_snack.visible = false
	var state := Places.npc_badge(npc_id)
	_badge.text = "✓" if state == "ready" else ("!" if state == "new" else "")
	_badge.add_theme_color_override("font_color", Palette.PRIMARY if state == "ready" else Palette.GOLD)


# --- Comportamento -----------------------------------------------------------

func _brain() -> void:
	await get_tree().process_frame
	while is_inside_tree():
		if not room.is_visible_in_tree():
			await get_tree().create_timer(0.3).timeout
			continue
		if friend_visit and friend_id == "pipoca" and GameState.dog.sleeping:
			_play("sleep", "east")
			await get_tree().create_timer(0.3).timeout
			continue
		_play("idle", _facing)
		await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
		if not is_inside_tree():
			return
		await _go_to(_roam_target())


## Personagem "decor" (ex.: Pipoca): sem conversa nem balão; tocar faz pulinhos.
func is_decor() -> bool:
	if friend_id != "" and GameState.friend_unlocked(friend_id):
		return false
	return bool(Database.npcs.get(npc_id, {}).get("decor", false))


## Pulinhos de alegria (reação ao toque de personagens decor).
func react() -> void:
	if _hopping:
		return
	_hopping = true
	var tween := create_tween()
	for i in 2:
		tween.tween_property(_sprite, "position:y", -_feet - 10.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_sprite, "position:y", -_feet, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	_hopping = false


## Destino alcançável perto de casa (o NPC não atravessa o mapa todo). Quem tem "follow"
## escolhe destinos perto do personagem que acompanha.
func _roam_target() -> Vector2:
	if friend_visit:
		var dog: DogWorld = room.get("_dog")
		return room.floor_point_near(dog.position if is_instance_valid(dog) else home, FOLLOW_RADIUS)
	if friend_id != "" and npc_id == "":
		return room.floor_point_near(home, FOLLOW_RADIUS)
	var leader := room.npc_node(str(Database.npcs.get(npc_id, {}).get("follow", "")))
	if leader != null:
		return room.floor_point_near(leader.position, FOLLOW_RADIUS)
	for attempt in 12:
		var target := room.random_floor_point(position)
		if target.distance_to(home) <= ROAM_RADIUS:
			return target
	return room.nearest_floor_point(home)


func _go_to(target: Vector2) -> void:
	var path := room.find_path(position, target)
	var revision := room.navigation_revision
	for point in path:
		if not is_inside_tree() or not room.is_visible_in_tree() or revision != room.navigation_revision:
			return
		var delta := point - position
		if delta.length() < 1.0:
			continue
		if absf(delta.x) > absf(delta.y) * 1.2:
			_facing = "east" if delta.x > 0.0 else "west"
		else:
			_facing = "south" if delta.y > 0.0 else "north"
		_play("walk", _facing)
		_move_tween = create_tween()
		_move_tween.tween_property(self, "position", point, delta.length() / SPEED)
		await _move_tween.finished
	_play("idle", _facing)


# --- Animação ----------------------------------------------------------------

## "<ação>_<direção>"; sem ela, o espelho (leste/oeste) ou a pose parada da direção.
func _play(action: String, direction: String) -> void:
	var frames := _sprite.sprite_frames
	var flip := false
	var anim := "%s_%s" % [action, direction]
	if not frames.has_animation(anim) and MIRROR.has(direction) and frames.has_animation("%s_%s" % [action, MIRROR[direction]]):
		anim = "%s_%s" % [action, MIRROR[direction]]
		flip = true
	if not frames.has_animation(anim):
		anim = "pose_" + direction
		flip = false
	if not frames.has_animation(anim):
		anim = "pose_south"
	if not frames.has_animation(anim) or (_sprite.animation == anim and _sprite.flip_h == flip and _sprite.is_playing()):
		return
	_sprite.flip_h = flip
	_sprite.play(anim)


func _build_frames() -> SpriteFrames:
	var dir: String = GameState.friend_def(friend_id).get("sprite_dir", "") if friend_id != "" else Database.npcs.get(npc_id, {}).get("sprite_dir", "")
	var frames := SpriteFrames.new()
	if dir == "" or ResourceLoader.list_directory(dir + "rotations/").is_empty():
		return frames
	for file in ResourceLoader.list_directory(dir + "rotations/"):
		if file.ends_with(".png"):
			var texture: Texture2D = load(dir + "rotations/" + file)
			var anim := "pose_" + file.get_basename()
			frames.add_animation(anim)
			frames.add_frame(anim, texture)
			if file == "south.png":
				# Pés = última linha opaca do desenho (o canvas do PixelLab tem sobra embaixo).
				var used := texture.get_image().get_used_rect()
				_feet = used.end.y - texture.get_height() / 2.0
	for action in ResourceLoader.list_directory(dir):
		if not action.ends_with("/") or action == "rotations/":
			continue
		action = action.trim_suffix("/")
		for direction in ResourceLoader.list_directory(dir + action + "/"):
			if not direction.ends_with("/"):
				continue
			var folder := "%s%s/%s" % [dir, action, direction]
			var anim := "%s_%s" % [action, direction.trim_suffix("/")]
			frames.add_animation(anim)
			frames.set_animation_speed(anim, 8.0)
			var files := Array(ResourceLoader.list_directory(folder))
			files.sort()
			for file: String in files:
				if file.ends_with(".png"):
					frames.add_frame(anim, load(folder + file))
	if friend_id == "pipoca":
		frames.add_animation("sleep_east")
		frames.add_frame("sleep_east", load("res://assets/sprites/ui/album/pipoca_sleep.png"))
	return frames
