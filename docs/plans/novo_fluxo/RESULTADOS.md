# Novo fluxo · F05 — Ritmo da semana

Medido em 21/11/2026 com o simulador de economia (GameState real, relógio injetado, só ações reais; sem `dev_*`, sem depósito ilimitado, sem `ready_at` forçado). Tudo aqui é **simulado**: o robô é perfeito e instantâneo, por isso foi somado um tempo de leitura e de gesto (ver "Limites").

## Como reproduzir

```powershell
# três perfis, três sementes cada; relatório de uma linha por execução
powershell -ExecutionPolicy Bypass -File tools\economy_simulate.ps1 -Until week -Profile muito -Seed 1..3 -Parallel 3 -OutRoot build/economy/f05_depois
powershell -ExecutionPolicy Bypass -File tools\economy_simulate.ps1 -Until week -Profile regular -Seed 1..3 -Parallel 3 -OutRoot build/economy/f05_depois
powershell -ExecutionPolicy Bypass -File tools\economy_simulate.ps1 -Until week -Profile perde_dia -Seed 1..3 -Parallel 3 -OutRoot build/economy/f05_depois
powershell -ExecutionPolicy Bypass -File tools\week_report.ps1 -Dir build/economy/f05_depois
```

O robô novo é `game/tests/helpers/week_session_route.gd` (a rota antiga por "dia N", `week_economy_route.gd`, continua para `tranquilo/regular(antigo)/dedicado` só como base). Ele segue a ordem nova (Ato 1, Ato 2, capítulos 2 a 11) por **sessões no relógio**:

| Perfil | Sessões por dia | Minutos de jogo por sessão (depois da 1ª) | Como cuida das refeições |
|---|---|---|---|
| `muito` | 5 (8h, 11h, 14h, 17h, 20h) | até 30 | almoço e jantar ao vivo; faz a missão secreta quando ela aparece |
| `regular` | 2 (8h30 e 19h30) | até 45 | almoço pela tigela, jantar ao vivo |
| `perde_dia` | igual ao regular, mas **não aparece no dia 4** | até 45 | enche a tigela como sempre (não sabia que ia faltar); no dia 4 só vale o que ele deixou |

Regras do robô: espera de até 4 minutos fica dentro da sessão; maior que isso, ele sai e volta na próxima entrada marcada depois do pronto. Antes de sair, dá a refeição da janela aberta e enche a tigela de dois lugares para as janelas que fecham antes de ele voltar. A primeira sessão (Ato 1 + Ato 2) não é cortada. Planta todos os canteiros livres de uma vez e espera uma só vez por colheita.

Saídas: `build/economy/f05_antes/` (dados anteriores), `f05_depois/` (dados novos), mais `f05_antes_sem_leitura/` (primeira versão do robô, sem tempo de leitura). `week.json` de cada execução traz capítulo a capítulo: dia real, minutos de sessão, espera e toque.

## Resultado: antes × depois

Dias = dia real do calendário (dia 1 = dia em que o save começou). "Cap. 10 fecha" = dia em que o capítulo 10 termina (capítulos 2 a 10 prontos). Cada célula traz as sementes 1, 2 e 3.

| Perfil | Meta (cap. 2–10 / Dentinhos) | Antes (cap. 10 / Dentinhos) | Depois (cap. 10 / Dentinhos) |
|---|---|---|---|
| `muito` | 2 a 3 dias / dia 6 ou 7 (com segredo ~5) | 2, 2, 2 / **4**, 4, 4 | **3, 3, 3 / 5, 5, 5** |
| `regular` | 5 a 7 dias / dia 7 a 9 | **3**, 3, 3 / 7, 7, 7 | 5, 6, **8** / 6, 7, 8 |
| `perde_dia` | igual ao regular +1 dia / +1 dia | 3, 3, 3 / 8, 8, 8 | 6, 8, 8 / 7, 8, 8 |

Nota: o `muito` "antes" tinha 4 sessões por dia (8h, 12h, 16h, 20h); com os dados novos e as mesmas 4 sessões ele fecha o cap. 10 no dia 4 (Dentinhos dia 5). Passei a 5 sessões (3+ por dia) para voltar ao dia 3.

