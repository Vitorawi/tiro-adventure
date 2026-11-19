# E10. Carroça do Feirante

## Referências

Claude Docs (projeto `b45e1b2e-da97-4e57-af6f-b9e8a342ad66`) e Artifact indisponíveis nesta sessão. Consultadas as cópias do cache em `%TEMP%/claude/ecb7a66fe8453e1f/`: `10ea2159-07a2-4098-8ec8-bab61252a04f/scratchpad/plano.md` (plano da primeira semana) e `21190024-f3e9-4ba7-b173-5032cd6fff58/scratchpad/artifact-files/ed7f930e-e696-49f1-8c44-533a90384d65/project/Banca.dc.html` (canvas, prancha T4).

## Arquivos e execução

- Regras e recibos em `game/autoload/game_state.gd`, `game/scripts/state/week_state.gd` e `game/autoload/save_manager.gd`.
- Catálogo em `game/data/progression.json`, `items.json` e `growth.json`. Destino e cenário em `worlds.json`, `rooms/farm.json` e `tools/build_farm_figma.py`.
- Interface em `game/scripts/ui/places.gd`, `orders_ui.gd`, `sell_ui.gd`, `trick_lesson.gd`, `progression_ui.gd`, `pet_care_tray.gd` e `pet_animator.gd`.
- Testes em `game/tests/cart_test.gd`, `play_week_test.gd`, `trick_use_test.gd`, `content_test.gd` e `coins_test.gd`, com registro em `tools/test_areas.json`.

1. Definir a abertura, os pedidos, a gorjeta e o catálogo em `game/data`. Usar o relógio da semana e guardar os recibos de entrega no save 29.
2. Colocar a carroça junto ao portão em `rooms/farm.json` e no gerador. Reutilizar a folha, as linhas de compra, as encomendas e os gestos de truques da E08.
3. Ligar o lacinho à coleção, a bolinha ao Quintal e o xampu ao banho caprichado em Cuidar. Reaproveitar os efeitos do banho e preservar a idle aprovada.
4. Registrar `cart_test`, rodar o circuito de etapa, os testes de brincadeiras e truques e o portão M2. Abrir capturas nas três resoluções e registrar o roteiro de celular.

Pronto quando a carroça abrir no dia 5, oferecer dois pedidos por dia estáveis até a virada, as compras e o banho funcionarem e `cart_test` passar.

## Implementação

- A carroça e o Feirante aparecem na estrada, à direita do portão do Sítio, a partir do dia 5. Qualquer um dos dois abre a folha. A Banca da vovó continua recebendo a venda avulsa.
- A T4 define os pedidos da estreia. Três ovos pagam 30 moedas, com mais 5 se o jogador acertar Senta. Duas abóboras e uma tilápia pagam 38. Os pares dos dias seguintes, os valores e o desconto variam no catálogo `progression.json → cart_orders/cart_catalog`. A E15 calibra os valores que a referência deixou em aberto.
- O dia civil da semana escolhe o par. A folha mostra quando a entrega foi feita ou qual item falta. A encomenda com truque abre o mesmo gesto da tigela quando Tiro já sabe aquele truque. Pular, errar ou deixar o tempo passar entrega pelo valor-base. O acerto paga a gorjeta na mesma transação que retira o estoque. A virada invalida a confirmação antiga. `WeekState.cart_deliveries` persiste os recibos no save 29, com reset sem migração.
- A loja reutiliza `shop_pack`, os limites e as compras de `GameState`. Xampu de filhote custa 30, o lacinho custa 45 e a bolinha que apita custa 35. A oferta alterna xampu, aveia e minhocas e pode ser comprada uma vez por dia. O lacinho entra na coleção para vestir no Caderninho. O Quintal usa a bolinha que apita após a compra. O dia 1 continua com a de pano e a ponte da lagoa continua disponível no dia 6.
- **Tiro → Cuidar → Banho → Xampu** usa um frasco do xampu de filhote e concede dois momentos de Pelagem. Usa as bolhas e a reação Animaref do banho existentes. A idle aprovada foi conferida pelo SHA-256 `FB010A541283D6FF575032EDF172642B569B0D22EAE062A11F1E4F0D9D4CA0B5`.

## Conferência no celular — M2

