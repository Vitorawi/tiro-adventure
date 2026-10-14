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
## Vários saves (slots 1..MAX_SLOTS): o slot 1 é o arquivo de sempre (user://save.json na versão
## publicada, user://save_dev.json na dev, ver BuildInfo.save_path()); os outros ganham o número
## no nome (save_2.json, save_dev_3.json...). Na Web as duas versões ficam no mesmo IndexedDB do
## site, por isso a dev usa nomes próprios e não apaga o progresso real.
## O slot em que o jogo ENTRA fica em user://settings.json (settings_dev.json na dev).

const SAVE_VERSION := 11
const MAX_SLOTS := 5

## Slot em uso agora e slot em que o jogo entra ao abrir.
var active_slot: int = 1
var default_slot: int = 1

var _save_pending := false
var _save_path := BuildInfo.save_path()


func _ready() -> void:
	_request_persistent_storage()
	_load_settings()
	active_slot = default_slot
	_save_path = slot_path(active_slot)
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


## Apaga o save do slot em uso e recomeça nele (ferramenta DEV).
func delete_save() -> void:
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)
	GameState.reset()


# --- Vários saves --------------------------------------------------------------------

func slot_path(slot: int) -> String:
	var base := BuildInfo.save_path()
	return base if slot == 1 else base.replace(".json", "_%d.json" % slot)


## Saves existentes (mais o slot em uso, mesmo que ainda sem arquivo), com um resumo de cada:
## { slot, level, coins, chapter, chapters, finished, saved_at, active, default }.
func list_slots() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot in range(1, MAX_SLOTS + 1):
		if slot == active_slot or FileAccess.file_exists(slot_path(slot)):
			result.append(_slot_summary(slot))
	return result


func can_add_slot() -> bool:
	return _free_slot() != 0


## Troca de save: grava o atual e carrega o escolhido. Quem chama recarrega a tela.
func switch_slot(slot: int) -> void:
	if slot == active_slot or slot < 1 or slot > MAX_SLOTS:
		return
	save_game()
	active_slot = slot
	_save_path = slot_path(slot)
	load_game()


## Começa um save novo (primeiro número livre) e passa a jogar nele. Devolve o slot, 0 se cheio.
func new_slot() -> int:
	var slot := _free_slot()
	if slot == 0:
		return 0
	save_game()
	active_slot = slot
	_save_path = slot_path(slot)
	GameState.reset()
	save_game()
	Events.game_loaded.emit()
	return slot


## Exclui um save. Se era o que estava em uso, passa para outro existente (ou recomeça do zero
## no mesmo número, quando era o único). O "padrão" nunca fica apontando para um save apagado.
func delete_slot(slot: int) -> void:
	if FileAccess.file_exists(slot_path(slot)):
		DirAccess.remove_absolute(slot_path(slot))
	var remaining: Array[int] = []
	for other in range(1, MAX_SLOTS + 1):
		if other != slot and FileAccess.file_exists(slot_path(other)):
			remaining.append(other)
	if slot == active_slot:
		if remaining.is_empty():
			GameState.reset()
			save_game()
			Events.game_loaded.emit()
		else:
			active_slot = remaining[0]
			_save_path = slot_path(active_slot)
			load_game()
	if slot == default_slot:
		default_slot = active_slot
	_save_settings()


func set_default_slot(slot: int) -> void:
	default_slot = slot
	_save_settings()


func _free_slot() -> int:
	for slot in range(1, MAX_SLOTS + 1):
		if slot != active_slot and not FileAccess.file_exists(slot_path(slot)):
			return slot
	return 0


func _slot_summary(slot: int) -> Dictionary:
	var summary := {
		"slot": slot, "level": 1, "coins": 0, "chapter": 1, "saved_at": 0.0,
		"chapters": Database.progression.chapters.size(),
		"active": slot == active_slot, "default": slot == default_slot,
	}
	var file: Dictionary = {}
	if FileAccess.file_exists(slot_path(slot)):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
		if typeof(parsed) == TYPE_DICTIONARY:
			file = parsed
	summary["saved_at"] = float(file.get("saved_at", 0.0))
	if slot == active_slot:
		summary["level"] = GameState.level
		summary["coins"] = GameState.coins
		summary["chapter"] = GameState.progress.chapter_index()
	elif not file.is_empty():
		var state: Dictionary = _migrate(file).get("state", {})
		summary["level"] = int(state.get("level", 1))
		summary["coins"] = int(state.get("coins", 0))
		var progress := ProgressionState.new()
		progress.from_dict(state.get("progression", {}))
		summary["chapter"] = progress.chapter_index()
	summary["finished"] = int(summary["chapter"]) > int(summary["chapters"])
	return summary


func _settings_path() -> String:
	return BuildInfo.save_path().replace("save", "settings")


func _load_settings() -> void:
	default_slot = 1
	if not FileAccess.file_exists(_settings_path()):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_settings_path()))
	if typeof(parsed) == TYPE_DICTIONARY:
		default_slot = clampi(int(parsed.get("default_slot", 1)), 1, MAX_SLOTS)


func _save_settings() -> void:
	var file := FileAccess.open(_settings_path(), FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: falha ao gravar as configurações (%s)" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify({"default_slot": default_slot}))
	file.close()


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
	if version < 11:
		# v11: história refeita com as linhas da Laís e da vovó Bloblo. Combinado com o Vitor:
		# o progresso anterior é descartado (sem migração) e o jogo recomeça do zero.
		return {"save_version": SAVE_VERSION, "state": {}}
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
