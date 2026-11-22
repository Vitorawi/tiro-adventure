# Novo fluxo do começo do jogo (plano aprovado, 20/11/2026)

Repensa a ordem em que o jogo se apresenta, da caixinha até Dentinhos.
**Aprovado pelo Vitor em 20/11/2026**, com todas as recomendações da seção 8, e com a diretriz:
*"bem legal, dinâmico, simplificado e auxiliar as pessoas o máximo possível para elas entenderem"*.
Execução na seção 10, com o Claude orquestrando subagentes etapa por etapa.

O que **fica** (o Vitor gostou e funciona): caixinha com carinho, relógio de refeições (almoço e jantar),
patinha por dia bem alimentado, Deixar pronto, motor de pratos, Cozinhar junto, Aula do Tiro, quintal,
pesca, carroça, Livro de receitas, Bom dia/Boa noite e o motor de tutoriais (`TutorialGuide`/`WeekTutorial`).
O que **muda** é a ordem, o ritmo e o que trava o jogador.

---

## 1. O que está errado hoje

| Problema | Onde está |
|---|---|
| A casa é pulada. Na 4ª fala da caixinha a vovó já diz "Venham ao sítio, vamos fazer a primeira papinha". | `week_story.json → arrival.lines[3]` |
| O primeiro passo depois da caixinha é colher cenoura e batata no Sítio. Comida, banho, brincar e dormir nunca viram passo da história. | `quests.json` cap. 1: `lais_first_crops` logo após `welcome` |
| O fogão aparece sem apresentação: o passo 3 já é "Cozinhar junto". E o fogão está na Casa enquanto a história está no Sítio. | `first_kitchen` (cap. 1, ordem 30) |
| O Álbum aparece sozinho: a foto da chegada já conta e o botão surge na home. | `h_arrival` + `AlbumButton` (aparece com `photo_count() > 0`) |
| O crescimento nunca é explicado. "Para crescer" só aparece como balão no dia 2. | tutorial `growth` (dia 2, balão) |
| O primeiro crescimento só acontece no jantar do dia 2, com uma lista de 8 coisas (caminha, 2 dias, 4 pratos, prato 2★, inventado, brincar 4, nome, Senta). O jogador nunca vê "cuidei → cresceu" no primeiro dia. | `growth.json → puppy` |
| Capítulo 1 tem 7 passos e apresenta 6 sistemas (horta, cozinha, minigame, banca, canteiros, quintal, inventar). Dia 1 tem 8 tutoriais. | `quests.json` cap. 1, `week_tutorials.json` dia 1 |
| Tudo preso ao dia do calendário: "A vovó volta amanhã", lagoa no dia 3, pomar no 4, carroça no 5, show no 6, tipos de prato e 3ª vaga da panela por dia, brincadeiras por dia. Quem quer jogar muito fica parado. | `week_quest_wait`, `farm.fishing_day/orchard_day`, `worlds.json → week_day`, `DishRules.available(day)`, `yard_rules().days`, `trick_settings.show.day` |

---

## 2. Princípios

1. **Uma coisa nova por vez.** Cada passo da história apresenta no máximo um sistema. Botão, aba ou lugar só aparece quando o passo o apresenta.
2. **Primeiro o Tiro, depois o mundo.** Começa na Casa, com os cuidados. O Sítio só abre quando o Tiro precisa de comida de verdade.
3. **Ensinar a regra do jogo cedo: cuidar → crescer.** O primeiro crescimento acontece na primeira sessão, e a tela de crescimento é explicada antes dele.
4. **Nada trava por dia do calendário.** O conteúdo abre pela história. O ritmo vem dos **tempos de produção** (que ficam mais longos) e das moedas.
5. **O único relógio de verdade é a refeição.** Almoço e jantar na hora dão patinha; patinhas são o que o crescimento pede. Quem joga muito adianta tudo, menos as patinhas.
6. **Explicar no momento de usar.** Mão + balão em cima do que vai ser tocado. Nada de lista de regras antes.
7. **Ajudar ao máximo, sem atrapalhar** (diretriz do Vitor, 20/11). Sempre existe um próximo toque óbvio: a pílula do
   próximo passo, a mão ou o brilho no objeto. Nenhum aviso de erro sem caminho ("Faltam 2 cenouras" leva à horta).
   Falas curtas (uma linha, no máximo duas), comemorar cada conquista pequena, nunca bronca.

---

## 3. Ato 1 — Em casa (sessão 1, cerca de 12 a 15 min)

Igual ao começo antigo que o Vitor gostava, com o que a semana trouxe de bom (caixinha, carinho, papinha).
Só a Casa existe. Sem Mapa, sem Missões cheias, sem Mochila. O Álbum aparece no fim do ato, como passo da história.

