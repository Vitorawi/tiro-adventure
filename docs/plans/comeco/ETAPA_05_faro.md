# Etapa 05 — Faro do Tiro (achados no mapa, álbum e o mapa rasgado)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_05_faro.md."
> Pré-requisito: Etapas 00–04 feitas.

## Objetivo (o que o jogador sente)
"O Tiro é um farejador! De vez em quando ele sai correndo, cheira o chão e eu cavo um tesouro."
Surpresa pequena e frequente (A Short Hike, Animal Crossing) + álbum com conjuntos (Stardew) +
um mistério: pedaços de um mapa do tesouro. Resolve D6.

## Como funciona (para o jogador)
1. Num mundo com faro liberado, a cada alguns minutos o Tiro **vai até um ponto, cheira o chão e
   senta abanando o rabo**; ali aparece um **montinho de terra brilhando**.
2. Tocar no montinho (ou no Tiro sentado ao lado): o Tiro **cava** (~0,8 s) e o achado salta na
   tela (`CollectFx`).
3. Achado novo no álbum → cartão curto "Novo achado!" (ícone 64 px, nome, `3/16`). Repetidos só saltam.
4. App fechado: o tempo corre, mas fica no máximo **1 montinho esperando por mundo**. Entra no
   cartão "Que bom que você voltou!" (Etapa 01) como "🐾 1 achado no Sítio [Ir]".
5. O álbum fica na tela do Tiro, botão **Coleção** (já existe), que ganha abas no topo:
   **Roupas · Achados** (Etapas futuras acrescentam "Passeios" e "Amigos"). Não encontrados = silhueta
   escura do ícone. Cada mundo é um **conjunto** de 4 achados; completo → botão **Receber**.
