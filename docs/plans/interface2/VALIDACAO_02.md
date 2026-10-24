# Interface 2 — validação da etapa 02

24/10/2026, Codex. Etapa 01 conferida como `[x]` antes da implementação. Somente peças de
interface: nenhum dado de conteúdo, regra, requisito, missão, fala, save ou publicação alterado.

## Pronto quando

- [x] Vitrine segue `estilo.png`: fontes, pílulas, cores semânticas, discos, anéis e superfícies lisas.
  Diferenças e limites abaixo.
- [x] Assinaturas antigas preservadas; as nove telas de `--i2-01-only` também abrem por
  `--i2-02-only`, com nomes `i2_02_*`.
- [x] `ui2_kit_test` e lista fechada verdes, incluindo o rápido obrigatório.

## Testes

Conferência prévia com `-DryRun`: somente os oito abaixo, estimativa inicial 88 s. Sem suíte
inteira, campanha, simulador, export ou teste de aparelho físico.

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Exact -Tests ui2_kit_test,ui_style_test,ui_base_test,sheet_test,lists_test
```

**Resultado final da lista: 8/8 PASS em 69 s.** Logs/CSV:
`build/test_logs/r20261024_184430_01997809/`.

| Teste | Resultado | Tempo |
|---|---|---|
| scripts_check | PASS | 9,5 s |
| content_test | PASS | 6,8 s |
| texts_test | PASS | 2,6 s |
| ui2_kit_test | PASS | 2,4 s |
| ui_style_test | PASS | 7,8 s |
| ui_base_test | PASS | 2,4 s |
| sheet_test | PASS | 17,6 s |
| lists_test | PASS | 18,6 s |

Tempos individuais somam 67,7 s; total inclui coordenação. Após essa lista, a revisão visual
ajustou o pontinho vazio (Label preservava altura de linha e o desenhava oval). Revalidação do
teste de peças: PASS em 2,6 s; após conferir também o nome legado `Plus` do slot de compra,
PASS em 2,5 s, `build/i2_02_kit_final.log` e `.err` vazio.

O teste novo cobre os dez casos pedidos, usa toque no viewport para stepper/toggle, confere
as áreas de toque e também a ordem das divisórias. Foi registrado em `suite`, área `ui_kit`
e `paths`, com `.uid`. Nenhum teste antigo foi alterado ou teve garantia enfraquecida.

Primeiras tentativas, corrigidas: alvo do ghost menor que 44; divisórias disparando sua própria
criação; nomes automáticos das divisórias; coordenadas de teste sem transformação do viewport.
A primeira lista parou em scripts_check porque o padding de segmented adicionava Controls onde
chamadores percorrem filhos como Button: o padding passou ao desenho, preservando filhos-botões.
Uma lista seguinte já passou 8/8 em 77,5 s; a lista final acima validou os ajustes visuais posteriores.

## Capturas e comparação

- Antes, **antes de qualquer edição do jogo**: `build/screenshots/i2_02_antes/` (9 PNGs, prefixo
  `i2_01_`, bloco existente usado conforme a instrução).
- Depois: `build/screenshots/i2_02_depois/`, `i2_02_depois_390/`, `i2_02_depois_412/` (9 por pasta).
- Vitrine: `build/screenshots/i2_02_vitrine/`, `i2_02_vitrine_390/`, `i2_02_vitrine_412/`
  (`vitrine.png` e `vitrine_listas.png` por pasta).
- Pranchas locais de revisão nas três resoluções: `build/i2_02_review/`.

PNGs abertos e comparados com `estilo.png`, `missoes2_historia/personagens/diarias.png`, `fogao.png`
e o antes. A vitrine foi dividida em duas páginas para mostrar todos os estados sem reduzir fonte
ou alvo de toque: controles/produção na primeira, listas/falas na segunda. O protótipo de estilo
é uma prancha editorial maior, com amostras e texto explicativo; a vitrine usa medidas do jogo.

| Tela | Revisão das peças | Composição preservada / próxima etapa |
|---|---|---|
| Vitrine, ambas as páginas | ✓ Fredoka/Nunito; cores com sinal adicional; chips com números; alvos ≥44; seleção branca/tinta; divisórias entre três linhas; menos animação | Catálogo de componentes, sem compor uma tela de jogo |
| Tiro | ✓ peças herdadas; rodapé não foi recomposto | HUD/casca 03, roleta 04 |
| Missões | ✓ botões/segmentos lisos; seleção sem verde; linhas compactas | Principal/Personagens/Temporárias antigos até 05 |
| Mochila | ✓ segmentos e chips; botões/nós preservados | Grade e filtro mantidos até 08 |
| Sítio | ✓ peças herdadas | Etiquetas/bloqueios antigos, sem remoção antecipada (06) |
| Fogão | ✓ SlotDot 52 e estados; chips compactos | Bandeja antiga, contorno da receita e recorte horizontal ainda da 07 |
| Detalhe de cenoura | ✓ alça a 10 do topo, fechar 32 em alvo 44, chips menores, mais conteúdo visível | Fluxo/layout do item mantido até 08 |
| Configurações | ✓ seleção branca sem borda verde, fechar afundado, acentos | Interruptor novo disponível; tela ainda usa segmented, sem redesenho antecipado |
| Capítulo/modal | ✓ tema/peças herdadas | Fita/composição antigas, só 10 |
| Resumo do avatar | ✓ superfície branca canto 16 e rabinho apontando para a âncora | Conteúdo e posição existentes; casca só 03 |

Na vitrine não há corte/sobreposição nas três resoluções. As telas antigas preservam as
limitações de composição registradas em VALIDACAO_01: etiquetas do mapa, bandejas altas/receitas
parciais, caderninho largo, contratos apertados e títulos de modais. Não são critério de redesenho
da 02; os componentes novos estão prontos para as etapas correspondentes. Textos/controles
montados à mão também continuam até as respectivas etapas.
O filtro da Mochila continua em faixa com rolagem horizontal (a última opção pode aparecer parcial),
e a receita selecionada da bandeja ainda tem o contorno verde próprio: substituições nas etapas 08/07.

A captura anterior teve avisos ambientais de escrita em `user://`/certificados no processo restrito;
os nove PNGs foram gerados. Importação, testes finais e capturas posteriores rodaram com acesso
normal do Godot, usando o isolamento de testes e o caminho descartável do tour. Logs finais sem
erros de script. Nenhum save pessoal foi usado como cenário de teste.

