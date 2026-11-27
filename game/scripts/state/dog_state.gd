class_name DogState
extends RefCounted
## Estado do Tiro.
##
## Necessidades (0-100) não são atualizadas por frame: guardamos o valor no
## instante `updated_at` e calculamos o valor atual pelo tempo decorrido.
## Assim elas continuam caindo com o app fechado. Antes de mudar valores ou
## o estado de sono, chame commit() para "fixar" o valor atual.

const DEFAULT_NEED := 80.0

var name: String = "Tiro"
var needs: Dictionary = {}  # need_id -> valor no instante updated_at
var updated_at: float = 0.0
## Início da ausência contínua em curso (Unix; 0 = online). Salvo, para a proteção valer após recarregar.
var away_since: float = 0.0
var sleeping: bool = false
## Bônus da caminha (0,1 / 0,2): multiplica só a recuperação de energia dormindo. Não é salvo (vem da Casa).
var sleep_bonus: float = 0.0
var outfit: Dictionary = {}  # slot -> item_id (customização, futuro)
## Barriga no relógio (README da alimentação, 2.5): depois da aula da comida a fome não cai por hora, ela é calculada entre
## `belly_from` (instante em que a metade do dia ganhou o ✓) e `belly_to` (fim da metade), em Unix real. Sem ✓: `from == to == 0`.
## Não é salvo: o `GameState` recalcula (`_sync_belly`).
var belly_clock: bool = false
var belly_from: float = 0.0
var belly_to: float = 0.0


func setup(now: float) -> void:
	for id: String in Database.needs:
		needs[id] = float(Database.needs[id].get("initial", DEFAULT_NEED))
	updated_at = now


## Valor atual: o trecho [updated_at, now] é dividido na ausência em curso (`away_since`).
## Antes dela vale a taxa online; depois, a proteção (metade da taxa, teto de horas por ausência,
## piso). Tempo negativo (relógio para trás) não gera ganho nem perda.
func get_need(id: String, now: float) -> float:
	if id == "hunger" and belly_clock:
		return _belly(now)
	var value := float(needs.get(id, DEFAULT_NEED))
	var end := maxf(now, updated_at)
	var online_end := end
	if away_since > 0.0:
		online_end = clampf(away_since, updated_at, end)
	value = _online(id, value, (online_end - updated_at) / 3600.0)
	if online_end < end:
		value = _offline(id, value, online_end, end)
	return clampf(value, 0.0, 100.0)


## Barriga pelo relógio: sem ✓ na metade fica com fome; com ✓ enche (`full`) e desce em linha reta até `end` no fim da metade.
func _belly(now: float) -> float:
	var clock: Dictionary = Database.needs.get("hunger", {}).get("clock", {})
	if belly_to <= belly_from:
		return float(clock.get("hungry", 20.0))
	var t := clampf((now - belly_from) / (belly_to - belly_from), 0.0, 1.0)
	return lerpf(float(clock.get("full", 100.0)), float(clock.get("end", 55.0)), t)


func _online(id: String, value: float, hours: float) -> float:
	var config: Dictionary = Database.needs.get(id, {})
	var rate := -float(config.get("decay_per_hour", 0.0))
	if sleeping and config.has("sleep_regen_per_hour"):
		rate = float(config["sleep_regen_per_hour"]) * (1.0 + sleep_bonus if id == "energy" else 1.0)
	return clampf(value + rate * hours, 0.0, 100.0)


## Trecho offline [from, to]: dormindo a energia sobe (e não volta a cair); o resto cai a
## `rate` da taxa online, só enquanto sobrar tempo protegido da ausência, sem passar do piso
## e sem curar uma barra que já estava abaixo dele.
func _offline(id: String, value: float, from: float, to: float) -> float:
	var config: Dictionary = Database.needs.get(id, {})
	if sleeping and config.has("sleep_regen_per_hour"):
		return clampf(value + float(config["sleep_regen_per_hour"]) * (1.0 + sleep_bonus if id == "energy" else 1.0) * (to - from) / 3600.0, 0.0, 100.0)
	var cap := float(Database.offline.get("max_hours", 8.0)) * 3600.0
	var protected := maxf(0.0, minf(to - away_since, cap) - minf(from - away_since, cap)) / 3600.0
	var floor_value := float(config.get("offline_floor", 0.0))
	if value <= floor_value:
		return value
	var drop := float(config.get("decay_per_hour", 0.0)) * float(Database.offline.get("rate", 0.5)) * protected
	return maxf(floor_value, value - drop)


func commit(now: float) -> void:
	var current := {}
	for id: String in Database.needs:
		current[id] = get_need(id, now)
	needs = current
	updated_at = now
	# Em ausência o Tiro não acorda: a energia fica em 100 e ele levanta ao voltar.
	if sleeping and away_since <= 0.0 and needs.get("energy", 0.0) >= 100.0:
		sleeping = false


## Começa uma ausência contínua (segundo plano/fechar). Idempotente: foco+pausa+fechar contam uma vez
## e salvar de novo não reinicia o teto de horas.
func begin_absence(at: float) -> void:
	if away_since > 0.0:
		return
	at = maxf(at, updated_at)
	commit(at)
	away_since = at


## Encerra a ausência em `now`: projeta o que faltava e volta às taxas online. Sem ausência não faz nada.
func end_absence(now: float) -> bool:
	if away_since <= 0.0:
		return false
	commit(now)
	away_since = 0.0
	if sleeping and needs.get("energy", 0.0) >= 100.0:
		sleeping = false
	return true


## Soma (ou subtrai) valores nas necessidades, ex.: {"hunger": 20}.
func apply(effects: Dictionary, now: float) -> void:
	commit(now)
	for id: String in effects:
		if id == "hunger" and belly_clock:
			continue  # o relógio manda na Barriga
		if needs.has(id):
			needs[id] = clampf(needs[id] + float(effects[id]), 0.0, 100.0)


func set_sleeping(value: bool, now: float) -> void:
	commit(now)
	sleeping = value


## Necessidade mais baixa no momento (para humor/IA).
func lowest_need(now: float) -> String:
	var lowest := ""
	var lowest_value := INF
	for id: String in Database.needs:
		var value := get_need(id, now)
		if value < lowest_value:
			lowest = id
			lowest_value = value
	return lowest


func to_dict() -> Dictionary:
	return {
		"name": name,
		"needs": needs,
		"updated_at": updated_at,
		"away_since": away_since,
		"sleeping": sleeping,
		"outfit": outfit,
	}


func from_dict(data: Dictionary, now: float) -> void:
	setup(now)
	name = data.get("name", name)
	for id: String in data.get("needs", {}):
		if needs.has(id):
			needs[id] = float(data["needs"][id])
	updated_at = float(data.get("updated_at", now))
	away_since = float(data.get("away_since", 0.0))
	sleeping = bool(data.get("sleeping", false))
	outfit = data.get("outfit", {})
