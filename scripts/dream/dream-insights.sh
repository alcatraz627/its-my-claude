#!/bin/bash
# dream-insights.sh — inject the atone mistake-pattern TL;DR (always), and
# optionally the dream digest + top rules, into each session via SessionStart.
#
# Sources:
#   1. atone/derived/_tldr.txt — mistake patterns to watch (the load-bearing part)
#   2. insight-digest.md — synthesized dream summary (refreshed every 3h by daemon)
#   3. associations.json — top dream rules by confidence, deduplicated
#
# The dream half (sources 2+3) is OFF BY DEFAULT. It was ~1800 chars every session
# at a measured ~0 of ~922 promoted insights ever becoming a gcc change, it cannot
# be conversion-measured (acting on it leaves no machine residue — see
# ledger/acted.toml, which excludes it for exactly this reason), and it is now
# redundant: migration 0031 routes high-confidence dream insights onto the
# improvement backlog, where they get a real decision at /backlog-triage. The
# atone TL;DR (source 1) is unaffected — it is action-shaped and load-bearing, and
# has its own separate mute at atone/.tldr-off.
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

# Part 1: Digest summary (compact, pre-synthesized)
if dream_enabled and part_mode != 'ranked' and os.path.isfile(digest_path):
    try:
        with open(digest_path, 'r', encoding='utf-8', errors='replace') as f:
            digest = f.read().strip()
        if digest:
            parts.append(digest)
    except OSError:
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
        ranked = [it for (_s, it) in scored[:5]]
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
                if last_ids == ranked_ids:
                    ranked = []
            except Exception:
                pass
        if ranked:
            lines = [f"[{s:.2f}] {str(it.get('text','')).strip()}"
                     for (s, it) in scored[:5]]
            title = ("## Lessons re-ranked for this prompt (dream consolidation)"
                     if part_mode == 'ranked'
                     else "## Lessons ranked for this session (dream consolidation)")
            parts.append(title + "\n" + "\n".join(lines))
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

