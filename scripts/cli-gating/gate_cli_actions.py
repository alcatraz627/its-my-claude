#!/usr/bin/env python3
"""Classifier core for selective CLI gating.

Reads a Bash command string + the gating policy, decides whether the command
performs a prod/unknown-env WRITE via a gated CLI (render/vercel/gh) that must
be hard-stopped. Prints a verdict line for the bash shim to act on.

Stdout protocol (single line):
  ALLOW                       -> shim exits 0
  BLOCK\t<reason>             -> shim exits 2 with <reason> on stderr

Core principle (revised 2026-05-21 after real false-positive incidents):
  Gate ONLY when a gated CLI is the actual COMMAND being invoked AND it's a
  write. Three things therefore ALWAYS pass:
    - reads (gh run view, render logs, vercel ls) — even with --jq/--json/quotes
      that defeat tokenizing;
    - a gated NAME that isn't the command (e.g. `bash render-visual.sh` — the
      script merely contains "render"; `cat file` with no gated CLI at all);
    - any command with no gated command-token anywhere.
  Writes via launcher/shell wrappers (env gh, /usr/bin/gh, bash -c "render
  deploy --prod") are still gated.

Threat model: a SEATBELT against accidental prod writes, not a vault door.
"""

import sys
import os
import shlex
import re

GATED = ("render", "vercel", "gh", "aws")
GATED_SET = frozenset(GATED)
SEGMENT_SPLIT = re.compile(r"\s*(?:&&|\|\||;|\||\n|&)\s*")
# Re-exec prefixes: the real command follows as a later TOKEN (env gh, sudo gh,
# nohup render, timeout 60 render). Unwrap them to find the real command.
RE_EXEC = frozenset({"env", "command", "nohup", "timeout", "nice", "stdbuf",
                     "setsid", "time", "sudo", "doas", "builtin", "exec", "xargs"})
# Shells that run a command from a STRING arg (bash -c "..."): recurse into it.
SHELL_C = frozenset({"bash", "sh", "zsh", "dash", "ksh"})
# eval runs its (joined) args as a command: recurse into the joined rest.
EVALISH = frozenset({"eval"})
NONREAD_HTTP = re.compile(r"\b(POST|PUT|PATCH|DELETE)\b", re.IGNORECASE)
ENV_ASSIGN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
# Mutating action sub-verbs. If any appears as a token, the command is a WRITE
# even when it sits under a read namespace (`render services delete`,
# `render env-vars set`, `render deploys cancel`) — a read-verb prefix must NOT
# launder a write subcommand.
MUTATING_SUBCMD = frozenset({
    "delete", "rm", "remove", "destroy", "drop", "set", "unset", "create",
    "scale", "cancel", "suspend", "resume", "restart", "update", "edit",
    "promote", "rollback", "prune", "purge", "rotate", "disable", "enable",
})


def _split_eq(tokens):
    """Normalize `--key=val` into `--key`,`val` so signal matching sees both
    halves (catches `--prod=true`, `--target=production`)."""
    out = []
    for t in tokens:
        if t.startswith("-") and "=" in t:
            k, v = t.split("=", 1)
            out.append(k)
            out.append(v)
        else:
            out.append(t)
    return out


def _split_segments(s):
    """Split a command on shell control operators (&& || ; | & newline) that sit
    OUTSIDE quotes. Returns the ORIGINAL substrings (quotes intact) so downstream
    shlex parsing of each segment is unchanged.

    A `|` inside a quoted string (e.g. an `rg "a|render|b"` alternation, a commit
    message, atone text) is literal and is never a segment boundary. Replaces the
    old quote-blind regex split, which mis-segmented quoted pipes into bare
    render/vercel/gh tokens and hard-blocked read-only commands.
    """
    segs, buf = [], []
    i, n = 0, len(s)
    quote = None
    while i < n:
        c = s[i]
        if quote is not None:
            buf.append(c)
            if c == quote:
                quote = None
            elif c == "\\" and quote == '"' and i + 1 < n:
                buf.append(s[i + 1])
                i += 2
                continue
            i += 1
            continue
        if c in ("'", '"'):
            quote = c
            buf.append(c)
            i += 1
            continue
        if c == "\\" and i + 1 < n:  # escaped char outside quotes
            buf.append(c)
            buf.append(s[i + 1])
            i += 2
            continue
        if s[i:i + 2] in ("&&", "||"):
            segs.append("".join(buf))
            buf = []
            i += 2
            continue
        if c in (";", "|", "&", "\n"):
            segs.append("".join(buf))
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    segs.append("".join(buf))
    return segs


