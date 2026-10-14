class_name TaskHelp
extends RefCounted
## Guia consultivo: requisitos, quantidades e próximo passo, sem alterar o estado.
## Todos os custos, fontes e tempos vêm do Database.

static func describe(kind: String, id: String, amount: int = 1, trail: Array[String] = []) -> Dictionary:
	var key := kind + ":" + id
	if key in trail or trail.size() >= 12:
		return _base("Continue a história", "Siga os passos da história.", {"screen": "tasks"}, "Missões")
	var visited: Array[String] = trail.duplicate()
	visited.append(key)
	var result: Dictionary
	match kind:
		"produced":
			var source := best_source(id)
			if source.is_empty():
				return _base(Database.item_name(id), "Continue produzindo.", {"screen": "tasks"}, "Missões")
			result = describe(source.kind, source.id, maxi(1, amount - GameState.progress.stat("produce:" + id)), visited)
			result["detail"] = "Produza e recolha " + Database.item_name(id)
		"quest":
			var quest: Dictionary = Database.quests[id]
			if GameState.quest_error(id) == "":
				return _base(quest.name, "Tudo pronto!", {"claim": id}, "Receber")
			var goal: Dictionary = quest.goals[0]
			for candidate: Dictionary in quest.goals:
				if GameState.goal_value(candidate) < int(candidate.get("target", 1)):
					goal = candidate
					break
			result = _goal(goal, visited)
			result["title"] = quest.name
			result["dialogue"] = quest.dialogue
			result["goals"] = quest.goals
			return result
		"item":
			var missing := maxi(0, amount - GameState.inventory.count(id))
			if missing == 0:
				return _base(Database.item_name(id), "Você já tem.", {"screen": "tasks"}, "Missões")
			var source := best_source(id)
			if source.is_empty():
				return _base(Database.item_name(id), "Veja na Mochila.", {"screen": "bag"}, "Mochila")
			var source_amount := missing if source.kind == "recipe" else 1
			result = describe(source.kind, source.id, source_amount, visited)
			result["title"] = Database.item_name(id)
			result["stock"] = "%d/%d" % [GameState.inventory.count(id), amount]
			return result
		"recipe":
			result = _recipe(id, amount)
		"upgrade":
			var upgrade: Dictionary = Database.progression.upgrades[id]
			if upgrade.has("nature_unlock"):
				var site: String = upgrade.nature_unlock.site
				var level := int(upgrade.nature_unlock.level)
				var config: Dictionary = Database.progression.nature_sites[site]
				var missing := maxi(0, int(config.levels[level - 1].xp) - int(GameState.progress.nature_xp.get(site, 0)))
				result = _base(upgrade.name, "Recolha coletas em %s para ganhar XP." % config.name, {"world":"nature", "place":"place:" + site}, "Coletar")
				result.detail = "Faltam %d XP · %d coleta(s)" % [missing, ceili(float(missing) / int(config.xp_per_collection))]
				result.needs = _requirements({"owned":[config.level_upgrades[0]]})
				return result
			result = _base(upgrade.name, "Junte o que falta e construa.", Places.goal_target({"type": "owned", "key": id}), "Ir")
			result.needs = _requirements(upgrade.get("requirements", {}))
			result.needs.append(_need("coins", "", int(upgrade.get("cost", 0))))
			_materials(result.needs, upgrade.get("materials", {}))
		"crop":
			var crop: Dictionary = Database.crops[id]
			result = _base(Database.item_name(id), "Plante e colha · %s" % TimeText.short(int(crop.seconds)), _focused("farm", "crop:" + id), "Ir")
			result.needs = _requirements(crop.get("requirements", {})) if GameState.content_error("crop", id, crop) != "" else []
		"route":
			var route: Dictionary = Database.progression.activities[id]
			result = _base(route.name, "Passeio de %s" % TimeText.short(int(route.seconds)), _focused("routes:" + str(route.place), "route:" + id), "Ir")
			result.needs = _requirements(route.get("requirements", {}))
			var site := Database.gathering_site(id)
			if site != "" and GameState.progress.nature_level(site) == 0:
				result.detail = "Desbloqueie %s para começar." % Database.progression.nature_sites[site].name
			elif site != "" and GameState.gathering_ready_count(site) > 0:
				result.detail = "%d coleta(s) pronta(s). Recolha no local." % GameState.gathering_ready_count(site)
			elif site != "" and GameState.gathering_free_count(site) == 0:
				result.detail = "Espaços ocupados. Aguarde ou recolha."
			elif site == "" and not GameState.progress.activity.is_empty():
				result.detail = "Já tem um passeio: " + ("recolha!" if GameState.activity_remaining() == 0 else "volta em %s" % TimeText.short(GameState.activity_remaining()))
		"order":
			var order: Dictionary = Database.progression.orders[id]
			result = _base(order.name, "Junte e entregue na Vila.", _focused("orders", "order:" + id), "Ir")
			result.needs = _requirements(order.get("requirements", {}))
			_materials(result.needs, order.inputs)
			var wait := GameState.progress.cooldown_left("order:" + id, GameState.now())
			if wait > 0:
				result.detail = "Novo pedido em %s" % TimeText.short(wait)
		"skill":
			var skill: Dictionary = Database.progression.skills[id]
			var info := GameState.skill_info(id)
			result = _base(skill.name, "Nível %d → %d" % [info.level, amount], Places.goal_target({"type": "skill", "key": id}), "Ir")
			if id == "cooking" and not GameState.has_upgrade("stove"):
				result.needs.append(_need("upgrade", "stove", 1))
		"care":
			result = _base("Comida para o Tiro", "Dê comida na Tigela.", Places.goal_target({"type": "stat", "key": "feed"}), "Ir")
		"coins":
			var target := Places.goal_target({"type": "coins"})
			if Places.world_error(str(target.get("world", ""))) != "":
				target = Places.goal_target({"type": "stat", "key": "harvest"})
			result = _base("Juntar moedas", "Colha e venda.", target, "Ir")
		"chapter":
			result = _base("Capítulo %d" % amount, "Siga a história.", {"screen": "tasks"}, "Missões")
		_:
			result = _base("Continuar", "Siga a história.", {"screen": "tasks"}, "Missões")
	# Inclui o bloqueio do mundo antes de qualquer ingrediente.
	var world: String = result.target.get("world", "")
	if world != "" and Database.worlds.has(world):
		result.needs = _requirements(Database.worlds[world].get("requirements", {})) + result.needs
	for need: Dictionary in result.needs:
		if int(need.have) < int(need.amount) and not result.has("next"):
			var next := describe(need.kind, need.id, int(need.amount), visited)
			# O passo mais fundo da cadeia (ex.: plantar cenoura antes do petisco).
			var first: Dictionary = next.get("next_need", need)
			result["next_need"] = first
			result["next"] = str(first.label)
			result["next_target"] = next.get("next_target", next.target)
			result["next_action"] = next.get("next_action", next.action)
			break
	return result


