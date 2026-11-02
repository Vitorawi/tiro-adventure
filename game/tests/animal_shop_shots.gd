extends SceneTree
## Capturas e MEDIDAS da loja de animais "madeira ilustrada" (galinheiro e curral). NÃO é teste da suíte, mas imprime FAIL e
## sai com código 1 se a geometria sair torta. Rodar SEM --headless, na resolução desejada:
##   & $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/animal_shop_shots.gd -- --out=animal_shop_wood
## PNGs em build/screenshots/<out>/animals_<largura>x<altura>_<tela>.png. Não grava o save pessoal.

const CREME_L := 37.6   # madeira da esquerda até o papel, em px de exibição de uma moldura de 372
const CREME_R := 34.4
const PLAQUE_CENTER := (83.9 + 294.2) / 2.0

var state: Node
var main: Control
var sheet: Control
var folder := "res://../build/screenshots/animal_shop_wood/"
var failures := 0


func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			folder = "res://../build/screenshots/%s/" % arg.trim_prefix("--out=")
	_run.call_deferred()
	create_timer(600).timeout.connect(func() -> void: quit(1))


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("  FAIL: ", message)


func _hide_modals() -> void:
	for member: String in ["_celebration", "_welcome", "_walk_result", "_growth_ceremony", "_quest_reward"]:
		var node: Variant = main.get(member)
		if node is CanvasLayer:
			(node as CanvasLayer).hide()
	var intro: Variant = main.get("_intro")
	if is_instance_valid(intro) and (intro as Node).is_inside_tree():
		(intro as Node).queue_free()
	main.set("_modal_queue", [] as Array[Callable])
	for hidden_name: String in ["Notice", "Toast", "MomentNotice"]:
		var extra := main.find_child(hidden_name, true, false) as CanvasItem
		if extra:
			extra.hide()


func _unlock() -> void:
	state.call("reset")
	state.get("progress").seen["intro"] = true
	state.call("dev_unlock_everything")
	state.call("_mark_all_seen")
	state.get("animals").clear()
	state.set("coins", 5000)
	await create_timer(1.2).timeout
	_hide_modals()


func _near(a: float, b: float, tolerance: float) -> bool:
	return absf(a - b) <= tolerance


func _text_fits(label: Label, name_: String, tag: String) -> void:
	if label == null:
		return
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	var rect := label.get_global_rect()
	if not label.clip_text and label.autowrap_mode == TextServer.AUTOWRAP_OFF:
		var width := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_check(width <= rect.size.x + 0.5, "[%s] %s passa da sua caixa (%.1f > %.1f): %s" % [tag, name_, width, rect.size.x, label.text])
	elif label.autowrap_mode != TextServer.AUTOWRAP_OFF:
		_check(label.get_line_count() <= 2 and label.get_visible_line_count() >= label.get_line_count(), "[%s] %s cortado (%d linhas): %s" % [tag, name_, label.get_line_count(), label.text])


func _transforms() -> Dictionary:
	var result := {}
	for node in sheet.find_children("*", "Control", true, false):
		var control := node as Control
		if control.is_visible_in_tree():
			result[str(control.get_path())] = [control.scale, control.size, control.get_global_rect().position]
	return result


func _open(shot_name: String, station: String = "chicken_coop") -> void:
	root.get_node("Events").sheet_requested.emit("Comprar animais", (load("res://scripts/ui/animal_shop_ui.gd") as Script).call("build", station))
	await create_timer(1.0).timeout
	_hide_modals()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(path)
	var image := root.get_texture().get_image()
	image.save_png(path + "animals_%dx%d_%s.png" % [image.get_width(), image.get_height(), shot_name])
	var before := _transforms()
	for i in 60:
		await process_frame
	var after := _transforms()
	for key: String in before:
		if after.has(key):
			_check(before[key][0] == after[key][0], "[%s] escala mudou em %s" % [shot_name, key])
			_check((before[key][1] as Vector2).is_equal_approx(after[key][1]), "[%s] tamanho mudou em %s" % [shot_name, key])
	_measure(shot_name)


func _map_x(x: float, width: float) -> float:
	var script := load("res://scripts/ui/animal_shop_ui.gd") as Script
	return float(script.call("map_x", x, width))


