# Plano "Interface nova" — índice das etapas

> Plano do Claude Code (15/10/2026) para deixar o Tiro Adventure **mais bonito, simples e vivo**.
> Pedido do Vitor: "a interface está travada, tem coisas feias e textos ruins; no mapa as imagens ficam
> estranhas, os blocos são grandes, plantar é difícil. Quero mais moderno, dinâmico e organizado."
> Ele aprovou as ideias do diagnóstico (bandeja de ação, mapa em tela cheia, arrastar para plantar) e
> pediu um plano detalhado para fazer **aos poucos, uma etapa por vez**.

Cada etapa é um arquivo próprio, feito para ser executado por **outro agente (Sonnet ou Codex)**,
**uma etapa por vez**, na ordem abaixo. Nenhuma etapa começa antes da anterior estar pronta e testada.
Toda etapa entrega o jogo **funcionando e publicável** (nada fica pela metade entre etapas).

## Como pedir ao agente (copie e cole, trocando o número da etapa)

```
Leia, nesta ordem: CLAUDE.md, docs/ROADMAP.md (seção Estado atual), docs/plans/interface/00_VISAO.md,
docs/plans/interface/01_REGRAS_E_ESTILO.md e docs/plans/interface/ETAPA_03_hud.md.
Execute SOMENTE a Etapa 03, seguindo o passo a passo e a lista de conferência do arquivo.
Use as recomendações do plano em qualquer dúvida e anote no docs/ROADMAP.md o que decidiu.
Antes de mexer, rode o tour de capturas (tools/ui_tour.gd) e guarde as fotos "antes"; no fim, rode de
novo e abra os PNGs "antes" e "depois" lado a lado para conferir.
Gere a arte com o PixelLab exatamente como descrito em 01_REGRAS_E_ESTILO.md e no arquivo da etapa.
Rode todos os testes (tools/test_all.ps1; se passar de 10 minutos, rode cada um, incluindo DEV em prod).
Faça um commit local no fim (não faça push). Ao terminar, marque a etapa como feita neste README.
```

## Etapas (ordem obrigatória)

| # | Arquivo | O que entrega | Arte nova | Tamanho |
|---|---|---|---|---|
| 00 | [ETAPA_00_base.md](ETAPA_00_base.md) | Tour de capturas fixo, `Palette`, `Motion`, `RingProgress`, ícones próprios das estações, Casa abrindo enquadrada | ~14 ícones | pequeno |
| 01 | [ETAPA_01_visual.md](ETAPA_01_visual.md) | Tema novo: cartão ≠ botão, 1 botão principal, botões fantasma/ícone, cadeado no lugar do botão cinza, tipografia em 3 tamanhos | 2 ícones | médio |
| 02 | [ETAPA_02_painel.md](ETAPA_02_painel.md) | Painel novo: meia altura / alta, alça para arrastar, título único, espaços de produção compactos, linhas baixas, fala em balão | nenhuma | médio |
| 03 | [ETAPA_03_hud.md](ETAPA_03_hud.md) | Barra superior flutuante (Tiro + anel de XP, moedas), abas que pulam, aviso (toast) novo | 1 retrato | médio |
| 04 | [ETAPA_04_mundo_cheio.md](ETAPA_04_mundo_cheio.md) | Mundo em tela cheia: céu/paisagem de fundo, enquadramento por mundo, sem cabeçalho grande, sem botões +/− | 5 fundos + nuvens | grande |
| 05 | [ETAPA_05_seletor.md](ETAPA_05_seletor.md) | Seletor de mundos em carrossel, aba Mapa abre no último mundo, transição de nuvem, personagens no canto | 2 ícones de mundo | médio |
| 06 | [ETAPA_06_indicadores.md](ETAPA_06_indicadores.md) | Balões sobre canteiros/estações com anel de progresso, "pronto" pulando, etiquetas só quando importam | nenhuma | médio |
| 07 | [ETAPA_07_bandeja_horta.md](ETAPA_07_bandeja_horta.md) | **Bandeja de ação** + horta: tocar para plantar, **arrastar para plantar/colher/regar vários** | nenhuma | grande |
| 08 | [ETAPA_08_bandeja_estacoes.md](ETAPA_08_bandeja_estacoes.md) | Bandeja no fogão, bancada, liquidificador, moinho, queijaria, costura, animais e Natureza: fila em bolinhas + grade de receitas | nenhuma | grande |
| 09 | [ETAPA_09_tiro.md](ETAPA_09_tiro.md) | Tela do Tiro: cenário, necessidades em anéis, **arrastar comida até ele**, esponja, bola, caderninho | cenário + 3 ícones | grande |
| 10 | [ETAPA_10_listas.md](ETAPA_10_listas.md) | Missões, Desejos, Mochila e Coleção em linhas compactas, filtros por ícone, detalhe do item | nenhuma | médio |
| 11 | [ETAPA_11_textos.md](ETAPA_11_textos.md) | Glossário aplicado em tudo, lista de textos visíveis, reescrita das frases ruins | nenhuma | médio |
| 12 | [ETAPA_12_festa.md](ETAPA_12_festa.md) | Cartões de comemoração novos, números que contam, confete, vibração, boas-vindas agrupado, polimento final | 1 efeito | médio |
| — | [FUTURO.md](FUTURO.md) | Ideias para depois (sons, noite, etc.; não executar) | — | — |

