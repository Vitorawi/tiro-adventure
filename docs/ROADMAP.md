# Roadmap

## Estado atual (passagem de bastão entre agentes)
> Atualize esta seção ao terminar cada tarefa: é por aqui que Claude Code e Codex continuam o trabalho
> um do outro. Última atualização: **13/10/2026, Codex**.

**Ferramentas por categoria e exigência clara (Codex, 13/10/2026).**
- Aba Ferramentas com filtros Madeira/Mineração/Fibras, definidos em `nature_tool_groups`.
  Cada filtro mostra apenas seu kit; Mineração reúne as três picaretas, mesmo vindo de Pedras.
- Ícones dos materiais atendidos, próxima ferramenta destacada e custos existentes.
  Na coleta: ícone + Usa/Precisa/À mão; requisito deriva da rota, não da última ferramenta
  comprada. Próxima melhoria indicada e atalho Ferramentas abre o grupo correspondente.
- Nature test ampliado com troca real de filtros, compra após trocar abas, material sem
  ferramenta e indicação da ferramenta correta após comprar todos os níveis.
- Suíte completa verde, capturas 360×780 conferidas e export Web prod/dev sem erros.
  Capturas `nature_tools_mining.png`, `nature_tools_buy.png`, `nature_collect.png` em build/screenshots.
- Publicação prod/dev autorizada por Vitor em 13/10/2026, via main. Próximo: acompanhar
  a clareza dos kits e dos requisitos de coleta no celular.

**Natureza integrada, ferramentas e seleção de mundos (Codex, 13/10/2026).**
- Substituído o mapa de pontos separados por paisagem PixelLab contínua 512×384: floresta,
  riacho com ponte, trilha e gruta. Obstáculos reais bloqueiam água, árvores e penhascos.
- NatureUi reúne todos os materiais e ferramentas num painel; botão Coletar no cabeçalho,
  cenário inteiro tocável. `nature_resources` prioriza melhor rota conforme ferramentas;
  madeira/pedra/cobre/cristais/fibras não exigem trocar de lugar para coletar.
- Machado → reforçado (madeira dura); picareta → reforçada → precisão; foice. Ferramentas
  são compras normais. Madeira dura vira tábuas na bancada e serve à picareta de precisão.
  Rotas existentes preservadas, melhorias opcionais; save/produção em curso mantêm resultados.
- Mundos: quatro cartões horizontais com miniatura inteira, nome curto, função, bloqueio/
  status; cartão inteiro entra com um toque. Título Para onde vamos?, volta por Mundos.
- Testes de Natureza cobrem compra via UI, seleção automática, rendimento, save e melhoria
  durante lote; campanha simulada chegou a 33 missões e 21 aquisições em 130 ciclos.
  Worlds test cobre bloqueio/entrada por cartão e atalho de coleta. Capturas 360×780.
- Suíte completa verde e export Web prod/dev sem erros. Capturas finais:
  `worlds_{locked,select}.png`, `nature_{open,collect,collect_ready,tools_buy}.png` em
  build/screenshots. Caminhos de ambos os lados da ponte e até a gruta também validados.
- Publicação prod/dev autorizada por Vitor em 13/10/2026, via main, incluindo Natureza,
  ferramentas, seleção de mundos e variedades dos animais. Próximo: acompanhar no celular.

**Natureza como novo mundo — protótipo substituído pela versão acima (Codex, 13/10/2026).**
- Quarto mundo, mapa 1208×683 com árvores/troncos, riacho/ponte, prado de fibras, gruta
  de pedra/cobre e gruta de cristais. Portão da Vila viaja para Natureza; Guia mudou para lá.
- Abre no capítulo 3. Bosque disponível ao entrar; riacho = Aventura 2; pedra = picareta;
  cristais = picareta + Aventura 3; prado = Aventura 4. Mesmas rotas/ids/tempos/recompensas.
- `regions.requirements` abre cercas por progressão e recalcula a navegação. Etiquetas
  alternam entre requisito e nome; objetos de exploração mostram timer/Recolher no mapa.
- Destinos de missão/manual/mochila resolvem cada zona. Saves e rotas em curso preservados.
- `nature_test` valida viagem pelo portão, evolução real abrindo riacho, picareta/grutas,
  áreas bloqueadas/abertas, coleta única, indicadores e navegação. Capturas 360×780 em
  `build/screenshots/nature_{locked,open,ready,crystals}.png`.
