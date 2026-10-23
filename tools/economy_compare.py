"""Relatório local da simulação de economia (etapa 01 do plano docs/plans/economia).

Lê os `summary.json` gerados por tools/economy_simulate.ps1 e escreve:
  * report.md   tabelas por perfil (mín/mediana/máx), marcos, critérios de experiência, fluxo de moedas,
                esperas, bloqueios (jogo x política) e saúde das guardas;
  * charts/*.svg gráficos simples (missões x tempo ativo, moedas x dia, esperas por motivo);
  * report.md inclui, com --base, diferenças de mediana entre revisões (mesma agenda/sementes).

IMPORTANTE: tudo aqui é SIMULADO (GameState real + agente idealizado). Não é o mesmo rótulo das
medidas teóricas do auditor estático (tools/economy_audit.py → BASELINE.md).

Uso:
  py -X utf8 -I tools/economy_compare.py --in build/economy/etapa_01 [--out build/economy/etapa_01/relatorio] [--base outra_pasta]
Somente biblioteca padrão.
"""
from __future__ import annotations

import argparse
import json
import statistics
import sys
from pathlib import Path

MILESTONE_LABELS = [
    ("first_harvest", "Primeira colheita"),
    ("first_wish", "Primeiro desejo cumprido"),
    ("first_find", "Primeiro achado"),
    ("first_walk", "Primeiro passeio"),
    ("stove", "Fogão comprado"),
    ("village_open", "Vila aberta"),
    ("workbench", "Bancada"),
    ("stall", "Banca"),
    ("chapter_9_done", "Fim do capítulo 9"),
    ("all_depots", "Todos os depósitos"),
    ("campaign_all_quests", "Todas as missões"),
]
# Critérios de experiência da seção E de 04_SIMULACAO_E_ACEITE.md (minutos ATIVOS).
EXPERIENCE = [
    ("first_harvest", "Primeira colheita ≤ 4 min ativos", 4.0),
    ("first_wish", "Primeiro desejo ≤ 7 min", 7.0),
    ("first_find", "Primeiro achado ≤ 10 min", 10.0),
    ("first_walk", "Primeiro passeio ≤ 60 min", 60.0),
]
# Alvos da seção E do plano Tiro (02_FASES_E_PILARES): dia de jogo em que cada crescimento acontece (mín, máx).
GROWTH_TARGETS = [
    ("puppy", "Filhotinho", 0.0, 30 / 1440, "primeira sessão (≤30 min)"),
    ("teething", "Dentinhos", 1.0, 3.0, "dia 1–3"),
    ("explorer", "Aventureiro", 5.0, 8.0, "dia 5–8"),
    ("young", "Mocinho", 10.0, 14.0, "dia 10–14"),
    ("adult", "Azul e Dourado", 18.0, 24.0, "dia 18–24"),
]
COLORS = ["#2b6cb0", "#c05621", "#2f855a", "#805ad5", "#b83280", "#718096"]


def load_runs(folder: Path) -> list[dict]:
    runs = []
    for path in sorted(folder.glob("*/summary.json")):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, ValueError):
            continue
        if str(path.parent.name).startswith("_"):
            continue  # pastas de teste
        data["_dir"] = path.parent.name
        runs.append(data)
    return runs


def spread(values: list[float], digits: int = 1) -> str:
    if not values:
        return "—"
    fmt = "%%.%df / %%.%df / %%.%df" % (digits, digits, digits)
    return fmt % (min(values), statistics.median(values), max(values))


def med(values: list[float]):
    return statistics.median(values) if values else None


def by_profile(runs: list[dict]) -> dict[str, list[dict]]:
    groups: dict[str, list[dict]] = {}
    for run in runs:
        name = str(run.get("profile"))
        if run.get("params", {}).get("rare") == "worst":
            name += " (raro zero)"
        groups.setdefault(name, []).append(run)
    return dict(sorted(groups.items()))


def milestone_values(runs: list[dict], key: str, field: str) -> list[float]:
    return [float(r["milestones"][key][field]) for r in runs if key in r.get("milestones", {})]


