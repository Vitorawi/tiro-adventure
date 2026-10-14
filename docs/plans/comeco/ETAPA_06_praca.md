# Etapa 06 — Mapa novo: a Praça (Nina, Pipoca e o primeiro passeio)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_06_praca.md."
> Pré-requisito: Etapas 00–05 feitas.

## Objetivo (o que o jogador sente)
"Abriu uma pracinha no bairro! Conheci a Nina e a Pipoca e levei o Tiro para passear pela primeira vez."
A Praça abre **depois da Vila** (fim do capítulo 4). Esta etapa cria o mundo, a personagem, a cadela
Pipoca andando e o **motor de passeios** com o primeiro passeio. A Etapa 07 enche os passeios de
conteúdo (vários passeios, raros, materiais). Resolve D8.

## Como funciona (para o jogador)
1. Ao concluir o capítulo 4 (entregar a primeira encomenda), a comemoração do capítulo mostra
   **"Novo! Praça"** (além do portão da Natureza). No Mapa → Mundos aparece **Praça** (entre Sítio e Vila).
2. Na Praça: a **Nina** passeia com a **Pipoca** (vira-lata caramelo) perto dela; balão "!" na Nina.
3. Conversa com a Nina (3 falas de apresentação) → missão: dar a primeira **Volta na praça** com o Tiro.
4. Lugar **Passeio** (portão da praça com etiqueta "Passeio"): painel no padrão de produção:
   - em cima, **1 espaço** (o Tiro é um só): vazio / passeio em andamento (cartão-postal, tempo, barra) / pronto ("Recolher");
   - embaixo, cartões dos passeios (nesta etapa só "Volta na praça": 2 min, ⚡ 8, chips do que pode achar).
5. Durante o passeio **o Tiro sai de casa**: some dos mapas; na tela do Tiro aparece o cartão-postal
   do passeio com o Tiro andando (animação `walk` leste do Tiro do mapa, em escala 2x) e o tempo.
   Comer/brincar/banho ficam desabilitados com o motivo "Tiro está passeando".
6. Quando termina: no mapa da Praça o portão mostra "Recolher" (`StationIndicator`); tocar recolhe:
   **cartão "Volta do passeio"** com o postal, os achados em fila (ícone + quantidade) e o Tiro de
   volta. Ele volta mais feliz (+felicidade), um pouco cansado (−energia) e sujinho (−higiene) →
   aparece desejo de banho (laço com a Etapa 03).

## Leia antes
`game/data/worlds.json`, `rooms/village.json` (modelo de sala externa), `npcs.json`,
`scenes/levels/room/room.gd` (`_spawn_dog`, `_spawn_npcs`), `scenes/entities/npc_world/`,
`scripts/ui/places.gd` (`_panel`), `scripts/ui/sheet_builder.gd` (`slot_frame`),
`scripts/ui/station_indicator.gd`, `scenes/ui/pet_screen/pet_screen.gd`, `docs/WORLDS.md`
(receita de mundo novo — **siga-a**).

## Passo a passo

### 6.1 O mundo (`worlds.json`)
Insira **entre** `farm` e `village` (a ordem do JSON é a ordem da lista):
```json
"park": {
  "name": "Praça", "map_caption": "Passear e fazer amigos", "icon": "tab_park",
  "description": "Passeios com o Tiro, amigos e novidades.",
  "room": "park",
  "requirements": {"quests": ["main_2_order"]},
  "npcs": ["nina", "dog_pipoca"],
  "places": {
    "walk": {"name": "Passeio", "icon": "action_walk", "description": "Passear com o Tiro.", "panel": "walks"},
    "home": {"name": "Voltar para casa", "icon": "tab_house", "description": "", "panel": "travel:house", "hidden": true}
  }
}
```
(Etapas futuras acrescentam `petshop` (08), `friends` (09) e `training` (10). Máximo 4 visíveis:
Passeio, Pet shop, Amigos, Treino.)

