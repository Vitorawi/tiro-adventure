"""Metas de ritmo e leitura de relatórios existentes. Nunca inicia Godot."""
from __future__ import annotations

import hashlib
import json
import math
import statistics
import threading
from datetime import datetime, timezone
from pathlib import Path
from content_economy import ledger_economy, journeys

ROOT = Path(__file__).resolve().parents[1]
PLAN = ROOT / "tools/content_map/pacing_plan.json"
EVIDENCE = ROOT / "build/economy"
LOCK = threading.Lock()
_CACHE = {}
PROFILES = {"reference": "Referência · 3 × 10 min/dia", "light": "Leve · 1 × 10 min/dia",
            "active": "Ativo · sessões longas", "affective": "Afetivo", "commercial": "Comercial", "recovery": "Recuperação"}
SPECIAL = {
    "first_harvest": ("Primeira colheita", "crop:carrot"),
    "first_wish": ("Primeiro desejo atendido", "feature:wishes"),
    "first_find": ("Primeiro achado", "find:farm"),
    "first_walk": ("Primeiro passeio concluído", "walk:park_loop"),
    "chapter_9_done": ("Fim da jornada · capítulos 1–9", "chapter:9"),
    "projects_all": ("Obras do relatório concluídas", "project:park_picnic"),
}
HIGHLIGHTS = ["event:first_harvest", "event:first_wish", "event:first_find", "upgrade:dog_bed",
              "upgrade:fridge", "upgrade:stove", "event:first_walk", "world:village", "upgrade:forest_open",
              "upgrade:workbench", "upgrade:warehouse", "upgrade:chicken_coop", "upgrade:cow_barn",
              "upgrade:mill", "upgrade:dairy", "upgrade:orchard", "upgrade:stall", "upgrade:greenhouse",
              "upgrade:atelier", "event:chapter_9_done", "project:park_bench", "project:village_garden",
              "project:park_picnic", "event:projects_all"]


def content_hash(data_dir):
    """Mesmo contrato de hash de EconomySim.content_hash, sem executar o motor."""
    parts = []
    for folder in [data_dir, data_dir / "rooms"]:
        for file in sorted(folder.glob("*.json")):
            if file.name == "version.json":
                continue
            text = file.read_text(encoding="utf-8").replace("\r\n", "\n")
            parts.append(f"data/{file.relative_to(data_dir).as_posix()}:" + hashlib.sha256(text.encode()).hexdigest())
    return hashlib.sha256("\n".join(parts).encode()).hexdigest()


def read_plan(path=PLAN):
    with LOCK:
        return json.loads(path.read_text(encoding="utf-8-sig"))


