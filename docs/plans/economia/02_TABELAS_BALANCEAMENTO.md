# Tabelas R1 — aplicar por etapa

Valores iniciais executáveis derivados da pesquisa, **ainda sujeitos à medição**. A etapa 23 calibra o conjunto; cada etapa corrige impossibilidades antes de continuar. V0 preservada em [arquivo histórico](historico_v0/02_TABELAS_BALANCEAMENTO.md). Campos não citados conservam seus valores atuais. Capacidades são totais; custos em moedas; tempos em segundos de jogo real.

## A. Armazenamento (05–08; expansões finais na 18)

| Estágio | Silo | Geladeira | Armazém | Baú |
|---|---:|---:|---:|---:|
| Provisório | 16 | 12 | 16 | 12 |
| Construído | 32 | 24 | 32 | 24 |
| `_2` | 56 | 40 | 56 | 40 |
| `_3` | 88 | 64 | 88 | 64 |
| `_4` novo | 128 | 88 | 128 | 88 |
| `_5` novo | 176 | 120 | 176 | 120 |

Somar apenas diferenças no campo atual `storage_capacity`. Ex.: silo_2 soma 24, não 56. Novos jogos usam capacidade provisória mesmo sem edifício; categoria só aparece quando apresentada/possui item. Saves com capacidade antiga comprada maior conservam piso legado.

| Edifício | Moedas | Materiais | Requisito da compra |
|---|---:|---|---|
| silo | 0 | nenhum | first_harvest |
| fridge | 40 | nenhum | lais_first_crops |
| warehouse | 40 | wood× 4, stone× 2 | lais_forest |
| chest | 0 | stick× 2 | nina_walk |

Silo = recuperar estrutura emprestada da Bloblo; baú = montar com gravetos, ambos via compra existente de custo zero e ação Construir. Não autoentregar moedas equivalentes. Já adquiridos não recebem reembolso. Armazém requer pedra acessível na Caverna inicial, nunca bancada própria.

| Ampliação | Silo custo/material | Geladeira | Armazém | Baú | Requisito extra |
|---|---|---|---|---|---|
| `_2` | 100; plank 2+bolt 1 | 100; plank 2+bolt 1 | 90; plank 2+bolt 1 | 80; plank 2+bolt 1 | main_4_bench |
| `_3` | 260; plank 4+brick 2+bolt 1 | 240; plank 4+brick 2+bolt 1 | 240; plank 4+brick 2+bolt 1 | 200; plank 3+fabric 1+bolt 1 | own_business; baú também atelier |
| `_4` | 550; plank 6+brick 4+iron_band1 | 500; plank 5+brick 3+iron_band1 | 500; plank 6+brick 3+iron_band1 | 400; plank 4+fabric 2+iron_band1 | atelier_open |
| `_5` | 1000; plank 8+brick 6+iron_band2 | 900; plank 6+brick 4+iron_band2 | 900; plank 8+brick 5+iron_band2 | 750; plank 5+fabric 3+iron_band2 | respectivo _4 + stats.contracts ≥ 12 |

Todas exigem o estágio anterior da própria categoria. Nenhuma exige ampliar outro depósito ou completar fila inteira da Bloblo. Até _3 nas etapas 05–08; _4/_5 somente 18. Peças de ampliação não ocupam depósito.

Primeiros parafusos garantidos: `storage_first_planks` (produzir duas tábuas depois da bancada) concede 1 bolt; `storage_first_delivery` (uma encomenda depois dessa missão) concede 1 bolt. Ambas entram na etapa 07, na linha `storage`, sem exigir ampliação. O jogador pode escolher qual depósito ampliar primeiro.

Também na etapa 07, `bloblo_bigger` e `bloblo_biggest` passam a reconhecer 1 e 3 ampliações quaisquer, respectivamente, e concedem 2 e 1 bolts. Não exigem mais silo_2 + fridge_2 ou silo_3, nem concedem os antigos aros. Preservar prêmios já recebidos. Os detalhes de objetivos, moedas e contagem estão na seção B de [Jornada e missões](03_JORNADA_E_MISSOES.md). Contratos, rotinas e clientes fornecem peças adicionais. O primeiro aro determinístico pode vir de `banquet_contract` (banca 1, a partir da etapa 15) ou de `workshop_first_set` (etapa 17), sem exigir uma ampliação `_4` para obtê-lo.

