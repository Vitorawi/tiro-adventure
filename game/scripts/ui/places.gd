class_name Places
extends RefCounted
## Lugares e personagens dos mundos (data/worlds.json): abrir, listar e avisar.
##
## Um lugar tem "panel", que diz o que ele abre:
##   station:<id>  estação (fogão, forno, bancada, ateliê)   inventory  geladeira/mochila
##   feed          tigela (dar comida)                        sleep      sofá (soneca)
##   farm          canteiros e terrenos                       build:<mundo>  construções daquele mundo
##   sell          vender na feira                            orders     encomendas
##   routes:<tipo> rotas ("walk", "mine", "orchard")          travel:<mundo> ir para outro mundo
## "upgrade" (opcional) = construção necessária; sem ela, tocar abre a compra.
## Nas salas (rooms/<id>.json) objetos e zonas usam "action": "place:<id>" ou "npc:<id>".


## Abre um lugar do mundo (painel inferior, ação ou viagem).
static func open(world_id: String, place_id: String) -> void:
	var place: Dictionary = Database.worlds.get(world_id, {}).get("places", {}).get(place_id, {})
	if place.is_empty():
		return
	var upgrade: String = place.get("upgrade", "")
	if upgrade != "" and not GameState.has_upgrade(upgrade):
		Events.sheet_requested.emit(place.name, ProgressionUi.purchase(upgrade))
		return
	var panel: String = place.get("panel", "")
	var kind := panel.get_slice(":", 0)
	var arg := panel.get_slice(":", 1) if ":" in panel else ""
	match kind:
		"travel":
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(arg, "")
		"sleep":
			var sleeping := not GameState.dog.sleeping
			GameState.set_sleeping(sleeping)
			Events.toast_requested.emit("Hora da soneca!" if sleeping else "Tiro acordou!")
		_:
			Events.sheet_requested.emit(place.name, _panel(kind, arg))


static func _panel(kind: String, arg: String) -> Control:
	match kind:
		"station":
			return SheetBuilder.station_view(arg)
		"inventory":
			return SheetBuilder.inventory_view()
		"feed":
			return SheetBuilder.food_picker()
		"farm":
			return SheetBuilder.farm_view()
		"build":
			return ProgressionUi.build_panel(arg)
		"sell":
			return ProgressionUi.sell_panel()
		"orders":
			return ProgressionUi.orders_panel()
		"routes":
			return ProgressionUi.routes_panel(arg)
	return UiKit.label("Em breve!")


static func open_npc(npc_id: String) -> void:
	Events.sheet_requested.emit(Database.npcs.get(npc_id, {}).get("name", npc_id), ProgressionUi.npc_view(npc_id))


## "place:<id>" | "npc:<id>" | "buy:<construção>" (ações das salas e dos botões "Ir").
static func run(world_id: String, action: String) -> void:
	if action.begins_with("recipe:"):
		var id := action.trim_prefix("recipe:")
		if Database.recipes.has(id):
			Events.sheet_requested.emit(Database.item_name(Database.recipes[id].output), SheetBuilder.station_view(Database.recipes[id].station, id))
	elif action.begins_with("route:"):
		var id := action.trim_prefix("route:")
		if Database.progression.activities.has(id):
			Events.sheet_requested.emit(Database.progression.activities[id].name, ProgressionUi.routes_panel(Database.progression.activities[id].place, id))
	elif action.begins_with("order:"):
		var id := action.trim_prefix("order:")
		if Database.progression.orders.has(id):
			Events.sheet_requested.emit(Database.progression.orders[id].name, ProgressionUi.orders_panel(id))
	elif action.begins_with("crop:"):
		var id := action.trim_prefix("crop:")
		if Database.crops.has(id):
			Events.sheet_requested.emit(Database.item_name(id), SheetBuilder.farm_view(id))
	elif action.begins_with("npc:"):
		open_npc(action.trim_prefix("npc:"))
	elif action.begins_with("buy:"):
		var upgrade := action.trim_prefix("buy:")
		Events.sheet_requested.emit(Database.progression.upgrades.get(upgrade, {}).get("name", "Construir"), ProgressionUi.purchase(upgrade))
	elif action.begins_with("place:"):
		open(world_id, action.trim_prefix("place:"))
	elif action != "":
		open(world_id, action)


