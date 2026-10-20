# Decisões — plano "Tiro no centro"

## Fechadas com o Vitor (19/10/2026)

| # | Decisão |
|---|---|
| 1 | O objetivo do jogo passa a ser ver o Tiro crescer; fazenda, estações e economia existem a serviço dele. |
| 2 | **5 fases** (Filhotinho, Dentinhos, Aventureiro, Mocinho, Azul e Dourado), a partir do Recém-chegado, casadas com os capítulos. |
| 3 | Crescer é sempre o principal: é o último passo dos capítulos 1, 3, 6, 9 e 12 e abre o arco seguinte. |
| 4 | Atributos passam a ser do Tiro (Corpo, Pelagem, Esperteza, Coragem). |
| 5 | O avatar do HUD mostra o crescimento do Tiro; **o nível do jogador deixa de existir** para quem joga. |
| 6 | Liberdade para repensar a economia e criar comidas, itens e fatos reais da raça. |
| 7 | Etapas pequenas, uma por vez, no mesmo padrão dos planos anteriores. |
| 8 | Testes enxutos: só o teste novo + os afetados; sem simulação de economia por etapa; suíte inteira só nos portões. O Vitor simula quando quiser; o simulador fica atualizado e com modo rápido. |
| 9 | **O Tiro continua o mesmo cachorro:** o adulto é o Tiro atual (não redesenhar); fases jovens partem das imagens atuais, com aprovação do Vitor (portões das etapas 01 e 04). |
| 10 | **Saves zerados:** "não precisa fazer muita coisa para manter o save atual, porque eu vou zerar praticamente o jogo de todo mundo". `SAVE_VERSION` 13 com reset na etapa 02; nada de migração. |
| 11 | **Sessões encadeadas:** cada etapa, ao terminar, abre uma sessão nova com a próxima (parando nos portões do Vitor). |

## Decisões de desenho deste plano (podem ser revistas pelo Vitor)

| # | Decisão | Motivo |
|---|---|---|
| D1 | Teto de pilar por fase + reserva (padrão "ascensão") | evita "grind" adiantado sem perder pontos |
| D2 | Bem-estar só dá bônus (Radiante ×1,5), nunca tira | gentileza; pesquisa de jogos cozy |
| D3 | Crescer só pelo botão, quando o jogador quiser | antecipação tem valor; padrão Pokémon GO |
| D4 | Silhueta revela forma em partes, nunca a cor | a mudança de cor do Yorkie é o grande segredo natural |
| D5 | Adulto = Tiro atual; Mocinho = mesma arte com shader | identidade garantida e menos arte |
| D6 | ~~Saves antigos entram na fase do capítulo~~ → substituída pela decisão 10 (reset) | — |
| D7 | `level`/`xp`/`skills` saem da interface; podem sair do código se o simulador/testes permitirem | reset tira a necessidade de compatibilidade |
| D8 | Ração de crescimento com ovo e mingau com leite/farinha | dá ao galinheiro, curral e moinho um porquê no Tiro; revisar se pesar |
| D9 | Álbum com 54 fotos, no máximo 3 condições por foto, janelas ≥ 3 h, sorte só com garantia | lições de Stardew/AC (frustração) e Pokémon Sleep (encanto) |
| D10 | Sem velhice/fase "Sábio" | jogo cozy; ver FUTURO |

## Registro de ajustes durante a execução

