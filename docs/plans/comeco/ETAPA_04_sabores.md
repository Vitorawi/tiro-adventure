# Etapa 04 — Primeiros sabores (morango, batata-doce, liquidificador)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_04_sabores.md."
> Pré-requisito: Etapas 00–03 feitas.

## Objetivo (o que o jogador sente)
"Tem coisa nova para plantar e cozinhar o tempo todo, e tudo vira mimo para o Tiro."
Resolve D4 e D5. **Regra temática:** tudo que se planta no começo é **seguro para cachorro**
(nada de cebola, alho, uva, chocolate, abacate). O Tiro pede essas coisas nos Desejos.

## Leia antes
`items.json`, `crops.json`, `recipes.json`, `config.json → stations`, `progression.json → upgrades/orders`,
`worlds.json → house`, `rooms/house.json`, `quests.json` (linha `bloblo` e cap. 3 da Laís),
`wishes.json` (Etapa 03), `scripts/ui/sheet_builder.gd` (painel de plantar: ordem das sementes).

## Passo a passo

### 4.1 Itens (`items.json`) — ícones na seção 4.8
```json
"strawberry":   {"name": "Morango", "category": "crop", "icon": "res://assets/sprites/ui/icons/item_strawberry.png",
                 "sell_price": 5, "trade_xp": 2, "feed": {"hunger": 4, "happiness": 6}},
"sweet_potato": {"name": "Batata-doce", "category": "crop", "icon": "res://assets/sprites/ui/icons/item_sweet_potato.png",
                 "sell_price": 8, "trade_xp": 3},
"strawberry_pop": {"name": "Picolé de morango", "category": "food", "icon": "res://assets/sprites/ui/icons/item_strawberry_pop.png",
                 "sell_price": 16, "trade_xp": 4, "feed": {"happiness": 25, "hunger": 5}},
"strawberry_juice": {"name": "Suco de morango", "category": "food", "storage": "fridge",
                 "icon": "res://assets/sprites/ui/icons/item_strawberry_juice.png", "sell_price": 20, "trade_xp": 5},
"mashed_potato": {"name": "Purê de batata", "category": "food", "icon": "res://assets/sprites/ui/icons/item_mashed_potato.png",
                 "sell_price": 18, "trade_xp": 4, "feed": {"hunger": 35, "happiness": 5}},
"sweet_potato_chips": {"name": "Chips de batata-doce", "category": "food", "icon": "res://assets/sprites/ui/icons/item_sweet_potato_chips.png",
                 "sell_price": 30, "trade_xp": 7, "feed": {"hunger": 20, "happiness": 25}}
```
(O suco é para pessoas: não tem `feed`. Ele aparece em pedidos e na entrega à Laís.)

### 4.2 Culturas (`crops.json`)
```json
"strawberry":   {"seconds": 180, "coins": 5, "yield": {"strawberry": 2},
                 "sprite": "res://assets/sprites/areas/farm/crop_strawberry.png", "skill_xp": 15,
                 "requirements": {"quests": ["bloblo_more_crops"]}},
"sweet_potato": {"seconds": 420, "coins": 12, "yield": {"sweet_potato": 2},
                 "sprite": "res://assets/sprites/areas/farm/crop_sweet_potato.png", "skill_xp": 30,
                 "requirements": {"quests": ["farm_deed"]}}
```
- [ ] `pumpkin.requirements` → `{"quests": ["bloblo_pumpkin"]}`.
- [ ] (A Etapa 05 muda o requisito do morango para o primeiro achado do Tiro. Agora fica `bloblo_more_crops`.)
- [ ] Ordem no painel de plantar: do mais rápido para o mais lento entre os liberados
  (cenoura 60 s, trigo 120 s, morango 180 s, milho 180 s, batata 300 s, batata-doce 420 s,
  abóbora 600 s, ervas 900 s). Se a ordem hoje vem do JSON, ordene por `seconds` no `SheetBuilder`.

