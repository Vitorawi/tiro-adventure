# 03 — Interface e arte

Tudo no padrão **madeira ilustrada** (ver CLAUDE.md, "Madeira ilustrada"). Uma ação verde por tela, ícone +
número em vez de frase, alvos ≥ 44 px, celular em pé.

## 1. Lagoa no mapa do Sítio

- Toque na água → `Places.run("fishing")`: câmera centra na lagoa (zoom 0,6), o Tiro anda até `fishing_spot`
  e senta olhando a água. Se ele estiver dormindo/no passeio, aviso de madeira e nada mais.
- **Bolha** = `WorldBalloon` não; é um efeito no próprio mapa (`FishingBubbles`, círculos que sobem) e um
  pontinho mel no ícone do Sítio no seletor de mundos (`Places.world_summary → fishing`).
- Antes da vara: tocar na lagoa = balão curto da vovó "Um dia eu te ensino a pescar aqui!".
- Lagoa **não** vira lugar visível (o Sítio já tem 4); entra na lista "Lugares" como `fishing` escondido
  com o ícone da vara, só depois da vara de bambu.

## 2. Painel de arremesso (`FishingPanel`, bandeja de madeira presa embaixo)

Mesma pele das bandejas de estação (`StationWood`):
- cabeçalho com o ícone da vara, nome e nível de pesca (`FishingLevel`, barrinha);
- linha **Vara** (só aparece com 2+ varas): quadradinhos `Rod_<id>`;
- linha **Isca**: quadradinhos `Bait_<id>` com "×N"; a escolhida em amarelo; isca que falta = cadeado
  e toque abre o "Como fazer" (vovó/Feirante);
- embaixo do quadradinho da isca, os **3 peixes do grupo** como silhuetas/ícones com o recorde
  ("28 cm") — quem não foi pego ainda aparece como sombra com "?";
- botão verde grande `CastButton` "Arremessar" (segurar = força; ver §3); sem isca = `StepCardUi.locked_button`
  "Sem minhoca" + "?".

## 3. Arremesso, espera e mordida (por cima do mapa)

- Segurando `CastButton`: barrinha de força horizontal em madeira acima dele, com três faixas
  Perto/Meio/Longe e o ponteiro indo e voltando; soltar = a linha voa num arco (`Motion.fly_arc`) até a água.
- Boia (`Bobber`) no mapa, balançando; um anel discreto mostra a espera só se ela passar de 6 s.
- Mordida: boia afunda 2×, respingo, "!" grande sobre ela, `Haptics.success`, o Tiro late. Toque em
  qualquer lugar da tela fisga. Toque antes da hora: a linha volta ("Ainda não mordeu!"), sem gastar.

## 4. Minigame (`FishingGame`, tela por cima do mapa, z abaixo do HUD)

```
 ┌──────────────── HUD ────────────────┐
 │                                      │
 │   [lagoa escurecida atrás]   ┌──┐ ┌┐ │
 │                              │  │ ││ │  ← pista em moldura de madeira vertical (à direita,
 │   Tiro na margem torcendo    │▓▓│ ││ │     perto do polegar) + rede/medidor ao lado
 │                              │🐟│ ││ │
 │   "Segure para subir"        │▓▓│ │█│ │
 │   (só nas 3 primeiras)       │  │ │█│ │
 │                              └──┘ └┘ │
 │            [ ⏸ ]                     │
 └──────────────── abas ───────────────┘
```

- Pista: altura = espaço entre `Hud.HEIGHT + 16` e o topo das abas − 16, largura 72 px; moldura de madeira
  (NinePatch), água azul por dentro com ondinhas paradas.
- Barra do jogador: verde translúcida com borda clara; o peixe: ícone lateral do peixe (§6) com leve
  rabeada; baú (vara 2+): ícone com a sua própria rodinha de progresso.
- Rede (medidor): coluna ao lado, enche de baixo para cima, verde → amarelo → vermelho conforme cai;
  treme de leve quando o peixe está fora.
- `PauseButton` (⏸) pausa e oferece "Continuar" e "Soltar o peixe" (= escapou, a isca já foi).
- Vibração: tic leve a cada vez que o peixe sai da barra (`Haptics.tap`, no máximo 1 por 0,5 s).
- "Menos animação": sem ondinhas, sem tremor e sem respingo; física igual.
- Todas as medidas da tela vêm do tamanho real da tela (`_layout` em `resized`), nunca de constantes.

## 5. Resultado

- **Pegou** (`FishCaught`, `RewardSheet` de madeira, sem fila modal pesada): placa com o nome do peixe,
  ícone grande no pratinho, régua de madeira com a marca do tamanho (`FishSize`, "32,5 cm"), selo da classe
  (`FishClass`), "Novo recorde!" (`FishRecord`) quando for, chips do que ganhou (peixes ×N, XP de pesca,
  baú). Verde `FishAgain` "Pescar de novo" + amarelo `FishLeave` "Sair". Gigante usa o `ModalCard` com
  confete.
- **Escapou**: aviso de madeira embaixo (`Notice`) "Escapou! A minhoca foi junto." e volta ao painel.
- Primeira vez de cada espécie: o cartão diz "Primeira vez!" e o Tiro ganha o momento de Coragem
  (`MomentNotice` normal).

## 6. Arte a gerar (etapa 03)

**Toda arte nova é pixel art feita no MCP PixelLab** (decisão do Vitor, 11/11/2026; nada de image_gen,
Scenario ou ilustração por enquanto). Detalhes, tamanhos, ferramentas e prompts em `etapas/ETAPA_03_ARTE.md`.

| Peça | Quantas | Estilo | Onde |
|---|---|---|---|
| Ícones dos peixes `item_fish_*.png` | 9 | PixelLab, 32 px (padrão dos itens) | `ui/icons/` |
| Peixes do minigame `fish_*.png` | 9 | PixelLab, lateral, 48–64 px, escala inteira | `ui/fishing/` |
| Ícones das iscas `item_bait_*.png` | 3 | PixelLab, 32 px | `ui/icons/` |
| Varas `rod_*.png` | 3 | PixelLab, 32 px (ícone) + 64 px (painel) | `ui/icons/`, `ui/fishing/` |
| Pratos (ícones) | 4 | PixelLab, 32 px; a bandeja do fogão mostra o ícone pixel no tamanho original | `ui/icons/` |
| Boia, respingo, bolha | 3 + quadros | PixelLab, no estilo do mapa do Sítio | `sprites/fx/` |
| Baú da lagoa | 1 | PixelLab, 48 px | `ui/fishing/` |
| Pista, barra, rede do minigame | 3 | **não é arte nova**: montadas das peças de madeira que já existem, NinePatch 3× | `ui/home/fishing_*.png` via `tools/fishing_art.gd` |

O Tiro na margem usa clipes que já existem (`sit`, `bark`, `happy_jump`); arte nova do Tiro **não** entra.
Pranchas para o Vitor: `build/art/pesca/` (todos os peixes lado a lado com o tamanho real em escala).

## 7. Capturas (FAIL nas medidas)

`tests/fishing_shots.gd` → `build/screenshots/fishing/`, três resoluções: lagoa sem vara, lagoa com bolha,
painel com 1 e 3 varas, painel sem isca, força, espera, mordida, minigame no começo/meio/baú, pausa,
resultado Pequeno/Gigante/recorde, escapou, cada passo do tutorial, Coleção → Peixes.
