class_name AlbumRules
extends RefCounted
## Motor de condições do álbum (05 E): um único avaliador para todas as fotos.
## Eventos e condições conhecidos ficam aqui; `Database.album_problems` rejeita o que não estiver nesta lista.

const EVENTS: Array[String] = [
	"fed", "bathed", "petted", "played", "brushed", "slept", "woke", "walk_returned", "dug", "harvested", "watered",
	"tapped_dog", "tapped_object", "equipped", "grew", "quest_claimed", "project_used", "project_gathered",
	"friend_heart", "friend_visit", "trick_learned", "world_entered", "album_opened", "app_opened",
	"intro_done", "chapter_done", "customer_delivery",
]
const CONDITIONS: Array[String] = [
	"phase_min", "phase_in", "hour", "months", "full_moon", "world", "world_in", "dog_in_world", "need_below", "need_min",
	"sleeping", "sleep_spot", "equipped", "owned", "house_item", "stat_min", "friend_hearts", "within",
	"item", "crop", "route", "count_in_window", "quests", "quest_is", "grew_to", "trick", "tricks_min", "growth_food",
	"rare", "chapter_last", "object", "project_done", "start_days", "anniversary", "after_days", "chance",
]
const SECTIONS: Array[String] = ["story", "firsts", "tricks", "sleep", "friends", "dates"]
const SYNODIC := 29.530588853
## Lua nova de referência: 6/1/2000 18:14 UTC.
const NEW_MOON := 947182440.0


## A foto vale agora? Todas as condições do `when` precisam valer.
static func matches(entry: Dictionary, event: String, ctx: Dictionary, at: float) -> bool:
	if event not in events_of(entry):
		return false
	var when: Dictionary = entry.get("when", {})
	for key: String in when:
		if not holds(key, when[key], ctx, event, at):
			return false
	return true


## Eventos que disparam a foto: `on` pode ser um nome ou uma lista (ex.: soneca OU missão da caminha).
static func events_of(entry: Dictionary) -> Array:
	var on: Variant = entry.get("on", "")
	return on.duplicate() if on is Array else [str(on)]


static func holds(key: String, value: Variant, ctx: Dictionary, event: String, at: float) -> bool:
	var growth: GrowthState = GameState.growth
	match key:
		"phase_min":
			return growth.phase_index() >= growth.phase_index(str(value))
		"phase_in":
			return growth.phase in value
		"grew_to":
			return str(ctx.get("grew_to", "")) == str(value)
		"hour":
			var hour := int(Time.get_datetime_dict_from_unix_time(GameState._local_time(at)).hour)
			return (hour >= int(value[0]) and hour < int(value[1])) if int(value[0]) < int(value[1]) else (hour >= int(value[0]) or hour < int(value[1]))
		"months":
			var months: Array = Database.album_config.get("cold_months", [6, 7, 8]) if value is String else value
			var month := int(Time.get_datetime_dict_from_unix_time(GameState._local_time(at)).month)
			return months.any(func(candidate: Variant) -> bool: return int(candidate) == month)
		"full_moon":
			return full_moon(at) == bool(value)
		"world":
			return str(ctx.get("world", "")) == str(value)
		"world_in":
			if value is Dictionary:
				return str(ctx.get("world", "")) in value.ids and growth.phase_index() >= growth.phase_index(str(value.phase_min))
			return str(ctx.get("world", "")) in value
		"dog_in_world":
			return str(ctx.get("dog_world", "")) == str(value)
		"need_below":
			for need: String in value:
				if GameState.dog.get_need(need, at) >= float(value[need]):
					return false
			return true
		"need_min":
			for need: String in value:
				if GameState.dog.get_need(need, at) < float(value[need]):
					return false
			return true
		"sleeping":
			return GameState.dog.sleeping == bool(value)
		"sleep_spot":
			return str(ctx.get("spot", "")) == str(value)
		"equipped":
			return str(value) in GameState.progress.equipped.values()
		"owned":
			return GameState.has_upgrade(str(value))
		"house_item":
			if str(value).begins_with("toy:"):
				return GameState.house_has("toy_basket") and GameState.progress.house.toys.has(str(value).trim_prefix("toy:"))
			return GameState.house_has(str(value))
		"stat_min":
			for stat: String in value:
				var amount: int = int(GameState.progress.customer_orders(stat.trim_prefix("customer_orders:")).count) if stat.begins_with("customer_orders:") else GameState.progress.stat(stat)
				if amount < int(value[stat]):
					return false
			return true
		"friend_hearts":
			for friend: String in value:
				if GameState.friend_hearts(friend) < int(value[friend]):
					return false
			return true
		"within":
			var before: float = GameState.album.last_before(str(value.event), at)
			return before > 0.0 and at >= before and at - before <= float(value.seconds)
		"count_in_window":
			return GameState.album.occurrences(str(value.event), float(value.seconds), at) >= int(value.n)
		"item":
			return str(ctx.get("item", "")) == str(value)
		"crop":
			return str(ctx.get("crop", "")) == str(value)
		"route":
			return str(ctx.get("route", "")) == str(value)
		"object":
			return str(ctx.get("object", "")) == str(value)
		"quests":
			for quest: String in value:
				if not GameState.progress.claimed_quests.has(quest):
					return false
			return true
		"quest_is":
			return str(ctx.get("quest", "")) == str(value)
		"trick":
			return str(ctx.get("trick", "")) == str(value)
		"tricks_min":
			return GameState.progress.tricks.values().count(true) >= int(value)
		"growth_food":
			return bool(ctx.get("growth_food", false)) == bool(value)
		"rare":
			return bool(ctx.get("rare", false)) == bool(value)
		"chapter_last":
			return bool(ctx.get("chapter_last", false)) == bool(value)
		"project_done":
			return GameState.projects.is_completed(str(value))
		"start_days":
			var days := (at - GameState.progress.started_at) / 86400.0
			return days >= float(value[0]) and days < float(value[1])
		"anniversary":
			return anniversary_year(at, float(value)) > 0
		"after_days":
			var completed: float = float(GameState.projects.entry(str(value.project)).get("completed_at", 0.0))
			return completed > 0.0 and floor(GameState._local_time(at) / 86400.0) - floor(GameState._local_time(completed) / 86400.0) >= int(value.days)
		"chance":
			return bool(ctx.get("photobomb", false))
	return false


static func full_moon(at: float) -> bool:
	var age := fmod((at - NEW_MOON) / 86400.0, SYNODIC)
	if age < 0.0:
		age += SYNODIC
	return absf(age - SYNODIC * 0.5) <= 1.0


## Aniversário no calendário local; 29/2 usa 28/2 em anos sem esse dia.
static func anniversary_year(at: float, window: float = 7.0) -> int:
	var start := Time.get_datetime_dict_from_unix_time(GameState._local_time(GameState.progress.started_at))
	var today := Time.get_datetime_dict_from_unix_time(GameState._local_time(at))
	if int(today.year) <= int(start.year): return 0
	var year := int(today.year)
	var leap := year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)
	var day := mini(int(start.day), 28) if int(start.month) == 2 and not leap else int(start.day)
	var anniversary := Time.get_unix_time_from_datetime_dict({"year": year, "month": start.month, "day": day, "hour": 0, "minute": 0, "second": 0})
	var elapsed := GameState._local_time(at) - anniversary
	return year if elapsed >= 0.0 and elapsed < window * 86400.0 else 0
