# 01 — Bíblia visual ("tokens")

> Fonte da verdade para cores, letras, medidas, peças e movimento. O protótipo
> (`prototipo/proto.css`) usa exatamente estes valores; o jogo os recebe na etapa 01 (`Palette`, tema) e 02
> (`UiKit`). Valores em px lógicos da base 360×780 (`stretch=expand`).

## A. Letras

Duas famílias (licença OFL, arquivos e licenças em `prototipo/fonts/`, copiados para `game/assets/fonts/`
na etapa 01). Variáveis: o peso vem de `FontVariation.variation_opentype = {"wght": N}`.

| Estilo (variação do tema) | Fonte | Peso | Tamanho / linha | Uso |
|---|---|---|---|---|
| `TitleLabel` | Fredoka | 600 | 24 / 28 | título da tela ou da folha — **um por tela** |
| `StrongLabel` (novo) · botões · `NumberLabel` | Fredoka | 600 | 18 / 22 | nomes de coisas, números, valores, texto de botão |
| `Label` (corpo) | Nunito | 700 | 15 / 20 | frases (fala de personagem, explicação de uma linha) |
| `SmallLabel` · `OverLabel` (novo, maiúsculas +6% de espaço) | Nunito | 800 | 12 / 16 | legendas, tempo sob ícone, rótulo de seção |

Regras:
- **Só esses quatro tamanhos.** `add_theme_font_size_override` some do código (43 usos hoje); a exceção é
  botão pequeno (16) e chip (15), que viram variações próprias do tema (`SmallButton`, `ChipLabel`).
- Sem contorno no texto sobre papel. Número sobre o mundo (balão, etiqueta) usa contorno 0: fica dentro
  de pílula branca. O único contorno de texto que sobra é o do selo vermelho (borda da cor do fundo).
- Números com algarismos de largura fixa (Fredoka tem `tnum`): moedas que contam não "tremem".
- Maiúsculas só no `OverLabel` (rótulo de seção: HISTÓRIA, PERSONAGENS, HOJE, PRÓXIMO PASSO).
- Mínimo absoluto: 12. Nada menor que isso, nem em selo.

## B. Cores (`Palette`, 60/30/10)

```gdscript
# 60% neutro
const PAPER := Color("fff8ee")      # fundo de tela e de folha
const CARD := Color("ffffff")       # superfície elevada (cartão, pílula, bandeja)
const SUNKEN := Color("f6ede0")     # afundado: trilho, chip neutro, espaço vazio, botão calmo
const LINE := Color("eee2d1")       # divisória fina (1 px)
const BASE := Color("fbf1e2")       # rodapé claro (base das abas e dos cuidados)
const BASE_LINE := Color("efe0cb")
# 30% tinta
const INK := Color("3a2a1f")        # texto principal, contorno de seleção
const INK_SOFT := Color("745e4d")   # secundário, legenda, ícone de controle
const INK_FAINT := Color("bca894")  # só decoração: setinha ›, tracejado de vazio (nunca texto)
# 10% destaque — uma cor, um significado
const GO := Color("2b9946")         # fazer / pronto (botão principal, anel pronto)
const GO_EDGE := Color("1f7a37")    # lábio do botão verde
const GO_INK := Color("23783a")     # texto "tem"/"pronto" sobre GO_SOFT
const GO_SOFT := Color("e7f6ea")    # linha pronta, chip "tem"
const HONEY := Color("ffb730")      # prêmio, moeda, crescimento, "vale um momento" (✦)
const HONEY_SOFT := Color("fff1d3") # chip de prêmio
const HONEY_INK := Color("8c5800")  # texto sobre mel claro
const TAB_ON := Color("ffe2a6")     # almofada da aba ativa
const SKY := Color("3e9fe4")        # tempo, progresso, água
const SKY_SOFT := Color("e2f1fc")
const SKY_INK := Color("22679a")
const ALERT := Color("e5483c")      # pede atenção (selo, pontinho), falta
const ALERT_SOFT := Color("fde6e3")
const ALERT_INK := Color("b0322a")
# Sombra quente (nunca cinza/preta)
const SHADOW := Color(0.43, 0.27, 0.12, 0.13)
const SCRIM := Color(0.23, 0.16, 0.12, 0.38)  # fundo atrás de folha de prêmio/modal
const WORLD := {...}                # mantém as cores dos mundos (só pílula do mundo e etiquetas)
```

Variação "madeira" do rodapé (se o Vitor escolher): `BASE = 4a3426`, `BASE_LINE = 5c4331`,
`TAB_ON = 6e4e38`, rótulo `cdb59b`, rótulo ativo `ffd27a`; os cuidados do Tiro continuam sobre `fbf1e2`.

Nomes antigos (`PRIMARY`, `ACCENT`, `GOOD`, `BAD`, `INFO`, `GOLD`, `HUD`, `DIM`, `CARD_LINE`, `SHADE`)
continuam existindo como **apelidos** dos novos na etapa 01 (para nada quebrar) e são trocados tela a
tela; a etapa 11 remove os que sobrarem.

