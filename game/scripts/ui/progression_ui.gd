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
	var album_line := GameState.album_talk(npc_id)
	var panel := UiKit.vbox(10)
	var speech := npc_header(panel, npc_id, "", true)
	panel.add_child(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var npc: Dictionary = Database.npcs.get(npc_id, {})
		var active := Places.npc_active_quests(npc_id)
		speech.text = album_line if album_line != "" else (str(Database.quests[active[0]].get("dialogue", "")) if not active.is_empty() else str(npc.get("greeting", "")))
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
	var row := UiKit.hbox(4)
	var picture: Control
	if animated and npc.has("portrait_animations"):
		var portrait := NpcPortrait.new()
		portrait.name = "NpcPortrait"
		portrait.npc_id = npc_id
		portrait.custom_minimum_size = Vector2(96, 96)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		picture = portrait
	else:
		picture = UiKit.icon(npc_portrait(npc_id), 96)
	picture.size_flags_vertical = Control.SIZE_SHRINK_END  # o retrato fica embaixo e o balão aponta para ele
	row.add_child(picture)
	var balloon := SpeechBubble.new(speech if speech != "" else str(npc.get("greeting", "")), str(npc.get("name", "")))
	balloon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(balloon)
	box.add_child(row)
	return balloon.label


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
	# Bloqueio por requisito (não por moedas): cartão apagado e cadeado com o motivo, sem botão.
	var lock := GameState.requirement_error(data.get("requirements", {}))
	if lock != "":
		card.get_parent().modulate.a = 0.55
	var cost := UiKit.flow()
	if int(data.cost) <= 0:
		cost.add_child(UiKit.chip(UiKit.ui_icon("coin"), "Grátis", UiKit.GOOD))
	else:
		cost.add_child(UiKit.chip(UiKit.ui_icon("coin"), "%d/%d" % [mini(GameState.coins, int(data.cost)), int(data.cost)], UiKit.GOOD if GameState.coins >= int(data.cost) else UiKit.BAD))
	var space := GameState.storage_upgrade_preview(id)
	if not space.is_empty():
		var gain := UiKit.chip(UiKit.ui_icon(str(data.get("icon", "station_" + str(space.depot)))), "%d → %d" % [int(space.from), int(space.to)])
		gain.name = "SpaceChip"
		cost.add_child(gain)
	card.add_child(cost)
	_amounts(card, data.get("materials", {}))
	if lock != "":
		card.add_child(UiKit.lock_hint(lock, TaskHelp.open.bind("upgrade", id)))
		return
	var free: bool = int(data.cost) <= 0 and (data.get("materials", {}) as Dictionary).is_empty()
	_action(card, "Construir" if free else "Comprar", func() -> String: return GameState.buy_upgrade(id), GameState.upgrade_error(id), "%s é seu!" % data.name, TaskHelp.open.bind("upgrade", id))


# --- Vila: vender e encomendas --------------------------------------------------------

## Acessos antigos continuam válidos; cada lugar abre só sua função.
static func market_panel(tab: String = "sell", world_id: String = "village") -> Control:
	return MarketUi.orders() if tab == "orders" else MarketUi.sell(world_id)

static func sell_panel() -> Control:
	return MarketUi.sell()

static func orders_panel(focus: String = "") -> Control:
	return MarketUi.orders(focus)


# --- Rotas (passeios, mina, pomar) ------------------------------------------------------

## Rotas de um ou mais grupos ("orchard"...). Só uma por vez em todo o jogo. Mesmo molde das
## estações: o espaço com a rota em andamento em cima, as rotas para escolher embaixo.
static func routes_panel(place: String, focus: String = "") -> Control:
	var groups := place.split("+")
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var activity: Dictionary = GameState.progress.activity
		var remaining := GameState.activity_remaining() if not activity.is_empty() else 0
		var slot_row := SheetBuilder.slot_flow()
		var running_data: Dictionary = {}
		if activity.is_empty():
			slot_row.add_child(SheetBuilder.slot_frame(null, "", 0.0, false, true))
		else:
			var running: Dictionary = Database.progression.activities.get(activity.id, {})
			running_data = running
			var icon_name: String = running.get("icon", "")
			var duration := maxf(1.0, float(activity.ready_at) - float(activity.started_at))
			slot_row.add_child(SheetBuilder.slot_frame(UiKit.ui_icon(icon_name), "Pronto!" if remaining == 0 else TimeText.short(remaining), 1.0 - remaining / duration, remaining == 0, false))
		var collect_text := "Pegar" if not activity.is_empty() and remaining == 0 else ""
		box.add_child(SheetBuilder.slot_strip(slot_row, collect_text, func() -> void:
			var error := GameState.collect_activity()
			if error != "":
				Events.toast_requested.emit(error)
			else:
				Events.items_gained.emit(running_data.get("rewards", {}).get("items", {}), int(running_data.get("rewards", {}).get("coins", 0)), Vector2(-1.0, -1.0))))
		box.add_child(UiKit.label("Rotas", &"SectionLabel"))
		for id: String in Database.progression.activities:
			var data: Dictionary = Database.progression.activities[id]
			if not str(data.get("place", "walk")) in groups or (focus != "" and id != focus):
				continue
			var chips: Array[Control] = [UiKit.chip(UiKit.ctl_icon("clock"), TimeText.short(int(data.seconds)))]
			for item: String in data.rewards.get("items", {}):
				chips.append(UiKit.chip(Database.item_icon(item), "+%d" % int(data.rewards.items[item]), UiKit.GOOD))
			if int(data.rewards.get("coins", 0)) > 0:
				chips.append(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(data.rewards.coins), UiKit.GOOD))
			var reason := GameState.activity_error(id)
			var go := UiKit.secondary("Começar", func() -> void:
				var error := GameState.start_activity(id)
				if error != "":
					Events.toast_requested.emit(error), null, true)
			go.disabled = reason != ""
			go.custom_minimum_size.x = 88
			var row := UiKit.list_row(UiKit.ui_icon(data.get("icon", "")), str(data.name), chips, go)
			box.add_child(row)
			if reason != "":
				var hint := UiKit.hbox(8)
				hint.add_child(UiKit.fill_label(reason, &"SmallLabel"))
				hint.add_child(UiKit.icon_button(UiKit.ctl_icon("help"), TaskHelp.open.bind("route", id), 44))
				(row.get_child(0) as VBoxContainer).add_child(hint)
	)


