# Mundos (mini mundinhos) e navegação

## Animais comprados no sítio

Os abrigos abrem a loja pelo botão **Comprar animais**. Cada compra é individual; há
três vagas no galinheiro e três no curral. O jogador pode escolher/repetir as variedades.
Animais só aparecem depois da compra, com textura/escala definidas em `config.json.animals`.
Objetos em `rooms/farm.json` usam `animal_station` e `animal_slot` (índice de 0 a 2).
Vagas vazias são invisíveis, sem toque nem obstáculo. Quando o rebanho muda, RoomView
atualiza os sprites e recalcula a navegação. A posição é fixa, com movimento leve do sprite.

> Reorganização de 12/10/2026 (Claude Code): o jogador não precisa adivinhar onde fica cada coisa.
> Regra de ouro: **cada coisa fica no lugar onde estaria no mundo, e a aba Missões leva até lá.**

## Abas
| Aba | O que tem |
|---|---|
| **Tiro** | Tela do Pet (necessidades, carinho, comer, brincar, banho, dormir) e botão **Manual** para consultar recursos/estações. |
| **Mapa** | O mundo em que você está (sala tocável) com cabeçalho: botão **Mapa**, nome do mundo, botão **Lugares** ("O que tem aqui?") e os **personagens** dali (verdes com "!" quando há missão pronta). Tocar em "Mapa" (ou na aba de novo) mostra a lista de mundos com miniatura, personagens e avisos ("Canteiros: 2 prontos para colher!"). |
| **Missões** | "O que eu faço agora?": **História** (um passo por vez: rosto de quem pede, instrução breve + ícone + `0/6`, ícone do lugar, ingredientes que faltam em chips tocáveis, recompensa em chips, **Ir** + **?**), **Diárias** (3, renovam à meia-noite) e **Semanais** (2, renovam na segunda), também com instrução breve. A bolinha vermelha conta o que está pronto. Atributos e Coleção ficam na aba Tiro. |
| **Mochila** | Ícone + quantidade por categoria (aparece após a 1ª colheita). Tocar num item: preço, efeitos, **De onde vem** e **Usado em** (chips que levam ao lugar), "Dar ao Tiro" e "Vender". |

## Instruções das missões

Texto de ação: `quests.json → goals[].label` aparece junto ao progresso, na aba Missões
e nos cartões dos personagens; `routines.json → description` explica cada diária/semanal.
Use verbos concretos (plantar, colher, comprar, produzir, entregar) em uma frase curta.

## Manual visual (consulta na tela principal)

- Botão **Manual** acima do Tiro, sempre disponível; Recursos e Estações em dois botões.
- **Recursos:** todos os itens de `items.json`, agrupados por categoria, com ícone e nome,
  mesmo com mochila vazia. Tocar mostra como conseguir: plantar/colher, receita com ingredientes
  → produto, rota ou recompensa de missão; tempo e quantidade vêm dos JSON. Ingredientes e
  produtos são tocáveis para seguir a cadeia; mostra também usos em receitas/construções,
  comida do Tiro e preço de venda quando houver.
- **Estações:** fogão, forno, bancada e ateliê derivados de `config.json → stations`, produtos
  derivados de `recipes.json`; local legível (mundo › lugar). Também inclui canteiros e rotas
  para explicar onde coletar os materiais.
- **Ir até lá** usa a navegação existente; **Ver compra** para estação não comprada.
  Mundos/lugares fechados têm botão desabilitado e requisito. Receitas/culturas/rotas mostram
  requisitos pendentes. O catálogo permite conhecer conteúdos futuros, sem liberar suas ações.
- Código em `scripts/ui/game_manual.gd`; não depende de itens possuídos nem altera o save.
  `manual_test.gd` valida cobertura, consulta sem alterações, toque em ingrediente e destino.

## Onde fica cada coisa hoje

