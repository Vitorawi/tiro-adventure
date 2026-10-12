class_name ProgressionUi
extends RefCounted
## Painéis da progressão, abertos pelos lugares dos mundos (Places) e pelas Tarefas:
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
	var ready := GameState.quest_error(id) == ""
	var card := UiKit.card(box, &"ReadyCardPanel" if ready else &"CardPanel")
	card.add_child(UiKit.label(quest.name, &"SectionLabel"))
	_text(card, quest.dialogue, true)
	for goal: Dictionary in quest.goals:
		var target := int(goal.get("target", 1))
		var value := mini(GameState.goal_value(goal), target)
		_text(card, "%s · %d/%d" % [goal.label, value, target], true)
		card.add_child(UiKit.bar(100.0 * value / maxi(1, target), UiKit.GOOD, 8))
	_text(card, "Recompensa: " + rewards_text(quest.rewards), true)
	quest_action(card, id)


# --- Construir --------------------------------------------------------------------

static func purchase(id: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void: upgrade_card(box, id))


## Construções de um mundo: primeiro as que faltam, depois as conquistadas.
static func build_panel(world_id: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var upgrades: Dictionary = Database.progression.upgrades
		var owned: Array[String] = []
		for id: String in upgrades:
			if upgrades[id].get("world", "") != world_id:
				continue
			if GameState.has_upgrade(id):
				owned.append(id)
			else:
				upgrade_card(box, id)
		if not owned.is_empty():
			box.add_child(UiKit.label("Já é seu", &"SectionLabel"))
			for id in owned:
				upgrade_card(box, id)
	)


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
	_action(card, "Comprar " + data.name, func() -> String: return GameState.buy_upgrade(id), GameState.upgrade_error(id), "%s é seu!" % data.name)


# --- Vila: vender e encomendas --------------------------------------------------------

static func sell_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		_text(box, "Guarde o que precisar para receitas, construções e missões. O resto vira moeda!", true)
		var any := false
		for id: String in Database.items:
			var price := int(Database.items[id].get("sell_price", 0))
			var count := GameState.inventory.count(id)
			if price <= 0 or count == 0:
				continue
			any = true
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
		if not any:
			_text(box, "Nada para vender agora. Colha no sítio ou passeie na trilha!")
	)


static func orders_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		_text(box, "Encomendas pagam mais que a venda direta e voltam depois de um tempo.", true)
		for id: String in Database.progression.orders:
			var data: Dictionary = Database.progression.orders[id]
			var reason := GameState.order_error(id)
			var locked := GameState.requirement_error(data.get("requirements", {}))
			var card := UiKit.card(box, &"ReadyCardPanel" if reason == "" else &"CardPanel")
			card.add_child(UiKit.label(data.name, &"SectionLabel"))
			if locked != "":
				_text(card, "Ainda não: " + locked, true)
				continue
			_amounts(card, data.inputs)
			_text(card, "Recebe: " + rewards_text(data.rewards), true)
			_action(card, "Entregar", func() -> String: return GameState.fulfill_order(id), reason, "Encomenda entregue!")
	)


# --- Rotas (passeios, mina, pomar) ------------------------------------------------------

## Rotas de um lugar ("walk", "mine", "orchard"). Só uma rota por vez em todo o jogo.
static func routes_panel(place: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		active_activity(box)
		_text(box, "Uma rota por vez. O tempo continua passando com o jogo fechado.", true)
		for id: String in Database.progression.activities:
			var data: Dictionary = Database.progression.activities[id]
			if data.get("place", "walk") != place:
				continue
			var card := UiKit.card(box)
			_title(card, data.get("icon", ""), data.name)
			_text(card, data.description, true)
			var details := UiKit.flow()
			details.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(data.seconds))))
			for item: String in data.rewards.get("items", {}):
				details.add_child(UiKit.chip(Database.item_icon(item), "+%d" % int(data.rewards.items[item]), UiKit.GOOD))
			if int(data.rewards.get("coins", 0)) > 0:
				details.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(data.rewards.coins), UiKit.GOOD))
			card.add_child(details)
			_action(card, "Começar", func() -> String: return GameState.start_activity(id), GameState.activity_error(id), "Vocês saíram para: " + data.name)
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
		_text(box, "Cada atividade treina um atributo. Níveis altos liberam sementes, receitas, rotas e construções.", true)
		for id: String in Database.progression.skills:
			var data: Dictionary = Database.progression.skills[id]
			var info := GameState.skill_info(id)
			var card := UiKit.card(box)
			_title(card, data.icon, "%s · nível %d" % [data.name, int(info.level)])
			_text(card, data.description, true)
			_text(card, data.get("how_to", ""), true)
			for chapter in range(GameState.progress.chapter_index(), Database.progression.chapters.size() + 1):
				var needed := 0
				for quest in GameState.progress.main_quests(chapter):
					needed = maxi(needed, int(quest_skills(quest).get(id, 0)))
				if needed > int(info.level):
					_text(card, "A história pede nível %d no capítulo %d" % [needed, chapter], true)
					break
			card.add_child(UiKit.bar(100 if info.max else float(info.xp) / float(info.needed) * 100, Color(data.color)))
			_text(card, "Nível máximo" if info.max else "%d / %d XP para o próximo nível" % [int(info.xp), int(info.needed)], true)
			var next := _next_milestone(id, int(info.level))
			if next != "":
				_text(card, next, true)
	)


