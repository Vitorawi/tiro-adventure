class_name WeekTutorial
extends TutorialGuide
## Apresenta uma lição de cada vez, no controle que executa a ação do jogo.

var main: Control
var active := ""
var step := -1
var _shown: Dictionary = {}
var _anchor_rect := Rect2()
var _skip: Button
var _accept: Button
var _hint: PanelContainer
var _label: Label
var _tip_go: Button
var _elapsed := 0.0
var _resume_pending := true
var _idle_since: Dictionary = {}


static func enrolled() -> bool:
	return GameState.week.tutorial.get("arrival", {}).get("done", false)


static func record(id: String) -> Dictionary:
	return GameState.week.tutorial.get(id, {})


static func finish(id: String, skipped: bool = false) -> void:
	if record(id).get("done", false):
		return
	var data := record(id)
	data.merge({"done": true, "skipped": skipped}, true)
	GameState.week.tutorial[id] = data
	if GameState.week.tutorial.get("resume", "") == id:
		GameState.week.tutorial.erase("resume")
	Events.week_tutorial_changed.emit()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_focus(false)
	_build_hand()
	_build_balloon(self, "bloblo")
	_accept = StepCardUi.go_button("Entendi", _accept_balloon)
	_accept.name = "TutorialAccept"
	_balloon.add_child(_accept)
	_hint = PanelContainer.new()
	_hint.name = "WeekTutorialHint"
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WOOD_CREAM
	style.border_color = Palette.HONEY
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	_hint.add_theme_stylebox_override("panel", style)
	add_child(_hint)
	var row := UiKit.hbox(8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_child(row)
	_label = StepCardUi.wood("", 16)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size.x = 150
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_label)
	_tip_go = StepCardUi.go_button("Ir", _go_from_tip)
	row.add_child(_tip_go)
	_skip = StepCardUi.go_button("Pular", _skip_current)
	_skip.name = "TutorialSkip"
	_skip.custom_minimum_size.x = 78
	add_child(_skip)
	hide()


func _process(delta: float) -> void:
	_elapsed += delta
	var intro := is_instance_valid(main.get("_intro"))
	var blocked: bool = (main.call("story_card_pending") and not intro) or CardViewer.is_open() or AnglerTutorial.is_active() or AlbumTutorial.is_active() or LessonGuide.is_active()
	if blocked:
		hide()
		return
	if _elapsed >= 0.08:
		_elapsed = 0.0
		_pick(intro)
	if not visible:
		return
	if active == "fetch" and is_instance_valid(YardPlay.current) and not YardPlay.current.result.is_empty():
		finish("fetch")
		hide()
		return
	var target := _anchor_rect
	if not target.has_area():
		hide()
		return
	_layout_week(target, delta)


func _pick(intro: bool) -> void:
	if intro:
		var arrival: Dictionary = Database.week_tutorials[0]
		var index := mini(int(GameState.week.tutorial.get("arrival_step", 0)), 3)
		index = [0, 1, 1, 2][index]
		_present(arrival, index, arrival.steps[index].target)
		return
	if not enrolled() or GameState.growth.phase_index() >= GameState.growth.phase_index("teething"):
		hide()
		return
	if _resume_pending:
		if not main.call("notice_blocked"):
			_resume_pending = false
			_resume()
		else:
			return
	var day := GameState.content_day()
	for lesson: Dictionary in Database.week_tutorials:
		if lesson.day > day or lesson.get("native", false) or record(lesson.id).get("done", false):
			continue
		if _action_done(lesson):
			finish(lesson.id)
			continue
		var quest := str(lesson.get("quest", ""))
		if quest != "" and not GameState.quest_unlocked(quest):
			continue
		if lesson.has("after_quest") and not GameState.progress.claimed_quests.has(str(lesson.after_quest)):
			continue
		if lesson.has("idle") and not _idle_ready(lesson):
			continue  # só ajuda quem demora: o gesto já foi ensinado antes
		if lesson.id == "clock" and (_sheet_open() or _minigame()):
			continue
		if lesson.id == "feed" and (GameState.food_lesson_startable() or GameState.food_lesson_running()):
			continue  # a aula da comida cuida de arrastar a papinha (F02B)
		if lesson.has("after") and GameState.progress.stat(str(lesson.after)) < int(lesson.get("after_min", 1)):
			continue
		var data := record(lesson.id)
		if lesson.id == "name" and day > 1:
			continue
		if lesson.format == "new" and not data.get("announced", false):
			if _can_announce(lesson) and not main.call("notice_blocked") and not _sheet_open() and not _minigame() and GameState.week_card_candidates().is_empty():
				main.get("_celebration").show_week_tutorial(lesson, _card_closed.bind(lesson))
				hide()
				return
			continue
		var candidate := _locate(lesson)
		if not candidate.is_empty():
			_present(lesson, candidate.step, candidate.target)
			return
	hide()


