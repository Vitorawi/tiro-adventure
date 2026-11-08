"""Imagens ilustradas grandes entram no pacote como WebP com perda (qualidade 0,9).

No navegador o Godot mantém o .pck inteiro na memória; no iPhone isso derrubava
a página (pisca e recarrega). Sem perda, o álbum e os clipes do bebê somavam
~200 MB; com perda em qualidade alta ficam 4-5x menores, sem diferença visível.

Só muda os .import (as PNGs de origem ficam intactas). Idempotente.
Depois rode:  godot --headless --path game --import

Preservados sem perda: a respiração aprovada do bebê (regra da idle congelada)
e as referências de identidade (recortes exatos dos avatares).
Uso:  py -X utf8 -I tools/web_lossy_imports.py [--check]
"""
import re
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "game"
QUALITY = "0.9"
GLOBS = [
    "assets/sprites/ui/album/illustrated/*.png.import",
    "assets/sprites/ui/album/rarities/*/*.png.import",
    "assets/sprites/characters/tiro_pet_puppy_animaref/*.png.import",
]
KEEP_LOSSLESS = {"idle_breathe.png.import", "reference.png.import",
                 "reference_front.png.import", "reference_head.png.import"}


def wanted(text: str) -> str:
    text = re.sub(r"compress/mode=\d", "compress/mode=1", text)
    return re.sub(r"compress/lossy_quality=[0-9.]+", "compress/lossy_quality=" + QUALITY, text)


def main() -> int:
    check = "--check" in sys.argv
    changed = total = 0
    for pattern in GLOBS:
        for path in sorted(GAME.glob(pattern)):
            if path.name in KEEP_LOSSLESS:
                continue
            total += 1
            text = path.read_text(encoding="utf-8")
            new = wanted(text)
            if new != text:
                changed += 1
                if not check:
                    path.write_text(new, encoding="utf-8", newline="\n")
    verb = "fora do padrão" if check else "alterados"
    print(f"WEB LOSSY: {total} imagens, {changed} {verb}")
    return 1 if check and changed else 0


if __name__ == "__main__":
    sys.exit(main())
