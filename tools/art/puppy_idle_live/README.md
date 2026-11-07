# Respiração ilustrada do bebê — teste no jogo

Instalação/publicação solicitada pelo Vitor em 07/11/2026 para avaliar no celular.

Só `idle_breathe` do bebê na aba Tiro usa os nove PNGs de
`game/assets/sprites/characters/tiro_pet_puppy_illustrated/idle_breathe/`.
Canvas 768×648 = 3× o original; nove quadros e 6 fps, sem mudar o relógio.
Derivados da tentativa `tiro_idle_landmarks_v3` (nove desenhos com registro interno).
`manifest.json` guarda os hashes finais.

**Para voltar:** engrenagem → **Bebê ilustrado** → desligar. O pixel volta na hora,
sem apagar progresso nem reiniciar; a escolha fica em `settings.json`/`settings_dev.json`.
É preferência do aparelho, padrão ligado; não altera versão/formato dos saves.

Os PNGs pixel originais não foram sobrescritos. Outras animações do bebê,
retratos, Tiro do mapa e fases seguintes continuam originais. A pintura usa
linear+mipmaps e não passa pelo shader de cores da pixel art; ao voltar ao
pixel, filtro e material originais são restaurados.

Regressão `puppy_idle_preview_test`: recurso novo, nove quadros/6 fps, preferência
persistida/reversão, interruptor real, outros clipes, retratos e Dentinhos.
Capturas nativas dos dois modos em `build/screenshots/puppy_idle_preview/`.
Primeira checagem detectou importação pendente dos PNGs; após importar/mipmaps,
reexecução completa do teste com render nativo PASS. Afetados `pet_care_test`,
`saves_test` e `growth_ui_test` PASS, com scripts/conteúdo/textos PASS.

Reprodução da arte: executar `tiro_idle_shiny_v1/prepare_preview.py` para extrair
os nove desenhos da folha gerada; em seguida `tiro_idle_landmarks_v3/prepare.py`
para registrar marcos (Pillow/OpenCV/numpy); copiar os nove `frames_3x` para a
pasta de recursos acima e importar no Godot. Os originais do jogo permanecem
somente como entrada. Prévia é experimento artístico, sem promessa de equivalência
pixel a pixel de toda a deformação interna.
