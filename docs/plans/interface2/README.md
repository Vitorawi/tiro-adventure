# Plano "Interface 2 — aconchego moderno"

> Pedido do Vitor (24/10/2026): "a interface está muito no estilo pixel, feia, botão muito grande, lista,
> muito texto. Quero um jogo moderno, com interface moderna, rápida e intuitiva, ainda com os sprites em
> pixel. Gosto do lado B (moderno e limpo), mas com um pouco do A (aconchegante, temático). Não só a
> interface: todo o fluxo da jornada — não quero mexer nas missões, mas em como você interage com elas,
> recompensa, essas coisas." E, no fim: "faça um plano bem estruturado, bem detalhado, testes que façam
> sentido, seja o mais detalhista possível, porque vão ser outros modelos que vão fazer."

## A ideia em uma linha

> **Pixel é o que está no mundo; liso é o que você toca.** O Tiro, os personagens, os mapas e os itens
> continuam pixel art; botões, letras, painéis e ícones de controle ficam lisos, arredondados e calmos, com
> cores quentes de casa. Cada tela mostra uma coisa principal, e cada ação responde na hora.

## Decisões do Vitor (24/10/2026) — fechadas

| # | Decisão |
|---|---|
| 1 | **Direção geral aprovada**: moderno e limpo (B) com toque aconchegante (A); Fredoka + Nunito; paleta creme/mel/verde; pixel no mundo, liso nos controles. |
| 2 | **Rodapé claro**, preso à borda, um pouco transparente sobre o mundo; nome embaixo de todas as abas. (A barra branca solta foi reprovada: "ícones flutuando".) |
| 3 | **Próximo passo sempre no topo, só da missão principal** (a história da Laís), em todas as abas. |
| 4 | **Folha de prêmio** ao concluir passo da história. |
| 5 | **Missões continuam separadas**: História · Pessoas · Diárias ("meu medo de tudo num lugar só ficar ruim"). |
| 6 | **Tiro: botão Cuidar que abre uma roleta**, bem espaçada e meio transparente. (Objetos no cenário e barra apoiada foram comparados e não escolhidos.) |
| 7 | **Mapas sem as etiquetas de nome** ("deixa sem texto mesmo"): o objeto, os balões, o alfinete e o brilho de lugar novo guiam; tocar e segurar mostra o nome. |
| 8 | **Horta**: manter o arrastar, mais fácil — sementes numa barra embaixo e o arrasto começa em qualquer canteiro. |
| 9 | **Seta de direção lisa** (não pixel) → alfinete com o ícone do destino e anel no chão. |
| 10 | **Lista de mundos mais confortável** → cartões-postais com a foto de cada mundo. |
| 11 | **Testes enxutos e direcionados**: lista fechada por etapa (≤ 3 min; a 07 tem exceção registrada), suíte inteira só no fim, nada de campanha. |

## Documentos (ler nesta ordem)

| Arquivo | O que decide |
|---|---|
| [00 Visão](00_VISAO.md) | diagnóstico com números, referências (o que pegar de cada), princípios, o que muda e o que não muda |
| [01 Bíblia visual](01_BIBLIA_VISUAL.md) | fontes, tamanhos, cores (com contraste medido), espaçamento, cantos, sombras, ícones, peças, movimento |
| [02 Jornada](02_JORNADA.md) | os fluxos: sessão, mapa sem texto, próximo passo, alfinete, Missões, prêmios, avisos, produção, horta, cuidar (roleta), conversa, boas-vindas, compra, bloqueios |
| [03 Telas](03_TELAS.md) | tela por tela: como é hoje → como fica, nós preservados |
| [04 Regras e testes](04_REGRAS_E_TESTES.md) | contrato do executor, checklist de revisão, orçamento de texto, capturas, **filosofia e listas de teste**, modelo de teste, toque real |
| [05 Etapas](05_ETAPAS.md) | índice das 12 etapas |
| [etapas/](etapas/) | **um arquivo por etapa**, com o código de hoje, passo a passo, testes numerados e critério de pronto |
| [prototipo/](prototipo/) | protótipos em HTML com os sprites reais + PNGs e pranchas antes × depois |
| [ORQUESTRACAO.md](ORQUESTRACAO.md) | prompt do orquestrador (Grokbot): executores Codex GPT 6.1 / Claude Sonnet 5.5 com reserva mútua, conferência, passagem para sessão nova; prompt da etapa 01 pronto |

## Protótipos (`prototipo/`, renderize com `sh docs/plans/interface2/prototipo/render.sh <tela> [variação]`)

