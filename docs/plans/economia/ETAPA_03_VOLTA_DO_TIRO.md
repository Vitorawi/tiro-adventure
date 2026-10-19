# Etapa 03 — Separar retorno do passeio e bagagem

**Estado: concluída em 17/10/2026 (Claude Code; local, sem push).** Evidência em `build/economy/etapa_03/` e em `docs/PROGRESSION.md` ("Economia R1 — etapa 03"). Executar somente esta etapa. Pré-requisito: Etapas 00–02 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

05_SAVES_E_TRANSACOES D; 06_INTERFACE_E_ARTE; WalkState, GameState.*walk*, AwayView, WalkResult, WelcomeBack, indicadores e diário.

## Entrega e implementação

1. Separar `current` (viagem) e `pending_return` (uma bagagem). Implementar liquidação idempotente quando ready_at é alcançado, no update e ao restaurar save. `walking()` descreve ausência real; não basta trocar a condição sem processar resultado e limpar o estado.
2. Sortear e congelar resultado uma vez; gravar recibo e histórico/pity/postal de forma consistente. Aplicar moedas/XP/afeto de retorno uma vez, sem depender de espaço. Contadores de itens só quando itens entram no inventário; separar contador de passeio concluído de “guardar itens”.
3. Voltar o cachorro ao mundo/Cantinho, restaurar cuidados e visitantes permitidos. Guardar bagagem por parcelas que caibam, preservando resto, com IDs e flags da 05. Apenas uma bagagem pendente; impedir outro passeio com mensagem e destino ao baú. Não limitar cuidados, horta, projetos ou trocas de mundo.
4. Preservar APIs antigas como wrappers quando houver consumidores; atualizar manual, TaskHelp, “Terminar passeio”, cartão de resultado, diário, contador de prontos e welcome. Um resultado visual por viagem; reabrir resumo não premia.
5. Migrar save legado com viagem em andamento/pronta sem segundo sorteio, respeitando snapshot. A futura proteção offline da 04 deve aplicar eventos no instante correto do retorno, não na hora em que o usuário abre o cartão.

## Verificação obrigatória

Testar relógio antes/no/depois de ready_at; save+reload em cada transição; inventário cheio em todos os depósitos; receber parte/repetir; trocar mundo/aba; Tiro dormir/acordar após retorno; tentativa de novo passeio; raro garantido/pity. UI Tiro deixa AwayView no fim mesmo com bagagem impossível de guardar.

## Critérios de conclusão

Voltar e cuidar nunca dependem da bagagem; resultados e contadores são únicos; nenhuma coleta perde itens. Este comportamento deve estar pronto antes de ativar categoria trail no baú.

## Fora desta etapa

Não aumentar limite do baú para ocultar o problema, alterar chances dos passeios, tempos de viagem ou inserir recompensas para convencer o teste.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_03/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
