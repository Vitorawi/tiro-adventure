# Etapa 05 — Missões (três abas) e prêmios

> Tamanho: grande. Depende de: 04. Próxima: 06.
> Resultado que o Vitor vê: a aba Missões com **História · Pessoas · Diárias** separadas (decisão do Vitor),
> no visual novo; ao concluir um passo da história sobe a **folha de prêmio** (fala de quem deu, prêmios que
> contam, próximo passo e "Ir para…"); todo prêmio voa até as moedas/Mochila.

## 1. Ler antes
`02_JORNADA.md` §2 (pílula, que a 03 criou), §3 (abas), §4 e §4.1 (prêmios); `03_TELAS.md` "Missões";
protótipos `prototipo/missoes2_historia.png`, `missoes2_personagens.png`, `missoes2_diarias.png`,
`missoes_premio.png` (folha) e o HTML `prototipo/missoes2.html`.

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Tela | `scenes/ui/tasks_screen/tasks_screen.gd` (255) / `.tscn` | `%GroupTabs` (segmented `story`/`characters`/`timed`, botões `NotebookTab_<id>` com `NewBadge`), `%Holder` + `%Scroll`, `LiveBox` reconstrói em `state_changed`; legenda "! = prêmio pronto para pegar"; `_story_card` (`StoryCard`, chip do capítulo → `story_panel`, `_step_dots`, `_quest_body`, `SharedQuestGuidance`); `_characters` (cartão `Character_<npc>` com `CharacterOpen_<npc>` "Abrir/Fechar"; aberto mostra `LineCard_<line>`); `_routines(kind)` (`Routines_<kind>`, `Routine_<kind>_<id>`, `ClaimAllRoutines` com ≥ 2 prontas); funções públicas `choose_group(id)`, `choose_character(npc)`, `choose_routine(kind)` |
| Peças de missão | `scripts/ui/progression_ui.gd` | `quest_action(box, id, primary)` (Ir / Pegar prêmio / Liberar espaço + "?"), `quest_card`, `routine_card(box, kind, id, primary)`, `claim_routine_rows(host, entries)` (pega, emite `Events.items_gained(itens, moedas, origem)`, encolhe a linha), `story_panel()`, `goal_row(goal, value, px)`, `reward_chips(rewards)`, `current_goal(id)`, `quest_go_target(id)` |
| Concluir missão | `main.gd._on_quest_completed(id)` | aviso de texto "Missão concluída! Próximo: …" (ou "<npc> te deu: <item>! Crescimento → Dar." para `keepsake`) e `_schedule_announce()` (fim de capítulo/Novo!) |
| Fim de capítulo | `scenes/ui/celebration/celebration.gd` `show_chapter(index, unlocks)` | cartão grande com confete |
| Voo dos prêmios | `scripts/ui/collect_fx.gd` (`Events.items_gained` → ícones +N; moedas voam até `Hud.coins_target()`) | missão **não** voa (só diárias) |
| Testes | `tasks_test` (história, personagens recolhidos, `choose_character`), `tasks_groups_test` (abas cabem nas 3 resoluções, `NotebookTab_*` com `NewBadge`, personagem recolhido, diárias × semanais separadas), `lists_test` (`ClaimAllRoutines`, linha some ao pegar), `journey_test`, `navigation_test` | mudam junto (§6) |

## 3. Passo a passo

### 3.1 Estrutura da tela (`tasks_screen`)
1. Margem de cima 136 (linha 2 do HUD com a pílula do próximo passo, que a 03 já põe em todas as abas).
   Sem título "Missões" e **sem a legenda** "! = prêmio…".
2. `%GroupTabs`: `UiKit.segmented` novo (02) com ids **`story`, `characters`, `timed`** (mantidos), textos
   **"História", "Pessoas", "Diárias"**, ícones (`tab_tasks`; retrato de quem tem prêmio pronto ou da Bloblo;
   `ctl clock`), `count` = prêmios prontos da aba. Os botões continuam `NotebookTab_<id>`; o selo continua
   `NewBadge`. Some a aba `characters` quando não houver missão de personagem; some `timed` antes de
   `routines_unlocked("daily")`.
3. **"Pegar tudo (N)"** vai para a linha 2 do HUD (`Hud.set_row2_right`) quando a aba é `characters` ou
   `timed` e N ≥ 2 (só o que é daquela aba). Nós: `ClaimAllRoutines` (Diárias) e `ClaimAllCharacters`
   (Pessoas). Ao sair da aba Missões, `set_row2_right(null)`.

