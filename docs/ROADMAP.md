# Roadmap

## Fase 0 — Fundação
- [x] Estrutura de pastas e documentação
- [x] Projeto Godot 4.7.2 (Compatibility, pixel art, celular em pé 360x780)
- [x] Autoloads `Events`, `GameState`, `SaveManager`
- [x] Preset Web PWA single-thread + scripts de export/servidor local
- [x] Workflow de deploy no GitHub Pages
- [x] Repositório no GitHub + primeiro deploy
- [ ] Testar instalação PWA e save no iPhone e no Android

## Fase 1 — Design
- [x] Ideia do jogo registrada (`GAME_DESIGN.md`)
- [ ] Receber referências visuais (`docs/references/`)
- [ ] Responder perguntas em aberto do design
- [ ] Padrões de arte (tamanho de tile/personagem, paleta)

## Fase 2 — Iteração 1 (ver `GAME_DESIGN.md`)
- [x] Base: toque/arrasto de câmera, `Hotspot`, tempo real offline, save automático
- [x] Tela do Pet: Tiro detalhado + 4 necessidades + comer/brincar/banho/dormir/carinho
- [x] Casa: geladeira, fogão (fila), tigela, sofá, brinquedos; Tiro autônomo
- [x] Inventário + receitas no fogão (dados em JSON) + XP/nível
- [x] Sprites PixelLab: Tiro pet (128px) e Tiro mundo (4 direções + andar)
- [x] Casa montada no PixelLab: sala vazia + móveis separados (geladeira, fogão, tigela, sofá)
- [x] Colisão com móveis (grade de navegação), profundidade (Y-sort), toque por pixel, sombra do Tiro
- [x] Animações do Tiro no mundo: andar, parado, sentar, latir, dormir, comer
- [ ] Mais móveis/decoração (caminha, brinquedos, TV, mesa) — por enquanto casa enxuta
- [ ] Barra de segurança no topo para notch do iPhone

## Iteração 2
- [x] Horta: Sítio da Bloblo (aba Sítio + porta da casa), 6 canteiros, cenoura/batata/abóbora (`crops.json`)
- [ ] Bloblo como personagem (retrato + missões); Tiro passeando no sítio
- [ ] Tutor dentro de casa (sprite pequeno + retrato detalhado + diálogo) com missões
- [ ] Moedas: vender produtos

## Iteração 3
- [ ] Customização (Ateliê): camadas de roupa/acessório sobre o Tiro detalhado
- [ ] Parque: passeio, truques, minigames

## Backlog / ideias técnicas
- [ ] `AudioManager` (música/sfx; destravar áudio no primeiro toque)
- [ ] Exportar/importar save como código (backup manual)
- [ ] Aviso "nova versão disponível" no PWA
- [ ] Testes automatizados headless no CI
