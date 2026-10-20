extends PanelContainer
## Aba Missões: um cartão por linha ativa (História da Laís primeiro, depois a vovó Bloblo...),
## Diárias e Semanais. Ícone + ação breve + progresso; linhas correm em paralelo.


func _ready() -> void:
	%Holder.add_child(SheetBuilder.LiveBox.new(_build))


var _ready_routines: Array[Dictionary] = []


func _build(box: VBoxContainer) -> void:
	_ready_routines.clear()
	for kind: String in ["daily", "weekly"]:
		for id: String in GameState.routine_ids(kind):
			if GameState.routine_error(kind, id) == "": _ready_routines.append({"kind": kind, "id": id})
	_story_card(box)
	for line: String in GameState.progress.lines():
		var id := GameState.progress.current_line_quest(line)
		if id != "":
			_line_card(box, id)
	for kind: String in ["daily", "weekly"]:
		_routines(box, kind)


## Cartão da história: capítulo, passos, quem pede, ação + ícone + 0/6, onde, o que falta e Ir.
func _story_card(box: VBoxContainer) -> void:
	var chapter := GameState.current_chapter()
	var index := GameState.progress.chapter_index()
	var total: int = Database.progression.chapters.size()
	var current := GameState.progress.current_main_quest()
	var displayed := GameState.progress.displayed_main_quest()
	var shared := str(Database.quests.get(current, {}).get("shared_with", ""))
	var ready := shared == "" and displayed != "" and GameState.quest_error(displayed) == ""
	var card := UiKit.card(box, &"ReadyCardPanel" if ready else &"CardPanel")
	card.name = "StoryCard"
	var header := UiKit.tap_chip(UiKit.ui_icon("tab_tasks"), str(chapter.get("name", "História")) + "  ›", func() -> void:
		Events.sheet_requested.emit("História", ProgressionUi.story_panel()))
	header.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.add_child(header)
	if index > total:
		card.add_child(UiKit.label("História concluída!", &"SectionLabel", UiKit.GOOD))
		return
	var ids := GameState.progress.main_quests(index)
	card.add_child(_step_dots(ids.size(), ids.find(current)))
	if shared != "":
		_shared_story_goal(card, shared)
		return
	if displayed != "":
		_quest_body(card, displayed, _ready_routines.size() < 2)


## A história orienta até um marco da linha paralela; a entrega e o prêmio ficam só nela.
func _shared_story_goal(card: VBoxContainer, target: String) -> void:
	var quest: Dictionary = Database.quests[target]
	var npc: Dictionary = Database.npcs.get(str(quest.get("npc", "")), {})
	var name := str(npc.get("name", "personagem"))
	card.add_child(UiKit.label("Missões de " + name, &"SectionLabel"))
	var guidance := UiKit.label("Complete as missões de %s até “%s”." % [name, str(quest.name)], &"SmallLabel")
	guidance.name = "SharedQuestGuidance"
	card.add_child(guidance)
	card.add_child(UiKit.label("A história avança automaticamente ao concluir essa etapa.", &"SmallLabel"))
	var current := GameState.progress.displayed_main_quest()
	if current != "":
		card.add_child(UiKit.secondary("Ir", func() -> void: Places.go(Places.quest_target(current)), null, true))


## Cartão de uma linha secundária (ex.: vovó Bloblo): passos da linha + o passo atual.
func _line_card(box: VBoxContainer, id: String) -> void:
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.quest_error(id) == "" else &"CardPanel")
	card.name = "LineCard_" + str(Database.quests[id].line)
	var ids := GameState.progress.line_quests(str(Database.quests[id].line))
	card.add_child(_step_dots(ids.size(), ids.find(id)))
	_quest_body(card, id, false)


func _quest_body(card: VBoxContainer, id: String, primary: bool = true) -> void:
	var quest: Dictionary = Database.quests[id]
	var who := UiKit.hbox(10)
	if GameState.quest_error(id) == "":
		who.add_child(UiKit.ready_dot())
	who.add_child(UiKit.fill_label(quest.name, &"SectionLabel"))
	who.add_child(_destination(Places.quest_target(id)))
	card.add_child(who)
	for goal: Dictionary in quest.goals:
		card.add_child(ProgressionUi.goal_row(goal, GameState.goal_value(goal), 48))
	card.add_child(ProgressionUi.reward_chips(quest.rewards))
	ProgressionUi.quest_action(card, id, primary)


## Miniatura do destino, com a cor do mundo; o toque da missão continua no Ir.
func _destination(target: Dictionary) -> Control:
	var world_id := str(target.get("world", "house"))
	var world: Dictionary = Database.worlds.get(world_id, {})
	var place_id := str(target.get("spot", target.get("place", ""))).trim_prefix("place:")
	var place: Dictionary = world.get("places", {}).get(place_id, {})
	var texture := UiKit.ui_icon(str(place.get("icon", world.get("icon", "tab_pet"))))
	if place_id.begins_with("npc:"): texture = ProgressionUi.npc_portrait(place_id.trim_prefix("npc:"))
	if place_id.begins_with("buy:"): texture = UiKit.ui_icon(str(Database.progression.upgrades.get(place_id.trim_prefix("buy:"), {}).get("icon", "tab_map")))
	if target.has("screen") or target.has("growth"): texture = UiKit.ui_icon("tab_pet")
	var frame := PanelContainer.new()
	frame.name = "QuestDestination"
	frame.custom_minimum_size = Vector2(64, 64)
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WORLD.get(world_id, Palette.CARD)
	style.set_corner_radius_all(14)
	frame.add_theme_stylebox_override("panel", style)
	frame.add_child(UiKit.icon(texture, 48))
	return frame



## Um tracinho por passo do capítulo: feitos (verde), atual (laranja) e futuros (claro).
func _step_dots(count: int, done: int) -> HBoxContainer:
	var row := UiKit.hbox(4)
	for i in count:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(0, 8)
		dot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.color = UiKit.GOOD if i < done else (Palette.ACCENT if i == done else Palette.SUNKEN)
		row.add_child(dot)
	return row


## Diárias ou semanais: só aparecem depois de liberadas pela história.
func _routines(box: VBoxContainer, kind: String) -> void:
	if not GameState.routines_unlocked(kind):
		return
	var ids := GameState.routine_ids(kind)
	if ids.is_empty():
		return
	var section := UiKit.vbox(4)
	section.name = "Routines_" + kind
	box.add_child(section)
	var header := UiKit.hbox(8)
	header.add_child(UiKit.fill_label("Diárias" if kind == "daily" else "Semanais", &"SectionLabel"))
	header.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(GameState.routine_seconds_left(kind))))
	section.add_child(header)
	# Uma única ação principal para todas as rotinas prontas, inclusive entre seções.
	if _ready_routines.size() >= 2 and kind == str(_ready_routines[0].kind):
		var collect := UiKit.primary("Pegar tudo (%d)" % _ready_routines.size(), func() -> void:
			ProgressionUi.claim_routine_rows(box, _ready_routines.duplicate()))
		collect.name = "ClaimAllRoutines"
		section.add_child(collect)
	var shown := 0
	for id in ids:
		if GameState.routine_claimed(kind, id): continue
		ProgressionUi.routine_card(section, kind, id, _ready_routines.size() == 1 and GameState.progress.current_main_quest() == "")
		shown += 1
	if shown == 0: section.add_child(UiKit.label("Tudo feito por hoje!" if kind == "daily" else "Tudo feito nesta semana!", &"SmallLabel", Palette.GOOD))
