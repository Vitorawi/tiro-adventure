# Interface 2 — fechamento local (25/10/2026)

Etapas 00–12 encerradas localmente por Claude Sonnet 5.5 e Codex. Sem push ou publicação,
campanha/simulador, mudança de regras, falas, dados de conteúdo ou formato do save.
O teste em aparelho físico continua sendo a conferência do Vitor após pedir publicação.

## Critérios de pronto

- [x] Portão completo executado uma vez; 102/102 têm resultado PASS após correções/reexecuções focadas.
- [x] Percurso por eventos de toque do Chrome em modo celular, com capturas e save descartável.
- [x] Desempenho Web medido nos três cenários; **a meta de 20 ms não foi atingida em todas as amostras do Sítio**.
- [x] Tours nas três resoluções, pranchas finais abertas, checklist e diferenças registrados abaixo.
- [x] Documentação atualizada; `CLAUDE.md` e `AGENTS.md` com conteúdo idêntico.

## Testes e correções

O portão único (`tools/test.ps1 -Level portao`, três processos) levou **645 s (10 min 45 s)**:
97/102 na primeira passada, em `build/test_logs/r20261025_024012_262fb8d0/results.csv`;
transcrição em `build/portao_i2_12.log`. A passagem dizia sheet entre as cinco falhas;
o CSV mostra **worlds** nessa posição, com sheet já PASS após o reparo anterior ao portão.

| Falha | Tratamento e resultado |
|---|---|
| `sheet_test` (herdada da 11, corrigida antes do portão) | Procura `IntroductionNext` por nome e conta apenas cabeçalhos diretos de estação, distinguindo o título do cartão de compra. Mantém as verificações de botão inteiro e ausência de título repetido. |
| `wish_guide_test` | Procura `QuestGo_lais_first_wish`; o primeiro botão agora é ajuda. Mantém a navegação real do Ir. |
| `worlds_test` | Mede o alvo efetivo após layout e procura a textura válida do controle vetorial filho. Mantém altura mínima, ícone real e ausência de texto em Lugares. |
| `ready_badges_test` | Restaurados em `WorldCard` os chips independentes de prêmio, coleta, achado e tesouro. |
| `world_life_test` | Não reproduziu na reexecução; nenhuma garantia removida e nenhum reparo de lógica atribuído a essa falha intermitente. |
| `world_pin_test` | Uma falha em `place:friends`, sem reprodução na reexecução e nas três rodadas relatadas na passagem. Continua registrado como instável. |

Reexecução dos cinco: **PASS**, junto de scripts/conteúdo/textos,
`build/test_logs/r20261025_025125_56c030cb/results.csv` (8/8; 126,7 s somados por teste).
Não é uma segunda suíte inteira. O resultado consolidado do portão é 102/102, preservando
o resultado bruto e as duas instabilidades acima.

Na retomada, duas falhas de composição foram corrigidas:

- DEV: seis abas em **duas colunas**, para a folha não ultrapassar a tela.
- Tiro com bagagem pendente: `CollectWalk` fica **acima de Cuidar** e recolhe enquanto a
  roleta está aberta. Ao fechar, reaparece se ainda há bagagem. O teste existente ganhou
  verificações de não sobreposição e de abrir/fechar nas três resoluções.

Validação dessas mudanças: **7/7 PASS em 62,4 s** (DEV/prod, sheet, estilo e rápido),
`build/test_logs/r20261025_031413_1bbbc819/`; **6/6 PASS em 93 s** (volta do passeio,
roleta, cuidados e rápido), `build/test_logs/r20261025_031608_f462b626/`.
Uma tentativa inicial de teste dentro do sandbox não conseguiu escrever `user://` e
falhou na checagem de scripts por acesso ao ambiente; foi substituída pela execução acima.
Não houve falha de código nessa tentativa. A suíte inteira não foi repetida.

Durante o roteiro Web apareceu `Lambda capture was freed` no trecho do prêmio. O callback
de `Motion.fly_arc` passou a transportar apenas o id do ícone, consultando a instância
antes de movê-la; o efeito de chegada pode liberá-la no mesmo quadro. Validação:
**6/6 PASS em 67,6 s**, `build/test_logs/r20261025_033534_305d0e16/` (peças, prêmio,
camadas e rápido), mais o novo caso de ciclo de vida em `ui2_kit_test`, PASS em 2,5 s,
log `build/economy/etapa_01/ui2_kit_test.log` (é apenas o caminho padrão do runner;
nenhuma simulação foi executada).
O mesmo cuidado foi aplicado à entrada escalonada e à contagem animada: só ids e
valores atravessam os callbacks. HUD/próximo passo/prêmio/peças + rápido: **7/7 PASS
em 92,4 s**, `build/test_logs/r20261025_034122_ec36ea9e/`.

