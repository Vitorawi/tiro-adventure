# Etapa 24 — Validar entrega completa e preparar o teste do Vitor

**Estado: concluída com ressalvas (19/10/2026; ver README e RESULTADOS).** Executar somente esta etapa. Pré-requisito: Etapas 00–23 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

README/checklist;01/04/05/06;DECISOES/RESULTADOS;docs/PROGRESSION, GAME_DESIGN, ROADMAP, WORLDS e planos deinterface.

## Entrega e implementação

1. Executar testes completos pertinentes no estado final, auditor de conteúdo/requisitos/recompensas, migrações de saves e amostra fixa da economia. Registrar comandos, versão do executável e resultados. Nenhuma falha aberta de conservação, save ou bloqueio permanente é aceitável.
2. Executar tour visual e toque nas três resoluções, incluindo telas novas; abrir as capturas e corrigir cortes/hierarquia/alvos. Conferir Menos animação, vibração, modais, navegação, mochila, visitantes, filas, estufa e retorno do Tiro. Preservar o layout aprovado.
3. Exportar Web prod/dev apenas localmente para smoke test, quando ferramentas estiverem disponíveis. Conferir separação de saves, reload no IndexedDB, background/foreground e atualização offline. Não apagar dados do usuário: usar perfil/slot de teste. Se aparelho físico não estiver disponível, registrar a limitação.
4. Atualizar documentação de progressão, capacidades, produtos, projetos, ausência, serialização e comandos de teste. ROADMAP deve registrar feito, pendente e próximo passo. Se o mapa do projeto mudou, sincronizar AGENTS/CLAUDE mantendo-os iguais. Marcar no README somente etapas realmente concluídas.
5. Entregar mudanças, evidências e riscos residuais. Roteiro de celular: novo jogo por 20 min; salvar/voltar após 24 h; depósito cheio com passeio; fila de produção; projeto parcial; save antigo. Preparar commit somente conforme autorização da tarefa de execução. Push/deploy exigem pedido explícito.

## Verificação obrigatória

Checklist da seção 05 completo; etapas com evidência; simulação final reprodutível; nenhuma referência/ID inválido; `git diff --check`; somente alterações esperadas. Export não substitui gameplay e teste estático não substitui toque. Registrar falhas preexistentes separadamente, sem apagá-las.

## Critérios de conclusão

Entrega local jogável, documentada e revisável, sem reset, perda, arte provisória ou requisito futuro. Resposta final enumera testes efetivamente realizados e o que falta conferir no celular. Sem publicação automática.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_24/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
