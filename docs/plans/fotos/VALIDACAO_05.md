# Fotos do Tiro — validação da etapa 05

06/11/2026, Codex, local. Somente a etapa 05; sem commit, push ou publicação.

## Entrega

- `CardReveal.open(id, {host})`: verso de madeira com pata, título da foto, “Nova
  foto surpresa!” e um botão verde Abrir. Consome exatamente uma carta somente ao
  tocar; trava também chamadas repetidas. O motor decide/salva o resultado, a UI
  só encena `Events.photo_rolled` via `CardReveal.play_result(id, result)`.
- Flip de abertura 0,4 s e revelação branca de 0,6 s, selo `RevealSeal` e texto por
  nível. Comum: pulinho; Brilhante: luz dourada curta; Rara: confete leve + success;
  Holográfica: confete cheio + flash pastel arco-íris + big. Sem roleta.
- Tentar a sorte passa pelo verso e volta em 0,7 s; Melhorar mostra a moldura nova
  com luz/selo. Repetida diz “Você já tinha esta versão” e mantém a versão exibida.
  O nome do resultado só aparece quando a face é revelada. Menos animação entrega
  diretamente, sem flip, luz ou confete. Sequências completas: aproximadamente
  1,12 s (abrir), 1,42 s (tentar), 0,72 s (melhorar), além da entrada de 0,3 s.
- O MESMO `CardViewer` permanece aberto: a entrega só repõe seus controles.
  Fechar cancela os tweens; a limpeza do confete pertence ao próprio efeito.
  Reabrir após interrupção usa o estado já gravado, sem novo sorteio.
- `AlbumView.open_photo` encaminha fechadas para revelação sem consumo antecipado.
  `detail` continua disponível. `photo_taken` e `photo_sealed` entram na fila modal
  de Main, com deduplicação, atrás dos prêmios/capítulo/Novo!, e aguardam fechar o
  visualizador anterior. Fotos anteriores à descoberta do Álbum ficam fechadas.
- Gestos, folhas, bandejas, viagens e minijogos adiam a revelação; aviso tocável é
  lembrete e libera folha/bandeja para a fila. Boas-vindas conta cartas fechadas,
  mostra “N fotos para abrir” e Ir abre a primeira. DEV ganhou “Carta fechada”.
- Verso novo com `.import` e mipmaps, gerado pelo modo **`-- --back-only`** de
  `tools/photo_frames_art.gd`. Nenhuma moldura, selo ou shader da etapa 03 regravado.
  Ilustrações existentes e os 144 arquivos instalados foram preservados; nenhum
  lote foi instalado e a produção paralela não foi consultada/modificada.

Sem alteração de formato/save, custos, sorteio, pesos, garantias ou eventos de
obtenção. O único ajuste de consulta no motor foi a linha de boas-vindas contar
cartas fechadas em lugar de fotos não vistas. Nenhuma mudança em drag_scroll.gd
ou nos testes de rolagem.

## Testes

`card_reveal_test` registrado em `suite` e na área `album` de `tools/test_areas.json`.
Confere os seis grupos numerados da etapa e também prioridade de prêmio enfileirado
após foto, eventos `photo_sealed`, contagem/Ir de `Line_photo` e cartas anteriores
à descoberta do Álbum. Persistência validada por roundtrip de `GameState` ao fechar
em plena animação, sem usar save antigo.

Comando final:

```powershell
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests card_reveal_test,card_viewer_test,photo_rarity_test,festa_test,notice_test,welcome_test -KeepGoing
```

**9/9 PASS em 106,3 s**, incluindo parse, conteúdo e textos. Evidência:
`build/test_logs/r20261106_203033_c2e0437a/results.csv`.
Tempos: parse 12,6 s; conteúdo 9,6 s; textos 3,0 s; revelação 19,3 s;
visualizador 14,5 s; raridades 3,6 s; festa 12,0 s; avisos 17,0 s;
boas-vindas 13,2 s. A última revisão limitou o registro de visita da foto à
abertura inicial, sem repeti-lo ao Tentar a sorte/Melhorar. A rodada anterior
`r20261106_202641_892e8038` também passou 9/9 em 104,2 s.

Execução anterior finalizada em 108,6 s: também 9/9 PASS, evidência
`r20261106_202258_7fd84510`; checagem adicional de prioridade/boas-vindas:
4/4 PASS em 45,8 s (`r20261106_202519_98036f64`). A primeira rodada
`r20261106_201905_167401ff` expôs dois problemas de fixture, corrigidos: IDs de
foto inexistentes no teste novo e o teste `festa_test` emitia apenas pressionar
no toque da linha. Agora emite pressionar **e soltar**, preservando a verificação
de fechar/ir. As capturas iniciais também expuseram callback de limpeza capturando
confete já destruído; a limpeza foi vinculada ao efeito e revalidada sem esse erro.

Sem portão, campanha ou simulador. Todos os processos usaram `TIRO_TEST_TAG`;
os testes/capturas removem o SaveManager ou usam caminho descartável.

## Capturas

`game/tests/fotos_05_shots.gd`, **sem --headless**, Godot 4.7.2 / Compatibility / GTX 970.
16 PNGs por resolução, **48 no total**, em:

- `build/screenshots/fotos_05/` — 360×780.
- `build/screenshots/fotos_05_390/` — 390×844.
- `build/screenshots/fotos_05_412/` — 412×915.

Casos: verso, meio do flip, festa/luz/final nos quatro níveis, repetida e Menos
animação. Festa/luz são dois instantes distintos de cada efeito. Pranchas
`_contato.png` abertas para conferir todas as imagens; verso, repetida e final
holográfico também abertos individualmente. Auditorias automáticas OK nas três
resoluções: limites, textos, alvos >=44 px, escala uniforme dos NinePatch,
proporções das imagens e no máximo um botão verde. A carta cobre a casca como o
visualizador da 04; título, carta e ações ficam no primeiro plano, acima do HUD/abas.
As capturas usam fixtures de resultado para cobrir todos os níveis; o teste novo
usa as ações reais do motor. Sem silhuetas ou símbolos novos sobre o holográfico.

## Continuação e pendências

Etapa 06: Álbum novo, `etapas/ETAPA_06_ALBUM.md`; prompt em `PROMPT_06.md`.
Grade maior, Para abrir no álbum e Quase lá ficam na 06; tutorial fica na 09.
O verso já está pronto para a faixa Para abrir. Não chamar `open_photo_card` na
construção da grade: usar `CardReveal.open`/`AlbumView.open_photo` no toque.

Conferência de toque em Web e aparelho físico permanece pendente. Nenhum export
Web foi produzido nesta etapa e as medidas nativas não substituem celular.
