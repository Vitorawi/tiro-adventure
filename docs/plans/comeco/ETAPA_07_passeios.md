# Etapa 07 — Passeios: vários caminhos, materiais exclusivos e apetrechos raros

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_07_passeios.md."
> Pré-requisito: Etapas 00–06 feitas (o motor de passeios da Etapa 06 já existe).

## Objetivo (o que o jogador sente)
"Cada passeio é uma pequena aventura. Vou liberando caminhos novos, cada um tem materiais que só
existem lá, e de vez em quando o Tiro volta com uma **coisa rara** para ele vestir!"
É o **foco principal** pedido pelo Vitor. Referências: Pokémon GO / Pikmin Bloom (caminhar rende
itens, com garantia), Animal Crossing (raros por horário), Stardew (coleção por lugar), Neko Atsume (silhuetas).

## Como funciona (para o jogador)
1. **Sete passeios**, liberados aos poucos (por número de passeios, vínculo, mundo aberto e horário).
   No painel aparecem os liberados + **os 2 próximos bloqueados** (apagados, cadeado e o que falta
   em ícone + número: `🐾 4/6`, `❤ 3`, `🕔 17h`).
2. Cada passeio tem **materiais exclusivos** (só aparecem nele) e **um apetrecho raro exclusivo**.
3. **Raro com garantia**: cada passeio tem uma chance pequena de raro e uma "garantia": depois de N
   voltas sem raro naquele passeio, o próximo **com certeza** traz o apetrecho. O diário mostra
   "Raro garantido em até 3 passeios" — o jogador sabe que vai conseguir.
4. **Primeira volta** de cada passeio sempre traz uma porção do material principal dele (o jogador já
   vê para que aquele caminho serve).
5. Ao voltar com raro: o cartão "Volta do passeio" ganha **moldura dourada**, estrela girando,
   "RARO!", o apetrecho em 64 px e o texto "Guardado na Coleção" (a Etapa 08 troca por "Vestir agora").
   Se o apetrecho já é seu, vira um prêmio de consolo (moedas + material).
6. **Diário de passeios** (botão no painel do Passeio): um cartão por passeio com postal, quantas
   vezes foi, materiais (coloridos = já achou, silhueta = ainda não), o apetrecho raro (silhueta até
   achar) e a garantia.
7. **Passeio ao pôr do sol** só pode **começar** entre 17h e 21h (hora do aparelho). Fora disso, o
   cartão mostra "Abre às 17h" com o relógio. (Recolher pode ser a qualquer hora.)

## Passo a passo

### 7.1 Materiais do passeio (`items.json`, `category: "trail"`, `storage: "none"`)
| id | Nome | Venda | Onde aparece | `note` (mostrada no detalhe do item enquanto não houver receita) |
|---|---|---|---|---|
| `stick` | Graveto | 2 | Volta na praça, Rua das flores, Riacho | "O Tiro adora! E serve na costura." |
| `ribbon` | Fita colorida | 6 | Praça, Flores, Feirinha, Pôr do sol | "Serve para costurar apetrechos." |
| `wildflower` | Flor do campo | 4 | Rua das flores, Clareira, Pôr do sol | "Serve para uma coroa de flores." |
| `color_button` | Botão colorido | 4 | Feirinha da Vila | "Serve para costurar roupinhas." |
| `yarn` | Novelo de lã | 6 | Feirinha da Vila | "Serve para tricotar roupinhas." |
| `smooth_pebble` | Pedrinha lisa | 4 | Riacho, Mirante, Pôr do sol | "Bonita para coleiras." |
| `river_shell` | Conchinha | 6 | Beira do riacho | "Serve para uma coleira de conchas." |
| `wild_mint` | Hortelã silvestre | 5 | Clareira, Mirante | "Vira petisco de hortelã." |
| `bird_feather` | Pena de passarinho | 6 | Clareira, Mirante | "Serve para um chapéu de pena." |
| `golden_leaf` | Folha dourada (rara) | 25 | Mirante do morro | "Rara! Serve para a capa dourada." |
| `moon_pebble` | Pedrinha da lua (rara) | 30 | Pôr do sol | "Rara! Só aparece no fim da tarde." |
- [ ] Campo novo opcional `note` em `items.json`; `SheetBuilder.item_detail` mostra a `note` quando o
  item ainda não tem uso conhecido (receita/pedido). Uma linha.
