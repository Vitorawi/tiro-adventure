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
## Moldura de madeira atrás da lista (nos três grupos) e a bandeja de abas por cima da borda de cima.
## A geometria é só função do tamanho da tela e do topo da barra de abas: nada é medido depois do layout.
var _frame_holder: Control
var _frame: NinePatchRect
var _tabs_holder: Control
var _tabs: Control
var _tabs_sig := ""
## A bandeja começa logo abaixo da linha 1 do HUD: a linha 2 fica vazia nesta tela (o "Pegar tudo" mora na lista).
var _content_top := Hud.ROW2_TOP

const FRAME_SIDE := 8.0   # margem da moldura até a borda da tela, igual dos dois lados
const BORDER := 30.0      # madeira da moldura
const PAD := 12.0         # folga entre a madeira e a lista
const STORY_EDGE := 50.0  # FRAME_SIDE + BORDER + PAD: da borda da tela até o conteúdo
const TABS_WIDTH := 0.86  # largura da bandeja em relação à moldura

func _ready() -> void:
	_build_frame()
	_content = SheetBuilder.LiveBox.new(_build)
	%Holder.add_child(_content)
	visibility_changed.connect(_visibility_changed)
	_layout.call_deferred()


func _build_frame() -> void:
	# Fundo da tela inteira igual ao da Mochila (madeira com o papel creme até o topo); o quadro fica na frente.
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var backdrop := Control.new()
	backdrop.name = "MissionBackdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	move_child(backdrop, 0)
	BagUi.frame(backdrop, "frame", Vector4(14, 150, 14, 77), "Frame")
	_frame_holder = Control.new()
	_frame_holder.name = "MissionFrame"
	_frame_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_holder)
	move_child(_frame_holder, 1)
	_frame = MissionUi.frame(_frame_holder, "frame", Vector4(BORDER, BORDER, BORDER, BORDER), "Frame", Vector4.ZERO, false)
	_tabs_holder = Control.new()
	_tabs_holder.name = "MissionTabs"
	_tabs_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tabs_holder)
	(%Scroll as ScrollContainer).vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	resized.connect(_layout)


## Barra de abas da casca (arte ou painel, o que estiver mais alto), em coordenadas locais deste painel.
func _bar_top_local() -> float:
	var host := get_tree().root.find_child("Main", true, false)
	var top := INF
	if host:
		for node_name: String in ["TabBarArt", "TabBar"]:
			var bar := host.find_child(node_name, true, false) as Control
			if bar and bar.is_visible_in_tree():
				top = minf(top, bar.get_global_rect().position.y)
				if not bar.resized.is_connected(_layout):
					bar.resized.connect(_layout)
	return (top - global_position.y) if top != INF else size.y - 96.0


## Largura da tela: nunca a do conteúdo (um texto largo não pode alargar a moldura nem a bandeja).
func _screen_width() -> float:
	return minf(size.x, get_viewport_rect().size.x)


func _frame_top() -> float:
	return _content_top + MissionUi.TRAY_HEIGHT / 2.0


## Posiciona moldura, bandeja e lista a partir de: tamanho da tela, `_content_top` e topo da barra de abas.
## Roda só em resized/visibilidade/mudança da barra (nunca na reconstrução de 1 s do conteúdo).
func _layout() -> void:
	if not is_inside_tree() or size.x <= 0.0:
		return
	var panel := get_theme_stylebox("panel")
	var inset := panel.get_margin(SIDE_LEFT)
	var side := roundi(STORY_EDGE - inset)
	var top := _frame_top()
	var bottom := _bar_top_local() - 2.0
	var scroll_top := top + BORDER + PAD
	var scroll_end := bottom - BORDER - PAD
	var margins := {
		"margin_left": side,
		"margin_right": side,
		"margin_top": roundi(scroll_top - panel.get_margin(SIDE_TOP)),
		"margin_bottom": roundi(size.y - panel.get_margin(SIDE_BOTTOM) - scroll_end),
	}
	for key: String in margins:
		if $Margin.get_theme_constant(key) != int(margins[key]):
			$Margin.add_theme_constant_override(key, int(margins[key]))
	# Os dois suportes são filhos diretos do PanelContainer: a origem deles é a margem do estilo.
	var origin := Vector2(inset, panel.get_margin(SIDE_TOP))
	var frame_width := _screen_width() - 2.0 * FRAME_SIDE
	_frame.position = Vector2(FRAME_SIDE, top) - origin
	_frame.size = Vector2(frame_width, bottom - top) * 3.0
	_place_tabs()


