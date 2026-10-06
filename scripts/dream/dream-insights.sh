#!/bin/bash
# dream-insights.sh: optionally inject the dream digest and ranked lessons into
# each session via SessionStart. Off by default, so it usually prints nothing.
#
# Sources:
#   1. insight-digest.md: synthesized dream summary (refreshed every 3h by daemon)
#   2. the derived patterns view: lessons ranked for this session
#
# The atone TL;DR this script used to prepend is retired (owner ruling D12,
# 2026-10-06); see the note where its part was.
#
# The dream half is OFF BY DEFAULT. It was ~1800 chars every session
# at a measured ~0 of ~922 promoted insights ever becoming a gcc change, it cannot
# be conversion-measured (acting on it leaves no machine residue — see
# ledger/acted.toml, which excludes it for exactly this reason), and it is now
# redundant: migration 0031 routes high-confidence dream insights onto the
# improvement backlog, where they get a real decision at /backlog-triage.
#
# Re-enable ambient dream injection (opt-in, default off):
#   touch ~/.claude/subconscious/dreams/.inject-on
# Polarity is deliberately an ENABLE flag, not a mute: the default is OFF, so
# presence = inject (guards against the inverted-opt-in-polarity trap).
#
# Output: JSON {"additionalContext": "..."} to stdout, or nothing (silent exit).

SUBCON="$HOME/.claude/subconscious/dreams"
DIGEST_FILE="$SUBCON/insight-digest.md"
ASSOC_FILE="$SUBCON/associations.json"
DREAM_ON_FLAG="$SUBCON/.inject-on"

DREAM_ENABLED=0
[ -f "$DREAM_ON_FLAG" ] && DREAM_ENABLED=1
# Test/preview override — lets acceptance runs exercise the dream half
# without flipping the machine-wide flag.
[ "${INJECT_DREAM:-}" = "1" ] && DREAM_ENABLED=1

python3 - "$DIGEST_FILE" "$ASSOC_FILE" "$DREAM_ENABLED" "${INJECT_PART:-all}" <<'PYEOF'
import sys, json, os

digest_path = sys.argv[1]
assoc_path = sys.argv[2]
dream_enabled = sys.argv[3] == "1"
# 'all' = the full SessionStart block; 'ranked' = ONLY the query-ranked lessons
# section, for the first-prompt UserPromptSubmit lane (docs/25 item 15 tail).
part_mode = sys.argv[4] if len(sys.argv) > 4 else 'all'

parts = []

# Parts 1 & 2 (the dream half) are gated OFF by default — see the header. The
# atone TL;DR (Part 3) below always runs. When the dream half is disabled we skip
# straight to it, so a session pays for the mistake-pattern reminder and nothing
# more.

# Part 1: Digest summary — dieted to ~2 sentences + pointer (B4 subtraction
# experiment, owner ruling; A3 curves measure the expectation of no degradation).
if dream_enabled and part_mode != 'ranked' and os.path.isfile(digest_path):
    try:
        with open(digest_path, 'r', encoding='utf-8', errors='replace') as f:
            digest = f.read().strip()
        if digest:
            # First real paragraph: skip headings and _subtitle_ lines, join
            # wrapped lines BEFORE sentence-splitting (gate BLOCKER-1).
            paras, cur = [], []
            for l in digest.splitlines():
                s = l.strip()
                if not s or s.startswith('#'):
                    if cur:
                        paras.append(' '.join(cur))
                        cur = []
                    continue
                if s.startswith('_') and s.endswith('_'):
                    continue
                cur.append(s)
            if cur:
                paras.append(' '.join(cur))
            first_para = paras[0] if paras else ''
            brief = '. '.join(first_para.split('. ')[:2]).strip()
            if len(brief) > 400:
                brief = brief[:397].rsplit(' ', 1)[0] + '…'
            elif brief and not brief.endswith('.'):
                brief += '.'
            if brief:
                parts.append("# Insight Digest (dieted — full: " + digest_path + ")\n"
                             + brief)
    except Exception:
        pass

