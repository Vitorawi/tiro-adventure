class_name SheetBuilder
extends RefCounted
## Monta o conteúdo dos painéis inferiores (sheets) usados por várias telas.
## Uso: Events.sheet_requested.emit("Título", SheetBuilder.food_picker())
## Peças visuais vêm do UiKit; ícones de itens/necessidades vêm do Database.
## Regra: ícone + número em vez de frase; no máximo uma linha curta de texto.


## Caminho único da comida desejada (o cumprimento já alimenta exatamente uma vez).
static func give_food(id: String) -> String:
	if GameState.walking(): return GameState.away_text()
	if GameState.dog.sleeping: return "Shh... ele está dormindo."
	if GameState.wish_wants_item(id): return GameState.fulfill_wish()
	return "" if GameState.feed(id) else "Você não tem essa comida."


## Comidas do inventário em madeira ilustrada: cartão de papel por comida (prato com o ícone, nome ×N, efeitos) e "Dar".
## Só a comida que o Tiro pede ("Ele quer!") leva o botão verde; as outras, o amarelo calmo.
static func food_picker() -> Control:
	var view := LiveBox.new(func(box: VBoxContainer) -> void:
		var any := false
		var primary_used := false
		# A comida que o Tiro está pedindo (balão do desejo) vem primeiro, com um coração.
		var foods: Array[String] = []
		for id: String in Database.items:
			if Database.items[id].has("feed") and GameState.inventory.count(id) > 0:
				foods.append(id)
		foods.sort_custom(func(a: String, b: String) -> bool:
			return GameState.wish_wants_item(a) and not GameState.wish_wants_item(b))
		for id: String in foods:
			any = true
			var wished := GameState.wish_wants_item(id)
			var chips: Array[Control] = []
			if wished:
				chips.append(StepCardUi.wood_chip(UiKit.ui_icon("heart"), "Ele quer!", "have"))
			chips.append_array(_effect_chips(Database.items[id]["feed"]))
			var on_give := func() -> void:
				var error := give_food(id)
				var message := error if error != "" else ("Era isso que ele queria!" if wished else "")
				if message != "":
					Events.toast_requested.emit(message)
				if error == "":
					Events.sheet_close_requested.emit()
			var wanted := wished and not primary_used
			primary_used = primary_used or wanted
			var give: Button
			if wanted:
				give = StepCardUi.go_button("Dar", on_give)
				give.size_flags_horizontal = Control.SIZE_SHRINK_END
				give.custom_minimum_size.x = 84.0
			else:
				give = WelcomeSheet._button("Dar", false, 84.0, "Give_" + id, on_give)
			give.name = "Give_" + id
			_wood_row(box, "Food_" + id, _plate(id, Database.item_icon(id)), "%s ×%d" % [Database.item_name(id), GameState.inventory.count(id)], chips, give)
		if not any:
			_empty_message(box, "Acabou a comida!", "")
		box.add_child(food_help(not any))
	)
	return _wood_sheet(view)


## Ajuda na Tigela e na guia vazia só depois de conhecer a vovó, com a mesma recarga salva.
static func food_help(primary: bool = true) -> Control:
	var help := LiveBox.new(func(box: VBoxContainer) -> void:
		box.visible = GameState.progress.seen.has("npc_intro:bloblo") or GameState.progress.claimed_quests.has("bloblo_meet")
		if not box.visible:
			return
		var wait := GameState.progress.cooldown_left("emergency_food", GameState.now())
		var on_ask := func() -> void:
			var error := GameState.emergency_food()
			Events.toast_requested.emit(error if error != "" else "A vovó trouxe %d rações!" % int(Database.progression.settings.emergency_food_amount))
		var button: Button
		if primary:
			button = StepCardUi.go_button("Pedir à vovó", on_ask)
		else:
			button = WelcomeSheet._button("Pedir à vovó", false, 200.0, "FoodHelpButton", on_ask)
		button.name = "FoodHelpButton"
		if wait <= 0:
			box.add_child(button)
		else:
			button.free()  # FoodHelpTimer já explica a espera.
		var caption := StationWood.text("Pedir de novo em " + TimeText.short(ceilf(wait)) if wait > 0 else "%d rações grátis" % int(Database.progression.settings.emergency_food_amount), 14)
		caption.name = "FoodHelpTimer"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(caption)
	)
	help.name = "FoodHelp"
	return help


# --- Madeira ilustrada: peças das folhas de produção, sementes e canteiros ----------------------------------------

## Marca a folha como "madeira ilustrada" (a `Sheet` desenha moldura, papel, título marrom e X).
static func _wood_sheet(content: Control) -> Control:
	content.set_meta("sheet_wood", true)
	content.set_meta("sheet_fit_content", true)
	return content


## Prato bege com o produto (comida ilustrada ou ícone pixel em escala inteira).
static func _plate(item: String, icon: Texture2D, size: float = 52.0) -> Control:
	var plate := Control.new()
	plate.name = "Plate"
	plate.custom_minimum_size = Vector2(size, size)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := StationWood.pic("slot", Vector2(size, size), "Art", true)
	plate.add_child(art)
	StepCardUi.stretch(art)
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(center)
	StepCardUi.stretch(center)
	var picture := StationWood.item_pic(item, icon, size - 16.0, "Picture")
	if icon != null and icon.get_width() > 48:
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS  # ilustração (cenoura nova): suave
	center.add_child(picture)
	return plate


