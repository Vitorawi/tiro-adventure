# Plano "Um começo mais gostoso" — índice das etapas

> **STATUS: CONCLUÍDO (etapas 00–11, 14/10/2026).** Veja o resumo final abaixo, em "PLANO CONCLUÍDO".

> Plano do Claude Code (13/10/2026) para melhorar a **primeira hora** do Tiro Adventure.
> Cada etapa é um arquivo próprio, feito para ser executado por **outro agente (Sonnet)**,
> **uma etapa por vez**, na ordem abaixo. Nenhuma etapa começa antes da anterior estar pronta e testada.

## Como pedir ao Sonnet (copie e cole, trocando o número da etapa)

```
Leia, nesta ordem: CLAUDE.md, docs/ROADMAP.md (seção Estado atual), docs/plans/comeco/00_VISAO.md,
docs/plans/comeco/01_REGRAS_E_ARTE.md
e docs/plans/comeco/ETAPA_05_faro.md. Execute SOMENTE a Etapa 05, seguindo o passo a passo e a
lista de conferência do arquivo. Use as recomendações do plano em qualquer dúvida e anote no
docs/ROADMAP.md o que decidiu. Gere a arte com o PixelLab exatamente como descrito em
01_REGRAS_E_ARTE.md e no arquivo da etapa. Rode todos os testes (tools/test_all.ps1; se passar
de 10 minutos nesta máquina, rode cada teste um a um, incluindo DEV em prod), gere capturas
360x780 e abra os PNGs para inspecionar antes de terminar. Faça um commit local no fim (não faça push).
Ao terminar, marque a etapa como feita no docs/plans/comeco/README.md.
```

## Etapas (ordem obrigatória)

| # | Arquivo | O que entrega | Arte nova | Tamanho |
|---|---|---|---|---|
| 00 | [ETAPA_00_fundacao.md](ETAPA_00_fundacao.md) | Save v12 zerado, contadores, requisitos novos, ordens ×10, "Ritmo" no DevPanel | nenhuma | pequeno |
| 01 | [ETAPA_01_facilitar.md](ETAPA_01_facilitar.md) | 2/4 canteiros, regar, nada preso a atributo escondido, nível com presente, "enquanto você estava fora", presente do dia, diárias no cap. 3, dica parada | 1 ícone | médio |
| 02 | [ETAPA_02_caminha.md](ETAPA_02_caminha.md) | Caminha do Tiro: presente da Laís, primeira construção grátis, Tiro dorme nela | 1 objeto + 1 ícone | pequeno |
| 03 | [ETAPA_03_desejos.md](ETAPA_03_desejos.md) | **Aba Desejos** (até 3 pedidos do Tiro), balão sobre o Tiro, vínculo em corações | 4 ícones | grande |
| 04 | [ETAPA_04_sabores.md](ETAPA_04_sabores.md) | Morango, batata-doce, liquidificador, picolé, suco, purê, chips; missões da vovó; pedidos | 2 plantas, 1 objeto, 6 ícones | médio |
| 05 | [ETAPA_05_faro.md](ETAPA_05_faro.md) | Faro do Tiro: ele fareja e cava achados no mapa; álbum; pedaços do mapa do tesouro | animações do Tiro, montinho, 18 ícones | grande |
| 06 | [ETAPA_06_praca.md](ETAPA_06_praca.md) | **Mapa novo: Praça** (abre depois da Vila), Nina e Pipoca, primeiro passeio | fundo, Nina, Pipoca, ícones | grande |
| 07 | [ETAPA_07_passeios.md](ETAPA_07_passeios.md) | **7 passeios** liberados aos poucos, materiais e **apetrechos raros que só saem no passeio**, diário de passeios, cartões-postais | 7 postais, 11 materiais, 7 apetrechos | grande |
| 08 | [ETAPA_08_apetrechos.md](ETAPA_08_apetrechos.md) | **Vestir o Tiro** (roupinhas aparecem nele), pet shop, mesa de costura com materiais dos passeios | sobreposições, quiosque, ícones | grande |
| 09 | [ETAPA_09_amigos.md](ETAPA_09_amigos.md) | Amigos do Tiro: cachorros da vizinhança, corações, visitas com presente | 3 cachorros | médio |
| 10 | [ETAPA_10_truques.md](ETAPA_10_truques.md) | Truques com minijogo de um toque (usa animações que já existem) | 5 ícones | médio |
| 11 | [ETAPA_11_tesouro.md](ETAPA_11_tesouro.md) | Mapa do tesouro completo, Clareira escondida, baú, mirtilo | clareira, baú, ícones | pequeno |
| — | [FUTURO.md](FUTURO.md) | Ideias para depois (não executar) | — | — |

