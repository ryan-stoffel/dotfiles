#!/usr/bin/env python3
"""Reports whether a GitHub PR is ready to merge, using GraphQL only (REST quota is shared and runs out).

Usage, inside the repo checkout:
  pr_status.py <number|url>                 print status; exit 0 ready, 1 not ready, 2 error
  pr_status.py <number|url> --wait [secs]   re-check every secs (default 120) until something needs action

Ready means: open, not draft, no conflicts, not behind base, every check on the head commit
passed, no unresolved review threads, and no outstanding change request.
--wait returns on: ready, a failed check, a conflict, new comments/reviews/threads, a new head
commit, or the PR closing. Behind-base only returns once checks finish, so a busy base branch
does not restart CI on every poll. After 5 failed reads in a row it exits 2 instead of spinning.
"""
import json, re, subprocess, sys, time

QUERY = """
query($o: String!, $r: String!, $n: Int!) {
  repository(owner: $o, name: $r) {
    pullRequest(number: $n) {
      url state isDraft mergeable mergeStateStatus reviewDecision headRefOid baseRefName
      comments { totalCount }
      reviews { totalCount }
      reviewThreads(first: 100) { nodes { isResolved } }
      commits(last: 1) { nodes { commit { statusCheckRollup { contexts(first: 100) { nodes {
        __typename
        ... on CheckRun { name status conclusion }
        ... on StatusContext { context state }
      } } } } } }
    }
  }
}"""
BEHIND = """
query($o: String!, $r: String!, $base: String!, $head: String!) {
  repository(owner: $o, name: $r) { ref(qualifiedName: $base) { compare(headRef: $head) { behindBy } } }
}"""
PASS = {"SUCCESS", "NEUTRAL", "SKIPPED"}
PENDING_STATUS = {"PENDING", "EXPECTED"}


def gh_graphql(query, **fields):
    args = ["gh", "api", "graphql", "-f", f"query={query}"]
    for k, v in fields.items():
        args += ["-F" if isinstance(v, int) else "-f", f"{k}={v}"]
    out = subprocess.run(args, capture_output=True, text=True)
    if out.returncode:
        raise RuntimeError(out.stderr.strip() or out.stdout.strip())
    return json.loads(out.stdout)["data"]["repository"]


def classify(node):
    """Map one CheckRun or StatusContext to (name, pass|fail|pending)."""
    if node["__typename"] == "CheckRun":
        if node["status"] != "COMPLETED":
            return node["name"], "pending"
        return node["name"], "pass" if node["conclusion"] in PASS else "fail"
    state = node["state"]
    return node["context"], "pending" if state in PENDING_STATUS else "pass" if state == "SUCCESS" else "fail"


def summarize(pr, behind):
    """Pure readiness verdict from the GraphQL PR payload and the behind-base count."""
    commits = pr["commits"]["nodes"]
    rollup = commits[0]["commit"]["statusCheckRollup"] if commits else None
    checks = [classify(n) for n in (rollup or {}).get("contexts", {}).get("nodes", [])]
    failing = sorted(name for name, s in checks if s == "fail")
    pending = sorted(name for name, s in checks if s == "pending")
    unresolved = sum(not t["isResolved"] for t in pr["reviewThreads"]["nodes"])
    reasons = []
    is_open = pr["state"] == "OPEN"
    if not is_open: reasons.append(f"PR is {pr['state'].lower()}")
    if pr["isDraft"]: reasons.append("draft")
    if is_open and pr["mergeable"] == "CONFLICTING": reasons.append("merge conflict with base")
    if is_open and pr["mergeable"] == "UNKNOWN": reasons.append("GitHub is still computing mergeability")
    if behind: reasons.append(f"{behind} commits behind {pr['baseRefName']}")
    if not checks: reasons.append("no checks reported on head yet")
    if failing: reasons.append("failing: " + ", ".join(failing))
    if pending: reasons.append("pending: " + ", ".join(pending))
    if unresolved: reasons.append(f"{unresolved} unresolved review threads")
    if pr["reviewDecision"] == "CHANGES_REQUESTED": reasons.append("changes requested")
    return {
        "url": pr["url"], "state": pr["state"], "head": pr["headRefOid"][:10], "behind": behind,
        "checks": len(checks), "failing": failing, "pending": pending, "unresolved": unresolved,
        "conflict": pr["mergeable"] == "CONFLICTING", "merge_state": pr["mergeStateStatus"],
        "activity": pr["comments"]["totalCount"] + pr["reviews"]["totalCount"] + len(pr["reviewThreads"]["nodes"]),
        "reasons": reasons, "ready": not reasons,
    }


def needs_action(start, cur):
    """True when the agent should wake up: anything changed that it has to handle."""
    settled = cur["checks"] and not cur["pending"]
    return (cur["ready"] or cur["state"] != "OPEN" or cur["conflict"] or bool(cur["failing"])
            or cur["activity"] > start["activity"] or cur["head"] != start["head"]
            or (settled and cur["behind"] > 0))


def resolve(arg):
    m = re.match(r"https://github\.com/([^/]+)/([^/]+)/pull/(\d+)", arg)
    if m:
        return m.group(1), m.group(2), int(m.group(3))
    repo = subprocess.run(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
                          capture_output=True, text=True, check=True).stdout.strip()
    owner, name = repo.split("/")
    return owner, name, int(arg.lstrip("#"))


def read(owner, name, number):
    pr = gh_graphql(QUERY, o=owner, r=name, n=number)["pullRequest"]
    behind = 0
    if pr["state"] == "OPEN":
        ref = gh_graphql(BEHIND, o=owner, r=name, base=pr["baseRefName"], head=pr["headRefOid"])["ref"]
        behind = ref["compare"]["behindBy"] if ref else 0
    return summarize(pr, behind)


def show(s):
    print(f"{s['url']} head={s['head']} state={s['state']} merge_state={s['merge_state']}")
    print("verdict: READY" if s["ready"] else "verdict: NOT READY: " + "; ".join(s["reasons"]))
    sys.stdout.flush()


def main(argv):
    if not argv:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    owner, name, number = resolve(argv[0])
    wait = "--wait" in argv
    interval = int(argv[argv.index("--wait") + 1]) if wait and len(argv) > argv.index("--wait") + 1 else 120
    start, started, errors = None, None, 0
    while True:
        try:
            cur = read(owner, name, number)
            errors = 0
        except Exception as e:  # rate limit, auth, network: report, back off, never loop silently
            errors += 1
            print(f"pr_status: read failed ({errors}/5): {e}", file=sys.stderr)
            if not wait or errors >= 5:
                return 2
            time.sleep(interval * errors)
            continue
        start = start or cur
        started = started or time.time()
        # A repo with no CI never reports checks; hand back after 10 minutes instead of waiting forever.
        no_ci = not cur["checks"] and time.time() - started > 600
        if not wait or needs_action(start, cur) or no_ci:
            show(cur)
            return 0 if cur["ready"] else 1
        time.sleep(interval)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
