# Interface 2 — validação da etapa 01

24/10/2026, Codex. Somente a base visual; nenhuma alteração de regras, dados de conteúdo, save,
missões ou falas. Etapa 00 conferida como `[x]` antes da execução. Etapa 02 não iniciada.

## Pronto quando

- [x] `tools/test.ps1 -Exact` funcionando; `-DryRun` só seleciona o rápido + a lista pedida.
- [x] `ui_tour.gd --i2-01-only` com nove telas e saída configurável; comandos no mapa do projeto.
- [x] Tema e tour com Fredoka/Nunito, nova paleta e controles SVG. PNGs antigos e Jersey preservados.
- [x] Teste novo registrado em `suite`, área `ui_kit` e `paths`; lista fechada verde.
- [x] Pacotes Web antes/depois medidos; aumento abaixo de 600 KB, sem subconjunto de fontes.
- [x] Capturas abertas, diferenças e quebras registradas abaixo para as próximas etapas.

## Testes e pacote

Comando conferido primeiro com `-DryRun`:

```powershell
powershell -ExecutionPolicy Bypass -File tools/test.ps1 -Level etapa -Exact -Tests ui2_tokens_test,ui_style_test,ui_base_test,hud_test,sheet_test
```

**Final: 8/8 PASS em 68 s.** Logs e CSV: `build/test_logs/r20261024_181601_774176ce/`.

| Teste | Resultado | Tempo |
|---|---|---|
| scripts_check | PASS | 9,8 s |
| content_test | PASS | 7,5 s |
| texts_test | PASS | 2,9 s |
| ui2_tokens_test | PASS | 2,7 s |
| ui_style_test | PASS | 9,7 s |
| ui_base_test | PASS | 2,7 s |
| hud_test | PASS | 12,4 s |
| sheet_test | PASS | 19,1 s |

Tempos individuais somam 66,8 s; total inclui a coordenação dos processos. Isolado:
`build/i2_01_tokens_isolado_final.log` (PASS, sem erros de script).

O novo teste foi executado isoladamente antes da lista. Primeiras tentativas revelaram dependência do
autoload `Database` no carregamento estático do UiKit: teste passou a carregá-lo em tempo de execução,
como os outros testes de UI. Não foram tratadas falhas de script como PASS.

As duas regressões da lista foram corrigidas no tema sem enfraquecer testes: `PillPanel` mantém 10 px
laterais (aviso ≤320 px, antes ficou 324); `RowPanel` mantém margens anteriores 8/5/8/5 (linha ≤100 px,
antes ficou 102). Cor clara forçada do aviso foi trocada pela tinta escura sobre o novo fundo branco.
Somente `ui_style_test` mudou expectativas deliberadamente: tipografia 24/12, cartão/botão sem borda,
chip canto 14, folha canto 28 e ajuda/cadeado SVG. A verificação de um primário por painel permanece.

**PCK prod: 7.210.824 → 7.504.112 bytes (7.041,8 → 7.328,2 KiB), +293.288 bytes / +286,4 KiB.**
Mesmo conteúdo dos canais prod/dev; o canal altera apenas a identificação local. Sem subconjunto necessário.

Logs dos exports: `build/i2_01_export_antes.log` e `build/i2_01_export_depois.log`; medidas em
`build/i2_01_pck_antes.json` e `build/i2_01_pck_depois.json`. Export local prod/dev, sem publicação.
Primeiro tour/export restritos emitiram erros ambientais de certificados e escrita em `user://`;
os processos finais rodaram com acesso normal do Godot, sem esses erros. Não houve suíte inteira,
campanha, simulação de economia ou teste de aparelho físico.

## Capturas e revisão visual

- Antes, após criar as ferramentas e antes de trocar o visual: `build/screenshots/i2_01_antes/` (9).
- Depois: `build/screenshots/i2_01_depois/`, `i2_01_depois_390/`, `i2_01_depois_412/` (9 cada).
- Tour completo final 360×780: `build/screenshots/i2_01_tour/` (114).
- Pranchas locais para revisar todas as telas: `build/i2_review/`.

