extends SceneTree
## Fotos do Tiro, etapa 04: a carta grande em 3D (CardViewer). Abre/fecha, inclinação com mola, versões (tidas coloridas,
## faltantes escuras), Tentar a sorte, Melhorar, varal e um só botão verde.

var failures := 0
var state: Node
var viewer_script: GDScript
var toasts: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void:
		print("CARD VIEWER TEST: TEMPO ESGOTADO")
		quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Carta: " + message)


func _open(id: String) -> Control:
	var viewer: Control = viewer_script.call("open", id, {"host": root})
	await process_frame
	await process_frame
	return viewer


func _close_all() -> void:
	if viewer_script.call("is_open"):
		(viewer_script.get("current") as Control).call("close")
	await process_frame


func _tilt(viewer: Control) -> Vector2:
	return Vector2((viewer.call("surface_material") as ShaderMaterial).get_shader_parameter("tilt"))


func _greens(node: Node) -> int:
	var total := 0
	for button in node.find_children("*", "Button", true, false):
		if (button as Button).has_meta("wood_primary") and (button as Button).is_visible_in_tree():
			total += 1
	return total


func _give_cost(id: String) -> void:
	var cost: Dictionary = state.upgrade_cost(id)
	for item: String in cost.items:
		state.inventory.add(item, int(cost.items[item]))


