# Plano "Pesca na lagoa da vovó"

> Pedido do Vitor (11/11/2026): um minigame de pesca na **lagoa do Sítio**, no modelo "segurar = a barra
> sobe, soltar = cai" (especificação técnica dele, resumida em [01_DESENHO.md](01_DESENHO.md) §1). A pesca
> começa **no meio da fase Filhotinho**, porque o peixe é ingrediente de pratos que o Tiro **precisa comer**
> para crescer. **3 varas**, cada uma pega **3 peixes reais**; o **tamanho** do peixe é sorteado e depende da
> pontuação, e fica registrado (recorde por espécie). As duas varas melhores vêm **ao longo da história**
> (compra na Vila e missão). **Iscas** se compram. Tutorial muito bom. Objetivo extra: **dar mais tempo de
> jogo** entre os crescimentos do Tiro. Álbum/fotos de pesca ficam **para depois**.

Estado: **plano CONCLUÍDO localmente (etapas 00–10, 12/11/2026)**; ritmo APROVADO pelo Vitor em 12/11/2026 (equilíbrio fica para ele rever depois; ver "Registro da 10" e `RESULTADOS.md`). Sem commit/push/publicação.

## A ideia em uma linha

> **A vovó Bloblo empresta a vara de bambu dela e ensina a pescar na lagoa.** Você compra minhocas, arremessa,
> espera a boia afundar, fisga e segura o peixe dentro da barra até a rede encher. O peixe vira **papinha de
> peixe** para os Dentinhos do Tiro; depois vêm a vara de molinete (Vila), a vara do pescador (missão), peixes
> maiores, pratos que dão brilho ao pelo e um caderno com o recorde de cada espécie.

## Respostas do Vitor (11/11/2026) — fechadas

| Pergunta | Decisão |
|---|---|
| Gravidade ao segurar | **A opção que deixa o jogo mais fácil.** Ponto de partida: a fórmula dele (a gravidade some ao segurar, subida leve e rápida). Na etapa 00 o protótipo tem as duas opções lado a lado e fica a mais fácil de controlar, confirmada jogando. |
| Papinha × Cenoura gelada | **Soma**: os Dentinhos pedem as duas. |
| Vara 3 | **Guia da trilha**, por enquanto (pode virar outro personagem depois). |
| Peixe Gigante | **Vale 2 peixes.** |
| Lixo na margem | **Sem lixo.** |
| Oferta do dia na banca | **Sim** (ligada na etapa 10, depois de medir o ritmo). |
| Arte | **Tudo no PixelLab** (pixel art), por enquanto. Pista, barra e rede do minigame são montadas das peças de madeira que já existem. |

As decisões abaixo (1–13) valem como estão; as perguntas do fim do arquivo estão respondidas aqui.

## Decisões do plano

| # | Decisão proposta | Por quê |
|---|---|---|
| 1 | Quem ensina: **vovó Bloblo** (a lagoa é do sítio dela). Ela dá a **vara de bambu** + 5 minhocas. | Ela já conduz o capítulo 2 no Sítio; não precisa de personagem novo. |
| 2 | Começa no **capítulo 2**, logo depois de "Mãos na terra" (`lais_first_crops`), ainda Filhotinho. | É o meio exato da fase (Filhotinho vai do fim do cap. 1 até o fim do cap. 3). |
| 3 | O primeiro prato de peixe (**Papinha de peixe**, fogão) é **requisito novo dos Dentinhos**: dar 2 porções. A Cenoura gelada continua. | Faz o peixe ser "primordial" e dá mais tempo à fase, sem tirar nada que já existe. |
| 4 | **Iscas por tipo de peixe**: Minhoca (peixes da vara 1), Massa de milho (vara 2), Isca artificial (vara 3). A isca escolhe **qual grupo** morde; a vara decide **o que você aguenta** (barra maior, grupos liberados). | Simples de entender (uma escolha), realista (peixe predador come isca artificial; carpa e pacu comem massa). |
| 5 | A isca é gasta **na fisgada** (quando o peixe morde). Errar o toque da fisgada não gasta; o peixe escapar gasta. | Justo e fácil de explicar: "a minhoca foi junto com o peixe". |
| 6 | Minhoca: compra na **banca do Sítio** (aba nova **Comprar**, ver decisão 13) e às vezes aparece ao colher na horta. Massa de milho: faz no fogão ou compra no Feirante. Isca artificial: só compra no Feirante (depois da vara 3, também se faz na bancada). | Iscas compradas, como o Vitor pediu; a minhoca da horta evita travar quem ficou sem moeda no começo. |
| 13 | **A banca do Sítio vende E compra** (pedido do Vitor, 11/11): a banca da vovó ganha duas abas, **Vender · Comprar**. O mesmo componente vale para o Feirante da Vila. O catálogo é genérico (`progression.json → shops` + `shop_items`), serve para iscas agora e para outras coisas do jogo depois (ração, oferta do dia…). | Uma loja só, já onde o jogador vende; abre espaço para futuras compras sem tela nova. |
| 7 | **Tamanho em cm**, sorteado na faixa real da espécie, puxado pela pontuação. Quatro classes: Pequeno, Médio, Grande, **Gigante**. Peixe Gigante rende **2 peixes** no inventário. | Dá motivo para jogar bem sem mudar o item (o peixe empilha normal na geladeira). |
| 8 | **Recorde por espécie** (maior cm, quantos pegou, primeira vez) no **Caderninho → Coleção → Peixes** (filtro novo, sem aba nova). | Já existe a coleção em madeira; peixe que falta aparece como sombra com "?". |
| 9 | Peixe que escapa não dá nada além da lição; nunca há "lixo" (bota velha) na lagoa. | Jogo aconchegante; o risco já é perder a isca. |
| 10 | **Tiro animado** (já existe) dá **barra 10% maior** e o Tiro senta na margem latindo quando a boia afunda. | Mantém o Tiro no centro; reaproveita a regra que já ajuda horta, passeio e faro. |
| 11 | A física segue a especificação do Vitor, **em frações da pista** (não em pixels), para caber nas três resoluções. | 568 px não cabem em 360×780 com HUD e abas. |
| 12 | Saves **zerados**: subir `SAVE_VERSION` na etapa 01 (regra do Vitor, sem migração). | Regra do projeto. |



## Documentos

| Arquivo | O que decide |
|---|---|
| [01_DESENHO.md](01_DESENHO.md) | Minigame (física, medidor, comportamentos, arremesso, baú), varas, iscas, os 9 peixes, tamanho e recorde, números do `fishing.json`. |
| [02_HISTORIA_E_TUTORIAL.md](02_HISTORIA_E_TUTORIAL.md) | Missões da história e da linha da vovó, pratos e requisitos de crescimento, roteiro do tutorial passo a passo, diárias/encomendas. |
| [03_INTERFACE_E_ARTE.md](03_INTERFACE_E_ARTE.md) | Telas (lagoa no mapa, arremesso, minigame, resultado, caderno), arte a gerar e capturas. |
| [04_BANCA.md](04_BANCA.md) | Banca do Sítio com Vender · Comprar: motor genérico de lojas, catálogo, limites, tela. |

## Regras gerais para todas as etapas

- Uma etapa por sessão, em ordem. Cada etapa termina com: testes da lista dela PASS, capturas abertas e
  conferidas nas três resoluções (360×780, 390×844, 412×915) e a seção "Estado atual" do `docs/ROADMAP.md`
  atualizada. Sem commit/push/publicação até o Vitor pedir.
- **Conteúdo em JSON** (`game/data/fishing.json` + `items.json`, `recipes.json`, `quests.json`,
  `growth.json`, `progression.json`). Código sem números fixos.
- **Estado só no `GameState`** (classe `scripts/state/fishing_state.gd`); ações com `*_error()`.
- O minigame em si roda **ao vivo** (não é timer de app fechado). Ao sair do app no meio, a partida é
  cancelada **sem gastar a isca** (a isca só é gasta na fisgada e devolvida se o app fechar antes do fim).
