"""Offline checks for upload failures and the Markdown handed to PR authors."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("upload.sh")


class UploadTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.config = self.root / "r2.env"
        self.config.write_text(
            "CLOUDFLARE_ACCOUNT_ID='" + "a" * 32 + "'\n"
            "R2_BUCKET='pr-media'\nR2_PUBLIC_URL='https://media.example.com/'\n"
        )
        self.calls = self.root / "calls.jsonl"
        for tool in ("npx", "curl"):
            stub = self.root / tool
            stub.write_text(
                "#!/usr/bin/env python3\n"
                "import json, os, sys\n"
                "from pathlib import Path\n"
                "tool = Path(sys.argv[0]).name\n"
                "with open(os.environ['UPLOAD_TEST_CALLS'], 'a') as f:\n"
                "    f.write(json.dumps([tool, *sys.argv[1:]]) + '\\n')\n"
                "print('tool output', file=sys.stderr)\n"
                "sys.exit(int(os.environ.get('UPLOAD_TEST_FAIL_' + tool.upper(), '0')))\n"
            )
            stub.chmod(0o755)
        self.env = dict(os.environ, PATH=f"{self.root}:{os.environ['PATH']}",
                        PR_MEDIA_CONFIG=str(self.config), UPLOAD_TEST_CALLS=str(self.calls))
        self.media = self.root / "screen shot.PNG"
        self.media.write_bytes(b"test media")

    def upload(self, file=None, caption="Settings", **env):
        return subprocess.run(
            ["bash", str(SCRIPT), str(file or self.media), caption],
            env=dict(self.env, **env), capture_output=True, text=True,
        )

    def commands(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()] if self.calls.exists() else []

    def test_image_url_and_remote_upload(self):
        result = self.upload(caption="Settings [fixed]\nNow")
        digest = hashlib.sha256(self.media.read_bytes()).hexdigest()
        url = f"https://media.example.com/{digest}-screen-shot.PNG"
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, f"![Settings \\[fixed\\] Now]({url})\n")
        put, head = self.commands()
        self.assertEqual(put[:5], ["npx", "--yes", "wrangler@4.156.0", "--cwd", str(self.root)])
        self.assertIn("--remote", put)
        self.assertEqual(put[put.index("--file") + 1], str(self.media))
        self.assertEqual(put[put.index("--content-type") + 1], "image/png")
        self.assertIn("--head", head)
        self.assertEqual(head[-1], url)

    def test_content_changes_get_a_new_url(self):
        first = self.upload().stdout
        self.assertEqual(first, self.upload().stdout)
        self.media.write_bytes(b"different media")
        self.assertNotEqual(first, self.upload().stdout)

    def test_failed_upload_returns_no_embed_or_public_check(self):
        result = self.upload(UPLOAD_TEST_FAIL_NPX="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")
        self.assertEqual(len(self.commands()), 1)

    def test_inaccessible_public_url_returns_no_embed(self):
        result = self.upload(UPLOAD_TEST_FAIL_CURL="22")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "")

    def test_rejects_large_files_and_unsupported_types_before_upload(self):
        with self.media.open("wb") as f:
            f.truncate(5_000_000)
        self.assertNotEqual(self.upload().returncode, 0)
        text = self.root / "log.txt"
        text.write_text("private log")
        self.assertNotEqual(self.upload(text).returncode, 0)
        self.assertEqual(self.commands(), [])

    def test_missing_configuration_fails_before_upload(self):
        self.config.write_text("")
        for name in ("CLOUDFLARE_ACCOUNT_ID", "R2_BUCKET", "R2_PUBLIC_URL"):
            self.env.pop(name, None)
        result = self.upload()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("configure CLOUDFLARE_ACCOUNT_ID", result.stderr)
        self.assertEqual(self.commands(), [])

    def test_video_is_a_link(self):
        video = self.root / "demo.mp4"
        video.write_bytes(b"test video")
        result = self.upload(video)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(result.stdout.startswith("[Settings](https://"))
        put = self.commands()[0]
        self.assertEqual(put[put.index("--content-type") + 1], "video/mp4")


if __name__ == "__main__":
    unittest.main()
