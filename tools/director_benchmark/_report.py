"""Descriptive metrics and escaped Markdown; no policy or model decisions."""
from collections import Counter
import html
import json
import math
import statistics


def _ratio(numerator, denominator):
    return {"numerator": numerator, "denominator": denominator,
            "rate": numerator / denominator if denominator else None}


def _latencies(attempts):
    values = sorted(a["latency_ms"] for a in attempts if a.get("latency_ms") is not None)
    return {"n": len(values), "min_ms": min(values) if values else None,
            "median_ms": statistics.median(values) if values else None,
            "max_ms": max(values) if values else None,
            "p95_ms": values[math.ceil(.95 * len(values)) - 1] if values else None,
            "p95_method": "nearest-rank; exploratory with n=24"}


def summarize(attempts):
    legal = [a for a in attempts if a["legal"]]
    evaluable = [a for a in attempts if a["action_id"] is not None]
    hits = sum(a["oracle_hit"] for a in legal)
    cases = dict.fromkeys(a["case_id"] for a in attempts)
    within = {}
    for case in cases:
        decisions = Counter(a["action_id"] for a in legal if a["case_id"] == case)
        count = sum(decisions.values())
        within[case] = {"legal_responses": count, "distinct_ids": len(decisions),
                        "action_counts": dict(decisions),
                        "modal_agreement": _ratio(max(decisions.values(), default=0), count)}
    plans = Counter(a["action_id"] for a in legal)
    non_pause = [a for a in legal if a["action_id"] != "pause"]
    spawns = [spawn for a in non_pause for spawn in a["plan"]["spawns"]]
    status_counts = dict(Counter(a["status"] for a in attempts))
    return {"total_attempts": len(attempts), "legal_count": len(legal),
            "evaluable_count": len(evaluable), "oracle_hit_count": hits,
            "status_counts": status_counts,
            "legal_over_attempts": _ratio(len(legal), len(attempts)),
            "legal_over_evaluable": _ratio(len(legal), len(evaluable)),
            "oracle_over_attempts": _ratio(hits, len(attempts)),
            "oracle_over_legal": _ratio(hits, len(legal)),
            "baseline_agreement_descriptive": _ratio(sum(a["agrees_with_baseline"] for a in legal), len(legal)),
            "within_case": within,
            "between_cases": {"total_cases": len(cases),
                              "cases_with_legal_response": sum(v["legal_responses"] > 0 for v in within.values()),
                              "distinct_legal_plans": len(plans)},
            "plan_distribution": {"counts": dict(plans), "denominator_legal_decisions": len(legal)},
            "spawn_distribution": {"roles": dict(Counter(s["role"] for s in spawns)),
                                   "lanes": {str(k): v for k, v in Counter(s["lane"] for s in spawns).items()},
                                   "denominator_spawns": len(spawns), "denominator_non_pause_plans": len(non_pause),
                                   "role_sequence": "AAR is fixed; role counts do not measure policy diversity"},
            "latency_all_attempts": _latencies(attempts),
            "latency_by_status": {status: _latencies([a for a in attempts if a["status"] == status])
                                  for status in status_counts}}


def _cell(value):
    return html.escape(str(value), quote=True).replace("|", "&#124;").replace("\n", "<br>")


def _number(value):
    return "no disponible" if value is None else f"{value:.3f}"


def _plan(plan):
    if plan is None:
        return "sin plan legal"
    if not plan["spawns"]:
        return "pausa (coste 0)"
    spawns = ", ".join(f'{s["role"]}{s["lane"]}@{plan["initial_delay_s"] + i * plan["cadence_s"]:g}s'
                       for i, s in enumerate(plan["spawns"]))
    return f'{spawns}; coste {plan["cost_slots"]}'


