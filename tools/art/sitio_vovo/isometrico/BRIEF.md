# Brief — Sítio da vovó Bloblo em isométrico (para o Codex / image_gen)

## Por que refazer
A versão atual (`../horta_e_curral_hd.png`, 941×3344) é quase vista de cima: casas e celeiro de frente,
canteiros como retângulos, caminho e rio "soltos". Ao lado do apartamento (`game/assets/sprites/areas/house/apartment/room.webp`),
que é isométrico de verdade, o Tiro e os NPCs não teriam chão coerente para andar.
**Mesma ideia, mesmas ligações; só a projeção e o acabamento mudam.**

## Referências (anexar as três)
1. `game/assets/sprites/areas/house/apartment/room.webp` — **estilo e ângulo** a copiar.
2. `tools/art/sitio_vovo/horta_e_curral_hd.png` — **conteúdo e ordem** (o que existe e onde).
3. `tools/art/sitio_vovo/isometrico/guia_composicao.png` (1248×4400) — **blockout já em isométrico 2:1**:
   posições, direções do caminho/rio/cercas. Seguir a composição; ignorar cores e etiquetas brancas.
   (Gerado por `make_guide.py`, dá para mexer e regenerar.)

## Projeção (o ponto principal)
- Isométrico **2:1** igual ao apartamento: linhas do chão a ~26,6° (sobe 1 a cada 2 de lado). Nada em perspectiva, nada de frente, nada visto de cima.
- **Todo objeto mostra o topo + duas faces laterais** (esquerda e direita), com a quina mais próxima apontando para baixo, exatamente como as paredes do apartamento.
- Canteiros, cercas, currais, pontes, caminho e rio seguem **os dois eixos da grade** (diagonais para baixo-direita e para baixo-esquerda). Curvas só arredondam as quinas entre trechos.
- Verticais sempre verticais (postes, paredes, troncos, chaminé).
- Luz vinda de cima à esquerda: face esquerda mais clara, face direita na sombra, sombras projetadas para baixo-direita, suaves.
- Escala: 1 losango da grade do guia = ~80 px de largura; o Tiro ocupa cerca de 1 losango. A porta da casa tem a altura certa para a Laís passar, na mesma proporção dos móveis do apartamento.

## Estilo
Ilustração pintada, suave, quente e aconchegante, **mesma paleta e acabamento do apartamento**:
telhas de barro laranja-avermelhadas, madeira mel, grama amarelo-esverdeada com florzinhas brancas, terra batida bege-alaranjada,
contornos marrons finos, sem pixel art, sem texto além da placa "Vender".

## Conteúdo, de cima para baixo (manter tudo)
1. **Rio de cima** descendo pela esquerda, margens de pedrinhas, taboas; **ponte de madeira** no canto superior esquerdo saindo do mapa.
2. **Placa "Vender"** com caixote de legumes/frutas, na trilha que liga a ponte à casa.
3. **Casa da vovó** (canto superior direito): casinha creme, telhado de barro, chaminé, floreiras nas janelas, lampião, vaso, degrau de pedra. Porta voltada para o caminho.
4. **Caminho de terra** largo saindo da porta e serpenteando até o fim da imagem (S em trechos isométricos).
5. **Horta: 6 canteiros vazios** de madeira, 2 × 3, à esquerda do caminho — losangos com bordas de tábua e terra arada (sem plantas: o jogo desenha as plantas).
6. **Cerca de madeira** atravessando o sítio na diagonal, com **portão de duas folhas aberto** exatamente onde o caminho passa.
7. **Celeiro** (telhado de barro, porta aberta com feno, barril) com **curral cercado** à frente, à esquerda do caminho; duas vacas (uma malhada branca/marrom, uma marrom).
8. **Rio de baixo** entrando pela esquerda e descendo até o fim; **trilha** sai do caminho para a esquerda e cruza o rio numa **ponte de madeira**.
9. **Galinheiro** sobre estacas com rampinha, à direita do caminho, em **cercado** com 4 galinhas e um bebedouro.
10. Árvores amarelo-esverdeadas e arbustos nas bordas (cortadas pelas bordas da imagem), pedras, flores.

As bordas da imagem cortam a grama (o chão continua para fora), sem céu: diferente do apartamento, aqui é chão aberto.

## Saídas pedidas
- `sitio_iso_completo.png` — tudo acima. Largura **1248 px** (igual ao apartamento), altura ~4400 px (proporção do guia).
  Se o gerador não suportar essa proporção, gerar em 2–3 faixas com **sobreposição de ~300 px** e o mesmo prompt/semente, e emendar.
- `sitio_iso_fundo.png` — **mesma imagem sem** os 6 canteiros, o portão, as duas pontes e os animais (só o chão por baixo deles),
  para o jogo colocar essas peças como sprites com estados (canteiro livre/bloqueado, portão aberto/fechado, ponte inteira/destruída, animais por vaga).
- As peças soltas, já no mesmo ângulo e escala, fundo transparente: canteiro livre, canteiro bloqueado, portão aberto, portão fechado,
  ponte inteira, ponte destruída (como em `../quadrante_horta/`).

## Checagem antes de aceitar
- Sobrepor `guia_composicao.png` a 50%: caminho, cerca, canteiros e construções caem nas mesmas linhas da grade 2:1?
- As arestas dos canteiros, cercas e paredes são paralelas às linhas do chão do apartamento (~26,6°)?
- Nenhum prédio aparece só de frente; todos mostram duas faces.
- Colocar o sprite do Tiro (`tiro_world_*`) em cima do caminho e de um canteiro: parece apoiado no chão?
