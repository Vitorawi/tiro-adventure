extends CanvasLayer
## Comemoração modal acima do Sheet, sem estado persistente: capítulo concluído, nível, vínculo,
## achado, tesouro, truque e novidades reveladas pela história ("Novo!": ícone + nome + Ir).
## Todos os cartões usam o `ModalCard` (fita, ícone com raios, chips que entram um por um).
## Confete só nos grandes momentos: nível, capítulo, tesouro e vínculo.


## Capítulo concluído: recompensas + novidades.
func show_chapter(index: int, unlocks: Array[String]) -> void:
	var chapter: Dictionary = Database.progression.chapters[index - 1]
	var card := _open({"title": "Capítulo concluído!", "ribbon": Palette.PRIMARY, "icon": UiKit.ui_icon("xp"),
		"scroll_name": "CelebrationScroll", "confetti": true, "haptic": "big"})
	card.add_text(str(chapter.name), &"SectionLabel")
	card.add_chips(ProgressionUi.reward_chips(chapter.get("rewards", {})))
	_unlock_rows(card, unlocks)
	card.add_primary("Próximo passo", func() -> void:
		hide()
		Events.sheet_close_requested.emit()
		Events.screen_requested.emit(&"tasks"))
	card.add_ghost("Continuar", hide)
	show()


## Subiu de nível: o presente já entrou; o botão só fecha.
## Obra comunitária concluída: o prêmio já entrou (itens sem espaço ficaram em "Presentes para guardar").
func show_project(id: String) -> void:
	var def := Database.project(id)
	var card := _open({"title": "Obra pronta!", "ribbon": Palette.PRIMARY, "icon": UiKit.ui_icon(str(def.get("icon", "tab_park"))), "icon_px": 96,
		"scroll_name": "CelebrationScroll", "confetti": true, "haptic": "big"})
	card.add_text(str(def.get("name", "")), &"SectionLabel")
	var chips := ProgressionUi.reward_chips(def.get("rewards", {}))
	# A coleção já entrou no prêmio: o cartão a mostra pelo nome (lembrança da obra, sem ocupar baú).
	for collection: String in def.get("rewards", {}).get("collections", []):
		chips.add_child(UiKit.chip(UiKit.ui_icon(str(Database.collections.get(collection, {}).get("icon", "item_accessory_set"))), str(Database.collections.get(collection, {}).get("name", collection))))
	card.add_chips(chips)
	card.add_text(str(def.get("interaction", {}).get("hint", "")), &"SmallLabel")
	card.add_primary("Oba!", hide)
	show()


## Subiu de vínculo com o Tiro: o presente já entrou; o botão só fecha.
func show_bond(level: int, rewards: Dictionary) -> void:
	var card := _open({"title": "Vínculo %d!" % level, "ribbon": Palette.ACCENT, "icon": UiKit.ui_icon("bond_heart"),
		"scroll_name": "CelebrationScroll", "confetti": true, "haptic": "success"})
	card.add_chips(ProgressionUi.reward_chips(rewards))
	card.add_primary("Oba!", hide)
	show()


## Pelagem de seda: cartão curto; confete só a partir do nível II. O presente já entrou.
func show_silk(level: int) -> void:
	var def: Dictionary = Database.growth.silk.levels[level - 1]
	var card := _open({"title": "Mais brilho!", "ribbon": Palette.GOLD, "icon": load(str(Database.growth.bodies.adult.portrait)),
		"scroll_name": "CelebrationScroll", "confetti": level > 1, "haptic": "success"})
	card.add_text(str(def.name), &"SectionLabel")
	card.add_chips(ProgressionUi.reward_chips(def.get("rewards", {})))
	card.add_primary("Oba!", hide)
	show()


## Achado novo do faro.
func show_find(result: Dictionary) -> void:
	var ids: Array = result.get("new", [])
	var item := str(ids[0]) if not ids.is_empty() else ""
	var texture: Texture2D = Database.item_icon(item) if item != "" else UiKit.ui_icon(str(result.get("icon", "find_paw")))
	var card := _open({"title": "Novo achado!", "ribbon": Palette.INFO, "icon": texture,
		"scroll_name": "CelebrationScroll", "haptic": "success"})
	card.add_text(Database.item_name(item) if item != "" else str(result.get("announcement", result.label)), &"SectionLabel")
	var progress_text := "%d/16" % GameState.find_album_count()
	if item.begins_with("map_piece_"):
		var pieces := 0
		for n in range(1, 5):
			pieces += 1 if GameState.progress.stat("find_item:map_piece_%d" % n) > 0 else 0
		progress_text = "%d/4" % pieces
	elif item == "":
		progress_text = str(result.get("unlock_label", ""))
	card.add_text(progress_text, &"SmallLabel")
	card.add_primary("Oba!", hide)
	show()


## Baú da Clareira: a festa grande. Os prêmios já entraram; o cartão só mostra o que veio.
func show_treasure(rewards: Dictionary) -> void:
	var def: Dictionary = Database.progression.treasure
	var card := _open({"title": "Tesouro encontrado!", "ribbon": Palette.GOLD,
		"icon": UiKit.ui_icon(str(def.get("icon", "item_map_piece"))), "icon_px": 96,
		"scroll_name": "CelebrationScroll", "confetti": true, "haptic": "big"})
	card.add_text(str(def.get("name", "")), &"SectionLabel")
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
			card.add_text("Muda nova: %s" % Database.item_name(crop), &"SmallLabel", UiKit.GOOD)
	card.add_primary("Oba!", hide)
	show()


func show_trick(id: String) -> void:
	var def: Dictionary = Database.progression.tricks[id]
	var card := _open({"title": "Novo truque!", "ribbon": Palette.ACCENT, "icon": UiKit.ui_icon(str(def.icon)),
		"scroll_name": "CelebrationScroll", "haptic": "success"})
	card.add_text(str(def.name), &"SectionLabel")
	card.add_primary("Oba!", hide)
	show()


func show_unlocks(unlocks: Array[String]) -> void:
	var card := _open({"title": "Novo!", "ribbon": Palette.PRIMARY, "scroll_name": "CelebrationScroll"})
	_unlock_rows(card, unlocks)
	card.add_primary("Continuar", hide)
	show()


## Uma linha por novidade: [ícone] Nome  [Ir].
func _unlock_rows(card: ModalCard, unlocks: Array[String]) -> void:
	for key in unlocks:
		var view := Places.unlock_view(key)
		if view.is_empty():
			continue
		var target: Dictionary = view.target
		var name_box := UiKit.vbox(0)
		name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_box.add_child(UiKit.label("Novo!", &"SmallLabel", UiKit.GOOD))
		name_box.add_child(UiKit.label(view.name, &"SectionLabel"))
		var go := UiKit.secondary("Ir", func() -> void:
			hide()
			Places.go(target), null, true)
		go.custom_minimum_size = Vector2(72, 48)
		var inner := UiKit.card(card.box, &"CardPanel")
		var row := UiKit.hbox(10)
		row.add_child(UiKit.icon(view.icon, 48))
		row.add_child(name_box)
		row.add_child(go)
		inner.add_child(row)


func _open(options: Dictionary) -> ModalCard:
	return ModalCard.open(self, options)
