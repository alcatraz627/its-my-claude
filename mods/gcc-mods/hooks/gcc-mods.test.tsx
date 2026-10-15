// Drives the surfaces (band, side pane, status line, wakes, path links) with the
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
  inbox: () => string
  store: Record<string, unknown>
  storeSets: string[]
  storeDeletes: string[]
  dirs: Record<string, { name: string; kind: 'file' | 'dir' }[]>
  opens: Record<string, unknown>[]
  listed: string[]
  closes: string[]
  taskStore: string | null
  mcp: string
  ledger: string
  plugins: Record<string, boolean>
}

function world(on: On) {
  const w: World = {
    toasts: [], fills: [], copies: [], submitted: [], commands: [], rendered: [], statuses: [], runs: [],
    box: { text: '', cursor: 0 }, files: {}, exists: new Set(),
    pathPy: () => ok(goalJson('USER: pick one')),
    resolve: () => miss,
    inbox: () => '{"messages":[]}',
    store: {}, storeSets: [], storeDeletes: [], dirs: {}, opens: [], listed: [], closes: [],
    taskStore: null, mcp: '', ledger: '', plugins: {},
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
  on('session.end', ($, e) => ({ sessionId: e.sessionId }))
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
  on('fs.list', ($, e) => {
    const dir = String((e as { path?: string }).path ?? '')
    w.listed.push(dir)
    return { value: (w.dirs[dir] ?? []).map(f => ({ ...f, size: 0, mtimeMs: NOW, isLink: false })) }
  })
  on('store.keys', () => ({ value: Object.keys(w.store) }))
  on('store.get', ($, e) => ({ value: w.store[e.key] }))
  on('store.set', ($, e) => {
    w.store[e.key] = e.value
    w.storeSets.push(e.key)
    return { value: undefined }
  })
  on('store.delete', ($, e) => {
    delete w.store[e.key]
    w.storeDeletes.push(e.key)
    return { value: undefined }
  })
  on('ui.open', ($, e) => {
    w.opens.push({ ...(e as unknown as Record<string, unknown>) })
    return { value: { isPlaced: true } }
  })
  on('ui.close', ($, e) => {
    w.closes.push(e.id)
    return { value: undefined }
  })
  on('settings.read', () => ({ value: { enabledPlugins: w.plugins } }))
  on('fs.read', ($, e) => ({ value: w.files[String((e as { path?: string }).path ?? '')] ?? '' }))
  on('process.run', ($, e) => {
    w.runs.push([...e.argv])
    const argv = e.argv.join(' ')
    if (argv.includes('path.py')) return w.pathPy()
    if (argv.includes('resolve.sh')) return w.resolve()
    if (argv.includes('claude-ipc peers')) return ok('{"peers":[]}')
    if (argv.includes('claude-ipc inbox')) return ok(w.inbox())
    if (argv.includes('echo $PPID')) return ok('4242\n')
    if (argv.startsWith('id -u')) return ok('501\n')
    if (argv.includes('task.sh store')) return w.taskStore ? ok(w.taskStore + '\n') : miss
    if (argv.includes('mcp list')) return ok(w.mcp)
    if (argv.startsWith('tail ')) return ok(w.ledger)
    return ok('')
  })
  on('ui.render', ($, e) => {
    const text = (e as { props?: { text?: unknown } }).props?.text
    if (typeof text === 'string') w.rendered.push(text)
    return $.ui.resolve(e).Box({ children: [] })
  })
  return Object.assign(w, { clock })
}

type W = ReturnType<typeof world>

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
    expect(await band.find({ text: /My page/ })).toBeDefined()
    expect(await band.find({ text: /2 calls drafted for you/ })).toBeDefined()
    expect((await band.find({ type: 'Link' }))?.props.href).toBe('http://localhost:5106/dp/pg/')
    expect(await band.findAll({ type: 'Text', text: /localhost/ })).toEqual([])
    expect(await band.find({ key: 'cu-load' })).toBeUndefined()
  })

  test('owed reads point at /tasks now when nothing else applies', ON, async ($, on) => {
    world(on)
    await $.classic.SessionStart({ source: 'clear' })
    // a2 open and reviewed, plus one gated row whose gate is an object.
    const band = await mountBand($)
    expect(await band.find({ text: /2 reads owed by you/ })).toBeDefined()
    expect(await band.find({ text: /\/tasks now/ })).toBeDefined()
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
    expect(await band.find({ text: 'context 72% used' })).toBeDefined()
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
    expect(w.rendered.at(-1)).toBe('Wrote [~/.claude/notes/x.md](http://localhost:5106/doc?path=%2FUsers%2Falcatraz627%2F.claude%2Fnotes%2Fx.md).')
  })

  test('a markdown or text path opens in the doc viewer, any other file stays a file link', ON, async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'startup' })
    const mount = (text: string) => $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'AssistantMessage', props: { text } as any })
    await mount('See `~/.claude/notes/plan.txt` and ~/.claude/out/data.json.')
    const out = w.rendered.at(-1)!
    expect(out).toContain('(http://localhost:5106/doc?path=%2FUsers%2Falcatraz627%2F.claude%2Fnotes%2Fplan.txt)')
    expect(out).toContain('(file:///Users/alcatraz627/.claude/out/data.json)')
    await mount('Open ~/.claude/docs/GUIDE.markdown.')
    expect(w.rendered.at(-1)).toContain('(http://localhost:5106/doc?path=%2FUsers%2Falcatraz627%2F.claude%2Fdocs%2FGUIDE.markdown).')
  })
})

