# 01 — Regras de execução e circuito de testes

## Contrato de cada agente

- Leia `CLAUDE.md`/`AGENTS.md`, o Estado atual do `docs/ROADMAP.md`, o [README](README.md), a [00](00_VISAO.md),
  este arquivo, a etapa pedida e as seções do [02](02_DESENHO.md) que ela indicar. Rode `git status` e preserve
  alterações de outras tarefas.
- **Uma etapa por sessão**, na ordem 00 → 07. O jogo funciona ao fim de cada uma.
- **Simplificar de verdade:** o que a etapa remove sai do código, dos dados, dos testes e dos textos. Nada de
  deixar sistema morto "por compatibilidade".
- **Saves sempre zerados** (pedido do Vitor, 23/10/2026). Mudou o formato? Suba `SAVE_VERSION` e deixe o ramo
  de reset cobrir. Não escreva migração, piso legado, nem teste de save antigo.
- Os números do [02](02_DESENHO.md) são alvos iniciais: implemente sem pedir confirmação de cada um; a
  calibração é da 07.
- Pedido novo do Vitor vale mais que tudo (registrar em [DECISOES](DECISOES.md)).
- **Sem push e sem publicar.** Commit local só quando o Vitor pedir.

## Por que mudar os testes

Linha de base (19/10/2026): **suíte inteira 37,7 min**, dos quais `progression_test` = 24,5 min; sem ele,
~12 min para ~90 testes de 2–55 s cada. As etapas ficavam perto de 40 min porque: (1) a lista de "afetados"
crescia a cada etapa e era montada à mão; (2) os portões rodavam a campanha; (3) seis falhas "históricas"
obrigavam a reproduzir e comparar logs toda vez; (4) tudo rodava em série, porque todos os testes usam o
mesmo `user://save_dev.json`.

## Os quatro níveis

Um comando só: `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level <nível>` (criado na etapa 00).

| Nível | Quando | O que roda | Orçamento |
|---|---|---|---|
| **rapido** | o tempo todo enquanto programa | checagem de scripts (import/parse), `content_test`, `texts_test` | ≤ 1 min |
| **etapa** | uma vez, ao fechar a etapa (e quantas vezes precisar durante) | `rapido` + o teste novo da etapa (`-Tests`) + os testes das **áreas** dos arquivos mudados | ≤ 5 min |
| **portao** | etapas **03 e 07** | todos os testes de jogo, menos os da campanha, **em paralelo** (`-Jobs 3`) | ≤ 8 min |
| **campanha** | só na **07**, ou quando o Vitor pedir | `progression_test`, `economy_sim_test`, autotestes Python e `economy_simulate.ps1 -Quick`, com resumo de **dias por fase** | o que levar (≈ 30–45 min) |

Regras dos níveis:

- **Áreas automáticas.** `tools/test_areas.json` liga caminhos (globs) a testes. O nível `etapa` pega os arquivos
  mudados (`git status --porcelain`, ou `-Since <commit>`) e soma os testes das áreas. Arquivos **largos**
  (`game_state.gd`, `database.gd`, `events.gd`, `save_manager.gd`) não escolhem área sozinhos: a etapa diz quais
  áreas passar em `-Areas growth,wishes`. O comando imprime a lista e a estimativa (pelos tempos do último CSV)
  antes de começar; acima do orçamento, avisa — a correção é refinar o mapa, não rodar tudo.
- **Verde é verde.** Depois da 00 não existe "falha histórica". Se um teste quebra porque a etapa mudou a regra
  de propósito, atualize o teste (ou apague, se ele testava o que foi removido) **na mesma etapa**.
- **Campanha pode ficar quebrada entre 01 e 06.** O robô do simulador e a campanha do `progression_test`
  cuidam do Tiro pelas regras antigas; a 07 os reescreve. Por isso eles saem do nível `portao`.
