# E12. História da semana

## Fontes

Claude Docs (projeto b45e1b2e-da97-4e57-af6f-b9e8a342ad66) e Artifact não estão disponíveis nesta sessão. Referências consultadas no cache Claude em `%TEMP%/claude/ecb7a66fe8453e1f/`: `plano.md` e as pranchas `Dias1e2.dc.html`, `Dias2a7.dc.html` e `Semana2.dc.html`. Em divergência prevalece REGRAS.md.

## Blocos

1. Conteúdo e calendário. Substituir os capítulos iniciais em `quests.json` e `progression.json`. Definir falas, fotos e desafios nos dados. Motor em GameState e estado persistido no save 31.
2. Chegada e Missões. Caixinha progressiva, janela do jantar, espera do dia seguinte e um Próximo passo das linhas. Reaproveitar IntroScene, Missões, Caderninho e relógio.
3. Sítio e saída. Ligar os objetivos às ações, recibos e pratos do Para crescer. Integrar o almoço no passo Dentinhos, foto de grupo e acesso à Vila. Renumerar os requisitos posteriores.
4. Testar. Registrar o percurso da semana e ajustar fixtures da abertura e o roteiro da campanha. Rodar a etapa, conferir as quatro telas nas três resoluções e registrar a comparação com a E11.

Pronto quando um save novo percorre os 30 passos reais até Dentinhos e consegue completar a primeira missão na Vila. A campanha integral roda na E15.

## Implementação

- A chegada usa a caixinha da Casa e revela a pose aprovada em etapas, com a Laís e a vovó. Dois canteiros começam disponíveis. A primeira horta entrega o fogão e a primeira papinha liga Cozinhar junto à tigela. O Inventar abre no início da janela do jantar escolhida no relógio do Tiro. A primeira papinha do dia da chegada dá uma patinha mesmo fora da janela.
- A História tem 30 passos em sete capítulos. O próximo capítulo fica visível com **A vovó volta amanhã** até o dia mínimo e até virar a data do último capítulo concluído. Quem falta retoma o mesmo capítulo e suas surpresas e fotos. Concluir o capítulo atrasado libera o seguinte no próximo dia civil. O desafio opcional acompanha o dia do relógio. Na primeira semana a aba Missões mostra a História e, quando há uma linha disponível, um único Próximo passo. As outras linhas ficam no Caderninho.
- O Bom dia do dia 2 paga 30 moedas. A compra do kit do galinheiro custa 60 e devolve 20 no mesmo ato. Cada pagamento usa o motor de recibos. Os três pratos-chave usam o registro de refeições da fase do Para crescer. O ovo dado em Filhotinho já vale no dia 6. O Senta da fase anterior continua no total dos três truques aprendidos.
- O passo final inclui uma porção para a vovó, outra para a Laís e outra para o Tiro. Servir baixa o prato do estoque. Os lugares já servidos persistem no save. A terceira porção registra a foto de grupo e abre o caminho para a cerimônia. O Tiro passa para Dentinhos pelo Para crescer.
- Dentinhos abre a Vila. A missão seguinte é **Passeio na Vila**, agora no capítulo 8. A Praça segue atrás da primeira encomenda e a Natureza atrás do baú de passeio, no capítulo 9. A história anterior da Vila em diante conserva a ordem e os prêmios, com numeração atualizada.
- O save passa de 30 para 31, com reset e sem migração. `WeekState` grava a data do último capítulo, o desafio corrente e os lugares servidos. Falas, calendários, objetivos, fotos e prêmios ficam nos JSONs. A idle aprovada conserva o SHA-256 `FB010A541283D6FF575032EDF172642B569B0D22EAE062A11F1E4F0D9D4CA0B5`.

## Roteiro curto no celular

1. Comece um save novo. Abra a caixinha e toque nos carinhos. Faça a papinha no Cozinhar junto e arraste para a tigela fora da janela. Confira a patinha e o aviso do jantar no último passo do capítulo.
2. No dia 2, confira o Bom dia e a devolução de 20 moedas ao comprar o kit. Feche e reabra a PWA para conferir os dois recibos. Complete o jantar e vá a Para crescer.
3. Depois de faltar um dia, abra Missões. Confira o capítulo atrasado, siga o **Ir** e confirme a surpresa e a foto no Álbum. Sirva o prato com ovo em Filhotinho antes do dia 6 e confira o ✓ ao chegar ao show.
4. No dia 7, abra o almoço pelo **Ir**, sirva os três lugares e reabra a PWA depois do primeiro prato. Confira a foto a seguir, a cerimônia e o **Ir** de Passeio na Vila. Deslize a lista e use o Caderninho para confirmar que há um único Próximo passo em Missões durante a semana.

## Validação

- `week_story_test` passou. O roteiro começa com o save novo, usa `dev_week_goto` e `dev_week_hour` para o calendário e percorre ações, compras, recebimentos e crescimentos reais. Cobre a papinha às 23h, os dois recibos, os três pratos-chave, a volta após faltar, a espera após salvar, o almoço com três lugares e a primeira missão da Vila.
- `onboarding_test` passou no percurso de manhã com a espera pelo jantar. `recipe_book_test`, `content_test`, `texts_test` e `scripts_check` passaram. O `progression_test` usa a mesma abertura e passou em `--check-only`. A execução integral fica na E15.
- Conferidas 27 capturas nativas em 360×780, 390×844 e 412×915. Incluem a caixinha, a História, a espera, o almoço, a foto de grupo e a chegada à Vila. O teste de captura tocou nos botões **Ir** e **Servir**. [Capturas](../../../../build/screenshots/e12_historia/).
- A rodada `tools/test.ps1 -Level etapa` nas áreas afetadas selecionou 128 casos. A primeira passada teve 96 PASS, 28 falhas e 4 timeouts. O consolidado pelo último resultado dos retestes ficou em **117 PASS, 8 falhas e 3 timeouts**. [Rodada de etapa](../../../../build/test_logs/r20261118_230541_9644d8fc/results.csv), [reteste dos destinos](../../../../build/test_logs/r20261118_233148_6d36d173/results.csv) e [reteste final](../../../../build/test_logs/r20261118_233402_b88daaea/results.csv).
- A E11 consolidou **90 PASS em 98 casos**. Entre os 93 casos comuns, a E11 teve 85 PASS e a E12 teve 85 PASS. Todos os casos comuns que passaram na E11 passaram na E12.
- Falhas finais em `card_reveal_test`, `hud_growth_test`, `quest_reward_test`, `ready_badges_test`, `tasks_test`, `text_budget_test`, `world_selector_test`, `world_view_test`.
- Limite de tempo em `care_ui_test`, `station_tray_test`, `tray_test`.
- A conferência em aparelho físico fica pendente.