func _place_tabs() -> void:
	if _tabs == null or not is_instance_valid(_tabs):
		return
	var panel := get_theme_stylebox("panel")
	# Cada aba tem sempre a largura de um terço da bandeja cheia: com menos grupos a bandeja encolhe (não estica a aba).
	var full := roundf((_screen_width() - 2.0 * FRAME_SIDE) * TABS_WIDTH)
	var count := maxi(1, _tabs.get_node("TabRow").get_child_count())
	var tab_width := (full - 12.0 - 8.0) / 3.0
	var tabs_width := roundf(12.0 + count * tab_width + (count - 1) * 4.0)
	_tabs.position = Vector2(roundf(_screen_width() / 2.0 - tabs_width / 2.0) - panel.get_margin(SIDE_LEFT), _content_top - panel.get_margin(SIDE_TOP))
	_tabs.size = Vector2(tabs_width, MissionUi.TRAY_HEIGHT)


func _visibility_changed() -> void:
	if not is_visible_in_tree(): _mark_people_seen()
	else: _layout()
	sync_hud()

func _mark_people_seen() -> void:
	if _seen_quests.is_empty(): return
	var keys: Array[String] = _seen_quests.duplicate()
	_seen_quests.clear()
	GameState.mark_seen(keys)

func _build(box: VBoxContainer) -> void:
	box.add_theme_constant_override("separation", 20 if _group == "timed" else 12)
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
	_add_claim_all(box)
	match _group:
		"story": _story_card(box)
		"characters": _characters(box, characters)
		"timed":
			_routines(box, "daily")
			_routines(box, "weekly")
	sync_hud()

func _update_groups(characters: Dictionary) -> void:
	if _group == "characters" and characters.is_empty(): _group = "story"
	if _group == "timed" and not GameState.routines_unlocked("daily"): _group = "story"
	var current := GameState.progress.current_main_quest()
	var entries: Array[Dictionary] = [{"id": "story", "text": "Principal", "alert": current != "" and GameState.quest_error(current) == ""}]
	# As três abas aparecem sempre (o topo é igual em todos os grupos); as fechadas ganham cadeado e explicam no toque.
	entries.append({"id": "characters", "text": "Pessoas", "alert": not _ready_characters.is_empty(),
		"locked": "" if not characters.is_empty() else "Pessoas libera quando alguém da vila te pedir ajuda"})
	entries.append({"id": "timed", "text": "Diárias", "alert": not _ready_routines.is_empty(),
		"locked": "" if GameState.routines_unlocked("daily") else "Diárias liberam mais adiante na história"})
	# As abas só são recriadas quando algo visível muda; a bandeja não mexe de lugar nem a cada segundo.
	var sig := _group
	for entry: Dictionary in entries: sig += "|%s:%s:%s" % [entry.id, entry.alert, entry.get("locked", "")]
	if sig == _tabs_sig and _tabs != null and is_instance_valid(_tabs): return
	_tabs_sig = sig
	if _tabs != null and is_instance_valid(_tabs):
		_tabs_holder.remove_child(_tabs)
		_tabs.queue_free()
	_tabs = MissionUi.tabs(entries, _group, choose_group)
	_tabs_holder.add_child(_tabs)
	_place_tabs()

## A casca chama depois de trocar a tela, liberando o espaço dos anéis do Tiro.
func sync_hud() -> void:
	var host := get_tree().root.find_child("Main", true, false)
	if not host: return
	var hud := host.find_child("TopBar", true, false) as Hud
	if is_visible_in_tree(): hud.set_row2_right(null)


