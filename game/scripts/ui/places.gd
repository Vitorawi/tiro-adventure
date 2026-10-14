class_name Places
extends RefCounted
## Lugares e personagens dos mundos (data/worlds.json): abrir, listar e avisar.
##
## Um lugar tem "panel", que diz o que ele abre:
##   station:<id>            uma estação (bancada, ateliê)        inventory  geladeira/mochila
##   stations:<id>+<id>      várias estações num painel (cozinha) feed       tigela (dar comida)
##   farm                    canteiros e terrenos                 sleep      sofá (soneca)
##   market:<sell|orders>    feira com abas Vender/Encomendas     travel:<mundo> ir para outro mundo
##   routes:<tipo>+<tipo>    rotas ("walk", "mine", "orchard")
## "upgrade" = construção necessária (sem ela, tocar abre a compra); "upgrades" = compras feitas
## dentro do painel (ex.: picareta no portão); "requirements" = lugar fechado até cumprir;
## "hidden" = fora da lista "Lugares". Nas salas (rooms/<id>.json) objetos e zonas usam
## "action": "place:<id>", "npc:<id>" ou "market:<aba>".


## Abre um lugar do mundo (painel inferior, ação ou viagem).
static func open(world_id: String, place_id: String) -> void:
	var place: Dictionary = Database.worlds.get(world_id, {}).get("places", {}).get(place_id, {})
	if place.is_empty():
		return
	var closed := place_error(place)
	if closed != "":
		Events.toast_requested.emit("Ainda fechado: " + closed)
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
			Events.sheet_requested.emit(place.name, _panel(kind, arg) if kind == "nature" else _with_upgrades(_panel(kind, arg), place.get("upgrades", [])))


static func place_error(place: Dictionary) -> String:
	return GameState.requirement_error(place.get("requirements", {}))


static func _panel(kind: String, arg: String) -> Control:
	match kind:
		"station":
			return SheetBuilder.station_view(arg)
		"stations":
			return SheetBuilder.stations_view(arg.split("+"))
		"inventory":
			return SheetBuilder.inventory_view()
		"fridge":
			return SheetBuilder.inventory_view("fridge")
		"storage":
			return SheetBuilder.inventory_view(arg)
		"feed":
			return SheetBuilder.food_picker()
		"farm":
			return SheetBuilder.farm_view()
		"market":
			return ProgressionUi.market_panel(arg)
		"routes":
			return ProgressionUi.routes_panel(arg)
		"nature":
			for site: String in Database.progression.nature_sites:
				if arg.get_slice("+", 0) in Database.progression.nature_sites[site].groups:
					return NatureUi.panel(site)
	return UiKit.label("Em breve!")


static func _is_slot_upgrade(upgrade_id: String) -> bool:
	for station: Dictionary in Database.stations.values():
		if station.get("slot_upgrades", {}).has(upgrade_id):
			return true
	return false


## Painel do lugar + cartões de compra das construções que se compram ali (somem ao comprar).
static func _with_upgrades(panel: Control, upgrades: Array) -> Control:
	if upgrades.is_empty():
		return panel
	var box := UiKit.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(panel)
	box.add_child(SheetBuilder.LiveBox.new(func(cards: VBoxContainer) -> void:
		for id: String in upgrades:
			if not GameState.has_upgrade(id) and not _is_slot_upgrade(id):  # espaços de estação ficam na fileira de espaços
				ProgressionUi.upgrade_card(cards, id)))
	return box


static func open_npc(npc_id: String) -> void:
	if not GameState.progress.npc_visible(npc_id):
		return
	GameState.talk_to(npc_id)
	var npc: Dictionary = Database.npcs.get(npc_id, {})
	var introducing: bool = not npc.get("introduction", []).is_empty() and not GameState.progress.seen.has("npc_intro:" + npc_id)
	Events.sheet_requested.emit(npc.get("name", npc_id), ProgressionUi.npc_introduction(npc_id) if introducing else ProgressionUi.npc_view(npc_id))


## Balão sobre o personagem no mapa: "ready" (missão para receber), "new" (passo ainda
## não conversado) ou "".
static func npc_badge(npc_id: String) -> String:
	var active := npc_active_quests(npc_id)
	for id in active:
		if GameState.quest_error(id) == "":
			return "ready"
	for id in active:
		if not GameState.progress.seen.has("quest:" + id):
			return "new"
	return ""


