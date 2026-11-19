# Primeira semana do Tiro · E15

Em 19/11/2026, nove percursos de save novo chegaram a Dentinhos, serviram o almoço de despedida e concluíram a primeira missão da Vila. A economia fecha nos três perfis. O tempo de interação e a validação completa em aparelho físico continuam com ressalvas. Save 33.

## Como reproduzir

Na raiz, execute o comando abaixo com cada um dos três nomes de perfil. Cada processo usa a semente indicada, remove o SaveManager pessoal e começa com 10 moedas. O robô usa as operações de plantio, produção, venda, compra, refeições, aulas, crescimento e missões do GameState. O relógio avança para o próximo evento ou sessão. Os depósitos continuam limitados.

```powershell
powershell -ExecutionPolicy Bypass -File tools/economy_simulate.ps1 -Until week -Profile regular -Seed 1..3 -OutRoot build/economy/e15_verificado
```

As duas sessões do primeiro dia começam de manhã e no jantar. Depois, o percurso joga perto das 11h e das 19h nos dias de presença. O dedicado comparece todos os dias e obtém 3 estrelas ao cozinhar junto. O regular falta no D3 e obtém 2 estrelas. O tranquilo falta no D3 e D4, faz a primeira papinha guiada com 2 estrelas e usa pratos de 1 estrela depois. As escolhas são cenários de teste. O perfil estritamente “só fila, três pratos” do estudo nutricional ficaria abaixo dos quatro pratos e do prato de duas estrelas exigidos para Filhotinho. O resultado dos gestos é simulado na API do motor. O relógio, as recompensas e o inventário seguem as regras do jogo.

## Evidência dos critérios 1 a 7

| Critério | Resultado observado |
|---|---|
| 1. Do save novo a Dentinhos | 9/9 chegaram a Dentinhos, com o relógio DEV em zero. O percurso joga os 30 passos, entrega o mordedor e serve os três pratos do almoço. |
| 2. Dia do crescimento | Nas três sementes, Filhotinho no D2. Dentinhos no D7 dedicado, D8 regular e D9 tranquilo. A diferença decorre da frequência programada e das patinhas conquistadas. |
| 3. Minutos de jogo | Meta sem comprovação. A tabela abaixo separa tempo de sessão e espera. O caminho principal do dedicado leva 15,8 e 16,1 min nos dois primeiros dias, abaixo dos 35–40 min. Nos cinco seguintes varia de 5,8 a 30,0 min. Leitura, exploração livre e habilidade humana precisam de cronometragem em M3. |
| 4. Moedas e espaço | As nove execuções pagaram todos os investimentos de 190 moedas. O roteiro também comprou sementes, aveia e xampu. Vendas do excedente liberaram espaço para compras e colheitas. Valores brutos nas tabelas abaixo. |
| 5. Dia perdido | O regular retoma a lagoa no D4, o tranquilo no D5. Ambos chegam à Vila com sete patinhas. A Foto do peixe, as surpresas e os recibos são cobertos também por week_story_test após salvar e recarregar. |
| 6. Continuação | Todos receberam lais_village no capítulo 8. O tour navegou pelo botão Ir, serviu o almoço e conferiu a foto de grupo. A campanha integral alcançou também os capítulos posteriores. |
| 7. Telas e toque | Capturas abertas nos três tamanhos. Na exportação Web local, Chrome com toque emulado abriu a caixa, reabriu o save 33 do IndexedDB e avançou no carinho sustentado nos três tamanhos. A cobertura por tela e as falhas de interface estão descritas abaixo. |

## Caixa e depósitos

Semente 1. Cada célula mostra **entradas / saídas / saldo final** em moedas do dia de calendário. Entradas e saídas zeradas juntas indicam dia sem sessão. O prêmio de 20 do galinheiro entra pelo valor bruto. O último saldo de cada perfil foi lido depois de receber a primeira missão da Vila.

