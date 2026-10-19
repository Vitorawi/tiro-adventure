extends "res://autoload/game_state.gd"
## Relógio injetável SÓ para as simulações de economia (etapa 01 do plano docs/plans/economia).
##
## O jogo normal continua usando `Time.get_unix_time_from_system()` em `GameState.now()`. Este
## script é colocado no lugar do autoload `GameState` pelo runner (set_script), igual a
## tests/friend_clock.gd, e troca apenas a FONTE do tempo: nenhum método de regra é copiado.
##
## Todo timestamp de regra nasce de `now()` ou de `_local_time()` (fuso/dia/semana):
##   produção (StationState.enqueue/ready_at), plantio (plot.planted_at/ready_at), rega,
##   coletas da Natureza e rotas (gathering/activity), necessidades (DogState.updated_at),
##   recargas/cooldowns (care:*, order:*, trick:*, emergency_food), desejos (WishState),
##   faro (FindState.next_at), passeio (WalkState.started_at/ready_at/seed), janela e visitas
##   dos amigos, presente do dia, período das diárias/semanais e horário dos passeios.
## `tests/economy_sim_test.gd` confere por varredura estática que nenhum outro arquivo de
## regra (autoload/, scripts/state/, scripts/util/) lê o relógio do sistema.

const CachedProgress := preload("res://tests/helpers/economy_progress.gd")

var sim_time: float = 1792411200.0
## Segundos somados ao horário universal para obter a hora local (padrão: UTC-3, Brasil).
var zone_bias: int = -10800


func now() -> float:
	return sim_time


func _local_time(at: float = -1.0) -> int:
	return int(now() if at < 0.0 else at) + zone_bias


## Só avança: o relógio de simulação nunca anda para trás (o teste de relógio atrasado é outro).
func advance_clock(seconds: float) -> void:
	sim_time += maxf(0.0, seconds)


func set_clock(value: float) -> void:
	sim_time = value


## A progressão é recriada em reset() e from_dict(): troca por uma com memória das consultas puras
## mais caras (mesma regra, mesmo resultado; ver economy_progress.gd).
func reset() -> void:
	super.reset()
	_use_cached_progress()


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	_use_cached_progress()


func _use_cached_progress() -> void:
	var cached = CachedProgress.new()
	cached.from_dict(progress.to_dict())
	progress = cached
