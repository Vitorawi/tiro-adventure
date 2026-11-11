# Etapa 02 — Lagoa no Sítio (o fluxo inteiro, de ponta a ponta)

> Tamanho: grande. Depende de: 01. Próxima: 03.
> Resultado que o Vitor vê (com DEV "Dar vara" + "Dar iscas"): no Sítio, tocar na lagoa → a câmera vai até
> ela, o Tiro corre e senta na beirinha, abre a bandeja de madeira com vara e isca, segura "Arremessar", a boia
> cai na água, espera, afunda com "!" e o Tiro late, toca, joga o minigame, vê o cartão "Pegou! 12,5 cm".
> Arte ainda provisória onde a etapa 03 vai trocar (peixe, boia, vara, iscas).

## 1. Ler antes

- `01_DESENHO.md` §1, §6; `03_INTERFACE_E_ARTE.md` §1–§5 (o desenho de cada tela).
- `CLAUDE.md`: "Sítio em ilha" (o `farm.json` é **gerado**), "Bandeja de estação madeira ilustrada"
  (`StationWood`, `ActionTray._place_bottom`), "Botão bloqueado de madeira" (`StepCardUi.locked_button`),
  "Avisos em madeira, embaixo" (`Notice`), "Comemorações (ModalCard) em madeira", `RewardSheet`.
- Código:
  - `tools/build_farm_island.py` (l. ~243 `zones`, l. ~211 `spot`, l. ~291 `near`, l. ~312 `dig_spots`,
    l. ~323 `points`): onde zonas e pontos são gerados. **Nunca edite o `farm.json` à mão.**
  - `game/scenes/levels/room/room.gd`: `_on_object_tapped(action, target)` (l. ~2283), `point_at`,
    `zoom_to(pivot, zoom, seconds)`, `_tween_camera`, `nearest_floor_point`, `open_station_tray` (molde da
    bandeja presa embaixo), `_sync_dog`.
  - `game/scenes/entities/dog_world/dog_world.gd`: `react_at(kind, alvo, on_start)` (l. ~196) e
    `_show_reaction(kind)` (casos `bench`, `garden`, `picnic`; clipes `sit`, `bark`, `eat`, `sniff`, `dig`).
  - `game/scripts/ui/places.gd`: `open(world, place, from_object)`, `_panel(kind, arg, world)` (l. ~55),
    `run(world, action)` (l. ~203), `goal_target`, `world_summary` (l. ~512).
  - `game/scripts/ui/station_wood.gd`, `step_card_ui.gd`, `reward_sheet.gd`, `modal_card.gd`, `notice.gd`.
  - `game/scenes/main/main.gd`: `_queue_modal`, `notice_blocked`, `set_row2_blocker(key, on)`.

## 2. Como está hoje

A lagoa é só obstáculo. `GameState` já tem pesca completa (01). `FishingGame` existe como protótipo (00).

## 3. Passo a passo

1. **Gerador do Sítio** (`tools/build_farm_island.py`), depois rodar e conferir com `tests/farm_nav_overlay.gd`:
   - zona `{"id": "lake", "action": "place:fishing", "polygon": <só a ÁGUA, recolhida ~6 px do obstáculo
     `lake`>, "label": "Lagoa", "label_pos": centro da água}` acrescentada em `zones` (a água continua no
     `obstacles`, o Tiro não entra nela);
   - ponto `fishing_spot` em `points`: chão andável mais perto da margem de baixo da água, com `near(...)`,
     e `fishing_face` (`"west"`/`"north"`… a direção que olha a água);
   - `fishing_bubbles`: 3 pontos dentro da água (lista em `points`), longe da margem.
   - Rodar `py -X utf8 -I tools/build_farm_island.py`. Diferença esperada no `farm.json`: só esses campos.
2. **Lugar** em `worlds.json → farm.places`: `"fishing": {"name": "Lagoa", "icon": "rod_bamboo" (provisório
   `coin`), "description": "Pesque com a vara da vovó.", "panel": "fishing", "hidden": true,
   "requirements": {"rod": "bamboo_rod"}}`. **Fica escondido** (o Sítio já tem 4 visíveis). Antes da vara, o
   toque na lagoa mostra só um balão curto da vovó: `npcs.json → bloblo.lines.lake_locked`
   "Um dia eu te ensino a pescar aqui!" (aviso `Notice` com o rosto dela, nada mais).
3. **Toque na lagoa** (`room.gd → _on_object_tapped`, caso `action == "place:fishing"`):
   - `GameState.fishing_error()` não vazio → aviso e fim;
   - câmera: `zoom_to(centro_da_agua, max(zoom_atual, 0,6))`;
   - Tiro: `dog.react_at(&"fishing", fishing_spot)`; caso novo em `_show_reaction`: `sit` virado para
     `fishing_face` e **fica sentado** enquanto `GameState.fishing.cast` existir (verificar a cada 0,5 s); ao
     terminar, `happy`/pulo se pegou (`Events.fish_caught`) ou `idle` se escapou;
   - abre o **painel de arremesso** (item 4) preso embaixo, como as bandejas de estação.
