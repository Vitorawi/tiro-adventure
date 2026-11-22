# F00 — Sem travas por dia do calendário

Plano: `docs/plans/novo_fluxo/README.md` (princípios 4 e 5, seção 9 "Sai", decisão F6).
Mapa do projeto: `CLAUDE.md`. Esta etapa **não** mexe na ordem da história, nas falas nem no relógio das refeições.

## Objetivo

Hoje o conteúdo da primeira semana abre pelo **dia do calendário** (`GameState.week_day()`), e a história para com
"A vovó volta amanhã". Depois desta etapa:

1. O conteúdo abre pelo **capítulo da história**. Criar `GameState.content_day() -> int` =
   `clampi(progress.chapter_index(), 1, 99)` (capítulo principal atual; a semana tem os capítulos 1–7, então
   "dia N" de hoje vira "capítulo N"). Comentário curto explicando isso.
2. A história nunca espera o relógio: `week_quest_wait()` passa a devolver sempre `""` e é **removida** com todos
   os chamadores (UI e GameState). Sai também a regra "um capítulo por dia" (`week.last_story_chapter_date`:
   remover o campo do `WeekState` e o que grava nele) e o campo `meal_open` das missões (`quests.json`).
3. O **relógio das refeições fica exatamente igual**: janelas, patinha, `well_fed_day`, Deixar pronto, dia fraco,
   marmita, Bom dia/Boa noite, limites diários de loja, desafio do dia, ingrediente do dia, rotação da oferta e da
   carroça (o que é "por dia" porque renova a cada dia, não porque tranca conteúdo) continuam em `week_day()`.

## Inventário (classificar cada uso)

Troque `week_day()` por `content_day()` **só** onde o dia tranca conteúdo. Lista encontrada com
`grep -rn "week_day\|fishing_day\|orchard_day\|from_day\|max_by_day\|week_invent_open" game --include=*.gd --include=*.json`:

| Trava | Onde | Vira |
|---|---|---|
| Missões esperam o dia/jantar | `game_state.gd` `week_quest_wait`, `week_quest_day`; UI `places.gd:746-751`, `quest_guide.gd:22`, `step_card_ui.gd:399`, `celebration.gd:20`, `tasks_screen.gd:361`; `game_state.gd:3815/3891/3963` | removido; `week_quest_day` só fica se ainda tiver uso real |
| Crescer só no jantar do dia 2 | `week_growth_error` ("O Tiro cresce a partir do jantar") | linha removida (o resto da função fica) |
| Requisito `week_day` | `GameState.requirement_error` (linha ~3318) + `progression.json` (truques, lojas, carroça), `recipes.json:761`, `rooms/farm.json` (objetos da semana) | o requisito passa a comparar com `content_day()`; renomear a chave para `"story_day"` nos JSON **e** no código (o texto de erro vira "Continue a História" em vez de "Abre no dia N") |
| Lagoa / pomar | `config.json → farm.fishing_day/orchard_day`, `farm_lake_open`, entrega do pomar (~7418–7440), texto "A lagoa abre no dia" (~6828) | `content_day()`; renomear as chaves para `fishing_chapter`/`orchard_chapter` |
| Show de truques | `trick_settings.show.day`, `meal_trick_offer` (~895–965) | trava de abertura por `content_day()`; o prêmio "uma vez por dia" (`last_trick_show_day`) continua por `week_day()` |
| Aula do Tiro uma por período | `WeekState.trick_periods` e onde é checado | **sai o limite** (decisão F6): só o custo de 1 biscoito segura. Remover o campo |
| Brincadeiras | `yard_rules().days`, `yard_open` (~1192–1221) | `content_day()`; erro "Continue a História" |
| Tipos de prato e 3º espaço | `DishRules.available(day)`, `slot_count(..., day)`, `max_by_day`, `dish_type_open` (`opens`) | os chamadores passam `content_day()` (o motor puro continua recebendo um número) |
| Inventar só no jantar do dia 1 | `week_invent_open` | `has_upgrade("stove")` + capítulo; sem relógio. Revisar `cook_panel.gd:520` e `game_state.gd:1640, 8529, 8908` |
| Livro de receitas | `recipe_book.json → from_day` | `from_chapter`, comparado com `content_day()` (o ingrediente do dia segue renovando por dia) |
| Rotina por dia | `week_routine.json` cartões `day` + `game_state.gd:~8904` | o que **abre** cartão/linha por dia passa a `content_day()`; contagem de dia ("Dia %d com o Tiro") continua no calendário |
| Desejos a partir do dia 3 | `game_state.gd:4134` | `content_day() >= 3` |
| Novidade de receita | `game_state.gd:4240` `novelty.from_day` | `content_day()` |
| Primeiros dias mais rápidos | `farm.early_through` (~2088, ~2477) | **fica** no calendário (é ritmo, não trava). Registrar no README do plano que a F05 decide isso |
| Carroça | `cart_day()`, `shop("week_cart").requirements.week_day` (~3456–3520) | abertura por `story_day`; a rotação dos pedidos segue por dia |

