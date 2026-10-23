extends "res://autoload/save_manager.gd"
## Instância fora da árvore: nenhum _ready/autosave e caminhos exclusivos da fixture.

func _ready() -> void:
	pass

func slot_path(slot: int) -> String:
	return (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "growth_test_fixture/save_%d.json") % slot

func _settings_path() -> String:
	return (str(load("res://scripts/util/build_info.gd").call("data_dir")) + "growth_test_fixture/settings.json")
