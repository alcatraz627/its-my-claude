#!/usr/bin/env bash
# policy-inject.sh — SessionStart injector: one line telling the session what
# the owner's policy allows and blocks. The injection lane runs each injector
# with no arguments, so this forwards the payload to `pol.sh inject`.
exec bash "$(dirname "${BASH_SOURCE[0]}")/pol.sh" inject