def save_plan(payload, path=PLAN):
    if not isinstance(payload, dict) or not isinstance(payload.get("targets"), dict):
        raise ValueError("Formato de metas inválido")
    targets = {}
    for key, value in payload["targets"].items():
        if not isinstance(key, str) or len(key) > 160 or not isinstance(value, dict):
            raise ValueError("Marco inválido")
        low, high = value.get("min"), value.get("max")
        for number in [low, high]:
            if number is not None and (isinstance(number, bool) or not isinstance(number, (int, float)) or not math.isfinite(number) or not 0 <= number <= 100000):
                raise ValueError("Use minutos positivos e finitos nas metas")
        if low is not None and high is not None and low > high:
            raise ValueError("O início da faixa não pode passar do fim")
        note = value.get("note", "")
        if not isinstance(note, str) or len(note) > 1000:
            raise ValueError("Anotação inválida (máximo 1.000 caracteres)")
        targets[key] = {"min": low, "max": high, "note": note, "basis": "user"}
    with LOCK:
        current = json.loads(path.read_text(encoding="utf-8-sig"))
        for key, value in targets.items():
            old = current.get("targets", {}).get(key)
            if old and all(old.get(field) == value.get(field) for field in ["min", "max", "note"]):
                value["basis"] = old.get("basis", "user")
        current["targets"] = targets
        current["updated_at"] = datetime.now(timezone.utc).isoformat()
        temp = path.with_suffix(".tmp")
        temp.write_text(json.dumps(current, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        temp.replace(path)
    return current


def read_run(path):
    """Extrai compras e primeiras aquisições do ledger, sem inferir compra por missão."""
    ledger = path.with_name("ledger.jsonl")
    signature = (str(path), path.stat().st_mtime_ns, path.stat().st_size,
                 ledger.stat().st_mtime_ns if ledger.exists() else 0, ledger.stat().st_size if ledger.exists() else 0)
    if signature in _CACHE:
        return _CACHE[signature]
    run = json.loads(path.read_text(encoding="utf-8-sig"))
    times = {}
    transactions = {}
    for key, value in run.get("quest_times", {}).items():
        times[f"quest:{key}"] = value
    for key, value in run.get("milestones", {}).items():
        times[f"event:{key}"] = value
    for milestone, upgrade in {"stove": "stove", "workbench": "workbench", "stall": "stall"}.items():
        if milestone in run.get("milestones", {}):
            times[f"upgrade:{upgrade}"] = run["milestones"][milestone]
    for value in run.get("projects", []):
        if value.get("done"):
            times.setdefault(f"project:{value['id']}", value)
    if ledger.exists():
        with ledger.open(encoding="utf-8-sig") as stream:
            for line in stream:
                try:
                    row = json.loads(line)
                except ValueError:
                    continue  # última linha pode estar sendo escrita
                if row.get("ev") != "act" or not row.get("ok"):
                    continue
                point = {"active_min": float(row.get("act", 0)) / 60,
                         "hours": float(row.get("t", 0)) / 3600, "session": row.get("s", 0)}
                key, args = row.get("kind"), row.get("args", {})
                if key == "claim_quest" and args.get("id"):
                    times[f"quest:{args['id']}"] = point
                if key in {"buy_upgrade", "buy_animal"} and args.get("id"):
                    kind = "upgrade" if key == "buy_upgrade" else "animal"
                    times.setdefault(f"{kind}:{args['id']}", point)
                    transactions.setdefault(f"{kind}:{args['id']}", {
                        "items": {k: -v for k, v in row.get("di", {}).items() if v < 0},
                        "before": row.get("before"), "after": row.get("after"), **point})
                if key == "cook" and args.get("recipe"):
                    times.setdefault(f"recipe:{args['recipe']}", point)
                for item, amount in row.get("di", {}).items():
                    if amount > 0:
                        times.setdefault(f"item:{item}", point)
    run["_times"], run["_path"] = times, path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path.name
    run["_economy"] = ledger_economy(ledger)
    run["_transactions"] = transactions
    _CACHE[signature] = run
    if len(_CACHE) > 200:
        _CACHE.pop(next(iter(_CACHE)))
    return run


def spread(values):
    values = [float(v) for v in values if isinstance(v, (int, float)) and math.isfinite(v)]
    return {"min": min(values), "median": statistics.median(values), "max": max(values)} if values else None


def build_pacing(graph, data_dir, batch="", profile="reference", until="", plan_path=PLAN, evidence_dir=EVIDENCE):
    plan = read_plan(plan_path)
    batches = sorted((p for p in evidence_dir.glob("etapa_*") if p.is_dir() and any(p.glob("*/summary.json"))),
                     key=lambda p: int(p.name.split("_")[1]) if p.name.split("_")[1].isdigit() else -1, reverse=True)
    selected = next((p for p in batches if p.name == batch), batches[0] if batches else None)
    candidates, ignored = [], 0
    for path in selected.glob("*/summary.json") if selected else []:
        if path.parent.name.startswith("_"):
            continue
        try:
            run = json.loads(path.read_text(encoding="utf-8-sig"))
            if run.get("guards", {}).get("violations", 1) != 0 or run.get("params", {}).get("rare", "normal") != "normal":
                ignored += 1
                continue
            candidates.append((path, run))
        except (OSError, ValueError, TypeError):
            ignored += 1
    profiles = sorted({r.get("profile", "") for _, r in candidates})
    if profile not in profiles and profiles:
        profile = "reference" if "reference" in profiles else profiles[0]
    horizons = sorted({r.get("params", {}).get("until", "days") for _, r in candidates if r.get("profile") == profile})
    if until not in horizons:
        until = "projects" if "projects" in horizons else "campaign" if "campaign" in horizons else next(iter(horizons), "")
    # Não misturar revisões, horizontes ou duas tentativas da mesma semente.
    chosen = [(p, r) for p, r in candidates if r.get("profile") == profile and r.get("params", {}).get("until", "days") == until]
    current_hash = content_hash(data_dir)
    hashes = {r.get("content_hash") for _, r in chosen}
    chosen_hash = current_hash if current_hash in hashes else max(chosen, key=lambda pr: pr[0].stat().st_mtime_ns)[1].get("content_hash") if chosen else None
    latest = {}
    for path, run in sorted(chosen, key=lambda pr: pr[0].stat().st_mtime_ns):
        if run.get("content_hash") == chosen_hash:
            latest[run.get("seed")] = path
    runs = []
    for path in latest.values():
        try:
            original = read_run(path)
            runs.append(dict(original, _times=dict(original["_times"])))
        except (OSError, ValueError, TypeError):
            ignored += 1
    index = {n["id"]: n for n in graph["nodes"]}
    rows = []
    ids = [(f"event:{k}", name, node, "event") for k, (name, node) in SPECIAL.items()]
    for n in graph["nodes"]:
        if n["kind"] in {"upgrade", "quest", "project", "animal", "item", "recipe", "world"}:
            ids.append((n["id"], n["name"], n["id"], n["kind"]))
    # Capítulo concluído = todos os seus marcos principais recebidos, inclusive shared_with.
    for n in graph["nodes"]:
        if n["kind"] != "chapter":
            continue
        chapter = int(n["key"])
        members = [x["id"] for x in graph["nodes"] if x["kind"] == "quest" and x["data"].get("kind") == "main" and x["data"].get("chapter") == chapter]
        key = f"finish:{n['id']}"
        ids.append((key, f"Concluir {n['name']}", n["id"], "chapter"))
        for run in runs:
            if members and all(m in run["_times"] for m in members):
                run["_times"][key] = max((run["_times"][m] for m in members), key=lambda v: (v.get("active_min", 0), v.get("hours", 0)))
    for run in runs:
        if "event:village_open" in run["_times"]:
            run["_times"]["world:village"] = run["_times"]["event:village_open"]
        if chosen_hash == current_hash:
            for n in graph["nodes"]:
                if n["kind"] == "rule" and n["key"] == "config:start":
                    for item in n["data"].get("inventory", {}):
                        run["_times"][f"item:{item}"] = {"active_min": 0, "hours": 0, "session": 1}
                if n["kind"] != "world" or n["id"] in run["_times"]:
                    continue
                req = n["data"].get("requirements", {})
                if set(req) - {"quests", "owned", "chapter"}:
                    continue
                needs = [f"quest:{k}" for k in req.get("quests", [])] + [f"upgrade:{k}" for k in req.get("owned", [])]
                if req.get("chapter", 1) > 1:
                    needs.append(f"finish:chapter:{req['chapter']-1}")
                if all(k in run["_times"] for k in needs):
                    run["_times"][n["id"]] = max((run["_times"][k] for k in needs), key=lambda v: (v.get("active_min", 0), v.get("hours", 0))) if needs else {"active_min": 0, "hours": 0, "session": 1}
    for key, name, node, kind in ids:
        samples = [r["_times"][key] for r in runs if key in r["_times"]]
        target = plan.get("targets", {}).get(key)
        active = spread([v.get("active_min") for v in samples])
        hours = spread([v.get("hours") for v in samples])
        result = "no_target" if not target or target.get("min") is None and target.get("max") is None else "unmeasured"
        if active and result != "no_target":
            result = "early" if target.get("min") is not None and active["median"] < target["min"] else "late" if target.get("max") is not None and active["median"] > target["max"] else "within"
            if chosen_hash != current_hash:
                result = "stale"
        rows.append({"id": key, "node": node, "name": name, "kind": kind, "highlight": key in HIGHLIGHTS,
                     "target": target, "active": active, "hours": hours,
                     "sessions": spread([v.get("session") for v in samples]), "reached": len(samples), "total": len(runs), "result": result,
                     "definition": index.get(node, {}).get("data", {})})
    return {
        "plan": plan, "rows": rows, "current_hash": current_hash, "journeys": journeys(runs),
        "datasets": [p.name for p in batches], "profiles": [{"id": k, "name": PROFILES.get(k, k)} for k in profiles],
        "horizons": horizons, "batch": selected.name if selected else "", "profile": profile, "until": until,
        "evidence": {"runs": len(runs), "matching": bool(runs) and chosen_hash == current_hash, "hash": chosen_hash,
                     "ignored": ignored, "complete": sum(r.get("status") == "complete" for r in runs),
                     "sources": [{"file": r["_path"], "seed": r.get("seed"), "status": r.get("status"), "stall": r.get("stall", "")} for r in runs]},
        "notice": "Resultados SIMULADOS já gravados, com jogador automatizado. Nenhuma simulação é iniciada. Mesmo hash confirma os JSONs, não o código do motor ou da política. Meta de design não é previsão. Dias equivalentes de orçamento não incluem timers, ausência nem escolhas.",
    }
