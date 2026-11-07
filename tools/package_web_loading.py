"""Instala a tela anterior ao motor e inclui suas artes no cache offline do PWA."""
import json
from pathlib import Path
import shutil
import sys

def package(output):
    source = Path(__file__).resolve().parents[1] / 'game' / 'web'
    output = Path(output)
    shutil.copytree(source / 'loading', output / 'loading', dirs_exist_ok=True)
    shutil.copy2(source / 'loading.js', output / 'loading.js')
    worker = output / 'index.service.worker.js'
    text = worker.read_text(encoding='utf-8')
    marker = '// Tiro loading assets\n'
    if marker not in text:
        files = ['loading.js'] + ['loading/' + p.name for p in sorted((source / 'loading').glob('*.webp'))]
        hook = 'const FULL_CACHE = CACHED_FILES.concat(CACHEABLE_FILES);'
        if hook not in text:
            raise RuntimeError('Template de service worker mudou; revisar integração do loading.')
        text = text.replace(hook, marker + 'CACHED_FILES.push(...' + json.dumps(files) + ');\n' + hook)
        worker.write_text(text, encoding='utf-8')

if __name__ == '__main__':
    package(sys.argv[1])