4. **Painel de arremesso — `game/scripts/ui/fishing_panel.gd`** (`class_name FishingPanel`): monta com as
   peças da `StationWood` (mesma madeira, `backing`, `heading`, `board`, `wood_button`), filho da `RoomView`
   como o `ActionTray` (`_place_bottom`, largura da sala − 8 até 420):
   - cabeçalho: ícone da vara, nome, `FishingLevel` (nível + barrinha de XP), X `CloseTray`;
   - linha `RodRow` só com 2+ varas: quadradinhos `Rod_<id>` (`StationWood.recipe_tile`), escolhido em amarelo;
   - linha `BaitRow`: `Bait_<id>` com "×N"; isca sem estoque = cadeado (toque → `TaskHelp.open` da isca);
   - faixa `BaitFish`: os 3 peixes do grupo da isca escolhida, ícone + recorde ("28 cm") ou sombra + "?";
   - tábua: botão verde `CastButton` "Arremessar". Sem isca: `StepCardUi.locked_button("Sem minhoca", ícone,
     ajuda)`.
5. **Força do arremesso** (`FishingPanel`): `CastButton` em `button_down` mostra `CastPower` (barrinha de
   madeira horizontal com três faixas Perto/Meio/Longe, ponteiro indo e voltando em `cast.power_period`);
   `button_up` → zona = faixa do ponteiro; chama `GameState.cast(bait, zone, on_bubble)`. `on_bubble`: há
   bolha e o ponto de queda (calculado ao longo de uma linha do `fishing_spot` para o centro da água, pela
   força) fica a < 40 px do ponto da bolha → o jogo "puxa" a boia para a bolha.
   O painel some (fecha) e entra a **espera**.
6. **Linha, boia e espera** (`game/scripts/ui/fishing_bobber.gd`, `Node2D` filho da `RoomView`, z como os
   indicadores): a linha voa em arco (`Motion.fly_arc`) da margem até o ponto; a boia balança (seno). Anel
   discreto (`RingProgress` pequeno) só se a espera passar de 6 s. Tocar em qualquer lugar **antes** da
   mordida = `GameState.miss_bite()` + aviso "Ainda não mordeu!" + boia volta. `Events.fish_bite` →
   boia afunda 2×, respingo (provisório: `Motion.pop_in` num círculo), "!" grande, `Haptics.success`, o Tiro
   late (`_play("bark", …)` no `DogWorld`). Toque dentro de `bite_window` → `GameState.hook()` e abre o
   minigame; janela perdida → `miss_bite()` + "Ele foi embora!".
7. **Minigame de verdade** — evolua `FishingGame` (00) para o desenho do `03_INTERFACE §4`:
   - filho de `Main`, tela cheia, **z 7** (acima do mundo e do seletor 6, abaixo do HUD 8); fundo = a própria
     lagoa escurecida (`Palette.DIM`) — o mundo continua desenhado atrás;
   - `set_row2_blocker("fishing", true)` enquanto aberto (a pílula do próximo passo some); abas visíveis, mas
     **trocar de aba = `cancel_fishing()`** (devolve a isca) com aviso "Você soltou a linha";
   - pista com a altura real da tela (`_layout` no `resized`: de `Hud.HEIGHT + 16` até o topo da `TabBarArt`
     − 16), à direita; madeira provisória com `StationWood.backing` até a 03;
   - `FishingSim` com `bar_h = GameState.fishing_bar_height()`, peixe da partida (`cast.fish`), `rod`, semente
     da partida;
   - `PauseButton` (disco de madeira 44): "Continuar" (verde) e "Soltar o peixe" (amarelo → `release`
     equivale a escapou);
   - ao terminar: `GameState.finish_fishing({caught, score, perfect, chest: false})`;
   - app para o segundo plano (`NOTIFICATION_APPLICATION_PAUSED`/`FOCUS_OUT` na Web) → pausa; fechar o app →
     no próximo carregamento, `cast` em `fighting` vira `cancel_fishing()` (devolve a isca).
8. **Resultado** (`game/scripts/ui/fish_result.gd`, `class_name FishResult`):
   - Pegou: `RewardSheet.open(host, {title: nome do peixe, hero: ícone, ...})` com régua `FishSize` (cm),
     selo `FishClass`, `FishRecord` "Novo recorde!" (quando `cm > previous_cm`), "Primeira vez!", chips
     (peixe ×N, XP). Verde `FishAgain` "Pescar de novo" (mesma isca/vara: volta direto para o `CastButton`) e
     amarelo `FishLeave` "Sair". **Gigante** usa `ModalCard` com `confetti` e `haptic "big"`.
   - Escapou: `Notice` "Escapou! A minhoca foi junto." e o painel volta.
   - Geladeira cheia (`finish_fishing` devolveu erro): cartão com `StepCardUi.locked_button` "Geladeira cheia"
     e amarelo "Liberar espaço" (abre o depósito como a bagagem do passeio) + "Soltar o peixe".
   - O cartão entra pela fila modal (`main._queue_modal`) só se houver outra comemoração; senão abre direto.
