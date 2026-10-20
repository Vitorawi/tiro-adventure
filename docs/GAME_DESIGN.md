# Game Design
## O objetivo do jogo é o Tiro crescer (plano "Tiro no centro", fechado em 19/10/2026)

As pessoas entram para ver o Tiro evoluir; a fazenda, a vila e as construções existem para isso.
- **Fases:** Recém-chegado → Filhotinho → Dentinhos → Aventureiro → Mocinho → Azul e Dourado, casadas com os
  capítulos 1/3/6/9/12. Cada fase muda corpo, pelagem e jeito; a próxima aparece em silhueta. É sempre o mesmo cachorro.
- **Pilares:** Corpo, Pelagem, Esperteza e Coragem sobem com cuidados, comidas, passeios, obras e rotinas; cada
  fase tem teto e crescer abre o próximo. Para crescer ele também precisa de um item-chave do capítulo e de uma
  refeição da fase. O jogador aperta **Crescer!** quando quiser (cerimônia com antes e depois e risco na régua).
- **A fazenda serve ao Tiro:** ração de crescimento, mingau, xampu, mordedor, escova, lacinho; paladar e comida favorita.
- **Álbum:** 54 fotos em seis seções (história, primeiras vezes, travessuras, soninhos, amigos, datas), com dicas.
- **Casa que cresce:** régua, prateleira de lembranças, caminhas, tigela, cesto e fotos penduradas.
- **Jeito próprio** (Explorador, Comilão, Brincalhão, Dengoso, Tranquilo) e, no adulto, a Pelagem de seda I–III.
- **HUD:** avatar e anel mostram o crescimento; o nível do jogador deixou de existir para quem joga.
Detalhes: `docs/plans/tiro/00_VISAO.md` e `docs/PROGRESSION.md`.

## Tiro no centro — etapa 11: a história é o crescimento (19/10/2026)

A história principal agora gira em torno do Tiro: a Laís conta que ele chegou assustado, "tremia na caixinha", e
cada arco termina com ele crescendo — Filhotinho no fim do capítulo 1, Dentinhos no 3, Aventureiro no 6, Mocinho
no 9 e Azul e Dourado no 12. A última missão de cada arco é "o Tiro chega à fase" e o capítulo seguinte só abre
quando ele cresce. A vovó Bloblo fala de comida (argolinha, ração com ovo, mingau), a Nina de passeio e coragem,
o Feirante de clientes que perguntam pelo Tiro, o Guia de natureza e energia. Truques e passeios longos chegam
quando ele tem idade ("Quando ele for Aventureiro"). O capítulo 12 termina com a homenagem à Smoky (a Yorkie que,
em 1944, passou um cabo por um cano de 20 m) na Festa e, depois do Azul e Dourado, o capítulo final.

## Tiro no centro — etapa 07 (19/10/2026)

O HUD mostra o retrato e a pelagem da fase, anel por fração de requisitos concluídos e número da fase
(Recém-chegado = •; demais 1–5). O avatar pronto pulsa; Menos animação desliga o pulso. Toque abre
nome da fase, quantos requisitos faltam e Ver → painel Crescimento. Nível/XP/atributos do jogador
saíram da interface, inclusive prêmios, lista de saves e ferramentas DEV. `level` fica congelado;
`xp`/`skills` são contadores internos preservados para snapshots/testes/simulador, sem presentes ou avisos.
`Events.level_up` não é emitido; `Celebration.show_level` e sua conexão na casca foram removidos.
`features.skills` foi removida; a antiga entrada `skills_panel()` encaminha ao Crescimento.
`treat_box` exige `growth: explorer`, mantendo bancada e geladeira. Rotinas de cuidado dão Coragem 4,
banho Pelagem 4; Banco/Jardim/Piquenique/Festa dão Coragem 5 pela ação única `_grant_automatic`.
Radiante e reserva seguem `_gain_pillar`. Os demais XP ficam internos, inclusive Encontro da turma.
XP/níveis locais da Natureza continuam válidos. Nenhum preço foi alterado: presentes de nível deixam
de entrar; os cinco presentes de fase já existentes somam 590 moedas. Conferência econômica só na 17.


## Voz do jogo (Interface nova — Etapa 11)
Curta, calorosa, falando com o jogador, no presente. Sem "·" juntando frases, sem "Conclua:", sem abreviações ("Nv", "Máx."), sem "x0" e sem número de capítulo (mostre o nome). Um verbo por ação:

| Situação | Usar | Não usar |
|----------|------|----------|
| Pegar planta madura | **Colher** | Recolher, Coletar |
| Pegar o que ficou pronto (fogão, animais, natureza, passeio, presente) | **Pegar** | Recolher, Coletar, Receber |
| Pegar todos de uma vez | **Pegar tudo (3)** | Coletar prontos (3) |
| Fazer no fogão/liquidificador | **Cozinhar** | Produzir, Preparar |
| Fazer na bancada/moinho/queijaria | **Fazer** (costura: **Costurar**; animais: **Alimentar**) | Produzir |
| Começar uma coleta na Natureza | **Buscar** | Coletar |
| Prêmio de missão | **Pegar prêmio** | Receber |
| Comprar construção | **Construir** (moedas) / **Comprar** (animais, roupas) | |
| Ampliar espaço | **Ampliar** (áreas do sítio: **Abrir área**) | Expandir |
| Ir até o lugar | **Ir** | Ver, Ir até lá |
| Explicação | botão **?** | Ajuda |
| Fechado | cadeado + "Depois de: <passo>" / "Abre em: <capítulo>" | "Fechado · Conclua:" |
| Fila | "Na fila" | |
| Pronto | "Pronto!" ("1 pronto!", "3 prontos!") | "Concluído" |

