class_name CardReveal
extends Node
## Encena resultados já decididos pelo motor. Vive no MESMO visualizador; fechar cancela os tweens.

var viewer: CardViewer
var animation: Tween
var busy := false
var opened := false
var _note_open := false
var seal: Control
var _white: ColorRect


static func open(id: String, options: Dictionary = {}) -> CardViewer:
	if GameState.photo_sealed(id) <= 0:
		return CardViewer.open(id, options)
	var config := options.duplicate()
	config["reveal"] = true
	var card := CardViewer.open(id, config)
	if card == null: return null
	var reveal := _for_viewer(card)
	reveal._closed_card()
	return card


static func _for_viewer(card: CardViewer) -> CardReveal:
	var reveal := card.get_node_or_null("CardReveal") as CardReveal
	if reveal == null:
		reveal = CardReveal.new()
		reveal.name = "CardReveal"
		reveal.viewer = card
		card.add_child(reveal)
	return reveal


static func play_result(id: String, result: Dictionary) -> void:
	if not CardViewer.is_open() or CardViewer.current.photo_id != id: return
	_for_viewer(CardViewer.current)._result(result.duplicate())


func _exit_tree() -> void:
	if animation != null: animation.kill()


func _prepare() -> void:
	viewer.revealing = true
	viewer._versions.hide()
	viewer._clear_actions()
	for child in viewer._info.get_children():
		viewer._info.remove_child(child)
		child.queue_free()


func _closed_card() -> void:
	_prepare()
	var title := StepCardUi.wood("Nova foto surpresa!", 22)
	title.name = "RevealTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	viewer._info.add_child(title)
	viewer._actions.add_child(WelcomeSheet._button("Abrir", true, 250.0, "OpenCard", _open_card))
	# Mantém espaço para as ações finais: a carta não salta na entrega.
	if not Motion.reduced:
		viewer._surface.position.y -= 24.0
		animation = create_tween()
		animation.tween_property(viewer._surface, "position:y", viewer._surface.position.y + 24.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _open_card() -> void:
	if busy or opened: return
	opened = true
	_note_open = true
	busy = true  # trava antes do sinal síncrono do motor; nunca abre duas vezes
	var error := GameState.open_photo_card(viewer.photo_id)
	if error != "":
		busy = false
		opened = false
		_note_open = false
		Events.toast_requested.emit(error)


func _face(level: int) -> void:
	viewer.showing_back = false
	viewer.level = level
	viewer._build_stage()


func _result(result: Dictionary) -> void:
	busy = true
	if animation != null: animation.kill()
	_prepare()
	var level := int(result.get("rolled", viewer.level))
	var duplicate := not bool(result.get("new_variant", false))
	var target := viewer.level if duplicate and viewer.level > 0 else level
	var action := str(result.get("action", result.get("kind", "")))
	seal = PhotoCard.rarity_badge(level, 26)
	seal.name = "RevealSeal"
	seal.set_meta("level", level)
	viewer._info.add_child(seal)
	var text := StepCardUi.wood("Você já tinha esta versão" if duplicate else str(PhotoCard.LEVEL_NAMES.get(level, "")) + "!", 19)
	text.name = "RevealResult"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	viewer._actions.add_child(text)
	if duplicate: Events.toast_requested.emit("Você já tinha esta versão")
	if Motion.reduced:
		_face(target)
		viewer._set_spin(0.0)
		_finish()
		return
	seal.modulate.a = 0.0
	text.modulate.a = 0.0
	animation = create_tween()
	if action == "upgrade":
		_face(target)
	else:
		# Tentar a sorte passa pelo verso, sem executar outro sorteio.
		if action == "reroll":
			animation.tween_method(viewer._set_spin, 0.0, 84.0, 0.15)
			animation.tween_callback(func() -> void:
				viewer.showing_back = true
				viewer._build_stage())
			animation.tween_method(viewer._set_spin, -84.0, 0.0, 0.15)
		animation.tween_method(viewer._set_spin, 0.0, 84.0, 0.2)
		animation.tween_callback(_face.bind(target))
		animation.tween_method(viewer._set_spin, -84.0, 0.0, 0.2)
	animation.tween_callback(_light.bind(level))
	animation.tween_property(seal, "modulate:a", 1.0, 0.12)
	animation.parallel().tween_property(text, "modulate:a", 1.0, 0.12)
	animation.tween_interval(0.6)
	animation.tween_callback(_finish)


func _light(level: int) -> void:
	_white = ColorRect.new()
	_white.name = "RevealLight"
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_white.color = Color.WHITE
	_white.position = viewer._slot.global_position - viewer.global_position
	_white.size = viewer._slot.size
	viewer.add_child(_white)
	var fade := create_tween()
	fade.tween_property(_white, "modulate:a", 0.0, 0.6)
	fade.tween_callback(_white.queue_free)
	Motion.bounce(seal)
	if level == 1: Motion.bounce(viewer._surface)
	if level == 2: _white.color = Color("fff2bd")
	if level >= 3:
		Haptics.big() if level == 4 else Haptics.success()
		# Reutiliza a festa do ModalCard, sem abrir outro modal.
		var party := ModalCard.new()
		party.name = "RevealParty"
		party.mouse_filter = Control.MOUSE_FILTER_IGNORE
		viewer.add_child(party)
		party.fire_confetti()
		party.confetti.amount = 40 if level == 4 else 16
		party.confetti.restart()
		var cleanup := party.create_tween()
		cleanup.tween_interval(1.8)
		cleanup.tween_callback(party.queue_free)
	if level == 4:
		_white.color = Color("e2d1ff")
		var rainbow := create_tween()
		rainbow.tween_property(_white, "color", Color("c7efff"), 0.17)
		rainbow.tween_property(_white, "color", Color("fff0bd"), 0.17)
		rainbow.tween_property(_white, "color", Color("ffd1e9"), 0.25)


func _finish() -> void:
	busy = false
	viewer.revealing = false
	viewer.showing_back = false
	viewer._versions.show()
	viewer._refresh(true)
	if _note_open:
		_note_open = false
		GameState.open_album_photo(viewer.photo_id)
	# O selo do resultado fica consultável durante a carta, sem outra faixa de layout.
	var badge := viewer._info.find_child("RarityBadge", true, false)
	if badge != null:
		badge.name = "RevealSeal"
		badge.set_meta("level", viewer.level)
