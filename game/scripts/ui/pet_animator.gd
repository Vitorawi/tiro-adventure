class_name PetAnimator
extends Node
## Toca as animações do Tiro detalhado (Tela do Pet) num TextureRect.
## Fica em "respirar" parado, sorteia travessuras de vez em quando, reage às ações
## do jogador, ao sono e ao carinho com o dedo (cabeça, barriga ou patinhas).
## Às vezes ele rola de barriga para cima para ganhar carinho na barriga.

const DIR := "res://assets/sprites/characters/tiro_pet/" # apenas roupas/âncoras originais
const IDLE := &"idle_breathe"
const SLEEP := &"sleep"
const ROLL := &"roll_over"
const CLOTHES_CACHE_LIMIT := 48
const ANIMAREF := preload("res://scripts/ui/animaref_clips.gd")
const FEEDING := [&"eat_enter", &"eat_loop", &"eat_exit"]
const SLEEP_SEQUENCE := [&"sleep_enter", &"sleep_loop", &"sleep_exit"]
const BELLY_SEQUENCE := [&"belly_enter", &"belly_loop", &"belly_exit"]
const CARE_SEQUENCE := [&"eat_enter", &"eat_loop", &"eat_exit", &"bath", &"play_ball", &"sleep_enter", &"sleep_loop", &"sleep_exit", &"belly_enter", &"belly_loop", &"belly_exit"]
## No legacy clip may render on the illustrated puppy's home screen.
const PUPPY_ALIASES := {&"sniff": &"head_tilt", &"stretch": &"head_tilt", &"bark": &"head_tilt",
	&"happy_jump": &"close_eyes", &"shake_off": &"head_tilt", &"look_around": &"head_tilt",
	&"chase_tail": &"head_tilt", &"give_paw": &"pet_head", &"wag_excited": &"pet_head",
	&"pet_paw": &"pet_head", &"roll_over": &"belly_enter", &"belly_rub": &"belly_loop",
	&"belly_kick": &"belly_loop", &"sleep": IDLE, &"eat": IDLE}
var _animaref_frames: Dictionary = {}
var allow_animaref := true
static var _portrait_bounds: Dictionary = {}
var _portrait_holder: Control
## Quadros por segundo de cada animação.
const FPS := {
	&"idle_breathe": 6.0, &"head_tilt": 7.0, &"scratch": 8.0, &"yawn": 6.0, &"sniff": 7.0,
	&"stretch": 7.0, &"bark": 8.0, &"eat": 8.0, &"happy_jump": 9.0, &"shake_off": 10.0,
	&"sleep": 5.0, &"look_around": 7.0, &"chase_tail": 9.0, &"lick_paw": 7.0,
	&"give_paw": 7.0, &"wag_excited": 9.0, &"sad": 6.0, &"roll_over": 11.0,
	&"pet_head": 8.0, &"pet_paw": 9.0, &"belly_rub": 9.0, &"belly_kick": 10.0,
}
## Travessuras sorteadas quando ele está parado (peso maior = mais comum).
## Ação do jogador -> [animação, repetições].
const REACTIONS := {
	&"feed": [&"eat", 3], &"play": [&"happy_jump", 3], &"bathe": [&"shake_off", 3],
	&"pet": [&"wag_excited", 1],
	&"wish": [&"happy_jump", 2], &"brush": [&"wag_excited", 2],
}
## Reação ao paladar -> clipes depois de comer (o segundo, se houver, vem em seguida).
const TASTE_CLIPS := {
	"loved": [&"happy_jump"], "liked": [&"wag_excited"], "odd": [&"head_tilt", &"lick_paw"], "grimace": [&"shake_off"],
}
## Quanto carinho (segundos de dedo na barriga/cabeça) até ele rolar de barriga.
const ROLL_AFTER := 1.6
## Segundos de barriga para cima sem carinho até ele levantar.
const BELLY_IDLE := 4.0

