"""Declared FAKE HTTP only. These tests never invoke Gemma or a server."""
import copy
import io
import json
import socket
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.error import HTTPError

from tools.director_benchmark import benchmark as subject
from test_decisions import plans, snapshot


MODEL_HASH = "181938105e0eefd105961417e8da75903eacda102c4fce9ce90f50b97139a63c"
MODEL_SIZE = 2588147712
MANIFEST = {"repo": "litert-community/gemma-4-E2B-it-litert-lm",
            "revision": "1caa527c1e88b55f046fcd8d2b4265606680663d",
            "file": {"rfilename": "gemma-4-E2B-it.litertlm", "size": MODEL_SIZE,
                     "lfs": {"size": MODEL_SIZE, "sha256": MODEL_HASH}}}


def envelope(content='{"action_id":"right"}', finish="stop"):
    return json.dumps({"choices": [{"message": {"content": content},
                                  "finish_reason": finish}]}).encode()


class FakeResponse(io.BytesIO):
    def __init__(self, data, url="http://127.0.0.1:9379/v1/chat/completions", status=200):
        super().__init__(data); self.url = url; self.status = status; self.read_sizes = []
        self.headers = {"Content-Type": "application/json"}

    def geturl(self):
        return self.url

    def getcode(self):
        return self.status

    def read(self, size=-1):
        self.read_sizes.append(size)
        return super().read(size)


class FakeOpener:
    """Supports normal stdlib .open and a callable injection, without real IO."""
    def __init__(self, data=None, error=None, url=None, status=200, models=None):
        self.data = envelope() if data is None else data
        self.error = error; self.url = url; self.status = status
        self.calls = []; self.responses = []
        self.models = {"data": [{"id": "gemma4-e2b"}]} if models is None else models

    def open(self, request, timeout=None):
        self.calls.append((request, timeout))
        if self.error:
            raise self.error
        url = self.url or (request.full_url if hasattr(request, "full_url") else str(request))
        data = (json.dumps(self.models).encode()
                if url.endswith("/v1/models") else self.data)
        response = FakeResponse(data, url, self.status)
        self.responses.append(response)
        return response

    __call__ = open


