"""Autoteste de tools/economy_compare.py (etapa 01 do plano de economia).

Gera dois summary.json sintéticos em uma pasta temporária, roda o relatório e confere que ele
rotula as medidas como SIMULADAS, mostra os marcos, separa bloqueio do jogo de falha de política
e escreve os gráficos. Uso: py -X utf8 -I tools/economy_compare_selftest.py
"""
from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def fake(profile: str, seed: int, status: str, quests: int, blocks: dict) -> dict:
    return {
        "profile": profile, "seed": seed, "status": status, "stall": "",
        "end": {"days": 3.0, "coins": 500 + seed, "quests": quests, "quests_total": 81, "upgrades": 20, "upgrades_total": 48},
        "time": {"active_min": 100.0 + seed, "forced_wait_min": 5.0, "nav_min": 20.0, "sessions": 8, "actions": 500, "first_session_idle_pct": 10.0},
        "guards": {"violations": 0, "details": []},
        "milestones": {"first_harvest": {"active_min": 1.5, "hours": 0.0, "session": 1, "day": 0}, "first_wish": {"active_min": 1.5, "hours": 0.0, "session": 1, "day": 0}},
        "coin_flow": {"recurring:harvest": 900, "recurring:order": 300, "unique:quest": 400, "spend:buy_upgrade": -800},
        "item_flow": {"made:carrot": 50}, "waits_by_reason": {"lavoura": 120.0}, "blocks": blocks,
        "actions_by_why": {"goal": 10, "space": 2}, "pending_at_close": [{"plots": 1, "stations": 0, "nature": 0, "walk": 0, "outside_depots": 4}],
        "quest_times": {"a": {"active_min": 1.0}, "b": {"active_min": 3.0}}, "daily": [{"day": 0, "coins": 100}, {"day": 1, "coins": 300}],
        "unclaimed": ["merchant_festival"], "last_sessions": [{"focus": "merchant_festival", "focus_why": "no_path:treat_box"}],
    }


def main() -> int:
    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        for name, data in (("reference_s1", fake("reference", 1, "stalled", 80, {"jogo:storage": 3, "politica:no_path": 5})), ("light_s1", fake("light", 1, "horizon", 40, {}))):
            (base / name).mkdir()
            (base / name / "summary.json").write_text(json.dumps(data), encoding="utf-8")
        out = base / "relatorio"
        result = subprocess.run([sys.executable, "-X", "utf8", "-I", str(ROOT / "tools" / "economy_compare.py"), "--in", str(base), "--out", str(out)], capture_output=True, text=True, encoding="utf-8")
        report = (out / "report.md").read_text(encoding="utf-8") if (out / "report.md").exists() else ""
        checks = {
            "saiu com código 0": result.returncode == 0,
            "rotula como SIMULADO": "SIMULADO" in report and "auditor estático" in report,
            "mostra marcos": "Primeira colheita" in report and "1.5 / 1.5 / 1.5" in report,
            "separa jogo de política": "jogo:storage" in report and "politica:no_path" in report,
            "explica a parada": "merchant_festival" in report and "no_path:treat_box" in report,
            "escreve gráficos": (out / "charts" / "missoes_x_tempo_ativo.svg").exists() and (out / "charts" / "moedas_x_dia.svg").exists(),
            "moedas recorrentes e únicas": "% recorrente" in report,
        }
        for label, ok in checks.items():
            print(("ok   " if ok else "FALHOU ") + label)
            failures += 0 if ok else 1
        empty = subprocess.run([sys.executable, "-X", "utf8", "-I", str(ROOT / "tools" / "economy_compare.py"), "--in", str(base / "nada")], capture_output=True, text=True, encoding="utf-8")
        print(("ok   " if empty.returncode == 2 else "FALHOU ") + "pasta sem resultados devolve 2")
        failures += 0 if empty.returncode == 2 else 1
        # Incluir raro zero no conjunto rotulado, sem misturar as medianas com sorte normal.
        for name, rare in (("reference_s1_final", "normal"), ("reference_s1_final_raro0", "worst")):
            data = fake("reference", 1, "complete", 81, {})
            data["params"] = {"rare": rare}
            (base / name).mkdir()
            (base / name / "summary.json").write_text(json.dumps(data), encoding="utf-8")
        tagged = subprocess.run([sys.executable, "-X", "utf8", "-I", str(ROOT / "tools" / "economy_compare.py"), "--in", str(base), "--out", str(out), "--tag", "final"], capture_output=True, text=True, encoding="utf-8")
        report = (out / "report.md").read_text(encoding="utf-8")
        ok = tagged.returncode == 0 and "Execuções: 2" in report and "| reference (raro zero) | 1 |" in report and "| reference | 1 |" in report
        print(("ok   " if ok else "FALHOU ") + "rótulo inclui raro zero e mantém estatísticas separadas")
        failures += 0 if ok else 1
    print("ECONOMY COMPARE SELFTEST: " + ("PASS" if failures == 0 else f"FAIL ({failures})"))
    return 0 if failures == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
