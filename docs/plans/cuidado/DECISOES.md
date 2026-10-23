# Decisões

## Do Vitor

| Data | Decisão |
|---|---|
| 23/10/2026 | Repensar desejos, necessidades e pilares juntos; simplificar e dar utilidade. Direção aprovada: necessidade → cuidado útil → momento → crescimento; desejo como voz do crescimento; Tiro animado com efeitos no jogo. |
| 23/10/2026 | **Saves sempre zerados**: não precisa se importar com compatibilidade. Sem migração e sem teste de save antigo. Substitui a regra antiga do `CLAUDE.md` ("não ampliar o ramo de reset"). |
| 23/10/2026 | Testes por ciclos que fazem sentido com o que a etapa mexe; ciclo total com simulação de tempos só no fim. |

## De desenho (propostas do planejamento; o Vitor pode vetar)

| Decisão | Por quê |
|---|---|
| **Vínculo (afeto/corações) sai.** Truques e passeios passam a exigir fase. | duas barras para o mesmo cachorro; o crescimento é o objetivo |
| **Aba Desejos sai**; o desejo vive num balão na tela do Tiro e no avatar. | com um desejo só, uma aba inteira vira tela vazia |
| Um desejo por período (manhã/tarde/noite), sem trocar. | resolve o "pede coisa toda hora" e dá um motivo para voltar em horários diferentes |
| Corpo continua pelas refeições da fase; Energia não dá momento; nap deixa de dar Corpo. | as refeições já funcionam (correção de 20/10); menos regras |
| Escovar vale 1 momento por dia, sem necessidade própria. | não criar uma quinta necessidade |
| Esconde-esconde custa um petisco. | liga a Esperteza à produção da fazenda |
| Código de migração (`EconomyMigration`, `legacy_r0.json`) **fica** por ora; só os testes de save antigo saem. | remover mexe em `SaveManager`/`from_dict` sem ganho para o jogador; faxina própria depois, se o Vitor quiser |

## Ajustes durante a execução

- **23/10/2026, etapa 06 (Codex):** `lais_first_wish` abre o capítulo 2 (ordem 5), depois da caminha e do primeiro crescimento. A feature de desejos já exige Filhotinho; pôr o passo antes desse crescimento bloquearia a história circularmente. `growth_1_puppy` continua encerrando o capítulo 1. O contador `wish` não é fresh: se já atendeu, o primeiro desejo vale, sem esperar outro período. Sem prêmio adicional. A fala de Tiro animado entra em `lais_first_crops`, no capítulo do Sítio. Agora são 111 missões, 51 principais.
- **23/10/2026, etapa 06:** roupas de `care_week`: `clean_bow` e `walker_bandana` vão para `big_harvest`; `heart_collar` para `orders_week`. Sorteio continua escolhendo uma roupa ainda não obtida. Contagens mantidas em 3 diárias/2 semanais, iguais ou menores que os respectivos catálogos (3/3); no começo, só a colheita disponível é sorteada. Catálogos `legacy` e seu fallback de consulta removidos de verdade, inclusive os modelos antigos de cuidado/passeio/desejo. `SAVE_VERSION` 17 zera rotinas persistidas com esses IDs, sem migração nem teste antigo.
- **23/10/2026, etapa 06:** “Somar 4 corações de amizade” virou “Chegar a 4 de amizade com a turma”, sem mudar a regra dos amigos; `texts_test` veda vínculo/afeto/corações e referências antigas de desejo, sem diferenciar maiúsculas nessas palavras novas. Regras históricas do glossário preservam sua sensibilidade a maiúsculas. O catálogo de desejos permanece igual; incluir copinhos fica para eventual calibração da 07, não integra a entrega de missões.

