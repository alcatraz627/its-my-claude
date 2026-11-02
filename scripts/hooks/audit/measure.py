#!/usr/bin/env python3
"""Turn one scan.py folder into the numbers the hook-tuning plan tracks, one per defect row, so
a change can be judged by a before and after instead of by the hook's own account of itself.

    measure.py SCAN_DIR [--save FILE] [--compare BASELINE.json]

Each measure is a plain number or small table. The ledger section compares what hooks logged
with what the transcripts show, because a gap there means the ledger cannot be used for tuning.
"""
import argparse
import collections
import datetime
import json
import os
import re
import statistics
import sys

WARN_LOG = os.environ.get("HOOK_AUDIT_WARN_LOG", os.path.expanduser("~/.claude/hooks/warn-events.jsonl"))
SECRET_LOG = os.environ.get("HOOK_AUDIT_SECRET_LOG", os.path.expanduser("~/.claude/logs/secret-leaks.jsonl"))
ARBITER_SEPARATOR = "\n\n--- next gate ---\n\n"
AUTOMATED = ("<task-notification", "[keepwarm]", "[usage-resume]", "<system-reminder")
# How to recognise each hook's message in a transcript, for comparing with its ledger rows.
TRANSCRIPT_SIGNS = {
    "guard-env-dump": r"\[env-dump\] Refused",
    "pr-review": r"PR review gate",
    "goal-paste": r"/goal paste",
    "format-gate": r"^format-gate",
    "doc-voice-gate": r"doc check|tells the owner the doc",
    "bare-id-cluster": r"bare-id",
    "guard-rg-replace-bundle": r"rg -r IS --replace",
}


def load(folder, name):
    """One message class from a scan. A scan killed partway leaves a torn last row, so skip it."""
    rows = []
    path = os.path.join(folder, name)
    if not os.path.exists(path):
        sys.exit("%s has no %s, so it is not a finished scan" % (folder, name))
    with open(path) as handle:
        for line in handle:
            try:
                rows.append(json.loads(line))
            except ValueError:
                continue
    return rows


def population(info):
    first = info.get("first") or ""
    if first.startswith("You enforce a style ledger"):
        return "style-critic"
    if first.startswith("show me examples"):
        return "show-me-examples"
    if info.get("entry") in ("sdk-cli", "sdk-py"):
        return "other-headless"
    return "human"


def gate_of(text):
    """Name the gate behind a Stop block, from the wording it uses."""
    if text.startswith("format-gate"):
        match = re.match(r"format-gate: re-emit once with all of these fixed\. (\S+)", text)
        return "format:" + (match.group(1).rstrip(":") if match else "?")
    for needle, name in [("PR review gate", "pr-review"), ("/goal paste", "goal-paste"), ("doc check", "doc-voice"),
                         ("tells the owner the doc", "doc-voice"), ("bare-id", "bare-id"), ("task list hasn't", "task-stale"),
                         ("queue drive", "queue"), ("you haven't answered", "ipc-owed"), ("request you haven't", "ipc-owed"), ("ui-verified", "ui-verified"),
                         ("structural-claim", "structural")]:
        if needle in text:
            return name
    return "other"


def ledger_rows(since, until):
    rows = []
    if not os.path.exists(WARN_LOG):
        return rows
    with open(WARN_LOG, errors="replace") as handle:
        for line in handle:
            try:
                row = json.loads(line)
            except ValueError:
                continue
            if since <= str(row.get("ts", "")) < until:
                rows.append(row)
    return rows