- [ ] Mochila: categoria "Do passeio" (ícone `action_walk`).

### 7.2 Apetrechos raros (`collections.json`)
Formato igual aos existentes (`name`, `slot`, `description`, `icon`, `sprite: ""`), com `"source": "walk:<id>"`:
| id | Nome | slot | description (uma linha) | Passeio |
|---|---|---|---|---|
| `plaid_bow` | Laço xadrez | head | "Achado raro da Volta na praça." | `park_loop` |
| `flower_clip` | Presilha de flor | head | "Achado raro da Rua das flores." | `flower_street` |
| `bow_tie` | Gravata-borboleta | neck | "Achado raro da Feirinha da Vila." | `village_fair` |
| `sailor_scarf` | Lenço de marinheiro | neck | "Achado raro da Beira do riacho." | `creek_walk` |
| `explorer_backpack` | Mochilinha de explorador | body | "Achado raro da Clareira dos passarinhos." | `bird_clearing` |
| `star_glasses` | Óculos de estrelinha | head | "Achado raro do Mirante do morro." | `hill_view` |
| `glow_collar` | Coleira que brilha | neck | "Achado raro do Passeio ao pôr do sol." | `sunset_walk` |
`icon`: `outfit_<id>` (seção 7.9). Coleção → aba Roupas mostra silhueta + "Raro de passeio: <nome do passeio>" com Ir.

### 7.3 Os sete passeios (`walks.json → walks`)
Substitua o `park_loop` da Etapa 06 e acrescente os outros. Formato completo (exemplo do primeiro;
os outros seguem a tabela):
```json
"park_loop": {
  "name": "Volta na praça", "icon": "action_walk", "postcard": "park_loop.png",
  "seconds": 120, "energy": 8,
  "requirements": {"quests": ["nina_meet"]},
  "needs": {"happiness": 20, "hygiene": -10},
  "rewards": {"coins": 6, "affection": 3, "skill_xp": {"adventure": 5}},
  "loot": {
    "rolls": 2,
    "table": [
      {"weight": 40, "items": {"stick": [1, 2]}},
      {"weight": 15, "items": {"ribbon": 1}},
      {"weight": 25, "coins": [2, 6]},
      {"weight": 15, "find": "park"},
      {"weight": 5,  "items": {"dog_food": 1}}
    ],
    "first": {"items": {"stick": 2, "ribbon": 1}},
    "rare": {"chance": 0.08, "pity": 6, "collection": "plaid_bow",
             "duplicate": {"coins": 20, "items": {"ribbon": 1}}}
  }
}
```
| id | Nome | Tempo | ⚡ | 🪙 | Requisitos | Sorteios | Tabela (peso) | `first` | Raro (chance / garantia) |
|---|---|---|---|---|---|---|---|---|---|
| `park_loop` | Volta na praça | 2 min | 8 | 6 | `quests: nina_meet` | 2 | stick 1–2 (40), ribbon (15), moedas 2–6 (25), find park (15), ração (5) | stick 2, ribbon 1 | `plaid_bow` 8% / 6 |
| `flower_street` | Rua das flores | 5 min | 10 | 10 | `stats: walk 3` | 2 | wildflower 1–3 (45), ribbon (15), stick (15), moedas 3–8 (15), find park (10) | wildflower 3 | `flower_clip` 8% / 8 |
| `village_fair` | Feirinha da Vila | 10 min | 12 | 15 | `stats: walk 6` | 2 | color_button 1–2 (35), yarn (25), ribbon (10), moedas 5–12 (20), find village (10) | yarn 2 | `bow_tie` 8% / 8 |
| `creek_walk` | Beira do riacho | 20 min | 15 | 22 | `bond: 3`, `owned: forest_open` | 3 | smooth_pebble 1–3 (35), river_shell 1–2 (30), stick (10), moedas 6–14 (15), find nature (10) | river_shell 2 | `sailor_scarf` 7% / 10 |
| `bird_clearing` | Clareira dos passarinhos | 30 min | 18 | 30 | `stats: walk 15`, `bond: 4` | 3 | wild_mint 1–3 (35), bird_feather 1–2 (30), wildflower (10), moedas 8–18 (15), find nature (10) | bird_feather 2 | `explorer_backpack` 7% / 10 |
| `hill_view` | Mirante do morro | 60 min | 25 | 50 | `stats: walk 25`, `bond: 5` | 4 | bird_feather (30), smooth_pebble (20), wild_mint (15), moedas 10–25 (25), golden_leaf 1 (10) | golden_leaf 1 | `star_glasses` 6% / 12 |
| `sunset_walk` | Passeio ao pôr do sol | 15 min | 12 | 20 | `stats: walk 10`, `hours: [17, 21]` | 3 | smooth_pebble (30), wildflower (20), ribbon (15), moedas 5–12 (20), moon_pebble 1 (15) | moon_pebble 1 | `glow_collar` 10% / 6 |
`needs` ao recolher (todos): `happiness` +20 (curtos) a +40 (Mirante); `hygiene` −10 a −25; `affection` 3 a 8.
`skill_xp.adventure` 5 a 30. Ajuste proporcional ao tempo.