### 4.3 Liquidificador (estação nova)
- [ ] `config.json → stations.blender`: `{"name": "Liquidificador", "slots": 1, "instruction": "Frutas viram picolé e suco."}`.
- [ ] `progression.json → upgrades.blender`:
```json
"blender": {"name": "Liquidificador", "world": "house",
  "description": "Faz picolé de morango para o Tiro e suco para a Laís.",
  "cost": 30, "requirements": {"quests": ["first_kitchen"]},
  "skill_xp": {"cooking": 10}, "icon": "item_strawberry_pop", "station": "blender"}
```
- [ ] `worlds.json → house.places.stove.panel`: `"stations:stove+blender+oven"` e um lugar oculto:
```json
"blender": {"name": "Liquidificador", "icon": "item_strawberry_pop", "description": "Picolé e suco.",
  "upgrade": "blender", "panel": "station:blender", "hidden": true}
```
- [ ] `rooms/house.json → objects`: o liquidificador fica **em cima da ilha** (sem `footprint`):
```json
{"id": "blender", "action": "place:blender", "upgrade": "blender", "station": "blender",
 "sprite": "res://assets/sprites/areas/house/blender.png", "pos": [318, 236], "approach": [300, 292]}
```
  Ajuste `pos` olhando a captura: deve parecer apoiado no tampo da ilha (a ilha é `slice: true`;
  confira que o liquidificador desenha **na frente** da fatia da ilha — se não, use `z_index`/ordem
  para ficar por cima). Se o "+" da compra ficar escondido atrás da ilha, ajuste a posição do marcador.
- [ ] `StationIndicator` funciona sozinho por ter `station`.

### 4.4 Receitas (`recipes.json`)
```json
"strawberry_pop":   {"station": "blender", "inputs": {"strawberry": 2}, "output": "strawberry_pop", "qty": 1,
                     "seconds": 90, "skill": "cooking", "skill_xp": 12},
"strawberry_juice": {"station": "blender", "inputs": {"strawberry": 3}, "output": "strawberry_juice", "qty": 1,
                     "seconds": 60, "skill": "cooking", "skill_xp": 10},
"mashed_potato":    {"station": "stove", "inputs": {"potato": 2}, "output": "mashed_potato", "qty": 1,
                     "seconds": 90, "skill": "cooking", "skill_xp": 15, "requirements": {"quests": ["bloblo_potato"]}},
"sweet_potato_chips": {"station": "stove", "inputs": {"sweet_potato": 2}, "output": "sweet_potato_chips", "qty": 1,
                     "seconds": 150, "skill": "cooking", "skill_xp": 25, "requirements": {"quests": ["bloblo_sweet_potato"]}}
```
- [ ] `pumpkin_mash.requirements` → `{"quests": ["bloblo_pumpkin"]}`.

