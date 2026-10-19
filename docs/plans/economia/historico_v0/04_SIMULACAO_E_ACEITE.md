> **RASCUNHO PAUSADO — 16/10/2026, por pedido do Vitor. Não executar.** Números, produtos e critérios abaixo não estão aprovados. Conteúdo preliminar preservado para revisão após o estudo [Economia e ritmo do Tiro](../../../reports/Economia%20e%20ritmo%20do%20Tiro.md). Consulte o [estado do planejamento](README.md).

# Medir o ritmo sem confundir possibilidade com diversão

## 1. Dois instrumentos, propósitos diferentes

**Auditoria estática** lê os JSON e calcula dependências, valor de receitas, taxas, maiores lotes, espaço necessário e fontes de prêmios. Pode ser Python; não replica regras dinâmicas. Saídas `build/economy/<revisao>/audit.json` e `.md`; resumo relevante versionado em `DECISOES.md`.

**Simulação dinâmica** usa GameState real em SceneTree headless, `unlimited_storage=false`, sem dar moedas/itens/compras nem forçar `ready_at`. Relógio de simulação pode avançar por hook de teste isolado; não altera relógio do Windows e não distribui ferramenta na produção. `dev_advance_time` só é adequado se reproduzir timestamps, sono, janelas e recargas — provar isso antes de usá-lo. Remover SaveManager antes de reset/mutações, como os testes atuais.

O teste de campanha antigo continua útil para alcance de conteúdo, identificado como tal. Não apresentar seu número de ciclos como minutos de jogabilidade.

## 2. Perfis fixos

| Perfil | Sessões | Política |
|---|---|---|
| Referência | 20 min iniciais; depois 3×10 min/dia, 08h/14h/20h locais | Segue história, reserva ingredientes de uma meta, atende Tiro, vende excedente |
| Leve | 1×10 min/dia às 19h, primeira de 20 min | Escolhe lotes longos, não perde itens pela ausência |
| Ativo | até 2 h/dia em bloco | Otimiza dinheiro sem conhecer sorteios futuros; pausa para cuidados |
| Comercial | mesmo calendário da referência | Prioriza encomendas e uma melhoria produtiva antes da história |
| Explorador | mesmo calendário da referência | Prioriza Natureza e passeios; mantém renda básica |
| Desorganizado recuperável | referência, com uma venda indevida e uma compra opcional cedo | Precisa recuperar recursos sem reset ou concessão invisível |

Ação custa 3 s como ponto de partida; trocar de mundo/painel custa 2 s adicionais; gestos em grupo somam 1 s por alvo após primeiro. Calibrar por toque manual, registrar parâmetros. Fora da sessão não clicar, recolher, replantar, alimentar, vender nem receber prêmio; timers continuam, filas finitas não se renovam sozinhas.

Política deve reservar SOMENTE insumos de uma meta selecionada e cuidado próximo, com limite por depósito. Não bloquear todo o inventário para todos os objetivos futuros nem vender a última matéria-prima de uma entrega atual por uma diária. Registrar a decisão para distinguir defeito de economia de defeito do agente.

## 3. Aleatoriedade

Rodar no mínimo sementes 1–10 para referência/leve; ativo e extremos com 3 sementes. Reportar mediana, mínimo/máximo e cada cenário travado. Com dez amostras, não vender percentil 95 como estimativa robusta. Cenários de pior garantia desligam chance aleatória e preservam pity. Evento obrigatório não pode depender de sucesso aleatório. Estado de sorteio não muda ao falhar por estoque.

## 4. Log mínimo por ação

Tempo ativo e calendário; marco da história; ação/contexto; saldo antes/depois; fonte/sumidouro; inventário por categoria/capacidade; insumos reservados; filas usadas; próxima ação escolhida; motivo de espera; recompensa manual/automática; semente. Produzir relatório de 1ª sessão, dia 1, dia 3, dia 7, dia 14 e conclusão.

Métricas: primeira colheita/venda/silo/cozinha/passeio/bancada; moedas ganhas por fonte; gastos por destino; saldo ao comprar; tempo para financiar próxima compra por pedidos disponíveis; ocupação de estoque e bloqueios resolvidos; tempo ocioso dentro da sessão; porcentagem da sessão em cuidado, produção, navegação e recebimento; variedade de receitas; frequência de colher cenoura para financiar todo o resto; uso das ampliações antes de concluir campanha; tempo de fila coberto ao sair.

## 5. Critérios de segurança obrigatórios