| Data | Etapa | O que mudou | Por quê | Antes → depois |
|---|---|---|---|---|
| 19/10/2026 | 00 | `test_all.ps1` ganhou também `-KeepGoing` (não estava na etapa) | sem ele a linha de base pararia na primeira falha histórica e não daria para listar todas | — → `-KeepGoing` opcional; sem parâmetros continua parando na primeira falha |
| 19/10/2026 | 00 | `run_godot_test.ps1`: tempo máximo padrão era 10 min | a etapa pede 5 min; `economy_sim_test`, o mais lento que costuma passar por ele, leva ~55 s | 10 → 5 min |
| 19/10/2026 | 00 | `festival_test` e `economy_checkpoint_test` não foram postos na suíte | a etapa não muda testes existentes e a suíte sem parâmetros deve rodar igual; ficam registrados no README para o Vitor decidir | — |
| 19/10/2026 | 01 | Método do quadro base = combinação c + b (não um método puro) | o inpaint (c) mantém o rosto idêntico mas deixa o cinza da cabeça; a troca exata (b) pinta a sela com os pretos da paleta | 3 métodos isolados → c (forma) + b (sela) + `reduce_colors` |
| 19/10/2026 | 01 | `idle_front` 160 e mundo 64 feitos por `edit_image` em modo referência (não inpaint) | o quadro 256 escolhido serve de referência e a pose de cada tamanho fica preservada; inpaint em 64 px tem pouco espaço | — |
| 19/10/2026 | 01 | Filhote do mesmo tamanho do adulto no canvas (06 E pede "menor, cabeça maior") | reduzir por pixel estraga o traço (#2 da prancha); o candidato #1 é o mais "bebê" mas redesenha olhos/língua | **Vitor escolheu a opção 1 (19/10/2026)**: filhote = edição PixelLab (a); 160 e 64 refeitos com ela de referência (seeds 411/511), redução local para a paleta |
| 19/10/2026 | 01 | Pranchas e finais ainda não instalados nas pastas definitivas | o item 8 só vale para arquivos aprovados; `growth_art_shots.gd --step=install` copia depois da aprovação | — |
| 19/10/2026 | 01 | Pelagem do Mocinho sai do preto do jovem e vai até o Tiro atual; o dourado não escurece | pedido do Vitor: a 1ª versão escurecia o dourado e "parecia torrado"; tem que continuar a partir do jovem | coat 0 = sela quase preta + dourado castanho fundo → coat 0 = adulto com os mesmos pretos do jovem (0 pixels de diferença), dourado intacto |

| 19/10/2026 | 02 | Requisitos congelados nas mutações, consultas puras | compatibilizar "nunca volta" com `growth_info` sem efeitos colaterais | `_sync_growth` no `_changed`; `given` já fica salvo no reset |
| 19/10/2026 | 02 | Só moedas e ração nos presentes atuais | cestos, receita do lacinho e título não existem nesta etapa; sem criar conteúdo futuro | recompensas 30/60/100/150/250 + ração ×3, decoração nas etapas próprias |
| 19/10/2026 | 02 | Fixtures de integração econômica usam envelope v13; v12 agora tem assert de reset | o reset autorizado substituiu a expectativa antiga de migração do SaveManager | preservados os testes puros de EconomyMigration e de recibos/snapshots |
| 19/10/2026 | 02 | Aviso espera a introdução terminar | a chegada da Laís cobre o toast se mostrado no primeiro quadro | aviso consumido uma vez e exibido após `tree_exited` da introdução |
| 19/10/2026 | 02 | Encadeamento pela ferramenta nativa `create_thread` | `claude-code-remote.create_session` não está disponível; manter mesma pasta e prompt autorizado | sessão local no projeto ClaudeGame, título Tiro — Etapa 03 |

| 19/10/2026 | 03 | Caminho interno `bathe(true)` pronto, sem item/receita/interface de xampu | ligar a fonte da tabela 02 D sem criar conteúdo da etapa 09; recarga do xampu usa a mesma chave `bath` |
| 19/10/2026 | 03 | Bônus do cesto no brincar acompanha fase ≥ Aventureiro | o cesto é presente garantido dessa fase, mas sua decoração só entra na 14; não criar uma construção provisória |
| 19/10/2026 | 03 | DEV soma exatamente a quantidade pedida, usando `_gain_pillar` com origem `dev` | ferramenta e fixtures precisam de pontos exatos; só essa origem dispensa Radiante; fontes do jogador sempre aplicam o bônus |
| 19/10/2026 | 03 | `feature_unlocked` encaminha requisitos de crescimento à consulta pura do GameState | `ProgressionState` sozinho não contém `GrowthState`; a aba não pode abrir no Recém-chegado |
| 19/10/2026 | 03 | Ajustes das fixtures de `growth_test` e `pet_care_test` | alimentar agora soma pontos reais; reserva compara o valor salvo, transferência continua com assert exato; quatro abas exigem fase puppy além das antigas liberações |


### Etapa 04 — produção da arte (19/10/2026; aprovação visual pendente)

| Ajuste | Motivo e limite |
|---|---|
| Edição com referência aprovada em folhas de quadros, seguida da edição exata da sela e quantização | Cada célula vem do respectivo quadro adulto, sem escala; preserva a sequência de poses e economiza chamadas. Produção usa `edit_image` em modo referência em vez de repetir o inpaint separado em cada quadro. Filhote continua a opção 1 e jovem a 10; a aceitação final do resultado/método é o portão do Vitor, ainda pendente. |
| Paleta completa dos clipes: 241 cores originais, em vez das 81 das quatro imagens paradas | As 81 não contêm a tigela azul, mão e outros adereços existentes. Só foram acrescentadas cores já presentes nos PNGs originais, sem criar paleta nova. Os pretos da sela continuam os mesmos 19 da 01. |
| Lotes de um quadro sem célula vazia; mundo de nove quadros em 3×3 | Folha com espaço sobrando fez a última rolagem cortar o corpo e o último quadro de cavar mudar de direção. Lotes afetados refeitos; IDs anteriores registrados, sem duplicar quadros para esconder faltas. |
| Limpeza de pequenos fragmentos e língua do latido do filhote por edição exata | Remoção de componentes isolados (<16 pixels na tela, <3 no mundo) e recoloração só da ilha interna da língua, mantendo boca/focinho. Um quadro recebeu polígono manual conferido em ampliação. Bases aprovadas e adulto existente nunca recebem essas edições. |
| `bodies.<corpo>.dir` é `{pet, world}`; `parts` usa listas de retângulos `[x,y,w,h]` | Um catálogo para a 05; retratos/frontais/fallback ficam junto. Não foi preciso `pet_feet` diferente: cada quadro foi alinhado à linha de apoio do adulto correspondente. Ainda sem uso na interface. |
| Smoke/testes em projeto espelho, importação no original | Evita carregar/gravar saves reais; o único reset continua sendo o da 02. Nenhuma alteração em `SAVE_VERSION` ou regras de progressão. |


Complemento da revisão final da 04:
- **Tamanhos reais do mundo:** o plano supunha 64×64 para tudo; os originais têm 8 rotações 64×64, 45 quadros
  76×76, 38 quadros 80×80 e 8 quadros 96×96 por corpo. Foi mantido o tamanho **de cada arquivo adulto**,
  priorizando o contrato de canvas/apoio e a identidade, sem reduzir o desenho para caber em 64. A seção E
  do 06 e a etapa 04 foram corrigidas para documentar esse fato; não houve alteração no adulto.
- A revisão visual achou cortes em `idle/east` e `walk/east` nas folhas de ambos os corpos. Esses quatro
  clipes foram refeitos com `transfer_outfit` em quadros nativos 80×80, seeds 4701 (jovem) / 4801 (filhote),
  sem extração por células; o instalador aplica esses arquivos **depois** das folhas. A auditoria agora
  acusa pixels tocando as bordas das células/quadros, além de nomes/quantidade/canvas/paleta/apoio.
- A edição exata da língua rosa foi aplicada também em `young/pet_paw` quando a ilha interna estava exposta.
  Boca fechada não recebe uma língua artificial. A aprovação estética continua pendente do Vitor.

## Etapa 05 — integração dos corpos (19/10/2026)

- `GameState.dog_look()` é uma consulta pura ao catálogo da 04; a criação de materiais e os vínculos das
  imagens ficam no helper visual `DogLook`. Estado/saves não passam a guardar recursos de renderização.
- `state_changed` também atualiza o visual, além de `grew` no PetAnimator: isso cobre DEV, recarga e o coat
  do Mocinho crescendo dentro da mesma fase. Não foram emitidos eventos de crescimento falso pelo DEV.
- Jovem reutiliza as variantes de roupa por quadro do adulto: rosto/linha dos pés foram preservados na 04.
  Âncoras em `bodies.young` por clipe/slot: cabeça e pescoço escala 1/deslocamento zero; corpo escala 0,94,
  deslocamento (6,8) no canvas 256×216. Pranchas das 19 roupas em cinco poses abertas; nenhuma variante
  nova necessária nas poses conferidas. Filhote oculta as camadas sem alterar o equipamento salvo.
- O shader preserva o modulate/alfa dos nós. Coat=1 renderizado foi comparado à mesma pose sem material:
  zero diferenças. Os canvases 64/76/80/96 do mundo não foram normalizados/redimensionados.
- `create_session` não está disponível neste ambiente; a passagem usa `create_thread` local, como nas
  sessões anteriores e por instrução expressa do bloco recebido. Sem commit/push para continuar.


## Etapa 06 — tela de crescimento (19/10/2026)

- Vínculo e selo ficam lado a lado numa faixa abaixo das quatro necessidades. Colocar mais um selo na
  antiga linha de 360 px espremia os anéis; as necessidades preservam tamanho e posição.
- O retrato animado usa `PetAnimator.portrait(120)` com enquadramento compacto; Crescer cabe inteiro em
  360×780. O corpo não é refeito, e nenhum canvas/PNG fonte é redimensionado.
- `growth_info()` ganha dados de apresentação sem gravar estado; `unlocks_text` entra no JSON como prévia,
  sem adiantar as travas de história das próximas etapas. Não há ajuste econômico.
- `LiveBox` aceita `tick_refresh=false`: crescimento atualiza pelos sinais, sem reiniciar o Tiro a cada
  segundo. Os outros painéis mantêm seu comportamento.
- Recém-chegado passado não possui timestamp próprio no save existente: exibe Primeira chegada em vez
  de inventar data. Fases com cerimônia usam a data real salva; fase atual usa `phase_since`. Sem campo novo.
- Fotos oficiais continuam provisórias (retrato do corpo e coat da fase). A etapa 13 fará as fotos reais.
- Entrega é validada com requisito de teste usando gravetos existentes, só no espelho descartável. Não
  criar item-chave antecipado ou caminho de teste no executável normal.
- `create_session` de claude-code-remote não está disponível; a próxima sessão será tentada com
  `create_thread` no projeto local, conforme autorização expressa recebida nesta conversa.

## Etapa 07 — fim do nível e prêmios (19/10/2026)

- Escolha permitida pela etapa: preservar `level`/`xp`/`progress.skills`, `level_reward` e tabela antiga
  como dados internos, para manter snapshots, simulador e testes simples. `level` não sobe;
  `_award_skill` só conta internamente, sem toast; XP não paga moedas, itens ou recibos.
  Não há novo reset nem alteração de SAVE_VERSION. A feature skills e sua UI saíram.
- Conversões: diárias atuais `care` e `tiro_walk` → Coragem 4; semanal atual `care_week` → Coragem 4.
  Definições legacy (ainda usadas por período ativo): daily `wishes`, `feed`, `play`, `tiro_walk`;
  weekly `walker_week`, `best_friend` → Coragem 4; daily `bathe`, weekly `clean_week` → Pelagem 4.
  Não tinham `player_xp` explícito no legado: substituímos o XP padrão implícito nesses casos.
  Obras `park_bench` (40 XP), `village_garden` (60), `park_picnic` (60), `village_festival` (100)
  → Coragem 5 cada, preservando a coleção da Festa. Passam por `_gain_pillar`, Radiante e reserva.
  O Encontro da turma preserva XP 10 interno por ciclo; seu chip foi removido. Demais XP permanecem
  invisíveis. Moedas de rotinas/obras, afeto, materiais, preços e tempos não foram alterados.
- Moedas: saem os presentes por nível (410 até o 10 e a fórmula depois); os presentes por fase
  da 02 somam 590. Não se afirma equilíbrio: efeito no meio da campanha será visto na execução
  rápida autorizada da 17, sem simulação nesta etapa.
- `treat_box` troca somente Cozinha 5 por Aventureiro, preservando bancada e geladeira.
  Natureza mantém XP/níveis locais: não são nível do jogador. Lista de textos revisada em
  `build/texts.csv`; ocorrências restantes são locais, vínculo ou código interno.
- Popover do HUD dura 8 s para permitir ler e tocar Ver (padrão genérico continua 2 s).
  Ajuste incidental achado no afetado: chip de ajuda da obra remove o redundante “Falta ”,
  pois a linha logo acima já informa a falta; Piquenique deixa de medir 367 px no painel de 360.
- Testes de nível agora exigem nível congelado, ausência de level_up/recibos e moedas intactas;
  festa visual testa ModalCard via tesouro. Testes de obras exigem Coragem e idempotência.
  A conta dos capítulos 10/11 na Festa separa 70 dos capítulos + 10 do vínculo 2 (antes a tolerância
  atribuía incorretamente esse extra ao nível). Nenhum assert foi afrouxado.


## Etapa 08 — cerimônia e portão (19/10/2026)

- `GrowthCeremony` usa só os PNGs existentes, com snapshots de fase e coat no recibo. Canvases
  256×216/48×48 e os originais do mundo 64/76/80/96 intactos; adulto preservado. Nenhuma arte nova.
- `ceremonies.<fase>` guarda `at`, `seen`, `before`, `before_coat`, `after_coat`, `delivered`.
  `seen` só muda em Que lindo!: uma interrupção retoma o cartão pendente uma vez, sem repetir
  consumo nem presente. A casca deduplica por fase e data; outro slot não herda a deduplicação.
- `pending_reveal` adia Mocinho/Azul e Dourado quando dormindo. A fase já muda; acordar na tela
  do Tiro ou fechar a linha de boas-vindas libera a revelação. `ready_seen` guarda a fase cujo
  aviso de pronto já foi exibido. Campos novos têm padrão vazio; SAVE_VERSION continua 13.
- Entregas já feitas voam apenas como feedback; sem entrega não há voo. Menos animação usa
  somente dissolve de 0,4 s e cartão sem confete. Transformação normal: 1 s de concentração,
  intervalos 0,54/0,48/0,42/0,38/0,34/0,34 s (2,5 s; ≤3 trocas/s), depois cartão e Novo!.
- Das features existentes da tabela 02 F, Desejos recebe `growth: puppy`, somado a `lais_bed`.
  Cada Novo! usa a fila já existente depois do cartão. Sem antecipar escova, itens-chave,
  missões de crescimento, fotos oficiais ou régua na Casa (etapas seguintes).
- Portão com `test_all.ps1 -KeepGoing -Skip economy_sim_test`: preservado `progression_test`
  explicitamente exigido pelo portão. Excluído somente o teste do simulador, pela instrução
  explícita do Vitor “Nenhuma simulação de economia”. Nenhum comando economy_simulate executado.
- Fixtures de Desejos/vínculo/produtos/listas/cuidados agora selecionam Filhotinho onde testam
  esses sistemas, preservando as verificações. `bond_test` tinha acesso a `player_xp` removido
  pela 07 (reproduzido no espelho da 07); agora exige Coragem 4 nas rotinas de cuidado/passeio.
  O teste usa relógio fixo para conferir o limite exato de ganho 3 sem queda entre duas leituras;
  o cenário de sorteio sem estação/passeio remove explicitamente fogão e `nina_walk` da fixture
  após o salto DEV, que já podia tê-los liberado. Nenhuma regra de jogo foi alterada por esses ajustes.

- No portão apareceram duas fixtures anteriores ao corpo/gates: `tricks_test` agora seleciona adulto
  para conferir roupas; `market_test` seleciona Aventureiro no cenário do contrato fabricado.
  Ambas passaram sem mudar produto, roupa ou assert. Registro bruto da suíte mantém 8 falhas;
  aceitação após essas repetições deixa os 6 testes históricos vermelhos. Os robôs de progression
  e onboarding produzem mensagens adicionais em relação à base; não foram adaptados ao crescimento
  antes da etapa 11. Ressalva explícita em VALIDACAO_08; não se declara suíte toda verde.


## 19/10/2026 — Etapa 09: refeições finais e catálogo de Cuidados

- IDs meals preservados. Saves v13 anteriores à 09 recebem growth.foods_revision = 1 uma vez: apaga-se somente o recibo meals dos crescimentos ainda não alcançados (Dentinhos/Aventureiro/Mocinho), e os novos contadores feed:frozen_carrot, feed:growth_kibble, feed:milk_porridge e shampoo_bath partem do valor atual. ready_seen é liberado para avisar quando o novo requisito estiver pronto. Fases já alcançadas, chaves, pilares, moedas e cerimônias ficam preservados. Sem outro reset; recarga testada.
- Feed não especificado na 03 C: frozen_carrot 20/5, puppy_mash 35/10 (exemplo da 03 A), corn_crunch 20/5, growth_kibble 35/10, egg_scramble 30/10, cheese_bites 15/10, milk_porridge 30/10 (fome/felicidade). Pilares, quantidades, tempos, desbloqueios e preços seguem a tabela sem ajuste. Xampu não é comida.
- Cuidados entrou em SheetBuilder.CATEGORIES para o xampu aparecer no Manual e filtro da Mochila. Escolha Com xampu é estática só na sessão e vale para toque/arrasto já existentes; desaparece sem estoque e banho comum continua disponível. A recarga compartilhada limita pontos, não o consumo nem o contador de banhos, conforme o motor da 03.
- growth_test trocou a fixture carrot_snack por frozen_carrot, mantendo o assert de que só a refeição pedida conta. Manual inicialmente detectou a categoria ausente; corrigida e repetida com PASS.


## 19/10/2026 — Etapa 10: itens-chave

- Ids de requisito preservados (`key`) em Dentinhos/Aventureiro/Mocinho/adulto: saves v13 em andamento mantêm `growth.done` e só precisam do item se ainda não cumpriram. Sem reset nem revisão nova (quem já passou a fase não é afetado; quem estava no meio precisa do item-chave, obtido pelas receitas/missões reais).
- Adulto: `owned atelier` e `project village_festival` saíram, conforme a tabela 02 C (medalhinha + lacinho + refeição); a refeição fica `feed any ×3` até a etapa 12. A medalhinha vem da `community_12_memory`, que já exige a Festa, então a obra continua no caminho.
- Lacinho: arte derivada do `yellow_bow` por rotação de matiz (sem PixelLab), a receita pede a fase Mocinho (`growth: young`) e usa as âncoras de cabeça já existentes do jovem.
- Ícones dos quatro itens-chave no PixelLab (seeds 10100–10103). `festival_test` passou a aceitar `courage_medal` no prêmio da lembrança; `growth_test` valida referência quebrada de projeto por um requisito de projeto acrescentado (o adulto não tem mais `project`).
- Não verificado nesta etapa: ritmo/economia dos novos itens (sem simulação, por regra) e o robô do simulador, que só cresce na etapa 11.


## 19/10/2026 — Etapa 11: a história conduzida pelo Tiro

- **Capítulo 1 passou a ter sete passos** (`growth_1_puppy` depois de `lais_bed`); `content_test` aceita 2–7 passos por capítulo (era 2–6). Não encurtei o capítulo nem fundi a missão: a regra da 04 é "crescer é o último passo".
- **`lais_stew` deixou de fechar o capítulo 3** (depois dele vêm `teeth_3_ring` e `growth_3_teething`); `tasks_test` esperava o prêmio do capítulo nele. O prêmio do capítulo é o mesmo, só sai mais tarde.
- **`dev_complete_quest`/`dev_jump_to_chapter` colocam o Tiro na fase** das missões `growth` que completam (`dev_set_phase`, só sobe). Sem isso todo teste que pula capítulos ficaria com o Tiro recém-chegado e travaria no capítulo 1. Os testes de truques e passeios (`tricks_test`, `walks_test`) agora fixam a fase explicitamente e ganharam a checagem "Quando ele for …".
- **`young_8_shampoo` paga 10 moedas** (a 04 não definia prêmio; as `growth_*` e os alias `shared_with` não pagam nada). Valor simbólico, igual a `main_5_cooking`/`main_7_greenhouse`; calibração fica para a 17.
- **O capítulo final ficou com a fala nova** ("O filhotinho da caixinha virou o Guardião do Vale…") no `final_chapter.description` em vez de uma missão: o painel da História mostra a descrição do capítulo.
- **Robôs de teste que cresciam por atalho:** `progression_test` e `onboarding_test` passam pelos crescimentos pelas ações reais (refeição da fase, item-chave, xampu, lacinho, `grow`) mas completam os **pontos dos pilares com `dev_add_pillar`**; o ritmo deles é de `pillars_test` e da calibração (17). Só o robô do simulador (`economy_bot.gd`) cresce 100% pelos gestos do jogador. `progression_test` também passou a fazer as obras da vila (capítulos 10–12), que a campanha antiga nunca fazia (era a falha histórica "Campanha deve concluir todos os capítulos"); o material das obras é posto na mochila, porque a cadeia delas é coberta por `projects_test`/`festival_test`/robô.
- **`onboarding_test`:** continua histórico, mas com menos falhas que a linha de base (o raro agora sai em 32 min; resta só "ocioso total", 540 s contra 240 s; a linha de base tinha 730 s). O tempo ocioso inclui esperas pelo pilar/vovó que a 17 vai calibrar.
- Limite do robô: sem ritmo calibrado. Diagnóstico solto (não é medida): 14 dias → Aventureiro/capítulo 9; 40 dias → Mocinho/capítulo 12.

## 19/10/2026 — Etapa 12: escovar e paladar

- **Semente do save:** `GrowthState.taste_seed` (sorteada em `GameState.reset`, derivada de `progress.started_at` em saves que não a têm). Favorita = `favorite_pool[seed % tamanho]`; reação de cada item = hash(semente + item) → 60% gostou / 30% estranhou / 10% careta. Tudo reproduzível; `tastes` guarda só a reação da primeira prova. Sem `SAVE_VERSION` novo.
- **Dois sinais:** `taste_discovered` (só na primeira prova) e `taste_reacted` (primeira prova + toda vez que a favorita é dada, para a dancinha "sempre"); o `PetAnimator` encadeia o clipe do sabor depois do `eat`.
- **Escovinha:** a recompensa de Dentinhos passou a incluir `basic_brush` (keepsake). Manual ganhou a fonte "Presente do Tiro" (`kind: growth`) para itens-chave que são prêmio de fase. Ícone do item = o mesmo `action_brush.png` (1 ícone novo, como a etapa manda).
- **Gesto:** toque simples na escova só avisa "Passe a escova nas costas dele"; a escovação vale ~600 px dentro de `back_rect` (faixa do corpo). Os nós só aparecem quando a escovada vai render (sem recarga); em recarga o gesto anima e o toast diz "Ele já está penteadinho".
- **Cinco cuidados em 360 px:** mínimo dos tiles baixou de 72 para 56 e o espaço entre eles de 8 para 4 quando há escova; círculos continuam 56×56.
- **Fixtures:** `growth_foods_test` e `pillars_test` medem ganho comum, então escolhem uma semente cuja favorita não seja o item testado (senão o +50% distorce). Os robôs (`economy_bot`, `progression_test`, `onboarding_test`) resolvem `favorite` para `favorite_food()`.
- **Adulto:** `meals` passou de `feed any ×3` provisório para `feed favorite ×3`. Como a favorita pode exigir ingredientes de animais, o "Como fazer" aponta o caminho da comida; se a favorita ainda não foi descoberta, lista até 4 comidas não provadas.

## 19/10/2026 — Etapa 13: álbum, motor e fotos garantidas

- **Contador "X/22", não "X/54":** o contador do álbum conta só as seções ativas (22 fotos) e vira 54/54 quando as outras quatro seções forem ativadas (15). Mostrar "X/54" com 32 fotos invisíveis seria um número que o jogador não consegue alcançar.
- **`on` pode ser lista:** `h_first_night` dispara na soneca **ou** ao receber `lais_bed` (condições: `quests` + `stat_min sleep_started 1`), para que quem dormiu antes da caminha não perca a foto. Novo contador `sleep_started`.
- **Eventos/condições a mais que a lista do 05 E**, para o catálogo caber no motor: eventos `intro_done`, `chapter_done`, `customer_delivery`, `bond_up`, `project_gathered`; condições `quests`, `quest_is`, `grew_to`, `trick`, `tricks_min`, `growth_food`, `rare`, `chapter_last`, `object`, `world_in`, `project_done`, `start_days`, `anniversary`, `after_days`, `chance`. As quatro seções inativas ficam no dado e validadas, mas só História e Primeiras vezes têm gatilho ligado nas ações (as outras entram na 15: `after_days` e `chance` ainda devolvem falso).
- **`d_full_moon` perdeu "Aventureiro+":** a regra "no máximo 3 condições" (05 A.4) e as quatro condições do catálogo (lua cheia, mundo, depois das 20h, fase) não cabem; fica lua cheia + Praça/Natureza + hora. A 15 decide se a fase volta como filtro de elenco.
- **Dentinho de leite:** não mexi em `finds.json`. O mecanismo é o mesmo do `quest_find`, em código (`_milk_tooth_due`): enquanto o save estiver em Dentinhos ou depois e nunca tiver achado o dentinho, o próximo montinho de qualquer mundo o inclui. Quem pulou direto para Aventureiro ainda o recebe. Item sem depósito, `sell_price` 0, fora dos grupos do álbum de achados (a foto `f_tooth` é o álbum dele).
- **Fotos com `phase`/`coat` gravados:** `PhotoCard` resolve o corpo pela fase da foto (mesma pasta de clipes do `PetAnimator`), então a foto continua mostrando o filhote depois de crescer. Roupas não aparecem nas fotos (só adereços).
- **Cenários:** recortes dos mapas atuais (`album.json → scenes`), sem arte nova. Cantinho = `corner.png`.
- **Seções no caderninho:** com até 3 seções ativas as abas mostram ícone + nome; com mais, só ícone (seis nomes não cabem em 360 px).
- **Fora desta etapa (como a etapa manda):** `HintButton`/lupa e `HangButton` (14/15); recompensas por quantidade de fotos (14); fotos com datas, secretas e sonecas (15).
- **Aviso "📸 Nova foto!":** o emoji não existe na fonte do jogo; o aviso é "Nova foto!" com o ícone do álbum, tocável (abre a foto).

## 19/10/2026 — Retomada da 14 após limite do Claude (Codex)

Histórico local recuperado (`ce5df0db-9717-5a66-9a5f-973c2248457d`), mudanças anteriores preservadas. Caminhas e tigela usam melhorias com materiais e zero moedas, conforme a implementação deixada; acesso agora no painel da caminha/tigela. `bed_level` é derivado das melhorias possuídas; não duplicado em campo salvo. Escolhas das fotos ficam em AlbumState, brinquedos/recibos de chegada em ProgressionState.house. Régua inclui a chegada e somente cerimônias registradas, sem inventar datas para fases escolhidas em DEV.

Arte procedural herdada foi mantida provisoriamente. Cinco tentativas PixelLab falharam por conexão HTTP, sem imagens. A 14 fica em andamento exclusivamente com essa pendência após a validação funcional; não abrir a 15. Teste de pilares atualizado para dar brinquedo de verdade e para isolar alimentação sem tigela opcional; validação de conteúdo reconhece o painel house:bed. Nenhum assert foi removido.

## 19/10/2026 — Pendência da 14 resolvida: PixelLab voltou

Após o pedido "Tenta de novo o pixellab", as 13 fontes foram geradas e baixadas. Os sprites procedurais foram substituídos por fontes PixelLab com preparo determinístico (`tools/house_art.gd`, manifesto de jobs/prompts/hashes em `tools/art/house_pixellab/`). Posições/footprints/canvases finais mantidos; régua corta apenas uma faixa de piso isolada gerada no fim do canvas; moldura frontal do cantinho usa a fonte nova. Adulto e todos os PNGs do Tiro preservados (2.019 hashes). Testes afetados e capturas finais conferidos; a 14 está concluída. Próxima: 15 em sessão própria.

## 19/10/2026 — Etapa 15: segredos, dicas e calendário (Codex)

- **32 fotos restantes:** a etapa dizia 40, mas o catálogo autoritativo é 14 + 8 + 13 + 8 + 6 + 5 = 54. As 22 da etapa 13 somam-se às 32 desta etapa; nenhum ID foi removido ou inventado para fechar a conta.
- **Lua cheia mantém Aventureiro+:** `world_in` aceita `{ids, phase_min}`, reunindo o cenário elegível numa condição; lua, cenário e horário continuam sendo três condições no dado. `hour` também aceita atravessar meia-noite (a bolinha vale das 20h às 6h).
- **Datas:** aniversário por calendário local, com 29/2 em 28/2 nos anos comuns. Foto única; festa anual com maior ano já comemorado, janela até o sétimo dia do aniversário, sem prorrogação por reabrir. Lupa usa maior dia local já gasto. Relógio para trás não devolve essas oportunidades já usadas. `cold_months` vem de config.json.
- **Arrasto:** cinco regas no MESMO gesto, sem somar Toque/Tudo ou dois gestos próximos. O cesto conta dois toques no próprio cesto, sem somar outro móvel. Soninhos guardam o local real (`AlbumState.sleep_spot`); tocar no sofá permite escolhê-lo, mesmo depois da caminha.
- **Fotos com roupa:** a foto agora congela `equipped` junto de fase/coat; quadros e âncoras existentes são reutilizados. Fotos anteriores sem esse campo continuam sem roupa. O chapéu do tesouro não tinha overlay e era impossível vesti-lo; ganhou adereço PixelLab e overlay separado, sem modificar qualquer PNG dos corpos do Tiro.
- **Pistas:** a contagem de três dias começa na primeira abertura da seção secreta. Cinco fotos são necessárias para a fala de dica. Recibos de falas, lupas, anos e local de sono entram no AlbumState sem alterar SAVE_VERSION. O brilho conserva a opacidade dos móveis bloqueados.
- **Arte:** adereços pequenos PixelLab, preparo nearest e fontes/prompts/jobs/hashes no repositório. Sombras e linhas de velocidade são formas desenhadas no preparo, como previsto no catálogo. Bolo e chapéu de festa são acessórios temporários, sem tomar o slot salvo de roupa.


## 19/10/2026 — Etapa 16: jeito e lembranças (Codex)

- **Média de dias jogados:** janela dos últimos 14 dias locais com atividades relevantes, sem contar ausências. Cada jeito soma até 1 por dia, com pesos no JSON; 65% da média recente + 35% da média histórica. Troca exige vantagem de 0,20 e ao menos três dias da janela em que o candidato pontuou mais que o atual. Isso impede que repetir mil ações num dia troque o jeito. Relógio atrasado permanece no último dia gravado. Histórico começa quando o campo é criado; não inventamos datas para contadores anteriores à etapa.
- **Fontes:** os mesmos contadores das ações reais (`walk`, `find`, `feed`, `play`, `trick`, `trick_learned`, `care_useful:pet`, `wish`, `bathe`); primeiras comidas de crescimento diferentes e primeiros mundos somam eventos próprios, sem criar objetivo ou recompensa. Soneca pontua quando passa pela conclusão real já existente (`_finish_pillar_nap`), não pelo cochilo visual.
- **Revelação:** antes de Aventureiro os comportamentos usam só a fase, e o título fica escondido. A partir dele, a novidade usa a fila existente e o recibo `personality:revealed`. Sem atividade prevalece Tranquilo; nenhum jeito muda regras.
- **Diário:** até 20 entradas `{at, day, kind, text}`, modelos no dado; fotos, primeiras provas e fases têm recibos separados das linhas, por isso descartar a linha mais antiga não permite duplicá-la. Passeios e achados raros podem voltar a acontecer e produzem uma nova lembrança pela ação real.
- **Animação:** somente clipes/PNG existentes. Dormir por alguns segundos na tela ou no mapa é apresentação; não chama `set_sleeping`, não dá energia ou pilares. O chapéu temporário também se esconde no cochilo visual do mapa. Corridas mantêm o caminho calculado, reações e revisões de navegação; tropeço é pausa/pulinho do sprite. Jeito soma pesos à fase.
- **Portão:** `brush_taste_test` existia desde a 12, mas faltava na lista de `test_all.ps1`; incluído para a passagem total cobrir o quinto cuidado. A suíte inclui o teste de regressão `economy_sim_test`; não foi executado `economy_simulate.ps1` nem uma rodada de economia.

## 19/10/2026 — Etapa 17: Pelagem de seda e simulador

- **Seda:** níveis, requisitos e presentes da 02 G em `growth.json → silk` (I: Pelagem 10, 5 dias de escovação, 3 banhos com xampu; II: 10 dias, 6 banhos; III: 20 dias, 10 banhos; 50/80/120 moedas). Dias = datas diferentes em `growth.brush_days`; banhos = total de `shampoo_bath` (sem base por fase, pois "nunca exige comprar nada" e o xampu já é obtido antes). A requisição é viva (não fica definitiva como na fase): se o contador cair o botão volta a bloquear, mas os contadores só crescem.
- **Brilho:** `sheen` 0,33/0,66/1 no `tiro_coat.gdshader` (faixa diagonal clara que desliza no pelo de luminância > 0,3, 45% no máximo); `sheen = 0` não altera pixel; `reduced` (Menos animação) deixa a faixa parada.
- **Simulador:** `growth_days`, `chapter_coins`, `end.phase/silk/pillars` no `summary.json`; seção 4b em `economy_compare.py`.
- **Ritmo:** nenhum número de crescimento foi ajustado (ver `RESULTADOS.md`): Dentinhos/Aventureiro saem cedo por mais de 2×, mas só um requisito com espera de calendário corrigiria, o que é decisão de desenho do Vitor. Moedas dos capítulos 5–9 registradas, preços intocados.
