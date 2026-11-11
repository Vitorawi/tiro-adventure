# Respiração do bebê — prova com base estável

Correção experimental de 07/11/2026, após Vitor identificar que a geração
independente por quadro fazia o personagem "sambar". A versão anterior só alinhava
os limites externos, com escalas variáveis: não fixava os detalhes internos.

[Comparação animada](comparison.gif) · [Prévia com pausa/quadro](preview.html)

A comparação tem três colunas: sprite original, teste anterior e nova prova.

## Método

- Reutiliza um único desenho-base (`tiro_idle_shiny_v1/frames_3x/frame_00.png`).
- Mede deslocamentos de nariz e peito nos nove sprites pixel originais com
  correspondência de template; guarda valores e confiança em `motion.json`.
- Nariz: x sempre 0; y = 0, −1, −3, −6, −8, −8, −5, −3, −1 pixels do original.
- O desenho da cabeça recebe translação rígida. O tronco faz a transição por
  deformação contínua WebGL; a faixa das patinhas fica fixa. Sem escala variável
  ou enquadramento novo por quadro.
- Só a região da boca muda de expressão: uma pequena camada do quadro fechado
  anterior é alinhada pelo nariz (+1,+1 pixels em 3×), com máscara suave. O resto
  do rosto/corpo continua sendo a mesma textura.
- Nove quadros, 6 fps; não gera arte nova nem altera os PNGs anteriores.

## Verificação

`validation.json`: patas idênticas pixel a pixel nos nove quadros; região superior
da cabeça idêntica pixel a pixel após descontar a translação medida; deslocamento
horizontal zero; nove hashes dos sprites originais preservados. Prévia sem erros
JavaScript, exportação PNG por Canvas/WebGL e GIF de comparação.

`build.py` reproduz medições/montagem (OpenCV, numpy, Pillow). `export_check.py`
renderiza a prévia no Chrome via Playwright, exporta os nove quadros e confere
as áreas estáveis. A arte é a do teste image_gen anterior; aqui a animação é
feita em código, com textura fixa, não por geração de novos quadros.

**Limite:** dois controles aproximam a respiração; isto não reproduz cada
deformação interna do sprite pixel. O fechamento da boca é uma camada separada.
Este resultado cobre só `idle_breathe`; as três outras sequências ainda são o
experimento anterior, com a instabilidade apontada pelo Vitor. Não as considerar
prontas para instalação. Aprovar a estabilidade visual deste método antes de
adaptar os controles específicos de inclinação, coçada e bocejo.

Só teste local: nada alterado em `game/`, sem export ou publicação do jogo.
