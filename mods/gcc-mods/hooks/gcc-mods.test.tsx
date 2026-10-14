// Drives the passive surfaces (band, status line, wakes, path links) with the
// engine beneath answered from memory: a fixed clock, canned output for the gcc
// commands, a prompt box modelled as text plus a cursor, and quiet side effects.

import type { On } from 'claude-code'
import { describe, expect, mock, test } from 'claude-code/testing'

const NOW = 1_790_000_000_000
// The mod starts off by default; most tests drive it on.
const ON = { options: { startOn: true } }
const CWD = '/Users/alcatraz627/.claude'
const DP = CWD + '/assets/decision-pages'
const CKPT = CWD + '/_20261015-probe-aa.claude.md'
const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
const miss = { value: { exitCode: 3, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }

const goalJson = (gate: unknown, readyRows = 0) =>
  JSON.stringify({
    goals: [
      {
        id: 'g1',
        outcome: 'The band offers what waits',
        accept: [
          { id: 'a1', kind: 'functional', text: 'views render', status: 'proven' },
          { id: 'a2', kind: 'reviewed', text: 'owner reads it', status: 'open' },
        ],
        tasks: [
          { id: '1', subject: 'gated row', state: 'owner-gate', gate, blocked_by: [] },
          ...Array.from({ length: readyRows }, (_, i) => ({ id: 'r' + i, subject: 'ready row', state: 'todo', gate: null, blocked_by: [] })),
        ],
      },
    ],
  })

type World = {
  toasts: string[]
  fills: { text: string; mode: string }[]
  copies: string[]
  submitted: string[]
  commands: string[]
  rendered: string[]
  statuses: (string | undefined)[]
  runs: string[][]
  box: { text: string; cursor: number }
  files: Record<string, string>
  exists: Set<string>
  pathPy: () => ReturnType<typeof ok>
  resolve: () => ReturnType<typeof ok> | typeof miss
}

function world(on: On) {
  const w: World = {
    toasts: [], fills: [], copies: [], submitted: [], commands: [], rendered: [], statuses: [], runs: [],
    box: { text: '', cursor: 0 }, files: {}, exists: new Set(),
    pathPy: () => ok(goalJson('USER: pick one')),
    resolve: () => miss,
  }
  const clock = mock.clock(on, { now: NOW })
  on('session.start', ($, e) => ({ cwd: e.cwd }))
  on('command.register', ($, e) => ({ value: { command: (e as { name?: string }).name ?? '' } }))
  on('command.run', ($, e) => {
    w.commands.push('/' + e.command + ' ' + e.args)
    return {}
  })
  on('session.measure', () => ({ changed: [] }))
  on('classic.SessionStart', () => ({}))
  on('classic.Stop', () => ({}))
  on('ui.toast', ($, e) => {
    w.toasts.push(e.text)
    return { value: undefined }
  })
  on('ui.status', ($, e) => {
    w.statuses.push((e as { text?: string }).text)
    return { value: undefined }
  })
  on('ui.log', () => ({ value: undefined }))
  on('ui.copy', ($, e) => {
    w.copies.push(e.text)
    return { value: { isCopied: true } }
  })
  on('ui.invalidate', () => ({ value: undefined }))
  on('prompt.read', () => ({ value: { ...w.box } }))
  on('prompt.fill', ($, e) => {
    w.fills.push({ text: e.text, mode: String((e as { mode?: string }).mode ?? 'replace') })
    return { isFilled: true }
  })
  on('prompt.submit', ($, e) => {
    w.submitted.push(e.text)
    return { text: e.text }
  })
  on('session.cwd', () => ({ value: CWD }))
  on('session.id', () => ({ value: 'test-session-0001' }))
  on('fs.exists', ($, e) => ({ value: w.exists.has(String((e as { path?: string }).path ?? '')) }))
  on('fs.list', () => ({ value: [] }))
  on('fs.read', ($, e) => ({ value: w.files[String((e as { path?: string }).path ?? '')] ?? '' }))
  on('process.run', ($, e) => {
    w.runs.push([...e.argv])
    const argv = e.argv.join(' ')
    if (argv.includes('path.py')) return w.pathPy()
    if (argv.includes('resolve.sh')) return w.resolve()
    if (argv.includes('claude-ipc peers')) return ok('{"peers":[]}')
    if (argv.includes('claude-ipc inbox')) return ok('{"messages":[]}')
    return ok('')
  })
  on('ui.render', ($, e) => {
    const text = (e as { props?: { text?: unknown } }).props?.text
    if (typeof text === 'string') w.rendered.push(text)
    return $.ui.resolve(e).Box({ children: [] })
  })
  return Object.assign(w, { clock })
}

const BAND_PROPS = { hasSurvey: false, isWorking: false, maxRows: 6, bodyColumns: 120, scroll: { offset: 0, bodyRows: 6 }, view: {} }
const mountBand = ($: any, surface: 'terminal' | 'desktop' = 'terminal') => $.ui.mount({ plugin: 'gcc-mods', surface, component: 'AbovePrompt', props: BAND_PROPS })

function withCheckpoint(w: World) {
  w.resolve = () => ok(JSON.stringify({ name: 'probe-aa', checkpoint_path: CKPT, ts: new Date(NOW - 600_000).toISOString(), summary: 'the probe session' }))
  w.exists.add(CKPT)
}

function withPage(w: World) {
  w.files[DP + '/.pending.txt'] = 'pg\n'
  w.files[DP + '/pg/config.json'] = JSON.stringify({ title: 'My page', origin: { project: CWD, session: 'me' }, decisions: [{ id: 'D1' }, { id: 'D2' }] })
}

describe('off by default', () => {
  test('a new session draws nothing, says nothing, and runs nothing', async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    await $.classic.SessionStart({ source: 'clear' })
    const band = await mountBand($)
    expect(await band.find({ key: 'cu-load' })).toBeUndefined()
    expect(w.toasts).toEqual([])
    expect(w.runs).toEqual([])
  })

  test('/hub on turns it on; /hub off silences it again', async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'on' } as any)
    expect(w.toasts.some(t => t.includes('on for this session'))).toBe(true)
    expect(w.runs.some(a => a.join(' ').includes('path.py'))).toBe(true)
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeDefined()
    await $.command.run({ command: 'hub', args: 'off' } as any)
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeUndefined()
  })

  test('the startOn switch turns it on for every session', ON, async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    await $.classic.SessionStart({ source: 'clear' })
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeDefined()
  })
})