- Interface no padrão **madeira ilustrada** (`StepCardUi`, `SellUi`, `ModalCard`, `Sheet` com `sheet_bare`).
- Testes em níveis (`tools/test.ps1`): teste novo + áreas afetadas por etapa; portão só na 06 e na 10;
  campanha (progression_test + simulador Quick) só na 10. Registrar cada teste novo em
  `tools/test_areas.json` (área nova `fishing`).
- Toda captura que mede layout falha (FAIL) se algo sair da tela, ficar sob o HUD/abas, alvo < 44 px ou
  texto cortado — como `sell_shots.gd`/`walks_wood_shots.gd`.

## Etapas

Cada etapa tem um arquivo próprio em [`etapas/`](etapas/) com: o que ler antes (com arquivos e linhas do
código atual), como está hoje, passo a passo numerado, o que **não** fazer, armadilhas, testes numerados,
capturas, critério de pronto e um **prompt pronto** para mandar a outro agente.

| # | Arquivo | Entrega | Depende | Portão do Vitor |
|---|---|---|---|---|
| 00 | [ETAPA_00_PROTOTIPO.md](etapas/ETAPA_00_PROTOTIPO.md) | Minigame isolado jogável (`FishingSim` + `FishingGame`), física no `fishing.json`, ajuste fino | — | **Sim**: a sensação |
| 01 | [ETAPA_01_MOTOR.md](etapas/ETAPA_01_MOTOR.md) | `FishingState`, `cast/hook/finish_fishing/cancel_fishing`, sorteio, tamanho, recorde, bolhas, requisito `rod`, `SAVE_VERSION` 20 | 00 | — |
| 02 | [ETAPA_02_LAGOA.md](etapas/ETAPA_02_LAGOA.md) | Toque na lagoa, Tiro na margem, painel de arremesso, força, boia, mordida, minigame real, resultado | 01 | — |
| 03 | [ETAPA_03_ARTE.md](etapas/ETAPA_03_ARTE.md) | 9 peixes, 3 varas, 3 iscas, boia, respingo, bolhas, peças de madeira do minigame | 02 | **Sim**: arte |
| 04 | [ETAPA_04_BANCA.md](etapas/ETAPA_04_BANCA.md) | Lojas genéricas; banca da vovó e Feirante com abas Vender · Comprar | 01 | — |
| 05 | [ETAPA_05_TUTORIAL.md](etapas/ETAPA_05_TUTORIAL.md) | Capítulo 2: vovó dá a vara, tutorial de 13 passos, 5 missões, robô pesca no simples | 02, 03, 04 | — |
| 06 | [ETAPA_06_PAPINHA.md](etapas/ETAPA_06_PAPINHA.md) | Papinha de peixe, requisito novo dos Dentinhos (soma à cenoura), minhoca ao colher; **portão de testes** | 05 | — |
| 07 | [ETAPA_07_VARA2.md](etapas/ETAPA_07_VARA2.md) | Vara de molinete no Feirante, carpa/pacu/tambaqui, massa de milho, baú, ensopado, Aventureiro | 06 | — |
| 08 | [ETAPA_08_VARA3.md](etapas/ETAPA_08_VARA3.md) | Vara do pescador (Guia, bancada), traíra/tucunaré/pintado, isca artificial, peixe com ervas (Pelagem), Mocinho | 07 | — |
| 09 | [ETAPA_09_CADERNO.md](etapas/ETAPA_09_CADERNO.md) | Coleção → Peixes com recordes, detalhe da espécie, diárias/semanais, encomendas, petisco de lambari | 08 | — |
| 10 | [ETAPA_10_FECHAMENTO.md](etapas/ETAPA_10_FECHAMENTO.md) | Robô pescador, ritmo medido, oferta do dia, portão + campanha, roteiro do celular | 09 | **Sim**: ritmo |

### Como mandar para outro agente

1. Mande **só a etapa 00** (prompt pronto do fim de `etapas/ETAPA_00_PROTOTIPO.md`); as próximas se abrem
   sozinhas pela seção "Sessões encadeadas" abaixo, parando nos portões.
2. O agente lê `CLAUDE.md`/`AGENTS.md`, este README, os documentos de desenho citados e o arquivo da etapa.
3. Ao terminar, ele escreve o **"Registro da NN"** no fim deste README (o que fez, nomes novos de funções/nós,
   decisões tomadas, testes e capturas, pendências) e atualiza o "Estado atual" do `docs/ROADMAP.md`.
   O próximo agente começa lendo esses registros.
4. Nas etapas com portão (00, 03, 10) o agente **para** e espera o Vitor.
5. Nenhum agente faz commit, push ou publicação sem o Vitor pedir.

### Sessões encadeadas (pedido do Vitor, 11/11/2026)

Cada etapa roda numa **sessão própria de Sonnet 5.5**. **Ao terminar uma etapa concluída** (critério de pronto
cumprido e o "Registro da NN" escrito), o agente abre uma sessão nova para a próxima com a ferramenta
`create_session` (servidor `claude-code-remote`), com:
- `model`: `claude-sonnet-5-5`;
- o **mesmo ambiente** (o computador do Vitor, a mesma pasta do projeto; não precisa de commit nem push);
- `title`: `Pesca — Etapa NN` (NN = a próxima);
- `prompt`: o bloco "Prompt pronto" do fim do arquivo `etapas/ETAPA_NN_*.md` da próxima etapa, inteiro.

Depois disso a sessão atual para de mexer em arquivos e responde ao Vitor com um resumo curto e o nome da sessão
aberta.

**Não abrir a próxima sessão quando:**
- a etapa não foi concluída (falhou, ficou pela metade ou tem bloqueio): registrar no README e avisar o Vitor;
- é **portão do Vitor** (00, 03 e 10): a sessão termina "aguardando aprovação do Vitor" e só abre a próxima
  **depois** que o Vitor aprovar nessa mesma conversa;
- a ferramenta recusar (limite de sessões encadeadas, ambiente indisponível): avisar o Vitor para abrir a próxima
  à mão, colando o "Prompt pronto" da próxima etapa numa sessão nova de Sonnet 5.5;
- o Vitor pediu para parar.

A 10 é a última: não abre outra.

### Contrato entre etapas (nomes que as próximas usam)

| Nome | Criado na | Usado nas |
|---|---|---|
| `game/data/fishing.json`, `Database.fishing`, `Database.fishing_problems()` | 00/01 | todas |
| `FishingSim` (`scripts/fishing/fishing_sim.gd`), `FishingGame` (`scenes/ui/fishing/`) | 00 | 02, 05, 07 |
| `FishingState` (`GameState.fishing`, chave `fishing` no save) | 01 | todas |
| `GameState.fishing_info/fishing_error/cast/hook/miss_bite/finish_fishing/cancel_fishing/release_fish/fishing_bar_height/give_rod` | 01 | 02, 05–10 |
| Requisitos `{"rod": id}` e `{"fishing_level": n}`; recompensa `"rods": [...]` | 01 / 07 | 04–09 |
| Contadores `fish`, `fish:<id>`, `fish_size:<classe>[:<id>]`, `fish_perfect`, `fish_gigante`, `fish_escape`, `rod:<id>`, `bought:<item>` | 01 / 04 | 05–10 |
| Sinais `fishing_changed`, `fish_bite`, `fish_caught`, `fish_escaped`, `fishing_level_up` | 01 | 02, 05, 07 |
| Lugar `farm.places.fishing`, zona `lake`, pontos `fishing_spot/fishing_face/fishing_bubbles` | 02 | 05–10 |
| `FishingPanel`, `FishingBobber`, `FishingBubbles`, `FishResult` | 02 | 03, 05, 07, 08 |
| `progression.json → shops`, `shop_items` com `requirements/max/daily/rods/materials`, `GameState.shop_items/buy_shop_item(id, qty)`, ação `shop:<id>` | 04 | 05, 07, 08, 10 |
| `AnglerTutorial`, `fishing.tutorial`, dicas `fishing_tip:<id>` | 05 | 07 |

## Perguntas para o Vitor (respondidas em 11/11 — ver "Respostas do Vitor" no topo)

