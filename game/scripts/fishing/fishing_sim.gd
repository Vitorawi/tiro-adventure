class_name FishingSim
extends RefCounted
## Motor puro do minigame de pesca: só números, sem nó, sem desenho e sem relógio.
## A cena (FishingGame) e o teste headless usam exatamente este código.
## Pista vertical: y = 0 é o fundo e y = 1 o topo (fração da altura da pista na tela).
## Física por passo fixo acumulado (`physics.tick`): o resultado não depende do fps.

const MAX_STEPS := 10  # segurança: se o app engasgar, não roda mais que isso por chamada

var config: Dictionary
var fish: Dictionary
var rod: Dictionary
## Regras do tutorial da pesca (opcionais): `drain_until` (sem dreno até a rede passar disso), `meter_floor`
## (depois disso a rede nunca cai abaixo) e `cap` (teto temporário da rede). Vazio = partida normal.
var tutorial: Dictionary = {}

# Estado público.
var bar_y := 0.0
var bar_v := 0.0
var bar_h := 0.17
var fish_y := 0.5
var meter := 0.0
var elapsed := 0.0
var inside_time := 0.0   ## tempo com o peixe na barra, contado depois da folga (`grace`)
var outside_time := 0.0  ## tempo fora da barra, contado depois da folga
var bursts := 0          ## arrancadas do peixe (darter), para teste e ajuste
var finished := false
var caught := false
var perfect := false

## Baú da lagoa (opcional, decidido na fisgada): aparece depois de `chest.appear_after` s e enche a `chest.fill` por s
## enquanto a barra cobre a altura dele; nunca esvazia. `chest_open` = rede do baú cheia.
var chest_enabled := false
var chest_shown := false
var chest_y := 0.0
var chest_meter := 0.0
var chest_open := false

var _chest_rng := RandomNumberGenerator.new()
var _rng := RandomNumberGenerator.new()
var _unlocked := false
var _acc := 0.0
var _tick := 1.0 / 60.0
var _base := 0.5          ## posição do peixe sem o ruído
var _target := 0.5
var _wait := 0.0
var _moving := false
var _bursting := false
var _from := 0.5          ## origem do movimento em S (smooth)
var _progress := 0.0
var _duration := 1.0


func _init(p_config: Dictionary, p_fish: Dictionary, p_seed: int, p_bar_height: float, p_rod: Dictionary = {}) -> void:
	config = p_config
	fish = p_fish
	rod = p_rod
	bar_h = p_bar_height
	_tick = float(config.physics.tick)
	meter = float(config.meter.start)
	_rng.seed = p_seed
	_chest_rng.seed = hash("chest:%d" % p_seed)  # sorteio próprio: o baú não muda o movimento do peixe
	_base = 0.5
	fish_y = 0.5
	_target = _base
	_wait = _pause() * 0.5  # dá um instante para o jogador achar o peixe


func step(holding: bool, delta: float) -> void:
	if finished:
		return
	_acc += delta
	var steps := 0
	while _acc >= _tick - 1e-9 and steps < MAX_STEPS and not finished:
		_acc -= _tick
		steps += 1
		_one_tick(holding)
	if steps >= MAX_STEPS:
		_acc = 0.0  # descarta o atraso acumulado em vez de correr atrás dele


## Pontuação 0–1: fração do tempo (depois da folga) com o peixe dentro da barra.
func score() -> float:
	return clampf(inside_time / maxf(elapsed - float(config.meter.grace), _tick), 0.0, 1.0)


