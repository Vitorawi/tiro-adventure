# Etapa 01 — Facilitar o começo

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_01_facilitar.md."
> Pré-requisito: Etapa 00 feita.

## Objetivo (o que o jogador sente)
"Nunca fico parado esperando, sempre sei o que fazer, e sou recompensado ao voltar e ao subir de nível."
Resolve D1, D3 (nível), D4, D7 e D9 de `00_VISAO.md`.

## Leia antes
`game/data/config.json` (`farm`), `game/data/crops.json`, `game/data/recipes.json`,
`game/data/progression.json` (`features`, `upgrades.farm`), `game/autoload/game_state.gd`
(canteiros, `_add_player_xp`, rotinas), `game/scenes/levels/room/room.gd` (`_on_plot_tapped`,
etiquetas), `game/scripts/ui/plot_indicator.gd`, `game/scenes/ui/celebration/`, `game/scenes/main/main.gd`.

---

## 1A. Mais canteiros no começo
- [ ] `config.json → farm.lent_plots`: `[{"count": 2, requirements: bloblo_meet}, {"count": 4, requirements: bloblo_more_crops}]` (eram 1 e 3).
- [ ] `config.json → farm.initial_plots`: `4`; `farm.unlock_costs`: `[0, 0, 0, 0, 40, 70, 100, 150, 220]`
  (a escritura não pode "tirar" canteiro; `accessible_plots()` troca emprestados por comprados).
- [ ] `progression.json → upgrades.farm.description`: "O terreno passa a ser seu: quatro canteiros e espaço para expandir."
- [ ] `npcs.json → bloblo.introduction[1]`: "Este é o meu sítio. Vou te emprestar dois canteiros para começar."
- [ ] `quests.json → bloblo_more_crops.dialogue`: "Mais umas colheitas e te empresto outros dois canteiros." (confira; já deve estar assim).

## 1B. Nada preso a atributo escondido
- [ ] `crops.json → pumpkin.requirements`: `{"quests": ["bloblo_potato"]}` (a Etapa 04 troca por `bloblo_pumpkin`).
- [ ] `recipes.json → pumpkin_mash.requirements`: `{"quests": ["lais_stew"]}` (a Etapa 04 troca).
- [ ] Revise `crops.json`, `recipes.json`, `progression.json → activities/orders`: qualquer
  `requirements.skills` em conteúdo dos capítulos 1–5 vira requisito de missão/capítulo/construção.
  (Atributos só aparecem no cap. 6 — `features.skills`.)
- [ ] `content_test.gd`: nova verificação — conteúdo com `requirements.skills` precisa também exigir
  `chapter >= 6` **ou** uma construção/missão que só existe depois do cap. 6. Mensagem de erro clara.

## 1C. Diárias e semanais mais cedo
- [ ] `progression.json → features.daily.requirements`: `{"chapter": 3}` (era 4).
- [ ] `features.weekly.requirements`: `{"chapter": 4}` (era 5).
- [ ] Confirme que no cap. 3 há pelo menos 3 diárias elegíveis (`feed`, `bathe`, `play`, `harvest`,
  `water` desta etapa). `tasks_test`: diárias aparecem no cap. 3 com 3 missões.

## 1D. Etiqueta só no próximo canteiro fechado
- [ ] Hoje cada canteiro fechado mostra "Sítio" (ver `build/screenshots/ql_farm_bloblo.png`).
  Novo comportamento (em `room.gd`, onde as etiquetas/marcadores dos canteiros são criados):
  - só o **próximo** canteiro fechado (`index == accessible_plots()`) tem etiqueta;
  - antes da escritura: etiqueta "Vovó" (com o ícone `tab_farm`), toque = conversa da vovó (como hoje);
  - depois da escritura: etiqueta com moeda + preço (`[moeda] 40`), toque = compra (como hoje);
  - os outros canteiros fechados: sem etiqueta, só o solo escurecido.
- [ ] Captura antes/depois (`farm_progress.png`).

## 1E. Regar
**Comportamento:** planta crescendo e **não regada** mostra uma gotinha (ícone `action_water`, 24 px,
balançando de leve) acima da barra do `PlotIndicator`. Tocar no canteiro **rega na hora**: gotinhas
caem (tween do ícone descendo e sumindo + 4 pontinhos azuis), o tempo que falta diminui 30%, a gotinha
some. Tocar de novo (já regada) abre o painel de progresso como hoje. Uma rega por plantio.