## A lição com `idle` (segundos) só aparece depois que o passo dela ficou parado esse tempo (quem já sabe o gesto não precisa da mão).
func _idle_ready(lesson: Dictionary) -> bool:
	var id := str(lesson.id)
	if not _idle_since.has(id):
		_idle_since[id] = Time.get_ticks_msec()
	return Time.get_ticks_msec() - int(_idle_since[id]) >= int(float(lesson.idle) * 1000.0)


func _action_done(lesson: Dictionary) -> bool:
	var stat := str(lesson.get("done", ""))
	# "owned:<melhoria>" e "growth:<fase>" não são contadores: o que vale é ter a caminha / já ser aquela fase.
	if stat.begins_with("owned:"):
		return GameState.has_upgrade(stat.trim_prefix("owned:"))
	if stat.begins_with("growth:"):
		return GameState.growth.phase_index() >= GameState.growth.phase_index(stat.trim_prefix("growth:"))
	return stat != "" and GameState.progress.stat(stat) >= int(lesson.get("min_value", 1))


func _locate(lesson: Dictionary) -> Dictionary:
	var stages: Array = lesson.get("steps", [])
	if lesson.id == "garden" and GameState.progress.stat("plant:carrot") > 0:
		return {"step": 2, "target": "@harvest"} if _target("@harvest").has_area() else {}
	if lesson.id == "name" and GameState.progress.stat("yard:ball") > 0:
		return {"step": 2, "target": "YardName"} if _target("YardName").has_area() else {}
	if lesson.id == "cart" and GameState.progress.stat("cart_delivery") > 0 and _control_rect("CartShop").has_area():
		return {"step": 2, "target": "@cart_shop"}
	if lesson.id == "coop" and GameState.has_upgrade("chicken_coop") and not _target("KitAssemblyGo").has_area():
		if int(record("coop").get("step", -1)) >= 2:
			finish("coop")
		return {}
	if stages.is_empty():
		var anchor := str(lesson.get("anchor", ""))
		return {"step": 0, "target": anchor} if _target(anchor).has_area() else {}
	for i in range(stages.size() - 1, -1, -1):
		var target := str(stages[i].target)
		if target in ["@cart_shop", "YardName"]:
			continue
		if target == "InvSlot_0" and not GameState.week.tutorial.get("invent_type_chosen", false):
			continue
		if lesson.id == "coop" and target == "BuyItem":
			var kit := main.find_child("Buy_week_coop", true, false)
			if not is_instance_valid(kit) or not kit.get_meta("selected", false):
				continue
		if _target(target).has_area():
			return {"step": i, "target": target}
	return {}


func _present(lesson: Dictionary, index: int, anchor: String) -> void:
	_anchor_rect = _target(anchor)
	if active != lesson.id or step != index or not visible:
		_reset_hand()
	if active != lesson.id or step != index:
		active = lesson.id
		step = index
		_shown = lesson
		_update_copy()
		if active != "arrival":
			var data := record(active)
			var new_step := maxi(int(data.get("step", -1)), index)
			if new_step != int(data.get("step", -1)) or GameState.week.tutorial.get("resume", "") != active:
				data.step = new_step
				var dock := FarmDock.current()
				if active == "garden" and index == 1 and dock != null:
					data.plot = dock.plot_index
				GameState.week.tutorial[active] = data
				if lesson.has("resume"):
					GameState.week.tutorial.resume = active
				Events.week_tutorial_changed.emit()
	show()


func _update_copy() -> void:
	var guided := _shown.has("steps")
	var pointing: bool = _shown.get("point", false)  # balão que também aponta (anel + mão) para a aba, sem escurecer a tela
	_veil.visible = guided or pointing
	_balloon.visible = _shown.format == "balloon"
	_hint.visible = guided or _shown.format in ["tip", "list"]
	var tip: bool = _shown.format == "tip"
	_tip_go.visible = tip or _shown.format == "list"
	_label.text = str(_shown.steps[step].say) if guided else str(_shown.get("say", _shown.text))
	var petting := guided and str(_shown.steps[step].target) == "ArrivalPet"
	if petting:
		_hint.hide()
	for rect: ColorRect in _rects:
		rect.color.a = 0.0 if pointing else (0.18 if petting else 0.5)
	_skip.visible = active != "arrival"
	_skip.custom_minimum_size.x = 110.0 if active == "cook" else 78.0
	_skip.text = "Pular guia" if active == "cook" else "Pular"
	if _balloon.visible:
		_balloon.queue_free()
		remove_child(_balloon)
		_build_balloon(self, str(_shown.npc))
		_balloon_label.text = str(_shown.say)
		_accept = StepCardUi.go_button("Entendi", _accept_balloon)
		_accept.name = "TutorialAccept"
		_balloon.add_child(_accept)
		move_child(_skip, -1)