def measure(folder):
    """Every tracked number for one scan folder, keyed by the plan's row ids where one applies."""
    attachments = load(folder, "attachments.jsonl")
    stops = load(folder, "stop_blocks.jsonl")
    summaries = load(folder, "stop_summaries.jsonl")
    denials = load(folder, "tool_denials.jsonl")
    with open(os.path.join(folder, "sessions.json")) as f:
        sessions = json.load(f)
    with open(os.path.join(folder, "window.json")) as f:
        window = json.load(f)
    pop = {sid: population(info) for sid, info in sessions.items()}
    human = {sid for sid, p in pop.items() if p == "human" and not sessions[sid].get("sub")}
    m = {"window": window, "populations": dict(collections.Counter(pop.values()))}
    m["interactive_sessions"] = len(human)
    m["interactive_stops"] = sum(1 for s in summaries if s["sid"] in human)
    raw_blocks = [r for r in stops if r["sid"] in human]
    # The arbiter sends all gates in one message. Count each gate apart, and the messages as sent.
    human_blocks = [dict(r, text=part) for r in raw_blocks for part in r["text"].split(ARBITER_SEPARATOR)]
    m["interactive_block_messages"] = len(human_blocks)
    gates = collections.Counter(gate_of(r["text"]) for r in human_blocks)
    m["blocks_by_gate"] = dict(gates.most_common())

    # One stop can carry several gates. They land in the same second, whereas the reply text
    # can repeat across separate stops of one turn.
    per_stop = collections.Counter((r["sid"], r["ts"][:19]) for r in raw_blocks)
    m["interactive_blocked_stops"] = len(per_stop)
    m["H27_stops_with_2plus_messages"] = sum(1 for n in per_stop.values() if n >= 2)

    m["H1_critic_sessions"] = sum(1 for p in pop.values() if p == "style-critic")
    m["H2_stop_blocks_in_headless"] = sum(1 for r in stops if pop.get(r["sid"]) in ("style-critic", "other-headless", "show-me-examples"))
    m["H3_blocks_on_warm_replies"] = sum(1 for r in human_blocks if r.get("prev_assistant", "").strip().lower().rstrip(".") == "warm")

    keyword = re.compile(r"\[[\w-]+ memory\] This prompt names|- \d{4}-\d\d-\d\d \[|\[glossary\]|\[persona\]")
    m["H4_keyword_injects_on_automated_prompts"] = sum(
        1 for r in attachments if r.get("event") == "UserPromptSubmit" and r["atype"] == "hook_additional_context"
        and r["sid"] in human and (r.get("prompt") or "").lstrip().startswith(AUTOMATED) and keyword.search(r["text"]))

    ledger = ledger_rows(window["since"], window["until"])
    warn = [r for r in ledger if r.get("kind") == "warn"]
    m["H5_guard_env_dump"] = {"ledger": sum(1 for r in warn if r.get("hook_id") == "guard-env-dump"),
                              "transcript": sum(1 for r in denials if re.search(TRANSCRIPT_SIGNS["guard-env-dump"], r["text"][:400]))}
    review = [r for r in warn if r.get("hook_id") == "review-nudge"]
    m["H6_review_nudge_rows"] = {"total": len(review), "on_critics": sum(1 for r in review if pop.get(r.get("sid")) == "style-critic")}
    m["H6_known_session_share"] = round(sum(1 for r in warn if r.get("sid") in pop) / max(1, len(warn)), 3)
    logged = {r.get("hook_id") for r in ledger}
    m["H7_hooks_missing_from_ledger"] = [h for h in ("pr-review", "goal-paste", "secret-scan", "memory-reach", "guidance", "subagent-box")
                                         if not any(str(x or "").startswith(h) for x in logged)]
    emdash = [r for r in ledger if r.get("kind") == "heed" and r.get("hook_id") == "emdash"]
    m["H8_emdash_heed_rows_from_critics"] = sum(1 for r in emdash if pop.get(r.get("sid")) == "style-critic")
    # What actually followed each block: work, an explanation, or the same reply sent again.
    outcomes = collections.defaultdict(collections.Counter)
    dismissal = re.compile(r"still fails|on purpose|leaving|left it|as it is|known false|not mine|false alarm", re.I)
    for row in human_blocks:
        if row.get("next_tool"):
            outcome = "fixed"
        elif dismissal.search(row.get("next_text", "")):
            outcome = "dismissed"
        else:
            outcome = "no_action"
        outcomes[gate_of(row["text"])][outcome] += 1
    m["H8_block_outcomes"] = {gate: dict(c) for gate, c in sorted(outcomes.items())}

    fires = guidance_word = 0
    memory_false = collections.Counter()
    persona = notes = 0
    per_doc = collections.Counter()
    for row in attachments:
        if row["sid"] not in human:
            continue
        text = row["text"]
        # A hook's context appears twice in a transcript, as its raw output and as the inject.
        if row.get("event") == "PostToolUse" and row["atype"] == "hook_additional_context" and "does not read as a doc" in text:
            match = re.search(r"([\w.-]+) does not read as a doc", text)
            notes += 1
            per_doc[match.group(1) if match else "?"] += 1
        if row.get("event") != "UserPromptSubmit" or row["atype"] != "hook_additional_context":
            continue
        prompt = (row.get("prompt") or "").lower()
        for match in re.finditer(r"- \d{4}-\d\d-\d\d \[([^\]]+)\]", text):
            fires += 1
            keys = [k.strip().lower() for k in match.group(1).split(",")]
            if any(re.search(r"\b" + re.escape(k) + r"\b", prompt) for k in keys):
                guidance_word += 1
        for match in re.finditer(r"\[([\w-]+) memory\] This prompt names", text):
            name = match.group(1)
            if not (re.search(r"(?<![\w-])" + re.escape(name) + r"(?![\w-])", prompt) or name.replace("-", " ") in prompt):
                memory_false[name] += 1
        if "[persona]" in text:
            persona += 1
    m["H11_guidance"] = {"fires": fires, "on_real_keyword": guidance_word}
    m["H12_memory_false_loads"] = sum(memory_false.values())
    m["H12_by_project"] = dict(memory_false.most_common(6))
    m["H17_doc_notes"] = {"notes": notes, "files": len(per_doc), "per_file": round(notes / max(1, len(per_doc)), 1)}
    m["H18_persona_fires"] = persona

    if os.path.exists(SECRET_LOG):
        with open(SECRET_LOG, errors="replace") as handle:
            m["H13_secret_rows"] = sum(1 for line in handle if window["since"] <= str(json_ts(line)) < window["until"])
    else:
        m["H13_secret_rows"] = None

    relpath = collections.Counter()
    path_notes = [r for r in attachments if r["sid"] in human and r.get("event") == "Stop"
                  and r["atype"] == "hook_system_message" and "full paths:" in r["text"]]
    for row in human_blocks + path_notes:
        marker = "relpath: write the full path once:" if "relpath: write the full path once:" in row["text"] else "full paths:"
        if marker not in row["text"]:
            continue
        fragment = row["text"].split(marker, 1)[1].split(" | ")[0].split("\n")[0]
        for item in fragment.split(" ; "):
            if "->" in item:
                left, right = [x.strip() for x in item.split("->", 1)]
                relpath["items"] += 1
                relpath["bare"] += "/" not in left
                relpath["wrong_worktree"] += right.startswith("/private/tmp")
    m["H14_relpath"] = dict(relpath)
    m["H15_rg_r_denials"] = sum(1 for r in denials if r["sid"] in human and r["text"].startswith("PreToolUse")
                                and re.search(TRANSCRIPT_SIGNS["guard-rg-replace-bundle"], r["text"][:400]))
    m["H19_note"] = "fixture-based, see the plan"

    m["H20_path_blocks"] = gates["format:filename-dot"] + gates["format:relpath"]
    pr = [r for r in human_blocks if gate_of(r["text"]) == "pr-review"]
    kinds = collections.Counter("findings" if "no disposition" in r["text"] else ("retrigger" if "Retrigger" in r["text"] else "wait") for r in pr)
    m["H21_pr_review"] = {"total": len(pr), **kinds}
    over = []
    for row in human_blocks:
        match = re.search(r"terse-reply: (\d+) chars, prose cap (\d+) chars", row["text"])
        if match:
            over.append((int(match.group(1)) - int(match.group(2))) / int(match.group(2)))
    m["H22_terse"] = {"blocks": len(over), "median_over": round(statistics.median(over), 2) if over else 0,
                      "under_15pct": sum(1 for o in over if o < .15)}
    m["H23_dp_server_ipc_owed"] = sum(1 for r in human_blocks if gate_of(r["text"]) == "ipc-owed" and "dp-server" in r["text"])
    m["H24_review_nudge_stop_messages"] = sum(1 for r in attachments if r["sid"] in human and r.get("event") == "Stop"
                                              and r["atype"] == "hook_system_message" and "review-nudge" in r["text"])
    boxes = [r for r in attachments if r["sid"] in human and r["atype"] == "hook_additional_context" and "subagent-box" in r["text"][:60]]
    m["H25_box_injects"] = {"count": len(boxes), "chars": sum(r["chars"] for r in boxes)}
    m["H29_explanatory_injects"] = sum(1 for r in attachments if r.get("event") == "SessionStart"
                                       and r["atype"] == "hook_additional_context" and "explanatory' output style" in r["text"])
    m["H30_signature_denials"] = sum(1 for r in denials if r["sid"] in human and re.search(r"carries an AI si|ai-signature:", r["text"][:500]))
    goal = [r for r in human_blocks if gate_of(r["text"]) == "goal-paste"]
    asks = r"\?\s|answer like|waiting on you|blocked on|your call|your go|say go|you to"
    m["H31_goal_paste"] = {"total": len(goal), "reply_asks_owner": sum(1 for r in goal if re.search(asks, r.get("prev_assistant", "")[-900:], re.I))}

    # A gap over a quarter means one of the two records is wrong, so tuning from the ledger would mislead.
    reconcile = {}
    all_blocks = [r["text"] for r in stops] + [r["text"][:400] for r in denials]
    for hook, sign in TRANSCRIPT_SIGNS.items():
        seen = sum(1 for t in all_blocks if re.search(sign, t))
        rows = sum(1 for r in warn if str(r.get("hook_id", "")).startswith(hook))
        gap = abs(rows - seen) / max(1, max(rows, seen))
        reconcile[hook] = {"ledger": rows, "transcript": seen, "flag": gap > 0.25}
    m["H10_reconcile"] = reconcile
    return m


