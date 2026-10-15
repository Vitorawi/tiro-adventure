# 01 — Regras do executor, guia de estilo, movimento, textos e arte

> Vale para **todas** as etapas. Leia inteiro antes da primeira etapa e volte aqui sempre que for
> criar uma peça de interface, escolher uma cor, escrever um texto ou gerar arte.

---

## A. Regras do executor

1. **Uma etapa por vez.** Não adiante etapas futuras. Se uma tela ainda não foi refeita, deixe-a como
   está (ela vai ganhar o tema novo automaticamente pela Etapa 01).
2. **Só interface.** Não mude tempos, preços, recompensas, requisitos, missões nem o save.
   `SAVE_VERSION` continua 12. Se precisar lembrar uma preferência de interface (ex.: última semente),
   use `GameState.progress.seen["ui:<chave>"]` ou um campo novo **opcional** com valor padrão no
   `from_dict` — nunca um reset.
3. Siga o `CLAUDE.md`: ações pelo `GameState` (devolvem `""` ou o motivo; `*_error()` igual para
   desabilitar); estado só no `GameState`; sinais globais só em `Events`; GDScript tipado; cena + script
   com o mesmo nome; comentários em português; toque chega como `InputEventMouse*`.
4. **Peças novas de interface** vão para `game/scripts/ui/` (classe com `class_name`) e são **reusadas**:
   nada de montar o mesmo botão/cartão à mão em duas telas. Se uma tela precisa de algo que já existe
   em `UiKit`, use o `UiKit`; se não existe, crie no `UiKit` (ou numa classe própria) e use de lá.
5. **Cores, tamanhos e tempos só das constantes** (`Palette`, `Motion`, seção B/C). Nada de
   `Color("f7e9c9")` solto no código novo. Ao mexer numa tela antiga, troque as cores soltas dela.
6. **Nomes de nós usados nos testes** precisam continuar existindo (ou o teste é atualizado na mesma
   etapa, explicando no ROADMAP). Lista atual dos mais usados: `WorldsScreen`, `Sheet`, `ContentHolder`,
   `Title`, `PetScreen`, `WishBubble`, `MoodLabel`, `BagTab`, `WishesTab`, `SettingsButton`, `DevButton`,
   `Toast`, `PlacesButton`, `WorldCard_<mundo>`, `World_<mundo>`, `Pointer`, `PurchaseMarker`,
   `LockedSlot_<melhoria>`, `Material_<item>`, `GatherItem_<local>_<i>`, `NatureLevel_*`, `NatureSkill_*`,
   `NextTool_*`, `Region_<id>`, `Celebration`, `CelebrationScroll`, `WalkResult*`, `StartWalk_*`,
   `CollectWalk`, `CancelWalk`, `WalkSlot`, `Equip_<roupa>`, `ManualButton`, `ManualPanel`, `TrickTraining`,
   `NpcIntroduction`, `NpcPortrait`, `LineCard_<npc>`, `StoryCard`, `Save_<n>`, `NewSave`.
   Antes de renomear/remover um nó: `Select-String -Path game\tests\*.gd -Pattern '<Nome>'`.
7. **Testes:** rode todos (`powershell -ExecutionPolicy Bypass -File tools/test_all.ps1`). Todo teste novo
   entra no `test_all.ps1` e imprime `<NOME> TEST: PASS`.
8. **Capturas (obrigatório em toda etapa):**
   - antes de mexer: `& $env:GODOT_BIN --path game --resolution 360x780 -s res://tests/ui_tour.gd -- --out=etapaNN_antes`
   - no fim: o mesmo com `--out=etapaNN_depois`;
   - **abra** os PNGs e compare tela por tela. Rode também com `--resolution 390x844` e `--resolution 412x915`
     no fim (celulares maiores) e confira que nada corta.
   - O tour é criado na Etapa 00 (`game/tests/ui_tour.gd`); cada etapa que cria uma tela nova
     **acrescenta** as capturas dela ao tour.
9. **Teste de toque real** nas etapas com arrastar (04, 07, 08, 09): exporte, rode `serve_local.ps1` e
   `touch_test.ps1` com um roteiro `build/touch_steps_etapaNN.json` (ver exemplos nas etapas).
10. **Ao terminar a etapa:**
    - `docs/ROADMAP.md → Estado atual`: bloco novo no topo (o que foi feito, decisões, pendências, próxima etapa);
    - se criou peça/arquivo/pasta: atualizar `CLAUDE.md` **e** `AGENTS.md` (mesmo conteúdo; linha na tabela
      "Onde trabalhar" e, se for o caso, na "Estrutura");
    - arte gerada registrada em `docs/ART_PIPELINE.md`;
    - marcar a etapa no `docs/plans/interface/README.md`;
    - commit local `feat(ui): <resumo em português>` com a linha de coautoria pedida pelo ambiente. **Sem push.**