As nove telas são Tiro, Missões, Mochila, Sítio, bandeja do fogão, detalhe da cenoura,
Configurações, capítulo concluído e resumo do avatar. PNGs abertos nas três resoluções; conferidos
acentos em “Missões”, “Configurações”, “Você não tem”, “Próximo passo”, “Cenoura gelada” e “Papinha”.

| Tela | Fontes/cores/controle | Layout e diferença intencional do protótipo |
|---|---|---|
| Tiro | ✓ Fredoka/Nunito, moeda escura sobre branco, engrenagem lisa | Cuidados e HUD ainda na composição antiga; roleta só na 04 e casca na 03 |
| Missões | ✓ títulos, corpo, cartões e botões lisos | Abas Principal/Personagens/Temporárias preservadas até a 05 |
| Mochila | ✓ quantidade em Fredoka 18 e controles novos | Grade, filtros e selos Novo antigos; etapa 08 |
| Sítio | ✓ fontes, check e relógio lisos | Nomes e marcadores se sobrepõem; etapa 06 retira etiquetas |
| Fogão | ✓ fechar/relógio/quantidade SVG e primário com lábio | Bandeja antiga larga/alta e rolagem horizontal; etapa 07 |
| Detalhe de item | ✓ título, botões, cartões e sombra | Conteúdo/fluxo preservado; etapa 08 |
| Configurações | ✓ acentos e botões lisos, fechar SVG | Contorno de seleção ainda verde; peças da etapa 02 |
| Modal | ✓ tema e fontes herdados | Fita, composição e tamanhos forçados antigos; etapa 10 |
| Resumo do avatar | ✓ pílula branca e ação calma | Conteúdo adulto curto; casca/resumo da etapa 03 |

As quatro medidas globais e a linguagem visual já estão no tema. A auditoria de tamanhos forçados
abaixo é a exceção transitória expressamente prevista na etapa 01. A composição das telas, o número de
ações, os ícones pixel de itens sem moldura e a seleção ainda verde ficam para as etapas específicas.
Menos animação continua disponível e o tour inclui a tela de sua preferência; a lista de testes foi
executada com as verificações de movimento já existentes, sem criar testes visuais por pixel.

## Quebras e alertas de layout (não corrigidos nesta etapa)

| Problema observado | Arquivo/função de origem | PNG em `i2_01_tour/` | Próxima etapa |
|---|---|---|---|
| Caderninho fica mais largo que a tela: título cortado à esquerda, X/abas/colunas saem pelas laterais | `scripts/ui/pet_notebook.gd: panel`, `UiKit.segmented`, `sheet.gd` | `f05_notebook_manual`, `f06_notebook_collection`, `t06_notebook_growth` | 02 prepara peças; 08 resolve a composição |
| Prêmios das encomendas/contratos ficam apertados; “300 moedas · Preparar” corta na base do tile | `scripts/ui/market_ui.gd: _order_tile` | `b14b_neighbor_orders`, `b14c_own_stall` | 09 |
| Textos dos bloqueios de destinos quebram em duas/três linhas e ficam junto à borda inferior | `scripts/ui/world_card.gd`, `world_selector.gd` | `a03_map` | 06 |
| Etiquetas de Casa se sobrepõem (Sítio/Geladeira/Fogão); Sítio corta Armazém/Moinho nas bordas | `scripts/ui/world_label.gd`, `levels/room/room.gd` | `b06_world_house`, `b06_world_farm`, `d01_farm_zoom_out`, `d06_farm_zoom_out` | 06 |
| Praça corta Pet shop/Costura à direita, Natureza corta Clareira escondida à esquerda | `scripts/ui/world_label.gd`, `levels/room/room.gd` | `b06_world_park`, `b06_world_nature` | 06 |
| Bandeja de estação usa grande parte da altura; última receita da faixa aparece parcial, chips de efeitos passam à segunda linha | `scripts/ui/action_tray.gd`, `station_tray.gd` | `e07_tray_stove`, `e08_tray_stove_missing`, `e12_tray_blender`; também `i2_01_stove_tray` nas três resoluções | 07 |
| Menu de comida quebra “Petisco de cenoura” e o selo Provar compete com a borda do menu | `scripts/ui/pet_care_tray.gd` | `f08_pet_food_menu` | 04 |
| Títulos dos cartões de volta/boas-vindas ocupam duas linhas; “De volta!Volta na praça” expõe concatenação antiga sem respiro | `scripts/ui/modal_card.gd`, `ui/walk_result/walk_result.gd`, `ui/welcome_back/welcome_back.gd` | `c03_welcome_back`, `c04_walk_result`, `h04_welcome_grouped` | 10 |

