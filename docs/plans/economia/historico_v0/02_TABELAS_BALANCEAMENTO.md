> **RASCUNHO PAUSADO — 16/10/2026, por pedido do Vitor. Não executar.** Números, produtos e critérios abaixo não estão aprovados. Conteúdo preliminar preservado para revisão após o estudo [Economia e ritmo do Tiro](../../../reports/Economia%20e%20ritmo%20do%20Tiro.md). Consulte o [estado do planejamento](README.md).

# Tabelas de balanceamento — candidata V0

**Fonte única dos números propostos. Não são dados já aplicados nem resultados testados.** Alterar somente na etapa dona do assunto; registrar revisões em [DECISOES](DECISOES.md). IDs existentes não mudam. Campos novos são propostas de schema. Valores não citados permanecem como estão até auditoria indicar problema.

## A. Moedas e preços de venda — Etapa 07

Plantio gratuito. `crops.*.coins = 0` em TODAS as culturas. Zerar moedas das buscas produtivas da Natureza; passeios do Tiro continuam com moedas moderadas. Não cobrar rega, coleta, uso de fila ou ingrediente duas vezes.

| Item | Venda por unidade | Item | Venda por unidade |
|---|---:|---|---:|
| carrot | 2 | potato | 5 |
| pumpkin | 12 | herbs | 10 |
| wheat | 2 | corn | 3 |
| strawberry | 4 | blueberry | 8 |
| sweet_potato | 6 | apple | 5 |
| wood | 2 | stone | 2 |
| copper | 7 | crystal | 18 |
| hardwood | 6 | fiber | 3 |
| plank | 10 | brick | 10 |
| fabric | 20 | accessory_set | 85 |
| carrot_snack | 10 | pumpkin_mash | 24 |
| vegetable_soup | 18 | apple_biscuit | 18 |
| treat_box | 100 | egg | 6 |
| milk | 8 | flour | 9 |
| cheese | 25 | strawberry_pop | 12 |
| strawberry_juice | 16 | mashed_potato | 15 |
| sweet_potato_chips | 20 | mint_snack | 18 |

Passeios/achados conservam preços por ora; auditar efeitos antes de mudar. `dog_food`, `bed_gift`, `bolt`, `iron_band`, pedaços do mapa continuam sem venda e fora da capacidade. Não colocar `feed` em item novo por inferência. O título em português vem de `items.json`.

### Margens de referência (entradas atuais)

Petisco cenoura: 4 → 10; ensopado: 9 → 18; biscoitos de maçã: 20 → 36 (duas unidades); caixa de petiscos: 70 → 100; tecido: 9 → 20; acessórios: 58 → 85; queijo: 16 → 25. Margem é sobre venda dos ingredientes, não custo de semente. Auditar receitas alternativas e caminhos completos, sem contabilizar moedas de colheita como custo.

## B. Estoques — Etapas 03–06 e ampliações da 14

Capacidades são **totais**, unidades somadas. `0` significa estágio provisório, não capacidade zero.

| Estágio | Silo | Geladeira | Armazém | Baú |
|---|---:|---:|---:|---:|
| Provisório | 12 | 8 | 12 | 8 |
| Construído (`silo/fridge/warehouse/chest`) | 24 | 20 | 30 | 20 |
| `_2` | 40 | 35 | 50 | 35 |
| `_3` | 64 | 55 | 80 | 55 |
| `_4` **novo** | 96 | 80 | 120 | 80 |
| `_5` **novo** | 144 | 110 | 170 | 110 |

Nos JSON atuais, `storage_capacity` de melhoria soma: gravar diferença para o nível anterior, não estes totais. Capacidade efetiva pode ter piso legado, ver saves. Não duplicar concessão no objeto do mapa e no GameState.

| Construção | Custo moedas | Materiais | Requisito mínimo / etapa |
|---|---:|---|---|
| silo | 20 | nenhum | `first_harvest`; Etapa 03 |
| fridge | 40 | nenhum | `lais_first_crops`; Etapa 04 |
| warehouse | 80 | wood×4, stone×2 | `lais_forest`, Caverna acessível; Etapa 05 |
| chest | 40 | stick×2 | `nina_walk`; Etapa 06 |

Não cobrar escritura antes do silo. Não cobrar bancada antes do armazém. Baú não precisa de pet shop, raro ou mesa de costura. Para conseguir pedra antes do armazém, `pebbles` na Caverna inicial permanece acessível; a missão não exige ainda guardar seis madeiras da bancada.

