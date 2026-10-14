# Roadmap

## Estado atual (passagem de bastão entre agentes)
> Atualize esta seção ao terminar cada tarefa: é por aqui que Claude Code e Codex continuam o trabalho
> um do outro. Última atualização: **14/10/2026, Claude Code**.

**✔ Etapa 01 do começo (facilitar) feita — Claude Code, 14/10/2026.** Próximo passo: `docs/plans/comeco/ETAPA_02_caminha.md` (Etapa 02).
- 1A: vovó empresta 2 e depois 4 canteiros; `initial_plots` 4, `unlock_costs` `[0,0,0,0,40,70,100,150,220]`. 1D: só o próximo
  canteiro fechado tem etiqueta (`PlotIndicator`: ícone `tab_farm` + "Vovó", ou moeda + preço).
- 1B: abóbora → `bloblo_potato`, papinha → `lais_stew`; regra nova no `content_test` (skills só com cap. ≥ 6 ou construção com
  materiais; herbas/caixa de petiscos passam por estufa/forno). 1C: diárias no cap. 3, semanais no 4; diária nova "Regue 5 plantas".
- 1E: regar (`GameState.water/water_error`, `watered` no canteiro salvo, tira 30% do tempo que falta, 1 XP, contador `water`;
  gotinha `action_water` no mapa e animação em `RoomView._water_fx`; `first_harvest` pede regar + colher; ação `water` em
  `available_actions`). Arte: `action_water.png` (PixelLab, ver ART_PIPELINE).
- 1F: `level_rewards` + `Events.level_up` + `Celebration.show_level`. Decisão: nível fora da tabela = `coins_per_level × nível`.
  Vários níveis juntos dão um cartão só (soma). 1G: presente do dia (`daily_gift`, `progress.daily_gift`, dias jogados) e cartão
  `welcome_back` (`SaveManager.last_saved_at`; abre após 300 s fora; decisão: só abre se houver presente ou algo pronto).
  `main.gd` ganhou fila de cartões (`_queue_modal`): nível/bem-vindo esperam a introdução e as comemorações fecharem.
- 1H: dica parada em `WorldsScreen.advance_idle` (15 s, cap. ≤ 4, uma vez por passo, só no mundo aberto).
- 1I: `onboarding_test.gd` (jogador simulado; imprime a linha do tempo: 1ª colheita ~1,5 min, cap. 4 em ~10,5 min, ocioso 220 s,
  maior trecho 30 s). O tempo é simulado com `dev_advance_time` (3 s por ação), então é só uma estimativa. Novos: `welcome_test`.
  Ajustes em `farm_test` (4 canteiros, regar), `tasks_test`, `navigation_test` (dica), `progression_test` (campanha rega).
- `tools/test_all.ps1` reescrito: modo "Continue" (no PowerShell 5.1 os avisos "RIDs leaked" do stderr derrubavam a suíte) e
  respeita `$env:GODOT_BIN`; inclui `welcome_test` e `onboarding_test`. Suíte completa verde. Capturas 360×780 conferidas:
  `farm_progress{,_vovo,_zoom}`, `welcome_back`, `level_up`.
- Pendente/atenção: economia do começo não foi jogada de verdade (ver 00_VISAO §6; se ficar fácil, escritura 220); `dev_advance_time`
  não mexe em `watered`. Nada publicado (sem push).

**✔ Etapa 00 do começo (fundação) feita — Claude Code, 13/10/2026.**
- Save **v12 zerado** (`_migrate` descarta qualquer save < 12, todos os slots); `quests.json` com `order` ×10;
  `content_test` espera ordens 10, 20, 30...
- `pet()` conta `pet`; `feed()` conta `feed:<item>`; todas as contagens do `GameState` passam por `_count`,
  que grava `progress.firsts[chave]` (primeira vez) e `progress.started_at` (novo jogo). Aba **Ritmo** no DevPanel
  (`ProgressionState.pace_lines`, botão Copiar).
- Requisitos `stats` (rótulos em `settings.stat_labels`), `bond` e `hours`; recompensas `affection` e `needs`.
  `progression.json → bond_levels` criado com os valores da Etapa 03.
- `Loot` (`scripts/util/loot.gd`, `loot_test.gd` novo na suíte) e `GameState.available_actions()`.
- Decisões: `bond` e `hours` ficam em `GameState.requirement_error` (precisam de `dog.affection` e da hora local;
  `content_error` do GameState agora passa por ele). `progress.requirement_error` continua puro (só stats/quests/etc.).
  Chip de `affection` nas recompensas usa `need_happiness` até a Etapa 03. Nenhuma arte nova (a etapa não pede).
- Observação: os testes aceitam avisos de "RIDs leaked" do Godot; o `tools/test_all.ps1` no PowerShell 5.1 trata
  esses avisos (stderr) como erro — rodei cada teste direto no Godot e todos deram PASS (inclusive `-- --prod`).

**▶ PRÓXIMO GRANDE TRABALHO: um começo mais gostoso — plano em andamento (Claude Code, 13/10/2026).**
- Pedido do Vitor: mais missões, itens, receitas, estruturas e um mapa novo, focando a primeira hora.
- **Plano por etapas para executar: pasta `docs/plans/comeco/`** — comece pelo `README.md` (ordem,
  mensagem pronta para o agente, andamento). `00_VISAO.md` = diagnóstico, pesquisa e princípios;
  `01_REGRAS_E_ARTE.md` = regras, receitas do PixelLab e catálogo de ids; um `ETAPA_XX_*.md` por etapa.
- Etapas: 00 fundação (save v12 zerado) · 01 facilitar · 02 caminha · 03 aba Desejos + vínculo ·
  04 sabores (morango, liquidificador) · 05 faro do Tiro · 06 Praça (abre depois da Vila; Nina, Pipoca,
  primeiro passeio) · 07 passeios (7 caminhos, materiais exclusivos, apetrechos raros) · 08 vestir o Tiro,
  pet shop, costura · 09 amigos · 10 truques · 11 mapa do tesouro.
- Decisões do Vitor: pode zerar os saves; Praça depois da Vila; Desejos em aba própria; foco nos passeios.
  Etapa 00 feita; as demais ainda não.

