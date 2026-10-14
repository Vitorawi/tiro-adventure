extends SceneTree
## Vários saves: criar, trocar, resumo (nível/capítulo/moedas), padrão e exclusão.
## Usa o SaveManager de verdade, mas começa no slot 4 e devolve o "padrão" original no fim.

var failures: int = 0


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Saves: " + message)


func _initialize() -> void:
	_run.call_deferred()


func _slot_info(manager: Node, slot: int) -> Dictionary:
	for info: Dictionary in manager.call("list_slots"):
		if int(info.slot) == slot:
			return info
	return {}


func _run() -> void:
	var manager: Node = root.get_node("SaveManager")
	var state: Node = root.get_node("GameState")
	var original_default: int = manager.get("default_slot")
	# Começa num slot de teste (4), sem tocar no save em uso pelo desenvolvedor.
	manager.set("active_slot", 4)
	manager.set("_save_path", manager.call("slot_path", 4))
	state.call("reset")
	state.set("coins", 123)
	state.set("level", 3)
	manager.call("save_game")
	var first := _slot_info(manager, 4)
	check(not first.is_empty() and first.active and int(first.level) == 3 and int(first.coins) == 123, "Resumo do save em uso")
	check(int(first.chapter) == 1 and not first.finished, "Começa no capítulo 1")

	var created: int = manager.call("new_slot")
	check(created != 0 and created != 4, "Novo save usa um número livre")
	check(manager.get("active_slot") == created and state.get("level") == 1 and state.get("coins") != 123, "Novo save começa do zero")
	var old := _slot_info(manager, 4)
	check(not old.is_empty() and not old.active and int(old.level) == 3 and int(old.coins) == 123, "Save anterior guarda nível e moedas e aparece como inativo")

	manager.call("switch_slot", 4)
	check(state.get("level") == 3 and state.get("coins") == 123, "Trocar de save carrega o progresso dele")

	manager.call("set_default_slot", created)
	check(manager.get("default_slot") == created, "Escolher o padrão")
	var settings_path: String = manager.call("_settings_path")
	check(JSON.parse_string(FileAccess.get_file_as_string(settings_path)).default_slot == created, "Padrão fica gravado em configurações")

	manager.call("delete_slot", created)
	check(not FileAccess.file_exists(manager.call("slot_path", created)), "Excluir apaga o arquivo")
	check(manager.get("default_slot") == manager.get("active_slot"), "Padrão nunca aponta para um save apagado")
	check(_slot_info(manager, created).is_empty(), "Save excluído some da lista")

	# Interface: engrenagem no topo e painel com os saves.
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(0.3).timeout
	check(main.find_child("SettingsButton", true, false) != null, "Engrenagem na barra superior")
	main.find_child("SettingsButton", true, false).pressed.emit()
	await create_timer(0.4).timeout
	check(main.find_child("Save_4", true, false) != null and main.find_child("NewSave", true, false) != null, "Painel lista o save e oferece um novo")
	check(main.find_child("Play_4", true, false).disabled, "Save em uso aparece como 'Jogando'")

	# Limpeza: remove os arquivos de teste e devolve o padrão original.
	manager.call("delete_slot", 4)
	manager.call("set_default_slot", original_default)
	if failures == 0:
		print("SAVES TEST: PASS")
	else:
		print("SAVES TEST: FAIL (%d)" % failures)
	quit(1 if failures > 0 else 0)