Números: `3/6` é meta, `×3` é quantidade de um item, `+20` é ganho; tempo pelo `TimeText`. Nunca `×0`. Erros curtos e com o que fazer: "Falta Cenoura ×2" (`GameState._missing_text`). Mensagem de sucesso que repete a animação (plantou, preparou, vendeu, comida dada) não aparece. As falas da história (`dialogue`, `introduction`, `greeting`) não foram reescritas. A guarda é `tests/texts_test.gd`; a lista de todos os textos sai de `tools/list_texts.ps1` (`build/texts.csv`).

## Interface do cantinho do Tiro (Interface nova — Etapa 09)
O cenário original ocupa a largura toda, sem moldura lateral nem deformar a arte; Tiro e sombra ficam sobre o tapete. Quatro necessidades em anéis e o coração de vínculo ficam na mesma fileira, sem o nome Tiro acima; o caderninho flutua à direita. A faixa de cuidados flutua acima das abas: Comida, Banho, Brincar e Dormir/Acordar usam o mesmo círculo, tamanho e alinhamento.

Comida abre uma guia vertical com até cinco opções visíveis e rolagem para todas as comidas da mochila. As mais usadas vêm primeiro (contadores existentes), com desempate pelo uso recente da sessão; coração indica o pedido. Tocar alimenta; arrastar pelo ícone só entrega ao soltar na cabeça. Arrastar pelo nome rola a guia. O desejo usa o mesmo caminho do “Ele quer!” e alimenta uma vez. Esfregar a esponja e arremessar a bola também têm toque simples equivalente. Dormindo só Acordar funciona; passeando a faixa dá lugar ao postal. Carinho direto permanece.

O caderninho abre Manual por padrão, com Crescimento/Coleção/Truques revelados conforme o progresso. Luz acompanha a hora local, sono tinge a tela, humor aparece em balão temporário e o desejo continua tocável. Nada altera regras, custos, tempos ou save.


## Listas (Interface nova — Etapa 10)
Missões mantém a História como cartão com pontinhos dos passos, nome do capítulo, miniatura do destino e progresso. Diárias e semanais usam linhas compactas com anel, instrução inteira, prêmio e Ir/Pegar; as recebidas saem da lista. Com duas ou mais rotinas prontas, um único **Pegar tudo (N)** recebe diárias e semanais elegíveis, sem repetir recompensas. A História e as outras linhas usam ações secundárias enquanto esse principal aparece.

Desejos mantém retrato e vínculo no cabeçalho, troca no canto, ajuda e Ir/Dar/Pegar conforme o estado. Só o primeiro pedido cumprível usa o botão principal; os demais continuam tocáveis como ações secundárias. Espaços fechados mostram o vínculo exigido; espera mostra anel e tempo.

Mochila mostra os depósitos construídos em linhas com nome, ícone próprio e capacidade. Tocar filtra os itens daquele depósito; tocar de novo volta a todos. Filtros segmentados com ícones rolam na horizontal e aparecem só para categorias presentes (Tudo, Comidas, Colheitas, Materiais, Produtos, Achados, Passeio). Uma grade de quatro colunas substitui as seções empilhadas. O selo Novo dura a abertura e usa as marcações opcionais `ui:bag:<item>`, sem migração. Item sem quantidade fica fora da grade; o detalhe diz “Você não tem”. Comida no detalhe compartilha `SheetBuilder.give_food` com os cuidados, preservando desejo e consumo único; vender continua na feira.

Coleção usa abas segmentadas Roupas/Achados/Amigos. Roupas e Amigos têm três colunas; Achados conserva o álbum por mundo. O contador usa barra fina. Tocar numa roupa possuída veste/tira, com check na vestida; a origem das bloqueadas fica no detalhe. Só roupas com arte de sobreposição entram na grade e no denominador. A Home e seu cenário continuam como foram ajustados com o Vitor na Etapa 09.


## Interface (Interface nova — visão geral e Etapa 12, festa)
**O mundo é a tela.** Casa, Sítio, Praça, Vila e Natureza ocupam a tela inteira, com céu, paisagem e chão atrás da maquete; o HUD (avatar do Tiro com anel de crescimento, moedas, engrenagem), a pílula do mundo e as abas flutuam por cima. A câmera arrasta com inércia, aproxima por pinça ou duplo toque e volta ao enquadramento por um botão. A aba Mapa abre no último mundo; trocar de mundo é pelo carrossel (a pílula) e a viagem cobre a tela com nuvens de papel.