1. Comece um save novo no DEV. No dia 1, atravesse o Mapa até o Sítio, compre um canteiro na banca da vovó e abra o Quintal pelo cesto. Faça uma partida com a bolinha de pano.
2. No dia 2, monte o galinheiro, plante milho e recolha ovos. Aprenda **Senta** no tapete com a vovó. Confira a pesca no dia 3 e as duas árvores e a cordinha no dia 4.
3. Antes do dia 5, confira o portão livre. Vá ao dia 5 às 9h. Arraste o mapa até a entrada, toque na carroça e confira os dois pedidos. Tente um pedido com item faltando. Entregue três ovos, faça o gesto de **Senta** e confira 35 moedas. Na volta, confira **Já entregue**. Feche e reabra a PWA para conferir o recibo e a oferta.
4. Confira os preços, role até a oferta e compre uma vez. Vista o lacinho no Caderninho e veja o Tiro em repouso. Jogue uma partida no Quintal antes e outra depois da compra da bolinha. Compare alcance, Felicidade e som com o volume do celular ligado.
5. Abra **Cuidar → Banho → Xampu** e confira a espuma, a reação do Tiro, o consumo de um frasco e os dois momentos de Pelagem. Confira também a opção de banho comum.
6. Às 23h do dia 5 avance uma hora. Confira os dois pedidos novos e a nova oferta. No dia 6, lance na ponte e confira o quique, o Esconde-esconde e o Show. Faça o roteiro com toque e rolagem de uma mão. O aparelho físico fica para a conferência do Vitor.

## Validação

- Rodada de etapa incluindo `farm,world,week,market,shops,pet,growth,tricks,saves,checks` e áreas descobertas pelo ChangeList. Foram 96 testes em 859,9 s. Com retestes, 86 PASS, nove falhas históricas e um timeout histórico. Logs `build/e10_etapa.log`, `build/e10_retest_*.log` e `build/e10_confirm_*.log`.
- Repetiram a E09 `hud_growth_test`, `tray_test`, `world_selector_test`, `world_view_test`, `tasks_test`, `item_sources_test`, `text_budget_test` e o timeout de `care_ui_test`. `onboarding_test` repete a linha de base da E07 (`build/e07_baseline_onboarding_test.log`), parada em `bloblo_first_fish`. `station_tray_test` repete o bloqueio histórico da bandeja com o tutorial da pesca. `trick_use_test` passou após retirar da fixture a segunda aplicação do deslocamento DEV. `coins_test` passou com a fixture da banca do dia 1 alinhada à E06. `content_test` e `market_test` passaram nos retestes com catálogo da carroça e da Vila independentes.
- `cart_test` cobre o circuito integrado desde o dia 1, entrega com gesto e gorjeta, virada, recibos e compras, toque no mapa e em Cuidar, lacinho no filhote e opção da lagoa no Quintal. `play_week_test`, `trick_use_test` e `farm_week_test` também passaram. Foram abertas 24 capturas nativas de 360×780, 390×844 e 412×915 em `build/screenshots/e10_cart/`. O roteiro acima fica para o aparelho físico.
- Portão M2 geral (`tools/test.ps1 -Level portao -Jobs 5 -KeepGoing`): 155 testes em 1.025,8 s, com 133 PASS, 21 falhas e um timeout na primeira passada. `farm_market_label_test` passou isolado, como já havia passado na rodada de etapa. Consolidado: 134 PASS, 20 falhas e um timeout. `cart_test` passou em 32,5 s. Também passaram `farm_week_test`, `play_week_test`, `trick_use_test`, `puppy_bath_test`, `care_choice_window_test`, `market_test`, `coins_test` e `content_test`. [Resultados do portão](../../../../build/test_logs/r20261118_200253_82bf689e/results.csv).
- Ressalvas do portão: além das falhas da rodada de etapa, ficaram `food_menu_bounds_touch_test`, `food_order_touch_test`, `blender_position_touch_test`, `drag_scroll_test`, `mood_test`, `walk_return_test`, `photo_rarity_test`, `card_reveal_test`, `ready_badges_test`, `dev_tools_test` e `nature_routes_test`. O reteste de `card_reveal_test` imprimiu PASS, mas ainda emitiu erros em `CardViewer._layout_later`, então segue como falha no consolidado. Logs em `build/e10_portao.log` e `build/e10_portao_retest_*.log`.
