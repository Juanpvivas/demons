"""PC-only comparison of a deterministic policy and a verified local Gemma endpoint."""
import argparse
from collections import Counter
import copy
import hashlib
import json
import math
from pathlib import Path
import platform
import random
import socket
import sys
import tempfile
from time import perf_counter
import urllib.error
import urllib.request

from ._report import summarize, markdown

_LIMIT = 65536
_TIMEOUT = 30
_MODELS_URL = "http://127.0.0.1:9379/v1/models"
_CHAT_URL = "http://127.0.0.1:9379/v1/chat/completions"
_MODEL = "gemma4-e2b"
_MODEL_REPO = "litert-community/gemma-4-E2B-it-litert-lm"
_MODEL_REVISION = "1caa527c1e88b55f046fcd8d2b4265606680663d"
_MODEL_FILE = "gemma-4-E2B-it.litertlm"
_MODEL_SIZE = 2588147712
_MODEL_HASH = "181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c"
_TACTICAL_KEYS = ("terminal", "budget_slots", "lane_loads", "lane_caps", "defense",
                  "recent_death", "high_pressure", "previous_action_id", "allowed_actions")
_PARAMETERS = dict(model=_MODEL, reasoning_effort="none", max_completion_tokens=64,
                   temperature=0.2, top_p=0.95)
_SYSTEM = (
    'Select one action_id from the supplied catalog. Return only {"action_id":"ID"}, '
    'without explanation or extra fields. Respect allowed actions, budget and each lane capacity; '
    'projected load includes every spawn in that lane. Terminal permits only pause. '
    'Non-pause plans have exactly A,A,R at cadence 1 second. '
    'Prefer relief (pause or delayed plans) after a recent death or under high pressure. '
    'Otherwise avoid repeating a previous plan when a legal alternative exists, '
    'reduce projected load stacking and prefer weaker defense. Do not generate new plans.'
)
_SCHEMA = {"type": "json_schema", "json_schema": {"name": "director_decision", "schema": {
    "type": "object", "properties": {"action_id": {"type": "string"}},
    "required": ["action_id"], "additionalProperties": False}}}


def catalog() -> dict:
    plans = {"pause": dict(action_id="pause", cost_slots=0, initial_delay_s=0,
                           cadence_s=0, spawns=[])}
    lanes = {"left": [0, 1, 0], "center": [1, 2, 3], "right": [3, 4, 4],
             "spread": [0, 2, 4], "delayed_left": [0, 1, 0], "delayed_right": [3, 4, 4]}
    for action, rows in lanes.items():
        plans[action] = dict(action_id=action, cost_slots=3,
                             initial_delay_s=3 if action.startswith("delayed_") else 0,
                             cadence_s=1.0, spawns=[dict(role=r, lane=n) for r, n in zip("AAR", rows)])
    return plans


def scenarios() -> list[dict]:
    ids = list(catalog())
    definitions = [
        ("balanced", {}, ids),
        ("empty_lane", {"lane_loads": [2, 2, 2, 0, 0]}, ["right", "delayed_right"]),
        ("strong_defense", {"defense": [1, 1, .2, .2, .2]}, ["right", "delayed_right"]),
        ("recent_loss", {"recent_death": True, "lane_loads": [1, 0, 0, 0, 0]},
         ["pause", "delayed_left", "delayed_right"]),
        ("high_pressure", {"high_pressure": True, "lane_loads": [2] * 5, "lane_caps": [4] * 5},
         ["pause", "delayed_left", "delayed_right"]),
        ("previous_repeat", {"previous_action_id": "center"}, [i for i in ids if i != "center"]),
        ("insufficient_budget", {"budget_slots": 2}, ["pause"]),
        ("terminal", {"terminal": True}, ["pause"]),
    ]
    result = []
    for name, changes, acceptable in definitions:
        state = dict(case_id=name, terminal=False, budget_slots=3, lane_loads=[0] * 5,
                     lane_caps=[3] * 5, defense=[.5] * 5, recent_death=False,
                     high_pressure=False, previous_action_id=None, allowed_actions=ids.copy())
        state.update(changes)
        state["acceptable_actions"] = acceptable.copy()
        result.append(state)
    return result