## Chips de madeira dos efeitos de uma comida (ícone da necessidade + "+N").
static func _effect_chips(effects: Dictionary) -> Array[Control]:
	var chips: Array[Control] = []
	for need_id: String in effects:
		var amount := int(effects[need_id])
		chips.append(StepCardUi.wood_chip(Database.need_icon(need_id), "%+d" % amount, "have" if amount > 0 else "missing"))
	return chips


## Chip de ingrediente "tem/precisa": verde se tem, vermelho (e tocável: "Como fazer") se falta.
static func _need_chip(item_id: String, need: int) -> Control:
	var have := GameState.inventory.count(item_id)
	return StepCardUi.wood_chip(Database.item_icon(item_id), "%d/%d" % [have, need], "have" if have >= need else "missing", TaskHelp.open.bind("item", item_id, need), "Need_" + item_id)


## Linha de lista em madeira: cartão de papel com prato, título (fonte da madeira), chips que quebram de linha,
## ação à direita e, se houver, um aviso/bloqueio embaixo. Devolve o cartão (`node_name`).
static func _wood_row(parent: Control, node_name: String, plate: Control, title: String, chips: Array[Control], action: Control = null, note: Control = null) -> Control:
	var box := StepCardUi.inner_card(parent, node_name, Vector4i(10, 8, 10, 8))
	var card := box.get_parent().get_parent() as Control
	var top := UiKit.hbox(8)
	box.add_child(top)
	top.add_child(plate)
	var name_label := StationWood.text(title, 17)
	name_label.name = "RowTitle"
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.x = 40.0
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(name_label)
	if action != null:
		action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(action)
	if not chips.is_empty():
		var flow := UiKit.flow(4)
		flow.name = "RowChips"
		for chip in chips:
			flow.add_child(chip)
		box.add_child(flow)
	if note != null:
		box.add_child(note)
	return card


const CATEGORIES := {"food": "Comidas", "care": "Cuidados", "crop": "Colheitas", "material": "Materiais", "product": "Produtos", "find": "Achados", "trail": "Do passeio", "keepsake": "Para o Tiro"}


## Mochila: lugar único com todos os itens e a ocupação de cada depósito ("12/30" ao construir).
## Com `only` (id de depósito: "fridge", "chest", "silo", "warehouse"), só o que mora nele. Ícone + quantidade por
## categoria; tocar abre o detalhe.
## Folha em madeira ilustrada (mesmas peças da aba Mochila, `BagUi`).
static func inventory_view(only: String = "") -> Control:
	var list := InventoryList.new(only)
	list.wood = true
	list.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	list.set_meta("sheet_wood", true)
	return tall(list)


## Consulta compartilhada pelos contratos de conteúdo e achados.
static func _fits_fridge(id: String) -> bool:
	return GameState.storage_of(id) == "fridge"


## Marca o conteúdo como painel alto (88% da tela, com rolagem): listas longas e consultas.
static func tall(content: Control) -> Control:
	content.set_meta("sheet_size", "tall")
	return content


## Detalhe do item (folha "madeira ilustrada", montada pelo `ItemUi`): placa com o nome, cartão compacto (ícone, quantidade,
## uma linha de uso, chips e ações) e os painéis "Origem" / "Usado em". As fontes e os usos vêm de `_sources`/`_uses` abaixo.
static func item_detail(id: String) -> Control:
	return ItemUi.build(id)


## Onde o item fica guardado, em chip: "Geladeira 4/24" (só com o limite ligado). O nó se chama `DepotRow`;
## com lugar no mundo, tocar leva até o depósito. Cheio = chip vermelho.
static func _depot_row(id: String) -> Control:
	var depot := GameState.storage_of(id)
	if depot == "" or not GameState.storage_active(depot):
		return null
	var data: Dictionary = Database.progression.storage[depot]
	var building: Dictionary = Database.progression.upgrades.get(str(data.get("building", "")), {})
	var used := GameState.storage_used(depot)
	var capacity := GameState.storage_capacity(depot)
	var text := "%s %d/%d" % [GameState.storage_name(depot), used, capacity]
	var icon := UiKit.ui_icon(str(building.get("icon", "station_" + depot)))
	var kind := "missing" if used >= capacity else "neutral"
	var row: Control
	if str(data.get("place", "")) != "" and Places.world_error(str(data.get("world", "house"))) == "":
		row = UiKit.tap_chip(icon, text, Places.go.bind({"world": str(data.get("world", "house")), "place": str(data.place)}), null, kind)
	else:
		row = UiKit.chip(icon, text, null, kind)
	row.name = "DepotRow"
	return row