| Ampliação de qualquer depósito | Moedas | Materiais comuns | Condição adicional |
|---|---:|---|---|
| `_2` | 100 | plank×2, bolt×1 | depósito + `main_4_bench`; armazém também ensina refinamento; não exige os outros depósitos |
| `_3` | 260 | plank×4, brick×2, bolt×1 | `_2` + `own_business` |
| `_4` | 600 | plank×6, brick×4, iron_band×1 | `_3` + `atelier_open` |
| `_5` | 1200 | plank×8, brick×6, fabric×2, iron_band×2 | `_4` + `community_garden` concluído (só adicionar requisito na 19) |

Etapas 03–06 implementam até `_3`, removendo as exigências tardias antigas. Etapa 14 acrescenta `_4`. Etapa 19 acrescenta `_5`. Primeira caixa de materiais comporta construção do armazém (6 unidades); armazém 30 comporta sua ampliação (2 tábuas + peça isenta). Materiais de ampliação isentos não podem ter quantidade negativa nem comércio infinito.

### Peças especiais garantidas

Primeiro parafuso: `storage_first_planks` (após bancada, sem exigir ampliação), recompensa bolt×1. Segundo: `storage_first_delivery` (um pedido de vizinhança após bancada), bolt×1. Depois, contratos produtivos dão peças. Sem esperar semanal para primeira ampliação. Aro de ferro via `banquet_contract`, com fonte alternativa determinística `artisan_first_set` (após primeiro acessório). Projeto que exige uma peça não é a única fonte dessa própria peça.

### Categorias

- Silo: todas as colheitas, incluindo maçã e novos rendimentos.
- Geladeira: comidas, ovos, leite, queijo, farinha; novos pão/biscoito/compota/iogurte. Ração básica continua isenta.
- Armazém: madeira, pedra, minério, cristal, tábuas, tijolos, fibra, tecido, madeira dura.
- Baú: caixas de petiscos, conjunto de acessórios, cesta de piquenique, sachê; stick/ribbon/wildflower/color_button/yarn/smooth_pebble/river_shell/wild_mint/bird_feather/golden_leaf/moon_pebble.
- Isentos: ração emergencial, peças de ampliação, presente da caminha, peças do mapa, achados de álbum não usados como insumo e roupas da coleção. Exceções são explícitas em `storage`, não categoria desconhecida silenciosamente ilimitada.

## C. Culturas — Etapa 08

Uma rega: 30% do tempo RESTANTE. Não acumula. Estufa: fator de tempo **0,85** para trabalhos novos; segue só culturas `only/any`. XP abaixo é de Horta por canteiro, com primeiro descobrimento ×2 já existente. XP do jogador por colher/regar permanece na base até medição.

| Cultura | Segundos | Rendimento | XP Horta | Papel |
|---|---:|---:|---:|---|
| carrot | 60 | 2 | 6 | ação curta e recuperação |
| potato | 300 | 4 | 16 | primeiro lote maior |
| strawberry | 600 | 8 | 24 | bebida, desejo e venda |
| pumpkin | 1200 | 6 | 35 | início da ausência curta |
| sweet_potato | 1800 | 16 | 45 | preparar para próxima sessão |
| wheat | 300 | 8 | 16 | animais e farinha |
| corn | 600 | 10 | 24 | animais e biscoitos |
| herbs | 2700 | 12 | 50 | estufa e caixas |
| blueberry | 5400 | 20 | 65 | tesouro e produção longa |

Rendimento alto exige espaço: cada lote individual cabe no silo correspondente; não prometer que nove colheitas cabem junto. Antes de liberar mirtilo, silo `_3` disponível; não obrigar estoque máximo. Interface mostra ×N antes de plantar. Batata mantém primeira experiência ≤5 min sem rega. Ervas/mirtilo recebem usos recorrentes sem exigir sorte para receita básica.

Com venda V0 e rega imediata, cenoura ≈5,71 moedas/min/canteiro; batata ≈5,71; morango ≈4,57; abóbora ≈5,14. Essa comparação deliberadamente evita que só a cenoura seja financeiramente sensata. Nenhum desses valores inclui pedidos ou custos de toque.

Canteiros: 2 emprestados → 4 após `bloblo_more_crops`; escritura preserva os 4. Próximos cinco custam **100, 180, 300, 480, 750**. Não exigir compra dos nove para seguir a história. Estufa tem quatro, como hoje.

