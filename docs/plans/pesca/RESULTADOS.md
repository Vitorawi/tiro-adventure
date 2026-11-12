# Pesca — resultados da etapa 10 (12/11/2026, local)

> Medida SIMULADA (`GameState` real, relógio injetado, robô pescador); não é o tempo de um jogador humano.
> Uma execução `-Quick` (reference, semente 1, campanha) por lado; mais sementes só se o Vitor pedir.
> Evidência: `build/economy/pesca_10/antes/summary_antes.json` (código de antes da pesca, commit `da047fbe`, num worktree
> separado) e `build/economy/pesca_10/quick2/reference_s1/summary.json` (código atual).

## 1. Ritmo antes × depois

| Fase do Tiro | Antes (dia · min ativos) | Depois (dia · min ativos) | Diferença | Meta do plano |
|---|---|---|---|---|
| Filhotinho | 0,00 d · 1,6 | 0,00 d · 1,6 | 0 | — |
| Dentinhos | 0,34 d · 24,7 | **0,09 d · 15,1** | −0,25 d · −9,6 min | +1–2 h |
| Aventureiro | 2,33 d · 90,7 | **2,08 d · 75,1** | −0,25 d · −15,6 min | +3–5 h |
| Mocinho | 9,08 d · 284,9 | **7,84 d · 246,7** | −1,24 d · −38,2 min | +3–5 h |
| Adulto | 19,09 d · 584,2 | 19,09 d · 584,6 | 0 · +0,4 min | — |
| Campanha inteira | 20,08 d · 622,0 min · 111 missões | 20,34 d · 632,1 min · 125 missões | **+0,26 d (+1,3%) · +10,1 min (+1,6%)** | ≤ +10% |

(Dia/minutos = quando o Tiro CHEGA à fase. A linha de base aprovada em 23/10 era 0,34 / 2,08 / 8,84 / 19,84 d; o "antes" acima é a
mesma simulação refeita no código de hoje sem a pesca, então a comparação é limpa.)

**Leitura honesta:** a pesca ficou **dentro do teto de +10%** (+1,3%), mas **muito abaixo das metas de +1–2 h e +3–5 h**, e as
fases chegam um pouco MAIS CEDO que antes, não mais tarde. Não investiguei a causa; hipóteses: as missões novas (pesca, papinha,
ensopado) pagam moedas/XP e abrem o capítulo mais rápido, e o robô pesca quase sem erro. O que a pesca acrescenta no robô é só o
tempo de jogar (abaixo), porque nada nela obriga a ESPERAR relógio (as esperas da campanha são cozinhar, crescer e cooldowns).

## 2. A pesca em números (robô, reference, semente 1)

- 34 ações de pescar · 33 lançadas, 29 capturas, 4 escapadas; **9,7 min de pesca no total** (Filhotinho 1,4 · Dentinhos 5,8 ·
  Aventureiro 2,5 · Mocinho 0).
- Iscas compradas: 5 minhocas + 4 massas = **30 moedas** (3 compras de pacote); a isca artificial e a vara 3 vêm de receita.
- Peixes: lambari 5, cará 3, tilápia 5, carpa 3, pacu 2, tambaqui 2, tucunaré 6, pintado 3 (a traíra não foi necessária).
- Gigantes 2 de 29 (6,9%), perfeitas 2.
- 0 violações de guarda (a primeira rodada acusou 1: a vara entra em `fishing.rods`, não na mochila; o simulador foi corrigido).

## 3. O que NÃO está medido (limites)

- Um robô com nota 0,65 e sem erro de leitura pesca em segundos o que uma pessoa leva minutos (taxa humana de sucesso ainda
  desconhecida: o plano supôs 50–70% para o pintado). O ritmo humano real é maior que o simulado.
- O robô **não usa a oferta do dia** (não ajuda a ninguém a acelerar): a medida é conservadora.
- Só uma semente e o perfil reference. `light` e `active` têm `fishing_skill` 0,5 e 0,8 mas não rodaram.
- Quem pesca de verdade perde tempo com a espera (4–10 s por mordida) e com as bolhas; isso já está contado (espera média 7 s).

## 4. Ajustes aplicados / opções para o Vitor

Nada foi ajustado (regra da etapa: só ajustar quando passa do teto; aqui ficou abaixo da meta). Opções, da mais barata:

1. **Aceitar como está** (a pesca vale como conteúdo e flavor; o crescimento continua determinado por cuidado e cozinha).
2. Pratos de peixe de 2 → **3** porções (papinha, ensopado, peixe com ervas): mais ~2–3 min de pesca por fase no robô.
3. Preço/pacote das iscas (minhocas 10 → 15 moedas; massa 20 → 30): custo em moedas, quase nenhum em tempo.
4. Tornar a pesca um **gargalo de tempo** de verdade (ex.: uma espécie que só morde à noite ou com bolha), o que é desenho novo.

A física aprovada na etapa 00 não foi tocada.

## 5. Portão, campanha e capturas

