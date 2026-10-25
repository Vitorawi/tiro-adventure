extends "res://scenes/levels/room/room.gd"
var audited_action: String = ""
func _on_object_tapped(action: String, _target: Node = null) -> void:
	audited_action = action
