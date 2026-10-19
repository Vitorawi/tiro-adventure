# Etapa 15 — Dar variedade ao comércio e sentido à banca

**Estado: concluída (18/10/2026, Claude Code; local, sem commit nem publicação).** Evidência em `build/economy/etapa_15/` (suite/, *_depois, capturas em `build/screenshots/etapa15_antes|depois`); registro em `DECISOES.md`; sistemas em `docs/PROGRESSION.md` ("Economia R1 — etapa 15"). Executar somente esta etapa. Pré-requisito: Etapas 00–14 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 banca; 03 merchant; 07 seção B; MarketUi, order_error/deliver_order, ProgressionState requirements.

## Entrega e implementação

1. Atribuir três clientes às encomendas existentes conforme07; confiança derivada dos contadores, patamares3/8/18 com variedade1/2/2, recibos únicos de 10/20/30 moedas e bolt no segundo. Usar selo diferente de vínculo do Tiro.
2. Aplicar banca 2/3 custos900/1500 e materiais da 02. Requisitos6 contratos/2 tipos e15 / 3 tipos, respectivamente. `distinct_orders` valida somente canalcontracts; consulta não incrementa. Atualizar merchant_contracts para6 e merchant_clients para15; rótulos/falas e ajuda coerentes.
3. Reaproveitar cooldowns/quantidades/recompensas dos pedidos antigos salvo alterações explícitas09. Não introduzir economia de preço dinâmico, redução paga de espera ou expiração.
4. Provar caminho de tipos de contratos antes da banca seguinte: banca1 tem building_order, special_order e banquet_contract; banca 2 libera fabric_order. Mover requisito owned:stall_2 de banquet_contract para stall, preservando dairy/blender, ingredientes, recompensa e recarga. Assim variedade não exige estufa/pomar/caixas antes da banca 2. Não exigir festival_contract para comprar a banca que o abre. Bolt e iron_band continuam renováveis por contratos acessíveis.
5. UI de cliente no detalhe e resumo, feedback de patamar leve, sem outra aba. Preservar posse antiga de bancas e não retirar acesso se contagem atual não satisfaz o novo requisito. História usa progresso já realizado.

## Verificação obrigatória

Clientes com histórico antigo, primeira entrega/nona/reload/patamar já pago; encomenda não conta como contrato; contratos repetidos não somam diversidade. Comprar banca 2 com5/6 e 1/2 tipos, banca 3 com14/15 e2/3 tipos. Simular receita de recuperação e renda por atenção versus venda direta. Capturas com cliente sem patamar e no último.

## Critérios de conclusão

Comércio tem escolhas de produtos e clientes; bancas não se completam em duas entregas repetidas. Nenhum multiplicador de confiança alimenta inflação. Itens para expansões têm fonte determinística acessível.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_15/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
