#!/usr/bin/env python3
"""Apply reviewed Markdown changes to the gcc canon through a bounded bridge."""
import argparse
import difflib
import fcntl
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path.home() / ".claude"
EXACT = {"GLOSSARY.md", "LOOKUP.md", "CLAUDE.md", "NAMESPACE.md"}
HEX = re.compile(r"[0-9a-f]{64}\Z")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def fail(message):
    raise ValueError(message)


def target_for(name):
    p = Path(name)
    parts = p.parts
    if p.is_absolute() or not parts or any(x in (".", "..") or x.startswith(".") for x in parts):
        fail(f"invalid canonical path: {name}")
    allowed = name in EXACT or (
        len(parts) == 2 and parts[0] in {"rules", "features", "conventions"}
        and parts[1].endswith(".md") and parts[1] != "00-index.md"
    ) or (len(parts) == 3 and parts[:2] == ("memory", "global") and parts[2].endswith(".md")) or (
        len(parts) == 3 and parts[0] == "skills" and parts[2] == "SKILL.md"
    )
    if not allowed:
        fail(f"path is outside the authored canon allowlist: {name}")
    target = ROOT / p
    for ancestor in (ROOT, *target.relative_to(ROOT).parents):
        if isinstance(ancestor, Path) and ancestor.is_absolute() and ancestor.is_symlink():
            fail(f"symlinked canonical ancestor: {ancestor}")
    cur = target
    while cur != ROOT:
        if cur.is_symlink():
            fail(f"symlinked canonical path: {cur}")
        cur = cur.parent
    return target


def load_manifest(path, expected_digest):
    raw = Path(path).read_bytes()
    if len(raw) > 1_000_000:
        fail("manifest exceeds 1 MB")
    got = digest(raw)
    if got != expected_digest:
        fail("manifest changed after gcc captured its hash")
    manifest = json.loads(raw)
    if manifest.get("schema_version") != 1 or not isinstance(manifest.get("changes"), list):
        fail("manifest needs schema_version 1 and changes array")
    changes = manifest["changes"]
    if not 1 <= len(changes) <= 16:
        fail("manifest needs 1..16 changes")
    seen = set()
    checked = []
    for row in changes:
        if not isinstance(row, dict) or set(row) != {"path", "expected_sha256", "content"}:
            fail("each change needs path, expected_sha256, content")
        name, expected, content = row["path"], row["expected_sha256"], row["content"]
        if not isinstance(name, str) or name in seen:
            fail("duplicate or invalid path")
        seen.add(name)
        if not isinstance(content, str) or not content.endswith("\n") or len(content.encode()) > 100_000:
            fail(f"content must be newline-terminated UTF-8 under 100 KB: {name}")
        if "DERIVED FILE. NEVER hand-edit" in content:
            fail(f"derived content refused: {name}")
        target = target_for(name)
        old = target.read_bytes() if target.is_file() else None
        if old is not None and b"DERIVED FILE. NEVER hand-edit" in old:
            fail(f"derived target refused: {name}")
        if old is None and expected is not None:
            fail(f"new target must have null expected_sha256: {name}")
        if old is not None and (not isinstance(expected, str) or not HEX.fullmatch(expected) or digest(old) != expected):
            fail(f"base hash mismatch: {name}")
        if name == "CLAUDE.md" and len(content.splitlines()) > 200:
            fail("CLAUDE.md exceeds 200 lines")
        checked.append((name, target, old, content.encode()))
    return got, checked


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("command", choices=("check", "apply"))
    ap.add_argument("manifest")
    ap.add_argument("manifest_sha256")
    args = ap.parse_args()
    lock_path = ROOT / "adapters/codex/state/canon.lock"
    if args.command == "apply":
        lock_path.parent.mkdir(parents=True, exist_ok=True)
        lock = lock_path.open("a+")
        fcntl.flock(lock, fcntl.LOCK_EX)
    got, checked = load_manifest(args.manifest, args.manifest_sha256)
    for name, _, old, new in checked:
        before = [] if old is None else old.decode("utf-8").splitlines(keepends=True)
        after = new.decode("utf-8").splitlines(keepends=True)
        sys.stdout.writelines(difflib.unified_diff(before, after, fromfile=f"a/{name}", tofile=f"b/{name}"))
    if args.command == "check":
        print(f"gcc canon check: {len(checked)} changes; manifest sha256 {got}")
        return
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    backup = Path(tempfile.mkdtemp(prefix=f"gcc-canon-{stamp}-"))
    staged = []
    for name, target, old, new in checked:
        target.parent.mkdir(parents=True, exist_ok=True)
        if old is not None:
            b = backup / name
            b.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, b)
        fd, temp = tempfile.mkstemp(prefix=".gcc-canon-", dir=target.parent)
        with os.fdopen(fd, "wb") as f:
            f.write(new)
        if old is not None:
            os.chmod(temp, target.stat().st_mode)
        staged.append((Path(temp), target))
    applied = []
    try:
        for temp, target in staged:
            temp.replace(target)
            applied.append(target)
    except OSError:
        for target in reversed(applied):
            relative = target.relative_to(ROOT)
            old_backup = backup / relative
            if old_backup.is_file():
                shutil.copy2(old_backup, target)
            elif target.exists():
                target.replace(backup / relative)
        raise
    rec = {"ts": datetime.now(timezone.utc).isoformat(), "session": os.environ.get("GCC_CODEX_SID", ""),
           "manifest_sha256": got, "paths": [name for name, *_ in checked], "backup": str(backup)}
    receipt = ROOT / "adapters/codex/state/canon-applies.jsonl"
    with receipt.open("a") as f:
        f.write(json.dumps(rec) + "\n")
    print(f"gcc canon apply: {len(checked)} files; backup {backup}")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, json.JSONDecodeError, UnicodeError) as exc:
        print(f"gcc canon: {exc}", file=sys.stderr)
        raise SystemExit(2)
