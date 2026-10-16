#!/usr/bin/env python3
"""Import the project and require a successful, nonempty GUT run for CI."""

import argparse
from pathlib import Path
import re
import subprocess
import sys


ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
ENGINE_ERROR = re.compile(r"^\s*(?:SCRIPT )?ERROR:", re.MULTILINE)


def run(command: list[str], project: Path) -> tuple[int, str]:
    result = subprocess.run(
        command, cwd=project, stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT, text=True, errors="replace",
    )
    sys.stdout.write(result.stdout)
    sys.stdout.flush()
    output = ANSI.sub("", result.stdout)
    return result.returncode or int(bool(ENGINE_ERROR.search(output))), output


def passed_summary(output: str) -> bool:
    if "= Run Summary" not in output:
        return False
    summary = output.rsplit("= Run Summary", 1)[1]
    tests = re.findall(r"^Tests\s+(\d+)\s*$", summary, re.MULTILINE)
    passing = re.findall(r"^Passing Tests\s+(\d+)\s*$", summary, re.MULTILINE)
    failures = re.search(
        r"^(?:Errors|Failing Tests|Risky/Pending)\s+[1-9]\d*\s*$|^Asserts\s+\d+/\d+\s*$",
        summary, re.MULTILINE,
    )
    return (
        len(tests) == len(passing) == 1 and int(tests[0]) > 0
        and tests == passing and failures is None
        and re.search(r"^---- All tests passed! ----\s*$", summary, re.MULTILINE) is not None
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[2])
    args = parser.parse_args()
    project = args.project.resolve()
    command = [args.godot, "--headless", "--path", str(project)]
    try:
        code, _ = run(command + ["--editor", "--import"], project)
        if code:
            print("CI GUT: la importación falló; no se ejecuta la suite.", file=sys.stderr)
            return code
        code, output = run(command + [
            "-s", "addons/gut/gut_cmdln.gd", "-gdir=res://tests/unit",
            "-ginclude_subdirs=true", "-gexit",
        ], project)
    except OSError as error:
        print(f"CI GUT: no se pudo ejecutar Godot: {error}", file=sys.stderr)
        return 1
    if code or not passed_summary(output):
        print("CI GUT: errores o resumen de pruebas incompleto/fallido.", file=sys.stderr)
        return code or 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
