# F04 — Ato 3: um sistema por capítulo (capítulos 2 a 11)

Plano: `docs/plans/novo_fluxo/README.md` seções 2, 6, 6b e 7; decisões F3, F5, F7. Mapa: `CLAUDE.md`.
Base: F00 (`content_day()` = capítulo; requisito `story_day`), F01 (Ato 1), F02 (relógio/aula/cartela),
F03 (Ato 2: `lais_farm` … `first_meal`; capítulo 1 fecha em `first_meal`; `ato2_done()`; moedas e banca no
capítulo 2; `SAVE_VERSION` 37).

Etapa grande: **duas partes, feitas em sessões separadas, em ordem**. A Parte B termina com o **portão**.

---

## Parte A — Capítulos e fotos de fechamento

### A.1 Ordem nova (seção 6 do plano)

Hoje a semana tem os capítulos 2 a 7 (`week_*`) e o pós-semana começa no 8 (`lais_village`). Reorganize em
**10 capítulos (2 a 11)**, um sistema novo cada, reaproveitando os ids e objetivos que já existem:

| Cap. | Sistema | Passos (reaproveitar) | Fecha com |
|---|---|---|---|
| 2 | Banca: vender, comprar, mais canteiros | `week_market`, `week_plots` + passo novo "fazer a primeira sopinha" (`week_dish:soup`/equivalente; 2º tipo de prato) | foto |
| 3 | Desejo do Tiro | `lais_first_wish` | foto |
| 4 | Galinheiro | `week_coop`, `week_eggs`, `week_egg_dish` | foto |
| 5 | Aula do Tiro: Senta | `week_biscuits`, `week_sit` | foto `h_first_trick` (ajustar o texto se preciso) |
| 6 | Lagoa | `week_bridge`, `week_fish`, `week_fish_dish` | foto `h_week_fish` |
| 7 | Pomar | `week_orchard`, `week_fruit_dish` | foto `h_week_mingau` |
| 8 | Inventar + Livro de receitas | `week_invent` + passo novo "abrir o Livro de receitas" | foto |
| 9 | Carroça do Feirante | `week_cart_order`, `week_bath` | foto `h_week_foam` |
| 10 | Quintal: brincadeiras e show | `week_fetch`, `week_rope`, `week_paw`, `week_down`, `week_show`, `week_hide` | foto `h_trick_show` |
| 11 | Argolinha + almoço de despedida | `teeth_3_ring`, `growth_3_teething` | foto `h_week_group` → **Dentinhos** → Vila |

- Se um capítulo ficar com passo demais, divida o objetivo, nunca junte dois sistemas novos no mesmo capítulo.
  Ajuste o limite de passos do `content_test` se for regra de conteúdo (hoje 8).
- `progression.json → chapters`: nomes novos dos capítulos 2–11 (curtos, ex. "A banca da vovó", "O primeiro
  desejo", "As galinhas", "Senta!", "A lagoa", "O pomar", "Cozinheiro inventor", "A carroça", "O quintal",
  "O primeiro dentinho"). Os capítulos pós-semana (hoje 8 a 12…) passam a **12 em diante**, sem mudar o conteúdo.
- **Renumeração**: todo número de capítulo no conteúdo precisa acompanhar (o conteúdo abre por `content_day()`
  = capítulo). Faça uma tabela "antes → depois" e aplique em **todos** os lugares: `story_day` dos JSON,
  `config.json → farm.fishing_chapter/orchard_chapter`, `trick_settings.*.day`, `growth.json → week_play.days`,
  `dishes.json → opens/max_by_day`, `recipe_book.json → from_chapter`, `week_routine.json` (dia das linhas/cartões),
  `week_tutorials.json → day`, `worlds.json`/`features` com `chapter`, `growth.json → phases[].chapter`, `wishes`
  (`content_day() >= 3` no código), qualquer `chapter:` em requisitos de missões/compras/receitas, e números
  fixos no código (`grep -n "content_day()" game -r`). Liste a tabela no relatório. Cada sistema deve abrir
  **no capítulo em que é apresentado**, não antes (uma coisa por vez).
- Desejos: só aparecem no capítulo 3 (hoje `content_day() >= 3`; confira depois da renumeração).

### A.2 Foto de fechamento em cada capítulo (F5)

O último passo de cada capítulo 2–11 entrega uma **carta fechada** da conquista (o Álbum já existe; a carta fechada
segue as regras do plano das Fotos: chega fechada, abre pelo `CardReveal`). Reaproveite as fotos existentes em
`album.json` (lista acima é sugestão; `h_week_*`, `h_first_trick`, `h_trick_show`, `h_banca`...). Para capítulos sem
foto adequada (banca/sopinha, desejo, galinheiro, inventar), crie fotos novas na seção `story` **reaproveitando
ilustrações existentes** (sem arte nova nesta etapa) e registre cada uma em
`docs/plans/primeira_semana/PROVISORIOS.md` para a arte final depois. O gatilho é o passo do capítulo
(`quest_claimed` com o id), não o dia. Depois da carta aberta, a pílula leva ao próximo capítulo.