### 7.4 Regras do sorteio (em `GameState.collect_walk`)
1. Semente = `current.seed`; tudo determinístico (recarregar não muda o resultado).
2. Se `history[id].count == 0` → soma `loot.first`.
3. `rolls` sorteios na `table` (`Loot.roll`; `find: <mundo>` resolve na tabela do `finds.json` sem garantidos).
4. **Raro:** `pity[id] += 1`; se `rng < chance` **ou** `pity[id] >= pity` → raro:
   - se o apetrecho ainda não é seu → `progress.collection[id] = true`, contador `walk_rare` e
     `walk_rare:<walk>`; `pity[id] = 0`;
   - se já é seu → aplica `duplicate` (e zera `pity` também).
5. `history[id].count += 1`; contadores `walk`, `walk:<id>`, `walk_item` (total de itens) e
   `walk_item:<item>`.
6. Devolve `{"items", "coins", "rare": "<collection>"|"", "rare_duplicate": bool, "new_items": [...], "first": bool}`.
- [ ] `walk_error(id)` com `hours`: começar só dentro da janela (`requirement_error` já trata `hours`, Etapa 00).
- [ ] `walk_pity_left(id) -> int` (para o diário: `pity - pity[id]`).

### 7.5 Telas
- [ ] **Painel do Passeio** (`ProgressionUi.walks_panel`): cartões ordenados por tempo; liberados
  primeiro; depois só os **2 próximos** bloqueados. Cada cartão: postal 64×40, nome, chips
  `⏱`, `⚡`, ícones dos **materiais exclusivos** (silhueta se nunca achou), ícone do raro (silhueta ou
  colorido com ✓) e botão **Passear** (desabilitado + "?" com o motivo). Botão **Diário** no topo.
- [ ] **Diário de passeios** (`ProgressionUi.walk_diary()`, aberto no Sheet): lista vertical, um bloco
  por passeio: postal 128×80, nome, `🐾 ×12`, fileira de materiais (silhuetas), apetrecho raro
  (silhueta/colorido) e "Raro garantido em até N passeios" (ou "Raro encontrado ✓").
  Passeios ainda bloqueados aparecem como **silhueta do postal** + requisitos (mistério).
- [ ] **Cartão "Volta do passeio"** (Etapa 06) com:
  - "Primeira vez!" quando `first`;
  - etiqueta "Novo!" nos itens nunca vistos;
  - **raro**: moldura dourada (`ReadyCardPanel` com borda dourada), `rare_star.png` girando atrás do
    ícone 64 px, título "RARO!", nome do apetrecho, "Guardado na Coleção"; vibração curta no celular
    (`Input.vibrate_handheld(80)` — ignore se não suportado);
  - consolo: "Você já tem o <nome>! Ganhou <chips>".
- [ ] Coleção → aba **Roupas** (já existe): mostra os 7 raros com silhueta e "Raro de passeio" + Ir
  para o painel do Passeio.
- [ ] Mapa da Praça: ao voltar com raro, o Tiro aparece no `dog_start` com a reação `wish` (pulinho).

### 7.6 Receita e desejos com materiais
- [ ] `items.json → mint_snack`: `{"name": "Petisco de hortelã", "category": "food", "icon": "res://assets/sprites/ui/icons/item_mint_snack.png",
  "sell_price": 22, "trade_xp": 5, "feed": {"hunger": 15, "happiness": 15, "hygiene": 10}}`
- [ ] `recipes.json → mint_snack`: `{"station": "stove", "inputs": {"wild_mint": 2, "carrot": 1}, "output": "mint_snack",
  "qty": 1, "seconds": 120, "skill": "cooking", "skill_xp": 18, "requirements": {"stats": {"walk:bird_clearing": 1}}}`
