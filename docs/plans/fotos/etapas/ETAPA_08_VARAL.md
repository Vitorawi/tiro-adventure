# Etapa 08 — Varal na home (3 fotos em destaque)

> Tamanho: médio. Depende de: 04. Próxima: 09.
> Resultado que o Vitor vê: na tela principal do Tiro, um varalzinho na parede, acima do Tiro, com até 3
> polaroides presas por pregadores, bem visíveis; tocar numa abre a carta 3D; vazio mostra molduras "+"
> discretas que levam ao álbum. A Holográfica brilha ali também.

## 1. Ler antes
`01_DESENHO.md` §6, §10. Código: `scenes/ui/pet_screen/pet_screen.gd` (nós `ManualButton`, `NeedsPanel`,
`WishBubble`, `CareButton`, `AwayView`, `head_rect()`, `PetBackdrop`), `scripts/ui/pet_backdrop.gd`
(enquadramento do quarto: `ZOOM`, `FEET_Y`), `scripts/ui/house_ui.gd` (`wall`, `shelf`: o que existe na Casa
do mapa, **não mexer**), `GameState.feature_photo/featured_photos` (01), `CardViewer` (04).

## 2. Como está hoje
A home é o quarto ilustrado em tela cheia com o Tiro no centro, a bandeja de necessidades, o balão de
desejo, o caderninho e o botão Cuidar. As fotos só aparecem na Casa do mapa (parede/moldura comprada), em
listas de botões.

## 3. Passo a passo
1. **Arte**: cordinha + 3 pregadores de madeira + pequena sombra (gere em `tools/photo_frames_art.gd` ou num
   script próprio; ilustração suave com mipmaps). Polaroides do varal usam `PhotoCard` pequeno (~84 px) com
   leve rotação alternada (−4°, +2°, −2°) e um balanço sutil (tween lento; parado em Menos animação).
2. **Posição** (`PhotoLine` em `pet_screen`): na parede, entre o HUD e a cabeça do Tiro (`head_rect()`),
   centralizado; **medir** e garantir que não cobre `NeedsPanel`, `WishBubble`, `ManualButton`, `CareButton`
   nem a cabeça do Tiro nas 3 resoluções; se não couber, encolha as polaroides até 72 px. Some durante o
   passeio (`AwayView`) e no sono se cobrir o Zz.
3. Toque numa polaroide → `CardViewer.open(id)`. Toque num espaço vazio → abre o Álbum (`PetNotebook.open("album")`).
   O varal só aparece depois da primeira foto aberta.
4. Trocar pelo visualizador (04, `FeatureButton`); com 3 cheias, escolher qual sai.
5. Atualizar ao mudar `featured`/versão mostrada (`state_changed`, sem reconstruir o quarto inteiro).

## 4. Não fazer
Mexer na parede/moldura da Casa do mapa (`HouseUi`, `HouseDecor`) — fica para depois (pedido do Vitor).

## 5. Armadilhas
- A home usa `PetBackdrop` com zoom: posicione pelo retângulo da tela e pelos nós reais, não por pixels do PNG.
- Toques no varal não podem disparar carinho/gesto no Tiro (consuma o evento).

## 6. Testes
Novo **`tests/photo_line_test.gd`** (área `album`, mais `care`/`home` se existir):
1. Sem foto aberta: sem varal. Com 1: uma polaroide e dois "+".
2. 3 em destaque: 3 polaroides na ordem; tocar abre o `CardViewer` da certa.
3. Não intersecta `NeedsPanel`, `WishBubble`, `ManualButton`, `CareButton`, `head_rect()` em 360×780,
   390×844, 412×915.
4. Trocar a versão mostrada atualiza a polaroide do varal.
5. Toque no varal não conta carinho no Tiro.
Lista fechada: `photo_line_test,card_viewer_test,pet_care_test,care_ui_test,home_test` (use os nomes que
existirem em `tools/test_areas.json` para a home).
Capturas `tests/fotos_08_shots.gd` (3 resoluções): vazio, 1, 3 com uma Holográfica, dormindo, passeando.

## 7. Pronto quando
O varal aparece claro e bonito sem cobrir nada nas 3 resoluções, testes passam, capturas olhadas.
