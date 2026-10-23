# Etapa 05 — Tiro animado: cuidar ajuda o resto do jogo

**Estado: concluída (23/10/2026, Codex).** Pré-requisito 04 conferido no README, ROADMAP e VALIDACAO_04. Evidências em [VALIDACAO_05](VALIDACAO_05.md).

## Objetivo

Dar utilidade às necessidades: quando nada está pedindo, o Tiro fica **animado** e ajuda na horta, no passeio e
no faro. Ninguém é castigado.

## Leitura

[02 C](02_DESENHO.md), em `game_state.gd`: `harvest`, `start_walk`/`_walk_snapshot`/`walk_loot`, `update_finds`;
`scripts/ui/collect_fx.gd`, `scripts/ui/hud.gd`.

## Entrega

1. `GameState.tiro_animated()` (acordado e nenhuma necessidade pedindo) e `config.json → mood.animated`
   (`harvest_chance` 0,2, `walk_extra_rolls` 1, `dig_extra_per_period` 1).
2. Horta: colheita com chance de +1 (semente do sorteio existente, determinística), só se couber; aviso "O Tiro
   ajudou!" e `CollectFx`.
3. Passeio: `animated` congelado no snapshot na saída; volta com +1 sorteio de achado.
4. Faro: +1 montinho por período quando animado.
5. HUD: selo "Animado" no avatar; tocar mostra em uma linha o que ele está ajudando. Tela do Tiro: brilho
   discreto (respeita "Menos animação").
6. Simulador: nada (a 07 trata).

## Teste da etapa

`mood_test`: animado só sem necessidade pedindo e acordado; colheita animada dá +1 com a semente certa e não
passa do depósito; passeio iniciado animado traz um sorteio a mais mesmo se ele deixar de estar animado depois;
montinho extra só uma vez por período; nada muda quando não animado.

`-Level etapa -Tests mood_test -Areas farm,walks,finds,shell`.

## Para passar para a próxima

- [x] Nível etapa verde.
- [x] README e ROADMAP.