9. **Bolhas no mapa** (`game/scripts/ui/fishing_bubbles.gd`): círculos que sobem no ponto `fishing_bubbles[i]`
   da bolha ativa (`GameState.fishing.bubble`), parados em "Menos animação" (só um anel estático).
   `Places.world_summary("farm")` ganha `fishing: 1` quando há bolha → o seletor de mundos mostra o disco
   `map_status_*` da bolha (use o de "busy" provisório até a 03).
10. **Lista "Lugares" do Sítio** (`Places.world_list`): a lagoa aparece como `Place_fishing` (ícone da vara)
    depois da vara, e o Ir aponta o alfinete na água (`point_at("place:fishing")`).
11. **`Places._panel`/`run`**: `"fishing"` abre o fluxo do item 3 na sala do Sítio (se estiver em outro mundo,
    viaja primeiro, como os outros "Ir"). `goal_target` de `{"type": "stat", "key": "fish..."}` → lagoa.

## 4. Não fazer

Tutorial (05), missões (05–06), loja (04), arte final (03), baú (07). Não deixe o minigame passar por cima do
HUD nem das abas. Não pause a árvore do jogo (timers do resto do jogo continuam).

## 5. Armadilhas

- `farm.json` é gerado: mudança à mão some na próxima geração.
- O toque que fisga não pode também tocar no mapa embaixo (consuma o evento: `_swallow_touch` da `RoomView`).
- A `ActionTray`/`FarmDock` aberta precisa fechar ao tocar na lagoa (o padrão do `open_station_tray`).
- Durante o minigame o dedo vale em qualquer lugar: o `FishingGame` precisa ter `mouse_filter = STOP` na tela
  toda e repassar nada ao mapa.

## 6. Testes

Novo **`game/tests/fishing_lake_test.gd`** (área `fishing` + `world`):
1. Sem vara: tocar na lagoa mostra o aviso da vovó e não abre painel.
2. Com vara e isca: tocar abre `FishingPanel`, `CastButton` ativo; o Tiro recebe a reação `fishing`.
3. Sem isca: `Locked_CastButton` com o motivo; toque abre o Como fazer.
4. Arremesso (simular `button_down`/`button_up` com o ponteiro em cada faixa) gera a zona certa.
5. Tocar antes da mordida chama `miss_bite` (nada gasto); depois de `fish_bite`, tocar abre `FishingGame`.
6. Minigame: simular `step` com toque contínuo até pegar → `FishResult` abre com `FishSize`; `FishAgain` volta
   ao arremesso.
7. Trocar de aba no meio devolve a isca.
8. Recarregar o save com partida em `fighting` → `cancel_fishing` aplicado, isca de volta.
9. Bolha ativa: arremesso com força que cai perto dela usa a espera menor.
10. O `FishingGame` não cobre o HUD nem as abas (retângulos).
Afetados: `world_view_test`, `world_life_test`, `farm_dock_test`, `tray_test`, `navigation_test`,
`fishing_test`, `fishing_physics_test`.

## 7. Capturas

`game/tests/fishing_shots.gd` → `build/screenshots/fishing/`, três resoluções, com medidas que dão **FAIL**
(fora da tela, sob HUD/abas, alvo < 44, texto cortado): lagoa sem vara, painel (1 vara), painel sem isca,
força, espera, mordida, minigame começo/meio, pausa, resultado comum, recorde, Gigante, geladeira cheia,
bolha no mapa.

## 8. Pronto quando

Testes PASS; fluxo completo jogado no Godot e, com `tools/touch_test.ps1`, no Chrome em modo celular (roteiro
`game/tests/touch/fishing_lake.json`: entrar no Sítio, tocar na lagoa, arremessar, esperar, fisgar, segurar e
soltar até pegar), sem queda de fps abaixo de 50 no minigame. Registro no README do plano, ROADMAP,
`CLAUDE.md`/`AGENTS.md` (linha "Onde trabalhar" nova: Pesca).

## 9. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 02 do plano "Pesca na lagoa da vovó".
Leia CLAUDE.md, docs/plans/pesca/README.md (Registros da 00 e 01), 01_DESENHO.md,
03_INTERFACE_E_ARTE.md e docs/plans/pesca/etapas/ETAPA_02_LAGOA.md antes de editar.
O farm.json é GERADO por tools/build_farm_island.py: mude o gerador e rode de novo.
Madeira ilustrada, um botão verde por tela, bloqueios com StepCardUi.locked_button, alvos >= 44.
Registre fishing_lake_test em suite e nas áreas fishing/world. Capturas SEM --headless nas três
resoluções, PNGs abertos. Teste de toque real com tools/touch_test.ps1.
Ao terminar: Registro da 02 no README do plano, ROADMAP, CLAUDE.md = AGENTS.md.
Sem commit/push/publicação. Não executar a 03.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
