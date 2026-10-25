class_name WelcomeBack
extends CanvasLayer
## Cartão "Que bom que você voltou!": presente do dia (um por dia jogado, em destaque no topo) e o
## que ficou pronto enquanto o jogador estava fora, UMA linha por tipo (achados juntos, prontos
## por mundo, visita de amigo, passeio). Sem estado próprio: tudo vem do GameState.



## Só vale a pena abrir se há presente para receber ou algo pronto (e a história já apresentou o jogo).
static func has_content() -> bool:
	if GameState.requirement_error(Database.progression.settings.get("welcome_requirements", {})) != "":
		return false
	return GameState.daily_gift_error() == "" or not GameState.welcome_ready_lines().is_empty()


## `animate` falso reabre o cartão sem repetir a entrada (depois de pegar o presente).
func open(animate: bool = true) -> void:
	var has_gift := GameState.daily_gift_error() == ""
	var sheet := RewardSheet.open(self, {"title": "Que bom que você voltou!", "ribbon": Palette.HONEY, "ribbon_icon": "",
		"hero": PetAnimator.portrait(), "scroll_name": "WelcomeScroll", "animate": animate, "haptic": "", "on_close": _close})
	if has_gift:
		_gift_card(sheet, animate)
	for line: Dictionary in GameState.welcome_ready_lines():
		sheet.add(_line_row(line))
		if str(line.kind) == "growth" and not bool(line.get("sleeping", false)):
			GameState.mark_growth_ready_seen()
	if has_gift:
		sheet.add_actions("Depois", _close, "", Callable())
	else:
		sheet.add_actions("", Callable(), "Vamos lá!", _close)
	show()
	sheet.present()


func _close() -> void:
	hide()
	GameState.reveal_sleeping_growth()


## Presente do dia: cartão verde no topo, chips grandes e o único botão principal (Pegar).
func _gift_card(sheet: RewardSheet, animate: bool) -> void:
	var rewards := GameState.daily_gift_rewards()
	var gift := UiKit.card(sheet.body, &"ReadyCardPanel")
	gift.name = "DailyGift"
	var title := UiKit.label("Presente do dia", &"SectionLabel")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gift.add_child(title)
	var chips := ProgressionUi.reward_chips(rewards)
	chips.alignment = FlowContainer.ALIGNMENT_CENTER
	for chip: Node in chips.get_children():
		RewardSheet.grow_chip(chip as Control)
	gift.add_child(chips)
	if animate:
		RewardSheet.reveal_in(chips)
	gift.add_child(UiKit.primary("Pegar", func() -> void:
		var items: Dictionary = rewards.get("items", {})
		var coins := int(rewards.get("coins", 0))
		if GameState.claim_daily_gift() == "":
			Events.items_gained.emit(items, coins, Vector2(-1.0, -1.0))
		open(false)))


## Uma linha por tipo: [ícone] "3 achados" / "2 prontos no Sítio" / visita / passeio, com "Ir" (tocar na linha também).
func _line_row(line: Dictionary) -> Control:
	var kind := str(line.kind)
	var count := int(line.count)
	var world: Dictionary = Database.worlds.get(str(line.world), {})
	var texture: Texture2D = UiKit.ui_icon(str(world.get("icon", "tab_map")))
	var title := ""
	var chips: Array[Control] = []
	match kind:
		"growth":
			texture = UiKit.ui_icon("tab_pet")
			title = "Ele cresceu enquanto dormia!" if bool(line.get("sleeping", false)) else "Ele pode crescer!"
		"photo":
			texture = UiKit.ui_icon("album_story")
			title = "%d foto%s nova%s no álbum" % [count, "s" if count > 1 else "", "s" if count > 1 else ""]
		"dig":
			texture = UiKit.ui_icon("find_paw")
			title = "%d achado%s" % [count, "s" if count > 1 else ""]
			for world_id: String in line.get("worlds", []):
				chips.append(UiKit.icon(UiKit.ui_icon(str(Database.worlds.get(world_id, {}).get("icon", "tab_map"))), 32))
		"walk":
			texture = UiKit.ui_icon("action_walk")
			title = "Tiro voltou do passeio"
		"friend_visit":
			var friend: Dictionary = GameState.friend_def(str(line.friend))
			texture = UiKit.ui_icon(str(friend.icon))
			title = "%s passou aqui e deixou um presente!" % str(friend.name)
		_:
			title = "%d pronto%s %s" % [count, "s" if count > 1 else "", str(world.get("in_name", world.get("name", "")))]
			for id: String in line.get("icons", []):
				chips.append(UiKit.icon(Database.item_icon(id), 32))
	var target := {"world": line.world, "place": line.target}
	var go := func() -> void:
		hide()
		if kind == "photo":
			PetNotebook.open("album")
		elif kind == "growth":
			if bool(line.get("sleeping", false)): GameState.reveal_sleeping_growth()
			else: GrowthUi.open()
		elif kind == "friend_visit":
			Events.world_requested.emit("house", "look:" + str(line.target))
		else:
			Places.go(target)
	var button := UiKit.ctl_button("chev", go, 40, "sunken")
	var row := UiKit.list_row(texture, title, chips, button, go)
	row.name = "Line_" + kind + ("_" + str(line.world) if kind == "ready" else "")
	return row
