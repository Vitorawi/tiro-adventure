extends "res://autoload/save_manager.gd"
## Persiste apenas arquivos próprios dos testes; jamais toca nos slots pessoais.
func _settings_path() -> String:
	return "user://friends_test_settings.json"

func slot_path(slot: int) -> String:
	return "user://friends_test_slot_%d.json" % slot
