> **RASCUNHO PAUSADO — 16/10/2026, por pedido do Vitor. Não executar.** Números, produtos e critérios abaixo não estão aprovados. Conteúdo preliminar preservado para revisão após o estudo [Economia e ritmo do Tiro](../../../reports/Economia%20e%20ritmo%20do%20Tiro.md). Consulte o [estado do planejamento](README.md).

# Saves, capacidade e transações

## 1. Contrato de compatibilidade

Base observada: SaveManager versão 12; `_migrate` descarta versões anteriores a 12 por uma decisão histórica. **Não aumentar essa condição para apagar v12.** Criar ramo sequencial para v12 e novos campos. Não escolher um número de versão aqui: usar o próximo livre na execução, pois outros agentes podem ter criado uma versão antes.

Separar versão de formato (`save_version`) de revisão de conteúdo (`economy_revision`, proposta). Cada etapa que precisa reinterpretar dados tem migração idempotente própria e fixture anterior. `reset`, `to_dict` e `from_dict` cobrem todos os campos. Importação/exportação e os cinco slots usam a mesma migração. Não mudar separação prod/dev.

## 2. Estoque finito e excesso legado

- `storage_capacity` usa capacidade provisória antes da construção e capacidade construída depois; níveis são capacidades totais na tabela, convertidas em incrementos somente ao gravar nos dados existentes.
- Ativação da regra não depende de descobrir a UI. A categoria existe finita desde a primeira unidade. O painel aparece quando há item, aquisição ou tutorial correspondente.
- Para save existente, preservar contagem integral. Acima do limite: mostrar `58/24`, bloquear apenas novas entradas da categoria; consumo, venda, entrega e ampliação continuam possíveis. Não vender/apagar itens automaticamente.
- Se depósito já comprado tinha capacidade maior que a candidata, preservar piso legado igual à capacidade anterior adquirida, NÃO ao estoque acumulado. Ex.: geladeira antiga 30, nova 20: capacidade efetiva `max(capacidade_nova, piso_legado=30)`. Ampliações futuras recalculam sobre a curva nova; sem somar piso repetidamente.
- Material que muda de categoria (passeio → baú) pode causar excesso; aplicar a mesma regra. Se o jogo não dava acesso à venda desses itens, disponibilizar o acesso junto da migração/etapa, sem cobrar nova construção só para esvaziar.
- Guardar somente revisão aplicada e pisos necessários, não cópia inteira do inventário. Cálculo/migração deve funcionar com campo ausente e não recalcular piso a partir do inventário em toda abertura.

## 3. Recebimentos: quatro caminhos distintos

| Origem | Se não couber | Momento de pagar/contar |
|---|---|---|
| Colheita, estação, Natureza, passeio, visita | Continua pronto na origem; lote indivisível | Somente após entrega efetiva |
| Missão, encomenda, rotina, compra com item de presente | Validar inventário projetado depois de consumir entradas; bloquear integralmente se ainda não couber | Transação única; não consumir nem marcar antes da validação |
| Recompensa automática de nível/capítulo/vínculo | Moedas/XP/desbloqueios uma vez; itens que não couberem viram recibo pendente persistente | Evento automático já reconhecido; resgate só entrega itens |
| Projeto com contribuições parciais | Recebe apenas o que o jogador confirmou, até o necessário | Consome e incrementa contribuição na mesma transação |

Não aplicar `storage_error` ao inventário anterior a uma entrega que abre espaço. Validar todo o delta por categoria, incluindo produtos mistos e presente de animal/compra, antes de mutar. Não permitir entrada parcial de um lote animal. `Pegar tudo` processa lotes individualmente e deixa os que não cabem, sem perder o estado nem multiplicar eventos.

## 4. Recibos automáticos, não depósito alternativo

Proposta: estado `pending_rewards`, entries com `id` estável (`level:8`, `chapter:6`, `bond:4`), `items` fixados e `claimed`. Pode remover recibo resgatado se a origem já preserva a marca de pagamento. Não sortear de novo; recibo não expira. Não colocar produtos fabricados, passeios ou recompensas recorrentes manuais aqui.

