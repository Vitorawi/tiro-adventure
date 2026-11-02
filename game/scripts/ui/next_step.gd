class_name NextStep
extends Button
## Cartão de madeira do próximo passo da HISTÓRIA (segunda linha do HUD, só na aba Tiro): retrato de quem pede,
## ícone do objetivo em pixel e `valor/alvo`; a seta já vem na arte. Pronto = selo verde "Pegar" (um toque entrega).
## O resto abre o mini-cartão. Só lê (`QuestGuide.current()`); quem muda o jogo é o `GameState.claim_quest` do toque.
## Cartão fixo de 140×65 (posições do protótipo); os modos `compact`/`mini` do Mapa existem por compatibilidade.

const HEIGHT := 65.0
const WIDTH := 140.0
const PAD := 12.0
const COMPACT_MAX_WIDTH := 140.0
const FACE := Rect2(11.0, 10.0, 42.0, 42.0)
const ICON := Rect2(67.0, 10.0, 28.0, 28.0)
const COUNT := Rect2(55.0, 37.0, 52.0, 18.0)

## Modo do Mapa: mesmo cartão (já cabe nos 140 px).
var compact: bool = false:
	set(value):
		compact = value
		_rebuild()
## Sem espaço (nome de mundo longo): mesmo cartão; guardado só para o Mapa.
var mini: bool = false:
	set(value):
		mini = value
		_rebuild()

var _row: Control
var _face: Control
var _icon: TextureRect
var _count: Label
var _chevron: TextureRect
var _claim: PanelContainer
var _claim_text: Label
var _portrait: Texture2D
var _guide: Dictionary = {"state": "hidden", "id": ""}
var _shown_id: String = ""
var _shown_value: int = -1
var _tween: Tween
var _skin: StyleBoxTexture
var shown_on_screen: bool = true:
	set(value):
		shown_on_screen = value
		refresh()


func _init() -> void:
	name = "NextStep"
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	focus_mode = Control.FOCUS_NONE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	visible = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # cartão ilustrado suave; rosto e ícone pedem nearest neles
	_skin = StyleBoxTexture.new()
	_skin.texture = HomeUi.tex("quest_card")
	_row = Control.new()
	_row.name = "StepRow"
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	_face = Control.new()
	_face.name = "StepFace"
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_face.position = FACE.position
	_face.size = FACE.size
	_face.draw.connect(_draw_face)
	_row.add_child(_face)
	_icon = UiKit.icon(null, 28)
	_icon.name = "StepIcon"
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.position = ICON.position
	_icon.size = ICON.size
	_row.add_child(_icon)
	_count = HomeUi.text(_row, "", COUNT, 14, Palette.WOOD_INK, Palette.WOOD_INK, 0, "StepCount")
	# A seta do cartão já está na arte; o nó continua existindo (escondido) para quem o procura.
	_chevron = UiKit.ctl("chev", 16, Palette.INK_FAINT)
	_chevron.name = "StepChevron"
	_chevron.visible = false
	_row.add_child(_chevron)
	_claim = PanelContainer.new()
	_claim.name = "StepClaim"
	_claim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_claim.add_theme_stylebox_override("panel", UiKit.surface(Palette.GO, 14, true))
	_claim.position = Vector2(58.0, 14.0)
	_claim.size = Vector2(66.0, 32.0)
	var claim_row := UiKit.hbox(4)
	claim_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	claim_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_claim_text = UiKit.label("Pegar", &"StrongLabel", Palette.CARD)
	_claim_text.autowrap_mode = TextServer.AUTOWRAP_OFF
	claim_row.add_child(_claim_text)
	claim_row.add_child(UiKit.ctl("check", 16, Palette.CARD))
	_claim.add_child(claim_row)
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


## Lê o passo atual e redesenha. Só lê: nunca entrega nada daqui.
func refresh() -> void:
	_guide = QuestGuide.current()
	var state := str(_guide.state)
	visible = shown_on_screen and state != "hidden"
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


## Estado do cartão: pronto troca o ícone/número pelo selo "Pegar"; espaço cheio avermelha o papel.
func _rebuild() -> void:
	if _row == null:
		return
	var state := str(_guide.state)
	var ready := _is_ready()
	_skin.modulate_color = Color(1.0, 0.86, 0.82) if state == "blocked_storage" else Color.WHITE
	for phase: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		add_theme_stylebox_override(phase, _skin)
	# `talk`: o retrato já é o personagem; o ícone do objetivo repetiria.
	_icon.visible = not ready and state != "talk"
	_count.visible = not ready
	_claim.visible = ready
	custom_minimum_size = Vector2(WIDTH, HEIGHT)
	size = custom_minimum_size
	_row.position = Vector2.ZERO
	_row.size = size
	pivot_offset = size / 2.0


## Largura que o cartão pede (fixa: o Mapa decide se cabe).
func wanted_width() -> float:
	return custom_minimum_size.x


func _draw_face() -> void:
	var rect := Rect2(Vector2.ZERO, FACE.size)
	if _portrait == null:
		_face.draw_rect(rect, Palette.SUNKEN)
		return
	_face.draw_texture_rect(_portrait, rect, false)


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


## Mini-cartão da madeira ilustrada (`StepCardUi`): retrato + fala, uma linha por objetivo com barra, prêmios, `?` e
## `Ir` (ou "Liberar espaço"). Estático: dá para montar sem a casca. Os botões fecham o `PopoverCatcher` mais próximo.
static func card(id: String) -> Control:
	return StepCardUi.build(id)


static func _close_popover() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var catcher := tree.root.find_child("PopoverCatcher", true, false)
	if catcher:
		catcher.queue_free()
