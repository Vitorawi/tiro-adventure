class_name LessonGuide
extends TutorialGuide
## Duas lições guiadas curtas do Novo fluxo (F02B), com a Laís e a mão do tutorial:
##  - "growth": lição do painel de crescimento (passo `lais_growth`): três falas, uma por toque, apontando a grade de passos,
##    os ✓ acesos e a barra do avatar no HUD. Some sozinha se o painel fechar (e volta na próxima abertura até concluir).
##  - "food": aula da comida (passo `week_story.json → food_lesson.quest`): reloginho → folha Hoje → arrastar a papinha
##    (a primeira patinha é garantida a qualquer hora) → a patinha voa ao avatar → painel Crescer na linha das patinhas.
## As falas ficam em `week_story.json → food_lesson`. O passo salvo da aula é do `GameState` (`food_lesson_data`): fechar o
## jogo no meio retoma no mesmo toque. Nós: `LessonGuide`, `TutorialVeil`, `TutorialBalloon`, `LessonNext`, `LessonSkip`, `LessonPaw`.

const FOOD_BEATS := 5

static var current: LessonGuide

var main: Control
var kind := ""  ## "", "growth" ou "food"
var beat := 0
var _text := ""
var _target := Rect2()
var _accept: Button
var _skip: Button
var _elapsed := 0.0
var _retry := 0.0
var _paw: TextureRect


static func is_active() -> bool:
	return current != null and is_instance_valid(current) and current.kind != ""


func _ready() -> void:
	current = self
	name = "LessonGuide"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_focus(true)
	_build_hand()
	_build_balloon(self, str(Database.week_story.food_lesson.get("npc", "lais")), 64.0)  # menor: não esconde o painel
	var row := UiKit.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_balloon.add_child(row)
	_accept = StepCardUi.go_button(str(Database.week_story.food_lesson.next), _on_next)
	_accept.name = "LessonNext"
	_accept.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_accept)
	# O "Pular" é a mesma pílula pequena do WeekTutorial, fora do balão (canto da tela, acima ou abaixo dele).
	_skip = StepCardUi.go_button("Pular", _on_skip)
	_skip.name = "LessonSkip"
	_skip.custom_minimum_size.x = 78
	add_child(_skip)
	hide()


func _exit_tree() -> void:
	if current == self:
		current = null


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 0.05:
		_elapsed = 0.0
		_tick()
	if kind != "" and visible:
		_layout(delta)


# --- Máquina de passos -------------------------------------------------------------------------

func _tick() -> void:
	if kind == "food" and GameState.week.food_lesson:
		_stop()  # a aula foi encerrada por fora (ja vista): nao ha mais o que mostrar
		return
	if _blocked():
		hide()
		return
	match kind:
		"growth": _tick_growth()
		"food": _tick_food()
		_: _try_start()


func _blocked() -> bool:
	return is_instance_valid(main.get("_intro")) or bool(main.call("story_card_pending")) or CardViewer.is_open() \
		or AnglerTutorial.is_active() or AlbumTutorial.is_active() or CookTogether.current() != null \
		or TrickLesson.current() != null or is_instance_valid(YardPlay.current)


func _try_start() -> void:
	var panel := main.find_child("GrowthPanel", true, false) as Control
	if panel != null and panel.is_visible_in_tree() and _growth_due():
		kind = "growth"
		_enter(1)
		return
	if GameState.food_lesson_running() or (GameState.food_lesson_startable() and _calm()):
		kind = "food"
		var saved := GameState.food_lesson_data()
		if not saved.has("branch"):
			GameState.set_food_lesson_step(1, {"branch": GameState.food_lesson_branch()})
		_enter(maxi(1, int(saved.get("step", 1))))


## Só começa a aula com a tela livre: sem folha, sem painel do fogão e sem avisos ou cartões na fila.
func _calm() -> bool:
	return not bool(main.get_node("Sheet").call("is_open")) and CookPanel.current() == null and not bool(main.call("notice_blocked"))


func _growth_due() -> bool:
	return GameState.progress.stat("arrival_box") > 0 and GameState.quest_unlocked("lais_growth") \
		and not GameState.progress.claimed_quests.has("lais_growth") and not WeekTutorial.record("growth_lesson").get("done", false)


