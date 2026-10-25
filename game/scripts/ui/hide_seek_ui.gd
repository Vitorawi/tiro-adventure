class_name HideSeekUi
extends VBoxContainer
## Esconde-esconde (Cuidar é crescer, etapa 04): o petisco vai para um de três copinhos, eles trocam de lugar
## (3/4/5 trocas por fase) e o jogador toca onde acha que está. O petisco é gasto ao começar; a rodada termina
## acertando ou não e dá o momento de Esperteza (teto do período). O estado do jogo só muda por `GameState`.

const CUP_SIZE := 72.0
const GAP := 12.0

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


func _build() -> void:
	if not cups.is_empty(): return
	add_theme_constant_override("separation", 10)
	var dog := UiKit.icon(null, 160)
	dog.custom_minimum_size.x = 0
	add_child(dog)
	_animator = PetAnimator.new()
	add_child(_animator)
	_animator.setup(dog)
	_stage = Control.new()
	_stage.name = "CupStage"
	_stage.custom_minimum_size = Vector2(0, CUP_SIZE + 40.0)
	add_child(_stage)
	for i in 3:
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
	_status = UiKit.label("", &"")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_status)
	_again = UiKit.button("Jogar de novo", _play_again, &"PrimaryButton")
	_again.name = "HideAgain"
	_again.custom_minimum_size.y = 56
	_again.hide()
	add_child(_again)
	_stage.resized.connect(_place_cups)
	_place_cups.call_deferred()


func _slot_x(slot: int) -> float:
	var total := CUP_SIZE * 3.0 + GAP * 2.0
	return (_stage.size.x - total) * 0.5 + slot * (CUP_SIZE + GAP)


func _place_cups() -> void:
	if cups.is_empty(): return
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
	var error := start(item)
	if error != "": Events.toast_requested.emit(error)
