# 00 — Visão: para onde a interface vai

> Leia inteiro antes da primeira etapa. Aqui está **o porquê** de cada mudança; o **como** fica em
> `01_REGRAS_E_ESTILO.md` e nos arquivos das etapas.

## 1. A frase que guia tudo
**O mundo é a interface.** O jogador olha para o sítio, a casa e o Tiro — não para painéis bege.
Ações rápidas acontecem **perto do dedo**, sem cobrir o mundo; painéis grandes ficam só para consulta.

## 2. Diagnóstico (capturas de 15/10/2026, 360×780)

### 2.1 Tudo parece botão
- Cartões, chips, botões, abas e cabeçalho usam a mesma receita: fundo bege/laranja, borda marrom
  3 px, "degrau" de 6 px embaixo, canto 10. O olho não separa o que se toca do que é informação.
- Quase toda tela tem vários botões verdes grandes iguais (Plantar ×4, Ir ×3, Vestir ×4).
- Bloqueado = botão cinza largo + "?" ao lado: muito espaço para dizer "ainda não".

### 2.2 Mundos são maquetes no vazio
- Fundo roxo-escuro liso (`room.tscn → Void`). Na Praça e na Vila a maquete ocupa ~40% da tela.
- Sítio abre com zoom 0,62 sobre 1208×683: canteiros minúsculos, indicadores ilegíveis, etiquetas
  cortadas ("ufa", "Po").
- **Casa abre com zoom 1 e cortada** (parede à esquerda, Tiro fora de quadro): `_show_whole_room` roda
  antes de a sala ter tamanho e não é refeito.
- Botões + / − grandes ocupam área de jogo (a pinça já funciona em `RoomView._input`).

### 2.3 Cabeçalhos comem a tela
- Barra superior + cabeçalho do mundo ("Mundos", nome, "Lugares", chips de personagens) ≈ 165 px de 780.
  Com as abas, sobra ~55% da altura para o mundo.
- "Lugares" e "Locais" (Natureza): mesmo botão, dois nomes.
- Toast "Missão concluída!" aparece por cima do cabeçalho.

### 2.4 Plantar e produzir dão trabalho
- Plantar = tocar → painel cobre 70% → lista de cartões altos → "Plantar" → fecha → repetir por canteiro.
- Fogão, bancada, galinheiro, Bosque: espaços "Livre" ocupam meia tela; cabem 1,5 receitas por tela.
- Painel "Canteiros" em grade é uma segunda forma de plantar, diferente da do mapa.

### 2.5 Painel sempre igual
- Sempre ~70% da altura; título duplicado ("Cozinha" + "Fogão"); fala da Laís com meia tela vazia.
- Ícones emprestados: Fogão = petisco de cenoura, Geladeira = casinha da aba, Bancada = tábua,
  Baú = caixa de petiscos, Moinho = farinha...

### 2.6 Textos de sistema
"Fechado · Conclua: Um presente na mochila", "Abre no capítulo 4", "Estufa · plantas delicadas, crescem
mais rápido", "Seus animais · 1/3", "Nv 20 / Máx.", "Cenoura x0", "Bolsinha de passeio · +1 achado";
quatro verbos para pegar o que ficou pronto (Recolher, Coletar, Colher, Receber).

### 2.7 Tela do Tiro
Bonita no centro, mas Manual/Atributos/Coleção/Truques são chips soltos flutuando acima dele; cuidar é
só tocar em 4 botões.

### 2.8 Pouco movimento
Painéis secos, botões não afundam, números não contam, troca de mundo é corte seco → "travado".

## 3. Referências (o que copiar)

| Jogo | O que pegar |
|------|-------------|
| **Hay Day** | Bandejinha de sementes ao lado do canteiro; arrastar semente/foice por vários canteiros; produção em grade de ícones + fila; HUD só nos cantos. |
| **Township** | Balões grandes sobre construções prontas, que pulam. |
| **Animal Crossing: Pocket Camp** | Painéis claros, cantos redondos, sem bordas grossas; um botão principal; fala em balão com etiqueta de nome. |
| **Pou / My Talking Tom** | Arrastar comida até a boca; esfregar para banho; carrossel de comida embaixo. |
| **Neko Atsume** | Muito cenário, pouca interface; coleção em grade com silhuetas. |
| **Stardew Valley (celular)** | Cenário cobre a tela; mochila em grade com filtro por ícone. |
| **Pokémon Sleep** | Cartões de recompensa que viram e brilham; barra inferior limpa. |
| **Duolingo** | Microanimações: números que contam, botão que pula ao ficar disponível, confete. |

## 4. Como cada tela vai ficar (esboços)

