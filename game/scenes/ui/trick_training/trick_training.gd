class_name TrickTraining
extends VBoxContainer
## Minijogo sem custo: tentativas locais, o estado persistente só muda ao aprender.

var trick_id: String = "paw"
var marker: float = 0.0
var zone_center: float = 0.5
var hits: int = 0
var _busy: bool = false
var _done: bool = false
var _motion: Tween
var _bar: Control
var _feedback: Label
var _points: HBoxContainer
var _button: Button
var _animator: PetAnimator


func _ready() -> void:
	add_child(UiKit.label("Toque quando a marca entrar no verde", &"SmallLabel"))
	var dog := UiKit.icon(null, 216)
	dog.custom_minimum_size.x = 0
	add_child(dog)
	_animator = PetAnimator.new()
	add_child(_animator)
	_animator.setup(dog)
	_points = UiKit.hbox(12)
	_points.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_points)
	for i in int(Database.progression.trick_settings.hits):
		_points.add_child(UiKit.icon(UiKit.ui_icon("rare_star"), 32))
	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(0, 56)
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	_feedback = UiKit.label("Sem pressa!", &"SectionLabel")
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_feedback)
	_button = UiKit.button("Agora!", attempt, &"PrimaryButton")
	_button.custom_minimum_size.y = 64
	add_child(_button)
	add_child(UiKit.button("Voltar ao treino", func() -> void:
		Events.sheet_requested.emit("Treino", TrickUi.panel(true))))
	Events.state_changed.connect(_validate)
	_attempt_ready()


## Consulta pura: não consome tentativa nem altera progresso.
func check_hit(value: float) -> bool:
	var half := float(Database.progression.tricks[trick_id].zone) * 0.5
	return value >= zone_center - half and value <= zone_center + half


func _attempt_ready() -> void:
	zone_center = randf_range(0.43, 0.57)
	marker = 0.0
	_busy = false
	for i in _points.get_child_count():
		_points.get_child(i).modulate = Color.WHITE if i < hits else Color(0.4, 0.4, 0.4, 0.35)
	_motion = create_tween().set_loops()
	var seconds := float(Database.progression.tricks[trick_id].speed)
	_motion.tween_property(self, "marker", 1.0, seconds).from(0.0)
	_motion.tween_property(self, "marker", 0.0, seconds)
	_validate()


func _validate() -> void:
	if _done:
		return
	var error := GameState.learn_trick_error(trick_id)
	_button.disabled = _busy or error != ""
	if error != "":
		_feedback.text = error
	_animator.set_sleeping(GameState.dog.sleeping)


func _process(_delta: float) -> void:
	_bar.queue_redraw()


func _draw_bar() -> void:
	var width := _bar.size.x - 12.0
	_bar.draw_rect(Rect2(6, 8, width, 40), Color("352c39"))
	var zone := float(Database.progression.tricks[trick_id].zone)
	_bar.draw_rect(Rect2(6 + (zone_center - zone * 0.5) * width, 8, zone * width, 40), Color("66cc73"))
	_bar.draw_rect(Rect2(4 + marker * width, 0, 4, 56), Color("fff2b0"))


func attempt() -> void:
	if _done:
		Events.sheet_requested.emit("Treino", TrickUi.panel(true))
		return
	if _busy:
		return
	var error := GameState.learn_trick_error(trick_id)
	if error != "":
		_feedback.text = error
		return
	_busy = true
	_button.disabled = true
	_motion.kill()
	var success := check_hit(marker)
	_feedback.text = "Isso!" if success else "Quase! Tente de novo"
	if success:
		hits += 1
		_points.get_child(hits - 1).modulate = Color.WHITE
		_animator.react(StringName(Database.progression.tricks[trick_id].animation))
	if hits >= int(Database.progression.trick_settings.hits):
		_done = true
		error = GameState.learn_trick(trick_id)
		_feedback.text = "Aprendeu!" if error == "" else error
		_button.text = "Voltar ao treino"
		_button.disabled = false
		return
	await get_tree().create_timer(1.2).timeout
	if is_inside_tree():
		_attempt_ready()


## Posição forçada apenas no teste/DEV; segue a mesma ação e trava contra toque duplo.
func dev_force_marker(value: float) -> void:
	if not BuildInfo.is_dev():
		return
	marker = clampf(value, 0.0, 1.0)