## Fontes do item: [ícone] nome curto → destino. Ex.: Canteiros, Bancada, Volta pelo bairro.
static func _sources(id: String) -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	for source: Dictionary in Database.item_sources(id):
		var key: String = source.key
		var target := Places.goal_target(source)
		if key.begins_with("activity:"):
			var route: Dictionary = Database.progression.activities.get(key.trim_prefix("activity:"), {})
			links.append({"icon": UiKit.ui_icon(route.get("icon", "")), "name": route.get("name", ""), "target": target})
		elif key.begins_with("shop:"):
			var pack: Dictionary = Database.progression.shop_items.get(key.trim_prefix("shop:"), {})
			var shop := Database.shop(str(pack.get("shop", "")))
			links.append({"icon": UiKit.ui_icon("coin"), "name": str(shop.get("name", "Banca")), "target": target})
		elif key.begins_with("walk:"):
			var walk := GameState.walk_def(key.trim_prefix("walk:"))
			links.append({"icon": UiKit.ui_icon("action_walk"), "name": walk.get("name", ""), "target": target})
		elif not target.is_empty() and target.has("world"):
			var place: Dictionary = Database.worlds[target.world].places.get(target.place, {})
			links.append({"icon": UiKit.ui_icon(place.get("icon", "")), "name": place.get("name", ""), "target": target})
	return links


## Onde o item é usado: receitas, construções, encomendas e comida do Tiro.
static func _uses(id: String) -> Array[Dictionary]:
	var links: Array[Dictionary] = []
	for recipe_id: String in Database.recipes:
		var recipe: Dictionary = Database.recipes[recipe_id]
		if recipe.get("inputs", {}).has(id):
			var location := Database.place_with_panel("station:" + str(recipe.station))
			links.append({"icon": Database.item_icon(Database.recipe_output(recipe)), "name": Database.item_name(Database.recipe_output(recipe)), "target": {"world": location[0], "place": "recipe:" + recipe_id, "spot": location[1]}})
	for upgrade_id: String in Database.progression.upgrades:
		var upgrade: Dictionary = Database.progression.upgrades[upgrade_id]
		if upgrade.get("materials", {}).has(id) and not GameState.has_upgrade(upgrade_id):
			links.append({"icon": UiKit.ui_icon(upgrade.get("icon", "")), "name": upgrade.name, "target": Places.goal_target({"type": "owned", "key": upgrade_id})})
	for order_id: String in Database.progression.orders:
		if Database.progression.orders[order_id].get("inputs", {}).has(id):
			links.append({"icon": UiKit.ui_icon("item_treat_box"), "name": Database.progression.orders[order_id].name, "target": Places.goal_target({"type": "stat", "key": "order:" + order_id})})
	return links


## Título curto + botões com ícone que levam ao lugar (fechados ficam apagados).
static func _link_section(box: VBoxContainer, title: String, links: Array[Dictionary]) -> void:
	if links.is_empty():
		return
	box.add_child(UiKit.section(title))
	var list := UiKit.list_card(box)
	for link: Dictionary in links:
		var target: Dictionary = link.target
		var row := UiKit.list_row(link.icon, str(link.name), [], UiKit.ctl("chev", 18), Places.go.bind(target))
		row.custom_minimum_size.y = 56
		if target.has("world") and Places.world_error(str(target.world)) != "":
			row.modulate.a = 0.55
		list.add_child(row)


## Várias estações num painel (Cozinha = fogão + forno): título com ícone e a estação embaixo.
## Estação ainda não comprada mostra o cartão de compra no lugar. Folha em madeira ilustrada.
static func stations_view(ids: PackedStringArray) -> Control:
	var box := UiKit.vbox(12)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	# Só as estações já liberadas contam: com uma só visível, o título do painel já diz o nome.
	var visible_ids := PackedStringArray()
	for id in ids:
		if GameState.requirement_error(Database.stations.get(id, {}).get("requirements", {})) == "":
			visible_ids.append(id)
	for id in visible_ids:
		if visible_ids.size() > 1:
			var title := UiKit.hbox(8)
			title.name = "StationTitle_" + id
			title.add_child(_plate("", UiKit.ui_icon(Database.progression.upgrades.get(id, {}).get("icon", "")), 40.0))
			var name_label := StationWood.text(str(Database.stations.get(id, {}).get("name", id)), 22)
			name_label.name = "StationTitle"
			title.add_child(name_label)
			box.add_child(title)
		box.add_child(station_view(id, "", visible_ids))
	return _wood_sheet(box)


