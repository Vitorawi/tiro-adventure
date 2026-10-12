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

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 3

var _save_pending := false


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
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: falha ao abrir save para escrita (%s)" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	Events.game_saved.emit()
	return true


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		GameState.reset()
		Events.game_loaded.emit()
		return

	var text := FileAccess.get_file_as_string(SAVE_PATH)
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
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.reset()


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
