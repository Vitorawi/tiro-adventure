class_name PetNotebook
extends RefCounted
## Consultas do Tiro reunidas no Caderninho (`CodexUi`): abas laterais Recursos, Estações, Crescer, Coleção e Truques (o Álbum tem tela própria, `AlbumScreen`),
## cada uma com filtros no topo. `open("<seção>")`, `open("<seção>:<filtro>")` e `open("album:<seção do álbum>")` abrem direto;
## "manual" continua aceito (= Recursos).


static func tabs() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id": "resources", "text": "Recursos"}, {"id": "stations", "text": "Estações"}]
	if GameState.progress.feature_unlocked("growth_tab"): result.append({"id": "growth", "text": "Crescer"})
	if not GameState.progress.collection.is_empty() or GameState.progress.feature_unlocked("finds"):
		result.append({"id": "collection", "text": "Coleção"})
	if GameState.progress.feature_unlocked("tricks"):
		result.append({"id": "tricks", "text": "Truques"})
	for entry: Dictionary in result:
		entry["alert"] = section_has_new(str(entry.id))
	return result


## "manual" → "resources"; "<seção>:<filtro>" → (seção, filtro).
static func _parse(section: String) -> Array[String]:
	var filter := ""
	if ":" in section:
		filter = section.get_slice(":", 1)
		section = section.get_slice(":", 0)
	if section == "manual" or section == "":
		section = "resources"
	return [section, filter]


static func open(section: String = "resources") -> void:
	# O Álbum saiu do caderninho: tem tela e botão próprios (compatibilidade com "album" e "album:<seção>").
	if section == "album" or section.begins_with("album:"):
		AlbumScreen.open(section.get_slice(":", 1) if ":" in section else "")
		return
	var parsed := _parse(section)
	visit(parsed[0])
	Events.sheet_requested.emit("Caderninho", panel(section))


## Abrir uma seção confirma só as novidades dela.
static func visit(section: String) -> void:
	var keys := section_unlocks(section)
	if not keys.is_empty(): GameState.mark_seen(keys)


static func panel(section: String = "resources") -> Control:
	var parsed := _parse(section)
	return CodexUi.build(parsed[0], parsed[1])


static func has_new() -> bool:
	return tabs().any(func(entry: Dictionary) -> bool: return entry.alert)


static func section_has_new(section: String) -> bool:
	return not section_unlocks(section).is_empty()


## Cada aba confirma só suas próprias novidades; fotos são vistas uma a uma.
static func section_unlocks(section: String) -> Array[String]:
	var result: Array[String] = []
	for key in GameState.new_unlocks():
		if (section == "growth" and key == "feature:growth_tab"
			or section == "collection" and (key in ["feature:dress", "feature:finds"] or key.begins_with("collection:"))
			or section == "tricks" and (key == "feature:tricks" or key.begins_with("trick:"))):
			result.append(key)
	return result
