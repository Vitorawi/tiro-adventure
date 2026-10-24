# Interface 2 — validação da etapa 05

24/10/2026, Codex. Somente interface e fluxo de apresentação, sem push ou publicação.
Etapa 04 conferida como `[x]` antes das edições. Próxima: **06**, não iniciada.

## Pronto quando

- [x] História/Pessoas/Diárias com selos e liberação progressiva; título e legenda antigos removidos.
- [x] Cartão, pílula, conversa, linha e Pegar tudo usam voo; nenhuma entrega nova no GameState.
- [x] História abre QuestReward, capítulo abre só Celebration, personagem/rotina têm voo sem folha.
- [x] Conferência guiada do save novo ao capítulo 2, usando pílula e folhas; PNGs abertos.
- [x] AGENTS/CLAUDE idênticos, APIs/nós novos documentados; resultados dos testes abaixo.

## Implementação

- `tasks_screen.gd/.tscn`: margem 136/16, abas `story/characters/timed`, textos História/Pessoas/Diárias,
  ícones com legenda juntos e selos `NewBadge`. Pessoas só aparece com linha ativa, Diárias após desbloquear.
  `ChapterSteps`, `ChapterStep_<id>` e `StoryFull`; `StoryCard`, `SharedQuestGuidance` preservados.
  `LineCard_<line>` é a linha da missão, `LineDetail_<line>` é a sanfona; uma aberta por vez;
  `choose_character` expande/recolhe a primeira linha do personagem. `QuestNew` usa a chave existente
  `ui:quest_new:<id>` via `GameState.mark_seen` ao sair de Pessoas. Hoje/Semana são seções simultâneas;
  `RoutineDetail_<kind>_<id>` guarda a descrição inteira; `choose_routine` traz a seção à vista.
- `TasksScreen.sync_hud`: `ClaimAllCharacters`/`ClaimAllRoutines` pequenos na linha 2, apenas N ≥ 2;
  saem ao mudar de aba/tela. Pegar tudo de Pessoas bloqueia reconstrução pelo `ui_animating` do LiveBox
  e espaça as entregas por 80 ms (zero em Menos animação).
- `ProgressionUi.claim_quest_fx(id, origin)`: copia prêmios antes, chama claim_quest uma vez; sucesso
  emite items_gained, falha emite notice_requested(error). Usada por quest_action, NextStep, linhas e pelo atalho Pegar de TaskHelp._go.
  `quest_speech`, `quest_goal_strip`, `next_step_card`, `quest_place_name` compartilham apresentação;
  `story_panel` usa linhas com controle vetorial para capítulos e passos.
- `QuestReward` (`scenes/ui/quest_reward/quest_reward.gd/.tscn`, `.uid`): folha com margem 8/canto 28,
  `RewardHandle`, `RewardRibbon`, `RewardClose`, `RewardSpeech`, `RewardChips`, `RewardChip_*`,
  `NextStepCard`, `RewardLater` e `RewardGo`; alça arrastável com os limites de 25%/900 px/s;
  `open(id, next)` só apresenta o prêmio já pago. Chips 44/36, contagem e Haptics.success.
  Sem próximo, não há NextStepCard e o único botão diz Que bom!. Menos animação é imediato.
- `main.gd`: espera Motion.FLY, serializa folha/capítulo/Novo! na fila modal, inclui QuestReward em
  `_card_open`; retira aviso genérico Missão concluída. Keepsake de personagem só dá aviso curto.
  `celebration.gd` reaproveita NextStepCard e Ir para o destino, sem folha extra no fim de capítulo.
- `CollectFx`: moedas ao HUD, itens ao centro da almofada Mochila (ou sobem/somem enquanto oculta),
  voo em arco durante Motion.FLY; `Hud.flash_coins` e `NavTab.reward_arrived` dão resposta à chegada.
  Mantém uso independente da casca (destinos opcionais).
- `UiKit`: opção `inline_icon` de segmented para ícone e nome ficarem juntos; chip centralizado
  verticalmente evita ocupar a altura inteira da linha. APIs antigas mantidas.

## Testes

