#!/usr/bin/env python3
"""validate-shas.py — replace any SHA in a themes file not present in commits.tsv.

Catches the "fake-precise SHA" failure: the themes agent can emit SHA-shaped
strings (7-12 hex chars) that look like real commits but aren't in scope. This
script extracts every such token, checks it against the actual commit list, and
replaces unknown ones with `(post-cutoff)` — removing the SHA-hygiene burden
from the verifier entirely.

Usage:
  validate-shas.py <themes.md> <commits.tsv>

Writes the file in place. Logs replacements to <themes.md dir>/_sha-fixes.log.
"""
import sys, os, re

themes_path = sys.argv[1] if len(sys.argv) > 1 else "themes/THEMES.md"
commits_path = sys.argv[2] if len(sys.argv) > 2 else "01-commits.tsv"

# Known SHAs = first column of commits.tsv (short hashes).
known = set()
if os.path.exists(commits_path):
    with open(commits_path) as f:
        for line in f:
            sha = line.split("\t", 1)[0].strip()
            if sha:
                known.add(sha)

# Also accept any known SHA matched by prefix (commits.tsv uses short hashes;
# a theme may cite a longer form). Build a prefix check.
def is_known(sha):
    if sha in known:
        return True
    # prefix/suffix tolerance: a cited sha that starts-with or is-started-by a known one
    for k in known:
        if sha.startswith(k) or k.startswith(sha):
            return True
    return False

# Only treat a token as a SHA candidate when it appears in a commit-citation
# context (Commits: line, or backtick-wrapped hex). Avoid clobbering hex that is
# actually a color, hash id, etc. — restrict to 7-12 lowercase hex.
SHA_RE = re.compile(r"\b([0-9a-f]{7,12})\b")

with open(themes_path) as f:
    text = f.read()

fixes = []
def repl(m):
    sha = m.group(1)
    # Heuristic: skip pure-decimal (years, counts) — require at least one a-f letter
    if not re.search(r"[a-f]", sha):
        return sha
    if is_known(sha):
        return sha
    fixes.append(sha)
    return "(post-cutoff)"

# Only rewrite within lines that look like commit citations to avoid false positives.
out_lines = []
for line in text.split("\n"):
    if re.search(r"(?i)commits?\s*:", line) or "`" in line:
        out_lines.append(SHA_RE.sub(repl, line))
    else:
        out_lines.append(line)
new_text = "\n".join(out_lines)

if new_text != text:
    with open(themes_path, "w") as f:
        f.write(new_text)

log_path = os.path.join(os.path.dirname(themes_path) or ".", "_sha-fixes.log")
with open(log_path, "w") as f:
    f.write(f"known SHAs in commits.tsv: {len(known)}\n")
    f.write(f"replaced {len(fixes)} unknown SHAs with (post-cutoff):\n")
    for s in fixes:
        f.write(f"  {s}\n")

print(f"sha-validate: {len(known)} known, {len(fixes)} replaced → {log_path}")
