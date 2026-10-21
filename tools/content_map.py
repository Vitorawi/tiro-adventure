"""Mapa local e somente leitura do conteúdo do Tiro. Sem dependências externas.

    py -X utf8 tools/content_map.py --open
"""
from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import threading
import webbrowser
from collections import Counter, defaultdict
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlsplit

from content_pacing import EVIDENCE, PLAN, build_pacing, save_plan

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "game/data"
UI = Path(__file__).resolve().parent / "content_map"

KINDS = {
    "item": "Materiais e produtos", "recipe": "Receitas", "crop": "Horta",
    "upgrade": "Construções e melhorias", "station": "Estações", "quest": "Missões",
    "order": "Encomendas e contratos", "activity": "Coleta na Natureza",
    "world": "Mundos", "place": "Lugares", "npc": "Personagens",
    "storage": "Depósitos", "project": "Obras comunitárias", "phase": "Etapas de obra",
    "walk": "Passeios", "find": "Faro e conjuntos", "wish": "Desejos",
    "routine": "Diárias e semanais", "collection": "Coleção", "animal": "Animais",
    "friend": "Amigos", "trick": "Truques", "skill": "Atributos",
    "chapter": "Capítulos", "feature": "Funcionalidades", "shop": "Compras",
    "reward": "Presentes e marcos", "counter": "Contadores", "condition": "Condições",
    "resource": "Moedas e necessidades", "rule": "Configurações",
    "growth": "Crescimento do Tiro", "pillar": "Pilares do Tiro",
    "album": "Álbum e fotos", "house": "Decorações da Casa",
}