1. **Gravidade ao segurar:** na sua fórmula a gravidade some enquanto o dedo está apertado (subida rápida).
   Quer assim, ou a gravidade continua puxando (subida mais pesada, mais difícil)? *Proposta: como na sua
   fórmula; ajustamos na etapa 00.*
2. **Requisito dos Dentinhos:** a papinha de peixe **soma** à cenoura gelada (proposta) ou **substitui**?
3. **Vara 3 por missão de quem?** Proposta: o Guia da trilha (Natureza), porque ele ensina materiais e a
   vara usa madeira dura e fibra. Alternativa: um pescador novo na Vila (personagem e arte novos).
4. **Gigante = 2 peixes** (proposta) ou só o recorde/moedas extra?
5. Quer **lixo** (bota velha, lata) na margem como no Stardew? Proposta: **não**.
6. **Banca:** além de iscas e ração, quer a **oferta do dia** (um material em pouca quantidade, ex.: 2 madeiras,
   com limite diário) para quem travar? Proposta: sim, mas ligada só na etapa 10, depois de medir o ritmo.

## Registros das etapas

(Cada agente acrescenta aqui o "Registro da NN" ao terminar.)

### Registro da 00 — protótipo do minigame (11/11/2026, local; aguardando o portão do Vitor)

- **Feito:** `game/data/fishing.json` (só `physics`, `meter`, `motion`, `proto_fish`; `Database.fishing`), motor puro `FishingSim` (`scripts/fishing/fishing_sim.gd`: passo fixo acumulado, máx. 10 passos por chamada, sem nó/relógio; `step(holding, delta)`, `score()`, estado público `bar_y/bar_v/bar_h/fish_y/meter/elapsed/inside_time/outside_time/bursts/finished/caught/perfect`, `rod` opcional com `hold`/`bounce`, perfil de teste `still: true`) e a cena provisória `FishingGame` (`scenes/ui/fishing/`, sinal `closed`, `track_rect()/meter_rect()/json_block()`; segurar em qualquer lugar da tela sobe a barra; toque conta por índice do dedo e o mouse emulado é ignorado; ferramentas `Proto_<perfil>`, `ProtoGravity` ("Segurar: leve/pesado"), `ProtoMinus_/ProtoPlus_<campo>` para subida, gravidade, atrito, enche, esvazia, barra, e `ProtoDump` "Copiar JSON", que também imprime ao "Sair"). Abrir: DEV → Recursos → "Pesca (protótipo)" (`DevPanel._open_fishing_proto`, CanvasLayer 20) ou `godot -s res://tests/fishing_proto.gd -- --fish=<perfil> --seed=N` (sem `--headless`). Roteiro de toque `tests/touch/fishing_proto.json` (coordenadas do DEV a conferir na 1ª execução; **não rodado**: exige export + `serve_local`).
- **Decisões:** `inside_time` conta só depois da folga `grace` (assim `score()` fica coerente em 0–1); "alvo abaixo/acima" do `sinker`/`floater` é relativo à posição atual do peixe; o ruído do `mixed`/`darter` é aditivo (não acumula); números do movimento (distâncias, ruído, pista [0,02; 0,98]) estão em `fishing.json → motion`. Nenhum número fixo no motor além do limite de 10 passos. Tendência do sinker/floater é média de sementes (com `biased` 0,75 deu ~70%; uma semente isolada pode ficar em ~55%).
- **Gravidade (decisão do Vitor = a mais fácil):** o padrão ficou `gravity_on_hold: false` (a gravidade some ao segurar, subida rápida) como ponto de partida; o Vitor confirma jogando com `ProtoGravity` e a escolha final é anotada aqui depois do portão.
- **Testes:** `fishing_physics_test` (10 casos do plano + limite de passos e folga) PASS em 3,3 s; `test.ps1 -Level etapa -Exact -Tests fishing_physics_test,content_test` PASS (35,6 s). Área `fishing` criada em `tools/test_areas.json` e teste na `suite`.
- **Capturas:** `tests/fishing_proto_shots.gd` (sem `--headless`) → `build/screenshots/fishing_proto/proto_<res>_{a_comeco,b_meio,c_pegou,d_escapou}.png` nas três resoluções, PNGs abertos; mede pista entre HUD (168) e abas (100), pista/rede na tela e ferramentas sem encostar: PASS nas três.
- **Pendências para o Vitor aprovar (portão):** jogar os 5 perfis (Tilápia/mixed, Cará/smooth, Carpa/sinker, Lambari/floater, Tucunaré/darter), comparar `Segurar: leve` × `pesado`, ajustar com −/+ e colar o bloco do "Copiar JSON" no `fishing.json`; dizer "está bom" ou o que mudar. Só então abrir a etapa 01. **A 01 não foi aberta.**

### Registro da 01 — motor da pesca (11/11/2026, local)

- **Portão da 00:** o Vitor aprovou ("vamos seguir assim"). Ele aplicou no `fishing.json` `physics.bar_base` 0,459 e `meter.fill` 0,22 (preservados). **Atenção para o Vitor decidir:** `bar_base` 0,459 passa de `physics.bar_max` 0,34, então `fishing_bar_height()` sempre devolve 0,34 e nível de pesca, vara e Tiro animado não mudam a barra (o teste 15 usa `bar_base` 0,169 em memória para medir a soma). Para a progressão da barra voltar a existir, ou sobe `bar_max` ou baixa `bar_base`; não mexi.
- **Feito:** `FishingState` (`scripts/state/fishing_state.gd`; `GameState.fishing`, chave `fishing`; `SAVE_VERSION` 20, saves zerados), `fishing.json` completo (`cast`, `bubbles` com `spots`, `chest`, `classes`, `size_formula`, `pity_large`, `levels`, `rods`, `baits`, `fish`, `story_guarantee`, `story_share`, `moment_first`), 9 itens `fish_*` (`product`, `storage fridge`, sem `feed`) e 3 `bait_*` (`material`, `storage none`, `sell_price 0`) com ícone provisório e `icon_todo` (o `content_test` só aceita em `fish_*`/`bait_*`; a 03 remove), fonte `fish_first` em `growth.json`, `Database.fishing_problems()` no `content_test`, aba DEV "Pesca".
- **Nomes para as próximas etapas:** `GameState.fishing_info/fishing_error/choose_rod/choose_bait/cast_error/cast(bait, zona, na_bolha)/bite_due/hook_error/hook/miss_bite/finish_fishing_error/finish_fishing(result)/release_fish_error/release_fish/cancel_fishing/fishing_bar_height/give_rod/current_rod/has_rod/fishing_level/update_fishing`; `result = {caught, score 0..1, perfect, chest}`; `fishing.cast` = {seed, n, bait, rod, zone, bubble, at, wait, state waiting|fighting|interrupted, fish, spent, bitten, pending_result}; requisitos `rod` e `fishing_level`, recompensa `"rods": [...]`; sinais `Events.fishing_changed/fish_bite/fish_caught(fish_id, cm, classe, recorde_anterior)/fish_escaped/fishing_level_up`; contadores `fish`, `fish:<id>`, `fish_size:<classe>[:<id>]` (classes `small/medium/large/giant`; Gigante também soma em `fish_size:large`), `fish_perfect`, `fish_gigante`, `fish_escape[:<id>]`, `fish_miss`, `fish_hook`, `fish_release`, `rod:<id>`.
- **Decisões:** (1) `proto_fish` ficou no `fishing.json` (o plano mandava tirar) porque a cena do protótipo e o `fishing_physics_test` ainda leem; a 02/03 podem removê-lo junto com o protótipo. (2) Perfeita sobe uma classe E leva `f` ao mínimo dela (o cm acompanha a classe). Com a fórmula do desenho, nota 1 + perfeita dá sempre Grande ou Gigante (Gigante só com sorte ≥ 0,33 na zona 1); o teste 6 confere "Grande+ sempre e o Gigante aparece". (3) Garantia da tilápia e do lambari do tutorial só valem com minhoca; o tutorial não encerra sozinho (a 05 grava `tutorial.done`); `dev_give_rod` encerra o tutorial para o DEV pescar normal. (4) Ao carregar: linha lançada sem fisgada some (nada gasto); luta sem resultado guardado devolve a isca e vira `interrupted` (o peixe sorteado fica no save, mas já dá para lançar de novo); luta com `pending_result` (geladeira cheia) é mantida. (5) `finish_fishing` com `pending_result` usa o resultado guardado, não o novo. (6) A bolha não some ao arremessar nela (dura os 10 min); a primeira bolha é marcada ao ganhar a primeira vara. (7) Mordida sem fisgar em `bite_window` (1 s, sem limite no tutorial) é limpa pelo tick e conta `fish_miss`. (8) Baú só com vara de tier ≥ `chest.from_rod`; vara 1 ignora `chest: true`.
- **Testes:** `fishing_test` (16 casos do plano + validação do resultado, baú, isca artificial, recompensa `rods`) PASS, repetido 5× (semente do save é aleatória); afetados `content_test`, `texts_test`, `fishing_physics_test`, `saves_test`, `storage_test`, `dev_tools_test` e `scripts_check` PASS (`test.ps1 -Level etapa -Exact`, 66,5 s).
- **Pendências:** nenhuma de código; a decisão do `bar_max` é do Vitor. Sem commit/push/publicação.

