class_name ProgressionUi
extends RefCounted
## Painéis da Jornada. Conteúdo, requisitos e recompensas vêm dos JSON.

static func panel(page: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		match page:
			"skills":
				_skills(box)
			"quests":
				_quests(box)
			"shop":
				_shop(box)
			"routes":
				_routes(box)
			"market":
				_market(box)
			"production":
				_production(box)
			"collection":
				_collection(box)
			_:
				_today(box)
	)


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
	box.add_child(UiKit.label(text, &"SmallLabel" if small else &""))


static func _action(box: VBoxContainer, text: String, action: Callable, reason: String = "") -> void:
	var button := UiKit.button(text, func() -> void:
		var error: String = action.call()
		Events.toast_requested.emit(error if error != "" else "Concluído!"), &"PrimaryButton")
	button.disabled = reason != ""
	box.add_child(button)
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
		row.add_child(UiKit.chip(Database.item_icon(id), "%d/%d %s" % [have, need, Database.item_name(id)], UiKit.GOOD if have >= need else UiKit.BAD))
	card.add_child(row)


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


static func _today(box: VBoxContainer) -> void:
	var chapter := GameState.current_chapter()
	var card := UiKit.card(box, &"ReadyCardPanel")
	card.add_child(UiKit.label(chapter.name, &"SectionLabel"))
	_text(card, chapter.description)
	if chapter.target != "":
		card.add_child(UiKit.button("Próxima conquista", func() -> void:
			Events.sheet_requested.emit("Construir", purchase(chapter.target)), &"PrimaryButton"))
	_active_activity(box)
	var ready := GameState.ready_quest_count()
	if ready > 0:
		_text(box, "%d missão(ões) com recompensa pronta!" % ready)
		box.add_child(UiKit.button("Receber recompensas", func() -> void:
			Events.sheet_requested.emit("Missões", panel("quests")), &"PrimaryButton"))
	if not GameState.has_upgrade("farm"):
		var farm_card := UiKit.card(box)
		_text(farm_card, "Um canteiro da Bloblo é seu por empréstimo.")
		_text(farm_card, "Toque na aba Sítio, plante cenoura e colha para juntar moedas.", true)
	_text(box, "Cada descoberta vale XP em dobro no atributo da atividade.", true)
	box.add_child(UiKit.button("Abrir mochila", func() -> void:
		Events.sheet_requested.emit("Mochila", SheetBuilder.inventory_view())))
	box.add_child(UiKit.button("Pedir comida à Bloblo", func() -> void:
		var error := GameState.emergency_food()
		Events.toast_requested.emit(error if error != "" else "A Bloblo deixou comida para o Tiro!")))


static func _skills(box: VBoxContainer) -> void:
	for id: String in Database.progression.skills:
		var data: Dictionary = Database.progression.skills[id]
		var info := GameState.skill_info(id)
		var card := UiKit.card(box)
		_title(card, data.icon, "%s · %d" % [data.name, int(info.level)])
		_text(card, data.description, true)
		card.add_child(UiKit.bar(100 if info.max else float(info.xp) / float(info.needed) * 100, Color(data.color)))
		_text(card, "Nível máximo" if info.max else "%d / %d XP para o próximo nível" % [int(info.xp), int(info.needed)], true)
		var milestones: Array[Dictionary] = []
		for group: Dictionary in [Database.progression.upgrades, Database.progression.activities, Database.crops, Database.recipes]:
			for content_id: String in group:
				var entry: Dictionary = group[content_id]
				var required := int(entry.get("requirements", {}).get("skills", {}).get(id, 0))
				if required > int(info.level):
					milestones.append({"level": required, "name": entry.get("name", Database.item_name(entry.get("output", content_id)))})
		milestones.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.level) < int(b.level))
		for i in mini(2, milestones.size()):
			_text(card, "Nível %d → %s" % [milestones[i].level, milestones[i].name], true)


