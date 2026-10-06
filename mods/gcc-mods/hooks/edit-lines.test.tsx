// The prompt-box edit lines (gcc-goal:, snip-note, dp-note), the snippet store
// and the goal toast, driven with every side effect answered from memory. The
// prompt box is modelled as text plus a cursor, so a fill can be applied the way
// the engine applies an insert.

import type { On } from 'claude-code'
import { describe, expect, mock, test } from 'claude-code/testing'

const NOW = 1_790_000_000_000
// The mod starts off by default; these tests drive it on.
const ON = { options: { startOn: true } }
const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
const fail = (stderr: string) => ({ value: { exitCode: 1, stdout: '', stderr, isStdoutTruncated: false, isStderrTruncated: false } })

const goalJson = (allProven: boolean) =>
  JSON.stringify({
    scope: 'scope',
    armed: '',
    goals: [
      {
        id: 'g1',
        outcome: 'The pane shows the goal record',
        projects: ['/Users/alcatraz627/.claude'],
        accept: [
          { id: 'a1', kind: 'functional', text: 'views render', evidence: 'ran', status: 'proven', source: null },
          { id: 'a2', kind: 'reviewed', text: 'owner reads it', evidence: allProven ? 'ok' : null, status: allProven ? 'proven' : 'open', source: null },
        ],
        milestones: [{ id: 'm1', name: 'STORE', status: 'met' }],
        tasks: [{ id: '1', subject: 'first row', milestone: 'm1', state: 'done', gate: null, blocked_by: [] }],
        containment: [],
        cwd: '/Users/alcatraz627/.claude',
      },
    ],
  })

type World = {
  toasts: string[]
  fills: string[]
  copies: string[]
  writes: { path: string; text: string }[]
  runs: string[][]
  submitted: string[]
  box: { text: string; cursor: number }
  files: Record<string, string>
  pathPy: () => ReturnType<typeof ok>
  writeThrows: boolean
  ipcPeers: string
  ipcLog: string
  ipcPending: string
}

