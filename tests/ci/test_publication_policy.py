"""Publication is a separate, explicit gate; integration must never distribute.

Read the workflows' small mapping subset without a YAML dependency, evaluate
their actual job conditions, and run their real version guard offline. This
does not invoke Actions, export an app, load credentials, or contact a service.
"""

import ast
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
APPROVAL = "APROBADO PARA PUBLICACIÓN"
TARGETS = (
    ("android", "deploy-android-testers.yml", "deploy-android", "version/code", "version/name"),
    ("ios", "deploy-ios-testflight.yml", "deploy-ios", "application/version", "application/short_version"),
)

# Offline GitHub responses include workflow conclusions and the publication
# job/step conclusions separately: a skipped job can belong to a successful run.
FAKE_GH_HISTORY = r'''import json, os, pathlib, re, sys
args = sys.argv[1:]
history = json.loads(pathlib.Path(os.environ['FIXTURE_HISTORY']).read_text())
fault = os.environ.get('FIXTURE_FAULT', '')
if (fault == 'gh_list' and args[:2] == ['run', 'list']) or (fault == 'gh_details' and args[:2] == ['run', 'view']):
    print('Fixture GitHub CLI request failed', file=sys.stderr)
    sys.exit(9)
if (fault == 'invalid_json_runs' and args[:2] == ['run', 'list']) or (fault == 'invalid_json_jobs' and args[:2] == ['run', 'view']):
    print('Not a valid JSON response')
    sys.exit(0)
def option(flag, default=None):
    return args[args.index(flag) + 1] if flag in args else default
def unsupported():
    print('FAKE_GH_UNSUPPORTED: ' + repr(args), file=sys.stderr)
    sys.exit(2)
if args[:2] == ['run', 'list']:
    data = [{key: value for key, value in run.items() if key != 'jobs'} for run in history]
    data = data[:int(option('--limit', str(len(data))))]
elif args[:2] == ['run', 'view']:
    run = next(run for run in history if str(run['databaseId']) == args[2])
    data = run.copy()
elif args[:1] == ['api'] and re.search(r'/actions/runs/\d+/jobs$', args[1]):
    run_id = args[1].split('/')[-2]
    run = next(run for run in history if str(run['databaseId']) == run_id)
    data = {'jobs': run['jobs']}
else:
    unsupported()
query = option('--jq', option('-q'))
if query == '.[0].headSha // empty':
    print(data[0]['headSha'] if data else '')
elif query is not None:
    unsupported()
else:
    fields = option('--json')
    if fields:
        selected = fields.split(',')
        if isinstance(data, list):
            data = [{key: item[key] for key in selected} for item in data]
        else:
            data = {key: data[key] for key in selected}
    print(json.dumps(data))
'''


def mapping(lines, indent):
    """Return direct mapping entries and their indented children, not shell text."""
    entries = {}
    for index, line in enumerate(lines):
        if len(line) - len(line.lstrip()) != indent or line.lstrip().startswith("#"):
            continue
        match = re.fullmatch(r"\s*([\w-]+):(?:\s*(.*))?", line)
        if not match:
            continue
        end = index + 1
        while end < len(lines):
            next_line = lines[end]
            if next_line.strip() and not next_line.lstrip().startswith("#"):
                if len(next_line) - len(next_line.lstrip()) <= indent:
                    break
            end += 1
        entries[match[1]] = (match[2] or "", lines[index + 1:end])
    return entries


def scalar(entry):
    raw, children = entry
    if raw in ("|", "|-", ">", ">-"):
        separator = " " if raw.startswith(">") else "\n"
        return separator.join(line.strip() for line in children if line.strip())
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "\"'":
        return raw[1:-1]
    return raw.split(" #", 1)[0].strip()


TOKEN = re.compile(r"\s*(?:('(?:[^']|'')*')|([A-Za-z_][\w.]*)|(&&|\|\||==|!=|[!()]))")


