# Interface 2 — ajustes: fechamento local (25/10/2026)

Executor: Codex, sozinho, sem worktree. Etapa 12 concluída localmente (Codex + Claude Sonnet 5.5).
Sem push, publicação, campanha/simulador, mudança de regra, save, fala ou arte.

## Item 32 e decisões finais da revisão

- ✓ `UiKit.GOOD/BAD` removidos: 35 referências qualificadas do HEAD anterior (27 GOOD, oito BAD), mais o uso interno de `effect_chip_list`, agora usam `Palette.GO_INK/ALERT_INK` diretamente.
- ✓ `UiKit.secondary` removida; chamadores usam `UiKit.soft` com os mesmos argumentos. Nenhum botão, callback, ícone ou alvo foi retirado. A variação atual continua se chamando `SecondaryButton`.
- ✓ Busca prévia em `game/`: `TopBarPanel`, `BarLabel` e `ToastLabel` só existiam no tema; `SoftButton` já não existia. Removidas as três variações e o sub-recurso `toast`, que ficou órfão. `OverLabel`/`UiKit.section` da etapa 10 preservados.
- ✓ `Motion.reveal_rewards(container, animate := true)` é a implementação única da entrada dos prêmios. `ModalCard.reveal` e `RewardSheet.reveal_in` são fachadas de uma linha para preservar os contratos. Mantidos início 0,28 s, intervalo 0,08 s, pop, contagem de +N/×N, `animate: false` e `Motion.reduced`. Callback transporta id e verifica a instância antes de mostrar.
- ✓ `world_selector.gd` preservado: referenciado pela cena, não é órfão.

Notas do §4 da revisão: a sequência executada é a do plano aprovado de ajustes (12 etapas), com executor único; a proposta antiga de lotes paralelos/worktrees foi substituída pela ORQUESTRACAO. Decisões 7/8/9/31/35 já aprovadas e executadas nas respectivas etapas. Comparações usam dados reais; não se alterou requisito, tempo, preço, prêmio, fala ou formato do save para reproduzir um protótipo. Nada publicado.

## Testes

Lista fechada: **10/10 PASS em 144,4 s**, incluindo os três rápidos obrigatórios, sem lista extra.
`build/test_logs/r20261025_171231_a18b1dc2/results.csv`; transcrição `build/aj_12_lista.log`.

| Teste | Resultado | Segundos |
|---|---|---:|
| scripts_check | PASS | 11,3 |
| content_test | PASS | 8,0 |
| texts_test | PASS | 3,3 |
| ui2_kit_test | PASS | 3,0 |
| ui_style_test | PASS | 10,9 |
| festa_test | PASS | 12,0 |
| quest_reward_test | PASS | 27,6 |
| walk_return_ui_test | PASS | 23,3 |
| text_budget_test | PASS | 23,8 |
| lists_test | PASS | 19,5 |

Primeira tentativa: `r20261025_171150_3ec24f5b`, interrompida no `ui2_kit_test`: a tabela de fábricas ainda chamava `secondary` dinamicamente. A entrada duplicada do apelido saiu; `soft` continua verificada com a mesma variação e alvo mínimo. `ui_style_test` testa `soft` também na versão pequena (44 px); `ui_base_test` passa a exigir ausência dos apelidos, substituindo o contrato transitório da migração visual. Nenhuma regra nova das etapas 09–11 foi enfraquecida. `festa_test` continua conferindo chips inicialmente ocultos, entrada, contagem final e Menos animação.

Portão: 102 testes; primeira passada do Codex teve 3 falhas (park_test, sheet_test, station_tray_test: `_recipe_card` usava `action.custom_minimum_size` depois de `free()` e o `park_test` esperava `StartWalk_` com bagagem pendente; ambos corrigidos). Segunda passada (`build/aj_12_portao2.log`, `build/test_logs/r20261025_173340_449db815`, 618 s): 99 PASS e 3 falhas intermitentes (pet_care_test, manual_test, gestures_test) sob carga paralela; os três (mais sheet_test, que também oscila: o arrasto curto depende de velocidade em tempo real) passaram isolados e em `test.ps1 -Jobs 3` (`r20261025_174537_16684557`). Nenhum código mudou entre as passadas. Pendência de estabilidade: sheet_test e esses três são sensíveis à carga.

## Capturas e pranchas