def table(headers: list[str], rows: list[list[str]]) -> str:
    lines = ["| " + " | ".join(headers) + " |", "|" + "|".join("---" for _ in headers) + "|"]
    for row in rows:
        lines.append("| " + " | ".join(row) + " |")
    return "\n".join(lines)


def section_overview(groups: dict[str, list[dict]]) -> str:
    rows = []
    for name, runs in groups.items():
        status: dict[str, int] = {}
        for r in runs:
            status[r["status"]] = status.get(r["status"], 0) + 1
        rows.append([
            name, str(len(runs)), ", ".join(f"{k}×{v}" for k, v in sorted(status.items())),
            spread([r["end"]["days"] for r in runs]), spread([r["time"]["active_min"] for r in runs]),
            spread([r["end"]["quests"] for r in runs]), spread([r["end"]["upgrades"] for r in runs]),
            str(sum(int(r["guards"]["violations"]) for r in runs)),
        ])
    return table(["Perfil", "Sementes", "Estado final", "Dias (mín/med/máx)", "Min ativos", "Missões /81", "Melhorias /48", "Violações"], rows)


def section_milestones(groups: dict[str, list[dict]]) -> str:
    out = []
    for field, title in (("active_min", "Minutos ATIVOS até o marco (mín/mediana/máx)"), ("hours", "Horas de calendário até o marco")):
        rows = []
        for key, label in MILESTONE_LABELS:
            row = [label]
            for name, runs in groups.items():
                values = milestone_values(runs, key, field)
                row.append(spread(values) + (f" ({len(values)}/{len(runs)})" if len(values) != len(runs) else ""))
            rows.append(row)
        out.append(f"**{title}**\n\n" + table(["Marco"] + list(groups), rows))
    out.append("Marcos inexistentes na economia atual (primeiro projeto, festa): não medidos nesta linha de base.")
    return "\n\n".join(out)


def section_experience(groups: dict[str, list[dict]]) -> str:
    rows = []
    for key, label, limit in EXPERIENCE:
        row = [label]
        for name, runs in groups.items():
            values = milestone_values(runs, key, "active_min")
            if not values:
                row.append("sem dado")
            else:
                worst = max(values)
                row.append(("dentro" if worst <= limit else "FORA") + f" (pior {worst:.1f})")
        rows.append(row)
    idle_row = ["Ociosidade da 1ª sessão ≤ 25%"]
    for name, runs in groups.items():
        values = [float(r["time"]["first_session_idle_pct"]) for r in runs]
        idle_row.append(("dentro" if max(values) <= 25.0 else "FORA") + f" (pior {max(values):.1f}%)")
    rows.append(idle_row)
    ch9_row = ["Fim do cap. 9 em 3–6 h ativas (alvo)"]
    for name, runs in groups.items():
        values = milestone_values(runs, "chapter_9_done", "active_min")
        ch9_row.append(f"{statistics.median(values) / 60.0:.1f} h (mediana)" if values else "não atingido")
    rows.append(ch9_row)
    note = ("\nAgente idealizado (04, seção B): tempos mostram o que a economia permite, **não** a experiência de uma pessoa. "
            "Calibrar com toque manual na etapa 23.")
    return table(["Critério (04, seção E)"] + list(groups), rows) + note


def section_growth(groups: dict[str, list[dict]]) -> str:
    """Tabela fase × dia contra os alvos; FORA quando passa de 2× o limite ou fica abaixo da metade do mínimo."""
    rows = []
    for key, label, low, high, target in GROWTH_TARGETS:
        row = [label, target]
        for name, runs in groups.items():
            values = [float(r["growth_days"][key]["day"]) for r in runs if key in r.get("growth_days", {})]
            if not values:
                row.append("não atingiu")
                continue
            worst = max(values)
            best = min(values)
            verdict = "dentro" if low <= best and worst <= high else ("FORA >2×" if worst > 2 * high or best < low / 2 and low > 0 else "perto")
            row.append(f"{spread(values, 2)} d ({verdict})")
        rows.append(row)
    final = ["Momentos totais no fim (Pelagem/Esperteza/Coragem)", ""]
    silk = ["Pelagem de seda no fim (0–3)", ""]
    for name, runs in groups.items():
        parts = []
        for r in runs:
            levels = r["end"].get("pillars", {})
            parts.append("/".join(str(levels.get(k, {}).get("total", levels.get(k, {}).get("level", "?"))) for k in ("coat", "smart", "brave")))
        final.append(" · ".join(parts) if parts else "—")
        silk.append(" · ".join(str(r["end"].get("silk", 0)) for r in runs))
    rows += [final, silk]
    chapters = []
    for chapter in range(1, 13):
        row = [f"Moedas ao fechar o cap. {chapter}", "risco do meio do jogo (03 G)" if 5 <= chapter <= 9 else ""]
        for name, runs in groups.items():
            values = [float(r["chapter_coins"][str(chapter)]["coins"]) for r in runs if str(chapter) in r.get("chapter_coins", {})]
            row.append(spread(values, 0) if values else "—")
        chapters.append(row)
    rows += chapters
    return table(["Item", "Alvo"] + list(groups), rows) + "\n\nAlvos iniciais do plano, não resultado de playtest; agente idealizado."


