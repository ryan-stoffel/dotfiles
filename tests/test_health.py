"""Formatting and reporting logic for the health checks and dashboard."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

import health
import tui
from health import Check


def rows(results, expand=False):
    return [text for text, _ in tui.build(results, expand)]


class CheckTests(unittest.TestCase):
    def test_doctor_line_joins_name_and_detail(self):
        self.assertEqual(Check("tools", "nix", "ok", "/usr/bin/nix").line, "nix: /usr/bin/nix")
        self.assertEqual(Check("tools", "nix", "ok").line, "nix")

    def test_status_maps_to_doctor_level(self):
        self.assertEqual(Check("git", "a", "ok").level, "PASS")
        self.assertEqual(Check("git", "a", "warn").level, "WARN")
        self.assertEqual(Check("git", "a", "fail").level, "FAIL")

    def test_every_task_name_matches_a_rendered_group(self):
        self.assertEqual(sorted(t.__name__ for t in health.TASKS), sorted(health.GROUPS))

    def test_collect_reports_a_failing_probe_instead_of_raising(self):
        def broken():
            raise OSError("probe exploded")
        broken.__name__ = "system"
        result = health.collect(broken)
        self.assertEqual([c.status for c in result], ["fail"])
        self.assertIn("probe exploded", result[0].detail)


class DashboardTests(unittest.TestCase):
    def test_uniform_passing_group_collapses_to_one_line(self):
        results = {"tools": [Check("tools", f"t{i}", "ok") for i in range(12)]}
        self.assertIn("  TOOLS       12 ok", rows(results))

    def test_collapsed_group_expands_on_request(self):
        results = {"tools": [Check("tools", f"t{i}", "ok") for i in range(12)]}
        self.assertEqual(sum("t5" in r for r in rows(results, expand=True)), 1)

    def test_group_with_a_problem_is_never_collapsed(self):
        results = {"tools": [Check("tools", "nix", "ok"), Check("tools", "uv", "fail", "missing")]}
        self.assertTrue(any("uv" in r and "fail" in r for r in rows(results)))

    def test_fix_is_shown_for_problems_and_hidden_for_passes(self):
        results = {"git": [Check("git", "Branch", "warn", "2 to push", "git push"),
                           Check("git", "Tree", "ok", "clean", "git status")]}
        printed = rows(results)
        self.assertTrue(any("run: git push" in r for r in printed))
        self.assertFalse(any("run: git status" in r for r in printed))

    def test_unfinished_group_reads_as_pending(self):
        self.assertIn("      checking...", rows({}))

    def test_long_name_is_truncated_to_keep_columns_aligned(self):
        results = {"links": [Check("links", "~/" + "x" * 80, "fail")]}
        line = next(r for r in rows(results) if "xxx" in r)
        self.assertLess(len(line), 60)

    def test_summary_counts_problems_once_checks_finish(self):
        results = {"git": [Check("git", "a", "fail"), Check("git", "b", "warn"), Check("git", "c", "ok")]}
        self.assertIn("1 failed, 1 warnings", tui.summarise(results, pending=[]))
        self.assertIn("all checks passing", tui.summarise({"git": [Check("git", "a", "ok")]}, pending=[]))
        self.assertIn("checking 2 group(s)", tui.summarise(results, pending=[object(), object()]))


if __name__ == "__main__":
    unittest.main()
