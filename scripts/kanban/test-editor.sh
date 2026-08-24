#!/bin/bash
# The editing core (#13 layer 0), proven outside any page. editor.js touches no
# DOM until a function is called, so the history can be exercised against a
# stub element — which is the only way this is testable at all, and the reason
# it is its own file rather than a section of shared.js.
HERE="$(cd "$(dirname "$0")" && pwd)"
pass=0; fail=0
ok()  { printf '  PASS  %s\n' "$1"; pass=$((pass+1)); }
bad() { printf '  FAIL  %s\n     %s\n' "$1" "${2:-}"; fail=$((fail+1)); }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]"; fi; }

out=$(bun -e '
const { attachBuffer, insertAtCursor } = require("'"$HERE"'/editor.js");
// the smallest thing that behaves like a textarea for this purpose
const mk = (id) => ({ id, value: "", dataset: {}, selectionStart: 0, selectionEnd: 0,
  _on: {}, addEventListener(k, f) { (this._on[k] ??= []).push(f); },
  dispatchEvent(e) { (this._on[e.type] ?? []).forEach((f) => f(e)); return true; },
  setSelectionRange(a, b) { this.selectionStart = a; this.selectionEnd = b; },
  focus() {} });
const key = (k, mods = {}) => ({ type: "keydown", key: k, preventDefault(){}, stopPropagation(){}, ...mods });
const typeIn = (el, v) => { el.value = v; el.dispatchEvent({ type: "input" }); };

const el = mk("t1");
const b = attachBuffer(el, { id: "t1" });
// COALESCING, exercised rather than bypassed. Three edits inside the window
// must leave ONE snapshot, not three: calling snap() by hand after each edit
// (which this test used to do) makes the timer irrelevant and the row cannot
// fail. Verified by mutation: drop the timer and burst below goes to 3.
typeIn(el, "a"); typeIn(el, "ab"); typeIn(el, "abc");
await new Promise((r) => setTimeout(r, 900));
const burst = b.depth() - 1;          // minus the empty start
b.snap();
typeIn(el, "one"); b.snap();
typeIn(el, "one two"); b.snap();
typeIn(el, "one two three"); b.snap();
const d0 = b.depth() - 2;             // ignore the coalescing pair above
b.undo(); const u1 = el.value;
b.undo(); const u2 = el.value;
b.redo(); const r1 = el.value;

// a fresh element with the SAME key resumes the same stack, which is the whole
// point: the board rebuilds and the native stack dies with the node
const el2 = mk("t1");
el2.value = u2;
const b2 = attachBuffer(el2, { id: "t1" });
b2.undo(); const survived = el2.value;

// a different key is a different history, so two cards do not share one
const el3 = mk("t2");
const b3 = attachBuffer(el3, { id: "t2" });
const freshDepth = b3.depth();

// insert at cursor puts text where the caret is, not at the end
const el4 = mk("t4"); el4.value = "hello world";
el4.selectionStart = el4.selectionEnd = 5;
insertAtCursor(el4, " there");

// attaching twice must not double-bind: same element, same key -> ONE listener
// set survives, because two sets undo against each other and cancel (H2)
const listenersBefore = el._on.input.length;
attachBuffer(el, { id: "t1" });
const singleBind = String(el._on.input.length === listenersBefore);

// a static element shown for a NEW surface re-keys the one binding: the same
// listeners now drive the new surface own stack, not the old card
el.value = "B text";
const rk = attachBuffer(el, { id: "t9" });
typeIn(el, "B text more"); rk.snap();
rk.undo(); const rkUndo = el.value;

process.stdout.write([burst, d0, u1, u2, r1, survived, freshDepth, el4.value, singleBind, rkUndo].join("|"));
' 2>&1)

IFS="|" read -r burst depth u1 u2 r1 survived freshDepth inserted singleBind rkUndo <<< "$out"
check "three keystrokes inside the window leave ONE snapshot"  "$burst"     "1"
check "three explicit snapshots each land"                    "$depth"     "3"
check "undo walks back one snapshot, not one keystroke"       "$u1"        "one two"
check "and again"                                             "$u2"        "one"
check "redo goes forward"                                     "$r1"        "one two"
# undo snapshots what is on screen BEFORE stepping back, so nothing half-typed
# is lost by pressing it; the fresh node therefore lands on the previous
# snapshot of the SHARED stack rather than on whatever it was seeded with.
check "a fresh element with the same key resumes the shared stack"   "$survived"  "one two"
check "a different key is a different, empty history"         "$freshDepth" "1"
check "insert lands at the caret, not at the end"             "$inserted"  "hello there world"
check "re-attach with the same key adds no second listener"   "$singleBind" "true"
check "re-attach with a new key drives the new surface stack" "$rkUndo"    "B text"

printf '  ---- %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
