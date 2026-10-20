# Etapa 06 — Tela de crescimento

**Estado: concluída em 19/10/2026 (Codex).** Executar somente esta etapa. Pré-requisito: etapa 05 concluída.

## Objetivo

"Toco no selinho ao lado do coração e vejo o Tiro de agora, a sombra do que ele vai ser, o que falta (cada
coisa leva aonde fazer) e, quando está tudo pronto, o botão Crescer! acende." Embaixo, a caderneta com a vida
dele.

## Leitura obrigatória

[06](06_INTERFACE_E_ARTE.md) A, B, C, D, H; [02](02_FASES_E_PILARES.md) A, C, F; `pet_screen.gd` (`BondChip`),
`ui_kit.gd`, `sheet_builder.gd`, `task_help.gd`, `places.gd` (`goal_target`, `run`), `ring_progress.gd`,
`docs/plans/interface/01_REGRAS_E_ESTILO.md`.

## Entrega e implementação

1. `scripts/ui/growth_ui.gd` (`GrowthUi`): `panel()` monta o painel alto (06 B) só com `growth_info()`;
   `open()` pede o Sheet. Nós: `LifeDots`, `CurrentDog`, `NextSilhouette`, `NextUnlocks`, `GrowthReq_<id>`,
   `PillarRing_<id>`, `GrowButton`, `GrowthCard_<fase>`.
2. `silhouette.gdshader` final com revelação por partes (06 D), usando `growth.json → bodies.<corpo>.parts`.
   Nunca mostra cor nem textura da fase futura.
3. Requisitos: ✓ quando cumprido; "Falta 1!"; toque abre `TaskHelp` com o que falta e "Ir"
   (`TaskHelp.describe("growth_req", …)` + destinos em `Places`). Item-chave na Mochila mostra "Dar"
   (`deliver_growth`) — testado com fixture, pois os itens-chave chegam na 10.
4. `GrowButton` (`UiKit.primary`) chama `GameState.grow()`; bloqueado = `UiKit.lock_hint` com o primeiro motivo.
   Feedback provisório até a 08: `Motion.pop_in` no Tiro + aviso "O Tiro cresceu!".
5. Caderneta (06 C): cartões por fase com idade, peso, data, fato (passadas/atual) e silhueta + `teaser` + "Cap. N"
   (futuras). Na passada, a "foto oficial" é provisória (retrato do corpo da fase) até o álbum (13).
6. Tela do Tiro: `GrowthBadge` (anel 44 com o número da fase) ao lado do `BondChip`; pílula "Falta 1!" e pulso
   quando pronto. Toque abre o painel. A aba Crescimento do caderninho ganha o botão "Ver crescimento".
7. Glossário: verbos **Crescer** e **Dar** no `texts_test`.

## Teste da etapa — `growth_ui_test.gd` (novo, ≤ 3 min)

Nós do painel existem; requisito mostra `n/m` e ✓; pronto → `GrowButton` habilitado, senão `lock_hint` com o
motivo; tocar requisito abre o "Como fazer" com "Ir"; "Dar" entrega (fixture com item-chave falso); silhueta
usa o material de silhueta e o estágio de revelação = requisitos cumpridos; cartões futuros não usam textura
sem o shader; `GrowthBadge` mostra "Falta 1!" quando falta um; um `PrimaryButton` só (regra do `ui_style_test`).

Rodar também: `ui_style_test`, `sheet_test`, `texts_test`, `navigation_test`, `tasks_test`, `pet_care_test`,
`manual_test`, `growth_test`.

Toque real: `touch_test.ps1` — tocar no selo, tocar num requisito (abre ajuda), tocar Crescer pronto (DEV).
Capturas `t01_growth_panel`, `t02_growth_almost`, `t03_growth_ready` nas **três resoluções**; abrir PNGs.

## Para passar para a próxima

- [x] Painel responde "o que eu faço agora?" em um toque em qualquer fase (conferir com `dev_set_phase`).
- [x] Nenhuma pista visual da aparência futura além da silhueta.
- [x] Afetados PASS; capturas conferidas.

## Fora desta etapa

Cerimônia (08), HUD (07), itens-chave reais (10), fotos do álbum (13).

## Evidência e passagem de bastão

`build/test_logs/tiro06/`, `build/screenshots/tiro06_*`. README, ROADMAP, `CLAUDE.md`/`AGENTS.md` (linha
"Crescimento do Tiro": `GrowthUi`, nós, shader). Sem push.

Validação e tabela de afetados no registro da etapa 06 do [README](README.md).