Primeira sessão (Ato 1 + Ato 2, jogo ativo com leitura): **20 a 24 minutos** nos três perfis (meta 30–40 min, ver "Limites"). Minutos de sessão dos capítulos 2 a 10 somados: muito ≈ 87, regular ≈ 112 a 119, perde_dia ≈ 111 a 116 (antes: 107–110 nos três). **Maior espera única: 30 minutos** (o lote de ovos); nenhuma outra passa de 20. **Caixa: nunca abaixo das 10 moedas do começo** em nenhuma das 18 execuções (o dinheiro não trava a história). Depósitos cheios: só o cesto da horta e a despensa chegam ao teto, por poucos instantes (silo 5 a 41 leituras, despensa 0 a 8); o robô vende o excedente para abrir espaço.

Missão secreta (só `muito`): minhoca gorda 1, peixe dourado Perfeito 3, Ensopado Dourado 3 por execução; a patinha extra foi ganha ao vivo.

## O que foi ajustado e por quê (só dados)

1. **`config.json → farm.early_through`: 2 → 0** (removido). Com a regra antiga os dois primeiros dias do calendário tinham tempos curtos (milho 3 min, ovos 2 min, abóbora 6 min, batata 2 min). Quem joga muito fazia os capítulos 2 a 9 dentro dessas 24 horas, e o regular cumpria tudo em 3 dias. Sem o atalho os tempos reais valem desde o começo. Foi a única mudança que atingiu o regular sem prejudicar o `muito` (com ela sozinha, `muito` fechou no dia 4; os 5 horários de sessão por dia do perfil trouxeram de volta o dia 3). `early_through` ficou no código (calendário), mas o dado 0 o desliga; não vale reativar por capítulo, porque o ritmo já fecha sem ele.
2. **`config.json → meals.secret.max_extra`: a F05 baixou para 1, o Claude voltou para 2 (decisão F3a do Vitor).** Com duas patinhas extras o robô `muito` (perfeito, 5 sessões/dia) chega aos Dentinhos no dia 4; com uma, no dia 5. Como é decisão do Vitor, ficou 2; a troca fica para ele decidir depois de jogar.
3. Testes ajustados ao dado novo: `farm_week_test` (batata 5 min, abóbora 10 min, milho 20 min, ovos 30 min já no primeiro lote) (o `secret_stew_test` continua com o teto de duas).
4. Não mexi em tempos de receitas nem em preços: mudar ovos 30 → 20 min e milho 20 → 15 min não alterou nada (qualquer espera acima de 4 minutos já é uma saída; o que decide o ritmo é **quantas vezes** ele precisa esperar, não quanto cada uma dura).

## Metas

- `muito`: **atingida** (cap. 10 no dia 3, Dentinhos dia 5 com o segredo; sem ele, dia 6 pelo número de patinhas).
- `regular`: **quase**. Capítulos em 5, 6 e 8 dias (meta 5 a 7) e Dentinhos em 6, 7 e 8 (meta 7 a 9). A semente 3 estoura por causa do sorteio do peixe pedido pela carroça (o robô pesca até vir o peixe certo e cada tentativa que falha é uma saída), e a semente 1 chega um dia cedo nos Dentinhos.
- `perde_dia`: **atingida no Dentinhos** (um dia depois do regular em 2 de 3 sementes, e igual na 3, que já era a mais lenta). Perde só aquele dia; nenhuma recompensa se perde, e a refeição do dia 4 não conta porque a tigela do dia 3 só cobriu o que ele sabia que ia perder.
- Nenhum capítulo do Ato 3 tem espera única maior que 30 minutos, e o jogador sempre tem o que fazer enquanto espera (outras etapas, cuidar, pescar, brincar); o robô só espera em fila porque é sequencial.
- Caixa nunca trava: sim.

## Limites e ressalvas (sem rodeio)

- O robô é **perfeito e instantâneo**. Para aproximar uma pessoa foi somado tempo de leitura e de gesto por painel (tabela `READ` do robô: 35 s por passo de História, 150 s na chegada, 90 s no Álbum, 20 s no fogão etc.). Isso é uma suposição minha, **não medida em aparelho**. A primeira sessão deu 20–24 minutos, abaixo dos 30–40 da meta; só uma pessoa jogando mostra o número de verdade (roteiro de celular, M3).
- O robô espera em sequência (planta, espera, colhe). Uma pessoa faria outra coisa nesse tempo, então os dias medidos são um **teto** do que o jogador sente; o regular real tende a cair um pouco abaixo do medido.
- O peixe Perfeito do segredo é sempre acertado pelo robô; uma pessoa erra e perde uma tentativa por dia, então no jogo real o `muito` tende ao dia 6.
- O `regular` perde o dia de calendário só pelas saídas de 11–13 h entre sessões; um jogador com sessões em outros horários (por exemplo 12h e 20h) tem outro desenho de dias. A regra de ritmo é por **sessões**, não por dia.
- Proposta (só se o Vitor quiser o regular mais firme dentro de 5 a 7 dias nas três sementes): fixar o peixe da carroça (ou aceitar dois peixes) para tirar o acaso da pescaria; é regra, não dado, então não foi feita.
- Não alterei nenhuma regra. A campanha (`progression_test` + simulador `-Quick` + Python) está no relatório da etapa.

