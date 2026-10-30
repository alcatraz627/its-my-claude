# Read the siblings before you add to a file

Before adding a component, control, list, derivation, hook or table, open the
two or three files that already answer the same shape, and follow them. Or
say in one sentence why this case differs.

Deviating is allowed, and sometimes right. Deviating silently is the defect.
A choice that is defensible alone becomes a defect when every neighbour
answered the same question differently: the reader now holds two conventions
instead of one, and nothing mechanical sees the split. It compiles, the tests
pass, and only a person notices, usually the user, usually after it ships.

## What a sibling is

The nearest answer to the same question, not the nearest file by path.

- Adding a list page? The other list pages.
- Adding a derived boolean? How the file's other derivations are written.
- Adding a hook? The hooks on the same event.
- Adding a table? Every other table in the product.
- Adding a line to a prompt or rule? Every other instruction about the same
  decision.

Search for the concept, not the filename. The sibling rarely shares your
file's name.

## The check

1. Name the shape you are adding: a list, a derivation, a toggle, a gate.
2. Find two or three existing answers to it.
3. Follow them, or say in one sentence why this case differs.

## Example

Two data viewers rendered their full row sets, 2,452 rows in one case, with a
plain `Table` component. Every other list in the product paginated through a
shared data-table model. Nothing failed. They were simply the only two pages
in the product that behaved differently, and that difference is the cost.

## What this does not mean

- Not a ban on new patterns. A better answer is welcome. Say it out loud, and
  ideally apply it to the siblings too, so the product does not end up with
  two.
- Not a mandate to read the whole tree. Two or three real siblings is the bar.
- Different from searching before claiming something is absent. That fires
  when you say a thing does not exist. This fires when you add a thing that
  does.

## Diagnostic

You are writing a component, derivation or list and have not opened one
neighbouring file that does the same job.