var _party_hat: TextureRect
var _target: TextureRect
var _look: Dictionary = {}
var _clothes: Dictionary = {}
var _anchors: Dictionary = {}
var _clothes_cache: Dictionary = {}
## Só a instância da aba Tiro participa do teste; retratos ficam originais.
var allow_illustrated_puppy := false
## Prévia local de sprites externos; nulo mantém o animador normal.
var preview_texture: Texture2D
var _frames: Dictionary = {}  # nome -> Array[Texture2D]
var _clip: StringName = IDLE
var _frame := 0
var _clock := 0.0
var _loops_left := 0
var _reverse := false
var _next: StringName = &""
var _chain: Array[StringName] = []
var _taste: Array = []
var _fidget_in := 5.0
var _sleeping := false
var _sad := false
var _belly_up := false
var _belly_timer := 0.0
var _stroke_time := 0.0  # carinho acumulado (sentado) para decidir rolar
var _stroke_age := 0.0   # tempo desde o último carinho


## Retrato vestido com recorte do canvas transparente; o Tiro continua legível em 64 px.
static func portrait(px: int = 64) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(px, px + 20)
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var target := TextureRect.new()
	target.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	target.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	holder.add_child(target)
	var animator := PetAnimator.new()
	animator._portrait_holder = holder
	holder.add_child(animator)
	animator.setup(target)
	animator.set_sleeping(GameState.dog.sleeping)
	return holder


func setup(target: TextureRect) -> void:
	_target = target
	_party_hat = TextureRect.new()
	_party_hat.name = "PartyHat"
	_party_hat.texture = load("res://assets/sprites/ui/album/prop_party_hat.png")
	_party_hat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_party_hat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_party_hat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_hat.z_index = 2
	target.add_child(_party_hat)
	_anchors = JSON.parse_string(FileAccess.get_file_as_string(DIR + "overlay_anchors.json"))
	for slot: String in ["body", "neck", "head"]:
		var layer := TextureRect.new()
		layer.name = "Outfit_" + slot
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		layer.stretch_mode = target.stretch_mode
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		target.add_child(layer)
		layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_clothes[slot] = layer
	Events.state_changed.connect(_refresh_look)
	Events.grew.connect(_on_grew)
	_refresh_look()
	Events.dog_action.connect(react)
	Events.taste_reacted.connect(func(_item: String, reaction: String) -> void: _taste = TASTE_CLIPS.get(reaction, []).duplicate())
	_show()


func _on_grew(_phase: String) -> void:
	_refresh_look()


func _refresh_look() -> void:
	var look := GameState.dog_look()
	if _look.get("body", "") != look.body:
		if _clip in CARE_SEQUENCE:
			_clip = SLEEP if _sleeping and (_clip in SLEEP_SEQUENCE or _clip in BELLY_SEQUENCE) else IDLE
			_belly_up = false
			_chain.clear()
		_look = look
		_frames.clear()
		_clothes_cache.clear()
		for clip: StringName in FPS:
			_load_clip(clip)
		_frame = 0
	else:
		_look = look
	DogLook.tint(_target)
	_show()


func _load_clip(clip: StringName) -> void:
	if _look.get("body", "") == "puppy":
		_frames[clip] = [DogLook.pose_texture("puppy")]
		return
	var folder := str(_look.dir_pet)
	var resolved := str(_look.clip_fallback.get(str(clip), str(clip)))
	var list: Array[Texture2D] = []
	var index := 0
	while ResourceLoader.exists("%s%s/frame_%02d.png" % [folder, resolved, index]):
		list.append(load("%s%s/frame_%02d.png" % [folder, resolved, index]))
		index += 1
	_frames[clip] = list


func set_sleeping(value: bool) -> void:
	if value == _sleeping:
		return
	_sleeping = value
	if _clip in CARE_SEQUENCE: _chain.clear()
	_belly_up = false
	_next = &""
	if _clip in BELLY_SEQUENCE and _belly_available():
		# Finish standing up before changing to the seated sleep entrance.
		if _clip == &"belly_loop": _play(&"belly_exit", 1)
		return
	if _sleep_available():
		# Finish the current transition before honoring a rapid toggle.
		# This preserves pose continuity instead of restarting another clip.
		if _clip in [&"sleep_enter", &"sleep_exit"]: return
		if value:
			_play(&"sleep_enter", 1)
		elif _clip == &"sleep_loop":
			_play(&"sleep_exit", 1)
		else:
			_play(IDLE, 1)
		return
	if _animaref_enabled():
		_play(IDLE, 1)
		return
	_play(SLEEP if value else IDLE, 1)
	if not value:
		_fidget_in = 3.0


