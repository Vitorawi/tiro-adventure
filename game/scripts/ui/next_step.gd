class_name NextStep
extends Button
## Pílula do próximo passo da HISTÓRIA (segunda linha do HUD, nas quatro abas): rosto de quem pede, ícone do
## objetivo, `valor/alvo` e `›`. Pronto = pílula verde "Pegar" (um toque entrega). O resto abre o mini-cartão.
## Só lê (`QuestGuide.current()`); quem muda o jogo é o `GameState.claim_quest` do toque.

const HEIGHT := 48.0
const PAD := 12.0
const COMPACT_MAX_WIDTH := 140.0

## Modo do Mapa: retrato 32, ícone 28, sem `›`, largura até 140.
var compact: bool = false:
	set(value):
		compact = value
		_rebuild()
## Sem espaço (nome de mundo longo): só retrato e número.
var mini: bool = false:
	set(value):
		mini = value
		_rebuild()

var _row: HBoxContainer
var _face: Control
var _icon: TextureRect
var _count: Label
var _chevron: TextureRect
var _claim: HBoxContainer
var _claim_text: Label
var _portrait: Texture2D
var _guide: Dictionary = {"state": "hidden", "id": ""}
var _shown_id: String = ""
var _shown_value: int = -1
var _tween: Tween


func _init() -> void:
	name = "NextStep"
	custom_minimum_size = Vector2(0, HEIGHT)
	focus_mode = Control.FOCUS_NONE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	visible = false
	_row = UiKit.hbox(6)
	_row.name = "StepRow"
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_row)
	_face = Control.new()
	_face.name = "StepFace"
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_face.draw.connect(_draw_face)
	_row.add_child(_face)
	_icon = UiKit.icon(null, 32)
	_icon.name = "StepIcon"
	_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(_icon)
	_count = UiKit.short_label("", &"NumberLabel")
	_count.name = "StepCount"
	_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(_count)
	_chevron = UiKit.ctl("chev", 16, Palette.INK_FAINT)
	_chevron.name = "StepChevron"
	_chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_row.add_child(_chevron)
	_claim = UiKit.hbox(4)
	_claim.name = "StepClaim"
	_claim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_claim.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_claim_text = UiKit.label("Pegar", &"StrongLabel", Palette.CARD)
	_claim_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	_claim.add_child(_claim_text)
	_claim.add_child(UiKit.ctl("check", 18, Palette.CARD))
	_row.add_child(_claim)
	Motion.press(self)
	pressed.connect(_on_pressed)
	var beat := Timer.new()
	beat.wait_time = 4.0
	beat.autostart = true
	beat.timeout.connect(func() -> void:
		if visible and not Motion.reduced and _is_ready() and not _row_busy():
			Motion.bounce(self))
	add_child(beat)
	Events.state_changed.connect(refresh)
	_rebuild()


func _ready() -> void:
	refresh()


func _row_busy() -> bool:
	return get_parent() == null or not is_visible_in_tree()


func _is_ready() -> bool:
	return str(_guide.state) in ["ready", "shared_ready"]


func _face_px() -> float:
	return 32.0 if compact else 40.0


## Lê o passo atual e redesenha. Só lê: nunca entrega nada daqui.
func refresh() -> void:
	_guide = QuestGuide.current()
	var state := str(_guide.state)
	visible = state != "hidden"
	if not visible:
		_shown_id = ""
		_shown_value = -1
		return
	var goal: Dictionary = _guide.goal
	_portrait = ProgressionUi.npc_portrait(str(_guide.npc))
	_face.queue_redraw()
	if state == "blocked_storage":
		var depot: Dictionary = GameState.quest_reward_shortage(str(_guide.id))
		_icon.texture = UiKit.ui_icon(str(Database.progression.storage.get(str(depot.get("depot", "")), {}).get("icon", "tab_bag")))
	else:
		_icon.texture = ProgressionUi.goal_icon(goal)
	var value := int(_guide.value)
	var fmt := "%d/" + str(int(_guide.target))
	var rose := str(_guide.id) == _shown_id and _shown_value >= 0 and value > _shown_value
	if _tween:
		_tween.kill()
	if rose:
		_tween = Motion.count_up(_count, _shown_value, value, fmt)
		Motion.bounce(self)
	else:
		_count.text = fmt % value
	_shown_id = str(_guide.id)
	_shown_value = value
	_rebuild()


