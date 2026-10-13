# Linhas de missões por NPC — Laís e Bloblo (proposta)

> Rascunho para discussão (13/10/2026). Nada disto está implementado ainda.
> Decidido com o Vitor: **o save será zerado**; Feirante, Guia e quests antigas **ficam como estão
> por enquanto**; o foco é a linha da **Laís** (história principal) ligada à linha da **Bloblo** (sítio).
> Números de moedas/tempos são chutes iniciais: ajustar jogando.

## 1. A ideia em uma frase
Cada NPC é **uma pessoa que mora numa região** e tem **a sua própria linha de missões**.
A **Laís** conduz a história e libera o mundo aos poucos; a **Bloblo** cuida do sítio
e libera construções e **novos animaizinhos**. As duas linhas se cruzam.

## 2. O que aprendemos com outros jogos
| Referência | O que fazem | Como usamos |
|---|---|---|
| Hay Day | Animais chegam em degraus: galinha logo no começo, vaca bem depois, porco e ovelha mais tarde. Cada animal traz uma construção + produto + cadeia nova. | A linha da Bloblo libera **um animal por vez**, cada um com o seu abrigo e o seu produto. |
| Hay Day | O curral já vem com **uma vaca e ração inicial**; o primeiro moinho é grátis. | **Presente de boas-vindas:** ao liberar um abrigo, a Bloblo dá o primeiro animal. Dá para usar na hora. |
| Hay Day | Guardar moedas, porque cada desbloqueio custa. | As missões alternam **ganhar** (colher, vender) e **gastar** (comprar). |
| Fae Farm / Stardew | As missões **são** o tutorial; as quests liberam ilhas, roupas, materiais e animais. | Sem tutorial separado: cada passo ensina uma ação e já recompensa. |
| Fae Farm (crítica) | NPC que só fala de um assunto fica chato. | Falas curtas e com personalidade; a Laís comenta o que você fez, não só pede. |
| Design de onboarding | Revelar aos poucos e ensinar no momento em que precisa. | Uma ação nova por passo; a aba/lugar só aparece quando a missão pede. |

## 3. Como o jogador vê (interface)
Regras para ficar **fácil e com sensação de crescer**:

1. **Um próximo passo claro por NPC.** No máximo um passo ativo por linha, então o jogador
   vê de 1 a 3 cartões, nunca uma lista.
2. **O NPC anda no mapa.** A Laís passeia pela casa (e a Bloblo pelo sítio) com a mesma IA de
   passeio do Tiro. Sobre a cabeça aparece:
   - **`!` amarelo** = tem missão nova (tocar abre a conversa);
   - **`✓` verde** = missão pronta (tocar entrega e recebe);
   - nada = passo em andamento (tocar mostra o objetivo + Ir).
3. **A conversa é curtinha:** retrato grande + **uma fala** + objetivo em ícone e número +
   botão **Ir** (seta sobre o objeto). Na apresentação são 2 ou 3 falas, tocando para avançar.
4. **Aba Missões:** um cartão por NPC (retrato, fala atual, objetivo, barra `passo 3/6` do capítulo,
   botões **Ir** e **?**). Diárias e Semanais continuam embaixo.
5. **Entregar é uma festa:** chips de recompensa voando e, no fim do capítulo, a tela **"Novo!"**
   mostrando o que abriu (região, construção, animal, aba).
6. **Crescer à vista:** quase todo marco **muda o mapa**: um móvel novo na casa, uma área do sítio
   que perde a cerca, um bicho novo andando. Ninguém fica só com um número maior.
7. **Badge** na aba Missões e no botão Mapa quando há `!` ou `✓` esperando.

## 4. Personagens
- **Laís**: foi ela que **trouxe o Tiro**. Chega com ele no começo do jogo, se apresenta e
  ensina a cuidar dele. Mora na **Casa** e, por enquanto, **não sai de lá**.
  Arte: o retrato já existe no PixelLab (**"Laís Avatar"**, só rosto, com as animações
  "Acenando sorrindo" e "Pedindo algo"). **Falta o personagem que anda**: criar no PixelLab
  usando o retrato como referência (mesmo estilo/tamanho do Tiro no mapa).
- **Bloblo, a vovó do sítio**: calma, carinhosa e prática. Mora no **Sítio** e **nunca sai de lá**.
  Retrato já existe (`npc_bloblo/portrait.png`). O personagem que anda provavelmente é a
  **"Senhora de Verde"** do PixelLab (corpo inteiro, 8 direções). Confirmado: usar essa por enquanto,
  com o mínimo de animação (só andar); a arte pode mudar depois. Foco agora é testar a mecânica.
  Ela empresta o canteiro, ensina a plantar e **recebe a comida especial** feita na cozinha da casa.

