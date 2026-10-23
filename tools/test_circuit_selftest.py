"""Contratos do seletor em um workspace temporário, sem executar o Godot."""
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent


class CircuitTests(unittest.TestCase):
    def test_selection_and_guards(self):
        with tempfile.TemporaryDirectory(prefix="tiro_circuit_") as folder:
            root = Path(folder)
            (root / "tools").mkdir()
            (root / "game/tests").mkdir(parents=True)
            shutil.copy(ROOT / "tools/test.ps1", root / "tools/test.ps1")
            data = json.loads((ROOT / "tools/test_areas.json").read_text(encoding="utf-8"))
            for area in data["areas"].values():
                area["paths"] = [p for p in area["paths"] if not p.startswith("game/tests/")]
            for name in data["suite"]:
                name = "dev_tools_test" if name == "dev_tools_test_prod" else name
                (root / f"game/tests/{name}.gd").touch()
            manifest = root / "tools/test_areas.json"
            manifest.write_text(json.dumps(data), encoding="utf-8")
            subprocess.run(["git", "init", "--quiet", str(root)], check=True)
            # Fixture files do not count as changes: only production paths select areas here.
            subprocess.run(["git", "-C", str(root), "add", "."], check=True, capture_output=True)

            def run(*args):
                return subprocess.run(
                    ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                     str(root / "tools/test.ps1"), *args, "-DryRun"],
                    cwd=root, capture_output=True, text=True, errors="replace", timeout=30,
                )

            selected = run("-Level", "etapa", "-Areas", "wishes")
            self.assertEqual(selected.returncode, 0, selected.stdout + selected.stderr)
            self.assertIn("scripts_check, content_test, texts_test, wish_moments_test", selected.stdout)
            (root / "game/data").mkdir()
            (root / "game/data/wishes.json").write_text("{}")
            automatic = run("-Level", "etapa")
            self.assertIn("wish_moments_test", automatic.stdout)
            (root / "game/autoload").mkdir()
            (root / "game/autoload/game_state.gd").touch()
            broad = run("-Level", "etapa")
            self.assertIn("game_state.gd mudou: passe -Areas", broad.stdout)
            self.assertNotIn("growth_test,", broad.stdout)
            scope = root / "task_scope.txt"
            scope.write_text("# Escopo desta tarefa\ngame/autoload/game_state.gd\n", encoding="utf-8")
            scoped = run("-Level", "etapa", "-ChangeList", str(scope), "-Tests", "moments_test")
            self.assertEqual(scoped.returncode, 0, scoped.stdout + scoped.stderr)
            self.assertIn("moments_test", scoped.stdout)
            self.assertNotIn("wish_moments_test", scoped.stdout)
            self.assertNotEqual(run("-Level", "etapa", "-ChangeList", str(scope), "-Since", "HEAD").returncode, 0)
            scope.write_text("../outside.gd\n", encoding="utf-8")
            self.assertNotEqual(run("-Level", "etapa", "-ChangeList", str(scope)).returncode, 0)
            self.assertNotEqual(run("-Level", "etapa", "-Tests", "unknown_test").returncode, 0)
            self.assertNotEqual(run("-Level", "etapa", "-Areas", "unknown_area").returncode, 0)
            gate = run("-Level", "portao")
            self.assertEqual(gate.returncode, 0, gate.stderr)
            self.assertNotIn("progression_test,", gate.stdout)
            campaign = run("-Level", "campanha")
            self.assertEqual(campaign.returncode, 0, campaign.stderr)
            self.assertIn("progression_test, economy_sim_test", campaign.stdout)
            data["suite"].append("orphan_test")
            manifest.write_text(json.dumps(data), encoding="utf-8")
            orphan = run("-Level", "rapido")
            self.assertNotEqual(orphan.returncode, 0)
            self.assertIn("orphan_test", orphan.stderr)


if __name__ == "__main__":
    unittest.main()
