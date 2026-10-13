class_name ProgressionUi
extends RefCounted
## Painéis da progressão, abertos pelos lugares dos mundos (Places) e pelas Missões:
## personagem (missões), construir por mundo, vender, encomendas, rotas, atributos e coleção.
## Conteúdo, requisitos e recompensas vêm dos JSON; ações passam pelo GameState.


# --- Personagens e missões ------------------------------------------------------

## Personagem: saudação, missões ativas e atalhos para os lugares dele ("services").
static func npc_view(npc_id: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var npc: Dictionary = Database.npcs.get(npc_id, {})
		npc_header(box, npc_id)
		_text(box, npc.get("greeting", ""), true)
		var active := 0
		var done := 0
		for id: String in Database.quests:
			if Database.quests[id].npc != npc_id:
				continue
			if GameState.progress.claimed_quests.has(id):
				done += 1
			elif GameState.quest_unlocked(id):
				active += 1
				quest_card(box, id)
		if active == 0:
			_text(box, "Nenhuma missão agora. Continue sua jornada que logo aparece outra!", true)
		if done > 0:
			_text(box, "%d missão(ões) concluída(s) com %s." % [done, npc.get("name", "")], true)
		var world_id := Database.npc_world(npc_id)
		var services: Array = npc.get("services", [])
		if not services.is_empty():
			box.add_child(UiKit.label("Posso ajudar com:", &"SectionLabel"))
			for place_id: String in services:
				var place: Dictionary = Database.worlds[world_id].places.get(place_id, {})
				box.add_child(UiKit.button(place.get("name", place_id), Places.open.bind(world_id, place_id), &"", UiKit.ui_icon(place.get("icon", ""))))
	)


static func npc_portrait(npc_id: String) -> Texture2D:
	var npc: Dictionary = Database.npcs.get(npc_id, {})
	if npc.get("portrait", "") != "" and ResourceLoader.exists(npc.portrait):
		return load(npc.portrait)
	return UiKit.ui_icon(npc.get("icon", "xp"))


static func npc_header(box: VBoxContainer, npc_id: String) -> void:
	var npc: Dictionary = Database.npcs.get(npc_id, {})
	var row := UiKit.hbox(10)
	row.add_child(UiKit.icon(npc_portrait(npc_id), 64))
	var info := UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(npc.get("name", npc_id), &"SectionLabel"))
	info.add_child(UiKit.label(npc.get("role", ""), &"SmallLabel"))
	row.add_child(info)
	box.add_child(row)


static func quest_card(box: VBoxContainer, id: String) -> void:
	var quest: Dictionary = Database.quests[id]
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.quest_error(id) == "" else &"CardPanel")
	card.add_child(UiKit.label(quest.name, &"SectionLabel"))
	for goal: Dictionary in quest.goals:
		card.add_child(goal_row(goal, GameState.goal_value(goal)))
	card.add_child(reward_chips(quest.rewards))
	quest_action(card, id)


# --- Construir --------------------------------------------------------------------

static func purchase(id: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void: upgrade_card(box, id))


static func upgrade_card(box: VBoxContainer, id: String) -> void:
	var data: Dictionary = Database.progression.upgrades[id]
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.upgrade_error(id) == "" else &"CardPanel")
	_title(card, data.get("icon", ""), data.name)
	_text(card, data.description, true)
	if GameState.has_upgrade(id):
		_text(card, "Adquirido!", true)
		var place := Database.place_with_panel("station:" + id)
		if place[0] != "":
			card.add_child(UiKit.button("Abrir " + Database.stations[id].name, Places.open.bind(place[0], place[1])))
		return
	var cost := UiKit.flow()
	cost.add_child(UiKit.chip(UiKit.ui_icon("coin"), "%d/%d" % [mini(GameState.coins, int(data.cost)), int(data.cost)], UiKit.GOOD if GameState.coins >= int(data.cost) else UiKit.BAD))
	card.add_child(cost)
	_amounts(card, data.get("materials", {}))
	_action(card, "Comprar", func() -> String: return GameState.buy_upgrade(id), GameState.upgrade_error(id), "%s é seu!" % data.name, TaskHelp.open.bind("upgrade", id))


# --- Vila: vender e encomendas --------------------------------------------------------

