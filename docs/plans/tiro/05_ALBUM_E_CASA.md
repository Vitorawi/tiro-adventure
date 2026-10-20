# 05 — Álbum de recordações e a Casa que cresce (autoritativo)

## A. Princípios

1. **Coleciona momentos de um cachorro só.** Nada de "Tiros diferentes"; cada foto é uma cena da vida dele.
2. **Você arma, ele atua.** O Tiro anda sozinho: quando as condições valem, a cena acontece e vira foto
   ("📸 Nova foto!"), vista na hora ou no cartão de boas-vindas. Sem reflexo de fotógrafo.
3. **Nada se perde.** Fotos da história ficam pendentes até serem vistas; datas valem por vários dias e voltam;
   sorte sempre com garantia.
4. **No máximo 3 condições** por foto, todas visíveis no jogo. Janelas de horário largas (≥ 3 h).
5. **Arte barata:** a foto é montada na hora (cenário + quadro do Tiro na fase em que foi tirada + adereço +
   moldura). Arte exclusiva só para adereços pequenos e para as fotos das cerimônias.
6. Ritmo saudável: ~1 foto nova por sessão no começo, ~1 por semana no fim. Sem metas diárias de foto.

## B. Seções

| Seção | Regra | Qtde |
|---|---|---|
| História | garantidas, vêm com a história e as cerimônias | 14 |
| Primeiras vezes | automáticas, na primeira vez de cada coisa | 8 |
| Travessuras | **secretas**: silhueta + título + dica enigmática | 13 |
| Soninhos | poses de sono; dependem de caminha, brinquedo, roupa, fase | 8 |
| Amigos | garantidas pelo vínculo (nunca sorteio) | 6 |
| Datas | janela de dias, voltam todo ano | 5 |
| **Total** | | **54** |


## C. Catálogo

Formato do gatilho: condições do motor (seção E). `pose` = clipe/quadro do `PetAnimator` na fase da foto.

### História (14)

| id | Título | Gatilho | Composição |
|---|---|---|---|
| `h_arrival` | Chegada | intro da Laís concluída | caixinha de papelão + Tiro espiando (adereço `box`) |
| `h_first_night` | Primeira noite | `lais_bed` recebida e primeira soneca | caminha + `sleep` |
| `h_growth_puppy` | Filhotinho! | cerimônia `puppy` | cantinho + `idle_breathe` + fita "Filhotinho" |
| `h_kitchen` | Cheirinho de papinha | primeira `puppy_mash` dada | cantinho + `eat` + adereço `bowl` |
| `h_growth_teething` | As orelhas subiram | cerimônia `teething` | cantinho + `head_tilt` |
| `h_first_walk` | O mundo é grande | volta do primeiro passeio | cenário da Praça + `look_around` |
| `h_first_trick` | Pata! | aprendeu `paw` | Praça + `give_paw` + Nina (retrato pequeno) |
| `h_growth_explorer` | Pequeno aventureiro | cerimônia `explorer` | Natureza + `sniff` |
| `h_banca` | Mascote da banca | `own_business` recebida | Vila + `wag_excited` + adereço `stall_sign` |
| `h_growth_young` | Pelo de mocinho | cerimônia `young` | cantinho + `idle_breathe` |
| `h_bench` | Um banco para a turma | `community_10_use` | Praça + banco pronto + `idle_breathe` |
| `h_courage` | Coragem de verdade | `courage_medal` recebida | Vila (festa) + `happy_jump` + adereço `medal` |
| `h_growth_adult` | Azul e dourado | cerimônia `adult` | **antes e depois**: foto `h_arrival` ao lado da nova |
| `h_guardian` | Guardião do Vale | `final_chapter` recebido | Vila + turma (retratos) + Tiro adulto |

### Primeiras vezes (8)

| id | Título | Gatilho |
|---|---|---|
| `f_bath` | Primeiro banho | primeiro `bathe` |
| `f_taste` | Primeira papinha | primeira comida de crescimento dada |
| `f_dig` | Primeiro achado | primeiro `dig` |
| `f_tooth` | Dentinho de leite | o faro acha o achado especial `milk_tooth` (garantido no 1º montinho da fase Dentinhos) |
| `f_friend` | Primeiro amigo | primeiro coração da Pipoca |
| `f_outfit` | Primeira roupa | primeira vez que veste algo |
| `f_rare` | Achado raro | primeiro raro de passeio |
| `f_brush` | Primeira escovada | primeira escovação (etapa 12) |

`milk_tooth` é um achado novo (categoria `find`, sem depósito) com ícone próprio, adicionado em `finds.json`
como `quest_find`/garantido da fase Dentinhos.

### Travessuras — secretas (13)

