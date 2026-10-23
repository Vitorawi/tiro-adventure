# 02 — Desenho: regras e números

Arquivo autoritativo das regras do plano. Os números são **alvos iniciais**; a etapa 07 calibra.
Caminhos relativos a `game/`.

## A. Necessidades e pilares

As quatro necessidades continuam (Barriga, Felicidade, Energia, Higiene), com decaimento e piso de ausência
atuais (`config.json → needs`, `offline`). Novo campo por necessidade: `ask_below` (padrão **50**). Abaixo dele a
necessidade está **pedindo**.

| Necessidade | Cuidado que atende | Pilar que o cuidado útil faz crescer |
|---|---|---|
| Felicidade | carinho, brincar | carinho → **Coragem**; brincar → **Esperteza** |
| Higiene | banho (xampu = banho que vale 2) | **Pelagem** |
| Barriga | comida | **Corpo** pelas refeições da fase (regra atual de `feed.body_level`, sem mudança) |
| Energia | dormir | nenhum (só libera o passeio, como hoje) |

**Cuidado útil** = a necessidade estava pedindo **antes** da ação. Esta é a única regra de utilidade: saem
`care_useful_gain`, `care_useful_gain_pet`, `care_need_threshold`, `care_affection_cooldown`,
`care_reward_cooldown` e as recargas de `growth.json → sources`. O contador `care_useful` continua (álbum e
jeito usam), com a definição nova. Cuidado não útil dá a animação e o ganho normal da necessidade, sem momento.

Escovar não tem necessidade: vale **um momento de Pelagem por dia** (dia local; usa `brush_days`, que a seda
já conta).

Valores iniciais de um save novo: Barriga 40, Felicidade 40, Higiene 70, Energia 80 — a primeira sessão já
tem carinho e comida úteis.

## B. Momentos

Um **momento** é +1 num pilar. Os pilares Coragem, Esperteza e Pelagem passam a contar só momentos (Corpo
continua sendo as refeições da fase). Sem níveis, sem teto de fase, sem reserva, sem Radiante.

### Fontes

| Pilar | Fonte | Momentos | Teto do período? |
|---|---|---|---|
| Coragem | carinho útil | 1 | sim |
| Coragem | volta de passeio (`return_due_walk`) | 1 | sim |
| Coragem | primeira conversa com um personagem; primeira visita a um mundo; amigo novo (1º coração); obra concluída | 1 | não (primeira vez) |
| Esperteza | brincar útil | 1 | sim |
| Esperteza | esconde-esconde (etapa 04) | 1 | sim |
| Esperteza | truque aprendido; achado novo do faro (item nunca achado) | 1 | não (primeira vez) |
| Esperteza | mostrar truque (fora da recarga) | 1 | sim |
| Pelagem | banho útil / banho de xampu útil | 1 / 2 | sim |
| Pelagem | escovar (uma vez por dia) | 1 | não |
| qualquer | desejo atendido (seção D) | 1 do pilar do desejo | não |

**Teto do período:** no máximo **2 momentos do mesmo pilar por período** pelas fontes marcadas "sim".
Períodos no horário local: madrugada 0–6, manhã 6–12, tarde 12–18, noite 18–24
(`growth.json → moments.periods`). O teto evita maratonas sem obrigar a esperar entre gestos.

### Requisitos das fases

Momentos contam **desde o início da fase** (`GrowthState.phase_moments`); passar do pedido não guarda sobra.
O total da vida (`GrowthState.moments`) aparece no caderninho.

| Fase | Coragem | Esperteza | Pelagem | Mantém | Sai |
|---|---|---|---|---|---|
| Filhotinho | 2 | — | — | chegou, caminha, 3 refeições | — |
| Dentinhos | 3 | — | — | 3 cenouras geladas, `chew_ring` | — |
| Aventureiro | 4 | 3 | — | 3 refeições da fase, `stick_chew`, 3 passeios | — |
| Mocinho | 4 | 4 | 4 | refeições, `soft_brush` | "2 banhos com xampu" (o xampu vale 2 momentos) |
| Azul e Dourado | 5 | 5 | 5 | medalha, lacinho, 3 favoritas | — |

Tipo novo de requisito em `growth.json → phases[].requirements`: `{"id": "brave", "type": "moments",
"pillar": "brave", "qty": 3, "label": "Carinho e novidades"}`. Rótulos: Coragem "Carinho e novidades",
Esperteza "Brincadeiras e descobertas", Pelagem "Banho e escova".

## C. Tiro animado

**Condição:** acordado e **nenhuma necessidade pedindo**. É um estado calculado (`GameState.tiro_animated()`), não
salvo. Efeitos em `config.json → mood.animated`:

| Onde | Efeito | Detalhe |
|---|---|---|
| Horta | 1 em 5 colheitas de canteiro dá +1 do produto | aviso "O Tiro ajudou!" com `CollectFx`; respeita o depósito (se não couber, não dá) |
| Passeio | +1 sorteio de achado na volta | decidido na saída e congelado no snapshot do passeio |
| Faro | +1 montinho por período | só em mundo aberto, pelo sorteio existente |

Sem castigo: não animado só não tem os efeitos. O avatar do HUD mostra o selo "Animado" ou o ícone da
necessidade que está pedindo.

## D. Desejos

- **Um desejo ativo de cada vez.** Um novo chega no início de cada período **manhã, tarde e noite**
  (madrugada não traz desejo; o da noite continua). Desejo não atendido é trocado pelo do período seguinte, sem
  castigo. O primeiro chega logo depois da caminha (`lais_bed`) e é sempre carinho.