def _canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)


def _hash(value):
    return hashlib.sha256(_canonical(value).encode("utf-8")).hexdigest()


def _reject_constant(value):
    raise ValueError("nonfinite JSON value")


def _pairs(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON key")
        result[key] = value
    return result


def _finite_float(value):
    number = float(value)
    if not math.isfinite(number):
        raise ValueError("nonfinite JSON number")
    return number


def _strict_json(raw):
    if not isinstance(raw, str) or len(raw.encode("utf-8")) > _LIMIT:
        raise ValueError("invalid JSON text size/type")
    return json.loads(raw, object_pairs_hook=_pairs, parse_constant=_reject_constant,
                      parse_float=_finite_float)


def _projection(snapshot):
    state = {key: copy.deepcopy(snapshot[key]) for key in _TACTICAL_KEYS}
    if any(type(state[k]) is not bool for k in ("terminal", "recent_death", "high_pressure")):
        raise ValueError("invalid tactical flags")
    if type(state["budget_slots"]) is not int or state["budget_slots"] < 0:
        raise ValueError("invalid budget")
    for key in ("lane_loads", "lane_caps"):
        if not isinstance(state[key], list) or len(state[key]) != 5 or any(
                type(n) is not int or n < 0 for n in state[key]):
            raise ValueError("invalid lane loads/capacities")
    defense = state["defense"]
    if not isinstance(defense, list) or len(defense) != 5 or any(
            type(n) not in (int, float) or not 0 <= n <= 1 or not math.isfinite(n) for n in defense):
        raise ValueError("invalid defense")
    if state["previous_action_id"] is not None and not isinstance(state["previous_action_id"], str):
        raise ValueError("invalid previous action")
    if not isinstance(state["allowed_actions"], list) or any(
            not isinstance(i, str) or i not in catalog() for i in state["allowed_actions"]):
        raise ValueError("invalid allowed actions")
    return state


def _plan_valid(action, plan):
    expected = catalog()[action]
    if not isinstance(plan, dict) or set(plan) != set(expected) or plan != expected:
        return False
    if type(plan["cost_slots"]) is not int:
        return False
    if any(type(plan[k]) not in (int, float) or not math.isfinite(plan[k])
           for k in ("initial_delay_s", "cadence_s")):
        return False
    return isinstance(plan["spawns"], list) and all(
        isinstance(spawn, dict) and set(spawn) == {"role", "lane"}
        and type(spawn["lane"]) is int for spawn in plan["spawns"])


def validate(raw_text, snapshot, plans) -> dict:
    try:
        value = _strict_json(raw_text)
    except (ValueError, TypeError, UnicodeError, RecursionError):
        return {"valid": False, "reason": "invalid_json"}
    reason = "ok"
    if not isinstance(value, dict) or set(value) != {"action_id"} or not isinstance(value["action_id"], str):
        reason = "invalid_shape"
    else:
        action = value["action_id"]
        try:
            state = _projection(snapshot)
        except (ValueError, KeyError, TypeError):
            return {"valid": False, "reason": "invalid_shape"}
        if not isinstance(plans, dict):
            reason = "invalid_plan"
        elif action not in catalog() or action not in plans:
            reason = "unknown_action"
        elif not _plan_valid(action, plans[action]):
            reason = "invalid_plan"
        elif action not in state["allowed_actions"]:
            reason = "not_allowed"
        elif state["terminal"] and action != "pause":
            reason = "terminal"
        elif plans[action]["cost_slots"] > state["budget_slots"]:
            reason = "over_budget"
        elif action != "pause":
            counts = Counter(s["lane"] for s in plans[action]["spawns"])
            if any(state["lane_loads"][n] + counts[n] > state["lane_caps"][n] for n in range(5)):
                reason = "over_capacity"
    return {"valid": reason == "ok", "reason": reason}


def baseline(snapshot, plans) -> str:
    state = _projection(snapshot)
    if state["terminal"] or state["budget_slots"] < 3 or state["recent_death"] or state["high_pressure"]:
        return "pause"
    candidates = []
    for action, plan in plans.items():
        if action == "pause" or not validate(_canonical({"action_id": action}), state, plans)["valid"]:
            continue
        loads = state["lane_loads"].copy()
        for spawn in plan["spawns"]:
            loads[spawn["lane"]] += 1
        score = (action == state["previous_action_id"], sum(n * n for n in loads),
                 sum(state["defense"][s["lane"]] for s in plan["spawns"]), action)
        candidates.append((score, action))
    return min(candidates)[1] if candidates else "pause"


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise urllib.error.HTTPError(req.full_url, code, "redirect denied", headers, fp)


def _request(url, payload=None, *, opener=None):
    """The only network seam; even injected doubles face URL/size/status guards."""
    if url not in (_MODELS_URL, _CHAT_URL):
        return {"status": "protocol_error", "error": "endpoint denied", "data": None}
    try:
        body = None if payload is None else _canonical(payload).encode("utf-8")
        if body is not None and len(body) > _LIMIT:
            raise ValueError("request exceeds 65536 bytes")
        request = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"},
                                         method="GET" if payload is None else "POST")
        transport = opener if opener is not None else urllib.request.build_opener(
            urllib.request.ProxyHandler({}), _NoRedirect())
        open_request = transport.open if hasattr(transport, "open") else transport
        with open_request(request, timeout=_TIMEOUT) as response:
            if response.geturl() != url:
                raise ValueError("redirect or unexpected response URL")
            if not 200 <= response.getcode() < 300:
                return {"status": "http_error", "error": f"HTTP {response.getcode()}", "data": None}
            raw = response.read(_LIMIT + 1)
            if len(raw) > _LIMIT:
                raise ValueError("response exceeds 65536 bytes")
            data = _strict_json(raw.decode("utf-8"))
        return {"status": "ok", "error": None, "data": data}
    except urllib.error.HTTPError as error:
        return {"status": "http_error", "error": f"HTTP {error.code}", "data": None}
    except (TimeoutError, socket.timeout):
        return {"status": "timeout", "error": "request timed out", "data": None}
    except urllib.error.URLError as error:
        status = "timeout" if isinstance(error.reason, (TimeoutError, socket.timeout)) else "transport_error"
        return {"status": status, "error": str(error.reason)[:240], "data": None}
    except OSError as error:
        return {"status": "transport_error", "error": str(error)[:240], "data": None}
    except (ValueError, TypeError, UnicodeError, RecursionError) as error:
        return {"status": "protocol_error", "error": str(error)[:240], "data": None}


