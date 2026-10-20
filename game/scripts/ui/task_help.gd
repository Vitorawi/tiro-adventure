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
		"growth_req":
			return _growth_requirement(id, visited)
		"growth":
			result = _growth_phase(id)
		"stat":
			return _goal({"type": "stat", "key": id, "target": amount}, visited)
		"wish":
			var wish := GameState.wish_def(id)
			if wish.is_empty():
				return _base("Desejos", "Veja o que o Tiro quer.", {"screen": "wishes"}, "Ir")
			if wish.get("type", "") != "action":
				return describe("item", str(wish.item), amount, visited)
			var goal: Dictionary = wish.goal.duplicate()
			goal["type"] = "stat"
			goal["label"] = wish.name
			result = _goal(goal, visited)
			result.target = WishUi.go_target(wish)
		"produced":
			var source := best_source(id)
			if source.is_empty():
				return _base(Database.item_name(id), "Continue produzindo.", {"screen": "tasks"}, "Missões")
			result = describe(source.kind, source.id, maxi(1, amount - GameState.progress.stat("produce:" + id)), visited)
			result["detail"] = "Faça e pegue " + Database.item_name(id)
		"quest":
			var quest: Dictionary = Database.quests[id]
			if GameState.quest_error(id) == "":
				return _base(quest.name, "Tudo pronto!", {"claim": id}, "Pegar prêmio")
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
				# Peça sem receita nem rota (ex.: o parafuso): vem do prêmio do passo de missão que está aberto.
				var giver := _reward_step(id)
				if giver != "":
					result = describe("quest", giver, 1, visited)
					result["title"] = Database.item_name(id)
					result["stock"] = "%d/%d" % [GameState.inventory.count(id), amount]
					return result
				return _base(Database.item_name(id), "Veja na Mochila.", {"screen": "bag"}, "Mochila")
			var source_amount := missing if source.kind == "recipe" else 1
			result = describe(source.kind, source.id, source_amount, visited)
			result["title"] = Database.item_name(id)
			result["stock"] = "%d/%d" % [GameState.inventory.count(id), amount]
			return result
		"recipe":
			result = _recipe(id, amount)
		"walk":
			var walk := GameState.walk_def(id)
			result = _base(str(walk.get("name", id)), "Passeie na Praça e guarde os achados.", {"world": "park", "place": "walk"}, "Ir")
			var error := GameState.walk_error(id)
			if error != "":
				result.detail = error
		"upgrade":
			var upgrade: Dictionary = Database.progression.upgrades[id]
			if upgrade.has("nature_unlock"):
				var site: String = upgrade.nature_unlock.site
				var level := int(upgrade.nature_unlock.level)
				var config: Dictionary = Database.progression.nature_sites[site]
				var missing := maxi(0, int(config.levels[level - 1].xp) - int(GameState.progress.nature_xp.get(site, 0)))
				result = _base(upgrade.name, "Busque em %s para ganhar XP." % config.name, {"world":"nature", "place":"place:" + site}, "Buscar")
				result.detail = "Faltam %d XP" % missing
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
				result.detail = "%s Pegue no local." % Places.ready_text(GameState.gathering_ready_count(site))
			elif site != "" and GameState.gathering_free_count(site) == 0:
				result.detail = "Espaços ocupados. Aguarde ou pegue."
			elif site == "" and not GameState.progress.activity.is_empty():
				result.detail = "Já tem um passeio: " + ("pegue!" if GameState.activity_remaining() == 0 else "volta em %s" % TimeText.short(GameState.activity_remaining()))
		"order":
			var order: Dictionary = Database.progression.orders[id]
			result = _base(order.name, "Junte e entregue na sua banca." if MarketUi.is_contract(id) else "Junte e entregue no quadro da vizinhança.", _focused("contracts" if MarketUi.is_contract(id) else "orders", "order:" + id), "Ir")
			result.needs = _requirements(order.get("requirements", {}))
			_materials(result.needs, order.inputs)
			var wait := GameState.progress.cooldown_left("order:" + id, GameState.now())
			if wait > 0:
				result.detail = "Novo pedido em %s" % TimeText.short(wait)
		"project":
			result = _project(id)
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
	if type == "stat" and (key == "trick_learned" or key == "trick" or key.begins_with("trick:")):
		return _base(str(goal.get("label", "Truques")), "Treine 3 acertos na Praça." if key == "trick_learned" else "Peça um truque; recarga por truque.", Places.goal_target(goal), "Ir")
	if type == "stat" and (key == "friend_level" or key.begins_with("friend_gift")):
		var id := key.trim_prefix("friend_gift:") if key.begins_with("friend_gift:") else "pipoca"
		var def := GameState.friend_def(id)
		var result := _base(str(goal.get("label", "Amigos do Tiro")), "Um petisco por amigo a cada 3 horas.", Places.goal_target(goal), "Ir")
		if GameState.inventory.count(str(def.likes)) == 0:
			return describe("item", str(def.likes), 1, trail)
		return result
	match type:
		"owned": return describe("upgrade", key, 1, trail)
		"skill": return describe("skill", key, amount, trail)
		"coins", "chapter": return describe(type, "", amount, trail)
		"quest": return describe("quest", key, 1, trail)
		"project": return describe("project", key, 1, trail)
		"growth": return describe("growth", key, 1, trail)
		"have", "deliver":
			var result := describe("item", key, amount, trail)
			if type == "deliver":
				result.detail = "Será entregue ao pegar o prêmio."
			return result
		"stat":
			if key == "shampoo_bath":
				var result := _base("Banho com xampu", "Aba Tiro → marque Com xampu e dê Banho.", {"screen": "pet"}, "Ir")
				if GameState.inventory.count("herb_shampoo") < 1:
					result.needs.append(_need("item", "herb_shampoo", 1))
				return result
			if key.begins_with("produce:"):
				for recipe_id: String in Database.recipes:
					if Database.recipe_output(Database.recipes[recipe_id]) == key.trim_prefix("produce:"):
						return describe("recipe", recipe_id, maxi(0, amount - GameState.goal_value(goal)), trail)
			if key.begins_with("activity:"):
				return describe("route", key.trim_prefix("activity:"), 1, trail)
			if key.begins_with("order:"):
				return describe("order", key.trim_prefix("order:"), 1, trail)
			if key == "orders":
				return describe("order", _best_order(), 1, trail)
			if key == "contracts":
				return _base("Contratos da sua banca", "Vila → Minha banca: prepare os produtos e entregue um contrato.", {"world": "village", "place": "stall"}, "Ir")
			if key.begins_with("harvest:"):
				return describe("crop", key.trim_prefix("harvest:"), 1, trail)
	var target := Places.goal_target(goal)
	var hints := {"talk:lais": "Toque na Laís, na Casa.", "talk:bloblo": "Toque na vovó Bloblo, no Sítio.", "open:bag": "Toque na aba Mochila.", "feed": "Dê comida na Tigela.", "pet": "Aba Tiro → faça carinho com o dedo.", "harvest": "Plante e colha.", "water": "Toque na plantinha com a gota.", "bathe": "Aba Tiro → Banho.", "play": "Aba Tiro → Brincar.", "trade": "Venda na Vila.", "sold": "Venda na Vila.", "explore": "Faça um passeio.", "walk": "Praça → Passeio: leve o Tiro para passear.", "talk:nina": "Toque na Nina, na Praça.", "produce": "Cozinhe no Fogão."}
	return _base(str(goal.get("label", "Seu objetivo")), hints.get(key, ""), target, "Ir")