function world(on: On) {
  const w: World = { toasts: [], fills: [], copies: [], writes: [], runs: [], submitted: [], box: { text: '', cursor: 0 }, files: {}, pathPy: () => ok(goalJson(false)), writeThrows: false, ipcPeers: '{"peers":[]}', ipcLog: '{"messages":[]}', ipcPending: '{"messages":[]}' }
  const clock = mock.clock(on, { now: NOW })
  on('classic.SessionStart', () => ({}))
  on('classic.Stop', () => ({}))
  on('ui.toast', ($, e) => {
    w.toasts.push(e.text)
    return { value: undefined }
  })
  on('ui.status', () => ({ value: undefined }))
  on('ui.log', () => ({ value: undefined }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('ui.close', () => ({ value: undefined }))
  on('ui.panes', () => ({ value: [] }))
  on('ui.copy', ($, e) => {
    w.copies.push(e.text)
    return { value: { isCopied: true } }
  })
  on('ui.invalidate', () => ({ value: undefined }))
  on('prompt.read', () => ({ value: { ...w.box } }))
  on('prompt.fill', ($, e) => {
    w.fills.push(e.text)
    return { isFilled: true }
  })
  on('prompt.submit', ($, e) => {
    w.submitted.push(e.text)
    return { text: e.text }
  })
  on('session.cwd', () => ({ value: '/Users/alcatraz627/.claude' }))
  on('session.id', () => ({ value: 'test-session-0001' }))
  on('fs.exists', () => ({ value: false }))
  on('fs.list', () => ({ value: [] }))
  on('fs.read', ($, e) => ({ value: w.files[String((e as { path?: string }).path ?? '')] ?? '' }))
  on('fs.write', ($, e) => {
    if (w.writeThrows) throw new Error('EACCES: simulated write failure')
    const ev = e as { path?: string; text?: string; content?: string; data?: string }
    const text = String(ev.text ?? ev.content ?? ev.data ?? '')
    w.writes.push({ path: String(ev.path), text })
    w.files[String(ev.path)] = text
    return { value: undefined }
  })
  on('process.run', ($, e) => {
    w.runs.push([...e.argv])
    const argv = e.argv.join(' ')
    if (argv.includes('path.py')) return w.pathPy()
    if (argv.includes('claude-ipc inbox --project')) return ok('{"messages":[]}')
    if (argv.includes('claude-ipc inbox')) return ok(w.ipcPending)
    if (argv.includes('claude-ipc peers')) return ok(w.ipcPeers)
    if (argv.includes('claude-ipc log')) return ok(w.ipcLog)
    if (argv.startsWith('tail')) return ok('')
    if (argv.includes('resolve.sh')) return { value: { exitCode: 3, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
    return ok('ok')
  })
  on('ui.render', ($, e) => $.ui.resolve(e).Box({ children: [] }))
  return Object.assign(w, { clock })
}

const PANE_PROPS = { title: 'gcc', isFocused: true, bodyColumns: 90, placement: 'dock' as const, scroll: { offset: 0, bodyRows: 40 }, view: {} }
const DP = '/Users/alcatraz627/.claude/assets/decision-pages'
const PROJ = '/Users/alcatraz627/.claude/snippets/project-Users_alcatraz627_.claude.jsonl'
const snipRow = (id: string, text: string) => JSON.stringify({ kind: 'snippet', id, ts: NOW, scope: 'project', project: '/Users/alcatraz627/.claude', sid: 'x', title: text, text, notes: '', tags: [] })

function withPage(w: World) {
  w.files[DP + '/.pending.txt'] = 'pg\n'
  w.files[DP + '/pg/config.json'] = JSON.stringify({
    title: 'My page',
    origin: { project: '/Users/alcatraz627/.claude', session: 'me' },
    decisions: [{ id: 'D1', question: 'which?', options: [{ code: 'a', label: 'A', rec: true }, { code: 'b', label: 'B' }] }],
  })
}

const isDrop = (r: unknown) => typeof (r as { drop?: unknown }).drop === 'string'

describe('edit lines', () => {
  test('a dp-note shows on the page and travels in the answer string', ON, async ($, on) => {
    const w = world(on)
    withPage(w)
    await $.classic.SessionStart({ source: 'clear' })
    expect(isDrop(await $.prompt.submit({ text: 'dp-note pg/D1: prefer b after the migration' } as any))).toBe(true)
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-decide' })
    expect(await ui.find({ text: 'note: prefer b after the migration' })).toBeDefined()
    await ui.press({ key: 'dp-copy' })
    expect(w.copies[0]).toContain('D1 note — prefer b after the migration')
  })

  test('text after a dp-note line comes back to the box and stays out of the note', ON, async ($, on) => {
    const w = world(on)
    withPage(w)
    await $.classic.SessionStart({ source: 'clear' })
    const r = await $.prompt.submit({ text: 'dp-note pg/D1: prefer b\nalso, please rerun the suite before you commit' } as any)
    await w.clock.advance(400)
    expect(isDrop(r)).toBe(true)
    expect(w.submitted).toEqual([])
    expect(w.fills).toEqual(['also, please rerun the suite before you commit'])
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-decide' })
    expect(await ui.find({ text: 'note: prefer b' })).toBeDefined()
  })

  test('a goal line filled at the start of a draft saves only the goal; the draft comes back', ON, async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'clear' })
    w.box = { text: 'fix the login bug before lunch', cursor: 0 }
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-tasks' })
    await ui.press({ key: 'goal-edit-btn' })
    const pv = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc-preview', props: PANE_PROPS })
    await pv.press({ key: 'pv-edit' })
    await pv.press({ key: 'pv-goal-long' })
    expect(w.fills.length).toBe(1)
    const boxAfter = w.box.text.slice(0, w.box.cursor) + w.fills[0] + w.box.text.slice(w.box.cursor)
    w.runs.length = 0
    w.fills.length = 0
    const r = await $.prompt.submit({ text: boxAfter } as any)
    await w.clock.advance(400)
    expect(isDrop(r)).toBe(true)
    const set = w.runs.find(a => a.includes('set'))
    expect(set).toContain('The pane shows the goal record')
    expect(set?.join(' ')).not.toContain('login')
    expect(w.fills).toEqual(['fix the login bug before lunch'])
  })

  test('a snip-note for an unknown id says so, writes nothing, and puts the draft back', ON, async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'clear' })
    w.writes.length = 0
    const r = await $.prompt.submit({ text: 'snip-note s-doesnotexist: my careful note' } as any)
    await w.clock.advance(400)
    expect(isDrop(r)).toBe(true)
    expect(w.toasts.some(t => t.startsWith('Snippet note saved'))).toBe(false)
    expect(w.toasts.some(t => t.includes('s-doesnotexist'))).toBe(true)
    expect(w.writes).toEqual([])
    expect(w.fills).toEqual(['snip-note s-doesnotexist: my careful note'])
  })

  test('a dp-note for an unknown page says so and puts the draft back', ON, async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'clear' })
    const r = await $.prompt.submit({ text: 'dp-note nopage/D9: a ruling' } as any)
    await w.clock.advance(400)
    expect(isDrop(r)).toBe(true)
    expect(w.toasts.some(t => t.includes('nopage/D9'))).toBe(true)
    expect(w.fills).toEqual(['dp-note nopage/D9: a ruling'])
  })

  test('when the save throws, the edit line is not sent and the draft comes back', ON, async ($, on) => {
    const w = world(on)
    w.files[PROJ] = snipRow('s-x', 'x') + '\n'
    await $.classic.SessionStart({ source: 'clear' })
    w.writeThrows = true
    const r = await $.prompt.submit({ text: 'snip-note s-x: private aside about the customer' } as any)
    await w.clock.advance(400)
    expect(isDrop(r)).toBe(true)
    expect(w.submitted).toEqual([])
    expect(w.fills).toEqual(['snip-note s-x: private aside about the customer'])
  })

  test('an ordinary prompt passes through untouched', ON, async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'clear' })
    const r = await $.prompt.submit({ text: 'hello there\nsecond line' } as any)
    expect(isDrop(r)).toBe(false)
    expect(w.submitted).toEqual(['hello there\nsecond line'])
  })
})

