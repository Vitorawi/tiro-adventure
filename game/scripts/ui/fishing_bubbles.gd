class_name FishingBubbles
extends Node2D
## Bolhas quentes da lagoa (etapa 02): círculos que sobem no ponto da bolha ativa (`GameState.fishing.bubble`).
## PROVISÓRIO em código; com "Menos animação" fica só um anel parado.
## Os pontos vêm da sala (`points.fishing_bubble_1..N`), na mesma ordem do índice `bubble.spot`.

var spots: Array[Vector2] = []

var _active := -1
var _time := 0.0


func _ready() -> void:
	name = "FishingBubbles"
	z_index = 2
	Events.state_changed.connect(refresh)
	Events.fishing_changed.connect(refresh)
	refresh()


## Índice do ponto com bolha agora (−1 = nenhuma). Só existe com vara e fora de pesca em andamento.
func active_spot() -> int:
	return _active


func refresh() -> void:
	var bubble := GameState.fishing.bubble
	var next := -1
	if not bubble.is_empty() and GameState.current_rod() != "":
		next = clampi(int(bubble.get("spot", 0)), 0, maxi(0, spots.size() - 1)) if not spots.is_empty() else -1
	if next != _active:
		_active = next
		visible = next >= 0
		queue_redraw()


func spot_position(index: int) -> Vector2:
	return spots[index] if index >= 0 and index < spots.size() else Vector2.INF


func _process(delta: float) -> void:
	if _active < 0 or not is_visible_in_tree():
		return
	_time += delta
	if not Motion.reduced:
		queue_redraw()


func _draw() -> void:
	if _active < 0 or _active >= spots.size():
		return
	var center := spots[_active]
	var tone := Color(1, 1, 1, 0.85)
	draw_arc(center, 11.0, 0, TAU, 24, Color(1, 1, 1, 0.55), 2.0)  # anel que marca o lugar (parado)
	if Motion.reduced:
		return
	for i in 5:
		var phase := fposmod(_time * 0.7 + i * 0.2, 1.0)
		var offset := Vector2(sin((_time + i) * 2.0) * 5.0 + (i - 2) * 4.0, -phase * 26.0)
		var side := 8.0 + (i % 3) * 3.0
		var tex := _bubble_texture()
		draw_texture_rect(tex, Rect2(center + offset - Vector2(side, side) / 2.0, Vector2(side, side)), false, Color(1, 1, 1, 1.0 - phase))


static var _bubble_tex: Texture2D

static func _bubble_texture() -> Texture2D:
	if _bubble_tex == null:
		_bubble_tex = load("res://assets/sprites/fx/fishing_bubble.png") as Texture2D
	return _bubble_tex
