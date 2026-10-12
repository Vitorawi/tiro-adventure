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
					if key.begins_with("produce:"):
						check(db.get("recipes").values().any(func(r: Dictionary) -> bool: return r.output == key.trim_prefix("produce:")), id + ": produção " + key)
					if key.begins_with("activity:"):
						check(data.activities.has(key.trim_prefix("activity:")), id + ": rota " + key)
					if key.begins_with("order:"):
						check(data.orders.has(key.trim_prefix("order:")), id + ": pedido " + key)
		for reward: String in q.get("rewards", {}).get("collections", []):
			check(db.get("collections").has(reward), id + ": coleção " + reward)
	for world: String in db.get("worlds"):
		var w: Dictionary = db.get("worlds")[world]
		for npc: String in w.get("npcs", []):
			check(db.get("npcs").has(npc), world + ": NPC " + npc)
			for service: String in db.get("npcs").get(npc, {}).get("services", []):
				check(w.places.has(service), npc + ": serviço " + service)
		for place: String in w.places:
			var p: Dictionary = w.places[place]
			if p.has("upgrade"):
				check(data.upgrades.has(p.upgrade), place + ": construção inexistente")
	for id: String in data.activities:
		var a: Dictionary = data.activities[id]
		if a.place in ["walk", "mine"]:
			check(int(a.requirements.get("chapter", 1)) >= 3, id + ": rota antes da Trilha abrir")
	for id: String in data.orders:
		check("first_harvest" in data.orders[id].requirements.get("quests", []), id + ": pedido antes da Vila abrir")
	print("CONTENT TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
