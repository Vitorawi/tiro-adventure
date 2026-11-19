# E07. Aula do Tiro e caderno de truques

## Referências

- Claude Docs e Artifact indisponíveis nesta sessão. Consultadas as leituras locais salvas no cache do Claude: `10ea2159…/scratchpad/plano.md` (seções “Brincar, itens e truques” e “Dois minigames novos”) e `21190024…/scratchpad/artifact-files/ed7f930e…/project/Truques.dc.html` (T3) e `Minigames.dc.html` (T6).
- Senta no dia 2, Dá a pata no dia 4, Deita no dia 5. A T3 traz o caderno e a versão anterior dos gestos. A T6 e o ajuste 2 de REGRAS definem a aula: arco por cima do focinho, descida até a pata indicada e descida lenta até o chão, respectivamente.

## Arquivos

- `game/autoload/game_state.gd`, dados de progressão e crescimento: abertura, biscoito, períodos, pontuação e contadores.
- `TrickUi`, `Places`, `GrowthUi` e cena da aula: caderno e navegação pelo tapete do Sítio e pelo Para crescer.
- `game/tests/trick_lesson_test.gd`, roteiro de capturas e `tools/test_areas.json`.

## Passo a passo

1. Definir os caminhos, dias e ajustes de pontuação. Conectar o custo ao Biscoito e registrar o limite por período.
2. Montar a aula de cinco repetições com Mostrar, Marcar em “Isso!” e Premiar tocando no Tiro. Encerrar com estrelas, acertos e próximo nível.
3. Abrir o caderno pelo tapete e ligar os requisitos do Para crescer aos contadores da aula. Deixar com a Nina os truques a partir de Fala.
4. Conferir o fluxo por toque nas três resoluções e registrar a arte provisória.

## Testes e critério de pronto

- `trick_lesson_test` cobre dias, caminhos, repetições, estrelas, cobrança, níveis, período, fraquinho e Para crescer. Usar o calendário DEV e toque injetado no viewport de 360×780.
- Rodar `tools/test.ps1 -Level etapa` com as áreas afetadas e abrir as capturas de 360×780, 390×844 e 412×915.
- Pronto quando os três truques subirem de nível pela aula e o teste passar.

## Implementação

- O tapete do Sítio abre o Caderno de truques a partir do dia 2. A aba Truques do caderninho e o botão do Para crescer levam à aula da vovó. Cada cartão mostra o nível, a barra até o próximo patamar e o motivo de bloqueio. O Deita pede uma descida lenta e dois segundos no alvo. Na pata, o lado alterna a cada repetição.
- `progression.json → tricks.*.lesson` descreve gestos, dias e clipes provisórios. `trick_settings.lesson` guarda o número de repetições e as faixas de pontuação. A aula exige cinco sequências completas. Seguir o caminho vale 1 ponto, marcar vale até 2 e premiar no tempo vale 1. Os totais 0–9, 10–16 e 17–20 dão, respectivamente, 1, 2 e 3 estrelas. Em Sabe bem, aumenta o percurso e diminui a tolerância de marcação.
- O `GameState` aceita biscoitos fixos e do Inventar. Cobra um ao concluir, incluindo ao praticar no nível Craque. Sair descarta a aula em andamento. Cada estrela soma um acerto em `trick:<id>`, com níveis 3/8/15. O primeiro aprendizado conta uma vez em `trick_learned` e usa os eventos de momentos e álbum existentes.
- `WeekState.trick_periods` guarda o último período civil de cada truque concluído. Manhã começa às 6h, tarde às 12h e noite às 18h, com a madrugada na noite anterior. `SAVE_VERSION` 26 aplica reset sem migração.
- Os ganchos `trick_sit` e `tricks_three` estão ligados. Na Praça, Nina ensina Fala, Rola, Pula e Gira. A foto “Pata!” recebe o evento da Aula e o destino do Sítio. Pedido de truque na refeição e show ficam na E08.

## Validação

- `trick_lesson_test` PASS em 44,6 s no reteste da etapa. Treinou os três truques em 360×780 pelo viewport, com toque e arrasto injetados, cinco repetições cada. Cobriu arco cortado, pata errada, Deita solto cedo, estrelas 1/2/3, custo, cancelamento, níveis, limite por período, save, fraquinho e Para crescer.
- `tools/test.ps1 -Level etapa -ChangeList build/e07_files.txt -Areas 'tricks,growth,week,saves,world,farm,album,story' -Jobs 4 -KeepGoing` selecionou 107 testes. Consolidado com os retestes: **94 PASS, 12 falhas e 1 timeout**. Logs em `build/e07_etapa.log` e `build/e07_reteste.log`. Passaram os retestes de conteúdo, truques da Nina, crescimento (motor, UI e história), álbum, Sítio e save.
- Falhas registradas na E06: `tray_test`, `station_tray_test`, `world_view_test`, `world_selector_test`, `item_sources_test` e `tasks_test`. Registros anteriores também apontam `hud_growth_test`, `photo_rarity_test` e `text_budget_test`. `onboarding_test`, `ready_badges_test` e `care_ui_test` repetiram os mesmos problemas com os ganchos da E07 desligados: espera pela lagoa, contagem do pomar e expectativa antiga de Coragem, respectivamente. `card_reveal_test` conclui as asserções e o runner marca falha pelo acesso a uma árvore já removida em `CardViewer._layout_later`.
- Abertas e conferidas 27 capturas nativas de caderno, gestos, marcação, prêmio, resultado e crescimento em 360×780, 390×844 e 412×915. PNGs e pranchas de conferência em `build/screenshots/e07_tricks/`. A idle aprovada permanece com o arquivo intacto.

## Conferência no celular

No DEV Semana, abra o tapete nos dias 2, 4 e 5. Confira o tracejado sob o dedo, a troca de lado da pata, os dois segundos do Deita e o toque em “Isso!”. Termine uma aula, confira a baixa de um biscoito e tente repetir antes da troca de período. Em um dia fraco, sirva uma refeição na hora e volte ao tapete para conferir a liberação.
