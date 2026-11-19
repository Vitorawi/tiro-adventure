# E04. Cozinhar junto

Plano: [`../README.md`](../README.md) (E04) · regras: [`../REGRAS.md`](../REGRAS.md) (D7, D8) · cozinha: [`ETAPA_03_cozinha_completa.md`](ETAPA_03_cozinha_completa.md).
Telas de referência: canvas "Cozinha interativa do Tiro" (Passos, Picar, Mexer, Servir, Prato pronto, Prova), lidas em 18/11/2026.

## Arquivos envolvidos

- `game/data/cooking.json` (novo): números do minigame, cores dos ingredientes e textos.
- `game/scripts/state/cook_rules.gd` (novo, `CookRules`): funções puras (brilho de cada gesto, estrelas, corte de tempo).
- `game/autoload/game_state.gd`: `cook_many/cook_dish/cook_invented` ganham `stars` e `together`; `_note_recipe(recipe, stars)`; `cook_serve_now`; `taste_line`.
- `game/autoload/database.gd`: `cooking` (carrega o JSON) e `cooking_problems()`.
- `game/scripts/ui/cook_together.gd` (novo, `CookTogether`): overlay de tela cheia com Picar, Mexer, Servir e a tela Prato pronto (ModalCard de madeira).
- `game/scripts/ui/cook_panel.gd` (`TogetherButton`, `start_together`) e `cook_invent.gd` (`InvCookButton` abre o minigame).
- Testes: `cook_together_test` (novo); `cook_panel_test`, `cook_invent_test`, `cook_dishes_test` ajustados (agora o botão abre o minigame; os testes usam Pular).
- Capturas: `tests/cook_together_shots.gd`.

## Regras fechadas

- **Passos da semana 1**: todo prato passa por Picar → Mexer → Servir (D8). Os gestos novos da prancha "Passos" (Amassar, Tirar espinha, Arrumar, Abrir massa, Carimbar, Decorar) ficam para depois da semana 1. Gororoba não abre o minigame (só enche a barriga): cozinha direto, como na E03.
- **Picar**: cada ingrediente da panela passa pela tábua, um de cada vez. Deslizar de cima para baixo cortando perto da linha tracejada (a linha anda para o meio do que sobrou). Total de 6 cortes divididos pelos ingredientes (2 a 6 por ingrediente). Perto da linha: Perfeito! (3), mais ou menos: Boa! (2), longe: Torto (1). Cortar torto só deixa o pedaço torto, não há relógio.
- **Mexer**: girar o dedo em volta da panela. O anel enche enquanto a velocidade do giro está boa (devagar demais ele para; rápido demais saem respingos, nada queima). Precisa de 8 s de giro bom; brilho pelo tempo total (até 10,7 s = 3; até 16 s = 2; depois = 1).
- **Servir**: tocar a panela enche a concha; arrastar até o anel da tigela e soltar. Duas conchas. Centro do anel = 3, dentro do anel = 2, fora a concha volta e tenta de novo; cada tentativa errada tira 1 (mínimo 1). No fim, jogar o coração na tigela fecha o prato (não pontua).
- **Estrelas**: soma dos três passos (3 a 9): 3 a 4 = 1 estrela, 5 a 7 = 2, 8 a 9 = 3.
- **Tempo**: cada estrela corta o tempo da fila: 1 = −25%, 2 = −50%, 3 = −75%. O corte é gravado no lote (`job.seconds`) quando ele entra na fila.
- **Pular** (qualquer passo): cozinha como o botão Cozinhar (1 estrela, tempo cheio) e fecha o minigame. **Sair** (X ou Esc): não gasta nada. Os ingredientes só são gastos ao terminar o Servir (ou ao Pular).
- **Prato pronto** (ModalCard): nome, estrelas, chip de tempo cortado, nutrientes, "pronta em". **Dar ao Tiro** serve na hora (o lote sai da fila na hora e o Tiro come; abre a tela do Tiro e mostra a reação de paladar). **Guardar** deixa o lote na fila já com o tempo cortado.
- **Melhor estrela**: `week.dishes` guarda o maior valor (prato do motor por `_note_dish`, receita fixa por `_note_recipe`). Receita fixa não muda de nutrientes com a estrela (só o prato do motor muda: a estrela vai no id do item).
- **Acessibilidade**: Menos animação desliga confete, tremidos e pulinhos; Vibrar dá um toque leve a cada brilho (`Haptics.tap`) e um maior ao fechar cada passo.
- **Tiro espiando**: o retrato do filhote espia na borda de baixo e pula no Perfeito! (provisório, `PROVISORIOS.md`).

## Passo a passo

1. `cooking.json`, `CookRules` e `Database.cooking`.
2. `GameState`: parâmetros `stars`/`together`, `cook_serve_now`, `taste_line`.
3. `CookTogether`: moldura do overlay, barra dos 3 passos, Pular/Sair, os três gestos, Tiro espiando, resultado.
4. Ligar `TogetherButton` e `InvCookButton`.
5. `cook_together_test`, ajustes dos três testes, capturas nas três resoluções, PROVISORIOS, README/ROADMAP/CLAUDE/AGENTS.

## Testes

`cook_together_test` (área `dishes`, `suite`): regras puras (brilhos, estrelas, corte); começar sem gastar; sair no meio não gasta; Pular cozinha 1 estrela e tempo cheio; os três passos por toque real (eventos de mouse no overlay) com 3 estrelas e tempo −75% no lote; 1 estrela por cortes tortos/giro lento e retry da concha; Dar ao Tiro serve na hora e o Tiro come; Guardar mantém na fila; Gororoba não abre o minigame; Menos animação e Vibrar.

## Pronto quando

Os três passos funcionam por toque real em 360×780 e `cook_together_test` cobre estrelas, pular e sair no meio.