## Ações das salas e dos botões "Ir": "place:<id>" | "npc:<id>" | "buy:<construção>" |
## "market:<aba>" | foco direto em "recipe:", "route:", "order:" ou "crop:" <id>.
static func run(world_id: String, action: String) -> void:
	if action.begins_with("recipe:"):
		var id := action.trim_prefix("recipe:")
		if Database.recipes.has(id):
			Events.sheet_requested.emit(Database.item_name(Database.recipes[id].output), SheetBuilder.station_view(Database.recipes[id].station, id))
	elif action.begins_with("route:"):
		var id := action.trim_prefix("route:")
		if Database.progression.activities.has(id):
			var data: Dictionary = Database.progression.activities[id]
			var target := Database.place_with_panel("routes:" + str(data.place))
			if target[0] == "nature":
				NatureUi.open_route(id)
			else:
				Events.sheet_requested.emit(data.name, ProgressionUi.routes_panel(data.place, id))
	elif action.begins_with("order:"):
		var id := action.trim_prefix("order:")
		if Database.progression.orders.has(id):
			Events.sheet_requested.emit(Database.progression.orders[id].name, ProgressionUi.orders_panel(id))
	elif action.begins_with("crop:"):
		var id := action.trim_prefix("crop:")
		if Database.crops.has(id):
			Events.sheet_requested.emit(Database.item_name(id), SheetBuilder.farm_view(id))
	elif action.begins_with("market:"):
		var location := Database.place_with_panel("sell")
		var place: Dictionary = Database.worlds[location[0]].places[location[1]]
		Events.sheet_requested.emit(place.name, _with_upgrades(ProgressionUi.market_panel(action.trim_prefix("market:")), place.get("upgrades", [])))
	elif action.begins_with("npc:"):
		open_npc(action.trim_prefix("npc:"))
	elif action.begins_with("buy:"):
		var upgrade := action.trim_prefix("buy:")
		Events.sheet_requested.emit(Database.progression.upgrades.get(upgrade, {}).get("name", "Construir"), ProgressionUi.purchase(upgrade))
	elif action.begins_with("place:"):
		open(world_id, action.trim_prefix("place:"))
	elif action != "":
		open(world_id, action)


## "O que tem aqui?": personagens e lugares do mundo, um botão grande com ícone cada.
## Verde = tem algo pronto; apagado = fechado ou ainda não construído.
static func world_list(world_id: String) -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var world: Dictionary = Database.worlds.get(world_id, {})
		for npc_id: String in visible_npcs(world_id):
			var ready := npc_alert(npc_id) != ""
			var button := UiKit.button(("! " if ready else "") + str(Database.npcs.get(npc_id, {}).get("name", npc_id)), open_npc.bind(npc_id), &"PrimaryButton" if ready else &"", ProgressionUi.npc_portrait(npc_id))
			_list_button(box, button)
		var places: Dictionary = world.get("places", {})
		for place_id: String in places:
			var place: Dictionary = places[place_id]
			if place.get("hidden", false):
				continue
			var upgrade: String = place.get("upgrade", "")
			var dim := place_error(place) != "" or (upgrade != "" and not GameState.has_upgrade(upgrade))
			var ready := place_alert(world_id, place_id) != ""
			var button := UiKit.button(place.name, open.bind(world_id, place_id), &"PrimaryButton" if ready else &"", UiKit.ui_icon(place.get("icon", "")))
			if dim:
				button.modulate.a = 0.6
			_list_button(box, button)
	)


## Ação do lugar onde a construção é feita (usada quando a sala não tem o "+" dela).
static func upgrade_place_action(upgrade_id: String) -> String:
	var spot := Database.place_of_upgrade(upgrade_id)[1]
	if spot == "plots":
		return "plot"
	return "place:" + spot if spot != "" else ""


## Ação da sala (objeto ou zona de rooms/<id>.json) que representa o destino do "Ir",
## para a seta apontar: "place:stove", "npc:bloblo", "market:orders" ou "plot".
static func highlight_action(place: String) -> String:
	if place == "" or place.begins_with("npc:") or place.begins_with("market:"):
		return place
	var id := place.get_slice(":", 1) if ":" in place else place
	var spot := id
	match place.get_slice(":", 0) if ":" in place else "place":
		"recipe":
			spot = Database.place_with_panel("station:" + str(Database.recipes.get(id, {}).get("station", "")))[1]
		"route":
			spot = Database.place_with_panel("routes:" + str(Database.progression.activities.get(id, {}).get("place", "")))[1]
		"order":
			return "market:orders"
		"crop":
			return "plot"
		"buy":
			return "buy:" + id  # seta no "+" do objeto; RoomView.point_at cai no lugar se não houver "+"
	if spot == "plots":
		return "plot"
	return "place:" + spot if spot != "" else ""


## Personagens do mundo que a história já apresentou.
static func visible_npcs(world_id: String) -> Array[String]:
	var result: Array[String] = []
	for npc_id: String in Database.worlds.get(world_id, {}).get("npcs", []):
		if GameState.progress.npc_visible(npc_id):
			result.append(npc_id)
	return result


