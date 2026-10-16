class_name PlotTray
extends RefCounted
## Bandejas de ação da horta (Etapa 07): sementes, cuidado, regador e foice.
## Só chamam o que já existe (`GameState.plant/water/harvest` por `RoomView.*_plot`), um canteiro por vez.

const HINT_DRAG := "ui:tray_drag_hint"
const HINT_HARVEST := "ui:tray_harvest_hint"

## Última semente usada nesta sessão (vem primeiro na bandeja). Não é salva.
static var last_crop := ""


## Sementes para um canteiro vazio: toque planta aqui; arrastar a semente planta em vários canteiros.
## `focus` = planta pedida pelo "Ir" (primeira e destacada).
static func seeds(room: RoomView, index: int, focus: String = "") -> ActionTray:
	var greenhouse := GameState.is_greenhouse_plot(index)
	var speed := float(Database.farm.get("greenhouse_speed", 1.0)) if greenhouse else 1.0
	var ids: Array[String] = []
	for crop_id: String in Database.crops:
		if GameState.crop_plot_error(index, crop_id) == "":
			ids.append(crop_id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		var rank_a := _seed_rank(a, focus)
		var rank_b := _seed_rank(b, focus)
		if rank_a != rank_b:
			return rank_a < rank_b
		var time_a := int(Database.crops[a].seconds)
		var time_b := int(Database.crops[b].seconds)
		return time_a < time_b if time_a != time_b else a > b)
	var entries: Array[Dictionary] = []
	for crop_id in ids:
		var crop: Dictionary = Database.crops[crop_id]
		entries.append({
			"id": crop_id,
			"icon": Database.item_icon(crop_id),
			"caption": TimeText.short(int(round(float(crop.get("seconds", 60)) * speed))),
			"error": GameState.content_error("crop", crop_id, crop),
			"help": TaskHelp.open.bind("crop", crop_id),
			"highlight": crop_id == focus,
			"tap": func() -> String:
				var reason := room.plant_plot(index, crop_id)
				if reason == "":
					last_crop = crop_id
				return reason,
			"drag": func(point: Vector2) -> bool:
				var target := room.plot_at(point)
				if target < 0 or GameState.plant_error(target, crop_id) != "":
					return false  # ocupado/incompatível: ignora em silêncio, sem toast no meio do arrasto
				if room.plant_plot(target, crop_id) != "":
					return false
				last_crop = crop_id
				return true,
		})
	var anchor := room.plot_anchor(index)
	var options := {
		"title": "Estufa" if greenhouse else "",
		"below": anchor.below,
		"footer_ghost": {"text": "Ver tudo", "action": func() -> void:
			Events.sheet_requested.emit("Estufa" if greenhouse else "Canteiro", SheetBuilder.seed_picker(index))},
	}
	var first := _first_open(entries)
	if first >= 0 and not bool(GameState.progress.seen.get(HINT_DRAG, false)):
		var points: Array[Vector2] = []
		for other in room.plot_indices():
			if GameState.plot_status(other) == "empty" and GameState.plant_error(other, str(entries[first].id)) == "" and points.size() < 2:
				points.append(room.plot_center(other))
		if points.size() >= 2:
			options["hint"] = {"key": HINT_DRAG, "icon": entries[first].icon, "from": first, "points": points, "caption": "Arraste até a terra"}
	return ActionTray.open(room, anchor.above, entries, options)


static func _seed_rank(crop_id: String, focus: String) -> int:
	if crop_id == focus and focus != "":
		return 0
	var locked := GameState.content_error("crop", crop_id, Database.crops[crop_id]) != ""
	if locked:
		return 3
	return 1 if crop_id == last_crop else 2


static func _first_open(entries: Array[Dictionary]) -> int:
	for i in entries.size():
		if str(entries[i].get("error", "")) == "":
			return i
	return -1


## Planta crescendo: anel com o tempo que falta (e o regador, se ainda dá para regar).
static func care(room: RoomView, index: int) -> ActionTray:
	var entries: Array[Dictionary] = []
	if GameState.water_error(index) == "":
		entries.append(_water_entry(room, index))
	var anchor := room.plot_anchor(index)
	return ActionTray.open(room, anchor.above, entries, {
		"header": CareHeader.new(index),
		"below": anchor.below,
		"auto_close": 3.0,
		"footer_ghost": {"text": "Ver tudo", "action": func() -> void:
			Events.sheet_requested.emit("Plantação", SheetBuilder.growing_plot(index))},
	})


## Regador: arraste por outros canteiros crescendo (uma rega por plantio). Tocar rega todos os que faltam.
static func water(room: RoomView, index: int) -> ActionTray:
	var entries: Array[Dictionary] = [_water_entry(room, index)]
	var anchor := room.plot_anchor(index)
	return ActionTray.open(room, anchor.above, entries, {"below": anchor.below, "auto_close": 3.0})


