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
## Moldura de madeira atrás do grupo História (some nos outros grupos) e o vão que a separa das abas.
var _frame_holder: Control
var _frame: NinePatchRect
var _title_holder: Control
var _plaque: Control
var _gap: Control
var _gap_fixed := false
var _fit_queued := false

const FRAME_SIDE := 8.0   # margem da moldura até a borda da tela, igual dos dois lados
const BORDER := 30.0      # madeira da moldura
const PAD := 12.0         # folga entre a madeira e a lista
const STORY_EDGE := 50.0  # FRAME_SIDE + BORDER + PAD: da borda da tela até o conteúdo

func _ready() -> void:
	_build_story_frame()
	_content = SheetBuilder.LiveBox.new(_build)
	%Holder.add_child(_content)
	visibility_changed.connect(_visibility_changed)


## Moldura de madeira atrás da lista (como a Mochila, mas só no retângulo da lista), placa do título por cima da borda
## de cima e um vão acima dela para as abas não encostarem.
func _build_story_frame() -> void:
	_frame_holder = Control.new()
	_frame_holder.name = "MissionFrame"
	_frame_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_holder)
	move_child(_frame_holder, 0)
	_frame = MissionUi.frame(_frame_holder, "frame", Vector4(BORDER, BORDER, BORDER, BORDER), "Frame", Vector4.ZERO, false)
	_title_holder = Control.new()
	_title_holder.name = "MissionTitle"
	_title_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_holder)
	_gap = Control.new()
	_gap.name = "MissionGap"
	_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%Scroll.get_parent().add_child(_gap)
	%Scroll.get_parent().move_child(_gap, %Scroll.get_index())
	%Scroll.item_rect_changed.connect(_queue_fit)
	resized.connect(_queue_fit)
	_set_story_look(true)


## Topo da barra de abas (a arte ou o painel, o que estiver mais alto): a moldura termina logo acima.
func _bar_top() -> float:
	var host := get_tree().root.find_child("Main", true, false)
	var top := INF
	if host:
		for node_name: String in ["TabBarArt", "TabBar"]:
			var bar := host.find_child(node_name, true, false) as Control
			if bar and bar.is_visible_in_tree():
				top = minf(top, bar.get_global_rect().position.y)
	return top if top != INF else global_position.y + size.y - 96.0


## Os sinais de layout só marcam o ajuste: ele roda uma vez no fim do quadro (nada de recursão dentro do layout).
func _queue_fit() -> void:
	if _fit_queued:
		return
	_fit_queued = true
	_fit_frame.call_deferred()


func _frame_width() -> float:
	return maxf(size.x, 360.0) - 2.0 * FRAME_SIDE


## Placa do capítulo: 78% da largura da moldura, metade fora da borda de cima. O vão acima da lista acompanha a altura dela.
func _set_plaque(value: String) -> void:
	for child: Node in _title_holder.get_children():
		_title_holder.remove_child(child)
		child.queue_free()
	_plaque = MissionUi.plaque(value, roundf(_frame_width() * 0.78))
	_title_holder.add_child(_plaque)
	var tabs_gap := 12.0 if (%GroupTabs as Control).visible else 0.0
	_gap.custom_minimum_size = Vector2(0, 8.0 + _plaque.size.y / 2.0 + BORDER + PAD - 12.0 - tabs_gap)
	_gap_fixed = false
	_queue_fit()


