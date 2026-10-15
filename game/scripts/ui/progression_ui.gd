class_name ProgressionUi
extends RefCounted
## Painéis da progressão, abertos pelos lugares dos mundos (Places) e pelas Missões:
## personagem (missões), construir por mundo, vender, encomendas, rotas, atributos e coleção.
## Conteúdo, requisitos e recompensas vêm dos JSON; ações passam pelo GameState.


# --- Personagens e missões ------------------------------------------------------

## Falas curtas, avançadas por toque. Fechar antes do fim permite rever a apresentação.
static func npc_introduction(npc_id: String, index: int = 0) -> Control:
	var npc: Dictionary = Database.npcs[npc_id]
	var lines: Array = npc.get("introduction", [])
	var box := UiKit.vbox(12)
	box.name = "NpcIntroduction"
	npc_header(box, npc_id, str(lines[index]))
	box.add_child(UiKit.button("Vamos!" if index == lines.size() - 1 else "Continuar", func() -> void:
		if index + 1 < lines.size():
			Events.sheet_requested.emit(npc.name, npc_introduction(npc_id, index + 1))
		else:
			GameState.mark_seen(["npc_intro:" + npc_id])
			Events.sheet_requested.emit(npc.name, npc_view(npc_id)), &"PrimaryButton"))
	return box

## Personagem: saudação, missões ativas e atalhos para os lugares dele ("services").
static func npc_view(npc_id: String) -> Control:
	var panel := UiKit.vbox(10)
	var speech := npc_header(panel, npc_id, "", true)
	panel.add_child(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var npc: Dictionary = Database.npcs.get(npc_id, {})
		var active := Places.npc_active_quests(npc_id)
		speech.text = str(Database.quests[active[0]].get("dialogue", "")) if not active.is_empty() else str(npc.get("greeting", ""))
		for id in active:
			quest_card(box, id)
		# Atalhos para os lugares que o personagem cuida.
		var world_id := Database.npc_world(npc_id)
		for place_id: String in npc.get("services", []):
			var place: Dictionary = Database.worlds[world_id].places.get(place_id, {})
			if place.is_empty() or Places.place_error(place) != "":
				continue
			var upgrade: String = place.get("upgrade", "")
			if upgrade != "" and not GameState.has_upgrade(upgrade):
				continue
			box.add_child(UiKit.button(place.get("name", place_id), Places.open.bind(world_id, place_id), &"", UiKit.ui_icon(place.get("icon", ""))))
	))
	return panel


static func npc_portrait(npc_id: String) -> Texture2D:
	var npc: Dictionary = Database.npcs.get(npc_id, {})
	if npc.get("portrait", "") != "" and ResourceLoader.exists(npc.portrait):
		return load(npc.portrait)
	return UiKit.ui_icon(npc.get("icon", "xp"))


## Rosto grande + fala do passo atual (ou o cumprimento); o nome já está no título do painel.
static func npc_header(box: VBoxContainer, npc_id: String, speech: String = "", animated: bool = false) -> Label:
	var npc: Dictionary = Database.npcs.get(npc_id, {})
	var row := UiKit.hbox(10)
	if animated and npc.has("portrait_animations"):
		var portrait := NpcPortrait.new()
		portrait.name = "NpcPortrait"
		portrait.npc_id = npc_id
		portrait.custom_minimum_size = Vector2(96, 96)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(portrait)
	else:
		row.add_child(UiKit.icon(npc_portrait(npc_id), 96))
	var bubble := UiKit.fill_label(speech if speech != "" else str(npc.get("greeting", "")), &"")
	bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(bubble)
	box.add_child(row)
	return bubble


static func quest_card(box: VBoxContainer, id: String) -> void:
	var quest: Dictionary = Database.quests[id]
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.quest_error(id) == "" else &"CardPanel")
	card.add_child(UiKit.label(quest.name, &"SectionLabel"))
	for goal: Dictionary in quest.goals:
		card.add_child(goal_row(goal, GameState.goal_value(goal)))
	card.add_child(reward_chips(quest.rewards))
	quest_action(card, id)


# --- Construir --------------------------------------------------------------------

static func purchase(id: String) -> Control:
	var unlock: Dictionary = Database.progression.upgrades[id].get("nature_unlock", {})
	if not unlock.is_empty():
		return NatureUi.panel(str(unlock.site))
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void: upgrade_card(box, id))


static func upgrade_card(box: VBoxContainer, id: String) -> void:
	var data: Dictionary = Database.progression.upgrades[id]
	if data.has("nature_unlock"):
		box.add_child(NatureUi.levels_panel(str(data.nature_unlock.site)))
		return
	var card := UiKit.card(box, &"ReadyCardPanel" if GameState.upgrade_error(id) == "" else &"CardPanel")
	_title(card, data.get("icon", ""), data.name)
	_text(card, data.description, true)
	if GameState.has_upgrade(id):
		_text(card, "Adquirido!", true)
		var place := Database.place_with_panel("station:" + id)
		if place[0] != "":
			card.add_child(UiKit.button("Abrir " + Database.stations[id].name, Places.open.bind(place[0], place[1])))
		return
	var cost := UiKit.flow()
	if int(data.cost) <= 0:
		cost.add_child(UiKit.chip(UiKit.ui_icon("coin"), "Grátis", UiKit.GOOD))
	else:
		cost.add_child(UiKit.chip(UiKit.ui_icon("coin"), "%d/%d" % [mini(GameState.coins, int(data.cost)), int(data.cost)], UiKit.GOOD if GameState.coins >= int(data.cost) else UiKit.BAD))
	card.add_child(cost)
	_amounts(card, data.get("materials", {}))
	_action(card, "Comprar", func() -> String: return GameState.buy_upgrade(id), GameState.upgrade_error(id), "%s é seu!" % data.name, TaskHelp.open.bind("upgrade", id))


