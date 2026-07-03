#!/usr/bin/env python3
"""ta mine — turn a corpus query into ready-to-paste sub-agent prompts.

This is a scaffold, not a dispatcher: it runs a `ta query`, chunks the matching
turns into batches, and for each batch prints a self-contained prompt built from
a named preset (the mining question + output schema). The parent agent or a
Workflow pastes each prompt into an Agent dispatch. Presets live as one .md per
question in ../presets/.
"""

import argparse
import datetime
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ta_core as C  # noqa: E402
import query as Q  # noqa: E402

PRESETS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "presets")


def load_preset(name):
    path = os.path.join(PRESETS_DIR, name + ".md")
    if not os.path.isfile(path):
        avail = ", ".join(sorted(
            os.path.splitext(f)[0] for f in os.listdir(PRESETS_DIR) if f.endswith(".md")
        )) if os.path.isdir(PRESETS_DIR) else "(none)"
        sys.stderr.write("ta mine: no preset '%s' (available: %s)\n" % (name, avail))
        sys.exit(2)
    with open(path, encoding="utf-8") as fh:
        return path, fh.read().strip()


def chunk(rows, size):
    for i in range(0, len(rows), size):
        yield rows[i:i + size]


def render_batch(preset_body, rows, batch_no, batch_total, out_path):
    lines = []
    lines.append("You are a transcript-mining sub-agent. Batch %d of %d." % (batch_no, batch_total))
    lines.append("")
    lines.append(preset_body)
    lines.append("")
    lines.append("## Turns to inspect in THIS batch (%d)" % len(rows))
    lines.append("")
    lines.append("Each pointer is  <transcript_path> :: turn <idx> :: <session> :: <when>")
    lines.append("with a snippet. When a snippet is not enough, Read the transcript file")
    lines.append("(turns are delimited by real user messages) or re-run:")
    lines.append("  ta query --project <substr> --user-match '<a distinctive phrase>' --format jsonl")
    lines.append("")
    for n, r in enumerate(rows, 1):
        lines.append("%d. %s :: turn %s :: %s :: %s" % (
            n, r["transcript_path"], r["turn_index"],
            (r["session_id"] or "?")[:8], (r["ts"] or "")[:19]))
        lines.append("   > %s" % r["snippet"])
    lines.append("")
    lines.append("## Persist before returning")
    lines.append("Write your findings to: %s" % out_path)
    lines.append("Then return:  WROTE: %s  + a 5-bullet abstract of what you found." % out_path)
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="ta mine", description="emit ready-to-paste sub-agent mining prompts over matched turns")
    Q.add_query_args(ap)
    ap.add_argument("--preset", required=True, help="preset name (see ../presets/*.md)")
    ap.add_argument("--batch-size", type=int, default=30, help="turns per batch (default 30)")
    ap.add_argument("--snippet-len", type=int, default=800,
                    help="chars of context per turn in the prompt (default 800)")
    ap.add_argument("--out-dir", default="", help="base dir for suggested sub-agent output paths")
    a = ap.parse_args(argv)

    preset_path, preset_body = load_preset(a.preset)

    spec = Q.spec_from_args(a)
    spec["snippet_len"] = a.snippet_len
    rows = C.run_query(spec)

    if not rows:
        print("ta mine: query matched 0 turns — nothing to mine.", file=sys.stderr)
        return 1

    today = datetime.date.today().strftime("%Y%m%d")
    out_base = a.out_dir or os.path.join(
        os.path.expanduser("~"), ".claude", "assets", "reports",
        "%s-ta-mine-%s" % (today, a.preset))

    batches = list(chunk(rows, a.batch_size))
    total = len(batches)
    print("# ta mine — preset '%s' — %d turns → %d batch(es) of ≤%d" %
          (a.preset, len(rows), total, a.batch_size))
    print("# preset source: %s" % preset_path)
    print("# suggested output dir: %s" % out_base)
    print()
    for i, batch in enumerate(batches, 1):
        out_path = os.path.join(out_base, "batch-%02d.md" % i)
        print("=" * 78)
        print("### BATCH %d/%d — paste the block below into an Agent dispatch" % (i, total))
        print("=" * 78)
        print(render_batch(preset_body, batch, i, total, out_path))
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