## "Pegar tudo" no topo da lista, à direita (fora do HUD: a bandeja não anda quando ele aparece).
func _add_claim_all(box: VBoxContainer) -> void:
	var count := _ready_routines.size() if _group == "timed" else (_ready_characters.size() if _group == "characters" else 0)
	if count < 2: return
	_claim_all = UiKit.small_go("Pegar tudo (%d)" % count, func() -> void:
		if _group == "timed": ProgressionUi.claim_routine_rows(_content, _ready_routines.duplicate())
		else: _claim_characters(_ready_characters.duplicate()))
	_claim_all.name = "ClaimAllRoutines" if _group == "timed" else "ClaimAllCharacters"
	_claim_all.size_flags_horizontal = Control.SIZE_SHRINK_END
	box.add_child(_claim_all)

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
		# Aberta, o Pegar fica só dentro do detalhe (laranja); a linha mostra a setinha para recolher.
		var quick := ready and _line != line
		var action: Control
		if quick:
			# Pegar laranja (mesmo padrão do detalhe); STOP impede o toque de abrir o cartão da linha.
			action = MissionUi.button("go", "Pegar", func() -> void: _claim_characters([id]), 88.0)
			action.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			action = UiKit.row_chevron(choose_line.bind(line))
		action.name = "ClaimQuest_" + id if quick else "OpenLine_" + line
		# Linha sempre branca (o verde fica no Pegar e no n/n); o Pegar fica à direita, como nas Diárias.
		var row := UiKit.list_row(ProgressionUi.npc_portrait(str(quest.npc)), str(quest.name), [meta], action, choose_line.bind(line), false)
		row.name = "LineCard_" + line
		row.set_meta("quest", id)
		var top := row.get_child(0).get_child(0) as HBoxContainer
		_compact_name(top)
		# Nomes de missão de pessoa são longos: quebram em até duas linhas em vez de cortar.
		for node: Node in top.find_children("*", "Label", true, false):
			var title := node as Label
			if title.theme_type_variation == &"":
				title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				title.max_lines_visible = 2
				title.clip_text = false
				title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var face := top.get_child(0) as PanelContainer
		(face.get_child(0) as TextureRect).custom_minimum_size = Vector2(44, 44)
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
			if disc:
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
	var pill := MissionUi.chapter_pill("História" if finished else str(GameState.current_chapter().get("name", "História")), roundf((_screen_width() - 2.0 * STORY_EDGE) * 0.86))
	card.add_child(pill)
	if finished:
		_story_done(card)
		return
	if displayed != "":
		var shared := str(Database.quests[current].get("shared_with", "")) != ""
		card.add_child(_story_hero(displayed))
		if shared:
			var guidance := MissionUi.text("A história segue com " + str(Database.npcs.get(str(Database.quests[displayed].npc), {}).get("name", "")), 13, Palette.WOOD_CREAM, 3)
			guidance.name = "SharedQuestGuidance"
			guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_child(guidance)
		_story_rewards(card, displayed)
		_story_steps(card, displayed)
	var full := MissionUi.link("História completa ›", func() -> void: MissionUi.story_book())
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
	var full := MissionUi.link("História completa ›", func() -> void: MissionUi.story_book())
	full.name = "StoryFull"
	card.add_child(full)


## Cartão do topo: retrato 84×84, e à direita (mesma borda) título, fala (até 2 linhas) e a barra do capítulo.
func _story_hero(id: String) -> Control:
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
	MissionUi.tap_full_text(speech)
	info.add_child(speech)
	# Barra = progresso desta missão: cada passo pesa igual e conta a parte já feita (ex.: 3 de 5 cenouras).
	var goals: Array = quest.get("goals", [])
	var share := 0.0
	var met := 0
	var value := 0
	var target := 1
	for goal: Dictionary in goals:
		target = maxi(1, int(goal.get("target", 1)))
		value = mini(GameState.goal_value(goal), target)
		share += float(value) / target
		if value >= target: met += 1
	var claimed := GameState.progress.claimed_quests.has(id)
	var fraction := 1.0 if claimed or goals.is_empty() else share / goals.size()
	var caption := "%d/%d" % [value, target] if goals.size() == 1 else "%d/%d" % [met, goals.size()]
	var bar := MissionUi.bar(fraction, caption)
	bar.name = "StoryBar"
	info.add_child(bar)
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
	var room := (_screen_width() - 2.0 * STORY_EDGE) - 24.0 - MissionUi.BUTTON.x - 8.0
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
	# Passos por fazer primeiro, concluídos embaixo (o nome do nó mantém o índice original do objetivo).
	var order: Array[int] = []
	var finished: Array[int] = []
	for i in quest.goals.size():
		var check_goal: Dictionary = quest.goals[i]
		if GameState.goal_value(check_goal) >= int(check_goal.get("target", 1)): finished.append(i)
		else: order.append(i)
	order.append_array(finished)
	for i: int in order:
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


