# Etapa 03 — Aba Desejos do Tiro (e o vínculo)

> **Mensagem para o Sonnet:** "Leia CLAUDE.md, docs/plans/comeco/00_VISAO.md,
> docs/plans/comeco/01_REGRAS_E_ARTE.md e execute docs/plans/comeco/ETAPA_03_desejos.md."
> Pré-requisito: Etapas 00–02 feitas.

## Objetivo (o que o jogador sente)
"O Tiro tem vontades! Ele me pede comidinhas e carinho, eu faço na cozinha e entrego, e a gente fica
mais amigo." É o quadro de pedidos do Hay Day, só que do **próprio cachorro**. Liga o bichinho à
produção (resolve D2).

## Como funciona (para o jogador)
1. Depois de pôr a caminha (`lais_bed`), surge a tela **"Novo! Desejos do Tiro"** e uma **aba nova
   na barra de baixo**: **Desejos** (ícone `tab_wishes`, coração num balão). Ordem das abas:
   **Tiro · Desejos · Mapa · Missões · Mochila**.
2. A aba mostra até **3 cartões de desejo** (espaços). No começo só 1 espaço está aberto; o 2º abre
   com **vínculo 2** e o 3º com **vínculo 4** (espaço fechado mostra cadeado + "❤ 2").
3. Cada cartão: ícone grande (64 px) do que ele quer, frase curta ("Quero picolé!"), progresso
   (`tem 0/1` para comida/itens; `1/3` para ações), recompensa em chips (moedas + ❤ afeto) e botões:
   - **Dar** (verde) quando o jogador tem o item → dá na hora, Tiro comemora, recompensa entra;
   - **Receber** (verde) quando um desejo de ação foi cumprido (ex.: 3 carinhos);
   - **Ir** + **?** quando falta algo (Ir leva ao lugar; ? abre o "Como fazer" do `TaskHelp`);
   - **Trocar** (botão pequeno com setas, canto do cartão): troca o desejo por outro. Sem custo; o
     espaço fica esperando **5 min** com um relógio ("Novo desejo em 4:12").
4. Depois de cumprido, o espaço espera **10 min** e aparece outro desejo. Os **3 primeiros desejos**
   do jogo esperam só **1 min** (para ensinar).
5. **Desejos não vencem** e não têm punição.
6. Sobre o Tiro (no mapa e na tela do Tiro) aparece um **balãozinho** com o ícone do primeiro
   desejo que dá para cumprir agora (ou do primeiro desejo, se nenhum der). Tocar no balão (ou no
   Tiro quando tem balão, no mapa) abre a aba Desejos.
7. A aba Desejos tem **badge vermelho** com o número de desejos que dá para cumprir agora.
8. No topo da aba: retrato do Tiro + **chip de vínculo** (`❤ 2` + barrinha até o próximo coração).
   Subir de vínculo abre a comemoração (como a de nível): "Vínculo 3!" + prêmio.
9. **Desejo especial** (5% das vezes, só depois de vínculo 3): moldura dourada, pede uma comida mais
   trabalhosa e dá o dobro.
10. Necessidade baixa tem prioridade ao sortear: higiene < 35 → "Quero um banho"; barriga < 35 →
    "Tô com fome" (qualquer comida); felicidade < 35 → "Quero brincar".

## Leia antes
`scenes/main/main.tscn` + `main.gd` (abas `_tabs`, badges, `features`), `scenes/ui/tasks_screen/`
(estrutura de tela e cartões), `scripts/ui/progression_ui.gd` (`goal_row`, `reward_chips`,
`item_chip`), `scripts/ui/task_help.gd`, `scenes/ui/pet_screen/pet_screen.gd`,
`scenes/entities/dog_world/dog_world.gd`, `scripts/ui/sheet_builder.gd` (`food_picker`),
`game/autoload/game_state.gd` (rotinas: `_ensure_routines`, sorteio por período — copie o estilo).

## Passo a passo