11. **Windows / acentos:** nunca `Set-Content`/`Out-File` sem `-Encoding utf8`; prefira as ferramentas de edição.
12. **Se travar** (algo não fica bom depois de 3 tentativas): entregue o resto, deixe o comportamento
    antigo naquele ponto, anote no ROADMAP e siga.

---

## B. Guia de estilo

### B.1 Paleta (`game/scripts/ui/palette.gd`, criada na Etapa 00)
```gdscript
class_name Palette
extends RefCounted
## Cores da interface. Use sempre estas constantes (nada de Color("...") solto).

# Superfícies
const PAPER := Color("fff6e3")        # fundo dos painéis
const CARD := Color("f8ead0")         # cartão (informação agrupada)
const CARD_LINE := Color("e3cba3")    # borda fina do cartão (2 px)
const SUNKEN := Color("eedcb8")       # chip/pílula dentro de cartão, trilho de barra
const SHADE := Color(0.17, 0.11, 0.07, 0.18)  # sombra suave
const DIM := Color(0.12, 0.08, 0.05, 0.45)    # fundo escurecido atrás de painel/modal
# Texto
const INK := Color("3d2618")          # texto principal
const INK_SOFT := Color("7a5c44")     # texto secundário
const INK_ON_DARK := Color("fff1d6")  # texto sobre HUD escuro
# Ações
const PRIMARY := Color("6cc24a")      # botão principal (verde folha)
const PRIMARY_EDGE := Color("3f8a2b") # degrau do botão principal
const ACCENT := Color("f6b85e")       # mel: botão secundário forte, destaque
const ACCENT_EDGE := Color("c9822f")
const DANGER := Color("e0574b")       # falta / fechar
const GOOD := Color("3f8a2b")         # tem / ganho (texto)
const BAD := Color("c2412f")          # falta (texto)
const INFO := Color("4fa3d9")         # água, tempo, progresso
const GOLD := Color("ffd23f")         # moeda, estrela, XP
const HUD := Color(0.17, 0.11, 0.07, 0.78)  # pílulas do HUD sobre o mundo
# Cor de cada mundo (cabeçalho, pílula do mundo, seletor)
const WORLD := {
	"house": Color("c98b5a"), "farm": Color("7db84a"), "park": Color("e9b93a"),
	"village": Color("d9694a"), "nature": Color("4fa3d9"),
}
```
`UiKit.GOOD/BAD` passam a apontar para `Palette.GOOD/BAD` (manter os nomes antigos para não quebrar).

### B.2 Medidas
| Coisa | Valor |
|-------|-------|
| Grade de espaçamento | múltiplos de 4: 4, 8, 12, 16, 24 |
| Margem lateral de painel | 16 |
| Canto | botão 12 · cartão 14 · painel 22 (só em cima) · pílula = metade da altura |
| Borda | cartão 2 px `CARD_LINE`; botão 2 px na cor da borda + **degrau 5 px** embaixo; chip sem borda |
| Sombra | cartão: `shadow_size 3`, `shadow_offset (0, 2)`, cor `SHADE`; HUD: igual |
| Alvo de toque | mínimo 48×48 (ícone-botão 44 visível + 4 de folga) |
| Ícones | 32 (chip, linha), 48 (bandeja, linha grande), 64 (destaque); sempre escala inteira do PNG 32 px, exceto o anel de progresso |
| Botão principal | altura 52, largura cheia ou ≥ 140 |
| Linha de lista | altura 64–72 |

### B.3 Tipografia (Jersey 10)
| Variação | Tamanho | Uso |
|----------|---------|-----|
| `TitleLabel` | 30 | título de painel/tela (um por tela) |
| `SectionLabel` | 22, cor `INK_SOFT` | seção dentro do painel |
| `Label` (corpo) | 22 | texto normal, nome em linha |
| `SmallLabel` | 18, cor `INK_SOFT` | detalhe, instrução de uma linha |
| `NumberLabel` (nova) | 22, contorno 4 px `INK`, cor `INK_ON_DARK` | números no HUD e sobre o mundo |
| `BadgeLabel` (nova) | 16, branco, fundo `DANGER` redondo | selos de aba e balões |
Mínimo absoluto: 16 só em selos; texto legível nunca abaixo de 18.

