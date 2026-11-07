# Etapa 02 — Arte por raridade (instalar e escolher a imagem certa)

> Tamanho: médio. Depende de: 01. Próxima: 03. **Pode ser repetida** sempre que o Vitor terminar lotes novos.
> Resultado que o Vitor vê: cada foto aparece com a arte do nível escolhido para exibição; se esse nível ainda
> não tem arte revisada, aparece a ilustração atual da própria foto.

## 1. Ler antes
**`INTEGRACAO_RARIDADES.md` inteiro (instruções do Vitor, valem acima deste arquivo).**
`01_DESENHO.md` §1, §10.1, §11. `tools/art/album_rarities/README.md` e `catalog.json`.
Código: `scripts/ui/photo_card.gd` (`make`, ramo `illustration`), `game/data/album.json`.

## 2. Como está hoje

| Coisa | Onde | Estado |
|---|---|---|
| Arte de cada foto | `album.json → photos[].photo.illustration` → `assets/sprites/ui/album/illustrated/<id>.png` (54, 1254×1254, mipmaps) | é o **fallback** |
| Arte por nível | `tools/art/album_rarities/photos/<seção>/<id>/{common,shiny,rare,holographic}.png` | fora do jogo; 44 revisados (11 fotos), 172 pendentes em 06/11 |
| Catálogo | `catalog.json → photos[].variants[chave].{status, path, integration_target, sha256}` | fonte da verdade |
| Validação | `tools/album_rarity_pipeline.py check` (Python do Codex: `C:/Users/Vitor/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`) | não instala |

## 3. Passo a passo

### 3.1 Instalador (`tools/album_rarity_install.gd`, script Godot `-s`, ou `.ps1`; idempotente)
1. Lê `catalog.json`; para cada foto e cada chave (`common`, `shiny`, `rare`, `holographic`) com
   `status == "reviewed"` e `path` existente: copia **reduzida para 768×768** (bilinear/lanczos, PNG) para o
   `integration_target` (`res://assets/sprites/ui/album/rarities/<id>/<chave>.png`).
2. Pula se o destino já existe com o mesmo hash de origem (grave um `rarities/manifest.json` com `id`, chave,
   `sha256` da origem, tamanho, data). Remove do destino o que deixou de estar `reviewed` (e avisa).
3. Nunca lê `tools/art/album_rarity_tests/` (histórico).
4. Depois rode `--import` e garanta `mipmaps/generate=true` em todos os `.import` novos (gere o `.import` ou
   corrija após o import, como os outros `tools/*_art.gd` fazem).
5. Imprime um resumo: instalados, pulados, removidos, fotos completas.

### 3.2 Escolher a imagem (`PhotoCard`)
1. Função pública `static func art_for(id: String, level: int) -> Texture2D`: mapeamento **explícito**
   `{1: "common", 2: "shiny", 3: "rare", 4: "holographic"}` → `res://.../rarities/<id>/<chave>.png` se existir
   (via `manifest.json` lido uma vez, ou `ResourceLoader.exists`); senão `photo.illustration` da própria foto.
   Nunca a imagem de outra foto.
2. `PhotoCard.make(id, width, options)` usa `options.level` se vier; senão `GameState.photo_shown_rarity(id)`;
   carta fechada (nível 0) continua mostrando o estado fechado de hoje (a etapa 05 faz o verso).
3. Todos os lugares que mostram a foto passam pelo `PhotoCard` (procure `PhotoCard.make` e
   `photo.illustration` em `scripts/` e `scenes/`): caderninho/álbum, detalhe, cerimônia/caderneta do
   crescimento (`CeremonyPhoto_<fase>`), Casa (`HouseUi.shelf/wall`, `HouseDecor`). Corrija quem lê a
   ilustração direto.

### 3.3 Exportação
Confira que `export_presets.cfg` inclui os PNGs novos (são recursos importados, entram normalmente) e o
`manifest.json` (arquivo não-recurso: acrescente ao `include_filter` se o instalador gravar JSON).

## 4. Não fazer
- Alterar `photo.illustration`, ids, raridade salva ou coleção do jogador.
- Colocar os originais 1254 no `res://`.
- Mostrar arte `generated`/`pending`.

## 5. Armadilhas
- O catálogo é foto antiga dos dados: confira `id` contra o `album.json` atual (o `check` do pipeline faz).
- Mapear pelo `label`/posição dá errado: use a chave.
- Se testar no navegador, refaça o export Web (o PCK não atualiza sozinho).

## 6. Testes
Novo **`tests/photo_art_test.gd`** (área `album`):
1. `art_for` de uma foto completa devolve as 4 texturas diferentes, cada uma do seu caminho.
2. Foto pendente: os 4 níveis devolvem a ilustração atual da própria foto.
3. Nunca devolve caminho de outra foto (varre as 54 × 4).
4. Trocar a versão mostrada (`set_photo_variant`) muda a textura do `PhotoCard`.
5. O instalador rodado duas vezes não copia nada na segunda (manifesto).
6. Texturas instaladas têm 768×768 e mipmaps.
Também rode o `check` do pipeline e cole o resultado no registro.
Lista fechada: `photo_art_test,photo_rarity_test,album_test,house_test`.
Capturas `tests/fotos_02_shots.gd`: uma foto completa nos 4 níveis + uma pendente nos 4 níveis (360×780).

## 7. Pronto quando
Instalador idempotente, `art_for` usado por todos os lugares, testes e `check` passando, capturas olhadas.
