# Etapa 06 — Balões no mundo e etiquetas só quando importam

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_06_indicadores.md."
> Pré-requisito: Etapas 00–05.

## Objetivo (o que o jogador sente)
"Bato o olho no Sítio e vejo na hora o que está pronto (balões verdes pulando) e o que ainda cresce
(anel enchendo). O mapa não está poluído de nomes."
Hoje os indicadores são texto miúdo + barrinha (ilegíveis no zoom do Sítio) e todas as etiquetas
aparecem sempre.

## Leia antes
`scripts/ui/plot_indicator.gd`, `station_indicator.gd`, `route_indicator.gd`, `walk_indicator.gd`
(todos desenham com `_draw` e têm `hit_rect`), `room.gd` (`_spawn_labels`, `_place_labels`,
`_update_plot`, `_handle_tap` — usa os `hit_rect`), `places.gd` (`place_alert`, `npc_badge`),
marcador de compra (`PurchaseMarker` em `room.gd`).

## Passo a passo

### 6.1 Peça única: `WorldBalloon` — `scripts/ui/world_balloon.gd`
- [ ] `class_name WorldBalloon extends Node2D`. Desenha (no `_draw`) um balão redondo de **44 px de tela**
  com rabinho para baixo:
  | Estado | Aparência |
  |---|---|
  | `progress` | fundo `PAPER`, borda 2 `CARD_LINE`, ícone do produto 32 no meio, anel `INFO` em volta (mesma conta do `RingProgress`) |
  | `ready` | fundo `PRIMARY` claro, borda 3 `PRIMARY_EDGE`, ícone 32, `ui_check` 16 no canto; pulinho a cada 2 s (`Motion.bounce`) |
  | `queued` | igual a `progress` com ícone `modulate.a 0.6` |
  | `buy` | fundo `ACCENT`, "+" 24 + pílula com preço embaixo |
  | `alert` | fundo `PAPER` com "!" `DANGER` (para NPC com missão nova) |
- [ ] **Tamanho constante na tela:** `scale = Vector2.ONE / room_zoom`, limitado para não passar de
  1,25× nem ficar menor que 0,8× do tamanho base quando o zoom é extremo. O `RoomView` avisa os balões
  quando o zoom muda (`_zoom_at` → `get_tree().call_group("world_balloons", "set_zoom", _zoom)`).
- [ ] Propriedades: `state`, `texture`, `progress`, `caption` (texto opcional embaixo, ex.: tempo — só
  quando `show_caption` for verdadeiro), `hit_rect` (em coordenadas locais, já considerando a escala).
- [ ] Ícones em escala inteira dentro do balão (o balão compensa o zoom; o ícone fica 32 px de tela).

### 6.2 Usar o balão nos quatro indicadores
- [ ] `PlotIndicator`: crescendo → `progress` com o ícone da planta; pronto → `ready`; regável → um
  pequeno ícone `action_water` 16 no canto do balão. O **tempo** só aparece como `caption` quando o zoom
  ≥ 1,2 **ou** por 2 s depois de tocar no canteiro (a Etapa 07 mostra o tempo na bandeja).
- [ ] `StationIndicator`: produzindo → `progress` com o ícone do produto do primeiro lote; prontos →
  `ready` com "×N" na `caption` se N > 1.
- [ ] `RouteIndicator` (Natureza) e `WalkIndicator` (Praça): mesmos estados.
- [ ] `PurchaseMarker` ("+" de compra): `buy` com o preço; só aparece quando os requisitos valem (regra atual).
- [ ] O `_handle_tap` continua usando `hit_rect` — confira que os retângulos acompanham o novo tamanho
  (toque no balão = toque no objeto; balão pronto = pegar).

### 6.3 Etiquetas inteligentes
Regra nova para as etiquetas de lugar (`_labels`):
- [ ] **Sempre visíveis:** lugar com algo a fazer (`Places.place_alert != ""`), compra disponível,
  passo de missão ativo apontando para ele, personagem com missão.
- [ ] **Visíveis por zoom:** demais etiquetas só com zoom ≥ 0,9 (hoje `detail_label`/`overview_label`
  já têm limiares; unifique: abaixo de 0,9 só as "sempre visíveis").
- [ ] **Primeira visita:** nas 2 primeiras entradas em cada mundo (`progress.seen["ui:labels:<mundo>"]`
  conta até 2 — é uma marcação de interface, permitida pela regra A.2), todas as etiquetas aparecem por 4 s
  e depois somem com fade.
- [ ] Estilo: pílula `PAPER` 90%, texto `INK` 18, ícone 16 do lugar à esquerda (de `worlds.json → places.icon`),
  borda 2 na cor do mundo quando é "sempre visível". `Motion.pop_in` ao aparecer.
- [ ] Tocar na etiqueta continua fazendo o mesmo que tocar no objeto (`_tap_label`).
- [ ] Etiquetas de regiões fechadas ("Estufa · Expandir") viram `lock_hint` compacto: cadeado + nome
  ("Estufa"), e o preço aparece no balão `buy` da região quando dá para comprar.

### 6.4 Brilho no que está pronto
- [ ] Sprite de estação/canteiro com produção pronta ganha um contorno claro piscando suave (`modulate`
  1,0 ↔ 1,15 a cada 1,2 s) — opcional se pesar no celular; teste com o tour e no `touch_test`.

## Testes
- [ ] `game/tests/balloon_test.gd` (novo): canteiro plantado → balão `progress`; `dev_finish_timers` →
  `ready`; zoom 0,5 e 2,0 → tamanho de tela do balão entre 0,8× e 1,25× do base; toque no balão pronto
  colhe (chamar `_handle_tap` no centro do balão).
- [ ] Regra das etiquetas: zoom 0,6 sem alertas → só etiquetas "sempre visíveis"; com fogão pronto →
  etiqueta da cozinha visível.
- [ ] `world_life_test`, `farm_test`, `animals_test`, `nature_test`, `park_test` continuam passando
  (eles tocam em indicadores pelos `hit_rect`).

## Capturas
`etapa06_antes`/`etapa06_depois`: b06 de todos os mundos, b08 canteiro crescendo, `d05_farm_ready`
(canteiros prontos + fogão pronto), `d06_farm_zoom_out` (zoom mínimo: balões legíveis, poucas etiquetas).

## Lista de conferência (aceite)
- [ ] No zoom de abertura do Sítio, dá para ver o que cresce e o que está pronto sem aproximar.
- [ ] Afastado, o mapa mostra só o que importa; aproximado, todos os nomes.
- [ ] Toques nos balões funcionam igual aos indicadores antigos.
- [ ] CLAUDE.md/AGENTS.md: linha "Recolher/colher com animação" e Ambientes (etiquetas) atualizadas;
  `WorldBalloon` na tabela.
- [ ] ROADMAP e README marcados; commit `feat(ui): balões com anel no mundo e etiquetas inteligentes`.
