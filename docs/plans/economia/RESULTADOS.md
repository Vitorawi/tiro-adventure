# Resultados da calibração (etapa 23) — concluída com ressalvas (decisão do Vitor, 19/10/2026)

Por decisão do Vitor, as verificações pendentes (sementes 2–10, light com retorno de 24 h, perfil ativo, gráficos, baseline × R1, relatório por visita, sessão no celular) foram movidas para a etapa 24, junto da validação final. O critério da Festa continua falho e a banca 3 (15→12) segue como proposta não aplicada.

Medidas **SIMULADAS** (GameState real, relógio injetado; semente 1; `until=campaign`; `--rare=normal`). Não medem diversão nem
substituem a sessão no celular. Nenhum número de dados foi alterado nesta rodada (ver DECISOES, etapa 23). Evidência em
`build/economy/etapa_23/` (`commercial_s1_campanha`, `recovery_s1_campanha`, `light_s1_campanha`, `light_s1_r2`, `reference_s1_r2`)
e `build/economy/etapa_22/reference_s1_campanha`.

Escopo desta rodada (pedido do Vitor: "ser mais rápido, testar só o que mudamos"): **uma semente (1) por perfil**, sem as sementes 2–10,
sem o baseline de 35 execuções, sem `progression_test`, sem sessão humana.

## Campanha completa (99 missões, 4 obras)

| Perfil | Estado | Dias | Missões | Melhorias | Minutos ativos | Violações |
|---|---|---|---|---|---|---|
| reference | completo | 21,1 | 99/99 | 57/61 | 647,9 | 0 |
| commercial | completo | **28,1** | 99/99 | 56/61 | 859,3 | 0 |
| recovery | completo | 22,4 | 99/99 | 58/61 | 687,6 | 0 |
| light | **98/99 aos 75 d** (parou, ver abaixo) | 96,3 (limite) | 98/99 | 59/61 | 974,4 | 0 |

`reference` repetido com o mesmo código (`reference_s1_r2`): resultado idêntico (21,1 d, 7914 ações) — determinístico.

## Marcos (minutos ativos desde o início)

| Marco | reference | commercial | recovery | light |
|---|---|---|---|---|
| primeira colheita | 1,8 | 1,8 | 1,9 | 1,8 |
| primeiro desejo | 1,3 | 1,8 | 1,4 | 1,3 |
| primeiro achado | 2,4 | 2,3 | 2,5 | 2,4 |
| fogão | 4,2 | 4,3 | 4,1 | 4,2 |
| primeiro passeio | 14,9 | 14,6 | 13,7 | 15,6 |
| todos os depósitos | 27,8 | 16,1 | 16,1 | 28,8 |
| fim do capítulo 9 | 233,7 (3,9 h, dia 7) | 481,3 (8,0 h, dia 15) | 241,5 (4,0 h, dia 7) | 342,8 (5,7 h, dia 33) |
| Banco | 264,4 | 512,1 | 282,3 | 363,0 |
| Jardim / Piquenique | 278,3 / 334,4 | 553,6 / 667,5 | 294,7 / 355,8 | 372,7 / 429,1 |
| banca 3 (`merchant_village_stall`) | dia 17,1 | dia 13,8 | dia 17,8 | dia 61,3 |
| Festa | 600,3 (dia 19) | 841,1 (dia 27) | 630,6 (dia 20) | 679,3 (dia 67) |

Primeira sessão: ociosidade 25,8% / 26,8% / 24,0% / 22,3% (faixa ≤ 25%: reference e commercial ficam 1–2 pontos acima).

## Renda (moedas ganhas)

Recorrente (vendas, encomendas, rotinas, achados...) × único (prêmios): reference 54.454 × 3.885; commercial 64.686 × 4.010;
recovery 63.010 × 3.945; light 84.317 × 4.165. Vendas + encomendas = 94–96% da renda recorrente (faixa ≥ 60%: atingida).

## Veredito por critério