def condition(expression, context):
    """Evaluate the boolean/string subset used by publication job/step guards.

    Unsupported expressions fail the test, rather than silently approving a
    workflow. Missing job/step `if` has Actions' default successful-job behavior.
    """
    if expression is None:
        return True
    expression = expression.strip().removeprefix("${{").removesuffix("}}").strip()
    translated = []
    position = 0
    while position < len(expression):
        match = TOKEN.match(expression, position)
        if not match:
            raise AssertionError(f"Unsupported publication condition: {expression!r}")
        quoted, identifier, operator = match.groups()
        if quoted is not None:
            translated.append(repr(quoted[1:-1].replace("''", "'")))
        elif identifier is not None:
            value = {"true": True, "false": False, "null": None}.get(
                identifier, context.get(identifier, ""))
            translated.append(repr(value))
        else:
            translated.append({"&&": "and", "||": "or", "!": "not"}.get(operator, operator))
        position = match.end()
    node = ast.parse(" ".join(translated), mode="eval").body

    def equal(left, right):
        # Actions string equality is case-insensitive; unlike Python it also
        # coerces different primitive types to numbers. See GitHub's official
        # actions/reference/workflows-and-actions/expressions#operators.
        if isinstance(left, str) and isinstance(right, str):
            return left.casefold() == right.casefold()
        if type(left) is not type(right):
            def number(value):
                if value is None or value == "":
                    return 0
                if isinstance(value, (bool, int, float)):
                    return int(value)
                try:
                    return float(value)
                except (TypeError, ValueError):
                    return math.nan
            return number(left) == number(right)
        return left == right

    def evaluate(item):
        if isinstance(item, ast.Constant):
            return item.value
        if isinstance(item, ast.BoolOp):
            values = [bool(evaluate(value)) for value in item.values]
            return all(values) if isinstance(item.op, ast.And) else any(values)
        if isinstance(item, ast.UnaryOp) and isinstance(item.op, ast.Not):
            return not evaluate(item.operand)
        if isinstance(item, ast.Compare) and len(item.ops) == 1:
            left, right = evaluate(item.left), evaluate(item.comparators[0])
            if isinstance(item.ops[0], ast.Eq):
                return equal(left, right)
            if isinstance(item.ops[0], ast.NotEq):
                return not equal(left, right)
        raise AssertionError(f"Unsupported publication condition node: {ast.dump(item)}")

    return bool(evaluate(node))


class Workflow:
    def __init__(self, filename, job_id):
        self.path = ROOT / ".github/workflows" / filename
        self.text = self.path.read_text()
        top = mapping(self.text.splitlines(), 0)
        self.name = scalar(top["name"])
        self.events = mapping(top["on"][1], 2)
        self.jobs = mapping(top["jobs"][1], 2)
        self.job = mapping(self.jobs[job_id][1], 4)
        self.job_if = scalar(self.job["if"]) if "if" in self.job else None
        dispatch = mapping(self.events.get("workflow_dispatch", ("", []))[1], 4)
        self.inputs = mapping(dispatch.get("inputs", ("", []))[1], 6)
        self.steps = []
        step_lines = self.job["steps"][1]
        starts = [index for index, line in enumerate(step_lines) if line.startswith("      - ")]
        for start, end in zip(starts, starts[1:] + [len(step_lines)]):
            block = step_lines[start:end]
            # The first step property shares its line with the list marker.
            block = ["        " + block[0][8:]] + block[1:]
            self.steps.append(mapping(block, 8))

    def context(self, event="workflow_dispatch", ref="refs/heads/main", approval=APPROVAL, authorized=True):
        return {
            "github.event_name": event, "github.ref": ref,
            "inputs.approval_status": approval, "inputs.human_authorized": authorized,
        }

    def activates(self, **kwargs):
        context = self.context(**kwargs)
        return context["github.event_name"] in self.events and condition(self.job_if, context)

    def version_guard(self):
        guards = [(index, step) for index, step in enumerate(self.steps)
                  if "run" in step and "gh run list" in scalar(step["run"])
                  and "export_presets.cfg" in scalar(step["run"])]
        if len(guards) != 1:
            raise AssertionError(f"Expected one executable version guard in {self.path.name}: {len(guards)}")
        return guards[0]


