# F03 — Ato 2 com a vovó (passos 9 a 14)

Plano: `docs/plans/novo_fluxo/README.md` seções 2, 4, 5b e 6b; decisões F4. Mapa: `CLAUDE.md`.
Base: F00 (`content_day()`), F01 (Ato 1: `welcome` … `lais_photo`, `ato1_done()`, `story_gate`, roleta por passo,
abas por feature, `SAVE_VERSION` 35) e F02 (virada às 6h, `food_lesson_done()`, `LessonGuide`, aula da comida
presa a `week_story.json → food_lesson.quest`, hoje `first_kitchen`; `PawCard`; `SAVE_VERSION` 36).

## Objetivo

Depois da carta da chegada, a pessoa conhece o Sítio e a vovó, planta a primeira cenoura, ganha o fogão da vovó
e o coloca em casa, faz a primeira papinha e aprende a regra da comida. Uma coisa nova por vez, sempre com a mão
apontando o próximo toque. **Sem moedas e sem banca no Ato 2** (moedas e banca são o capítulo 2).

## Os 6 passos (capítulo 1, depois de `lais_photo` ordem 80)

| Ordem | id | Fala (curta) | Objetivo | Aparece / prêmio |
|---|---|---|---|---|
| 90 | `lais_farm` | Laís: "Vamos conhecer a vovó Bloblo? Ela mora no Sítio." | `open:farm` (abrir o mundo do Sítio) | Sítio no seletor (só Casa e Sítio). Mão: aba Mapa → pílula do mundo → cartão do Sítio |
| 100 | `bloblo_meet` (ou novo id se o atual tiver outro uso; confira) | — (apresentação da vovó, `npcs.json → bloblo.introduction`, já existe) | `talk:bloblo` | Vovó no Sítio com balão "!". Mão nela |
| 110 | `lais_first_crops` (reaproveitar) | Vovó: "Plante cenoura e batata. Crescem rapidinho!" | colher cenoura 1 + batata 1 (já existe) | Dois canteiros com sementes da vovó (já existe). Lição `garden` (já existe). Ao colher a primeira, a **Mochila** aparece com balão "Guardei aqui" (aba no rodapé). Prêmio: 1 `stove_gift` (item novo, "Fogãozinho da vovó"), **sem moedas** |
| 120 | `place_stove` | Vovó: "Leve meu fogãozinho e ponha na sua cozinha." | `owned stove` | Igual à caminha (F01): `upgrades.stove` passa a custar 0 com `materials {stove_gift: 1}`, `verb` "Colocar", requisito o passo 110 pego (tire `owned fridge`). O "+" do fogão na Casa aparece só agora (ajuste o filtro do F01 que só deixa a caminha durante o Ato 1). Mão: Mapa → Casa → "+" → Colocar, só se a pessoa demorar (o gesto já foi ensinado) |
| 130 | `first_kitchen` (reaproveitar, só o Cozinhar junto) | Laís: "Vamos fazer a primeira papinha!" | `together:puppy_mash` 1 | Lição `cook` (já existe) |
| 140 | `first_meal` (novo) | Laís: "Agora é com você: dê a papinha para ele." | `feed:puppy_mash` 1, `fresh` | É aqui que a **aula da comida** acontece: troque `week_story.json → food_lesson.quest` para `first_meal`. Ao pegar: capítulo 1 completo |

- O que hoje é `first_kitchen` (Cozinhar junto + dar) fica dividido em 130 e 140. Confira o `cook_together._give`
  da F02 (manda a papinha para a Mochila e abre o cardápio enquanto a aula não foi dada) com a ordem nova.
- `week_market`, `week_plots` e `week_invent` saem do capítulo 1 e vão para o **começo do capítulo 2**, antes de
  `week_coop` (ordens menores), sem mudar os objetivos. A F04 reorganiza o capítulo 2 em diante; aqui só precisa
  continuar tudo alcançável e o capítulo 2 fechando.
- **Moedas e banca**: a pílula de moedas do HUD e a banca do Sítio (`early_market`: lugar, placa, compras na banca)
  só aparecem no capítulo 2 (`content_day() >= 2` ou requisito `chapter: 2` / passo 140 pego). Nenhum prêmio do
  Ato 2 paga moeda. Os canteiros a mais (compra) também são capítulo 2. Ajuste `ato1_done()`-dependentes que
  revelavam moedas no fim do Ato 1.
