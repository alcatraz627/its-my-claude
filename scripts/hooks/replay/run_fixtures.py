#!/usr/bin/env python3
"""
run_fixtures.py — regression runner for the Stop-hook fixture set.

Runs each fixture (a captured single-turn slice) through the REAL hook and checks
the outcome against the manifest's `expected` field. This is the ship-gate check:
before a hook change goes live, run the fixtures — a FAIL means the change altered
behavior on a turn whose correct outcome is already pinned.

`expected` records what the CURRENT hook does (the guardrail against regressions).
`desired` records what the v2 redesign should do (TP -> block-or-soft, FP ->
soft-or-silent). By default the runner asserts `expected`; pass `--desired` to
assert `desired` instead (the acceptance gate for the redesign). `desired` uses
OR-set semantics: "block-or-soft" passes on block or soft, "soft-or-silent" passes
on soft or silent, "silent" passes only on silent.

Usage (via run-fixtures.sh): run_fixtures.py [--desired] <hook-script> [fixtures-subdir]
"""

import json
import os
import re
import sys
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import replay_lib as rl  # noqa: E402

MANIFEST = os.path.join(HERE, "fixtures", "manifest.json")
RUN_DIR = f"/tmp/run-fixtures-{os.getpid()}"


def desired_ok(got, desired):
    """OR-set match: 'block-or-soft' -> {block, soft}; 'silent' -> {silent}."""
    allowed = set(desired.lower().replace("-or-", "-").split("-"))
    return got in allowed


def main():
    argv = [a for a in sys.argv[1:]]
    mode = "expected"
    if "--desired" in argv:
        mode = "desired"
        argv = [a for a in argv if a != "--desired"]
    hook_arg = argv[0] if len(argv) > 0 else None
    subdir = argv[1] if len(argv) > 1 else None

    if not os.path.isfile(MANIFEST):
        print(f"ERROR: manifest not found: {MANIFEST}  (run seed-fixtures.py first)", file=sys.stderr)
        return 2
    manifest = json.loads(Path(MANIFEST).read_text())
    fixtures = manifest.get("fixtures", [])

    hook_path = os.path.abspath(hook_arg) if hook_arg else None
    hook_base = os.path.basename(hook_path) if hook_path else None
    # Normalize a version suffix (declared-ready-stop-v2.sh -> declared-ready-stop.sh)
    # so a redesign variant can be tested against its baseline's pinned fixtures.
    hook_base_norm = re.sub(r"-v\d+(?=\.sh$)", "", hook_base) if hook_base else None
    if hook_path:
        if not os.path.isfile(hook_path):
            print(f"ERROR: hook not found: {hook_path}", file=sys.stderr)
            return 2
        tokens, present = rl.check_mute_files(hook_path)
        if present:
            print(f"!! WARNING: mute file present for {hook_base} — every fixture will read SILENT:", file=sys.stderr)
            for f in present:
                print(f"!!   {f}", file=sys.stderr)

    os.makedirs(RUN_DIR, exist_ok=True)
    selected = []
    for fx in fixtures:
        if subdir and subdir not in fx["fixture"]:
            continue
        if hook_base_norm and fx["hook"] != hook_base_norm:
            continue
        selected.append(fx)

    if not selected:
        print("ERROR: no fixtures matched the given hook/subdir.", file=sys.stderr)
        return 2

    # Resolve the hook path per fixture when none was passed on the CLI.
    hooks_dir = os.path.join(rl.HOME, ".claude", "scripts", "hooks")
    npass = nfail = 0
    idx = 0
    assert_col = "desired" if mode == "desired" else "expected"
    print(f"asserting against: {assert_col}")
    print(f"{'RESULT':6}  {'FIXTURE':28} {'exp':7} {'got':7} {'desired':14} note")
    print("-" * 100)
    for fx in selected:
        this_hook = hook_path or os.path.join(hooks_dir, fx["hook"])
        fixture_path = os.path.join(HERE, fx["fixture"])
        if not os.path.isfile(fixture_path):
            print(f"{'ERROR':6}  {fx['name']:28} fixture file missing: {fixture_path}")
            nfail += 1
            continue
        outcome, rc, err, _ = rl.run_slice(this_hook, fixture_path, idx, fx.get("cwd", rl.HOME), RUN_DIR)
        idx += 1
        got = outcome.lower()
        exp = fx["expected"].lower()
        if mode == "desired":
            ok = desired_ok(got, fx.get("desired", ""))
        else:
            ok = (got == exp)
        npass += ok
        nfail += (not ok)
        tag = "PASS" if ok else "FAIL"
        note = fx.get("note", "")[:44]
        print(f"{tag:6}  {fx['name']:28} {exp:7} {got:7} {fx.get('desired',''):14} {note}")

    try:
        import shutil
        shutil.rmtree(RUN_DIR)
    except OSError:
        pass

    print("-" * 100)
    print(f"{npass} passed, {nfail} failed  ({len(selected)} fixtures)")
    return 1 if nfail else 0


if __name__ == "__main__":
    sys.exit(main())
