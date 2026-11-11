class_name FishingFlow
extends Node
## Fluxo da pesca na lagoa do Sítio (etapa 02): painel de arremesso → arremesso → espera (boia) → mordida →
## minigame → resultado → painel de novo. Filho da `RoomView`; só amarra as peças (`FishingPanel`, `FishingBobber`,
## `FishingGame`, `FishResult`, o Tiro e a câmera). TODA regra mora no `GameState` (`cast/hook/miss_bite/finish_fishing`).
##
## `state`: "idle" | "panel" | "waiting" | "fighting" | "result".
## Sair da sala (trocar de aba ou de mundo) com a pesca aberta solta a linha: a isca volta se já tinha sido gasta.

signal state_changed(new_state: String)

## Fração do caminho da margem até o meio da água para cada força (Perto, Meio, Longe).
const REACH := [0.45, 0.7, 0.95]
const BUBBLE_PULL := 40.0

var room: RoomView
var state := "idle"
var panel: FishingPanel
var bobber: FishingBobber
var game: FishingGame
var result: FishResult

var spot := Vector2.ZERO
var face := "west"
var water_center := Vector2.ZERO
var water_polygon := PackedVector2Array()
var bubble_points: Array[Vector2] = []
var last_landing := Vector2.ZERO
var last_cast_on_bubble := false

var _caught: Dictionary = {}
var _poll := 0.0
var _tip_offset := Vector2(0, -28)


func _ready() -> void:
	name = "FishingFlow"
	result = FishResult.new()
	add_child(result)
	result.again.connect(_again)
	result.leave.connect(end)
	result.release.connect(_release_full)
	result.free_space.connect(_free_space)
	bobber = FishingBobber.new()
	room.fishing_world().add_child(bobber)
	Events.fish_bite.connect(_on_bite)
	Events.fish_caught.connect(_on_caught)
	Events.fishing_changed.connect(_on_changed)


func _exit_tree() -> void:
	if is_instance_valid(bobber):
		bobber.queue_free()


func busy() -> bool:
	return state != "idle"


## Ponto da água onde a linha cai para a força (1–3): do `spot` até o meio, sempre dentro da lagoa.
func landing_for(zone: int) -> Vector2:
	var reach: float = REACH[clampi(zone, 1, REACH.size()) - 1]
	var point := spot.lerp(water_center, reach)
	var guard := 0
	while not water_polygon.is_empty() and not Geometry2D.is_point_in_polygon(point, water_polygon) and guard < 30:
		point = point.lerp(water_center, 0.15)
		guard += 1
	return point


# --- Entrada ---------------------------------------------------------------------------------

## Toque na lagoa (já validado pela sala: câmera e Tiro a caminho). Abre o que a partida atual pede.
func begin() -> void:
	var error := GameState.fishing_error()
	if error != "":
		Events.toast_requested.emit(error)
		return
	var c := GameState.fishing.cast
	if not c.is_empty() and str(c.get("state", "")) == "waiting":
		_resume_waiting()
	elif not c.is_empty() and str(c.get("state", "")) == "fighting" and c.has("pending_result"):
		# O peixe esperava a geladeira: se já coube, entrega na hora; senão mostra o cartão de novo.
		var pending: Dictionary = c.pending_result
		if GameState.finish_fishing_error(pending) == "":
			_finish(pending)
		else:
			_show_full()
	else:
		_show_panel()


func _set_state(next: String) -> void:
	if state == next:
		return
	state = next
	state_changed.emit(next)


func _show_panel() -> void:
	_close_game()
	bobber.retract()
	result.close()
	_set_state("panel")
	panel = FishingPanel.open(room)
	panel.cast_requested.connect(_on_cast_requested)
	panel.closed.connect(_on_panel_closed.bind(panel))


func _on_panel_closed(closed_panel: FishingPanel) -> void:
	if state == "panel" and closed_panel == panel:
		end()


# --- Arremesso e espera --------------------------------------------------------------------------

func _on_cast_requested(bait: String, zone: int, _power: float) -> void:
	var landing := landing_for(zone)
	var on_bubble := false
	var bubble := GameState.fishing.bubble
	if not bubble.is_empty() and GameState.current_rod() != "":
		var index := int(bubble.get("spot", 0))
		if index >= 0 and index < bubble_points.size() and landing.distance_to(bubble_points[index]) < BUBBLE_PULL:
			on_bubble = true
			landing = bubble_points[index]
	var error := GameState.cast(bait, zone, on_bubble)
	if error != "":
		Events.toast_requested.emit(error)
		return
	last_landing = landing
	last_cast_on_bubble = on_bubble
	if is_instance_valid(panel):
		panel.close(true)
	panel = null
	_set_state("waiting")
	bobber.launch(spot + _tip_offset, landing)
	bobber.show_ring = false


func _resume_waiting() -> void:
	_set_state("waiting")
	var c := GameState.fishing.cast
	var landing := last_landing if last_landing != Vector2.ZERO else landing_for(int(c.get("zone", 2)))
	bobber.rod_tip = spot + _tip_offset
	bobber.position = landing
	bobber.state = "waiting"
	bobber.show()
	if bool(c.get("bitten", false)):
		bobber.bite()


func _process(delta: float) -> void:
	if state == "idle":
		return
	# Saiu da sala (trocou de aba/mundo): solta a linha e fecha tudo.
	if not room.is_visible_in_tree():
		_abandon("Você soltou a linha" if state == "fighting" else "")
		return
	if state == "waiting":
		_poll += delta
		var c := GameState.fishing.cast
		if not c.is_empty():
			var wait := float(c.get("wait", 1.0))
			var elapsed := GameState.now() - float(c.get("at", 0.0))
			bobber.show_ring = wait > 6.0
			bobber.wait_fraction = clampf(elapsed / maxf(wait, 0.1), 0.0, 1.0)
		if _poll >= 0.1:
			_poll = 0.0
			GameState.update_fishing()  # a mordida precisa chegar na hora: a janela é de 1 s


