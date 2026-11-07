# Etapa 05 — Abrir a foto nova (carta surpresa + festa, sem roleta)

> Tamanho: grande. Depende de: 04. Próxima: 06.
> Resultado que o Vitor vê: quando o Tiro ganha uma foto, aparece "Nova foto surpresa!" com a carta virada;
> **Abrir** vira a carta e a arte revela já na versão sorteada, com festa do tamanho da raridade; no fim, a
> carta fica no visualizador da etapa 04. **Não há roleta** (decisão do Vitor): a "sorte" é só o botão
> **Tentar a sorte** dentro da carta.

## 1. Ler antes
`01_DESENHO.md` §4, §10.4. Código: `scenes/main/main.gd` (`_photo_queue`, `_show_photo_toast`,
`_queue_modal`, linha ~108 `photo_taken`), `scripts/ui/notice.gd` (aviso "Nova foto!"), `CardViewer` (04),
`scripts/ui/modal_card.gd` (confete, `Haptics`), `scenes/ui/welcome_back/` (`Line_photo` nas boas-vindas).

## 2. Como está hoje
`photo_taken` → `_photo_queue` → aviso tocável "Nova foto!" (`Notice` kind `photo`) que abre o detalhe.
Só depois de conhecer o Álbum (`photo_alerts_enabled`). Sem festa.

## 3. Passo a passo
1. **`scripts/ui/card_reveal.gd`** (`class_name CardReveal`, `--import`): sequência sobre o visualizador:
   a) verso de madeira (pata do Tiro; gere `assets/sprites/ui/album/card_back.png` no mesmo script de arte
   das molduras) cai com "Nova foto surpresa!" + título da foto + botão verde **Abrir**;
   b) toque em Abrir → `GameState.open_photo_card(id)` (o resultado já vem decidido), a carta vira (0,4 s) e
   a arte revela branco → imagem (0,6 s) **já com a moldura/efeito do nível sorteado**; o selo do nível
   (`RevealSeal`) aparece com um pulinho;
   c) festa por nível: 1 pulinho; 2 brilho curto; 3 confete leve + `Haptics.success`; 4 confete cheio +
   flash arco-íris + `Haptics.big`; texto "Rara!" etc. Versão repetida: "Você já tinha esta versão";
   d) entrega para o `CardViewer` (mesma carta, sem fechar e reabrir) com as ações da etapa 04.
   "Menos animação": sem virar nem revelar, carta já aberta no resultado.
2. **Fila**: `photo_taken`/`photo_sealed` passam a enfileirar pela fila modal (`_queue_modal`), uma carta por
   vez, nunca junto com outro cartão; o aviso "Nova foto!" vira só lembrete quando o jogador está no meio de
   algo (ex.: arrastando, minigame): tocar nele abre a revelação. Fotos tiradas antes de conhecer o Álbum não
   abrem sozinhas (ficam em "Para abrir"; o tutorial cuida da primeira).
3. **Tentar a sorte / Melhorar**: o `CardViewer` chama `CardReveal.play_result(id, result)`: Tentar a sorte =
   a carta vira de costas e volta (0,6 s) na versão sorteada; Melhorar = a moldura sobe um degrau com brilho e
   o selo novo. Mesma festa por nível do item 1c.
4. **Boas-vindas**: `Line_photo` passa a dizer "N fotos para abrir" e o Ir abre a primeira carta fechada.
5. DEV: botão no `DevPanel` (aba Álbum, se houver) "Carta fechada" que usa `dev_seal_photo`.

## 4. Não fazer
Roleta, fileira de níveis acendendo, caça-níquel ou qualquer "giro" de sorteio. Mudar o sorteio (já decidido
no motor), juntar com outros cartões, abrir carta sozinha fora da fila.

## 5. Armadilhas
- O resultado é sorteado **antes** da animação; a animação só encena. Fechar o app no meio não pode perder nem
  repetir: o estado já foi gravado ao tocar em Abrir; ao voltar, a carta aparece aberta.
- A fila modal pode estar segurando o capítulo/Novo!: a carta entra depois deles.

## 6. Testes
Novo **`tests/card_reveal_test.gd`** (área `album`):
1. `photo_taken` com o Álbum conhecido enfileira uma revelação (uma vez).
2. Abrir chama `open_photo_card` uma vez; ao fim, a carta mostra o nível devolvido (`RevealSeal`).
3. "Menos animação": resultado direto, sem animação.
4. Duas fotos seguidas: duas revelações em sequência, nunca juntas.
5. Fechar no meio e reabrir: carta aberta, sem novo sorteio.
6. Tentar a sorte pelo visualizador vira a carta e termina na versão nova; repetida mostra o aviso.
Lista fechada: `card_reveal_test,card_viewer_test,photo_rarity_test,festa_test,notice_test,welcome_test`.
Capturas `tests/fotos_05_shots.gd`: verso, meio do virar, final em cada um dos 4 níveis, repetida.

## 7. Pronto quando
Testes passam, capturas olhadas, a sequência completa leva ≤ 3 s e dá vontade de abrir a próxima.