describe('the band', () => {
  for (const surface of ['terminal', 'desktop'] as const) {
    test('after a clear it offers the checkpoint, and load runs /catchup on it, on ' + surface, ON, async ($, on) => {
      const w = world(on)
      withCheckpoint(w)
      await $.classic.SessionStart({ source: 'clear' })
      const band = await mountBand($, surface)
      expect(await band.find({ text: /probe-aa/ })).toBeDefined()
      await band.press({ key: 'cu-load' })
      expect(w.commands).toEqual(['/catchup ' + CKPT])
      expect(w.submitted).toEqual([])
    })
  }

  test('a pending decision page for this folder shows with its link, ahead of the checkpoint', ON, async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    withPage(w)
    await $.classic.SessionStart({ source: 'clear' })
    const band = await mountBand($)
    expect(await band.find({ text: /My page · 2 calls drafted for you · http:\/\/localhost:5106\/dp\/pg\// })).toBeDefined()
    expect(await band.find({ key: 'cu-load' })).toBeUndefined()
  })

  test('owed reads point at /tasks now when nothing else applies', ON, async ($, on) => {
    world(on)
    await $.classic.SessionStart({ source: 'clear' })
    // a2 open and reviewed, plus one gated row whose gate is an object.
    expect(await (await mountBand($)).find({ text: /2 reads owed by you · \/tasks now/ })).toBeDefined()
  })

  test('a gate written as an object still counts, in the band and the status line', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(goalJson({ text: 'USER: pick the display', do: 'Agent pick: a count' }))
    await $.classic.SessionStart({ source: 'clear' })
    expect(await (await mountBand($)).find({ text: /2 reads owed/ })).toBeDefined()
    expect(w.statuses.at(-1)).toContain('2 gates')
  })

  test('a stop with agent-ready rows open offers continue, and continue submits the queue prompt', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(goalJson(null, 2))
    await $.classic.SessionStart({ source: 'startup' })
    await $.classic.Stop({ last_assistant_message: 'paused' } as any)
    const band = await mountBand($)
    expect(await band.find({ text: /stopped with 2 agent-ready rows open/ })).toBeDefined()
    await band.press({ key: 'idle-continue' })
    expect(w.submitted.at(-1)).toContain('left.py')
  })

  test('hide band hides it until /hub band', ON, async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    await $.classic.SessionStart({ source: 'clear' })
    await (await mountBand($)).press({ key: 'band-hide' })
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeUndefined()
    await $.command.run({ command: 'hub', args: 'band' } as any)
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeDefined()
  })
})

