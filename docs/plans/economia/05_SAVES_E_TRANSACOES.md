# Contratos de estado, transação e migração

APIs/estruturas aqui são **propostas para implementação nas etapas indicadas**, não existentes. O executor pode ajustar nomes internos mantendo a responsabilidade e os testes. Números de SAVE_VERSION são escolhidos na execução usando próximo livre; não reutilizar versão de outra tarefa.

## A. Migração sem reset

SaveManager atual v12 possui ramo `<12` que apaga progresso por acordo antigo. NÃO ampliá-lo para apagar v12; manter tratamento histórico e adicionar ramos idempotentes para novas revisões. Separar `save_version` (formato) de `economy_revision` (conteúdo) e revisões próprias de missões/depósitos. Sempre reset/to_dict/from_dict com defaults.

Capturar na 02 mapa versionado antigo de capítulos/linhas/requisitos e tabelas usadas em trabalhos. Antes de inserir missão, determinar capítulo concluído com mapa ANTIGO. Tutoriais novos anteriores ao marco conquistado são reconhecidos sem prêmio; objetivos atuais não herdam base `fresh` de outra missão. Não autoexecutar projetos novos. Atualizar `steps`, `claimed_quests`, aliases e seen uma vez, mantendo todos os IDs.

Relatórios de slot usam migração pura sem pagar, alterar timestamps ou gerar visita. Importação/exportação e cinco slots passam pelo mesmo caminho. Novos campos não são compartilhados entre slots; preferências do aparelho e controle de ausência já compartilhados permanecem com sua função.

## B. Capacidade e recebimentos (02,05–08)

Capacidade = `max(curva_nova_do_estagio, piso_legado_comprado)`. Piso é capacidade anterior comprada, não estoque acumulado. Excesso legado permanece, bloqueando só novas entradas daquela categoria; consumir/vender/entregar/ampliar funciona. Não recalcular piso repetidamente após carregar.

Cada categoria migra na sua etapa; infraestrutura 02 não ativa todos os limites. Campo de dados `prebuild_capacity` ativa categoria finita sem edifício; ausência do campo preserva regra antiga até sua etapa. Depois 08 nenhuma categoria dos quatro depósitos permanece ilimitada antes de construir.

Transação deve validar inventário PROJETADO depois de consumir ingredientes/entregas antes de aplicar saídas; somar por depósito. Manual com erro não consome, não conta, não altera RNG ou cooldown. Uma ação bem-sucedida conta e paga uma vez; evento visual vem depois. `Pegar tudo` recebe lotes independentes, deixa lotes inteiros que não cabem e informa motivo, sem parcial escondido.

| Origem | Quando não cabe |
| --- | --- |
| Horta, estação, Natureza, visita | permanece pronta na origem; lote indivisível |
| Missão/pedido/rotina manual | transação bloqueada antes de consumir; Ir ao depósito/venda |
| Nível/capítulo/vínculo/cliente automático | moedas/desbloqueios pagos uma vez; somente itens ficam em recibo persistente identificado |
| Passeio | cão retorna; item da bagagem espera (contrato D) |
| Projeto | contribuições parciais explícitas; prêmio automático final conforme recibo |

`pending_rewards` guarda id estável (`level:8`, `chapter:6`, `bond:4`, `customer:lais:2`, `project:park_bench`) e snapshot dos itens pendentes. Não expira nem ressorteia. Só essas origens; nunca guardar produção comum ou todos os pedidos para criar estoque alternativo. Mochila tem linha `Presentes para guardar (N)`, com resgate da quantidade que cabe por item, saldo restante persistido no recibo e atalho ao depósito. A 02 já inclui essa UI.

Auditar todos `inventory.add`/`_apply_rewards`: diferenciar inicialização/migração/teste, recebimento manual validado e automático identificado. Não passar contexto automático genérico sem origem única. Lote animal com qty/animals é inteiro; presente de animal de compra não vira item de inventário.

## C. Snapshots de trabalho (02)

Ao iniciar receita/planta/busca/passeio guardar contrato de entradas consumidas, saídas/quantidade, tempo, XP e efeitos necessários. Não inferir produção antiga pela nova tabela na coleta. Campos mínimos por domínio em testes; não criar cópia do Database inteiro por lote. Se receita entrega coleção, guardar id de coleção.

Entradas anteriores sem snapshot recebem contrato calculado UMA vez com tabela versionada da revisão anterior. `ready_at` já existente prevalece; não alongar lote iniciado, não reaplicar rega/estufa e não recalcular número de animais. Snapshot de passeio congela tabela relevante ou resultado fixado sem incrementar pity até marco definido em D. Random seed nunca muda por falha de armazenamento.

Novo preço de venda vale para ação futura. Moedas antigas não reembolsadas. Nova curva de Natureza preserva no mínimo nível/material/vagas adquiridos; revisão própria não reativa `nature_levels_version2`. Adequar piso de XP à nova escala, mantendo posse anterior. Vínculo não rebaixa nível nem reaplica presente.

## D. Passeio: viagem e bagagem são estados diferentes (03)

`current` só significa viagem não retornada. `return_due_walk(now)` é idempotente: se ready_at≤now, computa/fixa resultado pela seed e snapshot; move para `pending_return` único; limpa current. `walking()` consulta viagem com tempo restante>0, não bagagem. Rodar transição no tick e antes de consultas/ações relevantes e após carregamento; UI não pode ser dona exclusiva do retorno.

