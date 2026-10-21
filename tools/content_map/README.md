# Atlas do Tiro

Painel **local**, para explorar como o conteúdo atual se conecta e planejar seu ritmo.
Lê os JSONs em `game/data` diretamente. Não executa simulações, não usa um save e
não muda o balanceamento. Somente o arquivo de metas do Atlas pode ser editado.
Não depende de Godot, npm, serviços externos ou MCP.
Requer Python 3.9+ (o mesmo `py` usado nas ferramentas de economia).

## Abrir

Na raiz do projeto:

```powershell
py -X utf8 tools/content_map.py --open
```

Abre `http://127.0.0.1:8765/`. Deixe o terminal aberto; `Ctrl+C` encerra.
Porta ocupada: acrescente `--port 8766`.
Alternativa: `powershell -ExecutionPolicy Bypass -File tools/content_map.ps1`.
O servidor escuta apenas no computador local e serve somente a interface,
os JSONs e as imagens do projeto.

## Usar

- **Catálogo:** busca por nome ou ID (ignora acentos), categoria e quantidade de conexões.
- **Mapa:** clique numa peça para torná-la o foco; arraste o fundo, aproxime com a roda
  ou com +/− e use Enquadrar. Também é possível selecionar cartões com Tab/Enter.
- **Filtros:** produção/materiais, missões/desbloqueios, locais e prêmios/usos;
  origens/destinos e alcance de uma a três ligações.
- **Contadores:** opcionais no mapa, sempre acessíveis no catálogo e no detalhe.
  Ative para ver, por exemplo, os lotes recolhidos que uma missão exige.
- **Lista:** alternativa ao grafo, útil em telas pequenas ou com muitas ligações.
- **Detalhe:** quantidades, tempo base, custo, requisitos, destinos, recompensas,
  arquivo de origem e definição JSON completa.
- **Atualização:** verifica os arquivos a cada três segundos enquanto a aba está
  visível; novos registros e alterações aparecem automaticamente. Atualizar força
  a releitura. Se um JSON estiver inválido durante a edição, mostra o erro e mantém
  a última leitura até o arquivo ser corrigido.
- O endereço com `#item%3Awood`, por exemplo, guarda o elemento selecionado.

## Economia: tela inicial

### Crescimento e relatórios recentes (20/10/2026)

O Atlas também encontra `build/economy/quick/<data>/*/summary.json` e outras
pastas de jornadas, além das etapas. A seleção inicial usa o lote com o relatório
mais recente por data de modificação. Pastas iniciadas por `_` ou `.` são ignoradas;
perfil, horizonte, revisão e semente continuam separados.

As fases do Tiro aparecem no diário, nas conquistas e nas metas de tempo. O resumo
mostra fase final, Pelagem de seda e nível/pontos finais dos quatro pilares.
As datas de `growth_days` são aproximadas (dias arredondados pelo simulador), sem
inventar sessão ou conquista ausente. Execuções Quick sem `ledger.jsonl` mostram
os marcos e o estado final disponíveis; fluxos diários e movimentações de materiais
continuam indisponíveis. Para medir as regras atuais com esses detalhes é preciso
gerar outra simulação com ledger; abrir o Atlas não inicia essa execução.

Conexões inclui as fases e seus presentes, refeições, entregas de itens-chave,
pilares e fontes, patamares de seda, fotos do álbum e decorações da Casa. Fotos e
decorações têm suas definições completas; as ligações específicas cobrem crescimento
e melhorias, sem interpretar todos os gatilhos do álbum. Itens e receitas novos
continuam entrando automaticamente pelos JSONs. O aviso de relatório histórico
permanece quando os JSONs mudaram desde a simulação.

A navega??o come?a em **Economia**, com vers?o do relat?rio, perfil, objetivo e
semente expl?citos. Cada jornada ? independente. Clique numa semana para filtrar
as tr?s ?reas: **Conquistas e tempo**, **Moedas**, **Recursos e dep?sitos**.

- Conquistas: compras, cap?tulos e obras, com busca e filtros para miss?es,
  primeiro preparo, primeira aquisi??o e mundos. Cada cart?o mostra semana/dia,
  tempo ativo acumulado e horas corridas. O clique abre as conex?es atuais.
- Moedas: curva do ?ltimo saldo observado por dia (tamb?m acess?vel como texto),
  entradas/sa?das e a??es associadas no per?odo. A classifica??o cont?bil original
  do resumo fica dispon?vel para a jornada inteira.
- Recursos: entradas e sa?das por item, usos registrados e maior ocupa??o observada
  dos dep?sitos. Esperas dentro das sess?es aparecem separadas dos timers/aus?ncias.

