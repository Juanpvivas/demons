#!/usr/bin/env bash
# Genera el paquete Web para carga manual. No publica ni distribuye a testers.
set -euo pipefail

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(CDPATH='' cd -- "$SCRIPT_DIR/../.." && pwd -P)"
BUILD_DIR="$REPO_ROOT/build"
WEB_DIR="$BUILD_DIR/web"
GODOT_WEB_BIN="${GODOT_WEB_BIN:-godot}"

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

for dependency in python3 git tee; do
    command -v "$dependency" >/dev/null 2>&1 || fail "Falta $dependency."
done
GODOT_PATH="$(command -v "$GODOT_WEB_BIN")" || fail 'Configura GODOT_WEB_BIN con Godot estandar 4.7.1.'
GODOT_PATH="$(python3 -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "$GODOT_PATH")"
GODOT_VERSION="$("$GODOT_PATH" --version)" || fail 'No se pudo consultar la version de Godot.'
[[ "$GODOT_VERSION" =~ ^4\.7\.1\.stable\.official\.[0-9a-f]+$ ]] || fail "Se requiere Godot estandar oficial 4.7.1; se encontro: $GODOT_VERSION"

# Limpiar solo salidas conocidas; rechazar symlinks antes de borrar/escribir.
# .gdignore debe existir ANTES de importar para evitar sidecars en el export.
python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import shutil
import sys

root = Path(sys.argv[1])
build = root / 'build'
if build.is_symlink() or (build.exists() and not build.is_dir()):
    raise SystemExit('Error: build debe ser un directorio local, no un enlace.')
build.mkdir(exist_ok=True)
ignore = build / '.gdignore'
if ignore.is_symlink() or (ignore.exists() and not ignore.is_file()):
    raise SystemExit('Error: build/.gdignore no es un archivo local seguro.')
ignore.write_text('', encoding='utf-8')
web = build / 'web'
if web.is_symlink() or (web.exists() and not web.is_dir()):
    raise SystemExit('Error: build/web debe ser un directorio local, no un enlace.')
for name in ('demons-web.zip', 'web-manifest.json', 'web-import.log', 'web-export.log'):
    target = build / name
    if target.is_symlink() or (target.exists() and not target.is_file()):
        raise SystemExit(f'Error: salida insegura: build/{name}')
    target.unlink(missing_ok=True)
if web.exists():
    shutil.rmtree(web)
web.mkdir()
for name in ('GODOT_LICENSE.txt', 'GODOT_COPYRIGHT.txt', 'NOTICE.txt'):
    source = root / 'tools' / 'web' / 'licenses' / name
    if source.is_symlink() or not source.is_file() or source.stat().st_size == 0:
        raise SystemExit(f'Error: falta aviso de distribucion: {name}')
PY

printf 'Importando con Godot %s...\n' "$GODOT_VERSION"
"$GODOT_PATH" --headless --path "$REPO_ROOT" --editor --import 2>&1 | tee "$BUILD_DIR/web-import.log"
printf 'Exportando Web release...\n'
"$GODOT_PATH" --headless --path "$REPO_ROOT" --export-release Web "$WEB_DIR/index.html" 2>&1 | tee "$BUILD_DIR/web-export.log"

python3 - "$REPO_ROOT" "$GODOT_VERSION" <<'PY'
from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import sys
import zipfile

root = Path(sys.argv[1])
engine_version = sys.argv[2]
build = root / 'build'
web = build / 'web'
for name in ('web-import.log', 'web-export.log'):
    log = (build / name).read_text(encoding='utf-8', errors='replace')
    if any(line.lstrip().startswith(('ERROR:', 'SCRIPT ERROR:')) for line in log.splitlines()):
        raise SystemExit(f'Error: Godot registro errores; revisar build/{name}.')
required = ('index.html', 'index.js', 'index.wasm', 'index.pck')
for name in required:
    path = web / name
    if path.is_symlink() or not path.is_file() or path.stat().st_size == 0:
        raise SystemExit(f'Error: export incompleto, falta {name}. Revisar build/web-export.log.')