static func _npc_header(box: VBoxContainer, npc_id: String) -> void:
	var npc: Dictionary = Database.npcs[npc_id]
	var row := UiKit.hbox(10)
	var portrait: Texture2D = null
	if npc.get("portrait", "") != "" and ResourceLoader.exists(npc.portrait):
		portrait = load(npc.portrait)
	else:
		portrait = UiKit.ui_icon(npc.get("icon", "xp"))
	row.add_child(UiKit.icon(portrait, 48))
	var info := UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(npc.name, &"SectionLabel"))
	info.add_child(UiKit.label(npc.role, &"SmallLabel"))
	row.add_child(info)
	box.add_child(row)


static func _quests(box: VBoxContainer, npc_filter: String = "") -> void:
	_text(box, "Missões acompanham suas conquistas. Entregas consomem os itens indicados.", true)
	for npc_id: String in Database.npcs:
		if npc_filter != "" and npc_filter != npc_id:
			continue
		var card := UiKit.card(box)
		_npc_header(card, npc_id)
		_text(card, Database.npcs[npc_id].greeting, true)
		var active: int = 0
		var done: int = 0
		for id: String in Database.quests:
			var quest: Dictionary = Database.quests[id]
			if quest.npc != npc_id:
				continue
			if GameState.progress.claimed_quests.has(id):
				done += 1
				continue
			if not GameState.quest_unlocked(id):
				continue
			active += 1
			_quest_card(card, id)
		_text(card, "%d missão(ões) concluída(s)" % done, true)
		if active == 0:
			_text(card, "Continue sua jornada para novas histórias.", true)


static func npc_view(npc_id: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void: _quests(box, npc_id))


static func _quest_card(box: VBoxContainer, id: String) -> void:
	var quest: Dictionary = Database.quests[id]
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.quest_error(id) == "" else &"CardPanel")
	card.add_child(UiKit.label(quest.name, &"SectionLabel"))
	_text(card, quest.dialogue, true)
	for goal: Dictionary in quest.goals:
		var target := int(goal.get("target", 1))
		var value := mini(GameState.goal_value(goal), target)
		_text(card, "%s · %d/%d" % [goal.label, value, target], true)
		card.add_child(UiKit.bar(100.0 * value / maxi(1, target), UiKit.GOOD, 8))
	_text(card, "Recompensa: " + rewards_text(quest.rewards), true)
	_action(card, "Concluir missão", func() -> String: return GameState.claim_quest(id), GameState.quest_error(id))


static func purchase(id: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void: _upgrade_card(box, id))


static func _upgrade_card(box: VBoxContainer, id: String) -> void:
	var data: Dictionary = Database.progression.upgrades[id]
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.upgrade_error(id) == "" else &"CardPanel")
	_title(card, data.get("icon", ""), data.name)
	_text(card, data.description, true)
	if GameState.has_upgrade(id):
		_text(card, "Adquirido", true)
		if Database.stations.has(id):
			card.add_child(UiKit.button("Abrir " + Database.stations[id].name, func() -> void:
				Events.sheet_requested.emit(Database.stations[id].name, SheetBuilder.station_view(id))))
		return
	_text(card, "%d moedas · Você tem %d" % [int(data.cost), GameState.coins])
	_amounts(card, data.get("materials", {}))
	_action(card, "Comprar " + data.name, func() -> String: return GameState.buy_upgrade(id), GameState.upgrade_error(id))


static func _shop(box: VBoxContainer) -> void:
	_text(box, "Seu lar cresce com você. Cada compra libera novas possibilidades.", true)
	for id: String in Database.progression.upgrades:
		if not GameState.has_upgrade(id):
			_upgrade_card(box, id)
	_text(box, "Suas conquistas")
	for id: String in Database.progression.upgrades:
		if GameState.has_upgrade(id):
			_upgrade_card(box, id)