describe('keys and the prompt box', () => {
  test('no Button the band draws carries a hotkey, in any of its states', ON, async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    w.pathPy = () => ok(goalJson(null, 1))
    await $.classic.SessionStart({ source: 'clear' })
    const states: unknown[][] = []
    const band = await mountBand($)
    states.push(await band.findAll({ type: 'Button' }))
    await band.press({ key: 'cu-skip' })
    await $.classic.Stop({ last_assistant_message: 'paused' } as any)
    const idle = await mountBand($)
    expect(await idle.find({ key: 'idle-continue' })).toBeDefined()
    states.push(await idle.findAll({ type: 'Button' }))
    const buttons = states.flat() as { key?: string; props: Record<string, unknown> }[]
    expect(buttons.length).toBeGreaterThan(3)
    expect(buttons.filter(b => b.props.hotkey !== undefined).map(b => b.key)).toEqual([])
  })

  test('the core-dump button inserts at the cursor over a long draft, never replacing or diverting it', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(JSON.stringify({ goals: [] }))
    w.box = { text: 'a long prompt the owner is still writing', cursor: 7 }
    await $.classic.SessionStart({ source: 'startup' })
    await $.session.measure({ context: { percent: 72 }, rateLimits: [], cost: {} } as any)
    const band = await mountBand($)
    expect(await band.find({ text: 'context at 72%' })).toBeDefined()
    await band.press({ key: 'dump' })
    expect(w.fills).toEqual([{ text: '/core-dump ', mode: 'insert' }])
    expect(w.copies).toEqual([])
  })
})

describe('wakes', () => {
  test('an answered decision page wakes an idle session once, naming the read command', ON, async ($, on) => {
    const w = world(on)
    withPage(w)
    await $.session.start({ cwd: CWD, surface: 'terminal', isInteractive: true })
    await $.classic.SessionStart({ source: 'startup' })
    await $.classic.Stop({ last_assistant_message: 'waiting on the page' } as any)
    w.exists.add(DP + '/pg/.answer.json')
    await w.clock.advance(61_000)
    await w.clock.advance(61_000)
    const wakes = w.submitted.filter(t => t.includes('decision-page.sh answer pg'))
    expect(wakes.length).toBe(1)
  })
})

describe('paths', () => {
  test('a home path in a reply becomes a clickable absolute link with the period outside it', ON, async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'startup' })
    await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'AssistantMessage', props: { text: 'Wrote ~/.claude/notes/x.md.' } as any })
    expect(w.rendered.at(-1)).toBe('Wrote [~/.claude/notes/x.md](file:///Users/alcatraz627/.claude/notes/x.md).')
  })
})