## "O que tem aqui?": personagens e lugares do mundo, em cartões com botão.
static func world_list(world_id: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var world: Dictionary = Database.worlds.get(world_id, {})
		for npc_id: String in world.get("npcs", []):
			var npc: Dictionary = Database.npcs.get(npc_id, {})
			var card := UiKit.card(box, &"ReadyCardPanel" if npc_alert(npc_id) != "" else &"CardPanel")
			var row := UiKit.hbox(10)
			row.add_child(UiKit.icon(ProgressionUi.npc_portrait(npc_id), 48))
			var info := UiKit.vbox(2)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label(npc.get("name", npc_id), &"SectionLabel"))
			info.add_child(UiKit.label(npc_alert(npc_id) if npc_alert(npc_id) != "" else npc.get("role", ""), &"SmallLabel"))
			row.add_child(info)
			var talk := UiKit.button("Conversar", open_npc.bind(npc_id), &"PrimaryButton")
			talk.custom_minimum_size = Vector2(110, 48)
			talk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(talk)
			card.add_child(row)
		var places: Dictionary = world.get("places", {})
		for place_id: String in places:
			var place: Dictionary = places[place_id]
			var upgrade: String = place.get("upgrade", "")
			var locked := upgrade != "" and not GameState.has_upgrade(upgrade)
			var alert := place_alert(world_id, place_id)
			var card := UiKit.card(box, &"ReadyCardPanel" if alert != "" else &"CardPanel")
			var row := UiKit.hbox(10)
			row.add_child(UiKit.icon(UiKit.ui_icon(place.get("icon", "")), 32))
			var info := UiKit.vbox(2)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label(place.name, &"SectionLabel"))
			var hint: String = alert if alert != "" else place.get("description", "")
			if locked:
				hint = "Construa primeiro: " + Database.progression.upgrades.get(upgrade, {}).get("name", upgrade)
			if hint != "":
				info.add_child(UiKit.label(hint, &"SmallLabel"))
			row.add_child(info)
			var go := UiKit.button("Ver" if locked else "Abrir", open.bind(world_id, place_id), &"" if locked else &"PrimaryButton")
			go.custom_minimum_size = Vector2(88, 48)
			go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(go)
			card.add_child(row)
	)


# --- Avisos ("tem coisa pronta aqui") -------------------------------------------------

## Mundo liberado? "" ou o motivo (requisitos de worlds.json).
static func world_error(world_id: String) -> String:
	return GameState.requirement_error(Database.worlds.get(world_id, {}).get("requirements", {}))


## Texto curto se o personagem tem missão com recompensa pronta.
static func npc_alert(npc_id: String) -> String:
	for id: String in Database.quests:
		if Database.quests[id].npc == npc_id and GameState.quest_error(id) == "":
			return "Missão pronta: " + str(Database.quests[id].name)
	return ""


## Missões em andamento (liberadas e ainda não recebidas) do personagem.
static func npc_active_quests(npc_id: String) -> Array[String]:
	var result: Array[String] = []
	for id: String in Database.quests:
		if Database.quests[id].npc == npc_id and GameState.quest_unlocked(id) and not GameState.progress.claimed_quests.has(id):
			result.append(id)
	return result


## Texto curto se o lugar tem algo pronto (colheita, produção, rota que voltou).
static func place_alert(world_id: String, place_id: String) -> String:
	var place: Dictionary = Database.worlds.get(world_id, {}).get("places", {}).get(place_id, {})
	var panel: String = place.get("panel", "")
	var arg := panel.get_slice(":", 1) if ":" in panel else ""
	match panel.get_slice(":", 0):
		"farm":
			var ready := 0
			for i in GameState.accessible_plots():
				if GameState.plot_status(i) == "ready":
					ready += 1
			return "%d pronto(s) para colher!" % ready if ready > 0 else ""
		"station":
			if GameState.has_upgrade(arg):
				var count := GameState.station(arg).ready_count(GameState.now())
				return "%d pronto(s) para coletar!" % count if count > 0 else ""
		"routes":
			var activity: Dictionary = GameState.progress.activity
			if not activity.is_empty() and Database.progression.activities.get(activity.id, {}).get("place", "walk") == arg:
				return "A rota terminou: recolha!" if GameState.activity_remaining() == 0 else "Em andamento (%s)" % TimeText.short(GameState.activity_remaining())
	return ""


## Avisos de um mundo inteiro (cartões do mapa).
static func world_alerts(world_id: String) -> PackedStringArray:
	var alerts: PackedStringArray = []
	var world: Dictionary = Database.worlds.get(world_id, {})
	for npc_id: String in world.get("npcs", []):
		if npc_alert(npc_id) != "":
			alerts.append("Missão pronta com " + str(Database.npcs[npc_id].name))
	for place_id: String in world.get("places", {}):
		var alert := place_alert(world_id, place_id)
		if alert != "" and not alert.begins_with("Em andamento"):
			alerts.append("%s: %s" % [world.places[place_id].name, alert])
	return alerts

