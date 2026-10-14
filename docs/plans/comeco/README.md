# Plano "Um começo mais gostoso" — índice das etapas

> Plano do Claude Code (13/10/2026) para melhorar a **primeira hora** do Tiro Adventure.
> Cada etapa é um arquivo próprio, feito para ser executado por **outro agente (Sonnet)**,
> **uma etapa por vez**, na ordem abaixo. Nenhuma etapa começa antes da anterior estar pronta e testada.

## Como pedir ao Sonnet (copie e cole, trocando o número da etapa)

```
Leia, nesta ordem: CLAUDE.md, docs/plans/comeco/00_VISAO.md, docs/plans/comeco/01_REGRAS_E_ARTE.md
e docs/plans/comeco/ETAPA_03_desejos.md. Execute SOMENTE a Etapa 03, seguindo o passo a passo e a
lista de conferência do arquivo. Use as recomendações do plano em qualquer dúvida e anote no
docs/ROADMAP.md o que decidiu. Gere a arte com o PixelLab exatamente como descrito em
01_REGRAS_E_ARTE.md e no arquivo da etapa. Rode todos os testes (tools/test_all.ps1) e confira as
capturas 360x780 antes de terminar. Faça um commit local no fim (não faça push).
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
- [ ] Etapa 02 — caminha
- [ ] Etapa 03 — desejos
- [ ] Etapa 04 — sabores
- [ ] Etapa 05 — faro
- [ ] Etapa 06 — praça
- [ ] Etapa 07 — passeios
- [ ] Etapa 08 — apetrechos
- [ ] Etapa 09 — amigos
- [ ] Etapa 10 — truques
- [ ] Etapa 11 — tesouro

## Decisões já fechadas com o Vitor (13/10/2026)
- **Saves serão zerados** (save v12 começa do zero, como já foi feito no v11). Nada de migração.
- **Praça abre depois da Vila** (fim do capítulo 4), não junto com ela.
- **Desejos ganham uma aba própria** na barra de baixo; o Tiro pede principalmente comidas.
- **Passeios são o foco**: vários passeios, liberados com o tempo; neles aparecem **coisas raras**
  (apetrechos/roupinhas para o Tiro) e **materiais que só existem no passeio**.
- Caminha do Tiro é o primeiro presente da Laís.
- Publicação (push na `main`) só depois de o Vitor jogar a versão dev e aprovar.