func _enter(next_beat: int) -> void:
	beat = next_beat
	_retry = 0.0
	_text = ""
	var story: Dictionary = Database.week_story.food_lesson
	if kind == "growth":
		_text = str(story.growth[beat - 1])
	else:
		GameState.set_food_lesson_step(beat)
		var branch := str(GameState.food_lesson_data().get("branch", "window"))
		match beat:
			1:
				_text = str(story.clock)
				Events.sheet_close_requested.emit()
			2:
				_text = _today_text(branch)
				_retry = 0.8
				if not _sheet_has("TodayPanel"):
					MealUi.open_today()
			3:
				_text = str(story.feed)
				_retry = 0.8
				GameState.set_food_lesson_step(3, {"feed0": GameState.progress.stat("feed")} if not GameState.food_lesson_data().has("feed0") else {})
				_open_food_menu()
			4:
				_text = _paw_text(branch)
				GameState.grant_lesson_paw(_fed_item())
				_fly_paw()
			5:
				_text = str(story.grow)
				GameState.set_food_lesson_step(5)
				_retry = 0.8
				GrowthUi.open("days")
	_balloon_label.text = _text
	for rect: ColorRect in _rects:
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE if (kind == "food" and beat == 3) else Control.MOUSE_FILTER_STOP
	_accept.visible = not (kind == "food" and beat == 3)
	_reset_hand()
	_target = _target_rect()
	if _target.has_area():
		show()
	else:
		hide()


func _tick_growth() -> void:
	var panel := main.find_child("GrowthPanel", true, false) as Control
	if panel == null or not panel.is_visible_in_tree() or GameState.progress.claimed_quests.has("lais_growth"):
		_stop()  # o painel fechou: a lição some e volta quando ele abrir de novo
		return
	_follow_target()


func _tick_food() -> void:
	_retry -= 0.05
	match beat:
		1:
			if _sheet_has("TodayPanel"):
				_enter(2)  # tocou no reloginho: a folha Hoje abriu
				return
		2:
			if not _sheet_has("TodayPanel") and _retry <= 0.0:
				_retry = 0.6
				MealUi.open_today()  # fechou a folha sem querer: abre de novo
		5:
			if _retry <= 0.0:
				_retry = 0.5
				if _sheet_has("GrowthPanel"):
					_reveal_paw_card()
				else:
					GrowthUi.open("days")  # fechou o painel sem querer: abre de novo na linha das patinhas
		3:
			var saved := GameState.food_lesson_data()
			if GameState.progress.stat("feed") > int(saved.get("feed0", GameState.progress.stat("feed"))):
				_enter(4)
				return
			if _retry <= 0.0 and not _menu_open():
				_retry = 0.8
				_open_food_menu()
	_follow_target()


## O painel Crescer rola ate a cartela de patinhas (com 13 passos ela fica abaixo da dobra).
func _reveal_paw_card() -> void:
	var card := main.find_child("PawCard", true, false) as Control
	var scroll := main.get_node("Sheet").find_child("Scroll", true, false) as ScrollContainer
	if card != null and scroll != null and card.is_visible_in_tree():
		scroll.ensure_control_visible(card)


func _follow_target() -> void:
	_target = _target_rect()
	if _target.has_area():
		if not visible:
			show()
	else:
		hide()


func _on_next() -> void:
	if kind == "growth":
		if beat < 3:
			_enter(beat + 1)
		else:
			WeekTutorial.finish("growth_lesson")
			GameState.note_growth_lesson()
			_stop()
		return
	if kind != "food":
		return
	# A fala 5 (seis patinhas → Dentinhos) só existe quando o painel já mostra a linha das patinhas: antes do Filhotinho,
	# a aula termina na patinha e o painel de crescimento é apresentado pela lição dele (passo "Como ele cresce").
	if beat < FOOD_BEATS and not (beat == 4 and not _has_days_row()):
		_enter(beat + 1)
	else:
		_finish_food()


func _on_skip() -> void:
	if kind == "growth":
		WeekTutorial.finish("growth_lesson", true)
		GameState.note_growth_lesson()
		_stop()
	elif kind == "food":
		_finish_food()


## Volta ao repouso: nada na tela, esperando a próxima chance de começar.
func _stop() -> void:
	kind = ""
	beat = 0
	hide()


