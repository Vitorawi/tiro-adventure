extends SceneTree
## Runner headless da simulação de economia (etapa 01). Não é um teste: gera relatórios.
##
##   godot --headless --path game -s res://tests/economy_simulation.gd -- \
##       --profile=reference --seed=1 --days=30 --out=build/economy/etapa_01/ref_s1
##
## Opções: --profile=reference|light|active|affective|commercial|recovery  --seed=N  --days=N
##         --until=days|campaign|projects  --rare=normal|worst  --ledger=full|compact|off  --reload=none|session
##         --out=<pasta relativa à raiz do repositório>  --stall-days=N  --stall-active-min=N  --max-actions=N  --trace-end=1 (depuração: rastreia as buscas do último plano)
## Invocador: tools/economy_simulate.ps1. Não grava o save pessoal (SaveManager é removido).



func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# load em tempo de execução: o preload compilaria antes dos autoloads existirem.
	var SimScript: GDScript = load("res://tests/helpers/economy_sim.gd")
	var options := _parse(OS.get_cmdline_user_args())
	if options.until == "week":
		_run_week(options)
		return
	if not SimScript.PROFILES.has(str(options.profile)):
		push_error("Perfil desconhecido: %s" % options.profile)
		quit(2)
		return
	var base := ProjectSettings.globalize_path("res://../")
	if str(options.out) != "" and not str(options.out).is_absolute_path():
		options["out"] = base.path_join(str(options.out))
	var started := Time.get_ticks_msec()
	var sim = SimScript.new(root, options)
	var summary: Dictionary = sim.run()
	var end: Dictionary = summary.end
	print("ECONOMY SIM: perfil=%s seed=%d status=%s dias=%.1f missões=%d/%d melhorias=%d/%d moedas=%d ações=%d ativo=%.1f min violações=%d (%.1f s reais)" % [
		summary.profile, summary.seed, summary.status, end.days, end.quests, end.quests_total, end.upgrades, end.upgrades_total,
		end.coins, summary.time.actions, summary.time.active_min, summary.guards.violations, (Time.get_ticks_msec() - started) / 1000.0])
	if summary.stall != "":
		print("ECONOMY SIM: gargalo=", summary.stall)
	quit(1 if int(summary.guards.violations) > 0 else 0)


func _parse(args: PackedStringArray) -> Dictionary:
	var options := {"profile": "reference", "seed": 1, "days": 30, "until": "days", "rare": "normal", "ledger": "compact", "reload": "none", "out": "", "stall_days": 21, "stall_active_min": 600, "max_actions": 400000, "trace_end": 0}
	for arg in args:
		if not arg.begins_with("--") or not "=" in arg:
			continue
		var key := arg.trim_prefix("--").get_slice("=", 0).replace("-", "_")
		var value := arg.get_slice("=", 1)
		options[key] = value if key in ["profile", "until", "rare", "ledger", "reload", "out"] else int(value)
	return options


func _run_week(options: Dictionary) -> void:
	if options.profile not in ["tranquilo", "regular", "dedicado", "muito", "perde_dia"]:
		push_error("Escolha muito, regular, perde_dia (ou tranquilo/dedicado, rota antiga)")
		quit(2)
		return
	root.get_node("SaveManager").free()
	var state := root.get_node("GameState")
	state.set_script(load("res://tests/helpers/week_story_clock.gd"))
	state.set_clock(1792411200.0)
	seed(options.seed)
	state.reset()
	var sessions: bool = options.profile in ["muito", "regular", "perde_dia"]
	var script := "res://tests/helpers/week_session_route.gd" if sessions else "res://tests/helpers/week_economy_route.gd"
	var bot = load(script).new(state, root.get_node("Database"), Callable())
	var result: Dictionary = bot.measure_sessions(options.profile) if sessions else bot.measure(options.profile)
	var output := ProjectSettings.globalize_path("res://../").path_join(options.out)
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output.path_join("week.json"), FileAccess.WRITE)
	if not file:
		push_error("Falha ao criar relatório " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("ECONOMY SIM: ", options.profile, " Dentinhos D", result.get("growth_day", result.get("phases", {}).get("teething", {}).get("day", 0)), " erros ", result.errors.size())
	quit(0 if result.errors.is_empty() else 1)
