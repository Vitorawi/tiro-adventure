# Etapa 02 — Proteger saves, lotes e recompensas antes de limitar estoque

**Estado: concluída em 17/10/2026 (Claude Code).** Resultado, evidências e falhas históricas isoladas no fim deste arquivo e em [DECISOES](DECISOES.md). Pré-requisito atendido: Etapas 00–01 concluídas.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

05_SAVES_E_TRANSACOES A/B/C/F; 06_INTERFACE_E_ARTE; SaveManager, Inventory, StationState, Crop/Activity states e callbacks de recompensa.

## Entrega e implementação

1. Introduzir versão de balanceamento/migração monotônica sem reset. Congelar mapa das missões e capacidades antigas antes das mudanças de ordem. Separar migração de estrutura de save de simples mudança de preço; não incrementar versão sem necessidade comprovada.
2. Implementar função única de validação de saldo/inventário projetado após entradas/saídas. Entrega consome ingredientes e recebe prêmio atomicamente; se espaço ainda falta após consumo, não aplicar nenhum efeito. Erro é consulta pura, sem RNG, cooldown, contador ou side effect.
3. Snapshot de trabalhos ao iniciar: entradas efetivamente pagas, saídas, quantidade, duração/ready_at, regra de XP relevante. Jobs antigos mantêm rendimentos e prazo anteriores. Uma alteração de receita não muda colheita plantada ou lote em fila. Construir migração de trabalhos antigos usando dados legados congelados, não os futuros valores R1.
4. Preparar suporte de `prebuild_capacity` por depósito, porém não ativar todos agora. `legacy_capacity_floor` decorre das compras do save, nunca da quantidade estocada; estoque acima do teto não some. Permitir consumir/vender mesmo acima do limite, novas entradas obedecem saldo projetado.
5. Recompensas automáticas criam recibo persistente somente para itens que não cabem. Identidade estável por nível/capítulo/vínculo; moedas/XP/desbloqueios aplicados uma vez. UI Mochila “Presentes para guardar” entregue nesta mesma etapa. Recompensas manuais continuam transacionais, não viram banco sem limite.
6. Atualizar chamadas de todos os recebimentos para o contrato compartilhado; helpers existentes devem delegar, não manter duas checagens divergentes.

## Verificação obrigatória

Fixtures: legado com cada depósito comprado, todos ampliados, capacidade excedida, trabalho em andamento, nível recebido duas vezes, capítulo compartilhado e recompensa recebida parcialmente. Testar consumir itens do mesmo depósito para abrir espaço, prêmio misto e reload entre receber/guardar. Simular mudança de receita após iniciar e verificar saída antiga. UI de pendência e limite legado nas três resoluções.

## Critérios de conclusão

Nenhum inventário/prêmio perdido ou duplicado; jogo ainda usa limites anteriores para categorias ainda não ativadas; migração idempotente e interface de presentes utilizável. Testes de save/content/storage/rewards existentes passam ou falhas prévias estão isoladas.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_02/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.

## Resultado (17/10/2026)

Implementado (sem alterar nenhum número de balanceamento nem ativar depósito novo):

| Entrega | Onde |
|---|---|
| Revisão de economia sem reset; migração pura/idempotente; mapa de missões e capacidades antigos congelados | `EconomyState`, `EconomyMigration`, `data/legacy_r0.json` (`tools/freeze_legacy.py`), `SaveManager._migrate`, `GameState.from_dict` |
| Validação única do inventário projetado e transações atômicas | `GameState.storage_shortage/storage_error/transaction_error`; todos os recebimentos (missão, encomenda, rotinas, presente do dia, desejo, rota, achados, tesouro, loja, amigos, visitas, colheita, lote, Natureza) |
| Snapshots de trabalhos | `WorkJobs` + `plots[].job`, `queue[].job`, rota `rewards/player_xp`, `walks.current.snapshot` |
| `prebuild_capacity` e `legacy_capacity_floor` | `GameState.storage_active/curve/floor/capacity/excess`; campo ainda não usado nos JSON |
| Recibos persistentes e identidade estável | `GameState._grant_automatic` (`level:N`, `chapter:N`, `bond:N`; formato pronto para `customer:`/`project:`), `economy.pending/granted` |
| Mochila "Presentes para guardar" | `InventoryList` (`PendingGifts`, `GiftsToggle`, `StoreGifts`, `GiftsBlocked`, `Gift_<item>`); ferramenta DEV "Presente para guardar" |

Verificação:
- `economy_transactions_test` (fixtures v12: início sem depósitos, cada depósito comprado, todos ampliados, excesso legado, trabalho em andamento, nível recebido duas vezes, capítulo compartilhado, recibo parcial, consumo que libera espaço, prêmio misto, reload entre receber/guardar, troca de receita após iniciar, prebuild/piso, migração pura, cinco slots) e `pending_gifts_test` (toque real nas três resoluções): PASS.
- Simulador (`build/economy/etapa_02/simulador/`, 35 execuções com limites reais, sem concessões dev): 35/35 completas, 81/81 missões, zero violações, resultados idênticos aos da etapa 01 (`comparacao_simulador.md`); duas reexecuções (`reference_s1`, `commercial_s2`) com `ledger.jsonl` byte a byte igual ao da etapa 01.
- Capturas antes/depois em 360×780, 390×844 e 412×915 (`build/economy/etapa_02/capturas/`), conferidas uma a uma; toque real no export Web dev em Chrome mobile emulado: ferramenta DEV → Mochila → **Guardar** (`toque/web/`), com o save no IndexedDB conferido.
- Suíte: ver a seção da etapa em `docs/ROADMAP.md` (falhas históricas isoladas: `npc_lines_test`, `finds_test`, `onboarding_test` instável, `progression_test` preso em `merchant_festival`; todas reproduzidas no commit `6c01198`).

Limitações: não houve teste em aparelho físico (iPhone/Android); o teste de toque no viewport e o Chrome emulado não equivalem a isso. Nenhum depósito foi limitado de novo nem mudou de curva: isso é das etapas 05–08. O retorno do passeio continua como era (etapa 03).
