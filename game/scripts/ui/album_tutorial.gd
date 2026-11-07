class_name AlbumTutorial
extends Control
## Tutorial da foto da chegada (Fotos do Tiro, etapa 09). A Laís ensina com a carta `h_arrival`: Abrir (Comum), Tentar a
## sorte grátis (Brilhante), Melhorar de presente (Rara), inclinar, escolher a versão e pôr no varal.
## Os resultados forçados são do motor (`GameState._tutorial_level`); aqui só véu, balão e passos salvos.
##
## O véu são quatro retângulos em volta do alvo (só o buraco recebe o toque; o resto é consumido). Nós: `TutorialVeil`
## (`Veil_T/B/L/R`), `TutorialHighlight`, `TutorialBalloon` (retrato + fala da Laís), `TutorialArrow`, `TutorialHand`,
## `TutorialStamp` ("Grátis"/"Presente"), `TutorialStrike` (custo riscado).
##
## Passos salvos (`AlbumState.tutorial.step`): 1 abrir, 2 revelando, 3 tentar a sorte, 4 melhorar, 5 inclinar + versão,
## 6 pôr no varal. Fechar o app no meio retoma no mesmo passo na próxima visita ao Álbum.

const PHOTO := "h_arrival"
const SAY := {
	"open": "Olha! A primeira foto do Tiro chegou fechadinha. Toque em Abrir!",
	"reroll": "Toda foto tem quatro versões. Tente a sorte, essa é por minha conta.",
	"upgrade": "Melhorar sempre sobe um nível. Hoje os materiais são presente meu.",
	"tilt": "Arraste a foto para ver o brilho. Escolha qual versão mostrar!",
	"version": "Agora toque numa versão para mostrar. Escolha a que você mais gosta!",
	"feature": "Põe ela no varal da home pra gente ver sempre.",
}
const DRAG_NEEDED := 0.5  ## ~60 px de arrasto sobre a carta (tilt normalizado)

static var current: AlbumTutorial

var phase := ""  ## open, reveal, reroll, upgrade, tilt, version, feature ou "" (esperando começar)
var viewer: CardViewer
var _wait := 0
var _best := 0
var _veil: Control
var _rects: Array[ColorRect] = []
var _highlight: Panel
var _balloon: Control
var _balloon_label: Label
var _arrow: Control
var _hand: Control
var _stamp: PanelContainer
var _strike: ColorRect
var _pulse: Tween
var _finishing := false


## Chamado quando o Álbum é montado no caderninho. Começa (ou retoma) se a foto da chegada ainda ensina.
static func maybe_start() -> void:
	if is_active() or GameState.album_tutorial_done() or not GameState.album.has_photo(PHOTO):
		return
	if GameState.photo_sealed(PHOTO) <= 0 and GameState.album_tutorial_step() <= 0:
		return  # a foto já foi aberta fora do tutorial: nada a ensinar
	var main := _main()
	if main == null:
		return
	var node := AlbumTutorial.new()
	node.name = "AlbumTutorial"
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.z_index = 13
	main.add_child(node)
	current = node


static func is_active() -> bool:
	return current != null and is_instance_valid(current) and not current.is_queued_for_deletion()


static func _main() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	var node := tree.root.get_node_or_null("Main")
	return node if node != null else tree.current_scene


func _exit_tree() -> void:
	if current == self:
		current = null
	if Events.photo_rolled.is_connected(_on_rolled):
		Events.photo_rolled.disconnect(_on_rolled)


func _ready() -> void:
	Events.photo_rolled.connect(_on_rolled)


## Fecha o tutorial sem concluir: o passo fica salvo e a próxima visita ao Álbum retoma.
func stop() -> void:
	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()


# --- Passos ---------------------------------------------------------------------------------

func _start() -> void:
	var main := _main()
	if GameState.photo_sealed(PHOTO) > 0:
		GameState.advance_album_tutorial(1)
	elif GameState.album_tutorial_step() < 3:
		GameState.advance_album_tutorial(3)  # fechou o app durante a revelação: a carta já está aberta
	viewer = CardReveal.open(PHOTO, {"host": main})
	if viewer == null:
		stop()
		return
	_build_layer()
	var step := GameState.album_tutorial_step()
	_best = GameState.photo_rarity(PHOTO)
	match step:
		1: _go("open")
		2, 3: _go("reroll")
		4: _go("upgrade")
		5: _go("tilt")
		_: _go("feature")
	_layout()