| Mundo | Personagens | Lugares (tocar na cena ou em "Lugares") |
|---|---|---|
| **Casa** | — | Tigela, **Cozinha** (fogão + forno + fila extra), Geladeira, porta → Sítio. Sofá = enfeite com soneca (`hidden`). |
| **Sítio da Bloblo** | Bloblo (casinha) | Canteiros (+ estufa), Produção (bancada + moinho + queijaria), Pomar e Animais (galinheiro + curral). Volta para casa é atalho oculto. |
| **Praça** | Nina (+ Pipoca, enfeite) | **Passeio** (portão; o Tiro sai de casa e volta com achados). Pet shop, amigos e treino chegam nas Etapas 08–10. |
| **Vila** | Feirante, Laís | **Feira** (vender/encomendas; + banca), **Ateliê**, **Portão da trilha** (viaja para Natureza; capítulo 3) |
| **Natureza** | Guia da trilha | **Bosque** (madeira/madeira dura), **Caverna** (pedra/cobre/cristais), **Prado** (fibras). Cada local tem uma a três coletas paralelas. |

Regra atual: **5 mundos (Casa, Sítio, Praça, Vila, Natureza), no máximo 4 lugares visíveis cada** (`content_test`).
Não existe menu "Construir": cada construção é comprada **no próprio lugar** — `"upgrade"` do lugar
(sem ela, tocar abre a compra; móveis mostram "+") ou `"upgrades"` (cartões de compra dentro do painel).
`Database.place_of_upgrade` acha esse lugar; o "Ir" das missões leva até lá.
A trilha mora no novo mundo Natureza; o portão da Vila usa `travel:nature`. A arte antiga
`areas/trail/` continua guardada. Rotas aparecem no lugar do tipo delas (`activities.place`:
`walk`, `creek`, `mine`, `crystal`, `meadow` em Natureza; `orchard` no sítio).

Natureza tem paisagem contínua 512×384 com bosque, riacho com ponte, trilha e gruta.
`regions` cercam/sombreiam zonas fechadas, abrem por `requirements` ou compra (`upgrade`).
Abrir por Aventura recalcula a grade do Tiro, mesmo sem nova construção comprada.
Tocar no Bosque, Caverna ou Prado abre o local. Fechado, oferece desbloqueio; aberto,
mostra barra de XP, próximo marco, coletas restantes, materiais e fila. Recolher coletas
evolui o local; níveis 2/3 liberam materiais e espaços automaticamente. Sem compras de
ferramentas, níveis ou vagas. O ? mostra a cadeia; Atributos do Tiro mostra o XP de cada região.
Bosque nível 3 libera madeira dura; Caverna nível 2 cobre e nível 3 cristais.
Regiões usam requisitos das ampliações, recalculando navegação ao abrir.
Um toque no material inicia na primeira vaga livre. Recolher prontos é um botão único.
Fila permanece simultânea, com ícone/tempo/barra. Refinar mostra receitas existentes e
leva às estações no sítio/vila. Desbloqueio e curva de XP ficam em progression.json; nature_xp é salvo por região.
O painel `nature:<grupos>` resolve os aliases `routes:<grupo>` para missão/manual/mochila.
`route_markers.site` mostra tempo/quantidade pronta por `RouteIndicator`; obstáculos
separados impedem andar na água, árvores ou penhascos. O save mantém os ids de atividade.

## Seleção de mundos

A aba Mapa retoma o último mundo da sessão (Casa no começo, sem gravação em disco). Tocar novamente
na aba ou na pílula do mundo abre `MapView`, seletor sobre o mundo escurecido, sem esconder a sala.
`WorldSelector` organiza cinco cartões 240×330 em carrossel horizontal, com margens para centralizar
o primeiro/último, encaixe ao soltar e laterais menores. Tocar num lateral centraliza; tocar no central
aberto viaja. Fecha pelo ✕, fora dos cartões ou arrastando para baixo. A pinça da sala fica suspensa
enquanto ele está aberto, sem alterar o zoom ou desalinhamento da textura do chão.

