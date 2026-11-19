class_name HideSeekUi
extends VBoxContainer
## Esconde-esconde (Cuidar é crescer, etapa 04): o petisco vai para um de três copinhos, eles trocam de lugar
## (3/4/5 trocas por fase) e o jogador toca onde acha que está. O petisco é gasto ao começar; a rodada termina
## acertando ou não e dá o momento de Esperteza (teto do período). O estado do jogo só muda por `GameState`.

const CUP_SIZE := 72.0
const GAP := 12.0
const COOP := preload("res://assets/sprites/areas/farm/figma_galinheiro.png")
const ORCHARD := preload("res://assets/sprites/areas/farm/orchard.png")
const FLOWER := preload("res://assets/sprites/ui/icons/item_wildflower.png")
const GRASS := preload("res://assets/sprites/areas/common/grass_ground.png")

var item := ""
var cups: Array[Control] = []
## `slots[copo]` = posição (0..2) em que o copo está agora.
var slots: Array[int] = [0, 1, 2]
var treat_cup := 0
var plan: Array[Vector2i] = []
var ready_to_pick := false
var finished := false
var found := false
var _stage: Control
var _status: Label
var _treat: TextureRect
var _again: Button
var _animator: PetAnimator
var _tween: Tween
var _yard_round: Dictionary = {}
var _tail: Control
var _dog: TextureRect


## Folha em madeira ilustrada (a `Sheet` lê a meta ao abrir o conteúdo).
func _init() -> void:
	set_meta("sheet_wood", true)


func start(treat: String) -> String:
	_build()
	item = treat
	var error := GameState.hide_and_seek(treat)
	if error != "":
		return error
	treat_cup = randi() % 3
	slots = [0, 1, 2]
	plan.clear()
	var last := Vector2i(-1, -1)
	while plan.size() < GameState.hide_swaps():
		var a := randi() % 3
		var b := (a + 1 + randi() % 2) % 3
		var pair := Vector2i(mini(a, b), maxi(a, b))
		if pair != last:
			plan.append(pair)
			last = pair
	ready_to_pick = false
	finished = false
	found = false
	_place_cups()
	_treat.texture = Database.item_icon(treat)
	_treat.show()
	_status.text = "Olha onde está o petisco!"
	_again.hide()
	_play_plan()
	return ""


func _ready() -> void:
	_build()


func start_yard() -> String:
	var round := GameState.start_yard_round("hide")
	if round.has("error"): return str(round.error)
	_yard_round = round
	set_meta("sheet_fit_content", true)
	_build()
	_start_yard_preview()
	return ""


func _start_yard_preview() -> void:
	ready_to_pick = false
	finished = false
	found = false
	_status.text = "Tiro está se escondendo…"
	_dog.modulate.a = 1.0
	_tail.hide()
	_again.modulate.a = 0.0
	_again.disabled = true
	for cup: Control in cups:
		(cup as BaseButton).disabled = true
	set_process(true)


func _process(_delta: float) -> void:
	if _yard_round.is_empty() or ready_to_pick or finished:
		set_process(false)
		return
	if Time.get_ticks_msec() / 1000.0 - float(_yard_round.since) < 1.1: return
	ready_to_pick = true
	_dog.modulate.a = 0.0
	_tail.show()
	for cup: Control in cups:
		(cup as BaseButton).disabled = false
	_place_cups()
	_status.text = "Procure o rabo e toque no esconderijo."
	set_process(false)


func _exit_tree() -> void:
	if not _yard_round.is_empty():
		GameState.cancel_yard_round(int(_yard_round.id))


func _build() -> void:
	if not cups.is_empty(): return
	add_theme_constant_override("separation", 10)
	var in_yard := not _yard_round.is_empty()
	_dog = UiKit.icon(null, 128 if in_yard else 160)
	_dog.custom_minimum_size.x = 0
	if not in_yard: add_child(_dog)
	_animator = PetAnimator.new()
	add_child(_animator)
	_stage = Control.new()
	_stage.name = "CupStage"
	_stage.custom_minimum_size = Vector2(0, 174.0 if in_yard else CUP_SIZE + 40.0)
	add_child(_stage)
	if in_yard:
		_stage.clip_contents = true
		_stage.add_child(_dog)
		_dog.size = Vector2(128, 128)
		_stage.draw.connect(_draw_yard_ground)
		_stage.resized.connect(_stage.queue_redraw)
		_tail = Control.new()
		_tail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tail.z_index = 2
		_tail.draw.connect(_draw_tail)
		_stage.add_child(_tail)
	_animator.setup(_dog)
	for i in 3:
		if not _yard_round.is_empty():
			_add_hideout(i)
			continue
		var cup := TextureButton.new()
		cup.name = "Cup_%d" % i
		cup.texture_normal = UiKit.ui_icon("hide_cup")
		cup.ignore_texture_size = true
		cup.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		cup.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cup.custom_minimum_size = Vector2(CUP_SIZE, CUP_SIZE)
		cup.size = Vector2(CUP_SIZE, CUP_SIZE)
		cup.pressed.connect(choose.bind(i))
		_stage.add_child(cup)
		cups.append(cup)
	_treat = UiKit.icon(null, 40)
	_treat.name = "Treat"
	_treat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(_treat)
	_treat.hide()
	_status = StepCardUi.wood("", 18)
	_status.name = "HideStatus"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	_again = StepCardUi.go_button("Jogar de novo", _play_again)
	_again.name = "HideAgain"
	_again.custom_minimum_size.y = 56
	_again.visible = in_yard
	add_child(_again)
	_stage.resized.connect(_place_cups)
	_place_cups.call_deferred()


