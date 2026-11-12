class_name CodexSections
extends RefCounted
## Conteúdo de cada seção do Caderninho (`CodexUi`): filtros do topo + blocos de quadradinhos. Só lê o estado; toda ação
## passa pelo `GameState`. `view(...)` devolve `{filters: [{id, text, icon, alert}], filter, blocks: [{title, count, tiles,
## ratio, lines, action}], foot, empty, name}`; a UI monta e dimensiona os quadradinhos. Detalhes enxutos (estação, planta,
## rota, pilar) abrem numa folha de madeira com ícones e o botão Ir.

const CAPTION_RATIO := 1.4   # quadradinho com legenda: mais alto que largo (ícone 2x + duas linhas)


static func view(section: String, filter: String, model: Dictionary) -> Dictionary:
	match section:
		"stations": return _stations(filter)
		"growth": return _growth(filter)
		"album": return _album(filter, model)
		"collection": return _collection(filter)
		"tricks": return _tricks()
		_: return _resources(filter)


## Escolhe o filtro válido (o pedido, senão o primeiro).
static func _pick(options: Array[Dictionary], wanted: String) -> String:
	for entry: Dictionary in options:
		if str(entry.id) == wanted:
			return wanted
	return str(options[0].id) if not options.is_empty() else ""


static func _icon(file: String) -> Texture2D:
	return UiKit.ui_icon(file)


# --- Recursos ------------------------------------------------------------------------------

static func item_icon(id: String) -> Texture2D:
	var food := StationWood.food_texture(id)
	return food if food != null else Database.item_icon(id)


static func open_item(id: String) -> void:
	if Database.collections.has(id):
		Events.sheet_requested.emit("Coleção", ProgressionUi.collection_panel())
		return
	Events.sheet_requested.emit(Database.item_name(id), SheetBuilder.item_detail(id))


static func _resources(wanted: String) -> Dictionary:
	var groups := {}
	for id: String in Database.items:
		var category := str(Database.items[id].get("category", "product"))
		if not groups.has(category):
			groups[category] = []
		groups[category].append(id)
	var options: Array[Dictionary] = []
	for category: String in SheetBuilder.CATEGORIES:
		if groups.has(category):
			var art := BagUi.icon(category)
			options.append({"id": category, "text": SheetBuilder.CATEGORIES[category], "icon": art if art != null else _icon("tab_pet")})
	var filter := _pick(options, wanted)
	var tiles: Array[Dictionary] = []
	for id: String in groups.get(filter, []):
		var have := GameState.inventory.count(id)
		tiles.append({
			"name": "Resource_" + id, "icon": item_icon(id), "caption": Database.item_name(id), "dim": have <= 0,
			"tooltip": Database.item_name(id), "on_tap": open_item.bind(id)})
	return {"filters": options, "filter": filter, "name": "ManualPanel", "blocks": [{"tiles": tiles, "ratio": 1.0}]}


# --- Estações ------------------------------------------------------------------------------

static func _stations(wanted: String) -> Dictionary:
	var options: Array[Dictionary] = [
		{"id": "machines", "text": "Estações", "icon": _icon("station_stove")},
		{"id": "crops", "text": "Plantas", "icon": Database.item_icon("carrot")},
		{"id": "nature", "text": "Natureza", "icon": _icon("item_wood")},
	]
	var filter := _pick(options, wanted)
	var tiles: Array[Dictionary] = []
	match filter:
		"crops":
			for id: String in Database.crops:
				var crop: Dictionary = Database.crops[id]
				var out := _first_key(crop.get("yield", {}))
				tiles.append({"name": "Crop_" + id, "icon": item_icon(out), "caption": Database.item_name(out),
					"dim": GameState.requirement_error(crop.get("requirements", {})) != "", "on_tap": _open_crop.bind(id)})
		"nature":
			for id: String in Database.progression.activities:
				var route: Dictionary = Database.progression.activities[id]
				tiles.append({"name": "Route_" + id, "icon": _icon(str(route.get("icon", ""))), "caption": str(route.name),
					"dim": GameState.requirement_error(route.get("requirements", {})) != "", "on_tap": _open_route.bind(id)})
		_:
			for id: String in Database.stations:
				tiles.append({"name": "Station_" + id, "icon": _station_icon(id), "caption": str(Database.stations[id].name),
					"dim": not _station_owned(id), "on_tap": _open_station.bind(id)})
	return {"filters": options, "filter": filter, "name": "ManualPanel", "blocks": [{"tiles": tiles, "ratio": CAPTION_RATIO}]}