func _measure(tag: String) -> void:
	var screen := root.get_visible_rect().size
	var frame := sheet.find_child("AnimalFrame", true, false) as Control
	if frame == null:
		_check(false, "[%s] sem AnimalFrame" % tag)
		return
	var fr := frame.get_global_rect()
	_check(fr.position.x >= 0.0 and fr.end.x <= screen.x, "[%s] moldura fora da tela %s" % [tag, fr])
	_check(_near(fr.get_center().x, screen.x / 2.0, 1.0), "[%s] moldura não centralizada" % tag)
	_check(_near(fr.position.x, screen.x - fr.end.x, 1.0), "[%s] folgas da moldura diferentes %.1f / %.1f" % [tag, fr.position.x, screen.x - fr.end.x])
	var info := "[%s] tela %dx%d moldura %s" % [tag, screen.x, screen.y, fr]
	# Título centrado na plaquinha.
	var title := sheet.find_child("AnimalTitle", true, false) as Label
	var plaque_center := fr.position.x + (_map_x(83.9, fr.size.x) + _map_x(294.2, fr.size.x)) / 2.0
	_check(_near(title.get_global_rect().get_center().x, plaque_center, 1.0), "[%s] título fora do centro da plaquinha (%.1f x %.1f)" % [tag, title.get_global_rect().get_center().x, plaque_center])
	_check(title.get_global_rect().position.x >= fr.position.x + _map_x(83.9, fr.size.x) - 0.5 and title.get_global_rect().end.x <= fr.position.x + _map_x(294.2, fr.size.x) + 0.5, "[%s] título passa da plaquinha" % tag)
	_text_fits(title, "AnimalTitle", tag)
	var title_font := title.get_theme_font("font")
	var title_w := title_font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
	var text_l := title.get_global_rect().get_center().x - title_w / 2.0
	var text_r := title.get_global_rect().get_center().x + title_w / 2.0
	var screw_l := fr.position.x + _map_x(102.3, fr.size.x)
	var screw_r := fr.position.x + _map_x(275.8, fr.size.x)
	_check(text_l - screw_l >= 6.0 and screw_r - text_r >= 6.0, "[%s] título perto dos parafusos: folga %.1f / %.1f (mín. 6)" % [tag, text_l - screw_l, screw_r - text_r])
	# Barra de capacidade: texto dentro da faixa e preenchimento dentro dela.
	var capacity := sheet.find_child("CapacityLabel", true, false) as Label
	var lane := Rect2(fr.position.x + 49.5, fr.position.y + 108.9, _map_x(304.5, fr.size.x) - 49.5, 22.9)
	_check(lane.grow(0.5).encloses(capacity.get_global_rect()), "[%s] texto da barra fora da faixa %s %s" % [tag, capacity.get_global_rect(), lane])
	_text_fits(capacity, "CapacityLabel", tag)
	var fill := sheet.find_child("CapacityFill", true, false) as Control
	if fill and fill.visible:
		_check(lane.grow(0.5).encloses(fill.get_global_rect()), "[%s] preenchimento fora da faixa" % tag)
	# Grade e cartões.
	var grid := sheet.find_child("AnimalGrid", true, false) as Control
	var cards: Array[Control] = []
	for child in grid.get_children():
		if str(child.name).begins_with("AnimalCard_"):
			cards.append(child as Control)
	var first := cards[0]
	var fr0 := first.get_global_rect()
	var columns := {}
	var pill_w := -1.0
	var pill_dx := -1.0
	var name_dx := -1.0
	for card in cards:
		var rect := card.get_global_rect()
		columns[snappedf(rect.position.x, 0.5)] = true
		_check(_near(card.size.x, first.size.x, 1.0) and _near(card.size.y, first.size.y, 1.0), "[%s] cartão de tamanho diferente %s" % [tag, card.name])
		var disc := card.find_child("Disc", true, false) as Control
		_check(_near(disc.get_global_rect().get_center().y, rect.get_center().y, 1.0), "[%s] disco fora do centro vertical em %s" % [tag, card.name])
		_check(disc.get_global_rect().position.x - rect.position.x >= 3.5, "[%s] disco sem folga em %s" % [tag, card.name])
		var figure := disc.find_child("Figure", true, false) as Control
		_check_figure(figure, disc, tag, card.name)
		var name_label := card.find_child("AnimalName", true, false) as Label
		var pill := card.find_child("PricePill", true, false) as Control
		if pill == null:
			pill = card.find_child("LockPill", true, false) as Control
		_check(_near(name_label.get_global_rect().position.x, pill.get_global_rect().position.x, 1.0), "[%s] nome e pílula em bordas diferentes em %s" % [tag, card.name])
		_check(not name_label.get_global_rect().intersects(pill.get_global_rect()), "[%s] nome sobre a pílula em %s" % [tag, card.name])
		_check(card.get_global_rect().grow(0.5).encloses(pill.get_global_rect()) and card.get_global_rect().grow(0.5).encloses(name_label.get_global_rect()), "[%s] conteúdo fora do cartão %s" % [tag, card.name])
		_check(pill.get_global_rect().end.x <= rect.end.x - 3.5, "[%s] pílula sem folga à direita em %s" % [tag, card.name])
		var dx := pill.get_global_rect().position.x - rect.position.x
		if pill_w < 0.0:
			pill_w = pill.size.x
			pill_dx = dx
			name_dx = name_label.get_global_rect().position.x - rect.position.x
		_check(_near(pill.size.x, pill_w, 0.5) and _near(dx, pill_dx, 1.0), "[%s] pílula com largura/borda diferente em %s" % [tag, card.name])
		_check(_near(name_label.get_global_rect().position.x - rect.position.x, name_dx, 1.0), "[%s] nome fora da coluna em %s" % [tag, card.name])
		_check(name_label.get_visible_line_count() <= 2, "[%s] nome com mais de 2 linhas" % tag)
		_text_fits(card.find_child("Price", true, false) as Label, "Price", tag)
		_text_fits(card.find_child("LockText", true, false) as Label, "LockText", tag)
		var owned := card.find_child("Owned", true, false) as Control
		if owned:
			_check(disc.get_global_rect().grow(1.0).encloses(owned.get_global_rect()), "[%s] selo ×N fora do disco em %s" % [tag, card.name])
			_text_fits(owned.find_child("*", true, false) as Label, "Owned", tag)
		var action := card.find_child("Buy_*", true, false) as Control
		if action == null:
			action = card.find_child("Locked_Buy_*", true, false) as Control
		_check(action != null, "[%s] sem Buy_ nem Locked_Buy_ em %s" % [tag, card.name])
		if action:
			_check(action.size.x >= 43.5 and action.size.y >= 43.5, "[%s] alvo de toque menor que 44 em %s" % [tag, card.name])
	_check(columns.size() <= 2, "[%s] mais de 2 colunas: %s" % [tag, columns.keys()])
	var last_right := -1.0
	for card in cards:
		last_right = maxf(last_right, card.get_global_rect().end.x)
	var gap_l := fr0.position.x - fr.position.x - CREME_L
	var gap_r := fr.end.x - CREME_R - last_right
	var gutter := sheet.find_child("ScrollGutter", true, false) as Control
	if cards.size() >= 2 and not (gutter != null and gutter.visible):
		_check(_near(gap_l, gap_r, 1.5), "[%s] folga até o papel: esquerda %.1f != direita %.1f" % [tag, gap_l, gap_r])
		var h_gap := cards[1].get_global_rect().position.x - fr0.end.x
		_check(_near(h_gap, 8.0, 0.5), "[%s] espaço entre colunas %.1f" % [tag, h_gap])
	if cards.size() >= 3:
		_check(_near(cards[2].get_global_rect().position.y - fr0.end.y, 8.0, 0.5), "[%s] espaço entre linhas diferente de 8" % tag)
	# Tábua e botão.
	var board := sheet.find_child("AnimalBoard", true, false) as Control
	var br := board.get_global_rect()
	_check(_near(br.get_center().x, fr.get_center().x, 1.0), "[%s] tábua não centralizada" % tag)
	_check(br.end.y <= screen.y + 0.5, "[%s] tábua passa do fim da tela (%.1f > %.1f)" % [tag, br.end.y, screen.y])
	_check(br.position.y >= fr.end.y, "[%s] tábua dentro da moldura" % tag)
	_check(_near(br.size.x, fr.size.x, 1.0), "[%s] tábua com largura diferente da moldura (%.1f x %.1f)" % [tag, br.size.x, fr.size.x])
	var tabs := main.find_child("TabBar", true, false) as Control
	if tabs and tabs.is_visible_in_tree():
		_check(br.end.y <= tabs.get_global_rect().position.y + 0.5, "[%s] tábua sobre a barra de abas (%.1f > %.1f)" % [tag, br.end.y, tabs.get_global_rect().position.y])
		_check(fr.end.y <= tabs.get_global_rect().position.y, "[%s] moldura sobre a barra de abas" % tag)
	var view := sheet.find_child("ViewAnimals", true, false) as Control
	var vr := view.get_global_rect()
	_check(_near(vr.get_center().x, br.get_center().x, 1.0) and _near(vr.get_center().y, br.get_center().y, 1.0), "[%s] botão fora do centro da tábua" % tag)
	_check(vr.size.x >= 43.5 and vr.size.y >= 43.5, "[%s] botão menor que 44" % tag)
	_text_fits(view.find_child("ViewAnimalsLabel", true, false) as Label, "ViewAnimalsLabel", tag)
	_check(vr.position.x - br.position.x - 99.7 >= 8.0, "[%s] botão a menos de 8 px do ninho (%.1f)" % [tag, vr.position.x - br.position.x - 99.7])
	_check(br.end.x - vr.end.x - 79.1 >= 8.0, "[%s] botão a menos de 8 px da casinha da direita (%.1f)" % [tag, br.end.x - vr.end.x - 79.1])
	var close := frame.find_child("CloseButton", true, false) as Control
	_check(close.get_global_rect().size.x >= 43.5 and close.get_global_rect().size.y >= 43.5, "[%s] X menor que 44" % tag)
	_check(frame.get_global_rect().grow(0.5).encloses(close.get_global_rect()), "[%s] X fora da moldura" % tag)
	print(info, " cartões %d tamanho %s tábua %s" % [cards.size(), first.size, br])