## Triste (necessidade baixa): as travessuras passam a ser carinhas tristes.
func set_sad(value: bool) -> void:
	_sad = value


func react(action: StringName) -> void:
	if _clip in CARE_SEQUENCE: return
	for id: String in Database.progression.tricks:
		if action == StringName(Database.progression.tricks[id].animation) and not _sleeping:
			_belly_up = false
			_next = &""
			_play(action, 1)
			return
	if _sleeping or _belly_up or not REACTIONS.has(action):
		return
	if action == &"pet" and _clip != IDLE:
		return  # o carinho com o dedo já está animando
	if action == &"pet" and _reaction_available(&"pet_head"):
		_chain.clear()
		_play(&"pet_head", 1)
		return
	if action == &"bathe" and _bath_available():
		_chain.clear()
		_next = &""
		_play(&"bath", 1)
		return
	if action == &"play" and _ball_available():
		_chain.clear()
		_next = &""
		_play(&"play_ball", 1)
		return
	if action == &"feed" and _feeding_available():
		_next = &""
		_chain.assign([&"eat_loop", &"eat_exit"])
		# The new sequence includes its own satisfied return to idle.
		# Taste discovery/feedback remains handled by the gameplay and UI.
		_taste.clear()
		_play(&"eat_enter", 1)
		return
	if _animaref_enabled() and action in [&"feed", &"bathe", &"play"]:
		_chain.clear()
		_next = &""
		_play(IDLE, 1)
		return
	var info: Array = REACTIONS[action]
	_play(info[0], info[1])
	_chain.clear()
	if action == &"feed":
		for clip: StringName in _taste: _chain.append(clip)
	_taste = []


## Escovando: balança o rabo enquanto o dedo passa pelas costas.
func scrub() -> void:
	if _sleeping or _belly_up or _clip != IDLE:
		return
	_play(&"wag_excited", 1)


## Lugar favorito acariciado: rola de barriga para cima na hora.
func love() -> void:
	if _sleeping or _belly_up or _clip == ROLL or _clip in CARE_SEQUENCE:
		return
	_stroke_time = 0.0
	if _belly_available():
		_next = &""
		if _clip == &"pet_head" and _reaction_available(&"pet_head"):
			_chain.assign([&"belly_enter"])
		else:
			_chain.clear()
			_play(&"belly_enter", 1)
		return
	if _animaref_enabled():
		_chain.clear()
		_next = &""
		_play(&"pet_head", 1)
		return
	_next = &"belly_rub"
	if _clip == &"pet_head" and _reaction_available(&"pet_head"):
		# Finish the illustrated head reaction before offering the belly.
		_chain.assign([ROLL])
		return
	_play(ROLL, 1)


## Carinho com o dedo. `zone`: &"head", &"belly" ou &"paw"; `seconds` = tempo desde o último aviso.
func stroke(zone: StringName, seconds: float) -> void:
	if _sleeping: return
	if _clip == &"belly_loop":
		_stroke_age = 0.0
		_belly_up = true
		_belly_timer = BELLY_IDLE
		return
	if _clip in CARE_SEQUENCE:
		return
	_stroke_age = 0.0
	if _belly_up:
		_belly_timer = BELLY_IDLE
		return
	if _clip == ROLL or _clip == &"eat" or _clip == &"shake_off":
		return
	_stroke_time += seconds
	var wants_roll := zone == &"belly" and _stroke_time > ROLL_AFTER * 0.5
	wants_roll = wants_roll or (zone == &"head" and _stroke_time > ROLL_AFTER * 3.0 and randf() < 0.5)
	if wants_roll:
		love()
		return
	var clip: StringName = {&"head": &"pet_head", &"belly": &"wag_excited", &"paw": &"pet_paw"}.get(zone, IDLE)
	if _clip == clip:
		_loops_left = maxi(_loops_left, 1)  # continua enquanto houver carinho
	else:
		_play(clip, 1)


