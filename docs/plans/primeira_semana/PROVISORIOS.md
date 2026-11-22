# Assets provisórios da primeira semana

Lista viva (README, seção 8). Cada etapa E01 a E15 que usar um asset improvisado **acrescenta uma linha** aqui, com o que precisa substituir. A E16 só termina quando esta tabela estiver vazia ou cada item restante estiver aprovado pelo Vitor.

| Etapa | Onde aparece | Provisório usado | O que precisa substituir | Lote da E16 |
|---|---|---|---|---|
| E02 | Mochila, venda, fogão (ingredientes novos) | Aveia e arroz: ícones do trigo tingidos. Banana: ícone do milho tingido (fica parecido, trocar logo). Abobrinha: cenoura verde. Melancia: maçã rosa. Gororoba: papinha acinzentada (`tools/dish_icons_art.py`) | Ícones finais dos 5 ingredientes e da Gororoba (D4: conferir com o veterinário antes) | Comida |
| E02 | Pratos (cozinha, Mochila, livro) | Ícone do TIPO para todos os pratos (`puppy_mash`, `carrot_snack`, `apple_biscuit`, `vegetable_soup`, `milk_porridge`); nomeados com peixe usam `fish_mash`, o ovinho usa `egg_scramble` | Ícones próprios dos ~25 pratos com nome e do ícone por tipo na cor do ingrediente principal | Comida |
| E03 | Cozinha (aba Pratos) | Selo "Para crescer" desenhado por código (pílula verde, `CookPanel.grow_badge`); estrelas dos cartões com a arte `ck_stars_N` já existente | Selo final e arte própria das estrelas (E16) | Interface |
| E04 | Minigame Cozinhar junto (Picar, Mexer, Servir, Prato pronto) | Tudo desenhado por código numa tela virtual 360×780: bancada/fogão/cozinha de madeira lisa, tábua, ingrediente como barra colorida + ícone do item, panela e concha em círculos, tigela, coração e selos (Perfeito!/Boa!/Torto) em texto, barra dos 3 passos e botões Pular/Sair; Tiro espiando = retrato do filhote (`HomeUi.head_texture`) subindo e descendo; Prato pronto usa o `ModalCard` de madeira com a ilustração do prato e `ck_stars_N` | Fundos, tábua, panela, concha, tigela, coração, selos, mão do tutorial, `tiro_espiando`/`tiro_esperando` e as reações do Tiro (prancha de arte do canvas "Cozinha interativa"); gestos novos Amassar, Tirar espinha, Arrumar, Abrir massa, Carimbar e Decorar não existem ainda | Cozinhar junto |
| E05 | Para crescer (painel e cerimônia) | Ícones dos requisitos novos: patinha = `tab_pet` (dias bem alimentados), `puppy_mash`/`apple_biscuit`/`carrot_snack` (pratos, 2 estrelas, inventado), `item_egg`/`item_apple`/`item_fish_tilapia` (prato-chave), `action_play` (brincar e Senta); resumo e "Abriu" da cerimônia em texto simples | Patinha cheia/riscada própria, ícones de prato-chave (ovo, fruta, peixe) e de truque; arte do resumo da semana | Interface |

