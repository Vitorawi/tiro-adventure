# Tiro bebê — direção vigente: arte original articulada em 2D

**Escolha explícita do Vitor em 07/11/2026:** abandonar o caminho 3D e seguir
com o visual 2D exatamente como na respiração ilustrada aprovada. Este registro
substitui a recomendação anterior de modelo 3D → sprites.

## Regra de identidade

A fonte é `game/assets/sprites/characters/tiro_pet_puppy_illustrated/idle_breathe/`,
os nove PNGs aprovados, com hashes em `tools/art/puppy_idle_live/manifest.json`.
Preservar rosto, cores, manchas, pelagem, contorno e proporções. Não redesenhar o
cachorro inteiro para cada ação. O rascunho 3D não é fonte de arte para esta rota.

Preparar camadas e articulações no Godot. Nos trechos em que os arquivos atuais
já bastam, usar a textura original sem alterações. Regiões escondidas que vierem
a ser expostas e outras vistas exigem arte própria coerente, com revisão antes
de substituir qualquer superfície visível aprovada. Não prometer que cortar
uma única imagem frontal resolve rolar, virar ou levantar.

## Primeiro bloco concluído localmente

- Cena editável: `game/scenes/art/puppy_2d_rig/puppy_2d_rig.tscn`.
- Script de controle: `game/scripts/ui/puppy_illustrated_rig.gd`.
- Skeleton2D com BodyAnchor e Head; três regiões ligadas da mesma textura:
  cabeça/rosto/orelhas, ligação do pescoço, tronco/patas.
- Repouso com o Sprite2D original, sem recoloração ou geração de outra imagem.
- Respiração original nove quadros/6 fps, com fase contínua durante a inclinação.
- Inclinação de 9/7 s, rotação interpolada; cancelamento volta suavemente.
- Cena gravada por `tools/prepare_puppy_2d_rig.gd` e recarregada na validação.
- 103 renders nativos da sequência respirar → inclinar → respirar; originais
  intactos, diferença RGB zero em repouso e nas patas contra a referência na
  mesma fase. Ver `tools/art/tiro_puppy_2d_rig/validation.json`/README/HTML/GIF.

**Limite:** é uma primeira pose frontal. Orelhas, olhos, mandíbula, patas e
cauda ainda não têm controles independentes. Inclinação aproxima a ação pixel
por rotação e não replica toda sua translação/piscada. Não está no PetAnimator,
no jogo publicado nem aprovada como solução completa para as demais ações.

## Prova adicional: patinha no rosto

`scenes/art/puppy_2d_rig/puppy_2d_paw.tscn` acrescenta uma perna independente à
base aprovada. A arte oculta atrás dela foi completada uma vez com image_gen;
o corpo novo só aparece sob a máscara da perna. O rosto e a pata usam os PNGs
originais. Prévia, fontes, prompt, auditoria e limites em
`tools/art/tiro_puppy_2d_paw/README.md`. Prova local, não aprovação nem instalação.
144 renders em seis segundos, com o loop alinhado à respiração; repouso e
regiões protegidas idênticos; IK/cancelamento e Chrome PASS. Rápido 3/3 PASS.

## Próximos passos

1. Conferir esta sequência no tamanho real de tela: identidade, pescoço, apoio
   e transições. Não aceitar efeito de fotografia inteira esticada.
2. Separar orelhas/olhos/mandíbula, completando apenas superfícies escondidas
   necessárias. Fazer bocejo com mandíbula/expressão próprios e mesma cabeça.
3. Separar os quatro membros e cauda a partir de um conjunto de poses coerente.
   Conferir coçada canina com sustentação, e não movimento de braços humanos.
4. Preparar sentar/deitar/levantar/rolar com vistas e oclusão corretas. Validar
   essas ações antes de ampliar o lote; uma boa inclinação não valida o corpo.
5. Cobrir os caminhos realmente usados do inventário, incluindo sono/barriga,
   reversão, interrupções por cuidados e variantes ainda pixel. Integrar de
   forma reversível, preservando a alternativa pixel e sem misturar estilos
   inesperadamente na mesma sequência.

## Critérios por ação

Mesmo personagem; cores e manchas preservadas; articulações e quatro patas
coerentes; pés de apoio respeitados quando plantados. Peso pode ser transferido
e raiz pode se mover quando a ação pede: não congelar tudo para zerar um número.

Conferir entrada → ação → retorno, repetição e interrupção, em velocidade normal
e metade, quadro a quadro e no quarto real. Não esconder mudança de personagem
com fade. Manter fase da respiração quando compatível. Testar no Web e aparelho
antes de declarar aprovação para celular.

O inventário continua em `inventory.py`/`inventory.json`: 21 sequências + pose
sleep_belly, 206 PNGs pixel; give_paw usa wag_excited no bebê. Arte pixel, saves
e regras não foram alterados nesta preparação.

## Histórico preservado

- v1–v4: folhas redesenhadas com registro; reprovadas por continuidade.
- v5: prova de shader com pele compartilhada; parcial, fora do jogo.
- `tools/art/tiro_bebe_3d/`: rascunho 3D que o Vitor achou distante da referência.
  Não reutilizar como direção aprovada nem continuar a modelagem sem novo pedido.
- Base nativa 2D atual: `tools/art/tiro_puppy_2d_rig/`.

Nenhuma publicação autorizada/realizada nesta revisão. Mudanças de outras
sessões ficam fora deste trabalho.

## Referências técnicas

- [Godot: Polygon2D, UVs, pesos e Skeleton2D](https://docs.godotengine.org/en/stable/classes/class_polygon2d.html)
- [Godot: Bone2D e pose de repouso](https://docs.godotengine.org/en/stable/classes/class_bone2d.html)
- [Godot: animação por partes e desenhos adicionais](https://docs.godotengine.org/en/stable/tutorials/animation/cutout_animation.html)