func _close() -> void:
	root.get_node("Events").sheet_close_requested.emit()
	await create_timer(0.6).timeout


func _run() -> void:
	var saver: Node = root.get_node("SaveManager")
	root.get_node("Events").state_changed.disconnect(Callable(saver, "_schedule_save"))
	for child: Node in saver.get_children():
		if child is Timer:
			child.queue_free()
	saver.set("_save_path", (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "animals_descartavel.json"))
	state = root.get_node("GameState")
	Motion.reduced = false
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.5).timeout
	sheet = main.find_child("Sheet", true, false)
	_hide_modals()

	# a: galinheiro com moedas e espaço, ruiva/preta bloqueadas pelos ovos
	await _unlock()
	state.get("progress").stats["produce:egg"] = 3
	state.call("_changed")
	await _open("a_galinheiro")
	await _close()

	# b: curral
	await _unlock()
	state.get("progress").stats["produce:milk"] = 0
	state.call("_changed")
	await _open("b_curral", "cow_barn")
	await _close()

	# c: tudo liberado (ruiva e preta já valem)
	await _unlock()
	await _open("c_liberado")
	await _close()

	# d: sem moedas
	await _unlock()
	state.set("coins", 10)
	await _open("d_sem_moedas")
	await _close()

	# e: abrigo cheio
	await _unlock()
	state.get("animals")["chicken_white"] = 3
	state.call("_changed")
	await _open("e_cheio")
	await _close()

	# f: já tem vários (selo ×N) e sobra uma vaga
	await _unlock()
	state.get("animals")["chicken_white"] = 2
	state.call("_changed")
	await _open("f_tem_varios")
	await _close()

	# g: curral com vários e nome longo
	await _unlock()
	state.get("animals")["cow_white"] = 1
	state.get("animals")["cow_brown"] = 1
	var cfg: Dictionary = root.get_node("Database").get("animals")
	var old_name: String = cfg["chicken_white"]["name"]
	cfg["chicken_white"]["name"] = "Galinha branquinha da vovó"
	state.call("_changed")
	await _open("g_nome_longo")
	cfg["chicken_white"]["name"] = old_name
	await _close()

	# h: muitos animais (10): a grade rola, com a barra fina à direita
	await _unlock()
	var extra: Array[String] = []
	for i in 9:
		var copy: Dictionary = (cfg["chicken_white"] as Dictionary).duplicate(true)
		copy["name"] = "Galinha extra %d" % i
		cfg["extra_%d" % i] = copy
		extra.append("extra_%d" % i)
	state.call("_changed")
	await _open("h_muitos")
	for key in extra:
		cfg.erase(key)
	await _close()

	print("ANIMAL SHOP SHOTS: ", "OK" if failures == 0 else "%d FAIL" % failures)
	quit(0 if failures == 0 else 1)


