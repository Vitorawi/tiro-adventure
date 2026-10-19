# Etapa 18 — Oferecer conforto de longo prazo e reconhecer experiência

**Estado: concluída em 18/10/2026 (Claude Code; local, sem commit nem publicação).** Executar somente esta etapa. Pré-requisito: Etapas 00–17 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seções A/D; 07 seção C; 05 migração; 06 medidores/slots; contadores de lotes da 16.

## Entrega e implementação

1. Criar silo/fridge/warehouse/chest `_4` e `_5` com totais, custos e requisitos da tabela 02. Manter os edifícios e ampliações existentes. Somar incrementos; o piso legado não é bônus aplicado novamente após cada reload. O último estágio não é obrigatório para terminar história ou projetos.
2. Criar `stove_queue3`, `mill_queue`, `dairy_queue` e `atelier_queue` com custos e condições da tabela 02. Não aumentar rendimento nem velocidade junto. Vagas dependem da compra e dos requisitos indicados, sem obrigar patamar de maestria.
3. Implementar maestria das seis estações pelos lotes concluídos e variedade da seção 07C. Reusar o contador de lotes da etapa 16 e ampliar por receita; cuidar da migração de histórico inexato. Patamares de 12/40/100 lotes, com diversidade limitada ao catálogo elegível e sem retroceder ao desbloquear receita nova.
4. Prêmios únicos de 10/20/30 moedas e selos, sem multiplicador de renda ou produção. Medidor dentro da estação; ajuda explica total e variedade. Recompensa usa o contrato automático da etapa 02 e identidade persistente.
5. Simular ampliação escolhida antes/depois da compra. Avaliar capacidade para retorno e reserva, inclusive lotes deixados prontos fora do depósito. Não adicionar manutenção. Rodar a verificação completa antes de começar os projetos.

## Verificação obrigatória

Cada ampliação calcula o total exato e exige a anterior. Save antigo não perde capacidade; estoque acima do limite permite consumir/vender. Lote com saída de três unidades conta como um trabalho; repetir coleta não conta. Maestria do moinho é alcançável com uma receita; desbloqueios não apagam selos. Executar perfis referência/leve com longa ausência, suíte completa e tour de vagas/medidores.

## Critérios de conclusão

Expansões são úteis e opcionais, filas dão autonomia mensurável, maestria reconhece uso sem acelerar inflação. Nenhuma regressão de save/armazenamento pendente no gate 18.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_18/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
