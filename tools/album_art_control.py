"""Atualiza o catálogo local de arte sem modificar album.json nem imagens.

Uso: powershell -NoProfile -File tools/album_art_control.ps1
"""
import hashlib
import html
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / 'docs/art/album_ilustrado'
MANIFEST = REPORT / 'manifest.json'
PHASES = {'newborn': 'Recém-chegado', 'puppy': 'Filhotinho', 'teething': 'Dentinhos',
          'explorer': 'Aventureiro', 'young': 'Mocinho', 'adult': 'Azul e Dourado'}


def relative(path):
    import os
    return Path(os.path.relpath(ROOT / path, REPORT)).as_posix()


def main():
    data = json.loads(MANIFEST.read_text(encoding='utf-8-sig'))
    photos = data['photos']
    assert len(photos) == 54 and len({p['id'] for p in photos}) == 54
    album = json.loads((ROOT / 'game/data/album.json').read_text(encoding='utf-8-sig'))
    definitions = {p['id']: p for p in album['photos']}
    rows, cards, fingerprints = [], [], {}
    generated = 0
    for p in photos:
        assert p['id'] in definitions
        record_path = REPORT / 'generation_records' / (p['id'] + '.json')
        if record_path.is_file():
            p.update(json.loads(record_path.read_text(encoding='utf-8')))
        p['portable_reference_paths'] = []
        for reference in p.get('reference_paths', []):
            normalized = reference.replace('\\', '/')
            if normalized.endswith('/1-Imagem-colada-1.jpg'):
                normalized = 'docs/art/album_ilustrado/references/style_original.jpg'
            elif normalized.lower().startswith(ROOT.as_posix().lower() + '/'):
                normalized = normalized[len(ROOT.as_posix()) + 1:]
            p['portable_reference_paths'].append(normalized)
        output = ROOT / p['new_path']
        p['original_capture_exists'] = (ROOT / p['original_capture']).is_file()
        installed = definitions[p['id']]['photo'].get('illustration', '')
        p['installed_path'] = 'game/' + installed.removeprefix('res://') if installed.startswith('res://') else None
        p['installed'] = False
        if output.is_file():
            raw = output.read_bytes()
            assert raw[:8] == b'\x89PNG\r\n\x1a\n', output
            width, height = struct.unpack('>II', raw[16:24])
            assert width == height and width >= 1024, (output, width, height)
            digest = hashlib.sha256(raw).hexdigest()
            assert digest not in fingerprints, (output, fingerprints.get(digest))
            fingerprints[digest] = p['id']
            p.update(status='generated', width=width, height=height, bytes=len(raw), sha256=digest)
            if p['installed_path']:
                installed_file = ROOT / p['installed_path']
                p['installed'] = installed_file.is_file() and hashlib.sha256(installed_file.read_bytes()).hexdigest() == digest
            generated += 1
        status = 'Instalada localmente' if p['installed'] else ('Gerada; aguarda troca' if p['status'] == 'generated' else 'Pendente')
        phase = PHASES[p['phase']]
        source = p['source_definition']
        original = f"[original]({relative(p['original_capture'])})" if p['original_capture_exists'] else 'captura pendente'
        new = f"[nova]({relative(p['new_path'])})" if p['status'] == 'generated' else f"`{p['new_path']}`"
        target = f"`{p['installed_path']}`" if p['installed'] else '—'
        rows.append(f"| `{p['id']}` | {p['title']} | {phase} | {original} | {new} | {target} | {status} |")
        esc = html.escape
        pictures = ''
        for label, path, exists in [('Original', p['original_capture'], p['original_capture_exists']),
                                    ('Nova', p['new_path'], p['status'] == 'generated')]:
            uri = esc(relative(path), quote=True)
            content = f'<a href="{uri}"><img loading="lazy" src="{uri}" alt="{label}: {esc(p["title"])}"></a>' if exists else '<p>Pendente</p>'
            pictures += f'<figure>{content}<figcaption>{label}</figcaption></figure>'
        cards.append(f'<article data-section="{p["section"]}"><h2>{esc(p["title"])}</h2><p><code>{p["id"]}</code> · {phase} · {status}</p><div class="pair">{pictures}</div><details><summary>Origem e caminhos</summary><p>{esc(source)}</p><p>{esc(p["new_path"])}</p><p>{esc(p["scene_prompt"])}</p></details></article>')
    data['summary'] = {'total': len(photos), 'generated': generated, 'pending': len(photos)-generated,
                       'installed': sum(p['installed'] for p in photos),
                       'original_captures': sum(p['original_capture_exists'] for p in photos)}
    MANIFEST.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    text = f'''# Controle do álbum ilustrado

## Progresso

**{generated}/54 geradas**, {54-generated} pendentes; {data['summary']['installed']} instaladas localmente.
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
''' + '\n'.join(rows) + '''

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
'''
    (REPORT / 'CONTROLE.md').write_text(text, encoding='utf-8')
    gallery = '''<!doctype html><html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Álbum do Tiro — original × ilustração</title><style>body{margin:0;background:#fff5e5;color:#493023;font:16px system-ui}header,main{max-width:1200px;margin:auto;padding:24px}h1{margin-bottom:8px}article{background:#fffaf2;border:1px solid #d6bb96;border-radius:18px;padding:20px;margin:24px 0}h2{margin:0}code{font-size:.85em}article p{color:#735b48}nav{display:flex;gap:8px;flex-wrap:wrap}button{background:#eed9b9;border:0;border-radius:20px;padding:10px 16px;font:inherit;cursor:pointer}button.on{background:#517441;color:white}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}figure{margin:0;text-align:center}img{width:100%;height:auto;aspect-ratio:1;object-fit:contain;background:#f3e6d1;border-radius:10px}figcaption{padding:8px}details{overflow-wrap:anywhere}a{color:#426338}@media(max-width:560px){header,main{padding:12px}.pair{gap:8px}article{padding:12px}}</style><header><h1>Álbum do Tiro</h1>'''
    gallery += f'<p>{generated}/54 ilustrações geradas · originais e novas lado a lado · não publicado</p>'
    gallery += '<p>Fase indicada é a referência artística; o original foi reconstituído nessa fase.</p><nav>'
    sections = [('all','Todas'),('story','História'),('firsts','Primeiras vezes'),('tricks','Travessuras'),('sleep','Soninhos'),('friends','Amigos'),('dates','Datas')]
    gallery += ''.join(f'<button data-filter="{key}" class="{"on" if key == "all" else ""}">{label}</button>' for key,label in sections)
    gallery += '</nav></header><main>' + ''.join(cards) + '</main><script>document.querySelectorAll("button").forEach(b=>b.onclick=()=>{document.querySelectorAll("button").forEach(x=>x.classList.toggle("on",x===b));document.querySelectorAll("article").forEach(a=>a.hidden=b.dataset.filter!=="all"&&a.dataset.section!==b.dataset.filter)})</script></html>'
    (REPORT / 'galeria.html').write_text(gallery, encoding='utf-8')
    print(json.dumps(data['summary'], ensure_ascii=False))


if __name__ == '__main__':
    main()
