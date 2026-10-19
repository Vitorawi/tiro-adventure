"""Congela as tabelas "legadas" (antes da R1) em game/data/legacy_r0.json.

Etapa 02 do plano de economia: capacidades de depósito, rendimentos de colheita/receita/rota/passeio
e o mapa de capítulos/missões ANTES das mudanças de ordem e números das etapas seguintes.
A migração (`EconomyMigration`) lê SOMENTE este arquivo para reconstruir trabalhos antigos e o piso
de capacidade; assim, balancear os JSON vivos nunca altera o que um save antigo já tinha.

ATENÇÃO: rode UMA vez, no estado do jogo anterior à R1. Depois o arquivo é imutável. O script
recusa sobrescrever; use --force só para refazer em um checkout do commit anterior às mudanças.

    py -X utf8 -I tools/freeze_legacy.py [--force]
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "game" / "data"
OUT = DATA / "legacy_r0.json"


def load(name: str) -> dict:
    return json.loads((DATA / name).read_text(encoding="utf-8"))


# Textos mostrados ao jogador não entram no congelado (não são regra e o texts_test varre data/*.json).
TEXT_KEYS = {"name", "description", "label", "dialogue", "map_name", "map_caption", "instruction", "action_label",
             "queue_label", "recipe_label", "hint", "introduction", "postcard", "note", "unlocks_text", "role",
             "greeting", "text", "how_to", "breed", "announcement", "away_text", "unlock_label", "title",
             "caption", "detail_label", "overview_label", "button", "equip", "friend_gift", "icon", "sprite"}


def strip_text(node):
    if isinstance(node, dict):
        return {k: strip_text(v) for k, v in node.items() if k not in TEXT_KEYS}
    if isinstance(node, list):
        return [strip_text(v) for v in node]
    return node


def main() -> int:
    if OUT.exists() and "--force" not in sys.argv:
        print(f"{OUT} já existe (congelado). Use --force só em checkout anterior à R1.")
        return 1
    progression = load("progression.json")
    config = load("config.json")
    crops = load("crops.json")
    recipes = load("recipes.json")
    quests = load("quests.json")
    walks = load("walks.json")
    finds = load("finds.json")

    storage = {}
    for depot, data in progression["storage"].items():
        levels = []
        for upgrade in data.get("levels", []):
            levels.append({"id": upgrade, "capacity": int(progression["upgrades"][upgrade].get("storage_capacity", 0))})
        storage[depot] = {
            "building": data["building"],
            "base": int(data.get("base", 0)),
            "levels": levels,
        }

    crop_table = {}
    for crop_id, crop in crops.items():
        entry = {k: v for k, v in crop.items() if k != "sprite"}
        crop_table[crop_id] = strip_text(entry)

    activities = {}
    for route_id, route in progression["activities"].items():
        activities[route_id] = {
            "seconds": route.get("seconds", 0),
            "rewards": strip_text(route.get("rewards", {})),
            "player_xp": route.get("player_xp", 5),
            "place": route.get("place", ""),
        }

    quest_map = {}
    for quest_id, quest in quests.items():
        entry = {"kind": quest.get("kind", "side")}
        for key in ("chapter", "line", "order", "shared_with", "requires", "requirements"):
            if key in quest:
                entry[key] = quest[key]
        entry["goals"] = [
            {k: v for k, v in goal.items() if k in ("type", "key", "target", "fresh")}
            for goal in quest.get("goals", [])
        ]
        quest_map[quest_id] = entry

    chapters = [{"rewards": c.get("rewards", {})} for c in progression["chapters"]]

    frozen = {
        "_nota": "Congelado em 17/10/2026 (etapa 02 da economia R1) a partir do jogo ANTES das mudanças. Não editar nem regenerar.",
        "tabelas": "r0",
        "storage": storage,
        "crops": crop_table,
        "recipes": strip_text(recipes),
        "xp": config["xp"],
        "activities": activities,
        "walks": strip_text(walks),
        "find_worlds": {w: {"table": strip_text(d.get("table", []))} for w, d in finds.get("worlds", {}).items()},
        "quest_map": quest_map,
        "chapters": chapters,
    }
    OUT.write_text(json.dumps(frozen, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"gravado {OUT} ({OUT.stat().st_size} bytes): {len(quest_map)} missões, {len(chapters)} capítulos")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
