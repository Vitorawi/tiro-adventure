# 06 — Interface e arte (autoritativo)

Base: regras do plano Interface (`docs/plans/interface/01_REGRAS_E_ESTILO.md`), `UiKit`, `Palette`, `Motion`,
`ModalCard`, `Sheet`. Base de tela 360×780. Nomes de nós abaixo são **contrato dos testes**.

## A. Mapa das telas

| Onde | O que entra | Etapa |
|---|---|---|
| Tela do Tiro | selo de crescimento `GrowthBadge` ao lado do `BondChip`; ícone "Nova foto" no caderninho | 06, 13 |
| Painel Crescimento | `GrowthUi.panel()` (Sheet alto): antes → silhueta, requisitos, pilares, botão Crescer, caderneta | 06 |
| HUD | avatar = retrato da fase; anel = progresso do crescimento; número = fase | 07 |
| Cerimônia | `GrowthCeremony` na fila modal (`main.gd._queue_modal`) + cartão antes/depois (`ModalCard`) | 08 |
| Caderninho | abas: Manual · **Crescimento** · **Álbum** · Coleção · Truques | 03, 13 |
| Bandeja de cuidados | 5 cuidados iguais: Comida, Banho, **Escovar**, Brincar, Dormir; opção "Com xampu" | 09, 12 |
| Guia de comida | selo de pilar nas adequadas, ♥ na favorita, "Nova!" nas não provadas | 09, 12 |
| Missões | passo `growth` com miniatura da silhueta e "Ir" (abre o painel) | 11 |
| Boas-vindas | linhas `Line_photo` (N fotos novas) e `Line_growth` (ele pode crescer!) | 13, 08 |
| Casa e cantinho | régua, prateleira, parede de fotos, cestos, caminhas, enfeites | 14 |

## B. Painel Crescimento (layout autoritativo)

```
 ● ● ◉ ○ ○ ○                         LifeDots (6 bolinhas: Recém + 5 fases)
 [Tiro agora]   →→✦→→   [silhueta ?]  CurrentDog (PetAnimator 120) · Arrow · NextSilhouette
  Filhotinho                Dentinhos   nomes; idade do atual
  3 meses · 0,9 kg          Cap. 3     
  Próxima fase: 🦷 truques · 🎒 …        NextUnlocks (ícones do que a fase libera; nunca a aparência)
 ┌────────────┬────────────┐
 │🔑 Argolinha │🍲 Cenoura  │             GrowthReq_<id> (2×2; 64 px de altura mínima)
 │  0/1   Dar │ gelada 2/3 │             "Dar" entrega item-chave; "Ir" leva à origem
 ├────────────┼────────────┤
 │📊 Pilares   │            │
 └────────────┴────────────┘
 🦴 2/2  ✨ 1/2  💡 0/2  ⭐ 2/2          PillarRing_<id> (nível/teto; "+N guardado")
        [ 🐾 Crescer! ]                 GrowButton (PrimaryButton) — ou lock_hint com o motivo
 ── Caderneta ──────────────            GrowthCard_<fase> (rolagem, ver C)
```

- Requisito cumprido: ✓ + borda; nunca só cor. "Falta 1!" (pílula `ALMOST`) quando falta um requisito.
- Tocar no requisito: `TaskHelp` (o que falta e onde) com "Ir". Item-chave na Mochila: botão "Dar".
- O painel não fecha ao entregar; o botão Crescer acende na hora.
- Sem fase seguinte (adulto): o topo mostra a Pelagem de seda (etapa 17) ou "Ele já é o Guardião do Vale".

## C. Caderneta (cartões de fase)