func _one_tick(holding: bool) -> void:
	var phys: Dictionary = config.physics
	var thrust := float(phys.thrust)
	var gravity := float(phys.gravity)
	var drag := float(phys.drag)
	var bounce := float(rod.get("bounce", phys.bounce))
	elapsed += _tick
	# a) barra
	var accel: float
	if holding:
		accel = thrust - drag * bar_v
		if bool(phys.get("gravity_on_hold", false)):
			accel -= gravity
	else:
		accel = -gravity - drag * bar_v
	bar_v += accel * _tick
	bar_y += bar_v * _tick
	# b) fronteiras: no fundo repica, no topo só para
	if bar_y <= 0.0:
		bar_y = 0.0
		bar_v = -bounce * bar_v
		if absf(bar_v) < 0.02:
			bar_v = 0.0
	elif bar_y >= 1.0 - bar_h:
		bar_y = 1.0 - bar_h
		bar_v = 0.0
	# c) peixe
	_move_fish()
	# d) rede
	var meter_cfg: Dictionary = config.meter
	var after_grace := elapsed > float(meter_cfg.grace)
	if meter >= float(tutorial.get("drain_until", 2.0)):
		_unlocked = true
	if fish_y >= bar_y and fish_y <= bar_y + bar_h:
		meter += float(meter_cfg.fill) * float(fish.get("fill_mult", 1.0)) * _tick
		if after_grace:
			inside_time += _tick
	else:
		# Tutorial: sem dreno até a rede passar de `drain_until`; depois ela nunca cai abaixo de `meter_floor`.
		var drain := float(meter_cfg.drain) * float(fish.get("drain_mult", 1.0)) * (1.0 - float(rod.get("hold", 0.0))) * _tick
		if tutorial.has("drain_until") and not _unlocked:
			drain = 0.0
		meter -= drain
		if tutorial.has("meter_floor") and _unlocked:
			meter = maxf(meter, float(tutorial.meter_floor))
		if after_grace:
			outside_time += _tick
	if tutorial.has("cap"):
		meter = minf(meter, float(tutorial.cap))  # demonstração pausada: a rede não termina sozinha
	if chest_enabled:
		_tick_chest()
	# e) fim
	if meter >= 1.0:
		meter = 1.0
		finished = true
		caught = true
		perfect = outside_time == 0.0
	elif meter <= 0.0:
		meter = 0.0
		finished = true
		caught = false


# ---------- baú ----------

func _tick_chest() -> void:
	var chest: Dictionary = config.get("chest", {})
	if not chest_shown:
		if elapsed < float(chest.get("appear_after", 2.0)):
			return
		_place_chest()
	if not chest_open and chest_y >= bar_y and chest_y <= bar_y + bar_h:
		chest_meter = minf(chest_meter + float(chest.get("fill", 0.5)) * _tick, 1.0)
		chest_open = chest_meter >= 1.0


## Altura sorteada a pelo menos 0,3 do peixe (dentro da pista; se não houver lado com espaço, o mais longe possível).
func _place_chest() -> void:
	var lane := _lane()
	var gap := 0.3
	var below := maxf(0.0, (fish_y - gap) - lane.x)
	var above := maxf(0.0, lane.y - (fish_y + gap))
	if below + above <= 0.0:
		chest_y = lane.x if fish_y - lane.x > lane.y - fish_y else lane.y
	elif _chest_rng.randf() * (below + above) < below:
		chest_y = _chest_rng.randf_range(lane.x, fish_y - gap)
	else:
		chest_y = _chest_rng.randf_range(fish_y + gap, lane.y)
	chest_shown = true


# ---------- peixe ----------

func _difficulty() -> float:
	return clampf(float(fish.get("difficulty", 30)) / 100.0, 0.0, 1.0)


func _speed() -> float:
	var speeds: Array = config.motion.speed
	return lerpf(float(speeds[0]), float(speeds[1]), _difficulty())


func _pause() -> float:
	var pauses: Array = config.motion.pause
	return lerpf(float(pauses[0]), float(pauses[1]), _difficulty()) * (0.6 + 0.8 * _rng.randf())


func _lane() -> Vector2:
	var lane: Array = config.motion.lane
	return Vector2(float(lane[0]), float(lane[1]))


