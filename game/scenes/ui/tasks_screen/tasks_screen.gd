extends PanelContainer
## História, Pessoas e Diárias, com uma sanfona por vez.
var _group := "story"
var _line := ""
var _routine := ""
var _content: Control
var _ready_routines: Array[Dictionary] = []
var _ready_characters: Array[String] = []
var _seen_quests: Array[String] = []
var _claim_all: Button
var _animate_detail := ""

func _ready() -> void:
	_content = SheetBuilder.LiveBox.new(_build)
	%Holder.add_child(_content)
	visibility_changed.connect(_visibility_changed)

func _visibility_changed() -> void:
	if not is_visible_in_tree(): _mark_people_seen()
	sync_hud()

func _mark_people_seen() -> void:
	if _seen_quests.is_empty(): return
	var keys: Array[String] = _seen_quests.duplicate()
	_seen_quests.clear()
	GameState.mark_seen(keys)

func _build(box: VBoxContainer) -> void:
	box.add_theme_constant_override("separation", 12)
	_ready_routines.clear()
	_ready_characters.clear()
	for kind: String in ["daily", "weekly"]:
		for id: String in GameState.routine_ids(kind):
			if GameState.routine_error(kind, id) == "": _ready_routines.append({"kind": kind, "id": id})
	var characters := _character_quests()
	for ids: Array in characters.values():
		for id: String in ids:
			if GameState.quest_error(id) == "": _ready_characters.append(id)
	_update_groups(characters)
	match _group:
		"story": _story_card(box)
		"characters": _characters(box, characters)
		"timed":
			_routines(box, "daily")
			_routines(box, "weekly")
	sync_hud()

func _update_groups(characters: Dictionary) -> void:
	for child: Node in %GroupTabs.get_children():
		%GroupTabs.remove_child(child)
		child.queue_free()
	if _group == "characters" and characters.is_empty(): _group = "story"
	if _group == "timed" and not GameState.routines_unlocked("daily"): _group = "story"
	var current := GameState.progress.current_main_quest()
	var entries: Array[Dictionary] = [{"id": "story", "text": "História", "icon": UiKit.ui_icon("tab_tasks")}]
	if current != "" and GameState.quest_error(current) == "": entries[0].count = 1
	if not characters.is_empty():
		var npc := str(Database.quests[_ready_characters[0]].get("npc", "bloblo")) if not _ready_characters.is_empty() else "bloblo"
		entries.append({"id": "characters", "text": "Pessoas", "icon": ProgressionUi.npc_portrait(npc)})
		if not _ready_characters.is_empty(): entries.back().count = _ready_characters.size()
	if GameState.routines_unlocked("daily"):
		entries.append({"id": "timed", "text": "Diárias", "icon": UiKit.ctl_icon("clock")})
		if not _ready_routines.is_empty(): entries.back().count = _ready_routines.size()
	for entry: Dictionary in entries: entry.inline_icon = true
	%GroupTabs.add_child(UiKit.segmented(entries, _group, choose_group))

## A casca chama depois de trocar a tela, liberando o espaço dos anéis do Tiro.
func sync_hud() -> void:
	var host := get_tree().root.find_child("Main", true, false)
	if not host: return
	var hud := host.find_child("TopBar", true, false) as Hud
	if _claim_all:
		if _claim_all.get_parent(): _claim_all.get_parent().remove_child(_claim_all)
		_claim_all.queue_free()
		_claim_all = null
	if not is_visible_in_tree(): return
	hud.set_row2_right(null)
	var count := _ready_routines.size() if _group == "timed" else (_ready_characters.size() if _group == "characters" else 0)
	if count < 2: return
	_claim_all = UiKit.small_go("Pegar tudo (%d)" % count, func() -> void:
		if _group == "timed": ProgressionUi.claim_routine_rows(_content, _ready_routines.duplicate())
		else: _claim_characters(_ready_characters.duplicate()))
	_claim_all.name = "ClaimAllRoutines" if _group == "timed" else "ClaimAllCharacters"
	hud.set_row2_right(_claim_all)

func choose_group(id: String) -> void:
	if _group == "characters" and id != _group: _mark_people_seen()
	_group = id
	%Scroll.scroll_vertical = 0
	_content.call("refresh")

func choose_routine(kind: String) -> void:
	if _group != "timed": choose_group("timed")
	_scroll_routine.call_deferred(kind)

func _scroll_routine(kind: String) -> void:
	var section := _content.find_child("Routines_" + kind, true, false) as Control
	if section: %Scroll.ensure_control_visible(section)

func choose_routine_detail(kind: String, id: String) -> void:
	var key := kind + "_" + id
	_routine = "" if _routine == key else key
	_content.call("refresh")

func _character_quests() -> Dictionary:
	var groups := {}
	for line: String in GameState.progress.lines():
		var id := GameState.progress.current_line_quest(line)
		if id == "": continue
		var npc := str(Database.quests[id].get("npc", ""))
		if not groups.has(npc): groups[npc] = []
		groups[npc].append(id)
	return groups

