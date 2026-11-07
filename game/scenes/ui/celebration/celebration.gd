extends CanvasLayer
## Comemoração modal acima do Sheet, sem estado persistente: capítulo concluído, nível, vínculo,
## achado, tesouro, truque e novidades reveladas pela história ("Novo!": ícone + nome + Ir).
## Todos os cartões usam o `ModalCard` (fita, ícone com raios, chips que entram um por um).
## Confete só nos grandes momentos: nível, capítulo, tesouro e vínculo.


var _pending_unlocks: Array[Dictionary] = []


## Capítulo concluído: recompensas + novidades.
func show_chapter(index: int, unlocks: Array[String]) -> void:
	var chapter: Dictionary = Database.progression.chapters[index - 1]
	var card := _open({"title": "Capítulo concluído!", "ribbon": Palette.GO, "ribbon_icon": "check", "icon": UiKit.ui_icon("xp"),
		"scroll_name": "CelebrationScroll", "fixed_body": true, "confetti": true, "haptic": "big"})
	card.add_text(str(chapter.name), &"StrongLabel")
	card.add_chips(ProgressionUi.reward_chips(chapter.get("rewards", {})))
	_unlock_rows(card, unlocks)
	var next := GameState.progress.displayed_main_quest()
	if next != "":
		card.add(RewardSheet.next_card(next))
		card.add_primary("Ir para " + ProgressionUi.quest_place_name(Places.quest_target(next)), func() -> void:
			hide()
			Events.sheet_close_requested.emit()
			Places.go(Places.quest_target(next)))
	else: card.add_primary("Que bom!", hide)
	card.add_ghost("Continuar", hide)
	show()


## Subiu de nível: o presente já entrou; o botão só fecha.
## Obra comunitária concluída: o prêmio já entrou (itens sem espaço ficaram em "Presentes para guardar").
func show_project(id: String) -> void:
	var def := Database.project(id)
	var card := _open({"title": "Obra pronta!", "ribbon": Palette.GO, "ribbon_icon": "check", "icon": UiKit.ui_icon(str(def.get("icon", "tab_park"))), "icon_px": 96,
		"scroll_name": "CelebrationScroll", "confetti": true, "haptic": "big"})
	card.add_text(str(def.get("name", "")), &"StrongLabel")
	var chips := ProgressionUi.reward_chips(def.get("rewards", {}))
	# A coleção já entrou no prêmio: o cartão a mostra pelo nome (lembrança da obra, sem ocupar baú).
	for collection: String in def.get("rewards", {}).get("collections", []):
		chips.add_child(UiKit.chip(UiKit.ui_icon(str(Database.collections.get(collection, {}).get("icon", "item_accessory_set"))), str(Database.collections.get(collection, {}).get("name", collection))))
	card.add_chips(chips)
	card.add_text(str(def.get("interaction", {}).get("hint", "")), &"SmallLabel")
	card.add_primary("Oba!", hide)
	show()


## Pelagem de seda: cartão curto; confete só a partir do nível II. O presente já entrou.
func show_silk(level: int) -> void:
	var def: Dictionary = Database.growth.silk.levels[level - 1]
	var card := _open({"title": "Mais brilho!", "ribbon": Palette.HONEY, "icon": load(str(Database.growth.bodies.adult.portrait)),
		"scroll_name": "CelebrationScroll", "confetti": level > 1, "haptic": "success"})
	card.add_text(str(def.name), &"StrongLabel")
	card.add_chips(ProgressionUi.reward_chips(def.get("rewards", {})))
	card.add_primary("Oba!", hide)
	show()


## Achado novo do faro.
func show_find(result: Dictionary) -> void:
	var ids: Array = result.get("new", [])
	var item := str(ids[0]) if not ids.is_empty() else ""
	var texture: Texture2D = Database.item_icon(item) if item != "" else UiKit.ui_icon(str(result.get("icon", "find_paw")))
	var card := _open({"title": "Novo achado!", "ribbon": Palette.SKY, "ribbon_icon": "spark", "icon": texture,
		"scroll_name": "CelebrationScroll", "haptic": "success"})
	card.add_text(Database.item_name(item) if item != "" else str(result.get("announcement", result.label)), &"StrongLabel")
	var progress_text := "%d/16" % GameState.find_album_count()
	if item.begins_with("map_piece_"):
		var pieces := 0
		for n in range(1, 5):
			pieces += 1 if GameState.progress.stat("find_item:map_piece_%d" % n) > 0 else 0
		progress_text = "%d/4" % pieces
	elif item == "":
		progress_text = str(result.get("unlock_label", ""))
	if progress_text != "":
		card.add_pill(progress_text, "FindCount")
	card.add_primary("Oba!", hide)
	show()