static func _base(title: String, detail: String, target: Dictionary, action: String) -> Dictionary:
	return {"title": title, "detail": detail, "target": target, "action": action, "needs": []}


static func _goal(goal: Dictionary, trail: Array[String]) -> Dictionary:
	var type: String = goal.type
	var key: String = goal.get("key", "")
	var amount := int(goal.get("target", 1))
	match type:
		"owned": return describe("upgrade", key, 1, trail)
		"skill": return describe("skill", key, amount, trail)
		"coins", "chapter": return describe(type, "", amount, trail)
		"quest": return describe("quest", key, 1, trail)
		"have", "deliver":
			var result := describe("item", key, amount, trail)
			if type == "deliver":
				result.detail = "Será entregue ao receber."
			return result
		"stat":
			if key.begins_with("produce:"):
				for recipe_id: String in Database.recipes:
					if Database.recipes[recipe_id].output == key.trim_prefix("produce:"):
						return describe("recipe", recipe_id, maxi(0, amount - GameState.goal_value(goal)), trail)
			if key.begins_with("activity:"):
				return describe("route", key.trim_prefix("activity:"), 1, trail)
			if key.begins_with("order:"):
				return describe("order", key.trim_prefix("order:"), 1, trail)
			if key == "orders":
				return describe("order", _best_order(), 1, trail)
			if key.begins_with("harvest:"):
				return describe("crop", key.trim_prefix("harvest:"), 1, trail)
	var target := Places.goal_target(goal)
	var hints := {"talk:lais": "Toque na Laís, na Casa.", "talk:bloblo": "Toque na vovó Bloblo, no Sítio.", "open:bag": "Toque na aba Mochila.", "feed": "Dê comida na Tigela.", "harvest": "Plante e colha.", "bathe": "Aba Tiro → Banho.", "play": "Aba Tiro → Brincar.", "trade": "Venda na Vila.", "sold": "Venda na Vila.", "explore": "Faça um passeio.", "produce": "Cozinhe no Fogão."}
	return _base(str(goal.get("label", "Seu objetivo")), hints.get(key, ""), target, "Ir")


