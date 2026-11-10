# Sítio da vovó Bloblo — ilha isométrica (Scenario)

Experimento de 10/11/2026 para refazer o Sítio como **diorama isométrico** no padrão do apartamento
(`game/assets/sprites/areas/house/apartment/room.webp`), usando o MCP do Scenario.
Substitui a ideia do mapa comprido de `../BRIEF.md` (o BRIEF antigo continua válido só para o quadrante 1).
Nada aqui está ligado ao jogo ainda.

## Decisão (Vitor, 10/11/2026)
`sitio_ilha_base.png` (2400×1712) foi **aceita como base** do Sítio. Estilo = referência "sítio cozy" enviada
pelo Vitor (diorama com borda de terra, muito detalhe); câmera = apartamento (isométrico 2:1).

## Arquivos
| Arquivo | O que é |
| --- | --- |
| `sitio_ilha_base.png` | Arte aceita, 2400×1712, fundo bege `#F5ECD7`, sem transparência. Asset Scenario `asset_KBeYddk3irrfMzVw9oV2J1Xk` |
| `ilha_blockout_limpo.png` / `ilha_blockout_etiquetas.png` | Blockout usado como layout (30×30 tiles, 80 px por tile) |
| `make_ilha_blockout.py` | Gera o blockout: `py -I make_ilha_blockout.py <pasta> <1 etiquetas \| 0 limpo> <saida.png>` (exige Pillow) |
| `make_quadrante1_v2.py` | Blockout do quadrante 1 do mapa comprido (caminho em L, 6 canteiros); caminhos absolutos |

## Como foi gerado
- Modelo `model_openai-gpt-image-2-5-sunburst`, `quality: high`, 2400×1712, 1 saída, **16 CU**.
- Referências, nesta ordem (assets do projeto Scenario `proj_xVyw9Z5BixZne3DZDLTU8Hhb`):
  1. `asset_qUxBTCztGbpGV3cwCabdhRFG` — blockout (layout);
  2. `asset_sbqBjXN9dcgHeAXQgcHKyiys` — referência de sítio do Vitor (estilo, detalhe, harmonia);
  3. `asset_xfHKPYxKYBRHoNkHEdPsTcdL` — apartamento (câmera isométrica 2:1).
- O prompt diz qual imagem manda em quê (1 posição, 2 acabamento, 3 câmera), lista cada elemento (casa enxaimel,
  silo, armazém, bancada, moinho, queijaria, galinheiro, curral, pomar, estufa, banca "Vender", portão, 9 canteiros
  vazios 3×3, lago com cachoeira/píer/barco) e exige: caminhos largos e retos nos dois eixos, nenhum prédio escondido,
  nada sobre canteiros ou caminhos, sem pessoas, só o texto "Vender", fundo bege liso.

## Decisões sobre o que é construído depois (Vitor, 10/11/2026)
- **Fundo = chão limpo** nos lotes fechados (sem plaquinha nem entulho): o jogo já escurece o lote, põe a cerca da
  divisa e o balão de compra com o preço (`RoomView._spawn_regions`).
- **Banca de venda aparece desde o começo**: fica no fundo, não é peça com requisito.
- Peças = recortes dos pixels desta arte (encaixe exato); fundo = esta arte com as peças apagadas e o chão refeito
  por inpaint, recomposto só dentro da máscara.
- Pendências: cerca da divisa hoje é `Line2D` em código (pode virar peça pintada); polígonos/portões das `regions`
  do `farm.json` precisam ser refeitos sobre esta ilha.

## Teste do fundo vazio: área do galinheiro (10/11/2026) — `teste_galinheiro/`
- Máscara (`mascara_galinheiro.png`, transparente = editar; asset `asset_Qmg2ecHbMNQGkupnfV8hoYN9`) cobre prédio, pátio
  cercado e galinhas. Edição: `model_openai-gpt-image-2-5-sunburst`, `quality: high`, 2400×1712, 1ª referência = a arte base,
  `mask` = a máscara. Resultado `asset_gPk5osh4HfFzvekWdjk2g9av`.
- **Deriva:** fora da máscara o modelo regrava a imagem inteira (diferença média ≈ 11/255; 13% dos pixels com diferença > 24).
  Por isso `fundo_sem_galinheiro.png` é recomposto: base fora da máscara, edição dentro, com borda suave de ~5 px.
- Resultado: galinheiro, cerca e galinhas somem; o chão fica contínuo e a quina do armazém que estava escondida é completada.
  O modelo acrescentou arbustos com flores no lote; se o lote deve ficar 100% limpo, pedir "no bushes" ou limpar à mão.