| # | Passo (fala da Laís) | Ensina | Aparece |
|---|---|---|---|
| 1 | Abrir a caixinha e fazer carinho (já existe, mantém) | Segurar = carinho | Tiro na tela |
| 2 | "Ele está com fome. Trouxe uma papinha pronta." | Arrastar a comida até a boca, anel da Fome | Botão Cuidar, só com Comida |
| 3 | "A caixinha sujou ele todo!" | Banho com a esponja | Banho na roleta |
| 4 | "Agora ele quer brincar." | Jogar a bolinha | Brincar na roleta |
| 5 | "Trouxe uma caminha para ele. Escolha o cantinho." | **Colocar um presente na casa**: tocar no "+" e pôr (grátis, como era antes) | Caminha na Casa |
| 6 | "Viu como ele está mudando?" Abre a tela de crescimento | **Como o Tiro cresce** (seção 5) | Anel do HUD, painel Crescer |
| 7 | Crescer! → **Filhotinho** (cerimônia) | Cerimônia, próxima fase | Lista do Filhotinho |
| 8 | "Tirei uma foto de vocês!" Abrir a carta da chegada | **Álbum**: abrir carta, versões, varal (tutorial que já existe) | Botão do Álbum, varal na home |

**O Álbum é parte central da história, não opcional** (pedido do Vitor, 20/11). Ele entra logo depois da
cerimônia porque é o momento mais emocionante da sessão: a primeira foto é a chegada do Tiro.
Depois disso, **toda conquista importante vira foto**: cada capítulo do Ato 3 termina com uma carta
fechada para abrir (seção 6), e o Dentinhos fecha com a foto de grupo do almoço de despedida.
Até o passo 8 as fotos ficam guardadas em silêncio; o botão não aparece sozinho.

No fim do passo 8 a Laís mostra a lista nova e diz a frase-gancho:
"Filhotinho come comida de verdade, **na hora do almoço e do jantar**. Quem planta tudo isso é a vovó Bloblo."

---

## 4. Ato 2 — A vovó (sessão 1 ou 2, cerca de 20 min)

| # | Passo | Ensina | Aparece |
|---|---|---|---|
| 9 | Ir ao Sítio | Mapa e viagem | Mapa com só Casa e Sítio |
| 10 | Conhecer a vovó | Conversa com personagem | Vovó no Sítio |
| 11 | Plantar e colher a cenoura (sementes da vovó, crescimento curto) | Horta: semente, regar, colher | 2 canteiros |
| 12 | "Vou te dar meu fogãozinho. Ponha na sua cozinha." Voltar para casa e colocar o fogão | Mesmo gesto da caminha: tocar no "+" e pôr (grátis) | Fogão na Casa (só agora) |
| 13 | Fazer a primeira papinha com a cenoura | Fogão + Cozinhar junto | Cozinha |
| 14 | Dar a papinha na hora do almoço ou do jantar | **Reloginho e patinha** | Reloginho no HUD, folha Hoje |

**Presentes que você coloca** (pedido do Vitor, 20/11): a caminha (Laís) e o fogão (vovó) são grátis, mas é o
jogador quem vai até o lugar e põe. O passo 5 ensina o gesto; o passo 12 repete sem precisar de mão.
As moedas só aparecem no capítulo 2, com a banca, então o Ato 1 fica sem compra nenhuma.

Fim do dia 1: Boa noite, com o gancho de amanhã.
No dia 1 continua valendo "uma refeição basta, a qualquer hora" (quem começa às 23h não perde o dia).

---

## 5. Como o jogo é explicado (passo 6)

Hoje ninguém explica a dinâmica. Proposta: um tutorial curto, **dentro do painel de crescimento**, com a mão da Laís apontando cada parte. Três falas, uma por toque:

1. "Cada fase tem uma lista. Quando tudo ficar ✓, ele cresce." (aponta a grade de passos)
2. "Tudo o que você faz por ele conta: comida, banho, brincar." (aponta os ✓ que já acenderam no Ato 1)
3. "Aqui em cima você sempre vê quanto falta." (aponta o anel do avatar no HUD)

E uma 4ª fala no passo 14, quando a patinha aparecer:
"Comer **na hora** do almoço e do jantar vale uma patinha por dia. As patinhas são o que mais faz ele crescer, e elas não dá para adiantar."

Essa última frase é importante: é ela que explica ao jogador que joga muito por que o crescimento espera.

---

## 5b. A regra da comida: onde cada parte é explicada

A regra tem oito partes. Explicar tudo junto não funciona, então cada parte é ensinada **no momento em que o
jogador precisa dela pela primeira vez**, e fica sempre disponível para rever.

