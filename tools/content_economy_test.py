import json
import tempfile
import unittest
from pathlib import Path
from content_economy import ledger_economy


class EconomyTests(unittest.TestCase):
    def test_stock_requires_explicit_checkpoint_and_keeps_recorded_costs(self):
        rows = [{"ev": "start", "t": 0, "coins": 10, "di": {"wood": 999}},
                {"ev": "session_end", "t": 7200, "act": 600, "s": 1, "coins": 20,
                 "checkpoint": {"schema": 1, "coins": 20, "inventory": {"wood": 3},
                                "targets": [{"id": "mill", "cost": 100, "missing_coins": 80}]}}]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/"ledger.jsonl"
            path.write_text("\n".join(json.dumps(r) for r in rows), encoding="utf-8")
            result = ledger_economy(path)
        self.assertEqual(len(result["checkpoints"]), 1)
        self.assertEqual(result["checkpoints"][0]["inventory"], {"wood": 3})
        self.assertEqual(result["checkpoints"][0]["hours"], 2)
        self.assertEqual(result["checkpoints"][0]["targets"][0]["missing_coins"], 80)

    def test_daily_flow_reconciles_without_double_counting(self):
        rows = [
            {"ev": "start", "t": 0, "act": 0, "coins": 10},
            {"ev": "act", "t": 60, "act": 60, "coins": 30, "ok": True, "kind": "claim_quest", "di": {"wood": 4}, "dep": {"warehouse": [4, 8]}},
            {"ev": "session_end", "t": 60, "act": 60, "coins": 30},
            {"ev": "walk_return", "t": 86400, "act": 60, "coins": 35},
            {"ev": "act", "t": 86460, "act": 120, "coins": 15, "ok": True, "kind": "buy_upgrade", "di": {"wood": -3}, "dep": {"warehouse": [1, 8]}},
            {"ev": "act", "t": 86465, "act": 125, "coins": 15, "ok": False, "di": {"wood": 999}},
        ]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "ledger.jsonl"
            path.write_text("\n".join(json.dumps(r) for r in rows) + '\n{"unfinished":', encoding="utf-8")
            result = ledger_economy(path)
        first, second = result["days"]
        self.assertEqual((first["day"], second["day"]), (1, 2))
        self.assertEqual(first["income"], 20)
        self.assertEqual(second["income"], 5)
        self.assertEqual(second["expense"], 20)
        self.assertEqual(result["initial"] + sum(d["income"]-d["expense"] for d in result["days"]), second["balance"])
        self.assertEqual(first["items"]["wood"]["in"], 4)
        self.assertEqual(first["items"]["wood"]["sources"], {"claim_quest": 4})
        self.assertEqual(second["actions"], {"buy_upgrade": 1})
        self.assertEqual(sum(second["failures"].values()), 1)
        self.assertEqual(second["items"]["wood"]["out"], 3)
        self.assertEqual(second["items"]["wood"]["in"], 0)
        self.assertEqual(first["storage"]["warehouse"]["ratio"], .5)
        self.assertAlmostEqual(sum(d["active_min"] for d in result["days"]), 125/60)

    def test_missing_ledger_is_not_zero_economy(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(ledger_economy(Path(tmp)/"missing"), {"available": False, "days": [], "initial": None})


if __name__ == "__main__":
    unittest.main()
