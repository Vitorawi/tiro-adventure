# Etapa 06 — Papinha de peixe e Dentinhos (portão de testes)

> Tamanho: média. Depende de: 05. Próxima: 07.
> Resultado que o Vitor vê: no capítulo 3, depois de comprar o fogão, a Laís pede a **Papinha de peixe**
> (tilápia + batata). Os **Dentinhos** do Tiro passam a pedir 2 papinhas de peixe **além** das 3 cenouras
> geladas. Minhocas às vezes saem da terra ao colher. A vovó pede uma tilápia das grandes.

## 1. Ler antes

- `02_HISTORIA_E_TUTORIAL.md` §1 (capítulo 3) e §2 (pratos).
- `CLAUDE.md`: "Crescimento do Tiro" (`growth.json`, requisitos `feed`, `GrowthUi`, `GrowthReq_<id>`,
  `step_view`), "Refeições e Corpo alinhados" (`body_level` só na refeição que já existe), "Bandeja de estação
  madeira ilustrada" (`food_<item>.png`, `recipe_tile`).
- Código: `game/data/growth.json → phases[teething].requirements` (hoje `pillars`, `meals frozen_carrot 3
  body_level 2`, `key chew_ring`); `game/data/recipes.json` (molde `puppy_mash`: `station stove`, `inputs`,
  `output`, `qty`, `seconds`, `player_xp 0`, `requirements {quests [first_kitchen]}`); `game/data/items.json`
  (molde `puppy_mash`: `category food`, `storage fridge`, `feed`, `growth.phases`, `sell_price`);
  `GameState.harvest(index)` (l. ~1579: semente fixa por plantio, bônus do Tiro animado).

## 2. Passo a passo

1. **Item `fish_mash`** "Papinha de peixe": `category food`, `storage fridge`, `feed {hunger 40, happiness 10}`,
   `growth {phases [puppy, teething]}`, `sell_price 18`, `trade_xp 6`, ícone `item_fish_mash.png` (pixel art
   PixelLab, já gerado na 03 e registrado em `tools/art/pesca/manifest.json`). **Arte só PixelLab** (decisão do
   Vitor): sem `food_fish_mash.png` ilustrado; a bandeja do fogão mostra o ícone pixel no tamanho original. O
   mesmo vale para `fish_stew`, `herb_fish` e `lambari_crunch` nas etapas 07–09.
2. **Receita `fish_mash`**: `station stove`, `inputs {fish_tilapia 1, potato 1}`, `output fish_mash`, `qty 1`,
   `seconds 180`, `player_xp 0`, `requirements {quests [first_kitchen], rod: "bamboo_rod"}`.
   Batata: a planta `potato` libera com `bloblo_more_crops` (capítulo 2, `crops.json`), então já existe quando o
   fogão chega no capítulo 3.
3. **Requisito novo nos Dentinhos** (`growth.json → teething.requirements`, depois de `meals`):
   `{"id": "fish_meal", "type": "feed", "item": "fish_mash", "qty": 2, "label": "Papinha de peixe"}` — **sem**
   `body_level` (o Corpo segue vindo da cenoura gelada; decisão do Vitor: **soma**). Fato real em
   `teething.facts`: "Peixe cozido, sem espinha e sem sal, é uma proteína leve para filhotes."
4. **Missões do capítulo 3**: `lais_fish_mash` (`kind main`, `chapter 3`, `order 22` — entre `first_kitchen`
   o20 e `lais_blender` o25 —, goals `{type stat, key "produce:fish_mash", target 1, fresh true,
   label "Fazer a papinha de peixe"}` (contador real que `GameState.collect` soma ao recolher do fogão,
   `game_state.gd` l. ~1232) e `{type stat, key "feed:fish_mash", target 1, fresh true, label "Dar ao Tiro"}`, rewards coins 15, `go {world house, place stove}`) e `bloblo_big_tilapia`
   (`line bloblo`, `order 64`, `requirements {quests [lais_fish_mash]}`, goal `{type stat, key
   "fish_size:large:fish_tilapia", target 1, label "Pegar uma tilápia Grande"}`, rewards coins 20 + bolt 1).