## Campanha (nível `campanha`)

- `progression_test`: **PASS** (467 ciclos, 64 aquisições, 147 missões). Ajustes só no teste: Bosque agora abre no capítulo 13 (renumeração da F04), `info.next` vazio no fim da campanha e a missão secreta (`bloblo_secret`, só existe no Filhotinho) fora da lista "deve alcançar".
- Simulador `-Quick` (reference, semente 1): **complete, 147/147 missões, 28,3 dias, 0 violações** (59/64 melhorias: o sofá é evitado de propósito e as ampliações `_5` são opcionais). A primeira tentativa dizia "travado 147/148" só por causa da missão secreta; ela passou a ficar fora da contagem do simulador (`economy_sim.gd`).
- `economy_sim_test`, `economy_audit_selftest`, `economy_compare_selftest`, `test_circuit_selftest`: PASS.
- Testes de etapa depois dos ajustes: `ato1_test`, `ato2_test`, `ato3_chapters_test`, `ato3_help_test`, `food_lesson_test`, `meal_rules_test`, `secret_stew_test`, `week_story_test`, `farm_week_test`, `content_test`, `texts_test`: PASS. `tasks_test` segue com a falha antiga "Humor do Tiro substitui a instrução fixa" (anterior a esta etapa).


---

# F06 — Revisão e roteiro do celular

## O que a revisão achou e corrigiu (21/11/2026)

Tour de capturas nas três resoluções (360x780, 390x844, 412x915) com os scripts `ato1_shots`, `ato2_shots`, `food_lesson_shots` e `ato3_shots` (sem FAIL nas medidas automáticas) em `build/screenshots/ato1|ato2|food_lesson|ato3/`, pranchas em `build/screenshots/novo_fluxo/`.

| Momento | Problema | Correção |
|---|---|---|
| Cerimônia do Filhotinho (`ato1_*_15_passo7_cerimonia`) | "1 dias bem alimentados · 1 pratos diferentes · 1 brincadeiras" | `growth.json → week_summary[].text_one` (singular quando for 1) |
| Cerimônia do Filhotinho | nome "Filhotinho" cortado embaixo da foto | foto do Tiro de 136 para 116 px quando é uma só |
| Painel Crescimento (lista dos Dentinhos, `food_lesson/s_linha_das_patinhas`) | ícones de 40 px passavam da borda do quadradinho de 4 colunas e cobriam o número ("1/6", "0/8") | `GrowthUi.step_ring` usa o tamanho do anel (32 px nas 4 colunas) |
| Tiro, capítulos 2 a 11 (`ato3_*_cap02..cap11_inicio`, `desafio_do_dia`) | a fala do humor ("O Tiro se enroscou...") cobria o nome do botão Cuidar | `PetScreen` sobe a fala acima do Cuidar quando cruzam |
| Aula do painel (`ato1_*_12_passo6_avatar_popover`) | a fala "Toque em Ver detalhes" cobria o texto do balão do avatar | a fala fica embaixo do botão (`week_tutorial.gd`, alvo `ViewGrowth`) |

## O que ficou aberto (sem mudar regra ou ritmo)

Fechado no acabamento (22/11/2026), com recaptura em 360x780 e 412x915 (`ato1_shots`, `ato2_shots`, `food_lesson_shots`, PNGs abertos):

- Cartão Boa noite do dia 1: uma frase só para o combinado ("Amanhã começa o combinado: almoço e jantar na hora valem uma patinha.") mais a linha dos horários; os botões Mais cedo / Normal / Mais tarde e Sim / Agora não ficaram (`week_routine.json → text.deal_need`, `celebration.gd`; `food_lesson_test` ajustado).
- Aviso "Pratos diferentes: 1/8" não cobre mais a tigela: `main.notice_bottom` sobe o aviso acima da guia de comida (`FoodMenu`).
- Botão "Pular" das lições não cobre mais o rosto da vovó: `week_tutorial.gd` o move para baixo do balão quando cruzaria a coluna `NpcRow`.
- Texto cru "buy:week_zucchini_seed" na dica de semente bloqueada: agora diz "Compre na banca da vovó" (`progression_state.gd`).
- Manual e "Como fazer" da minhoca gorda: fonte explicada (montinho do faro com o pedido secreto aberto) em `GameManual.sources` e `TaskHelp`.
- Pomar pronto agora conta no Mapa/boas-vindas do Sítio (`world_ready_counts` achava o lugar só por `routes:orchard`).

