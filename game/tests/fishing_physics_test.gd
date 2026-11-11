extends SceneTree
## Pesca, etapa 00: só o motor puro `FishingSim` (física da barra, rede, peixes, determinismo).
var failures := 0
var base: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()
	create_timer(120).timeout.connect(func() -> void: print("FISHING PHYSICS TEST: TIMEOUT"); quit(1))


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Pesca/física: " + message)


## Configuração com remendos: `patch = {"physics": {...}, "meter": {...}}`.
func cfg(patch: Dictionary = {}) -> Dictionary:
	var out: Dictionary = base.duplicate(true)
	for block: String in patch:
		for key: String in patch[block]:
			out[block][key] = patch[block][key]
	return out


func sim(config: Dictionary, fish: Dictionary = {"motion": "mixed", "difficulty": 30}, seed_value: int = 1, bar_h: float = 0.169, rod: Dictionary = {}) -> FishingSim:
	return FishingSim.new(config, fish, seed_value, bar_h, rod)


## Mundo parado: nem a barra se mexe (gravidade e subida zeradas) nem o peixe.
func frozen(extra: Dictionary = {}) -> Dictionary:
	var patch := {"physics": {"thrust": 0.0, "gravity": 0.0}}
	for block: String in extra:
		patch[block] = patch.get(block, {}).merged(extra[block], true)
	return cfg(patch)


