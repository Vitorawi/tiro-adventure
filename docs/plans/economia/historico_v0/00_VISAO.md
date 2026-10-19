> **RASCUNHO PAUSADO — 16/10/2026, por pedido do Vitor. Não executar.** Números, produtos e critérios abaixo não estão aprovados. Conteúdo preliminar preservado para revisão após o estudo [Economia e ritmo do Tiro](../../../reports/Economia%20e%20ritmo%20do%20Tiro.md). Consulte o [estado do planejamento](README.md).

# Uma vida que cresce — visão da economia e da progressão

Plano solicitado por Vitor em 16/10/2026. **Planejamento, não implementação.** Ler o [índice](README.md) e executar somente a etapa pedida. Este plano substitui, quando cada etapa for executada, os números e a regra de estoque ilimitado do antigo `../ARMAZENAMENTO.md`; não reabre o plano visual.

## 1. Experiência desejada

O Tiro continua sendo o centro afetivo. A produção sustenta o cuidado, a casa, os amigos e a comunidade. O jogador aprende uma coisa por vez, encontra pequenas decisões e vê o resultado no mundo. Não deve precisar trabalhar numa planilha para jogar, tocar sem parar, ficar sem poder cuidar do cachorro ou voltar em horários obrigatórios.

A curva é **experimentar → escolher → combinar → planejar → realizar um projeto**. Aumentar dificuldade significa aumentar decisões compreensíveis, não multiplicar arbitrariamente entregas e esperas.

## 2. Diagnóstico confirmado em 16/10

- 81 missões, sendo 31 principais e 50 nas linhas. 2.660 moedas nas missões e 700 nos capítulos, além de níveis, desejos, colheitas, vendas, passeios e presentes.
- Plantar não gasta moedas; `crops.coins` é prêmio de colheita, NÃO preço de semente. Cenoura regada imediatamente: 42 s, 3 moedas + duas unidades vendáveis por 6; teto de 51,4 moedas/min com quatro canteiros e venda de tudo. Não é renda medida de jogador real.
- Caixa de petiscos: ingredientes imediatos valem 121; venda 60. Contrato de três: 220 contra 363 dos ingredientes, além de parafuso/XP. É preciso calcular toda a cadeia, não só comparar contrato com produto acabado.
- Silo exige `main_9_cheese`; armazém exige `bloblo_silo`; baú exige `bloblo_warehouse`. Antes da construção, `storage_active` deixa a categoria ilimitada.
- Baú guarda somente `treat_box` e `accessory_set`; objetos de passeio têm `storage: none`. Roupas costuradas vão para a coleção, não ocupam o baú.
- Bosque/Prado: segunda vaga em três coletas e terceira em nove; aumento de rendimento e vagas se reforçam.
- `pet()` dá afeto por toque; rotina de banho conta mesmo sem necessidade. Recarga de XP de cuidado não protege esses outros contadores.
- `progression_test.gd` força prontos e usa `unlimited_storage`; é teste de alcançabilidade, não validação de economia. `onboarding_test` mede parte do começo, com agente idealizado.

## 3. Decisões deste plano

1. Estoque finito desde a primeira unidade de cada categoria; a construção amplia a capacidade provisória.
2. Sementes básicas gratuitas. Retirar moedas recorrentes da colheita; renda vem sobretudo de vendas e entregas. Não introduzir custo de replantio nesta rodada.
3. Sem deterioração, dívida, manutenção obrigatória, aluguel, imposto, energia global do jogador ou perda de itens por ausência.
4. Recompensas de cuidado priorizam vínculo. Nenhuma economia exige dar banho num cachorro limpo repetidamente.
5. Uma receita comercial agrega valor sobre seus ingredientes; uma encomenda agrega valor sobre a venda avulsa. Exceções afetivas/cosméticas são explícitas, nunca erro escondido.
6. Usar estações, mapas, personagens e interface existentes. Acrescentar seis produtos, melhorias de filas, três reformas, uma festa e contratos recorrentes; não criar dez prédios nem outra moeda.
7. Não resetar saves. A autorização antiga de reset do plano `comeco` não vale para este plano. Não retirar aquisições, roupas, moedas ou materiais já obtidos.
8. Nada depende exclusivamente de sorte, item raro de passeio ou dia específico para avançar na campanha.
9. Publicação continua exigindo pedido explícito. Este plano não autoriza push.

## 4. Curva por atos

