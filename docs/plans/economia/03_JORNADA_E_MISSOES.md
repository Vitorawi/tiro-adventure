# Jornada, missões e desbloqueios R1

Usar junto da [matriz completa dos IDs atuais](08_MATRIZ_QUESTS.md). Essa matriz é inventário de alterações, não uma nova cópia dos JSON. `main_9_*` são IDs históricos da linha de animais; não renomeá-los para coincidir com capítulos.

## A. Princípios operacionais

- Uma apresentação, uma entrega canônica, um prêmio. História usa `shared_with` para orientar até o marco do personagem. Nunca criar duas entregas do mesmo produto para representar o mesmo acontecimento.
- `fresh` só quando a fala pede uma ação nova, não quando basta reconhecer algo que a pessoa já aprendeu. Posse, diversidade e produção total anterior podem contar.
- Não pedir guardar um intermediário e entregá-lo em duas missões seguidas só para alongar. `have` não consome; `deliver` consome exatamente uma vez.
- Não alterar ordem de missão sem migrar capítulo/linha/steps antigos. A lista antiga versionada é capturada na etapa 02; migração de conteúdo específica em cada etapa que reordena.
- Nova missão aparece com nome e objetivo concreto, Ir e ?. Não exibir código, capítulo numérico ou regra interna ao jogador.
- Linhas `flavors` e `storage` usam Bloblo, `workshop` usa Guia, `nina_discoveries` e `nina_flavors` usam Nina. São trilhas no sistema existente, não abas novas. Mostrar no máximo um cartão por linha; ordenar pelo objetivo da história e pelos prontos. Conferir NPC com duas linhas no mesmo painel.

## B. Depósitos entram no contexto (05–08)

### Bloblo / horta

Ordem da linha principal da Bloblo após 05: `bloblo_meet`10 → `first_harvest`20 → `bloblo_sell_surplus`22 → `bloblo_dig`25 → `bloblo_silo`27 → `bloblo_more_crops`30 → `bloblo_carrots`40 → `bloblo_potato`50 → `bloblo_stew`60 → `farm_deed`70 → animais 80 em diante.

`bloblo_silo` mantém ID, muda de 140 para 27, objetivo owned:silo, prêmio 10 moedas (sem bolt); fala: “Vamos arrumar o silo. Assim sobra lugar para a próxima colheita.” Construção gratuita após first_harvest. Remover requisito main_9_cheese. Primeiro aprender vender; depois ampliar antes dos quatro canteiros. Não exigir encher o cesto para liberar a missão.

### Guia / materiais

Na etapa 07: `guide_meet`10 → `guide_wood`20 → **`guide_open_cave`22** → `bloblo_warehouse`25 → `guide_stone`30 → `guide_fibers`40 → `guide_treasure`50. `bloblo_warehouse` muda npc/line para guide, mantém ID e estado recebido. Objetivo owned:warehouse, prêmio 10 moedas. `guide_open_cave`: owned:cave_open, prêmio 5. Não exigir warehouse para abrir cave_open; compra continua capítulo 5.

`main_4_materials` pede wood 6 e owned:warehouse a partir 07; não consome madeira. Isso ensina preparar a caixa antes da bancada. Armazém consome wood 4+stone 2; capacidade provisória 16 comporta tudo. `guide_wood` continua uma busca nova e não cobra o material já usado.

Linha `storage`, npc bloblo, abre com main_4_bench: **`storage_first_planks`10** (produzir 2 tábuas, fresh, prêmio bolt 1) → **`storage_first_delivery`20** (orders 1, fresh, prêmio bolt 1) → `bloblo_bigger`30 → `bloblo_biggest`40. Na etapa 07 mover os dois IDs existentes para essa linha, mudando objetivos para stat storage_upgrades1 e storage_upgrades3, respectivamente. `storage_upgrades` conta ampliações compradas (_2 e posteriores, qualquer depósito), não os quatro edifícios iniciais; derivar posse antiga e incrementar uma vez em cada compra, nunca por abrir painel. Moedas 15/40 e itens bolt 2/bolt 1, respectivamente, substituem os antigos pacotes de bolts/aros para recebimentos futuros. Preservar tudo que já foi pago. Renomear para “Mais espaço onde importa” e “Uma casa organizada”. Isso permite escolher silo, geladeira, armazém ou baú sem perder a fonte inicial de peças. Não fazem parte da história obrigatória nem bloqueiam categorias diferentes.

### Nina / bagagem

