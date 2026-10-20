# Etapa 07 — HUD do crescimento e fim do nível do jogador

**Estado: concluída em 19/10/2026 (Codex).** Executar somente esta etapa. Pré-requisito: etapa 06 concluída.

## Objetivo

"No alto da tela está o rostinho do Tiro na idade dele, com um anel que enche conforme ele se aproxima de
crescer." O número de nível do jogador, o XP e os atributos do jogador somem do jogo.

## Leitura obrigatória

[03](03_COMIDAS_E_ECONOMIA.md) F, G; [06](06_INTERFACE_E_ARTE.md) A; `hud.gd` (`LevelLabel`, `XpRing`, `XpBar`,
`show_level_popover`), `main.gd`, `celebration.gd` (`show_level`), `game_state.gd` (`_add_player_xp`,
`level_reward`, `_award_skill`, `_apply_rewards`), `progression_ui.gd` (`reward_chips`), `market_ui.gd`,
`project_ui.gd`, `tasks_screen.gd`, `welcome_back.gd`, `routines.json`, `recipes.json` (`treat_box`),
`progression.json` (`features.skills`, `level_rewards`).

## Entrega e implementação

1. **HUD:** avatar = retrato da fase (com `coat`); `XpRing` (nome mantido, por compatibilidade dos testes)
   mostra a fração de requisitos cumpridos da fase; `LevelLabel` mostra o número da fase (1–5; Recém = "•").
   Toque no avatar: `Popover` com nome da fase, "faltam N" e "Ver" (abre o painel de crescimento). Pronto para
   crescer: o avatar pulsa.
2. **Fim do nível:** `_add_player_xp` continua somando `xp` (compatibilidade), mas `level` **congela**: não sobe,
   não emite `Events.level_up`, não paga `level_rewards`, não chama `Celebration.show_level`.
3. `reward_chips` e demais listas não mostram `xp`, `player_xp` nem `skill_xp`. Procurar textos "Nível",
   "XP" e "Atributos" visíveis (`tools/list_texts.ps1`) e trocar/remover.
4. Atributos do jogador: feature `skills` removida; `_award_skill` vira sem efeito visível; `treat_box` passa a
   exigir `growth: explorer`.
5. Rotinas e obras: onde havia prêmio `xp`/`player_xp` de cuidado, trocar por `pillars` (rotinas de cuidado →
   Coragem 4; banho → Pelagem 4; obras → Coragem 5). Os demais ficam sem efeito visível. Listar no registro.
6. Como os saves foram zerados (02), `level`/`xp`/`skills` podem sair do save e do código; tirar só se o
   simulador e os testes continuarem simples de ajustar, senão apenas esconder (registrar a escolha).
7. Atualizar textos do manual/boas-vindas que falem de nível.

## Teste da etapa — `hud_growth_test.gd` (novo, ≤ 3 min)

HUD mostra o retrato da fase e o número; anel = fração dos requisitos; popover abre o painel; ganhar XP não
muda `level` nem emite `level_up`; nenhum chip de XP/atributo em missões, receitas, encomendas, obras e rotinas
(varrer os construtores); `treat_box` pede Aventureiro; rotina de cuidado paga pilar; save novo nunca mostra nível.

Rodar também (ajustando o que esperava nível/XP, com explicação): `hud_test`, `festa_test`, `coins_test`
(presente de nível sai), `lists_test`, `tasks_test`, `texts_test`, `welcome_test`, `products_test`,
`economy_transactions_test`, `growth_ui_test`.

Capturas 360×780: `t05_hud_growth` e uma missão com prêmios (antes/depois).

## Para passar para a próxima

- [x] Nenhum "Nível N"/"XP" do jogador visível em lugar nenhum (lista de textos conferida).
- [x] HUD mostra o crescimento; afetados PASS com ajustes explicados.
- [x] DECISOES registra a lista de prêmios de XP trocados por pilar e o efeito nas moedas (03 G).

## Fora desta etapa

Cerimônia (08), novos prêmios de moeda além dos presentes de fase já pagos pela 02.

## Evidência e passagem de bastão

`build/test_logs/tiro07/`. README, ROADMAP, PROGRESSION, GAME_DESIGN (nível do jogador sai), `CLAUDE.md`/`AGENTS.md`
(linhas do HUD e "Regar, presente de nível..."). Sem push.