**A bandeja fica ao lado do dedo.** Plantar, regar, cozinhar, fazer, alimentar animais e iniciar buscas na Natureza usam uma bandeja pequena perto do alvo, sem tirar o mundo da vista; o painel grande continua para consulta ("Ver tudo"). **Arrastar** a semente ou o regador por vários canteiros age em todos de uma vez. **Coletar no mapa só coleta:** planta madura, estação/criação, Natureza e pomar prontos entregam os produtos sem abrir bandeja nem painel depois. O balão mostra o anel de progresso e o "pronto" pulando; tocar nele pega/colhe na hora.

**O Tiro tem o próprio cantinho.** Quatro anéis de necessidade e o coração de vínculo; quatro cuidados iguais (Comida, Banho, Brincar, Dormir) por toque ou arrasto; o **caderninho** flutuante guarda Manual, Crescimento, Coleção e Truques.

**Quando se ganha algo, o jogo comemora.** Todos os cartões de comemoração (nível, capítulo, tesouro, vínculo, achado, truque, "Novo!", volta do passeio, roupa nova, boas-vindas) usam o mesmo `ModalCard`: fundo escurecido, cartão que salta, **fita** colorida com o título, ícone grande com **raios** girando devagar, prêmios em chips que entram um por um e **números que contam**, um botão verde e, às vezes, uma ação fraca. **Confete** (40 pedacinhos coloridos, uma vez) só nos grandes momentos: nível, capítulo, tesouro, vínculo e raro/lendário do passeio; o "Novo!" simples fica sem, para não banalizar. O celular **vibra de leve** (toque no canteiro do arrasto, colher/pegar, forte em nível/capítulo/tesouro/raro, duas batidinhas no "não dá"; iPhone/Safari ignora vibração na web).

**Configurações do aparelho** (engrenagem → "Jogo"): **Vibrar** (Sim por padrão) e **Menos animação** (Não por padrão; zera os tempos das animações e desliga confete e raios girando). Valem para todos os saves e ficam em `settings.json`, não no save.

**Boas-vindas agrupado.** Ao voltar, o presente do dia fica em destaque no topo; embaixo vem **uma linha por tipo**: "3 achados" (com o ícone de cada mundo em fileira), "2 prontos no Sítio" (canteiros, estações e coletas do mesmo mundo juntos), visita de amigo e passeio. Tocar na linha (ou em Ir) leva ao primeiro.

## Faro do Tiro (Etapa 05, 14/10/2026)

O Tiro fareja sozinho: de tempos em tempos aparece um montinho com brilho no chão do mapa (sítio, vila,
natureza e, depois, a praça), no máximo um por mundo. Tocar no montinho faz o Tiro cavar e rende um
achado (moedas, comida ou um objeto do álbum). Os primeiros achados de cada mundo são garantidos e o
último deles é um pedaço do mapa do tesouro. O álbum (Coleção → Achados e Mochila → Achados) agrupa os
achados por mundo; completar o conjunto de um mundo dá moedas e, às vezes, um apetrecho. Nada vence nem
some: o montinho espera. Dados em `finds.json`; `dig_spots` das salas dizem onde ele pode aparecer.

## Praça e passeios (Etapas 06–07, 14/10/2026)

Depois da Vila (primeira encomenda entregue) abre a **Praça**, entre Sítio e Vila no Mapa. A Nina,
adestradora, passeia com a Pipoca (vira-lata caramelo, só enfeite por enquanto). Conversar com a Nina
abre a missão do primeiro passeio. No portão **Passeio** o jogador manda o Tiro passear: ele gasta
energia, **sai de casa** (some dos mapas; a tela do Tiro mostra o postal com ele andando) e volta
quando o tempo acaba. Recolher mostra o cartão "Volta do passeio" com achados, moedas e vínculo. Ele
volta mais feliz, um pouco cansado e sujinho (laço com o banho). Não há punição: dá para chamar o Tiro de
volta (devolve a energia, sem prêmio). Só um passeio por vez.

Sete caminhos abrem por passeios feitos, vínculo e Bosque aberto. O Pôr do sol só começa das 17h às 21h
(hora do aparelho); pode ser recolhido depois. O painel mostra os liberados e dois próximos bloqueados.
Cada caminho tem postal, materiais e apetrecho raro próprio. A primeira volta garante materiais; o raro
vem por sorte ou em até 6–12 voltas daquele caminho, sem perder a garantia ao fechar o jogo. Duplicados
viram moedas e materiais. O Diário (após 3 passeios) mostra silhuetas, histórico e quantas voltas faltam
para a garantia. Raros ficam na Coleção; vestir e costurar ficam para a Etapa 08. Materiais vão para
Mochila → Do passeio, sem ocupar depósitos. Hortelã + cenoura rendem petisco no fogão após a Clareira.


## Desejos do Tiro e vínculo (Etapa 03, 14/10/2026)

Depois da caminha, a aba Desejos aparece entre Tiro e Mapa. O primeiro pedido é 3 carinhos.
Um espaço abre com a caminha, outro com vínculo 2 e o terceiro com vínculo 4. Pedidos não vencem;
trocar é grátis e espera 5 min. Cumprir dá moedas e afeto, com festa do Tiro; o próximo chega em
1 min nos três primeiros cumpridos e em 10 min depois. Necessidades baixas têm prioridade.