Usar helper de recompensa com contexto explícito (manual validado / automático identificado), não trocar cegamente `_apply_rewards` para enviar qualquer falha a uma caixa infinita. Auditoria de todos os `inventory.add` e `_apply_rewards` deve distinguir migração/teste/inicialização de entrada econômica real.

Mochila ganha uma linha discreta `Presentes para guardar (N)`; abre lista com ícone, quantidade e Pegar/Ir ao depósito. Sem nova aba, sem `Novo!` infinito. Resgate cabe integralmente ou permanece pendente. Primeira implementação já inclui acesso à UI; não deixar recibos invisíveis até etapa futura.

## 5. Missões antigas e novos marcos

`chapter_index` atualmente deriva da primeira missão principal não recebida. Inserir missão num capítulo passado pode retroceder o mundo inteiro. Antes de reordenar, capturar capítulo/linhas concluídos com a lista ANTIGA versionada; não calcular isso usando somente a nova lista.

- Conservar `claimed_quests` e prêmios já recebidos.
- Missões de tutorial inseridas antes de marco já concluído são marcadas compatíveis, sem pagar novamente. Construções que a pessoa já possui continuam satisfazendo seus objetivos.
- Se inserir missão antes do passo ativo, rebasear `steps[line].base` de modo explícito; não herdar a base de outro objetivo `fresh`.
- Novos projetos e novas histórias opcionais permanecem jogáveis; não autoentregar suas recompensas como compensação genérica.
- Capítulos novos 10–12 entram só com conteúdo completo na Etapa 20. Save que concluiu 1–9 começa o 10. IDs históricos `main_9_*` continuam sendo a linha de animais, não renumerar por aparência do ID.
- `shared_with` é referência à única entrega canônica. Migração fecha aliases uma vez; moedas/XP/itens não se repetem.

## 6. Timers, rendimentos, Natureza e progressões

Receitas, plantações, passeios e buscas iniciados guardam snapshot de tempo e rendimento relevante. Ao alterar valores, trabalho já iniciado mantém `ready_at`, entradas gastas e saída contratada. Entradas antigas sem snapshot são resolvidas UMA vez por tabela de compatibilidade da revisão anterior, não pelo conteúdo atual a cada carregamento.

Não aplicar multiplicador de estufa/maestria duas vezes ao carregar. Novo preço vale para venda futura, sem compensação retroativa. Ordem com recarga iniciada mantém timestamp. Animais adquiridos não alteram lote já alimentado.

Natureza: converter a partir de nível/vagas anteriormente alcançados; preservar no mínimo ambos. Não deixar a migração antiga `nature_levels_version=2` rodar outra vez; introduzir revisão própria, sem reutilizar marcador com outro significado. XP antigo continua registrado ou mapeado monotonamente à nova escala. Ter vaga 3 não pode virar vaga 2 após abrir o jogo.

Vínculo e atributos: não reduzir nível conquistado. Se houver nova curva, mapear piso de XP/afeto ao mesmo nível e preservar presentes já recebidos. Este plano mantém a curva de afeto e modifica principalmente sua obtenção.

## 7. Fixtures obrigatórias

Novo; começo sem depósitos; geladeira comprada; cada depósito acima do limite; todos os depósitos antigos no máximo; capítulo 3 ativo; capítulo 7 ativo com `shared_with`; campanha 1–9 concluída; lote animal em preparo; receita pronta; passeio com raro fixado; Natureza nível 3/vaga 3; recibo pendente; importação/exportação; troca de slot prod/dev.

Executar ida e volta serializada e migração duas vezes. Comparar invariantes: mesmas posses/quantidades/moedas antes de ações novas, nenhum pagamento repetido, próximo objetivo alcançável, coleção equipada preservada, timer não alongado e ausência não processada como visita em troca de slot. Fixtures são sintéticas, sem dados do jogador.
