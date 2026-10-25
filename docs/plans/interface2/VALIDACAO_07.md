# Validação — Interface 2, etapa 07 (barra da horta e bandejas das estações)

Data: 24/10/2026. Executor: Claude Sonnet 5.5. Local; sem push, publicação ou suíte inteira.

## O que mudou
- `FarmDock` (`game/scripts/ui/farm_dock.gd`): barra presa logo acima do rodapé (`Layout/TabBar`), modos
  `plant` (sementes + Regar + ✓) e `harvest` (foice + "Colher tudo (N)" verde, ou `lock_hint` com o ícone da
  colheita quando o depósito não tem lugar). Entradas vêm do `PlotTray` (`seed_entries/water_entry/sickle_entries`).
- Gesto: com a barra aberta, o dedo que **começa num canteiro** usa a ferramenta escolhida em todo canteiro por
  onde passar (uma vez por canteiro por gesto, a câmera fica parada). Ficha 56 px acima do dedo com contador,
  rastro claro e losangos tracejados nos alvos (`FarmDock.GestureLayer`); rolagem na borda; a pinça cancela o gesto.
- `RoomView`: `_gui_input` entrega o gesto ao `FarmDock`; toque fora dos canteiros e da barra fecha a barra sem
  agir; mexer na câmera NÃO fecha a barra (só a `ActionTray`); `open_plot_tray(…, plant_now)`, `open_farm_dock`,
  `dock_plot_tap`, `plot_diamond`; `_bring_into_view(…, bottom_extra)` sobe a câmera para os canteiros ficarem
  acima da barra. Canteiro crescendo sem rega mostra o `CareHeader` num `Popover` (sem o resto da bandeja).
- Dica "Arraste pelos canteiros": pílula `INK` com `spark`, só nas três primeiras aberturas em `plant` com 2+
  vazios; `progress.seen["ui:tray_drag_hint"]` agora é contador (número; booleano antigo conta como 3).
- `ActionTray` modo `pick` / `StationTray`: cartão branco 24 com sombra funda, largura 336, abre 0,92→1 em
  `Motion.TRAY_IN`; cabeçalho = ícone da estação + nome (`StrongLabel`) + selo de maestria (bronze/prata/ouro com
  o nível) + `ctl list` (Ver tudo, nó `SeeAll`) + `ctl x` (`CloseTray`); grade de 4 colunas de `UiKit.tile` 70×76
  sem rolagem horizontal (mais de 8 receitas = 2,5 linhas rolando na vertical); receita sem ingrediente =
  `tile missing` com mini-disco do ingrediente (`missing_fn`); detalhe = nome + chip de tempo, "entra → sai" em
  chips e rodapé fixo `Actions` (`UiKit.stepper` + verde, ou `lock_hint` com o motivo: fila cheia/falta item);
  "Comprar animais" virou linha com `plus`/`chev` no rodapé.
- `UiKit.tile`: a marca "falta" do estado `missing` agora fica no canto (antes ocupava 40 px por causa de preset
  de âncora sem tamanho).

## Testes
**Resultado: 9/9 PASS em 291 s** (scripts_check 10,4; content 7,2; texts 2,9; farm_dock 31,6; tray 71,2; garden 8,2; queue 8,6; recipe_help 11,1; station_tray 138,6) — log `build/test_logs/r20261024_235110_301d2ec6/`.
Lista fechada (`tools\test.ps1 -Level etapa -Exact -Tests farm_dock_test,tray_test,garden_test,queue_test,recipe_help_test,station_tray_test`):
resultado e tempos no registro do README do plano. Testes atualizados SEM enfraquecer o que conferem:
- `tray_test`: a metade da horta foi reescrita para a barra (plantar tocando/arrastando, estufa, bloqueadas,
  colher/foice, depósito cheio, regar, fechar, borda, dica contada, eventos reais, caminhos do "Ir"); `plot_at`,
  `first_water_hint` e helpers de estado ficaram como estavam (o `Pointer`/alfinete no primeiro canteiro continua).
- `station_tray_test`: largura 336, `SeeAll`, grade sem `RecipeScroll` (2,5 linhas na vertical), `Plus` do stepper
  do `UiKit`, tile `missing` (`Missing` + imagem apagada), fila cheia/falta item = `LockHint` sem botão `Cook`
  (o `GameState` continua recusando: conferido com `cook`).
- `queue_test`: stepper por `Minus/QuantityValue/FinishAt`, chips de ingrediente contados só entre botões.
- Novo `farm_dock_test` (sete casos do plano + eventos reais).
Também PASS (fora da lista, por tocarem nas peças): nature_test, nature_routes_test, animals_test, friends_test,
ui2_kit_test, world_view_test, balloon_test, ui_style_test (97,6 s com 3 processos).

## Toque real (Chrome headless, 390×844 CSS, escala 2, perfil descartável, export dev local)
`build/touch_steps_i2_07.json` (Sítio) e `build/touch_steps_i2_07_casa.json` (fogão); PNGs em
`build/screenshots/i2_07_toque/`:
1. tocar num canteiro vazio → planta nele e abre a barra (`t01`); 2. arrasto começando noutro canteiro vazio
planta mais três (`t02`); 3. tocar em Regar e arrastar por três crescendo rega (`t03`, `t04`; sobrou ×1);
4. após 70 s, tocar num pronto colhe só ele e abre "Colher tudo (3)" (`t06`); 5. tocar no verde colhe os outros
e a barra fecha (`t07`); 6. fogão → receita escolhida → Cozinhar: cenouras 10→8, vaga 1 acesa, "Fila cheia"
(`a02`, `a03`). Console sem erros. Evidência de toque emulado; nenhum aparelho físico.

## Capturas
`build/screenshots/i2_07_antes` (estado anterior, 9 PNGs) e `i2_07_depois`, `_390`, `_412` (10 PNGs cada,
incluindo `i2_07_dock_hint`). Abertas e comparadas com `horta_plantar.png`, `horta_colher.png` e `fogao.png`.

## Diferenças em relação ao protótipo
- A barra mostra quatro sementes (desbloqueadas) + Regar; o protótipo tem mais sementes e rola — o nosso rola na
  horizontal (sem barra visível) quando faltar espaço.
- Fogão: com o cartão aberto o mundo fica parcialmente atrás dele (o fogão fica sob o cabeçalho/HUD no
  enquadramento atual); a câmera não é levantada para estações (regra existente `_lift_for_sheet` só vale para
  painéis).
- Fila cheia: o `lock_hint` mostra só "Fila cheia"; as vagas a comprar (preço) ficam no cabeçalho, não repetidas
  no rodapé.
- "Ver tudo" das estações (`station_view`/`NatureUi.panel`) não mudou nesta etapa (já usa as peças da etapa 02).
- Natureza: título do material continua `SectionLabel` (pequeno) no detalhe.

## Pendências
- Aviso antigo "Lambda capture ... was freed" ao fechar painéis (anterior, não derruba nada).
- `StepCard` ainda não abre o nome do capítulo (opcional, da 03).
- Quebras conhecidas para as próximas: Caderninho largo e filtro da Mochila (08); contratos apertados (09);
  títulos de modais em duas linhas e cartão grande de capítulo (10).
