# Conteúdo novo e contratos dos sistemas

As decisões abaixo são R1 para implementar, sujeitas ao protocolo de calibração. IDs novos devem ser verificados contra o catálogo antes de inserção. Valores existentes não citados permanecem iguais. Não criar novos NPCs, moedas ou mundos.

## A. Três produtos e uma receita de apoio (17)

| ID / nome | Estação | Ingredientes por lote | Saída | Tempo s | Venda/unidade | Depósito | Requisito extra |
| --- | --- | --- | ---: | ---: | ---: | --- | --- |
| braided_toy / Brinquedo trançado | workbench | fabric 1 + stick 2 | 1 | 720 | 40 | chest | atelier_open |
| picnic_pack / Cesta do encontro | stove | carrot_snack 2 + strawberry_pop 2 + strawberry_juice 1 | 1 | 1080 | 110 | chest | atelier_open |
| blueberry_treat / Petisco de mirtilo | stove | blueberry 2 + herbs 1 + carrot_snack 1 | 1 | 900 | 65 | fridge | tesouro aberto + greenhouse |
| cut_sticks / Preparar gravetos (receita; saída stick) | workbench | wood 1 | 2 | 60 | preço existente do stick | chest | bancada comprada |

Não criar um item `cut_sticks`. Mapear estações para os IDs efetivos do catálogo; `workbench` designa a bancada e sua estação de receitas, não uma segunda máquina. Receitas normais exigem a respectiva estação comprada além do requisito extra. Produção das três novidades dá XP global 8/10/10 e skill_xp 20/25/25, com skill adventure/cooking/cooking respectivamente. Na etapa 17, implementar campo opcional `player_xp` por receita, com fallback exato para `_gain_xp("cook")` das receitas antigas. Hoje collect usa o valor global fixo: só cadastrar JSON não implementa a regra. Snapshot do trabalho congela player_xp; pagar uma única fonte, nunca fallback mais override. `cut_sticks` dá XP global 1 e XP local 0 para não virar treino dominante. Caso a arquitetura não tenha XP local por receita, não criar um atributo para isso.

Margens imediatas previstas: brinquedo 40−(24+2 × 2)=12; cesta 110−(2 × 12+2 × 16+20)=34; petisco 65−(2 × 9+16+12)=19. Auditar preços reais na 00/17; não chamar estes cálculos de lucro por minuto, pois há máquinas, tempo e alternativas. `cut_sticks`: saída vende 4 contra madeira 2, limitado por trabalho60 s; avaliar junto das rotas curtas, não pode substituir toda economia.

Brinquedo é objeto de encontro/projeto/encomenda, não comida. A cesta é uma entrega social; não alimentar o Tiro com uma cesta inteira. Petisco de mirtilo: comida, fome+20 e alegria+10, sem energia/vínculo especial por alimento; afeto vem do desejo/cuidado conforme regra 16. Não incluir deterioração. Receitas e manual usam ingredientes tocáveis e destino comercial claro.

Usos obrigatórios antes de concluir 17: brinquedo = missão workshop_toy + encomenda nina_toys + projeto futuro banco; cesta = workshop_picnic + encomenda lais_picnic + projeto futuro piquenique/festa; petisco = desejo do Tiro + encomenda nina_blueberries + missão opcional pós-tesouro. Referências a projetos só entram nos dados quando seus IDs existirem; explicar uso atual no manual. Nem brinquedo nem petisco tornam-se consumo obrigatório diário.

## B. Clientes e encomendas (15; novidades 17)

Clientes são os personagens existentes Laís, Bloblo e Nina. Acrescentar `customer` às encomendas, manter canal, ID, cooldown e histórico. Mapeamento: Laís = vegetables, soup_order, juice_order; Bloblo = snacks, puree_order, farm_breakfast; Nina = fruit_basket, pop_order. Conferir nomes canônicos no catálogo da etapa 00; não renomear pedidos antigos para coincidir com um rótulo deste plano. Os contratos continuam do Feirante e não contam como encomendas desses três clientes.

Confiança comercial deriva de pedidos `order:<id>` realmente entregues. Patamares: 3 entregas/1 tipo, 8/2 tipos, 18/2 tipos por cliente. Quantidade de tipos distintos é o número de IDs desse cliente com contador>0. Reconhecer histórico antigo sem pagamentos retroativos duplicados; premiar um patamar ainda nunca pago somente uma vez, com 10/20/30 moedas, respectivamente. No segundo, um bolt extra usa o recibo automático. Um patamar deve melhorar fala/selo e indicar novos pedidos já liberados; não aumentar preço pago ou velocidade. Não bloquear história por confiança. Sem decaimento ou perdas por ausência.