### Registro da 02 — lagoa no Sítio, fluxo de ponta a ponta (11/11/2026, local)

- **Feito:** a lagoa é jogável com a vara (DEV → Pesca: "Dar vara" + "+10 de cada isca"). Tocar na água → a câmera enquadra a lagoa acima do painel, o Tiro corre à margem e senta olhando a água (reação `fishing` do `DogWorld`, `fishing_session`/`fishing_face`/`fishing_bite()`; late na mordida) → bandeja de madeira `FishingPanel` → segurar "Arremessar" (barra de força Perto/Meio/Longe) → boia na água (`FishingBobber`) → mordida (boia afunda 2×, "!" e vibração) → toque fisga → minigame de verdade (`FishingGame` modo ao vivo) → cartão `FishResult` → "Pescar de novo". Sem vara, tocar na lagoa mostra só o aviso da vovó (`npcs.json → bloblo.lines.lake_locked`, com o rosto dela).
- **Gerador:** `tools/build_farm_island.py` acrescenta a zona `lake` (`place:fishing`, só a água recolhida ~6 px do obstáculo), os pontos `fishing_spot`, `fishing_face` e `fishing_bubble_1..4` (4 porque `bubbles.spots` = 4; o plano dizia 3). `farm.json` regenerado; diferença só nesses campos. Lugar `farm.places.fishing` (`hidden`, requisito `rod`, ícone provisório `coin`); entra na lista "Lugares" (`Place_fishing`) depois da primeira vara.
- **Nomes novos (contrato):** `FishingFlow` (`scripts/ui/fishing_flow.gd`, filho da sala; `state` idle|panel|waiting|fighting|result; `begin/end/handle_tap/landing_for`), `FishingPanel` (`scripts/ui/fishing_panel.gd`; nós `FishingLevel`, `RodRow`/`Rod_<id>`, `BaitRow`/`Bait_<id>`, `BaitFish`, `CastPower`, `CastButton`, `Locked_CastButton`; `power_override` p/ teste; estático `current/is_open/close_current`), `FishingBobber`, `FishingBubbles` (`active_spot/spot_position`), `FishResult` (`show_caught/show_full`; `FishSize/FishClass/FishRecord/FishFirst/FishRuler/FishAgain/FishLeave`, `Locked_Fridge/FishFreeSpace/FishRelease`), `FishingGame.open_live(host)` (sinais `ended(result)`/`released`; `PauseButton`, `PauseCard`, `ResumeButton`, `ReleaseButton`, `HoldHint`). Na `RoomView`: `open_fishing/fishing_flow/fishing_bubbles/fishing_world/dog_node/main_host/lake_center`. `Places`: `world_summary.fishing` (e `busy` conta a bolha), `goal_target` de `fish*`/`rod:*` leva à lagoa.
- **Decisões:** (1) O minigame ocupa SÓ a área entre o HUD e as abas (z 7), então nunca cobre nenhum dos dois; o mundo fica escurecido atrás. (2) Sair da sala (aba/mundo) com a pesca aberta chama `cancel_fishing` (devolve a isca) e avisa "Você soltou a linha" na luta. (3) `FishingFlow` chama `update_fishing()` a cada 0,1 s durante a espera: com o tick de 1 s a janela de 1 s da fisgada quase sempre se perdia. (4) A fisgada tem janela de 1 s (como no desenho); só no tutorial ela não fecha. (5) Geladeira cheia: o peixe espera na linha (`pending_result`); "Liberar espaço" abre a geladeira, e ao tocar na lagoa de novo ele entra sozinho se já couber. (6) Comum e recorde usam `RewardSheet`; Gigante usa `ModalCard` com confete e vibração forte (sem fila modal pesada). (7) Peixes, boia, vara, bolhas e respingo seguem PROVISÓRIOS (ícone de parafuso/ovo, desenho em código); a 03 troca.
- **Testes:** `fishing_lake_test` (13 casos: aviso da vovó, painel/Tiro, sem isca, força→zona, toque cedo, mordida→minigame→resultado→"de novo", troca de aba, recarregar em luta, bolha, retângulos, escapou, geladeira cheia, Lugares/goal_target/summary) PASS, registrado em `suite` e nas áreas `fishing` e `world`. Capturas: `tests/fishing_shots.gd` → `build/screenshots/fishing/` (16 PNGs × 3 resoluções, SEM `--headless`, abertos; medidas de tela/HUD/abas/alvo 44/texto cortado: OK nas três).
- **Ajustes pedidos pelo Vitor depois:** (1) o Tiro senta na PONTA DA PONTE (`points.fishing_pier` [512,1262]; a ponte é obstáculo, então ele chega à margem pela grade, anda reto até a ponta e desce no fim; `DogWorld.fishing_stand`); a linha e os cálculos de alcance saem dali e as bolhas ficam longe da ponte. (2) O minigame ganhou o cartão da esquerda (`InfoCard`: vara, isca, peixe da luta, tamanho possível, recorde). (3) Só o botão grande `HoldButton` "Segurar para subir" sobe a barra (o resto da tela não faz nada); `StepCardUi.go_button` aceita a meta `art_height`.
- **Testes afetados:** `content_test` (painel `fishing` aceito), `navigation_test`, `worlds_test`, `world_selector_test`, `world_life_test`, `farm_dock_test`, `fishing_test`, `fishing_physics_test`, `texts_test` PASS. FALHAS ANTIGAS, sem relação com a pesca: `world_view_test` ("Casa: cenário inteiro na largura") e `tray_test` ("Sítio com 9 canteiros + 4 da estufa visíveis": a estufa virou bandeja sem canteiros no mapa no commit da047fbe; o teste trava depois do erro).
- **Pendências:** roteiro de toque em Chrome emulado (`touch_test.ps1`) NÃO executado nesta sessão (ver ROADMAP); `Heading` mostra "Lagoa" (o nome da vara fica no ícone/linha de varas); ícone da lagoa e todos os desenhos da pesca vêm na 03; o Vitor ainda decide `bar_max` × `bar_base` (Registro da 01). Sem commit/push/publicação. A 03 (portão do Vitor, arte) NÃO foi aberta.

### Registro da 03 (11/11/2026) — AGUARDANDO PORTÃO DO VITOR
Geradas no PixelLab (`create_image_pixflux`) as opções de arte; **nada instalado em `game/assets`**, provisórios mantidos. Opções em `tools/art/pesca/opcoes/`, manifesto (ids de job, seeds) em `tools/art/pesca/manifest.json`, pranchas em `build/art/pesca/`: `a_icones_peixe.png` (9 peixes × 2 opções, 32 px), `a_peixe_jogo.png` (9 × 1, 48/64 px), `b_iscas_varas_pratos.png`, `c_boia_fx_bau.png` (`tools/art/pesca/board.py` monta). Pendências: painel das varas 64 px, quadros animados da boia/respingo, boia 16 px e bolha 12 px (pixflux só faz área ≥ 32×32), pista/barra/rede por `tools/fishing_art.gd`, prancha (d) minigame e (e) lagoa, instalação, troca dos provisórios e `content_test` sem `icon_todo` — só depois da escolha do Vitor. A 04 não foi aberta.

