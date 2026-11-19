# E14. Tutoriais

## Fontes

Conectores Claude Docs e Artifact indisponíveis. Consultei o cache em `%TEMP%/claude/ecb7a66fe8453e1f/`.

- `10ea2159-07a2-4098-8ec8-bab61252a04f/scratchpad/plano.md`, seção Tutoriais e guia, e `revisao.md`, Parte A.
- `21190024-f3e9-4ba7-b173-5032cd6fff58/scratchpad/txt/Main.dc.txt` (T0) e `Filhote_Semana.dc.txt` (E), extrações do canvas.
- `REGRAS.md` prevalece. A Aula usa Mostrar, Marcar e Premiar, com um biscoito por aula. Os 33 tutoriais distribuídos pelos dias 1–7 são seguidos, na tabela original, pelo aviso condicional de dia fraco.

## Blocos

1. Extrair foco, mão e balão de Álbum e Pesca para `tutorial_guide.gd`. Pronto quando ambos continuarem com os passos e alvos anteriores.
2. Ligar `week_tutorials.json` às ações e telas da semana. Pronto quando os cinco formatos aparecerem no contexto certo e Pular preservar a História.
3. Persistir os passos em `WeekState` e expor o conteúdo no Manual. Pronto quando a reabertura preservar os passos concluídos e a mão voltar após 20 s.
4. Registrar `week_tutorial_test` e rodar o nível etapa com história e rotina. Conferir capturas nas três resoluções. Deixar a campanha integral para a E15 e o roteiro de sete dias para M3.

## Implementação

- `TutorialGuide` compartilha o foco, a fala e o indicador de gesto entre a semana, o Álbum e a Pesca. A lição semanal aparece junto do controle que executa a ação. Pular dispensa a lição e mantém as regras da História.
- `week_tutorials.json` reúne 33 lições e o caso condicional de dia fraco. Bom dia, Pesca e cerimônia usam as telas já existentes. Os outros formatos reutilizam a fila de cartões, o painel Hoje e os controles do jogo.
- Save **33**, com reset. `WeekState.tutorial` guarda a etapa da chegada, lições concluídas ou puladas e pontos de retomada. A cozinha conserva os brilhos dos gestos concluídos, e a Aula conserva os acertos da rodada dentro do mesmo período. Gestos em curso recomeçam do início.
- Em **Caderninho › Recursos › Manual de tutoriais**, o jogador pode rever qualquer explicação, inclusive as lições puladas. A revisão é uma consulta e não executa ações do jogo.
- Arquivos principais `tutorial_guide.gd`, `week_tutorial.gd`, `week_state.gd`, `week_tutorials.json`, `main.gd`, `intro.gd`, `celebration.gd`, `growth_ceremony.gd`, `pet_care_tray.gd`, `cook_together.gd`, `trick_lesson.gd`, `yard_play.gd`, `room.gd`, `orders_ui.gd`, `game_manual.gd`, `codex_ui.gd`, `album_tutorial.gd` e `angler_tutorial.gd`. Registro do circuito em `tools/test_areas.json`.

## Roteiro para o portão M3 no celular

1. **Dia 1.** Use um save novo. Toque na caixa, segure o carinho, feche a PWA e volte. Plante e colha cenoura e batata. No meio do Cozinhar junto, deixe a mão sumir e confira o retorno após 20 s. Sirva a papinha, leia o relógio, venda cenouras, compre sementes e amplie a horta. Jogue a bolinha, use **Tiro!** e volte no jantar para Inventar. Pule uma lição e revise-a no Manual.
2. **Dia 2.** Confira o Bom dia e o saldo. Use **Ir** no cartão do galinheiro, compre o kit e siga até a montagem. Plante milho, alimente e recolha ovos. Confira a dica junto ao biscoito. Faça uma Aula do Senta com Mostrar, Marcar e Premiar. Dê as duas refeições, brinque de buscar e siga o painel Para crescer até Filhotinho.
3. **Dia 3.** Vá à lagoa e reabra durante a pesca. Confira a sopinha e a terceira vaga, sirva o prato-chave com peixe, peça Senta antes de uma refeição e siga o balão do desejo.
4. **Dia 4.** Colha no pomar, confira quando a fruta volta, veja a primeira dupla no Livro, faça Dá a pata e jogue Cabo de guerra.
5. **Dia 5.** Confira os dois pedidos e os itens à venda na Carroça, entregue um pedido, compre e use xampu e faça a aula Deita.
6. **Dia 6.** Faça o Show, busque uma pista em Secretas e ache o Tiro pelo rabo no Esconde-esconde.
7. **Dia 7.** Use as três tarefas de Hoje e os atalhos de Para crescer, entregue o mordedor, faça o almoço de despedida e veja a cerimônia de Dentinhos. Confira o primeiro destino da Vila. Num percurso com refeição perdida, veja também o Bom dia de dia fraco e a recuperação com a próxima refeição na hora.

