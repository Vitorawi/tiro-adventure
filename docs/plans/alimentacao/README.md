# Comida do Tiro: dia e noite (plano aprovado, 26/11/2026)

Proposta visual: `proposta.html` (nesta pasta). **Aprovada pelo Vitor em 26/11/2026 com todas as recomendações:**
caminho **A (dia e noite)**, virada às **16h**, **sem castigos** (ração, fraquinho e marmita saem), **a Barriga vira o
relógio**, na tela **"de dia / de noite"** com sol e lua, e duas comidas perto da virada **valem** a patinha.
Pedido: "bem ajustadinho, bem claro, bem simples, bem fácil das pessoas entenderem".

Este arquivo é a **fonte única** da regra nova. Quando outro documento discordar (plano da primeira semana,
novo fluxo seções 5b/5c, `REGRAS.md`), vale o que está aqui.

---

## 1. A regra, como o jogador entende (4 frases)

1. Ele come uma vez **de dia** (sol, 6h às 16h) e uma vez **de noite** (lua, 16h às 6h).
2. As duas no mesmo dia valem **uma patinha**. Seis patinhas: Dentinhos.
3. Não vai estar lá? **Deixe na tigela**: ele come sozinho na hora.
4. **Petisco** é carinho, não é refeição.

Nada mais precisa ser explicado. Nenhuma tela mostra janela de horário, opção de horário, ração, fraquinho ou marmita.

## 2. A regra no motor

### 2.1 Metades do dia
- O dia do Tiro continua virando às 6h (`config.json → meals.day_starts_at: 6`).
- Duas metades com ids **`sun`** e **`moon`** (substituem `lunch` e `dinner` em todo lugar: config, registros do dia em
  `WeekState.days`, tigela, recados, eventos, diárias, DEV, testes). `sun` = 6h–16h, `moon` = 16h–6h
  (`meals.night_starts_at: 16`). Sempre existe uma metade aberta: `meal_period_now()` nunca devolve `""`.
- Cada metade tem, em `config.json → meals.periods.<id>`: `name` ("De dia"/"De noite"), `meal` ("comidinha do dia"/
  "comidinha da noite") e `when` ("de dia"/"de noite"). As horas saem de `day_starts_at` e `night_starts_at`.

### 2.2 Comer
- **Comer nunca trava.** `feed` sempre funciona (fora do passeio).
- Refeição (`is_meal_item`) dada **ao vivo** na metade atual **ainda sem ✓** = ✓ da metade (registro com `on_time: true`
  como hoje). Mantém o bônus de quem dá ao vivo (`on_time_bonus`, Felicidade) e o pedido de truque.
- ✓ `sun` + ✓ `moon` no mesmo dia do Tiro = **patinha** (`well_fed_day`, `Events.paw_earned`). Pode acontecer em
  minutos (15h50 e 16h10 valem, decisão do Vitor).
- **Dia da chegada**: uma refeição basta (`arrival_on_time_needed: 1`), como hoje. **Sai** a extensão do dia da chegada
  (`arrival_extended`, `arrival_min_hours`): o dia da chegada é só o dia do Tiro em que a caixinha abriu.
- Refeição quando a metade atual **já tem ✓**:
  - Se a tigela tem lugar para a próxima metade sem ✓ → a tela pergunta (folha "Ele já comeu", seção 3.3).
  - "Dar assim mesmo", ou tigela cheia/sem destino → ele come **de sobremesa**: conta como prato, desejo, crescimento
    e paladar, mas **não** ✓ nem patinha. Aviso: "Comeu de sobremesa! Conta como prato, não como patinha."
- Sai a regra "a primeira comida do dia não pergunta" (`first_meal_of_day`) e o erro "Ainda não é hora de comer".
- Antes da aula da comida (`food_clock_on()` falso) o relógio não existe: comer **não registra** ✓ (a aula dá a
  primeira). Isso evita que a papinha do Ato 1 deixe o Tiro "já alimentado" quando a aula chega.
- Ensopado Dourado: continua valendo patinha extra quando é a refeição ✓ ao vivo de uma metade (como hoje).

### 2.3 Tigela (Deixar pronto)
- Dois lugares (`meals.stored_slots: 2`). Destinos, em ordem: as **duas próximas metades** ainda sem ✓ e sem comida
  guardada. De dia: noite de hoje, depois dia de amanhã. De noite: dia de amanhã, depois noite de amanhã.
- Só dá para guardar quando a metade **atual já tem ✓** (se ele está com fome, a comida vai para ele).
- Ele come sozinho **no começo da metade** (6h ou 16h), mesmo com o jogo fechado; conta ✓ e patinha; sem bônus de
  Felicidade nem truque. "Pegar de volta" continua. Recado guardado para Bom dia/boas-vindas, com a hora.

