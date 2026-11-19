# E00. Preparação (18/11/2026)

**Entrega:** regras fechadas em um lugar só e ferramentas para testar a semana.

## Arquivos
- `docs/plans/primeira_semana/REGRAS.md` (novo): decisões D1–D18, 12 ajustes, divergências resolvidas, documento de alimentação que vale.
- `docs/plans/primeira_semana/PROVISORIOS.md` (novo): lista viva dos assets provisórios.
- `game/scripts/state/week_state.gd` (novo): `WeekState` (`started_day`, `clock_offset`), chave `week` do save.
- `game/autoload/game_state.gd`: `week`, `week_now/week_day_number/week_day/week_hour/week_minute`, `dev_week_goto/dev_week_hour/dev_week_shift_hours/dev_week_reset_clock/dev_week_meal/dev_week_kit`.
- `game/scripts/ui/dev_panel.gd`: aba DEV **Semana**.
- `game/tests/week_clock_test.gd` (+ `week_clock_test_prod`) e `game/tests/week_dev_shots.gd` (capturas).
- `tools/test_areas.json` (área `week`, suíte e área `dev`), `tools/test.ps1` e `tools/test_worker.ps1` (alias `_prod`).

## Passo a passo
1. Ler o plano, a revisão (Parte A) e os dois documentos de alimentação; perguntar as decisões ao Vitor (feito: todas aprovadas).
2. Registrar decisões e resolver as divergências (`REGRAS.md`).
3. `WeekState` + relógio da semana no `GameState` (dia 1 = dia em que o save começou; `week_day()` nunca volta abaixo de 1).
4. Aba DEV Semana: ir ao dia 1–7 ou 9, mudar a hora (08h…23h, ±1 h), voltar ao real, pular o passo da história; refeição e kit são ganchos que avisam a etapa certa (E01 e E06 os preenchem).
5. Testes e capturas nas três resoluções.

## Não fazer
- Arte nova, regra de refeição, subir `SAVE_VERSION` (a chave `week` é opcional no save; a E01 sobe a versão ao criar o estado do dia).
- Editar os documentos externos do claude.ai.

## Testes
`week_clock_test` e `week_clock_test_prod` (novos), `dev_tools_test`/`_prod`, área `saves` (muda o save), `content_test`, `texts_test`, `scripts_check`.

## Pronto quando
Nenhuma regra em conflito (`REGRAS.md`) e o DEV leva a qualquer dia/hora da semana (teste + capturas).
