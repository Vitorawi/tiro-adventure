# 01 — Desenho: a foto como carta colecionável

Este documento é a fonte das regras. As etapas apontam para as seções daqui. Números marcados **(ajustável)**
ficam em dados (`game/data/album.json`) para o Vitor calibrar sem mexer em código.

## 1. Vocabulário

| Termo | O que é |
|---|---|
| **Foto / carta** | uma das 54 entradas de `album.json → photos` (mesmo `id` de sempre). No jogo continua se chamando "foto"; "carta" é o jeito de apresentar. |
| **Nível / versão** | 1 Comum · 2 Brilhante · 3 Rara · 4 Holográfica. Cada nível é uma versão diferente da mesma foto. |
| **Melhor nível** | o maior nível que o jogador já tem daquela foto (`rarity`). |
| **Versão mostrada** | a que o jogador escolheu para aparecer (`shown`; 0 = mostra a melhor). |
| **Coleção de versões** | o conjunto de níveis já conseguidos (`variants`, ex.: `[1, 3]`). Completa = os quatro. |
| **Carta fechada** | foto conseguida e ainda não aberta (`sealed` > 0). Não tem nível até abrir. |
| **Abrir** | sortear o nível de uma carta fechada (a carta vira e revela; sem roleta). |
| **Tentar a sorte** | pagar **moedas** para sortear outra vez entre os 4 níveis; a versão sorteada entra na coleção. |
| **Melhorar** | pagar **materiais** (+ moedas) para ganhar **exatamente o nível acima do melhor** que você tem. |
| **Varal** | as 3 fotos em destaque na home (tela do Tiro). |

Mapeamento explícito nível ↔ arte (nunca deduzir por nome exibido ou posição em lista):
`1 ↔ common`, `2 ↔ shiny`, `3 ↔ rare`, `4 ↔ holographic`.

## 2. Estado de cada foto (no save, `AlbumState.photos[id]`)

Campos que já existem (etapa 1 antiga): `at`, `phase`, `coat`, `seen`, `equipped`, `rarity`, `variants`,
`shown`, `rolls`, `rerolls`, `best_at`, `rolled_at`. Campos novos desta etapa 01:

| Campo | Tipo | Significado |
|---|---|---|
| `sealed` | int | cartas fechadas esperando abrir (a 1ª captura cria 1; cada retomada natural de foto repetível cria +1). |
| `upgrades` | int | quantas vezes "Melhorar" foi usado nesta foto. |
| `opened_at` | float | quando a primeira carta foi aberta (antes disso a foto não tem nível). |

Estado global novo em `AlbumState`: `featured: Array[String]` (até 3 ids, varal), `tutorial: Dictionary`
(`step`, `done`), `granted` não — os prêmios usam o `_grant_automatic` com ids próprios (§7).
`SAVE_VERSION` sobe (saves sempre zerados; regra do Vitor; sem migração).

Regras de consistência:
- Uma foto com `sealed > 0` e sem `opened_at` ainda **não tem nível**: o álbum a mostra como carta fechada,
  nunca com moldura de raridade. `photo_rarity(id)` devolve 0 nesse caso.
- `variants` nunca perde elementos; `rarity = max(variants)`; `shown` só pode ser um nível de `variants`
  (ou 0).

## 3. Sorteio

- Pesos **(ajustável)** em `album.json → cards.weights`: `{1: 45, 2: 30, 3: 18, 4: 7}`.
- Fotos da seção História usam `cards.section_weights.story` `{1: 20, 2: 35, 3: 30, 4: 15}` **(ajustável)**
  (são marcos únicos). Foto pode ter `rarity_weights` próprio.
- Garantias **(ajustável)** `cards.pity`: 10 sorteios seguidos sem Rara+ → o próximo é no mínimo Rara;
  30 sem Holográfica → o próximo é Holográfica. Valem para **Abrir** e **Tentar a sorte** (não para Melhorar,
  que não é sorteio). Contadores `pity_rare`, `pity_holo` no `AlbumState`.
- Sorteio determinístico com semente salva (`AlbumState.rarity_seed`, já existe), via `Loot.pick_weighted`.
  Carregar o save nunca ressorteia.

## 4. Como uma carta chega e abre

1. O evento da foto acontece (`_album_event`, regras de `on`/`when` inalteradas):
   - foto nova → cria a entrada com `sealed = 1`, **sem sortear**; emite `Events.photo_taken(id)`;
   - foto repetível já aberta, fora da recarga **(ajustável)** `repeat_cooldown_hours` 20 h e ainda sem as
     4 versões → `sealed += 1`; emite `Events.photo_sealed(id)` (novo).
2. **Abrir** (`GameState.open_photo_card(id)` / `open_photo_card_error(id)`): consome 1 `sealed`, sorteia
   (§3), adiciona à coleção, atualiza melhor/`rolled_at`/garantias, emite
   `Events.photo_rolled(id, {rarity, previous, new_photo, improved, new_variant, rolled, kind: "open"})`.
   Versão repetida (já tinha) também conta como sorteio, mas não ganha nada além da contagem — o cartão diz
   "Você já tinha esta versão".
