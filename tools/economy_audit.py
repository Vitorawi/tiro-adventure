#!/usr/bin/env python3
"""Auditoria estática da economia do Tiro Adventure (plano economia, etapa 00).

Lê os JSON de game/data (somente biblioteca padrão) e escreve em build/economy/baseline:
  baseline.json  dados da auditoria (determinístico: nada de data/hora ou caminhos)
  baseline.md    o mesmo, em Markdown
  references.md  referências quebradas, ciclos e alcançabilidade
  manifest.json  arquivos usados + SHA-256 dos dados e dos scripts auditados
  run_meta.json  metadados da execução (git, data, argumentos) — ÚNICO arquivo que varia entre execuções

O que NÃO faz: não simula GameState nem estima taxa de uso do jogador. Valores como "teto teórico"
são limites aritméticos dos dados, nunca taxas reais.

Uso:
  py tools/economy_audit.py [--data game/data] [--out build/economy/baseline] [--code game]
Saída de status: 0 = sem erros de referência/ciclo; 1 = há erros (listados em references.md).
"""
from __future__ import annotations

import argparse
import datetime
import hashlib
import json
import math
import re
import subprocess
import sys
from collections import Counter, defaultdict
from fractions import Fraction
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DATA_FILES = [
    "items", "recipes", "crops", "config", "progression", "quests", "routines", "walks",
    "wishes", "friends", "finds", "worlds", "npcs", "collections",
]
CODE_FILES = [
    "autoload/game_state.gd", "autoload/database.gd", "autoload/save_manager.gd",
    "scripts/state/progression_state.gd", "scripts/state/inventory.gd", "scripts/state/station_state.gd",
]
# Prefixos de contadores (`stat`) que sabemos resolver contra os dados.
STAT_PREFIXES = {
    "talk": "npc", "harvest": "crop", "produce": "item", "order": "order", "feed": "item",
    "walk": "walk", "activity": "activity", "friend_gift": "friend", "find_item": "item",
    "walk_item": "item", "wish_item": "item", "open": "screen",
}


# --------------------------------------------------------------------------------------
# Utilidades
# --------------------------------------------------------------------------------------

def sha256_bytes(raw: bytes) -> str:
    return hashlib.sha256(raw).hexdigest()


def sha256_text_file(path: Path) -> str:
    """Hash estável entre CRLF/LF (o repositório alterna as terminações de linha)."""
    return sha256_bytes(path.read_bytes().replace(b"\r\n", b"\n"))


def num(value):
    """Inteiros ficam inteiros; fracionários viram float arredondado para o relatório."""
    if isinstance(value, Fraction):
        if value.denominator == 1:
            return int(value)
        return round(float(value), 4)
    if isinstance(value, float):
        return int(value) if value.is_integer() else round(value, 4)
    return value


def avg(value):
    """Valor de moedas pode ser inteiro ou faixa [min, max]. Devolve (mín, máx)."""
    if isinstance(value, list) and len(value) == 2:
        return Fraction(value[0]), Fraction(value[1])
    return Fraction(value), Fraction(value)


def walk(obj, path=()):
    """Percorre dicionários/listas devolvendo (caminho, chave, valor) de cada entrada de dicionário."""
    if isinstance(obj, dict):
        for key, value in obj.items():
            yield path, key, value
            yield from walk(value, path + (key,))
    elif isinstance(obj, list):
        for index, value in enumerate(obj):
            yield from walk(value, path + (index,))


def fmt_path(path) -> str:
    return "/".join(str(p) for p in path)


def md_table(headers, rows) -> str:
    out = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for row in rows:
        out.append("| " + " | ".join("—" if c is None else str(c).replace("|", "\\|") for c in row) + " |")
    return "\n".join(out)


def amounts_text(amounts: dict) -> str:
    return ", ".join(f"{k}×{num(v)}" for k, v in sorted(amounts.items())) if amounts else ""


# --------------------------------------------------------------------------------------
# Carga
# --------------------------------------------------------------------------------------

class Data:
    def __init__(self, data_dir: Path):
        self.dir = data_dir
        self.files: dict[str, dict] = {}
        self.hashes: dict[str, str] = {}
        for name in DATA_FILES:
            path = data_dir / f"{name}.json"
            self.files[name] = json.loads(path.read_text(encoding="utf-8"))
            self.hashes[f"{name}.json"] = sha256_text_file(path)
        rooms_dir = data_dir / "rooms"
        self.rooms: dict[str, dict] = {}
        if rooms_dir.exists():
            for path in sorted(rooms_dir.glob("*.json")):
                self.rooms[path.stem] = json.loads(path.read_text(encoding="utf-8"))
                self.hashes[f"rooms/{path.name}"] = sha256_text_file(path)
        version = data_dir / "version.json"
        if version.exists():
            # version.json muda a cada deploy: entra no manifesto, não no hash do conteúdo.
            self.hashes["version.json"] = sha256_text_file(version)
        cfg = self.files["config"]
        self.items = self.files["items"]
        self.recipes = self.files["recipes"]
        self.crops = self.files["crops"]
        self.stations = cfg["stations"]
        self.animals = cfg["animals"]
        self.farm = cfg["farm"]
        self.config = cfg
        prog = self.files["progression"]
        self.prog = prog
        self.upgrades = prog["upgrades"]
        self.storage = prog["storage"]
        self.orders = prog["orders"]
        self.activities = prog["activities"]
        self.quests = self.files["quests"]
        self.npcs = self.files["npcs"]
        self.worlds = self.files["worlds"]
        self.collections = self.files["collections"]
        self.walks = self.files["walks"]
        self.wishes = self.files["wishes"]
        self.friends = self.files["friends"]
        self.finds = self.files["finds"]
        self.routines = self.files["routines"]

    def content_hash(self) -> str:
        """Hash dos dados de conteúdo (sem version.json), estável entre execuções."""
        digest = hashlib.sha256()
        for name in sorted(k for k in self.hashes if k != "version.json"):
            digest.update(f"{name}:{self.hashes[name]}\n".encode())
        return digest.hexdigest()

    # --- consultas ---------------------------------------------------------------
    def sell(self, item_id: str):
        value = self.items.get(item_id, {}).get("sell_price")
        return None if value is None else Fraction(value)

    def storage_of(self, item_id: str) -> str:
        """Réplica da regra de GameState.storage_of (depósito do item; '' = sem limite)."""
        item = self.items.get(item_id, {})
        forced = str(item.get("storage", ""))
        if forced != "":
            return "" if forced == "none" or forced not in self.storage else forced
        category = str(item.get("category", "product"))
        for dep_id, dep in self.storage.items():
            if category in dep.get("categories", []):
                return dep_id
        return ""

    def recipe_output(self, recipe: dict) -> str:
        return str(recipe.get("output", recipe.get("output_collection", "")))

    def station_upgrade(self, station_id: str) -> str:
        """Melhoria que libera a estação (Database.station_upgrade: campo `station` da melhoria, senão o próprio ID)."""
        for up_id, up in self.upgrades.items():
            if up.get("station", "") == station_id:
                return up_id
        return station_id


# --------------------------------------------------------------------------------------
# Seções
# --------------------------------------------------------------------------------------

def section_meta(d: Data, code_dir: Path) -> dict:
    quests = d.quests
    mains = [q for q, v in quests.items() if v.get("kind") == "main"]
    lines = [q for q, v in quests.items() if v.get("kind") == "line"]
    save_version = None
    sm = code_dir / "autoload/save_manager.gd"
    if sm.exists():
        found = re.search(r"const SAVE_VERSION\s*:?=\s*(\d+)", sm.read_text(encoding="utf-8"))
        save_version = int(found.group(1)) if found else None
    return {
        "content_hash": d.content_hash(),
        "save_version": save_version,
        "quests": {"total": len(quests), "main": len(mains), "line": len(lines),
                   "lines": dict(sorted(Counter(v.get("line") for v in quests.values() if v.get("kind") == "line").items())),
                   "shared_with": sorted([q, v["shared_with"]] for q, v in quests.items() if "shared_with" in v)},
        "counts": {"items": len(d.items), "recipes": len(d.recipes), "crops": len(d.crops),
                   "upgrades": len(d.upgrades), "orders": len(d.orders), "activities": len(d.activities),
                   "stations": len(d.stations), "animals": len(d.animals), "chapters": len(d.prog["chapters"]),
                   "walks": len(d.walks["walks"]), "wishes": len(d.wishes["wishes"]), "friends": len(d.friends["friends"]),
                   "routines_daily": len(d.routines["daily"]["missions"]), "routines_weekly": len(d.routines["weekly"]["missions"])},
        "data_hashes": dict(sorted(d.hashes.items())),
    }


def section_items(d: Data) -> dict:
    rows = []
    for item_id in sorted(d.items):
        item = d.items[item_id]
        rows.append({"id": item_id, "name": item.get("name"), "category": item.get("category", "product"),
                     "storage_field": item.get("storage"), "deposit": d.storage_of(item_id) or "(sem limite)",
                     "sell_price": item.get("sell_price"), "trade_xp": item.get("trade_xp"),
                     "feed": item.get("feed")})
    deposits = defaultdict(list)
    for row in rows:
        deposits[row["deposit"]].append(row["id"])
    return {"items": rows, "by_deposit": {k: sorted(v) for k, v in sorted(deposits.items())}}


def section_storage(d: Data) -> dict:
    out = {}
    for dep_id, dep in sorted(d.storage.items()):
        building = dep["building"]
        levels = []
        total = int(dep.get("base", 0))
        for level_id in dep.get("levels", []):
            up = d.upgrades.get(level_id, {})
            total += int(up.get("storage_capacity", 0))
            levels.append({"id": level_id, "cost": up.get("cost"), "materials": up.get("materials", {}),
                           "add": up.get("storage_capacity"), "total_capacity": total,
                           "requirements": up.get("requirements", {})})
        up = d.upgrades.get(building, {})
        out[dep_id] = {
            "name": dep.get("name"), "categories": dep.get("categories", []), "base": dep.get("base"),
            "building": building, "building_cost": up.get("cost"), "building_materials": up.get("materials", {}),
            "building_requirements": up.get("requirements", {}),
            "limit_active_only_after_purchase": True,  # GameState.storage_active → has_upgrade(building)
            "levels": levels,
            "items": sorted(i for i in d.items if d.storage_of(i) == dep_id),
        }
    unlimited = sorted(i for i in d.items if d.storage_of(i) == "")
    exempt_reason = {}
    for item_id in unlimited:
        item = d.items[item_id]
        exempt_reason[item_id] = "storage=none" if item.get("storage") == "none" else f"categoria {item.get('category', 'product')} sem depósito"
    return {"deposits": out, "exempt_items": exempt_reason,
            "exempt_by_category": dict(sorted(Counter(d.items[i].get("category", "product") for i in unlimited).items()))}