## Estação de produção (fogão): espaços de preparo + receitas em cartões de madeira. `group` = as estações do mesmo
## painel: só a primeira com algo pronto leva o "Pegar tudo" verde (um verde por tela).
static func station_view(station_id: String, focus: String = "", group: PackedStringArray = PackedStringArray()) -> Control:
	var view := LiveBox.new(func(box: VBoxContainer) -> void:
		if not GameState.has_upgrade(station_id):
			ProgressionUi.upgrade_card(box, station_id, true)
			return
		var target := GameState.station(station_id)
		var now := GameState.now()
		var slots := GameState.station_slots(station_id)
		var full := target.queue.size() >= slots
		var data: Dictionary = Database.stations[station_id]
		if data.get("instruction", "") != "":
			var instruction := StationWood.text(str(data.instruction), 15)
			instruction.name = "StationInstruction"
			instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			instruction.custom_minimum_size.x = 40.0
			box.add_child(instruction)
		if data.get("kind", "") == "animal":
			var count := StationWood.text("%d de %d animais" % [GameState.animal_count(station_id), int(data.animal_capacity)], 15)
			count.name = "AnimalCount"
			box.add_child(count)
			var buy := WelcomeSheet._button("Comprar animais", false, 190.0, "BuyAnimals", open_animal_shop.bind(station_id))
			buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			box.add_child(buy)
			if GameState.animal_count(station_id) == 0:
				_empty_message(box, "Abrigo vazio", "Escolha seu primeiro animal.")
				return

		box.add_child(StationWood.station_strip(station_id))
		var ready := target.ready_count(now)
		var first_ready := station_id
		for other in group:
			if GameState.has_upgrade(other) and GameState.station(other).ready_count(now) > 0:
				first_ready = other
				break
		if ready > 0:
			var collect: Button
			var on_collect := func() -> void:
				var received := GameState.collect(station_id)
				Events.items_gained.emit(received, 0, Vector2(-1.0, -1.0))
			if first_ready == station_id:
				collect = StepCardUi.go_button("Pegar tudo (%d)" % ready, on_collect)
			else:
				collect = WelcomeSheet._button("Pegar tudo (%d)" % ready, false, 200.0, "CollectAll_" + station_id, on_collect)
				collect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			collect.name = "CollectAll_" + station_id
			box.add_child(collect)
		box.add_child(mastery_row(station_id))

		if data.get("kind", "") == "animal":
			var section := StationWood.text(str(data.get("recipe_label", "Receitas")), 16)  # estações comuns: a lista fala por si
			section.name = "RecipeSection"
			box.add_child(section)
		for recipe_id in Database.recipes_for(station_id):
			if focus != "" and recipe_id != focus:
				continue
			_recipe_card(box, recipe_id, full))
	return _wood_sheet(view)


## Fileira de bolinhas da estação: um espaço por vaga (vazio, fila, produzindo ou pronto, `Slot_<i>`)
## e, no fim, as ampliações que ainda dá para comprar ("+" e preço, `LockedSlot_<melhoria>`).
## Usada pelo painel (`station_view`) e pela bandeja de estação.
static func station_slot_row(station_id: String) -> HFlowContainer:
	if Database.stations[station_id].get("kind", "") == "animal":
		return _animal_slot_row(station_id)
	var target := GameState.station(station_id)
	var now := GameState.now()
	var row := slot_flow()
	for i in GameState.station_slots(station_id):
		var dot := _slot_card(target.queue[i] if i < target.queue.size() else {}, now)
		dot.name = "Slot_%d" % i
		row.add_child(dot)
	for upgrade_id: String in GameState.pending_slot_upgrades(station_id):
		row.add_child(_locked_slot(upgrade_id))
	return row


## Cada animal fica alinhado ao seu espaço; compras novas não participam do lote antigo.
static func _animal_slot_row(station_id: String) -> HFlowContainer:
	var row := slot_flow()
	row.name = "Herd"
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	var roster := GameState.animal_roster(station_id)
	row.custom_minimum_size.x = roster.size() * SlotDot.DOT + maxi(0, roster.size() - 1) * 8.0
	var queue := GameState.station(station_id).queue
	var entry: Dictionary = queue[0] if not queue.is_empty() else {}
	var fed: Dictionary = {}
	if not entry.is_empty():
		var per_animal := maxi(1, int(Database.recipes[entry.recipe].get("qty", 1)))
		var fallback := roster.slice(0, int(entry.get("qty", per_animal)) / per_animal)
		for id: String in entry.get("animals", fallback):
			fed[id] = int(fed.get(id, 0)) + 1
	for i in roster.size():
		var id: String = roster[i]
		var producing := int(fed.get(id, 0)) > 0
		if producing: fed[id] = int(fed[id]) - 1
		var column := UiKit.vbox(4)
		column.name = "Animal_%d" % i
		var portrait := UiKit.icon(load(Database.animals[id].sprite), 32)
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(portrait)
		var dot := _slot_card(entry if producing else {}, GameState.now())
		dot.name = "Slot_%d" % i
		column.add_child(dot)
		row.add_child(column)
	return row


static func _slot_card(entry: Dictionary, now: float) -> Control:
	if entry.is_empty():
		return slot_frame(null, "", 0.0, false, true)
	var recipe: Dictionary = Database.recipes[entry["recipe"]]
	var seconds := float(recipe["seconds"])
	var remaining := float(entry["ready_at"]) - now
	var texture := Database.item_icon(Database.recipe_output(recipe))
	if remaining <= 0.0:
		return slot_frame(texture, "Pronto!", 1.0, true, false)
	if remaining > seconds:
		return slot_frame(texture, "Na fila", 0.0, false, false, true)
	return slot_frame(texture, format_time(int(ceil(remaining))), 1.0 - remaining / seconds, false, false)