static func _recipe(id: String, amount: int) -> Dictionary:
	var recipe: Dictionary = Database.recipes[id]
	var station: String = recipe.station
	var target := _focused("station:" + station, "recipe:" + id)
	var result := _base(Database.item_name(recipe.output), "", target, "Ir")
	var pending := 0
	var ready := 0
	var remaining := 0
	for entry: Dictionary in GameState.station(station).queue:
		if entry.recipe == id:
			pending += int(entry.get("qty", recipe.get("qty", 1)))
			if float(entry.ready_at) <= GameState.now():
				ready += int(entry.get("qty", recipe.get("qty", 1)))
			remaining = maxi(remaining, int(ceil(float(entry.ready_at) - GameState.now())))
	var batches := ceili(float(maxi(0, amount - pending)) / maxi(1, GameState.recipe_quantity(id)))
	result["batches"] = batches
	result["pending"] = pending
	result.detail = "Prepare %dx · %s cada" % [batches, TimeText.short(int(recipe.seconds))]
	if pending > 0:
		result.detail += " · %d na fila" % pending
	if ready > 0 or (pending >= amount and pending > 0):
		result.action = "Recolher" if ready > 0 else "Ver"
		result.detail = "%d pronto(s)!" % ready if ready > 0 else "Já está no fogo · %s" % TimeText.short(remaining)
		return result
	if not GameState.has_upgrade(station):
		result.needs.append(_need("upgrade", station, 1))
	if GameState.content_error("recipe", id, recipe) != "":
		result.needs.append_array(_requirements(recipe.get("requirements", {})))
	if Database.stations[station].get("kind", "") == "animal" and GameState.animal_count(station) == 0:
		result["next"] = "Compre seu primeiro animal no abrigo"
		result["next_target"] = target
		result["next_action"] = "Comprar animais"
		return result
	_materials(result.needs, GameState.recipe_inputs(id), batches)
	if GameState.station(station).queue.size() >= GameState.station_slots(station):
		result["next"] = "Fila cheia: recolha ou espere"
		result["next_target"] = target
		result["next_action"] = "Ver"
	return result


static func _need(kind: String, id: String, amount: int) -> Dictionary:
	var have := 0
	var label := ""
	match kind:
		"produced":
			have = GameState.progress.stat("produce:" + id)
			label = "Recolher " + Database.item_name(id)
		"item":
			have = GameState.inventory.count(id)
			label = Database.item_name(id)
		"upgrade":
			have = 1 if GameState.has_upgrade(id) else 0
			label = str(Database.progression.upgrades[id].name)
		"skill":
			have = GameState.progress.skill_level(id)
			label = "%s nível %d" % [Database.progression.skills[id].name, amount]
		"coins":
			have = GameState.coins
			label = "Moedas"
		"quest":
			have = 1 if GameState.progress.claimed_quests.has(id) else 0
			label = str(Database.quests[id].name)
		"chapter":
			have = GameState.progress.chapter_index()
			label = "Capítulo %d" % amount
	return {"kind": kind, "id": id, "amount": amount, "have": have, "label": label}