| E06 | Sítio, banca, kits e bandejas | Galinheiro e galinhas existentes, pomar e tapete reutilizados, plaquinhas de madeira e silhuetas | Acabamento do Sítio e dos kits | Sítio / Interface |
| E07 | Caderno, Aula e resultado | Ícones `tab_pet`, `trick_paw` e `need_energy`; tapete `paw_rug`, retrato atual da vovó, moldura da Mochila, biscoito de maçã, estrelas `rare_star`/`ck_stars_N` e `ModalCard`; tracejado, alvo e tempo desenhados em código | Ícones/selos dos três truques, tapete e cena final da aula, guias e indicação visual de acerto, ilustração do resultado | Sítio / Interface |
| E07 | Poses da Aula do Tiro | `idle_breathe` no Senta, `lick_paw` na pata, sequência `belly_*` no Deita e `pet_head` no prêmio com o corpo filhote; clipes disponíveis dos demais corpos quando já cresceu | Clipes de cada truque e reação de recompensa, com o mesmo filhote e a idle aprovada preservada | Tiro filhote |
| E07 | Álbum, foto “Pata!” | Ilustração existente na Praça com a Nina; a descoberta agora vem da Aula no Sítio | Refazer a ilustração no tapete com a vovó | Fotos |
| E08 | Pedido sobre a tigela e Show de truques | Moldura da Aula, tigela `prop_bowl`, ícone do prato, tapete `paw_rug`, tracejados da E07 e poses da Aula. A plateia usa as poses em pé do Sítio. Aplauso apresentado na folha de madeira com confete | Tigela e palco acabados, vovó e Laís sentadas e aplaudindo, clipes próprios de cada truque | Interface / Sítio / Tiro filhote |
| E08 | Álbum, foto “O show do Tiro” | Composição do `PhotoCard` com cenário existente do Sítio, pose da pata e retratos da vovó e da Laís | Arte da foto na varanda e suas versões | Fotos |
| E09 | Quintal, Bolinha, Cabo de guerra e Esconde-esconde | Cesto e grama existentes, recortes do Sítio e da lagoa, galinha e flor reaproveitadas. Bolinhas, arco, balde, lama, vaso, ponte, cordinha e rabo desenhados no código. Galinheiro e pomar representam casinha e arbusto. | Arte dos dois quintais, dos brinquedos, dos alvos e esconderijos. Som do apito sintetizado no jogo para revisão. | Sítio / Interface |
| E09 | Reações do Tiro ao brincar | Movimento com poses e clipes existentes. Salto animado sobre a pose, reação de chegada e barriga para o descanso. | Clipes de buscar, saltar e pegar, voltar com a bolinha, trapalhadas, puxar, atender ao chamado, espiar pelo rabo e ficar ofegante. | Tiro filhote |

| E10 | Entrada do Sítio e folha da Carroça | Banca verde da Vila e retrato do Feirante como figura estática junto ao portão. Folha, cartões, ícones e gesto do cliente reaproveitados. | Carroça própria, pose do Feirante no mapa, posição final e acabamento da T4. | Sítio / Interface |
| E10 | Xampu, lacinho e bolinha | Frasco do xampu de ervas, lacinho amarelo da coleção e ícone Brincar. Lacinho do filhote sobreposto na pose de repouso, preso por uma âncora provisória. | Ícones próprios, sobreposições do lacinho nos demais clipes e arte da bolinha da E09. Preservar a idle aprovada. | Interface / Tiro filhote |
| E10 | Banho caprichado | Reusa as bolhas de Cuidar e o clipe Animaref de banho. | Conferir no celular o encaixe da espuma, o roteiro e a reação. | Tiro filhote |

| E11 | Livro e cartão Achado! | Moldura do Caderninho, ícone do fogão e ícones de prato da E02. Pedaços, seleção, maestria e nível em controles de UI. Achado! usa ModalCard com o mapa rasgado existente. | Arte final do papel, do avental, dos selos e do Tiro com a página (T5). | Interface / Tiro filhote |
| E11 | Horta | Sprites da cenoura e da abóbora representam abobrinha e melancia no canteiro. Os ícones dos itens são os reaproveitados da E02. | Sprites das duas culturas e ícones finais. | Sítio / Comida |

| F04b | Minhoca gorda, Peixe dourado, Ensopado Dourado, foto "O peixe dourado" | Ícones 32 px derivados da minhoca, do pintado e do ensopado de peixe com tom dourado (`item_golden_worm`, `item_fish_golden`, `item_golden_stew`); ilustração da foto = `f_dig` tingida de dourado (`s_golden_fish.png`, sem arte de raridade própria); carimbo "Extra" desenhado em código | Ícones e ilustração próprios, com as quatro raridades da foto | Comida / Fotos |

## Improvisos do Sítio (E06)

