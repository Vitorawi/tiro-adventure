# Brincadeiras e Truques do Tiro — desenho dos minigames

Plano de desenho (27/11/2026). Canvas com as telas: https://claude.ai/artifact/HJE32r6dBRf36kptU2CFG1
Nada implementado ainda; este documento é a referência para as etapas de código.

## 1. O que queremos

- Brincar com o Tiro tem que ser **gostoso de jogar sozinho**, não só um botão que dá ponto. Cada brincadeira é um
  minigame curto (20 a 45 s), com **um gesto principal** que a gente sente no dedo e o Tiro **reagindo de verdade**.
- Truque é **ensinar**: o jogador aprende o gesto com a mão, o Tiro aprende o truque, e depois **usa** o truque
  em outros lugares (tigela, show, amigos, fotos).
- Tudo com **um polegar**, celular em pé, sem botões direcionais. Sem tela de texto: ícone + número + uma dica curta.
- O Tiro filhote é **desastrado e fofo** (erra, tropeça, larga a bolinha); o adulto é **ágil** (combos, janelas
  menores). O mesmo jogo muda com a fase.

## 2. Regras comuns de todos os minigames

| Regra | Valor inicial | Onde mora |
|---|---|---|
| Duração | 20–45 s, 3 a 5 jogadas | `growth.json → week_play` (por jogo) |
| Resultado | 1 a 3 estrelas + recorde do jogo | `WeekState.play` (recordes) |
| Prêmio por partida | 1 momento do pilar do jogo (dentro do teto do período) + contador do jogo | `GameState._gain_moment`, `_count("play:<jogo>")` |
| Partidas que dão prêmio | 3 por período (manhã/tarde/noite); depois joga "por diversão" (sem prêmio, recorde vale) | `week_play.limit` |
| Recorde novo | +5 moedas | `week_play.record_coins` |
| Felicidade | sobe a cada partida (bolinha 10, apito 14, corda 6, esconde 6…) | `week_play.happiness` |
| Energia | brincar gasta energia; com energia baixa o Tiro boceja e a partida tem só 3 jogadas | necessidade `energy` |
| Primeira vez | mão animada mostrando o gesto (TutorialGuide), sem cobrar nada | `week_tutorials.json` |
| Menos animação | sem tremidas e confete; tempo de reação +30% | `Motion.reduced` |
| Vibração | toque leve no acerto, forte no perfeito, dupla no erro | `Haptics` |

**Tela padrão (todas iguais, muda o palco):**
1. Barra de topo de madeira: nome do jogo, bolinhas de jogadas (●●●○○), pontos e o X.
2. Palco (360×~520): cenário do Sítio/Quintal recortado, Tiro grande no meio ou no fundo, alvos.
3. Faixa da dica (uma linha) embaixo do palco: "Puxe e solte", "Segure quando ele puxar"…
4. Rodapé: o controle do jogo (quando não é no próprio palco) — botão grande, gesto ou nada.
5. Fim: folha de madeira (ModalCard) com estrelas, pontos, "Recorde!", o momento ganho (ícone do pilar voando
   para o avatar) e os botões **De novo** (amarelo) e **Pronto** (verde).

**Fase do Tiro muda o jogo:**

| Fase | Janelas de acerto | Comportamento |
|---|---|---|
| Filhotinho | +40% | tropeça, larga a bolinha no meio, senta para descansar; ganha pelo esforço |
| Dentinhos | +25% | morde a corda e não larga, quer brincar de puxar |
| Aventureiro | normal | corre mais longe, se distrai com galinha/borboleta |
| Mocinho | −15% | pega no ar, combos de 2 |
| Adulto | −25% | combos de 3, truques encadeados |

## 3. As brincadeiras (7)

Resumo:

| # | Brincadeira | Gesto | Pilar | Libera | Hoje |
|---|---|---|---|---|---|
| B1 | **Bolinha** (buscar) | puxar e soltar (estilingue) + toque "Pega!" | Corpo | cap. 10 (Quintal) | existe (estilingue, alvos) |
| B2 | **Cabo de guerra** | segurar e soltar no ritmo dele | Corpo | cap. 10 | existe (janela segurar) |
| B3 | **Chama o Tiro** ("Tiro!") | tocar quando ele olha | Esperteza | cap. 10 | existe (gancho `name_call`) |
| B4 | **Copinhos** (esconde o petisco) | seguir com os olhos + farejar segurando | Esperteza | Filhotinho (cap. 6) | existe (`HideSeekUi`) |
| B5 | **Apito no ritmo** | tocar na batida | Coragem | bolinha que apita (carroça, cap. 9) | novo (hoje o apito só arremessa mais longe) |
| B6 | **Pedrinhas da lagoa** | tocar para pular na hora | Coragem | Dentinhos (lagoa aberta) | novo (dados `bridge` já existem) |
| B7 | **Onde está o Tiro?** | procurar tocando nos esconderijos | Coragem | Aventureiro | novo (dados `hideouts` já existem) |

