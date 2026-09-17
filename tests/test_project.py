import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("project", Path(__file__).resolve().parents[1] / "scripts/project.py")
project = importlib.util.module_from_spec(spec)
spec.loader.exec_module(project)


class ProjectTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()

    def folder(self, name, marker=None):
        path = self.root / name
        path.mkdir(parents=True, exist_ok=True)
        if marker:
            (path / marker).touch()
        return path

    def test_nested_discovery_stops_at_repository_and_ignores_worktrees_folder(self):
        self.folder("school/capstone/ember-bench", ".git")
        self.folder("school/capstone/ember-bench/corpus/example", "package.json")
        self.folder("personal/.worktrees/feature", ".git")
        self.folder("school/FA26/csci3210/projects")
        with patch.object(project, "configuration", return_value={}):
            self.assertEqual(project.discover(self.root), ["school/FA26/csci3210", "school/capstone/ember-bench"])

    def test_duplicate_names_require_disambiguation_without_terminal(self):
        with patch.object(project, "configuration", return_value={}), patch.object(project.sys.stdin, "isatty", return_value=False):
            with self.assertRaisesRegex(ValueError, "exact project name"):
                project.select("app", ["personal/app", "work/app"])

    def test_aliases_resolve_to_exact_project(self):
        with patch.object(project, "configuration", return_value={"aliases": {"bench": "school/capstone/ember-bench"}}):
            self.assertEqual(project.select("bench", ["school/capstone/ember-bench"]), "school/capstone/ember-bench")

    def test_current_directory_selects_deepest_project(self):
        cwd = self.folder("school/capstone/bench/src")
        with patch.object(project, "ROOT", self.root), patch.object(project.Path, "cwd", return_value=cwd), patch.object(project, "configuration", return_value={}):
            self.assertEqual(project.select(None, ["school/capstone", "school/capstone/bench"], current=True), "school/capstone/bench")

    def test_native_justfile_takes_precedence(self):
        path = self.folder("personal/app", "Justfile")
        (path / "package.json").write_text('{}')
        self.assertEqual(project.commands(path, "check"), [["just", "--justfile", str(path / "Justfile"), "check"]])

    def test_node_check_runs_only_declared_checks_in_order(self):
        path = self.folder("personal/web")
        (path / "package.json").write_text(json.dumps({"scripts": {"test": "node --test", "typecheck": "tsc"}}))
        self.assertEqual(project.commands(path, "check"), [["npm", "run", "typecheck"], ["npm", "run", "test"]])
        with self.assertRaisesRegex(ValueError, "No 'lint'"):
            project.commands(path, "lint")

    def test_direnv_is_used_without_automatically_allowing_it(self):
        path = self.folder("personal/a project; echo unsafe", ".envrc")
        self.assertEqual(project.environment(path, ["npm", "test"]), ["direnv", "exec", str(path), "npm", "test"])

    def test_missing_runtime_uses_pinned_dotfiles_shell(self):
        path = self.folder("personal/rust", "Cargo.toml")
        cmd = project.environment(path, ["cargo", "test"])
        self.assertIn("--no-write-lock-file", cmd)
        self.assertIn(str(project.DOTS / "nix-darwin") + "#rust", cmd)
        self.assertEqual(cmd[-2:], ["cargo", "test"])


if __name__ == "__main__":
    unittest.main()
