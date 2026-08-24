// editor.js — the editing core every text surface gets (#13 layer 0).
//
// Its own file for the same reason match.js is: nothing here touches the DOM
// until a function is CALLED, so bun can require it and test the history
// against a stub element, while the board loads it as a plain <script>. A core
// that can only be tested through a browser is a core nobody tests.

// Every text surface gets these three whatever else it is. Not one editor
// component: the drafts page is a document edited over days and a note is a
// message sent once, and forcing them into one shape is the thing the owner
// ruled against. This is only the part that has no reason to differ.
//
// 1. Undo that survives the element. The board rebuilds a card and the native
//    stack dies with the textarea, so the history lives beside the surface,
//    keyed by id, and a rebuilt element resumes the same stack.
// 2. Coalescing, because a sentence should not take thirty presses to undo.
// 3. insertAtCursor, because every surface with chips or templates needs it
//    and two copies of it drift.
const BUF_CAP = 60, BUF_COALESCE = 600;
const bufHist = new Map();          // id -> { past: [], future: [], timer }

function insertAtCursor(el, text) {
  const a = el.selectionStart ?? el.value.length, b = el.selectionEnd ?? a;
  el.value = el.value.slice(0, a) + text + el.value.slice(b);
  const at = a + text.length;
  el.setSelectionRange(at, at);
  el.dispatchEvent(new Event("input", { bubbles: true }));
  el.focus();
}

// Never rebuild an element that has focus: the caret and the selection live in
// the DOM node, so replacing it eats whatever was half-typed. One guard here
// rather than the same comment in three files.
const hasLiveCaret = (el) => !!el && document.activeElement === el;

const bufBound = new WeakMap();     // el -> { rekey, api }: the one binding a reused element carries

function attachBuffer(el, { id, onChange } = {}) {
  if (!el) return null;
  const wantKey = id || el.id || "buffer";
  // A static element reused across surfaces (the note popover, the card
  // composer) reaches here once per surface it shows. A second listener set
  // would fight the first — each stack's undo dispatches a synthetic input
  // that re-enters the other's record(), and the net movement is zero — so a
  // repeat call re-keys the binding it already has instead of attaching again.
  if (el.dataset.buffered === "1") {
    const bound = bufBound.get(el);
    if (!bound) return null;
    bound.rekey(wantKey, onChange);
    return bound.api;
  }
  el.dataset.buffered = "1";
  let h = bufHist.get(wantKey) ?? { past: [], future: [], timer: null };
  bufHist.set(wantKey, h);
  if (!h.past.length) h.past.push(el.value ?? "");
  let change = onChange;

  const snap = () => {
    const now = el.value ?? "";
    if (h.past[h.past.length - 1] === now) return;
    h.past.push(now);
    if (h.past.length > BUF_CAP) h.past.shift();
    h.future = [];                       // a new edit forks the timeline
  };
  const record = () => { clearTimeout(h.timer); h.timer = setTimeout(snap, BUF_COALESCE); };
  const put = (v) => {
    el.value = v;
    el.dispatchEvent(new Event("input", { bubbles: true }));
    if (change) change(v);
  };
  const undo = () => {
    clearTimeout(h.timer); snap();
    if (h.past.length < 2) return false;
    h.future.push(h.past.pop());
    put(h.past[h.past.length - 1]);
    return true;
  };
  const redo = () => {
    if (!h.future.length) return false;
    const v = h.future.pop();
    h.past.push(v);
    put(v);
    return true;
  };
  el.addEventListener("input", record);
  el.addEventListener("keydown", (e) => {
    if (!(e.metaKey || e.ctrlKey)) return;
    const k = e.key.toLowerCase();
    if (k === "z" && !e.shiftKey) { if (undo()) { e.preventDefault(); e.stopPropagation(); } }
    else if ((k === "z" && e.shiftKey) || k === "y") { if (redo()) { e.preventDefault(); e.stopPropagation(); } }
  });
  const api = { undo, redo, snap, depth: () => h.past.length, id: wantKey,
                insert: (t) => insertAtCursor(el, t) };
  const rekey = (nextKey, nextChange) => {
    clearTimeout(h.timer);               // a pending snapshot belongs to the surface we are leaving
    h = bufHist.get(nextKey) ?? { past: [], future: [], timer: null };
    bufHist.set(nextKey, h);
    if (!h.past.length) h.past.push(el.value ?? "");
    change = nextChange;
    api.id = nextKey;
  };
  bufBound.set(el, { rekey, api });
  return api;
}


// classic script in the browser, CommonJS under bun
if (typeof module !== "undefined" && module.exports)
  module.exports = { attachBuffer, insertAtCursor, hasLiveCaret, BUF_CAP, BUF_COALESCE };
