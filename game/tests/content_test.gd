extends SceneTree
## Validação estrutural do conteúdo; destinos são conferidos quando disponíveis.
var failures: int = 0
var db: Node

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, context: String) -> void:
	if not ok:
		failures += 1
		push_error("Conteúdo: " + context)

func _run() -> void:
	db = root.get_node("Database")
	for id: String in db.get("animals"):
		var animal: Dictionary = db.get("animals")[id]
		check(db.get("stations").has(animal.station), id + ": abrigo existente")
		check(int(animal.price) > 0, id + ": preço positivo")
		check(ResourceLoader.exists(animal.sprite), id + ": sprite existente")
		check(int(db.get("stations")[animal.station].get("animal_capacity", 0)) > 0, id + ": capacidade do abrigo")
	# Geladeira guarda comida e ingredientes (ovo, leite...); colheitas vão ao silo, materiais ao armazém.
	var builder: Script = load("res://scripts/ui/sheet_builder.gd")
	for id: String in ["vegetable_soup", "egg", "milk", "flour", "cheese"]:
		check(builder.call("_fits_fridge", id), id + ": cabe na geladeira")
	for id: String in ["dog_food", "carrot", "apple", "wood", "stone", "plank", "brick", "copper", "crystal", "fiber", "fabric", "hardwood", "treat_box", "accessory_set"]:
		check(not builder.call("_fits_fridge", id), id + ": não cabe na geladeira")
	# Cada abrigo abre só o próprio painel (galinheiro ≠ curral).
	var farm_room: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms/farm.json"))
	for object: Dictionary in farm_room.objects:
		var shelter: String = object.get("animal_station", object.get("station", ""))
		if shelter != "" and db.get("stations").get(shelter, {}).get("kind", "") == "animal":
			check(object.get("action", "") == "place:" + shelter, str(object.get("id", "")) + ": abre só o painel de " + shelter)
			check(db.get("worlds").farm.places.has(shelter) and db.get("worlds").farm.places[shelter].panel == "station:" + shelter, shelter + ": lugar próprio")
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var progress: RefCounted = root.get_node("GameState").get("progress")
	var quests: Dictionary = db.get("quests")
	var data: Dictionary = db.get("progression")
	for c in range(1, data.chapters.size() + 1):
		var ids: Array = progress.main_quests(c)
		check(ids.size() >= 2 and ids.size() <= 5, "capítulo %d deve ter 2–5 passos" % c)
		for i in ids.size():
			check(int(quests[ids[i]].get("order", 0)) == (i + 1) * 10, "ordem repetida ou lacuna: " + ids[i])
		if not ids.is_empty() and str(data.chapters[c - 1].target) != "":
			# Capítulo com construção-alvo: algum passo pede essa compra.
			check(ids.any(func(q: String) -> bool: return quests[q].goals.any(func(g: Dictionary) -> bool: return g.type == "owned" and g.key == data.chapters[c - 1].target)), "capítulo %d precisa de um passo com a construção-alvo" % c)
	# Linhas de NPC (vovó Bloblo...): passos em ordem 1..N, sem lacunas.
	for line: String in progress.lines():
		var steps: Array = progress.line_quests(line)
		for i in steps.size():
			check(int(quests[steps[i]].order) == (i + 1) * 10, line + ": ordem repetida ou lacuna: " + steps[i])
	for id: String in quests:
		var q: Dictionary = quests[id]
		check(db.get("npcs").has(q.npc), id + ": NPC inexistente")
		if q.get("kind", "side") == "main":
			check(int(q.get("chapter", 0)) >= 1 and int(q.get("chapter", 0)) <= data.chapters.size() and q.has("order"), id + ": chapter/order obrigatório")
			check(not q.has("requires"), id + ": main não usa requires")
		for previous: String in q.get("requires", []):
			check(quests.has(previous), id + ": requires inexistente")
		for g: Dictionary in q.goals:
			var key: String = g.get("key", "")
			match str(g.type):
				"have", "deliver": check(db.get("items").has(key), id + ": item " + key)
				"owned": check(data.upgrades.has(key), id + ": construção " + key)
				"skill": check(data.skills.has(key), id + ": atributo " + key)
				"stat":
					check(key in ["feed", "play", "bathe", "pet", "harvest", "water", "produce", "trade", "sold", "orders", "explore", "build", "quests", "open:bag"] or (key.begins_with("talk:") and db.get("npcs").has(key.trim_prefix("talk:"))) or (key.begins_with("open:") and db.get("worlds").has(key.trim_prefix("open:"))) or key.begins_with("produce:") or key.begins_with("activity:") or key.begins_with("order:") or key.begins_with("harvest:"), id + ": contador desconhecido " + key)
					if key.begins_with("harvest:"):
						check(db.get("crops").has(key.trim_prefix("harvest:")), id + ": cultura " + key)
					if key.begins_with("produce:"):
						check(db.get("recipes").values().any(func(r: Dictionary) -> bool: return r.output == key.trim_prefix("produce:")), id + ": produção " + key)
					if key.begins_with("activity:"):
						check(data.activities.has(key.trim_prefix("activity:")), id + ": rota " + key)
					if key.begins_with("order:"):
						check(data.orders.has(key.trim_prefix("order:")), id + ": pedido " + key)
				"quest":
					check(quests.has(key) and quests[key].get("kind", "") in ["main", "line"], id + ": cruzamento com missão inexistente " + key)
				"coins", "chapter":
					check(int(g.get("target", 0)) > 0, id + ": alvo obrigatório")
				_:
					check(false, id + ": tipo desconhecido " + str(g.type))
		for reward: String in q.get("rewards", {}).get("collections", []):
			check(db.get("collections").has(reward), id + ": coleção " + reward)
		check(q.get("kind", "") in ["main", "line"], id + ": só existem história e linhas de NPC (diárias/semanais ficam em routines.json)")
		if q.get("kind", "") == "line":
			check(q.has("line") and q.has("order") and not q.has("chapter"), id + ": linha precisa de line/order")
	# Atributos: só os 4 do jogo em qualquer "skill", "skill_xp" ou requisito.
	var skill_refs: Array[String] = []
	for source: Dictionary in [quests, data, db.get("recipes"), db.get("crops")]:
		_collect_skills(source, skill_refs)
	for ref in skill_refs:
		check(data.skills.has(ref), "atributo inexistente: " + ref)
	check(data.skills.size() == 4, "o jogo tem 4 atributos")
	for id: String in data.upgrades:
		check(not data.upgrades[id].get("requirements", {}).has("skills"), id + ": construção não exige nível (a história não trava)")
	# Atributos só aparecem no capítulo 6: conteúdo dos capítulos 1–5 não pode depender deles.
	# Vale se exigir também capítulo ≥ 6 ou uma construção que pede materiais (só existe depois).
	var gated: Array = []
	for source: Dictionary in [db.get("recipes"), db.get("crops")]:
		for id: String in source:
			var entry_reqs: Dictionary = source[id].get("requirements", {}).duplicate(true)
			if source[id].has("station"):
				entry_reqs["owned"] = entry_reqs.get("owned", []) + [source[id].station]
			gated.append([id, entry_reqs])
	for id: String in data.get("activities", {}):
		gated.append([id, data.activities[id].get("requirements", {})])
	for entry: Array in gated:
		var reqs: Dictionary = entry[1]
		if not reqs.has("skills"):
			continue
		var late := int(reqs.get("chapter", 0)) >= 6
		for owned_id: String in reqs.get("owned", []):
			late = late or not data.upgrades.get(owned_id, {}).get("materials", {}).is_empty()
		check(late, str(entry[0]) + ": exige atributo (skills) antes do capítulo 6; use missão/capítulo/construção com materiais")
	# Diárias e semanais: contador conhecido, alvo, recompensa e quantidade sorteável no começo.
	for kind: String in ["daily", "weekly"]:
		var group: Dictionary = db.get("routines")[kind]
		var open := 0
		for id: String in group.missions:
			var m: Dictionary = group.missions[id]
			var key: String = m.goal.key
			check(key in ["feed", "play", "bathe", "harvest", "water", "produce", "sold", "orders", "explore"] or key.begins_with("activity:") or key.begins_with("produce:"), kind + "/" + id + ": contador " + key)
			if key.begins_with("produce:"):
				check(db.get("items").has(key.trim_prefix("produce:")), kind + "/" + id + ": produto inexistente")
				check(db.get("recipes").values().any(func(recipe: Dictionary) -> bool: return recipe.output == key.trim_prefix("produce:")), kind + "/" + id + ": produto sem receita")
			if key.begins_with("activity:"):
				check(data.activities.has(key.trim_prefix("activity:")), kind + "/" + id + ": rota " + key)
			check(int(m.goal.get("target", 0)) > 0 and int(m.rewards.get("coins", 0)) > 0, kind + "/" + id + ": alvo e moedas")
			for reward: String in m.rewards.get("collections", []):
				check(db.get("collections").has(reward), kind + "/" + id + ": coleção " + reward)
			if m.get("requirements", {}).is_empty():
				open += 1
		check(open >= int(group.count), kind + ": precisa de modelos sem requisito para o primeiro sorteio")
	for world: String in db.get("worlds"):
		var w: Dictionary = db.get("worlds")[world]
		for npc: String in w.get("npcs", []):
			check(db.get("npcs").has(npc), world + ": NPC " + npc)
			for service: String in db.get("npcs").get(npc, {}).get("services", []):
				check(w.places.has(service), npc + ": serviço " + service)
		for place: String in w.places:
			var p: Dictionary = w.places[place]
			var panel: String = p.get("panel", "")
			var arg := panel.get_slice(":", 1)
			match panel.get_slice(":", 0):
				"station": check(db.get("stations").has(arg), place + ": estação inexistente")
				"stations":
					for id in arg.split("+"):
						check(db.get("stations").has(id), place + ": estação inexistente " + id)
				"travel": check(db.get("worlds").has(arg), place + ": mundo inexistente")
				"routes", "nature":
					for group in arg.split("+"):
						check(data.activities.values().any(func(a: Dictionary) -> bool: return a.place == group), place + ": grupo de rotas inexistente " + group)
				"market": check(arg in ["sell", "orders"], place + ": aba da feira")
				"storage": check(data.storage.has(arg), place + ": depósito inexistente")
				"inventory", "fridge", "feed", "sleep", "farm": pass
				_: check(false, place + ": painel desconhecido")
			if p.has("upgrade"):
				check(data.upgrades.has(p.upgrade), place + ": construção inexistente")
			for id: String in p.get("upgrades", []):
				check(data.upgrades.has(id), place + ": construção inexistente " + id)
		# Simplicidade: no máximo 4 lugares visíveis por mundo (fora viagens).
		var visible: Array = w.places.values().filter(func(p: Dictionary) -> bool: return not p.get("hidden", false) and not str(p.get("panel", "")).begins_with("travel"))
		check(visible.size() <= 4, world + ": mais de 4 lugares")
	check(db.get("worlds").size() == 4, "o jogo tem 4 mundos")
	# Revelar aos poucos: personagem aparece até o capítulo da primeira missão dele.
	for npc: String in db.get("npcs"):
		var from := int(db.get("npcs")[npc].get("requirements", {}).get("chapter", 1))
		for id: String in quests:
			check(int(quests[id].get("chapter", 99)) >= from or quests[id].npc != npc, npc + ": aparece depois da missão " + id)
	for feature: String in ["bag", "daily", "weekly", "skills"]:
		check(data.get("features", {}).has(feature), "recurso usado pelo código: " + feature)
	# Toda construção tem um lugar onde é comprada (fora a escritura do sítio, que fica nos canteiros).
	for id: String in data.upgrades:
		check(id == "farm" or db.call("place_of_upgrade", id)[0] != "", id + ": sem lugar para comprar")
	for id: String in data.activities:
		var a: Dictionary = data.activities[id]
		if a.place in ["walk", "mine"]:
			check(int(a.requirements.get("chapter", 1)) >= 3, id + ": rota antes da Trilha abrir")
	for id: String in data.get("nature_resources", {}):
		check(db.get("items").has(id), id + ": material de coleta existente")
		for route: String in data.nature_resources[id].routes:
			check(data.activities.has(route) and data.activities[route].rewards.get("items", {}).has(id), id + ": rota rende este material")
	for id: String in data.get("nature_sites", {}):
		var site: Dictionary = data.nature_sites[id]
		check(site.levels.size() == site.level_upgrades.size(), id + ": cadeia de níveis completa")
		check(int(site.levels[0].xp) == 0 and int(site.xp_per_collection) > 0, id + ": XP de uso válido")
		for level in range(1, site.levels.size()):
			check(int(site.levels[level].xp) > int(site.levels[level - 1].xp), id + ": níveis de XP crescentes")
			check(int(site.levels[level].slots) == level + 1, id + ": vaga acompanha nível")
		check(site.slot_upgrades.size() == 2, id + ": começa com uma vaga e libera mais duas")
		for upgrade: String in site.slot_upgrades + site.level_upgrades:
			check(data.upgrades.has(upgrade), id + ": compra existente " + upgrade)
		for resource: String in site.resources:
			check(data.nature_resources.has(resource), id + ": material com coleta definida")
	for id: String in data.orders:
		check("first_harvest" in data.orders[id].requirements.get("quests", []), id + ": pedido antes da Vila abrir")
	_validate_targets()
	print("CONTENT TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)


## Junta os ids de atributo usados em "skill", "skill_xp" e "requirements.skills" (fora das definições).
func _collect_skills(value: Variant, refs: Array[String]) -> void:
	if value is Array:
		for entry: Variant in value:
			_collect_skills(entry, refs)
	if not value is Dictionary:
		return
	for key: Variant in value:
		var child: Variant = value[key]
		if key == "skill" and child is String:
			refs.append(child)
		elif key == "skill_xp" and child is Dictionary:
			refs.append_array(child.keys())
		elif key == "skills" and child is Dictionary and child.values().all(func(v: Variant) -> bool: return v is float or v is int):
			refs.append_array(child.keys())
		elif key == "type" and child == "skill":
			refs.append(str(value.get("key", "")))
		_collect_skills(child, refs)


## Simula um jogador que avança as linhas de NPC em paralelo com a história: a cada capítulo,
## cada linha anda até onde os requisitos deixam. Todo destino precisa existir e estar aberto.
func _validate_targets() -> void:
	var state: Node = root.get_node("GameState")
	var progress: RefCounted
	var quests: Dictionary = db.get("quests")
	var line_done: Dictionary = {}
	for chapter in range(1, db.get("progression").chapters.size() + 1):
		state.call("reset")
		progress = state.get("progress")  # reset cria um estado novo
		for previous in range(1, chapter):
			for id: String in progress.main_quests(previous):
				progress.claimed_quests[id] = true
		for id: String in line_done:
			progress.claimed_quests[id] = true
		_sync_owned(state)
		for line: String in progress.lines():
			for step: String in progress.line_quests(line):
				if progress.claimed_quests.has(step):
					continue
				if state.call("requirement_error", quests[step].get("requirements", {})) != "":
					break
				_validate_quest(step, state)
				progress.claimed_quests[step] = true
				line_done[step] = true
				_sync_owned(state)
		var lines_claimed: Dictionary = progress.claimed_quests.duplicate()
		for id: String in progress.main_quests(chapter):
			progress.claimed_quests = lines_claimed.duplicate()
			for before: String in progress.main_quests(chapter):
				if int(quests[before].order) < int(quests[id].order):
					progress.claimed_quests[before] = true
			_sync_owned(state)
			_validate_quest(id, state)


## Missão de compra recebida implica a construção adquirida.
func _sync_owned(state: Node) -> void:
	var progress: RefCounted = state.get("progress")
	progress.owned.clear()
	for claimed_id: String in progress.claimed_quests:
		for acquired: Dictionary in db.get("quests")[claimed_id].goals:
			if acquired.type == "owned":
				progress.owned[acquired.key] = true


func _validate_quest(id: String, state: Node) -> void:
	var places: Script = load("res://scripts/ui/places.gd")
	var q: Dictionary = db.get("quests")[id]
	var npc_world: String = db.call("npc_world", q.npc)
	check(npc_world != "", id + ": NPC sem mundo")
	if npc_world != "":
		check(state.call("requirement_error", db.get("worlds")[npc_world].get("requirements", {})) == "", id + ": NPC em mundo fechado")
	for goal: Dictionary in q.goals:
		var target: Dictionary = places.call("goal_target", goal)
		check(not target.is_empty(), id + ": objetivo sem destino")
		_validate_target(target, id, state)
	if q.has("go"):
		_validate_target(q.go, id + ": go", state)


func _validate_target(target: Dictionary, id: String, state: Node) -> void:
	if target.has("screen"):
		check(target.screen in ["pet", "tasks", "bag", "map"], id + ": aba inexistente")
		return
	var world: String = target.get("world", "")
	check(db.get("worlds").has(world), id + ": mundo inexistente")
	if not db.get("worlds").has(world):
		return
	var w: Dictionary = db.get("worlds")[world]
	var place: String = target.get("place", "")
	if place.begins_with("buy:"):
		check(db.get("progression").upgrades.has(place.trim_prefix("buy:")), id + ": compra inexistente")
	elif place.begins_with("npc:"):
		check(place.trim_prefix("npc:") in w.npcs, id + ": personagem fora do mundo")
	elif place.begins_with("market:"):
		check(db.call("place_with_panel", "sell")[0] == world, id + ": feira fora do mundo")
	elif place == "":
		check(state.call("requirement_error", w.get("requirements", {})) == "", id + ": mundo ainda fechado")
	else:
		check(w.places.has(place), id + ": lugar inexistente")
		check(state.call("requirement_error", w.places.get(place, {}).get("requirements", {})) == "", id + ": destino em lugar ainda fechado")
	check(state.call("requirement_error", w.get("requirements", {})) == "", id + ": destino em mundo ainda fechado")