## Destino estruturado de um objetivo; não depende de texto traduzido.
static func goal_target(goal: Dictionary) -> Dictionary:
	var key: String = goal.get("key", "")
	match str(goal.get("type", "")):
		"owned":
			if Database.progression.upgrades.has(key):
				return {"world": Database.progression.upgrades[key].world, "place": "buy:" + key, "hint": "Construir: " + str(Database.progression.upgrades[key].name)}
		"coins":
			return _panel_target("sell")
		"chapter":
			return {"screen": "tasks", "hint": "Continue os passos da história."}
		"have", "deliver":
			for source: Dictionary in Database.item_sources(key):
				var target := goal_target(source)
				if not target.is_empty():
					return target
		"skill":
			var panels := {"agriculture": "farm", "cooking": "station:stove", "building": "station:workbench", "commerce": "sell", "walking": "routes:walk", "mining": "routes:mine"}
			if key == "bond":
				return {"screen": "pet", "hint": "Tiro → cuidar e brincar"}
			return _panel_target(panels.get(key, ""))
		"stat":
			if key == "feed":
				return _panel_target("feed")
			if key == "harvest" or key.begins_with("harvest:"):
				return _panel_target("farm")
			if key in ["trade", "sold"]:
				return _panel_target("sell")
			if key == "orders" or key.begins_with("order:"):
				return _panel_target("orders")
			if key in ["bathe", "play", "pet"]:
				return {"screen": "pet", "hint": "Tiro → cuidar e brincar"}
			if key == "explore":
				return _panel_target("routes:walk")
			if key.begins_with("activity:"):
				var route: Dictionary = Database.progression.activities.get(key.trim_prefix("activity:"), {})
				if not route.is_empty():
					return _panel_target("routes:" + str(route.place))
			if key == "produce":
				return _panel_target("station:stove")
			if key.begins_with("produce:"):
				for recipe: Dictionary in Database.recipes.values():
					if recipe.output == key.trim_prefix("produce:"):
						return _panel_target("station:" + str(recipe.station))
	return {}


static func _panel_target(panel: String) -> Dictionary:
	var location := Database.place_with_panel(panel)
	if location[0] == "":
		return {}
	return {"world": location[0], "place": location[1], "hint": "%s → %s" % [Database.worlds[location[0]].name, Database.worlds[location[0]].places[location[1]].name]}


## Primeiro objetivo pendente, com substituições opcionais do conteúdo.
static func quest_target(id: String) -> Dictionary:
	var quest: Dictionary = Database.quests[id]
	var goal: Dictionary = quest.goals[0]
	for candidate: Dictionary in quest.goals:
		if GameState.goal_value(candidate) < int(candidate.get("target", 1)):
			goal = candidate
			break
	var result: Dictionary = quest.get("go", goal_target(goal)).duplicate()
	if quest.has("hint"):
		result["hint"] = quest.hint
	return result


## "Onde": [ícone do mundo] › [ícone do lugar] Nome. Aba Tiro: [Tiro]. null se não houver lugar.
static func target_view(target: Dictionary) -> HBoxContainer:
	var row := UiKit.hbox(6)
	if target.get("screen", "") == "pet":
		row.add_child(UiKit.icon(UiKit.ui_icon("tab_pet"), 32))
		row.add_child(UiKit.fill_label("Tiro", &"SmallLabel"))
		return row
	var world: Dictionary = Database.worlds.get(target.get("world", ""), {})
	if world.is_empty():
		row.free()
		return null
	var place: String = target.get("place", "")
	var texture: Texture2D = null
	var place_name := ""
	if place.begins_with("buy:"):
		var upgrade: Dictionary = Database.progression.upgrades.get(place.trim_prefix("buy:"), {})
		texture = UiKit.ui_icon(upgrade.get("icon", ""))
		place_name = upgrade.get("name", "")
	elif place.begins_with("npc:"):
		texture = ProgressionUi.npc_portrait(place.trim_prefix("npc:"))
		place_name = Database.npcs.get(place.trim_prefix("npc:"), {}).get("name", "")
	else:
		var data: Dictionary = world.get("places", {}).get(place.trim_prefix("place:"), {})
		texture = UiKit.ui_icon(data.get("icon", ""))
		place_name = data.get("name", "")
	row.add_child(UiKit.icon(UiKit.ui_icon(world.get("icon", "")), 32))
	if place_name != "":
		row.add_child(UiKit.short_label("›", &"SmallLabel"))
		row.add_child(UiKit.icon(texture, 32))
		row.add_child(UiKit.fill_label(place_name, &"SmallLabel"))
	else:
		row.add_child(UiKit.fill_label(world.get("name", ""), &"SmallLabel"))
	return row


static func go(target: Dictionary) -> void:
	Events.sheet_close_requested.emit()
	if target.has("screen"):
		Events.screen_requested.emit(StringName(target.screen))
	elif target.has("world"):
		Events.world_requested.emit(target.world, target.get("place", ""))
