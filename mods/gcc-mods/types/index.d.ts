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

export type Meter = { ctx: number | null; week: number | null; at: number }

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
// so it never counts as new.
export type Msg = { id: string; from: string; kind: string; at: number; isRead: boolean }
export type Mail = { messages: Msg[]; at: number; lastWakeAt: number; error: string | null }

export type Idle = { since: number | null; openRows: number; continueOfferedAt: number | null }

// A pending decision page, as much as the band and the wake need: whose it is
// and how many calls it carries. The page itself is answered in the browser.
export type DecideSet = { slug: string; title: string; project: string; session: string; calls: number }
export type Decide = { pending: DecideSet[]; answered: string[]; at: number }

export type View = { isBandHidden: boolean }

declare module 'claude-code' {
  interface PluginState {
    'gcc-mods': {
      view: View
      goals: GoalsSnap | null
      catchup: Catchup | null
      meter: Meter
      seats: Seat[]
      mail: Mail
      idle: Idle
      decide: Decide
      // null until /hub on or /hub off decides it this session; the startOn switch fills in.
      enabled: boolean | null
    }
  }
}