# Los sidecars no forman parte de la salida Web; nunca incluirlos en el ZIP.
allowed_suffixes = {'.html', '.js', '.wasm', '.pck', '.png', '.ico', '.svg'}
for path in web.iterdir():
    if path.is_symlink():
        raise SystemExit(f'Error: enlace inesperado en export: {path.name}')
    if path.is_file() and (path.suffix in {'.import', '.uid'} or path.name == '.DS_Store'):
        path.unlink()
        continue
    if not path.is_file() or not path.name.startswith('index') or path.suffix not in allowed_suffixes:
        raise SystemExit(f'Error: archivo inesperado en export: {path.name}')

licenses = web / 'licenses'
licenses.mkdir()
for name in ('GODOT_LICENSE.txt', 'GODOT_COPYRIGHT.txt', 'NOTICE.txt'):
    shutil.copyfile(root / 'tools' / 'web' / 'licenses' / name, licenses / name)


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def git(*args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True).strip()


files = sorted(path for path in web.rglob('*') if path.is_file())
if len(files) > 1000:
    raise SystemExit('Error: el paquete excede 1000 archivos.')
if sum(path.stat().st_size for path in files) > 500_000_000:
    raise SystemExit('Error: el paquete excede 500 MB extraidos.')
for path in files:
    relative = path.relative_to(web).as_posix()
    if len(relative) > 240 or path.stat().st_size > 200_000_000:
        raise SystemExit(f'Error: el archivo excede los limites de itch.io: {relative}')

archive = build / 'demons-web.zip'
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
    for path in files:
        entry = zipfile.ZipInfo(path.relative_to(web).as_posix(), date_time=(1980, 1, 1, 0, 0, 0))
        entry.compress_type = zipfile.ZIP_DEFLATED
        entry.create_system = 3
        entry.external_attr = 0o100644 << 16
        with path.open('rb') as source, package.open(entry, 'w') as target:
            shutil.copyfileobj(source, target)

revision = git('rev-parse', 'HEAD')
dirty = bool(git('status', '--porcelain', '--untracked-files=normal'))
describe = git('describe', '--tags', '--always')
build_version = describe + ('-wip' if dirty else '')
preset_text = (root / 'export_presets.cfg').read_text(encoding='utf-8')
web_preset = re.search(r'\[preset\.(\d+)\]\s*\n\s*name="Web"(.*?)(?=\[preset\.|\Z)', preset_text, re.S)
if web_preset is None:
    raise SystemExit('Error: no se encuentra el preset Web para registrar su politica.')
exclude = re.search(r'^exclude_filter="([^"]*)"', web_preset.group(2), re.M)
manifest = {
    'schema_version': 1,
    'generated_at_utc': datetime.now(timezone.utc).isoformat(),
    'build_version': build_version,
    'source_revision': revision,
    'source_dirty': dirty,
    'godot_version': engine_version,
    'export_preset': 'Web',
    'export_mode': 'release',
    'entrypoint': 'index.html',
    'rendering_method': 'gl_compatibility',
    'threads': False,
    'extensions': False,
    'pwa': False,
    'excluded_resource_patterns': exclude.group(1).split(',') if exclude else [],
    'pck_content_validation': 'Requiere inspeccion del tester; la lista exterior no valida el contenido del PCK.',
    'license_files': [path.relative_to(web).as_posix() for path in sorted(licenses.iterdir())],
    'files': [
        {'path': path.relative_to(web).as_posix(), 'size_bytes': path.stat().st_size, 'sha256': sha256(path)}
        for path in files
    ],
    'uncompressed_size_bytes': sum(path.stat().st_size for path in files),
    'archive': {'path': archive.name, 'size_bytes': archive.stat().st_size, 'sha256': sha256(archive)},
}
(build / 'web-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Paquete: build/demons-web.zip')
print('Manifiesto: build/web-manifest.json')
print(f'Revision: {revision}; WIP: {dirty}; ZIP: {archive.stat().st_size} bytes')
PY