### 6.2 A sala (`rooms/park.json`)
- [ ] Fundo `res://assets/sprites/areas/park/park.png` (632×395, seção 6.8).
- [ ] Copie a estrutura de `rooms/village.json`: `floor` (losango que cobre a calçada), `navigation_margin: 8`,
  `dog_scale: 0.5`, `obstacles` (fonte, canteiros, árvores, bancos, quiosque) desenhados sobre o fundo.
- [ ] `zones`:
  - `walk_gate`: polígono do portão/arco de saída, `"action": "place:walk"`, `"label": "Passeio"`, `label_pos` acima;
  - (Etapa 10 acrescenta a zona de treino; Etapa 08 o quiosque.)
- [ ] `points`: `dog_start` (perto do portão), `npc_nina` (perto da fonte), `npc_dog_pipoca` (ao lado da Nina),
  `walk_marker` (onde o `StationIndicator` do passeio aparece, acima do portão).
- [ ] `dig_spots`: 6–8 pontos, metade na **caixa de areia**.
- [ ] `initial_zoom`/`view_center` como na vila, para a praça inteira caber.
- [ ] Gere uma captura com o polígono do chão, obstáculos e pontos desenhados (modo dev) e ajuste até
  o Tiro e a Nina andarem só na calçada, contornando fonte e bancos.

### 6.3 Nina e Pipoca (`npcs.json`)
```json
"nina": {
  "name": "Nina", "role": "Adestradora da praça",
  "portrait": "res://assets/sprites/characters/npc_nina/portrait.png",
  "sprite_dir": "res://assets/sprites/characters/npc_nina/",
  "icon": "action_walk", "greeting": "Bora passear?",
  "requirements": {"quests": ["main_2_order"]},
  "introduction": [
    "Oi! Eu sou a Nina, e essa bagunceira é a Pipoca.",
    "Que yorkshire mais lindo! Passeio todo dia deixa qualquer cachorro feliz.",
    "Aparece sempre que quiser. A Pipoca vai adorar um amigo!"
  ],
  "services": ["walk"]
},
"dog_pipoca": {
  "name": "Pipoca", "role": "Vira-lata caramelo da Nina",
  "portrait": "res://assets/sprites/characters/dog_pipoca/portrait.png",
  "sprite_dir": "res://assets/sprites/characters/dog_pipoca/",
  "icon": "action_walk", "decor": true, "follow": "nina",
  "requirements": {"quests": ["main_2_order"]}
}
```
- [ ] `decor: true` (novo): sem conversa, sem balão, fora da lista de personagens e da aba Missões;
  tocar faz ela latir/pular (reação simples no `NpcWorld`). A Etapa 09 transforma a Pipoca em amiga.
- [ ] `follow: "nina"` (novo): o `NpcWorld` escolhe destinos perto (≤ 40 px) da posição atual da Nina.
- [ ] Cachorros usam animações `walk` (S/E/N) e `idle` (S/E): confira se o `NpcWorld` aceita `idle`;
  se não, use a rotação parada.

### 6.4 Motor de passeios — `game/data/walks.json` (novo)
Nesta etapa só o primeiro passeio. O formato já é o completo (a Etapa 07 usa o resto).
```json
{
  "settings": {
    "slots": 1,
    "postcard_dir": "res://assets/sprites/areas/walks/",
    "away_text": "Tiro está passeando"
  },
  "walks": {
    "park_loop": {
      "name": "Volta na praça", "icon": "action_walk", "postcard": "park_loop.png",
      "seconds": 120, "energy": 8,
      "requirements": {"quests": ["nina_meet"]},
      "needs": {"happiness": 20, "hygiene": -10},
      "rewards": {"coins": 6, "affection": 3, "skill_xp": {"adventure": 5}},
      "loot": {
        "rolls": 1,
        "table": [
          {"weight": 50, "coins": [2, 6]},
          {"weight": 30, "find": "park"},
          {"weight": 20, "items": {"dog_food": 1}}
        ]
      }
    }
  }
}
```
Campos:
- `energy`: gasta essa energia ao **sair**; precisa ter `energy + 5`.
- `needs`: aplicado ao **recolher**.
- `loot.table`: entradas com `coins`, `items` (quantidade número ou `[min, max]`) ou `find: "<mundo>"`
  (= um sorteio da tabela daquele mundo no `finds.json`, sem consumir montinho e sem os garantidos).