class PublicationPolicyTests(unittest.TestCase):
    def workflows(self):
        for platform, filename, job_id, code, name in TARGETS:
            yield platform, Workflow(filename, job_id), code, name

    def test_push_and_pull_request_cannot_activate_distribution(self):
        for platform, workflow, _, _ in self.workflows():
            for event in ("push", "pull_request", "pull_request_target"):
                with self.subTest(platform=platform, event=event):
                    self.assertFalse(workflow.activates(event=event),
                                     f"{platform}: {event} on main currently activates the publication job")

    def test_only_manual_dispatch_is_declared(self):
        for platform, workflow, _, _ in self.workflows():
            with self.subTest(platform=platform):
                self.assertEqual(set(workflow.events), {"workflow_dispatch"})

    def test_confirmation_inputs_are_explicit_and_default_to_no_authorization(self):
        for platform, workflow, _, _ in self.workflows():
            with self.subTest(platform=platform):
                self.assertIn("approval_status", workflow.inputs)
                approval = mapping(workflow.inputs["approval_status"][1], 8)
                self.assertEqual(scalar(approval["type"]), "choice")
                self.assertEqual(scalar(approval["default"]), "PENDIENTE")
                options = [line.strip()[2:] for line in approval["options"][1]
                           if line.strip().startswith("- ")]
                self.assertIn(APPROVAL, options)
                self.assertIn("PENDIENTE", options)
                self.assertIn("human_authorized", workflow.inputs)
                human = mapping(workflow.inputs["human_authorized"][1], 8)
                self.assertEqual(scalar(human["type"]), "boolean")
                self.assertEqual(scalar(human["default"]), "false")

    def test_manual_dispatch_without_both_explicit_confirmations_is_denied(self):
        cases = (("", False), ("PENDIENTE", True), (APPROVAL, False),
                 ("", True), (APPROVAL, None), (APPROVAL, "false"))
        for platform, workflow, _, _ in self.workflows():
            for approval, authorized in cases:
                with self.subTest(platform=platform, approval=approval, human=authorized):
                    self.assertFalse(workflow.activates(approval=approval, authorized=authorized),
                                     f"{platform}: missing/refused confirmation currently allows publication")

    def test_approval_on_unintegrated_branch_or_tag_is_denied(self):
        for platform, workflow, _, _ in self.workflows():
            for ref in ("refs/heads/codex/pending", "refs/tags/v1", ""):
                with self.subTest(platform=platform, ref=ref):
                    self.assertFalse(workflow.activates(ref=ref))

    def test_explicit_human_approval_on_main_allows_manual_publication(self):
        for platform, workflow, _, _ in self.workflows():
            with self.subTest(platform=platform):
                self.assertTrue(workflow.activates())

    def test_job_guard_protects_checkout_and_every_secret_using_step(self):
        for platform, workflow, _, _ in self.workflows():
            with self.subTest(platform=platform):
                self.assertIsNotNone(workflow.job_if,
                                     "A job-level guard must run before checkout or secret-bearing steps")
                self.assertEqual(len(workflow.jobs), 1, "Audit any added job before it can use publication secrets")
                self.assertTrue(any("uses" in step and "actions/checkout@" in scalar(step["uses"])
                                    for step in workflow.steps))
                for context in (workflow.context(authorized=False), workflow.context(event="push"),
                                workflow.context(ref="refs/heads/codex/pending")):
                    self.assertFalse(condition(workflow.job_if, context))

    def test_version_guard_cannot_be_skipped_by_authorized_manual_dispatch(self):
        for platform, workflow, _, _ in self.workflows():
            with self.subTest(platform=platform):
                _, guard = workflow.version_guard()
                guard_if = scalar(guard["if"]) if "if" in guard else None
                self.assertTrue(condition(guard_if, workflow.context()),
                                f"{platform}: version check is skipped on workflow_dispatch")

    def test_version_guard_precedes_exports_signing_and_distribution_secrets(self):
        for platform, workflow, _, _ in self.workflows():
            with self.subTest(platform=platform):
                guard_index, _ = workflow.version_guard()
                sensitive = [index for index, step in enumerate(workflow.steps)
                             if any(any(marker in "\n".join((value[0], *value[1]))
                                        for marker in ("secrets.", "--export-", "Firebase-Distribution", "--upload-app"))
                                    for value in step.values())]
                self.assertTrue(sensitive, "Expected a real export/publication path in this workflow")
                self.assertTrue(all(guard_index < index for index in sensitive))

    def invoke_version_guard(self, workflow, code, name, *, prior=True, changed_key=None,
                             skipped_run=False, fault=None):
        with tempfile.TemporaryDirectory(prefix="demons-publication-gate-") as directory:
            root = Path(directory)
            env = os.environ.copy()
            # Remove inherited Git routing so the real guard cannot touch the checkout.
            for key in tuple(env):
                if key.startswith("GIT_") or key in ("GH_TOKEN", "GITHUB_TOKEN"):
                    env.pop(key)
            env.update({"GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_SYSTEM": os.devnull})

            def git(*args):
                return subprocess.run(["git", *args], cwd=root, env=env, check=True,
                                      capture_output=True, text=True).stdout.strip()

            git("init", "--quiet")
            git("config", "user.name", "Publication gate fixture")
            git("config", "user.email", "fixture@example.invalid")
            versions = {"version/code": "3", "version/name": '"1.0"',
                        "application/version": '"3"', "application/short_version": '"1.0"',
                        "unrelated/setting": "1"}

            def write_versions():
                (root / "export_presets.cfg").write_text("\n".join(f"{key}={value}" for key, value in versions.items()) + "\n")

            write_versions()
            git("add", "export_presets.cfg")
            git("commit", "--quiet", "-m", "previous distributed version")
            previous = git("rev-parse", "HEAD")
            previous_versions = versions.copy()
            if skipped_run and prior:
                # A later successful workflow did not publish. Its version is
                # intentionally different so choosing it produces the opposite
                # answer for both the repeated-version and changed-version cases.
                versions[code] = "4"
                write_versions()
                git("add", "export_presets.cfg")
                git("commit", "--quiet", "-m", "run with skipped publication job")
                skipped_sha = git("rev-parse", "HEAD")
                versions = previous_versions.copy()
            else:
                skipped_sha = previous
            if changed_key is not None:
                versions[changed_key] = '"2.0"' if changed_key == name else "4"
            if changed_key is not None or (skipped_run and prior):
                write_versions()
                git("add", "export_presets.cfg")
                git("commit", "--quiet", "--allow-empty", "-m", "candidate version")

            def history_run(run_id, sha, published):
                return {
                    "databaseId": run_id, "headSha": sha, "conclusion": "success",
                    "status": "completed", "event": "workflow_dispatch", "headBranch": "main",
                    "workflowName": workflow.name,
                    "jobs": [{"name": scalar(workflow.job["name"]),
                              "status": "completed", "conclusion": "success" if published else "skipped",
                              "steps": [{"name": scalar(workflow.steps[-1]["name"]),
                                         "number": len(workflow.steps), "status": "completed",
                                         "conclusion": "success"}] if published else []}],
                }

            history = [history_run(201, previous, True)] if prior else []
            if skipped_run:
                history.insert(0, history_run(202, skipped_sha, False))
            if fault == "invalid_sha":
                history[0]["headSha"] = "f" * 40
            elif fault == "history_cap":
                history = [history_run(202 + index, skipped_sha, False) for index in range(100)]
            history_path = root / "history.json"
            history_path.write_text(json.dumps(history))
            fake_bin = root / "bin"
            fake_bin.mkdir()
            fake_gh = fake_bin / "gh"
            fake_gh.write_text(f"#!{sys.executable}\n" + FAKE_GH_HISTORY)
            fake_gh.chmod(0o755)
            env.update({"PATH": str(fake_bin) + os.pathsep + env["PATH"],
                        "FIXTURE_HISTORY": str(history_path), "FIXTURE_FAULT": fault or ""})
            _, guard = workflow.version_guard()
            result = subprocess.run(["bash", "--noprofile", "--norc", "-eo", "pipefail", "-c", scalar(guard["run"])],
                                    cwd=root, env=env, capture_output=True, text=True, timeout=10)
            self.assertNotIn("FAKE_GH_UNSUPPORTED", result.stderr, result.stderr)
            if fault not in ("invalid_json_runs", "invalid_json_jobs"):
                self.assertNotIn("Traceback (most recent call last)", result.stderr, result.stderr)
            result.history_description = json.dumps(history, ensure_ascii=False)
            return result

    def test_first_distribution_with_no_successful_history_is_allowed(self):
        for platform, workflow, code, name in self.workflows():
            with self.subTest(platform=platform):
                result = self.invoke_version_guard(workflow, code, name, prior=False)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_repeated_version_and_unrelated_config_changes_are_blocked(self):
        for platform, workflow, code, name in self.workflows():
            for changed in (None, "unrelated/setting"):
                with self.subTest(platform=platform, changed=changed):
                    result = self.invoke_version_guard(workflow, code, name, changed_key=changed)
                    self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
                    self.assertIn("::error::", result.stdout)

    def test_version_pair_change_allows_distribution(self):
        for platform, workflow, code, name in self.workflows():
            for changed in (code, name):
                with self.subTest(platform=platform, changed=changed):
                    result = self.invoke_version_guard(workflow, code, name, changed_key=changed)
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_successful_run_with_skipped_publication_does_not_prevent_first_distribution(self):
        for platform, workflow, code, name in self.workflows():
            with self.subTest(platform=platform):
                result = self.invoke_version_guard(workflow, code, name, prior=False, skipped_run=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr + result.history_description)

    def test_skipped_run_cannot_hide_repeated_version_of_last_real_publication(self):
        for platform, workflow, code, name in self.workflows():
            with self.subTest(platform=platform):
                result = self.invoke_version_guard(workflow, code, name, skipped_run=True)
                self.assertEqual(result.returncode, 1, result.stdout + result.stderr + result.history_description)

    def test_skipped_run_cannot_block_changed_version_since_last_real_publication(self):
        for platform, workflow, code, name in self.workflows():
            with self.subTest(platform=platform):
                result = self.invoke_version_guard(workflow, code, name, changed_key=code, skipped_run=True)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr + result.history_description)

    # Supplemental GREEN coverage of the already implemented fail-closed paths;
    # these cases are not evidence of RED before the implementation.
    def test_github_run_list_error_blocks_distribution(self):
        for platform, workflow, code, name in self.workflows():
            with self.subTest(platform=platform):
                result = self.invoke_version_guard(workflow, code, name, changed_key=code, fault="gh_list")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_github_job_details_error_blocks_distribution(self):
        for platform, workflow, code, name in self.workflows():
            with self.subTest(platform=platform):
                result = self.invoke_version_guard(workflow, code, name, changed_key=code, fault="gh_details")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_invalid_history_or_job_json_blocks_distribution(self):
        for platform, workflow, code, name in self.workflows():
            for fault in ("invalid_json_runs", "invalid_json_jobs"):
                with self.subTest(platform=platform, fault=fault):
                    result = self.invoke_version_guard(workflow, code, name, changed_key=code, fault=fault)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_unknown_history_sha_or_git_diff_error_blocks_distribution(self):
        for platform, workflow, code, name in self.workflows():
            with self.subTest(platform=platform):
                result = self.invoke_version_guard(workflow, code, name, changed_key=code, fault="invalid_sha")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_full_history_window_without_proven_publication_blocks_distribution(self):
        for platform, workflow, code, name in self.workflows():
            with self.subTest(platform=platform):
                result = self.invoke_version_guard(workflow, code, name, prior=False, skipped_run=True, fault="history_cap")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("Historial de publicación incompleto", result.stdout)


if __name__ == "__main__":
    unittest.main()