def load_policy(path):
    import json
    try:
        with open(path) as f:
            return json.load(f) or _fallback_policy()
    except (FileNotFoundError, ValueError):
        return _fallback_policy()


def _fallback_policy():
    return {
        "gates": [
            {"cli": "render", "read_verbs": ["services", "list", "get", "logs", "ps", "deploys", "env-vars", "psql", "help", "version", "whoami"],
             "prod_signals": ["--prod", "--production"], "dev_signals": ["--env dev", "--env staging"],
             "default_env": "prod", "gate_all_writes": True},
            {"cli": "vercel", "read_verbs": ["ls", "list", "inspect", "logs", "whoami", "help"],
             "read_action_verbs": ["ls", "list", "inspect", "get"],
             "prod_signals": ["--prod"], "dev_signals": ["--target preview"],
             "default_env": "dev", "safe_default_verbs": ["deploy"], "gate_all_writes": True},
            {"cli": "gh", "read_verbs": ["auth", "browse", "status", "repo view", "repo list", "pr view", "pr list", "pr diff", "pr checks", "issue view", "issue list", "run view", "run list", "release view", "release list", "search", "label list", "help"],
             "always_gate_verbs": ["repo delete", "release delete", "secret set", "secret delete"],
             "main_branch_gate_verbs": ["pr merge", "push", "release create", "release edit"],
             "main_branches": ["main", "master"]},
            {"cli": "aws",
             "read_op_prefixes": ["describe-", "list-", "get-", "lookup-", "head-", "batch-get-", "search-", "view-"],
             "read_ops_exact": ["ls", "help", "list", "get", "scan", "query", "select", "tail", "filter-log-events", "wait", "presign"],
             "sensitive_read_ops": ["get-secret-value", "batch-get-secret-value", "get-login-password", "get-session-token", "get-federation-token"],
             "prod_signals": ["--profile prod", "--profile production"],
             "dev_signals": ["--profile dev", "--profile development", "--profile staging"],
             "default_env": "prod", "gate_all_writes": True},
        ]
    }


def gate_for(cli, policy):
    for g in policy.get("gates", []):
        if g.get("cli") == cli:
            return g
    return None


def signal_in_tokens(signal, tokens):
    sig_toks = signal.split()
    n = len(sig_toks)
    if n == 0:
        return False
    for i in range(len(tokens) - n + 1):
        if tokens[i:i + n] == sig_toks:
            return True
    return False


def _tokenize(s):
    """(tokens, parse_ok). Falls back to whitespace split when shlex fails."""
    try:
        return shlex.split(s, comments=True), True
    except ValueError:
        return s.split(), False


def _base(tok):
    return os.path.basename(tok.strip().strip('"\''))


def _resolve_command(tokens):
    """Strip leading VAR= assignments + re-exec wrappers; return the index of the
    real command token (or len(tokens) if none)."""
    i = 0
    while i < len(tokens) and ENV_ASSIGN.match(tokens[i]):
        i += 1
    guard = 0
    while i < len(tokens) and guard < 12:
        guard += 1
        if _base(tokens[i]) in RE_EXEC:
            # `command -v|-V gh` only LOOKS UP gh — it does not execute it (unlike
            # plain `command gh …`, which does run it). Without this carve-out the
            # gated CLI name is read as the command and whatever follows (a
            # `>/dev/null` redirect, a `-flag`) becomes a bogus "write verb" — the
            # false positive that blocked `command -v gh >/dev/null && …`.
            if _base(tokens[i]) == "command" and i + 1 < len(tokens) and tokens[i + 1] in ("-v", "-V"):
                return len(tokens)
            i += 1
            # skip the wrapper's own flags / VAR= / a bare duration (timeout 60)
            while i < len(tokens) and (tokens[i].startswith("-")
                                       or ENV_ASSIGN.match(tokens[i])
                                       or re.match(r"^\d+[smhd]?$", tokens[i])):
                i += 1
            continue
        break
    return i