func _layout_week(target: Rect2, delta: float) -> void:
	var screen := get_viewport_rect().size
	if _veil.visible:
		_layout_focus(target, screen)
		var points := _gesture(target, str(_shown.steps[step].get("gesture", "tap"))) if _shown.has("steps") else [target.get_center() + Vector2(-7, 12), target.get_center()]
		_guide_hand(delta, points[0], points[1])
	var bubble: Control = _balloon if _balloon.visible else _hint
	var width := minf(320.0, screen.x - 28.0)
	if bubble == _hint:
		width = minf(280.0, width)
	bubble.size.x = width
	var height := bubble.get_combined_minimum_size().y
	var y := target.position.y - height - 14.0
	if y < 58.0 or target.size.y > screen.y * 0.65:
		y = target.end.y + 14.0
	if y + height > screen.y - 74.0:
		y = clampf(target.position.y - height - 14.0, 64.0, screen.y - height - 74.0)
	# O botão Ver detalhes fica no pé do balão do avatar: a fala vai embaixo, para não cobrir o texto dele.
	if _shown.has("steps") and str(_shown.steps[step].get("target", "")) == "ViewGrowth":
		y = target.end.y + 14.0
	if active == "arrival":
		y = minf(y, screen.y - 275.0)
	if (active.begins_with("home_") or active == "place_stove") and _sheet_open():
		# Com uma folha aberta o balão (e o Pular) ficam acima dela, sem cobrir o texto do cartão.
		var panel := main.get_node("Sheet").get_node("Panel") as Control
		y = clampf(panel.get_global_rect().position.y - height - 8.0, 64.0, y)
	bubble.position = Vector2(clampf(target.get_center().x - width * 0.5, 12.0, screen.x - width - 12.0), y)
	bubble.size = Vector2(width, height)
	_skip.size = _skip.get_combined_minimum_size()
	var skip_y := y - _skip.size.y - 4.0
	var skip_row := Rect2(Vector2(screen.x - _skip.size.x - 12.0, skip_y), _skip.size)
	# Rostos de personagem (NpcRow) ficam no canto de cima à direita: o Pular não os cobre.
	var faces := _control_rect("NpcRow")
	if skip_y < 10.0 or target.intersects(skip_row) or (faces.has_area() and faces.grow(4.0).intersects(skip_row)):
		skip_y = y + height + 4.0
	_skip.position = Vector2(screen.x - _skip.size.x - 12.0, clampf(skip_y, 10.0, screen.y - _skip.size.y - 12.0))


func _gesture(rect: Rect2, style: String) -> Array:
	var center := rect.get_center()
	match style:
		"plot":
			var plot := _target("@plot", true)
			return [center, plot.get_center() if plot.has_area() else center + Vector2(0, -100)]
		"feed":
			var pet := main.find_child("PetScreen", true, false)
			var care: Node = pet.get("_care")
			var bowl: Rect2 = care.call("meal_bowl_rect")
			return [center, bowl.get_center() + Vector2(0, DragGhost.LIFT)]
		"cut":
			var kitchen := CookTogether.current()
			if kitchen == null:
				return [center, center]
			var at := kitchen.to_screen(Vector2(kitchen.guide_x(), 320.0)) + kitchen.global_position
			return [at - Vector2(0, 40), at + Vector2(0, 42)]
		"slide": return [center - Vector2(36, 0), center + Vector2(42, 0)] if active != "fetch" and active != "name" else [center, center + Vector2(18, -60)]
		"up": return [center + Vector2(0, 42), center - Vector2(0, 36)]
		"down": return [center - Vector2(0, 36), center + Vector2(0, 42)]
		"serve": return [center - Vector2(60, 40), center + Vector2(60, 42)]
		"circle":
			var angle := _demo_time * 2.6
			var p := center + Vector2.from_angle(angle) * rect.size.x * 0.48
			return [p, p]
		"hold": return [center, center]
		"scrub":
			# Da esponja até as costas do Tiro, esfregando de um lado para o outro.
			var pet := main.find_child("PetScreen", true, false)
			var back: Rect2 = pet.call("back_rect")
			var wobble := Vector2(sin(_demo_time * 7.0) * 26.0, 0.0)
			return [center, back.get_center() + wobble]
	return [center + Vector2(-7, 12), center]