### B1. Bolinha (buscar)
- **Gesto:** encostar na bolinha (no pé da tela), puxar para trás e soltar. A linha pontilhada mostra a mira; a
  distância do puxão é a força (`launch.drag 0.32`, `range 0.71`).
- **Alvos no gramado:** Arco de flores 3 pts, Balde 2 pts, grama 1 pt (`targets`). Faixas de distância
  `bands [0.68, 0.5, 0.32]`.
- **Pega!:** quando a bolinha quica perto do Tiro aparece um anel em volta dele; tocar no Tiro com o anel aceso
  (`jump.opens 0.7` → `closes 1.45`) faz ele **pegar no ar**: pontos ×2.
- **Acasos (dão graça, não punem):** Lama (volta enlameado → pede banho, Pelagem), Galinha (para para latir, 0 pts),
  Vaso (esconde a bolinha atrás do vaso — toca no vaso para achar, +1).
- **Jogadas:** 5 arremessos (`throws`). **Estrelas:** 6 / 10 / 13 pontos.
- **Fases:** filhote larga a bolinha no meio do caminho em 1 de 3 viagens (ele volta para buscar — engraçado, sem
  perder ponto); adulto faz "Pega!" com janela menor e encadeia: dois "Pega!" seguidos = +1.
- **Tiro anima:** correr, pular (`happy_jump`), voltar com a bolinha na boca (`play_ball_*`), sentar e oferecer.

### B2. Cabo de guerra
- **Gesto:** **segurar** o dedo na corda quando o Tiro **puxa** (balança a cabeça, sacode) e **soltar** quando ele
  **cansa** (senta e ofega). Uma barra horizontal com o nó da corda: segurando, o nó vem para você; soltando, vai
  para ele.
- **Meta:** manter o nó na faixa verde do meio (nem arrancar a corda da boca dele, nem deixar ele cair).
  `rope.opens 1.0`, `closes 1.65`, `max_hold 2.2` (segurar demais = ele larga e late).
- **Jogadas:** 3 puxões (`pulls`). **Estrelas:** tempo na faixa verde ≥ 50% / 70% / 85%.
- **Final carinhoso:** no último puxão, **deixar ele ganhar** (soltar com o nó no lado dele) dá +1 estrela de bônus
  ("Ele ganhou! Ficou todo orgulhoso").
- **Fases:** Dentinhos morde forte e não larga (puxões mais longos); filhote cai sentado se você puxar forte.

### B3. Chama o Tiro ("Tiro!")
- **Gesto:** um botão grande "Tiro!" no rodapé. O Tiro passeia distraído pelo quintal; um anel em volta da cabeça
  acende quando ele **olha para você** (orelhas sobem, cabeça vira). Chamar com o anel aceso: ele vem correndo.
- **Distrações:** borboleta, galinha, flor, cheiro no chão aparecem e puxam a atenção (o anel some). Chamar
  distraído: ele ignora e a jogada passa.
- **Pontos:** quanto mais longe ele estava, mais pontos (1–3). 5 chamadas. **Estrelas:** 6 / 10 / 13.
- **Por quê:** ensina o nome (contador `name_call`, gancho do Para crescer).
- **Fases:** filhote demora para entender (anel aceso mais tempo, mas ele vem tropeçando); adulto vem na hora e senta.

### B4. Copinhos (esconde o petisco)
- **Gesto:** ver o petisco ir para um dos 3 copos, acompanhar as trocas e tocar no copo certo. O Tiro empurra o
  copo escolhido com o focinho.
- **Farejar (novo):** **segurar** o dedo 1 s em cima de um copo antes de escolher: o rabo do Tiro abana forte
  (quente) ou fraco (frio). 1 farejada por rodada; usar a farejada tira 1 ponto.
- **Rodadas:** 3, com trocas 3 / 4 / 5 conforme a fase (já existe). O petisco é gasto ao começar (já existe).
- **Estrelas:** acertos 1 / 2 / 3.

### B5. Apito no ritmo (bolinha que apita) — novo
- **Gesto:** **tocar** na bolinha no ritmo. Círculos encolhem sobre a bolinha; tocar quando o círculo encosta na
  bolinha ("Pi!") faz o Tiro dar um pulinho no ritmo. Perfeito / Bom / Errou.
