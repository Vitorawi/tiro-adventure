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
	# Diárias e semanais: contador conhecido, alvo, recompensa e quantidade sorteável no começo.
	for kind: String in ["daily", "weekly"]:
		var group: Dictionary = db.get("routines")[kind]
		var open := 0
		for id: String in group.missions:
			var m: Dictionary = group.missions[id]
			var key: String = m.goal.key
			check(key in ["feed", "play", "bathe", "harvest", "produce", "sold", "orders", "explore"] or key.begins_with("activity:"), kind + "/" + id + ": contador " + key)
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
				"travel", "build": check(db.get("worlds").has(arg), place + ": mundo inexistente")
				"routes": check(data.activities.values().any(func(a: Dictionary) -> bool: return a.place == arg), place + ": grupo de rotas inexistente")
				"inventory", "feed", "sleep", "farm", "sell", "orders": pass
				_: check(false, place + ": painel desconhecido")
			if p.has("upgrade"):
				check(data.upgrades.has(p.upgrade), place + ": construção inexistente")
	for id: String in data.activities:
		var a: Dictionary = data.activities[id]
		if a.place in ["walk", "mine"]:
			check(int(a.requirements.get("chapter", 1)) >= 3, id + ": rota antes da Trilha abrir")
	for id: String in data.orders:
		check("first_harvest" in data.orders[id].requirements.get("quests", []), id + ": pedido antes da Vila abrir")
	_validate_targets()
	print("CONTENT TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)


func _validate_targets() -> void:
	var places: Script = load("res://scripts/ui/places.gd")
	var state: Node = root.get_node("GameState")
	var quests: Dictionary = db.get("quests")
	for chapter in range(1, 10):
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
	else:
		check(w.places.has(place), id + ": lugar inexistente")
	check(state.call("requirement_error", w.get("requirements", {})) == "", id + ": destino em mundo ainda fechado")