**Atualização da 03 (11/11/2026):** o Vitor deixou a escolha comigo ("depois a gente repensa; importante já ter o estrutural"). Instalado por `tools/art/pesca/install_escolhas.py` (opções: todas "a", exceto pacu e carpa "b"): 9 ícones `item_fish_*`, 9 peixes do minigame `ui/fishing/fish_<id>.png` (desenhados em escala 1 no `FishingGame`), 3 iscas, 3 varas (ícone), 4 pratos (arquivos prontos, itens vêm nas etapas 06–09), `station_fishing`, `fishing_bobber/bubble/splash.png` (32 px; boia a 0,5× e bolha 8–14 px no código), `ui/fishing/chest.png`. `icon_todo` removido (`items.json`, `fishing.json`; `content_test` não aceita mais), ícone da lagoa em `worlds.json`. Testes PASS: content, texts, fishing_lake, fishing, ui_base. **Pendente (a revisitar):** painel das varas 64 px, quadros animados de boia/respingo (hoje o respingo ainda é desenhado em código), boia 16 px/bolha 12 px reais, baú no minigame ainda sem uso, pista/barra/rede de madeira (`tools/fishing_art.gd` não criado), disco `map_status_fishing`, pranchas d/e e capturas `fishing_03`. A 04 não foi aberta.

**Fechamento das pendências da 03 (11/11/2026):** painel das varas 64 px (`ui/fishing/rod_<id>.png`, instalado; ainda sem uso na interface), quadros de respingo (`fx/fishing_splash/0..4`) e boia afundando (`fx/fishing_bobber_sink/0..4`) ligados na `FishingBobber`; peças de madeira do minigame por `tools/fishing_art.py` (Python/Pillow, não `.gd`): `ui/home/fishing_track/meter/bar/meter_fill.png` (NinePatch, mipmaps) usadas no `FishingGame._draw_live`; disco `map_status_fishing.png` + tipo `fishing` em `WorldCard.KINDS` (some o disco "busy" provisório). Corrigido: os ícones de peixe/isca no `items.json` só foram trocados nesta rodada. Opções extras (boia/bolha 16 px do `create_image_pixen`, 3 rods 64) em `tools/art/pesca/opcoes/extra/`; boia 16/bolha 12 px reais NÃO usadas (ficam a boia 32 px a 0,5× e a bolha 32 px reduzida no código). Baú: arte instalada, uso é da etapa do baú. Capturas `build/screenshots/fishing_03/` (3 resoluções, FISHING SHOTS: OK); testes content/texts/fishing_lake/fishing/ui_base PASS; `world_view_test` falha só no caso antigo "Casa: cenário inteiro na largura" (já falhava antes). Pranchas `build/art/pesca/d_extras.png` e `e_madeira.png`.

### Registro da 04 — banca com Vender · Comprar (11/11/2026, local)

- **Feito:** motor genérico de lojas e a banca da vovó/Feirante com duas abas de madeira. Dados em `progression.json → shops` (`farm_stall`, `market`, `petshop`) e `shop_items` (`food_stall` ração ×3 · 10 moedas, 2/dia; `worm_pack` minhocas ×5 · 10, vara de bambu; `dough_pack` massa ×4 · 20, vara de molinete; `lure` isca artificial ×1 · 25, vara do pescador; `dog_food_pack` do pet shop igual). `worlds.json → farm.places.early_market.name` = "Banca da vovó".
- **Nomes novos (contrato):** `Database.shop(id)/shop_of_place(mundo, lugar)/shops_selling(item)/shop_problems()` (no `content_test`); `GameState.shop_error(loja)/shop_items(loja)` (revelados + UM bloqueado como dica)/`shop_item_locked(id)/shop_daily_left(id)` (-1 = sem limite)/`shop_max_qty(id)/buy_shop_item_error(id, qty := 1)/buy_shop_item(id, qty := 1)` (cobra, entrega, conta `bought:<item>` por unidade, `bought_shop:<loja>`, `buy:<id>`, emite `items_gained`); estado `progress.shop_daily = {id: {day, n}}` e `shop_day_max` (o dia só avança: relógio atrasado não reabre; dia = `_local_time()/86400`), em `ProgressionState` (`to_dict/from_dict`; formato aditivo, `SAVE_VERSION` NÃO subiu). Ação `shop:<id>` em `Places.run` (abre a banca na aba Comprar com o pacote escolhido; loja fechada = aviso), `Places.goal_target` (`stat` com chave `shop:<id>`), `highlight_action` (seta na banca), `Database.item_sources` devolve `{"type":"stat","key":"shop:<id>"}` (e `sources_of` lista "Banca da vovó · 10 moedas"), `TaskHelp.describe("shop", pacote)` + `best_source` (a loja entra como fonte; a minhoca leva "Comprar" até a banca), `SheetBuilder._sources` (chip da banca no detalhe do item).
- **Tela (`SellUi`):** `SellUi.build(mundo)` agora monta a banca inteira. Sem pacote à venda (loja fechada ou só a dica bloqueada) = EXATAMENTE a tela de antes (sem abas). Com pacote: `MissionUi.tabs` dentro do creme (`NotebookTab_sell`/`NotebookTab_buy`, selo `NewBadge` na Comprar enquanto há pacote liberado não visto, `progress.seen["shop_item:<id>"]` marcado ao abrir a aba). Comprar: `BuyGrid` (2 colunas, mesmo `sell_card`), cartão `Buy_<id>` (`Picture`, `Caption`, `Pack` "×5", `Price` + moeda, `DailyLeft` "2 hoje"; escolhido = contorno dourado, meta `selected`; o bloqueado apagado com `LockIcon` + `LockText` curto e meta `locked`, toque mostra o motivo), tábua no molde da venda (`_board_shell` agora compartilhado), `QuantityRow` (máx. = menor entre `max`, limite do dia, moedas ÷ preço, espaço), `BuyTotal`/`BuyTotalValue`, verde `BuyItem` "Comprar" ou `Locked_BuyItem` (`StepCardUi.locked_button`, meta `reason`; com o botão bloqueado o motivo ocupa a linha toda e o total some). `SellUi.last_tab` guarda a última aba só na sessão; `SellUi.open_tab/open_pack` vêm do "Ir".
- **Decisões:** (1) a aba Comprar só aparece com pelo menos um pacote liberado (a dica sozinha não abre aba). (2) `shop_error("petshop")` mantém "Monte o pet shop". (3) o Feirante usa `chapter: 4` (do plano); os pacotes dele só aparecem com as varas 2/3 (etapas 07/08). (4) `petshop_panel` já filtrava `shop == "petshop"`; nada a mudar. (5) A oferta do dia fica para a 10.
- **Testes:** `shop_test` (10 casos do plano, incluindo limite diário com relógio para trás, depósito cheio com pacote de teste, tela com e sem abas, `Places.run("farm", "shop:worm_pack")` e `sources_of/item_sources/TaskHelp`) PASS, registrado em `suite` e nas áreas novas `shops` e `market`; afetados PASS: `content_test`, `texts_test`, `market_test`, `petshop_test`, `ui_style_test`, `farm_market_label_test` (título agora "Banca da vovó"), `coins_test`, `economy_transactions_test`. **Falhas antigas, sem relação:** `item_sources_test` (9 × `fish_*` sem origem concreta, desde a etapa 01) e `world_pin_test` ("farm: ação sem toque físico: place:animals", desde a estufa/animais).
- **Capturas:** `tests/shop_shots.gd` (SEM `--headless`) → `build/screenshots/shop/shop_<res>_{a_sem_abas,b_com_abas_vender,c_comprar_1_pacote,d_comprar_3_pacotes_bloqueio,e_sem_moedas,f_limite_do_dia,f2_limite_esgotado,g_feirante_massa_e_isca}.png` nas três resoluções, medidas com FAIL (moldura/abas/cartões/colunas/alvos 44/texto cortado/tábua) = OK; PNGs abertos.
- **Pendências:** roteiro de toque em Chrome emulado não rodado; as falhas antigas acima (os peixes precisam de "origem" = lagoa em `Database.item_sources`, a combinar com a 05/06). Sem commit/push/publicação.

