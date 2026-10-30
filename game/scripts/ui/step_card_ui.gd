class_name StepCardUi
extends RefCounted
## Mini-cartão do próximo passo da história no visual "madeira ilustrada" (abre ao tocar no `NextStep`): moldura de
## madeira com miolo creme, retrato + fala, uma linha por objetivo (nome, ícone e barra com "n/m" ou medalhão de
## feito), prêmios, "?" de madeira e o grande "Ir" verde. As imagens ficam em `assets/sprites/ui/home/step_*.png`
## (geradas por `tools/step_card_art.gd`, ~3x o tamanho final: os NinePatch usam escala 1/3, então moram sempre num
## Control comum, nunca direto num container). Estático: dá para montar sem a casca.

const WIDTH := 320.0
const EDGE := 8.0
## Sulco da barra no arquivo do trilho (pixels guardados, 3x): recuo e altura, impressos por `step_card_art.gd`.
const GROOVE_INSET := 16.5
const GROOVE_Y := 16.5
const TRACK_H := 66.0
const FILL_H := 27.0
const BAR_CAP := 33.0

const GO_HEIGHT := 44.0
const HELP_SIZE := 44.0


static func tex(file: String) -> Texture2D:
	return load(HomeUi.DIR + "step_" + file + ".png") as Texture2D


static func stretch(node: Control) -> void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Imagem estática ilustrada (suave) que não pega o toque.
static func pic(file: String, px: Vector2, node_name: String = "") -> TextureRect:
	var result := TextureRect.new()
	result.texture = tex(file)
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_SCALE
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.custom_minimum_size = px
	if node_name != "":
		result.name = node_name
	return result


## NinePatch em escala 1/3 (margens esquerda/direita em pixels guardados). `scale_factor` encolhe ainda mais.
static func patch(file: String, margin_x: int, margin_y: int = 0) -> NinePatchRect:
	var result := NinePatchRect.new()
	result.texture = tex(file)
	result.patch_margin_left = margin_x
	result.patch_margin_right = margin_x
	result.patch_margin_top = margin_y
	result.patch_margin_bottom = margin_y
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func wood(value: String, px: int, color: Color = Palette.WOOD_INK) -> Label:
	var result := Label.new()
	result.text = value
	result.theme = HomeUi.theme(px, color)
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## Largura do cartão: 320, ou o que couber na tela deixando a folga do Popover.
static func card_width() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	return minf(WIDTH, tree.root.get_visible_rect().size.x - EDGE * 2.0)


## Cartão inteiro de uma missão: devolve o `StepCard` (PanelContainer) já com `popover_bare`.
static func build(id: String) -> Control:
	var quest: Dictionary = Database.quests[id]
	var goals: Array = quest.goals
	var compact := goals.size() >= 3
	var width := card_width()
	var root := PanelContainer.new()
	root.name = "StepCard"
	root.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.mouse_filter = Control.MOUSE_FILTER_STOP  # o toque no cartão não fecha o balão
	root.custom_minimum_size.x = width
	root.set_meta("popover_bare", true)

	var art := Control.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(art)
	var frame := patch("frame", 42, 42)
	frame.name = "Frame"
	frame.scale = Vector2.ONE / 3.0
	art.add_child(frame)
	var fit := func() -> void:
		frame.position = Vector2.ZERO
		frame.size = art.size.max(Vector2.ONE) * 3.0
	art.resized.connect(fit)
	fit.call()
	# Brilhos dourados no canto de cima à direita (só enfeite).
	var big := pic("sparkle", Vector2(24, 28), "StepSparkle")
	big.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	big.offset_left = -34.0
	big.offset_right = -10.0
	big.offset_top = -9.0
	big.offset_bottom = 19.0
	art.add_child(big)
	var small := pic("sparkle_small", Vector2(14, 15), "StepSparkleSmall")
	small.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	small.offset_left = -52.0
	small.offset_right = -38.0
	small.offset_top = 3.0
	small.offset_bottom = 18.0
	art.add_child(small)

	var inner := MarginContainer.new()
	inner.name = "Body"
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		inner.add_theme_constant_override("margin_" + side, 20)
	inner.add_theme_constant_override("margin_top", 17)
	inner.add_theme_constant_override("margin_bottom", 19)
	root.add_child(inner)
	var box := UiKit.vbox(9)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(box)

	box.add_child(_head(quest))

	var rows := goal_list(id)
	var viewport_h := (Engine.get_main_loop() as SceneTree).root.get_visible_rect().size.y
	var budget := viewport_h * 0.6 - 190.0
	var estimate := goals.size() * (50.0 if compact else 64.0)
	if estimate > budget:
		var scroll := ScrollContainer.new()
		scroll.name = "StepGoalsScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size.y = maxf(budget, 120.0)
		scroll.add_child(rows)
		rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(scroll)
	else:
		box.add_child(rows)

	var prizes := reward_row(quest.get("rewards", {}))
	if prizes != null:
		box.add_child(prizes)
	box.add_child(action_row(id, "step"))
	return root


