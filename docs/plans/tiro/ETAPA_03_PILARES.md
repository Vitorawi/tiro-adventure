# Etapa 03 — Os quatro pilares do Tiro

**Estado: concluída em 19/10/2026 (Codex).** Executar somente esta etapa. Pré-requisito: etapa 02 concluída.

## Objetivo

Tudo o que você faz pelo Tiro passa a somar em Corpo, Pelagem, Esperteza e Coragem. No caderninho, a aba
"Atributos" (que era do jogador) vira **Crescimento**, com os quatro pilares dele. Um "+2 ⭐" sobe do Tiro
quando ele ganha pontos.

## Leitura obrigatória

[02](02_FASES_E_PILARES.md) B, D; [03](03_COMIDAS_E_ECONOMIA.md) A, B, F (só a linha da aba); [06](06_INTERFACE_E_ARTE.md) A, H;
`game_state.gd` (`feed`, `bathe`, `play`, `pet`, `_care_useful`, `fulfill_wish`, `return_due_walk`, `dig`,
`learn_trick`, `perform_trick`, `give_friend`, `talk_to`, `use_project`, sono), `pet_notebook.gd`,
`progression_ui.gd` (`skills_panel`).

## Entrega e implementação

1. `GameState._gain_pillar(id, pontos, origem)`: aplica Radiante (02 B), teto da fase, reserva; emite
   `Events.pillar_gained`; conta `pillar:<id>` em `progress.stat`.
2. Ligar **todas** as fontes da tabela 02 D (exceto escovar, que é da etapa 12), com as recargas em
   `growth.cooldowns` e os "uma vez só" em `growth.firsts`. Números em `growth.json → sources`, não no script.
3. Campo `growth` (pilares + `phases`) nas comidas existentes (03 B); ×1 adequada / ×0,5 fora; regra especial
   da ração. O ganho acontece dentro do `feed` e do caminho "Ele quer!" (sem duplicar).
4. Prêmio `pillars` aceito por `_apply_rewards` e `_grant_automatic`.
5. Caderninho: feature `growth_tab` (requisito `growth: puppy`, ou seja, depois do primeiro crescimento) no
   lugar da `skills`; aba "Crescimento"
   com nome/idade da fase e quatro `PillarRing_<id>` (`RingProgress` + ícone + "N/teto" + "+N guardado").
   O painel antigo de atributos sai do caderninho (código pode ficar). As "Buscas da Natureza" continuam no
   painel da Natureza.
6. Tela do Tiro: ao receber `pillar_gained`, `Motion.float_text` "+N" com o ícone do pilar acima do Tiro (um
   por vez, agrupando ganhos no mesmo quadro). Subiu de nível: o anel do pilar pulsa se o caderninho estiver aberto.
7. Arte: ícones `pillar_body`, `pillar_coat`, `pillar_smart`, `pillar_brave` (32 px, PixelLab, estilo dos
   ícones de necessidade; prompts no ART_PIPELINE).

## Teste da etapa — `pillars_test.gd` (novo, ≤ 3 min)

Cada fonte da 02 D dá os pontos certos **uma vez** (e respeita recarga/uma-vez-só, inclusive recarregando o
save); Radiante ×1,5 arredondado para cima só com as 4 necessidades ≥ 60; comida fora da fase ×0,5; ração só
nas duas primeiras fases; teto segura o nível e manda o excesso para a reserva; crescer (via `grow`) aplica a
reserva até o novo teto; prêmio `pillars` funciona; aba Crescimento mostra `PillarRing_body` etc. com o texto certo.

Rodar também: `pet_care_test`, `wishes_test`, `walks_test`, `tricks_test`, `friends_test`, `manual_test`,
`lists_test`, `texts_test`, `growth_test`.

## Para passar para a próxima

- [x] Todas as fontes ligadas e testadas; nenhum ganho fora do `_gain_pillar`.
- [x] Aba Crescimento no caderninho (captura 360×780 antes/depois, PNG aberto).
- [x] Afetados PASS (tabela no registro).

## Fora desta etapa

Escovar, comidas novas, painel de crescimento, HUD, fim do nível do jogador.

## Evidência e passagem de bastão

`build/test_logs/tiro03/`, capturas `build/screenshots/tiro03_antes|depois/`. README, ROADMAP, PROGRESSION,
ART_PIPELINE. Sem push.

Validação, ressalva histórica e arquivos/testes no registro da etapa 03 do [README](README.md).


**Encadeamento bloqueado após a conclusão (19/10/2026):** tentativa real de `create_thread` para
**Tiro — Etapa 04**, projeto local ClaudeGame, devolveu `MCP tool call requires approval, but approval
policy is never`. Nenhuma sessão foi criada. Não é pendência de implementação da etapa 03: abrir a
04 manualmente com o bloco "Como passar" e `ETAPA_04_ARTE_CORPOS.md`; ela é portão do Vitor e não
abre a 05 antes da aprovação escrita. Não houve push nem publicação.
