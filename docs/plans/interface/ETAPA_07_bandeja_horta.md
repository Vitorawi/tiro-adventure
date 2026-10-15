# Etapa 07 — Bandeja de ação na horta: tocar e arrastar para plantar, regar e colher

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_07_bandeja_horta.md."
> Pré-requisito: Etapas 00–06. **É a etapa mais importante do plano: capriche no toque real.**

## Objetivo (o que o jogador sente)
"Toco num canteiro e as sementes aparecem do lado do meu dedo. Arrasto a cenoura por cima da horta e
planto tudo de uma vez. Quando fica pronto, toco num e passo a foice pelo resto." (Hay Day.)
Hoje: um painel de 70% por canteiro, um canteiro por vez.

## Leia antes
`room.gd` (`_handle_tap`, `_on_plot_tapped`, `_water_fx`, `_gui_input`, `_input`, `_objects` com
`meta "plot"`, `_screen_point`, `point_at`), `game_state.gd` (`plot_status`, `plant`, `crop_plot_error`,
`content_error`, `water_error`, `water`, `harvest`, `storage_error`, `usable_plot_indices`),
`sheet_builder.gd` (`seed_picker`, `farm_view`, `growing_plot`, `plot_purchase`), `places.gd` (linhas
com `farm_view`/`"plot"`), `collect_fx.gd`, `task_help.gd` (`TaskHelp.open`), `tests/intro_test.gd`
(chama `_on_plot_tapped(2)`), `tests/farm_test.gd`.

## Regras do jogo que NÃO mudam
Plantar não custa nada; uma rega por plantio; colher respeita o armazenamento (`storage_error`);
estufa só aceita plantas delicadas e vice-versa (`crop_plot_error`); plantas fechadas por requisito
(`content_error`). A bandeja só chama os métodos que já existem, um canteiro por vez.

## Passo a passo

### 7.1 Ação nova no `GameState` (convenção `*_error`)
- [ ] `func plant_error(index: int, crop_id: String) -> String` com exatamente as mesmas checagens de
  `plant` (na mesma ordem); `plant` passa a começar com `var reason := plant_error(index, crop_id)`.
- [ ] `func harvest_error(index: int) -> String`: "" se pronto e cabe no armazenamento; senão o motivo
  ("Ainda não está pronto", texto do `storage_error`). `harvest` continua igual (devolve `{}` se falhar).
- [ ] Sem estado novo salvo. A "última semente usada" fica numa `static var` da bandeja (memória da sessão).

### 7.2 A bandeja — `scripts/ui/action_tray.gd`
```gdscript
class_name ActionTray
extends Control
## Bandeja de ação perto do dedo: ícones grandes com legenda curta (tempo, quantidade).
## Toque no ícone = ação no alvo. Arrastar o ícone = repetir a ação em cada alvo por onde o dedo passar.

signal closed

## entry: {
##   "id": String, "icon": Texture2D, "caption": String (tempo/quantidade), "badge": String ("", "!", "♥"),
##   "error": String ("" = disponível; senão aparece apagado com cadeado e o toque mostra o motivo),
##   "help": Callable (opcional, abre "Como fazer" quando bloqueado),
##   "tap": Callable () -> String  ("" = deu certo; senão motivo para toast),
##   "drag": Callable (world_point: Vector2) -> bool  (opcional; true = agiu neste ponto)
## }
static func open(room: RoomView, anchor_world: Vector2, entries: Array[Dictionary], options: Dictionary = {}) -> ActionTray
func close() -> void
```
`options`: `"title"` (texto pequeno opcional no topo, ex.: "Canteiro da estufa"), `"header"` (Control
opcional, ex.: anel com tempo), `"footer_ghost"` (`{"text": "Ver tudo", "action": Callable}`),
`"auto_close"` (segundos sem toque para fechar sozinha; 0 = não fecha).

**Visual**
- [ ] Painel `PAPER` com cantos 16, sombra `SHADE` 6, borda 2 `CARD_LINE`; setinha (triângulo 12 px)
  apontando para o alvo.