| Parte da regra | Momento em que é ensinada | Formato |
|---|---|---|
| 1. Ele come **almoço (11h–15h) e jantar (18h–22h)** | Passo 14, primeira papinha | Aula da comida (abaixo) |
| 2. Comer **na hora** = ✓ naquele período | Passo 14 | Aula da comida |
| 3. Almoço + jantar na hora = **1 patinha** | Passo 14 | Aula da comida |
| 4. **Patinhas fazem crescer** (6 = Dentinhos), uma por dia, não dá para adiantar | Passo 14, termina no painel Crescer | Aula da comida |
| 5. Escolher o **horário** (mais cedo, normal, mais tarde) | Boa noite do dia 1 | Pergunta no cartão |
| 6. **Deixar pronto** quando não vai estar na hora | Primeira vez que abre o jogo antes de uma janela e vai sair (Bom dia do dia 2, de manhã) ou cozinha uma refeição fora da hora | Dica no lugar, com a tampinha |
| 7. **Lanche não é refeição** | Primeira vez que dá um petisco | Balão curto |
| 8. **Dia fraco** e marmita da vovó | Primeiro dia em que falta uma refeição | Cartão no Bom dia, sem bronca |

### A aula da comida (passo 14)

É a lição mais importante depois da caixinha. Acontece na casa, com a Laís, logo depois da primeira papinha.
Cinco toques, cada um apontando uma coisa na tela:

1. **Reloginho** (pulsa no avatar do HUD): "Viu o reloginho? Ele fica verde quando é hora de comer."
2. **Folha Hoje** abre sozinha, com os dois espaços: "Filhotinho come duas vezes por dia: almoço, das 11h às 15h, e jantar, das 18h às 22h."
3. **Arrastar a papinha** até ele. O espaço ganha ✓: "Deu na hora? Ganhou um ✓."
4. **A patinha aparece** e voa até o avatar: "Almoço e jantar na hora valem uma patinha. Hoje é especial: uma papinha já vale!"
5. **Painel Crescer** abre na linha das patinhas (1/6): "Seis patinhas e ele ganha os Dentinhos. É uma por dia, não dá para adiantar."

**A primeira patinha é garantida na aula**, a qualquer hora (ver 5c). As falas 2 e 3 mudam conforme o relógio:

| Hora em que a aula acontece | Fala 2 | Fala 3 |
|---|---|---|
| Dentro do almoço ou do jantar | "É hora do almoço! Ele come duas vezes por dia..." | "Deu na hora? Ganhou um ✓." |
| Manhã ou tarde, fora da janela | "Ele come no almoço e no jantar. Hoje é o dia da chegada, então qualquer hora vale." | "Pronto, valeu! O próximo é o jantar, às 18h." |
| Noite e madrugada (22h às 6h) | "Comidinha antes de dormir! Ele come no almoço e no jantar..." | "Agora é hora de dormir. Amanhã é o almoço." O Tiro boceja e vai para a caminha, e a sessão termina no Boa noite. |

---

### Boa noite do dia 1

O cartão termina com o combinado de amanhã, que é a primeira vez que a regra vale de verdade:
- "Amanhã ele precisa de **almoço e jantar na hora** para ganhar a patinha."
- Os dois horários, com os botões **Mais cedo · Normal · Mais tarde**.
- "Quer que eu avise na hora de comer?" (o aviso opcional, que hoje só é oferecido depois do primeiro dia fraco, passa para cá; decisão F8).

### Bom dia do dia 2

"Hoje é o primeiro dia de verdade: almoço e jantar na hora." Se abrir antes das 11h, aparece a dica da tampinha:
"Vai sair? Deixe o almoço pronto na tigela e ele come sozinho no horário."

### Para rever a qualquer hora

- A folha **Hoje** (tocar no reloginho) tem um **?** que reabre a aula em uma tela: o dia de 24 h com as duas janelas, ✓ ✓ → patinha → crescer.
- O painel Crescer, na linha das patinhas, mostra "próximo almoço em 2 h" e o mesmo **?**.
- O Manual do caderninho ganha a página **Comida e crescimento** com o mesmo desenho.

---

## 5c. Primeira refeição e quem joga em horário diferente

Pedido do Vitor (20/11): a primeira comida nunca pode travar, e quem começa à meia-noite precisa entender tudo.

### Comer nunca trava

- **Dar comida sempre funciona.** Fora da janela ele come do mesmo jeito e a fome passa; só não conta para a patinha.
- **Antes da aula (passos 1 a 13) o relógio não existe para o jogador:** sem reloginho, sem folha Hoje, sem a pergunta "Dar agora ou Deixar pronto". A papinha da Laís no passo 2 só mata a fome.
- **A pergunta "Dar agora / Deixar pronto" só aparece depois da aula**, e nunca na primeira refeição de um dia.
- Nos passos da história que pedem comida, o Tiro **não dorme sozinho** à noite, para nenhum cuidado ficar bloqueado no meio da aula.