| Critério | Resultado |
|---|---|
| Invariantes (sem perda/duplicação/negativos, guardas) | **Passou**: 0 violações nas 5 execuções. |
| Recuperação com zero moeda (`recovery`) | **Passou**: 99/99 em 22,4 d (invariante, não média). |
| Primeira colheita ≤ 4 min, desejo ≤ 7, achado ≤ 10, passeio ≤ 60 | **Passou** (1,8 / 1,3 / 2,4 / 13,7–15,6 min). |
| Fim 9 em 3–6 h ativas | **Passou** em reference (3,9 h), recovery (4,0 h) e light (5,7 h); **falhou** em commercial (8,0 h). |
| Festa "mais 2–4 h" após o fim 9 | **Falhou pela métrica de sessão**: reference +6,1 h, recovery +6,5 h, commercial +6,0 h, light +5,6 h. |
| commercial conclui o piquenique (pendência da 21) | **Resolvido sem mexer em dados**: com a campanha inteira o commercial conclui as quatro obras (dia 27). O travamento da 21 era de `until=projects`, que só rodava `ph_projects`; ver DECISOES. |
| light trava em `nina_sewing` (pendência da 21/22) | **Rótulo enganoso, não bloqueio**: `nina_sewing` foi recebida no dia 67,3 junto com a Festa (par `shared_with`); o texto "gargalo" do relatório vem de uma sessão antiga. O que falta é só `nina_blueberry` (opcional). Ver abaixo. |
| Margens com intermediários, relatório por visita | **Hipótese / não refeito**: a margem vem da etapa 17 e da auditoria estática; o relatório por visita não foi regerado nesta rodada. |
| Sementes 2–10 (reference/light), sementes de controle | **Não rodado.** |
| Sessão humana no celular | **Não feita.** |

## Leituras que mudam a conclusão

1. **A Festa depende do calendário, não do esforço.** Em reference o fim 9 é no dia 7 e a Festa no dia 19,8. Entre os dias 11 e 17 o robô
   espera a banca 3 (1.500 moedas + tábuas 8, tijolos 6, tecido 2 + 15 contratos de 3 tipos; `merchant_village_stall` no dia 17,1) e o
   morango do canteiro. A métrica "minutos ativos" do simulador conta o orçamento da sessão (10 min × 3 por dia) mesmo com sessão ociosa, por
   isso 366 min "ativos" ≈ 12,8 dias de calendário. O mesmo vale para `commercial` (banca 3 no dia 13,8, mas a Festa só no 27: depois
   dela o gargalo são o jardim/piquenique e as fases da Festa).
2. **light:** a campanha termina no dia 75 (`merchant_festival`); `nina_blueberry` nunca é ativada porque esse perfil não tem a fase `ph_others`
   e portanto nunca abre o baú da Clareira (`treasure` ≥ 1). O jogo não bloqueia: o baú pode ser aberto a qualquer momento. Não alterei a
   política do robô só para produzir PASS.
3. **Experimento descartado:** uma garantia de 1 fita na `park_loop` até receber `nina_sewing` (extensão de `loot.guarantee`) não mudou
   nada (light idêntico, dia 67,3) porque a fita nunca foi o gargalo. Revertida.

## Hipóteses e proposta concreta (para o Vitor decidir)

- **Se a Festa chegar tarde demais no celular** (sensação de espera entre jardim/piquenique e Festa), a menor alavanca na ordem do protocolo
  (requisito → quantidade) é a banca 3: de 15 contratos para 12 (−20%, nos dados `merchant_clients`, `stall_3` e `customer_tiers`) e,
  se ainda faltar, o custo de 1.500 para 1.200 moedas. Ambas mexem em textos, na tabela 02/07 e em `customers_test`/`market_test`/
  `expansion_test`; só vale a pena após ver o ritmo real.
- **Não é para reduzir antes de testar:** se a Festa em ~20 dias de sessões curtas parecer boa, a faixa "2–4 h" do plano foi calibrada com
  sessões ininterruptas e pode ser reinterpretada em dias de calendário.

## Perguntas para o Vitor testar no celular