5. **Minhoca ao colher**: em `GameState.harvest`, depois do bônus do Tiro animado, com a MESMA `rng` da colheita:
   se o jogador tem a vara de bambu e `rng.randf() < fishing.harvest_worm_chance` (0,15 em `fishing.json`), soma
   `bait_worm 1` ao recebido (só se `storage_error` aceitar — a minhoca é `storage none`, então sempre cabe) e
   aviso "Achou uma minhoca!". Sem reabrir o sorteio ao recarregar (semente do plantio).
6. **Comida e ajuda**: `GrowthUi.step_view` do `fish_meal` mostra o ícone da papinha, "0/2" e Ir → fogão (receita
   escolhida); `TaskHelp.describe("item", "fish_mash")` mostra a cadeia: tilápia (lagoa) + batata → fogão. O
   `FoodMenu` da tela do Tiro mostra a papinha com "Ele quer!" quando ela é o que falta.
7. **Desejos**: `wishes.json` — se houver desejo de comida por fase, incluir `fish_mash` na fase Dentinhos
   (consultar como `meal` resolve a refeição da fase; não criar desejo novo).

## 3. Não fazer

Mudar `body_level`, a cenoura gelada, ou o passo `growth_3_teething`. Vara 2.

## 4. Testes

Novo **`game/tests/fishing_story_test.gd`** (área `fishing` + `growth` + `story`):
1. Receita bloqueada sem fogão/sem vara; liberada depois de `first_kitchen` com a vara.
2. Cozinhar consome 1 tilápia + 1 batata (ou cenoura) e entrega 1 papinha; dar ao Tiro conta `feed:fish_mash`.
3. Dentinhos: com tudo pronto **menos** o `fish_meal`, `grow` não deixa; 2 papinhas → deixa.
4. O Corpo (`body_level`) não muda por causa da papinha.
5. `lais_fish_mash` aparece depois de `first_kitchen`, conclui com o contador certo, `go` leva ao fogão.
6. `bloblo_big_tilapia` conclui com Grande e também com Gigante.
7. Minhoca na colheita: com semente fixa, 100 colheitas dão ≈ 15 minhocas (±6); sem vara, nenhuma.
8. `GrowthUi`: `GrowthReq_fish_meal` existe, "0/2", Ir abre a bandeja do fogão com a receita.
Afetados: `growth_meals_test`, `growth_ui_test`, `growth_story_test`, `garden_test`, `journey_test`,
`foods_test` (se existir), `care_story_test`, `content_test`.

**Portão desta etapa:** `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level portao` (≤ 8 min,
paralelo). Falhas históricas já listadas no ROADMAP não contam; qualquer falha nova precisa de correção ou de
explicação no registro.

## 5. Capturas

`GrowthUi` dos Dentinhos com o passo novo (pendente e feito), bandeja do fogão com a papinha, cartão "Achou uma
minhoca!", nas três resoluções (`build/screenshots/fishing_06/`).

## 6. Pronto quando

Testes e portão PASS, capturas abertas, registro no README do plano, ROADMAP, `docs/PROGRESSION.md` (seção
"Pesca — etapa 06").

## 7. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 06 do plano "Pesca na lagoa da vovó" (papinha + Dentinhos + portão).
Leia CLAUDE.md, docs/plans/pesca/README.md (Registros 00–05), 02_HISTORIA_E_TUTORIAL.md e
docs/plans/pesca/etapas/ETAPA_06_PAPINHA.md. A papinha SOMA à cenoura gelada (decisão do Vitor).
Confira os contadores reais antes de escrever objetivos. Rode o portão (-Level portao).
Ao terminar: Registro da 06, ROADMAP, PROGRESSION.md, CLAUDE.md = AGENTS.md.
Sem commit/push/publicação. Não executar a 07.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
