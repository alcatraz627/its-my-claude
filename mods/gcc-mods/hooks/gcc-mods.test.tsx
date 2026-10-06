// Drives the hub, the band and the router on two surfaces, with the engine
// beneath answered from memory: a fixed clock, canned process output for the
// gcc commands, and quiet side effects.

import type { On } from 'claude-code'
import { describe, expect, mock, test } from 'claude-code/testing'

const NOW = 1_790_000_000_000
// The mod starts off by default; these tests drive it on.
const ON = { options: { startOn: true } }

const PATH_JSON = JSON.stringify({
  scope: 'scope: live goals touching .claude · 1 goal(s)',
  armed: '',
  goals: [
    {
      id: 'g1',
      outcome: 'The pane shows the goal record at real width',
      projects: ['/Users/alcatraz627/.claude'],
      accept: [
        { id: 'a1', kind: 'functional', text: 'views render', evidence: 'ran', status: 'proven', source: null },
        { id: 'a2', kind: 'reviewed', text: 'owner reads the path render and does not re-ask', evidence: null, status: 'open', source: null },
      ],
      milestones: [{ id: 'm1', name: 'STORE', status: 'met' }],
      tasks: [
        { id: '1', subject: 'first row', milestone: 'm1', state: 'done', gate: null, blocked_by: [] },
        { id: '2', subject: 'second row', milestone: 'm1', state: 'todo', gate: null, blocked_by: [] },
      ],
      containment: [],
      cwd: '/Users/alcatraz627/.claude',
    },
  ],
})

