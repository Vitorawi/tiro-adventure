# Contrato de execução por agente

## Leia antes

AGENTS.md (Codex) ou CLAUDE.md (Claude Code); Estado atual do ROADMAP; README deste plano; 00_VISAO; este contrato; arquivo da etapa solicitada; documentos comuns indicados nele. Confirme o `git status` e preserve alterações de outras tarefas. Não retome a V0 arquivada.

## Uma etapa, uma entrega

Executar somente a etapa pedida, na ordem 00–24. Cada etapa tem pré-requisito imediatamente anterior. Não criar novos requisitos que dependam de conteúdo de uma etapa futura. Infraestrutura ainda não usada não aparece na interface. Se dependência anterior estiver incompleta, identificar exatamente a lacuna; não marcar etapa como pronta nem passar à seguinte.

O jogo deve continuar funcionando ao final de cada etapa. Não publicar. Commit local apenas quando solicitado ou exigido por instrução vigente; antes de qualquer commit, rodar a suíte completa exigida no mapa do projeto. Não incluir .codex, build, saves ou arquivos privados.

## Autoridade dos arquivos

| Tema | Arquivo autoritativo |
|---|---|
| Escopo e direção | 00_VISAO.md |
| Preços, custos, capacidades, tempos | 02_TABELAS_BALANCEAMENTO.md |
| Ordem, IDs, requisitos, objetivos e prêmios de missões | 03_JORNADA_E_MISSOES.md e 08_MATRIZ_QUESTS.md |
| Experimentos, perfis e aprovação | 04_SIMULACAO_E_ACEITE.md |
| Saves, snapshots, transações e volta do Tiro | 05_SAVES_E_TRANSACOES.md |
| Interface, arte e capturas | 06_INTERFACE_E_ARTE.md |
| Produtos, clientes, maestrias, projetos e rotina | 07_CONTEUDO_E_SISTEMAS.md |
| Desvios medidos depois da R1 | DECISOES.md |

Números repetidos em uma etapa são exemplos; em conflito prevalece a tabela autoritativa e o agente corrige o exemplo. Mudança de objetivo do usuário prevalece sobre tudo. Não copiar números para vários scripts: dados em JSON, estado em classes, ações no GameState e UI apenas apresenta/chama ações.

## R1 executável, calibrável

Implementar os valores R1 atribuídos à etapa, sem pedir confirmação de cada escolha. São alvos iniciais para teste, não resultado de playtest. Se um critério falhar, seguir o protocolo da seção G de 04_SIMULACAO_E_ACEITE: investigar regra/política antes de mexer em números; ajustar uma família por vez; documentar e repetir cenários afetados. Não relaxar assert para aprovar regressão. Depois de três rodadas sem resolver, entregar diagnóstico e deixar a etapa em andamento; não inventar validação.

Não há liberdade para criar moeda, novo mundo, retirar saves ou adicionar trava de calendário. Ajustes dentro do protocolo não precisam de nova aprovação. Mudança desse escopo deve ser registrada como proposta, sem implementar silenciosamente.

## Persistência e interface

Preservar IDs existentes e seus `.uid/.import`; mudanças de linha/NPC não renomeiam ID da missão. Novos campos têm reset/serialização/migração e teste idempotente. Estoque nunca evapora. Trabalhos iniciados conservam contratos; permissões prod/dev continuam separadas.

Reutilizar UiKit, Palette, Motion, Sheet, StationTray, ActionTray, MarketUi e ModalCard. Não redesenhar HUD, abas, câmera ou gestos. Alvos de toque, nomes de nós usados nos testes e glossário do plano Interface permanecem. No máximo quatro lugares visíveis por mundo; acessos secundários podem ser `hidden` e existir no objeto correspondente.

## Testes e evidência

Cada etapa define casos comportamentais e suítes focadas. Fixtures unitárias podem montar estado; simulações de alcançabilidade/ritmo não podem conceder recursos ou desativar limite. Instrumento não é prova de experiência subjetiva.

Mudança visual: capturar antes/depois, abrir PNGs e inspecionar em 360×780, 390×844 e 412×915. Mudança de interação: ao menos um teste real de toque da ação. Sem mudança visual, não repetir tour inteiro. Testes novos entram em tools/test_all.ps 1. Rodar suíte completa nos marcos 08, 13, 18, 22 e 24, e antes de qualquer commit. Falha histórica precisa de reprodução e descrição; timeout não é PASS.

## Encerramento obrigatório

Atualizar README (pendente/em andamento/concluída com data), DECISOES quando houver ajuste, Estado atual do ROADMAP com resultado/evidência/pendência/próxima etapa. Atualizar PROGRESSION/GAME_DESIGN apenas com comportamento implementado. Mudou arquitetura? AGENTS e CLAUDE ficam idênticos. Arte nova vai ao ART_PIPELINE.

Entrega ao Vitor: efeito para jogador, arquivos principais, testes efetivamente executados, limitações e próxima etapa. Nada de dizer que toda economia está balanceada porque um trecho passou.