class ContentGraph:
    def __init__(self, data_dir: Path = DATA):
        self.data_dir = data_dir
        self.docs = {}
        self.sources = []
        self.nodes = {}
        self.edges = []
        self.edge_keys = set()
        self.warnings = []
        digest = hashlib.sha256()
        # Migração congelada, layout das salas e versão de build não são catálogo ativo.
        for path in sorted(data_dir.glob("*.json")):
            if path.stem in {"legacy_r0", "version"}:
                continue
            raw = path.read_bytes()
            self.docs[path.stem] = json.loads(raw.decode("utf-8-sig"))
            digest.update(path.name.encode() + raw)
            self.sources.append({"file": f"game/data/{path.name}", "bytes": len(raw)})
        self.revision = digest.hexdigest()
        self.p = self.docs.get("progression", {})
        self.config = self.docs.get("config", {})

    def add(self, kind, key, data=None, file="", pointer="", name="", **extra):
        node_id = f"{kind}:{key}"
        if node_id in self.nodes:
            return node_id
        data = data if data is not None else {}
        if not name:
            name = data.get("name", "") if isinstance(data, dict) else ""
        if not name and kind in {"recipe", "crop"}:
            out = data.get("output_collection", data.get("output", key))
            name = self.docs.get("items", {}).get(out, self.docs.get("collections", {}).get(out, {})).get("name", out)
        icon = data.get("icon", data.get("portrait", "")) if isinstance(data, dict) else ""
        if not icon and kind in {"crop", "recipe"}:
            out = data.get("output_collection", data.get("output", key))
            icon = self.docs.get("items", {}).get(out, self.docs.get("collections", {}).get(out, {})).get("icon", "")
        if icon:
            icon = icon.replace("res://", "/game/") if icon.startswith("res://") else f"/game/assets/sprites/ui/icons/{icon}.png"
        # Não emitir URLs quebradas de ícones simbólicos ausentes.
        if icon and not (ROOT / icon.lstrip("/")).is_file():
            icon = ""
        self.nodes[node_id] = {
            "id": node_id, "key": str(key), "kind": kind, "name": name or str(key),
            "icon": icon, "file": f"game/data/{file}.json" if file else "",
            "pointer": pointer or f"/{key}", "data": data, **extra,
        }
        return node_id

    def ref(self, kind, key):
        node_id = f"{kind}:{key}"
        if node_id not in self.nodes:
            self.add(kind, key, name=str(key), missing=True)
            self.warnings.append(f"Referência sem definição: {node_id}")
        return node_id

    def link(self, source, target, label, relation, **extra):
        edge_key = (source, target, label, relation)
        if source == target or edge_key in self.edge_keys:
            return
        self.edge_keys.add(edge_key)
        self.edges.append({"source": source, "target": target, "label": label, "relation": relation, **extra})

    def condition(self, key, name, data=None):
        return self.add("condition", key, data or {}, name=name)

    def counter(self, key):
        labels = self.p.get("settings", {}).get("stat_labels", {})
        prefix, _, value = key.partition(":")
        verbs = {"produce": "Produzir", "harvest": "Colher", "feed": "Dar ao Tiro", "sell": "Vender",
                 "order": "Entregar", "walk": "Passear", "talk": "Conversar com", "trick": "Mostrar truque",
                 "activity": "Concluir busca", "friend_gift": "Dar petisco para", "wish_item": "Atender desejo de"}
        plain = {"production_jobs": "Lotes de produção recolhidos", "cook": "Lotes preparados", "harvest": "Colheitas",
                 "sew": "Costuras concluídas", "water": "Plantas regadas", "pet": "Carinhos", "play": "Brincadeiras",
                 "bathe": "Banhos", "feed": "Alimentações", "wish": "Desejos atendidos", "find": "Achados do faro",
                 "walk": "Passeios concluídos", "sold": "Itens vendidos", "orders": "Encomendas entregues",
                 "contracts": "Contratos entregues", "storage_upgrades": "Ampliações de depósito", "care_useful": "Cuidados úteis",
                 "friend_level": "Níveis de amizade", "friend_gift": "Petiscos para amigos", "trick": "Truques apresentados",
                 "trick_learned": "Truques aprendidos", "walk_rare": "Raros de passeio", "treasure": "Tesouro aberto", "equip": "Roupas vestidas"}
        name = plain.get(key, labels.get(key, key))
        if value and prefix in verbs:
            other = next((n for n in self.nodes.values() if n["key"] == value and n["kind"] in {"item", "npc", "activity", "order", "walk", "trick", "friend"}), None)
            name = f"{verbs[prefix]} {other['name'] if other else value}"
        elif prefix == "open":
            name = "Abrir " + {"bag": "a Mochila", "village": "a Vila"}.get(value, value)
        elif prefix == "distinct_orders":
            name = "Tipos diferentes de contratos" if value == "contracts" else "Tipos diferentes de encomendas"
        node = self.add("counter", key, name=name)
        kind = {"produce": "item", "harvest": "item", "feed": "item", "sell": "item",
                "order": "order", "walk": "walk", "talk": "npc", "trick": "trick", "activity": "activity",
                "friend_gift": "friend", "wish_item": "item",
                "station_jobs": "station", "station_recipe_jobs": "station"}.get(prefix)
        if value and kind:
            # station_recipe_jobs:<station>:<recipe> conserva os dois vínculos.
            val = value.split(":")[0] if prefix == "station_recipe_jobs" else value
            if f"{kind}:{val}" in self.nodes:
                self.link(f"{kind}:{val}", node, "contabiliza", "counter")
            if prefix == "station_recipe_jobs" and ":" in value:
                self.link(self.ref("recipe", value.split(":", 1)[1]), node, "contabiliza", "counter")
        return node

    def requirements(self, target, req):
        for key, value in req.items():
            kind = {"owned": "upgrade", "quests": "quest", "projects": "project"}.get(key)
            if kind:
                for item in value:
                    self.link(self.ref(kind, item), target, "precisa concluir" if key != "owned" else "precisa ter", "requirement")
            elif key == "chapter":
                self.link(self.ref("chapter", value), target, "a partir deste capítulo", "requirement")
            elif key == "growth":
                self.link(self.ref("growth", value), target, f"fase {value}", "requirement")
            elif key == "skills":
                for skill, level in value.items():
                    self.link(self.ref("skill", skill), target, f"nível ≥ {level}", "requirement")
            elif key in {"stats", "produced", "distinct_orders"}:
                for stat, amount in value.items():
                    counter = f"produce:{stat}" if key == "produced" else f"distinct_orders:{stat}" if key == "distinct_orders" else stat
                    self.link(self.counter(counter), target, f"≥ {amount}", "requirement")
            else:
                name = f"Vínculo ≥ {value}" if key == "bond" else f"Horário: {value[0]}h–{value[1]}h" if key == "hours" else f"{key}: {value}"
                cond = self.condition(f"{key}:{json.dumps(value, sort_keys=True)}", name, {key: value})
                self.link(cond, target, "condição", "requirement")

    def inputs(self, target, items, label="consome", relation="input"):
        for item, amount in items.items():
            self.link(self.ref("item", item), target, f"{label} ×{amount}", relation, amount=amount)

    def rewards(self, source, rewards, label="recompensa", relation="reward"):
        if not isinstance(rewards, dict):
            return
        for item, amount in rewards.get("items", {}).items():
            self.link(source, self.ref("item", item), f"{label} ×{amount}", relation, amount=amount)
        for item in rewards.get("collections", []):
            self.link(source, self.ref("collection", item), label, relation)
        if rewards.get("collection"):
            self.link(source, self.ref("collection", rewards["collection"]), label, relation)
        for unlock in rewards.get("unlocks", []):
            kind, _, key = unlock.partition(":")
            self.link(source, self.ref(kind, key), "pode liberar (alternativa aos requisitos)", "unlock")
        for resource in ["coins", "xp", "affection"]:
            if rewards.get(resource):
                self.link(source, f"resource:{resource}", f"{label} {rewards[resource]}", relation)
        for skill, amount in rewards.get("skill_xp", {}).items():
            self.link(source, self.ref("skill", skill), f"XP +{amount}", relation)
        if rewards.get("find"):
            self.link(source, self.ref("find", rewards["find"]), "sorteia um achado", relation)

    def goal(self, target, goal):
        key = goal.get("key", "")
        kind = goal.get("type", "stat")
        amount = goal.get("target", 1)
        label = {"deliver": f"entregar ×{amount}", "have": f"guardar ×{amount}",
                 "owned": "comprar / ter", "quest": "concluir missão", "project": "concluir obra",
                 "growth": "alcançar fase"}.get(kind, f"meta ≥ {amount}")
        if goal.get("fresh"):
            label += " · após aceitar"
        ref_kind = {"deliver": "item", "have": "item", "owned": "upgrade", "quest": "quest", "project": "project",
                    "growth": "growth"}.get(kind)
        source = self.ref(ref_kind, key) if ref_kind else self.counter(key)
        self.link(source, target, label, "goal")
        for counter in goal.get("also_counts", []):
            self.link(self.counter(counter), target, "também conta para a meta", "goal")

    def build(self):
        for key, name in {"coins": "Moedas", "xp": "XP do jogador", "affection": "Afeto"}.items():
            self.add("resource", key, name=name)
        catalogs = [("item", "items", None), ("recipe", "recipes", None), ("crop", "crops", None),
                    ("quest", "quests", None), ("npc", "npcs", None), ("collection", "collections", None),
                    ("world", "worlds", None), ("upgrade", "progression", "upgrades"),
                    ("activity", "progression", "activities"), ("order", "progression", "orders"),
                    ("storage", "progression", "storage"), ("skill", "progression", "skills"),
                    ("feature", "progression", "features"), ("trick", "progression", "tricks"),
                    ("shop", "progression", "shop_items"), ("station", "config", "stations"),
                    ("animal", "config", "animals"), ("project", "projects", "projects"),
                    ("walk", "walks", "walks"), ("wish", "wishes", "wishes"),
                    ("friend", "friends", "friends"), ("find", "finds", "worlds")]
        for kind, file, section in catalogs:
            values = self.docs.get(file, {})
            if section:
                values = values.get(section, {})
            for key, value in values.items():
                name = "Faro · " + self.docs.get("worlds", {}).get(key, {}).get("name", key) if kind == "find" else ""
                self.add(kind, key, value, file, f"/{section}/{key}" if section else f"/{key}", name=name)
        for index, chapter in enumerate(self.p.get("chapters", []), 1):
            self.add("chapter", index, chapter, "progression", f"/chapters/{index-1}", name=f"{index}. {chapter['name']}")
        for period, data in self.docs.get("routines", {}).items():
            if not isinstance(data, dict):
                continue
            for key, routine in data.get("missions", {}).items():
                self.add("routine", f"{period}:{key}", routine, "routines", f"/{period}/missions/{key}", period=period)
        for world, data in self.docs.get("worlds", {}).items():
            for key, place in data.get("places", {}).items():
                self.add("place", f"{world}:{key}", place, "worlds", f"/{world}/places/{key}", world=world)
        for key, value in self.docs.get("finds", {}).get("sets", {}).items():
            self.add("find", f"set:{key}", value, "finds", f"/sets/{key}")
        for key, project in self.docs.get("projects", {}).get("projects", {}).items():
            for i, phase in enumerate(project.get("phases", [])):
                self.add("phase", f"{key}:{phase['id']}", phase, "projects", f"/projects/{key}/phases/{i}")
        if self.p.get("treasure"):
            self.add("reward", "treasure", self.p["treasure"], "progression", "/treasure")
        for key, value in self.p.get("level_rewards", {}).items():
            self.add("reward", f"level:{key}", value, "progression", f"/level_rewards/{key}", name=f"Presente de nível {key}")
        for i, value in enumerate(self.p.get("daily_gift", []), 1):
            self.add("reward", f"daily:{i}", value, "progression", f"/daily_gift/{i-1}", name=f"Presente do dia {i}")
        for i, value in enumerate(self.p.get("bond_levels", []), 1):
            self.add("reward", f"bond:{i}", value, "progression", f"/bond_levels/{i-1}", name=f"Vínculo nível {i}")
        for key, value in self.config.get("needs", {}).items():
            self.add("resource", key, value, "config", f"/needs/{key}")
        for key, value in self.config.items():
            if key not in {"stations", "animals", "needs"}:
                self.add("rule", f"config:{key}", value, "config", f"/{key}", name=f"Configuração · {key}")
        for key in ["settings", "customer_tiers", "mastery", "nature_sites", "nature_resources", "trick_settings"]:
            if key in self.p:
                self.add("rule", key, self.p[key], "progression", f"/{key}", name=f"Regras · {key}")
        legendary = self.docs.get("walks", {}).get("legendary")
        if legendary:
            self.add("reward", "legendary", legendary, "walks", "/legendary", name="Lendários dos passeios")
        for source, d in [("wishes", self.docs.get("wishes", {}).get("settings", {})),
                          ("friends", self.docs.get("friends", {}).get("settings", {}))]:
            self.add("rule", source, d, source, "/settings", name=f"Regras · {source}")
        for i, tier in enumerate(self.p.get("customer_tiers", []), 1):
            for npc in {o["customer"] for o in self.p.get("orders", {}).values() if o.get("customer")}:
                rid = self.add("reward", f"customer:{npc}:{i}", tier, "progression", f"/customer_tiers/{i-1}",
                               name=f"{self.docs.get('npcs', {}).get(npc, {}).get('name', npc)} · {tier['name']}")
                self.link(self.ref("npc", npc), rid, f"{tier['count']} entregas / {tier['kinds']} tipo(s)", "goal")
        for i, tier in enumerate(self.p.get("mastery", {}).get("tiers", []), 1):
            for station in self.p.get("mastery", {}).get("stations", []):
                rid = self.add("reward", f"mastery:{station}:{i}", tier, "progression", f"/mastery/tiers/{i-1}",
                               name=f"{self.config.get('stations', {}).get(station, {}).get('name', station)} · {tier['name']}")
                self.link(self.ref("station", station), rid, f"{tier['jobs']} lotes / {tier['kinds']} receitas", "goal")

        # Todas as definições existem antes de resolver as referências.
        for node in list(self.nodes.values()):
            nid, kind, key, d = node["id"], node["kind"], node["key"], node["data"]
            if not isinstance(d, dict):
                continue
            self.requirements(nid, d.get("requirements", {}))
            self.rewards(nid, d.get("rewards", {}))
            if d.get("world"):
                self.link(self.ref("world", d["world"]), nid, "local", "location")
            if d.get("npc"):
                self.link(self.ref("npc", d["npc"]), nid, "personagem", "location")
            if kind == "item":
                storage = d.get("storage")
                if not storage:
                    storage = next((sid for sid, sd in self.p.get("storage", {}).items() if d.get("category", "product") in sd.get("categories", [])), None)
                if storage and storage != "none":
                    self.link(nid, self.ref("storage", storage), "guardado em", "storage")
                if d.get("sell_price"):
                    self.link(nid, "resource:coins", f"venda unitária {d['sell_price']}", "sale")
                for need, amount in d.get("feed", {}).items():
                    self.link(nid, self.ref("resource", need), f"alimentar +{amount}", "care")
            elif kind == "recipe":
                self.inputs(nid, d.get("inputs", {}))
                out_kind = "collection" if "output_collection" in d else "item"
                out = d.get("output_collection", d.get("output", ""))
                if out:
                    self.link(nid, self.ref(out_kind, out), f"produz ×{d.get('qty', 1)}", "output")
                self.link(self.ref("station", d["station"]), nid, "feito nesta estação", "station")
            elif kind == "crop":
                self.rewards(nid, {"items": d.get("yield", {})}, "colhe", "output")
                if d.get("greenhouse") == "only":
                    self.link(self.ref("upgrade", "greenhouse"), nid, "somente na estufa", "requirement")
            elif kind in {"upgrade", "animal", "shop"}:
                self.inputs(nid, d.get("materials", {}))
                cost = d.get("cost", d.get("price", 0))
                if cost:
                    self.link("resource:coins", nid, f"custa {cost}", "cost")
                if d.get("station"):
                    self.link(nid, self.ref("station", d["station"]), "habilita" if kind == "upgrade" else "vive em", "station")
                if d.get("gift_animal"):
                    self.link(nid, self.ref("animal", d["gift_animal"]), "primeiro animal", "reward")
                if kind == "shop":
                    self.rewards(nid, {"items": d.get("items", {})}, "compra", "output")
            elif kind == "collection":
                if d.get("price"):
                    self.link("resource:coins", nid, f"custa {d['price']}", "cost")
                if d.get("shop") and f"upgrade:{d['shop']}" in self.nodes:
                    self.link(f"upgrade:{d['shop']}", nid, "compra aqui", "location")
                origin = d.get("source", "")
                if ":" in origin:
                    source_kind, _, source_key = origin.partition(":")
                    if f"{source_kind}:{source_key}" in self.nodes:
                        self.link(f"{source_kind}:{source_key}", nid, "origem declarada", "reward")
            elif kind == "station":
                upgrade = next((k for k, v in self.p.get("upgrades", {}).items() if v.get("station") == key), key)
                if upgrade in self.p.get("upgrades", {}):
                    self.link(f"upgrade:{upgrade}", nid, "habilita", "station")
                for u, slots in d.get("slot_upgrades", {}).items():
                    self.link(self.ref("upgrade", u), nid, f"+{slots} vaga(s)", "station")
            elif kind == "order":
                self.inputs(nid, d.get("inputs", {}), "entregar")
                if d.get("customer"):
                    self.link(self.ref("npc", d["customer"]), nid, "cliente", "location")
            elif kind == "quest":
                for goal in d.get("goals", []):
                    self.goal(nid, goal)
                for required in d.get("requires", []):
                    self.link(self.ref("quest", required), nid, "pré-requisito explícito", "requirement")
                if d.get("shared_with"):
                    self.link(self.ref("quest", d["shared_with"]), nid, "conclui junto · sem prêmio duplicado", "shared")
                if d.get("chapter"):
                    self.link(self.ref("chapter", d["chapter"]), nid, "faz parte", "chapter")
            elif kind == "storage":
                self.link(self.ref("upgrade", d["building"]), nid, f"capacidade base {d['base']}", "storage")
                for u in d.get("levels", []):
                    self.link(self.ref("upgrade", u), nid, "amplia", "storage")
            elif kind == "world":
                for npc in d.get("npcs", []):
                    self.link(nid, self.ref("npc", npc), "personagem neste mundo", "location")
                for place in d.get("places", {}):
                    self.link(nid, f"place:{key}:{place}", "contém", "location")
            elif kind == "place":
                for u in ([d["upgrade"]] if d.get("upgrade") else []) + d.get("upgrades", []):
                    self.link(nid, self.ref("upgrade", u), "compra aqui", "location")
                panel = d.get("panel", "")
                if panel.startswith(("station:", "stations:")):
                    for station in panel.split(":", 1)[1].split("+"):
                        self.link(nid, self.ref("station", station), "acesso à estação", "location")
                if panel.startswith("travel:"):
                    self.link(nid, self.ref("world", panel.split(":", 1)[1]), "leva para", "location")
            elif kind == "project":
                if d.get("start_coins"):
                    self.link("resource:coins", nid, f"entrada {d['start_coins']}", "cost")
                previous = None
                for phase in d.get("phases", []):
                    pid = f"phase:{key}:{phase['id']}"
                    self.link(pid, nid, "etapa da obra", "phase")
                    if previous:
                        self.link(previous, pid, "próxima etapa", "sequence")
                    previous = pid
            elif kind == "phase":
                self.inputs(nid, d.get("items", {}), "contribuir")
            elif kind in {"wish", "routine"}:
                if d.get("item"):
                    self.inputs(nid, {d["item"]: d.get("qty", 1)}, "dar ao Tiro")
                if d.get("goal"):
                    self.goal(nid, d["goal"])
                if d.get("guarantee_quest"):
                    self.link(self.ref("quest", d["guarantee_quest"]), nid, "garante este desejo", "unlock")
            elif kind == "walk":
                loot = d.get("loot", {})
                for row in loot.get("table", []):
                    self.rewards(nid, row, f"sorteio · peso {row.get('weight', '?')}", "random")
                self.rewards(nid, loot.get("first", {}), "primeira volta", "reward")
                rare = loot.get("rare", {})
                self.rewards(nid, rare, "raro (condicional)", "random")
                for field in ["consolation", "duplicate"]:
                    self.rewards(nid, rare.get(field, {}), field, "random")
                guarantees = loot.get("guarantee", [])
                if isinstance(guarantees, dict):
                    guarantees = [guarantees]
                for guarantee in guarantees:
                    if guarantee.get("item"):
                        condition = f"ter {guarantee['until_owned']}" if guarantee.get("until_owned") else f"concluir {guarantee['until_claimed']}" if guarantee.get("until_claimed") else "a condição cadastrada"
                        self.link(nid, self.ref("item", guarantee["item"]), f"garante até {condition} ×{guarantee.get('count', 1)}", "reward")
            elif kind == "find":
                if key in self.docs.get("worlds", {}):
                    self.link(f"world:{key}", nid, "cavar neste mundo", "location")
                for row in d.get("guaranteed", []):
                    self.rewards(nid, row, "achado garantido", "reward")
                for row in d.get("table", []):
                    self.rewards(nid, row, f"sorteio · peso {row.get('weight', '?')}", "random")
                for item in d.get("items", []):
                    self.link(self.ref("item", item), nid, "completa conjunto", "goal")
                qf = d.get("quest_find", {})
                if qf:
                    self.link(self.ref("quest", qf["quest"]), nid, "garantia durante missão", "requirement")
                    self.link(nid, self.ref("item", qf["item"]), "item da missão (condicional)", "reward")
            elif kind == "friend":
                self.inputs(nid, {d["likes"]: 1} if d.get("likes") else {}, "petisco favorito")
                for i, reward in enumerate(d.get("heart_rewards", []), 1):
                    self.rewards(nid, reward, f"prêmio de amizade {i}")
                gift = d.get("visit_gift", {})
                self.rewards(nid, gift, "visita")
                for row in gift.get("loot", []):
                    self.rewards(nid, row, "presente sorteado", "random")
            elif kind == "reward":
                self.rewards(nid, d)
            elif kind == "npc" and d.get("follow"):
                self.link(self.ref("npc", d["follow"]), nid, "acompanha este personagem", "location")

        for key, recipe in self.docs.get("recipes", {}).items():
            node = f"recipe:{key}"
            output = recipe.get("output", "")
            if output:
                self.link(node, self.counter(f"produce:{output}"), "ao recolher o lote", "counter", inferred=True)
            for counter in ["production_jobs"] + (["sew"] if recipe.get("output_collection") else []):
                self.link(node, self.counter(counter), "ao recolher o lote", "counter", inferred=True)
        for key, crop in self.docs.get("crops", {}).items():
            for counter in ["harvest", f"harvest:{key}"]:
                self.link(f"crop:{key}", self.counter(counter), "ao colher", "counter", inferred=True)
        for key, order in self.p.get("orders", {}).items():
            channel = "contracts" if order.get("channel") == "contracts" else "orders"
            self.link(f"order:{key}", self.counter(channel), "ao entregar", "counter", inferred=True)
            self.link(f"order:{key}", self.counter(f"order:{key}"), "ao entregar", "counter", inferred=True)
        for key in self.docs.get("walks", {}).get("walks", {}):
            self.link(f"walk:{key}", self.counter("walk"), "ao voltar", "counter", inferred=True)
            if legendary:
                self.link(f"walk:{key}", "reward:legendary", "sorteio independente (condicional)", "random")
        for key, wish in self.docs.get("wishes", {}).get("wishes", {}).items():
            self.link("rule:wishes", f"wish:{key}", "sorteio, vagas e recarga", "requirement")
            if wish.get("item"):
                self.link(f"wish:{key}", self.counter(f"wish_item:{wish['item']}"), "ao atender", "counter", inferred=True)

        for key, route in self.p.get("activities", {}).items():
            for world, wd in self.docs.get("worlds", {}).items():
                for place, pd in wd.get("places", {}).items():
                    if pd.get("panel") == f"nature:{route.get('place', '')}":
                        self.link(f"place:{world}:{place}", f"activity:{key}", "rota neste local", "location")
        for key, recipe in self.docs.get("recipes", {}).items():
            skill = recipe.get("skill", "adventure" if recipe.get("output_collection") else "cooking")
            xp = recipe.get("skill_xp", 20 if recipe.get("output_collection") else 10)
            self.link(f"recipe:{key}", self.ref("skill", skill), f"XP base +{xp}", "reward", inferred=True)
        for key, crop in self.docs.get("crops", {}).items():
            self.link("world:farm", f"crop:{key}", "plantar no sítio", "location", inferred=True)
            self.link(f"crop:{key}", self.ref("skill", crop.get("skill", "agriculture")), f"XP base +{crop.get('skill_xp', 10)}", "reward", inferred=True)
        if "rule:config:start" in self.nodes:
            start = self.config.get("start", {})
            self.rewards("rule:config:start", {"items": start.get("inventory", {}), "coins": start.get("coins", 0)}, "início do jogo")

        # Sequências são implícitas no motor; não estão em requirements dos JSONs.
        groups = defaultdict(list)
        for key, quest in self.docs.get("quests", {}).items():
            if quest.get("kind") in {"main", "line"}:
                group = "main" if quest["kind"] == "main" else quest["line"]
                groups[group].append((key, quest))
        for group, quests in groups.items():
            quests.sort(key=lambda kv: (kv[1].get("chapter", 0) if group == "main" else 0, kv[1].get("order", 0)))
            for (previous, _), (current, _) in zip(quests, quests[1:]):
                self.link(f"quest:{previous}", f"quest:{current}", "próximo passo da história" if group == "main" else f"próxima da linha {group}", "sequence", inferred=True)
        chapters = self.p.get("chapters", [])
        for i in range(2, len(chapters) + 1):
            for key, q in self.docs.get("quests", {}).items():
                if q.get("kind") == "main" and q.get("chapter") == i - 1:
                    self.link(f"quest:{key}", f"chapter:{i}", "concluir para avançar capítulo", "sequence", inferred=True)
        degree = Counter()
        for edge in self.edges:
            degree[edge["source"]] += 1
            degree[edge["target"]] += 1
        for node in self.nodes.values():
            node["degree"] = degree[node["id"]]
        return {
            "nodes": list(self.nodes.values()), "edges": self.edges, "kinds": KINDS,
            "revision": self.revision, "sources": self.sources, "warnings": self.warnings,
            "loaded_at": datetime.now(timezone.utc).isoformat(),
            "scope": "Conteúdo atual em game/data; não é progresso de um save nem simulação. Relações condicionais não representam disponibilidade imediata.",
        }


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = unquote(urlsplit(self.path).path)
        if path == "/api/pacing":
            try:
                query = parse_qs(urlsplit(self.path).query)
                options = {key: query.get(key, [""])[0] for key in ["batch", "profile", "until"]}
                graph = ContentGraph(self.server.data_dir).build()
                self.send_json(200, build_pacing(graph, self.server.data_dir,
                    plan_path=getattr(self.server, "pacing_plan_path", PLAN),
                    evidence_dir=getattr(self.server, "pacing_evidence_dir", EVIDENCE), **options))
            except (ValueError, OSError, KeyError, TypeError) as exc:
                self.send_json(503, {"error": f"Não foi possível carregar o planejamento: {exc}"})
            return
        if path == "/api/graph":
            try:
                payload = ContentGraph(self.server.data_dir).build()
                self.send_json(200, payload)
            except (ValueError, OSError, KeyError, TypeError) as exc:
                self.send_json(503, {"error": f"Não foi possível ler o conteúdo atual: {exc}"})
            return
        if path == "/api/revision":
            try:
                graph = ContentGraph(self.server.data_dir)
                self.send_json(200, {"revision": graph.revision})
            except (ValueError, OSError) as exc:
                self.send_json(503, {"error": str(exc)})
            return
        if path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
            return
        # Somente a interface, os JSONs ativos e as imagens podem ser servidos.
        if path.startswith("/game/assets/"):
            base = ROOT / "game/assets"
            file = (ROOT / path.lstrip("/")).resolve()
            allowed = file.suffix.lower() in {".png", ".svg", ".webp", ".jpg"}
        elif path.startswith("/game/data/"):
            base = DATA
            file = (ROOT / path.lstrip("/")).resolve()
            allowed = file.suffix == ".json" and file.parent == DATA
        else:
            base = UI
            file = (UI / (path.lstrip("/") or "index.html")).resolve()
            allowed = file.suffix in {".html", ".css", ".js"}
        if not allowed or not file.is_relative_to(base.resolve()) or not file.is_file():
            self.send_error(404)
            return
        data = file.read_bytes()
        self.send_response(200)
        mime = mimetypes.guess_type(file.name)[0] or "application/octet-stream"
        self.send_header("Content-Type", mime + ("; charset=utf-8" if file.suffix in {".html", ".css", ".js", ".json"} else ""))
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, status, value):
        data = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        if urlsplit(self.path).path != "/api/pacing/plan":
            self.send_error(404)
            return
        origin = self.headers.get("Origin")
        if origin and origin != f"http://{self.headers.get('Host')}":
            self.send_json(403, {"error": "Origem inválida"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 65536 or self.headers.get_content_type() != "application/json":
                raise ValueError("Envie um planejamento JSON de até 64 KB")
            payload = json.loads(self.rfile.read(length))
            self.send_json(200, {"plan": save_plan(payload, getattr(self.server, "pacing_plan_path", PLAN))})
        except (ValueError, TypeError, OSError) as exc:
            self.send_json(400, {"error": str(exc)})

    def log_message(self, fmt, *args):
        if args and str(args[1] if len(args) > 1 else "") not in {"200", "204"}:
            super().log_message(fmt, *args)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--open", action="store_true", help="Abrir painel no navegador")
    parser.add_argument("--check", action="store_true", help="Validar extração e imprimir contagens")
    args = parser.parse_args()
    if args.check:
        graph = ContentGraph().build()
        print(json.dumps({"nodes": len(graph["nodes"]), "edges": len(graph["edges"]), "kinds": dict(Counter(n["kind"] for n in graph["nodes"])), "warnings": graph["warnings"]}, ensure_ascii=False, indent=2))
        return
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    server.data_dir = DATA
    url = f"http://127.0.0.1:{server.server_port}/"
    print(f"Mapa do Tiro: {url}\nLendo game/data automaticamente. Ctrl+C para encerrar.", flush=True)
    if args.open:
        threading.Timer(0.3, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