| Prancha / PNG | O que mostra |
|---|---|
| `estilo.png` | a bíblia visual numa folha só |
| `prancha_rodape.png` | rodapé preso: clara (**escolhida**) × madeira |
| `prancha_tiro.png`, `prancha_roleta.png` | tela do Tiro hoje × proposta; **botão Cuidar fechado × roleta aberta** (escolhido) |
| `prancha_cuidados.png` | as três ideias de cuidados que foram comparadas (histórico) |
| `prancha_missoes2.png` | Missões hoje × **História · Pessoas · Diárias** × folha de prêmio (escolhido) |
| `prancha_missoes.png` | a lista única que foi descartada (histórico) |
| `prancha_horta.png` | horta hoje × barra da horta (plantar arrastando) × colher tudo |
| `prancha_seta.png` | alfinete com o ícone do destino e anel no chão |
| `prancha_mundos.png` | lista de mundos hoje × cartões-postais |
| `prancha_fogao.png` | bandeja do fogão hoje × presa ao fogão, mundo visível |

## Ordem de execução

```mermaid
flowchart TD
  E0[00 plano + protótipos<br/>APROVADO pelo Vitor] --> E1[01 base: fontes, cores, ícones, tema<br/>+ test.ps1 -Exact e --i2-NN-only]
  E1 --> E2[02 peças do UiKit]
  E2 --> E3[03 casca: rodapé, HUD, próximo passo, avisos]
  E3 --> E4[04 Tiro: botão Cuidar + roleta]
  E4 --> E5[05 Missões em 3 abas + folha de prêmio]
  E5 --> E6[06 mundo: sem texto, alfinete, cartões-postais]
  E6 --> E7[07 barra da horta + bandejas]
  E7 --> E8[08 Mochila, item, caderninho]
  E8 --> E9[09 painéis grandes]
  E9 --> E10[10 comemorações e boas-vindas]
  E10 --> E11[11 texto mínimo + Texto maior + limpeza]
  E11 --> E12[12 fechamento: ÚNICA suíte inteira + toque real]
```

| Feita | Etapa | Entrega | Tamanho |
|---|---|---|---|
| [x] | 00 | plano, bíblia, jornada, telas, regras/testes, 12 etapas, protótipos e pranchas; decisões do Vitor | — |
| [x] | [01](etapas/ETAPA_01_BASE.md) | fontes, `Palette`, ícones vetoriais, tema; ferramentas enxutas de teste/captura | médio |
| [x] | [02](etapas/ETAPA_02_PECAS.md) | peças do `UiKit` | médio |
| [x] | [03](etapas/ETAPA_03_CASCA.md) | rodapé claro preso, HUD em 2 linhas, `NextStep`/`QuestGuide`, `Notice` | grande |
| [x] | [04](etapas/ETAPA_04_TIRO.md) | cenário aproximado, anéis no topo, botão Cuidar + roleta | grande |
| [x] | [05](etapas/ETAPA_05_MISSOES.md) | Missões em 3 abas, `claim_quest_fx`, `QuestReward` | grande |
| [x] | [06](etapas/ETAPA_06_MUNDO.md) | mapa sem texto, balões, `WorldPin`, cartões-postais, conversa, compra | grande |
| [ ] | [07](etapas/ETAPA_07_HORTA_BANDEJAS.md) | `FarmDock`, bandejas das estações | grande |
| [ ] | [08](etapas/ETAPA_08_MOCHILA.md) | Mochila, detalhe, caderninho, Coleção, Álbum | médio |
| [ ] | [09](etapas/ETAPA_09_PAINEIS.md) | painéis grandes | grande |
| [ ] | [10](etapas/ETAPA_10_FESTA.md) | `ModalCard` novo, `RewardSheet`, boas-vindas, Novo! | médio |
| [ ] | [11](etapas/ETAPA_11_TEXTO.md) | orçamento de texto, Texto maior, limpeza | médio |
| [ ] | [12](etapas/ETAPA_12_FECHAMENTO.md) | suíte inteira, toque real, desempenho, docs | médio |

## Como passar para o próximo agente

Copie e troque só o número e o nome do arquivo:

