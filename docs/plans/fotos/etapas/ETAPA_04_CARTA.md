# Etapa 04 — A carta em 3D (visualizador, versões, Tentar a sorte, Melhorar)

> Tamanho: grande. Depende de: 03. Próxima: 05.
> Resultado que o Vitor vê: tocar numa foto (no caderninho/álbum de hoje) abre a carta grande em tela cheia.
> Arrastar o dedo inclina a carta para os lados e o brilho/foil acompanha. Embaixo: as 4 versões (tidas
> coloridas, faltantes escuras, tocar escolhe qual mostrar), **Tentar a sorte** (moedas) e **Melhorar**
> (materiais), e **Pôr no varal**.

## 1. Ler antes
`01_DESENHO.md` §4, §5, §6, §10.3, §10.5. `02_REGRAS_E_TESTES.md` inteiro. Código: `PhotoCard` (etapas 02/03),
`scripts/ui/album_view.gd` (`open_photo`, `detail`, `secret_detail`), `scripts/ui/modal_card.gd` (como montar
uma camada modal), `scripts/ui/step_card_ui.gd` (`go_button`, `locked_button`, `wood_chip`),
`scripts/ui/welcome_sheet.gd` (`_button` verde/amarelo), `scenes/main/main.gd` (`_queue_modal`).

## 2. Como está hoje
`AlbumView.open_photo(id)` abre `detail(id)` numa `Sheet` lisa: polaroide 264, "Fase", par antes/depois,
botões lisos "Pendurar na parede", "Foto do cantinho", "Voltar ao álbum" (screenshot de referência:
`build/screenshots/album_illustrated_360/t10_photo_detail.png`).

## 3. Passo a passo
1. **`scripts/ui/card_viewer.gd`** (`class_name CardViewer`, rode `--import`): camada em tela cheia (filho
   de `Main`, acima da `Sheet`, abaixo dos avisos), véu `SCRIM`, fecha no X de madeira, toque fora e Escape.
   API: `CardViewer.open(id: String, options := {})`, `close()`, `is_open()`. Um só aberto por vez.
2. **Carta 3D**: a carta (PhotoCard no tamanho grande, ≈78% da largura) é desenhada num `SubViewport`
   (`CardStage`), mostrada num `TextureRect` (`CardSurface`) com um shader de perspectiva no vértice
   (`assets/shaders/card_tilt.gdshader`, ou estenda o `photo_foil`) e o foil/brilho no fragmento.
   Arrasto horizontal → `tilt.x` até ±22°, vertical → `tilt.y` até ±10°; soltar volta com mola 0,35 s;
   o `tilt` alimenta o shader do nível 3/4. Toque curto (< 10 px) não inclina. "Menos animação": inclinação
   máxima ±8°, sem mola, efeito parado.
3. **Cabeçalho**: placa de madeira com o título da foto; selo do nível mostrado (`rarity_badge`); data e fase
   numa linha pequena.
4. **Versões** (`CardVersions`): 4 quadradinhos (`Version_1..4`) com a miniatura daquele nível; tidas
   coloridas com o selo; faltantes **escuras** (modulate escuro + cadeado pequeno), nunca a imagem de outra foto.
   Tocar numa tida → `GameState.set_photo_variant` e a carta grande troca com um giro rápido (flip 0,25 s).
   Tocar numa faltante → aviso curto "Tente a sorte ou melhore para conseguir".
5. **Ações** (tábua de madeira embaixo, `CardActions`):
   - `RerollButton` "Tentar a sorte · <moeda> N" (amarelo); sem moedas → `locked_button` com a moeda.
   - `UpgradeButton` "Melhorar → <nome do próximo nível>" (verde) com os chips do custo (`wood_chip`
     tem/precisa); faltando material → `locked_button` com o ícone do que falta, toque abre o "Como fazer"
     do material. Esconde quando o melhor nível é 4.
   - `FeatureButton` "Pôr no varal" / "Tirar do varal" (amarelo pequeno); com o varal cheio abre a escolha de
     qual sai (3 miniaturas tocáveis).
   - Com as 4 versões: no lugar de Tentar a sorte/Melhorar, medalhão "Coleção completa!".
6. **Resultado de Tentar a sorte/Melhorar**: depois da ação, chame a animação de resultado da etapa 05 se já existir;
   nesta etapa use um efeito simples: flip da carta para a versão nova + pulinho; versão repetida → aviso
   "Você já tinha esta versão" e a carta não troca.
7. **Ligações**: `AlbumView.open_photo(id)` passa a abrir o `CardViewer` (o `detail` liso fica só como
   reserva para testes antigos; se nenhum teste usar, remova). Antes/depois (`compare`) vira um botão
   pequeno "Antes e depois" dentro do visualizador, se a outra foto existir.
8. Desempenho: o `SubViewport` só existe com o visualizador aberto; `render_target_update_mode` só quando
   algo muda ou durante o arrasto/animação.

## 4. Não fazer
Revelação de abrir (05), álbum novo (06), varal na home (08). Nenhuma regra nova: só chamadas ao `GameState`.

## 5. Armadilhas
- O `SubViewport` precisa de `transparent_bg` e tamanho inteiro; ajuste ao redimensionar a tela.
- Arrasto vs. rolagem/fechamento: o visualizador consome o arrasto que começa na carta; fora da carta, toque fecha.
- Moedas/itens mudam com `state_changed`: reconstrua só a tábua de ações, não a carta (o giro não pode reiniciar).

## 6. Testes
Novo **`tests/card_viewer_test.gd`** (área `album`):
1. `CardViewer.open` mostra a carta da versão mostrada; X/Escape fecham; só um aberto.
2. Arrasto de 120 px para a direita deixa `tilt.x > 0` no material; soltar volta a ~0 em ≤ 0,5 s.
3. Versões: tidas coloridas, faltantes escuras; tocar numa tida chama `set_photo_variant` e troca a textura.
4. Tentar a sorte: com moedas consome e adiciona versão; sem moedas mostra `Locked_RerollButton`.
5. Melhorar: sobe 1 nível; faltando material mostra o bloqueio com o ícone do item; no nível 4 some.
6. Varal: pôr/tirar; cheio abre a escolha.
7. Um só botão verde (`wood_primary`) visível.
Lista fechada: `card_viewer_test,photo_frames_test,photo_rarity_test,album_test,ui_style_test`.
Capturas `tests/fotos_04_shots.gd` (3 resoluções): carta nível 1/3/4 parada e inclinada, versões 2/4,
Melhorar bloqueado, coleção completa.

## 7. Pronto quando
Testes passam, capturas olhadas nas 3 resoluções, inclinação suave conferida (dois quadros), sem queda de
quadros perceptível com o nível 4 aberto.
