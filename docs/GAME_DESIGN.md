# Game Design

> Documento vivo.
> Imagens de referência: salvar em `docs/references/`. Referências visuais serão adicionadas em `docs/references/`.

## Conceito
Um **bichinho virtual** (cuidar de um cachorrinho) misturado com **produção em cadeia estilo Hay Day**:
o jogador planta, colhe, cozinha e fabrica coisas em vários ambientes para cuidar do cachorro,
cumprir missões de personagens e desbloquear novos lugares.

## Plataforma e tela
- Celular **em pé**, ocupando a tela inteira (base 360×780, formato dos celulares atuais; estica
  para qualquer aparelho sem faixas pretas).
- Jogado no navegador / instalado como app (PWA).

## Princípio de interação: 100% toque
- **Sem controles de movimento.** O jogador não anda com o cachorro.
- O **cachorro vive sozinho**: anda, deita, brinca, reage, de forma autônoma.
- O jogador **toca nas coisas**: geladeira abre a geladeira, horta mostra o que plantar, fogão
  mostra receitas, cachorro mostra carinho/necessidades.
- **Arrastar para mover a câmera** pelo ambiente (ex.: andar pelo apartamento); pinça para zoom (a confirmar).
- Alvos de toque grandes, poucos passos por ação, feedback visual imediato.
- Ações frequentes ao alcance do polegar (parte de baixo da tela).

## As duas visões
### 1. Tela do Pet (close-up)
- Cachorro **grande e detalhado** em pixel art, com as coisinhas dele (cama, pote, brinquedos).
- Mostra as necessidades e permite interagir diretamente: alimentar, carinho, brincar, banho...

### 2. Mundo (ambientes)
- Pixel art **menos detalhada**, visão do ambiente com o cachorro pequeno andando por ali.
- É onde acontece a **produção**. Ambientes desbloqueados aos poucos:
  1. **Casa / apartamento** (início): geladeira, fogão, cama...
  2. **Hortinha**: plantações.
  3. Outros lugares (a definir).
- Cada novo ambiente traz **personagens (NPCs) que dão missões**.

## Loop principal
```
necessidades do cão caem com o tempo
        ↓
produzir recursos no Mundo (plantar → colher → cozinhar/fabricar)
        ↓
usar os produtos no cachorro (comida, brinquedos, cuidados)
        ↓
cachorro feliz → ganha XP / evolui atributos  +  missões cumpridas → recompensas
        ↓
desbloquear ambientes, estações, receitas, itens e personagens
```

## Sistemas
| Sistema | Descrição |
|---|---|
| **Necessidades** | Fome, felicidade, energia, higiene, passeio... caem com o tempo real. |
| **Atributos / evolução** | O cachorro tem atributos que evoluem (nível, XP, outros a definir) e destravam conteúdo. |
| **Inventário** | Recursos e produtos (sementes, vegetais, pratos, itens). |
| **Plantação** | Canteiros com timer: plantar → esperar → colher. |
| **Estações de produção** | Fogão etc.: receitas que consomem itens e levam tempo (fila estilo Hay Day). |
| **Ambientes** | Áreas desbloqueáveis com objetos tocáveis. |
| **Personagens e missões** | NPCs pedem itens produzidos ou tarefas; dão recompensas. |
| **Minigames** | Ex.: passeio, brincadeiras (a definir). |
| **Moeda / economia** | A definir. |
| **Tempo real** | Timers e necessidades continuam com o app fechado (calculado ao abrir). |

## Referências
- Bichinho virtual (Tamagotchi e similares).
- Hay Day (produção em cadeia, pedidos, timers).
- Imagens: a receber.

## Perguntas em aberto
- O cachorro pode ficar doente/fugir se abandonado, ou só fica triste? (sugestão: só triste, sem punição dura)
- Nome/raça do cachorro escolhíveis?
- Como funciona o passeio: minigame, ação com timer, ou ambiente?
- Moeda: existe dinheiro para comprar sementes/itens? De onde vem?
- Zoom com pinça no Mundo?
- Qual o terceiro ambiente em diante?

## Escopo do MVP (proposta)
- Tela do Pet com 3 necessidades (fome, felicidade, energia) e interações básicas.
- Mundo com **Casa** (geladeira, fogão) e **Horta** (2–3 canteiros).
- 2 plantas, 2 receitas no fogão, inventário.
- 1 personagem com 3 missões.
- Tempo real offline + save local.
