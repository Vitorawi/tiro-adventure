# Etapa 01 — Base: fontes, cores, ícones de controle e tema

> Tamanho: médio. Depende de: etapa 00 aprovada. Próxima: 02.
> Resultado que o Vitor vê: o jogo inteiro troca de cara de uma vez — letras Fredoka/Nunito, cores novas,
> botões e cartões lisos, ícones de controle vetoriais — **sem mudar o lugar de nada**.

## 1. Ler antes

`CLAUDE.md`; `docs/ROADMAP.md` (Estado atual); `docs/plans/interface2/README.md`; `00_VISAO.md` §3;
`01_BIBLIA_VISUAL.md` **inteiro**; `04_REGRAS_E_TESTES.md` §A, §D, §E.
Protótipo de referência: `prototipo/estilo.png` (e o CSS em `prototipo/proto.css`, que tem os mesmos valores).

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Fonte | `game/assets/fonts/main_font.tres` | `FontVariation` com `Jersey10.ttf` e fallback `story_symbols.fnt` (símbolos da história) |
| Tema | `game/assets/theme/main_theme.tres` (516 linhas) | `default_font = main_font`, `default_font_size = 22`; variações: `Button`, `PrimaryButton`, `SecondaryButton`, `GhostButton`, `IconButton`, `CloseButton`, `TabButton`, `ChipButton`, `CardPanel`, `ReadyCardPanel`, `RowPanel`, `ChipPanel`, `PillPanel`, `SheetPanel`, `TopBarPanel`, `TabBarPanel`, `TitleLabel` (30), `SectionLabel` (22), `SmallLabel` (18), `BarLabel`, `NumberLabel`, `BadgeLabel`, `ToastLabel`, `ProgressBar`, `VScrollBar` |
| Cores | `game/scripts/ui/palette.gd` | constantes `PAPER`, `CARD`, `CARD_LINE`, `SUNKEN`, `SHADE`, `DIM`, `INK`, `INK_SOFT`, `INK_ON_DARK`, `PRIMARY`, `PRIMARY_EDGE`, `ACCENT`, `ACCENT_EDGE`, `DANGER`, `GOOD`, `BAD`, `INFO`, `GOLD`, `HUD`, `WORLD`, `OUTLINE`, `FENCE_*`, `PET_SURFACE`... (confira a lista real no arquivo antes de mexer) |
| Ícones de controle | PNG pixel em `game/assets/sprites/ui/icons/` | `ui_close`, `ui_lock`, `ui_check`, `settings`, `ui_recenter`, `timer` — ~30 usos via `UiKit.ui_icon(...)`; o "?" é texto em `UiKit.square_button("?")` (7 usos) |
| Tamanhos forçados | 43 `add_theme_font_size_override` em `scripts/` e `scenes/` | compensavam a fonte pixel |
| Testes que conferem o tema | `ui_style_test.gd:62-89` (cores de cartão/botões, título 30/pequeno 18, alturas 44), `ui_base_test.gd:70-75` (cores distintas, `UiKit.GOOD/BAD`) | mudam nesta etapa |
| Seleção de testes | `tools/test.ps1` | o nível `etapa` soma sozinho as áreas dos arquivos mudados (linhas 38–64) |
| Tour | `game/tests/ui_tour.gd` | blocos `--X-only` (linhas 78–140) |

## 3. Passo a passo

### 3.1 Ferramentas enxutas (faça primeiro: o resto da etapa já usa)
1. `tools/test.ps1`: novo parâmetro `[switch]$Exact`. No bloco `if ($Level -eq 'etapa')`, envolva a
   descoberta de arquivos mudados (o `if ($ChangeList) … elseif ($Since) … else …` e o `foreach ($path in
   $changed)`) em `if (-not $Exact) { … }`. Com `-Exact`, o plano é só `rapido` + `-Tests`. Comentário no
   topo explicando. Teste à mão: `-Level etapa -Exact -Tests ui_style_test -DryRun` lista só
   `import?`, `scripts_check`, `content_test`, `texts_test`, `ui_style_test`.