- [ ] `wishes.json → wishes`:
```json
"stick":      {"type": "give", "item": "stick", "name": "Quero um graveto!", "rewards": {"coins": 6, "affection": 6},
               "weight": 3, "requirements": {"quests": ["nina_walk"]}},
"wildflower": {"type": "give", "item": "wildflower", "name": "Quero cheirar flor", "rewards": {"coins": 8, "affection": 6},
               "weight": 2, "requirements": {"stats": {"walk:flower_street": 1}}},
"mint_snack": {"type": "feed", "item": "mint_snack", "name": "Quero hortelã!", "rewards": {"coins": 18, "affection": 10},
               "weight": 2, "special": true, "requirements": {"stats": {"walk:bird_clearing": 1}}}
```
  (O tipo `give` foi feito na Etapa 03: consome o item e conta `give:<item>`.)

### 7.7 Missões da Nina, diárias e semanais
```json
"nina_routes": {
  "npc": "nina", "name": "Rua das flores",
  "dialogue": "Depois de três voltas, conhece a Rua das flores. Tem flor pra todo lado!",
  "goals": [{"type": "stat", "key": "walk:flower_street", "target": 1, "label": "Passear na Rua das flores"}],
  "rewards": {"coins": 20, "items": {"ribbon": 2}},
  "kind": "line", "line": "nina", "order": 30
},
"nina_rare": {
  "npc": "nina", "name": "Coisa rara",
  "dialogue": "Dizem que nos passeios aparece coisa rara. Me mostra uma?",
  "goals": [{"type": "stat", "key": "walk_rare", "target": 1, "label": "Achar um raro no passeio"}],
  "rewards": {"coins": 30, "affection": 10},
  "kind": "line", "line": "nina", "order": 40
}
```
- [ ] Diária `walk_items`: `{"name": "Ache 6 coisas passeando", "description": "Materiais e achados contam.",
  "goal": {"key": "walk_item", "target": 6}, "rewards": {"coins": 15}, "requirements": {"quests": ["nina_walk"]}}`.
- [ ] Semanal `walker_week`: `{"name": "Passeador", "description": "Faça 10 passeios nesta semana.",
  "goal": {"key": "walk", "target": 10}, "rewards": {"coins": 90, "items": {"ribbon": 3}, "collections": ["walker_bandana"]},
  "requirements": {"quests": ["nina_walk"]}}` + `collections.json → walker_bandana` "Bandana de passeador" (neck, ícone `action_walk`).
- [ ] `progression.json → features.walk_diary`: `{"name": "Diário de passeios", "icon": "action_walk",
  "go": {"world": "park", "place": "walk"}, "requirements": {"stats": {"walk": 3}}}` ("Novo!" quando
  a Rua das flores abre).
- [ ] Tela "Novo!" também quando um **passeio novo** é liberado: some cada passeio às chaves de
  `new_unlocks` (`walk:<id>`) com o postal como ícone e Ir para o painel.

### 7.8 Balanceamento a conferir
- Em ~1 h de jogo na Praça (passeios curtos), o jogador deve conseguir o **primeiro raro** (garantia
  6 na Volta na praça). Simule no `park_test`: 6 voltas → raro garantido.
- Materiais da Etapa 08 (costura) precisam ser alcançáveis: coroa de flores = 3 flores + 1 fita
  (~2–3 passeios na Rua das flores).

### 7.9 Arte
**Postais 128×80** (receita "Cartão-postal"; description começa com "small cozy landscape postcard:"
e termina com ", soft daylight, cute pixel art, no people, no text"):
| Arquivo (`areas/walks/`) | cena |
|---|---|
| `park_loop.png` | (já feito na Etapa 06) |
| `flower_street.png` | "a quiet residential street lined with colorful flower pots, pink bougainvillea over low walls and a cobblestone sidewalk" |
| `village_fair.png` | "a small street fair with striped awnings, fruit crates, colorful bunting flags (bandeirinhas) and yarn baskets" |
| `creek_walk.png` | "a gentle creek with smooth river stones, a tiny wooden bridge, reeds and little shells on the sand bank" |
| `bird_clearing.png` | "a sunny forest clearing with tall grass, wild mint plants, small birds on branches and floating feathers" |
| `hill_view.png` | "a grassy hilltop lookout with a wooden fence, a view of tiny houses far below and golden leaves in the wind" (soft morning light) |
| `sunset_walk.png` | "a calm lakeside path at sunset with orange and purple sky, glowing pebbles on the path and the first stars" (sunset light no lugar de daylight) |