func choose_character(npc: String) -> void:
	var ids: Array = _character_quests().get(npc, [])
	if not ids.is_empty(): choose_line(str(Database.quests[ids[0]].line))

func choose_line(line: String) -> void:
	_line = "" if _line == line else line
	_animate_detail = _line
	_content.call("refresh")

func _claim_characters(ids: Array[String]) -> void:
	if _content.get_meta("ui_animating", false): return
	_content.set_meta("ui_animating", true)
	for id: String in ids:
		if GameState.quest_error(id) != "": continue
		var row := _content.find_child("LineCard_" + str(Database.quests[id].line), true, false) as Control
		ProgressionUi.claim_quest_fx(id, row.get_global_rect().get_center() if row else get_global_rect().get_center())
		if row: Motion.pop_out(row, false)
		if not Motion.reduced: await get_tree().create_timer(0.08).timeout
	_content.set_meta("ui_animating", false)
	_content.call("refresh")

func _characters(box: VBoxContainer, groups: Dictionary) -> void:
	var ids: Array[String] = []
	for quests: Array in groups.values(): ids.append_array(quests)
	ids.sort_custom(func(a: String, b: String) -> bool: return GameState.quest_error(a) == "" and GameState.quest_error(b) != "")
	var list := UiKit.list_card(box)
	for id: String in ids:
		var quest: Dictionary = Database.quests[id]
		var line := str(quest.line)
		var ready := GameState.quest_error(id) == ""
		var goal := ProgressionUi.current_goal(id)
		var target := int(goal.get("target", 1))
		var meta := UiKit.hbox(4)
		meta.add_child(UiKit.icon(ProgressionUi.goal_icon(goal), 20))
		meta.add_child(UiKit.short_label("%d/%d" % [mini(GameState.goal_value(goal), target), target], &"SmallLabel", Palette.GO_INK if ready else Palette.INK_SOFT))
		var action := UiKit.small_go("Pegar", func() -> void: _claim_characters([id])) if ready else UiKit.ctl_button("chev", choose_line.bind(line), 32, "sunken")
		action.name = "ClaimQuest_" + id if ready else "OpenLine_" + line
		var row := UiKit.list_row(ProgressionUi.npc_portrait(str(quest.npc)), str(quest.name), [meta], action, choose_line.bind(line), ready)
		row.name = "LineCard_" + line
		row.set_meta("quest", id)
		var top := row.get_child(0).get_child(0) as HBoxContainer
		var face := top.get_child(0) as PanelContainer
		(face.get_child(0) as TextureRect).custom_minimum_size = Vector2(44, 44)
		if not ready and int(quest.rewards.get("coins", 0)) > 0:
			top.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(quest.rewards.get("coins", 0)), null, "prize"))
			top.move_child(action, top.get_child_count() - 1)
		var seen_key := "ui:quest_new:" + id
		if not GameState.progress.seen.has(seen_key):
			var overlay := Control.new()
			overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			face.add_child(overlay)
			var badge := UiKit.short_label("Nova", &"SmallLabel", Palette.HONEY_INK)
			badge.name = "QuestNew"
			badge.add_theme_stylebox_override("normal", UiKit.surface(Palette.HONEY_SOFT, 8))
			overlay.add_child(badge)
			badge.position = Vector2(0, 28)
			if seen_key not in _seen_quests: _seen_quests.append(seen_key)
		list.add_child(row)
		if _line == line:
			var detail := UiKit.vbox(8)
			detail.name = "LineDetail_" + line
			(row.get_child(0) as VBoxContainer).add_child(detail)
			_quest_detail(detail, id, false)
			if _animate_detail == line:
				Motion.pop_in(detail)
				_animate_detail = ""
			var disc := action.find_child("Disc", true, false) as Control
			if not ready and disc:
				disc.pivot_offset = Vector2(16, 16)
				disc.rotation = PI / 2