- **Escolha** (`GameState._pick_wish`, determinística pela semente do save + período):
  1. se uma necessidade está pedindo, o desejo dela (Felicidade → carinho ou brincar, o que tiver mais momentos
     faltando na fase; Higiene → banho; Barriga → a comida da refeição da fase, se o jogador já sabe fazê-la,
     senão qualquer comida);
  2. senão, o pilar com mais momentos faltando na fase → um desejo desse pilar da lista da fase;
  3. senão, qualquer desejo da fase (inclusive a comida da refeição).
  Não repete os dois últimos ids. Só entram desejos cujos `requirements` valem.
- **Prêmio:** 1 momento do pilar do desejo, fora do teto, mais a reação de alegria. Sem moedas, sem afeto.
  Desejo de comida também conta como refeição, se for a comida da fase.
- **Catálogo** (`wishes.json`, reescrito): cada desejo tem `pillar`, `phases`, `goal` (ação, comida, lugar,
  passeio, truque) e `go`.

| Fase | Desejos (pilar) |
|---|---|
| Filhotinho | carinho (Coragem), comida (Corpo) |
| Dentinhos | carinho, conhecer a vovó/um personagem (Coragem); brincar (Esperteza); cenoura gelada (Corpo) |
| Aventureiro | passear, ir a um mundo (Coragem); cavar um montinho, esconde-esconde, brincar (Esperteza); comida da fase |
| Mocinho | banho, banho de xampu, escovar (Pelagem); mostrar um truque (Esperteza); passear (Coragem); mingau |
| Azul e Dourado | comida favorita; passeio longo (Coragem); truque, esconde-esconde (Esperteza); escovar (Pelagem) |

## E. Vínculo sai

Saem afeto (`DogState.affection`), `progression.json → bond_levels`, `BondChip`, painel de vínculo, prêmios de
vínculo, requisito `bond` e o selo de vínculo nas fotos. Trocas de requisito:

| Onde | Antes | Depois |
|---|---|---|
| truques (`progression.json → tricks`) | `bond` 2/3/4/5 | o `growth` atual de cada truque basta; onde não houver, `growth` da fase em que o truque aparece |
| passeios longos (`walks.json`) | `bond` 3/4/5 | `growth`: Aventureiro / Mocinho / Azul e Dourado (mantendo `stats.walk`) |
| espaços de desejo | `bond` 2/4 | não existem mais (um desejo) |

## F. Gestos (etapa 04)

- **Carinho de segurar:** segurar o dedo sobre o Tiro por **1,2 s** (anel pequeno enche) = um carinho. Esfregar
  continua valendo, mas um gesto contínuo = **um** carinho, não vários.
- **Lugar favorito:** três zonas (cabeça, queixo, barriga), favorita sorteada pela semente do save. Carinho no
  favorito: reação especial (rola de barriga para cima, clipe existente `roll_over`), Felicidade +25 em vez de
  +15. A primeira vez revela o favorito (diário + aviso).
- **Esconde-esconde** (a partir do Aventureiro, opção dentro de Brincar): custa **1 petisco** (campo novo
  `treat: true` em `items.json`: `carrot_snack`, `mint_snack`, `apple_biscuit`, `corn_crunch`, `cheese_bites`); três copinhos, o petisco vai para um, os copinhos trocam de lugar (3 trocas
  no Aventureiro, 4 no Mocinho, 5 no adulto) e o jogador toca onde acha que está. Acertando ou errando o Tiro
  come o petisco e ganha o momento de Esperteza (respeita o teto); acertando, faz festa. Arte: um copinho
  32 px (PixelLab) e o petisco com o ícone do item.

## G. Missões e rotinas

- Diárias/semanais **só da fazenda**: saem `care`, `care_week` e `tiro_walk` de `routines.json`. As roupas que
  `care_week` dava (`clean_bow`, `heart_collar`, `walker_bandana`) vão para `big_harvest`/`orders_week`
  ou para presentes de fase.
- `lais_feed`, `lais_bath`, `lais_play` ficam (tutorial). Passo novo da Laís depois de `lais_bed`:
  "Atender o primeiro desejo" (objetivo `wish`, alvo 1) com fala explicando que, quando ele pede, é hora de
  cuidar, e que cada cuidado assim vira um momento para crescer.
- Feature `wishes` ("Novo!") deixa de abrir aba: apresenta o balão do desejo na tela do Tiro.

## H. Estado, eventos e interface

- `SAVE_VERSION` **14**; o ramo de reset cobre `< 14`. Saves zerados, preferências preservadas.
- `GrowthState`: saem `points`, `reserve`, `cooldowns` (de pilar); entram `moments` {pilar: total},
  `phase_moments` {pilar: n}, `period_moments` {"<data>:<período>:<pilar>": n}.
- `WishState`: sai `slots`; entram `current` {id, period, progress, since} e `last_ids`.
- `Events.moment_gained(pillar, source)` substitui `pillar_gained`; `Events.wish_changed`.
- Tela do Tiro: um balão de desejo; anel de necessidade pedindo ganha o ícone do pilar que o cuidado dá. Aviso
  curto "Momento de Coragem!" com o ícone do pilar voando para o avatar. Painel de crescimento e caderninho
  mostram "Coragem ●●●○" (bolinhas, não números grandes).
- Abas: **Tiro · Mapa · Missões · Mochila** (sai Desejos).
- DEV: `dev_add_moment(pilar)`, `dev_next_period()`, `dev_set_need(id, valor)` (guarda `BuildInfo.is_dev()`).