def json_ts(line):
    try:
        return json.loads(line).get("ts", "")
    except ValueError:
        return ""


def compare(now, base):
    """Print every number that moved since the baseline, when the two can be compared at all.

    A shorter window or an empty scan would read as every defect shrinking.
    """
    if not now["window"].get("files"):
        sys.exit("this scan read no transcripts, so it says nothing about the baseline")
    now_days = (datetime.datetime.fromisoformat(now["window"]["until"]) - datetime.datetime.fromisoformat(now["window"]["since"])).days
    base_days = (datetime.datetime.fromisoformat(base["window"]["until"]) - datetime.datetime.fromisoformat(base["window"]["since"])).days
    if now_days != base_days:
        print("WINDOWS DIFFER: this scan covers %d days and the baseline %d, so raw counts are not comparable" % (now_days, base_days))
    for key in sorted(set(now) | set(base)):
        if key != "window" and now.get(key) != base.get(key):
            print("%-44s %s -> %s" % (key, json.dumps(base.get(key)), json.dumps(now.get(key))))


def main():
    parser = argparse.ArgumentParser(description="Measure hooks from a scan.py folder.")
    parser.add_argument("folder")
    parser.add_argument("--save", help="write the numbers to this JSON file")
    parser.add_argument("--compare", help="a saved baseline to compare with")
    args = parser.parse_args()
    numbers = measure(args.folder)
    if args.save:
        with open(args.save, "w") as f:
            json.dump(numbers, f, indent=1, sort_keys=True)
    if args.compare:
        with open(args.compare) as f:
            compare(numbers, json.load(f))
    else:
        print(json.dumps(numbers, indent=1, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
