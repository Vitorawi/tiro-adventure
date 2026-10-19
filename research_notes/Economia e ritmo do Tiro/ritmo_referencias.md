# Ritmo, aprendizado e armazenamento no Tiro Adventure

Pesquisa em 16/10/2026. Dossiê do usuário lido integralmente em três trechos. Consultados os rascunhos `00_VISAO.md`/`02_TABELAS_BALANCEAMENTO.md`, dados reais de crops/config/quests/progression e regras de armazenamento/fila. Nenhuma implementação ou alteração dos planos. A numeração V0 abaixo é candidata não validada; não a tratar como decisão aprovada. Evidência externa, observação local e proposta estão separadas.

## 1. Como acomodar sessões reais sem transformar aprendizado em espera?

### Takeaway

O próximo desenho deve começar pela sequência de decisões durante uma sessão e pelo trabalho útil que pode ser preparado para a ausência. A meta anterior de durar 14–24 dias, o perfil de três sessões diárias e todas as durações candidatas precisam ser reabertos: são hipóteses nossas, não resultado da pesquisa.

### Cited Findings

- **Fonte primária em entrevista histórica (2013):** Timur Haussila relata que o soft launch de Hay Day alterou praticamente todos os valores iniciais da economia e permitiu observar incompreensões e intervalos sem conteúdo. Destaca coerência causal — ovos são produzidos, moedas vêm de vendê-los ou transformá-los — e liberdade de aprender. É testemunho retrospectivo do responsável, não ensaio causal nem regra atual sobre ausência de tutorial. [Entrevista publicada pelo Deconstructor of Fun](https://www.deconstructoroffun.com/blog//2013/01/behind-success-of-hay-day.html).
- **Interpretação histórica de terceiros (2015):** a análise de SimCity BuildIt relaciona tempos curtos à permanência na sessão, médios a retornos e longos à ausência; explica que filas sequenciais permitem produzir enquanto o jogador está fora. O mesmo artigo associa inventário e retornos a monetização e até obrigação emocional. Essas intenções comerciais não são metas do Tiro. [Análise](https://www.deconstructoroffun.com/blog//2015/02/simcity-buildit-nice-town-but-would-you.html).
- **Dado local:** culturas atuais duram 60–900 s; rega reduz 30% do restante e estufa tem fator 0,7. Natureza tem várias atividades de 60–600 s, e pomar 300 s. [Culturas](../../game/data/crops.json), [configuração](../../game/data/config.json), [atividades](../../game/data/progression.json).
- **Dado local:** filas são sequenciais e baseadas em timestamps; fogão e liquidificador têm uma vaga inicial. Portanto uma receita curta não gera produção contínua por uma noite só porque o tempo corre offline. [Fila](../../game/scripts/state/station_state.gd), [estações](../../game/data/config.json).
- **Rascunho, não decisão:** V0 usa três sessões de dez minutos com intervalos de seis a oito horas, mas seus cultivos chegam a 90 minutos, suas receitas majoritariamente a 3–30 minutos e várias estações começam com uma vaga. [Visão V0](../../docs/plans/economia/00_VISAO.md), [tabelas V0](../../docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).

### Inferences

**Problema que precisa ser resolvido:** mais minutos nos timers não significam mais jogo nem maior dificuldade. Uma pessoa que visita a cada seis horas colhe uma rodada de uma cultura de cinco minutos e uma rodada de uma de sessenta minutos; os 55 minutos adicionais não mudam o resultado nesse regime. Quem joga continuamente sente essa diferença intensamente. O peso do tempo depende da distribuição de sessões.

Medir por estratégia e perfil: moedas por minuto ativo, por visita, por unidade de armazenamento, por minuto de ocupação de cada estação e por dia de calendário. Separar valor do produto, atenção exigida, produção que poderia ter acontecido e objetivo realmente cumprido. Uma receita pode valer mais moedas por lote e ainda ser ruim se ocupar o fogão que bloqueia três outros objetivos.

**Alternativas concretas para ausência, a prototipar antes de escolher:**

1. **Receitas curtas + filas/lotes maiores cedo:** preserva a brincadeira ativa e permite preparar mais unidades para depois. Exige ingredientes e espaço coerentes com o lote. A melhoria vende autonomia de sessão, não só um número de slots.
2. **Opções curtas e longas coexistindo:** uma escolha atende quem quer cozinhar agora; outra rende mais por coleta quando a pessoa sairá. A longa não deve ser obrigatória para concluir o primeiro exemplo da cadeia. Culturas longas precisam de demanda e de armazenamento para o retorno.
3. **Preparação em lotes de uma receita conhecida:** em vez de seis itens novos, o jogador pode escolher uma preparação maior/mais lenta de um produto já compreendido. Deve ser uma opção explícita com ingredientes e saída claros, sem automação infinita nem mudança de identidade do jogo.

É possível combinar 1 e 2. Não é necessário construir um sistema novo de tarefas automáticas. Antes, verificar se a fila atual, com receitas/lotes adequados, já resolve.

**Curva de aprendizado proposta:**

- Primeiro exemplo: uma ação causa um resultado visível e útil ao Tiro ou à Bloblo.
- Segundo exemplo: escolher o destino de um ingrediente entre duas necessidades já conhecidas.
- Terceiro: combinar duas cadeias independentes; o jogador pode decidir a ordem.
- Quarto: preparar reservas e fila para sair.
- Depois: um projeto com etapas visíveis usa a infraestrutura conhecida e permite caminhos opcionais.

Não lançar junto novas moedas, quatro categorias de armazenamento, receita de três subprodutos e requisito por atributo. A complexidade cresce por relações conhecidas. A dificuldade deve alternar: um novo sistema chega confortável; a próxima missão pede uso deliberado.

**Ritmo de retorno para testar:** retorno acolhedor → recolher/usar algo → fazer uma escolha → perceber progresso → deixar algo preparado. A sessão deve poder terminar bem. Se o último passo exige ficar esperando quarenta segundos só para reiniciar uma máquina, há um problema de autonomia, mesmo que o saldo de moedas esteja equilibrado.

**Divergência do plano anterior:** não escolher semanas de duração e preencher o intervalo com quantidades. Primeiro comparar a jornada existente em quatro agendas: sessão longa contínua; duas ou três visitas; uma visita; ausência irregular de dois dias. As frequências são cenários de teste, não segmentação validada. Além do jogador ótimo, simular quem guarda mais do que precisa, vende um item de missão por engano e compra uma decoração antes da melhoria produtiva.

### Gaps

- Sem telemetria/diário de partidas reais não sabemos duração de sessão, frequência de acesso, tempo de navegação ou qual etapa é tediosa.
- Nenhuma fonte consultada valida três sessões/dia, campanha de semanas ou 60/300/900 segundos para Tiro Adventure. O dossiê também marca suas durações como propostas.
- Não medimos subjetivamente se novas receitas dão variedade suficiente. Precisa de teste no celular, além de simulação econômica.

## 2. Como criar necessidade de espaço sem transformar o começo em gestão burocrática?

### Takeaway

Limites desde a entrada da categoria corrigem a regra invertida do jogo, mas quatro depósitos não precisam virar quatro tutoriais nem quatro bloqueios simultâneos. Dimensionar a primeira capacidade a partir das próximas ações e lotes, e abrir a solução antes da primeira colisão frustrante.

### Cited Findings

- **Fonte primária atual:** Hay Day separa culturas/frutas no silo de produtos, derivados animais e suprimentos no celeiro; ambos estão disponíveis desde o começo e são reparados no tutorial. A caixa de pesca só entra junto à área de pesca. A página oficial não fundamenta os números 12/24/40 do Tiro. [Suporte Supercell, versão espanhola indexada](https://support.supercell.com/hay-day/es/articles/silo-barn-tackle-box.html).
- **Dado local:** `storage_active` só limita se a construção existe; `storage_full` soma unidades por depósito e compara com espaço restante. A categoria ainda não construída é ilimitada. [GameState, linhas 1210–1263](../../game/autoload/game_state.gd).
- **Dado local:** `first_harvest` ensina rega/colheita; `bloblo_sell_surplus`, na ordem 22, ensina vender; `bloblo_more_crops` na 30 pede três colheitas novas e libera mais dois canteiros. A missão do silo está na ordem 140, depois de queijo na 130. [Missões](../../game/data/quests.json), [canteiros emprestados](../../game/data/config.json).
- **Dado local:** os limites construídos atuais são geladeira30, baú20, silo40 e armazém40. V0 propõe provisórios 8/8/12/12 e construídos 20/20/24/30. [Estado real](../../game/data/progression.json), [candidato V0](../../docs/plans/economia/02_TABELAS_BALANCEAMENTO.md).
- **Interpretação histórica de terceiros (2015):** o artigo de SimCity trata inventário como freio de acumulação e sugere que vender a NPC libera espaço sem destruir o esforço do jogador. Seu objetivo declarado também é controlar frequência e conversão paga; não constitui prova de que quanto mais apertado melhor. [Análise](https://www.deconstructoroffun.com/blog//2015/02/simcity-buildit-nice-town-but-would-you.html).

### Inferences

**Capacidade12 não está validada:** dois canteiros × duas cenouras = quatro unidades por rodada; 12 cabem em três rodadas sem consumo. Com quatro canteiros são oito unidades: cabe uma rodada e meia. Reservas de quatro cenouras para a Bloblo deixam apenas uma rodada inteira livre. O resultado depende da ordem exata de vender, entregar e coletar; somar moedas de recompensas futuras não prova viabilidade.

**Outro conflito V0:** quatro morangueiros com rendimento8 entregam32, acima do silo construído24; quatro mirtilos com rendimento20 entregam80, acima do silo3 de64. Um lote individual caber não garante retorno satisfatório após preparar a horta toda. Pode ser aceitável colher aos poucos no avançado, mas não deve ser a regra toda vez nem surpreender logo na cultura nova. Maior produção por coleta melhora a ausência e simultaneamente piora o espaço; validar em conjunto.

**Dimensionamento por necessidades, em vez de número redondo:**

`capacidade de aprendizado >= reserva para objetivo ensinado + entradas do próximo lote relevante + folga de uma coleta comum`.

A fórmula é heurística nossa, não garantia universal: partes das entradas podem ser consumidas antes da coleta e cadeias paralelas exigem simulação. Quantificar por categoria. Uma condição mínima de segurança é conseguir reunir os insumos da própria ampliação ou entregá-los parcialmente em um destino finito.

**Introdução recomendada:**

- Silo: já há um cesto/depósito pequeno desde a primeira cenoura, com indicador discreto. Missão de venda demonstra saída; reparar o silo dá folga visível. Apresentar ampliação antes de exigir que a horta lotada bloqueie a missão.
- Geladeira: limite já existe na primeira comida guardada; a cozinha apresenta sua função. Considerar uma geladeira pequena recuperada como parte da compra/inauguração da cozinha, em vez de impor duas compras sequenciais só para fazer a primeira receita.
- Armazém: pequena área de materiais desde a primeira busca; a missão de construí-lo acompanha a descoberta da Natureza. Evitar que o jogador precise desbloquear a Caverna, juntar madeira e pedra e construir bancada só para entender onde guardar a primeira madeira.
- Baú: introduzir junto a um conjunto coerente de materiais de passeio/costura, quando há uso suficiente. Não converter achados de álbum ou pistas raras em lixo a descartar. Coleções conquistadas e peças essenciais ficam protegidas.

**Alternativas estruturais a comparar:**

A. Manter quatro depósitos internamente, mostrar apenas categorias já usadas, sempre na Mochila central. Vantagem: preserva a base do jogo; risco: o jogador não entende por que uma prateleira vazia não aceita algo que cabe fisicamente.

B. Dois grupos de gestão no começo (horta e demais consumíveis), especializar apenas quando o conteúdo justificar. Vantagem: menos conceitos. Risco: migração e redistribuição de espaço são mais complexas; não fazer só para imitar Hay Day.

C. Quatro depósitos narrativos, com primeiras capacidades concedidas pela apresentação do sistema; as melhorias seguintes são decisões econômicas. Minha preferência inicial para experimentar, por aproveitar a base e evitar uma sequência de taxas de admissão. Capacidade finita desde o início continua atendida.

**Estoques provisórios/entrepostos:** nome visual de capacidade finita, não uma segunda carteira infinita escondida. Caixa postal para prêmio inevitável pode proteger recompensa, mas não deve virar destino manual de produção. Entrega parcial de projeto pode aliviar material, desde que o projeto seja finito, não reembolsável para armazenar indefinidamente e tenha progresso legível.

**Três saídas amigáveis quando encher:** usar/transformar no objetivo já aberto; vender o excedente com quantidade e valor claros; ampliar por caminho alcançável. A interface pode sugerir a ação correspondente àquele item, mas não vender automaticamente. Preparar produto e deixá-lo na origem deve preservar o trabalho; nunca consumir insumos de novo ao tentar coletar. Levar em conta saídas das estações, não só o estoque visível.

**Risco de integração identificado pelo coordenador:** a coleta do passeio passa pela capacidade, e `walking()` só deixa de valer quando o passeio é retirado. Ao passar materiais de passeio para um baú limitado, o jogador pode ficar sem o cachorro em casa porque não cabe um graveto. A proposta precisa separar retorno afetivo de retirada dos produtos: Tiro volta quando termina o passeio; uma única bagagem pendente conserva os itens. Não abrir novo passeio acumulável até resolver a bagagem, para ela não virar estoque infinito. Cuidado básico continua disponível. Isso é uma alternativa de desenho a validar, não implementação. [GameState](../../game/autoload/game_state.gd).

**Qualidade de uma ampliação:** mostrar antes/depois e o benefício concreto: agora cabe outra colheita ou uma reserva para dois pedidos. Se a compra imediatamente libera produção suficiente para ocupar toda a capacidade nova, a ampliação não concede sensação de alívio; separar esses marcos ou ajustar escala.

**Testes concretos antes de fechar valores:**

- Primeira horta com jogador que colhe tudo e ainda não vendeu.
- Compra do silo com as reservas da próxima missão mantidas.
- Primeiro retorno de 8h com horta e fila prontas.
- Inventário cheio com produto essencial aguardando e sem moedas para ampliar.
- Capacidade menor que o save legado, mantendo consumo e venda possíveis.
- Compra de mais canteiros/animal antes da ampliação de depósito.

### Gaps

- Não sabemos se quatro grupos confundem o público real. É hipótese de carga cognitiva, não resultado de experimento.
- O portal oficial Supercell oscilou entre redirecionar/retornar corpo vazio; regras acima foram obtidas no texto indexado da página oficial espanhola e corroboradas por outras línguas do mesmo suporte. Não usei a wiki como regra oficial nem validei capacidade inicial 50 nessa fonte.
- Ainda falta traçar todos os lotes multidepósito e validar a ordem de consumo e coleta em cada ação.

## 3. Que expansão dá profundidade, e o que não devemos copiar das referências F2P?

### Takeaway

Mais conteúdo é útil quando altera escolhas e deixa consequência visível. Expandir só preços, contadores e requisitos de desbloqueio cria uma campanha mais longa no relógio, mas a mesma tarefa repetida. Referências comerciais explicam também como fabricar escassez para vender conveniência; isso precisa ficar fora dos objetivos do Tiro.

### Cited Findings

- **Interpretação de terceiros de 2020:** a análise de Township atribui legibilidade a receitas familiares e descreve aumento de complexidade combinando instalações novas e conhecidas; o crescimento da cidade fornece progresso visual. Também distingue pedidos com recompensas em moedas/XP e rotas que trazem materiais. São observações históricas do autor, não regras atuais nem causalidade demonstrada. [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/2020/10/13/how-playrix-township-became-a-billion-dollar-game).
- **Interpretação de terceiros de 2021:** a análise de Everdale critica pesquisa linear que acrescenta uma cobrança entre desbloquear e construir, falta de especialização e demanda excessiva de atenção. Também relaciona gargalos, pedidos com prazo e pressão social à venda de conveniência. Não adotar a crítica como diagnóstico experimental de todos os jogadores nem extrapolar monetização atual. [Deconstructor of Fun](https://www.deconstructoroffun.com/blog/2021/8/29/everdale-by-supercell).
- **Fonte primária atual:** suporte de Hay Day descreve máquinas começando com 1–3 vagas, expansão com diamantes, experiência de maestria medida em horas e estrelas com benefícios como tempo, moedas ou XP; aparência pode mudar no máximo. [Production Buildings](https://support.supercell.com/hay-day/en/articles/production-building.html).
- **Fonte primária atual:** ofertas personalizadas fornecem os materiais exatos que faltam para expandir silo/celeiro e aplicam a melhoria ao comprar. Demonstra vínculo concreto entre a escassez de expansão e o comércio do jogo. [Upgrade Offers](https://support.supercell.com/hay-day/en/articles/upgrade-offers.html).
- **Fonte primária, comunicação da empresa em junho de 2026:** Supercell apresenta Hay Day como espaço seguro em que animais não morrem e árvores podem ser recuperadas. Não significa ausência de todo custo de oportunidade; confirma a intenção acolhedora declarada. [Supercell](https://supercell.com/en/news/nothing-bad-happens-in-hay-day/).
- **Dado local:** Bosque/Prado têm XP local0/30/90 e10 por coleta; Caverna0/40/120. Vagas crescem1/2/3, junto à abertura de materiais. Contar só coletas incentiva a mais curta, independentemente de objetivo. [Natureza](../../game/data/progression.json).

### Inferences

**Separar quatro benefícios das melhorias:**

1. **Capacidade:** guardar/preparar mais antes de voltar.
2. **Eficiência:** usar menos insumos/tempo para uma tarefa, com cautela porque compõe multiplicadores.
3. **Variedade:** nova receita com função e demanda próprias.
4. **Expressão:** novo aspecto, lugar ou relação que não é requisito obrigatório.

Cada etapa pode destacar um deles. Não dar simultaneamente mais vagas, mais rendimento, mais moedas e menos tempo em toda evolução: o crescimento composto acelera demais e torna antigos desafios irrelevantes. Tampouco remover toda melhora produtiva; o jogador precisa sentir resultado. Uma fila extra é particularmente coerente porque muda a autonomia sem tornar cada segundo da estação mais valioso.

**Propostas concretas de profundidade horizontal, aproveitando o existente:**

- Clientes com preferências previsíveis: um valoriza cesta simples, outro produtos preparados, outro materiais. O jogador escolhe qual atender para o objetivo atual. Evitar pedidos que sempre peçam o item exato que acabou de vender.
- Um projeto comunitário com duas ou três contribuições alternativas. Exemplo: o piquenique pode ser ajudado pela cozinha ou por uma peça de oficina, seguido de um momento do Tiro e dos personagens no lugar pronto. A escolha muda esforço e narrativa; não é necessário exigir ambas para o mesmo marco.
- Reutilizar ingredientes antigos em demandas novas antes de criar culturas. Trigo pode sustentar animais, farinha e comida; a escolha é como distribuí-lo. Não multiplicar itens apenas para preencher cinco níveis de cada estação.
- Melhorias opcionais de organização: fila maior versus espaço maior versus nova receita. O jogador deve conseguir avançar pela escolha preferida e adquirir as demais depois; a missão principal não manda comprar todas imediatamente.
- Maestria por experiências relevantes: usar receitas variadas que já tenham demanda. Contador bruto de75 lotes pode premiar fabricar a receita mais barata sem necessidade. Um título/visual funciona melhor quando celebra um percurso já vivido, não quando exige repetição sem destino.

**A festa e as reformas da V0 são boas hipóteses**, mas seis produtos + três projetos + novos níveis não estão automaticamente justificados. Testar primeiro uma reforma curta e uma cadeia com produto novo. Verificar se muda escolhas, se os insumos antigos continuam úteis e se o jogador reconhece sua contribuição no cenário. Expandir após esse ciclo demonstrar valor.

**Não transplantar:** moeda premium para corrigir gargalos, prazos que apagam pedidos, energia global, calendário que exige dias consecutivos, materiais de expansão exclusivamente aleatórios, presença obrigatória para não perder produto, pet usado para culpa, mercado volátil para impor a hora de vender. O Tiro pode ter desafio de planejamento sem nenhum desses mecanismos.

**Divergências explícitas de V0/dossiê:**

- Não assumir cobrança por semente só para adicionar gasto de moeda; o plantio gratuito atual é uma saída de recuperação simples. A pesquisa não invalida essa escolha.
- Não atrelar evolução afetiva a idade mínima e seis refeições por janela24h como no MVP do dossiê; isso acrescenta calendário e pode incentivar alimentar artificialmente. O Tiro já tem vínculos/truques/coleções próprios.
- Não fazer a demanda fisiológica do Tiro absorver toda a produção agrícola: a barriga decai8/h na configuração atual, muito abaixo da capacidade de produzir unidades. A solução coerente são destinos variados (amigos, comunidade, transformação e venda), não aumentar fome ou recompensar sobrealimentação. [Configuração](../../game/data/config.json).
- Não adotar infraestrutura de servidor do dossiê para um jogo local offline: atomicidade de ações e consistência continuam importantes, mas um backend não é requisito para estudar ritmo.
- Não forçar maestria5, depósitos5 e campanha24dias porque esses números já apareceram no rascunho. O desafio deve surgir dos objetivos e escolhas, não do número de degraus.
- Retirar dinheiro automático de colheita é hipótese forte de coerência e fluxo; ainda precisa ser testada junto à venda inicial e aos preços. Não tratar a soma das mudanças de V0 como pacote aprovado.

### Gaps

- Artigos de2013/2015/2020/2021 refletem versões históricas. Não utilizar suas receitas, preços, prazos e métricas como informação atual.
- Maestria, projetos e especializações sugeridos ainda precisam provar valor na experiência real; não sabemos o custo de arte/conteúdo que produzirá melhor resultado.
- A página oficial de produção e a de ofertas tiveram corpo vazio em abertura direta, mas retornaram texto completo indexado em busca. Há evidência oficial para as regras citadas, não inspeção do cliente de Hay Day.
- Não há justificativa empírica para encurtar ou alongar a campanha em X%. Próximo passo recomendado ao coordenador: síntese das hipóteses e um pequeno conjunto de experiências comparáveis antes de reabrir as etapas de implementação.
