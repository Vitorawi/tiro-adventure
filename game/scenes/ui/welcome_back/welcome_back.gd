class_name WelcomeBack
extends CanvasLayer
## Cartão "Que bom que você voltou!": presente do dia (um por dia jogado) e o que ficou pronto
## enquanto o jogador estava fora. Sem estado próprio: tudo vem do GameState.

const TIRO := "res://assets/sprites/characters/tiro_pet/tiro_pet_idle_front.png"


## Só vale a pena abrir se há presente para receber ou algo pronto (e a história já apresentou o jogo).
static func has_content() -> bool:
	if GameState.requirement_error(Database.progression.settings.get("welcome_requirements", {})) != "":
		return false
	return GameState.daily_gift_error() == "" or not GameState.welcome_ready_lines().is_empty()


func open() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.12, 0.08, 0.04, 0.72)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)
	var panel := PanelContainer.new()
	panel.theme = load("res://assets/theme/main_theme.tres")
	panel.theme_type_variation = &"ReadyCardPanel"
	panel.custom_minimum_size.x = 320
	center.add_child(panel)
	var box := UiKit.vbox(12)
	box.custom_minimum_size.x = 292
	panel.add_child(box)
	_fill(box)
	show()


func _fill(box: VBoxContainer) -> void:
	box.add_child(_center(PetAnimator.portrait()))
	box.add_child(_center(UiKit.label("Que bom que você voltou!", &"TitleLabel")))
	if GameState.daily_gift_error() == "":
		var gift := UiKit.card(box, &"CardPanel")
		var rewards := GameState.daily_gift_rewards()
		var chips := ProgressionUi.reward_chips(rewards)
		chips.alignment = FlowContainer.ALIGNMENT_CENTER
		gift.add_child(_center(UiKit.label("Presente do dia", &"SectionLabel")))
		gift.add_child(chips)
		gift.add_child(UiKit.button("Receber", func() -> void:
			var items: Dictionary = rewards.get("items", {})
			var coins := int(rewards.get("coins", 0))
			if GameState.claim_daily_gift() == "":
				Events.items_gained.emit(items, coins, Vector2(-1.0, -1.0))
			open(), &"PrimaryButton"))
	for line: Dictionary in GameState.welcome_ready_lines():
		var card := UiKit.card(box, &"CardPanel")
		var row := UiKit.hbox(10)
		var texture: Texture2D = Database.item_icon(str(line.icon)) if str(line.icon) != "" else UiKit.ui_icon("tab_map")
		if str(line.kind) == "dig":
			texture = UiKit.ui_icon("find_paw")
		elif str(line.kind) == "walk":
			texture = UiKit.ui_icon("action_walk")
		row.add_child(UiKit.icon(texture, 32))
		var count := UiKit.label("%d pronto%s" % [line.count, "s" if int(line.count) > 1 else ""], &"SectionLabel")
		if str(line.kind) == "dig":
			count.text = "1 achado · " + str(Database.worlds.get(str(line.world), {}).get("name", line.world))
		elif str(line.kind) == "walk":
			count.text = "Tiro voltou do passeio"
		count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(count)
		var target := {"world": line.world, "place": line.target}
		var go := UiKit.button("Ir", func() -> void:
			hide()
			Places.go(target), &"PrimaryButton")
		go.custom_minimum_size = Vector2(72, 48)
		row.add_child(go)
		card.add_child(row)
	box.add_child(UiKit.button("Vamos lá!", hide))


func _center(control: Control) -> Control:
	if control is Label:
		(control as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return control