## Feira: abas Vender | Encomendas (`tab` = "sell" ou "orders").
static func market_panel(tab: String = "sell") -> Control:
	var box := UiKit.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	var tabs := UiKit.hbox(8)
	var holder := UiKit.vbox(0)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var buttons := {}
	var show_tab := func(id: String) -> void:
		for child in holder.get_children():
			child.queue_free()
		holder.add_child(sell_panel() if id == "sell" else orders_panel())
		for key: String in buttons:
			buttons[key].theme_type_variation = &"PrimaryButton" if key == id else &""
	for entry: Array in [["sell", "Vender", "coin"], ["orders", "Encomendas", "item_treat_box"]]:
		var button := UiKit.button(entry[1], show_tab.bind(entry[0]), &"", UiKit.ui_icon(entry[2]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons[entry[0]] = button
		tabs.add_child(button)
	box.add_child(tabs)
	box.add_child(holder)
	show_tab.call(tab if tab in ["sell", "orders"] else "sell")
	return box


static func sell_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var any := false
		for id: String in Database.items:
			var price := int(Database.items[id].get("sell_price", 0))
			var count := GameState.inventory.count(id)
			if price <= 0 or count == 0:
				continue
			any = true
			var row := UiKit.hbox(8)
			row.add_child(UiKit.icon(Database.item_icon(id), 40))
			row.add_child(UiKit.fill_label("x%d" % count))
			var sell := UiKit.button("+%d" % price, func() -> void:
				var error := GameState.sell(id)
				Events.toast_requested.emit(error if error != "" else "Vendeu %s!" % Database.item_name(id)), &"PrimaryButton", UiKit.ui_icon("coin"))
			sell.custom_minimum_size = Vector2(96, 48)
			row.add_child(sell)
			UiKit.card(box).add_child(row)
		if not any:
			_text(box, "Nada para vender.")
	)


static func orders_panel(focus: String = "") -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		for id: String in Database.progression.orders:
			if focus != "" and id != focus:
				continue
			var data: Dictionary = Database.progression.orders[id]
			var reason := GameState.order_error(id)
			var locked := GameState.requirement_error(data.get("requirements", {}))
			var card := UiKit.card(box, &"ReadyCardPanel" if reason == "" else &"CardPanel")
			card.add_child(UiKit.label(data.name, &"SectionLabel"))
			if locked != "":
				_action(card, "Bloqueada", func() -> String: return locked, locked, "", TaskHelp.open.bind("order", id))
				continue
			_amounts(card, data.inputs)
			card.add_child(reward_chips(data.rewards))
			_action(card, "Entregar", func() -> String: return GameState.fulfill_order(id), reason, "Encomenda entregue!", TaskHelp.open.bind("order", id))
	)


# --- Rotas (passeios, mina, pomar) ------------------------------------------------------

## Rotas de um ou mais grupos ("walk", "mine+walk", "orchard"). Só uma rota por vez em todo o jogo.
static func routes_panel(place: String, focus: String = "") -> Control:
	var groups := place.split("+")
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		active_activity(box)
		for id: String in Database.progression.activities:
			var data: Dictionary = Database.progression.activities[id]
			if not str(data.get("place", "walk")) in groups or (focus != "" and id != focus):
				continue
			var card := UiKit.card(box)
			_title(card, data.get("icon", ""), data.name)
			var details := UiKit.flow()
			details.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(data.seconds))))
			for item: String in data.rewards.get("items", {}):
				details.add_child(UiKit.chip(Database.item_icon(item), "+%d" % int(data.rewards.items[item]), UiKit.GOOD))
			if int(data.rewards.get("coins", 0)) > 0:
				details.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(data.rewards.coins), UiKit.GOOD))
			card.add_child(details)
			_action(card, "Começar", func() -> String: return GameState.start_activity(id), GameState.activity_error(id), "Vocês saíram para: " + data.name, TaskHelp.open.bind("route", id))
	)


## Cartão da rota em andamento (com "Recolher" quando termina).
static func active_activity(box: VBoxContainer) -> void:
	var activity: Dictionary = GameState.progress.activity
	if activity.is_empty():
		return
	var data: Dictionary = Database.progression.activities.get(activity.id, {})
	var remaining := GameState.activity_remaining()
	var card := UiKit.card(box, &"ReadyCardPanel")
	_title(card, data.get("icon", ""), data.get("name", ""))
	var duration := maxf(1.0, float(activity.ready_at) - float(activity.started_at))
	card.add_child(UiKit.bar(clampf(1.0 - remaining / duration, 0, 1) * 100, UiKit.GOOD))
	_text(card, "Voltaram! Recolha o que acharam." if remaining == 0 else "Em andamento · faltam " + TimeText.short(remaining))
	if remaining == 0:
		_action(card, "Recolher", func() -> String: return GameState.collect_activity(), "", "Recebeu: " + rewards_text(data.get("rewards", {})))


