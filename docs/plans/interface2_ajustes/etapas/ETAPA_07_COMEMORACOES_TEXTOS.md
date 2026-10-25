# Etapa 07 — Comemorações e textos

> Tamanho: médio. Depende de: 06. Próxima: 08.
> Itens da revisão: **16** (cartão de capítulo com muitas novidades estoura a altura) e **31** (textos do
> Novo! e do passeio — **textos aprovados pelo Vitor**).
> Resultado que o Vitor vê: o cartão "Capítulo concluído!" mostra sempre a fita e o herói, com as novidades
> numa grade de chips, sem repetir "Sítio"; a folha "Novo!" diz **onde** a coisa está e o botão diz para onde
> vai ("Ir para a Vila"); a volta do passeio diz "Voltou do passeio!".

## 1. Objetivo
Arrumar o cartão grande do capítulo e trocar três textos por versões que informam (onde está, para onde vai,
quem voltou).

## 2. Ler antes
`REVISAO_OPUS.md` itens 16 e 31; `02_JORNADA.md` §4 (grande = fita + ícone com raios; médio = folha);
`docs/plans/interface2/etapas/ETAPA_10_FESTA.md` (como `ModalCard`/`RewardSheet` ficaram).

## 3. Arquivos
| Arquivo | Itens |
|---|---|
| `game/scenes/ui/celebration/celebration.gd` (`_unlock_rows` ~156, `_unlock_line` ~146, folha Novo! ~129–143) | 16, 31 |
| `game/scripts/ui/modal_card.gd` (área rolável só para a grade) | 16 |
| `game/scenes/ui/walk_result/walk_result.gd` (linha ~22: `"Roupa pronta!" if sewing else "De volta!"`) | 31 |
| `game/tests/walk_return_ui_test.gd` (linha ~124 procura "De volta!"), `texts_test` | 31 |

## 4. Como está hoje (estado esperado ao começar)
- `_unlock_rows` monta **uma linha (cartão) por novidade** dentro do `ModalCard` do capítulo (ícone 48 +
  "Novo!" em `UiKit.GOOD` + nome em `SectionLabel` + `ctl_button chev`). Com 5 novidades o cartão rola e
  esconde a fita "Capítulo concluído!" (`i2_05_chapter`), com repetições (lugar e mundo "Sítio").
- Folha "Novo!" (`RewardSheet`, nó `UnlockGo`): título = nome, linha `_unlock_line` = "Um mundo novo para
  explorar" / "Um lugar novo" / "Uma nova amizade" / "Um passeio novo"; botões "Depois" / "Ir".
- Passeio: fita "De volta!" logo acima de "Volta na praça" ("volta" duas vezes).
- `worlds.json` tem `in_name` por mundo ("na Casa", "no Sítio", …).

## 5. Passo a passo

### 5.1 Capítulo com grade de novidades (item 16)
1. No `ModalCard` do capítulo, fita e herói **fixos**; só a área das novidades rola (se rolar).
2. Novidades viram **grade de chips** (3 por linha): ícone 40 + nome em `SmallLabel`/legenda numa linha
   (reticências), tocável (leva com `Places.go(target)`, como o chev de hoje). Sem "Novo!" em cada um (a
   seção já diz "Novidades").
3. **Juntar repetições**: se duas novidades levam ao mesmo destino (`target` igual, ou mundo X e lugar
   dentro de X com o mesmo nome visível), mostre uma só (a do mundo).
4. `festa_test`: caso com 6 novidades → fita e herói visíveis (retângulo dentro do cartão sem rolar) e
   nenhum nome repetido.

### 5.2 Textos aprovados (item 31)
1. `_unlock_line(key)` diz **onde**:
   - mundo → **"Já está no Mapa"**;
   - lugar → o `in_name` do mundo do lugar com maiúscula: **"No Sítio"**, "Na Vila", "Na Casa";
   - amizade (npc) → o `in_name` do mundo do personagem: **"Na Praça"** para a Nina/Pipoca;
   - passeio → "Na Praça" (passeios saem do portão da Praça);
   - outro → mantém "Uma novidade".
   Pegue o mundo pelo `Places.unlock_view(key)`/`target`; não escreva mundo fixo no código.
2. Botão: **"Ir para " + destino**, derivado do `in_name` (tire a preposição: "na Vila" → "Ir para a Vila";
   "no Sítio" → "Ir para o Sítio"). Para mundo, o destino é o próprio mundo. Nó continua `UnlockGo`.
   Se o texto passar da largura do botão em 360, use "Ir" (e registre o caso).
3. `walk_result.gd`: `"De volta!"` → **"Voltou do passeio!"**; "Roupa pronta!" continua. O nome do caminho
   continua embaixo.
4. `walk_return_ui_test.gd:124`: o teste passa a procurar "Voltou do passeio!" (mesma garantia: o título do
   cartão). `texts_test` e `tools\list_texts.ps1 -ByScreen` conferem o glossário (Ir/Pegar/…).

### 5.3 Armadilhas
- A fila modal (`main.gd._queue_modal`) não muda: só o conteúdo do cartão.
- Com `Motion.reduced`, a grade aparece de uma vez (o `reveal` já trata).
- `quest_reward_test` abre o capítulo pelo fluxo real: rode-o.

## 6. Testes
- Lista: `festa_test,quest_reward_test,walk_return_ui_test,welcome_test,texts_test,text_budget_test`
  (~1 min 40).

## 7. Capturas
Bloco `--aj-07-only`: `i2_05_chapter`, `h02_chapter_card`, `i2_10_chapter`, `i2_10_unlock` (mundo, lugar e
amizade: crie `aj_07_unlock_place` e `aj_07_unlock_npc` se o tour só tiver um), `i2_10_walk`, `c04_walk_result`.
Antes e depois nas 3 resoluções.

## 8. Pronto quando
- [ ] Capítulo com fita e herói sempre visíveis; novidades em grade, sem repetição.
- [ ] Folha Novo! com "Já está no Mapa" / "No <mundo>" / "Na Praça" e botão "Ir para …".
- [ ] Passeio com "Voltou do passeio!".
- [ ] Testes verdes; nenhuma fala da história mudou (só textos de interface aprovados).

## 9. Handoff
Pontos naturais: após 5.1 e após 5.2. Diga como o destino do botão é derivado e quais casos caíram em "Ir".

## 10. Registro
```
**Etapa 07 (data, executor[es]):** capítulo com fita/herói fixos e grade de novidades sem repetição; Novo!
diz onde está ("Já está no Mapa", "No Sítio", "Na Praça") e "Ir para …" (textos aprovados pelo Vitor);
passeio "Voltou do passeio!". Testes … PASS em … s. Pendências: … Sem push.
```