- **Música:** 16 batidas por partida, acelerando um pouco no fim; a cada 4 perfeitos seguidos o Tiro faz uma
  dancinha (gira).
- **Estrelas:** 60% / 80% / 95% de acertos.
- **Libera:** com a bolinha que apita comprada na carroça (a mesma compra de hoje).
- **Arte nova:** bolinha com apito (já existe ícone), círculos de batida, notinhas.

### B6. Pedrinhas da lagoa — novo
- **Gesto:** **tocar** para o Tiro pular para a próxima pedra/vitória-régia. As vitórias-régias boiam e passam
  embaixo; pular na hora certa = cai em cima.
- **Dificuldade:** as pedras ficam menores a cada travessia (`bridge [0.4, 0.29, 0.2, 0.12]` = largura da área boa).
- **Cair na água:** não perde a partida — o Tiro nada, volta para a pedra e se sacode (fica molhado: Pelagem pede
  banho/secar). Cada queda tira pontos da travessia.
- **Jogadas:** 4 travessias de 4 pulos. **Estrelas:** quedas 3 / 1 / 0.
- **Libera:** Dentinhos (a lagoa já está aberta).

### B7. Onde está o Tiro? — novo
- **Gesto:** o Tiro se esconde no quintal (Vaso, Casinha, Arbusto + novos: Carrinho de mão, Fardo de feno); você
  **toca nos esconderijos** para procurar.
- **Pistas:** o rabinho aparecendo, folhas mexendo, um latido baixinho (onda no esconderijo certo), pegadas.
- **Pontos:** achar no 1º toque 3, no 2º 2, no 3º 1. 3 rodadas. **Estrelas:** 4 / 6 / 9.
- **Fases:** filhote se esconde mal (o rabo fica de fora); adulto troca de esconderijo se você demorar.

## 4. Os truques

### 4.1 Ciclo de cada truque: Aprender → Treinar → Usar

1. **Aprender (Aula)** — uma vez, com biscoito. 5 repetições de três passos (já existe para Senta/Pata/Deita):
   - **Mostrar:** arrastar o biscoito pelo caminho do truque (gesto próprio de cada truque, abaixo).
   - **Marcar:** tocar **"Isso!"** no instante em que o Tiro completa a pose (um anel em volta dele fecha).
     Perfeito ≤ 0,22 s, Bom ≤ 0,48 s (`mark_perfect`, `mark_good`).
   - **Premiar:** levar o biscoito até a boca dele em 1,6 s (`reward_seconds`).
   - Estrelas da aula: pontos 0 / 10 / 17 (`star_points`). O biscoito é gasto só ao concluir.
2. **Treinar** — sem biscoito, quantas vezes quiser. Um balão mostra o **ícone do comando**; você faz o **gesto
   curto** do truque; o Tiro faz; você marca "Isso!" na pose. 5 comandos por sessão, misturando os truques já
   aprendidos. Acertos sobem o **nível do truque**: ★ 3, ★★ 8, ★★★ 15 (`trick:<id>`, já existe).
3. **Usar** —
   - **Na tigela:** antes da refeição o Tiro senta esperando; pedir um truque (gesto curto) dá bônus de felicidade
     (`trick_meal`, já existe).
   - **Show da plateia** (Sítio, cap. 10): a plateia mostra uma sequência de 3 a 5 cartas de truques; você repete
     com os gestos curtos, na ordem (memória). Moedas; perfeito = biscoitos (já existe).
   - **Amigos na Praça:** um visitante pede um truque; fazer dá coração de amizade (novo).
   - **Fotos do álbum:** primeiro truque, primeiro show perfeito, truque ★★★.

A Nina (Fala, Rola, Pula, Gira) passa a usar **a mesma Aula** com gesto (some a barrinha de tempo antiga); ela fala
as dicas no lugar da vovó.

### 4.2 Os truques um por um