func _finish_food() -> void:
	var branch := str(GameState.food_lesson_data().get("branch", "window"))
	GameState.finish_food_lesson()
	WeekTutorial.finish("food")
	_stop()
	if branch == "night":
		_bedtime()


## Noite: ele boceja e vai para a caminha; a sessão termina no Boa noite (que aparece sozinho).
func _bedtime() -> void:
	Events.sheet_close_requested.emit()
	main.call("show_screen", &"pet")
	var pet := main.find_child("PetScreen", true, false)
	var animator: Object = pet.get("_animator") if pet != null else null
	if animator != null:
		animator.call("play_lesson_pose", &"yawn")
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		if GameState.auto_sleep_allowed():
			GameState.set_sleeping(true))


# --- Textos ---------------------------------------------------------------------------------

func _today_text(branch: String) -> String:
	var today: Dictionary = Database.week_story.food_lesson.today
	if branch != "window":
		return str(today[branch])
	var period := GameState.meal_period_now()
	var name := MealUi.period_name(period if period != "" else "lunch").to_lower()
	var lunch := GameState.meal_window("lunch")
	var dinner := GameState.meal_window("dinner")
	return str(today.window) % [name, lunch.x, lunch.y, dinner.x, dinner.y]


func _paw_text(branch: String) -> String:
	var paw: Dictionary = Database.week_story.food_lesson.paw
	if branch != "day":
		return str(paw[branch])
	var next := GameState.next_meal_in()
	var period := str(next.get("period", "dinner"))
	return str(paw.day) % [MealUi.period_name(period).to_lower(), GameState.meal_window(period).x]


## A refeição que ele comeu na aula (para o carimbo da cartela): a mais recente do registro de hoje.
func _fed_item() -> String:
	var record: Dictionary = GameState.week.day_record(int(GameState.meal_info().day))
	for period: String in Database.meals.periods:
		var entry: Dictionary = record.get(period, {})
		if bool(entry.get("on_time", false)) and str(entry.get("item", "")) not in ["", "ration"]:
			return str(entry.item)
	return "puppy_mash"


# --- Alvos e posição --------------------------------------------------------------------------

func _sheet_has(node_name: String) -> bool:
	var node := main.find_child(node_name, true, false) as Control
	return node != null and node.is_visible_in_tree()


func _pet() -> Control:
	return main.find_child("PetScreen", true, false) as Control


func _menu_open() -> bool:
	var pet := _pet()
	var care: Object = pet.get("_care") if pet != null else null
	var menu := care.get("_menu") as Control if care != null else null
	return menu != null and menu.visible


func _open_food_menu() -> void:
	main.call("show_screen", &"pet")
	Events.sheet_close_requested.emit()
	var pet := _pet()
	var care: Object = pet.get("_care") if pet != null else null
	if care != null and not _menu_open():
		care.call("open_food_menu")


func _target_rect() -> Rect2:
	match kind:
		"growth":
			match beat:
				1: return _rect("GrowthSteps")
				# Dois exemplos do que já está feito: a caminha e a papinha caseira (senão, o passo feito mais à mão).
				2: return _done_tile("GrowthReq_bed", 0)
				3: return _done_tile("GrowthReq_home_mash", 1)
		"food":
			match beat:
				1: return _rect("MealClock")
				2: return _rect("TodayCard")
				3:
					var item := _rect("Care_" + _fed_item_in_menu())
					return item if item.has_area() else _rect("FoodMenu")
				4: return _rect("HudAvatar")
				5:
					var card := _rect("PawCard")  # a cartela (Patinhas 1/6) fica na linha das patinhas
					if card.has_area():
						return card
					var row := _rect("GrowthReq_days")
					return row if row.has_area() else _rect("GrowthSteps")
	return Rect2()


static func _has_days_row() -> bool:
	for req: Dictionary in GameState.growth_info().get("requirements", []):
		if str(req.get("id", "")) == "days":
			return true
	return false


## Quadradinho de um passo já feito do painel de crescimento: o pedido, ou o n-ésimo passo com ✓, ou a grade toda.
func _done_tile(preferred: String, fallback_index: int) -> Rect2:
	var wanted := main.find_child(preferred, true, false) as Control
	if wanted != null and wanted.is_visible_in_tree():
		return wanted.get_global_rect()
	var done: Array[Control] = []
	for tile: Node in main.find_children("GrowthReq_*", "Button", true, false):
		var button := tile as Button
		if button.is_visible_in_tree() and button.find_child("StepCheck", true, false) != null:
			done.append(button)
	if done.size() > fallback_index:
		return done[fallback_index].get_global_rect()
	return _rect("GrowthSteps")