## "Nível 3 → Abóbora": o próximo conteúdo que o atributo libera.
static func _next_milestone(skill_id: String, current: int) -> String:
	var best_level := 999
	var best_name := ""
	for group: Dictionary in [Database.progression.upgrades, Database.progression.activities, Database.crops, Database.recipes]:
		for content_id: String in group:
			var entry: Dictionary = group[content_id]
			var required := int(entry.get("requirements", {}).get("skills", {}).get(skill_id, 0))
			if required > current and required < best_level:
				best_level = required
				best_name = entry.get("name", Database.item_name(entry.get("output", content_id)))
	return "" if best_name == "" else "Nível %d → %s" % [best_level, best_name]


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


## Botão de ação do GameState: desabilitado com o motivo embaixo; toast com o resultado.
static func _action(box: VBoxContainer, text: String, action: Callable, reason: String = "", done: String = "Feito!") -> void:
	var button := UiKit.button(text, func() -> void:
		var error: String = action.call()
		Events.toast_requested.emit(error if error != "" else done), &"PrimaryButton")
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


## Requisitos de atributo diretos e da construção do passo.
static func quest_skills(id: String) -> Dictionary:
	var result := {}
	for goal: Dictionary in Database.quests[id].goals:
		if goal.type == "skill":
			result[goal.key] = maxi(int(result.get(goal.key, 0)), int(goal.target))
		if goal.type == "owned":
			for skill: String in Database.progression.upgrades[goal.key].get("requirements", {}).get("skills", {}):
				result[skill] = maxi(int(result.get(skill, 0)), int(Database.progression.upgrades[goal.key].requirements.skills[skill]))
	return result


static func quest_action(box: VBoxContainer, id: String) -> void:
	var ready := GameState.quest_error(id) == ""
	box.add_child(UiKit.button("Receber recompensa" if ready else "Ir", func() -> void:
		if ready:
			var error := GameState.claim_quest(id)
			if error != "":
				Events.toast_requested.emit(error)
		else:
			Places.go(Places.quest_target(id)), &"PrimaryButton"))


static func quest_fraction(id: String) -> float:
	var total := 0.0
	var goals: Array = Database.quests[id].goals
	for goal: Dictionary in goals:
		total += minf(1.0, float(GameState.goal_value(goal)) / maxi(1, int(goal.get("target", 1))))
	return total / maxi(1, goals.size())


static func side_quests() -> Array[String]:
	var ids: Array[String] = []
	for id: String in Database.quests:
		if Database.quests[id].get("kind", "side") == "side" and GameState.quest_unlocked(id) and not GameState.progress.claimed_quests.has(id):
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var a_ready := GameState.quest_error(a) == ""
		var b_ready := GameState.quest_error(b) == ""
		if a_ready != b_ready:
			return a_ready
		if not is_equal_approx(quest_fraction(a), quest_fraction(b)):
			return quest_fraction(a) > quest_fraction(b)
		return a < b)
	return ids


static func side_card(box: VBoxContainer, id: String) -> void:
	var q: Dictionary = Database.quests[id]
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.quest_error(id) == "" else &"CardPanel")
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(npc_portrait(q.npc), 40))
	var info := UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(q.name))
	var category: Dictionary = Database.progression.skills.get(q.get("category", ""), {})
	info.add_child(UiKit.label(category.get("name", Database.npcs[q.npc].name), &"SmallLabel", Color(category.get("color", "#62764d"))))
	row.add_child(info)
	card.add_child(row)
	for goal: Dictionary in q.goals:
		card.add_child(UiKit.label("%s · %d/%d" % [goal.label, mini(GameState.goal_value(goal), int(goal.get("target", 1))), int(goal.get("target", 1))], &"SmallLabel"))
	card.add_child(UiKit.label(rewards_text(q.rewards), &"SmallLabel"))
	quest_action(card, id)


static func side_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var ids := side_quests()
		for npc: String in Database.npcs:
			var header := false
			for id in ids:
				if Database.quests[id].npc == npc:
					if not header:
						box.add_child(UiKit.label(Database.npcs[npc].name, &"SectionLabel"))
						header = true
					side_card(box, id)
		var completed := UiKit.vbox()
		completed.visible = false
		var count := 0
		for id: String in Database.quests:
			if Database.quests[id].get("kind", "side") == "side" and GameState.progress.claimed_quests.has(id):
				count += 1
				completed.add_child(UiKit.label("✓ " + str(Database.quests[id].name), &"SmallLabel", UiKit.GOOD))
		box.add_child(UiKit.button("Concluídas (%d)" % count, func() -> void: completed.visible = not completed.visible))
		box.add_child(completed)
	)


static func story_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var current := GameState.progress.chapter_index()
		for i in Database.progression.chapters.size():
			var chapter: Dictionary = Database.progression.chapters[i]
			var index: int = i + 1
			var card := UiKit.card(box, &"ReadyCardPanel" if index == current else &"CardPanel")
			card.add_child(UiKit.label("%s %d · %s" % ["✓" if index < current else ("▶" if index == current else "?"), index, chapter.name], &"SectionLabel"))
			if index < current:
				card.add_child(UiKit.label("Recompensas recebidas · " + rewards_text(chapter.get("rewards", {})), &"SmallLabel", UiKit.GOOD))
			elif index == current:
				for id in GameState.progress.main_quests(index):
					var claimed := GameState.progress.claimed_quests.has(id)
					card.add_child(UiKit.label(("✓ " if claimed else "○ ") + str(Database.quests[id].name), &"SmallLabel"))
					if id == GameState.progress.current_main_quest():
						quest_action(card, id)
	)
