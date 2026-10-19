# Etapa 00 — Auditar o jogo e congelar a linha de base

**Estado: concluída em 17/10/2026** (resultado em [BASELINE.md](BASELINE.md)). Executar somente esta etapa. Pré-requisito: Nenhuma. Esta etapa só mede o estado atual.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

02_TABELAS_BALANCEAMENTO, 03_JORNADA_E_MISSOES, 04_SIMULACAO_E_ACEITE; relatório de pesquisa; docs/PROGRESSION.md; game/data/*.json; GameState, ProgressionState, Inventory e StationState.

## Entrega e implementação

1. Registrar branch, HEAD, versão de save, diff e alterações locais já presentes. Não limpar nem incorporar trabalho alheio por conveniência. Produzir manifesto de arquivos usados e hash dos dados; a execução do plano começa no estado real, não numa cópia idealizada da pesquisa.
2. Criar `tools/economy_audit.py`, usando biblioteca padrão, para ler JSON e gerar relatório Markdown + dados JSON em build/economy/baseline. Listar todas as fontes/sumidouros de moedas, preços, ingredientes, saídas por lote, tempos, requisitos, filas, capacidades, categorias isentas, recompensas de missões/capítulos/vínculo/rotinas/passeios. Resolver referências e ciclos de requisitos. Não estimar taxas de uso desconhecidas como fatos.
3. Mapear grafo real de missões (inclusive `shared_with`, ordem de linha, chapter, requisitos de compras/receitas). Anotar 81 IDs atuais e diferenças desde esta R1. Verificar moedas de compra→recompensa e receita→intermediário→venda por lote. Incluir perda de oportunidade ao transformar ingredientes, não só custo de plantio zero.
4. Confirmar todas as suposições críticas: capacidade só ativa após compra, receita produz múltiplas unidades, vagas sequenciais, carinho com guarda UI, colheita com moeda, fontes de bolt/iron_band e disponibilidade da venda inicial. Auditar `farm_breakfast` existente, item `egg` versus receita `eggs`, IDs das estações e campos de XP.
5. Criar relatório versionado `docs/plans/economia/BASELINE.md` com números reais e método; saídas volumosas ficam em build. Se código mudou desde a redação, corrigir somente referências factuais e registrar impacto; não aplicar tabelas de balanceamento nesta etapa.

## Verificação obrigatória

Executar auditor duas vezes: resultados determinísticos salvo metadados de execução. Conferir manualmente cenoura, apple_biscuit (saída 2), treat_box, farm_breakfast e banco de recompensas. Testar erro de ID/requisito ausente com fixture temporária; não alterar dados do jogo para fabricar falha. Executar validação de conteúdo já existente para distinguir falhas prévias.

## Critérios de conclusão

BASELINE identifica estado auditado, fontes e incertezas; nenhum JSON de balanceamento alterado; toda divergência do plano tem destino explícito em DECISOES. O agente seguinte sabe os comandos corretos do Godot e testes deste computador.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Entregar BASELINE.md, comando do auditor, relatório de referências/ciclos e manifesto em build/economy/baseline. Não copiar saves privados do usuário para o git.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.