Ao retornar, aplicar efeitos no cachorro e recompensa não inventariável (moeda/afeto/XP/coleção) uma vez, incrementar walk/history/pity uma vez e `walk_rare`/lendário conforme resultado fixado. Itens continuam no pending_return. `walk_item`/find_item só incrementam na retirada efetiva dos itens; separar stats para objetivos de voltar e de achar/receber. Guardar `returned_at`, `rewards_applied`, `result_shown`, `items_claimed` (ou representação equivalente) e resultado. Não disparar retrospectivamente dezenas de comemorações ao carregar; usar fila modal e marcar visualização persistida.

Home mostra Tiro disponível; postal/resumo tem `Guardar achados` ou `Ver bagagem`, nunca obriga ausência. Marcador da Praça e Mochila dão mesmo acesso. Falta espaço: bagagem intacta, mensagem com depósito. Só existe uma bagagem; não iniciar outro passeio até esvaziar. `cancel_walk` só durante viagem: depois de retornar não devolver energia nem descartar/prêmio duplicado. Bagagem sem itens pode ser encerrada imediatamente após marcar resultado.

Retorno ao carregar depois de48 h: aplicar efeitos do passeio no timestamp de ready_at dentro da evolução temporal do cachorro, não curar totalmente como se ele tivesse acabado agora; depois simular restante da ausência protegida. Testar ordem com sono e necessidades. Pode usar projeção segmentada de eventos; não mutar duas vezes no mesmo now.

Compatibilidade: API `collect_walk` antiga pode chamar return_due_walk e tentar receber bagagem para preservar callers, mas UI passa a distinguir. Produções, quarto, DogWorld, cuidados, cancelamento, disponibilidade de desejos, contador do Mapa e boas-vindas devem usar nova definição. Teste de estoque cheio precisa ver cão presente e nenhum ganho repetido.

## E. Ausência protegida (04)

Salvar início da ausência após `dog.commit(now)` quando perde foco/pausa; no retorno/load projetar separadamente intervalos online e offline. Deduplicar eventos foco+pause+load; fechamento abrupto usa último timestamp persistido como início estimado. Timestamp `last_applied_absence`/marca equivalente por slot impede processar intervalo novamente. Troca de slot não pode dar bônus de volta nem visita, mas necessidades daquele slot evoluem no tempo em que ele não foi jogado como offline (não abandono online).

Uma ausência contínua tem teto 8 h de queda; autosave/heartbeat/consulta não reiniciam o teto. Para barra x abaixo do piso p, fórmula sem sono: `max(min(x,p), x - taxa_online×0,5×min(horas,8))`. Isso não cura uma barra já baixa. Para sono, energia cresce até 100; não acorda e volta a cair ainda offline. Ao regressar com energia 100 pode acordar, depois taxa online normal. Demais barras com proteção. Futuros timestamps/relógio para trás: elapsed=max(0, diferença); não permitir explorar reabertura para ganhos extras.

Exemplo de teste R1:100 em todas,8 h acordado offline →68/80/76/88.24 h dá o mesmo pelo teto. Partindo 30 de barriga →25, nunca 68. Partindo 10 →10 (não curar pelo piso). Sono 0 em 8 h→100 energia, sem afetar forma das outras barras. Online continua regra antiga.

## F. Fixtures mínimas e aceitação

Criar fixtures sintéticas v12: início sem depósitos; cada depósito comprado/cheio/acima; todas ampliações; capítulos 3/7 ativos e final 9; aliases pendentes; lote animal em andamento; fogão pronto; canteiro regado; Natureza 3/vaga 3; passeio raro pronto com resultado antigo; cinco slots e import/export. Acrescentar recibos/retorno/projetos nas etapas donas.

Migrar duas vezes + serializar/recarregar. Invariantes: mesmo saldo/itens/posses imediatamente antes de nova ação (exceto efeitos temporais intencionais), nenhum prêmio duplicado, nenhuma retrocessão de mundo, nenhum lote alongado, equipamentos preservados e próximo objetivo atingível. Testes só usam fixtures, nunca save real do Vitor.


## G. Precisões após revisão cruzada

Recompensa de confiança comercial é origem automática permitida: `customer:<id>:<patamar>`. Persistir o patamar pago; no legado sem esse sistema, reconhecer histórico e emitir cada patamar ainda não pago uma vez. Testar reload após moedas e antes do bolt guardado. Maestria usa identidade análoga, embora seus prêmios atuais sejam moedas/selos.

Dividir ausência no retorno do passeio não reinicia o teto 8 h. Para segmento [a, b], usar tempo protegido consumível `max(0,min(b−absence_start,8h)−min(a−absence_start,8h))`, com limites não negativos e timestamp da mesma ausência contínua. Efeitos de retorno são aplicados entre segmentos. Na etapa 03, segmentar usando a política temporal vigente; a 04 introduz metade das taxas, pisos e teto. Testar passeio que acaba em 1 h e jogador que volta em 24 h: há 8 h de queda protegida total, não 9 h.

Exceção de cuidado por desejo/tutorial é identificada pela instância e pelo objetivo ainda incompleto, consumida uma vez. Desejo já satisfeito aguardando “Receber” não autoriza mais exceções. Carinho tem benefício normal de+3 felicidade; para seu contador útil, aceitar recuperação efetiva≥3 com guarda120 s. Isso não altera o limiar≥5 de alimentação/banho/brincadeira. Reação visual livre não implica novo contador, XP ou afeto.