# --- Vila: vender e encomendas --------------------------------------------------------

## Feira: abas Vender | Encomendas (`tab` = "sell" ou "orders").
static func market_panel(tab: String = "sell") -> Control:
	var box := UiKit.vbox(10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	var tabs := UiKit.hbox(8)
	var holder := UiKit.vbox(0)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	var buttons := {}
	var show_tab := func(id: String) -> void:
		for child in holder.get_children():
			child.queue_free()
		holder.add_child(sell_panel() if id == "sell" else orders_panel())
		for key: String in buttons:
			buttons[key].theme_type_variation = &"PrimaryButton" if key == id else &""
	for entry: Array in [["sell", "Vender", "coin"], ["orders", "Encomendas", "item_treat_box"]]:
		var button := UiKit.button(entry[1], show_tab.bind(entry[0]), &"", UiKit.ui_icon(entry[2]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons[entry[0]] = button
		tabs.add_child(button)
	box.add_child(tabs)
	box.add_child(holder)
	show_tab.call(tab if tab in ["sell", "orders"] else "sell")
	return box


static func sell_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var any := false
		for id: String in Database.items:
			var price := int(Database.items[id].get("sell_price", 0))
			var count := GameState.inventory.count(id)
			if price <= 0 or count == 0:
				continue
			any = true
			var row := UiKit.hbox(8)
			row.add_child(UiKit.icon(Database.item_icon(id), 40))
			row.add_child(UiKit.fill_label("x%d" % count))
			var sell := UiKit.button("+%d" % price, func() -> void:
				var error := GameState.sell(id)
				Events.toast_requested.emit(error if error != "" else "Vendeu %s!" % Database.item_name(id)), &"PrimaryButton", UiKit.ui_icon("coin"))
			sell.custom_minimum_size = Vector2(96, 48)
			row.add_child(sell)
			UiKit.card(box).add_child(row)
		if not any:
			_text(box, "Nada para vender.")
	)


static func orders_panel(focus: String = "") -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		for id: String in Database.progression.orders:
			if focus != "" and id != focus:
				continue
			var data: Dictionary = Database.progression.orders[id]
			var reason := GameState.order_error(id)
			var locked := GameState.requirement_error(data.get("requirements", {}))
			var card := UiKit.card(box, &"ReadyCardPanel" if reason == "" else &"CardPanel")
			card.add_child(UiKit.label(data.name, &"SectionLabel"))
			if locked != "":
				_action(card, "Bloqueada", func() -> String: return locked, locked, "", TaskHelp.open.bind("order", id))
				continue
			_amounts(card, data.inputs)
			card.add_child(reward_chips(data.rewards))
			_action(card, "Entregar", func() -> String: return GameState.fulfill_order(id), reason, "Encomenda entregue!", TaskHelp.open.bind("order", id))
	)


# --- Rotas (passeios, mina, pomar) ------------------------------------------------------

## Rotas de um ou mais grupos ("orchard"...). Só uma por vez em todo o jogo. Mesmo molde das
## estações: o espaço com a rota em andamento em cima, as rotas para escolher embaixo.
static func routes_panel(place: String, focus: String = "") -> Control:
	var groups := place.split("+")
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var activity: Dictionary = GameState.progress.activity
		var remaining := GameState.activity_remaining() if not activity.is_empty() else 0
		box.add_child(UiKit.label("Em andamento  %d/1" % (0 if activity.is_empty() else 1), &"SectionLabel"))
		var slot_row := UiKit.hbox(8)
		if activity.is_empty():
			slot_row.add_child(SheetBuilder.slot_frame(null, "Livre", 0.0, false, true))
		else:
			var running: Dictionary = Database.progression.activities.get(activity.id, {})
			var icon_name: String = running.get("icon", "")
			var duration := maxf(1.0, float(activity.ready_at) - float(activity.started_at))
			slot_row.add_child(SheetBuilder.slot_frame(UiKit.ui_icon(icon_name), "Pronto!" if remaining == 0 else TimeText.short(remaining), 1.0 - remaining / duration, remaining == 0, false))
		box.add_child(slot_row)
		if not activity.is_empty() and remaining == 0:
			var data: Dictionary = Database.progression.activities.get(activity.id, {})
			var collect := UiKit.button("Recolher", func() -> void:
				var error := GameState.collect_activity()
				if error != "":
					Events.toast_requested.emit(error)
				else:
					Events.items_gained.emit(data.get("rewards", {}).get("items", {}), int(data.get("rewards", {}).get("coins", 0)), Vector2(-1.0, -1.0)), &"PrimaryButton")
			box.add_child(collect)
		box.add_child(UiKit.label("Rotas", &"SectionLabel"))
		for id: String in Database.progression.activities:
			var data: Dictionary = Database.progression.activities[id]
			if not str(data.get("place", "walk")) in groups or (focus != "" and id != focus):
				continue
			var card := UiKit.card(box)
			var top := UiKit.hbox(10)
			top.add_child(UiKit.icon(UiKit.ui_icon(data.get("icon", "")), 64))
			var info := UiKit.vbox(4)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label(data.name))
			var details := UiKit.flow()
			details.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(data.seconds))))
			for item: String in data.rewards.get("items", {}):
				details.add_child(UiKit.chip(Database.item_icon(item), "+%d" % int(data.rewards.items[item]), UiKit.GOOD))
			if int(data.rewards.get("coins", 0)) > 0:
				details.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(data.rewards.coins), UiKit.GOOD))
			info.add_child(details)
			top.add_child(info)
			card.add_child(top)
			_action(card, "Começar", func() -> String: return GameState.start_activity(id), GameState.activity_error(id), "Vocês saíram para: " + data.name, TaskHelp.open.bind("route", id))
	)