| id | Título | Gatilho (≤ 3 condições) | Dica enigmática (1 linha) | Adereço |
|---|---|---|---|---|
| `s_foam_ghost` | Fantasminha de espuma | carinho na cabeça até 10 s depois do banho | "Se você brincar com as bolhas antes da água cair..." | `foam` |
| `s_carrot_thief` | Ladrão da horta | colher cenoura no Sítio + Tiro no Sítio + barriga < 30 | "Barriga vazia não resiste a cenoura saindo da terra." | `carrot_mouth` |
| `s_hero_shadow` | Sombra de herói | tocar no Tiro na Praça das 17h às 20h | "O sol baixo faz qualquer cachorrinho parecer um lobo." | sombra longa (desenhada) |
| `s_sock_hunter` | Caçador de meias | fase Dentinhos ou Aventureiro + tocar 2× no cesto de roupa | "Um cesto desprotegido é presa fácil." | `sock` |
| `s_blueberry_face` | A careta do mirtilo | dar mirtilo cru pela primeira vez | "Nem toda fruta da mata é docinha." | — (`shake_off`) |
| `s_soap_explorer` | Aventureiro de espuma | banho com o chapéu de explorador vestido | "Aventureiro também toma banho... ou não?" | `foam` |
| `s_sprinkler` | Chuva suspeita | regar 5 canteiros num arrasto com o Tiro no Sítio | "Chuva que anda é muito suspeita." | `drops` |
| `s_sofa_throne` | Trono do sofá | fase Aventureiro+ + sofá comprado + soneca no sofá | "Na ausência dos olhos, todo móvel é dele." | — |
| `s_photobomb` | Penetra | rever fotos no álbum (1 chance em 8 por foto aberta, garantida na 8ª) + Pipoca ♥1 | "Tem alguém sempre aparecendo onde não foi chamada." | retrato da Pipoca no canto |
| `s_moon_friend` | Amigo da lua | Praça depois das 21h + banco pronto + usar o banco | "Quem senta sob o luar recebe as luzes que piscam." | `moon`, `fireflies` |
| `s_zoomies` | Corrida maluca | fase Aventureiro + brincar 3× em 1 min | "Às vezes a energia não cabe dentro dele." | linhas de velocidade |
| `s_begging` | Pidão | tocar na geladeira com o Tiro na Casa + barriga < 40 | "Tem um par de olhos seguindo cada porta que abre." | — (`head_tilt`) |
| `s_muddy` | Pé de lama | voltar do `creek_walk` com higiene < 30 | "Quem visita o riacho volta com um pedacinho dele." | `mud` |

### Soninhos (8)

| id | Título | Gatilho | Pose |
|---|---|---|---|
| `p_curled` | Emboladinho | primeira soneca | `sleep` |
| `p_belly_up` | Barriga pra cima | dormindo + felicidade ≥ 90 + vínculo ≥ 4 | **arte nova** `sleep_belly` (1 quadro por corpo) |
| `p_ball_hug` | Abraçado na bolinha | dormindo + noite (20h–6h) + `lost_ball` no cesto de brinquedos | `sleep` + `ball` |
| `p_sofa` | De bruços no sofá | soneca no sofá | `sleep` (cenário sofá) |
| `p_pipoca` | Encostadinhos | visita da Pipoca na Casa com o Tiro dormindo | `sleep` + Pipoca dormindo |
| `p_crown` | Cochilo real | dormindo + coroa de flores vestida + felicidade 100 | `sleep` (roupa já tem quadro de sono) |
| `p_sweater` | Quentinho | dormindo + suéter + meses frios (jun–ago; `config.json → album.cold_months`) | `sleep` |
| `p_luxe` | Sono de rei | dormindo na caminha de luxo | `sleep` + caminha de luxo |

### Amigos (6)

| id | Título | Gatilho |
|---|---|---|
| `a_pipoca` | Melhores amigas | Pipoca ♥3 |
| `a_nina_class` | Aula particular | os 5 truques aprendidos |
| `a_bloblo_helper` | Ajudante da vovó | 20 entregas para a vovó (contador de cliente) |
| `a_gathering` | Piquenique da turma | Encontro da turma concluído 3 vezes |
| `a_lais_lap` | No colo da Laís | vínculo 8 |
| `a_four_friends` | Turma dos quatro | os 4 amigos com ♥1 |

### Datas (5)

| id | Título | Gatilho | Janela |
|---|---|---|---|
| `d_month` | Um mês juntos | 30 dias desde `progress.started_at` | 7 dias |
| `d_gotcha` | Dia do Tiro | aniversário de `started_at` (todo ano) | 7 dias; bolo + chapeuzinho; libera `birthday_cake` |
| `d_full_moon` | Uivo para a lua | lua cheia (±1 dia, cálculo astronômico simples) + Praça ou Natureza depois das 20h + Aventureiro+ | toda lua cheia |
| `d_first_cold` | Primeiro frio | meses frios + suéter vestido | todo ano |
| `d_after_party` | Depois da festa | Festa concluída + entrar na Vila no dia seguinte | sempre que vale |

Data de referência: `progress.started_at` (gravado quando o save nasce).

## D. Dicas em camadas (só Travessuras e Soninhos)

1. **Sempre:** silhueta cinza + título + dica de uma linha.
2. **Com o tempo:** depois de 3 dias com a foto em aberto (e 5 fotos já tiradas), um personagem comenta na
   próxima conversa (`hint_npc` + `hint_talk` no dado).