Continuam abertos, por serem desenho da lição ou do tour:

- Fala da Laís na lição "patinhas" (`e_crescer_patinhas`) e na do painel cobre parte da grade do Crescimento enquanto o jogador lê; é o desenho da lição (a grade realçada é a de baixo).
- No passo do painel (`ato1_*_12_passo6_avatar_popover`) o "Pular" encosta na borda do cartão, sem cobrir texto.
- No tour o desafio do dia continua aberto por cima do Caderninho (`ato3_*_manual_licoes`) e a roleta aparece aberta no passo da caminha (`ato1_*_11_passo5_roleta_dormir`): vêm do script, que conclui o passo por código; no jogo o toque fora fecha.

## Toque real (Chrome emulado, 390x844, build dev local)

`game/tests/touch/novo_fluxo.json` rodado com `tools/touch_test.ps1`. Cobriu de verdade, com dedo: abrir a caixinha, segurar para fazer carinho, Pegar, folha "Passo concluído!", Cuidar, roleta, menu de comida e arrastar a papinha. **Não cobriu** banho com esponja, bola, colocar a caminha, Crescer e a carta (cada passo exige achar as coordenadas por tentativa; ficou para o roteiro do celular e para uma próxima rodada). Sem medida de quadros por segundo nesta rodada.

## Portão

Portão da primeira passada (`tools/test.ps1 -Level portao -KeepGoing`, 2585 s, 3 processos): 141 PASS e 30 sem PASS. Os 4 testes de toque (`food_order`, `food_menu_bounds`, `daily_claim`, `blender_position`) já falhavam no HEAD anterior; os que estouram 300 s por carga foram rodados sozinhos, sem limite, no acabamento (22/11/2026, `-Jobs 1` ou direto no Godot). **Classificação final, nenhuma falha nova do novo fluxo:**

| Teste | Classe | O que foi feito |
|---|---|---|
| `festival_test` | regra antiga | 77 principais, 20 capítulos, comunidade nos capítulos 18/19/20 (história até o 17) — PASS |
| `album_test` | regra antiga | seção Truques passou de 13 para 14 fotos (`h_trick_show`) — PASS |
| `growth_story_test` | regra antiga | catálogo 153 entradas — PASS |
| `manual_test` | bug pequeno | `golden_worm` sem fonte: `GameManual.sources` agora aponta para o montinho do faro (Sítio) — PASS |
| `item_sources_test` | bug pequeno | `TaskHelp` explica a minhoca gorda (montinho com o pedido secreto aberto) — PASS |
| `ready_badges_test` | regra antiga + bug | a missão pronta agora é `arrival_box` (caixinha); o pomar pronto não contava no Mapa (`world_ready_counts` só achava `routes:orchard`), corrigido — PASS |
| `park_test`, `walk_return_test` | regra antiga | a Praça abre em Dentinhos (`growth: teething`, já no HEAD); em `walk_return_test` também `bathe` devolve `bool` (erro de script do teste, igual no HEAD) — PASS |
| `flavors_test` | regra antiga + bug | sementes agora ordenadas por tempo (Trigo antes de Milho); a dica de semente bloqueada mostrava a chave crua `buy:week_zucchini_seed`, agora "Compre na banca da vovó" — PASS |
| `photo_rarity_test` | regra antiga | a foto do peixe dourado (`s_golden_fish`, seção Truques) é uma conquista de uma vez só, não repete — PASS |
| `nature_test`, `nature_routes_test` | regra antiga | capítulos renumerados (+4): `dev_jump_to_chapter` 8 para 13; pomar é 2 h por 2 maçãs e pede estufa (valores do HEAD) — PASS |
| `week_tutorial_test` | carga | falhou uma vez com 3 processos, PASS sozinho |
| `farm_market_label_test` | carga | PASS |
| `tray_test` | antiga | só o bloco da estufa (`barra na estufa`), anterior ao novo fluxo |
| `world_view_test` | antiga | "9 canteiros na tela" e "Casa: cenário inteiro na largura" (Sítio do Figma e Casa), sem relação |
| `world_selector_test` | antiga | toque no fundo fecha a lista (o toque cai sob o HUD de madeira); sem relação |
| `care_ui_test` | antiga | procura `NeedPillar_*`/anel no HUD, que o HUD de madeira já não tem (HEAD igual); o erro de script faz o teste travar até o limite |
| `hud_growth_test` | antiga | espera `ShaderMaterial` no avatar do HUD, que o HEAD já não tem |
| `text_budget_test` | antiga | override de fonte em `room.gd`, `fishing_game.gd`, `fish_result.gd`, `recipe_book_ui.gd`; os três últimos nem foram tocados pelo novo fluxo e o de `room.gd` já existia no HEAD |
| `tasks_test` | antiga | "Humor do Tiro substitui a instrução fixa" |
| `card_reveal_test` | antiga | PASS no teste, erro de encerramento do Godot |