**Materiais e outros ícones 32×32** (receita "Ícone 32×32"; "game inventory icon: <texto>, cute, bold outline, centered, no text"):
| Arquivo | texto |
|---|---|
| `item_stick.png` | "small brown wooden stick with a tiny leaf" |
| `item_ribbon.png` | "curled colorful ribbon in pink and yellow stripes" |
| `item_wildflower.png` | "small bunch of wildflowers, white daisies and purple flowers" |
| `item_color_button.png` | "three colorful sewing buttons, red, blue and yellow" |
| `item_yarn.png` | "ball of soft pink yarn with a loose thread" |
| `item_smooth_pebble.png` | "two smooth flat gray river pebbles" |
| `item_river_shell.png` | "small pink and white scallop seashell" |
| `item_wild_mint.png` | "fresh green mint sprig with round leaves" |
| `item_bird_feather.png` | "small sky-blue bird feather" |
| `item_golden_leaf.png` | "shiny golden autumn leaf with a sparkle" |
| `item_moon_pebble.png` | "small round pale blue pebble glowing softly with a crescent moon mark" |
| `item_mint_snack.png` | "bone-shaped light green dog biscuit with a small mint leaf on top" |
| `rare_star.png` | "golden star with white shine rays" |

**Apetrechos 32×32** (mesma receita; são ícones da Coleção — a roupa no Tiro é a Etapa 08):
| Arquivo | texto |
|---|---|
| `outfit_plaid_bow.png` | "small red and green plaid hair bow" |
| `outfit_flower_clip.png` | "hair clip with a pink flower" |
| `outfit_bow_tie.png` | "small navy blue bow tie with white polka dots" |
| `outfit_sailor_scarf.png` | "blue and white sailor neckerchief scarf" |
| `outfit_explorer_backpack.png` | "tiny brown explorer backpack with a compass badge" |
| `outfit_star_glasses.png` | "star-shaped yellow sunglasses" |
| `outfit_glow_collar.png` | "dog collar with small glowing light blue beads" |
Use também `outfit_<id>` nos `icon` das coleções acima (o `icon` aceita nome de arquivo sem `.png`).

## Testes (amplie `park_test.gd` ou crie `walks_test.gd`)
- [ ] Liberação: Rua das flores só com 3 passeios; Feirinha com 6; Riacho com vínculo 3 + Bosque;
  Clareira com 15 + vínculo 4; Mirante com 25 + vínculo 5; Pôr do sol com 10 e só começa das 17h às 21h
  (simule a hora local).
- [ ] `first` só na primeira volta de cada passeio.
- [ ] Garantia: N voltas sem raro → a N-ésima traz o raro; depois de achado, raro vira `duplicate`.
- [ ] Contadores `walk_rare`, `walk_item`, `walk_item:<item>`; materiais só nos passeios certos
  (nenhum material `trail` aparece em `finds.json`, colheitas ou estações — teste de dados).
- [ ] Sorteio estável ao recarregar no meio do passeio.
- [ ] Diário: silhuetas e "garantido em até N".
- [ ] `content_test`: todo `collection` de raro existe; todo item de tabela existe; postais existem.
- [ ] `onboarding_test`/campanha: chegar ao primeiro raro dentro do limite configurado.

## Capturas
Painel com 3 liberados + 2 bloqueados; Pôr do sol fechado ("Abre às 17h"); Diário; cartão de volta
normal, com "Primeira vez!", com **RARO** e com consolo; Coleção → Roupas com raros em silhueta; Mochila → Do passeio.

## Lista de conferência (aceite)
- [ ] Os passeios abrem um a um, sempre mostrando o que falta para o próximo.
- [ ] Cada passeio tem cara própria (postal, materiais, raro).
- [ ] O primeiro raro chega em no máximo 6 voltas da Volta na praça; a festa do raro é marcante.
- [ ] Nenhum material de passeio aparece em outro lugar do jogo.
- [ ] CLAUDE.md/AGENTS.md (passeios: `walks.json`, sorteio, garantia, diário), `docs/GAME_DESIGN.md`
  (seção Passeios), `docs/PROGRESSION.md`, ROADMAP, ART_PIPELINE, README; commit.