As bordas do mapa já cortavam algumas etiquetas antes; a fonte mais larga agrava a sobreposição.
As capturas preservam o enquadramento existente: não foram reposicionados mapas, objetos ou painéis.
As listas longas do Manual/Coleção/receitas continuam roláveis, sem tentar encolher conteúdo para caber.

## Arquivos e funções novos

- `font_display.tres`, `font_body.tres`, `font_caption.tres`; `main_font.tres` preserva o caminho antigo.
  Fredoka 600; Nunito 700/800; eixo `wght`, números tabulares e fallback dos símbolos preservados.
- Dois TTFs e duas licenças OFL, importação cinza/hinting leve/sem MSDF ou mipmaps.
- `assets/sprites/ui/ctl/`: 17 SVGs com `.import`, 96×96. Catálogo/atribuição em `ART_PIPELINE.md`.
- `UiKit.CTL_DIR`, cache `_ctl_cache`, `ctl_icon(name)` e `ctl(name, px, color)`.
  `icon`/`button` aplicam filtro linear/tinta só aos controles; `icon_button` também resolve símbolos
  legados de ajuda, voltar e quantidade. Nenhum PNG de item foi substituído.
- `StrongLabel`, `OverLabel`, `ChipLabel` e `SmallButton` no tema; novos tokens e apelidos da Palette.
- `ui2_tokens_test.gd` + `.uid`; oito casos do contrato, incluindo compatibilidade dos símbolos.
- `test.ps1 -Exact`; bloco `ui_tour.gd --i2-01-only` com as nove capturas.

## Decisões e limites

- A lista detalhada da etapa define **17 ícones incluindo `talk`**. Seguiu-se essa lista e o teste
  numerado, que prevalecem sobre a lista resumida da bíblia que menciona `sort`.
- Seguiu-se a instrução mais específica de importação SVG **4×** da etapa (a bíblia resume 2×).
- Cores de mundos/selos/cercas/luz preservadas. Jersey e PNGs antigos permanecem para a limpeza da 11.
- `square_button` conserva a API antiga usada por testes; ajuda é SVG e não texto.
- Removidos sete overrides redundantes via variações (avatar, quantidade da Mochila, título de mundo,
  humor do Tiro, texto das abas, nome da rotina e etiqueta de mundo). Os restantes estão listados abaixo para as telas.
- Não foram corrigidas as quebras de layout listadas. Nenhuma etapa seguinte foi executada.
- Alterações alheias em `assets/` e seus arquivos excluídos ficaram fora do commit; nenhum sprite do
  Tiro bebê, arte-fonte ou linha de publicação do ROADMAP foi descartado ou incluído por esta etapa.

## Overrides de tamanho ainda presentes

Inventário gerado após a implementação; não removidos porque ainda dependem da etapa da tela.