**Armazenamento com limite (Claude Code, 13/10/2026) — local, sem commit.** Plano: `docs/plans/ARMAZENAMENTO.md`.
- Feito (base): `progression.json → storage` (geladeira/baú/silo/armazém: `categories`, `base`, `building`, `levels`) +
  melhorias `fridge_2/3`, `chest(_2/_3)`, `silo(_2/_3)`, `warehouse(_2/_3)` com `storage_capacity` (sem estado novo: níveis = `owned`).
  `items.json → storage` força o depósito (`"none"` = sem limite: ração). `GameState.storage_of/capacity/used/space/error`.
  O limite só vale com a construção comprada (a geladeira já vale). Sem espaço: `harvest`, `collect` e `collect_gathering`
  não entregam (lote continua pronto, toast "X sem espaço"); recompensas de missão sempre entram.
- UI: Mochila e painéis de depósito mostram chips usado/capacidade (`SheetBuilder._storage_bars`); painel `storage:<id>`.
  Lugares `chest`/`silo`/`warehouse` (ocultos) em `worlds.json`. `storage_test.gd` novo; testes que enchem a mochila usam `GameState.unlimited_storage`.
- Feito (2ª passada): objetos Baú (casa), Silo e Armazém (sítio) com arte PixelLab; ficam na parte ABERTA do sítio, fora das áreas fechadas (estufa/pomar/animais) para não dependerem de compra de outra área.
  Linha da vovó ganhou `bloblo_silo → warehouse → chest → bigger → biggest` (ordens 14–18): cada construção só aparece após a missão anterior;
  ampliações pedem itens novos `bolt` (Parafuso) e `iron_band` (Cinta de ferro), dados por essas missões e (parafuso) pelas semanais. Itens com `storage: "none"` não ocupam espaço.
- Falta: aviso de "cheio" no marcador do mapa; `dev_add_items` ignora o limite; painel de ampliação direto na tela de cada depósito; balancear números
  (parafuso aparece nas semanais antes de a história apresentá-lo); a simulação de campanha roda com `unlimited_storage`.

**Ajustes pós-publicação (Claude Code, 13/10/2026) — locais, sem commit.**
- Codex parou no limite de uso sem alterar arquivos. Feedback do Vitor após o deploy `2c78f95`:
  (1) a conversa com a Laís abria sozinha ao fim da introdução; (2) Laís pequena demais.
- (1) Fim da intro usa `world_requested("house", "look:npc:lais")`: `WorldsScreen.enter` aceita
  `look:<ação>` = só a seta, sem abrir o painel. `intro_test` agora exige talk:lais == 0 + seta.
- (2) `npcs.json → world_scale` (padrão 1) multiplica a escala do NPC na sala; Laís = 1.7
  (maior que o Tiro, quase na altura do balcão). Ajustar o número se ainda parecer pequena/grande.
- (3) Feedback do Vitor: o "Ir" pulava etapas (missão do ensopado levava direto à horta de cenoura).
  `ProgressionUi.quest_go_target` agora = `Places.quest_target` (lugar do objetivo: fogão/geladeira);
  a cadeia de ingredientes continua no "?" (`TaskHelp`). Os botões "Ir" de dentro do "?" seguem
  levando ao passo que falta.
- (4) Fogão expansível até 3 espaços: `stove_queue` (+1, 180 moedas + 3 tábuas) e novo `stove_queue_2`
  (+1, 320 + 5 tábuas, exige `stove_queue`); ambos em `config.json → stations.stove.slot_upgrades`,
  `progression.json → upgrades` e no lugar Cozinha de `worlds.json`. Números fáceis de ajustar.
- (6) Espaços do fogão a ampliar ficam na própria fileira de espaços ("+" com o preço; tocar abre
  a compra), em vez de um cartão lá embaixo: `SheetBuilder._locked_slot`, `GameState.pending_slot_upgrades`;
  `Places._with_upgrades` não repete as compras que são `slot_upgrades` de estação. Vale para qualquer
  estação com `slot_upgrades` em `config.json`. Teste em `progression_test` (captura `ui_kitchen_slots`).
  Local, depois do deploy `e2e2f90`; falta publicar.
- (7) Cartão de missão enxuto (pedido do Vitor): só o que fazer (objetivo), onde (lugar) e a recompensa;
  saíram os chips de ingredientes que faltam (a cadeia fica no "?"). `tasks_screen._quest_body`.
  Bancada não tinha bug: Vitor confirmou que "desbugou" (nada a corrigir). Falta publicar (itens 6 e 7).
- (8) Laís do mapa refeita (v3, pro 128 px, mesmo detalhe do Tiro, esguia) com caminhada de 8 quadros;
  `world_scale` removido do `npcs.json` (campo e suporte no `room.gd` continuam para outros NPCs).
  Detalhes em `docs/ART_PIPELINE.md`. Falta publicar.
- (9) Painéis de produção padronizados (pedido do Vitor: gostou do do fogão): espaços em cima com
  tempo/barra, espaço fechado mostrando preço (estações) ou nível/XP (Natureza), recolher, e embaixo
  os cartões do que escolher. Aplicado à Natureza (`NatureUi.panel/_material/_slot`) e ao Pomar
  (`ProgressionUi.routes_panel`); `SheetBuilder.slot_frame` agora é público. Regra em `CLAUDE.md`.
  Falta publicar (itens 8 e 9).
- (10) Geladeira só com comida e ingredientes: lugar `fridge` usa `panel: "fridge"` →
  `SheetBuilder.inventory_view(true)` (categorias food/crop + itens com `"storage": "fridge"` em
  `items.json`: ovos, leite, farinha). Materiais/produtos de oficina ficam só na aba Mochila.
  Teste em `content_test` (`_fits_fridge`). Falta publicar (itens 8–10).
- (11) Contador de ingrediente mostrava o estoque limitado ao que a receita pede (6 pedras = "3/3",
  e depois de gastar 3 continuava "3/3"; parecia que não descontava). `ProgressionUi.item_chip` e
  os chips do `TaskHelp` agora mostram o estoque real ("6/3" → "3/3"). O desconto em si (`GameState.cook`)
  sempre esteve correto. Falta publicar (itens 8–11).
- (12) Sombra das áreas bloqueadas (Estufa/Pomar/Animais) ficava NA FRENTE de objetos (galinheiro, plantas):
  `room.gd._spawn_regions` agora usa z_index 0 e `move_child(region, 0)`: sombra e cerca ficam atrás dos
  objetos. Falta publicar (itens 8–12).
- (13) Galinheiro e curral abriam o mesmo painel com os dois. Agora cada abrigo tem lugar próprio
  (`worlds.json → farm.places.chicken_coop / cow_barn`, `hidden`, `panel: station:<id>`) e os objetos do
  `rooms/farm.json` (abrigo + bichos) usam `place:chicken_coop` / `place:cow_barn`. A zona "Animais"
  (`animal_yard`) e a lista "Lugares" continuam com o painel junto. Teste em `content_test`.
  Falta publicar (itens 8–13).