### 3.1 Dados — `game/data/wishes.json` (novo)
Nesta etapa entram **só** os desejos abaixo. Os de etapas futuras são criados nelas.
```json
{
  "settings": {
    "slots": [
      {"requirements": {"quests": ["lais_bed"]}},
      {"requirements": {"bond": 2}},
      {"requirements": {"bond": 4}}
    ],
    "refill_seconds": 600,
    "first_refill_seconds": 60,
    "first_count": 3,
    "swap_seconds": 300,
    "first": "pet",
    "need_threshold": 35,
    "need_wishes": {"hygiene": "bath", "hunger": "food_any", "happiness": "play"},
    "special_chance": 0.05,
    "special_requirements": {"bond": 3},
    "special_multiplier": 2
  },
  "wishes": {
    "pet":      {"type": "action", "name": "Quero carinho", "icon": "action_pet",
                 "goal": {"key": "pet", "target": 3}, "go": "screen:pet",
                 "rewards": {"coins": 5, "affection": 5}, "weight": 3},
    "play":     {"type": "action", "name": "Quero brincar", "icon": "action_play",
                 "goal": {"key": "play", "target": 1}, "go": "screen:pet",
                 "rewards": {"coins": 5, "affection": 5}, "weight": 3},
    "bath":     {"type": "action", "name": "Quero um banho", "icon": "action_bathe",
                 "goal": {"key": "bathe", "target": 1}, "go": "screen:pet",
                 "rewards": {"coins": 5, "affection": 4}, "weight": 1},
    "food_any": {"type": "action", "name": "Tô com fome", "icon": "item_dog_food",
                 "goal": {"key": "feed", "target": 1}, "go": "screen:pet",
                 "rewards": {"coins": 5, "affection": 4}, "weight": 1},
    "carrot":   {"type": "feed", "item": "carrot", "name": "Quero cenoura",
                 "rewards": {"coins": 6, "affection": 5}, "weight": 3,
                 "requirements": {"quests": ["first_harvest"]}},
    "carrot_snack": {"type": "feed", "item": "carrot_snack", "name": "Quero petisco de cenoura",
                 "rewards": {"coins": 12, "affection": 8}, "weight": 4,
                 "requirements": {"owned": ["stove"]}},
    "vegetable_soup": {"type": "feed", "item": "vegetable_soup", "name": "Quero ensopado",
                 "rewards": {"coins": 18, "affection": 10}, "weight": 2, "special": true,
                 "requirements": {"quests": ["bloblo_stew"]}}
  }
}
```
Tipos:
- `action`: cumpre quando o contador `goal.key` sobe `goal.target` desde que o desejo começou
  (guardar a `base` como nas diárias). Depois aparece **Receber**.
- `feed`: "Dar" chama `GameState.feed(item)` e cumpre na hora (uma unidade).
- `give` (usado a partir da Etapa 07): "Dar" consome o item (`inventory.remove`) e cumpre; conta `give:<item>`.
- `special: true`: só entra no sorteio de desejo especial.
- `go`: alvo do Ir para ações (`screen:pet`, ou alvo de lugar como nas missões). Para `feed`/`give`
  o Ir/? vem do `TaskHelp` do item (de onde ele vem).

### 3.2 Estado — `game/scripts/state/wish_state.gd` (novo, `class_name WishState`)
```
slots: Array[Dictionary]  # 3 entradas: {"id": "", "base": 0, "since": 0.0, "ready_at": 0.0, "special": false}
                          # id "" + ready_at > agora = esperando; id "" + ready_at <= agora = pronto para sortear
done_count: int           # quantos desejos já cumpridos (para os 3 primeiros rápidos e estatísticas)
first_done: bool          # o desejo "first" já saiu
```
`to_dict`/`from_dict`/`reset`. O `GameState` guarda em `var wishes: WishState` e salva junto.

### 3.3 Ações no `GameState`
- [ ] `wish_slot_open(i) -> bool` (requisitos de `settings.slots[i]`).
- [ ] `update_wishes()` — chamada ao carregar, no timer de atualização que já existe (o mesmo que
  atualiza a UI) e depois de cada `_changed()`: para cada espaço aberto com `id == ""` e
  `ready_at <= now` → sorteia. Regras do sorteio:
  1. se `first_done == false` → `settings.first` (`pet`);
  2. se alguma necessidade < `need_threshold` e o desejo dela não está em outro espaço → ele;
  3. se vínculo ≥ requisito e `rng < special_chance` → sorteia entre `special: true` elegíveis;
  4. senão sorteio por `weight` entre elegíveis (requisitos ok), **sem repetir** um id que já está
     em outro espaço;
  - semente determinística: `int(ready_at) + i` (mesmo resultado ao recarregar);
  - guarda `base = progress.stat(goal.key)` para `action`; `since = now`.
