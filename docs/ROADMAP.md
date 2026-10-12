# Roadmap

## Fase 0 — Fundação
- [x] Estrutura de pastas e documentação
- [x] Projeto Godot 4.7.2 (Compatibility, pixel art, celular em pé 360x780)
- [x] Autoloads `Events`, `GameState`, `SaveManager`
- [x] Preset Web PWA single-thread + scripts de export/servidor local
- [x] Workflow de deploy no GitHub Pages
- [ ] Repositório no GitHub + primeiro deploy
- [ ] Testar instalação PWA e save no iPhone e no Android

## Fase 1 — Design
- [x] Ideia do jogo registrada (`GAME_DESIGN.md`)
- [ ] Receber referências visuais (`docs/references/`)
- [ ] Responder perguntas em aberto do design
- [ ] Padrões de arte (tamanho de tile/personagem, paleta)

## Fase 2 — MVP (ver escopo em `GAME_DESIGN.md`)
- [ ] Base: toque/arrasto de câmera, componente de objeto tocável, tempo real offline
- [ ] Tela do Pet: cachorro + necessidades + interações
- [ ] Mundo: Casa (geladeira, fogão) com cachorro autônomo
- [ ] Inventário + Horta (plantar/colher) + receitas no fogão
- [ ] 1 personagem com 3 missões
- [ ] Primeiros assets no PixelLab

## Backlog / ideias técnicas
- [ ] `AudioManager` (música/sfx; destravar áudio no primeiro toque)
- [ ] Exportar/importar save como código (backup manual)
- [ ] Aviso "nova versão disponível" no PWA
- [ ] Testes automatizados headless no CI
