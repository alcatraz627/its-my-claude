# Find every reader before calling a rename done

When you rename anything that something else refers to by name, the rename is
not finished when it compiles. It is finished when every reader of the old
name has been found and updated, or shown not to exist. Search the full tree
for the old name, and treat a green build as no evidence.

## Why a green build proves nothing

The readers that break are the ones resolved at runtime, by string. A
migration renamed a tag. A deduplication step matched on that tag string and
silently stopped matching. There was no symbol and no import, so nothing could
fail to compile, and every test passed. Type checks, imports and the suite are
all structurally blind to a string key.

## Names a reader can key on

- exported functions, classes and constants, including lazy or inline imports
- tag, label and status strings a consumer matches
- marker, lock and file names built by string concatenation
- config, JSON keys, env var names, job and hook names
- anything a doc, migration or script names as a literal

So the search covers non-code files too: configs, migrations, docs, data
files and shell scripts.

## Readers outside the tree

The same rule governs a corrected claim. When something you wrote turns out
wrong, its other copies are readers of the old version. Some live where no
search of the repo reaches:

- the PR title and description, the first thing a reviewer opens
- PR and issue comments, including your own earlier in the thread
- pushed commit messages, which you correct in the next commit's message
- chat messages, published docs, other repos

Example: a review found that a guide's central mechanism was wrong. It was
fixed in the three cited places, a fourth turned up by searching for the claim
itself, and the tree then searched clean three times. The same wrong
mechanism was still in the PR description, word for word, and in two PR
comments. Nobody looked, because the sweep was scoped to the file being
edited.

A reversed decision is the same case. Every prompt, help text, doc and test
that states the old decision is a reader. A test that pins the old behavior is
the worst copy, because it fails the fix.

## The check

1. Search the old name across the whole project, hidden and ignored files
   included, not only the renamed file's folder.
2. For each hit, update it, or say why it is unrelated.
3. List the off-tree surfaces above and check each by hand.
4. Only then is the rename done. If you cannot list the readers, you do not
   know the rename is safe.

In chat, if you only have part of the codebase, say which readers you could
not search.

## Reviewing a rename

Noting a rename in a review is not reviewing it. A review that mentions a
breaking rename without a reader sweep has not reviewed the rename.

## What this does not mean

A local variable, or a name whose only reader is the file you are editing,
needs no sweep. The trigger is a name that crosses a file, process or data
boundary.
