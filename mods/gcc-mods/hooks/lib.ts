// Shared ground for every gcc-mods surface: the state atoms, the gcc paths,
// and the small pure helpers each tab repeats. Nothing here takes `$`: the
// validator follows `$` only into functions declared in the module's own
// file, so everything that touches the engine lives in register.tsx.

import type { PluginOptions } from 'claude-code'

import type { Decide, DecideSet, Doc, Fun, GoalView, GoalsSnap, Idle, Mail, Meter, Receipt, TaskRow, View } from '../types'

export type El = Record<string, any>

export const PLUGIN = 'gcc-mods'
export const PANE = 'gcc'
export const HOME = '/Users/alcatraz627'
export const GCC = HOME + '/.claude'
export const GS = GCC + '/scripts/goals/gs'
export const VIEWS = GCC + '/scripts/goals/views'
export const GOAL_SH = GCC + '/scripts/goal/goal.sh'
export const DP_REG = GCC + '/assets/decision-pages'

export const initialView: View = {
  tab: 'tasks',
  docFilter: 'session',
  docSel: null,
  docFull: false,
  hidden: [],
  goalSel: 0,
  showDone: false,
  showOthers: false,
  rejecting: null,
  nudgeSel: null,
  nudgeMode: 'text',
  snoozeFor: '4h',
  seatSel: null,
  msgSel: null,
  isReplying: false,
  isBandHidden: false,
  decideSlug: null,
  decideSel: null,
  dismissed: [],
  goalEditing: false,
}

export const emptyMeter: Meter = { ctx: null, fiveHour: null, week: null, costUsd: null, at: 0 }
export const emptyMail: Mail = { messages: [], at: 0, lastWakeAt: 0, error: null }
export const emptyReceipt: Receipt = { turnStartedAt: 0, lastRun: null, lastShot: null, lastCurl: null, claim: null }
export const emptyIdle: Idle = { since: null, openRows: 0, continueOfferedAt: null }
export const emptyDecide: Decide = { pending: [], picks: {}, notes: {}, at: 0, submitted: [], answered: [] }
export const emptyFun: Fun = { greetedAt: null, metGoals: [], lastLanding: '' }

// The switches from plugin.json's userConfig, read once at register time.
export type Switches = {
  hygiene: boolean
  continuity: boolean
  tasks: boolean
  tasksWrite: boolean
  fleet: boolean
  wake: boolean
  mailWake: boolean
  router: boolean
  nudges: boolean
  decide: boolean
  receipt: boolean
  fun: boolean
  sound: boolean
}
export function switchesOf(options: PluginOptions): Switches {
  const on = (k: keyof Switches, dflt = true) => (typeof options[k] === 'boolean' ? (options[k] as boolean) : dflt)
  return {
    hygiene: on('hygiene'),
    continuity: on('continuity'),
    tasks: on('tasks'),
    tasksWrite: on('tasksWrite'),
    fleet: on('fleet'),
    wake: on('wake'),
    mailWake: on('mailWake', false),
    router: on('router'),
    nudges: on('nudges'),
    decide: on('decide'),
    receipt: on('receipt'),
    fun: on('fun'),
    sound: on('sound', false),
  }
}

export function ago(now: number, at: number): string {
  const m = Math.floor((now - at) / 60_000)
  if (m < 1) return 'now'
  if (m < 60) return m + 'm'
  if (m < 48 * 60) return Math.floor(m / 60) + 'h'
  return Math.floor(m / 1440) + 'd'
}

// How long ago, as a phrase that stands alone: "just now", "5m ago".
export const agoPhrase = (now: number, at: number) => (ago(now, at) === 'now' ? 'just now' : ago(now, at) + ' ago')

export function dur(ms: number): string {
  const s = Math.max(0, Math.floor(ms / 1000))
  if (s < 60) return s + 's'
  return Math.floor(s / 60) + 'm' + String(s % 60).padStart(2, '0') + 's'
}

export const abs = (p: string) => (p.startsWith('~') ? HOME + p.slice(1) : p)
export const tilde = (p: string) => (p.startsWith(HOME) ? '~' + p.slice(HOME.length) : p)
export const head = (text: string, n: number) => text.split('\n').slice(0, n).join('\n')
export const clip = (text: string, n: number) => (text.length > n ? text.slice(0, n - 1) + '…' : text)
export const firstLine = (text: string) => text.split('\n').find(l => l.trim())?.trim() ?? ''

// Optional-true props (hotkey, autoFocus) are refused as false or undefined,
// so they are spread in only when they apply.
export const hk = (key: string, when = true) => (when ? { hotkey: key } : {})

