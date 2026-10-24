# Etapa 03 — Casca: HUD em duas linhas, rodapé preso, próximo passo e avisos

> Tamanho: grande. Depende de: 02. Próxima: 04.
> Resultado que o Vitor vê: HUD novo (avatar com anel mel + "Tiro 3/5" + moedas brancas + engrenagem);
> rodapé claro e translúcido, preso à borda, com o nome embaixo de todas as abas; **a pílula do próximo
> passo da história sempre no topo**, que leva até o lugar e entrega o prêmio; avisos numa fila só.

## 1. Ler antes
`02_JORNADA.md` §1, §2, §2.2, §5; `03_TELAS.md` "Casca"; `01_BIBLIA_VISUAL.md` §C (HUD, rodapé) e §H;
protótipos `tiro_cuidar.png` (HUD), `missoes2_historia.png` (pílula + linha 2), `fogao.png` e
`horta_seta.png` (Mapa), `prancha_rodape.png` (versão **clara**).

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Casca | `game/scenes/main/main.tscn` | `Layout` é `VBoxContainer` (separação −22) com `Screens` (Control) e `TabBar` (`PanelContainer`, `TabBarPanel`, altura 72) → `Tabs` (`HBoxContainer`) → `PetTab`/`MapTab`/`TasksTab`/`BagTab` (`TabButton`); fora do Layout: `TopBar` (Control, 60 de altura, `Hud`), `Sheet`, `UpdateBanner`, `Toast` (`PillPanel` → `Row` → `ToastIcon`/`ToastText`) |
| Lógica da casca | `game/scenes/main/main.gd` (449 linhas) | abas (`_on_tab_pressed`, `show_screen`), selos (`_build_tasks_badge`, `_refresh_tasks_badge`), aviso (`_show_toast`, fila de fotos), fila modal (`_queue_modal`/`_flush_modals`), pulsar da aba Missões (`_refresh_guide`), aviso de momento (`_build_moment_notice`, `_run_moments`, `_fly_moment_icon`), conclusão de missão (`_on_quest_completed` → texto "Missão concluída! Próximo: …") |
| HUD | `game/scripts/ui/hud.gd` (360) | `HEIGHT 60`, avatar 52 com anel 60 (`HudAvatar`, `XpRing`, `LevelBadge`/`LevelLabel`, `AvatarAsk`, `AnimatedBadge`, `GrowthBadge`), direita (`CoinsPill`/`CoinsLabel`, `DevButton`, `SettingsButton`); `refresh(animate)`, `coins_target()`, `show_level_popover()` |
| Abas | `game/scripts/ui/nav_tab.gd` (146) | círculo 52 que sobe 6 px na ativa; `attach`, `bounce_icon`, `lift_node`, `icon_center`, `set_active` |
| Mapa | `scenes/ui/worlds_screen/worlds_screen.gd` | `WorldBar` com `MapButton` (`WorldPill`) em `BAR_TOP = 64`, `PlacesButton`, `NpcRow` (coluna de `NpcFace` à direita); `toast_top()`; `_transition.busy` |
| Consultas de missão | `scripts/state/progression_state.gd` | `current_main_quest()`, `displayed_main_quest()` (resolve `shared_with`), `chapter_index()`, `main_quests(cap)`; `GameState.quest_error(id)`, `goal_value(goal)`, `quest_reward_shortage(id)`, `claim_quest(id)`; `ProgressionUi.current_goal(id)`, `Places.quest_target(id)`, `Places.go(target)`, `TaskHelp.open("quest", id)` |
| Estados que escondem a linha 2 | — | `Sheet.is_open()`, `ActionTray.current` (static), `WorldTransition.busy`, cartões (`_celebration.visible`, `_welcome.visible`, `_walk_result.visible`, `_growth_ceremony.visible`, intro) |
| Testes com medidas da casca | `hud_test.gd` (margem ≥ 64 nas telas; pílula 40; engrenagem 44; ordem `Layout` < `TopBar` < `Sheet`), `world_selector_test.gd:103,151` (`Layout/TabBar`), `station_tray_test.gd:490` e `action_tray.gd:201` (`find_child("TabBar")`) | mantenha os caminhos |

## 3. Passo a passo

