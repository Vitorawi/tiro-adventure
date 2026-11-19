class_name TutorialGuide
extends Control
## Peças do foco e da fala usadas pelo Álbum, pela Pesca e pela primeira semana.

const HAND_RETURN := 20.0

var _veil: Control
var _rects: Array[ColorRect] = []
var _highlight: Panel
var _balloon: VBoxContainer
var _balloon_label: Label
var _hand: Control
var _pulse: Tween
var _idle := HAND_RETURN
var _demo_time := 0.0
var _pointer_held := false


static func _main() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var node := tree.root.get_node_or_null("Main")
	return node if node != null else tree.current_scene


func _build_focus(blocking: bool = true) -> void:
	_veil = Control.new()
	_veil.name = "TutorialVeil"
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["T", "B", "L", "R"]:
		var rect := ColorRect.new()
		rect.name = "Veil_" + side
		rect.color = Color(0.0, 0.0, 0.0, 0.5)
		rect.mouse_filter = Control.MOUSE_FILTER_STOP if blocking else Control.MOUSE_FILTER_IGNORE
		_veil.add_child(rect)
		_rects.append(rect)
	_highlight = Panel.new()
	_highlight.name = "TutorialHighlight"
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Palette.HONEY
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	_highlight.add_theme_stylebox_override("panel", style)
	_veil.add_child(_highlight)
	if not Motion.reduced:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_highlight, "modulate:a", 0.45, 0.6)
		_pulse.tween_property(_highlight, "modulate:a", 1.0, 0.6)


func _build_balloon(host: Node, npc: String) -> void:
	_balloon = VBoxContainer.new()
	_balloon.name = "TutorialBalloon"
	_balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(_balloon)
	_balloon_label = ProgressionUi.npc_header(_balloon, npc, "", true, true)


func _build_hand() -> void:
	_hand = Panel.new()
	_hand.name = "TutorialHand"
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand.custom_minimum_size = Vector2(30, 30)
	_hand.size = Vector2(30, 30)
	_hand.pivot_offset = _hand.size * 0.5
	var dot := StyleBoxFlat.new()
	dot.bg_color = Color(1, 1, 1, 0.9)
	dot.border_color = Palette.HONEY
	dot.set_border_width_all(3)
	dot.set_corner_radius_all(15)
	_hand.add_theme_stylebox_override("panel", dot)
	_veil.add_child(_hand)


func _layout_focus(target: Rect2, screen: Vector2) -> Rect2:
	var none := not target.has_area()
	var hole := Rect2(screen * 0.5, Vector2.ZERO) if none else target.grow(6.0)
	_rects[0].position = Vector2.ZERO
	_rects[0].size = Vector2(screen.x, maxf(hole.position.y, 0.0))
	_rects[1].position = Vector2(0, hole.end.y)
	_rects[1].size = Vector2(screen.x, maxf(screen.y - hole.end.y, 0.0))
	_rects[2].position = Vector2(0, hole.position.y)
	_rects[2].size = Vector2(maxf(hole.position.x, 0.0), hole.size.y)
	_rects[3].position = Vector2(hole.end.x, hole.position.y)
	_rects[3].size = Vector2(maxf(screen.x - hole.end.x, 0.0), hole.size.y)
	_highlight.visible = not none
	_highlight.position = hole.position
	_highlight.size = hole.size
	return hole


func _place_above_siblings() -> void:
	var parent := get_parent()
	if parent != null and get_index() != parent.get_child_count() - 1:
		parent.move_child(self, -1)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_pointer_held = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_pointer_held = event.pressed
	elif not (event is InputEventScreenDrag or event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		return
	_idle = 0.0
	_demo_time = 0.0


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		_pointer_held = false


func _reset_hand() -> void:
	_idle = HAND_RETURN
	_demo_time = 0.0


func _guide_hand(delta: float, start: Vector2, finish: Vector2) -> void:
	if not _pointer_held:
		_idle = minf(HAND_RETURN, _idle + delta)
	_hand.visible = _idle >= HAND_RETURN
	if not _hand.visible:
		return
	_demo_time += delta
	var movement := 0.0 if Motion.reduced else smoothstep(0.13, 0.82, fposmod(_demo_time, 1.65) / 1.65)
	_hand.position = start.lerp(finish, movement) - _hand.size * 0.5
	var pressure := 0.08 * sin(_demo_time * TAU / 1.65) if not Motion.reduced and start.is_equal_approx(finish) else 0.0
	_hand.scale = Vector2.ONE * (1.0 + pressure)
