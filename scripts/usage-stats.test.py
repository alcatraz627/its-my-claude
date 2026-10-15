"""Checks that usage-stats.py's RATES table, its `rates --tsv` output and the
statusline's model-rates.tsv all say the same thing.

Run: python3 ~/.claude/scripts/usage-stats.test.py
"""
import importlib.util
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "zrecover"))
from testlib import expect, finish  # noqa: E402

SCRIPT = os.path.join(HERE, "usage-stats.py")
TSV_FILE = os.path.join(HERE, "statusline", "model-rates.tsv")

spec = importlib.util.spec_from_file_location("usage_stats", SCRIPT)
us = importlib.util.module_from_spec(spec)
spec.loader.exec_module(us)


def parse(text):
    rows = {}
    for line in text.splitlines():
        parts = line.split("\t")
        if len(parts) != 3:
            return None
        rows[parts[0]] = (float(parts[1]), float(parts[2]))
    return rows


r = subprocess.run([sys.executable, SCRIPT, "rates", "--tsv"], capture_output=True, text=True)
expect("rates --tsv exits 0", r.returncode == 0)
cmd_rows = parse(r.stdout)
expect("rates --tsv prints model<TAB>input<TAB>output on every line", cmd_rows is not None and len(cmd_rows) > 0)
expect("rates --tsv matches RATES exactly", cmd_rows == {k: tuple(v) for k, v in us.RATES.items()})

file_rows = parse(open(TSV_FILE).read()) if os.path.exists(TSV_FILE) else None
expect("model-rates.tsv exists and is well formed", file_rows is not None)
expect("model-rates.tsv matches RATES (regenerate: usage-stats.py rates --tsv > scripts/statusline/model-rates.tsv)",
       file_rows == {k: tuple(v) for k, v in us.RATES.items()})

# Prices checked against https://platform.claude.com/docs/en/about-claude/pricing on 2026-10-15.
for model, want in [("claude-opus-5", (5.0, 25.0)), ("claude-opus-5-5", (4.0, 20.0)),
                    ("claude-sonnet-5", (2.0, 10.0)), ("claude-sonnet-5-5", (2.0, 10.0)),
                    ("claude-fable-5-1", (10.0, 50.0))]:
    expect("priced: %s" % model, us.rate_for(model + "-20261001", True) == want)
expect("Haiku 5.5 is tiered by prompt size, so it stays unpriced rather than guessed",
       us.rate_for("claude-haiku-5-5", True) is None)
finish()