static func _requirements(requirements: Dictionary) -> Array[Dictionary]:
	var needs: Array[Dictionary] = []
	for item: String in requirements.get("produced", {}):
		if GameState.progress.stat("produce:" + item) < int(requirements.produced[item]):
			needs.append(_need("produced", item, int(requirements.produced[item])))
	for id: String in requirements.get("owned", []):
		if not GameState.has_upgrade(id):
			needs.append(_need("upgrade", id, 1))
	for id: String in requirements.get("quests", []):
		if not GameState.progress.claimed_quests.has(id):
			needs.append(_need("quest", id, 1))
	if GameState.progress.chapter_index() < int(requirements.get("chapter", 1)):
		needs.append(_need("chapter", "", int(requirements.chapter)))
	for id: String in requirements.get("skills", {}):
		if GameState.progress.skill_level(id) < int(requirements.skills[id]):
			needs.append(_need("skill", id, int(requirements.skills[id])))
	return needs


static func _materials(needs: Array, materials: Dictionary, batches: int = 1) -> void:
	for item: String in materials:
		needs.append(_need("item", item, int(materials[item]) * batches))


## Prefere uma fonte acessível; evita mandar à mina fechada quando uma trilha já rende pedra.
static func best_source(item: String) -> Dictionary:
	var best := {}
	var score := INF
	for source: Dictionary in Database.item_sources(item):
		var candidate := {}
		var requirements := {}
		var station := ""
		if str(source.key).begins_with("harvest:"):
			var crop: String = str(source.key).trim_prefix("harvest:")
			candidate = {"kind": "crop", "id": crop}
			requirements = Database.crops[crop].get("requirements", {})
		elif str(source.key).begins_with("produce:"):
			for id: String in Database.recipes:
				if Database.recipes[id].output == item:
					candidate = {"kind": "recipe", "id": id}
					requirements = Database.recipes[id].get("requirements", {})
					station = Database.recipes[id].station
					break
		elif str(source.key).begins_with("activity:"):
			var route: String = str(source.key).trim_prefix("activity:")
			candidate = {"kind": "route", "id": route}
			requirements = Database.progression.activities[route].get("requirements", {})
		if candidate.is_empty():
			continue
		var target := Places.goal_target(source)
		var value := float(_requirements(requirements).size() * 100)
		if station != "" and not GameState.has_upgrade(station):
			value += 100
		if target.has("world") and Places.world_error(target.world) != "":
			value += 1000
		if value < score:
			score = value
			best = candidate
	if item == "dog_food":
		return {"kind": "care", "id": "feed"}
	return best


static func _best_order() -> String:
	var best := ""
	var score := INF
	for id: String in Database.progression.orders:
		var order: Dictionary = Database.progression.orders[id]
		var value := float(_requirements(order.get("requirements", {})).size() * 1000)
		for item: String in order.inputs:
			value += maxi(0, int(order.inputs[item]) - GameState.inventory.count(item))
		value += GameState.progress.cooldown_left("order:" + id, GameState.now())
		if value < score:
			best = id
			score = value
	return best


static func _focused(panel: String, focus: String) -> Dictionary:
	var location := Database.place_with_panel(panel)
	return {"world": location[0], "place": focus, "spot": location[1], "hint": "%s → %s" % [Database.worlds[location[0]].name, Database.worlds[location[0]].places[location[1]].name]}


## Painel "Como fazer" (botão "?" e chips de ingrediente). `history` = etapas anteriores, para voltar.
static func open(kind: String, id: String, amount: int = 1, history: Array[Dictionary] = []) -> void:
	Events.sheet_requested.emit("Como fazer", panel(kind, id, amount, history))


