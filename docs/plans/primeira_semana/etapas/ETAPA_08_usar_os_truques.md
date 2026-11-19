# E08. Usar os truques

## Referências

Claude Docs e Artifact indisponíveis. O documento “Tiro filhote: plano da primeira semana” (projeto `b45e1b2e-da97-4e57-af6f-b9e8a342ad66`) foi consultado na cópia `10ea2159…/scratchpad/plano.md`, nas seções de usos dos truques, tutoriais e desafios. A prancha T3 do canvas “Primeira semana do Tiro” foi consultada em `21190024…/scratchpad/artifact-files/ed7f930e…/project/Truques.dc.html`, nos quadros do pedido antes de comer e do show.

## Arquivos e execução

1. `GameState`, `WeekState` e dados de progressão/crescimento/álbum: validar refeição, sequência, prêmio diário e desejo. Separar os contadores dos acertos da aula e atualizar a versão do save.
2. `MealUi`, `TrickLesson`, `TrickUi` e navegação do Sítio: oferecer o pedido com “Só dar”, reaproveitar gestos e madeira e ligar o show à plateia da E06.
3. `trick_use_test` na suíte e nas áreas afetadas. Conferir almoço, jantar, erro, pulo, bônus, calendário do show, foto, recompensa, desejo e níveis do Caderno.
4. Rodar `tools/test.ps1 -Level etapa`, comparar com a E07 e abrir capturas em 360×780, 390×844 e 412×915. Registrar os provisórios e atualizar Andamento e ROADMAP.

Pronto quando almoço e jantar puderem ser servidos em todos os resultados, o show pagar uma vez por dia a partir do dia 6, a aula cumprir o desejo e `trick_use_test` passar.

## Implementação

- A partir do dia 3, servir uma refeição ainda pendente no almoço ou jantar abre o pedido sobre a tigela. O mesmo fluxo recebe o prato recém-preparado em Cozinhar junto. O truque vem do conjunto aprendido na Aula. “Só dar”, errar e deixar o tempo acabar servem o prato normalmente. Acertar aplica Felicidade +5 (+8 em Sabe bem ou Craque) e um momento de Esperteza fora do teto do período. A janela é conferida ao servir e o recibo da refeição guarda o truque.
- A partir do dia 6, toque em um dos integrantes da plateia ou use o botão do Caderno. Com os três truques aprendidos, escolha 3, 4 ou 5 gestos em ordem. Um erro permite tentar o mesmo gesto dentro do tempo. Cada dia com show concluído paga 10 moedas provisórias e a primeira conclusão rende a foto. O primeiro show de cinco sem erros concede também três biscoitos. A futura linha “Aplausos” pode usar o contador `trick_show`.
- O desejo “Quero treinar” concorre no sorteio quando há uma aula disponível. “Ir” abre o Caderno no Sítio e uma aula concluída resgata o momento automaticamente. Contadores `trick_meal`, `trick_show` e seus detalhes guardam os usos. A Aula continua sendo a fonte dos acertos do Caderno. `SAVE_VERSION` 27, com reset.

## Validação

- `trick_use_test` passou em 48,8 s no circuito final e nas três execuções gráficas. Fixou o viewport em 360×780 no modo headless, usou o calendário DEV e injetou toque/arrasto. Cobriu bônus de almoço e jantar, erro e pulo, repetição, fila e prêmio do show após carregar o save e no dia seguinte, foto, desejo pelo botão “Ir” e acertos do Caderno.
- `trick_lesson_test` passou em 51 s. `cook_together_test` passou em 86,2 s, incluindo o pedido da tigela após “Dar ao Tiro”. As 24 capturas nativas foram abertas e conferidas em 360×780, 390×844 e 412×915. PNGs e pranchas em `build/screenshots/e08_tricks/`. A idle aprovada manteve o SHA-256 `FB010A541283D6FF575032EDF172642B569B0D22EAE062A11F1E4F0D9D4CA0B5`.
- `tools/test.ps1 -Level etapa` com as áreas dos arquivos da E08, retestes do Álbum/conteúdo e área de pratos somou **106 testes distintos, 95 PASS, 10 falhas e 1 timeout**. Logs em `build/e08_etapa.log`, `build/e08_reteste_album.log` e `build/e08_reteste_cozinha.log`. Os retestes passaram com os contratos do catálogo atualizados para 55 fotos, o novo painel registrado e as regras de dia das aulas reconhecidas pelo teste de desejos.
- As falhas restantes já aparecem no registro da E07. São `card_reveal_test`, `hud_growth_test`, `item_sources_test`, `onboarding_test`, `photo_rarity_test`, `station_tray_test`, `tasks_test`, `tray_test`, `world_selector_test` e `world_view_test`. `care_ui_test` voltou a exceder o tempo. As verificações requeridas da E08 passaram.

## Conferência no celular

1. No DEV Semana, aprenda Senta, Dá a pata e Deita. No dia 5 às 12h, arraste um prato à tigela e acerte o gesto. Às 19h, sirva outro prato e teste “Só dar” ou erre o gesto. Em ambos os casos o Tiro deve comer. Confira o ganho de Felicidade e Esperteza no acerto.
2. No dia 6, toque na vovó ou na Laís ao lado do tapete. Confira a fila de gestos, a troca de lado da pata e a descida de dois segundos do Deita. Termine o show, abra a foto no Álbum e tente de novo no mesmo dia. No dia 7, confira a liberação e tente cinco gestos sem erros.
3. Com a caminha e Filhotinho, use o balão “Quero treinar” quando aparecer. No DEV, “Desejo novo já” refaz o sorteio. Confira o destino do “Ir” e o momento ao terminar uma aula. Complete a apresentação da lagoa se ela ainda estiver cobrindo o Sítio.