def crop_rows(d: Data) -> list[dict]:
    speedup = Fraction(str(d.farm["water"]["speedup"]))
    rows = []
    for crop_id in sorted(d.crops):
        crop = d.crops[crop_id]
        seconds = Fraction(crop["seconds"])
        watered = seconds * (1 - speedup)
        sells = [d.sell(i) for i in crop["yield"]]
        sell_known = all(s is not None for s in sells)
        yield_value = sum(Fraction(q) * d.sell(i) for i, q in crop["yield"].items()) if sell_known else None
        coins = Fraction(crop.get("coins", 0))
        rows.append({
            "id": crop_id, "seconds": crop["seconds"], "seconds_watered_once": num(watered),
            "yield": crop["yield"], "harvest_coins": crop.get("coins", 0), "skill_xp": crop.get("skill_xp"),
            "greenhouse": crop.get("greenhouse"), "requirements": crop.get("requirements", {}),
            "plant_cost_coins": crop.get("cost", 0),
            "yield_sell_value": num(yield_value) if yield_value is not None else None,
            "value_per_harvest_with_coins": num(coins + yield_value) if yield_value is not None else None,
            "ceiling_per_plot_per_min": num((coins + yield_value) / watered * 60) if yield_value is not None else None,
            "ceiling_per_plot_per_min_without_coins": num(yield_value / watered * 60) if yield_value is not None else None,
        })
    return rows


def expand_raw(d: Data, item_id: str, qty: Fraction, trail=()):
    """Expande o item até matérias-primas (sem receita). Devolve (dict item->qtd, ambíguos)."""
    producers = [r for r, v in d.recipes.items() if d.recipe_output(v) == item_id and v["station"] != "chicken_coop"
                 and v["station"] != "cow_barn" and "output" in v]
    animal = [r for r, v in d.recipes.items() if v.get("output") == item_id and d.stations[v["station"]].get("kind") == "animal"]
    chosen = (producers + animal)
    if item_id in trail or not chosen:
        return {item_id: qty}, []
    notes = []
    if len(chosen) > 1:
        notes.append(f"{item_id}: {len(chosen)} receitas ({', '.join(chosen)}); usada {chosen[0]}")
    recipe = d.recipes[chosen[0]]
    batches = qty / Fraction(recipe.get("qty", 1))
    total: dict = defaultdict(Fraction)
    for ing, amount in recipe["inputs"].items():
        sub, sub_notes = expand_raw(d, ing, batches * Fraction(amount), trail + (item_id,))
        notes += sub_notes
        for key, value in sub.items():
            total[key] += value
    return dict(total), notes


def crop_coin_per_unit(d: Data) -> dict:
    """Moeda de colheita por unidade da primeira cultura que rende o item (informativo)."""
    result = {}
    for crop in d.crops.values():
        for item_id, qty in crop["yield"].items():
            result.setdefault(item_id, Fraction(crop.get("coins", 0), int(qty)))
    return result


def section_recipes(d: Data) -> dict:
    coin_unit = crop_coin_per_unit(d)
    rows = []
    for recipe_id in sorted(d.recipes):
        recipe = d.recipes[recipe_id]
        station = recipe["station"]
        qty = Fraction(recipe.get("qty", 1))
        out = d.recipe_output(recipe)
        is_collection = "output_collection" in recipe
        inputs = recipe["inputs"]
        unknown = sorted(i for i in inputs if d.sell(i) is None)
        in_value = None if unknown else sum(Fraction(q) * d.sell(i) for i, q in inputs.items())
        out_price = d.sell(out) if not is_collection else None
        out_value = out_price * qty if out_price is not None else None
        raw, notes = ({}, [])
        raw_value = None
        harvest_coins = None
        if not is_collection:
            raw: dict = defaultdict(Fraction)
            for ing, amount in inputs.items():
                sub, sub_notes = expand_raw(d, ing, Fraction(amount))
                notes += sub_notes
                for k, v in sub.items():
                    raw[k] += v
            raw = dict(raw)
            raw_unknown = [i for i in raw if d.sell(i) is None]
            raw_value = None if raw_unknown else sum(v * d.sell(i) for i, v in raw.items())
            harvest_coins = sum(v * coin_unit.get(i, 0) for i, v in raw.items())
        seconds = Fraction(recipe["seconds"])
        margin = out_value - in_value if (in_value is not None and out_value is not None) else None
        raw_margin = out_value - raw_value if (raw_value is not None and out_value is not None) else None
        kind = d.stations[station].get("kind", "")
        rows.append({
            "id": recipe_id, "station": station, "station_kind": kind or "producao", "output": out,
            "output_is_collection": is_collection, "qty": num(qty), "seconds": recipe["seconds"],
            "inputs": inputs, "requirements": recipe.get("requirements", {}), "skill_xp": recipe.get("skill_xp"),
            "skill": recipe.get("skill"),
            "inputs_unknown_price": unknown,
            "input_sell_value": num(in_value) if in_value is not None else None,
            "output_unit_sell_price": num(out_price) if out_price is not None else None,
            "output_sell_value": num(out_value) if out_value is not None else None,
            "margin_immediate": num(margin) if margin is not None else None,
            "margin_immediate_pct": num(margin / in_value * 100) if margin is not None and in_value else None,
            "margin_per_machine_min": num(margin / seconds * 60) if margin is not None else None,
            "raw_inputs": {k: num(v) for k, v in sorted(raw.items())},
            "raw_sell_value": num(raw_value) if raw_value is not None else None,
            "margin_vs_raw": num(raw_margin) if raw_margin is not None else None,
            "margin_vs_raw_per_machine_min": num(raw_margin / seconds * 60) if raw_margin is not None else None,
            "raw_harvest_coins_share": num(harvest_coins) if harvest_coins is not None else None,
            "chain_notes": sorted(set(notes)),
            "per_animal": kind == "animal",
        })
    return {"recipes": rows}


def section_orders(d: Data) -> dict:
    rows = []
    for order_id in sorted(d.orders):
        order = d.orders[order_id]
        inputs = order["inputs"]
        unknown = sorted(i for i in inputs if d.sell(i) is None)
        in_value = None if unknown else sum(Fraction(q) * d.sell(i) for i, q in inputs.items())
        raw: dict = defaultdict(Fraction)
        for ing, amount in inputs.items():
            sub, _ = expand_raw(d, ing, Fraction(amount))
            for k, v in sub.items():
                raw[k] += v
        raw_unknown = [i for i in raw if d.sell(i) is None]
        raw_value = None if raw_unknown else sum(v * d.sell(i) for i, v in raw.items())
        coins = order["rewards"].get("coins", 0)
        rows.append({
            "id": order_id, "name": order["name"], "inputs": inputs, "coins": coins,
            "items": order["rewards"].get("items", {}), "cooldown": order.get("cooldown"),
            "channel": order.get("channel", "neighbors"), "requirements": order.get("requirements", {}),
            "inputs_unknown_price": unknown,
            "input_sell_value": num(in_value) if in_value is not None else None,
            "margin_vs_sale": num(Fraction(coins) - in_value) if in_value is not None else None,
            "raw_inputs": {k: num(v) for k, v in sorted(raw.items())},
            "raw_sell_value": num(raw_value) if raw_value is not None else None,
            "margin_vs_raw": num(Fraction(coins) - raw_value) if raw_value is not None else None,
            "coins_per_hour_at_cooldown": num(Fraction(coins) * 3600 / order["cooldown"]) if order.get("cooldown") else None,
        })
    return {"orders": rows}


def section_stations(d: Data) -> dict:
    rows = []
    for station_id, st in sorted(d.stations.items()):
        upgrades = st.get("slot_upgrades", {})
        rows.append({
            "id": station_id, "name": st.get("name"), "kind": st.get("kind", "producao"), "slots": st.get("slots", 1),
            "slot_upgrades": upgrades, "max_slots": st.get("slots", 1) + sum(upgrades.values()),
            "animal_capacity": st.get("animal_capacity"), "requirements": st.get("requirements", {}),
            "upgrade_id": d.station_upgrade(station_id), "upgrade_id_exists": d.station_upgrade(station_id) in d.upgrades, "recipes": sorted(r for r, v in d.recipes.items() if v["station"] == station_id),
            "slot_upgrade_costs": {u: {"cost": d.upgrades.get(u, {}).get("cost"), "materials": d.upgrades.get(u, {}).get("materials", {}),
                                       "requirements": d.upgrades.get(u, {}).get("requirements", {})} for u in upgrades},
        })
    return {"stations": rows}


def section_upgrades(d: Data) -> dict:
    rows = []
    for up_id in sorted(d.upgrades):
        up = d.upgrades[up_id]
        mats = up.get("materials", {})
        rows.append({"id": up_id, "name": up.get("name"), "world": up.get("world"), "cost": up.get("cost", 0),
                     "materials": mats, "requirements": up.get("requirements", {}),
                     "storage_capacity": up.get("storage_capacity")})
    plots = {"unlock_costs": d.farm["unlock_costs"], "plots": d.farm["plots"], "initial": d.farm["initial_plots"],
             "greenhouse_plots": d.farm["greenhouse_plots"], "lent_plots": d.farm["lent_plots"]}
    animals = {a: {"station": v["station"], "price": v["price"], "requirements": v.get("requirements", {})} for a, v in sorted(d.animals.items())}
    return {"upgrades": rows, "plots": plots, "animals": animals, "shop_items": d.prog["shop_items"]}


def section_nature(d: Data) -> dict:
    rows = []
    for act_id in sorted(d.activities):
        act = d.activities[act_id]
        rewards = act.get("rewards", {})
        rows.append({"id": act_id, "place": act.get("place"), "seconds": act.get("seconds"),
                     "items": rewards.get("items", {}), "coins": rewards.get("coins", 0), "skill_xp": rewards.get("skill_xp"),
                     "requirements": act.get("requirements", {}), "site": next((s for s, v in d.prog["nature_sites"].items() if act.get("place") in v["groups"]), None)})
    return {"activities": rows, "sites": d.prog["nature_sites"], "resources": d.prog["nature_resources"]}