## Andamento (o executor marca ao terminar cada etapa)
- [x] Etapa 00 — base (tour, paleta, movimento, ícones) — feita em 15/10/2026
- [x] Etapa 01 — visual (tema) — feita em 15/10/2026
- [x] Etapa 02 — painel — feita em 15/10/2026
- [x] Etapa 03 — barra superior e abas — feita em 15/10/2026
- [x] Etapa 04 — mundo em tela cheia — feita em 15/10/2026; revisão do chão texturado e das bordas pelo Codex
- [x] Etapa 05 — seletor de mundos — feita em 15/10/2026; carrossel, encaixe, viagem e ícones próprios
- [x] Etapa 06 — indicadores e etiquetas — feita em 15/10/2026; balões `WorldBalloon` e etiquetas `WorldLabel` (brilho 6.4 opcional não feito)
- [ ] Etapa 07 — bandeja na horta
- [ ] Etapa 08 — bandeja nas estações
- [ ] Etapa 09 — tela do Tiro
- [ ] Etapa 10 — listas (missões, desejos, mochila, coleção)
- [ ] Etapa 11 — textos
- [ ] Etapa 12 — festa e polimento

## Decisões já fechadas com o Vitor (15/10/2026)
1. **Bandeja de ação** perto do dedo para plantar, colher, regar, cozinhar e alimentar — o painel grande
   continua existindo para consulta ("Ver tudo").
2. **Arrastar** para plantar/colher/regar vários de uma vez (estilo Hay Day), **sempre** com o toque simples
   funcionando igual.
3. **Mapa em tela cheia:** a aba Mapa abre direto no último mundo visitado; a troca de mundo é por um
   seletor em carrossel. Sem faixa de cabeçalho fixa.
4. **Tela do Tiro:** os 4 botões viram uma bandeja de cuidados; comida se arrasta até o Tiro (tocar também
   funciona). Manual, Atributos, Coleção e Truques vão para um "caderninho".
5. **Fonte:** continua a Jersey 10 (pixel, combina com a arte); tamanho mínimo 18 e números com contorno.
6. **Arte nova no PixelLab liberada** (fundos de céu/paisagem por mundo, ícones de estação, retrato do Tiro).
7. **Nada muda nas regras do jogo** (tempos, preços, recompensas, save). Este plano é só de interface:
   `SAVE_VERSION` continua 12 e nenhum save é zerado.