func _go(next: String) -> void:
	phase = next
	_wait = 0
	var step := {"open": 1, "reveal": 2, "reroll": 3, "upgrade": 4, "tilt": 5, "version": 5, "feature": 6}.get(next, 0) as int
	if step > 0:
		GameState.advance_album_tutorial(step)
	_balloon.visible = SAY.has(next)
	if SAY.has(next):
		_balloon_label.text = SAY[next]
	if next == "version":
		_best = viewer.level
	_hand.visible = next == "tilt"
	_stamp.visible = next == "reroll" or next == "upgrade"
	_strike.visible = false
	if _stamp.visible:
		((_stamp.get_child(0)) as Label).text = "Grátis" if next == "reroll" else "Presente"
	_arrow.visible = next in ["open", "feature"]
	if next == "tilt":
		_start_hand()


func _on_rolled(id: String, result: Dictionary) -> void:
	if _veil == null:
		return
	if id != PHOTO or str(result.get("kind", "")) != "tutorial":
		return
	match str(result.get("action", "")):
		"open":
			_go("reveal")
			_wait = 3
		"reroll":
			phase = "reveal"
			_wait = 3
			_next_after = "upgrade"
		"upgrade":
			phase = "reveal"
			_wait = 3
			_next_after = "tilt"
			_best = GameState.photo_rarity(PHOTO)
	if str(result.get("action", "")) == "open":
		_next_after = "reroll"


var _next_after := ""


func _process(_delta: float) -> void:
	if _veil == null:
		_try_start()
		return
	if not is_instance_valid(viewer) or not viewer.is_inside_tree():
		if not _finishing:
			stop()  # o jogador saiu: o passo continua salvo
		return
	match phase:
		"reveal":
			_wait -= 1
			if _wait <= 0 and not viewer.revealing:
				_go(_next_after)
		"tilt":
			if viewer.tilt.length() >= DRAG_NEEDED:
				_go("version")
		"version":
			if viewer.level != _best and not viewer.revealing:
				_go("feature")
		"feature":
			if PHOTO in GameState.album.featured and not _finishing:
				_finish()
	_layout()


## Espera a fila modal esvaziar e o caderninho estar de pé; sem o Álbum aberto, desiste.
func _try_start() -> void:
	var main := _main()
	var sheet := main.get_node_or_null("Sheet") if main != null else null
	if sheet == null or not bool(sheet.call("is_open")):
		stop()
		return
	if bool(main.call("notice_blocked")):
		return
	if CardViewer.is_open():
		return
	_start()


func _finish() -> void:
	_finishing = true
	GameState.finish_album_tutorial()
	_balloon.hide()
	_arrow.hide()
	var timer := get_tree().create_timer(0.7)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(viewer):
			viewer.close()
		Events.sheet_close_requested.emit()
		var count := GameState.sealed_photos().size()
		if count > 0:
			Events.toast_requested.emit("Você tem %d %s para abrir!" % [count, "foto" if count == 1 else "fotos"])
		stop())


# --- Camada visual -------------------------------------------------------------------------

func _build_layer() -> void:
	_veil = Control.new()
	_veil.name = "TutorialVeil"
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["T", "B", "L", "R"]:
		var rect := ColorRect.new()
		rect.name = "Veil_" + side
		rect.color = Color(0.0, 0.0, 0.0, 0.5)
		rect.mouse_filter = Control.MOUSE_FILTER_STOP
		_veil.add_child(rect)
		_rects.append(rect)
	_highlight = Panel.new()
	_highlight.name = "TutorialHighlight"
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = Palette.HONEY
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	_highlight.add_theme_stylebox_override("panel", style)
	_veil.add_child(_highlight)
	if not Motion.reduced:
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_highlight, "modulate:a", 0.45, 0.6)
		_pulse.tween_property(_highlight, "modulate:a", 1.0, 0.6)
	_balloon = VBoxContainer.new()
	_balloon.name = "TutorialBalloon"
	_balloon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.add_child(_balloon)
	_balloon_label = ProgressionUi.npc_header(_balloon as VBoxContainer, "lais", "", true, true)
	_arrow = UiKit.ctl("down", 34, Palette.HONEY)
	_arrow.name = "TutorialArrow"
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.add_child(_arrow)
	_hand = Panel.new()
	_hand.name = "TutorialHand"
	_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hand.custom_minimum_size = Vector2(30, 30)
	_hand.size = Vector2(30, 30)
	var dot := StyleBoxFlat.new()
	dot.bg_color = Color(1, 1, 1, 0.9)
	dot.border_color = Palette.HONEY
	dot.set_border_width_all(3)
	dot.set_corner_radius_all(15)
	_hand.add_theme_stylebox_override("panel", dot)
	_veil.add_child(_hand)
	_stamp = PanelContainer.new()
	_stamp.name = "TutorialStamp"
	_stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag := StyleBoxFlat.new()
	tag.bg_color = Palette.HONEY
	tag.set_corner_radius_all(10)
	tag.content_margin_left = 10.0
	tag.content_margin_right = 10.0
	tag.content_margin_top = 2.0
	tag.content_margin_bottom = 2.0
	_stamp.add_theme_stylebox_override("panel", tag)
	var tag_label := StepCardUi.wood("", 15)
	tag_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp.add_child(tag_label)
	_veil.add_child(_stamp)
	_strike = ColorRect.new()
	_strike.name = "TutorialStrike"
	_strike.color = Palette.ALERT_INK
	_strike.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.add_child(_strike)