describe('mail', () => {
  const MAIL = { options: { startOn: true, mailWake: true } }
  const msg = (state: string | undefined, ts: number, id = 'm1') => ({ id, kind: 'inform', fromAlias: 'other', ts, ...(state ? { deliveryState: state } : {}) })
  const idleSession = async ($: any, w: W) => {
    await $.session.start({ cwd: CWD, surface: 'terminal', isInteractive: true })
    await $.classic.SessionStart({ source: 'startup' })
    await $.classic.Stop({ last_assistant_message: 'waiting' } as any)
    await w.clock.advance(61_000)
    await w.clock.advance(61_000)
  }
  const mailWakes = (w: World) => w.submitted.filter(t => t.includes('ipc message'))

  test('a surfaced message gives no wake and no mail count', MAIL, async ($, on) => {
    const w = world(on)
    w.inbox = () => JSON.stringify({ messages: [msg('surfaced', NOW + 5_000)] })
    await idleSession($, w)
    expect(mailWakes(w)).toEqual([])
    expect(w.statuses.at(-1)).not.toContain('✉')
  })

  test('a queued and a delivered message each wake once and are counted', MAIL, async ($, on) => {
    const w = world(on)
    w.inbox = () => JSON.stringify({ messages: [msg('queued', NOW + 5_000, 'q'), msg('delivered', NOW + 6_000, 'd'), msg('surfaced', NOW + 7_000, 's')] })
    await idleSession($, w)
    expect(mailWakes(w).length).toBe(1)
    expect(mailWakes(w)[0]).toContain('2 ipc messages')
    expect(w.statuses.at(-1)).toContain('✉ 2')
  })

  test('with no delivery state, mail older than the mod switching on never wakes or counts', MAIL, async ($, on) => {
    const w = world(on)
    w.inbox = () => JSON.stringify({ messages: [msg(undefined, NOW - 3_600_000)] })
    await idleSession($, w)
    expect(mailWakes(w)).toEqual([])
    expect(w.statuses.at(-1)).not.toContain('✉')
  })

  test('with no delivery state, mail that arrives after the mod switched on still wakes', MAIL, async ($, on) => {
    const w = world(on)
    w.inbox = () => JSON.stringify({ messages: [msg(undefined, NOW + 30_000)] })
    await idleSession($, w)
    expect(mailWakes(w).length).toBe(1)
    expect(w.statuses.at(-1)).toContain('✉ 1')
  })
})