### 3.2 Aba História
1. `StoryCard` (cartão 20): `section("Capítulo")` em `HONEY_INK` + nome do capítulo (`StrongLabel`) +
   `UiKit.steps(total, atual)`; retrato 56 + `SpeechBubble(dialogue, "", inside_card = true)`; para cada
   objetivo, faixa `PAPER` com ícone 32, nome (`goals[].label` ou o do `goal_row`), barra `SKY` e `n/m`;
   prêmios em `chip(..., "prize")`; à direita `?` (`ctl_button("help")` → `TaskHelp.open("quest", id)`) e **uma**
   ação verde pequena: `Ir →` (andando: `Places.go(quest_go_target(id))`) ou `Pegar` (pronto:
   `claim_quest_fx`, §3.5). Depósito cheio: `lock_hint` com o ícone do depósito e "Liberar espaço".
2. Passo que aponta para personagem (`shared_with`): o cartão mostra a missão da linha (rosto e fala do
   personagem) e, no lugar do Ir, `soft("Ver em Pessoas")` (`choose_group("characters")` e expande a linha).
   O texto `SharedQuestGuidance` continua existindo (uma linha curta: "A história segue com a <nome>").
3. **Neste capítulo** (`ChapterSteps`): `section("Neste capítulo", "n de m")` + `list_card` com uma linha por
   passo do capítulo atual (`GameState.progress.main_quests(index)`): feito = `ctl check` em disco
   `GO_SOFT` + nome em `INK_SOFT`; atual = fundo `HONEY_SOFT` + nome em `INK`; futuro = `ctl lock` + nome a
   50%. Nós `ChapterStep_<id>`. Linhas não são tocáveis (o atual já está no cartão de cima).
4. `StoryFull`: `ghost("História completa ›")` → `Events.sheet_requested.emit("História", story_panel())`.

### 3.3 Aba Pessoas
1. `list_card` com **uma linha por missão ativa** de personagem (`_character_quests()` como hoje, achatado),
   prontas primeiro. Linha (`UiKit.list_row`): retrato 44, nome da missão, ícone do objetivo + `n/m`
   (`GO_INK` quando pronto), à direita `chip(coin, "+N", "prize")` + `ctl chev`, ou `small_go("Pegar")`.
   Nome do nó da linha: **`LineCard_<line>`** (mantido).
2. Toque na linha (fora do Pegar) **expande ali mesmo** (`LineDetail_<line>`, 0,2 s, uma por vez): objetivos
   com barra, todos os prêmios, `?` e `soft("Ir →")`. O `›` gira 90°.
3. Compatibilidade: mantenha a **função** `choose_character(npc)` (expande a primeira linha daquele
   personagem; chamar de novo recolhe). Os nós `Character_<npc>` e `CharacterOpen_<npc>` deixam de existir
   (não crie nós vazios só para teste); os testes mudam para a forma nova (§6).
4. Linha nova: selo `Nova` mel no retrato enquanto `progress.seen["ui:quest_new:<id>"]` não existir; marcar
   como visto ao sair da aba.

### 3.4 Aba Diárias
1. `section("Hoje", chip(time))` + `list_card` de `Routine_daily_<id>`; `section("Semana", chip(time))` +
   `list_card` de `Routine_weekly_<id>`. Os dois blocos continuam `Routines_daily` / `Routines_weekly`.
2. Linha: `UiKit.ring(ícone do objetivo, valor/alvo, SKY ou GO, 44)`, nome (sem a descrição), `n/m`
   embaixo, prêmio em chip + `›`, ou `small_go("Pegar")`. Toque expande (`RoutineDetail_<kind>_<id>`) com a
   descrição de uma linha e `soft("Ir →")`.
3. `choose_routine(kind)` continua existindo: rola a lista até a seção daquele período.
4. Tudo feito no período: linha única com `ctl check` e "Tudo feito por hoje!" / "Tudo feito nesta semana!".

### 3.5 Pegar com voo (`ProgressionUi.claim_quest_fx`)
```gdscript
## Pega o prêmio da missão; se deu certo, faz os prêmios voarem de `origin` (ponto global).
## Devolve "" ou o motivo (já avisado). Não muda regra: só chama GameState.claim_quest.
static func claim_quest_fx(id: String, origin: Vector2) -> String
```
Lê `Database.quests[id].rewards` **antes**, chama `GameState.claim_quest(id)`; se `""`, emite
`Events.items_gained(rewards.items, rewards.coins, origin)`; senão `Events.notice_requested.emit("error",
motivo, "")`. Use em: `quest_action` (botão Pegar), linhas de Pessoas, `NextStep` (03) e conversa com
personagem (`ProgressionUi.quest_card`). `ClaimAllCharacters` pega as prontas da aba uma a uma (80 ms entre
elas), cada uma voando da sua linha.