- Suíte completa verde (incluindo Natureza e animais); export Web prod/dev concluído sem
  erros. Capturas conferidas em 360×780, com requisitos legíveis e sem etiquetas sobrepostas.
- Protótipo substituído pela versão integrada acima, incluída na publicação autorizada.

**Compra individual e variedades dos animais (Codex, 13/10/2026).**
- Galinheiro/curral novos começam vazios. Loja dentro do abrigo: três variedades por espécie,
  preço individual, quantidade possuída e três vagas por abrigo; cada compra aparece no mapa.
- Galinhas branca/ruiva/preta; vacas pintadinha/caramelo/malhada. Variedade muda o visual;
  cada animal consome o alimento da receita e produz duas unidades. Quantidade do lote é
  fixada ao alimentar, inclusive offline; comprar outro animal não aumenta lote em curso.
- Save v7 mantém os dois animais antes incluídos em cada abrigo já adquirido; saves novos
  guardam quantidades por variedade. Slots vazios não bloqueiam caminhos nem recebem toque.
- Suíte completa passou, incluindo campanha com compras reais, lotação, moedas,
  save/migração e caminhos com as seis variedades. Loja/mapa conferidos em 360×780.
- Export Web prod/dev concluído sem erros; capturas em `build/screenshots/animals_shop.png`
  e `animals_farm_overview.png`. O botão da loja também é testado acionando sua compra.
- Incluído na publicação autorizada em 13/10/2026, junto de Natureza e seleção de mundos.

**Sítio dos animais e processamento (Codex, 13/10/2026).**
- Quarta área no sítio (1208×683), cercada até comprar o galinheiro. Corredor independente
  das expansões de estufa/pomar; duas galinhas e duas vacas, com arte PixelLab e movimento leve.
- Cadeias: milho → ovos; trigo → leite → queijo; trigo → farinha. Galinheiro/curral = um lote
  por vez; moinho/queijaria = duas posições na fila. Alimentar, esperar, recolher; indicador
  de tempo/coleta no mapa. Reutiliza StationState/save v6, sem duplicação de alimentação/coleta.
- Abre após sítio próprio/capítulo ≥3; lugar Animais e lugar Produção (bancada+moinho+queijaria).
  Manual, mochila, venda, ajuda dos ingredientes e navegação já reconhecem os novos recursos.
- Capítulo 9 com cinco passos, preservando a campanha anterior; duas diárias, uma semanal e
  encomenda Café da manhã. Campanha simulada passou com 328 ciclos, 16 compras e 33 missões.
- Novo `animals_test` cobre requisitos, alimentação, lotação, coleta única, offline/save antigo,
  processamento e corredor. Capturas `animals_{farm_overview,feed,dairy,manual_milk}.png`.
- Suíte completa verde; export Web prod/dev concluído sem erros. Toque direto no moinho
  também validado com bancada ainda não comprada; destinos próprios no manual/missões.
- Publicação em prod/dev autorizada por Vitor em 13/10/2026, junto das melhorias de mundo
  abaixo, via push na main. Próximo: acompanhar balanceamento e experiência no celular.

**Tiro reagindo, construções visíveis e sítio ampliado (Codex, 13/10/2026).**
- Sítio 1208×539: duas laterais cercadas e sombreadas, abertas pelas compras já existentes
  de estufa/pomar. Centro anterior preservado, mesmos nove canteiros/índices de save; câmera
  começa no centro e pode arrastar/diminuir zoom. Ir enquadra destinos fora da tela.
- Arte PixelLab: bancada, estufa, pomar, forno, banca extra e estação de costura aparecem após
  comprar; caminhos contornam suas bases. `regions` bloqueia chão antes da compra e retira
  a cerca ao abrir. Requisitos/custos existentes preservados, sem migração de save.
- Colher, recolher e comprar emitem `world_activity`. Tiro vai ao objeto, cheira em colheita/
  produção pronta e comemora com pulo/coração. Reações não acordam o Tiro nem rodam em mapa
  oculto; o movimento se interrompe quando muda a navegação ou chega outra ação.
- Novo `world_life_test` cobre ações reais, construções em save avançado, áreas fechadas/abertas,
  reação a produção pronta, sono e caminhos completos após compras. Capturas 360×780 em
  `build/screenshots/{farm_expansion_start,farm_expansion_built,farm_orchard_focus,house_buildings,village_buildings}.png`.