## Visual: o que é (ícone + tem/precisa), o primeiro passo com Ir e o que falta em chips tocáveis.
static func panel(kind: String, id: String, amount: int = 1, history: Array[Dictionary] = []) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var data := describe(kind, id, amount)
		var top := UiKit.hbox(10)
		if not history.is_empty():
			var previous: Dictionary = history.back()
			top.add_child(UiKit.square_button("‹", func() -> void:
				var back: Array[Dictionary] = history.duplicate()
				back.pop_back()
				open(previous.kind, previous.id, previous.amount, back)))
		top.add_child(UiKit.icon(icon_for(kind, id), 64))
		var title := UiKit.vbox(2)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_child(UiKit.label(data.title, &"SectionLabel"))
		if data.has("stock"):
			var enough := GameState.inventory.count(id) >= amount
			title.add_child(UiKit.label(data.stock, &"", UiKit.GOOD if enough else UiKit.BAD))
		top.add_child(title)
		box.add_child(top)
		# Próximo passo: ícone + o que fazer + Ir.
		var step := UiKit.hbox(10)
		var first: Dictionary = data.get("next_need", {})
		step.add_child(UiKit.icon(need_icon(first) if not first.is_empty() else icon_for(kind, id), 48))
		step.add_child(UiKit.fill_label(data.get("next", data.detail)))
		var go := UiKit.button(data.get("next_action", data.action), _go.bind(data.get("next_target", data.target)), &"PrimaryButton")
		go.custom_minimum_size = Vector2(92, 52)
		go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		step.add_child(go)
		UiKit.card(box, &"ReadyCardPanel").add_child(step)
		if data.has("next") and data.detail != "":
			box.add_child(UiKit.label(data.detail, &"SmallLabel"))
		if data.needs.is_empty():
			return
		var chips := UiKit.flow()
		for need: Dictionary in data.needs:
			var ok := int(need.have) >= int(need.amount)
			chips.add_child(UiKit.tap_chip(need_icon(need), "%d/%d" % [int(need.have), int(need.amount)], func() -> void:
				var path: Array[Dictionary] = history.duplicate()
				path.append({"kind": kind, "id": id, "amount": amount})
				open(need.kind, need.id, int(need.amount), path), UiKit.GOOD if ok else UiKit.BAD))
		box.add_child(chips)
	)


## Ícone do que o painel explica (missão = objetivo atual).
static func icon_for(kind: String, id: String) -> Texture2D:
	match kind:
		"produced":
			return Database.item_icon(id)
		"quest":
			return ProgressionUi.goal_icon(ProgressionUi.current_goal(id))
		"item", "crop":
			return Database.item_icon(id)
		"recipe":
			return Database.item_icon(Database.recipes[id].output)
		"route":
			return UiKit.ui_icon(Database.progression.activities[id].get("icon", "action_play"))
		"order":
			return UiKit.ui_icon("item_treat_box")
		"care":
			return UiKit.ui_icon("need_hunger")
	return need_icon({"kind": kind, "id": id})


## Ícone de um requisito (item, construção, atributo, moedas, missão).
static func need_icon(need: Dictionary) -> Texture2D:
	var id: String = need.get("id", "")
	match str(need.get("kind", "")):
		"item":
			return Database.item_icon(id)
		"upgrade":
			return UiKit.ui_icon(Database.progression.upgrades[id].get("icon", "tab_house"))
		"skill":
			return UiKit.ui_icon(Database.progression.skills[id].get("icon", "xp"))
		"coins":
			return UiKit.ui_icon("coin")
	return UiKit.ui_icon("tab_tasks")


static func _go(target: Dictionary) -> void:
	if target.has("claim"):
		var error := GameState.claim_quest(target.claim)
		if error != "":
			Events.toast_requested.emit(error)
	else:
		Places.go(target)
