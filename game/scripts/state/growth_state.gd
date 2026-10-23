class_name GrowthState
extends RefCounted
## Dados do crescimento; consultas não alteram o estado.

var personality: Dictionary = {}
var diary: Array[Dictionary] = []
var diary_receipts: Dictionary = {}

var schema: int = 1
var phase: String = "newborn"
var phase_since: float = 0.0
var moments: Dictionary = {}
var phase_moments: Dictionary = {}
var period_moments: Dictionary = {}
## Corpo é garantido somente pelas refeições, no patamar indicado na fase.
var body_level: int = 0
var done: Dictionary = {}
var delivered: Dictionary = {}
var phase_stats: Dictionary = {}
var ceremonies: Dictionary = {}
var firsts: Dictionary = {}
var pending_reveal: String = ""
var ready_seen: String = ""
## Paladar: item -> reação da primeira prova; semente do save sorteia a favorita e as reações.
var tastes: Dictionary = {}
var taste_seed: int = 0
## Dias (local, "AAAA-MM-DD") em que ele foi escovado.
var brush_days: Dictionary = {}
## Nível da Pelagem de seda (0–3), só cosmético, depois de adulto.
var silk: int = 0


func reset() -> void:
	body_level = 0
	silk = 0
	personality = {}
	diary = []
	diary_receipts = {}
	schema = 1
	tastes = {}
	brush_days = {}
	taste_seed = 0
	phase = "newborn"
	phase_since = 0.0
	pending_reveal = ""
	ready_seen = ""
	for field: String in ["moments", "phase_moments", "period_moments", "done", "delivered", "phase_stats", "ceremonies", "firsts"]:
		set(field, {})
	for pillar: String in ["brave", "smart", "coat"]:
		moments[pillar] = 0
		phase_moments[pillar] = 0


func phase_index(id: String = "") -> int:
	for i in Database.growth.get("phases", []).size():
		if str(Database.growth.phases[i].id) == (phase if id == "" else id):
			return i
	return -1


func phase_need(pillar: String) -> int:
	var index := phase_index() + 1
	if index > 0 and index < Database.growth.phases.size():
		for req: Dictionary in Database.growth.phases[index].requirements:
			if req.type == "moments" and str(req.pillar) == pillar: return int(req.qty)
	return 0


func to_dict() -> Dictionary:
	var data := {"personality": personality.duplicate(true), "diary": diary.duplicate(true), "diary_receipts": diary_receipts.duplicate(), "schema": schema, "phase": phase, "phase_since": phase_since, "pending_reveal": pending_reveal, "ready_seen": ready_seen, "tastes": tastes.duplicate(), "taste_seed": taste_seed, "brush_days": brush_days.duplicate(), "silk": silk, "body_level": body_level}
	for field: String in ["moments", "phase_moments", "period_moments", "done", "delivered", "phase_stats", "ceremonies", "firsts"]:
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
	phase = str(data.get("phase", "newborn"))
	if phase_index() < 0:
		phase = "newborn"
	phase_since = float(data.get("phase_since", 0.0))
	pending_reveal = str(data.get("pending_reveal", ""))
	ready_seen = str(data.get("ready_seen", ""))
	taste_seed = int(data.get("taste_seed", 0))
	body_level = maxi(0, int(data.get("body_level", 0)))
	silk = clampi(int(data.get("silk", 0)), 0, Database.growth.get("silk", {}).get("levels", []).size())
	if data.get("tastes") is Dictionary: tastes = data.tastes.duplicate()
	if data.get("brush_days") is Dictionary: brush_days = data.brush_days.duplicate()
	for field: String in ["moments", "phase_moments", "period_moments", "done", "delivered", "phase_stats", "ceremonies", "firsts"]:
		if data.get(field) is Dictionary:
			set(field, data[field].duplicate(true))
