class_name Places
extends RefCounted
## Lugares e personagens dos mundos (data/worlds.json): abrir, listar e avisar.
##
## Um lugar tem "panel", que diz o que ele abre:
##   station:<id>            uma estação (bancada, ateliê)        inventory  geladeira/mochila
##   stations:<id>+<id>      várias estações num painel (cozinha) feed       tigela (dar comida)
##   farm                    canteiros e terrenos                 sleep      sofá (soneca)
##   sell / orders / contracts   venda / vizinhos / banca própria    travel:<mundo> viagem
##   routes:<tipo>+<tipo>    rotas ("walk", "mine", "orchard")
## "upgrade" = construção necessária (sem ela, tocar abre a compra); "upgrades" = compras feitas
## dentro do painel (ex.: picareta no portão); "requirements" = lugar fechado até cumprir;
## "hidden" = fora da lista "Lugares". Nas salas (rooms/<id>.json) objetos e zonas usam
## "action": "place:<id>", "npc:<id>" ou "market:<aba>".


## Abre um lugar do mundo (painel inferior, ação ou viagem).
static func open(world_id: String, place_id: String, from_object: bool = false) -> void:
	var place: Dictionary = Database.worlds.get(world_id, {}).get("places", {}).get(place_id, {})
	if place.is_empty():
		return
	var closed := place_error(place)
	if closed != "":
		Events.toast_requested.emit("Ainda não: " + closed)
		return
	var upgrade: String = place.get("upgrade", "")
	if upgrade != "" and not GameState.has_upgrade(upgrade):
		Events.sheet_requested.emit(place.name, ProgressionUi.purchase(upgrade))
		return
	var panel: String = place.get("panel", "")
	var kind := panel.get_slice(":", 0)
	var arg := panel.get_slice(":", 1) if ":" in panel else ""
	match kind:
		"house":
			Events.sheet_requested.emit(place.name, HouseUi.bed() if arg == "bed" else HouseUi.wall())
		"travel":
			Events.sheet_close_requested.emit()
			Events.world_requested.emit(arg, "")
		"sleep":
			var sleeping := not GameState.dog.sleeping
			GameState.set_sleeping(sleeping)
			Events.toast_requested.emit("Hora da soneca!" if sleeping else "Tiro acordou!")
		_:
			var content := _panel(kind, arg, world_id) if kind in ["nature", "petshop", "contracts"] else _with_upgrades(_panel(kind, arg, world_id), place.get("upgrades", []))
			# Ao tocar na estação do mapa, deixa o objeto à vista; puxar a alça para cima amplia a consulta.
			if from_object and kind in ["station", "stations"]:
				content.set_meta("sheet_size", "half")
			Events.sheet_requested.emit(place.name, content)


static func place_error(place: Dictionary) -> String:
	return GameState.requirement_error(place.get("requirements", {}))


static func _panel(kind: String, arg: String, world_id: String = "village") -> Control:
	match kind:
		"tricks":
			return TrickUi.panel(true)
		"friends":
			return FriendUi.panel()
		"community":
			return ProjectUi.community(arg if arg != "" else "park")
		"project":
			return ProjectUi.panel(arg)
		"petshop":
			return ProgressionUi.petshop_panel()
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
		"greenhouse":
			return SheetBuilder.farm_view("", true)
		"market":
			return ProgressionUi.market_panel(arg, world_id)
		"sell":
			return MarketUi.sell(world_id)
		"orders":
			return MarketUi.orders()
		"contracts":
			return MarketUi.orders("", "contracts")
		"routes":
			return ProgressionUi.routes_panel(arg)
		"walks":
			return ProgressionUi.walks_panel()
		"nature":
			var site := _site_of_group(arg)
			if site != "":
				return NatureUi.panel(site)
	return UiKit.label("Em breve!")


## Local da Natureza (Bosque, Caverna, Prado) de um grupo de rotas ("walk", "creek+mine+crystal"...) ou "".
static func _site_of_group(arg: String) -> String:
	for site: String in Database.progression.nature_sites:
		if arg.get_slice("+", 0) in Database.progression.nature_sites[site].groups:
			return site
	return ""


## Local da Natureza que um lugar do mundo abre ("" se o lugar não for da Natureza).
static func nature_site(world_id: String, place_id: String) -> String:
	var panel: String = Database.worlds.get(world_id, {}).get("places", {}).get(place_id, {}).get("panel", "")
	return _site_of_group(panel.get_slice(":", 1)) if panel.begins_with("nature:") else ""


