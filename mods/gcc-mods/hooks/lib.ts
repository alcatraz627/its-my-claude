// Shared ground for the gcc-mods surfaces: the gcc paths, the switches, and the
// small pure helpers. Nothing here takes `$`: the validator follows `$` only
// into functions declared in the module's own file, so everything that touches
// the engine lives in register.tsx.

import type { PluginOptions } from 'claude-code'

import type { Decide, GoalView, GoalsSnap, Idle, Mail, Meter, TaskRow, View } from '../types'

export type El = Record<string, any>

export const HOME = '/Users/alcatraz627'
export const GCC = HOME + '/.claude'
export const VIEWS = GCC + '/scripts/goals/views'
export const DP_REG = GCC + '/assets/decision-pages'
export const DP_URL = 'http://localhost:5106/dp/'

export const initialView: View = { isBandHidden: false }
export const emptyMeter: Meter = { ctx: null, week: null, at: 0 }
export const emptyMail: Mail = { messages: [], at: 0, lastWakeAt: 0, error: null }
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
