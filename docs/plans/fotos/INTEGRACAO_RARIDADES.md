# Instruções do Vitor: integrar as ilustrações por raridade (06/11/2026)

Guardadas a pedido do Vitor ("guarda essas instruções que vou te explicar o que fazer com elas").
AINDA NÃO EXECUTAR: aguardar a explicação dele sobre como usar.

---

Você vai integrar as ilustrações por raridade no álbum do Tiro Adventure.

Projeto: C:\Users\Vitor\Documents\ClaudeGame
Leia AGENTS.md antes de trabalhar e preserve as alterações locais de outros agentes.

ONDE ESTÁ A PRODUÇÃO

Pasta principal:
tools/art/album_rarities/

Leia:
- README.md — processo, organização e recuperação.
- catalog.json — catálogo mestre e estado atual de todas as fotos.
- gallery.html — comparação visual dos resultados.

Cada foto fica em:
photos/<section>/<photo_id>/

Dentro há:
- photo.json — ficha da foto e suas associações.
- common.png — Comum.
- shiny.png — Brilhante.
- rare.png — Rara.
- holographic.png — Holográfica.
- prompts/ — prompts usados na geração.

COMO CORRELACIONAR COM O JOGO

Use sempre o campo `id` da foto como chave, igual ao ID em game/data/album.json. Não faça associação pelo título nem pela ordem dos arquivos.

O catálogo registra:
- id e title;
- section e section_name: seção do álbum;
- phase: fase artística representada;
- game_scene: cenário;
- trigger: evento e condições de obtenção;
- source_definition: referência ao registro do jogo;
- base_image: ilustração atualmente instalada;
- original_photo_definition: definição do jogo na criação do catálogo;
- variants: os quatro arquivos por raridade.

Consulte também o album.json atual: o catálogo guarda uma fotografia dos dados e outras alterações podem ter ocorrido desde sua criação.

COMO PEGAR CADA RARIDADE

Para um photo_id:
1. Localize a foto em catalog.photos pelo `id`.
2. Acesse variants[rarity].
3. Leia o arquivo indicado em `path`, relativo à raiz do repositório.

Chaves:
common → Comum
shiny → Brilhante
rare → Rara
holographic → Holográfica

Não derive a raridade pelo nome exibido nem pela posição em um array. Confira como o motor atual representa os níveis e faça o mapeamento explícito.

Cada variante também tem `integration_target`, um destino PROPOSTO em res:// para a instalação futura. Esse campo não significa que o arquivo já esteja instalado. A origem real é `path`.

ESTADO DA PRODUÇÃO

Na entrega do primeiro lote:
- 54 fotos previstas;
- quatro arquivos por foto: Comum + três variações;
- 11 fotos completas / 44 arquivos;
- 43 fotos ainda pendentes / 172 arquivos.

Leia o catálogo para obter o estado atualizado. Algumas pastas têm ficha e prompts, mas ainda não têm PNG.

Estados:
pending: não gerada.
generating: tentativa em andamento ou que precisa de recuperação.
generated: arquivo salvo, aguardando revisão visual.
reviewed: arquivo conferido visualmente.

Integre apenas arquivos existentes e revisados. `reviewed` é revisão técnica visual, não uma aprovação individual expressa do Vitor.

As séries antigas em tools/art/album_rarity_tests/ são histórico de experimentos. Use os arquivos selecionados no catálogo canônico album_rarities, para não misturar versões de brilho ou direções descartadas.

COMPORTAMENTO ESPERADO

A imagem deve acompanhar a raridade escolhida para EXIBIÇÃO da foto. O sistema atual pode distinguir a melhor raridade conquistada da variante que o jogador selecionou; verifique isso antes de implementar.

Se a variante pedida ainda não estiver produzida, mantenha como fallback a ilustração atual da própria foto. Não mostre a imagem de outra foto nem altere sua raridade salva.

Preserve:
- IDs, condições e eventos das fotos;
- sorteio e probabilidades;
- progresso, coleção de variantes e seleção do jogador;
- fase e identidade representadas na arte.

A produção destas imagens não instalou essas variantes no jogo. A integração precisa contemplar todos os locais que exibem a foto: álbum, detalhe, revelação/prêmio e fotos em destaque na Casa/home, conforme o código atual.

VALIDAÇÃO

O gerenciador de produção está em:
tools/album_rarity_pipeline.py

Para conferir o catálogo:
& C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe tools/album_rarity_pipeline.py check

Ele verifica IDs, bases, prompts, PNGs, dimensões, hashes e arquivos duplicados. Não gera nem instala imagens.

Após integrar, valide a seleção das quatro versões, o fallback de uma foto pendente e os diferentes lugares de exibição. Preserve a suavização das ilustrações e configure a importação adequadamente para celular.

Se testar no navegador local, refaça o export Web: alterar os PNGs ou o código-fonte não atualiza automaticamente o PCK já exportado.

Atualize docs/ROADMAP.md com a integração e suas pendências. Não publique nem faça push sem pedido do Vitor.

---

## Notas do Claude (contexto)
- Motor atual (etapa 1): níveis 1 Comum, 2 Brilhante, 3 Rara, 4 Holográfica; `GameState.photo_shown_rarity(id)`
  (variante escolhida para exibir; `shown` 0 = a melhor), `photo_rarity(id)` = melhor conquistada,
  `photo_variants(id)` = coleção. Mapeamento explícito: common→1, shiny→2, rare→3, holographic→4.
- A etapa 2 do plano (molduras procedurais + brilho/holográfico em shader) foi iniciada antes destas instruções e
  parou no limite de uso; com arte própria por raridade, ela precisa ser revista (ex.: só moldura/selo leve por
  cima, sem shader que brigue com a arte).