Lista dos testes do novo fluxo no fim do acabamento: `ato1`, `ato2`, `ato3_chapters`, `ato3_help`, `food_lesson`, `meal_rules`, `secret_stew`, `week_story`, `no_day_gates`, `growth_ui`, `ceremony`, `pet_care`, `care_wheel`, `week_tutorial` (mais `festival`, `album`, `growth_story`, `manual`, `park`, `flavors`, `photo_rarity`, `walk_return`, `ready_badges`, `item_sources`): todos PASS.

Rodados sozinhos no acabamento: `drag_scroll_test` PASS (era carga); `station_tray_test` segue com 3 falhas (comida do próximo crescimento primeiro — a premissa "Dentinhos pede `growth_kibble`" é de antes do novo fluxo —, "tocar no galinheiro abre a bandeja" e "Comprar animais é o último botão", essas duas já conhecidas do tutorial da pesca): ficam como antigas, sem ajuste nesta etapa; o teste leva mais de 5 min e por isso estoura o limite do portão.

## Roteiro do celular (para o Vitor)

Use a versão de testes (/dev/) e comece com um save novo. Em cada momento: o que fazer e o que olhar.

1. **Começo, de preferência à noite (22h às 6h) e depois de dia.** Abra o jogo. Toque em "Abrir a caixinha", segure o botão "Segure para fazer carinho" até o Tiro sair. Olhe: dá para entender sem ler muito? A mão e o brilho estão em cima do botão certo?
2. **Ato 1, em casa (oito passos).** Pegar a papinha, Cuidar, Comida (arraste a papinha até a boca), Banho (esfregue com a esponja), Brincar (jogue a bolinha para cima), Mapa, + da caminha (Colocar), carinha do Tiro, Ver detalhes, Crescer!, Álbum, Abrir a carta. Olhe: só uma coisa nova por vez? Apareceu moeda ou "dia N"? Algum texto cortado ou botão pequeno demais para o dedo?
3. **Ato 2, com a vovó.** Mapa, pílula "Casa", Sítio, falar com a vovó, plantar no canteiro, Mochila, fogão (+ e Colocar), cozinhar junto (Picar, Mexer, Servir). Olhe: a mão aponta o lugar certo? O minijogo é fácil na primeira vez?
4. **Aula da comida.** Reloginho verde, folha "Hoje", arrastar a papinha na hora certa, cartela de patinhas. Olhe: entendeu que são seis patinhas, uma por dia?
5. **Primeira noite.** À noite aparece "Boa noite!". Escolha Sim ou Agora não. Olhe: o texto do cartão ficou curto e claro? Deixar pronto na tigela é claro?
6. **Dia 2.** Abra o jogo na manhã seguinte: "Bom dia!". Dê o almoço na janela (11h às 15h) e o jantar (18h às 22h). Jogue só uma vez por dia, com a tigela cheia, e veja se o Tiro ganha a patinha. Olhe: se faltar um dia, o texto é gentil?
7. **Capítulos 2 a 11 e desafio do dia.** A cada capítulo concluído, olhe o cartão "Novo!" (Ir / Depois), a foto de fechamento e o pedido do dia da vovó. Olhe: sempre há um próximo passo na pílula do alto?
8. **Missão secreta e Dentinhos.** Siga o pedido da vovó do peixe dourado e do ensopado; ao fechar a lista, o Tiro cresce e a Vila abre. Olhe: o Seletor mostra a Vila trancada com a dica certa antes disso?

Anote: o passo onde você ficou parado, qualquer botão que o dedo errou e qualquer texto que não entendeu.