Categorias: silo=colheitas/maçã; geladeira=comidas, ovos, leite, queijo e farinha; armazém=wood/stone/copper/crystal/plank/brick/fiber/fabric/hardwood; baú=treat_box/accessory_set, os 11 materiais `trail` e brinquedo/cesta novos. Ração, bed_gift, bolt, iron_band, partes do mapa, achados de álbum não usados em fabricação e coleções permanecem isentos. `wild_mint` fica no baú como material de passeio; petisco pronto vai à geladeira. Nenhum novo item pode cair em categoria desconhecida ilimitada.

## B. Dinheiro e margens (09)

Zerar `crops.*.coins` e moedas de buscas produtivas `activities`; manter vendas, moedas de passeios e achados. Plantio continua gratuito. Não reduzir todas as recompensas ao mesmo tempo: preservar começo, diárias, desejos e nível até suas etapas específicas.

Manter preços atuais de todos os itens **exceto** `apple_biscuit`:40→30 por unidade; `treat_box`:60→140. Assim biscoito usa 26 e entrega 60; caixa usa 101 e entrega 140. Nada é cobrado à carteira por esses valores: são comparação com venda dos ingredientes. Não exigir margem universal de 20%; identificar destino útil e evitar receita comercial dominada em todos os eixos.

Pedidos que mudam pelo preço da caixa: `special_order`→600 moedas; `festival_contract`→940. Demais moedas, ingredientes e peças dos pedidos existentes permanecem nesta etapa. Atualizar teste de margem com cadeia completa; peças são bônus, não cotação fictícia usada para esconder perda.

Na etapa 09, reduzir os prêmios únicos que devolvem compras depressa: `merchant_stall`, de 150 para 30 moedas; `atelier_open`, de 200 para 40. `bloblo_biggest` já passa de 200 para 40 na etapa 07, junto da reorganização da linha `storage`; manter esse valor. Capítulos 1–9: 10/20/30/40/60/60/60/80/80 moedas. Os demais prêmios permanecem conforme as revisões já executadas. Nesta etapa, não retirar itens, desbloqueios ou roupas; `shared_with` continua sem outra entrega ou prêmio.

Níveis 2–10 e curva de XP permanecem; acima de 10 trocar fallback por `min(80, 20+3×nível)` usando parâmetros no JSON, sem fórmula escondida na UI. Presentes já recebidos não são recalculados. `dog_food` emergencial e ajuda atual preservados.

## C. Culturas e demanda de espaço (10)

Rega 30% do tempo restante, uma vez; fator estufa 0,7 mantido. Quatro canteiros delicados; índices e permissões conservados. Tempo longo opcional não bloqueia a cozinha inicial: objetivos de abóbora/morango secundários são reorganizados na 03_JORNADA desde a etapa 10 se necessário.

| Cultura | Segundos | Saída por lote | XP Horta | Função |
|---|---:|---:|---:|---|
| carrot | 60 | 2 | 6 | curto, ensino, recuperação |
| potato | 300 | 3 | 16 | cozinha inicial |
| strawberry | 900 | 4 | 24 | bebida, amigos, visita curta |
| pumpkin | 3600 | 4 | 35 | preparar retorno |
| sweet_potato | 7200 | 6 | 45 | alimento amigo/pedido para ausência |
| wheat | 600 | 4 | 18 | farinha e vacas |
| corn | 1200 | 6 | 24 | galinhas e reservas |
| herbs | 7200 | 6 | 50 | estufa e caixa |
| blueberry | 14400 | 8 | 65 | tesouro e petisco especial |

Exemplo de retorno: quatro mirtilos=32 unidades, não 80; cabe no silo_2=56 com reserva de 24. Quatro cenouras=8; provisório 16 permite duas rodadas, mas silo 32 é apresentado antes de emprestar quatro canteiros. A chegada de nova cultura não exige simultaneamente colher todas as anteriores.

Custos dos cinco canteiros adicionais: 80/140/220/340/500. Quantidades 2→4 emprestadas mantidas, escritura não reinicia. História não exige nove canteiros. Não acrescentar custo de semente para controlar renda.

## D. Estações, receitas e autonomia (12)