### 4.5 Missões
Vovó (`kind: "line"`, `line: "bloblo"`; `order` com folga da Etapa 00):
```json
"bloblo_strawberry": {
  "npc": "bloblo", "name": "Docinho da Laís",
  "dialogue": "Morango é o docinho preferido da Laís. Planta e colhe um pra ela?",
  "goals": [{"type": "stat", "key": "harvest:strawberry", "target": 1, "label": "Colher morango"}],
  "rewards": {"coins": 15, "items": {"dog_food": 2}},
  "kind": "line", "line": "bloblo", "order": 35
},
"bloblo_pumpkin": {
  "npc": "bloblo", "name": "Abóbora gorducha",
  "dialogue": "Agora a abóbora. Demora, mas vira uma papinha que o Tiro adora!",
  "goals": [{"type": "stat", "key": "harvest:pumpkin", "target": 1, "label": "Colher abóbora"}],
  "rewards": {"coins": 20, "skill_xp": {"agriculture": 15}},
  "kind": "line", "line": "bloblo", "order": 55
},
"bloblo_sweet_potato": {
  "npc": "bloblo", "name": "A favorita dos cachorros",
  "dialogue": "Batata-doce é a favorita dos cachorros. Planta no seu terreno novo!",
  "goals": [{"type": "stat", "key": "harvest:sweet_potato", "target": 1, "label": "Colher batata-doce"}],
  "rewards": {"coins": 25, "skill_xp": {"agriculture": 20}},
  "kind": "line", "line": "bloblo", "order": 75
}
```
Laís, capítulo 3 (`lais_stew` já tem `order` 30 após a Etapa 00; o liquidificador entra antes):
```json
"lais_blender": {
  "npc": "lais", "name": "Picolé pro calor",
  "dialogue": "Com um liquidificador, o morango vira picolé pro Tiro!",
  "goals": [{"type": "owned", "key": "blender", "label": "Comprar o liquidificador"}],
  "rewards": {"coins": 10, "items": {"strawberry": 2}},
  "kind": "main", "chapter": 3, "order": 25
}
```
- [ ] `TaskHelp`/`Places.goal_target` já sabem lidar com `harvest:<cultura>` e `owned`; confira.

### 4.6 Desejos novos (`wishes.json → wishes`)
```json
"strawberry":     {"type": "feed", "item": "strawberry", "name": "Quero morango",
                   "rewards": {"coins": 8, "affection": 6}, "weight": 3, "requirements": {"quests": ["bloblo_strawberry"]}},
"strawberry_pop": {"type": "feed", "item": "strawberry_pop", "name": "Quero picolé!",
                   "rewards": {"coins": 15, "affection": 10}, "weight": 4, "requirements": {"owned": ["blender"]}},
"mashed_potato":  {"type": "feed", "item": "mashed_potato", "name": "Quero purê",
                   "rewards": {"coins": 15, "affection": 8}, "weight": 2, "requirements": {"quests": ["bloblo_potato"], "owned": ["stove"]}},
"pumpkin_mash":   {"type": "feed", "item": "pumpkin_mash", "name": "Quero papinha",
                   "rewards": {"coins": 20, "affection": 10}, "weight": 2, "special": true, "requirements": {"quests": ["bloblo_pumpkin"]}},
"sweet_potato_chips": {"type": "feed", "item": "sweet_potato_chips", "name": "Quero chips!",
                   "rewards": {"coins": 25, "affection": 12}, "weight": 2, "special": true, "requirements": {"quests": ["bloblo_sweet_potato"]}}
```

### 4.7 Pedidos na feira e diárias
- [ ] `progression.json → orders`:
```json
"fruit_basket": {"name": "Cesta de morangos", "inputs": {"strawberry": 4},
  "requirements": {"quests": ["bloblo_strawberry"]}, "rewards": {"coins": 26, "skill_xp": {"commerce": 12}}, "cooldown": 120},
"pop_order":    {"name": "Picolés da praça", "inputs": {"strawberry_pop": 2},
  "requirements": {"owned": ["blender"]}, "rewards": {"coins": 45, "skill_xp": {"commerce": 18}}, "cooldown": 240},
"puree_order":  {"name": "Almoço do vizinho", "inputs": {"mashed_potato": 2},
  "requirements": {"quests": ["bloblo_potato"], "owned": ["stove"]}, "rewards": {"coins": 50, "skill_xp": {"commerce": 20}}, "cooldown": 300},
"juice_order":  {"name": "Suco para a Laís", "inputs": {"strawberry_juice": 2},
  "requirements": {"owned": ["blender"]}, "rewards": {"coins": 48, "skill_xp": {"commerce": 18}}, "cooldown": 300}
```
- [ ] `routines.json → daily.missions`:
```json
"blender": {"name": "Faça 2 picolés", "description": "Use o liquidificador da cozinha.",
  "goal": {"key": "produce:strawberry_pop", "target": 2}, "rewards": {"coins": 15}, "requirements": {"owned": ["blender"]}},
"strawberries": {"name": "Colha morango 2 vezes", "description": "Plante morango no sítio e colha.",
  "goal": {"key": "harvest:strawberry", "target": 2}, "rewards": {"coins": 12}, "requirements": {"quests": ["bloblo_strawberry"]}}
```