## D. Receitas existentes e filas — Etapa 09

Entradas/saídas mantidas nesta tabela; valores por unidade estão em A. Tempo é por lote; filas são sequenciais. Estações distintas operam em paralelo.

| Receita | Segundos novos | Rendimento | Observação |
|---|---:|---:|---|
| carrot_snack | 60 | 1 | opção curta permanente |
| mashed_potato | 180 | 1 | primeiro processamento de batata |
| vegetable_soup | 300 | 1 | pedido básico |
| pumpkin_mash | 480 | 1 | prato intermediário |
| sweet_potato_chips | 600 | 1 | lote para amigo/pedido |
| strawberry_juice | 180 | 1 | liquidificador curto |
| strawberry_pop | 300 | 1 | outra utilização da fruta |
| mint_snack | 360 | 1 | liga passeio e cozinha |
| apple_biscuit | 900 | 2 | receita em cadeia |
| treat_box | 1800 | 1 | contrato de produção avançada |
| plank | 180 | 1 | oficina curta |
| brick | 300 | 1 | segunda matéria-prima |
| hardwood_planks | 600 | 3 | conversão em lote |
| fabric | 600 | 1 | ateliê inicial |
| accessory_set | 1200 | 1 | ateliê avançado |
| eggs | 600 | 2 por animal | entradas por animal; guardar `animals` e `qty` |
| milk | 1200 | 2 por animal | sem perder animal por ausência |
| flour | 300 | 2 | moinho |
| cheese | 900 | 1 | queijaria |

Costura de coleção conserva os tempos atuais. Não inflar simultaneamente passeio, chance rara e tempo de costura.

Filas iniciais: fogão 1, liquidificador 1, bancada 2, moinho 2, queijaria 2, ateliê 2, costura 1. Animais conservam um lote, até três animais. `stove_queue` +1, `stove_queue_2` +1; Etapa 14 acrescenta `stove_queue_3` +1, `blender_queue` +1, `mill_queue` +1, `dairy_queue` +1, `atelier_queue` +1. Vaga NÃO significa máquina em paralelo. Reservar saída não conta como inventário antes da coleta, mas mostrar capacidade atual no detalhe.

## E. Natureza — Etapa 10

Remover prêmio em moedas de buscas produtivas. XP do local passa a ser definido por rota e fixado no lote; NÃO usar um XP igual por coleta que privilegie spam da busca mais curta. XP de Aventura existente inicialmente mantido, auditado depois.

| Rota | Segundos | Saída | XP local |
|---|---:|---|---:|
| lane | 180 | wood×3 | 3 |
| pebbles | 180 | stone×2 | 3 |
| trail | 600 | wood×4, stone×4 | 10 |
| quarry | 600 | stone×8 | 10 |
| woodcutting | 600 | wood×10 | 10 |
| timber | 1800 | wood×12, hardwood×4 | 20 |
| deep_quarry | 1800 | stone×12, copper×5 | 20 |
| copper_vein | 1200 | stone×4, copper×4 | 15 |
| crystal_cave | 2400 | crystal×3, copper×3 | 25 |
| crystal_deep | 3600 | crystal×6, copper×5 | 35 |
| meadow | 600 | fiber×5, wood×2 | 10 |
| reeds | 1800 | fiber×12, wood×4 | 20 |
| orchard_harvest | 1800 | apple×12 | — |

Bosque/Caverna/Prado níveis 1–5: **0, 30, 150, 450, 1000 XP acumulados**. Vagas: **1, 2, 2, 3, 3**. Cobre no nível 2; madeira dura/cristal no 3. Nível 4 entrega terceira vaga e título visual; 5 entrega decoração/maestria, sem multiplicar produção. Prado 2 abre reeds; 3 marco visual, 4 vaga 3; não inventar minério/fibra novos para preencher níveis.

Os tokens existentes de vaga 3 passam a ser associados ao nível 4 para novos jogos; posse anterior é preservada. Materiais do nível 3 continuam acessíveis sem a terceira vaga. Descrição/ajuda precisam explicar isso. A rota lenta é mais conveniente, não deve ser simultaneamente sempre superior em material/min, XP/min e lucro/min. Auditar as alternativas e tornar a diferença visível; ajustar V0 se alguma for inútil.

## F. Construções e ampliações produtivas

Preços atuais permanecem até a etapa indicada. Tabela é custo total em moedas + materiais, não prazo de construção: **comprar continua instantâneo**.

