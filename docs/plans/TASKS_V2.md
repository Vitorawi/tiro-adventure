# Plano: Tarefas v2 — história principal + missões secundárias

> Plano escrito pelo Claude Code em 12/10/2026 para o **Codex executar**. Leia o `AGENTS.md` antes.
> Execute as fases **em ordem**, rode os testes ao fim de cada uma e marque o checklist do fim.
> Ao terminar (ou parar no meio), atualize `docs/ROADMAP.md → Estado atual` dizendo até onde chegou.

## 1. Objetivo (pedido do Vitor)
"Gostei bastante da parte de Tarefas, de ter missões principais e secundárias direcionando a pessoa.
Deixa mais claras as missões principais e secundárias, para uma evolução bem clara: as pessoas
entenderem o que têm que evoluir."

Hoje a aba Tarefas (`game/scenes/ui/tasks_screen/tasks_screen.gd`) mostra um "Próximo passo"
(capítulo + construção alvo) e uma lista única de missões misturadas. O problema:
- não existe **história principal** com passos claros: o capítulo diz "compre a geladeira", mas não
  diz o caminho (cozinhar → vender → encomenda → juntar moedas → comprar);
- missões que conduzem a história (`first_sale`, `farm_deed`...) estão misturadas com as opcionais;
- quando falta atributo (ex.: "Culinária 3"), o jogador não sabe **o que fazer para subir**;
- concluir algo não tem comemoração nem diz "próximo: ...";
- os 4 mundos ficam abertos desde o primeiro segundo (muita coisa de uma vez para quem começa).

## 2. Resultado esperado (o que o jogador vê)
```
┌ HISTÓRIA · Capítulo 2 de 8 ───────────────────────┐
│ Nossa primeira cozinha                  ▓▓▓░░ 2/4 │
│ ✓ Preparar um petisco                              │
│ ▶ Vender algo na feira                    [ Ir ]   │  ← passo atual, destacado
│   Dica: Vila → barraca "Vender"                    │
│ ○ Entregar uma encomenda                           │
│ ○ Comprar a geladeira (75 moedas)                  │
│ Ao terminar: +40 moedas · libera a Trilha          │
│ [ Ver a história completa ]                        │
└────────────────────────────────────────────────────┘
┌ PARA EVOLUIR ─────────────────────────────────────┐   (só quando um passo pede atributo)
│ A história pede Culinária 3 (você tem 2: 40/70 XP) │
│ Cozinhe receitas no Fogão — receita nova vale 2x   │
│                                           [ Ir ]   │
└────────────────────────────────────────────────────┘
PRONTOS AGORA          (já existe: colheitas, produções, rota que voltou)
MISSÕES SECUNDÁRIAS · 3 recomendadas      [Ver todas (6)]
  [retrato] Companheiros de trilha · Passeio · 1/3   +lenço   [Ir]
SUA EVOLUÇÃO   [Atributos] [Coleção] [História]
```
- Passo principal concluído → **toast + faixa** "Missão concluída! Próximo: Entregar uma encomenda".
- Capítulo concluído → **tela de comemoração** (painel) com recompensas e o que foi liberado.
- Aba Tarefas: bolinha vermelha = coisas para receber; no começo do jogo a aba **pulsa** até o
  jogador abrir e concluir o primeiro passo ("Comece por aqui!").

## 3. Modelo de dados

### 3.1 `quests.json`: tipo e capítulo
Cada missão ganha:
```json
"kind": "main",          // "main" (história) ou "side" (secundária). Padrão: "side".
"chapter": 2,            // só main: capítulo (1..8)
"order": 3,              // só main: posição no capítulo (1, 2, 3...)
"hint": "Vila → barraca \"Vender\"",   // opcional: texto curto de onde fazer
"category": "commerce"   // opcional (side): atributo da missão, vira a etiqueta colorida
```
- Missões `main` NÃO usam `requires`: a ordem é `chapter` + `order` (uma de cada vez).
- Missões `side` continuam com `requires` e podem pedir `"requirements"` extra
  (ex.: `{"chapter": 3}` = só aparecem a partir do capítulo 3 — ver 3.3).