### 2.4 Quando falta
- Metade que passa sem comer: **nada acontece**. Sem ração, sem fraquinho, sem marmita, sem aviso de erro.
- Dia que termina sem patinha: o registro do dia ganha `missed: true` (era `weak`) e a cartela mostra o espaço
  tracejado vazio. O Bom dia comenta com carinho.
- Saem: `ration`, `lunchbox`, `lunchbox_after_weak_days` (config), `WeekState.weak`, `weak_streak`, `lunchboxes`,
  `option`, `arrival_extended`; `GameState.tiro_weak`, `set_meal_option`, `first_meal_of_day`, `food_lesson_branch`;
  `Events.weak_day`, `lunchbox_given`, `meal_missed`; o item `lunchbox` se só a marmita o usa; o bloqueio da aula de
  truques por fraquinho (`LessonWeak_<id>`, `LessonFeed_<id>`); `WeakDot`, `WeakNote`; lições `weak` e `clock`.
- Saem também as opções Mais cedo · Normal · Mais tarde e a oferta/configuração do aviso de hora de comer
  (`week_meal_reminder_*`). No lugar, um aviso simples e sempre ligado (seção 3.8).

### 2.5 Barriga = relógio
- Depois que o relógio existe (`food_clock_on()`), a Barriga (`hunger`) não cai mais por hora: ela é calculada.
  - Metade atual **sem ✓**: Barriga em **20** (com fome, pede comida).
  - Metade atual **com ✓**: enche para **100** na hora da refeição e desce em linha reta até **55** no fim da metade.
    Fica sempre acima de `ask_below` (50): ele só pede comida quando uma comida conta.
  - Números em `config.json → needs.hunger.clock: {"hungry": 20, "full": 100, "end": 55}`.
- Com a Barriga no relógio, efeitos de comida/passeio sobre `hunger` são ignorados (o relógio manda). Os outros três
  atributos continuam iguais. Antes da aula vale o modelo antigo (queda por hora), para o Ato 1 funcionar igual.
- O cálculo é puro (instante da refeição e fim da metade), então vale com o jogo fechado sem tique nenhum.
- "Cuidado útil" de comida continua por ganho efetivo: comer com fome rende momento; sobremesa não.

## 3. Telas (madeira ilustrada)

### 3.1 Potinho do dia (HUD)
O reloginho `MealClock` vira o **potinho** `MealDay`: pílula de madeira com dois discos, sol e lua (ícones vetoriais
novos `sun.svg`/`moon.svg` em `ui/ctl`). Estados por disco: **com fome** (verde, pulsando; parado em Menos animação),
**✓** (selo verde), **na tigela** (selo de reloginho mel), **mais tarde** (apagado), **passou** (apagado, mais claro).
Toque abre a folha Hoje. Só aparece com `food_clock_on()`. Alvo de toque ≥ 44 px.

### 3.2 Folha Hoje
Madeira (`sheet_wood`), título "Hoje" com "?" (abre `MealReview`) e X. Só isto:
- Dois cartões lado a lado `Slot_sun` / `Slot_moon`: disco grande, nome ("De dia"/"De noite") e estado curto
  ("Papinha ✓", "Com fome!", "Na tigela · às 16h", "A partir das 16h", "Passou").
- A conta desenhada: sol + lua = patinha.
- A cartela `PawCard` (6 espaços).
- Comida na tigela, com "Pegar de volta". Botões de guardar só quando a metade atual já tem ✓ e cabe na tigela.
Sem opções de horário, sem aviso de fraquinho, sem configuração de aviso.

### 3.3 "Ele já comeu" (substitui "Deixar pronto?")
Folha de madeira, título "Ele já comeu". Ícone da comida + "Ele já comeu a comidinha do dia. Quer deixar esta na tigela
para a noite?". Botão verde **"Guardar para a noite"** (ou "Guardar para amanhã de dia"/"Guardar para amanhã à
noite"), botão amarelo **"Dar assim mesmo"**, nota pequena "Dar assim mesmo conta como prato, não como patinha."
Na primeira vez, mão da Laís no botão verde ("Guarde na tigela: ele come sozinho na hora.") se o motor de tutoriais
permitir com uma entrada de `week_tutorials.json`.

### 3.4 Guia de comida
Refeições primeiro, com selo pequeno sol/lua; quando a metade atual está sem ✓, as refeições ganham contorno verde e ✓.
Petiscos depois de uma divisória, com coração. A ordem por uso continua dentro de cada grupo.

