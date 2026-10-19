> **RASCUNHO PAUSADO — 16/10/2026, por pedido do Vitor. Não executar.** Números, produtos e critérios abaixo não estão aprovados. Conteúdo preliminar preservado para revisão após o estudo [Economia e ritmo do Tiro](../../../reports/Economia%20e%20ritmo%20do%20Tiro.md). Consulte o [estado do planejamento](README.md).

# Regras para executar uma etapa

## Antes de editar

1. Ler `AGENTS.md` (Codex) ou `CLAUDE.md` (Claude Code), `docs/ROADMAP.md → Estado atual`, [README](README.md), [visão](00_VISAO.md), este arquivo e o arquivo da etapa solicitada.
2. Conferir `git status`; não descartar, incluir em commit ou reformatar trabalho alheio sem necessidade. Na criação deste plano havia alterações locais de avisos de prontos e testes associados.
3. Confirmar etapas anteriores concluídas por evidência, não só uma caixa marcada. Se faltar dependência, registrar o ponto concreto; não executar várias etapas por conta própria.
4. Ler os contratos comuns indicados pela etapa. Caminhos sob `game/` são existentes salvo quando marcados **novo**. APIs propostas são sugestões de responsabilidade, não afirmação de que existem.
5. Registrar o estado anterior em `build/economy/etapa_NN/`. Não ler/escrever saves pessoais para testar; usar fixtures sintéticas e remover SaveManager do SceneTree de teste antes de mutar estado.

## Fonte única de decisões

| Assunto | Fonte |
|---|---|
| Objetivos e limites de escopo | `00_VISAO.md` |
| Capacidades, preços, receitas, tempos, recompensas | `02_TABELAS_BALANCEAMENTO.md` |
| IDs, ordem, requisitos e novos capítulos | `03_JORNADA_E_MISSOES.md` |
| Métricas, perfis, casos de bloqueio | `04_SIMULACAO_E_ACEITE.md` |
| Persistência e compatibilidade | `05_SAVES_E_TRANSACOES.md` |
| Arte e interface | `06_INTERFACE_E_ARTE.md` |
| Ajustes posteriores ao plano | `DECISOES.md` |

Valores são a **versão candidata V0**: implementar somente as linhas atribuídas à etapa, medir e ajustar quando os critérios pedirem. Não são balanceamento comprovado. Ao mudar número, atualizar sua linha na tabela, registrar antes/depois e motivo em `DECISOES.md` e rodar novamente só os cenários afetados. Não manter outra cópia divergente em cada etapa.

Se a regra inviabiliza uma compra, coleta, receita ou missão, resolver nessa etapa. Não deixar a campanha quebrada aguardando uma etapa futura. Requisitos que apontam para IDs futuros só entram junto com esses IDs. Conteúdo ainda não implementado fica apenas neste plano, não como botão sem função no jogo.

## Fronteiras

- Uma etapa por solicitação; nunca push/deploy automático. Não gerar arte nem implementar mecânicas durante a mera leitura do plano.
- Não aumentar todos os preços ou tempos por um fator global. Cada ajuste deve ter efeito esperado e comparação com a fase anterior.
- Não inserir contador diário/tempo de conta para obrigar a duração prevista. Metas de calendário são observações do perfil de sessões.
- Não alterar aparência geral, abas, câmera, controles de arrasto, glossário ou padrões de comemoração. Reutilizar `UiKit`, `Sheet`, `ActionTray`, `MarketUi`, `ModalCard`, `Palette`, `Motion` e `TaskHelp`.
- Preservar IDs de itens, construções, missões e receitas existentes. Novos IDs usam prefixos/nomes deste plano. Preservar `shared_with`, entrega única e reconhecimento de progresso anterior.
- GDScript tipado; conteúdo/números em JSON, não espalhados nos scripts. Helpers de testes e relatórios não entram no export.
- Arte nova por PixelLab, conforme o projeto. Só produzir na etapa dona da arte. Não reutilizar ícone de outro item com nome diferente no resultado final.
- Refatorar apenas o necessário. Separar regra pura de UI. Classes de estado não dependem de painel nem autoload de apresentação.

## Economia segura

Não existe moeda negativa, perda silenciosa, venda automática, estoque infinito disfarçado de presentes, prêmio duplicado, produção já iniciada alongada retroativamente, personagem inacessível necessário para destravar o próprio acesso ou receita obrigatória exigindo o produto que ela libera.

Novos itens sempre têm origem alcançável, destino, categoria, capacidade suficiente para um lote, ícone, texto, ajuda e pelo menos um uso recorrente quando forem comerciais. Expansão precisa ter demanda antes do fim. Nenhuma compra essencial depende apenas de recompensa aleatória ou semanal.

## Verificação proporcional

- Etapas só de instrumentos: checagem headless e testes do instrumento; não exigir tour inteiro sem mudança visual.
- Mudança de regra: teste de comportamento real + regressões das ações afetadas + simulação curta do começo/trecho; fixture isolada é permitida para teste unitário, mas não prova alcançabilidade.
- Mudança de UI: capturas antes/depois em 360×780, 390×844 e 412×915; abrir as imagens e conferir cortes; exercitar toque real da ação nova, não só método por script.
- Teste novo entra em `tools/test_all.ps1`; evitar asserts que só espelham um número e não detectam falha de regra. As tabelas de conteúdo têm auditoria própria.
- Antes de qualquer commit, seguir a regra do projeto de suíte completa. Sem commit, rodar o conjunto específico de cada etapa; rodar suíte completa nos marcos 06, 11, 16, 20 e 23. Em caso de falha antiga, registrar reprodução e não chamá-la de PASS.
- Teste lento pode ser executado individualmente; timeout não significa sucesso. Guardar saída e comando. Não afrouxar critérios para fabricar aprovação.

## Passagem de bastão obrigatória

No fim, registrar em `docs/ROADMAP.md`: etapa, mudanças, números adotados, versões de migração, testes realmente executados, capturas abertas, pendências e próxima etapa. Atualizar o andamento do README apenas se todos os critérios essenciais passaram. Caso parcial, marcar **em andamento**, listar o que falta e não avançar.

Mudou arquitetura? Atualizar AGENTS/CLAUDE com conteúdo idêntico e o documento de sistema relevante. Mudou arte? Atualizar ART_PIPELINE. Mudou regra definitiva? Atualizar PROGRESSION/GAME_DESIGN sem apresentar o restante do plano como implementado.

Final ao Vitor: o que a pessoa perceberá, verificações, limitações reais e caminho para continuar. Commit local só se solicitado ou conforme instrução vigente; nunca incluir `.codex/`, saves, `build/` ou segredos.