`WorldCard` mostra miniatura sobre céu/chão do `backdrop`, faixa `Palette.WORLD`, nome, legenda,
"Você está aqui", quantidade de avisos (`Places.world_alerts`) e selo de missão. `map_name`, `map_caption`
e `icon` de `worlds.json` fornecem os textos/ícones; os cinco ícones próprios são `tab_house`, `tab_farm`,
`tab_park`, `tab_village` e `tab_nature`. Mundo fechado fica desabilitado, com cadeado e
`Places.unlock_hint`: "Abre no capítulo N", nome da história ou missão e seu ícone/retrato.
Quando o requisito é uma missão, o capítulo vem do próprio `quests.json`, sem alterar a regra de abertura.

`WorldsScreen.enter` usa `WorldTransition` quando muda o mundo com a aba visível. Duas massas de papel
arredondadas entram em 0,22 s, a sala troca coberta e elas saem em 0,22 s (alternativa permitida pelo plano).
O nó coordenador é `CanvasLayer`; `CloudCover` usa o canvas da tela em z 5, abaixo do HUD em z 8,
para preservar a ordem sem mover o `TopBar`. A seta e o painel do "Ir" esperam a viagem terminar;
um pedido novo cancela o destino atrasado anterior. `Motion.reduced` troca imediatamente.
`show_map()`/`is_map_open()` continuam válidos e `close_map()` fecha o seletor. Os nomes
`WorldCard_<mundo>` e `World_<mundo>` permanecem. Natureza mantém os três locais em "Lugares".

## Mundo em tela cheia: fundo, enquadramento e câmera (Interface nova, Etapa 04)

O mundo ocupa a tela toda (o HUD e a `WorldBar` flutuam por cima). Nada de vazio escuro: atrás da maquete
há céu, paisagem ao longe e chão. Campos opcionais em `rooms/<id>.json` (sem `backdrop` a sala mantém a cor escura de antes):

```json
"backdrop": {
  "texture": "res://assets/sprites/areas/farm/backdrop.png",
  "sky": ["#8fd3f4", "#dff3e6"],
  "ground": "#7f9150",
  "ground_texture": "res://assets/sprites/areas/common/grass_ground.png",
  "clouds": false,
  "parallax": 0.25,
  "horizon": 0.2
},
"framing": "width",
"initial_zoom": 1.0,
"view_center": [562, 250],
"min_zoom": 0.3,
"edge_cover": [[20, 335], [604, 629], [1184, 341], [1184, 412], [616, 700], [20, 412]]
```

- `sky` = degradê vertical (topo, meio) do alto da tela até o horizonte; `ground` = cor lisa do horizonte para baixo.
  `texture` (opcional) = faixa de paisagem (PNG com céu transparente, base na cor do chão) apoiada no horizonte, em escala
  inteira que cubra a largura; `clouds` = `true` (3–4 nuvens `areas/common/cloud_*.png` a 6–12 px/s, escala 2) ou `"mist"`
  (névoa: nuvens grandes a 20%, lentas); `parallax` = fração do movimento da câmera que o horizonte e a paisagem acompanham;
  `horizon` = altura do horizonte como fração da tela no enquadramento inicial (padrão 0,42; ajuste para ficar na altura do
  fundo da maquete). Tudo é montado em `RoomView._setup_backdrop` (nó `Backdrop`: `Void`, `Sky`, `Ground`, `Clouds`, `Far`).
- Os PNGs dos mapas (`farm_animals`, `room`, `park`, `banner`) têm o fundo transparente em volta da maquete
  (`Invoke-ClearCorner` em `tools/pixel_tools.ps1`); mapa novo precisa seguir isso, senão o céu não aparece.
- `ground_texture` (opcional) = textura repetível de grama. `WorldGround` ajusta o brilho à cor `ground`, repete abaixo do
  horizonte e acompanha a posição e o zoom do mundo. Sem o campo, mantém o chão liso (Casa). Os mundos atuais deixam
  `clouds: false` para simplificar o fundo; as nuvens e a névoa continuam disponíveis para outras salas.
