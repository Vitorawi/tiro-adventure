extends SceneTree
## Interface 2, etapa 03: a central de avisos (`Notice`): um aviso por vez, erro > momento > foto > info,
## erro substitui o que está na tela, nada aparece com cartão aberto, e as ligações com `Events`.

var failures: int = 0
var state: Node
var main: Control
var notice: Object
var toast: Control
var text: Label


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("NOTICE: " + message)


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
	for i in 4:
		await process_frame
	notice = main.get("_notice")
	toast = main.get_node("Toast")
	text = main.find_child("ToastText", true, false)
	await _one_at_a_time()
	await _error_replaces()
	await _priority()
	await _modal_blocks()
	await _events()
	await _photo_tap()
	Motion.reduced = false
	print("NOTICE TEST: ", "PASS" if failures == 0 else "FAIL")
	quit(1 if failures else 0)


func _clear() -> void:
	notice.finish_current()
	while notice.queued() > 0 or notice.showing() != "":
		notice.finish_current()
	toast.hide()
	await process_frame


## 1. Dois avisos juntos: um por vez, o segundo depois do primeiro.
func _one_at_a_time() -> void:
	await _clear()
	notice.notify("info", "a")
	notice.notify("info", "b")
	await process_frame
	check(toast.visible and text.text == "a", "o primeiro aviso aparece (veio %s)" % text.text)
	check(notice.queued() == 1, "o segundo espera na fila")
	notice.finish_current()
	await process_frame
	check(toast.visible and text.text == "b", "o segundo aparece depois do primeiro (veio %s)" % text.text)
	await _clear()


## 2. Erro entra na hora no lugar do aviso comum.
func _error_replaces() -> void:
	await _clear()
	notice.notify("info", "a")
	await process_frame
	notice.notify("error", "x")
	await process_frame
	check(toast.visible and text.text == "x" and notice.showing() == "error", "o erro substitui o aviso na tela (veio %s)" % text.text)
	await _clear()


## 3. Momento antes de info quando os dois esperam.
func _priority() -> void:
	await _clear()
	notice.notify("info", "ocupado")
	await process_frame
	notice.notify("info", "depois")
	notice.notify("moment", "Momento de Coragem!", (load("res://scripts/ui/ui_kit.gd") as GDScript).call("ui_icon", "coin"))
	notice.finish_current()
	# Com Menos animação o momento dura zero: confere na hora, antes do próximo quadro.
	check(notice.showing() == "moment" and main.find_child("MomentText", true, false).text == "Momento de Coragem!", "o momento passa na frente do info que esperava")
	notice.finish_current()
	check(notice.showing() == "info" and text.text == "depois", "o info vem depois do momento")
	check(not (main.find_child("MomentNotice", true, false) as Control).visible, "momento e aviso nunca juntos")
	await _clear()


## 4. Com cartão aberto nada aparece; ao fechar a fila anda.
func _modal_blocks() -> void:
	await _clear()
	var celebration: CanvasLayer = main.get("_celebration")
	celebration.show()
	notice.notify("info", "espera o cartão")
	await process_frame
	await process_frame
	check(not toast.visible, "com um cartão aberto nada aparece")
	celebration.hide()
	await create_timer(0.3).timeout
	check(toast.visible and text.text == "espera o cartão", "ao fechar o cartão a fila anda")
	await _clear()


## 5. Ligações: `toast_requested` chega como info; `notice_requested` leva o ícone do item.
func _events() -> void:
	await _clear()
	root.get_node("Events").emit_signal("toast_requested", "oi")
	await process_frame
	check(toast.visible and text.text == "oi" and notice.showing() == "info", "toast_requested chega como info")
	await _clear()
	root.get_node("Events").emit_signal("notice_requested", "error", "Falta 1 cenoura", "carrot")
	await process_frame
	var icon := main.find_child("ToastIcon", true, false) as TextureRect
	check(notice.showing() == "error" and icon.visible and icon.texture == root.get_node("Database").item_icon("carrot"), "o erro mostra o ícone da cenoura")
	await _clear()


## 6. A foto é tocável e chama a abertura.
func _photo_tap() -> void:
	await _clear()
	var opened: Array = []
	notice.notify("photo", "Nova foto!", null, func() -> void: opened.append(true))
	await process_frame
	check(notice.showing() == "photo" and toast.mouse_filter == Control.MOUSE_FILTER_STOP, "o aviso de foto pega toque")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	toast.emit_signal("gui_input", click)
	await process_frame
	check(opened.size() == 1, "tocar chama a abertura da foto")
	check(not toast.visible, "o aviso some ao tocar")
	await _clear()