### Registro da 05 — tutorial "A vovó ensina a pescar" e capítulo 2 (11/11/2026, local)

- **Feito:** cinco missões novas em `quests.json` — `lais_fishing` (main, cap. 2, o30, `shared_with bloblo_first_fish`, fecha o capítulo 2), `bloblo_rod` (o32: falar com a vovó, fresh; dá `rods: [bamboo_rod]` + 5 `bait_worm`, requisito `lais_first_crops`), `bloblo_first_fish` (o34: `fish` 1 fresh, 10 moedas, Ir à lagoa), `bloblo_three_fish` (o36: `fish:fish_lambari/cara/tilapia`, 15 moedas + 5 minhocas) e `bloblo_worms` (o38: `bought:bait_worm` fresh, 5 moedas; Ir = `shop:worm_pack`). Total: 15 pares `shared_with` (14 + `lais_fishing→bloblo_first_fish`), +5 missões (116 no catálogo; 52 principais).
- **Tutorial:** `AnglerTutorial` (`scripts/ui/angler_tutorial.gd`, filho de `Main`, z 13, sempre o último filho; molde do `AlbumTutorial`): véu `Veil_T/B/L/R` com buraco só no alvo, `TutorialHighlight`, balão `TutorialBalloon` (retrato animado da vovó via `ProgressionUi.npc_header`) numa `CanvasLayer` 25 (acima do `FishResult`, que é 24), `TutorialNote` (fala curta ao lado da pista nos passos do minigame, para não tapar o peixe), `TutorialNext` ("Continuar"), `TutorialArrow`/`TutorialArrowFish` (passo 7). Começa sozinho no Sítio quando há vara e o tutorial não terminou (`RoomView._check_angler_tutorial` em `state_changed` e ao ficar visível), esperando `Main.notice_blocked()` e a folha fechar (o prêmio da vara fecha antes). Fases e passo salvo: `lake` 2, `bait` 3, `force` 4, `wait` 5, `bite` 6, `see` 7, `hold` 8, `release` 9, `play` 10, `almost` 11, `result` 12, `outro` 13. Só avança com a ação certa (tocar a água; Continuar; segurar/soltar a barra; fisgar tocando na lagoa; "Pescar de novo"). Fechar o app: passos 6–11 recomeçam da mordida (relança a minhoca sem gastar e pula a espera), 12–13 vão ao "outro". Falas em `npcs.json → bloblo.lines.tutorial/tips` (nada de texto no código).
- **Primeira pesca não falha (motor):** `fishing.json → tutorial {difficulty 8, drain_until 0.5, meter_floor 0.2, cap 0.4}`; `FishingSim.tutorial` (`drain_until`: sem dreno até a rede passar de 50%; `meter_floor`: depois disso nunca cai abaixo de 0,2; `cap`: teto temporário da rede nas demonstrações dos passos 8–9); `FishingGame.frozen` (passo 7 para o tempo), `is_holding/hold_button_rect/track_global_rect`; `FishingPanel.release_cast` sobe a zona para ≥ Meio no tutorial; `GameState.hook()` NÃO gasta a minhoca enquanto `tutorial.done` for falso; já existiam lambari garantido e espera fixa de 3 s. Ações novas: `fishing_tutorial_step/fishing_tutorial_done/advance_fishing_tutorial(step)/finish_fishing_tutorial/fishing_tutorial_bite_now`.
- **Dicas de primeira vez** (`GameState.fishing_tip(id)` devolve o texto UMA vez, marca `progress.seen["fishing_tip:<id>"]`, só depois do tutorial; `FishingFlow.tip(id)` mostra num `Notice` com o rosto da vovó): `bubble` (ao abrir a lagoa com bolha), `escape` (peixe escapou), `no_bait` (painel sem a isca). A `chest` fica para a 07.
- **Ligações:** `Places.goal_target` para `bought:<item>` (leva à loja que vende, `shop:<pacote>`), `TaskHelp` para `fish*`/`bought:` ("Pescar na lagoa do Sítio", "Comprar na banca"), `RoomView.lake_screen_rect()`, `Database.item_sources` dos peixes (`fish:<id>`, corrige o `item_sources_test` antigo) e linha "Pesca: lagoa do Sítio" em `sources_of`.
- **Robô da campanha:** `economy_bot.gd` ganhou `_pursue_fish`/`_pursue_bait` (`fish` e `bought`): `economy_sim.gd` ações `fish` (cast → relógio injetado avança a espera → hook → `finish_fishing` com nota 0,6 → encerra o tutorial) e `buy_shop` (`buy_shop_item`, contabilizada no ledger); `onboarding_test` ganhou o mesmo (e o objetivo `talk:` fresh agora usa `goal_value`). **Campanha completa NÃO executada** (ver pendências).
- **Testes:** `fishing_tutorial_test` (nova, suite + áreas `fishing`/`story`): missões e falas nos dados, regras do motor (12 sementes ficam sem tocar e ainda capturam; controle negativo perde sem as regras), vara/minhocas uma vez só, tutorial começa sozinho com véu e buraco na lagoa, cada passo só com a ação certa e passo salvo (2–12), tempo congelado no 7, 1 s segurando no 8, zona ≥ Meio, espera fixa, minhoca intacta, lambari, partida sem tocar termina em captura, retomada no passo 9 sem duplicar prêmio, passo 13, entrega (+ capítulo), `bloblo_three_fish` ativa, `bloblo_worms` com Ir que abre a banca em Comprar com o pacote escolhido, dicas `escape`/`no_bait` uma vez cada. Ajustados por causa do conteúdo novo: `content_test` (contadores `fish`/`fish:`/`bought:`, destino `shop:` e lagoa), `journey_test` (15 pares), `tasks_test` (a vara vem entre a colheita e a batata; capítulo 2 fecha em `lais_fishing`), `onboarding_test`, `fishing_lake_test` (`_reset(false)` limpa a vara que `dev_unlock_everything` agora entrega).
- **Capturas:** `tests/fishing_tutorial_shots.gd` (SEM `--headless`, uma resolução por vez) → `build/screenshots/fishing_tutorial/step_<01..13>_<tela>_<largura>x<altura>.png` (13 PNGs × 360×780, 390×844 e 412×915, abertos e lidos em sequência). Medidas com FAIL: balão dentro da tela e fora do HUD, sem cobrir o alvo (o balão troca de lado se encostar), nota sem cobrir a pista, texto sem corte, Continuar com alvo ≥ 44; resultado `FISHING TUTORIAL SHOTS: OK` nas três. Câmera: no passo 2 `RoomView.look_at_lake()` leva a água ao centro da tela.
- **Simulador/campanha:** o robô agora pesca e compra minhocas; execução curta `economy_simulate.ps1 -Profile reference -Seed 1 -Days 6 -Until days` (`build/economy/pesca_05/`): 90/116 missões em 5,8 dias, **0 violações**, as cinco missões novas cumpridas na 1ª sessão (4–5 min ativos). A campanha inteira (`progression_test`, `-Quick`) NÃO foi rodada.
- **Falhas antigas, sem relação:** `world_view_test` ("Casa: cenário inteiro na largura"), `tasks_test` ("Humor do Tiro..."), `economy_sim_test` ("uma hora depois tudo o que estava em andamento ficou pronto"/"passeio pronto pode ser recolhido": a bagagem do passeio já é guardada sozinha pela regra "sempre guarda").
- **Pendências:** roteiro de toque em Chrome emulado e celular físico não rodados; `progression_test`/simulador `-Quick` não rodados nesta etapa (a decisão de rodar a campanha fica para a 06, junto com os Dentinhos); falha antiga sem relação: `tasks_test` ("Humor do Tiro..."). A 06 foi aberta numa sessão nova de Sonnet 5.5 ("Pesca — Etapa 06"), pela regra de sessões encadeadas.