- [ ] `config.json → farm.water`: `{"speedup": 0.3, "xp": 1}`.
- [ ] Estado: cada canteiro ganha `"watered": false` (em `plant` = false; `from_dict` aceita ausência).
- [ ] `GameState.water_error(index) -> String`: `"Canteiro vazio"`, `"Já foi regado"`, `"Já está pronto"`, `"Compre este terreno primeiro"`.
- [ ] `GameState.water(index) -> String`:
```gdscript
## Rega uma planta crescendo: o tempo que falta cai (config farm.water.speedup), uma vez por plantio.
func water(index: int) -> String:
	var reason := water_error(index)
	if reason != "":
		return reason
	var target := plot(index)
	var left := float(target.ready_at) - now()
	target.ready_at = now() + left * (1.0 - float(Database.farm.water.speedup))
	target.watered = true
	_count("water")
	_add_player_xp(int(Database.farm.water.get("xp", 0)))
	_changed()
	Events.world_activity.emit(&"water", str(target.crop), index)
	return ""
```
  (`plot_progress` usa `planted_at`/`ready_at`: confira que a barra continua indo de 0 a 1 sem pular para trás.)
- [ ] `RoomView._on_plot_tapped(index)`: se `GameState.water_error(index) == ""` → `GameState.water(index)` + efeito; senão comportamento atual.
- [ ] `available_actions()`: tipo `water` (planta crescendo sem rega).
- [ ] `quests.json → first_harvest`:
```json
"dialogue": "Esse canteiro é seu. Planta uma cenoura e rega!",
"goals": [
  {"type": "stat", "key": "water", "target": 1, "label": "Regar a plantinha"},
  {"type": "stat", "key": "harvest", "target": 1, "label": "Colher a cenoura"}
]
```
- [ ] `routines.json → daily.missions.water`:
```json
"water": {"name": "Regue 5 plantas", "description": "Toque nas plantinhas com gota para regar.",
  "goal": {"key": "water", "target": 5}, "rewards": {"coins": 10},
  "requirements": {"quests": ["first_harvest"]}}
```
- [ ] `Places.goal_target`: chave `water` → canteiros do sítio (igual a `harvest`).
- [ ] **Arte:** `action_water.png` (receita "Ícone 32×32" do `01_REGRAS_E_ARTE.md`, descrição
  "game inventory icon: blue watering can pouring water drops, cute, bold outline, light blue and silver, centered, no text").

## 1F. Subir de nível dá presente
**Comportamento:** ao subir de nível abre a comemoração (mesmo visual da de capítulo):
"Nível 3!" grande, a estrela de XP, chips da recompensa e o botão "Oba!". A recompensa entra na hora
(o botão só fecha). Se subir dois níveis juntos, mostra o último com a soma.
- [ ] `progression.json → level_rewards`:
```json
"level_rewards": {
  "2": {"coins": 15, "items": {"dog_food": 2}},
  "3": {"coins": 20, "items": {"carrot_snack": 1}},
  "4": {"coins": 25, "items": {"bolt": 1}},
  "5": {"coins": 30, "affection": 5},
  "6": {"coins": 40, "items": {"bolt": 1}},
  "7": {"coins": 50},
  "8": {"coins": 60, "items": {"iron_band": 1}},
  "9": {"coins": 70},
  "10": {"coins": 100, "items": {"bolt": 2}},
  "default": {"coins_per_level": 10}
}
```
- [ ] `events.gd`: `signal level_up(level: int, rewards: Dictionary)`.
- [ ] `GameState._add_player_xp`: em vez do toast, soma as recompensas dos níveis atingidos
  (`_apply_rewards`) e emite `Events.level_up(level, soma)` uma vez no fim.
- [ ] `celebration.gd`: `show_level(level, rewards)` reaproveitando `_open()`/`_center()`.
- [ ] `main.gd`: conecta `Events.level_up` → `show_level`. Se a introdução estiver na tela, adie até ela fechar.
- [ ] Teste: XP para 2 níveis dá as duas recompensas uma vez; save preserva.

## 1G. "Bem-vindo de volta" + presente do dia
**Comportamento:** ao abrir o jogo (ou voltar do segundo plano) depois de **5 min ou mais**, mostra
um cartão centralizado (mesmo estilo da comemoração):
1. Título "Que bom que você voltou!" + retrato pequeno do Tiro (`tiro_pet_idle_front.png` em 64 px).
2. **Presente do dia** (se ainda não recebeu hoje): ícone grande + quantidade + botão "Receber"
   (CollectFx ao receber).
3. Até 4 linhas "o que ficou pronto": ícone + número + botão "Ir" (ex.: `[cenoura] 3 prontos  [Ir]`),
   vindas de `available_actions()` filtrando `harvest`, `collect`, `gather_ready` (e, nas etapas
   futuras, achados, passeio pronto, presentes de amigos).
