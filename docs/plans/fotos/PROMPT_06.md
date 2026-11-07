# Prompt pronto — etapa 06

Projeto: C:\Users\Vitor\Documents\ClaudeGame (Godot 4.7.2, Tiro Adventure).
Godot: "$env:USERPROFILE\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
Python: C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe

Execute SOMENTE a ETAPA 06 do plano "Fotos do Tiro — cartas colecionáveis".

Leia AGENTS.md (ou CLAUDE.md), docs/plans/fotos/README.md, 01_DESENHO.md,
02_REGRAS_E_TESTES.md, INTEGRACAO_RARIDADES.md e etapas/ETAPA_06_ALBUM.md.
Leia também VALIDACAO_05.md e os arquivos atuais antes de editar.
Siga o passo a passo, os "não fazer", os testes numerados e o critério de pronto.

Contexto da etapa 05:
- CardReveal.open(id, {host}) devolve um CardViewer: verso de madeira com pata,
  título e Abrir. O consumo/sorteio acontece uma única vez, só ao tocar em Abrir.
- CardReveal.play_result(id, result) usa o resultado de Events.photo_rolled, sem
  sortear. Tentar a sorte passa pelo verso; Melhorar troca a moldura com brilho;
  repetida explica e mantém a carta. Menos animação entrega direto.
- A revelação termina no MESMO CardViewer, sem reabrir. CardViewer.is_open()
  cobre tanto a carta fechada quanto a revelação e as ações finais.
- AlbumView.open_photo(id) encaminha fechadas a CardReveal e abertas a CardViewer;
  não consome cartas antecipadamente. detail permanece como reserva.
- photo_taken/photo_sealed estão na fila modal de Main; capítulo/Novo!/prêmios
  têm prioridade. Uma carta por vez; fotos anteriores ao Álbum ficam fechadas.
  Durante atividades há lembrete; o toque libera a folha/bandeja e usa a fila.
- Line_photo das boas-vindas conta cartas fechadas, diz "N fotos para abrir" e
  Ir abre a primeira. DEV tem "Carta fechada" (dev_seal_photo).
- Verso: res://assets/sprites/ui/album/card_back.png, com mipmaps. Gerador:
  tools/photo_frames_art.gd -- --back-only; NÃO rodar sem esse argumento para
  refazer o verso, pois o modo padrão regrava molduras aprovadas.
- Preserve a arte da 03: Rara limpa, holográfico só DENTRO DA FOTO, sem símbolo
  sobre a foto holográfica. Carta quadrada. Não redesenhar molduras/foil.
- Só o visualizador tem SubViewport (destruído ao fechar). Níveis 1/2 e Menos
  animação: UPDATE_ONCE; 3/4 animados: UPDATE_ALWAYS (foil usa TIME).
- Há 144 variantes instaladas (36 fotos); o catálogo pode avançar em paralelo.
  Nível sem arte usa a ilustração da própria foto. Não instalar lotes nesta etapa.
  photo_art_test usa fixture privada (não instala no jogo).

Preserve alterações locais dos outros agentes. Não mexa em drag_scroll.gd nem
nos testes de rolagem. Nunca use tools/art/album_rarity_tests/. Sem novas regras de
sorteio, save, custos ou eventos de obtenção. Sem roleta. Madeira ilustrada, um botão
verde, bloqueios com StepCardUi.locked_button, alvos >= 44 px e ilustrações suaves.
Classe nova exige --headless --path game --import. PNG novo com .import e mipmaps.

Na 06: álbum em duas colunas de cartas grandes dentro do caderninho; AlbumSummary,
AlbumSealed/Para abrir, faltantes com pista e Quase lá barato; preserve abas/filtros
fora do Álbum, selo Novo e rolagem por seção. Use as APIs existentes da 04/05.

Validação: registre album_book_test em suite/album de tools/test_areas.json.
powershell -ExecutionPolicy Bypass -File tools\test.ps1 -Level etapa -Exact -Tests album_book_test,album_test,album_secrets_test,manual_test,card_viewer_test -KeepGoing
Sem portão, campanha ou simulador. Capturas fotos_06_shots.gd SEM --headless nas
resoluções 360x780, 390x844, 412x915; abrir e conferir os PNGs. Use save descartável.

Ao terminar: preencher Registro do README; atualizar AGENTS.md e CLAUDE.md (iguais)
e Estado atual do docs/ROADMAP.md. Entregar resumo curto, testes, capturas, pendências
e prompt pronto da etapa 07. Não fazer commit, push nem publicação.