### 3.5 Contou / Dia completo
- ✓ ao vivo com a outra metade pendente: aviso "Comidinha do dia ✓ · A da noite é a partir das 16h" (ou
  "Comidinha da noite ✓ · Amanhã cedo tem mais").
- Patinha ao vivo ou da tigela com o jogo aberto: cartão **"Dia completo!"** na fila modal: sol ✓ + lua ✓ = patinha,
  cartela com o carimbo novo saltando, "Patinhas N/6", e, se veio da tigela, "Comeu sozinho da tigela às 16h05".
  Botão verde "Oba!". Durante a aula da comida, a aula mostra a própria patinha (sem cartão).

### 3.6 Bom dia e Boa noite
- Bom dia: linha "Ontem" com sol ✓/faltou e lua ✓/faltou; com patinha, "+1 patinha"; sem patinha, "Ele sentiu sua
  falta. Sem patinha ontem, e tudo bem: hoje a gente capricha!". Recados da tigela: "Comeu sozinho da tigela às 16h05 ✓".
  Dica da tigela de manhã cedo continua ("Vai sair? Deixe a comidinha da noite na tigela.").
- Boa noite: mantém o resumo e o gancho de amanhã; "Comidinha do dia ✓ · Comidinha da noite ✓" no lugar de
  "Almoço na hora · Jantar na hora".
- Boa noite do dia 1: "Dia da chegada completo! +1 patinha", "Amanhã: uma comidinha de dia e uma de noite valem uma
  patinha." e, se a tigela não estiver cheia, "Vai sair amanhã cedo? Deixe a comidinha na tigela." com "Deixar pronto".
  **Sem** botões de horário e **sem** a pergunta do aviso.

### 3.7 Aula da comida em 3 toques (`LessonGuide`, passo `first_meal`)
1. O Tiro pede comida; mão na papinha. Laís: "Ele está com fome! Arraste a papinha até ele."
2. O disco da metade ganha ✓ e a primeira patinha voa ao avatar (garantida, `grant_lesson_paw`). Laís: "Ele come uma
   vez de dia e uma de noite. As duas valem uma patinha. A de hoje é presente!"
3. Painel Crescer na linha das patinhas (1/6). Laís: "Com seis patinhas ele ganha os Dentinhos. É uma por dia."
Uma fala só, para qualquer hora (saem as três versões por hora e o "boceja e vai dormir" da noite).

### 3.8 Aviso de fome
Com o jogo aberto, quando uma metade começa e ele ainda não comeu nela: aviso "Ele está com fome: hora da comidinha
da noite!" (ou "do dia"). Uma vez por metade, sempre ligado, só depois da aula.

### 3.9 Rever ("?" e Manual)
`MealReview`: barra do dia 6h → 16h → 6h com as duas metades (sol claro, lua escura) e cinco linhas com ícone:
"Uma comidinha de dia e uma de noite." · "As duas no mesmo dia valem uma patinha." · "Vai sair? Deixe na tigela: ele
come sozinho na hora." · "Petisco é carinho, não é refeição." · "Seis patinhas e ele ganha os Dentinhos."

### 3.10 Textos
- Painel Crescer: o passo `days` passa a se chamar **"Patinhas"**; explicação "Cada dia em que ele come uma comidinha de
  dia e uma de noite vale uma patinha. Junte {need}."
- `PawCard.next_text`: "Hora da comidinha do dia!" · "A da noite é a partir das 16h" · "Amanhã cedo tem mais".
- Tiro tocado já alimentado: "Barriga cheia! De noite tem mais." / "Barriga cheia! Amanhã cedo tem mais."
- Petisco (primeira vez): "Petisco é carinho: não conta como refeição."
- Diárias `lunch`/`dinner` viram `sun` "Comidinha do dia" e `moon` "Comidinha da noite".
- História (`quests.json`): "Filhotinho come comida de verdade: uma vez de dia e uma de noite. Quem planta tudo isso é
  a vovó Bloblo." Item Ensopado Dourado: "Dado como comidinha do dia ou da noite, vale uma patinha extra."
- Qualquer texto do jogador que ainda diga "almoço/jantar na hora", "reloginho", "fraquinho", "marmita" ou "ração da
  vovó" para essa regra muda (nomes de pratos, de missões de almoço de despedida e de itens de ração ficam).

## 4. Etapas