## 5. Ordem combinada (13/10/2026)
```
Laís chega com o Tiro ─▶ cuidar (comida, banho, brincar) ─▶ Mochila
  ─▶ conhecer a Bloblo (abre o Sítio e as plantações)
  ─▶ Geladeira (lugar para guardar a colheita) ─▶ Fogão ─▶ ensopado para a vovó Bloblo (entregue no sítio)
  ─▶ Vila (vender colheita, encomendas) ─▶ portão ─▶ Natureza (madeira) ─▶ Bancada (tábuas)
  ─▶ galinheiro/curral (moedas + tábuas; vender na Vila ajuda a juntar as moedas)
  ─▶ (depois) Caverna, forno, banca, ateliê…
```
A casa **começa sem fogão e sem geladeira**: eles só aparecem quando a história pede, porque
não fazem sentido antes de existir colheita para guardar e cozinhar.
Vamos **por partes**: implementar primeiro os capítulos 1 e 2 (+ B1–B4); cada parte só abre a seguinte quando a anterior estiver jogável (ex.: a Vila precisa estar pronta para vender antes dos abrigos), testar no celular e
só depois seguir.

### Paralelismo: o jogador escolhe o que evoluir primeiro
A história **abre portas**, mas não obriga uma fila única. Sempre existem caminhos em paralelo:

- **Uma missão ativa por NPC, ao mesmo tempo:** com a Laís e a Bloblo abertas, dá para avançar
  na que quiser primeiro. O cruzamento (ex.: Laís 2.2 pede Bloblo B3) só segura **aquele** passo;
  a outra linha continua andando.
- **Coisas que já abriram ficam livres:** depois que um lugar abre (sítio, cozinha, natureza),
  o jogador pode evoluir ali no ritmo dele: comprar canteiros, abrir vagas, subir o nível de um
  local, comprar mais animais. Nada disso espera missão.
- **Timers em paralelo:** plantar, cozinhar e coletar na natureza correm juntos. Enquanto a cenoura
  cresce, o Tiro toma banho e a madeira está sendo coletada.
- **Diárias e Semanais** correm por fora da história e dão moedas para o que o jogador preferir.
- **Regra de design:** cada passo da história pede **um** objetivo, mas o jogador sempre tem
  2 ou 3 coisas úteis para fazer enquanto espera. Se em algum momento só existir "esperar",
  falta conteúdo paralelo naquele trecho.

## 6. Linha da Laís (história principal)
Cada capítulo termina num **marco** que muda o jogo (tela "Novo!" + algo novo no mapa).

| # | Fala da Laís | Objetivo (ícone + número) | Recompensa |
|---|---|---|---|
| **Cap. 1 · Um novo lar** (Casa) ||||
| 1.1 | "Oi! Eu sou a Laís, e esse é o Tiro. Agora ele é seu!" | Falar com a Laís | 3 rações |
| 1.2 | "Ele está com fome. Enche a tigela?" | Alimentar o Tiro ×1 | 10 moedas |
| 1.3 | "Eita, ele rolou na terra…" | Dar banho ×1 | 10 moedas |
| 1.4 | "Agora ele quer brincar!" | Brincar ×1 | 10 moedas |
| 1.5 | "Deixei um presente na sua mochila." | Abrir a Mochila | **Marco: Mochila** + 10 moedas |
| **Cap. 2 · O sítio da Bloblo** ||||
| 2.1 | "Minha amiga Bloblo tem um sítio aqui do lado. Vai lá conhecer!" | Falar com a Bloblo | **Marco: Sítio no Mapa** + abre a linha da Bloblo |
| 2.2 | "Já colheu alguma coisa?" | **Bloblo B3 feita** (cruzamento) | 15 moedas |
| **Cap. 3 · A cozinha** ||||
| 3.1 | "Precisamos de um lugar para guardar a colheita." | Comprar a Geladeira | **Marco: Geladeira** |
| 3.2 | "Com um fogão dá para cozinhar de verdade!" | Comprar o Fogão | **Marco: Fogão** |
| 3.3 | "Vamos fazer um ensopado para a vovó Bloblo?" | Preparar 1 ensopado e entregar à Bloblo no sítio | **Marco: Diárias** |
| **Cap. 4 · Conhecendo a Vila** ||||
| 4.1 | "Vamos passear na Vila? Tem uma feira!" | Ir à Vila | **Marco: Vila** |
| 4.2 | "Vende o que sobrou da colheita." | Fazer 1 venda | 20 moedas |
| 4.3 | "Uma encomenda paga melhor!" | Entregar 1 encomenda | **Marco: Semanais** |
| **Cap. 5 · Além do portão** ||||
| 5.1 | "O portão da Vila dá numa natureza linda, cheia de madeira." | Abrir o Bosque | **Marco: Natureza** |
| 5.2 | "Junta madeira para a gente construir." | Guardar 6 madeiras | 30 moedas |
| 5.3 | "Com uma bancada a madeira vira tábua!" | Comprar a Bancada | **Marco: Bancada** |
| 5.4 | "A vovó quer montar abrigos para os bichos." | **Bloblo B6 feita** (cruzamento) | Atributos aparecem |
| **Depois** (vamos escrever quando chegar lá) ||||
| 6+ | Caverna e forno, banca, **ateliê** (sonho da Laís) | | |