# --- Atributos e coleção --------------------------------------------------------------

static func skills_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		for id: String in Database.progression.skills:
			var data: Dictionary = Database.progression.skills[id]
			var info := GameState.skill_info(id)
			var card := UiKit.card(box)
			var top := UiKit.hbox(8)
			top.add_child(UiKit.icon(UiKit.ui_icon(data.icon), 40))
			top.add_child(UiKit.fill_label(data.name, &"SectionLabel"))
			top.add_child(UiKit.short_label("Nv %d" % int(info.level), &"SectionLabel"))
			card.add_child(top)
			var line := UiKit.hbox(6)
			var bar := UiKit.bar(100 if info.max else float(info.xp) / float(info.needed) * 100, Color(data.color), 12)
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(bar)
			line.add_child(UiKit.short_label("Máx." if info.max else "%d/%d" % [int(info.xp), int(info.needed)], &"SmallLabel"))
			card.add_child(line)
			var next := _next_milestone(id, int(info.level))
			if not next.is_empty():
				var unlock := UiKit.hbox(6)
				unlock.add_child(UiKit.short_label("Nv %d →" % int(next.level), &"SmallLabel"))
				unlock.add_child(UiKit.icon(next.icon, 32))
				unlock.add_child(UiKit.fill_label(next.name, &"SmallLabel"))
				card.add_child(unlock)
	)


## Próximo conteúdo que o atributo libera: { level, icon, name } (vazio se nada).
static func _next_milestone(skill_id: String, current: int) -> Dictionary:
	var best := {}
	for kind: String in ["activity", "crop", "recipe"]:
		var group: Dictionary = {"activity": Database.progression.activities, "crop": Database.crops, "recipe": Database.recipes}[kind]
		for content_id: String in group:
			var entry: Dictionary = group[content_id]
			var required := int(entry.get("requirements", {}).get("skills", {}).get(skill_id, 0))
			if required <= current or (not best.is_empty() and required >= int(best.level)):
				continue
			match kind:
				"activity":
					best = {"level": required, "icon": UiKit.ui_icon(entry.get("icon", "action_play")), "name": entry.name}
				"crop":
					best = {"level": required, "icon": Database.item_icon(content_id), "name": Database.item_name(content_id)}
				"recipe":
					best = {"level": required, "icon": Database.item_icon(entry.output), "name": Database.item_name(entry.output)}
	return best


static func collection_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		_text(box, "Roupas e apetrechos ganhos nas missões ficam guardados aqui.", true)
		for id: String in Database.collections:
			var data: Dictionary = Database.collections[id]
			var earned := GameState.progress.collection.has(id)
			var card := UiKit.card(box, &"ReadyCardPanel" if earned else &"CardPanel")
			_title(card, data.icon, data.name)
			_text(card, data.description, true)
			_text(card, "Conquistado!" if earned else "Recompensa de missão", true)
	)


# --- Peças ------------------------------------------------------------------------------