def _gh_api_verdict(rest, rest_str, segment):
    if NONREAD_HTTP.search(rest_str) or any(
            t in ("-f", "--field", "-F", "--raw-field", "--input") for t in rest):
        return ("block", f"gh api mutating call (non-GET method or field input): `{segment}`")
    return ("allow", None)


# AWS global options that take a VALUE and can appear BEFORE the service name
# (`aws --region us-east-1 s3 rm …`). Their value must be skipped so the service
# and operation are read from the right positions, not from a flag's argument.
# A leading global flag previously made the gate misread the flag as the service
# and wave the whole command through as a read — a destructive-write bypass.
AWS_GLOBAL_VALUE_FLAGS = frozenset({
    "--region", "--profile", "--output", "--endpoint-url", "--color",
    "--ca-bundle", "--cli-read-timeout", "--cli-connect-timeout",
    "--cli-binary-format", "--query", "--page-size", "--max-items",
    "--starting-token",
})


def _aws_service_op(rest):
    """Return (service, operation) for an `aws …` invocation, skipping global
    flags — and the values of value-taking ones — that may precede the service.

    Fail-safe by construction: a global value-flag we don't know at worst leaves
    its value sitting where the service is expected, which yields a non-read op
    and therefore a gated (blocked) verdict — never a wrongful allow."""
    pos = []
    i = 0
    while i < len(rest):
        t = rest[i]
        if t.startswith("-"):
            base = t.split("=", 1)[0]
            if "=" not in t and base in AWS_GLOBAL_VALUE_FLAGS:
                i += 2  # skip the flag AND its separate value token
                continue
            i += 1
            continue
        pos.append(t)
        i += 1
        if len(pos) >= 2:
            break
    return (pos[0] if pos else "", pos[1] if len(pos) > 1 else "")


def _aws_is_read(rest, g):
    """AWS commands are `aws <service> <operation>`. Returns True ONLY when a read
    can be POSITIVELY identified — the operation name starts with a known read
    prefix (describe-/list-/get-/lookup-/head-/…) or is an exact read (`s3 ls`,
    `dynamodb scan|query`). The prefix set is the closed dimension; it covers
    AWS's ~7000 verb-noun operations without enumerating them.

    Anything NOT provably a read — create-/delete-/put-/terminate-/run-/
    `s3 cp|sync|mv|rm`, an unknown op, an unparseable shape — falls through to a
    WRITE and is gated. For a security gate the unidentifiable case must block,
    never allow."""
    service, op = _aws_service_op(rest)
    if not service or service == "help":
        return True  # bare `aws`, `aws help`, `aws --version` -> usage text
    if not op or op == "help":
        return True  # `aws ec2`, `aws ec2 help` -> no operation, no mutation
    if op in set(g.get("read_ops_exact", ())):
        return True
    return any(op.startswith(p) for p in g.get("read_op_prefixes", ()))


def _aws_is_sensitive_read(op, rest, g):
    """Some AWS operations read no resource state yet hand back a live secret or
    credential — `secretsmanager get-secret-value`, `ecr get-login-password`, STS
    short-lived tokens, an SSM SecureString fetched with decryption. They mutate
    nothing, so the plain read rule would wave them through; but surfacing a
    credential deserves the same per-command approval a write gets. SSM
    `get-parameter*` is sensitive ONLY with --with-decryption (otherwise the
    value comes back masked)."""
    if op in set(g.get("sensitive_read_ops", ())):
        return True
    if op in ("get-parameter", "get-parameters", "get-parameters-by-path"):
        return any(t == "--with-decryption" or t.startswith("--with-decryption=")
                   for t in rest)
    return False


