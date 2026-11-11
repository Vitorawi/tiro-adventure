# Etapa 07 — Vara de molinete (Feirante), peixes médios, ensopado e baú da lagoa

> Tamanho: grande. Depende de: 06. Próxima: 08.
> Resultado que o Vitor vê: no capítulo 5, o Feirante passa a vender a **vara de molinete** (aba Comprar). Com
> ela e a **massa de milho**, a lagoa dá **carpa, pacu e tambaqui**, peixes maiores e mais difíceis. Às vezes
> aparece um **baú** no minigame. O Aventureiro precisa de 2 **ensopados de peixe**.

## 1. Ler antes

- `01_DESENHO.md` §4 (baú), §7 (varas/iscas), §8 (peixes da vara 2); `02_HISTORIA §1` (capítulos 5–6) e §2.
- `04_BANCA.md` (motor de lojas). `CLAUDE.md`: "Feira, venda inicial e banca própria" (linha `merchant`),
  "Obras/recompensa automática" (`_grant_automatic` e recibos).
- Código: linha `merchant` em `quests.json` (`merchant_meet 10 … merchant_orders 30, merchant_regular 40,
  merchant_variety 45, merchant_stall 50…`); `growth.json → explorer` (`meals growth_kibble 3 body_level 4`,
  `key stick_chew`, `walks 3`); `progression.json → orders` (formato com `customer`); itens `corn`, `fiber`.

## 2. Passo a passo

1. **Loja vende vara**: `shop_items` aceita `"rods": ["reel_rod"]` (em vez de/junto com `items`) e
   `"materials": {"fiber": 4}` (consumidos junto com o preço). `buy_shop_item_error` verifica `materials`
   (`_missing_text`, como `upgrade_error`) e "Você já tem" se a vara já é sua; `buy_shop_item` chama
   `give_rod`. Pacote `reel_rod_pack` no `market`: `price 180`, `materials {fiber 4}`, `rods [reel_rod]`,
   `requirements {chapter 5, fishing_level 3}`, `max 1`. Requisito novo `fishing_level` em
   `GameState.requirement_error` ("Pesca nível 3").
2. **Missão** `merchant_fishing` "Vara nova" (`line merchant`, `order 35` — entre `merchant_orders` 30 e
   `merchant_regular` 40 —, `requirements {chapter 5, rod: bamboo_rod}`, goal `{type stat, key
   "rod:reel_rod", target 1, label "Comprar a vara de molinete"}`, `go {world village, place market, action
   "shop:reel_rod_pack"}`, rewards coins 20 + `bait_dough 4`). Fala do Feirante: "Vara de bambu é boa pra
   lambari. Peixe grande pede molinete!"
3. **Massa de milho**: receita `bait_dough` (fogão, `corn 2` → `bait_dough 4`, 300 s, `requirements {rod:
   reel_rod}`); `dough_pack` (da 04) já fica visível com a vara.
4. **Peixes da vara 2** já estão no `fishing.json` (01). Confirmar que `cast` com massa sorteia só eles e que as
   faixas/dificuldades da tabela foram usadas. Momento de Coragem na primeira de cada (01).
5. **Baú da lagoa** (`01_DESENHO §4`):
   - `fishing.json → chest.loot` (sorteio `Loot.roll` com semente da partida): `[{coins [10,30], w 50},
     {bolt 1, w 20}, {bait_lure 1, w 10, requirements rod angler_rod}, {seed_pack…}]` — **só itens que
     existem** (confirmar ids em `items.json`; sem sementes se não houver item de semente);
   - `FishingSim`: `chest_y`, `chest_meter`, `chest_open` — aparece depois de `appear_after` s numa altura a
     ≥ 0,3 do peixe; enche a `fill` 0,5/s enquanto a barra cobre o baú; nunca esvazia;
   - chance decidida no `hook` (semente; nunca no tutorial, nunca na primeira vez da espécie); grava
     `cast.chest = true`; `FishingGame` desenha o baú (`ui/fishing/chest.png`) com o anelzinho próprio;
   - `finish_fishing({…, chest: chest_meter ≥ 1})`: só entrega se pegou o peixe; prêmio por
     `_grant_automatic("fish_chest:<seq>", …)` (o que não couber vira recibo em "Presentes para guardar");
   - resultado: chip extra "Baú!" no `FishResult`; dica de primeira vez `fishing_tip:chest` com pausa curta.