1. Do momento em que o Banco abre até a Festa, existe um dia inteiro sem nada para fazer além de esperar (banca 3, morangos)?
2. A banca 3 (15 contratos de 3 tipos + 1.500 moedas) parece "mais um pedido igual" ou um objetivo claro?
3. Jardim e Piquenique em qualquer ordem: dá vontade de escolher, ou parece obrigação dupla antes da Festa?
4. O Encontro da turma (24 h) aparece sem ser lembrado ou fica esquecido?
5. Ao abrir o jogo depois de um dia fora, o que você faz primeiro, e quanto tempo até a primeira coisa útil?

## Próxima ação exata (para fechar a etapa 23)

1. Vitor joga um trecho (banco → Festa) no celular e responde às perguntas acima.
2. Rodar `reference` e `light` nas sementes 2–10 e `commercial`/`recovery` nas sementes 2–3 (`tools/economy_baseline.ps1`), com o mesmo código, e anexar mínimo/mediana/máximo aqui.
3. Se a decisão for encurtar a Festa: uma rodada, só a banca 3 (15 → 12 contratos), reexecutar reference s1 e commercial s1 e registrar antes/depois.
4. Gráficos de fontes/consumos/marcos (`tools/economy_compare.py`) sobre as sementes novas.

## Etapa 24 — validação final (19/10/2026, concluída com ressalvas)

Medidas **SIMULADAS** (GameState real, relógio injetado, `until=campaign`, `--rare=normal`), mesmo código em todas as execuções "antes". Evidência: `build/economy/etapa_24/` (`*_c` = antes do ajuste da banca 3, `*_d` = depois, `relatorio/report.md` e gráficos, `estatisticas.txt`, `auditoria/`, `suite_resultados.csv`). Mínimo / mediana / máximo (não percentil 95).

| Perfil (sementes) | Dias até o fim | Missões | Fim do cap. 9 (h ativas) | Festa (h ativas) | Festa − fim 9 (h ativas / dias) |
|---|---|---|---|---|---|
| reference (1–10) | 19,3 / 20,6 / 22,1 | 99/99 em 10/10 | 3,4 / 3,8 / 4,0 | 9,2 / 9,9 / 10,2 | 5,7 / 6,1 / 6,5 h · 11,5 / 12,4 / 13,0 d |
| light (1–10) | 82,3 / 87,3 / 95,3 | 98/99 em 10/10 | 3,4 / 4,1 / 5,7 | 9,1 / 10,4 / 11,3 | 5,5 / 6,0 / 7,0 h · 33 / 36 / 42 d |
| commercial (1–3) | 28,1 / 45,1 / 46,3 | 99/99 em 1/3; 98/99 em 2/3 | 7,4 / 8,0 / 8,0 | 12,7 / 13,4 / 14,0 | 5,3 / 5,3 / 6,0 h · 10,5 / 10,7 / 12,0 d |
| recovery (1–3) | 19,3 / 20,3 / 22,4 | 99/99 em 3/3 | 3,7 / 3,9 / 4,0 | 9,2 / 9,9 / 10,5 | 5,3 / 6,1 / 6,5 h · 10,7 / 12,2 / 13,0 d |
| active (1–2) | 3,4 | 99/99 em 2/2 | 6,7 / 7,0 / 7,4 | 18,1 / 18,3 / 18,6 | 10,7 / 11,3 / 11,9 h · 1,9 / 2,0 / 2,0 d |

Primeira colheita 1,8 min, primeiro desejo 1,3–1,8, primeiro achado 2,3–2,6, primeiro passeio 12,3–15,6 min em todos os perfis (limites 4/7/10/60). **0 violações de conservação em todas as 28 execuções** (e nas 9 "depois").

