extends PanelContainer
## Missões em três grupos; linhas secundárias agrupadas por personagem, abertas sob demanda.

var _group := "story"
var _npc := ""
var _routine_kind := "daily"
var _content: Control
var _tabs_key := ""


func _ready() -> void:
	_content = SheetBuilder.LiveBox.new(_build)
	%Holder.add_child(_content)


var _ready_routines: Array[Dictionary] = []


func _build(box: VBoxContainer) -> void:
	_ready_routines.clear()
	for kind: String in ["daily", "weekly"]:
		for id: String in GameState.routine_ids(kind):
			if GameState.routine_error(kind, id) == "": _ready_routines.append({"kind": kind, "id": id})
	var characters := _character_quests()
	var character_ready := 0
	for ids: Array in characters.values():
		for id: String in ids:
			if GameState.quest_error(id) == "": character_ready += 1
	var current := GameState.progress.current_main_quest()
	var story_ready := current != "" and str(Database.quests[current].get("shared_with", "")) == "" and GameState.quest_error(current) == ""
	_update_groups(story_ready, character_ready > 0)
	box.add_child(UiKit.label("! = prêmio pronto para pegar", &"SmallLabel"))
	match _group:
		"story": _story_card(box)
		"characters": _characters(box, characters)
		"timed":
			var tabs: Array[Dictionary] = []
			for kind: String in ["daily", "weekly"]:
				tabs.append({"id": kind, "text": "Diárias" if kind == "daily" else "Semanais", "alert": _ready_routines.any(func(entry: Dictionary) -> bool: return entry.kind == kind)})
			box.add_child(UiKit.segmented(tabs, _routine_kind, choose_routine))
			if GameState.routines_unlocked(_routine_kind):
				_routines(box, _routine_kind)
			else:
				box.add_child(UiKit.label("Chegam ao avançar na história.", &"SmallLabel"))


func _update_groups(story_ready: bool, characters_ready: bool) -> void:
	var key := str([_group, story_ready, characters_ready, not _ready_routines.is_empty()])
	if key == _tabs_key: return
	_tabs_key = key
	for child in %GroupTabs.get_children():
		%GroupTabs.remove_child(child)
		child.queue_free()
	var groups := UiKit.segmented([
		{"id": "story", "text": "Principal", "alert": story_ready},
		{"id": "characters", "text": "Personagens", "alert": characters_ready},
		{"id": "timed", "text": "Temporárias", "alert": not _ready_routines.is_empty()},
	], _group, choose_group)
	for button: Button in groups.get_children():
		button.add_theme_font_size_override("font_size", 16)
	%GroupTabs.add_child(groups)


func choose_group(id: String) -> void:
	_group = id
	%Scroll.scroll_vertical = 0
	_content.call("refresh")


func choose_routine(id: String) -> void:
	_routine_kind = id
	%Scroll.scroll_vertical = 0
	_content.call("refresh")


func _character_quests() -> Dictionary:
	var groups := {}
	for line: String in GameState.progress.lines():
		var id := GameState.progress.current_line_quest(line)
		if id != "":
			var npc := str(Database.quests[id].get("npc", ""))
			if not groups.has(npc): groups[npc] = []
			groups[npc].append(id)
	return groups


func choose_character(id: String) -> void:
	_npc = "" if _npc == id else id
	_content.call("refresh")


