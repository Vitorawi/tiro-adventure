# Simulação, critérios e protocolo de ajuste

## A. Linha de base antes de mudar números

00 produz auditoria estática (`tools/economy_audit.py`, novo): lê dados reais, calcula margem imediata e cadeia expandida por estação, moedas/XP por origem, lotes máximos, custos de expansão, dependências e ciclos. Não replica GameState dinâmico em Python. Saídas JSON/Markdown/CSV em build/economy/baseline; snapshot dos JSON e revisão do Git. Unidade/campo explícitos: crops.coins é prêmio, não custo.

01 produz simulador headless (`tests/economy_sim.gd` e helper em tests/helpers/, novos) com GameState real e relógio injetável de teste. Desanexar SaveManager antes de reset/mutar. `unlimited_storage=false`, sem moedas/itens grátis, sem setar ready_at=0, sem compras diretas em owned; fora da sessão somente relógio/timers, nunca ações. Fixtures de regras isoladas podem preparar dados, mas relatório de campanha não.

Primeiro conferir uma sequência manual calculável de 20 ações: plantio/rega/colheita/venda, fabricação, fila sequencial, compra, missão, recebimento com estoque cheio. Modelo e regra precisam concordar em entradas, saídas, tempos e moeda. Relógio de simulação não altera Windows; timestamps de todos os subsistemas avançam juntos. Dev tools têm guarda BuildInfo; teste não cria cheat em produção.

## B. Perfis

| Perfil | Agenda | Prioridade |
|---|---|---|
| Referência | primeira 20 min, depois 08 h/14 h/20 h com 10 min cada | história, cuidar, reservar uma meta, pedido, preparar saída |
| Leve | primeira 20 min, depois 19 h/10 min por dia | um objetivo, produções longas disponíveis |
| Ativo | blocos de 2 h, pausas normais | otimizar renda sem saber sorte futura |
| Afetivo | referência | Tiro/amigos primeiro, depois história |
| Comercial | referência | pedido e melhoria produtiva antes de história |
| Recuperação | referência, sofá cedo e venda indevida de ingrediente | reconstruir reserva sem concessão invisível |

Por ação 3 s, mais 2 s para troca de painel/mundo; arrasto: primeiro 3 s, depois 1 s por alvo. Registrar e calibrar com toque manual, não acelerar agente idealizado. Reserva cobre uma meta ativa + cuidado próximo, não todos os projetos futuros. Não vender item reservado para cumprir diária; escolher outro excedente. Lotes longos só quando realmente desbloqueados.

Sementes 1–10 no referência e leve; 1–3 nos demais. Pior caso de raro usa chance 0 e preserva garantia. Reportar mínimo/mediana/máximo, não percentil 95 supostamente robusto com dez amostras. Mesma semente/agenda para comparar revisões.

## C. Registro por ação e por marco

Tempo ativo/calendário, ação e contexto, saldo antes/depois e fonte/sumidouro, estoque/capacidade/reserva por categoria, filas, trabalhos prontos pendentes, necessidades, afeto, bagagem, missão/projeto, motivo de espera ou falha, próximo objetivo. Logs não incluem saves pessoais. Relatório separado para primeira sessão, abertura da Vila, bancada, banca, fim 9, primeiro projeto, festa e todos os depósitos.

Métricas: renda recorrente vs prêmio único; valor livre/custo da próxima escolha; número de pedidos por melhoria; fonte dominante; produção útil por abertura; minutos de autonomia de fila; ações para liberar espaço; ocupação e coletas pendentes; variedade realmente utilizada; tempo gasto em navegação/decisão/limpeza; cenas/interações do Tiro; ociosidade por ausência vs por falta de ação possível.

## D. Invariantes de aprovação

1. Sem perda, duplicação, inventário negativo, moeda negativa ou ciclo de requisitos. Todo lote obrigatório cabe ou existe contribuição parcial explícita. Material da ampliação cabe no estágio anterior.
2. Moeda 0 + inventário vazio tem recuperação via plantio grátis/venda acessível; ração emergencial mantém cuidado. Comprar sofá não encerra história.
3. Nova categoria tem capacidade desde primeira unidade, acesso de consulta/venda e construção atingível antes de saturar a campanha.
4. Tiro retornado não fica ausente por bagagem; abrir/cancelar/importar não ressorteia nem duplica passeio. Não começar nova saída com bagagem pendente.
5. Save mantém posses, níveis/vagas adquiridos, itens excedentes e contratos iniciados; migrar duas vezes não paga duas vezes.
6. Receita comercial nova oferece valor maior que ingredientes imediatos na venda; cadeia completa e minutos de máquina também auditados. Receitas antigas abaixo dessa margem podem permanecer se têm uso afetivo/comercial claro, anotado; perda da caixa atual deve ser corrigida.
7. Pedido comercial paga ao menos o valor avulso dos itens; prêmios de missão afetiva não seguem essa regra. Compra em loja→revenda/pedido não cria arbitragem instantânea sem custo/recarga.
8. Cuidado responde mesmo sem prêmio; repetir banho/carinho vazio não conclui rotinas úteis nem concede afeto sem intervalo. História tutorial continua atingível.
9. `shared_with` e projetos nunca cobram/pagam duas vezes o mesmo marco; nenhuma fonte obrigatória de expansão só por sorte/semana.