### O dia do Tiro vira às 6h, não à meia-noite

A madrugada conta como "a noite de hoje". O Bom dia aparece de manhã e a madrugada fica sendo a hora de o Tiro dormir.
Sem isso, quem dá o jantar às 23h e volta à 0h30 já estaria num dia novo, com as regras zeradas. (Decisão F9.)

### O dia da chegada é livre

- O dia da chegada vai até **as 6h da manhã seguinte**. Nele, uma refeição a qualquer hora vale a patinha, e ela já sai na aula.
- O **combinado** (almoço e jantar na hora) começa no dia seguinte. O Boa noite diz quando: "Seu primeiro combinado começa amanhã, no almoço das 11h."

| Começou às | Dia da chegada vai até | Primeiro combinado |
|---|---|---|
| 9h de segunda | 6h de terça | almoço de terça |
| 20h de segunda | 6h de terça | almoço de terça |
| **00h10 de segunda** | 6h de segunda (é a noite de domingo) | **almoço de segunda**, 11 h depois. Ele dorme, acorda e já está no primeiro dia de verdade, sem perder nada |
| 4h de segunda | 6h de **terça** | almoço de terça. Se faltam menos de 3 h para a virada, o dia da chegada se estende um dia, para não começar com pressa |

### Quem só joga uma vez por dia

Hoje esse jogador nunca ganha patinha: o Deixar pronto guarda **uma** refeição, só para a próxima janela.
Proposta: a **tigela de dois lugares**. Antes de sair, ele deixa o almoço e o jantar prontos, e o Tiro come cada um na hora.
Conta para a patinha do mesmo jeito. Quem dá na hora, ao vivo, continua ganhando mais: Felicidade extra, o pedido de truque antes de comer e o momento do desejo. (Decisão F10, aprovada.)

### Equilíbrio: jogar ao vivo dá carinho, não velocidade

Aprovado pelo Vitor (20/11): não penalizar quem não consegue jogar duas vezes por dia.

| Joga | Patinhas | O que ganha a mais |
|---|---|---|
| Uma vez por dia, deixando a tigela pronta | 1 por dia, igual | — |
| Almoço e jantar ao vivo | 1 por dia, igual | Felicidade extra, pedido de truque antes de comer, desejo do período |
| Falta um dia | aquele dia não conta | Nada se perde; a marmita da vovó ajuda depois de 2 dias fracos |

Exemplos com a tigela de dois lugares: quem joga às **8h** deixa almoço e jantar; quem joga às **20h** dá o jantar ao vivo e deixa o almoço
de amanhã; quem joga à **meia-noite** deixa os dois do dia que começa. Todos crescem no mesmo dia.
O Boa noite de quem vai sair sem a tigela cheia lembra uma vez: "Quer deixar a comida de amanhã pronta?"

### Fazer disso uma parte gostosa do dia

- **Ele mostra que está com fome.** Quando a janela abre, o Tiro vai até a tigela, abana o rabo e a tigela brilha. Fora da janela ele fica deitado, satisfeito: "Já almocei!".
- **Cartela de patinhas.** No painel Crescer e na folha Hoje, uma cartela com **6 espaços**, como cartão de carimbo. A cada dia completo um carimbo cai com o desenho do prato que ele comeu, com um "Dia completo!" curto. O primeiro carimbo é especial: "Dia da chegada". A cartela cheia vira o Crescer! do Dentinhos.
- **Recado ao voltar.** Se deixou pronto: "Ele comeu o almoço às 11h12 ✓" no Bom dia ou nas boas-vindas, com a tigela vazia na casa.
- **Dia fraco sem bronca.** O carimbo daquele dia fica vazio e tracejado, e a vovó comenta: "Ontem ele ficou com saudade. Hoje a gente capricha!"

---

## 6. Ato 3 — A semana no Sítio (abre pela história, não pelo dia)

Cada capítulo apresenta **um** sistema e termina num prato-chave que o Dentinhos pede.
A ordem segue a lista do crescimento, então o jogador sempre sabe por que está fazendo aquilo.

