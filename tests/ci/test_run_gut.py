"""The CI gate must prove a real GUT run, rather than trust Godot's exit code."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


RUNNER = Path(__file__).resolve().parents[2] / "tools/ci/run_gut.py"
# Actual summary: specs/003-web-itchio/evidence/t017-green-full.log:293-307.
PASS = """= Run Summary
Totals
------
Warnings              3
Scripts              16
Tests               189
Passing Tests       189
Asserts             532
Time              38.194s
---- All tests passed! ----
"""
# Actual false-green job117134049321, run38948627481, HEAD2744803.
FALSE_GREEN = (
    "ERROR: Some GUT class_names have not been imported.  Please restart "
    "the Editor or run godot --headless --import\n"
)
FAKE = """import json, pathlib, sys
root = pathlib.Path(__file__).parent
args = sys.argv[1:]
phase = 'import' if '--import' in args else 'gut'
with (root / 'calls.jsonl').open('a') as stream:
    stream.write(json.dumps({'phase': phase, 'args': args, 'cwd': str(pathlib.Path.cwd())}) + '\\n')
scenario = json.loads((root / 'scenario.json').read_text())[phase]
print(scenario.get('stdout', ''), end='')
print(scenario.get('stderr', ''), end='', file=sys.stderr)
sys.exit(scenario.get('code', 0))
"""


class RunGutContractTests(unittest.TestCase):
    def invoke(self, *, import_result=None, gut_result=None):
        with tempfile.TemporaryDirectory(prefix="demons-gut-gate-") as directory:
            root = Path(directory)
            project = root / "project with spaces"
            project.mkdir()
            fake = root / "fake-godot"
            fake.write_text(f"#!{sys.executable}\n" + FAKE)
            fake.chmod(0o755)
            (root / "scenario.json").write_text(json.dumps({
                "import": import_result or {"stdout": "IMPORT_OK\n"},
                "gut": gut_result or {"stdout": PASS},
            }))
            result = subprocess.run(
                [sys.executable, str(RUNNER), "--godot", str(fake), "--project", str(project)],
                capture_output=True, text=True, timeout=10,
            )
            calls = [json.loads(line) for line in (root / "calls.jsonl").read_text().splitlines()]
            for call in calls:
                self.assertIn("--headless", call["args"])
                path = Path(call["args"][call["args"].index("--path") + 1])
                self.assertEqual((Path(call["cwd"]) / path).resolve(), project.resolve())
            return result, [call["phase"] for call in calls]

    def test_import_precedes_real_summary_and_both_outputs_are_forwarded(self):
        for summary in [PASS, "\x1b[32m" + PASS + "\x1b[0m"]:
            with self.subTest(ansi=summary != PASS):
                result, phases = self.invoke(gut_result={"stdout": summary})
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(phases, ["import", "gut"])
                self.assertIn("IMPORT_OK", result.stdout)
                self.assertIn(summary, result.stdout)

    def test_import_failure_or_engine_error_prevents_running_gut(self):
        for import_result in [
            {"code": 7, "stdout": "Import failed\n"},
            {"stderr": "ERROR: Unable to import a required resource\n"},
            {"stdout": "SCRIPT ERROR: Parse Error: Missing class\n"},
        ]:
            with self.subTest(import_result=import_result):
                result, phases = self.invoke(import_result=import_result)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(phases, ["import"])

    def test_false_green_ci_and_other_incomplete_or_failed_runs_are_rejected(self):
        invalid = {
            "actual_false_green": {"stderr": FALSE_GREEN},
            "engine_error_with_complete_summary": {"stdout": PASS, "stderr": "ERROR: Runtime failure\n"},
            "script_error_with_complete_summary": {"stdout": "SCRIPT ERROR: Parse Error\n" + PASS},
            "nonzero_with_complete_summary": {"stdout": PASS, "code": 1},
            "no_summary": {"stdout": "Godot Engine started\n"},
            "zero_tests": {"stdout": PASS.replace("189", "0")},
            "count_mismatch": {"stdout": PASS.replace("Passing Tests       189", "Passing Tests       188")},
            "missing_passing_count": {"stdout": PASS.replace("Passing Tests       189\n", "")},
            "failing_tests": {"stdout": PASS + "Failing Tests       1\n"},
            "gut_error_count": {"stdout": PASS.replace("Warnings              3", "Errors                1")},
            "failed_setup_assert": {"stdout": PASS.replace("532", "531/532").replace(
                "---- All tests passed! ----", "---- 1 assert(s) in before_all/after_all methods failed ----")},
        }
        for name, gut_result in invalid.items():
            with self.subTest(scenario=name):
                result, _ = self.invoke(gut_result=gut_result)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