| ID | Moedas | Materiais | Aplicar |
|---|---:|---|---|
| stove | 60 | — | 07 |
| blender | 40 | — | 07 |
| farm | 250 | — | 07 |
| sofa | 90 | — | 07 (manter opção) |
| forest_open | 40 | — | 07 |
| cave_open | 100 | — | 07 |
| meadow_open | 80 | — | 07 |
| workbench | 200 | wood×6 | 07 |
| chicken_coop | 350 | plank×4 | 11 |
| cow_barn | 650 | plank×6, brick×2 | 11 |
| mill | 400 | plank×3, stone×6 | 11 |
| dairy | 600 | plank×4, brick×3 | 11 |
| orchard | 500 | plank×5 | 11 |
| stall | 650 | plank×5, brick×3 | 11 |
| greenhouse | 1400 | plank×8, brick×6, crystal×2 | 11 |
| atelier | 1600 | plank×8, copper×6 | 11 |
| stall_2 | 1400 | plank×8, brick×6 | 13 |
| stall_3 | 2600 | plank×10, brick×8, fabric×3 | 13 |
| petshop | 250 | stick×4, ribbon×2 | 16 |
| sewing_table | 180 | yarn×2, ribbon×2 | 16 |
| walk_bag | 350 | yarn×3, ribbon×2 | 16 |
| stove_queue | 180 | plank×3 | 09 |
| stove_queue_2 | 420 | plank×5 | 09 |
| stove_queue_3 (novo) | 900 | plank×6, bolt×1 | 14 |
| blender_queue (novo) | 220 | plank×2, bolt×1 | 14 |
| mill_queue (novo) | 450 | plank×4, bolt×1 | 14 |
| dairy_queue (novo) | 650 | plank×4, brick×2 | 14 |
| atelier_queue (novo) | 850 | plank×6, fabric×2 | 14 |

Animais (Etapa 11): primeira unidade continua presente do abrigo. Adicionais: galinhas branca/ruiva/preta 120/160/200; vacas pintadinha/caramelo/malhada 240/320/400. Variedade inicialmente cosmética; mesmo rendimento evita escolha-armadilha. Requisitos de variedades usam produção recolhida 8/24, não raridade aleatória. Animais legados preservados.

## G. Prêmios — Etapa 07; rotinas/cuidados na 15

Início: 10 moedas + 3 rações, como hoje. Manter 55 moedas das seis missões da Laís do capítulo 1 e caminha grátis. Presente inicial de nível 2: 10 moedas + 2 rações. Não garantir compra do sofá e toda cozinha ao mesmo tempo; garantir recuperação se a pessoa escolher o sofá.

Capítulos 1–9: moedas **10, 15, 20, 25, 30, 40, 50, 60, 80**. Futuros 10–12: **60, 80, 100** na Etapa 20. Outros prêmios de capítulo preservados, salvo loop comprovado.

Missões existentes após tutorial: regra candidata determinística para a Etapa 07:
- conversa/abrir tela: 5 moedas;
- primeira ação/aprendizado: 10;
- compra/owned: 10, exceto `atelier_open` 30 e `merchant_stall` 20;
- entrega de item: `ceil(0,20 × valor de venda entregue)`, mínimo 5 e máximo 40;
- objetivos mistos de produção/estoque: 15;
- `shared_with`: zero, só canônica paga;
- missão que não dava moedas continua sem moedas; demais prêmios preservados exceto regras explícitas deste plano.

Material essencial entregue pela missão é contabilizado no orçamento, não removido para acertar uma porcentagem. Auditoria registra a lista resultante por ID. Construção + missão + capítulo precisa respeitar teto combinado de 25% de devolução de moedas; baixar prêmio da missão primeiro, depois capítulo daquele marco, com exceção de tutorial registrada.

Níveis jogador 2–10: moedas **10,15,20,20,25,30,35,40,50**, manter itens existentes. Depois: `min(60, 10 + 3×nível)`; novos parâmetros no bloco default, sem fórmula fixa espalhada na UI. Curva de XP do jogador permanece inicialmente.

Vínculo conserva thresholds atuais 0/20/50/100/170/260/380/520, mas moedas nos níveis 2–8 passam a **10/15/20/25/30/40/50**. Itens preservados. Cuidado significativo e afeto: ver Etapa 15. Não recalcular prêmios já pagos.

Presente diário continua ciclo de dias jogados sem perda por faltar: ração×3, 10 moedas, petisco cenoura×1, 15 moedas, bolt×1, 20 moedas, 25 moedas. Nunca exigir presente diário para primeira ampliação.

