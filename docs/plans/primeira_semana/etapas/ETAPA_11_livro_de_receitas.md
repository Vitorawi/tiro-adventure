# E11. Livro de receitas

## Fontes

Claude Docs e Artifact indisponíveis entre os conectores. Referências locais em `%TEMP%/claude/ecb7a66fe8453e1f/`: `10ea2159-07a2-4098-8ec8-bab61252a04f/scratchpad/plano.md` e a T5 em `21190024-f3e9-4ba7-b173-5032cd6fff58/scratchpad/artifact-files/ed7f930e-e696-49f1-8c44-533a90384d65/project/Livro.dc.html`. O catálogo já incorporado em `game/data/dishes.json` mantém os dados da E02. Em divergências vale REGRAS.md. Receita do dia na banca fica cortada conforme o plano.

## Blocos

1. Catálogo, chaves e save 30 em `game/data`, `Database`, `WeekState` e `GameState`. Contabilizar preparo na fila e no Cozinhar junto e consolidar revelações, estoque e porções pelo motor de pratos.
2. Ligar pedaços a montinhos, pesca, ovos e frutas. Integrar pistas, ingrediente do dia, farejo e desejo por prato inédito.
3. Integrar `recipe_book_ui.gd` ao Caderninho, à Mochila e à cozinha. Reusar folhas, cartões e ícones existentes.
4. Registrar e rodar `recipe_book_test` e a rodada de etapa. Conferir Livro, ingrediente, receita, Segredos e Achado! em 360×780, 390×844 e 412×915 e registrar o roteiro no celular.

Pronto com os 12 pedaços garantidos, as quatro revelações pelos dois caminhos sem duplicação, maestria na produção e teste novo passando. A E12 fica para a sessão seguinte.


## Implementação

- O Livro abre em **Caderninho → Receitas**, pela Mochila e pelo **Ver tudo** do fogão. Cruzar fichas filtra por todos os ingredientes selecionados. Pratos com estoque suficiente vêm primeiro. As páginas mostram o estoque, a origem, o sabor, os nutrientes, a versão caprichada quando existe e os atalhos de preparo. Receitas desconhecidas entram na contagem de cada ingrediente. Pistas e páginas incompletas aparecem em Segredos.
- `GameState` registra a descoberta, a prova e os pontos. O save 30 guarda `WeekState.recipe_book` e os pontos, preparos e estrelas nas chaves existentes de `WeekState.dishes`. O reset segue a regra do plano, sem migração. As receitas fixas mantêm os itens que a história e as encomendas consomem. A qualidade numérica do motor de pratos usa as chaves dinâmicas e tem teto de três estrelas.
- A fila dá um ponto. Cozinhar junto dá de um a três e aplica o desconto de tempo pelas estrelas. Os patamares por receita são 0, 6, 15 e 30. Na fila, Dominada sai com duas estrelas e 75% do tempo, e Especialidade sai com três estrelas e 50% do tempo. O brinde é uma segunda porção do lote, a cada quatro preparos em Dominada e a cada dois em Especialidade. O contador começa ao subir de patamar. O cozinheiro soma até 30 pontos por receita e recebe as vagas, a prévia exata e o resgate de um ingrediente na Gororoba conforme os patamares do plano. Combinações que já devolviam o ingrediente que quebrou a regra preservam esse retorno.
- Cada segredo usa a combinação de `dishes.json`. `recipe_book.json` dá a cada pedaço um contador garantido. São quatro montinhos premiados ao cavar 4, 8, 12 e 16 vezes, três pedaços nas três primeiras pescarias bem-sucedidas, dois nos primeiros lotes de ovos, dois nas primeiras colheitas do pomar e um na terceira entrega da carroça. Na lagoa a página acompanha o peixe, preservando a captura dos primeiros dias. O Caderno de peixes, a vovó, o Feirante e a Laís dão as pistas. O cartão **Achado!** abre o Livro em Segredos.
- Juntar três partes ou acertar no Inventar usa a mesma chave e o mesmo registro de descoberta. O próprio registro serve de recibo, inclusive ao reunir as páginas depois de inventar. Descobrir pelas páginas disponibiliza o preparo e o nome, e a história continua contando os pratos efetivamente feitos.
- A banca tem arroz e semente de abobrinha no dia 3. A muda de batata-doce fica disponível no dia 4, inclusive pelo pomar. A carroça vende a semente de melancia no dia 5. Comprar a semente ou a muda libera o cultivo de forma permanente. Rendimentos e tempos das culturas novas ficam em `crops.json` para a calibração da E15.
- A partir do dia 3, a diária alternada escolhe um ingrediente. O primeiro prato inédito que o usa libera 20 moedas. A rotação e o recibo usam o dia da semana do save. Ao encontrar uma combinação inédita viável na Mochila, Tiro fareja no fogão e o Inventar mostra a indicação. O desejo periódico de novidade aceita qualquer refeição daquele sabor que ele ainda não provou, incluindo a distinção entre receita e qualidade do preparo.
- A Receita do dia na banca ficou fora da E11. Arte provisória registrada em PROVISORIOS.md. A idle aprovada foi conferida pelo SHA-256 `FB010A541283D6FF575032EDF172642B569B0D22EAE062A11F1E4F0D9D4CA0B5`.

