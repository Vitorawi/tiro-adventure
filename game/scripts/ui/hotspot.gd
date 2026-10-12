class_name Hotspot
extends Control
## Área tocável invisível (geladeira, fogão, Tiro...).
##
## Emite `tapped` apenas em toque curto: se o dedo arrastar, o evento segue
## para o pai (que move a câmera) e o toque é ignorado.

signal tapped

const TAP_SLOP := 12.0

var _press_position := Vector2.ZERO
var _pressing := false
var _flash := 0.0:
	set(value):
		_flash = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_pressing = true
		_press_position = button.global_position
	elif _pressing:
		_pressing = false
		if button.global_position.distance_to(_press_position) <= TAP_SLOP:
			_flash = 0.35
			create_tween().tween_property(self, "_flash", 0.0, 0.25)
			tapped.emit()


func _draw() -> void:
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, _flash))
