# Controle do álbum ilustrado

## Progresso

**54/54 geradas**, 0 pendentes; 54 instaladas localmente.
Pedido do Vitor em 06/11/2026. Instalação local das 54 autorizada na sequência; nada publicado.

- [Galeria visual original × nova](galeria.html)
- [Manifesto completo e prompts](manifest.json)
- Fontes originais: `game/data/album.json` e `game/scripts/ui/photo_card.gd`.
- Atualizar contagem, caminhos, dimensões e hashes: `powershell -NoProfile -File tools/album_art_control.ps1`.

## Padrão de arte e fases

Ilustração 2D de animação/livro, contorno escuro fino, pelo em mechas, olhos castanhos expressivos,
sombra desenhada e fundo suave. Mesma referência fornecida pelo Vitor e mesmas oito amostras iniciais.
Arte quadrada, sem texto/moldura/interface, composição pensada para o recorte 152:128 da polaroide.

Filhotinho: muito pequeno, preto e castanho, orelhas caídas. Dentinhos/Aventureiro: juvenil pequeno,
orelhas em pé, topo da cabeça e costas ainda pretos. Mocinho: corpo adulto, pelagem ainda escura em
transição. Adulto: cabeça dourada e dorso azul-aço. Pessoas, roupas, amigos e locais seguem suas
referências reais no jogo. Cada prompt novo está guardado em `prompts/<id>.txt`.

**Atenção para a instalação:** o álbum original monta a foto dinamicamente e guarda fase/pelo/roupa
do dia da conquista. Uma ilustração fixa representa a fase artística indicada na tabela; não substitui
todas as combinações possíveis de um save. Não alteramos esse save nem as condições da conquista.

## Original e nova arte

Não havia um PNG original por foto: cada original era cenário + quadro do Tiro + adereços/personagens,
compostos por `PhotoCard`. As capturas em `originais/` são reproduções dessa montagem, na fase artística
escolhida para comparação, sem as novas ilustrações. Definição completa, gatilho e composição estão
preservados por identificador no JSON, inclusive o caminho de cada cenário original.