2. `game/tests/ui_tour.gd`: bloco `--i2-01-only` (vitrine geral, reaproveitada pelas próximas etapas como
   conferência rápida) com estas capturas, nesta ordem: `i2_01_pet` (aba Tiro), `i2_01_tasks` (Missões),
   `i2_01_bag` (Mochila), `i2_01_farm` (mundo Sítio), `i2_01_stove_tray` (bandeja do fogão aberta),
   `i2_01_sheet` (folha de um item: `SheetBuilder.item_detail("carrot")`), `i2_01_settings`
   (Configurações), `i2_01_modal` (`Celebration.show_chapter(2, [])` ou equivalente), `i2_01_popover`
   (`Hud.show_level_popover()`). Use os helpers já existentes (`_sheet`, `_world`, `shot`).
3. Rode o bloco **antes** de mexer no visual: `--i2-01-only --out=i2_01_antes`.

### 3.2 Fontes
1. Copie `docs/plans/interface2/prototipo/fonts/Fredoka.ttf`, `Nunito.ttf`, `OFL_Fredoka.txt`,
   `OFL_Nunito.txt` para `game/assets/fonts/`. Rode `--headless --path game --import`.
   Importação: antialiasing **cinza**, hinting **leve**, `generate_mipmaps = false`, sem MSDF.
2. Crie três `FontVariation` em `game/assets/fonts/`:
   - `font_display.tres` → base `Fredoka.ttf`, peso 600;
   - `font_body.tres` → base `Nunito.ttf`, peso 700;
   - `font_caption.tres` → base `Nunito.ttf`, peso 800.
   Todas com `fallbacks = [story_symbols.fnt]`. O peso vai em `variation_opentype` com a chave do eixo
   `wght` (inteiro `2003265652`; no editor: Variation → OpenType → `wght`). Exemplo:
   ```
   [gd_resource type="FontVariation" load_steps=3 format=3]
   [ext_resource type="FontFile" path="res://assets/fonts/Fredoka.ttf" id="1"]
   [ext_resource type="FontFile" path="res://assets/fonts/story_symbols.fnt" id="2"]
   [resource]
   base_font = ExtResource("1")
   fallbacks = Array[Font]([ExtResource("2")])
   variation_opentype = {2003265652: 600}
   ```
3. `main_font.tres` passa a ter a mesma configuração do `font_body.tres` (Nunito 700). **Não renomeie**
   o arquivo: tema e cenas apontam para ele. `Jersey10.ttf` fica no disco (a etapa 11 decide removê-lo).
4. Confira numa captura 412×915 que os acentos (ã, ç, é, ô) aparecem e que o texto não fica borrado.

### 3.3 Cores (`palette.gd`)
1. Escreva as constantes de `01_BIBLIA_VISUAL.md` §B **exatamente** (com os valores conferidos no
   contraste). Inclua `BASE_GLASS := Color(0.984, 0.945, 0.886, 0.92)` (rodapé claro translúcido).
2. Mantenha os nomes antigos como **apelidos** dos novos, cada um com o comentário
   `# apelido da Interface 2; sai na etapa 11`:
   `PRIMARY = GO`, `PRIMARY_EDGE = GO_EDGE`, `ACCENT = HONEY`, `ACCENT_EDGE = Color("e2961a")` (mel escuro,
   o único valor novo fora da bíblia: serve só ao lábio de botão mel, se algum restar), `DANGER = ALERT`,
   `GOOD = GO_INK`, `BAD = ALERT_INK`, `INFO = SKY`, `GOLD = HONEY`, `CARD_LINE = LINE`, `SHADE = SHADOW`,
   `DIM = SCRIM`, `HUD = CARD`, `INK_ON_DARK = INK`, `PET_SURFACE = BASE`. Constantes que não estão na
   bíblia (`WORLD`, `OUTLINE`, `FENCE_*` etc.) **ficam como estão**.
3. Atenção: `INK_ON_DARK` era texto claro sobre o HUD escuro. Com `HUD = CARD` (branco), o texto do HUD
   precisa ficar escuro — por isso o apelido aponta para `INK`. Confira a pílula de moedas na captura.

