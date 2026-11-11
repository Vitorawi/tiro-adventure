# Plano "Pesca na lagoa da vovó"

> Pedido do Vitor (11/11/2026): um minigame de pesca na **lagoa do Sítio**, no modelo "segurar = a barra
> sobe, soltar = cai" (especificação técnica dele, resumida em [01_DESENHO.md](01_DESENHO.md) §1). A pesca
> começa **no meio da fase Filhotinho**, porque o peixe é ingrediente de pratos que o Tiro **precisa comer**
> para crescer. **3 varas**, cada uma pega **3 peixes reais**; o **tamanho** do peixe é sorteado e depende da
> pontuação, e fica registrado (recorde por espécie). As duas varas melhores vêm **ao longo da história**
> (compra na Vila e missão). **Iscas** se compram. Tutorial muito bom. Objetivo extra: **dar mais tempo de
> jogo** entre os crescimentos do Tiro. Álbum/fotos de pesca ficam **para depois**.

Estado: **etapa 00 (protótipo) feita em 11/11/2026, aguardando o portão do Vitor** (ver "Registro da 00"); as demais não iniciadas. Save, missões e a lagoa não mudaram.

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