| Cap. | Sistema novo | Termina com | Espera natural (o que segura o ritmo) |
|---|---|---|---|
| 2 | Banca: vender e comprar sementes, mais canteiros | Sopinha (2º tipo de prato) | Abóbora e batata crescendo |
| 3 | Desejo do Tiro (balão, um por período) | Atender o primeiro desejo | Período do dia |
| 4 | Galinheiro (kit): milho → ovos | Prato com ovo | Lote de ovos |
| 5 | Aula do Tiro: Senta (biscoito de aveia) | Senta aprendido | Biscoitos no fogão |
| 6 | Lagoa: pescar com a vovó (tutorial já existe) | Prato com peixe | Iscas do dia |
| 7 | Pomar: macieira e bananeira | Mingau / prato com fruta | Frutas amadurecendo |
| 8 | Inventar + Livro de receitas | Prato inventado | Ingredientes |
| 9 | Carroça do Feirante: encomendas e xampu | Banho com xampu | Pedidos que renovam |
| 10 | Quintal: cabo de guerra, show, esconde-esconde | Show de truques | — |
| 11 | Argolinha + almoço de despedida | **Dentinhos** → Vila | **Patinhas** |

**Cada capítulo termina com uma foto.** O último passo de cada capítulo entrega uma carta fechada daquela
conquista (primeiro ovo, primeiro peixe, o Senta, o banho de espuma...). Abrir a carta vira o "fechamento"
do capítulo, e o Álbum vai enchendo junto com a semana. Fotos que já existem no `album.json` são reaproveitadas
onde couber; as que faltarem entram como fotos novas da semana.

---

## 6b. Checagem: todo sistema aparece, é ensinado e dá para rever

"Simples, porém completo": nenhum sistema aparece sem ser apresentado, e todo sistema tem onde rever.
Rever = Manual do caderninho (`GameManual.open("tutorials")`, uma página por linha desta tabela) e o "?" no próprio lugar.

| Sistema | Aparece em | Como é ensinado | Onde rever |
|---|---|---|---|
| Carinho | Passo 1 | Mão: segurar | Manual |
| Comida, banho, brincar | Passos 2–4 | Mão em cima do botão Cuidar | Manual, roleta |
| Colocar presente na casa | Passo 5 (caminha), repete no 12 (fogão) | Mão no "+" | — (gesto único) |
| Crescer | Passos 6–7 | Aula do painel, 3 toques | "?" do painel Crescer, Manual |
| Álbum e cartas | Passo 8 | Tutorial da carta (já existe) | "?" do Álbum, Manual |
| Próximo passo (pílula no topo) | Passo 8, depois da cerimônia | Balão: "Toque aqui para saber o que fazer" | Sempre visível |
| Mapa | Passo 9 | Mão na pílula do mundo | Manual |
| Personagens | Passo 10 | Conversa da vovó | — |
| Horta | Passo 11 | Mão: arrastar a semente | "?" do canteiro, Manual |
| Mochila | Passo 11, ao colher a primeira cenoura | Balão: "Guardei aqui" | Manual |
| Fogão e Cozinhar junto | Passos 12–13 | Mão nos três passos | "?" do fogão, Manual |
| Refeições e patinhas | Passo 14 | Aula da comida, 5 toques (5b) | "?" da folha Hoje e do painel, Manual |
| Bom dia e Boa noite | Fim do dia 1 | O próprio cartão | — |
| Aba Missões | Fim do Ato 2 (primeiro capítulo completo) | Balão na aba | Sempre visível |
| Moedas e banca | Cap. 2 | Mão em Vender e Comprar | Manual |
| Desejo | Cap. 3 | Balão no Tiro | Manual |
| Galinheiro | Cap. 4 | Mão: dar milho | "?" da bandeja, Manual |
| Truques | Cap. 5 | Aula do Tiro (já existe) | Caderno de truques |
| Pesca | Cap. 6 | Tutorial da vovó (já existe) | "?" da lagoa, Manual |
| Pomar | Cap. 7 | Balão | Manual |
| Inventar e Livro | Cap. 8 | Mão na aba Inventar | Livro de receitas |
| Carroça e encomendas | Cap. 9 | Mão na carroça | Manual |
| Quintal | Cap. 10 | Mão em cada brincadeira | Manual |
| Desafio do dia | Quando só faltam patinhas | Balão da vovó | Próximo passo |
| Missão secreta | Quando só faltam patinhas e o desafio foi feito | Selo "Segredo" da vovó | Missões |

Hoje são 33 lições na semana. Com esta tabela ficam **uma por linha** (cerca de 25), cada uma presa ao passo em que o sistema aparece.

---

## 7. Ritmo: quem joga muito × quem joga pouco

**Regra:** a história nunca diz "volte amanhã". Se o jogador tem tempo e moedas, ele pode fazer os capítulos 2 a 10 em sequência.
O que segura são os tempos (alongados de propósito) e as moedas.

Meta de ritmo (o simulador confirma depois):

| Perfil | Capítulos 2–10 (conteúdo) | Dentinhos (patinhas) |
|---|---|---|
| Joga muito (3+ sessões por dia) | 2 a 3 dias reais | dia 6 ou 7 |
| Regular (1–2 sessões) | 5 a 7 dias | dia 7 a 9 |
| Perde um dia | igual, um dia depois | um dia depois, sem perder nada |