## Atalhos e Lugares usam a bandeja do mundo visível; `open` continua sendo a consulta em painel.
static func open_tray(world_id: String, place_id: String) -> bool:
	var place: Dictionary = Database.worlds.get(world_id, {}).get("places", {}).get(place_id, {})
	if place.is_empty() or place_error(place) != "":
		return false
	var upgrade: String = place.get("upgrade", "")
	if upgrade != "" and not GameState.has_upgrade(upgrade):
		return false
	var panel: String = place.get("panel", "")
	for room: Node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("room_views"):
		if not room is RoomView or room.world_id != world_id or not room.is_visible_in_tree():
			continue
		if panel in ["farm", "greenhouse"]:
			# O Ir geral abre as sementes direto; sem espaço, mostra a ferramenta da plantação.
			for status: String in ["empty", "ready", "growing"]:
				for index: int in room.plot_indices():
					if GameState.is_greenhouse_plot(index) == (panel == "greenhouse") and GameState.plot_status(index) == status:
						Events.sheet_close_requested.emit()
						room.open_plot_tray(index, "", true, false)
						return true
		if panel.get_slice(":", 0) in ["station", "stations"]:
			for station_id: String in panel.get_slice(":", 1).split("+"):
				if room.can_open_station_tray(station_id):
					Events.sheet_close_requested.emit()
					room.open_station_tray(station_id)
					return true
		var site := nature_site(world_id, place_id)
		if site != "" and room.can_open_nature_tray(site):
			Events.sheet_close_requested.emit()
			room.open_nature_tray(site)
			return true
	return false


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
	if panel.has_meta("sheet_size"):
		box.set_meta("sheet_size", panel.get_meta("sheet_size"))  # a altura pedida pelo painel vale para o conjunto
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
	if action == "growth":
		GrowthUi.open()
	elif action.begins_with("friend_visit:"):
		var reason := GameState.collect_friend_visit(action.trim_prefix("friend_visit:"))
		if reason != "":
			Events.toast_requested.emit(reason)
	elif action.begins_with("friend:"):
		FriendUi.open(action.trim_prefix("friend:"))
	elif action.begins_with("recipe:"):
		var id := action.trim_prefix("recipe:")
		if Database.recipes.has(id):
			# No mundo da estação, a bandeja abre ao lado dela com a receita já escolhida.
			var station: String = Database.recipes[id].station
			for room: Node in (Engine.get_main_loop() as SceneTree).get_nodes_in_group("room_views"):
				if room is RoomView and room.world_id == world_id and room.is_visible_in_tree() and room.can_open_station_tray(station):
					Events.sheet_close_requested.emit()
					room.open_station_tray(station, id, true)
					return
			Events.sheet_requested.emit(Database.item_name(Database.recipe_output(Database.recipes[id])), SheetBuilder.station_view(Database.recipes[id].station, id))
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
			if world_id == "farm":
				# No Sítio a bandeja de sementes abre no primeiro canteiro vazio, com a planta pedida em destaque.
				Events.plot_tray_requested.emit(id, -1)
			else:
				Events.sheet_requested.emit(Database.item_name(id), SheetBuilder.farm_view(id, Database.crops.get(id, {}).get("greenhouse", "") == "only"))
	elif action.begins_with("market:"):
		var orders := action.trim_prefix("market:") == "orders"
		Events.sheet_requested.emit("Encomendas" if orders else "Vender", ProgressionUi.market_panel("orders" if orders else "sell", world_id))
	elif action.begins_with("npc:"):
		open_npc(action.trim_prefix("npc:"))
	elif action.begins_with("buy:"):
		var upgrade := action.trim_prefix("buy:")
		Events.sheet_requested.emit(Database.progression.upgrades.get(upgrade, {}).get("name", "Construir"), ProgressionUi.purchase(upgrade))
	elif action.begins_with("place:"):
		var id := action.trim_prefix("place:")
		if not open_tray(world_id, id):
			open(world_id, id)
	elif action != "":
		if not open_tray(world_id, action):
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
	if place.begins_with("friend:") or place.begins_with("friend_visit:"):
		return place
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
			return "place:stall" if MarketUi.is_contract(id) else "place:orders"
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
		if GameState.progress.npc_visible(npc_id) and not Database.npcs.get(npc_id, {}).get("decor", false):
			result.append(npc_id)
	return result