describe('/hub on across /clear', () => {
  const END = { sessionId: 'test-session-0001', resume: { kind: 'id', value: 'x' } } as any
  const clearEnd = ($: any) => $.session.end({ reason: 'clear', ...END })

  test('an on session leaves a marker for its process when it is cleared', async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'on' } as any)
    await clearEnd($)
    expect(w.storeSets).toEqual(['carry:4242'])
  })

  test('the session after a clear starts on, uses the marker once, and offers the checkpoint', async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    w.store['carry:4242'] = { at: NOW - 2_000 }
    await $.classic.SessionStart({ source: 'clear' })
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeDefined()
    expect(w.storeDeletes).toEqual(['carry:4242'])
    expect(w.store['carry:4242']).toBeUndefined()
  })

  test('a marker is ignored by a startup, by another process, and when stale', async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    w.store['carry:4242'] = { at: NOW - 2_000 }
    await $.classic.SessionStart({ source: 'startup' })
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeUndefined()
    delete w.store['carry:4242']
    w.store['carry:999'] = { at: NOW - 2_000 }
    await $.classic.SessionStart({ source: 'clear' })
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeUndefined()
    delete w.store['carry:999']
    w.store['carry:4242'] = { at: NOW - 3_600_000 }
    await $.classic.SessionStart({ source: 'clear' })
    expect(await (await mountBand($)).find({ key: 'cu-load' })).toBeUndefined()
  })

  test('a session that was off, or left for any other reason, leaves no marker', async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'startup' })
    await clearEnd($)
    await $.command.run({ command: 'hub', args: 'on' } as any)
    await $.session.end({ reason: 'prompt_input_exit', ...END })
    expect(w.storeSets).toEqual([])
  })

  test('/hub off before the clear is not carried over', async ($, on) => {
    const w = world(on)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'on' } as any)
    await $.command.run({ command: 'hub', args: 'off' } as any)
    await clearEnd($)
    expect(w.storeSets).toEqual([])
  })
})