### 4.8 Arte
**Ícones 32×32** (receita "Ícone 32×32"):
| Arquivo | description |
|---|---|
| `item_strawberry.png` | "game inventory icon: two shiny red strawberries with green leaves, cute, bold outline, centered, no text" |
| `item_sweet_potato.png` | "game inventory icon: purple-skinned sweet potato with a bright orange cut end, cute, bold outline, centered, no text" |
| `item_strawberry_pop.png` | "game inventory icon: pink strawberry popsicle with seeds on a wooden stick, cute, bold outline, centered, no text" |
| `item_strawberry_juice.png` | "game inventory icon: glass of pink strawberry juice with a striped straw and a strawberry slice, cute, bold outline, centered, no text" |
| `item_mashed_potato.png` | "game inventory icon: small blue bowl of creamy yellow mashed potato with a butter pat, cute, bold outline, centered, no text" |
| `item_sweet_potato_chips.png` | "game inventory icon: pile of crunchy orange sweet potato chips in a small paper cone, cute, bold outline, centered, no text" |

**Plantas maduras** (receita "Planta madura no canteiro", referência `crop_carrot.png`):
| Arquivo | description |
|---|---|
| `crop_strawberry.png` | "mature strawberry plant growing from a small dark soil mound, bushy green leaves with five ripe red strawberries hanging, cute farm game crop, isometric 3/4 view, pixel art" |
| `crop_sweet_potato.png` | "mature sweet potato plant growing from a small dark soil mound, heart-shaped green and purple leaves, two purple sweet potatoes peeking out of the soil, cute farm game crop, isometric 3/4 view, pixel art" |

**Liquidificador** — `create_object_pro_flash`:
```
n_directions: 1, view: "low top-down", width: 32, height: 48,
style_image: {"url": "upload:<areas/house/stove.png>", "usage_description": "match palette, outline and shading of this kitchen stove"},
description: "small kitchen blender with a clear glass jar half full of pink strawberry smoothie and a red base,
  isometric 3/4 view, cute, pixel art, no background"
```
Recorte → `areas/house/blender.png`. Deve ficar mais ou menos do tamanho da panela do fogão.
Opcional: `busy_frames` (4 quadros) com `mcp__pixellab__animate_object` ou editando só a faixa do copo
(lição do fogão no `ART_PIPELINE.md`: animar só a parte que muda). Se não ficar bom, deixe sem animação.

## Testes
- [ ] `farm_test`: morango e batata-doce plantam/colhem; ordem do painel por tempo.
- [ ] `content_test`: ícones/sprites existem; receitas apontam estações existentes; nada com `skills` antes do cap. 6.
- [ ] `progression_test` (campanha simulada) passa pelos passos novos; `manual_test` lista o liquidificador e as receitas novas.
- [ ] `wishes_test`: desejo de picolé só com liquidificador.
- [ ] `onboarding_test` continua dentro dos limites.

## Capturas
Painel de plantar com morango; morangueiro maduro; cozinha com liquidificador (antes "+", depois
objeto e trabalhando); aba Desejos pedindo picolé; feira com os pedidos novos.

## Lista de conferência (aceite)
- [ ] Do minuto ~12 em diante sempre há algo novo crescendo ou para fazer na cozinha.
- [ ] O Tiro pede comidas que o jogador consegue fazer.
- [ ] Abóbora e papinha liberadas por missão (sem "Horta nível").
- [ ] ROADMAP, ART_PIPELINE, `docs/PROGRESSION.md` (receitas/culturas), README; commit.
