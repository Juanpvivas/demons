"""Offline report/CLI oracles. Injected HTTP is explicitly FAKE."""
import copy
import json
import random
import tempfile
import unittest
from collections import Counter
from pathlib import Path
from unittest.mock import patch

from tools.director_benchmark import benchmark as subject
from test_transport import FakeOpener


def prompt_hashes(value):
    """Inspect public report metadata without assuming a private hash API."""
    found = []
    def walk(item, path=""):
        if isinstance(item, dict):
            for key, child in item.items(): walk(child, path + "/" + key.lower())
        elif isinstance(item, list):
            for child in item: walk(child, path)
        elif isinstance(item, str) and "prompt" in path and len(item) == 64:
            try: int(item, 16)
            except ValueError: return
            found.append(item)
    walk(value)
    return sorted(found)


class RunnerContractTests(unittest.TestCase):
    def report(self, backend, output, **options):
        result = subject.run(backend, output, **options)
        self.assertIsInstance(result, dict, "runner must return a complete public report")
        for key, kind in [("attempts", list), ("warmup", dict), ("summary", dict),
                          ("metadata", dict), ("outputs", dict)]:
            self.assertIsInstance(result.get(key), kind)
        return result

    def test_baseline_records_24_ordered_attempts_warmup_and_external_json_markdown(self):
        with tempfile.TemporaryDirectory() as temp:
            result = self.report("baseline", Path(temp))
            attempts = result["attempts"]
            self.assertEqual(len(attempts), 24)
            self.assertEqual(len({a["case_id"] for a in attempts}), 8)
            expected = [(case["case_id"], seed) for case in subject.scenarios() for seed in [42, 43, 44]]
            random.Random(20261031).shuffle(expected)
            self.assertEqual([(a["case_id"], a["seed_requested"]) for a in attempts], expected)
            self.assertEqual(result["warmup"]["case_id"], "balanced")
            self.assertEqual(result["warmup"]["seed_requested"], 42)
            self.assertTrue(all(a["status"] == "ok" for a in attempts))
            self.assertTrue(all(a["latency_ms"] >= 0 for a in attempts))
            oracles = {case["case_id"]: set(case["acceptable_actions"]) for case in subject.scenarios()}
            self.assertEqual(result["summary"]["total_attempts"], len(attempts))
            self.assertEqual(result["summary"]["legal_count"], 24)
            self.assertEqual(result["summary"]["evaluable_count"], 24)
            self.assertEqual(result["summary"]["oracle_hit_count"],
                             sum(a["action_id"] in oracles[a["case_id"]] for a in attempts))
            self.assertEqual(result["summary"]["status_counts"], dict(Counter(a["status"] for a in attempts)))
            self.assertIn("not_measured", json.dumps(result["metadata"]))
            self.assertTrue(prompt_hashes(result), "canonical tactical prompt hashes must be reported")
            raw = Path(result["outputs"]["json"])
            md = Path(result["outputs"]["markdown"])
            self.assertEqual(raw.name, "results.json"); self.assertEqual(md.name, "report.md")
            self.assertEqual(raw.resolve().parent, Path(temp).resolve())
            saved = json.loads(raw.read_text())
            self.assertEqual(saved["attempts"], attempts)
            self.assertEqual(saved["summary"], result["summary"])
            text = md.read_text()
            self.assertIn("24", text)
            self.assertIn("evaluable", text.lower())
            self.assertTrue("/24" in "".join(text.split()) or
                            any(word in text.lower() for word in ["denominator", "denominador"]))
            self.assertIn("not_measured", text)
            self.assertTrue(any(word in text.lower() for word in ["nearest-rank", "nearest_rank"]))

    def test_case_and_oracle_metadata_do_not_influence_tactical_hash_or_decisions(self):
        original = subject.scenarios()
        self.assertIsInstance(original, list)
        changed = copy.deepcopy(original)
        for case in changed:
            case["case_id"] = "renamed_" + case["case_id"]
            case["acceptable_actions"] = ["deliberately_wrong_evaluation_only"]
            case["report_metadata"] = {"expected": "deliberately_wrong_evaluation_only"}
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            first = self.report("baseline", Path(a))
            with patch.object(subject, "scenarios", return_value=changed):
                second = self.report("baseline", Path(b))
            self.assertEqual([r["action_id"] for r in first["attempts"]],
                             [r["action_id"] for r in second["attempts"]])
            self.assertTrue(prompt_hashes(first)); self.assertEqual(prompt_hashes(first), prompt_hashes(second))

    def test_fake_gemma_preserves_failed_attempts_without_retry_and_separates_warmup(self):
        fake = FakeOpener(data=b"invalid envelope")
        with tempfile.TemporaryDirectory() as temp, \
                patch.object(subject, "verify_identity", return_value={"status": "ok", "error": None,
                                                                       "metadata": {"test_double": True}}):
            result = self.report("gemma", Path(temp), manifest_path="FAKE", model_file="FAKE", opener=fake)
        self.assertEqual(len(result["attempts"]), 24)
        self.assertEqual(len(fake.calls), 25, "one warmup + 24 measured calls, no replacement/retry")
        self.assertEqual(result["warmup"]["status"], "protocol_error")
        self.assertTrue(all(a["status"] == "protocol_error" and a["action_id"] is None
                            for a in result["attempts"]))
        self.assertEqual(result["summary"]["total_attempts"], 24)
        self.assertEqual(result["summary"]["legal_count"], 0)
        self.assertEqual(result["summary"]["evaluable_count"], 0)
        self.assertEqual(result["summary"]["oracle_hit_count"], 0)
        self.assertEqual(result["summary"]["status_counts"], {"protocol_error": 24})

    def test_preflight_identity_failure_stops_batch_and_cli_exits_one(self):
        fake = FakeOpener()
        with tempfile.TemporaryDirectory() as temp, \
                patch.object(subject, "verify_identity", return_value={"status": "identity_error",
                                                                       "error": "FAKE wrong model", "metadata": {}}):
            result = subject.run("gemma", Path(temp), manifest_path="FAKE", model_file="FAKE", opener=fake)
            self.assertIsInstance(result, dict)
            self.assertEqual(result["attempts"], [])
            self.assertTrue(result.get("error"))
            self.assertFalse(fake.calls)
            self.assertEqual(subject.main(["--backend", "gemma", "--model-manifest", "FAKE",
                                           "--model-file", "FAKE", "--output-dir", temp]), 1)

    def test_cli_baseline_and_invalid_arguments_and_checkout_symlink_guard(self):
        with tempfile.TemporaryDirectory() as temp:
            self.assertEqual(subject.main(["--backend", "baseline", "--output-dir", temp]), 0)
            self.assertTrue((Path(temp) / "results.json").is_file())
        for args in [["--backend", "invented"], ["--endpoint", "https://cloud.invalid/"]]:
            with self.subTest(args=args):
                self.assertEqual(subject.main(args), 2)
        checkout = Path(__file__).resolve().parents[2]
        with tempfile.TemporaryDirectory() as temp:
            alias = Path(temp) / "checkout"; alias.symlink_to(checkout, target_is_directory=True)
            for output in [checkout / "FORBIDDEN_BENCHMARK_OUTPUT", alias / "FORBIDDEN_BENCHMARK_OUTPUT"]:
                self.assertEqual(subject.main(["--backend", "baseline", "--output-dir", str(output)]), 1)
                self.assertFalse(output.exists(), "resolved paths inside checkout must not be written")


if __name__ == "__main__":
    unittest.main()
