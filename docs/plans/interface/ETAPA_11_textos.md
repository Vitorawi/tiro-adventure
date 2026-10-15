# Etapa 11 — Textos: um verbo por ação, frases que falam com o jogador

> **Mensagem para o agente:** "Leia CLAUDE.md, docs/plans/interface/00_VISAO.md,
> docs/plans/interface/01_REGRAS_E_ESTILO.md e execute docs/plans/interface/ETAPA_11_textos.md."
> Pré-requisito: Etapas 00–10. (As etapas anteriores já usam o glossário nas telas que refizeram; esta é a
> varredura final de **tudo** o que sobrou.)

## Objetivo (o que o jogador sente)
"O jogo fala comigo de um jeito só, curto e carinhoso." Sem "Fechado · Conclua:", sem "Nv", sem
"Recolher" num lugar e "Coletar" no outro.

## Leia antes
`01_REGRAS_E_ESTILO.md → D` (voz, glossário, números). Todos os `game/data/*.json` com texto visível
e as chamadas `UiKit.label/button/chip`, `Events.toast_requested.emit(...)`, retornos de `*_error()` no
`game_state.gd`, `task_help.gd`, `places.gd`.

## Passo a passo

### 11.1 Lista de todos os textos visíveis — `tools/list_texts.ps1`
- [ ] Script que gera `build/texts.csv` (colunas: arquivo, linha/caminho JSON, texto):
  - JSON: campos `name`, `description`, `dialogue`, `label`, `map_name`, `map_caption`, `instruction`,
    `action_label`, `queue_label`, `recipe_label`, `hint`, `introduction`, `postcard`, `note`, falas em listas;
  - GDScript (`scripts/ui`, `scenes`, `autoload/game_state.gd`): literais entre aspas dentro de
    `label(`, `short_label(`, `fill_label(`, `button(`, `primary(`, `secondary(`, `ghost(`, `chip(`,
    `toast_requested.emit(`, `return "` (nos `*_error`), `text = "`.
- [ ] Leia em UTF-8 (`Get-Content -Encoding utf8`) e escreva com `Out-File -Encoding utf8`.

### 11.2 Reescrever
- [ ] Aplique o glossário (`01 → D.2`) em tudo. Casos já conhecidos (confira a lista do CSV, há mais):
  | Onde | Hoje | Depois |
  |------|------|--------|
  | `sheet_builder.gd` estação | "Coletar prontos (%d)" | "Pegar tudo (%d)" |
  | `nature_ui.gd` | "Recolher prontos (%d)", "Coletar" | "Pegar tudo (%d)", "Buscar" |
  | `nature_ui.gd` | "Nível %d · Máximo", "Nv %d" | "Nível %d ★" (máximo), "Nível %d" |
  | `progression_ui.gd` rotas/passeio | "Recolher" | "Pegar" |
  | `progression_ui.gd` atributos | "Nv %d", "Máx.", "Nv %d →", "Fechado" | "Nível %d", "★ completo", "Nível %d:" , cadeado |
  | `progression_ui.gd`/`wish_ui.gd`/`task_help.gd`/`find_ui.gd` | "Receber" | "Pegar prêmio" (missão) / "Pegar" (achado, desejo pronto) |
  | `station_indicator.gd`, `route_indicator.gd`, `walk_indicator.gd` | "Coletar", "Recolher %d" | (balões da Etapa 06 já não têm texto; se sobrar: "Pegar") |
  | `places.gd` | "%d pronto(s) para coletar!", "Ainda fechado: " | "%d prontos!" (1 = "1 pronto!"), "Ainda não: " |
  | `worlds_screen.gd` | "Algo pronto para recolher!" | (seletor da Etapa 05 já usa "N prontos") |
  | `sheet_builder.gd` animais | "Seus animais · %d/%d" | (bandeja da Etapa 08; no painel: "%d de %d animais") |
  | `sheet_builder.gd` | "Expandir o sítio" | "Abrir área" |
  | `game_manual.gd` | "Onde produzir", "Onde coletar", "→ recolher" | "Onde fazer", "Onde buscar", "→ pegar" |
  | `game_state.gd` | "Nada para recolher", "Conclua a atividade em andamento" | "Nada pronto ainda", "Termine o que está fazendo" |
  | `main.gd` | tooltip "Comece por aqui!" | (some; a aba pulsa) |
  | `config.json → stations.*.action_label` | "Produzir"/"Preparar" | fogão/liquidificador "Cozinhar"; bancada/moinho/queijaria/ateliê "Fazer"; costura "Costurar"; animais "Alimentar" |
  | `config.json → queue_label/recipe_label` | "Preparando", "Receitas" | (bolinhas não usam rótulo; no painel "Ver tudo": "Na fila", "Receitas") |
- [ ] Frases com "·" juntando duas ideias: separe em título + chip/ícone, ou reescreva numa frase.
- [ ] Erros (`*_error`) curtos e com o que fazer: "Falta 🥕 2" é melhor que "Ingredientes insuficientes"
  (use o nome do item quando não der ícone: "Faltam 2 cenouras").
- [ ] Falas (`dialogue`, `introduction`) **não** reescreva o conteúdo da história; só corrija "·",
  abreviações e erros de digitação.
- [ ] Toasts de sucesso que repetem o que a animação já mostra ("Plantou Cenoura!") saem — a animação basta.

### 11.3 Guarda automática — `game/tests/texts_test.gd`
- [ ] Lê os mesmos JSON e scripts do 11.1 e falha se algum texto visível tiver: `"Recolher"`, `"Coletar"`,
  `"Conclua:"`, `" · Conclua"`, `"Nv "`, `"Máx."`, `"capítulo %d"`, `"x0"`, `"Produzir"`. Lista de exceções
  explícita no próprio teste (ex.: comentários, ferramentas DEV, nomes de id).

## Testes
- [ ] Todos os testes passam (vários procuram textos de botão: atualize-os junto e anote quais).
- [ ] `texts_test` passa.

## Capturas
Tour completo `etapa11_antes`/`etapa11_depois`. Leia **todas** as telas procurando texto estranho.

## Lista de conferência (aceite)
- [ ] `build/texts.csv` revisado; nenhuma palavra proibida fora das exceções.
- [ ] Glossário do `01_REGRAS_E_ESTILO.md` copiado para `docs/GAME_DESIGN.md` (seção "Voz do jogo").
- [ ] CLAUDE.md/AGENTS.md: em "Convenções → Visual e simples", uma linha "Verbos: Colher, Pegar, Cozinhar,
  Fazer, Buscar, Ir (glossário em docs/GAME_DESIGN.md)".
- [ ] ROADMAP e README marcados; commit `feat(ui): textos revisados com glossário único`.
