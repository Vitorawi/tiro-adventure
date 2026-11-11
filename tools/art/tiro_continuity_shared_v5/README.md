# Prova isolada: mesma pele na respiração e inclinação

Pedido do Vitor em 07/11/2026, após reprovar a continuidade dos clipes separados.
Esta prova investiga um rig parcial; **não é a solução para todos os movimentos**.
O método para o conjunto completo está em `docs/plans/tiro_animacao_coerente/README.md`.

[Prévia com play, pausa e quadro](preview.html) · [Comparação animada](comparison.gif)

Três colunas: pixel original, ilustrações atualmente publicadas e prova nova.
A sequência completa é respirar → inclinar → respirar, com 103 capturas nativas
a 24 fps, duração aproximada de 4,29 s. A inclinação dura os mesmos 9/7 s.

A nova coluna usa os nove desenhos da respiração aprovada como pele de corpo e
rosto, com relógio contínuo. A cabeça gira sobre o pescoço; a região do pescoço
faz a ligação local com o torso, enquanto as patas ficam fora da deformação.
Uma camada local de pálpebras mantém a piscada. Não substitui o cachorro por
outro desenho de corpo inteiro ao começar a inclinação.

A primeira prova somava a subida do clipe à respiração e alongava o pescoço;
foi descartada. A versão final usa rotação articulada e o balanço já presente
na respiração. Isso **aproxima** a ação pixel: não conserva sua trajetória
completa de translação nem constitui um esqueleto canino tridimensional.
Não é uma aprovação de qualidade de todas as poses.

Validação em `validation.json`:

- Os nove PNGs da respiração aprovada continuam com os mesmos SHA256.
- Região inferior do corpo/patas em cada captura: diferença zero contra o
  descanso na mesma fase da respiração, inclusive durante a inclinação.
- Entrada e saída: diferença zero contra a pose neutra na mesma fase.
- O teste mede a imagem renderizada pelo Godot, não só os controles da malha.
- Prévia Chrome: 103 imagens carregadas, seleção entrada/ação/piscada/saída/fim,
  vista isolada da nova prova e zero erros JavaScript.

Reproduzir a partir da raiz (Godot 4.7.2 e Pillow/numpy):

```powershell
& $env:GODOT_BIN --path game --resolution 960x330 -s res://tests/puppy_shared_pose_shots.gd
py tools/art/tiro_continuity_shared_v5/build.py
```

Os renders ficam em `build/screenshots/puppy_shared_pose/`. O shader está nesta
pasta e só é lido pelo script de capturas, excluído do export do jogo.
`PetAnimator` não foi alterado. Sem instalação em produção, export, push ou
publicação nesta revisão. Regras e saves não foram alterados.