### 3.4 Ícones de controle vetoriais
1. Crie `game/assets/sprites/ui/ctl/` com um SVG por ícone. Modelo (troque só o miolo):
   ```xml
   <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
        stroke="#ffffff" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">MIOLO</svg>
   ```
   Miolos (estilo Lucide, licença ISC — registre em `docs/ART_PIPELINE.md`):

   | Arquivo | Miolo |
   |---|---|
   | `x.svg` | `<path d="M18 6 6 18"/><path d="m6 6 12 12"/>` |
   | `back.svg` | `<path d="m15 18-6-6 6-6"/>` |
   | `chev.svg` | `<path d="m9 18 6-6-6-6"/>` |
   | `down.svg` | `<path d="m6 9 6 6 6-6"/>` |
   | `check.svg` | `<path d="M20 6 9 17l-5-5"/>` |
   | `lock.svg` | `<rect width="16" height="11" x="4" y="11" rx="3"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/>` |
   | `plus.svg` | `<path d="M5 12h14"/><path d="M12 5v14"/>` |
   | `minus.svg` | `<path d="M5 12h14"/>` |
   | `clock.svg` | `<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>` |
   | `help.svg` | `<circle cx="12" cy="12" r="9"/><path d="M9.3 9a2.8 2.8 0 0 1 5.4 1c0 1.9-2.7 2.5-2.7 2.5"/><path d="M12 16.5h.01"/>` |
   | `list.svg` | `<path d="M9 6h11"/><path d="M9 12h11"/><path d="M9 18h11"/><path d="M4 6h.01"/><path d="M4 12h.01"/><path d="M4 18h.01"/>` |
   | `arrow.svg` | `<path d="M5 12h14"/><path d="m13 6 6 6-6 6"/>` |
   | `spark.svg` | `<path d="M12 3.5l1.8 4.9 4.9 1.8-4.9 1.8L12 17l-1.8-5-4.9-1.8 4.9-1.8z"/><path d="M19 15.5l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7z"/>` |
   | `gear.svg` | o caminho `gear` de `prototipo/proto.js` + `<circle cx="12" cy="12" r="3"/>` |
   | `recenter.svg` | `<circle cx="12" cy="12" r="3"/><circle cx="12" cy="12" r="8"/><path d="M12 2v2"/><path d="M12 20v2"/><path d="M2 12h2"/><path d="M20 12h2"/>` |
   | `talk.svg` | `<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>` |
   | `info.svg` | `<circle cx="12" cy="12" r="9"/><path d="M12 16v-4"/><path d="M12 8h.01"/>` |

2. Importe e, em cada `.svg.import`, ponha `svg/scale=4.0` (nítido até 96 px); reimporte. Commite os
   `.import`.
3. `UiKit`: `const CTL_DIR := "res://assets/sprites/ui/ctl/"`; `static func ctl_icon(name: String) ->
   Texture2D` (carrega com cache estático); `static func ctl(name: String, px: int = 20, color: Color =
   Palette.INK_SOFT) -> TextureRect` (expand + keep aspect, `self_modulate = color`, filtro **linear**:
   `texture_filter = TEXTURE_FILTER_LINEAR`, porque o resto do jogo usa nearest).
4. Troque os usos de controle: `Select-String -Path game\scripts\*.gd,game\scenes\*\*.gd,game\scenes\*\*\*.gd -Pattern 'ui_icon\("(ui_close|ui_lock|ui_check|settings|ui_recenter|timer)"\)'`
   → `ctl_icon("x" | "lock" | "check" | "gear" | "recenter" | "clock")`, com filtro linear onde a textura
   for desenhada. `UiKit.square_button("?", …)` → `UiKit.icon_button(UiKit.ctl_icon("help"), …)`. Não
   apague os PNGs antigos (capturas de outros testes podem usá-los).
   Cuidado: `ui_lock`/`ui_check` também aparecem em **etiquetas e balões do mundo** (`WorldLabel`,
   `WorldBalloon._draw`): troque também, com filtro linear no nó que desenha.