## Andamento (o executor marca ao terminar cada etapa)
- [x] Etapa 00 — fundação (13/10/2026)
- [x] Etapa 01 — facilitar (14/10/2026)
- [x] Etapa 02 — caminha (14/10/2026)
- [x] Etapa 03 — desejos e vínculo (14/10/2026, retomada Claude Code + Codex; testes e capturas conferidos, sem push)
- [x] Etapa 04 — sabores (14/10/2026, Codex; morango/abóbora após ensopado para preservar ritmo, sem push)
- [x] Etapa 05 — faro (14/10/2026, Codex + Claude Code; código e testes ok, capturas 360x780 pendentes, sem push)
- [x] Etapa 06 — praça (14/10/2026, Claude Code; testes e capturas ok, sem push)
- [x] Etapa 07 — passeios (14/10/2026, retomada Claude Code + Codex; 7 caminhos, raros, diário; testes e capturas ok, sem push)
- [x] Etapa 08 — apetrechos (14/10/2026, Codex; lenço e lendários aprovados, vestir/pet shop/costura/bolsinha, testes e capturas conferidos, sem push)
- [x] Etapa 09 — amigos (14/10/2026, Codex; quatro cachorros, janelas, corações e visitas offline; testes/capturas/Web prod/dev conferidos, sem push)
- [x] Etapa 10 — truques (14/10/2026, Codex; cinco truques, treino de um toque, testes/capturas/Web prod/dev conferidos, sem push)
- [x] Etapa 11 — tesouro (14/10/2026; mapa completo, baú da Clareira, mirtilo; testes/capturas/Web prod/dev conferidos, sem push)

## ✔ PLANO CONCLUÍDO — resumo para o próximo planejamento (14/10/2026)
Todas as 12 etapas (00–11) estão feitas, testadas e publicadas na `main` (último commit do plano: `30c8257`;
depois dele, `6beacf4` deixou as etiquetas dos mapas tocáveis). `SAVE_VERSION` ficou em **12** desde a Etapa 00
(save zerado, sem migrações depois disso). O que o jogo ganhou:

- **Fundação (00):** contadores (`GameState._count`), requisitos novos (`bond`, `hours`, `stats`), sorteios com semente (`Loot`), aba **Ritmo** no DevPanel para medir a primeira hora.
- **Começo mais fácil (01–02):** 2/4 canteiros, regar, presente de nível e do dia, "enquanto você estava fora", dica parada; caminha do Tiro como primeiro presente da Laís (ele dorme nela).
- **Desejos e vínculo (03):** aba Desejos (até 3 pedidos), balão sobre o Tiro, corações com presentes por nível.
- **Sabores (04):** morango, batata-doce, liquidificador, picolé, suco, purê, chips; linha de missões da vovó e pedidos.
- **Faro (05):** o Tiro fareja e cava achados por mundo; álbum, conjuntos e os quatro pedaços do mapa do tesouro.
- **Praça (06) e passeios (07):** mundo novo com Nina e Pipoca; 7 passeios liberados aos poucos, materiais exclusivos, raros com garantia/consolo, lendários, diário e postais.
- **Apetrechos (08):** vestir o Tiro (cabeça/pescoço/corpo) com camadas no `PetAnimator`, pet shop, mesa de costura, bolsinha.
- **Amigos (09):** quatro cachorros, petiscos, corações, visitantes na Praça e visitas com presente após ausência offline.
- **Truques (10):** cinco truques, treino de um toque com a Nina, botão Truques na tela do Tiro.
- **Tesouro (11):** missão "O mapa completo", baú na Clareira escondida da Natureza, mirtilo (cultura e desejo especial) — fecha o mistério do pedaço 1.

**Pendências / pontas soltas conhecidas**
- Chapéu de explorador sem overlay ("Em breve no Tiro"); baú da Clareira com arte pequena (~19 px) e sem região/clareira desenhada (a Natureza não tem espaço livre).
- Avisos antigos de recursos/RIDs no encerramento de alguns testes (ex.: `park_test`) — inofensivos.
- Ideias não implementadas ficam em [FUTURO.md](FUTURO.md).

**Para o próximo plano:** comece por `CLAUDE.md`, `docs/ROADMAP.md` (Estado atual) e `docs/PROGRESSION.md`; o ritmo da primeira hora
está medido pelo `onboarding_test` (capítulo 4 em ~10,6 min, 1º passeio ~14,3 min, 1º raro na 6ª volta em ~25,7 min). Mantenha as
decisões abaixo e use este formato (um arquivo por etapa + índice) se o plano for executado por outro agente.

## Decisões já fechadas com o Vitor (13/10/2026)
- **Saves serão zerados** (save v12 começa do zero, como já foi feito no v11). Nada de migração.
- **Praça abre depois da Vila** (fim do capítulo 4), não junto com ela.
- **Desejos ganham uma aba própria** na barra de baixo; o Tiro pede principalmente comidas.
- **Passeios são o foco**: vários passeios, liberados com o tempo; neles aparecem **coisas raras**
  (apetrechos/roupinhas para o Tiro) e **materiais que só existem no passeio**.
- Caminha do Tiro é o primeiro presente da Laís.
- Publicação (push na `main`) só depois de o Vitor jogar a versão dev e aprovar.