- **Aba Missões**: aparece ao fechar o capítulo 1 (passo 140 pego), com um balão curto na aba
  ("Suas missões ficam aqui"), uma vez. Até lá, a pílula do próximo passo é a guia. A Mochila aparece no passo 110
  (veja acima). Ajuste `features.tab_tasks` e `features.bag`.
- Fala-gancho: hoje está em `lais_first_crops`; passe para `lais_farm` (é o primeiro passo depois da carta):
  "Filhotinho come comida de verdade, na hora do almoço e do jantar. Quem planta tudo isso é a vovó Bloblo."
- Mundo `farm`: requisito `story_gate: [lais_photo]` continua (abre ao fim do Ato 1). O seletor mostra Casa e Sítio;
  os outros mundos seguem trancados e escondidos como hoje.
- Item novo `stove_gift`: ícone provisório reaproveitando `station_stove` (sem arte nova), categoria que não
  confunda a Mochila (ex.: `keepsake`/material de presente, como o `bed_gift`).

## Guia (ajudar ao máximo)

Use `week_tutorials.json` + `WeekTutorial` (mão + balão, presos ao passo pelo campo `quest`), como o F01 fez:
passo 90 (Mapa → pílula → Sítio), 100 (tocar na vovó), 110 (`garden`, já existe), 120 (só se ficar parado > ~8 s
fora da Casa: Mapa → Casa → "+"), 130 (`cook`), 140 (a aula da comida da F02). Cada mão aparece uma vez e some ao
agir; a pílula do próximo passo sempre leva ao destino certo (`go` de cada missão / `Places.goal_target`).
Nenhum aviso de erro sem caminho (ex.: "Falta batata" leva ao canteiro).

## Saves, textos, docs

- `SAVE_VERSION` +1, saves zerados. Falas curtas no tom da Laís/vovó, em JSON.
- `docs/ROADMAP.md` (uma linha), `CLAUDE.md` = `AGENTS.md` (uma linha), "Andamento" do plano (uma linha).

## Testes e capturas

- Teste novo `game/tests/ato2_test.gd` (suite + áreas `story`, `farm`, `week`): save novo → Ato 1 pelo helper
  (`tests/helpers/week_story_route.gd → ato_one()`) → passos 9 a 14 pelas ações reais (abrir Sítio, falar com a vovó,
  plantar/colher, colocar o fogão, Cozinhar junto, dar a papinha) e confere: (1) nenhuma moeda e nenhuma banca no
  Ato 2; (2) Mochila aparece no passo 110, Missões só ao fechar o capítulo 1; (3) o "+" do fogão só no passo 120 e
  a compra é grátis com o `stove_gift`; (4) a aula da comida acontece no passo 140 e dá a patinha; (5) capítulo 2
  começa com `week_market` e as moedas aparecem.
- Ajustar à regra nova (não apagar): `ato1_test`, `food_lesson_test`, `meal_rules_test`, `week_story_test` e o
  helper de rota, `growth_story_test`, `quest_reward_test`, `tasks_test`, `tasks_groups_test`, `journey_test`,
  `care_story_test`, `farm_week_test`, `cook_together_test`, `cook_panel_test`, `courage_start_test`, `customers_test`,
  `market_test`, `content_test`, `texts_test`, `no_day_gates_test` e o que mais quebrar.
  Rode a linha de base antes (com `-Exact -Jobs 1`). Falhas anteriores conhecidas: `blender_position_touch_test`,
  `daily_claim_touch_test`, `food_menu_bounds_touch_test`, `food_order_touch_test` (iguais no HEAD), `tasks_test`
  ("Humor do Tiro"), `tray_test` (estufa), `care_ui_test`, `farm_market_label_test` (instável sob carga).
- Testes não podem depender da hora real (virada às 6h, dia da chegada estendido): fixe o relógio.
- Capturas `tests/ato2_shots.gd` (sem `--headless`, 360x780) → `build/screenshots/ato2/`: seletor com Casa e Sítio,
  vovó com "!", conversa, canteiros, balão da Mochila, "+" do fogão na Casa, folha "Colocar" do fogão, Cozinhar junto,
  aula na tigela, balão da aba Missões. Abra os PNGs e confira.

## Pronto quando

- Do fim do Ato 1 ao fim do capítulo 1, tudo guiado, um sistema por vez, sem moeda e sem banca, e a aula da comida
  acontece na primeira papinha.
- Teste novo PASS, afetados PASS ou falha antiga documentada, capturas conferidas. Sem commit, push ou publicação.