Lista conferida com `-DryRun`: somente scripts_check/content_test/texts_test + os sete testes pedidos.
Sem suíte inteira, campanha, export ou teste adicional fora da lista. O teste novo foi executado sozinho
antes da lista e registrado em suite, story/tests e story/paths, com `.uid`.

Lista final: **10/10 PASS em 158,6 s** (tempo total do runner).
Log: `build/test_logs/r20261024_204158_b60ee618/results.csv`.

| Teste | Resultado | Segundos |
|---|---|---|
| scripts_check | PASS | 9,9 |
| content_test | PASS | 7,1 |
| texts_test | PASS | 2,8 |
| quest_reward_test | PASS | 26,1 |
| tasks_test | PASS | 24,8 |
| tasks_groups_test | PASS | 16,8 |
| lists_test | PASS | 18,6 |
| navigation_test | PASS | 13,4 |
| journey_test | PASS | 8,1 |
| next_step_test | PASS | 29,6 |

Na revisão final, encontrou-se o atalho Pegar de `TaskHelp._go` (Como fazer), também ligado a
claim_quest_fx. Reexecução apenas do teste novo, com caso desse caminho: **PASS em 25,9 s** (`build/i2_05_quest_help_final.log`, `.err` vazio). Após conferir também o contrato público `QuestReward.open(id)`, última reexecução **PASS em 25,4 s** (`build/i2_05_quest_api_final.log`, `.err` vazio). Lista + essas duas reexecuções: **209,9 s**; a lista fechada permanece abaixo de 3 min.
É a mesma lista autorizada; nenhum teste adicional fora dela.

Cobertura nova: pagamento +5/+2 uma vez, origem dentro de StoryCard, voo único, próximo lais_feed,
Ir para a tigela, Depois, segunda entrega recusada, capítulo sem folha, linha de personagem sem folha,
depósito cheio sem pagar/voar/abrir, pílula/conversa/Como fazer com voo, Pegar tudo de Pessoas com duas linhas reais,
liberação da linha 2 ao sair. Os testes existentes preservam seus contadores/requisitos/destinos.
`lists_test` continua exigindo três diárias abaixo de 300 px; a descrição inteira é conferida expandida;
Pegar tudo é procurado no HUD. `tasks_groups_test` confere as três abas nas três larguras e as duas
seções; `choose_routine` deve deixar Semana inteira visível, rolando quando necessário.
`next_step_test` só muda a limpeza da fixture para incluir QuestReward e sua fila entre os cenários;
todas as asserções de espaço, visibilidade e pagamento são mantidas.

Correções durante a validação: comparação dos números vindos de JSON pelo valor inteiro (2.0 == 2),
liberação do botão substituído por Liberar espaço, nomes de NPC lidos do catálogo, limpeza da nova
folha entre casos e tipos explícitos nos índices. Tentativas iniciais dentro do sandbox falharam por
acesso ao log/perfil/certificados do Windows; a execução final usa o acesso adequado e perfil isolado
pelo TIRO_TEST_TAG do runner. Logs de tentativas preservados em build/i2_05_* e build/test_logs/.

## Conferência guiada do capítulo 1

`game/tests/i2_05_walk_shots.gd` (não é teste nem campanha), sem headless, save descartável e SaveManager
removido. Navegação/entrega por botões da pílula e RewardGo; ações reais via GameState. Não usa
`dev_complete_quest`, `dev_jump_to_chapter` nem `dev_set_phase`. Somente ajusta fome/felicidade por DEV
para executar as duas refeições restantes e carinho útil sem esperar horas reais.

Ordem confirmada no log `build/i2_05_mao.log`:
`welcome` → `lais_feed` → `lais_bath` → `lais_play` → `lais_bag` → `lais_bed` → `growth_1_puppy`.
Destinos: Laís/Casa → Tigela/Casa → Tiro/Banho → Tiro/Brincar → Mochila → compra da caminha/Casa →
painel Crescimento. O próprio Ir da Mochila cumpre open:bag; a caminha consome o presente real;
GrowButton cresce com refeições 3/3 e Coragem 3/3. Os sete passos foram recebidos e chapter_index == 2.
Folha → Novo! observada após lais_play. Quinze PNGs em `build/screenshots/i2_05_mao/`, abertos e
conferidos (incluindo requisitos prontos, crescimento e cartão do capítulo).