## 7. Linha da Bloblo (sítio e animais)
Abre no passo 2.1 da Laís. Cada animal novo chega com **abrigo + o primeiro bicho de presente
+ produto + uma variedade nova para comprar depois**. Os abrigos custam **moedas + tábuas**: as tábuas vêm da Bancada da Laís e as moedas,
principalmente, das vendas na Vila (que já está aberta nessa altura).

| # | Fala da Bloblo | Objetivo | Recompensa / o que abre |
|---|---|---|---|
| **Horta** (cap. 2 da Laís) ||||
| B1 | "Oi! Amigo da Laís é meu amigo. Vem ver as plantações!" | Falar com a Bloblo | **Canteiros abertos** (1 emprestado) |
| B2 | "Planta uma cenoura e espera crescer." | Colher ×1 | 10 moedas |
| B3 | "Mais umas colheitas e te dou outro canteiro." | Colher ×3 | **+2 canteiros** |
| B4 | "Me traz umas cenouras?" | Entregar 4 cenouras | 20 moedas |
| B5 | "Batata rende mais!" | Colher batata ×1 | 20 moedas |
| **Animais** (depois da Bancada, cap. 5 da Laís) ||||
| B6 | "Com tábuas a gente faz um galinheiro!" | Comprar o Galinheiro (moedas + tábuas) | **Galinha branca de presente** |
| B7 | "Galinha gosta de milho." | Recolher 2 ovos | **Libera a galinha ruiva** |
| B8 | "Agora o curral!" | Comprar o Curral (moedas + tábuas) | **Vaca pintadinha de presente** |
| B9 | "Vaca gosta de trigo." | Recolher 2 leites | **Libera a vaca caramelo** |
| B10+ | Moinho, queijaria, mais variedades, pomar, estufa | | |

## 8. O que muda no código (resumo para a implementação)
1. **Quests com `line`** (`"lais"`, `"bloblo"`) e `order` dentro da linha; um passo ativo por linha.
   `progress.claimed_quests` continua sendo a fonte; o "passo atual" de cada linha é derivado.
   A linha da Laís mantém `chapter` (é ela que define o capítulo).
2. **NPC = pessoa:** `npcs.json` ganha `world`, `sprite` (o que anda), `lines` e `intro` (falas);
   `services` deixa de ser o que define o NPC (os lugares continuam em `worlds.json`).
3. **Objetivos novos:** `talk` (falar com NPC), `quest` (passo de outra linha feito), `animals`
   (quantos bichos de um abrigo), `open` (abrir aba/mundo) e `feed_item` (alimentar com X).
4. **Recompensas novas:** `gift_animal`, `plots`, `unlock` (variedade de animal com
   `requirements` em `config.animals`) e `items`.
5. **NPC andando:** entidade `npc_world` reaproveitando a IA do `DogWorld`, com marcador `!`/`✓`
   e toque → painel de conversa (`SheetBuilder`/`ProgressionUi`).
6. **Sítio aberto pela Laís:** `worlds.json → farm.requirements = {"quests": ["lais_2_1"]}`;
   o canteiro emprestado vem da Bloblo (B1).
7. **Save:** subir `SAVE_VERSION` e **zerar** (sem migração).
8. Testes: campanha simulada do `progression_test` refeita seguindo as duas linhas.

## 9. Ideias para os próximos passos (pegar de Hay Day e cia.)
- **Ovelha → lã → tecido**: cruza a Bloblo com o ateliê da Laís (mais bonito que só fibra).
- **Abelhas → mel → biscoito de mel** pro Tiro.
- **Porquinho** (fofo, sem produto triste): acha trufas ou cogumelos.
- **Laguinho** no sítio: peixinho como petisco.
- **Feirante** e **Guia** ganham linhas próprias depois, com o mesmo modelo.
- **Encomendas da Bloblo/Laís** no quadro (estilo pedidos de caminhão do Hay Day).

## 10. Decisões e pendências
- Sprite da Bloblo = "Senhora de Verde" (PixelLab), por enquanto; animações mínimas.
- Comida da vovó = **ensopado de legumes** (receita de fogão já existente, hoje chamada
  "Caldo de legumes": 2 cenouras + 1 batata + 1 abóbora). Na implementação: renomear para
  "Ensopado" e garantir que a linha da Bloblo ensine **batata e abóbora antes do passo 3.3**
  (hoje exigem Agricultura 2 e 3) — ou simplificar a receita para cenoura + batata.
- Laís andando: criar no PixelLab a partir do "Laís Avatar", só rotações + caminhada.