### 3.2 Objetivos novos (goal `type`)
Além de `stat`, `owned`, `skill`, `deliver`:
| type | key | Conta | Consome? |
|---|---|---|---|
| `coins` | — | moedas atuais ≥ target | não |
| `have` | item | itens na mochila ≥ target | não (diferente de `deliver`) |
| `chapter` | — | capítulo atual ≥ target | não (útil em side) |

Implementar em `GameState.goal_value()`.

### 3.3 `progression.json → chapters`
Cada capítulo passa a listar recompensas e o que libera (o alvo continua existindo):
```json
{ "name": "Nossa primeira cozinha", "description": "...", "target": "fridge",
  "rewards": { "coins": 40, "skill_xp": { "cooking": 20 } },
  "unlocks_text": "Libera a Trilha do riacho" }
```
- **Capítulo concluído = todas as missões `main` dele recebidas** (antes: ter o `target`).
  O último passo de cada capítulo é um objetivo `owned` do `target`, então continua coerente.
- Ao receber o último passo: aplicar `rewards` do capítulo, emitir `Events.chapter_completed(index)`.
- Requisito novo no formato comum: `"requirements": { "chapter": 3 }` = capítulo atual ≥ 3.
  Implementar em `ProgressionState.requirement_error()` ("Disponível no capítulo 3").

### 3.4 Mundos liberados aos poucos (`worlds.json → requirements`)
- Casa e Sítio: abertos.
- **Vila**: `{"quests": ["first_harvest"]}` (abre quando a história manda vender).
- **Trilha**: `{"chapter": 3}` (abre no capítulo do primeiro passeio).
O mapa já mostra mundo fechado com o motivo (`Places.world_error`). Ao abrir um mundo, mostrar no
painel de comemoração: "Novo lugar no Mapa: Vila!".
**Atenção:** missões secundárias e pedidos que dependem desses mundos precisam ter requisitos
compatíveis (ex.: `first_walk` só depois do capítulo 3). A validação da fase 6 pega isso.

### 3.5 Estado e save (v5)
Nada novo para guardar: capítulo e passo atual são **derivados** de `claimed_quests`.
Migração `SaveManager._migrate` v4 → v5 (`SAVE_VERSION := 5`):
- Para cada capítulo cujo `target` o jogador **já possui**: marcar como recebidas (sem dar
  recompensa de novo) todas as missões `main` desse capítulo.
- Missões antigas que viraram `main` e já estavam recebidas continuam recebidas.
- Teste obrigatório: save v4 de quem já tem fogão, geladeira e sítio → abre no capítulo 4, sem
  recompensas duplicadas.

## 4. Conteúdo: a história em passos
Reaproveite as missões existentes (mesmos ids = saves antigos continuam valendo) e crie as que
faltam. Sugestão (ajuste textos e números à vontade; mantenha 3–5 passos por capítulo, objetivos
de UMA coisa só por passo, e diálogo curto na voz do NPC):