- [ ] Item: 60×72 — ícone 48 (escala inteira) sobre um círculo `SUNKEN` 56, legenda 16 embaixo
  (`TimeText.short` ou "×3"). Selo no canto (`BadgeLabel`). Bloqueado: `modulate.a 0.45` + `ui_lock` 16.
- [ ] Até 5 itens por linha; mais que 5 → segunda linha; mais que 10 → linha única com rolagem horizontal.
- [ ] Abre com `Motion.pop_in` a partir da setinha (pivô na ponta); fecha com `pop_out`.

**Onde fica**
- [ ] Filho do `RoomView` (não do `Content`: não escala com o zoom), por cima do mundo e do `WorldBar`,
  abaixo do HUD e dos painéis.
- [ ] Posição: converte `anchor_world` para tela (`_content.position + anchor * _zoom`). Prefere **acima**
  do alvo (16 px de folga); se não couber abaixo do HUD (y < 120), vai **abaixo**. Em x, centralizada no alvo
  e presa entre 8 e `largura − 8`. A setinha acompanha o alvo mesmo com a bandeja deslocada.
- [ ] Se a câmera mover (arrasto do mundo, zoom), a bandeja **fecha** (mais simples e previsível).

**Quando fecha**
- [ ] Toque fora dela (o toque é **consumido**: fecha e não age no mundo — evita plantar sem querer);
  arrasto do mundo; abrir painel (`Events.sheet_requested`); trocar de aba/mundo; `auto_close`;
  depois de um arrasto que agiu em pelo menos um alvo.
- [ ] Só existe uma bandeja por vez (abrir outra fecha a anterior).

**Toque e arrasto** (lembrete: o toque chega como mouse)
- [ ] `button_down` num item guarda o ponto. Soltar sem mover > `TAP_SLOP` (12 px) = **toque**: chama
  `tap`; resultado "" → `Motion.bounce` no item e a bandeja fecha (ou fica, conforme o caso abaixo);
  motivo → `Motion.shake` + toast. Item bloqueado → toast com `error` e, se tiver `help`, abre o "Como fazer".
- [ ] Mover > `TAP_SLOP` com o item tendo `drag` = **arrasto**:
  - cria o "fantasma": ícone 56 seguindo o dedo, **40 px acima** do dedo (para o dedo não cobrir);
  - avisa o `RoomView` (`room.tray_dragging = true`): o mundo **não** move a câmera nem trata toques enquanto isso;
  - a cada movimento, converte a posição do fantasma (ponta de baixo) para o mundo e chama `drag(point)`;
    cada alvo só recebe uma vez por arrasto (a função `drag` decide o alvo; a bandeja guarda os ids já feitos
    via retorno — ver 7.3);
  - **rolagem na borda:** fantasma a menos de 36 px da borda da tela → câmera anda 6 px/quadro naquela direção
    (respeitando os limites);
  - soltar: fantasma some (`pop_out`); se agiu em ≥ 1 alvo, a bandeja fecha; senão volta ao normal.
- [ ] O fantasma e a bandeja usam `_input` global enquanto arrasta (o dedo sai de cima da bandeja).
  Teste com mouse **e** com toque (`InputEventScreenDrag`); lembre do `emulate_mouse_from_touch`
  (os dois chegam — trate só o mouse, como o `RoomView` faz no `_gui_input`, ou filtre duplicados).

### 7.3 `RoomView`: achar canteiro no ponto e efeitos
- [ ] `func plot_at(world_point: Vector2) -> int`: −1 se nenhum. Usa o `footprint` do objeto do canteiro
  (losango no chão) **ampliado 20%** — arrastar por cima tem que ser fácil — e, se não achar, o retângulo
  do sprite da planta (`Crop`).
- [ ] `func screen_to_world(screen: Vector2) -> Vector2` e `func world_to_screen(world: Vector2) -> Vector2`
  (já há `_screen_point`; unifique).
- [ ] `var tray_dragging := false`; no `_gui_input`/`_input` saia cedo quando verdadeiro.
- [ ] `func plot_feedback(index: int, kind: StringName)`: `Motion.bounce` no sprite do canteiro +
  pequeno efeito: `plant` → 4 pontinhos de terra; `water` → reaproveita `_water_fx`; `harvest` → o
  `CollectFx` já faz as miniaturas saltarem (emitir `Events.items_gained` com a origem do canteiro).
