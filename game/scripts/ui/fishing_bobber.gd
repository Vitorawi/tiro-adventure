class_name FishingBobber
extends Node2D
## Linha e boia da pesca no mapa (etapa 02). Filha do `World` da sala, então acompanha a câmera.
## PROVISÓRIA: desenhada em código; a 03 troca por arte PixelLab. A linha voa em arco da ponta da vara até a água,
## a boia balança e, na mordida, afunda duas vezes com respingo e um "!" grande.
## Só desenha: quem decide o que acontece é o `FishingFlow` + `GameState`.

signal landed

var rod_tip := Vector2.ZERO  ## ponta da vara (ponto da sala)
var state := "idle"  ## idle | flying | waiting | bite
var wait_fraction := 0.0  ## 0..1 (só mostrado se a espera for longa)
var show_ring := false

var _time := 0.0
var _sink := 0.0  ## 0..1: quanto a boia afundou (mordida)
var _splash := 0.0  ## 0..1: respingo (1 = acabou de acontecer)
var _alert := 0.0  ## 0..1: "!" visível
var _flight: Tween

const BOBBER_SCALE := 0.5  ## a arte é 32 px; ~16 px no mapa (a 03 definitiva pode trazer 16 px)
static var _bobber_tex: Texture2D


func _ready() -> void:
	name = "FishingBobber"
	z_index = 6
	hide()


## A linha sai da ponta da vara e cai em `target` (ponto da sala).
func launch(from: Vector2, target: Vector2) -> void:
	rod_tip = from
	state = "flying"
	_sink = 0.0
	_splash = 0.0
	_alert = 0.0
	show()
	if _flight != null and _flight.is_valid():
		_flight.kill()
	_flight = Motion.fly_arc(self, from, target, 0.45)
	_flight.finished.connect(_on_landed)
	queue_redraw()


func _on_landed() -> void:
	if state != "flying":
		return
	state = "waiting"
	_splash = 1.0 if not Motion.reduced else 0.0
	landed.emit()
	queue_redraw()


## Boia afunda duas vezes, respinga e mostra o "!".
func bite() -> void:
	if state != "waiting" and state != "flying":
		return
	if _flight != null and _flight.is_valid():
		_flight.kill()
	state = "bite"
	_splash = 1.0 if not Motion.reduced else 0.0
	_alert = 1.0
	if Motion.reduced:
		_sink = 0.6
	else:
		var tween := create_tween()
		for repeat in 2:
			tween.tween_property(self, "_sink", 1.0, 0.16)
			tween.tween_property(self, "_sink", 0.15, 0.16)
		tween.tween_property(self, "_sink", 0.6, 0.12)
	Haptics.success()
	queue_redraw()


## Recolhe a linha (toque antes da hora ou fim da pesca).
func retract() -> void:
	state = "idle"
	if _flight != null and _flight.is_valid():
		_flight.kill()
	hide()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_splash = maxf(0.0, _splash - delta * 1.6)
	queue_redraw()


func _draw() -> void:
	if state == "idle":
		return
	var bob := 0.0 if Motion.reduced or state == "flying" else sin(_time * 3.0) * 1.6
	var float_center := Vector2(0, bob + _sink * 7.0)
	# linha: da ponta da vara (em coordenadas locais) até a boia, com uma barriga leve
	var from := rod_tip - position
	var mid := (from + float_center) / 2.0 + Vector2(0, 10)
	draw_polyline(PackedVector2Array([from, from.lerp(mid, 0.5), mid, mid.lerp(float_center, 0.5), float_center]), Color(0.1, 0.1, 0.1, 0.7), 1.5)
	# respingo: cinco quadros do anel de água (arte PixelLab), do mais novo ao mais velho
	if _splash > 0.0:
		var frame := clampi(int((1.0 - _splash) * 5.0), 0, 4)
		var ring := _frames("res://assets/sprites/fx/fishing_splash/%d.png", 5)[frame] as Texture2D
		var ring_half := Vector2(ring.get_size()) * BOBBER_SCALE * 0.5
		draw_texture_rect(ring, Rect2(Vector2(0, 2) - ring_half, ring_half * 2.0), false)
	# boia: bolinha vermelha com topo branco
	var down := clampf(_sink, 0.0, 1.0)
	var tex := _bobber_texture()
	if state == "bite":  # quadros da boia afundando: o mais fundo quando _sink chega a 1
		tex = _frames("res://assets/sprites/fx/fishing_bobber_sink/%d.png", 5)[clampi(int(down * 4.0 + 0.5), 0, 4)]
	var half := Vector2(tex.get_size()) * BOBBER_SCALE / 2.0
	draw_texture_rect(tex, Rect2(float_center - half + Vector2(0, down * 3.0), half * 2.0), false)
	# anel da espera longa
	if show_ring and state == "waiting":
		draw_arc(float_center, 13.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(wait_fraction, 0.0, 1.0), 32, Palette.HONEY, 2.5)
	# "!" grande sobre a boia
	if _alert > 0.0:
		var font := ThemeDB.fallback_font
		draw_circle(float_center + Vector2(0, -30), 13.0, Palette.ALERT)
		draw_circle(float_center + Vector2(0, -30), 13.0, Color.WHITE, false, 2.0)
		draw_string(font, float_center + Vector2(-5, -23), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)


static func _bobber_texture() -> Texture2D:
	if _bobber_tex == null:
		_bobber_tex = load("res://assets/sprites/fx/fishing_bobber.png") as Texture2D
	return _bobber_tex


static var _frame_cache: Dictionary = {}

static func _frames(pattern: String, count: int) -> Array:
	if not _frame_cache.has(pattern):
		var list: Array = []
		for i in count:
			list.append(load(pattern % i))
		_frame_cache[pattern] = list
	return _frame_cache[pattern]
