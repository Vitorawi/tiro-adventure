extends PanelContainer
## Aba Missões: História (um passo por vez), Diárias e Semanais. Ícone + ação breve + progresso.


func _ready() -> void:
	%Holder.add_child(SheetBuilder.LiveBox.new(_build))


func _build(box: VBoxContainer) -> void:
	_story_card(box)
	for kind: String in ["daily", "weekly"]:
		_routines(box, kind)


## Cartão da história: quem pede, ação em texto breve + ícone + 0/6, onde, o que falta e Ir.
func _story_card(box: VBoxContainer) -> void:
	var chapter := GameState.current_chapter()
	var index := GameState.progress.chapter_index()
	var total: int = Database.progression.chapters.size()
	var card := UiKit.card(box, &"ReadyCardPanel")
	card.name = "StoryCard"
	var header := UiKit.tap_chip(UiKit.ui_icon("tab_tasks"), "Capítulo %d/%d  ›" % [mini(index, total), total], func() -> void:
		Events.sheet_requested.emit("História", ProgressionUi.story_panel()))
	header.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.add_child(header)
	if index > total:
		card.add_child(UiKit.label("História concluída!", &"SectionLabel", UiKit.GOOD))
		card.add_child(UiKit.label(chapter.get("name", ""), &"SmallLabel"))
		return
	var ids := GameState.progress.main_quests(index)
	var current := GameState.progress.current_main_quest()
	card.add_child(_step_dots(ids.size(), ids.find(current)))
	var quest: Dictionary = Database.quests[current]
	var who := UiKit.hbox(10)
	who.add_child(UiKit.icon(ProgressionUi.npc_portrait(quest.npc), 48))
	who.add_child(UiKit.fill_label(quest.name, &"SectionLabel"))
	card.add_child(who)
	for goal: Dictionary in quest.goals:
		card.add_child(ProgressionUi.goal_row(goal, GameState.goal_value(goal), 48))
	var place := Places.target_view(Places.quest_target(current))
	if place:
		card.add_child(place)
	if GameState.quest_error(current) != "":
		var needs: Array = TaskHelp.describe("quest", current).needs
		if not needs.is_empty():
			var chips := UiKit.flow()
			for need: Dictionary in needs:
				var ok := int(need.have) >= int(need.amount)
				chips.add_child(UiKit.tap_chip(TaskHelp.need_icon(need), "%d/%d" % [mini(int(need.have), int(need.amount)), int(need.amount)], TaskHelp.open.bind(need.kind, need.id, int(need.amount)), UiKit.GOOD if ok else UiKit.BAD))
			card.add_child(chips)
	card.add_child(ProgressionUi.reward_chips(quest.rewards))
	ProgressionUi.quest_action(card, current)


## Um tracinho por passo do capítulo: feitos (verde), atual (laranja) e futuros (claro).
func _step_dots(count: int, done: int) -> HBoxContainer:
	var row := UiKit.hbox(4)
	for i in count:
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(0, 8)
		dot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.color = UiKit.GOOD if i < done else (Color(0.96, 0.62, 0.25) if i == done else Color(0.85, 0.78, 0.68))
		row.add_child(dot)
	return row


## Diárias ou semanais: só aparecem depois de liberadas pela história.
func _routines(box: VBoxContainer, kind: String) -> void:
	if not GameState.routines_unlocked(kind):
		return
	var ids := GameState.routine_ids(kind)
	if ids.is_empty():
		return
	var header := UiKit.hbox(8)
	header.add_child(UiKit.fill_label("Diárias" if kind == "daily" else "Semanais", &"SectionLabel"))
	header.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(GameState.routine_seconds_left(kind))))
	box.add_child(header)
	for id in ids:
		ProgressionUi.routine_card(box, kind, id)