- `loot.rolls`: quantas vezes sorteia. (A Etapa 07 acrescenta `first`, `rare`, `materials`.)
- [ ] `Database`: carregar `walks.json` (variável `walks`).

### 6.5 Estado e ações
- [ ] `game/scripts/state/walk_state.gd` (novo, `class_name WalkState`):
```
current: Dictionary   # {"id": "", "started_at": 0.0, "ready_at": 0.0, "seed": 0}
pity: Dictionary      # id -> passeios sem raro (Etapa 07)
history: Dictionary   # id -> {"count": int}   (Etapa 07 usa para o diário)
```
- [ ] `GameState`:
  - `walking() -> bool` (há passeio em andamento, pronto ou não);
  - `walk_error(id)`: requisitos; `"O Tiro já está passeando"`; `"Tiro está dormindo"`;
    `"Tiro está cansado: deixe ele dormir"` (energia < `energy + 5`);
  - `start_walk(id)`: gasta energia (`dog.apply({"energy": -energy})`), grava `current` com
    `seed = int(now)`, `_changed()`;
  - `walk_remaining()`, `walk_ready()`;
  - `collect_walk_error()` / `collect_walk() -> Dictionary`: sorteia `loot` com `Loot.roll` (semente
    `current.seed`), resolve `find:<mundo>` usando a tabela do `finds.json`, checa espaço
    (`storage_error`; se não couber, toast e o passeio continua pronto), aplica recompensas + `needs`,
    contadores `walk`, `walk:<id>`, `walk_item:<item>` (cada item), `find_item:<item>` (para achados do
    álbum), limpa `current`, `Events.items_gained`; devolve o resumo para o cartão de volta;
  - `cancel_walk()` (botão "Chamar de volta" no painel, confirmação com 2 toques): devolve a energia, sem prêmio;
  - `available_actions()`: `walk` (pode sair) e `walk_ready`.
- [ ] Bloqueios enquanto `walking()`: `feed`, `play`, `bathe`, `set_sleeping(true)`, `dig` → erro
  `settings.away_text`. Desejos de comida mostram "Quando ele voltar".
- [ ] `RoomView`: não cria o `DogWorld` enquanto `walking()`; recria quando o passeio é recolhido
  (escute `state_changed`). O Tiro aparece no `dog_start` da sala aberta.
- [ ] Dev: `dev_finish_timers` também termina o passeio.

### 6.6 Telas
- [ ] **Painel `walks`** (novo caso em `Places._panel` → `ProgressionUi.walks_panel()`), no padrão de
  produção (`SheetBuilder.slot_frame`):
  - topo: espaço do passeio (postal 128×80 dentro do quadro, tempo, barra, botão "Recolher" ou "Chamar de volta");
  - lista: um cartão por passeio liberado (postal pequeno 64×40, nome, chips `⏱ 2 min`, `⚡ 8`,
    chips dos achados possíveis (ícones), botão **Passear**). Passeios ainda bloqueados aparecem
    **apagados com cadeado** e o requisito em ícone + número (ex.: `🐾 3/3 passeios`, `❤ 3`) — só
    os 2 próximos bloqueados, para não poluir.
- [ ] **Cartão "Volta do passeio"** (`scenes/ui/walk_result/walk_result.tscn` + `.gd`): postal grande,
  título "De volta da Volta na praça!", fila de achados (ícone 48 + `×N`, com etiqueta "Novo!" se for a
  primeira vez), moedas, ❤, botão "Oba!". Abre no recolher (pelo mapa ou pelo painel).
