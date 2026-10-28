// The values gcc-mods keeps in $.state for the session. Every one is a VIEW
// over a gcc file or command; the files (gs, claude-ipc, decision pages, the
// checkpoint index) stay the source of truth and the mod never writes them.

export type AcceptRow = { id: string; kind: string; status: string }
export type TaskRow = { id: string; state: string; gate: string | null; blockedBy: string[] }
export type GoalView = { id: string; outcome: string; accept: AcceptRow[]; tasks: TaskRow[] }
export type GoalsSnap = { goals: GoalView[]; at: number; error: string | null }

export type Catchup = {
  name: string
  path: string
  at: number
  summary: string
  source: string
  state: 'offered' | 'loaded' | 'skipped'
}

// `tokens` and `window` are the last response's real input side and the model's window.
export type Meter = { ctx: number | null; week: number | null; tokens: number | null; window: number | null; at: number }

export type Seat = {
  id: string
  agentId: string | null
  name: string
  startedAt: number
  endedAt: number | null
  durationMs: number | null
  outputPath: string | null
  hasOutput: boolean | null
  isBackground: boolean
  wokeAt: number | null
}

// One ipc message this session received or sent. A sent one is stored as read,
// so it never counts as new. `deliveryState` is the broker's own word for how far
// the message got; null when an older broker does not say.
export type DeliveryState = 'queued' | 'delivered' | 'surfaced'
export type Msg = { id: string; from: string; kind: string; at: number; isRead: boolean; deliveryState: DeliveryState | null }
// `enabledAt` is when the mod switched on in this session: without a delivery
// state, a message older than that is never news.
export type Mail = { messages: Msg[]; at: number; lastWakeAt: number; enabledAt: number; error: string | null }

export type Idle = { since: number | null; openRows: number; continueOfferedAt: number | null }

// A pending decision page, as much as the band and the wake need: whose it is
// and how many calls it carries. The page itself is answered in the browser.
// `waiting` is false once the ledger dropped the page but its answer file is still
// unread: kept only so the wake fires, never shown as waiting on the owner.
export type DecideSet = { slug: string; title: string; project: string; session: string; calls: number; waiting?: boolean }
// `dismissed` mirrors decision-page.sh's band list: pages kept off the band but
// still listed in the side pane.
export type Decide = { pending: DecideSet[]; answered: string[]; dismissed: string[]; at: number }

// The band's look: S1 one line (default), S2 accent bar, S3 rounded box.
export type Preset = 'S1' | 'S2' | 'S3'
export type View = { isBandHidden: boolean; preset: Preset }

// What the display-only side pane shows. Each block keeps its own refresh time
// so a slow source (the MCP health check) is not re-run on every tick. Nothing
// here ever holds an env value, a header or a token: the MCP rows carry only a
// name, a state, a transport and a command or URL already stripped of secrets.
export type SideTab = 'overview' | 'tasks' | 'decisions' | 'mcp' | 'plugins' | 'injections' | 'context'
// One decision page as the side pane lists it: every project's, marked here or not.
export type SidePage = { slug: string; title: string; project: string; calls: number; isHere: boolean; isDismissed: boolean }
export type SideTask = { id: string; subject: string; status: string; blockedBy: string[] }
export type McpRow = { name: string; state: 'ok' | 'auth' | 'failed'; transport: string; target: string; file: string }
export type PluginRow = { id: string; name: string; marketplace: string; enabled: boolean; version: string; path: string }
export type PlugFire = { plug: string; fired: number; chars: number; last: number; event: string; script: string }
// Token estimates from $.session.usage({ breakdown }): MCP tool schemas by server,
// and skill listings by plugin. `ok` is false when the engine gave no breakdown.
export type SideCost = { servers: Record<string, { total: number; loaded: number }>; skills: Record<string, number>; at: number; ok: boolean }
// The fields of the engine's summary breakdown the context tab reads. The whole
// breakdown is kept as it came (the contract cannot import the engine's type);
// null when the engine gave none.
export type CtxBreakdown = {
  categories: { name: string; tokens: number; kind: 'used' | 'free' | 'buffer' | 'deferred' }[]
  totalTokens: number
  rawMaxTokens: number
  autoCompactThreshold?: number
  memoryFiles: { path: string; type: string; tokens: number }[]
}
export type SideContext = { breakdown: CtxBreakdown | null; at: number }
export type Side = {
  isOpen: boolean
  tab: SideTab
  tasks: { store: string | null; rows: SideTask[]; at: number; triedAt: number; error: string | null }
  mcp: { rows: McpRow[]; at: number; error: string | null }
  plugins: { rows: PluginRow[]; at: number }
  fires: { rows: PlugFire[]; at: number; error: string | null }
  cost: SideCost
  context: SideContext
}

// Images named in the prompt draft ([Image #n]) and where their files live.
export type Images = {
  nums: number[]
  sid: string
  dir: string | null
  files: Record<string, string>
  // The draft's image set the owner dismissed the row for.
  dismissed: string
}

declare module 'claude-code' {
  interface PluginState {
    'gcc-mods': {
      view: View
      goals: GoalsSnap | null
      catchup: Catchup | null
      // The checkpoint this session's own /core-dump wrote.
      dump: { name: string; path: string } | null
      meter: Meter
      seats: Seat[]
      mail: Mail
      idle: Idle
      decide: Decide
      side: Side
      images: Images
      // Main turns finished this session, and band rows skipped for it.
      turns: number
      skipped: string[]
      // null until /hub on or /hub off decides it this session; the startOn switch fills in.
      enabled: boolean | null
    }
  }
}
