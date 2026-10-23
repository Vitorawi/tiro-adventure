# Etapa 03 — A tela do Tiro mostra o que ele precisa (PORTÃO de testes)

**Estado: concluída (23/10/2026, Claude Code).** Pré-requisito: 02 concluída.

## Objetivo

Olhar para o Tiro e entender na hora: o que ele está pedindo, o que cada cuidado faz crescer e quanto falta
para a próxima fase. Sai a aba Desejos.

## Leitura

[02 H](02_DESENHO.md), regras de estilo `docs/plans/interface/01_REGRAS_E_ESTILO.md`, `scenes/ui/pet_screen/`,
`scripts/ui/pet_care_tray.gd`, `scripts/ui/hud.gd`, `scripts/ui/growth_ui.gd`, `scripts/ui/pillar_ui.gd`,
`scenes/main/main.gd` (abas), `scenes/ui/wishes_screen/`, `scripts/ui/wish_ui.gd`.

## Entrega

1. **Balão do desejo** sobre o Tiro (reaproveitar `WishBubble`): ícone do pedido + ícone do pilar; tocar mostra
   o pedido em uma linha e o botão Ir quando o desejo é fora da tela (passeio, mundo, comida que precisa fazer).
2. **Anéis das necessidades:** necessidade pedindo pulsa e ganha o mini-ícone do pilar que o cuidado dá.
   Satisfeita: anel normal, sem ícone.
3. **Aviso "Momento de Coragem!"** (pílula curta) com o ícone do pilar voando até o avatar do HUD; o anel do
   avatar avança. Mesmo aviso para momento vindo de passeio/mundo/desejo.
4. **Painel de crescimento** e caderninho: requisitos `moments` em bolinhas (●●●○), com "de onde vêm" (lista
   das fontes do pilar, com Ir quando houver lugar). Sai o texto de pontos/recarga.
5. **Avatar do HUD:** mostra o ícone do desejo ativo (ou da necessidade pedindo); o selo "Animado" chega na 05.
6. **Abas:** Tiro · Mapa · Missões · Mochila. Apagar `scenes/ui/wishes_screen/`, o que restar de `WishUi` sem uso,
   `BondChip` e a feature/aba `wishes` (o "Novo!" do desejo aponta para a tela do Tiro).
7. Capturas `ui_tour` atualizadas para as telas mexidas.

## Teste da etapa

`care_ui_test` (novo): balão aparece com o desejo e some ao atender; anel pedindo tem o ícone do pilar; aviso
de momento aparece e o avatar avança; painel mostra bolinhas certas; só quatro abas; nenhum nó de vínculo.

**Portão:** `tools\test.ps1 -Level portao` (paralelo) — tudo verde, exceto a campanha, que não roda. Capturas nas
três resoluções (360×780, 390×844, 412×915) das telas mexidas. Registrar tempo do portão.

## Para passar para a próxima

- [x] Portão: 442,8 s, 86 PASS; `park_test` falhou só em paralelo (instável) e passou isolado.
- [x] Capturas abertas e conferidas (nada cortado, texto em uma linha).
- [x] README, ROADMAP e `CLAUDE.md`/`AGENTS.md` (abas e tela do Tiro).