| Dia | Dedicado | Regular | Tranquilo |
|---:|---:|---:|---:|
| 1 | 83 / 50 / 43 | 83 / 50 / 43 | 83 / 50 / 43 |
| 2 | 123 / 100 / 66 | 105 / 100 / 48 | 105 / 100 / 48 |
| 3 | 36 / 0 / 102 | 0 / 0 / 48 | 0 / 0 / 48 |
| 4 | 36 / 0 / 138 | 46 / 0 / 94 | 0 / 0 / 48 |
| 5 | 113 / 30 / 221 | 21 / 0 / 115 | 36 / 0 / 84 |
| 6 | 25 / 0 / 246 | 90 / 30 / 175 | 26 / 0 / 110 |
| 7 | 118 / 50 / 314 | 21 / 0 / 196 | 109 / 30 / 189 |
| 8 | — | 101 / 50 / 247 | 16 / 0 / 205 |
| 9 | — | — | 81 / 50 / 236 |

O saldo antes da compra do galinheiro foi de 68 a 73 moedas nas nove execuções, abaixo da estimativa de 95 da revisão e suficiente para o preço de 60.

Os dois canteiros custam 20 cada no D1. Galinheiro e caminha custam 60 e 40 no D2. O mordedor custa 50 no capítulo 7. No D1 também saem 6 pela semente de abóbora e 4 pela aveia. No capítulo 5 saem 30 pelo xampu exigido na missão Banho de filhote. Assim, as compras desta rota somam **230 moedas brutas**. O Bom dia do D2 paga 30 uma vez, e o kit do galinheiro devolve 20 na compra.

| Perfil | Saldo antes de comprar o galinheiro (s1) | Saldo no D7 (s1, s2, s3) | Saldo após a primeira missão da Vila (s1, s2, s3) |
|---|---:|---|---|
| dedicado | 73 | 314, 298, 305 | 314, 298, 305 |
| regular | 73 | 196, 201, 223 | 247, 252, 269 |
| tranquilo | 73 | 189, 189, 192 | 236, 231, 234 |

Os limites observados foram cesto 16, despensa 12, pilha de materiais 16 e sacola 12. Cesto e despensa chegaram ao limite. Pilha e sacola tiveram pico zero nesta rota. A tabela mostra o pico **cesto/despensa** no dia. Os quatro picos e capacidades, as transações e o valor vendido para abrir espaço ficam em cada week.json.

| Dia | Dedicado | Regular | Tranquilo |
|---:|---:|---:|---:|
| 1 | 13/1 | 11/1 | 11/1 |
| 2 | 16/4 | 16/4 | 16/4 |
| 3 | 13/6 | 11/3 | 11/3 |
| 4 | 13/9 | 13/6 | 11/3 |
| 5 | 16/12 | 13/9 | 13/6 |
| 6 | 16/12 | 16/11 | 12/9 |
| 7 | 16/12 | 14/12 | 16/11 |
| 8 | — | 15/12 | 14/9 |
| 9 | — | — | 15/11 |

## Ritmo e ajustes

Semente 1. Em minutos por capítulo, cada célula mostra **sessão / espera de produção ou pesca / toque e navegação**. A sessão exclui a ausência entre refeições e inclui os pequenos intervalos reais dos gestos do quintal. O modelo cobra 3 s por toque instrumentado e 2 s por mudança de painel. A interface pode exigir tempo adicional para ler e executar um minigame. O robô espera de forma sequencial quando precisa imediatamente do produto. Essa espera mede a estratégia, e só o teste com uma pessoa pode determinar quanto desse tempo ela ocuparia com outra atividade.

| Capítulo | Dedicado | Regular | Tranquilo |
|---:|---:|---:|---:|
| 1 | 15,8 / 12,9 / 2,7 | 17,5 / 14,6 / 2,7 | 20,0 / 17,1 / 2,7 |
| 2 | 16,1 / 11,8 / 3,8 | 17,2 / 13,1 / 3,7 | 19,7 / 15,6 / 3,7 |
| 3 | 7,2 / 4,9 / 2,0 | 10,9 / 8,7 / 2,0 | 18,4 / 16,2 / 2,0 |
| 4 | 30,0 / 26,6 / 3,3 | 35,0 / 31,6 / 3,3 | 45,0 / 41,6 / 3,3 |
| 5 | 26,2 / 21,6 / 4,5 | 27,2 / 23,6 / 3,5 | 34,6 / 31,1 / 3,3 |
| 6 | 5,8 / 4,3 / 1,5 | 7,0 / 5,5 / 1,4 | 9,5 / 8,1 / 1,4 |
| 7 | 20,3 / 18,4 / 2,0 | 21,5 / 19,6 / 1,9 | 23,8 / 22,1 / 1,7 |