def markdown(report):
    summary = report["summary"]
    latency = summary["latency_all_attempts"]
    warmup = report["warmup"]
    lines = [f'# Benchmark de directores — {_cell(report["metadata"]["backend"])}', "",
             "Comparación exploratoria sobre ocho estados sintéticos y tres semillas solicitadas (42/43/44).",
             "Los oráculos suaves se evalúan después de decidir; acertarlos no prueba estrategia óptima ni victoria.", "",
             f'Intentos: {summary["total_attempts"]}. Legales: {summary["legal_count"]}/24; '
             f'evaluables: {summary["evaluable_count"]}; legales/evaluables: '
             f'{summary["legal_count"]}/{summary["evaluable_count"]}.',
             f'Aciertos del oráculo: {summary["oracle_hit_count"]}/24 y '
             f'{summary["oracle_hit_count"]}/{summary["legal_count"]} legales.',
             f'Fallos y éxitos por status: {_cell(json.dumps(summary["status_counts"], ensure_ascii=False))}.', "",
             "Latencia wall de decisión/roundtrip completo, en ms (calentamiento excluido):",
             f'n={latency["n"]}; mínimo={_number(latency["min_ms"])}; '
             f'mediana={_number(latency["median_ms"])}; máximo={_number(latency["max_ms"])}; '
             f'p95={_number(latency["p95_ms"])} (nearest-rank, exploratorio con n=24).',
             "Los fallos y timeouts también tienen latencia y se desglosan por status más abajo.",
             "Arranque frío: not_measured. CPU, memoria RSS/GPU y FPS: not_measured.", "",
             f'Calentamiento separado: {_cell(warmup["case_id"])} / seed solicitada 42 / '
             f'{_cell(warmup["status"])} / {_cell(warmup["action_id"])} / {_number(warmup["latency_ms"])} ms.', "",
             "| Orden | Caso | Seed solicitada | ID y plan sintético (carriles 0–4) | Status / razón | Legal | Oráculo | ms |",
             "|---:|---|---:|---|---|---|---|---:|"]
    for attempt in report["attempts"]:
        reason = attempt["error"] or attempt["validation_reason"]
        lines.append("| " + " | ".join(_cell(v) for v in [attempt["order"], attempt["case_id"],
                     attempt["seed_requested"], f'{attempt["action_id"]}: {_plan(attempt["plan"])}',
                     f'{attempt["status"]} / {reason}', attempt["legal"], attempt["oracle_hit"],
                     _number(attempt["latency_ms"])]) + " |")
    lines += ["", "Acuerdo dentro de cada caso (≤3 respuestas legales, semillas distintas solicitadas):", "",
              "| Caso | IDs distintos | Moda / respuestas legales |", "|---|---:|---:|"]
    for case, data in summary["within_case"].items():
        agreement = data["modal_agreement"]
        lines.append(f'| {_cell(case)} | {data["distinct_ids"]} | {agreement["numerator"]}/{agreement["denominator"]} |')
    lines += ["", "Diversidad entre casos y distribución descriptiva (denominadores explícitos):", "",
              "<pre>" + html.escape(json.dumps({key: summary[key] for key in (
                  "between_cases", "plan_distribution", "spawn_distribution", "baseline_agreement_descriptive",
                  "latency_by_status")}, indent=2, ensure_ascii=False)) + "</pre>", "",
              "El acuerdo con baseline es descriptivo; no define calidad. AAR es fijo, no diversidad aprendida.",
              "Semillas, parámetros y modo estructurado de Gemma son solicitados, no garantías de reproducibilidad.",
              "El hash del archivo y el alias no atestiguan los bytes cargados por el runtime.", "",
              "Procedencia y parámetros:", "<pre>" + html.escape(json.dumps(report["metadata"], indent=2, ensure_ascii=False)) + "</pre>", "",
              "Respuestas raw y errores escapados como datos (incluido calentamiento):"]
    for attempt in [warmup, *report["attempts"]]:
        lines += [f'<details><summary>{_cell(attempt["case_id"])} / {_cell(attempt["seed_requested"])} / '
                  f'{_cell(attempt["status"])}</summary>',
                  "<pre>" + html.escape(json.dumps({k: attempt[k] for k in ("raw_text", "error", "acceptable_actions")},
                                                   ensure_ascii=False, indent=2)) + "</pre></details>"]
    lines += ["", "No se infiere diversión, robustez, probabilidad de ganar, GPU/FPS o viabilidad S24.", ""]
    return "\n".join(lines)
