// Shared ground for the gcc-mods surfaces: the gcc paths, the switches, and the
// small pure helpers. Nothing here takes `$`: the validator follows `$` only
// into functions declared in the module's own file, so everything that touches
// the engine lives in register.tsx.

import type { PluginOptions } from 'claude-code'

import type { Decide, DeliveryState, GoalView, GoalsSnap, Idle, Images, Mail, McpRow, Meter, Msg, PlugFire, Side, SideTask, TaskRow, View } from '../types'

export type El = Record<string, any>

export const HOME = '/Users/alcatraz627'
export const GCC = HOME + '/.claude'
export const VIEWS = GCC + '/scripts/goals/views'
export const DP_REG = GCC + '/assets/decision-pages'
export const DP_URL = 'http://localhost:5106/dp/'
export const DOC_URL = 'http://localhost:5106/doc?path='
export const CLAUDE_BIN = HOME + '/.local/bin/claude'
export const SIDE_ID = 'gcc-side'
export const IMAGE_ID = 'gcc-image'

export const initialView: View = { isBandHidden: false, preset: 'S1' }
export const emptyMeter: Meter = { ctx: null, week: null, at: 0 }
export const emptyMail: Mail = { messages: [], at: 0, lastWakeAt: 0, enabledAt: 0, error: null }
export const emptySide: Side = {
  isOpen: false,
  tasks: { store: null, rows: [], at: 0, triedAt: 0, error: null },
  mcp: { rows: [], at: 0, error: null },
  plugins: { enabled: [], disabled: 0, at: 0 },
  fires: { rows: [], at: 0, error: null },
}
export const emptyImages: Images = { nums: [], sid: '', dir: null, files: {}, dismissed: '' }
export const emptyIdle: Idle = { since: null, openRows: 0, continueOfferedAt: null }
export const emptyDecide: Decide = { pending: [], answered: [], at: 0 }