- [ ] `wish_value(i)`, `wish_target(i)`, `wish_error(i)` (`"Falta <item>"`, `"Faça: <rótulo>"`, `"Espere"`).
- [ ] `fulfill_wish(i) -> String`:
  - `feed`: precisa ter o item; chama `feed(item)` (que já conta `feed` e `feed:<item>`), aplica recompensa;
  - `give`: consome o item, conta `give:<item>`;
  - `action`: precisa `wish_value >= target`;
  - aplica recompensa (× `special_multiplier` se especial), conta `wish` e `wish:<id>`,
    `done_count += 1`, `first_done = true`, `ready_at = now + (first_refill_seconds se done_count <= first_count senão refill_seconds)`;
  - `Events.dog_action.emit(&"wish")` (Tiro comemora) e `Events.items_gained` para a animação.
- [ ] `swap_wish(i) -> String` + `swap_wish_error(i)`: limpa o espaço e `ready_at = now + swap_seconds`.
- [ ] `fulfillable_wish_count() -> int` (badge) e `balloon_wish() -> String` (id para o balão).
- [ ] `available_actions()`: tipo `wish` quando algum desejo dá para cumprir agora.
- [ ] Desejos de `feed`: se o jogador alimentar o Tiro **pela tela do Tiro** com a comida desejada, o
  desejo **não** se cumpre sozinho (precisa tocar em Dar). Simples e claro. (A comida desejada aparece
  primeiro no `food_picker` com um coraçãozinho e o texto "Ele quer!", e tocar nela ali **cumpre o
  desejo** em vez de só alimentar — chame `fulfill_wish`.)

### 3.4 Vínculo
- [ ] `progression.json → bond_levels` (criada na Etapa 00; confira os valores):
```json
"bond_levels": [
  {"affection": 0},
  {"affection": 20,  "rewards": {"coins": 15}},
  {"affection": 50,  "rewards": {"coins": 25, "items": {"carrot_snack": 2}}},
  {"affection": 100, "rewards": {"coins": 40}},
  {"affection": 170, "rewards": {"coins": 60, "items": {"bolt": 1}}},
  {"affection": 260, "rewards": {"coins": 80}},
  {"affection": 380, "rewards": {"coins": 100, "items": {"bolt": 1}}},
  {"affection": 520, "rewards": {"coins": 150}}
]
```
- [ ] Afeto já sobe com carinho (+1) e brincar (+2); desejos dão +4 a +10; recompensas `affection`.
- [ ] `GameState.bond_level()`; `progress.claimed_bond_level` (salvo). Ao subir, aplicar as
  recompensas dos níveis novos e emitir `Events.bond_up(level, rewards)` → comemoração "Vínculo N!".
- [ ] Na tela do Tiro: chip `❤ N` ao lado do texto de humor; tocar mostra barra até o próximo e o que
  libera (espaço de desejo, especiais; nas etapas futuras: passeios e truques).

### 3.5 Tela — `scenes/ui/wishes_screen/wishes_screen.tscn` + `.gd` (nova)
- [ ] Layout de cima para baixo (360×780, rolagem se precisar):
  - cabeçalho: retrato do Tiro 64 px + "O que o Tiro quer" + chip de vínculo com barra;
  - 3 cartões de espaço (componente `wish_card` montado em código com `UiKit`/`ProgressionUi`,
    estilo `CardPanel`; especial = `ReadyCardPanel` com borda dourada e ícone `rare_star` se existir,
    senão estrela de XP);
  - espaço esperando: ícone `timer` + "Novo desejo em 4:12";
  - espaço fechado: cadeado + `❤ 2`.
- [ ] `main.tscn`: botão de aba `%WishesTab` entre `%PetTab` e `%MapTab`, mesma configuração das
  outras abas (`icon_max_width` 28, fonte 18); visível só com `feature_unlocked("wishes")`.
  Com 5 abas na largura 360, confira que nada corta (cada aba ~72 px). Badge igual ao das Missões.
- [ ] `progression.json → features.wishes`:
```json
"wishes": {"name": "Desejos do Tiro", "icon": "tab_wishes", "go": {"screen": "wishes"},
  "requirements": {"quests": ["lais_bed"]}}
```
- [ ] `Events.screen_requested(&"wishes")` abre a aba (confira como o `main.gd` trata `screen_requested`).

### 3.6 Balão sobre o Tiro
- [ ] `DogWorld`: nó filho (Sprite2D) com `wish_bubble.png` + o ícone do desejo por cima (24 px),
  acima da cabeça, balançando (tween de 2 px). Atualiza no `state_changed`. Escondido dormindo.
  Respeita `dog_scale` (no sítio/vila o Tiro é 0,5: o balão deve continuar legível — escala do balão
  = `max(1.0, 1.0 / dog_scale) * 0.5`… teste e ajuste para ~24 px na tela).