| Etapa | O quê | Quem |
|---|---|---|
| A1 | Regras: config, `WeekState`, `GameState`, Barriga no relógio, saídas da seção 2.4, robô do simulador por sessões, testes de regra. `SAVE_VERSION` 41. | Agente (Sonnet) |
| A2 | Telas e textos: seções 3.1 a 3.10, capturas nas três resoluções, testes de tela. | Agente (Sonnet) |
| A3 | Revisão, nível `etapa` das áreas mexidas, simulador por sessões (`regular`), documentos. | Claude |

Regras de trabalho: sem commit, push ou publicação. Saves zerados (sem migração). Testes por nível
(`tools/test.ps1 -Level etapa`). Visual em madeira ilustrada com as peças existentes.

## Andamento
- 26/11/2026: plano aprovado; A1 em andamento.
- 26/11/2026: A1 concluída (regras do motor): metades `sun`/`moon` (`meals.night_starts_at` 16, sem `options`/`ration`/`lunchbox`/`arrival_min_hours`),
  ✓ ao vivo + patinha, sobremesa, tigela que come no começo da metade, `missed` no lugar de `weak`, Barriga no relógio
  (`needs.hunger.clock`, `DogState.belly_*`, `GameState._sync_belly`), aviso de fome por metade, `SAVE_VERSION` 41. Telas só no mínimo para compilar
  (o visual novo é da A2). Testes: `meal_rules_test` reescrito, `day_clock_test` reescrito e os demais ajustados.
  Extras da A1: `meals.night_card_at` (20h: o Boa noite só aparece à noite) e `meals.bowl_tip_until` (10h: a dica da tigela do Bom dia é de manhã cedo);
  `GameState.dev_belly_clock(false)` desliga a Barriga no relógio nos testes de mecânica geral (queda por hora).
- 26/11/2026: A2 concluída (telas e textos 3.1 a 3.10): potinho `MealDay`, folha Hoje, "Ele já comeu", guia de comida (refeições primeiro, selo sol/lua no canto de cima à direita, contorno verde com ✓ quando a metade conta, divisória com coração antes dos petiscos), aviso do ✓ e cartão "Dia completo!" só ao vivo (`MealUi.live_paw`: a hora do ✓ é de agora; patinha do jogo fechado fica para o Bom dia), Bom dia/Boa noite, aula em 3 toques, `MealReview`. Tutoriais: lições novas `meal_day` e `bowl` (38 no total); "tigela" só como o lugar da comida guardada (arrastar comida é "até o Tiro"; o ponto de soltar `TutorialMealBowl` virou marcador invisível). Capturas em `build/screenshots/meal_dia_noite/`.
- 26/11/2026: A3 (revisão, Claude): cartela sempre com os 6 espaços da fase (dia sem patinha não ocupa espaço); Bom dia com miolo que rola e sem o "Pular" repetido; lições `meal_day` e `bowl` presas ao passo `first_meal` (`after_quest`); robô por sessões só usa a tigela para a metade que perderia e só come depois da caixinha. Ritmo (`-Until week`, sementes 1–3): muito Dentinhos dia 5, regular 6–7, perde_dia 7–8 (antes: 5 / 6–8 / 7). Testes: 110 do nível etapa; falhas restantes já existiam no HEAD (navigation, tasks, roleta, gestures, card_reveal, album, hud_growth; care_ui e station_tray por tempo); cart, play_week e fishing_tutorial passam sozinhos (falharam só sob carga). Sem commit.
- 26/11/2026: telas do dia mais diretas (pedido do Vitor: "comeu, acabou"): Bom dia só com "Dia N", linha Ontem em discos, "+1 patinha" e "Vamos!" (saíram manchete, "Hoje: ...", recado da tigela e dica da tigela); Boa noite só com a linha Hoje em discos, "+1 patinha" e "Boa noite!" (dia 1 leva a conta desenhada "Amanhã: sol + lua = patinha" e o atalho "Guardar na tigela"); "Dia completo!" e folha Hoje sem a linha "Amanhã cedo tem mais" (`PawCard.build(..., with_next)`); estados curtos do cartão ("16h", "Na tigela"); "Ele já comeu" = ícone + dois botões; avisos de uma frase ("Comidinha do dia ✓", "Hora da comidinha!", "Sobremesa! Não vale patinha.", "Petisco não é refeição.", "Barriga cheia!"); aula, lições, Rever (4 linhas) e passo "Patinhas" reescritos em "Dia + noite = 1 patinha".
- 26/11/2026: revisão do "libera no dia": dados e falas já não prometiam nada por dia (F00); o que ainda fala de hoje/amanhã é recarga diária (lupa, show, peixe dourado, banca) ou comida. Ajustados: recibo e aviso "Desafio do dia" → "Desafio da vovó" e o texto DEV dos tipos de prato (abrem pela História).