## H. Encomendas existentes — Etapa 07 preços; Etapa 13 diversidade

Entradas atuais conservadas na 07. Cada linha é recompensa em moedas e cooldown em segundos após entrega. O cooldown não expira o pedido.

| ID | Moedas | Recarga |
|---|---:|---:|
| vegetables | 12 | 120 |
| snacks | 42 | 300 |
| soup_order | 52 | 600 |
| fruit_basket | 24 | 300 |
| pop_order | 34 | 600 |
| puree_order | 42 | 600 |
| juice_order | 46 | 600 |
| farm_breakfast | 80 | 1200 |
| building_order | 120 + bolt×1 | 1200 |
| special_order | 420 + bolt×1 | 2400 |
| fabric_order | 120 + bolt×1 | 1800 |
| banquet_contract | 220 + iron_band×1 | 2400 |
| festival_contract | 800 + bolt×1 + iron_band×1 | 3600 |

Contrato Festa continua repetível e diferente do projeto visual Festa: o primeiro financia; o segundo conclui capítulos e muda o mundo. Não usar mesma marca de conclusão nos dois.

Na 13, banca 2 exige 6 contratos e ao menos 2 tipos; banca 3 exige 15 e ao menos 3 tipos. `fabric_order`/`banquet_contract` devem oferecer terceiro tipo antes da banca 3; não exigir festa para desbloquear a banca que libera festa.

## I. Seis produtos novos — Etapa 12

| Item/receita novo | Estação | Entradas | Saída | Segundos | Venda/un. | Categoria |
|---|---|---|---:|---:|---:|---|
| village_bread | stove | flour×2 | 2 | 900 | 14 | food/fridge |
| corn_biscuit | stove | flour×1, corn×2, egg×1 | 2 | 720 | 16 | food/fridge |
| apple_compote | blender | apple×3 | 1 | 1200 | 24 | food/fridge |
| strawberry_yogurt | dairy | milk×2, strawberry×2 | 2 | 1200 | 18 | food/fridge |
| picnic_basket | stove | village_bread×2, cheese×1, strawberry_juice×1 | 1 | 1200 | 105 | product/chest |
| flower_sachet | atelier | fabric×1, wildflower×2, ribbon×1 | 1 | 1200 | 50 | product/chest |

XP da especialidade por lote: 25/25/30/30/45/40, primeira descoberta ×2. `picnic_basket` não é comida direta do Tiro. Todos vendáveis; liberar por cadeia e missão de apresentação, não só por nível.

Pedidos associados (inseridos na 12 para já dar uso; cliente evolutivo na 13): `bread_order` pão×4 →80 moedas/1200 s; `corn_biscuit_order` biscoito×4 →90/1200; `compote_order` compota×2 →68/1800; `yogurt_order` iogurte×4 →100/1800; `picnic_order` cesta×2 →300/3600; `sachet_order` sachê×2 →140/2400. Os dois últimos são contratos; os quatro primeiros vizinhança. Não exigir todos na campanha principal.

## J. Projetos e maestria

Quantidades e prêmios de projetos estão na seção de projetos de [03_JORNADA_E_MISSOES](03_JORNADA_E_MISSOES.md), única fonte desse conteúdo. Maestria: 10/30/75 lotes recolhidos, com 2/3/3 receitas distintas quando a estação tiver catálogo suficiente; primeiro título e bolt×1, segundo libera compra de fila ou alternativa visual, terceiro decoração. Sem multiplicador infinito de dinheiro/velocidade/rendimento. Só implementar estações com catálogo compatível, não inventar receitas para cumprir a contagem.

## K. Orçamento de arranque a provar

Antes de receber o silo: início 10 + tutorial 55 + capítulo 10 + primeiras missões/venda, silo 20; espaço para colher/vender permanece. Cozinha: geladeira40 + fogão60 + liquidificador40. Mesmo depois de sofá90, plantio gratuito e venda no sítio recuperam o saldo. Simular o percurso exato, não concluir acessibilidade por soma nominal de recompensas que ainda estão bloqueadas.

Remover moeda de colheita, aumentar preço e alongar tempo em etapas distintas facilita atribuir efeito. Em cada etapa, manter o começo dentro dos critérios; ajustar valores novos se necessário antes de avançar. Não usar recompensas futuras, venda de item que a missão vai consumir ou ciclos impossíveis para fechar o orçamento.