### 3.5 Tema (`main_theme.tres`)
Reescreva as variações com os tokens (pode editar o `.tres` à mão ou montar por script de ferramenta e
salvar; o resultado tem de ser um `.tres` legível). Valores:

| Variação | O que fica |
|---|---|
| raiz | `default_font = main_font` (Nunito 700), `default_font_size = 15`; `Label/colors/font_color = INK` |
| `TitleLabel` | `font_display`, 24 |
| `StrongLabel` (nova, base `Label`) | `font_display`, 18 |
| `SectionLabel` | `font_caption`, 12, cor `INK_SOFT` (vira o rótulo de seção; maiúsculas ficam no `UiKit.section` da 02) |
| `SmallLabel` | `font_caption`, 12, `INK_SOFT` |
| `NumberLabel` | `font_display`, 18, **sem contorno**, cor `INK` |
| `BadgeLabel` | `font_display`, 12, branco, fundo `ALERT` arredondado (o estilo atual muda só a cor) |
| `BarLabel`, `ToastLabel` | `font_body`, 15 |
| `Button` | `font_display` 16, cor `INK`; `normal` = `SUNKEN` pílula (canto 22), sem borda; `hover` = igual; `pressed` = `SUNKEN` escurecido 6%; `disabled` = alfa 0,5; `content_margin` 16/10 |
| `PrimaryButton` | `font_display` 18 branca; `normal` = `GO` pílula + `border_width_bottom = 3` `GO_EDGE` + sombra verde (cor `GO_EDGE` alfa 0,25, tamanho 6, offset (0, 4)); `pressed` = sem borda de baixo e 2 px mais baixo (`content_margin_top` +2) |
| `SecondaryButton` | igual ao `Button` (é o "calmo"; a etapa 02 cria o apelido `soft`) |
| `GhostButton` | sem fundo, `font_display` 16, cor `INK_SOFT` |
| `IconButton` | disco `CARD` (canto 22), sombra `SHADOW` 8 (0, 4), sem borda |
| `CloseButton` | disco `SUNKEN` 32 (canto 16), sem sombra |
| `TabButton` | sem fundo (o desenho da aba é do `NavTab`) |
| `ChipButton` | `SUNKEN` pílula, `font_display` 15 |
| `CardPanel` | `CARD`, canto 20, sombra `SHADOW` 8 (0, 4), **sem borda**, `content_margin` 12 |
| `ReadyCardPanel` | `GO_SOFT`, canto 20, sem borda, sem sombra |
| `RowPanel` | `CARD`, canto 16, sem sombra |
| `ChipPanel` | `SUNKEN`, canto 14 |
| `PillPanel` | `CARD`, pílula, sombra `SHADOW` |
| `SheetPanel` | `PAPER`, canto 28 só em cima, sombra para cima |
| `TopBarPanel` | vazio (o HUD flutua) |
| `TabBarPanel` | `BASE_GLASS`, canto 24 só em cima, sombra para cima (0, −4) alfa 0,10 |
| `ProgressBar` | trilho `SUNKEN` (canto 4), preenchimento `SKY` |
| `VScrollBar` | fina (4 px), `LINE`, sem fundo |

Depois: **remova** os `add_theme_font_size_override` cujo valor vira um dos 4 tamanhos (ex.: 18 →
nada a fazer se o estilo já é 18; 16 em botões → `SmallButton` na 02). Os demais ficam e são listados no
registro com arquivo:linha (as etapas das telas tratam).

### 3.6 Medida do pacote Web
`tools\export_web.ps1` antes e depois; anote o tamanho de `build/web/*.pck`. Se crescer mais de 600 KB,
crie `tools/font_subset.py` (pyftsubset, latim básico + latim-1 + `–—…•·✓★`) e use as fontes reduzidas.

## 4. Não fazer
- Mudar layout, tamanhos de contêiner, posições ou o fluxo de qualquer tela.
- Apagar PNGs, a Jersey 10 ou constantes da `Palette`.
- Mexer em `WorldBalloon._draw` além de trocar a textura do check/cadeado.