Cartões mostram ícone, progresso e recompensa; Dar entrega uma comida, Pegar conclui ações,
Ir e ? levam ao cuidado ou à origem do alimento. O seletor de comida põe primeiro o pedido com
"Ele quer!": Dar ali também cumpre o desejo. Alimentar diretamente por outras ações só alimenta.
Balão no mapa e na tela Tiro abre Desejos; some dormindo. Badge conta os pedidos prontos.

Vínculo usa o afeto acumulado, fica visível nas duas telas e entrega presentes uma vez por nível.
O chip mostra a barra, próximo presente e liberações. A partir do vínculo 3, há 5% de chance de
um pedido especial elegível, com borda dourada e prêmio dobrado. Nesta etapa entram carinho,
brincar, banho, qualquer comida, cenoura, petisco de cenoura e ensopado especial; alimentos,
passeios e apetrechos das próximas etapas ficam para elas. Diária: 2 desejos; semanal: 12,
com Coleira de coração na coleção (ainda sem sprite de vestir).

## Natureza: evolução dos locais (13/10/2026)
Desbloqueie Bosque, Caverna e Prado com moedas. Depois, cada busca recolhida dá o XP **da rota escolhida**
(buscas curtas 2 XP, médias 8–16, longas 26–60), com patamares de 24/120/360 XP. Os novos
materiais vêm do nível do local, sem comprar ferramentas: cobre na Caverna 2, madeira dura no Bosque 3 e
cristais na Caverna 3. A segunda vaga entra no nível 2 e **a terceira só no nível 4**. Material tocado mostra as rotas
que já valem (duração, saída e XP) e o jogador escolhe quanto tempo ficar fora; nada troca sozinho. Até três
buscas simultâneas por local. O atalho Refinar leva às receitas/estações existentes.
Custos, vagas e requisitos: docs/PROGRESSION.md e data/progression.json.


> Documento vivo. Itens marcados **(proposta)** são sugestões ainda não decididas.
> Imagens de referência ficam em `docs/references/`.

## Conceito
Um **bichinho virtual** (cuidar do **Tiro**, um Yorkshire Terrier) misturado com **produção em cadeia
estilo Hay Day**: o jogador planta, colhe, cozinha e fabrica coisas em vários ambientes para cuidar
do Tiro, cumprir missões de personagens e desbloquear novos lugares.

## Plataforma e tela
- Celular **em pé**, ocupando a tela inteira (base 360×780, formato dos celulares atuais; estica
  para qualquer aparelho sem faixas pretas).
- Jogado no navegador / instalado como app (PWA).

## Princípio de interação: 100% toque
- **Sem controles de movimento.** O jogador não anda com o Tiro.
- O **Tiro vive sozinho**: anda, deita, brinca, reage, de forma autônoma.
- O jogador **toca nas coisas**: geladeira abre a geladeira, horta mostra o que plantar, fogão
  mostra receitas, Tiro mostra carinho/necessidades.
- **Arrastar para mover a câmera** pelo ambiente (ex.: andar pelo apartamento); pinça para zoom (a confirmar).
- Alvos de toque grandes, poucos passos por ação, feedback visual imediato.
- Ações frequentes ao alcance do polegar (parte de baixo da tela).

## As duas visões
### 1. Tela do Pet (close-up)
- Tiro **grande e detalhado** em pixel art, com as coisinhas dele (cama, pote, brinquedos).
- Mostra as necessidades e a customização; permite interagir: alimentar, carinho, brincar, banho...

### 2. Mundo (ambientes)
- Pixel art **menos detalhada**, visão 3/4 isométrica do ambiente com o Tiro pequeno andando por ali.
- É onde acontece a **produção**. Ambientes desbloqueados aos poucos (ver "Áreas e desbloqueio").
- Cada novo ambiente traz **personagens (NPCs) que dão missões**.

## Dois níveis de sprite (proposta)
| | Tela do Pet | Mundo |
|---|---|---|
| Tiro | Grande e detalhado (~128px), mostra customização | Pequeno (~32px), versão simplificada |
| Comportamento | Reage ao toque (carinho, truques) | **IA autônoma**: passear, cheirar, deitar; vai até a tigela com fome; dorme no sofá quando cansado |
| Pessoas | Retrato detalhado + diálogo | NPCs pequenos parados/andando |

- Regra vale para pessoas: **NPC pequeno no mundo, toque abre retrato detalhado + diálogo**.

## Personagens (proposta)
| Personagem | Onde | Papel |
|---|---|---|
| **Tutor** (o próprio jogador/dono) | Dentro de casa | Toque abre retrato com diálogo, dicas e missões da casa |
| Vizinha jardineira | Horta | Missões de plantio/colheita |
| Padeiro / cozinheira | Padaria / feira | Pedidos de comida, compra de produtos |
| Costureira | Ateliê | Customização, roupinhas |
| Veterinária | Clínica | Cuidados, saúde, banho |
| Treinador | Parque | Ensina truques via minigames |