- `edge_cover` = polígono (ou lista) em coordenadas do fundo, acima do `Background` e abaixo dos objetos. Os quatro mundos
  externos cobrem a lateral de terra com a mesma textura do chão, alinhada pelas coordenadas UV do mundo. O contorno de cima
  segue a grama; o de baixo passa de toda a imagem para não sobrar terra solta. Sem textura, usa `ground` ou `edge_cover_color`.
  `tools/edge_cover.ps1 <png>` sugere o contorno superior (confira na imagem antes de usar).
- `framing`: `"width"` (padrão: a maquete ocupa a largura toda, centrada em `view_center` ou no meio), `"height"` ou `"fit"`
  (sala inteira). `initial_zoom` e `view_center` têm prioridade. O zoom mínimo (`min_zoom`; padrão = o menor entre a sala inteira
  e a abertura) deixa afastar até ver tudo; o máximo é 2,0. `RoomView._initial_zoom()`/`_min_zoom()`.
- Câmera: arrastar passa até 48 px da borda e volta em 0,2 s ao soltar; soltar com velocidade continua deslizando (últimos 80 ms,
  perde 10% por quadro, para abaixo de 10 px/s; qualquer toque para). Duplo toque (< 300 ms, < 24 px, primeiro toque em área vazia)
  aproxima para 1,6 no ponto ou, se já passou de 1,4, volta ao enquadramento. `zoom_to(pivô, zoom, segundos)` e `recenter()` animam.
  Os botões +/− saíram (os nós ficam escondidos); `RecenterButton` (`ui_recenter`) aparece quando o zoom difere > 15% do inicial ou o
  centro passa de 120 px. Ao abrir um painel por um objeto que ficaria atrás dele (y > 45% da tela), a câmera o sobe para 30%
  (pode passar da borda; ao fechar o painel só volta ao limite do mundo — `Events.sheet_closed`).
- Estações abertas pelo objeto usam `Places.open(mundo, lugar, true)`: `station`/`stations` pedem `sheet_size: half`
  para preservar o cenário visível. A alça continua permitindo ampliar para consulta; listas/atalhos mantêm o automático.
  Desvio da implementação original da Etapa 04: subir o objeto não adiantava com o painel de Produção em 88% da tela.
- Etiquetas que sairiam pelas laterais são empurradas para dentro (margem 8 px); totalmente fora, ficam onde estão.
- `WorldsScreen`: sem cabeçalho. `WorldBar` (abaixo do HUD, y 64, ignora o mouse): pílula `WorldPill` (`MapButton`: ícone do mundo +
  `map_name` + seta, borda na cor `Palette.WORLD`; abre o seletor de mundos), botão de ícone `PlacesButton` (painel "Lugares", sempre
  esse título) e, à direita em coluna, `NpcFace` por personagem (`NpcRow`; selo "!" = missão nova, check = pronta; `Places.npc_badge`).

## Como criar um mundo novo (receita)

### Sítio ampliado e construções (13/10/2026)
- Fundo ampliado para 1208×539, preservando a área antiga (deslocamento +288 px em X).
  Nove canteiros e índices de save preservados; o espaço extra recebe estufa e pomar.
- Duas `regions` laterais: `greenhouse_area` e `orchard_area`. Cada uma usa a compra existente
  (`greenhouse`/`orchard`) para abrir. Chão sombreado + cerca; tocar abre a compra. Enquanto
  fechada, a região inteira é obstáculo; após comprar, apenas a construção bloqueia o caminho.
- A região tem `id`, `polygon`, `gate` (duas pontas da divisa), `upgrade`, `label`, `label_pos`
  e `locked_label: true`. Móvel dentro dela usa `region` e `upgrade`. Etiquetas dos móveis
  aparecem somente após a compra; a etiqueta Expandir desaparece quando a área abre.