def section_coins(groups: dict[str, list[dict]]) -> str:
    rows = []
    for name, runs in groups.items():
        recurring = []
        unique = []
        spent = []
        dominant: dict[str, int] = {}
        for r in runs:
            flow = r.get("coin_flow", {})
            rec = sum(v for k, v in flow.items() if k.startswith("recurring:"))
            uni = sum(v for k, v in flow.items() if k.startswith("unique:"))
            recurring.append(rec)
            unique.append(uni)
            spent.append(-sum(v for k, v in flow.items() if k.startswith("spend:")))
            top = max(((k, v) for k, v in flow.items() if k.startswith("recurring:")), key=lambda kv: kv[1], default=("—", 0))
            dominant[top[0]] = dominant.get(top[0], 0) + 1
        share = [rec / (rec + uni) * 100.0 for rec, uni in zip(recurring, unique) if rec + uni > 0]
        rows.append([name, spread(recurring, 0), spread(unique, 0), "%.0f%%" % med(share) if share else "—", spread(spent, 0),
                     ", ".join(f"{k.replace('recurring:', '')}×{v}" for k, v in sorted(dominant.items(), key=lambda kv: -kv[1]))])
    return table(["Perfil", "Moedas recorrentes", "Moedas únicas (prêmios)", "% recorrente (med)", "Gasto em compras", "Fonte recorrente dominante"], rows)


def section_waits(groups: dict[str, list[dict]]) -> str:
    rows = []
    for name, runs in groups.items():
        totals: dict[str, float] = {}
        active = sum(float(r["time"]["active_min"]) for r in runs)
        for r in runs:
            for k, v in r.get("waits_by_reason", {}).items():
                totals[k] = totals.get(k, 0.0) + float(v)
        wait_total = sum(totals.values()) / 60.0
        top = ", ".join(f"{k} {v / 60.0:.1f} min" for k, v in sorted(totals.items(), key=lambda kv: -kv[1])[:5]) or "—"
        nav = sum(float(r["time"]["nav_min"]) for r in runs)
        no_action = [float(r["time"].get("unused_no_action_min", 0.0)) for r in runs]
        with_actions = [float(r["time"].get("left_with_actions_min", 0.0)) for r in runs]
        gap = [float(r["time"].get("longest_gap_active_min", 0.0)) for r in runs]
        rows.append([name, f"{active:.0f}", f"{wait_total:.1f}", f"{nav:.0f}", spread(no_action), spread(with_actions), spread(gap), top])
    return table(["Perfil", "Min ativos (soma)", "Esperas forçadas dentro da sessão (min)", "Navegação (min)",
                  "Sessão fechada sem ação possível (min, mín/med/máx)", "Sessão fechada com ações disponíveis (min)", "Maior intervalo sem missão (min ativos)", "Maiores motivos de espera"], rows)