func _story_card(box: VBoxContainer) -> void:
	var index := GameState.progress.chapter_index()
	var current := GameState.progress.current_main_quest()
	var displayed := GameState.progress.displayed_main_quest()
	var card := UiKit.card(box)
	card.name = "StoryCard"
	if displayed != "" and GameState.quest_error(displayed) == "": card.add_child(UiKit.ready_dot())
	card.add_child(UiKit.section("Capítulo"))
	card.add_child(UiKit.label(str(GameState.current_chapter().get("name", "História")), &"StrongLabel"))
	if index > Database.progression.chapters.size():
		card.add_child(UiKit.label("História concluída!", &"StrongLabel", Palette.GO_INK))
		return
	var ids := GameState.progress.main_quests(index)
	card.add_child(UiKit.steps(ids.size(), ids.find(current)))
	if displayed != "":
		var quest: Dictionary = Database.quests[displayed]
		card.add_child(ProgressionUi.quest_speech(displayed, true))
		var shared := str(Database.quests[current].get("shared_with", ""))
		if shared != "":
			var guidance := UiKit.label("A história segue com " + str(Database.npcs.get(str(quest.npc), {}).get("name", "")), &"SmallLabel")
			guidance.name = "SharedQuestGuidance"
			card.add_child(guidance)
			for goal: Dictionary in quest.goals: card.add_child(ProgressionUi.quest_goal_strip(goal))
			card.add_child(ProgressionUi.reward_chips(quest.rewards))
			card.add_child(UiKit.soft("Ver em Pessoas", func() -> void:
				_line = str(quest.line)
				choose_group("characters"), null, true))
		else: _quest_detail(card, displayed, true)
	var done := 0
	for id: String in ids:
		if GameState.progress.claimed_quests.has(id): done += 1
	var steps := UiKit.vbox(8)
	steps.name = "ChapterSteps"
	box.add_child(steps)
	steps.add_child(UiKit.section("Neste capítulo", UiKit.short_label("%d de %d" % [done, ids.size()], &"SmallLabel")))
	var list := UiKit.list_card(steps)
	for id: String in ids:
		var claimed := GameState.progress.claimed_quests.has(id)
		var row := UiKit.list_row(UiKit.ctl_icon("check" if claimed else ("chev" if id == current else "lock")), str(Database.quests[id].name), [])
		row.name = "ChapterStep_" + id
		if id == current: row.add_theme_stylebox_override("panel", UiKit.surface(Palette.HONEY_SOFT, 16))
		elif not claimed: row.modulate.a = 0.5
		list.add_child(row)
	var full := UiKit.ghost("História completa ›", func() -> void: Events.sheet_requested.emit("História", ProgressionUi.story_panel()))
	full.name = "StoryFull"
	box.add_child(full)

func _quest_detail(box: VBoxContainer, id: String, main_action: bool) -> void:
	if not main_action:
		ProgressionUi.character_quest_detail(box, id)
		return
	for goal: Dictionary in Database.quests[id].goals: box.add_child(ProgressionUi.quest_goal_strip(goal))
	var bottom := UiKit.hbox(4)
	var prizes := ProgressionUi.reward_chips(Database.quests[id].rewards)
	prizes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(prizes)
	var actions := UiKit.vbox(0)
	bottom.add_child(actions)
	ProgressionUi.quest_action(actions, id, main_action)
	box.add_child(bottom)

func _routines(box: VBoxContainer, kind: String) -> void:
	if not GameState.routines_unlocked(kind): return
	var section := UiKit.vbox(8)
	section.name = "Routines_" + kind
	box.add_child(section)
	section.add_child(UiKit.section("Hoje" if kind == "daily" else "Semana", UiKit.chip(UiKit.ctl_icon("clock"), TimeText.short(GameState.routine_seconds_left(kind)), null, "time")))
	var list := UiKit.list_card(section)
	var shown := 0
	for id: String in GameState.routine_ids(kind):
		if GameState.routine_claimed(kind, id): continue
		shown += 1
		var data := GameState.routine_data(kind, id)
		var target := GameState.routine_target(kind, id)
		var value := mini(GameState.routine_value(kind, id), target)
		var ready := GameState.routine_error(kind, id) == ""
		var key := kind + "_" + id
		var action := UiKit.small_go("Pegar", func() -> void: ProgressionUi.claim_routine_rows(_content, [{"kind": kind, "id": id}])) if ready else UiKit.ctl_button("chev", choose_routine_detail.bind(kind, id), 32, "sunken")
		var row := UiKit.list_row(null, str(data.name), [UiKit.short_label("%d/%d" % [value, target], &"SmallLabel", Palette.GO_INK if ready else Palette.INK_SOFT)], action, choose_routine_detail.bind(kind, id), ready)
		row.name = "Routine_" + key
		var top := row.get_child(0).get_child(0) as HBoxContainer
		top.get_child(0).free()
		var ring := UiKit.ring(ProgressionUi.stat_icon(str(data.goal.key)), float(value) / maxi(1, target), Palette.GO if ready else Palette.SKY, 44)
		top.add_child(ring)
		top.move_child(ring, 0)
		if not ready and int(data.rewards.get("coins", 0)) > 0:
			top.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(data.rewards.get("coins", 0)), null, "prize"))
			top.move_child(action, top.get_child_count() - 1)
		list.add_child(row)
		if _routine == key:
			var detail := UiKit.vbox(8)
			detail.name = "RoutineDetail_" + key
			(row.get_child(0) as VBoxContainer).add_child(detail)
			detail.add_child(UiKit.label(str(data.get("description", data.name))))
			detail.add_child(ProgressionUi.reward_chips(data.rewards))
			detail.add_child(UiKit.soft("Ir →", func() -> void: Places.go(Places.goal_target({"type": "stat", "key": data.goal.key})), null, true))
			Motion.pop_in(detail)
	if shown == 0: list.add_child(UiKit.list_row(UiKit.ctl_icon("check"), "Tudo feito por hoje!" if kind == "daily" else "Tudo feito nesta semana!", []))