Na etapa 08 mover `bloblo_chest` para npc/line nina, order 25, após nina_walk e antes nina_routes. Objetivo owned:chest, prêmio 10 moedas, sem bolt. Fala: “Trouxe gravetos? Vamos montar um baú para as coisas dos passeios.” Primeiro passeio garante stick 2 como hoje; baú consome 2, sem depender de madeira da Natureza. Nunca exige receber uma nova bagagem para resolver uma antiga cheia: venda dos itens de passeio existe na feira e a primeira bagagem deve caber vazia no provisório.

Geladeira conserva `main_2_fridge` e preço 40. Antes dela existe despensa 12; panela/fogão continuam pedindo geladeira. A missão diz que a compra aumenta espaço, não revela um limite até então ausente.

## C. Sabores sem bloquear a história (ajuste de suporte na etapa 10, acabamento na etapa 13)

Mover para linha `flavors`, npc bloblo: `bloblo_strawberry`10 (requisito first_kitchen), `bloblo_pumpkin`20, `bloblo_sweet_potato`30 (requisito farm_deed). IDs e recompensas atuais preservados. Culturas continuam liberadas por marcos reais: strawberry por bloblo_dig; pumpkin por bloblo_potato; sweet_potato por farm_deed. Não exigir a missão que pede colher para liberar o próprio plantio.

Receita pumpkin_mash continua após bloblo_pumpkin, chips após bloblo_sweet_potato. Nenhuma das três missões é pré-requisito da escritura, do ensopado ou da primeira viagem. Cesta de morangos e desejos podem exigir a apresentação específica da fruta. A UI de receitas deve mostrar origem mesmo com missão lateral pendente.

## D. História 1–9 revisada (13; custos e animais na etapa 14)

| Capítulo | IDs/marcos existentes | Alteração de objetivo |
|---|---|---|
|1 Um novo lar | welcome, lais_feed, lais_bath, lais_play, lais_bag, lais_bed | manter; tutorial de cuidado conta uma ação mesmo sem necessidade, sem farm de recompensa |
|2 O sítio da vovó | lais_meet_bloblo, lais_first_crops | aliases existentes; silo entra antes de bloblo_more_crops |
|3 A cozinha | main_2_fridge, first_kitchen, lais_blender, lais_stew | manter; não acrescentar produção de morango 15 min no caminho crítico; alias do ensopado único |
|4 Conhecendo a Vila | lais_village, first_sale, main_2_order | manter aliases do Feirante; primeiro passeio abre ao concluir |
|5 Além do portão | lais_forest, main_4_materials, main_4_bench | armazém na etapa de materiais; bancada 120/160 conforme etapa 14, sem entrega duplicada de madeira |
|6 Uma produção de verdade | main_5_pickaxe, stone_path, main_5_cooking, main_5_bricks | pickaxe alias guide_open_cave; stone_path alias guide_stone; cooking objetivos específicos abaixo; bricks mantém have 4 |
|7 Nosso lugar na vila | market_day, main_6_commerce, own_business | market_day alias merchant_regular; commerce alias merchant_variety novo; own_business alias merchant_stall |
|8 Um mundo de possibilidades | main_7_orchard, deep_earth, main_7_greenhouse | orchard mantém; cristais deliver 2 mantém; greenhouse owned + harvest:herbs 1 (sem fresh) |
|9 Feito por nós | main_8_fiber, main_8_building, atelier_open | fiber have 6 mantém; tábuas 6 contar produção histórica (retirar fresh); atelier owned+produce:fabric 2+produce:accessory_set1 |

`main_5_cooking`: substituir produce 5 genérico por produce:carrot_snack2, produce:vegetable_soup1, produce:strawberry_juice1, todos sem fresh. Objetivo visível “Experimente três receitas da cozinha”; não repetir o que já foi feito. `main_7_greenhouse` requer que herbs esteja disponível com estufa; remover skills.agriculture 5 dessa cultura, deixando owned:greenhouse. Atributo permanece útil para maestria/consulta, não trava oculta da demonstração.

`merchant_variety` novo, line merchant order 45, depois merchant_regular40 e antes merchant_stall50: objetivos stat order:vegetables 1 e order:snacks 1 sem fresh, prêmio 10 moedas. São dois pedidos simples já acessíveis antes da banca; reconhecer se concluídos antes. Descrição distingue produzir/entregar de vender avulso. Não exigir contrato para montar banca.

Não fazer `shared_with` de duas missões principais para a mesma canônica no mesmo capítulo. Após reorganização, testar sincronização de capítulo, recompensas e posicionamento do Ir. Principal orienta até marco, como interface atual, sem clonar cartão de entrega.

## E. Animais e processamento (14)

