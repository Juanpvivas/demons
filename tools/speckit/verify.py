#!/usr/bin/env python3
"""Verify the project's Spec Kit preset and Claude outputs (read-only by default).

Uses only the standard library to find the installed ``specify`` launcher,
then reads YAML and renders expected skills with that installation's Python
and existing dependencies. Explicit --reapply only re-registers the already
installed, unchanged project preset; it never installs or updates Spec Kit,
runs a workflow, or executes project agents/tests. Private renderer helpers mirror
Spec Kit 1.0.1 and 1.2.0; an incompatible runtime fails explicitly rather than
certifying stale output.
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys


PRESET_ID = "demons-agent-tdd"
WORKFLOW_ID = "demons-preparation"
MINIMUM_VERSION = "1.0.1"
COMMANDS = (
    "analyze", "checklist", "clarify", "constitution", "converge",
    "implement", "plan", "specify", "tasks", "taskstoissues",
)
TEMPLATES = ("spec-template", "plan-template", "tasks-template")


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--project-root", type=Path, default=Path(__file__).resolve().parents[2],
        help="Project checkout to inspect (default: this script's repository).",
    )
    parser.add_argument(
        "--source-root", type=Path,
        help="Source directory containing presets/ and workflows/ "
             "(default: <project-root>/tools/speckit).",
    )
    parser.add_argument(
        "--specify", default="specify", help="Installed specify executable to inspect.",
    )
    parser.add_argument(
        "--runtime-python", type=Path,
        help="Python belonging to specify, if its launcher has no Python shebang.",
    )
    parser.add_argument(
        "--reapply", action="store_true",
        help="Explicit recovery: after read-only preflight, re-register the unchanged "
             "installed preset's Claude skills and verify again. Never syncs edited source.",
    )
    parser.add_argument("--_runtime", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--_preflight", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--_reapply-runtime", action="store_true", help=argparse.SUPPRESS)
    return parser.parse_args()


def runtime_command(args: argparse.Namespace) -> list[str]:
    if args.runtime_python:
        # Keep the venv's interpreter path: resolving its symlink to the base
        # Python loses that environment's specify_cli/PyYAML installation.
        executable = args.runtime_python.expanduser().absolute()
        if not executable.is_file():
            raise ValueError(f"Runtime Python not found: {executable}")
        return [str(executable)]
    executable = shutil.which(args.specify)
    if not executable:
        raise ValueError("specify is not installed/on PATH; install Spec Kit >=1.0.1, "
                         "or pass --specify /path/to/specify. Nothing was changed.")
    launcher = Path(executable).resolve()
    with launcher.open("rb") as handle:
        first_line = handle.readline(4096).decode("utf-8", errors="replace").strip()
    if not first_line.startswith("#!"):
        raise ValueError("Cannot discover specify's Python from its launcher; "
                         "pass --runtime-python with that installation's interpreter.")
    command = shlex.split(first_line[2:].strip())
    if command and Path(command[0]).name == "env":
        command = command[1:]
        if command and command[0] == "-S":
            command = command[1:]
        if command:
            resolved = shutil.which(command[0])
            if resolved:
                command[0] = resolved
    if not command or "python" not in Path(command[0]).name.lower():
        raise ValueError("Unsupported specify launcher; pass --runtime-python "
                         "with the Python that can import its specify_cli package.")
    return command


def forbid_writes(event: str, values: tuple) -> None:
    """Keep renderer/library calls read-only, including Python import caches."""
    if event == "open":
        _path, mode, flags = values
        writing = isinstance(mode, str) and any(char in mode for char in "wax+")
        writing |= isinstance(flags, int) and bool(
            flags & (os.O_WRONLY | os.O_RDWR | os.O_CREAT | os.O_TRUNC | os.O_APPEND)
        )
        if writing:
            raise PermissionError("Verification refused a filesystem write.")
    if event in {
        "os.mkdir", "os.remove", "os.rmdir", "os.rename", "os.link", "os.symlink",
        "os.chmod", "os.chown", "os.utime", "os.truncate", "shutil.copyfile",
        "shutil.copymode", "shutil.copystat", "shutil.rmtree", "subprocess.Popen",
        "os.system", "os.exec", "os.posix_spawn",
    }:
        raise PermissionError(f"Verification refused mutating/executing operation: {event}")


class Checks:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.count = 0

    def require(self, condition: bool, message: str) -> bool:
        self.count += 1
        if not condition:
            self.errors.append(message)
        return bool(condition)

    def read_json(self, path: Path) -> dict:
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            raise ValueError(f"Expected a JSON object: {path}")
        return data

    def read(self, path: Path) -> str:
        if not path.is_file() or path.is_symlink():
            raise ValueError(f"Missing/non-regular file: {path}")
        return path.read_text(encoding="utf-8")

    def tree(self, root: Path) -> dict[str, bytes]:
        if not root.is_dir() or root.is_symlink():
            raise ValueError(f"Missing/non-regular directory: {root}")
        result = {}
        for path in sorted(root.rglob("*")):
            if path.is_symlink():
                raise ValueError(f"Unexpected symlink: {path}")
            if path.is_file():
                result[path.relative_to(root).as_posix()] = path.read_bytes()
        return result

    def stage(self, label: str, operation) -> None:
        try:
            operation()
        except Exception as exc:
            self.errors.append(f"{label}: {exc}")

    def finish(self, runtime_version: str, *, preflight: bool = False) -> int:
        if self.errors:
            print(f"FAIL: {len(self.errors)} problem(s).")
            for problem in self.errors:
                print(f"  - {problem}")
            return 1
        scope = "source/copy, resolution and workflow preflight" if preflight else (
            "10 commands, 3 templates and materialized skills/workflow"
        )
        print(f"OK: {PRESET_ID}, {scope}; Claude, Spec Kit {runtime_version}. "
              f"Read-only checks ({self.count}).")
        return 0


def verify(args: argparse.Namespace, *, protect: bool = True) -> int:
    # Import from the actual CLI environment, not a second user/global install.
    sys.dont_write_bytecode = True
    if protect:
        sys.addaudithook(forbid_writes)
    try:
        import yaml
        from packaging.specifiers import SpecifierSet
        from packaging.version import Version
        from specify_cli import get_speckit_version
        from specify_cli.agents import CommandRegistrar
        from specify_cli.integrations import get_integration
        from specify_cli.presets import PresetManager, PresetManifest, PresetResolver
        try:
            # Spec Kit 1.2 moved this domain from "overlays" to "overlay";
            # both expose the same pure resolver/layer interface. Do not hide
            # missing transitive dependencies behind the compatibility fallback.
            from specify_cli.workflows.overlay import WorkflowResolver
        except ModuleNotFoundError as exc:
            if exc.name != "specify_cli.workflows.overlay":
                raise
            from specify_cli.workflows.overlays import WorkflowResolver
    except Exception as exc:
        print(f"FAIL: Cannot load the installed specify runtime: {exc}. "
              "Use --runtime-python from a Spec Kit >=1.0.1 installation.")
        return 2

    runtime_version = str(get_speckit_version())
    if Version(runtime_version) < Version(MINIMUM_VERSION):
        print(f"FAIL: Spec Kit {runtime_version} is unsupported; require >=1.0.1. "
              "Nothing was updated.")
        return 2

    root = args.project_root.expanduser().resolve()
    source_root = (args.source_root or root / "tools" / "speckit").expanduser().resolve()
    source = source_root / "presets" / PRESET_ID
    installed = root / ".specify" / "presets" / PRESET_ID
    checks = Checks()

    def mapping_yaml(path: Path) -> dict:
        value = yaml.safe_load(checks.read(path))
        if not isinstance(value, dict):
            raise ValueError(f"Expected a YAML mapping: {path}")
        return value

    def check_integration() -> None:
        options = checks.read_json(root / ".specify" / "init-options.json")
        integration = checks.read_json(root / ".specify" / "integration.json")
        active = integration.get("default_integration", integration.get("integration"))
        if options.get("ai") != "claude" or active != "claude":
            raise ValueError(
                f"Only active Claude is verified (init ai={options.get('ai')!r}, "
                f"active={active!r}). Other integrations are unverified; none was switched."
            )
        checks.require("claude" in integration.get("installed_integrations", []),
                       "Claude is absent from installed_integrations; repair integration state.")
        commands_dir = root / ".claude" / "commands"
        for stem in COMMANDS:
            for filename in (f"speckit.{stem}.md", f"speckit-{stem}.md"):
                duplicate = commands_dir / filename
                checks.require(not duplicate.exists(),
                               f"Legacy duplicate command: {duplicate.relative_to(root)}. "
                               "This preset natively generates skills only; review/remove "
                               "the legacy command so it cannot bypass the preset. "
                               "The checker will not remove it.")

    checks.stage("Integration", check_integration)
    if checks.errors:
        return checks.finish(runtime_version)

    def check_preset() -> None:
        manifest = PresetManifest(source / "preset.yml")
        checks.require(manifest.id == PRESET_ID, f"Source preset ID must be {PRESET_ID}.")
        required_version = SpecifierSet(manifest.requires_speckit_version)
        checks.require(Version(runtime_version) in required_version,
                       f"Runtime {runtime_version} does not satisfy source requirement "
                       f"{manifest.requires_speckit_version}; use a compatible runtime.")
        checks.require(Version("1.0.0") not in required_version,
                       "preset.yml must require at least Spec Kit 1.0.1.")

        expected_names = {("command", f"speckit.{name}") for name in COMMANDS}
        expected_names |= {("template", name) for name in TEMPLATES}
        entries = {(entry["type"], entry["name"]): entry for entry in manifest.templates}
        if not checks.require(set(entries) == expected_names,
                              "preset.yml must provide exactly 10 project commands and "
                              "spec/plan/tasks templates; review its provides.templates."):
            return
        for entry in entries.values():
            checks.require(entry.get("strategy", "replace") == "replace",
                           f"Unsupported composition for {entry['name']}; this checker "
                           "supports the project's explicit replace strategy only.")

        original = checks.tree(source)
        materialized = checks.tree(installed)
        for relative in sorted(original.keys() | materialized.keys()):
            checks.require(original.get(relative) == materialized.get(relative),
                           f"Preset copy drift: {relative}. Reinstall from the reviewed "
                           "tools/speckit source; do not edit installed copies.")
        registry = checks.read_json(root / ".specify" / "presets" / ".registry")
        state = registry.get("presets", {}).get(PRESET_ID)
        if not isinstance(state, dict):
            raise ValueError(f"Preset {PRESET_ID} is not registered; install its local source.")
        checks.require(state.get("enabled") is True,
                       "Project preset is disabled; enable the reviewed installed preset.")
        checks.require(state.get("version") == manifest.version,
                       "Registry preset version differs from source; reinstall the preset.")
        checks.require(state.get("manifest_hash") == manifest.get_hash(),
                       "Registry manifest hash differs from source; reinstall the preset.")

        resolver = PresetResolver(root)
        registrar = CommandRegistrar()
        integration = get_integration("claude")
        if integration is None:
            raise ValueError("Installed runtime cannot load its Claude integration.")
        for (kind, name), entry in sorted(entries.items()):
            expected_path = (installed / entry["file"]).resolve()
            layers = resolver.collect_all_layers(name, kind)
            resolved = resolver.resolve(name, kind)
            owns_resolution = bool(layers) and resolved is not None
            owns_resolution = owns_resolution and layers[0]["path"].resolve() == expected_path
            owns_resolution = owns_resolution and resolved.resolve() == expected_path
            owns_resolution = owns_resolution and layers[0]["strategy"] == "replace"
            if not checks.require(owns_resolution,
                                  f"Resolution drift for {name}: winner is "
                                  f"{resolved or 'missing'}. Remove/review competing overrides "
                                  "or priorities so the project preset wins."):
                continue
            content = checks.read(source / entry["file"])
            checks.require(resolver.resolve_content(name, kind) == content,
                           f"Effective content differs for {name}; inspect preset layers.")
            if kind == "command" and not args._preflight:
                check_skill(name, content, registrar, integration, state)

    def check_skill(name, content, registrar, integration, state) -> None:
        # These are the pure transformations used by PresetManager._register_skills
        # in Spec Kit 1.0.1/1.2.0. Do not call registration/reconciliation methods:
        # they write. The 1.2 refactor keeps these helpers on PresetManager.
        frontmatter, body = registrar.parse_frontmatter(content)
        if not frontmatter.get("description"):
            raise ValueError(f"Command {name} needs an explicit description in its source.")
        body = registrar.resolve_skill_placeholders("claude", frontmatter, body, root)
        body = PresetManager._resolve_skill_command_refs(body, registrar, "claude", root)
        modern, legacy = PresetManager._skill_names_for_command(name)
        targets = [modern]
        if (root / ".claude" / "skills" / legacy).exists():
            targets.append(legacy)
        registered = state.get("registered_skills", {}).get("claude", [])
        checks.require(modern in registered,
                       f"Registry lacks Claude skill {modern}; re-register the preset.")
        for skill_name in targets:
            expected_fm = registrar.build_skill_frontmatter(
                "claude", skill_name, frontmatter["description"], f"preset:{PRESET_ID}"
            )
            registrar.apply_argument_hint(frontmatter, expected_fm, integration)
            title = PresetManager._skill_title_from_command(name)
            expected = registrar.render_frontmatter(expected_fm)
            expected += f"\n# Speckit {title} Skill\n\n{body}\n"
            expected = integration.post_process_skill_content(expected)
            expected_fm, expected_body = registrar.parse_frontmatter(expected)
            path = root / ".claude" / "skills" / skill_name / "SKILL.md"
            actual_fm, actual_body = registrar.parse_frontmatter(checks.read(path))
            checks.require(actual_fm == expected_fm,
                           f"Skill metadata/flags drift: {path.relative_to(root)}. "
                           "Re-register from the source preset; verify metadata.source "
                           "and Claude invocation flags.")
            if actual_body != expected_body:
                changed = next((line for line in difflib.unified_diff(
                    expected_body.splitlines(), actual_body.splitlines(), n=0
                ) if line.startswith("@@")), "body differs")
                checks.require(False,
                               f"Rendered skill body drift: {path.relative_to(root)} "
                               f"({changed}). Re-register; do not patch generated skills.")
            else:
                checks.require(True, "")

    def check_workflow() -> None:
        source_file = source_root / "workflows" / WORKFLOW_ID / "workflow.yml"
        target_file = root / ".specify" / "workflows" / WORKFLOW_ID / "workflow.yml"
        text = checks.read(source_file)
        checks.require(checks.read(target_file) == text,
                       "Installed preparation workflow differs from source; reinstall "
                       "the local demons-preparation workflow.")
        workflow = mapping_yaml(source_file)
        metadata = workflow.get("workflow", {})
        checks.require(metadata.get("id") == WORKFLOW_ID,
                       f"Workflow source ID must be {WORKFLOW_ID}.")
        registry = checks.read_json(root / ".specify" / "workflows" / "workflow-registry.json")
        state = registry.get("workflows", {}).get(WORKFLOW_ID)
        if not isinstance(state, dict):
            raise ValueError("Preparation workflow is not registered; install its local source.")
        checks.require(state.get("source") not in (None, "bundled"),
                       "Project workflow must be registered from local source, not bundled.")
        checks.require(state.get("enabled", True) is True,
                       "Preparation workflow is disabled; review its registry state.")
        checks.require(state.get("version") == metadata.get("version"),
                       "Workflow registry version differs from source; reinstall it.")
        # Reject active overlays instead of certifying the unchanged base while
        # an overlay silently changes the workflow users would actually run.
        layers = WorkflowResolver(root).collect_all_layers(WORKFLOW_ID)
        overlays = [layer.source for layer in layers if layer.tier != "base"]
        checks.require(not overlays,
                       f"Unverified active workflow overlays: {overlays}. Review/disable "
                       "them before verification; this checker never removes overlays.")
        checks.require(len([layer for layer in layers if layer.tier == "base"]) == 1,
                       "Preparation workflow has no unique installed base layer.")
        steps = workflow.get("steps")
        if not isinstance(steps, list):
            raise ValueError("Workflow needs a steps list.")
        sequence = []
        for step in steps:
            if not isinstance(step, dict):
                raise ValueError("Workflow contains a non-mapping step.")
            if "command" in step:
                sequence.append(step["command"])
                checks.require(step.get("type", "command") == "command",
                               "Workflow command step has an unsupported execution type.")
                checks.require(set(step) <= {"id", "type", "command", "integration", "input"},
                               "Workflow command has extra execution/flow keys; review source.")
            else:
                sequence.append("gate")
                checks.require(step.get("type") == "gate",
                               "Workflow may contain only preparation commands and gates.")
                checks.require(set(step) <= {
                    "id", "type", "message", "options", "on_reject"
                }, "Workflow gate has unsupported execution/flow keys; review source.")
                checks.require(step.get("on_reject") == "abort",
                               "Preparation gates must abort on rejection.")
        checks.require(sequence == [
            "speckit.specify", "gate", "speckit.plan", "gate", "speckit.tasks", "gate"
        ], "Workflow must stop after specify/plan/tasks and their review gates; "
           "implementation, test execution or agent steps are not allowed here.")

    checks.stage("Preset/resolution/rendered skills", check_preset)
    checks.stage("Preparation workflow", check_workflow)
    return checks.finish(runtime_version, preflight=args._preflight)


def reapply(args: argparse.Namespace) -> int:
    """Explicit, narrowly scoped recovery using the existing native registration."""
    if not args.reapply:
        print("FAIL: Recovery requires explicit --reapply.")
        return 2
    args._preflight = True
    if verify(args, protect=False):
        return 1
    root = args.project_root.expanduser().resolve()
    state = json.loads((root / ".specify/presets/.registry").read_text(encoding="utf-8"))
    enabled = {
        key for key, entry in state.get("presets", {}).items()
        if isinstance(entry, dict) and entry.get("enabled", True)
    }
    if enabled != {PRESET_ID}:
        print("FAIL: --reapply supports only the project's single enabled preset. "
              f"Enabled presets: {sorted(enabled)}. Review/reapply other presets separately.")
        return 1

    generated_dirs = [root / ".claude/skills" / f"speckit-{name}" for name in COMMANDS]
    generated_dirs += [root / ".claude/skills" / f"speckit.{name}" for name in COMMANDS]
    registry = root / ".specify/presets/.registry"
    parents = {root / ".claude", root / ".claude/skills", root / ".specify",
               root / ".specify/presets"}

    def allowed(path, *, mkdir: bool = False) -> bool:
        # Native atomic output writers may reopen their already-created fd.
        if isinstance(path, int):
            return True
        candidate = Path(os.fsdecode(path)).resolve()
        if mkdir and candidate in parents:
            return True
        return candidate == registry or any(
            candidate == directory or directory in candidate.parents
            for directory in generated_dirs
        )

    def protect_recovery(event: str, values: tuple) -> None:
        if event == "open":
            path, mode, flags = values
            writing = isinstance(mode, str) and any(char in mode for char in "wax+")
            writing |= isinstance(flags, int) and bool(flags & (
                os.O_WRONLY | os.O_RDWR | os.O_CREAT | os.O_TRUNC | os.O_APPEND
            ))
            if writing and not allowed(path):
                raise PermissionError(f"Recovery refused a write outside generated skills/registry: {path}")
        elif event == "os.rename":
            if not allowed(values[0]) or not allowed(values[1]):
                raise PermissionError("Recovery refused a rename outside generated skills/registry.")
        elif event in {"os.mkdir", "os.remove", "os.rmdir", "os.chmod", "os.chown",
                       "os.utime", "os.truncate", "shutil.rmtree"}:
            if not allowed(values[0], mkdir=event == "os.mkdir"):
                raise PermissionError(f"Recovery refused filesystem operation: {event} {values[0]}")
        elif event in {"os.link", "os.symlink", "subprocess.Popen", "os.system",
                       "os.exec", "os.posix_spawn"}:
            raise PermissionError(f"Recovery refused operation: {event}")

    from specify_cli.presets import PresetManager
    sys.addaudithook(protect_recovery)
    PresetManager(root).register_enabled_presets_for_agent("claude")
    print("Reapplied the unchanged installed preset to Claude outputs. "
          "Sources, core manifests and workflows were not updated; checking final outputs.")
    return 0


def main() -> int:
    args = arguments()
    if args._reapply_runtime:
        try:
            return reapply(args)
        except Exception as exc:
            print(f"FAIL: Explicit recovery could not complete: {exc}. "
                  "Run the default read-only checker to inspect remaining drift.")
            return 2
    if args._runtime:
        try:
            return verify(args)
        except Exception as exc:
            print(f"FAIL: Runtime verification could not complete: {exc}. "
                  "Renderer APIs may have changed; update this checker before certifying outputs.")
            return 2
    try:
        command = runtime_command(args)
        command += ["-B", str(Path(__file__).resolve()), *sys.argv[1:]]
        environment = dict(os.environ, PYTHONDONTWRITEBYTECODE="1")
        if args.reapply:
            result = subprocess.run(command + ["--_reapply-runtime"], env=environment,
                                    check=False, timeout=60)
            if result.returncode:
                return result.returncode
        return subprocess.run(command + ["--_runtime"], env=environment,
                              check=False, timeout=60).returncode
    except (OSError, ValueError, subprocess.TimeoutExpired) as exc:
        print(f"FAIL: {exc}")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
