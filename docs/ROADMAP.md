# Roadmap

## Estado atual (passagem de bastão entre agentes)
> Atualize esta seção ao terminar cada tarefa: é por aqui que Claude Code e Codex continuam o trabalho
> um do outro. Última atualização: **12/10/2026, Claude Code**.

**Simplificar — Fases 1 e 2 de 5 concluídas (Claude Code, 12/10/2026).**
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
  (`settings.skills_from_chapter`). Construções não exigem nível. Passos "suba o atributo" viraram ações
  contadas a partir do início do passo (`"fresh": true` + `ProgressionState.step`). Save v6 soma
  Passeio+Mineração+Construção em Aventura e remove Vínculo. Painel de Atributos em ícones.
  Dados migrados com uma ferramenta única (não versionada); a formatação dos JSON foi mantida.
- Próximo: **Fase 3** (3 mundos, até 4 lugares cada, Trilha vira portão na Vila, construir no próprio lugar). Sem push.

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