### B.4 Componentes (todas no `UiKit`, criadas/refeitas na Etapa 01, salvo indicação)
| Peça | Função | Aparência |
|------|--------|-----------|
| `UiKit.primary(text, cb)` | o **único** botão principal da tela | verde `PRIMARY`, degrau `PRIMARY_EDGE`, texto branco com contorno 2 |
| `UiKit.secondary(text, cb)` | ação alternativa | `ACCENT` com degrau `ACCENT_EDGE`, texto `INK` |
| `UiKit.ghost(text, cb)` | ação fraca ("Ver tudo", "Cancelar") | sem fundo, texto `INK_SOFT` sublinhado por 2 px |
| `UiKit.icon_button(tex, cb, px=44)` | "?", fechar, trocar, lista | círculo `CARD` com borda 2 px, ícone 32 |
| `UiKit.card(parent)` | já existe; muda o estilo | `CARD`, borda 2 `CARD_LINE`, sombra, **sem degrau** |
| `UiKit.chip(...)` | já existe; muda o estilo | pílula `SUNKEN`, sem borda, ícone 32 + número |
| `UiKit.pill(tex, text)` (nova) | HUD sobre o mundo | `HUD` translúcido, número `NumberLabel` |
| `UiKit.lock_hint(text, cb_help)` (nova) | substitui botão cinza bloqueado | ícone cadeado 32 + texto `SmallLabel` + "?" opcional |
| `UiKit.list_row(icon, title, chips, action)` (Etapa 02) | linha baixa de lista | ícone 48 · título + chips · ação à direita (botão pequeno 44 ou nada) |
| `UiKit.slot_dot(state, tex, progress)` (Etapa 02) | espaço de produção compacto | círculo 56: vazio tracejado, produzindo com `RingProgress`, pronto verde pulando, "+" com preço |
| `RingProgress` (Etapa 00) | anel de progresso com ícone no meio | `draw_arc` 4 px, trilho `SUNKEN`, cor `INFO` (pronto = `PRIMARY`) |
| `ActionTray` (Etapa 07) | bandeja perto do dedo | ver ETAPA_07 |

Regra de ouro: **um `primary` por tela/painel/bandeja.** Listas repetidas usam `secondary` pequeno
(altura 44) ou o toque na linha inteira.

### B.5 Estados
- **Pronto/disponível:** borda do cartão `PRIMARY` + leve pulsar (escala 1,00↔1,03, 0,9 s).
- **Falta algo:** número em `BAD`; chip tocável que abre "Como fazer" (já existe em `ProgressionUi.item_chip`).
- **Bloqueado:** `lock_hint` (cadeado + motivo curto); o item fica com `modulate.a = 0.55`.
- **Novo:** selo `BadgeLabel` "Novo" no canto do ícone por uma sessão (já há `GameState.new_unlocks`).

---

## C. Movimento (`game/scripts/ui/motion.gd`, criada na Etapa 00)
Todas as animações por `Tween` (sem shaders, sem `AnimationPlayer` novo). Tempos fixos:

| Função | O que faz | Tempo / curva |
|--------|-----------|---------------|
| `Motion.press(button)` | conecta `button_down/up`: escala 0,94 → 1,0 | 0,08 / 0,14 s, `TRANS_BACK` |
| `Motion.pop_in(node)` | aparece de 0,6 → 1,0 com alfa 0 → 1 | 0,22 s, `TRANS_BACK` `EASE_OUT` |
| `Motion.pop_out(node, free)` | 1,0 → 0,8 e alfa → 0 | 0,14 s |
| `Motion.slide_up(node, from_y)` | sobe de baixo | 0,26 s, `TRANS_CUBIC` `EASE_OUT` |
| `Motion.bounce(node)` | pulinho (y −6 e volta) | 0,25 s |
| `Motion.pulse(node)` | pulsar contínuo 1,00↔1,04 (devolve o Tween para parar) | 0,9 s em loop |
| `Motion.count_up(label, from, to, fmt)` | número que conta | 0,5 s |
| `Motion.shake(node)` | "não dá" (x ±4, 3 vezes) | 0,24 s |
| `Motion.float_text(parent, pos, text, color)` | "+3" que sobe e some | 0,7 s |

Regras: pivô no centro (`pivot_offset = size / 2` depois do layout); nunca animar `size` de container
(anima `scale`/`position`/`modulate`); animação nunca bloqueia toque; respeitar uma flag
`Motion.reduced` (lida de `settings.json`, desligada por padrão) que zera os tempos.

---

## D. Textos

### D.1 Voz
Curta, calorosa, falando com o jogador, no presente. Sem "·" juntando frases, sem "Conclua:", sem
abreviações ("Nv", "Máx."), sem "x0", sem número de capítulo para o jogador.