| Cap. | Passos (`order`) | id (existente ou novo) | NPC | Objetivo |
|---|---|---|---|---|
| 1 Um novo começo | 1 | `welcome` | bloblo | stat `feed` 1 |
| | 2 | `first_harvest` | bloblo | stat `harvest` 1 |
| | 3 | `main_1_coins` (novo) | bloblo | coins 40 — dica "Colha e venda na Vila" |
| | 4 | `first_kitchen` | bloblo | owned `stove` (tirar o objetivo do petisco daqui) |
| 2 Nossa primeira cozinha | 1 | `main_2_snack` (novo) | bloblo | stat `produce:carrot_snack` 1 |
| | 2 | `first_sale` | merchant | stat `trade` 1 |
| | 3 | `main_2_order` (novo) | merchant | stat `orders` 1 |
| | 4 | `main_2_fridge` (novo) | bloblo | owned `fridge` |
| 3 Um pedacinho de terra | 1 | `first_walk` | guide | stat `activity:lane` 1 |
| | 2 | `main_3_agri` (novo) | bloblo | skill `agriculture` 2 |
| | 3 | `farm_deed` | bloblo | owned `farm` |
| 4 Construindo o futuro | 1 | `main_4_materials` (novo) | artisan | have `wood` 6 (+ outro passo have `stone` 4, ou dois objetivos) |
| | 2 | `main_4_bench` (novo) | artisan | owned `workbench` |
| | 3 | `workshop` | artisan | stat `produce:plank` 2 (tirar o owned daqui) |
| 5 Uma produção de verdade | 1 | `stone_path` | artisan | owned `pickaxe` + stat `activity:quarry` 1 |
| | 2 | `main_5_cooking` (novo) | bloblo | skill `cooking` 3 |
| | 3 | `main_5_bricks` (novo) | artisan | have `brick` 4 |
| | 4 | `main_5_oven` (novo) | bloblo | owned `oven` |
| 6 Nosso lugar na vila | 1 | `market_day` | merchant | stat `orders` 3 |
| | 2 | `main_6_commerce` (novo) | merchant | skill `commerce` 4 |
| | 3 | `own_business` | merchant | owned `stall` + stat `order:building_order` 1 |
| 7 Um mundo de possibilidades | 1 | `main_7_orchard` (novo) | bloblo | owned `orchard` |
| | 2 | `deep_earth` | artisan | deliver `crystal` 2 |
| | 3 | `main_7_greenhouse` (novo) | bloblo | owned `greenhouse` |
| 8 Feito por nós | 1 | `main_8_fabric` (novo) | artisan | stat `produce:fabric` 2 |
| | 2 | `atelier_open` | artisan | owned `atelier` + stat `produce:accessory_set` 1 |

**Secundárias** (`kind: "side"`): `trail_friend` (Passeio), `good_cook` (Culinária), `green_fingers`
(Agricultura). Crie mais 4–6 para cada NPC ter algo opcional, de preferência com **roupa/apetrecho**
de recompensa (`collections.json`) — é o que dá vontade de fazer secundária. Ideias: "Cliente fiel"
(feirante, 10 vendas → avental de feirante), "Pequeno minerador" (guia, 5 mineradas → capacete),
"Banho em dia" (bloblo, 3 banhos → laço), "Mãos habilidosas" (Laís, 10 tábuas → luvas).

Cada missão ganha `"hint"` quando o lugar não for óbvio pelo objetivo (ver 5.2).

## 5. Código

### 5.1 Estado / regras (`ProgressionState` + `GameState`)
- `ProgressionState`:
  - `main_quests(chapter: int) -> Array[String]` (ordenado por `order`);
  - `chapter_index() -> int` (1-based; `chapters.size() + 1` = história completa);
  - `current_main_quest() -> String` (primeira `main` não recebida do capítulo atual, "" no fim);
  - `quest_unlocked(id)`: main → só se for a `current_main_quest()`; side → regra atual (`requires`
    + `requirements`);
  - `current_chapter()` passa a usar `chapter_index()`.
- `GameState`:
  - `goal_value()` com `coins`, `have`, `chapter`;
  - `claim_quest()`: se a missão for o último passo do capítulo → recompensa do capítulo +
    `Events.chapter_completed.emit(index)`; sempre `Events.quest_completed.emit(id)`;
  - nada de lógica de UI aqui.
- `Events`: `signal quest_completed(id: String)` e `signal chapter_completed(index: int)`.