No ensaio inicial da semente 1, produzir ovos só ao chegar à carroça levou o capítulo 5 a 91,5 min no dedicado e 111,3 min nos outros dois perfis. O novo percurso deixa milho no comedouro antes de fechar a sessão e recolhe os ovos ao voltar. As medições finais também incluem o tempo dos toques e a política de estrelas de cada perfil. Com ovos antecipados, a despensa do dedicado chegou a 12/12 e a compra de xampu foi recusada. O robô passou a verificar o espaço antes da compra e vender excedentes pelo preço real da banca. Repetição em três sementes por perfil sem violação de caixa ou capacidade. [Primeiro ensaio](../../../build/economy/e15) · [Ensaio da despensa](../../../build/economy/e15_final) · [Nove medições finais](../../../build/economy/e15_verificado)

Preços, tempos de produção e requisitos de crescimento foram preservados. O estoque preparado resolveu a espera mais longa; baixar o preço do galinheiro ou aumentar o depósito não corrigiria o déficit de tempo ativo nos dias 1 e 2. A medição confirma que quatro pratos são alcançáveis antes do crescimento no D2. Não se ampliou a duração artificialmente para atingir a meta.

## Validação visual e M3

No tour da História, o almoço, as ações Servir, a foto e o destino da Vila ficaram acessíveis nos três tamanhos. No D1, a lista de História permite rolar até a ação Ir da primeira horta. A captura seguinte mostra o cartão Boa noite com a patinha e o gancho das galinhas. As pranchas reúnem 19 capturas novas por tamanho, entre História, tutoriais, Manual, Cozinhar junto e cerimônia. [360×780](../../../build/screenshots/e15_historia/360x780.jpg) · [390×844](../../../build/screenshots/e15_historia/390x844.jpg) · [412×915](../../../build/screenshots/e15_historia/412x915.jpg)

Na Web local, o [roteiro de toque e reabertura](../../../build/e15_web_check.py) passou nas três resoluções na exportação final. As três capturas depois do gesto mostram a fala “Olha o focinho!” e o próximo botão inteiro. [360×780](../../../build/screenshots/e15_semana/360x780/pwa_carinho.png) · [390×844](../../../build/screenshots/e15_semana/390x844/pwa_carinho.png) · [412×915](../../../build/screenshots/e15_semana/412x915/pwa_carinho.png)

No D2, o teste abriu Para crescer, tocou em **Crescer!**, leu a fase e tocou em **Que lindo!**. O botão ficou inteiro nos três tamanhos, o cartão fechou e o recibo de Filhotinho ficou marcado como visto. O erro de referência liberada reaparecia depois, quando o antigo temporizador do alfinete tentava usar a indicação já removida. A expiração agora acompanha a vida do alfinete e verifica seu identificador antes de fechar. Os três tours concluíram sem erro do motor. [360×780](../../../build/screenshots/e15_tutoriais/360x780/dia2_cerimonia.png) · [390×844](../../../build/screenshots/e15_tutoriais/390x844/dia2_cerimonia.png) · [412×915](../../../build/screenshots/e15_tutoriais/412x915/dia2_cerimonia.png)