## Novidade para a tela "Novo!": { icon, name, target } (target no formato de Places.go).
static func unlock_view(key: String) -> Dictionary:
	var kind := key.get_slice(":", 0)
	var id := key.get_slice(":", 1)
	match kind:
		"personality":
			return {"icon": UiKit.ui_icon("tab_pet"), "name": Database.growth.personality.unlock, "target": {"growth": true}}
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
		"walk":
			var postcard := WalkResult.postcard_texture(GameState.walk_postcard(id))
			return {"icon": postcard if postcard else UiKit.ui_icon("action_walk"), "name": GameState.walk_def(id).get("name", id), "target": {"world": "park", "place": "walk"}}
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


## Mostra o capítulo de abertura e a história/missão exigida, conforme pedido do Vitor.
static func unlock_hint(world_id: String) -> Dictionary:
	var requirements: Dictionary = Database.worlds.get(world_id, {}).get("requirements", {})
	if requirements.has("chapter"):
		var chapters: Array = Database.progression.get("chapters", [])
		var index := int(requirements.chapter) - 1
		if index >= 0 and index < chapters.size():
			return {"icon": UiKit.ui_icon("tab_tasks"), "text": "Abre no capítulo %d\n%s" % [index + 1, str(chapters[index].name)]}
	for quest_id: String in requirements.get("quests", []):
		if not GameState.progress.claimed_quests.has(quest_id):
			var quest: Dictionary = Database.quests.get(quest_id, {})
			var chapter := int(quest.get("chapter", 0))
			var text := "Depois de: " + str(quest.get("name", quest_id))
			if chapter > 0:
				text = "Abre no capítulo %d\n%s" % [chapter, text]
			return {"icon": ProgressionUi.npc_portrait(str(quest.get("npc", ""))), "text": text}
	return {"icon": UiKit.ui_icon("ui_lock"), "text": world_error(world_id)}


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


## "1 pronto!" / "3 prontos!" (glossário: Pegar o que ficou pronto).
static func ready_text(count: int) -> String:
	return "1 pronto!" if count == 1 else "%d prontos!" % count