Não há novo nível de vínculo com humanos. Guardar apenas IDs de patamares premiados se os contadores atuais bastarem. Disponibilidade de pedidos depende exclusivamente de origens acessíveis, não de ver o cliente presente no mapa. Pedido fixo permanece até entrega; cooldown só após entregar. Pelo menos um pedido inicial de ingredientes comuns fica utilizável em toda fase comercial; escolha livre do pedido, sem descarte pago.

Novas encomendas:

| ID | Etapa | Cliente | Pedido | Moedas | XP global | Recarga s | Requisitos |
| --- | ---: | --- | --- | ---: | ---: | ---: | --- |
| farm_breakfast (existente; manter) | 14/15 | Bloblo | egg 2 + flour 2 + cheese 1 | 95 | manter XP Comércio 25 | 600 | manter first_harvest + dairy |
| nina_toys | 17 | Nina | braided_toy 2 | 110 | 10 | 3600 | atelier_open |
| lais_picnic | 17 | Laís | picnic_pack 1 + strawberry_juice 2 | 190 | 12 | 3600 | atelier_open |
| nina_blueberries | 17 | Nina | blueberry_treat 2 | 175 | 12 | 7200 | tesouro aberto + greenhouse |

`bloblo_breakfast` é adicionada na 14 e aponta para o pedido `farm_breakfast` que já existe. Preservar seus ingredientes,95 moedas, XP Comércio 25, recarga 600 e requisitos. Valor imediato atual: egg 2 × 9 + flour 2 × 14 + cheese 1 × 32 =78, pagamento 95. Na 15, acrescentar apenas cliente/confiança ao pedido. O ID da missão anterior é `main_9_cheese`, não `bloblo_cheese`. As outras três linhas são encomendas novas. Não criar itens sem origem nem requisito de ordem inexistente.

Contratos existentes: aumentar somente `special_order` para 600 e `festival_contract` para 940 na 09; outras quantidades/prêmios permanecem. Na 15, objetivos do Feirante que pediam 2/5 contratos passam a 6/15, coerentes com banca 2/3; exigir tipos distintos 2/3 na própria compra. Usar novo requisito `distinct_orders` com escopo `contracts` se necessário; nunca contar encomendas normais nesse requisito. Preservar posse de bancas já compradas e missões recebidas. Itens de ampliação vindos desses contratos permanecem como recuperação determinística; auditar cooldown e acesso, sem exigir a própria ampliação que o material financia.

## C. Maestria de estação e ampliações (18)

Maestria é reconhecimento de uso diverso, derivado de lotes concluídos/recolhidos; não criar outro XP numérico farmável. Estações: fogão, liquidificador, bancada, moinho, laticínio e ateliê. Patamares 1/2/3: 12/40/100 lotes e diversidade de receitas min(2, catálogo elegível), min(3, catálogo elegível), min(4, catálogo elegível). Catálogo elegível = receitas permanentemente acessíveis ao jogador, excluindo cosméticos únicos já feitos; mudança de catálogo não remove patamar recebido. Em estação de uma receita, diversidade=1. Cada trabalho da fila vale 1 independentemente da quantidade de itens de saída. Alimentação de animais fica fora.

Contador novo `station_jobs:<station>` e `station_recipe_jobs:<station>:<recipe>` no recebimento, uma vez. Histórico antigo de `produce:<item>` não identifica lotes com certeza: migrar mínimo comprovável por rendimento histórico conhecido, registrar método e nunca inferir cem lotes de cem produtos quando saída>1. Aceitável iniciar medidor específico em 0 para informação incompleta, mantendo todo o histórico/benefícios antigos. Explicar “Novas conquistas da estação” sem retirar progresso visível existente.

Prêmio único por patamar: 10/20/30 moedas e selo visual bronze/prata/dourado. Sem multiplicadores de tempo/XP/rendimento, novas moedas ou ferramentas obrigatórias. Filas pagas da tabela 02 dão autonomia independentemente da maestria; maestria não é gargalo de campanha. Recompensas automáticas usam IDs persistentes. Tela mostra critério total e variedade separadamente.

Ampliar depósitos até _5 com custos da 02. Não exigir _5 nos projetos ou na campanha; são escolhas de conforto. A ampliação maior precisa de utilidade verificada em inventário de retorno, sem reduzir os limites menores para forçá-la. Preservar compras prévias com regra de piso legado da 05.

## D. Projetos comunitários: estado e dados (19)

Novo `game/data/projects.json`, carregado por Database; `ProjectState` em `scripts/state`, integrado a reset/to_dict/from_dict. Cada projeto: id, name, npc, world, requirements, start_coins, phases[{id, items, visual_state}], rewards, go, interaction. Estado por ID: started, paid_start, phase_index, contributions por fase/material, completed, completion_rewarded, used_once, repeat_cycle quando aplicável. IDs de fases estáveis; se texto/arte muda, não mudar ID. Não reutilizar contrato comercial como projeto.