// `own` names the events a test answers itself; the engine takes one mock per event.
function world(on: On, toasts: string[] = [], own: string[] = []) {
  const mine = (ev: string) => !own.includes(ev)
  mock.clock(on, { now: NOW })
  on('classic.SessionStart', () => ({}))
  on('classic.Stop', () => ({}))
  on('ui.toast', ($, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  on('ui.status', () => ({ value: undefined }))
  on('ui.log', () => ({ value: undefined }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  if (mine('ui.copy')) on('ui.copy', () => ({ value: { isCopied: true } }))
  on('ui.invalidate', () => ({ value: undefined }))
  if (mine('prompt.fill')) on('prompt.fill', () => ({ isFilled: true }))
  on('prompt.submit', () => ({ text: '' }))
  on('session.cwd', () => ({ value: '/Users/alcatraz627/.claude' }))
  on('session.id', () => ({ value: 'test-session-0001' }))
  on('fs.exists', () => ({ value: false }))
  on('fs.list', () => ({ value: [] }))
  if (mine('fs.read')) on('fs.read', () => ({ value: '' }))
  on('process.run', ($, e) => {
    const argv = e.argv.join(' ')
    if (argv.includes('path.py')) return { value: { exitCode: 0, stdout: PATH_JSON, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
    if (argv.includes('claude-ipc inbox')) return { value: { exitCode: 0, stdout: '{"messages":[{"id":"m1","kind":"query","fromAlias":"peer-a","body":"is the band done?","ts":1790000000}]}', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
    if (argv.startsWith('tail')) return { value: { exitCode: 0, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
    if (argv.includes('resolve.sh')) return { value: { exitCode: 3, stdout: '', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
    return { value: { exitCode: 0, stdout: 'ok', stderr: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })
  on('ui.render', ($, e) => $.ui.resolve(e).Box({ children: [] }))
}

const SURFACES = ['terminal', 'desktop'] as const

const PANE_PROPS = { title: 'gcc', isFocused: true, bodyColumns: 90, placement: 'dock' as const, scroll: { offset: 0, bodyRows: 40 }, view: {} }
const BAND_PROPS = { hasSurvey: false, isWorking: false, maxRows: 6, bodyColumns: 120, scroll: { offset: 0, bodyRows: 6 }, view: {} }

describe('gcc-mods', () => {
  for (const surface of SURFACES) {
    test('hub tabs draw from the goal record and the inbox on ' + surface, ON, async ($, on) => {
      world(on)
      await $.classic.SessionStart({ source: 'clear' })
      const ui = await $.ui.mount({ plugin: 'gcc-mods', surface, component: 'Pane', requestId: 'gcc', props: PANE_PROPS })

      await ui.press({ key: 'tab-tasks' })
      expect(await ui.find({ text: 'owner reads the path render and does not re-ask' })).toBeDefined()
      expect(await ui.find({ key: 'yes-a2' })).toBeDefined()
      await ui.press({ key: 'no-a2' })
      expect(await ui.find({ key: 'why-a2' })).toBeDefined()
      await ui.input({ key: 'why-a2', text: 'still spread out' })
      expect(await ui.find({ key: 'why-a2' })).toBeUndefined()

      await ui.press({ key: 'tab-inbox' })
      expect(await ui.find({ key: 'msg-m1' })).toBeDefined()
      await ui.press({ key: 'msg-m1' })
      expect(await ui.find({ text: 'is the band done?' })).toBeDefined()

      await ui.press({ key: 'tab-docs' })
      expect(await ui.find({ key: 'filter' })).toBeDefined()
      await ui.press({ key: 'tab-fleet' })
      expect(await ui.find({ text: 'Nothing running' })).toBeDefined()
      await ui.press({ key: 'tab-nudges' })
      expect(await ui.find({ key: 'nudge-refresh' })).toBeDefined()
      await ui.press({ key: 'tab-decide' })
      expect(await ui.find({ text: 'Nothing waiting on you here.' })).toBeDefined()
    })

    test('band shows the owed read, the chips, and hides on ' + surface, ON, async ($, on) => {
      world(on)
      await $.classic.SessionStart({ source: 'clear' })
      const band = await $.ui.mount({ plugin: 'gcc-mods', surface, component: 'AbovePrompt', props: BAND_PROPS })
      expect(await band.find({ key: 'gates' })).toBeDefined()
      expect((await band.find({ key: 'c-owed' }))?.text).toContain('1 owed')
      expect((await band.find({ key: 'c-mail' }))?.text).toContain('1 new')
      await band.press({ key: 'band-hide' })
      expect(await band.find({ key: 'c-docs' })).toBeUndefined()
    })
  }

  test("showing other agents' decision pages leaves the Tasks tab's done rows folded", ON, async ($, on) => {
    world(on, [], ['fs.read'])
    on('fs.read', ($, e) => {
      const p = String((e as { path?: string }).path ?? '')
      if (p.endsWith('.pending.txt')) return { value: 'peer-page\n' }
      if (p.endsWith('peer-page/config.json')) return { value: JSON.stringify({ title: 'A peer page', origin: { project: '/elsewhere', session: 'peer-x' }, decisions: [{ id: 'D1', question: 'q?', options: [{ code: 'a', label: 'yes', rec: true }] }] }) }
      return { value: '' }
    })
    await $.classic.SessionStart({ source: 'clear' })
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-decide' })
    expect((await ui.find({ key: 'dp-stale' }))?.text).toContain("1 other agent's page")
    await ui.press({ key: 'dp-stale' })
    expect(await ui.find({ key: 'dp-peer-page' })).toBeDefined()
    await ui.press({ key: 'tab-tasks' })
    expect((await ui.find({ key: 'done' }))?.text).toContain('show done rows')
  })

  test('a command fill over a draft goes to the clipboard, never into the box', ON, async ($, on) => {
    const fills: string[] = []
    const copies: string[] = []
    world(on, [], ['prompt.fill', 'ui.copy'])
    on('prompt.read', () => ({ value: { text: 'my own words', cursor: 12 } }))
    on('prompt.fill', ($, e) => {
      fills.push(e.text)
      return { isFilled: true }
    })
    on('ui.copy', ($, e) => {
      copies.push(e.text)
      return { value: { isCopied: true } }
    })
    await $.classic.SessionStart({ source: 'clear' })
    const ui = await $.ui.mount({ plugin: 'gcc-mods', surface: 'terminal', component: 'Pane', requestId: 'gcc', props: PANE_PROPS })
    await ui.press({ key: 'tab-tasks' })
    await ui.press({ key: 'goal-paste' })
    expect(fills).toEqual([])
    expect(copies.length).toBe(1)
  })

  test('router strips tagged owner blocks from hook context and keeps the rest', ON, async ($, on) => {
    const seen: string[] = []
    world(on, seen)
    on('prompt.attachment', ($, e) => ({ text: e.text }))
    const text = 'Check the output files before trusting them.\n<owner surface="toast" hook="subagent-box">seat pain-records landed · output ✓</owner>\nSurface this box verbatim to the user.'
    const r = await $.prompt.attachment({ type: 'hook_context', text, origin: { kind: 'hook', event: 'SubagentStop' } } as any)
    expect(seen.some(t => t.includes('pain-records landed'))).toBe(true)
    expect(String(r.text)).toContain('Check the output files')
    expect(String(r.text)).not.toContain('<owner')

    const tabled = '<owner surface="pane:tasks" hook="task-table-inject" model="The pane draws the table; point there.">THE TABLE</owner>'
    const r2 = await $.prompt.attachment({ type: 'hook_context', text: tabled, origin: { kind: 'hook', event: 'UserPromptSubmit' } } as any)
    expect(String(r2.text)).toBe('The pane draws the table; point there.')
    expect(String(r2.text)).not.toContain('THE TABLE')
  })
})
