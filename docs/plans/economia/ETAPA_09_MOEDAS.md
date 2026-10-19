# Etapa 09 — Reorganizar as fontes de renda e corrigir transformação

**Estado: concluída (18/10/2026, Claude Code).** Evidência em `build/economy/etapa_09/` e em DECISOES. Executar somente esta etapa. Pré-requisito: Etapas 00–08 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02 seção B; BASELINE; 04; crops/activities/items/quests/progression; _apply_rewards e venda inicial.

## Entrega e implementação

1. Zerar moedas de todas as colheitas e das atividades produtivas de Natureza; manter itens/XP/tempos por enquanto. Não zerar prêmios de passeios narrativos/achados sem estar na tabela. Plantar/regar continua gratuito.
2. Corrigir venda de apple_biscuit para 30 por unidade, treat_box para 140; special_order 600 e festival_contract 940. Atualizar UI/ajuda que exibe preço derivado, não copiar números em falas. Recalcular margens de toda cadeia considerando saída 2 do biscoito.
3. Ajustar prêmios pontuais merchant_stall 30, atelier_open 40, bloblo_biggest 40; capítulos 1–9 para 10/20/30/40/60/60/60/80/80. Preservar itens/XP e pagamentos antigos. Não aplicar compensação negativa a quem já recebeu. Níveis 2–10 mantidos; acima 10 usar fórmula min(80,20+3*nível) orientada a dados, se hoje houver presente padrão maior.
4. Identificar todas as fontes de moedas no ledger, incluindo diário, vínculo, desejo, visitante e achado. As mudanças de desejo/vínculo só vêm na 16; medir contribuição transitória sem “corrigir” sistemas fora da etapa.
5. Jogador com zero moeda/estoque pode plantar gratuito, colher, vender em early_market e recuperar. Nenhuma compra obrigatória exige moeda antes dessa rota. Atualizar mensagem que prometia moeda direta da planta.

## Verificação obrigatória

Testes sem moeda em harvest, nenhuma recompensa parcial em erro, venda disponível cedo, preços lote/unidade, contrato 3 caixas 600 versus venda 420 e contrato festival 940 versus insumos calculados. Executar perfis referência/comercial/recuperação em baseline e patch, reportar origem do saldo e primeira compra; não exigir janela final antes de tempos/custos revisados.

## Critérios de conclusão

Renda recorrente vem principalmente de vender/entregar, transformação caixa não destrói valor imediato, recuperação funciona. Evidência quantifica redução das recompensas únicas; nenhuma economia “validada” apenas por cálculos.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_09/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