Entradas e rendimentos atuais, salvo os novos produtos da etapa 17. Tempos abaixo; demais receitas (costura de coleção) mantêm atuais. Uma vaga contém um trabalho sequencial, não uma máquina paralela.

| Receita | s | Receita | s |
|---|---:|---|---:|
| carrot_snack | 60 | mashed_potato | 120 |
| vegetable_soup | 180 | pumpkin_mash | 300 |
| strawberry_juice | 120 | strawberry_pop | 180 |
| sweet_potato_chips | 600 | mint_snack | 240 |
| apple_biscuit | 480 | treat_box | 900 |
| plank | 120 | brick | 180 |
| hardwood_planks | 480 | fabric | 900 |
| accessory_set | 1800 | flour | 300 |
| eggs | 900 | milk | 1800 |
| cheese | 1200 | — | — |

Primeiro fogão 1 vaga; cozinha organizada `stove_queue`+1 por 80 moedas, sem tábuas, exige first_kitchen; `stove_queue_2`+1 por 220+plank 3, exige bancada e fila anterior. Liquidificador fila+1 `blender_queue` por 100+plank 1 após bancada. Não criar botão para enfileirar mais do que cabe; ação Preparar N enfileira N trabalhos iguais, cada um ocupa vaga e consome ingredientes próprios, sem desconto/velocidade extra. N máximo=min(vagas livres, lotes financiáveis). Validação atômica de todo pedido, não metade silenciosa.

Na etapa 18: `stove_queue_3`+1 por 500+plank 4+bolt 1, exige 2 e own_business; `mill_queue`+1 por 250+plank 3, exige mill; `dairy_queue`+1 por 350+plank 3+brick 2; `atelier_queue`+1 por 450+plank 4+fabric 1. Sem ampliar fila de animais: um lote com até 3 animais. Ateliê/maestria não altera velocidade automaticamente.

## E. Natureza (11)

XP local por rota, fixado ao iniciar; não multiplicar automaticamente por quantidade de itens ou número de cliques. Desbloquear material e adicionar vaga são benefícios separados.

| Rota | s | Saída | XP local |
|---|---:|---|---:|
| lane | 120 | wood 2 | 2 |
| pebbles | 120 | stone 2 | 2 |
| trail | 600 | wood 4+stone 3 | 8 |
| quarry | 600 | stone 6 | 8 |
| woodcutting | 900 | wood 8 | 12 |
| timber | 3600 | wood 8+hardwood 3 | 35 |
| copper_vein | 1200 | stone 3+copper 3 | 16 |
| deep_quarry | 3600 | stone 8+copper 5 | 35 |
| crystal_cave | 2400 | crystal 2+copper 2 | 26 |
| crystal_deep | 7200 | crystal 5+copper 4 | 60 |
| meadow | 600 | fiber 4+wood 2 | 8 |
| reeds | 3600 | fiber 10+wood 3 | 35 |
| orchard_harvest | 3600 | apple 8 | não é local de XP |

Níveis 1–4 dos três locais: XP acumulado 0/24/120/360. Vagas 1/2/2/3. Cobre no 2; madeira dura e cristal no 3; nível 4 abre terceira vaga. Prado 2 abre reeds; 3 título visual de domínio,4 vaga. Não criar quarto material só para preencher nível. Tokens antigos nível 3 mantêm liberação de material, token vaga 3 passa a nível 4 para saves novos. Posse de vagas/materiais já alcançados preservada na migração.

Na etapa 11, `woodcutting` fica disponível desde `forest_open`, retirando somente o requisito de nível 2. Mantém 900 s, wood × 8 e 12 de XP local; `lane`, com 120 s, wood × 2 e 2 de XP local, continua como alternativa curta. Expor duração e rota na bandeja de madeira para o jogador escolher; não substituir automaticamente a curta pela longa. Nos demais recursos, preservar a disponibilidade vigente e expor rotas elegíveis quando houver mais de uma. Lembrar a escolha na sessão; o padrão inicial é a rota elegível mais curta. Selecionar não inicia a produção.

## F. Investimentos (14; preços da banca na etapa 15; filas como D)

Não mexer nos preços não listados. Custos de depósitos seguem A. Não cobrar tempo de construção: compra continua instantânea.