static func rewards_text(rewards: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(rewards.get("coins", 0)) > 0:
		parts.append("%d moedas" % int(rewards.coins))
	if not rewards.get("items", {}).is_empty():
		parts.append(Database.describe_amounts(rewards["items"]))
	for id: String in rewards.get("skill_xp", {}):
		parts.append("+%d XP %s" % [int(rewards.skill_xp[id]), Database.progression.skills[id].name])
	for id: String in rewards.get("collections", []):
		parts.append(Database.collections.get(id, {}).get("name", id))
	return " · ".join(parts)


## Linha de título de cartão: ícone (UiKit.ui_icon) + nome.
static func _title(card: VBoxContainer, icon_name: String, text: String) -> void:
	var row := UiKit.hbox()
	var texture := UiKit.ui_icon(icon_name) if icon_name != "" else null
	if texture:
		row.add_child(UiKit.icon(texture, 32))
	var title := UiKit.label(text, &"SectionLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	card.add_child(row)


static func _text(box: VBoxContainer, text: String, small: bool = false) -> void:
	if text != "":
		box.add_child(UiKit.label(text, &"SmallLabel" if small else &""))


## Botão de ação do GameState; toast com o resultado. Bloqueado: motivo curto embaixo e,
## se houver `help`, um "?" ao lado que abre o "Como fazer".
static func _action(box: VBoxContainer, text: String, action: Callable, reason: String = "", done: String = "Feito!", help: Callable = Callable()) -> void:
	var button := UiKit.button(text, func() -> void:
		var error: String = action.call()
		Events.toast_requested.emit(error if error != "" else done), &"PrimaryButton")
	button.disabled = reason != ""
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(8)
	row.add_child(button)
	if reason != "" and help.is_valid():
		row.add_child(UiKit.square_button("?", help))
	box.add_child(row)
	if reason != "":
		_text(box, reason, true)


## Chips "tem/precisa" com ícone de cada item (verde = suficiente).
static func _amounts(card: VBoxContainer, amounts: Dictionary) -> void:
	if amounts.is_empty():
		return
	var row := UiKit.flow()
	for id: String in amounts:
		var have := GameState.inventory.count(id)
		var need := int(amounts[id])
		row.add_child(item_chip(id, need))
	card.add_child(row)


## [Ir | Receber] + "?". O Ir leva ao primeiro passo possível (ex.: plantar antes de cozinhar).
static func quest_action(box: VBoxContainer, id: String) -> void:
	var ready := GameState.quest_error(id) == ""
	var row := UiKit.hbox(8)
	var main := UiKit.button("Receber" if ready else "Ir", func() -> void:
		if ready:
			var error := GameState.claim_quest(id)
			if error != "":
				Events.toast_requested.emit(error)
		else:
			Places.go(quest_go_target(id)), &"PrimaryButton")
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(main)
	if not ready:
		row.add_child(UiKit.square_button("?", TaskHelp.open.bind("quest", id)))
	box.add_child(row)


static func quest_go_target(id: String) -> Dictionary:
	var target: Dictionary = TaskHelp.describe("quest", id).get("next_target", {})
	return target if not target.is_empty() and not target.has("claim") else Places.quest_target(id)


## Objetivo que falta (ou o primeiro, se todos cumpridos).
static func current_goal(id: String) -> Dictionary:
	var goals: Array = Database.quests[id].goals
	for goal: Dictionary in goals:
		if GameState.goal_value(goal) < int(goal.get("target", 1)):
			return goal
	return goals[0]


## Diária ou semanal: [ícone] nome · barra · recompensa · [Ir | Receber].
static func routine_card(box: VBoxContainer, kind: String, id: String) -> void:
	var data := GameState.routine_data(kind, id)
	var goal: Dictionary = data.goal
	var target := int(goal.get("target", 1))
	var value := mini(GameState.routine_value(kind, id), target)
	var claimed := GameState.routine_claimed(kind, id)
	var ready := GameState.routine_error(kind, id) == ""
	var card := UiKit.card(box, &"ReadyCardPanel" if ready else &"CardPanel")
	if claimed:
		card.get_parent().modulate.a = 0.55
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(stat_icon(goal.key), 40))
	var info := UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(data.name))
	var line := UiKit.hbox(6)
	var bar := UiKit.bar(100.0 * value / maxi(1, target), UiKit.GOOD, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(bar)
	line.add_child(UiKit.short_label("%d/%d" % [value, target], &"SmallLabel"))
	info.add_child(line)
	info.add_child(reward_chips(data.get("rewards", {})))
	row.add_child(info)
	if claimed:
		row.add_child(UiKit.short_label("✓", &"SectionLabel", UiKit.GOOD))
	else:
		var button := UiKit.button("Receber" if ready else "Ir", func() -> void:
			if ready:
				var error := GameState.claim_routine(kind, id)
				Events.toast_requested.emit(error if error != "" else "Missão concluída!")
			else:
				Places.go(Places.goal_target({"type": "stat", "key": goal.key})), &"PrimaryButton")
		button.custom_minimum_size = Vector2(96, 48)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(button)
	card.add_child(row)


## História completa: capítulos passados (✓), o atual com os passos e os próximos apagados.
static func story_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var current := GameState.progress.chapter_index()
		for i in Database.progression.chapters.size():
			var chapter: Dictionary = Database.progression.chapters[i]
			var index: int = i + 1
			var card := UiKit.card(box, &"ReadyCardPanel" if index == current else &"CardPanel")
			if index > current:
				card.get_parent().modulate.a = 0.5
			var title := "%d · %s" % [index, chapter.name] if index <= current else "%d · ?" % index
			card.add_child(UiKit.label(("✓ " if index < current else "") + title, &"SectionLabel", UiKit.GOOD if index < current else null))
			if index == current:
				for id in GameState.progress.main_quests(index):
					var claimed := GameState.progress.claimed_quests.has(id)
					var row := UiKit.hbox(8)
					row.add_child(UiKit.icon(goal_icon(current_goal(id)), 32))
					row.add_child(UiKit.fill_label(Database.quests[id].name, &"SmallLabel", UiKit.GOOD if claimed else null))
					if claimed:
						row.add_child(UiKit.short_label("✓", &"", UiKit.GOOD))
					card.add_child(row)
			if index >= current:
				card.add_child(reward_chips(chapter.get("rewards", {})))
	)


