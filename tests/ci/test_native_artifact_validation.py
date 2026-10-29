"""Execute publication checks offline against signed/metadata tool fixtures.

The actual workflow run steps and repository verifier run in temporary folders.
No credential, Godot export, connected device or distribution service is used.
"""

import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest
import zipfile

from test_publication_policy import ROOT, TARGETS, Workflow, scalar


FAKE_TOOL = r'''import json, os, pathlib, sys
tool = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with pathlib.Path(os.environ['NATIVE_CALLS']).open('a') as stream:
    stream.write(json.dumps({'tool': tool, 'args': args}) + '\n')
if tool in ('apksigner', 'codesign'):
    if '--verify' not in args and 'verify' not in args:
        print('Fixture requires a signature verification invocation', file=sys.stderr)
        sys.exit(12)
    if os.environ.get('NATIVE_BAD_SIGNATURE') == '1':
        print('Invalid fixture signature', file=sys.stderr)
        sys.exit(8)
    print('Signature verified')
elif tool == 'aapt2':
    if args[:2] != ['dump', 'badging']:
        print('Unsupported metadata query', file=sys.stderr)
        sys.exit(13)
    data = json.loads(os.environ['NATIVE_APK_METADATA'])
    print("package: name='{}' versionCode='{}' versionName='{}'".format(
        data.get('package', ''), data.get('code', ''), data.get('name', '')))
'''

FAKE_GODOT = r'''import json, os, pathlib, sys
phase = 'import' if '--import' in sys.argv else 'export'
with pathlib.Path(os.environ['NATIVE_CALLS']).open('a') as stream:
    stream.write(json.dumps({'phase': phase, 'ignored_build': pathlib.Path('build/.gdignore').is_file()}) + '\n')
if os.environ.get('NATIVE_ENGINE_ERROR_PHASE') == phase:
    print(os.environ['NATIVE_ENGINE_ERROR'], file=sys.stderr)
sys.exit(int(os.environ.get('NATIVE_ENGINE_EXIT', '0')) if os.environ.get('NATIVE_ENGINE_ERROR_PHASE') == phase else 0)
'''


def run_command(step):
    raw, children = step['run']
    if raw in ('|', '|-'):
        return textwrap.dedent('\n'.join(children)).strip()
    return scalar(step['run'])