func _fresh() -> void:
	state.reset()
	state.progress.seen["intro"] = true
	state.dev_reset_album()
	state.coins = 0


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	viewer_script = load("res://scripts/ui/card_viewer.gd")
	root.get_node("Events").toast_requested.connect(func(text: String) -> void: toasts.append(text))
	Motion.reduced = false

	# 1. Abre na versão mostrada; X e Escape fecham; só um aberto; o SubViewport só existe aberto
	_fresh()
	state.dev_take_photo("h_arrival", 3)
	state.dev_take_photo("f_bath", 1)
	var viewer: Control = await _open("h_arrival")
	check(viewer != null and viewer_script.call("is_open"), "abre o visualizador")
	check(int(viewer.get("level")) == 3, "mostra a versão escolhida (Rara)")
	var stage := viewer.find_child("CardStage", true, false) as SubViewport
	check(stage != null and stage.transparent_bg, "carta num SubViewport transparente")
	var frame := stage.find_child("CardFrame", true, false)
	check(frame != null and int(frame.get_meta("level")) == 3, "a carta do SubViewport tem a moldura do nível 3")
	check(viewer.find_child("CardFoil", true, false) != null, "nível 3 com o foil dentro da carta")
	check(viewer.find_child("CardSurface", true, false) != null, "tem o CardSurface")
	check(viewer.find_child("CardTitle", true, false) != null and viewer.find_child("RarityBadge", true, false) != null, "título e selo do nível")
	# Prêmios pendentes esperam a carta fechar; avisos da própria carta continuam disponíveis.
	var shell := load("res://scenes/main/main.gd").new() as Control
	var pending: Array[Callable] = [func() -> void: check(false, "modal não pode abrir sobre a carta")]
	shell.set("_modal_queue", pending)
	shell.call("_flush_modals")
	check((shell.get("_modal_queue") as Array).size() == 1, "fila modal espera o visualizador fechar")
	shell.free()
	var second: Control = await _open("f_bath")
	check(root.find_children("CardViewer", "", true, false).size() == 1 and second != viewer, "só um visualizador por vez")
	await _close_all()
	check(not viewer_script.call("is_open") and root.find_child("CardStage", true, false) == null, "fechar remove o visualizador e o SubViewport")
	viewer = await _open("h_arrival")
	(viewer.find_child("CloseViewer", true, false) as Button).pressed.emit()
	check(not viewer_script.call("is_open"), "o X fecha")
	viewer = await _open("h_arrival")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	viewer.call("_input", escape)
	check(not viewer_script.call("is_open"), "Escape fecha")
	viewer = await _open("h_arrival")
	var rect: Rect2 = viewer.call("card_rect")
	viewer.call("touch_down", Vector2(8, 8))
	viewer.call("touch_up", Vector2(8, 8))
	check(not viewer_script.call("is_open"), "toque fora da carta fecha")

	# 2. Inclinação: 120 px à direita inclina; soltar volta em ≤ 0,5 s; toque curto não inclina
	viewer = await _open("h_arrival")
	rect = viewer.call("card_rect")
	var center := rect.get_center()
	viewer.call("touch_down", center)
	viewer.call("touch_move", center + Vector2(5, 0))
	check(_tilt(viewer) == Vector2.ZERO, "toque curto (< 10 px) não inclina")
	viewer.call("touch_move", center + Vector2(120, 0))
	check(_tilt(viewer).x > 0.5, "arrasto de 120 px para a direita inclina (tilt.x > 0)")
	var foil := (stage_foil(viewer))
	check(foil != null and Vector2(foil.get_shader_parameter("tilt")).x > 0.5, "o foil recebe o mesmo tilt")
	check(viewer_script.call("is_open"), "arrastar a carta não fecha")
	viewer.call("touch_up", center + Vector2(120, 0))
	await create_timer(0.48).timeout
	check(absf(_tilt(viewer).x) < 0.02, "soltar volta ao centro em até 0,5 s")
	viewer.call("touch_down", center)
	viewer.call("touch_move", center + Vector2(0, -120))
	check(_tilt(viewer).y < -0.5, "arrasto vertical inclina em y")
	viewer.call("touch_up", center)
	await _close_all()

	# 2b. Menos animação: inclinação menor e sem mola
	Motion.reduced = true
	viewer = await _open("h_arrival")
	var material := viewer.call("surface_material") as ShaderMaterial
	check(float(material.get_shader_parameter("max_yaw")) <= 8.0, "Menos animação: inclinação máxima ±8°")
	rect = viewer.call("card_rect")
	viewer.call("touch_down", rect.get_center())
	viewer.call("touch_move", rect.get_center() + Vector2(120, 0))
	viewer.call("touch_up", rect.get_center() + Vector2(120, 0))
	check(_tilt(viewer) == Vector2.ZERO, "Menos animação: volta na hora, sem mola")
	await _close_all()
	Motion.reduced = false

	# 3. Versões: tidas coloridas, faltantes escuras; tocar numa tida troca; tocar numa faltante avisa
	_fresh()
	state.dev_take_photo("h_arrival", 1)
	state.dev_take_photo("h_arrival", 3)
	viewer = await _open("h_arrival")
	for version in [1, 2, 3, 4]:
		var tile := viewer.find_child("Version_%d" % version, true, false) as Button
		check(tile != null, "existe Version_%d" % version)
		if tile == null: continue
		var owned: bool = version in [1, 2, 3]
		check(bool(tile.get_meta("owned")) == owned, "Version_%d owned=%s" % [version, owned])
		var card := tile.find_child("PhotoCard", true, false) as Control
		check(owned == (card.modulate.r > 0.9), "Version_%d %s" % [version, "colorida" if owned else "escura"])
		check((tile.find_child("VersionLock", true, false) != null) == (not owned), "cadeado só nas faltantes (%d)" % version)
	toasts.clear()
	(viewer.find_child("Version_4", true, false) as Button).pressed.emit()
	check(toasts.size() == 1 and "sorte" in toasts[0], "faltante: aviso para tentar a sorte ou melhorar")
	check(int(viewer.get("level")) == 3, "faltante não troca a carta")
	(viewer.find_child("Version_1", true, false) as Button).pressed.emit()
	check(state.photo_shown_rarity("h_arrival") == 1, "tocar numa tida chama set_photo_variant")
	await create_timer(0.5).timeout
	check(int(viewer.get("level")) == 1, "a carta grande trocou de versão")
	var swapped := (viewer.find_child("CardStage", true, false) as Node).find_child("CardFrame", true, false)
	check(swapped != null and int(swapped.get_meta("level")) == 1, "a textura da carta é da versão 1")
	check((viewer.find_child("Version_1", true, false).find_child("Selected", true, false)) != null, "a versão exibida fica marcada")
	await _close_all()

	# 4. Tentar a sorte: com moedas consome e sorteia; sem moedas, bloqueado com a moeda
	_fresh()
	state.dev_take_photo("h_arrival", 1)
	state.coins = 500
	viewer = await _open("h_arrival")
	var reroll := viewer.find_child("RerollButton", true, false) as Button
	check(reroll != null and viewer.find_child("Locked_RerollButton", true, false) == null, "com moedas: botão Tentar a sorte")
	var before: int = state.coins
	var cost := int(state.reroll_cost("h_arrival").coins)
	var stage_id := viewer.find_child("CardStage", true, false).get_instance_id()
	state.coins += 1
	state.call("_changed")
	await process_frame
	check(viewer.find_child("CardStage", true, false).get_instance_id() == stage_id, "state_changed mantém a carta e só atualiza os controles")
	state.coins = before
	reroll.pressed.emit()
	await process_frame
	check(state.coins == before - cost and int(state.album.photos["h_arrival"].rerolls) == 1, "Tentar a sorte cobrou as moedas e sorteou")
	await create_timer(1.7).timeout
	state.coins = 0
	state.call("_changed")
	await process_frame
	await process_frame
	var locked := viewer.find_child("Locked_RerollButton", true, false) as Button
	check(locked != null and viewer.find_child("RerollButton", true, false) == null, "sem moedas: Locked_RerollButton")
	check(locked != null and locked.find_child("LockRequirement", true, false) != null, "o bloqueio mostra a moeda")
	await _close_all()

	# 5. Melhorar: sobe 1 nível; falta material → bloqueio com o ícone; nível 4 some
	_fresh()
	state.dev_take_photo("h_arrival", 1)
	state.coins = 1000
	viewer = await _open("h_arrival")
	var locked_up := viewer.find_child("Locked_UpgradeButton", true, false) as Button
	check(locked_up != null and viewer.find_child("UpgradeButton", true, false) == null, "falta material: Locked_UpgradeButton")
	check(locked_up != null and locked_up.find_child("LockRequirement", true, false) != null, "o bloqueio mostra o ícone do que falta")
	_give_cost("h_arrival")
	state.coins = 1000
	state.call("_changed")
	await process_frame
	await process_frame
	var upgrade := viewer.find_child("UpgradeButton", true, false) as Button
	check(upgrade != null and viewer.find_child("Locked_UpgradeButton", true, false) == null, "com materiais: UpgradeButton")
	check(_greens(viewer) == 1, "exatamente um botão verde visível (%d)" % _greens(viewer))
	upgrade.pressed.emit()
	await create_timer(0.5).timeout
	check(state.photo_rarity("h_arrival") == 2 and 2 in state.photo_variants("h_arrival"), "Melhorar subiu exatamente um nível")
	check(int(viewer.get("level")) == 2, "a carta mostra a versão melhorada")
	await _close_all()
	_fresh()
	state.dev_take_photo("h_arrival", 4)
	viewer = await _open("h_arrival")
	check(viewer.find_child("UpgradeButton", true, false) == null and viewer.find_child("Locked_UpgradeButton", true, false) == null, "nível 4: Melhorar some")
	check(viewer.find_child("CollectionComplete", true, false) != null, "nível 4 destrava as versões abaixo: coleção completa")
	await _close_all()
	_fresh()
	for level in [1, 2, 3, 4]:
		state.dev_take_photo("h_arrival", level)
	viewer = await _open("h_arrival")
	check(viewer.find_child("CollectionComplete", true, false) != null, "4 versões: medalhão Coleção completa")
	check(viewer.find_child("RerollButton", true, false) == null and viewer.find_child("Locked_RerollButton", true, false) == null and viewer.find_child("UpgradeButton", true, false) == null, "coleção completa: sem Tentar a sorte nem Melhorar")
	await _close_all()

	# 6. Varal: pôr/tirar; cheio abre a escolha
	_fresh()
	state.dev_take_photo("h_arrival", 1)
	viewer = await _open("h_arrival")
	var feature := viewer.find_child("FeatureButton", true, false) as Button
	check(feature != null and feature.text == "Pôr no varal", "botão Pôr no varal")
	feature.pressed.emit()
	await process_frame
	check("h_arrival" in state.album.featured, "pôs no varal")
	feature = viewer.find_child("FeatureButton", true, false) as Button
	check(feature != null and feature.text == "Tirar do varal", "agora diz Tirar do varal")
	feature.pressed.emit()
	await process_frame
	check("h_arrival" not in state.album.featured, "tirou do varal")
	await _close_all()
	_fresh()
	var others: Array[String] = ["f_bath", "h_kitchen", "h_growth_adult"]
	for other in others:
		state.dev_take_photo(other, 1)
		state.feature_photo(other)
	state.dev_take_photo("h_arrival", 1)
	viewer = await _open("h_arrival")
	(viewer.find_child("FeatureButton", true, false) as Button).pressed.emit()
	await process_frame
	var choice := viewer.find_child("FeatureChoice", true, false)
	check(choice != null and choice.find_children("Swap_*", "Button", true, false).size() == 3, "varal cheio: escolha com 3 miniaturas")
	(viewer.find_child("Swap_f_bath", true, false) as Button).pressed.emit()
	await process_frame
	check("h_arrival" in state.album.featured and "f_bath" not in state.album.featured and state.album.featured.size() == 3, "trocou a escolhida no varal")
	await _close_all()

	# 7. Antes e depois (h_growth_adult compara com outra foto)
	_fresh()
	var compare := str(root.get_node("Database").photo("h_growth_adult").get("photo", {}).get("compare", ""))
	if compare != "":
		state.dev_take_photo(compare, 1)
	state.dev_take_photo("h_growth_adult", 1)
	viewer = await _open("h_growth_adult")
	check((viewer.find_child("CompareButton", true, false) != null) == (compare != ""), "Antes e depois só quando a outra foto existe")
	if compare != "":
		(viewer.find_child("CompareButton", true, false) as Button).pressed.emit()
		await process_frame
		check(viewer.find_child("BeforePhoto", true, false) != null, "mostra o antes")
	await _close_all()

	# Ajuda por cima da carta: Escape não fecha o visualizador; Ir sai dele.
	viewer = await _open("h_arrival")
	viewer.set("z_index", 9)
	viewer.call("_input", escape)
	check(viewer_script.call("is_open"), "Escape na ajuda não fecha a carta que está atrás")
	root.get_node("Events").sheet_closed.emit()
	check(viewer.z_index == 11, "fechar ajuda restaura a camada da carta")
	root.get_node("Events").world_requested.emit("farm", "")
	check(not viewer_script.call("is_open"), "Ir da ajuda fecha a carta e libera o destino")
	await process_frame

	print("CARD VIEWER TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)


func stage_foil(viewer: Control) -> ShaderMaterial:
	var foil := viewer.find_child("CardFoil", true, false) as Control
	return foil.material as ShaderMaterial if foil != null else null