def section_blocks(groups: dict[str, list[dict]]) -> str:
    out = []
    for name, runs in groups.items():
        game: dict[str, int] = {}
        policy: dict[str, int] = {}
        for r in runs:
            for k, v in r.get("blocks", {}).items():
                if k.startswith("jogo:"):
                    game[k] = game.get(k, 0) + int(v)
                elif k.startswith("politica:"):
                    policy[k] = policy.get(k, 0) + int(v)
        stalled = [r for r in runs if r["status"] == "stalled"]
        lines = [f"**{name}** — bloqueios do jogo: " + (", ".join(f"{k}×{v}" for k, v in sorted(game.items(), key=lambda kv: -kv[1])[:6]) or "nenhum")
                 + "; falhas de política: " + (", ".join(f"{k}×{v}" for k, v in sorted(policy.items(), key=lambda kv: -kv[1])[:6]) or "nenhuma")]
        for r in stalled:
            last = (r.get("last_sessions") or [{}])[-1]
            lines.append(f"  - seed {r['seed']} parou em {r['end']['quests']}/{r['end']['quests_total']} missões; meta `{last.get('focus', '?')}`, motivo `{last.get('focus_why', '?')}`; faltam {r.get('unclaimed')}")
        out.append("\n".join(lines))
    out.append("Classificação: `jogo:*` = requisito/limite do jogo encontrado na busca (inclui sorte e espaço); `politica:*` = o agente não achou um caminho que o jogo permite. Ocorrências transitórias em rotas alternativas não provam um bloqueio da campanha; conferir estado final, meta e ledger da execução interrompida.")
    return "\n\n".join(out)


def section_items(groups: dict[str, list[dict]]) -> str:
    rows = []
    for name, runs in groups.items():
        made = {}
        for r in runs:
            for k, v in r.get("item_flow", {}).items():
                if k.startswith("made:"):
                    made[k[5:]] = made.get(k[5:], 0) + int(v)
        top = ", ".join(f"{k} {v}" for k, v in sorted(made.items(), key=lambda kv: -kv[1])[:8])
        pend = []
        for r in runs:
            for p in r.get("pending_at_close", []):
                pend.append(p["plots"] + p["stations"] + p["nature"] + p["walk"])
        outside = [p["outside_depots"] for r in runs for p in r.get("pending_at_close", [])]
        rows.append([name, top or "—", spread([float(x) for x in pend]), spread([float(x) for x in outside])])
    return table(["Perfil", "Itens mais produzidos (soma das sementes)", "Prontos esperando ao fechar (mín/med/máx)", "Itens fora de depósito limitado ao fechar"], rows)


def section_actions(groups: dict[str, list[dict]]) -> str:
    rows = []
    for name, runs in groups.items():
        why: dict[str, int] = {}
        total = 0
        for r in runs:
            for k, v in r.get("actions_by_why", {}).items():
                why[k] = why.get(k, 0) + int(v)
                total += int(v)
        space = why.get("space", 0)
        rows.append([name, str(total), "%.1f%%" % (space / total * 100.0) if total else "—",
                     ", ".join(f"{k} {v * 100 // max(total, 1)}%" for k, v in sorted(why.items(), key=lambda kv: -kv[1])[:6])])
    return table(["Perfil", "Ações", "Ações só para liberar espaço", "Motivos das ações"], rows)


# --- Gráficos SVG simples ------------------------------------------------------------------------------