- `initial_zoom: 1.0` e `view_center` (Interface nova, Etapa 04; antes 0,62) mantêm a horta 3×3 grande;
  arrastar mostra as laterais e diminuir o zoom mostra tudo. A seta do Ir desliza a câmera até o destino.
- Construções novas visíveis: bancada, estufa e pomar no sítio; forno na casa; banca extra e
  estação de costura na vila. Casa da Laís/Feira continuam no fundo; as compras acrescentam
  equipamento a esses lugares. Todas as peças têm `footprint` e se ordenam por Y.
- `Events.world_activity(kind, subject, plot_index)` é emitido após colheita, coleta e compra
  bem-sucedidas. A sala visível encontra o objeto e seu `approach`, e o Tiro se aproxima,
  cheira ao colher/achar produção pronta e comemora com pulos/coração. `station` detecta
  aumento do número de produtos prontos. Sono e mapas ocultos suspendem reações.
- Não há novo formato de save nem moeda de expansão: as áreas leem `progress.owned`.
  `world_life_test` cobre compras reais, saves já avançados, reações e caminhos após construir.

### Área dos animais (13/10/2026)
- Fundo atual `farm_animals.png`, 1208×683: quarta área na frente das três anteriores.
  `animals_area` é cercada até comprar `chicken_coop`; não libera estufa/pomar junto.
- Divisas das laterais deixam um corredor de 60 px no centro: é possível visitar os animais
  sem antes comprar as expansões de estufa/pomar. Polígonos de navegação incluem essa ligação.
- Galinheiro, curral, moinho e queijaria ficam nessa área, como sprites separados. Galinhas
  e vacas são sprites tocáveis com `upgrade`, `decoration: true` e `animal_idle: true`.
  Galinhas usam escala 0,6; vacas escala 1. Seus footprints conservadores também bloqueiam o Tiro.
- **Animais** abre `stations:chicken_coop+cow_barn`, após sítio próprio/capítulo ≥3.
  **Produção** abre `stations:workbench+mill+dairy`: receitas e compras moram no sítio.
  Continuação com no máximo quatro lugares visíveis; `home` fica oculto.
- Moinho/queijaria também têm lugares individuais `hidden`; toque no prédio abre sua
  própria estação, mesmo antes de comprar a bancada. `place_with_panel` prefere estes
  painéis exatos para o Ir do manual/missões. Compras pendentes mostram "+" após abrir a área.
- Estações com requisito ainda pendente não entram no painel múltiplo. Manual permite
  consulta de futuras receitas/construções, e os botões de compra continuam validando requisitos.
- Etiquetas detalhadas só no zoom ≥0,5. Ao afastar, aparece uma etiqueta Animais para evitar
  sobreposição. `StationIndicator` mostra tempo/barra e Coletar no objeto, e é tocável.
  Objetos aceitam `z_index` (padrão 0): use 1 para um objeto apoiado sobre um móvel fatiado,
  como o liquidificador em `[318,186]` na ilha da Casa. O campo altera a camada visual,
  sem criar bloqueio de chão; o liquidificador não tem `footprint` e reage em `[300,292]`.

### Receita para novos mundos

1. **Arte:** gere a cena no PixelLab no mesmo estilo (ex.: `create_image_pro` 632x395, sem fundo
   transparente, com `farm.png` como referência de estilo: "ilha isométrica flutuante, fundo escuro").
   Salve em `game/assets/sprites/areas/<mundo>/background.png`. Registre em `docs/ART_PIPELINE.md`.
