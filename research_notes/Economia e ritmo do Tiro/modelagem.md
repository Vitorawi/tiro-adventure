# Modelagem econômica do Tiro Adventure: revisão crítica do dossiê e da candidata V0

Pesquisa em 16/10/2026. Escopo: matemática da economia, sessões, conversões, filas e capacidade. Leitura integral das 826 linhas do dossiê enviado; inspeção dos JSON e dos métodos relevantes do jogo. Nenhum valor abaixo é uma tabela nova aprovada. Cálculos são verificações analíticas, não resultados de simulação de jogadores ou de playtest.

## 1. O que as fontes sustentam, e que modelo representa este jogo?

### Takeaway

O dossiê oferece uma linguagem útil de fluxos, oportunidades e testes, mas especifica um outro MVP. Seu custo monetário de sementes, estoque unificado, backend autoritativo e evolução por idade não são regras do Tiro. Machinations ajuda a estruturar hipóteses; seus textos comerciais e exemplos comunitários não validam os números de nenhum dos dois projetos.

### Cited Findings

- **[Fato do dossiê]** O próprio texto classifica as tabelas como propostas, reconhece não ter confirmado templates oficiais com os nomes Farming Simulator, Idle Converter e Virtual Pet Mechanics, e separa moedas, itens, tempo e afeto. Leitura integral, incluindo os apêndices. [Dossiê enviado](C:/Users/Vitor/.codex/codex-remote-attachments/01a145eb-7e5d-75d3-b858-ef3b77b50400/6C1711EC-C0DD-4209-98AD-6FAD132BBDBC/1-Farm_Virtual_Pet_Game_Design_Economia_Pesquisa_Completa.md).
- **[Fonte primária de ferramenta]** A documentação de Machinations distingue Delay (recursos podem ser processados simultaneamente) de Queue (um de cada vez). O corpo completo dessa página foi obtido na extração de busca; a abertura direta repetidamente trouxe só o shell da página. Isso apoia a distinção estrutural, não certifica um diagrama que tenhamos executado. [Delays & Queues](https://machinations.io/docs/delays-queues-2).
- **[Fonte primária de ferramenta]** Pools armazenam recursos e têm limite de capacidade; Drains removem recursos da economia. As páginas foram localizadas e seus corpos recuperados pela extração do mecanismo de busca, mas a navegação direta devolveu apenas a moldura do site. Não extrapolar detalhes de versão nem suporte a capacidade dinâmica sem testar. [Pools](https://machinations.io/docs/pools), [Drains](https://machinations.io/docs/drains).
- **[Fonte comercial, não benchmark]** O artigo de idle defende acomodar jogo ativo e ausente, metas além do ciclo básico e escolhas significativas. Também recomenda escassez ligada à monetização. Essa segunda parte não é requisito do Tiro, e não há neste artigo estudo de campo que valide durações de campanha ou preços. [How to design idle games](https://machinations.io/articles/idle-games-and-how-to-design-them).
- **[Fonte comercial]** O manifesto associa preços, valor, produção e alocação; sua discussão inclui crypto, pré-mineração e retorno financeiro. A primeira abertura recuperou o texto; tentativas posteriores falharam. Sua defesa de simular antes de fixar preços é útil, mas não demonstra que um jogo solo precisa de escassez permanente ou equilíbrio monetário estacionário. [Manifesto](https://machinations.io/articles/the-machinations-manifesto-for-building-sustainable-game-economies).
- **[Fonte comercial, exemplo construído]** O case F2P usa 100 agentes por 120 passos, compara perfis monetizados e afirma que uma diferença média próxima de 60% é aceitável. Isso é conclusão do autor sobre o exemplo, não benchmark transferível para Tiro. A ideia útil é observar distribuições de resultados, e não apenas a média. [Simulating Player Personas](https://machinations.io/articles/balancing-f2p-economies-simulating-player-personas-and-progression-curves-with-machinations).
- **[Exemplo comunitário]** Idle Game Loop Simulation existe, é de Zeynab Ghazi, e sua página marca grande parte da descrição como auto-generated. Isso confirma a existência do exemplo, não seu equilíbrio nem um template oficial de fazenda. [Diagrama comunitário](https://machinations.io/community/ZeynabGhazi/idle-game-loop-simulation-3066bbe049ba11ed9a660626ff1c9bc8). O link IDLE/Clicker GAME foi aberto, mas não foi executado nem auditado como modelo. [Outro exemplo](https://machinations.io/community/shinigami/idleclicker-game-dc24126c2f1d11ef900a0ad568087609).
- **[Fonte terminológica]** Custo marginal é o custo adicional da próxima compra; custo cumulativo agrega os recursos já gastos para chegar ao estado atual. Essas definições não determinam crescimento exponencial de preços. [Marginal Cost](https://machinations.io/glossary/marginal-cost), [Cumulative Cost](https://machinations.io/glossary/cumulative-cost).
- **[Fato atual]** Plantar no Tiro não debita moeda nem item. `crops.*.coins` é crédito na colheita. Regar reduz uma vez 30% do tempo restante; estufa multiplica o tempo inicial. [GameState: plant, water, harvest](C:/Users/Vitor/Documents/ClaudeGame/game/autoload/game_state.gd:880), [config](C:/Users/Vitor/Documents/ClaudeGame/game/data/config.json), [culturas](C:/Users/Vitor/Documents/ClaudeGame/game/data/crops.json).
- **[Fato atual]** Ingredientes são removidos ao enfileirar; a estação agenda o próximo trabalho a partir do fim do anterior. Lotes prontos continuam ocupando a fila até recolhidos. Se o lote não cabe, continua pronto. Estações diferentes trabalham em paralelo; vagas adicionais da mesma estação são uma fila, não máquinas extras. [StationState](C:/Users/Vitor/Documents/ClaudeGame/game/scripts/state/station_state.gd), [cook/collect](C:/Users/Vitor/Documents/ClaudeGame/game/autoload/game_state.gd:680).
- **[Fato atual]** Categorias só limitam quando a construção está comprada (`storage_active`). O jogo é local, com progresso no dispositivo. [Armazenamento](C:/Users/Vitor/Documents/ClaudeGame/game/autoload/game_state.gd:1193), [Mapa do projeto](C:/Users/Vitor/Documents/ClaudeGame/AGENTS.md).

### Inferences

**Modelo mínimo recomendado para raciocinar, ainda sem escolher números:**

1. Inventário disponível por item e categoria.
2. Itens comprometidos em trabalhos em andamento, com saídas futuras e horários.
3. Produtos prontos fora do inventário (canteiros, estações e buscas).
4. Carteira, desbloqueios, missões e prêmios ainda não resgatados.
5. Disponibilidade de atenção: sessões, ações possíveis por sessão, navegação e prioridades.
6. Necessidades e afeto do Tiro como utilidades próprias, não como moeda equivalente obrigatória.

Equação contábil de itens: `ΔI = coletas + recompensas − receitas iniciadas − entregas − alimentação − vendas − materiais de compra`. Equação da carteira: `ΔC = moedas de coleta + vendas + pedidos + recompensas − compras`. Pedido é ralo de itens e fonte de moedas; venda também. Construção é ralo de moedas/materiais e pode gerar capacidade produtiva permanente. Atribuir o recurso a cada aresta evita chamar toda troca de sink.

Saldo crescente não é automaticamente inflação. Neste jogo solo, com preços fixos e sem mercado entre jogadores, o problema relevante é **perda de utilidade da moeda**: quantas decisões de investimento ainda existem e quantas sessões de renda representam. Examinar `saldo/custo da próxima escolha desejada`, custo em sessões e concentração da renda por fonte. Não buscar emissão igual à destruição em todas as fases: poupar para algo deve funcionar.

Aumentar canteiros/animais/rotas cria feedback positivo: mais capacidade → mais renda → mais capacidade. Uma compra pode escoar dinheiro hoje e acelerar seu excesso amanhã. Avaliar separadamente retorno financeiro, conveniência, opções novas e progresso narrativo. Um cosmético não precisa se pagar; uma fila pode valer por permitir sair do jogo.

Não importar backend nem custos de sementes para resolver um problema que a versão local não tem. Preservar uma produção básica gratuita é uma boa hipótese de recuperação econômica. Verificar também acesso à venda e espaço para recolher essa produção: plantio gratuito sozinho não prova recuperação.

### Gaps

- Não foi executado nenhum modelo Machinations. Não há números de progressão do Tiro validados externamente.
- As páginas comerciais não fornecem uma razão ótima universal para moeda/minuto, ocupação de estoque, duração de campanha ou prêmio de pedido.
- Não existe nesta pesquisa telemetria real de sessões, toque por tarefa, preferência entre cozinhar/vender ou tempo até capítulo. A arquitetura deve admitir testar essas incertezas antes de fixar valores.

## 2. O que os cálculos mostram sobre margem, atenção, filas e armazenamento?

### Takeaway

A progressão precisa ser comparada por sessão e pelo recurso que realmente limita o jogador. Margem positiva é só uma condição parcial: tempo na mesma máquina, lote, estoque, destino do produto e custo de oportunidade mudam o resultado. Por outro lado, exigir que toda receita avançada sempre supere a simples em moedas/minuto eliminaria o valor da atenção e das preferências.

### Cited Findings

**A. Margem atual e valor que se perde ao transformar.** Cálculos próprios a partir de [receitas](C:/Users/Vitor/Documents/ClaudeGame/game/data/recipes.json) e [preços](C:/Users/Vitor/Documents/ClaudeGame/game/data/items.json). Não incluem XP, vínculo, prêmios de missão, tempo agrícola, desbloqueios ou deslocamento.

| Conversão atual | Venda dos ingredientes imediatos | Venda da saída do lote | Valor incremental | Tempo de máquina | Incremento/min de máquina |
|---|---:|---:|---:|---:|---:|
| Petisco cenoura | 6 | 12 | 6 | 1 min | 6 |
| Ensopado | 13 | 28 | 15 | 2 min | 7,5 |
| Biscoitos maçã (2) | 26 | 80 | 54 | 5 min | 10,8 |
| Caixa petiscos | 121 | 60 | −61 | 7 min | −8,71 |
| Farinha (2) | 9 | 28 | 19 | 2 min | 9,5 |
| Queijo | 24 | 32 | 8 | 4 min | 2 |

Caixa não custa 121 moedas debitadas: os ingredientes poderiam ser vendidos por isso. Também não é correto dizer que toda cadeia perde 61 moedas desde a matéria-prima: o valor dos ingredientes agrícolas crus dessa cadeia é 55 (maçã×2=14, cenoura×2=6, abóbora=12, batata=7, ervas=16). A saída de 60 supera essa base em 5. O problema forte é a opção melhor de interromper a cadeia nos ingredientes intermediários e vendê-los por 121. Moedas de colheita já obtidas não devem ser subtraídas como custo. [Mesmas fontes de receitas e preços acima](C:/Users/Vitor/Documents/ClaudeGame/game/data/recipes.json).

O pedido de três caixas paga 220 + parafuso e XP, consumindo intermediários que poderiam valer 363. Isso é troca de 143 moedas de oportunidade mais tempo de fogão por progresso/peça; pode ser deliberada, mas precisa ser legível e comparada a outras fontes da peça. [Encomendas](C:/Users/Vitor/Documents/ClaudeGame/game/data/progression.json).

**B. A V0 melhora a caixa nominalmente, mas não resolve seu papel.** Cálculos sobre valores propostos, não implementados: petisco passa de ingredientes 4 para saída 10 em 1 min (+6/min); biscoitos de ingredientes 20 para saída 36 em 15 min (+1,07/min); caixa de ingredientes 70 para 100 em 30 min (+1/min). A cadeia completa da caixa ocupa o mesmo fogão por 54 min: petisco 1 + biscoitos 15 + papinha 8 + caixa 30. Matéria-prima vale 41, saída 100: +59/54≈1,09/min de fogão, antes de atenção, cultivo e estoques. [Tabela candidata V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).

**C. Atenção muda a ordem das melhores opções.** Exemplo analítico de estado estável: quatro canteiros desbloqueados, três aberturas diárias separadas por oito horas, plantio e rega imediatamente após cada coleta, apenas um lote por canteiro entre aberturas, venda possível, sem demandas concorrentes e espaço suficiente. Não representa o começo da campanha nem inclui interações durante a sessão.

| Sistema/produção | Moedas brutas por lote de um canteiro | Por dia, quatro canteiros e três coletas |
|---|---:|---:|
| Atual: cenoura | 3 de colheita + 2×3 de venda = 9 | 108 |
| Atual: abóbora | 16 + 1×12 = 28 | 336 |
| V0: cenoura | 2×2 = 4 | 48 |
| V0: abóbora | 6×12 = 72 | 864 |

Na V0, cenoura e abóbora têm taxas ativas teóricas próximas (5,71 e 5,14 moedas/min/canteiro com rega imediata), mas por abertura a abóbora dá 18 vezes mais. Isso não é automaticamente ruim: concede conveniência à cultura longa. Demonstra por que equilibrar apenas moedas/minuto pode aumentar enormemente a diferença entre perfis e o volume que deve caber no silo. Com estoque real, o valor de 864 não é automaticamente alcançável: depende de vender/liberar espaço dentro da abertura. [Culturas atuais](C:/Users/Vitor/Documents/ClaudeGame/game/data/crops.json), [preços atuais](C:/Users/Vitor/Documents/ClaudeGame/game/data/items.json), [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).

**D. Filas comparadas por retorno, com matéria-prima disponível.** Na V0, ignorando preparos prévios e com intervalo de seis horas entre aberturas: um espaço de petisco entrega incremento de 6 moedas por retorno; três espaços entregam 18. Caixa entrega incremento 30 com um espaço; três espaços entregam 90. Em seis horas, todas essas filas terminam. Assim, caixa pode ser melhor por retorno mesmo sendo pior por minuto de máquina. O cálculo é condicional: exige ingredientes intermediários preparados, capacidade de coleta e não inclui tempo/gargalo de prepará-los no mesmo fogão. [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md), [agendamento sequencial](C:/Users/Vitor/Documents/ClaudeGame/game/scripts/state/station_state.gd).

Na mesma hipótese, três petiscos cobrem 3/360=0,83% da ausência; três caixas cobrem 90/360=25%. Capacidade da fila não cria produção automática depois que seus trabalhos acabam. Fila maior precisa ser avaliada em minutos de autonomia e em número de lotes por visita, nunca como três vezes a velocidade de uma máquina ocupada continuamente. [StationState](C:/Users/Vitor/Documents/ClaudeGame/game/scripts/state/station_state.gd), [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).

**E. Estoque mínimo e conforto são testes diferentes.** O Tiro valida a saída inteira do lote e mantém na origem o que não couber. [harvest](C:/Users/Vitor/Documents/ClaudeGame/game/autoload/game_state.gd:947), [collect](C:/Users/Vitor/Documents/ClaudeGame/game/autoload/game_state.gd:736).

- V0 silo provisório 12 e quatro cenouras×2: primeira rodada usa 8; sobram 4. Sem consumir/vender, só duas das quatro colheitas seguintes cabem. São 1,5 rodadas, sem qualquer reserva. Isso é pressão muito cedo, mesmo que cada lote individual caiba. [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).
- V0 mirtilo×20 em quatro canteiros produz 80. Silo `_3` sugerido de 64 não recebe a rodada toda. Com cinco outros itens, só dois lotes de 20 cabem de imediato. **Não é hardlock:** lote individual cabe e venda pode liberar espaço; é conflito entre a promessa de uma boa volta e uma sequência de colher/vender/voltar. [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).
- Para iniciar caixa atual é necessário ter simultaneamente dois biscoitos e uma papinha na geladeira (3 unidades) mais uma erva no silo; não precisa guardar toda a matéria-prima inicial simultaneamente se etapas forem feitas em ordem. Coletar exige 1 livre no baú. Para o contrato de três caixas, é necessário reunir as três, salvo futura entrega parcial. [Receitas](C:/Users/Vitor/Documents/ClaudeGame/game/data/recipes.json), [pedidos](C:/Users/Vitor/Documents/ClaudeGame/game/data/progression.json).
- V0 armazém construído exige madeira×4+pedra×2: são 6 materiais, abaixo da caixa provisória de 12. Isso só prova capacidade estática; é necessário verificar acesso às rotas, moeda e espaço ocupado por outros itens. Armazém `_2` exige duas tábuas e um parafuso isento: duas unidades no armazém são suficientes ao comprar, mas fabricar as tábuas exige lotes de madeira e fila. A soma bruta de toda madeira histórica não é capacidade mínima porque ela é consumida durante o preparo. [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).
- Comprar animais aumenta tanto rendimento como ingredientes do lote; a versão atual salva quais animais participaram e a quantidade. Três animais podem tornar o lote maior do que a folga disponível, mesmo se um animal funcionava bem. [cook/collect](C:/Users/Vitor/Documents/ClaudeGame/game/autoload/game_state.gd:680), [receitas](C:/Users/Vitor/Documents/ClaudeGame/game/data/recipes.json).

### Inferences

**Métricas diferentes que não devem ser fundidas:**

- Receita de venda total por lote.
- Valor incremental versus vender ingredientes agora.
- Incremento por minuto de cada máquina e por minuto de canteiro necessário.
- Valor por ação e por abertura (incluindo coleta, fila, navegação e venda).
- Necessidade de estoque simultâneo e maior lote atômico.
- Recuperação efetiva de necessidades por ingrediente, com truncamento a 100.
- Utilidade de missão, desbloqueio, peça especial, carinho e coleção.

Não atribuir um preço universal a afeto para forçar o cuidado a competir financeiramente com a venda. Mas mostrar seu custo de oportunidade: alimentar com biscoito atual deixa de vender por 40; vender duas unidades deixa de ter até duas interações de cuidado. Se compras ficam muito caras e vínculo pouco perceptível, o sistema pode ensinar a evitar o Tiro. Essa hipótese deve ser observada, não presumida.

Uma receita avançada pode intencionalmente pagar menos por minuto e mais por retorno, dar uma peça ou mudar o mundo. O critério útil é não ser estritamente pior para todos os perfis e objetivos. Identificar uma fronteira de opções: mais moeda/atenção, mais afeto/ingrediente, mais autonomia, mais descoberta.

Preço de produto isolado não é mecanismo de demanda. Com venda ilimitada, sempre haverá um destino, mas pode ser um destino tedioso. Antes de multiplicar rendimento, verificar se cozinha, pedidos, cuidados e projetos absorvem o volume sem depender de limpeza constante do silo.

Fila e canteiro maduros são estoque externo. Deixar produtos neles pode ser estratégia legítima, mas reduz capacidade produtiva. O modelo deve conservar os itens lá, impedir replantio/reabastecimento incompatível e contar bloqueios por capacidade. Um simulador que só conta mochila perde o custo dessas decisões.

Usar quatro condições de armazenamento separadas: (1) todo lote obrigatório cabe vazio; (2) existe sequência executável para a próxima receita/ampliação; (3) uma volta típica cabe junto com reservas; (4) o esforço para esvaziar não domina a sessão. As duas primeiras previnem travas; as duas últimas medem diversão.

### Gaps

- Os exemplos ignoram outras rendas e missões de propósito. Não podem virar promessa de dias até comprar uma construção.
- Não sabemos quantas ações de coleta/replantio cabem numa sessão de dez minutos e quanto o jogador dedica ao Tiro, diálogos e troca de mundos.
- Não foi calculado um preço de peça especial: não é vendável e seu valor depende do desbloqueio desejado, fontes alternativas e excedente.
- Nenhum teste aqui decide a capacidade ideal. 12 ou 64 são candidatos sob crítica, não valores recomendados.

## 3. Que decisões da V0 devem ser reabertas, e que experiências resolvem as dúvidas?

### Takeaway

A V0 já inclui algumas proteções corretas, mas combina grandes mudanças de renda, duração, rendimentos, prêmios e preços antes de provar a experiência. O próximo trabalho deve responder perguntas de projeto e testar cenários, em vez de transformar uma planilha arbitrária em contrato para os agentes implementarem.

### Cited Findings

- **[Proposta V0, não regra vigente]** Zera todas as moedas de colheita e busca, reduz preços de vários itens e prêmios, aumenta custos de construções, estende tempos e aumenta bastante rendimentos. São intervenções diferentes com efeitos combinados. [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).
- **[Proposta V0]** A recompensa de entrega de missão é 20% do valor vendido, com mínimo 5/máximo 40; construções/owned recebem valor baixo e o reembolso combinado tem teto de 25%. Essas proporções não têm fonte empírica no dossiê nem nas páginas Machinations consultadas. [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md), [dossiê](C:/Users/Vitor/.codex/codex-remote-attachments/01a145eb-7e5d-75d3-b858-ef3b77b50400/6C1711EC-C0DD-4209-98AD-6FAD132BBDBC/1-Farm_Virtual_Pet_Game_Design_Economia_Pesquisa_Completa.md).
- **[Proposta V0]** Seis produtos adicionais e quatro depósitos com ampliações de custos iguais aparecem antes de uma demonstração de lacuna de uso, de autonomia ou de demanda. O fogão já concentra muitas cadeias; acrescentar nele pão, biscoito e cesta aumenta competição por um recurso serial. [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md), [receitas atuais](C:/Users/Vitor/Documents/ClaudeGame/game/data/recipes.json).
- **[Proposta V0]** Rotas longas têm XP local maior, mas por minuto podem continuar abaixo das curtas: lane 3 XP/3 min=1; timber 20/30≈0,67. Isso não é erro necessariamente, mas a proposta não eliminou o incentivo de atenção — apenas o tornou explícito. É preciso decidir o valor aceitável desse prêmio de atividade. [V0](C:/Users/Vitor/Documents/ClaudeGame/docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).
- **[Proposta dossiê]** Perfis 2/5/15 acessos, 14 dias e 1.000 agentes são metodologia proposta, não padrão externo validado. O dossiê reconhece que o número de visitas sozinho é insuficiente e pede timestamps. [Dossiê](C:/Users/Vitor/.codex/codex-remote-attachments/01a145eb-7e5d-75d3-b858-ef3b77b50400/6C1711EC-C0DD-4209-98AD-6FAD132BBDBC/1-Farm_Virtual_Pet_Game_Design_Economia_Pesquisa_Completa.md).

### Inferences

**Decisões a reabrir antes do plano de execução:**

1. **Qual experiência estamos comprando com o tempo?** Sessão inicial acolhedora, produção útil ao retornar, conteúdo que ocupa semanas, ou desafio de otimização são objetivos diferentes. Definir primeiro a experiência de uma abertura e de uma semana; o calendário não deve ser um requisito artificial a cumprir com timers.
2. **Qual é o papel de cada fonte de dinheiro?** Zerar moeda automática é candidato, não consequência obrigatória da pesquisa. Pode haver renda pequena de ação para feedback e recuperação, desde que a venda e os pedidos continuem relevantes. Comparar zero, redução e deslocamento para primeiras descobertas, sem editar simultaneamente todos os preços.
3. **Quanto esforço de atenção deve ser recompensado?** Preservar opção rápida é bom; tornar cliques repetidos a única maneira razoável de progredir não. Medir diferença de avanços entre sessões curtas espaçadas e sessão contínua, sem tentar igualá-las por definição.
4. **O que é conforto de armazenamento?** A limitação desde o começo tem respaldo no problema relatado. Mas não derivar capacidade da existência de um lote que cabe; derivar de reservas, retorno e próxima decisão. Depósitos de categorias com diversidade/fluxo muito distintos não precisam compartilhar custo e curva.
5. **Qual é a utilidade das ampliações?** Fila compra autonomia; canteiro compra vazão/opções; silo compra folga; receita compra transformação/destino. Custear todas apenas por moeda nominal esconde essa diferença.
6. **Que produtos novos resolvem lacuna real?** Exigir para cada candidato: insumo sem uso que aproveita, estação com tempo livre que ocupa, destinatário, narrativa, efeito em estoque e tradeoff distinto. Se só alonga uma receita existente, talvez um lote maior ou um projeto em etapas funcione melhor que mais um item.
7. **Como a campanha remunera entregas?** Missão pode trocar itens por desbloqueio valioso e não precisa imitar encomenda. Porém um coeficiente global de 20% pode fazer o jogador sentir punição por seguir a história. Orçar por marco: itens entregues, moedas entregues/recebidas, nova utilidade e esforço antes da próxima escolha.
8. **Quão central o cachorro continua sendo?** Cuidado e desejos não devem virar uma taxação que concorre com cada meta financeira. Preservar maneiras acessíveis de cuidado e tornar visíveis as recompensas afetivas/narrativas.
9. **Qual é a experiência depois da campanha?** Construções finitas não escoam moeda para sempre. Isso não exige taxas de manutenção nem sinks infinitos: coleções opcionais, projetos e um final satisfatório podem ser suficientes. Não usar escassez permanente como objetivo abstrato.

**Experimentos analíticos e de jogo recomendados (propostas):**

1. **Linha de base fiel.** Rodar economia atual com estoque realmente ativado, ações via regras reais, filas seriais e itens prontos persistentes. Separar estado novo de save avançado. O simulador tem de reproduzir manualmente ao menos uma sequência conhecida antes de prever campanha.
2. **Caminho crítico e recuperação.** Desde cada marco, testar vender reserva, gastar dinheiro em decoração, colher categoria cheia, acumular saídas, retornar após ausência e comprar animal extra. Procurar um caminho possível sem recompensa futura, capacidade fictícia ou item contado duas vezes. A existência do caminho não basta: registrar quantos toques/minutos ele exige.
3. **Perfis por agenda, não só por contagem.** Três sessões de dez minutos em horários fixos; sessões curtas irregulares; sessão contínua; jogador que cuida primeiro; jogador que segue só a história; maximizador de renda. Repetir com estoque conservador, venda agressiva e reserva para missões. Incluir dias pulados e intervalos longos.
4. **Comparação controlada.** Primeiro avaliar limite inicial e reposicionamento das construções; depois fontes de moeda; depois margem/demanda; depois ritmos e autonomia. Não atribuir um resultado ao preço de uma construção quando também mudou cultura, recompensa e slot.
5. **Retorno típico.** Registrar quantidade pronta, quantidade que coube, ações até liberar espaço, produtos que ficaram bloqueados e minutos de fila efetivamente ocupados durante a ausência. Esse experimento captura a frustração que um gráfico de saldo não revela.
6. **Sensibilidade.** Variar uma faixa de preço/tempo/capacidade, sem nova tabela final. Verificar quais pequenas alterações causam grandes mudanças no capítulo alcançado, no dinheiro acumulado e na obrigação de vender. Uma economia robusta admite que o jogador não seja ótimo.
7. **Experimento de papel com produtos.** Para cada receita nova proposta, comparar três casos: não adicionar; adicionar receita; oferecer entrega/projeto usando produtos existentes. Só escolher novo item quando ele melhora variedade de decisão ou narrativa, não apenas quantidade de ícones.
8. **Playtest de significado.** Observar se o jogador sabe o que está preparando e por quê, se sente melhora ao ampliar, se consegue encerrar a sessão satisfeito e se cuida do Tiro por vontade. Simulação não demonstra isso.

**Métricas que tornam os resultados comparáveis:**

- Minutos ativos, dias de calendário e número de aberturas por marco, separados.
- Dinheiro livre versus dinheiro necessário para as próximas duas escolhas desejadas.
- Participação da renda por coleta, venda, pedido e prêmio; sem chamar saldo acumulado de inflação por padrão.
- Maior déficit temporário por item e capacidade, com causa identificada.
- P50/P90 de ações de limpeza de estoque por retorno, não só média de ocupação.
- Percentual de tempo das estações sem trabalho por falta de ingredientes, ausência, falta de demanda ou bloqueio de saída, causas separadas.
- Cobertura de ausência em minutos e lotes por vaga comprada.
- Entregas necessárias por melhoria e recompensa acumulada liberada imediatamente por comprá-la.
- Diversidade de opções efetivamente usadas e existência de estratégias alternativas viáveis.
- Tempo em que não há ação desejada possível, separando pausa satisfatória de bloqueio sem saída clara.

**Matriz de decisão para a síntese — julgamento de design desta pesquisa, não aprovação de implementação:**

| Proposta/ideia | Parecer | Fundamentação e próximo exame |
|---|---|---|
| Separar fontes, conversores, estoques e ralos por recurso | Manter | É a base contábil; pedidos removem itens e criam moeda. Mapear o código real antes de prever resultados. |
| Limites desde o primeiro uso da categoria e depósito como melhoria | Manter a direção | Corrige a inversão atual de infinito para limitado; capacidade e momento exatos ainda precisam de teste de retorno e recuperação. |
| Não perder produto maduro/pronto por falta de espaço ou ausência | Manter | Já é parte das regras relevantes; simulação deve preservar essa semântica. |
| Plantas/receitas curtas e longas coexistirem | Manter | Há necessidades distintas de atenção; comparar opções por visita e por máquina, sem impor igualdade de rendimento. |
| Medir sessões e distribuições em vez de só lucro/hora | Manter | Cálculos acima mostram inversão de preferência conforme agenda. |
| Plantio pago, sementes como moeda/item e kit de falência do dossiê | Descartar como solução necessária neste redesenho | Resolvem um risco introduzido pelo próprio modelo proposto; Tiro hoje planta gratuitamente. Só reabrir se houver objetivo de experiência específico que justifique a complexidade. |
| Estoque unificado do MVP externo | Descartar como transplante | O jogo possui categorias e depósitos narrativos; comparar complexidade das quatro categorias antes de redesenhar arquitetura. |
| Backend autoritativo, antifraude competitivo e trading como pré-requisito | Descartar como requisito desta economia | Não correspondem ao jogo local descrito; não ajudam a decidir ritmo ou diversão. Robustez local e migração continuam importantes. |
| Zerar toda moeda de colheita/busca | Rever | Pode reforçar venda direcionada, mas não é exigência matemática. Comparar zero com redução e prêmio de primeira descoberta. |
| Forçar emissão de moedas igual aos gastos permanentemente | Descartar | Um jogo solo finito pode permitir acúmulo e conclusão; investigar perda precoce de poder de escolha, não saldo crescente isolado. |
| Aumentar preço de compra para absorver renda | Rever | A compra também pode aumentar a renda futura; avaliar retorno e demanda, além do custo imediato. |
| Culturas com lotes 16/20 e capacidades 12/64 | Rever | Um lote cabe, mas várias saídas simultâneas e reservas podem exigir limpeza recorrente; não se comprovou conforto. |
| Mesma curva de ampliação para todos os depósitos | Rever | Diversidade e fluxo por categoria diferem; medir pico de espaço simultâneo e ritmo de desbloqueios. |
| Receita avançada sempre superar a básica em moedas/min | Descartar como regra universal | Receita longa pode ganhar por retorno, demanda, afeto ou narrativa; também não basta ter margem nominal positiva. |
| Prêmios globais de 20% e teto de devolução de 25% | Rever | Sem validação externa ou local; orçamento por marco e utilidade do desbloqueio são mais informativos. |
| Seis produtos, maestrias e novas ampliações definidos antecipadamente | Rever | Primeiro demonstrar a lacuna que cada um resolve e seu efeito no fogão, nas reservas e na demanda. |
| Prolongar campanha para semanas antes de medir | Rever | Duração desejada é uma decisão de produto; converter dias em espera artificial não prova aprendizagem nem variedade. |
| 1.000 agentes como garantia de precisão | Descartar como garantia | Muitas execuções de um modelo errado só repetem o erro; validar trajetórias concretas e comportamento antes de ampliar amostra. |

Esta matriz preserva o que é princípio útil e suspende os números. Crescimento de capacidade sem consumo útil pode produzir estoques excessivos ou venda repetitiva; isso deve ser corrigido pela relação entre produção e objetivos, e não automaticamente por taxas permanentes, escassez artificial ou punições ao cuidado.

### Gaps

- Faltam decisões do usuário sobre duração desejada de campanha e rotina preferida, mas é possível progredir estudando cenários sem pedir esse compromisso agora.
- O teto de 25%, a regra de 20%, os lotes de 16/20 unidades, seis produtos novos e semanas de campanha continuam hipóteses. Não devem ser apresentados aos agentes como requisitos fechados.
- Os percentis propostos não têm limites de aprovação ainda. A primeira medição da base e um playtest curto devem informar esses limites.
- A conclusão robusta hoje é estrutural: alinhar produção, consumo, atenção, filas e estoque; não há ainda fundamento para uma nova tabela final de números.