## Toca `clip` `loops` vezes e depois volta ao descanso (ou segue para `_next`).
func _play(clip: StringName, loops: int, reverse := false) -> void:
	if _animaref_enabled():
		if clip == ROLL and reverse:
			clip = &"belly_exit"
			reverse = false
		else:
			clip = PUPPY_ALIASES.get(clip, clip)
		if not ANIMAREF.CLIPS.has(clip) or not _reaction_available(clip): clip = IDLE
	_clip = clip
	_frame = 0
	_clock = 0.0
	_loops_left = loops
	_reverse = reverse
	_show()


func _process(delta: float) -> void:
	if preview_texture != null:
		_show()
		return
	if _target == null:
		return
	if _clip in SLEEP_SEQUENCE and not _sleep_available():
		_play(SLEEP if _sleeping else IDLE, 1)
		return
	if _clip in BELLY_SEQUENCE and not _belly_available():
		_belly_up = false
		_chain.clear()
		_next = &""
		_play(SLEEP if _sleeping else IDLE, 1)
		return
	_stroke_age += delta
	if _stroke_age > 2.0:
		_stroke_time = 0.0
	if _belly_up:
		_belly_timer -= delta
		if _belly_timer <= 0.0 and _clip != ROLL:
			_belly_up = false
			if _clip != &"belly_loop":
				_play(ROLL, 1, true)  # levanta (rola de volta)
				return
	var list: Array = _clip_frames()
	var resting := _clip == IDLE
	if resting and not _sleeping:
		_fidget_in -= delta
		if _fidget_in <= 0.0 and (not _uses_animaref() or _frame == 0):
			_fidget_in = _fidget_delay()
			_play(_pick_fidget(), 1)
			return
	if _clip == SLEEP and _frame >= list.size() - 1:
		if not _sleeping:
			_fidget_in -= delta
			if _fidget_in <= 0: _finish_clip()
		return  # dormindo: segura o último quadro
	_clock += delta
	var step: float = _frame_seconds()
	while _clock >= step:
		_clock -= step
		_frame += 1
		if _frame >= list.size():
			_frame = 0
			if resting or (_clip == &"sleep_loop" and _sleeping) or (_clip == &"belly_loop" and _belly_up):
				continue
			if _clip == SLEEP:
				_frame = list.size() - 1
				break
			if _belly_up and _clip != ROLL:
				_play(&"belly_kick" if _clip == &"belly_rub" and randf() < 0.5 else &"belly_rub", 1)
				return
			_loops_left -= 1
			if _loops_left <= 0:
				_finish_clip()
				return
		step = _frame_seconds()
	_show()


func _finish_clip() -> void:
	if _clip in BELLY_SEQUENCE:
		if _clip == &"belly_enter":
			if _sleeping:
				_play(&"belly_exit", 1)
			else:
				_belly_up = true
				_belly_timer = BELLY_IDLE
				_play(&"belly_loop", 1)
		elif _clip == &"belly_loop":
			_play(&"belly_loop" if _belly_up and not _sleeping else &"belly_exit", 1)
		else:
			_belly_up = false
			_play((&"sleep_enter" if _sleep_available() else SLEEP) if _sleeping else IDLE, 1)
			_fidget_in = _fidget_delay()
		return
	if _clip in SLEEP_SEQUENCE:
		if _clip == &"sleep_enter":
			_play(&"sleep_loop" if _sleeping else &"sleep_exit", 1)
		elif _clip == &"sleep_loop":
			_play(&"sleep_loop" if _sleeping else &"sleep_exit", 1)
		elif _sleeping:
			_play(&"sleep_enter", 1)
		else:
			_play(IDLE, 1)
			_fidget_in = _fidget_delay()
		return
	if not _chain.is_empty():
		_play(_chain.pop_front(), 1)
		return
	if _next != &"":
		var clip := _next
		_next = &""
		if clip == &"belly_rub":
			_belly_up = true
			_belly_timer = BELLY_IDLE
		_play(clip, 1)
		return
	_play(IDLE, 1)
	_fidget_in = _fidget_delay()