describe('snippet store', () => {
  test("a note saved here keeps a snippet another session added since load", ON, async ($, on) => {
    const w = world(on)
    w.files[PROJ] = snipRow('s-mine', 'mine') + '\n'
    await $.classic.SessionStart({ source: 'clear' })
    w.files[PROJ] = snipRow('s-mine', 'mine') + '\n' + snipRow('s-peer', 'peer session snippet') + '\n'
    await $.prompt.submit({ text: 'snip-note s-mine: a note' } as any)
    const out = w.files[PROJ] ?? ''
    expect(out).toContain('s-peer')
    expect(out).toContain('"notes":"a note"')
  })

  test("deleting a snippet here keeps the one another session added", ON, async ($, on) => {
    const w = world(on)
    w.files[PROJ] = snipRow('s-mine', 'mine') + '\n'
    await $.classic.SessionStart({ source: 'clear' })
    w.files[PROJ] = snipRow('s-mine', 'mine') + '\n' + snipRow('s-peer', 'peer session snippet') + '\n'
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-snips' })
    await ui.press({ key: 'snip-s-mine' })
    await ui.press({ key: 'snip-del' })
    const out = w.files[PROJ] ?? ''
    expect(out).toContain('s-peer')
    expect(out).not.toContain('"id":"s-mine"')
  })

  test('a note can go on a snippet another session added since load', ON, async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'clear' })
    w.files[PROJ] = snipRow('s-peer', 'peer session snippet') + '\n'
    const r = await $.prompt.submit({ text: 'snip-note s-peer: noted here' } as any)
    expect(isDrop(r)).toBe(true)
    expect(w.files[PROJ] ?? '').toContain('"notes":"noted here"')
  })

  test('a new snippet saved here keeps the one another session added since load', ON, async ($, on) => {
    const w = world(on)
    on('ui.selection', () => ({ value: { text: 'a line worth keeping' } }))
    await $.classic.SessionStart({ source: 'clear' })
    w.files[PROJ] = snipRow('s-peer', 'peer session snippet') + '\n'
    await $.command.run({ command: 'hub', args: 'snip' } as any)
    const out = w.files[PROJ] ?? ''
    expect(out).toContain('s-peer')
    expect(out).toContain('a line worth keeping')
  })

  test('moving a snippet to global takes it out of the project file and keeps the peer row', ON, async ($, on) => {
    const w = world(on)
    w.files[PROJ] = snipRow('s-mine', 'mine') + '\n'
    await $.classic.SessionStart({ source: 'clear' })
    w.files[PROJ] = snipRow('s-mine', 'mine') + '\n' + snipRow('s-peer', 'peer') + '\n'
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-snips' })
    await ui.press({ key: 'snip-s-mine' })
    await ui.press({ key: 'snip-move' })
    expect(w.files[PROJ] ?? '').toContain('s-peer')
    expect(w.files[PROJ] ?? '').not.toContain('"id":"s-mine"')
    expect(w.files['/Users/alcatraz627/.claude/snippets/global.jsonl'] ?? '').toContain('"id":"s-mine"')
  })
})