### Registro da 06 — papinha de peixe e Dentinhos (11/11/2026, local)

- **Feito:** item `fish_mash` + receita do fogão (tilápia 1 + batata 1, 180 s, `first_kitchen` + `rod bamboo_rod`); requisito `fish_meal` nos Dentinhos (`feed fish_mash ×2`, sem `body_level`, soma à cenoura gelada) e fato real em `teething.facts`; missões `lais_fish_mash` (main cap. 3, o22, contadores reais `produce:fish_mash`/`feed:fish_mash` fresh, Ir ao fogão) e `bloblo_big_tilapia` (linha bloblo, o64, requisito `lais_fish_mash`, `fish_size:large:fish_tilapia`); `fishing.json → harvest_worm_chance` 0,15 e sorteio em `GameState.harvest` (só com a vara de bambu, mesma semente do plantio, aviso "Achou uma minhoca!").
- **Correção de contador:** o Gigante agora também soma `fish_size:large:<id>` (antes só `fish_size:large`), para a tilápia da vovó valer com Gigante.
- **Decisões:** arte só PixelLab (ícone pixel no fogão, sem `food_fish_mash.png`); nenhum desejo novo (o desejo `meal` já resolve a refeição da fase); `growth_meals_test` passou a escolher a refeição que tem `body_level`.
- **Também ajustado:** `Places.goal_target` agora entende `feed:<item>` (objetivo sem destino no `content_test`); `GameState.feed` só anuncia o progresso da refeição que a comida realmente alimenta (a papinha não rouba o aviso da cenoura gelada); `bloblo_big_tilapia` ficou na ordem 72 (a 64 quebrava a sequência `bloblo_chew_ring` → `farm_deed` do `garden_test`); testes atualizados: `content_test` (chave `fish_size:<classe>:<peixe>`), `festival_test` (53 principais), `growth_story_test` (118 missões/53 principais), `keys_test` (conta a papinha), `garden_test` (minhoca de bônus não entra no total), `growth_meals_test`, `onboarding_test` (o robô pesca tilápia, cozinha e dá a papinha).
- **Testes:** `fishing_story_test` PASS (suite, áreas `fishing`/`growth`/`story`). PASS isolados depois dos ajustes: content, festival, growth_story, growth_meals, growth_ui, garden, keys, journey, care_story, fishing, fishing_tutorial, texts, shop, onboarding. **Portão** (`-Level portao`, 1178 s, antes dos ajustes acima) teve 20 falhas/1 timeout; as minhas foram corrigidas (lista acima). Seguem falhando, sem relação aparente com a papinha (não conferi contra a linha de base): `tasks_test` (Humor do Tiro), `manual_test` (peixes sem fonte no Manual), `food_order_touch_test`, `blender_position_touch_test`, `photo_rarity_test` (SAVE_VERSION 19), `card_reveal_test`, `world_selector_test`, `world_pin_test`, `world_view_test`, `station_tray_test`, `hud_growth_test`, `drag_scroll_test`, `tray_test` (timeout), `warehouse_test`. O portão NÃO foi reexecutado inteiro depois dos ajustes.
- **Não feito:** capturas (`build/screenshots/fishing_06/`: Dentinhos com o passo novo, bandeja do fogão, aviso da minhoca) e campanha completa. A sessão da 07 NÃO foi aberta por isso (critério de pronto incompleto).

### Registro da 07 — vara de molinete, massa, baú e ensopado (11/11/2026, local)

- **Feito:** tudo do arquivo da etapa; detalhes e nomes em `docs/PROGRESSION.md` ("Pesca — etapa 07") e no "Estado atual" do ROADMAP. Resumo: `reel_rod_pack` no Feirante (`shop_items` aceita `rods` e `materials`), receita `bait_dough`, baú da lagoa (`_chest_due`, `FishingSim.chest_*`, `FishingGame._draw_chest`, `FishResult` "Baú!", dica `chest`), `fish_stew` + três receitas, passo `fish_meal` do Aventureiro, missões, encomenda `lais_fish_lunch`, `GameState.last_fish_chest`, contador `fish_chest`, rótulo de recibo "Baú da lagoa".
- **Decisões:** (1) `merchant_fishing` e `bloblo_carp` ficam na linha NOVA `angling` (o10/o20), não em `merchant`/`bloblo`: numa linha o primeiro passo não cumprido trava os seguintes, e travaria o comércio e o capítulo 9 de quem ainda não comprou o molinete. (2) `lais_fish_stew` é o42 (entre `main_5_bricks` o40 e `explorer_6_eggs` o45); os capítulos do jogo são 1 a 12 próprios, não os do plano. (3) O chip do baú no resultado e o anel do baú no minigame são desenhados no código; o baú aparece como mancha clara no anel (arte `chest.png` da 03). (4) A dica `chest` congela o minigame por 2,5 s (`FishingGame.frozen`). (5) `lais_fish_lunch` exige também `first_harvest` (regra do `content_test`).
- **Testes:** `fishing_rod2_test` PASS (13,8 s; suite e áreas `fishing`, `market`, `growth`, `story`). PASS junto: content, texts, shop, market, customers, growth_meals, growth_ui, growth_story, festival (54 principais), journey, pending_gifts, fishing, fishing_physics, fishing_story, fishing_lake, fishing_tutorial, keys, item_sources, onboarding, care_story, quest_reward, garden, ui_style. Ajustados: `fishing_test` (baú exige `cast.chest`), `content_test` (contador `rod:`), `growth_story_test` (121 missões, ensopado depois dos tijolos), `festival_test` (54). Falha antiga, sem relação: `tasks_test` ("Humor do Tiro..."). Portão completo NÃO reexecutado.
- **Capturas:** `tests/fishing_rod2_shots.gd` (SEM `--headless`) → `build/screenshots/fishing_07/rod2_<res>_{a,b,c_feirante…,d_painel_2_varas,e_minigame_bau,f_resultado_bau,g_aventureiro_ensopado}.png`, três resoluções, medidas OK, PNGs abertos.
- **Pendências:** o robô do simulador (`economy_bot`) e a campanha (`progression_test`, `-Quick`) NÃO compram o molinete nem fazem o ensopado: a campanha trava no `lais_fish_stew` (capítulo 6) até o robô aprender `rod:reel_rod`, massa de milho e peixes da vara 2; roteiro de toque em Chrome e celular físico não rodados.

### Registro da 08 — vara do pescador, isca artificial e pelo brilhante (11/11/2026, local)