def verify_identity(manifest_path, model_file, *, opener=None) -> dict:
    metadata = {}
    try:
        with Path(manifest_path).open(encoding="utf-8") as source:
            manifest_raw = source.read(_LIMIT + 1)
        manifest = _strict_json(manifest_raw)
        file = manifest["file"]
        if (manifest["repo"] != _MODEL_REPO or manifest["revision"] != _MODEL_REVISION
                or file["rfilename"] != _MODEL_FILE or type(file["size"]) is not int
                or file["size"] != _MODEL_SIZE or type(file["lfs"]["size"]) is not int
                or file["lfs"]["size"] != _MODEL_SIZE or file["lfs"]["sha256"] != _MODEL_HASH):
            raise ValueError("manifest does not match pinned Gemma 4 E2B identity")
        model = Path(model_file)
        if model.stat().st_size != _MODEL_SIZE:
            raise ValueError("model file size does not match pinned identity")
        digest = hashlib.sha256()
        with model.open("rb") as source:
            while chunk := source.read(1024 * 1024):
                digest.update(chunk)
        if digest.hexdigest() != _MODEL_HASH:
            raise ValueError("actual model file hash does not match pinned identity")
        metadata = {"repo": _MODEL_REPO, "revision": _MODEL_REVISION, "file": _MODEL_FILE,
                    "size_bytes": _MODEL_SIZE, "model_sha256": digest.hexdigest(),
                    "manifest_sha256": hashlib.sha256(manifest_raw.encode("utf-8")).hexdigest(),
                    "runtime_attestation": "not_available: file hash and alias do not attest loaded runtime bytes"}
        response = _request(_MODELS_URL, opener=opener)
        if response["status"] != "ok":
            raise ValueError(f'{response["status"]}: {response["error"]}')
        data = response["data"]
        if not isinstance(data, dict) or not isinstance(data.get("data"), list) or not any(
                isinstance(item, dict) and item.get("id") == _MODEL for item in data["data"]):
            raise ValueError("verified endpoint does not offer gemma4-e2b alias")
        metadata["alias"] = _MODEL
        return {"status": "ok", "error": None, "metadata": metadata}
    except (OSError, ValueError, TypeError, KeyError, UnicodeError, RecursionError) as error:
        return {"status": "identity_error", "error": str(error)[:240], "metadata": metadata}