- [ ] Toque no Tiro com balão no mapa → `Events.screen_requested(&"wishes")`.
- [ ] `pet_screen`: balão ao lado da cabeça do Tiro grande (64 px), toque abre a aba Desejos.

### 3.7 Missões, diárias e semanais
- [ ] Diária nova (`routines.json`):
```json
"wishes": {"name": "Realize 2 desejos", "description": "Abra a aba Desejos e atenda o Tiro.",
  "goal": {"key": "wish", "target": 2}, "rewards": {"coins": 15},
  "requirements": {"quests": ["lais_bed"]}}
```
- [ ] Semanal nova:
```json
"best_friend": {"name": "Melhor amigo", "description": "Realize 12 desejos do Tiro.",
  "goal": {"key": "wish", "target": 12},
  "rewards": {"coins": 90, "items": {"bolt": 1}, "collections": ["heart_collar"]},
  "requirements": {"quests": ["lais_bed"]}}
```
- [ ] `collections.json → heart_collar`: `{"name": "Coleira de coração", "slot": "neck",
  "description": "Prêmio por realizar muitos desejos.", "icon": "bond_heart", "sprite": ""}`.
- [ ] `Places.goal_target`: chaves `wish`/`wish:<id>` → `screen:wishes` (abre a aba).

### 3.8 Arte (receita "Ícone 32×32" do `01_REGRAS_E_ARTE.md`)
| Arquivo | description |
|---|---|
| `tab_wishes.png` | "game inventory icon: pink heart inside a white thought bubble, cute, bold outline, centered, no text" |
| `wish_bubble.png` | "game inventory icon: empty white thought bubble with two small trailing circles at bottom left, cute, bold outline, no text" (pode precisar ser 32×32 e o ícone do desejo vai por cima em 20 px) |
| `action_pet.png` | "game inventory icon: open hand petting gesture with a small pink heart above it, cute, bold outline, centered, no text" |
| `bond_heart.png` | "game inventory icon: bright red heart with a tiny white paw print in the middle, cute, bold outline, centered, no text" |
- [ ] Troque o ícone provisório de `affection` no `reward_chips` por `bond_heart`.
- [ ] Animação de comemoração: reaproveite `happy_jump`/`wag_excited` da tela do Tiro (`PetAnimator`)
  e no mapa a reação existente (`DogWorld._show_reaction`, tipo novo `&"wish"` = latido + pulinho).

## Testes — `wishes_test.gd` (novo, no `test_all.ps1`)
- [ ] Antes de `lais_bed`: aba escondida, nenhum desejo.
- [ ] Depois: 1 espaço aberto; primeiro desejo = `pet`; 3 carinhos → Receber dá moedas + afeto uma vez.
- [ ] Os 3 primeiros reabastecem em 60 s; o 4º em 600 s (com `dev_advance_time`).
- [ ] `feed`: sem o item → `wish_error` com o nome do item; com o item → Dar consome 1, cumpre, conta `feed:<item>` e `wish`.
- [ ] Trocar: espaço espera 300 s; sem custo.
- [ ] Prioridade: higiene 20 → próximo desejo é `bath`.
- [ ] Sorteio estável: salvar, recarregar → mesmos desejos.
- [ ] Vínculo 2 abre o 2º espaço; não repete o mesmo desejo em dois espaços.
- [ ] Especial só com vínculo ≥ 3; recompensa dobrada.
- [ ] Vínculo: recompensa de nível dada uma vez, comemoração emitida.
- [ ] `onboarding_test`: acrescente `wish` às ações e exija o primeiro desejo cumprido ≤ 7 min.

## Capturas
Aba Desejos com 1 espaço (início); com 3 espaços (dev: vínculo alto) incluindo especial, esperando e
fechado; balão no mapa da casa; balão na tela do Tiro; `food_picker` com "Ele quer!"; comemoração de vínculo.

## Lista de conferência (aceite)
- [ ] Logo após a caminha aparece "Novo! Desejos do Tiro" e a aba nova.
- [ ] O Tiro pede carinho primeiro, depois comidas que o jogador já sabe fazer.
- [ ] Dar é um toque; a festa aparece; o badge some.
- [ ] Nada vence; trocar não custa nada.
- [ ] Vínculo visível na tela do Tiro e na aba; subir de vínculo comemora.
- [ ] CLAUDE.md/AGENTS.md (linha "Desejos do Tiro": `data/wishes.json`, `WishState`, `wishes_screen`),
  `docs/GAME_DESIGN.md` (seção Desejos e Vínculo), ROADMAP, ART_PIPELINE, README; commit.