- Conclusão: o método (máscara + inpaint + recomposição local) serve para o fundo e para as outras áreas.

### Teste da peça: recolocar o galinheiro (10/11/2026)
- Entrada: recorte `(1460,540)-(1960,880)` da arte base, ampliado 2,56× (1280×864), asset `asset_3DJB5zC3ZwRdfq87mmajFSXx`.
- `model_openai-gpt-image-2-5-sunburst`, `background: transparent`, prompt "isole só o galinheiro com o pátio de terra e a cerca,
  sem galinhas, sem mais nada, sem redesenhar". Saída `asset_FA67ndvdckH77SHWUtwZFSUQ` → `peca_galinheiro*.png`.
- Resultado: alfa limpo, vaso e cesta mantidos, galinhas removidas. Reduzida a 500×340 e colocada em (1460,540) sobre
  `fundo_sem_galinheiro.png` cai quase no lugar original (`fundo_com_peca_de_volta.png`, `comparacao_*.png`).
- Ressalvas: o modelo **redesenha** a peça (cerca e telhado levemente diferentes do original, alguns px de deriva), então
  falta um passo de alinhamento (casamento de imagem pelo contorno) antes de virar sprite final; as galinhas são sprites
  por vaga (`hen_1..3`), gerados à parte.

## Fundo vazio em UMA passada (10/11/2026) — `sitio_fundo_vazio.png`
- Uma só máscara (`mascara_tudo_o_que_e_comprado.png`, asset `asset_1459F7MwoREz9HrtKicQMM3J`) cobre silo, armazém, moinho,
  queijaria, galinheiro, curral, pomar, estufa, bancada (puxadinho ao lado da casa) e os 9 canteiros. Casa, lago, banca "Vender",
  portão e cercas do lago ficam de fora.
- `model_openai-gpt-image-2-5-sunburst`, 2400×1712, `quality: high`, **16 CU** no total (contra ~16 CU por prédio no método
  uma-a-uma). Edição `asset_VHXCepyw1m9uoTu5xhf2WVCN`, recomposta só dentro da máscara (borda suave de ~5 px); deriva fora
  da máscara ≈ 7/255, por isso a recomposição continua obrigatória.
- Resultado: chão contínuo, caminhos largos ligados, lote central de grama onde ficavam os canteiros, fundo bege e borda
  de terra restaurados. Sobras pequenas a limpar: um pedaço de cerca à esquerda do lote central, um poste junto à casa, uma
  marca de terra perto de onde era o silo e um poste na borda direita.
- **Sobras limpas (10/11/2026):** uma passada curta com 4 máscaras pequenas (`mascara_limpeza_sobras.png`, asset
  `asset_tRj9uqnAoWFUWAQhKbyM91iR`) sobre o fundo (`asset_7DSCcKmd2UDE55ygVPbofz84`) removeu a cerca à esquerda do lote central, o
  poste junto à casa, a marca de terra e o poste da borda direita (resultado `asset_vKyxWzfNm4NVBaJreST35KCu`, 16 CU, recomposto
  só dentro das máscaras). `sitio_fundo_vazio.png` já é a versão limpa; `limpeza_sobras_antes_depois.png` mostra o antes e depois.
  Detalhe restante: a ponta esquerda de um trecho de caminho ficou com a borda suave, e há um pequeno talo escuro no arbusto da borda direita.
## Peças soltas em UMA passada (10/11/2026) — `pecas/`
- `model_openai-gpt-image-2-5-sunburst`, 2400×1712, `background: transparent`, 1 referência (a arte base), **16 CU**. Prompt: "mantenha SÓ
  estes 10 objetos (pomar, bancada, silo com sacos, armazém, moinho, queijaria, galinheiro sem galinhas, curral sem vacas,
  estufa, 9 canteiros vazios) e apague o resto". Saída `asset_13JgPR23Gk8WRvQmyG4Jjrt3` → `pecas/folha_bruta_do_modelo.png`.
- **O modelo reorganiza a folha:** os objetos saem ~1,25× maiores (escala uniforme ≈ 0,8 para voltar ao tamanho da ilha) e
  deslocados 50–250 px. `pecas/cortar_pecas.py` separa por componentes conexos, reduz por 0,8 e **acha a posição na arte base por
  casamento de imagem** (resultado em `pecas/posicoes.json`: `x,y,w,h,erro,escala`).
