class_name WishUi
extends RefCounted
## Peças visuais do desejo do Tiro: ícone, destino do "Ir" e o cartão curto do balão (sem aba própria).
## Ícone + número; só ações pelo GameState.


## Ícone do desejo: o campo "icon" (ação) ou o do item pedido.
static func icon(wish_id: String) -> Texture2D:
	var def := GameState.wish_now() if wish_id == GameState.wish_id() else GameState.wish_def(wish_id)
	if def.get("type", "") == "action":
		return UiKit.ui_icon(str(def.get("icon", "tab_wishes")))
	return Database.item_icon(str(def.get("item", "")))


## Ícone do pilar que o desejo faz crescer (Corpo conta pela refeição).
static func pillar_icon(pillar: String) -> Texture2D:
	var data: Dictionary = Database.growth.pillars.get(pillar, {})
	return UiKit.ui_icon(str(data.get("icon", "heart"))) if not data.is_empty() else null


## O desejo pede para sair da tela do Tiro (passeio, outro mundo, comida que ainda precisa fazer)?
static func needs_trip(def: Dictionary) -> bool:
	var target := go_target(def)
	return not target.is_empty() and (target.has("world") or str(target.get("screen", "")) != "pet")


## Cartão do balão: o pedido em uma linha, o prêmio (momento) e Pegar/Dar quando dá, ou Ir quando é fora da tela.
static func balloon_card() -> Control:
	var def := GameState.wish_now()
	var card := UiKit.vbox(6)
	card.name = "WishCard"
	card.custom_minimum_size.x = 232
	if def.is_empty():
		return card
	var row := UiKit.hbox(8)
	row.add_child(UiKit.icon(icon(GameState.wish_id()), 40))
	var title := UiKit.fill_label(str(def.name) + "!", &"SectionLabel")
	title.name = "WishTitle"
	row.add_child(title)
	card.add_child(row)
	var ready := GameState.wish_error() == ""
	var pillar := str(def.pillar)
	var prize := UiKit.chip(pillar_icon(pillar), "Refeição" if pillar == "body" else "+1 momento")
	prize.name = "WishPrize"
	card.add_child(prize)
	if ready:
		var give: bool = def.type != "action"
		var take := UiKit.primary("Dar" if give else "Pegar", func() -> void:
			var error := GameState.fulfill_wish()
			if error != "": Events.toast_requested.emit(error))
		take.name = "WishTake"
		card.add_child(take)
	elif needs_trip(def):
		var go := UiKit.secondary("Ir", func() -> void: Places.go(go_target(def)), null, true)
		go.name = "WishGo"
		card.add_child(go)
	return card


## Para onde o "Ir" leva: tela ("screen:pet"), lugar/personagem ("place:mundo:lugar") ou, para comida, a origem dela.
static func go_target(def: Dictionary) -> Dictionary:
	var go := str(def.get("go", ""))
	if go.begins_with("screen:"):
		return {"screen": go.trim_prefix("screen:")}
	if go.begins_with("place:"):
		var parts := go.split(":", true, 2)
		return {"world": parts[1], "place": parts[2], "hint": "Passeio"}
	if def.get("type", "") != "action":
		return Places.goal_target({"type": "have", "key": str(def.item)})
	return {"screen": "pet"}
