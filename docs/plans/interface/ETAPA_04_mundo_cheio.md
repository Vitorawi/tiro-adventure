# Etapa 04 — Mundo em tela cheia: céu, paisagem e câmera gostosa

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_04_mundo_cheio.md."
> Pré-requisito: Etapas 00–03.

## Objetivo (o que o jogador sente)
"Abri o Sítio e ele está **ali**, grande, com céu e grama em volta — não uma maquete boiando no escuro.
Arrasto e o mundo desliza macio; dou dois toques e ele aproxima."
Resolve a reclamação principal ("no mapa as imagens ficam estranhas, os blocos são grandes").

## Leia antes
`scenes/levels/room/room.tscn` + `room.gd` (`_ready`, `_gui_input`, `_input`, `_zoom_at`, `_fit_zoom`,
`_show_whole_room`, `_clamp_content`, `_place_labels`, `point_at`, `_reveal`), `rooms/*.json`
(`initial_zoom`, `view_center`), `scenes/ui/worlds_screen/worlds_screen.tscn` + `.gd` (`Header`,
`MapButton`, `PlacesButton`, `NpcRow`, `_refresh_header`), `docs/WORLDS.md`.

## Passo a passo

### 4.1 Fundo de cada mundo (backdrop)
- [ ] Novo campo opcional em `rooms/<id>.json`:
```json
"backdrop": {
  "texture": "res://assets/sprites/areas/farm/backdrop.png",
  "sky": ["#8fd3f4", "#d8f1e4"],
  "ground": "#6fa046",
  "clouds": true,
  "parallax": 0.25
}
```
  - `sky` = degradê vertical (topo, meio) desenhado por `GradientTexture2D` atrás de tudo;
  - `ground` = cor sólida da metade de baixo (grama/piso/água) para a maquete "assentar";
  - `texture` (opcional) = arte por cima do degradê (morros, árvores ao longe), ancorada embaixo,
    escala inteira que cubra a largura;
  - `clouds` = nuvens passando (só nos mundos abertos);
  - `parallax` = quanto o fundo anda quando a câmera anda (0 = parado; 0,25 = um quarto).
- [ ] `room.tscn`: o `Void` (ColorRect escuro) vira `Backdrop` (Control em tela cheia, atrás do `Content`)
  com: `Sky` (TextureRect com gradiente), `Far` (TextureRect com a `texture`), `Clouds` (Node2D).
  Sem `backdrop` no JSON = comportamento antigo (cor escura), para não quebrar salas futuras.
- [ ] Parallax: no `_gui_input` (arrasto) e no `_zoom_at`, `Far.position = base + content_delta * parallax`.
- [ ] Nuvens: 3–4 sprites (`areas/common/cloud_1.png`, `cloud_2.png`), y aleatório na faixa do céu
  (topo até 35% da altura), andam 6–12 px/s para a direita e voltam pela esquerda (`_process`, não tween
  infinito). Escala inteira 2×. `modulate.a 0.9`.
- [ ] Valores por mundo (ponto de partida; ajuste olhando as capturas):
  | Mundo | sky | ground | texture | clouds |
  |---|---|---|---|---|
  | house | `#f3dcc0`, `#e9c9a3` (parede quente) | `#9a6b48` (piso) | nenhuma | não |
  | farm | `#8fd3f4`, `#dff3e6` | `#6fa046` | morros verdes + árvores ao longe | sim |
  | park | `#9ad7f5`, `#fbeec9` | `#79a84c` | prédios baixos e ipês ao longe | sim |
  | village | `#a7d8f0`, `#f6e3c4` | `#7aa24d` | telhados ao longe | sim |
  | nature | `#9cc9d8`, `#e4efe6` (névoa) | `#4f8a5b` | montanhas e pinheiros | não (névoa: 2 faixas brancas 20% que andam devagar) |
- [ ] **Bordas da maquete:** as maquetes têm "borda de terra" (bloco flutuante). Com o `ground` da mesma
  cor da grama, a terra continua aparecendo. Opção A (preferida): **cobrir a borda** desenhando uma faixa
  de grama (`ground`) por cima da terra — polígono `"edge_cover"` no JSON da sala, preenchido com a cor
  `ground`, desenhado logo acima do `Background` e abaixo dos objetos. Opção B: deixar a borda e escurecer
  levemente o `ground` embaixo dela (fica "ilha no gramado"). Gere capturas das duas no Sítio e escolha a
  que parecer mais natural; anote no ROADMAP.