2. **Sala:** `game/data/rooms/<mundo>.json`:
   ```json
   { "background": "res://assets/sprites/areas/<mundo>/background.png",
     "objects": [],
     "zones": [
       { "id": "barraca", "action": "place:sell", "label": "Vender", "label_pos": [228, 72],
         "polygon": [[165, 120], [245, 85], [290, 140], [215, 222]] },
       { "id": "casa", "action": "npc:artisan", "label": "Artesã", "label_pos": [425, 32], "polygon": [...] }
     ],
     "points": {} }
   ```
   - `zones` = áreas tocáveis do desenho (polígono em pixels da imagem); `label` + `label_pos` =
     etiqueta que mostra ao jogador que dá para tocar ali (fica com o mesmo tamanho em qualquer zoom).
   - Sem `floor` = ninguém anda (só toques). Com `floor` + `points.dog_start` o Tiro passeia lá
     (Casa, Sítio e Vila). Móveis separados vão em `objects` (ver `CLAUDE.md`, "Ambientes").
   - `objects[].footprint` bloqueia móveis e canteiros; `obstacles` contém polígonos dos
     elementos desenhados no fundo (`{ "id": "arvore", "polygon": [...] }`). As `zones`
     continuam sendo somente áreas de toque: não use sua área inteira como colisão sem
     conferir a arte. No fundo plano, bloqueie também a silhueta de casas/árvores para o Tiro
     não aparecer sobre telhados/copas (esses elementos não têm ordenação por Y separada).
   - `navigation_margin` dá folga nos cantos de cada célula (padrão 4 px; mapas externos 8 px).
   - `dig_spots` (lista de `[x, y]`, 6–10 pontos) = onde o Tiro fareja e aparece o montinho do Faro (`finds.json`); precisam estar no chão alcançável (o `finds_test` confere).
     `dog_scale` ajusta a proporção do Tiro à arte de cada mapa, incluindo sombra e área de toque
     (padrão 1; Sítio e Vila usam 0,5, pois as construções externas são menores na imagem).
     O Tiro nasce numa célula livre perto de `dog_start`, sorteia destinos alcançáveis e nunca
     acrescenta um trecho direto até um alvo bloqueado. `bowl`, `sleep` e `sleep_approach` são
     opcionais: sem esses pontos, ele não procura a tigela e dorme no chão onde estiver.
   - Para achar coordenadas: abra a imagem, ou gere uma prévia com `tools/pixel_tools.ps1`.
3. **Mundo:** entrada em `game/data/worlds.json`:
   ```json
   "praia": { "name": "Praia", "icon": "tab_beach", "description": "...", "room": "praia",
              "requirements": { "owned": ["boat"] },
              "npcs": ["fisher"],
              "places": { "fish": { "name": "Pescar", "icon": "...", "description": "...", "panel": "routes:fish" } } }
   ```
   - `requirements` usa o formato comum (`owned`/`quests`/`skills`/`chapter`); mundo fechado aparece no
     mapa com o motivo.
   - `panel` dos lugares: `station:<id>`, `stations:<id>+<id>`, `inventory`, `feed`, `sleep`, `farm`,
     `market:<sell|orders>`, `routes:<tipo>+<tipo>`, `travel:<mundo>` (lista em `scripts/ui/places.gd`).
     `upgrade` opcional: sem essa construção, tocar abre a compra. `upgrades`: compras dentro do painel.
     `requirements`: lugar fechado até cumprir. `hidden`: fora da lista "Lugares".
     **No máximo 4 lugares visíveis por mundo.**
   - Sem `room`, o mundo ainda funciona: vira uma tela com a imagem `banner` + cartões dos
     personagens e lugares (bom para prototipar antes da arte).
4. **Personagens:** em `game/data/npcs.json` (`name`, `role`, `greeting`, `portrait`, `icon`,
   `services` = lugares do mundo que ele oferece como atalho). Missões em `quests.json` com `"npc"`.
5. **Conteúdo:** rotas (`activities` com `"place"`), construções (`upgrades` com `"world"`),
   receitas/estações etc.
6. **Teste:** `progression_test.gd -- --screenshots` gera `ui_world_<mundo>.png` para os mundos
   da lista do teste (acrescente o novo), e a campanha simulada valida o progresso.
   `navigation_test.gd` verifica 100 caminhos por mapa, incluindo cada trecho entre células,
   limites do piso, obstáculos, destinos sem rota e sono nos mapas externos.

