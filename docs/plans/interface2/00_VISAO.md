# 00 — Visão: por que a interface parece "pixel e pesada" e para onde ela vai

## 1. Diagnóstico (capturas `build/screenshots/interface2_antes`, 24/10/2026)

O plano "Interface nova" (15–16/10) já resolveu a **estrutura**: mundo em tela cheia, bandejas perto do
dedo, folhas inferiores, HUD flutuante, seletor de mundos, comemorações num cartão só. O que nunca existiu
foi uma **linguagem visual decidida antes de construir**, e o jogo ficou com cara de pixel até nos botões.

| Sintoma | Onde | Causa |
|---|---|---|
| Tudo parece "jogo antigo" | todas as telas | a única fonte é a **Jersey 10** (pixel), em 7 estilos de texto (Title 30, Section 22, corpo 22, Small 18, Number, Badge, Toast) e 43 tamanhos forçados no código (`add_theme_font_size_override`) |
| Controles parecem itens | X de fechar, engrenagem, cadeado, check, "?" | 30 usos de ícones de controle em pixel (`ui_close`, `ui_lock`, `ui_check`, `settings`, `timer`...) |
| Tudo pesa igual | cartões, botões, chips | borda marrom de 2 px + "degrau" de 5 px em todo botão e cartão; botão principal de 52 px de altura com a largura toda |
| Verde quer dizer quatro coisas | botões, prontos, selecionado, texto de sucesso | `PRIMARY` usado como ação, pronto, seleção (aba ativa, receita escolhida) e cor de texto |
| Tela do Tiro apertada | `b02_pet` | cartão de necessidades ocupa ¼ da tela com rótulos; anel "5" solto; balão "Crescer: Tiro está feliz da vida!"; dica em texto embaixo dos cuidados |
| Missões escondidas em abas | `a02_tasks`, `b03_tasks` | três abas (Principal/Personagens/Temporárias), legenda "! = prêmio pronto para pegar", personagens com Abrir/Fechar; a diária repete o título na descrição |
| Prêmio sem festa e sem rumo | `GameState.claim_quest` | pegar prêmio de missão só mostra o aviso de texto "Missão concluída! Próximo: …"; nada voa até as moedas (as diárias voam: inconsistente) |
| Bandeja vira painel | `e07_tray_stove` | a bandeja do fogão cobre o mundo inteiro (o fogão some), com "Receitas: deslize para o lado", rolagem horizontal e "Ver tudo" em texto |
| "Novo" em tudo | `b04_bag` | selo "Novo" em todos os itens da Mochila: o selo perde o sentido |
| Rodapé pesado | todas | barra de abas marrom-escura com o ícone ativo saltando num círculo |
| Avisos competindo | casca | oito canais diferentes: `Toast`, `MomentNotice`, aviso de foto, `ModalCard` (cinco montadores), boas-vindas, "Novo!", selos das abas, balões "!" dos personagens; cada um com posição e tempo próprios |

## 2. Referências (o que pegar de cada uma)

| Referência | Pegar |
|---|---|
| **Finch** (bichinho de autocuidado) | bichinho no centro; interface clara e arredondada; pouco texto; comemorações gostosas e curtas |
| **Pokémon Sleep** | cartões limpos sobre arte fofa; número grande e rótulo pequeno; hierarquia clara |
| **Animal Crossing: Pocket Camp** | fonte arredondada; balão de fala moderno; pedido = ícone + quantidade |
| **Cats & Soup** | interface discreta sobre o mundo; produção de um toque |
| **Ms Farm** (Behance, enviado pelo Vitor) | HUD só nos cantos; painel do canteiro sobre o canteiro com setinha; cartões de loja com preço em pílula verde; bloqueado = cinza + cadeado + nível; recompensa diária em grade |
| **Royal Match / Duolingo** | velocidade: animação curta com mola; um botão principal; quase nenhuma palavra; prêmio que voa até o contador |
| **Neko Atsume** | coragem de esconder: a tela principal é o bichinho |