static func _first_key(amounts: Dictionary) -> String:
	for id: String in amounts:
		return id
	return ""


static func _station_owned(id: String) -> bool:
	var upgrade := Database.station_upgrade(id)
	var needs_buy: bool = upgrade != "" and Database.progression.upgrades.has(upgrade) and not GameState.has_upgrade(upgrade)
	return not needs_buy and GameState.requirement_error(Database.stations[id].get("requirements", {})) == ""


static func _open_station(id: String) -> void:
	Events.sheet_requested.emit(str(Database.stations[id].name), station_detail(id))


static func _open_crop(id: String) -> void:
	Events.sheet_requested.emit(Database.item_name(_first_key(Database.crops[id].get("yield", {}))), crop_detail(id))


static func _open_route(id: String) -> void:
	Events.sheet_requested.emit(str(Database.progression.activities[id].name), route_detail(id))


## Folha de madeira: cabeça (ícone + nome + uma linha), o que sai/ganha em ícones tocáveis, o tempo e o Ir.
static func _detail(icon: Texture2D, title: String, line: String = "") -> Dictionary:
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	var inner := ProgressionUi._wood_hero(content, icon, title, line)
	for spare_name: String in ["UpgradeName", "UpgradeText"]:  # o nome já está na placa
		var spare := inner.find_child(spare_name, true, false)
		if spare != null and (spare_name == "UpgradeName" or line == ""):
			inner.remove_child(spare)
			spare.queue_free()
	# Mesma folha nua das outras telas: moldura `item_frame`, placa com o nome e X de madeira.
	var width := ItemUi.panel_width()
	var frame := PanelContainer.new()
	frame.name = "CodexDetail"
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	frame.custom_minimum_size.x = width
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var art := SellUi.nine("frame", ItemUi.FRAME_MARGINS, "Art", null, "item_")
	frame.add_child(art)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_theme_constant_override("margin_left", int(ItemUi.IN_L))
	margin.add_theme_constant_override("margin_right", int(ItemUi.IN_R))
	margin.add_theme_constant_override("margin_top", int(ItemUi.TOP))
	margin.add_theme_constant_override("margin_bottom", int(ItemUi.BOTTOM))
	margin.add_child(content)
	frame.add_child(margin)
	frame.add_child(ItemUi._overlay(width, title))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(frame)
	var tail := Control.new()
	tail.custom_minimum_size.y = ItemUi.TAIL
	box.add_child(tail)
	box.set_meta("sheet_bare", true)
	box.set_meta("sheet_fit_content", true)
	return {"box": box, "inner": inner}


static func _chips(inner: VBoxContainer, chips: Array[Control], node_name: String) -> void:
	if chips.is_empty():
		return
	var flow := HFlowContainer.new()
	flow.name = node_name
	flow.alignment = FlowContainer.ALIGNMENT_CENTER
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	for chip in chips:
		flow.add_child(chip)
	inner.add_child(flow)


static func _item_chips(amounts: Dictionary) -> Array[Control]:
	var result: Array[Control] = []
	for id: String in amounts:
		var qty := int(amounts[id])
		result.append(StepCardUi.wood_chip(Database.item_icon(id), ("%d× " % qty if qty > 1 else "") + Database.item_name(id), "", open_item.bind(id)))
	return result


static func _time_chip(seconds: int) -> Control:
	return StepCardUi.wood_chip(UiKit.ctl_icon("clock"), TimeText.short(seconds))