- (14) Loja de animais: botão cinza só dizia o 1º motivo ("Recolha 2 × Ovos") mesmo faltando moedas
  também. `SheetBuilder._animal_missing` mostra tudo em chips ícone + número (ovos 0/2, moedas 78/80);
  texto só para outros motivos (abrigo cheio etc.). Falta publicar (itens 8–14).
- (15) "Ir" de comprar/construir (objetivo `owned`) levava ao lugar da estação (ex.: fogão). Agora
  `Places.goal_target` devolve sempre `buy:<construção>`: a seta aponta o "+" do objeto
  (`RoomView.point_at("buy:<id>")`, cai no lugar só se a sala não tiver o "+") e abre a compra com o que é
  preciso ter. `WorldsScreen.enter` espera um quadro numa sala recém-aberta e `RoomView._reveal` confere a
  câmera de novo após 0,2 s (a seta aparecia fora de vista na 1ª abertura). Falta publicar (itens 8–15).
- (16) Configurações com vários saves (pedido do Vitor): engrenagem (`ui/icons/settings.png`, Pixen job
  `2521958e-e74f-4ec9-a45c-38ad69c6b2d0`) ao lado das moedas abre `SettingsPanel`: até 5 saves, cada um com
  nível/capítulo/moedas, Jogar, Tornar padrão (o que o jogo abre ao iniciar) e Excluir (2 toques); "+ Novo save".
  O save de sempre vira o Save 1 (sem migração). Detalhes no cabeçalho de `save_manager.gd`.
  Teste: `saves_test` (usa o slot 4 e devolve o padrão). Falta publicar (itens 8–16).
- (5) Recolher direto no mapa + animação: `Events.items_gained` / `CollectFx` (z_index 20, filho de `main`).
  Tocar numa estação/criação com lote pronto, no marcador "Recolher" da Natureza ou numa planta
  madura recolhe sem abrir painel e salta ícone +N. Os botões de recolher dos painéis usam a mesma
  animação (a partir do meio da tela). `GameState.last_gain/last_coins` guardam o que a última coleta
  da Natureza trouxe. Teste em `nature_test` (captura `collect_fx`). Rotas legadas (`route_group` em
  objetos) ainda abrem o painel.
- Suíte completa verde. Falta publicar (aguardando OK do Vitor) e testar no celular.

**Publicação da nova história autorizada pelo Vitor (13/10/2026).**
- Pacote das Fases 1–3 e introdução preparado para envio na `main`, com deploy
  automático de prod (`/`) e dev (`/dev/`). Suíte completa e export local passaram.
- Save v11 reinicia saves anteriores, conforme decisão da reformulação da história.
- Próximo: testar no celular a chegada, as quatro linhas em paralelo e os animais;
  ajustar ritmo e clareza a partir da experiência do Vitor.

**Plano de linhas de NPC concluído — Fase 3 (Codex, 13/10/2026).**
- Feirante tem 4 passos a partir do capítulo 4 (conversa, vender 5, encomenda, mais 2).
  Guia tem 4 a partir do capítulo 5 (conversa, Bosque, Pedreira, Prado). As linhas
  progridem em paralelo sem bloquear Laís/Bloblo; metas fresh usam base de cada linha.
- Laís usa "Pedindo algo" nas conversas e "Acenando sorrindo" ao receber missão.
  Artes existentes do personagem correto "Laís Avatar", sem gerar imagens novas.
  `NpcPortrait` preserva a animação durante atualizações do painel e pausa oculto.
- Campanha simulada completa: 138 ciclos, 30 aquisições, 51 missões. Novo teste
  `npc_lines_test` cobre liberação gradual, independência, coleta real, save e animações.
- Suíte completa verde (incluindo DEV em prod); export Web prod/dev concluído sem
  erros em `build/web` e `build/web/dev`. PNGs, imports e UIDs novos gerados.
- Capturas 360×780: `npc_lais_request`, `npc_lais_complete`, `npc_merchant_line`,
  `npc_guide_line`. Próximo: jogar no aparelho e ajustar ritmo (publicação autorizada acima).

**Polimento das conversas e do sítio (Codex, 13/10/2026).**
- Mapa mostra ! para missão nova e ✓ com prioridade para missão pronta; NPCs fechados
  não geram aviso. Bloblo se apresenta em 3 falas, uma vez por save, com retomada se fechar.
- Canteiros fechados indicam Vovó e levam à conversa até liberar a escritura; atalhos
  dos NPCs escondem lugares fechados e construções não compradas (como o Pomar).
- Sheet remove conteúdo anterior da árvore antes da próxima fala, evitando nomes
  duplicados temporários. `intro_test` cobre apresentação, retomada, save, badges e atalhos.
- Capturas 360×780: `intro_bloblo.png` e `intro_bloblo_quest.png`.
- Suíte completa passou após os ajustes, incluindo introdução e DEV em prod;
  campanha do zero ao fim: 138 ciclos, 30 aquisições e 43 missões.
- Fase 3 ainda tem animações de missão da Laís e linhas próprias de Feirante/Guia.
  Trabalho local, sem commit/publicação.

**Fase 2 — animais na linha da vovó concluída (Codex, 13/10/2026).**
- B8–B13 ensinam galinheiro, ovos, curral, leite, farinha e queijo após a Bancada.
  Laís fica com 9 capítulos; ids antigos preservados, mais `bloblo_milk`.
- Abrigos custam moedas + tábuas (180 + 4 / 300 + 6), com primeiro animal presente.
  Variedades abrem com 2 e 6 produtos recolhidos; lojas e ajuda mostram o requisito.
- Campanha passou com 138 ciclos, 30 aquisições e 43 missões. Testes cobrem custo,
  presente único, persistência, desbloqueio só na coleta e produção por lote.
- Próximo: Fase 3 (badge no Mapa, apresentação da Bloblo, animações e outras linhas),
  além dos ajustes de canteiros/atalhos anotados no plano. Sem commit ou publicação.

**Introdução — retomada da última conversa do Claude (13/10/2026).**
- Após a Fase 1, Vitor pediu a chegada em casa com a Laís apresentando e soltando o Tiro.
  Claude implementou a cena e parou no limite da sessão após acrescentar título/capítulo.
- Codex conferiu o retrato contra o arquivo de "Laís Avatar" baixado pelo Claude (hash igual),
  revisou capturas 360×780 e protegeu o fim da cena contra toques repetidos no mesmo frame.