| Arquivo:linha | Override preservado |
|---|---|
| `game/scripts/ui/album_view.gd:51` | `button.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/album_view.gd:90` | `badge.add_theme_font_size_override("font_size", 6)` |
| `game/scripts/ui/album_view.gd:91` | `badge.add_theme_font_size_override("outline_size", 0)` |
| `game/scripts/ui/album_view.gd:165` | `caption.add_theme_font_size_override("font_size", 13)` |
| `game/scripts/ui/collect_fx.gd:47` | `label.add_theme_font_size_override("font_size", 22)` |
| `game/scripts/ui/dev_panel.gd:39` | `tab.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/dev_panel.gd:62` | `button.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/game_manual.gd:72` | `tile.add_theme_font_size_override("font_size", 14)` |
| `game/scripts/ui/growth_ui.gd:305` | `result.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/hud.gd:41` | `_growth_alert.add_theme_font_size_override("font_size", 20)` |
| `game/scripts/ui/hud.gd:120` | `_animated_badge.add_theme_font_size_override("font_size", 13)` |
| `game/scripts/ui/hud.gd:187` | `dev_button.add_theme_font_size_override("font_size", 18)` |
| `game/scripts/ui/hud.gd:305` | `tip.add_theme_font_size_override("font_size", 14)` |
| `game/scripts/ui/hud.gd:317` | `help.add_theme_font_size_override("font_size", 14)` |
| `game/scripts/ui/market_ui.gd:137` | `button.add_theme_font_size_override("font_size", 14)` |
| `game/scripts/ui/market_ui.gd:208` | `if label: label.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/market_ui.gd:213` | `summary.add_theme_font_size_override("font_size", 14)` |
| `game/scripts/ui/modal_card.gd:125` | `label.add_theme_font_size_override("font_size", 26)` |
| `game/scripts/ui/motion.gd:173` | `label.add_theme_font_size_override("font_size", 22)` |
| `game/scripts/ui/nature_ui.gd:196` | `button.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/pet_care_tray.gd:56` | `_play_hint.add_theme_font_size_override("font_size", 14)` |
| `game/scripts/ui/photo_card.gd:116` | `text.add_theme_font_size_override("font_size", maxi(9, int(12 * scale_factor)))` |
| `game/scripts/ui/photo_card.gd:125` | `title.add_theme_font_size_override("font_size", maxi(11, int(13 * scale_factor)))` |
| `game/scripts/ui/photo_card.gd:135` | `date.add_theme_font_size_override("font_size", maxi(9, int(11 * scale_factor)))` |
| `game/scripts/ui/progression_ui.gd:763` | `button.add_theme_font_size_override("font_size", 18)` |
| `game/scripts/ui/sheet_builder.gd:636` | `tile.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/slot_dot.gd:55` | `plus.add_theme_font_size_override("font_size", 40)` |
| `game/scripts/ui/ui_kit.gd:385` | `tab.add_theme_font_size_override("font_size", 18)` |
| `game/scripts/ui/world_card.gd:43` | `_here.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/world_card.gd:50` | `_arrow.add_theme_font_size_override("font_size", 30)` |
| `game/scripts/ui/world_card.gd:58` | `_hint.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/world_card.gd:92` | `caption.add_theme_font_size_override("font_size", 16)` |
| `game/scripts/ui/world_pill.gd:21` | `add_theme_font_size_override("font_size", 22)` |
| `game/scripts/ui/world_selector.gd:44` | `title.add_theme_font_size_override("font_size", 26)` |
| `game/scenes/entities/npc_world/npc_world.gd:42` | `_badge.add_theme_font_size_override("font_size", 28)` |
| `game/scenes/levels/room/room.tscn:97` | `theme_override_font_sizes/font_size = 36` |
| `game/scenes/levels/room/room.tscn:104` | `theme_override_font_sizes/font_size = 36` |
| `game/scenes/main/main.tscn:202` | `theme_override_font_sizes/font_size = 20` |
| `game/scenes/ui/tasks_screen/tasks_screen.gd:60` | `button.add_theme_font_size_override("font_size", 16)` |