Nenhum código precisa mudar para um mundo novo, a não ser que ele traga um **tipo de painel novo**
(aí: um caso em `Places._panel` + a função que monta o painel).

## Código
| Arquivo | Papel |
|---|---|
| `scenes/ui/worlds_screen/` | Aba Mapa: lista de mundos + mundo atual (instancia `levels/room/room.tscn` por mundo e mantém em memória). `enter(mundo, lugar)`. |
| `scripts/ui/places.gd` (`Places`) | Abre lugares/personagens (`open`, `open_npc`, `run`), lista "O que tem aqui?" (`world_list`) e calcula avisos (`world_alerts`, `npc_alert`, `place_alert`). |
| `scripts/ui/progression_ui.gd` | Painéis: personagem, construir (por mundo), vender, encomendas, rotas, atributos, coleção. |
| `scenes/ui/tasks_screen/` | Aba Missões. |
| `scenes/ui/bag_screen/` + `SheetBuilder.inventory_view/item_detail` | Aba Mochila (e geladeira). |
| `Events.world_requested(mundo, lugar)` | "Ir até lá": `main.gd` troca para o Mapa e entra no mundo; `lugar` = `"<lugar>"`, `"npc:<id>"` ou `"buy:<construção>"`. |
| `Database.npc_world`, `place_with_panel`, `sources_of`, `uses_of` | Consultas de conteúdo usadas pela navegação e pela Mochila. |


## Acesso gradual (Tarefas v2)

Casa e Sítio são abertos. Vila exige `quests: ["first_harvest"]`; o Portão da trilha (lugar da Vila)
exige `chapter: 3`. Pedidos da Vila e rotas de passeio/mina repetem esses requisitos.
O capítulo é derivado das principais recebidas (comprar a geladeira não basta).
A comemoração anuncia mundos recém-abertos; o mapa mostra o motivo dos bloqueios.
Toda missão deve ter um destino válido e acessível quando liberada: valide com
`content_test.gd` e a campanha simulada. `Places.goal_target` produz
`{world, place, hint}` ou `{screen, hint}` para cuidados na aba Tiro.

## Revelar aos poucos (simplificação, fase 4)
- **Começo:** abas Tiro, Mapa (Casa) e Missões. A Mochila aparece após a primeira colheita; diárias no
  capítulo 2; semanais e Atributos no capítulo 3 (`progression.json → features`).
- **Personagens:** `npcs.json → requirements` (Feirante cap. 2, Guia cap. 3, Laís cap. 4). Escondidos no
  cabeçalho, no mapa e em "Lugares" até lá (`Places.visible_npcs`). O `content_test` garante que nenhum
  aparece depois do capítulo da primeira missão dele.
- **"Novo!":** ao concluir passos, tudo o que abriu (recursos, mundos, lugares e personagens com requisito)
  aparece numa tela com ícone + **Ir** — junto da comemoração quando o capítulo termina. Cada novidade aparece
  uma vez (`ProgressionState.seen`; saves antigos marcam como visto o que já estava aberto).
- **Seta do Ir:** `Places.highlight_action` traduz o destino ("recipe:x", "buy:oven", "market:orders"...) para o
  objeto/zona da sala; `RoomView.point_at` desenha a seta pulsando; o painel abre `POINT_DELAY` (0,8 s) depois.

## Praça (Etapa 06)

- Mundo `park` (`worlds.json`, entre `farm` e `village`; abre com `quests: ["main_2_order"]`, a primeira
  encomenda). Sala `rooms/park.json` (fundo `areas/park/park.png`, `dog_scale` 0,5): zona `walk_gate`
  (`place:walk`, etiqueta "Passeio") e pontos `dog_start`, `npc_nina`, `npc_dog_pipoca`, `walk_marker`.
- `walk_marker` = onde o `WalkIndicator` (tempo / "Recolher") aparece; tocar nele ou no portão com o
  passeio pronto recolhe direto. O lugar `walk` usa o painel `walks` (`ProgressionUi.walks_panel`).
