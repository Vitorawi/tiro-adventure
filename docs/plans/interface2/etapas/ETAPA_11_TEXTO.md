# Etapa 11 — Texto mínimo, "Texto maior" e limpeza

> Tamanho: médio. Depende de: 10. Próxima: 12.
> Resultado que o Vitor vê: menos palavras em todas as telas (só o que o gesto não ensina); opção "Texto
> maior" em Configurações; nada de sobra do visual antigo.

## 1. Ler antes
`04_REGRAS_E_TESTES.md` §C (orçamento de texto); glossário em `docs/GAME_DESIGN.md`; `tools/list_texts.ps1`.

## 2. Como está hoje
- `tools/list_texts.ps1` gera `build/texts.csv` com os textos visíveis; `texts_test` (3 s) guarda o glossário
  (Pegar/Colher/Cozinhar/Fazer/Buscar/Ir).
- Preferências do aparelho em `settings.json` via `SaveManager.set_vibrate/set_reduced_motion`
  (`Haptics.enabled`, `Motion.reduced`), linhas em `SettingsPanel._toggle_row`.
- Apelidos antigos na `Palette` (01), `add_theme_font_size_override` restantes (lista do registro da 01),
  PNGs de controle antigos (`ui_close`, `ui_lock`, `ui_check`, `settings`, `ui_recenter`, `timer`),
  `Jersey10.ttf`.

## 3. Passo a passo
1. **Orçamento:** `tools/list_texts.ps1 -ByScreen` (novo parâmetro): agrupa `build/texts.csv` por tela do
   tour e conta palavras fora nomes/números. Corte instruções redundantes até caber no §C. Falas da história
   (`dialogue`, `introduction`, `greeting`) **não** se mexem (pedido antigo do Vitor).
2. **Texto maior:** `SaveManager.set_large_text(on)` / `large_text_enabled()` gravando `large_text` em
   `settings.json` (padrão desligado); ao abrir o jogo e ao trocar, multiplicar por 1,15 os tamanhos das
   variações do tema (`Theme.set_font_size` em `TitleLabel`, `StrongLabel`, `Label`/padrão, `SmallLabel`,
   `ChipLabel`, `NumberLabel`, `BadgeLabel`, botões) a partir dos valores originais guardados (não acumular).
   Linha em Configurações com `UiKit.toggle` (`LargeTextToggle`). Conferir 412×915 e 360×780 com ele ligado:
   nada corta (listar e consertar o que cortar).
3. **Limpeza:** remover os apelidos da `Palette` (trocar cada uso pelo nome novo: `Select-String`), os
   `add_theme_font_size_override` restantes, os PNGs de controle sem uso (confira `Select-String` em `game/`
   e nos testes antes de apagar) e a `Jersey10.ttf` se nada mais usar (o `story_symbols.fnt` fica).
4. Glossário: acrescentar "Pegar tudo (N)", "Depois", "Ir para <lugar>", "Cuidar" em `docs/GAME_DESIGN.md`.
5. Tour `--i2-11-only` = `--i2-01-only` com "Texto maior" ligado (`i2_11_*`).

## 4. Não fazer
Reescrever falas de personagem; mudar nomes de itens/lugares.

## 5. Testes
**`game/tests/text_budget_test.gd`** (área `checks`): monta as telas principais (Tiro, Missões nas 3 abas,
Mochila, bandeja do fogão, barra da horta, folha de prêmio) e conta as palavras visíveis de `Label`/`Button`
que não são nome de item/lugar/personagem (use `Database` para reconhecer nomes) nem números; confere o
máximo de 04 §C por tela; com "Texto maior", confere que nenhum `Label` de uma linha passa da largura do pai.
**Comando:** `tools\test.ps1 -Level etapa -Exact -Tests text_budget_test,texts_test,content_test,ui_style_test` (~40 s).

## 6. Pronto quando
- [x] Orçamento respeitado; "Texto maior" funciona nas 3 resoluções; limpeza feita sem quebrar testes.

## 7. Registro
```
**Etapa 11 (data, executor):** orçamento de texto aplicado (N palavras cortadas), Texto maior (settings.json),
apelidos/overrides/PNGs antigos removidos. Testes … PASS em … s.
```