- O galinheiro usa `figma_galinheiro` e duas instâncias da galinha branca. O milho ocupa o canteiro inferior existente.
- Usam-se os lotes da estufa e queijaria para o `orchard` e o `paw_rug` ampliado. As poses da vovó e da Laís são quadros estáticos das caminhadas. O píer e o portão são os próprios do fundo do Sítio.
- As áreas futuras usam os sprites atuais escurecidos, a cerca de região já existente e a tábua ilustrada da bandeja como placa. Os canteiros extras reaproveitam a placa de compra do Figma.
- A banca e a montagem usam `tab_farm`, `station_coop`, `item_bed_gift` e `item_chew_ring`, com a folha de madeira existente. A bandeja do pomar reutiliza as texturas dos itens, incluindo o ícone da banana da E02, que ainda se parece com milho. Os cartões identificam as frutas pelo nome.
- Na E16, trocar as silhuetas e placas pela arte final, ajustar as posições, preparar os sprites da macieira, bananeira, tapete, plateia e galinheiro pequeno, e finalizar a apresentação dos kits.
| E12 | Caixinha e saída do Tiro | `arrival_box`, pose frontal aprovada e quarto existente, com recorte e movimento em código | Caixa com tampa animada, poses de dentro e saída progressiva | Tiro filhote / Interface |
| E12 | Biscoito de aveia | Ícone do biscoito de maçã | Ícone próprio do biscoito de aveia | Comida |
| E12 | Lembranças da semana e almoço | Quatro fotos reaproveitam ilustrações do Álbum. A foto de grupo compõe o Sítio, Tiro e retratos existentes. As surpresas aparecem em texto com as peças da História. | Ilustrações próprias da caminha, peixe, mingau, espuma e foto de grupo. Reações das sete surpresas. | Fotos / Tiro filhote |
| E13 | Bom dia, Boa noite, Missões e Caderninho | Moldura e ícones existentes, selo textual e silhuetas feitas com os ícones de cada novidade. Sementes usam os ícones das hortaliças, marmita o da papinha e paninho o da caminha. O chapéu usa a sobreposição de explorador. | Retrato fraquinho, patinha, selo, silhuetas e ícones próprios das lembranças. Chapéu de cozinheiro com a pose aprovada preservada. | Interface / Tiro filhote |
| E13 | Fotos das três linhas | Ilustrações reaproveitadas da primeira papinha, barriga para cima, primeira pata e cozinha. | Ilustrações e variações próprias para “A favorita”, “Barriga para cima”, “Bom menino” e “Dia perfeito”. | Fotos |

### Provisórios da E14

| Etapa | Onde aparece | Provisório usado | O que precisa substituir | Lote da E16 |
|---|---|---|---|---|
| E14 | Guias, cartões Novo! e Manual de tutoriais | Cursor circular do Álbum e da Pesca, contorno em código, molduras e retratos existentes. Tigela reutilizada do Álbum. | Arte da mão e dos movimentos de toque, gesto e arrasto, e acabamento da tigela e das dicas. | Interface |

### Provisórios da F04 (fotos de fechamento dos capítulos)

| Etapa | Onde aparece | Provisório usado | O que precisa substituir | Lote da E16 |
|---|---|---|---|---|
| F04 | `h_week_soup` (cap. 2), `h_week_book` (cap. 8) | Ilustração da cozinha (`h_kitchen`) | Ilustrações próprias da primeira sopinha e do Livro de receitas | Fotos |
| F04 | `h_week_wish` (cap. 3) | Ilustração do Filhotinho (`h_growth_puppy`) | Ilustração do Tiro fazendo o primeiro pedido | Fotos |
| F04 | `h_week_eggs` (cap. 4) | Ilustração da primeira papinha (`f_taste`) | Ilustração do prato com ovo | Fotos |
| F04 | `h_first_trick` (cap. 5, agora "Primeiro truque") | Arte antiga do Dá a pata com a Nina | Ilustração do Senta com a vovó (a arte atual mostra a pata e a Nina) | Fotos |
| F04 | `h_week_fish` | Passou a fechar o prato com peixe (cap. 6); arte igual | Ilustração própria do peixe | Fotos |

## Pendências que não são arte

| Pendência | Quem | Trava |
|---|---|---|
| D4: conferir com o veterinário aveia, banana, maçã sem sementes, abobrinha, arroz, melancia e batata-doce | Vitor | Arte final dos ingredientes (E16); a estrutura não depende |
- Reloginho/balão/Hoje: cor do reloginho e posição ainda provisórios (E16).
- E10: a bolinha que apita passou do empréstimo provisório à compra na Carroça do Feirante no dia 5. A cordinha está disponível no quintal no dia 4, e a História passa pelo Cabo de guerra no capítulo do pomar.
- E09: números para a calibração da E15 em `growth.json → week_play`. Felicidade +10 na bolinha comum, +14 na que apita, +6 na cordinha e ao achar Tiro. O primeiro recorde positivo premiável de cada dia paga 5 moedas. Alcance dos brinquedos, janelas dos gestos e posição dos alvos são ajustáveis.
