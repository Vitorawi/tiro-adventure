"""Guarded Godot Web loader patches: one owned buffer per downloaded PCK.

No persistent filesystem paths are changed. Fail exports if the upstream loader
changes, instead of silently shipping the old high-memory path.
"""
from pathlib import Path


PACK_READER = """// Tiro: read the pack into its final allocation, without Response.arrayBuffer's
// intermediate collection of all download chunks. Sizes come from Godot's export.
async function tiroReadPack(response, status, size) {
    const bytes = new Uint8Array(size);
    const reader = response.body.getReader();
    let offset = 0;
    try {
        while (true) {
            const {done, value} = await reader.read();
            if (done) break;
            if (offset + value.length > size) throw new Error('Game pack size mismatch; reload to update.');
            bytes.set(value, offset);
            offset += value.length;
            status.loaded = offset;
        }
        if (offset !== size) throw new Error('Incomplete game pack; please retry.');
        status.done = true;
        return bytes.buffer;
    } finally {
        await reader.cancel().catch(() => {});
        reader.releaseLock();
    }
}
"""


def patch_engine(path):
    path = Path(path)
    text = path.read_text(encoding='utf-8')
    if '// Tiro: read the pack' in text:
        return
    hooks = [
        ('const Preloader =', PACK_READER + '\nconst Preloader ='),
        ('const tr = getTrackedResponse(response, tracker[file]);',
         "if (!raw && /\\.pck(?:[?#]|$)/.test(file) && Number.isSafeInteger(fileSize) && fileSize > 0) {\n"
         '\t\t\t\treturn tiroReadPack(response, tracker[file], fileSize);\n\t\t\t}\n'
         '\t\t\tconst tr = getTrackedResponse(response, tracker[file]);'),
        # Emscripten MEMFS may own the immutable pack buffer. Other callers keep
        # ordinary copy semantics (including saves and JS bridge byte arrays).
        ('FS.writeFile(path,new Uint8Array(buffer))',
         'FS.writeFile(path,new Uint8Array(buffer),{canOwn:typeof path==="string"&&path.endsWith(".pck")&&buffer instanceof ArrayBuffer})'),
    ]
    for old, new in hooks:
        if text.count(old) != 1:
            raise RuntimeError(f'Godot Web loader changed: expected one {old!r}; review memory patch.')
        text = text.replace(old, new, 1)
    path.write_text(text, encoding='utf-8')