Para quem joga muito, os tempos da produção ficam mais longos que os de hoje (hoje: ovos a cada 30 min, frutas a cada 2 h, abóbora 10 min).
Números finais saem da simulação, não deste doc.

**Quando só faltam as patinhas** (o caso que o Vitor levantou):
- O painel de crescimento mostra só isso: "Falta: 3 patinhas · próximo almoço em 2 h", sem parecer erro.
- A pílula do próximo passo vira o **desafio do dia da vovó** (os 7 desafios de `week_story.json → days` viram desafios opcionais, um por dia, com prêmio pequeno).
- Conteúdo de profundidade que não depende de dia: estrelas das receitas, descobrir pratos no Livro, nível dos truques, recorde de peixe, encomendas da carroça, fotos.
- A Vila **não** abre antes de Dentinhos (decisão do Vitor, 20/11). Para quem chegou antes, existe a missão secreta abaixo.

### 7.1 Missão secreta da vovó: o Ensopado Dourado

Ideia do Vitor (20/11): quem chega antes ganha uma missão secreta, mais difícil, com uma comida "mega reforçada" que acelera o crescimento.

**Quando aparece:** só quando **todos** os passos do Dentinhos estão ✓ e faltam apenas patinhas.
Quem joga no ritmo normal nunca precisa dela (e quase nunca vê). A vovó chama em segredo, com o selo
"Segredo" no lugar do "!": *"Psiu... tem um jeito antigo de deixar ele forte mais rápido. Mas não é fácil."*

**O que pede** (três partes, cada uma um sistema que ele já domina, na versão difícil):

| Parte | Como consegue | Por que é difícil |
|---|---|---|
| Minhoca gorda | Achado raro do faro (montinhos do Tiro), só com a missão ativa | Sorte + cavar vários montinhos |
| **Peixe dourado** | Pescado na lagoa com a minhoca gorda; morde no máximo 1 vez por dia | Puxada mais forte do minigame e só vale com pescaria **Perfeita**; se escapar, só amanhã |
| Ensopado Dourado | Peixe dourado + abóbora + ovo, só pelo **Cozinhar junto** com 3 estrelas | A fila não faz; 1 ou 2 estrelas vira um ensopado comum |

**O que faz:** dado **na hora** do almoço ou do jantar, vale **uma patinha extra** naquele dia (o dia conta 2).
Não vale pelo Deixar pronto: precisa estar lá na hora.

**Limites:** um por dia (o peixe dourado só morde uma vez por dia) e no máximo **2 patinhas extras** na fase.
Assim quem joga muito e acerta tudo cresce por volta do **dia 5** em vez do dia 7, sem pular a semana inteira.

**De brinde:** a primeira vez rende a foto secreta "O peixe dourado" no Álbum.

---

## 8. Decisões (todas fechadas em 20/11/2026)

| Nº | Decisão |
|---|---|
| F1 | Primeiro crescimento (Filhotinho) na **sessão 1**, com a lista simples do Ato 1 (comer, banho, brincar, caminha). A lista grande da semana vai para o Dentinhos. |
| F2 | **6 patinhas** para o Dentinhos; o dia da chegada conta. |
| F3 | Vila só depois do Dentinhos; quem chega antes ganha a missão secreta (7.1). |
| F3a | Missão secreta: **+1 patinha por dia, no máximo 2 na fase**. |
| F3b | Comida secreta: **peixe dourado → Ensopado Dourado**. |
| F4 | A vovó dá o fogão de graça e o jogador vai à Casa colocar (passo 12), igual à caminha (passo 5). |
| F5 | Álbum na história: passo 8 e uma foto fechando cada capítulo. |
| F6 | Aula do Tiro **sem limite por período**, só o custo de 1 biscoito. |
| F7 | Ordem dos capítulos 2 a 11 como na seção 6. |
| F8 | Oferecer o aviso de hora de comer no **Boa noite do dia 1**; desligado até o jogador aceitar. |
| F9 | O dia do Tiro vira às **6h**. |
| F10 | **Tigela de dois lugares**; jogar ao vivo dá carinho, não velocidade. |

---

## 9. O que muda no código (inventário para o plano)

**Sai**
- `week_quest_wait` ("A vovó volta amanhã" / "no jantar") e a regra "um capítulo por dia" (`week.last_story_chapter_date`).
- Travas por dia: `farm.fishing_day`, `farm.orchard_day`, `worlds.json → village/week_day`, `requirements.week_day` dos truques, `trick_settings.show.day`, `yard_rules().days`, `DishRules.available(day)` e `slot_count(day)`, `recipe_book.json → from_day`, `week_routine.json` cartões por dia. Tudo vira requisito de missão (`quests`) ou de compra.
- A 4ª fala da vovó na caixinha.

