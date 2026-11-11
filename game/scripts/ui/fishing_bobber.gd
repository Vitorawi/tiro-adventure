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
	# respingo
	if _splash > 0.0:
		var radius := 9.0 + (1.0 - _splash) * 16.0
		draw_arc(Vector2(0, 2), radius, 0, TAU, 28, Color(1, 1, 1, _splash * 0.8), 2.0)
		draw_arc(Vector2(0, 2), radius * 0.6, 0, TAU, 20, Color(1, 1, 1, _splash * 0.6), 1.5)
	# boia: bolinha vermelha com topo branco
	var down := clampf(_sink, 0.0, 1.0)
	draw_circle(float_center + Vector2(0, 2), 6.5, Color(0.1, 0.1, 0.1, 0.35))
	draw_circle(float_center, 6.0, Color("d9402e"))
	draw_circle(float_center + Vector2(0, -2.5), 3.4 * (1.0 - down * 0.4), Color.WHITE)
	# anel da espera longa
	if show_ring and state == "waiting":
		draw_arc(float_center, 13.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(wait_fraction, 0.0, 1.0), 32, Palette.HONEY, 2.5)
	# "!" grande sobre a boia
	if _alert > 0.0:
		var font := ThemeDB.fallback_font
		draw_circle(float_center + Vector2(0, -30), 13.0, Palette.ALERT)
		draw_circle(float_center + Vector2(0, -30), 13.0, Color.WHITE, false, 2.0)
		draw_string(font, float_center + Vector2(-5, -23), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