## 5. Armadilhas
- A Nunito é mais larga que a Jersey 10: rótulos longos podem quebrar ou cortar (abas, chips, botões de
  bandeja). **Não conserte o layout aqui**; liste cada caso no registro com o PNG.
- `variation_opentype` com chave errada não dá erro: só não muda o peso. Compare `font_display` e
  `font_body` numa captura (Fredoka é visivelmente mais redonda).
- Textura vetorial com filtro nearest fica serrilhada: use linear nos nós de ícone de controle.
- `ui_style_test` compara cores por nome antigo; com os apelidos ele continua passando, mas o teste de
  tipografia (`TitleLabel == 30`, `SmallLabel == 18`) e o de cor do botão comum (`ACCENT`) mudam: atualize
  para 24/12 e `SUNKEN`.

## 6. Testes

**Teste novo `game/tests/ui2_tokens_test.gd`** (área `ui_kit`), modelo de `04 §E.2` sem instanciar o
`main` (só tema e classes):
1. `ThemeDB`/`load("res://assets/theme/main_theme.tres")`: a fonte padrão tem base `Nunito.ttf`; `TitleLabel`,
   `StrongLabel`, `NumberLabel` usam fonte com base `Fredoka.ttf`; tamanhos `TitleLabel 24`, `StrongLabel 18`,
   `SmallLabel 12`, padrão 15.
2. Nenhuma variação do tema usa fonte com base `Jersey10.ttf`.
3. `Palette.GO == Color("2b9946")`, `Palette.INK == Color("3a2a1f")`, `Palette.PAPER == Color("fff8ee")`,
   `Palette.HONEY == Color("ffb730")`, `Palette.SKY == Color("3e9fe4")`, `Palette.ALERT == Color("e5483c")`;
   apelidos: `Palette.PRIMARY == Palette.GO`, `Palette.GOOD == Palette.GO_INK`.
4. Cada um dos 17 arquivos de `ctl/` carrega como `Texture2D` com largura ≥ 96.
5. `UiKit.ctl("x", 20)` devolve `TextureRect` 20×20 com `texture_filter == TEXTURE_FILTER_LINEAR`.
6. Uma árvore montada com `UiKit.icon_button(UiKit.ctl_icon("help"), …)` não contém `Label` com texto "?".
7. Varre `scripts/ui/*.gd` como texto: nenhuma ocorrência de `ui_icon("ui_close")`, `ui_icon("settings")`,
   `square_button("?"` (garante a troca).
8. `PrimaryButton` normal: `bg_color == Palette.GO`, `border_width_bottom == 3`.

**Atualizar:** `ui_style_test` (tipografia 24/12, botão comum `SUNKEN`, cartão sem borda) e, se precisar,
`ui_base_test` (só nomes de cor). `hud_test` só se a pílula de moedas mudar de altura (não deve).

**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests ui2_tokens_test,ui_style_test,ui_base_test,hud_test,sheet_test` (~1 min).

## 7. Capturas
- `--i2-01-only` antes/depois nas 3 resoluções.
- **Tour completo** no fim (360×780): `--out=i2_01_tour`. Abra e confira tela por tela que nada sumiu nem
  cortou feio; liste as quebras de texto no registro.

## 8. Pronto quando
- [ ] `-Exact` e `--i2-01-only` funcionando e documentados em `CLAUDE.md`/`AGENTS.md` (seção Comandos).
- [ ] Todas as telas do tour com Fredoka/Nunito e as cores novas; nenhum ícone de controle pixel nas telas.
- [ ] `ui2_tokens_test` e a lista fechada verdes.
- [ ] Tamanho do `.pck` antes/depois registrado.
- [ ] Registro com as quebras de layout encontradas (arquivo + PNG) para as próximas etapas.

## 9. Registro (copiar no README do plano)
```
**Etapa 01 (data, executor):** fontes Fredoka/Nunito (pck X → Y KB), Palette nova com apelidos, N ícones
ctl, tema reescrito; -Exact e --i2-01-only. Testes: <lista> PASS em Z s. Quebras de layout anotadas: …
Diferenças do protótipo: … Pendências: …
```
