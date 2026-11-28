# Criações: comprar animal por animal (galinheiro e curral)

Decisões do Vitor (27/11/2026):
- O galinheiro (kit da banca, capítulo 4) chega **vazio**. Uma missão pede para juntar moedas e **comprar a primeira galinha**.
- **Cada galinha comprada abre o próprio espaço de produção** (tempo e ovo próprios). Os espaços que ainda cabem aparecem como "+ Comprar" com o preço.
- Preço sobe por galinha: **1ª 30, 2ª 50, 3ª 80** (4ª 120 depois da ampliação).
- Galinheiro **começa com 2 lugares**; uma **ampliação** (depois da semana) leva para **4**.
- Botão **"Alimentar todas"**: um toque alimenta todas as galinhas livres (1 ração por galinha); tocar numa galinha alimenta só ela.
- **Curral com a mesma regra** (vem vazio, vaca por vaca, ampliação para 4).

## Como funciona hoje (o que muda)

- Cada abrigo tem **uma vaga só** (`config.json → stations.<abrigo>.slots: 1`) e **um lote multiplica por todos os animais** (`GameState.recipe_quantity/recipe_inputs` × `animal_count`). As "colunas por animal" da bandeja são só desenho.
- O kit `week_coop` (`progression.json → shop_items`) constrói o galinheiro com `gift_animal_count: 2` (2 galinhas brancas grátis, abrigo cheio 2/2 na semana). O curral (`upgrades.cow_barn`) dá 1 vaca de presente.
- Capacidade: `animal_capacity` 3, `week_animal_capacity` 2; o mapa só tem `hen_1/hen_2` e `cow_1/cow_2`.
- Preço por variedade fixo (`config.json → animals.<id>.price`: 120/150/180 e 220/280/340).

## Regra nova (motor)

1. **Um animal = um espaço.** Nos abrigos (`kind: "animal"`), `station_slots(abrigo)` = número de animais. Cada lote é de **um** animal: entradas e quantidade da receita **por animal** (sem multiplicar). O lote guarda `slot` (índice do animal em `animal_roster`) e `animals: [variedade]`.
2. **Lotes em paralelo** nos abrigos: o lote começa na hora (não espera o anterior, ao contrário do fogão). `StationState` ganha um `enqueue` paralelo e guarda `slot` no save.
3. **Alimentar todas** = `cook_many(receita, N)` com N = animais livres que a ração paga (`cook_max`); cada lote vai para o primeiro animal livre. Com N = 1, alimenta o primeiro livre (ou o animal tocado, se a interface passar o índice).
4. **Capacidade**: `animal_capacity` base 2 + `capacity_upgrades` (`chicken_coop_2`/`cow_barn_2`: +2). Sem capacidade especial da semana.
5. **Preço** = `stations.<abrigo>.animal_prices[quantos já tem] + animals.<variedade>.price_extra`.
   - Galinheiro: `[30, 50, 80, 120]`; branca +0, ruiva +20 (depois de 8 ovos), preta +40 (depois de 24 ovos).
   - Curral: `[80, 120, 170, 230]`; pintadinha +0, caramelo +30 (8 leites), malhada +60 (24 leites).
   - Consultas: `GameState.animal_price(id)`, `buy_animal_error/buy_animal` usam o preço novo e contam `buy_animal:<abrigo>` e `buy_animal`.
6. **Sem animal de presente**: tirar `gift_animal`/`gift_animal_count` do kit e do curral.
7. **Ampliações** novas em `progression.json → upgrades`: `chicken_coop_2` (150 moedas + 4 tábuas; requer `owned chicken_coop` e `growth: teething`) e `cow_barn_2` (260 + 6 tábuas; `owned cow_barn`). Aparecem como espaço trancado "Ampliar" na faixa e na loja de animais.
8. **Ração e tempos** ficam como estão (por animal): semana 1 milho → 1 ovo em 30 min; depois 2 milhos → 2 ovos em 15 min; vaca 2 trigos → 2 leites em 30 min.

## História e missões

- `week_coop` (cap. 4, ordem 10): "Montar o galinheiro" — o kit monta o galinheiro e o canteiro de milho (fala nova: galinha se compra depois, com o dinheiro da colheita).
- **Nova `week_hen`** (cap. 4, ordem 15): "A primeira galinha" — junte 30 moedas vendendo a colheita e compre uma galinha (`stat buy_animal:chicken_coop` 1; Ir = galinheiro). Prêmio: 2 milhos (para a primeira alimentação).
- `week_eggs` (ordem 20): "O primeiro ovo" passa a pedir **1** ovo.
- Linha da vovó: falas de `main_9_coop`/`main_9_cows` sem presente; **nova `bloblo_first_cow`** (ordem 105): comprar a primeira vaca; `bloblo_milk` depois dela.
- Rotina diária "Pegar ovos" só com ao menos uma galinha.

## Mapa e interface

- `rooms/farm.json` (via `tools/build_farm_figma.py`): `hen_1..hen_4` e `cow_1..cow_4` dentro dos cercados; cada um aparece quando o animal daquele índice existe.
- Bandeja do abrigo (`StationTray.animal` / `StationWood.herd_row`/`station_strip`): uma coluna por animal (retrato + o lote dele), depois "+ Comprar · preço" para cada lugar livre e "Ampliar" se houver ampliação; botão principal "Alimentar todas (N)". Abrigo vazio: "Compre sua primeira galinha" + botão comprar.
- Loja (`AnimalShopUi`): preço do próximo animal por variedade, barra "Galinheiro · 1/2", cartão de ampliação quando cheio.