### D.2 Glossário (um verbo por ação)
| Situação | Usar | Não usar |
|----------|------|----------|
| Pegar planta madura | **Colher** | Recolher, Coletar |
| Pegar o que ficou pronto (fogão, animais, natureza, passeio, presente) | **Pegar** | Recolher, Coletar, Receber |
| Pegar todos de uma vez | **Pegar tudo (3)** | Coletar prontos (3) |
| Fazer no fogão/liquidificador | **Cozinhar** | Produzir, Preparar |
| Fazer na bancada/moinho/queijaria/costura | **Fazer** | Produzir |
| Começar uma coleta na Natureza | **Buscar** | Coletar |
| Prêmio de missão | **Pegar prêmio** | Receber |
| Comprar construção | **Construir** (moedas) / **Comprar** (animais, roupas) | |
| Ampliar espaço | **Ampliar** | Expandir (só para áreas do sítio: "Abrir área") |
| Ir até o lugar | **Ir** | Ver, Ir até lá |
| Explicação | botão **?** | Ajuda, Como fazer (como título do painel pode) |
| Fechado | cadeado + "Depois de [ícone] <passo>" | "Fechado · Conclua:" |
| Fila | "Na fila" | — |
| Pronto | "Pronto!" | "Concluído" |

### D.3 Números
`3/6` quando é meta; `×3` quando é quantidade de um item; `+20` quando é ganho; tempo pelo `TimeText`
("1 min", "2:30", "1 h 05"). Nunca mostrar `×0`: mostrar o item apagado com "Você não tem".

---

## E. Arte (PixelLab)

O fluxo é o mesmo do plano anterior: **`docs/plans/comeco/01_REGRAS_E_ARTE.md`, seção B.1** (upload de
referência, jobs assíncronos, originais em `build/art_sources/interface_etapaNN/`, prancha com
`New-ContactSheet`, recorte com `Invoke-TrimSprite`, `.import` commitado, registro no `ART_PIPELINE.md`,
tags `tiro-adventure`, `interface`, `ativo`). Receitas novas deste plano:

**Ícone de estação/lugar 32×32** — `mcp__pixellab__create_image_pixen`
```
width: 32, height: 32, no_background: true,
outline: "single color black outline", detail: "medium detail",
description: "game UI icon: <OBJETO>, front 3/4 view, cute, bold outline, <CORES>, centered, no text"
```
Gere com referência de estilo de um ícone existente quando a ferramenta aceitar (`item_carrot_snack.png`,
`tab_house.png`). Até 3 tentativas. Destino `game/assets/sprites/ui/icons/station_<id>.png`.

**Fundo de céu/paisagem do mundo (backdrop) 360×640** — `mcp__pixellab__create_image_pro`
```
width: 360, height: 640, no_background: false,
reference_images: [{"url": "upload:<fundo do mundo, ex. areas/farm/farm_animals.png>",
  "usage": "same palette, pixel density, outline and lighting"}],
description: "<CENA DE FUNDO>, soft vertical background for a mobile farming game, no buildings in the
  middle, no characters, no text, gentle gradient, pixel art"
```
O backdrop fica **atrás** da maquete e precisa ter a parte de baixo na mesma cor do chão em volta da
maquete (grama, piso, água), para a maquete "assentar" nele. Gere 2–3 e escolha. Destino
`game/assets/sprites/areas/<mundo>/backdrop.png`. Se nenhum servir, use o plano B da Etapa 04
(degradê desenhado por código + faixa de grama repetível).

**Nuvem 64×24 / 96×32** — `mcp__pixellab__create_image_pixen`, `no_background: true`,
"small fluffy pixel art cloud, soft white with light blue shade, no outline" → `areas/common/cloud_1.png`, `cloud_2.png`.

**Retrato do Tiro para o HUD 48×48** — recorte da cabeça de um quadro existente do `PetAnimator`
(`assets/sprites/characters/tiro_pet/...`), sem gerar arte: `Invoke-TrimSprite` + redimensionar para
48 px por vizinho mais próximo. Destino `ui/icons/hud_tiro.png`.

---

## F. Tour de capturas (`game/tests/ui_tour.gd`, criado na Etapa 00)
Roteiro que monta um jogo novo e um jogo avançado (sem `SaveManager`, como `walks_shots.gd`) e salva
PNGs numerados em `build/screenshots/<out>/`. Argumento `-- --out=<pasta>`. Ele **não** é teste (não
entra no `test_all.ps1`); é a régua visual de todas as etapas. Base: `docs/plans/interface/ui_tour_rascunho.gd` (rascunho de
15/10/2026 que gerou o diagnóstico) — copiar para `game/tests/ui_tour.gd` e completar.
