#!/usr/bin/env python3
"""Autoteste do auditor de economia: dados reais passam; uma cópia temporária quebrada falha.

Não altera game/data: a fixture é uma cópia em pasta temporária.
Uso: py -X utf8 -I tools/economy_audit_selftest.py
"""
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
AUDIT = REPO / "tools" / "economy_audit.py"


def run(data: Path, out: Path) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, "-X", "utf8", "-I", str(AUDIT), "--data", str(data), "--out", str(out)],
                          capture_output=True, text=True, encoding="utf-8")


def load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def save(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> int:
    failures: list[str] = []
    with tempfile.TemporaryDirectory(prefix="economy_audit_") as tmp:
        tmp_path = Path(tmp)
        real = run(REPO / "game" / "data", tmp_path / "real")
        if real.returncode != 0:
            failures.append(f"dados reais deveriam passar (saída {real.returncode}): {real.stderr.strip()[:300]}")

        data = tmp_path / "data"
        shutil.copytree(REPO / "game" / "data", data)
        quests = load(data / "quests.json")
        quests["first_harvest"]["requirements"] = {"quests": ["missao_inexistente"]}
        quests["welcome"]["goals"][0] = {"type": "have", "key": "item_fantasma", "target": 1}
        save(data / "quests.json", quests)
        recipes = load(data / "recipes.json")
        recipes["carrot_snack"]["inputs"] = {"cenoura_inexistente": 2}
        save(data / "recipes.json", recipes)
        progression = load(data / "progression.json")
        progression["upgrades"]["silo"]["requirements"] = {"quests": ["bloblo_silo"]}  # ciclo: silo ↔ bloblo_silo
        save(data / "progression.json", progression)

        broken = run(data, tmp_path / "broken")
        references = (tmp_path / "broken" / "references.md").read_text(encoding="utf-8")
        if broken.returncode == 0:
            failures.append("fixture quebrada deveria falhar (saída 0)")
        for expected in ("missao_inexistente", "item_fantasma", "cenoura_inexistente", "quest:bloblo_silo"):
            if expected not in references:
                failures.append(f"references.md deveria citar '{expected}'")

    if failures:
        for failure in failures:
            print("FALHA:", failure)
        print("ECONOMY AUDIT SELFTEST: FAIL")
        return 1
    print("ECONOMY AUDIT SELFTEST: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
