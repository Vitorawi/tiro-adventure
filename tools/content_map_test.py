"""Validação das relações e da releitura dinâmica. Não executa o jogo."""
import json
import tempfile
import threading
import unittest
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import urlopen

from content_map import ContentGraph, DATA, Handler, ThreadingHTTPServer


class ContentMapTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.graph = ContentGraph().build()
        cls.nodes = {n["id"]: n for n in cls.graph["nodes"]}

    def has_edge(self, source, target, relation=None):
        return any(e["source"] == source and e["target"] == target and
                   (relation is None or e["relation"] == relation) for e in self.graph["edges"])

    def test_all_references_resolve_and_ids_are_unique(self):
        self.assertEqual(self.graph["warnings"], [])
        self.assertEqual(len(self.nodes), len(self.graph["nodes"]))
        for e in self.graph["edges"]:
            self.assertIn(e["source"], self.nodes)
            self.assertIn(e["target"], self.nodes)

    def test_production_and_storage_match_current_content(self):
        for key, recipe in ContentGraph().docs["recipes"].items():
            for item in recipe.get("inputs", {}):
                self.assertTrue(self.has_edge(f"item:{item}", f"recipe:{key}", "input"))
            kind = "collection" if recipe.get("output_collection") else "item"
            output = recipe.get("output_collection", recipe.get("output"))
            self.assertTrue(self.has_edge(f"recipe:{key}", f"{kind}:{output}", "output"))
        self.assertTrue(self.has_edge("item:carrot", "storage:silo", "storage"))
        self.assertTrue(self.has_edge("item:vegetable_soup", "storage:fridge", "storage"))
        self.assertFalse(any(e["source"] == "item:bolt" and e["relation"] == "storage" for e in self.graph["edges"]))

    def test_quest_goals_shared_milestones_and_implicit_sequences(self):
        self.assertTrue(self.has_edge("item:carrot", "quest:bloblo_carrots", "goal"))
        self.assertTrue(self.has_edge("quest:guide_open_cave", "quest:main_5_pickaxe", "shared"))
        quests = ContentGraph().docs["quests"]
        line = sorted(((k, v) for k, v in quests.items() if v.get("line") == "bloblo"), key=lambda kv: kv[1]["order"])
        for (before, _), (after, _) in zip(line, line[1:]):
            self.assertTrue(self.has_edge(f"quest:{before}", f"quest:{after}", "sequence"))

    def test_rewards_are_sources_not_consumers(self):
        self.assertTrue(self.has_edge("quest:welcome", "item:dog_food", "reward"))
        self.assertFalse(self.has_edge("item:dog_food", "quest:welcome", "input"))
        self.assertTrue(self.has_edge("walk:park_loop", "collection:plaid_bow", "random"))
        self.assertTrue(self.has_edge("reward:legendary", "collection:sponge_hat", "reward"))

    def test_project_phases_and_unlock_alternatives(self):
        self.assertTrue(self.has_edge("item:plank", "phase:park_bench:base", "input"))
        self.assertTrue(self.has_edge("phase:park_bench:base", "phase:park_bench:comfort", "sequence"))
        self.assertTrue(self.has_edge("reward:treasure", "crop:blueberry", "unlock"))

    def test_growth_materials_pillars_and_memories(self):
        self.assertTrue(self.has_edge("item:chew_ring", "growth:teething", "input"))
        self.assertTrue(self.has_edge("item:growth_kibble", "growth:explorer", "goal"))
        self.assertTrue(self.has_edge("item:growth_kibble", "pillar:body", "care"))
        self.assertTrue(self.has_edge("pillar:smart", "growth:explorer", "requirement"))
        self.assertTrue(self.has_edge("growth:teething", "growth:explorer", "sequence"))
        self.assertTrue(self.has_edge("growth:puppy", "album:h_growth_puppy", "reward"))
        self.assertTrue(self.has_edge("growth:puppy", "house:height_chart", "unlock"))
        self.assertTrue(self.has_edge("growth:adult", "growth:silk_1", "requirement"))
        self.assertTrue(self.has_edge("growth:young", "recipe:sew_topknot_bow", "requirement"))
        phase = self.nodes["growth:explorer"]
        req = next(r for r in phase["data"]["requirements"] if r["id"] == "care_smart")
        self.assertEqual(req["levels"]["smart"], 2)

    def test_reloads_changed_files_and_new_definitions_without_generation(self):
        with tempfile.TemporaryDirectory() as temp:
            directory = Path(temp)
            for path in DATA.glob("*.json"):
                (directory / path.name).write_bytes(path.read_bytes())
            before = ContentGraph(directory).build()
            items = json.loads((directory / "items.json").read_text(encoding="utf-8-sig"))
            items["atlas_test"] = {"name": "Novo produto", "category": "food", "storage": "fridge"}
            (directory / "items.json").write_text(json.dumps(items), encoding="utf-8")
            recipes = json.loads((directory / "recipes.json").read_text(encoding="utf-8-sig"))
            recipes["atlas_test"] = {"station": "stove", "inputs": {"carrot": 7}, "output": "atlas_test", "seconds": 47}
            (directory / "recipes.json").write_text(json.dumps(recipes), encoding="utf-8")
            after = ContentGraph(directory).build()
            self.assertNotEqual(before["revision"], after["revision"])
            self.assertEqual(next(n for n in after["nodes"] if n["id"] == "recipe:atlas_test")["data"]["seconds"], 47)
            self.assertTrue(any(e["source"] == "item:carrot" and e["target"] == "recipe:atlas_test" and e["amount"] == 7 for e in after["edges"]))

    def test_server_exposes_only_catalog_ui_and_assets(self):
        server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        server.data_dir = DATA
        worker = threading.Thread(target=server.serve_forever, daemon=True)
        worker.start()
        url = f"http://127.0.0.1:{server.server_port}"
        try:
            for path in ["/", "/app.js", "/api/graph", "/api/revision", "/game/data/items.json"]:
                with urlopen(url + path) as response:
                    self.assertEqual(response.status, 200)
            for path in ["/AGENTS.md", "/.codex/config.toml", "/%2e%2e/AGENTS.md", "/game/assets/../../project.godot"]:
                with self.assertRaises(HTTPError) as raised:
                    urlopen(url + path)
                self.assertEqual(raised.exception.code, 404)
        finally:
            server.shutdown()
            server.server_close()
            worker.join()


if __name__ == "__main__":
    unittest.main()