## Texto curto se o lugar tem algo pronto (colheita, produção, rota que voltou).
static func place_alert(world_id: String, place_id: String) -> String:
	var place: Dictionary = Database.worlds.get(world_id, {}).get("places", {}).get(place_id, {})
	var panel: String = place.get("panel", "")
	if panel == "farm":
		var ready := 0
		for i in GameState.usable_plot_indices():
			if GameState.plot_status(i) == "ready":
				ready += 1
		return ready_text(ready) if ready > 0 else ""
	if world_id == "nature" and Database.progression.nature_sites.has(place_id):
		var count := GameState.gathering_ready_count(place_id)
		if count > 0:
			return ready_text(count)
		if not GameState.gathering_jobs(place_id).is_empty():
			return "Buscando"
	for part in Database.panel_parts(panel):
		var arg := part.get_slice(":", 1)
		if part.begins_with("station:") and GameState.has_upgrade(arg):
			var count := GameState.station(arg).ready_count(GameState.now())
			if count > 0:
				return ready_text(count)
		if part.begins_with("routes:"):
			var activity: Dictionary = GameState.progress.activity
			if not activity.is_empty() and Database.progression.activities.get(activity.id, {}).get("place", "walk") == arg:
				return "Pronto! Pegue" if GameState.activity_remaining() == 0 else "Em andamento (%s)" % TimeText.short(GameState.activity_remaining())
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
		"growth_req": return TaskHelp.describe("growth_req", key).target
		"growth": return {"growth": true, "hint": "Tiro → Crescimento"}
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
		"project":
			var project_go: Dictionary = Database.project(key).get("go", {})
			if not project_go.is_empty():
				return project_go
		"have", "deliver":
			for source: Dictionary in Database.item_sources(key):
				var target := goal_target(source)
				if not target.is_empty():
					return target
		"skill":
			var panels := {"agriculture": "farm", "cooking": "station:stove", "commerce": "sell", "adventure": "routes:walk"}
			return _panel_target(panels.get(key, ""))
		"stat":
			if key == "open:album": return {"notebook": "album", "hint": "Tiro → caderninho → Álbum"}
			if key == "trick_learned":
				return _panel_target("tricks")
			if key.begins_with("project_use:"):
				var use_go: Dictionary = Database.project(key.trim_prefix("project_use:")).get("go", {})
				if not use_go.is_empty():
					return use_go
			if key == "trick" or key.begins_with("trick:"):
				return {"screen": "pet", "hint": "Tiro → Truques"}
			if key.begins_with("friend_gift:"):
				return {"world": "park", "place": "friend:" + key.trim_prefix("friend_gift:")}
			if key in ["friend_gift", "friend_level"]:
				return _panel_target("friends")
			if key == "equip":
				return {"screen": "pet", "collection": true, "hint": "Tiro → Coleção → Vestir"}
			if key == "sew":
				return {"world": "park", "place": "sewing"}
			if key.begins_with("talk:"):
				var npc_id := key.trim_prefix("talk:")
				return {"world": Database.npc_world(npc_id), "place": "npc:" + npc_id, "hint": str(Database.npcs.get(npc_id, {}).get("name", ""))}
			if key.begins_with("open:"):
				var screen := key.trim_prefix("open:")
				if Database.worlds.has(screen):
					return {"world": screen, "place": "", "hint": "Mapa → " + str(Database.worlds[screen].name)}
				return {"screen": screen}
			if key == "walk" or key.begins_with("walk:") or key.begins_with("walk_"):
				return _panel_target("walks")
			if key == "feed":
				return _panel_target("feed")
			if key in ["harvest", "water"] or key.begins_with("harvest:"):
				return _panel_target("farm")
			if key == "find" or key.begins_with("find:"):
				var world := key.trim_prefix("find:") if key.begins_with("find:") else "farm"
				if key == "find":
					for id: String in GameState.finds.worlds:
						if int(GameState.finds.worlds[id].pending) > 0:
							world = id
							break
				return {"world": world, "place": "find", "hint": "Cavar onde o Tiro farejou"}
			if key == "sold:village": return {"world": "village", "place": "market"}
			if key in ["trade", "sold"]:
				return {"world": "village", "place": "market"} if GameState.requirement_error(Database.worlds.village.get("requirements", {})) == "" else {"world": "farm", "place": "early_market"}
			if key == "contracts":
				return {"world": "village", "place": "stall"}
			if key.begins_with("order:"):
				var order_id := key.trim_prefix("order:")
				return {"world": "village", "place": "order:" + order_id, "spot": "stall" if MarketUi.is_contract(order_id) else "orders"}
			if key == "orders":
				return _panel_target("orders")
			if key == "storage_upgrades":
				# Ampliar um depósito qualquer: leva à próxima ampliação de um que já existe (sítio ou casa).
				var next := ""
				for depot: String in Database.progression.storage:
					var candidate := GameState.storage_next_upgrade(depot)
					if candidate != "" and GameState.has_upgrade(str(Database.progression.storage[depot].building)):
						next = candidate
						break
				return goal_target({"type": "owned", "key": next if next != "" else "silo"})
			if key == "wish" or key.begins_with("wish:"):
				return {"screen": "wishes", "hint": "Desejos do Tiro"}
			if key in ["bathe", "shampoo_bath", "play", "pet", "care_useful"] or key.begins_with("care_useful:"):
				return {"screen": "pet", "hint": "Tiro → cuidar e brincar"}
			if key == "explore":
				return _panel_target("routes:walk")
			if key.begins_with("activity:"):
				var route: Dictionary = Database.progression.activities.get(key.trim_prefix("activity:"), {})
				if not route.is_empty():
					return _panel_target("routes:" + str(route.place))
			if key in ["produce", "production_jobs"]:
				return _panel_target("station:stove")
			if key.begins_with("produce:"):
				for recipe: Dictionary in Database.recipes.values():
					if Database.recipe_output(recipe) == key.trim_prefix("produce:"):
						return _panel_target("station:" + str(recipe.station))
	return {}


static func _panel_target(panel: String) -> Dictionary:
	var location := Database.place_with_panel(panel)
	if location[0] == "":
		return {}
	# Encomendas ficam na aba própria da Feira.
	var place := location[1]
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
	if target.get("screen", "") == "pet" or target.has("growth"):
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
	if target.has("storage"):
		Events.sheet_requested.emit(GameState.storage_name(str(target.storage)), SheetBuilder.inventory_view(str(target.storage)))
	elif target.has("notebook"):
		Events.screen_requested.emit(&"pet")
		PetNotebook.open(str(target.notebook))
	elif target.has("growth"):
		GrowthUi.open()
	elif target.has("screen"):
		Events.screen_requested.emit(StringName(target.screen))
		if bool(target.get("collection", false)):
			Events.sheet_requested.emit("Coleção", ProgressionUi.collection_panel())
	elif target.has("world"):
		Events.world_requested.emit(target.world, target.get("place", ""))
