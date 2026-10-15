class_name WorldTransition
extends CanvasLayer
## Duas massas de nuvem cobrem a troca. O plano permite papel arredondado como alternativa aos sprites.
## A cobertura usa o canvas do mundo (z 5), preservando o HUD (z 8) e as abas acima dela.

var busy: bool = false
var _cover: Control
var _left: Panel
var _right: Panel
var _tween: Tween


func _ready() -> void:
	_cover = Control.new()
	_cover.name = "CloudCover"
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_cover.clip_contents = true
	_cover.z_index = 5
	(get_parent() as Control).add_child.call_deferred(_cover)
	_cover.hide()
	_left = _cloud()
	_right = _cloud()
	_cover.add_child(_left)
	_cover.add_child(_right)


func _cloud() -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.PAPER
	style.set_corner_radius_all(96)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func travel(change_world: Callable) -> void:
	busy = true
	var width := _cover.size.x / 2 + 192
	for cloud: Panel in [_left, _right]:
		cloud.size = Vector2(width, _cover.size.y + 192)
		cloud.position.y = -96
	_left.position.x = -width
	_right.position.x = _cover.size.x
	_cover.show()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_left, "position:x", -96.0, Motion.POP_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_right, "position:x", _cover.size.x / 2 - 96, Motion.POP_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished
	change_world.call()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_left, "position:x", -width, Motion.POP_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_right, "position:x", _cover.size.x, Motion.POP_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished
	_cover.hide()
	busy = false