6. **Ensopado de peixe**: item `fish_stew` (`food`, `fridge`, `feed {hunger 45, energy 15}`, `growth {phases
   [explorer, young]}`, venda 35) e duas receitas `fish_stew_carp` (`fish_carp 1, carrot 1, potato 1`) e
   `fish_stew_pacu` (`fish_pacu 1, carrot 1, potato 1`), saída 2, 480 s, `requirements {rod: reel_rod}`.
   Também `fish_stew_tambaqui` igual. Ícone `item_fish_stew.png` (PixelLab, da 03; sem ilustrado).
7. **Aventureiro** (`growth.json → explorer.requirements`): `{"id": "fish_meal", "type": "feed", "item":
   "fish_stew", "qty": 2, "label": "Ensopado de peixe"}` (sem `body_level`).
8. **Missões**: `bloblo_carp` (`line bloblo`, `order 115`, goal `fish:fish_carp` 1, coins 25) e
   `lais_fish_stew` (`kind main`, `chapter 6`, `order 25` — entre `main_5_cooking` o30? **confira**: use uma
   ordem livre antes de `explorer_6_eggs` o45 —, goals `produce:fish_stew` 1 + `feed:fish_stew` 1, coins 30).
9. **Encomenda** `lais_fish_lunch` em `progression.json → orders` (molde das encomendas com `customer`):
   2 `fish_pacu` + 1 `fish_stew`, 90 moedas, `customer lais`, requisito `rod reel_rod`.
10. **Painel de arremesso**: com 2 varas aparece `RodRow`; trocar de vara muda as iscas aceitas.

## 3. Não fazer

Vara 3, pintado/tucunaré/traíra, prato do pelo.

## 4. Testes

Novo **`game/tests/fishing_rod2_test.gd`** (área `fishing` + `market` + `growth`):
1. Pacote da vara invisível antes do cap. 5 / nível 3; visível depois; compra cobra 180 + 4 fibras e dá a vara.
2. Comprar de novo → "Você já tem".
3. Massa sorteia só carpa/pacu/tambaqui; minhoca com a vara 2 continua dando os peixes da vara 1.
4. A barra da vara 2 é maior e o dreno menor (`hold 0,15`).
5. Baú: semente com baú → cobrir o baú e pegar o peixe entrega o prêmio uma vez; peixe escapa → nada; baú não
   aparece no tutorial nem na primeira de uma espécie.
6. Item do baú sem espaço vira recibo.
7. Ensopado: as três receitas; Aventureiro exige 2 ensopados; Corpo não muda.
8. Missões e encomenda concluem com os contadores certos.
Afetados: `shop_test`, `market_test`, `customers_test`, `growth_meals_test`, `growth_ui_test`, `journey_test`,
`pending_gifts_test`, `fishing_test`, `fishing_physics_test`.

## 5. Capturas

Feirante na aba Comprar com a vara; painel com duas varas; minigame com baú (cheio pela metade); resultado com
"Baú!"; `GrowthUi` do Aventureiro. Três resoluções, `build/screenshots/fishing_07/`.

## 6. Pronto quando

Testes PASS, capturas abertas, registro no README do plano, ROADMAP, PROGRESSION.md, CLAUDE.md = AGENTS.md.

## 7. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 07 do plano "Pesca na lagoa da vovó" (vara de molinete + baú).
Leia CLAUDE.md, docs/plans/pesca/README.md (Registros 00–06), 01_DESENHO.md, 02_HISTORIA_E_TUTORIAL.md,
04_BANCA.md e docs/plans/pesca/etapas/ETAPA_07_VARA2.md. Confira ids de itens e ordens livres antes de
escrever dados. Registre fishing_rod2_test em suite e nas áreas certas. Capturas SEM --headless.
Ao terminar: Registro da 07, ROADMAP, PROGRESSION.md, CLAUDE.md = AGENTS.md.
Sem commit/push/publicação. Não executar a 08.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
