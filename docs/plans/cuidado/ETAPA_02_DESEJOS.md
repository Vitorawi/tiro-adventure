# Etapa 02 — Desejos com propósito e fim do vínculo

**Estado: concluída (23/10/2026).** Pré-requisito: 01 concluída.

## Objetivo

Um desejo por período, escolhido pelo que **falta para crescer** e pelo que ele está precisando; atender dá um
momento garantido. O vínculo (afeto/corações) sai: o crescimento é a única barra do Tiro.

## Leitura

[02 D e E](02_DESENHO.md), `data/wishes.json`, `scripts/state/wish_state.gd`, em `game_state.gd`: `update_wishes`,
`_pick_wish`, `fulfill_wish`, `swap_wish*`, `requirement_error` (ramo `bond`), `_apply_rewards` (`affection`);
`progression_state.gd` (`bond_level`), `album_rules.gd`, `trick_ui.gd`, `walks.json`, `progression.json → tricks/bond_levels`.

## Entrega

1. `wishes.json` reescrito pelo catálogo do 02 D (`pillar`, `phases`, `goal`, `go`, `requirements`); saem
   `slots`, `refill_*`, `swap_seconds`, `special_*`, `need_wishes`.
2. `WishState`: `current`, `last_ids`; `GameState.update_wishes()` cria o desejo do período (chamado no tick e
   ao carregar), `_pick_wish` com a ordem do 02 D, `fulfill_wish()` (sem índice) dá o momento fora do teto.
   Saem `swap_wish*`.
3. Vínculo removido: `DogState.affection`, `bond_levels`, `bond_level`, requisito `bond` (avaliador e dados),
   prêmios `affection`, `Events.bond_up` e o cartão de vínculo da `Celebration`. Trocas de requisito pela tabela
   do 02 E. Condições de foto que usavam vínculo/afeto: trocar por fase ou apagar a foto se não fizer sentido
   (registrar em DECISOES).
4. A aba Desejos continua funcionando nesta etapa, mostrando o único desejo (a 03 tira a aba).

## Teste da etapa

`wish_moments_test` (novo, relógio injetável): primeiro desejo depois da caminha é carinho; um desejo por
período e nenhum na madrugada; necessidade pedindo escolhe o desejo dela; sem necessidade, escolhe o pilar com
mais falta; não repete os dois últimos; atender dá +1 momento mesmo com o teto do período cheio; desejo de
comida da fase conta como refeição; desejo não atendido é trocado no período seguinte; truque e passeio longo
abrem pela fase.

`-Level etapa -Tests wish_moments_test -Areas wishes,tricks,walks,album,story`. `wishes_test` e `bond_test`
são **apagados** (cobertos pelo novo).

## Para passar para a próxima

- [x] Nenhuma referência a `affection`/`bond` no código, dados e textos (exceto este plano).
- [x] Nível etapa verde.
- [x] README e ROADMAP.