## Cores e peças de cada estado; recalcula o tamanho (o botão não cresce sozinho com os filhos).
func _rebuild() -> void:
	if _row == null:
		return
	var state := str(_guide.state)
	var ready := _is_ready()
	var fill := Palette.CARD
	var ink := Palette.INK
	if ready:
		fill = Palette.GO
		ink = Palette.CARD
	elif state == "blocked_storage":
		fill = Palette.ALERT_SOFT
		ink = Palette.ALERT_INK
	for phase: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(phase, UiKit.surface(fill if phase != "pressed" else fill.darkened(0.04), int(HEIGHT / 2.0), true))
	_count.add_theme_color_override("font_color", ink)
	_face.custom_minimum_size = Vector2(_face_px(), _face_px())
	_face.size = _face.custom_minimum_size
	_icon.custom_minimum_size = Vector2(28, 28) if compact else Vector2(32, 32)
	# `talk`: o rosto já é o personagem; o ícone do objetivo repetiria o retrato.
	_icon.visible = not mini and not ready and state != "talk"
	_chevron.visible = not compact and not mini and not ready
	_claim.visible = ready
	_claim_text.visible = not compact  # compacto: só o ✓ (cabe nos 140 px do Mapa)
	var width := _row.get_combined_minimum_size().x + PAD * 2.0
	if compact:
		width = minf(width, COMPACT_MAX_WIDTH)
	custom_minimum_size = Vector2(width, HEIGHT)
	size = custom_minimum_size
	_row.position = Vector2(PAD, 0.0)
	_row.size = Vector2(width - PAD * 2.0, HEIGHT)
	pivot_offset = size / 2.0


## Largura que a pílula pede no modo atual (o Mapa decide se cabe).
func wanted_width() -> float:
	return custom_minimum_size.x


func _draw_face() -> void:
	var px := _face_px()
	var center := Vector2(px, px) / 2.0
	_face.draw_circle(center, px / 2.0, Palette.SUNKEN)
	if _portrait == null:
		return
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 40:
		var unit := Vector2.from_angle(TAU * i / 40.0)
		points.append(center + unit * (px / 2.0 - 2.0))
		uvs.append(Vector2(0.5, 0.5) + unit * 0.5)
	_face.draw_colored_polygon(points, Color.WHITE, uvs, _portrait)


func _on_pressed() -> void:
	var id := str(_guide.id)
	if id == "":
		return
	if _is_ready():
		ProgressionUi.claim_quest_fx(id, get_global_rect().get_center())
		return
	var host := get_tree().root.find_child("Main", true, false) as Control
	if host == null:
		host = get_parent() as Control
	Popover.open(host, self, NextStep.card(id), 0.0)


## Mini-cartão (02 §2.2): fala curta, objetivos, prêmios e `?` + `Ir` (ou "Liberar espaço"). Estático: dá para
## montar sem a casca. Os botões fecham o `PopoverCatcher` mais próximo.
static func card(id: String) -> Control:
	var quest: Dictionary = Database.quests[id]
	var box := UiKit.vbox(8)
	box.name = "StepCard"
	box.custom_minimum_size.x = 264
	var head := UiKit.hbox(8)
	var face := UiKit.disc(ProgressionUi.npc_portrait(str(quest.get("npc", ""))), 40, 40)
	face.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	head.add_child(face)
	var speech := UiKit.short_label(str(quest.get("dialogue", quest.get("name", ""))), &"")
	speech.name = "StepSpeech"
	speech.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	speech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speech.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speech.custom_minimum_size.x = 200
	head.add_child(speech)
	box.add_child(head)
	for goal: Dictionary in quest.goals:
		box.add_child(ProgressionUi.goal_row(goal, GameState.goal_value(goal)))
	var prizes := ProgressionUi.reward_chips(quest.get("rewards", {}))
	if prizes.get_child_count() > 0:
		box.add_child(prizes)
	var shortage := GameState.quest_reward_shortage(id)
	var actions := UiKit.hbox(8)
	var help := UiKit.ctl_button("help", func() -> void:
		_close_popover()
		TaskHelp.open("quest", id), 40, "sunken")
	help.name = "StepCardHelp"
	actions.add_child(help)
	if shortage.is_empty():
		var go := UiKit.primary("Ir", func() -> void:
			_close_popover()
			Places.go(Places.quest_target(id)))
		go.name = "StepCardGo"
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(go)
	else:
		var space := UiKit.primary("Liberar espaço", func() -> void:
			_close_popover()
			Places.go({"storage": str(shortage.depot)}))
		space.name = "StepCardSpace"
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(space)
	box.add_child(actions)
	return box


static func _close_popover() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var catcher := tree.root.find_child("PopoverCatcher", true, false)
	if catcher:
		catcher.queue_free()