# --- Fluxos de moedas / itens ----------------------------------------------------------

def coin_occurrences(d: Data) -> list[dict]:
    """Toda ocorrência do campo `coins` (fonte) em todos os arquivos, com origem e valor (mín/máx)."""
    rows = []
    for name in DATA_FILES:
        for path, key, value in walk(d.files[name]):
            if key != "coins" or isinstance(value, (dict, str, bool)) or value is None:
                continue
            lo, hi = avg(value)
            rows.append({"file": name, "path": fmt_path(path), "min": num(lo), "max": num(hi)})
    return rows


def classify_coin(row: dict) -> str:
    f, p = row["file"], row["path"].split("/")
    if f == "quests":
        return "quests"
    if f == "crops":
        return "crops"
    if f == "routines":
        return "routines:" + p[0]
    if f == "walks":
        if "loot" in p and "table" in p:
            return "walks:sorteio"
        if "loot" in p:
            return "walks:primeira/raro"
        return "walks:fixo"
    if f == "progression":
        return "progression:" + ("/".join(p[:2]) if p[0] in ("orders", "activities", "treasure") else p[0])
    if f == "wishes":
        return "wishes"
    if f == "friends":
        return "friends"
    if f == "finds":
        return "finds"
    return f


def section_coins(d: Data) -> dict:
    rows = coin_occurrences(d)
    groups: dict = defaultdict(lambda: {"entries": 0, "min": Fraction(0), "max": Fraction(0)})
    for row in rows:
        g = groups[classify_coin(row)]
        g["entries"] += 1
        g["min"] += Fraction(row["min"])
        g["max"] += Fraction(row["max"])
    summary = {k: {"entries": v["entries"], "sum_min": num(v["min"]), "sum_max": num(v["max"])} for k, v in sorted(groups.items())}
    # Fontes que não usam o campo `coins`: venda de itens, presente do dia/nível/vínculo (agrupadas acima por `coins`).
    sources_extra = {
        "start_coins": d.config["start"]["coins"],
        "sell_price_items": sum(1 for i in d.items.values() if "sell_price" in i),
        "level_rewards_default_per_level": d.prog["level_rewards"].get("default", {}),
    }
    # Sumidouros
    sinks = {
        "upgrades_coins": {k: v.get("cost", 0) for k, v in sorted(d.upgrades.items()) if v.get("cost", 0)},
        "upgrades_coins_total": sum(v.get("cost", 0) for v in d.upgrades.values()),
        "plots_unlock_total": sum(d.farm["unlock_costs"]),
        "animals_total": sum(v["price"] for v in d.animals.values()),
        "shop_items": {k: v.get("price") for k, v in d.prog["shop_items"].items()},
    }
    # Todos os campos que parecem preço/custo (para não perder sumidouros fora dos conhecidos)
    price_fields = []
    for name in DATA_FILES:
        for path, key, value in walk(d.files[name]):
            if key in ("cost", "price", "unlock_costs") and not isinstance(value, dict):
                price_fields.append({"file": name, "path": fmt_path(path + (key,)), "value": value})
    quest_split = {kind: {"entries": 0, "coins": Fraction(0)} for kind in ("main", "line")}
    for q in d.quests.values():
        coins = q["rewards"].get("coins", 0)
        quest_split[q["kind"]]["entries"] += 1
        quest_split[q["kind"]]["coins"] += coins
    chapters_total = sum(c["rewards"].get("coins", 0) for c in d.prog["chapters"])
    levels_total = sum(v.get("coins", 0) for k, v in d.prog["level_rewards"].items() if k.isdigit())
    return {
        "occurrences": rows, "by_source": summary, "sources_extra": sources_extra, "sinks": sinks,
        "price_fields": sorted(price_fields, key=lambda r: (r["file"], r["path"])),
        "quests_coin_totals": {k: {"entries": v["entries"], "coins": num(v["coins"])} for k, v in quest_split.items()},
        "chapters_coin_total": chapters_total, "level_rewards_2_to_10_coins": levels_total,
        "bond_levels_coins": [lv.get("rewards", {}).get("coins", 0) for lv in d.prog["bond_levels"]],
        "daily_gift_cycle": d.prog["daily_gift"],
    }


def item_gain_occurrences(d: Data, item_filter=None) -> list[dict]:
    """Toda ocorrência de itens recebidos (dicionário `items`) fora de entradas de receita/custos."""
    rows = []
    for name in DATA_FILES:
        for path, key, value in walk(d.files[name]):
            if key != "items" or not isinstance(value, dict):
                continue
            for item_id, amount in value.items():
                if item_filter and item_id not in item_filter:
                    continue
                if isinstance(amount, (int, float)):
                    lo, hi = amount, amount
                elif isinstance(amount, list) and len(amount) == 2:
                    lo, hi = amount
                else:
                    continue
                rows.append({"file": name, "path": fmt_path(path), "item": item_id, "min": lo, "max": hi})
    return rows


def section_bolts(d: Data) -> dict:
    targets = ("bolt", "iron_band")
    gains = item_gain_occurrences(d, set(targets))
    by_item = {}
    for t in targets:
        entries = [g for g in gains if g["item"] == t]
        kinds = defaultdict(lambda: {"entries": 0, "min": 0, "max": 0})
        for g in entries:
            parts = g["path"].split("/")
            if g["file"] == "progression":
                origin = "progression:" + parts[0]
            elif g["file"] == "finds":
                origin = "finds:sorteio" if "table" in parts else "finds:" + parts[0]
            elif g["file"] == "walks":
                origin = "walks"
            else:
                origin = g["file"]
            kinds[origin]["entries"] += 1
            kinds[origin]["min"] += g["min"]
            kinds[origin]["max"] += g["max"]
        demand = []
        for up_id, up in sorted(d.upgrades.items()):
            if t in up.get("materials", {}):
                demand.append({"upgrade": up_id, "qty": up["materials"][t]})
        for rid, recipe in sorted(d.recipes.items()):
            if t in recipe["inputs"]:
                demand.append({"recipe": rid, "qty": recipe["inputs"][t]})
        by_item[t] = {"sources_by_origin": dict(sorted(kinds.items())), "entries": sorted(entries, key=lambda g: (g["file"], g["path"])),
                      "demand": demand, "demand_total": sum(x["qty"] for x in demand)}
    return by_item


def section_reward_bank(d: Data) -> dict:
    """Banco de recompensas únicas de missões/capítulos/vínculo (o que o jogo entrega sem repetição)."""
    items = defaultdict(int)
    for q in d.quests.values():
        for item_id, amount in q["rewards"].get("items", {}).items():
            items[item_id] += amount
    collections = sorted({c for q in d.quests.values() for c in q["rewards"].get("collections", [])})
    affection = sum(q["rewards"].get("affection", 0) for q in d.quests.values())
    skill_xp = Counter()
    for q in d.quests.values():
        for k, v in q["rewards"].get("skill_xp", {}).items():
            skill_xp[k] += v
    by_chapter = defaultdict(lambda: {"quests": 0, "coins": 0, "items": defaultdict(int)})
    for q_id, q in d.quests.items():
        key = f"cap{q['chapter']}" if q["kind"] == "main" else f"linha:{q['line']}"
        by_chapter[key]["quests"] += 1
        by_chapter[key]["coins"] += q["rewards"].get("coins", 0)
        for k, v in q["rewards"].get("items", {}).items():
            by_chapter[key]["items"][k] += v
    return {
        "quest_items_total": dict(sorted(items.items())), "quest_collections": collections,
        "quest_affection_total": affection, "quest_skill_xp_total": dict(sorted(skill_xp.items())),
        "by_group": {k: {"quests": v["quests"], "coins": v["coins"], "items": dict(sorted(v["items"].items()))} for k, v in sorted(by_chapter.items())},
        "chapters": [{"index": i + 1, "name": c["name"], "coins": c["rewards"].get("coins", 0), "skill_xp": c["rewards"].get("skill_xp", {}),
                      "target": c.get("target")} for i, c in enumerate(d.prog["chapters"])],
        "level_rewards": d.prog["level_rewards"], "bond_levels": d.prog["bond_levels"],
        "treasure": d.prog["treasure"]["rewards"],
    }


def section_purchases(d: Data) -> dict:
    """Compra → recompensa: quanto as missões devolvem em moedas depois de cada construção."""
    rows = []
    owned_goal = defaultdict(list)
    for q_id, q in d.quests.items():
        for goal in q["goals"]:
            if goal["type"] == "owned":
                owned_goal[goal["key"]].append(q_id)
    chapter_target = {c.get("target"): i + 1 for i, c in enumerate(d.prog["chapters"]) if c.get("target")}
    for up_id in sorted(d.upgrades):
        up = d.upgrades[up_id]
        cost = up.get("cost", 0)
        mats = up.get("materials", {})
        sell_known = [i for i in mats if d.sell(i) is not None]
        mats_value = sum(Fraction(mats[i]) * d.sell(i) for i in sell_known) if mats else Fraction(0)
        qs = owned_goal.get(up_id, [])
        reward = sum(d.quests[q]["rewards"].get("coins", 0) for q in qs
                     if "shared_with" not in d.quests[q])
        chapter = chapter_target.get(up_id)
        chapter_coins = d.prog["chapters"][chapter - 1]["rewards"].get("coins", 0) if chapter else None
        rows.append({
            "upgrade": up_id, "cost": cost, "materials": mats, "materials_sell_value_known": num(mats_value),
            "materials_without_sell_price": sorted(i for i in mats if d.sell(i) is None),
            "quests_with_owned_goal": qs, "quest_coin_rewards": reward,
            "quest_items": {q: d.quests[q]["rewards"].get("items", {}) for q in qs if d.quests[q]["rewards"].get("items")},
            "reward_over_cost_pct": num(Fraction(reward) / cost * 100) if cost else None,
            "chapter_whose_target_is_it": chapter, "chapter_coin_reward": chapter_coins,
        })
    return {"purchases": rows}