static func _recipe(id: String, amount: int) -> Dictionary:
	var recipe: Dictionary = Database.recipes[id]
	var station: String = recipe.station
	var target := _focused("station:" + station, "recipe:" + id)
	var result := _base(Database.item_name(Database.recipe_output(recipe)), "", target, "Ir")
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
	result.detail = "Faça %d× · %s cada" % [batches, TimeText.short(int(recipe.seconds))]
	if pending > 0:
		result.detail += " · %d na fila" % pending
	if ready > 0 or (pending >= amount and pending > 0):
		result.action = "Pegar" if ready > 0 else "Ver"
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
		result["next"] = "Fila cheia: pegue ou espere"
		result["next_target"] = target
		result["next_action"] = "Ver"
	return result


## Consulta pura de uma obra: o que falta para começar ou o material restante da fase atual.
static func _project(id: String) -> Dictionary:
	var def := Database.project(id)
	var result := _base(str(def.get("name", id)), "Entregue o material da obra.", def.get("go", {}), "Ir")
	if def.is_empty():
		return result
	if GameState.projects.is_completed(id):
		result.detail = "Obra pronta!"
		return result
	if not GameState.project_started(id):
		result.detail = "Comece a obra."
		result.needs = _requirements(def.get("requirements", {}))
		result.needs.append(_need("coins", "", int(def.get("start_coins", 0))))
		return result
	_materials(result.needs, GameState.project_stage(id).get("remaining", {}))
	return result