## Cabeçalho: quadradinho bege com o retrato e a fala (até 3 linhas; cortada, toque mostra inteira).
static func _head(quest: Dictionary) -> Control:
	var head := UiKit.hbox(10)
	head.name = "StepHead"
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face := MissionUi.tile(null, "", "StepFace", Vector2(52, 52))
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var picture := TextureRect.new()
	picture.name = "Portrait"
	picture.texture = ProgressionUi.npc_portrait(str(quest.get("npc", "")))
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(picture)
	stretch(picture)
	picture.offset_left = 5.0
	picture.offset_top = 5.0
	picture.offset_right = -5.0
	picture.offset_bottom = -5.0
	head.add_child(face)
	var speech := wood(str(quest.get("dialogue", quest.get("name", ""))), 14)
	speech.name = "StepSpeech"
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.max_lines_visible = 3
	speech.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	speech.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speech.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	speech.custom_minimum_size = Vector2(120, 0)
	MissionUi.tap_full_text(speech)
	head.add_child(speech)
	return head


## Uma linha por objetivo: [ícone] nome / [barra de madeira] n/m (ou medalhão de feito).
static func goal_row(id: String, quest: Dictionary, index: int, is_next: bool, compact: bool) -> Control:
	var goal: Dictionary = (quest.goals as Array)[index]
	var target := maxi(1, int(goal.get("target", 1)))
	var value := GameState.goal_value(goal)
	var done := value >= target
	var icon_px := 22 if compact else 26
	var text_px := 13 if compact else 14
	var row := PanelContainer.new()
	row.name = "StepGoal_%d" % index
	row.custom_minimum_size.y = 44.0
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var style: StyleBox
	if is_next:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(1.0, 0.8, 0.38, 0.34)
		flat.set_corner_radius_all(11)
		style = flat
		row.set_meta("go_goal", true)
	else:
		style = StyleBoxEmpty.new()
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	row.add_theme_stylebox_override("panel", style)

	var column := UiKit.vbox(2 if compact else 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(column)
	var top := UiKit.hbox(6)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := UiKit.icon(ProgressionUi.goal_icon(goal), icon_px)
	icon.name = "StepGoalIcon_%d" % index
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(icon)
	var caption := str(goal.get("label", quest.get("name", "")))
	var name_label := wood(caption, text_px, Color(Palette.WOOD_INK, 0.62) if done else Palette.WOOD_INK)
	name_label.name = "StepGoalName_%d" % index
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.custom_minimum_size.x = 100.0
	top.add_child(name_label)
	column.add_child(top)

	var low := UiKit.hbox(6)
	low.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low.add_child(bar(float(mini(value, target)) / target, 20.0 if compact else 24.0))
	var slot := Control.new()
	slot.name = "StepGoalSlot_%d" % index
	slot.custom_minimum_size = Vector2(44, 0)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if done:
		var medal := pic("done", Vector2(26, 26) if compact else Vector2(30, 30), "StepGoalDone_%d" % index)
		slot.add_child(medal)
		medal.set_anchors_preset(Control.PRESET_CENTER)
		medal.offset_left = -medal.custom_minimum_size.x / 2.0
		medal.offset_right = medal.custom_minimum_size.x / 2.0
		medal.offset_top = -medal.custom_minimum_size.y / 2.0
		medal.offset_bottom = medal.custom_minimum_size.y / 2.0
	else:
		var count := wood("%d/%d" % [value, target], text_px + 1)
		count.name = "StepGoalCount_%d" % index
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.add_child(count)
		stretch(count)
	low.add_child(slot)
	column.add_child(low)

	if not done:
		# Toque no objetivo pendente: vai direto ao lugar dele.
		var tap := BagUi.plain_button(func() -> void:
			NextStep._close_popover()
			Places.go(Places.goal_target(goal)))
		tap.name = "StepGoalGo_%d" % index
		tap.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(tap)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return row


## Barra de madeira de `height` px finais com sulco marrom e preenchimento verde (`fraction` 0..1). Expande na largura.
static func bar(fraction: float, height: float = 24.0, node_name: String = "StepBar") -> Control:
	var meter := Control.new()
	meter.name = node_name
	meter.custom_minimum_size = Vector2(60, height)
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track := patch("bar_track", int(BAR_CAP))
	track.name = "Track"
	meter.add_child(track)
	var fill := patch("bar_fill", 13)
	fill.name = "Fill"
	meter.add_child(fill)
	var amount := clampf(fraction, 0.0, 1.0)
	var fit := func() -> void:
		if meter.size.y <= 0.0 or meter.size.x <= 0.0:
			return
		var scale_factor := meter.size.y / TRACK_H
		var wide := meter.size.x / scale_factor
		track.scale = Vector2.ONE * scale_factor
		track.position = Vector2.ZERO
		track.size = Vector2(wide, TRACK_H)
		var room := wide - GROOVE_INSET * 2.0
		fill.scale = Vector2.ONE * scale_factor
		fill.position = Vector2(GROOVE_INSET, GROOVE_Y) * scale_factor
		fill.visible = amount > 0.0
		fill.size = Vector2(maxf(room * amount, FILL_H), FILL_H)
	meter.resized.connect(fit)
	fit.call()
	return meter


## Prêmios: [ícone] +N em fila (moedas com a estrela de ouro). Nulo se a missão não paga nada.
static func reward_row(rewards: Dictionary) -> Control:
	var chips: Array[Control] = []
	if int(rewards.get("coins", 0)) > 0:
		chips.append(_prize(tex("coin"), "+%d" % int(rewards.coins), false))
	for item: String in rewards.get("items", {}):
		var label := "+%d" % int(rewards.items[item])
		if Database.items.get(item, {}).get("category", "") == "keepsake":
			label += " " + Database.item_name(item)
		chips.append(_prize(Database.item_icon(item), label, true))
	for collection: String in rewards.get("collections", []):
		if not GameState.progress.collection.has(collection):
			chips.append(_prize(UiKit.ui_icon("item_accessory_set"), "+1", true))
	if chips.is_empty():
		return null
	var row := HFlowContainer.new()
	row.name = "StepRewards"
	row.add_theme_constant_override("h_separation", 14)
	row.add_theme_constant_override("v_separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for chip in chips:
		row.add_child(chip)
	return row


static func _prize(icon: Texture2D, value: String, pixel: bool) -> Control:
	var chip := UiKit.hbox(5)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := TextureRect.new()
	picture.texture = icon
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(24, 24)
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	chip.add_child(picture)
	chip.add_child(wood(value, 16))
	return chip


## Objetivos da missão em linhas (compactas com 3+). O primeiro pendente leva o destaque (é para onde o "Ir" vai).
static func goal_list(id: String) -> VBoxContainer:
	var quest: Dictionary = Database.quests[id]
	var goals: Array = quest.goals
	var compact := goals.size() >= 3
	var first_pending := -1
	for i in goals.size():
		if GameState.goal_value(goals[i]) < int((goals[i] as Dictionary).get("target", 1)):
			first_pending = i
			break
	var rows := UiKit.vbox(4 if compact else 6)
	rows.name = "StepGoals"
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in goals.size():
		rows.add_child(goal_row(id, quest, i, i == first_pending, compact))
	return rows


## "?" de madeira (alvo 44, desenho 40).
static func help_button(on_pressed: Callable) -> Button:
	var help := BagUi.plain_button(on_pressed)
	help.custom_minimum_size = Vector2(HELP_SIZE, HELP_SIZE)
	help.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	help.pressed.connect(func() -> void: Motion.bounce(help))
	var disc := pic("help", Vector2(40, 40), "Disc")
	help.add_child(disc)
	disc.set_anchors_preset(Control.PRESET_CENTER)
	disc.offset_left = -20.0
	disc.offset_right = 20.0
	disc.offset_top = -20.0
	disc.offset_bottom = 20.0
	return help


## Rodapé: "?" de madeira e o grande botão verde. `mode` "step" (mini-cartão: Ir ou Liberar espaço, nomes `StepCard*`) ou
## "npc" (conversa: Pegar quando pronta, Ir ou Liberar espaço, nomes `ClaimQuest_`/`QuestGo_`/`QuestSpace_<id>`).
## O destino do Ir é sempre o do primeiro objetivo pendente (`Places.quest_target`).
static func action_row(id: String, mode: String = "step") -> Control:
	var actions := UiKit.hbox(8)
	actions.name = "StepActions"
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var help := help_button(func() -> void:
		NextStep._close_popover()
		TaskHelp.open("quest", id))
	help.name = "StepCardHelp" if mode == "step" else "QuestHelp_" + id
	actions.add_child(help)
	var shortage := GameState.quest_reward_shortage(id)
	var ready := mode == "npc" and GameState.quest_error(id) == ""
	var go: Button
	if not shortage.is_empty():
		var depot_icon := UiKit.ui_icon(str(Database.progression.storage.get(str(shortage.depot), {}).get("icon", "tab_bag")))
		go = go_button("Liberar espaço", func() -> void:
			NextStep._close_popover()
			Places.go({"storage": str(shortage.depot)}), depot_icon if mode == "npc" else null)
		go.name = "StepCardSpace" if mode == "step" else "QuestSpace_" + id
	elif ready:
		go = go_button("Pegar", func() -> void:
			ProgressionUi.claim_quest_fx(id, actions.get_global_rect().get_center()))
		go.name = "ClaimQuest_" + id
	else:
		go = go_button("Ir", func() -> void:
			NextStep._close_popover()
			Places.go(Places.quest_target(id)))
		go.name = "StepCardGo" if mode == "step" else "QuestGo_" + id
	actions.add_child(go)
	return actions


## Cartão de papel interno (o `mission_card` creme com borda cobre) dentro de `parent`; devolve o VBox do conteúdo.
static func inner_card(parent: Control, node_name: String = "", pad: Vector4i = Vector4i(14, 12, 14, 12)) -> VBoxContainer:
	var card := MissionUi.card("card", pad, node_name, 10)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var box := UiKit.vbox(8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	MissionUi.body(card).add_child(box)
	return box


## Medalhão verde de "feito".
static func done_medal(px: float, node_name: String = "StepDone") -> TextureRect:
	return pic("done", Vector2(px, px), node_name)


## Retrato dentro da moldura de madeira do `MissionUi.portrait`: `face` é o TextureRect que mostra a imagem
## (pode ser o `NpcPortrait` animado); ele troca o `Face` padrão e recebe o nome `face_name` se vier.
static func portrait_frame(face: TextureRect, px: float, face_name: String = "") -> Control:
	var frame := MissionUi.portrait(null, px)
	var old := frame.find_child("Face", true, false)
	var window := old.get_parent() as Control
	window.remove_child(old)
	old.free()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.custom_minimum_size = Vector2.ZERO
	if face_name != "":
		face.name = face_name
	window.add_child(face)
	stretch(face)
	return frame


## Aviso de bloqueio na madeira: cadeado, motivo na fonte da madeira e "?" (nó `LockHint`, como o `UiKit.lock_hint`).
static func lock_note(text: String, on_help: Callable = Callable(), missing: Texture2D = null) -> HBoxContainer:
	var row := UiKit.hbox(8)
	row.name = "LockHint"
	var lock := UiKit.ctl("lock", 20, Palette.WOOD_INK)
	lock.name = "LockIcon"
	row.add_child(lock)
	if missing:
		var picture := UiKit.icon(missing, 26)
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(picture)
	var label := wood(text, 15)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 80.0
	row.add_child(label)
	if on_help.is_valid():
		row.add_child(help_button(on_help))
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				on_help.call())
	return row


## Pílula de madeira com ícone + texto; `tap` (opcional) a torna tocável (ex.: ingrediente que mostra de onde vem).
## `tone`: "have" (verde), "missing" (vermelho) ou "" (marrom).
static func wood_chip(icon: Texture2D, value: String, tone: String = "", tap: Callable = Callable(), node_name: String = "") -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.WOOD_INSET
	style.border_color = Color("c9935f")
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.content_margin_left = 8.0
	style.content_margin_right = 10.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.y = 32.0
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.mouse_filter = Control.MOUSE_FILTER_PASS if tap.is_valid() else Control.MOUSE_FILTER_IGNORE
	if node_name != "":
		panel.name = node_name
	var row := UiKit.hbox(5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon != null:
		var picture := UiKit.icon(icon, 24)
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(picture)
	var ink := Palette.WOOD_INK
	if tone == "have":
		ink = Palette.GO_INK
	elif tone == "missing":
		ink = Palette.ALERT_INK
	var label := wood(value, 15, ink)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(label)
	panel.add_child(row)
	if tap.is_valid():
		panel.gui_input.connect(func(event: InputEvent) -> void:
			var click := event as InputEventMouseButton
			if click and not click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
				tap.call())
	return panel


## Botão verde brilhante (alvo 44, desenho 40): rótulo creme com contorno escuro na fonte da madeira.
static func go_button(caption: String, on_pressed: Callable, icon: Texture2D = null) -> Button:
	var result := BagUi.plain_button(on_pressed)
	result.custom_minimum_size = Vector2(0, GO_HEIGHT)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	result.pressed.connect(func() -> void: Motion.bounce(result))
	var art := Control.new()
	art.name = "Art"
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.show_behind_parent = true
	result.add_child(art)
	stretch(art)
	var frame := patch("go", 60, 0)
	frame.name = "Frame"
	frame.scale = Vector2.ONE / 3.0
	art.add_child(frame)
	var fit := func() -> void:
		var drawn := 40.0
		frame.position = Vector2(0.0, (art.size.y - drawn) / 2.0)
		frame.size = Vector2(art.size.x, drawn) * 3.0
	art.resized.connect(fit)
	fit.call()
	result.theme = HomeUi.theme(19, Palette.WOOD_CREAM, Palette.WOOD_INK, 4)
	if icon == null:
		result.text = caption
		result.clip_text = true
		return result
	# Com ícone (moeda do preço): ícone + texto centralizados juntos no miolo verde, nunca encostados na borda.
	result.set_meta("caption", caption)
	var row := UiKit.hbox(6)
	row.name = "GoContent"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_child(row)
	stretch(row)
	var picture := UiKit.icon(icon, 24)
	picture.name = "GoIcon"
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if icon.get_width() > 48:
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # moeda ilustrada reduzida: suave
	row.add_child(picture)
	var label := MissionUi.text(caption, 19, Palette.WOOD_CREAM, 4)
	label.name = "GoText"
	row.add_child(label)
	return result