## Baú da Clareira: a festa grande. Os prêmios já entraram; o cartão só mostra o que veio.
func show_treasure(rewards: Dictionary) -> void:
	var def: Dictionary = Database.progression.treasure
	var card := _open({"title": "Tesouro encontrado!", "ribbon": Palette.HONEY,
		"icon": UiKit.ui_icon(str(def.get("icon", "item_map_piece"))), "icon_px": 96,
		"scroll_name": "CelebrationScroll", "confetti": true, "haptic": "big"})
	card.add_text(str(def.get("name", "")), &"StrongLabel")
	var chips := UiKit.flow()
	if int(rewards.get("coins", 0)) > 0:
		chips.add_child(UiKit.chip(UiKit.ui_icon("coin"), "+%d" % int(rewards.coins)))
	for id: String in rewards.get("items", {}):
		chips.add_child(UiKit.chip(Database.item_icon(id), "+%d" % int(rewards.items[id])))
	for id: String in rewards.get("collections", []):
		chips.add_child(UiKit.chip(UiKit.ui_icon(str(Database.collections.get(id, {}).get("icon", "item_accessory_set"))), "+1"))
	card.add_chips(chips)
	for unlock: String in rewards.get("unlocks", []):
		if unlock.begins_with("crop:"):
			var crop := unlock.trim_prefix("crop:")
			card.add_text("Muda nova: %s" % Database.item_name(crop), &"SmallLabel", Palette.GO_INK)
	card.add_primary("Oba!", hide)
	show()


## Item principal que um personagem entregou: o item já entrou; o cartão só o mostra.
func show_gift(item: String, npc: String) -> void:
	var card := _open({"title": "Você ganhou!", "icon": Database.item_icon(item), "icon_px": 96,
		"scroll_name": "CelebrationScroll", "haptic": "success"})
	card.add_text(Database.item_name(item), &"StrongLabel")
	var giver := str(Database.npcs.get(npc, {}).get("name", ""))
	if giver != "":
		card.add_text("%s te deu" % giver, &"SmallLabel")
	card.add_primary("Oba!", hide)
	show()


## Marco de coleção do álbum (seção completa, 4 versões, Raras ou primeira Holográfica): o prêmio já entrou.
func show_album_milestone(kind: String, key: String) -> void:
	var title := "Marco do álbum!"
	var subtitle := ""
	var level := 3
	match kind:
		"section":
			var name_text := key
			for section: Dictionary in Database.album_sections():
				if str(section.id) == key: name_text = str(section.name)
			title = "Seção completa!"
			subtitle = name_text
		"styles":
			title = "Quatro versões!"
			subtitle = str(Database.photo(key).get("title", key))
		"rare":
			title = "Fotos Raras!"
			subtitle = "%s Raras ou melhores" % key
		"holo":
			title = "Primeira Holográfica!"
			subtitle = "O brilho mais raro"
			level = 4
	var options := {"title": title, "ribbon": Palette.HONEY, "ribbon_icon": "spark",
		"scroll_name": "CelebrationScroll", "confetti": true, "haptic": "big"}
	var photo := _milestone_photo(kind, key)
	if photo != "":
		options["hero"] = PhotoCard.make(photo, 150.0, {"effects": false})
	else:
		options["icon"] = load(PhotoCard.FRAMES_DIR + "frame_%d.png" % level)
		options["icon_px"] = 96
	var card := _open(options)
	if subtitle != "":
		card.add_text(subtitle, &"StrongLabel")
	card.add_chips(ProgressionUi.reward_chips(GameState.album_milestone_rewards(kind, key)))
	card.add_primary("Oba!", hide)
	show()


## A foto que ilustra o marco: a própria (4 versões) ou a de melhor versão entre as que o motivaram.
func _milestone_photo(kind: String, key: String) -> String:
	if kind == "styles":
		return key if GameState.album.has_photo(key) else ""
	var best := ""
	for entry: Dictionary in Database.album.photos:
		var id := str(entry.id)
		if not GameState.album.has_photo(id): continue
		if kind == "section" and str(entry.section) != key: continue
		if kind == "rare" and GameState.photo_rarity(id) < 3: continue
		if kind == "holo" and 4 not in GameState.photo_variants(id): continue
		if best == "" or GameState.photo_rarity(id) > GameState.photo_rarity(best): best = id
	return best


