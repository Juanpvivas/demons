#!/usr/bin/env python3
"""Verify native package signatures and preset metadata before distribution."""

import argparse
import configparser
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import zipfile


def preset_options(path: Path, platform: str) -> dict[str, str]:
    config = configparser.ConfigParser(interpolation=None)
    with path.open(encoding="utf-8") as stream:
        config.read_file(stream)
    presets = [section for section in config.sections()
               if re.fullmatch(r"preset\.\d+", section)
               and json.loads(config[section]["platform"]).lower() == platform]
    if len(presets) != 1:
        raise ValueError(f"Se requiere un único preset para {platform}.")
    keys = (("package/unique_name", "version/code", "version/name")
            if platform == "android" else
            ("application/bundle_identifier", "application/short_version", "application/version"))
    options = config[presets[0] + ".options"]
    return {key: str(json.loads(options[key])) for key in keys}


def require_metadata(actual: dict, expected: dict) -> None:
    for key, value in expected.items():
        if not value or actual.get(key) != value:
            raise ValueError(
                f"Metadato {key} distinto del preset: "
                f"esperado {value!r}, recibido {actual.get(key)!r}.")


def run_tool(command: list[str]) -> str:
    result = subprocess.run(command, check=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, errors="replace")
    return result.stdout


def verify_android(artifact: Path, options: dict, build_tools: Path) -> None:
    expected_certificate = os.environ.get("DEMONS_ANDROID_CERT_SHA256")
    if expected_certificate is not None:
        expected_certificate = expected_certificate.replace(":", "").strip().lower()
        if re.fullmatch(r"[0-9a-f]{64}", expected_certificate) is None:
            raise ValueError("DEMONS_ANDROID_CERT_SHA256 debe contener una huella SHA-256 válida.")
    certificates = run_tool([
        str(build_tools / "apksigner"), "verify", "--print-certs", str(artifact)])
    if expected_certificate is not None:
        # Count every leaf digest line before validating it, including malformed values.
        signers = re.findall(
            r"^Signer #\d+ certificate SHA-256 digest:([^\r\n]*)",
            certificates, re.MULTILINE)
        if len(signers) != 1:
            raise ValueError("El APK debe contener exactamente un certificado firmante SHA-256.")
        actual_certificate = signers[0].replace(":", "").strip().lower()
        if (re.fullmatch(r"[0-9a-f]{64}", actual_certificate) is None
                or actual_certificate != expected_certificate):
            raise ValueError("El certificado firmante del APK no coincide con la firma Android esperada.")
    badging = run_tool([str(build_tools / "aapt2"), "dump", "badging", str(artifact)])
    package = re.search(r"^package:\s+(.+)$", badging, re.MULTILINE)
    if package is None:
        raise ValueError("El APK no contiene metadatos de paquete legibles.")
    metadata = dict(re.findall(r"(\w+)='([^']*)'", package.group(1)))
    require_metadata(metadata, {
        "name": options["package/unique_name"],
        "versionCode": options["version/code"],
        "versionName": options["version/name"],
    })


def extract_ipa(artifact: Path, destination: Path) -> Path:
    with zipfile.ZipFile(artifact) as archive:
        seen = set()
        for entry in archive.infolist():
            relative = PurePosixPath(entry.filename)
            mode = entry.external_attr >> 16
            if (relative.is_absolute() or ".." in relative.parts
                    or "\\" in entry.filename or not relative.parts
                    or relative in seen or stat.S_ISLNK(mode)
                    or (stat.S_IFMT(mode) not in (0, stat.S_IFREG, stat.S_IFDIR))):
                raise ValueError(f"Entrada IPA insegura o repetida: {entry.filename!r}.")
            seen.add(relative)
            target = destination.joinpath(*relative.parts)
            if entry.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(entry) as source, target.open("xb") as output:
                    shutil.copyfileobj(source, output)
                # Preserve executable bits without restoring privileged permissions.
                if mode & 0o777:
                    target.chmod(mode & 0o777)
    apps = list((destination / "Payload").glob("*.app"))
    if len(apps) != 1 or not apps[0].is_dir():
        raise ValueError("El IPA debe contener una única app en Payload/.")
    return apps[0]


def verify_ios(artifact: Path, options: dict) -> None:
    with tempfile.TemporaryDirectory(prefix="demons-ipa-verify-") as directory:
        app = extract_ipa(artifact, Path(directory))
        run_tool(["codesign", "--verify", "--deep", "--strict", str(app)])
        with (app / "Info.plist").open("rb") as stream:
            metadata = plistlib.load(stream)
        require_metadata(metadata, {
            "CFBundleIdentifier": options["application/bundle_identifier"],
            "CFBundleShortVersionString": options["application/short_version"],
            "CFBundleVersion": options["application/version"],
        })


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("platform", choices=("android", "ios"))
    parser.add_argument("artifact", type=Path)
    parser.add_argument("--presets", type=Path, default=Path("export_presets.cfg"))
    parser.add_argument("--build-tools", type=Path)
    args = parser.parse_args()
    if args.platform == "android" and args.build_tools is None:
        parser.error("Android requiere --build-tools.")
    try:
        if not args.artifact.is_file() or args.artifact.stat().st_size == 0:
            raise ValueError("El artefacto no existe o está vacío.")
        options = preset_options(args.presets, args.platform)
        if args.platform == "android":
            verify_android(args.artifact, options, args.build_tools)
        else:
            verify_ios(args.artifact, options)
    except subprocess.CalledProcessError as error:
        print(f"Verificación nativa fallida: {error.cmd[0]} terminó con "
              f"código {error.returncode}.\n{error.stdout}", file=sys.stderr)
        return 1
    except (OSError, ValueError, KeyError, configparser.Error, zipfile.BadZipFile,
            RuntimeError, plistlib.InvalidFileException) as error:
        print(f"Verificación nativa fallida: {error}", file=sys.stderr)
        return 1
    print(f"Artefacto {args.platform}: firma, empaquetado y versión verificados.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