### 3.6 Destinos do voo (`CollectFx` → destinos de 02 §4.1)
Moedas → `Hud.coins_target()` (já existe; a pílula ganha contorno mel 0,6 s). Itens → centro da almofada
da aba Mochila (`NavTab.icon_center()` da `BagTab`), que dá `bounce_icon()` na chegada. Se a Mochila estiver
escondida (antes da história apresentá-la), itens sobem e somem no lugar (como hoje).

### 3.7 Folha de prêmio (`scenes/ui/quest_reward/quest_reward.gd/.tscn`, `class_name QuestReward`)
1. Quando: **passo da história** concluído (`kind == "main"`) e **não** fechou capítulo. Montada pela fila
   modal (`main._queue_modal`), depois do voo (espere `Motion.FLY`).
2. Forma: folha baixa com margem 8 dos lados e de baixo, canto 28 nos quatro, fundo `PAPER`, véu `SCRIM`
   atrás; alça 40×5; fecha arrastando para baixo (> 25% da altura ou > 900 px/s, como o `Sheet`) ou no X.
3. Conteúdo (nós): `RewardRibbon` (pílula `GO` com `ctl check` + "Passo concluído!" `StrongLabel` branco) +
   `RewardClose` (X); `RewardSpeech` = retrato 56 do `npc` + `SpeechBubble` com a fala — o `dialogue` do
   **próximo** passo (`current_main_quest()` depois de pegar); se vazio, a `greeting` do personagem;
   `RewardChips` = chips grandes (altura 44, ícone 36, `HONEY_SOFT`) que contam com `Motion.count_up`, um por
   moeda/item (`RewardChip_coins`, `RewardChip_<item>`; item `keepsake` ganha `UiKit.spark()`); `section("Próximo
   passo")` + `NextStepCard` (cartão branco: ícone 40 do objetivo, nome, onde em `SmallLabel` — o nome do lugar
   de `Places.quest_target`, `n/m`); botões `RewardLater` (`soft("Depois")`) e `RewardGo` (`primary("Ir para
   <lugar>")`, `Places.go(Places.quest_target(próximo))`).
4. Sem próximo passo (história acabou): sem `NextStepCard`; botão único `primary("Que bom!")`.
5. Vibração `Haptics.success()` ao abrir. `Motion.reduced`: aparece parada, números já no valor final.

### 3.8 `main.gd`
1. `_on_quest_completed(id)`: `main` sem capítulo → enfileira `QuestReward.open(id)`; capítulo fechado no
   mesmo passo → **só** o cartão do capítulo (`show_chapter`), que ganha no rodapé a linha do próximo passo
   (`NextStepCard` reaproveitado) e o botão `Ir`; `line` (personagem) → nada além do voo. O texto "Missão
   concluída! Próximo: …" **sai**; o caso `keepsake` vira o chip com ✦ na folha (ou um aviso `info` curto
   "Laís te deu: <item>" quando for missão de personagem).
2. Nunca dois cartões de uma vez: a fila modal já serializa; confira que folha + Novo! saem nessa ordem.

### 3.9 Tour
Bloco `--i2-05-only`: `i2_05_story` (passo andando), `i2_05_story_shared` (passo que aponta para a Bloblo),
`i2_05_people` (2 prontas + 2 andando), `i2_05_people_open` (linha expandida), `i2_05_daily` (Hoje + Semana,
uma pronta), `i2_05_reward` (folha depois de `talk_to("lais")` e pegar `welcome`), `i2_05_chapter` (fim de
capítulo com próximo passo).

## 4. Não fazer
- Mudar prêmios, objetivos, ordem ou falas das missões.
- Juntar as abas (o Vitor pediu separadas).
- Abrir janela para diárias ou missões de personagem (são prêmio pequeno: só voo).

## 5. Armadilhas
- `LiveBox` reconstrói tudo em `state_changed`: guarde a linha expandida e a aba em variáveis da tela, não
  em nós (como `_npc` hoje).
- `claim_routine_rows` já marca `ui_animating` no `LiveBox` para não reconstruir no meio do voo: use o mesmo
  cuidado em `claim_quest_fx` quando chamado de uma linha.
