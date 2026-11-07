# Etapa 09 — Tutorial com a foto da chegada

> Tamanho: médio. Depende de: 05, 06 (e 08 para o último passo). Próxima: 10.
> Resultado que o Vitor vê: na primeira visita ao Álbum (missão "Nossas primeiras lembranças" da Laís), a
> Laís ensina com a foto da chegada (o Tiro na caixinha): abre a carta (sai Comum), tenta a sorte grátis (sai
> Brilhante), melhora com materiais de presente (sai Rara), aprende a inclinar a carta, escolher a versão e
> pôr no varal.

## 1. Ler antes
`01_DESENHO.md` §8 (roteiro, falas e resultados forçados). Código: `quests.json → lais_album` (linha
`lais_memories`, objetivo `stat open:album`, `go {notebook: "album"}`), `GameState.note_screen_opened`,
`photo_alerts_enabled`, `album_tutorial_step/advance_album_tutorial/finish_album_tutorial` (01), `CardReveal`
(05), `CardViewer` (04), varal (08), `SpeechBubble(..., wood)` e `NpcPortrait` (balão da Laís), `Places.go`
com destino `notebook`.

## 2. Como está hoje
A missão `lais_album` pede só abrir o Álbum; a foto `h_arrival` é tirada no fim da chegada (`intro_done`) e,
desde a etapa 01, fica **fechada** até o tutorial. Não há tutorial.

## 3. Passo a passo
1. **Camada de tutorial** (`scripts/ui/album_tutorial.gd`, `class_name AlbumTutorial`): véu que escurece tudo
   menos o alvo do passo (recorte com borda dourada pulsando), balão de madeira da Laís (retrato animado +
   fala, uma linha ou duas), dedo/seta apontando o botão. Só o alvo recebe toque.
2. **Gatilho**: ao abrir o Álbum (`note_screen_opened("album")` / `PetNotebook.open("album")`) com
   `h_arrival` fechada e o tutorial não concluído → começa no passo salvo.
3. **Passos** (falas do §8 do desenho; tudo já forçado pelo motor):
   1. Carta fechada em destaque → toque **Abrir** → revelação (05) com resultado forçado Comum.
   2. No visualizador: `RerollButton` "Tentar a sorte" com selo "Grátis" → a carta vira e revela → Brilhante.
   3. `UpgradeButton` com selo "Presente" e o custo riscado → sobe para Rara (moldura nova + brilho).
   4. Dica de inclinar: dedo animado arrastando sobre a carta; avança quando o jogador arrastar ≥ 60 px.
   5. Versões: toca numa versão para mostrar; mostra as faltantes escuras ("ainda faltam uma").
   6. **Pôr no varal** → fecha o visualizador e mostra a home com a foto no varal (se a 08 estiver feita;
      senão encerra no passo 5).
   Cada passo chama `advance_album_tutorial`; o fim chama `finish_album_tutorial`.
4. **Retomar**: fechar o app ou a tela no meio retoma no mesmo passo na próxima visita ao Álbum. Não há pular.
5. Depois do tutorial: aviso curto "Você tem N fotos para abrir!" se houver outras fechadas.
6. Texto das falas: as do §8 (falas novas da Laís; nenhuma fala existente muda).

## 4. Não fazer
Mudar a missão `lais_album` (objetivo/prêmio), dar itens de verdade, deixar o tutorial forçar resultado fora
dele.

## 5. Armadilhas
- A fila modal pode ter cartões esperando (capítulo, Novo!): o tutorial começa só com a fila vazia.
- O "Ir" da missão leva ao caderninho na aba Álbum: o tutorial precisa esperar o quadro montar (um quadro).
- Save novo em teste: `h_arrival` existe fechada depois de `mark_seen("intro")`.

## 6. Testes
Novo **`tests/album_tutorial_test.gd`** (área `album`, mais `story`):
1. Save novo → intro → `lais_play` concluída → abrir o Álbum inicia o tutorial no passo 1.
2. Abrir dá Comum; rolar grátis dá Brilhante; melhorar grátis dá Rara; moedas/materiais e garantias intactos.
3. Só o alvo recebe toque em cada passo (tocar fora não avança).
4. Fechar no passo 3 e reabrir o Álbum retoma no passo 3.
5. Fim: `tutorial.done`, `h_arrival` no varal, missão `lais_album` cumprida.
6. Depois do fim, abrir outra carta sorteia normal (nada forçado).
Lista fechada: `album_tutorial_test,card_reveal_test,card_viewer_test,photo_rarity_test,quest_reward_test,album_test`.
Capturas `tests/fotos_09_shots.gd` (3 resoluções): um PNG por passo.

## 7. Pronto quando
O tutorial inteiro roda de ponta a ponta em um save novo, testes passam, capturas olhadas.