# --- Passeios -------------------------------------------------------------------------

## "Chamar de volta" pede dois toques: vale até este instante (Unix).
static var _cancel_armed_until := 0.0


## Painel do portão da Praça, no molde das estações: um espaço em cima (o Tiro é um só) e os passeios embaixo.
## Liberados primeiro (do mais curto ao mais longo), depois só os 2 próximos bloqueados.
static func walks_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		if GameState.friend_walk_bonus() > 0:
			box.add_child(UiKit.label("Pipoca vai junto · +1 achado", &"SmallLabel"))
		if GameState.has_upgrade("walk_bag"):
			box.add_child(UiKit.label("Bolsinha de passeio · +1 achado", &"SmallLabel"))
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


## Espaço do passeio em bolinha: vazio, andando (tempo no anel) ou bagagem esperando; ao lado, o postal e a ação.
static func _walk_slot() -> Control:
	var strip := UiKit.hbox(10)
	strip.mouse_filter = Control.MOUSE_FILTER_PASS
	if GameState.walk_ready():
		return _baggage_slot(strip)
	if not GameState.walk_state.active():
		var empty := UiKit.slot_dot(SlotDot.EMPTY)
		empty.name = "WalkSlot"
		strip.add_child(empty)
		var hint := UiKit.fill_label("Escolha um passeio", &"SmallLabel")
		hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		strip.add_child(hint)
		return strip
	var entry: Dictionary = GameState.walk_state.current
	var remaining := GameState.walk_remaining()
	var seconds := maxf(1.0, float(entry.ready_at) - float(entry.started_at))
	var dot := UiKit.slot_dot(SlotDot.BUSY, UiKit.ui_icon("action_walk"), clampf(1.0 - remaining / seconds, 0.0, 1.0), TimeText.short(remaining))
	dot.name = "WalkSlot"
	strip.add_child(dot)
	var info := UiKit.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var heading := UiKit.hbox(8)
	heading.add_child(_postcard(GameState.walk_postcard(str(entry.id)), Vector2(64, 40)))
	heading.add_child(UiKit.fill_label(str(GameState.walk_def(str(entry.id)).get("name", "")), &"SectionLabel"))
	info.add_child(heading)
	var armed := GameState.now() < _cancel_armed_until
	var call_back := UiKit.secondary("Toque de novo para chamar" if armed else "Chamar de volta", func() -> void:
		if GameState.now() < _cancel_armed_until:
			_cancel_armed_until = 0.0
			GameState.cancel_walk()
			Events.toast_requested.emit("Tiro voltou para casa")
		else:
			_cancel_armed_until = GameState.now() + 4.0
			Events.toast_requested.emit("Sem prêmio se voltar agora. Toque de novo."), null, true)
	call_back.name = "CancelWalk"
	info.add_child(call_back)
	strip.add_child(info)
	return strip