# --- Peças visuais de missão ---------------------------------------------------------------

## Ícone de um objetivo pelo tipo: item, construção, atributo, moedas ou contador.
static func goal_icon(goal: Dictionary) -> Texture2D:
	var key: String = goal.get("key", "")
	match str(goal.get("type", "stat")):
		"owned":
			return UiKit.ui_icon(Database.progression.upgrades.get(key, {}).get("icon", "tab_house"))
		"skill":
			return UiKit.ui_icon(Database.progression.skills.get(key, {}).get("icon", "xp"))
		"have", "deliver":
			return Database.item_icon(key)
		"coins":
			return UiKit.ui_icon("coin")
		"chapter":
			return UiKit.ui_icon("tab_tasks")
	return stat_icon(key)


## Ícone de um contador ("harvest", "produce:plank", "activity:lane"...).
static func stat_icon(key: String) -> Texture2D:
	var prefix := key.get_slice(":", 0)
	var arg := key.get_slice(":", 1) if ":" in key else ""
	if arg != "" and prefix in ["harvest", "produce"]:
		return Database.item_icon(arg)
	if prefix == "activity":
		return UiKit.ui_icon(Database.progression.activities.get(arg, {}).get("icon", "action_play"))
	var icons := {"feed": "need_hunger", "bathe": "action_bathe", "play": "action_play", "pet": "need_happiness", "harvest": "tab_farm", "produce": "item_carrot_snack", "trade": "coin", "sold": "coin", "orders": "item_treat_box", "order": "item_treat_box", "explore": "tab_map", "quests": "tab_tasks", "build": "item_plank"}
	return UiKit.ui_icon(icons.get(prefix, "xp"))


## Linha de objetivo: ícone + barra + "3/6".
static func goal_row(goal: Dictionary, value: int, px: int = 32) -> HBoxContainer:
	var target := int(goal.get("target", 1))
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(goal_icon(goal), px))
	var bar := UiKit.bar(100.0 * mini(value, target) / maxi(1, target), UiKit.GOOD, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar)
	row.add_child(UiKit.short_label("%d/%d" % [mini(value, target), target], &"", UiKit.GOOD if value >= target else null))
	return row


## Recompensas em chips: [moeda] +40  [cenoura] +2  [atributo] +20  [roupa] +1.
static func reward_chips(rewards: Dictionary) -> HFlowContainer:
	var row := UiKit.flow()
	if int(rewards.get("coins", 0)) > 0:
		row.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(rewards.coins)))
	for id: String in rewards.get("items", {}):
		row.add_child(UiKit.chip(Database.item_icon(id), "+%d" % int(rewards.items[id])))
	for id: String in rewards.get("skill_xp", {}):
		if Database.progression.skills.has(id) and GameState.progress.skills_visible():
			row.add_child(UiKit.chip(UiKit.ui_icon(Database.progression.skills[id].get("icon", "xp")), "+%d" % int(rewards.skill_xp[id])))
	for id: String in rewards.get("collections", []):
		if not GameState.progress.collection.has(id):
			row.add_child(UiKit.chip(UiKit.ui_icon("item_accessory_set"), "+1"))
	return row


## Ingrediente: ícone + tem/precisa (verde/vermelho); tocar mostra de onde vem.
static func item_chip(id: String, need: int) -> Button:
	var have := GameState.inventory.count(id)
	return UiKit.tap_chip(Database.item_icon(id), "%d/%d" % [mini(have, need), need], TaskHelp.open.bind("item", id, need), UiKit.GOOD if have >= need else UiKit.BAD)