- NPC com `"decor": true` (Pipoca): sem conversa, balão, "Novo!" nem lista de personagens; tocar faz
  pulinhos. `"follow": "<npc>"`: escolhe destinos a até 40 px do personagem seguido (`RoomView.floor_point_near`).
- Enquanto `GameState.walking()` o `RoomView` não mantém o `DogWorld` (casa, sítio, praça...) e o recria no
  `dog_start` ao recolher. Passeios: `data/walks.json`, `WalkState`, `GameState.start_walk/collect_walk/cancel_walk`.
- Achados da praça: `finds.json → worlds.park` (a tabela também alimenta `"find": "park"` dos passeios).

## Pet shop da Praça (Etapa 08)

`park.places.petshop` abre após `nina_rare`; `upgrade: petshop` representa a montagem inicial.
`upgrades: [sewing_table, walk_bag]` dá destinos às compras; o painel `petshop` as dispõe nos blocos
Costura/Comprar sem duplicar cartões genéricos. `Database.panel_parts("petshop")` também atende
`station:sewing`, portanto Manual/ajuda/avisos/Ir resolvem a estação no quiosque.

O fundo já tem toldo e balcão: as novas peças são placa/mercadorias e a pequena mesa, com
`z_index` 1/2 e sem footprint. Os quinze obstáculos anteriores permanecem, sem duplicar bloqueios
ou estreitar corredores. A mesa usa `station: sewing` para tempo/Coletar e toque de coleta direta.
Roupas aparecem somente no Tiro detalhado/retratos; o cachorro do mapa mantém seus sprites.

## Amigos na Praça e visitas na Casa (Etapa 09)

Praça mantém 15 obstáculos e três lugares visíveis (Passeio, Pet shop, Amigos), abaixo do limite 4.
`points.friend_1 = [370, 230]` fica em chão alcançável; a zona `friends` usa o mesmo gramado,
sem novo obstáculo. `RoomView._sync_friends` observa estado e confere presença a cada minuto.
Pipoca conserva `npc_dog_pipoca`, escala e `follow: nina`; `NpcWorld.friend_id` apenas troca o toque
e o balão quando a amizade fica acessível. Visitantes usam o mesmo NpcWorld e caminhos.

Casa usa `points.friend_visit = [400, 310]`; amigos com presente pendente andam perto do Tiro
(ou do ponto quando ele está passeando). Toque recolhe com CollectFx e aceno; cheio mantém o amigo.
Alvos `friend:<id>` e `friend_visit:<id>` são resolvidos por Places/RoomView; o Ver das boas-vindas
emite `look:friend_visit:<id>` para apontar sem entregar automaticamente.

### Treino da Praça — Etapa 10

Quarto lugar visível `park.places.training`, painel `tricks`, aberto após `nina_pipoca`; também disponível nos serviços da Nina. Zona `training` sobre os cones já desenhados, polígono `[[105, 182], [148, 174], [188, 198], [156, 220], [114, 210]]`, etiqueta `[136, 168]`. Não altera os 15 obstáculos, amigos ou acesso ao portão/quiosque. `Places.goal_target` usa Treino para `trick_learned` e a tela Tiro para `trick`/`trick:<id>`.

### Baú da Clareira — Etapa 11

`rooms/nature.json → objects` ganhou `treasure_chest` (ação `treasure`, `pos [96, 222]`, escala 1,6, grama livre à esquerda da ponte). Dois campos novos de objeto no `RoomView`: `"requirements"` (o objeto só existe — visível, tocável e bloqueando o chão — depois que valem; a etiqueta "Clareira escondida" segue o mesmo requisito) e `"seen_sprite": {"key", "sprite"}` (troca o desenho quando `progress.seen[key]` existe; aqui o baú aberto). O mapa da Natureza não tem espaço livre para uma clareira desenhada, então não há região fechada nem arte de clareira (ver ART_PIPELINE). Tocar no baú chama `GameState.open_treasure()`, com CollectFx e a festa "Tesouro encontrado!".