## Destino + bloqueio: Ir (verde) ou o botão de madeira bloqueado com o motivo.
static func _go(inner: VBoxContainer, target: Dictionary, station_id: String = "") -> void:
	if target.is_empty():
		return
	var upgrade := Database.station_upgrade(station_id)
	var world: Dictionary = Database.worlds[target.world]
	var place: Dictionary = world.places[target.get("spot", target.place)]
	var error := Places.world_error(str(target.world))
	if error == "":
		error = Places.place_error(place)
	var needs_buy: bool = upgrade != "" and Database.progression.upgrades.has(upgrade) and not GameState.has_upgrade(upgrade)
	var destination := Places.goal_target({"type": "owned", "key": upgrade}) if needs_buy else target
	if error != "":
		var note := StepCardUi.lock_note(error)
		note.name = "Locked_ManualGo_%s_%s" % [target.world, target.get("spot", target.place)]
		note.set_meta("reason", error)
		inner.add_child(note)
		return
	var row := UiKit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UiKit.icon(UiKit.ui_icon(str(world.get("icon", ""))), 24))
	row.add_child(StepCardUi.wood("%s › %s" % [world.name, place.name], 14))
	inner.add_child(row)
	if needs_buy:
		inner.add_child(StepCardUi.wood_chip(UiKit.ui_icon("coin"), "Compre: " + str(Database.stations[station_id].name)))
	var button := StepCardUi.go_button("Ir", Places.go.bind(destination))
	button.name = "ManualGo_%s_%s" % [target.world, target.get("spot", target.place)]
	inner.add_child(button)


static func station_detail(id: String) -> Control:
	var data: Dictionary = Database.stations[id]
	var made := _detail(_station_icon(id), str(data.name), "")
	var inner: VBoxContainer = made.inner
	var outputs := {}
	for recipe_id: String in Database.recipes_for(id):
		outputs[Database.recipe_output(Database.recipes[recipe_id])] = 1
	var tiles := HFlowContainer.new()
	tiles.name = "StationProducts"
	tiles.alignment = FlowContainer.ALIGNMENT_CENTER
	tiles.add_theme_constant_override("h_separation", 4)
	tiles.add_theme_constant_override("v_separation", 4)
	for item_id: String in outputs:
		var small := CodexUi.tile({"name": "Made_" + item_id, "icon": item_icon(item_id), "tooltip": Database.item_name(item_id), "on_tap": open_item.bind(item_id)}, 46.0, 46.0)
		tiles.add_child(small)
	inner.add_child(tiles)
	_go(inner, GameManual.focused("station:" + id), id)
	return made.box


static func crop_detail(id: String) -> Control:
	var crop: Dictionary = Database.crops[id]
	var out := _first_key(crop.get("yield", {}))
	var made := _detail(item_icon(out), Database.item_name(out), "")
	var inner: VBoxContainer = made.inner
	var chips: Array[Control] = [_time_chip(int(crop.seconds))]
	chips.append_array(_item_chips(crop.get("yield", {})))
	_chips(inner, chips, "CropChips")
	var error := GameState.requirement_error(crop.get("requirements", {}))
	if error != "":
		inner.add_child(StepCardUi.lock_note(error))
	_go(inner, GameManual.focused("farm", "crop:" + id))
	return made.box


static func route_detail(id: String) -> Control:
	var route: Dictionary = Database.progression.activities[id]
	var made := _detail(_icon(str(route.get("icon", ""))), str(route.name), "")
	var inner: VBoxContainer = made.inner
	var chips: Array[Control] = [_time_chip(int(route.seconds))]
	chips.append_array(_item_chips(route.rewards.get("items", {})))
	_chips(inner, chips, "RouteChips")
	var error := GameState.requirement_error(route.get("requirements", {}))
	if error != "":
		inner.add_child(StepCardUi.lock_note(error))
	_go(inner, GameManual.focused("routes:" + str(route.place), "route:" + id))
	return made.box


# --- Crescer -------------------------------------------------------------------------------