3. Fotos tiradas **antes de conhecer o Álbum** (hoje: `photo_alerts_enabled()` falso) ficam fechadas e
   esperando; o tutorial (§8) abre a da chegada e o álbum mostra o resto em "Para abrir".

## 5. Tentar a sorte e Melhorar

**Tentar a sorte** (`reroll_photo(id)` / `reroll_photo_error(id)`):
- Só para foto já aberta e sem as 4 versões. Custa **só moedas** **(ajustável)** `cards.reroll`:
  40 moedas na 1ª vez daquela foto, +20 a cada vez, teto 160.
- Sorteia com os mesmos pesos/garantias; adiciona a versão; nunca tira nada. `kind: "reroll"` no sinal.

**Melhorar** (`upgrade_photo(id)` / `upgrade_photo_error(id)`):
- Só para foto já aberta e com melhor nível < 4. Dá **o nível `rarity + 1`** (sem sorteio), adiciona à
  coleção e passa a ser a versão mostrada se o jogador mostrava a melhor (`shown == 0`). `kind: "upgrade"`.
- Custo por **nível de destino** **(ajustável)** `cards.upgrade`:

| Destino | Moedas | Materiais |
|---|---|---|
| 2 Brilhante | 30 | madeira 4, pedra 3 |
| 3 Rara | 80 | tábua 3, cobre 2, fibra 4 |
| 4 Holográfica | 180 | cristal 3, madeira dura 3, tecido 2 |

- Valida tudo antes de consumir (`transaction_error` / convenção `*_error` do projeto); consome uma vez.
- Falta de material: o botão vira o **botão de madeira bloqueado** (`StepCardUi.locked_button`) com o ícone
  do que falta; tocar abre o "Como fazer" do material.

Contadores novos: `photo_opens`, `photo_rerolls` (já existe), `photo_upgrades`, `photo_holo`.

## 6. Varal na home

- `AlbumState.featured` guarda até **3** ids **(ajustável)** `cards.featured_slots`.
- `feature_photo(id)` / `_error` (precisa estar aberta; se já cheio, devolve erro "Escolha qual sai" e a UI
  pede qual trocar), `unfeature_photo(id)`, `featured_photos()`.
- Antes de existir qualquer foto aberta, o varal não aparece.

## 7. Recompensas de coleção