## O Tiro já voltou: a bagagem espera. Guardar o que cabe é uma ação à parte; o que sobra continua aqui.
static func _baggage_slot(strip: HBoxContainer) -> Control:
	var view := GameState.walk_result_view()
	var dot := UiKit.slot_dot(SlotDot.READY, UiKit.ui_icon("action_walk"), 1.0, "Voltou!", UiKit.GOOD)
	dot.name = "WalkSlot"
	strip.add_child(dot)
	var info := UiKit.vbox(6)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var heading := UiKit.hbox(8)
	heading.add_child(_postcard(str(view.get("postcard", "")), Vector2(64, 40)))
	heading.add_child(UiKit.fill_label(str(view.get("name", "")), &"SectionLabel"))
	info.add_child(heading)
	var chips := UiKit.flow(4)
	chips.name = "BaggageChips"
	var left: Dictionary = GameState.walk_state.baggage_left()
	for item_id: String in left:
		var chip := UiKit.chip(Database.item_icon(item_id), "×%d" % int(left[item_id]))
		chip.name = "Baggage_" + item_id
		chips.add_child(chip)
	info.add_child(chips)
	var error := GameState.walk_baggage_error()
	if error == "":
		var store := UiKit.primary("Guardar achados", func() -> void: GameState.claim_walk_baggage())
		store.name = "CollectWalk"
		info.add_child(store)
		var hint := GameState.walk_baggage_hint()
		if hint != "":
			info.add_child(UiKit.label(hint, &"SmallLabel", Palette.INK_SOFT))
	else:
		var lock := UiKit.lock_hint(error)
		lock.name = "BaggageBlocked"
		info.add_child(lock)
		var depot := GameState.walk_baggage_depot()
		if depot != "":
			var data: Dictionary = Database.progression.storage[depot]
			var go := UiKit.secondary("Abrir " + GameState.storage_name(depot), func() -> void:
				Events.sheet_close_requested.emit()
				Events.world_requested.emit(str(data.get("world", "house")), str(data.get("place", ""))), null, true)
			go.name = "GoDepot"
			info.add_child(go)
	strip.add_child(info)
	return strip


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
		details.add_child(UiKit.lock_icon())
		for chip: Control in _walk_requirement_chips(data.get("requirements", {})):
			details.add_child(chip)
	else:
		details.add_child(UiKit.chip(UiKit.ctl_icon("clock"), TimeText.short(int(data.seconds))))
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
		actions.add_child(UiKit.icon_button(UiKit.ctl_icon("help"), TaskHelp.open.bind("walk", id)))
		body.add_child(actions)
		return
	body.add_child(walk_exclusives(id, 32))
	var go := UiKit.button("Passear", func() -> void:
		var error := GameState.start_walk(id)
		if error != "":
			Events.toast_requested.emit(error)
		else:
			Events.sheet_close_requested.emit(), &"PrimaryButton")
	go.name = "StartWalk_" + id
	go.disabled = GameState.walk_error(id) != ""
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(8)
	row.add_child(go)
	if go.disabled:
		row.add_child(UiKit.icon_button(UiKit.ctl_icon("help"), TaskHelp.open.bind("walk", id)))
	body.add_child(row)
	if go.disabled:
		var reason := UiKit.hbox(6)
		if GameState.walk_hours_error(id) != "":
			reason.add_child(UiKit.icon(UiKit.ctl_icon("clock"), 24))
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
	picture.modulate = Palette.INK


## Diário de passeios: um bloco por passeio (silhueta e requisitos enquanto bloqueado).
static func walk_diary() -> Control:
	return SheetBuilder.tall(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
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
				chips.add_child(UiKit.lock_icon())
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
				body.add_child(note)))