static func _growth(wanted: String) -> Dictionary:
	var options: Array[Dictionary] = [
		{"id": "pillars", "text": "Pilares", "icon": _icon("item_growth_kibble")},
		{"id": "tastes", "text": "Paladar", "icon": _icon("heart")},
		{"id": "diary", "text": "Diário", "icon": _icon("album_story")},
	]
	var filter := _pick(options, wanted)
	var foot := StepCardUi.go_button("Ver crescimento", GrowthUi.open)
	foot.name = "GrowthGo"
	var blocks: Array[Dictionary] = []
	match filter:
		"tastes":
			var foods: Array[String] = []
			for id: String in Database.items:
				if Database.items[id].has("feed"):
					foods.append(id)
			var found := 0
			var tiles: Array[Dictionary] = []
			for id: String in foods:
				var tried := GameState.growth.tastes.has(id)
				found += 1 if tried else 0
				var reaction := str(GameState.growth.tastes.get(id, ""))
				var loved := tried and (reaction == "loved" or (GameState.favorite_found() and id == GameState.favorite_food()))
				tiles.append({"name": "Taste_" + id, "icon": item_icon(id), "caption": Database.item_name(id) if tried else "?", "dim": not tried, "mark": "heart" if loved else ("face_" + reaction if tried else ""),
					"tooltip": Database.item_name(id) if tried else "?", "on_tap": open_item.bind(id)})
			blocks.append({"title": "Sabores", "count": "%d/%d" % [found, foods.size()], "tiles": tiles, "ratio": 1.0, "name": "TasteGuide"})
		"diary":
			var lines: Array = []
			var entries := GameState.growth.diary.duplicate()
			entries.reverse()
			entries = entries.slice(0, 10)  # só as lembranças mais recentes
			for entry: Dictionary in entries:
				lines.append(str(entry.day) + " · " + str(entry.text))
			var title := PersonalityRules.title(GameState.growth)
			blocks.append({"title": title if title != "" else "Hoje o Tiro...", "lines": lines, "name": "GrowthDiary"})
			if lines.is_empty():
				blocks[0]["lines"] = ["As lembranças dele vão aparecer aqui."]
		_:
			var tiles: Array[Dictionary] = []
			for id: String in Database.growth.pillars:
				var have := int(GameState.growth.phase_moments.get(id, 0))
				var need := GameState.growth.phase_need(id)
				if id == "body":
					for row: Dictionary in GameState.growth_info().requirements:
						if row.type == "feed":
							have = int(row.have)
							need = int(row.need)
				var done := need > 0 and have >= need
				tiles.append({"name": "Pillar_" + id, "icon": _icon(str(Database.growth.pillars[id].icon)), "caption": str(Database.growth.pillars[id].name),
					"dots_need": mini(need, 8), "dots_have": mini(have, need), "count": "×%d" % int(GameState.growth.moments.get(id, 0)) if need <= 0 else "", "mark": "check" if done else "", "on_tap": _open_pillar.bind(id)})
			var phase: Dictionary = Database.growth.phases[GameState.growth.phase_index()]
			blocks.append({"title": str(phase.name), "count": str(phase.age), "tiles": tiles, "ratio": 1.55, "name": "PillarPanel"})
	return {"filters": options, "filter": filter, "blocks": blocks, "foot": foot}


static func _open_pillar(id: String) -> void:
	if id == "body":
		GrowthUi.open()
		return
	Events.sheet_requested.emit(str(Database.growth.pillars[id].name), pillar_detail(id))


## Momentos do pilar em bolinhas e de onde eles vêm (cada fonte com lugar leva até lá).
static func pillar_detail(id: String) -> Control:
	var made := _detail(_icon(str(Database.growth.pillars[id].icon)), str(Database.growth.pillars[id].name), "")
	var inner: VBoxContainer = made.inner
	var have := int(GameState.growth.phase_moments.get(id, 0))
	var need := GameState.growth.phase_need(id)
	if need > 0:
		var dots := PillarUi.dots(have, need)
		dots.name = "PillarDots_" + id
		dots.alignment = BoxContainer.ALIGNMENT_CENTER
		inner.add_child(dots)
	var chips: Array[Control] = []
	for source: String in Database.growth.moments.sources:
		var rule: Dictionary = Database.growth.moments.sources[source]
		if str(rule.pillar) != id or not rule.has("label"):
			continue
		var go := Callable()
		if rule.has("go"):
			go = Places.go.bind(WishUi.go_target({"go": rule.go}))
		chips.append(StepCardUi.wood_chip(_icon(str(Database.growth.pillars[id].icon)), str(rule.label), "", go, "Origin_" + source))
	_chips(inner, chips, "MomentOrigins")
	return made.box