### 3.1 Rodapé preso (versão clara)
1. `main.tscn`: `Layout` deixa de ser `VBoxContainer` e vira `Control` de tela cheia (mesmo nome, mesmo
   lugar na árvore). `Screens` ocupa a tela inteira (anchors 15). `TabBar` fica preso embaixo (anchors
   bottom wide), **altura 84** (`offset_top = -84`), `TabBarPanel` (base `BASE_GLASS`, cantos de cima 24,
   sombra para cima), `content_margin` 6/8 em cima, 14 embaixo. Caminhos `Layout/TabBar` e `Layout/Screens`
   continuam valendo.
2. As telas de papel (Tiro, Missões, Mochila) reservam embaixo os 84 px do rodapé (margem inferior do
   conteúdo/rolagem = 96). O **Mapa vai até a borda** (o mundo aparece atrás do rodapé translúcido).
3. `NavTab` refeito: cada aba = coluna com **almofada 60×38** (canto 19) contendo o ícone pixel 32 e o
   **nome embaixo** (`SmallLabel` 12; ativa `INK`, inativa `INK_SOFT`). Ativa: almofada `TAB_ON`, sem subir.
   `lift_node()` passa a devolver a almofada (quem pulsa/pula); `icon_center()` = centro da almofada;
   `bounce_icon()` igual; `set_active(active, animate)` troca a cor em 0,15 s. Constantes antigas
   (`CIRCLE`, `LIFT`...) saem.
4. Selos das abas (`main._build_tasks_badge`): `UiKit.badge(n, edge = Palette.BASE)` no canto de cima à
   direita da almofada (`icon_center() + Vector2(22, -16)`).
5. `main.set_tab_joined(on: bool)`: com `true`, o `TabBar` perde cantos e sombra e ganha uma divisória de
   1 px `BASE_LINE` em cima (a etapa 04 usa para apoiar o botão Cuidar). Padrão `false`.

### 3.2 HUD em duas linhas (`hud.gd`)
1. `HEIGHT := 128` (linha 1: 10–68; linha 2: 76–128). `TopBar` continua filho direto do `Main`, entre
   `Layout` e `Sheet`, `mouse_filter = IGNORE` no fundo.
2. **Linha 1:** `HudAvatar` 58 (disco `CARD`, retrato 40, anel `XpRing` 5 px em `HONEY` = `GrowthUi.fraction`
   do crescimento; `AvatarAsk`, `GrowthBadge`, `AnimatedBadge` mantidos nos cantos do disco) + **`HudProfile`**
   (novo: pílula `CARD` com "Tiro" `StrongLabel`, barrinha `HONEY` 6 px e `feitos/total` `SmallLabel`, onde
   `total` e `feitos` vêm de `GameState.growth_info()` e `GrowthUi.missing(info)`; tocar = mesmo que tocar no
   avatar → `show_level_popover()`) · espaço · `CoinsPill` (pílula `CARD` 40, moeda pixel 28, `CoinsLabel`
   `NumberLabel` 18 com milhar "2.645") · `SettingsButton` (`UiKit.ctl_button("gear", …, 40)`). `DevButton`
   vira selo pequeno vermelho "DEV" encostado embaixo da engrenagem. `LevelBadge`/`LevelLabel`/`XpBar`
   continuam existindo (invisíveis se não couberem: os testes procuram por eles).
3. **Linha 2:** `HBoxContainer` `HudRow2` (margens 12, altura 52): `Row2Left` (recebe o `NextStep`) e
   `Row2Right` (vazio; `Hud.set_row2_right(control: Control)` troca o conteúdo; a 04 põe os anéis das
   necessidades, a 05 o "Pegar tudo"). `Hud.set_row2_inset(px: float)` empurra o `Row2Left` para a direita
   (o Mapa usa para caber a pílula do mundo).
4. Visibilidade da linha 2: `main` mantém um conjunto de bloqueios `main.set_row2_blocker(key: String, on:
   bool)` e um teste a cada 0,2 s (`Timer`) de `Sheet.is_open()`, `ActionTray.current != null`,
   `%WorldsScreen._transition.busy` (crie `WorldsScreen.is_traveling()`), cartões visíveis. Escondida =
   alfa 0 em 0,12 s e `mouse_filter = IGNORE`.