- Suíte completa verde e export Web prod/dev concluído sem erros. Reação de colheita conferida
  em `build/screenshots/tiro_harvest_reaction.png`; o teste aguarda a chegada/animação do Tiro.
- Incluído na publicação autorizada em 13/10/2026. Próximo: acompanhar visual/reações no celular.

**Manual visual na tela principal (Codex, 13/10/2026).**
- Botão Manual acima do Tiro, disponível desde o começo. Catálogo Recursos/Estações em
  `GameManual`, gerado dos dados existentes: itens por categoria, origens, ingredientes,
  quantidades, tempos, usos e local mundo › lugar. Toque em ingrediente abre sua origem.
- Ir até lá para os lugares; Ver compra para estações não compradas; mundos/lugares fechados
  continuam bloqueados com motivo. Catálogo completo é consulta, sem mudar progresso/save.
- Atalhos acima do Tiro usam fluxo para caber Manual + Atributos + Coleção no celular.
- Suíte completa incluindo novo `manual_test`: consulta sem alterações, todos os itens,
  bloqueios, ingrediente tocável e navegação até a bancada. Capturas 360×780 `manual_*` conferidas.
- Publicação autorizada pelo Vitor em 13/10/2026 pela `main` (prod e dev), após suíte completa verde.
  Próximo: revisar no celular a consulta de recursos e os atalhos do manual.

**Instruções breves nas missões (Codex, 13/10/2026).**
- Pedido do Vitor: só ícones deixaram a ação difícil de entender. `goal_row` agora mostra
  `goals[].label` acima da barra, tanto na História quanto nos cartões dos personagens.
- Primeira colheita explica plantar e esperar crescer. Todas as diárias/semanais têm
  `description` com ação e quantidade, exibida na largura do cartão, sem exigir tocar em "?".
- Teste de Missões passou; capturas 360×780 `tasks_start` e `tasks_middle` conferidas.
  Publicação autorizada pelo Vitor em 13/10/2026 pela `main` (prod e dev); suíte completa
  rodada novamente antes do envio. Próximo: revisar a clareza das frases jogando no celular.

**Tiro andando no Sítio e na Vila (Codex, 13/10/2026).**
- Ambos têm `dog_start`; Vila ganhou `floor`. Canteiros têm `footprint`; `obstacles` bloqueia
  casas, feira, árvores/pomar, caixas e banco desenhados no fundo. Margem de navegação de 8 px
  nos mapas externos; grade da casa também confere cantos de células (4 px).
- Proporção ajustada após pedido do Vitor: `dog_scale: 0.5` no Sítio/Vila; Casa mantém 1.
  Sprite, sombra e área de toque acompanham a escala; patas continuam ancoradas no chão.
- Pontos de tigela/sofá são opcionais: fora da casa o Tiro dorme no local e não tenta ir à origem.
  Nasce no chão livre, sorteia apenas destinos alcançáveis e não anda direto até um alvo sem rota.
- Suíte completa verde, incluindo novo `navigation_test` (100 caminhos por mapa, limites,
  obstáculos, sono e ausência de rota). Capturas 360×780 conferidas em
  `build/screenshots/tiro_{farm,village}{,_walking}.png`.
- Publicação autorizada pelo Vitor em 13/10/2026: enviar pela `main` para o deploy automático
  de prod e dev no GitHub Pages. Suíte completa rodada novamente antes do envio.
- Próximo: conferir no aparelho o passeio e a proporção do Tiro; ajustar as áreas conforme
  novas artes/objetos entrarem nos mapas.

**Simplificar — todas as 5 fases concluídas (Claude Code, 13/10/2026). Sem push: esperando o Vitor aprovar.**
- O Vitor achou o jogo confuso ("bombardeamento de informação"). Plano aprovado em `docs/plans/SIMPLIFICAR.md`:
  missões em 3 tipos (História, Diárias, Semanais), 3 mundos (a Trilha vira portão na Vila), 4 atributos,
  personagens que aparecem aos poucos, revelação gradual com "Novo!" e menos texto em todo canto.
  Regra que vale sempre: **ícone + número em vez de frase; simplificar**.