- **23/10/2026, etapa 00, pedido do Vitor:** encadear em outra sessão do Codex, mesmo projeto/ambiente local, modelo `gpt-6.1-sol`, em vez de Claude Sonnet. Só abrir a 01 se todos os critérios da 00 fecharem.
- **23/10/2026, etapa 00:** a suíte canônica fica no campo `suite` do `test_areas.json`; o atalho antigo passa a chamar portão + campanha. Novos testes entram também em uma área ou na campanha, sob validação de órfãos. O mapa incluiu `festival_test` e `item_sources_test`, que existiam fora da lista antiga.
- **23/10/2026, etapa 00:** removidos os limites de espera total do protótipo pré-R1 no `onboarding_test`; com culturas de duração maior esses limites já não descreviam o jogo. Primeiras colheita/desejo/achado, capítulo 4, passeio e raro continuam com prazos e asserções; espera é medida e registrada. Fixture agora tem semente fixa, relógio injetável e vende excedente quando o silo enche (sem alterar o robô da campanha ou regra do jogo).
- **23/10/2026, etapa 00:** cenários atuais que comprovam snapshot de um trabalho iniciado, persistência no formato atual, garantia em passeios repetidos e histórico de missões continuam. Saíram as fixtures de versões anteriores/campos faltantes e chamadas de migração. Código de migração preservado.
- **23/10/2026, etapa 00:** `station_tray_test` foi inspecionado e preservado por conter o trabalho local protegido de receitas; suas esperas não foram otimizadas nesta etapa. Os demais ajustes encurtam somente esperas de layout ou repetição, mantendo a chegada real do Tiro ao banco.

- **23/10/2026, etapa 00:** em paralelo, esperas fixas de UI mostraram corridas; `tray_test` e `world_selector_test` agora esperam a bandeja com prazo máximo, sem aumentar esperas em todos os passos. No banco, a fixture remove o faro aprontado por `dev_finish_timers` e usa o manipulador da obra para testar chegada/callback (o toque continua coberto em três zooms). Isso evita uma segunda ação autônoma cancelando a que está sob teste.
- **23/10/2026, etapa 00:** `park_test` admite meia diagonal da célula de navegação (8 px) ao verificar destino perto da Nina; `petshop_test` começa os passeios com inventário vazio, pois materiais da costura anterior podiam lotar o baú e tornar a coleta vazia. As duas fixtures têm semente fixa. `dev_tools_test` espera o passo do baú da Nina antes da Natureza, conforme a história local atual.

- **23/10/2026, etapa 00:** a fixture de `progression_test` também precisa informar `world_id: village` nas vendas e realizar a primeira venda quando a missão aparece. Ajuste de chamada à API atual, antes da única campanha; `economy_bot.gd` e os drivers de simulação continuam intactos. Sem tempos medidos, o runner usa referências históricas para a campanha (24,5 min progressão, 55 s fidelidade, 6 min Quick), em vez de estimar esses testes longos em 15 s.

- **23/10/2026, etapa 00, pendente de resposta do Vitor:** durante a campanha única, a inspeção encontrou que `progression_test` não abre o Álbum, mas cobra também `lais_album`. A fixture foi ajustada para chamar `note_album_section("story")` quando essa missão está desbloqueada; parse PASS. O processo já iniciado conserva a versão anterior. Solicitada autorização para interromper/repetir somente esse teste, sem repetir Quick; sem resposta, respeitar o limite original e registrar o bloqueio se a campanha não fechar. Não abrir 01 com falha aceita.

- **23/10/2026, fechamento parcial da 00:** sem resposta à autorização de reexecução focada, o limite original foi preservado. A tentativa antiga de `progression_test` foi interrompida no ciclo 400 (526,3 s), quando o log confirmou só `lais_album`; não foi repetida nem aceita como PASS. Os demais cinco componentes passaram, inclusive Quick 110/110 com zero guardas. Etapa bloqueada; 01 não aberta. O portão (87 PASS) excedeu a meta de 8 min em 26,2 s, registrado como excesso de orçamento, sem falha de teste aceita.