O adaptador `tools/content_economy.py` l? os ledgers existentes e reconcilia as
varia??es sucessivas do saldo, inclusive fora das a??es (por exemplo, volta de passeio).
Entradas/sa?das s?o l?quidas por evento e podem incluir pr?mios autom?ticos. N?o
confundir fluxo de itens com estoque nem ocupa??o cheia com bloqueio confirmado.
Aus?ncia de ledger ? indicada, sem inventar economia zerada. Os nomes/?cones e
conex?es v?m do jogo atual; os tempos pertencem ao relat?rio selecionado.

Novos relat?rios nas etapas existentes e novas etapas aparecem na releitura a cada
10 segundos com a tela ativa. Altera??es nos JSONs mudam a indica??o de validade;
n?o recalculam simula??es antigas. Nenhuma simula??o ? iniciada pelo painel.
Novos registros nos formatos conhecidos aparecem automaticamente; sistemas novos
exigem ampliar o adaptador. Teste: `py -X utf8 tools/content_economy_test.py`.

### Di?rio: vis?o principal dos dias

A entrada principal ? **Como foram os dias**. Cada cart?o di?rio re?ne tempo ativo,
quantidade de a??es, miss?es, marcos e saldo. O clique foca o resumo do dia;
**Acumulado at? aqui** soma do in?cio at? o fim desse dia, inclusive fora da semana
vis?vel. Resumo geral da jornada, a??es menos frequentes e listas extensas ficam
recolhidos para facilitar a leitura.

A tabela de recursos mostra entradas, sa?das, varia??o e origens/destinos por a??o.
O clique abre barras dia a dia para aquele recurso e totais acumulados. Os n?meros
s?o unidades movimentadas em a??es bem-sucedidas, incluindo presentes e compras;
n?o representam estoque. Contagem de a??es tamb?m n?o ? n?mero de unidades, pois
h? a??es em lote. Tentativas recusadas s?o separadas. Dias sem conquista podem ter
atividade: o texto mostra essa diferen?a sem julgar automaticamente o pacing.
O acumulado termina no fim do dia, n?o no instante exato de um marco.

### Evolu??o entre dias e requisitos

Conquistas s?o agrupadas em uma trilha di?ria, com r?gua para saltar de dia e
expans?o dos dias com mais de seis marcos. O clique abre condi??es anteriores,
marco alcan?ado e pr?ximos elementos dependentes. Requisitos s?o naveg?veis,
inclusive fora do filtro; o mapa completo permanece dispon?vel.

Verde indica evento observado (miss?o, compra, obra ou consumo de material).
Condi??es sem instante comprovado ficam diferenciadas. Primeira aquisi??o n?o
comprova estoque nem quantidade. Em relat?rios de outro hash, registros de
progress?o s?o hist?ricos; as regras exibidas continuam sendo as atuais.
Compras usam `di`, `before` e `after` do ledger; o saldo inclui pr?mios autom?ticos.
Cap?tulos exigem todas as miss?es principais do cap?tulo, e n?o os pr?-requisitos
da entrada nele. A dist?ncia temporal entre registros n?o atribui causalidade.

## Metas de tempo

A aba **Metas de tempo** organiza marcos por tempo acumulado desde o início:
construções, missões, capítulos concluídos, obras, primeiras aquisições e preparos.
Clique numa linha para definir mínimo/máximo em **minutos ativos** e anotar a intenção.
**Salvar metas** guarda em `tools/content_map/pacing_plan.json`, separado dos JSONs do jogo.
As metas iniciais vêm de `docs/plans/economia/00_VISAO.md` e da seção E da `04_SIMULACAO_E_ACEITE.md`.
Marcos sem faixa documentada não recebem uma previsão inventada. A faixa da comunidade
é uma referência acumulada provisória; as obras atuais não comprovam a Festa futura.

A visualização principal é um **calendário semanal**, com segunda a domingo,
cartões com ícones, contagem por dia, expansão dos dias cheios e navegação entre
semanas. O primeiro dia da semana pode ser escolhido; os nomes são uma referência
visual, sem associar as conquistas a datas reais. Dia 1 representa as primeiras 24 h.
“Quando chegou” usa os dias de calendário dos relatórios existentes. “Onde queremos
chegar” distribui os prazos das metas pelo orçamento de sessões/minutos por dia:
o cartão fica no último dia da faixa e informa a janela quando cruza dias.
Uma meta de 30 min com orçamento de 30 min/dia fica no dia 1; 31 min no dia 2.
Essa conversão é planejamento de orçamento, não previsão de chegada no jogo.
Marcos sem registro/meta ficam em uma seção separada; dias sem cartões não
significam que o jogo ficou sem atividades. Busca, categoria e perfil filtram o
calendário. A tabela anterior fica na opção “Tabela”; relatório e contagens ficam
recolhidos. O editor de metas abre como painel lateral ao tocar num cartão, com
salvamento, fechamento por botão/fundo/Escape e navegação pelo teclado.
Os campos ficam bloqueados durante o salvamento; em caso de falha a mensagem aparece
no editor e a edição é preservada para tentar novamente. Os cartões de metas são
ordenados pelo prazo dentro de cada dia.