static func _walk_requirement_chips(requirements: Dictionary) -> Array[Control]:
	var chips: Array[Control] = []
	for key: String in requirements.get("stats", {}):
		var label := "%d/%d" % [mini(GameState.progress.stat(key), int(requirements.stats[key])), int(requirements.stats[key])]
		chips.append(UiKit.chip(UiKit.ui_icon("action_walk"), label + " passeios" if key == "walk" else label))
	for upgrade: String in requirements.get("owned", []):
		var built: Dictionary = Database.progression.upgrades.get(upgrade, {})
		chips.append(UiKit.chip(UiKit.ui_icon(str(built.get("icon", "tab_map"))), str(built.get("name", upgrade)).trim_prefix("Desbloquear ")))
	if requirements.has("hours"):
		chips.append(UiKit.chip(UiKit.ctl_icon("clock"), "%dh" % int(requirements.hours[0])))
	if requirements.has("quests") and not requirements.has("stats"):
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
	return GrowthUi.panel()


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


## Compras do quiosque; a costura tem acesso próprio e usa StationTray.
static func petshop_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
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
			var button := UiKit.secondary("Vestir" if own else "Comprar · %d" % int(data.price), func() -> void:
				var error := GameState.equip(id) if own else GameState.buy_cosmetic(id)
				if error != "":
					Events.toast_requested.emit(error), null, true)
			button.disabled = (GameState.equip_error(id) if own else GameState.buy_cosmetic_error(id)) != ""
			card.add_child(button)
		for id: String in Database.progression.get("shop_items", {}):
			var data: Dictionary = Database.progression.shop_items[id]
			if data.get("shop", "") != "petshop":
				continue
			var card := UiKit.card(box)
			card.add_child(UiKit.label(str(data.name), &"SectionLabel"))
			card.add_child(reward_chips({"items": data.items}))
			var button := UiKit.secondary("Comprar · %d" % int(data.price), func() -> void:
				var error := GameState.buy_shop_item(id)
				if error != "":
					Events.toast_requested.emit(error), null, true)
			button.disabled = GameState.buy_shop_item_error(id) != ""
			card.add_child(button)
		if not GameState.has_upgrade("walk_bag"):
			box.add_child(purchase("walk_bag"))
	)

static func collection_panel() -> Control:
	return SheetBuilder.tall(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var entries: Array[Dictionary] = [{"id": "clothes", "text": "Roupas"}]
		for entry: Dictionary in [{"id": "finds", "text": "Achados"}, {"id": "friends", "text": "Amigos"}]:
			if GameState.progress.feature_unlocked(entry.id): entries.append(entry)
		if not entries.any(func(entry: Dictionary) -> bool: return entry.id == _collection_tab): _collection_tab = "clothes"
		box.add_child(UiKit.segmented(entries, _collection_tab, func(id: String) -> void:
			_collection_tab = id
			(box as SheetBuilder.LiveBox).refresh()))
		match _collection_tab:
			"friends": box.add_child(FriendUi.album())
			"finds": box.add_child(FindUi.album())
			_: box.add_child(_clothes_panel())
	))


static func _clothes_panel() -> Control:
	return SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
		var count := 0
		var total := 0
		var grid := GridContainer.new()
		grid.name = "ClothesGrid"
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 4)
		grid.add_theme_constant_override("v_separation", 4)
		for id: String in Database.collections:
			var data: Dictionary = Database.collections[id]
			var earned := GameState.progress.collection.has(id)
			if not GameState.has_overlay(id): continue
			if str(data.get("source", "")).begins_with("friend:") and not earned and not GameState.progress.feature_unlocked("friends"): continue
			if data.get("rarity", "") == "legendary" and not earned and not GameState.progress.feature_unlocked("legendary_walks"): continue
			total += 1
			count += 1 if earned else 0
			var tile := UiKit.grid_tile(UiKit.ui_icon(data.icon), str(data.name) if earned else "?", func() -> void:
				if not earned:
					Events.sheet_requested.emit(str(data.name), _clothing_source(id))
					return
				var wearing := str(GameState.progress.equipped.get(str(data.slot), "")) == id
				var error := GameState.unequip(str(data.slot)) if wearing else GameState.equip(id)
				if error != "": Events.toast_requested.emit(error), 100, 64)
			tile.custom_minimum_size.y = 120
			tile.name = "Equip_" + id
			var wearing := str(GameState.progress.equipped.get(str(data.slot), "")) == id
			var mark := UiKit.icon(UiKit.ctl_icon("check" if wearing else "lock"), 24)
			mark.name = "EquippedCheck" if wearing else "ClothingLock"
			mark.visible = wearing or not earned
			tile.add_child(mark)
			if not earned:
				_silhouette(tile.get_node("Visual/Picture"))
				tile.modulate.a = 0.55
				if str(data.get("source", "")).begins_with("walk:") or str(data.get("source", "")).begins_with("legendary:"):
					mark.name = "RareHint_" + id
					mark.tooltip_text = "Raro de passeio"
			grid.add_child(tile)
		box.add_child(UiKit.collection_progress(count, total))
		box.add_child(grid)
	)


