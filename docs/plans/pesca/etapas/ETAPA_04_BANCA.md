# Etapa 04 — Banca do Sítio: Vender · Comprar (lojas genéricas)

> Tamanho: média. Depende de: 01 (itens de isca e requisito `rod`). Próxima: 05.
> Resultado que o Vitor vê: a banca da vovó (e o Feirante) ganha duas abas de madeira no topo, **Vender** e
> **Comprar**. Em Comprar aparecem os pacotes (ração da vovó; minhocas depois da vara), com quantidade, total e
> o botão verde "Comprar". Enquanto não houver nada para comprar, a banca fica igual à de hoje.

## 1. Ler antes

- **`docs/plans/pesca/04_BANCA.md` inteiro** (dados, ações, catálogo, tela) — é a especificação desta etapa.
- `CLAUDE.md`: "Venda madeira ilustrada" (`SellUi`, `sheet_bare`, nós `SellBoard/SellGrid/Sell_<id>/SellPanel`,
  `Quantity/Minus/QuantityValue/Plus/QuantityMax`, `SellTotal`), "Missões madeira ilustrada" (abas
  `MissionUi.tabs`), "Botão bloqueado de madeira".
- Código:
  - `game/autoload/game_state.gd` l. ~1781–1802: `buy_shop_item_error(id)` / `buy_shop_item(id)` (hoje exige
    `has_upgrade(shop)` e compra 1).
  - `game/scripts/ui/progression_ui.gd` l. ~836–885: `petshop_panel()`; **l. ~865 percorre TODOS os
    `shop_items`** — depois desta etapa precisa filtrar `shop == "petshop"`.
  - `game/scripts/ui/sell_ui.gd`: `build(world_id)` (l. ~86), `seller(world_id)`, `_frame`, `_grid_area`,
    `_card`, `_board`, `_quantity_row`, `_total_pill`, `scrolled`, `overlay`.
  - `game/scripts/ui/mission_ui.gd`: `tabs(entries, selected, on_choose)` (l. ~323) — abas de madeira.
  - `game/scripts/ui/places.gd`: `run(world, "market:...")` (l. ~245), `_panel(kind == "sell")`.
  - `Database.sources_of(item)` (`database.gd` l. ~400) e `GameManual.sources` (de onde vem um item).

## 2. Como está hoje

Banca = `farm.places.early_market` (`panel "sell"`), Feirante = `village.places.market` (`panel "sell"`), ambos
`SellUi.build(world_id)`. Compra genérica só no pet shop, 1 item (`dog_food_pack`).

## 3. Passo a passo

1. **Dados** (`progression.json`): seção `shops` e `shop_items` exatamente como `04_BANCA.md` §2
   (`farm_stall`, `market`, `petshop`; pacotes `food_stall`, `worm_pack`, `dough_pack`, `lure`,
   `dog_food_pack`). `dough_pack` e `lure` já entram, com requisitos de vara (só aparecem nas etapas 07/08).
   `worlds.json → farm.places.early_market.name` = "Banca da vovó".
2. **`Database.shop(id)`, `Database.shop_of_place(world, place)`** e `shop_problems()` (todo item aponta
   para loja existente; `items` existem; `price > 0`; `max ≥ 1`; `daily ≥ 1` se existir) chamado no
   `content_test`.
3. **`GameState`** (substitui as duas funções atuais, mesma assinatura com `qty` opcional):
   - `shop_error(shop_id)`; `shop_items(shop_id) -> Array[String]` (revelados + **um** próximo bloqueado como
     dica, igual às sementes da horta); `shop_daily_left(id) -> int` (−1 = sem limite);
   - `buy_shop_item_error(id, qty := 1)`: loja (`shop_error`), requisitos do item (`requirement_error`), `qty`
     entre 1 e `max` (padrão 10), limite do dia, moedas ≥ `price·qty` ("Faltam N moedas"),
     `storage_error(itens·qty)`;
   - `buy_shop_item(id, qty := 1)`: cobra, `inventory.add`, `_count("bought:" + item, unidades)`,
     `_count("bought_shop:" + loja, qty)`, `_count("buy:" + id, qty)`, grava o dia; `_changed()`;
     emite `Events.items_gained(itens, 0, "shop")` para o `CollectFx` voar os itens.
   - Estado do limite diário: `progress.shop_daily = {"<id>": {"day": int, "n": int}}` em
     `ProgressionState` (`to_dict/from_dict`). Dia = dia local de `_local_time()`; guardar também o maior dia já
     visto (`shop_day_max`): se o relógio voltar, usa o maior (não reabre). `SAVE_VERSION` sobe se a 01 já
     tiver fechado a versão (formato novo de save).