## Detalhe aberto dentro da linha da pessoa, com as peças da Principal em tamanho compacto: um passo por linha
## (quadradinho do ícone, instrução, pílula n/m e Ir laranja ou "Concluído"; por fazer primeiro) e, embaixo,
## os prêmios em quadradinhos com o Pegar laranja (apagado enquanto falta algo).
func _quest_detail(box: VBoxContainer, id: String) -> void:
	var quest: Dictionary = Database.quests[id]
	var order: Array[int] = []
	var finished: Array[int] = []
	for i in quest.goals.size():
		var check_goal: Dictionary = quest.goals[i]
		if GameState.goal_value(check_goal) >= int(check_goal.get("target", 1)): finished.append(i)
		else: order.append(i)
	order.append_array(finished)
	var first_open := true
	for i: int in order:
		var goal: Dictionary = quest.goals[i]
		var target := int(goal.get("target", 1))
		var value := mini(GameState.goal_value(goal), target)
		var complete := value >= target
		var row := UiKit.hbox(8)
		row.name = "PersonGoal_%d" % i
		row.add_child(MissionUi.tile(ProgressionUi.goal_icon(goal), "", "", Vector2(44, 44)))
		var info := UiKit.vbox(4)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(info)
		var words := MissionUi.text(str(goal.get("label", "")), 13, Palette.WOOD_INK, 0, HORIZONTAL_ALIGNMENT_LEFT)
		words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		words.max_lines_visible = 2
		words.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		MissionUi.tap_full_text(words)
		info.add_child(words)
		# Coluna da direita (88 px): pílula n/m em cima e, embaixo, o Ir ou o "Concluído".
		var column := UiKit.vbox(4)
		column.custom_minimum_size = Vector2(88, 0)
		column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(column)
		var count := MissionUi.pill("green" if complete else "brown", "%d/%d" % [value, target], "", Vector2(88, 22))
		column.add_child(count)
		if complete:
			var done_box := MissionUi.done_status()
			done_box.custom_minimum_size = Vector2(88, 28)
			column.add_child(done_box)
		else:
			var place := Places.goal_target(goal)
			var go := MissionUi.button("go", "Ir" if not place.is_empty() else "Como fazer", func() -> void:
				if place.is_empty(): TaskHelp.open("quest", id)
				else: Places.go(place), 88.0, 16 if not place.is_empty() else 11)
			go.name = ("QuestGo_" + id) if first_open else "GoalGo_%d" % i
			go.mouse_filter = Control.MOUSE_FILTER_STOP  # o toque não sobe para a linha (senão ela fecha antes do Ir)
			first_open = false
			column.add_child(go)
		box.add_child(row)
	# Prêmios e o Pegar, na mesma coluna de 88 px dos Ir.
	var bottom := UiKit.hbox(8)
	bottom.name = "PersonRewards"
	var prizes := UiKit.hbox(6)
	prizes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prizes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bottom.add_child(prizes)
	var gains: Dictionary = quest.rewards
	if int(gains.get("coins", 0)) > 0:
		prizes.add_child(MissionUi.tile(UiKit.ui_icon("coin"), "+%d" % int(gains.coins), "Prize_coins", Vector2(44, 44)))
	for item: String in gains.get("items", {}):
		prizes.add_child(MissionUi.tile(Database.item_icon(item), "+%d" % int(gains.items[item]), "Prize_" + item, Vector2(44, 44)))
	var ready := GameState.quest_error(id) == ""
	var claim := MissionUi.button("go", "Pegar", func() -> void: _claim_characters([id]), 88.0)
	claim.name = "DetailClaim_" + id
	claim.mouse_filter = Control.MOUSE_FILTER_STOP
	claim.disabled = not ready
	if claim.disabled:
		claim.get_node("Frame").modulate = Color(0.48, 0.48, 0.48, 0.65)
		claim.add_theme_color_override("font_disabled_color", Palette.WOOD_CREAM.darkened(0.28))
	bottom.add_child(claim)
	box.add_child(bottom)


func _routines(box: VBoxContainer, kind: String) -> void:
	if not GameState.routines_unlocked(kind): return
	var section := UiKit.vbox(8)
	section.name = "Routines_" + kind
	box.add_child(section)
	section.add_child(MissionUi.section_pill("Hoje" if kind == "daily" else "Esta semana", TimeText.short(GameState.routine_seconds_left(kind)), "RoutineHeader_" + kind))
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
		var row := UiKit.list_row(null, str(data.name), [UiKit.short_label("%d/%d" % [value, target], &"SmallLabel", Palette.GO_INK if ready else Palette.INK_SOFT)], action, choose_routine_detail.bind(kind, id), false)
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
			MissionUi.tap_full_text(title)


## A casca avisa quando a linha 2 do HUD esvazia ou enche; esta tela ignora: o topo é sempre logo abaixo do HUD
## completo, para a moldura e a bandeja não andarem ao trocar de aba ou ao aparecer o "Pegar tudo".
func set_content_top(_top: float) -> void:
	pass