## Espaço ainda fechado: "+" e o preço; tocar abre a compra da ampliação.
static func _locked_slot(upgrade_id: String) -> Control:
	var data: Dictionary = Database.progression.upgrades[upgrade_id]
	var ready := GameState.upgrade_error(upgrade_id) == ""
	var cost := int(data.cost)
	var dot := UiKit.slot_dot(SlotDot.BUY, null, 1.0 if ready else 0.0, "Grátis" if cost <= 0 else str(cost),
			Palette.GO_INK if GameState.coins >= cost else Palette.ALERT_INK, UiKit.ui_icon("coin") if cost > 0 else null)
	dot.name = "LockedSlot_" + upgrade_id
	if not ready:
		dot.modulate.a = 0.75
	UiKit.on_tap(dot, func() -> void:
		Events.sheet_requested.emit(str(data.name), ProgressionUi.purchase(upgrade_id)))
	return dot


## Um espaço de produção em bolinha (`SlotDot`): vazio, na fila, produzindo ou pronto.
## `text` é a legenda (tempo, "Na fila", "Pronto!").
static func slot_frame(texture: Texture2D, text: String, progress: float, done: bool, empty: bool, queued: bool = false) -> Control:
	var state := SlotDot.EMPTY if empty else (SlotDot.READY if done else (SlotDot.QUEUED if queued else SlotDot.BUSY))
	return UiKit.slot_dot(state, texture, progress, text, Palette.GO_INK if done else null)