- **Teste novo da etapa:** rápido (alvo ≤ 20 s), lógica pelo `GameState` com o relógio injetável
  (`tests/helpers/economy_clock.gd`) em vez de esperar tempo real; parte de UI só se a etapa mexeu em tela.
  Entra no `test_areas.json` na área certa.
- **Capturas** só quando a etapa mexe em tela: 360×780 na etapa; as três resoluções só nos portões.
- **Depurar** um teste: `tools\run_godot_test.ps1 <nome>` (tempo máximo; "TEMPO ESGOTADO" nunca é PASS).
- Registrar na etapa: comando usado, lista de testes, tempo total e resultado.

## Áreas iniciais (a 00 transforma em `tools/test_areas.json`)

Base: `docs/plans/tiro/MAPA_DE_TESTES.md`. Testes que este plano vai reescrever estão em **negrito**.

| Área | Caminhos | Testes |
|---|---|---|
| growth | `data/growth.json`, `scripts/state/growth_state.gd`, `scripts/ui/growth_ui.gd`, `scripts/ui/pillar_ui.gd` | `growth_test`, **`pillars_test`**, `growth_meals_test`, `growth_ui_test`, `hud_growth_test`, `ceremony_test`, `personality_test`, `silk_test` |
| wishes | `data/wishes.json`, `scripts/state/wish_state.gd`, `scripts/ui/wish_ui.gd`, `scenes/ui/wishes_screen/**` | **`wishes_test`**, **`bond_test`** |
| pet | `scenes/ui/pet_screen/**`, `scripts/ui/pet_care_tray.gd`, `scripts/ui/pet_animator.gd`, `scripts/ui/pet_notebook.gd` | `pet_care_test`, `pet_anchor_test`, `brush_taste_test`, `manual_test` |
| needs | `data/config.json` (needs/offline/mood) | `absence_test`, `pet_care_test` |
| story | `data/quests.json`, `data/progression.json`, `data/routines.json` | `growth_story_test`, `journey_test`, `tasks_test`, `tasks_groups_test`, `npc_lines_test` |
| walks | `data/walks.json`, `scripts/state/walk_state.gd` | `walks_test`, `park_test`, `walk_return_test` |
| tricks | `scripts/ui/trick_ui.gd`, `scenes/ui/trick_training/**` | `tricks_test` |
| finds | `data/finds.json`, `scripts/state/find_state.gd` | `finds_test` |
| farm | `data/crops.json`, `rooms/farm.json`, `scripts/ui/plot_tray.gd` | `farm_test`, `garden_test`, `tray_test` |
| album | `data/album.json`, `scripts/state/album_*.gd`, `scripts/ui/album_view.gd`, `scripts/ui/photo_card.gd` | `album_test`, `album_secrets_test` |
| shell | `scenes/main/**`, `scripts/ui/hud.gd`, `scripts/ui/modal_card.gd`, `scenes/ui/celebration/**`, `scenes/ui/welcome_back/**` | `hud_test`, `festa_test`, `welcome_test` |
| ui_kit | `scripts/ui/ui_kit.gd`, `scripts/ui/sheet_builder.gd`, `scripts/ui/progression_ui.gd`, `assets/theme/**` | `ui_style_test`, `sheet_test`, `lists_test` |
| navigation | `scripts/ui/places.gd`, `scripts/ui/task_help.gd` | `navigation_test`, `tasks_test` |
| dev | `scripts/ui/dev_panel.gd` | `dev_tools_test`, `dev_tools_test_prod` |
| saves | `autoload/save_manager.gd`, `scripts/util/build_info.gd` | `saves_test` |
| sim | `tests/helpers/economy_*.gd`, `tests/economy_simulation.gd` | (só campanha) |

Os caminhos acima são relativos a `game/`. A 00 completa as áreas que faltam (estações, mundo, mercado,
obras...) a partir do mapa do plano Tiro, de modo que **todo teste da suíte pertença a pelo menos uma área**.
