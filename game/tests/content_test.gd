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
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	var progress: RefCounted = root.get_node("GameState").get("progress")
	var quests: Dictionary = db.get("quests")
	var data: Dictionary = db.get("progression")
	for c in range(1, data.chapters.size() + 1):
		var ids: Array = progress.main_quests(c)
		check(ids.size() >= 3 and ids.size() <= 5, "capítulo %d deve ter 3–5 passos" % c)
		for i in ids.size():
			check(int(quests[ids[i]].get("order", 0)) == i + 1, "ordem repetida ou lacuna: " + ids[i])
		if not ids.is_empty():
			var last: Dictionary = quests[ids.back()]
			check(last.goals.any(func(g: Dictionary) -> bool: return g.type == "owned" and g.key == data.chapters[c - 1].target), "último passo precisa da construção-alvo no capítulo %d" % c)
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
					check(key in ["feed", "play", "bathe", "pet", "harvest", "produce", "trade", "sold", "orders", "explore", "build", "quests"] or key.begins_with("produce:") or key.begins_with("activity:") or key.begins_with("order:") or key.begins_with("harvest:"), id + ": contador desconhecido " + key)
					if key.begins_with("harvest:"):
						check(db.get("crops").has(key.trim_prefix("harvest:")), id + ": cultura " + key)
					if key.begins_with("produce:"):
						check(db.get("recipes").values().any(func(r: Dictionary) -> bool: return r.output == key.trim_prefix("produce:")), id + ": produção " + key)
					if key.begins_with("activity:"):
						check(data.activities.has(key.trim_prefix("activity:")), id + ": rota " + key)
					if key.begins_with("order:"):
						check(data.orders.has(key.trim_prefix("order:")), id + ": pedido " + key)
				"coins", "chapter":
					check(int(g.get("target", 0)) > 0, id + ": alvo obrigatório")
				_:
					check(false, id + ": tipo desconhecido " + str(g.type))
		for reward: String in q.get("rewards", {}).get("collections", []):
			check(db.get("collections").has(reward), id + ": coleção " + reward)
		check(q.get("kind", "") == "main", id + ": só existem missões de história (diárias/semanais ficam em routines.json)")
	# Atributos: só os 4 do jogo em qualquer "skill", "skill_xp" ou requisito.
	var skill_refs: Array[String] = []
	for source: Dictionary in [quests, data, db.get("recipes"), db.get("crops")]:
		_collect_skills(source, skill_refs)
	for ref in skill_refs:
		check(data.skills.has(ref), "atributo inexistente: " + ref)
	check(data.skills.size() == 4, "o jogo tem 4 atributos")
	for id: String in data.upgrades:
		check(not data.upgrades[id].get("requirements", {}).has("skills"), id + ": construção não exige nível (a história não trava)")
	# Diárias e semanais: contador conhecido, alvo, recompensa e quantidade sorteável no começo.
	for kind: String in ["daily", "weekly"]:
		var group: Dictionary = db.get("routines")[kind]
		var open := 0
		for id: String in group.missions:
			var m: Dictionary = group.missions[id]
			var key: String = m.goal.key
			check(key in ["feed", "play", "bathe", "harvest", "produce", "sold", "orders", "explore"] or key.begins_with("activity:") or key.begins_with("produce:"), kind + "/" + id + ": contador " + key)
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
				"inventory", "feed", "sleep", "farm": pass
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


func _validate_targets() -> void:
	var places: Script = load("res://scripts/ui/places.gd")
	var state: Node = root.get_node("GameState")
	var quests: Dictionary = db.get("quests")
	for chapter in range(1, db.get("progression").chapters.size() + 1):
		state.call("reset")
		for previous in range(1, chapter):
			for id: String in state.get("progress").main_quests(previous):
				state.get("progress").claimed_quests[id] = true
		for id: String in quests:
			var q: Dictionary = quests[id]
			# Percorre os passos em ordem mesmo quando o JSON está em outra ordem.
			if q.get("kind", "side") == "main":
				if int(q.chapter) != chapter:
					continue
				for before: String in state.get("progress").main_quests(chapter):
					if int(quests[before].order) < int(q.order):
						state.get("progress").claimed_quests[before] = true
					else:
						state.get("progress").claimed_quests.erase(before)
			elif not state.call("quest_unlocked", id):
				continue
			# Missão de compra recebida implica a construção adquirida. Recria
			# as posses de cada passo para validar lugares com requisito owned.
			state.get("progress").owned.clear()
			for claimed_id: String in state.get("progress").claimed_quests:
				for acquired: Dictionary in quests[claimed_id].goals:
					if acquired.type == "owned":
						state.get("progress").owned[acquired.key] = true
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
		check(target.screen in ["pet", "tasks"], id + ": aba inexistente")
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
	else:
		check(w.places.has(place), id + ": lugar inexistente")
		check(state.call("requirement_error", w.places.get(place, {}).get("requirements", {})) == "", id + ": destino em lugar ainda fechado")
	check(state.call("requirement_error", w.get("requirements", {})) == "", id + ": destino em mundo ainda fechado")