# --- Álbum ---------------------------------------------------------------------------------

static func _album(wanted: String, model: Dictionary) -> Dictionary:
	var sections := Database.album_sections()
	if sections.is_empty():
		return {"filters": [], "filter": "", "blocks": [], "empty": "Ainda não há fotos."}
	var unseen_sections: Array = GameState.photos_unseen().map(func(id: String) -> String: return str(Database.photo(id).section))
	# "Todas" primeiro (padrão): todas as fotos que o jogador tem. Depois as seções ativas, com progresso e ✓.
	var options: Array[Dictionary] = []
	var all_taken := 0
	var all_total := 0
	var all_complete := true
	for entry: Dictionary in sections:
		var counts := AlbumView.section_counts(str(entry.id))
		all_taken += counts.x
		all_total += counts.y
		var complete: bool = bool(GameState.album_milestones(str(entry.id)).section.get("complete", false))
		all_complete = all_complete and complete
		options.append({"id": str(entry.id), "text": str(entry.name), "icon": _icon(str(entry.icon)), "alert": str(entry.id) in unseen_sections,
			"have": counts.x, "total": counts.y, "complete": complete})
	if sections.size() > 1:
		options.push_front({"id": "all", "text": "Todas", "icon": CodexUi.tex("icon_album"), "alert": not unseen_sections.is_empty(),
		"have": all_taken, "total": all_total, "complete": all_complete})
	var filter := wanted
	if filter == "":
		filter = AlbumView.last_section
	filter = _pick(options, filter)
	AlbumView.last_section = filter
	if str(model.get("noted", "")) != filter:
		model["noted"] = filter
		GameState.note_album_section(filter)
	AlbumTutorial.maybe_start.call_deferred()
	return {"filters": options, "filter": filter, "name": "AlbumView", "cols": 3, "wide": true,
		"album_section": filter, "blocks": []}



# --- Coleção -------------------------------------------------------------------------------

static func _collection(wanted: String) -> Dictionary:
	var options: Array[Dictionary] = [{"id": "clothes", "text": "Roupas", "icon": _icon("outfit_star_glasses")}]
	if GameState.progress.feature_unlocked("finds"):
		options.append({"id": "finds", "text": "Achados", "icon": CodexUi.tex("icon_lens")})
	if GameState.progress.feature_unlocked("friends"):
		options.append({"id": "friends", "text": "Amigos", "icon": _icon("tab_pet")})
	if GameState.progress.feature_unlocked("fish_book"):
		options.append({"id": "fish", "text": "Peixes", "icon": _icon("item_fish_tilapia")})
	var filter := _pick(options, wanted)
	match filter:
		"fish": return {"filters": options, "filter": filter, "blocks": _fish_blocks(), "name": "FishBook"}
		"finds": return {"filters": options, "filter": filter, "blocks": _finds_blocks()}
		"friends": return {"filters": options, "filter": filter, "blocks": _friend_blocks()}
	return {"filters": options, "filter": filter, "blocks": _clothes_blocks(), "name": "ClothesGrid"}