### 4.1 Mundo (Sítio) — antes × depois
```
ANTES                                   DEPOIS
┌──────────────────────────────┐        ┌──────────────────────────────┐
│Nível 5 ▬▬▬   DEV  🪙3140  ⚙  │        │(🐶)5   ☁         🪙 3140  ⚙ │  ← HUD flutuante
├──────────────────────────────┤        │ [🌾 Sítio ▾]  ☁   (👵!)     │  ← pílula do mundo + rosto
│[Mundos] Sítio da Bloblo [Lug]│        │      céu azul em degradê     │
│[👵 Vovó Bloblo]              │        │   ╱╲ casa      🌳            │
├──────────────────────────────┤        │  ▦▦▦ (🥕✓)(⏱)   Bancada      │
│ ░░░░░ vazio escuro ░░░░░░░░  │        │  ▦▦▦  canteiros grandes      │
│   ▱▱ maquete pequena ▱▱     │        │  ▦▦▦                          │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░  │        │ grama continua até a borda   │
│                       [ + ]  │        │                               │
│                       [ − ]  │        │                               │
├──────────────────────────────┤        ├──────────────────────────────┤
│ Tiro  Desejos Mapa Missões M │        │  🐶    💗    🗺    📜    🎒  │
└──────────────────────────────┘        └──────────────────────────────┘
```

### 4.2 Plantar — antes × depois
```
ANTES: toque → painel 70% → lista → Plantar     DEPOIS: toque → bandeja ao lado do canteiro
                                                ┌─────────────────────────┐
┌──────────────────────────────┐                │  ┌──┬──┬──┬──┐         │
│ Canteiro                  (X)│                │  │🥕│🌾│🍓│🌽│ ◀ bandeja│
│ ┌──────────────────────────┐ │                │  │1m│2m│3m│3m│         │
│ │🥕 Cenoura ⏱1min 🪙+3 [Plantar]│             │  └──┴──┴──┴──┘         │
│ └──────────────────────────┘ │                │      ▼                  │
│ ┌──────────────────────────┐ │                │     ▦ ▦ ▦  ← arraste a  │
│ │🌾 Trigo ⏱2min ...  [Plantar]│               │     ▦ ▦ ▦    semente por│
│ └──────────────────────────┘ │                │     ▦ ▦ ▦    vários     │
└──────────────────────────────┘                └─────────────────────────┘
```

### 4.3 Fogão — depois
```
        ┌────────────────────────────────┐
        │ Fogão   (🦴⏱0:42)(○)(○)(+🪙320)│  ← fila em bolinhas de 56 px
        │ ┌───┬───┬───┬───┐              │
        │ │🦴 │🍲 │🍎 │🍪 │  ← grade      │
        │ └───┴───┴───┴───┘              │
        │ Petisco: 🥕2/2  ⏱1min  [Cozinhar]│  ← linha da receita escolhida
        └──────────────▼─────────────────┘
                     fogão
```

### 4.4 Tela do Tiro — depois
```
┌──────────────────────────────┐
│(🐶)5               🪙3140  ⚙ │
│ (🦴)(💗)(⚡)(🫧)   anéis     📒│  ← caderninho
│   janela ☀   quarto          │
│          🐶  ( 🦴 )  balão   │
│      tapete                  │
│ ┌───┬───┬───┬───┬───┐        │
│ │🦴3│🥫11│🍓2│🧽 │🎾 │ ← bandeja: arraste até o Tiro
│ └───┴───┴───┴───┴───┘        │
│        [ 💤 Dormir ]         │
└──────────────────────────────┘
```

## 5. Princípios (valem para toda tela)
1. **Mundo em tela cheia;** HUD só nos cantos.
2. **Ação perto do dedo** (bandeja); painel grande só para consulta.
3. **Um botão principal por tela**; o resto é ícone, texto ou chip.
4. **Três superfícies distintas:** fundo (sem borda), cartão (borda fina, sem degrau), botão (degrau, cor viva).
5. **Arrastar quando faz sentido,** sempre com o toque simples como alternativa.
6. **Tudo se mexe um pouquinho** (150–300 ms), nunca atrapalhando o toque.
7. **Texto fala com o jogador,** curto e caloroso; um verbo por ação.
8. **Mobile primeiro:** alvo de toque ≥ 48 px, ações perto do polegar, nada essencial nos 40 px do topo.

## 6. O que NÃO muda
- Regras, números, save, história, missões, mundos e lugares (só a forma de mostrar).
- Arquitetura do `CLAUDE.md`: ações pelo `GameState`, estado só lá, sinais globais em `Events`.
- Renderer Compatibility, Web single-thread, toque como mouse.