Contraste medido (WCAG; AA = 4,5:1 para texto de 15, 3:1 para 18 em negrito e ícones): `INK`/`PAPER`
13,0; `INK_SOFT`/`PAPER` 5,8, /`BASE` 5,4, /`SUNKEN` 5,3; branco/`GO` 3,7 → **só texto Fredoka 16–18 de
botão**, nunca 12; `HONEY_INK`/`HONEY_SOFT` 5,4; `SKY_INK`/`SKY_SOFT` 5,2; `GO_INK`/`GO_SOFT` 4,9;
`ALERT_INK`/`ALERT_SOFT` 5,3; branco/`ALERT` 3,9 (só número do selo); madeira: rótulo 5,9, ativo 8,2.
`INK_FAINT` (2,3) não é texto. Os primeiros valores do protótipo (verde `43b25c`, cinza `8a7462`) não
passavam e foram escurecidos em 24/10. A cor **nunca é o único sinal**:
pronto tem ✓ ou botão "Pegar"; falta tem o ícone do que falta; bloqueado tem cadeado.

## C. Medidas

| Coisa | Valor |
|---|---|
| Grade | 4 · 8 · 12 · 16 · 24 · 32 (nada fora disso) |
| Margem lateral de tela/folha | 16 |
| Espaço entre cartões | 12; entre seções 24 (o rótulo de seção fica a 8 do cartão) |
| Dentro do cartão | 12–14 |
| Alvo de toque | **44×44 mínimo**; botão visível pode ser 36 (pequeno) com folga invisível até 44 |
| Botão | grande 44 (`PrimaryButton`/`SoftButton`), pequeno 36 (`SmallButton`), ícone 40 (HUD) / 32 (dentro de folha) |
| Linha de lista | 64 |
| Ícone pixel | 24 (chip), 32 (linha, aba, HUD), 40 (bandeja, cuidado), 64 (destaque). PNG 32 → 32/64 inteiros; 24/40 aceitos (o jogo já escala) |
| Ícone de controle (vetor) | 16 (dentro de chip/selo), 18–20 (botão pequeno), 22 (HUD) |
| HUD | 10 do topo; avatar 58; pílulas 40; segunda linha (próximo passo/necessidades) a 76 do topo, 52 de altura |
| Rodapé | 84 de altura (8 em cima, 14 embaixo para a barra de gestos), cantos de cima 24 |
| Cuidados do Tiro | bloco de 104 apoiado no rodapé, discos de 56 com ícone 40 |

## D. Cantos e sombras

| Peça | Canto | Sombra |
|---|---|---|
| Cartão | 20 | `SHADOW`, tamanho 8, deslocamento (0, 4) |
| Folha inferior / folha de prêmio | 28 (só em cima; a de prêmio 28 nos quatro, com margem 8) | para cima, (0, −6), 12 |
| Bandeja | 24, setinha de 20 girada 45° com canto 4 | (0, 10), 16, alfa 0,25 |
| Pílula / chip / botão | metade da altura | pílula do HUD: `SHADOW`; chip: nenhuma |
| Botão verde | pílula | **lábio** de 3 px `GO_EDGE` embaixo + sombra verde (0, 6) alfa 0,25 — o único "degrau" que sobra, o toque aconchegante |
| Afundado (trilho, tile, vazio) | 16 | nenhuma |
| Rodapé | 24 em cima | (0, −4), 12, alfa 0,10 |

Godot: tudo `StyleBoxFlat` (`corner_radius_*`, `shadow_color/size/offset`, `border_width_bottom` para o
lábio). Sem desfoque de tela (renderer Compatibility; Web single-thread).

## E. Ícones

**Pixel (ficam):** itens, comidas, necessidades, pilares, estações, lugares, abas, retratos, moeda, Tiro.
Sempre dentro de algo liso: disco, tile afundado, chip ou pílula.

**Vetor (novos, etapa 01):** `game/assets/sprites/ui/ctl/<nome>.svg`, traço 2,4 arredondado no estilo
Lucide (licença ISC; os caminhos estão em `prototipo/proto.js → ICONS`), importados com escala 2 e
pintados por `modulate`. Lista: `x`, `back`, `chev` (›), `down`, `check`, `lock`, `plus`, `minus`, `clock`,
`help`, `list` (Ver tudo), `arrow` (Ir), `spark` (✦ vale um momento), `gear`, `recenter`, `sort`, `info`.
Substituem `ui_close`, `ui_lock`, `ui_check`, `settings`, `ui_recenter`, `timer` e o "?" desenhado com
texto. Os PNGs antigos ficam no disco até a etapa 11 (podem estar em capturas de teste).

## F. Peças (implementadas na etapa 02, no `UiKit`)