## Capturas, pranchas e diferenças

- Antes: `build/screenshots/interface2_antes/`.
- Tour completo: `build/screenshots/i2_12_tour/`, `i2_12_tour_390/`, `i2_12_tour_412/`:
  **114 PNGs em cada pasta**, produzidos na primeira parte desta etapa e revistos na retomada.
- Complementos regenerados com o código final: `i2_12_extra_360x780/`,
  `i2_12_extra_390x844/`, `i2_12_extra_412x915/`: **22 PNGs cada**, cobrindo roleta,
  História/Pessoas/Diárias, prêmio, alfinete, mundos abertos/bloqueados, compra e conversa.
- Pranchas HTML: `prototipo/prancha.html#final_tiro`, `#final_missoes`, `#final_premio`,
  `#final_alfinete`, `#final_mapa`, `#final_bandejas`, `#final_festa`.
  PNGs renderizados e abertos em `build/i2_12_review/final_*.png`.
- Contatos dos tours e complementos, todos abertos: `build/i2_12_review/tour*.png`,
  `extra*.png`. São índices de revisão; os PNGs originais preservam a resolução integral.

Os protótipos são direção visual, não uma troca dos dados reais. Foram mantidos nomes,
falas completas, ingredientes, filas, selos, bloqueios e a ordem dos cuidados; listas longas
rolam dentro da folha. Fotos dos mundos mostram o enquadramento real; a altura se adapta
à tela/dica. O fogão mostra todas as receitas em grade com rolagem vertical, sem a antiga
faixa lateral. O Tiro usa o zoom e os corpos reais de cada fase. O cartão grande de capítulo
pode precisar rolar quando um salto DEV libera muitas novidades de uma vez.

O tour completo contém fixtures históricas: `g01_tasks_ready_many` pode mostrar história
terminada; `t03_growth_ready` não prepara todos os requisitos atuais. Essas imagens não
provam esses estados. Os complementos e os testes de comportamento cobrem os estados
correspondentes. A prancha de prêmio passou a apontar para `i2_05_reward`, e não para g01.

### Checklist 04 §B por tela

✓ = conferido; △ = ressalva descrita depois da tabela. As três colunas correspondem aos
itens **Visual**, **Jogo** e **Celular** do §B. A revisão combina capturas nas três
resoluções, os testes de comportamento/estilo/texto e o roteiro de toque; não é uma medição
instrumentada da latência de cada botão. A resposta usa `Motion.press` (0,08 s), voos e
contagem existentes; a latência de entrada de um aparelho físico continua no roteiro abaixo.

