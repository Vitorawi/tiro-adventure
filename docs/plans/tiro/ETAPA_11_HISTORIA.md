# Etapa 11 — A história conduzida pelo Tiro (PORTÃO)

**Estado: concluída (19/10/2026), ver [VALIDACAO_11](VALIDACAO_11.md).** Executar somente esta etapa. Pré-requisito: etapa 10 concluída.

## Objetivo

"A Laís, a vovó e a Nina falam do Tiro o tempo todo. Cada parte da história termina com ele crescendo, e só
então a próxima começa." Truques e passeios longos chegam quando ele tem idade para isso.

## Leitura obrigatória

[04](04_HISTORIA.md) inteiro; `quests.json`, `progression.json` (`chapters`, `final_chapter`, `tricks`,
`features`), `walks.json`; `progression_state.gd` (`active_steps`, capítulos), `game_state.gd`
(`_sync_shared_quests`, objetivos), `places.gd` (`goal_target`), `task_help.gd`, `tasks_screen.gd`;
`tests/helpers/economy_bot.gd` e `economy_sim.gd`; `progression_test.gd`.

## Entrega e implementação

1. Objetivo `growth` (cumprido com fase ≥ alvo; "Ir" abre o painel; `TaskHelp`), card da História com a
   miniatura da silhueta.
2. As 9 missões principais novas e os pares `shared_with` da 04 C, com ordem, falas e objetivos exatos.
3. Reescrever as falas listadas na 04 C/F (missões antigas: só `dialogue`/textos; IDs, objetivos e prêmios iguais,
   exceto `community_12_memory` já mudado na 10). `final_chapter` com fala nova.
4. Requisitos `growth` da 04 D em truques, passeios, feature `wishes` e `topknot_bow` (o `treat_box` já foi na 07).
5. **Robô do simulador** (`economy_bot.gd`/`economy_sim.gd`) aprende a crescer: perseguir requisitos de
   crescimento (dar a refeição da fase, banho com xampu, entregar item-chave, apertar crescer) com as mesmas
   ações do `GameState`. Sem isso a campanha simulada trava no fim do capítulo 1.
6. `progression_test` (campanha do zero ao fim) passa pelos 5 crescimentos.

## Teste da etapa — `growth_story_test.gd` (novo, ≤ 3 min)

Save novo: capítulo 2 só abre depois de `growth_1_puppy`; cada `growth_*` é reconhecida quando a fase chega
(inclusive se ele já cresceu antes de a missão ficar ativa); pares `shared_with` entregam/premiam uma vez;
saves de exemplo nos capítulos 2, 5, 8 e 11 entram na fase certa com a próxima missão certa; truques e
passeios longos travam com "Quando ele for …"; falas novas sem palavras proibidas.

Rodar também: `journey_test`, `tasks_test`, `content_test`, `npc_lines_test`*, `tricks_test`, `walks_test`,
`wishes_test`, `festival_test`, `economy_sim_test`.

## PORTÃO — passagem total

`tools/test_all.ps1` inteiro, **com** `progression_test`. Capturas da aba Missões (passo de crescimento) nas
três resoluções. Não rodar simulações de perfis/sementes (o `economy_sim_test` basta).

## Para passar para a próxima

- [x] História jogável do zero ao fim com os 5 crescimentos (`progression_test` PASS).
- [x] Saves de exemplo de cada arco continuam sem travar.
- [x] Suíte inteira sem falha nova.

## Fora desta etapa

Calibrar ritmo (17), álbum, escovar, casa.

## Evidência e passagem de bastão

`build/test_logs/tiro11/` (suíte com tempos). README, ROADMAP, PROGRESSION (capítulos), GAME_DESIGN (história),
`docs/plans/economia/SIMULADOR.md` (o robô cresce), `CLAUDE.md`/`AGENTS.md` (linha "História principal" e objetivo
`growth`). Sem push.
