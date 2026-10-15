extends "res://autoload/game_state.gd"
## Relógio injetado só nos testes, sem caminho DEV em produção.
var test_time: float = 0.0
var zone_bias: int = 0

func now() -> float:
	return test_time if test_time > 0 else super.now()

func _local_time(at: float = -1.0) -> int:
	return int(now() if at < 0 else at) + zone_bias