5. Telas de papel: margem de cima do conteúdo = 136 (Missões, Mochila). Tiro: o cenário vai até em cima
   (atrás do HUD); o conteúdo de interface do Tiro começa em 136.

### 3.3 Mapa: pílula do mundo e próximo passo
1. `worlds_screen.gd`: `BAR_TOP := 76`. A `WorldPill` fica à esquerda da linha 2; ao trocar de mundo,
   chame `hud.set_row2_inset(pill.size.x + 8)`; ao sair do Mapa, `set_row2_inset(0)`.
2. No Mapa o `NextStep` usa o modo **compacto** (`compact = true`: retrato 32, ícone 28, sem `›`, largura
   ≤ 140). Garanta que `pílula do mundo + 8 + NextStep` termina antes da coluna `NpcRow` (x ≤ 360 − 12 −
   48 − 8 = 292 em 360 px); se não couber (nome de mundo longo), o `NextStep` mostra só o retrato + número.
3. `PlacesButton` (ícone de lista) passa para baixo dos rostos na coluna da direita (ou some, se a etapa 06
   decidir; aqui só não pode sobrepor).
4. `toast_top()` passa a considerar a linha 2 (o aviso nasce abaixo dela).

### 3.4 `QuestGuide` (novo, `game/scripts/ui/quest_guide.gd`, só consultas)
```gdscript
class_name QuestGuide
extends RefCounted
## Qual passo da HISTÓRIA a pílula mostra e em que estado. Sem estado próprio: lê o GameState.

## {id, npc, goal, value, target, state, shared}; state ∈ "hidden", "progress", "talk", "ready",
## "shared_ready", "blocked_storage".
static func current() -> Dictionary
```
Regras (02 §2): `id = GameState.progress.displayed_main_quest()`; `hidden` se `id == ""` ou
`chapter_index() > Database.progression.chapters.size()`; `shared = id != current_main_quest()`;
`blocked_storage` se `quest_reward_shortage(id)` não vazio; `ready`/`shared_ready` se `quest_error(id) == ""`;
`goal = ProgressionUi.current_goal(id)`; `talk` se `goal.type == "stat"` e `goal.key` começa com `talk:`;
senão `progress`. `value = mini(goal_value(goal), target)`, `target = int(goal.get("target", 1))`,
`npc = quests[id].npc`.

### 3.5 `NextStep` (novo, `game/scripts/ui/next_step.gd`)
1. `class_name NextStep extends Button` (variação `IconButton` sem sombra própria; o fundo é um estilo
   pílula `CARD` com sombra). Nó `NextStep`. Filhos nomeados: `StepFace` (retrato em disco), `StepIcon`,
   `StepCount` (`NumberLabel`), `StepChevron` (`ctl chev`), `StepClaim` ("Pegar" + `ctl check`, só no estado
   pronto). Propriedade `compact: bool`.
2. `refresh()`: lê `QuestGuide.current()`; conectado a `Events.state_changed`. Quando o valor sobe em
   relação ao último mostrado: `Motion.count_up` + `Motion.bounce`. `hidden` → `visible = false`.
   `ready`/`shared_ready` → fundo `GO`, textos brancos, `StepClaim` visível, pulinho a cada 4 s
   (`Motion.bounce`, nada com `Motion.reduced`). `blocked_storage` → fundo `ALERT_SOFT`, ícone do depósito.
3. Toque:
   - `progress`/`talk`/`blocked_storage` → abre o mini-cartão (`NextStep.card(id) -> Control`, estático,
     para testar sem a casca) num `Popover.open(main, self, card, 0.0)` (fica até tocar fora). Conteúdo: 02
     §2.2. Nós: `StepCard`, `StepCardGo` (verde, `Places.go(Places.quest_target(id))` e fecha),
     `StepCardHelp` (`TaskHelp.open("quest", id)`), `StepCardSpace` ("Liberar espaço", só no bloqueio).
   - `ready`/`shared_ready` → `GameState.claim_quest(id)`; erro → aviso de erro (§3.6). **Nesta etapa** o
     resultado de pegar continua o de hoje (aviso "Missão concluída!"); a etapa 05 troca pela folha de prêmio.
4. Some a pulsação da aba Missões no começo do jogo (`main._refresh_guide`, `_tasks_pulse`): o próximo
   passo faz esse papel. Mantenha o resto do `_refresh_guide` (Mochila aparece com a história).