É conferência visual assistida por script, sem aparelho físico ou toque Web. A etapa 05 não exige
Web (04/07/12 têm gestos e os roteiros próprios). O aviso antigo `Lambda capture ... was freed`
reapareceu duas vezes ao fechar painéis no percurso, sem travar nem impedir a sequência.

## Capturas e comparação

Antes, sem headless e antes das alterações: `build/screenshots/i2_05_antes/`, bloco `--lists-only`
(seis PNGs: Tiro/Missões/Mochila e listas). Depois, sete PNGs por pasta:
`build/screenshots/i2_05_depois/` (360×780), `i2_05_depois_390/` (390×844),
`i2_05_depois_412/` (412×915), bloco `--i2-05-only`.
Estados: história andando, história shared, Pessoas com duas prontas/duas andando, sanfona aberta,
Hoje+Semana/uma pronta, folha e capítulo (captura do rodapé para mostrar o próximo destino).
PNGs abertos e comparados com missoes2_historia/personagens/diarias, missoes_premio e missoes2.html.

Diferenças deliberadas:
- Dados e falas são os reais: capítulo inicial tem sete passos, nomes/prêmios/objetivos diferem do
  exemplo ilustrativo. Falas completas foram preservadas conforme §3.7, mesmo ultrapassando as 14
  palavras do orçamento genérico; quebram em linhas, sem alterar diálogo ou regra.
- Abas futuras somem no começo, conforme liberação progressiva pedida no passo a passo.
- A lista mostra todos os passos reais do capítulo com rolagem; o protótipo desenha só três exemplos.
- Sanfona abre dentro da própria linha; não duplica o cartão nem mostra a instrução ilustrativa
  “Tocar na linha abre o detalhe”. Sem nome/prêmio zero em chip.
- O cartão grande mantém a composição antiga (refeita na etapa 10); ganhou o próximo destino e Ir.
  Com cinco novidades, o rodapé é alcançado pela rolagem. Não há folha extra.
- Botões de destino usam o nome literal do lugar (ex.: Ir para Tigela do Tiro), sem inventar artigos
  para cada item do catálogo. Chip de prêmio conta os valores efetivos do jogo.

Revisão por tela:

| Tela | Visual | Interação/estado | Celular |
|---|---|---|---|
| História/shared | ✓ Fredoka/Nunito, controle liso, prêmios mel, passos/cadeado | ✓ objetivos completos e Ver em Pessoas | ✓ cartão e lista rolável acima do rodapé |
| Pessoas | ✓ retrato em disco, pronto verde com Pegar, Nova mel | ✓ sanfona única, Ir, voo, Pegar tudo | ✓ três larguras, alvo 44 e lista com rolagem |
| Diárias | ✓ anel azul/verde, tempo azul, prêmio mel | ✓ Hoje/Semana, descrição no detalhe, vazio com check | ✓ três diárias <300 px, sem ação atrás do rodapé |
| Folha | ✓ fita verde, retrato/fala, chips 44/36 e próximo destino | ✓ Depois/Ir/X/alça, números finais em Menos animação | ✓ margens 8, altura limitada e rolagem se necessário |
| Capítulo | ✓ composição preservada para etapa 10 | ✓ só cartão grande e próximo destino | ✓ rolagem chega ao Ir e Continuar |

## Passagem

Nenhum arquivo em game/data ou game/autoload alterado; SAVE_VERSION, regras, falas e prêmios preservados.
`CLAUDE.md` e `AGENTS.md` conferidos idênticos. Arquivos alheios de assets/sprites não foram tocados ou
incluídos no commit. O `.uid` pendente de pill_walk_shots da etapa 03 foi incluído conforme a passagem.
Sem pendência funcional desta etapa. Próxima **06**, não iniciada. Persistem o aviso antigo de lambda e
as pendências já reservadas: mapas/etiquetas (06), bandejas (07), caderninho/Mochila (08), contratos (09)
e composição dos modais (10); StepCard sem nome clicável do capítulo segue observação opcional da 03.