describe('the band rows', () => {
  test('a row is one line: kind chip, title, detail, link, then actions and a close, on one row', ON, async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    await $.classic.SessionStart({ source: 'clear' })
    const band = await mountBand($)
    const row = await band.find({ key: 'row-resume' })
    expect(row?.props.flexDirection).toBe('row')
    expect(row?.text).toContain('resume')
    expect(row?.text).toContain('probe-aa')
    // The close sits inside the same row, last, never on a line of its own.
    expect(row?.text.endsWith('✕')).toBe(true)
    expect(JSON.stringify(row?.children)).toContain('"key":"band-hide"')
    const buttons = (await band.findAll({ type: 'Button' })) as { key?: string; props: Record<string, unknown> }[]
    expect(buttons.map(b => b.key)).toEqual(['cu-load', 'cu-copy', 'cu-skip', 'band-hide'])
    expect(buttons.filter(b => b.props.variant === 'primary').map(b => b.key)).toEqual(['cu-load'])
    expect((await band.find({ key: 'band-hide' }))?.props.plain).toBe(true)
    // The separate "hide band" line is gone.
    expect(await band.find({ text: 'hide band' })).toBeUndefined()
  })

  test('a link is a Link element that underlines on hover, and a markdown checkpoint opens in the doc viewer', ON, async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    await $.classic.SessionStart({ source: 'clear' })
    const band = await mountBand($)
    const link = await band.find({ type: 'Link' })
    expect(link?.props.href).toBe('http://localhost:5106/doc?path=' + encodeURIComponent(CKPT))
    const label = link?.children[0] as { children: string[]; hover?: { underline?: boolean } }
    expect(label.children).toEqual(['view'])
    expect(label.hover?.underline).toBe(true)
  })

  const shapes: [string, (w: World, $: any) => Promise<void>][] = [
    ['decide', async (w) => withPage(w)],
    ['continue', async (w, $) => {
      w.pathPy = () => ok(goalJson(null, 2))
      await $.classic.Stop({ last_assistant_message: 'paused' } as any)
    }],
    ['context', async (w, $) => {
      w.pathPy = () => ok(JSON.stringify({ goals: [] }))
      await $.session.measure({ context: { percent: 72 }, rateLimits: [], cost: {} } as any)
    }],
    ['owed', async () => {}],
  ]
  for (const [kind, arrange] of shapes) {
    test('the ' + kind + ' offer is the same one-line row with a chip and a close', ON, async ($, on) => {
      const w = world(on)
      await $.classic.SessionStart({ source: 'startup' })
      await arrange(w, $)
      if (kind === 'decide') await $.classic.SessionStart({ source: 'clear' })
      const band = await mountBand($)
      const row = await band.find({ key: 'row-' + kind })
      expect(row?.props.flexDirection).toBe('row')
      expect(row?.text).toContain(kind === 'owed' ? 'owed' : kind)
      expect(await band.find({ key: 'band-hide' })).toBeDefined()
    })
  }

  test('the S2 and S3 presets stay selectable with /hub preset', ON, async ($, on) => {
    const w = world(on)
    withCheckpoint(w)
    await $.classic.SessionStart({ source: 'clear' })
    await $.command.run({ command: 'hub', args: 'preset S3' } as any)
    const boxed = await mountBand($)
    expect((await boxed.find({ key: 'row-resume' }))?.props.borderStyle).toBe('round')
    await $.command.run({ command: 'hub', args: 'preset S2' } as any)
    const barred = await mountBand($)
    expect((await barred.findAll({ type: 'Text', text: '▎' })).length).toBeGreaterThan(0)
    expect((await barred.find({ key: 'row-resume' }))?.props.borderStyle).toBeUndefined()
    await $.command.run({ command: 'hub', args: 'preset S1' } as any)
    expect((await (await mountBand($)).find({ key: 'row-resume' }))?.props.flexDirection).toBe('row')
    for (const preset of ['S1', 'S2', 'S3']) {
      await $.command.run({ command: 'hub', args: 'preset ' + preset } as any)
      const buttons = (await (await mountBand($)).findAll({ type: 'Button' })) as { props: Record<string, unknown> }[]
      expect(buttons.length).toBe(4)
      expect(buttons.filter(b => b.props.hotkey !== undefined)).toEqual([])
    }
  })
})

describe('status line', () => {
  test('the gauge says used, like the statusline', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(JSON.stringify({ goals: [] }))
    await $.classic.SessionStart({ source: 'startup' })
    await $.session.measure({ context: { percent: 42 }, rateLimits: [], cost: {} } as any)
    await $.classic.Stop({ last_assistant_message: 'done' } as any)
    expect(w.statuses.at(-1)).toContain('ctx 42% used')
  })

  test('decisions are counted for this project only', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(JSON.stringify({ goals: [] }))
    w.files[DP + '/.pending.txt'] = 'mine\nother\n'
    w.files[DP + '/mine/config.json'] = JSON.stringify({ title: 'A', origin: { project: CWD, session: 'x' }, decisions: [{}] })
    w.files[DP + '/other/config.json'] = JSON.stringify({ title: 'B', origin: { project: '/Users/alcatraz627/Code/elsewhere', session: 'y' }, decisions: [{}] })
    await $.classic.SessionStart({ source: 'startup' })
    await $.classic.Stop({ last_assistant_message: 'done' } as any)
    expect(w.statuses.at(-1)).toContain('1 decision')
    expect(w.statuses.at(-1)).not.toContain('2 decisions')
  })
})