## Novidade para a tela "Novo!": { icon, name, target } (target no formato de Places.go).
static func unlock_view(key: String) -> Dictionary:
	var kind := key.get_slice(":", 0)
	var id := key.get_slice(":", 1)
	match kind:
		"feature":
			var feature: Dictionary = Database.progression.features.get(id, {})
			return {"icon": UiKit.ui_icon(feature.get("icon", "")), "name": feature.get("name", id), "target": feature.get("go", {})}
		"world":
			var world: Dictionary = Database.worlds.get(id, {})
			return {"icon": UiKit.ui_icon(world.get("icon", "")), "name": world.get("name", id), "target": {"world": id, "place": ""}}
		"place":
			var world_id := id.get_slice("/", 0)
			var place: Dictionary = Database.worlds.get(world_id, {}).get("places", {}).get(id.get_slice("/", 1), {})
			return {"icon": UiKit.ui_icon(place.get("icon", "")), "name": place.get("name", id), "target": {"world": world_id, "place": id.get_slice("/", 1)}}
		"npc":
			return {"icon": ProgressionUi.npc_portrait(id), "name": Database.npcs.get(id, {}).get("name", id), "target": {"world": Database.npc_world(id), "place": "npc:" + id}}
	return {}


static func _list_button(box: VBoxContainer, button: Button) -> void:
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 40)
	button.custom_minimum_size = Vector2(0, 56)
	box.add_child(button)


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
	if panel == "farm":
		var ready := 0
		for i in GameState.accessible_plots():
			if GameState.plot_status(i) == "ready":
				ready += 1
		return "%d pronto(s) para colher!" % ready if ready > 0 else ""
	if world_id == "nature" and Database.progression.nature_sites.has(place_id):
		var count := GameState.gathering_ready_count(place_id)
		if count > 0:
			return "%d coleta(s) pronta(s)!" % count
		if not GameState.gathering_jobs(place_id).is_empty():
			return "Coletando"
	for part in Database.panel_parts(panel):
		var arg := part.get_slice(":", 1)
		if part.begins_with("station:") and GameState.has_upgrade(arg):
			var count := GameState.station(arg).ready_count(GameState.now())
			if count > 0:
				return "%d pronto(s) para coletar!" % count
		if part.begins_with("routes:"):
			var activity: Dictionary = GameState.progress.activity
			if not activity.is_empty() and Database.progression.activities.get(activity.id, {}).get("place", "walk") == arg:
				return "A rota terminou: recolha!" if GameState.activity_remaining() == 0 else "Em andamento (%s)" % TimeText.short(GameState.activity_remaining())
	return ""


## Avisos de um mundo inteiro (cartões do mapa).
static func world_alerts(world_id: String) -> PackedStringArray:
	var alerts: PackedStringArray = []
	var world: Dictionary = Database.worlds.get(world_id, {})
	for npc_id: String in visible_npcs(world_id):
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
				# Compra/construção: vai ao "+" do objeto (seta) e abre a compra com o que é preciso ter.
				return {"world": Database.progression.upgrades[key].world, "place": "buy:" + key, "hint": "Construir: " + str(Database.progression.upgrades[key].name)}
		"coins":
			return _panel_target("sell")
		"chapter":
			return {"screen": "tasks", "hint": "Continue os passos da história."}
		"quest":
			# Cruzamento: vai até o passo da outra linha (ex.: a vovó Bloblo).
			if Database.quests.has(key):
				return quest_target(key)
		"have", "deliver":
			for source: Dictionary in Database.item_sources(key):
				var target := goal_target(source)
				if not target.is_empty():
					return target
		"skill":
			var panels := {"agriculture": "farm", "cooking": "station:stove", "commerce": "sell", "adventure": "routes:walk"}
			return _panel_target(panels.get(key, ""))
		"stat":
			if key.begins_with("talk:"):
				var npc_id := key.trim_prefix("talk:")
				return {"world": Database.npc_world(npc_id), "place": "npc:" + npc_id, "hint": str(Database.npcs.get(npc_id, {}).get("name", ""))}
			if key.begins_with("open:"):
				var screen := key.trim_prefix("open:")
				if Database.worlds.has(screen):
					return {"world": screen, "place": "", "hint": "Mapa → " + str(Database.worlds[screen].name)}
				return {"screen": screen}
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
	# Encomendas ficam na aba própria da Feira.
	var place := "market:orders" if panel == "orders" else location[1]
	return {"world": location[0], "place": place, "hint": "%s → %s" % [Database.worlds[location[0]].name, Database.worlds[location[0]].places[location[1]].name]}


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
		# "spot" = lugar de destinos com foco ("recipe:...", "route:..."); "market:<aba>" = a Feira.
		var place_id: String = target.get("spot", place.trim_prefix("place:"))
		if place_id.begins_with("market:"):
			place_id = Database.place_with_panel("sell")[1]
		var data: Dictionary = world.get("places", {}).get(place_id, {})
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