```text
Execute somente a etapa NN do plano Interface 2: docs/plans/interface2/etapas/ETAPA_NN_<NOME>.md.
Leia, nesta ordem: CLAUDE.md; docs/ROADMAP.md (Estado atual); docs/plans/interface2/README.md (decisões);
00_VISAO.md §3; 01_BIBLIA_VISUAL.md; 04_REGRAS_E_TESTES.md inteiro; as seções de 02_JORNADA.md e
03_TELAS.md que o arquivo da etapa indicar; o arquivo da etapa inteiro; e os protótipos que ele citar
(abra os PNGs em docs/plans/interface2/prototipo/).
Confirme que a etapa anterior está marcada como feita neste README.
Antes de mexer, rode as capturas "antes" da etapa; no fim, as "depois" nas 3 resoluções e ABRA os PNGs.
Testes: SÓ a lista fechada da etapa (tools\test.ps1 -Level etapa -Exact -Tests <lista>); confira com -DryRun.
Nada de regra do jogo muda (tempos, preços, prêmios, requisitos, ids, falas, save).
Atualize: registro deste README (modelo no fim do arquivo da etapa), Estado atual do docs/ROADMAP.md e, se
criou peça/arquivo/comando, CLAUDE.md e AGENTS.md (idênticos).
Commit local "feat(ui2): etapa NN — <resumo>"; sem push, sem publicar. Não execute a etapa seguinte.
```

Pelo pedido do Vitor (23/10/2026), quem executa é um modelo mais barato (subagente Sonnet ou Codex), com o
Claude Code acompanhando: escreve o pedido acima, confere diff, capturas e testes e pede correções.

## Registro

**Etapa 00 (24/10/2026, Claude Code):** plano escrito; tour "antes" com 114 capturas em
`build/screenshots/interface2_antes`; fontes Fredoka e Nunito (OFL) baixadas em `prototipo/fonts/`;
protótipos de Tiro, Missões (+ prêmio) e bandeja do fogão com os sprites reais; primeira versão do rodapé
(barra branca solta) reprovada pelo Vitor ("ícones flutuando") e refeita como base presa à tela em duas
versões. Nenhum arquivo do jogo foi alterado.

**Etapa 00, segunda rodada (24/10/2026):** o Vitor escolheu o rodapé **claro** (gostou de ele ficar meio
transparente) e pediu para repensar a horta, a seta, a lista de mundos, os cuidados do Tiro e os testes.
Novos protótipos: `horta_plantar/colher/seta.png`, `mundos.png`, `tiro_objetos.png`, `tiro_arco.png`.
Paleta escurecida onde o contraste não passava. Testes refeitos em lista fechada por etapa.

**Etapa 00, terceira rodada (24/10/2026):** mapas sem os textos aprovados; **botão Cuidar com roleta**
escolhido e refeito mais espaçado e transparente (`tiro_cuidar.png`, `tiro_roleta.png`, `prancha_roleta.png`).

**Etapa 00, fechamento (24/10/2026):** o Vitor aprovou a direção geral, a pílula de próximo passo **só da
história, sempre no topo**, a folha de prêmio, e pediu Missões **separadas** (História · Pessoas · Diárias,
protótipo `missoes2_*.png`). Plano reescrito para execução por outros modelos: um arquivo por etapa em
`etapas/` com o mapeamento do código atual (arquivos, funções, nós e testes que dependem, com linhas),
passo a passo, armadilhas, testes novos com casos numerados, listas fechadas com tempos medidos
(`build/test_logs/times.csv`), modelo de teste e de registro. Achados que entraram no plano: `test.ps1`
puxa áreas inteiras sozinho (→ `-Exact` na 01); etiquetas do mapa também são alvo de toque (→ auditoria na
06); `pet_care_test`/`brush_taste_test` conferem a ordem dos cuidados e `wish_guide_test` exige
`CarePointer` como `Polygon2D` (→ roleta mantém ordem e raiz); `tasks_groups_test` espera personagens
recolhidos e diárias/semanais separadas (→ testes mudam na 05 com a mesma garantia). Nenhum arquivo do
jogo alterado; sem testes, commit, push ou publicação. **Pronto para a etapa 01.**

**Etapa 01 (24/10/2026, Codex; local):** fontes Fredoka/Nunito (PCK 7.210.824 → 7.504.112 bytes, +286,4 KiB), Palette nova com apelidos, 17 controles SVG 4× e tema liso; `-Exact` e `--i2-01-only`. Lista fechada + rápido: **8/8 PASS em 68 s**, logs `build/test_logs/r20261024_181601_774176ce/`. Nove capturas antes/depois nas três resoluções e tour completo (114 PNGs); acentos conferidos. Quebras: Caderninho excede largura, prêmios de contratos apertados, bloqueios/etiquetas de mapas cortados ou sobrepostos, bandejas altas e títulos de modais em duas linhas. Diferenças do protótipo são as composições antigas, reservadas às etapas seguintes. Auditoria, arquivos e PNGs em [VALIDACAO_01.md](VALIDACAO_01.md). Margens legadas de PillPanel/RowPanel preservadas para manter os contratos existentes; nenhum layout refeito. **Próxima: 02**, não iniciada. Sem push/publicação.