func _add_hideout(index: int) -> void:
	var label := str(GameState.yard_rules().hideouts[index])
	var spot := BagUi.plain_button(choose.bind(index))
	spot.name = "Hideout_%d" % index
	spot.custom_minimum_size = Vector2(CUP_SIZE, 30)
	spot.size = Vector2(CUP_SIZE, 84)
	spot.tooltip_text = label
	var tile := SellUi.nine("tile", CodexUi.TILE_MARGINS, "HideoutTile", null, "codex_")
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spot.add_child(tile)
	StepCardUi.stretch(tile)
	_stage.add_child(spot)
	cups.append(spot)
	var icon := UiKit.icon([FLOWER, COOP, ORCHARD][index], 56)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(8, 0)
	spot.add_child(icon)
	if index == 0:
		icon.position.y = 6
		icon.custom_minimum_size.y = 44
		icon.size.y = 44
		icon.draw.connect(func() -> void:
			icon.draw_colored_polygon(PackedVector2Array([Vector2(12, 30), Vector2(44, 30), Vector2(38, 43), Vector2(18, 43)]), Color("b65c40")))
	var caption := StepCardUi.wood(label, 14)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.position = Vector2(0, 55)
	caption.size = Vector2(CUP_SIZE, 26)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spot.add_child(caption)


func _draw_yard_ground() -> void:
	_stage.draw_texture_rect(GRASS, Rect2(Vector2.ZERO, _stage.size), true, Color("dce1a5"))


func _draw_tail() -> void:
	var points := PackedVector2Array([Vector2(0, 12), Vector2(6, 10), Vector2(13, 4), Vector2(13, 0)])
	_tail.draw_polyline(points, Color("59391e"), 9, true)
	_tail.draw_polyline(points, Color("b9844c"), 5, true)


func _slot_x(slot: int) -> float:
	var total := CUP_SIZE * 3.0 + GAP * 2.0
	return (_stage.size.x - total) * 0.5 + slot * (CUP_SIZE + GAP)


func _place_cups() -> void:
	if cups.is_empty(): return
	if not _yard_round.is_empty():
		for i in 3:
			cups[i].position = Vector2(_slot_x(i), 81)
		_dog.position = Vector2((_stage.size.x - _dog.size.x) * 0.5, -15)
		_tail.position = cups[int(_yard_round.hideout)].position + Vector2(58, 21)
		return
	for i in 3:
		cups[i].position = Vector2(_slot_x(slots[i]), 36)
	_place_treat()


func _place_treat() -> void:
	var cup := cups[treat_cup]
	_treat.position = cup.position + Vector2((CUP_SIZE - 40.0) * 0.5, CUP_SIZE - 30.0)


func _play_plan() -> void:
	if _tween and _tween.is_valid(): _tween.kill()
	if Motion.reduced or not is_inside_tree():
		skip_animation()
		return
	_tween = create_tween()
	_tween.tween_interval(1.0)
	_tween.tween_callback(_treat.hide)
	for pair: Vector2i in plan:
		_tween.tween_callback(_swap.bind(pair))
		_tween.tween_interval(0.42)
	_tween.tween_callback(_open_picking)


func _swap(pair: Vector2i) -> void:
	var a := slots.find(pair.x)
	var b := slots.find(pair.y)
	slots[a] = pair.y
	slots[b] = pair.x
	for i in [a, b]:
		var tween := create_tween()
		tween.tween_property(cups[i], "position:x", _slot_x(slots[i]), 0.36)


## Teste/menos animação: termina as trocas na hora e libera a escolha.
func skip_animation() -> void:
	if _tween and _tween.is_valid(): _tween.kill()
	slots = [0, 1, 2]
	for pair: Vector2i in plan:
		var a := slots.find(pair.x)
		var b := slots.find(pair.y)
		slots[a] = pair.y
		slots[b] = pair.x
	_treat.hide()
	_place_cups()
	_open_picking()


func _open_picking() -> void:
	ready_to_pick = true
	_status.text = "Onde está o petisco?"


func choose(cup: int) -> void:
	if not ready_to_pick or finished: return
	if not _yard_round.is_empty():
		var outcome := GameState.yard_find(int(_yard_round.id), cup)
		if outcome.is_empty(): return
		found = bool(outcome.found)
		if not found:
			_status.text = "Ainda não! Procure o rabinho."
			return
		finished = true
		ready_to_pick = false
		_tail.hide()
		_dog.modulate.a = 1.0
		_animator.react(&"play")
		_again.modulate.a = 1.0
		_again.disabled = false
		_status.text = "Achou! Contou para crescer." if outcome.rewarded else "Achou! Só por diversão neste período."
		return
	finished = true
	ready_to_pick = false
	found = cup == treat_cup
	var gained := GameState.finish_hide_and_seek(found)
	_place_treat()
	_treat.show()
	cups[treat_cup].position.y -= 24
	if found:
		_status.text = "Achou! Festa!" if gained == 0 else "Achou! Momento de Esperteza!"
		if _animator: _animator.react(&"play")
	else:
		_status.text = "Era aquele! Ele comeu mesmo assim." if gained == 0 else "Era aquele! Momento de Esperteza!"
	_again.visible = GameState.hide_and_seek_error(item) == ""


func _play_again() -> void:
	if not _yard_round.is_empty():
		var error := start_yard()
		if error != "": Events.toast_requested.emit(error)
		return
	var error := start(item)
	if error != "": Events.toast_requested.emit(error)
