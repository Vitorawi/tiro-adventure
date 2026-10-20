# Etapa 08 — Crescer de verdade: a cerimônia (PORTÃO)

**Estado: concluída em 19/10/2026, com ressalvas históricas do portão registradas em VALIDACAO_08.** Executar somente esta etapa. Pré-requisito: etapa 07 concluída.

## Objetivo

"Aperto Crescer!, a tela escurece, a silhueta pisca entre o Tiro de antes e o de depois, explode em luz e
aparece ele novo, ao lado de como era, com idade, peso e um risquinho novo na régua." É o momento mais
importante do jogo.

## Leitura obrigatória

[06](06_INTERFACE_E_ARTE.md) F; `modal_card.gd`, `celebration.gd`, `main.gd` (`_queue_modal`), `motion.gd`,
`haptics.gd`, `welcome_back.gd` + `GameState.welcome_ready_lines`, `progression.json → features` (Novo!).

## Entrega e implementação

1. `scenes/ui/growth_ceremony/` (`GrowthCeremony`), entrando pela fila modal ao receber `Events.grew`, com os
   6 tempos da 06 F. Constantes de tempo no topo do script; alternância da silhueta ≤ 3 por segundo.
2. Cartão antes/depois em `ModalCard` (nós `BeforeAfter`, `HeightMark`): pose antiga × nova, fase, idade, peso,
   fato real; miniatura da régua com o risquinho novo. Botão único "Que lindo!".
3. `Motion.reduced`: sem piscar, troca suave de 0,4 s, sem confete. `Haptics` conforme preferência.
4. "Cresce dormindo" (fases Mocinho e Azul e Dourado): `grow()` com o Tiro dormindo grava
   `growth.pending_reveal`; a revelação toca ao acordar ou ao abrir o jogo (boas-vindas, linha `Line_growth`
   "Ele cresceu enquanto dormia!"); tocar nele acorda e revela na hora. O estado (fase) já muda no `grow()`.
5. Boas-vindas: linha `Line_growth` "Ele pode crescer!" quando houver `growth_ready` não visto.
6. Liberações da fase (02 F) aparecem como "Novo!" depois do cartão (features com requisito `growth`, ainda só
   as que já existem).
7. Remover o feedback provisório da 06.

## Teste da etapa — `ceremony_test.gd` (novo, ≤ 3 min)

`grow()` enfileira uma cerimônia (uma só, mesmo recarregando); nós `BeforeAfter`/`HeightMark`; com
`Motion.reduced` não há tween de piscar; "cresce dormindo" guarda e revela ao acordar e ao reabrir, sem repetir;
linha de boas-vindas aparece e some depois de vista; constante de alternância ≤ 3/s.

Toque real: crescer pelo botão e fechar o cartão.

## PORTÃO — passagem total

- `tools/test_all.ps1` inteiro (uma vez), com duração e falhas registradas.
- Capturas `t04_ceremony_before_after` e o painel de crescimento nas **três resoluções**; `ui_tour` completo em 360×780
  (`--out=tiro08_depois`) comparado com `tiro00_antes` (abrir os PNGs das telas do Tiro, HUD e caderninho).

## Para passar para a próxima

- [x] Crescer completo do Recém-chegado ao Azul e Dourado pelo DEV, vendo as 5 cerimônias sem erro.
- [x] Suíte inteira uma vez; após duas fixtures corrigidas, nenhum teste fora da lista histórica permanece falhando (diferenças de asserts registradas).
- [x] Capturas conferidas.

## Fora desta etapa

Álbum (as fotos oficiais entram na 13), régua na Casa (14).

## Evidência e passagem de bastão

`build/test_logs/tiro08/` (suíte com tempos), `build/screenshots/tiro08_*`. README, ROADMAP, GAME_DESIGN
(seção "Crescimento do Tiro"), `CLAUDE.md`/`AGENTS.md` (linha "Cartão de comemoração" e cerimônia). Sem push.


Registro técnico e tabela arquivo → teste → resultado em [VALIDACAO_08](VALIDACAO_08.md).
