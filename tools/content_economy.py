"""Read-only weekly views of recorded simulation ledgers."""
import json
import math


def ledger_economy(path):
    days = {}
    previous_coins = None
    previous_active = 0
    initial = None
    records = 0
    checkpoints = []
    def day_at(t):
        day = max(0, math.floor(float(t) / 86400))
        return days.setdefault(day, {"day": day + 1, "income": 0, "expense": 0,
            "balance": None, "active_min": 0, "sources": {}, "sinks": {},
            "items": {}, "storage": {}, "waits": {}, "sessions": [], "actions": {}, "failures": {}})
    if not path.exists():
        return {"available": False, "days": [], "initial": None}
    with path.open(encoding="utf-8-sig") as stream:
        for line in stream:
            try:
                row = json.loads(line)
            except ValueError:
                continue
            if not isinstance(row, dict) or "t" not in row:
                continue
            records += 1
            checkpoint = row.get("checkpoint")
            if isinstance(checkpoint, dict) and checkpoint.get("schema") == 1 and isinstance(checkpoint.get("inventory"), dict):
                checkpoints.append({**checkpoint, "hours": row["t"] / 3600,
                                    "active_min": row.get("act", 0) / 60,
                                    "session": row.get("s", 0), "event": row.get("ev")})
            day = day_at(row["t"])
            if isinstance(row.get("coins"), (int, float)):
                coins = row["coins"]
                if initial is None:
                    initial = coins
                if previous_coins is not None:
                    delta = coins - previous_coins
                    key = row.get("kind", row.get("ev", "other"))
                    group = "sources" if delta >= 0 else "sinks"
                    day[group][key] = day[group].get(key, 0) + abs(delta)
                    day["income" if delta >= 0 else "expense"] += abs(delta)
                previous_coins = coins
                day["balance"] = coins
            active = float(row.get("act", previous_active))
            day["active_min"] += max(0, active - previous_active) / 60
            previous_active = active
            if row.get("s", 0) and row["s"] not in day["sessions"]:
                day["sessions"].append(row["s"])
            if row.get("ev") == "wait":
                key = row.get("reason", "other")
                day["waits"][key] = day["waits"].get(key, 0) + row.get("seconds", 0) / 60
            if row.get("ev") == "act" and not row.get("ok"):
                error = row.get("err") or row.get("kind", "other")
                day["failures"][error] = day["failures"].get(error, 0) + 1
            if row.get("ev") != "act" or not row.get("ok"):
                continue
            action = row.get("kind", "other")
            day["actions"][action] = day["actions"].get(action, 0) + 1
            for key, delta in row.get("di", {}).items():
                item = day["items"].setdefault(key, {"in": 0, "out": 0, "uses": {}, "sources": {}})
                item["in" if delta >= 0 else "out"] += abs(delta)
                if delta > 0:
                    item["sources"][action] = item["sources"].get(action, 0) + delta
                if delta < 0:
                    action = row.get("kind", "other")
                    item["uses"][action] = item["uses"].get(action, 0) - delta
            for key, values in row.get("dep", {}).items():
                if len(values) == 2 and values[1] > 0:
                    value = {"used": values[0], "capacity": values[1], "ratio": values[0] / values[1]}
                    if value["ratio"] > day["storage"].get(key, {}).get("ratio", -1):
                        day["storage"][key] = value
    return {"available": bool(records), "initial": initial, "days": [days[k] for k in sorted(days)], "checkpoints": checkpoints}


def journeys(runs):
    return [{"id": r["_path"], "seed": r.get("seed"), "status": r.get("status"),
             "end": r.get("end", {}), "time": r.get("time", {}),
             "coin_flow": r.get("coin_flow", {}), "blocks": r.get("blocks", {}),
             "growth_days": r.get("growth_days", {}), "chapter_coins": r.get("chapter_coins", {}),
             "milestones": r["_times"], "transactions": r.get("_transactions", {}),
             "ledger": r["_economy"]} for r in runs]