def section_early_game(d: Data) -> dict:
    """Primeiras moedas/itens: início, primeira colheita e venda inicial."""
    wp = d.worlds["farm"]["places"]
    early = wp.get("early_market")
    return {
        "start": d.config["start"],
        "carrot": next((r for r in crop_rows(d) if r["id"] == "carrot"), None),
        "farm_places_with_requirements": {k: v.get("requirements") for k, v in wp.items() if v.get("requirements")},
        "early_market_place": early,
        "initial_plots": d.farm["initial_plots"], "lent_plots": d.farm["lent_plots"],
    }


# --- Missões ---------------------------------------------------------------------------

def section_quest_graph(d: Data) -> dict:
    mains = sorted((q for q, v in d.quests.items() if v["kind"] == "main"), key=lambda q: (d.quests[q]["chapter"], d.quests[q]["order"]))
    lines: dict = defaultdict(list)
    for q, v in d.quests.items():
        if v["kind"] == "line":
            lines[v["line"]].append(q)
    for key in lines:
        lines[key].sort(key=lambda q: d.quests[q]["order"])
    rows = []
    for q_id in sorted(d.quests):
        q = d.quests[q_id]
        goals = [{"type": g["type"], "key": g["key"], "target": g.get("target"), "fresh": bool(g.get("fresh", False))} for g in q["goals"]]
        rows.append({
            "id": q_id, "npc": q["npc"], "kind": q["kind"], "line": q.get("line") or "main", "chapter": q.get("chapter"),
            "order": q["order"], "shared_with": q.get("shared_with"), "requirements": q.get("requirements", {}),
            "goals": goals, "coins": q["rewards"].get("coins", 0), "items": q["rewards"].get("items", {}),
            "affection": q["rewards"].get("affection", 0), "collections": q["rewards"].get("collections", []),
            "go": q.get("go"),
        })
    order_chain = {"main": mains, **{k: v for k, v in sorted(lines.items())}}
    return {"quests": rows, "order": order_chain}


def section_matrix_diff(d: Data, matrix_path: Path) -> dict:
    """Compara os IDs do JSON com a tabela de 08_MATRIZ_QUESTS.md (IDs entre crases no início da linha)."""
    if not matrix_path.exists():
        return {"available": False}
    text = matrix_path.read_text(encoding="utf-8")
    section = text.split("## Todos os IDs existentes", 1)[-1]
    matrix_ids = []
    for match in re.finditer(r"^\|\s*`([a-z0-9_]+)`\s*\|", section, re.M):
        matrix_ids.append(match.group(1))
    # a parte seguinte da matriz (novos IDs) começa em outro título; parar no próximo '## '
    head = section.split("\n## ", 1)[0]
    existing_ids = [m.group(1) for m in re.finditer(r"^\|\s*`([a-z0-9_]+)`\s*\|", head, re.M)]
    in_json = set(d.quests)
    return {"available": True, "matrix_rows_existing": len(existing_ids), "json_total": len(in_json),
            "in_json_not_matrix": sorted(in_json - set(existing_ids)),
            "in_matrix_not_json": sorted(set(existing_ids) - in_json),
            "duplicate_matrix_ids": sorted(i for i, c in Counter(existing_ids).items() if c > 1)}


# --------------------------------------------------------------------------------------
# Referências, ciclos e alcançabilidade
# --------------------------------------------------------------------------------------

def resolve_stat(d: Data, key: str):
    """None = não resolvível estaticamente (contador genérico); True/False = prefixo conhecido."""
    if ":" not in key:
        return None
    prefix, rest = key.split(":", 1)
    kind = STAT_PREFIXES.get(prefix)
    if kind is None:
        return None
    if kind == "npc":
        return rest in d.npcs
    if kind == "crop":
        return rest in d.crops
    if kind == "item":
        return rest in d.items
    if kind == "order":
        return rest in d.orders
    if kind == "walk":
        return rest in d.walks["walks"]
    if kind == "activity":
        return rest in d.activities
    if kind == "friend":
        return rest in d.friends["friends"]
    if kind == "screen":
        return True
    return None


def check_references(d: Data) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    item_ids, upgrade_ids, quest_ids = set(d.items), set(d.upgrades), set(d.quests)
    collection_ids, npc_ids = set(d.collections), set(d.npcs)
    place_ids = {w: set(v.get("places", {})) for w, v in d.worlds.items()}

    def where(file, path):
        return f"{file}:{fmt_path(path)}"

    def check_amounts(file, path, mapping, label):
        for item_id in mapping:
            if item_id not in item_ids:
                errors.append(f"{where(file, path)}: {label} usa item inexistente '{item_id}'")

    for name in DATA_FILES:
        for path, key, value in walk(d.files[name]):
            here = path + (key,)
            if key in ("inputs", "materials", "yield") and isinstance(value, dict) and name != "quests":
                check_amounts(name, here, value, key)
            elif key == "items" and isinstance(value, dict):
                check_amounts(name, here, value, "items")
            elif key == "collections" and isinstance(value, list):
                for c in value:
                    if c not in collection_ids:
                        errors.append(f"{where(name, here)}: coleção inexistente '{c}'")
            elif key == "requirements" and isinstance(value, dict):
                for q in value.get("quests", []):
                    if q not in quest_ids:
                        errors.append(f"{where(name, here)}: requisito de missão inexistente '{q}'")
                for up in value.get("owned", []):
                    if up not in upgrade_ids:
                        errors.append(f"{where(name, here)}: requisito owned inexistente '{up}'")
                for it in value.get("produced", {}):
                    if it not in item_ids:
                        errors.append(f"{where(name, here)}: requisito produced com item inexistente '{it}'")
                for skill in value.get("skills", {}):
                    if skill not in d.prog["skills"]:
                        errors.append(f"{where(name, here)}: atributo inexistente '{skill}'")
                for stat in value.get("stats", {}):
                    if resolve_stat(d, stat) is False:
                        errors.append(f"{where(name, here)}: contador '{stat}' aponta para ID inexistente")
                if "chapter" in value and not 1 <= int(value["chapter"]) <= len(d.prog["chapters"]) + 1:
                    errors.append(f"{where(name, here)}: capítulo {value['chapter']} fora da lista")

    # Missões
    for q_id, q in d.quests.items():
        if q["npc"] not in npc_ids:
            errors.append(f"quests:{q_id}: npc inexistente '{q['npc']}'")
        if "shared_with" in q and q["shared_with"] not in quest_ids:
            errors.append(f"quests:{q_id}: shared_with inexistente '{q['shared_with']}'")
        if q["kind"] == "main" and not 1 <= q["chapter"] <= len(d.prog["chapters"]):
            errors.append(f"quests:{q_id}: capítulo {q['chapter']} sem entrada em chapters")
        for index, goal in enumerate(q["goals"]):
            g_type, g_key = goal["type"], goal["key"]
            tag = f"quests:{q_id}/goals/{index}"
            if g_type == "quest" and g_key not in quest_ids:
                errors.append(f"{tag}: objetivo quest inexistente '{g_key}'")
            elif g_type == "owned" and g_key not in upgrade_ids:
                errors.append(f"{tag}: objetivo owned inexistente '{g_key}'")
            elif g_type in ("have", "deliver") and g_key not in item_ids:
                errors.append(f"{tag}: objetivo {g_type} com item inexistente '{g_key}'")
            elif g_type == "stat":
                res = resolve_stat(d, g_key)
                if res is False:
                    errors.append(f"{tag}: contador '{g_key}' aponta para ID inexistente")
                elif res is None and ":" in g_key:
                    warnings.append(f"{tag}: contador '{g_key}' não resolvido estaticamente")
        go = q.get("go")
        if go:
            world = go.get("world")
            if world and world not in d.worlds:
                errors.append(f"quests:{q_id}/go: mundo inexistente '{world}'")
            place = str(go.get("place", ""))
            # Formas aceitas por Places.run: "<lugar>", "npc:", "buy:", "crop:", "recipe:", "order:", "route:", "station:", "market:"
            prefix, _, rest = place.partition(":")
            targets = {"npc": npc_ids, "buy": upgrade_ids, "crop": set(d.crops), "recipe": set(d.recipes),
                       "order": set(d.orders), "route": set(d.activities), "station": set(d.stations)}
            if world in d.worlds and place:
                if prefix in targets and rest:
                    if rest not in targets[prefix]:
                        errors.append(f"quests:{q_id}/go: '{place}' aponta para ID inexistente")
                elif prefix == "market":
                    pass  # aba do comércio (MarketUi); não há tabela de dados para validar
                elif place not in place_ids[world]:
                    errors.append(f"quests:{q_id}/go: lugar '{place}' inexistente em '{world}'")

    # Receitas / estações
    for r_id, r in d.recipes.items():
        if r["station"] not in d.stations:
            errors.append(f"recipes:{r_id}: estação inexistente '{r['station']}'")
        out = d.recipe_output(r)
        if "output_collection" in r:
            if out not in collection_ids:
                errors.append(f"recipes:{r_id}: coleção de saída inexistente '{out}'")
        elif out not in item_ids:
            errors.append(f"recipes:{r_id}: saída inexistente '{out}'")
    for s_id in d.stations:
        if s_id not in upgrade_ids:
            if d.station_upgrade(s_id) not in upgrade_ids:
                warnings.append(f"config:stations/{s_id}: sem melhoria que a libere em progression.upgrades")
        for up_id in d.stations[s_id].get("slot_upgrades", {}):
            if up_id not in upgrade_ids:
                errors.append(f"config:stations/{s_id}/slot_upgrades: melhoria inexistente '{up_id}'")
    for a_id, a in d.animals.items():
        if a["station"] not in d.stations:
            errors.append(f"config:animals/{a_id}: estação inexistente '{a['station']}'")

    # Depósitos e Natureza
    for dep_id, dep in d.storage.items():
        if dep["building"] not in upgrade_ids:
            errors.append(f"progression:storage/{dep_id}: construção inexistente '{dep['building']}'")
        for lv in dep.get("levels", []):
            if lv not in upgrade_ids:
                errors.append(f"progression:storage/{dep_id}: ampliação inexistente '{lv}'")
    for site_id, site in d.prog["nature_sites"].items():
        for key in ("slot_upgrades", "level_upgrades"):
            for up in site[key]:
                if up not in upgrade_ids:
                    errors.append(f"progression:nature_sites/{site_id}/{key}: melhoria inexistente '{up}'")
    for res_id, res in d.prog["nature_resources"].items():
        for route in res["routes"]:
            if route not in d.activities:
                errors.append(f"progression:nature_resources/{res_id}: rota inexistente '{route}'")
    # Mundos
    for w_id, w in d.worlds.items():
        for p_id, p in w.get("places", {}).items():
            if "upgrade" in p and p["upgrade"] not in upgrade_ids:
                errors.append(f"worlds:{w_id}/places/{p_id}: melhoria inexistente '{p['upgrade']}'")
            for up in p.get("upgrades", []):
                if up not in upgrade_ids:
                    errors.append(f"worlds:{w_id}/places/{p_id}: melhoria inexistente '{up}'")
    # Amigos / passeios
    for f_id, f in d.friends["friends"].items():
        if f.get("likes") and f["likes"] not in item_ids:
            errors.append(f"friends:{f_id}: petisco preferido inexistente '{f['likes']}'")
    for key in ("economia", ):
        pass
    return {"errors": sorted(set(errors)), "warnings": sorted(set(warnings))}