# Part 3: atone TL;DR (top mistake patterns + affirmed behaviors).
# Prepended (not appended) so it survives the 3500-char cap — atone is the
# more action-shape-specific content vs dream's free-form insights.
# _tldr.txt is regenerated by atone-consolidate.sh on every event add. Here we
# enrich its weak mistake lines (where the description just echoes the slug)
# with each pattern's `precheck` from the event log — so the injection carries
# the at-action-time check ("do this instead"), not a bare label.
import re
# ATONE_DIR_OVERRIDE exists for acceptance tests only — fixtures exercise the
# escalation ladder without touching the live atone ledger.
_atone_dir = os.path.expanduser(os.environ.get('ATONE_DIR_OVERRIDE') or "~/.claude/atone")
_atone_tldr = os.path.join(_atone_dir, "derived/_tldr.txt")
_atone_tldr_off = os.path.join(_atone_dir, ".tldr-off")
if part_mode != 'ranked' and os.path.isfile(_atone_tldr) and not os.path.isfile(_atone_tldr_off):
    try:
        with open(_atone_tldr, 'r', encoding='utf-8', errors='replace') as f:
            tldr = f.read().strip()

        # From the event log, per slug: the newest precheck (fallback fix) BY
        # ts — keyed on ts, not file order, because atone has backfilled events
        # out of chronological order — and how many times it recurred in the
        # last 7 days. The recurrence count drives blind-spot escalation below:
        # a pattern injected every session that KEEPS happening needs a louder
        # framing than "watch out for this". RFC3339-Z timestamps compare
        # lexically, so a string cutoff is sufficient.
        import datetime
        cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=7)).strftime(
            '%Y-%m-%dT%H:%M:%SZ'
        )
        prechecks = {}      # slug -> (ts, precheck)
        recent_count = {}   # slug -> occurrences in the last 7 days
        ev_path = os.path.join(_atone_dir, "events.jsonl")
        if os.path.isfile(ev_path):
            with open(ev_path, 'r', encoding='utf-8', errors='replace') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        o = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    s = o.get('slug')
                    if not s:
                        continue
                    ts = o.get('ts') or ''
                    if ts >= cutoff:
                        recent_count[s] = recent_count.get(s, 0) + 1
                    pc = (o.get('precheck') or o.get('fix') or '').strip()
                    if not pc:
                        continue
                    pc = ' '.join(pc.split())
                    if s not in prechecks or ts >= prechecks[s][0]:
                        prechecks[s] = (ts, pc)

        # The escalation ladder (docs/25 item 15): advisory → rule → hook.
        # Per slug, find its graduated rule in ~/.claude/rules/ and whether
        # that rule already carries a mechanical hook (the rule text names a
        # scripts/hooks/ path). One scan per session start, ~40 small files.
        slug_rule = {}      # slug -> (rule_path, has_hook)
        rules_dir = os.path.expanduser(
            os.environ.get('RULES_DIR_OVERRIDE') or "~/.claude/rules"
        )
        try:
            for fn in sorted(os.listdir(rules_dir)):
                if not fn.endswith(".md"):
                    continue
                fp = os.path.join(rules_dir, fn)
                try:
                    with open(fp, 'r', encoding='utf-8', errors='replace') as rf:
                        body = rf.read()
                except OSError:
                    continue
                # Provenance phrasing varies across real rules ("Graduated
                # from", "Graduated immediately from", "Promoted", lowercase
                # "graduated", "Provenance: atone slug") — the old exact
                # "Graduated from" gate silently skipped real graduated rules
                # (validation 2026-07-13 finding 2). Case-insensitive stems.
                body_lower = body.lower()
                if not any(k in body_lower
                           for k in ("graduated", "provenance", "promoted")):
                    continue
                has_hook = "scripts/hooks/" in body
                for mslug in re.findall(r'slug[s]?\s+`?([a-z0-9-]{8,})`?', body):
                    slug_rule.setdefault(mslug, (fn, has_hook))
        except OSError:
            pass

        def already_proposed_or_rejected(slug):
            # An escalation must not re-file what the human already has in
            # the backlog OR already rejected (the audit-side rejection
            # memory's sibling check — otherwise this lane grows its own
            # zombies). Word-boundary match: a bare substring let an
            # unrelated proposal mentioning "<slug>-v2-legacy" suppress the
            # real slug forever (validation 2026-07-13 finding 3).
            pat = re.compile(
                r'(?<![a-z0-9-])' + re.escape(slug) + r'(?![a-z0-9-])'
            )
            for p in ("~/.claude/proposals.jsonl",
                      "~/.claude/i-dream/audits/_rejections.jsonl",
                      "~/.claude/i-dream/audits/_archived/rejections-expired.jsonl"):
                fp = os.path.expanduser(p)
                try:
                    with open(fp, 'r', encoding='utf-8', errors='replace') as f:
                        if pat.search(f.read()):
                            return True
                except OSError:
                    continue
            return False

        # Rewrite each "⚠️ [SEV, Nx] slug — <desc>" line per the ladder:
        #  • rule + hook  → drop the line entirely (mechanically enforced;
        #    re-injecting it is noise)
        #  • rule + recurring ≥2×/7d → the advisory failed at the rule rung:
        #    emit a hook proposal (deduped) instead of repeating the reminder
        #  • otherwise: enrich a weak description with the precheck, and
        #    escalate the framing to a 🔴 blind-spot callout when recurring
        line_re = re.compile(r'^(\s*)⚠️?\s*\[([^\]]*)\]\s*(\S+)\s+—\s+(.*)$')
        out_lines = []
        injected_slugs = []
        enforced_omitted = 0
        for ln in tldr.splitlines():
            m = line_re.match(ln)
            if m:
                indent, bracket, slug, desc = (
                    m.group(1), m.group(2), m.group(3), m.group(4).strip()
                )
                rule_entry = slug_rule.get(slug)
                if rule_entry and rule_entry[1]:
                    # Rule AND hook exist — enforced mechanically, drop.
                    enforced_omitted += 1
                    continue
                rc = recent_count.get(slug, 0)
                if rule_entry and not rule_entry[1] and rc >= 2:
                    # Rule exists, still recurring: hand off to the hook rung.
                    filed = ""
                    if not already_proposed_or_rejected(slug):
                        # Fixture runs (ATONE_DIR_OVERRIDE) must never file a
                        # real proposal from fabricated evidence, even if the
                        # caller forgot INJECT_TEST — the two gates were
                        # independent footguns (validation 2026-07-13).
                        if (os.environ.get('INJECT_TEST') == '1'
                                or os.environ.get('ATONE_DIR_OVERRIDE')):
                            filed = " (test mode: proposal NOT filed)"
                        else:
                            import subprocess
                            try:
                                r = subprocess.run(
                                    ["bash", os.path.expanduser("~/.claude/scripts/propose.sh"),
                                     "add",
                                     "--title", f"Hook to mechanically enforce {slug} (rule exists, still recurring)",
                                     "--body", f"Auto-escalated by the query-conditioned injector (docs/25 item 15): slug {slug} has rule {rule_entry[0]} and was injected every session, yet recurred {rc}x in the last 7 days. The advisory->rule rungs are not landing; propose a mechanical gate.",
                                     "--category", "hooks", "--effort", "medium",
                                     "--tags", "src:injector-escalation"],
                                    capture_output=True, timeout=10,
                                )
                                # A non-zero exit is a FAILED filing — saying
                                # "filed" on a broken propose.sh defeats the
                                # ladder (validation 2026-07-13 finding 1).
                                if r.returncode == 0:
                                    filed = " (hook proposal filed)"
                                else:
                                    filed = " (proposal filing failed — will retry next session)"
                            except Exception:
                                filed = " (proposal filing failed — will retry next session)"
                    else:
                        filed = " (already in backlog/rejections — not re-filed)"
                    injected_slugs.append(slug)
                    out_lines.append(
                        f"{indent}↗ [{bracket} · rule {rule_entry[0]} not landing, "
                        f"{rc}× this week] {slug} — escalated to hook rung{filed}"
                    )
                    continue
                injected_slugs.append(slug)
                entry = prechecks.get(slug)
                pc = entry[1] if entry else None
                weak = (desc == slug or len(desc) <= len(slug) + 3)
                guidance = pc if (pc and weak) else desc
                if rc >= 2:
                    ln = (
                        f"{indent}🔴 [{bracket} · {rc}× THIS WEEK, still recurring "
                        f"despite this reminder — this is a blind spot, slow down] "
                        f"{slug} → {guidance}"
                    )
                elif pc and weak:
                    ln = f"{indent}⚠️  [{bracket}] {slug} → {pc}"
            out_lines.append(ln)
        if enforced_omitted:
            out_lines.append(
                f"  ({enforced_omitted} pattern(s) omitted — already mechanically enforced by a hook)"
            )
        tldr = "\n".join(out_lines)

        if tldr:
            parts.insert(0, "### Atone — patterns to watch\n" + tldr)

        # Record what was flagged this session so `i-dream reflect` can show
        # "warned N sessions" alongside the recurrence trend. Best-effort — a
        # log-write failure must never break the session injection.
        if injected_slugs and os.environ.get('INJECT_TEST') != '1':
            try:
                import datetime
                inj_dir = os.path.expanduser("~/.claude/i-dream")
                os.makedirs(inj_dir, exist_ok=True)
                ts = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
                rec = json.dumps({"ts": ts, "slugs": injected_slugs})
                with open(os.path.join(inj_dir, "injections.jsonl"), "a",
                          encoding="utf-8") as f:
                    f.write(rec + "\n")
            except Exception:
                pass
    # Catch ANY error, not just OSError: this block runs at every SessionStart
    # and must never break the hook (which would drop the injected context).
    except Exception:
        pass

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