func _target(anchor: String, behind: bool = false) -> Rect2:
	if anchor.is_empty():
		return Rect2()
	if anchor.begins_with("@"):
		return _special_target(anchor.trim_prefix("@"), behind)
	var rect := _control_rect(anchor)
	if anchor == "MealClock" and not rect.has_area():
		rect = _control_rect("TopBar")
		if rect.has_area():
			rect = Rect2(rect.position + Vector2(8, 45), Vector2(64, 44))
	if anchor == "QuantityRow" and rect.has_area():
		var sell := _control_rect("SellSelected")
		if sell.has_area():
			rect = rect.merge(sell)
	return rect


func _control_rect(node_name: String, scope: Node = null) -> Rect2:
	if scope == null:
		scope = main
	for node: Node in scope.find_children(node_name, "Control", true, false):
		var control := node as Control
		if not control.is_visible_in_tree() or control.is_queued_for_deletion():
			continue
		if control is BaseButton and control.disabled:
			continue
		var rect := control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
		var parent := control.get_parent()
		while parent is Control and rect.has_area():
			if parent.clip_contents:
				rect = rect.intersection(parent.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, parent.size))
			parent = parent.get_parent()
		if rect.intersection(get_viewport_rect()).size.y >= 14.0:
			return rect.intersection(get_viewport_rect())
	return Rect2()


func _special_target(id: String, behind: bool) -> Rect2:
	if id in ["plot", "harvest", "coop", "orchard"]:
		if id == "orchard":
			var button := _control_rect("OrchardHarvest")
			if button.has_area():
				return button
		if id == "coop" and GameState.station("chicken_coop").ready_count(GameState.now()) == 0:
			return Rect2()
		if not behind and (_sheet_open() or _minigame()):
			return Rect2()
		var room := main.find_child("World_farm", true, false) as RoomView
		if is_instance_valid(room) and room.is_visible_in_tree():
			return room.week_tutorial_rect(id, behind)
	if id in ["buy_bed", "buy_stove"]:
		# O "+" do presente (caminha ou fogão) na Casa (só com o Mapa aberto na Casa e sem folha por cima).
		if not behind and (_sheet_open() or _minigame()):
			return Rect2()
		var house := main.find_child("World_house", true, false) as RoomView
		if is_instance_valid(house) and house.is_visible_in_tree():
			return house.week_tutorial_rect("buy:dog_bed" if id == "buy_bed" else "buy:stove")
	if id == "npc_bloblo":
		if not behind and (_sheet_open() or _minigame()):
			return Rect2()
		var farm := main.find_child("World_farm", true, false) as RoomView
		if is_instance_valid(farm) and farm.is_visible_in_tree():
			return farm.week_tutorial_rect("npc:bloblo")
	if id in ["picar", "mexer", "servir"]:
		var kitchen := CookTogether.current()
		if kitchen != null and kitchen.phase == id:
			return kitchen.tutorial_rect()
	if id in ["ball", "rope"]:
		var yard := YardPlay.current
		if is_instance_valid(yard) and yard.kind == id and yard.result.is_empty():
			return yard.tutorial_rect()
	if id.begins_with("lesson_") or id in ["meal_gesture", "show"]:
		var lesson := TrickLesson.current()
		if lesson != null:
			return lesson.tutorial_rect(id)
	if id == "feed_hens":
		var recipe := _control_rect("Tile_eggs")
		if recipe.has_area():
			var cook := _control_rect("Cook")
			if cook.has_area():
				return cook
			return recipe
	if id == "snack":
		for item: String in ["oat_biscuit", "apple_biscuit", "carrot_snack"]:
			var rect := _control_rect("Care_" + item)
			if rect.has_area():
				return rect
	if id == "key_dish":
		var detail := _control_rect("DetailGrowBadge")
		return detail if detail.has_area() else _control_rect("GrowthSeal")
	if id == "cart_shop":
		return _control_rect("CartShop")
	return Rect2()


func _can_announce(lesson: Dictionary) -> bool:
	match str(lesson.id):
		"pair": return not GameState.week_routine_pairs().is_empty()
		"soup": return GameState.quest_unlocked("week_bridge")
		_: return true