const BAND_PROPS = { hasSurvey: false, isWorking: false, maxRows: 6, bodyColumns: 120, scroll: { offset: 0, bodyRows: 6 }, view: {} }

describe('off by default', () => {
  test('a new session draws nothing, says nothing, and lets every prompt through', async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'startup' })
    const band = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'AbovePrompt', props: BAND_PROPS })
    expect(await band.find({ key: 'c-docs' })).toBeUndefined()
    expect(w.toasts).toEqual([])
    expect(w.runs).toEqual([])
    const r = await $.prompt.submit({ text: 'gcc-goal: not a goal while the mod is off' } as any)
    expect(isDrop(r)).toBe(false)
    expect(w.submitted).toEqual(['gcc-goal: not a goal while the mod is off'])
  })

  test('/hub turns the mod on and opens the hub; /hub off silences it again', async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'tasks' } as any)
    expect(w.toasts.some(t => t.includes('on for this session'))).toBe(true)
    expect(w.runs.some(a => a.join(' ').includes('path.py'))).toBe(true)
    const band = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'AbovePrompt', props: BAND_PROPS })
    expect(await band.find({ key: 'c-docs' })).toBeDefined()
    await $.command.run({ command: 'hub', args: 'off' } as any)
    const after = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'AbovePrompt', props: BAND_PROPS })
    expect(await after.find({ key: 'c-docs' })).toBeUndefined()
  })

  test('the startOn switch turns it on for every session', { options: { startOn: true } }, async ($, on) => {
    world(on)
    await $.classic.SessionStart({ source: 'startup' })
    const band = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'AbovePrompt', props: BAND_PROPS })
    expect(await band.find({ key: 'c-docs' })).toBeDefined()
  })
})