**Etapa 02 (24/10/2026, Codex; local):** peças novas no UiKit (`soft`, `small_go`, `ctl_button`,
`list_card`, `section`, chip por tipo, `badge/dot/spark`, `ring`, `steps`, `stepper`, `tile`, `toggle`),
SlotDot 52, SpeechBubble, Sheet, Popover, `Motion.fly_arc/stagger_in` e voo da coleta. APIs antigas e
filhos-botões de `segmented` preservados. Lista fechada + rápido: **8/8 PASS em 69 s**
(`build/test_logs/r20261024_184430_01997809/`); teste de peças repetido após o ajuste visual do pontinho:
PASS em 2,6 s (`build/i2_02_kit_final.log`). Capturas antes e depois (nove telas, três resoluções) e
vitrine abertas. Diferenças: vitrine em duas páginas para preservar alvos/tamanhos; contorno de tile
2 px (StyleBoxFlat usa inteiros); composições das telas ainda antigas, conforme etapas 03–10.
Registro completo e pendências em [VALIDACAO_02.md](VALIDACAO_02.md). **Próxima: 03**, não iniciada.
Sem regra/save/fala alterada, push ou publicação.

**Etapa 03 (24/10/2026, Claude Sonnet 5.5; local):** rodapé preso claro (84, translúcido), `NavTab` com nomes,
HUD em 2 linhas (`HudProfile`, `HudRow2`), `NextStep` + `QuestGuide`, `Notice` + `Events.notice_requested`; pulsar da aba
Missões saiu. Lista fechada + rápido **12/12 PASS em 163,7 s** (`build/test_logs/r20261024_191708_2c0e9e2b/`;
`next_step_test` 28,8 s e `notice_test` 10,1 s novos). Extras rodados e justificados por tocarem no que mudei:
`tasks_test` (conferia `_tasks_pulse`; agora confere a pílula, mesma garantia de "o jogador é chamado à história"),
`care_ui_test`/`mood_test` (momento e `AnimatedBadge`), `ui_style_test`, `world_view_test` (aviso no Mapa): 5/5 PASS
(`build/test_logs/r20261024_192004_f7e19286/`). Testes alterados por mudança de fluxo, sem enfraquecer: `hud_test`
(HUD 128, linha 2, alvo 44 da engrenagem, aviso um por vez a y ≥ 136, almofada no lugar do círculo que subia) e
`tasks_test`. `world_card.gd`: tirei o override de fonte 16 da dica de bloqueio (volta a 12 da bíblia) porque a dica não
cabia em duas linhas na linha de 64 (`world_selector_test` falhava). Diferenças do protótipo: (a) o ícone de objetivo
`talk` usa o rosto do personagem (a bíblia pede balão de fala vetorial, que não está nos 17 controles): no estado
`talk` a pílula mostra só rosto + `0/1`; (b) o avatar tem retrato 40 em disco 58, um pouco menor que o desenho; (c) "Pegar" no
Mapa fica só com ✓ (compacto); (d) os conteúdos da tela do Tiro (anéis, cuidados) continuam os de antes, só deslocados 40 px
para baixo do novo HUD: a 04 os refaz. Pendências: `StepCard` não abre o nome do capítulo (02 §2.2, opcional); aviso toca
Como fazer só para erro com item. Capturas: `i2_03_antes`, `i2_03_depois`, `_390`, `_412`.

**Etapa 03, conferência a mão até `lais_bag` (24/10/2026):** script `game/tests/pill_walk_shots.gd` (não é teste; sem
`--headless`) dirige o `main` com save novo e só usa a pílula do próximo passo: em cada passo captura, abre o cartão,
toca em `Ir` (anota o destino), faz no lugar o que a missão pede e toca na pílula verde. Ordem e destinos do `Ir`:
`welcome` (mundo `house`, `npc:lais`) → `lais_feed` (`house`, `bowl`; abriu a tigela) → `lais_bath` (tela Tiro) →
`lais_play` (tela Tiro) → `lais_bag` (tela Mochila; o próprio `Ir` conta o objetivo `open:bag`). Os cinco passaram a
`ready`, a pílula verde concluiu cada um (`claimed_quests`) e o seguinte apareceu. Capturas abertas em
`build/screenshots/i2_03_mao/` (20 PNGs: antes/cartão/destino/pronto por passo), log em `build/i2_03_mao.log`. Nada
quebrou; lista fechada não precisou rodar de novo (nenhum código do jogo mudou). Observação: um aviso do Godot
"Lambda capture ... was freed" aparece uma vez ao tocar `Ir` com o cartão aberto (do fechamento do `PopoverCatcher`,
padrão já usado em `Hud._close_popover`); não derruba nada.

