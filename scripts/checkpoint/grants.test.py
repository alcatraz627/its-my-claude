"""Checks how a checkpoint decides that an approval is really the owner's: short approvals, carried approvals, and who counts as the owner.

Run: python3 ~/.claude/scripts/checkpoint/grants.test.py
"""
import importlib.util
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import ckutil as ck  # noqa: E402

spec = importlib.util.spec_from_file_location("finalize", os.path.join(HERE, "finalize.py"))
fin = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(fin)
except SystemExit:
    pass

passed = failed = 0


def check(name, got, want):
    global passed, failed
    if got == want:
        passed += 1
        print(f"  PASS {name}")
    else:
        failed += 1
        print(f"  FAIL {name}: got {got!r}, want {want!r}")


def said(words, *messages):
    return ck.judge_quote(words, [ck.norm(m) for m in messages])[0]


print("== a short approval counts when it is the owner's whole message and names the action ==")
check("'commit' as the whole message verifies", said("commit", "commit"), True)
check("'commit and push' as the whole message verifies", said("commit and push", "Commit and push."), True)
check("'yes push' as the whole message verifies", said("yes push", "yes push"), True)
check("'yes' alone still does not", said("yes", "yes"), False)
check("'go ahead' names no action, so it does not", said("go ahead", "go ahead"), False)
check("'push' lifted out of a longer message does not", said("push", "do not push this to main yet"), False)
check("'commit' lifted out of a longer message does not", said("commit", "I will commit this myself later tonight"), False)
check("a short quote nobody said does not", said("deploy it", "commit"), False)
check("four words in one message still verify as before", said("go ahead and push", "ok go ahead and push for PR 12"), True)

print("== who counts as the owner ==")


def entry(text, **extra):
    return {"type": "user", "message": {"content": text}, **extra}


check("a typed message is the owner's", ck.owner_words(entry("push it", turnOrigin="human", origin={"kind": "human"})), "push it")
check("a record with no origin mark is still read (older transcripts)", ck.owner_words(entry("push it")), "push it")
check("a headless prompt is not the owner's", ck.owner_words(entry("push it", turnOrigin="sdk")), None)
check("a peer session's message is not the owner's", ck.owner_words(entry("push it", turnOrigin="peer")), None)
check("a timer's message is not the owner's", ck.owner_words(entry("push it", turnOrigin="scheduled")), None)
check("a background job's notice is not the owner's", ck.owner_words(entry("push it", turnOrigin="task_notification")), None)

print("== a carried approval is matched on the owner's words and the target, not on the commit it pointed at ==")
a = '"commit and push the docs branch" (2026-11-20 10:00) · target: repo/docs @abc1234 · standing'
b = '"commit and push the docs branch" (2026-11-20 10:00) · target: repo/docs @def5678 · standing'
c = '"commit and push the docs branch" (2026-11-20 10:00) · target: repo/main @abc1234 · standing'
key = getattr(fin, "grant_key", None)
check("the helper exists", callable(key), True)
if callable(key):
    check("same words, same target, new commit: same approval", key(a) == key(b), True)
    check("same words, different target: a different approval", key(a) == key(c), False)

print(f"---\n{passed}/{passed + failed} passed")
sys.exit(1 if failed else 0)