describe('the side pane', () => {
  const STORE = CWD + '/tasks/session-test'
  const task = (id: number, status: string, blockedBy: string[] = []) => JSON.stringify({ id: String(id), subject: 'task ' + id, status, blocks: [], blockedBy })
  const mountSide = ($: any) => $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc-side', props: { title: 'gcc', isFocused: false, bodyColumns: 60, placement: 'dock', scroll: { offset: 0, bodyRows: 40 }, view: {} } as any })
  const seed = (w: World) => {
    w.taskStore = STORE
    w.dirs[STORE] = [{ name: '1.json', kind: 'file' }, { name: '2.json', kind: 'file' }, { name: '3.json', kind: 'file' }, { name: '4.json', kind: 'file' }, { name: '.lock', kind: 'file' }]
    w.files[STORE + '/1.json'] = task(1, 'completed')
    w.files[STORE + '/2.json'] = task(2, 'in_progress')
    w.files[STORE + '/3.json'] = task(3, 'pending', ['2'])
    w.files[STORE + '/4.json'] = task(4, 'pending')
    w.mcp = 'Checking MCP server health…\n\nrender: https://mcp.render.com/mcp (HTTP) - ✔ Connected\npostgres: npx -y server-postgres postgresql://user:secret@localhost/db - ✔ Connected\nplugin:foo:bar: npx foo - ✗ Failed to connect\nlinear: https://x (HTTP) - ! Needs authentication\n'
    w.plugins = { 'a@mkt': true, 'b@mkt': true, 'c@mkt': false }
    const fire = (sid: string, plug: string, chars: number) => JSON.stringify({ ts: 'x', plug, session_id: sid, chars })
    w.ledger = [fire('test-session-0001', 'sessionstart-lane', 700), fire('test-session-0001', 'ctx-pressure', 300), fire('test-session-0001', 'ctx-pressure', 300), fire('other-session', 'noise', 99999), JSON.stringify({ plug: 'trap', session_id: 'other-session', parent: 'test-session-0001', chars: 5000 })].join('\n')
  }
  const texts = async (pane: any) => ((await pane.findAll({ type: 'Text' })) as { text: string }[]).map(t => t.text).join('\n')

  test('/hub side opens the pane without asking for focus', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    expect(w.opens.length).toBe(1)
    expect(w.opens[0]).toMatchObject({ id: 'gcc-side' })
    expect(w.opens[0]!.focus).toBeUndefined()
    expect(w.opens[0]!.closeOnEscape).toBeUndefined()
    await $.command.run({ command: 'hub', args: 'side off' } as any)
    expect(w.closes).toEqual(['gcc-side'])
  })

  test('the pane is display only: no Button, Input or autofocus anywhere in it', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    const pane = await mountSide($)
    expect(await pane.findAll({ type: 'Button' })).toEqual([])
    expect(await pane.findAll({ type: 'Input' })).toEqual([])
    expect(await pane.findAll({ type: 'Select' })).toEqual([])
    expect((await texts(pane)).length).toBeGreaterThan(50)
  })

  test('tasks: running first, blocked marked, finished folded into a count', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    const t = await texts(await mountSide($))
    expect(t).toContain('Tasks')
    expect(t).toContain('task 2')
    expect(t).toContain('task 3')
    expect(t).not.toContain('task 1')
    expect(t).toContain('1 done')
    expect(t.indexOf('task 2')).toBeLessThan(t.indexOf('task 3'))
    expect(w.runs.filter(a => a.join(' ').includes('task.sh store')).length).toBe(1)
  })

  test('tasks: at most twelve rows, the rest as a count', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    w.dirs[STORE] = Array.from({ length: 30 }, (_, i) => ({ name: i + 1 + '.json', kind: 'file' as const }))
    for (let i = 1; i <= 30; i++) w.files[STORE + '/' + i + '.json'] = task(i, 'pending')
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    const t = await texts(await mountSide($))
    expect(t).toContain('task 12')
    expect(t).not.toContain('task 13')
    expect(t).toContain('+18 more')
  })

  test('a Task tool call refreshes the task rows, and the store is resolved once', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    on('tool.call', { tool: 'TaskCreate' }, () => ({ result: { ok: true } }) as any)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    w.dirs[STORE] = [...w.dirs[STORE]!, { name: '5.json', kind: 'file' }]
    w.files[STORE + '/5.json'] = task(5, 'pending')
    await $.tool.call({ tool: 'TaskCreate', subject: 'new', description: 'd' } as any)
    expect(await texts(await mountSide($))).toContain('task 5')
    expect(w.runs.filter(a => a.join(' ').includes('task.sh store')).length).toBe(1)
  })

  test('a clear makes the pane look the store up again', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    await $.session.start({ cwd: CWD, surface: 'terminal', isInteractive: true })
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    await $.classic.SessionStart({ source: 'clear' })
    await w.clock.advance(61_000)
    expect(w.runs.filter(a => a.join(' ').includes('task.sh store')).length).toBe(2)
  })

  test('MCP servers: healthy ones folded to a count, the others named, no command text', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    await w.clock.advance(100)
    const t = await texts(await mountSide($))
    expect(t).toContain('MCP servers')
    expect(t).toContain('2 connected')
    expect(t).toContain('foo:bar')
    expect(t).toContain('linear')
    expect(t).not.toContain('secret')
    expect(t).not.toContain('postgresql://')
  })

  test('plugins: enabled ones as a count with their names', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    const t = await texts(await mountSide($))
    expect(t).toContain('Plugins')
    expect(t).toContain('2 enabled')
    expect(t).toContain('1 off')
  })

  test('injections: only this session, grouped by hook, biggest first, in human numbers', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    await $.classic.SessionStart({ source: 'startup' })
    await $.command.run({ command: 'hub', args: 'side' } as any)
    const t = await texts(await mountSide($))
    expect(t).toContain('Injections')
    expect(t).toContain('3 fired')
    expect(t).toContain('1.3K chars')
    expect(t).toContain('sessionstart-lane')
    expect(t).toContain('ctx-pressure')
    expect(t).not.toContain('noise')
    expect(t).not.toContain('trap')
    expect(t.indexOf('sessionstart-lane')).toBeLessThan(t.indexOf('ctx-pressure'))
  })

  test('the pane is not read while it is closed', ON, async ($, on) => {
    const w = world(on)
    seed(w)
    await $.session.start({ cwd: CWD, surface: 'terminal', isInteractive: true })
    await $.classic.SessionStart({ source: 'startup' })
    await w.clock.advance(61_000)
    expect(w.runs.filter(a => a.join(' ').includes('task.sh store') || a.includes('tail') || a.join(' ').includes('mcp list'))).toEqual([])
  })
})