## A moldura fica FRAME_SIDE px da borda dos dois lados (medido na tela, não no nó), logo abaixo do vão das abas e
## termina acima da barra de abas; a lista fica recortada no interior marrom (borda + PAD de folga).
func _fit_frame() -> void:
	_fit_queued = false
	if not _frame_holder.visible or not is_inside_tree():
		return
	var panel := get_theme_stylebox("panel")
	var rect := get_global_rect()
	var bottom := _bar_top() - 2.0
	var scroll_end := bottom - BORDER - PAD
	var want := rect.end.y - panel.get_margin(SIDE_BOTTOM) - scroll_end
	if absf(float($Margin.get_theme_constant("margin_bottom")) - want) > 0.5:
		$Margin.add_theme_constant_override("margin_bottom", roundi(want))
		_queue_fit()
		return
	var top := (%Scroll as Control).get_global_rect().position.y - BORDER - PAD
	# A placa começa 8 px abaixo das abas (ou do topo da lista, sem abas): o vão se ajusta até bater.
	var tabs := %GroupTabs as Control
	var tabs_bottom := tabs.get_global_rect().end.y if tabs.visible else ($Margin/Layout as Control).get_global_rect().position.y
	var delta := top - (_plaque.size.y / 2.0 if _plaque else 0.0) - (tabs_bottom + 8.0)
	if absf(delta) > 0.5 and not _gap_fixed:
		_gap_fixed = true  # uma correção só por montagem: sem laço entre o vão e o layout
		_gap.custom_minimum_size = Vector2(0, maxf(0.0, _gap.custom_minimum_size.y - delta))
		_queue_fit()
		return
	_frame.global_position = Vector2(rect.position.x + FRAME_SIDE, top)
	_frame.size = Vector2(rect.size.x - 2.0 * FRAME_SIDE, bottom - top) * 3.0
	if _plaque:
		_plaque.global_position = Vector2(rect.position.x + rect.size.x / 2.0 - _plaque.size.x / 2.0, top - _plaque.size.y / 2.0)


func _set_story_look(on: bool) -> void:
	_frame_holder.visible = on
	_title_holder.visible = on
	_gap.visible = on
	(%Scroll as ScrollContainer).vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER if on else ScrollContainer.SCROLL_MODE_AUTO
	# O painel do tema já recua o conteúdo (margem do estilo); a lista fica a STORY_EDGE px da borda da tela.
	var inset := get_theme_stylebox("panel").get_margin(SIDE_LEFT)
	var side := roundi(STORY_EDGE - inset) if on else 16
	$Margin.add_theme_constant_override("margin_left", side)
	$Margin.add_theme_constant_override("margin_right", side)
	if not on:
		$Margin.add_theme_constant_override("margin_bottom", 96)
	else:
		_queue_fit()


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
	_set_story_look(_group == "story")
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
	%GroupTabs.visible = entries.size() > 1
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
		var action := UiKit.small_go("Pegar", func() -> void: _claim_characters([id])) if ready else UiKit.row_chevron(choose_line.bind(line))
		action.name = "ClaimQuest_" + id if ready else "OpenLine_" + line
		var row := UiKit.list_row(ProgressionUi.npc_portrait(str(quest.npc)), str(quest.name), [meta], action, choose_line.bind(line), ready)
		row.name = "LineCard_" + line
		row.set_meta("quest", id)
		var top := row.get_child(0).get_child(0) as HBoxContainer
		_compact_name(top)
		var face := top.get_child(0) as PanelContainer
		(face.get_child(0) as TextureRect).custom_minimum_size = Vector2(44, 44)
		if ready:
			top.remove_child(action)
			meta.add_child(action)
		if not ready and int(quest.rewards.get("coins", 0)) > 0:
			meta.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(quest.rewards.get("coins", 0)), null, "prize"))
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
			_quest_detail(detail, id)
			if _animate_detail == line:
				Motion.pop_in(detail)
				_animate_detail = ""
			var disc := action.find_child("RowChevron", true, false) as Control
			if not ready and disc:
				disc.pivot_offset = Vector2(10, 10)
				disc.rotation = PI / 2