## E. Critérios de experiência e faixas de investigação

- Primeira colheita ≤ 4 min ativos; desejo ≤ 7; achado ≤ 10; primeiro passeio ≤ 60. Primeiro presente/ração não exige uso de produção ainda fechada.
- Até cozinha, espera forçada contínua ≤ 120 s e ociosidade ≤ 25% da primeira sessão. Não contar cuidar sem necessidade ou fechar dez modais como atividade útil. Se agenda de 10 min cortar um timer, isso é ausência voluntária, não espera forçada.
- Primeiro aperto de armazenamento deve ocorrer por acumular/reservar, sem exigir fracassar na coleta. No roteiro típico, coletar a rodada planejada e conservar reserva da próxima ação. Rodada de todos os canteiros no máximo não é garantia universal, mas precisa ter estratégia comunicada.
- Resolver um bloqueio comum com no máximo duas ações econômicas além de navegação. Sessão referência: meta ≤ 20% do tempo em venda/reorganização apenas para liberar saída; acima disso rever lote/capacidade, não culpar jogador.
- Depois de Vila, idealmente ≥ 60% da renda recorrente vem de vendas/pedidos; separar moedas de prêmios únicos. Não cortar prêmio afetivo só para cumprir percentual.
- Entre melhorias do mesmo ato, pelo menos duas alternativas desejáveis, sem poder comprar todas de imediato e sem precisar fazer mais de cinco pedidos idênticos consecutivos para a única compra obrigatória. Projetos podem exigir várias entregas diferentes.
- Ao menos uma receita curta útil e uma preparação para ausência em cada ato produtivo. Uma preparação deve caber na fila e gerar quantidade útil recolhível; nenhuma exigência de cobrir 6 h em todas as máquinas.
- Fim 9 alvo 3–6 h ativas; festa mais 2–4 h. Se conteúdo interessante concluir antes, não criar calendário/grind para bater faixa; registrar recomendação. Não declarar a janela atingida sem executar perfis.

## F. Seis experimentos, vinculados às etapas

1. Linha base/modelo:00–01, fidelidade 20 ações. 2. Aperto de espaço:05–08, retorno/reserva/ampliação. 3. Renda:09, comparar regra atual/R1 mantendo resto fixo. 4. Preparar saída:10–12, receita curta/longo cultivo/filas com agenda. 5. Retorno/vínculo:03–04 e16, offline e gesto útil. 6. Projeto Tiro:20–22, contribuição com consequência visível. Ao final 23 comparar conjunto, não somar ganhos isolados como previsão final.

## G. Procedimento quando falha

Primeiro reproduzir com semente/estado/ações. Separar bug real, política defeituosa do simulador e valor inadequado. Corrigir bugs/ciclos antes de calibrar. Ordem de ajustes: origem/requisito → quantidade de objetivo → capacidade/lote → fila → prêmio/preço → tempo. Alterar uma família por rodada, máximo 3 rodadas por etapa.

Dentro da autorização do plano, capacidades/custos/prêmios/tempos podem variar até 25% do R1 por rodada, arredondando capacidade para múltiplo 4 e moedas para 5 (preços unitários inteiros podem variar 1). Não reduzir capacidade comprada legada nem alongar trabalhos iniciados. Não aumentar duração inicial da cenoura/primeiro petisco para segurar campanha. Alteração maior requer explicação técnica no DECISOES e deve continuar no escopo; não pedir permissão para correção necessária de bloqueio, mas não inventar mecânica nova para esconder falha.

Registrar antes/depois, hipótese, perfis, resultados e efeito colateral. Rodar novamente cenário falho e referência curta. Em 3 rodadas sem resultado: etapa permanece em andamento, relatório com causa, não avançar. Não aumentar budget/duração de teste até ele passar sem explicar por quê.

## H. Verificação manual e final

Três resoluções, Android/iPhone se disponível ao Vitor, timers reais do navegador e retorno após pausa. Roteiros: dinheiro 0; estoque cheio; nível durante coleta no limite; contrato consome e premia mesma categoria; compra de animal durante lote; bagagem pronta antes de fechar app; relógio retrocede; 48 h fora; save final antigo; importar e alternar slots; entregar projeto por partes; duplo toque. Testes de produção verificam cheats desligados. Falta de aparelho deve ser registrada, não substituída por alegação de teste real.