static func _clothes_blocks() -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []
	var count := 0
	var total := 0
	for id: String in Database.collections:
		var data: Dictionary = Database.collections[id]
		var earned := GameState.progress.collection.has(id)
		if not GameState.has_overlay(id):
			continue
		var source := str(data.get("source", ""))
		if source.begins_with("friend:") and not earned and not GameState.progress.feature_unlocked("friends"):
			continue
		if data.get("rarity", "") == "legendary" and not earned and not GameState.progress.feature_unlocked("legendary_walks"):
			continue
		total += 1
		count += 1 if earned else 0
		var wearing := earned and str(GameState.progress.equipped.get(str(data.slot), "")) == id
		tiles.append({
			"name": "Equip_" + id, "icon": _icon(str(data.icon)), "caption": str(data.name) if earned else "?", "dim": not earned,
			"mark": "check" if wearing else ("lock" if not earned else ""), "tooltip": "Raro de passeio" if source.begins_with("walk:") or source.begins_with("legendary:") else "",
			"on_tap": _tap_clothing.bind(id)})
	var note: Array = []
	if GameState.dog_look().body == "puppy":
		note = ["Vai aparecer quando ele crescer"]
	return [{"title": "Roupas", "count": "%d/%d" % [count, total], "tiles": tiles, "ratio": CAPTION_RATIO, "lines": note, "name": "ClothesGrid"}]


static func _tap_clothing(id: String) -> void:
	var data: Dictionary = Database.collections[id]
	if not GameState.progress.collection.has(id):
		Events.sheet_requested.emit(str(data.name), ProgressionUi._clothing_source(id))
		return
	var on_now := str(GameState.progress.equipped.get(str(data.slot), "")) == id
	var error := GameState.unequip(str(data.slot)) if on_now else GameState.equip(id)
	if error != "":
		Events.toast_requested.emit(error)


static func _finds_blocks() -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	var pieces: Array[Dictionary] = []
	var map_found := 0
	for n in range(1, 5):
		var earned := GameState.progress.stat("find_item:map_piece_%d" % n) > 0
		map_found += 1 if earned else 0
		pieces.append({"name": "MapPiece_%d" % n, "icon": _icon("item_map_piece"), "caption": "Pedaço %d" % n, "dim": not earned, "tooltip": "Mapa rasgado"})
	blocks.append({"title": "Mapa rasgado", "count": "%d/4" % map_found, "tiles": pieces, "ratio": 1.0})
	for world: String in Database.finds.album_groups:
		var items: Array = Database.finds.album_groups[world]
		var tiles: Array[Dictionary] = []
		for id: String in items:
			var earned := GameState.progress.stat("find_item:" + id) > 0
			tiles.append({"name": "Find_" + id, "icon": item_icon(id), "caption": Database.item_name(id) if earned else "?", "dim": not earned, "tooltip": Database.item_name(id) if earned else "?",
				"on_tap": open_item.bind(id)})
		var block := {"title": str(Database.finds.album_names[world]), "tiles": tiles, "ratio": 1.0}
		var set_id := world + "_set"
		if Database.finds.sets.has(set_id):
			block["count"] = "%d/4" % GameState.find_set_progress(set_id)
			if set_id in GameState.finds.claimed_sets:
				block["action"] = StepCardUi.done_medal(28.0, "FindSetDone_" + set_id)
			elif GameState.find_set_error(set_id) == "":
				var claim := StepCardUi.go_button("Pegar", func() -> void:
					var result := GameState.claim_find_set(set_id)
					if result != "":
						Events.toast_requested.emit(result))
				claim.name = "ClaimFind_" + set_id
				claim.custom_minimum_size = Vector2(84, 44)
				claim.size_flags_horizontal = Control.SIZE_SHRINK_END
				block["action"] = claim
		blocks.append(block)
	return blocks


## Vara que pega o peixe: a primeira (em ordem de tier) que aceita a isca dele.
static func fish_rod(fish_id: String) -> String:
	var bait := str(Database.fishing.fish[fish_id].bait)
	for rod: String in Database.fishing.rods:
		if bait in Database.fishing.rods[rod].get("baits", []):
			return rod
	return ""


static func fish_cm(value: float) -> String:
	return ("%.1f cm" % value).replace(".", ",")


static func _fish_blocks() -> Array[Dictionary]:
	var blocks: Array[Dictionary] = []
	for rod: String in Database.fishing.rods:
		var owned := GameState.fishing.has_rod(rod)
		var tiles: Array[Dictionary] = []
		var caught := 0
		for id: String in Database.fishing.fish:
			if fish_rod(id) != rod:
				continue
			var record: Dictionary = GameState.fishing.record(id)
			var got := not record.is_empty()
			caught += 1 if got else 0
			var tile := {"name": "Fish_" + id, "icon": item_icon(id), "caption": Database.item_name(id) if got else "?", "dim": not got,
				"on_tap": fish_open.bind(id)}
			if got:
				tile["caption"] = Database.item_name(id) + "