export function jsonOr<T>(text: string | null | undefined, fallback: T): T {
  if (!text) return fallback
  try {
    return JSON.parse(text) as T
  } catch {
    return fallback
  }
}

export function parseJsonl(text: string): Record<string, any>[] {
  const rows: Record<string, any>[] = []
  for (const line of text.split('\n')) {
    const t = line.trim()
    if (!t) continue
    try {
      rows.push(JSON.parse(t))
    } catch {
      /* skip */
    }
  }
  return rows
}

export const sid8 = (sid: string) => sid.slice(0, 8)

export function plural(n: number, one: string, many = one + 's') {
  return n + ' ' + (n === 1 ? one : many)
}

// Goal record derivations the band, the status line and the Tasks tab share.
export const isGate = (a: GoalView['accept'][number]) => a.status !== 'proven' && a.kind !== 'functional' && a.kind !== 'deployed'
export const openGates = (g: GoalView) => g.accept.filter(isGate)
export const rowIsReady = (t: TaskRow) => !t.gate && t.blockedBy.length === 0 && /^(todo|ready|active|doing|open)$/.test(t.state)
export const readyRows = (g: GoalView) => g.tasks.filter(rowIsReady)
export const gatedRows = (g: GoalView) => g.tasks.filter(t => t.gate && !/^(done|dropped)$/.test(t.state))

export function goalCounts(snap: GoalsSnap | null) {
  const goals = snap?.goals ?? []
  return {
    gates: goals.reduce((n, g) => n + openGates(g).length + gatedRows(g).length, 0),
    ready: goals.reduce((n, g) => n + readyRows(g).length, 0),
    goals: goals.length,
  }
}