class TransportContractTests(unittest.TestCase):
    def decision(self, opener, state=None, catalog=None):
        result = subject.gemma(state or snapshot(), catalog or plans(), 42, opener=opener)
        self.assertIsInstance(result, dict, "backend must return a classified result")
        return result

    def test_http_body_has_exact_requested_parameters_schema_and_no_oracle_leak(self):
        first = FakeOpener(); second = FakeOpener()
        state = snapshot()
        changed = dict(state, case_id="terminal", acceptable_actions=["left"],
                       report_metadata={"expected": "left", "secret_oracle_marker": "LEAK"})
        a = self.decision(first, state); b = self.decision(second, changed)
        self.assertEqual(a["status"], "ok"); self.assertEqual(b["status"], "ok")
        self.assertEqual(a["action_id"], "right")
        self.assertEqual(len(first.calls), 1); self.assertEqual(len(second.calls), 1)
        request, timeout = first.calls[0]
        self.assertEqual(request.full_url, "http://127.0.0.1:9379/v1/chat/completions")
        self.assertEqual(request.get_method(), "POST"); self.assertEqual(timeout, 30)
        self.assertLessEqual(len(request.data), 65536)
        self.assertEqual(request.data, second.calls[0][0].data)
        payload = json.loads(request.data)
        for key, value in dict(model="gemma4-e2b", reasoning_effort="none",
                               max_completion_tokens=64, temperature=.2, top_p=.95, seed=42).items():
            self.assertEqual(payload[key], value)
        self.assertNotIn("max_tokens", payload)
        schema = payload["response_format"]
        self.assertEqual(schema["type"], "json_schema")
        self.assertEqual(schema["json_schema"]["schema"], {
            "type": "object", "properties": {"action_id": {"type": "string"}},
            "required": ["action_id"], "additionalProperties": False})
        text = json.dumps(payload["messages"])
        for forbidden in ["case_id", "acceptable_actions", "report_metadata", "secret_oracle_marker", "LEAK"]:
            self.assertNotIn(forbidden, text)
        self.assertGreaterEqual(a["latency_ms"], 0)
        self.assertTrue(all(0 < size <= 65537 for size in first.responses[0].read_sizes))

    def test_format_illegality_and_truncation_remain_distinct_without_fallback(self):
        for content, finish, expected, action in [
            ('```json\n{"action_id":"right"}\n```', "stop", "invalid_output", None),
            ('{"action_id":"invented"}', "stop", "illegal_action", "invented"),
            ('{"action_id":"right"}', "length", "protocol_error", None)]:
            with self.subTest(expected=expected):
                fake = FakeOpener(envelope(content, finish))
                result = self.decision(fake)
                self.assertEqual(result["status"], expected)
                self.assertEqual(result["action_id"], action)
                self.assertEqual(len(fake.calls), 1)

    def test_transport_http_timeout_and_protocol_errors_do_not_become_actions_or_retry(self):
        cases = [(FakeOpener(error=TimeoutError("fake timeout")), "timeout"),
                 (FakeOpener(error=socket.timeout("fake socket timeout")), "timeout"),
                 (FakeOpener(error=OSError("fake disconnect")), "transport_error"),
                 (FakeOpener(error=HTTPError("http://127.0.0.1:9379/v1/chat/completions", 503,
                                             "fake unavailable", {}, None)), "http_error"),
                 (FakeOpener(b'{"choices":[]}'), "protocol_error"),
                 (FakeOpener(b'{"choices":[{"message":{"content":4}}]}'), "protocol_error"),
                 (FakeOpener(b"not json"), "protocol_error")]
        for fake, expected in cases:
            with self.subTest(expected=expected):
                result = self.decision(fake)
                self.assertEqual(result["status"], expected)
                self.assertIsNone(result["action_id"])
                self.assertEqual(len(fake.calls), 1)

    def test_request_and_response_size_caps_and_redirects_fail_closed(self):
        fake = FakeOpener(b"x" * 65537)
        self.assertEqual(self.decision(fake)["status"], "protocol_error")
        self.assertTrue(all(0 < n <= 65537 for n in fake.responses[0].read_sizes))
        for url in ["https://cloud.invalid/", "http://localhost:9379/v1/chat/completions",
                    "http://127.0.0.1:9378/v1/chat/completions",
                    "http://user@127.0.0.1:9379/v1/chat/completions",
                    "http://127.0.0.1:9379/v1/chat/completions?extra=1"]:
            with self.subTest(url=url):
                self.assertEqual(self.decision(FakeOpener(url=url))["status"], "protocol_error")
        fake = FakeOpener(status=302)
        self.assertNotEqual(self.decision(fake)["status"], "ok")
        large = plans(); large["left"]["extra_data"] = "x" * 65537
        fake = FakeOpener()
        self.assertEqual(self.decision(fake, catalog=large)["status"], "protocol_error")
        self.assertFalse(fake.calls, "oversized request must be rejected before HTTP")

    def test_default_transport_disables_environment_proxies_and_redirect_following(self):
        fake = FakeOpener()
        with patch.dict("os.environ", {"HTTP_PROXY": "http://cloud.invalid:8080",
                                       "HTTPS_PROXY": "http://cloud.invalid:8080"}), \
                patch("urllib.request.build_opener", return_value=fake) as builder:
            result = subject.gemma(snapshot(), plans(), 42)
        self.assertIsInstance(result, dict)
        self.assertEqual(result["status"], "ok")
        self.assertTrue(builder.called)
        handlers = builder.call_args.args
        self.assertTrue(any(getattr(h, "proxies", None) == {} for h in handlers))
        redirect_handlers = [h for h in handlers if hasattr(h, "redirect_request")]
        self.assertTrue(redirect_handlers, "default redirect following must be overridden")
        for handler in redirect_handlers:
            try:
                redirected = handler.redirect_request(fake.calls[0][0], None, 302, "fake", {},
                                                       "http://cloud.invalid/")
            except HTTPError:
                continue
            self.assertIsNone(redirected)

    def test_identity_rejects_changed_manifest_and_small_file_before_model_http(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); model = root / "gemma-4-E2B-it.litertlm"; model.write_bytes(b"NOT A MODEL")
            path = root / "manifest.json"
            for mutate in [lambda m: m.update(repo="wrong"), lambda m: m.update(revision="wrong"),
                           lambda m: m["file"].update(size=1),
                           lambda m: m["file"]["lfs"].update(sha256="0" * 64), lambda m: None]:
                metadata = copy.deepcopy(MANIFEST); mutate(metadata); path.write_text(json.dumps(metadata))
                fake = FakeOpener()
                result = subject.verify_identity(path, model, opener=fake)
                self.assertIsInstance(result, dict)
                self.assertEqual(result["status"], "identity_error")
                self.assertFalse(fake.calls, "identity mismatch must block HTTP and batch")

    def test_identity_positive_io_hash_double_is_explicit_fake_and_alias_is_checked(self):
        # This fixture is NOT a real 2.588GB model. Stat, content IO and digest
        # are explicitly mocked; only identity protocol/guards are credited.
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); model = root / "gemma-4-E2B-it.litertlm"
            model.write_bytes(b"FAKE MODEL HASH INPUT")
            manifest = root / "manifest.json"; manifest.write_text(json.dumps(MANIFEST))
            real_stat, real_open = Path.stat, Path.open
            read_sizes = []; hash_updates = []

            class FakeModel(io.BytesIO):
                def read(self, size=-1):
                    read_sizes.append(size)
                    return super().read(size)

            class FakeHash:
                def __init__(self, data=b""):
                    if data: self.update(data)

                def update(self, data):
                    hash_updates.append(data)

                def hexdigest(self):
                    return MODEL_HASH

            def fake_stat(path, *args, **kwargs):
                result = real_stat(path, *args, **kwargs)
                if path == model:
                    values = list(result); values[6] = MODEL_SIZE
                    return os.stat_result(values)
                return result

            def fake_open(path, *args, **kwargs):
                return FakeModel(b"FAKE MODEL HASH INPUT") if path == model else real_open(path, *args, **kwargs)

            for aliases, digest, expected in [({"data": [{"id": "gemma4-e2b"}]}, MODEL_HASH, "ok"),
                                              ({"data": [{"id": "other-model"}]}, MODEL_HASH, "identity_error"),
                                              ({"data": [{"id": "gemma4-e2b"}]}, "0" * 64, "identity_error")]:
                with self.subTest(expected=expected), patch.object(Path, "stat", fake_stat), \
                        patch.object(Path, "open", fake_open), patch("hashlib.sha256", FakeHash), \
                        patch.object(FakeHash, "hexdigest", return_value=digest):
                    fake = FakeOpener(models=aliases)
                    result = subject.verify_identity(manifest, model, opener=fake)
                    self.assertIsInstance(result, dict)
                    self.assertEqual(result["status"], expected)
                    if digest != MODEL_HASH:
                        self.assertFalse(fake.calls, "actual file hash mismatch must block model HTTP")
                        continue
                    self.assertEqual(len(fake.calls), 1)
                    request, timeout = fake.calls[0]
                    url = request.full_url if hasattr(request, "full_url") else request
                    self.assertEqual(url, "http://127.0.0.1:9379/v1/models")
                    self.assertEqual(timeout, 30)
                    self.assertTrue(hash_updates, "hash must be calculated, not trusted from manifest alone")
                    self.assertTrue(read_sizes)
                    self.assertTrue(all(size > 0 for size in read_sizes), "hash file read must use bounded blocks")


if __name__ == "__main__":
    unittest.main()