4. **Tela** (`sell_ui.gd`): `build(world_id)` passa a desenhar a banca inteira:
   - `shop_id = Database.shop_of_place(world_id, lugar_de_venda)`; `buy_ids = GameState.shop_items(shop_id)`;
   - sem `buy_ids` → **exatamente** a tela de hoje (sem abas). Com `buy_ids` → abas `MissionUi.tabs` no topo
     do papel (`ShopTab_sell` "Vender", `ShopTab_buy` "Comprar"; nomes de nó `NotebookTab_sell/_buy` como as
     outras abas de madeira), com "!" na Comprar quando há pacote revelado e não visto
     (`progress.seen["shop_item:<id>"]`, marcado ao abrir a aba);
   - aba **Comprar**: `_buy_grid` (2 colunas, mesmo `sell_card.png`), cartão `Buy_<id>` com `Picture`
     (ícone do primeiro item, pixel em escala inteira), `Pack` "×5", `Caption` (nome), `Price` (moeda + preço),
     `DailyLeft` "2 hoje" se houver limite; escolhido = contorno dourado (`meta selected`); o próximo bloqueado
     aparece apagado com `LockIcon` e `LockText` curto;
   - tábua da Comprar (`_buy_board`, mesmo `station_board`): pratinho, `_quantity_row(qty, max_ok, …)` (máx. =
     menor entre `max`, limite do dia, moedas ÷ preço, espaço), `BuyTotal` (caixinha da moeda) e o verde
     `BuyItem` "Comprar" (`StepCardUi.go_button`, meta `wood_primary`); erro →
     `StepCardUi.locked_button(motivo, ícone, ajuda)` (`Locked_BuyItem`, meta `reason`);
   - modelo da folha guarda `tab` ("sell"/"buy") e `buy_selected`; a última aba fica só na sessão
     (variável estática).
5. **Ir direto para a compra**: `Places.run(world, "shop:<id>")` abre a banca/Feirante na aba Comprar com o
   pacote escolhido (viaja antes se precisar). `Database.sources_of(item)`/`GameManual.sources` passam a listar
   "Banca da vovó · 10 moedas" para os itens vendidos em loja, com destino `{"world", "place", "action":
   "shop:<id>"}`. `TaskHelp.describe("item", …)` mostra a loja como primeiro passo quando é a origem mais simples.
6. **Pet shop**: `petshop_panel` passa a usar `GameState.shop_items("petshop")` (corrige a l. ~865), sem mudança
   visual.

## 4. Não fazer

Mudar a aba Vender, as encomendas ou a banca própria da Vila (`contracts`). Oferta do dia (fica para a 10).
Mudar preços de venda.

## 5. Armadilhas

- `SellUi.build` hoje usa `tick_refresh = false`: a aba Comprar também não refaz a cada segundo (o limite do dia
  só muda na virada de dia; refazer ao abrir é suficiente).
- `MissionUi.tabs` foi feito para a moldura das Missões: medir onde cabe sobre a moldura da venda (plaquinha +
  X); se não couber em 360 px, abas dentro do papel, logo abaixo da placa.
- Todo texto de erro vem do `GameState` (não montar texto na UI).

## 6. Testes

Novo **`game/tests/shop_test.gd`** (área nova `shops`; também listar em `market`), com relógio injetado:
1. Loja fechada (`bloblo_meet` não feita) → `shop_error` explica; `shop_items` vazio.
2. Item com requisito (minhoca sem vara) não aparece, mas é a dica bloqueada (um só).
3. Compra de `qty 3`: cobra `3·preço`, entrega `3·itens`, conta `bought:<item>` por unidade.
4. Sem moedas → "Faltam N moedas", nada muda. Depósito cheio → erro do depósito, nada cobrado.
5. `max` respeitado; `qty 0` e `qty > max` recusados.
6. `daily 2`: 2 compras ok, a 3ª "Volta amanhã"; virar o dia reabre; voltar o relógio não reabre.
7. Pet shop: `dog_food_pack` igual ao comportamento antigo; `petshop_panel` mostra só os itens dele.
8. Tela: banca sem itens = sem abas (nós `NotebookTab_buy` ausentes); com itens = duas abas; Comprar mostra
   `Buy_food_stall`; `BuyItem` compra e a quantidade/total batem.
9. `Places.run("farm", "shop:worm_pack")` abre em Comprar com o pacote escolhido.
10. `sources_of("bait_worm")` inclui a banca.
Afetados: `market_test`, `petshop_test`, `ui_style_test` (bloco "Feira"), `content_test`, `item_sources_test`.

## 7. Capturas

`game/tests/shop_shots.gd` → `build/screenshots/shop/`, três resoluções, FAIL nas medidas: banca sem abas;
banca com abas na Vender; Comprar com 1 e 3 pacotes; pacote bloqueado; sem moedas; limite do dia esgotado;
Feirante com massa e isca (via DEV dando as varas).

## 8. Pronto quando

Testes PASS, capturas abertas, a aba Vender idêntica à de antes (comparar com `build/screenshots/sell_wood/`),
registro no README do plano, ROADMAP, `CLAUDE.md`/`AGENTS.md` (parágrafo "Venda madeira ilustrada" + linha
nova "Lojas (comprar)" no "Onde trabalhar").

## 9. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 04 do plano "Pesca na lagoa da vovó" (banca com Vender · Comprar).
Leia CLAUDE.md, docs/plans/pesca/README.md, docs/plans/pesca/04_BANCA.md e
docs/plans/pesca/etapas/ETAPA_04_BANCA.md antes de editar. A aba Vender não pode mudar.
Registre shop_test em suite e nas áreas shops/market. Capturas SEM --headless nas três resoluções.
Ao terminar: Registro da 04 no README do plano, ROADMAP, CLAUDE.md = AGENTS.md.
Sem commit/push/publicação. Não executar a 05.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