- `intro_test.gd`, incluído em `tools/test_all.ps1`, verifica apresentação automática,
  revelação do Tiro, persistência após recarregar, chegada em casa e primeira conversa
  sem receber a missão automaticamente. Capturas: `build/screenshots/intro_*.png`.
- Validação: suíte completa passou (incluindo DEV em prod), teste novo de introdução
  passou com renderização e novamente headless após a proteção contra toque repetido.
- Próximo: Fase 2 do plano (animais da vovó); apresentação da Bloblo e demais polimentos
  continuam pendentes. Alterações locais, sem publicação.

**▶ PRÓXIMO GRANDE TRABALHO: linhas de missões por NPC (Laís + vovó Bloblo) — Claude Code, 13/10/2026.**
- Design combinado com o Vitor: `docs/plans/QUESTLINES.md` (história, falas, paralelismo).
- **Plano de execução com fases e checklist: `docs/plans/TASKS_QUESTLINES.md`** — leia primeiro.
  Decisões fechadas: save zerado; Laís (casa) conduz a história; Bloblo é a vovó do sítio;
  um passo ativo por linha; casa começa sem fogão/geladeira; ensopado = 2 cenouras + 1 batata.
- **Fase 1 feita (Claude Code, 13/10/2026):** linhas em paralelo (`kind: "line"`), Laís andando na
  Casa e vovó Bloblo no Sítio (`NpcWorld`, balão `!`/`✓`, toque = conversa com retrato + fala),
  aba Missões com um cartão por linha, cap. 1–5 da Laís + B1–B7 da vovó, cozinha só depois do
  sítio, ensopado (2 cenouras + 1 batata), canteiros emprestados (`farm.lent_plots`), save v11 zerado.
  Suíte completa verde (campanha: 139 ciclos, 30 aquisições, 42 missões); capturas 360×780 conferidas.
  Ainda não publicado. **Próximo: Fase 2** (animais na linha da vovó, abrigos com moedas + tábuas,
  primeiro bicho de presente) e os "Pontos para olhar" listados no plano.

**Experiência por uso e cadeia clara de desbloqueios (Codex, 13/10/2026).**
- Região abre uma vez com moedas; recolher cada coleta dá 10 XP próprios. Níveis/espaços
  seguintes são automáticos: Bosque/Prado em 30/90 XP, Caverna em 40/120 XP.
- Painel mostra barra, próxima liberação, coletas restantes e ? com cadeia completa.
  Atributos do Tiro inclui as três regiões. Compra inicial mostra preço/requisitos normais.
- nature_xp persistente e consultas puras; XP local salvo no lote e entregue uma vez.
  Tokens owned mantêm rotas/ajuda; marcos de XP não podem ser comprados. Pomar não ganha XP local.
- Save v10 preserva ferramentas/níveis/vagas anteriores e histórico de uso como XP equivalente;
  nature_levels_version 2 impede conversão duplicada. Prazo/produtos/missões/moedas preservados.
- Suíte completa passou; campanha 129 ciclos, 30 aquisições, 33 missões. Nature/tasks/content
  repetidos após ajustes finais; capturas 360×780 verificadas (incluindo Caverna nível 2).
  Export Web prod/dev sem erros. Publicação prod/dev autorizada em 13/10/2026 via main.
  Próximo: avaliar clareza/ritmo de XP no celular.

**Níveis comprados — substituídos por experiência de uso acima (Codex, 13/10/2026).**
- Bosque, Caverna e Prado têm desbloqueio e níveis permanentes, comprados no próprio painel.
  Nível 3 do Bosque libera madeira dura; Caverna 2 cobre, Caverna 3 cristais; Prado 2 mais fibras.
  Coleta com um toque e três vagas simultâneas continuam. Vagas compradas separadamente.
- Removidas compras de ferramentas e trava extra de Aventura para materiais. Conteúdo em
  nature_sites.level_upgrades/requirements; progress.nature_level deriva ampliações compradas.
- Refinar lista receitas/ingredientes e leva às estações existentes. Sem novas receitas.
- Save v9 converte ferramentas e locais já explorados sem cobrar; preserva moedas, missões,
  vagas e tarefas com prazo/recompensa. main_5_pickaxe mantém id e agora pede abrir a Caverna.
- Suíte completa passou; campanha com 158 ciclos, 29 aquisições e 33 missões. Nature test
  repetido após ajustes, incluindo migração idempotente, acesso antigo sem ferramentas,
  prazo/recompensa em curso, níveis bloqueados e destino real do refino. Export Web prod/dev
  sem erros; capturas 360×780 verificadas (Bosque fechado/nível 1 e Caverna nível 3).
  Alteração local; ainda não publicada. Próximo: publicar e avaliar progressão no celular.

**Coleta com um toque e painel enxuto (Codex, 13/10/2026).**
- Material virou ação direta: tocar já chama `start_next_gathering` e ocupa a primeira
  vaga livre. Sem selecionar material e depois espaço; cada toque inicia uma tarefa.
- Painel compacto: materiais com ícone/rendimento/tempo, ferramenta em legenda, fila
  com ícone/tempo/barra, compra das vagas e botão único para recolher os prontos.
  Próxima ferramenta tem atalho Melhorar, em vez de cartão de compra completo na coleta.
- Nature test verifica um toque por tarefa, fila cheia sem sobrescrita, requisitos,
  coletas mistas e reutilização de vaga no meio preservando as outras tarefas.
- Suíte completa verde (incluindo campanha e dev/prod); Nature test repetido após ajuste
  visual, sem erros. Capturas 360×780 verificadas, incluindo fila mista e recolhimento.
  Publicação prod/dev autorizada em 13/10/2026 via main. Próximo: avaliar os toques no celular.

**Coleta por local e três vagas simultâneas (Codex, 13/10/2026).**
- Árvores e Pedras agora são pontos distintos no mapa; Fibras fica no prado. Um toque abre
  ferramenta, rendimento/tempo, vagas e próxima melhoria daquele local, sem abas/listão.
- Uma vaga inicial por local; segunda/terceira compradas ali (Árvores 100/200, Pedras 120/240,
  Fibras 80/160 moedas). Máximo três, começando juntas e terminando independentemente.
  Locais trabalham ao mesmo tempo; iniciar nos livres/recolher prontos tem botão único.
- Save v8: progress.gathering por local/índice, timestamps Unix e rewards congeladas. Atividade
  antiga da Natureza migra para a vaga 1, sem perder prazo/recompensa; pomar segue compatível.
  Ir das missões mantém lane/quarry exatos após comprar ferramentas melhores.
