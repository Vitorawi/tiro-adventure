# F02 — Lição do crescimento e aula da comida

Plano: `docs/plans/novo_fluxo/README.md` seções 5, 5b e 5c (leia inteiras) e decisões F2, F8, F9, F10.
Mapa: `CLAUDE.md`. Base: F00 (`content_day()`) e F01 (Ato 1 em casa, passos `welcome` … `lais_photo`,
`GameState.ato1_done()`, requisito `story_gate`, `SAVE_VERSION` 35).

A etapa tem **duas partes, feitas por sessões separadas, em ordem**: A (regras do relógio) e B (aulas e telas).
Cada parte termina com testes `-Level etapa -Exact`; a Parte B termina com o **portão** (`-Level portao`).

Onde a aula acontece: no plano final é o passo 14 (Ato 2, F03). Hoje o primeiro prato de verdade depois do Ato 1 é o
passo `first_kitchen` (papinha no Cozinhar junto + dar ao Tiro). Prenda a aula a um id configurável
(`week_story.json → food_lesson.quest`, hoje `first_kitchen`), para a F03 só trocar o id.

---

## Parte A — Regras do relógio (sem tela nova)

1. **O dia do Tiro vira às 6h** (F9). `week_day_number()` passa a usar o horário local deslocado de 6 h (00h–05h59
   contam como a noite do dia anterior). Número em `config.json → meals.day_starts_at: 6`. Tudo que é "por dia"
   (patinha, dia fraco, marmita, Bom dia/Boa noite, desafio, limites diários) passa a seguir essa virada.
   Confira janelas que cruzam a meia-noite (não há hoje: almoço 11–15, jantar 18–22).
2. **Dia da chegada livre até as 6h seguintes.** O dia 1 é o dia (já deslocado) em que a caixinha foi aberta.
   Se faltarem menos de 3 h para a virada quando a caixinha abre (`meals.arrival_min_hours: 3`), o dia da chegada
   se estende até a virada seguinte. Nele, uma refeição a qualquer hora vale a patinha (já existe
   `arrival_on_time_needed: 1`). Exponha `GameState.arrival_day_ends_at()` e `first_deal_at()` (início do primeiro
   almoço do combinado) para as telas da Parte B. Cubra a tabela de exemplos da seção 5c no teste.
3. **Comer nunca trava.** `feed` sempre funciona; fora da janela só não conta.
   - Antes da aula da comida (`GameState.food_lesson_done()`, novo, lido do estado salvo), **o relógio não existe
     para o jogador**: nada de reloginho, folha Hoje, pergunta "Dar agora / Deixar pronto", ração sozinho, dia fraco,
     marmita nem Bom dia/Boa noite. Substitua os usos de `ato1_done()` que escondem o relógio por
     `food_lesson_done()` (o `ato1_done()` continua para moedas/abas/Casa). Patinha do dia da chegada continua
     contando por baixo (a aula a "revela").
   - A pergunta "Dar agora / Deixar pronto" nunca aparece na **primeira refeição de um dia**.
   - Enquanto um passo da história pedir comida (`feed`/`together`/aula ativa), o Tiro **não dorme sozinho** à noite.
4. **Tigela de dois lugares** (F10). `WeekState.stored` passa de uma refeição para até duas, uma por período
   (almoço e jantar da próxima volta do relógio: quem guarda às 20h deixa o almoço de amanhã; às 8h, almoço e
   jantar de hoje). `store_meal`, `cancel_stored_meal`, `stored_meal`, `meal_next_target` e o fechamento em
   `update_week()` passam a lidar com a lista. Conta para a patinha igual ao ao vivo. **Ao vivo dá mais**: mantenha
   `on_time_bonus` (Felicidade) e o pedido de truque só para refeição dada ao vivo.
5. Recado ao voltar: quando a tigela serviu sozinha, guarde `{período, hora}` para a Parte B mostrar
   ("Ele comeu o almoço às 11h12 ✓").
6. `SAVE_VERSION` +1, saves zerados. Teste novo `game/tests/meal_rules_test.gd` (suite + área `week`):
   virada às 6h; os quatro exemplos de início da seção 5c; nada do relógio antes da aula; pergunta nunca na primeira
   refeição do dia; tigela com dois lugares servindo os dois períodos e contando a patinha; Tiro não dorme sozinho
   com passo de comida ativo. Ajuste `day_clock_test`, `meal_ui_test`, `week_routine_test`, `no_day_gates_test`,
   `ato1_test` e o que mais quebrar pela regra nova (não apague).