class NativeArtifactValidationTests(unittest.TestCase):
    def workflow(self, platform):
        _, filename, job, _, _ = next(item for item in TARGETS if item[0] == platform)
        return Workflow(filename, job)

    def verifier_step(self, platform):
        workflow = self.workflow(platform)
        steps = [(index, step) for index, step in enumerate(workflow.steps)
                 if 'run' in step and 'verify_native_artifact.py' in scalar(step['run'])]
        self.assertEqual(len(steps), 1,
                         f'{platform}: expected one executable native artifact verification step before upload')
        return workflow, steps[0]

    def workspace(self, directory):
        root = Path(directory)
        (root / 'tools').mkdir()
        shutil.copytree(ROOT / 'tools/ci', root / 'tools/ci')
        (root / 'export_presets.cfg').write_text(
            '[preset.0]\nname="Android"\nplatform="Android"\n'
            '[preset.0.options]\nversion/code=4\nversion/name="1.0.1"\n'
            'package/unique_name="com.juanpvivas.demons"\n'
            '[preset.1]\nname="iOS"\nplatform="iOS"\n'
            '[preset.1.options]\napplication/version="4"\n'
            'application/short_version="1.0.1"\n'
            'application/bundle_identifier="com.juanpvivas.demons"\n')
        bindir = root / 'bin'
        tools = root / 'sdk/build-tools/34.0.0'
        tools.mkdir(parents=True)
        bindir.mkdir()
        for directory, names in [(tools, ('aapt2', 'apksigner')), (bindir, ('codesign',))]:
            for name in names:
                path = directory / name
                path.write_text(f'#!{sys.executable}\n' + FAKE_TOOL)
                path.chmod(0o755)
        godot = bindir / 'godot'
        godot.write_text(f'#!{sys.executable}\n' + FAKE_GODOT)
        godot.chmod(0o755)
        env = os.environ.copy()
        env.update({
            'PATH': str(bindir) + os.pathsep + os.environ['PATH'],
            'ANDROID_HOME': str(root / 'sdk'),
            'ANDROID_SDK_ROOT': str(root / 'sdk'),
            'RUNNER_TEMP': str(root / 'runner'),
            'NATIVE_CALLS': str(root / 'calls.jsonl'),
            'NATIVE_APK_METADATA': json.dumps({
                'package': 'com.juanpvivas.demons', 'code': '4', 'name': '1.0.1'}),
        })
        return root, env

    def calls(self, root):
        path = root / 'calls.jsonl'
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def invoke_verifier(self, platform, *, apk_metadata=None, ios_metadata=None,
                        bad_signature=False, additional_entries=None):
        _, (_, step) = self.verifier_step(platform)
        with tempfile.TemporaryDirectory(prefix='demons-native-check-') as directory:
            root, env = self.workspace(directory)
            if apk_metadata is not None:
                env['NATIVE_APK_METADATA'] = json.dumps(apk_metadata)
            env['NATIVE_BAD_SIGNATURE'] = '1' if bad_signature else '0'
            apk = root / 'build/android/demons.apk'
            apk.parent.mkdir(parents=True)
            apk.write_bytes(b'Fixture APK; external tools validate metadata and signature')
            ipa = root / 'runner/export/demons.ipa'
            ipa.parent.mkdir(parents=True)
            info = ios_metadata if ios_metadata is not None else {
                'CFBundleIdentifier': 'com.juanpvivas.demons',
                'CFBundleVersion': '4', 'CFBundleShortVersionString': '1.0.1',
            }
            with zipfile.ZipFile(ipa, 'w') as archive:
                archive.writestr('Payload/demons.app/Info.plist', plistlib.dumps(info))
                archive.writestr('Payload/demons.app/demons', b'Fixture executable')
                for name, contents in additional_entries or []:
                    archive.writestr(name, contents)
            result = subprocess.run(['bash', '-euo', 'pipefail', '-c', run_command(step)],
                                    cwd=root, env=env, capture_output=True, text=True, timeout=15)
            return result, self.calls(root)

    def test_valid_android_package_and_signature_are_accepted(self):
        result, calls = self.invoke_verifier('android')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual({call['tool'] for call in calls}, {'apksigner', 'aapt2'})

    def test_invalid_android_signature_is_rejected(self):
        result, calls = self.invoke_verifier('android', bad_signature=True)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(any(call['tool'] == 'apksigner' for call in calls))

    def test_android_identifier_version_or_build_mismatch_is_rejected(self):
        for field, invalid in [('package', 'com.other.game'), ('name', '1.0'), ('code', '3')]:
            metadata = {'package': 'com.juanpvivas.demons', 'name': '1.0.1', 'code': '4'}
            metadata[field] = invalid
            with self.subTest(field=field):
                result, _ = self.invoke_verifier('android', apk_metadata=metadata)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_valid_ios_bundle_and_signature_are_accepted(self):
        result, calls = self.invoke_verifier('ios')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        verification = [call for call in calls if call['tool'] == 'codesign']
        self.assertEqual(len(verification), 1)
        self.assertIn('--verify', verification[0]['args'])
        self.assertIn('--strict', verification[0]['args'])
        self.assertIn('--deep', verification[0]['args'])

    def test_invalid_ios_signature_is_rejected(self):
        result, calls = self.invoke_verifier('ios', bad_signature=True)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue(any(call['tool'] == 'codesign' for call in calls))

    def test_ios_identifier_version_or_build_mismatch_is_rejected(self):
        for field, invalid in [('CFBundleIdentifier', 'com.other.game'),
                               ('CFBundleShortVersionString', '1.0'), ('CFBundleVersion', '3')]:
            metadata = {'CFBundleIdentifier': 'com.juanpvivas.demons',
                        'CFBundleShortVersionString': '1.0.1', 'CFBundleVersion': '4'}
            metadata[field] = invalid
            with self.subTest(field=field):
                result, _ = self.invoke_verifier('ios', ios_metadata=metadata)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_unsafe_or_ambiguous_ipa_is_rejected(self):
        for entry in [('../outside.txt', b'escape'),
                      ('Payload/other.app/Info.plist', plistlib.dumps({}))]:
            with self.subTest(entry=entry[0]):
                result, _ = self.invoke_verifier('ios', additional_entries=[entry])
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_verification_is_between_packaging_and_upload(self):
        for platform in ('android', 'ios'):
            with self.subTest(platform=platform):
                workflow, (verification_index, _) = self.verifier_step(platform)
                packaging = [index for index, step in enumerate(workflow.steps)
                             if 'run' in step and ('--export-debug' if platform == 'android'
                                                  else '-exportArchive') in scalar(step['run'])]
                upload = [index for index, step in enumerate(workflow.steps)
                          if 'name' in step and scalar(step['name']) == (
                              'Subir a Firebase App Distribution' if platform == 'android'
                              else 'Subir a TestFlight')]
                self.assertEqual(len(packaging), 1)
                self.assertEqual(len(upload), 1)
                self.assertLess(packaging[0], verification_index)
                self.assertLess(verification_index, upload[0])

    def invoke_export(self, platform, *, error_phase='', engine_error='', engine_exit=0):
        workflow = self.workflow(platform)
        relevant = [step for step in workflow.steps if 'run' in step and (
            '--import' in scalar(step['run']) or
            ('--export-debug' if platform == 'android' else '--export-release') in scalar(step['run']) or
            ('name' in step and scalar(step['name']) == 'Crear directorio de salida'))]
        self.assertTrue(any('--import' in scalar(step['run']) for step in relevant),
                        f'{platform}: explicit import is required before native export')
        with tempfile.TemporaryDirectory(prefix='demons-native-export-') as directory:
            root, env = self.workspace(directory)
            env.update({'NATIVE_ENGINE_ERROR_PHASE': error_phase,
                        'NATIVE_ENGINE_ERROR': engine_error, 'NATIVE_ENGINE_EXIT': str(engine_exit)})
            commands = '\n'.join(run_command(step) for step in relevant)
            result = subprocess.run(['bash', '-euo', 'pipefail', '-c', commands],
                                    cwd=root, env=env, capture_output=True, text=True, timeout=15)
            return result, self.calls(root)

    def test_build_is_ignored_before_import_and_import_precedes_export(self):
        for platform in ('android', 'ios'):
            with self.subTest(platform=platform):
                result, calls = self.invoke_export(platform)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual([call['phase'] for call in calls], ['import', 'export'])
                self.assertTrue(all(call['ignored_build'] for call in calls))

    def test_godot_errors_with_zero_exit_block_native_export(self):
        for platform in ('android', 'ios'):
            for phase in ('import', 'export'):
                for message in ('ERROR: Cannot set object script.', 'SCRIPT ERROR: Parse Error'):
                    with self.subTest(platform=platform, phase=phase, message=message):
                        result, calls = self.invoke_export(platform, error_phase=phase,
                                                           engine_error=message)
                        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                        self.assertEqual([call['phase'] for call in calls],
                                         ['import'] if phase == 'import' else ['import', 'export'])

    def test_nonzero_engine_exit_blocks_native_export(self):
        for platform in ('android', 'ios'):
            for phase in ('import', 'export'):
                with self.subTest(platform=platform, phase=phase):
                    result, _ = self.invoke_export(platform, error_phase=phase, engine_exit=9)
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