## Fileira de bolinhas (quebra para a linha de baixo se não couber).
static func slot_flow() -> HFlowContainer:
	var row := UiKit.flow(8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return row


## Medidor de maestria da estação (etapa 18): três selos (bronze/prata/ouro), lotes e receitas até o próximo
## patamar, e "?" com a explicação. Só aparece para estação comprada e com maestria (`Mastery_<estação>`).
static func mastery_row(station_id: String) -> Control:
	var row := UiKit.hbox(6)
	row.name = "Mastery_" + station_id
	if not GameState.mastery_enabled(station_id) or not GameState.has_upgrade(station_id):
		row.visible = false
		return row
	var level := GameState.mastery_level(station_id)
	var seals := UiKit.hbox(2)
	seals.name = "MasterySeals"
	seals.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var colors := [Palette.SEAL_BRONZE, Palette.SEAL_SILVER, Palette.SEAL_GOLD]
	for index in 3:
		var seal := UiKit.icon(UiKit.ui_icon("item_ribbon"), 20)
		seal.modulate = colors[index] if index < level else Color(1, 1, 1, 0.22)
		seals.add_child(seal)
	row.add_child(seals)
	var text := StationWood.text(mastery_text(station_id), 14)
	text.name = "MasteryText"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.custom_minimum_size.x = 40.0
	row.add_child(text)
	row.add_child(StepCardUi.help_button(func() -> void:
		Events.sheet_requested.emit("Maestria: %s" % str(Database.stations[station_id].name), mastery_help(station_id))))
	return row


## "5/12 lotes · 1/2 receitas": o que falta para o próximo patamar (total e variedade); no ouro, só o total.
static func mastery_text(station_id: String) -> String:
	var tiers := GameState.mastery_tiers()
	var level := GameState.mastery_level(station_id)
	var jobs := GameState.mastery_jobs(station_id)
	if level >= tiers.size():
		return "%s · %d lotes" % [str(tiers[level - 1].name), jobs]
	var next: Dictionary = tiers[level]
	var needed := GameState.mastery_kinds_needed(station_id, level)
	var done := GameState.mastery_kinds_done(station_id)
	return "%d/%d lotes · %d/%d %s" % [mini(jobs, int(next.jobs)), int(next.jobs), mini(done, needed), needed, "receita" if needed == 1 else "receitas"]


## Ajuda do medidor em madeira: o total e a variedade de cada patamar, em separado, e o que o selo NÃO faz.
static func mastery_help(station_id: String) -> Control:
	var box := UiKit.vbox(8)
	box.name = "MasteryHelp"
	box.set_meta("sheet_wood", true)
	box.set_meta("sheet_fit_content", true)
	var intro := StationWood.text("Cada lote recolhido vale 1, mesmo que saiam 2 ou 3 itens. Repetir a coleta não conta.", 15)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.custom_minimum_size.x = 40.0
	box.add_child(intro)
	var tiers := GameState.mastery_tiers()
	var level := GameState.mastery_level(station_id)
	var colors := [Palette.SEAL_BRONZE, Palette.SEAL_SILVER, Palette.SEAL_GOLD]
	for index in tiers.size():
		var card := StepCardUi.inner_card(box, "", Vector4i(10, 8, 10, 8))
		var line := UiKit.hbox(8)
		line.name = "Tier_%d" % (index + 1)
		card.add_child(line)
		var seal := UiKit.icon(UiKit.ui_icon("item_ribbon"), 28)
		seal.modulate = colors[index] if index < level else Color(1, 1, 1, 0.22)
		seal.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(seal)
		var needed := GameState.mastery_kinds_needed(station_id, index)
		var text := StationWood.text("%s: %d lotes e %d %s diferentes" % [str(tiers[index].name), int(tiers[index].jobs), needed, "receita" if needed == 1 else "receitas"], 15)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.custom_minimum_size.x = 40.0
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		line.add_child(StepCardUi.wood_chip(UiKit.ui_icon("coin"), "+%d" % int(tiers[index].rewards.get("coins", 0))))
	var kinds := GameState.mastery_kinds_done(station_id)
	for sentence: String in ["Feitos aqui: %d lotes, %d receitas diferentes (de %d abertas)." % [GameState.mastery_jobs(station_id), kinds, GameState.mastery_catalog_size(station_id)], "É só um reconhecimento: não deixa nada mais rápido nem rende mais."]:
		var note := StationWood.text(sentence, 14)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.custom_minimum_size.x = 40.0
		box.add_child(note)
	return box


## Fileira de espaços e, ao lado, o botão "Pegar tudo (N)" (só aparece com `collect_text`; o único principal do painel).
static func slot_strip(slots: Control, collect_text: String = "", on_collect: Callable = Callable(), collect_name: String = "") -> Control:
	var strip := UiKit.hbox(8)
	strip.add_child(slots)
	if collect_text != "":
		var collect := UiKit.primary(collect_text, on_collect)
		collect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		if collect_name != "":
			collect.name = collect_name
		strip.add_child(collect)
	return strip


## Linha de receita em madeira: o que sai, tempo, o que faz, o que precisa e o botão da estação (amarelo calmo;
## bloqueio = botão de madeira apagado com o motivo, no lugar da ação).
static func _recipe_card(parent: VBoxContainer, recipe_id: String, _station_full: bool) -> void:
	var recipe: Dictionary = Database.recipes[recipe_id]
	var locked := GameState.content_error("recipe", recipe_id, recipe)
	var output: String = Database.recipe_output(recipe)
	var inputs: Dictionary = GameState.recipe_inputs(recipe_id)
	var qty := GameState.recipe_quantity(recipe_id)

	# Chips: tempo, efeitos (comidas) e ingredientes (tocáveis quando faltam: mostram de onde vêm).
	var chips: Array[Control] = [StepCardUi.wood_chip(UiKit.ctl_icon("clock"), format_time(int(recipe["seconds"])))]
	chips.append_array(_effect_chips(Database.items.get(output, {}).get("feed", {})))
	for item_id: String in inputs:
		chips.append(_need_chip(item_id, int(inputs[item_id])))

	var action: Button = null
	var note: Control = null
	var error := GameState.cook_error(recipe_id)
	if locked == "":
		var label: String = Database.stations.get(recipe.station, {}).get("action_label", "Fazer")
		if Database.recipe_unique(recipe) and error in ["Você já tem", "Já está sendo costurado", "Já está sendo feita"]:
			label = error
		if error == "":
			action = WelcomeSheet._button(label, false, 92.0, "Cook_" + recipe_id, func() -> void:
				var reason := GameState.cook(recipe_id)
				if reason != "":
					Events.toast_requested.emit(reason))
		else:
			var missing: Texture2D = null
			for item: String in inputs:
				if GameState.inventory.count(item) < int(inputs[item]):
					missing = Database.item_icon(item)
					break
			note = StepCardUi.lock_note(error, TaskHelp.open.bind("recipe", recipe_id), missing)
	else:
		# Receita fechada: linha apagada e botão bloqueado com o motivo.
		note = StepCardUi.lock_note(locked, TaskHelp.open.bind("recipe", recipe_id, int(recipe.get("qty", 1))))
	var card := _wood_row(parent, "Recipe_" + recipe_id, _plate(output, Database.item_icon(output)), Database.item_name(output) + (" ×%d" % qty if qty > 1 else ""), chips, action, note)
	if locked != "":
		card.modulate.a = 0.6


static func open_animal_shop(station_id: String) -> void:
	Events.sheet_requested.emit("Comprar animais", animal_shop(station_id))


## Loja de animais em madeira ilustrada (ver `AnimalShopUi`).
static func animal_shop(station_id: String) -> Control:
	return AnimalShopUi.build(station_id)


## O que falta para comprar o animal, em ícone + número (pode faltar mais de uma coisa):
## produtos a recolher (ex.: ovos 1/2) e moedas (78/80). Outros motivos continuam em texto.
static func _animal_missing(body: VBoxContainer, animal: Dictionary, error: String) -> void:
	var chips := UiKit.flow(4)
	var produced: Dictionary = animal.get("requirements", {}).get("produced", {})
	for item_id: String in produced:
		var done := GameState.progress.stat("produce:" + item_id)
		if done < int(produced[item_id]):
			chips.add_child(UiKit.chip(Database.item_icon(item_id), "%d/%d" % [done, int(produced[item_id])], Palette.ALERT_INK))
	if GameState.coins < int(animal.price):
		chips.add_child(UiKit.chip(UiKit.ui_icon("coin"), "%d/%d" % [GameState.coins, int(animal.price)], Palette.ALERT_INK))
	if chips.get_child_count() > 0:
		body.add_child(chips)
	else:
		chips.free()
		body.add_child(UiKit.label(error, &"SmallLabel"))


## Sementes para um canteiro vazio em madeira: [prato] nome · tempo · colheita · [Plantar] (moeda só se o dado ainda pagar).
## Bloqueada: apagada, com o botão de bloqueio e o "?" que mostra como liberar.
static func seed_picker(plot_index: int, focus: String = "") -> Control:
	var view := LiveBox.new(func(box: VBoxContainer) -> void:
		var crop_ids: Array = Database.crops.keys()
		crop_ids.sort_custom(func(a: String, b: String) -> bool:
			var a_time := int(Database.crops[a].seconds)
			var b_time := int(Database.crops[b].seconds)
			return a_time < b_time if a_time != b_time else a > b)
		for crop_id: String in crop_ids:
			if focus != "" and crop_id != focus:
				continue
			if GameState.crop_plot_error(plot_index, crop_id) != "":
				continue  # estufa: só plantas delicadas; sítio: sem as que só crescem na estufa
			var crop: Dictionary = Database.crops[crop_id]
			var locked := GameState.content_error("crop", crop_id, crop)
			var chips: Array[Control] = [StepCardUi.wood_chip(UiKit.ctl_icon("clock"), format_time(int(round(GameState.crop_seconds(plot_index, crop_id)))))]
			if int(crop.get("coins", 0)) > 0:  # R1: colher não paga moeda; só mostra se o dado ainda pagar
				chips.append(StepCardUi.wood_chip(UiKit.ui_icon("coin"), "+%d" % int(crop.get("coins", 0))))
			var harvest: Dictionary = crop.get("yield", {})
			for item_id: String in harvest:
				chips.append(StepCardUi.wood_chip(Database.item_icon(item_id), "+%d" % int(harvest[item_id]), "have"))
			var plant: Button = null
			var note: Control = null
			if locked == "":
				plant = WelcomeSheet._button("Plantar", false, 92.0, "Plant_" + crop_id, func() -> void:
					var error := GameState.plant(plot_index, crop_id)
					if error != "":
						Events.toast_requested.emit(error)
					Events.sheet_close_requested.emit())
			else:
				note = StepCardUi.lock_note(locked, TaskHelp.open.bind("crop", crop_id))
			var card := _wood_row(box, "Seed_" + crop_id, _plate(crop_id, PlotTray.seed_icon(crop_id)), Database.item_name(crop_id), chips, plant, note)
			if locked != "":
				card.modulate.a = 0.6)
	return _wood_sheet(view)


## Canteiros em madeira: terrenos (barra), próximo terreno e cada canteiro num quadradinho creme (ícone + estado).
static func farm_view(focus: String = "", greenhouse_only: bool = false) -> Control:
	var view := LiveBox.new(func(box: VBoxContainer) -> void:
		if greenhouse_only:
			var hint := StationWood.text("Plantas delicadas · crescem mais rápido", 15)
			hint.name = "GreenhouseHint"
			box.add_child(hint)
			var house_grid := GridContainer.new()
			house_grid.name = "GreenhousePlots"
			house_grid.columns = 2
			house_grid.mouse_filter = Control.MOUSE_FILTER_PASS
			house_grid.add_theme_constant_override("h_separation", 8)
			house_grid.add_theme_constant_override("v_separation", 8)
			for index in GameState.usable_plot_indices():
				if GameState.is_greenhouse_plot(index):
					house_grid.add_child(_plot_tile(index, focus))
			box.add_child(house_grid)
			return
		var total := int(Database.farm.get("plots", 0))
		if not GameState.has_upgrade("farm"):
			# Antes da escritura: um canteiro emprestado e a compra do sítio.
			ProgressionUi.upgrade_card(box, "farm", true)
		var land := UiKit.hbox(8)
		land.name = "Land"
		land.add_child(_plate("", UiKit.ui_icon("tab_farm"), 40.0))
		land.add_child(StepCardUi.bar(float(GameState.accessible_plots()) / maxf(1.0, float(total)), 22.0, "LandBar"))
		var count := StationWood.text("%d/%d" % [GameState.accessible_plots(), total], 18)
		count.name = "LandCount"
		land.add_child(count)
		box.add_child(land)
		if GameState.has_upgrade("farm") and GameState.unlocked_plots < total:
			var cost := GameState.plot_cost(GameState.unlocked_plots)
			var on_buy := func() -> void:
				Events.sheet_requested.emit("Terreno %d" % (GameState.unlocked_plots + 1), plot_purchase(GameState.unlocked_plots))
			var buy: Button
			if GameState.coins >= cost:
				buy = StepCardUi.go_button("+1 terreno · %d" % cost, on_buy, UiKit.ui_icon("coin"))
			else:
				buy = WelcomeSheet._button("+1 terreno · %d" % cost, false, 220.0, "", on_buy)
				buy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			buy.name = "BuyNextPlot"
			box.add_child(buy)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		var garden: Array[int] = []
		for index in GameState.usable_plot_indices():
			if not GameState.is_greenhouse_plot(index):
				garden.append(index)
		for index in garden:
			grid.add_child(_plot_tile(index, focus))
		box.add_child(grid)
	)
	return _wood_sheet(view)


## Canteiro: vazio = "Livre"; crescendo = planta + %; pronto = quadradinho amarelo "Colher!".
static func _plot_tile(index: int, focus: String) -> Button:
	var status := GameState.plot_status(index)
	var crop: String = GameState.plot(index)["crop"]
	var caption := "Livre" if status == "empty" else ("Colher!" if status == "ready" else "%d%%" % int(GameState.plot_progress(index) * 100))
	var icon: Texture2D = PlotTray.seed_icon(crop) if crop != "" else UiKit.ui_icon("tab_farm")
	var tile := StationWood.recipe_tile({"icon": icon, "item": crop, "caption": caption}, "selected" if status == "ready" else "normal", null)
	tile.name = "Plot_%d" % index
	tile.custom_minimum_size = Vector2(0, 84)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# O resumo é só consulta: tocar num canteiro fecha o painel, leva a câmera até ele e abre a bandeja de ação.
	tile.pressed.connect(func() -> void:
		Motion.bounce(tile)
		Events.sheet_close_requested.emit()
		Events.plot_tray_requested.emit(focus, index))
	return tile


## Comprar terreno: a folha em madeira mora em `ProgressionUi.plot_purchase` (a mesma peça da compra de construção).
static func plot_purchase(index: int) -> Control:
	return ProgressionUi.plot_purchase(index)


## Planta crescendo em madeira: prato, barra com tempo e o que vai render.
static func growing_plot(index: int) -> Control:
	var view := LiveBox.new(func(box: VBoxContainer) -> void:
		var target := GameState.plot(index)
		if target["crop"] == "":
			box.add_child(StepCardUi.go_button("Plantar de novo", func() -> void:
				Events.sheet_requested.emit("Canteiro", seed_picker(index)), UiKit.ui_icon("tab_farm")))
			return
		var crop_id: String = target["crop"]
		var ready := GameState.plot_status(index) == "ready"
		var top := UiKit.hbox(10)
		top.add_child(_plate(crop_id, PlotTray.seed_icon(crop_id), 64.0))
		var info := UiKit.vbox(6)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var line := UiKit.hbox(6)
		line.add_child(StepCardUi.bar(GameState.plot_progress(index), 22.0, "GrowBar"))
		var remaining := maxi(0, int(ceil(float(target["ready_at"]) - GameState.now())))
		line.add_child(StationWood.text("Pronta!" if ready else format_time(remaining), 17, Palette.GO_INK if ready else Palette.WOOD_INK))
		info.add_child(line)
		var reward := int(GameState.plot_job(index).get("coins", 0))  # o que valia ao plantar
		var gains := UiKit.flow(4)
		if reward > 0:
			gains.add_child(StepCardUi.wood_chip(UiKit.ui_icon("coin"), "+%d" % reward))
		var harvest: Dictionary = Database.crops[crop_id].get("yield", {})
		for item_id: String in harvest:
			gains.add_child(StepCardUi.wood_chip(Database.item_icon(item_id), "+%d" % int(harvest[item_id]), "have"))
		info.add_child(gains)
		top.add_child(info)
		box.add_child(top)
		if ready:
			box.add_child(StepCardUi.go_button("Colher", func() -> void:
				var received := GameState.harvest(index)
				if not received.is_empty():
					Events.items_gained.emit(received, reward, Vector2(-1.0, -1.0)))))
	return _wood_sheet(view)


static func _empty_message(box: VBoxContainer, title: String, hint: String) -> void:
	var body := StepCardUi.inner_card(box, "EmptyMessage", Vector4i(14, 14, 14, 14))
	var text := StationWood.text(title, 19)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(text)
	if hint != "":
		var small := StationWood.text(hint, 15)
		small.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		small.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		small.custom_minimum_size.x = 40.0
		body.add_child(small)


static func format_time(seconds: int) -> String:
	return TimeText.short(seconds)


## Caixa que se reconstrói quando o estado muda e a cada segundo (timers).
class LiveBox extends VBoxContainer:
	var _build: Callable
	var _pending: bool = false
	var _touches: Dictionary = {}

	func _init(build: Callable) -> void:
		_build = build
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_theme_constant_override("separation", 8)

	func _ready() -> void:
		Events.state_changed.connect(_schedule_rebuild)
		var timer := Timer.new()
		timer.wait_time = 1.0
		timer.autostart = true
		timer.timeout.connect(_on_tick)
		add_child(timer)
		_rebuild()

	## Reconstrói no fim do frame (ex.: troca de aba dentro do painel).
	func refresh() -> void:
		_schedule_rebuild()

	func _input(event: InputEvent) -> void:
		if event is InputEventScreenTouch:
			if event.pressed and not event.canceled:
				_touches[event.index] = true
			else:
				_touches.erase(event.index)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
			_touches.clear()

	func _on_tick() -> void:
		# Não reconstrói com o dedo na tela, para não "roubar" um toque em andamento.
		if bool(get_meta("tick_refresh", true)) and is_visible_in_tree() and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_schedule_rebuild()

	func _schedule_rebuild() -> void:
		if _pending or bool(get_meta("ui_animating", false)):
			return
		_pending = true
		_rebuild.call_deferred()

	func _rebuild() -> void:
		_pending = true
		# state_changed e refresh também podem chegar entre down/up (não só o timer).
		# Preserve os nós e agrupe os pedidos até o fim do gesto, senão pressed se perde.
		while is_inside_tree() and (not _touches.is_empty() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			await get_tree().process_frame
		_pending = false
		if is_queued_for_deletion() or not is_inside_tree() or bool(get_meta("ui_animating", false)):
			return
		for child in get_children():
			if not child is Timer:
				remove_child(child)
				child.queue_free()
		_build.call(self)