- **23/10/2026, fechamento da 00:** Vitor autorizou criar a sessão da 01 antes de fechar a pendência e, depois, autorizou testar ("Vai testando aí entao"). Reexecutado somente `progression_test` com tag própria: PASS, 767 ciclos, 64 aquisições e 110 missões, exit 0 e stderr vazio; aproximadamente 959,3 s pelo intervalo do log. Portão e Quick não repetidos. Bloqueio superado, etapa 00 concluída; sessão da 01 já existe no Codex 6.1. Registros parciais anteriores são históricos.

- **23/10/2026, etapa 02 (Claude Code, continuação do Codex):** `wishes.json` reescrito em 11 desejos (`pet`, `meet`, `walk`, `walk_long`, `play`, `dig`, `trick`, `bath`, `shampoo`, `brush`, `meal`) com `pillar`, `phases`, `goal`, `go`, `need` e `requirements`/`have_item`. **`phases` é a fase que o Tiro está buscando** (a próxima, igual às linhas da tabela de requisitos do 02 B), não a atual; no adulto vale a última. O desejo de comida (`meal`) resolve a comida da refeição da fase quando dá para fazê-la ou tê-la; senão vira "Tô com fome" (qualquer comida). Corpo não ganha momento ao atender (a refeição já conta); os outros pilares ganham 1 fora do teto.
- **23/10/2026, etapa 02:** o desejo "esconde-esconde" (Esperteza, Aventureiro/adulto) **não entrou** no catálogo: o gesto só existe na etapa 04; entra lá junto da fonte `hide`. Também ficou de fora "ir a um mundo" (sem contador próprio; o primeiro mundo já rende o momento de Coragem). "Passeio longo" usa o contador `walk` com a trava de fase dos passeios.
- **23/10/2026, etapa 02:** o primeiro desejo (`pet`) chega assim que `lais_bed` + fase Filhotinho abrem o recurso, em qualquer período (inclusive madrugada); os seguintes só nos períodos manhã/tarde/noite, um por período (`WishState.period`), e o da noite continua na madrugada. `last_ids` guarda 4; o sorteio evita os 2 últimos (`keep_last`).
- **23/10/2026, etapa 02:** truques já tinham `growth` em todos; só se retirou `bond`. Passeios longos: `creek_walk` Aventureiro (já era), `bird_clearing` → Mocinho, `hill_view` → Azul e Dourado. Prêmios `affection` das missões foram trocados por 10/15 moedas nas três missões que só tinham afeto; nas demais só saiu o afeto. `nina_blueberry` pede agora `feed:blueberry_treat` (o desejo de petisco de mirtilo saiu).
- **23/10/2026, etapa 02:** fotos: `p_belly_up` troca `bond_min 4` por `phase_min explorer`; `a_lais_lap` (antes `bond_up`) passa a `petted` com `phase_min adult`. Condição `bond_min` e evento `bond_up` removidos de `AlbumRules`.
- **23/10/2026, etapa 02:** o ícone `bond_heart` foi renomeado para `heart` (usado também por amigos, paladar e "Ele quer!"). `SAVE_VERSION` 15 (saves zerados). A aba Desejos continua só com o cartão do desejo de agora; a 03 a tira. O robô do simulador (`economy_bot.gd`) foi só adaptado à API nova (`fulfill_wish()`); a política por momentos é a etapa 07.

- **23/10/2026, etapa 03 (Claude Code, Codex sem limite de uso):** o aviso de momento vive na casca (`main.gd`), não na tela do Tiro, para valer também para momentos de passeio/mundo/desejo; o `+N` flutuante da `PetScreen` saiu. As mensagens do balão de fala do Tiro ("Momento de Coragem!"/"…Esperteza!") continuam. O anel do HUD e o do selo de crescimento passam a contar fração de momentos (`GrowthUi.fraction`); requisito cumprido vale 1.
- **23/10/2026, etapa 03:** a feature `wishes` (Novo!) continua, mas aponta para a tela do Tiro; `Places`/`TaskHelp` levam a `screen: pet` em vez de `wishes`. Tocar no Tiro dentro do mundo agora sempre abre a tela do Tiro. "De onde vêm" é dado em `growth.json → moments.sources[].label/go` (só as fontes com `label` aparecem). O ícone de pilar nos anéis só aparece enquanto a necessidade pede (`ask_below` 50); Felicidade mostra Esperteza só quando falta mais Esperteza que Coragem. O selo "Animado" do avatar fica para a 05.
- **23/10/2026, etapa 03:** `park_test` falhou uma vez no portão em paralelo ("sem espaço: não guarda") e passou isolado; tratado como instabilidade, não corrigido nesta etapa.

