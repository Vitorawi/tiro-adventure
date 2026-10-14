# Game Design

## Desejos do Tiro e vínculo (Etapa 03, 14/10/2026)

Depois da caminha, a aba Desejos aparece entre Tiro e Mapa. O primeiro pedido é 3 carinhos.
Um espaço abre com a caminha, outro com vínculo 2 e o terceiro com vínculo 4. Pedidos não vencem;
trocar é grátis e espera 5 min. Cumprir dá moedas e afeto, com festa do Tiro; o próximo chega em
1 min nos três primeiros cumpridos e em 10 min depois. Necessidades baixas têm prioridade.

Cartões mostram ícone, progresso e recompensa; Dar entrega uma comida, Receber conclui ações,
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
Desbloqueie Bosque, Caverna e Prado com moedas. Depois, recolher coletas dá XP próprio ao local. Os novos
materiais vêm do nível do local, sem comprar ferramentas: madeira dura no Bosque 3,
cobre na Caverna 2 e cristais na Caverna 3. Os níveis 2 e 3 também liberam vagas automaticamente. Material tocado inicia uma coleta; até três
por local simultaneamente. O atalho Refinar leva às receitas/estações existentes.
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
Tiro feliz → vínculo e XP sobem  +  missões cumpridas → recompensas
        ↓
desbloquear áreas, estações, receitas, itens e personagens
```

## Sistemas

### Sítio dos animais — implementado em 13/10/2026

Ao ter o sítio próprio, o jogador pode construir o galinheiro (duas galinhas), o curral
(duas vacas), o moinho e a queijaria. Plantar milho/trigo → alimentar → esperar → recolher
ovos/leite; trigo → farinha e leite → queijo nas estações do sítio. As criações não produzem
sem alimento; um lote por vez, com tempo real e sem perda dos animais se o jogador ficar fora.
Os produtos servem à feira/encomendas e à progressão. Manual mostra a cadeia inteira.

Capítulo 9 amplia a história existente com cinco passos sobre essa produção. A área física
é uma expansão cercada, aberta pelo galinheiro; comprar também revela os animais no cenário.
Para números e campos dos dados, ver `PROGRESSION.md` e `WORLDS.md`.

| Sistema | Descrição |
|---|---|
| **Necessidades** | Caem com o tempo real (ver tabela abaixo). |
| **Evolução** | Nível do jogador, vínculo com o Tiro, truques. |
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
- Colher rende os produtos e moedas: cenoura 3, batata 9, abóbora 16 (`crops.json`, `coins`). Sementes continuam gratuitas.
- Cada plantação mostra ícone, tempo restante e barra; ao amadurecer, mostra “Colher”. O broto cresce e dá lugar à planta.
- Tocar na plantação abre o progresso detalhado; tocar na planta pronta colhe. Tocar num terreno bloqueado abre preço e requisitos.
- O botão “Meu sítio” mostra terrenos adquiridos, saldo, próxima expansão e acesso aos canteiros.
- Saves antigos preservam seus terrenos e plantações. Crescimento continua com o app fechado.

## Mundos e navegação (implementado)
Abas Tiro · Mapa · Missões · Mochila. Mini mundos (Casa, Sítio da Bloblo, Vila e Natureza),
cada um com personagens e lugares tocáveis; a aba Missões (História, Diárias, Semanais) diz o que fazer e leva até lá.
Ver [WORLDS.md](WORLDS.md).

## Progressão — Jornada (implementada)
Casa quase vazia no começo, 4 atributos (Horta, Cozinha, Comércio, Aventura), construções compradas, rotas de passeio/mineração, feira, capítulos, missões
de NPCs e coleção de roupas/apetrechos. **Detalhes, formatos e versão dev em [PROGRESSION.md](PROGRESSION.md).**

## Evolução (ideias originais; parte já virou a Jornada)
- **(a) Nível do jogador:** XP de produzir, cuidar e missões; desbloqueia áreas, receitas e estações.
- **(b) Carinho com o Tiro:** as necessidades (felicidade) mostram o cuidado; truques entram no futuro.
- **(c) Truques** (habilidades do Tiro, ligados aos sprites de referência), aprendidos com o Treinador via minigame:

| Truque | Sprite de referência |
|---|---|
| Sentar | Sitting (side sheet) |
| Latir | Bark (side sheet) |
| Pular | Jump (side sheet) |
| Fingir de morto | Play dead (poses) |
| Reverência (brincalhão) | Bow (poses) |

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