func _card_closed(skipped: bool, lesson: Dictionary) -> void:
	if skipped or not lesson.has("steps"):
		finish(lesson.id, skipped)
		return
	var data := record(lesson.id)
	data.announced = true
	GameState.week.tutorial[lesson.id] = data
	Events.week_tutorial_changed.emit()


func _skip_current() -> void:
	if active != "" and active != "arrival":
		finish(active, true)
		hide()


func _accept_balloon() -> void:
	finish(active)
	hide()


func _go_from_tip() -> void:
	if _shown.format == "list":
		_accept_balloon()
		Places.go({"growth": true})
	else:
		Places.go(_shown.go)


func _sheet_open() -> bool:
	return main.get_node("Sheet").call("is_open")


func _minigame() -> bool:
	return CookTogether.current() != null or TrickLesson.current() != null or is_instance_valid(YardPlay.current)


func _resume() -> void:
	var id := str(GameState.week.tutorial.get("resume", ""))
	if id == "" or record(id).get("done", false):
		return
	for lesson: Dictionary in Database.week_tutorials:
		if lesson.id == id and lesson.has("resume"):
			if _action_done(lesson):
				finish(id)
				return
			if id in ["sit", "paw", "down"] and GameState.week.tutorial.has("lesson"):
				var trick := str(GameState.week.tutorial.lesson.id)
				main.call("_on_world_requested", "farm", "")
				TrickLesson.open(main, trick)
				return
			if id == "garden" and record(id).get("step") == 1:
				main.call("_on_world_requested", "farm", "")
				var room := main.find_child("World_farm", true, false) as RoomView
				var plot := int(record(id).get("plot", 0))
				if is_instance_valid(room):
					room.open_plot_tray.call_deferred(maxi(0, plot), "carrot", true, false)
			elif id == "market" and int(record(id).get("step", 0)) >= 2:
				Places.go({"world": "farm", "place": "shop:week_plot"})
			elif id == "eggs" and int(record(id).get("step", 0)) == 1:
				Places.go({"world": "farm", "place": "chicken_coop"})
			elif id == "invent" and int(record(id).get("step", 0)) >= 1:
				RecipeBookUi.open_kitchen("invent")
			elif id == "cook" and GameState.week.tutorial.has("cooking"):
				var key := str(GameState.week.tutorial.cooking.get("key", ""))
				if key.begins_with("recipe:") or key.begins_with("dish:"):
					RecipeBookUi.open_kitchen("together:" + key)
				else:
					Places.go(lesson.resume)
			elif lesson.resume.get("care") == "feed":
				main.call("show_screen", &"pet")
				Events.care_requested.emit("feed")
			else:
				Places.go(lesson.resume)
			return


static func manual_body(model: Dictionary, refresh: Callable) -> Control:
	var box := UiKit.vbox(8)
	box.name = "WeekTutorialManual"
	var selected := str(model.get("tutorial", ""))
	if selected != "":
		var back := StepCardUi.go_button("Todos os tutoriais", func() -> void:
			model.erase("tutorial")
			model.scroll = 0
			refresh.call())
		box.add_child(back)
		for lesson: Dictionary in Database.week_tutorials:
			if lesson.id != selected:
				continue
			var card := StepCardUi.inner_card(box, "TutorialReview_" + selected)
			card.add_child(StepCardUi.wood(str(lesson.title), 20))
			var text := StepCardUi.wood(str(lesson.text), 17)
			text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(text)
			if selected == "food":
				card.add_child(MealReview.body())  # o desenho do dia de 24 h, o mesmo do "?" da folha Hoje
			break
		return box
	var last := GameState.week_last_chapter()  # um grupo por capítulo da semana (1 a 11) e o "Quando acontecer" (dia 0)
	for day in range(1, last + 2):
		var chapters: Array = Database.progression.get("chapters", [])
		var title := "Quando acontecer"
		if day <= last:
			title = "Capítulo %d" % day
			if day <= chapters.size():
				title += " · " + str(chapters[day - 1].get("name", ""))
		var heading := StepCardUi.wood(title, 18)
		heading.name = "TutorialChapter_%d" % (day if day <= last else 0)
		box.add_child(heading)
		for lesson: Dictionary in Database.week_tutorials:
			if int(lesson.day) != (day if day <= last else 0):
				continue
			var id := str(lesson.id)
			var show_lesson := func() -> void:
				model.tutorial = id
				model.scroll = 0
				refresh.call()
			var button := StepCardUi.go_button(str(lesson.title), show_lesson)
			button.name = "TutorialReview_" + id
			box.add_child(button)
	return box