4. Botão "Vamos lá!" fecha.
- [ ] `progression.json → daily_gift` (ciclo de 7 **dias jogados**; nunca zera):
```json
"daily_gift": [
  {"items": {"dog_food": 3}},
  {"coins": 15},
  {"items": {"carrot_snack": 2}},
  {"coins": 25},
  {"items": {"bolt": 1}},
  {"coins": 30},
  {"coins": 40}
]
```
- [ ] Estado `progress.daily_gift = {"period": "", "count": 0}` (salvo). Período = `routine_period("daily")`.
- [ ] `GameState.daily_gift_error()` (`"Já recebido hoje"`, ou requisito) e `claim_daily_gift()`:
  aplica `daily_gift[count % 7]`, `count += 1`, `period = hoje`.
- [ ] Requisito: só depois de `lais_bag` (`settings.welcome_requirements = {"quests": ["lais_bag"]}`).
- [ ] `SaveManager`: expor o `saved_at` do arquivo carregado (`var last_saved_at: float`).
- [ ] `main.gd`: no início (depois da intro) e em `NOTIFICATION_APPLICATION_FOCUS_IN`, se
  `now - last_saved_at >= 300` (ou o app ficou em segundo plano ≥ 300 s), mostra o cartão.
  Guarde o horário em que foi para o segundo plano (`NOTIFICATION_APPLICATION_FOCUS_OUT`).
- [ ] Novo `scenes/ui/welcome_back/welcome_back.tscn` + `.gd`.
- [ ] Teste `welcome_test.gd` (novo): presente uma vez por dia; ciclo avança só em dia jogado; não
  aparece antes de `lais_bag`; lista mostra canteiro pronto.

## 1H. Dica parada (seta sozinha)
- [ ] `progression.json → settings`: `"idle_hint_seconds": 15, "idle_hint_max_chapter": 4`.
- [ ] Na tela do Mapa (`worlds_screen`), se passar 15 s sem toque, o capítulo for ≤ 4, e o passo ativo
  da história (ou o primeiro passo de linha) tiver alvo no **mundo aberto** → `RoomView.point_at(alvo)`
  (só a seta, sem abrir painel). Uma vez por passo (guarde o id em memória, não no save).
- [ ] Qualquer toque reinicia o relógio.
- [ ] Teste em `navigation_test`: simular 16 s parado → seta no alvo certo; segunda vez no mesmo passo não repete.

## 1I. Teste "nunca só esperar" (`onboarding_test.gd`, novo)
- [ ] Novo jogo. Um "jogador simulado" repete até a história chegar ao cap. 4 (ou 60 min simulados):
  1. se há missão/diária pronta → recebe;
  2. senão faz o passo ativo da história se puder (comprar, plantar, cozinhar, conversar...);
  3. senão faz a primeira ação de `available_actions()`;
  4. se nada estiver disponível → avança o tempo 10 s (`dev_advance_time`) e soma em `ocioso`.
- [ ] Registra o minuto (tempo simulado) da primeira vez de: `harvest`, `water`, `cook`, `open:village`.
- [ ] Exige (constantes no topo do arquivo, fáceis de mudar): primeira colheita ≤ 4 min; ocioso total
  até o fim do cap. 3 ≤ 4 min; nenhum trecho ocioso contínuo > 120 s.
- [ ] Imprime a linha do tempo no console.
- [ ] Incluir em `tools/test_all.ps1`. As próximas etapas ampliam este teste.

## Testes desta etapa
`farm_test` (regar), `welcome_test` (novo), `onboarding_test` (novo), `navigation_test` (dica),
`tasks_test` (diárias no cap. 3), `content_test` (sem `skills` cedo), suíte completa.

## Capturas a conferir (360×780)
Canteiro com gotinha; canteiros fechados com etiqueta só no próximo; comemoração de nível;
cartão "que bom que você voltou" com presente e 2 linhas prontas.

## Lista de conferência (aceite)
- [ ] B1 empresta 2 canteiros; B3 deixa 4; escritura mantém 4.
- [ ] Nenhuma tela do cap. 1–5 fala em "Horta nível" ou "Cozinha nível".
- [ ] Regar acelera, uma vez, e funciona com o app fechado (timestamps).
- [ ] Nível 2 abre comemoração com presente.
- [ ] Voltar depois de 5 min mostra o cartão; o presente do dia vem uma vez por dia.
- [ ] Diárias no cap. 3.
- [ ] `onboarding_test` passa e imprime a linha do tempo.
- [ ] ROADMAP, CLAUDE.md/AGENTS.md (welcome_back, regar, level_rewards), ART_PIPELINE, README marcados; commit.