| Tela / estados revistos | Visual | Jogo | Celular |
|---|:---:|:---:|:---:|
| Casca: HUD, próximo passo/cartão, aviso, rodapé | ✓ | ✓ | ✓ |
| Tiro: normal, necessidades baixas, sono/noite | △ | ✓ | ✓ |
| Cuidar: roleta de quatro/cinco discos e alfinete | ✓ | ✓ | ✓ |
| Comidinhas, comida arrastada, esponja | ✓ | ✓ | ✓ |
| Bagagem pendente na tela Tiro | ✓ | ✓ | ✓ (correção + teste em três tamanhos) |
| História: início, cruzamento, concluída | ✓ | ✓ | ✓ |
| Pessoas: linhas recolhidas/expandidas, prontas | ✓ | ✓ | ✓ |
| Diárias: Hoje/Semana, prontas e em andamento | ✓ | ✓ | ✓ |
| Folha de prêmio e próximo destino | ✓ | △ | ✓ |
| Casa, Sítio, Praça, Vila e Natureza | ✓ | △ | ✓ |
| Seletor: mundos abertos/bloqueados, chips | ✓ | ✓ | ✓ |
| Alfinete, nome ao segurar e lugar novo | ✓ | ✓ | ✓ |
| Conversa de NPC e compra de construção | ✓ | ✓ | ✓ |
| Horta: sementes, arrasto, cuidado, colher tudo, estufa | ✓ | ✓ | ✓ |
| Fogão/liquidificador/bancada: livre, falta, ocupado | ✓ | ✓ | ✓ |
| Criações e petisco para amigo | ✓ | ✓ | ✓ |
| Natureza: bandeja e painel de coleta | ✓ | ✓ | ✓ |
| Feira, Encomendas e Minha banca | ✓ | ✓ | ✓ |
| Obras: banco, jardim, piquenique, festa | ✓ | ✓ | ✓ |
| Passeios: escolha, resultado, bagagem cheia/parcial | ✓ | ✓ | ✓ |
| Mochila: depósitos, filtros, presentes, vazio/cheio | ✓ | ✓ | ✓ |
| Item: ausente, ingredientes/origens/usos | ✓ | ✓ | ✓ |
| Caderninho, Manual, Coleção e Álbum | △ | △ | ✓ |
| Crescimento: fases, requisitos, detalhes e caderneta | ✓ | ✓ | ✓ |
| Comemorações: capítulo, tesouro, seda, cerimônias | ✓ | ✓ | ✓ |
| Boas-vindas: presente, achados, prontos e passeio | ✓ | ✓ | ✓ |
| Configurações: Texto maior, Menos animação, saves | ✓ | ✓ | ✓ |
| DEV: recursos/progresso | ✓ | ✓ | ✓ (duas colunas) |

Critérios visuais conferidos: Fredoka/Nunito e variações do tema, controles vetoriais,
superfícies/tokens, semântica das cores e seleção por contorno, um primário por painel,
espaçamento e destaque dos valores. Critérios de jogo: foco, texto, retorno visual,
estado, gestos, bloqueios com motivo, animações. Critérios de celular: alvos, corte/rodapé,
contraste com ícone/forma, Menos animação e estados vazio/andando/erro/sucesso.

Ressalvas da revisão, sem disfarçar como ✓:

- O balão de humor do Tiro encosta visualmente no tapete; é cosmético e está no FUTURO.
- A fala real da folha de prêmio pode ultrapassar as 14 palavras do orçamento. Foi
  preservada pela proibição de reescrever falas; cabe nas três larguras.
- No mundo com muitos prontos existem vários balões; a meta de somente um elemento
  pulando por tela não é estritamente cumprida. Não se retirou o estado de pronto.
- O Manual mantém instruções e exemplos do catálogo; certos ícones de conteúdo ficam
  junto ao texto, sem disco próprio. Não foi ampliado o redesenho do catálogo nesta etapa.
- Um aviso de momento já em exibição pode sobrepor temporariamente o título do seletor
  em fixtures do tour. O complemento de mundos, capturado após o aviso, mostra o estado estável.
- Menos animação foi coberto pelos testes existentes; vibração e latência percebida só
  podem ser fechadas em aparelho. Não foi declarado teste físico.

## Toque e desempenho Web

Export final local: `tools/export_web.ps1`, log `build/i2_12_export_final.log`.
Refeito na continuação de 25/10/2026 após o reinício do PC: **código de saída 0,
sem ERROR/SCRIPT ERROR/Falha no log**, produção e dev concluídos; `version.json`
restaurado pelo script. A primeira tentativa desta retomada gerou os pacotes, mas teve
erros do sandbox ao acessar certificados/configurações do Godot; não conta como export
final sem erro. Log preservado em `build/i2_12_export_final_sandbox.log`; a execução
válida usou acesso ao ambiente e está no log final acima.
Produção: **7.913.280 bytes**; dev: **7.913.264 bytes** (aproximadamente 7.727,8 KiB).
Inclui os assets que já estavam no disco; a arte do trabalho paralelo não integra este commit.

Roteiro reproduzível: `build/touch_steps_i2_12.json`; execução por
`tools/touch_test.ps1 -Url http://localhost:8000/dev/ -Steps build/touch_steps_i2_12.json`.
Chrome headless, viewport CSS 390×844, escala 2, `Input.dispatchTouchEvent`, perfil
descartável e save lido do IndexedDB desse perfil. Não há chamada de método do jogo
para executar as ações verificadas. Preparação: botões DEV existentes para liberar o
capítulo com fogão/horta/Praça e fornecer ingredientes/moedas.