def _messages(snapshot, plans):
    return [{"role": "system", "content": _SYSTEM},
            {"role": "user", "content": _canonical({"snapshot": _projection(snapshot), "catalog": plans})}]


def _classify(raw, snapshot, plans):
    check = validate(raw, snapshot, plans)
    action = None
    if check["reason"] not in ("invalid_json", "invalid_shape"):
        action = _strict_json(raw)["action_id"]
    status = "ok" if check["valid"] else (
        "invalid_output" if check["reason"] in ("invalid_json", "invalid_shape") else "illegal_action")
    return {"status": status, "action_id": action, "raw_text": raw,
            "error": None if check["valid"] else check["reason"]}


def gemma(snapshot, plans, seed, *, opener=None) -> dict:
    start = perf_counter()
    result = {"status": "protocol_error", "action_id": None, "raw_text": None, "error": None}
    try:
        if type(seed) is not int or seed not in (42, 43, 44):
            raise ValueError("unsupported requested seed")
        payload = dict(_PARAMETERS, seed=seed, messages=_messages(snapshot, plans), response_format=_SCHEMA)
        response = _request(_CHAT_URL, payload, opener=opener)
        if response["status"] != "ok":
            result.update(status=response["status"], error=response["error"])
        else:
            envelope = response["data"]
            choice = envelope["choices"][0]
            content = choice["message"]["content"]
            if not isinstance(content, str):
                raise ValueError("message.content is not text")
            result["raw_text"] = content
            if choice.get("finish_reason") != "stop":
                raise ValueError("incomplete or unsupported finish_reason")
            result.update(_classify(content, snapshot, plans))
            result["metadata"] = {key: envelope[key] for key in ("id", "model", "created", "usage") if key in envelope}
            result["metadata"]["finish_reason"] = choice["finish_reason"]
    except (ValueError, TypeError, KeyError, IndexError, UnicodeError, RecursionError) as error:
        result.update(status="protocol_error", action_id=None, error=str(error)[:240])
    result["latency_ms"] = (perf_counter() - start) * 1000
    return result


def _attempt(backend, case, plans, seed, order, opener):
    tactical = _projection(case)
    if backend == "gemma":
        result = gemma(tactical, plans, seed, opener=opener)
    else:
        start = perf_counter()
        raw = _canonical({"action_id": baseline(tactical, plans)})
        elapsed = (perf_counter() - start) * 1000
        result = dict(_classify(raw, tactical, plans), latency_ms=elapsed)
    legal = result["status"] == "ok"
    reference = baseline(tactical, plans)
    result.update(case_id=case["case_id"], seed_requested=seed, order=order, backend=backend,
                  legal=legal, oracle_hit=legal and result["action_id"] in case["acceptable_actions"],
                  acceptable_actions=case["acceptable_actions"].copy(),
                  validation_reason=(validate(result["raw_text"], tactical, plans)["reason"]
                                     if result["raw_text"] is not None else None),
                  baseline_action_id=reference,
                  agrees_with_baseline=result["action_id"] == reference if legal else None,
                  tactical_prompt_sha256=_hash(_messages(tactical, plans)),
                  plan=copy.deepcopy(plans[result["action_id"]]) if legal else None)
    return result