- Nature test cobre UI, compra das vagas, simultaneidade (três cortes + pedra), offline,
  coleta única, migração, melhorias durante coleta e indicador de três prontos. Campanha
  completa passou com 152 ciclos, 27 aquisições e 33 missões. Demais testes passaram.
- Suíte completa verde e export Web prod/dev concluído sem erros. Capturas 360×780 em
  `build/screenshots/nature_{trees_initial,trees_working,trees_ready,rocks,sites_map}.png`.
  Material por vaga fica salvo; coletas mistas preservam ícone, prazo e produtos extras.
- Publicação prod/dev autorizada em 13/10/2026, via push na main. Próximo: avaliar a clareza dos dois painéis no celular.

**Ferramentas por categoria — substituído pelos locais acima (Codex, 13/10/2026).**
- Aba Ferramentas com filtros Madeira/Mineração/Fibras, definidos em `nature_tool_groups`.
  Cada filtro mostra apenas seu kit; Mineração reúne as três picaretas, mesmo vindo de Pedras.
- Ícones dos materiais atendidos, próxima ferramenta destacada e custos existentes.
  Na coleta: ícone + Usa/Precisa/À mão; requisito deriva da rota, não da última ferramenta
  comprada. Próxima melhoria indicada e atalho Ferramentas abre o grupo correspondente.
- Nature test ampliado com troca real de filtros, compra após trocar abas, material sem
  ferramenta e indicação da ferramenta correta após comprar todos os níveis.
- Suíte completa verde, capturas 360×780 conferidas e export Web prod/dev sem erros.
  Capturas `nature_tools_mining.png`, `nature_tools_buy.png`, `nature_collect.png` em build/screenshots.
- Publicação prod/dev autorizada por Vitor em 13/10/2026, via main. Próximo: acompanhar
  a clareza dos kits e dos requisitos de coleta no celular.

**Natureza integrada, ferramentas e seleção de mundos (Codex, 13/10/2026).**
- Substituído o mapa de pontos separados por paisagem PixelLab contínua 512×384: floresta,
  riacho com ponte, trilha e gruta. Obstáculos reais bloqueiam água, árvores e penhascos.
- NatureUi reúne todos os materiais e ferramentas num painel; botão Coletar no cabeçalho,
  cenário inteiro tocável. `nature_resources` prioriza melhor rota conforme ferramentas;
  madeira/pedra/cobre/cristais/fibras não exigem trocar de lugar para coletar.
- Machado → reforçado (madeira dura); picareta → reforçada → precisão; foice. Ferramentas
  são compras normais. Madeira dura vira tábuas na bancada e serve à picareta de precisão.
  Rotas existentes preservadas, melhorias opcionais; save/produção em curso mantêm resultados.
- Mundos: quatro cartões horizontais com miniatura inteira, nome curto, função, bloqueio/
  status; cartão inteiro entra com um toque. Título Para onde vamos?, volta por Mundos.
- Testes de Natureza cobrem compra via UI, seleção automática, rendimento, save e melhoria
  durante lote; campanha simulada chegou a 33 missões e 21 aquisições em 130 ciclos.
  Worlds test cobre bloqueio/entrada por cartão e atalho de coleta. Capturas 360×780.
- Suíte completa verde e export Web prod/dev sem erros. Capturas finais:
  `worlds_{locked,select}.png`, `nature_{open,collect,collect_ready,tools_buy}.png` em
  build/screenshots. Caminhos de ambos os lados da ponte e até a gruta também validados.
- Publicação prod/dev autorizada por Vitor em 13/10/2026, via main, incluindo Natureza,
  ferramentas, seleção de mundos e variedades dos animais. Próximo: acompanhar no celular.

**Natureza como novo mundo — protótipo substituído pela versão acima (Codex, 13/10/2026).**
- Quarto mundo, mapa 1208×683 com árvores/troncos, riacho/ponte, prado de fibras, gruta
  de pedra/cobre e gruta de cristais. Portão da Vila viaja para Natureza; Guia mudou para lá.
- Abre no capítulo 3. Bosque disponível ao entrar; riacho = Aventura 2; pedra = picareta;
  cristais = picareta + Aventura 3; prado = Aventura 4. Mesmas rotas/ids/tempos/recompensas.
- `regions.requirements` abre cercas por progressão e recalcula a navegação. Etiquetas
  alternam entre requisito e nome; objetos de exploração mostram timer/Recolher no mapa.
- Destinos de missão/manual/mochila resolvem cada zona. Saves e rotas em curso preservados.
- `nature_test` valida viagem pelo portão, evolução real abrindo riacho, picareta/grutas,
  áreas bloqueadas/abertas, coleta única, indicadores e navegação. Capturas 360×780 em
  `build/screenshots/nature_{locked,open,ready,crystals}.png`.
- Suíte completa verde (incluindo Natureza e animais); export Web prod/dev concluído sem
  erros. Capturas conferidas em 360×780, com requisitos legíveis e sem etiquetas sobrepostas.
- Protótipo substituído pela versão integrada acima, incluída na publicação autorizada.

**Compra individual e variedades dos animais (Codex, 13/10/2026).**
- Galinheiro/curral novos começam vazios. Loja dentro do abrigo: três variedades por espécie,
  preço individual, quantidade possuída e três vagas por abrigo; cada compra aparece no mapa.
- Galinhas branca/ruiva/preta; vacas pintadinha/caramelo/malhada. Variedade muda o visual;
  cada animal consome o alimento da receita e produz duas unidades. Quantidade do lote é
  fixada ao alimentar, inclusive offline; comprar outro animal não aumenta lote em curso.
- Save v7 mantém os dois animais antes incluídos em cada abrigo já adquirido; saves novos
  guardam quantidades por variedade. Slots vazios não bloqueiam caminhos nem recebem toque.
- Suíte completa passou, incluindo campanha com compras reais, lotação, moedas,
  save/migração e caminhos com as seis variedades. Loja/mapa conferidos em 360×780.
- Export Web prod/dev concluído sem erros; capturas em `build/screenshots/animals_shop.png`
  e `animals_farm_overview.png`. O botão da loja também é testado acionando sua compra.
- Incluído na publicação autorizada em 13/10/2026, junto de Natureza e seleção de mundos.

**Sítio dos animais e processamento (Codex, 13/10/2026).**
- Quarta área no sítio (1208×683), cercada até comprar o galinheiro. Corredor independente
  das expansões de estufa/pomar; duas galinhas e duas vacas, com arte PixelLab e movimento leve.