def dependency_graph(d: Data):
    """Grafo E (AND) das dependências de liberação. Arestas: (origem, destino, tipo)."""
    edges: list[tuple[str, str, str]] = []
    mains = sorted((q for q, v in d.quests.items() if v["kind"] == "main"), key=lambda q: (d.quests[q]["chapter"], d.quests[q]["order"]))
    chapter_quests: dict = defaultdict(list)
    for q in mains:
        chapter_quests[d.quests[q]["chapter"]].append(q)

    def req_edges(src, requirements):
        for q in requirements.get("quests", []):
            edges.append((src, f"quest:{q}", "requisito"))
        for u in requirements.get("owned", []):
            edges.append((src, f"upgrade:{u}", "requisito"))
        if "chapter" in requirements:
            for ch in range(1, int(requirements["chapter"])):
                for q in chapter_quests.get(ch, []):
                    edges.append((src, f"quest:{q}", f"capítulo {requirements['chapter']}"))
        for item in requirements.get("produced", {}):
            for r_id, r in d.recipes.items():
                pass  # produzir exige receita; tratado na alcançabilidade (OU), não neste grafo E

    previous = None
    for q in mains:
        if previous:
            edges.append((f"quest:{q}", f"quest:{previous}", "ordem principal"))
        previous = q
    lines: dict = defaultdict(list)
    for q, v in d.quests.items():
        if v["kind"] == "line":
            lines[v["line"]].append(q)
    for line_quests in lines.values():
        line_quests.sort(key=lambda q: d.quests[q]["order"])
        for a, b in zip(line_quests, line_quests[1:]):
            edges.append((f"quest:{b}", f"quest:{a}", "ordem da linha"))
    for q_id, q in d.quests.items():
        req_edges(f"quest:{q_id}", q.get("requirements", {}))
        if "shared_with" in q:
            edges.append((f"quest:{q_id}", f"quest:{q['shared_with']}", "shared_with"))
        for goal in q["goals"]:
            if goal["type"] == "owned":
                edges.append((f"quest:{q_id}", f"upgrade:{goal['key']}", "objetivo owned"))
            elif goal["type"] == "quest":
                edges.append((f"quest:{q_id}", f"quest:{goal['key']}", "objetivo quest"))
    for u_id, up in d.upgrades.items():
        req_edges(f"upgrade:{u_id}", up.get("requirements", {}))
    # A liberação de cada nível de ampliação de depósito exige o anterior (ordem da lista)
    for dep in d.storage.values():
        chain = [dep["building"]] + dep.get("levels", [])
        for a, b in zip(chain, chain[1:]):
            edges.append((f"upgrade:{b}", f"upgrade:{a}", "ordem do depósito"))
    for c_id, crop in d.crops.items():
        req_edges(f"crop:{c_id}", crop.get("requirements", {}))
    for r_id, r in d.recipes.items():
        req_edges(f"recipe:{r_id}", r.get("requirements", {}))
    return edges


def strongly_connected(edges):
    graph: dict = defaultdict(list)
    nodes = set()
    for a, b, _ in edges:
        graph[a].append(b)
        nodes.update((a, b))
    index, low, on, stack, result = {}, {}, set(), [], []
    counter = [0]

    def visit(v):
        # iterativo para evitar limite de recursão
        work = [(v, iter(sorted(graph[v])))]
        index[v] = low[v] = counter[0]
        counter[0] += 1
        stack.append(v)
        on.add(v)
        while work:
            node, it = work[-1]
            advanced = False
            for w in it:
                if w not in index:
                    index[w] = low[w] = counter[0]
                    counter[0] += 1
                    stack.append(w)
                    on.add(w)
                    work.append((w, iter(sorted(graph[w]))))
                    advanced = True
                    break
                if w in on:
                    low[node] = min(low[node], index[w])
            if advanced:
                continue
            work.pop()
            if work:
                parent = work[-1][0]
                low[parent] = min(low[parent], low[node])
            if low[node] == index[node]:
                component = []
                while True:
                    w = stack.pop()
                    on.discard(w)
                    component.append(w)
                    if w == node:
                        break
                result.append(sorted(component))

    for v in sorted(nodes):
        if v not in index:
            visit(v)
    return [c for c in result if len(c) > 1 or any(a == c[0] and b == c[0] for a, b, _ in edges)]


def reachability(d: Data) -> dict:
    """Ponto fixo estático (aproximação): o que pode ser obtido a partir do início, sem simular tempo/estoque.

    Itens são obtidos por QUALQUER fonte conhecida (OU); melhorias/missões exigem TODOS os requisitos (E).
    Contadores (`stat`) e atributos são tratados como satisfazíveis — a auditoria não mede taxa de uso.
    """
    quests_done, owned, items = set(), set(), set(d.config["start"].get("inventory", {}))
    crops, recipes = set(), set()
    chapter_quests: dict = defaultdict(list)
    for q, v in d.quests.items():
        if v["kind"] == "main":
            chapter_quests[v["chapter"]].append(q)
    chapter_count = len(d.prog["chapters"])

    def chapter_ok(n):
        return all(q in quests_done for ch in range(1, n) for q in chapter_quests.get(ch, []))

    def req_ok(r):
        return (all(q in quests_done for q in r.get("quests", [])) and all(u in owned for u in r.get("owned", []))
                and chapter_ok(int(r.get("chapter", 1))) and all(i in items for i in r.get("produced", {})))

    def gain(mapping):
        for k in mapping:
            items.add(k)

    changed = True
    rounds = 0
    legacy = set(d.prog["settings"].get("initial_owned", []))
    owned |= legacy
    while changed:
        changed = False
        rounds += 1
        before = (len(quests_done), len(owned), len(items), len(crops), len(recipes))
        for c_id, crop in d.crops.items():
            if c_id not in crops and (req_ok(crop.get("requirements", {})) or c_id in ("carrot",)):
                crops.add(c_id)
                gain(crop["yield"])
        for r_id, r in d.recipes.items():
            if r_id not in recipes and d.station_upgrade(d.recipes[r_id]["station"]) in owned and req_ok(r.get("requirements", {})) \
                    and all(i in items for i in r["inputs"]):
                recipes.add(r_id)
                if "output" in r:
                    items.add(r["output"])
        for a_id, act in d.activities.items():
            if req_ok(act.get("requirements", {})):
                gain(act.get("rewards", {}).get("items", {}))
        for w in d.walks["walks"].values():
            if req_ok(w.get("requirements", {})):
                for entry in w["loot"]["table"]:
                    gain(entry.get("items", {}))
                gain(w["loot"].get("first", {}).get("items", {}))
                gain(w["loot"].get("rare", {}).get("duplicate", {}).get("items", {}))
        for world in d.finds["worlds"].values():
            if req_ok(world.get("requirements", {})):
                for entry in world.get("guaranteed", []) + world.get("table", []):
                    gain(entry.get("items", {}))
        for f in d.friends["friends"].values():
            if req_ok(f.get("requirements", {})):
                for reward in f.get("heart_rewards", []):
                    gain(reward.get("items", {}))
                for entry in f.get("visit_gift", {}).get("loot", []):
                    gain(entry.get("items", {}))
        for lv in d.prog["level_rewards"].values():
            gain(lv.get("items", {}))
        for lv in d.prog["bond_levels"]:
            gain(lv.get("rewards", {}).get("items", {}))
        for g in d.prog["daily_gift"]:
            gain(g.get("items", {}))
        for o in d.orders.values():
            if req_ok(o.get("requirements", {})) and all(i in items for i in o["inputs"]):
                gain(o["rewards"].get("items", {}))
        for s in d.prog["shop_items"].values():
            gain(s.get("items", {}))
        for r in d.routines["daily"]["missions"].values():
            gain(r.get("rewards", {}).get("items", {}))
        for r in d.routines["weekly"]["missions"].values():
            gain(r.get("rewards", {}).get("items", {}))
        gain(d.prog["treasure"]["rewards"].get("items", {}))
        for u_id, up in d.upgrades.items():
            if u_id in owned:
                continue
            if req_ok(up.get("requirements", {})) and all(i in items for i in up.get("materials", {})):
                owned.add(u_id)
        for q_id in sorted(d.quests, key=lambda q: (d.quests[q]["kind"], d.quests[q].get("chapter") or 0, d.quests[q]["order"])):
            if q_id in quests_done:
                continue
            q = d.quests[q_id]
            if q["kind"] == "main":
                previous = [x for x in d.quests if d.quests[x]["kind"] == "main"
                            and (d.quests[x]["chapter"], d.quests[x]["order"]) < (q["chapter"], q["order"])]
            else:
                previous = [x for x in d.quests if d.quests[x]["kind"] == "line" and d.quests[x]["line"] == q["line"]
                            and d.quests[x]["order"] < q["order"]]
            if not all(x in quests_done for x in previous):
                continue
            if not req_ok(q.get("requirements", {})):
                continue
            ok = True
            for goal in q["goals"]:
                if goal["type"] == "owned" and goal["key"] not in owned:
                    ok = False
                elif goal["type"] == "quest" and goal["key"] not in quests_done and goal["key"] != q.get("shared_with"):
                    ok = False
                elif goal["type"] in ("have", "deliver") and goal["key"] not in items:
                    ok = False
            if ok:
                quests_done.add(q_id)
                gain(q["rewards"].get("items", {}))
        changed = before != (len(quests_done), len(owned), len(items), len(crops), len(recipes))
        if rounds > 200:
            break
    return {
        "rounds": rounds, "quests_reached": len(quests_done), "quests_total": len(d.quests),
        "quests_not_reached": sorted(set(d.quests) - quests_done),
        "upgrades_reached": len(owned), "upgrades_total": len(d.upgrades),
        "upgrades_not_reached": sorted(set(d.upgrades) - owned),
        "crops_not_reached": sorted(set(d.crops) - crops), "recipes_not_reached": sorted(set(d.recipes) - recipes),
        "items_never_obtained_by_known_sources": sorted(set(d.items) - items),
        "note": "aproximação estática: ignora tempo, estoque, depósitos e contadores (stat); itens vêm de qualquer fonte conhecida",
    }