APIs mínimas em GameState: `project_error/start_project`, `project_contribution_error/contribute_project(id,item,qty)`, `project_ready/complete_project`, `project_use_error/use_project`. Todas as mutações passam por _changed/_count e persistência usuais. Começar valida requisitos e moedas numa única transação; pagar taxa uma vez. Entregar valida quantidade positiva inteira, restante e estoque; consome só a quantidade escolhida e grava contribuição atomicamente. Sem empréstimo, contribuição acima do necessário ou consumo automático de material de outra etapa. Fase concluída avança uma vez; última fase conclui automaticamente e concede prêmio único identificado, inclusive se o último material vier após reload. `complete_project` pode ser helper privado, mas UI não pode pagar outra vez.

**Contrato final implementado na etapa 19** (campos, eventos, recuperação, recibos e testes): `docs/PROGRESSION.md`, "Economia R1 — etapa 19". Requisito de projeto = `requirements.projects: [ids]`.

Goal `{"type":"project","key":"<id>","target":1}` consulta completed; requisitos dependem de `projects`/equivalente canônico validado em um único avaliador. TaskHelp/manual/go entendem esse tipo. Só a etapa 19 define nomes de campos finais coerentes com o esquema; registrar o contrato e testes antes das 20–22. Nunca usar `owned` de construção falsa para simular projeto concluído. Salvar cada contribuição; reler não consome nem premia novamente. Migração vazia para saves antigos; projetos novos não substituem compras/coleções existentes.

## E. Projetos: custos, fases, recompensa e função

Entradas em moedas são pagas ao começar, sem prazo e sem cancelamento com perda inesperada. Materiais listados são totais de cada fase, entregáveis parcialmente; sem `fresh` para exigir produzir tudo novamente. Prêmios não reembolsam obra. Taxas e quantidades são candidatas R1; testar com poucas visitas, não só inventário dev.

| Projeto / etapa | Requisito | Entrada | Fase 1 | Fase 2 | Fase 3 | Prêmio único |
| --- | --- | ---: | --- | --- | --- | --- |
| park_bench /20 | atelier_open | 150 | base: plank 4 + brick 2 | comfort: fabric 2 + braided_toy 1 | welcome: carrot_snack 3 | XP 40, cena permanente |
| village_garden /21 | park_bench concluído | 250 | beds: plank 4 + brick 4 | planting: herbs 8 + wood 6 | opening: strawberry_juice 3 | XP 60, cena permanente |
| park_picnic /21 | park_bench concluído | 250 | corner: plank 3 + fabric 3 | basket: picnic_pack 2 + cheese 2 | meeting: carrot_snack 4 + strawberry_pop 4 | XP 60, cena permanente |
| village_festival /22 | village_garden e park_picnic concluídos + stall_3 | 500 | decorate: fabric 4 + plank 6 + accessory_set 2 | table: picnic_pack 3 + apple_biscuit 6 + cheese 4 | gifts: treat_box 3 + braided_toy 2 | XP 100 + collection community_ribbon, festa permanente |

Os dois projetos intermediários ficam disponíveis juntos; a história pode apontar jardim antes do piquenique, mas não proíbe a escolha inversa. O contrato comercial `festival_contract` permanece uma encomenda do Feirante, nome “Encomenda para eventos” se precisar distinguir; não construir projeto nem conceder o mesmo marco. A última missão antiga do Feirante continua sendo a entrega desse contrato, com o mesmo ID. A Festa é outra obra com demanda, cena e conclusão próprias, sem obrigar entregar o contrato e repetir exatamente seus itens como tutorial.

Banco: sentar/brincar ao lado do brinquedo; Jardim: farejar/caminhar junto às plantas; Piquenique: cena de encontro com o Tiro; Festa: reação alegre e lembrança de comunidade. `use_project` é permitido somente concluído e com Tiro disponível; não exige alimento adicional, amigo presente ou espera. Primeira vez incrementa `project_use:<id>`1; repetições só visual, sem moedas/XP/afeto/contador inflável. História paga os afetos únicos previstos na 03. Não alterar barras fisiológicas por interação repetida. Se o movimento até o local falhar, não perder recurso e permitir repetir; contar uso quando reação efetivamente começar em ponto alcançável.

`community_ribbon`: coleção cosmética “Lenço da nossa turma”, slot compatível com acessórios existentes. Desenhar overlay/âncoras e poses conforme pipeline atual, inventário de coleção isento de espaço. Se asset necessário não puder ser produzido, etapa 22 permanece incompleta; não substituir silenciosamente por moedas. A arte pode ser combinada a partir de recursos do projeto se respeitar estilo e todos os estados do PetAnimator.