## A refeição que está no cardápio e vai ser arrastada (a papinha da aula).
func _fed_item_in_menu() -> String:
	return GameState.food_lesson_item()


func _rect(node_name: String) -> Rect2:
	for node: Node in main.find_children(node_name, "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.is_queued_for_deletion():
			continue
		var rect := control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
		var parent := control.get_parent()
		while parent is Control and rect.has_area():
			if (parent as Control).clip_contents:
				rect = rect.intersection(parent.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, (parent as Control).size))
			parent = parent.get_parent()
		if rect.intersection(get_viewport_rect()).size.y >= 14.0:
			return rect.intersection(get_viewport_rect())
	return Rect2()


func _layout(delta: float) -> void:
	_place_above_siblings()
	var screen := get_viewport_rect().size
	var hole := _layout_focus(_target, screen)
	var width := minf(320.0, screen.x - 24.0)
	_balloon.size = Vector2(width, 0.0)
	var height := _balloon.get_combined_minimum_size().y
	var below := hole.end.y + 12.0
	var above := hole.position.y - height - 12.0
	var top := Hud.HEIGHT + 4.0
	var limit := screen.y - height - 6.0
	var y := above
	if above < top or (hole.get_center().y < screen.y * 0.4 and below <= limit):
		y = below
	if y > limit:
		y = above
	if kind == "food" and beat == 3:
		y = top  # no arrasto o balao fica no alto: nao cobre o Tiro (alvo de soltar) nem a mao
	y = clampf(y, top, maxf(top, limit))
	if (kind == "growth" or (kind == "food" and beat in [2, 5])) and main.get_node("Sheet").call("is_open"):
		# Com uma folha aberta embaixo (Hoje, Crescimento) o balão fica acima dela: não cobre o título nem a explicação.
		var panel := main.get_node("Sheet").get_node("Panel") as Control
		var over := panel.get_global_rect().position.y - height - 8.0
		if over >= top:
			y = over
	_balloon.position = Vector2(clampf(hole.get_center().x - width * 0.5, 12.0, screen.x - width - 12.0), y)
	_balloon.size = Vector2(width, height)
	_skip.size = _skip.get_combined_minimum_size()
	var skip_x := screen.x - _skip.size.x - 12.0
	var skip_y := y - _skip.size.y - 4.0
	if skip_y < top - 4.0 or hole.intersects(Rect2(Vector2(skip_x, skip_y), _skip.size)):
		skip_y = y + height + 4.0
	_skip.position = Vector2(skip_x, clampf(skip_y, 10.0, screen.y - _skip.size.y - 12.0))
	var center := _target.get_center()
	if kind == "food" and beat == 3:
		var pet := _pet()
		var head: Rect2 = pet.call("head_rect") if pet != null else Rect2(center, Vector2.ZERO)
		_guide_hand(delta, center, head.get_center() + Vector2(0, DragGhost.LIFT))
	else:
		_guide_hand(delta, center + Vector2(-7, 12), center)


# --- A patinha que voa ----------------------------------------------------------------------

func _fly_paw() -> void:
	if is_instance_valid(_paw):
		_paw.queue_free()
	_paw = UiKit.icon(UiKit.ui_icon("find_paw"), 56)
	_paw.name = "LessonPaw"
	add_child(_paw)
	var pet := _pet()
	var from := get_viewport_rect().size * 0.5
	if pet != null:
		from = (pet.call("head_rect") as Rect2).get_center()
	var avatar := _rect("HudAvatar")
	var to := avatar.get_center() if avatar.has_area() else Vector2(40, 40)
	var arrived := func() -> void:
		if is_instance_valid(_paw):
			_paw.queue_free()
		var hud := main.find_child("HudAvatar", true, false) as Control
		if hud != null:
			Motion.bounce(hud)
	if Motion.reduced:
		arrived.call()
		return
	Motion.fly_arc(_paw, from - Vector2(28, 28), to - Vector2(28, 28), 0.9).tween_callback(arrived)
