# Etapa 19 — Criar contribuições persistentes sem nova economia paralela

**Estado: concluída em 18/10/2026 (Claude Code; local, sem push).** Evidências em `build/economy/etapa_19/RELATORIO.md`. Executar somente esta etapa. Pré-requisito: Etapas 00–18 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

07 seções D/E; 05 recibos/migração; Database, GameState, ProgressionState goals/requirements e TaskHelp.

## Entrega e implementação

1. Criar esquema `projects.json`, `ProjectState` e integração com Database, save e reset. Nesta etapa o catálogo de produção fica vazio; usar projeto de teste em fixtures, sem mostrar prédio vazio no jogo. Não inserir capítulos 10–12 antes de haver resultados jogáveis.
2. Implementar as APIs e regras da seção 07D: começar com taxa única, contribuir por item/quantidade, persistir fases e concluir/premiar uma vez. Validação de erro não consome nem avança; material aceito não reaparece no inventário após reload.
3. Objetivo de projeto, requisito de projeto anterior e destino específico entram no avaliador comum e no TaskHelp. Consultar estágio, restante e progresso não faz mutações. Definir eventos de fase, conclusão e uso uma vez, que a interface futura observará.
4. Última entrega e conclusão devem ser indivisíveis ou recuperáveis por flag idempotente. Se o prêmio não couber, usar recibo; nunca bloquear uma obra já concluída. A taxa existe apenas ao começar, sem cobrança por fase.
5. Documentar esquema final com exemplo de teste e serialização. Testar save vazio/antigo como estado sem projetos. Preservar IDs de projeto/fase e prever versão de esquema sem apagar contribuições.

## Verificação obrigatória

Projeto de teste com três fases: começar duas vezes, iniciar sem moedas, contribuir quantidade zero/negativa/fracionária/excessiva, entregar parcialmente e salvar em cada passo. Testar última entrega repetida, prêmio com estoque cheio, requisito cíclico, referência ausente e conclusão já recebida. Objetivos reconhecem conclusão uma vez. Simular interrupção nas fronteiras de persistência.

## Critérios de conclusão

Motor transacional e esquema documentados/testados; nenhum projeto incompleto aparece para jogador; interface das próximas etapas tem contrato estável. Não criar moeda ou inventário independente de contribuição.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_19/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
