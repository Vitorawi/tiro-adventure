class_name TaskHelp
extends RefCounted
## Guia consultivo: requisitos, quantidades e próximo passo, sem alterar o estado.
## Todos os custos, fontes e tempos vêm do Database.

static func describe(kind: String, id: String, amount: int = 1, trail: Array[String] = []) -> Dictionary:
	var key := kind + ":" + id
	if key in trail or trail.size() >= 12:
		return _base("Continue sua história", "Veja os passos anteriores para liberar este objetivo.", {"screen": "tasks"}, "Ver tarefas")
	var visited: Array[String] = trail.duplicate()
	visited.append(key)
	var result: Dictionary
	match kind:
		"quest":
			var quest: Dictionary = Database.quests[id]
			if GameState.quest_error(id) == "":
				return _base(quest.name, "Tudo pronto! Receba a recompensa para avançar.", {"claim": id}, "Receber recompensa")
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
				return _base(Database.item_name(id), "Você já tem a quantidade necessária na mochila.", {"screen": "tasks"}, "Voltar às tarefas")
			var source := best_source(id)
			if source.is_empty():
				return _base(Database.item_name(id), "Veja as fontes deste item na mochila.", {"screen": "bag"}, "Ver mochila")
			var source_amount := missing if source.kind == "recipe" else 1
			result = describe(source.kind, source.id, source_amount, visited)
			result["title"] = Database.item_name(id)
			result["stock"] = "Você tem %d / precisa de %d · faltam %d" % [GameState.inventory.count(id), amount, missing]
			return result
		"recipe":
			result = _recipe(id, amount)
		"upgrade":
			var upgrade: Dictionary = Database.progression.upgrades[id]
			result = _base(upgrade.name, "Construa no Mapa. Os materiais e as moedas serão usados na compra.", Places.goal_target({"type": "owned", "key": id}), "Ir construir")
			result.needs = _requirements(upgrade.get("requirements", {}))
			result.needs.append(_need("coins", "", int(upgrade.get("cost", 0))))
			_materials(result.needs, upgrade.get("materials", {}))
		"crop":
			var crop: Dictionary = Database.crops[id]
			result = _base(Database.item_name(id), "Plante e depois colha: %s. Leva %s; as sementes são gratuitas." % [Database.describe_amounts(crop.get("yield", {})), TimeText.short(int(crop.seconds))], _focused("farm", "crop:" + id), "Ir plantar / colher")
			result.needs = _requirements(crop.get("requirements", {})) if GameState.content_error("crop", id, crop) != "" else []
		"route":
			var route: Dictionary = Database.progression.activities[id]
			result = _base(route.name, "Comece a rota e recolha ao voltar. Leva %s. Recebe: %s." % [TimeText.short(int(route.seconds)), ProgressionUi.rewards_text(route.rewards)], _focused("routes:" + str(route.place), "route:" + id), "Ir à rota")
			result.needs = _requirements(route.get("requirements", {}))
			if not GameState.progress.activity.is_empty():
				result.detail = "Já existe uma rota em andamento. " + ("Recolha o resultado antes de começar outra." if GameState.activity_remaining() == 0 else "Volta em %s." % TimeText.short(GameState.activity_remaining()))
		"order":
			var order: Dictionary = Database.progression.orders[id]
			result = _base(order.name, "Separe os produtos e toque em Entregar. Os itens serão consumidos.", _focused("orders", "order:" + id), "Ir entregar")
			result.needs = _requirements(order.get("requirements", {}))
			_materials(result.needs, order.inputs)
			var wait := GameState.progress.cooldown_left("order:" + id, GameState.now())
			if wait > 0:
				result.detail += " Novo pedido em %s." % TimeText.short(wait)
		"skill":
			var skill: Dictionary = Database.progression.skills[id]
			var info := GameState.skill_info(id)
			result = _base(skill.name, "%s Você está no nível %d; precisa do nível %d (%d/%d XP para o próximo)." % [skill.how_to, info.level, amount, info.xp, info.needed], Places.goal_target({"type": "skill", "key": id}), "Ir evoluir")
			var stations := {"cooking": "stove", "building": "workbench"}
			if stations.has(id) and not GameState.has_upgrade(stations[id]):
				result.needs.append(_need("upgrade", stations[id], 1))
		"care":
			result = _base("Comida para o Tiro", "Abra a Tigela. Quando não houver comida, peça ração gratuita à Bloblo.", Places.goal_target({"type": "stat", "key": "feed"}), "Ir à tigela")
		"coins":
			var target := Places.goal_target({"type": "coins"})
			if Places.world_error(str(target.get("world", ""))) != "":
				target = Places.goal_target({"type": "stat", "key": "harvest"})
			result = _base("Juntar moedas", "Você tem %d / precisa de %d. Colha nos canteiros ou venda excedentes na Vila; guarde os ingredientes da missão." % [GameState.coins, amount], target, "Ir juntar moedas")
		"chapter":
			result = _base("Capítulo %d" % amount, "Continue a história até o capítulo %d." % amount, {"screen": "tasks"}, "Ver tarefas")
		_:
			result = _base("Continuar", "Veja o próximo passo em Tarefas.", {"screen": "tasks"}, "Ver tarefas")
	# Inclui o bloqueio do mundo antes de qualquer ingrediente.
	var world: String = result.target.get("world", "")
	if world != "" and Database.worlds.has(world):
		result.needs = _requirements(Database.worlds[world].get("requirements", {})) + result.needs
	for need: Dictionary in result.needs:
		if int(need.have) < int(need.amount) and not result.has("next"):
			var next := describe(need.kind, need.id, int(need.amount), visited)
			result["next"] = "Primeiro: " + str(need.label)
			result["next_detail"] = next.get("next", next.detail)
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
		"have", "deliver":
			var result := describe("item", key, amount, trail)
			result.detail += " Os itens serão entregues ao receber a missão." if type == "deliver" else "Basta guardar na mochila; esta missão não consome o item."
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
	var hints := {"feed": "Toque em Dar na Tigela do Tiro. Se a comida acabar, peça ajuda à Bloblo.", "harvest": "Escolha um canteiro, plante e volte para colher quando estiver pronto.", "bathe": "Abra Tiro e toque em Banho.", "play": "Abra Tiro e toque em Brincar.", "trade": "Na Vila, venda um produto da mochila ou entregue uma encomenda.", "sold": "Na Vila, venda os produtos que sobrarem.", "explore": "Complete passeios e recolha o resultado ao voltar."}
	return _base(str(goal.get("label", "Seu objetivo")), hints.get(key, target.get("hint", "Siga até o lugar indicado.")), target, "Ir fazer")