func _move_fish() -> void:
	if bool(fish.get("still", false)):  # perfil de teste: peixe parado
		return
	var motion: Dictionary = config.motion
	var kind := str(fish.get("motion", "mixed"))
	if kind == "darter" and not _bursting and _rng.randf() < float(motion.darter_bursts) * _difficulty() * _tick:
		_start_burst()
	if not _moving:
		_wait -= _tick
		if _wait <= 0.0:
			_pick_target(kind)
	else:
		_advance(kind)
	var noise := 0.0
	if kind == "mixed" or kind == "darter":
		noise = float(motion.noise_amp) * sin(TAU * float(motion.noise_hz) * elapsed)
	var lane := _lane()
	fish_y = clampf(_base + noise, lane.x, lane.y)


func _pick_target(kind: String) -> void:
	var motion: Dictionary = config.motion
	var range_: Array = motion.target_range
	var low := float(range_[0])
	var high := float(range_[1])
	var biased := float(motion.biased)
	match kind:
		"smooth":
			_target = _pick_far(low, high, float(motion.smooth_min_distance), _base)
		"sinker":
			_target = _pick_side(low, high, _rng.randf() < biased)
		"floater":
			_target = _pick_side(low, high, _rng.randf() >= biased)
		_:
			_target = _rng.randf_range(low, high)
	_from = _base
	_progress = 0.0
	_duration = maxf(absf(_target - _base) / _speed(), 0.05)
	_moving = true


## Alvo abaixo (`down`) ou acima da posição atual, dentro da pista.
func _pick_side(low: float, high: float, down: bool) -> float:
	if down:
		return _rng.randf_range(low, maxf(low, _base))
	return _rng.randf_range(minf(high, _base), high)


## Alvo a pelo menos `min_distance` da origem (sorteia entre os lados que existem).
func _pick_far(low: float, high: float, min_distance: float, origin: float) -> float:
	var below := maxf(0.0, (origin - min_distance) - low)
	var above := maxf(0.0, high - (origin + min_distance))
	if below + above <= 0.0:
		return _rng.randf_range(low, high)
	if _rng.randf() * (below + above) < below:
		return _rng.randf_range(low, origin - min_distance)
	return _rng.randf_range(origin + min_distance, high)


func _start_burst() -> void:
	var motion: Dictionary = config.motion
	var dist_range: Array = motion.burst_distance
	var distance := _rng.randf_range(float(dist_range[0]), float(dist_range[1]))
	var lane := _lane()
	var up := _rng.randf() < 0.5
	if up and _base + distance > lane.y:
		up = false
	elif not up and _base - distance < lane.x:
		up = true
	_target = clampf(_base + (distance if up else -distance), lane.x, lane.y)
	_from = _base
	_progress = 0.0
	_bursting = true
	_moving = true
	bursts += 1
	_duration = maxf(absf(_target - _base) / (_speed() * float(motion.burst_speed)), 0.05)


func _advance(kind: String) -> void:
	var motion: Dictionary = config.motion
	var speed := _speed()
	if _bursting:
		speed *= float(motion.burst_speed)
	if kind == "smooth":
		_progress = minf(_progress + _tick / _duration, 1.0)
		var s := _progress * _progress * (3.0 - 2.0 * _progress)  # curva em S
		_base = lerpf(_from, _target, s)
		if _progress >= 1.0:
			_arrive()
		return
	var down := _target < _base
	if kind == "sinker":
		speed *= float(motion.sinker_fall) if down else 1.0 / float(motion.sinker_fall)
	elif kind == "floater":
		speed *= float(motion.floater_rise) if not down else 1.0 / float(motion.floater_rise)
	var move := speed * _tick
	if absf(_target - _base) <= move:
		_base = _target
		_arrive()
	else:
		_base += move * signf(_target - _base)


func _arrive() -> void:
	_moving = false
	_bursting = false
	_wait = _pause()
