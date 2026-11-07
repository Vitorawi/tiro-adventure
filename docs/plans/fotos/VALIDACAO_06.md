# Fotos do Tiro — validação da etapa 06

06/11/2026, Codex, local. Somente a etapa 06; sem commit, push ou publicação.

## Entrega

- Álbum dentro do caderninho: `CodexSections._album` mantém filtros, novidades e
  visita; `CodexUi._grid_area` monta `AlbumView.book(section, width)` na mesma área
  de rolagem. As outras abas continuam usando os blocos/tiles atuais.
- `AlbumGrid`: duas colunas de botões `AlbumCard_<id>`, sem quadradinho genérico
  externo. Cartas quadradas feitas por `PhotoCard` no nível escolhido para exibir,
  com arte/moldura/foil das etapas anteriores. Cabe na largura útil existente
  (aproximadamente 116 px por carta na base lógica de 360 px; a moldura e as abas
  laterais foram preservadas). Legendas e pistas ocupam a área abaixo da carta.
- `AlbumSummary`: fotos obtidas/total da seção (fechadas contam como obtidas),
  quatro mini molduras com contagens de versões possuídas por nível e
  `Versões N/total×4`. Fechadas sem nível não contam como versão.
- `AlbumSealed`: verso e Para abrir, com `AlbumOpenSealed`/Abrir (N), contando todas
  as seções ativas. Abre a primeira pela API `AlbumView.open_photo` da etapa 05.
  Construir a grade e tocar na faixa não consomem cartas: o consumo segue no
  Abrir do verso do CardReveal. Uma foto já aberta com outra carta pendente
  conserva sua face na grade; o verso continua disponível na faixa.
- Faltantes: base da própria foto reduzida a 24×24, convertida em cinza e escura,
  ampliada com filtro linear, sem foil. Cadeado, título e hint atual embaixo.
  `tricks`/`sleep` ou campo `secret` sem pista usam somente o verso e ???, sem
  carregar sua ilustração. Após revelar a pista, a prévia escura fica disponível.
- `secret_detail`: folha PhotoSecret/CodexDetail em madeira, com prévia, pista,
  lupa, HintIcons depois de revelar e Voltar ao álbum. Herói vazio removido;
  folga inferior mantém a moldura acima das abas. Lupa esgotada usa
  `StepCardUi.locked_button`; a regra e a recarga da lupa foram preservadas.
- `AlbumNear`/`near_entries(section)`: consulta provisória barata, hint presente,
  um stat_min conhecido, progresso >0 e <meta, destino conhecido; ordena pela
  fração e limita a três, com Ir amarelo. As fotos atuais com contador útil não
  têm hint, por isso a faixa fica oculta com os dados atuais. Fixture privada
  de teste/captura cobre a faixa com o contador real de encomendas do Bloblo.
  Textos concretos e consultas gerais `photo_hint/near_photos` pertencem à 07.
- Novo continua por `seen`; abrir foto confirma a visita. `CodexUi.album_scroll`
  guarda `{scroll}` por seção e restaura ao voltar/trocar filtro/reconstruir.
  Não altera drag_scroll nem seus testes.

A seção inteira carrega de uma vez (máximo 14 fotos). Nenhum SubViewport na grade,
nenhum _process por carta; só o foil existente dos níveis 3–4 anima por TIME.
Menos animação usa o comportamento já existente do PhotoCard. Não há PNG novo,
shader novo nem instalação de lote. PhotoCard, CardViewer, CardReveal, arte da 03,
GameState, eventos, custos, probabilidades, save e catálogo de produção preservados.

## Testes

`album_book_test` registrado em suite e na área album de `tools/test_areas.json`.
Cobre os cinco grupos numerados: duas colunas/nível mostrado, resumo/versões,
faixa sem consumo/revelação, faltante cinza/segredo sem arte e toque no CardViewer.
Também cobre Novo, ausência de SubViewport, rolagem por seção e Quase lá com
fixture privada. `album_test` atualizado para o livro e para a distinção entre
seen e sealed nas boas-vindas; `album_secrets_test` confere a madeira e o verso.
Nenhum teste de obtenção foi removido.

Comando final:

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests album_book_test,album_test,album_secrets_test,manual_test,card_viewer_test -KeepGoing
```

**8/8 PASS em 117,6 s**, incluindo parse, conteúdo e textos. Evidência:
`build/test_logs/r20261106_204945_04be4330/results.csv`.
Tempos: parse 19,5 s; conteúdo 9,1 s; textos 3,4 s; livro 14,2 s;
álbum 18,4 s; segredos 12,7 s; caderninho 24,0 s; visualizador 15,0 s.
Rodada anterior normal também 8/8 PASS em 111,8 s
(`r20261106_204516_d0e30c4b`), antes do ajuste de contadores/folha da pista.

Primeira rodada (`r20261106_204413_cd8ea1c0`) teve bloqueios do sandbox no
AppData/logs/certificados do Godot e uma fixture inválida (`progress.contracts`),
corrigida para `progress.stats[order:snacks]`. Rodadas finais usam acesso normal
para logs e pastas descartáveis do circuito. Uma verificação direta inicial
expôs expectativas antigas de aba lateral versus filtro de seção, e boas-vindas
por seen versus sealed; foram atualizadas para os comportamentos atuais.
Sem portão, campanha ou simulador. SaveManager removido nos testes novos e nas
capturas; o circuito usa TIRO_TEST_TAG, sem gravar progresso pessoal.

## Capturas

`game/tests/fotos_06_shots.gd`, sem --headless, Godot 4.7.2 / Compatibility / GTX 970:

- `build/screenshots/fotos_06/`: 360×780.
- `build/screenshots/fotos_06_390/`: 390×844.
- `build/screenshots/fotos_06_412/`: 412×915.

Nove PNGs por resolução, **27 no total**: História cheia, outro instante do brilho,
rolagem, faltantes, rolagem restaurada, Para abrir, secretas, pista em madeira e
Quase lá com fixture privada (sem editar album.json). As três pranchas `_contato.png`
foram abertas e conferidas, cobrindo todas as imagens. História, faltantes e pista
360 também abertas individualmente durante a revisão.

Auditorias finais OK nas três resoluções: quadro/pista entre HUD e abas, largura
do conteúdo na área de rolagem, alvos >=44 px, textos sem corte interno, escala
uniforme de NinePatch, proporção de imagens e até um botão verde. Conteúdo fora
da janela de rolagem é recortado normalmente. Primeiras capturas expuseram quebra
do contador 14 em duas linhas e herói vazio na pista; ambos corrigidos e capturados
novamente. Botão Ir do Quase lá é amarelo para coexistir com Abrir verde.

## Continuação e pendências

Próxima SOMENTE 07, `etapas/ETAPA_07_PISTAS.md`; prompt pronto `PROMPT_07.md`.
Substituir near_entries e hints atuais pelas consultas/dados da 07, com progresso,
ícone, Ir, pista concreta após lupa e Conversar. Hoje Quase lá não aparece no
catálogo real por falta de combinação hint/contador; não inventamos pistas na 06.

Toque em Web e aparelho físico continuam pendentes; não houve export Web.
Resultados nativos e capturas não substituem medição no celular.