" + fish_cm(float(record.best_cm))
				tile["record"] = fish_cm(float(record.best_cm))
				if int(record.gigantes) > 0:
					tile["mark"] = "star"
			elif not owned:
				tile["mark"] = "lock"
			tiles.append(tile)
		var block := {"title": str(Database.fishing.rods[rod].name), "count": "%d/%d" % [caught, tiles.size()], "tiles": tiles, "ratio": CAPTION_RATIO,
			"name": "FishRod_" + rod}
		if not owned:
			block["lines"] = ["Ganhe a " + str(Database.fishing.rods[rod].name).to_lower()]
			block["dim"] = true
		blocks.append(block)
	return blocks


static func fish_open(id: String) -> void:
	var record: Dictionary = GameState.fishing.record(id)
	Events.sheet_requested.emit(Database.item_name(id) if not record.is_empty() else "Peixe da lagoa", fish_detail(id))


static func _fish_motion_line(motion: String) -> String:
	return {"floater": "Fica perto da superfície", "smooth": "Nada macio e devagar", "mixed": "Muda de ritmo toda hora",
		"sinker": "Nada para o fundo", "darter": "Dá arrancadas rápidas"}.get(motion, "")


## Régua de madeira com a faixa real (min–max cm) e a marca do recorde.
static func _fish_ruler(low: float, high: float, best: float) -> Control:
	var ruler := Control.new()
	ruler.name = "FishRuler"
	ruler.custom_minimum_size = Vector2(0, 46)
	ruler.draw.connect(func() -> void:
		var w := ruler.size.x
		var y := 24.0
		ruler.draw_rect(Rect2(8, y, w - 16, 10), Palette.WOOD_INSET, true)
		ruler.draw_rect(Rect2(8, y, w - 16, 10), Palette.WOOD_INK, false, 1.5)
		for i in 11:
			var x := 8.0 + (w - 16.0) * float(i) / 10.0
			ruler.draw_line(Vector2(x, y), Vector2(x, y + (10.0 if i % 5 == 0 else 5.0)), Palette.WOOD_INK, 1.0)
		var font := ThemeDB.fallback_font
		ruler.draw_string(font, Vector2(8, 16), fish_cm(low).replace(",0", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.WOOD_INK)
		ruler.draw_string(font, Vector2(0, 16), fish_cm(high).replace(",0", ""), HORIZONTAL_ALIGNMENT_RIGHT, w - 8.0, 13, Palette.WOOD_INK)
		if best > 0.0:
			var fraction := clampf((best - low) / maxf(0.1, high - low), 0.0, 1.0)
			var x := 8.0 + (w - 16.0) * fraction
			ruler.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, y + 22), Vector2(x + 6, y + 22), Vector2(x, y + 10)]), Palette.HONEY)
			ruler.draw_polyline(PackedVector2Array([Vector2(x - 6, y + 22), Vector2(x + 6, y + 22), Vector2(x, y + 10), Vector2(x - 6, y + 22)]), Palette.WOOD_INK, 1.5)
	)
	return ruler


