# Never delete a UI surface silently

Before deleting, removing or replacing a component, page or route, ask: has
the user seen and reviewed this surface before? If yes, then before the
deletion you need either the user's explicit approval in this conversation,
or a written note in the change that names the surface and says what now
covers what it did.

## Zero importers is not evidence

The tempting argument is "nothing imports it, so it is dead". But the user can
have reviewed and approved a surface that no code calls yet. A component that
this same piece of work orphaned looks exactly like one that was always dead.
The import graph cannot tell you which one you are looking at. Only the review
history can.

## Why this binds to the deletion itself

Most verification rules fire when someone writes a claim ("this is unused",
"nothing depends on this"). This failure happens during implementation, in the
middle of a refactor or cleanup, where a component gets removed and no claim
is ever written down to trigger a check. So the rule fires on the act of
deleting.

## An illustration

Say a refactor replaces an old settings panel with a new layout. The old
`NotificationPrefs` card has no importers left after the swap, so it gets
deleted as cleanup. The user had approved that card two rounds earlier, and
the new layout never got an equivalent. Nothing failed. The feature was gone,
and the user found out by looking for it.

## The check

1. List every component, page or route the change removes or replaces.
2. For each, ask whether the user has reviewed it.
3. If yes, either get approval now, or write in the change which new surface
   covers each thing the old one did. If nothing covers it, that is the
   question to ask.
4. If you cannot tell whether the user reviewed it, ask. A deleted surface
   costs more to rediscover than the question costs to ask.

If the user already asked for this exact removal, you hold the approval. Act.
