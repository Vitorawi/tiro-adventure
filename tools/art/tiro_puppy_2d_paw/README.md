# Patinha no rosto: prova 2D com a mesma arte

Pedido do Vitor em 07/11/2026 para testar a antiga coçada/patinha no método novo.
[Prévia](preview.html) · [GIF](comparison.gif) · [Prompt da única área nova](hidden_body_prompt.txt)

O rosto, o corpo visível e a própria perna vêm dos nove PNGs da respiração
aprovada. Foram preservados sem sobrescrita. `puppy_illustrated_paw.gd` articula
o recorte da perna dianteira da direita da imagem usando ombro/cotovelo e IK
de dois ossos; os comprimentos não mudam. A respiração mantém sua fase.

## Superfície oculta e origem da arte

Levantar a perna expõe corpo que não existia na imagem original. O **image_gen
integrado** produziu `hidden_body_generated.png` a partir do quadro 00, com o
prompt salvo acima: remover só aquela perna e completar barriga/pelagem atrás
dela. `prepare_hidden_body.py` apenas registra o canvas (768×648, deslocamento
0,+1) e grava `game/assets/sprites/characters/tiro_pet_puppy_illustrated/rig/hidden_body.png`.

O shader só usa essa imagem dentro do espaço revelado pela perna. A cabeça
gerada **nunca é usada**. O resto continua lendo a textura aprovada. Ao retornar
ao repouso, a imagem original inteira volta a ser exibida. A borda do recorte
tem suavização local; não há fade entre desenhos diferentes do cachorro.

Fontes, hashes, ferramenta e registro em `asset_manifest.json`; métricas em
`validation.json`. O preenchimento é uma superfície nova inferida, sujeita à
revisão visual; não descrever todas as partes do gesto como pixels já existentes.

## Cena e controle

- Cena editável: `game/scenes/art/puppy_2d_rig/puppy_2d_paw.tscn`.
- Controle: `game/scripts/ui/puppy_illustrated_paw.gd`.
- Corpo protegido: `puppy_paw_body.gdshader`; recorte da perna: `puppy_paw_cutout.gdshader`.
- Entrada 0,38 s, gesto de 9/8 s e saída 0,42 s: as pontes evitam começar com
  a pata já no rosto, como acontecia no sprite antigo.
- Cancelamento retorna gradualmente ao apoio sem reiniciar a respiração.

É uma prova frontal da patinha no rosto, não uma vista nova da sola da pata.
O recorte existente gira com a perna. Dobras fortes do cotovelo aproximam volume
por uma malha 2D e ainda pedem avaliação do contorno/encaixe no gesto completo.
Não representa as demais ações, uma coçada com a pata traseira ou um rig completo.

## Validação

`game/tests/puppy_2d_paw_shots.gd` recarregou a cena gravada e capturou 144 quadros
nativos a 24 fps. Testes funcionais PASS: mesma textura em corpo/perna, ossos
sem escala, alcance do punho (erro máximo observado 0,000123 px no canvas 3×),
cancelamento e respiração contínuos. `build_preview.py` confirma:

- Nove hashes originais intactos.
- Repouso e retorno: diferença RGB zero contra a imagem aprovada na mesma fase.
- Região protegida dos olhos/focinho e duas patas de apoio da esquerda: RGB
  zero de diferença nos 144 quadros.
- A pata traseira direita fica no lugar, mas a perna em movimento a encobre
  brevemente na entrada/saída. Não afirmar que todos os apoios ficam visíveis
  ou idênticos em todos os quadros.

O HTML tem capturas WebP sem perda; o GIF usa paleta reduzida para revisão.

```powershell
py tools/art/tiro_puppy_2d_paw/prepare_hidden_body.py
# Importar o PNG no Godot e habilitar mipmaps.
& $env:GODOT_BIN --headless --path game --script ../tools/prepare_puppy_2d_paw.gd
& $env:GODOT_BIN --path game --resolution 768x400 -s res://tests/puppy_2d_paw_shots.gd
py tools/art/tiro_puppy_2d_paw/build_preview.py
```

Prova separada do PetAnimator. Sem alteração de regras/save, export, push ou
publicação. A inclinação preparada antes continua separada e intacta.

A prévia dura seis segundos, quatro ciclos completos da respiração: a volta
do último quadro ao primeiro segue a fase aprovada 8 → 0. Chrome com 144 imagens
sem perda, play/pausa, seleção de entrada/gesto/saída/fim e vista isolada PASS,
sem erros JS. Rápido scripts/conteúdo/textos 3/3 PASS em 15,3 s
(`build/test_logs/r20261107_184350_632a1e5b/`).
