class_name GrowthState
extends RefCounted
## Dados do crescimento; consultas não alteram o estado.

var personality: Dictionary = {}
var diary: Array[Dictionary] = []
var diary_receipts: Dictionary = {}

var schema: int = 1
var phase: String = "newborn"
var phase_since: float = 0.0
var points: Dictionary = {}
var reserve: Dictionary = {}
var done: Dictionary = {}
var delivered: Dictionary = {}
var phase_stats: Dictionary = {}
var ceremonies: Dictionary = {}
var cooldowns: Dictionary = {}
var firsts: Dictionary = {}
var pending_reveal: String = ""
var ready_seen: String = ""
var foods_revision: int = 1
## Paladar: item -> reação da primeira prova; semente do save sorteia a favorita e as reações.
var tastes: Dictionary = {}
var taste_seed: int = 0
## Dias (local, "AAAA-MM-DD") em que ele foi escovado.
var brush_days: Dictionary = {}
## Nível da Pelagem de seda (0–3), só cosmético, depois de adulto.
var silk: int = 0


func reset() -> void:
	silk = 0
	personality = {}
	diary = []
	diary_receipts = {}
	schema = 1
	tastes = {}
	brush_days = {}
	taste_seed = 0
	foods_revision = 1
	phase = "newborn"
	phase_since = 0.0
	pending_reveal = ""
	ready_seen = ""
	for field: String in ["points", "reserve", "done", "delivered", "phase_stats", "ceremonies", "cooldowns", "firsts"]:
		set(field, {})
	for pillar: String in Database.growth.get("pillars", {}):
		points[pillar] = 0
		reserve[pillar] = 0


func phase_index(id: String = "") -> int:
	for i in Database.growth.get("phases", []).size():
		if str(Database.growth.phases[i].id) == (phase if id == "" else id):
			return i
	return -1


func cap() -> int:
	var index := phase_index()
	return int(Database.growth.phases[index].cap) if index >= 0 else 1


func level(pillar: String) -> int:
	var result := 0
	for threshold: Variant in Database.growth.get("levels", []):
		if int(points.get(pillar, 0)) >= int(threshold):
			result += 1
	return mini(result, cap())


func to_dict() -> Dictionary:
	var data := {"personality": personality.duplicate(true), "diary": diary.duplicate(true), "diary_receipts": diary_receipts.duplicate(), "schema": schema, "phase": phase, "phase_since": phase_since, "pending_reveal": pending_reveal, "ready_seen": ready_seen, "foods_revision": foods_revision, "tastes": tastes.duplicate(), "taste_seed": taste_seed, "brush_days": brush_days.duplicate(), "silk": silk}
	for field: String in ["points", "reserve", "done", "delivered", "phase_stats", "ceremonies", "cooldowns", "firsts"]:
		data[field] = (get(field) as Dictionary).duplicate(true)
	return data


func from_dict(data: Dictionary) -> void:
	reset()
	if data.get("personality") is Dictionary: personality = data.personality.duplicate(true)
	if data.get("diary_receipts") is Dictionary: diary_receipts = data.diary_receipts.duplicate()
	if data.get("diary") is Array:
		for row: Variant in data.diary:
			if row is Dictionary: diary.append(row.duplicate())
	while diary.size() > int(Database.growth.get("diary", {}).get("limit", 20)): diary.pop_front()
	foods_revision = int(data.get("foods_revision", 0))
	phase = str(data.get("phase", "newborn"))
	if phase_index() < 0:
		phase = "newborn"
	phase_since = float(data.get("phase_since", 0.0))
	pending_reveal = str(data.get("pending_reveal", ""))
	ready_seen = str(data.get("ready_seen", ""))
	taste_seed = int(data.get("taste_seed", 0))
	silk = clampi(int(data.get("silk", 0)), 0, Database.growth.get("silk", {}).get("levels", []).size())
	if data.get("tastes") is Dictionary: tastes = data.tastes.duplicate()
	if data.get("brush_days") is Dictionary: brush_days = data.brush_days.duplicate()
	for field: String in ["points", "reserve", "done", "delivered", "phase_stats", "ceremonies", "cooldowns", "firsts"]:
		if data.get(field) is Dictionary:
			set(field, data[field].duplicate(true))