- **Portão** (`tools/test.ps1 -Level portao -KeepGoing`, 1898 s): 120 PASS, 21 com FAIL/timeout. Dois eram da pesca e foram
  corrigidos e passam (`animals_chain_test`: faltavam as missões da pesca antes do galinheiro; `care_story_test`: rotinas de pesca).
  Dos 19 restantes, **nenhum aparece ligado à pesca**, mas só alguns são certamente antigos: `tasks_test` ("Humor do Tiro"),
  `photo_rarity_test`, `card_reveal_test`, `world_view_test`, `world_pin_test`, `world_selector_test`, `hud_growth_test`,
  `drag_scroll_test`, `food_order_touch_test` (falha também no commit sem a pesca), `blender_position_touch_test`, `tray_test`,
  `station_tray_test`, `animals_test`, `world_life_test`, `balloon_test` (timeouts/erros do Sítio). Há uma OUTRA sessão trocando a
  arte do Sítio agora (`farm.json` muito alterado, `ilha_*` removidos; erro "get_size em null" no `RoomView._ready`), que explica
  `silo_test` e `bench_test`; `ui_style_test` ("truque em recarga...") e esses dois passam no commit sem a pesca e **não foram
  atribuídos com certeza**. Lista completa: `build/test_logs/r20261112_031143_366a7170/results.csv`.
- **Campanha** (`-Level campanha`): `progression_test` falhou na primeira vez porque o robô DELE não pescava; ganhou `_fishing_step`
  e agora **PASS** (778 ciclos, 64 aquisições, 125 missões). `economy_quick` PASS. `economy_audit_selftest` corrigido
  (auditor aceita `shop:` e `output_rod`) e PASS. `economy_sim_test` só com as duas falhas antigas de passeio ("sempre guarda").
  `test_circuit_selftest` falha por `wish_moments_test` × `wish_guide_test` (antigo). Não reexecutei o portão inteiro depois dos ajustes.
- **Capturas** (`tools/pesca_tour.ps1`, três resoluções, PNGs em `build/screenshots/pesca_tour/`): `shop_shots` (banca com a oferta do
  dia), `fishing_book_shots`, `fishing_rod2_shots` e `fishing_rod3_shots` OK. O primeiro passe do `shop_shots` achou um erro real
  (motivo de bloqueio da oferta "Depois de: …" cortado), corrigido e OK nas duas resoluções repetidas. `fishing_shots` e `fishing_tutorial_shots` falhavam e foram **corrigidos** (12/11, depois da aprovação): no `fishing_shots` o tutorial da vovó começava sozinho ao ganhar a vara e cobria a tela (o roteiro agora o remove e usa janela de fisgada longa); no tutorial, o balão media altura enorme no primeiro quadro (`AnglerTutorial._layout_balloon` agora mede de novo no quadro seguinte). Os seis roteiros passam nas três resoluções; `fishing_tutorial_test`, `fishing_lake_test`, `shop_test`, `fishing_test`, `content_test`, `texts_test` PASS.

## Aprovação do Vitor (12/11/2026)

**Ritmo aceito como está** ("vamos aceitar do jeito que tá"); o equilíbrio (pratos, iscas, gargalo de tempo) fica para ele rever com calma depois. Desenvolvimento da pesca **fechado**. Pendente só o que depende do Vitor: roteiro do celular (§6) e o roteiro de toque Web.

## 6. Roteiro para testar no celular (Vitor)

Abra a versão de testes (`/dev/`) e use "Dar vara" no DEV só se quiser pular a história; o melhor teste é jogar do capítulo 2.

1. **Tutorial da vovó:** no Sítio, depois da colheita, fale com a vovó, pegue a vara e toque na lagoa. Siga os 12 passos
   segurando com o POLEGAR no botão grande "Segurar para subir". Ele deve ficar confortável com a mão direita e com a esquerda.
2. **Tela pequena:** pesque 5 vezes seguidas num celular menor (ou com o texto grande ligado). Conferir que a barra, o peixe e o
   botão nunca ficam sob o HUD nem sob as abas.
3. **Sair do app no meio do minigame e voltar:** a luta deve voltar pausada ou a isca devolvida, sem perder peixe nem minhoca
   em dobro; teste também travar a tela e trocar de app.
4. **Bolha com o app fechado:** pesque até aparecer a bolha, feche o app por ~10 min e abra: a bolha some sem penalidade;
   com o app aberto ela dura 10 min.
5. **Banca:** compre minhocas e massa, tente comprar a oferta do dia duas vezes (a 2ª deve dizer "Volta amanhã") e confira que
   a oferta é a mesma ao reabrir no mesmo dia.
6. **Geladeira cheia:** encha a geladeira e pesque: o peixe deve esperar na linha com "Liberar espaço".
7. **Vibração e Menos animação:** ligue "Vibrar" e confira a fisgada, o baú e o Gigante; com "Menos animação" a boia e o respingo
   ficam estáticos mas o jogo continua jogável.
8. **Desempenho:** o minigame deve ficar fluido (meta ≥ 50 fps no Chrome emulado; no celular real, sem engasgos nas rajadas do
   peixe). Anote o aparelho.

O roteiro de toque automático (`game/tests/touch/fishing.json` no Chrome emulado) **não foi rodado** nesta sessão (exige export Web
+ servidor local e coordenadas conferidas na primeira execução).