Depois da festa, opção repetível “Encontro da turma”, sem obrigação: reusar cenário completo, contribuição picnic_pack 1 + carrot_snack 2, nenhum custo em moedas, intervalo mínimo 24 h após conclusão, recompensa XP 10 e reação coletiva; sem afeto, moedas ou material de ampliação. Estado separado por cycle_id, recibo de prêmio único por ciclo; completar não apaga festa nem altera campanha. Não disparar enquanto Tiro indisponível; material só consome na confirmação válida. É um uso voluntário para quem quer voltar à cena, não requisito de diária nem mecanismo principal de retenção.

## F. Desejos e rotinas com demanda proporcional (16)

Aplicar fórmula de moedas e limites de carinho/brincadeira da 02. Conservar três slots, intervalo e prioridades do sistema atual até medição indicar mudança. Filtro de elegibilidade usa receita/estação/requisito acessível, não só item existente no catálogo. Pedido que se tornou impossível após migração pode ser trocado gratuitamente uma vez; guardar motivo, não gerar itens de graça. Desejos especiais continuam ocasionais; não exigir alimentação desnecessária para avançar.

Novo contador `wish_item:<item>` incrementa na entrega efetiva, sem duplicar quando o prêmio é recebido. Missão opcional de mirtilo garante este desejo na próxima vaga elegível enquanto ativa; não apagar desejo atual, não gerar petisco de graça, não eliminar troca. Brinquedo/cesta não entram em desejos de comida. Demais novos desejos somente se seu verbo já tiver implementação clara; não criar minigame nesta etapa.

Manter sorteio 3 diárias/2 semanais e IDs existentes sempre que possível. Migrar objetivos de banho/carinho/brincadeira repetidos para `care_useful`/`care_useful:<action>`; ação válida significa benefício real≥5 em algum atributo ou tutorial/desejo ativo, com exceção/tutorial consumido apenas uma vez. Contadores brutos continuam para história e saves. Baseline da rotina no sorteio; não usar toda a vida para completar a diária imediatamente. Nunca exigir amigo aleatório ou item raro sem garantia em rotina obrigatória.

Tabela de faixas de objetivos: começo até final cap 4; meio cap 5–9; comunidade cap 10+. Para produção, contar lotes/ciclos e não unidades se mudar rendimento. Faixas são valores exatos por fase, não multiplicadores automáticos de nível.

| Modelo | Começo | Meio | Comunidade | Recompensa |
| --- | ---: | ---: | ---: | --- |
| diária cuidado útil total | 1 | 2 | 2 | 5 moedas, XP 4 |
| diária colher ciclos | 2 | 4 | 4 | 6 moedas, XP 5 |
| diária preparar lotes | 1 | 2 | 3 | 8 moedas, XP 6 |
| diária encomenda vizinho | 1 | 1 | 2 | 8 moedas, XP 6 |
| diária passeio concluído | 1 | 1 | 1 | 5 moedas, XP 5 |
| semanal cuidado útil total | 5 | 8 | 10 | 20 moedas, XP 15 |
| semanal colheitas ciclos | 10 | 16 | 20 | 25 moedas, XP 20 |
| semanal produção lotes | 6 | 10 | 14 | 30 moedas, XP 20 |
| semanal encomendas | 3 | 5 | 6 | 30 moedas, XP 20, bolt 1 |

Estes nove são o catálogo R1 de sorteio. IDs antigos que representem esses mesmos objetivos são reaproveitados; demais modelos legados são desativados para novos sorteios, preservados enquanto ativos no save até vencer/receber. Passeio só sorteia após desbloqueio, produção após fogão, encomenda após quadro; antes de haver 3 candidatas, usar menos missões, nunca tarefa impossível ou repetida para preencher. Semanal de bolt só após quadro. Não adicionar streak com perda, reset pago ou prêmio por entrar todos os dias. Sete dias são janela de rotina, não prazo de obra. Limites antigos ativos não são endurecidos no meio do período; snapshot por rotina gerada.


## G. Integrações obrigatórias da revisão

Banquet_contract abre na banca 1, conservando ingredientes/recompensas, conforme 02 I. A confiança comercial não é a única rota de peças e não deve depender de aumentar a fome do Tiro. A missão de mirtilo está na linha independente nina_flavors 10, não atrás de nina_rare. A obra final exige ambos os projetos e banca 3: escolha é a ordem de investimento, não finais alternativos. Relatório 23 separa tempo financiando, produzindo para obras e entregando contratos; não atribuir toda duração à convivência.

Carinho é exceção explícita ao limiar útil de 5: ganho efetivo 3 e recarga120 s. Desejos concluídos ainda não recebidos não qualificam ações vazias. No catálogo de rotinas, reutilizar `tiro_walk` para passeio do cachorro; o antigo `walk` com contador explore é coleta da Natureza e sai dos novos sorteios. Production jobs tem contador próprio iniciado na 16, reutilizado pela maestria 18; saída 2/3 vale1 lote.
