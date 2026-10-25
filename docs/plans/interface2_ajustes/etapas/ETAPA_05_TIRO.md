# Etapa 05 — Tela do Tiro: humor, Animado, cardápio e cerimônia

> Tamanho: médio. Depende de: 04. Próxima: 06.
> Itens da revisão: **15** (humor e "Animado"), **19** (cardápio: "Provar" vermelho, cobre o focinho),
> **30** (cerimônia: Tiro repetido nos raios, régua fraca).
> Resultado que o Vitor vê: o humor aparece numa pílula legível sob o Tiro só quando muda ou ao tocar nele;
> "Animado" é um selinho mel no avatar; o cardápio não usa vermelho e não tapa a cabeça do Tiro; a cerimônia
> de crescimento mostra o antes/depois como herói, sem um mini-Tiro a mais, e uma régua com marcas.

## 1. Objetivo
Acertar a semântica de cor e a legibilidade na tela que o jogador mais vê, e limpar a cerimônia.

## 2. Ler antes
`REVISAO_OPUS.md` itens 15, 19, 30; `03_TELAS.md` "Tiro" (humor "só quando muda ou ao tocar nele") e
"Cerimônia"; `02_JORNADA.md` §7 (cardápio ancorado no botão Cuidar); `00_VISAO.md` §3.4 (vermelho = pede
atenção/falta); protótipos `prototipo/tiro_roleta.png`, `prancha_roleta.png`.

## 3. Arquivos
| Arquivo | Itens |
|---|---|
| `game/scenes/ui/pet_screen/pet_screen.gd` (`MoodLabel`) | 15 |
| `game/scripts/ui/hud.gd` (`AnimatedBadge`) | 15 |
| `game/scripts/ui/pet_care_tray.gd` (`FoodMenu`, `NewTaste`, `FavoriteHeart`, `_place_menu`) | 19 |
| `game/scenes/ui/growth_ceremony/growth_ceremony.gd` (`BeforeAfter`, `HeightMark`, raios) | 30 |

## 4. Como está hoje (estado esperado ao começar)
- `MoodLabel` ("Tiro está feliz da vida!") é texto solto sobre o tapete vermelho, sem fundo, visível por
  2,5 s após mudar (etapa 04 do Interface 2) — ilegível sobre o tapete (`i2_04_pet`).
- `AnimatedBadge` é uma legenda verde solta sob o avatar do HUD.
- `FoodMenu` usa chip **vermelho** "Provar" para sabor novo e nasce cobrindo o focinho do Tiro, que é o
  alvo do arrasto da comida (`i2_04_food_menu`, `f08_pet_food_menu`).
- Cerimônia: o Tiro aparece no raio (mini) **e** no antes/depois; `HeightMark` é uma linha fraca
  (`i2_10_ceremony`, `t04_ceremony_before_after`).

## 5. Passo a passo
1. **Humor (15):** `MoodLabel` vira pílula translúcida (`CARD` a 85%, Nunito 12, `INK`), presa sob o Tiro e
   acima do tapete (use `PetBackdrop.pet_feet`/`scene_rect`); aparece ao mudar de humor ou ao tocar no Tiro e
   some após 3 s (`Motion.pop_in/pop_out`; com `Motion.reduced`, aparece/some sem animar). O nó continua
   `MoodLabel` (os testes procuram por ele) — se a pílula for um contêiner, o `Label` interno mantém o nome.
2. **Animado (15):** `AnimatedBadge` vira selo pequeno no avatar (disco `HONEY` 18 com `ctl spark` branco),
   com a ajuda que já existe ao tocar no avatar. Sem legenda solta.
3. **Cardápio (19):** chip de sabor novo = chip **mel** "Nova!" com ✦ (semântica do `NewTaste`), e a
   quantidade no mesmo chip (`×12`), nunca vermelho. O `FoodMenu` nasce **acima do botão Cuidar** (02 §7) e
   abaixo do focinho do Tiro: calcule a partir do retângulo da cabeça (`PetScreen.back_rect`/área de soltar)
   e não deixe o cartão cruzar esse retângulo; se não couber, encolha a lista (5 linhas → rolagem).
4. **Cerimônia (30):** tire o mini-Tiro dos raios; os raios ficam atrás do par antes/depois (que é o herói).
   `HeightMark` ganha marcas a cada 10 px e um rótulo com a altura relativa da fase ("+1 palmo" ou o número
   do `growth.json` se já existir; **não** invente dado novo — se não houver número, só as marcas e o nome
   da fase).

### 5.1 Armadilhas
- `care_wheel_test`/`pet_care_test` conferem a ordem dos cuidados e `CarePointer` como `Polygon2D`: não mexa
  na roleta.
- `brush_taste_test` procura `NewTaste` e `FavoriteHeart`: mantenha os nomes.
- `mood_test` confere a regra do Animado: só a aparência muda.

## 6. Testes
- Lista: `care_ui_test,care_wheel_test,mood_test,brush_taste_test,pet_care_test,ceremony_test,hud_test`
  (~2 min 10).

## 7. Capturas
Bloco `--aj-05-only`: `i2_04_pet`, `i2_04_pet_ask`, `f07_pet_low_needs`, `i2_04_food_menu`,
`f08_pet_food_menu`, `i2_10_ceremony`, `t04_ceremony_before_after`, e o avatar com Animado (crie
`aj_05_hud_animated` se não houver). Antes e depois nas 3 resoluções.

## 8. Pronto quando
- [ ] Humor legível sobre o tapete, só ao mudar/tocar; Animado como selo no avatar.
- [ ] Nenhum vermelho no cardápio; o cardápio não cruza a cabeça do Tiro nas 3 resoluções.
- [ ] Cerimônia sem Tiro repetido; régua com marcas.
- [ ] Testes verdes.

## 9. Handoff
Pontos naturais: após cada passo 1–4. Diga quais nós mudaram de tipo (Label → contêiner) e onde ficou o nome.

## 10. Registro
```
**Etapa 05 (data, executor[es]):** humor em pílula translúcida (3 s, ao mudar/tocar); AnimatedBadge como selo;
FoodMenu com chip mel "Nova!" e acima do botão sem cobrir a cabeça; cerimônia sem mini-Tiro e com régua
marcada. Testes … PASS em … s. Pendências: … Sem push.
```