def section_references(d: Data) -> dict:
    refs = check_references(d)
    edges = dependency_graph(d)
    cycles = strongly_connected(edges)
    return {"errors": refs["errors"], "warnings": refs["warnings"],
            "edge_count": len(edges), "cycles": cycles, "reachability": reachability(d)}


# --------------------------------------------------------------------------------------
# Suposições críticas (dados + verificação textual do código)
# --------------------------------------------------------------------------------------

def find_line(path: Path, needle: str):
    if not path.exists():
        return None
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if needle in line:
            return number
    return None


def code_checks(code_dir: Path) -> list[dict]:
    gs = code_dir / "autoload/game_state.gd"
    checks = []

    def add(cid, claim, needle, file="autoload/game_state.gd", expect_present=True):
        path = code_dir / file
        line = find_line(path, needle)
        ok = (line is not None) if expect_present else (line is None)
        checks.append({"id": cid, "claim": claim, "file": file, "needle": needle, "line": line,
                       "result": "CONFIRMADO" if ok else "NÃO CONFIRMADO"})

    add("C1", "Limite do depósito só vale se a construção foi comprada (has_upgrade da construção)",
        "return Database.progression.storage.has(id) and has_upgrade(str(Database.progression.storage[id].building))")
    add("C2", "Colheita paga crop.coins além do produto", 'coins += int(crop.get("coins", 0))')
    add("C3", "Receita multiplica saída por `qty` (e por animais nas criações)", 'return int(recipe.get("qty", 1)) * factor')
    add("C4", "Carinho (`pet`) soma +1 afeto sem recarga no GameState", "dog.affection += 1")
    add("C5", "Brincar soma +2 afeto", "dog.affection += 2")
    add("C6", "Recompensa de cuidado usa recarga `care:<ação>` e só se a necessidade estava baixa", "func _care_reward(action_id: String, useful: bool)")
    add("C7", "Limite de armazenamento desligável por teste (`unlimited_storage`)", "var unlimited_storage := false")
    add("C8", "Cozinhar valida e consome tudo de uma vez (validação atômica)", "inventory.remove_all(recipe_inputs(recipe_id))")
    pet_body = ""
    if gs.exists():
        text = gs.read_text(encoding="utf-8")
        match = re.search(r"func pet\(\) -> void:(.*?)\nfunc ", text, re.S)
        pet_body = match.group(1) if match else ""
    checks.append({"id": "C9", "claim": "`GameState.pet()` não tem recarga/guarda de intervalo (a guarda de 1,2 s está só na interface)",
                   "file": "autoload/game_state.gd", "needle": "func pet() sem 'cooldown'",
                   "line": find_line(gs, "func pet() -> void:"), "result": "CONFIRMADO" if pet_body and "cooldown" not in pet_body else "NÃO CONFIRMADO"})
    add("C10", "Intervalo de 1,2 s do carinho existe só na interface (PET_REWARD_EVERY)", "const PET_REWARD_EVERY := 1.2",
        file="scenes/ui/pet_screen/pet_screen.gd")
    add("C11", "Fila da estação é sequencial: cada trabalho começa quando o anterior termina", 'start = maxf(now, float(queue.back()["ready_at"]))',
        file="scripts/state/station_state.gd")
    add("C12", "O tamanho da fila é limitado por station_slots (vagas = comprimento da fila, não máquinas paralelas)", "if target.queue.size() >= station_slots(station_id):")
    return checks


def data_checks(d: Data) -> list[dict]:
    checks = []

    def add(cid, claim, ok, evidence):
        checks.append({"id": cid, "claim": claim, "result": "CONFIRMADO" if ok else "DIVERGE", "evidence": evidence})

    q = d.quests
    mains = sum(1 for v in q.values() if v["kind"] == "main")
    add("D1", "81 missões atuais (31 principais e 50 de linhas)", len(q) == 81 and mains == 31, f"total={len(q)}, principais={mains}, linhas={len(q) - mains}")
    storage_up = {k: d.upgrades[k] for k in ("silo", "warehouse", "chest")}
    add("D2", "Silo exige main_9_cheese; armazém exige bloblo_silo; baú exige bloblo_warehouse (estado ANTES das etapas 05–08)",
        storage_up["silo"]["requirements"].get("quests") == ["main_9_cheese"]
        and storage_up["warehouse"]["requirements"].get("quests") == ["bloblo_silo"]
        and storage_up["chest"]["requirements"].get("quests") == ["bloblo_warehouse"],
        {k: v["requirements"] for k, v in storage_up.items()})
    add("D3", "Geladeira custa 40 moedas e exige lais_first_crops; fogão/geladeira/sofá/sítio e filas do fogão são `legacy_owned` (só saves antigos)",
        d.upgrades["fridge"].get("cost") == 40 and d.upgrades["fridge"].get("requirements", {}).get("quests") == ["lais_first_crops"],
        {"cost": d.upgrades["fridge"].get("cost"), "requirements": d.upgrades["fridge"].get("requirements"),
         "initial_owned": d.prog["settings"]["initial_owned"], "legacy_owned": d.prog["settings"]["legacy_owned"]})
    add("D4", "Colheita paga moedas (crops.*.coins > 0) e plantio é gratuito (sem custo de semente)",
        all(c.get("coins", 0) > 0 for c in d.crops.values()) and all("cost" not in c for c in d.crops.values()),
        {k: c.get("coins") for k, c in d.crops.items()})
    biscuit, treat = d.recipes["apple_biscuit"], d.recipes["treat_box"]
    add("D5", "apple_biscuit rende 2 por lote; treat_box 1 por lote",
        biscuit.get("qty") == 2 and treat.get("qty", 1) == 1, {"apple_biscuit.qty": biscuit.get("qty"), "treat_box.qty": treat.get("qty", 1)})
    add("D6", "Item `egg` é a saída da receita `eggs` (IDs diferentes) e farm_breakfast usa `egg`",
        d.recipes["eggs"].get("output") == "egg" and "egg" in d.orders["farm_breakfast"]["inputs"] and "eggs" not in d.items,
        {"recipes.eggs.output": d.recipes["eggs"].get("output"), "farm_breakfast.inputs": d.orders["farm_breakfast"]["inputs"], "item_eggs_exists": "eggs" in d.items})
    stations_ok = all(s in d.stations for s in ("stove", "workbench", "atelier", "chicken_coop", "cow_barn", "mill", "dairy", "blender", "sewing"))
    add("D7", "IDs de estação do plano existem em config.stations (sem estação `fridge`; geladeira é depósito/compra)",
        stations_ok and "fridge" not in d.stations, sorted(d.stations))
    add("D8", "Vagas de estação são filas sequenciais (campo `slots`); fogão tem `stove_queue`/`stove_queue_2`",
        d.stations["stove"].get("slot_upgrades") == {"stove_queue": 1, "stove_queue_2": 1},
        {s: {"slots": v.get("slots"), "slot_upgrades": v.get("slot_upgrades")} for s, v in sorted(d.stations.items())})
    add("D9", "Venda inicial: lugar `early_market` do Sítio exige bloblo_meet",
        d.worlds["farm"]["places"].get("early_market", {}).get("requirements", {}).get("quests") == ["bloblo_meet"],
        d.worlds["farm"]["places"].get("early_market"))
    add("D10", "XP de atributo vem de `skill_xp` (cultura/receita/rota); XP do jogador de `config.xp` por ação",
        all("skill_xp" in c for c in d.crops.values()) and "xp" in d.config,
        {"config.xp": d.config["xp"], "crops_have_skill_xp": all("skill_xp" in c for c in d.crops.values()), "crops_have_xp_key": any("xp" in c for c in d.crops.values())})
    add("D11", "farm_breakfast existe com egg×2, flour×2, cheese×1, 95 moedas e exige queijaria",
        d.orders["farm_breakfast"]["inputs"] == {"egg": 2, "flour": 2, "cheese": 1} and d.orders["farm_breakfast"]["rewards"]["coins"] == 95
        and d.orders["farm_breakfast"].get("requirements", {}).get("owned") == ["dairy"], d.orders["farm_breakfast"])
    bank_q = [k for k, v in q.items() if "bloblo_breakfast" == k]
    add("D12", "Missão bloblo_breakfast ainda não existe (será criada na etapa 14)", not bank_q, "ausente" if not bank_q else "presente")
    return checks


# --------------------------------------------------------------------------------------
# Verificações manuais (aritmética explícita para conferência humana)
# --------------------------------------------------------------------------------------