def svg_lines(title: str, x_label: str, y_label: str, series: dict[str, list[tuple[float, float]]], width: int = 640, height: int = 340) -> str:
    left, right, top, bottom = 56, 150, 36, 44
    xs = [p[0] for pts in series.values() for p in pts]
    ys = [p[1] for pts in series.values() for p in pts]
    if not xs:
        return ""
    x_max = max(xs) or 1.0
    y_max = max(ys) or 1.0

    def px(x: float) -> float:
        return left + (width - left - right) * x / x_max

    def py(y: float) -> float:
        return height - bottom - (height - top - bottom) * y / y_max

    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" font-family="sans-serif" font-size="11">',
             f'<rect width="{width}" height="{height}" fill="#ffffff"/>',
             f'<text x="{left}" y="20" font-size="13" font-weight="bold">{title}</text>',
             f'<line x1="{left}" y1="{height - bottom}" x2="{width - right}" y2="{height - bottom}" stroke="#444"/>',
             f'<line x1="{left}" y1="{top}" x2="{left}" y2="{height - bottom}" stroke="#444"/>']
    for i in range(5):
        value = y_max * i / 4
        y = py(value)
        parts.append(f'<line x1="{left}" y1="{y:.1f}" x2="{width - right}" y2="{y:.1f}" stroke="#ddd"/>')
        parts.append(f'<text x="{left - 6}" y="{y + 4:.1f}" text-anchor="end">{value:.0f}</text>')
        x_value = x_max * i / 4
        parts.append(f'<text x="{px(x_value):.1f}" y="{height - bottom + 16}" text-anchor="middle">{x_value:.0f}</text>')
    parts.append(f'<text x="{(left + width - right) / 2:.0f}" y="{height - 8}" text-anchor="middle">{x_label}</text>')
    parts.append(f'<text x="14" y="{(top + height - bottom) / 2:.0f}" transform="rotate(-90 14 {(top + height - bottom) / 2:.0f})" text-anchor="middle">{y_label}</text>')
    for index, (name, pts) in enumerate(series.items()):
        color = COLORS[index % len(COLORS)]
        coords = " ".join(f"{px(x):.1f},{py(y):.1f}" for x, y in pts)
        parts.append(f'<polyline fill="none" stroke="{color}" stroke-width="2" points="{coords}"/>')
        parts.append(f'<rect x="{width - right + 12}" y="{top + index * 18}" width="10" height="10" fill="{color}"/>')
        parts.append(f'<text x="{width - right + 28}" y="{top + index * 18 + 9}">{name}</text>')
    parts.append("</svg>")
    return "\n".join(parts)


def svg_bars(title: str, data: dict[str, float], unit: str, width: int = 640) -> str:
    items = sorted(data.items(), key=lambda kv: -kv[1])[:10]
    if not items:
        return ""
    height = 40 + 22 * len(items)
    maximum = max(v for _, v in items) or 1.0
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" font-family="sans-serif" font-size="11">',
             f'<rect width="{width}" height="{height}" fill="#ffffff"/>', f'<text x="10" y="20" font-size="13" font-weight="bold">{title}</text>']
    for i, (name, value) in enumerate(items):
        y = 34 + i * 22
        w = (width - 260) * value / maximum
        parts.append(f'<text x="10" y="{y + 12}">{name}</text>')
        parts.append(f'<rect x="170" y="{y}" width="{w:.1f}" height="14" fill="{COLORS[i % len(COLORS)]}"/>')
        parts.append(f'<text x="{176 + w:.1f}" y="{y + 12}">{value:.1f} {unit}</text>')
    parts.append("</svg>")
    return "\n".join(parts)


def curve_quests(run: dict) -> list[tuple[float, float]]:
    times = sorted(float(v["active_min"]) for v in run.get("quest_times", {}).values())
    return [(0.0, 0.0)] + [(t, float(i + 1)) for i, t in enumerate(times)]


def write_charts(groups: dict[str, list[dict]], folder: Path) -> list[str]:
    folder.mkdir(parents=True, exist_ok=True)
    written = []
    series = {}
    for name, runs in groups.items():
        # mediana das curvas: o tempo ativo mediano em que cada missão de índice i foi concluída
        curves = [curve_quests(r) for r in runs if r.get("quest_times")]
        if not curves:
            continue
        length = max(len(c) for c in curves)
        pts = []
        for i in range(length):
            values = [c[i][0] for c in curves if i < len(c)]
            pts.append((statistics.median(values), float(i)))
        series[name] = pts
    if series:
        (folder / "missoes_x_tempo_ativo.svg").write_text(svg_lines("Missões concluídas × minutos ativos (mediana das sementes)", "minutos ativos", "missões", series), encoding="utf-8")
        written.append("missoes_x_tempo_ativo.svg")
    coin_series = {}
    for name, runs in groups.items():
        longest = max(runs, key=lambda r: len(r.get("daily", [])))
        if longest.get("daily"):
            coin_series[name] = [(float(d["day"]), float(d["coins"])) for d in longest["daily"]]
    if coin_series:
        (folder / "moedas_x_dia.svg").write_text(svg_lines("Moedas em mãos ao fim de cada dia (semente mais longa)", "dia", "moedas", coin_series), encoding="utf-8")
        written.append("moedas_x_dia.svg")
    waits: dict[str, float] = {}
    for runs in groups.values():
        for r in runs:
            for k, v in r.get("waits_by_reason", {}).items():
                waits[k] = waits.get(k, 0.0) + float(v) / 60.0
    if waits:
        (folder / "esperas_por_motivo.svg").write_text(svg_bars("Esperas forçadas dentro das sessões (soma, min)", waits, "min"), encoding="utf-8")
        written.append("esperas_por_motivo.svg")
    return written


