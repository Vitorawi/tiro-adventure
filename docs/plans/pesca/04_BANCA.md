# 04 — Banca do Sítio: Vender · Comprar

> Pedido do Vitor (11/11/2026): "já vale pensar na banca do sítio de vender lá também poder comprar, vai ser
> bom para outras coisas do jogo". Entra como **etapa 04** do plano da pesca (antes do tutorial, porque a
> missão `bloblo_worms` ensina a comprar minhocas ali), mas o motor é **genérico**: qualquer loja do jogo
> pode usar.

## 1. O que existe hoje

- Banca da vovó = lugar `farm.places.early_market` (escondido, painel `sell`, desde `bloblo_meet`), aberto
  pelo toque na banca pintada no fundo do Sítio. Tela `SellUi` (madeira, só vende).
- Feirante da Vila = `village.places.market`, mesma `SellUi`.
- Compra genérica já existe mas presa ao pet shop: `progression.json → shop_items` (`{name, items, price,
  shop, icon}`), `GameState.buy_shop_item_error/buy_shop_item(id)`, exige `has_upgrade(shop)`; um item só
  (`dog_food_pack`). Roupas do pet shop usam `buy_cosmetic` (fica como está).

## 2. Motor genérico

### Dados

```json
"shops": {
  "farm_stall": {"name": "Banca da vovó", "world": "farm", "place": "early_market", "npc": "bloblo",
                 "requirements": {"quests": ["bloblo_meet"]}},
  "market":     {"name": "Feirante", "world": "village", "place": "market",
                 "requirements": {"chapter": 4}},
  "petshop":    {"name": "Pet shop", "world": "park", "place": "petshop",
                 "requirements": {"owned": ["petshop"]}}
},
"shop_items": {
  "worm_pack":     {"shop": "farm_stall", "name": "Minhocas", "items": {"bait_worm": 5}, "price": 10,
                    "icon": "item_bait_worm", "requirements": {"rod": "bamboo_rod"}, "max": 5},
  "food_stall":    {"shop": "farm_stall", "name": "Ração da vovó", "items": {"dog_food": 3}, "price": 10,
                    "icon": "item_dog_food", "requirements": {"quests": ["bloblo_meet"]}, "daily": 2},
  "dough_pack":    {"shop": "market", "name": "Massa de milho", "items": {"bait_dough": 4}, "price": 20,
                    "icon": "item_bait_dough", "requirements": {"rod": "reel_rod"}, "max": 5},
  "lure":          {"shop": "market", "name": "Isca artificial", "items": {"bait_lure": 1}, "price": 25,
                    "icon": "item_bait_lure", "requirements": {"rod": "angler_rod"}, "max": 3},
  "dog_food_pack": {"shop": "petshop", "name": "Pacote de ração", "items": {"dog_food": 5}, "price": 15,
                    "icon": "item_dog_food"}
}
```

- `shop` aponta para `shops`; item sem `requirements` herda só os da loja.
- `max` = quantos pacotes por compra (padrão 10). `daily` = limite por dia local (ausente = sem limite).
- Compatibilidade: `shop: "petshop"` continua funcionando (o requisito da loja é o mesmo `owned petshop`).

### Ações no `GameState`

| Função | Faz |
|---|---|
| `shop_error(loja)` | requisitos da loja (`requirement_error`) |
| `shop_items(loja)` | itens **revelados** (requisitos ok) em ordem do JSON; bloqueados não aparecem, exceto o próximo a liberar (uma dica, como as sementes da horta) |
| `buy_shop_item_error(id, qty := 1)` | loja aberta, requisitos, `qty` entre 1 e `max`, `daily` restante, moedas ≥ preço × qty, `storage_error(itens × qty)` |
| `buy_shop_item(id, qty := 1)` | cobra, entrega, conta `bought:<item>` (por unidade), `bought_shop:<loja>`, `buy:<id>`; registra `daily` |
| `shop_daily_left(id)` | quantos ainda hoje |

Estado salvo: `progress.shop_daily = {"<id>": {"day": <dia local>, "n": 2}}`; o dia só avança (como o
`FriendState.window_index`): atrasar o relógio não reabre o estoque. Nenhum número fixo no código.

## 3. Catálogo e quando aparece

