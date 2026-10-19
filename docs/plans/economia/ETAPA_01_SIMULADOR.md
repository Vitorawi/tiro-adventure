# Etapa 01 — Medir sessões usando as regras reais

**Estado: concluída (17/10/2026, Claude Code + retomada Codex).** 35 campanhas completas, 107.653 ações auditadas, zero violações; comandos, resultados e limitações em [SIMULADOR.md](SIMULADOR.md). Próxima: somente etapa 02, quando solicitada.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

04_SIMULACAO_E_ACEITE integral; BASELINE; game/autoload/game_state.gd; save_manager.gd; game/tests/progression_test.gd; DevPanel/Ritmo.

## Entrega e implementação

1. Criar relógio injetável mínimo para testes de economia. O tempo normal continua sendo o relógio real; não espalhar branches dev por todos os métodos. Mapear timestamps de produção, coleta, necessidades, rotina, visita, carinho e passeio que precisam da mesma fonte.
2. Implementar runner headless `game/tests/economy_simulation.gd` e invocador `tools/economy_simulate.ps1`, com perfil/seed/horizonte/saída configuráveis. Usar GameState e métodos públicos, requisitos e saves reais. Esperar pelo próximo evento por avanço do relógio, jamais forçar ready_at, owned, level ou saldo. Fixtures de migração são outro tipo de teste.
3. Codificar política de ações da 04: tempo de toque/navegação, uma reserva de objetivo, cuidado quando útil, produção elegível, venda do excedente, trabalhos antes de fechar. Perfil comercial não lê RNG futuro. Agenda encerra sessão mesmo que haja ações disponíveis. Não manter auto-clicker trabalhando durante ausência.
4. Ledger por ação: tempo real/ativo, saldo antes/depois, item e origem/destino, depósito usado/limite, fila, objetivo, erro e próxima opção legal. Classificar moedas únicas/recorrentes, itens produzidos/consumidos/vendidos, tempo sem progresso, avanço de história e coletável acumulado fora dos depósitos.
5. Rodar baseline sem balanceamento. Acrescentar scripts pequenos de comparação e gráficos simples ao relatório local; preservar logs completos de seed falha. Medidas teóricas do auditor e medidas simuladas não recebem o mesmo rótulo.

## Verificação obrigatória

Comparar pelo menos 20 ações do runner com execução direta do GameState e verificar conservação de moedas/itens. Testar agenda 1 ×10 min versus 3 ×10 min, reload no meio de receita, seed repetida e erro de ação. Guardas devem detectar unlimited_storage, concessão dev, ready_at forçado e alteração direta de inventário pelo planejador.

## Critérios de conclusão

Perfis e seeds da 04 executam sem atalhos; baseline reprodutível com relatório de gargalos reais. Não exigir que economia antiga passe metas R1. Falha de política do bot é distinguida de bloqueio do jogo.

## Fora desta etapa

Não reutilizar a progressão acelerada como evidência de ritmo, ajustar preços para o bot passar, criar dashboard de produto, servidor ou analytics externo.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_01/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