- Zero bloqueio permanente em todos os perfis. Timeout reporta estado/causa, nunca PASS.
- Todos os novos produtos e construções alcançáveis por ações reais, sem usar compras/níveis futuros para financiar o próprio acesso.
- Um lote indivisível cabe no depósito disponível no momento de liberar a fonte. Entrada mista valida todos os depósitos.
- Toda entrega obrigatória cabe com a capacidade alcançável ANTES dela, ou usa contribuição parcial explícita. Ingredientes de uma ampliação cabem no estoque anterior.
- Zero perda, duplicação, estoque negativo, saldo negativo ou retomada inválida de save.
- Ração emergencial garante cuidado quando não há alimento. Venda e plantio básico permitem recuperar moeda zero.
- Etapa que introduz limite não deixa personagem/atalho de venda atrás desse limite.
- Receita comercial: valor da saída pelo menos 20% acima dos ingredientes imediatos; auditar margem acumulada e por minuto de estação. Produtos novos têm pelo menos dois destinos previstos, sendo um recorrente.
- Pedido comercial: prêmio em moedas >= 1,15× venda avulsa dos produtos; materiais especiais são bônus separado. Repetível não permite compra e revenda imediata lucrativa de insumo vendido em loja.
- Produção/XP de cuidado não progride por milhares de toques em segundos. Fazer carinho continua respondendo.

## 6. Metas de conforto — investigar desvios, não travar artificialmente

- Primeira colheita ≤4 min; desejo ≤7; achado ≤10; primeiro passeio ≤60 min ativos.
- Até cozinha operante, nenhuma espera forçada contínua >120 s se não existe outra ação útil apresentada; meta de ociosidade ≤20% da primeira sessão. Receber vinte avisos não conta como atividade útil.
- Primeira limitação de cesto em 8–15 min se acumular; pode nunca ocorrer para quem vende bem. Tutorial não exige encher completamente nem perder uma coleta.
- Aperto normal resolvido em até duas ações econômicas (vender/cozinhar/entregar/ampliar), além da navegação. Não exigir esvaziar três categorias para continuar.
- Ocupação típica dos estoques: 40–80% no perfil referência; picos de 90–100% pontuais. Abaixo de 20% durante todo um ato indica ampliação sem utilidade.
- Em 60% ou mais dos marcos de investimento, comprar uma melhoria relevante deve exigir escolher entre alternativas; não ter dinheiro para todas nem ficar sem qualquer opção útil. Medir com cesta de alternativas realmente liberadas.
- Premiações de missão/capítulo devolvem no máximo 25% do custo em moedas da construção que acabaram de pedir, combinadas; exceção somente tutorial explicitamente anotada.
- Meta de fontes após abrir a Vila: maioria da renda recorrente vem de vender/entregar. Comparar jogo ativo e leve; presentes não sustentam sozinhos todas as compras.
- No perfil ativo, repetir apenas cenoura não deve financiar e resolver toda a progressão sem acessar cadeias. Não reduzir prazer da cenoura por limite diário; usar demanda de materiais/produtos e retorno das cadeias.
- Cada estação principal nova é usada em pelo menos três receitas/pedidos ou metas diferentes antes do encerramento dos capítulos 1–9, quando houver catálogo suficiente. Não impor três repetições idênticas só para satisfazer métrica.

## 7. Casos manuais e adversariais

Gastar todo dinheiro no sofá; vender toda colheita; encher cesto antes do silo; todos os depósitos cheios; falhar coleta com raro; receber nível ao colher no limite; contrato consome e entrega na mesma categoria; material de ampliação enche armazém; comprar animal durante produção; comprar fila durante receita; ficar 48 h fora; relógio retroceder; duplo toque em entrega; sair no meio do projeto; mudar slot e reimportar; save antigo com tudo concluído; campanha nova com pior sorte possível.

## 8. Ajustar sem mascarar

Ordem: erro/ciclo → política do simulador → requisito/ordem → quantidade/rendimento → margem → capacidade → tempo → preço. Não começar multiplicando dinheiro. Mudar uma família de parâmetros por rodada e comparar mesma semente/perfil. Se o jogo estiver muito curto, primeiro acrescentar decisões e usos, não fazer o jogador repetir o mesmo objetivo.

Resumo em `DECISOES.md`: revisão, etapa, hipótese, alteração, cenários, números antes/depois, conclusão e risco. Critério duro que falha impede concluir etapa. Janela de duração que falha exige ajuste ou decisão explícita documentada; não é justificativa para inventar aprovação de Vitor.
