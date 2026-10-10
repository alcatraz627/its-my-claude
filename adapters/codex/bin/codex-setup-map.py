#!/usr/bin/env python3
"""Check the installed Codex adapter against its current gcc sources."""

import argparse
import json
from pathlib import Path


def rule_rows(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    return {
        line.split("|")[1].strip(): line.strip()
        for line in path.read_text(errors="replace").splitlines()
        if line.startswith("| `")
    }


def target_ok(link: Path, target: Path) -> bool:
    return link.is_symlink() and link.resolve() == target.resolve()


def inspect(home: Path) -> dict:
    gcc = home / ".claude"
    adapter = gcc / "adapters/codex"
    codex = home / ".codex"
    agents = home / ".agents/skills"
    source_rows = rule_rows(gcc / "rules/00-index.md")
    installed_rows = rule_rows(codex / "AGENTS.md")
    missing = sorted(source_rows.keys() - installed_rows.keys())
    extra = sorted(installed_rows.keys() - source_rows.keys())
    changed = sorted(k for k in source_rows.keys() & installed_rows.keys() if source_rows[k] != installed_rows[k])
    checks = []

    def add(name: str, ok: bool, detail: str) -> None:
        checks.append({"name": name, "ok": ok, "detail": detail})

    add("rule_menu", bool(source_rows) and not (missing or extra or changed),
        f"source={len(source_rows)} installed={len(installed_rows)} missing={len(missing)} extra={len(extra)} changed={len(changed)}")
    agents_md = codex / "AGENTS.md"
    size = agents_md.stat().st_size if agents_md.is_file() else 0
    add("agents_size", 0 < size <= 32768, f"{size}/32768 bytes (default cap)")
    add("hooks_link", target_ok(codex / "hooks.json", adapter / "hooks.json"), str(codex / "hooks.json"))
    add("execpolicy_link", target_ok(codex / "rules/gcc.rules", adapter / "rules/gcc.rules"), str(codex / "rules/gcc.rules"))

    list_file = adapter / "skills.list"
    gcc_names = [line.strip() for line in list_file.read_text().splitlines()
                 if line.strip() and not line.lstrip().startswith("#")] if list_file.is_file() else []
    for name in gcc_names:
        override = adapter / "skills" / name
        target = override if (override / "SKILL.md").is_file() else gcc / "skills" / name
        add(f"gcc_skill:{name}", target_ok(agents / name, target), str(agents / name))
    add("codex_skill:core-dump", target_ok(agents / "core-dump", adapter / "skills/core-dump"), str(agents / "core-dump"))
    for path in sorted((adapter / "skills").glob("*/SKILL.md")):
        name = path.parent.name
        if name != "core-dump":
            add(f"codex_skill:{name}", target_ok(codex / "skills" / name, path.parent), str(codex / "skills" / name))

    hook_file = adapter / "hooks.json"
    try:
        data = json.loads(hook_file.read_text())
        matchers = [entry.get("matcher", "") for entry in data["hooks"].get("PreToolUse", [])]
        add("patch_hook", any("apply_patch" in m for m in matchers), f"PreToolUse matchers={matchers}")
        post = data["hooks"].get("PostToolUse", [])
        stop = data["hooks"].get("Stop", [])
        journal = any("turn-guard.py post" in hook.get("command", "") for group in post for hook in group.get("hooks", []))
        completion = any("turn-guard.py stop" in hook.get("command", "") for group in stop for hook in group.get("hooks", []))
        add("turn_evidence_hook", journal, "PostToolUse turn-guard.py post")
        add("completion_hook", completion, "Stop turn-guard.py stop")
    except (OSError, ValueError, KeyError, TypeError) as exc:
        add("patch_hook", False, f"cannot parse hooks.json: {exc}")
        add("turn_evidence_hook", False, f"cannot parse hooks.json: {exc}")
        add("completion_hook", False, f"cannot parse hooks.json: {exc}")

    return {
        "ok": all(c["ok"] for c in checks),
        "checks": checks,
        "rule_menu": {"missing": missing, "extra": extra, "changed": changed},
        "note": "Codex TUI hook trust is per hash; after hooks.json changes, trust the new entry in /hooks.",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--home", type=Path, default=Path.home(), help="home directory to inspect")
    parser.add_argument("--json", action="store_true", help="print machine-readable result")
    parser.add_argument("--check", action="store_true", help="exit 1 when any check fails")
    args = parser.parse_args()
    report = inspect(args.home.expanduser())
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        for check in report["checks"]:
            print(f"{'ok' if check['ok'] else 'DRIFT'}  {check['name']}: {check['detail']}")
        if report["rule_menu"]["missing"]:
            print("missing rules:", ", ".join(report["rule_menu"]["missing"]))
        print(report["note"])
    return int(args.check and not report["ok"])


if __name__ == "__main__":
    raise SystemExit(main())
