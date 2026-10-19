# Etapa 06 — Ligar a despensa à cozinha

**Estado: concluída (17/10/2026, Claude Code).** Executar somente esta etapa. Pré-requisito: Etapas 00–05 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção A; 03 início da cozinha; 05 e 06; recipes, item storage, main_2_fridge e first_kitchen.

## Entrega e implementação

1. Ativar despensa provisória 12, geladeira 24, _2 total 40 e _3 total 64. Geladeira 40 moedas, sem material, requisito lais_first_crops. Preservar o encadeamento main_2_fridge→first_kitchen e a compra da própria estação.
2. Classificar explicitamente alimentos e egg/milk/flour/cheese na geladeira; dog_food e outros itens de segurança isentos conforme 02. Nenhum item pode contar duas vezes por categoria+override. Ervas e mirtilo crus continuam silo; futuro petisco será geladeira.
3. Estações prontas não coletam se lote inteiro não cabe; ingredientes consumidos para nova receita liberam espaço normalmente. Prêmios automáticos com comida usam recibo; alimentação tira item do estoque, mesmo quando acima do piso legado.
4. Atualizar detalhe de comida, manual, lista do depósito e feedback de pronto. Não vender comida nem iniciar receita automaticamente para criar espaço. Explicar alimento versus produto industrial com ícone/destino, sem texto técnico.
5. Aplicar ampliações _2/_3 da tabela, preservando piso legado e todas as compras antigas. Nenhum tempo/valor alimentar muda nesta etapa.

## Verificação obrigatória

Cozinha inicial inteira desde save novo sem recargas dev; inventário 12→24; coleta qty 2 no espaço 1 deve bloquear sem XP. Missão que entrega comida e recebe itens valida o saldo pós-entrega; alimentação libera espaço; snapshot de comida pendente mantém saída. Verificar receitas de farinha/leite e presente de nível cheio.

## Critérios de conclusão

Cozinha ensina estoque de processados; comida básica e cuidados permanecem acessíveis; coleta e recompensa não se perdem. Nenhum depósito de material/passeio é ativado antes de sua etapa.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_06/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
