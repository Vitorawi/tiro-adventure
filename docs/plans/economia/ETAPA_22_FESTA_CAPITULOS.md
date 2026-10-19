# Etapa 22 — Concluir nova história com a Festa da Vila

**Estado: concluída em 18/10/2026 (Claude Code), com a ressalva de que `progression_test` foi pulado por decisão do Vitor.** Executar somente esta etapa. Pré-requisito: Etapas 00–21 concluídas; conferir evidências no README/ROADMAP.

## Leitura obrigatória

Mapa do projeto, Estado atual do ROADMAP, README, 00_VISAO, 01_REGRAS_DE_EXECUCAO e:

03 seção G;07village_festival/repetição;06arte/coleção; chapters/final_chapter/quests/celebration.

## Entrega e implementação

1. Cadastrar `village_festival` com requisitos Jardim, Piquenique e `stall_3`, entrada de 500 moedas, fases e prêmio da seção 07E. Diferenciar projeto Festa de `festival_contract`, que continua comercial. Não compartilhar entrega/prêmio nem deixar nomes ambíguos na navegação.
2. Entregar arte final da Festa e coleção `community_ribbon` (“Lenço da nossa turma”), com overlay/âncoras compatíveis e conferência das poses. Festa concluída permanece no mapa; coleção não ocupa baú. Primeiro uso registra evento quando o Tiro participa, sem janela de amigo.
3. Adicionar nove missões principais e capítulos 10–12 da seção 03G, com IDs, ordens e objetivos exatos. Reconhecem projetos/uso sem consumir material novamente. Capítulos pagam 30/40/60 moedas; missões só os afetos listados. Atualizar `final_chapter`, fala do antigo final, lista de história e notificações.
4. Quem concluiu capítulos 1–9 mantém tudo e entra no 10. Quem já fez obras nas etapas 20–21 recebe reconhecimento imediato, sem refazer entregas. Apenas conversas explicitamente marcadas fresh pedem novo toque. Recompensas e eventos consecutivos permanecem idempotentes.
5. Adicionar opção repetível Encontro da turma: intervalo de 24 h após última conclusão, materiais e XP 10 da seção 07E, identidade separada por ciclo. Reutiliza o cenário sem apagar a Festa. Sem afeto, moedas, ferramentas ou inclusão em rotina obrigatória.
6. Executar suíte completa e percurso final de todos os projetos por ações legais. Não concluir a Festa no simulador atribuindo flags diretamente.

## Verificação obrigatória

Novo jogo até o final; legado completo no capítulo 9; obras feitas antes de inserir o capítulo 10; repetição de recebimento. Conferir roupa equipada/retirada nas poses, sono e passeio. Testar falta de material, save na última entrega, encontro antes/depois de 24 h, reload no ciclo e Tiro indisponível. Tour nas três resoluções e suíte completa. Confirmar nove novas principais: 31 antigas + 9 = 40, sem excluir missões laterais.

## Critérios de conclusão

Nova história tem começo, meio e final jogáveis, obras permanentes e lembrança visível. Final não exige comprar todas as ampliações nem obter raro por sorte. Percurso de campanha registrado com ledger; testes que apenas montam um estado final não bastam.

## Fora desta etapa

Não executar etapas seguintes, redesenhar interface geral, alterar valores fora do escopo, resetar saves ou publicar.

## Evidência e passagem de bastão

Guardar logs/relatório em build/economy/etapa_22/. Se houver UI, guardar capturas antes/depois nas três resoluções e abrir os PNGs.

Atualizar andamento no README e Estado atual do ROADMAP. Registrar número ajustado e motivo em DECISOES, com cenários antes/depois. Só marcar concluída se os critérios acima passarem; caso contrário manter em andamento e indicar a próxima ação exata. Atualizar documentação dos sistemas realmente alterados. Sem push.

## Registro de execução (18/10/2026)

Festa, Lenço, Encontro da turma, capítulos 10–12 e nove missões entregues; detalhes em `docs/PROGRESSION.md` ("Economia R1 — etapa 22") e `DECISOES.md`.

| Arquivo mudado | Teste rodado | Resultado |
|---|---|---|
| `projects.json`, `project_state.gd`, `database.gd` (validação do encontro), `game_state.gd` (`gather_project`, `completed_at`) | `projects_test` | PASS (158) — esperava 8 campos/3 projetos, ajustado para 9/4 |
| idem + `festival_test` novo (dados, história do zero ao fim, legado, Encontro, sala, painel) | `festival_test` | PASS (438) |
| `rooms/village.json`, `worlds.json`, `dog_world.gd`, `room.gd` | `garden_picnic_test` / `bench_test` | PASS (238) / PASS 45 s |
| `quests.json`, `progression.json` (capítulos 10–12, nomes do contrato), `places.gd` | `content_test` | PASS (ajustado: contador `project_use:`, obra feita pela história abre os destinos) |
| idem | `journey_test` | FAIL → PASS (esperava a história acabar no ateliê; agora segue para `community_10_meet`) |
| `rooms/village.json` (footprint da festa) | `world_life_test` | FAIL → PASS (o teste tratava obra não começada como obstáculo) |
| `quests.json`, `progression.json`, `game_state.gd` | `market_test`, `customers_test`, `coins_test`, `expansion_test`, `products_test`, `dev_tools_test`, `tasks_test`, `texts_test`, `manual_test`, `treasure_test`, `lists_test` | todos PASS |
| `worlds.json`, `rooms/village.json` | `navigation_test`, `worlds_test`, `world_view_test`, `world_selector_test`, `park_test` | todos PASS |
| `project_ui.gd`, `celebration.gd` | `ui_base_test`, `ui_style_test` | PASS |
| helpers do simulador (`economy_bot.gd`, `economy_sim.gd`) | `economy_sim_test` | PASS (58 s) |
| missão/projeto/capítulo | simulador referência s1: `until=projects` e `until=campaign` | 17,3 d / **99/99 em 21,1 d**, 0 violações |
| interface | `festival_shots.gd` antes/depois e `ui_tour.gd` (`b16l`, `b16m`) nas três resoluções; PNGs abertos | ok |

**Deliberadamente NÃO rodados:** a suíte inteira (`tools/test_all.ps1`) e testes que não citam o que mudei (política da rodada); `progression_test` (≥ 20 min): **pulado por decisão do Vitor** ("se já testou bem onde mudamos as coisas"), apesar de `quests.json`/`progression.json` terem mudado. A cobertura equivalente ficou com `festival_test` (história do zero ao capítulo final) e a campanha simulada 99/99. Conhecidos e não investigados: `onboarding_test`, `finds_test`, `npc_lines_test`. Sem baseline de 35 execuções. Evidência em `build/economy/etapa_22/` e capturas em `build/screenshots/etapa22_antes|depois|tour/<resolução>/`.