describe('the image opener', () => {
  const ROOT = '/private/tmp/claude-501'
  const DIR = ROOT + '/-Users-alcatraz627--claude/test-session-0001/images'
  const seedImages = (w: World) => {
    w.dirs[ROOT] = [{ name: '-Users-alcatraz627--claude', kind: 'dir' }, { name: 'other', kind: 'dir' }]
    w.dirs[ROOT + '/-Users-alcatraz627--claude'] = [{ name: 'test-session-0001', kind: 'dir' }]
    w.dirs[ROOT + '/other'] = [{ name: 'aaaa', kind: 'dir' }]
    w.exists.add(DIR)
    w.exists.add(DIR + '/1.png')
    w.exists.add(DIR + '/3.png')
    w.box = { text: 'look at [Image #1] and [Image #3] please', cursor: 4 }
  }
  const mountView = ($: any) => $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc-image', props: { title: 'images', isFocused: false, bodyColumns: 60, placement: 'inline', scroll: { offset: 0, bodyRows: 30 }, view: {} } as any })
  const withImages = async ($: any, w: W) => {
    await $.session.start({ cwd: CWD, surface: 'terminal', isInteractive: true })
    await $.classic.SessionStart({ source: 'startup' })
    await w.clock.advance(1_000)
  }

  test('a draft with [Image #n] gets a band row with an open button per image and a view button', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(JSON.stringify({ goals: [] }))
    seedImages(w)
    await withImages($, w)
    const band = await mountBand($)
    const row = await band.find({ key: 'row-images' })
    expect(row?.props.flexDirection).toBe('row')
    expect(row?.text).toContain('2 images')
    const keys = ((await band.findAll({ type: 'Button' })) as { key?: string }[]).map(b => b.key)
    expect(keys).toEqual(['img-open-1', 'img-open-3', 'img-view', 'img-hide'])
    const variants = ((await band.findAll({ type: 'Button' })) as { props: Record<string, unknown> }[]).filter(b => b.props.variant === 'primary')
    expect(variants.length).toBe(1)
  })

  test('open runs open on that image file; view opens an unfocused pane with the big image', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(JSON.stringify({ goals: [] }))
    seedImages(w)
    await withImages($, w)
    const band = await mountBand($)
    await band.press({ key: 'img-open-3' })
    expect(w.runs.at(-1)).toEqual(['open', DIR + '/3.png'])
    await band.press({ key: 'img-view' })
    expect(w.opens.at(-1)).toMatchObject({ id: 'gcc-image' })
    expect(w.opens.at(-1)!.focus).toBeUndefined()
    const pane = await mountView($)
    const images = (await pane.findAll({ type: 'Image' })) as { props: { source: unknown } }[]
    expect(images.map(i => i.props.source)).toEqual([{ file: DIR + '/1.png', format: 'png' }, { file: DIR + '/3.png', format: 'png' }])
    expect(await pane.findAll({ type: 'Button' })).toEqual([])
    expect(await pane.findAll({ type: 'Input' })).toEqual([])
  })

  test('the draft is read once a second at most, and only changes redraw', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(JSON.stringify({ goals: [] }))
    seedImages(w)
    await withImages($, w)
    const before = [w.runs.length, w.listed.length]
    await w.clock.advance(1_000)
    await w.clock.advance(1_000)
    // Nothing changed: no directory search again and no process run for it.
    expect([w.runs.length, w.listed.length]).toEqual(before)
    w.box = { text: 'no images now', cursor: 0 }
    await w.clock.advance(1_000)
    expect(await (await mountBand($)).find({ key: 'row-images' })).toBeUndefined()
  })

  test('when the image file cannot be found the row says so and offers no open button', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(JSON.stringify({ goals: [] }))
    w.box = { text: '[Image #2]', cursor: 0 }
    await withImages($, w)
    const band = await mountBand($)
    expect((await band.find({ key: 'row-images' }))?.text).toContain('not found')
    expect((await band.findAll({ type: 'Button' })).map((b: any) => b.key)).toEqual(['img-hide'])
  })

  test('no image button carries a hotkey, and the row never touches the draft', ON, async ($, on) => {
    const w = world(on)
    w.pathPy = () => ok(JSON.stringify({ goals: [] }))
    seedImages(w)
    await withImages($, w)
    const band = await mountBand($)
    const buttons = (await band.findAll({ type: 'Button' })) as { props: Record<string, unknown> }[]
    expect(buttons.length).toBe(4)
    expect(buttons.filter(b => b.props.hotkey !== undefined)).toEqual([])
    await band.press({ key: 'img-view' })
    await band.press({ key: 'img-open-1' })
    expect(w.fills).toEqual([])
    await band.press({ key: 'img-hide' })
    expect(await (await mountBand($)).find({ key: 'row-images' })).toBeUndefined()
  })
})