## Origem fica no detalhe para manter os quadrados compactos.
static func _clothing_source(id: String) -> Control:
	var box := UiKit.vbox(8)
	var data: Dictionary = Database.collections[id]
	box.add_child(UiKit.icon(UiKit.ui_icon(data.icon), 64))
	box.add_child(UiKit.lock_hint("Você ainda não tem"))
	var source := str(data.get("source", ""))
	if source.begins_with("walk:") or source.begins_with("legendary:"):
		box.add_child(UiKit.label("Lendário de passeio" if source.begins_with("legendary:") else "Raro de passeio: " + str(GameState.walk_def(source.trim_prefix("walk:")).get("name", "")), &"SmallLabel"))
		box.add_child(UiKit.secondary("Ir", Places.go.bind({"world": "park", "place": "walk"}), null, true))
	elif source.begins_with("friend:"):
		var friend_id := source.trim_prefix("friend:")
		box.add_child(UiKit.label(str(GameState.friend_def(friend_id).name) + " ♥3", &"SmallLabel"))
		box.add_child(UiKit.secondary("Ir", Places.go.bind({"world": "park", "place": "friend:" + friend_id}), null, true))
	elif data.has("recipe"):
		box.add_child(UiKit.secondary("Costura", Places.go.bind({"world": "park", "place": "sewing"}), null, true))
	elif data.get("shop", "") == "petshop":
		box.add_child(UiKit.secondary("Pet shop", Places.go.bind({"world": "park", "place": "petshop"}), null, true))
	return box


# --- Peças ------------------------------------------------------------------------------

static func rewards_text(rewards: Dictionary) -> String:
	var parts: PackedStringArray = []
	if int(rewards.get("coins", 0)) > 0:
		parts.append("%d moedas" % int(rewards.coins))
	if not rewards.get("items", {}).is_empty():
		parts.append(Database.describe_amounts(rewards["items"]))
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
## `primary` = botão principal do painel; em listas de cartões repetidos use `false` (secundário pequeno).
static func _action(box: VBoxContainer, text: String, action: Callable, reason: String = "", done: String = "", help: Callable = Callable(), primary: bool = true) -> void:
	var on_press := func() -> void:
		var error: String = action.call()
		if error != "" or done != "":
			Events.toast_requested.emit(error if error != "" else done)
	var button := UiKit.primary(text, on_press) if primary else UiKit.secondary(text, on_press, null, true)
	button.disabled = reason != ""
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := UiKit.hbox(8)
	row.add_child(button)
	if reason != "" and help.is_valid():
		row.add_child(UiKit.icon_button(UiKit.ctl_icon("help"), help, 44))
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
static func quest_action(box: VBoxContainer, id: String, primary: bool = true) -> void:
	var ready := GameState.quest_error(id) == ""
	var shortage := GameState.quest_reward_shortage(id)
	if not shortage.is_empty():
		box.add_child(UiKit.label("Missão cumprida! Libere %d vaga(s) em %s para receber o prêmio." % [int(shortage.missing), GameState.storage_name(str(shortage.depot))], &"SmallLabel"))
	var row := UiKit.hbox(8)
	var main := UiKit.button("Liberar espaço" if not shortage.is_empty() else ("Pegar prêmio" if ready else "Ir"), func() -> void:
		if not shortage.is_empty():
			Places.go({"storage": str(shortage.depot)})
		elif ready:
			var error := GameState.claim_quest(id)
			if error != "":
				Events.toast_requested.emit(error)
		else:
			Places.go(quest_go_target(id)), &"PrimaryButton" if primary else &"SecondaryButton")
	if ready and primary: Motion.pulse.call_deferred(main)
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(main)
	if not ready:
		row.add_child(UiKit.icon_button(UiKit.ctl_icon("help"), TaskHelp.open.bind("quest", id)))
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


