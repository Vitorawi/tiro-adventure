import json
import tempfile
import unittest
from pathlib import Path

from content_map import ContentGraph, DATA
from content_pacing import PLAN, build_pacing, content_hash, read_run, save_plan


class PacingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.plan = self.root / "plan.json"
        self.plan.write_bytes(PLAN.read_bytes())
        self.evidence = self.root / "economy"
        self.stage = self.evidence / "etapa_99"
        self.stage.mkdir(parents=True)
        self.graph = ContentGraph().build()

    def tearDown(self):
        self.temp.cleanup()

    def run_file(self, folder="reference_s1", seed=1, hash=None, guards=0, **extra):
        directory = self.stage / folder
        directory.mkdir(exist_ok=True)
        run = {"profile": "reference", "seed": seed, "status": "complete", "params": {"until": "projects", "rare": "normal"},
               "content_hash": hash or content_hash(DATA), "guards": {"violations": guards},
               "milestones": {"stove": {"active_min": 4.2, "hours": .1, "session": 1}}, "quest_times": {}, **extra}
        path = directory / "summary.json"
        path.write_text(json.dumps(run), encoding="utf-8")
        return path

    def load(self, **options):
        return build_pacing(self.graph, DATA, plan_path=self.plan, evidence_dir=self.evidence, **options)

    def test_no_evidence_preserves_targets_without_invented_estimates(self):
        p = self.load()
        self.assertFalse(p["evidence"]["runs"])
        row = next(r for r in p["rows"] if r["id"] == "upgrade:stove")
        self.assertIsNone(row["active"])
        self.assertEqual(row["target"]["min"], 15)
        self.assertEqual(row["result"], "unmeasured")

    def test_same_content_compares_stale_does_not(self):
        path = self.run_file()
        p = self.load()
        self.assertTrue(p["evidence"]["matching"])
        self.assertEqual(next(r for r in p["rows"] if r["id"] == "upgrade:stove")["result"], "early")
        run = json.loads(path.read_text())
        run["content_hash"] = "old-content"
        path.write_text(json.dumps(run))
        p = self.load()
        self.assertFalse(p["evidence"]["matching"])
        self.assertEqual(next(r for r in p["rows"] if r["id"] == "upgrade:stove")["result"], "stale")

    def test_reads_actual_purchases_and_not_failed_actions(self):
        path = self.run_file()
        actions = [
            {"ev": "act", "ok": False, "kind": "buy_upgrade", "args": {"id": "workbench"}, "act": 30, "t": 40},
            {"ev": "act", "ok": True, "kind": "buy_upgrade", "args": {"id": "workbench"}, "act": 120, "t": 7200, "s": 2, "before": 200, "after": 40, "di": {"wood": -4, "bolt": 1}},
            {"ev": "act", "ok": True, "kind": "cook", "args": {"recipe": "carrot_snack"}, "act": 180, "t": 7300, "s": 2},
        ]
        path.with_name("ledger.jsonl").write_text("\n".join(json.dumps(a) for a in actions), encoding="utf-8")
        run = read_run(path)
        self.assertEqual(run["_times"]["upgrade:workbench"]["active_min"], 2)
        self.assertEqual(run["_times"]["upgrade:workbench"]["hours"], 2)
        self.assertEqual(run["_times"]["recipe:carrot_snack"]["active_min"], 3)
        transaction = run["_transactions"]["upgrade:workbench"]
        self.assertEqual(transaction["items"], {"wood": 4})
        self.assertEqual((transaction["before"], transaction["after"]), (200, 40))
        self.assertEqual(self.load()["journeys"][0]["transactions"]["upgrade:workbench"], transaction)

    def test_no_mixing_hashes_duplicates_or_invalid_runs(self):
        self.run_file()
        self.run_file("duplicate_s1")
        self.run_file("old_s2", seed=2, hash="old-content")
        self.run_file("invalid_s3", seed=3, guards=1)
        self.run_file("rare_s4", seed=4, params={"until": "projects", "rare": "worst"})
        p = self.load()
        self.assertEqual(p["evidence"]["runs"], 1)
        self.assertEqual(p["evidence"]["ignored"], 2)

    def test_partial_progress_is_not_converted_to_arrival(self):
        self.run_file(status="stalled", stall="luck")
        p = self.load()
        self.assertEqual(p["evidence"]["complete"], 0)
        row = next(r for r in p["rows"] if r["id"] == "project:park_picnic")
        self.assertEqual(row["reached"], 0)
        self.assertIsNone(row["active"])

    def test_chapter_uses_last_quest_when_hours_are_rounded_equal(self):
        members = [n for n in self.graph["nodes"] if n["kind"] == "quest" and n["data"].get("kind") == "main" and n["data"].get("chapter") == 1]
        self.run_file(quest_times={n["key"]: {"active_min": i + 1, "hours": .1, "session": 1} for i, n in enumerate(members)})
        row = next(r for r in self.load()["rows"] if r["id"] == "finish:chapter:1")
        self.assertEqual(row["active"]["median"], len(members))

    def test_edit_plan_persists_and_rejects_invalid_range(self):
        save_plan({"targets": {"upgrade:stove": {"min": 12, "max": 25, "note": "Teste de ritmo"}}}, self.plan)
        p = json.loads(self.plan.read_text(encoding="utf-8"))
        self.assertEqual(p["targets"]["upgrade:stove"]["min"], 12)
        self.assertEqual(p["targets"]["upgrade:stove"]["basis"], "user")
        before = self.plan.read_bytes()
        for value in [{"min": 40, "max": 20}, {"min": float("nan")}, {"max": -1}, {"max": True}]:
            with self.assertRaises(ValueError):
                save_plan({"targets": {"upgrade:stove": value}}, self.plan)
            self.assertEqual(self.plan.read_bytes(), before)


if __name__ == "__main__":
    unittest.main()