func _characters(box: VBoxContainer, groups: Dictionary) -> void:
	if groups.is_empty():
		box.add_child(UiKit.label("Novas missões chegam ao conhecer os personagens.", &"SmallLabel"))
	var npcs: Array = groups.keys()
	npcs.sort_custom(func(a: String, b: String) -> bool:
		var ready_a := (groups[a] as Array).any(func(id: String) -> bool: return GameState.quest_error(id) == "")
		var ready_b := (groups[b] as Array).any(func(id: String) -> bool: return GameState.quest_error(id) == "")
		return ready_a and not ready_b)
	for npc: String in npcs:
		var ids: Array = groups[npc]
		var ready := ids.filter(func(id: String) -> bool: return GameState.quest_error(id) == "").size()
		var card := UiKit.card(box, &"ReadyCardPanel" if ready > 0 else &"CardPanel")
		card.name = "Character_" + npc
		var chips: Array[Control] = []
		if ready > 0:
			chips.append(UiKit.alert_badge())
			chips.append(UiKit.short_label("1 prêmio pronto" if ready == 1 else "%d prêmios prontos" % ready, &"SmallLabel", Palette.GOOD))
		else:
			chips.append(UiKit.short_label("1 missão" if ids.size() == 1 else "%d missões" % ids.size(), &"SmallLabel"))
		var open := UiKit.secondary("Fechar" if _npc == npc else "Abrir", choose_character.bind(npc), null, true)
		open.name = "CharacterOpen_" + npc
		card.add_child(UiKit.list_row(ProgressionUi.npc_portrait(npc), str(Database.npcs.get(npc, {}).get("name", "Personagem")), chips, open))
		if _npc == npc:
			ids.sort_custom(func(a: String, b: String) -> bool: return GameState.quest_error(a) == "" and GameState.quest_error(b) != "")
			var primary_used := false
			for id: String in ids:
				var primary := not primary_used and GameState.quest_error(id) == ""
				_line_card(card, id, primary)
				primary_used = primary_used or primary


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
		_quest_body(card, displayed)


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
		var npc_id := str(Database.quests[current].get("npc", ""))
		card.add_child(UiKit.secondary("Ver missões de " + name, func() -> void:
			_npc = npc_id
			choose_group("characters"), null, true))


## Cartão de uma linha secundária (ex.: vovó Bloblo): passos da linha + o passo atual.
func _line_card(box: VBoxContainer, id: String, primary: bool = false) -> void:
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.quest_error(id) == "" else &"CardPanel")
	card.name = "LineCard_" + str(Database.quests[id].line)
	var ids := GameState.progress.line_quests(str(Database.quests[id].line))
	card.add_child(_step_dots(ids.size(), ids.find(id)))
	_quest_body(card, id, primary)


func _quest_body(card: VBoxContainer, id: String, primary: bool = true) -> void:
	var quest: Dictionary = Database.quests[id]
	var who := UiKit.hbox(10)
	if GameState.quest_error(id) == "":
		var badge := UiKit.alert_badge()
		badge.name = "ReadyDot"
		who.add_child(badge)
	who.add_child(UiKit.fill_label(quest.name, &"SectionLabel"))
	who.add_child(_destination(Places.quest_target(id)))
	card.add_child(who)
	if GameState.quest_error(id) == "": card.add_child(UiKit.label("Prêmio pronto!", &"SmallLabel", Palette.GOOD))
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
	if target.has("notebook"): texture = UiKit.ui_icon("ui_notebook")
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
	header.add_child(UiKit.chip(UiKit.ctl_icon("clock"), TimeText.short(GameState.routine_seconds_left(kind))))
	section.add_child(header)
	# Uma única ação principal para todas as rotinas prontas, inclusive entre seções.
	if _ready_routines.size() >= 2:
		var collect := UiKit.primary("Pegar tudo (%d)" % _ready_routines.size(), func() -> void:
			ProgressionUi.claim_routine_rows(box, _ready_routines.duplicate()))
		collect.name = "ClaimAllRoutines"
		section.add_child(collect)
	var shown := 0
	for id in ids:
		if GameState.routine_claimed(kind, id): continue
		ProgressionUi.routine_card(section, kind, id, _ready_routines.size() == 1)
		shown += 1
	if shown == 0: section.add_child(UiKit.label("Tudo feito por hoje!" if kind == "daily" else "Tudo feito nesta semana!", &"SmallLabel", Palette.GOOD))