- [ ] `func open_plot_tray(index: int)` (público, usado pelo "Ir" e pelo painel de canteiros).

### 7.4 O que cada toque no canteiro faz (substitui `_on_plot_tapped`)
Mantenha os casos de antes do sítio (vovó empresta / compra do sítio) e de canteiro fechado
(`plot_purchase`) exatamente como estão. Mudam:

**Canteiro vazio → bandeja de sementes**
- [ ] Itens: todas as culturas em que `crop_plot_error(index, id) == ""` (estufa mostra só as delicadas e
  vice-versa). Ordem: a última usada nesta sessão primeiro; depois por tempo (como o `seed_picker`).
- [ ] Liberadas: legenda = tempo (`TimeText.short`, considerando `greenhouse_speed` na estufa).
  Bloqueadas por `content_error`: no fim, apagadas, `help` = `TaskHelp.open.bind("crop", id)`.
- [ ] `tap` = `GameState.plant(index, id)` → feedback `plant`; fecha a bandeja.
- [ ] `drag(point)` = `var i := room.plot_at(point)`; se `i >= 0` e ainda não feito e
  `GameState.plant_error(i, id) == ""` → `plant(i, id)`, feedback, vibração curta (Etapa 12 liga), `true`.
  Canteiros ocupados/incompatíveis são ignorados em silêncio (sem toast no meio do arrasto).
- [ ] Título opcional: "Estufa" quando for canteiro da estufa. Rodapé: `ghost` "Ver tudo" → abre o
  `seed_picker(index)` antigo (continua existindo, com o visual da Etapa 02).

**Canteiro crescendo → bandeja de cuidado**
- [ ] Se dá para regar (`water_error == ""`): **o toque rega na hora** (como hoje) e, se houver outros
  canteiros regáveis, abre a bandeja com o regador (`action_water`, legenda "×N" regáveis) para arrastar
  por eles (`drag` → `water(i)`), com `auto_close` 3 s.
- [ ] Se não dá para regar: bandeja só com o cabeçalho: `RingProgress` 56 com o ícone da planta +
  tempo restante (atualiza a cada segundo) + "Regado ✓" se já foi regado; `auto_close` 3 s; rodapé
  "Ver tudo" → `growing_plot(index)`.

**Canteiro pronto → colher**
- [ ] O toque colhe na hora (como hoje, via `harvest` + `items_gained`). Falhou (armazenamento cheio) →
  `Motion.shake` no canteiro + o toast que o `harvest` já emite.
- [ ] Depois de colher, se ainda houver canteiros prontos: bandeja com a foice (`tool_sickle`, legenda
  "×N") para arrastar (`drag` → `harvest(i)`), **e** um item "Tudo" (ícone da planta mais comum entre os
  prontos + "×N") cujo `tap` colhe todos os prontos de uma vez (para quem não quer arrastar).
  `auto_close` 4 s. Colher todos para no primeiro que não couber (toast uma vez).

### 7.5 Ensinar o arrasto (uma vez)
- [ ] Na primeira vez que a bandeja de sementes abre com ≥ 2 canteiros vazios
  (`progress.seen["ui:tray_drag_hint"]` ainda falso): uma mãozinha/seta (reaproveite o sprite do
  `Pointer`) sai do primeiro item e desliza por dois canteiros vazios, em loop, até o jogador tocar em algo.
  Marque o `seen` ao plantar (por toque ou arrasto). Legenda pequena na bandeja: "Arraste até a terra".
- [ ] Mesma dica, uma vez, para a foice (`ui:tray_harvest_hint`).

### 7.6 Outros caminhos que abriam o painel de sementes
- [ ] "Ir" de missão/manual/"Como fazer" com alvo de canteiro (`Places.highlight_action` → `"plot"`) e o
  `Places.run` com foco numa planta (`farm_view(id)`, linha ~157 de `places.gd`): quando o Sítio está
  visível, em vez de abrir o painel, a seta aponta o **primeiro canteiro vazio compatível** e abre a
  bandeja nele com a planta pedida em primeiro e destacada (borda `PRIMARY`). Sem canteiro vazio: aponta o
  primeiro canteiro e mostra o toast "Todos os canteiros estão ocupados".