- Cadeias: milho → ovos; trigo → leite → queijo; trigo → farinha. Galinheiro/curral = um lote
  por vez; moinho/queijaria = duas posições na fila. Alimentar, esperar, recolher; indicador
  de tempo/coleta no mapa. Reutiliza StationState/save v6, sem duplicação de alimentação/coleta.
- Abre após sítio próprio/capítulo ≥3; lugar Animais e lugar Produção (bancada+moinho+queijaria).
  Manual, mochila, venda, ajuda dos ingredientes e navegação já reconhecem os novos recursos.
- Capítulo 9 com cinco passos, preservando a campanha anterior; duas diárias, uma semanal e
  encomenda Café da manhã. Campanha simulada passou com 328 ciclos, 16 compras e 33 missões.
- Novo `animals_test` cobre requisitos, alimentação, lotação, coleta única, offline/save antigo,
  processamento e corredor. Capturas `animals_{farm_overview,feed,dairy,manual_milk}.png`.
- Suíte completa verde; export Web prod/dev concluído sem erros. Toque direto no moinho
  também validado com bancada ainda não comprada; destinos próprios no manual/missões.
- Publicação em prod/dev autorizada por Vitor em 13/10/2026, junto das melhorias de mundo
  abaixo, via push na main. Próximo: acompanhar balanceamento e experiência no celular.

**Tiro reagindo, construções visíveis e sítio ampliado (Codex, 13/10/2026).**
- Sítio 1208×539: duas laterais cercadas e sombreadas, abertas pelas compras já existentes
  de estufa/pomar. Centro anterior preservado, mesmos nove canteiros/índices de save; câmera
  começa no centro e pode arrastar/diminuir zoom. Ir enquadra destinos fora da tela.
- Arte PixelLab: bancada, estufa, pomar, forno, banca extra e estação de costura aparecem após
  comprar; caminhos contornam suas bases. `regions` bloqueia chão antes da compra e retira
  a cerca ao abrir. Requisitos/custos existentes preservados, sem migração de save.
- Colher, recolher e comprar emitem `world_activity`. Tiro vai ao objeto, cheira em colheita/
  produção pronta e comemora com pulo/coração. Reações não acordam o Tiro nem rodam em mapa
  oculto; o movimento se interrompe quando muda a navegação ou chega outra ação.
- Novo `world_life_test` cobre ações reais, construções em save avançado, áreas fechadas/abertas,
  reação a produção pronta, sono e caminhos completos após compras. Capturas 360×780 em
  `build/screenshots/{farm_expansion_start,farm_expansion_built,farm_orchard_focus,house_buildings,village_buildings}.png`.
- Suíte completa verde e export Web prod/dev concluído sem erros. Reação de colheita conferida
  em `build/screenshots/tiro_harvest_reaction.png`; o teste aguarda a chegada/animação do Tiro.
- Incluído na publicação autorizada em 13/10/2026. Próximo: acompanhar visual/reações no celular.

**Manual visual na tela principal (Codex, 13/10/2026).**
- Botão Manual acima do Tiro, disponível desde o começo. Catálogo Recursos/Estações em
  `GameManual`, gerado dos dados existentes: itens por categoria, origens, ingredientes,
  quantidades, tempos, usos e local mundo › lugar. Toque em ingrediente abre sua origem.
- Ir até lá para os lugares; Ver compra para estações não compradas; mundos/lugares fechados
  continuam bloqueados com motivo. Catálogo completo é consulta, sem mudar progresso/save.
- Atalhos acima do Tiro usam fluxo para caber Manual + Atributos + Coleção no celular.
- Suíte completa incluindo novo `manual_test`: consulta sem alterações, todos os itens,
  bloqueios, ingrediente tocável e navegação até a bancada. Capturas 360×780 `manual_*` conferidas.
- Publicação autorizada pelo Vitor em 13/10/2026 pela `main` (prod e dev), após suíte completa verde.
  Próximo: revisar no celular a consulta de recursos e os atalhos do manual.

**Instruções breves nas missões (Codex, 13/10/2026).**
- Pedido do Vitor: só ícones deixaram a ação difícil de entender. `goal_row` agora mostra
  `goals[].label` acima da barra, tanto na História quanto nos cartões dos personagens.
- Primeira colheita explica plantar e esperar crescer. Todas as diárias/semanais têm
  `description` com ação e quantidade, exibida na largura do cartão, sem exigir tocar em "?".
- Teste de Missões passou; capturas 360×780 `tasks_start` e `tasks_middle` conferidas.
  Publicação autorizada pelo Vitor em 13/10/2026 pela `main` (prod e dev); suíte completa
  rodada novamente antes do envio. Próximo: revisar a clareza das frases jogando no celular.

**Tiro andando no Sítio e na Vila (Codex, 13/10/2026).**
- Ambos têm `dog_start`; Vila ganhou `floor`. Canteiros têm `footprint`; `obstacles` bloqueia
  casas, feira, árvores/pomar, caixas e banco desenhados no fundo. Margem de navegação de 8 px
  nos mapas externos; grade da casa também confere cantos de células (4 px).
- Proporção ajustada após pedido do Vitor: `dog_scale: 0.5` no Sítio/Vila; Casa mantém 1.
  Sprite, sombra e área de toque acompanham a escala; patas continuam ancoradas no chão.
- Pontos de tigela/sofá são opcionais: fora da casa o Tiro dorme no local e não tenta ir à origem.
  Nasce no chão livre, sorteia apenas destinos alcançáveis e não anda direto até um alvo sem rota.
- Suíte completa verde, incluindo novo `navigation_test` (100 caminhos por mapa, limites,
  obstáculos, sono e ausência de rota). Capturas 360×780 conferidas em
  `build/screenshots/tiro_{farm,village}{,_walking}.png`.
- Publicação autorizada pelo Vitor em 13/10/2026: enviar pela `main` para o deploy automático
  de prod e dev no GitHub Pages. Suíte completa rodada novamente antes do envio.
- Próximo: conferir no aparelho o passeio e a proporção do Tiro; ajustar as áreas conforme
  novas artes/objetos entrarem nos mapas.

**Simplificar — todas as 5 fases concluídas (Claude Code, 13/10/2026). Sem push: esperando o Vitor aprovar.**
- O Vitor achou o jogo confuso ("bombardeamento de informação"). Plano aprovado em `docs/plans/SIMPLIFICAR.md`:
  missões em 3 tipos (História, Diárias, Semanais), 3 mundos (a Trilha vira portão na Vila), 4 atributos,
  personagens que aparecem aos poucos, revelação gradual com "Novo!" e menos texto em todo canto.
  Regra que vale sempre: **ícone + número em vez de frase; simplificar**.
