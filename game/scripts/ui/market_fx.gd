class_name MarketFx
extends RefCounted
## Efeitos táteis da banca (Vender · Comprar): o item voa, as moedas voam e uma mensagenzinha discreta sobe.
## Só apresentação: a regra (`GameState.sell` / `buy_shop_item`) já rodou. Tudo vive numa camada própria
## ("MarketFxLayer", acima da folha) e some junto com a folha. Com Menos animação não há voos: só a mensagem.

const Z := 22
const ICON_PX := 30
const COIN_PX := 22
const TEXT_LIFE := 1.2
const RISE := 34.0
const MIN_TOP := 124.0  # nunca sobe para baixo do HUD


static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func _main() -> Node:
	var tree := _tree()
	var main := tree.root.get_node_or_null("Main")
	return main if main else (tree.current_scene if tree.current_scene else tree.root)


## Camada de efeitos (criada na primeira vez; esvaziada quando a folha fecha).
static func layer() -> Control:
	var host := _main()
	var found := host.get_node_or_null("MarketFxLayer") as Control
	if found:
		return found
	var made := Control.new()
	made.name = "MarketFxLayer"
	made.mouse_filter = Control.MOUSE_FILTER_IGNORE
	made.z_as_relative = false
	made.z_index = Z
	made.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.add_child(made)
	var events := _tree().root.get_node("Events")
	events.sheet_close_requested.connect(clear)
	return made


static func clear() -> void:
	var found := _main().get_node_or_null("MarketFxLayer") as Control
	if found:
		for child in found.get_children():
			child.queue_free()


static func _hud() -> Control:
	return _main().get_node_or_null("TopBar") as Control


static func _coins_point() -> Vector2:
	var hud := _hud()
	return hud.call("coins_target") if hud else Vector2(180.0, 40.0)


## Centro do ícone da aba Mochila (Vector2(-1, -1) se a casca não tem barra de abas).
static func bag_point() -> Vector2:
	var main := _main()
	var tab := main.find_child("BagTab", true, false) as Button
	var faces: Variant = main.get("_faces")
	if tab == null or not tab.is_visible_in_tree() or not (faces is Dictionary) or not (faces as Dictionary).has(&"bag"):
		return Vector2(-1.0, -1.0)
	return tab.global_position + ((faces as Dictionary)[&"bag"] as Control).call("icon_center")


static func _bag_arrived() -> void:
	var faces: Variant = _main().get("_faces")
	if faces is Dictionary and (faces as Dictionary).has(&"bag"):
		((faces as Dictionary)[&"bag"] as Object).call("reward_arrived")


static func _coins_arrived() -> void:
	var hud := _hud()
	if hud:
		hud.call("flash_coins")


## Quantas moedinhas voam para esse valor (1 a 5).
static func coin_count(total: int) -> int:
	return clampi(1 + total / 30, 1, 5)


## Mensagem pequena que sobe e some, centrada acima de `anchor` (retângulo global), contida na tela.
static func message(text: String, anchor: Rect2) -> Label:
	var label := MissionUi.text(text, 16, Palette.GO_INK, 0)  # verde escuro sobre o papel creme: legível e discreto
	label.name = "MarketMessage"
	var parent := layer()
	parent.add_child(label)
	var width := label.get_minimum_size().x
	var area := parent.get_viewport_rect().size
	var x := clampf(anchor.get_center().x - width / 2.0, 6.0, maxf(6.0, area.x - width - 6.0))
	var y := maxf(MIN_TOP, anchor.position.y - 26.0)
	label.position = Vector2(x, y)
	var tween := label.create_tween()
	if Motion.reduced:
		tween.tween_interval(TEXT_LIFE)
	else:
		label.modulate.a = 0.0
		tween.tween_property(label, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(label, "position:y", y - RISE, TEXT_LIFE).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3).set_delay(TEXT_LIFE - 0.3)
	tween.tween_callback(label.queue_free)
	return label


## Um ícone que voa em arco de `from` até `to` (globais), encolhendo; `arrive` roda na chegada.
static func _fly(texture: Texture2D, px: int, from: Vector2, to: Vector2, delay: float, arrive: Callable) -> void:
	if Motion.reduced or texture == null:
		return
	var token := UiKit.icon(texture, px)
	token.name = "MarketToken"
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.modulate.a = 0.0
	layer().add_child(token)
	var half := Vector2(px, px) / 2.0
	token.pivot_offset = half
	var tween := token.create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		token.modulate.a = 1.0
		token.scale = Vector2.ONE
		var flight := Motion.fly_arc(token, from - half, to - half, Motion.FLY)
		flight.parallel().tween_property(token, "scale", Vector2.ONE * 0.45, Motion.FLY)
		flight.tween_callback(func() -> void:
			if arrive.is_valid():
				arrive.call()
			token.queue_free()))


## `note_at` = retângulo global da tábua: a mensagem nasce logo acima dela, sem cobrir os controles.
## Venda: o item sai do cartão em direção ao vendedor (o botão), e as moedas voam do botão até o HUD.
static func sold(item: String, qty: int, total: int, card_center: Vector2, button_center: Vector2, note_at: Rect2) -> void:
	Haptics.success()
	message("Vendeu %s%s" % [Database.item_name(item), " ×%d" % qty if qty > 1 else ""], note_at)
	if Motion.reduced:
		return
	_fly(Database.item_icon(item), ICON_PX, card_center, button_center, 0.0, Callable())
	var coin := UiKit.ui_icon("coin")
	var count := coin_count(total)
	for i in count:
		_fly(coin, COIN_PX, button_center, _coins_point(), 0.2 + i * 0.07, _coins_arrived if i == count - 1 else Callable())


## Compra: moedas saem do HUD até o cartão e o item voa do cartão até a aba Mochila.
static func bought(texture: Texture2D, label: String, cost: int, card_center: Vector2, note_at: Rect2) -> void:
	Haptics.success()
	message("Comprou " + label, note_at)
	if Motion.reduced:
		return
	_coins_arrived()
	var coin := UiKit.ui_icon("coin")
	var count := coin_count(cost)
	for i in count:
		_fly(coin, COIN_PX, _coins_point(), card_center, i * 0.07, Callable())
	var bag := bag_point()
	if texture != null:
		_fly(texture, ICON_PX, card_center, bag if bag.x >= 0.0 else card_center + Vector2(0.0, -120.0), 0.2, _bag_arrived if bag.x >= 0.0 else Callable())
