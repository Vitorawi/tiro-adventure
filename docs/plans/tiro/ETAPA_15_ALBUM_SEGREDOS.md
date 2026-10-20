# Etapa 15 — Álbum: travessuras, soninhos, amigos e datas

**Estado: concluída em 19/10/2026 (Codex).** Evidência: [VALIDACAO_15](VALIDACAO_15.md). Executar somente esta etapa. Pré-requisito: etapa 14 concluída.

## Objetivo

"Tem fotos escondidas no álbum, com uma frase de pista. Descobri que se eu der banho nele com o chapéu de
explorador vira foto! E no aniversário do dia em que ele chegou teve bolo e chapeuzinho."

## Leitura obrigatória

[05](05_ALBUM_E_CASA.md) C (Travessuras, Soninhos, Amigos, Datas), D, E; `album.json` (etapa 13), `dog_world.gd`
(onde dorme), `friends.json`, `npcs.json` (conversa), `room.gd` (toque em objeto), `plot_tray.gd` (rega por arrasto).

## Entrega e implementação

1. Ativar as 4 seções restantes (32 fotos; 54 no total) e ligar os eventos/condições que faltam no `_album_event`
   (`tapped_dog`, `tapped_object`, `watered` com contagem do arrasto, `slept` com `sleep_spot`, `friend_visit`,
   `album_opened`, `app_opened`, `within`, `count_in_window`, `full_moon`, `months`).
2. **Dicas em camadas** (05 D): lupa (1 grátis por dia, +1 com a câmera antiga; mostra os ícones das condições),
   fala de personagem depois de 3 dias com a foto em aberto (`hint_npc`/`hint_talk`, uma vez), brilho no objeto
   ligado quando 2 de 3 condições valem.
3. **Penetra** (`s_photobomb`): 1 em 8 por foto aberta no álbum, garantida na 8ª (`photobomb_pity`).
4. **Datas:** `d_month` e `d_gotcha` por `progress.started_at` (janela de 7 dias, `d_gotcha` volta todo ano);
   no Dia do Tiro a Casa ganha bolo e o Tiro um chapeuzinho de festa (adereço) e libera a receita `birthday_cake`
   (03 C). Lua cheia por cálculo simples de fase da lua (data de referência + 29,53 dias), ±1 dia.
   Meses frios em `config.json → album.cold_months` (padrão junho–agosto).
5. **Soninhos:** expor no `DogWorld` onde ele dorme (`bed`, `sofa`, `box`, `floor`) e a visita da Pipoca dormindo.
   `p_belly_up` usa `sleep_belly` (etapa 04).
6. Fotos com personagem: o personagem comenta uma vez na conversa seguinte (`photo_talk`).
7. Arte: adereços `foam`, `carrot_mouth`, `sock`, `drops`, `ball`, `moon`, `fireflies`, `mud`, `party_hat`,
   `cake`; ícones de condição que faltarem.

## Teste da etapa — `album_secrets_test.gd` (novo, ≤ 3 min)

Cada uma das 32 fotos restantes sai pela combinação certa (fixture monta só o estado necessário e dispara a ação real) e
**não** sai com só parte das condições; lupa diária com relógio injetado; fala de dica uma vez após 3 dias;
brilho com 2 de 3; penetra garantido na 8ª; lua cheia em datas conhecidas; Dia do Tiro na janela de 7 dias e de
novo no ano seguinte; mudar o relógio para trás não reabre data já usada; recarregar não duplica.

Rodar também: `album_test`, `house_test`, `friends_test`, `welcome_test`, `texts_test`, `tray_test` (rega),
`world_life_test`.

Capturas 360×780: grade com silhuetas e uma foto secreta aberta com a lupa.

## Para passar para a próxima

- [x] As 54 fotos alcançáveis por ações do jogo (tabela foto → como foi testada no registro).
- [x] Nenhuma foto depende só de sorte sem garantia; nenhuma janela menor que 3 h.
- [x] Afetados PASS.

## Fora desta etapa

Jeito do Tiro (16), Pelagem de seda (17).

## Evidência e passagem de bastão

`build/test_logs/tiro15/`. README, ROADMAP, PROGRESSION ("Álbum"), ART_PIPELINE. Sem push.