### 3.6 Central de avisos (`game/scripts/ui/notice.gd`)
1. `class_name Notice extends Node`, criado pelo `main` (nó `Notice`). Usa o nó **`Toast`** existente para
   todos os tipos de texto e o **`MomentNotice`** para momento (mesma posição e animação de entrada; os dois
   nunca aparecem juntos).
2. API: `notify(kind: String, text: String, icon: Texture2D = null, on_tap: Callable = Callable())`;
   tipos e tempos (02 §5): `error` 2,0 s (fundo `ALERT_SOFT`, texto `ALERT_INK`, vibração `Haptics.error()`),
   `moment` 1,0 s (`HONEY_SOFT`, depois o voo até o avatar que já existe), `photo` 2,4 s (`CARD`, tocável →
   `AlbumView.open_photo`), `info` 1,6 s (`CARD`).
3. Fila com prioridade `error > moment > photo > info`; um por vez; `error` substitui o que estiver na tela;
   os outros esperam. Nada aparece enquanto um cartão modal estiver visível (mesma regra do
   `_flush_modals`).
4. Posição: logo abaixo da linha 2 do HUD (y = 136) ou de `WorldsScreen.toast_top()` no Mapa.
5. Ligações: `Events.toast_requested(text)` → `notify("info", text)`; **novo sinal**
   `Events.notice_requested(kind: String, text: String, item: String)` (item = id de item cujo ícone vai no
   aviso; vazio = sem ícone). Troque para `notice_requested("error", …)` os erros de
   `ProgressionUi.quest_action` e de `NextStep` (os demais lugares migram nas etapas das telas).
   `_on_moment_gained` passa a enfileirar `moment` no `Notice`; a foto (`_photo_queue`) idem.
6. `main._show_toast(text)` continua existindo (chamadores antigos) e só delega.

### 3.7 Tour
Bloco `--i2-03-only`: `i2_03_pet` (HUD na tela do Tiro), `i2_03_map_farm` (linha 2 com pílula do mundo +
próximo passo compacto), `i2_03_tasks` (aba Missões com a pílula), `i2_03_step_card` (mini-cartão aberto),
`i2_03_step_ready` (pílula verde: deixe `welcome` pronta com `talk_to("lais")`), `i2_03_notice_error`
(`Events.notice_requested.emit("error", "Falta 1 cenoura", "carrot")`), `i2_03_popover` (resumo do avatar).

## 4. Não fazer
- Mudar a aba Missões por dentro (05), a tela do Tiro além do espaço do HUD (04), etiquetas/balões do mundo (06).
- Criar fluxo de prêmio novo (folha de prêmio é da 05).

## 5. Armadilhas
- `Layout` como `Control`: as telas usavam o espaço que o VBox calculava. Confira que `PetScreen`,
  `TasksScreen` e `BagScreen` não ficam atrás do rodapé (rolagem até o fim mostra o último item inteiro).
- `RoomView` fica 84 px mais alto: o enquadramento inicial muda um pouco; confira os 5 mundos no tour.
  `ActionTray` (BOTTOM_LIMIT) e `WorldSelector` (`world_selector.gd:66`) acham o `TabBar` por nome: confira
  que a bandeja não entra embaixo do rodapé.
- A pílula compacta no Mapa não pode cobrir os rostos da `NpcRow` em 360 px.
- `displayed_main_quest()` pode mudar no meio de um `state_changed` em cadeia: o `NextStep.refresh` só lê;
  nunca chame `claim_quest` de dentro do `refresh`.
- `hud_test` confere margem ≥ 64 (passa com 136), pílula 40 e engrenagem 44: a engrenagem nova tem disco 40
  com alvo 44 — confira qual medida o teste lê e ajuste o teste para o **alvo** (44), não para o disco.

## 6. Testes

**`game/tests/next_step_test.gd`** (área `shell`; modelo 04 §E.2 com o `main`):
1. Save novo (`reset`, `seen.intro = true`): `NextStep` visível; `QuestGuide.current().id == "welcome"`,
   `state == "talk"`; `StepCount` mostra `0/1`.