| ID original | Foto | Fase da arte | Original | Arte nova | Caminho no jogo | Status |
|---|---|---|---|---|---|---|
| `h_arrival` | Chegada | Recém-chegado | [original](originais/h_arrival.png) | [nova](../../../tools/art/album_illustrated_candidates/h_arrival.png) | `game/assets/sprites/ui/album/illustrated/h_arrival.png` | Instalada localmente |
| `h_first_night` | Primeira noite | Recém-chegado | [original](originais/h_first_night.png) | [nova](../../../tools/art/album_illustrated_candidates/h_first_night.png) | `game/assets/sprites/ui/album/illustrated/h_first_night.png` | Instalada localmente |
| `h_growth_puppy` | Filhotinho! | Filhotinho | [original](originais/h_growth_puppy.png) | [nova](../../../tools/art/album_illustrated_candidates/h_growth_puppy.png) | `game/assets/sprites/ui/album/illustrated/h_growth_puppy.png` | Instalada localmente |
| `h_kitchen` | Cheirinho de papinha | Filhotinho | [original](originais/h_kitchen.png) | [nova](../../../game/assets/sprites/ui/album/illustrated/h_kitchen.png) | `game/assets/sprites/ui/album/illustrated/h_kitchen.png` | Instalada localmente |
| `h_growth_teething` | As orelhas subiram | Dentinhos | [original](originais/h_growth_teething.png) | [nova](../../../tools/art/album_illustrated_candidates/h_growth_teething.png) | `game/assets/sprites/ui/album/illustrated/h_growth_teething.png` | Instalada localmente |
| `h_first_walk` | O mundo é grande | Dentinhos | [original](originais/h_first_walk.png) | [nova](../../../tools/art/album_illustrated_candidates/h_first_walk.png) | `game/assets/sprites/ui/album/illustrated/h_first_walk.png` | Instalada localmente |
| `h_first_trick` | Pata! | Dentinhos | [original](originais/h_first_trick.png) | [nova](../../../tools/art/album_illustrated_candidates/h_first_trick.png) | `game/assets/sprites/ui/album/illustrated/h_first_trick.png` | Instalada localmente |
| `h_growth_explorer` | Pequeno aventureiro | Aventureiro | [original](originais/h_growth_explorer.png) | [nova](../../../tools/art/album_illustrated_candidates/h_growth_explorer.png) | `game/assets/sprites/ui/album/illustrated/h_growth_explorer.png` | Instalada localmente |
| `h_banca` | Mascote da banca | Aventureiro | [original](originais/h_banca.png) | [nova](../../../tools/art/album_illustrated_candidates/h_banca.png) | `game/assets/sprites/ui/album/illustrated/h_banca.png` | Instalada localmente |
| `h_growth_young` | Pelo de mocinho | Mocinho | [original](originais/h_growth_young.png) | [nova](../../../tools/art/album_illustrated_candidates/h_growth_young.png) | `game/assets/sprites/ui/album/illustrated/h_growth_young.png` | Instalada localmente |
| `h_bench` | Um banco para a turma | Mocinho | [original](originais/h_bench.png) | [nova](../../../tools/art/album_illustrated_candidates/h_bench.png) | `game/assets/sprites/ui/album/illustrated/h_bench.png` | Instalada localmente |
| `h_courage` | Coragem de verdade | Mocinho | [original](originais/h_courage.png) | [nova](../../../tools/art/album_illustrated_candidates/h_courage.png) | `game/assets/sprites/ui/album/illustrated/h_courage.png` | Instalada localmente |
| `h_growth_adult` | Azul e dourado | Azul e Dourado | [original](originais/h_growth_adult.png) | [nova](../../../tools/art/album_illustrated_candidates/h_growth_adult.png) | `game/assets/sprites/ui/album/illustrated/h_growth_adult.png` | Instalada localmente |
| `h_guardian` | Guardião do Vale | Azul e Dourado | [original](originais/h_guardian.png) | [nova](../../../tools/art/album_illustrated_candidates/h_guardian.png) | `game/assets/sprites/ui/album/illustrated/h_guardian.png` | Instalada localmente |
| `f_bath` | Primeiro banho | Filhotinho | [original](originais/f_bath.png) | [nova](../../../tools/art/album_illustrated_candidates/f_bath.png) | `game/assets/sprites/ui/album/illustrated/f_bath.png` | Instalada localmente |
| `f_taste` | Primeira papinha | Filhotinho | [original](originais/f_taste.png) | [nova](../../../tools/art/album_illustrated_candidates/f_taste.png) | `game/assets/sprites/ui/album/illustrated/f_taste.png` | Instalada localmente |
| `f_dig` | Primeiro achado | Filhotinho | [original](originais/f_dig.png) | [nova](../../../tools/art/album_illustrated_candidates/f_dig.png) | `game/assets/sprites/ui/album/illustrated/f_dig.png` | Instalada localmente |
| `f_tooth` | Dentinho de leite | Dentinhos | [original](originais/f_tooth.png) | [nova](../../../tools/art/album_illustrated_candidates/f_tooth.png) | `game/assets/sprites/ui/album/illustrated/f_tooth.png` | Instalada localmente |
| `f_friend` | Primeiro amigo | Aventureiro | [original](originais/f_friend.png) | [nova](../../../tools/art/album_illustrated_candidates/f_friend.png) | `game/assets/sprites/ui/album/illustrated/f_friend.png` | Instalada localmente |
| `f_outfit` | Primeira roupa | Mocinho | [original](originais/f_outfit.png) | [nova](../../../tools/art/album_illustrated_candidates/f_outfit.png) | `game/assets/sprites/ui/album/illustrated/f_outfit.png` | Instalada localmente |
| `f_rare` | Achado raro | Aventureiro | [original](originais/f_rare.png) | [nova](../../../tools/art/album_illustrated_candidates/f_rare.png) | `game/assets/sprites/ui/album/illustrated/f_rare.png` | Instalada localmente |
| `f_brush` | Primeira escovada | Dentinhos | [original](originais/f_brush.png) | [nova](../../../tools/art/album_illustrated_candidates/f_brush.png) | `game/assets/sprites/ui/album/illustrated/f_brush.png` | Instalada localmente |
| `s_foam_ghost` | Fantasminha de espuma | Filhotinho | [original](originais/s_foam_ghost.png) | [nova](../../../tools/art/album_illustrated_candidates/s_foam_ghost.png) | `game/assets/sprites/ui/album/illustrated/s_foam_ghost.png` | Instalada localmente |
| `s_carrot_thief` | Ladrão da horta | Azul e Dourado | [original](originais/s_carrot_thief.png) | [nova](../../../game/assets/sprites/ui/album/illustrated/s_carrot_thief.png) | `game/assets/sprites/ui/album/illustrated/s_carrot_thief.png` | Instalada localmente |
| `s_hero_shadow` | Sombra de herói | Aventureiro | [original](originais/s_hero_shadow.png) | [nova](../../../tools/art/album_illustrated_candidates/s_hero_shadow.png) | `game/assets/sprites/ui/album/illustrated/s_hero_shadow.png` | Instalada localmente |
| `s_sock_hunter` | Caçador de meias | Dentinhos | [original](originais/s_sock_hunter.png) | [nova](../../../tools/art/album_illustrated_candidates/s_sock_hunter.png) | `game/assets/sprites/ui/album/illustrated/s_sock_hunter.png` | Instalada localmente |
| `s_blueberry_face` | A careta do mirtilo | Aventureiro | [original](originais/s_blueberry_face.png) | [nova](../../../tools/art/album_illustrated_candidates/s_blueberry_face.png) | `game/assets/sprites/ui/album/illustrated/s_blueberry_face.png` | Instalada localmente |
| `s_soap_explorer` | Aventureiro de espuma | Mocinho | [original](originais/s_soap_explorer.png) | [nova](../../../tools/art/album_illustrated_candidates/s_soap_explorer.png) | `game/assets/sprites/ui/album/illustrated/s_soap_explorer.png` | Instalada localmente |
| `s_sprinkler` | Chuva suspeita | Aventureiro | [original](originais/s_sprinkler.png) | [nova](../../../tools/art/album_illustrated_candidates/s_sprinkler.png) | `game/assets/sprites/ui/album/illustrated/s_sprinkler.png` | Instalada localmente |
| `s_sofa_throne` | Trono do sofá | Aventureiro | [original](originais/s_sofa_throne.png) | [nova](../../../tools/art/album_illustrated_candidates/s_sofa_throne.png) | `game/assets/sprites/ui/album/illustrated/s_sofa_throne.png` | Instalada localmente |
| `s_photobomb` | Penetra | Mocinho | [original](originais/s_photobomb.png) | [nova](../../../tools/art/album_illustrated_candidates/s_photobomb.png) | `game/assets/sprites/ui/album/illustrated/s_photobomb.png` | Instalada localmente |
| `s_moon_friend` | Amigo da lua | Azul e Dourado | [original](originais/s_moon_friend.png) | [nova](../../../tools/art/album_illustrated_candidates/s_moon_friend.png) | `game/assets/sprites/ui/album/illustrated/s_moon_friend.png` | Instalada localmente |
| `s_zoomies` | Corrida maluca | Aventureiro | [original](originais/s_zoomies.png) | [nova](../../../tools/art/album_illustrated_candidates/s_zoomies.png) | `game/assets/sprites/ui/album/illustrated/s_zoomies.png` | Instalada localmente |
| `s_begging` | Pidão | Aventureiro | [original](originais/s_begging.png) | [nova](../../../tools/art/album_illustrated_candidates/s_begging.png) | `game/assets/sprites/ui/album/illustrated/s_begging.png` | Instalada localmente |
| `s_muddy` | Pé de lama | Azul e Dourado | [original](originais/s_muddy.png) | [nova](../../../tools/art/album_illustrated_candidates/s_muddy.png) | `game/assets/sprites/ui/album/illustrated/s_muddy.png` | Instalada localmente |
| `p_curled` | Emboladinho | Filhotinho | [original](originais/p_curled.png) | [nova](../../../tools/art/album_illustrated_candidates/p_curled.png) | `game/assets/sprites/ui/album/illustrated/p_curled.png` | Instalada localmente |
| `p_belly_up` | Barriga pra cima | Aventureiro | [original](originais/p_belly_up.png) | [nova](../../../tools/art/album_illustrated_candidates/p_belly_up.png) | `game/assets/sprites/ui/album/illustrated/p_belly_up.png` | Instalada localmente |
| `p_ball_hug` | Abraçado na bolinha | Azul e Dourado | [original](originais/p_ball_hug.png) | [nova](../../../tools/art/album_illustrated_candidates/p_ball_hug.png) | `game/assets/sprites/ui/album/illustrated/p_ball_hug.png` | Instalada localmente |
| `p_sofa` | De bruços no sofá | Mocinho | [original](originais/p_sofa.png) | [nova](../../../tools/art/album_illustrated_candidates/p_sofa.png) | `game/assets/sprites/ui/album/illustrated/p_sofa.png` | Instalada localmente |
| `p_pipoca` | Encostadinhos | Azul e Dourado | [original](originais/p_pipoca.png) | [nova](../../../tools/art/album_illustrated_candidates/p_pipoca.png) | `game/assets/sprites/ui/album/illustrated/p_pipoca.png` | Instalada localmente |
| `p_crown` | Cochilo real | Mocinho | [original](originais/p_crown.png) | [nova](../../../tools/art/album_illustrated_candidates/p_crown.png) | `game/assets/sprites/ui/album/illustrated/p_crown.png` | Instalada localmente |
| `p_sweater` | Quentinho | Mocinho | [original](originais/p_sweater.png) | [nova](../../../tools/art/album_illustrated_candidates/p_sweater.png) | `game/assets/sprites/ui/album/illustrated/p_sweater.png` | Instalada localmente |
| `p_luxe` | Sono de rei | Azul e Dourado | [original](originais/p_luxe.png) | [nova](../../../tools/art/album_illustrated_candidates/p_luxe.png) | `game/assets/sprites/ui/album/illustrated/p_luxe.png` | Instalada localmente |
| `a_pipoca` | Melhores amigas | Azul e Dourado | [original](originais/a_pipoca.png) | [nova](../../../tools/art/album_illustrated_candidates/a_pipoca.png) | `game/assets/sprites/ui/album/illustrated/a_pipoca.png` | Instalada localmente |
| `a_nina_class` | Aula particular | Azul e Dourado | [original](originais/a_nina_class.png) | [nova](../../../tools/art/album_illustrated_candidates/a_nina_class.png) | `game/assets/sprites/ui/album/illustrated/a_nina_class.png` | Instalada localmente |
| `a_bloblo_helper` | Ajudante da vovó | Azul e Dourado | [original](originais/a_bloblo_helper.png) | [nova](../../../tools/art/album_illustrated_candidates/a_bloblo_helper.png) | `game/assets/sprites/ui/album/illustrated/a_bloblo_helper.png` | Instalada localmente |
| `a_gathering` | Piquenique da turma | Azul e Dourado | [original](originais/a_gathering.png) | [nova](../../../tools/art/album_illustrated_candidates/a_gathering.png) | `game/assets/sprites/ui/album/illustrated/a_gathering.png` | Instalada localmente |
| `a_lais_lap` | No colo da Laís | Azul e Dourado | [original](originais/a_lais_lap.png) | [nova](../../../tools/art/album_illustrated_candidates/a_lais_lap.png) | `game/assets/sprites/ui/album/illustrated/a_lais_lap.png` | Instalada localmente |
| `a_four_friends` | Turma dos quatro | Azul e Dourado | [original](originais/a_four_friends.png) | [nova](../../../tools/art/album_illustrated_candidates/a_four_friends.png) | `game/assets/sprites/ui/album/illustrated/a_four_friends.png` | Instalada localmente |
| `d_month` | Um mês juntos | Azul e Dourado | [original](originais/d_month.png) | [nova](../../../tools/art/album_illustrated_candidates/d_month.png) | `game/assets/sprites/ui/album/illustrated/d_month.png` | Instalada localmente |
| `d_gotcha` | Dia do Tiro | Azul e Dourado | [original](originais/d_gotcha.png) | [nova](../../../tools/art/album_illustrated_candidates/d_gotcha.png) | `game/assets/sprites/ui/album/illustrated/d_gotcha.png` | Instalada localmente |
| `d_full_moon` | Uivo para a lua | Aventureiro | [original](originais/d_full_moon.png) | [nova](../../../tools/art/album_illustrated_candidates/d_full_moon.png) | `game/assets/sprites/ui/album/illustrated/d_full_moon.png` | Instalada localmente |
| `d_first_cold` | Primeiro frio | Mocinho | [original](originais/d_first_cold.png) | [nova](../../../tools/art/album_illustrated_candidates/d_first_cold.png) | `game/assets/sprites/ui/album/illustrated/d_first_cold.png` | Instalada localmente |
| `d_after_party` | Depois da festa | Azul e Dourado | [original](originais/d_after_party.png) | [nova](../../../tools/art/album_illustrated_candidates/d_after_party.png) | `game/assets/sprites/ui/album/illustrated/d_after_party.png` | Instalada localmente |

## Como conferir e instalar depois

Abra `galeria.html` para comparar as duas imagens lado a lado; cada imagem abre em tamanho integral.
O `manifest.json` é a fonte do controle e conserva os 54 IDs, definição original, caminhos novos e
`installed_path` com o destino no jogo; a marca de instalação confere também o hash do PNG copiado.
A referência de estilo está preservada em `references/style_original.jpg`; referências portáveis,
prompts e registros de geração ficam ligados a cada ID. A revisão de “Penetra” está selecionada;
sua primeira versão permanece em `tools/art/album_illustrated_candidates/alternatives/`.
As 54 artes estão associadas por `photo.illustration` ao mesmo ID em `game/data/album.json`, com PNGs
em `game/assets/sprites/ui/album/illustrated/`. A importação usa mipmaps e limite de 512 px para poupar
memória no celular; os PNGs completos de geração estão preservados e o recorte não distorce a arte.
O suporte de `PhotoCard` já usa proporção preservada e filtro linear. Fotos bloqueadas mantêm segredo
ou silhueta. Confira a polaroide no detalhe, na grade e na decoração antes de publicar.