- Cada um **destrava junto com sua área** e entrega missões.

## Áreas e desbloqueio (proposta)
| Área | Nível | O que tem | Personagem |
|---|---|---|---|
| Casa (início) | 1 | Geladeira, fogão, tigela, sofá, TV, cama | Tutor |
| Horta | 2 | Canteiros | Vizinha jardineira |
| Parque | 4 | Passeio, minigames | Treinador |
| Ateliê de costura | 6 | Tear, máquina de costura, roupinhas | Costureira |
| Feira / Padaria | 8 | Forno, venda de produtos | Padeiro / cozinheira |
| Clínica | 10 | Banho, saúde | Veterinária |

## Loop principal
```
necessidades do Tiro caem com o tempo
        ↓
produzir recursos no Mundo (plantar → colher → cozinhar/fabricar)
        ↓
usar os produtos no Tiro (comida, brinquedos, cuidados, roupinhas)
        ↓
Tiro feliz → vínculo e crescimento avançam  +  missões cumpridas → recompensas
        ↓
desbloquear áreas, estações, receitas, itens e personagens
```

## Sistemas

### Sítio dos animais — implementado em 13/10/2026

Ao ter o sítio próprio, o jogador pode construir o galinheiro (duas galinhas), o curral
(duas vacas), o moinho e a queijaria. Plantar milho/trigo → alimentar → esperar → recolher
ovos/leite; trigo → farinha e leite → queijo nas estações do sítio. As criações não produzem
sem alimento; um lote por vez, com tempo real e sem perda dos animais se o jogador ficar fora.
Os produtos servem ao comércio e à progressão. Manual mostra a cadeia inteira.

O comércio evolui em três funções claras: **vender excedentes** (moedas imediatas, disponível
no Sítio desde conhecer a Bloblo), **encomendas da vizinhança** (pedidos pequenos no quadro
da Vila) e **Minha banca** (negócio próprio com contratos maiores). A Bloblo ensina a primeira
venda após a colheita; ela não exige escritura nem acesso à Vila. Uma colheita de cenouras
custa 3 moedas e rende duas cenouras, vendidas por 6: há uma fonte repetível de renda inicial.

A banca tem três níveis. Montar abre dois contratos; entregar dois permite a primeira ampliação;
somar cinco permite a última. Nível 2 acrescenta tecidos e alimentos; nível 3 acrescenta a Festa
da vila. Contratos pagam mais que a venda avulsa dos produtos e também materiais de ampliação
já existentes, sem nova moeda. Pedidos não expiram: após entregar, aguardam a própria recarga.
A linha do Feirante guia as vendas, encomendas, montagem, ampliações e contrato final. Quando
a história compartilha esses marcos, apenas orienta a seguir a linha e avança automaticamente.

As telas usam seleção e detalhe na mesma janela: venda com quantidade e botão Tudo;
encomendas em grade 2×2 com quatro por página; contratos com dois por página. Produtos,
tem/precisa, pagamento e estado ficam nos cartões; só o selecionado mostra ingredientes
tocáveis e o botão de entrega. Prontos vêm primeiro, aguardando renovação no fim. Bloqueados
não ocupam cartões: uma faixa mostra o próximo desbloqueio.

Capítulo 9 amplia a história existente com cinco passos sobre essa produção. A área física
é uma expansão cercada, aberta pelo galinheiro; comprar também revela os animais no cenário.
Para números e campos dos dados, ver `PROGRESSION.md` e `WORLDS.md`.

| Sistema | Descrição |
|---|---|
| **Necessidades** | Caem com o tempo real (ver tabela abaixo). |
| **Evolução** | Fases do Tiro, vínculo e truques. |
| **Inventário** | Recursos e produtos (sementes, vegetais, pratos, tecidos, itens). |
| **Plantação** | Canteiros com timer: plantar → esperar → colher. |
| **Estações de produção** | Fogão, forno, tear etc.: receitas com fila e tempo, estilo Hay Day. |
| **Ambientes** | Áreas desbloqueáveis com objetos tocáveis. |
| **Personagens e missões** | NPCs pedem itens ou tarefas; dão recompensas. |
| **Minigames** | Passeio, truques, brincadeiras. |
| **Moeda / economia** | Moedas por vender produtos e cumprir pedidos. |
| **Tempo real** | Timers e necessidades continuam com o app fechado (calculado ao abrir). |

## Necessidades (proposta)
| Necessidade | O que reduz | O que restaura | Efeito quando baixa |
|---|---|---|---|
| Fome | Tempo | Comida (feita em estação > ingrediente cru) | Tiro triste, anda devagar, vai à tigela |
| Felicidade | Tempo, negligência | Carinho, brinquedos, passeio, truques | Tiro desanimado, ignora toques |
| Energia | Atividade, tempo acordado | Dormir (cama/sofá), petiscos energéticos | Tiro lento, procura onde dormir |
| Higiene | Tempo, passeio, sujeira | Banho (casa ou Clínica) | Tiro suja/cheira, felicidade cai mais rápido |
| Passeio | Tempo dentro de casa | Passeio no Parque | Tiro inquieto, felicidade cai |