### 5.2 "Onde fazer" de cada objetivo (`Places.goal_target`)
Função nova em `scripts/ui/places.gd`: `goal_target(goal: Dictionary) -> Dictionary`
(`{"world":..., "place":..., "hint":...}`) — é o que alimenta os botões **Ir** e as dicas:
| objetivo | vai para |
|---|---|
| stat `feed` | casa / `bowl` |
| stat `harvest`, `harvest:*` | sítio / `plots` |
| stat `produce:<item>` | lugar da estação da receita que produz o item (`Database.place_with_panel("station:<estação>")`) |
| stat `trade`, `sold` | vila / `sell` |
| stat `orders`, `order:<id>` | vila / `orders` |
| stat `activity:<id>`, `explore` | lugar da rota (`routes:<place>`) |
| stat `bathe`, `play` | aba Tiro (`Events.screen_requested(&"pet")`) |
| owned `<upgrade>` | mundo do upgrade, `buy:<upgrade>` |
| skill `<id>` | o "melhor lugar" do atributo (tabela fixa: agriculture→plots, cooking→stove, building→workbench, commerce→sell, walking→walks, mining→mine, bond→aba Tiro) |
| have/deliver `<item>` | primeira fonte do item (`Database.sources_of` → mesmo mapeamento acima) |
| coins | vila / `sell` |
O campo `"hint"` da missão, se existir, substitui o texto gerado. `"go": {"world","place"}`
opcional na missão substitui o destino (casos especiais).

### 5.3 Aba Tarefas (`scenes/ui/tasks_screen/tasks_screen.gd`)
Reescrever `_build` nesta ordem, um método por bloco (manter o padrão `LiveBox`):
1. `_story_card` — capítulo X de N, barra, lista de passos (✓ feito, ▶ atual, ○ futuro; futuros
   com texto em cinza), botão **Ir** (ou **Receber recompensa** se pronto) no passo atual, dica,
   recompensa do capítulo + `unlocks_text`, botão "Ver a história completa".
2. `_evolve_card` — só se o passo atual tiver objetivo `skill` não cumprido (ou a construção alvo
   pedir atributo): nível atual/necessário, barra de XP, dica de como subir (texto por atributo em
   `progression.json → skills.<id>.how_to`, campo novo) e **Ir** para o melhor lugar.
