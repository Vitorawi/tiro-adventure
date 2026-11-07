# Carregamento Web — integração local, 07/11/2026

- Caixinha Brilhante: Recém-chegado (`newborn`) e Filhotinho (`puppy`), também padrão sem dica.
- Cena da cenoura Brilhante: Dentinhos (`teething`) e demais fases atuais.
- Logo e barra ficam separados da ilustração; preenchimento usa progresso real do motor.
- Fontes PNG e prompts nesta pasta; WebPs consumidos em `game/web/loading/`.
- Layout: logo no espaço superior, barra e texto no inferior. Artes não contêm interface desenhada.
- `tools/prepare_loading_art.py` preserva fontes e gera derivados (Pillow).
- Shell, export local, CI, persistência e cache: ver `docs/DEPLOY.md`.

## Validação

Build local dos dois canais concluído, sem publicação.

`tools/test.ps1 -Level etapa -Exact -Tests saves_test,quest_reward_test -Jobs 2`:
5/5 PASS em 58,4 s, com verificação de scripts, conteúdo e textos.
Logs: `build/test_logs/r20261107_132206_f454d8ac/`.

`tools/loading_test.py`: PASS para as seis fases e fase desconhecida, separação
prod/dev, armazenamento indisponível, progresso real e espera da inicialização,
erro com nova tentativa, layouts 360×780 / 390×844 / 412×915, motor Web real,
sincronização inicial da dica e recarga offline com service worker ativo.
O teste usa perfis descartáveis e servidor próprio; não toca nos saves do usuário.

Seis capturas de carregamento e uma da primeira tela real foram conferidas em
`build/screenshots/loading/`. Celular físico ainda não conferido.
