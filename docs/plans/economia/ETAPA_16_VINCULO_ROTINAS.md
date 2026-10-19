# Etapa 16 — Recompensar cuidado útil e tirar sorte do caminho principal

**Estado: concluída (18/10/2026).** Executar somente esta etapa. Pré-requisito: Etapas 00–15 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção G; 03 seção F; 07 seção F; wishes/routines/nina e ações de pet/play/feed/bathe.

## Entrega e implementação

1. Carinho continua animando livremente, mas recompensa+1 afeto só a cada120s no GameState, inclusive por chamada direta. Brincar+2 somente quando útil (benefício≥5) ou desejo/tutorial válido, com cooldown120s. Não manter uma recompensa paralela na UI.
2. Incrementar care_useful total e por ação somente quando há benefício≥5, ou evento de tutorial/desejo consumível uma vez. Manter contadores brutos para compatibilidade. Não permitir reaproveitar um desejo ativo já satisfeito para farmar antes de receber o prêmio.
3. Moedas de desejos e vínculo conforme02. Preservar afeto dos desejos e demais prêmios; nível de vínculo não é gasto. Requisitos de comida/desejo consideram disponibilidade real, não apenas nível geral.
4. Migrar rotinas para catálogo de nove modelos da 07, mantendo IDs equivalentes e snapshot de sorteio já ativo. Precisará de contador de lotes para rotina de produção: criar agora, não depender da maestria da etapa 18. Baseline por período; idade do save não completa rotina automaticamente. Quantidade por fase é congelada na geração.
5. Nina: mover nina_rare para linha opcional nina_discoveries10 após nina_walk; petshop depende de nina_routes, não do raro. Preservar sequência de costura/amigos/truques como conteúdo paralelo. Não mudar chances/pity nem apagar o raro de quem já recebeu.
6. Implementar wish_item:<id> no momento de entrega efetiva, preparação para17. Garantia de mirtilo só entra junto da nova missão; não gerar referência ausente.
7. Para carinho útil, limiar efetivo3 e guarda120s. Exceção por tutorial/desejo exige objetivo ainda faltante e marca por instância consumida uma vez. Não contar repetição enquanto o botão Receber está pendente.

## Verificação obrigatória

Pet/play chamado diretamente100 vezes; reload antes/depois do cooldown; fome cheia versus benefício útil; mesmo desejo atendido com prêmio pendente; cuidado tutorial uma vez. Rotina antiga ativa mantém meta/prêmio, nova sorteia só acessíveis, contagem por lote não por saída. Caminho Nina com RNG raro sempre falhando deve continuar petshop/truques.

## Critérios de conclusão

Vínculo não é completado por toque repetido; cuidados livres continuam respondendo. Rotina não exige banhos vazios nem esperar sorte para história. Duração do vínculo relatada por perfil, sem impor calendário artificial.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_16/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