| Loja | Pacote | Quando | Por quê |
|---|---|---|---|
| Banca da vovó | **Ração da vovó** ×3 · 10 moedas, 2 por dia | cap. 2 (`bloblo_meet`) | o Filhotinho come ração e o pet shop só abre bem depois; hoje a ração só vem de presentes |
| Banca da vovó | **Minhocas** ×5 · 10 moedas | vara de bambu | isca da vara 1 |
| Feirante | **Massa de milho** ×4 · 20 moedas | vara de molinete | isca da vara 2 (também se faz no fogão) |
| Feirante | **Isca artificial** ×1 · 25 moedas | vara do pescador | isca da vara 3 |
| *(futuro)* Banca | **Oferta do dia**: 1 material em pouca quantidade (2 madeiras, 2 pedras…) com `daily: 1` | **aprovada pelo Vitor**; ligada na etapa 10 | destrava quem ficou sem material; precisa medir na etapa 10 antes |

Preços casam com a economia R1 (moeda curta no começo): 10 moedas = uma encomenda pequena. A etapa 10 mede
e ajusta.

## 4. Tela

`SellUi` (`scripts/ui/sell_ui.gd`) passa a montar a banca inteira; o nome fica para não quebrar quem chama
(`MarketUi.sell(world_id)`). A moldura, a placa, o X e o vendedor não mudam.

- **Abas no topo** (molde de `MissionUi.tabs`, madeira): `ShopTab_sell` "Vender" e `ShopTab_buy`
  "Comprar". A aba Comprar só aparece se `shop_items(loja)` tem algum item; senão a banca fica igual à de
  hoje (nenhuma aba). Selo "!" na aba Comprar quando um pacote novo foi revelado e ainda não visto
  (`progress.seen["shop_item:<id>"]`).
- **Comprar:** grade `BuyGrid` de 2 colunas com cartões `Buy_<id>` (mesmo cartão creme da venda): ícone
  no pratinho, "×5" (`Pack`), nome, pílula marrom com moeda e preço (`Price`), "2 hoje" (`DailyLeft`) se
  houver limite. Escolhido = contorno dourado. O próximo bloqueado aparece apagado com cadeado e o motivo
  curto ("Ganhe a vara").
- **Tábua embaixo** (`station_board`, como a venda): pratinho com o item, `Quantity` (`Minus`/`QuantityValue`/
  `Plus`/`QuantityMax` "Máx"), total `BuyTotal` na caixinha da moeda e o verde `BuyItem` "Comprar".
  Não dá: `StepCardUi.locked_button` com o motivo ("Faltam 4 moedas", "Despensa cheia", "Volta amanhã").
- Compra feita: `CollectFx` com os itens voando para a aba Mochila, moedas contam no HUD, cartão pula.
- Lembrar a última aba só na sessão; abrir pela missão de minhocas abre direto em Comprar
  (`Places.run("early_market:buy")`, foco `buy:<id>` destacando o pacote).

## 5. Ir, Como fazer e mapa

- `Database.item_sources(item)` passa a listar a loja ("Banca da vovó · 10 moedas") com Ir → abre a banca
  na aba Comprar com o pacote escolhido. Vale para minhoca, massa, isca e ração.
- `TaskHelp` da isca que falta = "Comprar na banca" (Ir) + "Colher na horta" (minhoca).
- Nada novo no mapa: a banca já é tocável. Etiqueta (segurar 500 ms) passa de "Vender" a "Banca da vovó".

## 6. Testes e capturas

- `shop_test` (área nova `shops`, também em `market`): loja fechada, item escondido/dica, preço × qty,
  moedas faltando, depósito cheio não cobra, `max`, `daily` (inclusive relógio para trás e virada de dia),
  contadores, pet shop igual ao antigo, `item_sources` com a loja.
- `market_test`, `petshop_test` e o bloco "Feira" do `ui_style_test` sem regressão.
- `tests/shop_shots.gd` → `build/screenshots/shop/`, três resoluções, FAIL nas medidas: banca só com
  Vender (sem abas), banca com abas na Vender, Comprar com 1 e 3 pacotes, bloqueado, sem moedas, limite do
  dia esgotado, Feirante com massa e isca.