- [ ] **Tela do Tiro durante o passeio**: no lugar do Tiro grande, o postal (escala 2x, ~256×160) com
  o Tiro do mapa andando para leste por cima (loop), o nome do passeio e o tempo; botões de cuidado
  desabilitados com "?" explicando.
- [ ] **Mapa da praça**: `StationIndicator` no `walk_marker` (tempo / "Recolher"); tocar quando
  pronto recolhe direto (mesmo padrão de `_collect_station`).
- [ ] Cartão "Que bom que você voltou!": linha "Tiro voltou do passeio [Recolher]".

### 6.7 Missões e conteúdo
- [ ] `quests.json` (linha nova `nina`):
```json
"nina_meet": {
  "npc": "nina", "name": "Uma amiga na praça",
  "dialogue": "Oi! Eu sou a Nina, e essa é a Pipoca. Bem-vindos à praça!",
  "goals": [{"type": "stat", "key": "talk:nina", "target": 1, "label": "Falar com a Nina"}],
  "rewards": {"coins": 10},
  "kind": "line", "line": "nina", "order": 10,
  "requirements": {"quests": ["main_2_order"]}
},
"nina_walk": {
  "npc": "nina", "name": "Primeiro passeio",
  "dialogue": "Bora dar uma volta na praça? Toque no portão do passeio!",
  "goals": [{"type": "stat", "key": "walk", "target": 1, "fresh": true, "label": "Passear com o Tiro"}],
  "rewards": {"coins": 15, "items": {"dog_food": 2}, "affection": 5},
  "kind": "line", "line": "nina", "order": 20
}
```
- [ ] `finds.json → worlds.park` (achados de cavar na praça + tabela usada por `find: "park"`):
```json
"park": {
  "interval": 420, "max_pending": 1,
  "requirements": {"quests": ["nina_meet"]},
  "guaranteed": [{"items": {"lost_ball": 1}}, {"items": {"map_piece_2": 1}}],
  "table": [
    {"weight": 30, "coins": [3, 8]},
    {"weight": 15, "items": {"dog_food": 1}},
    {"weight": 15, "items": {"lost_ball": 1}},
    {"weight": 12, "items": {"bone_keychain": 1}},
    {"weight": 10, "items": {"shiny_pebble": 1}},
    {"weight": 3,  "items": {"dog_tag": 1}}
  ]
}
```
  e `sets.park_set`: `{"name": "Tesouros da praça", "world": "park", "items": ["lost_ball", "bone_keychain",
  "shiny_pebble", "dog_tag"], "rewards": {"coins": 80, "collections": ["park_bow"]}}`;
  `collections.json → park_bow` "Laço da praça" (head).
- [ ] Desejo novo (`wishes.json`): `"walk": {"type": "action", "name": "Quero passear!", "icon": "action_walk",
  "goal": {"key": "walk", "target": 1}, "go": "place:park:walk", "rewards": {"coins": 10, "affection": 8},
  "weight": 3, "requirements": {"quests": ["nina_walk"]}}` (ajuste o formato do `go` ao que o
  `Places.goal_target` entende para "mundo + lugar").
- [ ] Diária: `"walk": {"name": "Passeie com o Tiro", "description": "Leve o Tiro para passear na Praça.",
  "goal": {"key": "walk", "target": 1}, "rewards": {"coins": 12}, "requirements": {"quests": ["nina_walk"]}}`.
- [ ] `Places.goal_target`: chaves `walk`/`walk:<id>` → `park` + `walk`; `talk:nina` → `npc:nina`.
- [ ] `content_test`: mundo `park` tem sala, pontos e NPCs válidos; `walks.json` aponta postais existentes.