# Part 2: query-conditioned lesson ranking over the derived patterns view
# (docs/25 item 15). The old static top-N-by-confidence injected the same
# five things into every session at measured ~0 efficacy; this ranks by
# importance × recency × relevance to THIS session's query (cwd path tokens
# + optional INJECT_QUERY, which a future first-prompt hook can supply).
# Deliberately no vector DB, no embeddings — keyword/path overlap only.
if dream_enabled:
    try:
        view_path = os.path.expanduser(
            "~/.claude/i-dream/derived/views/patterns.json"
        )
        view_items = []
        if os.path.isfile(view_path):
            with open(view_path, 'r', encoding='utf-8', errors='replace') as f:
                view = json.load(f)
            # Accept both the ViewFile wrapper and a bare list. (The old
            # one-liner called .get() on a list and the fallback was dead
            # code — validation 2026-07-13 finding 4.)
            if isinstance(view, list):
                view_items = view
            elif isinstance(view, dict):
                view_items = view.get('items', [])

        # The query: cwd path components + any caller-supplied text. Hook
        # stdin carries cwd at SessionStart; env overrides serve tests and
        # the future prompt-conditioned lane.
        raw_query = os.environ.get('INJECT_QUERY', '')
        # A byte-capped env value can arrive with a torn multibyte character
        # (surrogateescape); normalize now so no later strict re-encode —
        # logging, JSON round-trip — can ever throw on it.
        raw_query = raw_query.encode('utf-8', 'replace').decode('utf-8', 'replace')
        cwd = os.environ.get('INJECT_CWD') or os.environ.get('PWD', '')
        query_tokens = set()
        for src in (raw_query, cwd.replace('/', ' ').replace('-', ' ')):
            for w in src.lower().split():
                if len(w) > 2:
                    query_tokens.add(w)
        cwd_leaf = os.path.basename(cwd.rstrip('/')).lower()

        def as_num(v, default=0.0):
            try:
                return float(v)
            except (TypeError, ValueError):
                return default

        def score(it):
            strength = as_num(it.get('strength'), -1.0)
            conf = as_num(it.get('confidence'), 0.0)
            importance = strength if strength >= 0 else conf
            importance *= 1.0 + 0.25 * min(as_num(it.get('reactivations'), 0.0), 4.0)
            days = as_num(it.get('days_since_last_seen'), 60.0)
            recency = 1.0 / (1.0 + days / 30.0)
            text_tokens = {w for w in
                           ''.join(c if c.isalnum() else ' ' for c in
                                   str(it.get('text', '')).lower()).split()
                           if len(w) > 2}
            overlap = len(query_tokens & text_tokens)
            relevance = 1.0 + 0.15 * min(overlap, 6)
            projects = [str(p).lower() for p in it.get('source_projects', []) or []]
            if cwd_leaf and any(cwd_leaf in p or p in cwd_leaf for p in projects if p):
                relevance *= 2.0
            return importance * recency * relevance

        # Score per item under its own guard, so one corrupt item costs only
        # itself instead of blanking the whole section (validation 2026-07-13
        # finding 5 — the item-14 tolerant-reader principle, applied here).
        scored = []
        for it in view_items:
            if not isinstance(it, dict) or not it.get('is_representative', True):
                continue
            try:
                scored.append((score(it), it))
            except Exception:
                continue
        scored.sort(key=lambda t: t[0], reverse=True)
        # B4 diet: session lane carries 3; the prompt lane keeps 5 (delta-gated).
        top_n = 5 if part_mode == 'ranked' else 3
        ranked = [it for (_s, it) in scored[:top_n]]
        # The prompt lane only speaks when it has something NEW: if the
        # re-ranked top-5 matches the last dream injection (either lane), it
        # stays silent — SessionStart already delivered exactly this set.
        # Tolerant per-line read: a malformed ledger line costs only itself.
        ranked_ids = [it.get('stable_id', '') for it in ranked]
        if ranked and part_mode == 'ranked':
            try:
                # Dedupe against what THIS session was shown — records are
                # matched by sid, never globally: the last global entry may
                # belong to a different concurrent session, and matching it
                # would silently starve this one (gate finding 1, 2026-07-14).
                # Records without sid (pre-change history) never match.
                my_sid = os.environ.get('INJECT_SID', '')
                inj_path = os.path.expanduser("~/.claude/i-dream/injections.jsonl")
                last_ids = None
                if my_sid and os.path.isfile(inj_path):
                    with open(inj_path, 'r', encoding='utf-8', errors='replace') as f:
                        for line in f:
                            try:
                                obj = json.loads(line)
                            except Exception:
                                continue
                            if (isinstance(obj, dict)
                                    and obj.get('kind') in (
                                        'dream-ranked', 'dream-ranked-prompt')
                                    and obj.get('sid') == my_sid):
                                last_ids = obj.get('ids')
                # Speak only when something is NEW vs the last injection this
                # session saw — a subset re-delivery is noise (gate MAJOR-2:
                # exact-match dedupe died when session/prompt lane sizes split).
                if last_ids and not [i for i in ranked_ids if i not in last_ids]:
                    ranked = []
            except Exception:
                pass
        if ranked:
            def _ltag(it):
                sid8 = str(it.get('stable_id', ''))[:8]
                return f"[L:{sid8}] " if sid8 else ""
            lines = [f"[{s:.2f}] {_ltag(it)}{str(it.get('text','')).strip()}"
                     for (s, it) in scored[:top_n]]
            title = ("## Lessons re-ranked for this prompt (dream consolidation)"
                     if part_mode == 'ranked'
                     else "## Lessons ranked for this session (dream consolidation)")
            cite = ("_When a lesson above changes what you do, cite its "
                    "[L:xxxxxxxx] tag in your reply — cited lessons are "
                    "reinforced; silent ones decay._")
            parts.append(title + "\n" + "\n".join(lines) + "\n" + cite)
            # Entropy health signal (docs/25 item 15): log WHICH lessons were
            # injected so `i-dream reflect` can measure injected-set variety.
            # Test runs stay out of the health data.
            if os.environ.get('INJECT_TEST') != '1':
                try:
                    import datetime as _dt
                    inj_dir = os.path.expanduser("~/.claude/i-dream")
                    os.makedirs(inj_dir, exist_ok=True)
                    rec = {
                        "ts": _dt.datetime.now(_dt.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
                        "kind": ("dream-ranked-prompt" if part_mode == 'ranked'
                                 else "dream-ranked"),
                        "ids": ranked_ids,
                        "cwd_leaf": cwd_leaf,
                    }
                    sid = os.environ.get('INJECT_SID', '')
                    if sid:
                        rec["sid"] = sid
                    with open(os.path.join(inj_dir, "injections.jsonl"), "a",
                              encoding="utf-8") as f:
                        f.write(json.dumps(rec) + "\n")
                except Exception:
                    pass
    # Never break SessionStart: a ranking failure just skips the dream half.
    except Exception:
        pass

# The atone TL;DR that used to be Part 3 is retired (owner ruling D12, 2026-10-06):
# 14,000 injections across the top slugs moved no recurrence count. i-dream's weekly
# reader lands findings on a decision page instead. The TL;DR file itself is still
# written by atone-consolidate.sh for anything that reads it on purpose.

if not parts:
    sys.exit(0)

header = (
    "## Dream Insights + Atone (i-dream + atone)\n"
    "_High-confidence rules from background memory consolidation, plus mistake/affirmation "
    "patterns from the atone system. Behavioral directives — read once per session._\n\n"
)

# The prompt lane emits only its own section — the SessionStart block already
# delivered the header and the atone TL;DR.
content = ("\n\n".join(parts) if part_mode == 'ranked'
           else header + "\n\n".join(parts))

# Hard cap at 3500 chars to stay lean
if len(content) > 3500:
    content = content[:3450] + "\n...(truncated)"

print(json.dumps({"additionalContext": content}))
PYEOF