static func _recipe(id: String, amount: int) -> Dictionary:
	var recipe: Dictionary = Database.recipes[id]
	var station: String = recipe.station
	var target := _focused("station:" + station, "recipe:" + id)
	var result := _base(Database.item_name(recipe.output), "", target, "Ir preparar")
	var pending := 0
	var ready := 0
	var remaining := 0
	for entry: Dictionary in GameState.station(station).queue:
		if entry.recipe == id:
			pending += int(recipe.get("qty", 1))
			if float(entry.ready_at) <= GameState.now():
				ready += int(recipe.get("qty", 1))
			remaining = maxi(remaining, int(ceil(float(entry.ready_at) - GameState.now())))
	var batches := ceili(float(maxi(0, amount - pending)) / maxi(1, int(recipe.get("qty", 1))))
	result["batches"] = batches
	result["pending"] = pending
	result.detail = "Para conseguir %d: faça %d preparo(s). Cada preparo rende %d e leva %s. Recolha quando ficar pronto." % [amount, batches, int(recipe.get("qty", 1)), TimeText.short(int(recipe.seconds))]
	if pending > 0:
		result.detail += " Já há %d na fila." % pending
	if ready > 0 or (pending >= amount and pending > 0):
		result.action = "Ir recolher" if ready > 0 else "Ver preparo"
		result.detail = "Há %d pronto(s) para recolher." % ready if ready > 0 else "Já está preparando o necessário. Faltam até %s; não precisa produzir de novo." % TimeText.short(remaining)
		return result
	if not GameState.has_upgrade(station):
		result.needs.append(_need("upgrade", station, 1))
	if GameState.content_error("recipe", id, recipe) != "":
		result.needs.append_array(_requirements(recipe.get("requirements", {})))
	_materials(result.needs, recipe.inputs, batches)
	if GameState.station(station).queue.size() >= GameState.station_slots(station):
		result["next"] = "A fila está cheia. Recolha o que estiver pronto ou espere uma vaga."
		result["next_target"] = target
		result["next_action"] = "Ver fila"
	return result


