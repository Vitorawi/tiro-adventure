# Etapa 06 — Missões, caderninho e fontes pequenas

> Tamanho: médio. Depende de: 05. Próxima: 07.
> Itens da revisão: **22** ("Neste capítulo" pesado; nomes quebrando), **24** (segmentado de uma opção;
> rótulo cortado no caderninho; selo "∞"), **25** (fontes menores que 12), **29** (história concluída =
> cartão vazio).
> Resultado que o Vitor vê: o capítulo com ✓ e cadeado pequenos e linhas leves; nomes de Pessoas/Diárias
> numa linha em 360; nenhuma pílula gigante de uma opção só; o caderninho mostra "Álbum" inteiro; nada com
> letra menor que 12; e, no fim da história, um cartão "Nosso lugar no mundo ✓".

## 1. Objetivo
Deixar as listas das Missões e do caderninho no peso do protótipo e fechar as exceções de fonte que o
"Texto maior" não escala.

## 2. Ler antes
`REVISAO_OPUS.md` itens 22, 24, 25, 29; `03_TELAS.md` "Missões" e "Caderninho"; `01_BIBLIA_VISUAL.md` §A
(tamanhos) e §F (`segmented`, `list_row`); protótipos `prototipo/missoes2_historia.png`,
`missoes2_personagens.png`, `missoes2_diarias.png`.

## 3. Arquivos
| Arquivo | Itens |
|---|---|
| `game/scenes/ui/tasks_screen/tasks_screen.gd` (`ChapterSteps`, `ChapterStep_<id>`, linhas de Pessoas/Diárias, história concluída) | 22, 24, 29 |
| `game/scripts/ui/progression_ui.gd` (linhas compartilhadas de missão, se as linhas de Pessoas nascem ali) | 22 |
| `game/scripts/ui/ui_kit.gd` (`segmented`) | 24 |
| `game/scripts/ui/pet_notebook.gd` (`NotebookTab_<id>`, `TAB_ICONS`) | 24 |
| `game/scripts/ui/album_view.gd` (selo "∞", linha ~89 com fonte 6) | 24, 25 |
| `game/scripts/ui/photo_card.gd` (~116/125/135: 9–13 px com escala) | 25 |
| `game/scenes/entities/npc_world/npc_world.gd` (~42: 28 px), `game/scripts/ui/motion.gd` (~224: 22 px) | 25 |
| `game/assets/theme/main_theme.tres` (variações novas, se precisar), `game/scripts/ui/large_text.gd` | 25 |

## 4. Como está hoje (estado esperado ao começar)
- "Neste capítulo": linhas com discos de 44 (› e cadeado) pesados; no protótipo são ícones de 20. O › em
  disco rouba largura e os nomes quebram em duas linhas (`i2_05_story`, `i2_05_people`, `i2_05_daily`).
- Com uma só seção (Missões no início do jogo: só "História"; Álbum com uma seção), `UiKit.segmented` vira
  uma pílula gigante de uma opção.
- Caderninho: dois segmentados empilhados; o rótulo ativo do Álbum aparece cortado ("·· Álbum"); a seção do
  Álbum tem um selo vermelho com "∞".
- Fontes fora do tema: `album_view.gd:89` (6 px), `photo_card.gd` (9–13 com escala), `npc_world.gd:42`
  (28, selo "!"), `motion.gd:224` (22, texto flutuante). O "Texto maior" não escala nenhuma.
- História concluída: a aba História mostra um cartão vazio.

## 5. Passo a passo
1. **Capítulo leve (22):** em `ChapterSteps`, ✓ e cadeado como `UiKit.ctl` de 20 sem disco; linha de 56;
   passo atual com fundo `HONEY_SOFT`, sem o › grande. Pessoas/Diárias: `›` como `ctl chev` 20 sem disco.
   Conferir em 360 que os nomes cabem numa linha (se ainda quebrar, reduzir o padding, não a fonte).
2. **Segmentado de uma opção (24):** `UiKit.segmented` com uma opção só não desenha nada (devolve o
   contêiner vazio e invisível, mantendo o nó com o nome para os testes que o procuram). Missões no início
   e o Álbum de uma seção ficam sem a pílula.
3. **Caderninho (24):** um segmentado só. Opção A (preferida): rótulos sempre visíveis, com ícone 20 +
   texto, rolagem horizontal se não couber. Opção B: só ícones e o rótulo da aba ativa **fora** da pílula,
   como título pequeno. Nada cortado. Tire o selo vermelho "∞" da seção do Álbum (não é alerta).
4. **Fontes < 12 (25):** cada caso vira uma variação do tema (ex.: `PhotoCaptionLabel`, `WorldBadgeLabel`,
   `FloatLabel`) com o tamanho atual como base, para que `LargeText.apply` a escale junto; ou, se for "texto
   do mundo" (polaroide, que escala com a foto), documente isso num comentário e faça o `LargeText`
   multiplicar também esse caso. O 6 px do `album_view.gd:89` sobe para ≥ 12 ou some (é um selo: vire
   `UiKit.badge`). `text_budget_test` ganha a regra: nenhum `add_theme_font_size_override` < 12 fora da lista
   branca documentada.
5. **História concluída (29):** cartão "Nosso lugar no mundo ✓" (`StrongLabel` + ✓ verde), linha
   "História completa ›" (abre a lista dos capítulos já feitos, que hoje existe na sanfona) e um atalho
   calmo para o Álbum (`small_go`, leva a `PetNotebook.open("album")`). Sem botão verde.

### 5.1 Armadilhas
- `tasks_groups_test`/`tasks_test` esperam personagens recolhidos e Diárias/Semanais juntas na aba Diárias:
  não mude o agrupamento.
- `quest_reward_test` usa a pílula e `ChapterStep_<id>`: mantenha os nomes.
- `album_test` conta seções e procura `NotebookTab_album`: se a pílula de uma opção some, o nó continua.

## 6. Testes
- Lista: `tasks_test,tasks_groups_test,quest_reward_test,album_test,album_secrets_test,lists_test,text_budget_test,ui2_kit_test`
  (~2 min 50).

## 7. Capturas
Bloco `--aj-06-only`: `i2_05_story`, `i2_05_people`, `i2_05_people_open`, `i2_05_daily`, `i2_08_notebook_manual`,
`i2_08_collection`, `i2_08_album`, Missões no começo do jogo (crie `aj_06_tasks_first`), história concluída
(crie `aj_06_story_done`, com `dev_complete_quest` até o fim). Antes e depois nas 3 resoluções, e o
`--i2-11-only` com Texto maior para conferir as fontes que agora escalam.

## 8. Pronto quando
- [ ] Capítulo com ícones de 20 e linhas de 56; nomes numa linha em 360.
- [ ] Nenhum segmentado de uma opção visível; caderninho sem rótulo cortado; sem "∞" vermelho.
- [ ] Nenhuma fonte < 12 fora da lista branca; as que ficaram escalam com Texto maior.
- [ ] História concluída com cartão próprio.
- [ ] Testes verdes.

## 9. Handoff
Pontos naturais: após cada passo 1–5. No passo 4, liste as variações de tema criadas.

## 10. Registro
```
**Etapa 06 (data, executor[es]):** capítulo com ícones 20 e linhas 56; segmentado de uma opção some;
caderninho com <opção A/B>; fontes < 12 → variações <...>; história concluída com "Nosso lugar no mundo ✓".
Testes … PASS em … s. Pendências: … Sem push.
```