export function docKindOf(path: string): Doc['kind'] {
  if (/\/_.*\.claude\.md$/.test(path) || /\/checkpoints\//.test(path)) return 'checkpoint'
  if (/\/session-notes\//.test(path)) return 'notes'
  if (/\/assets\/reports\//.test(path)) return /review/i.test(path) ? 'review' : 'report'
  if (/plan/i.test(path)) return 'plan'
  if (/\.html?$/.test(path)) return 'page'
  return 'doc'
}

// The owner tag a settings hook wraps its owner-facing text in (hook_owner_wrap
// in scripts/hooks/hook-common.sh). An optional model="…" is what the model
// reads in the block's place once it has been drawn.
//   <owner surface="toast|log|band|pane:nudges|pane:tasks|ask" hook="<script>" model="…">…</owner>
const BLOCK_RE = /<owner\b([^>]*)>([\s\S]*?)<\/owner>\s*/g
const ATTR_RE = /(\w+)=("([^"]*)"|'([^']*)'|([^\s>]+))/g
export type OwnerBlock = { surface: string; hook: string; text: string; model: string }

export function splitOwnerBlocks(text: string): { rest: string; blocks: OwnerBlock[] } {
  const blocks: OwnerBlock[] = []
  const rest = text.replace(BLOCK_RE, (_m, attrs: string, body: string) => {
    const a: Record<string, string> = {}
    for (const m of attrs.matchAll(ATTR_RE)) a[m[1]!] = m[3] ?? m[4] ?? m[5] ?? ''
    blocks.push({ surface: (a.surface ?? 'toast').toLowerCase(), hook: a.hook ?? 'hook', text: body.trim(), model: (a.model ?? '').trim() })
    return a.model ? a.model.trim() + '\n' : ''
  })
  return { rest: rest.trim(), blocks }
}

// The decision page's answer string: "<id><code>" tokens on one line, then one
// "<id> note — <text>" line per note, the format the web page copies out.
export function answerString(set: DecideSet, picks: Record<string, string>, notes: Record<string, string>): string {
  const toks = set.items.map(it => it.id + (picks[set.slug + '/' + it.id] ?? it.options.find(o => o.rec)?.code ?? 'a'))
  const lines = [toks.join(' ')]
  for (const it of set.items) {
    const n = (notes[set.slug + '/' + it.id] ?? '').trim()
    if (n) lines.push(it.id + ' note — ' + n)
  }
  return lines.join('\n')
}

// The same vocabulary declared-ready-stop.sh keys on, so the receipt and the
// gate agree about what a done-claim is.
export const SUCCESS_RE = /\b(done|works|working|shipped|fixed|passing|passes|verified|complete|completed|good to go|all set|ready to (ship|go|commit))\b/i
export const SUBJECT_RE = /\b(the (fix|feature|change|bug|test|tests|build|code|implementation|patch|hook|script|mod|pane|band)|it|this|everything|all (the )?(tests|of it))\b/i
export const RUN_RE = /(pytest|python3?\s+[^|]*\.py|go\s+test|cargo\s+(test|run)|npm\s+(test|run|start)|pnpm\s+(test|run|dev|start)|yarn\s+(test|dev|start)|node\s+[^|]+|swift\s+(test|run)|xcodebuild\s+test|make\s+(test|run|check)|\.\/[A-Za-z0-9._/-]+|bash\s+[^|]*\.sh|jest|vitest|playwright\s+test|claude\s+plugin\s+(test|validate)|tsc\b)/
export const CURL_RE = /curl\s+[^|]*(localhost|127\.0\.0\.1|:\d{4})/

export function receiptLine(r: Receipt, now: number): string {
  const run = r.lastRun ? r.lastRun.cmd + ' ' + (r.lastRun.ok ? 'ok' : 'FAILED') + ' ' + ago(now, r.lastRun.at) + ' ago' : 'nothing run'
  const shot = r.lastShot ? 'read ' + (r.lastShot.path.split('/').pop() ?? 'image') + ' ' + ago(now, r.lastShot.at) + ' ago' : 'none'
  const curl = r.lastCurl ? r.lastCurl.url + ' ' + ago(now, r.lastCurl.at) + ' ago' : 'none'
  return 'run: ' + run + ' · screenshot: ' + shot + ' · curl: ' + curl
}

// The pane's markdown renderer wraps wide tables into rubble, so a table is
// drawn as an aligned monospace block instead, cut to the pane's width.
export function tablesToBlocks(text: string, cols: number): string {
  const lines = text.split('\n')
  const out: string[] = []
  let i = 0
  while (i < lines.length) {
    if (!/^\s*\|.*\|\s*$/.test(lines[i] ?? '')) {
      out.push(lines[i]!)
      i += 1
      continue
    }
    const rows: string[][] = []
    while (i < lines.length && /^\s*\|.*\|\s*$/.test(lines[i] ?? '')) {
      const cells = lines[i]!.trim().slice(1, -1).split('|').map(c => c.trim())
      if (!cells.every(c => /^:?-{2,}:?$/.test(c))) rows.push(cells)
      i += 1
    }
    const n = Math.max(...rows.map(r => r.length))
    const room = Math.max(8, Math.floor((cols - 2 - 3 * (n - 1)) / n))
    const widths = Array.from({ length: n }, (_, c) => Math.min(room, Math.max(...rows.map(r => (r[c] ?? '').length))))
    const fit = (s: string, w: number) => (s.length > w ? s.slice(0, w - 1) + '…' : s).padEnd(w)
    out.push('```text')
    rows.forEach((r, ri) => {
      out.push(widths.map((w, c) => fit(r[c] ?? '', w)).join(' │ '))
      if (ri === 0) out.push(widths.map(w => '─'.repeat(w)).join('─┼─'))
    })
    out.push('```')
  }
  return out.join('\n')
}

// A path-looking token: home-relative, absolute under the usual roots, or a
// gcc-shaped relative path. The boundary before it keeps URLs out.
export const PATH_RE =
  /(^|[\s(\[{'"<])((?:~|\.\.?)?\/(?:[\w.@+%-]+\/)*[\w.@+%-]+|(?:scripts|skills|assets|features|rules|conventions|docs|src|hooks|adapters|lib|tests?|config|i-dream|atone|goals|checkpoints|kanban|personas|shared|widgets|logs|rules-provenance|session-notes)\/(?:[\w.@+%-]+\/)*[\w.@+%-]+)/g
export const TRAIL_RE = /[.,;:)\]'"]+$/

export const WORDS = {
  seats: ['Herding seats', 'Conducting', 'Running the fleet', 'Delegating'],
  squeeze: ['Squeezing', 'Tidying the window', 'Breathing out', 'Compacting thoughts'],
  mail: ['Pondering mail', 'Reading the post'],
  night: ['Night-shifting', 'Moonlighting', 'Owling'],
  dawn: ['Brewing', 'Warming up', 'Stretching'],
  plain: ['Mulling', 'Tinkering', 'Noodling', 'Chewing on it', 'Puttering', 'Rummaging', 'Fiddling', 'Cooking'],
}
export const LANDING = ['landed', 'touched down', 'is back with the goods', 'reports in', 'has returned', 'came home']

// A glyph for the hour, for the status line's left edge.
export function hourGlyph(hour: number) {
  if (hour < 5) return '🌙'
  if (hour < 9) return '🌅'
  if (hour < 17) return '☀'
  if (hour < 21) return '🌇'
  return '🌙'
}

export function greetingFor(hour: number) {
  if (hour < 5) return 'Still up'
  if (hour < 12) return 'Good morning'
  if (hour < 17) return 'Good afternoon'
  if (hour < 22) return 'Good evening'
  return 'Late one'
}
