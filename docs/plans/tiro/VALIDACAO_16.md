# Etapa 16 — Validação (19/10/2026, Codex) — PORTÃO

**Implementação pronta; passagem total em andamento.** Alterações locais anteriores preservadas, sem reset de checkout/save, commit, push ou publicação. Arte existente reutilizada; nenhum PNG do Tiro redesenhado.

## O jogador encontra

Explorador, Comilão, Brincalhão, Dengoso ou Tranquilo, revelado ao virar Aventureiro pela novidade “O jeito dele apareceu”. “Tiro, o …” no painel e na aba Crescimento do caderninho. Rotina pesa por dia jogado (14 recentes + histórico); limites e confirmação por vários dias impedem uma troca por uma sessão diferente. Fase e jeito orientam animações na tela e no mapa. “Hoje o Tiro...” registra fotos, primeiras provas, crescimentos, passeios e raros, até 20 linhas, com datas e recibos persistentes.

## Teste novo

`personality_test`: cinco exemplos de contadores, revelação nas seis fases, save/reload, um dia com 10.000 brincadeiras que não troca Explorador, 40 dias de rotina que mudam para Brincalhão, janela de 14 dias, relógio atrasado, carinho sem utilidade, novidade com recibo, pesos/intervalos do JSON e clipes existentes, decisões de cochilar/sentar, diário por alimentar/crescer/foto/volta real do passeio (raro garantido), recarga e limite de 20. Última rodada focada: PASS, ~7 s (limite 3 min).

## Arquivo mudado → testes → resultado

| Área | Testes focados | Resultado |
|---|---|---|
| growth.json, GrowthState, PersonalityRules, ações reais e diário | personality_test, growth_test, pillars_test, content_test | PASS |
| PetAnimator | pet_care_test, wishes_test, manual_test, brush_taste_test | PASS |
| DogWorld | world_life_test, world_view_test, navigation_test | PASS |
| GrowthUi/PillarUi/Places, título e diário | growth_ui_test, sheet_test, tasks_test, lists_test, texts_test | PASS |
| Eventos de foto/crescimento/passeio, novidades | album_test, album_secrets_test, ceremony_test, welcome_test, festa_test, dev_tools_test, dev_tools_test_prod | PASS |
| Estilo | ui_style_test | Imprime PASS; filtro reprova recursos em uso ao sair (mesma falha histórica) |

Rodada `test_all.ps1 -Only … -KeepGoing`: **24 testes, 23 PASS + 1 histórico, 5,2 min** (`affected.log/csv`). A última correção de guarda do tropeço será coberta pela passagem completa já iniciada, antes de chegar aos testes de mundo. A primeira tentativa do teste novo encontrou um erro de compilação pela referência estática a autoloads em SceneTree; corrigida para carregar os scripts após os autoloads, como os testes existentes. Tentativa não contada como PASS.

## Portão total

`tools/test_all.ps1 -KeepGoing`, uma única passagem, em andamento. Log `build/test_logs/tiro16/suite.log`, CSV final com tempos em `suite.csv`. Sem chamada a economy_simulate/economy_baseline ou perfil/semente de economia. O teste de regressão economy_sim_test faz parte da suíte obrigatória.

## Capturas e fases

`tests/personality_shots.gd`, sem SaveManager, fixtures descartáveis, pelo DEV. Telas: cinco cuidados, painel com jeito, caderninho/diário, álbum secreto/foto, Casa/prateleira e seis fases. Três resoluções: 360×780, 390×844, 412×915; evidência em `build/screenshots/tiro16_<resolução>/`. A fixture inicial não tinha a escovinha e foi corrigida para mostrar os cinco cuidados; a foto oficial também passou a gravar Aventureiro na fixture. Revisão final em andamento.

As seis fases são escolhidas com `dev_set_phase`; cada uma observa 12 s do sorteio real e depois mostra uma animação representativa controlada para comparar os clipes existentes: Recém boceja, Filhotinho cochila, Dentinhos mordisca a pata, Aventureiro corre atrás do rabo, Mocinho inclina a cabeça, adulto respira devagar. Logs separam `PHASE OBSERVED` (sorteio) de `PHASE DEMO` (quadro controlado). No mapa, pesos do dado aumentam cochilos/tropeço nos pequenos, corridas no Aventureiro e aproximação/sentar nos maiores; caminhos, interrupções e construções têm cobertura em world_life/world_view/navigation.

## Limites

Sem aparelho físico e sem gesto novo; touch_test não é exigido. Jeito/diário começam com padrão seguro em saves v13, sem inventar datas passadas. Nenhuma mudança de necessidades, recompensas, receitas, economia ou requisitos. Pelagem de seda e atualização do simulador ficam exclusivamente para a etapa 17, em outra sessão.

## Portão total — resultado (Claude, 19/10/2026)

Suíte única `test_all.ps1 -KeepGoing`: 56,2 min, 8 falhas. Seis são as históricas (npc_lines, onboarding, finds, park, petshop, ui_style). `economy_sim_test` imprime PASS e só reprova pelos "Stack underflow" da saída da engine. A única nova era `progression_test`: a Caminha macia (etapa 14) pede lã (`yarn`) e o robô da campanha só ia à Feirinha enquanto não tinha a sacola de passeio. Correção só no teste (`progression_test.gd`, linha 132: Feirinha também enquanto faltar `bed_soft`). Reexecução: **PASS** (767 ciclos, 109/109), log `build/test_logs/tiro16/progression_rerun.log`. Nenhum dado do jogo alterado. **Etapa 16 concluída.** Próxima: etapa 17, em sessão própria.