func _story_card(box: VBoxContainer) -> void:
	var index := GameState.progress.chapter_index()
	var current := GameState.progress.current_main_quest()
	var displayed := GameState.progress.displayed_main_quest()
	var card := UiKit.vbox(8)
	card.name = "StoryCard"
	box.add_child(card)
	var finished: bool = index > Database.progression.chapters.size()
	_set_plaque("História" if finished else str(GameState.current_chapter().get("name", "História")))
	if finished:
		_story_done(card)
		return
	var ids := GameState.progress.main_quests(index)
	if displayed != "":
		var shared := str(Database.quests[current].get("shared_with", "")) != ""
		card.add_child(_story_hero(displayed, ids))
		if shared:
			var guidance := MissionUi.text("A história segue com " + str(Database.npcs.get(str(Database.quests[displayed].npc), {}).get("name", "")), 13, Palette.WOOD_CREAM, 3)
			guidance.name = "SharedQuestGuidance"
			guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(guidance)
		_story_rewards(card, displayed)
		_story_steps(card, displayed)
	var full := MissionUi.link("História completa ›", func() -> void: Events.sheet_requested.emit("História", ProgressionUi.story_panel()))
	full.name = "StoryFull"
	card.add_child(full)


## História toda concluída: o cartão diz onde estamos; só o Álbum é botão, a história completa é um link.
func _story_done(card: VBoxContainer) -> void:
	var done := MissionUi.card("card", Vector4i(12, 12, 12, 12), "StoryDone")
	var heading := UiKit.hbox(8)
	var title := MissionUi.text("Nosso lugar no mundo", 17, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_LEFT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(UiKit.ctl("check", 22, Palette.GO))
	MissionUi.body(done).add_child(heading)
	card.add_child(done)
	var album := MissionUi.button("go", "Álbum", func() -> void: PetNotebook.open("album"))
	album.name = "StoryAlbum"
	card.add_child(album)
	var full := MissionUi.link("História completa ›", func() -> void: Events.sheet_requested.emit("História", ProgressionUi.story_panel()))
	full.name = "StoryFull"
	card.add_child(full)


## Cartão do topo: retrato 84×84, e à direita (mesma borda) título, fala (até 2 linhas) e a barra do capítulo.
func _story_hero(id: String, ids: Array[String]) -> Control:
	var quest: Dictionary = Database.quests[id]
	var hero := MissionUi.card("hero", Vector4i(8, 8, 8, 8), "StoryHero", 12)
	var row := UiKit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	MissionUi.body(hero).add_child(row)
	row.add_child(MissionUi.portrait(ProgressionUi.npc_portrait(str(quest.get("npc", ""))), 84.0))
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(info)
	var title_row := UiKit.hbox(0)
	title_row.add_child(MissionUi.title_tag(str(quest.name)))
	var room := Control.new()
	room.custom_minimum_size = Vector2(32, 0)
	title_row.add_child(room)
	info.add_child(title_row)
	var speech := UiKit.label(str(quest.get("dialogue", "")), &"SmallLabel", Palette.WOOD_INK)
	speech.name = "StorySpeech"
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.max_lines_visible = 2
	speech.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	speech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(speech)
	var done := 0
	for step: String in ids:
		if GameState.progress.claimed_quests.has(step): done += 1
	info.add_child(MissionUi.bar(float(done) / maxi(1, ids.size()), "%d/%d" % [done, ids.size()]))
	var overlay := Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero.add_child(overlay)
	var help := MissionUi.help_button(TaskHelp.open.bind("quest", id))
	overlay.add_child(help)
	help.anchor_left = 1.0
	help.anchor_right = 1.0
	help.offset_left = -40.0
	help.offset_right = -4.0
	help.offset_top = 2.0
	help.offset_bottom = 38.0
	if GameState.quest_error(id) == "":
		var dot := UiKit.ready_dot()
		overlay.add_child(dot)
		dot.position = Vector2(3, 3)
	return hero


## "Recompensas" (pílula centralizada) e o cartão de 88 px: prêmios à esquerda, coluna de 104 px à direita
## (pílula x/y e o botão), na mesma borda direita dos botões Ir.
func _story_rewards(card: VBoxContainer, id: String) -> void:
	var quest: Dictionary = Database.quests[id]
	card.add_child(MissionUi.tag("Recompensas", "StoryRewardsTag"))
	var rewards := MissionUi.card("card", Vector4i(12, 0, 12, 0), "StoryRewards", 10, 88.0)
	card.add_child(rewards)
	var row := UiKit.hbox(8)
	MissionUi.body(rewards).add_child(row)
	var prizes := UiKit.hbox(8)
	prizes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prizes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(prizes)
	var gains: Dictionary = quest.rewards
	var entries: Array[Dictionary] = []
	if int(gains.get("coins", 0)) > 0:
		entries.append({"icon": UiKit.ui_icon("coin"), "amount": "+%d" % int(gains.coins), "name": "Prize_coins"})
	for item: String in gains.get("items", {}):
		entries.append({"icon": Database.item_icon(item), "amount": "+%d" % int(gains.items[item]), "name": "Prize_" + item})
	for collection: String in gains.get("collections", []):
		if not GameState.progress.collection.has(collection):
			entries.append({"icon": UiKit.ui_icon("item_accessory_set"), "amount": "+1", "name": "Prize_" + collection})
	# 56×56; com três prêmios eles encolhem para caber ao lado da coluna de 104 px.
	var room := (maxf(size.x, 360.0) - 2.0 * STORY_EDGE) - 24.0 - MissionUi.BUTTON.x - 8.0
	var edge := minf(56.0, floorf((room - 8.0 * (entries.size() - 1)) / maxf(1.0, entries.size())))
	for entry: Dictionary in entries:
		prizes.add_child(MissionUi.tile(entry.icon, entry.amount, entry.name, Vector2(edge, edge)))
	var met := 0
	for goal: Dictionary in quest.goals:
		if GameState.goal_value(goal) >= int(goal.get("target", 1)): met += 1
	var column := UiKit.vbox(4)
	column.custom_minimum_size = Vector2(MissionUi.BUTTON.x, 0)
	column.size_flags_horizontal = Control.SIZE_SHRINK_END
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.add_child(MissionUi.pill("green" if met == quest.goals.size() else "brown", "%d/%d" % [met, quest.goals.size()], "StoryGoalsPill"))
	row.add_child(column)
	var claimed := GameState.progress.claimed_quests.has(id)
	var ready := GameState.quest_error(id) == ""
	var claim := MissionUi.button("go", "Resgatado" if claimed else "Pegar", func() -> void: ProgressionUi.claim_quest_fx(id, rewards.get_global_rect().get_center()))
	claim.name = "ClaimQuest_" + id
	claim.disabled = claimed or not ready
	if claim.disabled:
		claim.get_node("Frame").modulate = Color(0.48, 0.48, 0.48, 0.65)
		claim.add_theme_color_override("font_disabled_color", Palette.WOOD_CREAM.darkened(0.28))
	column.add_child(claim)
	# Objetivos cumpridos com depósito cheio: mantém o caminho para liberar espaço.
	var shortage := GameState.quest_reward_shortage(id)
	if not claimed and not shortage.is_empty():
		var depot := str(shortage.depot)
		var space := MissionUi.button("go", "Liberar espaço", func() -> void: Places.go({"storage": depot}), MissionUi.BUTTON.x, 12)
		space.name = "QuestSpace_" + id
		column.add_child(space)


## "Passos": título centralizado e um cartão por objetivo. Linha 1: instrução + pílula n/m; linha 2: ícone 48×48
## e o botão Ir 104×44 (ou o ✓ no lugar dele).
func _story_steps(card: VBoxContainer, id: String) -> void:
	var quest: Dictionary = Database.quests[id]
	card.add_child(MissionUi.heading("Passos", "StoryStepsTitle"))
	var first_open := -1
	for i in quest.goals.size():
		var goal: Dictionary = quest.goals[i]
		var target := int(goal.get("target", 1))
		var value := mini(GameState.goal_value(goal), target)
		var complete := value >= target
		if not complete and first_open < 0: first_open = i
		var step := MissionUi.card("card", Vector4i(12, 12, 12, 12), "StoryGoal_%d" % i)
		if complete:
			step.get_node("Art/Frame").self_modulate = Color(0.90, 1.0, 0.90)
		var lines := UiKit.vbox(8)
		MissionUi.body(step).add_child(lines)
		var top := UiKit.hbox(8)
		lines.add_child(top)
		var words := MissionUi.text(str(goal.get("label", "")), 13, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_LEFT)
		words.name = "StepText"
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.max_lines_visible = 2
		words.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		top.add_child(words)
		var count := MissionUi.pill("green" if complete else "brown", "%d/%d" % [value, target], "StepPill_%d" % i)
		count.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		top.add_child(count)
		var bottom := UiKit.hbox(8)
		lines.add_child(bottom)
		if str(goal.get("type", "")) == "growth":
			var holder := MissionUi.tile(null)
			(holder.get_child(1) as CenterContainer).add_child(ProgressionUi._growth_silhouette(goal, value, 32))
			bottom.add_child(holder)
		else:
			bottom.add_child(MissionUi.tile(ProgressionUi.goal_icon(goal)))
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom.add_child(spacer)
		if complete:
			var done_box := MissionUi.done_status()
			done_box.name = "StepDone_%d" % i
			bottom.add_child(done_box)
		else:
			# Cada passo usa seu próprio destino, inclusive nas missões de Pessoas.
			var target_place := Places.goal_target(goal)
			var go := MissionUi.button("go", "Ir" if not target_place.is_empty() else "Como fazer", func() -> void:
				if target_place.is_empty(): TaskHelp.open("quest", id)
				else: Places.go(target_place), MissionUi.BUTTON.x, 16 if not target_place.is_empty() else 12)
			go.name = ("QuestGo_" + id) if i == first_open else "GoalGo_%d" % i
			bottom.add_child(go)
		card.add_child(step)


func _quest_detail(box: VBoxContainer, id: String) -> void:
	ProgressionUi.character_quest_detail(box, id)


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
		var action := UiKit.small_go("Pegar", func() -> void: ProgressionUi.claim_routine_rows(_content, [{"kind": kind, "id": id}])) if ready else UiKit.row_chevron(choose_routine_detail.bind(kind, id))
		var row := UiKit.list_row(null, str(data.name), [UiKit.short_label("%d/%d" % [value, target], &"SmallLabel", Palette.GO_INK if ready else Palette.INK_SOFT)], action, choose_routine_detail.bind(kind, id), ready)
		row.name = "Routine_" + key
		var top := row.get_child(0).get_child(0) as HBoxContainer
		_compact_name(top)
		top.get_child(0).free()
		var ring := UiKit.ring(ProgressionUi.stat_icon(str(data.goal.key)), float(value) / maxi(1, target), Palette.GO if ready else Palette.SKY, 44)
		top.add_child(ring)
		top.move_child(ring, 0)
		if not ready and int(data.rewards.get("coins", 0)) > 0:
			var meta := top.get_child(1).get_child(1) as FlowContainer
			meta.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(data.rewards.get("coins", 0)), null, "prize"))
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


## A linha inteira abre o detalhe; nome curto não disputa espaço com o disco de uma seta.
func _compact_name(top: HBoxContainer) -> void:
	top.add_theme_constant_override("separation", 4)
	for node: Node in top.find_children("*", "Label", true, false):
		var title := node as Label
		if title.theme_type_variation == &"":
			title.autowrap_mode = TextServer.AUTOWRAP_OFF
			title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			title.clip_text = true


## A casca sobe o conteúdo quando a linha 2 do HUD está vazia (história concluída): `top` = margem de cima.
func set_content_top(top: float) -> void:
	$Margin.add_theme_constant_override("margin_top", roundi(top))
