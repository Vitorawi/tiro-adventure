# Mapa de testes — o que rodar quando mexer em cada área

Regra (ver [01](01_REGRAS_DE_EXECUCAO.md)): numa etapa, rode **o teste novo da etapa + as linhas abaixo que
correspondem aos arquivos que você mudou**. Nada além disso, salvo nos portões (suíte inteira).
Tempos medidos na linha de base da etapa 00 (19/10/2026, Windows do Vitor), somando os testes da linha.
Como rodar: `powershell -ExecutionPolicy Bypass -File tools\test_all.ps1 -Only "a,b,c"` (tempos em
`build/test_logs/last_run.csv`). `-Skip "a,b"` pula; `-Fast` pula `progression_test`, `economy_sim_test` e os
autotestes Python; `-KeepGoing` não para na primeira falha.

| Se mudou... | Rode | ≈ tempo |
|---|---|---|
| `growth_ui.gd`, selo, silhueta e entrega na UI | `growth_ui_test`, `ui_style_test`, `sheet_test`, `texts_test`, `navigation_test`, `tasks_test`, `pet_care_test`, `manual_test`, `growth_test` (+ demais linhas alteradas) | novo ~14 s + afetados |
| `growth.json`, `growth_state.gd`, ações de crescimento no `game_state.gd` | `growth_test` (02), `pillars_test` (03), `personality_test` (16, ~7 s), `silk_test` (17, ~5 s), `content_test` | 5 s + novos |
| `items.json`, `recipes.json` (comidas/itens novos), `collections.json` (lacinho) | `keys_test` (10, ~6 s), `growth_foods_test` (09), `festival_test`, `lists_test`, `content_test`, `products_test`, `station_tray_test`, `fridge_test` | 55 s + novo |
| `quests.json`, `progression.json` (capítulos, missões, requisitos) | `growth_story_test` (11, ~5 s), `journey_test`, `tasks_test`, `content_test`, `festival_test`, `npc_lines_test`* ; `progression_test` só se a ordem dos capítulos mudou | 40 s (+ 24,5 min com `progression_test`) + novo |
| `album.json`, `album_state.gd`, `album_rules.gd`, `_album_event` nas ações, `photo_card.gd`, `album_view.gd`, aba Álbum, aviso "Nova foto!" | `album_test` (13, ~12 s), `album_secrets_test` (15, ~12 s), `finds_test`*, `welcome_test`, `manual_test`, `festa_test`, `lists_test`, `texts_test`, `ceremony_test`, `growth_ui_test`, `dev_tools_test` (+ `_prod`) | 24 s + afetados |
| `finds.json` (dentinho de leite) | `finds_test`*, `growth_story_test` | 6 s + novo |
| `walks.json` (requisito de fase nos passeios) | `walks_test`, `park_test` | 16 s |
| truques (`progression.json → tricks`) | `tricks_test` | 10 s |
| `wishes.json` / feature `wishes` | `wishes_test`, `bond_test` | 14 s |
| `save_manager.gd`, migração, chaves novas no save | `saves_test`, `economy_transactions_test`, o teste da etapa | 11 s + novo |
| `pet_screen.gd`, `pet_care_tray.gd`, `pet_animator.gd` | `pet_care_test`, `brush_taste_test`, `personality_test`, `wishes_test`, `manual_test` | 40 s |
| `pet_notebook.gd`, `game_manual.gd`, aba Atributos/Crescimento | `manual_test`, `lists_test` | 30 s |
| `hud.gd`, `main.gd` (fila modal, avatar) | `hud_test`, `festa_test`, `welcome_test` | 25 s |
| `celebration.gd`, `modal_card.gd`, `welcome_back.gd` | `festa_test`, `welcome_test` | 16 s |
| `house.json`, Casa/caminhas/tigela/brinquedos/fotos penduradas, `HouseDecor`/`HouseUi`/`CornerDecor` | `house_test` (~11 s), `world_life_test`, `world_view_test`, `navigation_test`, `pet_care_test`, `absence_test`, `texts_test`, `album_test`, `lists_test` | ~2 min |
| `dog_world.gd`, `room.gd`, `rooms/house.json` | `world_life_test`, `world_view_test`, `navigation_test`, `personality_test` | 55 s |
| `sheet_builder.gd`, `ui_kit.gd`, `progression_ui.gd` | `ui_style_test`, `sheet_test`, `lists_test` | 33 s |
| `personality_rules.gd`, `growth.json → personality/behaviors/diary`, `PillarUi` (jeito/diário) | `personality_test`, `growth_ui_test`, `manual_test`, `texts_test` | ~40 s |
| textos visíveis novos | `texts_test` | 2 s |
| `task_help.gd`, `places.gd` (Ir/Como fazer) | `navigation_test`, `tasks_test` | 32 s |
| roupas / `overlay_anchors.json` | `petshop_test`, `festival_test` (só a parte de roupa, se der para isolar) | 30 s |
| `dev_panel.gd`, `dev_*` | `dev_tools_test` e `dev_tools_test -- --prod` (`-Only dev_tools_test,dev_tools_test_prod`) | 7 s |
| helpers do simulador (`tests/helpers/economy_*.gd`) | `economy_sim_test` | 55 s |
| arte apenas (PNG) sem código | nenhum teste; prancha + capturas | — |

\* falhas históricas conhecidas: `onboarding_test`, `finds_test`, `npc_lines_test` — reproduzir uma vez e
registrar; não bloqueiam a etapa se a falha for a mesma de antes.
A linha de base da etapa 00 achou mais quatro (lista e primeira linha do erro no [README](README.md#falhas-que-já-existiam-antes-do-plano)):
`progression_test`, `petshop_test`, `park_test` e `ui_style_test` (esses dois imprimem PASS e caem só no filtro de
`ERROR:` do `test_all.ps1`, por recursos ainda em uso ao sair). Valem a mesma regra.

## Portões (suíte inteira, uma vez)

Etapas **08, 11, 16 e 18**: `powershell -ExecutionPolicy Bypass -File tools\test_all.ps1` (com
`progression_test`). Registrar duração total e falhas. Nas demais etapas, **não** rodar a suíte inteira.
Linha de base (etapa 00): **37,7 min** no total, dos quais `progression_test` = 24,5 min; sem ele (`-Fast`)
≈ 12 min. Os mais lentos depois dele: `economy_sim_test` 55 s, `tray_test` 49 s, `bench_test` 42 s,
`station_tray_test` 42 s, `animals_test` 40 s, `nature_test` 39 s, `garden_picnic_test` 31 s. Todos os demais
ficam abaixo de 25 s (tabela completa em `build/test_logs/tiro00/baseline.csv`, gerada na etapa 00).
Fora da suíte (não estão no `test_all.ps1`): `festival_test` 23 s (passa) e `economy_checkpoint_test` 3 s (falha).

## Simulação

Nenhuma etapa roda simulação de economia, exceto: etapa 11 (`economy_sim_test`, porque o robô precisa
aprender a crescer) e etapa 17 (uma execução rápida com `-Quick`). O Vitor simula quando quiser.