- O Tiro **nunca morre nem foge**: necessidades baixas só deixam ele triste/lento (punição leve).

## Produzir no mapa (Interface nova, Etapa 08)

Tocar no fogão, liquidificador, bancada, moinho, queijaria, costura ou ateliê abre uma bandeja junto
ao objeto: fila em bolinhas, receitas em grade e detalhe com ingredientes tocáveis. Escolher uma
receita só seleciona; Cozinhar/Fazer/Costurar inicia a produção e mantém a bandeja aberta. O toque
na estação pronta pega os produtos antes de abrir a bandeja. Ver tudo mantém a consulta completa.
Nos abrigos, tocar na ração alimenta os animais; sem animais, a bandeja leva à loja. Na Natureza,
escolher um material e Buscar inicia na primeira vaga livre; nível e XP ficam no cabeçalho.
Custos, tempos, quantidades e requisitos permanecem os mesmos.

## Cadeias de produção (proposta)
| Estação | Receita | Entradas | Tempo | Uso da saída |
|---|---|---|---|---|
| Horta | Cenoura | Semente | 1 min | Ingrediente, venda |
| Horta | Batata | Semente | 5 min | Ingrediente, venda |
| Horta | Abóbora | Semente | 10 min | Ingrediente, venda |
| Horta | Trigo | Semente | 15 min | Forno |
| Horta | Algodão | Semente | 30 min | Tear |
| Fogão | Petisco de cenoura | 2 cenoura | 2 min | Fome, felicidade |
| Fogão | Papinha de abóbora | Abóbora + batata | 8 min | Fome (forte) |
| Fogão | Sopinha | Cenoura + batata + abóbora | 12 min | Fome + energia |
| Forno | Biscoito canino | Trigo + abóbora | 15 min | Fome, felicidade, venda |
| Forno | Bolo de aniversário | Trigo + abóbora + cenoura | 30 min | Evento/missão, felicidade máx. |
| Tear | Tecido | Algodão | 10 min | Máquina de costura |
| Máquina de costura | Roupinhas / lenço | Tecido (+ linha) | 20 min | Customização do Tiro |
| Geladeira | Armazém | - | - | Capacidade evolui com melhorias |

- Regra: **comida feita em estação recupera mais** que o ingrediente cru.
- Valores de tempo são ponto de partida para balancear (dados em `game/data/`).

## Progressão do sítio (implementada)
- Novo jogo começa com **1 canteiro emprestado** pela Bloblo; a escritura do sítio (Jornada → Construir)
  libera 3 canteiros. Há 9 posições fixas visíveis no mapa, compradas em sequência.
- Preços dos terrenos 4 a 9: 20, 40, 70, 100, 150 e 220 moedas (`config.json`, `farm.unlock_costs`).
- Colher rende só os produtos e XP (etapa 09 da economia: `crops.json → coins` é 0); as moedas vêm de vender (feira) e entregar encomendas/contratos. Sementes continuam gratuitas.
- Cada plantação mostra ícone, tempo restante e barra; ao amadurecer, mostra “Colher”. O broto cresce e dá lugar à planta.
- **Como se planta (bandeja de ação, Interface nova Etapa 07):** tocar num canteiro vazio abre, ao lado do dedo, uma bandeja com as
  sementes (a última usada primeiro, o tempo embaixo de cada uma; bloqueadas ficam apagadas com cadeado e levam ao "Como fazer").
  Tocar na semente planta ali; **arrastar a semente por cima da horta planta em vários canteiros de uma vez** (a horta inteira
  leva 1 toque + 1 arrasto). Tocar numa planta crescendo rega na hora (uma rega por plantio) e oferece o regador para arrastar pelos
  outros; já regada, mostra o tempo que falta num anel. Tocar numa planta pronta só colhe, sem abrir sementes, foice ou painel.
  Para plantar novamente, toque depois no canteiro já vazio. Nada disso muda custo, tempo ou recompensa; o painel antigo continua em "Ver tudo".
  Tocar fora da bandeja só a fecha. Tocar num terreno bloqueado abre preço e requisitos.
- O botão “Meu sítio” mostra terrenos adquiridos, saldo, próxima expansão e acesso aos canteiros.
- Saves antigos preservam seus terrenos e plantações. Crescimento continua com o app fechado.

## Mundos e navegação (implementado)
Abas Tiro · Mapa · Missões · Mochila. Mini mundos (Casa, Sítio da Bloblo, Vila e Natureza),
cada um com personagens e lugares tocáveis; a aba Missões (História, Diárias, Semanais) diz o que fazer e leva até lá.
Ver [WORLDS.md](WORLDS.md).

## Progressão — Jornada (implementada)
Casa quase vazia no começo, crescimento do Tiro (Corpo, Pelagem, Esperteza, Coragem), construções compradas, rotas de passeio/mineração, feira, capítulos, missões
de NPCs e coleção de roupas/apetrechos. **Detalhes, formatos e versão dev em [PROGRESSION.md](PROGRESSION.md).**

