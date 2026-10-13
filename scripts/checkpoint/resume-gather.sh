#!/usr/bin/env bash
# resume-gather.sh: everything /catchup needs about a checkpoint, in one call.
#
# Resolves the checkpoint, validates it, compares it with the world as it is
# now (git, PRs, nonces, ipc, background jobs, goal record) and prints what is
# done, what waits on the agent, what waits on the owner, and whether the agent
# can simply continue. The work is done by resume-gather.py beside this file.
#
# usage: resume-gather.sh [<checkpoint path>] [--session-id SID] [--pick N]
#                         [--cwd DIR] [--no-ipc]
#   --session-id  resolve via that session's pointer (and name this session)
#   --no-ipc      do not register with claude-ipc (reads still happen)
# exit: 0 printed a block, 2 ambiguous (picker list printed), 3 nothing found
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
command -v python3 >/dev/null 2>&1 || { echo "checkpoint: unknown (python3 missing)"; exit 3; }
exec python3 -I "$HERE/resume-gather.py" "$@"