static func _need(kind: String, id: String, amount: int) -> Dictionary:
	var have := 0
	var label := ""
	match kind:
		"produced":
			have = GameState.progress.stat("produce:" + id)
			label = "Fazer " + Database.item_name(id)
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
			label = _chapter_name(amount)
		"project":
			have = 1 if GameState.projects.is_completed(id) else 0
			label = str(Database.project(id).get("name", id))
		"growth":
			var phase_index: int = GameState.growth.phase_index(id)
			have = 1 if phase_index >= 0 and GameState.growth.phase_index() >= phase_index else 0
			label = "Quando ele for " + str(Database.growth.phases[phase_index].name) if phase_index >= 0 else "Crescimento"
		"stat":
			have = GameState.progress.stat(id)
			label = str(Database.progression.settings.stat_labels.get(id, id))
	return {"kind": kind, "id": id, "amount": amount, "have": have, "label": label}


static func _requirements(requirements: Dictionary) -> Array[Dictionary]:
	var needs: Array[Dictionary] = []
	for id: String in requirements.get("stats", {}):
		if GameState.progress.stat(id) < int(requirements.stats[id]):
			needs.append(_need("stat", id, int(requirements.stats[id])))
	for item: String in requirements.get("produced", {}):
		if GameState.progress.stat("produce:" + item) < int(requirements.produced[item]):
			needs.append(_need("produced", item, int(requirements.produced[item])))
	for id: String in requirements.get("owned", []):
		if not GameState.has_upgrade(id):
			needs.append(_need("upgrade", id, 1))
	for id: String in requirements.get("quests", []):
		if not GameState.progress.claimed_quests.has(id):
			needs.append(_need("quest", id, 1))
	for id: String in requirements.get("projects", []):
		if not GameState.projects.is_completed(id):
			needs.append(_need("project", id, 1))
	if GameState.progress.chapter_index() < int(requirements.get("chapter", 1)):
		needs.append(_need("chapter", "", int(requirements.chapter)))
	if requirements.has("growth") and int(_need("growth", str(requirements.growth), 1).have) < 1:
		needs.append(_need("growth", str(requirements.growth), 1))
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
				if Database.recipe_output(Database.recipes[id]) == item:
					candidate = {"kind": "recipe", "id": id}
					requirements = Database.recipes[id].get("requirements", {})
					station = Database.recipes[id].station
					break
		elif str(source.key).begins_with("activity:"):
			var route: String = str(source.key).trim_prefix("activity:")
			candidate = {"kind": "route", "id": route}
			requirements = Database.progression.activities[route].get("requirements", {})
		elif str(source.key).begins_with("walk:"):
			var walk_id := str(source.key).trim_prefix("walk:")
			candidate = {"kind": "walk", "id": walk_id}
			requirements = GameState.walk_def(walk_id).get("requirements", {})
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


## Passo de missão aberto agora (história ou linha de personagem) que paga este item ("" = nenhum).
static func _reward_step(item: String) -> String:
	for quest_id: String in GameState.progress.active_steps().values():
		if int(Database.quests[quest_id].get("rewards", {}).get("items", {}).get(item, 0)) > 0:
			return quest_id
	return ""


static func _best_order() -> String:
	var best := ""
	var score := INF
	for id: String in Database.progression.orders:
		if MarketUi.is_contract(id): continue
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
		"growth":
			return UiKit.ui_icon("tab_pet")
		"growth_req":
			for row: Dictionary in GameState.growth_info().requirements:
				if str(row.id) != id: continue
				match str(row.type):
					"deliver": return Database.item_icon(str(row.item))
					"feed": return UiKit.ui_icon("need_hunger")
					"owned": return UiKit.ui_icon(Database.progression.upgrades[str(row.upgrade)].get("icon", "tab_house"))
					"pillars": return UiKit.ui_icon(str(Database.growth.pillars[row.levels.keys()[0]].icon))
			return UiKit.ui_icon("tab_pet")
		"produced":
			return Database.item_icon(id)
		"quest":
			return ProgressionUi.goal_icon(ProgressionUi.current_goal(id))
		"item", "crop":
			return Database.item_icon(id)
		"recipe":
			return Database.item_icon(Database.recipe_output(Database.recipes[id]))
		"route":
			return UiKit.ui_icon(Database.progression.activities[id].get("icon", "action_play"))
		"walk":
			return UiKit.ui_icon("action_walk")
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
		"growth_req":
			return icon_for("growth_req", id)
		"growth":
			return icon_for("growth", id)
	return UiKit.ui_icon("tab_tasks")


