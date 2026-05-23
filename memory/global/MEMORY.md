# Global Memory Index

<!-- Cross-project memories loaded via CLAUDE.md instruction. See README.md for format. -->

## User Profile
- [User Profile](user_profile.md) — Terminal-first macOS developer; vim-style nav; prefers CLI tools and dark mode

## Feedback — Communication & Autonomy
- [Challenge user requests](feedback_challenge_user_asks.md) — Push back on suboptimal asks; be opinionated, not a yes-machine
- [Autonomous mode](feedback_autonomous.md) — Prefers fully autonomous operation; batch work, use background agents
- [No speculative output descriptions](feedback_agent_output_descriptions.md) — Agents producing files: return path only, don't describe visual design
- [Skip Learn by Doing](feedback_no_learn_by_doing.md) — Don't use scaffolded learning prompts for simple mechanical tasks
- [Proactive question ownership](feedback_proactive_question_ownership.md) — Own meta-questions (project ceiling, user-stories, safety nets); ASK + RE-ASK + save answers; user explicitly endorses re-asking

## Feedback — Task Framing & Scope
- [Maximalist ≠ ambitious](feedback_ambitious_vs_maximalist.md) — Wide-and-flat works for agents; tall-stacked dependent layers fail (tower without spine)
- [Propose safety nets](feedback_propose_safety_nets.md) — Surface missing safety nets (idempotency, dry-runs, diff previews, undo) ASAP, even on existing projects; over-suggesting is fine, missing is regrettable

## Feedback — Verification & Testing
- [Always test small sample first](feedback_always_test_small_sample.md) — MANDATORY: test every transform on 2-3 rows before full run
- [Verify before refactoring](feedback_verify_before_refactoring.md) — Spot-check 2-3 targets against actual code before starting cleanup
- [Verify imports before reporting](feedback_verify_imports.md) — Check import sites and actual usage before reporting audit findings
- [Respect human comments](feedback_respect_human_comments.md) — Ask before changing human-commented code; verify each change independently
- [Test naming conventions](feedback_test_conventions.md) — Prefer generic reusable tests with specific naming conventions

## Feedback — Git & Session
- [No commit unless asked](feedback_no_commit_unless_asked.md) — Only commit when user says "commit" explicitly; "don't push" means no git ops
- [Session continuity](feedback_session_continuity.md) — Long sessions with frequent compaction; relies on /catchup and /core-dump

## Feedback — Technical
- [Node.js require cache](feedback_require_cache_clearing.md) — Always clear require.cache before re-loading config in pipeline engine
- [Use uv, avoid context overflow](feedback_uv_context.md) — Use uv package manager; don't load large files into context
