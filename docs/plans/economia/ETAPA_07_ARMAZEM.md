# Etapa 07 — Apresentar materiais e ampliações na Natureza

**Estado: concluída (17/10/2026, Claude Code).** Executar somente esta etapa. Pré-requisito: Etapas 00–06 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção A; 03 seção B/Guia e linha storage; 05/06; progression.activities/upgrades e Guide quests.

## Entrega e implementação

1. Ativar armazém provisório 16, construído 32, _2 total 56, _3 total 88. Compra 40 moedas+wood 4+stone 2 após lais_forest. A Caverna já pode ser aberta no capítulo 5; não exigir armazém para pegar a pedra necessária ao armazém.
2. Inserir guide_open_cave em 22 depois de guide_wood 20: owned:cave_open, moedas 5. Mover `bloblo_warehouse` (mesmo ID) para NPC/linha guide, ordem 25, owned:warehouse, moedas 10; guide_stone permanece 30. Exibir nome e rosto do Guia, nunca manter diálogo da vovó por descuido.
3. `main_4_materials` passa a have:wood 6 + owned:warehouse. O armazém consome madeira 4 separadamente, portanto reserva real de madeira deve cobrir construção e bancada; não duplicar entrega de seis tábuas/madeira numa missão canônica e alias.
4. Criar linha `storage` da Bloblo: storage_first_planks 10 após main_4_bench, produce:plank 2 fresh, prêmio bolt 1; storage_first_delivery 20, orders 1 fresh, bolt 1. Mover bloblo_bigger para 30 e bloblo_biggest 40 com objetivos stat storage_upgrades 1/3; prêmios15 moedas+bolt 2 e 40 moedas+bolt 1, substituindo os antigos pacotes de ferramentas ainda não pagos. Contador considera _2+ de qualquer depósito e migra da posse histórica; compra inicial não conta. Preservar recompensas já pagas. _3 agora não é “ao máximo”: revisar nome/fala.
5. Cobrir materiais wood/stone/copper/crystal/plank/brick/fiber/fabric/hardwood; tokens bolt/iron_band isentos. Guias de origem das duas primeiras peças de ampliação não podem apontar para banca que ainda não existe. Ainda há contratos para novas peças posteriormente.
6. Ajustar requisitos visuais e TaskHelp para caverna/armazém/primeira ampliação, preservando slots de coleta antigos.

## Verificação obrigatória

Percorrer capítulo 5 de save novo com moeda obtida por venda, incluindo caverna, armazém, material e bancada. Verificar sequência de Guia e dois bolts determinísticos sem sorteio. Repetir save antigo com warehouse recebido na Bloblo; não reabrir prêmio nem esconder próxima missão. Validar grafo de requisitos incluindo custos materiais, não só quests.
Testar primeiras ampliações em quatro ordens diferentes: silo primeiro, geladeira primeiro, armazém primeiro e baú primeiro; recompensa por 1/3 compras reconhece todas. Nunca exigir o próprio aro da ampliação para ganhar o primeiro aro.

## Critérios de conclusão

Armazém entra antes de acumular construção e não forma ciclo com bancada/caverna. Duas primeiras ampliações necessárias são financiáveis sem raro. Todos os IDs movidos preservam conclusão histórica.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_07/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