- **Fase 1 feita:** aba Tarefas → **Missões** com 3 blocos. História = cartão visual (rosto, ícone + `0/6`,
  lugar em ícones, ingredientes que faltam em chips tocáveis, recompensa em chips, **Ir** + **?**).
  Diárias (3, a partir do cap. 2) e Semanais (2, a partir do cap. 3) em `data/routines.json`, estado em
  `ProgressionState.routines`. Secundárias removidas (roupas → semanais). Atributos/Coleção → aba Tiro.
  "Como fazer" do Codex (`task_help.gd`) refeito em ícones; os botões de ajuda espalhados viraram "?" e chips.
  Novas peças: `UiKit.tap_chip/square_button/short_label/fill_label`, `ProgressionUi.goal_row/reward_chips/item_chip`,
  `Places.target_view`, tema `ChipButton`. DEV: "Recomeçar diárias e semanais".
- Testes verdes (farm, progression, DEV dev/prod, tasks com diárias/semanais, content). Capturas:
  `build/screenshots/tasks_{start,middle,story,help,end,celebration}.png`.
- **Fase 2 feita:** 4 atributos (Horta, Cozinha, Comércio, Aventura), escondidos até o capítulo 3
  (`features.skills`). Construções não exigem nível. Passos "suba o atributo" viraram ações
  contadas a partir do início do passo (`"fresh": true` + `ProgressionState.step`). Save v6 soma
  Passeio+Mineração+Construção em Aventura e remove Vínculo. Painel de Atributos em ícones.
  Dados migrados com uma ferramenta única (não versionada); a formatação dos JSON foi mantida.
- **Fase 3 feita:** 3 mundos (Casa, Sítio, Vila), no máximo 4 lugares visíveis cada. Casa: Tigela, Cozinha
  (fogão + forno + fila extra), Geladeira, porta. Vila: Feira (abas Vender/Encomendas + banca), Ateliê,
  Portão da trilha (passeios + mina + picareta; capítulo 3). Sem menus "Construir em…": cada construção é
  comprada no próprio lugar (`upgrade`/`upgrades` em `worlds.json`; `Database.place_of_upgrade`).
  Mapa e "Lugares" em ícones. `rooms/trail.json` removido (arte guardada). `content_test` garante 3 mundos e ≤4 lugares.
- **Fase 4 feita:** revelar aos poucos. `progression.json → features` (Mochila após a 1ª colheita, diárias cap. 2,
  semanais e atributos cap. 3); NPCs com `requirements` (Feirante 2, Guia 3, Laís 4). Tela "Novo!" (com a
  comemoração de capítulo) lista o que abriu com ícone + Ir, uma vez só (`ProgressionState.seen`). O "Ir" mostra
  uma seta sobre o objeto da sala e abre o painel 0,8 s depois. Detalhes em `docs/WORLDS.md`.
- **Fase 5 feita:** menos texto no resto. Mochila em 4 colunas (ícone + `x12`); detalhe do item com preço,
  "De onde vem" e "Usado em" em chips que levam ao lugar; sementes compactas (bloqueada = "?"); canteiros em
  grade; compra de terreno em ícones; coleção em grade (conquistado colorido, resto "?"); personagem = rosto +
  fala curta + atalhos (falas encurtadas em `npcs.json`).
- Capturas: `build/screenshots/` → `tasks_*`, `go_pointer`, `ui_*` (mapa, vila, feira, portão, cozinha, mochila,
  item, NPC), `sheet_seeds`, `farm_*`.
- **Próximos passos sugeridos:** Vitor jogar a versão dev e aprovar → publicar (push na main); testar o toque
  real (`tools/touch_test.ps1`); ícones próprios (PixelLab) para encomenda, passeio e coleção (hoje reaproveitam
  ícones de itens); balancear diárias/semanais com jogo real.

**Tarefas v2 — todas as fases (1–6) concluídas (Codex, 12/10/2026).**
- 28 passos principais em 8 capítulos e 9 secundárias; recompensas por capítulo, destinos
  com Ir, painel História, recomendações por progresso e ajuda para evoluir atributos.
- Comemoração modal, faixa/toast com próximo passo, guia inicial e badge sem duplicação.
- Save v5 migra capítulos cujas construções já eram adquiridas sem pagar recompensas.
  Vila abre após first_harvest; Trilha no capítulo 3. Ferramentas DEV seguem a sequência.
- Todos os testes verdes: farm, progression (296 ciclos, 37 missões, 12 construções),
  tasks, content, DEV e DEV --prod. Export Web prod/dev local e toque real em Chrome
  headless confirmaram Tarefas → Ir → Tigela do Tiro, sem erros no console.
- Capturas 360×780: build/screenshots/tasks_{start,middle,end,story,side,celebration}.png.
  Símbolos da história têm fonte bitmap própria de apoio (a Web não tem fallback do Windows).
- Ajustes ao esboço para evitar produção antes da estação: oficina/tecidos são secundárias;
  capítulo 8 prepara fibras e Construção antes do ateliê. Nenhum trecho ficou pela metade.
- Seis commits locais, um por fase. **Sem push/publicação.** Próximo: Vitor revisar as capturas;
  só publicar quando solicitado. Depois, balanceamento em jogo real e vestir a coleção.

**Rodada 2 (12/10/2026, Claude Code): navegação intuitiva + mini mundos**
- Pedido do Vitor: "tá difícil achar rotas, vender, missões; deixar os menus intuitivos" e
  "vão ter vários mini mundinhos, cada um com seus NPCs".
- Abas novas: **Tiro · Mapa · Tarefas · Mochila** (a aba Jornada com 8 sub-botões foi removida).
  Cada função mora num lugar de um mundo; Tarefas mostra próximo passo, prontos agora e missões com "Ir".
- Mundos orientados a dados (`data/worlds.json`): Casa, Sítio, **Vila** (Feirante, Laís: vender,
  encomendas, ateliê, lojas) e **Trilha** (Guia: passeios, mina). Vila e Trilha ganharam cena própria
  (PixelLab) com zonas tocáveis e etiquetas. Receita para criar mundos em `docs/WORLDS.md`.
- Mochila com detalhe do item (como conseguir, onde usar, vender). Retratos provisórios dos 4 NPCs.
- Testes passando; teste de toque no Chrome confirmou Tarefas → Ir → Trilha → Guia.

**Próximos passos (rodada 2)**
1. Trocar os retratos provisórios pelas fotos do Vitor (`npcs.json → portrait`). Feito: **Laís** (artesã da Vila).
   Receita em `docs/ART_PIPELINE.md`.