# --- Passeios -------------------------------------------------------------------------

## "Chamar de volta" pede dois toques: vale até este instante (Unix).
static var _cancel_armed_until := 0.0


## Painel do portão da Praça, no molde das estações: um espaço em cima (o Tiro é um só) e os passeios embaixo.
## Liberados primeiro (do mais curto ao mais longo), depois só os 2 próximos bloqueados.
static func walks_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_child(UiKit.label("Em andamento  %d/1" % (1 if GameState.walking() else 0), &"SectionLabel"))
		box.add_child(_walk_slot())
		var heading := UiKit.hbox(8)
		heading.add_child(UiKit.fill_label("Passeios", &"SectionLabel"))
		if GameState.progress.feature_unlocked("walk_diary"):
			var diary := UiKit.button("Diário", func() -> void:
				Events.sheet_requested.emit("Diário de passeios", walk_diary()), &"", UiKit.ui_icon("item_accessory_set"))
			diary.name = "WalkDiaryButton"
			heading.add_child(diary)
		box.add_child(heading)
		var open: Array[String] = []
		var closed: Array[String] = []
		for id: String in Database.walks.get("walks", {}):
			if GameState.walk_lock_error(id) == "":
				open.append(id)
			elif closed.size() < 2:
				closed.append(id)
		open.sort_custom(func(a: String, b: String) -> bool:
			return int(Database.walks.walks[a].seconds) < int(Database.walks.walks[b].seconds))
		for id: String in open:
			_walk_card(box, id, Database.walks.walks[id], false)
		for id: String in closed:
			_walk_card(box, id, Database.walks.walks[id], true))


## Espaço do passeio: vazio, andando (postal, tempo, barra) ou pronto.
static func _walk_slot() -> Control:
	var panel := PanelContainer.new()
	panel.name = "WalkSlot"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := UiKit.vbox(6)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	if not GameState.walking():
		panel.theme_type_variation = &"CardPanel"
		panel.modulate.a = 0.5
		box.add_child(_center(UiKit.icon(UiKit.ui_icon("action_walk"), 64)))
		box.add_child(_center(UiKit.label("Livre", &"SmallLabel")))
		return panel
	var entry: Dictionary = GameState.walk_state.current
	var ready := GameState.walk_ready()
	var remaining := GameState.walk_remaining()
	panel.theme_type_variation = &"ReadyCardPanel" if ready else &"CardPanel"
	box.add_child(_center(_postcard(GameState.walk_postcard(str(entry.id)), Vector2(128, 80))))
	box.add_child(_center(UiKit.label(str(GameState.walk_def(str(entry.id)).get("name", "")), &"SectionLabel")))
	box.add_child(_center(UiKit.label("Pronto!" if ready else TimeText.short(remaining), &"SmallLabel", UiKit.GOOD if ready else null)))
	if not ready:
		var seconds := maxf(1.0, float(entry.ready_at) - float(entry.started_at))
		box.add_child(UiKit.bar(100.0 * clampf(1.0 - remaining / seconds, 0.0, 1.0), Color(0.96, 0.62, 0.25), 10))
	if ready:
		var collect := UiKit.button("Recolher", func() -> void:
			var error := GameState.collect_walk_error()
			if error != "":
				Events.toast_requested.emit(error)
			else:
				Events.sheet_close_requested.emit()
				GameState.collect_walk(), &"PrimaryButton")
		collect.name = "CollectWalk"
		collect.disabled = GameState.collect_walk_error() != ""
		box.add_child(collect)
		if collect.disabled:
			box.add_child(UiKit.label(GameState.collect_walk_error(), &"SmallLabel", UiKit.BAD))
	else:
		var armed := GameState.now() < _cancel_armed_until
		var call_back := UiKit.button("Toque de novo para chamar" if armed else "Chamar de volta", func() -> void:
			if GameState.now() < _cancel_armed_until:
				_cancel_armed_until = 0.0
				GameState.cancel_walk()
				Events.toast_requested.emit("Tiro voltou para casa")
			else:
				_cancel_armed_until = GameState.now() + 4.0
				Events.toast_requested.emit("Sem prêmio se voltar agora. Toque de novo."))
		call_back.name = "CancelWalk"
		box.add_child(call_back)
	return panel