O painel apenas **lê relatórios já gravados** em `build/economy/etapa_*/*/summary.json`
e seus ledgers. Não conecta ao Godot nem executa novas simulações. O usuário escolhe
etapa, perfil e horizonte (`campaign`/`projects`/`days`). Execuções com violações ou
cenário de raro zero são excluídas; revisões e horizontes não são misturados.
Uma nova tentativa da mesma semente substitui a anterior. Jornadas interrompidas
contribuem apenas com marcos efetivamente alcançados; o estado final é informado.

Compras vêm de ações bem-sucedidas no ledger, não da suposição de que uma missão
completa significa uma compra recém-feita. O primeiro preparo de receita é o início,
não a coleta pronta. Capítulo concluído exige todas as suas missões principais.
O calendário de mundos sem evento explícito é derivado dos requisitos conhecidos,
apenas quando os JSONs coincidem com o relatório. Itens iniciais entram no instante
zero apenas nessa mesma condição.

Resultados continuam identificados como **SIMULADOS**: não são tempo humano nem
garantia. O hash reproduz `EconomySim.content_hash` (JSONs, inclusive salas e legado,
sem `version.json`). Diferenças desativam a avaliação do ritmo atual; igualdade de
JSONs não verifica alterações no código do motor/robô. Uma semente não permite
estimar variabilidade entre jogadores. Sem relatórios locais, as metas funcionam e
os tempos registrados ficam em branco. Os artefatos de build não vão para o git.

A conversão por sessões/dia é somente um **orçamento de tempo ativo**. Não prevê
dias de calendário: timers, disponibilidade e escolhas não entram nessa divisão.
Calendário registrado é mostrado em coluna separada e vem da execução existente.
O ponto do gráfico é a mediana; com várias sementes os valores mostram mínimo/máximo.
A escala horizontal é logarítmica para manter visíveis os primeiros minutos e as horas finais.

O módulo `tools/content_pacing.py` faz a leitura/comparação e valida as metas.
Releitura a cada 10 s com a aba ativa, preservando edições pendentes.

## Cobertura e interpretação

O adaptador em `tools/content_map.py` cobre itens, receitas, horta, estações,
animais, construções/ampliações, depósitos, missões, capítulos, atributos,
encomendas/contratos, mundos/lugares/NPCs, obras e fases, passeios, faro/conjuntos,
desejos, rotinas, coleção, compras, amigos, truques e presentes/marcos.
As configurações gerais também podem ser consultadas no catálogo.

Novos registros dos formatos existentes são lidos automaticamente. Novos sistemas
ou novos campos que expressem relações precisam de suporte no adaptador. O JSON
completo fica disponível para consulta; o painel não interpreta código GDScript
arbitrário. `legacy_r0.json` (migração congelada), `version.json` e o layout das salas
ficam fora do catálogo ativo.

Uma seta tem significado próprio: **consumir**, **produzir**, **recompensar**,
**precisar**, **guardar** ou **vir antes**. Sorteios são identificados por peso ou
condição; não representam produção garantida. Desbloqueios explícitos são uma
alternativa aos requisitos usuais. Metas `have` não são tratadas como consumo;
`deliver` são entregas; metas `fresh` mostram “após aceitar”.

A sequência das linhas e da história e a passagem de capítulo são derivadas de
`kind`, `line`, `chapter` e `order`, conforme `ProgressionState`. Os marcos
`shared_with` apontam para a missão que conclui junto, sem prêmio duplicado.
As relações derivadas têm `inferred: true` no JSON da API.

Todos os requisitos de uma definição podem ser simultâneos; os desbloqueios
alternativos e prêmios condicionais não devem ser interpretados como passos
obrigatórios. Tempo mostrado é **base**, sem calcular estufa, rega ou demais efeitos.
Não há inferência de disponibilidade atual para um jogador.

O mapa mostra no máximo 120 peças por foco para permanecer navegável e avisa
quando limita a expansão. O catálogo e o detalhe continuam oferecendo todas as
conexões diretas. Não há intenção de desenhar o catálogo inteiro sobreposto.

## Verificar

```powershell
py -X utf8 tools/content_map.py --check
py -X utf8 tools/content_map_test.py
node --check tools/content_map/app.js
py -X utf8 tools/content_pacing_test.py
node --check tools/content_map/pacing.js
```

A API `GET /api/graph` fornece nós, ligações, revisão e arquivos de origem.
`GET /api/revision` verifica alterações. `GET /api/pacing` lê metas e resultados existentes.
`POST /api/pacing/plan` grava exclusivamente o arquivo de metas do Atlas, com validação
de intervalos e origem. Nenhum endpoint muda conteúdo/save ou inicia o jogo.