## Conferência no celular

1. Abra um save DEV com fogão, vá ao dia 3 às 19h e abra **Caderninho → Receitas**. Alterne as três abas. Toque nos ícones de dois ingredientes e depois no nome de um deles. Confira o estoque, as duplas, as origens e a indicação de falta na receita.
2. Abra um prato, use **Colocar na fila** e volte pelo **Ver tudo**. Use **Cozinhar junto** e confira o resultado de até três estrelas. Em uma receita Dominada, use a contagem do Livro para confirmar a segunda porção na Mochila.
3. Recolha ovos no dia 2, pesque no dia 3 e colha no pomar no dia 4. Toque **Ver no livro** no Achado!, siga as pistas e confira as páginas. Para comparar os dois caminhos, invente uma das secretas antes de juntar a última parte. A contagem de pratos descobertos deve subir uma vez.
4. Confira o ponto de interrogação do fogão e a indicação no Inventar. Atenda um desejo de novidade com um prato novo do sabor pedido. Complete a diária do ingrediente, feche e reabra a PWA para conferir o recibo. Avance ao próximo dia alternado e confira o ingrediente novo.


## Validação

- `recipe_book_test` PASS na rodada final de etapa. Cobre estoque e filtros, os cinco estados, estrelas, tempo, brinde, save e diária, as 12 origens garantidas, os dois caminhos para cada secreta, os ingredientes das lojas e o desejo que recusa um prato já provado. Usa `dev_week_goto`, `dev_week_hour` e toque com `root.push_input` em 360×780. O toque abre o ingrediente, a receita, o Cozinhar junto e Segredos. O cartão Achado! abre por evento real de coleta.
- `tools/test.ps1 -Level etapa -Areas dishes,week,wishes,saves,finds,fishing,farm,market,collections,world,navigation,pet,stations,checks -ChangeList build/e11_changes.txt -Jobs 6 -KeepGoing` selecionou 98 casos em 795,9 s. Com os retestes da versão final, foram **90 PASS, seis falhas históricas e dois timeouts em testes com problemas históricos**. [Rodada de etapa](../../../../build/test_logs/r20261118_205536_dc2ed011/results.csv), [reteste da cozinha e Sítio](../../../../build/test_logs/r20261118_210808_7bc56bc1/results.csv) e [reteste final do Livro e da horta](../../../../build/test_logs/r20261118_211121_55de3b0d/results.csv).
- Repetiram a E10 `tray_test`, `world_selector_test`, `world_view_test`, `tasks_test` e `text_budget_test`, além de `ready_badges_test` do portão M2. `care_ui_test` atingiu o limite novamente e `station_tray_test` atingiu o limite no bloqueio histórico da bandeja dos animais depois do tutorial da pesca. Os retestes passaram em `recipe_book_test`, `cook_dishes_test`, `cook_invent_test` na rodada de etapa, `cook_together_test`, `cook_panel_test`, `cart_test`, `farm_week_test`, `garden_test`, `shop_test` e `pet_care_test`.
- Abertas as 15 capturas nativas do Livro, das duas páginas, de Segredos e do Achado! em 360×780, 390×844 e 412×915. Arquivos em [build/screenshots/e11_livro](../../../../build/screenshots/e11_livro/). Aparelho físico pendente.

## Ajuste visual

O Livro usa a largura da moldura, com retorno ao Caderninho no cabeçalho. As fichas da Mochila ficaram mais compactas, os pratos têm linhas com estado e disponibilidade, e a página da receita mostra os nutrientes, a maestria e as duas ações de preparo em menos altura. Segredos usa cartões com os três pedaços e atalhos ao lado de cada pista. As capturas em `build/screenshots/e11_livro/` mostram essa revisão.