- **23/10/2026, etapa 04 (Claude Code, Codex sem limite de uso):** `growth.json → gestures` guarda tudo: `hold_seconds` 1,2, `rub_distance` 160 px (esfregar contínuo), nomes das três zonas e `hide_seek` (fase `explorer`, 3 copinhos, trocas 3/4/5). Segurar e esfregar compartilham a trava `_hold_done`: **um carinho por gesto** (toque curto = só festa, sem carinho). `GameState.pet(zone)` ganhou a zona; o favorito é `hash("spot:<taste_seed>") % 3` e usa a ação `pet_favorite` (+25 de Felicidade; o carinho comum continua +3 de `actions.pet`). Primeira vez: diário (`templates.spot`), aviso "Ele ama carinho na barriga!" e `Events.favorite_spot_loved(zone, first)`; `PetAnimator.love()` rola de barriga para cima. Zonas = `PetScreen.SPOTS` em frações do quadro (cabeça/queixo/barriga), como o `back_rect`.
- **23/10/2026, etapa 04:** esconde-esconde em duas chamadas: `hide_and_seek(item)` gasta o petisco e deixa a rodada pendente (só em memória: fechar o jogo no meio perde o petisco), `finish_hide_and_seek(found)` paga o momento de Esperteza (fonte `hide`, teto do período) e Felicidade `actions.hide` +10, acertando ou não; sem rodada pendente não faz nada. Petisco = campo `treat: true` em cinco itens. Brincar com um toque abre a escolha Bola/Copinhos desde o Aventureiro (arrastar continua arremessando a bola); sem petisco, o motivo aparece com cadeado. Arte: `hide_cup.png` 32 px (PixelLab) em `ui/icons/`.
- **23/10/2026, etapa 04:** o desejo "esconde-esconde" **não entrou** em `wishes.json` (mudaria a contagem dos 11 desejos e os testes da 02/03); fica como sugestão para a 06 ou o ajuste de ritmo da 07.

- **23/10/2026, fechamento da 04 (Codex):** o toque Web encontrou Bola/Copinhos cortado pelas abas e a pressão dos botões propagando ao fundo, fechando o menu antes da seleção. Corrigido no `Popover`: abrir acima quando faltar espaço abaixo, conter a posição no host e fechar só por pressão fora do cartão. Regressões por geometria e clique roteado no `gestures_test`; sem mudar regras, arte ou save. `touch_test.ps1` passou a suportar segurar e capturar durante a pressão; roteiro reproduzível em `tools/care_gestures_touch_steps.json`.
- **23/10/2026, fechamento da 04:** conforme o pedido específico do Vitor, a falha do seletor foi investigada e registrada como preexistente/intermitente: mesma asserção na rodada inicial da 01, PASS isolado e na primeira bateria desta continuação, reaparecimento em rodada adicional. A rodada com FAIL não conta como verde; seleção final dos afetados da 04 e revalidação do Popover verdes. Evidência e limitação em `VALIDACAO_04.md`; causa interna do seletor não corrigida. `create_thread` não consta das ferramentas disponíveis; encadeamento da 05 não realizado e etapa seguinte não executada.

