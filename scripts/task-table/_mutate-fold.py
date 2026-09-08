#!/usr/bin/env python3
"""Plant the pre-ruling defect in a COPY of task-table.sh, for note-fold.test.sh.

Raises the inline-note floor above any real width, so no note ever qualifies to
ride the trait row and every one falls back to its own third line. That is
exactly how the renderer behaved before the owner's 2026-09-05 ruling, which
makes it the right mutation: a fold guard that stays green against this was
never testing the fold.

Lives as a file rather than inline in the suite because the mutation string is
the kind of thing a text-scanning hook trips on when it rides in a heredoc.
"""
import sys

path = sys.argv[1]
src = open(path).read()
mutated = src.replace("MIN_INLINE_NOTE = 28", "MIN_INLINE_NOTE = 9999  # MUTANT")
if mutated == src:
    sys.exit("mutation anchor not found: MIN_INLINE_NOTE = 28")
open(path, "w").write(mutated)