func _on_changed() -> void:
	# A partida sumiu enquanto esperava (mordida perdida): recolhe a linha e volta ao painel.
	if state == "waiting" and GameState.fishing.cast.is_empty():
		bobber.retract()
		Events.toast_requested.emit("Ele foi embora!")
		_show_panel()


func _on_bite() -> void:
	if state != "waiting":
		return
	bobber.bite()
	var dog := room.dog_node()
	if dog != null:
		dog.fishing_bite()


## Toque no mapa durante a espera: antes da mordida recolhe a linha; na mordida fisga. Devolve se consumiu o toque.
func handle_tap() -> bool:
	var consumed := state in ["waiting", "fighting", "result"]
	if state == "waiting":
		_tap_waiting()
	return consumed


func _tap_waiting() -> void:
	if GameState.fishing.cast.is_empty():
		return
	if not GameState.bite_due():
		_set_state("panel")  # evita que `_on_changed` (disparado pelo miss_bite) reabra o painel em duplicidade
		GameState.miss_bite()
		bobber.retract()
		Events.toast_requested.emit("Ainda não mordeu!")
		_show_panel()
		return
	var error := GameState.hook()
	if error != "":
		_set_state("panel")
		GameState.miss_bite()
		bobber.retract()
		Events.toast_requested.emit("Ele foi embora!")
		_show_panel()
		return
	_start_game()


# --- Minigame e resultado ---------------------------------------------------------------------------

func _start_game() -> void:
	_set_state("fighting")
	bobber.retract()
	var main := room.main_host()
	if main != null:
		main.call("set_row2_blocker", "fishing", true)
	game = FishingGame.open_live(main if main != null else room)
	game.ended.connect(_finish)
	game.released.connect(func() -> void: _finish({"caught": false, "score": 0.0, "perfect": false, "chest": false}))


func _close_game() -> void:
	var main := room.main_host()
	if main != null:
		main.call("set_row2_blocker", "fishing", false)
	if is_instance_valid(game):
		game.queue_free()
	game = null


func _finish(outcome: Dictionary) -> void:
	_close_game()
	var c := GameState.fishing.cast.duplicate(true)
	if c.is_empty():
		_show_panel()
		return
	var fish_id := str(c.get("fish", ""))
	var bait := str(c.get("bait", ""))
	var spent := bool(c.get("spent", false))
	_caught = {}
	var error := GameState.finish_fishing(outcome)
	if error != "":
		_show_full()  # geladeira cheia: o peixe espera na linha
		return
	if bool(outcome.caught) and not _caught.is_empty():
		_set_state("result")
		var def: Dictionary = Database.fishing.fish.get(fish_id, {})
		var classes: Array = Database.fishing.classes
		var cls_def: Dictionary = {}
		for entry: Dictionary in classes:
			if str(entry.id) == str(_caught.get("class", "")):
				cls_def = entry
		var xp := roundi(float(def.get("xp", 0)) * float(cls_def.get("xp", 1.0)) * (float(Database.fishing.meter.perfect_xp_mult) if bool(outcome.get("perfect", false)) else 1.0))
		_caught["xp"] = xp
		_caught["qty"] = int(cls_def.get("qty", 1))
		_caught["perfect"] = bool(outcome.get("perfect", false))
		result.show_caught(_caught)
	else:
		var text := "Escapou! A %s foi junto." % Database.item_name(bait).to_lower() if spent else "Escapou!"
		Events.notice_requested.emit("info", text, bait)
		_show_panel()


func _on_caught(fish_id: String, cm: float, size_class: String, previous_cm: float) -> void:
	_caught = {"fish": fish_id, "cm": cm, "class": size_class, "previous_cm": previous_cm, "first": previous_cm <= 0.0 and GameState.fishing.record(fish_id).get("count", 0) <= 1}


func _show_full() -> void:
	_set_state("result")
	bobber.retract()
	var fish_id := str(GameState.fishing.cast.get("fish", ""))
	result.show_full(fish_id)


## "Liberar espaço": fecha o cartão e abre a geladeira; a pesca continua guardada até caber (ou soltar).
func _free_space() -> void:
	result.close()
	Events.sheet_requested.emit("Geladeira", SheetBuilder.inventory_view("fridge"))
	end()  # a pesca fica guardada na linha: ao tocar na lagoa de novo, o peixe entra se já couber


func _release_full() -> void:
	GameState.release_fish()
	result.close()
	end()


func _again() -> void:
	result.close()
	_show_panel()


# --- Fim ---------------------------------------------------------------------------------------

## Fecha tudo e o Tiro volta à vida normal (o painel fechado, "Sair" ou a linha solta).
func end() -> void:
	if is_instance_valid(panel):
		panel.close(true)
	panel = null
	_close_game()
	if is_instance_valid(bobber):
		bobber.retract()
	if is_instance_valid(result):
		result.close()
	var dog := room.dog_node()
	if dog != null:
		dog.fishing_session = false
	_set_state("idle")


## Solta a linha por saída da sala: devolve a isca da luta e fecha tudo.
func _abandon(message: String) -> void:
	var fighting := state == "fighting"
	if fighting or state == "waiting":
		GameState.cancel_fishing()
	if message != "":
		Events.toast_requested.emit(message)
	end()
	if fighting:
		_caught = {}
