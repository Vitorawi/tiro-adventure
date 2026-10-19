# Etapa 17 — Adicionar três produtos com usos reais

**Estado: concluída em 18/10/2026 (Claude Code; evidência em build/economy/etapa_17/ e em DECISOES).** Executar somente esta etapa. Pré-requisito: Etapas 00–16 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

07 seçõesA/B/F; 03 seção F; 02 margens; 06 arte; items/recipes/wishes/quests/collections/manual.

## Entrega e implementação

1. Criar braided_toy, picnic_pack, blueberry_treat e receita cut_sticks conforme tabela 07. Conferir IDs, inputs, quantidade de saída, segundos, venda, depósito e requisitos. Preservar ração de emergência emergencial. Gravetos renováveis pela bancada impedem dependência de RNG nos projetos.
2. Adicionar encomendas nina_toys, lais_picnic, nina_blueberries com os valores/requisitos da seção 07. Nenhum pedido nasce visível antes de todas as origens necessárias. Associar cliente e preservar o catálogo antigo.
3. Nova linha workshop do Guia após atelier_open: brinquedo produzido, primeiro conjunto de acessórios histórico com iron_band1 e cesta produzida. Respeitar ordens10/20/30, prêmios da seção 03. Semfresh no conjunto já demonstrado pelo final do capítulo9; missão reconhece o que o jogador fez.
4. Nina opcional mirtilo após tesouro + estufa, goal wish_item:blueberry_treat1, afeto8. Enquanto ativa, garantir desejo de mirtilo na próxima vaga elegível; não substituir pedido atual, gerar ingrediente ou bloquear troca. Entregar incrementa uma vez.
5. Produzir ícones32px com pipeline do projeto; cadastrar manual/origem/destinos e ajuda. Brinquedo não é alimento; cesta não vai ao menu alimentar. Só o petisco tem efeitos alimentares20/10. Testar cadeias com estoque finito e saída longa.
6. Implementar override player_xp de receita com fallback para receitas antigas e snapshot, conforme07A. Nunca somar XP global fixo e override no mesmo recebimento. Mirtilo usa linha independente nina_flavors10, sem raro como requisito.

## Verificação obrigatória

Fabricar cada novidade com insumos reais, vender/entregar/guardar, requisitar antes do unlock, receber em estoque cheio, reload na fila. Cut_sticks não cria ciclo lucrativo de conversão reversa. Mirtilo: tesouro, cultivo, desejo garantido, troca voluntária e contagem única. Auditor compara margem imediata12/34/19 e atenção total com receitas antigas.
Receita antiga mantém XP global do cook; gravetos pagam1, novas receitas8/10/10. Testar snapshot antes de ajuste de player_xp. Nina pode oferecer missão/desejo de mirtilo com contador walk_rare=0, desde que tesouro/estufa estejam concluídos.

## Critérios de conclusão

Cada item tem ao menos um uso recorrente e um narrativo já implementados; nenhuma promessa de projeto futuro é o único uso. Não abrir estação/mundo/NPC novo. Arte final legível e integração completa no manual.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_17/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