static func _water_entry(room: RoomView, _index: int) -> Dictionary:
	return {
		"id": "water",
		"icon": UiKit.ui_icon("action_water"),
		"caption_fn": func() -> String: return "×%d" % room.waterable_plots().size(),
		"tap": func() -> String:
			var done := 0
			for target in room.waterable_plots():
				if room.water_plot(target) == "":
					done += 1
			return "" if done > 0 else "Nada para regar",
		"drag": func(point: Vector2) -> bool:
			var target := room.plot_at(point)
			return target >= 0 and GameState.water_error(target) == "" and room.water_plot(target) == "",
	}


## Foice (arraste) e "Tudo" (toque) para colher os que sobraram prontos.
static func sickle(room: RoomView, index: int) -> ActionTray:
	var warned := {"storage": false}
	var common := _most_common_ready_crop(room)
	var entries: Array[Dictionary] = [
		{
			"id": "sickle",
			"icon": UiKit.ui_icon("tool_sickle"),
			"caption_fn": func() -> String: return "×%d" % room.ready_plots().size(),
			"tap": func() -> String: return "Arraste a foice pelos canteiros",
			"drag": func(point: Vector2) -> bool:
				var target := room.plot_at(point)
				if target < 0 or GameState.plot_status(target) != "ready":
					return false
				var error := GameState.harvest_error(target)
				if error != "":
					if not bool(warned.storage):
						warned.storage = true
						Events.toast_requested.emit(error)
					return false
				return room.harvest_plot(target),
		},
		{
			"id": "all",
			"icon": Database.item_icon(common) if common != "" else UiKit.ui_icon("tool_sickle"),
			"caption_fn": func() -> String: return "×%d" % room.ready_plots().size(),
			"tap": func() -> String:
				var done := 0
				for target in room.ready_plots():
					var error := GameState.harvest_error(target)
					if error != "":
						if done == 0:
							return error
						Events.toast_requested.emit(error)  # para no primeiro que não couber, avisando uma vez
						break
					if room.harvest_plot(target):
						done += 1
				return "" if done > 0 else "Nada para colher",
		},
	]
	var anchor := room.plot_anchor(index)
	var options := {"below": anchor.below, "auto_close": 4.0}
	var ready := room.ready_plots()
	if ready.size() >= 2 and not bool(GameState.progress.seen.get(HINT_HARVEST, false)):
		options["hint"] = {"key": HINT_HARVEST, "icon": UiKit.ui_icon("tool_sickle"), "from": 0,
			"points": [room.plot_center(ready[0]), room.plot_center(ready[1])], "caption": "Arraste a foice"}
	return ActionTray.open(room, anchor.above, entries, options)


static func _most_common_ready_crop(room: RoomView) -> String:
	var counts := {}
	var best := ""
	for index in room.ready_plots():
		var crop_id := str(GameState.plot(index)["crop"])
		counts[crop_id] = int(counts.get(crop_id, 0)) + 1
		if best == "" or int(counts[crop_id]) > int(counts[best]):
			best = crop_id
	return best


## Cabeçalho da bandeja de cuidado: anel de tempo com a planta + quanto falta (atualiza sozinho).
class CareHeader extends HBoxContainer:
	var plot_index := 0
	var _ring: RingProgress
	var _time: Label
	var _watered: HBoxContainer
	var _crop := ""
	var _clock := 1.0

	func _init(index: int = 0) -> void:
		plot_index = index
		name = "CareHeader"
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_theme_constant_override("separation", 8)
		alignment = BoxContainer.ALIGNMENT_CENTER
		_ring = RingProgress.new()
		_ring.name = "Ring"
		add_child(_ring)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_time = UiKit.label("", &"")
		_time.name = "Time"
		_time.autowrap_mode = TextServer.AUTOWRAP_OFF
		column.add_child(_time)
		_watered = UiKit.hbox(4)
		_watered.name = "Watered"
		_watered.add_child(UiKit.icon(UiKit.ui_icon("ui_check"), 16))
		var done_label := UiKit.label("Regado", &"SmallLabel", Palette.GOOD)
		done_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_watered.add_child(done_label)
		column.add_child(_watered)
		add_child(column)
		refresh()

	func _process(delta: float) -> void:
		_clock += delta
		if _clock >= 0.25:
			_clock = 0.0
			refresh()

	func refresh() -> void:
		var target := GameState.plot(plot_index)
		var status := GameState.plot_status(plot_index)
		var crop_id := str(target.get("crop", ""))
		if crop_id != "" and crop_id != _crop:
			_crop = crop_id
			_ring.texture = Database.item_icon(crop_id)
		_ring.progress = 1.0 if status == "ready" else GameState.plot_progress(plot_index)
		if status == "ready":
			_time.text = "Pronta!"
		else:
			_time.text = TimeText.short(maxi(0, ceili(float(target.get("ready_at", 0.0)) - GameState.now())))
		_watered.visible = bool(target.get("watered", false))
