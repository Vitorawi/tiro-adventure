extends SceneTree
## Etapa 03 da interface nova (refeita na Interface 2, etapa 03): HUD flutuante de duas linhas (avatar com anel mel,
## perfil, moedas, engrenagem, DEV), abas com almofada e nome, balão do nível (Popover) e aviso (toast) abaixo da linha 2.
## Sem `Motion.reduced` os tempos seriam de animação; aqui ele fica ligado para os números chegarem na hora.

var failures: int = 0
var state: Node
var main: Control


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("HUD: " + message)


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.remove_child(saver)
	saver.free()
	state = root.get_node("GameState")
	state.call("reset")
	state.get("progress").seen["intro"] = true
	Motion.reduced = true
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	for i in 3:
		await process_frame
	await _structure()
	await _numbers()
	await _toast()
	await _tabs()
	await _tab_bounces()
	await _popover()
	await _coin_flight()
	Motion.reduced = false
	print("HUD TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _structure() -> void:
	var top: Node = main.find_child("TopBar", true, false)
	check(top != null and top.get_parent() == main, "o TopBar é filho direto da casca, fora do Layout")
	check(main.get_node("Layout").find_child("TopBar", true, false) == null, "nada chamado TopBar dentro do Layout")
	check((top as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE, "o fundo do HUD não pega toque")
	check(top.get_index() > main.get_node("Layout").get_index() and top.get_index() < main.get_node("Sheet").get_index(), "HUD fica depois do Layout e antes do Sheet")
	for node_name: String in ["LevelLabel", "XpBar", "CoinsLabel", "DevButton", "SettingsButton", "HudAvatar"]:
		check(main.find_child(node_name, true, false) != null, node_name + " existe")
	check(main.find_child("VersionLabel", true, false) == null, "a versão saiu do HUD")
	check(main.find_child("DevButton", true, false).visible == load("res://scripts/util/build_info.gd").call("is_dev"), "DEV só aparece na versão dev")
	check(not (main.find_child("XpBar", true, false) as Control).visible, "XpBar fica invisível (só compatibilidade)")
	# Telas sem mundo não ficam embaixo do HUD (60 px).
	for pair: Array in [["PetScreen", "Margin"], ["TasksScreen", "Margin"], ["BagScreen", "Margin"]]:
		var margin := main.find_child(pair[0], true, false).find_child(pair[1], true, false) as MarginContainer
		check(margin != null and margin.get_theme_constant("margin_top") >= 136, "%s deixa 136 px para as duas linhas do HUD" % pair[0])
		check(margin.get_theme_constant("margin_bottom") >= 96, "%s deixa 96 px para o rodapé" % pair[0])
	# Pílula de moedas com 40 px de altura; engrenagem com disco 40 e ALVO de 44.
	check(main.find_child("CoinsPill", true, false).size.y >= 40.0, "pílula de moedas tem 40 px")
	var gear := main.find_child("SettingsButton", true, false) as Control
	check(gear.size.x >= 44.0 and gear.size.y >= 44.0, "engrenagem com alvo de toque de 44 px")
	check(is_equal_approx((gear.find_child("Disc", true, false) as Control).size.x, 40.0), "disco da engrenagem de 40 px")
	check(is_equal_approx((top as Control).size.y, 168.0), "o HUD tem 168 px de altura (duas linhas de madeira)")
	var row2 := main.find_child("HudRow2", true, false) as Control
	check(row2 != null and is_equal_approx(row2.size.y, 65.0) and is_equal_approx(row2.position.y, 100.0), "linha 2: 65 px de altura a 100 do topo")
	check(main.find_child("HudProfile", true, false) != null and main.find_child("NextStep", true, false) != null, "perfil e próximo passo existem")


func _numbers() -> void:
	var level_label: Label = main.find_child("LevelLabel", true, false)
	check(level_label.text == "•", "LevelLabel mostra Recém-chegado")
	var coins_label: Label = main.find_child("CoinsLabel", true, false)
	var before: int = state.get("coins")
	state.set("coins", before + 50)
	root.get_node("Events").emit_signal("state_changed")
	await process_frame
	check(coins_label.text == str(before + 50), "ganhar 50 moedas: o número termina em %d (veio %s)" % [before + 50, coins_label.text])
	state.set("coins", before)
	root.get_node("Events").emit_signal("state_changed")
	await process_frame
	check(coins_label.text == str(before), "gastar volta o número")
	# O anel acompanha o XP.
	state.set("xp", int(state.call("xp_to_next_level")) / 2)
	root.get_node("Events").emit_signal("state_changed")
	await process_frame
	var ring: RingProgress = main.find_child("XpRing", true, false)
	check(is_equal_approx(ring.progress, 1.0 - float(load("res://scripts/ui/growth_ui.gd").call("missing", state.call("growth_info"))) / state.call("growth_info").requirements.size()), "anel acompanha requisitos e ignora XP (veio %f)" % ring.progress)


func _toast() -> void:
	var toast: Control = main.get_node("Toast")
	var text: Label = main.find_child("ToastText", true, false)
	var notice: Object = main.get("_notice")
	root.get_node("Events").emit_signal("toast_requested", "Primeiro aviso")
	root.get_node("Events").emit_signal("toast_requested", "Segundo aviso")
	await process_frame
	check(toast.visible and text.text == "Primeiro aviso", "dois avisos seguidos: um por vez, o primeiro primeiro")
	notice.finish_current()
	await process_frame
	check(toast.visible and text.text == "Segundo aviso", "o segundo aparece depois do primeiro")
	check(not main.find_child("ToastIcon", true, false).visible, "aviso comum sem ícone")
	check(toast.position.y >= 136.0 and toast.position.y < 200.0, "aviso fica logo abaixo da linha 2 do HUD (y = %f)" % toast.position.y)
	check(toast.size.x <= 320.0, "aviso com até 320 px de largura")
	var middle := toast.position.x + toast.size.x / 2.0
	check(absf(middle - main.size.x / 2.0) < 2.0, "aviso centralizado")
	notice.finish_current()
	root.get_node("Events").emit_signal("toast_requested", "Missão concluída! Próximo: um texto bem comprido para quebrar em duas linhas no celular")
	await process_frame
	check(main.find_child("ToastIcon", true, false).visible, "Missão concluída leva o ícone de check")
	check(toast.size.x <= 320.0 and toast.size.y <= 90.0, "aviso comprido quebra em até duas linhas (%s)" % str(toast.size))
	notice.finish_current()
	toast.hide()


func _tabs() -> void:
	for tab_name: String in ["PetTab", "MapTab", "TasksTab"]:
		check(main.find_child(tab_name, true, false).find_child("Face", false, false) != null, tab_name + " tem rosto novo")
	main.call("show_screen", &"map")
	await process_frame
	var map_face: NavTab = main.find_child("MapTab", true, false).find_child("Face", false, false)
	var pet_face: NavTab = main.find_child("PetTab", true, false).find_child("Face", false, false)
	check(map_face.is_active() and not pet_face.is_active(), "só a aba do Mapa fica ativa")
	check(map_face.cushion_color().a == 1.0, "aba ativa marcada")
	check(pet_face.cushion_color().a == 0.0, "almofada de aba comum fica sem fundo")
	check(is_equal_approx(pet_face.lift_node().position.y - map_face.lift_node().position.y, NavTab.LIFT), "a aba ativa sobe %d px, as outras ficam no lugar" % NavTab.LIFT)
	check(map_face.lift_node().size.is_equal_approx(NavTab.CUSHION), "encaixe de 72×72")
	check(map_face.find_child("Cushion", true, false) == map_face.lift_node(), "lift_node é a almofada")
	main.call("show_screen", &"pet")
	await process_frame
	check(pet_face.is_active() and not map_face.is_active(), "voltar ao Tiro troca a aba ativa")
	# Selo da aba Missões fica perto do ícone (centro + (22, −16)).
	var badge: Control = main.find_child("TasksTab", true, false).get_child(-1)
	check(badge is Label or main.find_child("TasksTab", true, false).get_child_count() >= 2, "selo mora na aba")


## Animação real: o bug só aparece com novos toques antes de terminar o pulinho.
func _tab_bounces() -> void:
	Motion.reduced = false
	for i in 24:
		var tab_name: String = ["MapTab", "MapTab", "TasksTab", "PetTab"][i % 4]
		(main.find_child(tab_name, true, false) as Button).pressed.emit()
		await create_timer(0.03).timeout
	main.call("show_screen", &"pet")
	await create_timer(0.6).timeout
	for tab_name: String in ["PetTab", "MapTab", "TasksTab", "BagTab"]:
		var face: NavTab = main.find_child(tab_name, true, false).find_child("Face", false, false)
		check(is_equal_approx(face.icon_node().position.y, NavTab.ICON_CENTER_Y - NavTab.ICON / 2.0), tab_name + ": pulinhos repetidos não acumulam altura")
		check(is_equal_approx(face.lift_node().position.y, face.rest_top() - (NavTab.LIFT if face.is_active() else 0.0)), tab_name + ": o encaixe só sobe na aba ativa, sem acumular")
	Motion.reduced = true


func _popover() -> void:
	var hud: Control = main.find_child("TopBar", true, false)
	hud.call("show_level_popover")
	await process_frame
	check(main.get_node_or_null("PopoverCatcher") != null, "tocar no avatar abre o balão do nível")
	var texts := PackedStringArray()
	for label: Node in main.get_node("PopoverCatcher").find_children("*", "Label", true, false):
		texts.append((label as Label).text)
	check(" ".join(texts).contains("Recém-chegado") and not " ".join(texts).contains("XP"), "balão mostra fase sem XP (%s)" % " | ".join(texts))
	# Tocar fora fecha.
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	main.get_node("PopoverCatcher").emit_signal("gui_input", click)
	await process_frame
	await process_frame
	check(main.get_node_or_null("PopoverCatcher") == null, "tocar fora fecha o balão")


func _coin_flight() -> void:
	var hud: Control = main.find_child("TopBar", true, false)
	var pill: Control = main.find_child("CoinsPill", true, false)
	check(pill.get_global_rect().has_point(hud.call("coins_target")), "as moedas do CollectFx voam para dentro da pílula")
	var count_before := main.get_children().size()
	root.get_node("Events").emit_signal("items_gained", {}, 5, Vector2(100.0, 400.0))
	await process_frame
	check(main.get_children().size() == count_before, "a animação nasce dentro do CollectFx, não solta na casca")
