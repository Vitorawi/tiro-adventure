# Tiro bebê: mesma arte, base 2D

Direção escolhida pelo Vitor em 07/11/2026: seguir em **2D**, preservando a arte
ilustrada da respiração aprovada. O modelo 3D não é referência para esta base.

[Prévia interativa](preview.html) · [Comparação animada](comparison.gif)

À esquerda, a respiração aprovada. À direita, os **mesmos nove PNGs**, na mesma
fase de respiração, ligados a um pequeno esqueleto 2D. Nenhuma imagem foi gerada,
redesenhada, recolorida ou substituída nesta etapa.

## Estrutura preparada

- Cena editável: `game/scenes/art/puppy_2d_rig/puppy_2d_rig.tscn`.
- Controle: `game/scripts/ui/puppy_illustrated_rig.gd`.
- `Skeleton2D/BodyAnchor/Head` controla a cabeça, com pesos suaves só no pescoço.
- Três regiões conectadas: `HeadFaceEars`, `NeckBridge`, `TorsoAndPaws`.
  Todas consultam o mesmo arquivo original e mantêm UVs na posição original.
- `NeutralArtwork` usa um Sprite2D com o PNG original quando não há inclinação,
  preservando o repouso também contra arredondamentos da rasterização da malha.
- Respiração com nove quadros a 6 fps e relógio contínuo; inclinação com duração
  original de 9/7 s e curva de rotação interpolada. Sem escala dos ossos,
  fade entre cachorros diferentes ou reinício do descanso ao terminar a ação.
- Cancelar a inclinação retorna gradualmente ao repouso e mantém a respiração.

Esta é a **primeira pose frontal**, não um personagem completo com todos os
membros articulados. Orelhas, olhos, mandíbula, patas e cauda ainda precisam de
separação própria; vistas de deitar/rolar e regiões escondidas não foram criadas.
O movimento aproxima a inclinação pixel por rotação: não reproduz toda a sua
translação nem a piscada separada. Não anunciar as demais ações como prontas.

## Validação da arte e do movimento

`puppy_2d_rig_shots.gd` renderizou 103 quadros nativos a 24 fps da sequência
respirar → inclinar → respirar. `build_preview.py` compara os renders completos
das duas colunas antes de gerar GIF/HTML:

- Nove SHA256 dos arquivos aprovados conferidos contra o manifesto inicial.
- Repouso/entrada/saída: diferença máxima RGB **0** contra o original na mesma fase.
- Região das patas de apoio (source y≥460): diferença máxima RGB **0** nos 103 quadros.
- A cabeça realmente se move; pesos normalizados e patas fora da influência
  do osso da cabeça; cancelamento mantém a fase e retorna sem salto inicial.

O HTML guarda capturas WebP sem perda; o GIF usa paleta reduzida somente para
revisão. Esses testes comprovam os pontos medidos, não aprovam artisticamente
todas as poses ou garantem movimentos que ainda não foram preparados.

Reprodução, na raiz do repositório:

```powershell
& $env:GODOT_BIN --headless --path game --script ../tools/prepare_puppy_2d_rig.gd
& $env:GODOT_BIN --path game --resolution 768x400 -s res://tests/puppy_2d_rig_shots.gd
py tools/art/tiro_puppy_2d_rig/build_preview.py
```

`prepare_puppy_2d_rig.gd` é um comando de autoria: grava os ossos e as malhas
na cena editável. Não deve ser confundido com um teste somente leitura.

**Fora do jogo publicado:** PetAnimator não foi alterado. Nenhum export, push
ou publicação desta base. O interruptor pixel existente e as regras/saves
continuam no fluxo atual; integração fica para depois da revisão visual.