| Peça | Aparência | Estados |
|---|---|---|
| `UiKit.primary(texto, cb)` | pílula `GO` 44, Fredoka 18 branca, lábio | aperto (0,96 + lábio some), desabilitado = vira `lock_hint` |
| `UiKit.soft(texto, cb, small)` (novo; `secondary` vira apelido) | pílula `SUNKEN`, texto `INK` | aperto |
| `UiKit.small_go(texto, cb)` | pílula `GO` 36, Fredoka 16 | — (Pegar nas linhas) |
| `UiKit.ghost(texto, cb)` | só texto `INK_SOFT` | — |
| `UiKit.icon_button(ctl, cb, 40/32)` | disco `CARD` com sombra (HUD) ou `SUNKEN` sem sombra (folha) com ícone vetor `INK_SOFT` | — |
| `UiKit.card(parent, ready)` | `CARD` 20 + sombra; `ready` = fundo `GO_SOFT` (não borda) | — |
| `UiKit.list_card()` + `UiKit.list_row(...)` | linhas de 64 dentro de um cartão, divisória `LINE`; linha pronta ganha `GO_SOFT` e sobe | pronto / normal / bloqueado (0,55) |
| `UiKit.chip(tex, texto, tipo)` | 28 de altura; tipos: `neutral` (SUNKEN), `prize` (mel), `time` (azul, ícone relógio vetor), `have` (verde + ✓), `missing` (vermelho, tocável → Como fazer) | — |
| `UiKit.badge(n)` / `UiKit.dot()` | vermelho, borda da cor do fundo; número Fredoka 12 | — |
| `UiKit.spark()` | disco mel 22 com ✦ branco = "vale um momento" | — |
| `UiKit.segmented(...)` | trilho `SUNKEN`, opção ativa = pílula `CARD` com sombra (não verde) | — |
| `UiKit.ring(tex, progresso, cor)` (`RingProgress`) | 4 px; trilho `SUNKEN`; cores: `SKY` andando, `GO` pronto, `ALERT` pedindo, `HONEY` crescimento | — |
| `UiKit.steps(total, atual)` | tracinhos 12×6: feito `GO`, atual `HONEY`, futuro `SUNKEN` | — |
| `UiKit.stepper(valor, min, max, cb)` | `− ×N +` em trilho `SUNKEN`, botões disco `CARD` | limite = botão apagado |
| `UiKit.tile(tex, legenda, estado)` | afundado 16, ícone 36–40, legenda 12 | selecionado = fundo `CARD` + contorno 2,5 `INK`; falta = ícone 45% + mini-disco vermelho com o ingrediente; bloqueado = cadeado vetor |
| `UiKit.slot(...)` (`SlotDot`) | 52: andando = anel azul + tempo embaixo; pronto = anel verde + ✓; vazio = tracejado `INK_FAINT` com +; trancado = afundado com cadeado + preço | — |
| `SpeechBubble` | `CARD` 16 com rabinho para o retrato; dentro de cartão usa `PAPER` sem sombra | — |
| `UiKit.lock_hint(motivo)` | cadeado vetor + ícone do que falta + uma linha | tocável → Como fazer |
| `UiKit.section(texto, direita)` | `OverLabel` + opcional (chip de tempo, botão) | — |
| `Sheet` | `PAPER`, canto 28, alça 40×5 `LINE`, título `TitleLabel`, X vetor 32 afundado | — |
| `ModalCard` | ver 02 §4 (tamanhos de prêmio) | — |

Regra de ouro (já testada por `ui_style_test`): **no máximo um `PrimaryButton` por painel**. Linhas com
"Pegar" usam `small_go` (variação `SmallGoButton`, que o teste conta à parte e limita a um por linha).

## G. Movimento (`Motion`, tempos novos)

| O quê | Tempo | Curva |
|---|---|---|
| Aperto de botão | 0,08 desce (0,96, lábio some) / 0,14 volta | `BACK` |
| Aparecer (pop) | 0,20 | `BACK`/`OUT` |
| Folha sobe / desce | 0,26 / 0,18 | `CUBIC`/`OUT` |
| Bandeja abre | 0,18 escala 0,92→1 a partir da setinha | `BACK`/`OUT` |
| Ícone que voa até o HUD/aba | 0,45 em arco (curva de Bézier, ponto de controle 80 px acima) | `CUBIC`/`IN` |
| Número que conta | 0,5 | linear |
| Linha pega some | 0,16 encolhe + 0,20 lista fecha o vão | `CUBIC` |
| Selo de aba quando chega coisa | pulinho 0,25 | `BACK` |

`Motion.reduced` zera tudo (já existe). Nenhuma animação bloqueia toque. Vibração (`Haptics`) igual à de hoje.

## H. Rodapé — a decisão do Vitor

Primeira versão (reprovada): barra branca solta a 12 px da borda, aba ativa como cápsula com nome e as
outras só ícone — "ícones flutuando". Nova regra: **o rodapé é uma base presa à borda**, cantos de cima 24,
quatro abas iguais com ícone 32 numa almofada 60×38 e o **nome embaixo de todas**; a ativa ganha a
almofada `TAB_ON` e o nome em `INK`. Na tela do Tiro, os cuidados **apoiam** na base (mesma cor, um bloco
só, divisória de 1 px). Duas versões em `prancha_rodape.png`: **clara** e **madeira**. **Decisão do Vitor (24/10/2026): clara**, um pouco
transparente (`BASE` a 92% sobre o mundo: `Color(0.984, 0.945, 0.886, 0.92)`; opaca nas telas de papel).