static func _need(kind: String, id: String, amount: int) -> Dictionary:
	var have := 0
	var label := ""
	match kind:
		"item":
			have = GameState.inventory.count(id)
			label = Database.item_name(id)
		"upgrade":
			have = 1 if GameState.has_upgrade(id) else 0
			label = "Construir " + str(Database.progression.upgrades[id].name)
		"skill":
			have = GameState.progress.skill_level(id)
			label = "%s nível %d" % [Database.progression.skills[id].name, amount]
		"coins":
			have = GameState.coins
			label = "Moedas"
		"quest":
			have = 1 if GameState.progress.claimed_quests.has(id) else 0
			label = "Concluir " + str(Database.quests[id].name)
		"chapter":
			have = GameState.progress.chapter_index()
			label = "Chegar ao capítulo %d" % amount
	return {"kind": kind, "id": id, "amount": amount, "have": have, "label": label}


static func _requirements(requirements: Dictionary) -> Array[Dictionary]:
	var needs: Array[Dictionary] = []
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
	return {"world": location[0], "place": focus, "hint": "%s → %s" % [Database.worlds[location[0]].name, Database.worlds[location[0]].places[location[1]].name]}


static func open(kind: String, id: String, amount: int = 1, history: Array[Dictionary] = []) -> void:
	Events.sheet_requested.emit("Como fazer", panel(kind, id, amount, history))


static func panel(kind: String, id: String, amount: int = 1, history: Array[Dictionary] = []) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		if not history.is_empty():
			var previous: Dictionary = history.back()
			box.add_child(UiKit.button("Voltar à etapa anterior", func() -> void:
				var back: Array[Dictionary] = history.duplicate()
				back.pop_back()
				open(previous.kind, previous.id, previous.amount, back)))
		var data := describe(kind, id, amount)
		box.add_child(UiKit.label(data.title, &"SectionLabel"))
		if data.has("stock"):
			box.add_child(UiKit.label(data.stock, &"SmallLabel"))
		var next := UiKit.card(box, &"ReadyCardPanel")
		next.add_child(UiKit.label(data.get("next", "Seu próximo passo"), &"SectionLabel"))
		next.add_child(UiKit.label(data.get("next_detail", data.detail), &"SmallLabel"))
		var destination: Dictionary = data.get("next_target", data.target)
		next.add_child(UiKit.button(data.get("next_action", data.action), _go.bind(destination), &"PrimaryButton"))
		if data.has("next"):
			box.add_child(UiKit.label(data.detail, &"SmallLabel"))
		if kind == "quest":
			for goal: Dictionary in Database.quests[id].goals:
				box.add_child(UiKit.label("%s · %d/%d" % [goal.label, mini(GameState.goal_value(goal), int(goal.get("target", 1))), int(goal.get("target", 1))], &"SmallLabel"))
		if not data.needs.is_empty():
			box.add_child(UiKit.label("O que você precisa", &"SectionLabel"))
		for need: Dictionary in data.needs:
			var missing := maxi(0, int(need.amount) - int(need.have))
			var card := UiKit.card(box)
			var row := UiKit.hbox(8)
			if need.kind == "item":
				row.add_child(UiKit.icon(Database.item_icon(need.id), 32))
			var label := UiKit.label("%s · %d/%d" % [need.label, need.have, need.amount])
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			card.add_child(row)
			card.add_child(UiKit.label("Já tem o necessário" if missing == 0 else "Faltam %d" % missing, &"SmallLabel", UiKit.GOOD if missing == 0 else UiKit.BAD))
			if missing > 0:
				card.add_child(UiKit.button("Como conseguir" if need.kind == "item" else "Ver como liberar", func() -> void:
					var path: Array[Dictionary] = history.duplicate()
					path.append({"kind": kind, "id": id, "amount": amount})
					open(need.kind, need.id, int(need.amount), path)))
		if kind == "quest" and GameState.quest_error(id) == "":
			box.add_child(UiKit.label("Recompensa: " + ProgressionUi.rewards_text(Database.quests[id].rewards), &"SmallLabel"))
	)


static func _go(target: Dictionary) -> void:
	if target.has("claim"):
		var error := GameState.claim_quest(target.claim)
		if error != "":
			Events.toast_requested.emit(error)
	else:
		Places.go(target)