static func _go(target: Dictionary) -> void:
	if target.has("claim"):
		var error := GameState.claim_quest(target.claim)
		if error != "":
			Events.toast_requested.emit(error)
	else:
		Places.go(target)


## "1 busca" / "3 buscas" (Natureza).
static func searches(count: int) -> String:
	return "1 busca" if count == 1 else "%d buscas" % count


## Nome do capítulo N (o jogador não vê o número).
static func _chapter_name(number: int) -> String:
	var chapters: Array = Database.progression.get("chapters", [])
	return str(chapters[number - 1].name) if number >= 1 and number <= chapters.size() else "Capítulo"


## Objetivo "o Tiro chega à fase X": os requisitos da próxima fase que ainda faltam, cada um tocável.
static func _growth_phase(id: String) -> Dictionary:
	var index: int = GameState.growth.phase_index(id)
	var name := str(Database.growth.phases[index].name) if index >= 0 else "Crescimento"
	var result := _base(name, "Veja o que ele precisa para crescer.", {"growth": true}, "Ir")
	if index < 0 or GameState.growth.phase_index() >= index:
		result.detail = "Ele já cresceu!"
		return result
	var info := GameState.growth_info()
	if info.ready:
		result.detail = "Tudo pronto: toque em Crescer!"
		return result
	for row: Dictionary in info.requirements:
		if not row.done:
			result.needs.append({"kind": "growth_req", "id": str(row.id), "amount": int(row.need), "have": mini(int(row.have), int(row.need)), "label": str(row.label)})
	return result


## Cada requisito indica uma ação disponível agora; nunca conta nem entrega pela consulta.
static func _growth_requirement(id: String, trail: Array[String]) -> Dictionary:
	for row: Dictionary in GameState.growth_info().requirements:
		if row.id != id: continue
		var result := _base(str(row.label), "Continue cuidando do Tiro.", {"screen": "pet"}, "Ir")
		match str(row.type):
			"owned": result = describe("upgrade", str(row.upgrade), 1, trail)
			"project": result = describe("project", str(row.project), 1, trail)
			"quest": result = describe("quest", str(row.quest), 1, trail)
			"deliver":
				result = describe("item", str(row.item), int(row.need) - int(row.have), trail)
				if GameState.inventory.count(str(row.item)) > 0:
					result = _base(str(row.label), "Você já tem. Volte ao crescimento e toque em Dar.", {"growth": true}, "Ir")
			"feed":
				result.detail = "Dê comida ao Tiro nesta fase."
				if row.item == "favorite" and not GameState.favorite_found():
					result.detail = "Ele ainda não provou a favorita. Experimente comidas novas."
					for food: String in GameState.untasted_foods().slice(0, 4):
						result.needs.append(_need("item", food, 1))
				elif row.item != "any":
					var food_id := GameState.favorite_food() if row.item == "favorite" else str(row.item)
					result = describe("item", food_id, 1, trail)
					if GameState.inventory.count(food_id) > 0:
						result = _base(str(row.label), "Tiro → Comida: dê " + Database.item_name(food_id), {"screen": "pet"}, "Ir")
			"stat": result = describe("stat", str(row.counter), int(row.need), trail)
			"collection": result = _base(str(row.label), "Faça na Costura da Praça.", {"world": "park", "place": "sewing"}, "Ir")
			"pillars":
				for pillar: String in row.levels:
					if int(GameState.growth_info().pillars[pillar].level) >= int(row.levels[pillar]): continue
					var hints := {"body": "Dê comida adequada à fase.", "coat": "Dê um banho quando ele precisar.", "smart": "Brinque com o Tiro ou cave um achado.", "brave": "Brinque ou faça carinho no Tiro."}
					result.detail = "%s %d: %s" % [Database.growth.pillars[pillar].name, row.levels[pillar], hints[pillar]]
					break
		result.title = str(row.label)
		result.detail += " (%d/%d%s)" % [mini(int(row.have), int(row.need)) if not row.done else int(row.need), row.need, " ✓" if row.done else ""]
		result.target = result.get("next_target", result.target)
		result.action = "Ir"
		result.erase("next_action")
		return result
	return _base("Crescimento", "Veja a fase atual.", {"growth": true}, "Ir")
