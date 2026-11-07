# Fotos do Tiro — validação da etapa 07

06/11/2026, Codex, local. Somente a etapa 07; sem commit, push ou publicação.

## Entrega

- `album.json`: `goal_hint` nas 54 fotos, com texto, ícone existente e destino explícito.
  História aponta para a jornada/Laís/Nina; as demais instruções seguem os eventos e
  condições atuais. Nomes de fase e comida seguem os dados (Aventureiro, Papinha da vovó).
  Contadores úteis: `customer_orders:bloblo` (20) e
  `project_gather:village_festival` (3). Hora/data e sequências temporárias ficam só no
  texto, sem contador artificial. Comparação estrutural com a cópia anterior confirmou
  que TODOS os campos anteriores, incluindo `on`, `when`, `hint`, falas e `cards`,
  continuam iguais; só `goal_hint` foi acrescentado.
- `GameState.photo_hint(id)` devolve `text/icon/have/need/go/revealed`, sem alterar
  estado. Progresso usa `progress.stat` e a consulta real de encomendas por cliente,
  como `AlbumRules`; números exibidos vão de zero à meta.
- `GameState.near_photos(limit)` lista faltantes das seções ativas, exclui segredos
  sem lupa e fotos já obtidas (mesmo fechadas), ordena por fração decrescente e mantém
  a ordem do catálogo nos empates. Sem contador tem fração zero. A faixa `AlbumNear`
  filtra essa consulta por seção e por progresso positivo, até três; nenhum destino
  é inferido a partir do nome do contador. Com os dados reais já mostra Bloblo/encontros.
- Grade: pista concreta, ícone da ação e n/m abaixo da carta faltante. Segredo sem
  lupa mantém verso, ??? e frase poética, sem carregar ilustração, ícone concreto,
  destino ou progresso. `secret_hidden` também usa a consulta do motor.
- `AlbumView.photo_hint(id)` monta `PhotoHint`/`CodexDetail` em madeira: prévia
  grande escura/verso, pista, barra quando há contador, Ir verde via `Places.go`
  (ou `StepCardUi.locked_button` se o mundo/lugar está fechado), lupa para segredo,
  retrato de `hint_npc` + Conversar e Voltar ao álbum amarelos. `secret_detail`
  continua como entrada compatível. Lupa revela o texto concreto na mesma folha.
- Conversar vai a `npc:<hint_npc>` no mundo do personagem; usa a conversa existente,
  sem chamar `album_talk` antecipadamente e sem ignorar seus requisitos/recibos.
- Lupa continua uma por dia, mais uma com câmera, idempotente e protegida contra
  relógio atrasado. A elegibilidade também reconhece o campo explícito `secret`,
  conforme o contrato (o catálogo atual usa as seções Travessuras/Soninhos).

Sem formato/save novo, alterações de obtenção, custos/sorteios, nova classe,
shader ou PNG. PhotoCard, CardViewer, CardReveal, molduras/foil aprovados,
rolagem do caderninho, `drag_scroll.gd` e testes existentes foram preservados.
Sem instalação de lotes ou acesso aos experimentos de raridade.

## Testes

`photo_hints_test` registrado em `suite` e `album` de `tools/test_areas.json`.
Cobre os cinco grupos numerados: 54 textos/ícones; destinos validados e emitidos
por `Places.go`; contador real que sobe; segredo antes/depois da lupa; ordenação
por fração/limite/fotos fechadas fora. Também confere pureza das consultas, data sem
contador, folha de madeira, barra, Conversar e consumo único da lupa.

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests photo_hints_test,album_book_test,album_secrets_test,content_test,texts_test -KeepGoing
```

**6/6 PASS em 65,6 s**. Evidência:
`build/test_logs/r20261106_210206_7eaa30dd/results.csv`.
Scripts 12,9 s; conteúdo 9,1 s; textos 3,1 s; pistas 9,7 s; livro 15,5 s;
segredos 14,4 s. Importação headless final também passou e gerou os `.uid`.

A primeira lista fechada teve somente `texts_test` FAIL pela palavra “corações”;
o objetivo passou a “terceiro coração”, sem alterar o teste/glossário. Um parse
direto inicial exigiu tipos explícitos nas frações e ajuste do nome da cor.
As correções estão incluídas na lista final acima.

Sem portão, campanha ou simulador. SaveManager removido nos testes/capturas novos;
o circuito também usa `TIRO_TEST_TAG`. Nenhum progresso pessoal foi gravado.

## Capturas

`game/tests/fotos_07_shots.gd`, SEM `--headless`, Godot 4.7.2 Compatibility:

- `build/screenshots/fotos_07/`: 360×780.
- `build/screenshots/fotos_07_390/`: 390×844.
- `build/screenshots/fotos_07_412/`: 412×915.

Nove PNGs por resolução, **27 no total**, e três pranchas `_contato.png` abertas
e conferidas: Quase lá com os contadores reais, grade com progresso, faltante com
barra, segredos na grade, antes/depois da lupa, lupa esgotada, pista longa e
hora/condições sem barra artificial. As primeiras capturas de 360 também foram
abertas individualmente. Nenhum dado de foto foi substituído por fixture privada.

Auditorias finais OK: quadro/folha entre HUD e abas, largura dentro da rolagem,
alvos ≥44, texto sem corte interno, NinePatch sem escala torta, imagens em
proporção e até um botão verde. Corte na borda da janela de rolagem é normal.
Retrato teve ajuste local para preservar a proporção da moldura. O save
descartável começa com a Chegada aberta para disponibilizar a aba Álbum;
a câmera é obtida pelo método DEV de fotos e pela regra existente de recompensa.

## Continuação e pendências

Próxima SOMENTE **08 — Varal na home**; prompt em `PROMPT_08.md`.
Motor de featured e CardViewer existentes continuam sendo a base da 08.
Toque Web e aparelho físico pendentes; não foi refeito export Web.
Capturas nativas não substituem validação no celular.