## Arquivos e contratos

- `scripts/ui/ui_kit.gd`: `soft` e apelido secondary, `small_go`, `ctl_button`, `surface/disc`,
  `list_card`, `section`, chips por tipo, `badge/dot/spark`, `ring`, `steps`, `stepper`, `tile`,
  `toggle`; list_row mantém VBox no filho 0 e ganha `ready` opcional. Segmentos conservam os nomes
  `NotebookTab_<id>` e têm somente botões como filhos diretos, como antes.
- `assets/theme/main_theme.tres`: `SmallGoButton`, desenho 36/lábio 2 em alvo 44. ChipLabel já
  existia da 01; foi reutilizado.
- `assets/fonts/font_caption_spaced.tres`: Nunito 800 com espaçamento de glifo 1.
- `slot_dot.gd`: DOT 52, anéis/tracejados e controles vetoriais, preço em chip. Preservados `state`,
  `icon_rect`, `Dot`, `Ring`, `Icon`, `Check`, `Plus`, `Caption`, `LockIcon` nos estados pertinentes.
- `speech_bubble.gd`: `inside_card` opcional, nome em SmallLabel acima, fundo/sombra e rabinho.
- `sheet.gd`: alça e fechar; sinais, alturas e gesto preservados; saída usa SHEET_OUT.
- `popover.gd`: superfície e rabinho; duração/fechamento/posicionamento preservados.
- `motion.gd`: aperto 0,96; novos tempos, `fly_arc` e `stagger_in`, ambos respeitam reduced.
- `collect_fx.gd`: usa arco até o mesmo destino de moedas; preserva camada WORLD_FX_Z.
- `tests/ui2_kit_test.gd/.uid`, `tests/ui2_kit_shots.gd/.uid`, bloco `--i2-02-only` no ui_tour,
  mapa `tools/test_areas.json`, este registro, README/ROADMAP e AGENTS/CLAUDE idênticos.

`RingProgress` já tinha color, track SUNKEN, espessura 4 e padrão 56; foi conferido e reutilizado,
sem alteração desnecessária do arquivo. Nenhuma função antiga do UiKit foi removida.

## Decisões, desvios e passagem

- Tile selecionado usa borda inteira de **2 px**, com border_blend; StyleBoxFlat só aceita inteiro
  para largura da borda. A bíblia descreve 2,5 px. Cor INK e estados preservados.
- Pequenos controles e SmallGo conservam botão com alvo ≥44; a superfície visível fica menor.
- Duas páginas de vitrine, pelas razões acima. Sem importação de arte nova ou alteração de sprites.
- A revisão automática rejeitou uma tentativa de encerrar processos Godot por idade, pelo risco
  de atingir editor alheio. A ação não foi executada: o runner encerrou o teste antigo pelo seu
  próprio timeout. Não há ação bloqueada nem aprovação pendente.
- Alterações preexistentes em `assets/` (incluindo exclusões da biblioteca Python de arte) ficaram
  intocadas e fora do commit; nenhum arquivo alheio foi incluído.

Próxima: **03, casca**. Ler este registro e VALIDACAO_01; usar as peças prontas sem reconstruir
estado de jogo. Caderninho/contratos/bandejas/mapas continuam para 08/09/07/06. Nova toggle e
small_go estão disponíveis; adoção pelas telas acontece nas etapas delas. Sem push/publicação.