## Retângulo do alvo do passo, em coordenadas da tela.
func target_rect() -> Rect2:
	if not is_instance_valid(viewer):
		return Rect2()
	var node: Control = null
	match phase:
		"open": node = viewer.find_child("OpenCard", true, false) as Control
		"reroll": node = viewer.find_child("RerollButton", true, false) as Control
		"upgrade": node = viewer.find_child("UpgradeButton", true, false) as Control
		"feature": node = viewer.find_child("FeatureButton", true, false) as Control
		"version": node = viewer._versions
		"tilt":
			var rect := viewer.card_rect()
			return Rect2(viewer.global_position + rect.position, rect.size)
	if node == null or not node.is_inside_tree():
		return Rect2()
	return node.get_global_rect()


func _layout() -> void:
	var parent := get_parent()
	if parent != null and get_index() != parent.get_child_count() - 1:
		parent.move_child(self, -1)  # por cima de tudo que abriu depois, inclusive no toque
	var screen := get_viewport_rect().size
	var hole := target_rect()
	var none := phase == "reveal" or hole.size == Vector2.ZERO
	if none:
		hole = Rect2(screen * 0.5, Vector2.ZERO)  # sem alvo: tudo escurecido e bloqueado
	else:
		hole = hole.grow(6.0)
	_rects[0].position = Vector2.ZERO
	_rects[0].size = Vector2(screen.x, maxf(hole.position.y, 0.0))
	_rects[1].position = Vector2(0, hole.end.y)
	_rects[1].size = Vector2(screen.x, maxf(screen.y - hole.end.y, 0.0))
	_rects[2].position = Vector2(0, hole.position.y)
	_rects[2].size = Vector2(maxf(hole.position.x, 0.0), hole.size.y)
	_rects[3].position = Vector2(hole.end.x, hole.position.y)
	_rects[3].size = Vector2(maxf(screen.x - hole.end.x, 0.0), hole.size.y)
	_highlight.visible = not none
	_highlight.position = hole.position
	_highlight.size = hole.size
	# O balão fica na metade da tela que o alvo não ocupa.
	var on_top := hole.get_center().y > screen.y * 0.5
	_balloon.size = Vector2(screen.x - 24.0, 0.0)
	_balloon.position = Vector2(12.0, Hud.HEIGHT + 6.0 if on_top else screen.y - _balloon.size.y - 110.0)
	if not on_top:
		_balloon.position.y = screen.y - _balloon.get_combined_minimum_size().y - 110.0
	_arrow.visible = _arrow.visible and not none
	if _arrow.visible:
		_arrow.position = Vector2(hole.get_center().x - 17.0, hole.position.y - 40.0)
	_stamp.position = Vector2(hole.end.x - _stamp.size.x - 4.0, hole.position.y - _stamp.size.y - 2.0)
	if phase == "upgrade" or phase == "reroll":
		_place_strike()


func _place_strike() -> void:
	var chips: Control = null
	if phase == "upgrade":
		chips = viewer.find_child("UpgradeCost", true, false) as Control
	else:
		var button := viewer.find_child("RerollButton", true, false) as Control
		if button != null and button.get_parent().get_child_count() > 1:
			chips = button.get_parent().get_child(1) as Control
	_strike.visible = chips != null and chips.is_inside_tree()
	if _strike.visible:
		var box := chips.get_global_rect()
		_strike.position = Vector2(box.position.x, box.get_center().y - 1.0)
		_strike.size = Vector2(box.size.x, 2.0)


func _start_hand() -> void:
	var rect := target_rect()
	var from := rect.get_center() - Vector2(40.0, 0.0) - _hand.size * 0.5
	_hand.position = from
	if Motion.reduced:
		return
	var swipe := create_tween().set_loops()
	swipe.tween_property(_hand, "position:x", from.x + 80.0, 0.8).set_trans(Tween.TRANS_SINE)
	swipe.tween_property(_hand, "position:x", from.x, 0.8).set_trans(Tween.TRANS_SINE)
	swipe.bind_node(_hand)