## Evolução (ideias originais; parte já virou a Jornada)
- **(a) Crescimento do Tiro:** cinco fases, requisitos e quatro pilares. O nível do jogador foi encerrado na etapa 07; história e fase orientam os desbloqueios.
  Ao tocar Crescer!, a cerimônia escurece a tela, alterna silhuetas de forma acelerada (máximo
  três trocas por segundo) e revela o Tiro com antes/depois, idade, peso, fato e miniatura de régua.
  “Que lindo!” confirma a recordação; as novidades aparecem depois. Menos animação usa troca suave,
  sem piscar nem confete. Mocinho e Azul e Dourado podem crescer dormindo: a revelação espera
  acordar (tocar nele na tela Tiro) ou voltar ao jogo. Boas-vindas avisa “Ele cresceu enquanto dormia!”
  ou “Ele pode crescer!” uma vez por fase pronta. Fotos oficiais e régua na Casa ficam para 13/14.

- **(b) Carinho com o Tiro:** as necessidades (felicidade) mostram o cuidado; truques aprendidos também aumentam felicidade e afeto.
- **(c) Truques (Etapa 10, implementada):** Nina ensina no lugar Treino da Praça, no cantinho dos cones, após `nina_pipoca`. Barra em ping-pong, zona verde e botão de 64 px “Agora!”. Três acertos aprendem; “Quase!” apenas repete, sem custo ou limite. Um truque por vez: Dá a pata, Fala (vínculo 2), Rola (3), Pula (4), Gira (5). A tela Tiro ganha Truques após aprender o primeiro; mostrar dá +3 felicidade e +1 afeto, com recarga individual de 2 min. Sono e passeio bloqueiam treino/execução. Reutiliza as cinco animações existentes: roupas permanecem na pata/latido, somem nas acrobacias e voltam ao descanso. “Novo truque!” usa a fila e o cartão com rolagem existentes. Missões Nina nas ordens 90 e 110, desejo e diária após `nina_trick`.

- **(d) Moedas:** vender produtos e entregar pedidos.
- **(e) Melhorias:** estações (fila maior, mais rápido), canteiros extras, geladeira maior.

## Construir e decorar (proposta)
| Dá para | Não dá (simplicidade no celular) |
|---|---|
| Comprar/colocar estações nos **slots fixos** de cada área | Construção livre em grid |
| Canteiros extras | Paredes |
| Móveis/decoração do Tiro (cama, casinha, brinquedos, tapetes) em **slots predefinidos** | Mover cômodos |
| Trocar cores | |

- Motivo: manter o toque simples, sem arrastar/posicionar com precisão.

## Customização do Tiro (proposta)
| Slot | Exemplos |
|---|---|
| Cabeça | Óculos, chapéu, laço |
| Pescoço | Coleira, lenço, gravatinha |
| Corpo | Roupinhas, capa |
| Pelagem / tosa | Estilos de corte (proposta) |

- Aparece em detalhe na **Tela do Pet** (camadas sobre o sprite grande).
- No Mundo: só versão simplificada (ex.: cor da roupa) ou nada no início.
- Fontes: **Ateliê** (produzido), recompensas de missão, loja com moedas.

## Missões (proposta)
| Tipo | Descrição | Recompensa |
|---|---|---|
| Pedidos | Quadro de pedidos estilo Hay Day: entregar X itens | Moedas + XP |
| História | Por personagem; cumprir destrava a área/NPC seguinte | Áreas, itens |
| Cuidado | Ex.: dar banho no Tiro, alimentar 3 vezes | XP, vínculo |
| Minigames | Treino de truques, passeio | Truques, moedas |

## Referências
- Bichinho virtual (Tamagotchi e similares) e Hay Day (produção em cadeia, pedidos, timers).
- [apartamento_sala_cozinha.jpg](references/apartamento_sala_cozinha.jpg): apartamento em pixel art 3/4 isométrico (sala + cozinha), primeira cena do Mundo.
- [dog_poses_movimentos.jpg](references/dog_poses_movimentos.jpg): poses detalhadas do cachorro (parado frente/costas/lado, correndo, fingir de morto, reverência, comendo, dormindo) para a Tela do Pet.
- [dog_personagem_sprite_lado.jpg](references/dog_personagem_sprite_lado.jpg): sprite sheet lateral mais simples (parado, sentado, andando, correndo, latindo, farejando, pulando) para o Mundo.

## Fatiamento de entrega
| Iteração | Conteúdo |
|---|---|
| **1 (agora)** | Tela do Pet + Casa com objetos tocáveis + necessidades + inventário + fogão + tempo real |
| **2** | Horta + Tutor com missões + nível/XP |
| **3** | Customização (Ateliê) + Parque/truques |

## Escopo do MVP (= Iteração 1)
- Tela do Pet com o Tiro e 3 necessidades (fome, felicidade, energia), interações básicas.
- Mundo com **Casa** (geladeira, fogão, tigela, sofá, cama) e Tiro autônomo.
- Inventário, 2 receitas no fogão, tempo real offline + save local.
- Fora do MVP: Horta, Tutor com missões, nível/XP (Iteração 2); customização e truques (Iteração 3).