func show_trick(id: String) -> void:
	var def: Dictionary = Database.progression.tricks[id]
	var card := _open({"title": "Novo truque!", "ribbon": Palette.SKY, "ribbon_icon": "spark", "icon": UiKit.ui_icon(str(def.icon)),
		"scroll_name": "CelebrationScroll", "haptic": "success"})
	card.add_text(str(def.name), &"StrongLabel")
	card.add_primary("Oba!", hide)
	show()


## "Novo!": uma folha pequena por novidade (ícone, nome, uma linha, Ir/Depois); Depois passa para a próxima.
func show_unlocks(unlocks: Array[String]) -> void:
	_pending_unlocks.clear()
	for key in unlocks:
		var view := Places.unlock_view(key)
		if not view.is_empty():
			view["key"] = key
			_pending_unlocks.append(view)
	_next_unlock()


func _next_unlock() -> void:
	if _pending_unlocks.is_empty():
		hide()
		return
	var view: Dictionary = _pending_unlocks.pop_front()
	var target: Dictionary = view.target
	var sheet := RewardSheet.open(self, {"title": "Novo!", "scroll_name": "CelebrationScroll", "haptic": "success", "on_close": _next_unlock})
	# Ícone num pratinho bege: pixel em escala inteira (nítido), ilustração reduzida e suave.
	var icon_texture: Texture2D = view.icon
	var drawn := 64.0
	if icon_texture.get_width() <= 32:
		drawn = float(icon_texture.get_width() * maxi(1, roundi(64.0 / icon_texture.get_width())))
	var plate := WelcomeSheet._plate(drawn + 24.0, icon_texture, "UnlockIcon", drawn)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sheet.add(plate)
	sheet.add_text(str(view.name), &"TitleLabel")
	sheet.add_text(_unlock_line(str(view.key)), &"SmallLabel")
	var actions := sheet.add_actions("Depois", sheet.close, _unlock_go_text(target), func() -> void:
		_pending_unlocks.clear()
		hide()
		Places.go(target))
	var go := actions.primary as Button
	go.name = "UnlockGo"
	# Destino que não cabe no botão vira só "Ir".
	if go.has_meta("too_long"):
		go.text = "Ir"
	show()
	sheet.present()


func _unlock_line(key: String) -> String:
	match key.get_slice(":", 0):
		"world": return "Já está no Mapa"
		"place", "npc", "walk":
			var target: Dictionary = Places.unlock_view(key).get("target", {})
			var in_name := str(Database.worlds.get(str(target.get("world", "")), {}).get("in_name", ""))
			if in_name != "": return in_name.left(1).to_upper() + in_name.substr(1)
	return "Uma novidade"


func _unlock_go_text(target: Dictionary) -> String:
	var in_name := str(Database.worlds.get(str(target.get("world", "")), {}).get("in_name", ""))
	if in_name.begins_with("na "): return "Ir para a " + in_name.trim_prefix("na ")
	if in_name.begins_with("no "): return "Ir para o " + in_name.trim_prefix("no ")
	return "Ir"


## Grade de novidades, com prioridade do mundo ao juntar destinos repetidos.
func _unlock_rows(card: ModalCard, unlocks: Array[String]) -> void:
	var views: Array[Dictionary] = []
	# Mundos primeiro: se um lugar tiver o mesmo nome/destino, fica o mundo.
	var ordered: Array[String] = []
	for key in unlocks:
		if key.begins_with("world:"): ordered.append(key)
	for key in unlocks:
		if not key.begins_with("world:"): ordered.append(key)
	for key in ordered:
		var view := Places.unlock_view(key)
		if view.is_empty(): continue
		var duplicate := false
		for previous: Dictionary in views:
			if previous.target == view.target or (str(previous.key).begins_with("world:") and key.begins_with("place:") and previous.target.get("world") == view.target.get("world") and previous.name == view.name):
				duplicate = true
		if duplicate: continue
		view["key"] = key
		views.append(view)
	if views.is_empty(): return
	card.add_text("Novidades", &"SmallLabel")
	var grid := GridContainer.new()
	grid.name = "ChapterUnlocks"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for view: Dictionary in views:
		var target: Dictionary = view.target
		var tile := UiKit.tile(view.icon, str(view.name), "sunken")
		tile.name = "ChapterUnlock_" + str(view.key).replace(":", "_").replace("/", "_")
		tile.set_meta("target", target)
		tile.set_meta("unlock_name", str(view.name))
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var caption := tile.find_child("Visual", true, false).get_child(1) as Label
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tile.pressed.connect(func() -> void:
			hide()
			Places.go(target))
		grid.add_child(tile)
	card.add_scroll_area(grid)
	card.reveal(grid)


func _open(options: Dictionary) -> ModalCard:
	_pending_unlocks.clear()
	return ModalCard.open(self, options)