func _pick_fidget() -> StringName:
	if _uses_animaref():
		if _sad and _reaction_available(&"sad") and randf() < 0.6:
			return &"sad"
		var choices: Array[StringName] = [&"head_tilt", &"close_eyes"]
		if _reaction_available(&"lick_paw"): choices.append(&"lick_paw")
		return choices.pick_random()
	if _sad and randf() < 0.6:
		return &"sad"
	var weights: Dictionary = PersonalityRules.behavior(GameState.growth).fidgets
	var total := 0.0
	for clip: String in weights: total += float(weights[clip])
	var roll := randf() * total
	for clip: String in weights:
		roll -= float(weights[clip])
		if roll < 0:
			if clip == "sleep": _fidget_in = float(Database.growth.behaviors.short_sleep_seconds)
			return StringName(clip)
	return &"head_tilt"


func _show() -> void:
	if _target == null:
		return
	if _portrait_holder != null and _look.get("body", "") == "puppy":
		_target.texture = DogLook.pose_texture("puppy")
		_target.material = null
		_target.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_party_hat.hide()
		for layer: TextureRect in _clothes.values(): layer.hide()
		_fit_portrait([_target.texture])
		return
	if preview_texture != null:
		_target.texture = preview_texture
		_target.material = null
		_target.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_party_hat.hide()
		for layer: TextureRect in _clothes.values(): layer.hide()
		return
	_party_hat.visible = not _animaref_enabled() and GameState.tiro_party() and _clip in [IDLE, &"head_tilt", &"wag_excited"]
	_party_hat.size = _target.size * Vector2(0.24, 0.28)
	_party_hat.position = _target.size * Vector2(0.38, 0.10)
	var list: Array = _clip_frames()
	var external: bool = _animaref_enabled() and not list.is_empty()
	if list.is_empty():
		return
	if external:
		_target.material = null
		_target.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	else:
		if _target.material == null: DogLook.tint(_target)
		_target.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var index := mini(_frame, list.size() - 1)
	_target.texture = list[list.size() - 1 - index if _reverse else index]
	_fit_portrait(list)
	var drawn := list.size() - 1 - index if _reverse else index
	for slot: String in _clothes:
		var layer: TextureRect = _clothes[slot]
		var id := str(GameState.progress.equipped.get(slot, ""))
		var path := str(Database.collections.get(id, {}).get("overlay", ""))
		layer.visible = _look.body != "puppy" and path != "" and str(_clip) in Database.collections.get(id, {}).get("show_in", _anchors.get("show_in", []))
		if slot == "head" and GameState.tiro_party(): layer.visible = false
		if not layer.visible:
			continue
		var variant := DIR + "overlays/%s/%s/frame_%02d.png" % [id, _clip, drawn]
		if ResourceLoader.exists(variant):
			path = variant
		if not _clothes_cache.has(path):
			if _clothes_cache.size() >= CLOTHES_CACHE_LIMIT:
				_clothes_cache.erase(_clothes_cache.keys().front())
			_clothes_cache[path] = load(path)
		layer.texture = _clothes_cache[path]
		var anchor: Dictionary = _anchors.get("bodies", {}).get(str(_look.body), {}).get(str(_clip), {}).get(slot, {})
		layer.scale = Vector2.ONE * float(anchor.get("scale", 1.0))
		var offset: Array = anchor.get("offset", [0, 0])
		# Âncoras expressas no canvas 256×216, independentes do tamanho da tela.
		layer.position = Vector2(float(offset[0]), float(offset[1])) * _target.size / Vector2(256, 216)


