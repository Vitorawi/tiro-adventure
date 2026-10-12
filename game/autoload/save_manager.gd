extends Node
## Persistência local (autoload "SaveManager").
##
## Único ponto do jogo que lê/escreve o save. No navegador, "user://" é
## guardado no IndexedDB do aparelho; no editor/desktop vira um arquivo em
## %APPDATA%/Godot/app_userdata/<projeto>/.
##
## Formato: JSON { "save_version": int, "saved_at": float, "state": {...} }.
## Ao mudar o formato do estado: incremente SAVE_VERSION e trate a versão
## antiga em _migrate() para não perder o progresso dos jogadores.
##
## Arquivo: user://save.json na versão publicada e user://save_dev.json na versão dev
## (BuildInfo.save_path()). Na Web as duas ficam no mesmo IndexedDB do site, por isso
## precisam de nomes diferentes para a versão dev não apagar o progresso real.

const SAVE_VERSION := 5

var _save_pending := false
var _save_path := BuildInfo.save_path()


func _ready() -> void:
	_request_persistent_storage()
	load_game()
	# Qualquer mudança de estado agenda um save (agrupado no fim do frame).
	Events.state_changed.connect(_schedule_save)


func _notification(what: int) -> void:
	# Autosave quando o app perde foco/vai para segundo plano/fecha.
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_APPLICATION_PAUSED, \
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_game()


func _schedule_save() -> void:
	if _save_pending:
		return
	_save_pending = true
	save_game.call_deferred()


func save_game() -> bool:
	_save_pending = false
	var data := {
		"save_version": SAVE_VERSION,
		"saved_at": Time.get_unix_time_from_system(),
		"state": GameState.to_dict(),
	}
	var file := FileAccess.open(_save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: falha ao abrir save para escrita (%s)" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	Events.game_saved.emit()
	return true


func load_game() -> void:
	if not FileAccess.file_exists(_save_path):
		GameState.reset()
		Events.game_loaded.emit()
		return

	var text := FileAccess.get_file_as_string(_save_path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: save corrompido, iniciando do zero.")
		GameState.reset()
		Events.game_loaded.emit()
		return

	var data := _migrate(parsed)
	GameState.from_dict(data.get("state", {}))
	Events.game_loaded.emit()


func delete_save() -> void:
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)
	GameState.reset()


## Só na versão dev: carrega uma CÓPIA do save da versão publicada (mesmo aparelho/navegador)
## para testar em cima do progresso real. O save real não é alterado.
func load_production_copy() -> String:
	const PROD_PATH := "user://save.json"
	if not BuildInfo.is_dev() or _save_path == PROD_PATH:
		return "Disponível só na versão dev"
	if not FileAccess.file_exists(PROD_PATH):
		return "Nenhum save da versão publicada neste aparelho"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROD_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return "Save da versão publicada ilegível"
	GameState.from_dict(_migrate(parsed).get("state", {}))
	return ""


## Converte saves antigos para o formato atual, uma versão por vez.
func _migrate(data: Dictionary) -> Dictionary:
	var version := int(data.get("save_version", 1))
	if version < 2:
		# v1 era só o contador de teste: começa um jogo novo.
		data["state"] = {}
		version = 2
	if version < 3:
		var state: Dictionary = data.get("state", {})
		if not state.is_empty():
			var old_plots: Array = state.get("plots", [])
			state["unlocked_plots"] = maxi(old_plots.size(), int(Database.farm.get("initial_plots", 3)))
		version = 3
	if version < 4:
		var state: Dictionary = data.get("state", {})
		if not state.is_empty():
			var old_owned := {}
			var old_unlocks := {}
			for id: String in Database.progression.settings.legacy_owned:
				old_owned[id] = true
			for id: String in Database.progression.settings.legacy_unlocks:
				old_unlocks[id] = true
			state["progression"] = {"owned": old_owned, "unlocks": old_unlocks}
		version = 4
	if version < 5:
		var state: Dictionary = data.get("state", {})
		if not state.is_empty():
			var progression: Dictionary = state.get("progression", {})
			var owned: Dictionary = progression.get("owned", {})
			var claimed: Dictionary = progression.get("claimed_quests", {})
			for id: String in Database.quests:
				var quest: Dictionary = Database.quests[id]
				if quest.get("kind", "side") != "main":
					continue
				var chapter: Dictionary = Database.progression.chapters[int(quest.chapter) - 1]
				if bool(owned.get(chapter.target, false)):
					claimed[id] = true
			progression["claimed_quests"] = claimed
			state["progression"] = progression
		version = 5
	data["save_version"] = version
	return data


## Pede ao navegador para não apagar o armazenamento do site sob pressão
## de espaço. Sem efeito fora da Web.
func _request_persistent_storage() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(
		"if (navigator.storage && navigator.storage.persist) { navigator.storage.persist(); }",
		true
	)
