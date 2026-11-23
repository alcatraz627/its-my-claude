#!/usr/bin/env bash
# rules-index.sh: regenerate rules/00-index.md, the always-on menu of behavioral
# rules. DERIVED from each rule's frontmatter; never hand-edit the generated file
# (fix the rule's `brief:`, `gist:`, `triggers:` or `paths:` and re-run instead).
#
# Why an index exists: an always-on rule loads in full every session, but a rule
# with a `paths:` block does not, so this menu is the only way an agent learns a
# scoped rule exists. Scoped rules therefore get the situations that call for
# them and what they say; always-on rules get one line.
#
# The work is in rules-index.py beside this file. This stays the entry point
# because docs, skills and export-agents-md.sh all name it.
#
# Run after adding / renaming / removing a rule (or wire it to a hook).
set -uo pipefail
exec python3 "$(dirname "$0")/rules-index.py" "$@"