**Muda**
- `quests.json` capítulos 1 a 7: refeitos como Ato 1 (casa), Ato 2 (vovó) e Ato 3 (capítulos por sistema).
- `growth.json → puppy` (lista curta do Ato 1) e `teething` (recebe a lista da semana + patinhas).
- `week_tutorials.json`: o campo `day` vira o passo da história que dispara a lição. A lição nova do painel de crescimento (seção 5) entra.
- Botão do Álbum e fogão só aparecem pelo passo da história (Álbum no passo 8; o `AlbumTutorial` atual passa a disparar por esse passo, não pela missão `lais_album`).
- Cada capítulo do Ato 3 ganha uma foto de fechamento em `album.json` (reaproveitar as que já existem).
- Missão secreta (7.1): item `golden_worm` (achado do faro), peixe `fish_golden` em `fishing.json`, prato `golden_stew` só pelo Cozinhar junto 3★, regra de patinha extra no `_register_meal` com teto por fase.
- Tempos de produção (`recipes.json`, `crops.json`, `config.json → farm`) alongados pela simulação.

**Fica igual**
- Relógio de refeições, patinha, Deixar pronto, dia fraco e marmita (`WeekState`, `MealUi`).
- Motor de pratos, cozinha, Cozinhar junto, Aula, quintal, pesca, carroça, livro, Bom dia/Boa noite.
- Motor de tutoriais. Só muda quando cada lição dispara.

---

## 10. Plano de execução

Uma etapa por vez, sequenciais. O Claude orquestra: escreve o briefing de cada etapa em `etapas/`,
manda a implementação a um subagente, revisa diff, testes e capturas, pede correções e só então abre a próxima.
Regras de sempre: saves zerados (subir `SAVE_VERSION` quando o formato mudar, sem migração), testes por nível
(`tools/test.ps1 -Level etapa` em toda etapa, `portao` em F02 e F04, `campanha` só na F05), sem commit, push
ou publicação sem o Vitor pedir, `CLAUDE.md` = `AGENTS.md`, registro no "Estado atual" do `docs/ROADMAP.md`.

| Etapa | Entrega | Briefing |
|---|---|---|
| F00 | Tirar as travas por dia: o conteúdo passa a abrir pelo capítulo da história (`content_day`), a história nunca diz "volte amanhã". O relógio das refeições fica igual | `etapas/F00_sem_travas.md` |
| F01 | Ato 1 em casa (passos 1–8): falas da caixinha sem a vovó, cuidados um por vez, caminha colocada, lista curta do Filhotinho, Álbum como passo 8 | `etapas/F01_ato1.md` |
| F02 | Lição do painel de crescimento + aula da comida (5b e 5c): falas por horário, dia da chegada livre, virada às 6h, tigela de dois lugares, cartela de patinhas, Boa noite/Bom dia com o combinado, "?" da folha Hoje e página do Manual | `etapas/F02_aula_da_comida.md` |
| F03 | Ato 2 com a vovó (passos 9–14), fogão dado pela vovó e colocado pelo jogador, Mochila e Missões apresentadas | `etapas/F03_ato2.md` |
| F04 | Ato 3: capítulos por sistema, foto de fechamento em cada capítulo, desafios do dia, lições presas ao passo | `etapas/F04_ato3.md` |
| F04b | Missão secreta do Ensopado Dourado | `etapas/F04b_segredo.md` |
| F05 | Tempos e moedas pelo simulador (perfis "joga muito", regular, perde um dia) | `etapas/F05_ritmo.md` |
| F06 | Revisão completa nas três resoluções + roteiro de celular para o Vitor | `etapas/F06_revisao.md` |

Os briefings de F01 em diante são escritos quando a etapa anterior termina, a partir do código como ficou.

## Andamento