## Perguntas em aberto
- Como funciona o passeio: minigame, ação com timer, ou ambiente?
- Zoom com pinça no Mundo?
- Balanceamento: tempos de produção, preços e valores de necessidades.
- Como o Tiro é representado fora da tela (notificações push no PWA)?

## Vestir e criar apetrechos (Etapa 08)

Coleção → Roupas permite vestir/tirar até três peças (cabeça, pescoço, corpo). O Tiro detalhado,
Desejos e cartão de boas-vindas mostram a combinação; no mapa ele mantém o visual pequeno.
Pet shop Patinhas ocupa o quiosque existente da Praça: compra roupas/ração/bolsinha e costura
roupas com materiais dos passeios. Roupa pronta e apetrecho encontrado têm **Vestir agora**.
Há 18 peças com arte; roupas antigas ainda sem sobreposição mostram "Em breve no Tiro".

Dois lendários temáticos aprovados pelo Vitor: uniforme de esponjinha e chapéu do Siri Cascudo,
separados para combinar. São cosméticos, com sorteio independente e garantia, sem reduzir a
chance dos raros existentes. Após pet shop + 20 voltas, chance 1% e garantia em 30 voltas elegíveis
por peça; não há pagamento premium. Óculos escuros clássicos substituem a presilha, preservando
o id de coleção anterior. Não foi criada diária de costura (roupas têm quantidade finita).

## Amigos do Tiro (Etapa 09)

Pipoca, Mel (poodle), Bolota (pug) e Fred (beagle) fazem parte da vizinhança. Na Praça ficam
Pipoca e um visitante por janela local de três horas. Cada um aceita seu petisco favorito uma vez
por janela; 1, 3 e 6 petiscos rendem corações e presentes únicos. Ninguém perde amizade por faltar.
Pipoca com dois corações soma um achado aos passeios, junto à bolsinha. Melhores amigos podem
visitar a Casa após oito horas de ausência real e deixam um presente persistido até o toque.
O cartão de boas-vindas leva à visita; a Coleção tem álbum de amigos e silhuetas dos desconhecidos.
Missões da Nina apresentam a turma; desejo, diária e semanal reutilizam dar petiscos.
- **(d) Tesouro (Etapa 11, implementada):** com os quatro pedaços achados pelo Tiro (sítio, praça, vila, natureza), o Guia da trilha ganha o passo "O mapa completo". Ao recebê-lo, um baú aparece na Natureza (Clareira escondida). Tocar uma vez: festa, 150 moedas, Chapéu de explorador, parafusos e as mudas de mirtilo (cultura nova e desejo especial). Final do mistério que começou no pedaço 1; plano de 12 etapas concluído.


## Crescimento — consulta e entrega (Tiro no centro, etapa 06)

Na tela Tiro, o selo ao lado do vínculo mostra a fase e o progresso do crescimento. Toque abre a fase
atual, a sombra da próxima e o que falta. Cada requisito leva à ajuda Como fazer com Ir; Dar entrega
um item-chave definitivamente. Quando tudo está pronto, Crescer! espera o jogador escolher a hora.
O painel permanece aberto ao entregar/crescer; a caderneta guarda fases anteriores e dicas das futuras.
Verbos do crescimento: **Crescer** e **Dar**. Fotos oficiais e cerimônia entram nas etapas próprias.

### Álbum completo — Tiro no centro, etapa 15

O caderninho mostra as 54 recordações em seis seções. Fotos secretas têm título, pista e lupa diária (a câmera dá uma extra); personagens ajudam depois de três dias, e o objeto relacionado pode brilhar. As cenas são automáticas quando o jogador prepara a combinação: nenhuma exige apertar um obturador. Rever fotos pode trazer a Pipoca, com garantia na oitava abertura elegível. Soninhos registram caminha, sofá e visitas. O Dia do Tiro celebra o aniversário da chegada por sete dias, todo ano, com bolo, chapéu de festa e receita própria; a foto permanece única no álbum.


### O jeito do Tiro (Tiro no centro — etapa 16)

A rotina dá ao Tiro um jeito: Explorador, Comilão, Brincalhão, Dengoso ou Tranquilo. Ele aparece ao virar Aventureiro, com “O jeito dele apareceu” e o título “Tiro, o …” no Crescimento e no caderninho. Todos são bons; nenhum bloqueia ou dá vantagem. A média dos últimos 14 dias jogados se combina ao histórico, com limite diário e confirmação por vários dias para mudar devagar. Antes de Aventureiro, só a fase orienta os comportamentos.

Filhotes bocejam/cochilam e às vezes pausam com um pulinho no caminho; Dentinhos mordisca as patinhas; Aventureiro corre em destinos próximos e olha/fareja mais; Mocinho e adulto descansam mais, procuram a turma e estações em uso. O adulto senta com ar importante. São animações existentes, sem alterar as necessidades, os prêmios ou o sono real.

“Hoje o Tiro...” no caderninho guarda as últimas 20 lembranças: fotos, primeiras provas, crescimentos, passeios e achados raros. Fotos/provas/fases não repetem depois de recarregar; datas locais acompanham as linhas.
