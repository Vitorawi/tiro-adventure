# Etapa 03 — Moldura e efeitos dos quatro níveis

> Tamanho: médio. Depende de: 02. Próxima: 04.
> Resultado que o Vitor vê: uma prancha com a mesma foto nos 4 níveis — 1 e 2 sem efeito (moldura simples e
> simples com fio dourado), 3 com moldura rara e brilho, 4 com cromo arco-íris na carta inteira. Ele aprova
> a prancha antes da etapa 04.

## 1. Ler antes
`01_DESENHO.md` §10.1, §10.2, §10.3 (só para saber o que o shader precisa aceitar), `02_REGRAS_E_TESTES.md`
§2 e §3. Código: `scripts/ui/photo_card.gd`, `assets/sprites/ui/album/polaroid.png`, peças de madeira em
`assets/sprites/ui/home/` (`item_frame`, `step_*`, `codex_*`) como referência de cor (`Palette.WOOD_*`).
Sobra: `tools/photo_frames_art.gd` (tentativa interrompida; leia, reaproveite o que servir ou apague).

## 2. Como está hoje
`PhotoCard` monta polaroide `polaroid.png` + janela quadrada + legenda; sem moldura por nível, sem shader.
Não existe shader de brilho/foil em `assets/shaders/`.

## 3. Passo a passo
1. **Arte das molduras** (script `tools/photo_frames_art.gd`, gera PNG 3× em
   `assets/sprites/ui/album/frames/`): `frame_1` papel creme limpo; `frame_2` creme com fio dourado fino;
   `frame_3` entalhada dourada/madeira com folhas nos cantos; `frame_4` prateada perolada. NinePatch em escala
   1/3 (cantos nunca deformam), mipmaps. Selos pequenos `seal_2/3/4`.
2. **Shader `assets/shaders/photo_foil.gdshader`** (`canvas_item`, Compatibility):
   - `uniform int level` (3 = brilho, 4 = foil), `uniform vec2 tilt` (−1..1, vindo do dedo na etapa 04),
     `uniform float strength`, `uniform bool still` (Menos animação).
   - Nível 3: faixa de luz diagonal que atravessa a cada ~3 s + cintilas pequenas; só sobre a arte e a moldura.
   - Nível 4: reflexo arco-íris (gradiente de matiz deslocado por UV + `tilt` + `TIME` lento) somado em modo
     tela/aditivo suave na **carta inteira**, com faixas finas de relevo; deve continuar legível (a arte é a
     estrela, o foil não lava as cores).
   - Barato: sem laços, poucas `texture()` (no máximo a própria `TEXTURE` + um ruído pequeno opcional).
3. **`PhotoCard`**: moldura pelo nível mostrado, selo, e `material` com o shader só nos níveis 3–4.
   Opções novas: `options.level`, `options.effects` (padrão true), `options.still`. Grade (≥ 4 cartas) usa o
   mesmo shader sem `tilt`. Nós: `CardFrame`, `CardArt`, `CardSeal`, `CardFoil` (preserve os nomes antigos que
   testes usam — procure em `tests/`).
4. `static func rarity_badge(level: int, px: int) -> Control` (selo com o nome do nível) para as etapas seguintes.
5. **Prancha** `tests/fotos_03_shots.gd`: `h_arrival` nos 4 níveis lado a lado (~150 px) e grande (~300 px),
   mais 2 outras fotos (uma pendente de arte); nível 4 capturado em dois instantes e com `tilt` (−1, 0) e (1, 0).

## 4. Não fazer
Carta 3D com inclinação por dedo (etapa 04), revelação (05), álbum (06).

## 5. Armadilhas
- Shader em `TextureRect` com `expand` usa `UV` 0..1 da textura: para cobrir moldura + arte juntas na etapa 04
  a carta virá de um `SubViewport`; deixe o shader independente de onde vem a textura.
- Mipmaps + shader: amostre `TEXTURE` normalmente; não use `textureLod`.

## 6. Testes
Novo **`tests/photo_frames_test.gd`** (área `album`):
1. Níveis 1 e 2 não têm `material` de efeito; 3 e 4 têm o shader com `level` certo.
2. `options.still` ou `Motion.reduced` deixam o efeito parado (`still = true`).
3. Moldura NinePatch com escala uniforme em 90, 150 e 300 px.
4. Foto fechada não recebe moldura de nível nem efeito.
Lista fechada: `photo_frames_test,photo_art_test,photo_rarity_test,album_test`.

## 7. Pronto quando
Testes passam, a prancha (3 resoluções) foi olhada e está bonita e legível, e o Vitor aprovou a prancha
(registre a resposta dele; se ele pedir ajustes, ajuste antes de fechar).