func _run() -> void:
	var file := FileAccess.open("res://data/fishing.json", FileAccess.READ)
	base = JSON.parse_string(file.get_as_text())
	check(base.has("physics") and base.has("meter") and base.has("motion"), "fishing.json tem os blocos")
	var tick: float = base.physics.tick

	# 1. Segurar sobe, soltar desce.
	var s := sim(cfg())
	for i in 60:
		s.step(true, tick)
	check(s.bar_y > 0.2, "segurando 1 s a barra sobe (%.3f)" % s.bar_y)
	var top: float = s.bar_y
	for i in 90:  # a inércia leva a barra um pouco mais para cima antes de ela cair
		s.step(false, tick)
	check(s.bar_y < top, "soltando a barra desce")

	# 2. Velocidades: analítica na física real e terminal numa pista em que cabe.
	var phys: Dictionary = base.physics
	s = sim(cfg())
	for i in 30:  # 0,5 s segurando
		s.step(true, tick)
	var expected: float = phys.thrust / phys.drag * (1.0 - exp(-phys.drag * 0.5))
	check(absf(s.bar_v - expected) / expected < 0.03, "v segurando 0,5 s ≈ %.3f (deu %.3f)" % [expected, s.bar_v])
	var slow := cfg({"physics": {"thrust": 6.0, "gravity": 4.0, "drag": 60.0}})
	s = sim(slow, {"motion": "mixed", "difficulty": 0, "still": true}, 1, 0.1)
	s.bar_y = 0.5
	for i in 30:
		s.step(true, tick)
	check(absf(s.bar_v - 6.0 / 60.0) / (6.0 / 60.0) < 0.05, "terminal segurando ≈ thrust/drag (%.4f)" % s.bar_v)
	s = sim(slow, {"motion": "mixed", "difficulty": 0, "still": true}, 1, 0.1)
	s.bar_y = 0.5
	for i in 30:
		s.step(false, tick)
	check(absf(s.bar_v + 4.0 / 60.0) / (4.0 / 60.0) < 0.05, "terminal soltando ≈ −gravity/drag (%.4f)" % s.bar_v)

	# 3. Repique no fundo.
	s = sim(cfg())
	s.bar_y = 0.001
	s.bar_v = -1.0
	s.step(false, tick)
	check(absf(s.bar_v - 0.45 * 0.999) / 0.45 < 0.02 and s.bar_v > 0.0, "repique = −bounce·v (%.3f)" % s.bar_v)
	s = sim(cfg({"physics": {"bounce": 0.0}}))
	s.bar_y = 0.001
	s.bar_v = -1.0
	s.step(false, tick)
	check(is_zero_approx(s.bar_v) and s.bar_y == 0.0, "bounce 0 para a barra")
	s = sim(cfg(), {"motion": "mixed", "difficulty": 0}, 1, 0.169, {"bounce": 0.0})
	s.bar_y = 0.001
	s.bar_v = -1.0
	s.step(false, tick)
	check(is_zero_approx(s.bar_v), "a vara pode trocar o repique")

	# 4. No topo a barra para.
	s = sim(frozen({"physics": {"thrust": 2.11}, "meter": {"fill": 0.0, "drain": 0.0}}), {"motion": "mixed", "difficulty": 0, "still": true})
	var max_y := 0.0
	for i in 240:
		s.step(true, tick)
		max_y = maxf(max_y, s.bar_y)
	check(max_y <= 1.0 - s.bar_h + 1e-9, "não passa de 1 − bar_h (%.4f)" % max_y)
	check(is_equal_approx(s.bar_y, 1.0 - s.bar_h) and s.bar_v == 0.0, "no topo v = 0 (y %.4f, v %.4f, lim %.4f, fim %s)" % [s.bar_y, s.bar_v, 1.0 - s.bar_h, s.finished])

	# 5. Peixe parado dentro da barra: rede de 0,30 a 1,0 em 0,70/fill s, perfeita.
	var calm := {"motion": "mixed", "difficulty": 0, "still": true}
	var inside := frozen()
	s = sim(inside, calm)
	s.bar_y = 0.5 - s.bar_h / 2.0
	var t := 0.0
	while not s.finished and t < 30.0:
		s.step(false, tick)
		t += tick
	var fill_time: float = 0.70 / float(inside.meter.fill)
	check(s.finished and s.caught and s.perfect, "peixe parado dentro: pegou e perfeita")
	check(absf(s.elapsed - fill_time) <= tick * 1.5, "enche em 0,70/fill = %.3f s (deu %.3f)" % [fill_time, s.elapsed])
	check(absf(s.score() - 1.0) < 0.02, "pontuação ≈ 1")

	# 6. Barra longe: esvazia em 0,30/drain s e escapa.
	s = sim(frozen(), calm)
	s.bar_y = 0.0
	t = 0.0
	while not s.finished and t < 30.0:
		s.step(false, tick)
		t += tick
	var drain_time: float = 0.30 / float(base.meter.drain)
	check(s.finished and not s.caught and not s.perfect, "barra longe: escapou")
	check(absf(s.elapsed - drain_time) <= tick * 1.5, "esvazia em 0,30/drain = %.3f s (deu %.3f)" % [drain_time, s.elapsed])

	# 7. hold = 0,30 deixa o dreno 30% mais lento.
	s = sim(frozen(), calm, 1, 0.169, {"hold": 0.30})
	s.bar_y = 0.0
	for i in 60:
		s.step(false, tick)
	var lost: float = float(base.meter.start) - s.meter
	var plain := sim(frozen(), calm)
	plain.bar_y = 0.0
	for i in 60:
		plain.step(false, tick)
	var plain_lost: float = float(base.meter.start) - plain.meter
	check(absf(lost / plain_lost - 0.70) < 0.01, "hold 0,30 → dreno 70%% do normal (%.3f)" % (lost / plain_lost))

	# 8. Determinismo: mesma semente e mesmos toques em 1/32, 1/64 e 1/128 s (tick exato em binário).
	var exact := cfg({"physics": {"tick": 0.0078125}, "meter": {"fill": 0.0, "drain": 0.0}})
	var results: Array[Dictionary] = []
	for frame in [1.0 / 32.0, 1.0 / 64.0, 1.0 / 128.0]:
		var run := sim(exact, {"motion": "darter", "difficulty": 70}, 99)
		var clock := 0.0
		while clock < 10.0 - 1e-9:
			run.step(int(floor(clock * 2.0)) % 2 == 0, frame)  # dedo pesa 0,5 s sim, 0,5 s não
			clock += frame
		results.append({"y": run.fish_y, "bar": run.bar_y, "elapsed": run.elapsed, "bursts": run.bursts})
	check(results[0] == results[1] and results[1] == results[2], "mesmo resultado em 32/64/128 Hz: %s" % str(results))
	var other := sim(exact, {"motion": "darter", "difficulty": 70}, 100)
	for i in 1280:
		other.step(false, 0.0078125)
	check(other.fish_y != results[0].y or other.bursts != results[0].bursts, "outra semente, outro peixe")

	# 9. Cada perfil por 60 s simulados (sem terminar): limites e tendência.
	var endless := cfg({"meter": {"fill": 0.0, "drain": 0.0}})
	for kind in ["mixed", "smooth", "sinker", "floater", "darter"]:
		var difficulty := 75 if kind == "darter" else 40
		var low := 0
		var high := 0
		var total := 0
		var ok := true
		var min_bursts := 999
		var max_bursts := 0
		for seed_value in range(1, 9):  # a tendência é média: vale para muitas sementes, não para uma só
			var run := sim(endless, {"motion": kind, "difficulty": difficulty}, seed_value)
			var hold_it := false
			for i in 3600:  # 60 s
				if i % 45 == 0:
					hold_it = not hold_it
				run.step(hold_it, tick)
				ok = ok and run.fish_y >= 0.02 - 1e-6 and run.fish_y <= 0.98 + 1e-6
				total += 1
				if run.fish_y < 0.5:
					low += 1
				else:
					high += 1
			min_bursts = mini(min_bursts, run.bursts)
			max_bursts = maxi(max_bursts, run.bursts)
		check(ok, kind + ": fica em [0,02; 0,98]")
		if kind == "sinker":
			check(float(low) / total > 0.6, "sinker passa > 60%% abaixo (%.0f%%)" % (100.0 * low / total))
		if kind == "floater":
			check(float(high) / total > 0.6, "floater passa > 60%% acima (%.0f%%)" % (100.0 * high / total))
		if kind == "darter":
			check(min_bursts >= 1, "darter D 75 arranca (mín. %d)" % min_bursts)
		else:
			check(max_bursts == 0, kind + " não arranca")

	# 10. Gravidade que continua puxando ao segurar sobe mais devagar.
	var light := sim(cfg(), calm)
	var heavy := sim(cfg({"physics": {"gravity_on_hold": true}}), calm)
	for i in 30:
		light.step(true, tick)
		heavy.step(true, tick)
	check(heavy.bar_y < light.bar_y, "gravity_on_hold sobe mais devagar (%.3f < %.3f)" % [heavy.bar_y, light.bar_y])

	# Extras: limite de passos por chamada e tempo da folga.
	var big := sim(cfg(), calm)
	big.step(true, 5.0)
	check(big.elapsed <= tick * 10.0 + 1e-9, "no máximo 10 passos por chamada")
	var scored := sim(frozen(), calm)
	scored.bar_y = 0.5 - scored.bar_h / 2.0
	for i in 120:
		scored.step(false, tick)
	check(scored.inside_time > 0.9 and scored.inside_time < 1.1 or scored.finished, "inside_time só conta depois da folga")

	print("FISHING PHYSICS TEST: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