### 6.8 Arte
**Fundo da Praça** (receita "Fundo de mundo 632×395"), description:
```
cozy small Brazilian neighborhood square (praça): wavy black and white Portuguese stone pavement paths,
a round stone fountain with water in the center, two yellow flowering ipê trees, a green lawn with a flower bed,
three wooden benches, a small sandbox in one corner, an orange training corner with small cones and a low arch,
an empty small kiosk with a striped awning on the right side, a stone arch gate with a small sign at the front-left edge,
street lamp, on a floating isometric island block with dirt edge, same style as reference,
dark empty background, no people, no animals, no text
```
Gere 2–3 e escolha o que tem **calçada larga e livre** para os personagens andarem e o portão bem visível.
→ `areas/park/park.png`.

**Nina** (receita "Personagem humano que anda"), description do `create_character`:
```
young adult female dog trainer, slim adult proportions, warm tan skin, dark curly hair in a high ponytail,
green cap, orange t-shirt, khaki shorts with a small treat pouch on the belt, white sneakers,
friendly cheerful look, full body, cute pixel art
```
Caminhada `walking-8-frames` (skeleton-v3, S/E/N/W) → `characters/npc_nina/rotations/` e `walk/`.
Retrato 64×64 (receita) com description "head and shoulders portrait of a young woman dog trainer with
dark curly ponytail and a green cap, big friendly smile, cute pixel art" → `characters/npc_nina/portrait.png`.

**Pipoca** (receita "Cachorro"), description:
```
Brazilian caramel mutt dog (vira-lata caramelo), short golden-caramel fur, white chest patch, perky ears,
curled happy tail, small cute dog, same size as a yorkshire terrier puppy, pixel art
```
Caminhada + parado (receita) → `characters/dog_pipoca/`. Retrato 64×64 → `characters/dog_pipoca/portrait.png`.

**Postal da Volta na praça** (receita "Cartão-postal 128×80"), description:
"small cozy landscape postcard: a sunny Brazilian square with a fountain, yellow ipê trees and wavy black and
white stone pavement, soft daylight, cute pixel art, no people, no text" → `areas/walks/park_loop.png`.

**Ícones 32×32** (receita):
| Arquivo | texto |
|---|---|
| `tab_park.png` | "green park bench under a small yellow flowering tree" |
| `action_walk.png` | "red dog leash looped with a small golden paw tag" |

## Testes — `park_test.gd` (novo, no `test_all.ps1`)
- [ ] Praça e Nina só aparecem depois de `main_2_order`; "Novo!" lista a Praça.
- [ ] Conversa da Nina (apresentação 3 falas uma vez) → `nina_meet` pronta.
- [ ] `start_walk`: bloqueia dormindo, cansado e passeando; gasta energia; Tiro some das salas.
- [ ] `collect_walk`: antes do tempo → erro; depois → recompensas, necessidades e contadores uma vez;
  sorteio estável ao recarregar; Tiro volta.
- [ ] App fechado: passeio termina sozinho (timestamps).
- [ ] `cancel_walk` devolve energia sem prêmio.
- [ ] `worlds_test`/`navigation_test` com 5 mundos; lista do Mapa cabe em 360×780 (captura).
- [ ] `npc_lines_test`: linha `nina` em paralelo, sem bloquear Laís/Bloblo; `dog_pipoca` não aparece como personagem.
- [ ] `onboarding_test`: estender a simulação até o primeiro passeio recolhido (limite ≤ 60 min).

## Capturas
Lista do Mapa com a Praça; Praça inteira com Nina e Pipoca; conversa da Nina; painel de passeio
(vazio, andando, pronto); tela do Tiro passeando; cartão "Volta do passeio"; casa sem o Tiro durante o passeio.

## Lista de conferência (aceite)
- [ ] A Praça só abre depois da Vila.
- [ ] Nina e Pipoca andam juntas sem atravessar fonte/bancos.
- [ ] Passear tira o Tiro de casa e ele volta com achados, feliz e sujinho.
- [ ] CLAUDE.md/AGENTS.md (mundo Praça, `walks.json`, `WalkState`, `decor`/`follow` de NPC),
  `docs/WORLDS.md`, `docs/GAME_DESIGN.md`, ROADMAP, ART_PIPELINE, README; commit.