Tour 114/114/114 PNGs gerados e amostras abertas (fogão, Crescimento, encomendas 412): sem corte, sem botão cinza mudo, sem apelidos de cor. Linha de base: `build/screenshots/aj_base`, `_390`, `_412`, da etapa 01.
Tour final: `aj_12_tour`, `_390`, `_412`. Complementos: `aj_12_extra_06*` (três abas e caderninho), `aj_12_extra_09*` (Como fazer/conversa/compra), `aj_12_texto*` (Texto maior).
Pranchas: `docs/plans/interface2/prototipo/prancha.html#aj_<tela>`; renders e contatos em `build/aj_12_review/`.
As telas que não existem nas 114 capturas da base têm comparação complementar identificada na própria prancha, sem apresentar uma imagem posterior como linha de base da etapa 01.

## Checklist 04 §B por tela

Conferido por amostras do tour nas três resoluções e pelas pranchas da revisão da Codex; sem divergência aberta além das pendências abaixo. Visual = fontes, vetores, superfícies, cores, primário, espaços, valores. Jogo = foco, texto, retorno, estado, gesto, bloqueio consultável e movimento. Celular = alvos, cortes/rodapé, contraste, Menos animação e estados. A latência/vibração em aparelho físico continua no roteiro; o teste local usa Chrome com eventos de toque reais.

## Toque e desempenho

Medido (Chrome, `build/touch_test/perf.txt`). Roteiro: `build/touch_steps_i2_12.json`; mesmo método da 01/03: intervalos de requestAnimationFrame, descartando os dois primeiros, média/P95/pico/quadros >33,4 ms. Meta de média ≤20 ms no computador. Isso não é tempo interno da GPU nem medição em telefone físico.

**Resultado final:** toque real PASS inteiro. Sítio com balões 17,5 ms média, P95 16,9, 11 quadros >33,4, pico 100 (n=622); folha de prêmio 17,4 ms, P95 16,9, pico 83; roleta 17,3 ms, pico 67. Meta ≤20 ms atingida; Sítio melhorou de 28,4 → 17,5 ms.

Base da 01: Sítio 28,4/28,2 ms; P95 66,6/66,6; 123/114 quadros >33,4; picos 183/217. Etapa 03: média 17,4–17,8; P95 16,8; 11 lentos por rodada; picos 83–117. Picos anteriores de roleta/folha 83–150 → 66–117 ms na 03.

## Roteiro do celular, quando o Vitor pedir publicação

1. Abrir `/dev/` e instalar como PWA. Alternar as quatro abas; conferir fontes, acentos, rodapé e barra de gestos.
2. Deixar um aviso de momento visível e abrir folha/seletor: ele deve ocupar a faixa recolhida, sem cobrir o título.
3. Ligar Texto maior. Ver HUD/moedas, Configurações/saves, História/Pessoas/Diárias e nomes do caderninho; nenhum corte ou sobreposição.
4. Na Casa, tocar o fogão: objeto visível acima da bandeja, escolher receita, usar −/+/Tudo e Cozinhar. Conferir falta de ingrediente, fila cheia consultável e coleta direta.
5. No Sítio, plantar arrastando desde o canteiro por outros quatro; regar/colher; câmera e pinça preservam a barra, pinça cancela o gesto. Ver selo do regador e Colher tudo.
6. Abrir Crescimento: duas fases, consulta no título, indicador único, grade de requisitos, seleção/detalhe e um verde. Ver pronto/Crescer e seda no adulto.
7. No Tiro, tocar para ler o humor; deve sumir em 3 s. Abrir Cuidar, cardápio sem cobrir o focinho, provar/arrastar comida e dar banho. Conferir selo Animado.
8. Abrir obras, encomendas, Natureza, passeios e saves. Ações bloqueadas devem mostrar motivo/ícone/consulta, sem botão cinza mudo; obras com um M/N e um indicador.
9. Conferir capítulo/Novo!/volta do passeio, Ir ao destino e entrega única dos prêmios; usar o alfinete e segurar um lugar sem agir ao soltar.
10. Repetir com Menos animação; testar vibração e resposta ao polegar. Observar engasgos no Sítio, na roleta e na primeira folha.

## Pendências preservadas

- Corpo da bandeja do Galinheiro ainda rola com animais/fila.
- `update_finds/update_wishes` no tique de 1 s ainda pesam no Sítio; medir em aparelho também.
- `Tudo` fica perto da borda direita do seletor de quantidade.
- Fala real de prêmio pode exceder o orçamento ilustrativo; preservada por ser fala da história.
- Manual conserva instruções/exemplos do catálogo; não foi redesenhado além do aprovado.
- Sons/música, tema escuro, dia/noite e decoração seguem em `../interface2/FUTURO.md`.

Exclusões preexistentes de `assets/pixellab_character/tiro_bebe/python_libs` e `IUREF/` pertencem ao estado anterior do Vitor e ficam fora do commit.