- **23/10/2026, etapa 05 (Codex):** o faro extra mantém a regra de um montinho pendente por mundo: antecipa um montinho após escavar, somente em mundo aberto, com limite **global** de um por período (os mesmos quatro períodos dos momentos). Não empilha nem substitui montinho pendente; não adia o relógio do normal. `FindState.bonus_period/bonus_used` e a marca `animated_bonus` persistem o limite e a origem. `SAVE_VERSION` 16; reset, sem migração/teste antigo. O fluxo existente escolhe ponto e recompensa.
- **23/10/2026, etapa 05:** a colheita usa a semente do Tiro + índice + timestamp do plantio normalizado em milissegundos (JSON conserva o sorteio). O CollectFx da sala já recebe todo o lote, evitando emitir efeito duplicado. O passeio congela tanto a condição quanto a quantidade extra **antes** do custo de energia; bônus de bolsa/amigo existentes continuam somando. O brilho fica estático com Menos animação. Simulador e etapa 06 não alterados.


- **23/10/2026, etapa 07 (Codex):** robô passa a usar necessidades/momentos, desejos, escova diária e
  copinhos. `hide` no runner representa começar e terminar uma rodada, com um petisco e 12 s de ação;
  a guarda confere o consumo. A semente inicial também fixa o sorteio do cachorro (agora usado pelo
  bônus da colheita); ausência entra/sai pelos métodos reais entre sessões, inclusive no reload atual.
- **23/10/2026, etapa 07:** `progression_test` reutiliza a política de cuidados e o relógio/cache do
  simulador, sem `dev_add_pillar`/concessão artificial de momentos. As fixtures econômicas anteriores
  continuam aceleradas e não são evidência de ritmo. Seu limite inicial de encomendas não pode impedir
  uma entrega fresh posterior: abre exceção enquanto há objetivo ativo de novas encomendas.
- **23/10/2026, etapa 07:** teste da Praça atualizado para a retirada de `tiro_walk`; mochila cheia
  usa recompensa exclusivamente de cenoura, pois garantia/consolo em outro depósito permitiam uma
  retirada parcial legítima. Fidelidade do simulador isola colheita sem Animado; o bônus tem `mood_test`.
  Auditor estático deixa de exigir vínculo/afeto removidos. Nenhum formato de save foi mudado.

- **23/10/2026, fechamento da 07:** limite aplicado conservadoramente às duas invocações do nível
  campanha, incluindo a tentativa técnica inválida. A segunda mediu cinco crescimentos, mas o Quick
  parou em `nina_blueberry` (110/111): objetivo `feed:<item>` ignorava o item; política corrigida e
  regressão pelo GameState real validada. Sem terceira campanha, sem declarar o Quick verde.
  Não foram aplicados números sem uma rodada disponível para verificá-los. Dentinhos 0,34 d,
  Aventureiro 2,08 d e Mocinho 8,84 d ficam como diagnóstico para o Vitor; adulto 19,84 d dentro.
  Aprovação não presumida, plano com ressalvas. Registro completo em RESULTADOS.

- **23/10/2026, portão final:** hud_growth/lists deixam de fabricar rotinas removidas e usam metas
  congeladas reais; Natureza usa relógio injetável; Festa passa a contar 51 principais (primeiro
  desejo da 06). Segunda passagem 90 PASS/1 FAIL em 465,2 s, última fixture reexecutada PASS
  (441 verificações). Validação final composta dos 91, CSV bruto preservado. Sem terceira passagem
  completa para uma alteração de expectativa; nenhuma falha chamada de histórica.

## Aprovação final do Vitor — 23/10/2026

- Ritmo atual aprovado por enquanto, sem nova calibração: Filhotinho 1,5 min de jogo ativo;
  Dentinhos 0,34 dia; Aventureiro 2,08 dias; Mocinho 8,84 dias; adulto 19,84 dias. Os desvios
  em relação às faixas iniciais ficam aceitos e documentados.
- Terceira rodada da campanha Quick dispensada. Evidência aceita como está: 110/111 + teste
  focado de `nina_blueberry` PASS, sem anunciar Quick 111/111 ou alterar os logs anteriores.
- **Plano Cuidado concluído e aprovado pelo Vitor, etapas 00–07, com essas ressalvas.**
  Fechamento apenas documental, sem novos testes, export, commit, push, publicação ou sessão/thread nova.