## Rotina compacta: anel, nome/instrução, prêmio e ação. O dono da tela decide o principal.
static func routine_card(box: VBoxContainer, kind: String, id: String, primary: bool = false) -> void:
	if GameState.routine_claimed(kind, id): return
	var data := GameState.routine_data(kind, id)
	var goal: Dictionary = data.goal
	var target := GameState.routine_target(kind, id)
	var value := mini(GameState.routine_value(kind, id), target)
	var ready := GameState.routine_error(kind, id) == ""
	var action := func() -> void:
		if ready: claim_routine_rows(box, [{"kind": kind, "id": id}])
		else: Places.go(Places.goal_target({"type": "stat", "key": goal.key}))
	var button := UiKit.primary("Pegar", action) if ready and primary else UiKit.secondary("Pegar" if ready else "Ir", action, null, true)
	button.custom_minimum_size = Vector2(60, 44)
	button.add_theme_font_size_override("font_size", 18)
	var action_column := UiKit.vbox(0)
	action_column.add_child(button)
	var panel := UiKit.list_row(null, "", [], action_column)
	panel.name = "Routine_" + kind + "_" + id
	var row := panel.get_child(0).get_child(0) as HBoxContainer
	row.add_theme_constant_override("separation", 6)
	row.get_child(0).free()
	row.get_child(0).free()
	var progress := UiKit.vbox(0)
	var ring := RingProgress.new()
	ring.custom_minimum_size = Vector2(52, 52)
	ring.texture = stat_icon(str(goal.key))
	ring.progress = float(value) / maxi(1, target)
	progress.add_child(ring)
	var number := UiKit.short_label("%d/%d" % [value, target], &"SmallLabel")
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_child(number)
	row.add_child(progress)
	row.move_child(progress, 0)
	var info := UiKit.vbox(0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := UiKit.hbox(2)
	if ready:
		var badge := UiKit.alert_badge()
		badge.name = "ReadyDot"
		title.add_child(badge)
	var name_label := UiKit.fill_label(str(data.name), &"StrongLabel")
	title.add_child(name_label)
	info.add_child(title)
	info.add_child(UiKit.label(str(data.get("description", data.name)), &"SmallLabel"))
	var prize := UiKit.hbox(2)
	prize.add_child(UiKit.icon(UiKit.ui_icon("coin"), 16))
	prize.add_child(UiKit.short_label("+%d" % int(data.get("rewards", {}).get("coins", 0)), &"SmallLabel", Palette.GOOD))
	action_column.add_child(prize)
	row.add_child(info)
	row.move_child(info, 1)
	if ready:
		panel.ready.connect(func() -> void:
			var style := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			style.border_color = Palette.PRIMARY
			panel.add_theme_stylebox_override("panel", style))
	box.add_child(panel)


## Recebe somente as elegíveis; anima antes do LiveBox reconstruir e não repete prêmios.
static func claim_routine_rows(host: Control, entries: Array[Dictionary]) -> void:
	var live: Node = host
	while live and not live is SheetBuilder.LiveBox: live = live.get_parent()
	if live and bool(live.get_meta("ui_animating", false)): return
	if live: live.set_meta("ui_animating", true)
	for entry: Dictionary in entries:
		if GameState.routine_error(entry.kind, entry.id) != "": continue
		var row := host.find_child("Routine_" + str(entry.kind) + "_" + str(entry.id), true, false) as Control
		var origin := row.get_global_rect().get_center() if row else host.get_global_rect().get_center()
		var rewards: Dictionary = GameState.routine_data(entry.kind, entry.id).get("rewards", {})
		var error := GameState.claim_routine(entry.kind, entry.id)
		if error != "":
			Events.toast_requested.emit(error)
			continue
		Events.items_gained.emit(rewards.get("items", {}), int(rewards.get("coins", 0)), origin)
		if row: Motion.pop_out(row, false)
	if not is_instance_valid(host): return
	await host.get_tree().create_timer(0.0 if Motion.reduced else Motion.POP_OUT).timeout
	if is_instance_valid(live):
		live.set_meta("ui_animating", false)
		(live as SheetBuilder.LiveBox).refresh()


## História completa: capítulos passados (✓), o atual com os passos e os próximos apagados.
static func story_panel() -> Control:
	return SheetBuilder.tall(SheetBuilder.LiveBox.new(func(box: VBoxContainer) -> void:
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
	))


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
		"project":
			return UiKit.ui_icon(str(Database.project(key).get("icon", "tab_map")))
		"growth":
			return UiKit.ui_icon("tab_pet")
	return stat_icon(key)


## Ícone de um contador ("harvest", "produce:plank", "activity:lane"...).
static func stat_icon(key: String) -> Texture2D:
	if key == "open:album": return UiKit.ui_icon("album_story")
	var prefix := key.get_slice(":", 0)
	var arg := key.get_slice(":", 1) if ":" in key else ""
	if prefix in ["trick", "trick_learned"]:
		return UiKit.ui_icon("trick_" + (arg if arg != "" else "paw"))
	if prefix in ["friend_gift", "friend_level"]:
		return UiKit.ui_icon(str(GameState.friend_def(arg if arg != "" else "pipoca").get("icon", "heart")))
	if arg != "" and prefix in ["harvest", "produce"]:
		return Database.item_icon(arg)
	if prefix == "activity":
		return UiKit.ui_icon(Database.progression.activities.get(arg, {}).get("icon", "action_play"))
	if prefix == "talk":
		return npc_portrait(arg)
	if prefix == "open":
		return UiKit.ui_icon(Database.worlds[arg].get("icon", "tab_map") if Database.worlds.has(arg) else "tab_" + arg)
	var icons := {"feed": "need_hunger", "bathe": "action_bathe", "play": "action_play", "pet": "action_pet", "care_useful": "action_pet", "production_jobs": "item_carrot_snack", "wish": "tab_wishes", "harvest": "tab_farm", "water": "action_water", "produce": "item_carrot_snack", "trade": "coin", "sold": "coin", "orders": "item_treat_box", "order": "item_treat_box", "explore": "tab_map", "quests": "tab_tasks", "build": "item_plank"}
	return UiKit.ui_icon(icons.get(prefix, "xp"))


## Linha de objetivo: ícone + instrução breve + barra e "3/6".
static func goal_row(goal: Dictionary, value: int, px: int = 32) -> HBoxContainer:
	var target := int(goal.get("target", 1))
	var row := UiKit.hbox(8)
	row.add_child(_growth_silhouette(goal, value, px) if str(goal.get("type", "")) == "growth" else UiKit.icon(goal_icon(goal), px))
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


## Objetivo de crescimento: a silhueta da fase que vem (vira o retrato quando ele já cresceu).
static func _growth_silhouette(goal: Dictionary, value: int, px: int) -> Control:
	var index: int = GameState.growth.phase_index(str(goal.key))
	if index < 0:
		return UiKit.icon(goal_icon(goal), px)
	var info := GameState.growth_info()
	var phase: Dictionary = info.phases[index]
	if value >= int(goal.get("target", 1)):
		var photo := UiKit.icon(load(str(phase.art.portrait)), px)
		photo.name = "GrowthGoalPhoto"
		photo.material = DogLook.material()
		(photo.material as ShaderMaterial).set_shader_parameter("coat", float(phase.coat))
		return photo
	var done: int = info.requirements.size() - GrowthUi.missing(info)
	var holder := GrowthUi.silhouette(phase, done, info.ready, "GrowthGoalSilhouette", px)
	holder.custom_minimum_size.y = px
	return holder


## Recompensas em chips: [moeda] +40  [cenoura] +2  [atributo] +20  [roupa] +1.
static func reward_chips(rewards: Dictionary) -> HFlowContainer:
	var row := UiKit.flow()
	if int(rewards.get("coins", 0)) > 0:
		row.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(rewards.coins)))
	for id: String in rewards.get("items", {}):
		var label := "+%d" % int(rewards.items[id])
		if Database.items.get(id, {}).get("category", "") == "keepsake":
			label += " " + Database.item_name(id)
		row.add_child(UiKit.chip(Database.item_icon(id), label))
	for id: String in rewards.get("collections", []):
		if not GameState.progress.collection.has(id):
			row.add_child(UiKit.chip(UiKit.ui_icon("item_accessory_set"), "+1"))
	return row


## Ingrediente: ícone + tem/precisa (verde/vermelho); tocar mostra de onde vem.
static func item_chip(id: String, need: int) -> Button:
	var have := GameState.inventory.count(id)
	return UiKit.tap_chip(Database.item_icon(id), "%d/%d" % [have, need], TaskHelp.open.bind("item", id, need), UiKit.GOOD if have >= need else UiKit.BAD)