Manter o roteiro M3 integral em aparelho físico. Cronometrar tempo ativo e espera em cada sessão, testar retorno após ausência e conferir no D2 o toque em **Crescer!**, **Que lindo!**, o fechamento da cerimônia e o próximo passo. Repetir o almoço e a entrada na Vila no D7. [Roteiro dos sete dias](etapas/ETAPA_14_tutoriais.md#roteiro-para-o-portão-m3-no-celular)

## Suíte completa e campanha

**Portão consolidado: 140 PASS, 17 falhas e 2 limites de tempo em 159 casos.** Os 19 casos restantes já tinham falhado ou atingido o limite na E14. No manifesto canônico completo são 145 PASS entre 164 casos. A simulação Quick é a execução adicional da campanha. O primeiro executor interrompeu a coleta quando tentou ler o log ainda aberto de um filho encerrado por timeout. O executor passou a registrar o timeout diretamente. A retomada selecionou todos os casos sem resultado na primeira passagem. A união foi conferida pelo nome contra o manifesto. [Primeira passagem](../../../build/e15_portao.log) · [Retomada](../../../build/test_logs/r20261119_133117_9176597c/results.csv) · [Consolidado por teste](../../../build/e15_suite.csv)

| Comparação com a E14 | Investigação |
|---|---|
| Oito falhas anteriores | `card_reveal_test` (nó fora da árvore), `hud_growth_test` (shader ausente), `quest_reward_test` (folha esperada), `ready_badges_test` (contagem), `tasks_test` (texto de humor), `text_budget_test` (fontes), `world_selector_test` (antigo capítulo da Natureza), `world_view_test` (enquadramento da Casa). |
| Horta e Natureza | `tray_test` ainda espera a barra na estufa. `nature_routes_test` espera a regra antiga de uma hora e oito maçãs no pomar. |
| Limites de tempo | `care_ui_test` e `station_tray_test` voltaram a atingir 300 s. Os primeiros erros registrados envolvem o anel do avatar e a ordem das comidas na bandeja. |
| Sete falhas do complemento E14 | `food_order_touch_test` e `food_menu_bounds_touch_test` continuam acusando alvo ou refeição. `daily_claim_touch_test` encontra painel nulo. `blender_position_touch_test` não abre a bandeja. `park_test`, `walk_return_test` e `festival_test` ainda esperam comportamentos ou contagens anteriores. |
| Casos investigados na E15 | `missions_actions_test` registrou a referência liberada sob carga. Passou no reteste isolado e após a correção do alfinete. `week_tutorial_test` voltou a testar o botão de crescer e a saída da cerimônia pela interface. O teste de arrasto da História tentava colocar o livro em uma folha quando ele já pertencia à cena principal; a fixture passou a arrastar a lista de capítulos e fechar o livro pelo botão próprio. O teste completo de rolagem passou com toque e mouse em 244,3 s. |

[Retestes da cerimônia, ações e alfinete](../../../build/test_logs/r20261119_144059_e65e31c0/results.csv) · [Reteste integral da rolagem](../../../build/test_logs/r20261119_144428_2cd9df06/results.csv)

A campanha final passou **6/6**. `progression_test` concluiu 514 ciclos com **138 missões ativas e 64 aquisições**. Esse teste histórico usa acelerações de fixture depois de Dentinhos. Na simulação separada com estoques limitados e regras do motor, o perfil de referência fez as **138/138 missões em 28,1 dias**, com 60/64 aquisições e **zero violações**. O encerramento do simulador considera todas as missões ativas; quatro ampliações opcionais ficaram por comprar. [Seis resultados](../../../build/test_logs/r20261119_143251_f68007b9/results.csv) · [Resumo do simulador](../../../build/economy/cuidado07_r20261119_143251_f68007b9_economy_quick/reference_s1/summary.json)

Na primeira campanha, o autoteste do simulador esperava o caminho antigo de Dentinhos e ignorava preço local de venda, semente de rotina e maestria da fila. O auditor estático incluía missões aposentadas e não reconhecia o pomar e os destinos do caderninho de receitas. O autoteste do circuito exigia uma ordem fixa anterior à ampliação da área de desejos. Os três voltaram a passar após a atualização das referências e das fórmulas. A comparação de 24 ações entre runner e GameState direto e as guardas contra concessão indevida e adulteração de timers continuam ativas.

## Fontes

Conectores Claude indisponíveis nesta sessão. Foram consultados no cache local `%TEMP%/claude/ecb7a66fe8453e1f/10ea2159-07a2-4098-8ec8-bab61252a04f/scratchpad/` os arquivos `plano.md` (dias, economia da banca, perfis e números do simulador) e `revisao.md` (Parte A, saldo do D2 e divisão do D1). No mesmo cache, diretório `21190024-f3e9-4ba7-b173-5032cd6fff58/scratchpad/txt/`, consultamos `Banca.dc.txt`, `Dias1e2.dc.txt` e `Dias2a7.dc.txt` para preços, cronograma e gestos. A convenção de tempo por ação vem de [Simulação e aceite da economia](../economia/04_SIMULACAO_E_ACEITE.md). Conferidos o README do plano, REGRAS, PROVISORIOS, o roteiro E14, AGENTS e CLAUDE. Nos conflitos prevalece REGRAS, inclusive D9, D10 e o recibo único do kit.