- **Feito:** tudo do arquivo da etapa; nomes e números em `docs/PROGRESSION.md` ("Pesca — etapa 08") e no "Estado atual" do ROADMAP. Resumo: receita `angler_rod` na bancada com `output_rod` (sem item; recolher chama `give_rod`, "Você já tem"/"Já está sendo feita", um por vez, `Database.recipe_unique/recipe_output/item_name/item_icon` reconhecem a vara), `bait_lure` (cobre 1 + graveto 1, 120 s, exige a vara 3), linha `guide` com `guide_angler` (o60), `guide_angler_rod` (o62) e `guide_pintado` (o64), `herb_fish` + receitas `herb_fish_pintado/tucunare`, fonte de momento `herb_fish` (Pelagem, com teto), passo `fish_meal` do Mocinho (2 peixes com ervas) e `lais_shiny_coat` (principal, cap. 9).
- **Decisões:** (1) `lais_shiny_coat` ficou na ordem **36** do capítulo 9 (depois de `young_9_milk` o35, antes de `growth_9_young` o40), não na 15: a ordem 15 trancaria fibra/tábua/ateliê atrás da linha inteira do Guia. A estufa/ervas abre no capítulo 8 (`main_7_greenhouse`), então as ervas já existem. (2) `guide_angler` exige `guide_treasure` + `rod reel_rod`; fibras e cobre da vara 3 vêm da Natureza. (3) A fonte de momento `herb_fish` usa `go: place:house:stove` (o `WishUi.go_target` só conhece `screen:`/`place:`). (4) A vara não entra na maestria da bancada (como as roupas). (5) Não mexi em `bar_max`/`bar_base` (decisão do Vitor, Registro da 01): com a barra presa em 0,34 o `bar_bonus` das varas não muda a barra; o que a vara 3 muda é o `hold` 0,30 (dreno −30%) e o rebote 0.
- **Taxa de acerto (honesta):** não joguei 10 partidas com o dedo. Medi com um piloto simulado (segue o peixe com reação de 0,3 s, 100 sementes): traíra, tucunaré e pintado **100%** com a vara 3 (pintado com a vara 1: 94%; com reação de 0,4–0,6 s o pintado cai para 98%). O piloto é perfeito demais para valer como "jogador médio": a meta de 50–70% precisa do Vitor jogando; se o pintado estiver fácil, os botões são `fish_pintado.difficulty` (85) e `fill_mult` (0,8).
- **Testes:** `fishing_rod3_test` PASS (suite e áreas `fishing`/`growth`/`story`). PASS junto: content, texts, growth_meals, growth_story, growth_ui, silk, journey, fishing, fishing_rod2, fishing_story, fishing_lake, fishing_tutorial, festival, onboarding, quest_reward, shop, keys, item_sources, care_story, garden, pending_gifts. Ajustados: `growth_story_test` (125 missões/55 principais, `lais_shiny_coat` antes de `growth_9_young`), `festival_test` (55). **Falha antiga, sem relação:** `station_tray_test` ("comida do próximo crescimento vem primeiro", já listada no Registro da 06). Portão completo NÃO reexecutado.
- **Capturas:** `tests/fishing_rod3_shots.gd` (SEM `--headless`) → `build/screenshots/fishing_08/rod3_<res>_{a_bancada_vara,b_painel_3_varas,c_minigame_pintado,d_resultado_gigante_pintado,e_mocinho_peixe_com_ervas}.png`, três resoluções, medidas OK, PNGs abertos.
- **Pendências:** o robô do simulador (`economy_bot`) e a campanha (`progression_test`, `-Quick`) NÃO sabem fazer a vara 3, o peixe com ervas nem o `lais_shiny_coat` (e já travavam no molinete/ensopado da 07); roteiro de toque em Chrome e celular físico não rodados; taxa de acerto humana do pintado a conferir pelo Vitor. Sem commit/push/publicação.

### Registro da 09 — caderno de peixes, rotinas e encomendas (12/11/2026, local)

- **Feito:** tudo do arquivo da etapa; nomes em `docs/ROADMAP.md`/`CLAUDE.md` ("Pesca — etapa 09"). Filtro Peixes na Coleção, detalhe da espécie, 3 rotinas, 2 encomendas, petisco `lambari_crunch`, fontes do Manual, Como fazer do peixe grande.
- **Decisões:** (1) o recorde vai na legenda do quadradinho ("Lambari\n12,5 cm"), não no canto, para não cobrir o peixe. (2) "Ir pescar" é o botão verde padrão (`go_button`), não amarelo: é o único da folha. (3) `ProgressionState.feature_unlocked` passou a usar o `GameState.requirement_error` quando há `rod` (o do estado não conhece vara). (4) Ícone do petisco derivado de `item_fish_lambari` (tingido dourado): o PixelLab respondeu 401; trocar por arte PixelLab quando houver credencial. (5) A diária `fish` entra no sorteio do capítulo 3 junto com a colheita (a vara já veio): `tasks_test` agora espera 2 diárias. (6) Espécie não pega mostra o desenho real, não silhueta (só a legenda "?"/nome genérico esconde).
- **Testes:** `fishing_book_test` PASS (suite, áreas `fishing`, `lists`). PASS junto: content, texts, manual, customers, lists, item_sources, fishing_rod3, growth_story, journey, festival, onboarding, growth_meals, ui_style, text_budget, fishing_story. Ajustados: `content_test` (contadores `fish`/`fish_size:` nas rotinas), `tasks_test` (2 diárias). Falha antiga, sem relação: `tasks_test` ("Humor do Tiro..."). `fishing_story_test` ("minhocas com vara") oscila por sorteio sem semente fixa: falhou uma vez e passou em seguida. Portão completo NÃO reexecutado.
- **Capturas:** `tests/fishing_book_shots.gd` (SEM `--headless`) → `build/screenshots/fishing_09/book_<res>_{a_vazio,b_meio,c_completo,d_detalhe_pego,e_detalhe_nao_pego}.png`, três resoluções, medidas OK, PNGs abertos.
- **Pendências:** prêmio por completar o caderno (proposta: moedas por vara completa, não implementado); robô/campanha seguem sem fazer molinete/vara 3 (Registros 07/08); celular físico não rodado. Sem commit/push/publicação.

### Registro da 10 — ritmo, oferta do dia e fechamento (12/11/2026, local; PLANO CONCLUÍDO; ritmo aprovado pelo Vitor)

- **Feito:** robô pescador no simulador (`fishing_skill` por perfil, nota sorteada, escapadas, tempo real; política por espécie com isca, vara 2 por pacote e vara 3 por receita; `summary.fishing`), oferta do dia na banca (`daily_offer` com `rotation`, `GameState.shop_pack`, selo "Hoje"), `tools/pesca_tour.ps1`, `FUTURO.md`, `RESULTADOS.md` (ritmo antes × depois e roteiro do celular), docs (PROGRESSION, GAME_DESIGN, ROADMAP, CLAUDE/AGENTS).
- **Ritmo (`-Quick`, reference, semente 1; detalhes e opções em `RESULTADOS.md`):** campanha 20,08 → 20,34 d (+1,3%, teto +10% respeitado), 111 → 125 missões, 0 violações, 9,7 min de pesca; as fases chegam um pouco antes, ficando **abaixo** das metas de +1–2 h / +3–5 h. Nada foi ajustado; **o Vitor decide** (aceitar, pratos 2 → 3, preço das iscas ou um gargalo de tempo novo).
- **Decisões:** (1) o "antes" foi medido num worktree separado do commit `da047fbe` (sem a pesca), porque o robô do código atual trava sem pescar. (2) A oferta do dia é a "dica bloqueada" da banca enquanto `lais_forest` não vale. (3) O robô não compra a oferta (medida conservadora). (4) O tour é um roteiro PowerShell que roda os seis scripts de captura da pesca, não um bloco `--pesca-only` do `ui_tour.gd`. (5) Roteiro de toque Web (`fishing.json`) NÃO escrito/rodado: exige export + servidor e coordenadas conferidas.
- **Testes:** `shop_test` (caso 10 da oferta) PASS; `progression_test` PASS (778 ciclos, 64 aquisições, 125 missões; o `progression_test` ganhou `_fishing_step`); `economy_audit_selftest` PASS (auditor aceita `shop:` e `output_rod`); `animals_chain_test` e `care_story_test` ajustados e PASS; `economy_sim_test` só com as 2 falhas antigas de passeio; `-Quick` PASS (0 violações). Portão (`-Level portao`): 120 PASS e 21 com FAIL/timeout — ver `RESULTADOS.md` (nenhum atribuído à pesca depois dos ajustes acima; os do Sítio vêm de outra sessão que está trocando a arte do Sítio: `ilha_*` removidos e `farm.json` alterado; `silo`, `bench` e `ui_style` passam no commit sem a pesca, então não foram atribuídos com certeza). `test_circuit_selftest` falha por `wish_moments_test` × `wish_guide_test` (antigo).
- **Fechamento (12/11/2026):** o Vitor aceitou o ritmo. Capturas `fishing_shots`/`fishing_tutorial_shots` corrigidas (tutorial cobrindo a tela no roteiro; balão medido no 1º quadro em `AnglerTutorial`). Nada mais pendente no código da pesca.