def compare(base: list[dict], head: list[dict]) -> str:
    groups_a, groups_b = by_profile(base), by_profile(head)
    rows = []
    for name in sorted(set(groups_a) & set(groups_b)):
        a, b = groups_a[name], groups_b[name]

        def delta(values_a: list[float], values_b: list[float]) -> str:
            ma, mb = med(values_a), med(values_b)
            if ma is None or mb is None:
                return "—"
            return f"{ma:.1f} → {mb:.1f} ({mb - ma:+.1f})"

        rows.append([name, delta([r["end"]["quests"] for r in a], [r["end"]["quests"] for r in b]),
                     delta([r["time"]["active_min"] for r in a], [r["time"]["active_min"] for r in b]),
                     delta(milestone_values(a, "chapter_9_done", "active_min"), milestone_values(b, "chapter_9_done", "active_min")),
                     delta([r["end"]["coins"] for r in a], [r["end"]["coins"] for r in b])])
    return table(["Perfil", "Missões", "Min ativos", "Fim do cap. 9 (min ativos)", "Moedas finais"], rows)


def build_report(runs: list[dict], out: Path, base_runs: list[dict] | None) -> str:
    groups = by_profile(runs)
    charts = write_charts(groups, out / "charts")
    violations = sum(int(r["guards"]["violations"]) for r in runs)
    header = f"""# Relatório da simulação de economia (SIMULADO)

> Medidas **simuladas**: GameState real com relógio injetado e um agente idealizado (tempo de toque 3 s + 2 s de navegação,
> arrasto 1 s por alvo extra). **Não** são as estimativas teóricas do auditor estático (`BASELINE.md`) nem a experiência de uma pessoa.
> Nenhuma economia foi ajustada para o agente passar. Execuções: {len(runs)} · violações de guarda: {violations}.

Pastas: {', '.join(r['_dir'] for r in runs)}
"""
    body = [header,
            "## 1. Visão geral\n\n" + section_overview(groups),
            "## 2. Marcos\n\n" + section_milestones(groups),
            "## 3. Critérios de experiência (indicativos)\n\n" + section_experience(groups),
            "## 4. Moedas: recorrente × prêmio único\n\n" + section_coins(groups),
            "## 4b. Fases do Tiro × dia\n\n" + section_growth(groups),
            "## 5. Tempo: esperas e navegação\n\n" + section_waits(groups),
            "## 6. Gargalos reais: bloqueio do jogo × falha de política\n\n" + section_blocks(groups),
            "## 7. Produção, prontos ao fechar e itens fora de depósito\n\n" + section_items(groups),
            "## 8. Em que o tempo ativo foi gasto\n\n" + section_actions(groups)]
    if charts:
        body.append("## 9. Gráficos\n\n" + "\n".join(f"![{c}](charts/{c})" for c in charts))
    if base_runs:
        body.append("## 10. Comparação com a revisão base\n\n" + compare(base_runs, runs))
    text = "\n\n".join(body) + "\n"
    out.mkdir(parents=True, exist_ok=True)
    (out / "report.md").write_text(text, encoding="utf-8")
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--in", dest="source", default="build/economy/etapa_01")
    parser.add_argument("--out", default=None)
    parser.add_argument("--base", default=None, help="pasta de outra revisão para comparar medianas")
    parser.add_argument("--tag", default="", help="só pastas que terminam com este rótulo (ex.: base)")
    args = parser.parse_args()
    source = Path(args.source)
    runs = load_runs(source)
    if args.tag:
        runs = [r for r in runs if r["_dir"].endswith((args.tag, args.tag + "_raro0"))]
    if not runs:
        print("Nenhum summary.json em", source, file=sys.stderr)
        return 2
    out = Path(args.out) if args.out else source / "relatorio"
    base_runs = load_runs(Path(args.base)) if args.base else None
    build_report(runs, out, base_runs)
    print(f"Relatório: {out / 'report.md'} ({len(runs)} execuções)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