### A.3 Testes da Parte A

- Teste novo `game/tests/ato3_chapters_test.gd` (suite + áreas `story`, `week`, `album`): para cada capítulo 2–11,
  com `dev_content_day` no capítulo anterior, confere que o sistema do capítulo **ainda não abriu** e, ao chegar ao
  capítulo, **abriu**; que o último passo entrega a carta fechada; que a Vila só abre com o Dentinhos.
- Ajustar à regra nova (não apagar): `week_story_test` + helper `tests/helpers/week_story_route.gd`, `content_test`,
  `growth_story_test`, `journey_test`, `farm_week_test`, `fishing_*`, `trick_*`, `play_week_test`, `cart_test`,
  `recipe_book_test`, `cook_*`, `week_routine_test`, `week_tutorial_test`, `no_day_gates_test`, `album_*`,
  `ato2_test`, `tasks_test`, `quest_reward_test` e o que mais quebrar. O helper de economia
  `tests/helpers/week_economy_route.gd` também segue a ordem nova (a F05 roda a simulação).

---

## Parte B — Ajudar a pessoa em cada capítulo (feita depois da A)

1. **Lições presas ao passo**: em `week_tutorials.json`, cada lição dispara pelo passo da história em que o
   sistema aparece (`quest`/`after_quest`), não pelo `day`. Uma lição por linha da tabela 6b do plano
   (~25 no total). Remova as que repetem (a mesma coisa dita duas vezes). Toda lição tem página no Manual
   (`GameManual.open("tutorials")`), agrupada por capítulo.
2. **Desafio do dia** (tabela 6b): quando todos os requisitos do Dentinhos estiverem feitos menos as patinhas,
   a pílula do próximo passo mostra o desafio do dia da vovó (já existe em `week_story.json`/`week_challenge`),
   com balão da vovó na primeira vez: "Agora é só esperar as patinhas. Enquanto isso, um desafio!".
   (A missão secreta é a F04b; deixe o gancho pronto: `GameState.only_paws_left()`.)
3. **Placas do Sítio** ("Galinheiro · dia 2", "Lagoa · dia 3", "Pomar · dia 4", "Quando ele crescer"): o texto
   "dia N" é da era do calendário. Esconda a placa de uma área até o capítulo **anterior** ao dela; nesse capítulo
   mostre só "Em breve" (sem número). Áreas da vila/pós-semana: escondidas.
4. **Seletor de mundos**: até o Dentinhos, mostre só os mundos abertos e **um** trancado, a Vila
   ("Quando o Tiro virar Dentinhos"). Praça e Natureza só aparecem quando a Vila abrir.
5. **Balão da aba Missões** (F03): a mão/destaque precisa apontar a **aba Missões** no rodapé, não só a fala.
6. **Ajuda no erro**: confira nos capítulos 2–11 que todo bloqueio leva ao lugar certo (Ir/"Como fazer"), sem
   "Abre no dia N" em lugar nenhum (`grep -rn "dia %d\|no dia" game/scripts game/data`).
7. Capturas `tests/ato3_shots.gd` nas três resoluções (360×780, 390×844, 412×915): início de cada capítulo (pílula +
   mão), a carta de fechamento de 2 capítulos, o Sítio no capítulo 2 (placas), o seletor, o desafio do dia.
   Abrir e conferir.
8. **Portão**: `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level portao -KeepGoing`. Para cada falha,
   rode o teste sozinho (`tools\run_godot_test.ps1`) e classifique como na triagem da F02 (regra antiga → ajustar
   teste; bug → corrigir; carga; antiga). Falhas antigas conhecidas: `blender_position_touch_test`,
   `daily_claim_touch_test`, `food_menu_bounds_touch_test`, `food_order_touch_test`, `tasks_test` ("Humor do Tiro"),
   `tray_test` (estufa), `care_ui_test`, `farm_market_label_test` (carga) e as de 19/11 (`card_reveal`, `festival`,
   `hud_growth`, `missions_actions`, `nature_routes`, `park`, `ready_badges`, `station_tray`, `text_budget`,
   `walk_return`, `world_selector`, `world_view`).

## Regras (as duas partes)

- `SAVE_VERSION` +1 se o formato mudar (saves zerados, sem migração). Textos em JSON, falas de uma linha.
- Testes não dependem da hora real (fixar relógio). Use `-Exact -Jobs 1` nas rodadas de etapa.
- `docs/ROADMAP.md`, `CLAUDE.md` = `AGENTS.md`, "Andamento" do plano: uma linha cada. Sem commit, push ou publicação.

## Pronto quando

- Capítulos 2–11 apresentam um sistema cada, abrem só no seu capítulo, fecham com uma carta, a pessoa sempre sabe
  o próximo toque, e o Dentinhos leva à Vila.
- Testes novos PASS, portão sem falha nova, capturas conferidas nas três resoluções.