3. `_ready_now` — manter.
4. `_side_quests` — até 3 recomendadas (prontas primeiro, depois as mais perto de acabar), cada uma
   com retrato do NPC, etiqueta do atributo (`category`, cor de `skills.<id>.color`), progresso,
   recompensa resumida e **Ir**/**Receber**; botão "Ver todas (N)" abre painel com todas as side
   liberadas agrupadas por NPC (+ concluídas recolhidas no fim).
5. `_extras` — Atributos, Coleção, **História** (novo).
- Painel **História** (`ProgressionUi.story_panel()`): todos os capítulos em linha do tempo
  (concluído ✓ com recompensas recebidas; atual com passos; futuros só com nome e "?").
- Atributos (`ProgressionUi.skills_panel`): em cada atributo mostrar "A história pede nível N no
  capítulo X" quando for o caso, e o `how_to`.

### 5.4 Comemoração e guia
- `scenes/ui/celebration/` (cena + script): painel por cima de tudo (z acima do Sheet), aberto
  por `main.gd` ao receber `Events.chapter_completed`: título "Capítulo concluído!", nome,
  recompensas, mundos liberados, botão "Continuar" (fecha) e "Ver próximo passo" (vai para Tarefas).
- `Events.quest_completed` de missão `main` → toast "Missão concluída! Próximo: <título>".
- Primeiro acesso: enquanto `welcome` não for recebida, a aba Tarefas pulsa (tween de escala/cor
  em `main.gd`) e a Tela do Pet mostra um balão "Veja suas tarefas aqui embaixo!". Sem tutorial
  longo: só apontar.
- Badge da aba: somar missões prontas para receber (main + side) às coisas prontas (já existe).

### 5.5 Ferramentas DEV (`scripts/ui/dev_panel.gd`)
- "Pular para o capítulo" deve marcar as `main` dos capítulos anteriores como recebidas
  (`GameState.dev_jump_to_chapter`), e "Concluir missão" respeitar main/side.
- Novo botão: "Concluir passo atual da história".

## 6. Testes (obrigatórios)
- `progression_test.gd`: a campanha simulada deve **seguir a história** (receber sempre a
  `current_main_quest()` quando pronta) e chegar ao fim (capítulo 8 concluído) + todas as side.
- `tests/content_test.gd` (novo) — **validação dos JSON**, falha com mensagem clara se:
  - missão `main` sem `chapter`/`order`, ordens repetidas ou buracos num capítulo;
  - capítulo cujo último passo não tem `owned` do `target`;
  - objetivo com `key` inexistente (item, upgrade, atributo, receita em `produce:`, rota em `activity:`);
  - objetivo sem destino em `Places.goal_target` (todo passo tem que ter botão **Ir**);
  - mundo/NPC/lugar referenciado que não existe (`worlds.json`, `npcs.json`, `services`);
  - missão/pedido/rota que depende de um mundo fechado antes de ele abrir.
- `tests/tasks_test.gd` (novo): sequência (só o passo atual aparece liberado), recompensa de
  capítulo uma vez só, sinais emitidos, migração v4 → v5 (ver 3.5), objetivos `coins`/`have`
  não consomem itens/moedas, `deliver` consome.
- Capturas (`-- --screenshots`): Tarefas no começo, no meio (cap. 4) e no fim; painel História;
  comemoração; missões secundárias "Ver todas".
- Rodar também `farm_test`, `dev_tools_test` (dev e `-- --prod`) e o teste de toque
  (`tools/touch_test.ps1`) passando por Tarefas → Ir.

## 7. Fases (cada uma termina com testes verdes e um commit)
1. **Dados e regras:** `kind/chapter/order`, objetivos novos, `chapter` em requisitos,
   `current_main_quest`, sinais, migração v5. Ainda sem UI nova. Testes: `tasks_test` + campanha.
2. **Conteúdo:** reescrever `quests.json` conforme a seção 4 + `rewards`/`unlocks_text` dos
   capítulos + `how_to` dos atributos + requisitos dos mundos. `content_test` passando.
3. **Onde fazer:** `Places.goal_target` + dicas. `content_test` garante destino para todo objetivo.
4. **Aba Tarefas v2 + painel História + Atributos com "a história pede".**
5. **Comemoração, toast de próximo passo, aba pulsando no começo, badge.**
6. **DEV + capturas + teste de toque + docs** (`docs/PROGRESSION.md` seção missões; `docs/WORLDS.md`
   requisitos de mundos; `AGENTS.md`/`CLAUDE.md` iguais; `ROADMAP.md → Estado atual`).

## 8. Regras que não podem ser quebradas
- Estado só no `GameState`/`ProgressionState`; UI não altera estado direto (ações devolvem "" ou motivo).
- Conteúdo nos JSON; nada de texto de missão no código.
- Toda missão tem caminho alcançável (a campanha simulada prova) e todo passo tem botão **Ir**.
- Save antigo nunca perde progresso nem ganha recompensa em dobro.
- Mobile primeiro: botões ≥ 44 px, nada de texto miúdo em excesso; o cartão da história precisa
  caber na tela de 360×780 sem rolar (passos futuros podem ficar resumidos: "+2 passos").
- GDScript tipado; comentários e textos em português; não ligar threads (Web single-thread).

## 9. Checklist de entrega
- [x] Fase 1 — dados/regras + migração v5 + `tasks_test`
- [ ] Fase 2 — conteúdo da história + secundárias + `content_test`
- [ ] Fase 3 — `goal_target` (todo objetivo com Ir)
- [ ] Fase 4 — Tarefas v2, História, Atributos
- [ ] Fase 5 — comemoração, toast, aba pulsando, badge
- [ ] Fase 6 — DEV, capturas, toque, docs, ROADMAP atualizado
- [ ] Mostrar as capturas ao Vitor e **só publicar (push na main) com o OK dele**