- Arquivos: `<peça>.png` (tamanho da ilha, para usar com `posicoes.json`) e `<peça>_hr.png` (1,25× maior, só para uso futuro).
  Peças: `silo`, `armazem`, `bancada`, `moinho`, `queijaria`, `galinheiro`, `curral`, `estufa`, `pomar`, `canteiro_livre`.
- **Canteiros:** os 9 são iguais; `canteiro_livre.png` é o modelo e `posicoes.json → canteiro_livre.posicoes` tem os 9 lugares achados
  na arte (a grade ficou um pouco irregular; no jogo use uma grade regular, a posição vem do `farm.json`).
- `pecas/recomposto_fundo_mais_pecas.png` = fundo vazio + todas as peças nos lugares (sem galinhas e vacas);
  `pecas/comparacao_original_x_recomposto.png` compara com a original.
- **Ajuste manual (Vitor pediu):** galinheiro e curral caíam em cima do caminho do fundo vazio (o modelo refez a rede de caminhos
  e os dois pátios saíram do tamanho dos originais). Deslocados no `posicoes.json`: galinheiro **+80,−40** e curral **−60,+30** px
  (campos `x`/`y` já atualizados; `x_casamento`/`y_casamento` guardam o valor do casamento e `ajuste_manual` o deslocamento).
  Só o telhado do celeiro do curral ainda sobrepõe o caminho que passa atrás dele (oclusão normal).
  **2º ajuste:** o galinheiro ficou colado na parede do armazém; desceu para (1604, 640) (pode ficar um pouco atrás do curral).
  Candidato mais à direita (1640, 650) foi descartado: colava na queijaria.
  **3º ajuste:** a frente do pátio encostava na ponta do telhado do curral; galinheiro **reduzido 12%** (escala 0.704 sobre o `_hr`,
  âncora no fundo/centro): `galinheiro.png` agora 289×220 em (1623, 640); o original em 0.8 ficou em `galinheiro_escala0.8_original.png`.
- Ressalvas: as peças são **redesenhadas** pelo modelo (pequenas diferenças de detalhe vs a arte base; a estufa e o pomar saíram um
  pouco maiores no recomposto); o erro de casamento é 35–52 nos objetos grandes (aparência diferente, não necessariamente
  desalinhamento) e 14–22 nos canteiros. Faltam: galinhas e vacas por vaga, canteiro bloqueado, portão aberto/fechado.
- Peças a recortar da arte base (lista original do plano; feitas acima exceto animais e estados) (uma passada com fundo transparente por grupo, ou uma folha só): silo+armazém, moinho,
  queijaria, galinheiro, curral, estufa, pomar, bancada, canteiro (livre/bloqueado), animais por vaga.

## Ambiente em volta da ilha — conceito em UMA cena (10/11/2026) — `ambiente/`
- Objetivo: a ilha parecia flutuar (bege em volta, penhasco de terra, sem sombra). Pedido: fundo "como o apartamento" + mato na frente.
- Entrada (`entrada_tela_com_ilha.png` 3200×3744 + `entrada_mascara.png`, assets `asset_ktLmwhWXdGKQdYzkY3KUbUkg` / `asset_DeQy1tcbmFAoLVWnkUAurntp`):
  `sitio_fundo_vazio.png` colada em (400,1500) **sem o penhasco** (detectado por cor; a faixa de terra e o bege entram na máscara);
  segunda referência = o apartamento (clima/cor do céu e do fundo). `model_openai-gpt-image-2-5-sunburst`, **19 CU**.
- O modelo devolveu **2656×3120** (teto de resolução): `saida_bruta_do_modelo_2656x3120.png`; ampliado para 3200×3744 e a ilha recolocada
  pixel a pixel por cima (`cena_ambiente_v1.png`).
- Resultado: céu com nuvens, colinas, campos, casinhas e moinho ao longe, gramado contínuo, estradinha saindo do portão, moitas/flores/pedras
  e uma árvore grande à esquerda com sombra. **Problemas:** (1) o estilo do entorno é mais pintado/realista e a ilha mais contornada
  e saturada, então ela aparece como um "remendo" de gramado; (2) a câmera do entorno é mais aérea/em perspectiva que o isométrico da ilha;
  (3) a ilha ocupa só ~60% da largura; o entorno ampliado 1,2× fica macio.
- Próximas tentativas possíveis: pedir o entorno no mesmo traço contornado, faixa de transição pintada em volta da ilha, ou separar em
  camadas (fundo distante com parallax + anel de gramado no estilo da ilha + moitas do primeiro plano como sprites).