- Passada: foto oficial (PhotoCard), data real, peso, idade e 1 fato real (02 A).
- Atual: nome, idade, "desde DD/MM", pilares e um fato.
- Futura: silhueta + dica poética (`teaser` no dado, ex.: "Dizem que um dia o preto vira céu e o castanho
  vira sol...") + "Cap. N" com cadeado. **Nunca** a cor nem a arte da fase futura.

## D. Silhueta (`silhouette.gdshader`)

- Usa o quadro `idle_breathe` 0 do **corpo da próxima fase**; pinta tudo de `Palette.INK` com contorno claro
  de 1 px (legível no claro e no escuro) e um "?" por cima.
- **Revela partes** conforme os requisitos: 0 → só contorno; 1 → orelhas; 2 → rabo e pernas; 3 → brilho
  pulsando; tudo pronto → brilho forte. Regiões em `growth.json → bodies.<corpo>.parts` (retângulos no
  canvas 256×216); revelado = contorno interno mais claro, nunca cor.
- Da Mocinho para Azul e Dourado o corpo é o mesmo: a silhueta ganha um "?" colorido (a cor é o segredo).

## E. Arte do Tiro — identidade (regra de ouro)

**O adulto (Azul e Dourado) é o Tiro atual e não é redesenhado.** `tiro_pet/`, `tiro_world/`, `hud_tiro.png`
e `tiro_pet_idle_front.png` continuam como estão. As outras fases são **o mesmo cachorro mais novo**.

### Corpos

| Corpo | Fases | Pastas novas | Diferença permitida |
|---|---|---|---|
| `puppy` | Recém-chegado, Filhotinho | `characters/tiro_pet_puppy/`, `characters/tiro_world_puppy/`, `ui/icons/hud_tiro_puppy.png` | menor no mesmo canvas, cabeça proporcionalmente maior, **orelhas caídas**, pelo curto e fofo, sela **preta**, castanho só no rosto, peito e patas, patas mais grossas |
| `young` | Dentinhos, Aventureiro | `characters/tiro_pet_young/`, `characters/tiro_world_young/`, `ui/icons/hud_tiro_young.png` | **orelhas em pé** como hoje, corpo mais comprido e magrinho, pelo meio bagunçado, sela preta |
| `adult` | Mocinho, Azul e Dourado | (existentes) | Mocinho = mesma arte com sela escurecida pelo shader de pelagem |

### O que NÃO pode mudar (checklist de cada imagem)

Olhos (formato, brilho, posição relativa), nariz, língua rosa, máscara castanha do rosto, contorno escuro de
1 px, direção da luz, estilo de pixel (densidade e tamanho do pixel), paleta (só as cores atuais + os pretos do
pelo jovem, tirados da própria paleta), canvas (256×216 tela do Tiro; mundo conforme cada original — rotações 64×64, clipes 76×76/80×80/96×96; 48×48 retrato; 160×160
`idle_front`) e **linha dos pés** (mesmo `pet_feet`, para sombra, estrelas e roupas não saírem do lugar).

### Pelagem por shader (`tiro_coat.gdshader`)

- Parâmetro `coat` 0..1 mapeia só as cores da sela do **adulto**: em 0 ela fica com os mesmos pretos do jovem e azula até o original em 1; o dourado não muda (ajuste do Vitor na etapa 01, ver DECISOES; antes: "e o
  dourado → castanho mais fundo em 0"). Corpos jovens não usam essas cores, então o shader não os afeta.
- Mocinho: `coat` vai de 0,3 a 0,7 conforme a média dos pilares na fase ("raiz azulando", como na vida real).
  Azul e Dourado: 1,0 (= Tiro atual, idêntico pixel a pixel).
- Parâmetro `sheen` 0..1 (etapa 17): faixa de brilho que desliza no pelo (Pelagem de seda).
- Aplicado em `PetAnimator`, `DogWorld`, retrato do HUD, `PetAnimator.portrait`, intro e boas-vindas.

### Clipes por corpo

- `young`: os 22 clipes da tela do Tiro (mesmos nomes e quantidade de quadros), mais `sleep_belly` (1 quadro).
- `puppy`: os 22 menos `give_paw` (filhote não faz truque; mapeado para `wag_excited` em
  `growth.json → bodies.puppy.clip_fallback`), mais `sleep_belly`.
- Mundo (`young` e `puppy`; canvas igual ao respectivo original adulto: rotações 64×64 e animações 76×76/80×80/96×96): `idle`, `walk` (east/north/south), `sit`, `sleep`, `sniff`, `dig`, `eat`,
  `bark` e as 8 `rotations`, com os mesmos quadros do adulto.
- `idle_front` 160×160 por corpo (intro e boas-vindas).
- **Roupas:** no `young`, as 19 roupas usam `overlay_anchors.json → bodies.young` (deslocamento e escala por
  clipe, variantes por quadro quando precisar). No `puppy`, roupas ficam escondidas ("ainda é pequeno para
  roupa"); equipar continua permitido e aparece quando ele crescer.

### Processo obrigatório

1. Extrair a paleta das imagens atuais (`pixelart_workbench describe` ou `tools/pixel_tools.ps1`).
2. Gerar o quadro base (`idle_breathe` 0) de cada corpo **a partir do quadro atual como referência**.
   Comparar 3 métodos na etapa 01: (a) edição com referência no PixelLab (`edit_image`/`edit_image_pro_flash`);
   (b) edição exata com `pixelart_workbench` sobre o quadro atual (orelhas, sela, proporção);
   (c) `inpaint_image` só nas orelhas/corpo. Prompt base: *"the same yorkshire terrier as the reference, as a
   younger puppy: floppy ears, rounder head, short fluffy coat mostly black with tan face, chest and legs; keep
   the same eyes, nose, pink tongue, outline and palette; front view, transparent background"*.
3. `reduce_colors` para a paleta extraída; alinhar a linha dos pés.
4. **Prancha lado a lado** (atual | filhote | jovem; tela 256, mundo 64, retrato 48) em
   `build/art/tiro_fases/prancha_*.png`; abrir o PNG. Portão do Vitor.
5. Animação: derivar **quadro a quadro dos clipes do adulto** (mesmo movimento e tempo; muda corpo/orelhas/
   cor). Ferramentas de animação do PixelLab só se mantiverem o checklist; conferir cada clipe numa prancha
   de quadros.
6. Registrar receitas, sementes e prompts em `docs/ART_PIPELINE.md`.

### Outras artes deste plano (todas 32 px salvo indicação)

Ícones: `pillar_body`, `pillar_coat`, `pillar_smart`, `pillar_brave`, `growth_badge`, `action_brush`,
itens novos do 03 (C), `milk_tooth`, ícones de seção do álbum. Adereços de foto (até 96 px): `box`, `foam`,
`carrot_mouth`, `sock`, `drops`, `ball`, `moon`, `fireflies`, `mud`, `medal`, `stall_sign`, `party_hat`,
`cake`. Moldura polaroide (9-patch). Objetos da Casa (05 G), no estilo de `rooms/house.json`.

## F. Cerimônia de crescer (etapa 08)

1. **Entrega:** se houver item-chave a entregar, os ícones voam até o Tiro (`fly_icon`, `Haptics.tap`).
2. **Concentração:** fundo `Palette.DIM`, Tiro no centro respirando, brilho crescendo (1 s).
3. **Transformação:** silhueta branca alternando forma velha ↔ nova, acelerando (no máximo **3 trocas por
   segundo**; 2,5 s). `Motion.reduced` → troca suave de 0,4 s.
4. **Revelação:** raios, confete, `Haptics.big`, fita "O Tiro cresceu!".
5. **Antes e depois:** `ModalCard` com as duas poses, nome da fase, idade, peso, fato real; risquinho novo
   desenhado na régua (miniatura).
6. **O que é novo:** um "Novo!" por liberação (fila modal existente).

Variante "cresce dormindo" (fases 4 e 5): depois de "Crescer!", se o Tiro estiver dormindo, a revelação
espera ele acordar ou a próxima abertura (cartão de boas-vindas); um toque nele acorda e revela na hora.

## G. Álbum (etapa 13)

`AlbumView` no caderninho: `UiKit.segmented` com as 6 seções; grade 3 colunas de `Photo_<id>` (polaroide;
faltando = silhueta cinza + título; secreta = "?" + título); contador "X/54". Detalhe `PhotoDetail`: `PhotoCard`
grande, título, data real ("12 de março, 19h"), fase, botão `HintButton` (lupa) e `HangButton` ("Pendurar"
na parede de fotos). `PhotoCard` monta: moldura + cenário recortado (`scene`) + quadro do Tiro no corpo/coat da
fase gravada + adereços.

## H. Textos e glossário

Verbos novos: **Crescer** (botão), **Dar** (entregar item-chave ou brinquedo ao Tiro), **Escovar**. Atualizar
`texts_test` na etapa que usa o verbo pela primeira vez. Nomes: "Pilares" não aparece para o jogador — a aba é
"Crescimento" e cada pilar é chamado pelo nome (Corpo, Pelagem, Esperteza, Coragem).

## I. Capturas (acrescentar ao `tests/ui_tour.gd`)

`t01_growth_panel`, `t02_growth_almost`, `t03_growth_ready`, `t04_ceremony_before_after`, `t05_hud_growth`,
`t06_notebook_growth`, `t07_brush`, `t08_tastes`, `t09_album_grid`, `t10_photo_detail`, `t11_house_shelf`,
`t12_pet_puppy`, `t13_pet_young`, `t14_pet_young_outfit`. Cada etapa acrescenta só as suas.
