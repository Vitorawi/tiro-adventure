# Etapa 08 — Vara do pescador (Guia da trilha), peixes grandes e pelo brilhante

> Tamanho: grande. Depende de: 07. Próxima: 09.
> Resultado que o Vitor vê: o Guia da trilha conta que pescava na lagoa e ensina a fazer a **vara do pescador**
> na bancada. Com ela e a **isca artificial**, a lagoa dá **traíra, tucunaré e pintado** (o gigante do fundo). O
> **Peixe com ervas** dá brilho ao pelo e o Mocinho precisa de 2.

## 1. Ler antes

- `01_DESENHO.md` §7–§8; `02_HISTORIA §1` (capítulo 8–9) e §2. Decisão do Vitor: a vara 3 vem do **Guia**.
- `CLAUDE.md`: "Pet shop / costura / receita que entrega roupa" (`recipes.json → output_collection` — molde para
  a receita que entrega a vara), "Crescimento", "Momentos" (`growth.json.moments.sources`).
- Código: linha `guide` em `quests.json` (`guide_meet 10`, `guide_wood 20`, `guide_open_cave 22`,
  `guide_stone 30`, `guide_fibers 40`, `guide_treasure 50`); receitas da bancada (`plank`, `soft_brush`…);
  `GameState.cook/collect` (onde trata `output_collection`); `growth.json → young`
  (`meals milk_porridge 3 body_level 6`, `key soft_brush`).

## 2. Passo a passo

1. **Receita que entrega vara**: `recipes.json → angler_rod` na bancada (`workbench`): `inputs {hardwood 3,
   fiber 4, copper 2}`, `output_rod "angler_rod"` (sem `output`/`qty`), `seconds 900`, `requirements {quests
   [guide_angler]}`. Em `cook_error/cook/collect`, tratar `output_rod` como `output_collection` é tratado
   (sem item no inventário; ao recolher chama `give_rod`; só 1 por vez; "Você já tem" se já possui).
   `Database.recipe_output` devolve o id da vara para ícone/nome (`fishing.json → rods.angler_rod`).
2. **Missões do Guia**: `guide_angler` (`line guide`, `order 60`, `requirements {quests [guide_treasure], rod:
   reel_rod}`, goal `talk:guide` fresh; fala "Antes de guiar trilhas eu pescava naquela lagoa…"; prêmio: só
   libera a receita), `guide_angler_rod` (o62, goal `rod:angler_rod`, `go` → bancada com a receita, prêmio
   `bait_lure 4`), `guide_pintado` (o64, goal `fish:fish_pintado`, coins 40).
   Conferir que o Guia aparece antes do capítulo 8: `guide_treasure` pode ser concluído antes; se o pintado
   chegar tarde demais para o Mocinho (cap. 9), baixar o requisito para `guide_fibers` e registrar.
3. **Isca artificial**: `lure` (Feirante, da 04) visível com a vara 3; receita da bancada `bait_lure`
   (`copper 1, stick 1` → 1, 120 s, `requirements {rod angler_rod}`); `keep_chance 0,7` no motor (01).
4. **Peixes da vara 3**: conferir sorteio, perfis (`darter` traíra/tucunaré, `sinker` pintado) e que a barra da
   vara 3 (`bar_bonus 0,05`, `hold 0,30`, **rebote 0**) deixa o pintado possível para jogador médio (jogar 10
   partidas no Godot e anotar taxa de acerto no registro; meta 50–70%).
5. **Peixe com ervas**: item `herb_fish` (`food`, `fridge`, `feed {hunger 35, hygiene 10}`, `growth {phases
   [young, adult]}`, venda 60); receitas `herb_fish_pintado` e `herb_fish_tucunare` (`<peixe> 1, herbs 2`,
   saída 2, 720 s, `requirements {rod angler_rod}`); ao dar ao Tiro, **1 momento de Pelagem**: fonte nova
   `growth.json → moments.sources.herb_fish {label "Peixe com ervas", pillar coat, qty 1, capped true,
   first false, go "recipe:herb_fish_pintado"}` chamada em `feed` quando o item for `herb_fish`.
   Fato em `young.facts`: "Peixe tem ômega-3, que deixa o pelo mais brilhante."
6. **Mocinho** (`growth.json → young.requirements`): `{"id": "fish_meal", "type": "feed", "item":
   "herb_fish", "qty": 2, "label": "Peixe com ervas"}`.
7. **Missão principal** `lais_shiny_coat` (`chapter 9`, `order 15` — antes de `main_8_building` o20? confira a
   ordem livre no capítulo 9: hoje `main_8_fiber 10`, `main_8_building 20`, `atelier_open 30`, `young_9_milk
   35`, `growth_9_young 40`), goals `produce:herb_fish` + `feed:herb_fish`, coins 30.
8. **Ervas**: `herbs` exige estufa (`main_7_greenhouse`, capítulo 8). Confirmar que a estufa vem antes do
   capítulo 9 na campanha.

## 3. Não fazer

Caderno/Coleção de peixes (09). Chapéu de pescador (só se houver arte aprovada; senão fica para depois).

## 4. Testes

Novo **`game/tests/fishing_rod3_test.gd`** (área `fishing` + `growth` + `story`):
1. `guide_angler` só depois do tesouro + vara 2; libera a receita.
2. Receita entrega a vara ao recolher (sem item), uma vez; "Você já tem" depois.
3. Isca artificial sorteia só traíra/tucunaré/pintado; 70% das pescas não gastam (semente fixa: conferir com
   100 pescas ≈ 30 gastas ±10).
4. Rebote 0 com a vara 3.
5. Peixe com ervas dá 1 momento de Pelagem (com teto); Mocinho exige 2.
6. Missões concluem; `guide_pintado` com o pintado.
Afetados: `growth_meals_test`, `growth_story_test`, `silk_test`, `journey_test`, `fishing_rod2_test`.

## 5. Capturas

Bancada com a vara; painel com três varas e três iscas; minigame com o pintado; resultado Gigante do pintado;
`GrowthUi` do Mocinho. Três resoluções, `build/screenshots/fishing_08/`.

## 6. Pronto quando

Testes PASS, taxa de acerto anotada, capturas abertas, registros (README, ROADMAP, PROGRESSION.md,
CLAUDE.md = AGENTS.md).

## 7. Prompt pronto

```
Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Execute SOMENTE a ETAPA 08 do plano "Pesca na lagoa da vovó" (vara do pescador, pelo brilhante).
Leia CLAUDE.md, docs/plans/pesca/README.md (Registros 00–07), 01_DESENHO.md, 02_HISTORIA_E_TUTORIAL.md e
docs/plans/pesca/etapas/ETAPA_08_VARA3.md. A vara 3 vem do Guia da trilha (decisão do Vitor).
Confira ordens livres e quando a estufa/ervas abrem. Registre fishing_rod3_test. Capturas SEM --headless.
Ao terminar: Registro da 08, ROADMAP, PROGRESSION.md, CLAUDE.md = AGENTS.md.
Sem commit/push/publicação. Não executar a 09.
Ao terminar, siga a seção "Sessões encadeadas" do docs/plans/pesca/README.md (abre a próxima
etapa numa sessão NOVA de Sonnet 5.5, modelo claude-sonnet-5-5).
```
