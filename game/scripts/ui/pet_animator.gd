class_name PetAnimator
extends Node
## Toca as animações do Tiro detalhado (Tela do Pet) num TextureRect.
## Fica em "respirar" parado, sorteia travessuras de vez em quando, reage às ações
## do jogador, ao sono e ao carinho com o dedo (cabeça, barriga ou patinhas).
## Às vezes ele rola de barriga para cima para ganhar carinho na barriga.

const DIR := "res://assets/sprites/characters/tiro_pet/"
const IDLE := &"idle_breathe"
const SLEEP := &"sleep"
const ROLL := &"roll_over"
## Quadros por segundo de cada animação.
const FPS := {
	&"idle_breathe": 6.0, &"head_tilt": 7.0, &"scratch": 8.0, &"yawn": 6.0, &"sniff": 7.0,
	&"stretch": 7.0, &"bark": 8.0, &"eat": 8.0, &"happy_jump": 9.0, &"shake_off": 10.0,
	&"sleep": 5.0, &"look_around": 7.0, &"chase_tail": 9.0, &"lick_paw": 7.0,
	&"give_paw": 7.0, &"wag_excited": 9.0, &"sad": 6.0, &"roll_over": 11.0,
	&"pet_head": 8.0, &"pet_paw": 9.0, &"belly_rub": 9.0, &"belly_kick": 10.0,
}
## Travessuras sorteadas quando ele está parado (peso maior = mais comum).
const FIDGETS := {
	&"head_tilt": 3, &"scratch": 2, &"yawn": 2, &"sniff": 3, &"stretch": 1, &"bark": 1,
	&"look_around": 3, &"chase_tail": 1, &"lick_paw": 2, &"give_paw": 1, &"wag_excited": 1,
}
## Ação do jogador -> [animação, repetições].
const REACTIONS := {
	&"feed": [&"eat", 3], &"play": [&"happy_jump", 3], &"bathe": [&"shake_off", 3],
	&"pet": [&"wag_excited", 1],
	&"wish": [&"happy_jump", 2],
}
## Quanto carinho (segundos de dedo na barriga/cabeça) até ele rolar de barriga.
const ROLL_AFTER := 1.6
## Segundos de barriga para cima sem carinho até ele levantar.
const BELLY_IDLE := 4.0

var _target: TextureRect
var _frames: Dictionary = {}  # nome -> Array[Texture2D]
var _clip: StringName = IDLE
var _frame := 0
var _clock := 0.0
var _loops_left := 0
var _reverse := false
var _next: StringName = &""
var _fidget_in := 5.0
var _sleeping := false
var _sad := false
var _belly_up := false
var _belly_timer := 0.0
var _stroke_time := 0.0  # carinho acumulado (sentado) para decidir rolar
var _stroke_age := 0.0   # tempo desde o último carinho


func setup(target: TextureRect) -> void:
	_target = target
	for clip: StringName in FPS:
		_load_clip(clip)
	Events.dog_action.connect(react)
	_show()


func _load_clip(clip: StringName) -> void:
	var list: Array[Texture2D] = []
	var index := 0
	while ResourceLoader.exists("%s%s/frame_%02d.png" % [DIR, clip, index]):
		list.append(load("%s%s/frame_%02d.png" % [DIR, clip, index]))
		index += 1
	_frames[clip] = list


func set_sleeping(value: bool) -> void:
	if value == _sleeping:
		return
	_sleeping = value
	_belly_up = false
	_next = &""
	_play(SLEEP if value else IDLE, 1)
	if not value:
		_fidget_in = 3.0


## Triste (necessidade baixa): as travessuras passam a ser carinhas tristes.
func set_sad(value: bool) -> void:
	_sad = value


func react(action: StringName) -> void:
	if _sleeping or _belly_up or not REACTIONS.has(action):
		return
	if action == &"pet" and _clip != IDLE:
		return  # o carinho com o dedo já está animando
	var info: Array = REACTIONS[action]
	_play(info[0], info[1])


## Carinho com o dedo. `zone`: &"head", &"belly" ou &"paw"; `seconds` = tempo desde o último aviso.
func stroke(zone: StringName, seconds: float) -> void:
	if _sleeping:
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
		_stroke_time = 0.0
		_next = &"belly_rub"
		_play(ROLL, 1)
		return
	var clip: StringName = {&"head": &"pet_head", &"belly": &"wag_excited", &"paw": &"pet_paw"}.get(zone, IDLE)
	if _clip == clip:
		_loops_left = maxi(_loops_left, 1)  # continua enquanto houver carinho
	else:
		_play(clip, 1)


## Toca `clip` `loops` vezes e depois volta ao descanso (ou segue para `_next`).
func _play(clip: StringName, loops: int, reverse := false) -> void:
	_clip = clip
	_frame = 0
	_clock = 0.0
	_loops_left = loops
	_reverse = reverse
	_show()


func _process(delta: float) -> void:
	if _target == null:
		return
	_stroke_age += delta
	if _stroke_age > 2.0:
		_stroke_time = 0.0
	if _belly_up:
		_belly_timer -= delta
		if _belly_timer <= 0.0 and _clip != ROLL:
			_belly_up = false
			_play(ROLL, 1, true)  # levanta (rola de volta)
			return
	var list: Array = _frames[_clip]
	var resting := _clip == IDLE
	if resting and not _sleeping:
		_fidget_in -= delta
		if _fidget_in <= 0.0:
			_fidget_in = randf_range(4.0, 9.0)
			_play(_pick_fidget(), 1)
			return
	if _clip == SLEEP and _frame >= list.size() - 1:
		return  # dormindo: segura o último quadro
	_clock += delta
	var step: float = 1.0 / float(FPS[_clip])
	while _clock >= step:
		_clock -= step
		_frame += 1
		if _frame >= list.size():
			_frame = 0
			if resting:
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
	_show()


func _finish_clip() -> void:
	if _next != &"":
		var clip := _next
		_next = &""
		if clip == &"belly_rub":
			_belly_up = true
			_belly_timer = BELLY_IDLE
		_play(clip, 1)
		return
	_play(IDLE, 1)
	_fidget_in = randf_range(2.0, 5.0)


func _pick_fidget() -> StringName:
	if _sad and randf() < 0.6:
		return &"sad"
	var total := 0
	for clip: StringName in FIDGETS:
		total += FIDGETS[clip]
	var roll := randi() % total
	for clip: StringName in FIDGETS:
		roll -= FIDGETS[clip]
		if roll < 0:
			return clip
	return &"head_tilt"


func _show() -> void:
	var list: Array = _frames[_clip]
	if list.is_empty():
		return
	var index := mini(_frame, list.size() - 1)
	_target.texture = list[list.size() - 1 - index if _reverse else index]