def manual_checks(d: Data) -> dict:
    out = {}
    carrot = d.crops["carrot"]
    carrot_price = d.sell("carrot")
    speedup = Fraction(str(d.farm["water"]["speedup"]))
    watered = carrot["seconds"] * (1 - speedup)
    value = carrot["coins"] + carrot["yield"]["carrot"] * carrot_price
    out["carrot"] = {
        "seconds": carrot["seconds"], "seconds_watered": num(watered), "coins": carrot["coins"], "yield": carrot["yield"],
        "sell_price": num(carrot_price), "value_per_harvest": num(value),
        "ceiling_per_plot_per_min": num(value / watered * 60), "ceiling_four_plots_per_min": num(4 * value / watered * 60),
        "formula": "(coins + yield×preço) / (segundos×(1−rega)) × 60",
    }
    ab, tb = d.recipes["apple_biscuit"], d.recipes["treat_box"]
    price = d.sell
    biscuit_in = sum(Fraction(q) * price(i) for i, q in ab["inputs"].items())
    biscuit_out = Fraction(ab["qty"]) * price("apple_biscuit")
    snack_raw = Fraction(d.recipes["carrot_snack"]["inputs"]["carrot"]) * price("carrot")
    out["apple_biscuit"] = {
        "inputs": ab["inputs"], "qty": ab["qty"], "seconds": ab["seconds"], "input_sell_value": num(biscuit_in),
        "output_sell_value": num(biscuit_out), "margin": num(biscuit_out - biscuit_in),
        "raw_value_with_carrot_snack_expanded": num(Fraction(ab["inputs"]["apple"]) * price("apple") + snack_raw),
        "unit_sell_price": num(price("apple_biscuit")),
    }
    treat_in = sum(Fraction(q) * price(i) for i, q in tb["inputs"].items())
    # expansão completa
    raw, _ = {}, None
    total: dict = defaultdict(Fraction)
    for ing, amount in tb["inputs"].items():
        sub, _n = expand_raw(d, ing, Fraction(amount))
        for k, v in sub.items():
            total[k] += v
    raw_value = sum(v * price(i) for i, v in total.items())
    out["treat_box"] = {
        "inputs": tb["inputs"], "qty": tb.get("qty", 1), "seconds": tb["seconds"], "input_sell_value": num(treat_in),
        "unit_sell_price": num(price("treat_box")), "margin_immediate": num(price("treat_box") * tb.get("qty", 1) - treat_in),
        "raw_inputs": {k: num(v) for k, v in sorted(total.items())}, "raw_sell_value": num(raw_value),
        "margin_vs_raw": num(price("treat_box") * tb.get("qty", 1) - raw_value),
        "orders_using_treat_box": {k: {"inputs": v["inputs"], "coins": v["rewards"].get("coins")} for k, v in d.orders.items() if "treat_box" in v["inputs"]},
    }
    fb = d.orders["farm_breakfast"]
    fb_in = sum(Fraction(q) * price(i) for i, q in fb["inputs"].items())
    flour_raw, _ = expand_raw(d, "flour", Fraction(fb["inputs"]["flour"]))
    cheese_raw, _ = expand_raw(d, "cheese", Fraction(fb["inputs"]["cheese"]))
    egg_raw, _ = expand_raw(d, "egg", Fraction(fb["inputs"]["egg"]))
    merged: dict = defaultdict(Fraction)
    for part in (flour_raw, cheese_raw, egg_raw):
        for k, v in part.items():
            merged[k] += v
    out["farm_breakfast"] = {
        "inputs": fb["inputs"], "coins": fb["rewards"]["coins"], "input_sell_value": num(fb_in),
        "margin_vs_sale": num(fb["rewards"]["coins"] - fb_in), "raw_inputs": {k: num(v) for k, v in sorted(merged.items())},
        "raw_sell_value": num(sum(v * price(i) for i, v in merged.items())),
        "margin_vs_raw": num(fb["rewards"]["coins"] - sum(v * price(i) for i, v in merged.items())),
        "cooldown": fb.get("cooldown"), "requirements": fb.get("requirements"),
    }
    return out


# --------------------------------------------------------------------------------------
# Relatório Markdown
# --------------------------------------------------------------------------------------

def render_markdown(report: dict) -> str:
    L: list[str] = []
    meta = report["meta"]
    L.append("# Auditoria estática da economia — linha de base\n")
    L.append("Gerado por `tools/economy_audit.py`. Só lê JSON (e faz verificações textuais no código); **não simula o jogo** e não estima taxa de uso do jogador. "
             "Valores como “teto” são limites aritméticos dos dados.\n")
    L.append(f"- Hash do conteúdo: `{meta['content_hash']}`")
    L.append(f"- SAVE_VERSION: `{meta['save_version']}`")
    q = meta["quests"]
    L.append(f"- Missões: **{q['total']}** ({q['main']} principais, {q['line']} de linhas: {', '.join(f'{k}={v}' for k, v in q['lines'].items())})")
    L.append(f"- Contagens: " + ", ".join(f"{k}={v}" for k, v in meta["counts"].items()) + "\n")

    L.append("## Verificações de suposições (dados)\n")
    L.append(md_table(["ID", "Suposição", "Resultado", "Evidência"], [[c["id"], c["claim"], c["result"], json.dumps(c["evidence"], ensure_ascii=False)[:300]] for c in report["assumptions_data"]]))
    L.append("\n## Verificações textuais do código\n")
    L.append(md_table(["ID", "Suposição", "Arquivo:linha", "Resultado"], [[c["id"], c["claim"], f"{c['file']}:{c['line']}" if c["line"] else c["file"], c["result"]] for c in report["assumptions_code"]]))

    L.append("\n## Culturas\n")
    L.append(md_table(["id", "s", "s c/ rega", "colheita", "moedas", "venda do lote", "valor/colheita", "teto/canteiro/min", "sem moedas", "XP atrib."],
                      [[r["id"], r["seconds"], r["seconds_watered_once"], amounts_text(r["yield"]), r["harvest_coins"], r["yield_sell_value"], r["value_per_harvest_with_coins"],
                        r["ceiling_per_plot_per_min"], r["ceiling_per_plot_per_min_without_coins"], r["skill_xp"]] for r in report["crops"]]))
    L.append("\nTeto = valor de 1 colheita ÷ tempo com uma rega, replantando no mesmo instante: limite aritmético, **não** taxa de uso.\n")

    L.append("## Receitas (por lote; criações por animal)\n")
    L.append(md_table(["receita", "estação", "entra", "sai (qtd)", "s", "venda entra", "venda sai", "margem", "margem/min máq.", "venda matéria-prima", "margem vs matéria-prima"],
                      [[r["id"], r["station"], amounts_text(r["inputs"]), f"{r['output']}×{r['qty']}", r["seconds"], r["input_sell_value"], r["output_sell_value"],
                        r["margin_immediate"], r["margin_per_machine_min"], r["raw_sell_value"], r["margin_vs_raw"]] for r in report["recipes"]]))
    L.append("\nMargem = valor de venda da saída − valor de venda dos ingredientes (perda de oportunidade de vendê-los em vez de transformá-los). "
             "“Matéria-prima” expande intermediários até as culturas/materiais. `—` = algum item sem preço de venda (não tratado como zero).\n")

    L.append("## Encomendas\n")
    L.append(md_table(["id", "entra", "moedas", "itens", "recarga s", "canal", "venda dos ingredientes", "margem", "margem vs matéria-prima", "moedas/h no limite de recarga"],
                      [[r["id"], amounts_text(r["inputs"]), r["coins"], amounts_text(r["items"]), r["cooldown"], r["channel"], r["input_sell_value"], r["margin_vs_sale"], r["margin_vs_raw"], r["coins_per_hour_at_cooldown"]] for r in report["orders"]]))

    L.append("\n## Conferência aritmética (cenoura, biscoito, caixa, café da manhã)\n")
    L.append("```json\n" + json.dumps(report["manual_checks"], ensure_ascii=False, indent=2, sort_keys=True) + "\n```\n")

    L.append("## Depósitos\n")
    for dep_id, dep in report["storage"]["deposits"].items():
        L.append(f"### {dep_id} — {dep['name']}\n")
        L.append(f"- Categorias: {', '.join(dep['categories'])}; base {dep['base']} (**só vale após comprar `{dep['building']}`**: {dep['building_cost']} moedas, {amounts_text(dep['building_materials'])}; requisitos {json.dumps(dep['building_requirements'], ensure_ascii=False)})")
        L.append(f"- Itens: {', '.join(dep['items'])}")
        for lv in dep["levels"]:
            L.append(f"  - {lv['id']}: +{lv['add']} → {lv['total_capacity']}; {lv['cost']} moedas {amounts_text(lv['materials'])}; req. {json.dumps(lv['requirements'], ensure_ascii=False)}")
    L.append("\nItens sem limite: " + ", ".join(f"{k} ({v})" for k, v in report["storage"]["exempt_items"].items()) + "\n")

    L.append("## Estações\n")
    L.append(md_table(["id", "tipo", "vagas", "máx. vagas", "ampliações de vaga", "receitas"],
                      [[s["id"], s["kind"], s["slots"], s["max_slots"], json.dumps(s["slot_upgrade_costs"], ensure_ascii=False), ", ".join(s["recipes"])] for s in report["stations"]]))

    L.append("\n## Fluxos de moedas (fontes pelo campo `coins`)\n")
    L.append(md_table(["origem", "entradas", "soma mín", "soma máx"], [[k, v["entries"], v["sum_min"], v["sum_max"]] for k, v in report["coins"]["by_source"].items()]))
    c = report["coins"]
    L.append(f"\n- Missões: principais {c['quests_coin_totals']['main']}; linhas {c['quests_coin_totals']['line']}; capítulos {c['chapters_coin_total']}; níveis 2–10 {c['level_rewards_2_to_10_coins']}; vínculo {c['bond_levels_coins']}.")
    L.append(f"- Início: {report['sources_start']} moedas; {c['sources_extra']['sell_price_items']} itens têm `sell_price` (venda direta, taxa de uso desconhecida).")
    L.append(f"- Sumidouros: melhorias {c['sinks']['upgrades_coins_total']} moedas; terrenos {c['sinks']['plots_unlock_total']}; animais {c['sinks']['animals_total']}; loja {c['sinks']['shop_items']}.\n")

    L.append("## Compra → recompensa\n")
    L.append(md_table(["compra", "custo", "materiais", "missões com objetivo owned", "moedas da missão", "% do custo", "capítulo-alvo", "moedas do capítulo"],
                      [[r["upgrade"], r["cost"], amounts_text(r["materials"]), ", ".join(r["quests_with_owned_goal"]), r["quest_coin_rewards"], r["reward_over_cost_pct"], r["chapter_whose_target_is_it"], r["chapter_coin_reward"]]
                       for r in report["purchases"] if r["cost"] or r["quests_with_owned_goal"]]))

    L.append("\n## Parafusos e cintas de ferro\n")
    for item, data in report["bolts"].items():
        L.append(f"- **{item}** — fontes: " + "; ".join(f"{k}: {v['entries']} entradas ({v['min']}–{v['max']})" for k, v in data["sources_by_origin"].items()) + f". Demanda em melhorias/receitas: {data['demand_total']} ({', '.join(str(list(x.values())[0]) + '×' + str(x['qty']) for x in data['demand'])}).")

    L.append("\n## Natureza\n")
    L.append(md_table(["rota", "local", "s", "itens", "moedas", "XP atrib.", "requisitos"],
                      [[r["id"], r["place"], r["seconds"], amounts_text(r["items"]), r["coins"], json.dumps(r["skill_xp"], ensure_ascii=False), json.dumps(r["requirements"], ensure_ascii=False)] for r in report["nature"]["activities"]]))

    L.append("\n## Banco de recompensas únicas\n")
    rb = report["reward_bank"]
    L.append(f"- Itens por missões: {amounts_text(rb['quest_items_total'])}; coleções: {', '.join(rb['quest_collections'])}; afeto {rb['quest_affection_total']}.")
    L.append(md_table(["grupo", "missões", "moedas", "itens"], [[k, v["quests"], v["coins"], amounts_text(v["items"])] for k, v in rb["by_group"].items()]))

    L.append("\n## Missões (ordem e prêmios)\n")
    L.append(md_table(["id", "tipo", "linha/cap.", "ordem", "shared_with", "requisitos", "objetivos", "moedas", "itens"],
                      [[r["id"], r["kind"], f"{r['line']}/{r['chapter']}" if r["chapter"] else r["line"], r["order"], r["shared_with"],
                        json.dumps(r["requirements"], ensure_ascii=False) if r["requirements"] else "",
                        "; ".join(f"{g['type']}:{g['key']}" + (f"×{g['target']}" if g["target"] else "") + ("*" if g["fresh"] else "") for g in r["goals"]),
                        r["coins"], amounts_text(r["items"])] for r in sorted(report["quest_graph"]["quests"], key=lambda r: (r["line"] != "main", r["line"], r["chapter"] or 0, r["order"]))]))
    L.append("\n`*` = objetivo `fresh` (conta só a partir do início do passo).\n")
    diff = report["matrix_diff"]
    if diff.get("available"):
        L.append(f"Comparação com `08_MATRIZ_QUESTS.md`: {diff['matrix_rows_existing']} IDs na matriz, {diff['json_total']} no JSON; "
                 f"no JSON e fora da matriz: {diff['in_json_not_matrix'] or 'nenhum'}; na matriz e fora do JSON: {diff['in_matrix_not_json'] or 'nenhum'}.")

    refs = report["references"]
    L.append("\n## Referências, ciclos e alcançabilidade\n")
    L.append(f"- Erros de referência: **{len(refs['errors'])}**; avisos: {len(refs['warnings'])}; arestas de dependência: {refs['edge_count']}; ciclos: **{len(refs['cycles'])}**.")
    reach = refs["reachability"]
    L.append(f"- Alcançabilidade estática (aproximação): missões {reach['quests_reached']}/{reach['quests_total']}, melhorias {reach['upgrades_reached']}/{reach['upgrades_total']}.")
    return "\n".join(L) + "\n"


