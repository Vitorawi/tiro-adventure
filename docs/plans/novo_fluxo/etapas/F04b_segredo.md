# F04b — Missão secreta da vovó: o Ensopado Dourado

Plano: `docs/plans/novo_fluxo/README.md` seção 7 e 7.1; decisões F3, F3a, F3b. Mapa: `CLAUDE.md`.
Base: F00–F04 (capítulos 2–11 por sistema, `GameState.only_paws_left()`, desafio do dia na pílula, `SAVE_VERSION` 38).

## Objetivo

Para quem chegou ao fim da lista do Dentinhos antes das patinhas: uma missão secreta, mais difícil, que dá no
máximo **2 patinhas extras na fase**, uma por dia. Quem joga no ritmo normal quase nunca a vê.

## Regras

1. **Quando aparece**: só com `only_paws_left()` verdadeiro (todos os passos do Dentinhos ✓ menos as patinhas) e
   fase `puppy` buscando `teething`. Missão `kind: "line"` da vovó (ex.: `bloblo_secret`, linha própria), com selo
   **"Segredo"** no lugar do "!" no balão do NPC e na lista de Missões (Pessoas). Fala:
   "Psiu... tem um jeito antigo de deixar ele forte mais rápido. Mas não é fácil."
   A pílula do próximo passo continua sendo o desafio do dia; a missão secreta é opcional e mora nas Missões e no
   balão da vovó.
2. **Minhoca gorda** (`golden_worm`, item novo): achado raro do faro (montinhos, `finds.json`), **só com a missão
   ativa**; chance pequena por montinho (ex.: 25%), com garantia no 4º montinho cavado com a missão ativa e sem
   minhoca (sorte, mas sem frustrar). Uma por vez no inventário basta.
3. **Peixe dourado** (`fish_golden`, peixe novo em `fishing.json`): só morde com a isca `golden_worm`; **no máximo
   1 mordida por dia** (do Tiro, virada às 6h); puxada mais forte (dificuldade maior no minigame) e **só vale se a
   pescaria for Perfeita**; se escapar ou não for Perfeita, a minhoca é gasta e só amanhã. Não entra na lista comum de
   peixes nem no robô de pesca normal.
4. **Ensopado Dourado** (`golden_stew`, item novo, refeição): peixe dourado + abóbora + ovo, **só pelo Cozinhar
   junto com 3 estrelas**. Com 1–2 estrelas (ou pela fila), vira um ensopado comum (`fish_stew` ou equivalente que
   já existe) — avise com uma linha curta, sem bronca: "Quase! Saiu um ensopado comum."
5. **Efeito**: dado **ao vivo, na hora** do almoço ou do jantar, vale **uma patinha extra** naquele dia
   (o dia conta 2). Não vale pelo Deixar pronto (tigela) nem fora da janela (aí só mata a fome). Teto: **2 patinhas
   extras na fase** e 1 por dia. Implemente na regra das patinhas (`_register_meal`/`well_fed_days`), guardando o
   extra no estado da semana (ex.: `week.bonus_paws {dia: 1}`), e a cartela (`PawCard`) mostra o carimbo extra
   dourado. Conta para o requisito `well_fed_day` do Dentinhos.
6. **Foto secreta** "O peixe dourado" (seção `secret` do `album.json`, carta fechada como as outras) na primeira
   vez que pescar o peixe dourado. Arte provisória reaproveitando uma ilustração de peixe existente; registrar em
   `docs/plans/primeira_semana/PROVISORIOS.md`.
7. **Ícones**: provisórios (recolorir/derivar ícones existentes em pixel — minhoca, peixe, ensopado — com tom
   dourado; sem PixelLab nesta etapa), registrados em `PROVISORIOS.md`.
8. **Ajuda**: cada parte tem "Como fazer"/Ir (`TaskHelp`) apontando o lugar certo (montinhos, lagoa com a isca,
   fogão com Cozinhar junto); o botão da missão leva ao próximo pedaço que falta.

## Pendência da F04 para fazer junto

- `tools/build_farm_figma.py` está defasado do `game/data/rooms/farm.json` (ainda usa `week_day` e não tem os
  `story_day`/placas "Em breve" da F04). Reconcilie o gerador para produzir exatamente o `farm.json` atual
  (rode e confira que o diff do `farm.json` fica vazio).
- No início do capítulo 4, o cartão "Novo!" do kit do galinheiro mostra "Ir" e um botão amarelo "Pular": confira de
  onde vem o "Pular" (lição sobreposta ao cartão?) e deixe só "Ir" + "Depois" (padrão do "Novo!").

## Saves, testes, docs

- `SAVE_VERSION` +1 (estado novo). Textos em JSON. `docs/ROADMAP.md`, `CLAUDE.md` = `AGENTS.md`, "Andamento": uma
  linha cada. Sem commit, push ou publicação.
- Teste novo `game/tests/secret_stew_test.gd` (suite + áreas `week`, `fishing`, `growth`): missão só aparece com
  `only_paws_left()`; minhoca só com missão ativa e garantia; peixe 1×/dia e só Perfeito; ensopado só 3 estrelas no
  Cozinhar junto (2 estrelas vira comum); patinha extra só ao vivo na janela, 1/dia, teto 2 na fase; tigela não vale;
  foto secreta. Fixar o relógio.
- Rodar `-Level etapa -Exact -Jobs 1` com o teste novo + afetados (`food_lesson_test`, `meal_rules_test`,
  `fishing_*`, `finds_test`, `cook_together_test`, `growth_week_test`, `album_*`, `ato3_*`, `content_test`,
  `texts_test`). Capturas `tests/secret_stew_shots.gd` em 360×780 (selo Segredo, fala, peixe dourado, ensopado,
  cartela com carimbo dourado) e abrir os PNGs.

## Pronto quando

- Quem termina a lista cedo encontra a missão secreta, consegue com esforço no máximo 2 patinhas extras (1/dia),
  e quem joga normal não é afetado. Testes PASS, capturas conferidas.
