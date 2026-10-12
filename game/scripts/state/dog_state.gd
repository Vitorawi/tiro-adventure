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
var sleeping: bool = false
var affection: int = 0
var outfit: Dictionary = {}  # slot -> item_id (customização, futuro)


func setup(now: float) -> void:
	for id: String in Database.needs:
		needs[id] = DEFAULT_NEED
	updated_at = now


func get_need(id: String, now: float) -> float:
	var config: Dictionary = Database.needs.get(id, {})
	var hours := maxf(0.0, now - updated_at) / 3600.0
	var rate := -float(config.get("decay_per_hour", 0.0))
	if sleeping and config.has("sleep_regen_per_hour"):
		rate = float(config["sleep_regen_per_hour"])
	return clampf(float(needs.get(id, DEFAULT_NEED)) + rate * hours, 0.0, 100.0)


func commit(now: float) -> void:
	var current := {}
	for id: String in Database.needs:
		current[id] = get_need(id, now)
	needs = current
	updated_at = now
	if sleeping and needs.get("energy", 0.0) >= 100.0:
		sleeping = false


## Soma (ou subtrai) valores nas necessidades, ex.: {"hunger": 20}.
func apply(effects: Dictionary, now: float) -> void:
	commit(now)
	for id: String in effects:
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
		"sleeping": sleeping,
		"affection": affection,
		"outfit": outfit,
	}


func from_dict(data: Dictionary, now: float) -> void:
	setup(now)
	name = data.get("name", name)
	for id: String in data.get("needs", {}):
		if needs.has(id):
			needs[id] = float(data["needs"][id])
	updated_at = float(data.get("updated_at", now))
	sleeping = bool(data.get("sleeping", false))
	affection = int(data.get("affection", 0))
	outfit = data.get("outfit", {})