### 4.2 Arte dos fundos
- [ ] Receita "Fundo de céu/paisagem" (`01 → E`) para farm, park, village e nature (house não precisa).
  Peça só o **horizonte** (faixa de 360×200 com morros/árvores/telhados, transparente em cima) se a
  ferramenta não acertar a imagem inteira — o céu vem do degradê.
- [ ] Nuvens: receita "Nuvem" (2 arquivos).
- [ ] **Plano B** se a arte não ficar boa em 3 tentativas: só degradê + `ground` + nuvens (já melhora muito).

### 4.3 Câmera
- [ ] **Enquadramento inicial** por sala (substitui o `_fit_zoom` como padrão de abertura):
  - novo campo `"framing": "width" | "height" | "fit"` (padrão `"width"`): `width` = a maquete ocupa a
    largura toda (`size.x / content.x`), centrada em `view_center` (ou no meio);
  - `initial_zoom`/`view_center` continuam valendo e têm prioridade.
  - Valores de partida: **farm** `initial_zoom 1.0`, `view_center [562, 250]` (a horta 3×3 inteira e grande);
    **house** `framing width`, `view_center` no meio do piso (o Tiro em `dog_start [330, 310]` tem que ficar
    visível); **park/village** `initial_zoom` ≈ 0,8–0,9 centrado no meio; **nature** `width`.
- [ ] **Zoom mínimo:** `"min_zoom"` opcional; padrão = o menor entre `_fit_zoom()` e o enquadramento
  inicial (pode afastar até ver tudo; o fundo cobre o resto). **Máximo:** 2,0 (como hoje).
- [ ] **Limites de arrasto:** hoje `_clamp_content` centraliza quando a maquete é menor que a tela.
  Mantenha, mas permita arrastar até 48 px além das bordas (fica elástico) e volte com tween de 0,2 s ao soltar.
- [ ] **Inércia:** ao soltar um arrasto, continue com a velocidade dos últimos 80 ms e desacelere
  (`velocity *= 0.9` por quadro a 60 fps, para em < 10 px/s). Qualquer toque para a inércia.
- [ ] **Duplo toque** (dois toques < 300 ms e < 24 px): se o zoom está abaixo de 1,4 → anima para 1,6
  centrado no ponto; senão → anima de volta ao enquadramento inicial. O primeiro toque do par **não** deve
  abrir nada? Não dá para esperar 300 ms em todo toque (ficaria lento). Regra: o toque simples age na hora;
  o duplo toque só dá zoom se o **primeiro** toque caiu em área vazia (não acertou objeto/etiqueta/NPC).
- [ ] **Zoom animado:** `_zoom_at` ganha uma versão `zoom_to(pivot, zoom, seconds := 0.25)` com tween,
  usada pelo duplo toque, pelo "centralizar" e pelo `point_at` (que passa a deslizar a câmera até o alvo
  em vez de pular).
- [ ] **Botões + / −** saem (`ZoomControls.visible = false`; mantenha o nó). Novo botão pequeno
  `RecenterButton` (`icon_button` 44, ícone de alvo — use `find_paw` ou gere `ui_recenter.png` 32) no canto
  inferior direito, **só aparece** quando a câmera está longe do enquadramento inicial (zoom diferente em
  > 15% ou centro deslocado > 120 px). Tocar = volta animada.
- [ ] **Painel por cima do objeto:** ao abrir um painel a partir de um objeto do mapa (`_on_object_tapped`),
  se o objeto ficaria escondido atrás do painel (y de tela > 45% da altura), deslize a câmera para ele ficar
  a 30% do topo. Ao fechar o painel, não volte (o jogador está ali).

### 4.4 Cabeçalho do mundo some
- [ ] `WorldView/Header` some do layout (`visible = false`; mantenha os nós `MapButton`, `PlacesButton`,
  `WorldTitle`, `NpcRow` para os testes, mas reposicionados como abaixo). O `WorldHolder` ocupa a tela toda.
