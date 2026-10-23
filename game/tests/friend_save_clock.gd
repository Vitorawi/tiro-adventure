extends "res://autoload/save_manager.gd"
## Persiste apenas arquivos próprios dos testes; jamais toca nos slots pessoais.
func _settings_path() -> String:
	return (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "friends_test_settings.json")

func slot_path(slot: int) -> String:
	return (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "friends_test_slot_%d.json") % slot
