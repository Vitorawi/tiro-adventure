# Matriz completa de missões — baseline e delta R1

Inventário congelado na redação: **81 missões existentes, 31 principais e 50 de linhas; 18 novas planejadas, total99 (40 principais e59 de linhas)**. A etapa00 confere se houve mudança posterior. Não renomear IDs antigos. Cada linha abaixo define o delta; objetivo/requisito/prêmio não citado permanece exatamente como no JSON, exceto regras gerais de transação/snapshot. “Manter” é decisão explícita, não trabalho esquecido.

## Regras de migração comuns

Concluída/recebida permanece assim; não cobrar diferença nem pagar de novo. Ao mover linha/ordem, preservar ID, contador, estado e base fresh aplicável. Alias recebe orientação, a canônica é a única entrega/prêmio. Remover prêmio próprio de novos aliases para recebimentos futuros. Para missões com item de recompensa alterado, preservar apenas o que já foi recebido; pendente aplica snapshot da missão ativa se existente, e a migração02 registra qual política herdada foi congelada. Não subtrair item do inventário antigo. A matriz e03 devem mudar juntas quando uma decisão mudar.

## Todos os IDs existentes

| ID | Local/ordem atual | Etapa | Delta R1 |
|---|---|---|---|
| `welcome` | capítulo 1 / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_feed` | capítulo 1 / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_bath` | capítulo 1 / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_play` | capítulo 1 / 40 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_bag` | capítulo 1 / 50 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_bed` | capítulo 1 / 60 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_meet_bloblo` | capítulo 2 / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_first_crops` | capítulo 2 / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_2_fridge` | capítulo 3 / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `first_kitchen` | capítulo 3 / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_blender` | capítulo 3 / 25 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_stew` | capítulo 3 / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_village` | capítulo 4 / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `first_sale` | capítulo 4 / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_2_order` | capítulo 4 / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `lais_forest` | capítulo 5 / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_4_materials` | capítulo 5 / 20 | 07 | have:wood6 + owned:warehouse; não consome; demais prêmios iguais. |
| `main_4_bench` | capítulo 5 / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_5_pickaxe` | capítulo 6 / 10 | 13 | shared_with:guide_open_cave; goal quest da mesma canônica; remover prêmio próprio e entrega duplicada. |
| `stone_path` | capítulo 6 / 20 | 13 | shared_with:guide_stone; goal quest da mesma canônica; remover prêmio próprio. |
| `main_5_cooking` | capítulo 6 / 30 | 13 | stat produce:carrot_snack2 + produce:vegetable_soup1 + produce:strawberry_juice1; todos históricos, sem fresh. |
| `main_5_bricks` | capítulo 6 / 40 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `market_day` | capítulo 7 / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_6_commerce` | capítulo 7 / 20 | 13 | shared_with:merchant_variety; goal quest da canônica; remover prêmio próprio. |
| `own_business` | capítulo 7 / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_7_orchard` | capítulo 8 / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `deep_earth` | capítulo 8 / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_7_greenhouse` | capítulo 8 / 30 | 13 | owned:greenhouse + stat harvest:herbs1 histórico; cultura liberada pela estufa sem Horta5. |
| `main_8_fiber` | capítulo 9 / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_8_building` | capítulo 9 / 20 | 13 | Manter produce:plank6, retirar fresh; reconhecer aprendizado anterior. |
| `atelier_open` | capítulo 9 / 30 | 09/13 | coins40 na09; na13 owned:atelier + produce:fabric2 + produce:accessory_set1 históricos; demais efeitos mantidos. |
| `bloblo_meet` | bloblo / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `first_harvest` | bloblo / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_sell_surplus` | bloblo / 22 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_dig` | bloblo / 25 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_more_crops` | bloblo / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_carrots` | bloblo / 40 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_potato` | bloblo / 50 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_stew` | bloblo / 60 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_strawberry` | bloblo / 62 | 10 | Mover para flavors/10, requisito first_kitchen; objetivo/prêmio mantidos. |
| `bloblo_pumpkin` | bloblo / 65 | 10 | Mover para flavors/20; objetivo/prêmio mantidos; entrada da linha first_kitchen. |
| `farm_deed` | bloblo / 70 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_sweet_potato` | bloblo / 75 | 10 | Mover para flavors/30; requisito extra farm_deed; objetivo/prêmio mantidos. |
| `main_9_coop` | bloblo / 80 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_9_eggs` | bloblo / 90 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_9_cows` | bloblo / 100 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_milk` | bloblo / 110 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `main_9_flour` | bloblo / 120 | 14 | owned:mill + produce:flour2, retirar fresh; não duplicar entrega de farinha. |
| `main_9_cheese` | bloblo / 130 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `bloblo_silo` | bloblo / 140 | 05 | Bloblo/27; owned:silo; coins10, sem bolt; silo grátis após first_harvest. |
| `bloblo_warehouse` | bloblo / 150 | 07 | Mover NPC/linha para guide/25; owned:warehouse; coins10; fala do Guia. |
| `bloblo_chest` | bloblo / 160 | 08 | Mover NPC/linha para nina/25; owned:chest; coins10, sem bolt. |
| `bloblo_bigger` | bloblo / 170 | 07 | Mover para storage/30; stat storage_upgrades1; coins15 + bolt2; remover demais itens futuros. Nome Mais espaço onde importa. |
| `bloblo_biggest` | bloblo / 180 | 07/09 | Mover para storage/40; stat storage_upgrades3; coins40 + bolt1; remover demais itens futuros. Nome Uma casa organizada. |
| `guide_meet` | guide / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `guide_wood` | guide / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `guide_stone` | guide / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `guide_fibers` | guide / 40 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `guide_treasure` | guide / 50 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `merchant_meet` | merchant / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `merchant_first_sale` | merchant / 15 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `merchant_surplus` | merchant / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `merchant_orders` | merchant / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `merchant_regular` | merchant / 40 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `merchant_stall` | merchant / 50 | 09 | coins30; objetivo e shared_with de own_business preservados. |
| `merchant_contracts` | merchant / 60 | 15 | stat contracts6 histórico, atualizar fala/meta; requisito de diversidade2 fica na compra stall_2. |
| `merchant_expand` | merchant / 70 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `merchant_clients` | merchant / 80 | 15 | stat contracts15 histórico, atualizar fala/meta; diversidade3 fica na compra stall_3. |
| `merchant_village_stall` | merchant / 90 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `merchant_festival` | merchant / 100 | 22 | Mesmo ID/objetivo order:festival_contract1; ajustar nome/fala para Encomenda para eventos, distinguindo da obra Festa. |
| `nina_meet` | nina / 10 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `nina_walk` | nina / 20 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `nina_routes` | nina / 30 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `nina_rare` | nina / 40 | 16 | Mover para nina_discoveries/10, requisito nina_walk; objetivo/prêmio mantidos; nunca requisito de petshop. |
| `nina_petshop` | nina / 50 | 16 | Manter nina/50 e objetivo; substituir dependência de nina_rare por nina_routes em compra/missão/ajuda. |
| `nina_dress` | nina / 60 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `nina_sewing` | nina / 70 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `nina_pipoca` | nina / 80 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `nina_trick` | nina / 90 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `nina_friends` | nina / 100 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |
| `nina_roll` | nina / 110 | 13 revisão | Manter ID, localização, objetivo, requisitos e recompensa; revisar apenas clareza do texto/Ir se o entorno mudou. |

## Novos IDs — cadastrar somente na etapa dona

Todos usam os verbos/sintaxe existentes: owned, stat, quest, ou project introduzido na19. Valores de recompensa omitidos são zero; não herdar pacote padrão por conveniência. A linha libera pelo requisito da primeira missão e pelas ordens já suportadas. Objetivos não marcados fresh reconhecem histórico. Os nomes abaixo são rótulos iniciais; falas finais curtas são responsabilidade da etapa dona.

| ID / nome | Etapa | NPC · linha/capítulo · ordem | Requisito extra | Objetivo | Prêmio |
|---|---|---|---|---|---|
| `guide_open_cave` — Um caminho pelas pedras | 07 | guide · guide ·22 | lais_forest e sequência guide_wood | owned:cave_open | coins5 |
| `storage_first_planks` — Peças para ampliar | 07 | bloblo · storage ·10 | main_4_bench | stat produce:plank2 fresh | bolt1 |
| `storage_first_delivery` — Uma peça da vizinhança | 07 | bloblo · storage ·20 | anterior da linha | stat orders1 fresh | bolt1 |
| `merchant_variety` — Dois sabores na feira | 13 | merchant · merchant ·45 | anterior da linha | stat order:vegetables1 + order:snacks1 | coins10 |
| `bloblo_breakfast` — Café da nossa fazenda | 14 | bloblo · bloblo ·140 | main_9_cheese | stat order:farm_breakfast1 | coins15 |
| `workshop_toy` — Um brinquedo para o Tiro | 17 | guide · workshop ·10 | atelier_open | stat produce:braided_toy1 | coins10 |
| `workshop_first_set` — Peças para os próximos planos | 17 | guide · workshop ·20 | anterior da linha | stat produce:accessory_set1 | iron_band1 |
| `workshop_picnic` — Uma cesta para compartilhar | 17 | guide · workshop ·30 | anterior da linha | stat produce:picnic_pack1 | coins10 |
| `nina_blueberry` — O sabor da descoberta | 17 | nina · nina_flavors ·10 | stat treasure1 + owned:greenhouse | stat wish_item:blueberry_treat1 | affection8 |
| `community_10_meet` — Um lugar para a nossa turma | 22 | lais · capítulo10 ·10 | atelier_open | stat talk:lais1 fresh | zero |
| `community_10_bench` — Um banco para descansar | 22 | lais · capítulo10 ·20 | ordem da história | project park_bench1 | zero |
| `community_10_use` — Senta aqui comigo | 22 | lais · capítulo10 ·30 | ordem da história | stat project_use:park_bench1 | affection5 |
| `community_11_garden` — A vila floresce | 22 | lais · capítulo11 ·10 | capítulo10 completo | project village_garden1 | zero |
| `community_11_picnic` — Vamos preparar um encontro | 22 | lais · capítulo11 ·20 | ordem da história | project park_picnic1 | zero |
| `community_11_tiro` — Nossa tarde juntos | 22 | lais · capítulo11 ·30 | ordem da história | stat project_use:park_picnic1 | affection5 |
| `community_12_prepare` — Uma festa para a turma | 22 | nina · capítulo12 ·10 | capítulo11 completo | stat talk:nina1 fresh | zero |
| `community_12_festival` — A festa da vila | 22 | lais · capítulo12 ·20 | ordem da história | project village_festival1 | zero |
| `community_12_memory` — Uma lembrança da nossa turma | 22 | lais · capítulo12 ·30 | ordem da história | stat project_use:village_festival1 | affection10 |

## Conferência obrigatória

- Existentes81 + novos18 =99; main31 + novos9 =40. Se a baseline mudou, registrar diferença por ID, não apagar conteúdo para bater contagem.
- Linha Nina rara e linha Nina mirtilo são independentes; a missão de mirtilo não espera um raro.
- storage_upgrades deriva de ampliações _2+, qualquer depósito; recompensas antigas excessivas não permanecem nos novos recebimentos.
- main_9_coop/eggs/cows/flour/cheese são IDs de linha Bloblo, não capítulo9. Não migrar para main por causa do prefixo.
- Inserir nove missões de projetos só na22; 19–21 são sistemas e obras laterais. Obra já concluída é reconhecida quando capítulo entrar.
- Textos de “máximo” e “fim da história” mudam quando entram ampliações/capítulos; sem criar outro prêmio para a mesma realização.