- A folha de prêmio entra na fila modal: se o jogador pegar pela pílula no Mapa, a folha aparece no Mapa;
  "Ir para…" usa `Events.world_requested` como sempre.
- `show_chapter(index, unlocks)` recebe `Array[String]` tipado.
- Capítulo fechado por missão de **personagem** (via `shared_with`): o `chapter_completed` chega igual; a
  regra "só o cartão do capítulo" vale também.

## 6. Testes

**`game/tests/quest_reward_test.gd`** (área `story`):
1. Save novo; `talk_to("lais")`; pegar `welcome` pelo `StoryCard` (botão Pegar): `QuestReward` aparece
   **uma** vez; `RewardChip_coins` mostra "+5" e `RewardChip_dog_food` "+2"; moedas +5 e ração +2 no
   `GameState` (uma vez só).
2. `Events.items_gained` foi emitido uma vez, com a origem dentro do `StoryCard` (escute o sinal).
3. `NextStepCard` mostra `lais_feed`; `RewardGo` emite `world_requested` para o alvo de `lais_feed`.
4. `RewardLater` fecha a folha sem perder nada (moedas continuam, `lais_feed` é o passo atual).
5. Pegar de novo (chamar a ação de novo) não paga de novo e não abre folha.
6. Último passo do capítulo 1 (`dev_complete_quest` até `growth_1_puppy` ficar como atual e deixá-lo pronto
   pelo `dev_set_phase("puppy")` ou equivalente): pegar abre **só** o cartão do capítulo, com o próximo passo
   no rodapé, e **nenhuma** `QuestReward`.
7. Missão de personagem pronta (ex.: a primeira da Bloblo com `dev_*`): pegar pela linha em Pessoas não abre
   folha; `items_gained` emitido; a linha some.
8. Erro (depósito cheio para o prêmio): `quest_reward_shortage` não vazio → o botão é "Liberar espaço" e
   nada é pago.

**Atualizar** (mesma garantia, nova forma):
- `tasks_groups_test`: abas continuam `NotebookTab_*` e cabem nas 3 resoluções; "personagem com prêmio tem
  exclamação" → "aba Pessoas tem selo e a linha pronta tem `Pegar`"; "personagem começa recolhido" → "linha
  começa recolhida (`LineDetail_*` ausente)" e `choose_character` expande/recolhe; "diárias × semanais
  separadas" → "as duas seções existem na aba Diárias e `choose_routine('weekly')` rola até `Routines_weekly`".
- `tasks_test`: "personagens agrupados por nome" → "uma linha por missão de personagem, com o retrato do
  personagem"; "missões recolhidas até abrir" → "detalhe recolhido até tocar"; o resto igual.
- `lists_test`: `ClaimAllRoutines` agora está na linha 2 do HUD (procure no `main`, não no `tasks`); a
  frase da diária ("Colha os canteiros do sítio.") continua inteira, mas dentro da linha **expandida**
  (`RoutineDetail_daily_harvest`): expanda antes de conferir; "três diárias ocupam menos de 300 px" continua.
- Testes que procuravam o texto "Missão concluída" no `Toast`: passam a procurar a `QuestReward` (história)
  ou o voo (personagem).

**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests quest_reward_test,tasks_test,tasks_groups_test,lists_test,navigation_test,journey_test,next_step_test` (~2 min 10).

## 7. Capturas
`--i2-05-only` antes (use `--lists-only`/tour da aba Missões como "antes") e depois nas 3 resoluções; compare
com `missoes2_*.png` e `missoes_premio.png`.

## 8. Pronto quando
- [ ] As três abas como no protótipo, com selos; nenhuma legenda/instrução extra.
- [ ] Toda forma de pegar (Pegar tudo, linha, cartão, pílula, conversa) faz os prêmios voarem.
- [ ] Passo da história → folha de prêmio; fim de capítulo → só o cartão grande; personagem/diária → só voo.
- [ ] Do save novo até o fim do capítulo 1 seguindo só pílula + folha (conferido à mão e registrado).
- [ ] Testes verdes; `CLAUDE.md`/`AGENTS.md` atualizados (`QuestReward`, `claim_quest_fx`, abas).

## 9. Registro
```
**Etapa 05 (data, executor):** Missões em 3 abas (História/Pessoas/Diárias) no visual novo, ChapterSteps,
linhas com sanfona, Pegar tudo na linha 2, claim_quest_fx (voo em toda forma de pegar), QuestReward, capítulo
com próximo passo, aviso "Missão concluída" removido. Testes … PASS em … s. Pendências: …
```
