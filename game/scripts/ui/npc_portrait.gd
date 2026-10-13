class_name NpcPortrait
extends TextureRect
## Retrato de conversa: pedido em loop e aceno completo ao receber uma missão.
## Só estado visual local; não altera progresso nem reinicia com os timers do painel.

var npc_id: String = ""
var _animations: Dictionary = {}
var _idle: Texture2D
var _mode: String = ""
var _frame: int = 0


func _ready() -> void:
	_idle = ProgressionUi.npc_portrait(npc_id)
	texture = _idle
	var config: Dictionary = Database.npcs.get(npc_id, {}).get("portrait_animations", {})
	for mode: String in config:
		var folder: String = config[mode]
		var frames: Array[Texture2D] = []
		var files := Array(ResourceLoader.list_directory(folder))
		files.sort()
		for file: String in files:
			if file.ends_with(".png"):
				frames.append(load(folder + file))
		_animations[mode] = frames
	Events.quest_completed.connect(_on_quest_completed)
	var timer := Timer.new()
	timer.wait_time = 0.125
	timer.timeout.connect(_tick)
	add_child(timer)
	timer.start()
	_tick()


func _on_quest_completed(id: String) -> void:
	if Database.quests.get(id, {}).get("npc", "") == npc_id and is_visible_in_tree():
		_mode = "complete"
		_frame = 0


func _tick() -> void:
	if not is_visible_in_tree():
		return
	if _mode != "complete":
		var mode := "request" if not Places.npc_active_quests(npc_id).is_empty() else ""
		if mode != _mode:
			_frame = 0
		_mode = mode
	var frames: Array = _animations.get(_mode, [])
	if frames.is_empty():
		texture = _idle
		_mode = ""
		return
	texture = frames[_frame]
	_frame += 1
	if _frame >= frames.size():
		_frame = 0
		if _mode == "complete":
			_mode = ""