Skills avaliadas (24/10/2026): `mobile-app-ui-design` (ceorkm) deu as regras visuais (4 tamanhos de fonte,
60/30/10, grade de 8, sombra tingida, valor > rótulo, zona do polegar, pico e fim); `game-ui-ux-design`
(fcsouza) deu o filtro de jogo ("sopa de interface", ensinar fazendo, estado sempre visível, resposta em
< 200 ms); `team-ui` (Donchitos) deu o método (bíblia antes, rascunho aprovado antes do código, revisão
com checklist); `mobile-games` (sickn33) só confirmou limites técnicos que o jogo já respeita. Nenhuma foi
instalada: as regras úteis estão neste plano.

## 3. Princípios (valem para toda tela nova ou refeita)

1. **Pixel = mundo, liso = controle.** Tiro, personagens, mapas, itens, comidas, estações e ícones das abas
   são pixel art. Fechar, voltar, ajuda, cadeado, check, engrenagem, relógio, setas, + e − são vetoriais.
2. **Uma coisa principal por tela.** Um botão verde por tela/folha/bandeja; o resto é calmo (afundado ou
   fantasma).
3. **Valor maior que o rótulo.** `3/6`, `+30`, `2.645` em Fredoka; a palavra fica pequena ou some.
4. **Uma cor, um significado.** Verde = fazer/pronto. Mel = prêmio, moeda, crescimento. Azul = tempo,
   progresso, água. Vermelho = pede atenção/falta. Cor do mundo = só pílula do mundo e etiquetas de lugar.
   Selecionado = contorno de tinta, nunca verde.
5. **Ícone + número, no máximo uma linha de texto** (já era regra; agora com orçamento por tela, 04 §B).
6. **Toda ação responde em menos de 200 ms**: aperto do botão, item que voa, número que conta, vibração.
7. **Prêmio tem tamanho**: micro (sem janela), pequeno (linha some e voa), médio (folha de prêmio), grande
   (cartão com confete). Ver 02 §4.
8. **Nada flutua sem apoio.** Rodapé e cuidados presos à borda; folhas saem da borda; bandejas apontam para
   o objeto; balões apontam para quem fala. (Lição do primeiro protótipo, reprovado por "ícones flutuando".)
9. **A ação principal fica no terço de baixo** (polegar). Em cima ficam só leitura (HUD, próximo passo).
10. **Revelar aos poucos continua** (`features`, Novo!); a interface nova não mostra nada antes da história.

## 4. O que muda e o que não muda

**Muda:** fonte, cores, sombras, cantos, ícones de controle, todas as peças do `UiKit`, HUD, rodapé,
avisos, tela do Tiro, Missões, bandejas, Mochila, painéis, comemorações, textos de interface.

**Não muda:** regras do jogo (tempos, preços, prêmios, requisitos, ids), missões e falas da história
(só como elas aparecem), mundos e sprites, `SAVE_VERSION` (preferências novas de interface vão em
`progress.seen["ui:..."]` ou `settings.json`; se algo precisar mesmo de campo salvo, segue a regra
"saves sempre zerados": sobe a versão, sem migração).

## 5. Riscos e como o plano lida com eles

| Risco | Cuidado |
|---|---|
| Pixel art ao lado de vetor parecer "colado" | ícones pixel sempre dentro de um disco/afundado liso (moldura), nunca soltos sobre o papel; escala inteira quando o PNG é 32 px (32/64) ou 1,5× só para 48 |
| Fonte nova pesar no export Web | Fredoka (155 KB) e Nunito (270 KB) variáveis; se o `.pck` crescer demais, gerar subconjunto latino (`tools/font_subset.py`, etapa 01) |
| Contorno/sombra custar desempenho no celular | sombras são `StyleBoxFlat.shadow_*` (barato); nada de desfoque de tela no renderer Compatibility |
| Quebrar testes que procuram nós por nome | lista de nós preservados em 03 e regra em 04 §A.5 |
| Etapas grandes demais / testes demorados | cada etapa entrega o jogo funcionando; testes em lista fechada (≤ 3 min); suíte inteira só na 12 |
