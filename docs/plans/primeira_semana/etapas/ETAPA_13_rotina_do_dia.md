# E13. Rotina do dia

## Fontes

Os conectores Claude Docs e Artifact estavam indisponíveis. No cache `%TEMP%/claude/ecb7a66fe8453e1f/`, consultei `10ea2159-07a2-4098-8ec8-bab61252a04f/scratchpad/plano.md` e `revisao.md` (Parte A). No diretório `21190024-f3e9-4ba7-b173-5032cd6fff58/scratchpad/artifact-files/`, consultei `ed7f930e-e696-49f1-8c44-533a90384d65/project/Filhote_Semana.dc.html` (E) e `Main.dc.html` (T0), além de `8b8bfad0-642d-4cd3-9b72-4c66df961e3c/project/Dia_Tiro.dc.html` (A7). Em divergência vale REGRAS.md.

## Blocos

1. Relógio e recibos em `game_state.gd`, `week_state.gd`, `save_manager.gd` e `week_routine.json`. Pronto quando a seleção, os cartões e o convite sobrevivem ao save 32 e a virada de dia respeita as refeições guardadas.
2. Cartões em `main.gd` e `celebration.gd`. Pronto quando aparecem uma vez por dia na fila, depois da cerimônia pendente, e mostram aberturas, recuperação e resumo do dia.
3. Diárias e linhas em Missões e no Caderninho. Pronto quando as ações reais completam objetivos, os atalhos chegam ao lugar e as semanais só abrem em Dentinhos. Arte provisória registrada em PROVISORIOS.md.
4. Validação em `week_routine_test`, teste da semana, livro, áreas afetadas e capturas nos três tamanhos. Registrar comparação com a E12 e roteiro para aparelho físico.

## Implementação

- `GameState` usa a data civil do relógio para sortear a atividade entre as disponíveis, fechar as duas refeições e marcar cada cartão ao abrir. A Boa noite fica disponível ao fechar a janela do jantar. Na volta após faltar, as refeições anteriores são apuradas antes do cartão do dia atual. A fila mantém a vez da cerimônia e de suas novidades. O crédito de 30 moedas conserva o recibo `week_morning:2` da E12.
- Antes de Dentinhos, Missões mostra Hoje junto da História e um único Próximo passo. O Caderninho abre cada uma das três linhas completas. O progresso vem do preparo e da prova de pratos, da horta, das brincadeiras, das aulas, dos shows, dos carinhos e do registro de refeições. As quatro fotos das linhas entram no Álbum.
- Os prêmios das diárias e das linhas caem automaticamente por recibo. Onde a fonte dizia apenas “moedas”, a E13 usa os valores de `week_routine.json` para calibrar na E15. As sementes de prêmio somam um produto à próxima colheita do mesmo tipo quando usadas em canteiro já liberado. A bolinha usa o item da Carroça. O paninho fica como lembrança na Mochila.
- O primeiro Bom dia após um dia fraco oferece o aviso uma vez. A opção começa desligada e pode ser alterada na folha Hoje. O aviso funciona com o jogo aberto. A refeição deixada pronta pode cair no período mesmo com o jogo fechado. O save 32 guarda os cartões, o sorteio, os objetivos e a opção, com reset e sem migração.

## Roteiro curto no celular

1. No dia 2, abra o Bom dia, confira o crédito de 30 moedas e reabra a PWA. Confirme o saldo, a ausência de um segundo cartão e a mesma atividade em Missões.
2. Complete as duas refeições e a atividade. Depois da janela do jantar, confira patinha, prato novo, selo e silhueta. Se crescer no mesmo dia, confirme que a cerimônia fica na frente dos cartões da rotina.
3. Após faltar um dia, abra o Bom dia fraco e ative o aviso. Use **Deixar pronto**, feche a PWA e volte durante a janela. Confira o prato servido, a recuperação e o capítulo pendente. Deixe a outra janela sem prato para conferir o aviso com o jogo aberto. Confira que outro dia fraco não repete a oferta.
4. Em Missões, desça de Hoje à História e ao Próximo passo. No Caderninho, toque nas três linhas, percorra seus passos e use **Ir**. Confira o toque, a rolagem e as semanais ao chegar a Dentinhos.

## Validação

- `week_routine_test` usou `dev_week_goto` e `dev_week_hour` para avançar o calendário e as ações reais da horta, do fogão, do quintal, das refeições e do crescimento. Cobriu a volta após faltar, o dia fraco, os recibos únicos, a marmita deixada pronta, as três diárias, os destinos **Ir** e a fila com a cerimônia.
- `week_story_test` voltou a percorrer a primeira semana até Dentinhos e a primeira missão da Vila. `recipe_book_test` e os testes focados de relógio, refeição e Álbum passaram. A campanha integral fica para a E15.
- Conferidas 15 capturas nativas de Bom dia normal e fraco, Boa noite, Missões e Caderninho, em 360×780, 390×844 e 412×915. [Capturas](../../../../build/screenshots/e13_rotina/).
- Na exportação Web local, foram usados toques em 390×844 para abrir a caixinha. Depois de fechar e iniciar outro processo do Chrome, o IndexedDB carregou o save 32 e o Bom dia visto não reapareceu. [Antes e depois da reabertura](../../../../build/screenshots/e13_rotina/revisao_pwa.png).
- A rodada ampliada de `tools/test.ps1 -Level etapa` cobriu semana, história, pratos, saves, álbum, coleção, truques, interface, Tiro e Sítio. Foram 143 casos, com 122 PASS, 18 falhas e 3 limites de tempo na primeira passada. Os retestes conferiram as origens dos itens novos, o catálogo ampliado do Álbum, o toque no HUD e as conversas após o Bom dia. [Rodada ampliada](../../../../build/test_logs/r20261118_235039_e75314e4/results.csv).
- Após os retestes, ficaram **131 PASS, 10 falhas e 2 limites de tempo**. Todos os 117 casos que passaram na E12 passaram de novo entre os 128 casos comuns. [Rotina, história, livro e textos](../../../../build/test_logs/r20261119_001625_866cdc5c/results.csv), [conversas](../../../../build/test_logs/r20261119_001802_0f23df58/results.csv), [Álbum](../../../../build/test_logs/r20261119_000136_88c37216/results.csv), [livro do Álbum](../../../../build/test_logs/r20261119_000930_09e93d14/results.csv), [origens e HUD](../../../../build/test_logs/r20261119_000633_798b6cec/results.csv) e [tutorial e humor](../../../../build/test_logs/r20261119_001456_b9c4b99b/results.csv).
- Permanecem as falhas da E12 em `card_reveal_test`, `hud_growth_test`, `quest_reward_test`, `ready_badges_test`, `tasks_test`, `text_budget_test`, `world_selector_test` e `world_view_test`. `care_ui_test` e `station_tray_test` atingiram o limite de tempo. `tray_test` falhou nesta rodada e havia atingido o limite na E12. Entre os casos adicionais, `nature_routes_test` ainda espera a antiga rota de uma hora do pomar.
- A conferência em celular físico fica pendente. O aviso opcional usa o relógio do jogo aberto.
