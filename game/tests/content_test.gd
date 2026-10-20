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
	for id: String in db.get("items"):
		check(ResourceLoader.exists(db.get("items")[id].icon), id + ": ícone existente")
	for id: String in db.get("crops"):
		check(ResourceLoader.exists(db.get("crops")[id].sprite), id + ": planta existente")
	for id: String in db.get("recipes"):
		check(db.get("stations").has(db.get("recipes")[id].station), id + ": estação existente")
	for id: String in db.get("animals"):
		var animal: Dictionary = db.get("animals")[id]
		check(db.get("stations").has(animal.station), id + ": abrigo existente")
		check(int(animal.price) > 0, id + ": preço positivo")
		check(ResourceLoader.exists(animal.sprite), id + ": sprite existente")
		check(int(db.get("stations")[animal.station].get("animal_capacity", 0)) > 0, id + ": capacidade do abrigo")
	# Caminha do Tiro: objeto na casa com sprite; o presente não se vende.
	var house_room: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/rooms/house.json"))
	var bed_objects: Array = house_room.objects.filter(func(o: Dictionary) -> bool: return o.id == "dog_bed")
	check(bed_objects.size() == 1 and ResourceLoader.exists(bed_objects[0].sprite), "dog_bed: sprite existente na casa")
	check(house_room.points.has("bed_sleep") and house_room.points.has("bed_approach"), "dog_bed: pontos de dormir")
	check(not db.get("items")["bed_gift"].has("sell_price"), "bed_gift: presente não se vende")
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
		check(ids.size() >= 2 and ids.size() <= 7, "capítulo %d deve ter 2–7 passos" % c)
		for i in ids.size():
			check(int(quests[ids[i]].get("order", 0)) > (int(quests[ids[i - 1]].order) if i > 0 else 0), "ordem positiva, crescente e única: " + ids[i])
		if not ids.is_empty() and str(data.chapters[c - 1].target) != "":
			# Capítulo com construção-alvo: algum passo pede essa compra.
			check(ids.any(func(q: String) -> bool: return quests[str(quests[q].get("shared_with", q))].goals.any(func(g: Dictionary) -> bool: return g.type == "owned" and g.key == data.chapters[c - 1].target)), "capítulo %d precisa de um passo com a construção-alvo" % c)
	# Linhas de NPC: ordens crescentes permitem inserir passos sem renumerar a história.
	for line: String in progress.lines():
		var steps: Array = progress.line_quests(line)
		for i in steps.size():
			check(int(quests[steps[i]].order) > (int(quests[steps[i - 1]].order) if i > 0 else 0), line + ": ordem positiva, crescente e única: " + steps[i])
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
					check(key in ["feed", "play", "bathe", "pet", "harvest", "water", "produce", "trade", "sold", "orders", "contracts", "storage_upgrades", "explore", "build", "quests", "open:bag", "find", "walk", "walk_item", "walk_rare", "equip", "sew", "friend_gift", "friend_level", "trick", "trick_learned", "shampoo_bath"] or (key.begins_with("friend_gift:") and db.get("friends").friends.has(key.trim_prefix("friend_gift:"))) or key.begins_with("walk:") or (key.begins_with("talk:") and db.get("npcs").has(key.trim_prefix("talk:"))) or (key.begins_with("open:") and db.get("worlds").has(key.trim_prefix("open:"))) or key.begins_with("produce:") or key.begins_with("activity:") or key.begins_with("order:") or key.begins_with("harvest:") or key.begins_with("find:") or key.begins_with("wish_item:") or (key.begins_with("project_use:") and not db.call("project", key.trim_prefix("project_use:")).is_empty()), id + ": contador desconhecido " + key)
					if key.begins_with("harvest:"):
						check(db.get("crops").has(key.trim_prefix("harvest:")), id + ": cultura " + key)
					if key.begins_with("produce:"):
						check(db.get("recipes").values().any(func(r: Dictionary) -> bool: return r.get("output", r.get("output_collection", "")) == key.trim_prefix("produce:")), id + ": produção " + key)
					if key.begins_with("activity:"):
						check(data.activities.has(key.trim_prefix("activity:")), id + ": rota " + key)
					if key.begins_with("order:"):
						check(data.orders.has(key.trim_prefix("order:")), id + ": pedido " + key)
				"quest":
					check(quests.has(key) and quests[key].get("kind", "") in ["main", "line"], id + ": cruzamento com missão inexistente " + key)
				"project": check(db.get("projects").get("projects", {}).has(key), id + ": obra " + key)
				"growth": check(db.get("growth").phases.any(func(phase: Dictionary) -> bool: return str(phase.id) == key), id + ": fase " + key)
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
			check(key in ["feed", "play", "bathe", "harvest", "water", "produce", "sold", "orders", "contracts", "explore", "wish", "find", "walk", "walk_item", "walk_rare", "equip", "sew", "friend_gift", "friend_level", "trick", "trick_learned", "care_useful", "production_jobs"] or key.begins_with("activity:") or key.begins_with("produce:") or key.begins_with("harvest:"), kind + "/" + id + ": contador " + key)
			if key.begins_with("harvest:"):
				check(db.get("crops").has(key.trim_prefix("harvest:")), kind + "/" + id + ": cultura inexistente")
			if key.begins_with("produce:"):
				check(db.get("items").has(key.trim_prefix("produce:")), kind + "/" + id + ": produto inexistente")
				check(db.get("recipes").values().any(func(recipe: Dictionary) -> bool: return recipe.get("output", recipe.get("output_collection", "")) == key.trim_prefix("produce:")), kind + "/" + id + ": produto sem receita")
			if key.begins_with("activity:"):
				check(data.activities.has(key.trim_prefix("activity:")), kind + "/" + id + ": rota " + key)
			check(int(m.goal.get("target", 0)) > 0 and int(m.rewards.get("coins", 0)) > 0, kind + "/" + id + ": alvo e moedas")
			var targets: Dictionary = m.goal.get("targets", {})
			check(int(targets.get("start", 0)) > 0 and int(targets.get("middle", 0)) >= int(targets.start) and int(targets.get("community", 0)) >= int(targets.middle), kind + "/" + id + ": metas por fase (começo ≤ meio ≤ comunidade)")
			for reward: String in m.rewards.get("collections", []):
				check(db.get("collections").has(reward), kind + "/" + id + ": coleção " + reward)
			if m.get("requirements", {}).is_empty():
				open += 1
		check(open >= 2, kind + ": precisa de modelos sem requisito para o primeiro sorteio (o resto só entra quando acessível)")
		for id: String in group.get("legacy", {}):
			check(not group.missions.has(id) or id in ["harvest", "cook", "order", "big_harvest", "chef_week", "tiro_walk"], kind + "/" + id + ": legado com o mesmo id só se reaproveitado no catálogo R1")
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
				"inventory", "fridge", "feed", "sleep", "farm", "greenhouse", "sell", "orders", "contracts", "walks", "petshop", "friends", "tricks", "community": pass
				"project": check(db.call("project", arg).size() > 0 and str(db.call("project", arg).get("world", "")) == world, place + ": obra inexistente ou de outro mundo")
				"house": check(world == "house" and arg == "bed", place + ": painel da Casa inválido")
				_: check(false, place + ": painel desconhecido")
			if p.has("upgrade"):
				check(data.upgrades.has(p.upgrade), place + ": construção inexistente")
			for id: String in p.get("upgrades", []):
				check(data.upgrades.has(id), place + ": construção inexistente " + id)
		# Simplicidade: no máximo 4 lugares visíveis por mundo (fora viagens).
		var visible: Array = w.places.values().filter(func(p: Dictionary) -> bool: return not p.get("hidden", false) and not str(p.get("panel", "")).begins_with("travel"))
		check(visible.size() <= 4, world + ": mais de 4 lugares")
	check(db.get("worlds").size() == 5, "o jogo tem 5 mundos")
	# Praça: sala com pontos para o Tiro, para cada personagem e para o passeio; postais dos passeios existem.
	var park_room: Dictionary = db.call("room", "park")
	check(ResourceLoader.exists(park_room.get("background", "")), "Praça: fundo")
	check(park_room.get("points", {}).has("dog_start") and park_room.get("points", {}).has("walk_marker"), "Praça: dog_start e walk_marker")
	for npc: String in db.get("worlds").park.npcs:
		check(park_room.get("points", {}).has("npc_" + npc), "Praça: ponto de " + npc)
		check(ResourceLoader.exists(db.get("npcs")[npc].portrait), "Praça: retrato de " + npc)
	for walk_id: String in db.get("walks").walks:
		var walk: Dictionary = db.get("walks").walks[walk_id]
		check(ResourceLoader.exists(db.get("walks").settings.postcard_dir + walk.postcard), walk_id + ": postal existe")
		var rare: Dictionary = walk.loot.get("rare", {})
		check(db.get("collections").has(str(rare.get("collection", ""))), walk_id + ": raro existe")
		for reward: Dictionary in [walk.loot.get("first", {}), rare.get("duplicate", {})]:
			for item: String in reward.get("items", {}):
				check(db.get("items").has(item), walk_id + ": item garantido/consolo " + item)
		for entry: Dictionary in walk.loot.table:
			if entry.has("find"):
				check(db.get("finds").worlds.has(entry.find), walk_id + ": mundo de achados " + str(entry.find))
			for item: String in entry.get("items", {}):
				check(db.get("items").has(item), walk_id + ": item " + item)
	# Materiais exclusivos de passeio (moram no baú) nunca são colheita, produto de estação ou achado do faro.
	for item: String in db.get("items"):
		if db.get("items")[item].get("category", "") != "trail":
			continue
		check(db.get("items")[item].get("storage", "") == "chest", item + ": mora no baú (etapa 08)")
		check(not db.get("crops").has(item), item + ": não é colheita")
		for recipe: Dictionary in db.get("recipes").values():
			# Etapa 17: gravetos renováveis na bancada (`cut_sticks`), a única receita que devolve um material de passeio.
			if item == "stick" and recipe == db.get("recipes").get("cut_sticks"):
				continue
			check(recipe.get("output", recipe.get("output_collection", "")) != item, item + ": não sai de estação")
		for world: Dictionary in db.get("finds").worlds.values():
			for entry: Dictionary in world.get("table", []) + world.get("guaranteed", []):
				check(not entry.get("items", {}).has(item), item + ": não sai de montinho")
	# Revelar aos poucos: personagem aparece até o capítulo da primeira missão dele.
	for npc: String in db.get("npcs"):
		var from := int(db.get("npcs")[npc].get("requirements", {}).get("chapter", 1))
		for id: String in quests:
			check(int(quests[id].get("chapter", 99)) >= from or quests[id].npc != npc, npc + ": aparece depois da missão " + id)
	for feature: String in ["bag", "daily", "weekly", "growth_tab"]:
		check(data.get("features", {}).has(feature), "recurso usado pelo código: " + feature)
	# Toda construção tem um lugar onde é comprada (fora a escritura do sítio, que fica nos canteiros).
	for id: String in data.upgrades:
		check(id == "farm" or db.call("place_of_upgrade", id)[0] != "", id + ": sem lugar para comprar")
	for id: String in data.activities:
		var a: Dictionary = data.activities[id]
		if a.place in ["walk", "mine"]:
			check(int(a.requirements.get("chapter", 1)) >= 3, id + ": rota antes da Trilha abrir")
	for id: String in data.activities:
		if str(db.call("gathering_site", id)) != "":
			check(int(data.activities[id].get("nature_xp", 0)) > 0, id + ": XP local próprio da rota")
		else:
			check(not data.activities[id].has("nature_xp"), id + ": rota sem local não dá XP local")
	for id: String in data.get("nature_resources", {}):
		check(db.get("items").has(id), id + ": material de coleta existente")
		for route: String in data.nature_resources[id].routes:
			check(data.activities.has(route) and data.activities[route].rewards.get("items", {}).has(id), id + ": rota rende este material")
	for id: String in data.get("nature_sites", {}):
		var site: Dictionary = data.nature_sites[id]
		check(site.levels.size() == 4 and site.level_upgrades.size() == 3, id + ": quatro patamares (o nível 4 não tem token próprio)")
		check(int(site.levels[0].xp) == 0 and int(site.xp_per_collection) > 0, id + ": XP de uso válido (o valor antigo só vale para lotes sem snapshot)")
		var thresholds: Array = [0, 24, 120, 360]
		var slot_counts: Array = [1, 2, 2, 3]
		for level in site.levels.size():
			check(int(site.levels[level].xp) == int(thresholds[level]), id + ": patamar de XP 0/24/120/360")
			check(int(site.levels[level].slots) == int(slot_counts[level]), id + ": vagas 1/2/2/3")
		check(site.slot_upgrades.size() == 2 and int(site.slot_levels[0]) == 2 and int(site.slot_levels[1]) == 4, id + ": segunda vaga no nível 2, terceira no nível 4")
		for upgrade: String in site.slot_upgrades:
			var index: int = site.slot_upgrades.find(upgrade)
			check(int(data.upgrades[upgrade].nature_unlock.level) == int(site.slot_levels[index]), id + ": token da vaga alinhado ao nível " + upgrade)
		for upgrade: String in site.slot_upgrades + site.level_upgrades:
			check(data.upgrades.has(upgrade), id + ": compra existente " + upgrade)
		for resource: String in site.resources:
			check(data.nature_resources.has(resource), id + ": material com coleta definida")
	for id: String in data.orders:
		check("first_harvest" in data.orders[id].requirements.get("quests", []), id + ": pedido antes da Vila abrir")
	for friend_id: String in db.get("friends").friends:
		var friend: Dictionary = db.get("friends").friends[friend_id]
		check(db.get("items").has(friend.likes), friend_id + ": petisco existente")
		check(ResourceLoader.exists(friend.portrait), friend_id + ": retrato existe")
		check(ResourceLoader.exists("res://assets/sprites/ui/icons/%s.png" % friend.icon), friend_id + ": ícone existe")
		for quest: String in friend.get("requirements", {}).get("quests", []):
			check(db.get("quests").has(quest), friend_id + ": requisito de missão existe")
		for reward: Dictionary in friend.heart_rewards:
			for item: String in reward.get("items", {}):
				check(db.get("items").has(item), friend_id + ": prêmio existe")
			for collection: String in reward.get("collections", []):
				check(db.get("collections").has(collection), friend_id + ": coleção existe")
	for problem: String in db.call("growth_problems"):
		check(false, problem)
	for problem: String in db.call("album_problems"):
		check(false, problem)
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
			elif acquired.type == "project":
				# Obra feita pela história: a conclusão abre os lugares que dependem dela.
				state.get("projects").projects[acquired.key] = {"completed": true}


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
	if target.has("growth"):
		return
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
	elif place.begins_with("friend:"):
		var friend_id := place.trim_prefix("friend:")
		check(world == "park" and db.get("friends").friends.has(friend_id), id + ": amigo fora da Praça")
		check(state.call("friend_unlocked", friend_id), id + ": amizade ainda fechada")
	elif place.begins_with("market:"):
		check(db.call("place_with_panel", "sell")[0] == world, id + ": feira fora do mundo")
	elif place.begins_with("order:"):
		check(db.get("progression").orders.has(place.trim_prefix("order:")) and world == "village", id + ": encomenda fora da Vila")
	elif place == "find":
		pass
	elif place == "":
		check(state.call("requirement_error", w.get("requirements", {})) == "", id + ": mundo ainda fechado")
	else:
		check(w.places.has(place), id + ": lugar inexistente")
		check(state.call("requirement_error", w.places.get(place, {}).get("requirements", {})) == "", id + ": destino em lugar ainda fechado")
	check(state.call("requirement_error", w.get("requirements", {})) == "", id + ": destino em mundo ainda fechado")