static func _walk_card(parent: VBoxContainer, id: String, data: Dictionary, locked: bool) -> void:
	var body := UiKit.card(parent)
	body.get_parent().name = "WalkCard_" + id
	if locked:
		body.get_parent().modulate.a = 0.6
	var top := UiKit.hbox(10)
	top.add_child(_postcard(GameState.walk_postcard(id), Vector2(64, 40)))
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(str(data.name)))
	var details := UiKit.flow()
	if locked:
		details.add_child(WishUi.LockIcon.new())
		for chip: Control in _walk_requirement_chips(data.get("requirements", {})):
			details.add_child(chip)
	else:
		details.add_child(UiKit.chip(UiKit.ui_icon("timer"), TimeText.short(int(data.seconds))))
		details.add_child(UiKit.chip(Database.need_icon("energy"), str(int(data.get("energy", 0)))))
	info.add_child(details)
	top.add_child(info)
	body.add_child(top)
	if locked:
		var actions := UiKit.hbox(8)
		var blocked := UiKit.button("Passear", func() -> void: pass)
		blocked.disabled = true
		blocked.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(blocked)
		actions.add_child(UiKit.square_button("?", TaskHelp.open.bind("walk", id)))
		body.add_child(actions)
		return
	body.add_child(walk_exclusives(id, 32))
	var go := UiKit.button("Passear", func() -> void:
		var error := GameState.start_walk(id)
		Events.toast_requested.emit(error if error != "" else "Vamos passear!")
		if error == "":
			Events.sheet_close_requested.emit(), &"PrimaryButton")
	go.name = "StartWalk_" + id
	go.disabled = GameState.walk_error(id) != ""
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(8)
	row.add_child(go)
	if go.disabled:
		row.add_child(UiKit.square_button("?", TaskHelp.open.bind("walk", id)))
	body.add_child(row)
	if go.disabled:
		var reason := UiKit.hbox(6)
		if GameState.walk_hours_error(id) != "":
			reason.add_child(UiKit.icon(UiKit.ui_icon("timer"), 24))
		reason.add_child(UiKit.fill_label(GameState.walk_error(id), &"SmallLabel", UiKit.BAD))
		body.add_child(reason)


## Materiais do passeio (trail) que aparecem na primeira volta ou na tabela, sem repetir.
static func walk_materials(id: String) -> Array[String]:
	var result: Array[String] = []
	var loot: Dictionary = GameState.walk_def(id).get("loot", {})
	var pools: Array = [loot.get("first", {})]
	pools.append_array(loot.get("table", []))
	for pool: Dictionary in pools:
		for item: String in pool.get("items", {}):
			if Database.items.get(item, {}).get("category", "") == "trail" and not item in result:
				result.append(item)
	return result


## Fileira de materiais + apetrecho raro do passeio: colorido = já achou, silhueta = ainda não.
static func walk_exclusives(id: String, px: int) -> Control:
	var row := UiKit.flow(4)
	row.name = "WalkExclusives"
	for item: String in walk_materials(id):
		var picture := UiKit.icon(Database.item_icon(item), px)
		picture.name = "Material_" + item
		if GameState.progress.stat("walk_item:" + item) == 0:
			_silhouette(picture)
		row.add_child(picture)
	var rare := str(GameState.walk_def(id).get("loot", {}).get("rare", {}).get("collection", ""))
	if rare != "":
		var own := GameState.progress.collection.has(rare)
		var cell := UiKit.hbox(2)
		var picture := UiKit.icon(UiKit.ui_icon(str(Database.collections.get(rare, {}).get("icon", ""))), px)
		picture.name = "Rare_" + rare
		if not own:
			_silhouette(picture)
		cell.add_child(picture)
		if own:
			cell.add_child(UiKit.label("✓", &"SectionLabel", UiKit.GOOD))
		row.add_child(cell)
	return row


static func _silhouette(picture: Control) -> void:
	picture.modulate = Color(0.1, 0.08, 0.06, 0.6)


## Diário de passeios: um bloco por passeio (silhueta e requisitos enquanto bloqueado).
static func walk_diary() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var legendary: Dictionary = Database.walks.get("legendary", {})
		if not legendary.is_empty() and GameState.progress.feature_unlocked("legendary_walks"):
			var card := UiKit.card(box)
			card.add_child(UiKit.label("Conjunto de esponjinha · LENDÁRIO", &"SectionLabel"))
			for id: String in legendary.get("collections", []):
				var row := UiKit.hbox(8)
				row.add_child(UiKit.icon(Database.item_icon(id), 48))
				row.add_child(UiKit.fill_label(Database.item_name(id) if GameState.progress.collection.has(id) else "?", &"SmallLabel"))
				card.add_child(row)
			var error := GameState.requirement_error(legendary.get("requirements", {}))
			var complete: bool = legendary.get("collections", []).all(func(id: String) -> bool: return GameState.progress.collection.has(id))
			card.add_child(UiKit.label("Conjunto completo!" if complete else (error if error != "" else "Lendário em até %d voltas" % maxi(1, int(legendary.pity) - int(GameState.walk_state.pity.get("legendary", 0)))), &"SmallLabel"))
		for id: String in Database.walks.get("walks", {}):
			var data: Dictionary = Database.walks.walks[id]
			var locked := GameState.walk_lock_error(id) != ""
			var rare := str(data.get("loot", {}).get("rare", {}).get("collection", ""))
			var found := rare != "" and GameState.progress.collection.has(rare)
			var body := UiKit.card(box, &"ReadyCardPanel" if found else &"CardPanel")
			body.get_parent().name = "Diary_" + id
			var top := UiKit.hbox(10)
			var picture := _postcard(GameState.walk_postcard(id), Vector2(128, 80))
			if locked:
				_silhouette(picture)
			top.add_child(picture)
			var info := UiKit.vbox(4)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_child(UiKit.label("???" if locked else str(data.name), &"SectionLabel"))
			if locked:
				var chips := UiKit.flow()
				chips.add_child(WishUi.LockIcon.new())
				for chip: Control in _walk_requirement_chips(data.get("requirements", {})):
					chips.add_child(chip)
				info.add_child(chips)
			else:
				info.add_child(UiKit.chip(UiKit.ui_icon("action_walk"), "×%d" % GameState.progress.stat("walk:" + id)))
			top.add_child(info)
			body.add_child(top)
			if locked:
				continue
			body.add_child(walk_exclusives(id, 32))
			if rare != "":
				var left := GameState.walk_pity_left(id)
				var note := UiKit.label("Raro encontrado ✓" if found else "Raro garantido em até %d passeios" % left, &"SmallLabel", UiKit.GOOD if found else null)
				note.name = "Pity"
				body.add_child(note))


