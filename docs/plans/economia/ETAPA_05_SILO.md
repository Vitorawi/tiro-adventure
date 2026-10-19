# Etapa 05 — Introduzir espaço finito junto da primeira horta

**Estado: concluída (17/10/2026, Claude Code).** Executar somente esta etapa. Pré-requisito: Etapas 00–04 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção A; 03 seção B/Bloblo; 05 capacidade/migração; 06 depósitos; InventoryList, PlotTray, harvest_error.

## Entrega e implementação

1. Ativar provisório 16 e silo construído 32; _2 total 56, _3 total 88 com incrementos corretos. Aplicar custo/requisitos das ampliações existentes na 02, sem criar _4/_5 ainda. Novos jogos já contam toda cultura no silo, inclusive maçã.
2. Recuperar silo gratuitamente após first_harvest, sem material. Mover ID `bloblo_silo` para ordem 27 da linha Bloblo, depois do faro 25 e antes de mais colheitas 30; objetivo owned:silo, moedas 10, retirar bolt dessa missão. Preservar recebida em saves antigos.
3. Mostrar “Cesto da horta” antes do silo; compra transforma visual/nome e amplia mesmo havendo itens. Fixar requisitos do lugar/objeto/balão para apresentar no mesmo momento da missão, não continuar escondido atrás de queijo.
4. Caminho com cheio: manter planta madura; venda inicial continua após conhecer Bloblo; ao vender/usar espaço a colheita volta a ser permitida. Coletar Tudo valida cada lote sem perder o que não cabe, comunica quantos ficaram prontos. Não dar saldo/moedas/XP de colheita rejeitada.
5. Atualizar falas de primeira horta e ajuda do silo; não abrir tutorial dos outros três depósitos juntos.

## Verificação obrigatória

Save novo com duas/quatro parcelas; encher provisório antes de comprar; comprar cheio; colher lote exato e lote+1; Colher Tudo parcial; vender e recuperar. Legado silo 40 não reduz para 32 por causa do piso; sem silo e estoque 100 preserva 100, bloqueia entradas e permite saída. Rodar cenário inicial sem dev até cozinha.

## Critérios de conclusão

O jogador encontra limite e expansão na primeira horta sem ficar preso. Apenas a categoria silo passa a ser finita nesta etapa; _2/_3 têm preço e pré-requisito coerentes mesmo antes de missões de apoio da 07.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_05/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
