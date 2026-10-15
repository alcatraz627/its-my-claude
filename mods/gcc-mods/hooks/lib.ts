// Shared ground for the gcc-mods surfaces: the gcc paths, the switches, and the
// small pure helpers. Nothing here takes `$`: the validator follows `$` only
// into functions declared in the module's own file, so everything that touches
// the engine lives in register.tsx.

import type { PluginOptions } from 'claude-code'

import type { Decide, DeliveryState, GoalView, GoalsSnap, Idle, Images, Mail, McpRow, Meter, Msg, PlugFire, PluginRow, Side, SideCost, SideTab, SideTask, TaskRow, View } from '../types'

export type El = Record<string, any>

export const HOME = '/Users/alcatraz627'
export const GCC = HOME + '/.claude'
export const VIEWS = GCC + '/scripts/goals/views'
export const DP_REG = GCC + '/assets/decision-pages'
export const DP_URL = 'http://localhost:5106/dp/'
export const CLAUDE_BIN = HOME + '/.local/bin/claude'
export const SIDE_ID = 'gcc-side'
export const IMAGE_ID = 'gcc-image'

export const initialView: View = { isBandHidden: false, preset: 'S1' }
export const emptyMeter: Meter = { ctx: null, week: null, at: 0 }
export const emptyMail: Mail = { messages: [], at: 0, lastWakeAt: 0, enabledAt: 0, error: null }
export const emptySide: Side = {
  isOpen: false,
  tab: 'overview',
  tasks: { store: null, rows: [], at: 0, triedAt: 0, error: null },
  mcp: { rows: [], at: 0, error: null },
  plugins: { rows: [], at: 0 },
  fires: { rows: [], at: 0, error: null },
  cost: { servers: {}, skills: {}, at: 0, ok: false },
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

// Every path opens natively as a file, notes included; the OS default handler decides.
export const linkFor = (full: string) => 'file://' + encodeURI(full)

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

export const SIDE_TABS: SideTab[] = ['overview', 'tasks', 'mcp', 'plugins', 'injections']
export const isSideTab = (word: string): word is SideTab => (SIDE_TABS as string[]).includes(word)

// Hard-cut a row at the pane width. No ellipsis: a row is one item, and it
// simply ends where the pane does.
export const cut = (text: string, n: number) => (text.length > n ? text.slice(0, n) : text)

// Anything that looks like a credential. Used on every command, URL and
// argument the side pane draws, because the MCP lines come from places that can
// hold connection strings and keys.
const SECRET_WORD = /(token|secret|passw|apikey|api[-_]?key|auth|bearer|credential|private[-_]?key|\bkey\b)/i
const SECRET_SHAPE = /^(?:sk|pk|rk|ghp|gho|ghs|ghu|github_pat|glpat|xox[a-z]|ya29|AKIA|AIza)[-_A-Za-z0-9.]{8,}$/
const RANDOM_SHAPE = /^[A-Za-z0-9_-]{24,}$/
export const REDACTED = '<hidden>'

export function looksSecret(word: string): boolean {
  if (SECRET_SHAPE.test(word)) return true
  return RANDOM_SHAPE.test(word) && /\d/.test(word) && /[A-Za-z]/.test(word)
}

// scheme://host/path with the userinfo, the query and the fragment dropped, and
// any path piece that looks like a key hidden.
export function safeUrl(url: string): string {
  const m = url.match(/^([a-z][a-z0-9+.-]*):\/\/(?:[^\/@?#]*@)?([^\/?#]*)([^?#]*)(\?[^#]*)?/i)
  if (!m) return looksSecret(url) ? REDACTED : url
  const path = (m[3] ?? '').split('/').map(seg => (looksSecret(seg) ? REDACTED : seg)).join('/')
  return m[1] + '://' + m[2] + path + (m[4] ? '?' + REDACTED : '')
}

// A command line as `claude mcp list` prints it, kept readable but never
// carrying a secret: URLs go through safeUrl, KEY=value with a secret-sounding
// key and the word after --token style flags are hidden, and anything shaped
// like a key is hidden.
export function safeCommand(line: string): string {
  const out: string[] = []
  let hideNext = false
  for (const word of line.split(/\s+/).filter(Boolean)) {
    if (hideNext) {
      out.push(REDACTED)
      hideNext = false
      continue
    }
    const eq = word.indexOf('=')
    if (/^[a-z][a-z0-9+.-]*:\/\//i.test(word)) out.push(safeUrl(word))
    else if (word.startsWith('-') && eq < 0 && SECRET_WORD.test(word)) {
      out.push(word)
      hideNext = true
    } else if (eq > 0 && (SECRET_WORD.test(word.slice(0, eq)) || looksSecret(word.slice(eq + 1)))) out.push(word.slice(0, eq + 1) + REDACTED)
    else if (eq > 0 && /^[a-z][a-z0-9+.-]*:\/\//i.test(word.slice(eq + 1))) out.push(word.slice(0, eq + 1) + safeUrl(word.slice(eq + 1)))
    else out.push(looksSecret(word) ? REDACTED : word)
  }
  return out.join(' ')
}

// `claude mcp list` prints "name: command args - state" or "name: url (HTTP) - state".
// The command part is passed through safeCommand before it is kept.
export function parseMcpList(text: string): Omit<McpRow, 'file'>[] {
  const rows: Omit<McpRow, 'file'>[] = []
  for (const line of text.split('\n')) {
    const i = line.indexOf(': ')
    const j = line.lastIndexOf(' - ')
    if (i < 1 || j < i) continue
    const state = line.slice(j + 3)
    if (!/connected|failed|authentication|needs/i.test(state)) continue
    const rest = line.slice(i + 2, j).trim()
    const remote = rest.match(/^(.*?)\s*\((HTTP|SSE)\)$/i)
    rows.push({
      name: line.slice(0, i),
      state: /connected/i.test(state) ? 'ok' : /auth/i.test(state) ? 'auth' : 'failed',
      transport: remote ? remote[2]!.toLowerCase() : 'stdio',
      target: remote ? safeUrl(remote[1]!) : safeCommand(rest),
    })
  }
  return rows
}

// The server names a config object declares. Only the names are kept, so an
// env block or a header in the file never leaves the function.
export function serverNames(obj: unknown): string[] {
  if (!obj || typeof obj !== 'object') return []
  return Object.entries(obj as Record<string, unknown>).filter(([, v]) => v && typeof v === 'object' && !Array.isArray(v)).map(([k]) => k)
}

// Which config file declares which server, from the files' text. `.mcp.json` may
// hold the servers at the top or under `mcpServers`; ~/.claude.json holds user
// servers at `mcpServers` and this folder's under `projects[cwd].mcpServers`.
export function mcpFileMap(files: { label: string; text: string | null; kind: 'dotmcp' | 'claudejson' }[], cwd: string): Record<string, string> {
  const map: Record<string, string> = {}
  const put = (names: string[], label: string) => {
    for (const n of names) if (!(n in map)) map[n] = label
  }
  for (const f of files) {
    const j = jsonOr<Record<string, any>>(f.text, {})
    if (f.kind === 'dotmcp') put(serverNames(j.mcpServers ?? j), f.label)
    else {
      put(serverNames(j.projects?.[cwd]?.mcpServers), f.label + ' (this folder)')
      put(serverNames(j.mcpServers), f.label + ' (user)')
    }
  }
  return map
}

// The same server spelled as `plugin:foo:bar`, `plugin_foo_bar` or `Plugin foo bar`.
export const norm = (name: string) => name.toLowerCase().replace(/[^a-z0-9]/g, '')

// Token estimates from the engine's context breakdown: tool schemas by server,
// skill listings by plugin.
export function costFrom(
  tools: { serverName: string; tokens: number; isLoaded: boolean }[],
  skills: { pluginName?: string; tokens: number }[],
): Pick<SideCost, 'servers' | 'skills'> {
  const servers: SideCost['servers'] = {}
  for (const t of tools) {
    const e = (servers[t.serverName] ??= { total: 0, loaded: 0 })
    e.total += t.tokens
    if (t.isLoaded) e.loaded += t.tokens
  }
  const bySkill: Record<string, number> = {}
  for (const k of skills) if (k.pluginName) bySkill[k.pluginName] = (bySkill[k.pluginName] ?? 0) + k.tokens
  return { servers, skills: bySkill }
}

export function serverCost(cost: SideCost, name: string): { total: number; loaded: number } | null {
  if (!cost.ok) return null
  const hit = Object.entries(cost.servers).find(([k]) => norm(k) === norm(name))
  return hit ? hit[1] : { total: 0, loaded: 0 }
}

// A plugin's share of the context: its skill listings plus the schemas of the
// MCP servers it ships. Its agents, commands and hooks are not itemized by the
// engine, so this is a floor and the column says so.
export function pluginCost(cost: SideCost, name: string): number | null {
  if (!cost.ok) return null
  const colon = 'plugin:' + name + ':'
  const under = 'plugin_' + name.replace(/[^A-Za-z0-9]/g, '_') + '_'
  let n = cost.skills[name] ?? 0
  for (const [k, v] of Object.entries(cost.servers)) if (k.startsWith(colon) || k.startsWith(under)) n += v.total
  return n
}

// plugin:chrome-devtools-mcp:chrome-devtools -> chrome-devtools
export const shortName = (name: string) => name.replace(/@[\w.-]+$/, '').split(':').pop() || name

// Plugins: enabledPlugins from settings joined with installed_plugins.json.
export function pluginRows(enabledPlugins: Record<string, unknown>, installedText: string | null): PluginRow[] {
  const installed = jsonOr<{ plugins?: Record<string, { installPath?: string; version?: string }[]> }>(installedText, {}).plugins ?? {}
  const ids = [...new Set([...Object.keys(enabledPlugins), ...Object.keys(installed)])]
  return ids
    .map((id): PluginRow => {
      const at = id.lastIndexOf('@')
      const info = installed[id]?.[0]
      return {
        id,
        name: at > 0 ? id.slice(0, at) : id,
        marketplace: at > 0 ? id.slice(at + 1) : 'n/a',
        enabled: enabledPlugins[id] !== undefined && enabledPlugins[id] !== false,
        version: info?.version ?? 'n/a',
        path: info?.installPath ?? 'n/a',
      }
    })
    .sort((a, b) => Number(b.enabled) - Number(a.enabled) || a.name.localeCompare(b.name))
}

// The hook scripts registered in settings, with the event each runs on, so a
// ledger name can be given the file that wrote it.
export function hookScripts(hooks: unknown): { event: string; script: string }[] {
  const found: { event: string; script: string }[] = []
  if (!hooks || typeof hooks !== 'object') return found
  for (const [event, groups] of Object.entries(hooks as Record<string, unknown>)) {
    if (!Array.isArray(groups)) continue
    for (const g of groups) {
      for (const h of (g as { hooks?: { command?: unknown }[] }).hooks ?? []) {
        const cmd = typeof h.command === 'string' ? h.command : ''
        for (const m of cmd.matchAll(/(?:^|\s)((?:~|\/)[^\s"']+\.(?:sh|py|js|mjs|ts))/g)) found.push({ event, script: abs(m[1]!) })
      }
    }
  }
  return found
}

// The script for a ledger name: the same base name, then a name that starts with
// it, then the only script sharing its first word (marked `(guess)`).
export function scriptFor(plug: string, scripts: { event: string; script: string }[]): { event: string; script: string } | null {
  const base = (s: string) => (s.split('/').pop() ?? s).replace(/\.[a-z]+$/, '')
  const shown = (s: { event: string; script: string }, guess = false) => ({ event: s.event, script: tilde(s.script) + (guess ? ' (guess)' : '') })
  const exact = scripts.find(s => base(s.script) === plug)
  if (exact) return shown(exact)
  const prefix = scripts.find(s => base(s.script).startsWith(plug) || plug.startsWith(base(s.script)))
  if (prefix) return shown(prefix)
  const word = plug.split('-')[0]!
  const same = scripts.filter(s => base(s.script).split('-')[0] === word)
  return same.length === 1 ? shown(same[0]!, true) : null
}

// What the hooks injected into this session, from the plug-events ledger lines.
export function summarizeFires(text: string, sid: string, scripts: { event: string; script: string }[] = []): PlugFire[] {
  const by = new Map<string, PlugFire>()
  for (const line of text.split('\n')) {
    if (!line.includes(sid)) continue
    const j = jsonOr<{ plug?: string; session_id?: string; chars?: number; ts?: string; lifecycle?: string }>(line, {})
    if (j.session_id !== sid || !j.plug) continue
    const found = scriptFor(j.plug, scripts)
    const row = by.get(j.plug) ?? { plug: j.plug, fired: 0, chars: 0, last: 0, event: found?.event ?? j.lifecycle ?? 'n/a', script: found?.script ?? 'n/a' }
    row.fired += 1
    row.chars += typeof j.chars === 'number' ? j.chars : 0
    const at = j.ts ? Date.parse(j.ts) : NaN
    if (Number.isFinite(at) && at > row.last) row.last = at
    by.set(j.plug, row)
  }
  return [...by.values()].sort((a, b) => b.chars - a.chars || b.fired - a.fired)
}

// Characters to tokens, the usual rough four to one.
export const estTokens = (chars: number) => Math.round(chars / 4)

// Rows as aligned columns: each column as wide as its widest cell, two spaces
// apart, every row hard-cut at the pane width. The header comes first.
export function alignRows(head: string[], rows: string[][], width: number): string[] {
  const all = [head, ...rows]
  const widths = head.map((_, c) => Math.max(...all.map(r => (r[c] ?? '').length)))
  return all.map(r => cut(r.map((cell, c) => (c === head.length - 1 ? cell : cell.padEnd(widths[c]!))).join('  '), width))
}

export const OVERVIEW_ITEMS = 4

// The Overview rule: a section is a heading, at most four item lines and a
// pointer to its tab. Over four items, the first three and one line that folds
// the rest into a count.
export function overviewItems<T>(items: T[], fold: (rest: T[]) => string): { shown: T[]; fold: string | null } {
  if (items.length <= OVERVIEW_ITEMS) return { shown: items, fold: null }
  return { shown: items.slice(0, OVERVIEW_ITEMS - 1), fold: fold(items.slice(OVERVIEW_ITEMS - 1)) }
}

// The task rows in the order the pane draws them: running first, then blocked,
// then waiting, then finished.
export function taskView(rows: SideTask[]) {
  const live = rows.filter(t => t.status !== 'completed' && t.status !== 'deleted')
  const openIds = new Set(live.map(t => t.id))
  const isBlocked = (t: SideTask) => t.blockedBy.some(id => openIds.has(id))
  const rank = (t: SideTask) => (t.status === 'in_progress' ? 0 : isBlocked(t) ? 1 : 2)
  const ordered = [...live].sort((a, b) => rank(a) - rank(b) || Number(a.id) - Number(b.id)).map(t => ({ ...t, blocked: isBlocked(t) }))
  const finished = rows.filter(t => t.status === 'completed').sort((a, b) => Number(a.id) - Number(b.id)).map(t => ({ ...t, blocked: false }))
  return { done: finished.length, open: live.length, ordered, finished }
}
