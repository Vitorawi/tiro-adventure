# Etapa 10 — Criar colheitas para visitas curtas e para a volta

**Estado: concluída em 18/10/2026 (Claude Code), ver DECISOES.** Executar somente esta etapa. Pré-requisito: Etapas 00–09 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção C; 03 seção C; 04; crops.json/config farm e requisitos das receitas.

## Entrega e implementação

1. Aplicar tempos/saídas/XP Horta exatos da 02, preservando requisitos não explicitamente trocados e snapshots de plantas já iniciadas. Custos das cinco expansões da horta 80/140/220/340/500, sem mudar índices nem presente de canteiros.
2. Manter rega 30% do tempo restante e fator estufa 0,7. Auditar aplicação única: não compor o bônus duas vezes ao carregar, transferir cena ou reaplicar ação. Interface deve mostrar tempo efetivo de cada cultura e retorno previsto, sem prometer rendimento aumentado por rega.
3. Desacoplar tutorial de sabores: bloblo_strawberry/pumpkin/sweet_potato vão para linha `flavors`, ordens 10/20/30. Entrada após first_kitchen, batata-doce também farm_deed. Requisitos de culturas: morango bloblo_dig, abóbora bloblo_potato, batata-doce farm_deed. Retirar gates circulares em que plantar exige terminar missão de colher a própria planta.
4. No caminho principal, preservar ensopado/carrot/potato; não exigir aguardar abóbora1 h para acessar escritura. Nas linhas opcionais, mostrar próximo sabor com origem e tempo sem ocultar horta curta.
5. Medir saídas por visita e espaço: quatro mirtilos produzem 32 unidades e precisam caber com reserva 24 no silo 2=56. Cenoura permanece ferramenta curta; nenhuma produção longa precisa ganhar todas as comparações por minuto.

## Verificação obrigatória

Plantar/regar cada cultura em normal/estufa quando compatível; invalidar plantas exclusivas na área errada. Trocar dados com planta antiga pronta mantém snapshot. Percorrer sabores e escritura sem clock-forcing; simular4 lotes longos com reserva, vender e replantar. Comparar atenção/visita, não só moedas/minuto.

## Critérios de conclusão

Horta oferece horizontes distintos com limites comportáveis. Mudanças de linha preservam missões recebidas e não prendem campanha em timer opcional. Manual/lista de sementes mostra os tempos novos.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_10/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
