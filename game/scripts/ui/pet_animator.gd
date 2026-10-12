class_name PetAnimator
extends Node
## Toca as animações do Tiro detalhado (Tela do Pet) num TextureRect.
## Fica em "respirar" parado, sorteia travessuras de vez em quando
## (coçar, bocejar, farejar...) e reage às ações do jogador e ao sono.

const DIR := "res://assets/sprites/characters/tiro_pet/"
const IDLE := &"idle_breathe"
const SLEEP := &"sleep"
## Quadros por segundo de cada animação.
const FPS := {
	&"idle_breathe": 6.0, &"head_tilt": 7.0, &"scratch": 8.0, &"yawn": 6.0, &"sniff": 7.0,
	&"stretch": 7.0, &"bark": 8.0, &"eat": 8.0, &"happy_jump": 9.0, &"shake_off": 10.0,
	&"sleep": 5.0,
}
## Travessuras sorteadas quando ele está parado (peso maior = mais comum).
const FIDGETS := {
	&"head_tilt": 3, &"scratch": 2, &"yawn": 2, &"sniff": 3, &"stretch": 1, &"bark": 1,
}
## Ação do jogador -> [animação, repetições].
const REACTIONS := {
	&"feed": [&"eat", 3], &"play": [&"happy_jump", 3], &"bathe": [&"shake_off", 3],
	&"pet": [&"happy_jump", 1],
}

var _target: TextureRect
var _frames: Dictionary = {}  # nome -> Array[Texture2D]
var _clip: StringName = IDLE
var _frame := 0
var _clock := 0.0
var _loops_left := 0
var _fidget_in := 5.0
var _sleeping := false


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
	_play(SLEEP if value else IDLE, 1)
	if not value:
		_fidget_in = 3.0


func react(action: StringName) -> void:
	if _sleeping or not REACTIONS.has(action):
		return
	var info: Array = REACTIONS[action]
	_play(info[0], info[1])


## Toca `clip` `loops` vezes e depois volta ao descanso (ou segura o último quadro no sono).
func _play(clip: StringName, loops: int) -> void:
	_clip = clip
	_frame = 0
	_clock = 0.0
	_loops_left = loops
	_show()


func _process(delta: float) -> void:
	if _target == null:
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
			_loops_left -= 1
			if _loops_left <= 0:
				_play(IDLE, 1)
				return
	_show()


func _pick_fidget() -> StringName:
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
	if not list.is_empty():
		_target.texture = list[mini(_frame, list.size() - 1)]