static func fish_detail(id: String) -> Control:
	var def: Dictionary = Database.fishing.fish[id]
	var record: Dictionary = GameState.fishing.record(id)
	var got := not record.is_empty()
	var made := _detail(item_icon(id), Database.item_name(id) if got else "Peixe da lagoa", _fish_motion_line(str(def.motion)) if got else "")
	var inner: VBoxContainer = made.inner
	var low := float(def.cm[0])
	var high := float(def.cm[1])
	inner.add_child(_fish_ruler(low, high, float(record.get("best_cm", 0.0))))
	var chips: Array[Control] = []
	if got:
		chips.append(StepCardUi.wood_chip(UiKit.ui_icon("rare_star"), "Recorde " + fish_cm(float(record.best_cm)), "", Callable(), "FishRecord"))
		chips.append(StepCardUi.wood_chip(item_icon(id), "Pegou %d" % int(record.count), "", Callable(), "FishCount"))
		chips.append(StepCardUi.wood_chip(UiKit.ui_icon("rare_star"), "Gigantes %d" % int(record.gigantes), "", Callable(), "FishGiants"))
		chips.append(StepCardUi.wood_chip(UiKit.ui_icon("item_fish_tilapia"), "Perfeitas %d" % int(record.perfects), "", Callable(), "FishPerfects"))
	else:
		chips.append(StepCardUi.wood_chip(UiKit.ui_icon("clock"), "Ainda não pegou", "", Callable(), "FishNever"))
	_chips(inner, chips, "FishChips")
	var rod_id := fish_rod(id)
	var bait := str(def.bait)
	var needs: Array[Control] = [
		StepCardUi.wood_chip(Database.item_icon(bait), Database.item_name(bait), "", open_item.bind(bait), "FishBait"),
		StepCardUi.wood_chip(load(str(Database.fishing.rods[rod_id].icon)) as Texture2D, str(Database.fishing.rods[rod_id].name), "", Callable(), "FishRod")]
	_chips(inner, needs, "FishNeeds")
	var target := {"world": "farm", "place": "fishing"}
	var error := Places.world_error("farm")
	if error == "" and GameState.current_rod() == "":
		error = "Você ainda não tem uma vara"
	if error != "":
		var note := StepCardUi.lock_note(error)
		note.name = "Locked_FishGo"
		note.set_meta("reason", error)
		inner.add_child(note)
	else:
		var button := StepCardUi.go_button("Ir pescar", Places.go.bind(target))
		button.name = "FishGo"
		inner.add_child(button)
	return made.box


static func _friend_blocks() -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []
	var known_count := 0
	for id: String in Database.friends.friends:
		var def := GameState.friend_def(id)
		var known := int(GameState.friend_state.entry(id).gifts) > 0
		known_count += 1 if known else 0
		tiles.append({"name": "Friend_" + id, "icon": load(str(def.portrait)) as Texture2D, "caption": str(def.name) if known else "?", "dim": not known,
			"on_tap": func() -> void: Events.sheet_requested.emit(str(def.name) if known else "Amigo da vizinhança", FriendUi.panel(id))})
	return [{"title": "Amigos", "count": "%d/%d" % [known_count, Database.friends.friends.size()], "tiles": tiles, "ratio": CAPTION_RATIO}]


# --- Truques -------------------------------------------------------------------------------

static func _tricks() -> Dictionary:
	var tiles: Array[Dictionary] = []
	for id: String in Database.progression.tricks:
		if not bool(GameState.progress.tricks.get(id, false)):
			continue
		var def: Dictionary = Database.progression.tricks[id]
		var reason := GameState.perform_trick_error(id)
		tiles.append({"name": "Trick_" + id, "icon": _icon(str(def.icon)), "caption": str(def.name), "dim": reason != "",
			"tooltip": reason, "on_tap": _perform_trick.bind(id)})
	var foot := StepCardUi.go_button("Treinar com a Nina", Places.go.bind({"world": "park", "place": "training"}))
	foot.name = "TrainWithNina"
	return {"filters": [], "filter": "", "foot": foot, "empty": "Treine com a Nina para aprender truques",
		"blocks": [{"tiles": tiles, "ratio": CAPTION_RATIO}] if not tiles.is_empty() else []}


static func _perform_trick(id: String) -> void:
	var error := GameState.perform_trick(id)
	if error != "":
		Events.toast_requested.emit(error)
	else:
		Events.sheet_close_requested.emit()
		Events.screen_requested.emit(&"pet")


## Ícone da estação: o da compra no mapa; sem ele, o `station_<id>` de ícones.
static func _station_icon(id: String) -> Texture2D:
	var icon := StationTray.station_icon(id)
	return icon if icon != null else _icon("station_" + id)
