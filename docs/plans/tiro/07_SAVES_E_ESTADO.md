# 07 — Saves, estado e eventos (autoritativo)

`SAVE_VERSION` sobe para **13** na etapa 02 e saves com versão menor **recomeçam do zero** (decisão do Vitor,
19/10/2026: "vou zerar praticamente o jogo de todo mundo"). Chaves novas no save com padrão seguro; sem migração
de saves antigos.

## A. `GrowthState` (`scripts/state/growth_state.gd`, chave `growth`)

| Campo | Tipo | O que guarda |
|---|---|---|
| `schema` | int | 1 |
| `phase` | String | id da fase atual (`newborn` … `adult`) |
| `phase_since` | float | Unix do começo da fase |
| `points` | Dictionary | pontos acumulados por pilar (`body`, `coat`, `smart`, `brave`) |
| `reserve` | Dictionary | pontos guardados acima do teto, por pilar |
| `done` | Dictionary | `{fase: {req_id: true}}` requisitos cumpridos (nunca voltam) |
| `delivered` | Dictionary | `{fase: {item: qty}}` entregas parciais |
| `phase_stats` | Dictionary | base dos contadores no início da fase (`feed:any`, `walk`, `shampoo_bath`…) |
| `ceremonies` | Dictionary | `{fase: {at, seen, before, before_coat, after_coat, delivered}}` (recibo visto ao fechar o cartão) |
| `ready_seen` | String | fase cujo aviso de pronto já apareceu em boas-vindas (08) |
| `pending_reveal` | String | fase aguardando a revelação "cresce dormindo" (ou vazio) |
| `cooldowns` | Dictionary | recargas de pilar (`bath`, `play`, `brush`, `nap`) em Unix |
| `firsts` | Dictionary | uma-vez-só de pilar (`npc:<id>`, `world:<id>`, `trick:<id>`) |
| `favorite` | String | comida favorita sorteada (etapa 12) |
| `tastes` | Dictionary | `{item: {reaction, at}}` (etapa 12) |
| `silk` | int | nível da Pelagem de seda 0–3 (etapa 17) |
| `brush_days` | Array | datas (AAAA-MM-DD) de escovações que contaram (etapa 12/17) |
| `personality` | Dictionary | jeito atual, últimos 14 dias locais ativos (`days`), somas limitadas históricas (`history`) e `played_days` (16) |
| `diary` | Array | até 20 linhas "Hoje o Tiro..." `{at, day, kind, text}` (16) |
| `diary_receipts` | Dictionary | fotos, primeiras provas e crescimentos já registrados, mesmo após descartar a linha (16) |

Consultas puras no estado (`level(pillar)`, `cap()`, `phase_index()`); regras e eventos no `GameState`.

## B. `AlbumState` (`scripts/state/album_state.gd`, chave `album`, etapa 13)

`photos: {id: {at, phase, coat, seen, equipped}}`, `hints: {id: nível revelado}`, `lupa_day`, `lupas_used`,
`photobomb_pity`, `wall: [ids]` (parede), `main_photo` (cantinho), `recent: {evento: [unix]}` (para `within` e contagem).

Etapa 15: `opened_at` guarda a primeira abertura de cada foto na seção secreta; `spoken` guarda recibos de
dicas/comentários; `years.gotcha` guarda o maior ano comemorado; `party_from/party_until` delimitam a festa;
`sleep_spot` guarda o lugar da soneca. Todos têm reset, to_dict/from_dict e valores seguros quando ausentes.
Fotos anteriores à 15 sem `equipped` continuam sem roupa. Sem reset nem aumento de SAVE_VERSION.

## C. Casa (etapa 14)

Objetos novos são construções/itens já existentes no modelo (`progress.owned`, requisitos de objeto de sala).
O que for só escolha do jogador (fotos penduradas, brinquedos no cesto) fica em `progress.house`
(`toys: [ids]`, `bed_level`), com `to_dict`/`from_dict` no `ProgressionState`.

## D. Reset dos saves (etapa 02)

1. `SaveManager.SAVE_VERSION` = 13. Save com versão < 13 (em qualquer slot) **recomeça do zero** ao abrir,
   do mesmo jeito que o ramo histórico `< 12` já fazia (agora ampliado com autorização do Vitor).
2. `settings.json` (Vibrar, Menos animação, slot padrão) é preservado; só o progresso do jogo zera.
3. Ao recomeçar, aparece uma vez um aviso curto e carinhoso (ex.: "O Tiro chegou de novo, filhotinho!").
4. Sem `GrowthMigration`, sem campos `legacy`, sem reconhecimento de missões antigas.
5. `EconomyMigration` continua como está (saves novos já nascem na revisão atual).
6. `level`/`xp`/`skills` podem sair do save e do código na etapa 07, se o simulador e os testes deixarem.

## E. Eventos novos (`autoload/events.gd`)

| Sinal | Quando |
|---|---|
| `pillar_gained(pillar: String, points: int, level_up: bool)` | todo ganho que passou pelo `_gain_pillar` |
| `growth_requirement_done(phase: String, req_id: String)` | requisito cumprido |
| `growth_ready(phase: String)` | todos cumpridos (selo "pode crescer") |
| `grew(phase: String)` | `GameState.grow()` concluiu |
| `photo_taken(id: String)` | foto nova no álbum |
| `taste_discovered(item: String, reaction: String)` | primeira prova |

## F. Ações do `GameState` (convenção: devolvem `""` ou o motivo; `*_error` igual)

| Ação | Etapa |
|---|---|
| `growth_info()` (consulta pura para a UI) | 02 |
| `_gain_pillar(id, pontos, origem)` (interna) | 03 |
| `deliver_growth_error(item)` / `deliver_growth(item)` | 02 (usada na 10) |
| `grow_error()` / `grow()` | 02 |
| `brush_error()` / `brush()` | 12 |
| `bathe(use_shampoo := false)` (parâmetro novo, padrão igual ao de hoje) | 09 |
| `give_toy_error(item)` / `give_toy(item)` | 14 |
| `hang_photo(id, slot)` / `use_lupa(id)` | 14 / 15 |

## G. Ferramentas DEV (só `BuildInfo.is_dev()`, botões no `DevPanel`, aba "Crescimento")

`dev_set_phase(fase)`, `dev_add_pillar(id, pontos)`, `dev_complete_growth_reqs()`, `dev_take_photo(id)`,
`dev_reset_album()`, `dev_set_favorite(item)`, `dev_set_coat(valor)`. `dev_tools_test -- --prod` confere que
todas ficam desligadas na publicada.