Se aparecer outra trava fora desta lista, aplique a mesma regra e anote no relatório.

## Saves e textos

- `SAVE_VERSION` +1 (`save_manager.gd`), saves zerados, sem migração (regra do projeto).
- Nenhuma fala nova. Os textos "Abre no dia N", "A vovó volta amanhã", "A vovó volta no jantar",
  "O Tiro cresce a partir do jantar" somem; onde precisar de motivo, use "Continue a História".
- Atualizar `docs/plans/primeira_semana/REGRAS.md` só se ele afirmar uma trava que deixou de existir (uma linha "substituído pela F00 do novo fluxo").

## Testes

- Teste novo `game/tests/no_day_gates_test.gd` (registrar em `tools/test_areas.json`, suite + áreas `week` e `story`):
  1. Save novo, relógio parado no dia 1 às 9h (`dev_week_goto`/`dev_week_hour` ou o relógio injetável): completar
     as missões principais dos capítulos 1 a 3 pelas ações reais/DEV de conteúdo, sem avançar o relógio, e conferir
     que nenhuma ficou bloqueada (`quest_ready`/`claim_quest` funcionam).
  2. Com `content_day()` = 3: lagoa aberta, tipos de prato do capítulo 3 abertos, terceiro espaço da papinha,
     brincadeiras do capítulo correspondente, mesmo com `week_day()` = 1.
  3. Aula do Tiro duas vezes seguidas no mesmo período (com 2 biscoitos) funciona.
  4. O relógio das refeições continua: refeição fora da janela não conta, `well_fed_day` só sobe pelo dia real.
  5. `grep` lógico: nenhum JSON de `game/data` tem mais as chaves `week_day`, `fishing_day`, `orchard_day`, `from_day`, `meal_open`.
- Rodar `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Tests no_day_gates_test -Areas week,story,farm,tricks,dishes,fishing -KeepGoing`.
  Testes antigos que testavam a trava por dia (ex.: `week_story_test`, `farm_week_test`, `trick_lesson_test`,
  `week_routine_test`, `cart_test`, `recipe_book_test`, `day_clock_test`) devem ser **ajustados para a regra nova**
  (abrir pelo capítulo), não apagados. Falhas que já existiam antes (ver "Estado atual" do `docs/ROADMAP.md`) ficam
  anotadas, não precisam ser consertadas.

## Pronto quando

- Nenhuma trava por dia do calendário para conteúdo; história flui sem "volte amanhã".
- Refeições/patinhas idênticas ao antes.
- Teste novo PASS e afetados PASS (ou falha antiga documentada).
- `docs/ROADMAP.md` "Estado atual": uma linha da F00. `CLAUDE.md` e `AGENTS.md`: uma linha curta no bloco
  "Primeira semana" dizendo que `content_day()` substitui o dia nas travas (os dois arquivos iguais).
- Sem commit, push ou publicação.
