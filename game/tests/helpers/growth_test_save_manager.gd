extends "res://autoload/save_manager.gd"
## Instância fora da árvore: nenhum _ready/autosave e caminhos exclusivos da fixture.

func _ready() -> void:
	pass

func slot_path(slot: int) -> String:
	return "user://growth_test_fixture/save_%d.json" % slot

func _settings_path() -> String:
	return "user://growth_test_fixture/settings.json"