- [ ] Novo overlay `WorldBar` (filho de `WorldView`, por cima do `WorldHolder`), abaixo do HUD (y = 64):
  - **esquerda:** pílula do mundo (`MapButton` reaproveitado): ícone do mundo 32 + nome + "▾", fundo
    `PAPER` com borda 2 na cor do mundo (`Palette.WORLD`). Por enquanto abre a lista atual (`show_map`);
    a Etapa 05 troca pelo seletor.
  - ao lado: `PlacesButton` vira `icon_button` 44 com ícone de lista (`tab_tasks` serve) — mesma ação.
    Título do painel sempre "Lugares" (sai o "Locais"/"O que tem aqui?").
  - **direita, em coluna:** rostos dos personagens do mundo (`NpcRow` vira VBox): círculo 48 com o retrato,
    borda `PAPER`; selo `BadgeLabel` "!" (nova) ou `ui_check` verde (pronta) no canto. Tocar = `Places.open_npc`.
    Sem nome escrito (o nome aparece no balão da fala).
- [ ] O `WorldBar` não pode bloquear arrasto do mundo fora das peças (`mouse_filter IGNORE` no contêiner).

### 4.5 Etiquetas não cortam
- [ ] Em `_place_labels` (ou depois), se a etiqueta sair da área visível em x por menos que a largura dela,
  empurre-a para dentro (8 px de margem) — em coordenadas do mundo, considerando `_content.position` e
  zoom. Etiqueta de objeto totalmente fora da tela fica onde está (some com ele).
- [ ] (As regras de quando mostrar etiqueta mudam na Etapa 06; aqui só não cortar.)

## Testes
- [ ] `game/tests/world_view_test.gd` (novo): para cada mundo aberto com `dev_unlock_everything`, depois de
  `enter` + 3 quadros:
  - nenhuma faixa vazia visível: o `Backdrop` cobre a tela (tamanho == tamanho da sala) e existe `Sky`;
  - Sítio: zoom ≈ 1,0 e os 9 canteiros da horta dentro da tela;
  - Casa: o Tiro (`_dog.position` convertido para tela) dentro da tela;
  - `ZoomControls` invisível; `RecenterButton` invisível no início e visível depois de `_zoom_at(…, 2.0)`;
  - duplo toque em área vazia muda o zoom; toque simples em objeto continua abrindo o painel na hora.
- [ ] `animals_test`/`world_life_test` usam `_zoom_at(…, 0.3)`: o zoom mínimo novo pode impedir 0,3.
  Ajuste o teste para usar `farm._fit_zoom()` (ou permita `min_zoom` ≤ fit) — anote a escolha.
- [ ] `navigation_test`, `farm_test`, `nature_test` continuam passando (pontos/toques não mudam).
- [ ] Toque real (`touch_test.ps1`): roteiro `build/touch_steps_etapa04.json` com drag no Sítio, pinch,
  duplo toque e toque na Bancada; capturas mostram o painel e a Bancada visível acima dele.

## Capturas
Tour `etapa04_antes`/`etapa04_depois` (todas as b06 de mundo, a04 Casa) + `d01_farm_zoom_out` (zoom mínimo),
`d02_farm_doubletap`, `d03_sheet_over_object` (Bancada visível acima do painel). Confira em 390×844 e 412×915.

## Lista de conferência (aceite)
- [x] Nenhum mundo mostra o vazio escuro; céu/paisagem combinam com a maquete.
- [x] Sítio abre com a horta grande; Casa inteira com o Tiro à vista; Praça/Vila preenchem a largura.
- [x] Arrasto com inércia, duplo toque e pinça funcionam no celular (touch_test).
- [x] Sem botões +/−; "centralizar" só quando precisa.
- [x] Cabeçalho do mundo virou pílula + lista + rostos; o mundo vai até o topo.
- [x] `docs/WORLDS.md` (campos `backdrop`, `framing`, `min_zoom`, `edge_cover`) e CLAUDE.md/AGENTS.md
  (Ambientes) atualizados; ART_PIPELINE com fundos/nuvens.
- [x] ROADMAP e README marcados; commit `feat(ui): mundos em tela cheia com céu, câmera macia e cabeçalho flutuante`.

Revisão visual do Codex (15/10/2026), após `7e84772`: grama repetível nos quatro mundos externos, cobertura da terra sem
sobras, Casa inteira e aviso abaixo dos controles. Nuvens desligadas para simplificar o fundo, conforme as alterações locais
do Claudi. Estações tocadas no mapa abrem em meia altura (componente da Etapa 02), deixando a Bancada visível acima do painel.
Jobs, decisões, testes e capturas da revisão estão no topo de `docs/ROADMAP.md` e no `docs/ART_PIPELINE.md`.