Pagas uma vez por `_grant_automatic(id, rewards)` (já existe; itens que não cabem viram "Presentes para
guardar"). Ids e valores **(ajustável)** em `cards.rewards`:

| Marco | Id | Prêmio |
|---|---|---|
| Seção completa (todas as fotos abertas) | `album:section:<seção>` | 60 moedas |
| As 4 versões de uma foto | `album:styles:<foto>` | 25 moedas |
| 5 / 15 / 30 fotos com Rara+ | `album:rare:<n>` | 40 / 80 / 150 moedas |
| Primeira Holográfica | `album:holo:first` | 100 moedas + o contador `photo_holo` |

## 8. Tutorial (roteiro)

Gatilho: a **primeira abertura do Álbum** com a foto `h_arrival` fechada (a missão `lais_album` da linha
`lais_memories` já leva até lá; o objetivo `open:album` continua o mesmo). Salva o passo em
`AlbumState.tutorial.step`; fechar no meio retoma no mesmo passo na próxima visita; não há "pular".

| Passo | Tela | Fala da Laís (balão de madeira) | Resultado forçado |
|---|---|---|---|
| 1 | carta fechada da chegada em destaque, resto escurecido | "Olha! A primeira foto do Tiro chegou fechadinha. Toque em Abrir!" | — |
| 2 | a carta vira e revela | (sem fala) | **Comum** (nível 1), sem contar garantia |
| 3 | carta aberta, botão **Tentar a sorte** com selo "Grátis" | "Toda foto tem quatro versões. Tente a sorte, essa é por minha conta." | **Brilhante** (nível 2); não cobra |
| 4 | carta com as versões (2 coloridas, 2 escuras) e **Melhorar** com selo "Presente" | "Melhorar sempre sobe um nível. Hoje os materiais são presente meu." | **Rara** (nível 3); não cobra (custo mostrado riscado) |
| 5 | carta Rara brilhando, dica de inclinar com o dedo | "Arraste a foto para ver o brilho. Escolha qual versão mostrar!" | — |
| 6 | botão **Pôr no varal** | "Põe ela no varal da home pra gente ver sempre." | entra no varal |

Regras: os resultados forçados só valem dentro do tutorial (`tutorial_override`), não mexem nos pesos, nem
nas garantias, nem consomem moedas/materiais; contam `photo_opens`/`photo_rerolls`/`photo_upgrades`
normalmente. Depois do tutorial as outras cartas fechadas aparecem em "Para abrir".

## 9. O que já existe ("etapa 1 antiga", feita em 06/11 antes deste plano)

Código: `album.json → rarity` (níveis/pesos/garantias/`section_weights`/`repeat_cooldown_hours`/`reroll` com
cristal + madeira dura), `repeatable` por foto, `AlbumState.pity_rare/pity_holo/rarity_seed`, campos por foto
(§2), `GameState.photo_rarity/photo_shown_rarity/photo_variants/photo_styles_complete/styles_complete_count/
rarity_counts/album_rarity_def/reroll_cost/photo_can_retake/set_photo_variant/reroll_photo` (+ `_error`),
`Events.photo_rolled`, `dev_take_photo(id, rarity)`, `SAVE_VERSION` 18, teste `photo_rarity_test`.
**Hoje o sorteio acontece ao tirar a foto** e o "Revelar de novo" custa cristal + madeira dura: a etapa 01
muda para carta fechada + abrir, rolar só com moedas e Melhorar com materiais. Arquivo solto
`tools/photo_frames_art.gd` é sobra de uma tentativa interrompida de molduras: a etapa 03 decide reaproveitar
ou apagar.

## 10. Visual

### 10.1 A carta
- Formato polaroide vertical: arte quadrada em cima, faixa de papel embaixo com o título (fonte da madeira),
  data pequena e o selo do nível. Proporção da carta ≈ 0,82 (largura/altura).
- A arte por nível vem do catálogo (§11); sem arte revisada → ilustração atual da foto
  (`photo.illustration`). Ilustrações: filtro `LINEAR_WITH_MIPMAPS`; nada esticado (escala uniforme,
  `STRETCH_KEEP_ASPECT_COVERED` só dentro da janela quadrada).

### 10.2 Os quatro níveis

| Nível | Moldura | Efeito | Selo |
|---|---|---|---|
| 1 Comum | papel creme liso (a polaroide de hoje, limpa) | nenhum | sem selo (ou ponto cinza discreto) |
| 2 Brilhante | papel creme com fio dourado fino | nenhum | estrela dourada pequena |
| 3 Rara | moldura entalhada dourada/madeira com folhas nos cantos | **brilho**: faixa de luz que atravessa a cada ~3 s + cintilas suaves (shader, `TIME`) | duas estrelas + "Rara" |
| 4 Holográfica | moldura prateada perolada | **cromo/foil**: reflexo arco-íris na **carta inteira** (arte + moldura + papel), que se move com o tempo e com a inclinação; levíssimo relevo de faixas | "Holográfica" em letras furta-cor |

### 10.3 A carta em 3D
- Visualizador em tela cheia sobre véu (`Palette.SCRIM`), carta ≈ 78% da largura.
- Arrastar: a carta gira em torno do eixo vertical (até ±22°) e um pouco no horizontal (até ±10°) com
  perspectiva; o reflexo (nível 3 e 4) segue o ângulo. Soltar: volta suave (mola ~0,35 s). Toque rápido não
  inclina. "Menos animação": inclinação menor e sem mola, efeitos parados num quadro bonito.
- Implementação recomendada: a carta inteira renderizada num `SubViewport` (só a carta grande) e mostrada
  num `TextureRect` com shader `canvas_item` que faz a perspectiva no vértice e o foil/brilho no fragmento;
  na grade do álbum, **sem** SubViewport: efeito estático barato (ou animação só por `TIME`).

### 10.4 Abrir e tentar a sorte (sem roleta)
- **Não há roleta** (decisão do Vitor: "não é para botar uma roleta nem nada"; "girar a sorte" é só o botão
  **Tentar a sorte**).
- Carta virada (verso de madeira com a pata do Tiro) cai no centro: "Nova foto surpresa!" + título.
- **Abrir**: o verso vira (0,4 s) e a arte "revela" (branco → imagem, 0,6 s) já com a moldura/efeito do nível
  sorteado; o selo do nível aparece com um pulinho.
- **Tentar a sorte**: a carta vira de costas e volta (0,6 s) mostrando a versão sorteada; versão repetida =
  "Você já tinha esta versão". **Melhorar**: a moldura sobe um degrau com brilho e o selo novo.
- Festa por nível: 1 = pulinho; 2 = brilho curto; 3 = confete leve + vibração `success`; 4 = confete cheio,
  flash arco-íris na tela e vibração `big`. Tudo pela fila modal (`main._queue_modal`), nunca dois juntos.

### 10.5 Padrão
Todas as telas em **madeira ilustrada** (peças `StepCardUi`, `MissionUi`, `SellUi`, `ItemUi`, `WelcomeSheet`,
`ModalCard`, `StationWood`); um só botão verde por tela; bloqueio = botão de madeira bloqueado; alvos ≥ 44.

## 11. Arte por raridade (resumo; detalhes em INTEGRACAO_RARIDADES.md)

- Fonte: `tools/art/album_rarities/catalog.json` → `photos[].variants[common|shiny|rare|holographic]`, campo
  `path` (relativo à raiz), só `status == "reviewed"`. Chave = `id` da foto.
- Instalação: cópia reduzida para o jogo em `res://assets/sprites/ui/album/rarities/<id>/<chave>.png`
  (destino `integration_target`), importada com mipmaps. Tamanho no jogo **(ajustável)** 768×768 (o
  original de 1254 fica só em `tools/`).
- Estado em 06/11: 54 fotos, 216 arquivos, **11 fotos completas (44 revisados)**, 172 pendentes.