| Truque | Ensina | Libera | Gesto da Aula (Mostrar) | Gesto curto (usar) | Animação |
|---|---|---|---|---|---|
| **Senta** | vovó | cap. 5 | arco: levar o biscoito por cima do focinho, para trás | arco curto para cima | `idle_breathe` → sentado |
| **Dá a pata** | vovó | cap. 10 | descer o biscoito até a pata indicada (alterna lado) | tocar na pata | `give_paw` (filhote `lick_paw`) |
| **Deita** | vovó | cap. 10 | descer devagar até o chão e segurar 2 s | deslizar para baixo | `roll_over` (deitar) |
| **Fala** | Nina | Dentinhos | segurar o biscoito na frente do focinho e soltar quando o peito dele encher (balão crescendo) | toque duplo na boca | `bark` |
| **Rola** | Nina | Aventureiro | desenhar um círculo completo em volta da cabeça | meia-volta | `roll_over` |
| **Pula** | Nina | Aventureiro | puxar o biscoito para cima rápido quando ele agacha (sombra encolhe) | deslizar para cima | `happy_jump` |
| **Gira** | Nina | Mocinho | desenhar um círculo grande em volta do corpo, sentido horário | círculo pequeno | `chase_tail` |
| *Toca aqui* (futuro) | Laís | Mocinho | encostar a palma na pata levantada | tocar com 2 dedos | `give_paw` alto |
| *Finge de morto* (futuro) | Nina | adulto | dois toques "Bang!" e segurar | dois toques | `roll_over` parado |

Errar o gesto da Aula não pune: o Tiro fica confuso (inclina a cabeça, `head_tilt`) e a repetição recomeça.

## 5. Onde cada coisa aparece no jogo

- **Quintal do Tiro** (cesto `week_yard` no Sítio): lista das brincadeiras liberadas, com estrelas e recorde de cada
  (cartões de madeira). Toque no cartão abre o jogo.
- **Tela do Tiro → Cuidar → Brincar:** abre a mesma lista (atalho).
- **Aula do Tiro** (tapete `week_training` no Sítio) e **Treino com a Nina** (Praça): lista dos truques com nível
  (estrelas) e o botão Aprender/Treinar.
- **Desejos e Para crescer:** pedidos como "Brincar de bolinha", "Pegar no ar 3 vezes", "Truque com ★★" usam os
  contadores dos jogos.
- **Rotina do dia:** uma diária de brincadeira e uma de truque por dia.

## 6. Contadores novos (para missões, desejos e crescimento)

`play:<jogo>`, `play_stars:<jogo>:<n>`, `play_record:<jogo>`, `catch_air` (Pega!), `rope_win` (deixou ganhar),
`rhythm_perfect`, `lake_cross`, `found_tiro`, `trick_train:<id>`, `trick_command`, `show_perfect`.

## 7. Arte necessária

- **Tiro (filhote e fases):** correr, pegar no ar, puxar a corda (cabeça sacudindo), sentar ofegante, nadar e se
  sacudir, espiar de esconderijo, pulinho no ritmo — conferir o que já existe em `tiro_pet_puppy_animaref/` e nos
  clipes do `PetAnimator` antes de pedir arte nova.
- **Objetos:** corda com nó, bolinha que apita (ícone existe), copinhos (existem), vitórias-régias e pedras,
  esconderijos (vaso, casinha e arbusto existem; carrinho e feno novos), borboleta, círculos de batida.
- **Interface:** tudo em madeira ilustrada (barra de topo, faixa da dica, folha de resultado já existem).

## 8. Etapas sugeridas (uma por sessão)

1. **Base comum:** tela padrão (`PlayStage`: barra de topo, palco, dica, rodapé) e folha de resultado; recordes,
   estrelas, limite por período e contadores em `GameState`/`WeekState`. Testes do motor.
2. **Bolinha com "Pega!"** + **Cabo de guerra** com final "deixa ele ganhar" (refazer `YardPlay` na base comum).
3. **Chama o Tiro** com distrações + **Copinhos** com farejar.
4. **Apito no ritmo** (novo).
5. **Pedrinhas da lagoa** (novo).
6. **Onde está o Tiro?** (novo).
7. **Truques — Aula única** para os 7 truques (gestos de Fala, Rola, Pula, Gira) e Nina usando a Aula.
8. **Truques — Treino** com comandos e gestos curtos; níveis ★ / ★★ / ★★★.
9. **Truques — Usar:** tigela, show com gestos curtos, pedido de amigo na Praça, fotos.
10. **Quintal e lista de truques** (cartões, estrelas, recordes), desejos e rotina; capturas nas três telas.

## 9. Perguntas para o Vitor

1. Os 3 jogos novos (Apito, Pedrinhas, Onde está o Tiro?) entram todos ou começamos por um?
2. Brincar deve gastar petisco/brinquedo (custo) ou só energia?
3. A Nina continua ensinando Fala/Rola/Pula/Gira ou a vovó ensina tudo e a Nina só faz o Treino/Show?
4. O Show da plateia deve virar memória (repetir a sequência) como proposto, ou continuar como hoje?
