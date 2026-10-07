"""Readiness verdict and wake-up rules for the babysit-pr skill's pr_status.py."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "agents" / "skills" / "babysit-pr"))

from pr_status import needs_action, summarize


def check(name, status="COMPLETED", conclusion="SUCCESS"):
    return {"__typename": "CheckRun", "name": name, "status": status, "conclusion": conclusion}


def pr(checks=(), threads=(), mergeable="MERGEABLE", state="OPEN", comments=0, head="a" * 40):
    return {
        "url": "u", "state": state, "isDraft": False, "mergeable": mergeable, "mergeStateStatus": "CLEAN",
        "reviewDecision": None, "headRefOid": head, "baseRefName": "main",
        "comments": {"totalCount": comments}, "reviews": {"totalCount": 0},
        "reviewThreads": {"nodes": [{"isResolved": r} for r in threads]},
        "commits": {"nodes": [{"commit": {"statusCheckRollup": {"contexts": {"nodes": list(checks)}}}}]},
    }


class SummarizeTests(unittest.TestCase):
    def test_green_up_to_date_pr_is_ready(self):
        self.assertTrue(summarize(pr([check("ci")], [True]), 0)["ready"])

    def test_no_checks_yet_is_not_ready(self):
        # Right after a push the rollup is empty; that must not read as green.
        self.assertIn("no checks reported on head yet", summarize(pr(), 0)["reasons"])

    def test_each_blocker_is_reported(self):
        s = summarize(pr([check("ci", conclusion="FAILURE"), check("e2e", status="IN_PROGRESS")], [False], "CONFLICTING"), 3)
        self.assertEqual(s["reasons"], ["merge conflict with base", "3 commits behind main", "failing: ci",
                                         "pending: e2e", "1 unresolved review threads"])


class NeedsActionTests(unittest.TestCase):
    def test_pending_checks_keep_waiting_even_when_behind(self):
        start = summarize(pr([check("ci", status="QUEUED")]), 0)
        self.assertFalse(needs_action(start, summarize(pr([check("ci", status="IN_PROGRESS")]), 2)))

    def test_behind_wakes_once_checks_settle(self):
        start = summarize(pr([check("ci", status="QUEUED")]), 0)
        self.assertTrue(needs_action(start, summarize(pr([check("ci")]), 2)))

    def test_new_comment_wakes(self):
        start = summarize(pr([check("ci", status="QUEUED")]), 0)
        self.assertTrue(needs_action(start, summarize(pr([check("ci", status="QUEUED")], comments=1), 0)))

    def test_merged_by_someone_else_wakes(self):
        start = summarize(pr([check("ci", status="QUEUED")]), 0)
        self.assertTrue(needs_action(start, summarize(pr(state="MERGED"), 0)))


if __name__ == "__main__":
    unittest.main()