- [ ] Painel "Canteiros" (`farm_view`, lugar `plots`): continua como **resumo**. Tocar num canteiro da grade
  fecha o painel, centraliza a câmera nele (`zoom_to`) e abre a bandeja (`open_plot_tray`). Os botões
  "Plantar" da grade saem (o quadro inteiro é tocável).

## Testes
- [ ] `game/tests/tray_test.gd` (novo, no `test_all.ps1`), com o Sítio de verdade (`main.tscn` + `enter("farm")`,
  sem `SaveManager`, `dev_unlock_everything`):
  1. tocar no canteiro vazio 0 abre a bandeja com cenoura; tocar na cenoura planta o 0 (`plot_status == "growing"`);
  2. bandeja no canteiro 1; arrasto simulado da cenoura passando pelos centros dos canteiros 1, 2, 3 e
     pelo 0 (já plantado) → 1, 2, 3 plantados, 0 intacto, **nenhum toast** de erro;
  3. canteiro da estufa (9): bandeja não oferece cenoura; oferece ervas/morango;
  4. planta bloqueada aparece apagada; tocar não planta e abre o "Como fazer" (sinal `sheet_requested`);
  5. `dev_finish_timers` → tocar no 1 colhe; bandeja da foice aparece; arrasto pelos 2 e 3 colhe;
  6. armazenamento cheio (encha com `dev_add_items`): colher falha, plantas continuam lá;
  7. durante o arrasto, `_content.position` não muda (sem rolagem na borda);
  8. abrir um painel fecha a bandeja; tocar fora fecha sem plantar;
  9. regar: canteiro crescendo regável → toque rega; arrasto do regador rega os outros uma vez só.
- [ ] Ajuste `intro_test` (`_on_plot_tapped(2)` esperava o painel de sementes → agora espera a bandeja)
  e qualquer teste que procurava o `seed_picker` aberto pelo toque.
- [ ] `farm_test`, `onboarding_test` (ritmo da primeira hora não pode piorar), `tasks_test` passam.
- [ ] **Toque real** (`touch_test.ps1`, Chrome em modo celular): roteiro `build/touch_steps_etapa07.json`
  — abrir o Sítio, `tap` num canteiro vazio, `ghost_drag` da cenoura por 3 canteiros, `shot`; esperar
  (`dev_finish_timers` pelo painel DEV ou use culturas de 1 min), `tap` num pronto, `ghost_drag` da foice,
  `shot`. Abra as fotos.

## Capturas
`etapa07_antes`/`etapa07_depois` + novas: `e01_tray_seeds`, `e02_tray_drag` (fantasma no meio do arrasto
— chame a função de arrasto e capture), `e03_tray_greenhouse`, `e04_tray_growing`, `e05_tray_sickle`,
`e06_drag_hint`. Em 360×780 **e** 412×915; bandeja nunca cortada, nunca embaixo do HUD.

## Lista de conferência (aceite)
- [ ] Plantar a horta inteira (9) leva 1 toque + 1 arrasto.
- [ ] Colher tudo leva 1 toque + 1 arrasto (ou 1 toque + "Tudo").
- [ ] O mundo continua visível o tempo todo; nenhuma ação comum da horta abre painel grande.
- [ ] Nada mudou nas regras (testes de fazenda/onboarding iguais).
- [ ] CLAUDE.md/AGENTS.md: linha nova "Bandeja de ação (plantar/colher/regar perto do dedo)" →
  `scripts/ui/action_tray.gd`, `RoomView.plot_at/open_plot_tray/tray_dragging`, `GameState.plant_error/harvest_error`;
  linha "Recolher/colher com animação" atualizada. `docs/GAME_DESIGN.md`: como se planta agora.
- [ ] ROADMAP e README marcados; commit `feat(ui): bandeja de ação na horta — tocar e arrastar para plantar, regar e colher`.
