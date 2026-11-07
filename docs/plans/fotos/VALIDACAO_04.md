# Fotos do Tiro — validação da etapa 04

06/11/2026, local. Claude iniciou; Codex retomou a sessão
`f73be960-73b5-55d4-b400-6b5379eceed7` e concluiu a conferência.

## Entrega

- `CardViewer.open(id, {host})`, `close()` e `is_open()`: visualizador único, sobre a
  Sheet e abaixo dos avisos; X, Escape e toque fora fecham. `AlbumView.open_photo`
  encaminha ao visualizador; `detail` continua como reserva dos testes antigos.
- `CardStage` transparente, só enquanto aberto; `CardSurface` com perspectiva via
  `card_tilt.gdshader`. Arrasto de 120 px inclina; mola de 0,35 s ao soltar; movimentos
  menores que 10 px não inclinam. O foil recebe o mesmo `tilt`.
- Limites de 22°/10°; Menos animação usa 8°/4°, volta imediata e foil parado.
  Níveis 1/2 e Menos animação desenham sob demanda (`UPDATE_ONCE`); 3/4 animados usam
  `UPDATE_ALWAYS` porque o efeito por `TIME` muda a cada quadro.
- Quatro versões, seleção persistida pelo GameState, faltantes escuras com cadeado;
  Tentar a sorte, Melhorar, chips com ajuda e alvos de 44 px, varal com substituição,
  Antes e depois e medalhão de coleção completa. No máximo um botão verde.
- `state_changed` atualiza os controles sem recriar o SubViewport nem reiniciar a
  inclinação. Prêmios na fila de Main aguardam a carta fechar. A ajuda de materiais
  fica acima da carta; Escape na ajuda preserva a carta, e Ir libera o destino.

Preservadas as molduras e a forma quadrada da etapa 03: esta etapa não redesenha a
arte para a proporção vertical proposta no desenho inicial. Holográfico só dentro
da foto, sem símbolo por cima; Rara com os cantos já ajustados pelo Vitor.

## Testes

**Resultado final: 10 testes distintos PASS**, após a reexecução focada descrita
abaixo. Nenhuma falha pendente da etapa.

Lista fechada da etapa mais os dois testes adicionais pedidos no prompt original:

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests card_viewer_test,photo_frames_test,photo_art_test,photo_rarity_test,album_test,house_test,ui_style_test -KeepGoing
```

Logs em `build/test_logs/r20261106_195139_cd1b6e01/`: 9 PASS e uma falha de
pré-condição em `photo_art_test`, em 132,5 s. Esse teste executa o instalador e
esperava zero cópias, mas o catálogo tinha avançado: instalou 80 variantes revisadas
além das 44 anteriores. Foram completados os imports, ativados os mipmaps dos 80
`.import` novos e reimportadas as imagens. Nenhuma imagem de origem foi alterada.
O instalador depois registrou zero cópias, 124 puladas e zero removidas: 31 fotos.
`album_rarity_pipeline.py check`: PASS para IDs, fontes, hashes e dimensões.

Uma segunda tentativa em `build/test_logs/r20261106_195558_e42a320d/` instalou outras
20 variantes recém-revisadas pela sessão de arte paralela, expondo a corrida do
teste. Seus imports/mipmaps foram concluídos sem chamar novamente o instalador
canônico: total instalado **144 variantes / 36 fotos**, sem mexer nas fontes.

Para não perseguir um catálogo em produção, `photo_art_test` agora congela uma foto
com quatro variantes em `build/photo_art_fixture/<execução>/catalog.json`, instala
duas vezes num destino privado e confere primeira cópia (4), dimensões (768×768) e
segunda cópia (0). O instalador ganhou `--catalog` e `--target`; sem argumentos,
mantém o comportamento existente. A verificação das texturas e mipmaps instalados
no jogo continua completa. O teste não instala nem remove lotes canônicos.

Reexecução final em `build/test_logs/r20261106_195931_e015a51a/`: parse, conteúdo,
textos e `photo_art_test` **4/4 PASS em 40,3 s** (arte: 15,6 s). Somados aos seis
outros testes da lista fechada já aprovados, completam os dez distintos.

A primeira tentativa em sandbox falhou por acesso a `user://` e ao repositório de
certificados do Windows; não foi considerada evidência de defeito no jogo. As
execuções acima usaram o acesso necessário e saves de teste isolados.
Sem portão, campanha ou simulador.

## Capturas e desempenho

`fotos_04_shots.gd`, sem headless, Godot 4.7.2 / Compatibility / GTX 970.
**51 PNGs conferidos visualmente**, 17 por resolução (360×780, 390×844, 412×915), em
`build/screenshots/fotos_04`, `fotos_04_390` e `fotos_04_412`.
Cada pasta tem `_contato.jpg` e `performance.json`.

Níveis 1/3/4 parados e inclinados nos dois sentidos; nível 4 em dois instantes na
mesma inclinação; duas versões, bloqueios, melhoria disponível, coleção completa,
varal cheio e Menos animação. Auditoria automática **OK** nas três resoluções:
limites da tela, textos, escala uniforme, alvos de toque e botão verde único.

Medição de 120 intervalos entre quadros por nível, após aquecimento, carta inclinada:

| Resolução | Comum média / p95 (ms) | Holográfica média / p95 (ms) | Holográfica >33,3 ms |
|---|---|---|---|
| 360×780 | 0,50 / 0,59 | 0,58 / 0,81 | 0/120 |
| 390×844 | 0,51 / 0,63 | 0,64 / 0,73 | 0/120 |
| 412×915 | 0,70 / 1,43 | 0,54 / 0,62 | 0/120 |

Sem engasgo observado nesta amostra nativa. Estes números não são medidas de celular
nem de Web. Conferência em aparelho físico permanece pendente.

## Continuação

Próxima etapa: **05**, `etapas/ETAPA_05_ABRIR.md`; prompt em `PROMPT_05.md`.
Até lá, abrir pelo álbum ainda consome automaticamente as cartas fechadas (ponte
da etapa 01). A 05 deve substituir isso pela revelação, sem sorteio antecipado ou
duplicado, e integrar o resultado ao mesmo visualizador e à fila modal.
Álbum novo, varal na home e tutorial ficam nas respectivas etapas.
Sem commit, push, publicação ou mudança nas regras/save.