## Pixels visíveis do sprite dentro do círculo do disco (folga >= 2 px) e retângulo visível centrado.
func _check_figure(figure: Control, disc: Control, tag: String, card_name: String) -> void:
	var texture := (figure as TextureRect).texture
	var image := texture.get_image()
	var used := image.get_used_rect()
	var f := figure.size.x / float(texture.get_width())
	var dr := disc.get_global_rect()
	var origin := figure.get_global_rect().position
	var visible := Rect2(origin + Vector2(used.position) * f, Vector2(used.size) * f)
	_check(_near(visible.get_center().x, dr.get_center().x, 1.0) and _near(visible.get_center().y, dr.get_center().y, 1.0), "[%s] animal visível fora do centro do disco em %s (%s x %s)" % [tag, card_name, visible.get_center(), dr.get_center()])
	var radius := dr.size.x / 2.0 - 2.0
	var worst := 0.0
	for y in range(used.position.y, used.end.y):
		for x in range(used.position.x, used.end.x):
			if image.get_pixel(x, y).a < 0.1:
				continue
			var near_corner := origin + Vector2(x, y) * f
			for corner in [Vector2.ZERO, Vector2(f, 0), Vector2(0, f), Vector2(f, f)]:
				worst = maxf(worst, (near_corner + corner - dr.get_center()).length())
	_check(worst <= radius + 0.01, "[%s] animal vaza do disco em %s (%.1f > raio %.1f, fator %.2f)" % [tag, card_name, worst, radius, f])
