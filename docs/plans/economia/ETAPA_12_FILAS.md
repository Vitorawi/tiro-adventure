# Etapa 12 — Dar autonomia com filas e preparo de vários lotes

**Estado: concluída (18/10/2026, Claude Code).** Evidência em `build/economy/etapa_12/`; registro em DECISOES. Executar somente esta etapa. Pré-requisito: Etapas 00–11 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção D; 05 transação/snapshot; 06 produção; StationState e StationTray; receitas de animais separadas.

## Entrega e implementação

1. Aplicar tempos de receitas existentes da 02, preservando ingredientes/rendimentos. Costura fica igual; receitas em andamento/fila usam snapshot 02. Valores de ovos/leite são duração do lote, não tempo por animal.
2. Ajustar stove_queue/stove_queue_2 como tabela e criar blender_queue. Mesmo tipo de vaga atual: fila sequencial. Primeiro fogão pode ter autonomia cedo após first_kitchen; filas finais de moinho/queijaria/ateliê ficam na 18.
3. Implementar `Preparar N` para receitas comuns: calcular vagas livres e ingredientes totais, validar antes de consumir, criar N jobs individuais com timestamps encadeados e snapshots. Se falta qualquer ingrediente/vaga, não enfileirar uma parte silenciosamente. N=1 usa o mesmo caminho de código.
4. UI permite quantidade 1..máximo, total de ingredientes/saídas e último horário. Colher mantém contratos atuais; selecionar receita não começa a produção. Não tratar animal qty como N receitas, nem alimentar animal novo num lote antigo.
5. Relatório de autonomia por estação: tempo de fila ocupada, produtos disponíveis na volta, ações exigidas por produto e dinheiro reservado. Não criar processamento paralelo nem exigir que toda máquina tenha seis horas de fila.

## Verificação obrigatória

N 1/Nmáximo/Nmáximo+1, ingredientes insuficientes em último lote, reload no meio, colher primeiro e enfileirar outro, fila de receitas diferentes, output_collection, animais comprados durante lote. Verificar uso de inputs uma vez, XP por recebimento, tempo acumulado correto; comparação de visitas 1 × 10/3 × 10 e interface360 px.

## Critérios de conclusão

Fila é inteligível e útil para retornar; múltiplos lotes não burlam espaço, cooldown ou economia. Todas as receitas antigas mantêm saída e ingredientes corretos, inclusive biscoito 2 e farinha 2.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_12/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