- **Fase 1 feita:** aba Tarefas → **Missões** com 3 blocos. História = cartão visual (rosto, ícone + `0/6`,
  lugar em ícones, ingredientes que faltam em chips tocáveis, recompensa em chips, **Ir** + **?**).
  Diárias (3, a partir do cap. 2) e Semanais (2, a partir do cap. 3) em `data/routines.json`, estado em
  `ProgressionState.routines`. Secundárias removidas (roupas → semanais). Atributos/Coleção → aba Tiro.
  "Como fazer" do Codex (`task_help.gd`) refeito em ícones; os botões de ajuda espalhados viraram "?" e chips.
  Novas peças: `UiKit.tap_chip/square_button/short_label/fill_label`, `ProgressionUi.goal_row/reward_chips/item_chip`,
  `Places.target_view`, tema `ChipButton`. DEV: "Recomeçar diárias e semanais".
- Testes verdes (farm, progression, DEV dev/prod, tasks com diárias/semanais, content). Capturas:
  `build/screenshots/tasks_{start,middle,story,help,end,celebration}.png`.
- **Fase 2 feita:** 4 atributos (Horta, Cozinha, Comércio, Aventura), escondidos até o capítulo 3
  (`features.skills`). Construções não exigem nível. Passos "suba o atributo" viraram ações
  contadas a partir do início do passo (`"fresh": true` + `ProgressionState.step`). Save v6 soma
  Passeio+Mineração+Construção em Aventura e remove Vínculo. Painel de Atributos em ícones.
  Dados migrados com uma ferramenta única (não versionada); a formatação dos JSON foi mantida.
- **Fase 3 feita:** 3 mundos (Casa, Sítio, Vila), no máximo 4 lugares visíveis cada. Casa: Tigela, Cozinha
  (fogão + forno + fila extra), Geladeira, porta. Vila: Feira (abas Vender/Encomendas + banca), Ateliê,
  Portão da trilha (passeios + mina + picareta; capítulo 3). Sem menus "Construir em…": cada construção é
  comprada no próprio lugar (`upgrade`/`upgrades` em `worlds.json`; `Database.place_of_upgrade`).
  Mapa e "Lugares" em ícones. `rooms/trail.json` removido (arte guardada). `content_test` garante 3 mundos e ≤4 lugares.
- **Fase 4 feita:** revelar aos poucos. `progression.json → features` (Mochila após a 1ª colheita, diárias cap. 2,
  semanais e atributos cap. 3); NPCs com `requirements` (Feirante 2, Guia 3, Laís 4). Tela "Novo!" (com a
  comemoração de capítulo) lista o que abriu com ícone + Ir, uma vez só (`ProgressionState.seen`). O "Ir" mostra
  uma seta sobre o objeto da sala e abre o painel 0,8 s depois. Detalhes em `docs/WORLDS.md`.
- **Fase 5 feita:** menos texto no resto. Mochila em 4 colunas (ícone + `x12`); detalhe do item com preço,
  "De onde vem" e "Usado em" em chips que levam ao lugar; sementes compactas (bloqueada = "?"); canteiros em
  grade; compra de terreno em ícones; coleção em grade (conquistado colorido, resto "?"); personagem = rosto +
  fala curta + atalhos (falas encurtadas em `npcs.json`).
- Capturas: `build/screenshots/` → `tasks_*`, `go_pointer`, `ui_*` (mapa, vila, feira, portão, cozinha, mochila,
  item, NPC), `sheet_seeds`, `farm_*`.
- **Próximos passos sugeridos:** Vitor jogar a versão dev e aprovar → publicar (push na main); testar o toque
  real (`tools/touch_test.ps1`); ícones próprios (PixelLab) para encomenda, passeio e coleção (hoje reaproveitam
  ícones de itens); balancear diárias/semanais com jogo real.

**Tarefas v2 — todas as fases (1–6) concluídas (Codex, 12/10/2026).**
- 28 passos principais em 8 capítulos e 9 secundárias; recompensas por capítulo, destinos
  com Ir, painel História, recomendações por progresso e ajuda para evoluir atributos.
- Comemoração modal, faixa/toast com próximo passo, guia inicial e badge sem duplicação.
- Save v5 migra capítulos cujas construções já eram adquiridas sem pagar recompensas.
  Vila abre após first_harvest; Trilha no capítulo 3. Ferramentas DEV seguem a sequência.
