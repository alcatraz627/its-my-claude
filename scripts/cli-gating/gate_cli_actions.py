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

GATED = ("render", "vercel", "gh")
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
             "default_env": "prod"},
            {"cli": "vercel", "read_verbs": ["ls", "list", "inspect", "logs", "whoami", "help"],
             "prod_signals": ["--prod"], "dev_signals": ["--target preview"],
             "default_env": "dev", "safe_default_verbs": ["deploy"]},
            {"cli": "gh", "read_verbs": ["auth", "browse", "status", "repo view", "repo list", "pr view", "pr list", "pr diff", "pr checks", "issue view", "issue list", "run view", "run list", "release view", "release list", "search", "label list", "help"],
             "always_gate_verbs": ["repo delete", "release delete", "secret set", "secret delete"],
             "main_branch_gate_verbs": ["pr merge", "push", "release create", "release edit"],
             "main_branches": ["main", "master"]},
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

    # If we could not parse the segment AND the verb isn't a known read, we don't
    # have enough to confidently call it a write of a specific shape — but an
    # unknown gated verb is exactly the conservative-gate case. However, to avoid
    # the read-with-weird-args false positive, require the FIRST token to look
    # like a subcommand (not a flag) before gating an unparseable segment.
    if not parse_ok and (not verb or verb.startswith("-")):
        return ("allow", None)  # can't identify a write verb; don't over-block

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
        for sub in SEGMENT_SPLIT.split(inner or ""):
            v, r = classify_segment(sub, policy, _depth=1)
            if v == "block":
                print(f"BLOCK\t(in substitution) {r}")
                return

    segments = SEGMENT_SPLIT.split(command)

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