def _classify_gated(cmd, rest, parse_ok, policy, segment):
    """cmd is a confirmed gated CLI command. Decide read (allow) vs write (gate).
    Reads pass even if parse_ok is False (best-effort verb)."""
    g = gate_for(cmd, policy)
    if g is None:
        return ("allow", None)
    rest_str = " ".join(rest)
    verb = rest[0] if rest else ""

    if cmd == "gh" and verb == "api":
        return _gh_api_verdict(rest, rest_str, segment)

    # AWS: read iff the operation name matches a read prefix/exact; every other
    # operation is a mutation and is approval-gated (any account/env). Env label
    # is best-effort from --profile and is cosmetic — the gate blocks regardless.
    if cmd == "aws":
        _, op = _aws_service_op(rest)
        sensitive = _aws_is_sensitive_read(op, rest, g)
        if _aws_is_read(rest, g) and not sensitive:
            return ("allow", None)
        norm = _split_eq(rest)
        prod = any(signal_in_tokens(s, norm) for s in g.get("prod_signals", []))
        dev = any(signal_in_tokens(s, norm) for s in g.get("dev_signals", []))
        envlbl = "PROD" if prod else ("dev" if dev else g.get("default_env", "?"))
        if sensitive:
            return ("block", f"aws sensitive read [{envlbl}] - reads a live secret/credential (op={op}); approval-gated: `{segment}`")
        return ("block", f"aws write [{envlbl}] - every AWS mutation is approval-gated (op={op or '∅'}): `{segment}`")

    # A mutating sub-verb anywhere means this is a WRITE — a read-namespace
    # prefix (services/env-vars/deploys) must not launder it.
    has_mutating = any(_base(t) in MUTATING_SUBCMD for t in rest)

    # READ allowlist — checked first, and the ONLY thing that matters when the
    # segment failed to parse (a read with a --jq filter must still pass).
    # Skipped when a mutating sub-verb is present.
    if not has_mutating:
        for rv in g.get("read_verbs", []):
            rv_tokens = rv.split()
            if rest[:len(rv_tokens)] == rv_tokens:
                return ("allow", None)
        # Reads shaped `<cli> <noun> ls|inspect|get` (e.g. `vercel domains ls`).
        # The read action is the SECOND token under an open-ended resource noun.
        # Enumerated by action (closed set), not noun, so a new noun never
        # false-blocks. Still guarded by has_mutating above.
        rav = g.get("read_action_verbs", [])
        if rav and len(rest) >= 2 and rest[1] in rav:
            return ("allow", None)

    # If we could not parse the segment AND the verb isn't a known read, we don't
    # have enough to confidently call it a write of a specific shape — but an
    # unknown gated verb is exactly the conservative-gate case. However, to avoid
    # the read-with-weird-args false positive, require the FIRST token to look
    # like a subcommand (not a flag) before gating an unparseable segment.
    if not parse_ok and (not verb or verb.startswith("-")):
        return ("allow", None)  # can't identify a write verb; don't over-block

    # Every write to this CLI is approval-gated, any env. Reads already returned
    # allow above; what reaches here is a write. Block with an env label so the
    # approval prompt can show prod vs preview/dev.
    if g.get("gate_all_writes"):
        norm = _split_eq(rest)
        prod = any(signal_in_tokens(s, norm) for s in g.get("prod_signals", []))
        dev = any(signal_in_tokens(s, norm) for s in g.get("dev_signals", []))
        envlbl = "PROD" if prod else ("preview/dev" if dev else g.get("default_env", "?"))
        return ("block", f"{cmd} write [{envlbl}] - every write to any env is approval-gated: `{segment}`")

    if cmd == "gh":
        for av in g.get("always_gate_verbs", []):
            if rest_str.startswith(av):
                return ("block", f"gh write op always gated: `{av}`")
        for mv in g.get("main_branch_gate_verbs", []):
            if rest_str.startswith(mv):
                mains = g.get("main_branches", ["main", "master"])
                if any(re.search(rf"\b{re.escape(b)}\b", rest_str) for b in mains):
                    return ("block", f"gh `{mv}` targets a protected branch")
                return ("block", f"gh `{mv}` — target branch not provable as non-main; gating")
        return ("block", f"gh write/unknown verb (not in read allowlist): `{rest_str}`")

    norm = _split_eq(rest)
    prod = any(signal_in_tokens(s, norm) for s in g.get("prod_signals", []))
    dev = any(signal_in_tokens(s, norm) for s in g.get("dev_signals", []))
    if prod:
        return ("block", f"{cmd} PROD write (prod signal present): `{segment}`")
    if dev:
        return ("allow", None)
    if g.get("default_env") == "dev" and verb in g.get("safe_default_verbs", []):
        return ("allow", None)
    return ("block", f"{cmd} write, no proven-dev signal (verb={verb or '∅'}) — treated as prod: `{segment}`")