- Todos os testes verdes: farm, progression (296 ciclos, 37 missões, 12 construções),
  tasks, content, DEV e DEV --prod. Export Web prod/dev local e toque real em Chrome
  headless confirmaram Tarefas → Ir → Tigela do Tiro, sem erros no console.
- Capturas 360×780: build/screenshots/tasks_{start,middle,end,story,side,celebration}.png.
  Símbolos da história têm fonte bitmap própria de apoio (a Web não tem fallback do Windows).
- Ajustes ao esboço para evitar produção antes da estação: oficina/tecidos são secundárias;
  capítulo 8 prepara fibras e Construção antes do ateliê. Nenhum trecho ficou pela metade.
- Seis commits locais, um por fase. **Sem push/publicação.** Próximo: Vitor revisar as capturas;
  só publicar quando solicitado. Depois, balanceamento em jogo real e vestir a coleção.

**Rodada 2 (12/10/2026, Claude Code): navegação intuitiva + mini mundos**
- Pedido do Vitor: "tá difícil achar rotas, vender, missões; deixar os menus intuitivos" e
  "vão ter vários mini mundinhos, cada um com seus NPCs".
- Abas novas: **Tiro · Mapa · Tarefas · Mochila** (a aba Jornada com 8 sub-botões foi removida).
  Cada função mora num lugar de um mundo; Tarefas mostra próximo passo, prontos agora e missões com "Ir".
- Mundos orientados a dados (`data/worlds.json`): Casa, Sítio, **Vila** (Feirante, Laís: vender,
  encomendas, ateliê, lojas) e **Trilha** (Guia: passeios, mina). Vila e Trilha ganharam cena própria
  (PixelLab) com zonas tocáveis e etiquetas. Receita para criar mundos em `docs/WORLDS.md`.
- Mochila com detalhe do item (como conseguir, onde usar, vender). Retratos provisórios dos 4 NPCs.
- Testes passando; teste de toque no Chrome confirmou Tarefas → Ir → Trilha → Guia.

**Próximos passos (rodada 2)**
1. Trocar os retratos provisórios pelas fotos do Vitor (`npcs.json → portrait`). Feito: **Laís** (artesã da Vila).
   Receita em `docs/ART_PIPELINE.md`.
2. NPCs pequenos dentro das cenas (sprite no mundo, além do botão no cabeçalho).
3. Novos mundos seguindo `docs/WORLDS.md` (ex.: parque, praia, clínica).
4. Tutorial curto inicial concluído em Tarefas v2 (guia no Tiro e aba pulsando).

**Rodada 1 — feito**
- Progressão completa (**Jornada**), criada pelo Codex: casa quase vazia no começo, canteiro emprestado,
  7 atributos, 12 construções, 7 rotas, feira (venda + 6 encomendas), 8 capítulos, 15 missões de 4 NPCs,
  6 itens de coleção. Save v4 com migração. Ver `docs/PROGRESSION.md`.
- Revisão e organização (Claude Code):
  - dados da progressão saíram de 9 variáveis soltas no `GameState` para `ProgressionState`
    (`scripts/state/`, acesso por `GameState.progress`), seguindo o padrão de `DogState`/`Inventory`;
  - o estado não depende mais da UI (`TimeText` em vez de `SheetBuilder.format_time`);
  - bugs corrigidos: rota removida do JSON travava o jogador para sempre; receita removida travava a coleta;
    texto do capítulo final fixo no código (agora `final_chapter` no JSON);
  - `house.json` voltou ao formato compacto (o Codex tinha expandido todas as coordenadas);
  - 14 ícones de itens novos + ícone da aba Jornada (PixelLab); ícones próprios em atributos,
    construções, rotas e chips "tem/precisa" com ícone na feira e nas construções;
  - abas inferiores com ícone em cima e texto embaixo (com 4 abas, "Jornada" não cabia).
- **Versão dev** (pedido do Vitor, que ficou sem resposta na conversa do Codex): `/dev/` com save
  separado, selo DEV e Ferramentas DEV (moedas, itens, atributos, pular capítulo, liberar tudo, terminar
  timers, avançar o tempo, copiar o save real). Deploy gera prod + dev. Ver `docs/DEPLOY.md`.
- Testes: `farm_test`, `progression_test` (campanha simulada) e `dev_tools_test` (dev e `--prod`) passando;
  teste de toque no Chrome headless confirmou prod sem selo e o painel DEV funcionando em `/dev/`.

