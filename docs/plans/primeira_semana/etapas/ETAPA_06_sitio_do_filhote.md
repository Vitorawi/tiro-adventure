# E06. Sítio do filhote

Referências: README (E06 e seção 8), REGRAS (D11–D13 e seção 5), documento da semana, canvases e exportação Figma existente.

## Arquivos

- game/autoload/game_state.gd, game/data/config.json, crops.json, progression.json e dados da pesca: calendário, produção, compras e montinhos.
- tools/build_farm_figma.py e game/data/rooms/farm.json: mapa, lotes e navegação.
- Controladores de sala, banca e bandejas: abertura, pistas, montagem e produção em madeira ilustrada.
- game/tests/farm_week_test.gd, capturas da etapa e tools/test_areas.json.

## Passo a passo

1. Conectar dia e fase ao Sítio, aos requisitos e aos montinhos.
2. Configurar os canteiros, kits, galinheiro e tempos iniciais. Usar as transações e filas existentes.
3. Ligar abertura da lagoa e iscas diárias; ativar macieira e bananeira no dia 4.
4. Regenerar o mapa com os lotes futuros, o tapete e a plateia provisórios. Conferir a região andável.
5. Validar entradas por toque, abrir capturas nas três resoluções e registrar os provisórios.

## Testes e pronto

farm_week_test cobre dias 1 a 4, compras únicas, custos, contagem e persistência, três iscas por dia, produção e navegação. Rodar tools/test.ps1 -Level etapa com as áreas afetadas. Conferir as cinco telas em 360×780, 390×844 e 412×915. Pronto quando as áreas abrem no dia certo, o Tiro circula e farm_week_test passa.
## Implementação

| Dia | Abertura |
|---|---|
| 1 | Sítio, banca, dois canteiros livres, dois de 20 moedas cada e o primeiro montinho após 20 s |
| 2 | Kit do galinheiro por 60 moedas com duas galinhas e o canteiro de milho. Kit da caminha por 40 moedas e tapete no lote da queijaria |
| 3 | Lagoa pelo píer existente, vara de bambu e três minhocas grátis por dia enquanto o Tiro estiver na primeira semana de crescimento |
| 4 | Pomar grátis. Macieira e bananeira já prontas na abertura e com recargas independentes de duas horas |
| 6 | Vovó e Laís aparecem como plateia no lote do treino |
| 7 | Kit do mordedor por 50 moedas, com entrega pelo painel Para crescer |

- `GameState` usa o relógio da semana nas áreas e nos tempos. Batata 120 s, abóbora 360 s e milho 180 s nos dias 1–2. O primeiro lote de ovos nesses dias leva 120 s. Durante a primeira semana de crescimento, as duas galinhas comem dois milhos e produzem dois ovos por lote de 30 min.
- `progression.json → shop_items` descreve os kits que constroem ou entregam o item no pagamento. A folha da montagem leva ao local. O atalho DEV usa os mesmos efeitos do kit. A instalação da caminha e a compra do mordedor convivem com as origens das missões antigas até a E12.
- `WeekState.bait_day` e `orchard_ready` guardam a última entrega de iscas e a recarga de cada árvore. `SAVE_VERSION` 25 zera saves anteriores.
- `tools/build_farm_figma.py` gera o mapa. O canteiro 8 recebe o milho, a placa e as cercas usam as peças ilustradas existentes, e o tapete/plateia cedem o lote quando a queijaria for construída.
- Os preços seguem a tabela provisória da semana. Sementes continuam como ações de plantio existentes; a banca já vende aveia e pacotes de isca. O roteiro de recompensas da História entra na E12, a calibração na E15.

## Referências consultadas

- Leitura salva do conector Claude Docs do projeto `b45e1b2e-da97-4e57-af6f-b9e8a342ad66`, tabelas **O sítio do filhote** e **Comprar e vender**.
- Cópias locais da leitura do Artifact, com as pranchas Banca e Formatos. Para o mapa, montagem da seção 8 e camadas Figma previamente exportadas em `tools/art/sitio_vovo/figma/`.

## Validação

- `farm_week_test` PASS em 28,8 s no reteste final. Exercita o calendário, compras pela banca, lote de ovos, colheita por árvore, repetição e recarga do save em 360×780 com `root.push_input`.
- `py -X utf8 -I tools/build_farm_figma.py --debug` encontrou caminhos até os pontos andáveis designados. `farm_week_test` e `world_pin_test` cobriram caminhos e alvos do mapa em execução.
- `tools/test.ps1 -Level etapa -ChangeList build/e06_files.txt -Areas farm,fishing,shops,stations,world,finds,saves,week -Tests keys_test,growth_ui_test -Jobs 4 -KeepGoing`: 62 testes. Resultado consolidado com reexecuções: 56 PASS. Históricos restantes: `tray_test` (estufa), `station_tray_test`, `world_view_test` (enquadramento da Casa), `world_selector_test`, `item_sources_test` e `tasks_test`. A rodada final de sete testes focados passou em 70 s.
- Capturas abertas em 360×780, 390×844 e 412×915. Arquivos em `build/screenshots/e06_farm/` (mapa, banca, montagem, galinheiro, pomar e Para crescer com a origem do mordedor).