def _external_paths(output_dir):
    checkout = Path(__file__).resolve().parents[2]
    if output_dir is None:
        parent = Path(tempfile.gettempdir()).resolve()
        if parent.is_relative_to(checkout):
            raise ValueError("temporary directory must be outside checkout")
        output_dir = tempfile.mkdtemp(prefix="demons-director-", dir=parent)
    directory = Path(output_dir).expanduser().resolve()
    if directory.is_relative_to(checkout):
        raise ValueError("output directory must resolve outside checkout")
    paths = {"json": directory / "results.json", "markdown": directory / "report.md"}
    if any(p.resolve().is_relative_to(checkout) or p.resolve().parent != directory for p in paths.values()):
        raise ValueError("output files cannot redirect through symlinks")
    directory.mkdir(parents=True, exist_ok=True)
    return paths


def run(backend, output_dir, *, manifest_path=None, model_file=None, opener=None) -> dict:
    report = {"attempts": [], "warmup": None, "summary": summarize([]), "metadata": {},
              "outputs": {"json": None, "markdown": None}, "error": None}
    try:
        if backend not in ("baseline", "gemma"):
            raise ValueError("unknown backend")
        paths = _external_paths(output_dir)
        plans, cases = catalog(), scenarios()
        identity = None
        if backend == "gemma":
            identity = verify_identity(manifest_path, model_file, opener=opener)
            if identity["status"] != "ok":
                report.update(metadata=identity["metadata"], error={"status": "identity_error", "message": identity["error"]})
                return report
        report["metadata"] = {
            "backend": backend, "python": platform.python_version(), "os": platform.platform(),
            "catalog_sha256": _hash(plans), "fixtures_sha256": _hash(cases),
            "tactical_prompt_sha256": [_hash(_messages(case, plans)) for case in cases],
            "parameters_requested": dict(_PARAMETERS, seeds=[42, 43, 44], response_format=_SCHEMA) if backend == "gemma" else {},
            "structured_mode": "requested_json_schema_not_guaranteed" if backend == "gemma" else "not_applicable",
            "cold_start_ms": "not_measured", "memory_cpu_gpu": "not_measured",
            "transport": ("not_applicable" if backend == "baseline" else
                          "explicit_test_double" if opener is not None else "stdlib_loopback_no_proxy_no_redirect"),
            "runtime_declared": {"name": "LiteRT-LM", "runtime_version": "0.19", "api_version": "0.19",
                                 "source": "root-provided environment; not attested by models endpoint"} if backend == "gemma" else None,
            "identity": identity["metadata"] if identity is not None else None,
            "limits": "Exploratory synthetic cases; no gameplay, optimal strategy, fun, wins, GPU/FPS or S24 inference.",
        }
        report["warmup"] = _attempt(backend, cases[0], plans, 42, None, opener)
        schedule = [(case, seed) for case in cases for seed in (42, 43, 44)]
        random.Random(20261031).shuffle(schedule)
        report["attempts"] = [_attempt(backend, case, plans, seed, order, opener)
                              for order, (case, seed) in enumerate(schedule)]
        report["summary"] = summarize(report["attempts"])
        report["outputs"] = {key: str(path) for key, path in paths.items()}
        paths["json"].write_text(json.dumps(report, indent=2, ensure_ascii=False, allow_nan=False) + "\n", encoding="utf-8")
        paths["markdown"].write_text(markdown(report), encoding="utf-8")
    except (OSError, ValueError, TypeError, KeyError, UnicodeError, RecursionError) as error:
        report["error"] = {"status": "preflight_error" if not report["attempts"] else "io_error", "message": str(error)[:240]}
        report["outputs"] = {"json": None, "markdown": None}
    return report


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--backend", required=True, choices=("baseline", "gemma"))
    parser.add_argument("--output-dir")
    parser.add_argument("--model-manifest")
    parser.add_argument("--model-file")
    try:
        args = parser.parse_args(argv)
        if args.backend == "gemma" and (not args.model_manifest or not args.model_file):
            parser.error("Gemma requires --model-manifest and --model-file")
    except SystemExit as error:
        return error.code
    report = run(args.backend, args.output_dir, manifest_path=args.model_manifest, model_file=args.model_file)
    if report["error"]:
        print(_canonical(report["error"]), file=sys.stderr)
        return 1
    print(_canonical({"summary": report["summary"], "outputs": report["outputs"]}))
    return 0 if len(report["attempts"]) == 24 else 1