static func _walk_requirement_chips(requirements: Dictionary) -> Array[Control]:
	var chips: Array[Control] = []
	for key: String in requirements.get("stats", {}):
		var label := "%d/%d" % [mini(GameState.progress.stat(key), int(requirements.stats[key])), int(requirements.stats[key])]
		chips.append(UiKit.chip(UiKit.ui_icon("action_walk"), label + " passeios" if key == "walk" else label))
	if requirements.has("bond"):
		chips.append(UiKit.chip(UiKit.ui_icon("bond_heart"), str(int(requirements.bond))))
	for upgrade: String in requirements.get("owned", []):
		var built: Dictionary = Database.progression.upgrades.get(upgrade, {})
		chips.append(UiKit.chip(UiKit.ui_icon(str(built.get("icon", "tab_map"))), str(built.get("name", upgrade)).trim_prefix("Desbloquear ")))
	if requirements.has("hours"):
		chips.append(UiKit.chip(UiKit.ui_icon("timer"), "%dh" % int(requirements.hours[0])))
	if requirements.has("quests") and not requirements.has("stats") and not requirements.has("bond"):
		chips.append(UiKit.chip(UiKit.ui_icon("tab_tasks"), "Missão"))
	return chips


static func _postcard(path: String, size: Vector2) -> TextureRect:
	var rect := UiKit.icon(WalkResult.postcard_texture(path), 0)
	rect.custom_minimum_size = size
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect


static func _center(control: Control) -> Control:
	if control is Label:
		(control as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return control


# --- Atributos e coleção --------------------------------------------------------------

static func skills_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		for id: String in Database.progression.skills:
			var data: Dictionary = Database.progression.skills[id]
			var info := GameState.skill_info(id)
			var card := UiKit.card(box)
			var top := UiKit.hbox(8)
			top.add_child(UiKit.icon(UiKit.ui_icon(data.icon), 40))
			top.add_child(UiKit.fill_label(data.name, &"SectionLabel"))
			top.add_child(UiKit.short_label("Nv %d" % int(info.level), &"SectionLabel"))
			card.add_child(top)
			var line := UiKit.hbox(6)
			var bar := UiKit.bar(100 if info.max else float(info.xp) / float(info.needed) * 100, Color(data.color), 12)
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.add_child(bar)
			line.add_child(UiKit.short_label("Máx." if info.max else "%d/%d" % [int(info.xp), int(info.needed)], &"SmallLabel"))
			card.add_child(line)
			var next := _next_milestone(id, int(info.level))
			if not next.is_empty():
				var unlock := UiKit.hbox(6)
				unlock.add_child(UiKit.short_label("Nv %d →" % int(next.level), &"SmallLabel"))
				unlock.add_child(UiKit.icon(next.icon, 32))
				unlock.add_child(UiKit.fill_label(next.name, &"SmallLabel"))
				card.add_child(unlock)
		if GameState.requirement_error(Database.worlds.nature.requirements) == "":
			box.add_child(UiKit.label("Coleta do Tiro · evolui com o uso", &"SectionLabel"))
			for site: String in Database.progression.nature_sites:
				var data: Dictionary = Database.progression.nature_sites[site]
				var info := GameState.progress.nature_info(site)
				var card := UiKit.card(box)
				card.name = "NatureSkill_" + site
				var heading := UiKit.hbox(6)
				heading.add_child(UiKit.icon(UiKit.ui_icon(data.icon)))
				heading.add_child(UiKit.fill_label(data.name, &"SectionLabel"))
				heading.add_child(UiKit.short_label("Fechado" if info.level == 0 else "Nv %d" % info.level, &"SmallLabel"))
				card.add_child(heading)
				if info.level > 0:
					card.add_child(UiKit.bar(100 if info.max else 100.0 * info.xp / maxi(1, int(info.needed)), UiKit.GOOD, 10))
					card.add_child(UiKit.label("Completo" if info.max else "Próximo: " + str(data.levels[info.level].label), &"SmallLabel"))
				card.add_child(UiKit.button("Ver evolução", func() -> void:
					Events.sheet_requested.emit("Evolução · " + str(data.name), NatureUi.levels_panel(site))))
	)


## Próximo conteúdo que o atributo libera: { level, icon, name } (vazio se nada).
static func _next_milestone(skill_id: String, current: int) -> Dictionary:
	var best := {}
	for kind: String in ["activity", "crop", "recipe"]:
		var group: Dictionary = {"activity": Database.progression.activities, "crop": Database.crops, "recipe": Database.recipes}[kind]
		for content_id: String in group:
			var entry: Dictionary = group[content_id]
			var required := int(entry.get("requirements", {}).get("skills", {}).get(skill_id, 0))
			if required <= current or (not best.is_empty() and required >= int(best.level)):
				continue
			match kind:
				"activity":
					best = {"level": required, "icon": UiKit.ui_icon(entry.get("icon", "action_play")), "name": entry.name}
				"crop":
					best = {"level": required, "icon": Database.item_icon(content_id), "name": Database.item_name(content_id)}
				"recipe":
					best = {"level": required, "icon": Database.item_icon(Database.recipe_output(entry)), "name": Database.item_name(Database.recipe_output(entry))}
	return best


static var _collection_tab := "clothes"