- **light:** 98/99 nas 10 sementes (82–95 dias): falta só `nina_blueberry` (opcional; o perfil leve não abre o baú). O gargalo escrito no relatório (`nina_sewing`/sorte) é o rótulo antigo. **light com recarga por sessão** (`--reload=session`): resultado idêntico ao sem recarga (95,3 d, 98/99), logo salvar/carregar a cada volta não muda a economia. O light já é uma sessão de 10 min a cada 24 h; o perfil **ativo** (blocos de 2 h) conclui em 3,4 dias de calendário.
- **commercial sementes 2 e 3** pararam em 98/99 (46,3 e 45,1 dias): só falta `nina_blueberry`, com o foco em "esperar o desejo" (`focus_state=wait`, `why=wish`) e baú/armazém cheios; o robô não troca pedido. **Limite de política do robô, não do jogo** (o desejo é garantido em vaga vazia; receita e requisitos existem). Não alterei a política só para produzir PASS. Risco residual: conferir no celular que o desejo "Quero petisco de mirtilo!" aparece quando os três espaços estão ocupados (trocar pedido libera a vaga).
- **Festa "+2–4 h" após o fim 9: continua falhando** (+5,3 a +7,0 h; active +11 h), robusta entre perfis e sementes. É calendário (banca 3), não esforço.

### Ajuste aplicado a pedido do Vitor: banca 3, 15 → 12 contratos

Antes → depois (mesmo código, sementes 1–3): reference banca 3 no dia 16,8 → 15,3 (mediana), Festa dia 19,3 → 18,3, Festa − fim 9 = 6,1 → 5,6 h (12,5 → 11,3 d); commercial Festa dia 27,8 / 26,3 / 25,1 → 24,1 / 23,8 / 22,3 (Festa − fim 9 chega a 4,2 h na semente 3). Ganho de ~1 dia e ~0,5 h: **ainda fora de 2–4 h** pela métrica de sessão. Segunda alavanca (1.500 → 1.200 moedas) **não aplicada**; decidir depois do teste no celular. A faixa "2–4 h" foi calibrada com sessões ininterruptas; em calendário o intervalo é de ~11 dias de jogo curto.

### Falhas históricas (registradas à parte, não corrigidas)

`finds_test` ("missão pronta"), `onboarding_test` (4 erros) e `npc_lines_test`; intermitentes sob carga: `park_test`, `walks_test`, `bench_test`, `world_selector_test`, `petshop_test`.

### Limitações desta validação

- **Sem aparelho físico e sem sessão humana.** Nada aqui prova diversão nem toque real no celular.
- `progression_test` **não foi rodado no estado final** (uma tentativa foi interrompida ao decidir o ajuste da banca 3; o Vitor pediu para não refazer todos os testes). Cobertura equivalente: `festival_test` (história do zero à Festa, 438 verificações), `journey_test`, campanha simulada 99/99.
- Suíte completa **não repetida no estado final**: 25 testes (ordem alfabética até `hud_test`) rodaram com PASS antes do ajuste, exceto `finds_test` (histórico). Depois do ajuste só os testes que tocam banca/contratos (tabela no README).
- Tour visual/toque nas três resoluções e smoke do export Web não repetidos (nenhuma tela mudou; só números e textos da banca 3).
- Baseline × R1 com horizonte e política iguais **não foi refeita**: o baseline da etapa 01 mede o jogo antigo (81 missões, outra política). Gráficos novos em `relatorio/charts/` (missões × tempo, moedas × dia, esperas).

### Roteiro de celular para o Vitor

1. Banco → Festa: existe um dia inteiro sem nada para fazer? A banca 3 (12 contratos de 3 tipos + 1.500 moedas) parece objetivo claro?
2. Novo jogo por 20 min: primeira colheita, primeiro desejo e primeiro passeio chegam rápido?
3. Salvar, fechar e voltar após 24 h: o que fazer primeiro? O Tiro está bem?
4. Depósito cheio com passeio na rua: o Tiro volta e a bagagem aparece em "Presentes para guardar"/Ver bagagem?
5. Fila de produção (Preparar N) e estufa: funcionam com o app fechado?
6. Projeto parcial (Banco/Jardim/Festa pela metade), fechar e reabrir: a contribuição se mantém?
7. Save antigo (se tiver): abre sem perder nada?