def render_references(report: dict) -> str:
    refs = report["references"]
    L = ["# Referências, ciclos e alcançabilidade\n"]
    L.append(f"Hash do conteúdo auditado: `{report['meta']['content_hash']}`\n")
    L.append(f"## Erros de referência ({len(refs['errors'])})\n")
    L += [f"- {e}" for e in refs["errors"]] or ["Nenhum."]
    L.append(f"\n## Avisos ({len(refs['warnings'])})\n")
    L += [f"- {w}" for w in refs["warnings"]] or ["Nenhum."]
    L.append(f"\n## Ciclos de requisitos ({len(refs['cycles'])})\n")
    L += [f"- {' → '.join(c)}" for c in refs["cycles"]] or ["Nenhum ciclo no grafo E (requisitos, ordem das linhas, objetivos owned/quest, ordem dos depósitos)."]
    reach = refs["reachability"]
    L.append("\n## Alcançabilidade estática (aproximação)\n")
    L.append(f"{reach['note']}.\n")
    L.append(f"- Missões alcançadas: {reach['quests_reached']}/{reach['quests_total']}; não alcançadas: {reach['quests_not_reached'] or 'nenhuma'}")
    L.append(f"- Melhorias alcançadas: {reach['upgrades_reached']}/{reach['upgrades_total']}; não alcançadas: {reach['upgrades_not_reached'] or 'nenhuma'}")
    L.append(f"- Culturas não alcançadas: {reach['crops_not_reached'] or 'nenhuma'}; receitas: {reach['recipes_not_reached'] or 'nenhuma'}")
    L.append(f"- Itens sem fonte conhecida: {reach['items_never_obtained_by_known_sources'] or 'nenhum'}")
    return "\n".join(L) + "\n"


# --------------------------------------------------------------------------------------
# Execução
# --------------------------------------------------------------------------------------

def git(*args) -> str:
    try:
        return subprocess.run(["git", *args], cwd=REPO, capture_output=True, text=True, encoding="utf-8", timeout=30).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def build_report(data_dir: Path, code_dir: Path, matrix: Path) -> dict:
    d = Data(data_dir)
    section_errors: list[str] = []

    def safe(name, func, fallback):
        """Dados quebrados (referência inexistente) não devem esconder o relatório de referências."""
        try:
            return func()
        except (KeyError, TypeError, ValueError, ZeroDivisionError) as error:
            section_errors.append(f"{name}: {type(error).__name__}: {error}")
            return fallback

    report = {
        "meta": safe("meta", lambda: section_meta(d, code_dir), {"content_hash": d.content_hash(), "save_version": None, "quests": {"total": len(d.quests), "main": 0, "line": 0, "lines": {}}, "counts": {}}),
        "assumptions_data": safe("assumptions_data", lambda: data_checks(d), []),
        "assumptions_code": safe("assumptions_code", lambda: code_checks(code_dir), []),
        "items": safe("items", lambda: section_items(d), {}),
        "storage": safe("storage", lambda: section_storage(d), {"deposits": {}, "exempt_items": {}}),
        "crops": safe("crops", lambda: crop_rows(d), []),
        "recipes": safe("recipes", lambda: section_recipes(d)["recipes"], []),
        "orders": safe("orders", lambda: section_orders(d)["orders"], []),
        "stations": safe("stations", lambda: section_stations(d)["stations"], []),
        "upgrades": safe("upgrades", lambda: section_upgrades(d), {}),
        "nature": safe("nature", lambda: section_nature(d), {"activities": []}),
        "coins": safe("coins", lambda: section_coins(d), {"by_source": {}, "quests_coin_totals": {"main": {}, "line": {}}, "chapters_coin_total": 0, "level_rewards_2_to_10_coins": 0, "bond_levels_coins": [], "sources_extra": {"sell_price_items": 0}, "sinks": {"upgrades_coins_total": 0, "plots_unlock_total": 0, "animals_total": 0, "shop_items": {}}}),
        "sources_start": d.config["start"]["coins"],
        "bolts": safe("bolts", lambda: section_bolts(d), {}),
        "reward_bank": safe("reward_bank", lambda: section_reward_bank(d), {"quest_items_total": {}, "quest_collections": [], "quest_affection_total": 0, "by_group": {}}),
        "purchases": safe("purchases", lambda: section_purchases(d)["purchases"], []),
        "early_game": safe("early_game", lambda: section_early_game(d), {}),
        "quest_graph": safe("quest_graph", lambda: section_quest_graph(d), {"quests": [], "order": {}}),
        "matrix_diff": safe("matrix_diff", lambda: section_matrix_diff(d, matrix), {"available": False}),
        "references": safe("references", lambda: section_references(d), {"errors": [], "warnings": [], "edge_count": 0, "cycles": [], "reachability": {}}),
        "manual_checks": safe("manual_checks", lambda: manual_checks(d), {}),
        "section_errors": sorted(section_errors),
    }
    report["_data_hashes"] = dict(sorted(d.hashes.items()))
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data", default=str(REPO / "game" / "data"))
    parser.add_argument("--code", default=str(REPO / "game"))
    parser.add_argument("--out", default=str(REPO / "build" / "economy" / "baseline"))
    parser.add_argument("--matrix", default=str(REPO / "docs" / "plans" / "economia" / "08_MATRIZ_QUESTS.md"))
    args = parser.parse_args()

    data_dir, code_dir, out_dir = Path(args.data), Path(args.code), Path(args.out)
    try:
        report = build_report(data_dir, code_dir, Path(args.matrix))
    except (OSError, KeyError, ValueError, TypeError) as error:
        print(f"ERRO ao auditar {data_dir}: {type(error).__name__}: {error}", file=sys.stderr)
        return 2

    out_dir.mkdir(parents=True, exist_ok=True)
    hashes = report.pop("_data_hashes")
    json_text = json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    (out_dir / "baseline.json").write_text(json_text, encoding="utf-8", newline="\n")
    (out_dir / "baseline.md").write_text(render_markdown(report), encoding="utf-8", newline="\n")
    (out_dir / "references.md").write_text(render_references(report), encoding="utf-8", newline="\n")

    code_hashes = {}
    for rel in CODE_FILES:
        path = code_dir / rel
        if path.exists():
            code_hashes[rel] = sha256_text_file(path)
    manifest = {
        "content_hash": report["meta"]["content_hash"],
        "data_files": hashes,
        "code_files_read": code_hashes,
        "outputs": {name: sha256_bytes((out_dir / name).read_bytes()) for name in ("baseline.json", "baseline.md", "references.md")},
    }
    (out_dir / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8", newline="\n")

    status = git("status", "--short")
    run_meta = {
        "generated_at": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
        "argv": sys.argv[1:], "python": sys.version.split()[0],
        "git_branch": git("branch", "--show-current"), "git_head": git("rev-parse", "HEAD"),
        "git_status_short": status.splitlines(),
        "git_diff_stat": git("diff", "--stat").splitlines(),
        "note": "Único arquivo que muda entre execuções; os demais são determinísticos para os mesmos dados.",
    }
    (out_dir / "run_meta.json").write_text(json.dumps(run_meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")

    refs = report["references"]
    print(f"Auditoria: {len(report['quest_graph']['quests'])} missões, {len(report['recipes'])} receitas, hash {report['meta']['content_hash'][:12]}")
    print(f"Erros de referência: {len(refs['errors'])}; ciclos: {len(refs['cycles'])}; avisos: {len(refs['warnings'])}")
    print(f"Saída: {out_dir}")
    for error in refs["errors"][:20]:
        print("  ERRO:", error, file=sys.stderr)
    for error in report["section_errors"]:
        print("  SEÇÃO COM FALHA:", error, file=sys.stderr)
    return 1 if refs["errors"] or refs["cycles"] or report["section_errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