static func _active_activity(box: VBoxContainer) -> void:
	var activity: Dictionary = GameState.progress.activity
	if activity.is_empty():
		return
	var data: Dictionary = Database.progression.activities.get(activity.id, {})
	var remaining := GameState.activity_remaining()
	var card := UiKit.card(box, &"ReadyCardPanel")
	card.add_child(UiKit.label(data.name, &"SectionLabel"))
	var duration := maxf(1.0, float(activity.ready_at) - float(activity.started_at))
	card.add_child(UiKit.bar(clampf(1.0 - remaining / duration, 0, 1) * 100, UiKit.GOOD))
	_text(card, "Pronto para recolher!" if remaining == 0 else "Faltam " + SheetBuilder.format_time(remaining))
	_text(card, rewards_text(data.rewards), true)
	if remaining == 0:
		_action(card, "Recolher descobertas", func() -> String: return GameState.collect_activity())


static func _routes(box: VBoxContainer) -> void:
	_text(box, "Uma atividade por vez. O tempo continua passando com o jogo fechado.", true)
	_active_activity(box)
	for id: String in Database.progression.activities:
		var data: Dictionary = Database.progression.activities[id]
		var card := UiKit.card(box)
		_title(card, data.get("icon", ""), data.name)
		_text(card, data.description, true)
		_text(card, SheetBuilder.format_time(int(data.seconds)) + " · " + rewards_text(data.rewards), true)
		_action(card, "Começar", func() -> String: return GameState.start_activity(id), GameState.activity_error(id))


static func _market(box: VBoxContainer) -> void:
	_text(box, "Encomendas", false)
	for id: String in Database.progression.orders:
		var data: Dictionary = Database.progression.orders[id]
		var card := UiKit.card(box)
		card.add_child(UiKit.label(data.name, &"SectionLabel"))
		_amounts(card, data.inputs)
		_text(card, "Recebe: " + rewards_text(data.rewards), true)
		_action(card, "Entregar pedido", func() -> String: return GameState.fulfill_order(id), GameState.order_error(id))
	_text(box, "Venda direta")
	_text(box, "Guarde ingredientes para refeições, construções e missões.", true)
	for id: String in Database.items:
		var price := int(Database.items[id].get("sell_price", 0))
		var count := GameState.inventory.count(id)
		if price <= 0 or count == 0:
			continue
		var row := UiKit.hbox(8)
		row.add_child(UiKit.icon(Database.item_icon(id), 32))
		var info := UiKit.label("%s · x%d" % [Database.item_name(id), count])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var sell := UiKit.button("+%d" % price, func() -> void:
			var error := GameState.sell(id)
			Events.toast_requested.emit(error if error != "" else "Vendeu %s!" % Database.item_name(id)), &"PrimaryButton", UiKit.ui_icon("coin"))
		sell.custom_minimum_size = Vector2(96, 48)
		row.add_child(sell)
		UiKit.card(box).add_child(row)


static func _production(box: VBoxContainer) -> void:
	_text(box, "Produção em cadeia", false)
	_text(box, "Transforme ingredientes e materiais. Novas receitas aparecem conforme seus atributos crescem.", true)
	for id: String in Database.stations:
		var card := UiKit.card(box)
		card.add_child(UiKit.label(Database.stations[id].name, &"SectionLabel"))
		if not GameState.has_upgrade(id):
			_text(card, "Adquira em Construir.", true)
			continue
		var ready := GameState.station(id).ready_count(GameState.now())
		_text(card, "%d pronto(s) · %d na fila" % [ready, GameState.station(id).queue.size()], true)
		card.add_child(UiKit.button("Abrir", func() -> void:
			Events.sheet_requested.emit(Database.stations[id].name, SheetBuilder.station_view(id)), &"PrimaryButton"))


static func _collection(box: VBoxContainer) -> void:
	_text(box, "Lembranças da nossa história")
	_text(box, "Roupas e apetrechos conquistados nas missões ficam guardados aqui.", true)
	for id: String in Database.collections:
		var data: Dictionary = Database.collections[id]
		var earned := GameState.progress.collection.has(id)
		var card := UiKit.card(box, &"ReadyCardPanel" if earned else &"CardPanel")
		_title(card, data.icon, data.name)
		_text(card, data.description, true)
		_text(card, "Conquistado!" if earned else "Recompensa de missão", true)