### Decisão sobre o ambiente (Vitor, 10/11/2026): fica a cena única v1
- Foi testado o caminho em **camadas** (`camadas/`: `ilha_sem_penhasco.png` com alfa, `grama_tile_256.png`, `paisagem_distante.png`,
  `primeiro_plano/*.png` com 8 sprites de vegetação, e a maquete em tela de celular), mas o Vitor achou a v1 melhor e **ficou a cena única**.
  As camadas ficam guardadas só como alternativa; não usar sem nova decisão.
- Arquivo final: **`sitio_cena_ambiente.png`** (3200×3744): saída do modelo ampliada + a ilha (`fundo vazio` sem penhasco) recolocada **exata**
  por cima, com a máscara certa (a recomposição da v1 antiga tratava flores brancas e pedras claras como bege e as trocava por pintura do modelo).
- **Posição da ilha dentro da cena: (400, 1500).** Para colocar as peças (`pecas/posicoes.json`, coordenadas da ilha 2400×1712) na cena,
  some (400, 1500) a x e y. As peças são sprites sobre o fundo vazio que já está dentro da cena.
- Pontos a tratar ao ligar ao jogo: o entorno tem estilo mais pintado e câmera mais aérea que a ilha; a ilha ocupa ~60% da largura da cena.

## O que a arte tem e o que se afastou do blockout
- Tem: os 9 canteiros comuns vazios, banca de venda, estufa, pomar, lago detalhado, animais, portão.
- Se afastou: silo e armazém ficaram à **direita** da casa (o blockout os punha à esquerda); a ilha saiu ~25% maior e os
  canteiros ~3,75 tiles (blockout: 3). **Área andável e colisões devem ser traçadas em cima da arte**, não do guia.
- Escala: com a Laís e o Tiro a 1,35 (valor da Casa) funcionam; como a ilha ficou maior, `dog_scale` desta sala deve
  ficar em torno de 1,7 (calibrar no jogo).
- Os dados do jogo pedem 13 canteiros (9 comuns + 4 de estufa, `config.json → farm`), não 6 como no BRIEF antigo.

## Próximos passos sugeridos
1. **Fundo vazio** (`sitio_iso_fundo.png`): tirar da arte o que o jogo revela por compra (estufa, pomar, animais,
   prédios das criações, silo/armazém/bancada, banca) e os canteiros; manter chão, caminhos, casa, lago e borda.
   Fazer com edição/inpaint a partir desta arte (mesma imagem como referência) e conferir deriva fora das áreas editadas.
2. **Peças soltas**, fundo transparente, mesmo ângulo e escala: canteiro livre/bloqueado, estufa, galinheiro, curral,
   moinho, queijaria, silo, armazém, bancada, banca, portão aberto/fechado, pomar, animais por vaga.
3. Ligar ao jogo: `rooms/farm.json` (objetos, regiões, `footprint`, polígonos de chão/obstáculos), `dog_scale`,
   `backdrop`/`edge_cover`. Ver `docs/WORLDS.md`.
4. Se quiser outros mundos (Praça, Vila) no mesmo padrão, repetir: blockout → referências (estilo + câmera) → gerar.

## Limites do Scenario nesta conta (Free)
- Não há ferramenta de "canvas" no MCP; o que existe é `asset_detect` (mapa de bordas/profundidade) e geração com
  referências.
- LoRAs de isométrico com controle de line art (Isometric Background etc.) pedem plano Starter.
- Upload: `upload_asset` com `file_size` exato → `curl -X PUT` na URL assinada → `upload_asset_complete`.

## Integração no jogo (10/11/2026, local)
- `py -X utf8 -I tools/build_farm_island.py` gera os assets em meia resolução (`game/assets/sprites/areas/farm/ilha_*`) e o `game/data/rooms/farm.json`.
  Depois: `godot --headless --path game --import` e `mipmaps/generate=true` nos `ilha_*.import` (já ligado) e `--import` de novo.
- Peças e posições vêm de `pecas/posicoes.json` (somando (400,1500) e ×0,5 para a sala). O canteiro bloqueado é o próprio canteiro livre com mato e pedra por cima (o do Codex, em `../../quadrante_horta/`, tinha outra perspectiva e não alinhava).
- Capturas: `game/tests/farm_island_shots.gd` (ver cabeçalho). Detalhes no `CLAUDE.md` ("Sítio em ilha").
