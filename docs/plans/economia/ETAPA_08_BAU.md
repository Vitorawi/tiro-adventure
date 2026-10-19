# Etapa 08 — Limitar bagagem junto dos passeios

**Estado: concluída (17/10/2026, Claude Code).** Executar somente esta etapa. Pré-requisito: Etapas 00–07 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção A; 03 seção B/Nina; 05 passeio; 06; walks.json, finds.json, items.json, Nina e treasure.

## Entrega e implementação

1. Ativar sacola provisória 12, baú 24, _2 total 40, _3 total 64. Baú sem moeda, stick 2 e requisito nina_walk. Mover `bloblo_chest` para NPC/linha nina ordem 25, entre nina_walk e nina_routes; prêmio 10 moedas sem bolt.
2. Mapear os 11 materiais da categoria trail para chest por override, incluindo wild_mint. Coleções/achados de álbum/pedaços do mapa continuam isentos; produtos treat_box/accessory_set também usam chest. Não limitar todos os finds indiscriminadamente.
3. Garantir 2 gravetos no primeiro retorno elegível que conduz ao baú, com mecanismo determinístico do passeio existente, não dado aleatório. Se já existirem 2 ou o jogador já tiver baú, não duplicar concessão retroativa. Save antigo sem baú e sem gravetos precisa de próxima rota inicial com fonte garantida até reunir 2; regra encerra com compra. Não vender automaticamente os gravetos.
4. Ajustar sacola/baú no mapa e Mochila, requisito Nina e cadeia de ajuda. Limite não prende Tiro, porque a 03 já está concluída. Simular retorno com 12/12 e bagagem mista; materiais aguardam, mapa/coleções seguem seu contrato.
5. Consolidar testes dos quatro depósitos e primeira rodada completa de regressão. Registrar taxa de bloqueio por estoque e número de saídas recuperáveis; não aumentar limites para ocultar perda de recompensa.

## Verificação obrigatória

Primeiro passeio de save novo;2 gravetos; construir baú; bagagem acima do espaço; coletar parcela/reload; passeios antigos completos;11 tipos trail; itens isentos; costura e consumos no baú. Rodar suítes completas do projeto e experimento de armazenamento 04. Conferir UI de limite antes/depois das compras nas três resoluções.

## Critérios de conclusão

Todos os recursos armazenáveis têm limite desde o primeiro recebimento, e há saída recuperável para cada bloqueio. Nenhum caso de Tiro permanentemente ausente. Gate: regressões resolvidas e logs antes da 09.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_08/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