describe('restyled tabs with rows in them', () => {
  test('Nudges lists a routed block as a row, and its detail frame switches between text and why', ON, async ($, on) => {
    world(on)
    on('prompt.attachment', ($, e) => ({ text: e.text }))
    await $.classic.SessionStart({ source: 'clear' })
    await $.prompt.attachment({ type: 'hook_context', text: '<owner surface="toast" hook="subagent-box">seat landed · output ✓</owner>', origin: { kind: 'hook', event: 'SubagentStop' } } as any)
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-nudges' })
    expect(await ui.find({ text: 'subagent-box' })).toBeDefined()
    expect(await ui.find({ text: 'seat landed · output ✓' })).toBeDefined()
    await ui.press({ key: 'm-why' })
    expect(await ui.find({ text: 'routed to toast' })).toBeDefined()
    expect(await ui.find({ key: 'nudge-preview' })).toBeDefined()
  })

  test('Inbox shows what this session sent beside what it received, and only the received one is new', ON, async ($, on) => {
    const w = world(on)
    w.ipcPeers = JSON.stringify({ peers: [{ sessionId: 'test-session-0001', sessionAliases: ['me-alias'] }] })
    w.ipcLog = JSON.stringify({
      messages: [
        { id: 'out-1', kind: 'inform', fromAlias: 'me-alias', toAlias: 'clanky-opus', body: 'please arm the hub', ts: 1_789_999_000 },
        { id: 'in-1', kind: 'query', fromAlias: 'clanky-opus', toAlias: 'me-alias', body: 'armed, thanks', ts: 1_789_999_500 },
        { id: 'in-0', kind: 'inform', fromAlias: 'switchboard-panel', toAlias: 'me-alias', body: 'already handled by the agent', ts: 1_789_998_000 },
      ],
    })
    // in-1 still waits in this session's inbox; in-0 was consumed, so it is not new.
    w.ipcPending = JSON.stringify({ messages: [{ id: 'in-1' }] })
    await $.classic.SessionStart({ source: 'clear' })
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-inbox' })
    expect(await ui.find({ text: '3 messages · 1 new · 1 sent' })).toBeDefined()
    expect(await ui.find({ text: '→ clanky-opus' })).toBeDefined()
    // The click target is the sender, not the one-glyph read dot beside it.
    expect((await ui.find({ key: 'msg-in-1' }))?.text).toBe('clanky-opus')
    expect((await ui.find({ key: 'msg-out-1' }))?.text).toBe('→ clanky-opus')
    await ui.press({ key: 'msg-out-1' })
    expect(await ui.find({ text: 'you → clanky-opus' })).toBeDefined()
    expect(await ui.find({ key: 'reply-open' })).toBeUndefined()
    await ui.press({ key: 'msg-in-1' })
    expect(await ui.find({ key: 'reply-open' })).toBeDefined()
    expect(w.runs.some(a => a.join(' ').includes('--consume'))).toBe(false)
  })

  test('Fleet lists a launched seat under Running with its detail frame', ON, async ($, on) => {
    world(on)
    on('tool.call', { tool: 'Agent' } as any, () => ({ result: { status: 'async_launched', agentId: 'ag-1' } }) as any)
    await $.classic.SessionStart({ source: 'clear' })
    await $.tool.call({ tool: 'Agent', tool_use_id: 'tu-1', description: 'Map the surfaces', prompt: 'Write to /tmp/x/report.md before returning', subagent_type: 'general-purpose', model: 'sonnet' } as any)
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-fleet' })
    expect(await ui.find({ text: 'Running · 1' })).toBeDefined()
    expect(await ui.find({ key: 'seat-tu-1' })).toBeDefined()
    expect(await ui.find({ key: 'seat-copy' })).toBeDefined()
    expect(await ui.find({ text: 'output: /tmp/x/report.md' })).toBeDefined()
  })
})

describe('goal toast', () => {
  test('a failed first read does not make the next read toast a long-met goal', ON, async ($, on) => {
    const w = world(on)
    let calls = 0
    w.pathPy = () => (++calls === 1 ? fail('path.py: transient') : ok(goalJson(true)))
    await $.classic.SessionStart({ source: 'clear' })
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-tasks' })
    await ui.press({ key: 'refresh' })
    expect(w.toasts.some(t => t.includes('every acceptance row is proven'))).toBe(false)
  })

  test('a goal met while the session watches toasts once', ON, async ($, on) => {
    const w = world(on)
    let met = false
    w.pathPy = () => ok(goalJson(met))
    await $.classic.SessionStart({ source: 'clear' })
    met = true
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-tasks' })
    await ui.press({ key: 'refresh' })
    await ui.press({ key: 'refresh' })
    expect(w.toasts.filter(t => t.includes('every acceptance row is proven')).length).toBe(1)
  })
})