## O quiosque reúne costura e compras; mantém o molde das estações.
static func petshop_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		box.add_child(UiKit.label("Costura", &"SectionLabel"))
		if GameState.has_upgrade("sewing_table"):
			box.add_child(SheetBuilder.station_view("sewing"))
		else:
			box.add_child(purchase("sewing_table"))
		box.add_child(UiKit.label("Comprar", &"SectionLabel"))
		for id: String in Database.collections:
			var data: Dictionary = Database.collections[id]
			if data.get("shop", "") != "petshop":
				continue
			var own := GameState.progress.collection.has(id)
			var card := UiKit.card(box)
			var row := UiKit.hbox(8)
			row.add_child(UiKit.icon(Database.item_icon(id), 64))
			row.add_child(UiKit.fill_label(str(data.name)))
			card.add_child(row)
			var button := UiKit.button("Vestir" if own else "Comprar · %d" % int(data.price), func() -> void:
				var error := GameState.equip(id) if own else GameState.buy_cosmetic(id)
				if error != "":
					Events.toast_requested.emit(error))
			button.disabled = (GameState.equip_error(id) if own else GameState.buy_cosmetic_error(id)) != ""
			card.add_child(button)
		for id: String in Database.progression.get("shop_items", {}):
			var data: Dictionary = Database.progression.shop_items[id]
			if data.get("shop", "") != "petshop":
				continue
			var card := UiKit.card(box)
			card.add_child(UiKit.label(str(data.name), &"SectionLabel"))
			card.add_child(reward_chips({"items": data.items}))
			var button := UiKit.button("Comprar · %d" % int(data.price), func() -> void:
				var error := GameState.buy_shop_item(id)
				if error != "":
					Events.toast_requested.emit(error))
			button.disabled = GameState.buy_shop_item_error(id) != ""
			card.add_child(button)
		if not GameState.has_upgrade("walk_bag"):
			box.add_child(purchase("walk_bag"))
	)

static func collection_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var tabs := UiKit.hbox(8)
		for entry: Array in [["clothes", "Roupas"], ["finds", "Achados"]]:
			if entry[0] == "finds" and not GameState.progress.feature_unlocked("finds"):
				continue
			var button := UiKit.button(str(entry[1]), func() -> void:
				_collection_tab = str(entry[0])
				(box as SheetBuilder.LiveBox).refresh())
			button.disabled = _collection_tab == entry[0]
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			tabs.add_child(button)
		box.add_child(tabs)
		box.add_child(FindUi.album() if _collection_tab == "finds" and GameState.progress.feature_unlocked("finds") else _clothes_panel())
	)

static func _clothes_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var count := 0
		var grid := GridContainer.new()
		grid.columns = 2
		grid.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		# Grade: conquistado = colorido com nome; ainda não = apagado com "?".
		for id: String in Database.collections:
			var data: Dictionary = Database.collections[id]
			var earned := GameState.progress.collection.has(id)
			if data.get("rarity", "") == "legendary" and not earned and not GameState.progress.feature_unlocked("legendary_walks"):
				continue
			count += 1 if earned else 0
			var card := UiKit.card(grid, &"ReadyCardPanel" if earned else &"CardPanel")
			card.alignment = BoxContainer.ALIGNMENT_CENTER
			var picture := UiKit.icon(UiKit.ui_icon(data.icon), 48)
			picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			card.add_child(picture)
			var source := str(data.get("source", ""))
			var is_walk_rare := (source.begins_with("walk:") or source.begins_with("legendary:")) and not earned
			if is_walk_rare:
				_silhouette(picture)
			var title := UiKit.label(data.name if earned else "?", &"SmallLabel")
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			card.add_child(title)
			if data.get("rarity", "") == "legendary":
				card.add_child(UiKit.label("LENDÁRIO", &"SmallLabel", Color("b56be0")))
			if earned:
				var wearing := str(GameState.progress.equipped.get(str(data.get("slot", "")), "")) == id
				var button := UiKit.button("Tirar" if wearing else "Vestir", func() -> void:
					var error := GameState.unequip(str(data.slot)) if wearing else GameState.equip(id)
					if error != "":
						Events.toast_requested.emit(error))
				button.disabled = not wearing and GameState.equip_error(id) != ""
				card.add_child(button)
				if not wearing and GameState.equip_error(id) != "":
					card.add_child(UiKit.label(GameState.equip_error(id), &"SmallLabel"))
			if is_walk_rare:
				var walk_name := str(GameState.walk_def(source.trim_prefix("walk:")).get("name", ""))
				var hint := UiKit.label("Lendário de passeio" if source.begins_with("legendary:") else "Raro de passeio: " + walk_name, &"SmallLabel")
				hint.name = "RareHint_" + id
				hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				card.add_child(hint)
				var go := UiKit.button("Ir", Places.go.bind({"world": "park", "place": "walk"}))
				go.custom_minimum_size.y = 48
				card.add_child(go)
			elif not earned and (data.get("shop", "") == "petshop" or data.has("recipe")):
				var go := UiKit.button("Pet shop", Places.go.bind({"world": "park", "place": "petshop"}))
				go.disabled = Places.world_error("park") != "" or Places.place_error(Database.worlds.get("park", {}).get("places", {}).get("petshop", {})) != ""
				card.add_child(go)
			if not earned:
				card.get_parent().modulate.a = 0.45 if not is_walk_rare else 0.8
		var header := UiKit.hbox(8)
		header.add_child(UiKit.icon(UiKit.ui_icon("item_accessory_set"), 32))
		header.add_child(UiKit.short_label("%d/%d" % [count, Database.collections.size()], &"SectionLabel"))
		box.add_child(header)
		box.add_child(grid)
	)


