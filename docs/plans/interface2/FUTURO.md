# Ideias para depois da Interface 2 (NÃO executar agora)

O plano "Interface 2 — aconchego moderno" terminou na etapa 12. O que ficou de fora de propósito:

- **Sons e música.** O jogo continua sem nenhum som (`assets/audio/` vazio). É a maior mudança de "sensação"
  que falta: toque de botão, plantar, colher, moedas, latido, comemoração e música calma por mundo. Pacotes CC0
  (Kenney) servem; `.ogg` curto, carregado sob demanda no Web; precisa de preferência "Som/Música" ao lado de
  "Vibrar" no `settings.json`.
- **Tema escuro.** A bíblia (`01_BIBLIA_VISUAL.md`) já tem os tokens em `Palette`; falta uma segunda paleta
  e a troca no `main_theme.tres`. Pensado para jogar à noite.
- **Dia e noite nos mundos:** o céu do `backdrop` muda com a hora local; luzes nas janelas à noite.
- **Clima:** chuva leve no Sítio (só visual; regar sozinho mudaria regra).
- **Decorar a casa** arrastando móveis: precisa de estado novo no save e de regras de footprint.
- **Câmera de cinema** nos capítulos: a câmera passeia até o lugar novo quando ele abre.
- **Ícones das abas animados** (Tiro piscando, mochila balançando quando chega item).
- **Mão que ensina** (a dica de arrasto da horta) reaproveitada para outros gestos novos.
- **Reduzir o duplicado** `ModalCard.reveal` × `RewardSheet.reveal_in` (hoje são dois códigos quase iguais).
- **Balão do humor do Tiro** ("Tiro está feliz da vida!") encosta no tapete na tela do Tiro em 360×780; ajustar
  a âncora do balão.
- **Fontes embutidas em tamanho maior:** "Texto maior" escala o tema em ×1,15; um segundo nível (×1,3) exigiria
  rever as grades de 4 colunas da Mochila.

Já feitos dentro do plano (não repetir): Texto maior (etapa 11), vibração e "Menos animação" (plano anterior).

Ressalvas observadas no fechamento (25/10/2026):

- Comparar o desempenho do Sítio em navegador visível/aparelho: amostras exploratórias da retomada
  ultrapassaram 20 ms; manter os números brutos junto dos resultados finais, sem prometer 60 FPS.
- Estabilizar as fixtures de `world_life_test` e `world_pin_test` (Amigos): passaram na reexecução,
  mas houve falhas intermitentes no portão. Não foram apagadas nem tiveram as garantias reduzidas.
- Atualizar as fixtures históricas `g01_tasks_ready_many` e `t03_growth_ready` do tour completo.
  Os complementos/testes reais cobrem os estados; o nome desses PNGs não prova que ficaram prontos.
- Revisar aviso de momento já visível ao abrir o seletor, que pode cobrir o título transitoriamente;
  Manual com exemplos/instruções e alguns ícones junto ao texto; vários balões de pronto pulando.
- A fala de prêmio real excede o orçamento ilustrativo de 14 palavras. Preservada por ser fala
  da história; uma redução depende de pedido do Vitor, não de uma limpeza visual automática.
