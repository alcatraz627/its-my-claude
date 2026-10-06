// The values gcc-mods keeps in $.state for the session. Every one is a VIEW
// over a gcc file or command; the files (gs, jsonl, claude-ipc, decision
// pages) stay the source of truth and nothing here is written back except
// through their own CLIs.

export type Tab = 'docs' | 'tasks' | 'nudges' | 'fleet' | 'inbox' | 'decide' | 'snips'

export type Scope = 'global' | 'project' | 'session'
// A selection the owner kept, with a title and notes, in a jsonl file per scope.
export type Snippet = { id: string; ts: number; scope: Scope; project: string; sid: string; title: string; text: string; notes: string; tags: string[] }
// A doc the owner bookmarked, in the same files.
export type Bookmark = { id: string; ts: number; scope: Scope; project: string; sid: string; path: string; note: string }
export type Snips = { snippets: Snippet[]; bookmarks: Bookmark[]; at: number; sel: string | null; editing: 'title' | 'notes' | 'tags' | null; scope: Scope | 'all' }

export type DocKind = 'report' | 'checkpoint' | 'notes' | 'plan' | 'review' | 'doc' | 'page'
export type Doc = {
  id: string
  title: string
  path: string
  kind: DocKind
  isThisSession: boolean
  edits: number
  at: number
  isLive: boolean
}
export type DocFilter = 'session' | 'all' | 'reports' | 'checkpoints'

export type AcceptRow = {
  id: string
  kind: string
  text: string
  evidence: string | null
  status: string
  source: string | null
}
export type TaskRow = {
  id: string
  subject: string
  milestone: string | null
  state: string
  gate: string | null
  blockedBy: string[]
  lane: string | null
  tier: string | null
  note: string | null
}
export type Milestone = { id: string; name: string; status: string }
export type GoalView = {
  id: string
  outcome: string
  projects: string[]
  accept: AcceptRow[]
  milestones: Milestone[]
  tasks: TaskRow[]
  containment: string[]
  cwd: string | null
}
export type GoalsSnap = { scope: string; armed: string; sessionGoal: string; goals: GoalView[]; at: number; error: string | null }

export type Catchup = {
  name: string
  path: string
  at: number
  summary: string
  source: string
  state: 'offered' | 'loaded' | 'skipped'
}

export type Meter = {
  ctx: number | null
  fiveHour: number | null
  week: number | null
  costUsd: number | null
  at: number
}

export type Seat = {
  id: string
  agentId: string | null
  name: string
  type: string
  model: string
  resolvedModel: string | null
  desc: string
  startedAt: number
  endedAt: number | null
  durationMs: number | null
  outputPath: string | null
  hasOutput: boolean | null
  isBackground: boolean
  wokeAt: number | null
}

// One ipc message this session sent or received. A sent one is stored as read,
// so it never counts as new.
export type Msg = {
  id: string
  from: string
  to: string
  isSent: boolean
  kind: string
  at: number
  text: string
  isRead: boolean
}
export type Mail = { messages: Msg[]; at: number; lastWakeAt: number; error: string | null }

export type Audience = 'owner' | 'model' | 'both'
export type Nudge = {
  id: string
  hook: string
  event: string
  audience: Audience
  action: string
  chars: number
  text: string
  detail: string
  at: number
  heeded: string
  snoozed: string | null
  feedback: string | null
}
export type NudgeMode = 'text' | 'why' | 'snooze' | 'feedback'

export type Notice = { id: string; hook: string; text: string; at: number }

export type Receipt = {
  turnStartedAt: number
  lastRun: { cmd: string; at: number; ok: boolean } | null
  lastShot: { path: string; at: number } | null
  lastCurl: { url: string; at: number } | null
  claim: { text: string; at: number } | null
}

export type Idle = { since: number | null; openRows: number; continueOfferedAt: number | null }

export type DecideOption = { code: string; label: string; rec: boolean }
// kind 'section': a page's agree/DISAGREE card (config `sections`), answered as
// `id: DISAGREE — note` only when it deviates, as the web page does.
export type DecideItem = { id: string; question: string; context: string; options: DecideOption[]; kind?: 'decision' | 'section' }
export type DecideSet = {
  slug: string
  title: string
  intro: string
  project: string
  session: string
  created: string
  items: DecideItem[]
}
export type Decide = {
  pending: DecideSet[]
  picks: Record<string, string>
  notes: Record<string, string>
  at: number
  submitted: string[]
  answered: string[]
}

// goalsSeeded: the goal record has been read successfully once, so a goal met
// from here on is news and earns its toast.
export type Fun = { greetedAt: number | null; metGoals: string[]; lastLanding: string; goalsSeeded: boolean }

// What the preview pane shows: the full text of whatever was last picked.
export type Preview = { title: string; text: string; path: string | null; at: number; kind: 'text' | 'goal'; goalId: string | null; editing: boolean }

export type View = {
  tab: Tab
  docFilter: DocFilter
  docSel: string | null
  docFull: boolean
  hidden: string[]
  goalSel: number
  showDone: boolean
  showOthers: boolean
  rejecting: string | null
  nudgeSel: string | null
  nudgeMode: NudgeMode
  snoozeFor: string
  seatSel: string | null
  msgSel: string | null
  isReplying: boolean
  isBandHidden: boolean
  decideSlug: string | null
  decideSel: string | null
  dismissed: string[]
  goalEditing: boolean
}

declare module 'claude-code' {
  interface PluginState {
    'gcc-mods': {
      view: View
      docs: Doc[]
      goals: GoalsSnap | null
      catchup: Catchup | null
      meter: Meter
      seats: Seat[]
      mail: Mail
      nudges: Nudge[]
      notices: Notice[]
      receipt: Receipt
      idle: Idle
      decide: Decide
      fun: Fun
      preview: Preview | null
      // null until /hub or /hub off decides it this session; the startOn switch fills in.
      enabled: boolean | null
      snips: Snips
    }
  }
}