Sequência Bloblo: farm_deed70 → main_9_coop80 → main_9_eggs90 → main_9_cows100 → bloblo_milk110 → main_9_flour120 → main_9_cheese130. Não voltar a pôr silo/armazém/baú no fim.

Manter 2 ovos e2 leites para ensinar primeiro lote. O curral não exige comprar outra galinha; moinho pode ser comprado depois do galinheiro para escolher investimento. main_9_flour pede owned:mill + produce:flour 2, sem fresh; queijo mantém deliver 2 + owned:dairy. Após queijo adicionar **`bloblo_breakfast`140**, stat order:farm_breakfast1, prêmio 15 moedas: uso real da cadeia, apenas uma entrega canônica do pedido (missão reconhece, não recolhe queijo outra vez).

Bônus de milho 4/trigo 6 das missões iniciais preservados como primeiro lote demonstrativo. Crescimento dos animais é opcional; história funciona com um de cada. Mostrar capacidade necessária para lote antes de alimentar vários.

## F. Nina, Guia e oficina (16–17)

Na etapa 16 retirar `nina_rare` da cadeia principal: line `nina_discoveries`, order 10, requisito nina_walk. Petshop passa a exigir nina_routes, não raro. `nina_petshop` continua order 50; roupas/costura/amigos/truques mantêm sequência e IDs. Nina_friends e nina_roll continuam opcionais; nenhuma história principal exige janela de amigo específica, raro ou três truques.

Na etapa 17 criar linha `workshop`, npc guide, requisito atelier_open. **`workshop_toy`10**: produce:braided_toy1, prêmio 10; **`workshop_first_set`20**: produce:accessory_set1 sem fresh, prêmio iron_band1; **`workshop_picnic`30**: produce:picnic_pack1, prêmio 10. Não criar uma Artesã nova no mapa nesta rodada. Os três itens já têm receitas disponíveis antes dos respectivos objetivos.

Adicionar **`nina_blueberry`10**, na linha própria nina_flavors (npc Nina), requisito treasure 1 + owned:greenhouse: realizar desejo blueberry_treat uma vez (`wish_item:blueberry_treat` novo contador gravado pelo fulfill, não qualquer feed), prêmio affection 8. Enquanto missão ativa, gerador de desejos oferece esse desejo no próximo espaço elegível sem taxa/sorte, sem apagar desejo atual; troca não consome ingredientes. Se jogador já realizou antes, conta. Não bloqueia campanha.

## G. Projetos e capítulos 10–12 (20–22)

Etapa 20 lança banco como projeto lateral pós-atelier_open; 21 jardim/piquenique; somente 22 acrescenta capítulos principais 10–12 com os projetos já funcionando. IDs de projetos são distintos de missões e contratos. O recurso goal `project` consulta conclusão persistente, não owned ou pedido de mesmo nome.

| Capítulo novo | Missão principal/ordem | Objetivo canônico | Prêmio da missão |
|---|---|---|---|
|10 Um lugar para descansar | community_10_meet/10 | talk:lais 1 fresh, requisito atelier_open | 0 |
|10 | community_10_bench/20 | project:park_bench1 | 0 |
|10 | community_10_use/30 | stat project_use:park_bench1 | affection 5 |
|11 Um encontro especial | community_11_garden/10 | project:village_garden1 | 0 |
|11 | community_11_picnic/20 | project:park_picnic1 | 0 |
|11 | community_11_tiro/30 | stat project_use:park_picnic1 | affection 5 |
|12 A festa da nossa turma | community_12_prepare/10 | talk:nina 1 fresh | 0 |
|12 | community_12_festival/20 | project:village_festival1 | 0 |
|12 | community_12_memory/30 | stat project_use:village_festival1 | affection 10 |

Cada projeto entrega seu prêmio uma vez ao concluir; missões só reconhecem. Capítulos 10/11/12 dão 30/40/60 moedas, sem segundo pacote dos mesmos materiais. Ao inserir capítulos, atualizar final_chapter e qualquer constante do final. Save que já fez projeto lateral reconhece a conclusão, mas interação `project_use` só conta se já realizada; não exigir pagar obra outra vez. Campanha antiga não retrocede por novas missões 1–9.

## H. Inventário de novidades e estágios donos

Novas missões: guide_open_cave07; storage_first_planks07; storage_first_delivery07; merchant_variety13; bloblo_breakfast14; workshop_toy/workshop_first_set/workshop_picnic17; nina_blueberry17; nove principais community_10/11/12 na etapa 22. Não adicionar novos IDs por conta própria para inflar a quantidade. Textos devem ter motivo/personagem; as falas podem ser redigidas pelo executor dentro desses objetivos, preservando voz curta e acolhedora.
