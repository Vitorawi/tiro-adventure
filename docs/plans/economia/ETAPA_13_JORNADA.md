# Etapa 13 — Consolidar capítulos 1–9 sem tarefas repetidas

**Estado: concluída (18/10/2026, Claude Code; local, sem commit nem publicação).** Evidência em `build/economy/etapa_13/`; registro em `DECISOES.md`; sistemas em `docs/PROGRESSION.md` ("Economia R1 — etapa 13"). Executar somente esta etapa. Pré-requisito: Etapas 00–12 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

03 integral A–D; 08_MATRIZ_QUESTS; 05 migração; tasks_screen, TaskHelp e shared_with; quests/npcs/progression.

## Entrega e implementação

1. Aplicar deltas da matriz para história 1–9. main_5_pickaxe aponta para guide_open_cave e stone_path para guide_stone por shared_with; principal orienta e secundária recebe uma vez. Preservar aliases já existentes, inclusive Laís/Bloblo e Feirante.
2. Trocar cozinhar 5 genérico por produce:carrot_snack 2, vegetable_soup 1, strawberry_juice 1 históricos. Criar merchant_variety na linha merchant 45 com order:vegetables 1 e order:snacks 1, prêmio 10; main_6_commerce vira alias. Não pedir entregar de novo os itens já consumidos nessas encomendas.
3. main_7_greenhouse exige estufa+harvest:herbs 1; remover Horta 5 como requisito adicional das ervas se ainda estiver, mantendo exclusividade de estufa. main_8_building conta6 tábuas históricas sem fresh. atelier_open exige ateliê+fabric 2+accessory_set 1, coerente com o final aprendido.
4. Revisar textos, nomes, Ir, ajuda, falas de capítulo e marcadores de NPC para todas as missões movidas nas 05–10. Uma missão mostra um verbo/objetivo claro; evitar “construa três prédios” sem passos. Linhas opcionais podem continuar em paralelo, sem bloquear principal.
5. Migrar snapshot das bases fresh só quando realmente muda objetivo de missão ativa; preservar concluídas, recompensas pagas e primeiras ações. Sincronização de alias nunca premia duas vezes, e missão recebida antes da migração não fica ativa novamente.
6. Atualizar PROGRESSION e rodada completa de regressão. Gate de jornada: percorrer até atelier_open sem dar itens ou marcar owned, preservando estoque finito.

## Verificação obrigatória

Auditoria de grafo incluindo ordens, requisitos e receitas; save novo, no meio dos capítulos 3/5/7/9 e antigo campanha completa. Não assumir quantidade: contar todos os pares shared_with reais e validar cada um. Primeiro capítulo, tutoriais de storage, ajuda e aliases via viewport. Suíte completa e perfil referência com ledger de repetição/fresh.

## Critérios de conclusão

Capítulos 1–9 têm passos ensináveis e nenhum custo/entrega duplicado nos cruzamentos. Campanha completa por ações legais; falha de ritmo fica quantificada para 23, bloqueio lógico precisa ser resolvido agora.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_13/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