| ID | Moedas R1 | Materiais R1 |
|---|---:|---|
| farm | 220 | — |
| workbench | 160 | wood 6 |
| chicken_coop | 260 | plank 4 |
| cow_barn | 420 | plank 6 |
| mill | 300 | plank 3+stone 6 |
| dairy | 420 | plank 4+brick 3 |
| orchard | 400 | plank 5 |
| stall | 500 | plank 5+brick 3 |
| greenhouse | 850 | plank 6+brick 6+crystal 2 |
| atelier | 1000 | plank 8+copper 6 |
| stall_2 | 900 | plank 6+brick 4 |
| stall_3 | 1500 | plank 8+brick 6+fabric 2 |

Primeiro animal continua presente do abrigo. Adicionais branca/ruiva/preta 120/150/180; vacas 220/280/340. Requisitos de variedade ruiva/caramelo 8 produtos, preta/malhada 24. Mesmo rendimento por animal, variedades não são upgrades escondidos.

Banca 2: seis contratos totais e dois tipos diferentes; banca 3: doze e três tipos (ajustada de quinze na etapa 24). Na etapa 15, `banquet_contract` troca o requisito `stall_2` por `stall`, mantendo `dairy` e `blender`, seus ingredientes, pagamento de 300 moedas e recarga de 1200 s. Assim, `building_order` e `banquet_contract` satisfazem a diversidade da banca 2 antes da estufa, do pomar e da caixa de petiscos. `fabric_order` permanece na banca 2; `special_order` permanece como opção de cadeia avançada na banca 1. O terceiro tipo não depende da própria banca 3. Preservar contadores antigos derivados dos pedidos; não criar contrato novo para resolver a variedade.

## G. Cuidado protegido (04) e vínculo (16)

Online: taxas e efeitos atuais. Offline: metade da taxa online por no máximo 8 horas de queda por ausência contínua. Pisos offline barriga 25/felicidade 35/energia 25/higiene 30; piso impede queda abaixo dele, mas NÃO aumenta uma barra que já estava menor. Sono offline usa +40 energia/h até 100; permanecendo em ausência, não volta a cair. As outras três seguem proteção. Ao voltar, resetar timestamp e continuar online normalmente. Datas retrocedidas não criam perda negativa/prêmios; ver contrato temporal.

Vínculo preserva os patamares atuais. Carinho pode conceder +1 afeto a cada 120 s, sem limite à reação visual; guardar o controle no estado, não só na UI. Para contar como cuidado útil, carinho exige recuperação efetiva de pelo menos 3 pontos, com intervalo de 120 s; os demais cuidados exigem pelo menos 5. Brincar concede +2 de afeto se recuperou pelo menos 5 de felicidade ou era uma ação de desejo/tutorial, com recarga de 120 s. Alimentar e banhar contam `care_useful:<ação>` quando recuperam pelo menos 5 em alguma necessidade positiva relevante ou cumprem desejo/tutorial ativo. A exceção de tutorial/desejo só existe enquanto falta progresso naquela instância: depois de satisfazê-la, aguardar Receber não produz novas recompensas. XP e afeto não são concedidos duas vezes pelo mesmo gesto. Manter contadores brutos antigos para saves e história; rotinas novas usam contadores úteis.

Desejos mantêm slots/recargas atuais; moedas candidatas: ações sem item 2; comida/give `min(8, max(2, round(sell_price×0,5)))`, ração 2; afeto e demais efeitos atuais. Especiais multiplicam afeto como já configurado, moedas limitadas a12. Não aplicar duas recompensas se feed direto encaminha a desejo. Vínculo níveis 2–8 moedas 10/15/20/25/30/40/50; itens atuais preservados. Nenhum recálculo retroativo.

Não alterar taxa de fome para consumir produção. Ração emergência permanece isenta e acessível. Após 48 h, se energia já era 0 antes de sair, o piso não dá energia grátis; ainda é possível carinho/banho/alimentação, e sono recupera. Teste de retorno não pode exigir brincar imediatamente em todo estado arbitrário.

## H. Números de conteúdo novo

Produtos, projetos, clientes e rotinas têm valores únicos em [Conteúdo e sistemas](07_CONTEUDO_E_SISTEMAS.md). Missões e prêmios exatos estão em [Jornada e missões](03_JORNADA_E_MISSOES.md) e na [matriz de quests](08_MATRIZ_QUESTS.md). Não duplicar aqui. Correções posteriores entram em DECISOES, com a tabela atualizada.