**Etapa 04 (24/10/2026, Codex; continuação local):** cenário 1,75×, anéis 40 na linha 2 do HUD,
MoodLabel de 2,5 s, WishBubble branco com estrela, PetCareTray como botão Cuidar + roleta
(CareButton, CareAsk, CareWheelOpen), FoodMenu acima do botão e CarePointer alfinete.
Lista fechada + rápido **10/10 PASS em 142,1 s** (`build/test_logs/r20261024_200942_9af303fe/`);
`growth_ui_test` adicional justificado pela remoção de GrowthBadgeHint: PASS em 15,3 s
(`build/i2_04_growth_final.log`), total 157,4 s. Toque Web emulado PASS: banho e alimentação
por arrasto (higiene 70→99,997; barriga 40→64,958; ração 3→2), seis PNGs abertos.
Sete capturas depois nas três resoluções abertas. Diferenças: ordem original dos cuidados;
ZOOM multiplicativo conforme passo a passo; contorno inteiro 2 px; rótulo Cuidar sobre o pé do disco;
ícones existentes preservados. Registro completo: [VALIDACAO_04.md](VALIDACAO_04.md).
Próxima: **05**, não iniciada. Sem regra/save/fala alterada, push ou publicação.

**Etapa 05 (24/10/2026, Codex; local):** Missões em História/Pessoas/Diárias, ChapterSteps,
linhas com sanfona e Pegar tudo na linha 2. `claim_quest_fx` dá voo em cartão, pílula, conversa, linha,
Pegar tudo e no atalho do Como fazer; QuestReward na fila modal, capítulo com próximo destino,
aviso genérico de missão removido. Lista fechada + rápido **10/10 PASS em 158,6 s**
(`build/test_logs/r20261024_204158_b60ee618/`); reexecução final do teste novo descrita em
[VALIDACAO_05.md](VALIDACAO_05.md). Sete capturas nas três resoluções, quinze da conferência guiada
até o fim do capítulo 1; PNGs abertos. Diferenças: dados/falas reais completos, capítulos/listas com
rolagem e cartão grande com composição preservada para a 10. AGENTS/CLAUDE idênticos.
Sem alteração de regra/save/fala/prêmio; nenhuma pendência funcional da 05. Aviso antigo de lambda ao
fechar painel reaparece no roteiro, sem travar. Próxima **06**, não iniciada. Sem push/publicação.

**Etapa 06 (24/10/2026, Codex; local):** mapas sem etiquetas permanentes; segurar 500 ms mostra o nome
por 1,5 s sem agir, arrastar cancela a consulta. Auditoria: 34 etiquetas elegíveis nos cinco mundos,
zero ações sem caminho físico, zero polígonos novos. Brilho de lugar novo com marcas em `progress.seen`,
balões lisos e `WorldPin` no nó Pointer com anel na base real; WorldPill/NpcFace/Lugares atualizados.
Seletor em cartões-postais, fotos/cinzas geradas por `tools/world_thumbs.gd`, conversa com detalhe de Pessoas
e serviços em linhas; compra com figura 64, SpaceChip e preço no botão. Lista fechada + rápido
**10/10 PASS em 125 s (Jobs=2; 247,8 s somados por processo, acima do orçamento estrito)**;
foco final world_pin_test PASS. Resultado e tempos na
[VALIDACAO_06.md](VALIDACAO_06.md), com oito capturas nas três resoluções e auditoria de toque.
Desvios: miniaturas mostram os enquadramentos reais com compras básicas; fotos se adaptam à altura
para manter cinco destinos e dicas completas; teste de retrato isola a fila de prêmio da etapa 05.
Nenhuma regra/save/fala/prêmio alterado. Próxima **07**, não iniciada. Sem push/publicação.

**Etapa 06, pausa por limite (24/10/2026, 21:45, orquestrador):** o Codex parou às 21:19 com a cota de 5 h em 100% (volta por volta de 01:02 de 25/10) e a continuação no Claude Sonnet 5.5 (aberta às 21:31 com `build/orquestrador/etapa06_continuacao.md`) foi recusada na hora por limite de sessão (volta às 22:20). Estado no disco: etapa 06 quase pronta, sem commit (último commit `abd4b5d`, etapa 05); README já marca a 06, mas falta a conferência e o commit local. Retomar pelo Claude após 22:20 com o mesmo arquivo de continuação.