## Validação

- O percurso de save novo usa o relógio acelerado, os controles reais para abrir e segurar a caixinha, plantar, colher, cozinhar, arrastar a papinha à tigela, abrir a banca e comprar o kit. As ações do motor preenchem o restante da História até Filhotinho. A mão volta após 20 s no teste, Pular persiste e o Manual reabre a lição dispensada. A cena é recriada a partir do save no carinho, na bandeja de sementes e em Mexer.
- Foram abertas pranchas com os cinco formatos, o Manual e a cozinha em [360×780](../../../../build/screenshots/e14_tutoriais/360x780_prancha.png), [390×844](../../../../build/screenshots/e14_tutoriais/390x844_prancha.png) e [412×915](../../../../build/screenshots/e14_tutoriais/412x915_prancha.png).
- Na exportação Web local em Chrome com toque emulado a 390×844, o save 33 foi conferido no IndexedDB. Outro processo do navegador com o mesmo perfil abriu no carinho e um toque sustentado avançou para o carinho seguinte. [Antes](../../../../build/screenshots/e14_tutoriais/pwa_antes.png) · [reabertura](../../../../build/screenshots/e14_tutoriais/pwa_reaberta.png) · [carinho seguinte](../../../../build/screenshots/e14_tutoriais/pwa_carinho.png).
- A fixture de Cozinhar junto prepara o jantar do dia 1 para que o teste de pratos inventados seja independente da hora local. O teste de raridade das fotos agora verifica a versão 33. O teste de capturas da História usa o gesto de segurar na abertura.
- O reteste final de etapa passou **6/6**, incluindo `week_tutorial_test`, `week_story_test` e `week_routine_test`. Álbum, Pesca, Aula do Tiro, Manual, raridade e Cozinhar junto também passaram na rodada focada. Introdução passou na rodada ampliada e isoladamente após uma falha sob carga. [Reteste final](../../../../build/test_logs/r20261119_123938_8e520609/results.csv) · [rodada focada](../../../../build/test_logs/r20261119_121427_463a05ef/results.csv) · [Introdução isolada](../../../../build/e14_intro_reteste.log).
- A rodada ampliada de `tools/test.ps1 -Level etapa` selecionou 144 testes. Com os retestes, ficaram **132 PASS, 10 falhas e 2 limites de tempo**. Oito falhas são as registradas na E13 em `card_reveal_test`, `hud_growth_test`, `quest_reward_test`, `ready_badges_test`, `tasks_test`, `text_budget_test`, `world_selector_test` e `world_view_test`. `tray_test` continua falhando na estufa e `nature_routes_test` ainda espera a rota antiga do pomar. `care_ui_test` e `station_tray_test` atingiram o limite. [Rodada ampliada](../../../../build/test_logs/r20261119_120623_444134f9/results.csv) · [retestes de Natureza](../../../../build/test_logs/r20261119_123811_b4eb699e/results.csv).
- Os 16 casos adicionais da lista do portão foram rodados à parte. Oito passaram, sete falharam (`food_order_touch_test`, `food_menu_bounds_touch_test`, `daily_claim_touch_test`, `blender_position_touch_test`, `park_test`, `walk_return_test`, `festival_test`) e `drag_scroll_test` atingiu o limite. [Complemento](../../../../build/test_logs/r20261119_122255_151df07f/results.csv).
- Um ensaio adicional que abriu o painel e passou pela cerimônia acusou uma referência de interface liberada durante a sequência de cenas do teste. O reteste da semana conclui o crescimento pela ação do motor nesse ponto. Conferir **Crescer!** pelo painel e a saída da cerimônia no roteiro do dia 2.
- A conferência dos sete dias por uma pessoa em aparelho físico permanece no portão M3. A campanha integral é da E15.
