#!/usr/bin/env bash
# Checks guard-env-capture-test: test code that stores and shows the whole
# environment is refused; passing an environment on or reading keys is not.
set -u
G="${GUARD:-$(dirname "$0")/guard-env-capture-test.sh}"
D=$(mktemp -d)
trap 'rm -rf "$D"' EXIT
mkdir -p "$D/probe/fixtures" "$D/src" "$D/tests"
pass=0; fail=0

verdict() { # want label json
  local out got
  out=$(printf '%s' "$3" | bash "$G")
  if printf '%s' "$out" | grep -q '"deny"'; then got=deny; else got=allow; fi
  if [[ $got == "$1" ]]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL want $1 got $got: $2"; fi
}
write() { # want label path content
  verdict "$1" "$2" "$(jq -cn --arg p "$3" --arg c "$4" '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}')"
}
edit() { # want label path old new
  verdict "$1" "$2" "$(jq -cn --arg p "$3" --arg o "$4" --arg n "$5" '{tool_name:"Edit",tool_input:{file_path:$p,old_string:$o,new_string:$n}}')"
}

# The 22 Oct local-models fixture, rebuilt from the commit before it was fixed
# (git 2c3d77d, probe/fixtures/verbs-drift.py:339): the stub keeps all of **kw,
# which carries env=, and a failing check prints str(calls).
LEAKY='calls = []
V.subprocess.run = lambda argv, **kw: (calls.append((argv, kw)) or Done())
check("hint is never run", not calls, str(calls)[:160])
'
write deny "kw stored whole and stringified (22 Oct fixture)" "$D/probe/fixtures/verbs-drift.py" "$LEAKY"

write deny "os.environ.copy asserted whole" "$D/tests/test_x.py" 'import os
env = os.environ.copy()
assert env == {"A": "1"}
'
write deny "dict(os.environ, ...) printed" "$D/tests/test_x.py" 'env = dict(os.environ, NO_COLOR="1")
print(env)
'
write deny "dict(os.environ) in an f-string" "$D/tests/test_x.py" 'e = dict(os.environ)
fail(f"bad run with {e}")
'
write deny "process.env spread logged" "$D/src/app.test.ts" 'const env = { ...process.env, A: "1" };
console.log(env);
'
write deny "os.environ printed directly" "$D/tests/test_x.py" 'print(os.environ)
'
printf 'import os\nenv = os.environ.copy()\nrun(cmd, env=env)\nVALUE = 1\n' >"$D/tests/test_y.py"
edit deny "edit adds the print to an existing capture" "$D/tests/test_y.py" 'VALUE = 1' 'assert env == {}'

# Legitimate uses.
FIXED='calls = []
V.subprocess.run = lambda argv, **kw: (calls.append((argv, {"shell": kw.get("shell")})) or Done())
check("hint is never run", not calls, str(calls)[:160])
'
write allow "stub keeps only argv and the shell flag (the fix)" "$D/probe/fixtures/verbs-drift.py" "$FIXED"
write allow "env copy only passed on" "$D/tests/test_x.py" 'env = dict(os.environ, NO_COLOR="1", LM_HINTS="0")
rc = run(cmd, env=env)
assert rc == 0
'
write allow "single keys read from the copy" "$D/tests/test_x.py" 'env = os.environ.copy()
env["A"] = "1"
assert env["A"] == "1"
assert env.get("B") is None
'
write allow "stub stores kw but nothing shows it" "$D/tests/test_x.py" 'calls = []
stub = lambda argv, **kw: calls.append((argv, kw))
assert len(calls) == 1
'
write allow "same capture in a non-test source file" "$D/src/runner.py" 'env = os.environ.copy()
print(env)
'
write allow "a markdown file in a test directory" "$D/tests/notes.md" 'env = os.environ.copy()
print(env)
'
verdict allow "other tool" "$(jq -cn '{tool_name:"Bash",tool_input:{command:"env"}}')"

echo "$pass passed, $fail failed"
[[ $fail == 0 ]]