// The switches from plugin.json's userConfig, read once at register time.
export type Switches = {
  startOn: boolean
  hygiene: boolean
  continuity: boolean
  tasks: boolean
  fleet: boolean
  wake: boolean
  mailWake: boolean
}
export function switchesOf(options: PluginOptions): Switches {
  const on = (k: keyof Switches, dflt = true) => (typeof options[k] === 'boolean' ? (options[k] as boolean) : dflt)
  return {
    startOn: on('startOn', false),
    hygiene: on('hygiene'),
    continuity: on('continuity'),
    tasks: on('tasks'),
    fleet: on('fleet'),
    wake: on('wake'),
    mailWake: on('mailWake', false),
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
export const clip = (text: string, n: number) => (text.length > n ? text.slice(0, n - 1) + '…' : text)
export const firstLine = (text: string) => text.split('\n').find(l => l.trim())?.trim() ?? ''

export function jsonOr<T>(text: string | null | undefined, fallback: T): T {
  if (!text) return fallback
  try {
    return JSON.parse(text) as T
  } catch {
    return fallback
  }
}

export const sid8 = (sid: string) => sid.slice(0, 8)

export function plural(n: number, one: string, many = one + 's') {
  return n + ' ' + (n === 1 ? one : many)
}

// Goal record derivations the band and the status line share.
export const isGate = (a: GoalView['accept'][number]) => a.status !== 'proven' && a.kind !== 'functional' && a.kind !== 'deployed'
export const rowIsReady = (t: TaskRow) => !t.gate && t.blockedBy.length === 0 && /^(todo|ready|active|doing|open)$/.test(t.state)
const gatedRows = (g: GoalView) => g.tasks.filter(t => t.gate && !/^(done|dropped)$/.test(t.state))

export function goalCounts(snap: GoalsSnap | null) {
  const goals = snap?.goals ?? []
  return {
    gates: goals.reduce((n, g) => n + g.accept.filter(isGate).length + gatedRows(g).length, 0),
    ready: goals.reduce((n, g) => n + g.tasks.filter(rowIsReady).length, 0),
  }
}

// A path-looking token: home-relative, absolute under the usual roots, or a
// gcc-shaped relative path. The boundary before it keeps URLs out.
export const PATH_RE =
  /(^|[\s(\[{'"<])((?:~|\.\.?)?\/(?:[\w.@+%-]+\/)*[\w.@+%-]+|(?:scripts|skills|assets|features|rules|conventions|docs|src|hooks|adapters|lib|tests?|config|i-dream|atone|goals|checkpoints|kanban|personas|shared|widgets|logs|rules-provenance|session-notes)\/(?:[\w.@+%-]+\/)*[\w.@+%-]+)/g
export const TRAIL_RE = /[.,;:)\]'"]+$/

// Mail: only what the broker has not yet put in front of the agent is news.
export function deliveryStateOf(raw: unknown): DeliveryState | null {
  return raw === 'queued' || raw === 'delivered' || raw === 'surfaced' ? raw : null
}

// A queued or delivered message is new. A surfaced one was already shown to the
// agent by the ipc hook. With no state (an older broker), only a message that
// arrived after the mod switched on counts, so old mail never wakes a session.
export function isNewMail(m: Msg, enabledAt: number): boolean {
  if (m.isRead) return false
  if (m.deliveryState) return m.deliveryState !== 'surfaced'
  return m.at >= enabledAt
}

// Where a path opens: notes in the doc viewer (a browser tab), the rest as files.
export const isDocPath = (full: string) => /\.(md|markdown|txt)$/i.test(full)
export const linkFor = (full: string) => (isDocPath(full) ? DOC_URL + encodeURIComponent(full) : 'file://' + encodeURI(full))

// The images a draft names, in order and without repeats.
export function imageNumsOf(draft: string): number[] {
  const found: number[] = []
  for (const m of draft.matchAll(/\[Image #(\d+)\]/g)) {
    const n = Number(m[1])
    if (!found.includes(n)) found.push(n)
  }
  return found.sort((a, b) => a - b)
}

// 1234 -> 1.2K, 1500000 -> 1.5M.
export function human(n: number): string {
  if (n < 1000) return String(n)
  if (n < 1_000_000) return (n / 1000).toFixed(n < 10_000 ? 1 : 0).replace(/\.0$/, '') + 'K'
  return (n / 1_000_000).toFixed(1).replace(/\.0$/, '') + 'M'
}

// Side pane sources.

// `claude mcp list` prints "name: command args - state". Only the name and the
// state are kept: the command part can carry a connection string.
export function parseMcpList(text: string): McpRow[] {
  const rows: McpRow[] = []
  for (const line of text.split('\n')) {
    const i = line.indexOf(': ')
    const j = line.lastIndexOf(' - ')
    if (i < 1 || j < i) continue
    const state = line.slice(j + 3)
    if (!/connected|failed|authentication|needs/i.test(state)) continue
    rows.push({ name: line.slice(0, i), state: /connected/i.test(state) ? 'ok' : /auth/i.test(state) ? 'auth' : 'failed' })
  }
  return rows
}

// plugin:chrome-devtools-mcp:chrome-devtools -> chrome-devtools
export const shortName = (name: string) => name.replace(/@[\w.-]+$/, '').split(':').pop() || name

// What the hooks injected into this session, from the plug-events ledger lines.
export function summarizeFires(text: string, sid: string): PlugFire[] {
  const by = new Map<string, PlugFire>()
  for (const line of text.split('\n')) {
    if (!line.includes(sid)) continue
    const j = jsonOr<{ plug?: string; session_id?: string; chars?: number }>(line, {})
    if (j.session_id !== sid || !j.plug) continue
    const row = by.get(j.plug) ?? { plug: j.plug, fired: 0, chars: 0 }
    row.fired += 1
    row.chars += typeof j.chars === 'number' ? j.chars : 0
    by.set(j.plug, row)
  }
  return [...by.values()].sort((a, b) => b.chars - a.chars || b.fired - a.fired)
}

export const MAX_ROWS = 12

// The task rows the pane draws: running first, then blocked, then waiting, at
// most MAX_ROWS of them; finished ones are only a count.
export function taskView(rows: SideTask[]) {
  const live = rows.filter(t => t.status !== 'completed' && t.status !== 'deleted')
  const openIds = new Set(live.map(t => t.id))
  const isBlocked = (t: SideTask) => t.blockedBy.some(id => openIds.has(id))
  const rank = (t: SideTask) => (t.status === 'in_progress' ? 0 : isBlocked(t) ? 1 : 2)
  const ordered = [...live].sort((a, b) => rank(a) - rank(b) || Number(a.id) - Number(b.id))
  return {
    done: rows.filter(t => t.status === 'completed').length,
    open: live.length,
    shown: ordered.slice(0, MAX_ROWS).map(t => ({ ...t, blocked: isBlocked(t) })),
    more: Math.max(0, ordered.length - MAX_ROWS),
  }
}
