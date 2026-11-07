# Respiração — registro de nove desenhos por marcos internos

Experimento de 07/11/2026 após o Vitor rejeitar a prova de textura única por
parecer uma fotografia esticando. Esta versão volta aos nove desenhos detalhados,
com suas diferenças de boca, rosto e pelagem; não usa um único desenho-base.

[Comparação GIF](comparison.gif) · [Prévia com pausa/quadro](preview.html)

Colunas: pixel original, nove desenhos anteriores, nove desenhos corrigidos.

## Lógica

Em cada quadro, medir olhos, nariz, peito e patas na arte original e na
arte detalhada. Os deslocamentos da arte detalhada devem corresponder aos do
pixel, escalados em 3×. Um registro suave por múltiplos marcos (thin plate spline)
corrige os desvios **daquele desenho**, sem congelar sua expressão/textura.
Também há controles na coroa, fora do corpo e abaixo das patas para limitar
deformações externas. O registro inverso reamostra a imagem do próprio quadro,
com alpha premultiplicado para evitar franjas.

Exemplo: no quadro de maior subida, o nariz detalhado subia 37 pixels,
enquanto o original em 3× sobe 24. O erro é corrigido localmente por quadro;
o corpo não recebe uma escala global variável pelo tamanho do retângulo externo.

## Medições

O erro médio observado nos seis marcos, em nove quadros, caiu de 3,710 para
0,227 pixel na imagem 3×. O maior erro residual detectado por template matching
foi 1,414 pixel (diagonal de 1×1). São medições de **registro dos marcos**,
não uma nota de qualidade artística nem uma garantia de animação perfeita.

Nove quadros e 6 fps preservados, nove hashes originais intactos.
Chrome: imagens carregadas, seleção 0/4/8, reprodução e ausência de erros JS PASS.

`prepare.py` reproduz o preparo (numpy/OpenCV/Pillow); os PNGs de origem e as
referências image_gen continuam em `../tiro_idle_shiny_v1/`, com o prompt original.
Nenhuma nova arte foi gerada nesta tentativa.

**Limite importante:** registro pode corrigir deslocamentos/proporções entre
marcos, mas não corrige sozinho mudanças de desenho/anatomia ou cintilação da
pelagem. Se ainda houver instabilidade artística, será necessária correção das
regiões inconsistentes mantendo as restrições de pose, em vez de afirmar que
alinhamento geométrico resolve toda a continuidade. Apenas esta respiração foi
preparada; os outros três clipes não foram refeitos neste método.

Só teste local, sem alterações em `game/` e sem export/publicação.
