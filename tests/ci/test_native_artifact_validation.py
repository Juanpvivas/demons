"""Execute publication checks offline against signed/metadata tool fixtures.

The actual workflow run steps and repository verifier run in temporary folders.
No credential, Godot export, connected device or distribution service is used.
"""

import base64
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

from test_publication_policy import ROOT, TARGETS, Workflow, mapping, scalar


EXPECTED_ANDROID_CERT = '0123456789abcdef' * 4
OTHER_ANDROID_CERT = 'fedcba9876543210' * 4
UNSET = object()


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
    if tool == 'apksigner' and '--print-certs' in args:
        print(os.environ.get('NATIVE_CERT_OUTPUT', ''))
elif tool == 'keytool':
    if '-list' not in args or '-keystore' not in args or '-alias' not in args:
        print('Fixture requires verification of the provided keystore alias', file=sys.stderr)
        sys.exit(14)
    key = pathlib.Path(args[args.index('-keystore') + 1])
    if (not key.is_file() or key.read_bytes() != b'fixture-private-keystore'
            or args[args.index('-alias') + 1] != 'fixture-beta'):
        print('Restored fixture keystore or alias does not match', file=sys.stderr)
        sys.exit(15)
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
if os.environ.get('NATIVE_REQUIRE_FIXED_SIGNING') == '1':
    key = pathlib.Path(os.environ.get('GODOT_ANDROID_KEYSTORE_DEBUG_PATH', 'missing'))
    if (not key.is_file() or key.read_bytes() != b'fixture-private-keystore'
            or os.environ.get('GODOT_ANDROID_KEYSTORE_DEBUG_USER') != 'fixture-beta'
            or os.environ.get('GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD') != 'fixture-password'):
        print('Godot did not receive the fixed signing configuration', file=sys.stderr)
        sys.exit(16)
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
        for directory, names in [(tools, ('aapt2', 'apksigner')), (bindir, ('codesign', 'keytool'))]:
            for name in names:
                path = directory / name
                path.write_text(f'#!{sys.executable}\n' + FAKE_TOOL)
                path.chmod(0o755)
        godot = bindir / 'godot'
        godot.write_text(f'#!{sys.executable}\n' + FAKE_GODOT)
        godot.chmod(0o755)
        env = os.environ.copy()
        env.pop('DEMONS_ANDROID_CERT_SHA256', None)
        env.update({
            'PATH': str(bindir) + os.pathsep + os.environ['PATH'],
            'ANDROID_HOME': str(root / 'sdk'),
            'ANDROID_SDK_ROOT': str(root / 'sdk'),
            'RUNNER_TEMP': str(root / 'runner'),
            'NATIVE_CALLS': str(root / 'calls.jsonl'),
            'NATIVE_CERT_OUTPUT': 'Signer #1 certificate SHA-256 digest: ' + EXPECTED_ANDROID_CERT,
            'NATIVE_APK_METADATA': json.dumps({
                'package': 'com.juanpvivas.demons', 'code': '4', 'name': '1.0.1'}),
        })
        return root, env

    def calls(self, root):
        path = root / 'calls.jsonl'
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def invoke_verifier(self, platform, *, apk_metadata=None, ios_metadata=None,
                        bad_signature=False, additional_entries=None,
                        expected_cert=UNSET, certificate_output=None):
        _, (_, step) = self.verifier_step(platform)
        with tempfile.TemporaryDirectory(prefix='demons-native-check-') as directory:
            root, env = self.workspace(directory)
            if apk_metadata is not None:
                env['NATIVE_APK_METADATA'] = json.dumps(apk_metadata)
            if expected_cert is not UNSET:
                env['DEMONS_ANDROID_CERT_SHA256'] = expected_cert
            if certificate_output is not None:
                env['NATIVE_CERT_OUTPUT'] = certificate_output
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

    def test_android_expected_certificate_queries_and_accepts_one_matching_leaf(self):
        upper = EXPECTED_ANDROID_CERT.upper()
        colon_separated = ':'.join(upper[index:index + 2] for index in range(0, 64, 2))
        for expected in (EXPECTED_ANDROID_CERT, upper, colon_separated):
            with self.subTest(expected=expected):
                result, calls = self.invoke_verifier('android', expected_cert=expected)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertTrue(any(call['tool'] == 'apksigner' and '--print-certs' in call['args']
                                    for call in calls), 'The verifier must inspect the actual APK signer')

    def test_android_expected_certificate_mismatch_is_rejected(self):
        result, _ = self.invoke_verifier('android', expected_cert=OTHER_ANDROID_CERT)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_android_present_but_invalid_expected_certificate_is_rejected(self):
        for expected in ('', '0' * 63, '0' * 65, 'g' * 64, 'not-a-certificate'):
            with self.subTest(expected=expected):
                result, _ = self.invoke_verifier('android', expected_cert=expected)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_android_missing_or_ambiguous_signer_digest_is_rejected(self):
        leaf = 'Signer #1 certificate SHA-256 digest: ' + EXPECTED_ANDROID_CERT
        outputs = (
            'Signature verified without a certificate digest',
            'Signer #1 certificate SHA-1 digest: ' + EXPECTED_ANDROID_CERT,
            'Source Stamp Signer certificate SHA-256 digest: ' + EXPECTED_ANDROID_CERT,
            'Signer #1 certificate SHA-256 digest: ' + 'g' * 64,
            leaf + '\nSigner #2 certificate SHA-256 digest: ' + OTHER_ANDROID_CERT,
            leaf + '\n' + leaf,
        )
        for output in outputs:
            with self.subTest(output=output):
                result, _ = self.invoke_verifier('android', expected_cert=EXPECTED_ANDROID_CERT,
                                                 certificate_output=output)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_android_without_expected_certificate_keeps_signature_only_compatibility(self):
        result, _ = self.invoke_verifier('android', certificate_output='Signature verified')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_ios_ignores_the_android_expected_certificate_environment(self):
        result, _ = self.invoke_verifier('ios', expected_cert='')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

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

    def test_android_workflow_restores_fixed_signing_before_export_and_cleans_up(self):
        workflow, (verification_index, verifier) = self.verifier_step('android')
        setups = [(index, step) for index, step in enumerate(workflow.steps)
                  if 'run' in step and 'GODOT_ANDROID_KEYSTORE_DEBUG_PATH' in scalar(step['run'])
                  and 'keytool' in scalar(step['run'])]
        self.assertEqual(len(setups), 1, 'Android export needs one fixed-keystore preflight, not a random fallback')
        setup_index, setup = setups[0]
        export_index, export = next((index, step) for index, step in enumerate(workflow.steps)
                                    if 'run' in step and '--export-debug' in scalar(step['run']))
        upload_index, upload = next((index, step) for index, step in enumerate(workflow.steps)
                                    if 'uses' in step and 'Firebase-Distribution' in scalar(step['uses']))
        self.assertLess(setup_index, export_index)
        self.assertLess(export_index, verification_index)
        self.assertLess(verification_index, upload_index)

        def declared_env(step):
            result = {}
            for entries, indent in [(mapping(workflow.text.splitlines(), 0), 2),
                                    (workflow.job, 6), (step, 10)]:
                result.update({name: scalar(value) for name, value in
                               mapping(entries.get('env', ('', []))[1], indent).items()})
            return result

        expected_binding = declared_env(verifier).get('DEMONS_ANDROID_CERT_SHA256', '')
        self.assertEqual(expected_binding.replace(' ', ''), '${{vars.ANDROID_BETA_CERT_SHA256}}',
                         'An absent Actions variable must reach the verifier as an empty, present value')
        for step in (setup, verifier, upload):
            self.assertNotEqual(scalar(step.get('continue-on-error', ('false', []))), 'true',
                                'Signing or certificate failures must not continue to distribution')
        cleanups = [step for index, step in enumerate(workflow.steps)
                    if index > upload_index and 'run' in step
                    and scalar(step.get('if', ('', []))).replace('${{', '').replace('}}', '').strip() == 'always()']
        self.assertEqual(len(cleanups), 1, 'The private signing file needs unconditional cleanup')

        bindings = {
            'secrets.ANDROID_BETA_KEYSTORE_BASE64': base64.b64encode(b'fixture-private-keystore').decode(),
            'secrets.ANDROID_BETA_KEYSTORE_PASSWORD': 'fixture-password',
            'secrets.ANDROID_BETA_KEYSTORE_ALIAS': 'fixture-beta',
            'vars.ANDROID_BETA_CERT_SHA256': EXPECTED_ANDROID_CERT,
        }
        for missing in (*bindings, None):
            with self.subTest(missing=missing), tempfile.TemporaryDirectory(prefix='demons-fixed-signing-') as directory:
                root, env = self.workspace(directory)
                runner = Path(env['RUNNER_TEMP'])
                runner.mkdir()
                environment_file = root / 'github-env'
                env['GITHUB_ENV'] = str(environment_file)
                environment_file.write_text('')
                values = {key: '' if key == missing else value for key, value in bindings.items()}
                for name, value in declared_env(setup).items():
                    for reference, resolved in values.items():
                        value = value.replace('${{ ' + reference + ' }}', resolved)
                        value = value.replace('${{' + reference + '}}', resolved)
                    self.assertNotIn('${{', value, 'Fixture does not accept an unreviewed Actions expression')
                    env[name] = value
                result = subprocess.run(['bash', '-euo', 'pipefail', '-c', run_command(setup)],
                                        cwd=root, env=env, capture_output=True, text=True, timeout=15)
                if missing is not None:
                    self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                    continue
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                persisted = dict(line.split('=', 1) for line in environment_file.read_text().splitlines() if line)
                for name in ('GODOT_ANDROID_KEYSTORE_DEBUG_PATH', 'GODOT_ANDROID_KEYSTORE_DEBUG_USER',
                             'GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD'):
                    self.assertIn(name, persisted)
                private_key = Path(persisted['GODOT_ANDROID_KEYSTORE_DEBUG_PATH'])
                self.assertTrue(private_key.resolve().is_relative_to(runner.resolve()))
                self.assertEqual(private_key.read_bytes(), b'fixture-private-keystore')
                self.assertEqual(private_key.stat().st_mode & 0o777, 0o600)
                self.assertTrue(any(call.get('tool') == 'keytool' for call in self.calls(root)))
                env.update(persisted)
                env['NATIVE_REQUIRE_FIXED_SIGNING'] = '1'
                (root / 'build').mkdir()
                (root / 'build/.gdignore').touch()
                exported = subprocess.run(['bash', '-euo', 'pipefail', '-c', run_command(export)],
                                          cwd=root, env=env, capture_output=True, text=True, timeout=15)
                self.assertEqual(exported.returncode, 0, exported.stdout + exported.stderr)
                self.assertTrue(any(call.get('phase') == 'export' for call in self.calls(root)))
                sentinel = runner / 'unrelated-file'
                sentinel.write_text('preserve')
                cleanup = subprocess.run(['bash', '-euo', 'pipefail', '-c', run_command(cleanups[0])],
                                         cwd=root, env=env, capture_output=True, text=True, timeout=15)
                self.assertEqual(cleanup.returncode, 0, cleanup.stdout + cleanup.stderr)
                self.assertFalse(private_key.exists())
                self.assertTrue(sentinel.is_file(), 'Cleanup must remove only its own signing material')

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