3. **Lupa:** botão "?" mostra os **ícones das condições** (ex.: 🌙 + 🎾 + 🛏️). Uma lupa grátis por dia; a
   câmera antiga (Casa) dá uma extra.
4. **No mundo:** quando 2 de 3 condições já valem, o objeto ligado brilha de leve (`hint_object`).

## E. Motor de condições (`album.json`)

```json
{"id": "s_carrot_thief", "section": "tricks", "title": "Ladrão da horta",
 "hint": "Barriga vazia não resiste a cenoura saindo da terra.", "hint_npc": "bloblo",
 "on": "harvested", "when": {"crop": "carrot", "dog_in_world": "farm", "need_below": {"hunger": 30}},
 "icons": ["item_carrot", "world_farm", "need_hunger"], "hint_object": "plot",
 "photo": {"scene": "farm", "pose": {"clip": "happy_jump", "frame": 3}, "props": ["carrot_mouth"]}}
```

- **Eventos (`on`):** `fed`, `bathed`, `petted`, `played`, `brushed`, `slept`, `woke`, `walk_returned`, `dug`,
  `harvested`, `watered`, `tapped_dog`, `tapped_object`, `equipped`, `grew`, `quest_claimed`, `project_used`,
  `friend_heart`, `friend_visit`, `trick_learned`, `world_entered`, `album_opened`, `app_opened`.
- **Condições (`when`):** `phase_min`, `phase_in`, `hour` [de, até), `months`, `full_moon`, `world`,
  `dog_in_world`, `need_below`, `need_min`, `sleeping`, `sleep_spot`, `equipped`, `owned`, `house_item`,
  `stat_min`, `bond_min`, `friend_hearts`, `within` (segundos desde outro evento), `item`, `crop`, `route`,
  `count_in_window`.
- Um único avaliador (`GameState._album_event(evento, contexto)`) chamado pelas ações. Foto tirada uma vez
  (`AlbumState.photos[id] = {at, phase, seen}`); emite `Events.photo_taken(id)`.
- O `Database` valida ids, adereços existentes e condições conhecidas.

## F. Recompensas do álbum

| Fotos | Ganha | Onde |
|---|---|---|
| 6 | Parede de fotos + Tapete de patinha | Casa / cantinho |
| 12 | Câmera antiga (+1 lupa por dia) | prateleira |
| 18 | Moldura dourada (escolher a foto principal do cantinho) | cantinho |
| 30 | Varal de estrelinhas | Casa |
| 45 | Retrato grande do Tiro (arte especial) | Casa |

Fotos com personagem: na conversa seguinte, o personagem comenta a foto uma vez (`photo_talk`).

## G. A Casa que cresce

Objetos em `rooms/house.json` (mapa da Casa) e enfeites no cantinho (`PetBackdrop`, por cima do cenário).
Bônus sempre pequenos e opcionais.

| id | Nome | Onde | Como chega | Efeito |
|---|---|---|---|---|
| `arrival_box` | Caixinha da chegada | Casa | início | ele dorme nela até a caminha; depois vai para a prateleira |
| `height_chart` | Régua da parede | Casa (parede) e cantinho | primeiro crescimento | um risquinho por fase, com nome e data (desenhado em código) |
| `dog_bed` | Caminha | Casa | `lais_bed` (existe) | — |
| `bed_soft` | Caminha macia | troca a caminha | ateliê: tecido 2 + novelo 2; fase Mocinho | energia dormindo +10%; mais chance de `p_belly_up` |
| `bed_luxe` | Caminha de luxo | troca a caminha | bancada: tábua 2 + tecido 2 + pena 2; fase Azul e Dourado | energia dormindo +20%; foto `p_luxe` |
| `memory_shelf` | Prateleira de lembranças | Casa (parede) | primeiro item-chave entregue | mostra cada lembrança (caixinha, argolinha, mordedor, escova, medalhinha); tocar abre a foto ligada |
| `photo_wall` | Parede de fotos | Casa | 6 fotos | até 3 fotos escolhidas |
| `laundry_basket` | Cesto de roupa | Casa | presente de Dentinhos | cena `s_sock_hunter` |
| `toy_basket` | Cesto de brinquedos | Casa + cantinho | presente de Aventureiro | brinquedos dados ficam lá; +1 Esperteza por brinquedo ao brincar (máx +3) |
| `named_bowl` | Tigela com nome | troca a tigela | bancada: tábua 1 + tijolo 1; fase Dentinhos+ | comidas de crescimento +10% nos pilares |
| `paw_rug`, `old_camera`, `gold_frame`, `star_garland`, `big_portrait` | prêmios do álbum | ver F | ver F | enfeite (câmera: +1 lupa/dia) |

Regras: objetos aparecem só quando chegam (`requirements` de objeto de sala já existe); a caminha troca de
desenho pelo nível (`sprite_by` no objeto); o cantinho mostra no máximo 3 enfeites para não poluir.
