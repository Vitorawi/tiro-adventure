# Primeira semana: regras fechadas (E00, 18/11/2026)

Este arquivo é a **fonte única** das decisões e dos ajustes que valem para as etapas E01 a E16. Quando um documento externo discordar, vale o que está aqui.
Números e tabelas completos continuam nos documentos da seção 1 do `README.md` (plano da primeira semana, catálogo de pratos, canvas).

## 1. Documento de alimentação que vale

Vale **"Alimentação do Tiro: design completo"** (artifact `U5HaGggnMLE9W4WZMwH6mg`, 20 KB): tabelas de ingredientes, tipos de refeição com vagas, 12 duplas, cálculo do prato, paladar, secretas e dados JSON.
O **"sistema completo"** (artifact `QhnD6Yt2cdZuzoJ2xoriL2`, 4 KB, rev. 3) é um resumo anterior, com tabela de nutrientes diferente: fica só como histórico e **não** vale.
Exceções onde o plano da primeira semana corrige o "design completo":
- Horários: castigo leve do dia fraco (o "nada pune" do documento cai; D3).
- Mingau único: grão + (fruta ou laticínio) + livre; abre no dia 4 (D6).
- Sopa do passeio muda de receita na semana 2; "Papinha da chegada" (pedia leite) também sai da semana 1.
- Nutrientes dos 5 ingredientes novos (aveia, banana, abobrinha, arroz, melancia) e das 7 duplas novas são proposta do plano; a E02 os fixa em `dishes.json`.

## 2. Decisões do Vitor (todas aprovadas em 18/11/2026, recomendação mantida)

| Nº | Decisão | Resultado |
|---|---|---|
| D1 | 12 ajustes da revisão (seção 3 abaixo) | Aprovados, todos |
| D2 | Botão **Deixar pronto** | Aprovado: fora da janela, arrastar a refeição à tigela oferece Dar agora ou Deixar para o almoço/jantar; tampinha com relógio; uma refeição guardada por vez, só para a próxima janela; o Tiro come sozinho ao abrir a janela, mesmo com o jogo fechado; quem dá na hora ganha mais Felicidade e pode pedir truque |
| D3 | Castigo do dia fraco | Leve: dia não conta e ele acorda fraquinho até a próxima refeição na hora; marmita da vovó depois de 2 dias fracos seguidos; nunca passa fome, adoece nem perde patinha |
| D4 | Veterinário (aveia, banana, maçã sem sementes, abobrinha, arroz, melancia, batata-doce) | **Pendência do Vitor**: conferir até a E16; só trava a arte final. A estrutura segue com os 13 ingredientes. Registrado em `PROVISORIOS.md` |
| D5 | Vagas da panela | Documento: Papinha = legume + livre (+ livre), Sopinha = legume + legume + livre; as 538 combinações dependem disso |
| D6 | Mingau | Um só: grão + (fruta ou laticínio) + livre; o leite (semana 2) só amplia o mesmo tipo |
| D7 | Estrelas na fila | Tabela de maestria: receita nova sai com 1 estrela; estrelas cortam 25%, 50% ou 75% do tempo |
| D8 | Passos da papinha | Semana 1: Picar, Mexer e Servir (sem Amassar) |
| D9 | Pratos diferentes em Recém-chegado | 4 (o simulador confirma na E15) |
| D10 | Desafio em Filhotinho | "8 pratos diferentes de pelo menos 3 tipos" (papinha, sopinha, mingau); o painel mostra três ícones de tipo |
| D11 | Posição das áreas novas do Sítio | Provisória, com os assets atuais (README, seção 8); ajuste fino na E16 |
| D12 | Casa e Sítio | Manter a cena interna da Casa (fogão e tigela) e abrir o Sítio no dia 1 |
| D13 | Kits na banca | Galinheiro, caminha e mordedor em kit que constrói ao comprar; preços finais saem do simulador (E15) |
| D14 | Treino | Só na Aula do Tiro, 1 biscoito por aula |
| D15 | Truques da vovó | Senta, Dá a pata e Deita; a Nina fica com Fala, Rola e os seguintes |
| D16 | Feirante | Carroça no portão a partir do dia 5, 2 encomendas por dia |
| D17 | Vila | Só depois de Dentinhos, capítulos renumerados; ponte de saída: a história antiga continua da Vila em diante |
| D18 | Dia 1 | Em duas sessões, com a aba Inventar liberada no jantar |
| — | Saves | Sem migração: subir `SAVE_VERSION` quando o formato mudar (hoje 20) |