| Ato | Conteúdo | Decisão ensinada | Pressão que NÃO entra ainda |
|---|---|---|---|
| Acolhimento | Laís, cuidados, caminha, desejos | Tocar, reconhecer necessidades | Dinheiro apertado, receitas longas |
| Nossa horta | Bloblo, dois/quatro canteiros, cesto/silo, venda | Guardar uma parte e vender excedente | Materiais da Natureza |
| Cozinha e vizinhança | Geladeira, fogão, liquidificador, Vila/Praça | Usar ingrediente em comida ou pedido | Grandes contratos e todas as estações juntas |
| Construir com intenção | Natureza, caixa/armazém, bancada | Reservar material e escolher melhoria | Três novas cadeias na mesma missão |
| Produzir em conjunto | Animais, moinho, queijaria, banca, estufa | Coordenar insumos, filas e estoque | Calendário obrigatório |
| Nosso lugar | Ateliê, clientes, especializações, reformas | Planejar entregas por etapas | Repetição sem mudança no mundo |
| Comunidade viva | Festa, encomendas variadas, amizades e coleções | Escolher metas pessoais e projetos | Obrigação de jogar todos os dias |

## 5. Ritmo desejado — hipótese a validar, não promessa

Perfil de referência: três sessões de 10 minutos por dia, separadas por cerca de 6–8 horas; a primeira pode durar 20 minutos. Perfil leve: uma sessão de 10 minutos/dia. Perfil ativo: sessões longas com ações custando tempo e navegação, sem alterar o relógio do aparelho.

| Marco | Tempo ativo desejado / referência | Janela de calendário de referência |
|---|---|---|
| Primeira colheita | até 4 min | primeira sessão |
| Primeiro desejo / achado | até 7 / 10 min | primeira sessão |
| Silo pequeno e primeira venda | 8–15 min | primeira sessão |
| Cozinha operando | 15–30 min | primeiras 1–3 sessões |
| Vila e primeiro passeio | 25–50 min | dia 1–2 |
| Natureza e bancada | 60–100 min | dia 2–4 |
| Animais + processamento e banca | 2–4 h acumuladas | dia 4–8 |
| Estufa, ateliê e capítulos 1–9 | 4–7 h acumuladas | dia 8–14 |
| Reformas e primeira Festa da Vila | 7–11 h acumuladas | dia 14–24 |
| Metas opcionais recorrentes/coleções | sem término obrigatório | semanas seguintes |

Tempos ativos e de calendário são medidos separadamente. Jogo contínuo pode terminar antes: não inserir bloqueio de dia nem inflar requisitos só para impedir isso. Se a simulação mostrar que o conteúdo não sustenta a janela sem repetição, reduzir a promessa de duração e registrar; priorizar diversão. Primeiro passeio deve continuar acessível em até 60 minutos ativos, sem piorar o primeiro raro garantido desnecessariamente.

## 6. Como cada recurso cria uma escolha

- Moeda: escolher um investimento, não pagar por existir. O jogador normalmente paga uma melhoria relevante, mas não todas as alternativas de uma vez.
- Estoque: manter reservas e produzir conforme demanda. Lote pronto nunca é perdido. Apertos iniciais se resolvem com uma venda ou uso, não cinco telas.
- Filas: preparar a próxima sessão. Vaga extra aumenta autonomia; não aumenta velocidade de uma máquina.
- Materiais: repartidos entre melhorias, objetos e contratos. Entrega parcial de projetos dá destino a materiais enquanto a obra avança.
- Tempo: curto para participar agora, médio para organizar a sessão, longo para ausências. Toda fase mantém opções curtas úteis.
- Experiência: mostrar domínio e liberar opções; não travar a história em atributo oculto.
- Vínculo: pequenas interações significativas ao longo do jogo. Carinho visual livre, recompensa protegida contra repetição mecânica.

## 7. Conteúdo novo dentro do escopo

Seis produtos: pão da vila, biscoito de milho, compota de maçã, iogurte de morango, cesta de piquenique e sachê de flores. São bens da comunidade; só recebem `feed` se houver decisão específica de design, não automaticamente por serem comida.

Três reformas: banco da praça, jardim da vila, cantinho de piquenique. Grande projeto: Festa da Vila com quatro entregas visíveis. Todos usam áreas existentes sem bloquear caminhos. Cliente da Laís, da Bloblo e da Artesã evolui por entregas variadas. Nina e Guia ganham objetivos que ligam Tiro, passeios e esses lugares.

Fora do escopo: novo mundo, nova moeda, leilão, multiplayer, clima destrutivo, produtos que estragam, calendário de presença diária, prestígio/reset, manutenção de máquinas, novo minijogo. Ver [FUTURO](FUTURO.md).

## 8. O que define sucesso

O jogador consegue explicar seu próximo objetivo, tem motivo para ampliar antes do fim e escolhe entre duas melhorias úteis. Nenhuma cadeia comercial perde valor sem motivo. Sair do jogo não exige abandonar a produção. A festa transforma o mundo, não só aumenta um contador. Saves existentes continuam funcionando. O relatório final separa fatos medidos, hipóteses e impressões de teste no celular.
