# Ideias para depois da Interface 2 (NÃO executar agora)

O plano "Interface 2 — aconchego moderno" terminou na etapa 12. O que ficou de fora de propósito:

- **Sons e música.** O jogo continua sem nenhum som (`assets/audio/` vazio). É a maior mudança de "sensação"
  que falta: toque de botão, plantar, colher, moedas, latido, comemoração e música calma por mundo. Pacotes CC0
  (Kenney) servem; `.ogg` curto, carregado sob demanda no Web; precisa de preferência "Som/Música" ao lado de
  "Vibrar" no `settings.json`.
- **Tema escuro.** A bíblia (`01_BIBLIA_VISUAL.md`) já tem os tokens em `Palette`; falta uma segunda paleta
  e a troca no `main_theme.tres`. Pensado para jogar à noite.
- **Dia e noite nos mundos:** o céu do `backdrop` muda com a hora local; luzes nas janelas à noite.
- **Clima:** chuva leve no Sítio (só visual; regar sozinho mudaria regra).
- **Decorar a casa** arrastando móveis: precisa de estado novo no save e de regras de footprint.
- **Câmera de cinema** nos capítulos: a câmera passeia até o lugar novo quando ele abre.
- **Ícones das abas animados** (Tiro piscando, mochila balançando quando chega item).
- **Mão que ensina** (a dica de arrasto da horta) reaproveitada para outros gestos novos.
- **Fontes embutidas em tamanho maior:** "Texto maior" escala o tema em ×1,15; um segundo nível (×1,3) exigiria
  rever as grades de 4 colunas da Mochila.

Já feitos dentro do plano (não repetir): Texto maior (etapa 11), vibração e "Menos animação" (plano anterior).

## Após o plano Interface 2 — ajustes

Fechamento original e ressalvas históricas permanecem em `RESULTADOS.md`; resultado atual em
[`../interface2_ajustes/RESULTADOS.md`](../interface2_ajustes/RESULTADOS.md).

Resolvidos no plano de ajustes: fixtures world_life/world_pin e g01/t03 (01), aviso/folha/HUD (02),
recálculo de 8 Hz e um balão pronto pulando por sala (03), fogão/Tudo/regador (04), humor/cardápio/cerimônia
(05), fontes/caderninho/abas (06), capítulo/Novo! (07), Crescimento/seda (08), Como fazer/Lugares/conversa/compra
(09), hierarquia de texto (10), bloqueios/obras (11), apelidos/tema e reveal compartilhado (12).

Pendências preservadas para o Vitor, fora do plano:

- Corpo da bandeja do Galinheiro ainda precisa rolar com os animais e a fila.
- Custo de `GameState.update_finds/update_wishes` no tique de 1 s; comparar desempenho em navegador visível
  e aparelho, sem prometer 60 FPS. Números finais e brutos no resultado do plano de ajustes.
- Pílula Tudo próxima à borda direita do seletor de quantidade.
- A fala real do prêmio excede o orçamento ilustrativo de 14 palavras: preservada; redução depende de pedido.
- Manual mantém instruções e exemplos de catálogo; alguns ícones de conteúdo ficam junto ao texto.
- Roteiro físico de PWA, vibração, polegar e latência: executar quando o Vitor pedir publicação.