2. Tocar no `NextStep` abre `StepCard` com `StepCardGo` e `StepCardHelp`; tocar em `StepCardGo` emite
   `Events.world_requested` para o lugar de `Places.quest_target("welcome")` (escute o sinal) e fecha o cartão.
3. `state.call("talk_to", "lais")`: estado `ready`; `StepClaim` visível; tocar no `NextStep` conclui
   `welcome` (está em `progress.claimed_quests`), as moedas sobem exatamente o prêmio (+5) e
   `dog_food` +2; tocar de novo **não** paga de novo (o `NextStep` já mostra `lais_feed`).
4. `lais_feed` (`progress`, `0/1`): `state.call("feed", "dog_food")` (ou o método de alimentar existente)
   → `StepCount` vira `1/1` e o estado vira `ready`.
5. História que aponta para personagem: `dev_complete_quest` em todas as principais antes de
   `lais_meet_bloblo` → `QuestGuide.current().shared == true` e `id` é o passo atual da linha da Bloblo
   (`progress.current_line_quest("bloblo")` ou a linha de `bloblo_meet`); o retrato é o da Bloblo.
6. História concluída (`dev_complete_quest` em todas as principais): `NextStep.visible == false`.
7. Linha 2 escondida com folha aberta (`Events.sheet_requested.emit("x", Control.new())` → depois de 0,3 s
   o `HudRow2` tem alfa 0) e de volta ao fechar.
8. Aba Mapa: o `NextStep` está em modo compacto e o retângulo dele não cruza o de `NpcRow` nem o da
   `WorldPill` (360×780 é o tamanho da janela de teste).
9. Rodapé: `Layout/TabBar` tem altura 84; cada aba tem um `Label` com o nome visível (as 4).

**`game/tests/notice_test.gd`** (área `shell`):
1. `notify("info", "a")` e logo `notify("info", "b")`: só um visível por vez; "b" aparece depois de "a".
2. `notify("info", "a")` e `notify("error", "x")`: o erro aparece na hora (substitui).
3. `moment` antes de `info`: ordem respeitada quando os dois estão na fila.
4. Com um cartão modal aberto (`Celebration` visível), nada aparece; ao fechar, a fila anda.
5. `Events.toast_requested.emit("oi")` chega como `info`; `Events.notice_requested.emit("error", "Falta",
   "carrot")` mostra o ícone da cenoura no `ToastIcon`.
6. Aviso de foto é tocável e chama a abertura da foto (escute com um `Callable` de teste passado no `on_tap`).

**Atualizar:** `hud_test` (medidas: alvo 44, altura do HUD, linha 2), `ready_badges_test` (posição do selo
na almofada), `world_selector_test` (se o `TabBar` mudou de altura, as contas `end.y <=` continuam valendo),
`effects_layer_test` (camadas: o `TabBar` precisa continuar acima dos efeitos do mundo).

**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests next_step_test,notice_test,hud_test,hud_growth_test,festa_test,welcome_test,ready_badges_test,effects_layer_test,world_selector_test` (~2 min 30).

## 7. Capturas
`--i2-03-only` antes (use `--i2-01-only` como "antes") e depois nas 3 resoluções; compare com
`missoes2_historia.png` (linha 2), `horta_seta.png` (Mapa) e `prancha_rodape.png` (clara).

## 8. Pronto quando
- [ ] Rodapé claro translúcido preso à borda, com nomes; o mundo aparece atrás dele no Mapa.
- [ ] HUD em duas linhas igual ao protótipo; nada sobrepõe em 360/390/412.
- [x] Seguir a história do save novo até `lais_bag` só pela pílula funciona (teste 3–4 + conferência à mão).
- [ ] Avisos nunca empilham; erro tem o ícone do que falta.
- [ ] Testes da lista verdes. `CLAUDE.md`/`AGENTS.md`: linhas novas para `NextStep`, `QuestGuide`, `Notice`,
      `Events.notice_requested` e o rodapé preso.

## 9. Registro
```
**Etapa 03 (data, executor):** rodapé preso claro (84, translúcido), NavTab com nomes, HUD em 2 linhas
(HudProfile, HudRow2), NextStep + QuestGuide, Notice + Events.notice_requested; pulsar da aba Missões saiu.
Testes … PASS em … s. Diferenças do protótipo: … Pendências: …
```