# --- Peças ------------------------------------------------------------------------------

static func rewards_text(rewards: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(rewards.get("coins", 0)) > 0:
		parts.append("%d moedas" % int(rewards.coins))
	if not rewards.get("items", {}).is_empty():
		parts.append(Database.describe_amounts(rewards["items"]))
	for id: String in rewards.get("skill_xp", {}):
		parts.append("+%d XP %s" % [int(rewards.skill_xp[id]), Database.progression.skills[id].name])
	for id: String in rewards.get("collections", []):
		parts.append(Database.collections.get(id, {}).get("name", id))
	return " · ".join(parts)


## Linha de título de cartão: ícone (UiKit.ui_icon) + nome.
static func _title(card: VBoxContainer, icon_name: String, text: String) -> void:
	var row := UiKit.hbox()
	var texture := UiKit.ui_icon(icon_name) if icon_name != "" else null
	if texture:
		row.add_child(UiKit.icon(texture, 32))
	var title := UiKit.label(text, &"SectionLabel")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	card.add_child(row)


static func _text(box: VBoxContainer, text: String, small: bool = false) -> void:
	if text != "":
		box.add_child(UiKit.label(text, &"SmallLabel" if small else &""))


## Botão de ação do GameState; toast com o resultado. Bloqueado: motivo curto embaixo e,
## se houver `help`, um "?" ao lado que abre o "Como fazer".
static func _action(box: VBoxContainer, text: String, action: Callable, reason: String = "", done: String = "Feito!", help: Callable = Callable()) -> void:
	var button := UiKit.button(text, func() -> void:
		var error: String = action.call()
		Events.toast_requested.emit(error if error != "" else done), &"PrimaryButton")
	button.disabled = reason != ""
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(8)
	row.add_child(button)
	if reason != "" and help.is_valid():
		row.add_child(UiKit.square_button("?", help))
	box.add_child(row)
	if reason != "":
		_text(box, reason, true)


## Chips "tem/precisa" com ícone de cada item (verde = suficiente).
static func _amounts(card: VBoxContainer, amounts: Dictionary) -> void:
	if amounts.is_empty():
		return
	var row := UiKit.flow()
	for id: String in amounts:
		var have := GameState.inventory.count(id)
		var need := int(amounts[id])
		row.add_child(item_chip(id, need))
	card.add_child(row)


## [Ir | Receber] + "?". O Ir leva ao lugar da missão; o "?" explica o que falta.
static func quest_action(box: VBoxContainer, id: String) -> void:
	var ready := GameState.quest_error(id) == ""
	var row := UiKit.hbox(8)
	var main := UiKit.button("Receber" if ready else "Ir", func() -> void:
		if ready:
			var error := GameState.claim_quest(id)
			if error != "":
				Events.toast_requested.emit(error)
		else:
			Places.go(quest_go_target(id)), &"PrimaryButton")
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(main)
	if not ready:
		row.add_child(UiKit.square_button("?", TaskHelp.open.bind("quest", id)))
	box.add_child(row)


## Leva ao lugar do OBJETIVO da missão (ex.: ensopado → fogão), sem pular para o ingrediente
## que falta; a cadeia de passos fica no "?" (TaskHelp).
static func quest_go_target(id: String) -> Dictionary:
	return Places.quest_target(id)


## Objetivo que falta (ou o primeiro, se todos cumpridos).
static func current_goal(id: String) -> Dictionary:
	var goals: Array = Database.quests[id].goals
	for goal: Dictionary in goals:
		if GameState.goal_value(goal) < int(goal.get("target", 1)):
			return goal
	return goals[0]


## Diária ou semanal: [ícone] nome · barra · recompensa · [Ir | Receber].
static func routine_card(box: VBoxContainer, kind: String, id: String) -> void:
	var data := GameState.routine_data(kind, id)
	var goal: Dictionary = data.goal
	var target := int(goal.get("target", 1))
	var value := mini(GameState.routine_value(kind, id), target)
	var claimed := GameState.routine_claimed(kind, id)
	var ready := GameState.routine_error(kind, id) == ""
	var card := UiKit.card(box, &"ReadyCardPanel" if ready else &"CardPanel")
	if claimed:
		card.get_parent().modulate.a = 0.55
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(stat_icon(goal.key), 40))
	var info := UiKit.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(data.name))
	var line := UiKit.hbox(6)
	var bar := UiKit.bar(100.0 * value / maxi(1, target), UiKit.GOOD, 10)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(bar)
	line.add_child(UiKit.short_label("%d/%d" % [value, target], &"SmallLabel"))
	info.add_child(line)
	info.add_child(reward_chips(data.get("rewards", {})))
	row.add_child(info)
	if claimed:
		row.add_child(UiKit.short_label("✓", &"SectionLabel", UiKit.GOOD))
	else:
		var button := UiKit.button("Receber" if ready else "Ir", func() -> void:
			if ready:
				var error := GameState.claim_routine(kind, id)
				Events.toast_requested.emit(error if error != "" else "Missão concluída!")
			else:
				Places.go(Places.goal_target({"type": "stat", "key": goal.key})), &"PrimaryButton")
		button.custom_minimum_size = Vector2(96, 48)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(button)
	card.add_child(row)
	# Frase de ação ocupa a largura toda, sem ficar espremida pelo botão Ir.
	card.add_child(UiKit.label(data.get("description", data.name), &"SmallLabel"))