## Usa a união dos quadros do clipe: cabe inteiro sem oscilar a cada quadro.
## O canvas varia entre corpos/poses; o recorte antigo pressupunha o adulto em pé.
func _fit_portrait(frames: Array) -> void:
	if _portrait_holder == null: return
	var key := str(_look.dir_pet) + str(_clip)
	if _look.get("body", "") == "puppy": key = "puppy_reference_portrait"
	if not _portrait_bounds.has(key):
		var bounds := Rect2()
		for texture: Texture2D in frames:
			var used := Rect2(texture.get_image().get_used_rect())
			if used.has_area(): bounds = bounds.merge(used) if bounds.has_area() else used
		_portrait_bounds[key] = bounds
	var bounds: Rect2 = _portrait_bounds[key]
	if not bounds.has_area(): return
	var area := _portrait_holder.custom_minimum_size
	var factor := minf((area.x - 8.0) / bounds.size.x, (area.y - 8.0) / bounds.size.y)
	_target.size = _target.texture.get_size() * factor
	_target.position = (area - bounds.size * factor) * 0.5 - bounds.position * factor
	_party_hat.size = _target.size * Vector2(0.24, 0.28)
	_party_hat.position = _target.size * Vector2(0.38, 0.10)


func _fidget_delay() -> float:
	if _uses_animaref(): return randf_range(9.0, 16.0)
	var seconds: Array = PersonalityRules.behavior(GameState.growth).idle_seconds
	return randf_range(float(seconds[0]), float(seconds[1]))


func _uses_animaref() -> bool:
	return _animaref_enabled() and ANIMAREF.CLIPS.has(_clip)


func _animaref_enabled() -> bool:
	return allow_animaref and allow_illustrated_puppy and _look.get("body", "") == "puppy"


func _clip_frames() -> Array:
	if _animaref_enabled():
		if not _animaref_frames.has(_clip):
			_animaref_frames[_clip] = ANIMAREF.frames(_clip)
		if not _animaref_frames[_clip].is_empty(): return _animaref_frames[_clip]
		if not _animaref_frames.has(IDLE): _animaref_frames[IDLE] = ANIMAREF.frames(IDLE)
		if not _animaref_frames[IDLE].is_empty(): return _animaref_frames[IDLE]
		return [DogLook.pose_texture("puppy")]
	return _frames.get(_clip, _frames.get(IDLE, []))


func _frame_seconds() -> float:
	if _animaref_enabled():
		var clip: StringName = _clip if ANIMAREF.CLIPS.has(_clip) and not _animaref_frames.get(_clip, []).is_empty() else IDLE
		return float(ANIMAREF.CLIPS[clip][mini(_frame, ANIMAREF.CLIPS[clip].size() - 1)])
	return 1.0 / float(FPS.get(_clip, 6.0))


func _feeding_available() -> bool:
	if not _animaref_enabled(): return false
	for clip: StringName in FEEDING:
		if not _animaref_frames.has(clip): _animaref_frames[clip] = ANIMAREF.frames(clip)
		if _animaref_frames[clip].is_empty(): return false
	return true


func _bath_available() -> bool:
	if not _animaref_enabled(): return false
	if not _animaref_frames.has(&"bath"): _animaref_frames[&"bath"] = ANIMAREF.frames(&"bath")
	return not _animaref_frames[&"bath"].is_empty()


func _ball_available() -> bool:
	if not _animaref_enabled(): return false
	if not _animaref_frames.has(&"play_ball"): _animaref_frames[&"play_ball"] = ANIMAREF.frames(&"play_ball")
	return not _animaref_frames[&"play_ball"].is_empty()


func _sleep_available() -> bool:
	if not _animaref_enabled(): return false
	for clip: StringName in SLEEP_SEQUENCE:
		if not _animaref_frames.has(clip): _animaref_frames[clip] = ANIMAREF.frames(clip)
		if _animaref_frames[clip].is_empty(): return false
	return true


func _reaction_available(clip: StringName) -> bool:
	if not _animaref_enabled(): return false
	if not _animaref_frames.has(clip): _animaref_frames[clip] = ANIMAREF.frames(clip)
	return not _animaref_frames[clip].is_empty()


func _belly_available() -> bool:
	if not _animaref_enabled(): return false
	for clip: StringName in BELLY_SEQUENCE:
		if not _animaref_frames.has(clip): _animaref_frames[clip] = ANIMAREF.frames(clip)
		if _animaref_frames[clip].is_empty(): return false
	return true