A ordem do roteiro foi adaptada ao save novo: a primeira pílula/folha/Ir é conferida
**antes** da preparação DEV; depois vêm cozinha, quatro canteiros, mundos/Praça,
Tiro/Cuidar/Banho/Mochila. Um save novo não tem fogão nem acesso ao Sítio/Praça;
não se mudou o requisito do jogo para forçar a ordem literal do exemplo da etapa.

Evidência exploratória preservada em `build/screenshots/i2_12_toque_previa/`:
fogão: cenouras **10 → 8**, lote em andamento e Fila cheia; quatro canteiros plantados
confirmados no save; Praça selecionada; banho com higiene **100**; Mochila aberta.
A execução consolidada e as medições finais estão registradas abaixo.

Execução consolidada válida: `build/i2_12_touch_final3.log`, 16 capturas em
`build/screenshots/i2_12_toque/`. O save confirma **quatro plantios, cenouras 8 e
carrot_snack na fila do fogão**; higiene final **100**. A pílula entregou welcome,
abriu a folha e Ir abriu a Tigela; Praça, roleta, banho e Mochila foram abertos por toque.
Duas tentativas anteriores não liberaram o cenário DEV porque a Tigela ainda estava
aberta e interceptou o toque no HUD: foram invalidadas para cozinha/horta/mundos, sem
aproveitar as respectivas médias baixas como prova de desempenho do Sítio.

Medição: intervalos de `requestAnimationFrame`, ignorando os dois primeiros,
com média, P95, pico e quantidade acima de 33,4 ms; não é o tempo interno da GPU/Godot.
As amostras exploratórias também ficam preservadas:

| Cenário | Quadros | Média | Pico | >33,4 ms |
|---|---:|---:|---:|---:|
| Pílula/conversa/folha (primeira parte) | 228 | 17,91 ms | 116,8 ms | 3 |
| Sítio com balões, exploração com outros renders | 154 | 22,51 ms | 183,4 ms | 4 |
| Sítio, segunda amostra da retomada | 215 | 28,14 ms | 166,7 ms | 53 |
| Abrir roleta, retomada | 135 | 19,63 ms | 150,1 ms | 3 |
| Folha, roteiro consolidado válido | 133 | 17,54 ms | 83,4 ms | 1 |
| Sítio, roteiro consolidado válido | 479 | 28,25 ms | 150,1 ms | 121 |
| Roleta, roteiro consolidado válido | 134 | 19,65 ms | 150,0 ms | 3 |

Não se descarta a amostra lenta para declarar a meta atingida. Investigar o Sítio em
uma sessão dedicada e comparar no navegador visível/aparelho, antes de prometer 60 FPS.

## Roteiro para o Vitor no celular, quando pedir publicação

1. Abrir `/dev/` e instalar como PWA. Conferir legibilidade de Fredoka/Nunito e acentos,
   inclusive com Texto maior, sem linhas cortadas.
2. Alternar as quatro abas. Conferir rodapé preso, transparência sobre o mundo e
   distância da barra de gestos do telefone.
3. Abrir o próximo passo, tocar Ir, fazer a ação, Pegar e usar Depois/Ir na folha.
   Conferir um prêmio por vez e moedas/itens chegando ao destino.
4. Na Casa, tocar o fogão, escolher receita, ajustar quantidade e Cozinhar. Conferir
   ingredientes ausentes, fila cheia e coleta direta quando pronto.
5. No Sítio, escolher semente e arrastar começando em um canteiro por outros quatro.
   Repetir com regador/foice, Colher tudo, câmera e pinça. Conferir se o dedo cobre o alvo.
6. Usar Ir para ver o alfinete/anel no chão. Segurar um lugar para consultar o nome;
   soltar não deve executar a ação. Viajar pelos cartões-postais até a Praça.
7. No Tiro, abrir Cuidar com o polegar, Banho, comida arrastada, carinho e escova quando
   disponível. Conferir conforto dos quatro/cinco discos e bagagem sem cobrir Cuidar.
8. Abrir Mochila, filtrar depósito, item e origem; conferir presente/bagagem sem espaço.
9. Ver vibração no aparelho e repetir com Menos animação. Conferir sensação de resposta
   e engasgos no Sítio com vários balões, na roleta e na abertura das folhas.

Melhorias posteriores e ressalvas de desempenho: [FUTURO.md](FUTURO.md).