6. O primeiro achado do jogo é garantido e especial: **mudas de morango** ("O Tiro achou mudas de
   morango!") — libera o morango.
7. Os **pedaços do mapa** (1 a 4) vêm em achados garantidos de cada mundo; a aba Achados mostra a
   moldura do mapa com os pedaços encaixados (`1/4`). O que o mapa revela fica para a Etapa 11.

## Leia antes
`scenes/levels/room/room.gd` (`_spawn_*`, `_handle_tap`, `point_at`, `_collect_site`),
`scenes/entities/dog_world/dog_world.gd` (`react_at`, `_show_reaction`, `_play`),
`scripts/ui/collect_fx.gd`, `scripts/ui/sheet_builder.gd` (`inventory_view`, coleção),
`scripts/ui/progression_ui.gd` (painel de coleção), `game/scripts/util/loot.gd` (Etapa 00).

## Passo a passo

### 5.1 Itens (`items.json`): 16 achados + 4 pedaços
Todos com `"category": "find"`, `"storage": "none"`, `"icon": "res://assets/sprites/ui/icons/item_<id>.png"`.
| id | Nome | Venda | Mundo | Raro? |
|---|---|---|---|---|
| `old_horseshoe` | Ferradura velha | 6 | farm | |
| `hen_feather` | Pena colorida | 6 | farm | |
| `grandma_button` | Botão da vovó | 8 | farm | |
| `old_coin` | Moeda antiga | 40 | farm | ✔ |
| `lost_ball` | Bolinha perdida | 6 | park | |
| `bone_keychain` | Chaveiro de osso | 8 | park | |
| `shiny_pebble` | Pedrinha brilhante | 8 | park | |
| `dog_tag` | Medalhinha | 40 | park | ✔ |
| `marble` | Bolinha de gude | 8 | village | |
| `old_ticket` | Bilhete antigo | 8 | village | |
| `silver_spoon` | Colher de prata | 12 | village | |
| `pocket_watch` | Relógio de bolso | 50 | village | ✔ |
| `pinecone` | Pinha | 6 | nature | |
| `creek_shell` | Concha do riacho | 8 | nature | |
| `owl_feather` | Pena de coruja | 10 | nature | |
| `fossil` | Fóssil | 60 | nature | ✔ |
`map_piece_1..4` "Pedaço do mapa N": `category: "find"`, `storage: "none"`, **sem** `sell_price`,
ícone único `item_map_piece.png` (o número aparece por cima na UI).
- [ ] Mochila (`SheetBuilder.inventory_view`): categoria nova "Achados" (ícone `find_paw`).
- [ ] Achados **não** entram na geladeira (`_fits_fridge` já filtra por categoria; confira).

### 5.2 Dados — `game/data/finds.json` (novo)
```json
{
  "settings": {"dig_seconds": 0.8, "first_delay": 20},
  "worlds": {
    "farm": {
      "interval": 480, "max_pending": 1,
      "requirements": {"quests": ["first_harvest"]},
      "guaranteed": [
        {"unlocks": ["crop:strawberry"], "label": "Mudas de morango", "icon": "item_strawberry"},
        {"items": {"old_horseshoe": 1}},
        {"items": {"map_piece_1": 1}}
      ],
      "table": [
        {"weight": 30, "coins": [3, 8]},
        {"weight": 20, "items": {"carrot": [1, 2]}},
        {"weight": 12, "items": {"dog_food": 1}},
        {"weight": 10, "items": {"old_horseshoe": 1}},
        {"weight": 10, "items": {"hen_feather": 1}},
        {"weight": 8,  "items": {"grandma_button": 1}},
        {"weight": 3,  "items": {"old_coin": 1}},
        {"weight": 2,  "items": {"bolt": 1}}
      ]
    },
    "village": {
      "interval": 600, "max_pending": 1,
      "requirements": {"chapter": 4},
      "guaranteed": [{"items": {"marble": 1}}, {"items": {"map_piece_3": 1}}],
      "table": [
        {"weight": 35, "coins": [5, 12]},
        {"weight": 14, "items": {"marble": 1}},
        {"weight": 12, "items": {"old_ticket": 1}},
        {"weight": 8,  "items": {"silver_spoon": 1}},
        {"weight": 3,  "items": {"pocket_watch": 1}},
        {"weight": 3,  "items": {"bolt": 1}}
      ]
    },
    "nature": {
      "interval": 600, "max_pending": 1,
      "requirements": {"chapter": 5},
      "guaranteed": [{"items": {"pinecone": 1}}, {"items": {"map_piece_4": 1}}],
      "table": [
        {"weight": 25, "coins": [4, 10]},
        {"weight": 15, "items": {"wood": [1, 2]}},
        {"weight": 10, "items": {"stone": [1, 2]}},
        {"weight": 14, "items": {"pinecone": 1}},
        {"weight": 12, "items": {"creek_shell": 1}},
        {"weight": 9,  "items": {"owl_feather": 1}},
        {"weight": 3,  "items": {"fossil": 1}}
      ]
    }
  },
  "sets": {
    "farm_set":    {"name": "Tesouros do sítio", "world": "farm",
                    "items": ["old_horseshoe", "hen_feather", "grandma_button", "old_coin"],
                    "rewards": {"coins": 60, "items": {"bolt": 1}, "collections": ["digger_bandana"]}},
    "village_set": {"name": "Tesouros da vila", "world": "village",
                    "items": ["marble", "old_ticket", "silver_spoon", "pocket_watch"],
                    "rewards": {"coins": 100, "items": {"bolt": 1}}},
    "nature_set":  {"name": "Tesouros da trilha", "world": "nature",
                    "items": ["pinecone", "creek_shell", "owl_feather", "fossil"],
                    "rewards": {"coins": 120, "items": {"iron_band": 1}, "collections": ["explorer_hat"]}}
  }
}
```
- [ ] A **Praça** (`park`) entra na Etapa 06 com o conjunto `park_set` (achados `lost_ball`,
  `bone_keychain`, `shiny_pebble`, `dog_tag`; pedaço `map_piece_2`). Os itens da praça já são
  criados agora (5.1) para o álbum mostrar as silhuetas; o mundo da praça só é adicionado ao `finds.json` na Etapa 06.
- [ ] `crops.json → strawberry.requirements` → `{"quests": ["bloblo_dig"]}` (a missão abaixo fecha
  com o primeiro achado, que também dá o `unlocks`).
- [ ] `collections.json`: `digger_bandana` "Bandana de farejador" (neck, ícone `find_paw`) e
  `explorer_hat` "Chapéu de explorador" (head, ícone `tab_map`), `sprite: ""` por enquanto.

### 5.3 Estado — `game/scripts/state/find_state.gd` (novo, `class_name FindState`)
```
worlds: Dictionary   # "<mundo>": {"next_at": float, "pending": int, "spot": int, "dug": int}
claimed_sets: Array  # ids de conjuntos recebidos
```
O álbum é **derivado** do contador `find_item:<id>` (não guarde de novo).

### 5.4 Ações no `GameState`
- [ ] `update_finds()` (ao carregar, no timer de atualização e após `_changed`): para cada mundo do
  `finds.json` com requisitos ok:
  - primeira vez → `next_at = now + settings.first_delay`;
  - se `now >= next_at` e `pending < max_pending` → `pending += 1`, `spot` sorteado entre os
    `dig_spots` da sala (semente `int(next_at)`), `next_at = now + interval`.
  - offline: gera no máximo `max_pending` (não acumula vários).
- [ ] `dig_error(world)` (`"Nada para cavar aqui"`, espaço cheio via `storage_error`) e
  `dig(world) -> Dictionary`:
  - recompensa = `guaranteed[dug]` se existir; senão `Loot.roll(table, 1, semente)`;
  - aplica (`_apply_rewards`, inclusive `unlocks`), `pending -= 1`, `dug += 1`;
  - contadores `find`, `find:<mundo>` e `find_item:<id>` para cada item;
  - devolve `{"items": ..., "coins": ..., "label": ..., "icon": ..., "new": [ids novos no álbum]}`;
  - `Events.items_gained(...)` a partir da posição do montinho.
- [ ] `find_set_progress(id)`, `find_set_error(id)`, `claim_find_set(id)`.
- [ ] `available_actions()`: tipo `dig` com `world` e alvo `find`.
- [ ] Dev: `dev_spawn_finds()` (guarda `BuildInfo.is_dev()`) põe 1 pendente em cada mundo liberado;
  botão no `DevPanel` ("Achados agora").

### 5.5 Mapa
- [ ] `rooms/farm.json`, `rooms/village.json`, `rooms/nature.json`: lista `"dig_spots"` com 6–10
  pontos **no chão alcançável**, longe de portas, canteiros, objetos e NPCs (confira com uma captura
  com todos os pontos marcados — faça um modo dev que desenha os pontos).
- [ ] `RoomView`: cria um nó `DigSpot` (Sprite2D `areas/fx/dig_spot.png` + brilho piscando com tween
  de `fx_sparkle.png`) quando `finds[mundo].pending > 0`. Toque no montinho (raio generoso, 28 px na
  tela) → `GameState.dig(mundo)` → o Tiro corre até lá, toca `dig` e o achado salta. O toque responde
  **na hora** (não espere o Tiro chegar para dar o item).
- [ ] `DogWorld`: quando um montinho aparece com a sala visível → `react_at(&"sniff", ponto)`: vai até
  lá, toca `sniff` (2 s) e fica sentado (`sit`) ao lado até cavar ou até 20 s.
- [ ] `RoomView.point_at("find")` aponta o montinho (Ir das missões `find`).
- [ ] O Tiro não fareja dormindo.

### 5.6 Missão, diária, semanal, "Novo!"
- [ ] `quests.json` (linha da vovó, entre `first_harvest` 20 e `bloblo_more_crops` 30):
```json
"bloblo_dig": {
  "npc": "bloblo", "name": "Faro de ouro",
  "dialogue": "Olha o Tiro cavando ali! Vai ver o que ele achou.",
  "goals": [{"type": "stat", "key": "find", "target": 1, "label": "Cavar onde o Tiro farejou"}],
  "rewards": {"coins": 10},
  "kind": "line", "line": "bloblo", "order": 25
}
```
- [ ] Ordem nova da vovó no começo: conversa (10) → plantar/regar/colher (20) → **cavar (25)** →
  colher 3× (30) → morango (35) → cenouras (40)...
- [ ] `routines.json → daily.dig`: `{"name": "Cave 2 achados", "description": "Toque onde o Tiro farejou.",
  "goal": {"key": "find", "target": 2}, "rewards": {"coins": 12}, "requirements": {"quests": ["bloblo_dig"]}}`.
- [ ] `routines.json → weekly.digger_week`: `{"name": "Farejador", "description": "Cave 10 achados nesta semana.",
  "goal": {"key": "find", "target": 10}, "rewards": {"coins": 100, "items": {"bolt": 1}, "collections": ["digger_bandana"]},
  "requirements": {"quests": ["bloblo_dig"]}}`.
- [ ] `progression.json → features.finds`: `{"name": "Achados do Tiro", "icon": "find_paw",
  "go": {"screen": "pet"}, "requirements": {"quests": ["bloblo_dig"]}}` (mostra o álbum como "Novo!").
- [ ] `Places.goal_target`: `find`/`find:<mundo>` → mundo com montinho pendente (ou o sítio) + `find`.
- [ ] Cartão "Que bom que você voltou!": linha de achados pendentes por mundo.

### 5.7 Arte
**Animações do Tiro do mapa** (receita "Animação nova do Tiro do mapa", personagem `8e4e8b4d-…`):
| Pasta | action_description | frames |
|---|---|---|
| `tiro_world/sniff/east/` | "small dog sniffing the ground, nose low, head moving left and right, tail wagging" | 8 |
| `tiro_world/dig/east/` | "small dog digging the ground fast with both front paws, little dirt clumps flying behind" | 8 |
Confira os nomes dos quadros com os de `tiro_world/sit/east/` e adicione `"sniff"`/`"dig"` onde o
`DogWorld` monta as animações (`_build_frames`; `dig` em loop).

**Montinho** — `create_object_pro_flash`: `n_directions: 1`, `view: "low top-down"`, `width: 32`, `height: 24`,
`style_image` = `areas/farm/farm.png` ("match palette, outline and shading of this farm ground"),
description "small mound of freshly dug brown soil with a few pebbles, isometric 3/4 view, cute, pixel art, no background".
→ `areas/fx/dig_spot.png`.
**Brilho** — `create_image_pixen` 16×16, `no_background: true`, description "tiny four-pointed yellow sparkle star, pixel art"
→ `areas/fx/fx_sparkle.png` (o piscar é feito por tween no código).

**Ícones 32×32** (receita "Ícone 32×32"; descrição = "game inventory icon: <texto>, cute, bold outline, centered, no text"):
| Arquivo | texto |
|---|---|
| `find_paw.png` | "brown paw print with three tiny yellow sparkles" |
| `item_old_horseshoe.png` | "old rusty iron horseshoe" |
| `item_hen_feather.png` | "colorful hen feather in orange and teal" |
| `item_grandma_button.png` | "big round wooden sewing button with four holes and a tiny flower painted" |
| `item_old_coin.png` | "ancient gold coin with a worn dog face engraving and a shine" |
| `item_lost_ball.png` | "slightly chewed yellow-green tennis ball" |
| `item_bone_keychain.png` | "small white bone-shaped keychain with a silver ring" |
| `item_shiny_pebble.png` | "small round lilac pebble with a white shine" |
| `item_dog_tag.png` | "golden heart-shaped dog tag on a tiny ring, shining" |
| `item_marble.png` | "glass marble with a blue and orange swirl inside" |
| `item_old_ticket.png` | "old yellowed paper ticket with a red stripe" |
| `item_silver_spoon.png` | "small ornate silver spoon with a shine" |
| `item_pocket_watch.png` | "golden pocket watch with an open lid and chain" |
| `item_pinecone.png` | "brown pinecone" |
| `item_creek_shell.png` | "small spiral freshwater shell, cream and brown" |
| `item_owl_feather.png` | "soft striped brown and white owl feather" |
| `item_fossil.png` | "beige stone with a spiral ammonite fossil imprint" |
| `item_map_piece.png` | "torn piece of old parchment treasure map with a red dotted path and part of an X" |

## Testes — `finds_test.gd` (novo, no `test_all.ps1`)
- [ ] Antes de `first_harvest`: sem achados. Depois: 1 pendente em ~20 s.
- [ ] 1º achado do sítio = mudas (libera `crop:strawberry`, missão `bloblo_dig` pronta); 2º = ferradura; 3º = `map_piece_1`.
- [ ] Nunca mais de 1 pendente por mundo; 2 h offline → 1.
- [ ] Sorteio estável ao recarregar; contadores `find`, `find:farm`, `find_item:<id>`.
- [ ] Conjunto: incompleto → erro; completo → recompensa uma vez.
- [ ] Armazenamento cheio (cenoura no silo, se houver silo) não some com o montinho.
- [ ] `dev_spawn_finds` desligado na prod (`dev_tools_test -- --prod`).
- [ ] `onboarding_test`: primeiro achado ≤ 9 min.

## Capturas
Tiro farejando + montinho no sítio; "Novo achado!"; Coleção → Achados (silhuetas, conjunto quase
completo, moldura do mapa 1/4); Mochila → Achados; cartão de volta com achado.

## Lista de conferência (aceite)
- [ ] Por volta do minuto 8 o Tiro fareja sozinho e o jogador cava as mudas de morango.
- [ ] O álbum é bonito e mostra o que falta por silhueta.
- [ ] Achados funcionam no Sítio, Vila e Natureza.
- [ ] CLAUDE.md/AGENTS.md (linha "Faro do Tiro": `finds.json`, `FindState`, `dig_spots`), `docs/WORLDS.md`
  (`dig_spots`), `docs/GAME_DESIGN.md`, ROADMAP, ART_PIPELINE, README; commit.