## 3. Os 12 ajustes da revisão (Parte A), como ficam

| Nº | Ajuste | Regra final |
|---|---|---|
| 1 | Custo do truque | 1 biscoito por **aula**; o tutorial do dia 2 ensina isso, não "biscoito por tentativa" |
| 2 | Formato do treino | Só a **Aula do Tiro** (Mostrar, Marcar, Premiar). Os três gestos são os caminhos do biscoito; a barra de um toque (Agora!) sai da semana 1 |
| 3 | Duplas | **7 novas** (13 no total), não três |
| 4 | Mingau | Um só (ver D6) |
| 5 | Secretas | Sopinha do pescador fica na semana 1; Sopa do passeio muda na semana 2; Papinha da chegada sai da semana 1 |
| 6 | Moedas do dia 2 | 30 moedas no cartão Bom dia do dia 2 (primeira patinha) e a missão do galinheiro paga **20 ao comprar** o kit, não ao montar; saldo estimado no minuto 7 do dia 2: 95 |
| 7 | Quem só joga à noite | Botão Deixar pronto (D2) |
| 8 | "8 pratos diferentes" | De pelo menos 3 tipos (D10) |
| 9 | Começar depois das 22h | No dia 1 a primeira papinha vale como refeição na hora **a qualquer horário** (uma refeição basta no dia da chegada) |
| 10 | Dia 1 pesado | Duas sessões (30 min + o resto); Inventar passa para o jantar; total perto de 40 min |
| 11 | Dia 7 vazio | **Almoço de despedida**: cozinhar 3 pratos (vovó, Laís, Tiro) antes da cerimônia; foto de grupo |
| 12 | Listas demais | A aba Missões mostra só a História e um único **Próximo passo** sorteado entre as linhas; o resto mora no caderninho |

Acréscimos: o cartão Boa noite termina com o **gancho de amanhã** (uma linha + silhueta); **aviso opcional** de hora de comer, desligado por padrão e oferecido uma vez, depois do primeiro dia fraco.

## 4. Divergências do plano, resolvidas

| Divergência | Resolvida como |
|---|---|
| "30 passos" (Missões) × "os 22 passos" (Ordem sugerida) | **30 passos em 7 capítulos** (conferido: a tabela da História tem 30 linhas). O "22" é resto de uma versão antiga |
| "4 receitas secretas" × "as duas secretas" (Ordem sugerida) | **4 secretas**: Sopinha do pescador, Risotinho do lago, Curau do Tiro, Doce de roça do Tiro. O "duas" é resto de versão antiga |
| Vagas da panela (documento × Figma) | Documento (D5) |
| Mingau Grão + Laticínio × Grão + Fruta | Mingau único (D6) |
| Truques: barra de um toque × Aula de três passos | Só a Aula (ajuste 2) |

Os documentos externos (artifacts do claude.ai) **não** foram editados nesta etapa; este arquivo e o `README.md` valem no lugar.

## 5. Números de partida (do plano; o simulador da E15 ajusta)

Dias bem alimentados 2 + 5 · pratos diferentes 3 e 8 · brincadeiras 4 e 8 · acertos do Senta 3 · cenoura/batata/abóbora 1/5/10 min (acelerado nos dias 1 e 2: batata 2 min, abóbora 6 min, milho 3 min, primeiro lote de ovos 2 min) · ovos 2 a cada 30 min · pomar 2 frutas por árvore a cada 2 h · 3 iscas grátis por dia · marmita após 2 dias fracos seguidos · níveis de truque 3, 8 e 15 · show de 3 a 5 truques, 1 por dia · carroça com 2 encomendas por dia · caminho obrigatório 190 moedas na semana.