2. NPCs pequenos dentro das cenas (sprite no mundo, além do botão no cabeçalho).
3. Novos mundos seguindo `docs/WORLDS.md` (ex.: parque, praia, clínica).
4. Tutorial curto inicial concluído em Tarefas v2 (guia no Tiro e aba pulsando).

**Rodada 1 — feito**
- Progressão completa (**Jornada**), criada pelo Codex: casa quase vazia no começo, canteiro emprestado,
  7 atributos, 12 construções, 7 rotas, feira (venda + 6 encomendas), 8 capítulos, 15 missões de 4 NPCs,
  6 itens de coleção. Save v4 com migração. Ver `docs/PROGRESSION.md`.
- Revisão e organização (Claude Code):
  - dados da progressão saíram de 9 variáveis soltas no `GameState` para `ProgressionState`
    (`scripts/state/`, acesso por `GameState.progress`), seguindo o padrão de `DogState`/`Inventory`;
  - o estado não depende mais da UI (`TimeText` em vez de `SheetBuilder.format_time`);
  - bugs corrigidos: rota removida do JSON travava o jogador para sempre; receita removida travava a coleta;
    texto do capítulo final fixo no código (agora `final_chapter` no JSON);
  - `house.json` voltou ao formato compacto (o Codex tinha expandido todas as coordenadas);
  - 14 ícones de itens novos + ícone da aba Jornada (PixelLab); ícones próprios em atributos,
    construções, rotas e chips "tem/precisa" com ícone na feira e nas construções;
  - abas inferiores com ícone em cima e texto embaixo (com 4 abas, "Jornada" não cabia).
- **Versão dev** (pedido do Vitor, que ficou sem resposta na conversa do Codex): `/dev/` com save
  separado, selo DEV e Ferramentas DEV (moedas, itens, atributos, pular capítulo, liberar tudo, terminar
  timers, avançar o tempo, copiar o save real). Deploy gera prod + dev. Ver `docs/DEPLOY.md`.
- Testes: `farm_test`, `progression_test` (campanha simulada) e `dev_tools_test` (dev e `--prod`) passando;
  teste de toque no Chrome headless confirmou prod sem selo e o painel DEV funcionando em `/dev/`.

**Próximos passos sugeridos**
1. Vestir as roupas da Coleção no Tiro (camadas sobre o sprite grande; `DogState.outfit` já existe).
2. Retratos dos NPCs a partir das fotos que o Vitor vai mandar (`npcs.json` → `portrait`).
3. NPCs pequenos no mundo (Bloblo no sítio, Tutor em casa) que abrem as missões ao toque.
4. Móveis da bancada, forno e ateliê na casa ou no sítio (hoje só pela Jornada → Produção).
5. Sprite próprio da planta de ervas (usa o broto como planta madura).
6. Balancear com jogo real (o ritmo hoje só é medido pela campanha simulada; ela termina com ~16 mil
   moedas, sinal de que vender o excedente rende demais no fim do jogo).
7. Telas do Hoje/Missões mais visuais (o painel ainda é bastante texto).

## Fase 0 — Fundação
- [x] Estrutura de pastas e documentação
- [x] Projeto Godot 4.7.2 (Compatibility, pixel art, celular em pé 360x780)
- [x] Autoloads `Events`, `GameState`, `SaveManager`
- [x] Preset Web PWA single-thread + scripts de export/servidor local
- [x] Workflow de deploy no GitHub Pages
- [x] Repositório no GitHub + primeiro deploy
- [ ] Testar instalação PWA e save no iPhone e no Android

## Fase 1 — Design
- [x] Ideia do jogo registrada (`GAME_DESIGN.md`)
- [ ] Receber referências visuais (`docs/references/`)
- [ ] Responder perguntas em aberto do design
- [ ] Padrões de arte (tamanho de tile/personagem, paleta)

## Fase 2 — Iteração 1 (ver `GAME_DESIGN.md`)
- [x] Base: toque/arrasto de câmera, `Hotspot`, tempo real offline, save automático
- [x] Tela do Pet: Tiro detalhado + 4 necessidades + comer/brincar/banho/dormir/carinho
- [x] Casa: geladeira, fogão (fila), tigela, sofá, brinquedos; Tiro autônomo
- [x] Inventário + receitas no fogão (dados em JSON) + XP/nível
- [x] Sprites PixelLab: Tiro pet (128px) e Tiro mundo (4 direções + andar)
- [x] Casa montada no PixelLab: sala vazia + móveis separados (geladeira, fogão, tigela, sofá)
- [x] Colisão com móveis (grade de navegação), profundidade (Y-sort), toque por pixel, sombra do Tiro
- [x] Animações do Tiro no mundo: andar, parado, sentar, latir, dormir, comer
- [ ] Mais móveis/decoração (caminha, brinquedos, TV, mesa) — por enquanto casa enxuta
- [ ] Barra de segurança no topo para notch do iPhone

## Iteração 2
- [x] Horta: Sítio da Bloblo (aba Sítio + porta da casa), cenoura/batata/abóbora (`crops.json`)
- [x] Progressão do sítio: canteiro emprestado, escritura, expansão até 9 em posições fixas, moedas por colheita, indicadores de crescimento e painel Meu sítio
- [x] Jornada: atributos, construções, rotas, feira (venda + encomendas), capítulos, missões de NPCs, coleção (`docs/PROGRESSION.md`)
- [x] Navegação intuitiva: abas Tiro/Mapa/Tarefas/Mochila, mundos em `worlds.json` (Casa, Sítio, Vila, Trilha) com NPCs (`docs/WORLDS.md`)
- [x] Versão dev em `/dev/` com save separado e Ferramentas DEV
- [ ] Bloblo como personagem no mundo (sprite + retrato); Tiro passeando no sítio
- [ ] Tutor dentro de casa (sprite pequeno + retrato detalhado + diálogo) com missões

## Iteração 3
- [ ] Customização (Ateliê): vestir as roupas da Coleção (camadas sobre o Tiro detalhado)
- [ ] Parque: passeio, truques, minigames

## Backlog / ideias técnicas
- [ ] `AudioManager` (música/sfx; destravar áudio no primeiro toque)
- [ ] Exportar/importar save como código (backup manual)
- [x] Aviso "nova versão disponível" no PWA
- [ ] Testes automatizados headless no CI
- [ ] `tools/pixel_tools.ps1` → `New-ContactSheet` falha ("Parâmetro inválido" ao criar o Bitmap)
