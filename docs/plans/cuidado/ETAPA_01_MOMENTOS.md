# Etapa 01 — Motor dos momentos

**Estado: concluída (23/10/2026).** Pré-requisito: 00 concluída.

Pré-requisito liberado em 23/10/2026: etapa 00 concluída após reexecução focada de `progression_test`, autorizada pelo Vitor, PASS (767 ciclos, 64 aquisições, 110 missões; log `build/test_logs/cuidado00/progression_final.log`). Portão e Quick não repetidos. Esta etapa continua não iniciada.

## Objetivo

Os pilares Coragem, Esperteza e Pelagem passam a contar **momentos** (cuidado útil, novidade, passeio) em vez
de pontos; cuidar com ele satisfeito não rende nada além da animação. É a etapa que mais **remove** código.

## Leitura

[02 A, B e H](02_DESENHO.md), `data/growth.json`, `scripts/state/growth_state.gd`, em `game_state.gd`:
`_gain_pillar`, `_pillar_source`, `_care_useful`, `_care_reward`, `_need_is_low`, `pet`, `play`, `bathe`, `brush`,
`set_sleeping`/`_finish_pillar_nap`, `growth_info`, `pet_growth_info`; `scripts/ui/pillar_ui.gd`, `scripts/ui/growth_ui.gd`.

## Entrega

1. `growth.json`: sai `levels`, `radiant`, `food_multiplier` (se só servia a pontos), `sources.*.cooldown`, `nap`;
   entra `moments` (`periods`, `period_cap` 2, `sources` da tabela do 02 B). Requisitos `pillars` das fases viram
   `moments` com as quantidades do 02 B; sai o requisito "2 banhos com xampu".
2. `config.json → needs.*.ask_below` (50) e os valores iniciais do 02 A; saem as chaves `care_*` de
   `progression.json → settings`.
3. `GrowthState`: `moments`, `phase_moments`, `period_moments` (guardar só o período atual e o anterior); saem
   `points`, `reserve` e os cooldowns de pilar. `growth_info()` devolve os requisitos `moments` com `have/need`.
4. `GameState`: um caminho só — `_gain_moment(pillar, source, capped)` — chamado pelas fontes do 02 B; emite
   `Events.moment_gained`. `_care_useful` vira "a necessidade estava pedindo antes da ação". Remover
   `pet_growth_info` (ou reduzir ao estado "pedindo/não pedindo"), Radiante e as recargas.
5. Fontes de primeira vez (conversa, mundo, amigo, obra, truque aprendido, achado novo) passam a chamar
   `_gain_moment` com `capped = false`, uma vez (`growth.firsts`).
6. `SAVE_VERSION` 14; ramo de reset `< 14`. Atualizar a linha "Migração de economia" do `CLAUDE.md`/`AGENTS.md`:
   "saves sempre zerados; subir `SAVE_VERSION` quando o formato mudar".
7. Interface **mínima** para não quebrar: onde `PillarUi`/`GrowthUi`/HUD mostravam pontos, mostrar `have/need` de
   momentos (o visual bonito é da 03). Textos de ajuda que falam em "a cada 2 min" saem.
8. DEV: `dev_add_moment`, `dev_set_need`, `dev_next_period`.

## Teste da etapa

`moments_test` (novo, relógio injetável): carinho pedindo = +1 Coragem; carinho satisfeito = 0; terceiro
carinho útil no mesmo período = 0 (teto 2); troca de período libera de novo; primeira conversa = +1 fora do teto
e só uma vez; xampu útil = 2; escovar 2× no dia = 1; requisito `moments` completo libera crescer; ao crescer
`phase_moments` zera e `moments` mantém.

`tools\test.ps1 -Level etapa -Tests moments_test -Areas growth,pet,needs,saves`. `pillars_test` é **reescrito**
dentro do `moments_test` (apagar o antigo). Outros que quebrarem por causa da regra nova: atualizar.

## Para passar para a próxima

- [x] Nenhuma referência a `points`/`reserve`/`radiant`/`care_affection_cooldown` no código e nos dados.
- [x] `moments_test` e o nível etapa verdes.
- [x] Filhotinho ainda alcançável numa sessão (conferir no próprio teste).
- [x] README (registro) e ROADMAP.

## Fora desta etapa

Desejos (02), visual novo (03), gestos (04), robô do simulador (07).
