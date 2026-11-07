# Revisão geral: todas as interfaces em "madeira ilustrada" (05/11/2026)

Pedido do Vitor: "dá um overview geral no jogo inteiro para ver todas as interfaces que ainda estão no padrão
ruim ... ajusta todas as interfaces para ficar nesse padrão. Não precisa ainda mexer nas sprites dos elementos,
das comidas, nem do cachorro". Linha de base: `build/screenshots/revisao_antes/` (tour completo) e pranchas em
`build/screenshots/revisao_pranchas/`.

## O padrão (o que "madeira ilustrada" quer dizer aqui)

Já convertido e servindo de modelo — LEIA o código de pelo menos dois antes de começar:
- Folha com moldura de madeira pela `Sheet`: `content.set_meta("sheet_wood", true)` (+ `sheet_fit_content` quando
  a altura deve seguir o conteúdo). A `Sheet` desenha moldura, papel creme, título marrom na fonte da madeira e o X.
  Modelos: `ProgressionUi.npc_view` / `_wood_upgrade_card` / `plot_purchase`, `Places.world_list` (linhas `_place_row`).
- Folha "nua" com moldura própria (`sheet_bare`): `ItemUi` (item_ui.gd), `HelpUi` (help_ui.gd), `SellUi`, `OrdersUi`,
  `WalksUi`, `AnimalShopUi`, `CodexUi`. Use quando a tela é grande e tem placa de título própria.
- Peças prontas (NÃO desenhe estilo novo do zero; reutilize):
  - `StepCardUi`: `wood(texto, px, cor)` (rótulo na fonte da madeira), `inner_card(pai, nome, pad)` (cartão de papel),
    `go_button(texto, cb, ícone)` (botão VERDE, um por tela, meta `wood_primary`), `locked_button`/`lock_note`
    (bloqueio = botão de madeira apagado com cadeado + motivo; toque explica), `wood_chip(ícone, valor, "have"|"missing"|"", cb, nome)`,
    `help_button` ("?" de madeira), `done_medal` (✓ verde), `portrait_frame`, `bar(fração)` (barra de madeira), `pic/patch/tex`.
  - `WelcomeSheet._button(texto, verde, largura, nome, cb)`: botão verde ou AMARELO (secundário/calmo) de madeira.
  - `MissionUi`: `card`, `pill`, `tile`, `bar`, `tabs` (abas de madeira), `heading`, `tag`, `link`, `portrait`, `chapter_pill`.
  - `SellUi`: `nine` (NinePatch das molduras), `scrolled` + `style_bar` (lista que rola com barra fina de mel), `overlay`
    (placa de título + X), `coin`.
  - `StationWood`: quadradinhos de receita, espaços (slots), tábua (`board`), `stepper`, `wood_button`.
  - `BagUi`: `frame`, `item_tile`, `depot_card`, `filter_plank`, `title`. `CodexUi.tile` (quadradinho creme igual).
  - `HomeUi.theme(px, cor)` / `HomeUi.FONT` (fonte da madeira), cores `Palette.WOOD_*`, `GO_INK`, `ALERT_INK`.
  - Arte disponível: `game/assets/sprites/ui/home/*.png` (step_*, mission_*, item_*, sell_*, station_*, bag_*, map_*,
    codex_*, farm_*, delivery_*, animalshop_*). Referências originais em `IUREF/` (só ler; não copiar texto assado).

Regras fixas:
- Nada de cartão branco liso, botão liso (`UiKit.primary/soft/small_go/ghost`), `UiKit.list_card/list_row/chip/segmented/
  toggle` nas telas convertidas. Troque pelas peças acima. Um só botão verde por tela.
- Texto: fonte da madeira, marrom (`Palette.WOOD_INK`), pouco texto, ícone + número.
- Ícones pixel: escala INTEIRA e filtro NEAREST; ilustrações (`food_*`, `home/*`): LINEAR_WITH_MIPMAPS. Nada distorcido:
  NinePatch em escala uniforme (1/3), imagens na razão da fonte.
- Alvos de toque ≥ 44 px. Nada sai da tela, nada sob o HUD (`Hud.SHEET_TOP` 128) nem sob as abas.
- PRESERVE os nomes de nós usados em testes (`find_child("Nome")`) e as APIs públicas. Sem mudança de regra, save,
  JSON de conteúdo ou falas. GDScript tipado, comentários em português.
- NÃO crie arquivo novo com `class_name` (vários agentes rodam ao mesmo tempo; o import global conflita). Se
  precisar de helper, ponha como `static func` num arquivo que você já está editando.
- NÃO edite CLAUDE.md, AGENTS.md nem docs/ROADMAP.md (o coordenador faz). Não faça commit/push.

## Lotes (rodam em paralelo, arquivos separados)

1. **Crescimento**: `growth_ui.gd` (painel, caderneta `history`, resumo `compact_steps` do popover do avatar),
   `pillar_ui.gd` ("Cuidados do Tiro"), `hud.gd` (faixa vermelha "! Pode Crescer!" que cobre o nome; popover do nível).
2. **Mapa e produção**: `sheet_builder.gd` (`station_view`/`stations_view` "Ver tudo", `food_picker` tigela,
   `farm_view` canteiros/estufa, `seed_picker`), `nature_ui.gd` (`panel`, `levels_panel`), `plot_tray.gd` (popover
   branco do canteiro "41s Regado" e o da colheita), `npc_world.gd` (selo "!"/"✓" sobre o personagem que aparece como
   quadrado vermelho).
3. **Praça, vila e Tiro**: `project_ui.gd` (Nossa praça/vila, obras, Encontro), `friend_ui.gd` (lista, bandeja do
   amigo), `trick_ui.gd` (painel de truques), `house_ui.gd` (cama/parede), `progression_ui.gd` só `petshop_panel`,
   `routes_panel` (Pomar), `walk_diary`, `collection_panel`.
4. **Avisos e diversos**: `settings_panel.gd`, `scenes/ui/celebration/` + `reward_sheet.gd` (`show_unlocks` "Novo!"),
   `scenes/ui/quest_reward/`, `inventory_list.gd` (cartões "Presentes para guardar"/"Achados do passeio"),
   `market_ui.gd` `customer_info`, `scenes/ui/trick_training/`, `hide_seek_ui.gd`, aviso "Missão concluída" se ainda liso.

Cada lote: script de capturas próprio `game/tests/<lote>_wood_shots.gd` (modelo: `tests/storage_wood_shots.gd`,
com medidas que imprimem FAIL), capturas nas três resoluções (360x780, 390x844, 412x915), testes afetados
(`tools/test_areas.json` diz as áreas; `tools/test.ps1 -Level etapa -Exact -Tests ...`). Relatório: o que mudou, nós
novos/renomeados, testes e capturas.
