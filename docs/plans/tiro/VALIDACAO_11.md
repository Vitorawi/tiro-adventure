# Etapa 11 — validação (19/10/2026, Claude Code) — PORTÃO

Etapa 10 confirmada em VALIDACAO_10.md. Sem commit, push, publicação ou reset.

## O jogador encontra

Nove missões principais novas (49 principais, 109 no total): o capítulo 1 termina com "Ele está crescendo!" (Filhotinho), o 3 com "Dentinhos coçando" (a história orienta a argolinha da vovó) e "As orelhinhas subiram!", o 6 com "Comida de quem cresce" (ovos da vovó) e "Um pequeno aventureiro", o 8 com "Banho de ervas", o 9 com "Mingau de mocinho" (farinha da vovó) e "Pelo de mocinho", o 12 com "Azul e dourado". O cartão da História mostra a silhueta da fase que vem (vira o retrato quando ele cresce); Ir abre o Crescimento e o "?" lista o que falta, cada item tocável. Falas reescritas com o Tiro como motivo (Smoky na festa). Truques (Dentinhos/Aventureiro/Mocinho) e passeios longos (Aventureiro) travam com "Quando ele for …".

## Arquivo mudado → teste → resultado

| Área | Teste | Resultado |
|---|---|---|
| quests/progression/walks.json, objetivo e requisito `growth` | `growth_story_test` (novo, 8 s) | PASS |
| mesmas áreas | `content_test`, `journey_test`, `tasks_test`, `tricks_test`, `walks_test`, `wishes_test`, `festival_test`, `texts_test`, `navigation_test`, `growth_*`, `manual_test`, `dev_tools_test` | PASS (ajustes de fixture em DECISOES) |
| `economy_bot.gd`/`economy_sim.gd` | `economy_sim_test` (parte 9 nova: Dentinhos, Mocinho, Azul e Dourado e 2 dias do zero) | PASS, sem violações |
| campanha | `progression_test` (obras da vila e cinco crescimentos) | **PASS**, 767 ciclos, 109/109 missões, 15 min (antes falhava em `community_10_*`–`12_*`) |
| suíte inteira `tools/test_all.ps1 -KeepGoing` | 78 testes, 32,2 min | 70 PASS; 8 falhas: seis **históricas** (`npc_lines_test`, `onboarding_test`, `finds_test`, `park_test`, `petshop_test`, `ui_style_test`, reproduzidas, não investigadas) + `garden_test` (regressão da etapa 10: argolinha entre ensopado e escritura) e `pillars_test` (fixture com `dev_unlock_everything`, que agora faz o Tiro crescer) — **ambos corrigidos e reexecutados: PASS** |

`onboarding_test` histórico tem agora 1 falha (ocioso total 540 s > 240 s; baseline: 730 s e raro fora do prazo). `npc_lines_test`: as mesmas 4 mensagens da linha de base. Logs: `build/test_logs/tiro11/` (`suite.log`, `suite.csv` com tempos, um log por teste).

## Capturas e toque

`tests/story_shots.gd` em `build/screenshots/tiro11_360x780|390x844|412x915` (9 PNGs cada; abertos os de 360 e amostras de 390/412): cap. 1 pendente (silhueta + Ir), Ir abrindo o Crescimento (clique real emulado no Godot, confere `GrowthPanel`), pronto com retrato e Pegar prêmio, cap. 3 orientando a vovó, "Como fazer" dos Dentinhos com chips tocáveis, caps. 6/9/12. Sem gesto novo: `touch_test.ps1` não exigido; sem aparelho físico.

## Limites

Ritmo de crescimento (dias por fase) não calibrado (etapa 17); diagnóstico solto do robô: 14 dias → Aventureiro/cap. 9; 40 dias → Mocinho/cap. 12. `progression_test`/`onboarding_test` completam pontos dos pilares com `dev_add_pillar`. Nenhum PNG do Tiro, canvas ou save alterado.