def classify_segment(segment, policy, _depth=0):
    """('allow', None) or ('block', reason) for one command segment.

    Only gates when a gated CLI is the actual command token. Non-gated commands
    (including script names that merely CONTAIN a gated word, e.g.
    render-visual.sh) pass."""
    segment = (segment or "").strip()
    if not segment or segment.startswith("#") or _depth > 4:
        return ("allow", None)

    tokens, parse_ok = _tokenize(segment)
    if not tokens:
        return ("allow", None)

    ci = _resolve_command(tokens)
    if ci >= len(tokens):
        return ("allow", None)
    cmd = _base(tokens[ci])
    rest = tokens[ci + 1:]

    # Shell -c "<cmd>": recurse into the string arg (so `bash -c "gh pr list"`
    # is a read, `bash -c "render deploy --prod"` is a write).
    if cmd in SHELL_C:
        inner = None
        # Match -c AND combined short flags ending in c (-lc, -xc, -ic) — the
        # command string is the next token.
        for k, t in enumerate(rest):
            if (t == "-c" or re.match(r"^-[a-zA-Z]*c$", t)) and k + 1 < len(rest):
                inner = rest[k + 1]
                break
        if inner is not None:
            return classify_segment(inner, policy, _depth + 1)
        # no -c arg (interactive shell etc.) — nothing to verify
        return ("allow", None)

    # eval runs its joined args as a command — recurse into that content
    # (`eval "render deploy --prod"` is a write; `eval "echo hi"` is not).
    if cmd in EVALISH:
        return classify_segment(" ".join(rest), policy, _depth + 1)

    if cmd not in GATED_SET:
        return ("allow", None)

    return _classify_gated(cmd, rest, parse_ok, policy, segment)


def _substitution_inners(command):
    """Yield the inner text of $(...), <(...), >(...), and `...` substitutions."""
    for m in re.finditer(r"(?:\$\(|<\(|>\()([^()]*)\)|`([^`]*)`", command):
        yield m.group(1) if m.group(1) is not None else m.group(2)


def main():
    if len(sys.argv) < 2:
        print("ALLOW")
        return
    command = sys.argv[1]
    policy_path = sys.argv[2] if len(sys.argv) > 2 else None
    policy = load_policy(policy_path) if policy_path else _fallback_policy()

    # Classify inside command/process substitutions by their CONTENT (a gated
    # read in $(...) is still a read — don't blanket-block).
    for inner in _substitution_inners(command):
        for sub in _split_segments(inner or ""):
            v, r = classify_segment(sub, policy, _depth=1)
            if v == "block":
                print(f"BLOCK\t(in substitution) {r}")
                return

    segments = _split_segments(command)

    # The >50-segment defensive cap applies ONLY when a gated command is actually
    # present — a long heredoc/script with no gated CLI must not be blocked.
    if len(segments) > 50:
        any_gated = any(
            classify_segment(s, policy)[0] == "block" or _base(_tokenize(s)[0][0] if _tokenize(s)[0] else "") in GATED_SET
            for s in segments[:200]
        )
        if any_gated:
            print("BLOCK\tcommand has >50 segments and invokes a gated CLI — too complex to classify safely; gating")
            return

    for seg in segments:
        verdict, reason = classify_segment(seg, policy)
        if verdict == "block":
            print(f"BLOCK\t{reason}")
            return
    print("ALLOW")


if __name__ == "__main__":
    main()