**Próximos passos sugeridos**
1. Vestir as roupas da Coleção no Tiro (camadas sobre o sprite grande; `DogState.outfit` já existe).
2. Retratos dos NPCs a partir das fotos que o Vitor vai mandar (`npcs.json` → `portrait`).
3. NPCs pequenos no mundo (Bloblo no sítio, Tutor em casa) que abrem as missões ao toque.
4. Móveis da bancada, forno e ateliê na casa ou no sítio (hoje só pela Jornada → Produção).
5. Sprite próprio da planta de ervas (usa o broto como planta madura).
6. Balancear com jogo real (o ritmo hoje só é medido pela campanha simulada; ela termina com ~16 mil
   moedas, sinal de que vender o excedente rende demais no fim do jogo).
7. Telas do Hoje/Missões mais visuais (o painel ainda é bastante texto).

## Fase 0 — Fundação
- [x] Estrutura de pastas e documentação
- [x] Projeto Godot 4.7.2 (Compatibility, pixel art, celular em pé 360x780)
- [x] Autoloads `Events`, `GameState`, `SaveManager`
- [x] Preset Web PWA single-thread + scripts de export/servidor local
- [x] Workflow de deploy no GitHub Pages
- [x] Repositório no GitHub + primeiro deploy
- [ ] Testar instalação PWA e save no iPhone e no Android

## Fase 1 — Design
- [x] Ideia do jogo registrada (`GAME_DESIGN.md`)
- [ ] Receber referências visuais (`docs/references/`)
- [ ] Responder perguntas em aberto do design
- [ ] Padrões de arte (tamanho de tile/personagem, paleta)

## Fase 2 — Iteração 1 (ver `GAME_DESIGN.md`)
- [x] Base: toque/arrasto de câmera, `Hotspot`, tempo real offline, save automático
- [x] Tela do Pet: Tiro detalhado + 4 necessidades + comer/brincar/banho/dormir/carinho
- [x] Casa: geladeira, fogão (fila), tigela, sofá, brinquedos; Tiro autônomo
- [x] Inventário + receitas no fogão (dados em JSON) + XP/nível
- [x] Sprites PixelLab: Tiro pet (128px) e Tiro mundo (4 direções + andar)
- [x] Casa montada no PixelLab: sala vazia + móveis separados (geladeira, fogão, tigela, sofá)
- [x] Colisão com móveis (grade de navegação), profundidade (Y-sort), toque por pixel, sombra do Tiro
- [x] Animações do Tiro no mundo: andar, parado, sentar, latir, dormir, comer
- [ ] Mais móveis/decoração (caminha, brinquedos, TV, mesa) — por enquanto casa enxuta
- [ ] Barra de segurança no topo para notch do iPhone

## Iteração 2
- [x] Horta: Sítio da Bloblo (aba Sítio + porta da casa), cenoura/batata/abóbora (`crops.json`)
- [x] Progressão do sítio: canteiro emprestado, escritura, expansão até 9 em posições fixas, moedas por colheita, indicadores de crescimento e painel Meu sítio
- [x] Jornada: atributos, construções, rotas, feira (venda + encomendas), capítulos, missões de NPCs, coleção (`docs/PROGRESSION.md`)
- [x] Navegação intuitiva: abas Tiro/Mapa/Tarefas/Mochila, mundos em `worlds.json` (Casa, Sítio, Vila, Trilha) com NPCs (`docs/WORLDS.md`)
- [x] Versão dev em `/dev/` com save separado e Ferramentas DEV
- [ ] Bloblo como personagem no mundo (sprite + retrato); Tiro passeando no sítio
- [ ] Tutor dentro de casa (sprite pequeno + retrato detalhado + diálogo) com missões

## Iteração 3
- [ ] Customização (Ateliê): vestir as roupas da Coleção (camadas sobre o Tiro detalhado)
- [ ] Parque: passeio, truques, minigames

## Backlog / ideias técnicas
- [ ] `AudioManager` (música/sfx; destravar áudio no primeiro toque)
- [ ] Exportar/importar save como código (backup manual)
- [x] Aviso "nova versão disponível" no PWA
- [ ] Testes automatizados headless no CI
- [ ] `tools/pixel_tools.ps1` → `New-ContactSheet` falha ("Parâmetro inválido" ao criar o Bitmap)