## História completa: capítulos passados (✓), o atual com os passos e os próximos apagados.
static func story_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var current := GameState.progress.chapter_index()
		for i in Database.progression.chapters.size():
			var chapter: Dictionary = Database.progression.chapters[i]
			var index: int = i + 1
			var card := UiKit.card(box, &"ReadyCardPanel" if index == current else &"CardPanel")
			if index > current:
				card.get_parent().modulate.a = 0.5
			var title := "%d · %s" % [index, chapter.name] if index <= current else "%d · ?" % index
			card.add_child(UiKit.label(("✓ " if index < current else "") + title, &"SectionLabel", UiKit.GOOD if index < current else null))
			if index == current:
				for id in GameState.progress.main_quests(index):
					var claimed := GameState.progress.claimed_quests.has(id)
					var row := UiKit.hbox(8)
					row.add_child(UiKit.icon(goal_icon(current_goal(id)), 32))
					row.add_child(UiKit.fill_label(Database.quests[id].name, &"SmallLabel", UiKit.GOOD if claimed else null))
					if claimed:
						row.add_child(UiKit.short_label("✓", &"", UiKit.GOOD))
					card.add_child(row)
			if index >= current:
				card.add_child(reward_chips(chapter.get("rewards", {})))
	)


# --- Peças visuais de missão ---------------------------------------------------------------

## Ícone de um objetivo pelo tipo: item, construção, atributo, moedas ou contador.
static func goal_icon(goal: Dictionary) -> Texture2D:
	var key: String = goal.get("key", "")
	match str(goal.get("type", "stat")):
		"owned":
			return UiKit.ui_icon(Database.progression.upgrades.get(key, {}).get("icon", "tab_house"))
		"skill":
			return UiKit.ui_icon(Database.progression.skills.get(key, {}).get("icon", "xp"))
		"have", "deliver":
			return Database.item_icon(key)
		"coins":
			return UiKit.ui_icon("coin")
		"chapter":
			return UiKit.ui_icon("tab_tasks")
		"quest":
			return npc_portrait(str(Database.quests.get(key, {}).get("npc", "")))
	return stat_icon(key)


## Ícone de um contador ("harvest", "produce:plank", "activity:lane"...).
static func stat_icon(key: String) -> Texture2D:
	var prefix := key.get_slice(":", 0)
	var arg := key.get_slice(":", 1) if ":" in key else ""
	if arg != "" and prefix in ["harvest", "produce"]:
		return Database.item_icon(arg)
	if prefix == "activity":
		return UiKit.ui_icon(Database.progression.activities.get(arg, {}).get("icon", "action_play"))
	if prefix == "talk":
		return npc_portrait(arg)
	if prefix == "open":
		return UiKit.ui_icon(Database.worlds[arg].get("icon", "tab_map") if Database.worlds.has(arg) else "tab_" + arg)
	var icons := {"feed": "need_hunger", "bathe": "action_bathe", "play": "action_play", "pet": "action_pet", "wish": "tab_wishes", "harvest": "tab_farm", "water": "action_water", "produce": "item_carrot_snack", "trade": "coin", "sold": "coin", "orders": "item_treat_box", "order": "item_treat_box", "explore": "tab_map", "quests": "tab_tasks", "build": "item_plank"}
	return UiKit.ui_icon(icons.get(prefix, "xp"))


## Linha de objetivo: ícone + instrução breve + barra e "3/6".
static func goal_row(goal: Dictionary, value: int, px: int = 32) -> HBoxContainer:
	var target := int(goal.get("target", 1))
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(goal_icon(goal), px))
	var info := UiKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(UiKit.label(goal.get("label", ""), &"SmallLabel"))
	var progress := UiKit.hbox(8)
	var bar := UiKit.bar(100.0 * mini(value, target) / maxi(1, target), UiKit.GOOD, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress.add_child(bar)
	progress.add_child(UiKit.short_label("%d/%d" % [mini(value, target), target], &"", UiKit.GOOD if value >= target else null))
	info.add_child(progress)
	row.add_child(info)
	return row


## Recompensas em chips: [moeda] +40  [cenoura] +2  [atributo] +20  [roupa] +1.
static func reward_chips(rewards: Dictionary) -> HFlowContainer:
	var row := UiKit.flow()
	if int(rewards.get("coins", 0)) > 0:
		row.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(rewards.coins)))
	for id: String in rewards.get("items", {}):
		row.add_child(UiKit.chip(Database.item_icon(id), "+%d" % int(rewards.items[id])))
	for id: String in rewards.get("skill_xp", {}):
		if Database.progression.skills.has(id) and GameState.progress.skills_visible():
			row.add_child(UiKit.chip(UiKit.ui_icon(Database.progression.skills[id].get("icon", "xp")), "+%d" % int(rewards.skill_xp[id])))
	for id: String in rewards.get("collections", []):
		if not GameState.progress.collection.has(id):
			row.add_child(UiKit.chip(UiKit.ui_icon("item_accessory_set"), "+1"))
	if int(rewards.get("affection", 0)) > 0:
		row.add_child(UiKit.chip(UiKit.ui_icon("bond_heart"), "+%d" % int(rewards.affection)))
	return row


## Ingrediente: ícone + tem/precisa (verde/vermelho); tocar mostra de onde vem.
static func item_chip(id: String, need: int) -> Button:
	var have := GameState.inventory.count(id)
	return UiKit.tap_chip(Database.item_icon(id), "%d/%d" % [have, need], TaskHelp.open.bind("item", id, need), UiKit.GOOD if have >= need else UiKit.BAD)