- 20/11/2026: plano aprovado. F00 em execução.
- 20/11/2026: F00 implementada localmente (`content_day()`, sem espera de dia, `SAVE_VERSION` 34). `farm.early_through` (primeiros dias mais rápidos) ficou no calendário: a F05 decide se vira capítulo.
- 21/11/2026: F00 revisada pelo Claude (8 testes PASS na conferência). F01 (Ato 1 em casa) em execução.
- 21/11/2026: F01 (Ato 1 em casa, passos 1 a 8) implementada localmente; capturas em `build/screenshots/ato1/`. F02 é a próxima.
- 21/11/2026: F01 revisada pelo Claude (capturas conferidas, correções de moedas/Casa/painel/folha; 9 testes PASS). F02 Parte A (regras do relógio) em execução.
- 21/11/2026: F02 Parte A (regras do relógio: virada às 6h, dia da chegada estendido, relógio só depois da aula, tigela de dois lugares, `meal_ask_allowed`, `SAVE_VERSION` 36) implementada localmente; teste `meal_rules_test`. Parte B (aulas e telas) é a próxima.
- 21/11/2026: F02 Parte B (lição do painel, aula da comida em cinco toques, cartela de patinhas, Boa noite/Bom dia novos, "?" e Manual, tigela e fome) implementada localmente; teste `food_lesson_test`, capturas `tests/food_lesson_shots.gd`. F03 é a próxima.
- 21/11/2026: triagem do portão da F02: testes ajustados às regras novas, falhas antigas confirmadas na base anterior, "Pular" pequeno na aula, Boa noite com Sim / Agora não e reloginho fora da borda (ver ROADMAP).
- 21/11/2026: F02 revisada e fechada pelo Claude. Portão: as falhas novas eram testes da regra antiga (ajustados) ou ruído de carga; sobram só falhas anteriores ao novo fluxo (4 testes de toque iguais no HEAD + as de 19/11). Boa noite do dia 1 sem a pergunta da tigela (fica para os Boa noite seguintes). F03 (Ato 2 com a vovó) em execução.
- 21/11/2026: F03 (Ato 2 com a vovó, passos 9 a 14) implementada localmente: fogão dado e colocado, aula da comida no passo 14, moedas/banca/Missões só no capítulo 2, `SAVE_VERSION` 37; teste `ato2_test`, capturas `tests/ato2_shots.gd`. F04 (Ato 3) é a próxima.
- 21/11/2026: F03 revisada pelo Claude (capturas conferidas, 8 testes PASS). Ficam para a F04: placas "dia N" do Sítio, seletor mostrando mundos trancados distantes, mão do balão das Missões apontando a aba. F04 Parte A (capítulos 2–11 e fotos) em execução.
- 21/11/2026: F04b (missão secreta da vovó: minhoca gorda, peixe dourado, Ensopado Dourado 3★ e patinha extra) implementada localmente; `SAVE_VERSION` 39, teste `secret_stew_test`.
- 21/11/2026: F04 Parte A (capítulos 2 a 11 por sistema, renumeração do pós-semana para 12–20, fotos de fechamento, Inventar e Livro no capítulo 8, teste `ato3_chapters_test`) implementada localmente. Parte B (lições presas ao passo, placas, seletor, desafio do dia, portão) é a próxima.
- 21/11/2026: F04 Parte B (lições presas ao passo, desafio do dia pela pílula, placas "Em breve", seletor só com abertos + Vila, mão na aba Missões, `SAVE_VERSION` 38) implementada localmente; teste `ato3_help_test`, capturas `tests/ato3_shots.gd`. Portão e triagem no relatório da etapa. F04b é a próxima.
- 21/11/2026: F04 (partes A e B) revisada pelo Claude: capítulos 2–11 por sistema, fotos de fechamento, lições presas ao passo, desafio do dia, placas "Em breve", seletor só com a Vila trancada. Portão: falhas restantes antigas ou ajustadas. F04b (Ensopado Dourado) em execução.
- 21/11/2026: F04b revisada pelo Claude (missão secreta do Ensopado Dourado; `fishing_test` ajustado para a lagoa no capítulo 6; 7 testes PASS). Pendente pequeno: selo "Segredo" no cartão da missão em Missões → Pessoas. F05 (ritmo) em execução.
- 21/11/2026: F05 (ritmo) implementada localmente: robô por sessões, `early_through` 0, `max_extra` 1; resultados em `docs/plans/novo_fluxo/RESULTADOS.md`. Campanha no relatório da etapa.
- 21/11/2026: F05 revisada pelo Claude. Ritmo medido com o robô por sessões (`week_session_route.gd`); `farm.early_through` 2→0; campanha PASS. O teto da missão secreta voltou para 2 (decisão F3a), com a troca registrada no RESULTADOS para o Vitor decidir. F06 (revisão final) é a próxima.

- 21/11/2026: F06 (revisão final nas três resoluções, correções de interface, toque real parcial, portão e roteiro do celular) implementada localmente. **Plano Novo fluxo concluído**; ver RESULTADOS.md.
- 22/11/2026: acabamento da F06: testes ajustados às regras novas (festival, album, growth_story, manual, park, flavors, photo_rarity, walk_return, ready_badges, nature, nature_routes, item_sources), três ajustes de interface (Boa noite com uma frase só, aviso acima da guia de comida, Pular fora do rosto da vovó), recaptura conferida em 360x780 e 412x915; falhas que sobram são antigas (lista em RESULTADOS.md, seção Portão).