---

## Parte B — Aulas e telas (feita depois da A)

1. **Lição do painel de crescimento** (seção 5), presa ao passo `lais_growth` do Ato 1: três falas, uma por toque,
   apontando a grade de passos, os ✓ acesos e o anel do avatar no HUD. Use `TutorialGuide`/`WeekTutorial`
   (mão + balão, botão Pular). Some sozinha se o painel fechar; a pílula do passo continua levando lá.
2. **Aula da comida** (5b), presa a `week_story.json → food_lesson.quest`: cinco toques (reloginho pulsa no
   avatar → folha Hoje abre com os dois espaços → arrastar a comida até o Tiro, o espaço ganha ✓ → a patinha voa ao
   avatar → painel Crescer abre na linha das patinhas, 1/6). **A primeira patinha é garantida** a qualquer hora.
   Falas 2 e 3 pela hora (tabela da 5b: dentro da janela / fora de dia / noite 22h–6h); na noite o Tiro boceja,
   vai para a caminha e a sessão termina no Boa noite. Ao terminar, `food_lesson_done()` fica verdadeiro.
   Textos em `week_story.json` (ou `week_tutorials.json`), não no código.
3. **Cartela de patinhas** (5c, "parte gostosa"): 6 espaços tipo cartão de carimbo no painel Crescer (linha das
   patinhas do Dentinhos) e na folha Hoje. Carimbo com o ícone do prato do dia, "Dia completo!" curto; o primeiro é
   "Dia da chegada"; dia fraco = carimbo tracejado vazio. Madeira ilustrada (padrão do projeto: `StepCardUi`,
   `CodexUi.tile`, etc.). Linha das patinhas com "Próximo almoço em 2 h".
4. **Boa noite do dia 1**: combinado de amanhã ("almoço e jantar na hora"), `first_deal_at()` ("Seu primeiro
   combinado começa amanhã, no almoço das 11h"), os três botões Mais cedo · Normal · Mais tarde (já existem em
   `MealUi`), a oferta do aviso de hora de comer (F8: `week_meal_reminder_offered` passa a ser verdade aqui;
   desligado até aceitar) e, se a tigela não estiver cheia, "Quer deixar a comida de amanhã pronta?" (uma vez).
5. **Bom dia do dia 2**: "Hoje é o primeiro dia de verdade: almoço e jantar na hora."; antes das 11h, dica da
   tampinha ("Vai sair? Deixe o almoço pronto na tigela..."). Recado da tigela ("comeu o almoço às 11h12 ✓").
   Dia fraco no Bom dia sem bronca, com a fala da vovó (5c).
6. **Lanche não é refeição**: balão curto na primeira vez que der um petisco.
7. **Ele mostra que está com fome**: com a janela aberta e o período sem ✓, o Tiro vai até a tigela/abana e a
   tigela brilha; com o período feito, balão "Já almocei!"/"Já jantei!" ao tocar nele.
8. **Rever**: "?" na folha Hoje e na linha das patinhas abre a aula em uma tela (dia de 24 h com as duas janelas,
   ✓ ✓ → patinha → crescer); página "Comida e crescimento" no Manual (`GameManual.open("tutorials")`).
9. Lições antigas que repetem isso (`clock`, `feed`, `paw`, `weak` em `week_tutorials.json`): remova ou prenda à
   aula para não falar duas vezes.
10. Teste novo `game/tests/food_lesson_test.gd` (suite + áreas `week`, `growth`): aula nas três faixas de hora,
    patinha garantida, cartela, Boa noite com combinado/opções/aviso, Bom dia do dia 2, nada antes da aula.
    Capturas `tests/food_lesson_shots.gd` nas **três resoluções** (360×780, 390×844, 412×915) → abrir e conferir.
11. **Portão** no fim: `powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level portao -KeepGoing`.
    Compare com as falhas antigas (`tasks_test`, `album_test`, `care_ui_test`, `tray_test`, `cart_test`) e liste.

## Pronto quando (etapa inteira)

- A regra da comida é ensinada no momento certo, a primeira patinha nunca falha, quem começa à meia-noite entende,
  quem joga uma vez por dia consegue a patinha com a tigela de dois lugares.
- Testes novos PASS, portão sem falha nova, capturas conferidas nas três resoluções.
- `docs/ROADMAP.md`, `CLAUDE.md` = `AGENTS.md` (uma linha cada) e "Andamento" do plano. Sem commit, push ou publicação.
